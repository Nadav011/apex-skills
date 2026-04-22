# database-patterns — Real-World Examples

The skill catches common database anti-patterns that cause performance degradation and security vulnerabilities. Each example maps to a specific failure mode.

## Before / After

### Example 1: N+1 query in a REST endpoint

**Before** (triggers the skill):
```typescript
// ❌ 1 query for orders + N queries for each customer — O(N) round trips
export async function GET() {
  const orders = await prisma.order.findMany({
    where: { status: 'pending' },
  });

  const enriched = await Promise.all(
    orders.map(async (order) => ({
      ...order,
      customer: await prisma.user.findUnique({ where: { id: order.userId } }),
    })),
  );

  return Response.json(enriched);
}
```

**After** (skill-compliant):
```typescript
// ✅ 2 queries total — Prisma batches the user lookups
export async function GET() {
  const orders = await prisma.order.findMany({
    where: { status: 'pending' },
    select: {
      id: true,
      total: true,
      createdAt: true,
      customer: {
        select: { id: true, name: true, email: true },
      },
    },
  });

  return Response.json(orders);
}
```

**Why:** With 500 pending orders, the before version fires 501 database round trips. The after version fires 2 (or 1 with a JOIN depending on the adapter). At 5 ms per round trip, that's 2.5 seconds vs ~10 ms.

---

### Example 2: Unsafe migration — adding a NOT NULL column

**Before** (triggers the skill):
```sql
-- ❌ Locks the entire table on large datasets; downtime on production
ALTER TABLE users ADD COLUMN preferences JSONB NOT NULL;
```

**After** (skill-compliant):
```sql
-- ✅ Step 1 (deploy): add nullable — zero locking on Postgres 11+
ALTER TABLE users ADD COLUMN preferences JSONB;

-- ✅ Step 2 (backfill in batches — run offline or as a background job):
UPDATE users SET preferences = '{}'
WHERE preferences IS NULL AND id IN (
  SELECT id FROM users WHERE preferences IS NULL LIMIT 5000
);
-- Repeat until 0 rows updated

-- ✅ Step 3 (follow-up deploy): apply NOT NULL + default now that all rows are filled
ALTER TABLE users ALTER COLUMN preferences SET NOT NULL;
ALTER TABLE users ALTER COLUMN preferences SET DEFAULT '{}';
```

**Why:** `ADD COLUMN ... NOT NULL` with no default rewrites every row in older Postgres versions and acquires an `ACCESS EXCLUSIVE` lock. On a table with 10M rows that's minutes of downtime. The three-step approach keeps each ALTER cheap and lock time sub-second.

---

### Example 3: Missing index on a foreign key

**Before** (triggers the skill):
```typescript
// ❌ Schema has no index on comments.post_id
// Loading all comments for a post = full table scan
const comments = await db.query(
  'SELECT id, body, created_at FROM comments WHERE post_id = $1 ORDER BY created_at DESC',
  [postId],
);
// EXPLAIN: Seq Scan on comments (cost=0.00..18432.00 rows=8000)
```

**After** (skill-compliant):
```sql
-- ✅ Add index on the foreign key used in WHERE + ORDER BY
CREATE INDEX idx_comments_post_id_created_at
  ON comments (post_id, created_at DESC);
```

```typescript
// Same query now uses the index
// EXPLAIN: Index Scan using idx_comments_post_id_created_at (cost=0.43..8.47 rows=8000)
const comments = await db.query(
  'SELECT id, body, created_at FROM comments WHERE post_id = $1 ORDER BY created_at DESC',
  [postId],
);
```

**Why:** On a table with 5M comments, a sequential scan reads every row on every page load. The composite index `(post_id, created_at DESC)` covers both the filter and the sort, making the query an index-only scan — typically 100-1000x faster.

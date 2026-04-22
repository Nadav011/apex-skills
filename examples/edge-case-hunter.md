# edge-case-hunter — Real-World Examples

The skill exhaustively enumerates execution paths in code: null/undefined gaps, boundary conditions, race conditions, async rejections, and RTL edge cases. Minimum 10 edge cases per review.

## Before / After

### Example 1: Order total calculation with hidden failure modes

**Before** (triggers the skill):
```typescript
// calculateOrderTotal — before edge-case review
function calculateOrderTotal(items: CartItem[], coupon?: Coupon) {
  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const discount = coupon ? subtotal * coupon.discountRate : 0;
  const tax = (subtotal - discount) * 0.17;
  return subtotal - discount + tax;
}
```

**After** (edge-case-hunter output + hardened code):
```typescript
/**
 * Edge Cases Found (10):
 * 1. BLOCKER  item.price null/undefined → NaN propagates through entire calculation
 * 2. CRITICAL items=[] → returns 0 (correct) but callers may not guard against it
 * 3. CRITICAL item.quantity=0 → zero cost item silently included in cart
 * 4. CRITICAL item.price < 0 → negative subtotal; coupon amplifies to store credit
 * 5. CRITICAL coupon.discountRate > 1 → 150% discount → negative total (free + credit)
 * 6. MAJOR    Float precision: 0.1 * 3 = 0.30000000000000004 → wrong displayed price
 * 7. MAJOR    coupon.expiresAt not checked → expired coupons accepted
 * 8. MAJOR    Number.MAX_SAFE_INTEGER: 999999 items * 99999 price = no overflow but
 *             display rounding issues above ~900 trillion
 * 9. MINOR    No return type annotation — callers assume number but get NaN on error
 * 10. MINOR   RTL: callers display result with text-left / ml-2 alignment
 */
function calculateOrderTotal(
  items: CartItem[],
  coupon?: Coupon,
): { subtotalCents: number; discountCents: number; taxCents: number; totalCents: number } {
  if (items.length === 0) {
    return { subtotalCents: 0, discountCents: 0, taxCents: 0, totalCents: 0 };
  }

  // Work in integer cents to eliminate float precision issues
  const subtotalCents = items.reduce((sum, item) => {
    if (item.priceCents == null || item.priceCents < 0) {
      throw new Error(`Invalid item price: ${item.priceCents}`);
    }
    if (item.quantity <= 0) throw new Error(`Invalid quantity: ${item.quantity}`);
    return sum + item.priceCents * item.quantity;
  }, 0);

  let discountCents = 0;
  if (coupon) {
    if (coupon.discountRate < 0 || coupon.discountRate > 1) {
      throw new Error(`Invalid discount rate: ${coupon.discountRate}`);
    }
    if (coupon.expiresAt && new Date(coupon.expiresAt) < new Date()) {
      throw new Error('Coupon has expired');
    }
    discountCents = Math.floor(subtotalCents * coupon.discountRate);
  }

  const taxableCents = subtotalCents - discountCents;
  const taxCents = Math.floor(taxableCents * 0.17);
  return { subtotalCents, discountCents, taxCents, totalCents: taxableCents + taxCents };
}
```

**Why:** Floating-point arithmetic on monetary values produces `0.30000000000000004` for `0.1 * 3`. Working in integer cents eliminates this entirely. The negative-price and >100%-discount cases are injection vectors that can result in a negative total — a free order plus store credit.

---

### Example 2: Async user lookup with race condition and unmount leak

**Before** (triggers the skill):
```typescript
// useUserProfile hook — before edge-case review
function useUserProfile(userId: string) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetch(`/api/users/${userId}`)
      .then(r => r.json())
      .then(data => {
        setProfile(data);
        setLoading(false);
      });
  }, [userId]);

  return { profile, loading };
}
```

**After** (edge-case-hunter output + hardened code):
```typescript
/**
 * Edge Cases Found (10):
 * 1. BLOCKER  Race condition: userId A→B; B resolves first, then A overwrites
 *    with stale data — shows wrong profile
 * 2. BLOCKER  Unmounted component setState: fetch resolves after navigation →
 *    React warning + potential stale closure memory leak
 * 3. CRITICAL fetch() network failure → unhandled rejection, loading stuck true
 * 4. CRITICAL r.json() throws if server returns HTML error page (non-JSON body)
 * 5. CRITICAL 404 / 500 responses treated as success — sets profile to error body
 * 6. MAJOR    userId="" → fetch("/api/users/") returns 405 or wrong resource
 * 7. MAJOR    No error state exposed — caller cannot render error UI
 * 8. MAJOR    setLoading(false) only in .then — stuck true on any error path
 * 9. MINOR    Profile shape not validated — silent type errors on API contract change
 * 10. MINOR   No debounce — rapid userId changes fire many parallel requests
 */
function useUserProfile(userId: string | undefined) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!userId) return;

    const controller = new AbortController();
    setLoading(true);
    setError(null);

    fetch(`/api/users/${encodeURIComponent(userId)}`, { signal: controller.signal })
      .then(async (r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        const raw: unknown = await r.json();
        return ProfileSchema.parse(raw); // validate shape at boundary
      })
      .then(setProfile)
      .catch((err: unknown) => {
        if (err instanceof Error && err.name === 'AbortError') return;
        setError(err instanceof Error ? err : new Error(String(err)));
      })
      .finally(() => setLoading(false));

    return () => controller.abort(); // cancels on userId change or unmount
  }, [userId]);

  return { profile, loading, error };
}
```

**Why:** The race condition is the most dangerous — userId changes A→B, both fetches fire, B resolves first and sets the correct profile, then A's older response overwrites it with stale data. `AbortController` cancels the in-flight request when `userId` changes, so only the latest fetch's result is applied.

---

### Example 3: Batch database migration with partial-failure trap

**Before** (triggers the skill):
```typescript
// migrate-emails.ts — normalize all user emails to lowercase
async function migrateEmails() {
  const users = await db.users.findMany(); // loads ALL users into memory

  for (const user of users) {
    const normalized = user.email.toLowerCase().trim();
    await db.users.update({
      where: { id: user.id },
      data: { emailNormalized: normalized },
    });
    console.log(`Updated ${user.id}`);
  }
  console.log('Done');
}
```

**After** (edge-case-hunter output + hardened code):
```typescript
/**
 * Edge Cases Found (10):
 * 1. BLOCKER  user.email null in legacy rows → .toLowerCase() throws, script aborts
 *    half-way — 50% of table updated, no way to know which 50%
 * 2. BLOCKER  findMany() with no limit on 500K-row table → OOM crash
 * 3. CRITICAL No resume point: script restart re-processes already-updated rows
 * 4. CRITICAL Single update failure aborts the loop — no error aggregation
 * 5. CRITICAL Live traffic sees inconsistent state during multi-hour migration
 * 6. MAJOR    email with Unicode (e.g. Turkish "İ") — toLowerCase() is locale-dependent
 * 7. MAJOR    No dry-run mode — cannot verify transformations before applying
 * 8. MAJOR    console.log floods logs, masks real errors at scale
 * 9. MINOR    Script exits 0 even when errors occurred — CI won't catch partial failure
 * 10. MINOR   No progress ETA — operator has no visibility on completion time
 */
async function migrateEmails({ dryRun = false } = {}) {
  const BATCH = 500;
  let cursor: string | undefined;
  let processed = 0;
  let errors = 0;

  logger.info({ dryRun }, 'Starting email normalization migration');

  while (true) {
    const users = await db.users.findMany({
      take: BATCH,
      ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
      orderBy: { id: 'asc' },
      select: { id: true, email: true },
    });
    if (users.length === 0) break;

    for (const user of users) {
      if (!user.email) {
        logger.warn({ userId: user.id }, 'Skipping null email');
        continue;
      }
      const normalized = user.email.toLocaleLowerCase('en-US').trim();
      if (!dryRun) {
        try {
          await db.users.update({ where: { id: user.id }, data: { emailNormalized: normalized } });
        } catch (err) {
          logger.error({ err, userId: user.id }, 'Update failed');
          errors++;
        }
      } else {
        logger.debug({ userId: user.id, from: user.email, to: normalized }, 'Would update');
      }
      processed++;
    }

    cursor = users.at(-1)!.id;
    logger.info({ processed, errors }, 'Batch complete');
  }

  if (errors > 0) { logger.error({ errors }, 'Migration completed with errors'); process.exit(1); }
  logger.info({ processed }, 'Migration complete');
}
```

**Why:** Loading all rows with `findMany()` (no `take`) OOMs the Node process on large tables. Cursor-based batching processes records in stable, resumable pages. The `dryRun` flag lets operators verify the transformation before committing — essential for irreversible operations on production data.

# adversarial-review — Real-World Examples

The skill performs a cynical L10+ Distinguished Engineer review: minimum 10 issues, BLOCKER/CRITICAL/MAJOR/MINOR severity, concrete fixes (not "consider using"). Code is assumed broken until proven otherwise.

## Before / After

### Example 1: Payment processing route with multiple blockers

**Before** (triggers the skill):
```typescript
// POST /api/payments — production payment handler
export async function POST(request: Request) {
  const body = await request.json();
  const user = await getSession(); // getSession, not getUser

  const payment = await stripe.paymentIntents.create({
    amount: body.amount,
    currency: body.currency ?? 'usd',
    customer: user.id,
    metadata: { orderId: body.orderId },
  });

  await db.payments.create({
    data: { userId: user.id, amount: body.amount, stripeId: payment.id }
  });

  return Response.json({ clientSecret: payment.client_secret });
}
```

**After** (adversarial review output + fixed code):
```typescript
/**
 * ADVERSARIAL REVIEW — POST /api/payments
 * Verdict: NEEDS WORK
 * Issues: 7 (3 BLOCKER, 2 CRITICAL, 2 MAJOR)
 *
 * BLOCKER-1 getSession() instead of getUser(): JWT not server-validated.
 *   Any expired/forged session cookie passes auth.
 * BLOCKER-2 body.amount is unsanitized: client controls charge amount.
 *   Attacker sends { amount: 1 } and pays $0.01 for any order.
 * BLOCKER-3 No rate limiting: endpoint can be hammered to exhaust Stripe quota.
 * CRITICAL-1 No idempotency key: network retry creates duplicate charges.
 * CRITICAL-2 DB write after Stripe call with no rollback: charge succeeds but
 *   DB fails → customer charged, no record in system.
 * MAJOR-1 No Zod validation: body.currency accepts "XYZ"; Stripe returns 400.
 * MAJOR-2 Leaks client_secret in JSON response without HTTPS enforcement check.
 */
export async function POST(request: Request) {
  // Rate limiting first
  const ip = request.headers.get('x-forwarded-for') ?? 'unknown';
  const { success } = await paymentRatelimit.limit(ip);
  if (!success) return Response.json({ error: 'Rate limit exceeded' }, { status: 429 });

  // Server-validated auth
  const { data: { user }, error } = await supabase.auth.getUser();
  if (!user || error) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  // Zod-validated, server-authoritative amount
  const result = createPaymentSchema.safeParse(await request.json());
  if (!result.success) {
    return Response.json({ error: result.error.flatten() }, { status: 422 });
  }

  // Fetch price server-side — never trust client-supplied amount
  const order = await db.orders.findUnique({ where: { id: result.data.orderId, userId: user.id } });
  if (!order) return Response.json({ error: 'Not found' }, { status: 404 });

  // Idempotency key prevents duplicate charges on retry
  const idempotencyKey = `pay_${order.id}_${user.id}`;

  const [payment, dbError] = await db.$transaction(async (tx) => {
    const pi = await stripe.paymentIntents.create(
      { amount: order.totalCents, currency: 'ils', customer: user.id,
        metadata: { orderId: order.id } },
      { idempotencyKey }
    );
    await tx.payments.create({ data: { userId: user.id, amount: order.totalCents, stripeId: pi.id } });
    return [pi, null];
  }).catch(err => [null, err]);

  if (dbError) {
    logger.error({ err: dbError, orderId: order.id }, 'Payment transaction failed');
    return Response.json({ error: 'Payment processing failed' }, { status: 500 });
  }

  return Response.json({ clientSecret: payment.client_secret });
}
```

**Why:** The adversarial review surfaces client-controlled amount (BLOCKER), unauthenticated session (BLOCKER), missing idempotency key (CRITICAL), and the non-atomic DB write (CRITICAL) — each independently causes real financial damage. The fix adds rate limiting, server-authoritative pricing, a transaction wrapping both operations, and an idempotency key.

---

### Example 2: User search endpoint with injection and N+1

**Before** (triggers the skill):
```typescript
// GET /api/admin/users?q=&role=
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const q = searchParams.get('q') || '';
  const role = searchParams.get('role') || 'user';

  const users = await db.$queryRaw`
    SELECT * FROM users
    WHERE name LIKE '%${q}%'
    AND role = '${role}'
  `;

  const enriched = await Promise.all(
    users.map(async (u: any) => ({
      ...u,
      orders: await db.orders.count({ where: { userId: u.id } }),
    }))
  );

  return Response.json(enriched);
}
```

**After** (adversarial review output + fixed code):
```typescript
/**
 * ADVERSARIAL REVIEW — GET /api/admin/users
 * Verdict: NEEDS WORK
 * Issues: 10 (2 BLOCKER, 3 CRITICAL, 3 MAJOR, 2 MINOR)
 *
 * BLOCKER-1 SQL injection via template literal: `%${q}%` interpolated directly.
 *   Attack: q="%'; DROP TABLE users; --" destroys the database.
 * BLOCKER-2 No auth/authz: any user can call admin endpoint.
 * CRITICAL-1 N+1 query: one db.orders.count per user row — 100 users = 101 queries.
 * CRITICAL-2 `any` type on users: DB errors silently treated as empty object.
 * CRITICAL-3 Unbounded result set: SELECT * with no LIMIT on users table.
 * MAJOR-1 `role` string interpolated unsanitized into raw SQL.
 * MAJOR-2 Returns full user rows including password_hash, tokens.
 * MAJOR-3 No pagination — response grows O(n) with user table size.
 * MINOR-1 `|| ''` instead of nullish coalescing masks explicit empty string.
 * MINOR-2 No traceId in error logs for correlation.
 */
export async function GET(request: Request) {
  const { user } = await getAuthenticatedUser();
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  const isAdmin = await db.profiles.findFirst({ where: { id: user.id, role: 'admin' } });
  if (!isAdmin) return Response.json({ error: 'Forbidden' }, { status: 403 });

  const params = searchUsersSchema.safeParse(
    Object.fromEntries(new URL(request.url).searchParams)
  );
  if (!params.success) return Response.json({ error: params.error.flatten() }, { status: 422 });

  const { q, role, cursor, limit } = params.data;

  // Parameterized query — no injection possible
  const users = await db.users.findMany({
    where: {
      ...(q ? { name: { contains: q, mode: 'insensitive' } } : {}),
      ...(role ? { role } : {}),
    },
    select: { id: true, name: true, email: true, role: true, createdAt: true },
    take: limit + 1,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
  });

  // Single aggregation query instead of N+1
  const orderCounts = await db.orders.groupBy({
    by: ['userId'],
    where: { userId: { in: users.map(u => u.id) } },
    _count: true,
  });
  const countMap = new Map(orderCounts.map(r => [r.userId, r._count]));

  const data = users.slice(0, limit).map(u => ({ ...u, orderCount: countMap.get(u.id) ?? 0 }));
  return Response.json({ data, hasMore: users.length > limit });
}
```

**Why:** The raw SQL template literal allows direct injection of the search query into SQL. The adversarial review immediately flags this as BLOCKER-1 alongside missing authz (BLOCKER-2) and the classic N+1 pattern (CRITICAL-1). The fix switches to Prisma parameterized queries, adds admin role check, and replaces per-row `count` calls with a single `groupBy` aggregation.

---

### Example 3: WebSocket message handler with race condition

**Before** (triggers the skill):
```typescript
// WebSocket message handler for a collaborative document editor
const sessions = new Map<string, { userId: string; doc: string }>();

wss.on('connection', (ws, req) => {
  const userId = req.headers['x-user-id'] as string; // trusted from header!

  ws.on('message', async (data) => {
    const msg = JSON.parse(data.toString()); // no try/catch

    if (msg.type === 'UPDATE') {
      const session = sessions.get(msg.docId);
      const updated = applyPatch(session!.doc, msg.patch);
      sessions.set(msg.docId, { ...session!, doc: updated });
      await db.documents.update({ where: { id: msg.docId }, data: { content: updated } });
      wss.clients.forEach(c => c.send(JSON.stringify({ type: 'DOC_UPDATE', doc: updated })));
    }
  });
});
```

**After** (adversarial review output + fixed code):
```typescript
/**
 * ADVERSARIAL REVIEW — WebSocket UPDATE handler
 * Verdict: NEEDS WORK
 * Issues: 11 (3 BLOCKER, 4 CRITICAL, 2 MAJOR, 2 MINOR)
 *
 * BLOCKER-1 userId from header: HTTP headers are client-controlled.
 *   Attacker sets x-user-id to any other user's ID.
 * BLOCKER-2 No authz on docId: any connected user can overwrite any document.
 * BLOCKER-3 session! non-null assertion: if docId not in map → crash.
 * CRITICAL-1 JSON.parse without try/catch: malformed message crashes the process.
 * CRITICAL-2 Race condition: two concurrent messages read same session, one wins,
 *   other's patch is lost (last-write-wins without version check).
 * CRITICAL-3 Broadcast to ALL clients including those on different docs.
 * CRITICAL-4 applyPatch unsanitized: patch object from client used directly.
 * MAJOR-1 No message size limit: 100MB message causes OOM.
 * MAJOR-2 DB update fires-and-forgets (no await error check).
 * MINOR-1 No heartbeat/ping-pong: dead connections stay in Map.
 * MINOR-2 No max-session per user: one user opens 10K connections.
 */
wss.on('connection', async (ws, req) => {
  // Auth via JWT in query param or Authorization header — never trust x-user-id
  const token = new URL(req.url!, 'ws://localhost').searchParams.get('token');
  const { userId } = await verifyJwt(token ?? '').catch(() => ({ userId: null }));
  if (!userId) { ws.close(4001, 'Unauthorized'); return; }

  ws.on('message', async (rawData) => {
    if (rawData.toString().length > 64_000) { ws.close(4002, 'Message too large'); return; }

    let msg: unknown;
    try { msg = JSON.parse(rawData.toString()); }
    catch { ws.send(JSON.stringify({ type: 'ERROR', code: 'INVALID_JSON' })); return; }

    const parsed = updateMessageSchema.safeParse(msg);
    if (!parsed.success) return;

    const { docId, patch, version } = parsed.data;

    // Authz: verify ownership before any mutation
    const doc = await db.documents.findFirst({ where: { id: docId, ownerId: userId } });
    if (!doc) { ws.send(JSON.stringify({ type: 'ERROR', code: 'FORBIDDEN' })); return; }

    // Optimistic concurrency control via version check
    if (doc.version !== version) {
      ws.send(JSON.stringify({ type: 'CONFLICT', currentDoc: doc.content }));
      return;
    }

    const updated = applyPatch(doc.content, patch);
    await db.documents.update({
      where: { id: docId, version }, // atomic version check at DB level
      data: { content: updated, version: version + 1 },
    });

    // Broadcast only to clients subscribed to this document
    docSubscribers.get(docId)?.forEach(client => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify({ type: 'DOC_UPDATE', doc: updated, version: version + 1 }));
      }
    });
  });
});
```

**Why:** The adversarial review identifies that headers are client-controlled (BLOCKER-1), authz on `docId` is absent (BLOCKER-2), and a classic last-write-wins race condition corrupts collaborative edits (CRITICAL-2). The fix uses JWT auth, optimistic concurrency with a version field, and scoped broadcast to document subscribers only.

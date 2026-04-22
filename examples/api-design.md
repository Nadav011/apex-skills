# api-design — Real-World Examples

The skill enforces RESTful API design principles: resource naming, correct HTTP verbs, precise status codes, cursor pagination, RFC 7807 error shape, idempotency keys, and consistent response envelopes.

## Before / After

### Example 1: Verb-in-path URLs and wrong status codes

**Before** (triggers the skill):
```typescript
// ❌ Verb-based routes, wrong status codes, inconsistent error shape
router.post('/getUser', async (req, res) => {
  const user = await db.users.findById(req.body.userId);
  if (!user) return res.status(200).json({ success: false, error: 'Not found' }); // 200 with error!
  return res.json(user); // no envelope, returns raw db row including password_hash
});

router.post('/deleteUser', async (req, res) => {
  await db.users.delete({ where: { id: req.body.userId } });
  return res.json({ deleted: true }); // 200 for a deletion
});

router.post('/updateUserEmail', async (req, res) => {
  const updated = await db.users.update({
    where: { id: req.body.userId },
    data: { email: req.body.email }
  });
  return res.json({ ok: true, data: updated });
});
```

**After** (skill-compliant):
```typescript
// ✅ Noun-based resources, precise status codes, consistent envelopes
// GET /v1/users/:id
router.get('/v1/users/:id', async (req, res) => {
  const user = await db.users.findUnique({
    where: { id: req.params.id },
    select: { id: true, email: true, name: true, role: true, createdAt: true }, // no password_hash
  });
  if (!user) {
    return res.status(404).json({ error: { code: 'USER_NOT_FOUND',
      message: 'User not found', traceId: req.traceId } });
  }
  return res.status(200).json({ data: user });
});

// DELETE /v1/users/:id → 204 No Content
router.delete('/v1/users/:id', async (req, res) => {
  await db.users.delete({ where: { id: req.params.id } });
  return res.status(204).send(); // no body on successful delete
});

// PATCH /v1/users/:id → 200 with updated resource
router.patch('/v1/users/:id', async (req, res) => {
  const result = updateUserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({ error: { code: 'VALIDATION_FAILED',
      message: 'Request validation failed',
      details: result.error.flatten().fieldErrors,
      traceId: req.traceId } });
  }
  const updated = await db.users.update({ where: { id: req.params.id }, data: result.data });
  return res.status(200).json({ data: updated });
});
```

**Why:** `POST /getUser` puts a verb in the URL and returns `200` with `success: false` — client code must inspect the body to detect errors, making error handling inconsistent. REST design maps HTTP methods to semantics: `GET` reads, `PATCH` partially updates, `DELETE` removes. `204 No Content` signals success without a body, which is cleaner than `{ deleted: true }`.

---

### Example 2: Offset pagination breaking on concurrent writes

**Before** (triggers the skill):
```typescript
// ❌ Offset pagination — breaks when rows are inserted between pages
router.get('/v1/products', async (req, res) => {
  const page = parseInt(req.query.page as string) || 1;
  const perPage = parseInt(req.query.per_page as string) || 20;

  const products = await db.products.findMany({
    skip: (page - 1) * perPage,
    take: perPage,
    orderBy: { createdAt: 'desc' },
  });

  const total = await db.products.count();
  return res.json({
    products, // raw array, no envelope
    page,
    total,
    totalPages: Math.ceil(total / perPage),
  });
});
```

**After** (skill-compliant):
```typescript
// ✅ Cursor pagination — stable regardless of concurrent inserts
interface CursorPayload { createdAt: string; id: string; }

function decodeCursor(cursor: string): CursorPayload {
  return JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
}

function encodeCursor(item: { createdAt: Date; id: string }): string {
  return Buffer.from(JSON.stringify({
    createdAt: item.createdAt.toISOString(), id: item.id,
  })).toString('base64url');
}

router.get('/v1/products', async (req, res) => {
  const params = listProductsSchema.safeParse(req.query);
  if (!params.success) {
    return res.status(422).json({ error: { code: 'VALIDATION_FAILED',
      message: 'Invalid query parameters', traceId: req.traceId } });
  }

  const { limit, cursor } = params.data; // limit max 100
  const decoded = cursor ? decodeCursor(cursor) : null;

  const products = await db.products.findMany({
    take: limit + 1, // fetch one extra to detect hasMore
    where: decoded ? {
      OR: [
        { createdAt: { lt: new Date(decoded.createdAt) } },
        { createdAt: new Date(decoded.createdAt), id: { gt: decoded.id } },
      ],
    } : undefined,
    orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    select: { id: true, name: true, priceCents: true, createdAt: true },
  });

  const hasMore = products.length > limit;
  const data = hasMore ? products.slice(0, limit) : products;
  const lastItem = data.at(-1);

  return res.status(200).json({
    data,
    pagination: {
      nextCursor: hasMore && lastItem ? encodeCursor(lastItem) : null,
      hasMore,
      limit,
    },
  });
});
```

**Why:** Offset pagination skips or duplicates items when rows are inserted between page requests. A user scrolling an infinite list on page 3 will miss newly added items that pushed previous items to a different offset. Cursor pagination uses a stable position (last-seen `createdAt` + `id` tie-breaker) that stays valid regardless of concurrent writes.

---

### Example 3: POST endpoint without idempotency

**Before** (triggers the skill):
```typescript
// ❌ No idempotency — network retry creates duplicate orders
router.post('/v1/orders', async (req, res) => {
  const order = await db.orders.create({
    data: {
      userId: req.user.id,
      items: req.body.items,
      totalCents: calculateTotal(req.body.items),
    },
  });

  await stripe.charges.create({
    amount: order.totalCents,
    currency: 'ils',
    customer: req.user.stripeId,
  });

  return res.status(201).json(order);
  // If client retries on 5xx → duplicate order + double charge
});
```

**After** (skill-compliant):
```typescript
// ✅ Idempotency key prevents duplicate orders on retry
router.post('/v1/orders', async (req, res) => {
  const idempotencyKey = req.headers['idempotency-key'] as string | undefined;

  if (idempotencyKey) {
    const cached = await cache.get(`idem:order:${idempotencyKey}`);
    if (cached) {
      // Return identical response as original request
      return res.status(cached.status).json(cached.body);
    }
  }

  const result = createOrderSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({ error: { code: 'VALIDATION_FAILED',
      message: 'Order validation failed',
      details: result.error.flatten().fieldErrors,
      traceId: req.traceId } });
  }

  const order = await db.$transaction(async (tx) => {
    const created = await tx.orders.create({
      data: { userId: req.user.id, items: result.data.items,
               totalCents: calculateTotal(result.data.items) },
    });
    await stripe.charges.create(
      { amount: created.totalCents, currency: 'ils', customer: req.user.stripeId },
      { idempotencyKey: idempotencyKey ?? created.id } // Stripe also deduplicates
    );
    return created;
  });

  const responseBody = { data: order };

  if (idempotencyKey) {
    await cache.set(`idem:order:${idempotencyKey}`, { status: 201, body: responseBody },
                   { ttl: 86400 }); // 24h TTL for retry window
  }

  res.setHeader('Location', `/v1/orders/${order.id}`);
  return res.status(201).json(responseBody);
});
```

**Why:** Without an idempotency key, a client that retries after a network timeout can create two orders and charge the card twice. The client generates a UUID, sends it as `Idempotency-Key`, and the server caches the response for 24 hours — any retry with the same key gets the identical `201 Created` response without re-executing the mutation.

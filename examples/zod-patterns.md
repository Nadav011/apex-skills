# zod-patterns — Real-World Examples

The skill enforces Zod 4 validation patterns: schema-first design at every system boundary, `safeParse` over `parse` in handlers, transforms and refinements for business rules, and the Result pattern for typed error propagation.

## Before / After

### Example 1: Unsafe cast instead of schema validation

**Before** (triggers the skill):
```typescript
// ❌ Unsafe casts — type errors at runtime, not compile time
interface CreateOrderBody {
  customerId: string;
  items: { productId: string; quantity: number }[];
  couponCode?: string;
}

export async function POST(request: Request) {
  // Trusts API client completely — no runtime validation
  const body = await request.json() as CreateOrderBody;

  // If body.items is undefined → TypeError: Cannot read properties of undefined
  // If body.customerId is a number → silent type coercion downstream
  // If quantity is "five" → NaN in calculation
  const total = body.items.reduce((sum, item) => sum + item.quantity * getPrice(item.productId), 0);
  const order = await createOrder({ customerId: body.customerId, total, items: body.items });
  return Response.json(order, { status: 201 });
}
```

**After** (skill-compliant):
```typescript
// ✅ Zod schema validates and types the boundary simultaneously
import { z } from 'zod';

const createOrderSchema = z.object({
  customerId: z.string().uuid('Customer ID must be a valid UUID'),
  items: z.array(z.object({
    productId: z.string().uuid(),
    quantity: z.number().int().positive().max(100, 'Max 100 units per item'),
  })).min(1, 'At least one item required'),
  couponCode: z.string().regex(/^[A-Z0-9]{6,10}$/).optional(),
});

type CreateOrderBody = z.infer<typeof createOrderSchema>; // type derived from schema

export async function POST(request: Request) {
  let raw: unknown;
  try { raw = await request.json(); }
  catch { return Response.json({ error: 'Invalid JSON' }, { status: 400 }); }

  const result = createOrderSchema.safeParse(raw);
  if (!result.success) {
    return Response.json(
      { error: 'Validation failed', details: result.error.flatten().fieldErrors },
      { status: 422 }
    );
  }

  // result.data is fully typed — TypeScript knows quantity is a positive integer
  const { customerId, items, couponCode } = result.data;
  const total = items.reduce((sum, item) => sum + item.quantity * getPrice(item.productId), 0);
  const order = await createOrder({ customerId, total, items, couponCode });
  return Response.json({ data: order }, { status: 201 });
}
```

**Why:** `as CreateOrderBody` tells TypeScript "trust me" — no actual runtime check happens. When a mobile client sends `quantity: "2"` (string) or omits `items` entirely, the code silently produces `NaN` totals or crashes with an unhandled `TypeError`. Zod's `safeParse` validates the shape and types at runtime, returning a typed `result.data` that is correct by construction.

---

### Example 2: Transform and refine for business-rule validation

**Before** (triggers the skill):
```typescript
// ❌ Manual validation scattered through business logic
export async function POST(request: Request) {
  const body = await request.json();

  // Manual validation — easy to miss, hard to reuse
  if (!body.email || typeof body.email !== 'string') {
    return Response.json({ error: 'Email required' }, { status: 400 });
  }
  if (!body.password || body.password.length < 8) {
    return Response.json({ error: 'Password too short' }, { status: 400 });
  }
  if (!body.birthDate) {
    return Response.json({ error: 'Birth date required' }, { status: 400 });
  }
  // Is the user 18+? Manual calculation, no reuse
  const age = new Date().getFullYear() - new Date(body.birthDate).getFullYear();
  if (age < 18) {
    return Response.json({ error: 'Must be 18+' }, { status: 400 });
  }

  await createAccount({ email: body.email, password: body.password, birthDate: body.birthDate });
  return Response.json({ success: true });
}
```

**After** (skill-compliant):
```typescript
// ✅ Business rules encoded in schema — reusable, composable, self-documenting
import { z } from 'zod';

const registerSchema = z.object({
  email: z.string().email('Must be a valid email address'),
  password: z
    .string()
    .min(8, 'Minimum 8 characters')
    .regex(/[A-Z]/, 'Must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Must contain at least one number'),
  birthDate: z
    .string()
    .date('Must be a valid date (YYYY-MM-DD)')
    .transform(s => new Date(s))  // string → Date at parse time
    .refine(
      d => {
        const age = Math.floor((Date.now() - d.getTime()) / (365.25 * 24 * 3600 * 1000));
        return age >= 18;
      },
      { message: 'Must be 18 years of age or older' }
    ),
  role: z.enum(['user', 'vendor']).default('user'),
  // Confirm password check using superRefine for cross-field validation
  confirmPassword: z.string(),
}).superRefine((data, ctx) => {
  if (data.password !== data.confirmPassword) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['confirmPassword'],
      message: 'Passwords do not match',
    });
  }
});

export async function POST(request: Request) {
  const result = registerSchema.safeParse(await request.json().catch(() => ({})));
  if (!result.success) {
    return Response.json({ error: result.error.flatten().fieldErrors }, { status: 422 });
  }
  // result.data.birthDate is already a Date object (transformed)
  // result.data.role defaults to 'user' if not provided
  await createAccount(result.data);
  return Response.json({ success: true });
}
```

**Why:** Manual validation scattered through handlers is fragile — it's easy to miss a check on a new endpoint. Encoding business rules in the schema means the same `registerSchema` can be reused on the client (React Hook Form), server (API route), and in tests. `.transform()` converts types at parse time (string → Date), so the rest of the code works with strongly-typed values.

---

### Example 3: Result pattern for typed error propagation

**Before** (triggers the skill):
```typescript
// ❌ Zod parse throws — callers must use try/catch and lose type information
async function parseWebhookEvent(body: unknown) {
  const event = WebhookEventSchema.parse(body); // throws ZodError on invalid input
  // Caller cannot tell the difference between:
  // - ZodError (invalid payload from webhook provider — expected)
  // - DatabaseError (infra failure — unexpected)
  return event;
}

// Caller must catch everything together
try {
  const event = await parseWebhookEvent(rawBody);
} catch (err) {
  // Is this a validation error or a system failure?
  // The type is unknown — fallback to (err as Error).message
  return Response.json({ error: 'Failed' }, { status: 500 });
}
```

**After** (skill-compliant):
```typescript
// ✅ Result pattern — caller knows exactly which error type to handle
import { z } from 'zod';
import type { ZodError } from 'zod';

type Result<T, E = Error> =
  | { ok: true; data: T }
  | { ok: false; error: E };

function parseWebhookEvent(body: unknown): Result<WebhookEvent, ZodError> {
  const result = WebhookEventSchema.safeParse(body);
  if (!result.success) {
    return { ok: false, error: result.error }; // ZodError with all field details
  }
  return { ok: true, data: result.data };
}

export async function POST(request: Request) {
  const rawBody = await request.text();

  // Verify Stripe signature before parsing
  let body: unknown;
  try {
    body = JSON.parse(rawBody);
  } catch {
    return Response.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const parsed = parseWebhookEvent(body);
  if (!parsed.ok) {
    // TypeScript knows parsed.error is ZodError — access .flatten() directly
    logger.warn({ issues: parsed.error.flatten() }, 'Invalid webhook payload');
    return Response.json({ error: 'Invalid payload' }, { status: 400 });
  }

  // TypeScript knows parsed.data is WebhookEvent
  try {
    await processWebhookEvent(parsed.data);
    return Response.json({ received: true });
  } catch (err) {
    // Only system failures reach here — clearly distinguishable from validation errors
    logger.error({ err, eventType: parsed.data.type }, 'Webhook processing failed');
    return Response.json({ error: 'Processing failed' }, { status: 500 });
  }
}
```

**Why:** Using `schema.parse()` (throwing) in a service function forces every caller to use `try/catch` and then inspect the error with `instanceof ZodError` to distinguish validation failures from system failures. The `Result<T, E>` pattern makes the error type part of the function's return type — TypeScript enforces that the caller handles both cases, and the exact error type is known without runtime inspection.

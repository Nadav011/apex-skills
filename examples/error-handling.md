# error-handling — Real-World Examples

The skill enforces robust TypeScript error handling: typed error classes, Result pattern for expected failures, no silent catch blocks, propagation with `{ cause }`, and user-facing vs. log-only message separation.

## Before / After

### Example 1: Silent catch and unsafe error exposure

**Before** (triggers the skill):
```typescript
// ❌ Silent swallow + raw error message leaked to client
export async function sendInvoice(orderId: string) {
  try {
    const order = await db.orders.findUnique({ where: { id: orderId } });
    await emailService.send({ to: order!.email, template: 'invoice', data: order });
    return { success: true };
  } catch (e) {
    // silent swallow — developer never knows email delivery failed
  }
}

// Route handler leaking internal error
app.use((err: unknown, req: Request, res: Response) => {
  res.status(500).json({
    error: (err as Error).message, // may contain SQL, file path, or stack trace
    stack: (err as Error).stack,   // full stack trace in production response
  });
});
```

**After** (skill-compliant):
```typescript
// ✅ Every catch block logs + re-throws or returns error; client gets safe message
import { logger } from '@/lib/logger';
import { AppError, NotFoundError } from '@/lib/errors';

export async function sendInvoice(orderId: string): Promise<{ success: true }> {
  const order = await db.orders.findUnique({ where: { id: orderId } });
  if (!order) throw new NotFoundError('Order', orderId);

  try {
    await emailService.send({ to: order.email, template: 'invoice', data: order });
    return { success: true };
  } catch (err) {
    // Intentionally non-fatal: order is placed, email can be retried.
    // Log with full context for ops team — never silently discard.
    logger.warn({ err, orderId, email: order.email }, 'Invoice email delivery failed');
    throw new AppError('Failed to send invoice email', 'EMAIL_DELIVERY_FAILED', 503, { cause: err });
  }
}

// Route error handler — safe external messages
app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
  const appErr = err instanceof AppError ? err : null;
  const status = appErr?.statusCode ?? 500;

  // Full details go to structured log only
  logger.error({ err, traceId: req.traceId, url: req.url }, 'Request failed');

  // Client gets code + safe message — never stack traces or SQL
  res.status(status).json({
    error: {
      code:    appErr?.code ?? 'INTERNAL_ERROR',
      message: status < 500 ? (appErr?.message ?? 'Bad request')
                             : 'An unexpected error occurred',
    },
  });
});
```

**Why:** An empty `catch` block means a failed invoice email is invisible — no alert, no retry, no incident. The route handler mistake is equally dangerous: `(err as Error).message` on a Prisma error contains the raw SQL query and table names. Attackers use this to map your database schema. The fix separates internal logging from the safe client response.

---

### Example 2: Stringly-typed error discrimination

**Before** (triggers the skill):
```typescript
// ❌ Checking error.message strings — brittle and breaks when messages change
async function createUser(email: string) {
  try {
    return await db.users.create({ data: { email } });
  } catch (err) {
    if ((err as Error).message.includes('unique constraint')) {
      return { error: 'Email already registered' };
    }
    if ((err as Error).message.includes('not found')) {
      return { error: 'Resource not found' };
    }
    throw err; // unknown errors propagate without context
  }
}

// Caller cannot tell which error type to handle without reading source
const result = await createUser(email);
if (result?.error) { /* what type of error was this? */ }
```

**After** (skill-compliant):
```typescript
// ✅ Typed error subclasses + Result pattern — discriminated by instanceof
export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class ConflictError extends AppError {
  constructor(resource: string, options?: ErrorOptions) {
    super(`${resource} already exists`, 'CONFLICT', 409, options);
  }
}

type Result<T, E = AppError> = { ok: true; value: T } | { ok: false; error: E };

async function createUser(email: string): Promise<Result<User, ConflictError | AppError>> {
  try {
    const user = await db.users.create({ data: { email } });
    return { ok: true, value: user };
  } catch (err) {
    // Prisma unique constraint violation has a stable error code
    if (isPrismaUniqueConstraintError(err)) {
      return { ok: false, error: new ConflictError('User', { cause: err }) };
    }
    // Unknown errors get wrapped with context and propagated
    throw new AppError(
      `Failed to create user with email "${email}"`,
      'DB_CREATE_FAILED',
      500,
      { cause: err },
    );
  }
}

// Caller: TypeScript knows exactly which error types to handle
const result = await createUser(email);
if (!result.ok) {
  if (result.error instanceof ConflictError) {
    return res.status(409).json({ error: { code: 'CONFLICT', message: 'Email already registered' } });
  }
  throw result.error; // escalate unknown errors
}
```

**Why:** `message.includes('unique constraint')` breaks the moment the database or ORM changes its error message format — a silent regression. Typed error subclasses are discriminated with `instanceof`, which TypeScript understands, giving compile-time exhaustiveness checking on error branches. The `Result<T, E>` pattern forces callers to handle both cases.

---

### Example 3: Missing error cause chain and lost context

**Before** (triggers the skill):
```typescript
// ❌ Re-throwing without cause — original error and stack trace are gone
async function getUserOrders(userId: string) {
  try {
    const orders = await db.orders.findMany({ where: { userId } });
    return orders;
  } catch {
    throw new Error('Failed to get orders'); // original error discarded
  }
}

async function generateReport(userId: string) {
  try {
    const orders = await getUserOrders(userId);
    return buildReport(orders);
  } catch {
    throw new Error('Report generation failed'); // no idea what actually failed
  }
}
// At the top level: "Report generation failed" — no SQL error, no userId, nothing
```

**After** (skill-compliant):
```typescript
// ✅ Error cause chain preserves full context through the call stack
async function getUserOrders(userId: string): Promise<Order[]> {
  try {
    return await db.orders.findMany({ where: { userId } });
  } catch (err) {
    // Wrap with context — preserve original error as cause
    throw new AppError(
      `Failed to fetch orders for user "${userId}"`,
      'DB_QUERY_FAILED',
      500,
      { cause: err }, // native Error cause chain (Node 16.9+)
    );
  }
}

async function generateReport(userId: string): Promise<Report> {
  try {
    const orders = await getUserOrders(userId);
    return buildReport(orders);
  } catch (err) {
    if (err instanceof AppError) throw err; // already has context — don't re-wrap
    throw new AppError(
      `Report generation failed for user "${userId}"`,
      'REPORT_FAILED',
      500,
      { cause: err },
    );
  }
}

// Printing the full cause chain at the top-level handler
function formatErrorChain(err: unknown): string {
  if (!(err instanceof Error)) return String(err);
  const parts = [err.message];
  let cause = err.cause;
  while (cause instanceof Error) {
    parts.push(`  caused by: ${cause.message}`);
    cause = (cause as Error & { cause?: unknown }).cause;
  }
  return parts.join('\n');
}
// Output: "Report generation failed for user "usr_123""
//           caused by: "Failed to fetch orders for user "usr_123""
//           caused by: "connection timeout after 30000ms"
```

**Why:** Discarding the original error with `throw new Error('...')` is like shredding the incident report. The `{ cause: err }` option added in Node.js 16.9 preserves the full chain — on-call engineers see the root cause (connection timeout) instead of the symptom (report generation failed), cutting mean-time-to-resolution dramatically.

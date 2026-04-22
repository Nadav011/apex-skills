# logging-patterns — Real-World Examples

The skill enforces structured JSON logging: no bare `console.log`, trace IDs on every request, correct log levels, PII redaction, and boundary logging at HTTP/DB/external-API edges.

## Before / After

### Example 1: Unstructured console.log replacing structured logging

**Before** (triggers the skill):
```typescript
// ❌ Unstructured logs — unsearchable, no context, PII exposed
export async function POST(request: Request) {
  const body = await request.json();
  console.log('Processing payment for user:', body.email); // PII in log!
  console.log('Amount:', body.amount);

  try {
    const payment = await stripe.paymentIntents.create({ amount: body.amount });
    console.log('Payment created:', payment.id);
    return Response.json({ id: payment.id });
  } catch (err) {
    console.error('Payment failed:', err); // full Stripe error object — may contain PII
    return Response.json({ error: 'failed' }, { status: 500 });
  }
}
// In Datadog/CloudWatch these are plain text strings with no indexable fields
// "Processing payment for user: alice@example.com" — GDPR violation
```

**After** (skill-compliant):
```typescript
// ✅ Structured logger — every field is independently queryable, PII redacted
import { logger } from '@/lib/logger'; // pino with redact config

export async function POST(request: Request) {
  const body = paymentSchema.parse(await request.json());
  // Log userId, not email — internal identifier is safe
  logger.info({ userId: body.userId, amountCents: body.amountCents }, 'Payment intent starting');

  try {
    const payment = await stripe.paymentIntents.create({
      amount: body.amountCents,
      currency: 'ils',
    });
    logger.info({ paymentIntentId: payment.id, status: payment.status }, 'Payment intent created');
    return Response.json({ id: payment.id });
  } catch (err) {
    logger.error({ err, userId: body.userId }, 'Payment intent creation failed');
    return Response.json({ error: 'Payment processing failed' }, { status: 500 });
  }
}
// In Datadog: filter by userId OR amountCents OR paymentIntentId OR level=error
// JSON: {"level":"info","time":1714000000,"userId":"usr_123","amountCents":9900,"msg":"Payment intent starting"}
```

**Why:** `console.log('Processing payment for user:', body.email)` creates a plain-text string in your logs that contains a customer email address — a GDPR violation and a PII exposure. Structured logging keeps the email out of logs entirely (use internal IDs), and makes every field independently filterable, alertable, and exportable in log aggregators.

---

### Example 2: Missing trace ID — impossible to correlate request logs

**Before** (triggers the skill):
```typescript
// ❌ No trace ID — can't find all logs for a single failed request
// Log output for a failed order:
// [INFO]  Fetching user profile
// [INFO]  Validating cart items
// [ERROR] Database write failed: connection timeout
// [INFO]  Fetching user profile     ← from a different request!
// [INFO]  Sending confirmation email
// Impossible to tell which lines belong to which request
```

**After** (skill-compliant):
```typescript
// ✅ Trace ID attached via AsyncLocalStorage — propagated automatically
// trace-context.ts
import { AsyncLocalStorage } from 'node:async_hooks';
const storage = new AsyncLocalStorage<{ traceId: string }>();
export const getTraceContext = () => storage.getStore();
export const runWithTrace = <T>(ctx: { traceId: string }, fn: () => T) =>
  storage.run(ctx, fn);

// middleware/trace.ts
export function traceMiddleware(req: Request, res: Response, next: NextFunction) {
  const traceId = req.headers['x-trace-id'] as string ?? crypto.randomUUID();
  res.setHeader('x-trace-id', traceId);
  runWithTrace({ traceId }, next);
}

// logger.ts — injects traceId into every call automatically
const baseLogger = pino({ level: process.env.LOG_LEVEL ?? 'info' });
export const logger = {
  info: (obj: object, msg: string) =>
    baseLogger.info({ ...getTraceContext(), ...obj }, msg),
  error: (obj: object, msg: string) =>
    baseLogger.error({ ...getTraceContext(), ...obj }, msg),
  warn: (obj: object, msg: string) =>
    baseLogger.warn({ ...getTraceContext(), ...obj }, msg),
};

// Log output with trace IDs:
// {"traceId":"01HX4Z...","userId":"usr_123","msg":"Fetching user profile"}
// {"traceId":"01HX4Z...","userId":"usr_123","msg":"Validating cart items"}
// {"traceId":"01HX4Z...","userId":"usr_123","level":"error","msg":"DB write failed"}
// filter by traceId=01HX4Z... → see exactly the 3 log lines for this request
```

**Why:** Without a trace ID, a failed request in production produces disconnected log lines that are interspersed with logs from other concurrent requests. `AsyncLocalStorage` propagates the trace ID through every async call in the request chain without threading it manually through every function argument. Support can give customers their `X-Trace-Id` response header, and ops can find every log line in seconds.

---

### Example 3: Wrong log levels causing alert fatigue or blind spots

**Before** (triggers the skill):
```typescript
// ❌ Everything logged at error level — alert fatigue + no signal
async function getUserProfile(userId: string) {
  try {
    const profile = await db.profiles.findUnique({ where: { id: userId } });
    if (!profile) {
      logger.error({ userId }, 'Profile not found'); // not an error — expected condition
      return null;
    }
    logger.error({ userId }, 'Profile retrieved successfully'); // definitely not error
    return profile;
  } catch (err) {
    logger.info({ err, userId }, 'Failed to fetch profile'); // this IS an error
    return null; // swallows the failure
  }
}
// PagerDuty fires for every 404 profile lookup
// Actual DB failures logged at info — never triggers alerts
```

**After** (skill-compliant):
```typescript
// ✅ Correct levels: debug=dev only | info=business events | warn=unexpected | error=failures
async function getUserProfile(userId: string): Promise<Profile | null> {
  logger.debug({ userId }, 'Fetching user profile'); // dev diagnostic — off in production

  try {
    const start = Date.now();
    const profile = await db.profiles.findUnique({ where: { id: userId } });
    const durationMs = Date.now() - start;

    if (durationMs > 200) {
      logger.warn({ userId, durationMs }, 'Slow profile query'); // unexpected but non-fatal
    }

    if (!profile) {
      // Not an error — expected condition when user hasn't completed onboarding
      logger.info({ userId }, 'Profile not found — user may not have completed onboarding');
      return null;
    }

    logger.debug({ userId, durationMs }, 'Profile fetched successfully'); // too noisy for info
    return profile;
  } catch (err) {
    // This IS a failure — something went wrong in the system
    logger.error({ err, userId }, 'Failed to fetch user profile');
    throw err; // re-throw — don't swallow real errors
  }
}
// Production log level: info → debug lines suppressed
// Alerts fire only on logger.error — genuine system failures
// Slow queries surface as warns — actionable but not paging
```

**Why:** Using `error` for expected conditions (profile not found) triggers alerts every time an unenrolled user logs in — dozens of false alarms per hour. When actual database failures are logged at `info`, they never trigger alerts. Correct level calibration means the on-call engineer is woken up only for real incidents, and slow queries surface as warnings for later investigation.

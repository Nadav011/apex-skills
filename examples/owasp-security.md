# owasp-security — Real-World Examples

The skill applies OWASP Top 10:2025 and ASVS 5.0 to code review. Each example
below maps to a specific vulnerability class. The before/after gap is the
difference between shipping a CVE and shipping production-grade code.

## Before / After

### Example 1: SQL injection + broken access control (A01 + A05)

**Before** (triggers the skill):
```typescript
// ❌ A05 Injection: string-concatenated query
// ❌ A01 Broken Access Control: no ownership check
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const invoiceId = searchParams.get('id');

  // Direct string interpolation — attacker sends id=1 OR 1=1
  const invoice = await db.query(
    `SELECT * FROM invoices WHERE id = ${invoiceId}`
  );

  // No check that this invoice belongs to the requesting user
  return Response.json(invoice.rows[0]);
}
```

**After** (skill-compliant):
```typescript
// ✅ Parameterized query + ownership enforcement
import { getServerSession } from 'next-auth';
import { z } from 'zod';

const QuerySchema = z.object({ id: z.string().uuid() });

export async function GET(req: Request) {
  const session = await getServerSession();
  if (!session?.user?.id) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const parse = QuerySchema.safeParse(
    Object.fromEntries(new URL(req.url).searchParams)
  );
  if (!parse.success) {
    return Response.json({ error: 'Invalid request' }, { status: 400 });
  }

  // Parameterized query — no injection possible
  // Ownership check in the WHERE clause — IDOR impossible
  const invoice = await db.query(
    'SELECT * FROM invoices WHERE id = $1 AND user_id = $2',
    [parse.data.id, session.user.id]
  );

  if (!invoice.rows[0]) {
    return Response.json({ error: 'Not found' }, { status: 404 });
  }
  return Response.json(invoice.rows[0]);
}
```

**Why:** String interpolation into SQL is direct injection. The missing
ownership check is an Insecure Direct Object Reference (IDOR) — any
authenticated user could retrieve any other user's invoice by guessing IDs.
Both are in the OWASP Top 10 and both are trivially exploitable.

---

### Example 2: Weak password hashing + fail-open auth check (A04 + A07)

**Before** (triggers the skill):
```python
# ❌ A04 Cryptographic Failure: MD5 for password storage
# ❌ A07 Auth Failure: exception causes fail-open (grants access on error)
import hashlib
from flask import request, jsonify

def hash_password(password: str) -> str:
    return hashlib.md5(password.encode()).hexdigest()  # cracked in seconds

def verify_password(stored_hash: str, provided: str) -> bool:
    return stored_hash == hashlib.md5(provided.encode()).hexdigest()

def check_permission(user_id: int, resource_id: int) -> bool:
    try:
        result = auth_service.check(user_id, resource_id)
        return result
    except Exception:
        return True  # ← DANGEROUS: error grants access instead of denying it

@app.route('/api/document/<int:doc_id>')
def get_document(doc_id: int):
    user_id = get_current_user_id()
    if check_permission(user_id, doc_id):  # fails open if auth service is down
        return jsonify(db.get_document(doc_id))
```

**After** (skill-compliant):
```python
# ✅ Argon2 for password hashing + fail-closed on auth errors
import uuid
import logging
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from flask import request, jsonify, abort

ph = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=2)
logger = logging.getLogger(__name__)

def hash_password(password: str) -> str:
    return ph.hash(password)  # Argon2id with configured cost factors

def verify_password(stored_hash: str, provided: str) -> bool:
    try:
        return ph.verify(stored_hash, provided)
    except VerifyMismatchError:
        return False

def check_permission(user_id: int, resource_id: int) -> bool:
    try:
        return auth_service.check(user_id, resource_id)
    except Exception as e:
        error_id = uuid.uuid4()
        logger.error(f"Auth check failed [{error_id}]: {e}", exc_info=True)
        return False  # ← Fail-closed: deny on any error

@app.route('/api/document/<int:doc_id>')
def get_document(doc_id: int):
    user_id = get_current_user_id()
    if not check_permission(user_id, doc_id):
        abort(403)
    return jsonify(db.get_document(doc_id))
```

**Why:** MD5 hashes are cracked by rainbow tables in milliseconds — entire
breach databases are pre-computed. Argon2id is the OWASP/ASVS 5.0 recommended
algorithm with tunable cost. The fail-open pattern is equally dangerous: if the
auth service is unavailable or throws, `return True` hands every resource to
every caller.

---

### Example 3: Exposed stack traces + missing rate limiting (A06 + A10)

**Before** (triggers the skill):
```typescript
// ❌ A10 Exception Handling: raw error sent to client (leaks internals)
// ❌ A06 Insecure Design: no rate limiting on auth endpoint
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  const { email, password } = await req.json();

  try {
    const user = await db.users.findUnique({ where: { email } });
    if (!user || user.password !== password) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }
    const token = generateSessionToken(user.id);
    return NextResponse.json({ token });
  } catch (err) {
    // Sends full stack trace, DB connection string, and query to the browser
    return NextResponse.json({ error: String(err) }, { status: 500 });
  }
}
```

**After** (skill-compliant):
```typescript
// ✅ Structured error handling + rate limiting + timing-safe comparison
import { NextRequest, NextResponse } from 'next/server';
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';
import { timingSafeEqual } from 'crypto';
import { randomUUID } from 'crypto';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(5, '1 m'), // 5 attempts per minute per IP
});

export async function POST(req: NextRequest) {
  const ip = req.headers.get('x-forwarded-for') ?? '127.0.0.1';
  const { success } = await ratelimit.limit(ip);
  if (!success) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  try {
    const { email, password } = await req.json();
    if (!email || !password) {
      return NextResponse.json({ error: 'Missing credentials' }, { status: 400 });
    }

    const user = await db.users.findUnique({ where: { email } });
    const valid = user && await verifyPassword(user.passwordHash, password);
    if (!valid) {
      // Same response for "user not found" and "wrong password" — no enumeration
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    const token = generateSessionToken(user.id);
    return NextResponse.json({ token });
  } catch (err) {
    const errorId = randomUUID();
    console.error({ errorId, msg: 'Login error', err }); // structured log with ID
    // Client gets a reference ID, not the stack trace
    return NextResponse.json({ error: 'Internal error', id: errorId }, { status: 500 });
  }
}
```

**Why:** Sending `String(err)` to the client leaks database table names,
connection strings, and internal paths — perfect reconnaissance for an attacker.
Without rate limiting, the endpoint is open to credential stuffing: automated
tools try millions of username/password pairs. The fix adds both defenses plus
consistent error responses to prevent user enumeration.

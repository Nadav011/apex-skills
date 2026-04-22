# typescript-strict — Real-World Examples

The skill eliminates `: any`, enforces runtime validation at boundaries, applies
branded types for IDs, and ensures the tsconfig is genuinely strict. Each
pattern here represents a class of silent bugs that compiles without warning
until it crashes in production.

## Before / After

### Example 1: API response typed as `any` — caller is completely unguided

**Before** (triggers the skill):
```typescript
// ❌ any propagates through the entire call chain
async function getUser(id: string): Promise<any> {
  const res = await fetch(`/api/users/${id}`);
  const data = await res.json(); // returns any
  return data;
}

async function displayUser(id: string) {
  const user = await getUser(id);
  // TypeScript does not warn on any of these:
  console.log(user.nam);          // typo — undefined at runtime
  console.log(user.role.toUpperCase()); // crashes if role is null
  const greeting = `Hello ${user.firstName}`; // wrong field name
}
```

**After** (skill-compliant):
```typescript
import { z } from 'zod';

// Single source of truth: schema defines type AND validates at runtime
const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
  role: z.enum(['user', 'admin']),
});
type User = z.infer<typeof UserSchema>;

async function getUser(id: string): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`Failed to fetch user: ${res.status}`);
  const raw = await res.json();
  return UserSchema.parse(raw); // throws ZodError with field-level details on mismatch
}

async function displayUser(id: string) {
  const user = await getUser(id);
  console.log(user.name);             // autocomplete, typos caught at compile time
  console.log(user.role.toUpperCase()); // role is string, always safe
  const greeting = `Hello ${user.name}`; // correct field, no guessing
}
```

**Why:** `Promise<any>` silently disables the type checker for every downstream
call. Zod validates the shape at the actual runtime boundary (the API response)
and derives a TypeScript type from the schema — one source of truth, no drift.

---

### Example 2: Interchangeable IDs cause silent data corruption

**Before** (triggers the skill):
```typescript
// ❌ All IDs are plain string — wrong ID passed in, no error
type UserId = string;
type OrderId = string;
type ProductId = string;

async function cancelOrder(orderId: OrderId, userId: UserId) {
  await db.orders.update({ id: orderId, cancelledBy: userId });
}

// Caller swaps the arguments — TypeScript is silent
const currentUser = await getSession(); // currentUser.id is string
const order = await fetchOrder();       // order.id is string
await cancelOrder(currentUser.id, order.id); // ← arguments reversed, no error
```

**After** (skill-compliant):
```typescript
// ✅ Branded types make wrong-ID-type a compile error
type Brand<T, B> = T & { readonly __brand: B };
type UserId  = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

// Smart constructors: validate + brand at the system boundary
function toUserId(raw: string): UserId {
  if (!raw || !/^usr_[a-z0-9]+$/.test(raw)) throw new Error(`Invalid UserId: ${raw}`);
  return raw as UserId;
}
function toOrderId(raw: string): OrderId {
  if (!raw || !/^ord_[a-z0-9]+$/.test(raw)) throw new Error(`Invalid OrderId: ${raw}`);
  return raw as OrderId;
}

async function cancelOrder(orderId: OrderId, userId: UserId) {
  await db.orders.update({ id: orderId, cancelledBy: userId });
}

const currentUser = { id: toUserId('usr_abc123') };
const order       = { id: toOrderId('ord_xyz789') };
// cancelOrder(currentUser.id, order.id); // ← compile error: OrderId ≠ UserId
cancelOrder(order.id, currentUser.id);   // ✅ correct order enforced by types
```

**Why:** When all IDs are plain `string`, swapping arguments is invisible to the
compiler and causes silent data corruption at runtime. Branded types make ID
categories structurally distinct — the compiler catches transpositions
immediately.

---

### Example 3: Unsafe array access and missing tsconfig flags

**Before** (triggers the skill):
```typescript
// ❌ tsconfig missing critical strict flags
// tsconfig.json: { "strict": true }  — "strict" alone is not enough

interface Config {
  hosts: string[];
  timeoutMs?: number;
}

function buildConnections(config: Config) {
  // noUncheckedIndexedAccess not enabled:
  const primary = config.hosts[0];       // typed as string, but could be undefined
  const secondary = config.hosts[1];     // typed as string, but could be undefined
  return {
    primary: primary.toUpperCase(),   // crash when hosts is empty
    secondary: secondary.toUpperCase(), // crash when only one host
    // exactOptionalPropertyTypes not enabled:
    timeout: config.timeoutMs ?? 5000, // timeoutMs could be explicitly set to undefined
  };
}
```

**After** (skill-compliant):
```typescript
// ✅ tsconfig with all required strict flags
// tsconfig.json:
// {
//   "strict": true,
//   "noUncheckedIndexedAccess": true,     // arr[0] is T | undefined, not T
//   "exactOptionalPropertyTypes": true,   // {x?: string} ≠ {x: string | undefined}
//   "noImplicitReturns": true,
//   "noFallthroughCasesInSwitch": true
// }

interface Config {
  hosts: string[];
  timeoutMs?: number; // with exactOptionalPropertyTypes: truly optional, never undefined
}

function buildConnections(config: Config) {
  // noUncheckedIndexedAccess forces explicit undefined handling:
  const primary   = config.hosts[0];   // string | undefined
  const secondary = config.hosts[1];   // string | undefined

  if (!primary) throw new Error('At least one host is required');

  return {
    primary: primary.toUpperCase(),
    secondary: secondary?.toUpperCase() ?? primary.toUpperCase(), // safe fallback
    timeout: config.timeoutMs ?? 5000,
  };
}
```

**Why:** `"strict": true` in tsconfig enables six checks but misses two of the
most important ones. `noUncheckedIndexedAccess` exposes the array-out-of-bounds
class of bugs at compile time. `exactOptionalPropertyTypes` prevents treating an
explicitly-set `undefined` the same as an absent property. Together they
eliminate an entire category of silent runtime crashes.

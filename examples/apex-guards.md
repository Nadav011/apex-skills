# apex-guards — Real-World Examples

The skill enforces APEX behavioral guards before every file write: RTL violations, `any` types, hardcoded secrets, `console.*` calls, and large fixed dimensions — plus a pre-completion L10+ gate checking typecheck, lint, and tests.

## Before / After

### Example 1: Component with multiple guard violations blocked

**Before** (triggers the skill):
```tsx
// ❌ Pre-write guard fires: RTL violation + any type + console.log
const API_KEY = 'sk-ant-api03-xyz'; // SECRET — guard blocks this

interface Props {
  user: any; // BLOCKED: `: any` without // type-ok override
}

export function UserCard({ user }: Props) {
  console.log('rendering user', user); // BLOCKED: console.* in .tsx

  return (
    <div className="ml-4 border-l-2 pl-3 text-left"> {/* BLOCKED: RTL violations */}
      <span style={{ width: '600px' }}>{user.name}</span> {/* BLOCKED: large fixed dimension */}
    </div>
  );
}
```

**After** (skill-compliant):
```tsx
// ✅ All guards pass: typed, RTL-safe, no secrets, no console.log
import type { User } from '@/types';
import { logger } from '@/lib/logger';

interface Props {
  user: User; // Specific type — guard satisfied
}

export function UserCard({ user }: Props) {
  // Development tracing goes through structured logger, not console
  logger.debug({ userId: user.id }, 'Rendering UserCard');

  return (
    <div className="ms-4 border-s-2 ps-3 text-start"> {/* Logical RTL-safe classes */}
      <span className="max-w-lg">{user.name}</span> {/* Responsive, no fixed width */}
    </div>
  );
}
```

**Why:** The pre-write guard catches four distinct violations before any code reaches the codebase. Secrets can never be committed (gitleaks would catch them too, but the guard fires first). The `any` type would disable TypeScript checking for the entire component. RTL physical classes break Hebrew layout. `console.log` in production is blocked — structured logging is the only allowed path.

---

### Example 2: Pre-completion gate revealing failing checks

**Before** (triggers the skill):
```typescript
// Developer claims "done" — pre-completion gate runs and catches issues

// lib/orders.ts — missing return type, uses as-cast
export async function getOrder(id: string) { // missing return type annotation
  const raw = await fetch(`/api/orders/${id}`);
  const data = await raw.json() as Order; // unsafe cast without runtime validation
  return data;
}

// Missing: pnpm run typecheck output would show TS error:
// lib/orders.ts(4,40): error TS2352: Conversion of type 'any' may be a mistake.
// Missing: tests pass but coverage is 52% (below 70% threshold)
// Missing: ESLint reports 3 errors (console.log × 2, no-explicit-any × 1)
```

**After** (pre-completion gate passes):
```typescript
// lib/orders.ts — typed return, Zod-validated response
import { z } from 'zod';
import { env } from '@/lib/env';
import { logger } from '@/lib/logger';

const OrderSchema = z.object({
  id: z.string().uuid(),
  status: z.enum(['pending', 'confirmed', 'shipped', 'delivered']),
  totalCents: z.number().int().nonnegative(),
  createdAt: z.string().datetime(),
});

export type Order = z.infer<typeof OrderSchema>;

export async function getOrder(id: string): Promise<Order> {
  const res = await fetch(`${env.NEXT_PUBLIC_API_URL}/orders/${id}`);
  if (!res.ok) throw new Error(`Order fetch failed: ${res.status}`);

  const raw: unknown = await res.json();
  return OrderSchema.parse(raw); // runtime validation — no unsafe cast
}

// pnpm run typecheck: 0 errors ✅
// pnpm run lint:      0 errors ✅
// pnpm run test:      all pass, coverage 78% ✅
// RTL scan:           0 violations ✅
```

**Why:** The pre-completion gate enforces that "done" means all gates pass, not just "it runs on my machine." TypeScript without a return type annotation silently widens the return type. The `as Order` cast skips runtime validation — if the API changes shape, the app crashes at the call site with an unhelpful error. Zod parse fails immediately with a descriptive error at the boundary.

---

### Example 3: Knowledge capture during pattern discovery

**Before** (triggers the skill):
```typescript
// Developer discovers a non-obvious pattern and moves on without logging it
// ❌ No knowledge capture — the insight is lost after the session

// Discovered: Supabase realtime channels need explicit cleanup or they
// accumulate across HMR in development, causing duplicate event handlers.
// Discovered: The channel name must be unique per component instance.
function useRealtimeOrders(userId: string) {
  useEffect(() => {
    const channel = supabase.channel('orders');
    channel.on('postgres_changes', { event: '*', schema: 'public', table: 'orders',
      filter: `user_id=eq.${userId}` }, handleChange).subscribe();
    return () => { supabase.removeChannel(channel); }; // cleanup discovered necessary
  }, [userId]);
}
```

**After** (skill-compliant — knowledge captured):
```typescript
// ✅ Insight logged via apex-guards knowledge capture mechanism
// echo "LEARNED: Supabase realtime channels MUST use unique names per instance
// (e.g., orders-${userId}) and MUST be removed in useEffect cleanup.
// Without cleanup, HMR accumulates duplicate subscriptions emitting N× events."

// Saved to ~/.claude/knowledge/learned.jsonl for future recall

function useRealtimeOrders(userId: string) {
  useEffect(() => {
    // Channel name scoped to userId — prevents cross-instance collisions
    const channel = supabase.channel(`orders-${userId}`);
    channel
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'orders',
        filter: `user_id=eq.${userId}`,
      }, handleChange)
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [userId]);
}
```

**Why:** The knowledge capture mechanism turns one-time discoveries into persistent institutional memory. Without it, the next developer (or the same developer next month) rediscovers the same gotcha. The `echo "LEARNED: ..."` line feeds the vector knowledge base so semantic search can surface it when someone asks about Supabase realtime or HMR in future sessions.

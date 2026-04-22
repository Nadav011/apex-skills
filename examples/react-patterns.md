# react-patterns — Real-World Examples

The skill enforces React patterns for modern apps: Server vs Client Component decisions, `use client` pushed to leaf components, error boundaries with `error.tsx`, Suspense with skeleton fallbacks, and custom hook extraction.

## Before / After

### Example 1: useState in a Server Component context

**Before** (triggers the skill):
```tsx
// ❌ useState in a Server Component — build error or runtime crash
// app/products/page.tsx (no 'use client' directive)
import { useState } from 'react';

export default async function ProductsPage() {
  const [filter, setFilter] = useState('all'); // Error: hooks not allowed in SC
  const products = await db.products.findMany();

  return (
    <div>
      <select value={filter} onChange={e => setFilter(e.target.value)}>
        <option value="all">All</option>
        <option value="sale">Sale</option>
      </select>
      {products.map(p => <ProductCard key={p.id} product={p} />)}
    </div>
  );
}
// Next.js: "You're importing a component that needs useState.
// It only works in a Client Component but none of its parents are marked with 'use client'"
```

**After** (skill-compliant):
```tsx
// ✅ Server Component fetches data; Client island handles interactivity
// app/products/page.tsx — Server Component (no directive)
import { ProductFilter } from './product-filter'; // 'use client' lives here

export default async function ProductsPage() {
  // Server-side: direct DB access, zero client JS for this file
  const products = await db.products.findMany({
    orderBy: { name: 'asc' },
    select: { id: true, name: true, priceCents: true, category: true },
  });

  return (
    <div>
      {/* Pass all products to client; filtering happens in browser — no re-fetch */}
      <ProductFilter products={products} />
    </div>
  );
}

// app/products/product-filter.tsx — Client Component
'use client';
import { useState } from 'react';

export function ProductFilter({ products }: { products: Product[] }) {
  const [filter, setFilter] = useState('all');
  const visible = filter === 'all' ? products : products.filter(p => p.category === filter);

  return (
    <>
      <select value={filter} onChange={e => setFilter(e.target.value)}
              className="rounded border px-3 py-2">
        <option value="all">הכל</option>
        <option value="sale">במבצע</option>
      </select>
      <ul>{visible.map(p => <li key={p.id}>{p.name}</li>)}</ul>
    </>
  );
}
```

**Why:** `useState` requires the component tree to be hydrated on the client. Adding `'use client'` to the entire page sends the full product list, DB query logic, and layout to the browser bundle unnecessarily. The split keeps data fetching on the server and confines the interactive filter to the smallest possible client island.

---

### Example 2: No error boundary — unhandled async error shows blank screen

**Before** (triggers the skill):
```tsx
// ❌ No error.tsx — an unhandled fetch error shows a blank white page
// app/orders/page.tsx
export default async function OrdersPage() {
  const orders = await db.orders.findMany(); // if DB is down → white screen
  return (
    <ul>
      {orders.map(o => <li key={o.id}>{o.status}</li>)}
    </ul>
  );
}
// No loading.tsx — page is blank until query resolves
// No error.tsx — DB failure crashes the route segment silently
```

**After** (skill-compliant):
```tsx
// app/orders/loading.tsx — shown automatically during Server Component fetch
export default function OrdersLoading() {
  return (
    <ul aria-label="טוען הזמנות..." aria-busy="true">
      {Array.from({ length: 5 }).map((_, i) => (
        <li key={i} className="mb-3 h-16 animate-pulse rounded-lg bg-gray-100" />
      ))}
    </ul>
  );
}

// app/orders/error.tsx — segment-level error boundary (MUST be 'use client')
'use client';
import { useEffect } from 'react';

export default function OrdersError({
  error,
  reset,
}: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    // Log to Sentry — never expose raw error message in UI
    console.error('[OrdersPage error]', error.digest);
  }, [error]);

  return (
    <div role="alert" className="rounded-lg border border-red-200 p-6 text-center">
      <p className="font-medium text-red-700">לא ניתן לטעון את ההזמנות</p>
      <button
        onClick={reset}
        className="mt-3 rounded bg-red-600 px-4 py-2 text-sm text-white"
      >
        נסה שוב
      </button>
    </div>
  );
}

// app/orders/page.tsx — clean Server Component
export default async function OrdersPage() {
  const orders = await db.orders.findMany({ orderBy: { createdAt: 'desc' } });
  return (
    <ul>
      {orders.map(o => (
        <li key={o.id} className="mb-3 rounded-lg border p-4">{o.status}</li>
      ))}
    </ul>
  );
}
```

**Why:** Without `loading.tsx` the browser shows nothing during the server fetch. Without `error.tsx` an unhandled exception produces Next.js's default error page — which shows stack traces in development and a blank page in production. `error.tsx` MUST be a `'use client'` component because React error boundaries use lifecycle methods only available on the client.

---

### Example 3: Duplicated fetch logic across components — extract to custom hook

**Before** (triggers the skill):
```tsx
// ❌ Same fetch logic copy-pasted in two components — state diverges silently
function OrderStatusBadge({ orderId }: { orderId: string }) {
  const [order, setOrder] = useState<Order | null>(null);
  useEffect(() => {
    fetch(`/api/orders/${orderId}`).then(r => r.json()).then(setOrder);
  }, [orderId]);
  return <span>{order?.status ?? '...'}</span>;
}

function OrderTimeline({ orderId }: { orderId: string }) {
  const [order, setOrder] = useState<Order | null>(null);
  // Exact same logic — but no error handling, no loading state
  useEffect(() => {
    fetch(`/api/orders/${orderId}`).then(r => r.json()).then(setOrder);
  }, [orderId]);
  return <div>{order?.events?.map(e => <p key={e.id}>{e.label}</p>)}</div>;
}
// Two separate fetch calls for the same order on every render
// Bug in one is invisible in the other
```

**After** (skill-compliant):
```tsx
// ✅ Custom hook: single source of truth, both components stay in sync
// hooks/use-order.ts
import { useState, useEffect } from 'react';

interface UseOrderResult {
  order: Order | null;
  loading: boolean;
  error: Error | null;
}

export function useOrder(orderId: string): UseOrderResult {
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!orderId) return;
    const controller = new AbortController();
    setLoading(true);

    fetch(`/api/orders/${encodeURIComponent(orderId)}`, { signal: controller.signal })
      .then(async r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return OrderSchema.parse(await r.json());
      })
      .then(setOrder)
      .catch(err => {
        if (err.name === 'AbortError') return;
        setError(err instanceof Error ? err : new Error(String(err)));
      })
      .finally(() => setLoading(false));

    return () => controller.abort();
  }, [orderId]);

  return { order, loading, error };
}

// Both components share the same hook — bug fixes apply everywhere
function OrderStatusBadge({ orderId }: { orderId: string }) {
  const { order, loading } = useOrder(orderId);
  if (loading) return <span className="animate-pulse">...</span>;
  return <span>{order?.status}</span>;
}

function OrderTimeline({ orderId }: { orderId: string }) {
  const { order, loading, error } = useOrder(orderId);
  if (loading) return <div className="animate-pulse h-20 bg-gray-100 rounded" />;
  if (error) return <p className="text-red-600">Failed to load timeline</p>;
  return <div>{order?.events?.map(e => <p key={e.id}>{e.label}</p>)}</div>;
}
```

**Why:** Copy-pasted fetch logic creates divergent behavior — one component adds error handling, the other doesn't. One component gets a race condition fix, the other doesn't. Extracting to `useOrder` means every consumer shares the same AbortController cleanup, error state, and schema validation. Changes apply everywhere automatically.

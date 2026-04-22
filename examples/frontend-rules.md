# frontend-rules — Real-World Examples

The skill enforces Next.js 16/React 19/Tailwind v4 development standards: Server vs Client Component decisions, caching with `'use cache'`, React Compiler memoization, and performance/accessibility patterns.

## Before / After

### Example 1: Client Component where a Server Component suffices

**Before** (triggers the skill):
```tsx
// ❌ Entire page is a Client Component — data fetched client-side, no SSR
'use client';

import { useState, useEffect } from 'react';

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/products')
      .then(r => r.json())
      .then(data => { setProducts(data); setLoading(false); });
  }, []);

  if (loading) return <div>Loading...</div>;

  return (
    <ul>
      {products.map((p: Product) => (
        <li key={p.id} className="ml-4 text-left">{p.name}</li>
      ))}
    </ul>
  );
}
// Issues: no SSR, no SEO, waterfall fetch, client bundle includes React + fetch logic
// + RTL violations: ml-4, text-left
```

**After** (skill-compliant):
```tsx
// ✅ Server Component: DB access, no client JS, RTL-safe classes
// No 'use client' — Server Component by default in App Router
import { db } from '@/lib/db';

export default async function ProductsPage() {
  // Runs on server — direct DB access, zero client JS for this component
  const products = await db.products.findMany({
    orderBy: { name: 'asc' },
    select: { id: true, name: true, priceCents: true },
  });

  return (
    <ul>
      {products.map((p) => (
        <li key={p.id} className="ms-4 text-start">{p.name}</li>
      ))}
    </ul>
  );
}
// SSR + SEO ✅ | Zero client JS ✅ | RTL-safe ✅ | No waterfall ✅
```

**Why:** `useEffect` + `fetch` in a Client Component means the HTML arrives empty (bad for SEO and LCP), then a waterfall request loads data. A Server Component runs the query at render time — the HTML ships with data included. The `'use client'` boundary should be pushed down to the smallest interactive leaf, not hoisted to the page level.

---

### Example 2: Missing Suspense boundaries causing layout shift

**Before** (triggers the skill):
```tsx
// ❌ Async Server Components with no Suspense — entire page blocks on slowest query
export default async function DashboardPage() {
  // All three run sequentially and block rendering
  const stats = await getStats();       // 120ms
  const orders = await getOrders();     // 340ms
  const activity = await getActivity(); // 280ms
  // Total: ~740ms before ANY HTML is sent to browser

  return (
    <div>
      <StatsPanel stats={stats} />
      <OrdersTable orders={orders} />
      <ActivityFeed activity={activity} />
    </div>
  );
}
```

**After** (skill-compliant):
```tsx
// ✅ Parallel Suspense streams — first bytes arrive immediately, sections stream in
import { Suspense } from 'react';
import { StatsPanel, StatsSkeleton } from './stats-panel';
import { OrdersTable, TableSkeleton } from './orders-table';
import { ActivityFeed, FeedSkeleton } from './activity-feed';

export default function DashboardPage() {
  // No await here — components fetch independently in parallel
  return (
    <div>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />      {/* streams in when ready (~120ms) */}
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <OrdersTable />     {/* streams in independently (~340ms) */}
      </Suspense>
      <Suspense fallback={<FeedSkeleton />}>
        <ActivityFeed />    {/* streams in independently (~280ms) */}
      </Suspense>
    </div>
    // First byte: immediate | Stats: 120ms | Activity: 280ms | Orders: 340ms
  );
}

// Each component does its own fetch
async function StatsPanel() {
  const stats = await getStats();
  return <div>{/* render stats */}</div>;
}
```

**Why:** Sequential awaits block the entire render — the slowest query determines when the first byte is sent. Parallel Suspense boundaries stream each section independently: the page is interactive as soon as the first section resolves, and skeletons prevent layout shift. TTFB drops from ~740ms to near-zero.

---

### Example 3: next/image ignored in favor of raw img tag

**Before** (triggers the skill):
```tsx
// ❌ Raw <img> — no optimization, CLS from unknown dimensions, no lazy loading
export function ProductCard({ product }: { product: Product }) {
  return (
    <div className="rounded-lg border p-4">
      <img
        src={product.imageUrl}
        alt={product.name}
        className="w-full rounded"
        // No width/height → CLS as image loads
        // No lazy loading → all images block page load
        // No WebP conversion → full PNG/JPG weight
      />
      <h3 className="mt-2 text-left font-semibold">{product.name}</h3>
      <p className="ml-2 text-gray-500">₪{product.priceCents / 100}</p>
    </div>
  );
}
```

**After** (skill-compliant):
```tsx
// ✅ next/image: WebP conversion, lazy loading, CLS prevention, RTL-safe text
import Image from 'next/image';

export function ProductCard({ product }: { product: Product }) {
  return (
    <div className="rounded-lg border p-4">
      <Image
        src={product.imageUrl}
        alt={product.name}
        width={400}
        height={300}
        className="w-full rounded object-cover"
        // Explicit dimensions prevent CLS
        // Lazy loading by default (priority={false})
        // Serves WebP/AVIF to browsers that support it
        // Responsive srcset generated automatically
      />
      <h3 className="mt-2 text-start font-semibold">{product.name}</h3>
      <p className="ms-2 text-gray-500">
        <span dir="ltr">₪{product.priceCents / 100}</span>
      </p>
    </div>
  );
}
```

**Why:** Raw `<img>` tags in Next.js miss three automatic optimizations: format conversion (WebP is 25-35% smaller than JPEG), lazy loading (images below the fold don't block page load), and CLS prevention (explicit `width`/`height` reserves space before the image loads). On a 20-product grid page, switching to `next/image` typically reduces total image payload by 40% and eliminates layout shift.

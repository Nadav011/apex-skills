# Cache, Streaming SSR & Hydration - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Rendering
> Consolidates: cache-components, streaming-ssr, hydration-analysis, ppr-optimization
> **Impact**: LCP -65%, Bundle Size -30-62%, TTFB -40%

---

## 1. CACHE COMPONENTS (Next.js 16)

### Overview

`cacheComponents` replaces PPR (Partial Prerendering) in Next.js 16. It creates a static shell at build time with dynamic holes that fill in at request time via streaming.

```typescript
// next.config.ts
const nextConfig = {
  cacheComponents: true, // Replaces PPR
};

export default nextConfig;
```

### How It Works

```
Build Time:
  ┌──────────────────────────────────────┐
  │  Static Shell (cached at CDN edge)   │
  │  ┌────────────────────────────────┐  │
  │  │  Header (static)               │  │
  │  │  Navigation (static)           │  │
  │  │  ┌─────────────────────────┐   │  │
  │  │  │  [Dynamic Hole 1]       │   │  │
  │  │  │  Suspense boundary      │   │  │
  │  │  └─────────────────────────┘   │  │
  │  │  Footer (static)               │  │
  │  │  ┌─────────────────────────┐   │  │
  │  │  │  [Dynamic Hole 2]       │   │  │
  │  │  └─────────────────────────┘   │  │
  │  └────────────────────────────────┘  │
  └──────────────────────────────────────┘

Request Time:
  Static shell served immediately from CDN
  Dynamic holes stream in as they resolve
  TTFB: ~50ms (static shell)
  LCP: depends on dynamic content priority
```

### Implementation Pattern

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';
import { DashboardHeader } from './header';     // Static
import { QuickStats } from './quick-stats';      // Dynamic
import { RecentActivity } from './activity';      // Dynamic
import { StatsSkeleton, ActivitySkeleton } from './skeletons';

export default function DashboardPage() {
  return (
    <div className="space-y-6 p-4 md:p-6">
      {/* Static shell -- cached, streams immediately */}
      <DashboardHeader />

      {/* Dynamic hole 1 -- streams when data ready */}
      <Suspense fallback={<StatsSkeleton />}>
        <QuickStats />
      </Suspense>

      {/* Dynamic hole 2 -- lower priority */}
      <Suspense fallback={<ActivitySkeleton />}>
        <RecentActivity />
      </Suspense>
    </div>
  );
}
```

### `use cache` + `cacheLife` (Replaces ISR)

```typescript
// app/products/page.tsx
import { cacheLife } from 'next/cache';

export default async function ProductsPage() {
  'use cache';
  cacheLife('hours'); // Revalidate every hour

  const products = await db.products.findMany({
    orderBy: { createdAt: 'desc' },
    take: 20,
  });

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}

// Cache life presets
cacheLife('seconds');  // ~1 second
cacheLife('minutes');  // ~1 minute
cacheLife('hours');    // ~1 hour
cacheLife('days');     // ~1 day
cacheLife('weeks');    // ~1 week
cacheLife('max');      // As long as possible
```

---

## 2. STREAMING SSR

### Suspense Boundary Placement Strategy

```tsx
// app/page.tsx
import { Suspense } from 'react';

export default function Page() {
  return (
    <div>
      {/* LAYER 1: Critical -- No Suspense (streams first) */}
      <Header />

      {/* LAYER 2: High Priority -- Individual Suspense */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Suspense fallback={<StatCardSkeleton />}>
          <QuickStats type="revenue" />
        </Suspense>
        <Suspense fallback={<StatCardSkeleton />}>
          <QuickStats type="orders" />
        </Suspense>
      </div>

      {/* LAYER 3: Medium Priority -- Grouped Suspense */}
      <div className="grid gap-6 lg:grid-cols-2">
        <Suspense fallback={<ChartSkeleton />}>
          <Charts />
        </Suspense>
        <Suspense fallback={<ActivitySkeleton />}>
          <RecentActivity />
        </Suspense>
      </div>

      {/* LAYER 4: Low Priority -- Deferred */}
      <Suspense fallback={<NotificationsSkeleton />}>
        <Notifications />
      </Suspense>
    </div>
  );
}
```

### Suspense Priority Matrix

| Priority | Content Type | Suspense Strategy | Skeleton |
|----------|-------------|-------------------|----------|
| Critical | Header, Navigation | No Suspense | None |
| High | Hero, Main CTA | Individual | Minimal |
| Medium | Primary content | Grouped | Detailed |
| Low | Secondary content | Grouped/Nested | Simple |
| Deferred | Analytics, Ads | Nested deep | Placeholder |

---

## 3. REACT SERVER COMPONENTS

### Server Component (Default)

```typescript
// app/products/page.tsx -- Server Component (no 'use client')
// Zero JavaScript sent to client for this component

export default async function ProductsPage({
  searchParams,
}: {
  searchParams: { category?: string; sort?: string };
}) {
  // Direct database access -- no API needed
  const products = await db.products.findMany({
    where: searchParams.category
      ? { category: searchParams.category }
      : undefined,
    orderBy: { [searchParams.sort || 'createdAt']: 'desc' },
  });

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

### Client Component (Interactive Only)

```typescript
// components/AddToCartButton.tsx
'use client';

import { useState, useTransition } from 'react';
import { addToCart } from '@/actions/cart';

export function AddToCartButton({ productId }: { productId: string }) {
  const [isPending, startTransition] = useTransition();
  const [added, setAdded] = useState(false);

  const handleClick = () => {
    startTransition(async () => {
      await addToCart(productId);
      setAdded(true);
      setTimeout(() => setAdded(false), 2000);
    });
  };

  return (
    <button
      onClick={handleClick}
      disabled={isPending}
      className="min-h-11 min-w-11 rounded-lg bg-primary px-4 py-2 text-white"
    >
      {isPending ? 'Adding...' : added ? 'Added!' : 'Add to Cart'}
    </button>
  );
}
```

### Composition Pattern (Server + Client)

```typescript
// Server Component wrapping Client Components
// app/products/product-card.tsx

import { AddToCartButton } from './add-to-cart-button'; // Client
import { QuickView } from './quick-view';                // Client

// Server Component -- zero client JS for static parts
export async function ProductCard({ productId }: { productId: string }) {
  const product = await getProduct(productId);

  return (
    <div className="rounded-lg border p-4">
      {/* Static content -- Server rendered, 0KB JS */}
      <img src={product.image} alt={product.name} className="aspect-square w-full object-cover" />
      <h3 className="mt-2 font-semibold">{product.name}</h3>
      <p className="text-muted-foreground">{product.description}</p>
      <p className="mt-2 text-lg font-bold">
        <span dir="ltr">{product.price.toLocaleString('he-IL')}&#8362;</span>
      </p>

      {/* Interactive -- Client Components (minimal JS) */}
      <div className="mt-4 flex gap-2">
        <AddToCartButton productId={productId} />
        <QuickView product={product} />
      </div>
    </div>
  );
}
```

### RSC Decision Matrix

| Scenario | Server Component | Client Component |
|----------|:---:|:---:|
| Data fetching | Yes | No |
| Large dependencies (date-fns, etc.) | Yes | No |
| Static content display | Yes | No |
| SEO-critical content | Yes | No |
| Auth-gated content | Yes | No |
| onClick/onChange handlers | No | Yes |
| useState/useEffect | No | Yes |
| Browser APIs (localStorage, etc.) | No | Yes |
| Real-time updates | No | Yes |
| Form validation (immediate) | No | Yes |

### Bundle Impact

| Component Type | Client Bundle | Savings |
|----------------|:---:|:---:|
| Data Display (RSC) | 0% | 100% |
| Forms with validation | 20% | 60% |
| Interactive widgets | 40% | 40% |
| Real-time features | 90% | 10% |

---

## 4. HYDRATION STRATEGIES

### 5 Hydration Patterns

| Pattern | Description | Client JS | Use Case |
|---------|-------------|-----------|----------|
| Full Hydration | Hydrate entire page | 100% | Legacy |
| Progressive | Hydrate in priority order | 80% | Gradual migration |
| Selective | Hydrate only interactive parts | 40-60% | Islands architecture |
| Islands | Static HTML + interactive islands | 20-40% | Content-heavy sites |
| Zero (RSC) | No hydration for server components | 0-30% | Next.js App Router |

### Selective Hydration (React 18+)

```typescript
// React selectively hydrates based on user interaction
export default function Page() {
  return (
    <div>
      {/* Hydrates first if user interacts */}
      <Suspense fallback={<GallerySkeleton />}>
        <ImageGallery />
      </Suspense>

      {/* Hydrates if user clicks/hovers */}
      <Suspense fallback={<ProductInfoSkeleton />}>
        <ProductInfo />
      </Suspense>

      {/* Hydrates on scroll into view */}
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews />
      </Suspense>
    </div>
  );
}

// Hydration priority based on user actions:
// Click on element  -> Immediate hydration (sync)
// Hover over element -> Prioritized hydration
// Scroll into view  -> Queued hydration
// No interaction    -> Background hydration
```

---

## 5. ERROR HANDLING WITH STREAMING

### Page-Level Error Boundary

```typescript
// app/dashboard/error.tsx
'use client';

import { useEffect } from 'react';

export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Dashboard error:', error);
  }, [error]);

  return (
    <div className="flex min-h-[400px] flex-col items-center justify-center gap-4" role="alert">
      <h2 className="text-xl font-semibold">Something went wrong</h2>
      <p className="text-muted-foreground">{error.message}</p>
      <button onClick={reset} className="min-h-11 rounded-lg bg-primary px-4 py-2 text-white">
        Try again
      </button>
    </div>
  );
}
```

### Component-Level Error Boundary

```typescript
// Using react-error-boundary for granular error handling
import { ErrorBoundary } from 'react-error-boundary';

export function ChartsSection() {
  return (
    <ErrorBoundary
      FallbackComponent={({ error, resetErrorBoundary }) => (
        <div className="rounded-lg border border-destructive p-4" role="alert">
          <p>Failed to load charts: {error.message}</p>
          <button onClick={resetErrorBoundary} className="min-h-11 mt-2">
            Retry
          </button>
        </div>
      )}
      onError={(error, info) => {
        reportError(error, { componentStack: info.componentStack });
      }}
    >
      <Suspense fallback={<ChartSkeleton />}>
        <Charts />
      </Suspense>
    </ErrorBoundary>
  );
}
```

---

## 6. PERFORMANCE METRICS

### Streaming Metrics

```typescript
// lib/performance/streaming-metrics.ts
export function measureStreamingPerformance() {
  if (typeof window === 'undefined') return;

  const nav = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
  const ttfb = nav.responseStart - nav.requestStart;

  return {
    ttfb,
    streamingBenefit: ttfb < 400 ? 'optimal' : 'needs-improvement',
  };
}
```

### Target Metrics

| Metric | Traditional SSR | Streaming SSR | Improvement |
|--------|:---:|:---:|:---:|
| TTFB | 800-1200ms | 200-400ms | -60-70% |
| LCP | 2.5-4.0s | 0.8-1.4s | -65% |
| Bundle Size | 100% | 38-70% | -30-62% |
| TTI | 3.0-5.0s | 1.5-2.5s | -50% |

---

## 7. CHECKLIST

```markdown
## Cache, Streaming & Hydration Checklist

### Cache Components
- [ ] cacheComponents: true in next.config.ts
- [ ] Static shell identified for each page
- [ ] Suspense boundaries around dynamic content
- [ ] Skeletons match final component dimensions (CLS = 0)
- [ ] use cache + cacheLife for data caching

### Streaming SSR
- [ ] Suspense boundaries placed by priority
- [ ] Critical content streams first (no Suspense)
- [ ] Lower-priority content in nested Suspense
- [ ] Error boundaries at component level

### Server Components
- [ ] Default to Server Components (no 'use client')
- [ ] 'use client' only for interactivity
- [ ] Composition pattern (Server wrapping Client)
- [ ] Heavy dependencies in Server Components only
- [ ] Bundle analyzer confirms RSC savings

### Hydration
- [ ] No unnecessary 'use client' directives
- [ ] Selective hydration via Suspense boundaries
- [ ] TTFB < 400ms with streaming
- [ ] LCP < 1.5s with priority content first
```

---

<!-- CACHE_STREAMING_HYDRATION v24.7.0 | cacheComponents, streaming SSR, RSC, hydration, error boundaries -->

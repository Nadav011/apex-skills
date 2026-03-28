# Core Web Vitals - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Metrics
> Consolidates: core-web-vitals, tbt-analysis, speed-index, dom-size

---

## 1. METRIC THRESHOLDS

### Complete Threshold Table

| Metric | Google "Good" | Needs Improvement | Poor | APEX Target | APEX Stretch |
|--------|---------------|-------------------|------|-------------|--------------|
| LCP | <= 2.5s | 2.5s - 4.0s | > 4.0s | < 1.5s | < 1.0s |
| INP | <= 200ms | 200ms - 500ms | > 500ms | < 150ms | < 100ms |
| CLS | <= 0.1 | 0.1 - 0.25 | > 0.25 | < 0.05 | 0 |
| FCP | <= 1.8s | 1.8s - 3.0s | > 3.0s | < 1.2s | < 0.8s |
| TTFB | <= 800ms | 800ms - 1800ms | > 1800ms | < 400ms | < 200ms |
| TBT | <= 200ms | 200ms - 600ms | > 600ms | < 150ms | < 100ms |
| SI | <= 3.4s | 3.4s - 5.8s | > 5.8s | < 2.0s | < 1.5s |

### Google Ranking Signal

Google uses CrUX (field data) at the **75th percentile** for Core Web Vitals ranking signal. Only LCP, INP, and CLS are ranking factors. FCP, TTFB, TBT, and SI are diagnostic metrics.

---

## 2. LARGEST CONTENTFUL PAINT (LCP)

### What Counts as LCP

```
LCP Candidates (in priority order):
1. <img> elements (including <img> inside <picture>)
2. <image> inside <svg>
3. <video> poster image (or first frame)
4. Element with background-image via url() (not gradient)
5. Block-level text elements (<h1>-<h6>, <p>, <div> with text)
```

### LCP Optimization Strategies

```typescript
// 1. Preload hero image
// In app/layout.tsx or page head
<link rel="preload" as="image" href="/hero.webp" fetchPriority="high" />

// 2. Next.js Image with priority
import Image from 'next/image';

export function HeroImage() {
  return (
    <Image
      src="/hero.webp"
      alt="Hero image"
      width={1200}
      height={630}
      priority // Sets fetchPriority="high" + preload
      sizes="100vw"
      quality={80}
    />
  );
}

// 3. Font optimization for text LCP
// next.config.ts -- Next.js auto-optimizes Google Fonts
// For local fonts:
import localFont from 'next/font/local';

const heebo = localFont({
  src: './fonts/Heebo-Variable.woff2',
  display: 'swap', // Prevents font-blocking
  preload: true,
  variable: '--font-heebo',
});
```

### LCP Sub-Parts Breakdown

```
LCP = TTFB + Resource Load Delay + Resource Load Time + Element Render Delay

Optimize each:
├── TTFB: CDN, edge computing, streaming SSR
├── Resource Load Delay: preload, fetchPriority="high"
├── Resource Load Time: image compression, modern formats, CDN
└── Element Render Delay: eliminate render-blocking CSS/JS
```

---

## 3. INTERACTION TO NEXT PAINT (INP)

### INP Anatomy

```
INP = Input Delay + Processing Time + Presentation Delay

├── Input Delay: Time from user input to event handler start
│   └── Caused by: long tasks blocking main thread
├── Processing Time: Time executing event handlers
│   └── Caused by: heavy computation, synchronous operations
└── Presentation Delay: Time from handler end to next paint
    └── Caused by: layout thrashing, expensive rendering
```

### INP Optimization Patterns

```typescript
// 1. Break up long tasks with scheduler.yield()
async function handleClick() {
  doFirstPart();
  await scheduler.yield(); // Yield to browser
  doSecondPart();
  await scheduler.yield();
  doThirdPart();
}

// 2. Use startTransition for non-urgent updates
import { useTransition } from 'react';

function SearchComponent() {
  const [isPending, startTransition] = useTransition();
  const [results, setResults] = useState([]);

  function handleInput(e: React.ChangeEvent<HTMLInputElement>) {
    // Urgent: update input field immediately
    setInputValue(e.target.value);

    // Non-urgent: defer search results
    startTransition(() => {
      setResults(search(e.target.value));
    });
  }

  return (
    <div>
      <input onChange={handleInput} className="min-h-11 min-w-11" />
      {isPending ? <Spinner /> : <ResultsList results={results} />}
    </div>
  );
}

// 3. Event delegation for lists
function ItemList({ items }: { items: Item[] }) {
  const handleClick = (e: React.MouseEvent<HTMLUListElement>) => {
    const target = (e.target as HTMLElement).closest('[data-item-id]');
    if (target) {
      const id = target.getAttribute('data-item-id');
      processItem(id);
    }
  };

  return (
    <ul onClick={handleClick}>
      {items.map(item => (
        <li key={item.id} data-item-id={item.id}>{item.name}</li>
      ))}
    </ul>
  );
}
```

---

## 4. CUMULATIVE LAYOUT SHIFT (CLS)

### Common CLS Causes and Fixes

| Cause | Fix | Impact |
|-------|-----|--------|
| Images without dimensions | Always set width/height or aspect-ratio | High |
| Ads/embeds without size | Reserve space with min-height | High |
| Dynamically injected content | Use CSS containment or placeholders | Medium |
| Web fonts causing FOUT | font-display: swap + size-adjust | Medium |
| Top-positioned banners | Use CSS transform for animations | Low |

### CLS Prevention Patterns

```typescript
// 1. Always set explicit dimensions on images
<Image
  src={src}
  alt={alt}
  width={800}
  height={450} // Explicit aspect ratio
  sizes="(max-width: 768px) 100vw, 50vw"
/>

// 2. Skeleton loading that matches final dimensions
function CardSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="aspect-video w-full rounded-lg bg-muted" />
      <div className="mt-4 h-6 w-3/4 rounded bg-muted" />
      <div className="mt-2 h-4 w-1/2 rounded bg-muted" />
    </div>
  );
}

// 3. Font size-adjust to prevent layout shift
@font-face {
  font-family: 'Heebo';
  src: url('/fonts/Heebo-Variable.woff2') format('woff2');
  font-display: swap;
  size-adjust: 105%; /* Match fallback font metrics */
}
```

---

## 5. TOTAL BLOCKING TIME (TBT)

### TBT Formula

```
TBT = Sum of (task_duration - 50ms) for all tasks > 50ms

Example:
Task 1: 30ms  → 0ms blocking (< 50ms threshold)
Task 2: 80ms  → 30ms blocking (80 - 50)
Task 3: 120ms → 70ms blocking (120 - 50)
Task 4: 45ms  → 0ms blocking (< 50ms threshold)
Task 5: 200ms → 150ms blocking (200 - 50)
─────────────
TBT = 0 + 30 + 70 + 0 + 150 = 250ms (POOR)
```

### TBT Reduction Strategies

```typescript
// 1. Code splitting to reduce main thread work
import dynamic from 'next/dynamic';

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <Skeleton />,
  ssr: false,
});

// 2. Web Worker for CPU-intensive tasks
// workers/heavy-computation.ts
self.onmessage = (e: MessageEvent) => {
  const result = expensiveCalculation(e.data);
  self.postMessage(result);
};

// Usage in component
const worker = new Worker(
  new URL('../workers/heavy-computation.ts', import.meta.url)
);
worker.postMessage(data);
worker.onmessage = (e) => setResult(e.data);

// 3. Time-sliced processing
async function processInChunks<T>(
  items: T[],
  processor: (item: T) => void,
  chunkSize = 5,
): Promise<void> {
  for (let i = 0; i < items.length; i += chunkSize) {
    const chunk = items.slice(i, i + chunkSize);
    chunk.forEach(processor);
    await scheduler.yield();
  }
}
```

---

## 6. SPEED INDEX (SI)

### Speed Index Explained

Speed Index measures how quickly content is visually displayed during page load. Lower is better. It captures the visual progress of the page, not just individual element timing.

```
Visual Progress Timeline:
0.0s: 0% visible
0.5s: 20% visible (background, nav skeleton)
1.0s: 60% visible (hero image, headings)
1.5s: 90% visible (body text, secondary images)
2.0s: 100% visible (all content rendered)

Speed Index = Area above the visual progress curve
```

### Speed Index Optimization

```typescript
// 1. Critical CSS inlining
// next.config.ts
module.exports = {
  experimental: {
    optimizeCss: true, // Extracts and inlines critical CSS
  },
};

// 2. Progressive rendering with streaming SSR
// Render above-the-fold content first
export default async function Page() {
  return (
    <>
      {/* Streams immediately -- critical for Speed Index */}
      <Header />
      <HeroSection />

      {/* Streams when ready -- below the fold */}
      <Suspense fallback={<ContentSkeleton />}>
        <MainContent />
      </Suspense>
    </>
  );
}

// 3. Above-the-fold priority
<link rel="preload" as="image" href="/hero.webp" fetchPriority="high" />
<link rel="preload" as="style" href="/critical.css" />
```

---

## 7. DOM SIZE

### DOM Size Thresholds

| Metric | Lighthouse Warning | Lighthouse Error | APEX Target |
|--------|-------------------|------------------|-------------|
| Total elements | > 800 | > 1400 | < 1000 |
| Maximum depth | > 32 | > 60 | < 32 |
| Maximum children | > 60 | > 120 | < 60 |

### DOM Size Reduction Strategies

```typescript
// 1. Virtual scrolling for large lists
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 64, // Estimated row height
    overscan: 5,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div
        style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              transform: `translateY(${virtualItem.start}px)`,
              width: '100%',
            }}
          >
            <ItemRow item={items[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}

// 2. content-visibility for off-screen content
// Tailwind class (custom utility or inline style)
<section style={{ contentVisibility: 'auto', containIntrinsicSize: '0 500px' }}>
  <HeavyContent />
</section>

// 3. DOM analysis function
function analyzeDOMSize(): {
  totalElements: number;
  maxDepth: number;
  maxChildren: number;
} {
  const all = document.querySelectorAll('*');
  let maxDepth = 0;
  let maxChildren = 0;

  all.forEach((el) => {
    let depth = 0;
    let current: Element | null = el;
    while (current.parentElement) {
      depth++;
      current = current.parentElement;
    }
    maxDepth = Math.max(maxDepth, depth);
    maxChildren = Math.max(maxChildren, el.children.length);
  });

  return {
    totalElements: all.length,
    maxDepth,
    maxChildren,
  };
}
```

---

## 8. MEASUREMENT

### web-vitals Library (RUM)

```typescript
// lib/performance/web-vitals.ts
import { onCLS, onINP, onLCP, onFCP, onTTFB } from 'web-vitals';

// Type augmentation for Network Information API (see browser-types.d.ts)
interface NetworkInformation {
  effectiveType: 'slow-2g' | '2g' | '3g' | '4g';
  downlink: number;
  rtt: number;
  saveData: boolean;
}

declare global {
  interface Navigator {
    connection?: NetworkInformation;
    deviceMemory?: number;
  }
}

interface VitalMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  delta: number;
  id: string;
  navigationType: string;
}

function sendToAnalytics(metric: VitalMetric): void {
  const body = JSON.stringify({
    name: metric.name,
    value: metric.value,
    rating: metric.rating,
    page: window.location.pathname,
    connection: navigator.connection?.effectiveType,
    deviceMemory: navigator.deviceMemory,
    navigationType: metric.navigationType,
    timestamp: Date.now(),
  });

  if (navigator.sendBeacon) {
    navigator.sendBeacon('/api/vitals', body);
  } else {
    fetch('/api/vitals', { body, method: 'POST', keepalive: true });
  }
}

export function initWebVitals(): void {
  onCLS(sendToAnalytics);
  onINP(sendToAnalytics);
  onLCP(sendToAnalytics);
  onFCP(sendToAnalytics);
  onTTFB(sendToAnalytics);
}
```

### PerformanceObserver for TBT

```typescript
// Measure TBT via Long Task API
function measureTBT(): void {
  let tbt = 0;

  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (entry.duration > 50) {
        tbt += entry.duration - 50;
      }
    }
  });

  observer.observe({ type: 'longtask', buffered: true });

  // Report after load
  window.addEventListener('load', () => {
    setTimeout(() => {
      observer.disconnect();
      console.log(`TBT: ${tbt.toFixed(0)}ms`);
    }, 5000);
  });
}
```

---

## 9. CHECKLIST

```markdown
## Core Web Vitals Optimization Checklist

### LCP (< 1.5s)
- [ ] Hero image preloaded with fetchPriority="high"
- [ ] Images in WebP/AVIF format
- [ ] Font display: swap with size-adjust
- [ ] Streaming SSR for critical content
- [ ] No render-blocking resources
- [ ] CDN for static assets

### INP (< 150ms)
- [ ] No long tasks on critical path
- [ ] scheduler.yield() for heavy handlers
- [ ] useTransition for non-urgent updates
- [ ] Event delegation for lists
- [ ] Code splitting for non-critical code
- [ ] Web Workers for CPU-intensive work

### CLS (< 0.05)
- [ ] All images have explicit dimensions
- [ ] Skeleton loading matches final layout
- [ ] Font size-adjust configured
- [ ] No dynamically injected content above fold
- [ ] CSS containment on dynamic sections
- [ ] Animations use transform/opacity only

### TBT (< 150ms)
- [ ] Code splitting reduces initial JS
- [ ] Lazy loading for below-fold components
- [ ] Web Workers for heavy computation
- [ ] Time-sliced processing for large datasets
- [ ] requestIdleCallback for non-critical work

### DOM Size (< 1000 elements)
- [ ] Virtual scrolling for long lists
- [ ] content-visibility: auto for off-screen
- [ ] Pagination or infinite scroll
- [ ] Conditional rendering for hidden content
- [ ] Regular DOM size monitoring
```

---

<!-- CWV_REFERENCE v24.7.0 | LCP, INP, CLS, FCP, TTFB, TBT, SI, DOM Size -->

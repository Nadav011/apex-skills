# Modern Browser APIs - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/APIs
> Consolidates: loaf-attribution, scheduler-api, speculation-rules, view-transitions

---

## 1. LONG ANIMATION FRAMES (LoAF) API

### Overview

LoAF (Chrome 123+) provides detailed attribution for frames that take > 50ms, replacing the less detailed Long Tasks API.

### Basic Usage

```typescript
// lib/performance/loaf.ts

interface LoAFEntry extends PerformanceEntry {
  duration: number;
  renderStart: number;
  styleAndLayoutStart: number;
  firstUIEventTimestamp: number;
  blockingDuration: number;
  scripts: LoAFScript[];
}

interface LoAFScript {
  invoker: string;
  invokerType: string;
  sourceURL: string;
  sourceCharPosition: number;
  sourceFunctionName: string;
  executionStart: number;
  duration: number;
  forcedStyleAndLayoutDuration: number;
  pauseDuration: number;
  windowAttribution: string;
}

function monitorLoAF(): void {
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries() as LoAFEntry[]) {
      // Log frames > 100ms (significant)
      if (entry.duration > 100) {
        console.warn('Slow frame:', {
          duration: `${entry.duration.toFixed(0)}ms`,
          blocking: `${entry.blockingDuration.toFixed(0)}ms`,
          scripts: entry.scripts.map((s) => ({
            invoker: s.invoker,
            source: `${s.sourceURL}:${s.sourceCharPosition}`,
            function: s.sourceFunctionName,
            duration: `${s.duration.toFixed(0)}ms`,
            forcedLayout: `${s.forcedStyleAndLayoutDuration.toFixed(0)}ms`,
          })),
        });
      }
    }
  });

  observer.observe({ type: 'long-animation-frame', buffered: true });
}
```

### INP-LoAF Correlation

```typescript
// Correlate INP events with LoAF data
import { onINP } from 'web-vitals/attribution';

function correlateINPWithLoAF(): void {
  onINP((metric) => {
    const attribution = metric.attribution;

    console.log('INP event:', {
      value: `${metric.value}ms`,
      element: attribution.interactionTarget,
      type: attribution.interactionType,
      // LoAF-enriched attribution
      inputDelay: `${attribution.inputDelay}ms`,
      processingDuration: `${attribution.processingDuration}ms`,
      presentationDelay: `${attribution.presentationDelay}ms`,
      longAnimationFrameEntries: attribution.longAnimationFrameEntries?.map((loaf: PerformanceEntry & { scripts?: Array<{ sourceURL: string }> }) => ({
        duration: `${loaf.duration}ms`,
        scripts: loaf.scripts?.map((s) => s.sourceURL),
      })),
    });
  });
}
```

---

## 2. SCHEDULER API

### scheduler.yield() (INP Critical)

```typescript
// Break up long tasks to keep main thread responsive
async function processItems(items: Item[]): Promise<void> {
  for (const item of items) {
    processItem(item);
    await scheduler.yield(); // Let browser handle pending events
  }
}

// With polyfill for older browsers
async function yieldToMain(): Promise<void> {
  if ('scheduler' in globalThis && 'yield' in scheduler) {
    await scheduler.yield();
  } else {
    await new Promise((resolve) => setTimeout(resolve, 0));
  }
}
```

### scheduler.postTask() with Priorities

```typescript
// Priority levels:
// "user-blocking"  -- Highest: critical user interactions
// "user-visible"   -- Medium: visible updates
// "background"     -- Lowest: non-visible work

// User-blocking: Immediate response needed
const result = await scheduler.postTask(
  () => processFormSubmission(data),
  { priority: 'user-blocking' },
);

// User-visible: UI updates that aren't blocking
scheduler.postTask(
  () => updateDashboardCharts(),
  { priority: 'user-visible' },
);

// Background: Analytics, prefetching, cache warming
scheduler.postTask(
  () => sendAnalytics(event),
  { priority: 'background' },
);
```

### Complete Scheduler Polyfill

```typescript
// lib/performance/scheduler-polyfill.ts
interface Scheduler {
  yield(): Promise<void>;
  postTask<T>(callback: () => T, options?: { priority?: string; signal?: AbortSignal }): Promise<T>;
}

declare global {
  // eslint-disable-next-line no-var
  var scheduler: Scheduler | undefined;
}

if (!('scheduler' in globalThis)) {
  globalThis.scheduler = {
    async yield(): Promise<void> {
      return new Promise((resolve) => setTimeout(resolve, 0));
    },

    async postTask<T>(
      callback: () => T,
      options?: { priority?: string; signal?: AbortSignal },
    ): Promise<T> {
      const { priority = 'user-visible', signal } = options || {};

      if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');

      return new Promise((resolve, reject) => {
        const run = () => {
          if (signal?.aborted) {
            reject(new DOMException('Aborted', 'AbortError'));
            return;
          }
          try {
            resolve(callback());
          } catch (e) {
            reject(e);
          }
        };

        switch (priority) {
          case 'user-blocking':
            queueMicrotask(run);
            break;
          case 'user-visible':
            setTimeout(run, 0);
            break;
          case 'background':
            if ('requestIdleCallback' in globalThis) {
              requestIdleCallback(() => run());
            } else {
              setTimeout(run, 100);
            }
            break;
        }
      });
    },
  };
}
```

### Chunked Processing with Priority

```typescript
// lib/performance/chunked-processing.ts
async function processChunked<T, R>(
  items: T[],
  processor: (item: T) => R,
  options: {
    chunkSize?: number;
    priority?: 'user-blocking' | 'user-visible' | 'background';
    onProgress?: (processed: number, total: number) => void;
    signal?: AbortSignal;
  } = {},
): Promise<R[]> {
  const { chunkSize = 10, priority = 'user-visible', onProgress, signal } = options;
  const results: R[] = [];

  for (let i = 0; i < items.length; i += chunkSize) {
    if (signal?.aborted) throw new DOMException('Aborted', 'AbortError');

    const chunk = items.slice(i, i + chunkSize);

    const chunkResults = await scheduler.postTask(
      () => chunk.map(processor),
      { priority, signal },
    );

    results.push(...chunkResults);
    onProgress?.(Math.min(i + chunkSize, items.length), items.length);

    await scheduler.yield();
  }

  return results;
}
```

---

## 3. SPECULATION RULES API

### Overview

Speculation Rules enable prefetching and prerendering of likely next navigations with declarative JSON syntax.

### Basic Syntax

```html
<script type="speculationrules">
{
  "prerender": [
    {
      "urls": ["/dashboard", "/products"],
      "eagerness": "moderate"
    }
  ],
  "prefetch": [
    {
      "urls": ["/about", "/contact"],
      "eagerness": "conservative"
    }
  ]
}
</script>
```

### Document Rules (Pattern-Based)

```html
<script type="speculationrules">
{
  "prerender": [
    {
      "where": {
        "and": [
          { "href_matches": "/products/*" },
          { "not": { "href_matches": "/products/*/edit" } },
          { "not": { "selector_matches": ".no-prerender" } }
        ]
      },
      "eagerness": "moderate"
    }
  ],
  "prefetch": [
    {
      "where": {
        "href_matches": "/blog/*"
      },
      "eagerness": "conservative"
    }
  ]
}
</script>
```

### Eagerness Levels

| Level | Trigger | Use For |
|-------|---------|---------|
| `immediate` | Page load | Very high confidence navigations |
| `eager` | Hover/pointerdown | High confidence links |
| `moderate` | Hover (200ms delay) | Moderate confidence links |
| `conservative` | Pointerdown/touchstart | Low confidence, expensive pages |

### Next.js Integration

```tsx
// components/SpeculationRules.tsx
export function SpeculationRules() {
  const rules = {
    prerender: [
      {
        where: {
          and: [
            { href_matches: '/*' },
            { not: { href_matches: '/api/*' } },
            { not: { href_matches: '/admin/*' } },
            { not: { selector_matches: '[data-no-prerender]' } },
          ],
        },
        eagerness: 'moderate',
      },
    ],
  };

  return (
    <script
      type="speculationrules"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(rules) }}
    />
  );
}

// Add to layout.tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <body>
        {children}
        <SpeculationRules />
      </body>
    </html>
  );
}
```

---

## 4. VIEW TRANSITIONS API

### Overview

The View Transitions API (Chrome 111+, Safari 18+) provides smooth animated transitions between page states or navigation.

### SPA View Transitions

```typescript
// lib/transitions/view-transition.ts
async function withViewTransition(
  updateDOM: () => void | Promise<void>,
): Promise<void> {
  if (!document.startViewTransition) {
    await updateDOM();
    return;
  }

  const transition = document.startViewTransition(async () => {
    await updateDOM();
  });

  await transition.finished;
}
```

### CSS Transition Styles

```css
/* RTL-aware view transitions */
::view-transition-old(root) {
  animation: slide-out 300ms ease-in;
}

::view-transition-new(root) {
  animation: slide-in 300ms ease-out;
}

/* RTL bidirectional animations */
@keyframes slide-out {
  to {
    transform: translateX(calc(var(--direction, 1) * -100%));
    opacity: 0;
  }
}

@keyframes slide-in {
  from {
    transform: translateX(calc(var(--direction, 1) * 100%));
    opacity: 0;
  }
}

/* Set direction based on document dir */
:root[dir="rtl"] {
  --direction: -1;
}

:root[dir="ltr"] {
  --direction: 1;
}

/* Respect reduced motion */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(root),
  ::view-transition-new(root) {
    animation: none;
  }
}
```

### Named Transitions

```css
/* Assign view-transition-name to elements */
.product-image {
  view-transition-name: product-hero;
}

.product-title {
  view-transition-name: product-title;
}

/* Custom transition per element */
::view-transition-old(product-hero) {
  animation: scale-down 300ms ease-in;
}

::view-transition-new(product-hero) {
  animation: scale-up 300ms ease-out;
}
```

### Next.js TransitionLink Component

```tsx
// components/TransitionLink.tsx
'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { type ComponentProps } from 'react';

type TransitionLinkProps = ComponentProps<typeof Link> & {
  viewTransitionName?: string;
};

export function TransitionLink({
  href,
  children,
  viewTransitionName,
  ...props
}: TransitionLinkProps) {
  const router = useRouter();

  const handleClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    e.preventDefault();

    if (!document.startViewTransition) {
      router.push(href.toString());
      return;
    }

    document.startViewTransition(() => {
      router.push(href.toString());
    });
  };

  return (
    <Link href={href} onClick={handleClick} {...props}>
      {children}
    </Link>
  );
}
```

---

## 5. BROWSER SUPPORT

| API | Chrome | Firefox | Safari | Edge |
|-----|--------|---------|--------|------|
| LoAF | 123+ | No | No | 123+ |
| scheduler.yield() | 129+ | No | No | 129+ |
| scheduler.postTask() | 94+ | No | No | 94+ |
| Speculation Rules | 109+ | No | No | 109+ |
| View Transitions (SPA) | 111+ | No | 18+ | 111+ |
| View Transitions (MPA) | 126+ | No | 18+ | 126+ |

**Strategy**: Use all APIs with progressive enhancement. Provide polyfills for scheduler. Feature-detect LoAF and View Transitions.

---

## 6. CHECKLIST

```markdown
## Modern Browser APIs Checklist

### LoAF
- [ ] PerformanceObserver monitoring long-animation-frame
- [ ] INP-LoAF correlation implemented
- [ ] forcedStyleAndLayoutDuration < 30ms
- [ ] Script attribution logged for debugging

### Scheduler
- [ ] scheduler.yield() in heavy event handlers
- [ ] scheduler.postTask() with priority levels
- [ ] Polyfill for non-supporting browsers
- [ ] Chunked processing for large datasets

### Speculation Rules
- [ ] Document rules for common navigation patterns
- [ ] Eagerness levels appropriate per page
- [ ] Admin/API routes excluded
- [ ] Reduced motion users considered

### View Transitions
- [ ] RTL-aware animations (var(--direction))
- [ ] Reduced motion media query respected
- [ ] Named transitions for key elements
- [ ] Graceful fallback for unsupported browsers
```

---

<!-- MODERN_BROWSER_APIS v24.7.0 | LoAF, Scheduler, Speculation Rules, View Transitions -->

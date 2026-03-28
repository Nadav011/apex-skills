# Runtime Profiling - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Runtime
> Consolidates: runtime-profiling, long-tasks, layout-thrashing, code-analysis

---

## 1. CPU PROFILING

### Long Task Detection

```typescript
// lib/performance/long-tasks.ts

interface LongTaskAttribution {
  containerSrc?: string;
  containerType?: string;
  containerId?: string;
  containerName?: string;
}

interface LongTaskEntry extends PerformanceEntry {
  attribution: LongTaskAttribution[];
}

function monitorLongTasks(): void {
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries() as LongTaskEntry[]) {
      if (entry.duration > 50) {
        console.warn('Long task detected:', {
          duration: `${entry.duration.toFixed(0)}ms`,
          blocking: `${(entry.duration - 50).toFixed(0)}ms`,
          startTime: `${entry.startTime.toFixed(0)}ms`,
          attribution: entry.attribution?.[0]?.containerSrc || 'self',
        });
      }
    }
  });

  observer.observe({ type: 'longtask', buffered: true });
}
```

### Task Anatomy

```
Long Task > 50ms
├── Input Delay: Main thread busy when user interacts
├── Processing Time: Event handler execution
└── Presentation Delay: Style/layout/paint after handler

Breaking strategy:
1. Identify: PerformanceObserver + LoAF API
2. Measure: Duration, attribution, forced layouts
3. Break: scheduler.yield(), requestIdleCallback, Web Workers
4. Verify: Re-measure after optimization
```

---

## 2. YIELDING PATTERNS

### scheduler.yield() (Best for INP)

```typescript
// Break up synchronous work
async function processLargeDataset(items: Item[]): Promise<void> {
  const CHUNK_SIZE = 10;

  for (let i = 0; i < items.length; i += CHUNK_SIZE) {
    const chunk = items.slice(i, i + CHUNK_SIZE);

    // Process chunk
    for (const item of chunk) {
      processItem(item);
    }

    // Yield to browser between chunks
    await scheduler.yield();
  }
}
```

### requestIdleCallback (For Non-Critical Work)

```typescript
// Schedule non-critical work during idle periods
function scheduleIdleWork(tasks: Array<() => void>): void {
  let taskIndex = 0;

  function processNext(deadline: IdleDeadline): void {
    while (taskIndex < tasks.length && deadline.timeRemaining() > 5) {
      tasks[taskIndex]();
      taskIndex++;
    }

    if (taskIndex < tasks.length) {
      requestIdleCallback(processNext);
    }
  }

  requestIdleCallback(processNext);
}

// Usage
scheduleIdleWork([
  () => prefetchImages(),
  () => initAnalytics(),
  () => warmCache(),
  () => loadNonCriticalScripts(),
]);
```

### React Hook for Idle Work

```typescript
// hooks/useIdleCallback.ts
'use client';

import { useEffect, useRef } from 'react';

export function useIdleCallback(
  callback: () => void,
  options?: { timeout?: number },
): void {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  useEffect(() => {
    const id = requestIdleCallback(
      () => callbackRef.current(),
      options,
    );

    return () => cancelIdleCallback(id);
  }, [options?.timeout]);
}

// Usage
function AnalyticsLoader() {
  useIdleCallback(() => {
    // Load analytics during idle time
    import('./analytics').then((m) => m.init());
  });

  return null;
}
```

---

## 3. LAYOUT THRASHING

### What Causes Layout Thrashing

Layout thrashing occurs when JavaScript repeatedly reads layout properties and writes style changes, forcing the browser to recalculate layout synchronously.

### Complete List of Reflow Triggers

```
Properties that trigger synchronous layout (avoid in loops):

BOX METRICS:
  elem.offsetLeft, elem.offsetTop, elem.offsetWidth, elem.offsetHeight
  elem.offsetParent
  elem.clientLeft, elem.clientTop, elem.clientWidth, elem.clientHeight
  elem.getClientRects(), elem.getBoundingClientRect()

SCROLL:
  elem.scrollBy(), elem.scrollTo(), elem.scrollIntoView()
  elem.scrollLeft, elem.scrollTop, elem.scrollWidth, elem.scrollHeight

COMPUTED STYLES:
  window.getComputedStyle()
  elem.computedStyleMap()

WINDOW:
  window.scrollX, window.scrollY
  window.innerHeight, window.innerWidth
  window.visualViewport.height, window.visualViewport.width
  window.visualViewport.offsetTop, window.visualViewport.offsetLeft

FOCUS:
  elem.focus() (can trigger scrolling)

OTHER:
  elem.checkVisibility(), document.scrollingElement
  Range.getClientRects(), Range.getBoundingClientRect()
```

### Anti-Pattern Detection

```typescript
// BAD: Layout thrashing (read-write-read-write cycle)
function badResize(elements: HTMLElement[]): void {
  elements.forEach((el) => {
    const width = el.offsetWidth;     // READ (forces layout)
    el.style.width = width * 2 + 'px'; // WRITE (invalidates layout)
    // Next iteration: offsetWidth forces NEW layout calculation
  });
}

// GOOD: Batch reads, then batch writes
function goodResize(elements: HTMLElement[]): void {
  // Phase 1: Read all
  const widths = elements.map((el) => el.offsetWidth);

  // Phase 2: Write all
  elements.forEach((el, i) => {
    el.style.width = widths[i] * 2 + 'px';
  });
}
```

### FastDOM Pattern

```typescript
// lib/performance/fastdom.ts
class FastDOM {
  private reads: Array<() => void> = [];
  private writes: Array<() => void> = [];
  private scheduled = false;

  read(fn: () => void): void {
    this.reads.push(fn);
    this.scheduleFlush();
  }

  write(fn: () => void): void {
    this.writes.push(fn);
    this.scheduleFlush();
  }

  private scheduleFlush(): void {
    if (!this.scheduled) {
      this.scheduled = true;
      requestAnimationFrame(() => this.flush());
    }
  }

  private flush(): void {
    // Execute all reads first
    while (this.reads.length) {
      this.reads.shift()!();
    }
    // Then all writes
    while (this.writes.length) {
      this.writes.shift()!();
    }
    this.scheduled = false;
  }
}

export const fastdom = new FastDOM();

// Usage
fastdom.read(() => {
  const height = element.offsetHeight;
  fastdom.write(() => {
    element.style.height = height * 2 + 'px';
  });
});
```

### React Layout Patterns

```typescript
// Use useLayoutEffect for DOM measurements (sync, before paint)
import { useLayoutEffect, useState, useRef } from 'react';

function MeasuredComponent() {
  const ref = useRef<HTMLDivElement>(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });

  useLayoutEffect(() => {
    if (ref.current) {
      // Single read + single state update (no thrashing)
      const { width, height } = ref.current.getBoundingClientRect();
      setDimensions({ width, height });
    }
  }, []);

  return <div ref={ref}>Size: {dimensions.width}x{dimensions.height}</div>;
}

// ResizeObserver for responsive measurements (no thrashing)
function useResizeObserver(ref: React.RefObject<HTMLElement>) {
  const [size, setSize] = useState({ width: 0, height: 0 });

  useLayoutEffect(() => {
    if (!ref.current) return;

    const observer = new ResizeObserver(([entry]) => {
      const { width, height } = entry.contentRect;
      setSize({ width, height });
    });

    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [ref]);

  return size;
}
```

---

## 4. MEMORY PROFILING

### Detect Memory Leaks

```typescript
// lib/performance/memory.ts
interface PerformanceMemory {
  usedJSHeapSize: number;
  totalJSHeapSize: number;
  jsHeapSizeLimit: number;
}

function monitorMemory(): void {
  if ('memory' in performance) {
    const memory = (performance as unknown as { memory: PerformanceMemory }).memory;

    setInterval(() => {
      const used = memory.usedJSHeapSize / (1024 * 1024);
      const total = memory.totalJSHeapSize / (1024 * 1024);
      const limit = memory.jsHeapSizeLimit / (1024 * 1024);

      console.log(`Memory: ${used.toFixed(1)}MB / ${total.toFixed(1)}MB (limit: ${limit.toFixed(1)}MB)`);

      // Alert if usage grows continuously
      if (used > total * 0.8) {
        console.warn('Memory usage > 80% of heap');
      }
    }, 10000);
  }
}
```

### Common Leak Patterns

```typescript
// LEAK: Event listener not cleaned up
function LeakyComponent() {
  useEffect(() => {
    window.addEventListener('resize', handleResize);
    // Missing: return () => window.removeEventListener('resize', handleResize);
  }, []);
}

// FIXED: Always clean up
function FixedComponent() {
  useEffect(() => {
    const handler = () => handleResize();
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }, []);
}

// LEAK: Timer not cleared
function LeakyTimer() {
  useEffect(() => {
    setInterval(() => pollData(), 5000);
    // Missing: clearInterval
  }, []);
}

// FIXED: Clear timer
function FixedTimer() {
  useEffect(() => {
    const id = setInterval(() => pollData(), 5000);
    return () => clearInterval(id);
  }, []);
}

// LEAK: AbortController not used
async function leakyFetch() {
  const response = await fetch('/api/data');
  // No way to cancel if component unmounts
}

// FIXED: AbortController
function useFetchWithAbort(url: string) {
  useEffect(() => {
    const controller = new AbortController();
    fetch(url, { signal: controller.signal })
      .then((r) => r.json())
      .then(setData)
      .catch((e) => {
        if (e.name !== 'AbortError') throw e;
      });
    return () => controller.abort();
  }, [url]);
}
```

---

## 5. CODE-LEVEL ANTI-PATTERN DETECTION

### Anti-Pattern Matrix

| ID | Pattern | Impact | Detection |
|----|---------|--------|-----------|
| CP-01 | backdrop-blur on sticky elements | Continuous GPU compositing | CSS selector scan |
| CP-02 | Fake virtualization (render all, overflow hidden) | DOM bloat | DOM count vs visible |
| CP-03 | Unthrottled touch/scroll handlers | Main thread blocking | Event listener audit |
| CP-04 | Heavy CSS transitions on layout properties | Forced reflow per frame | Transition property scan |
| CP-05 | Excessive box-shadow/filter on many elements | Paint cost | CSS property count |
| CP-06 | Synchronous localStorage in render path | Main thread blocking | Call stack analysis |
| CP-07 | Unoptimized SVG (inline, large, animated) | DOM bloat + paint | SVG element audit |

### Detection Script

```typescript
// scripts/detect-anti-patterns.ts
function detectAntiPatterns(): void {
  const results: { id: string; element: string; severity: string }[] = [];

  // CP-01: backdrop-blur on sticky/fixed
  document.querySelectorAll('[style*="backdrop"], [class*="backdrop-blur"]').forEach((el) => {
    const styles = getComputedStyle(el);
    if (styles.position === 'sticky' || styles.position === 'fixed') {
      results.push({
        id: 'CP-01',
        element: el.tagName + (el.id ? `#${el.id}` : ''),
        severity: 'HIGH',
      });
    }
  });

  // CP-02: DOM count vs visible viewport
  const allElements = document.querySelectorAll('*').length;
  if (allElements > 1500) {
    results.push({
      id: 'CP-02',
      element: `Total DOM: ${allElements}`,
      severity: allElements > 3000 ? 'CRITICAL' : 'HIGH',
    });
  }

  // CP-04: Transitions on layout properties
  const layoutProps = ['width', 'height', 'top', 'left', 'right', 'bottom', 'margin', 'padding'];
  document.querySelectorAll('*').forEach((el) => {
    const transition = getComputedStyle(el).transition;
    if (transition && transition !== 'none') {
      for (const prop of layoutProps) {
        if (transition.includes(prop)) {
          results.push({
            id: 'CP-04',
            element: el.tagName + (el.className ? `.${el.className.split(' ')[0]}` : ''),
            severity: 'MEDIUM',
          });
        }
      }
    }
  });

  console.table(results);
}
```

---

## 6. RENDER PROFILING

### PerformanceObserver for Paint Metrics

```typescript
// lib/performance/render-metrics.ts
function monitorRenderMetrics(): void {
  // Paint timing
  const paintObserver = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      console.log(`${entry.name}: ${entry.startTime.toFixed(0)}ms`);
    }
  });
  paintObserver.observe({ type: 'paint', buffered: true });

  // Layout shifts
  interface LayoutShiftSource {
    node?: Element;
    previousRect: DOMRectReadOnly;
    currentRect: DOMRectReadOnly;
  }

  interface LayoutShiftEntry extends PerformanceEntry {
    hadRecentInput: boolean;
    value: number;
    sources?: LayoutShiftSource[];
  }

  let clsValue = 0;
  const clsObserver = new PerformanceObserver((list) => {
    for (const entry of list.getEntries() as LayoutShiftEntry[]) {
      if (!entry.hadRecentInput) {
        clsValue += entry.value;
        console.log(`Layout shift: ${entry.value.toFixed(4)} (total CLS: ${clsValue.toFixed(4)})`);
        entry.sources?.forEach((source) => {
          console.log(`  Shifted element: ${source.node?.tagName}`);
        });
      }
    }
  });
  clsObserver.observe({ type: 'layout-shift', buffered: true });

  // Element timing (LCP candidates)
  interface ElementTimingEntry extends PerformanceEntry {
    element?: Element;
    renderTime: number;
  }

  const elementObserver = new PerformanceObserver((list) => {
    for (const entry of list.getEntries() as ElementTimingEntry[]) {
      console.log(`Element: ${entry.element?.tagName}, Render time: ${entry.renderTime.toFixed(0)}ms`);
    }
  });
  elementObserver.observe({ type: 'element', buffered: true });
}
```

### Layout Thrashing Detection

```typescript
// Detect forced synchronous layouts using LoAF
interface LoAFScriptTiming {
  forcedStyleAndLayoutDuration: number;
  name: string;
  sourceURL: string;
}

interface LoAFEntry extends PerformanceEntry {
  scripts: LoAFScriptTiming[];
}

function detectLayoutThrashing(): void {
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries() as LoAFEntry[]) {
      // Check for forced style/layout
      if (entry.scripts) {
        for (const script of entry.scripts) {
          if (script.forcedStyleAndLayoutDuration > 30) {
            console.error('Layout thrashing detected:', {
              duration: `${entry.duration.toFixed(0)}ms`,
              forcedLayout: `${script.forcedStyleAndLayoutDuration.toFixed(0)}ms`,
              source: script.sourceURL,
              function: script.sourceFunctionName,
              invoker: script.invoker,
            });
          }
        }
      }
    }
  });

  observer.observe({ type: 'long-animation-frame', buffered: true });
}
```

---

## 7. WEB WORKERS

### Offloading Heavy Computation

```typescript
// workers/data-processor.worker.ts
interface DataItem {
  name: string;
  [key: string]: unknown;
}

self.onmessage = (event: MessageEvent) => {
  const { type, payload } = event.data as { type: string; payload: DataItem[] };

  switch (type) {
    case 'SORT_LARGE_DATASET':
      const sorted = payload.sort((a, b) =>
        a.name.localeCompare(b.name, 'he'),
      );
      self.postMessage({ type: 'SORT_COMPLETE', payload: sorted });
      break;

    case 'FILTER_COMPLEX':
      const filtered = payload.filter((item) =>
        complexFilterLogic(item),
      );
      self.postMessage({ type: 'FILTER_COMPLETE', payload: filtered });
      break;
  }
};

// Hook for using Web Workers
// hooks/useWorker.ts
'use client';

import { useEffect, useRef, useState } from 'react';

// React Compiler auto-memoizes — no manual memo needed
export function useWorker<T, R>(
  workerFactory: () => Worker,
) {
  const workerRef = useRef<Worker | null>(null);
  const [result, setResult] = useState<R | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    workerRef.current = workerFactory();
    workerRef.current.onmessage = (e: MessageEvent) => {
      setResult(e.data.payload);
      setLoading(false);
    };

    return () => workerRef.current?.terminate();
  }, []);

  function postMessage(data: T) {
    setLoading(true);
    workerRef.current?.postMessage(data);
  }

  return { result, loading, postMessage };
}
```

---

## 8. CHECKLIST

```markdown
## Runtime Profiling Checklist

### Long Tasks
- [ ] PerformanceObserver monitoring long tasks
- [ ] No tasks > 50ms on critical interaction path
- [ ] scheduler.yield() for heavy event handlers
- [ ] requestIdleCallback for non-critical work
- [ ] Web Workers for CPU-intensive computation

### Layout Thrashing
- [ ] No read-write cycles in loops
- [ ] Batch reads then batch writes (fastdom pattern)
- [ ] useLayoutEffect for DOM measurements
- [ ] ResizeObserver instead of resize events
- [ ] forcedStyleAndLayoutDuration < 30ms (LoAF)

### Memory
- [ ] All event listeners cleaned up
- [ ] All timers/intervals cleared
- [ ] AbortController for fetch requests
- [ ] No detached DOM nodes
- [ ] Memory usage stable over time

### Anti-Patterns
- [ ] No backdrop-blur on sticky elements (CP-01)
- [ ] Virtual scrolling for lists > 100 items (CP-02)
- [ ] Throttled touch/scroll handlers (CP-03)
- [ ] Transitions on transform/opacity only (CP-04)
- [ ] Minimal box-shadow/filter usage (CP-05)
- [ ] No synchronous localStorage in render (CP-06)
```

---

<!-- RUNTIME_PROFILING v24.7.0 | CPU, memory, layout thrashing, anti-patterns, Web Workers -->

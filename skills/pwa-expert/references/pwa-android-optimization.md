# PWA-ANDROID-OPTIMIZATION v24.5.0 SINGULARITY FORGE

> The Android Performance Master & Old Device Compatibility Engine

> **See Also:** `android-rendering-fixes.md` for 8 critical rendering issues (content-visibility, strokeWidth, View Transitions, etc.)

---

## 1. PURPOSE

Android PWAs face unique performance challenges compared to iOS due to differences in GPU acceleration, memory management, and JavaScript engine behavior. This skill provides comprehensive guidance for optimizing PWA performance specifically for Android devices.

**Key Insight:** What works smoothly on iOS Safari may cause significant jank on Android Chrome. Always test on mid-range Android devices (not just flagships).

**Applies To:** React/Vite PWAs targeting Android devices (including legacy Android < Chrome 84)

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/pwa android-audit` | Full Android PWA performance audit | ~3min |
| `/pwa android-fix` | Auto-fix common Android performance issues | ~5min |
| `/pwa old-android` | Apply old Android (< Chrome 84) fallbacks | ~3min |
| `/pwa android-detect` | Setup Android version detection | ~1min |
| `/pwa viewport-fix` | Fix dvh/svh viewport height issues | ~2min |
| `/pwa gap-fallback` | Add flexbox gap fallbacks | ~2min |
| `/pwa blur-remove` | Remove/replace backdrop-filter effects | ~2min |
| `/pwa scroll-optimize` | Optimize scroll performance | ~2min |
| `/pwa memory-audit` | Check for memory leaks | ~3min |
| `/pwa test-matrix` | Generate device testing matrix | ~1min |

---

## 3. WORKFLOW

```
1. DETECT    - Identify Android version and Chrome version
              - Apply detection classes to document root
              - Check feature support (gap, dvh, container queries)

2. ANALYZE   - Run Lighthouse mobile audit
              - Profile scroll and animation performance
              - Check memory usage patterns
              - Identify backdrop-filter usage

3. FIX       - Remove/replace blur effects
              - Add viewport height fallbacks
              - Add flexbox gap fallbacks
              - Ensure passive event listeners
              - Add icon shrink protection
              - Fix text truncation in flex

4. VERIFY    - Test on real mid-range Android device
              - Verify 60fps scroll performance
              - Check memory stays stable
              - Confirm offline mode works
```

---

## 4. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-AND-1 | BACKDROP_FILTER | No unoptimized blur | Disabled or GPU-safe |
| G-AND-2 | GAP_FALLBACK | Flexbox gap works on old Android | Margin fallback present |
| G-AND-3 | DVH_FALLBACK | Viewport height chain | vh -> fill-available -> dvh |
| G-AND-4 | PASSIVE_LISTENERS | All scroll/touch listeners | `{ passive: true }` |
| G-AND-5 | ICON_SHRINK | Icons in flex containers | `shrink-0` applied |
| G-AND-6 | TRUNCATE_MINW | Text truncation in flex | `min-w-0` applied |
| G-AND-7 | MOMENTUM_SCROLL | Scroll containers | `-webkit-overflow-scrolling: touch` |
| G-AND-8 | HOVER_PROTECTION | Hover states | `@media (hover: hover)` |
| G-AND-9 | SAFE_AREA_SINGLE | Safe areas applied once | No double padding |
| G-AND-10 | MIN_FONT_SIZE | Readable text | No text below 12px |
| G-AND-11 | MEMORY_CLEANUP | useEffect cleanups | All subscriptions closed |
| G-AND-12 | BUNDLE_SIZE | Initial JS bundle | < 100KB gzipped |
| **G-AND-13** | **CSS_CONTAINMENT** | **No contain-content on Android** | **CSS override present** |
| **G-AND-14** | **GRADIENT_OPTIMIZE** | **Intelligent gradient fallbacks** | **Not all orange!** |
| **G-AND-15** | **SCROLL_OPTIMIZE** | **is-scrolling class pattern** | **Passive listeners + hover disable** |
| **G-AND-16** | **TOUCH_TARGETS** | **44px minimum touch area** | **before:inset-[-12px] pattern** |
| **G-AND-17** | **SPINNER_A11Y** | **role="status" on spinners** | **aria-label present** |

**Required**: 17/17 gates MUST pass for Android certification.

---

## 5. PERFORMANCE TARGETS

| Metric | Target | Critical | Measurement |
|--------|--------|----------|-------------|
| First Paint | < 0.8s | < 1.2s | Lighthouse FP |
| First Contentful Paint | < 1.0s | < 1.5s | Lighthouse FCP |
| Largest Contentful Paint | < 1.5s | < 2.5s | Lighthouse LCP |
| Time to Interactive | < 1.5s | < 2.5s | Lighthouse TTI |
| Total Blocking Time | < 150ms | < 300ms | Lighthouse TBT |
| Cumulative Layout Shift | 0 | < 0.1 | Lighthouse CLS |
| Scroll FPS | 55-60 | 45+ | DevTools Performance |
| Touch Response | < 50ms | < 100ms | DevTools Performance |
| Bundle Size (gzip) | < 100KB | < 150KB | Build output |
| Memory Usage | < 100MB | < 150MB | DevTools Memory |

### Device Testing Profiles

| Profile | RAM | CPU Throttle | Use Case |
|---------|-----|--------------|----------|
| Low-end | 2GB | Slow 4x | Budget phones |
| Mid-range | 4GB | Slow 2x | Most users |
| High-end | 8GB+ | No throttle | Flagship |

### Legacy Android Testing Matrix

| Device | Chrome | Test Priority |
|--------|--------|---------------|
| Samsung Galaxy A10 | 80 | High (old Chrome) |
| Xiaomi Redmi 8 | 83 | High (gap unsupported) |
| Android 9 emulator | 83 | Medium |
| Android 10 emulator | 90 | Medium |
| Android 13+ modern | 110+ | Low (baseline) |

---

## 6. PRIME DIRECTIVES

1. **NEVER use `backdrop-filter`** on Android - Use solid backgrounds
2. **ALWAYS use `{ passive: true }`** for scroll/touch listeners
3. **ALWAYS add `shrink-0`** to icons in flex containers
4. **ALWAYS add `min-w-0`** to truncating elements in flex
5. **ALWAYS cleanup** subscriptions in useEffect return
6. **ALWAYS use viewport height fallback chain**: `100vh` -> `-webkit-fill-available` -> `100dvh`
7. **ALWAYS protect hover states** with `@media (hover: hover)`
8. **NEVER apply safe areas** to nested elements (root only for horizontal)
9. **ALWAYS add momentum scrolling**: `-webkit-overflow-scrolling: touch`
10. **NEVER use font sizes below 12px** on old Android
11. **ALWAYS test on real mid-range devices** (not just emulators)
12. **ALWAYS lazy load** heavy components and libraries

---

## CRITICAL: Android Performance Requirements

### Passive Event Listeners (MANDATORY)

Android Chrome REQUIRES passive event listeners for smooth scrolling. Non-passive touch handlers cause jank and poor INP scores.

**MANDATORY Pattern:**

```typescript
// ❌ NEVER - Blocks scrolling, causes jank
element.addEventListener('touchstart', handler);
element.addEventListener('touchmove', handler);
element.addEventListener('wheel', handler);

// ✅ ALWAYS - Smooth 60fps scrolling
element.addEventListener('touchstart', handler, { passive: true });
element.addEventListener('touchmove', handler, { passive: true });
element.addEventListener('wheel', handler, { passive: true });
```

**Auto-Enforcement Helper:**

```typescript
const addPassiveEventListener = (
  element: Element,
  event: string,
  handler: EventListener
) => {
  const passiveEvents = ['touchstart', 'touchmove', 'wheel', 'scroll'];
  const options = passiveEvents.includes(event) ? { passive: true } : {};
  element.addEventListener(event, handler, options);
};
```

**Detection in DevTools:**

Chrome DevTools will show a warning in Console:
```
[Violation] Added non-passive event listener to a scroll-blocking event
```

**This is a BLOCKING issue for performance audits.**

---

### INP Optimization (< 100ms target)

Android devices, especially mid-range, need aggressive INP optimization:

**scheduler.yield() for Long Tasks:**

```typescript
async function processLargeList(items: Item[]) {
  for (let i = 0; i < items.length; i++) {
    processItem(items[i]);

    // Yield every 5 items to keep UI responsive
    if (i % 5 === 0) {
      await scheduler.yield();
    }
  }
}
```

**Avoid Main Thread Blocking:**

- Move heavy computation to Web Workers
- Use requestIdleCallback for non-urgent work
- Break up DOM updates with requestAnimationFrame

**INP Budget Allocation:**

| Phase | Target | Max |
|-------|--------|-----|
| Input delay | < 40ms | 50ms |
| Processing | < 40ms | 100ms |
| Presentation | < 20ms | 50ms |
| **Total INP** | **< 100ms** | **200ms** |

---

### Touch Targets (Android Material Guidelines)

All interactive elements MUST be minimum 48dp (approximately 44-48px):

| Element | Minimum Size | Tailwind |
|---------|--------------|----------|
| Buttons | 48x48dp | `min-h-12 min-w-12` |
| Links | 48dp height | `min-h-12 py-3` |
| Icons (tappable) | 48x48dp | `h-12 w-12` |
| Form inputs | 48dp height | `h-12` |
| Checkboxes/Radios | 48x48dp touch area | `before:inset-[-12px]` |
| List items | 48dp height | `min-h-12` |

**Touch Target Expansion Pattern:**

```tsx
// Expand touch area without changing visual size
<button
  className={cn(
    // Visual size
    "h-6 w-6",
    // Expanded 48x48dp touch target
    "relative before:absolute before:inset-[-12px] before:content-['']"
  )}
>
  <Icon className="h-6 w-6" />
</button>
```

---

## 7. KNOWLEDGE BASE

### 7.1 Critical Android vs iOS Differences

#### GPU Acceleration

**The Problem:**
- iOS has dedicated hardware for `backdrop-filter` and blur effects
- Android renders these effects on the CPU, causing frame drops
- Even flagship Android devices struggle with animated blur

**Solution:** Use solid backgrounds instead of blur on Android

```tsx
// ANTI-PATTERN: Blur effects kill Android performance
<div className="backdrop-blur-md bg-white/80">
  {/* Content */}
</div>

// RECOMMENDED: Solid backgrounds with opacity
<div className="bg-white/95 dark:bg-gray-900/95">
  {/* Content */}
</div>

// ADVANCED: Detect Android and conditionally apply
const isAndroid = /Android/i.test(navigator.userAgent);

<div className={cn(
  "transition-colors",
  isAndroid
    ? "bg-white/95"
    : "backdrop-blur-md bg-white/80"
)}>
  {/* Content */}
</div>
```

#### Scroll Handling

**The Problem:**
- iOS Safari ignores non-passive listeners (optimizes by default)
- Chrome blocks scroll waiting for `preventDefault()` check
- This causes scroll jank and input delay

**Solution:** Always use `{ passive: true }` for scroll/touch listeners

```tsx
// ANTI-PATTERN: Blocks scroll on Android
useEffect(() => {
  const handleScroll = () => { /* ... */ };
  window.addEventListener('scroll', handleScroll);
  return () => window.removeEventListener('scroll', handleScroll);
}, []);

// RECOMMENDED: Passive listeners
useEffect(() => {
  const handleScroll = () => { /* ... */ };
  window.addEventListener('scroll', handleScroll, { passive: true });
  return () => window.removeEventListener('scroll', handleScroll);
}, []);

// ANTI-PATTERN: Touch handlers without passive
<div onTouchStart={handleTouch} onTouchMove={handleMove}>

// RECOMMENDED: Use native events with passive flag
useEffect(() => {
  const element = ref.current;
  if (!element) return;

  const handleTouch = (e: TouchEvent) => { /* ... */ };
  element.addEventListener('touchstart', handleTouch, { passive: true });
  element.addEventListener('touchmove', handleTouch, { passive: true });

  return () => {
    element.removeEventListener('touchstart', handleTouch);
    element.removeEventListener('touchmove', handleTouch);
  };
}, []);
```

#### Memory Management

**The Problem:**
- iOS has more RAM and less aggressive garbage collection
- Android has strict memory limits with frequent GC pauses
- GC pauses cause visible frame drops (50-100ms stalls)

**Solution:** Clean up all subscriptions, limit collection sizes

```tsx
// ANTI-PATTERN: Unbounded Map growth
const cache = new Map<string, Data>();
function addToCache(key: string, data: Data) {
  cache.set(key, data); // Grows forever!
}

// RECOMMENDED: LRU cache with size limit
class LRUCache<K, V> {
  private cache = new Map<K, V>();
  private maxSize: number;

  constructor(maxSize = 100) {
    this.maxSize = maxSize;
  }

  set(key: K, value: V) {
    if (this.cache.has(key)) {
      this.cache.delete(key);
    } else if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
    this.cache.set(key, value);
  }

  get(key: K): V | undefined {
    const value = this.cache.get(key);
    if (value !== undefined) {
      this.cache.delete(key);
      this.cache.set(key, value);
    }
    return value;
  }
}

// ANTI-PATTERN: Subscription without cleanup
useEffect(() => {
  const channel = new BroadcastChannel('updates');
  channel.onmessage = handleMessage;
  // Missing cleanup!
}, []);

// RECOMMENDED: Always cleanup subscriptions
useEffect(() => {
  const channel = new BroadcastChannel('updates');
  channel.onmessage = handleMessage;

  return () => {
    channel.close(); // Critical for Android memory!
  };
}, []);
```

#### JavaScript Engine Differences

**The Problem:**
- iOS JavaScriptCore is optimized for Apple silicon
- Android V8 performance varies significantly by device
- Main thread blocking is more noticeable on Android

**Solution:** Minimize main thread work, use Web Workers for heavy computation

```tsx
// ANTI-PATTERN: Heavy computation on main thread
function processLargeData(items: Item[]) {
  return items
    .filter(item => complexValidation(item))
    .map(item => expensiveTransform(item))
    .sort((a, b) => complexCompare(a, b));
}

// RECOMMENDED: Offload to Web Worker
// worker.ts
self.onmessage = (e: MessageEvent<Item[]>) => {
  const result = e.data
    .filter(item => complexValidation(item))
    .map(item => expensiveTransform(item))
    .sort((a, b) => complexCompare(a, b));
  self.postMessage(result);
};

// Component
const worker = new Worker(
  new URL('./worker.ts', import.meta.url),
  { type: 'module' }
);

useEffect(() => {
  worker.onmessage = (e) => setProcessedData(e.data);
  return () => worker.terminate();
}, [worker]);

function processData(items: Item[]) {
  worker.postMessage(items);
}
```

---

### 7.2 CSS Anti-Patterns

```css
/* ANTI-PATTERN 1: backdrop-filter causes CPU rendering on Android */
.modal-overlay {
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

/* RECOMMENDED: Solid overlay */
.modal-overlay {
  background-color: rgba(0, 0, 0, 0.75);
}

/* ANTI-PATTERN 2: Animating box-shadow is expensive */
.card {
  transition: box-shadow 0.3s ease;
}
.card:hover {
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
}

/* RECOMMENDED: Animate opacity of pseudo-element */
.card {
  position: relative;
}
.card::after {
  content: '';
  position: absolute;
  inset: 0;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
}
.card:hover::after {
  opacity: 1;
}

/* ANTI-PATTERN 3: filter: blur() on visible elements */
.blurred-bg {
  filter: blur(20px);
}

/* RECOMMENDED: Pre-blurred image or gradient */
.blurred-bg {
  background-image: url('/pre-blurred-bg.webp');
}

/* ANTI-PATTERN 4: saturate() combined with blur */
.glass-effect {
  backdrop-filter: blur(10px) saturate(180%);
}

/* RECOMMENDED: Simple semi-transparent background */
.glass-effect {
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.9),
    rgba(255, 255, 255, 0.7)
  );
}

/* ANTI-PATTERN 5: will-change overuse */
.every-element {
  will-change: transform, opacity, filter;
}

/* RECOMMENDED: Apply only when needed, remove after */
.animating {
  will-change: transform;
}
/* Remove will-change after animation completes */

/* ANTI-PATTERN 6: CSS containment on Android - CRITICAL */
/* contain-content causes elements to DISAPPEAR during scroll on Chrome <90 */
.card {
  contain: content; /* BROKEN on Android! */
}

/* RECOMMENDED: Disable containment on Android via CSS override */
/* Add to index.css: */
.is-android .contain-content,
.is-android [class*="contain-"] {
  contain: none !important;
}

/* ANTI-PATTERN 7: transition-shadow causes jank */
.card {
  transition: box-shadow 0.3s ease;
}

/* RECOMMENDED: Remove box-shadow from transitions */
.card {
  transition: background-color 0.3s, border-color 0.3s, transform 0.3s;
  /* NOT box-shadow */
}

/* ANTI-PATTERN 8: Making ALL gradients orange on Android */
.is-android [class*="bg-gradient"] {
  background-image: none !important;
  background-color: hsl(var(--primary)) !important; /* WRONG! */
}

/* RECOMMENDED: Intelligent gradient mapping */
/* Subtle background gradients → transparent/card */
.is-android .bg-gradient-to-b.from-card,
.is-android [class*="bg-gradient-to-"][class*="from-card"] {
  background-image: none !important;
  background-color: hsl(var(--card)) !important;
}

/* Primary accent gradients → solid primary (for buttons, nav) */
.is-android .bg-gradient-to-r.from-primary.via-primary {
  background-image: none !important;
  background-color: hsl(var(--primary)) !important;
}

/* Generic fallback → TRANSPARENT (not orange!) */
.is-android [class*="bg-gradient-to-"]:not([class*="from-primary"]):not([class*="from-card"]) {
  background-image: none !important;
  background-color: transparent !important;
}
```

---

### 7.2.1 Scroll Optimization (is-scrolling Pattern)

Disable expensive hover effects during scroll to maintain 60fps.

```typescript
// main.tsx - Add after polyfills import
function setupScrollOptimization() {
  const isAndroid = /Android/i.test(navigator.userAgent);
  if (!isAndroid) return;

  let scrollTimeout: ReturnType<typeof setTimeout> | null = null;
  const root = document.documentElement;

  window.addEventListener(
    "scroll",
    () => {
      if (!root.classList.contains("is-scrolling")) {
        root.classList.add("is-scrolling");
      }
      if (scrollTimeout) clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(() => {
        root.classList.remove("is-scrolling");
      }, 150);
    },
    { passive: true },
  );
}

setupScrollOptimization();
```

```css
/* index.css - Disable hover during scroll */
.is-scrolling .card:hover,
.is-scrolling [class*="hover:"] {
  transform: none !important;
  box-shadow: inherit !important;
}

.is-android .space-y-4,
.is-android [class*="overflow-y"] {
  isolation: isolate;
  will-change: scroll-position;
}
```

---

### 7.2.2 Touch Target Accessibility (44px Minimum)

All interactive elements must have 44x44px minimum touch area (WCAG AAA).

```tsx
// Pattern: Expanded hit area using pseudo-element
<CheckboxPrimitive.Root
  className={cn(
    // Visual size remains 20px
    "relative grid place-content-center peer h-5 w-5 shrink-0",
    // Expanded touch target for mobile accessibility (44x44px)
    "before:absolute before:inset-[-12px] before:content-['']",
    // ... rest of styling
  )}
/>

// Button minimum sizes
className="min-w-11 min-h-11"  // ✅ GOOD (44px)
className="min-w-[2rem] min-h-[2rem]"  // ❌ BAD (32px)
```

```css
/* CSS utility for touch targets */
.touch-target-44 {
  position: relative;
}
.touch-target-44::before {
  content: '';
  position: absolute;
  inset: -12px;  /* Expand 12px in all directions */
}
```

---

### 7.2.3 Spinner Accessibility

All loading spinners must have screen reader support.

```tsx
// ❌ BAD - No accessibility
<div className="flex items-center justify-center py-4">
  <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
</div>

// ✅ GOOD - Accessible spinner
<div
  className="flex items-center justify-center py-4"
  role="status"
  aria-label="טוען נתונים"
>
  <Loader2
    className="w-6 h-6 animate-spin text-muted-foreground"
    aria-hidden="true"
  />
</div>

// Reusable spinner component
export function Spinner({
  className,
  label = "טוען...",
}: {
  className?: string;
  label?: string;
}) {
  return (
    <div role="status" aria-label={label}>
      <Loader2 className={cn("animate-spin", className)} aria-hidden="true" />
      <span className="sr-only">{label}</span>
    </div>
  );
}
```

---

### 7.3 JavaScript Anti-Patterns

```tsx
// ANTI-PATTERN 1: Inline handlers in map create new functions every render
function ItemList({ items }: { items: Item[] }) {
  return (
    <ul>
      {items.map(item => (
        <li key={item.id}>
          {/* New function created on every render! */}
          <button onClick={() => handleClick(item.id)}>
            {item.name}
          </button>
        </li>
      ))}
    </ul>
  );
}

// RECOMMENDED: Component with stable handler (React Compiler auto-memoizes)
function Item({
  item,
  onClick
}: {
  item: Item;
  onClick: (id: string) => void;
}) {
  const handleClick = () => {
    onClick(item.id);
  };

  return (
    <li>
      <button onClick={handleClick}>{item.name}</button>
    </li>
  );
}

function ItemList({ items }: { items: Item[] }) {
  const handleClick = (id: string) => {
    // Handle click
  };

  return (
    <ul>
      {items.map(item => (
        <MemoizedItem key={item.id} item={item} onClick={handleClick} />
      ))}
    </ul>
  );
}

// ANTI-PATTERN 2: useEffect without proper dependencies
useEffect(() => {
  fetchData(); // Runs on every render if fetchData changes!
});

// RECOMMENDED: Explicit dependencies
useEffect(() => {
  fetchData();
}, []); // Or [dependency1, dependency2]

// ANTI-PATTERN 3: setInterval without cleanup
useEffect(() => {
  setInterval(() => {
    checkForUpdates();
  }, 5000);
  // Memory leak! Interval runs forever
}, []);

// RECOMMENDED: Clear interval on cleanup
useEffect(() => {
  const intervalId = setInterval(() => {
    checkForUpdates();
  }, 5000);

  return () => clearInterval(intervalId);
}, []);

// ANTI-PATTERN 4: Large JSON.stringify for comparisons
useEffect(() => {
  // Expensive! Serializes entire object on every check
  if (JSON.stringify(prevData) !== JSON.stringify(currentData)) {
    handleChange();
  }
}, [currentData]);

// RECOMMENDED: Deep comparison library or manual checks
import { isEqual } from 'lodash-es';

const prevDataRef = useRef(currentData);

useEffect(() => {
  if (!isEqual(prevDataRef.current, currentData)) {
    handleChange();
    prevDataRef.current = currentData;
  }
}, [currentData]);

// Or use shallow comparison for flat objects
function shallowEqual(obj1: object, obj2: object): boolean {
  const keys1 = Object.keys(obj1);
  const keys2 = Object.keys(obj2);

  if (keys1.length !== keys2.length) return false;

  return keys1.every(key =>
    obj1[key as keyof typeof obj1] === obj2[key as keyof typeof obj2]
  );
}
```

---

### 7.4 React Anti-Patterns

```tsx
// React Compiler auto-memoizes components in React 19.2.4+
// No need for manual memo() wrapping — just write plain components:
function ExpensiveList({ items }: { items: Item[] }) {
  return (
    <div>
      {items.map(item => (
        <ExpensiveItem key={item.id} item={item} />
      ))}
    </div>
  );
}

// ANTI-PATTERN 2: Inline style objects cause re-renders
function Card({ isActive }: { isActive: boolean }) {
  return (
    <div style={{
      padding: 16,
      backgroundColor: isActive ? 'blue' : 'gray'
    }}>
      {/* New style object every render! */}
    </div>
  );
}

// RECOMMENDED: Use className for dynamic styles (React Compiler auto-memoizes)
function Card({ isActive }: { isActive: boolean }) {
  return (
    <div className={cn(
      "p-4",
      isActive ? "bg-blue-500" : "bg-gray-500"
    )}>
      {/* Tailwind classes are strings, no object creation */}
    </div>
  );
}

// Or if you must use inline styles:
function Card({ isActive }: { isActive: boolean }) {
  const style = {
    padding: 16,
    backgroundColor: isActive ? 'blue' : 'gray'
  };

  return <div style={style}>{/* ... */}</div>;
}

// ANTI-PATTERN 3: Using index as key for dynamic lists
function TodoList({ todos }: { todos: Todo[] }) {
  return (
    <ul>
      {todos.map((todo, index) => (
        <TodoItem key={index} todo={todo} /> // BAD!
      ))}
    </ul>
  );
}

// RECOMMENDED: Use stable unique IDs
function TodoList({ todos }: { todos: Todo[] }) {
  return (
    <ul>
      {todos.map(todo => (
        <TodoItem key={todo.id} todo={todo} />
      ))}
    </ul>
  );
}

// ANTI-PATTERN 4: Unnecessary re-renders from context
const AppContext = createContext<{
  user: User;
  theme: Theme;
  settings: Settings;
} | null>(null);

// Every consumer re-renders when ANY value changes!

// RECOMMENDED: Split contexts by update frequency
const UserContext = createContext<User | null>(null);
const ThemeContext = createContext<Theme>('light');
const SettingsContext = createContext<Settings | null>(null);

// Or use selector pattern with Zustand/Jotai
```

---

### 7.5 Service Worker Strategies

```typescript
// sw.ts - Workbox configuration for Android optimization

import { precacheAndRoute, cleanupOutdatedCaches } from 'workbox-precaching';
import { registerRoute, Route } from 'workbox-routing';
import {
  CacheFirst,
  NetworkFirst,
  StaleWhileRevalidate
} from 'workbox-strategies';
import { ExpirationPlugin } from 'workbox-expiration';
import { CacheableResponsePlugin } from 'workbox-cacheable-response';

// Clean up old caches on activation
cleanupOutdatedCaches();

// Precache app shell
precacheAndRoute(self.__WB_MANIFEST);

// STRATEGY 1: Cache First for static assets (images, fonts)
registerRoute(
  ({ request }) =>
    request.destination === 'image' ||
    request.destination === 'font',
  new CacheFirst({
    cacheName: 'static-assets',
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
      new ExpirationPlugin({
        maxEntries: 100,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
      }),
    ],
  })
);

// STRATEGY 2: Network First for API calls
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new NetworkFirst({
    cacheName: 'api-cache',
    networkTimeoutSeconds: 3, // Fast timeout for Android
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 5 * 60, // 5 minutes
      }),
    ],
  })
);

// STRATEGY 3: Stale While Revalidate for app pages
registerRoute(
  ({ request }) => request.mode === 'navigate',
  new StaleWhileRevalidate({
    cacheName: 'pages-cache',
    plugins: [
      new CacheableResponsePlugin({ statuses: [0, 200] }),
    ],
  })
);

// AGGRESSIVE UPDATE: For critical bug fixes
self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Client notification for updates
self.addEventListener('activate', (event) => {
  event.waitUntil(
    self.clients.claim().then(() => {
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({ type: 'SW_UPDATED' });
        });
      });
    })
  );
});
```

```tsx
// useServiceWorker.ts - Update handling in React

export function useServiceWorker() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [registration, setRegistration] = useState<ServiceWorkerRegistration | null>(null);

  useEffect(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready.then(reg => {
        setRegistration(reg);

        // Check for updates periodically
        const checkInterval = setInterval(() => {
          reg.update();
        }, 60 * 1000); // Every minute

        return () => clearInterval(checkInterval);
      });

      // Listen for new service worker
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        // New SW activated, reload for critical updates
        window.location.reload();
      });

      // Listen for update available message
      navigator.serviceWorker.addEventListener('message', (event) => {
        if (event.data?.type === 'UPDATE_AVAILABLE') {
          setUpdateAvailable(true);
        }
      });
    }
  }, []);

  const applyUpdate = () => {
    if (registration?.waiting) {
      registration.waiting.postMessage({ type: 'SKIP_WAITING' });
    }
  };

  return { updateAvailable, applyUpdate };
}
```

---

### 7.6 Bundle Optimization

```typescript
// vite.config.ts - Android-optimized bundle splitting

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Core vendor chunk (keep small!)
          'vendor-core': ['react', 'react-dom', 'react-router-dom'],

          // UI components (lazy loadable)
          'vendor-ui': [
            '@radix-ui/react-dialog',
            '@radix-ui/react-dropdown-menu',
            '@radix-ui/react-toast',
          ],

          // Data fetching (needed early)
          'vendor-data': ['@tanstack/react-query', '@supabase/supabase-js'],

          // Heavy libraries (lazy load!)
          'vendor-charts': ['recharts'],
          'vendor-forms': ['react-hook-form', '@hookform/resolvers', 'zod'],
        },
      },
    },
    // Smaller chunks for faster parsing on Android
    chunkSizeWarningLimit: 100,
  },
});
```

```tsx
// Lazy loading patterns

// LAZY LOAD: Sentry (heavy, not needed immediately)
const initSentry = async () => {
  if (import.meta.env.PROD) {
    const Sentry = await import('@sentry/react');
    Sentry.init({
      dsn: import.meta.env.VITE_SENTRY_DSN,
      tracesSampleRate: 0.1,
    });
  }
};

// Initialize after app is interactive
useEffect(() => {
  const timeoutId = setTimeout(initSentry, 3000);
  return () => clearTimeout(timeoutId);
}, []);

// LAZY LOAD: Heavy components
const ChartComponent = lazy(() =>
  import('./components/ChartComponent').then(module => ({
    default: module.ChartComponent
  }))
);

// Usage with Suspense
<Suspense fallback={<ChartSkeleton />}>
  <ChartComponent data={data} />
</Suspense>
```

```css
/* Font optimization - System fonts first */

/* ANTI-PATTERN: Loading custom fonts blocks rendering */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

/* RECOMMENDED: System font stack with fallback */
:root {
  --font-sans: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont,
    "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-hebrew: "Segoe UI", "Helvetica Neue", Arial, sans-serif;
}

body {
  font-family: var(--font-sans);
}

[lang="he"] body,
[dir="rtl"] body {
  font-family: var(--font-hebrew);
}

/* If custom font is required, use font-display: swap */
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2');
  font-display: swap;
  font-weight: 400 700;
}
```

---

### 7.7 Initialization Optimization

```tsx
// App.tsx - Optimized initialization for Android

function App() {
  return (
    <Suspense fallback={<AppShell />}>
      <AppProviders>
        <AppRouter />
      </AppProviders>
    </Suspense>
  );
}

// AppShell.tsx - Render immediately, no data dependencies
function AppShell() {
  return (
    <div className="min-h-screen bg-background">
      <header className="h-14 border-b flex items-center px-4">
        <div className="h-6 w-24 bg-muted animate-pulse rounded" />
      </header>
      <main className="p-4">
        <div className="space-y-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-20 bg-muted animate-pulse rounded" />
          ))}
        </div>
      </main>
    </div>
  );
}

// Defer data fetching until after shell renders
function Dashboard() {
  // This query starts AFTER component mounts
  const { data, isPending } = useQuery({
    queryKey: ['dashboard'],
    queryFn: fetchDashboardData,
    // Don't block initial render
    suspense: false,
  });

  if (isPending) {
    return <DashboardSkeleton />;
  }

  return <DashboardContent data={data} />;
}

// Async localStorage hydration (non-blocking)
function useAsyncStorage<T>(key: string, defaultValue: T) {
  const [value, setValue] = useState<T>(defaultValue);
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    // Read from localStorage async (doesn't block render)
    const stored = localStorage.getItem(key);
    if (stored) {
      try {
        setValue(JSON.parse(stored));
      } catch {
        // Ignore parse errors
      }
    }
    setIsHydrated(true);
  }, [key]);

  const setStoredValue = (newValue: T | ((prev: T) => T)) => {
    setValue(prev => {
      const nextValue = typeof newValue === 'function'
        ? (newValue as (prev: T) => T)(prev)
        : newValue;

      // Write async, don't block UI
      queueMicrotask(() => {
        localStorage.setItem(key, JSON.stringify(nextValue));
      });

      return nextValue;
    });
  };

  return [value, setStoredValue, isHydrated] as const;
}
```

---

### 7.8 Android-Specific Optimizations

```tsx
// useAndroidOptimizations.ts

export function useAndroidOptimizations() {
  const isAndroid = /Android/i.test(navigator.userAgent);

  useEffect(() => {
    if (!isAndroid) return;

    // Disable momentum scrolling which can cause jank
    document.body.style.overscrollBehavior = 'none';

    // Reduce animation complexity
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      document.documentElement.style.setProperty('--animation-duration', '0ms');
    }

    // Force hardware acceleration for scrollable containers
    document.querySelectorAll('[data-scroll-container]').forEach(el => {
      (el as HTMLElement).style.transform = 'translateZ(0)';
    });

    return () => {
      document.body.style.overscrollBehavior = '';
    };
  }, [isAndroid]);

  return { isAndroid };
}

// AndroidOptimizedModal.tsx
export function OptimizedModal({ open, onClose, children }: ModalProps) {
  const { isAndroid } = useAndroidOptimizations();

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogOverlay
        className={cn(
          "fixed inset-0 z-50",
          // No blur on Android!
          isAndroid
            ? "bg-black/75"
            : "bg-black/50 backdrop-blur-sm"
        )}
      />
      <DialogContent className="fixed z-50 ...">
        {children}
      </DialogContent>
    </Dialog>
  );
}
```

---

### 7.9 Legacy Android Compatibility (Chrome < 84)

#### Old Android Detection

```typescript
// useAndroidDetection.ts - Comprehensive Android version detection

interface AndroidInfo {
  isAndroid: boolean;
  isOldAndroid: boolean;      // Chrome < 84 or Android < 10
  chromeVersion: number | null;
  androidVersion: number | null;
  supportsGap: boolean;
  supportsDvh: boolean;
  supportsContainerQueries: boolean;
}

export function detectAndroid(): AndroidInfo {
  const ua = navigator.userAgent;
  const isAndroid = /Android/i.test(ua);

  // Extract Chrome version
  const chromeMatch = ua.match(/Chrome\/(\d+)/);
  const chromeVersion = chromeMatch ? parseInt(chromeMatch[1], 10) : null;

  // Extract Android version
  const androidMatch = ua.match(/Android\s+([\d.]+)/);
  const androidVersion = androidMatch ? parseFloat(androidMatch[1]) : null;

  // Feature detection thresholds
  const isOldAndroid = isAndroid && (
    (chromeVersion !== null && chromeVersion < 84) ||
    (androidVersion !== null && androidVersion < 10)
  );

  return {
    isAndroid,
    isOldAndroid,
    chromeVersion,
    androidVersion,
    supportsGap: chromeVersion === null || chromeVersion >= 84,
    supportsDvh: chromeVersion === null || chromeVersion >= 108,
    supportsContainerQueries: chromeVersion === null || chromeVersion >= 105,
  };
}

// React hook
export function useAndroidDetection(): AndroidInfo {
  return detectAndroid();
}

// Apply class to document for CSS targeting
export function applyAndroidClasses(): void {
  const { isAndroid, isOldAndroid, supportsDvh, supportsGap } = detectAndroid();
  const root = document.documentElement;

  if (isAndroid) root.classList.add('is-android');
  if (isOldAndroid) root.classList.add('is-android-old');
  if (!supportsDvh) root.classList.add('no-dvh');
  if (!supportsGap) root.classList.add('no-gap');
}

// Call in main.tsx or App.tsx
// applyAndroidClasses();
```

```tsx
// main.tsx - Apply detection on app load
import { applyAndroidClasses } from './hooks/useAndroidDetection';

// Apply before React renders
applyAndroidClasses();

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

#### dvh/svh Viewport Height Fallbacks

**The Problem:** `dvh` (dynamic viewport height) and `svh` (small viewport height) are not supported in Chrome < 108. This causes full-height layouts to break, especially when the mobile keyboard opens.

```css
/* globals.css - Viewport height fallbacks */

/* ANTI-PATTERN: Only dvh, breaks on old Android */
.full-height {
  height: 100dvh;
}

/* RECOMMENDED: Progressive enhancement with fallbacks */
.full-height {
  /* Fallback 1: Basic vh (works everywhere) */
  height: 100vh;

  /* Fallback 2: iOS Safari fill-available */
  height: -webkit-fill-available;

  /* Modern: Dynamic viewport height */
  height: 100dvh;
}

/* For containers that need small viewport height (excludes keyboard) */
.min-full-height {
  min-height: 100vh;
  min-height: -webkit-fill-available;
  min-height: 100svh;
}

/* For containers that need large viewport height (includes keyboard space) */
.max-full-height {
  height: 100vh;
  height: -webkit-fill-available;
  height: 100lvh;
}

/* When no-dvh class is detected, use JS-calculated height */
.no-dvh .full-height {
  height: calc(var(--vh, 1vh) * 100);
}

.no-dvh .min-full-height {
  min-height: calc(var(--vh, 1vh) * 100);
}
```

#### JavaScript Viewport Height Calculation

```typescript
// useViewportHeight.ts - Dynamic --vh CSS variable

export function useViewportHeight(): void {
  useEffect(() => {
    function updateVh() {
      // Get the actual visible viewport height
      const vh = window.innerHeight * 0.01;
      document.documentElement.style.setProperty('--vh', `${vh}px`);

      // Also set --viewport-height for convenience
      document.documentElement.style.setProperty(
        '--viewport-height',
        `${window.innerHeight}px`
      );
    }

    // Initial calculation
    updateVh();

    // Update on resize (handles keyboard open/close)
    window.addEventListener('resize', updateVh);

    // Update on orientation change
    window.addEventListener('orientationchange', () => {
      // Delay to let browser settle after orientation change
      setTimeout(updateVh, 100);
    });

    // Visual Viewport API for more accurate keyboard detection
    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', updateVh);
    }

    return () => {
      window.removeEventListener('resize', updateVh);
      if (window.visualViewport) {
        window.visualViewport.removeEventListener('resize', updateVh);
      }
    };
  }, []);
}

// Component that handles keyboard visibility
export function useKeyboardVisibility() {
  const [isKeyboardOpen, setIsKeyboardOpen] = useState(false);

  useEffect(() => {
    const initialHeight = window.innerHeight;

    function checkKeyboard() {
      // Keyboard is likely open if viewport shrunk significantly
      const heightDiff = initialHeight - window.innerHeight;
      setIsKeyboardOpen(heightDiff > 150);
    }

    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', checkKeyboard);
      return () => {
        window.visualViewport.removeEventListener('resize', checkKeyboard);
      };
    }

    window.addEventListener('resize', checkKeyboard);
    return () => window.removeEventListener('resize', checkKeyboard);
  }, []);

  return isKeyboardOpen;
}
```

```tsx
// App.tsx - Apply viewport height hook
function App() {
  useViewportHeight();

  return (
    <div className="full-height flex flex-col">
      {/* Content */}
    </div>
  );
}
```

```css
/* Using the --vh variable */
.modal-container {
  /* Fallback */
  height: 100vh;
  /* JS-calculated height that handles keyboard */
  height: calc(var(--vh, 1vh) * 100);
}

.bottom-sheet {
  /* Max height accounts for keyboard */
  max-height: calc(var(--vh, 1vh) * 80);
}

/* Dialog that stays visible when keyboard opens */
.dialog-content {
  max-height: calc(var(--viewport-height, 100vh) - 48px);
  overflow-y: auto;
}
```

#### Flexbox Gap Fallbacks

**The Problem:** CSS `gap` property for flexbox is not supported in Chrome < 84 (only Grid gap works). This causes items to stack without spacing.

```css
/* globals.css - Gap fallbacks */

/* ANTI-PATTERN: gap-only breaks on old Android */
.flex-container {
  display: flex;
  gap: 16px;
}

/* RECOMMENDED: Gap with margin fallback */
.flex-container {
  display: flex;
  gap: 16px;
}

/* Fallback for old Android - applied via JS class detection */
.no-gap .flex-container,
.is-android-old .flex-container {
  gap: 0;
}

.no-gap .flex-container > *,
.is-android-old .flex-container > * {
  margin-inline-end: 16px;
}

.no-gap .flex-container > *:last-child,
.is-android-old .flex-container > *:last-child {
  margin-inline-end: 0;
}

/* For vertical flex containers */
.flex-col-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.no-gap .flex-col-container,
.is-android-old .flex-col-container {
  gap: 0;
}

.no-gap .flex-col-container > *,
.is-android-old .flex-col-container > * {
  margin-bottom: 12px;
}

.no-gap .flex-col-container > *:last-child,
.is-android-old .flex-col-container > *:last-child {
  margin-bottom: 0;
}
```

```tsx
// GapFallback component pattern
interface FlexContainerProps {
  gap?: number;
  direction?: 'row' | 'column';
  children: React.ReactNode;
  className?: string;
}

export function FlexContainer({
  gap = 16,
  direction = 'row',
  children,
  className
}: FlexContainerProps) {
  const { supportsGap } = useAndroidDetection();

  if (supportsGap) {
    return (
      <div
        className={cn("flex", direction === 'column' && "flex-col", className)}
        style={{ gap: `${gap}px` }}
      >
        {children}
      </div>
    );
  }

  // Fallback: Apply margin to children
  const childArray = React.Children.toArray(children);

  return (
    <div className={cn("flex", direction === 'column' && "flex-col", className)}>
      {childArray.map((child, index) => (
        <div
          key={index}
          style={{
            [direction === 'row' ? 'marginInlineEnd' : 'marginBottom']:
              index < childArray.length - 1 ? `${gap}px` : 0
          }}
        >
          {child}
        </div>
      ))}
    </div>
  );
}
```

#### Flex Shrink-0 for Icons

**The Problem:** Icons in flex containers can get squished on old Android when there's not enough space, causing visual bugs.

```css
/* Icon protection in flex containers */

/* ANTI-PATTERN: Icons can squish */
.flex-row {
  display: flex;
  align-items: center;
}

.flex-row svg {
  width: 24px;
  height: 24px;
}

/* RECOMMENDED: Prevent icon squishing */
.flex-row svg,
.flex-row img,
.flex-row [data-icon] {
  flex-shrink: 0;
  min-width: 24px; /* Ensure minimum size */
}

/* Tailwind utility classes to use */
/* Always add shrink-0 to icons in flex containers */
```

```tsx
// Icon component with shrink protection
interface IconProps {
  name: string;
  size?: number;
  className?: string;
}

export function Icon({ name, size = 24, className }: IconProps) {
  return (
    <svg
      className={cn(
        "shrink-0", // CRITICAL: Prevent squishing
        className
      )}
      width={size}
      height={size}
      style={{ minWidth: size, minHeight: size }}
    >
      <use href={`/icons.svg#${name}`} />
    </svg>
  );
}

// Button with icon - correct pattern
function IconButton({ icon, label }: { icon: string; label: string }) {
  return (
    <button className="flex items-center gap-2 min-w-0">
      <Icon name={icon} className="shrink-0" />
      <span className="truncate">{label}</span>
    </button>
  );
}
```

#### Momentum Scrolling for Old WebView

**The Problem:** Old Android WebViews lack smooth momentum scrolling, making swipe gestures feel janky.

```css
/* Momentum scrolling for old WebView */

/* Apply to all scrollable containers */
.scrollable,
[data-scroll],
.overflow-auto,
.overflow-y-auto,
.overflow-x-auto {
  -webkit-overflow-scrolling: touch;

  /* Improve scroll performance */
  overscroll-behavior: contain;
}

/* For horizontal scroll containers */
.horizontal-scroll {
  display: flex;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  overscroll-behavior-x: contain;
  scroll-snap-type: x mandatory;

  /* Hide scrollbar but keep functionality */
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.horizontal-scroll::-webkit-scrollbar {
  display: none;
}

/* Scroll container with hardware acceleration */
.scroll-container {
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  transform: translateZ(0); /* Force GPU layer */
  will-change: scroll-position;
}

/* Remove will-change after scroll ends */
.scroll-container.idle {
  will-change: auto;
}
```

```tsx
// ScrollContainer component with momentum scrolling
export function ScrollContainer({
  children,
  className,
  horizontal = false
}: {
  children: React.ReactNode;
  className?: string;
  horizontal?: boolean;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Add will-change during scroll, remove when idle
    let idleTimeout: NodeJS.Timeout;

    function handleScroll() {
      el.classList.remove('idle');
      clearTimeout(idleTimeout);
      idleTimeout = setTimeout(() => {
        el.classList.add('idle');
      }, 150);
    }

    el.addEventListener('scroll', handleScroll, { passive: true });
    return () => {
      el.removeEventListener('scroll', handleScroll);
      clearTimeout(idleTimeout);
    };
  }, []);

  return (
    <div
      ref={ref}
      className={cn(
        horizontal ? "horizontal-scroll" : "scroll-container",
        "idle",
        className
      )}
      style={{
        WebkitOverflowScrolling: 'touch',
      }}
    >
      {children}
    </div>
  );
}
```

#### Safe Area Handling

**The Problem:** Devices with notches or rounded corners need safe area insets. Double-applying safe areas causes excessive padding.

```css
/* Safe area handling - avoid double padding */

/* Root container handles safe areas ONCE — use RTL-aware logical properties */
.app-root {
  padding-inline-start: env(safe-area-inset-left, 0);
  padding-inline-end: env(safe-area-inset-right, 0);
}

/* Bottom navigation handles bottom safe area */
.bottom-nav {
  padding-bottom: env(safe-area-inset-bottom, 0);
}

/* ANTI-PATTERN: Safe areas on nested elements */
.card {
  padding-left: env(safe-area-inset-left, 0);
  padding-right: env(safe-area-inset-right, 0);
  /* This compounds with parent safe areas! */
}

/* Fixed elements need their own safe areas */
.fixed-bottom {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  /* Add safe area to existing padding */
  padding-bottom: calc(16px + env(safe-area-inset-bottom, 0));
}

.fixed-top {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  /* Top safe area for notch */
  padding-top: calc(16px + env(safe-area-inset-top, 0));
}

/* Fallback for browsers without env() support */
@supports not (padding: env(safe-area-inset-bottom)) {
  .bottom-nav {
    padding-bottom: 0;
  }

  .fixed-bottom {
    padding-bottom: 16px;
  }
}
```

```tsx
// Safe area aware component
function BottomNavigation({ children }: { children: React.ReactNode }) {
  return (
    <nav
      className={cn(
        "fixed bottom-0 inset-x-0",
        "bg-background border-t",
        "flex items-center justify-around",
        "h-16", // Base height without safe area
        // Safe area handled via CSS pb-safe
      )}
      style={{
        paddingBottom: 'env(safe-area-inset-bottom, 0)',
      }}
    >
      {children}
    </nav>
  );
}

// Content that respects bottom navigation
function PageContent({ children }: { children: React.ReactNode }) {
  return (
    <main
      className="flex-1 overflow-y-auto"
      style={{
        // Avoid double safe area - parent handles horizontal
        paddingBottom: 'calc(64px + env(safe-area-inset-bottom, 0))',
      }}
    >
      {children}
    </main>
  );
}
```

#### Hover State Protection

**The Problem:** Touch devices trigger `:hover` states that "stick" after tapping, causing visual bugs on Android.

```css
/* Hover state protection - prevent sticky hover on touch */

/* ANTI-PATTERN: Hover always applies */
.button:hover {
  background-color: var(--hover-bg);
}

/* RECOMMENDED: Only apply hover on devices that support it */
@media (hover: hover) and (pointer: fine) {
  .button:hover {
    background-color: var(--hover-bg);
  }
}

/* Alternative: Use :focus-visible for keyboard users */
.button:focus-visible {
  outline: 2px solid var(--focus-ring);
  outline-offset: 2px;
}

/* Active state for touch feedback */
.button:active {
  background-color: var(--active-bg);
  transform: scale(0.98);
}

/* Card hover effects - desktop only */
@media (hover: hover) and (pointer: fine) {
  .card:hover {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    transform: translateY(-2px);
  }
}

/* Touch-specific feedback */
@media (hover: none) {
  .card:active {
    background-color: var(--card-active);
  }
}

/* Links with hover underline */
.link {
  text-decoration: none;
}

@media (hover: hover) {
  .link:hover {
    text-decoration: underline;
  }
}
```

```tsx
// Hook for hover capability detection
export function useHoverCapable(): boolean {
  return window.matchMedia('(hover: hover) and (pointer: fine)').matches;
}

// Component with conditional hover
function HoverCard({ children, className }: {
  children: React.ReactNode;
  className?: string;
}) {
  const canHover = useHoverCapable();

  return (
    <div
      className={cn(
        "transition-shadow",
        canHover && "hover:shadow-lg hover:-translate-y-0.5",
        className
      )}
    >
      {children}
    </div>
  );
}
```

#### Minimum Font Sizes

**The Problem:** Old Android browsers may have minimum font size settings that override small text, causing layout issues. Some old devices struggle to render very small text clearly.

```css
/* Minimum font sizes for old Android visibility */

/* ANTI-PATTERN: Font sizes below 12px */
.tiny-text {
  font-size: 10px; /* May be forced to 12px+ on old Android */
}

/* RECOMMENDED: Minimum 12px for body text */
:root {
  --min-font-size: 12px;
}

/* Small text with minimum */
.text-sm {
  font-size: max(0.875rem, var(--min-font-size));
}

.text-xs {
  font-size: max(0.75rem, var(--min-font-size));
}

/* Caption text - never below 12px */
.caption {
  font-size: clamp(12px, 0.75rem, 14px);
}

/* Badge/pill text */
.badge-text {
  font-size: max(11px, 0.6875rem);
  /* If you need smaller, use letter-spacing to compensate */
  letter-spacing: 0.02em;
}

/* Form labels and helpers */
.form-label {
  font-size: max(14px, 0.875rem);
}

.form-helper {
  font-size: max(12px, 0.75rem);
  color: var(--muted);
}

/* Old Android override - ensure readability */
.is-android-old .text-xs,
.is-android-old .caption {
  font-size: 12px;
}
```

#### Text Truncation in Flex Containers

**The Problem:** Text truncation with `text-overflow: ellipsis` doesn't work properly in flex containers without `min-width: 0` on old Android.

```css
/* Text truncation fixes for flex containers */

/* ANTI-PATTERN: Truncation without min-w-0 */
.flex-item {
  display: flex;
}

.flex-item .title {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  /* Won't work without min-width: 0! */
}

/* RECOMMENDED: Add min-w-0 to flex children that truncate */
.flex-item {
  display: flex;
  min-width: 0; /* Allow flex item to shrink below content size */
}

.flex-item .title {
  min-width: 0; /* CRITICAL for truncation */
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Tailwind pattern */
.truncate-in-flex {
  @apply min-w-0 truncate;
}
```

```tsx
// List item with proper truncation
function ListItem({
  icon,
  title,
  subtitle,
  action
}: {
  icon: React.ReactNode;
  title: string;
  subtitle?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex items-center gap-3 p-3 min-w-0">
      {/* Icon - prevent shrinking */}
      <div className="shrink-0">
        {icon}
      </div>

      {/* Text container - must have min-w-0 */}
      <div className="flex-1 min-w-0">
        <p className="font-medium truncate">{title}</p>
        {subtitle && (
          <p className="text-sm text-muted-foreground truncate">
            {subtitle}
          </p>
        )}
      </div>

      {/* Action - prevent shrinking */}
      {action && (
        <div className="shrink-0">
          {action}
        </div>
      )}
    </div>
  );
}

// Card with truncated content
function ContentCard({ title, description }: {
  title: string;
  description: string;
}) {
  return (
    <div className="flex flex-col min-w-0 p-4 rounded-lg border">
      {/* Title with truncation */}
      <h3 className="font-semibold min-w-0 truncate">{title}</h3>

      {/* Multi-line truncation (line-clamp) */}
      <p className="text-sm text-muted-foreground line-clamp-2">
        {description}
      </p>
    </div>
  );
}
```

---

### 7.10 Complete Fallback CSS File

```css
/* android-fallbacks.css - Import after main styles */

/* 1. Viewport height fallbacks */
.h-screen,
.min-h-screen {
  height: 100vh;
  height: -webkit-fill-available;
  height: 100dvh;
}

.min-h-screen {
  min-height: 100vh;
  min-height: -webkit-fill-available;
  min-height: 100svh;
}

/* JS-based viewport height */
.h-viewport {
  height: calc(var(--vh, 1vh) * 100);
}

.min-h-viewport {
  min-height: calc(var(--vh, 1vh) * 100);
}

.max-h-viewport {
  max-height: calc(var(--vh, 1vh) * 100);
}

/* 2. Gap fallbacks for old Android */
.is-android-old .flex.gap-1 { gap: 0; }
.is-android-old .flex.gap-1 > *:not(:last-child) { margin-inline-end: 0.25rem; }

.is-android-old .flex.gap-2 { gap: 0; }
.is-android-old .flex.gap-2 > *:not(:last-child) { margin-inline-end: 0.5rem; }

.is-android-old .flex.gap-3 { gap: 0; }
.is-android-old .flex.gap-3 > *:not(:last-child) { margin-inline-end: 0.75rem; }

.is-android-old .flex.gap-4 { gap: 0; }
.is-android-old .flex.gap-4 > *:not(:last-child) { margin-inline-end: 1rem; }

/* Vertical flex-col gaps */
.is-android-old .flex-col.gap-1 > *:not(:last-child) { margin-inline-end: 0; margin-bottom: 0.25rem; }
.is-android-old .flex-col.gap-2 > *:not(:last-child) { margin-inline-end: 0; margin-bottom: 0.5rem; }
.is-android-old .flex-col.gap-3 > *:not(:last-child) { margin-inline-end: 0; margin-bottom: 0.75rem; }
.is-android-old .flex-col.gap-4 > *:not(:last-child) { margin-inline-end: 0; margin-bottom: 1rem; }

/* 3. Icon shrink protection */
.flex svg,
.flex img.icon,
.flex [data-icon],
.inline-flex svg {
  flex-shrink: 0;
}

/* 4. Momentum scrolling */
.overflow-auto,
.overflow-y-auto,
.overflow-x-auto,
[class*="overflow-scroll"] {
  -webkit-overflow-scrolling: touch;
}

/* 5. Hover protection */
@media (hover: none) {
  .hover\:bg-accent:hover {
    background-color: inherit;
  }
  .hover\:bg-muted:hover {
    background-color: inherit;
  }
  .hover\:underline:hover {
    text-decoration: inherit;
  }
}

@media (hover: hover) and (pointer: fine) {
  .touch\:hidden {
    display: none;
  }
}

@media (hover: none) {
  .hover\:hidden {
    display: none;
  }
}

/* 6. Minimum font sizes */
.is-android-old .text-xs {
  font-size: 12px;
}

/* 7. Truncation in flex */
.truncate {
  min-width: 0;
}

.flex > .truncate,
.inline-flex > .truncate {
  min-width: 0;
}

/* 8. Safe area utilities */
.pb-safe {
  padding-bottom: env(safe-area-inset-bottom, 0);
}

.pt-safe {
  padding-top: env(safe-area-inset-top, 0);
}

.px-safe {
  padding-inline-start: env(safe-area-inset-left, 0);
  padding-inline-end: env(safe-area-inset-right, 0);
}

.mb-safe {
  margin-bottom: env(safe-area-inset-bottom, 0);
}

.mt-safe {
  margin-top: env(safe-area-inset-top, 0);
}
```

---

### 7.11 Testing Checklists

#### Detection & Setup
- [ ] `applyAndroidClasses()` runs before React render
- [ ] `.is-android` and `.is-android-old` classes applied correctly
- [ ] `.no-dvh` and `.no-gap` classes work when detected
- [ ] Console shows correct Android/Chrome version detection

#### Viewport Height (dvh/svh)
- [ ] Full-height layouts work on Android < 108
- [ ] Viewport height updates when keyboard opens
- [ ] `--vh` CSS variable updates on resize
- [ ] No content hidden behind URL bar
- [ ] Orientation change handles height update

#### Flexbox Gap
- [ ] Flex containers have proper spacing on Chrome < 84
- [ ] Horizontal gap fallback uses `margin-inline-end`
- [ ] Vertical gap fallback uses `margin-bottom`
- [ ] Last child has no trailing margin
- [ ] RTL layout gap fallbacks work correctly

#### Icons & Images
- [ ] Icons don't squish in narrow flex containers
- [ ] All icons have `shrink-0` class
- [ ] Icons maintain aspect ratio
- [ ] Icon touch targets are 44x44px minimum

#### Scrolling
- [ ] Momentum scrolling works on old WebView
- [ ] `-webkit-overflow-scrolling: touch` applied
- [ ] No scroll jank on long lists
- [ ] Pull-to-refresh works (if implemented)
- [ ] Overscroll behavior is contained

#### Safe Areas
- [ ] Safe areas applied only once (no double padding)
- [ ] Fixed bottom elements respect notch
- [ ] Fixed top elements respect notch
- [ ] Horizontal safe areas on root only
- [ ] env() fallbacks work

#### Hover States
- [ ] No sticky hover on touch devices
- [ ] `@media (hover: hover)` protects hover styles
- [ ] Active states work for touch feedback
- [ ] Focus-visible works for keyboard navigation

#### Font Sizes
- [ ] No text smaller than 12px on old Android
- [ ] Form labels readable (14px+)
- [ ] Helper text readable (12px+)
- [ ] Line height appropriate for readability

#### Text Truncation
- [ ] Truncation works in flex containers
- [ ] `min-w-0` applied to truncating elements
- [ ] Multi-line truncation (line-clamp) works
- [ ] Long titles don't break layouts

#### Before Release
- [ ] Test on mid-range Android device (not emulator)
- [ ] Run Lighthouse audit with mobile preset
- [ ] Check bundle size < 100KB gzipped
- [ ] Verify no `backdrop-filter` on Android
- [ ] All scroll listeners use `{ passive: true }`
- [ ] All intervals/timeouts cleaned up
- [ ] Memory stays stable during extended use
- [ ] No layout thrashing in DevTools Performance
- [ ] Service worker caches critical resources
- [ ] Offline mode works correctly

#### Legacy Android Checklist (Chrome < 84)
- [ ] `applyAndroidClasses()` called in main.tsx before React render
- [ ] Viewport height uses fallback chain: `100vh` -> `-webkit-fill-available` -> `100dvh`
- [ ] `useViewportHeight()` hook applied for keyboard handling
- [ ] Flex gap has margin fallbacks for `.is-android-old`
- [ ] All icons in flex containers have `shrink-0` class
- [ ] All truncating elements have `min-w-0` class
- [ ] `-webkit-overflow-scrolling: touch` on scroll containers
- [ ] Hover styles protected with `@media (hover: hover)`
- [ ] No font sizes below 12px
- [ ] Safe areas applied only once (root for horizontal, fixed elements for top/bottom)
- [ ] `android-fallbacks.css` imported after main styles

---

### 7.12 Common Fixes Quick Reference

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Scroll jank | Non-passive listeners | Add `{ passive: true }` |
| Slow modal open | `backdrop-filter` | Use solid background |
| Memory growth | Unclosed channels | Add cleanup in useEffect |
| Slow list render | Missing memo | Add memo to list items |
| Long initial load | Large bundle | Split chunks, lazy load |
| GC pauses | Large Maps | Use LRU cache with limit |
| Content behind URL bar | `100vh` without fallback | Use dvh fallback chain |
| No flex spacing | Gap unsupported | Add margin fallbacks for old Android |
| Icons squished | Missing shrink-0 | Add `shrink-0` to all flex icons |
| Sticky hover | Touch triggers hover | Use `@media (hover: hover)` |
| Truncation broken | Missing min-w-0 | Add `min-w-0` to flex children |
| Scroll not smooth | Missing momentum | Add `-webkit-overflow-scrolling: touch` |
| Double safe area padding | Nested env() | Apply safe areas once at correct level |
| **Elements disappear during scroll** | **contain-content bug** | **Add CSS override to disable containment on Android** |
| **Scroll jank/lag** | **transition-shadow** | **Remove box-shadow from transition properties** |
| **Logos have orange overlay** | **Naive gradient CSS** | **Use intelligent gradient mapping (not all orange!)** |
| **Scroll jank on hover** | **Expensive hover effects** | **Add `is-scrolling` class pattern** |
| **Touch targets too small** | **Missing hit area expansion** | **Use `before:inset-[-12px]` for 44px** |
| **Spinners not accessible** | **Missing ARIA** | **Add `role="status"` + `aria-label`** |

---

### 7.13 Debugging Tools

#### Chrome DevTools Performance Tab

```bash
# Enable remote debugging on Android device
# 1. Enable Developer Options on Android
# 2. Enable USB Debugging
# 3. Connect device via USB
# 4. Open chrome://inspect in desktop Chrome
# 5. Click "inspect" on your PWA

# In DevTools Performance tab:
# - Enable "Screenshots"
# - Enable "Web Vitals"
# - Set CPU throttling to 4x for low-end simulation
# - Record during typical user interaction
# - Look for:
#   - Long tasks (red blocks > 50ms)
#   - Layout thrashing (purple "Layout" events)
#   - Excessive paint (green "Paint" events)
#   - Memory growth (enable Memory checkbox)
```

#### Lighthouse PWA Audit

```bash
# Run Lighthouse in Chrome DevTools
# 1. Open DevTools > Lighthouse tab
# 2. Select "Mobile" device
# 3. Check: Performance, Accessibility, Best Practices, PWA
# 4. Click "Analyze page load"

# Key PWA checklist items:
# - Installable
# - Works offline
# - Has service worker
# - HTTPS
# - Fast loading on mobile networks
```

#### WebPageTest Mobile Presets

```bash
# https://www.webpagetest.org/
# Settings for Android testing:
# - Test Location: Choose geographically relevant
# - Browser: Chrome on Android
# - Connection: 4G (or 3G for stress testing)
# - Device: Moto G4 (good mid-range baseline)

# Analyze:
# - Waterfall chart for blocking resources
# - Filmstrip for visual progress
# - Core Web Vitals metrics
# - JavaScript execution time
```

#### Memory Profiling

```typescript
// Add memory logging in development
if (import.meta.env.DEV) {
  setInterval(() => {
    if ('memory' in performance) {
      const memory = (performance as unknown as { memory: { usedJSHeapSize: number; totalJSHeapSize: number; jsHeapSizeLimit: number } }).memory;
      console.log('Memory:', {
        usedJSHeapSize: Math.round(memory.usedJSHeapSize / 1024 / 1024) + 'MB',
        totalJSHeapSize: Math.round(memory.totalJSHeapSize / 1024 / 1024) + 'MB',
        jsHeapSizeLimit: Math.round(memory.jsHeapSizeLimit / 1024 / 1024) + 'MB',
      });
    }
  }, 10000);
}

// Performance observer for long tasks
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.duration > 50) {
      console.warn('Long task detected:', {
        duration: Math.round(entry.duration) + 'ms',
        startTime: Math.round(entry.startTime) + 'ms',
      });
    }
  }
});

observer.observe({ entryTypes: ['longtask'] });
```

---

## 8. ANIMATION THROTTLING FOR OLD DEVICES

### Why Throttle Animations

Old Android devices (2-4GB RAM) cannot maintain 60fps. Attempting 60fps causes:
- Frame drops and janky animations
- Battery drain
- Memory pressure
- UI freezing

### Adaptive Frame Rate

```typescript
// Determine optimal FPS based on device capabilities
function getTargetFPS(): number {
  const deviceMemory = (navigator as unknown as { deviceMemory?: number }).deviceMemory ?? 4;
  const hardwareConcurrency = navigator.hardwareConcurrency ?? 4;

  // Ultra low-end: 1-2GB RAM or 2 cores
  if (deviceMemory <= 2 || hardwareConcurrency <= 2) {
    return 30;
  }

  // Low-end: 3-4GB RAM
  if (deviceMemory <= 4) {
    return 45;
  }

  // Mid to high-end
  return 60;
}

// Throttled animation loop
class AdaptiveAnimationLoop {
  private animationId: number | null = null;
  private lastFrameTime = 0;
  private targetFPS: number;
  private frameInterval: number;
  private callback: (deltaTime: number) => void;

  constructor(callback: (deltaTime: number) => void) {
    this.targetFPS = getTargetFPS();
    this.frameInterval = 1000 / this.targetFPS;
    this.callback = callback;

    console.log(`Animation loop targeting ${this.targetFPS}fps`);
  }

  start() {
    const animate = (timestamp: number) => {
      this.animationId = requestAnimationFrame(animate);

      const elapsed = timestamp - this.lastFrameTime;

      if (elapsed >= this.frameInterval) {
        this.lastFrameTime = timestamp - (elapsed % this.frameInterval);
        this.callback(elapsed);
      }
    };

    this.animationId = requestAnimationFrame(animate);
  }

  stop() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
  }

  setTargetFPS(fps: number) {
    this.targetFPS = fps;
    this.frameInterval = 1000 / fps;
  }
}
```

### CSS Animation Optimization

```css
/* Disable animations on low-end devices */
.low-end-device *,
.low-end-device *::before,
.low-end-device *::after {
  animation-duration: 0.01ms !important;
  animation-iteration-count: 1 !important;
  transition-duration: 0.01ms !important;
}

/* Respect user preference */
@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
}

/* Reduce animation complexity on medium devices */
.mid-end-device .complex-animation {
  animation-duration: 0.15s !important;
}
```

### React Hook for Adaptive Animations

```typescript
import { useEffect, useState } from 'react';

function useAdaptiveAnimation() {
  const [config, setConfig] = useState({
    enabled: true,
    duration: 300,
    fps: 60,
  });

  useEffect(() => {
    const memory = (navigator as unknown as { deviceMemory?: number }).deviceMemory ?? 4;

    if (memory <= 2) {
      setConfig({ enabled: false, duration: 0, fps: 30 });
      document.documentElement.classList.add('low-end-device');
    } else if (memory <= 4) {
      setConfig({ enabled: true, duration: 150, fps: 45 });
      document.documentElement.classList.add('mid-end-device');
    }
  }, []);

  return config;
}
```

---

## 9. OEM BATTERY OPTIMIZATION GUIDANCE

### The Problem

Android OEMs (Samsung, Xiaomi, Huawei, etc.) add aggressive battery optimization that kills background processes, including Service Workers. This breaks:
- Push notifications
- Background sync
- Periodic updates
- Offline functionality

### OEM Detection

```typescript
interface OEMBatteryInfo {
  manufacturer: string;
  isProblematic: boolean;
  severity: 'critical' | 'high' | 'medium';
  settingsPath: string;
  steps: string[];
}

function detectOEMBattery(): OEMBatteryInfo | null {
  const ua = navigator.userAgent.toLowerCase();

  const oems: Record<string, Omit<OEMBatteryInfo, 'manufacturer'>> = {
    samsung: {
      isProblematic: true,
      severity: 'critical',
      settingsPath: 'הגדרות > סוללה > מגבלות רקע',
      steps: [
        'פתח הגדרות > אפליקציות',
        'חפש את האפליקציה',
        'סוללה > "ללא הגבלה"',
        'הסר מ"אפליקציות ישנות"',
      ],
    },
    xiaomi: {
      isProblematic: true,
      severity: 'critical',
      settingsPath: 'הגדרות > אפליקציות > ניהול',
      steps: [
        'הגדרות > אפליקציות > ניהול',
        'מצא את האפליקציה',
        'חיסכון בסוללה > "ללא הגבלות"',
        'הפעל "הפעלה אוטומטית"',
      ],
    },
    huawei: {
      isProblematic: true,
      severity: 'critical',
      settingsPath: 'הגדרות > סוללה > הפעלת אפליקציות',
      steps: [
        'הגדרות > סוללה',
        'הפעלת אפליקציות',
        'העבר ל"ידני"',
        'הפעל את כל שלוש האפשרויות',
      ],
    },
    oneplus: {
      isProblematic: true,
      severity: 'high',
      settingsPath: 'הגדרות > סוללה > אופטימיזציה',
      steps: [
        'הגדרות > סוללה',
        'אופטימיזציית סוללה',
        '"אל תבצע אופטימיזציה"',
      ],
    },
  };

  for (const [name, config] of Object.entries(oems)) {
    if (ua.includes(name) || ua.includes(name.replace('xiaomi', 'mi '))) {
      return { manufacturer: name, ...config };
    }
  }

  return null;
}
```

### Show User Guidance

```typescript
function showBatteryOptimizationGuide() {
  const oem = detectOEMBattery();

  if (!oem?.isProblematic) return;

  // Check if already dismissed
  const dismissed = localStorage.getItem(`battery-guide-${oem.manufacturer}`);
  if (dismissed) return;

  // Show after 30 seconds of app use
  setTimeout(() => {
    showBatteryModal(oem);
  }, 30000);
}

// Call on app mount
useEffect(() => {
  if (/Android/i.test(navigator.userAgent)) {
    showBatteryOptimizationGuide();
  }
}, []);
```

### Battery Guide Component

```tsx
function BatteryGuideModal({ oem, onDismiss }: {
  oem: OEMBatteryInfo;
  onDismiss: () => void;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white rounded-xl p-6 m-4 max-w-sm">
        <h2 className="text-lg font-bold mb-2">הגדרות סוללה</h2>
        <p className="text-sm text-muted-foreground mb-4">
          כדי לקבל התראות, יש להגדיר:
        </p>

        <div className="bg-yellow-50 p-3 rounded-lg mb-4 text-sm">
          <strong>נתיב:</strong> {oem.settingsPath}
        </div>

        <ol className="space-y-2 mb-6 text-sm">
          {oem.steps.map((step, i) => (
            <li key={i} className="flex gap-2">
              <span className="w-5 h-5 rounded-full bg-primary text-white text-xs flex items-center justify-center flex-shrink-0">
                {i + 1}
              </span>
              {step}
            </li>
          ))}
        </ol>

        <button
          onClick={onDismiss}
          className="w-full py-3 bg-primary text-white rounded-lg font-medium"
        >
          הבנתי
        </button>
      </div>
    </div>
  );
}
```

---


## 9.1 HARDWARE VS SOFTWARE RENDERING TOGGLE

### The Problem

Old/low-end Android devices may struggle with hardware-accelerated rendering, causing:
- High battery drain
- Thermal throttling
- Frame drops despite GPU usage
- Crashes on low-memory devices

### Detection and Toggle

```typescript
interface RenderingConfig {
  useHardwareAcceleration: boolean;
  reason: string;
  deviceMemory: number;
  hardwareConcurrency: number;
}

function detectOptimalRendering(): RenderingConfig {
  const deviceMemory = (navigator as unknown as { deviceMemory?: number }).deviceMemory ?? 4;
  const hardwareConcurrency = navigator.hardwareConcurrency ?? 4;

  // Low-end device thresholds
  const isLowEnd = deviceMemory <= 2 || hardwareConcurrency <= 2;
  const isVeryLowEnd = deviceMemory <= 1;
  
  // Check for known problematic GPUs (optional)
  const canvas = document.createElement('canvas');
  const gl = canvas.getContext('webgl');
  const renderer = gl?.getParameter(gl.RENDERER) ?? '';
  
  const problematicGPUs = ['Mali-400', 'Mali-T720', 'Adreno 304', 'Adreno 305'];
  const hasProblematicGPU = problematicGPUs.some(gpu => 
    renderer.toLowerCase().includes(gpu.toLowerCase())
  );
  
  // Decide rendering mode
  const useHardwareAcceleration = !isVeryLowEnd && !hasProblematicGPU;
  
  return {
    useHardwareAcceleration,
    reason: isVeryLowEnd ? 'very-low-memory' : 
            hasProblematicGPU ? 'problematic-gpu' :
            isLowEnd ? 'low-end-device' : 'normal',
    deviceMemory,
    hardwareConcurrency,
  };
}

// Apply rendering mode
function applyRenderingMode(config: RenderingConfig): void {
  const root = document.documentElement;
  
  if (config.useHardwareAcceleration) {
    root.classList.add('gpu-rendering');
    root.classList.remove('software-rendering');
  } else {
    root.classList.add('software-rendering');
    root.classList.remove('gpu-rendering');
    
    // Disable GPU-intensive features
    root.style.setProperty('--disable-blur', '1');
    root.style.setProperty('--disable-shadows', '1');
  }
  
  console.log(`[Rendering] Mode: ${config.useHardwareAcceleration ? 'GPU' : 'Software'} (${config.reason})`);
}

// Initialize on app start
const renderingConfig = detectOptimalRendering();
applyRenderingMode(renderingConfig);
```

### CSS Toggle Classes

```css
/* Hardware accelerated (default) */
.gpu-rendering .animated-element {
  transform: translateZ(0);
  will-change: transform;
}

/* Software rendering fallback */
.software-rendering .animated-element {
  transform: none;
  will-change: auto;
}

/* Disable blur effects on software rendering */
.software-rendering .backdrop-blur,
.software-rendering [class*="backdrop-blur"] {
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  background-color: rgba(255, 255, 255, 0.95) !important;
}

/* Disable shadows on software rendering */
.software-rendering .shadow,
.software-rendering [class*="shadow-"] {
  box-shadow: none !important;
}

/* Simpler animations for software rendering */
.software-rendering * {
  animation-duration: 0.1s !important;
  transition-duration: 0.1s !important;
}
```

---

## 9.2 NETWORK RESILIENCE PATTERNS

### Timeout and Retry Configuration

```typescript
interface FetchConfig {
  timeout: number;
  retries: number;
  retryDelay: number;
  backoffMultiplier: number;
}

const NETWORK_CONFIGS: Record<string, FetchConfig> = {
  critical: { timeout: 10000, retries: 3, retryDelay: 1000, backoffMultiplier: 2 },
  normal: { timeout: 5000, retries: 2, retryDelay: 500, backoffMultiplier: 1.5 },
  optional: { timeout: 3000, retries: 1, retryDelay: 0, backoffMultiplier: 1 },
};

async function resilientFetch(
  url: string,
  options: RequestInit = {},
  config: FetchConfig = NETWORK_CONFIGS.normal
): Promise<Response> {
  let lastError: Error | null = null;
  
  for (let attempt = 0; attempt <= config.retries; attempt++) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), config.timeout);
      
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok && attempt < config.retries) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      return response;
    } catch (error) {
      lastError = error as Error;
      
      if (attempt < config.retries) {
        const delay = config.retryDelay * Math.pow(config.backoffMultiplier, attempt);
        await new Promise(resolve => setTimeout(resolve, delay));
        console.log(`[Network] Retry ${attempt + 1}/${config.retries} for ${url}`);
      }
    }
  }
  
  throw lastError;
}
```

### Connection Quality Detection

```typescript
type ConnectionQuality = 'offline' | 'slow-2g' | '2g' | '3g' | '4g' | 'fast';

function detectConnectionQuality(): ConnectionQuality {
  if (!navigator.onLine) return 'offline';
  
  const connection = (navigator as unknown as { connection?: { effectiveType: string; downlink: number } }).connection;
  if (!connection) return 'fast'; // Assume fast if API unavailable
  
  const effectiveType = connection.effectiveType;
  const downlink = connection.downlink; // Mbps
  
  if (effectiveType === 'slow-2g' || downlink < 0.1) return 'slow-2g';
  if (effectiveType === '2g' || downlink < 0.5) return '2g';
  if (effectiveType === '3g' || downlink < 2) return '3g';
  if (effectiveType === '4g' || downlink < 10) return '4g';
  
  return 'fast';
}

// Adapt behavior based on connection
function getNetworkConfig(): FetchConfig {
  const quality = detectConnectionQuality();
  
  switch (quality) {
    case 'offline':
      return { timeout: 1000, retries: 0, retryDelay: 0, backoffMultiplier: 1 };
    case 'slow-2g':
    case '2g':
      return { timeout: 30000, retries: 5, retryDelay: 2000, backoffMultiplier: 2 };
    case '3g':
      return { timeout: 15000, retries: 3, retryDelay: 1000, backoffMultiplier: 2 };
    default:
      return NETWORK_CONFIGS.normal;
  }
}
```

### Offline Queue with Network Awareness

```typescript
class NetworkAwareQueue {
  private queue: QueueItem[] = [];
  private isProcessing = false;
  
  constructor() {
    // Listen for connection changes
    window.addEventListener('online', () => this.processQueue());
    
    const connection = (navigator as unknown as { connection?: EventTarget & { effectiveType: string; downlink: number } }).connection;
    if (connection) {
      connection.addEventListener('change', () => {
        if (navigator.onLine && detectConnectionQuality() !== 'slow-2g') {
          this.processQueue();
        }
      });
    }
  }
  
  async add(item: QueueItem): Promise<void> {
    this.queue.push({ ...item, addedAt: Date.now() });
    this.saveQueue();
    
    // Try immediate processing if online with decent connection
    if (navigator.onLine && detectConnectionQuality() !== 'slow-2g') {
      this.processQueue();
    }
  }
  
  private async processQueue(): Promise<void> {
    if (this.isProcessing || this.queue.length === 0) return;
    
    this.isProcessing = true;
    const config = getNetworkConfig();
    
    while (this.queue.length > 0) {
      const item = this.queue[0];
      
      try {
        await resilientFetch(item.url, item.options, config);
        this.queue.shift();
        this.saveQueue();
      } catch {
        // Stop processing on failure, will retry when connection improves
        break;
      }
    }
    
    this.isProcessing = false;
  }
  
  private saveQueue(): void {
    localStorage.setItem('network-queue', JSON.stringify(this.queue));
  }
}

interface QueueItem {
  url: string;
  options: RequestInit;
  addedAt?: number;
}
```

---

## 9.3 FILE DOWNLOAD MIME TYPE FIX

### The Problem

Android WebViews and some browsers fail to download files properly when:
- Content-Type header is missing or incorrect
- Content-Disposition header is missing
- MIME type doesn't match file extension
- Blob URLs are used without proper type

### Proper File Download Implementation

```typescript
interface DownloadOptions {
  filename: string;
  mimeType: string;
  data: Blob | ArrayBuffer | string;
}

// MIME type map for common file types
const MIME_TYPES: Record<string, string> = {
  // Documents
  pdf: 'application/pdf',
  doc: 'application/msword',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  xls: 'application/vnd.ms-excel',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  csv: 'text/csv',
  txt: 'text/plain',
  
  // Images
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  gif: 'image/gif',
  webp: 'image/webp',
  svg: 'image/svg+xml',
  
  // Archives
  zip: 'application/zip',
  rar: 'application/x-rar-compressed',
  
  // Others
  json: 'application/json',
  xml: 'application/xml',
};

function getMimeType(filename: string): string {
  const ext = filename.split('.').pop()?.toLowerCase() ?? '';
  return MIME_TYPES[ext] ?? 'application/octet-stream';
}

async function downloadFile(options: DownloadOptions): Promise<void> {
  const { filename, data } = options;
  const mimeType = options.mimeType || getMimeType(filename);
  
  // Create blob with correct MIME type
  let blob: Blob;
  if (data instanceof Blob) {
    // Re-create blob with correct type if needed
    blob = new Blob([data], { type: mimeType });
  } else if (data instanceof ArrayBuffer) {
    blob = new Blob([data], { type: mimeType });
  } else {
    blob = new Blob([data], { type: mimeType });
  }
  
  // Create object URL
  const url = URL.createObjectURL(blob);
  
  try {
    // Create download link
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    
    // Required for Firefox
    link.style.display = 'none';
    document.body.appendChild(link);
    
    // Trigger download
    link.click();
    
    // Cleanup
    document.body.removeChild(link);
    
    // Delay URL revocation for Android
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  } catch (error) {
    console.error('[Download] Failed:', error);
    
    // Fallback: open in new tab
    window.open(url, '_blank');
  }
}

// For API responses with file download
async function downloadFromResponse(
  response: Response,
  fallbackFilename: string = 'download'
): Promise<void> {
  // Extract filename from Content-Disposition header
  const contentDisposition = response.headers.get('Content-Disposition');
  let filename = fallbackFilename;
  
  if (contentDisposition) {
    const match = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
    if (match) {
      filename = match[1].replace(/['"]/g, '');
    }
  }
  
  // Get MIME type from response
  const mimeType = response.headers.get('Content-Type') || getMimeType(filename);
  
  // Get data as blob
  const blob = await response.blob();
  
  await downloadFile({ filename, mimeType, data: blob });
}
```

### Server-Side Headers (for reference)

```typescript
// Express.js example
app.get('/download/:filename', (req, res) => {
  const filename = req.params.filename;
  const mimeType = getMimeType(filename);
  
  // CRITICAL headers for Android
  res.setHeader('Content-Type', mimeType);
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.setHeader('Content-Length', fileSize);
  
  // Allow download in PWA
  res.setHeader('Access-Control-Expose-Headers', 'Content-Disposition');
  
  // Send file
  res.sendFile(filepath);
});
```

### React Hook for Downloads

```typescript
function useFileDownload() {
  const [isDownloading, setIsDownloading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const download = async (url: string, filename?: string): Promise<void> => {
    setIsDownloading(true);
    setError(null);
    
    try {
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      await downloadFromResponse(response, filename);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Download failed');
    } finally {
      setIsDownloading(false);
    }
  };
  
  return { download, isDownloading, error };
}
```

---

## 12. RELATED SKILLS

- `/skill offline-first-reference` - Offline data strategies
- `/skill asset-optimization-reference` - Image/font optimization
- `/skill performance` - General web performance
- `/skill monitoring-reference` - Performance monitoring

---

## 13. VERIFICATION SEAL

```
OMEGA_v24.5.0 | PWA_ANDROID_OPTIMIZATION
Gates: 19 | Commands: 10 | Phase: 2.4
ANDROID_FIRST | OLD_DEVICE_COMPAT | GPU_SAFE
NO_BACKDROP_FILTER | PASSIVE_LISTENERS | MEMORY_CLEANUP
NO_CONTAIN_CONTENT | NO_TRANSITION_SHADOW | INTELLIGENT_GRADIENTS
IS_SCROLLING_PATTERN | TOUCH_44PX | SPINNER_A11Y
ANIMATION_THROTTLING | OEM_BATTERY_GUIDANCE
Compatibility: React 19+, Vite 7+, Android Chrome 80+ (with fallbacks)
```

<!-- PWA-EXPERT/ANDROID-OPT v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->

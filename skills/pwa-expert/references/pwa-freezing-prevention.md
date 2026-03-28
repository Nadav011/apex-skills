# PWA Freezing Prevention - Memory Management & Performance

> **v24.5.0 SINGULARITY FORGE** | PWA Expert Skill
> **Critical for:** Old Android devices (2-4GB RAM), Low-end devices, Heavy apps

---

## Why PWAs Freeze on Old Android

| Cause | Impact | Detection |
|-------|--------|-----------|
| Memory pressure | App crashes/freezes | `performance.memory` API |
| No RAM-tier strategies | Same code on 2GB and 8GB devices | `navigator.deviceMemory` |
| WebGL/Canvas context loss | Charts/graphs freeze app | `webglcontextlost` event |
| Synchronous localStorage | Main thread blocks | Profile in DevTools |
| Heavy DOM operations | UI freezes during updates | Long Task API |
| 60fps on weak devices | Janky animations | `requestAnimationFrame` timing |

---

## GATE PWA-13: Memory Management

### 13.1 Memory Pressure Detection (CRITICAL)

```typescript
// Memory pressure detection utility
interface MemoryInfo {
  usedJSHeapSize: number;
  totalJSHeapSize: number;
  jsHeapSizeLimit: number;
}

interface MemoryPressure {
  level: 'low' | 'medium' | 'high' | 'critical';
  percentage: number;
  shouldCleanup: boolean;
  shouldReduceQuality: boolean;
}

function getMemoryPressure(): MemoryPressure | null {
  // Chrome/Edge only - check availability
  if (!('memory' in performance)) {
    return null;
  }

  const memory = (performance as any).memory as MemoryInfo;
  const { usedJSHeapSize, jsHeapSizeLimit } = memory;
  const percentage = (usedJSHeapSize / jsHeapSizeLimit) * 100;

  if (percentage > 85) {
    return {
      level: 'critical',
      percentage,
      shouldCleanup: true,
      shouldReduceQuality: true,
    };
  }

  if (percentage > 70) {
    return {
      level: 'high',
      percentage,
      shouldCleanup: true,
      shouldReduceQuality: true,
    };
  }

  if (percentage > 50) {
    return {
      level: 'medium',
      percentage,
      shouldCleanup: false,
      shouldReduceQuality: false,
    };
  }

  return {
    level: 'low',
    percentage,
    shouldCleanup: false,
    shouldReduceQuality: false,
  };
}

// Periodic memory monitoring
class MemoryMonitor {
  private intervalId: ReturnType<typeof setInterval> | null = null;
  private callbacks: ((pressure: MemoryPressure) => void)[] = [];

  start(intervalMs = 5000) {
    if (this.intervalId) return;

    this.intervalId = setInterval(() => {
      const pressure = getMemoryPressure();
      if (pressure && pressure.shouldCleanup) {
        this.callbacks.forEach(cb => cb(pressure));
      }
    }, intervalMs);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  onPressure(callback: (pressure: MemoryPressure) => void) {
    this.callbacks.push(callback);
    return () => {
      this.callbacks = this.callbacks.filter(cb => cb !== callback);
    };
  }
}

// Usage
const memoryMonitor = new MemoryMonitor();

memoryMonitor.onPressure((pressure) => {
  console.warn(`Memory pressure: ${pressure.level} (${pressure.percentage.toFixed(1)}%)`);

  if (pressure.level === 'critical') {
    // Aggressive cleanup
    clearImageCache();
    unloadOffscreenComponents();
    reduceCacheSize();
    forceGarbageCollection();
  } else if (pressure.level === 'high') {
    // Moderate cleanup
    clearImageCache();
    reduceCacheSize();
  }
});

memoryMonitor.start();
```

### 13.2 RAM-Tier Detection & Strategies (CRITICAL)

```typescript
// RAM tier detection
type RAMTier = 'ultra_low' | 'low' | 'mid' | 'high';

interface DeviceCapabilities {
  ramTier: RAMTier;
  ramGB: number;
  cpuCores: number;
  isLowEnd: boolean;
  maxConcurrentRequests: number;
  maxCacheSize: number;
  maxListItems: number;
  animationFPS: number;
  imageQuality: number;
}

function getDeviceCapabilities(): DeviceCapabilities {
  // navigator.deviceMemory returns RAM in GB (0.25, 0.5, 1, 2, 4, 8)
  // Returns undefined if not supported
  const ramGB = (navigator as any).deviceMemory ?? 4; // Default to 4GB if unknown
  const cpuCores = navigator.hardwareConcurrency ?? 4;

  // Determine RAM tier
  let ramTier: RAMTier;
  if (ramGB <= 1) {
    ramTier = 'ultra_low';
  } else if (ramGB <= 2) {
    ramTier = 'low';
  } else if (ramGB <= 4) {
    ramTier = 'mid';
  } else {
    ramTier = 'high';
  }

  // Configure capabilities based on tier
  const capabilities: Record<RAMTier, Omit<DeviceCapabilities, 'ramTier' | 'ramGB' | 'cpuCores'>> = {
    ultra_low: {
      isLowEnd: true,
      maxConcurrentRequests: 2,
      maxCacheSize: 10 * 1024 * 1024, // 10MB
      maxListItems: 20,
      animationFPS: 30,
      imageQuality: 0.6,
    },
    low: {
      isLowEnd: true,
      maxConcurrentRequests: 3,
      maxCacheSize: 25 * 1024 * 1024, // 25MB
      maxListItems: 50,
      animationFPS: 30,
      imageQuality: 0.7,
    },
    mid: {
      isLowEnd: false,
      maxConcurrentRequests: 4,
      maxCacheSize: 50 * 1024 * 1024, // 50MB
      maxListItems: 100,
      animationFPS: 60,
      imageQuality: 0.8,
    },
    high: {
      isLowEnd: false,
      maxConcurrentRequests: 6,
      maxCacheSize: 100 * 1024 * 1024, // 100MB
      maxListItems: 200,
      animationFPS: 60,
      imageQuality: 0.9,
    },
  };

  return {
    ramTier,
    ramGB,
    cpuCores,
    ...capabilities[ramTier],
  };
}

// Global device capabilities (compute once)
export const deviceCapabilities = getDeviceCapabilities();

// Usage in components
function VirtualizedList({ items }: { items: Item[] }) {
  const { maxListItems, isLowEnd } = deviceCapabilities;

  // Limit visible items based on device capabilities
  const visibleItems = items.slice(0, maxListItems);

  return (
    <VirtualList
      items={visibleItems}
      overscan={isLowEnd ? 2 : 5}
      // Reduce overscan on low-end devices
    />
  );
}
```

### 13.3 WebGL/Canvas Context Loss Handling (CRITICAL)

```typescript
// WebGL context loss is COMMON on mobile - MUST handle!
class WebGLContextManager {
  private canvas: HTMLCanvasElement;
  private gl: WebGLRenderingContext | null = null;
  private animationId: number | null = null;
  private isContextLost = false;
  private onContextLost?: () => void;
  private onContextRestored?: () => void;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.setupContextHandlers();
  }

  private setupContextHandlers() {
    // CRITICAL: Prevent default to allow restoration
    this.canvas.addEventListener('webglcontextlost', (e) => {
      e.preventDefault(); // MUST call to allow restoration
      this.isContextLost = true;

      // Stop animation loop
      if (this.animationId !== null) {
        cancelAnimationFrame(this.animationId);
        this.animationId = null;
      }

      // Notify application
      this.onContextLost?.();

      console.warn('WebGL context lost - will attempt restoration');
    });

    this.canvas.addEventListener('webglcontextrestored', () => {
      this.isContextLost = false;

      // Reinitialize WebGL resources
      this.initWebGL();

      // Restart animation loop
      this.startAnimationLoop();

      // Notify application
      this.onContextRestored?.();

      console.info('WebGL context restored');
    });
  }

  initWebGL() {
    this.gl = this.canvas.getContext('webgl', {
      // These options help prevent context loss
      powerPreference: 'low-power', // Prefer integrated GPU
      failIfMajorPerformanceCaveat: false,
      preserveDrawingBuffer: false, // Better performance
    });

    if (!this.gl) {
      throw new Error('WebGL not supported');
    }

    // Re-create all WebGL resources here
    // (shaders, buffers, textures, etc.)
    this.setupShaders();
    this.setupBuffers();
    this.setupTextures();

    return this.gl;
  }

  private setupShaders() {
    // Implement shader setup
  }

  private setupBuffers() {
    // Implement buffer setup
  }

  private setupTextures() {
    // Implement texture setup
  }

  private startAnimationLoop() {
    const render = () => {
      if (this.isContextLost) return;

      this.render();
      this.animationId = requestAnimationFrame(render);
    };

    this.animationId = requestAnimationFrame(render);
  }

  private render() {
    if (!this.gl || this.isContextLost) return;
    // Render logic here
  }

  setCallbacks(onLost: () => void, onRestored: () => void) {
    this.onContextLost = onLost;
    this.onContextRestored = onRestored;
  }

  destroy() {
    if (this.animationId !== null) {
      cancelAnimationFrame(this.animationId);
    }
    // Clean up WebGL resources
    if (this.gl) {
      const ext = this.gl.getExtension('WEBGL_lose_context');
      ext?.loseContext();
    }
  }
}

// React hook for WebGL context management
function useWebGLContext(canvasRef: React.RefObject<HTMLCanvasElement>) {
  const [isContextLost, setIsContextLost] = useState(false);
  const managerRef = useRef<WebGLContextManager | null>(null);

  useEffect(() => {
    if (!canvasRef.current) return;

    const manager = new WebGLContextManager(canvasRef.current);
    manager.setCallbacks(
      () => setIsContextLost(true),
      () => setIsContextLost(false)
    );
    manager.initWebGL();

    managerRef.current = manager;

    return () => {
      manager.destroy();
    };
  }, [canvasRef]);

  return { isContextLost, manager: managerRef.current };
}
```

### 13.4 Avoiding Synchronous Operations

```typescript
// BAD: Synchronous localStorage blocks main thread
function saveDataBad(key: string, data: object) {
  localStorage.setItem(key, JSON.stringify(data)); // BLOCKS!
}

// GOOD: Use IndexedDB with async wrapper
import { openDB, IDBPDatabase } from 'idb';

class AsyncStorage {
  private dbPromise: Promise<IDBPDatabase>;

  constructor(dbName = 'app-storage') {
    this.dbPromise = openDB(dbName, 1, {
      upgrade(db) {
        db.createObjectStore('keyval');
      },
    });
  }

  async get<T>(key: string): Promise<T | undefined> {
    const db = await this.dbPromise;
    return db.get('keyval', key);
  }

  async set(key: string, value: unknown): Promise<void> {
    const db = await this.dbPromise;
    await db.put('keyval', value, key);
  }

  async delete(key: string): Promise<void> {
    const db = await this.dbPromise;
    await db.delete('keyval', key);
  }

  async clear(): Promise<void> {
    const db = await this.dbPromise;
    await db.clear('keyval');
  }
}

export const asyncStorage = new AsyncStorage();

// Usage
await asyncStorage.set('user', { id: 1, name: 'Test' });
const user = await asyncStorage.get<User>('user');

// If you MUST use localStorage, batch and defer
function deferredLocalStorageSave(key: string, data: object) {
  // Use requestIdleCallback to avoid blocking
  if ('requestIdleCallback' in window) {
    requestIdleCallback(() => {
      localStorage.setItem(key, JSON.stringify(data));
    }, { timeout: 2000 });
  } else {
    // Fallback: use setTimeout
    setTimeout(() => {
      localStorage.setItem(key, JSON.stringify(data));
    }, 0);
  }
}
```

### 13.5 DOM Batching for Heavy Updates

```typescript
// BAD: Multiple DOM updates cause multiple reflows
function updateListBad(items: Item[]) {
  const container = document.getElementById('list')!;
  items.forEach(item => {
    const div = document.createElement('div');
    div.textContent = item.name;
    container.appendChild(div); // Triggers reflow EACH TIME
  });
}

// GOOD: Batch DOM updates with DocumentFragment
function updateListGood(items: Item[]) {
  const container = document.getElementById('list')!;
  const fragment = document.createDocumentFragment();

  items.forEach(item => {
    const div = document.createElement('div');
    div.textContent = item.name;
    fragment.appendChild(div); // No reflow
  });

  container.appendChild(fragment); // Single reflow
}

// BETTER: Use virtual DOM (React) with batched updates
function ListComponent({ items }: { items: Item[] }) {
  // React batches updates automatically
  return (
    <div>
      {items.map(item => (
        <div key={item.id}>{item.name}</div>
      ))}
    </div>
  );
}

// For vanilla JS: Use requestAnimationFrame for visual updates
class DOMBatcher {
  private pending: (() => void)[] = [];
  private scheduled = false;

  add(operation: () => void) {
    this.pending.push(operation);

    if (!this.scheduled) {
      this.scheduled = true;
      requestAnimationFrame(() => {
        const operations = this.pending;
        this.pending = [];
        this.scheduled = false;

        // Execute all operations in single frame
        operations.forEach(op => op());
      });
    }
  }
}

const domBatcher = new DOMBatcher();

// Usage
domBatcher.add(() => element1.style.transform = 'translateX(10px)');
domBatcher.add(() => element2.style.opacity = '0.5');
// Both execute in same animation frame
```

### 13.6 Long Task Detection & Breaking

```typescript
// Detect long tasks that freeze UI
const longTaskObserver = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.duration > 50) { // Tasks > 50ms are "long"
      console.warn(`Long task detected: ${entry.duration.toFixed(2)}ms`, {
        name: entry.name,
        startTime: entry.startTime,
      });

      // Report to analytics
      reportLongTask(entry);
    }
  }
});

longTaskObserver.observe({ entryTypes: ['longtask'] });

// Break long tasks into smaller chunks
async function processLargeArrayWithYield<T>(
  items: T[],
  processor: (item: T) => void,
  chunkSize = 100
) {
  for (let i = 0; i < items.length; i += chunkSize) {
    const chunk = items.slice(i, i + chunkSize);

    // Process chunk
    chunk.forEach(processor);

    // Yield to main thread between chunks
    await yieldToMainThread();
  }
}

function yieldToMainThread(): Promise<void> {
  return new Promise(resolve => {
    // scheduler.yield() is the modern way (Chrome 115+)
    if ('scheduler' in window && 'yield' in (window as any).scheduler) {
      (window as any).scheduler.yield().then(resolve);
    } else {
      // Fallback: setTimeout with 0
      setTimeout(resolve, 0);
    }
  });
}

// Usage
await processLargeArrayWithYield(
  largeDataset,
  (item) => processItem(item),
  50 // Process 50 items, then yield
);
```

---

## Animation Throttling for Old Devices

### Adaptive Frame Rate

```typescript
// Determine target FPS based on device capabilities
function getTargetFPS(): number {
  const { animationFPS } = deviceCapabilities;
  return animationFPS;
}

// Throttled animation loop
class ThrottledAnimationLoop {
  private lastFrameTime = 0;
  private animationId: number | null = null;
  private targetFPS: number;
  private frameInterval: number;
  private renderCallback: (deltaTime: number) => void;

  constructor(renderCallback: (deltaTime: number) => void) {
    this.targetFPS = getTargetFPS();
    this.frameInterval = 1000 / this.targetFPS;
    this.renderCallback = renderCallback;
  }

  start() {
    const animate = (currentTime: number) => {
      this.animationId = requestAnimationFrame(animate);

      const deltaTime = currentTime - this.lastFrameTime;

      // Only render if enough time has passed
      if (deltaTime >= this.frameInterval) {
        // Adjust for frame timing drift
        this.lastFrameTime = currentTime - (deltaTime % this.frameInterval);

        this.renderCallback(deltaTime);
      }
    };

    this.animationId = requestAnimationFrame(animate);
  }

  stop() {
    if (this.animationId !== null) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
  }

  setTargetFPS(fps: number) {
    this.targetFPS = fps;
    this.frameInterval = 1000 / fps;
  }
}

// Usage
const animationLoop = new ThrottledAnimationLoop((deltaTime) => {
  // Update and render
  updatePhysics(deltaTime);
  renderScene();
});

animationLoop.start();

// Dynamically reduce FPS under memory pressure
memoryMonitor.onPressure((pressure) => {
  if (pressure.level === 'critical') {
    animationLoop.setTargetFPS(15);
  } else if (pressure.level === 'high') {
    animationLoop.setTargetFPS(30);
  }
});
```

### CSS Animation Optimization

```css
/* Disable animations on low-end devices */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Low-end device class (added via JS) */
.low-end-device * {
  animation: none !important;
  transition: none !important;
}

/* Or reduce animation complexity */
.low-end-device .complex-animation {
  animation: simple-fade 0.3s ease-out;
}
```

```typescript
// Add low-end class based on device detection
if (deviceCapabilities.isLowEnd) {
  document.documentElement.classList.add('low-end-device');
}
```

---

## Memory Cleanup Strategies

### Image Cache Management

```typescript
class ImageCacheManager {
  private cache = new Map<string, HTMLImageElement>();
  private maxSize: number;

  constructor() {
    this.maxSize = deviceCapabilities.maxCacheSize;
  }

  private getCurrentSize(): number {
    let size = 0;
    this.cache.forEach(img => {
      // Estimate memory: width * height * 4 bytes (RGBA)
      size += img.naturalWidth * img.naturalHeight * 4;
    });
    return size;
  }

  add(url: string, img: HTMLImageElement) {
    // Check if we need to evict
    while (this.getCurrentSize() > this.maxSize && this.cache.size > 0) {
      // Evict oldest (first) entry
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }

    this.cache.set(url, img);
  }

  get(url: string): HTMLImageElement | undefined {
    return this.cache.get(url);
  }

  clear() {
    this.cache.clear();
  }

  // Aggressive cleanup for memory pressure
  reduceSize(targetPercentage = 0.5) {
    const targetSize = this.maxSize * targetPercentage;
    while (this.getCurrentSize() > targetSize && this.cache.size > 0) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
  }
}

export const imageCache = new ImageCacheManager();
```

### Component Unloading

```typescript
// React: Unload offscreen components
function useOffscreenUnload(ref: React.RefObject<HTMLElement>) {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    if (!ref.current) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        setIsVisible(entry.isIntersecting);
      },
      {
        rootMargin: '100px', // Start loading 100px before visible
      }
    );

    observer.observe(ref.current);

    return () => observer.disconnect();
  }, [ref]);

  return isVisible;
}

// Usage
function HeavyComponent() {
  const ref = useRef<HTMLDivElement>(null);
  const isVisible = useOffscreenUnload(ref);

  return (
    <div ref={ref}>
      {isVisible ? (
        <ActualHeavyContent />
      ) : (
        <Placeholder height={300} />
      )}
    </div>
  );
}
```

---

## Freezing Root Cause Checklist

When your PWA freezes, check these in order:

### 1. Memory Issues
- [ ] Check `performance.memory` usage
- [ ] Verify RAM-tier strategies are active
- [ ] Check for memory leaks in DevTools
- [ ] Verify image cache limits

### 2. Long Tasks
- [ ] Enable Long Task observer
- [ ] Check for synchronous operations
- [ ] Verify DOM batching
- [ ] Check for heavy computations on main thread

### 3. Rendering Issues
- [ ] Check animation frame rate
- [ ] Verify CSS animations use `transform`/`opacity`
- [ ] Check for layout thrashing
- [ ] Verify virtualization for long lists

### 4. WebGL/Canvas
- [ ] Handle `webglcontextlost` event
- [ ] Handle `webglcontextrestored` event
- [ ] Use `low-power` preference
- [ ] Limit texture sizes on low-end devices

### 5. Network/IO
- [ ] Avoid synchronous XHR
- [ ] Use IndexedDB instead of localStorage for large data
- [ ] Implement request queuing
- [ ] Use background sync for non-critical updates

---

## Service Worker Memory Considerations

```typescript
// In service worker: Limit cache size
const MAX_CACHE_ITEMS = deviceCapabilities.isLowEnd ? 50 : 200;

async function limitCacheSize(cacheName: string, maxItems: number) {
  const cache = await caches.open(cacheName);
  const keys = await cache.keys();

  if (keys.length > maxItems) {
    // Delete oldest entries
    const deleteCount = keys.length - maxItems;
    await Promise.all(
      keys.slice(0, deleteCount).map(key => cache.delete(key))
    );
  }
}

// Call after adding to cache
self.addEventListener('fetch', (event) => {
  event.respondWith(
    (async () => {
      const response = await fetch(event.request);

      if (response.ok) {
        const cache = await caches.open('dynamic');
        await cache.put(event.request, response.clone());
        await limitCacheSize('dynamic', MAX_CACHE_ITEMS);
      }

      return response;
    })()
  );
});
```

---

## Quick Fixes for Common Freezing Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Freeze on scroll | No virtualization | Use `react-window` or `@tanstack/virtual` |
| Freeze on input | No debounce | Add 150-300ms debounce |
| Freeze on page load | Heavy initialization | Defer non-critical JS |
| Freeze after time | Memory leak | Check event listeners, timers |
| Freeze on chart render | Canvas overload | Reduce data points, use `low-power` |
| Freeze on image gallery | No lazy loading | Implement intersection observer |
| Random freezes | GC pressure | Reduce object allocations |

<!-- PWA-EXPERT/FREEZING-PREVENTION v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->

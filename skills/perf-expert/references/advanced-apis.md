# Advanced APIs - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Advanced
> Consolidates: webgpu-compute, webcodecs, webassembly-perf, background-sync, bfcache-optimization, request-idle-callback

---

## 1. WEBGPU COMPUTE

### Overview

WebGPU provides access to GPU hardware for compute tasks. Useful for data processing, image manipulation, and ML inference.

### Basic Setup

```typescript
// lib/webgpu/setup.ts
async function initWebGPU(): Promise<{
  device: GPUDevice;
  adapter: GPUAdapter;
} | null> {
  if (!navigator.gpu) {
    console.warn('WebGPU not supported');
    return null;
  }

  const adapter = await navigator.gpu.requestAdapter();
  if (!adapter) return null;

  const device = await adapter.requestDevice();
  return { device, adapter };
}
```

### Compute Shader Example

```typescript
// Image processing on GPU
async function processImageGPU(
  device: GPUDevice,
  imageData: ImageData,
): Promise<ImageData> {
  const shaderModule = device.createShaderModule({
    code: `
      @group(0) @binding(0) var<storage, read> input: array<u32>;
      @group(0) @binding(1) var<storage, read_write> output: array<u32>;

      @compute @workgroup_size(256)
      fn main(@builtin(global_invocation_id) id: vec3<u32>) {
        let i = id.x;
        if (i >= arrayLength(&input)) { return; }

        let pixel = input[i];
        let r = (pixel >> 0u) & 0xFFu;
        let g = (pixel >> 8u) & 0xFFu;
        let b = (pixel >> 16u) & 0xFFu;
        let a = (pixel >> 24u) & 0xFFu;

        // Grayscale conversion
        let gray = u32(f32(r) * 0.299 + f32(g) * 0.587 + f32(b) * 0.114);
        output[i] = gray | (gray << 8u) | (gray << 16u) | (a << 24u);
      }
    `,
  });

  // Create buffers, bind groups, dispatch compute pipeline...
  // See WebGPU documentation for full pipeline setup
  return imageData;
}
```

### When to Use WebGPU

| Task | CPU | WebGPU | Speedup |
|------|-----|--------|---------|
| Image filters (1000x1000) | 150ms | 5ms | 30x |
| Matrix multiplication (1024x1024) | 2000ms | 15ms | 130x |
| Particle simulation (100K) | 500ms | 2ms | 250x |
| ML inference | varies | varies | 5-50x |

**Browser support:** Chrome 113+, Firefox 132+, Safari 18+ (limited).

---

## 2. WEBCODECS

### Video Processing

```typescript
// lib/webcodecs/video-decoder.ts
async function decodeVideo(videoUrl: string): Promise<VideoFrame[]> {
  const response = await fetch(videoUrl);
  const buffer = await response.arrayBuffer();

  const frames: VideoFrame[] = [];

  const decoder = new VideoDecoder({
    output: (frame) => {
      frames.push(frame);
    },
    error: (e) => console.error('Decode error:', e),
  });

  decoder.configure({
    codec: 'vp8', // or 'avc1.42E01E' for H.264
    codedWidth: 1280,
    codedHeight: 720,
  });

  // Feed encoded chunks to decoder
  // (simplified -- actual implementation needs demuxing)

  await decoder.flush();
  return frames;
}
```

### Camera Streaming

```typescript
// Efficient camera capture with WebCodecs
async function startCameraCapture(): Promise<void> {
  const stream = await navigator.mediaDevices.getUserMedia({
    video: { width: 1280, height: 720 },
  });

  const track = stream.getVideoTracks()[0];
  const processor = new MediaStreamTrackProcessor({ track });
  const reader = processor.readable.getReader();

  while (true) {
    const { value: frame, done } = await reader.read();
    if (done) break;

    // Process frame (e.g., apply filter, encode)
    processFrame(frame);
    frame.close(); // Important: release frame resources
  }
}
```

---

## 3. WEBASSEMBLY (WASM)

### Loading WASM Modules

```typescript
// lib/wasm/loader.ts
let wasmModule: WebAssembly.Instance | null = null;

async function loadWasm(wasmUrl: string): Promise<WebAssembly.Instance> {
  if (wasmModule) return wasmModule;

  // Streaming compilation (most efficient)
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch(wasmUrl),
    {
      env: {
        // Import functions the WASM module needs
        log: (value: number) => console.log('WASM:', value),
      },
    },
  );

  wasmModule = instance;
  return instance;
}

// Usage
const wasm = await loadWasm('/compute.wasm');
const result = (wasm.exports.processData as Function)(inputData);
```

### WASM Performance Features

```
WASM 3.0 Features:
├── SIMD (Single Instruction, Multiple Data)
│   └── Process 4-8 values in one instruction
├── Threads (SharedArrayBuffer + Atomics)
│   └── True parallelism across CPU cores
├── Tail Calls
│   └── Efficient recursion without stack overflow
└── Exception Handling
    └── Native try/catch in WASM
```

### When to Use WASM

| Task | JS Performance | WASM Performance | Use WASM? |
|------|---------------|------------------|-----------|
| JSON parsing | Fast | Slightly faster | No |
| Crypto operations | Moderate | 3-5x faster | Yes |
| Image processing | Slow | 5-10x faster | Yes |
| Physics simulation | Moderate | 10-20x faster | Yes |
| String manipulation | Fast | Comparable | No |
| DOM manipulation | N/A | Cannot (needs JS) | No |

---

## 4. BACKGROUND SYNC API

### One-Off Sync

```typescript
// Register a one-off sync when offline
async function registerSync(tag: string): Promise<void> {
  const registration = await navigator.serviceWorker.ready;

  if ('sync' in registration) {
    await registration.sync.register(tag);
  } else {
    // Fallback: try immediate
    await processSync(tag);
  }
}

// Service Worker: handle sync event
// sw.ts
self.addEventListener('sync', (event: SyncEvent) => {
  if (event.tag === 'send-pending-orders') {
    event.waitUntil(sendPendingOrders());
  }
});

async function sendPendingOrders(): Promise<void> {
  const db = await openDB('offline-queue');
  const orders = await db.getAll('pending-orders');

  for (const order of orders) {
    try {
      await fetch('/api/orders', {
        method: 'POST',
        body: JSON.stringify(order),
      });
      await db.delete('pending-orders', order.id);
    } catch {
      // Will retry on next sync event
      throw new Error('Sync failed, will retry');
    }
  }
}
```

### Periodic Background Sync

```typescript
// Type augmentations for Background Sync APIs
interface PeriodicSyncManager {
  register(tag: string, options?: { minInterval: number }): Promise<void>;
}

interface SyncManager {
  register(tag: string): Promise<void>;
}

interface ServiceWorkerRegistrationSync extends ServiceWorkerRegistration {
  periodicSync: PeriodicSyncManager;
  sync: SyncManager;
}

interface PeriodicSyncEvent extends ExtendableEvent {
  tag: string;
}

// Register periodic sync (Chromium-only)
async function registerPeriodicSync(): Promise<void> {
  const registration = await navigator.serviceWorker.ready;

  if ('periodicSync' in registration) {
    const status = await navigator.permissions.query({
      name: 'periodic-background-sync' as PermissionName,
    });

    if (status.state === 'granted') {
      await (registration as ServiceWorkerRegistrationSync).periodicSync.register('sync-data', {
        minInterval: 24 * 60 * 60 * 1000, // 24 hours
      });
    }
  }
}

// sw.ts
self.addEventListener('periodicsync', (event: PeriodicSyncEvent) => {
  if (event.tag === 'sync-data') {
    event.waitUntil(syncLatestData());
  }
});
```

### React Integration

```typescript
// hooks/useBackgroundSync.ts
'use client';

// React Compiler auto-memoizes — no manual memo needed

export function useBackgroundSync(tag: string) {
  async function sync(data: unknown) {
    // Store data in IndexedDB for the service worker
    const db = await openDB('sync-queue');
    await db.add('pending', { tag, data, timestamp: Date.now() });

    // Register sync
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      const reg = await navigator.serviceWorker.ready;
      await (reg as ServiceWorkerRegistrationSync).sync.register(tag);
    } else {
      // Fallback: immediate fetch
      await fetch(`/api/${tag}`, {
        method: 'POST',
        body: JSON.stringify(data),
      });
    }
  }

  return { sync };
}
```

---

## 5. BFCACHE OPTIMIZATION

### What Blocks BFCache

| Blocker | Severity | Fix |
|---------|----------|-----|
| `unload` event listener | Critical | Use `pagehide` instead |
| `Cache-Control: no-store` | Critical | Use `no-cache` or specific cache headers |
| Open WebSocket | Conditional | Close on `pagehide`, reconnect on `pageshow` |
| Pending `fetch()` / `XMLHttpRequest` | Conditional | Abort on `pagehide` |
| Active `IndexedDB` transaction | Conditional | Close transactions on `pagehide` |
| `window.opener` reference | Conditional | Use `rel="noopener"` |
| Granted permissions (mic/camera) | Conditional | Release on `pagehide` |

### BFCache-Safe Patterns

```typescript
// hooks/useBfCache.ts
'use client';

import { useEffect } from 'react';

export function useBfCache() {
  useEffect(() => {
    const handlePageHide = (event: PageTransitionEvent) => {
      if (event.persisted) {
        // Page is going into BFCache
        // Clean up resources that block BFCache
      }
    };

    const handlePageShow = (event: PageTransitionEvent) => {
      if (event.persisted) {
        // Page restored from BFCache
        // Reconnect WebSockets, refresh stale data
        refreshStaleData();
      }
    };

    window.addEventListener('pagehide', handlePageHide);
    window.addEventListener('pageshow', handlePageShow);

    return () => {
      window.removeEventListener('pagehide', handlePageHide);
      window.removeEventListener('pageshow', handlePageShow);
    };
  }, []);
}
```

### Tracked WebSocket Pattern

```typescript
// lib/bfcache/tracked-websocket.ts
class TrackedWebSocket {
  private ws: WebSocket | null = null;
  private url: string;

  constructor(url: string) {
    this.url = url;
    this.connect();
    this.setupBfCacheHandlers();
  }

  private connect(): void {
    this.ws = new WebSocket(this.url);
  }

  private setupBfCacheHandlers(): void {
    window.addEventListener('pagehide', () => {
      this.ws?.close(); // Allow BFCache
    });

    window.addEventListener('pageshow', (event) => {
      if ((event as PageTransitionEvent).persisted) {
        this.connect(); // Reconnect after BFCache restore
      }
    });
  }

  send(data: string): void {
    this.ws?.send(data);
  }
}
```

### BFCache Testing

```
Chrome DevTools:
1. Application tab -> Back/Forward Cache
2. Click "Test back/forward cache"
3. Review blockers listed
4. Fix issues and re-test
```

---

## 6. REQUESTIDLECALLBACK

### Overview

`requestIdleCallback` schedules work during browser idle periods, after the browser has finished critical rendering work.

### Patterns

```typescript
// 1. Analytics queue
const analyticsQueue: Array<() => void> = [];

function queueAnalytics(event: AnalyticsEvent): void {
  analyticsQueue.push(() => sendAnalytics(event));
  scheduleFlush();
}

function scheduleFlush(): void {
  requestIdleCallback((deadline) => {
    while (analyticsQueue.length > 0 && deadline.timeRemaining() > 5) {
      const task = analyticsQueue.shift();
      task?.();
    }
    if (analyticsQueue.length > 0) scheduleFlush();
  });
}

// 2. Lazy hydration
requestIdleCallback(() => {
  // Hydrate non-critical components during idle time
  import('./NonCriticalWidget').then((m) => m.hydrate());
});

// 3. Prefetching
requestIdleCallback(() => {
  // Prefetch likely next pages during idle
  const links = document.querySelectorAll('a[data-prefetch]');
  links.forEach((link) => {
    const href = link.getAttribute('href');
    if (href) {
      const prefetchLink = document.createElement('link');
      prefetchLink.rel = 'prefetch';
      prefetchLink.href = href;
      document.head.appendChild(prefetchLink);
    }
  });
});

// 4. Cache warming
requestIdleCallback(
  () => {
    warmFrequentlyAccessedData();
  },
  { timeout: 5000 }, // Ensure it runs within 5 seconds
);
```

### Browser Support

| API | Chrome | Firefox | Safari | Edge |
|-----|--------|---------|--------|------|
| requestIdleCallback | 47+ | 55+ | Yes (16.4+) | 79+ |
| Background Sync | 49+ | No | No | 79+ |
| Periodic Sync | 80+ | No | No | 80+ |
| BFCache | All modern | All modern | All modern | All modern |
| WebGPU | 113+ | 132+ | 18+ (limited) | 113+ |
| WebCodecs | 94+ | 130+ | 16.4+ | 94+ |
| WASM SIMD | 91+ | 89+ | 16.4+ | 91+ |

---

## 7. CHECKLIST

```markdown
## Advanced APIs Checklist

### BFCache
- [ ] No 'unload' event listeners (use 'pagehide')
- [ ] No Cache-Control: no-store on HTML
- [ ] WebSockets close on pagehide, reconnect on pageshow
- [ ] Pending fetch aborted on pagehide
- [ ] rel="noopener" on external links
- [ ] BFCache tested in DevTools

### Background Sync
- [ ] Offline queue in IndexedDB
- [ ] Service Worker sync event handler
- [ ] Fallback for unsupported browsers
- [ ] Retry logic for failed syncs

### requestIdleCallback
- [ ] Analytics deferred to idle time
- [ ] Non-critical prefetching during idle
- [ ] Cache warming during idle
- [ ] Timeout set for time-sensitive idle work

### WebGPU / WASM (When Applicable)
- [ ] Feature detection before use
- [ ] Fallback to CPU implementation
- [ ] Streaming WASM compilation
- [ ] Memory management (close frames, free buffers)
```

---

<!-- ADVANCED_APIS v24.7.0 | WebGPU, WebCodecs, WASM, Background Sync, BFCache, requestIdleCallback -->

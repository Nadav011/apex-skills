# PWA Auto-Update Pattern — 5-Layer Defense-in-Depth

> **v1.0.0** | Mandatory for ALL PWA projects | Cross-platform: Chrome, Firefox, Safari, iOS, Android
> **Source**: Cash Control (Z) — Feb 2026 | WebKit Bug 199110 research

## Problem

After deployment, users get stuck on old cached versions. The Service Worker caches the old files, and without explicit reload logic, the page never updates — even though `skipWaiting` and `clientsClaim` are configured.

## Root Cause

`skipWaiting` + `clientsClaim` make the new SW take control immediately, BUT the page still serves the OLD cached response. The browser needs a `location.reload()` to fetch fresh content from the new SW. Without a `controllerchange` listener, the reload never happens.

## The 5-Layer Defense

### Layer 1: `controllerchange` → Auto-Reload (Primary)

```typescript
let isInitialRegistration = !navigator.serviceWorker.controller;
let refreshing = false;

navigator.serviceWorker.addEventListener("controllerchange", () => {
  if (isInitialRegistration) {
    // First-ever SW registration — don't reload
    isInitialRegistration = false;
    return;
  }
  if (refreshing) return;
  refreshing = true;
  window.location.reload();
});
```

**Why `isInitialRegistration`**: Without this guard, first-time visitors get an unnecessary reload. `navigator.serviceWorker.controller` is `null` on first visit, so when the SW activates, `controllerchange` fires — but there's no stale content to clear.

**Platform support**: Chrome ✅ | Firefox ✅ | Safari macOS ✅ | iOS Safari ⚠️ (may not fire)

### Layer 2: iOS Safari Fallback (3-Second Timeout)

```typescript
onNeedRefresh() {
  updateSW(true); // calls skipWaiting
  setTimeout(() => {
    if (!refreshing) {
      refreshing = true;
      window.location.reload();
    }
  }, 3000);
},
```

**Why**: WebKit Bug 199110 — `controllerchange` may not fire reliably on iOS Safari. Fixed in iOS 16 but edge cases remain in PWA standalone mode. The 3s timeout is a safety net.

**Platform support**: Covers iOS Safari browser + iOS PWA standalone

### Layer 3: `visibilitychange` → Check for Updates

```typescript
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible" && !refreshing) {
    navigator.serviceWorker
      .getRegistration()
      .then((reg) => reg?.update())
      .catch(() => {}); // Non-critical
  }
});
```

**Why**: When user switches tabs/apps and returns, immediately check for a new SW. This catches deployments that happened while the tab was in the background.

**Platform support**: Universal ✅

### Layer 4: Periodic Polling (Every 60 Seconds)

```typescript
onRegisteredSW(_swUrl, registration) {
  if (registration) {
    setInterval(() => registration.update(), 60_000);
  }
},
```

**Why**: For users who keep the tab open continuously. 60s is aggressive but ensures max 60s staleness window. `registration.update()` does a byte-for-byte comparison of `sw.js` — no-op if unchanged.

**Platform support**: Universal ✅

### Layer 5: Stale Chunk Recovery (Last Resort)

```typescript
const STALE_CHUNK_PATTERNS = [
  "MIME type",
  "Failed to fetch dynamically imported module",
  "Importing a module script failed",
  "error loading dynamically imported module",
  "Loading chunk",
  "ChunkLoadError",
];

function handleStaleChunk(errorMessage: string): void {
  // Max 2 attempts to prevent infinite loops
  if (reloadsInWindow >= 2) return;

  // CRITICAL: Clear caches FIRST, then reload
  // Without clearing, SW serves the same stale chunks again
  void clearSwAndCaches().finally(() => window.location.reload());
}

async function clearSwAndCaches(): Promise<void> {
  const registrations = await navigator.serviceWorker.getRegistrations();
  await Promise.all(registrations.map((r) => r.unregister()));
  const keys = await caches.keys();
  await Promise.all(keys.map((k) => caches.delete(k)));
}
```

**Why**: When hashed filenames change after deployment, old chunks return HTML (via SPA fallback rewrite) instead of JS. This detects the MIME type error and does a clean recovery.

**Platform support**: Universal ✅

## Required Workbox Configuration

```typescript
// vite-plugin-pwa workbox config
{
  skipWaiting: true,        // New SW activates immediately
  clientsClaim: true,       // New SW claims all tabs immediately
  cleanupOutdatedCaches: true, // Remove old Workbox caches
}
```

## Required Cache Headers (Vercel/CDN)

```json
{ "source": "/sw.js", "headers": [{ "key": "Cache-Control", "value": "public, max-age=0, must-revalidate" }] },
{ "source": "/index.html", "headers": [{ "key": "Cache-Control", "value": "public, max-age=0, must-revalidate" }] },
{ "source": "/manifest.webmanifest", "headers": [{ "key": "Cache-Control", "value": "public, max-age=0, must-revalidate" }] },
{ "source": "/assets/(.*)", "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }] }
```

## Full Implementation Template (Vite + vite-plugin-pwa)

```typescript
// pwa-registration.ts — Copy this to any Vite PWA project
import { logDebug, logError } from "@/lib/logging/logger";

const SW_INIT_DELAY_MS = 1000;
const SW_UPDATE_INTERVAL_MS = 60_000;
const CONTROLLER_CHANGE_TIMEOUT_MS = 3000;

export function registerPWA(): void {
  if (!("serviceWorker" in navigator)) return;

  let isInitialRegistration = !navigator.serviceWorker.controller;
  let refreshing = false;

  // Layer 1: controllerchange → auto-reload
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (isInitialRegistration) {
      isInitialRegistration = false;
      return;
    }
    if (refreshing) return;
    refreshing = true;
    logDebug("New service worker activated, reloading for fresh content");
    window.location.reload();
  });

  // Layer 3: visibilitychange → check for updates
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible" && !refreshing) {
      navigator.serviceWorker
        .getRegistration()
        .then((reg) => {
          if (reg) reg.update();
        })
        .catch(() => {});
    }
  });

  let updateIntervalId: number | undefined;

  setTimeout(async () => {
    try {
      const { registerSW } = await import("virtual:pwa-register");
      const updateSW = registerSW({
        immediate: true,
        onNeedRefresh() {
          logDebug("New version available, auto-updating...");
          updateSW(true);
          // Layer 2: iOS Safari fallback
          setTimeout(() => {
            if (!refreshing) {
              refreshing = true;
              logDebug("iOS fallback: controllerchange did not fire, forcing reload");
              window.location.reload();
            }
          }, CONTROLLER_CHANGE_TIMEOUT_MS);
        },
        onOfflineReady() {
          logDebug("App is ready for offline use");
        },
        onRegisteredSW(_swUrl, registration) {
          if (registration) {
            // Layer 4: Periodic polling
            if (updateIntervalId !== undefined) clearInterval(updateIntervalId);
            updateIntervalId = window.setInterval(
              () => registration.update(),
              SW_UPDATE_INTERVAL_MS,
            );
          }
        },
        onRegisterError(error) {
          logError("Service Worker registration failed", error);
        },
      });
      window.updateSW = updateSW;
    } catch (error: unknown) {
      logError("Failed to register PWA", error instanceof Error ? error : new Error(String(error)));
    }
  }, SW_INIT_DELAY_MS);

  window.addEventListener("pagehide", () => {
    if (updateIntervalId !== undefined) clearInterval(updateIntervalId);
  }, { once: true });
}
```

## Stale Chunk Recovery Template

```typescript
// stale-chunk-recovery.ts — Copy this to any Vite PWA project
const RELOAD_KEY = "stale-chunk-reloads";
const RELOAD_TS_KEY = "stale-chunk-reload-ts";
const MAX_RELOADS = 2;
const WINDOW_MS = 30_000;

const STALE_CHUNK_PATTERNS = [
  "MIME type",
  "Failed to fetch dynamically imported module",
  "Importing a module script failed",
  "error loading dynamically imported module",
  "Loading chunk",
  "ChunkLoadError",
] as const;

export function isStaleChunkError(message: string): boolean {
  const lower = message.toLowerCase();
  return STALE_CHUNK_PATTERNS.some((p) => lower.includes(p.toLowerCase()));
}

async function clearSwAndCaches(): Promise<void> {
  try {
    if ("serviceWorker" in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((r) => r.unregister()));
    }
    if ("caches" in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
    }
  } catch {
    // Cache clearing failed — still attempt reload
  }
}

export function handleStaleChunk(errorMessage: string): void {
  const now = Date.now();
  const lastTs = Number(sessionStorage.getItem(RELOAD_TS_KEY) || "0");
  const count = Number(sessionStorage.getItem(RELOAD_KEY) || "0");
  const reloadsInWindow = now - lastTs < WINDOW_MS ? count : 0;

  if (reloadsInWindow >= MAX_RELOADS) {
    sessionStorage.removeItem(RELOAD_KEY);
    sessionStorage.removeItem(RELOAD_TS_KEY);
    return; // Let ErrorBoundary handle it
  }

  sessionStorage.setItem(RELOAD_KEY, String(reloadsInWindow + 1));
  sessionStorage.setItem(RELOAD_TS_KEY, String(now));
  void clearSwAndCaches().finally(() => window.location.reload());
}
```

## Wire-Up in main.tsx / Entry Point

```typescript
import { handleStaleChunk, isStaleChunkError } from "./stale-chunk-recovery";
import { registerPWA } from "./pwa-registration";

// Register PWA at module level (not inside React)
registerPWA();

// Stale chunk error handlers
window.addEventListener("error", (event) => {
  if (event.message && isStaleChunkError(event.message)) handleStaleChunk(event.message);
});
window.addEventListener("unhandledrejection", (event) => {
  const message = event.reason?.message ?? String(event.reason);
  if (isStaleChunkError(message)) handleStaleChunk(message);
});
```

## Audit Checklist

| # | Check | Pass/Fail |
|---|-------|-----------|
| 1 | `controllerchange` listener exists with `isInitialRegistration` guard | |
| 2 | iOS fallback timeout (3s) after `updateSW(true)` | |
| 3 | `visibilitychange` triggers `registration.update()` | |
| 4 | Polling interval ≤ 60s with `registration.update()` | |
| 5 | Stale chunk recovery clears caches BEFORE reload | |
| 6 | Stale chunk max retries (2) prevents infinite loops | |
| 7 | Workbox: `skipWaiting: true` | |
| 8 | Workbox: `clientsClaim: true` | |
| 9 | Workbox: `cleanupOutdatedCaches: true` | |
| 10 | `sw.js` cache header: `max-age=0, must-revalidate` | |
| 11 | `index.html` cache header: `max-age=0, must-revalidate` | |
| 12 | `manifest.webmanifest` cache header: `max-age=0, must-revalidate` | |
| 13 | Hashed assets: `max-age=31536000, immutable` | |
| 14 | `pagehide` cleanup for polling interval | |
| 15 | `refreshing` flag prevents double-reload | |

---

<!-- PWA_AUTO_UPDATE_PATTERN v1.0.0 | Created: 2026-02-28 | Source: Cash Control (Z) SW staleness fix -->

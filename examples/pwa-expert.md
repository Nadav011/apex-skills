# pwa-expert — Real-World Examples

The skill enforces PWA standards: `vite-plugin-pwa` + Workbox caching strategies, 5-layer SW auto-update defense, complete manifest, and all 30 verification gates including Android rendering compatibility.

## Before / After

### Example 1: Service worker with no auto-update — users stuck on stale version

**Before** (triggers the skill):
```typescript
// ❌ SW registers but users never receive updates until manual hard-refresh
// src/main.tsx
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
  // No controllerchange listener
  // No visibilitychange polling
  // No iOS Safari fallback
  // Users stay on old cached version indefinitely after deploy
}

// vite.config.ts
VitePWA({
  registerType: 'autoUpdate',
  workbox: {
    // No skipWaiting → new SW waits in 'waiting' state forever
    // No clientsClaim → old SW continues serving tabs
  },
})
```

**After** (skill-compliant):
```typescript
// ✅ 5-layer auto-update defense — new version reaches all users on next visit
// src/pwa/swSetup.ts
export async function registerServiceWorker() {
  if (!('serviceWorker' in navigator)) return;
  const reg = await navigator.serviceWorker.register('/sw.js', { scope: '/' });
  let isInitialRegistration = true;

  // Layer 1: controllerchange → reload when new SW takes control
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (isInitialRegistration) { isInitialRegistration = false; return; }
    window.location.reload();
  });

  // Layer 2: iOS Safari fallback — WebKit Bug 199110
  reg.addEventListener('updatefound', () => {
    reg.installing?.addEventListener('statechange', function () {
      if (this.state === 'activated' && navigator.serviceWorker.controller) {
        setTimeout(() => window.location.reload(), 3000);
      }
    });
  });

  // Layer 3: update on tab return from background
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) reg.update();
  });

  // Layer 4: periodic check every 60s
  setInterval(() => reg.update(), 60_000);

  // Layer 5: stale chunk recovery after deploy
  window.addEventListener('error', async (e) => {
    if (e.message?.includes('Failed to fetch dynamically imported module')) {
      const keys = await caches.keys();
      await Promise.all(keys.map(k => caches.delete(k))); // clear ALL first
      window.location.reload();
    }
  });
}

// vite.config.ts
VitePWA({
  workbox: { skipWaiting: true, clientsClaim: true, cleanupOutdatedCaches: true },
})
```

**Why:** Without `controllerchange`, a deployed update installs but sits in the "waiting" state — users on all open tabs stay on the old version until they close all tabs and reopen. In iOS Safari, `controllerchange` sometimes never fires (WebKit Bug 199110), so the 3-second fallback timeout in Layer 2 is mandatory. Clearing all caches before reload in Layer 5 prevents the SW from re-serving the same stale chunks that caused the fetch error.

---

### Example 2: Wrong caching strategy for API routes

**Before** (triggers the skill):
```typescript
// ❌ CacheFirst for API data — users see stale content indefinitely
VitePWA({
  workbox: {
    runtimeCaching: [
      {
        urlPattern: /\/api\/.*/,
        handler: 'CacheFirst', // WRONG — API data never refreshes
        options: { cacheName: 'api-cache' },
      },
      // Auth routes cached — security risk: tokens stored in Cache Storage
      // No offline fallback — users see Chrome's dinosaur page when offline
    ],
  },
})
```

**After** (skill-compliant):
```typescript
// ✅ Correct strategies per resource type + offline fallback
VitePWA({
  workbox: {
    skipWaiting: true,
    clientsClaim: true,
    cleanupOutdatedCaches: true,
    additionalManifestEntries: [{ url: '/offline.html', revision: null }],
    navigateFallback: '/offline.html',
    // NEVER cache auth or API — serve from cache only as last resort
    navigateFallbackDenylist: [/\/api\//, /\/auth\//, /\/storage\//],
    runtimeCaching: [
      {
        urlPattern: /\/api\/.*/,
        handler: 'NetworkFirst',  // always try network, fall back to cache
        options: {
          cacheName: 'api-v1',
          networkTimeoutSeconds: 10,
          expiration: { maxEntries: 100, maxAgeSeconds: 300 }, // 5 min stale
          cacheableResponse: { statuses: [200] },
        },
      },
      {
        urlPattern: /\/auth\/.*/,
        handler: 'NetworkOnly', // auth calls are NEVER cached
      },
      {
        urlPattern: /\.(js|css)$/,
        handler: 'StaleWhileRevalidate', // instant from cache, refresh in bg
        options: { cacheName: 'static-v4',
                   expiration: { maxAgeSeconds: 604800 } },
      },
      {
        urlPattern: /\.(png|jpg|webp|svg)$/,
        handler: 'CacheFirst', // images are content-addressed, safe to cache long
        options: { cacheName: 'images-v2',
                   expiration: { maxEntries: 200, maxAgeSeconds: 604800 } },
      },
    ],
  },
})
```

**Why:** `CacheFirst` for API routes means the SW serves the same JSON response forever, regardless of updates on the server. Users see stale order statuses, old prices, and outdated inventory. `NetworkFirst` with a 10-second timeout gives fresh data when online and gracefully degrades to cached data when offline. Auth routes must be `NetworkOnly` — caching JWTs or session cookies in Cache Storage makes them inspectable via browser DevTools.

---

### Example 3: Incomplete manifest failing installability check

**Before** (triggers the skill):
```json
{
  "name": "My App",
  "icons": [
    { "src": "/icon.png", "sizes": "192x192" }
  ]
}
// Chrome installability check: FAILS
// Missing: short_name, start_url, display, background_color, theme_color
// Missing: 512x512 icon (Chrome requires both 192 AND 512)
// Missing: maskable icon (Android adaptive icons)
// Lighthouse PWA score: 55
```

**After** (skill-compliant):
```json
{
  "name": "חנות אונליין",
  "short_name": "חנות",
  "description": "קניות מהירות ונוחות",
  "start_url": "/?source=pwa",
  "id": "/",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#ffffff",
  "theme_color": "#3b82f6",
  "lang": "he",
  "dir": "rtl",
  "icons": [
    { "src": "/pwa-192x192.png", "sizes": "192x192",
      "type": "image/png", "purpose": "any" },
    { "src": "/pwa-512x512.png", "sizes": "512x512",
      "type": "image/png", "purpose": "any" },
    { "src": "/pwa-maskable-512x512.png", "sizes": "512x512",
      "type": "image/png", "purpose": "maskable" },
    { "src": "/apple-touch-icon.png", "sizes": "180x180", "type": "image/png" }
  ],
  "screenshots": [
    { "src": "/screenshot-mobile.png", "sizes": "390x844",
      "type": "image/png", "form_factor": "narrow" }
  ]
}
```

**Why:** Chrome's installability check requires `short_name`, `start_url`, `display: standalone`, both 192 × 192 and 512 × 512 icons, and `background_color`. The `purpose: maskable` variant is mandatory for Android's adaptive icon system — without it Android crops the regular icon into a circle, cutting logo corners. `lang: "he"` and `dir: "rtl"` are required for correct RTL rendering in the system app switcher and splash screen.

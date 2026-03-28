# PWA Master Checklist | APEX v24.5.0 SINGULARITY FORGE

> Comprehensive checklist referencing ALL PWA skill files for audits and fixes

---

## 1. PURPOSE

Central hub for PWA development, auditing, and troubleshooting. This checklist consolidates 150+ items across 9 categories, referencing all specialized PWA skill files for quick fixes and implementation guidance. Aligned with CLAUDE.md v24.5.0 SINGULARITY FORGE performance targets and 70-Gate Matrix.

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/pwa audit` | Run full Lighthouse PWA audit | ~1min |
| `/pwa check [category]` | Check specific category (1-9) | ~30s |
| `/pwa fix [issue]` | Get quick fix for specific issue | ~10s |
| `/pwa verify` | Run verification checklist | ~2min |
| `/pwa test` | Run automated PWA tests | ~3min |

---

## 3. GATE MATRIX

| Gate | Category | Items | Threshold |
|------|----------|-------|-----------|
| G-PWA-1 | Performance | 15 | LCP < 1.0s, Bundle < 100KB |
| G-PWA-2 | Service Worker | 18 | SW registered, offline works |
| G-PWA-3 | Old Android CSS | 25 | All fallbacks implemented |
| G-PWA-4 | iOS Compatibility | 12 | Safari issues resolved |
| G-PWA-5 | Push Notifications | 10 | VAPID + SW handlers |
| G-PWA-6 | Install Experience | 10 | Prompt + manifest valid |
| G-PWA-7 | Memory Management | 10 | No leaks, cleanup done |
| G-PWA-8 | Security | 8 | HTTPS + headers + CSP |
| G-PWA-9 | Testing | 12 | Lighthouse > 90, E2E pass |
| **G-PWA-17** | **Network Reliability** | **3** | **Real connectivity check, not navigator.onLine** |
| **G-PWA-18** | **SW Update Safety** | **2** | **No double reloads, isReloading guard** |
| **G-PWA-19** | **Dark Mode Flash** | **1** | **class="dark" in HTML tag** |
| **G-PWA-20** | **Persistent Storage** | **2** | **Request persistence to prevent IndexedDB eviction** |
| **G-PWA-21** | **In-App Browser** | **3** | **Detect WebView, show escape UI** |
| **G-PWA-22** | **iOS SW Health** | **3** | **Ping/pong SW health check, auto-recover** |

---

## 4. QUICK REFERENCE: SKILL FILES

| Skill File | Focus Area |
|------------|------------|
| `pwa-lighthouse-fixes.md` | Lighthouse audit fixes, old Android optimization |
| `pwa-checklist.md` | Core PWA setup, Serwist, manifest |
| `pwa-performance.md` | First load, splash screens, caching |
| `pwa-android-optimization.md` | Android-specific optimizations |
| `pwa-ios-limitations.md` | iOS Safari workarounds |
| `pwa-push-troubleshooting.md` | Push notification debugging |
| `old-android-css-compat.md` | CSS fallbacks for Android 8-10 |
| `service-worker-patterns.md` | SW lifecycle, caching strategies |
| `offline-first-patterns.md` | Offline data sync patterns |
| `pwa-edge-cases.md` | **Critical PWA edge cases (PWA-17 to PWA-22)** |

---

## 5. VERIFICATION COMMANDS

```bash
# Full PWA audit
npx lighthouse https://your-app.com --only-categories=pwa,performance --output=html

# Bundle analysis
ANALYZE=true pnpm run build

# Service worker testing
npx workbox-cli wizard

# Type check + lint + test
pnpm run lint && ppnpm run test:run && pnpm run build
```

---

## 5.1 CRITICAL EDGE CASES (PWA-17 to PWA-22)

> **Reference:** `pwa-edge-cases.md` for full patterns and test examples

### PWA-17: navigator.onLine Unreliability (CRITICAL)

- [ ] Real connectivity check implemented | Quick fix:
```typescript
// NEVER trust navigator.onLine alone!
export async function checkRealConnectivity(): Promise<boolean> {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    const response = await fetch(`/logo.svg?_=${Date.now()}`, {
      method: "HEAD", cache: "no-store", signal: controller.signal,
    });
    clearTimeout(timeoutId);
    return response.ok;
  } catch { return false; }
}
```

### PWA-18: SW Double Reload Prevention (CRITICAL)

- [ ] isReloading guard implemented | Quick fix:
```typescript
let isReloading = false;
const safeReload = (reason: string) => {
  if (isReloading) return;
  isReloading = true;
  window.location.reload();
};
// Use safeReload() for BOTH SW_UPDATED and controllerchange
```

### PWA-19: Dark Mode Flash Prevention (MEDIUM)

- [ ] class="dark" on HTML tag | Quick fix:
```html
<!-- index.html - BEFORE any CSS -->
<html lang="he" dir="rtl" class="dark">
  <head>
    <script>
      (function() {
        const savedTheme = localStorage.getItem('theme');
        if (savedTheme === 'light') {
          document.documentElement.classList.remove('dark');
        }
      })();
    </script>
  </head>
```

### PWA-20: Persistent Storage Request (MEDIUM)

- [ ] Request persistent storage on app startup | Quick fix:
```typescript
// lib/pwa/persistentStorage.ts
export async function requestPersistentStorage(): Promise<boolean> {
  if (!navigator.storage?.persist) return false;
  const isPersisted = await navigator.storage.persisted();
  if (isPersisted) return true;
  return await navigator.storage.persist();
}
// Call after user engagement (login, install, first sync)
```

### PWA-21: In-App Browser Detection (CRITICAL)

- [ ] Detect WebView and show escape UI | Quick fix:
```typescript
// Detect Facebook/Instagram/TikTok WebViews
const IN_APP_PATTERNS = [/FBAN|FBAV/i, /Instagram/i, /TikTok|BytedanceWebview/i];
const isInAppBrowser = IN_APP_PATTERNS.some(p => p.test(navigator.userAgent));
// iOS: Show "Copy URL" button
// Android: Use intent:// URL to open in Chrome
```

### PWA-22: iOS Service Worker Health Check (CRITICAL)

- [ ] Implement SW ping/pong health check | Quick fix:
```typescript
// SW side: Respond to ping
self.addEventListener('message', (event) => {
  if (event.data?.type === 'SW_PING' && event.ports[0]) {
    event.ports[0].postMessage({ type: 'SW_PONG', timestamp: Date.now() });
  }
});

// App side: Check hourly + on visibility change
const channel = new MessageChannel();
channel.port1.onmessage = (e) => console.log(e.data?.type === 'SW_PONG' ? 'Healthy' : 'Dead');
registration.active.postMessage({ type: 'SW_PING' }, [channel.port2]);
```

---

## 6. PERFORMANCE (15 items)

### 6.1 Core Web Vitals

- [ ] LCP < 1.0s (critical < 1.5s) | Skill: `pwa-performance.md` | Quick fix:
```tsx
// Preload critical fonts
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin />
```

- [ ] FCP < 1.2s (critical < 1.8s) | Skill: `pwa-performance.md` | Quick fix:
```tsx
// Return minimal HTML quickly with Suspense
<Suspense fallback={<Skeleton />}>{children}</Suspense>
```

- [ ] CLS = 0 (critical < 0.1) | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
// Always specify dimensions for images
<img src="..." width={300} height={200} alt="..." />
```

- [ ] INP < 100ms (critical < 200ms) | Skill: `pwa-performance.md` | Quick fix:
```tsx
// Use startTransition for non-urgent updates
import { startTransition } from 'react';
startTransition(() => setData(newData));
```

- [ ] TTI < 2.0s (critical < 3.0s) | Skill: `pwa-performance.md` | Quick fix:
```tsx
// Defer non-critical scripts
<Script src="analytics.js" strategy="lazyOnload" />
```

### 6.2 Bundle Optimization

- [ ] Initial JS bundle < 100KB (critical < 120KB) | Skill: `pwa-performance.md` | Quick fix:
```tsx
// Dynamic imports for large components
const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <Skeleton className="h-64" />,
  ssr: false,
});
```

- [ ] Per-route chunk < 50KB | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```bash
# Analyze bundle
ANALYZE=true pnpm run build
```

- [ ] Total CSS < 30KB | Skill: `pwa-performance.md` | Quick fix:
```tsx
// Tailwind v4 uses CSS-first config — automatic content detection
// No content config needed. Use @import "tailwindcss" in globals.css
// Legacy v3: content: ['./src/**/*.{js,ts,jsx,tsx}'] in tailwind.config.ts
```

- [ ] Tree-shakeable imports only | Skill: `pwa-performance.md` | Quick fix:
```tsx
// GOOD - tree-shakeable
import { format } from 'date-fns';

// BAD - imports entire library
import * as dateFns from 'date-fns';
```

- [ ] Images optimized (WebP/AVIF) | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
<picture>
  <source srcSet="/image.avif" type="image/avif" />
  <source srcSet="/image.webp" type="image/webp" />
  <img src="/image.jpg" alt="..." loading="lazy" />
</picture>
```

### 6.3 Loading Optimization

- [ ] Critical CSS inlined | Skill: `pwa-performance.md` | Quick fix:
```tsx
// next.config.ts
experimental: { optimizeCss: true }
```

- [ ] Font display: swap configured | Skill: `pwa-performance.md` | Quick fix:
```tsx
const assistant = Assistant({
  subsets: ['hebrew', 'latin'],
  display: 'swap', // CRITICAL - prevents FOIT
  preload: true,
});
```

- [ ] Navigation preload enabled | Skill: `pwa-performance.md` | Quick fix:
```tsx
// src/sw.ts
const serwist = new Serwist({
  navigationPreload: true, // CRITICAL - speeds up navigation
});
```

- [ ] Above-the-fold content prioritized | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
// Priority for hero images
<Image src="hero.jpg" priority alt="Hero" />
```

- [ ] Skeleton loading implemented | Skill: `pwa-performance.md` | Quick fix:
```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return <div className="h-32 bg-gray-200 rounded-lg animate-pulse" />;
}
```

---

## 7. SERVICE WORKER (18 items)

### 7.1 Core Setup

- [ ] Using Serwist (NOT next-pwa) | Skill: `pwa-checklist.md` | Quick fix:
```bash
npm uninstall next-pwa
npm i @serwist/next && npm i -D serwist
```

- [ ] Service worker registered | Skill: `pwa-checklist.md` | Quick fix:
```tsx
// next.config.ts
import withSerwistInit from "@serwist/next";
const withSerwist = withSerwistInit({
  swSrc: "src/sw.ts",
  swDest: "public/sw.js",
});
```

- [ ] SW TypeScript config updated | Skill: `pwa-checklist.md` | Quick fix:
```json
// tsconfig.json
{
  "compilerOptions": { "lib": ["WebWorker"] },
  "include": ["src/sw.ts"]
}
```

- [ ] skipWaiting enabled | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
const serwist = new Serwist({
  skipWaiting: true,
  clientsClaim: true,
});
```

- [ ] SW fallbacks configured | Skill: `pwa-checklist.md` | Quick fix:
```tsx
fallbacks: {
  entries: [
    {
      url: '/offline',
      matcher({ request }) {
        return request.destination === 'document';
      },
    },
  ],
}
```

### 7.2 Caching Strategies

- [ ] Static assets: CacheFirst | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
{
  urlPattern: /\.(?:js|css|woff2)$/,
  handler: new CacheFirst({ cacheName: 'static-assets' }),
}
```

- [ ] Images: CacheFirst with expiration | Skill: `pwa-performance.md` | Quick fix:
```tsx
{
  urlPattern: /\.(?:png|jpg|jpeg|webp|avif)$/,
  handler: new CacheFirst({
    cacheName: 'images',
    plugins: [new ExpirationPlugin({ maxEntries: 50 })],
  }),
}
```

- [ ] API calls: NetworkFirst with timeout | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
{
  urlPattern: /\/api\//,
  handler: new NetworkFirst({
    cacheName: 'api-cache',
    networkTimeoutSeconds: 3,
  }),
}
```

- [ ] HTML pages: StaleWhileRevalidate | Skill: `pwa-performance.md` | Quick fix:
```tsx
{
  urlPattern: ({ request }) => request.destination === 'document',
  handler: new StaleWhileRevalidate({ cacheName: 'pages' }),
}
```

- [ ] Precache entries configured | Skill: `pwa-performance.md` | Quick fix:
```tsx
precacheEntries: [
  ...self.__SW_MANIFEST,
  { url: '/offline', revision: '1' },
  { url: '/shell', revision: '1' },
]
```

### 7.3 Update Handling

- [ ] SW update detection | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
navigator.serviceWorker.addEventListener('controllerchange', () => {
  window.location.reload();
});
```

- [ ] Update prompt UI | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
const [showUpdate, setShowUpdate] = useState(false);
// Show banner when new SW waiting
registration.waiting && setShowUpdate(true);
```

- [ ] Force update mechanism | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
registration.waiting?.postMessage({ type: 'SKIP_WAITING' });
```

- [ ] Cache versioning | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
const CACHE_VERSION = 'v2';
const cacheName = `app-${CACHE_VERSION}`;
```

- [ ] Old cache cleanup | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter(k => k !== currentCache).map(k => caches.delete(k)))
    )
  );
});
```

### 7.4 Offline Support

- [ ] Offline page exists | Skill: `pwa-checklist.md` | Quick fix:
```tsx
// app/offline/page.tsx
export default function OfflinePage() {
  return <div className="text-center">You are offline</div>;
}
```

- [ ] **CRITICAL: Real connectivity check (NOT just navigator.onLine)** | Skill: `pwa-edge-cases.md` (PWA-17) | Quick fix:
```tsx
// navigator.onLine is UNRELIABLE! Always verify with actual fetch
async function checkRealConnectivity(): Promise<boolean> {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    const response = await fetch(`/logo.svg?_=${Date.now()}`, {
      method: "HEAD", cache: "no-store", mode: "same-origin",
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    return response.ok;
  } catch { return false; }
}
```

- [ ] Offline page verifies real connectivity before showing | Skill: `pwa-edge-cases.md` (PWA-17) | Quick fix:
```html
<!-- public/offline.html - Check real connectivity, not just navigator.onLine -->
<script>
  async function checkRealConnectivity() {
    try { const r = await fetch('/logo.svg?_='+Date.now(), {method:'HEAD',cache:'no-store'}); return r.ok; } catch { return false; }
  }
  checkRealConnectivity().then(online => { if (online) window.location.reload(); });
  setInterval(async () => { if (await checkRealConnectivity()) window.location.reload(); }, 10000);
</script>
```

- [ ] Offline queue for mutations | Skill: `offline-first-patterns.md` | Quick fix:
```tsx
// Queue failed requests for retry
const offlineQueue = new Queue('offline-requests');
```

### 7.5 SW Update Edge Cases (CRITICAL)

- [ ] **Double reload prevention (PWA-18)** | Skill: `pwa-edge-cases.md` | Quick fix:
```tsx
// BOTH SW_UPDATED message AND controllerchange can fire - prevent double reload!
let isReloading = false;
const safeReload = (reason: string) => {
  if (isReloading) return;
  isReloading = true;
  window.location.reload();
};
navigator.serviceWorker.addEventListener("message", (e) => {
  if (e.data?.type === "SW_UPDATED") safeReload("SW_UPDATED");
});
navigator.serviceWorker.addEventListener("controllerchange", () => {
  safeReload("controllerchange");
});
```

- [ ] **Dark mode flash prevention (PWA-19)** | Skill: `pwa-edge-cases.md` | Quick fix:
```html
<!-- Add class="dark" to HTML tag to prevent light mode flash -->
<html lang="he" dir="rtl" class="dark">
```

---

## 8. OLD ANDROID CSS COMPATIBILITY (25 items)

### 8.1 Flexbox Fallbacks

- [ ] gap fallback with margins | Skill: `old-android-css-compat.md` | Quick fix:
```css
/* Modern */
.flex-container { display: flex; gap: 1rem; }
/* Fallback */
.flex-container > * + * { margin-inline-start: 1rem; }
```

- [ ] flex-wrap support check | Skill: `old-android-css-compat.md` | Quick fix:
```css
.container {
  display: flex;
  flex-wrap: wrap;
  /* Fallback for old WebKit */
  display: -webkit-box;
  -webkit-box-orient: horizontal;
}
```

- [ ] flex-basis fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.item {
  flex: 1 1 auto;
  /* Explicit width fallback */
  width: 100%;
  min-width: 0;
}
```

- [ ] align-items: stretch default | Skill: `old-android-css-compat.md` | Quick fix:
```css
.container {
  display: flex;
  align-items: stretch; /* Explicit for old browsers */
}
```

- [ ] flex-shrink: 0 for icons | Skill: `old-android-css-compat.md` | Quick fix:
```css
.icon { flex-shrink: 0; width: 24px; height: 24px; }
```

### 8.2 Grid Fallbacks

- [ ] CSS Grid with flexbox fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.grid {
  display: flex;
  flex-wrap: wrap;
}
@supports (display: grid) {
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }
}
```

- [ ] grid-gap to gap migration | Skill: `old-android-css-compat.md` | Quick fix:
```css
.grid {
  grid-gap: 1rem; /* Old syntax */
  gap: 1rem; /* New syntax */
}
```

- [ ] minmax() fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
/* Fallback width for old browsers */
.item { width: 300px; max-width: 100%; }
```

- [ ] auto-fit/auto-fill fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.grid { grid-template-columns: repeat(3, 1fr); } /* Fixed fallback */
@media (max-width: 768px) { .grid { grid-template-columns: 1fr; } }
```

### 8.3 Modern CSS Features

- [ ] aspect-ratio fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.video-container {
  position: relative;
  padding-bottom: 56.25%; /* 16:9 fallback */
  height: 0;
}
@supports (aspect-ratio: 16/9) {
  .video-container { aspect-ratio: 16/9; padding-bottom: 0; height: auto; }
}
```

- [ ] clamp() fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.text {
  font-size: 1rem; /* Fallback */
  font-size: clamp(1rem, 2vw, 1.5rem);
}
```

- [ ] min()/max() fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.container {
  width: 100%; /* Fallback */
  max-width: 1200px;
  width: min(100%, 1200px);
}
```

- [ ] :is()/:where() fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
/* Fallback: list all selectors */
.card h1, .card h2, .card h3 { color: blue; }
/* Modern */
.card :is(h1, h2, h3) { color: blue; }
```

- [ ] :has() fallback | Skill: `old-android-css-compat.md` | Quick fix:
```tsx
// Use JavaScript for :has() fallback
const hasError = container.querySelector('.error');
if (hasError) container.classList.add('has-error');
```

- [ ] container queries fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
/* Fallback to media queries */
@media (min-width: 600px) { .card { flex-direction: row; } }
/* Modern */
@container (min-width: 600px) { .card { flex-direction: row; } }
```

### 8.4 Logical Properties

- [ ] margin-inline-start/end fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.element {
  margin-left: 1rem; /* LTR fallback */
  margin-inline-start: 1rem;
}
[dir="rtl"] .element { margin-left: 0; margin-right: 1rem; }
```

- [ ] padding-inline-start/end fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.element { padding-left: 1rem; padding-inline-start: 1rem; }
```

- [ ] inset-inline-start/end fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.positioned { left: 0; inset-inline-start: 0; }
```

- [ ] border-inline-start/end fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.element { border-left: 1px solid; border-inline-start: 1px solid; }
```

- [ ] text-align: start/end fallback | Skill: `old-android-css-compat.md` | Quick fix:
```css
.text { text-align: left; text-align: start; }
```

### 8.5 Device Detection

- [ ] Old Android detection utility | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
export function isOldAndroid(): boolean {
  if (typeof navigator === 'undefined') return false;
  const ua = navigator.userAgent;
  const match = ua.match(/Android\s+(\d+)/i);
  return match ? parseInt(match[1], 10) <= 10 : false;
}
```

- [ ] CSS feature detection | Skill: `old-android-css-compat.md` | Quick fix:
```tsx
const supportsGap = CSS.supports('gap', '1rem');
const supportsGrid = CSS.supports('display', 'grid');
```

- [ ] Polyfill loading strategy | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
if (!CSS.supports('gap', '1rem')) {
  import('./polyfills/gap-polyfill');
}
```

- [ ] Performance-aware rendering | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
const isLowEnd = navigator.hardwareConcurrency <= 2 ||
  navigator.deviceMemory <= 2 ||
  navigator.connection?.effectiveType === '2g';
```

- [ ] Reduced motion respect | Skill: `old-android-css-compat.md` | Quick fix:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; }
}
```

---

## 9. iOS COMPATIBILITY (12 items)

### 9.1 Safari-Specific Issues

- [ ] 100vh fix for iOS Safari | Skill: `pwa-ios-limitations.md` | Quick fix:
```css
.full-height {
  height: 100vh;
  height: 100dvh; /* Dynamic viewport height */
  height: -webkit-fill-available;
}
```

- [ ] Safe area insets | Skill: `pwa-ios-limitations.md` | Quick fix:
```css
.bottom-nav {
  padding-bottom: env(safe-area-inset-bottom);
  padding-bottom: constant(safe-area-inset-bottom); /* iOS 11.0-11.2 */
}
```

- [ ] viewport-fit: cover | Skill: `pwa-ios-limitations.md` | Quick fix:
```tsx
export const viewport: Viewport = {
  viewportFit: 'cover', // Critical for safe areas
};
```

- [ ] Rubber-band scrolling handling | Skill: `pwa-ios-limitations.md` | Quick fix:
```css
body { overscroll-behavior: none; }
```

- [ ] iOS form zoom prevention | Skill: `pwa-ios-limitations.md` | Quick fix:
```css
input, select, textarea { font-size: 16px; } /* Prevents zoom on focus */
```

### 9.2 PWA-Specific iOS Issues

- [ ] apple-mobile-web-app-capable | Skill: `pwa-checklist.md` | Quick fix:
```tsx
export const metadata: Metadata = {
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'MyPWA',
  },
};
```

- [ ] Apple touch icon | Skill: `pwa-checklist.md` | Quick fix:
```tsx
<link rel="apple-touch-icon" href="/icons/apple-touch-icon.png" />
```

- [ ] iOS splash screens (all sizes) | Skill: `pwa-performance.md` | Quick fix:
```tsx
<link
  rel="apple-touch-startup-image"
  href="/splash/apple-splash-1179-2556.png"
  media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3)"
/>
```

- [ ] Generate all iOS splash sizes | Skill: `pwa-performance.md` | Quick fix:
```bash
npx pwa-asset-generator logo.svg ./public/splash \
  --background "#ffffff" --splash-only --type png
```

- [ ] iOS navigation gesture handling | Skill: `pwa-ios-limitations.md` | Quick fix:
```tsx
// Prevent back swipe interfering with app gestures
document.addEventListener('touchstart', handleTouchStart, { passive: true });
```

### 9.3 iOS Audio/Media

- [ ] Audio autoplay workaround | Skill: `pwa-ios-limitations.md` | Quick fix:
```tsx
// Must be triggered by user interaction
button.addEventListener('click', () => {
  audio.play();
});
```

- [ ] iOS media session API | Skill: `pwa-ios-limitations.md` | Quick fix:
```tsx
if ('mediaSession' in navigator) {
  navigator.mediaSession.metadata = new MediaMetadata({ title: 'Song', artist: 'Artist' });
}
```

---

## 10. PUSH NOTIFICATIONS (10 items)

### 10.1 Setup

- [ ] VAPID keys generated | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```bash
npx web-push generate-vapid-keys
```

- [ ] Push permission request | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
async function requestPushPermission() {
  const permission = await Notification.requestPermission();
  if (permission === 'granted') {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
    });
    return subscription;
  }
}
```

- [ ] Push subscription saved to backend | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
await fetch('/api/push/subscribe', {
  method: 'POST',
  body: JSON.stringify(subscription),
  headers: { 'Content-Type': 'application/json' },
});
```

- [ ] SW push event handler | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icons/icon-192.png',
      badge: '/icons/badge-72.png',
    })
  );
});
```

### 10.2 Troubleshooting

- [ ] Notification click handler | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.openWindow(event.notification.data?.url || '/')
  );
});
```

- [ ] Push subscription refresh | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
// Refresh subscription on each app load
registration.pushManager.getSubscription().then((sub) => {
  if (sub) { syncSubscriptionWithServer(sub); }
});
```

- [ ] Expired subscription handling | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
subscription.addEventListener('expirationTime', () => {
  resubscribe();
});
```

- [ ] Background sync for failed pushes | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
self.addEventListener('sync', (event) => {
  if (event.tag === 'retry-push') {
    event.waitUntil(retryFailedPushes());
  }
});
```

- [ ] iOS push workaround (no support) | Skill: `pwa-ios-limitations.md` | Quick fix:
```tsx
// iOS 16.4+ supports push in PWA mode
const isiOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
const isPWA = window.matchMedia('(display-mode: standalone)').matches;
if (isiOS && isPWA) { /* Push available */ }
```

- [ ] Push analytics tracking | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```tsx
// Track in notificationclick
analytics.track('push_opened', { campaign: event.notification.data?.campaign });
```

---

## 11. INSTALL EXPERIENCE (10 items)

### 11.1 Install Prompt

- [ ] beforeinstallprompt capture | Skill: `pwa-checklist.md` | Quick fix:
```tsx
let deferredPrompt: BeforeInstallPromptEvent | null = null;
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
});
```

- [ ] Custom install button | Skill: `pwa-checklist.md` | Quick fix:
```tsx
async function handleInstall() {
  if (!deferredPrompt) return;
  deferredPrompt.prompt();
  const { outcome } = await deferredPrompt.userChoice;
  if (outcome === 'accepted') { trackInstall(); }
  deferredPrompt = null;
}
```

- [ ] Install state detection | Skill: `pwa-checklist.md` | Quick fix:
```tsx
const isInstalled = window.matchMedia('(display-mode: standalone)').matches ||
  window.navigator.standalone === true;
```

- [ ] appinstalled event tracking | Skill: `pwa-checklist.md` | Quick fix:
```tsx
window.addEventListener('appinstalled', () => {
  analytics.track('pwa_installed');
  hideInstallButton();
});
```

### 11.2 Manifest Configuration

- [ ] Manifest icons (192 + 512) | Skill: `pwa-checklist.md` | Quick fix:
```tsx
icons: [
  { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
  { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
]
```

- [ ] Maskable icon (separate) | Skill: `pwa-checklist.md` | Quick fix:
```tsx
{ src: '/icons/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' }
```

- [ ] Screenshots for install UI | Skill: `pwa-checklist.md` | Quick fix:
```tsx
screenshots: [
  { src: '/screenshots/mobile.png', sizes: '750x1334', type: 'image/png', form_factor: 'narrow' },
  { src: '/screenshots/desktop.png', sizes: '1280x720', type: 'image/png', form_factor: 'wide' },
]
```

- [ ] App shortcuts configured | Skill: `pwa-checklist.md` | Quick fix:
```tsx
shortcuts: [
  { name: 'New Item', short_name: 'New', url: '/new', icons: [{ src: '/icons/shortcut-new.png', sizes: '96x96' }] },
]
```

- [ ] Share target configured | Skill: `pwa-checklist.md` | Quick fix:
```tsx
share_target: {
  action: '/share',
  method: 'POST',
  enctype: 'multipart/form-data',
  params: { title: 'title', text: 'text', url: 'url' },
}
```

- [ ] RTL manifest configuration | Skill: `pwa-checklist.md` | Quick fix:
```tsx
dir: 'rtl',
lang: 'he',
```

---

## 12. MEMORY MANAGEMENT (10 items)

### 12.1 React Optimization

- [ ] Cleanup useEffect subscriptions | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
useEffect(() => {
  const subscription = observable.subscribe();
  return () => subscription.unsubscribe();
}, []);
```

- [ ] Abort fetch on unmount | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
useEffect(() => {
  const controller = new AbortController();
  fetch(url, { signal: controller.signal });
  return () => controller.abort();
}, [url]);
```

- [ ] Event listener cleanup | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
useEffect(() => {
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, []);
```

- [ ] Timer cleanup | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
useEffect(() => {
  const timer = setInterval(tick, 1000);
  return () => clearInterval(timer);
}, []);
```

### 12.2 Cache Management

- [ ] IndexedDB cleanup on logout | Skill: `offline-first-patterns.md` | Quick fix:
```tsx
async function clearUserData() {
  await indexedDB.deleteDatabase('user-data');
}
```

- [ ] Cache size limits | Skill: `pwa-performance.md` | Quick fix:
```tsx
new ExpirationPlugin({
  maxEntries: 50,
  maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
})
```

- [ ] Blob URL revocation | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
useEffect(() => {
  const url = URL.createObjectURL(blob);
  return () => URL.revokeObjectURL(url);
}, [blob]);
```

### 12.3 Performance Monitoring

- [ ] Memory pressure detection | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
if ('memory' in performance) {
  const { usedJSHeapSize, jsHeapSizeLimit } = (performance as any).memory;
  if (usedJSHeapSize / jsHeapSizeLimit > 0.9) { clearCaches(); }
}
```

- [ ] Large list virtualization | Skill: `pwa-performance.md` | Quick fix:
```tsx
import { useVirtualizer } from '@tanstack/react-virtual';
const virtualizer = useVirtualizer({ count: items.length, getScrollElement: () => parentRef.current, estimateSize: () => 50 });
```

- [ ] Image lazy loading | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
<img src="image.jpg" loading="lazy" alt="..." />
```

---

## 13. SECURITY (8 items)

### 13.1 HTTPS & Headers

- [ ] HTTPS enforced | Skill: `pwa-checklist.md` | Quick fix:
```tsx
// Vercel automatically enforces HTTPS
// For other hosts, add redirect
if (location.protocol !== 'https:') {
  location.replace(`https:${location.href.substring(location.protocol.length)}`);
}
```

- [ ] Strict-Transport-Security header | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
// next.config.ts headers
{ key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains' }
```

- [ ] Content-Security-Policy | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
{ key: 'Content-Security-Policy', value: "default-src 'self'; script-src 'self' 'unsafe-inline'" }
```

- [ ] X-Content-Type-Options | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
{ key: 'X-Content-Type-Options', value: 'nosniff' }
```

### 13.2 Service Worker Security

- [ ] SW scope limited | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
navigator.serviceWorker.register('/sw.js', { scope: '/' });
```

- [ ] No sensitive data in SW cache | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
// Never cache auth tokens or sensitive data
if (request.url.includes('/api/auth')) {
  return fetch(request); // Always network
}
```

- [ ] SW update integrity | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
// Use byte-for-byte comparison for SW updates
// Serwist handles this automatically
```

- [ ] CSP for SW | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
// Allow service worker in CSP
{ key: 'Content-Security-Policy', value: "worker-src 'self'" }
```

---

## 14. TESTING (12 items)

### 14.1 Lighthouse Audits

- [ ] PWA audit score > 90 | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```bash
npx lighthouse https://your-app.com --only-categories=pwa
```

- [ ] Performance audit score > 90 | Skill: `pwa-performance.md` | Quick fix:
```bash
npx lighthouse https://your-app.com --only-categories=performance
```

- [ ] Accessibility audit score > 90 | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```bash
npx lighthouse https://your-app.com --only-categories=accessibility
```

### 14.2 Manual Testing

- [ ] Offline mode tested | Skill: `pwa-checklist.md` | Quick fix:
```markdown
1. Open DevTools > Network
2. Set to Offline
3. Reload page
4. Verify offline page shows
```

- [ ] Install flow tested (Chrome Android) | Skill: `pwa-checklist.md` | Quick fix:
```markdown
1. Open in Chrome on Android
2. Wait for install banner or use menu
3. Add to Home Screen
4. Open from home screen
5. Verify standalone mode
```

- [ ] Install flow tested (iOS Safari) | Skill: `pwa-ios-limitations.md` | Quick fix:
```markdown
1. Open in Safari on iOS
2. Tap Share button
3. Tap "Add to Home Screen"
4. Open from home screen
5. Verify fullscreen mode
```

- [ ] Push notifications tested | Skill: `pwa-push-troubleshooting.md` | Quick fix:
```markdown
1. Grant notification permission
2. Subscribe to push
3. Send test push from server
4. Verify notification appears
5. Click notification, verify action
```

### 14.3 Automated Testing

- [ ] SW registration test | Skill: `service-worker-patterns.md` | Quick fix:
```tsx
test('service worker registers', async () => {
  const registration = await navigator.serviceWorker.register('/sw.js');
  expect(registration).toBeDefined();
});
```

- [ ] Offline functionality test | Skill: `offline-first-patterns.md` | Quick fix:
```tsx
test('app works offline', async () => {
  await page.setOffline(true);
  await page.reload();
  expect(await page.locator('h1').textContent()).toBe('Offline Mode');
});
```

- [ ] Install prompt test | Skill: `pwa-checklist.md` | Quick fix:
```tsx
test('install prompt fires', async () => {
  const promptEvent = await page.evaluate(() => {
    return new Promise((resolve) => {
      window.addEventListener('beforeinstallprompt', resolve, { once: true });
    });
  });
  expect(promptEvent).toBeDefined();
});
```

- [ ] Old Android emulation test | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
// Test with Android 9 emulation
await page.emulate({
  userAgent: 'Mozilla/5.0 (Linux; Android 9; ...) AppleWebKit/537.36 Chrome/80.0.3987.149 Mobile Safari/537.36',
});
```

- [ ] Network throttling test | Skill: `pwa-lighthouse-fixes.md` | Quick fix:
```tsx
// Test with slow 3G
await page.emulateNetworkConditions({
  offline: false,
  downloadThroughput: 500 * 1024 / 8,
  uploadThroughput: 500 * 1024 / 8,
  latency: 400,
});
```

---

## 15. QUICK VERIFICATION CHECKLIST

```bash
# 1. Run full Lighthouse audit
npx lighthouse https://your-app.com --only-categories=pwa,performance,accessibility --output=html --output-path=./lighthouse.html

# 2. Verify bundle size
pnpm run build && du -sh .next/static

# 3. Test offline mode
# DevTools > Network > Offline > Reload

# 4. Test on real devices
# - Android Chrome
# - iOS Safari
# - Old Android (8-10)

# 5. Verify all caches work
# DevTools > Application > Cache Storage

# 6. Test push notifications
# Subscribe > Send test > Verify delivery

# 7. Run automated tests
ppnpm run test:run && pnpm run test:e2e
```

---

## 16. SEVERITY LEVELS

| Level | Meaning | Action |
|-------|---------|--------|
| CRITICAL | Blocks install/offline | Fix immediately |
| HIGH | Major UX issue | Fix before release |
| MEDIUM | Minor issue | Fix soon |
| LOW | Enhancement | Nice to have |

---

## 17. RELATED DOCUMENTS

- **[pwa-device-parity-checklist.md](./pwa-device-parity-checklist.md) - 🔥 iPhone ↔ Old Android Parity (CRITICAL)**
- [pwa-checklist.md](../../_archive/batch-2026-02-19/apex-mobile/references/pwa-checklist.md) - Core setup (archived from apex-mobile)
- [pwa-performance.md](../../_archive/batch-2026-02-19/apex-mobile/references/pwa-performance.md) - Performance (archived from apex-mobile)
- [pwa-lighthouse-fixes.md](./pwa-lighthouse-fixes.md) - Audit fixes
- [pwa-ios-limitations.md](./pwa-ios-limitations.md) - iOS workarounds
- [pwa-android-optimization.md](./pwa-android-optimization.md) - Android optimization
- [pwa-push-troubleshooting.md](./pwa-push-troubleshooting.md) - Push debugging
- [old-android-css-compat.md](./old-android-css-compat.md) - CSS fallbacks
- [service-worker-patterns.md](./service-worker-patterns.md) - SW patterns
- [offline-first-patterns.md](./offline-first-patterns.md) - Offline patterns

---

## 18. PERFORMANCE TARGETS (CLAUDE.md ALIGNED)

| Metric | Target | Critical | Check |
|--------|--------|----------|-------|
| LCP | < 1.0s | < 1.5s | CrUX 75th percentile |
| INP | < 100ms | < 200ms | CrUX 75th percentile |
| CLS | 0 | < 0.1 | CrUX 75th percentile |
| Bundle | < 100KB | < 120KB | Build analysis |
| FPS | 144 | 60 | Runtime monitoring |

### Verification Commands
```bash
# CrUX data check
npx psi https://your-app.com --strategy=mobile

# Bundle analysis
ANALYZE=true pnpm run build

# Runtime FPS monitoring
# DevTools > Performance > Record during interaction
```

---

## 19. 30-GATE PWA CHECKLIST

Verification items for CLAUDE.md gates:

### Gate 17 (RTL_STRICT)
- [ ] Manifest has `dir: 'rtl'` for Hebrew/Arabic apps
- [ ] Offline UI uses `ms-`/`me-` logical properties (not `ml-`/`mr-`) and `inset-s-`/`inset-e-` for inset (not `left-`/`right-`)
- [ ] Install prompt uses logical properties (`inset-s-`/`inset-e-` for positioning)
- [ ] Error messages use `text-start` (not `text-left`)

### Gate 29 (LCP)
- [ ] App shell loads < 1.0s
- [ ] Critical CSS inlined
- [ ] Above-fold images preloaded with `priority`
- [ ] Fonts preloaded with `display: swap`

### Gate 30 (CLS_Zero)
- [ ] No layout shifts from splash screens
- [ ] Icons have explicit width/height
- [ ] Skeleton loaders match final content size
- [ ] No FOUT (Flash of Unstyled Text)

### Gate 31 (Bundle)
- [ ] Total initial JS < 100KB gzipped
- [ ] Per-route chunks < 50KB
- [ ] Heavy components lazy loaded
- [ ] Tree-shaking verified

### Gate 50 (Spacing_Scale)
- [ ] All UI uses 8pt grid spacing
- [ ] Valid values: 4, 8, 12, 16, 24, 32, 48, 64px
- [ ] Tailwind: 1, 2, 3, 4, 6, 8, 12, 16
- [ ] No arbitrary spacing values

### Gate 52 (Component_Sizes)
- [ ] All buttons minimum 44x44px (`min-h-11 min-w-11`)
- [ ] All links minimum 44px height
- [ ] All tappable icons 44x44px
- [ ] Form inputs minimum 44px height

---

## 20. RTL COMPLIANCE CHECKLIST

> **Law #5 RTL-FIRST enforcement for PWA**

- [ ] Manifest has `dir: 'rtl'` and `lang: 'he'` (or `ar`)
- [ ] Offline page uses `ms-`, `me-`, `inset-s-`, `inset-e-` only (TW 4.2; `start-`/`end-` deprecated)
- [ ] Install prompt uses logical properties
- [ ] Numbers wrapped in `<span dir="ltr">{number}</span>`
- [ ] Directional icons have `rtl:rotate-180` class
- [ ] Decorative icons have `aria-hidden="true"` for screen readers
- [ ] No `ml-`, `mr-`, `pl-`, `pr-` in offline/install UI
- [ ] No `left-`, `right-` positioning (use `inset-s-`, `inset-e-`)
- [ ] No `text-left`, `text-right` (use `text-start`, `text-end`)

### Quick Fix Examples
```tsx
// Manifest RTL config
export default function manifest(): MetadataRoute.Manifest {
  return {
    dir: 'rtl',
    lang: 'he',
    // ...
  };
}

// Offline page RTL-compliant
<div className="flex flex-col items-center gap-4 p-6">
  <h1 className="text-xl font-bold text-center">אתה במצב לא מקוון</h1>
  <p className="text-muted-foreground text-start">
    <span dir="ltr">{retryCount}</span> ניסיונות נכשלו
  </p>
  <Button className="min-h-11 min-w-11">
    <ArrowIcon className="rtl:rotate-180" aria-hidden="true" />
    <span>חזרה</span>
  </Button>

  {/* Decorative icons always need aria-hidden */}
  <WifiOff className="w-5 h-5" aria-hidden="true" />
</div>
```

---

## 21. TOUCH TARGET CHECKLIST

> **Law #6 RESPONSIVE - 44px minimum touch targets**

- [ ] Install button: `min-h-11 min-w-11` (44x44px)
- [ ] Update button: `min-h-11 min-w-11` (44x44px)
- [ ] Dismiss/Close link: `min-h-11 py-2` (44px height)
- [ ] All interactive elements: minimum 44x44px
- [ ] Adequate spacing between touch targets (8px minimum)

### Quick Fix Examples
```tsx
// Install button
<Button
  onClick={handleInstall}
  className="min-h-11 min-w-11 px-6"
>
  התקן אפליקציה
</Button>

// Update prompt button
<Button
  onClick={handleUpdate}
  className="min-h-11 min-w-11 px-4"
>
  עדכן עכשיו
</Button>

// Dismiss link
<button
  onClick={handleDismiss}
  className="min-h-11 py-2 px-4 text-muted-foreground"
>
  לא עכשיו
</button>

// Icon button
<button className="h-11 w-11 flex items-center justify-center">
  <CloseIcon className="h-5 w-5" />
</button>
```

---

## 22. PASSIVE EVENT LISTENER CHECKLIST

> **Performance optimization for scroll/touch events**

- [ ] `touchstart` handlers use `{ passive: true }`
- [ ] `touchmove` handlers use `{ passive: true }`
- [ ] `wheel` handlers use `{ passive: true }`
- [ ] `scroll` handlers use `{ passive: true }`
- [ ] Only use `{ passive: false }` when `preventDefault()` is needed

### Quick Fix Examples
```tsx
// CORRECT - Passive listeners for performance
useEffect(() => {
  const handleTouchStart = (e: TouchEvent) => {
    // Handle touch without preventing default
  };

  const handleScroll = () => {
    // Handle scroll
  };

  const handleWheel = () => {
    // Handle wheel
  };

  // Add with passive: true
  document.addEventListener('touchstart', handleTouchStart, { passive: true });
  document.addEventListener('touchmove', handleTouchMove, { passive: true });
  document.addEventListener('wheel', handleWheel, { passive: true });
  document.addEventListener('scroll', handleScroll, { passive: true });

  return () => {
    document.removeEventListener('touchstart', handleTouchStart);
    document.removeEventListener('touchmove', handleTouchMove);
    document.removeEventListener('wheel', handleWheel);
    document.removeEventListener('scroll', handleScroll);
  };
}, []);

// ONLY use passive: false when you NEED preventDefault()
useEffect(() => {
  const handleTouchMove = (e: TouchEvent) => {
    e.preventDefault(); // Requires passive: false
    // Custom gesture handling
  };

  element.addEventListener('touchmove', handleTouchMove, { passive: false });
  return () => element.removeEventListener('touchmove', handleTouchMove);
}, []);
```

### Lighthouse Warning Fix
```tsx
// If Lighthouse reports "Does not use passive listeners"
// Check for these patterns and add { passive: true }:

// BAD - Missing passive option
element.addEventListener('touchstart', handler);
element.addEventListener('wheel', handler);

// GOOD - Explicit passive option
element.addEventListener('touchstart', handler, { passive: true });
element.addEventListener('wheel', handler, { passive: true });
```

---

## 23. RELOAD ON ONLINE WARNING

> **CRITICAL: `reloadOnOnline: true` can cause data loss**

If your PWA configuration includes `reloadOnOnline: true`, change it to `false`:

```tsx
// BAD - Can cause data loss and poor UX
const serwist = new Serwist({
  reloadOnOnline: true, // WARNING: Avoid this!
});

// GOOD - Let user control when to reload
const serwist = new Serwist({
  reloadOnOnline: false, // User decides when to refresh
});
```

### Why Avoid Auto-Reload
- **Data Loss**: Unsaved form data will be lost
- **Poor UX**: Unexpected page reload disrupts user workflow
- **Race Conditions**: May reload before sync completes
- **Battery Drain**: Unnecessary reloads on flaky connections

### Better Pattern
```tsx
// Show notification when back online, let user decide
window.addEventListener('online', () => {
  showToast({
    title: 'חזרת לרשת',
    description: 'האם לרענן את הדף?',
    action: {
      label: 'רענן',
      onClick: () => window.location.reload(),
    },
  });
});
```

---

---

## X. VERIFICATION SEAL

```
OMEGA_v24.5.0 | PWA_MASTER_CHECKLIST
Sections: 24 | Categories: 12 | Items: 160+
Gates: G-PWA-1 to G-PWA-9 + G-PWA-17 to G-PWA-22 + 30-GATE MATRIX | ALL_ENFORCED
RTL_FIRST: MANDATORY | RESPONSIVE: MANDATORY
CLAUDE.md: ALIGNED | Touch Targets: 44px ENFORCED
CRITICAL FIXES: navigator.onLine unreliability, SW double reload, dark mode flash, persistent storage, in-app browser, iOS SW health
```

<!-- PWA-EXPERT/MASTER-CHECKLIST v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->

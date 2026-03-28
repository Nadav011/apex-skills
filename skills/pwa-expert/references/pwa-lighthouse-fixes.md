# PWA Lighthouse Fixes v24.5.0 SINGULARITY FORGE

> Complete Lighthouse PWA audit fixes for Vite PWA, Next.js, Workbox, and old Android optimization

---

## 1. PURPOSE

This skill provides comprehensive fixes for all Lighthouse PWA audit failures:
- Installability requirements (SW registration, manifest, offline)
- PWA optimization (theme-color, maskable icons, viewport)
- Performance optimization (code splitting, caching, fonts)
- Old Android device optimization (backdrop-filter alternatives, GPU issues)
- Network-aware loading strategies
- Complete Vite PWA configuration

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/pwa audit` | Run Lighthouse PWA audit | ~30s |
| `/pwa fix-manifest` | Fix manifest installability issues | ~1min |
| `/pwa fix-offline` | Setup offline fallback page | ~2min |
| `/pwa fix-icons` | Generate all required icon sizes | ~1min |
| `/pwa fix-cache` | Configure workbox caching strategies | ~3min |
| `/pwa fix-android` | Apply old Android optimizations | ~5min |
| `/pwa config-vite` | Generate complete Vite PWA config | ~2min |

---

## 3. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-LH-1 | SW_REGISTERED | SW active in DevTools | Registration successful |
| G-LH-2 | MANIFEST_VALID | Lighthouse manifest check | All required fields |
| G-LH-3 | OFFLINE_200 | Offline navigation test | Returns 200 |
| G-LH-4 | THEME_COLOR | Meta + manifest match | Color defined |
| G-LH-5 | MASKABLE_ICON | purpose: maskable in manifest | 512x512 maskable |
| G-LH-6 | APPLE_TOUCH | apple-touch-icon 180x180 | Icon linked |
| G-LH-7 | VIEWPORT_FIT | viewport-fit=cover | Safe areas handled |
| G-LH-8 | BUNDLE_SIZE | < 100KB initial JS | Gzipped size |

---

## 4. FULL AUDIT COMMAND

```bash
# Full PWA audit
npx lighthouse https://your-app.com --only-categories=pwa --output=json --output-path=./pwa-report.json

# Local development (requires HTTPS or localhost)
npx lighthouse http://localhost:5173 --only-categories=pwa --chrome-flags="--ignore-certificate-errors"

# CI/CD integration
npx @lhci/cli autorun --collect.url=https://your-app.com
```

---

## 5. INSTALLABILITY FAILURES

### "Does not register a service worker"

**Cause:** Service worker not registered or registration fails.

**Fix (Vite PWA):**
```typescript
// vite.config.ts
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    VitePWA({
      registerType: 'autoUpdate',
      injectRegister: 'auto', // or 'script' for manual control
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
      },
    }),
  ],
});
```

**Fix (Manual Registration):**
```typescript
// src/sw-register.ts
export function registerServiceWorker() {
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', async () => {
      try {
        const registration = await navigator.serviceWorker.register('/sw.js', {
          scope: '/',
        });
        console.log('SW registered:', registration.scope);
      } catch (error) {
        console.error('SW registration failed:', error);
      }
    });
  }
}

// main.tsx - call after app loads
import { registerServiceWorker } from './sw-register';
registerServiceWorker();
```

**Timing is critical:** Register after `load` event, not immediately.

---

### "Web app manifest does not meet installability requirements"

**Cause:** Missing required fields or invalid values in manifest.

**Required Fields Checklist:**
```json
{
  "name": "App Name (full, max 45 chars)",
  "short_name": "App (max 12 chars for home screen)",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    }
  ]
}
```

**Fix (Vite PWA):**
```typescript
// vite.config.ts
VitePWA({
  manifest: {
    name: 'Cash Delivery Management',
    short_name: 'Cash',
    description: 'Delivery tracking and management system',
    start_url: '/',
    display: 'standalone',
    orientation: 'portrait',
    background_color: '#ffffff',
    theme_color: '#3b82f6',
    lang: 'he',
    dir: 'rtl',
    icons: [
      {
        src: '/icons/icon-192x192.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'any',
      },
      {
        src: '/icons/icon-512x512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'any',
      },
      {
        src: '/icons/icon-maskable-512x512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'maskable',
      },
    ],
  },
})
```

**Icon Requirements:**
| Size | Purpose | Required |
|------|---------|----------|
| 192x192 | Install prompt | Yes |
| 512x512 | Splash screen | Yes |
| 512x512 maskable | Adaptive icons | Recommended |

---

### "Does not respond with 200 when offline"

**Cause:** No offline fallback page cached.

**Fix (Workbox):**
```typescript
// vite.config.ts
VitePWA({
  workbox: {
    // Precache app shell
    globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],

    // Offline fallback
    navigateFallback: '/offline.html',
    navigateFallbackDenylist: [/^\/api\//],

    // Runtime caching for navigation
    runtimeCaching: [
      {
        urlPattern: ({ request }) => request.mode === 'navigate',
        handler: 'NetworkFirst',
        options: {
          cacheName: 'pages-cache',
          networkTimeoutSeconds: 3,
          plugins: [
            {
              handlerDidError: async () => {
                return caches.match('/offline.html');
              },
            },
          ],
        },
      },
    ],
  },
})
```

**Create offline.html:**
```html
<!-- public/offline.html -->
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>אופליין - Cash</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background: #f5f5f5;
      text-align: center;
    }
    .container {
      padding: 2rem;
    }
    h1 { color: #333; margin-bottom: 1rem; }
    p { color: #666; }
    button {
      margin-top: 1.5rem;
      padding: 0.75rem 1.5rem;
      background: #3b82f6;
      color: white;
      border: none;
      border-radius: 0.5rem;
      cursor: pointer;
      min-height: 44px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>אין חיבור לאינטרנט</h1>
    <p>נראה שאין חיבור לרשת. בדוק את החיבור ונסה שוב.</p>
    <button onclick="location.reload()">נסה שוב</button>
  </div>
</body>
</html>
```

---

### "start_url does not respond with 200 when offline"

**Cause:** start_url not in precache or cache-first strategy.

**Fix:**
```typescript
// vite.config.ts
VitePWA({
  workbox: {
    // Ensure start_url is precached
    globPatterns: ['**/*.{js,css,html,ico,png,svg}'],

    // Additional URLs to precache
    additionalManifestEntries: [
      { url: '/', revision: null },
      { url: '/index.html', revision: null },
    ],

    // Navigation handling
    navigateFallback: '/index.html',
    navigateFallbackAllowlist: [/^\/$/],
  },
})
```

**For SPA with client-side routing:**
```typescript
// Custom service worker (sw.ts)
import { precacheAndRoute, createHandlerBoundToURL } from 'workbox-precaching';
import { NavigationRoute, registerRoute } from 'workbox-routing';

// Precache all assets
precacheAndRoute(self.__WB_MANIFEST);

// Handle navigation requests
const handler = createHandlerBoundToURL('/index.html');
const navigationRoute = new NavigationRoute(handler, {
  denylist: [/^\/api\//, /^\/auth\//],
});
registerRoute(navigationRoute);
```

---

## 6. PWA OPTIMIZED FAILURES

### "Does not set a theme-color"

**Cause:** Missing theme-color in both HTML meta and manifest.

**Fix (Both Required):**
```html
<!-- index.html -->
<head>
  <meta name="theme-color" content="#3b82f6">
  <!-- For iOS Safari -->
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
</head>
```

```json
// manifest.json
{
  "theme_color": "#3b82f6"
}
```

**Dynamic theme-color (dark mode):**
```html
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#1a1a1a" media="(prefers-color-scheme: dark)">
```

---

### "Manifest doesn't have a maskable icon"

**Cause:** No icon with `purpose: "maskable"`.

**Safe Zone Requirements:**
- Content must be within center 80% of icon
- Outer 10% on each side may be clipped
- Use solid background color (no transparency)

**Fix:**
```json
{
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/maskable-icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

**Generate maskable icons:**
```bash
# Using maskable.app or pwa-asset-generator
npx pwa-asset-generator logo.svg ./public/icons --maskable --padding "20%"
```

---

### "Content is not sized correctly for viewport"

**Cause:** Missing or incorrect viewport meta, horizontal overflow.

**Fix:**
```html
<!-- index.html -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
```

```css
/* global.css */
html, body {
  overflow-x: hidden;
  width: 100%;
}

/* Safe area for notched devices — RTL-aware */
.content {
  padding-inline-start: env(safe-area-inset-left);
  padding-inline-end: env(safe-area-inset-right);
  padding-bottom: env(safe-area-inset-bottom);
}
```

**Debug horizontal scroll:**
```javascript
// Find elements causing overflow
document.querySelectorAll('*').forEach(el => {
  if (el.scrollWidth > el.clientWidth) {
    console.log('Overflow:', el);
  }
});
```

---

### "Does not provide a valid apple-touch-icon"

**Cause:** Missing or incorrectly sized Apple touch icon.

**Fix:**
```html
<!-- index.html -->
<head>
  <!-- Primary apple-touch-icon (180x180 for modern devices) -->
  <link rel="apple-touch-icon" sizes="180x180" href="/icons/apple-touch-icon.png">

  <!-- Additional sizes for older devices (optional) -->
  <link rel="apple-touch-icon" sizes="152x152" href="/icons/apple-touch-icon-152x152.png">
  <link rel="apple-touch-icon" sizes="120x120" href="/icons/apple-touch-icon-120x120.png">

  <!-- iOS splash screens (optional but recommended) -->
  <link rel="apple-touch-startup-image" href="/splash/apple-splash-2048-2732.png"
        media="(device-width: 1024px) and (device-height: 1366px)">
</head>
```

**Requirements:**
- Size: 180x180 PNG (primary)
- Format: PNG, non-transparent OK
- No rounded corners (iOS adds them)
- Place in public folder root or /icons

---

## 7. PERFORMANCE FAILURES

### "Reduce unused JavaScript"

**Fix (Code Splitting):**
```typescript
// React lazy loading
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

**Vite Build Optimization:**
```typescript
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          query: ['@tanstack/react-query'],
          ui: ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
        },
      },
    },
  },
});
```

---

### "Serve static assets with efficient cache policy"

**Fix (Service Worker Caching):**
```typescript
// vite.config.ts
VitePWA({
  workbox: {
    runtimeCaching: [
      // Images - Cache First (long-lived)
      {
        urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp|avif)$/,
        handler: 'CacheFirst',
        options: {
          cacheName: 'images-cache',
          expiration: {
            maxEntries: 100,
            maxAgeSeconds: 60 * 60 * 24 * 30, // 30 days
          },
        },
      },
      // Fonts - Cache First
      {
        urlPattern: /\.(?:woff|woff2|ttf|otf)$/,
        handler: 'CacheFirst',
        options: {
          cacheName: 'fonts-cache',
          expiration: {
            maxEntries: 20,
            maxAgeSeconds: 60 * 60 * 24 * 365, // 1 year
          },
        },
      },
      // API - Network First
      {
        urlPattern: /^https:\/\/api\./,
        handler: 'NetworkFirst',
        options: {
          cacheName: 'api-cache',
          networkTimeoutSeconds: 5,
          expiration: {
            maxEntries: 50,
            maxAgeSeconds: 60 * 5, // 5 minutes
          },
        },
      },
    ],
  },
})
```

**Vercel Headers (vercel.json):**
```json
{
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    },
    {
      "source": "/(.*).js",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

---

### "Eliminate render-blocking resources"

**Fix (Font Loading):**
```html
<!-- Preload critical fonts -->
<link rel="preload" href="/fonts/inter-var.woff2" as="font" type="font/woff2" crossorigin>

<!-- Font display swap -->
<style>
  @font-face {
    font-family: 'Inter';
    src: url('/fonts/inter-var.woff2') format('woff2');
    font-display: swap;
  }
</style>
```

**Fix (Critical CSS):**
```typescript
// vite.config.ts
import criticalCSS from 'vite-plugin-critical';

export default defineConfig({
  plugins: [
    criticalCSS({
      criticalUrl: 'http://localhost:5173',
      criticalPages: [{ uri: '/', template: 'index' }],
    }),
  ],
});
```

**Fix (Script Defer):**
```html
<!-- Defer non-critical scripts -->
<script defer src="/analytics.js"></script>

<!-- Async for independent scripts -->
<script async src="/third-party.js"></script>
```

---

## 8. OLD ANDROID PERFORMANCE OPTIMIZATION

> **Target:** Android 8-10 (API 26-29), Chrome 70-90, WebView-based apps
> **Critical:** These devices represent 30-40% of users in many markets

### backdrop-filter Alternatives

**Problem:** `backdrop-filter: blur()` causes severe performance issues on old Android:
- GPU memory spikes
- Frame drops to 10-15fps
- Battery drain
- Complete UI freezes on some devices

**Detection:**
```typescript
// utils/device-capabilities.ts
export function supportsBackdropFilter(): boolean {
  // Check CSS support
  const hasCSS = CSS.supports('backdrop-filter', 'blur(10px)') ||
                 CSS.supports('-webkit-backdrop-filter', 'blur(10px)');

  if (!hasCSS) return false;

  // Check device capability (old Android struggles even with support)
  const ua = navigator.userAgent;
  const androidMatch = ua.match(/Android (\d+)/);
  if (androidMatch) {
    const version = parseInt(androidMatch[1], 10);
    if (version < 11) return false; // Disable for Android 10 and below
  }

  // Check for low-end device markers
  const isLowEnd = navigator.hardwareConcurrency <= 4 ||
                   (navigator.deviceMemory && navigator.deviceMemory < 4);

  return !isLowEnd;
}
```

**CSS Fallback Pattern:**
```css
/* Modern devices - blur effect */
@supports (backdrop-filter: blur(10px)) {
  .modal-overlay {
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    background: rgba(0, 0, 0, 0.3);
  }
}

/* Fallback - semi-transparent background */
@supports not (backdrop-filter: blur(10px)) {
  .modal-overlay {
    background: rgba(0, 0, 0, 0.75);
  }
}

/* Force fallback for old Android via data attribute */
[data-low-end="true"] .modal-overlay {
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  background: rgba(0, 0, 0, 0.85);
}
```

**React Component Pattern:**
```tsx
// components/SafeOverlay.tsx
import { useEffect, useState } from 'react';
import { supportsBackdropFilter } from '@/utils/device-capabilities';

interface SafeOverlayProps {
  children: React.ReactNode;
  className?: string;
}

export function SafeOverlay({ children, className }: SafeOverlayProps) {
  const [useBlur, setUseBlur] = useState(true);

  useEffect(() => {
    setUseBlur(supportsBackdropFilter());
  }, []);

  return (
    <div
      className={cn(
        'fixed inset-0 z-50',
        useBlur
          ? 'bg-black/30 backdrop-blur-md'
          : 'bg-black/85',
        className
      )}
    >
      {children}
    </div>
  );
}
```

---

### GPU Acceleration Differences

**Problem:** Old Android WebView has inconsistent GPU acceleration:
- `transform: translateZ(0)` can cause rendering artifacts
- `will-change` is ignored or causes memory issues
- Hardware acceleration can be disabled by OEM

**Safe Transforms for Old Android:**
```css
/* AVOID on old Android - causes flickering */
.card {
  transform: translateZ(0); /* Don't use */
  will-change: transform; /* Don't use */
  backface-visibility: hidden; /* Can cause issues */
}

/* SAFE - CPU-based, predictable */
.card {
  transform: translate(0, 0); /* 2D transform only */
}

/* Conditional GPU acceleration */
@media (min-resolution: 2dppx) {
  /* High-DPI = likely modern device */
  .card {
    transform: translateZ(0);
    will-change: transform;
  }
}
```

**Animation Performance:**
```typescript
// hooks/useSafeAnimation.ts
import { useEffect, useState } from 'react';

export function useSafeAnimation() {
  const [animationConfig, setAnimationConfig] = useState({
    duration: 300,
    useTransform3d: true,
    useWillChange: true,
  });

  useEffect(() => {
    const isOldAndroid = /Android [4-9]\./.test(navigator.userAgent);
    const isLowEnd = navigator.hardwareConcurrency <= 4;

    if (isOldAndroid || isLowEnd) {
      setAnimationConfig({
        duration: 200, // Shorter = less frames to render
        useTransform3d: false,
        useWillChange: false,
      });
    }
  }, []);

  return animationConfig;
}
```

**Motion Optimization (motion/react):**
```tsx
// Use reduced motion for old devices
import { motion, useReducedMotion } from 'motion/react';

function AnimatedCard({ children }: { children: React.ReactNode }) {
  const prefersReduced = useReducedMotion();
  const isOldAndroid = /Android [4-9]\./.test(navigator.userAgent);

  const shouldReduce = prefersReduced || isOldAndroid;

  return (
    <motion.div
      initial={shouldReduce ? false : { opacity: 0, y: 20 }}
      animate={shouldReduce ? undefined : { opacity: 1, y: 0 }}
      transition={shouldReduce ? { duration: 0 } : { duration: 0.3 }}
    >
      {children}
    </motion.div>
  );
}
```

---

### Bundle Size Impact on Old Devices

**Problem:** Old Android devices have:
- Slower CPU for JavaScript parsing (2-4x slower)
- Less RAM for large bundles
- Slower storage I/O for cache reads

**Bundle Size Guidelines by Device Class:**

| Device Class | JS Budget | CSS Budget | Total |
|--------------|-----------|------------|-------|
| Modern (Android 12+) | 150KB | 50KB | 200KB |
| Mid-range (Android 10-11) | 100KB | 40KB | 140KB |
| Old (Android 8-9) | 70KB | 30KB | 100KB |
| Legacy (Android 7) | 50KB | 20KB | 70KB |

**Aggressive Code Splitting:**
```typescript
// vite.config.ts - Optimized for old devices
export default defineConfig({
  build: {
    target: 'es2018', // Don't go lower than needed
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
        passes: 2, // Extra minification pass
      },
    },
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          // Core - always loaded
          if (id.includes('react') || id.includes('react-dom')) {
            return 'react-core';
          }
          // Router - loaded on navigation
          if (id.includes('react-router')) {
            return 'router';
          }
          // Query - loaded on data fetch
          if (id.includes('@tanstack/react-query')) {
            return 'query';
          }
          // UI components - loaded on demand
          if (id.includes('@radix-ui')) {
            return 'ui-components';
          }
          // Forms - loaded on form pages
          if (id.includes('react-hook-form') || id.includes('zod')) {
            return 'forms';
          }
        },
        // Smaller chunks for parallel loading
        chunkFileNames: 'js/[name]-[hash:8].js',
        entryFileNames: 'js/[name]-[hash:8].js',
      },
    },
    // Target smaller chunks
    chunkSizeWarningLimit: 50, // Warn at 50KB
  },
});
```

**Conditional Feature Loading:**
```typescript
// utils/feature-loader.ts
export async function loadHeavyFeature(feature: 'charts' | 'maps' | 'editor') {
  const isLowEnd = navigator.hardwareConcurrency <= 4 ||
                   (navigator.deviceMemory && navigator.deviceMemory < 4);

  if (isLowEnd) {
    // Load lightweight alternatives
    switch (feature) {
      case 'charts':
        return import('./charts-lite'); // Simpler chart library
      case 'maps':
        return import('./maps-static'); // Static map images
      case 'editor':
        return import('./editor-basic'); // Basic textarea
    }
  }

  // Full featured versions
  switch (feature) {
    case 'charts':
      return import('./charts-full');
    case 'maps':
      return import('./maps-interactive');
    case 'editor':
      return import('./editor-rich');
  }
}
```

---

### Connection-Aware Loading Strategies

**Problem:** Old Android devices often on slow networks (2G/3G):
- Higher latency
- Limited bandwidth
- Data caps

**Network Information API:**
```typescript
// hooks/useNetworkQuality.ts
import { useEffect, useState } from 'react';

interface NetworkQuality {
  type: 'slow-2g' | '2g' | '3g' | '4g' | 'unknown';
  saveData: boolean;
  downlink: number; // Mbps
  rtt: number; // ms
  isMetered: boolean;
}

export function useNetworkQuality(): NetworkQuality {
  const [quality, setQuality] = useState<NetworkQuality>({
    type: 'unknown',
    saveData: false,
    downlink: 10,
    rtt: 50,
    isMetered: false,
  });

  useEffect(() => {
    const connection = (navigator as any).connection ||
                       (navigator as any).mozConnection ||
                       (navigator as any).webkitConnection;

    if (!connection) return;

    const updateQuality = () => {
      setQuality({
        type: connection.effectiveType || 'unknown',
        saveData: connection.saveData || false,
        downlink: connection.downlink || 10,
        rtt: connection.rtt || 50,
        isMetered: connection.type === 'cellular',
      });
    };

    updateQuality();
    connection.addEventListener('change', updateQuality);

    return () => connection.removeEventListener('change', updateQuality);
  }, []);

  return quality;
}
```

**Adaptive Image Loading:**
```tsx
// components/AdaptiveImage.tsx
import { useNetworkQuality } from '@/hooks/useNetworkQuality';

interface AdaptiveImageProps {
  src: string;
  alt: string;
  className?: string;
}

export function AdaptiveImage({ src, alt, className }: AdaptiveImageProps) {
  const { type, saveData } = useNetworkQuality();

  // Determine image quality based on network
  const getImageUrl = () => {
    if (saveData || type === 'slow-2g' || type === '2g') {
      // Lowest quality - 30% size
      return src.replace('/images/', '/images/low/');
    }
    if (type === '3g') {
      // Medium quality - 60% size
      return src.replace('/images/', '/images/medium/');
    }
    // Full quality
    return src;
  };

  return (
    <img
      src={getImageUrl()}
      alt={alt}
      className={className}
      loading="lazy"
      decoding="async"
    />
  );
}
```

**Service Worker Caching by Network:**
```typescript
// sw.ts - Adaptive caching
import { NetworkFirst, CacheFirst, StaleWhileRevalidate } from 'workbox-strategies';
import { registerRoute } from 'workbox-routing';

// API calls - adaptive strategy
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  async (args) => {
    const connection = (navigator as any).connection;
    const effectiveType = connection?.effectiveType || '4g';

    if (effectiveType === 'slow-2g' || effectiveType === '2g') {
      // Slow connection - prefer cache
      return new CacheFirst({
        cacheName: 'api-slow',
        networkTimeoutSeconds: 2,
      }).handle(args);
    }

    // Fast connection - prefer network
    return new NetworkFirst({
      cacheName: 'api-fast',
      networkTimeoutSeconds: 5,
    }).handle(args);
  }
);
```

**Data Saver Mode UI:**
```tsx
// components/DataSaverBanner.tsx
import { useNetworkQuality } from '@/hooks/useNetworkQuality';

export function DataSaverBanner() {
  const { saveData, type } = useNetworkQuality();

  if (!saveData && type !== 'slow-2g') return null;

  return (
    <div className="fixed bottom-16 inset-s-4 inset-e-4 z-40 rounded-lg bg-amber-100 p-3 text-sm text-amber-800 shadow-lg">
      <div className="flex items-center gap-2">
        <span>Data saver mode - images reduced</span>
      </div>
    </div>
  );
}
```

---

### Complete Old Android Detection Utility

```typescript
// utils/device-detection.ts
export interface DeviceCapabilities {
  isOldAndroid: boolean;
  isLowEnd: boolean;
  androidVersion: number | null;
  supportsBackdropFilter: boolean;
  supportsWebGL: boolean;
  coreCount: number;
  memoryGB: number;
  connectionType: string;
  tier: 'high' | 'medium' | 'low' | 'minimal';
}

export function detectDeviceCapabilities(): DeviceCapabilities {
  const ua = navigator.userAgent;
  const androidMatch = ua.match(/Android (\d+)\.?(\d+)?/);
  const androidVersion = androidMatch ? parseFloat(`${androidMatch[1]}.${androidMatch[2] || 0}`) : null;

  const coreCount = navigator.hardwareConcurrency || 4;
  const memoryGB = (navigator as any).deviceMemory || 4;

  const connection = (navigator as any).connection;
  const connectionType = connection?.effectiveType || 'unknown';

  const isOldAndroid = androidVersion !== null && androidVersion < 11;
  const isLowEnd = coreCount <= 4 || memoryGB < 4;

  // WebGL check
  let supportsWebGL = false;
  try {
    const canvas = document.createElement('canvas');
    supportsWebGL = !!(canvas.getContext('webgl') || canvas.getContext('experimental-webgl'));
  } catch (e) {
    supportsWebGL = false;
  }

  // Backdrop filter check
  const supportsBackdropFilter =
    (CSS.supports('backdrop-filter', 'blur(10px)') ||
     CSS.supports('-webkit-backdrop-filter', 'blur(10px)')) &&
    !isOldAndroid;

  // Determine tier
  let tier: 'high' | 'medium' | 'low' | 'minimal';
  if (isOldAndroid && isLowEnd) {
    tier = 'minimal';
  } else if (isOldAndroid || isLowEnd) {
    tier = 'low';
  } else if (coreCount >= 8 && memoryGB >= 8) {
    tier = 'high';
  } else {
    tier = 'medium';
  }

  return {
    isOldAndroid,
    isLowEnd,
    androidVersion,
    supportsBackdropFilter,
    supportsWebGL,
    coreCount,
    memoryGB,
    connectionType,
    tier,
  };
}

// React hook
export function useDeviceCapabilities(): DeviceCapabilities {
  const [capabilities, setCapabilities] = useState<DeviceCapabilities>(() => ({
    isOldAndroid: false,
    isLowEnd: false,
    androidVersion: null,
    supportsBackdropFilter: true,
    supportsWebGL: true,
    coreCount: 8,
    memoryGB: 8,
    connectionType: '4g',
    tier: 'high',
  }));

  useEffect(() => {
    setCapabilities(detectDeviceCapabilities());
  }, []);

  return capabilities;
}
```

**Apply Capabilities Globally:**
```tsx
// App.tsx
import { useDeviceCapabilities } from '@/utils/device-detection';

function App() {
  const { tier, isOldAndroid } = useDeviceCapabilities();

  useEffect(() => {
    // Set data attributes for CSS targeting
    document.documentElement.dataset.deviceTier = tier;
    document.documentElement.dataset.oldAndroid = String(isOldAndroid);
  }, [tier, isOldAndroid]);

  return (
    <DeviceCapabilitiesProvider value={capabilities}>
      {/* App content */}
    </DeviceCapabilitiesProvider>
  );
}
```

**CSS Targeting by Tier:**
```css
/* Minimal tier - disable all fancy effects */
[data-device-tier="minimal"] {
  --animation-duration: 0ms;
  --blur-amount: 0;
  --shadow-opacity: 0.3;
}

[data-device-tier="minimal"] .glass-effect {
  backdrop-filter: none;
  background: rgba(255, 255, 255, 0.95);
}

[data-device-tier="minimal"] .animated-element {
  animation: none;
  transition: none;
}

/* Low tier - reduced effects */
[data-device-tier="low"] {
  --animation-duration: 150ms;
  --blur-amount: 5px;
}

/* Medium and high - full effects */
[data-device-tier="medium"],
[data-device-tier="high"] {
  --animation-duration: 300ms;
  --blur-amount: 20px;
}
```

---

### Old Android Checklist

- [ ] `backdrop-filter` has fallback (solid background)
- [ ] Device capability detection in place
- [ ] Bundle size < 100KB for initial load
- [ ] Code splitting for features
- [ ] Network quality detection active
- [ ] Adaptive image loading based on connection
- [ ] Reduced animations on low-end devices
- [ ] No `will-change` on old Android
- [ ] Service worker cache prioritized on slow networks
- [ ] Data saver mode respected
- [ ] WebGL features gracefully degrade

---

## 9. BEST PRACTICES FAILURES

### "Does not use HTTPS"

**Local Development:**
```bash
# Generate local certs
mkcert -install
mkcert localhost 127.0.0.1 ::1

# Vite config
export default defineConfig({
  server: {
    https: {
      key: './localhost-key.pem',
      cert: './localhost.pem',
    },
  },
});
```

**Production:** Deploy to HTTPS-enabled host (Vercel, Netlify, Cloudflare).

**Mixed Content Fix:**
```html
<!-- Upgrade all HTTP to HTTPS -->
<meta http-equiv="Content-Security-Policy" content="upgrade-insecure-requests">
```

---

### "Registers service worker that controls page and start_url"

**Cause:** Service worker scope doesn't include start_url.

**Fix:**
```javascript
// Registration with correct scope
navigator.serviceWorker.register('/sw.js', {
  scope: '/', // Must include start_url path
});
```

**Manifest start_url must be within scope:**
```json
{
  "start_url": "/",
  "scope": "/"
}
```

**For subdirectory apps:**
```json
{
  "start_url": "/app/",
  "scope": "/app/"
}
```

---

## 10. COMPLETE VITE PWA CONFIGURATION

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'robots.txt', 'icons/*.png'],

      manifest: {
        name: 'Cash Delivery Management',
        short_name: 'Cash',
        description: 'Track and manage deliveries',
        start_url: '/',
        display: 'standalone',
        orientation: 'portrait',
        background_color: '#ffffff',
        theme_color: '#3b82f6',
        lang: 'he',
        dir: 'rtl',
        categories: ['business', 'productivity'],
        icons: [
          {
            src: '/icons/icon-192x192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any',
          },
          {
            src: '/icons/icon-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any',
          },
          {
            src: '/icons/maskable-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
        screenshots: [
          {
            src: '/screenshots/mobile.png',
            sizes: '750x1334',
            type: 'image/png',
            form_factor: 'narrow',
          },
          {
            src: '/screenshots/desktop.png',
            sizes: '1920x1080',
            type: 'image/png',
            form_factor: 'wide',
          },
        ],
      },

      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        navigateFallback: '/index.html',
        navigateFallbackDenylist: [/^\/api\//, /^\/auth\//],
        cleanupOutdatedCaches: true,
        clientsClaim: true,
        skipWaiting: true,

        runtimeCaching: [
          {
            urlPattern: /^https:\/\/.*\.supabase\.co\//,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'supabase-cache',
              networkTimeoutSeconds: 5,
              expiration: { maxEntries: 50, maxAgeSeconds: 300 },
            },
          },
          {
            urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp)$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'images-cache',
              expiration: { maxEntries: 100, maxAgeSeconds: 2592000 },
            },
          },
        ],
      },

      devOptions: {
        enabled: true,
        type: 'module',
      },
    }),
  ],
});
```

---

## 11. AUDIT CHECKLIST

### Installability
- [ ] Service worker registered after page load
- [ ] Manifest has name, short_name, start_url
- [ ] Manifest has 192x192 and 512x512 icons
- [ ] display is standalone, fullscreen, or minimal-ui
- [ ] Offline page returns 200
- [ ] start_url returns 200 when offline

### PWA Optimized
- [ ] theme-color in meta tag AND manifest
- [ ] Maskable icon with purpose: maskable
- [ ] Viewport meta tag with width=device-width
- [ ] apple-touch-icon 180x180 linked

### Performance
- [ ] Bundle < 100KB gzipped
- [ ] Code splitting for routes
- [ ] Cache-Control headers for assets
- [ ] Fonts use display: swap
- [ ] Critical CSS inlined

### Best Practices
- [ ] HTTPS in production
- [ ] No mixed content
- [ ] Service worker scope includes start_url

---

## 12. DEBUGGING TOOLS

```bash
# Chrome DevTools
# Application > Service Workers
# Application > Manifest
# Lighthouse > PWA

# Validate manifest
npx web-app-manifest-validator manifest.json

# Test offline
# DevTools > Network > Offline checkbox

# Clear service worker
# DevTools > Application > Service Workers > Unregister
```

---

## 13. RELATED SKILLS

- `/skill pwa-ios-limitations` - iOS PWA platform limitations
- `/skill pwa-push-troubleshooting` - Push notification debugging
- `/skill offline-first-reference` - Offline-first architecture

---

## 14. VERIFICATION SEAL

```
OMEGA_v24.5.0 | PWA_LIGHTHOUSE_FIXES
Gates: 8 | Commands: 7 | Phase: 2.4
INSTALLABILITY | OFFLINE_FIRST | OLD_ANDROID | NETWORK_AWARE
RTL_FIRST: MANDATORY | RESPONSIVE: MANDATORY
```

<!-- PWA-EXPERT/LIGHTHOUSE v24.5.0 | Updated: 2026-02-19 -->

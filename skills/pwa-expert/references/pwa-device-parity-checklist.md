# PWA Device Parity Checklist v24.5.0 SINGULARITY FORGE

> **Supreme Reference for PWA Compatibility: iPhone ↔ Old Android Parity**
> **Triggers:** pwa compatibility, old android, device parity, cross-platform pwa

---

## 1. PURPOSE

Ensure PWA looks and functions IDENTICALLY on iPhone and old Android devices (Chrome < 84, Android 8-10). This skill addresses the 10 critical gaps that cause PWA failures on old devices.

---

## 2. GATE MATRIX

| Gate | Name | Threshold | Severity |
|------|------|-----------|----------|
| G-DP-1 | BUILD_TARGET | ES2018 | CRITICAL |
| G-DP-2 | CSS_COMPAT | No @container | CRITICAL |
| G-DP-3 | ANIMATION_PERF | No box-shadow transition | CRITICAL |
| G-DP-3.1 | CSS_CONTAINMENT | No contain-content on Android | CRITICAL |
| G-DP-4 | BROWSER_DETECT | Chrome version detection | HIGH |
| G-DP-5 | POLYFILLS | All required loaded | HIGH |
| G-DP-6 | SW_CACHE | Selective cleanup | HIGH |
| G-DP-7 | IOS_PARITY | All iOS fixes | MEDIUM |
| G-DP-8 | DARK_MODE | System preference | MEDIUM |
| G-DP-9 | AUTOFILL | Styled correctly | LOW |
| G-DP-10 | TESTING | Real device tested | CRITICAL |
| G-DP-11 | GRADIENT_OPTIMIZE | Intelligent gradient fallback (not orange!) | HIGH |
| G-DP-12 | SCROLL_OPTIMIZE | is-scrolling class + passive listeners | HIGH |
| G-DP-13 | TOUCH_TARGETS | 44px minimum touch targets | HIGH |
| G-DP-14 | SPINNER_A11Y | role="status" + aria-label on spinners | MEDIUM |

---

## 3. BUILD TARGET (G-DP-1) - CRITICAL

### 3.1 Problem
ES2020+ features break on old Android WebView (Chrome < 84):
- `Promise.allSettled` - ES2020
- Optional chaining `?.` - ES2020
- Nullish coalescing `??` - ES2020
- `String.prototype.matchAll` - ES2020

### 3.2 Vite Configuration

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    // CRITICAL: Use ES2018 for old Android compatibility
    // Chrome 64+ supports ES2018, Chrome 80+ supports ES2020
    target: "es2018",

    // Ensure proper transpilation
    cssTarget: "chrome61",
  },

  esbuild: {
    // Match build target
    target: "es2018",
  },
});
```

### 3.3 Promise.allSettled ES2018 Pattern

```typescript
// ❌ BAD - ES2020 only
const results = await Promise.allSettled(promises);

// ✅ GOOD - ES2018 compatible
const results = await Promise.all(
  promises.map((p) =>
    p.then(
      (value) => ({ status: "fulfilled" as const, value }),
      (reason) => ({ status: "rejected" as const, reason }),
    ),
  ),
);

// Usage remains identical
results.forEach((result) => {
  if (result.status === "fulfilled") {
    console.log(result.value);
  } else {
    console.error(result.reason);
  }
});
```

### 3.4 Verification

```bash
# Check build output for ES2020+ syntax
grep -r "Promise.allSettled\|??\|?\." dist/assets/*.js
# Should return empty if properly transpiled
```

---

## 4. CSS COMPATIBILITY (G-DP-2, G-DP-3) - CRITICAL

### 4.1 Container Queries - NEVER USE DIRECTLY

```tsx
// ❌ BAD - Chrome 105+ only (breaks Android 8-12)
className="@container/card @md/card:flex-row"

// ✅ GOOD - Use media queries
className="md:flex-row"

// ✅ GOOD - Use Tailwind responsive prefixes
className="flex-col md:flex-row lg:grid"
```

### 4.2 Box-Shadow Transitions - REMOVE

Box-shadow transitions cause **60fps → 15fps jank** on old Android.

```tsx
// ❌ BAD - Causes jank
className="transition-all duration-200"
// or
className="transition-[color,background-color,box-shadow] duration-200"

// ✅ GOOD - Exclude box-shadow
className="transition-[color,background-color,border-color,transform] duration-200"

// ✅ GOOD - Use discrete transitions only
className="transition-colors duration-200"
className="transition-transform duration-200"
className="transition-opacity duration-200"
```

**Files commonly affected:**
- Button, Card, Input, Select, Checkbox, Radio, Textarea
- Badge, InputGroup, Navigation items
- Delivery cards, Autocomplete inputs

### 4.3 Backdrop-Filter Fallback

```tsx
// ❌ BAD - Not supported on old WebView
className="backdrop-blur-md bg-background/80"

// ✅ GOOD - Solid fallback
className="bg-background/95"

// ✅ GOOD - CSS with @supports
.glass-effect {
  background: hsl(var(--background) / 0.95);
}
@supports (backdrop-filter: blur(12px)) {
  .glass-effect {
    backdrop-filter: blur(12px);
    background: hsl(var(--background) / 0.8);
  }
}
```

### 4.4 CSS Containment - CRITICAL BUG (G-DP-3.1)

**Problem:** `contain-content`, `contain-layout`, `contain-paint` CSS properties cause elements to **DISAPPEAR** during scroll on old Android Chrome (<90). This is a known rendering bug.

**Symptoms:**
- Elements disappear and reappear while scrolling
- Components flicker or vanish temporarily
- Layout seems to "reset" during fast scrolling

**Files commonly affected:**
- Cards, list items, grid cells
- Any component using `contain-content` for performance optimization

**CSS Fix - Add to index.css:**

```css
/* ===== ANDROID: DISABLE CSS CONTAINMENT ===== */
/* contain-content causes elements to disappear during scroll on old Chrome */
/* This is a known bug in Chrome <90 with CSS containment */
.is-android .contain-content,
.is-android .contain-layout,
.is-android .contain-paint,
.is-android .contain-strict,
.is-android [class*="contain-"] {
  contain: none !important;
}

/* Also disable containment on all elements for old Android */
.is-android-old * {
  contain: none !important;
}
```

**Verification:**

```bash
# Check for contain-content usage
grep -r "contain-content\|contain-layout\|contain-paint" --include="*.tsx" src/

# Ensure CSS override is in place
grep -r "contain: none" src/index.css
```

### 4.5 Flexbox Gap Fallbacks

Add to `index.css`:

```css
/* Gap fallbacks for old Android (Chrome < 84) */
/* Applied when .is-android-old class is on documentElement */

/* gap-1 (0.25rem) */
.is-android-old .flex.gap-1 > * { margin-inline-start: 0.25rem; }
.is-android-old .flex.gap-1 > *:first-child { margin-inline-start: 0; }
.is-android-old .flex-col.gap-1 > * { margin-top: 0.25rem; margin-inline-start: 0; }
.is-android-old .flex-col.gap-1 > *:first-child { margin-top: 0; }

/* gap-2 (0.5rem) */
.is-android-old .flex.gap-2 > * { margin-inline-start: 0.5rem; }
.is-android-old .flex.gap-2 > *:first-child { margin-inline-start: 0; }
.is-android-old .flex-col.gap-2 > * { margin-top: 0.5rem; margin-inline-start: 0; }
.is-android-old .flex-col.gap-2 > *:first-child { margin-top: 0; }

/* gap-3 (0.75rem) */
.is-android-old .flex.gap-3 > * { margin-inline-start: 0.75rem; }
.is-android-old .flex.gap-3 > *:first-child { margin-inline-start: 0; }
.is-android-old .flex-col.gap-3 > * { margin-top: 0.75rem; margin-inline-start: 0; }
.is-android-old .flex-col.gap-3 > *:first-child { margin-top: 0; }

/* gap-4 (1rem) */
.is-android-old .flex.gap-4 > * { margin-inline-start: 1rem; }
.is-android-old .flex.gap-4 > *:first-child { margin-inline-start: 0; }
.is-android-old .flex-col.gap-4 > * { margin-top: 1rem; margin-inline-start: 0; }
.is-android-old .flex-col.gap-4 > *:first-child { margin-top: 0; }

/* gap-5 (1.25rem) */
.is-android-old .flex.gap-5 > * { margin-inline-start: 1.25rem; }
.is-android-old .flex.gap-5 > *:first-child { margin-inline-start: 0; }
.is-android-old .flex-col.gap-5 > * { margin-top: 1.25rem; margin-inline-start: 0; }
.is-android-old .flex-col.gap-5 > *:first-child { margin-top: 0; }

/* gap-6 (1.5rem) */
.is-android-old .flex.gap-6 > * { margin-inline-start: 1.5rem; }
.is-android-old .flex.gap-6 > *:first-child { margin-inline-start: 0; }
.is-android-old .flex-col.gap-6 > * { margin-top: 1.5rem; margin-inline-start: 0; }
.is-android-old .flex-col.gap-6 > *:first-child { margin-top: 0; }

/* gap-8 (2rem) */
.is-android-old .flex.gap-8 > * { margin-inline-start: 2rem; }
.is-android-old .flex.gap-8 > *:first-child { margin-inline-start: 0; }
.is-android-old .flex-col.gap-8 > * { margin-top: 2rem; margin-inline-start: 0; }
.is-android-old .flex-col.gap-8 > *:first-child { margin-top: 0; }
```

### 4.5 Icon Rendering Fix

```css
/* Fix icon rendering on old Android */
.icon-android-fix {
  -webkit-transform: translateZ(0);
  transform: translateZ(0);
  shape-rendering: geometricPrecision;
}
```

---

## 5. BROWSER DETECTION (G-DP-4) - HIGH

### 5.1 index.html Script (Add to <head>)

```html
<script>
  (function() {
    var root = document.documentElement;
    var ua = navigator.userAgent;

    // Android detection
    if (/Android/i.test(ua)) {
      root.classList.add('is-android');

      // Chrome version detection (MORE ACCURATE than Android version)
      var chromeMatch = ua.match(/Chrome\/(\d+)/);
      var chromeVersion = chromeMatch ? parseInt(chromeMatch[1], 10) : 999;

      // Chrome < 84 doesn't support gap, modern CSS
      if (chromeVersion < 84) {
        root.classList.add('is-android-old');
      }

      // Chrome < 105 doesn't support container queries
      if (chromeVersion < 105) {
        root.classList.add('is-android-no-container-queries');
      }
    }

    // iOS detection
    if (/iPad|iPhone|iPod/.test(ua)) {
      root.classList.add('is-ios');
    }

    // In-app browser detection (CRITICAL for push notifications)
    if (/FBAN|FBAV|Instagram|Line|Twitter|Snapchat|TikTok/i.test(ua)) {
      root.classList.add('is-in-app-browser');
    }

    // WebView detection
    if (/wv|WebView/i.test(ua)) {
      root.classList.add('is-webview');
    }

    // Dark mode - system preference with localStorage override
    var savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
      root.classList.toggle('dark', savedTheme === 'dark');
    } else {
      var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      root.classList.toggle('dark', prefersDark);
    }
  })();
</script>
```

### 5.2 TypeScript Detection Utilities

```typescript
// lib/browserDetection.ts

/** Check if running in Instagram/Facebook/etc in-app browser */
export function isInAppBrowser(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent;
  return /FBAN|FBAV|Instagram|Line|Twitter|Snapchat|TikTok/i.test(ua);
}

/** Check if old Android with Chrome < 84 */
export function isOldAndroid(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent;
  if (!/Android/i.test(ua)) return false;

  const chromeMatch = ua.match(/Chrome\/(\d+)/);
  const chromeVersion = chromeMatch ? parseInt(chromeMatch[1], 10) : 999;
  return chromeVersion < 84;
}

/** Check if Android WebView (not Chrome browser) */
export function isAndroidWebView(): boolean {
  if (typeof navigator === "undefined") return false;
  const ua = navigator.userAgent;
  return /Android/i.test(ua) && /wv|WebView/i.test(ua);
}

/** Check if iOS device */
export function isIOS(): boolean {
  if (typeof navigator === "undefined") return false;
  return /iPad|iPhone|iPod/.test(navigator.userAgent);
}

/** Check if iOS Safari (not in-app or WebView) */
export function isIOSSafari(): boolean {
  if (!isIOS()) return false;
  const ua = navigator.userAgent;
  return /Safari/i.test(ua) && !/CriOS|FxiOS|OPiOS/i.test(ua);
}

/** Check if PWA is installed (standalone mode) */
export function isInstalledPWA(): boolean {
  if (typeof window === "undefined") return false;
  return (
    window.matchMedia("(display-mode: standalone)").matches ||
    (window.navigator as any).standalone === true
  );
}

/** Get Chrome version (returns 999 if not Chrome) */
export function getChromeVersion(): number {
  if (typeof navigator === "undefined") return 999;
  const match = navigator.userAgent.match(/Chrome\/(\d+)/);
  return match ? parseInt(match[1], 10) : 999;
}
```

---

## 6. POLYFILLS (G-DP-5) - HIGH

### 6.1 Polyfills File

```typescript
// lib/polyfills.ts
// CRITICAL: Load this FIRST in main.tsx

/**
 * IntersectionObserver polyfill for old Android
 * Required for: infinite scroll, lazy loading, viewport detection
 */
if (typeof window !== "undefined" && !("IntersectionObserver" in window)) {
  (window as any).IntersectionObserver = class IntersectionObserverPolyfill {
    private callback: IntersectionObserverCallback;
    private elements: Set<Element> = new Set();

    constructor(callback: IntersectionObserverCallback) {
      this.callback = callback;
    }

    observe(element: Element): void {
      this.elements.add(element);
      // Immediate callback - element is "visible"
      setTimeout(() => {
        const entry = {
          target: element,
          isIntersecting: true,
          intersectionRatio: 1,
          boundingClientRect: element.getBoundingClientRect(),
          intersectionRect: element.getBoundingClientRect(),
          rootBounds: null,
          time: performance.now(),
        } as IntersectionObserverEntry;
        this.callback([entry], this as any);
      }, 100);
    }

    unobserve(element: Element): void {
      this.elements.delete(element);
    }

    disconnect(): void {
      this.elements.clear();
    }

    takeRecords(): IntersectionObserverEntry[] {
      return [];
    }
  };
}

/**
 * ResizeObserver polyfill for old Android
 * Required for: responsive components, container size detection
 */
if (typeof window !== "undefined" && !("ResizeObserver" in window)) {
  (window as any).ResizeObserver = class ResizeObserverPolyfill {
    private callback: ResizeObserverCallback;
    private elements: Set<Element> = new Set();

    constructor(callback: ResizeObserverCallback) {
      this.callback = callback;
    }

    observe(element: Element): void {
      this.elements.add(element);
      // Initial callback with current size
      setTimeout(() => {
        const entry = {
          target: element,
          contentRect: element.getBoundingClientRect(),
          borderBoxSize: [{ inlineSize: element.clientWidth, blockSize: element.clientHeight }],
          contentBoxSize: [{ inlineSize: element.clientWidth, blockSize: element.clientHeight }],
          devicePixelContentBoxSize: [{ inlineSize: element.clientWidth, blockSize: element.clientHeight }],
        } as ResizeObserverEntry;
        this.callback([entry], this as any);
      }, 100);
    }

    unobserve(element: Element): void {
      this.elements.delete(element);
    }

    disconnect(): void {
      this.elements.clear();
    }
  };
}

export {};
```

### 6.2 main.tsx Integration

```typescript
// main.tsx
// CRITICAL: Polyfills MUST be first import
import "./lib/polyfills";

import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
```

---

## 7. SERVICE WORKER CACHE (G-DP-6) - HIGH

### 7.1 Selective Cache Cleanup (NOT Delete All)

```typescript
// sw.ts
const CACHE_VERSION = "v6"; // Bump on deployment

self.addEventListener("install", (event) => {
  event.waitUntil(
    Promise.all([
      self.skipWaiting(),

      // SELECTIVE cleanup - only delete OLD caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames
            // Keep caches that include current version
            .filter((name) => !name.includes(CACHE_VERSION))
            .map((cacheName) => {
              console.log(`[SW] Deleting old cache: ${cacheName}`);
              return caches.delete(cacheName);
            }),
        );
      }),
    ]),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    Promise.all([
      self.clients.claim(),
      // Clean up any remaining old caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => !name.includes(CACHE_VERSION))
            .map((cacheName) => caches.delete(cacheName)),
        );
      }),
    ]),
  );
});
```

### 7.2 Quota Error Handling

```typescript
// Handle storage quota exceeded
async function safeCachePut(
  cacheName: string,
  request: Request,
  response: Response,
): Promise<boolean> {
  try {
    const cache = await caches.open(cacheName);
    await cache.put(request, response);
    return true;
  } catch (error) {
    if (error instanceof DOMException && error.name === "QuotaExceededError") {
      console.warn("[SW] Storage quota exceeded, cleaning old entries");

      // Delete oldest entries
      const cache = await caches.open(cacheName);
      const keys = await cache.keys();
      const toDelete = keys.slice(0, Math.floor(keys.length / 2));
      await Promise.all(toDelete.map((key) => cache.delete(key)));

      // Retry
      try {
        await cache.put(request, response);
        return true;
      } catch {
        return false;
      }
    }
    throw error;
  }
}
```

---

## 8. iOS PARITY (G-DP-7) - MEDIUM

### 8.1 Viewport Height Fix

```css
/* index.css */
.full-height {
  height: 100vh;
  height: 100dvh; /* Dynamic viewport height - iOS Safari */
  height: -webkit-fill-available; /* Fallback */
}

/* For fixed bottom elements */
.safe-area-bottom {
  padding-bottom: env(safe-area-inset-bottom, 0px);
  padding-bottom: constant(safe-area-inset-bottom, 0px); /* iOS 11.0-11.2 */
}

.safe-area-top {
  padding-top: env(safe-area-inset-top, 0px);
  padding-top: constant(safe-area-inset-top, 0px);
}
```

### 8.2 Viewport Meta Tag

```html
<meta
  name="viewport"
  content="width=device-width, initial-scale=1, viewport-fit=cover, user-scalable=no, maximum-scale=1"
/>
```

### 8.3 Form Input Zoom Prevention

```css
/* iOS zooms on inputs with font-size < 16px */
input, select, textarea {
  font-size: 16px !important;
}

/* Or use transform for smaller text */
.small-input {
  font-size: 16px;
  transform: scale(0.875); /* Visually 14px */
  transform-origin: left center;
}
```

### 8.4 iOS Push Notification Requirements

```typescript
// iOS 16.4+ requires:
// 1. PWA must be INSTALLED (standalone mode)
// 2. User must grant permission via user gesture
// 3. Only works in standalone mode, NOT browser

export async function requestIOSPushPermission(): Promise<boolean> {
  // Check if iOS
  if (!/iPad|iPhone|iPod/.test(navigator.userAgent)) {
    return false;
  }

  // Check if installed as PWA
  const isStandalone =
    window.matchMedia("(display-mode: standalone)").matches ||
    (window.navigator as any).standalone === true;

  if (!isStandalone) {
    console.warn("[Push] iOS requires PWA installation for push notifications");
    // Show install prompt to user
    return false;
  }

  // Request permission (must be from user gesture)
  const permission = await Notification.requestPermission();
  return permission === "granted";
}
```

---

## 9. DARK MODE (G-DP-8) - MEDIUM

### 9.1 System Preference Detection

```html
<!-- index.html (in <head>) -->
<script>
  (function() {
    var root = document.documentElement;
    var savedTheme = localStorage.getItem('theme');

    if (savedTheme) {
      root.classList.toggle('dark', savedTheme === 'dark');
    } else {
      // Check system preference
      var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      root.classList.toggle('dark', prefersDark);
    }

    // Listen for system changes (real-time update)
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
      // Only apply if no manual override
      if (!localStorage.getItem('theme')) {
        root.classList.toggle('dark', e.matches);
      }
    });
  })();
</script>
```

### 9.2 Theme Toggle Hook

```typescript
// hooks/useTheme.ts
import { useEffect, useState } from "react";

type Theme = "light" | "dark" | "system";

export function useTheme() {
  const [theme, setTheme] = useState<Theme>(() => {
    if (typeof window === "undefined") return "system";
    return (localStorage.getItem("theme") as Theme) || "system";
  });

  useEffect(() => {
    const root = document.documentElement;

    if (theme === "system") {
      localStorage.removeItem("theme");
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      root.classList.toggle("dark", prefersDark);
    } else {
      localStorage.setItem("theme", theme);
      root.classList.toggle("dark", theme === "dark");
    }
  }, [theme]);

  return { theme, setTheme };
}
```

---

## 10. AUTOFILL STYLING (G-DP-9) - LOW

```css
/* index.css */

/* Fix WebKit autofill background color */
input:-webkit-autofill,
input:-webkit-autofill:hover,
input:-webkit-autofill:focus,
textarea:-webkit-autofill,
textarea:-webkit-autofill:hover,
textarea:-webkit-autofill:focus,
select:-webkit-autofill,
select:-webkit-autofill:hover,
select:-webkit-autofill:focus {
  -webkit-box-shadow: 0 0 0 1000px hsl(var(--card)) inset !important;
  -webkit-text-fill-color: hsl(var(--foreground)) !important;
  transition: background-color 5000s ease-in-out 0s;
  caret-color: hsl(var(--foreground));
}

/* Dark mode autofill */
.dark input:-webkit-autofill,
.dark input:-webkit-autofill:hover,
.dark input:-webkit-autofill:focus {
  -webkit-box-shadow: 0 0 0 1000px hsl(var(--card)) inset !important;
  -webkit-text-fill-color: hsl(var(--foreground)) !important;
}

/* Animation for detecting autofill */
@keyframes onAutoFillStart { from {} to {} }
@keyframes onAutoFillCancel { from {} to {} }

input:-webkit-autofill {
  animation-name: onAutoFillStart;
}

input:not(:-webkit-autofill) {
  animation-name: onAutoFillCancel;
}
```

---

## 11. GRADIENT OPTIMIZATION (G-DP-11) - HIGH

### 11.1 Problem

The naive approach of replacing ALL gradients with solid primary color causes:
- Logos appearing with orange background overlays
- Icons losing their visual styling
- Cards and surfaces becoming too bright

### 11.2 Intelligent Gradient CSS

```css
/* ===== ANDROID: INTELLIGENT GRADIENT OPTIMIZATION ===== */
/* Replace complex gradients with appropriate solid colors */
/* CRITICAL: Don't make everything orange - match the original intent! */

/* Subtle background gradients → transparent/solid card */
.is-android .bg-gradient-to-b.from-card,
.is-android .bg-gradient-to-r.from-card,
.is-android [class*="bg-gradient-to-"][class*="from-card"] {
  background-image: none !important;
  background-color: hsl(var(--card)) !important;
}

/* Subtle primary accent gradients → very light primary or transparent */
.is-android [class*="from-primary/5"],
.is-android [class*="from-primary\/5"] {
  background-image: none !important;
  background-color: hsl(var(--primary) / 0.05) !important;
}

/* Active nav item gradients → solid primary (these SHOULD be primary) */
.is-android .bg-gradient-to-r.from-primary.via-primary {
  background-image: none !important;
  background-color: hsl(var(--primary)) !important;
}

/* Success gradients → solid success */
.is-android [class*="gradient-success"],
.is-android .bg-gradient-to-r.from-success {
  background-image: none !important;
  background-color: hsl(var(--success)) !important;
}

/* Background surface gradients → solid background */
.is-android .bg-gradient-to-b.from-background {
  background-image: none !important;
  background-color: hsl(var(--background)) !important;
}

/* Muted gradients → solid muted */
.is-android .bg-gradient-to-r.from-muted {
  background-image: none !important;
  background-color: hsl(var(--muted)) !important;
}

/* Generic fallback - use TRANSPARENT (NOT orange!) */
/* This prevents orange overlay on logos and icons */
.is-android [class*="bg-gradient-to-"]:not([class*="from-primary"]):not([class*="from-success"]):not([class*="from-card"]):not([class*="from-background"]):not([class*="from-muted"]) {
  background-image: none !important;
  background-color: transparent !important;
}
```

### 11.3 Anti-Pattern

```css
/* ❌ BAD - Makes EVERYTHING orange */
.is-android [class*="bg-gradient"] {
  background-image: none !important;
  background-color: hsl(var(--primary)) !important;
}
```

---

## 12. SCROLL OPTIMIZATION (G-DP-12) - HIGH

### 12.1 The is-scrolling Pattern

Add/remove a class during scroll to disable expensive hover effects.

**index.html / main.tsx:**

```typescript
// main.tsx - Add after polyfills import
function setupScrollOptimization() {
  const isAndroid = /Android/i.test(navigator.userAgent);
  if (!isAndroid) return;

  let scrollTimeout: ReturnType<typeof setTimeout> | null = null;
  const root = document.documentElement;

  // Use passive event listener for better scroll performance
  window.addEventListener(
    "scroll",
    () => {
      // Add class immediately when scrolling starts
      if (!root.classList.contains("is-scrolling")) {
        root.classList.add("is-scrolling");
      }

      // Remove class 150ms after scroll stops
      if (scrollTimeout) {
        clearTimeout(scrollTimeout);
      }
      scrollTimeout = setTimeout(() => {
        root.classList.remove("is-scrolling");
      }, 150);
    },
    { passive: true },
  );
}

setupScrollOptimization();
```

**index.css:**

```css
/* Disable expensive hover effects during scroll */
.is-scrolling .card:hover,
.is-scrolling [class*="hover:"] {
  transform: none !important;
  box-shadow: inherit !important;
}

/* Android scroll performance */
.is-android {
  overscroll-behavior: contain;
}

.is-android .space-y-4,
.is-android [class*="overflow-y"] {
  isolation: isolate;
  will-change: scroll-position;
}

/* Old Android scroll - force GPU layer */
.is-android-old [class*="overflow-y-auto"],
.is-android-old [class*="overflow-y-scroll"] {
  transform: translateZ(0);
  backface-visibility: hidden;
}
```

---

## 13. TOUCH TARGETS (G-DP-13) - HIGH

### 13.1 Minimum 44x44px Touch Targets

All interactive elements must have at least 44x44px touch area (WCAG AAA).

**Pattern: Expanded hit area using pseudo-element:**

```tsx
// Checkbox with 44px touch target (visual size 20px)
<CheckboxPrimitive.Root
  className={cn(
    // Base layout with 44px touch target
    "relative grid place-content-center peer h-5 w-5 shrink-0",
    // Expanded touch target for mobile accessibility (44x44px minimum)
    "before:absolute before:inset-[-12px] before:content-['']",
    // ... rest of styling
  )}
/>
```

**Button size minimums:**

```tsx
// Close buttons - minimum 44px
className="min-w-11 min-h-11"  // ✅ GOOD (44px)
className="min-w-[2rem] min-h-[2rem]"  // ❌ BAD (32px)
```

**Touch target CSS utility:**

```css
/* Add to index.css */
.touch-target-44 {
  position: relative;
}
.touch-target-44::before {
  content: '';
  position: absolute;
  inset: -12px;  /* Expand 12px in all directions from center */
}
```

---

## 14. SPINNER ACCESSIBILITY (G-DP-14) - MEDIUM

### 14.1 All loading spinners must have accessibility attributes

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
```

**Pattern for reusable spinner:**

```tsx
// components/ui/spinner.tsx
export function Spinner({
  className,
  label = "טוען...",
}: {
  className?: string;
  label?: string;
}) {
  return (
    <div role="status" aria-label={label}>
      <Loader2
        className={cn("animate-spin", className)}
        aria-hidden="true"
      />
      <span className="sr-only">{label}</span>
    </div>
  );
}
```

---

## 15. TESTING CHECKLIST (G-DP-10) - CRITICAL

### 11.1 Required Test Scenarios

```markdown
### Real Device Testing
- [ ] Test on Android device with Chrome < 84 (Android 8-9)
- [ ] Test on iPhone (Safari)
- [ ] Test on iPad (Safari)

### In-App Browser Testing
- [ ] Open PWA link in Instagram app
- [ ] Open PWA link in Facebook app
- [ ] Verify push notification warning appears

### DevTools Simulation
- [ ] Chrome DevTools > Network > Throttle to Slow 3G
- [ ] Chrome DevTools > Performance > CPU 4x slowdown
- [ ] Chrome DevTools > Application > Service Workers > Offline

### Feature Testing
- [ ] Infinite scroll works (IntersectionObserver)
- [ ] Responsive components resize (ResizeObserver)
- [ ] Bulk operations complete (Promise.allSettled pattern)
- [ ] Animations are smooth (60fps, no jank)
- [ ] Gap spacing correct on old Android
- [ ] Dark mode follows system preference
- [ ] Autofill fields styled correctly
- [ ] Service worker updates properly

### iOS-Specific Testing
- [ ] 100vh elements don't overflow
- [ ] Bottom navigation respects safe area
- [ ] Form inputs don't zoom on focus
- [ ] Push notifications work (iOS 16.4+ standalone only)

### Performance Testing
- [ ] Lighthouse PWA score > 90
- [ ] Lighthouse Performance score > 90
- [ ] No layout shifts (CLS = 0)
- [ ] LCP < 1.5s on slow network
```

### 11.2 Quick Verification Command

```bash
# Run all checks
pnpm run lint && ppnpm run test:run && pnpm run build

# Check for problematic patterns
grep -r "Promise.allSettled" src/
grep -r "@container" src/
grep -r "transition-all\|transition-\[.*box-shadow" src/
grep -r "backdrop-blur" src/
```

---

## 12. QUICK FIX REFERENCE

| Problem | Quick Fix |
|---------|-----------|
| JS doesn't work on old Android | Set `target: "es2018"` in vite.config.ts |
| Layout broken on old Android | Remove `@container` queries, use `md:` |
| Scroll jank on old Android | Remove `box-shadow` from transitions |
| **Elements disappear during scroll** | **Disable `contain-content` via CSS override for Android** |
| Gap not working | Add `.is-android-old` fallback CSS |
| Blur not showing | Use solid background instead of `backdrop-blur` |
| Push doesn't work in Instagram | Detect in-app browser, show warning |
| Service worker re-downloads everything | Use selective cache cleanup |
| iOS bottom cut off | Add `safe-area-inset-bottom` padding |
| Input zooms on iOS | Set `font-size: 16px` on inputs |
| Dark mode ignores system | Add `matchMedia` listener |
| **Logos have orange overlay** | **Use intelligent gradient CSS (not all orange)** |
| **Scroll jank on hover** | **Add `is-scrolling` class pattern** |
| **Touch targets too small** | **Use `before:inset-[-12px]` for 44px hit area** |
| **Spinners not accessible** | **Add `role="status"` + `aria-label`** |

---

## 17. RELATED SKILLS

- `pwa-master-checklist.md` - Complete 120+ item checklist
- `pwa-android-compatibility.md` - Android WebView details
- `service-worker-patterns.md` - SW implementation patterns
- `pwa-ios-limitations.md` - iOS Safari workarounds
- `pwa-push-troubleshooting.md` - Push notification debugging

---

## X. VERIFICATION SEAL

```
OMEGA_v24.5.0 | PWA_DEVICE_PARITY_CHECKLIST
Gates: 14 | Critical: 5 | High: 6 | Medium: 3 | Low: 1
TARGET: ES2018 | NO_CONTAINER_QUERIES | NO_BOX_SHADOW_TRANSITION
NO_CONTAIN_CONTENT | INTELLIGENT_GRADIENTS | TOUCH_44PX | SPINNER_A11Y
IPHONE ↔ OLD_ANDROID: PARITY_ENFORCED
```

---

*Last updated: 2026-01-30 | Addresses all gaps from production PWA fixes*

<!-- PWA-EXPERT/DEVICE-PARITY v24.5.0 | Updated: 2026-02-19 -->
</head>
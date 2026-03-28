# PWA Supreme Expert Skill v24.5.0

> **Inherits from SINGULARITY FORGE v24.5.0**
> **Aligned with CLAUDE.md v24.5.0**
> **Status:** Production-ready | **Library:** Serwist (NOT next-pwa)
> **Gates:** G-PWA-1 to G-PWA-22 + G-ARF-1 to G-ARF-8 (30 Verification Gates)

---

## Table of Contents

1. [Manifest Configuration](#1-manifest-configuration)
2. [Service Worker Patterns](#2-service-worker-patterns)
3. [Background Sync & Push](#3-background-sync--push-notifications)
4. [Offline-First Architecture](#4-offline-first-architecture)
5. [Performance Optimization](#5-performance-optimization)
6. [Install Experience](#6-install-experience)
7. [Cross-Platform UI](#7-cross-platform-ui)
8. [Security](#8-security)
9. [Cutting-Edge APIs](#9-cutting-edge-apis)
10. [Testing Checklist](#10-testing-checklist)
11. [Old Android Compatibility](#11-old-android-compatibility)
12. [Storage Quota Management](#12-storage-quota-management)
13. [Tree Shaking & Bundle Optimization](#13-tree-shaking--bundle-optimization)
14. [Content Indexing API](#14-content-indexing-api)
15. [Badge API](#15-badge-api)
16. [Periodic Background Sync](#16-periodic-background-sync)
17. [Advanced Manifest APIs](#17-advanced-manifest-apis)
18. [Reflexion Loop Integration](#18-reflexion-loop-integration)
19. [Memory MCP Integration](#19-memory-mcp-integration)
20. [Context7 Protocol](#20-context7-protocol)
21. [30-Gate Verification](#21-30-gate-verification)
22. [RTL-First Compliance](#22-rtl-first-compliance-law-5)
23. [Responsive Compliance](#23-responsive-compliance-law-6)
24. [INP Optimization](#24-inp-optimization)
25. [Field vs Lab Data](#25-field-vs-lab-data)
26. [Modern APIs (2025-2026)](#26-modern-apis-2025-2026)
27. [9-Dimension Alignment](#27-9-dimension-alignment)
28. [Haptic Feedback](#28-haptic-feedback)
29. [NVIDIA-Level Optimizations](#29-nvidia-level-optimizations-35-total)
30. [Android Rendering Fixes](#30-android-rendering-fixes-8-critical-issues)

---

## 1. MANIFEST CONFIGURATION

### 1.1 Complete Manifest (Next.js)

```typescript
// app/manifest.ts
import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    // Required fields
    name: 'My Progressive Web App',
    short_name: 'MyPWA',
    start_url: '/',
    scope: '/',
    display: 'standalone',

    // Visual
    theme_color: '#3b82f6',
    background_color: '#ffffff',
    orientation: 'portrait-primary',

    // RTL Support (Hebrew/Arabic)
    dir: 'rtl',
    lang: 'he',

    // Description
    description: 'App description for install prompt',

    // Display override (modern)
    display_override: ['window-controls-overlay', 'standalone', 'minimal-ui'],

    // Icons (CRITICAL)
    icons: [
      { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
      { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
      { src: '/icons/icon-maskable-192.png', sizes: '192x192', type: 'image/png', purpose: 'maskable' },
      { src: '/icons/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],

    // Screenshots for richer install UI
    screenshots: [
      {
        src: '/screenshots/mobile.png',
        sizes: '750x1334',
        type: 'image/png',
        form_factor: 'narrow',
        label: 'Home screen',
      },
      {
        src: '/screenshots/desktop.png',
        sizes: '1280x720',
        type: 'image/png',
        form_factor: 'wide',
        label: 'Dashboard',
      },
    ],

    // Shortcuts (Android home screen)
    shortcuts: [
      {
        name: 'New Item',
        short_name: 'New',
        url: '/new',
        icons: [{ src: '/icons/shortcut-new-96.png', sizes: '96x96' }],
      },
    ],

    // Share Target API
    share_target: {
      action: '/share',
      method: 'POST',
      enctype: 'multipart/form-data',
      params: {
        title: 'title',
        text: 'text',
        url: 'url',
      },
    },

    // Handle links (Chrome 121+)
    handle_links: 'preferred',

    // Launch handler (Chrome 110+)
    launch_handler: {
      client_mode: ['focus-existing', 'auto'],
    },

    // Related applications
    related_applications: [],
    prefer_related_applications: false,
  };
}
```

### 1.2 HTML Head Configuration

```tsx
// app/layout.tsx
import type { Metadata, Viewport } from 'next';

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover', // CRITICAL for safe areas
};

export const metadata: Metadata = {
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'MyPWA',
  },
  formatDetection: {
    telephone: false,
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // PWA-19: Add class="dark" to prevent dark mode flash (FOUC)
    // See pwa-edge-cases.md for full theme persistence solution
    <html lang="he" dir="rtl" className="dark">
      <head>
        {/* Apple Touch Icons */}
        <link rel="apple-touch-icon" href="/icons/apple-touch-icon-180.png" />
        <link rel="apple-touch-icon" sizes="152x152" href="/icons/apple-touch-icon-152.png" />
        <link rel="apple-touch-icon" sizes="167x167" href="/icons/apple-touch-icon-167.png" />
        <link rel="apple-touch-icon" sizes="180x180" href="/icons/apple-touch-icon-180.png" />

        {/* iOS Splash Screens */}
        <link
          rel="apple-touch-startup-image"
          href="/splash/apple-splash-1290-2796.png"
          media="(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3)"
        />
        <link
          rel="apple-touch-startup-image"
          href="/splash/apple-splash-1179-2556.png"
          media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3)"
        />
        <link
          rel="apple-touch-startup-image"
          href="/splash/apple-splash-1170-2532.png"
          media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3)"
        />
        <link
          rel="apple-touch-startup-image"
          href="/splash/apple-splash-750-1334.png"
          media="(device-width: 375px) and (device-height: 667px) and (-webkit-device-pixel-ratio: 2)"
        />
        {/* Add more sizes as needed - use pwa-asset-generator */}
      </head>
      <body>{children}</body>
    </html>
  );
}
```

### 1.3 Vite PWA Configuration (React/Vite)

```typescript
// vite.config.ts
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    VitePWA({
      registerType: 'prompt', // or 'autoUpdate'
      includeAssets: ['favicon.ico', 'robots.txt', 'icons/*.png'],
      manifest: {
        name: 'My PWA',
        short_name: 'MyPWA',
        start_url: '/',
        display: 'standalone',
        theme_color: '#3b82f6',
        background_color: '#ffffff',
        dir: 'rtl',
        lang: 'he',
        icons: [
          { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: '/icons/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/api\./,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'api-cache',
              networkTimeoutSeconds: 5,
              expiration: { maxEntries: 50, maxAgeSeconds: 86400 },
            },
          },
        ],
      },
    }),
  ],
});
```

### 1.4 Icon Requirements Matrix

| Size | Purpose | Required | File |
|------|---------|----------|------|
| 192x192 | Install prompt | **MANDATORY** | icon-192.png |
| 512x512 | Splash screen | **MANDATORY** | icon-512.png |
| 192x192 | Maskable (Android adaptive) | **MANDATORY** | icon-maskable-192.png |
| 512x512 | Maskable | **MANDATORY** | icon-maskable-512.png |
| 180x180 | Apple Touch Icon | Recommended | apple-touch-icon-180.png |
| 96x96 | Shortcuts | Optional | shortcut-*.png |

**Maskable Safe Zone:** Content must fit within center 80% (10% padding each side)

```bash
# Generate all icons
npx pwa-asset-generator logo.svg ./public/icons \
  --background "#3b82f6" \
  --maskable true \
  --padding "10%"

# Generate splash screens
npx pwa-asset-generator logo.svg ./public/splash \
  --splash-only \
  --background "#ffffff"
```

---

## 2. SERVICE WORKER PATTERNS

### 2.1 Caching Strategies Matrix

| Resource | Strategy | TTL | Max Entries | Timeout |
|----------|----------|-----|-------------|---------|
| HTML/Pages | StaleWhileRevalidate | 1 day | 50 | - |
| JS/CSS | CacheFirst | 1 year | 100 | - |
| Images | CacheFirst | 30 days | 200 | - |
| Fonts | CacheFirst | 1 year | 30 | - |
| API (read) | NetworkFirst | 1 day | 300 | 5s |
| API (write) | NetworkOnly + BackgroundSync | - | - | - |
| Third-party | StaleWhileRevalidate | 7 days | 50 | - |

### 2.2 Complete Serwist Configuration (Next.js)

```typescript
// src/sw.ts
import { defaultCache } from "@serwist/next/worker";
import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import {
  Serwist,
  CacheFirst,
  NetworkFirst,
  StaleWhileRevalidate,
  NetworkOnly,
  ExpirationPlugin,
  CacheableResponsePlugin,
  BackgroundSyncPlugin,
} from "serwist";

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}

declare const self: ServiceWorkerGlobalScope;

// Version for cache busting
const SW_VERSION = '1.0.0';

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: true,
  clientsClaim: true,
  navigationPreload: true,

  runtimeCaching: [
    // Static assets - Cache First (immutable)
    {
      urlPattern: /\.(?:js|css|woff2?)$/i,
      handler: new CacheFirst({
        cacheName: `static-assets-${SW_VERSION}`,
        plugins: [
          new ExpirationPlugin({
            maxEntries: 100,
            maxAgeSeconds: 365 * 24 * 60 * 60, // 1 year
          }),
        ],
      }),
    },

    // Images - Cache First with size limit
    {
      urlPattern: /\.(?:png|jpg|jpeg|webp|avif|gif|svg|ico)$/i,
      handler: new CacheFirst({
        cacheName: `images-${SW_VERSION}`,
        plugins: [
          new ExpirationPlugin({
            maxEntries: 200,
            maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
            purgeOnQuotaError: true,
          }),
        ],
      }),
    },

    // Google Fonts
    {
      urlPattern: /^https:\/\/fonts\.(?:gstatic|googleapis)\.com\/.*/i,
      handler: new CacheFirst({
        cacheName: 'google-fonts',
        plugins: [
          new ExpirationPlugin({
            maxEntries: 30,
            maxAgeSeconds: 365 * 24 * 60 * 60,
          }),
        ],
      }),
    },

    // API GET requests - Network First
    {
      urlPattern: /\/api\/.*$/,
      method: 'GET',
      handler: new NetworkFirst({
        cacheName: `api-cache-${SW_VERSION}`,
        networkTimeoutSeconds: 5,
        plugins: [
          new ExpirationPlugin({
            maxEntries: 300,
            maxAgeSeconds: 24 * 60 * 60, // 1 day
          }),
          new CacheableResponsePlugin({
            statuses: [0, 200],
          }),
        ],
      }),
    },

    // API mutations - Network Only with Background Sync
    {
      urlPattern: /\/api\/.*$/,
      method: 'POST',
      handler: new NetworkOnly({
        plugins: [
          new BackgroundSyncPlugin('api-mutations', {
            maxRetentionTime: 24 * 60, // 24 hours
          }),
        ],
      }),
    },

    // Pages - Stale While Revalidate
    {
      urlPattern: ({ request }) => request.mode === 'navigate',
      handler: new StaleWhileRevalidate({
        cacheName: `pages-${SW_VERSION}`,
        plugins: [
          new CacheableResponsePlugin({
            statuses: [0, 200],
          }),
          new ExpirationPlugin({
            maxEntries: 50,
            maxAgeSeconds: 24 * 60 * 60, // 1 day
          }),
        ],
      }),
    },
  ],

  // Offline fallback
  fallbacks: {
    entries: [
      {
        url: '/offline',
        matcher({ request }) {
          return request.destination === 'document';
        },
      },
    ],
  },
});

// Handle SKIP_WAITING message
self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Claim clients on activate
self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
});

serwist.addEventListeners();
```

### 2.3 Update Strategies

#### Aggressive Auto-Update (Recommended for Production)

```typescript
// lib/pwa/swUpdateChecks.ts
export function startServiceWorkerUpdateChecks(options?: {
  intervalMs?: number;
}) {
  if (!('serviceWorker' in navigator)) return () => {};

  const intervalMs = options?.intervalMs ?? 2 * 60 * 1000; // 2 minutes
  let stopped = false;

  const updateOnce = async () => {
    if (stopped) return;
    try {
      const reg = await navigator.serviceWorker.getRegistration('/');
      if (reg) await reg.update();
    } catch {
      // Silent fail - best effort
    }
  };

  // Multiple triggers for fastest detection
  window.addEventListener('focus', updateOnce);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') updateOnce();
  });
  window.addEventListener('online', updateOnce);

  const id = setInterval(updateOnce, intervalMs);
  updateOnce(); // Check on boot

  return () => {
    stopped = true;
    window.removeEventListener('focus', updateOnce);
    clearInterval(id);
  };
}

/**
 * CRITICAL: Double Reload Prevention (PWA-18)
 *
 * During SW updates, BOTH of these can fire and trigger reload:
 * 1. SW_UPDATED message from service worker
 * 2. controllerchange event
 *
 * This can cause unexpected double-reloads! Always use a guard.
 */
let isReloading = false; // Global guard to prevent double reloads

// Safe reload function that prevents multiple reloads
function safeReload(reason: string): void {
  if (isReloading) {
    console.log('Reload already in progress, skipping', { reason });
    return;
  }
  isReloading = true;
  console.log('Reloading page', { reason });
  window.location.reload();
}

// Auto-reload on controller change with double-reload protection
export function setupControllerChangeListener(): () => void {
  if (!('serviceWorker' in navigator)) return () => {};

  // Handle SW_UPDATED message
  const handleMessage = (event: MessageEvent) => {
    if (event.data?.type === 'SW_UPDATED') {
      safeReload('SW_UPDATED message received');
    }
  };

  // Handle controller change (new SW activated)
  const handleControllerChange = () => {
    safeReload('controllerchange event');
  };

  navigator.serviceWorker.addEventListener('message', handleMessage);
  navigator.serviceWorker.addEventListener('controllerchange', handleControllerChange);

  return () => {
    navigator.serviceWorker.removeEventListener('message', handleMessage);
    navigator.serviceWorker.removeEventListener('controllerchange', handleControllerChange);
  };
}

// Force activate waiting SW
export async function forceActivateWaitingSW(): Promise<boolean> {
  try {
    const reg = await navigator.serviceWorker.getRegistration('/');
    if (reg?.waiting) {
      reg.waiting.postMessage({ type: 'SKIP_WAITING' });
      return true;
    }
    return false;
  } catch {
    return false;
  }
}
```

#### Soft Update (User Prompt)

```tsx
// components/UpdatePrompt.tsx
'use client';

import { useEffect, useState } from 'react';
import { setupControllerChangeListener } from '@/lib/pwa/swUpdateChecks';

export function UpdatePrompt() {
  const [showUpdate, setShowUpdate] = useState(false);
  const [registration, setRegistration] = useState<ServiceWorkerRegistration | null>(null);

  useEffect(() => {
    const cleanup = setupControllerChangeListener();

    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready.then((reg) => {
        reg.addEventListener('updatefound', () => {
          const newWorker = reg.installing;
          if (!newWorker) return;

          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              setShowUpdate(true);
              setRegistration(reg);
            }
          });
        });
      });
    }

    return cleanup;
  }, []);

  const handleUpdate = () => {
    if (registration?.waiting) {
      registration.waiting.postMessage({ type: 'SKIP_WAITING' });
    }
  };

  if (!showUpdate) return null;

  return (
    <div className="fixed bottom-4 inset-s-4 inset-e-4 bg-blue-600 text-white p-4 rounded-lg shadow-lg flex items-center justify-between z-50">
      <span>עדכון זמין</span>
      <button
        onClick={handleUpdate}
        className="px-4 py-2 bg-white text-blue-600 rounded min-h-11 font-medium"
      >
        עדכן עכשיו
      </button>
    </div>
  );
}
```

#### Background Auto-Update (After 30s in Background)

```typescript
// hooks/usePwaUpdater.ts
import { useEffect, useRef, useState } from 'react';
import { forceActivateWaitingSW } from '@/lib/pwa/swUpdateChecks';

const AUTO_UPDATE_DELAY_MS = 30 * 1000; // 30 seconds

export function usePwaUpdater() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const timerRef = useRef<NodeJS.Timeout>();

  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'hidden' && updateAvailable) {
        // Schedule auto-update when in background
        timerRef.current = setTimeout(async () => {
          if (document.visibilityState === 'hidden') {
            await forceActivateWaitingSW();
          }
        }, AUTO_UPDATE_DELAY_MS);
      } else {
        // Cancel if user comes back
        clearTimeout(timerRef.current);
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      clearTimeout(timerRef.current);
    };
  }, [updateAvailable]);

  return { updateAvailable, setUpdateAvailable };
}
```

### 2.4 iOS Service Worker Health Check (PWA-22)

> **Gate PWA-22:** iOS Safari kills Service Workers after ~3 days of app inactivity. Monitor and recover.

**Service Worker Side:**

```typescript
// sw.ts - Add to your service worker

// PWA-22: Respond to health check pings from main app
self.addEventListener('message', (event) => {
  if (event.data?.type === 'SW_PING' && event.ports[0]) {
    event.ports[0].postMessage({
      type: 'SW_PONG',
      timestamp: Date.now(),
      version: self.__WB_MANIFEST ? 'workbox' : 'custom',
    });
  }
});
```

**Main App Side:**

```typescript
// lib/pwa/swHealthCheck.ts

interface HealthCheckResult {
  isHealthy: boolean;
  responseTime?: number;
  error?: string;
}

const SW_PING_TIMEOUT = 3000;

/**
 * PWA-22: Ping the Service Worker to check if it's alive
 * iOS Safari kills SW after ~3 days of inactivity.
 */
export async function pingServiceWorker(): Promise<HealthCheckResult> {
  if (!('serviceWorker' in navigator)) {
    return { isHealthy: false, error: 'Service Worker not supported' };
  }

  try {
    const registration = await navigator.serviceWorker.ready;

    if (!registration.active) {
      return { isHealthy: false, error: 'No active Service Worker' };
    }

    const startTime = Date.now();

    return new Promise<HealthCheckResult>((resolve) => {
      const channel = new MessageChannel();

      const timeout = setTimeout(() => {
        resolve({ isHealthy: false, error: 'Service Worker unresponsive (timeout)' });
      }, SW_PING_TIMEOUT);

      channel.port1.onmessage = (event) => {
        clearTimeout(timeout);
        const responseTime = Date.now() - startTime;

        if (event.data?.type === 'SW_PONG') {
          resolve({ isHealthy: true, responseTime });
        } else {
          resolve({ isHealthy: false, error: 'Invalid SW response' });
        }
      };

      registration.active.postMessage({ type: 'SW_PING' }, [channel.port2]);
    });
  } catch (error) {
    return {
      isHealthy: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Attempt to recover a dead Service Worker
 */
export async function recoverServiceWorker(): Promise<boolean> {
  if (!('serviceWorker' in navigator)) return false;

  try {
    const registrations = await navigator.serviceWorker.getRegistrations();
    for (const reg of registrations) {
      await reg.unregister();
    }

    await navigator.serviceWorker.register('/sw.js');
    await navigator.serviceWorker.ready;

    console.log('[PWA-22] Service Worker recovered');
    return true;
  } catch (error) {
    console.error('[PWA-22] Failed to recover Service Worker:', error);
    return false;
  }
}
```

**React Hook:**

```typescript
// hooks/useServiceWorkerHealth.ts
import { useEffect, useRef } from 'react';
import { pingServiceWorker, recoverServiceWorker } from '@/lib/pwa/swHealthCheck';

const HEALTH_CHECK_INTERVAL = 60 * 60 * 1000; // 1 hour

export function useServiceWorkerHealth() {
  const lastCheckRef = useRef<number>(0);

  useEffect(() => {
    // React Compiler auto-memoizes — no manual useCallback needed
    const runHealthCheck = async () => {
      const now = Date.now();
      if (now - lastCheckRef.current < HEALTH_CHECK_INTERVAL) return;
      lastCheckRef.current = now;

      const result = await pingServiceWorker();

      if (!result.isHealthy) {
        console.warn('[PWA-22] Service Worker unhealthy:', result.error);
        const recovered = await recoverServiceWorker();
        if (!recovered) {
          console.error('[PWA-22] Service Worker could not be recovered');
        }
      }
    };

    runHealthCheck();
    const intervalId = setInterval(runHealthCheck, HEALTH_CHECK_INTERVAL);

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') runHealthCheck();
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('focus', runHealthCheck);

    return () => {
      clearInterval(intervalId);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', runHealthCheck);
    };
  }, []);
}
```

---

## 3. BACKGROUND SYNC & PUSH NOTIFICATIONS

### 3.1 Background Sync Queue

```typescript
// lib/offlineQueue.ts
import { openDB, DBSchema } from 'idb';

interface QueuedRequest {
  id: string;
  url: string;
  method: string;
  headers: Record<string, string>;
  body: string | null;
  timestamp: number;
  retries: number;
}

interface QueueDB extends DBSchema {
  requests: {
    key: string;
    value: QueuedRequest;
    indexes: { 'by-timestamp': number };
  };
}

const DB_NAME = 'offline-queue';
const MAX_RETRIES = 3;

async function getDB() {
  return openDB<QueueDB>(DB_NAME, 1, {
    upgrade(db) {
      const store = db.createObjectStore('requests', { keyPath: 'id' });
      store.createIndex('by-timestamp', 'timestamp');
    },
  });
}

export async function queueRequest(url: string, options: RequestInit): Promise<void> {
  const db = await getDB();

  const request: QueuedRequest = {
    id: crypto.randomUUID(),
    url,
    method: options.method || 'GET',
    headers: Object.fromEntries(new Headers(options.headers).entries()),
    body: typeof options.body === 'string' ? options.body : null,
    timestamp: Date.now(),
    retries: 0,
  };

  await db.add('requests', request);

  // Register background sync if available
  if ('serviceWorker' in navigator && 'sync' in ServiceWorkerRegistration.prototype) {
    const reg = await navigator.serviceWorker.ready;
    await (reg as any).sync.register('sync-requests');
  }
}

export async function processQueue(): Promise<{ success: number; failed: number }> {
  const db = await getDB();
  const requests = await db.getAllFromIndex('requests', 'by-timestamp');
  let success = 0;
  let failed = 0;

  for (const request of requests) {
    try {
      const response = await fetch(request.url, {
        method: request.method,
        headers: request.headers,
        body: request.body,
      });

      if (response.ok) {
        await db.delete('requests', request.id);
        success++;
      } else if (request.retries < MAX_RETRIES) {
        await db.put('requests', { ...request, retries: request.retries + 1 });
      } else {
        await db.delete('requests', request.id);
        failed++;
      }
    } catch {
      if (request.retries < MAX_RETRIES) {
        await db.put('requests', { ...request, retries: request.retries + 1 });
      } else {
        failed++;
      }
    }
  }

  return { success, failed };
}

export async function getQueueSize(): Promise<number> {
  const db = await getDB();
  return db.count('requests');
}
```

### 3.2 Push Notifications

```typescript
// lib/pushNotifications.ts
const VAPID_PUBLIC_KEY = process.env.NEXT_PUBLIC_VAPID_KEY!;

export async function subscribeToPush(): Promise<PushSubscription | null> {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
    console.warn('Push notifications not supported');
    return null;
  }

  // Request permission
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') {
    console.warn('Push permission denied');
    return null;
  }

  const registration = await navigator.serviceWorker.ready;

  // Check existing subscription
  let subscription = await registration.pushManager.getSubscription();

  if (!subscription) {
    subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
    });

    // Send to server
    await fetch('/api/push/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(subscription),
    });
  }

  return subscription;
}

export async function unsubscribeFromPush(): Promise<boolean> {
  const registration = await navigator.serviceWorker.ready;
  const subscription = await registration.pushManager.getSubscription();

  if (subscription) {
    await subscription.unsubscribe();
    await fetch('/api/push/unsubscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ endpoint: subscription.endpoint }),
    });
    return true;
  }

  return false;
}

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const rawData = window.atob(base64);
  return Uint8Array.from([...rawData].map((char) => char.charCodeAt(0)));
}
```

### 3.3 Push Handler in Service Worker

```typescript
// Add to src/sw.ts
self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};

  const options: NotificationOptions = {
    body: data.body,
    icon: '/icons/icon-192.png',
    badge: '/icons/badge-72.png',
    tag: data.tag || 'default',
    data: { url: data.url || '/' },
    actions: data.actions,
    vibrate: [100, 50, 100],
    requireInteraction: data.requireInteraction ?? false,
    dir: 'rtl', // RTL support
    lang: 'he',
  };

  event.waitUntil(
    self.registration.showNotification(data.title || 'Notification', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const url = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url === url && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(url);
    })
  );
});
```

### 3.4 Android 13+ Notification Permission

```typescript
// hooks/useNotificationPermission.ts
export function useNotificationPermission() {
  const [permission, setPermission] = useState<NotificationPermission>('default');

  useEffect(() => {
    if ('Notification' in window) {
      setPermission(Notification.permission);
    }
  }, []);

  const requestPermission = async () => {
    if (!('Notification' in window)) return 'denied';

    // Android 13+ requires explicit permission request
    const result = await Notification.requestPermission();
    setPermission(result);
    return result;
  };

  return { permission, requestPermission };
}
```

---

## 4. OFFLINE-FIRST ARCHITECTURE

### 4.1 Data Layer Stack

```
React Query (memory cache)
        |
        v
localStorage (persist basic state)
        |
        v
IndexedDB (structured data, large storage)
        |
        v
OPFS (Origin Private File System - large files)
        |
        v
Supabase/Server (source of truth)
```

### 4.2 Sync Engine Pattern

```typescript
// lib/syncEngine.ts
import { openDB } from 'idb';

interface SyncableEntity {
  id: string;
  updatedAt: string;
  syncStatus: 'synced' | 'pending' | 'conflict';
  localVersion: number;
  serverVersion?: number;
}

// Optimistic update with conflict detection
export async function optimisticUpdate<T extends SyncableEntity>(
  entity: T,
  updateFn: (entity: T) => T,
  syncFn: (entity: T) => Promise<T>
): Promise<{ success: boolean; data: T; conflict?: T }> {
  // 1. Apply local update immediately
  const updated = updateFn({
    ...entity,
    syncStatus: 'pending',
    localVersion: entity.localVersion + 1,
    updatedAt: new Date().toISOString(),
  });

  // 2. Save to IndexedDB
  await saveToLocal(updated);

  // 3. Try to sync
  try {
    const serverResult = await syncFn(updated);

    // Check for conflict
    if (serverResult.serverVersion && serverResult.serverVersion > entity.serverVersion!) {
      return {
        success: false,
        data: updated,
        conflict: serverResult,
      };
    }

    // Success - update with server response
    const synced = {
      ...serverResult,
      syncStatus: 'synced' as const,
      serverVersion: serverResult.serverVersion,
    };
    await saveToLocal(synced);

    return { success: true, data: synced };
  } catch (error) {
    // Offline - keep pending status
    return { success: false, data: updated };
  }
}

// Conflict resolution strategies
export const conflictStrategies = {
  // Last Write Wins
  lastWriteWins: <T extends SyncableEntity>(local: T, server: T): T => {
    return new Date(local.updatedAt) > new Date(server.updatedAt) ? local : server;
  },

  // Server Wins
  serverWins: <T extends SyncableEntity>(_local: T, server: T): T => server,

  // Client Wins
  clientWins: <T extends SyncableEntity>(local: T, _server: T): T => local,

  // Field-level merge
  fieldMerge: <T extends SyncableEntity>(local: T, server: T): T => {
    // Merge non-conflicting fields, prefer newer for conflicts
    return { ...server, ...local, serverVersion: server.serverVersion };
  },
};
```

### 4.3 Online Status Hook (CRITICAL: Real Connectivity Check) - PWA-17

> **⚠️ WARNING (PWA-17):** `navigator.onLine` is UNRELIABLE! It can return `true` even when there's no real internet connectivity (WiFi connected but no internet, captive portal, etc.), or `false` when cellular data actually works. **ALWAYS verify with an actual fetch request!**

```typescript
// hooks/useOnlineStatus.ts
import { useState, useEffect, useRef } from 'react';

const CONNECTIVITY_CHECK_INTERVAL = 10000; // 10 seconds

/**
 * CRITICAL: Actually verify connectivity with a fetch request
 * Don't trust navigator.onLine - it can be stale or wrong!
 */
async function checkRealConnectivity(): Promise<boolean> {
  if (typeof window === 'undefined') return true;

  try {
    // CRITICAL: Don't return early based on navigator.onLine!
    // It can be wrong - always do the actual fetch.

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    const response = await fetch(`/logo.svg?_=${Date.now()}`, {
      method: 'HEAD',
      cache: 'no-store',
      mode: 'same-origin',
      signal: controller.signal,
    });

    clearTimeout(timeoutId);
    return response.ok;
  } catch {
    return false;
  }
}

export function useOnlineStatus() {
  const [isOnline, setIsOnline] = useState(true);
  const verifyingRef = useRef(false);

  // React Compiler auto-memoizes — no manual useCallback needed
  const verifyConnectivity = async () => {
    if (verifyingRef.current) return;
    verifyingRef.current = true;

    try {
      const reallyOnline = await checkRealConnectivity();
      const browserOnline = typeof navigator !== 'undefined' ? navigator.onLine : true;

      // CORRECT the browser's potentially stale state
      if (!browserOnline && reallyOnline) {
        // Browser says offline but we have real connectivity
        setIsOnline(true);
      } else if (browserOnline && !reallyOnline) {
        // Browser says online but no real connectivity
        setIsOnline(false);
      } else {
        setIsOnline(browserOnline);
      }
    } finally {
      verifyingRef.current = false;
    }
  };

  useEffect(() => {
    // Verify on mount
    verifyConnectivity();

    // Verify periodically (every 10 seconds)
    const intervalId = setInterval(verifyConnectivity, CONNECTIVITY_CHECK_INTERVAL);

    // Also verify on browser events (but don't trust them alone)
    const handleOnline = () => verifyConnectivity();
    const handleOffline = () => verifyConnectivity();

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      clearInterval(intervalId);
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [verifyConnectivity]);

  return isOnline;
}

// Export for use in offline.html and other places
export { checkRealConnectivity };
```

### 4.3.1 Offline Page with Real Connectivity Check

```html
<!-- public/offline.html -->
<script>
  // DON'T just show "no internet" - verify first!
  async function checkRealConnectivity() {
    try {
      const response = await fetch('/logo.svg?_=' + Date.now(), {
        method: 'HEAD',
        cache: 'no-store'
      });
      return response.ok;
    } catch {
      return false;
    }
  }

  // Check immediately and redirect if we actually have connectivity
  checkRealConnectivity().then(isOnline => {
    if (isOnline) {
      window.location.reload();
    }
  });

  // Also check periodically
  setInterval(async () => {
    const isOnline = await checkRealConnectivity();
    if (isOnline) {
      window.location.reload();
    }
  }, 10000);
</script>
```

### 4.4 Queue Overflow Protection

```typescript
// lib/queueManager.ts
const MAX_QUEUE_SIZE = 1000;
const MAX_QUEUE_AGE_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

export async function cleanupQueue(): Promise<void> {
  const db = await getDB();
  const requests = await db.getAll('requests');

  // Remove old requests
  const cutoff = Date.now() - MAX_QUEUE_AGE_MS;
  for (const req of requests) {
    if (req.timestamp < cutoff) {
      await db.delete('requests', req.id);
    }
  }

  // Trim if over size limit
  const remaining = await db.getAll('requests');
  if (remaining.length > MAX_QUEUE_SIZE) {
    const toRemove = remaining
      .sort((a, b) => a.timestamp - b.timestamp)
      .slice(0, remaining.length - MAX_QUEUE_SIZE);

    for (const req of toRemove) {
      await db.delete('requests', req.id);
    }
  }
}
```

---

## 5. PERFORMANCE OPTIMIZATION

### 5.1 Bundle Size Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Initial JS | < 100KB | < 100KB target | < 120KB critical |
| Per-route chunk | < 50KB | < 75KB |
| Total CSS | < 30KB | < 50KB |
| Images | WebP/AVIF | - |

### 5.2 App Shell Pattern

```tsx
// components/AppShell.tsx
import { Suspense } from 'react';

export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col">
      <Header /> {/* Static, cached */}
      <main className="flex-1">
        <Suspense fallback={<ContentSkeleton />}>
          {children}
        </Suspense>
      </main>
      <BottomNav /> {/* Static, cached */}
    </div>
  );
}

// Skeleton loader
function ContentSkeleton() {
  return (
    <div className="p-4 space-y-4 animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-1/3" />
      <div className="grid grid-cols-2 gap-4">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="h-32 bg-gray-200 rounded-lg" />
        ))}
      </div>
    </div>
  );
}
```

### 5.3 Android-Specific Optimizations

```css
/* globals.css - Android performance fixes */

/* Disable backdrop-filter on low-end Android */
@media (max-device-memory: 2gb) {
  .backdrop-blur {
    backdrop-filter: none !important;
    background-color: rgba(255, 255, 255, 0.95) !important;
  }
}

/* Use passive scroll listeners */
.scrollable {
  -webkit-overflow-scrolling: touch;
  overscroll-behavior-y: contain;
}

/* GPU acceleration for animations */
.animate-transform {
  transform: translateZ(0);
  will-change: transform;
}

/* Reduce animation on low-end devices */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

```typescript
// lib/deviceCapability.ts
export function isLowEndDevice(): boolean {
  // @ts-ignore - Device Memory API
  const memory = navigator.deviceMemory;
  const cores = navigator.hardwareConcurrency;

  if (memory !== undefined && memory <= 2) return true;
  if (cores !== undefined && cores <= 2) return true;

  return false;
}

export function getQualityPreset(): 'low' | 'medium' | 'high' {
  const memory = (navigator as any).deviceMemory ?? 4;
  const cores = navigator.hardwareConcurrency ?? 4;

  if (memory <= 2 || cores <= 2) return 'low';
  if (memory <= 4 || cores <= 4) return 'medium';
  return 'high';
}
```

### 5.4 iOS-Specific Optimizations

```css
/* iOS Safari fixes */

/* Prevent zoom on input focus */
input, textarea, select {
  font-size: 16px; /* CRITICAL */
}

/* Remove tap highlight */
body {
  -webkit-tap-highlight-color: transparent;
}

/* Smooth scrolling */
.scroll-container {
  -webkit-overflow-scrolling: touch;
}

/* Safe area handling */
.safe-bottom {
  padding-bottom: env(safe-area-inset-bottom);
}

.safe-top {
  padding-top: env(safe-area-inset-top);
}
```

### 5.5 Long List Virtualization

```tsx
// Use react-virtual or @tanstack/react-virtual
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 72, // Estimated item height
    overscan: 5,
  });

  return (
    <div ref={parentRef} className="h-full overflow-auto">
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            <ItemRow item={items[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## 6. INSTALL EXPERIENCE

### 6.1 Install Prompt Hook

```typescript
// hooks/usePWAInstall.ts
'use client';

import { useState, useEffect } from 'react';

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export function usePWAInstall() {
  const [installPrompt, setInstallPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isInstalled, setIsInstalled] = useState(false);
  const [isIOS, setIsIOS] = useState(false);

  useEffect(() => {
    // Check if already installed
    const isStandalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as any).standalone === true;

    setIsInstalled(isStandalone);

    // Detect iOS
    const ios = /iPad|iPhone|iPod/.test(navigator.userAgent);
    setIsIOS(ios);

    if (isStandalone) return;

    // Listen for install prompt (Android/Chrome)
    const handler = (e: Event) => {
      e.preventDefault();
      setInstallPrompt(e as BeforeInstallPromptEvent);
    };

    window.addEventListener('beforeinstallprompt', handler);
    window.addEventListener('appinstalled', () => setIsInstalled(true));

    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, []);

  // React Compiler auto-memoizes — no manual useCallback needed
  const install = async () => {
    if (!installPrompt) return false;

    await installPrompt.prompt();
    const { outcome } = await installPrompt.userChoice;

    if (outcome === 'accepted') {
      setIsInstalled(true);
      setInstallPrompt(null);
    }

    return outcome === 'accepted';
  };

  return {
    isInstallable: !!installPrompt,
    isInstalled,
    isIOS,
    install,
  };
}
```

### 6.2 Custom Install UI

```tsx
// components/InstallPrompt.tsx
'use client';

import { usePWAInstall } from '@/hooks/usePWAInstall';

export function InstallPrompt() {
  const { isInstallable, isInstalled, isIOS, install } = usePWAInstall();

  if (isInstalled) return null;

  // iOS instructions (no beforeinstallprompt)
  if (isIOS) {
    return (
      <div className="fixed bottom-4 inset-s-4 inset-e-4 bg-white p-4 rounded-lg shadow-lg border z-50">
        <p className="font-medium mb-2">התקן את האפליקציה</p>
        <p className="text-sm text-gray-600 mb-3">
          לחץ על <span className="inline-block w-5 h-5 align-middle">
            <ShareIcon />
          </span> ואז "הוסף למסך הבית"
        </p>
        <button
          onClick={() => {/* dismiss */}}
          className="w-full py-2 bg-gray-100 rounded min-h-11"
        >
          הבנתי
        </button>
      </div>
    );
  }

  // Android/Chrome install prompt
  if (!isInstallable) return null;

  return (
    <div className="fixed bottom-4 inset-s-4 inset-e-4 bg-blue-600 text-white p-4 rounded-lg shadow-lg z-50">
      <p className="font-medium mb-3">התקן את האפליקציה</p>
      <div className="flex gap-2">
        <button
          onClick={() => {/* dismiss */}}
          className="flex-1 py-2 bg-blue-700 rounded min-h-11"
        >
          לא עכשיו
        </button>
        <button
          onClick={install}
          className="flex-1 py-2 bg-white text-blue-600 rounded font-medium min-h-11"
        >
          התקן
        </button>
      </div>
    </div>
  );
}
```

### 6.3 Detect Installed Apps

```typescript
// Check if app is already installed
export async function isAppInstalled(): Promise<boolean> {
  // Method 1: display-mode check
  if (window.matchMedia('(display-mode: standalone)').matches) {
    return true;
  }

  // Method 2: iOS Safari standalone
  if ((window.navigator as any).standalone === true) {
    return true;
  }

  // Method 3: getInstalledRelatedApps API (Chrome)
  if ('getInstalledRelatedApps' in navigator) {
    try {
      const apps = await (navigator as any).getInstalledRelatedApps();
      return apps.length > 0;
    } catch {
      return false;
    }
  }

  return false;
}
```

### 6.4 In-App Browser Detection (PWA-21)

> **Gate PWA-21:** Detect when app runs in Facebook/Instagram/TikTok WebView and show escape UI.

Social apps open links in their own crippled WebViews that cannot install PWAs, have limited storage, and break Service Workers.

```typescript
// lib/pwa/inAppBrowserDetection.ts

interface InAppBrowserResult {
  isInAppBrowser: boolean;
  browserName: string | null;
  escapeMethod: 'copy' | 'intent' | null;
}

const IN_APP_BROWSERS = [
  { pattern: /FBAN|FBAV/i, name: 'Facebook' },
  { pattern: /Instagram/i, name: 'Instagram' },
  { pattern: /musical_ly|TikTok|BytedanceWebview/i, name: 'TikTok' },
  { pattern: /Line\//i, name: 'LINE' },
  { pattern: /Twitter|X/i, name: 'X (Twitter)' },
  { pattern: /LinkedIn/i, name: 'LinkedIn' },
  { pattern: /Pinterest/i, name: 'Pinterest' },
  { pattern: /WeChat|MicroMessenger/i, name: 'WeChat' },
  { pattern: /WhatsApp/i, name: 'WhatsApp' },
] as const;

/**
 * PWA-21: Detect if running in an in-app browser (WebView)
 */
export function detectInAppBrowser(): InAppBrowserResult {
  if (typeof navigator === 'undefined') {
    return { isInAppBrowser: false, browserName: null, escapeMethod: null };
  }

  const ua = navigator.userAgent;

  for (const { pattern, name } of IN_APP_BROWSERS) {
    if (pattern.test(ua)) {
      const isIOS = /iPad|iPhone|iPod/.test(ua);
      return {
        isInAppBrowser: true,
        browserName: name,
        // iOS: Copy URL (can't use intent)
        // Android: Use intent:// to open in Chrome
        escapeMethod: isIOS ? 'copy' : 'intent',
      };
    }
  }

  return { isInAppBrowser: false, browserName: null, escapeMethod: null };
}

/**
 * Generate Chrome intent URL for Android
 */
export function getChromeIntentUrl(url: string = window.location.href): string {
  return `intent://${url.replace(/^https?:\/\//, '')}#Intent;scheme=https;package=com.android.chrome;end`;
}
```

**React Component:**

```tsx
// components/InAppBrowserBanner.tsx
import { useEffect, useState } from 'react';
import { detectInAppBrowser, getChromeIntentUrl } from '@/lib/pwa/inAppBrowserDetection';

export function InAppBrowserBanner() {
  const [browserInfo, setBrowserInfo] = useState<ReturnType<typeof detectInAppBrowser> | null>(null);

  useEffect(() => {
    setBrowserInfo(detectInAppBrowser());
  }, []);

  if (!browserInfo?.isInAppBrowser) return null;

  const handleEscape = async () => {
    if (browserInfo.escapeMethod === 'copy') {
      await navigator.clipboard.writeText(window.location.href);
    } else {
      window.location.href = getChromeIntentUrl();
    }
  };

  return (
    <div className="fixed inset-x-0 top-0 z-50 bg-yellow-500 text-black p-4 text-center" dir="rtl">
      <p className="font-medium mb-2">
        האפליקציה פועלת בדפדפן {browserInfo.browserName}. לחוויה מלאה, פתח בדפדפן רגיל.
      </p>
      <button onClick={handleEscape} className="bg-black text-white px-4 py-2 rounded-lg min-h-11">
        {browserInfo.escapeMethod === 'copy' ? 'העתק קישור' : 'פתח ב-Chrome'}
      </button>
    </div>
  );
}
```

---

## 7. CROSS-PLATFORM UI

### 7.1 Safe Areas

```css
/* globals.css */
:root {
  --sat: env(safe-area-inset-top, 0px);
  --sar: env(safe-area-inset-right, 0px);
  --sab: env(safe-area-inset-bottom, 0px);
  --sal: env(safe-area-inset-left, 0px);
}

.app-container {
  padding-top: var(--sat);
  padding-bottom: var(--sab);
}

.bottom-nav {
  padding-bottom: calc(var(--sab) + 16px);
}

.header {
  padding-top: calc(var(--sat) + 16px);
}

/* Tailwind utilities */
@layer utilities {
  .safe-top { padding-top: env(safe-area-inset-top); }
  .safe-bottom { padding-bottom: env(safe-area-inset-bottom); }
  .safe-x {
    padding-inline-start: env(safe-area-inset-left);
    padding-inline-end: env(safe-area-inset-right);
  }
}
```

### 7.2 CSS Normalization

```css
/* Cross-platform resets */
*,
*::before,
*::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
}

body {
  -webkit-tap-highlight-color: transparent;
  -webkit-overflow-scrolling: touch;
  overscroll-behavior: none;
  /* Prevent pull-to-refresh in standalone */
}

/* Disable callout on long press */
a, img, button {
  -webkit-touch-callout: none;
}

/* Input normalization */
input, textarea, select, button {
  appearance: none;
  -webkit-appearance: none;
  border-radius: 0;
  font: inherit;
}

/* Focus states */
:focus {
  outline: none;
}

:focus-visible {
  outline: 2px solid var(--focus-color, #3b82f6);
  outline-offset: 2px;
}
```

### 7.3 RTL Support

```css
/* Always use logical properties */
.card {
  margin-inline-start: 1rem;
  margin-inline-end: 1rem;
  padding-inline-start: 1rem;
  padding-inline-end: 1rem;
  text-align: start;
  border-inline-start: 2px solid;
}

/* Tailwind RTL classes */
.example {
  /* Use ms-/me- instead of ml-/mr- */
  @apply ms-4 me-2;
  /* Use text-start/end instead of text-left/right */
  @apply text-start;
  /* Use inset-s-/inset-e- instead of left-/right- for logical inset (TW 4.2; start-/end- deprecated) */
  @apply inset-s-0 inset-e-4;
}
```

```tsx
// RTL icon rotation
<ChevronLeft className="rtl:rotate-180" />
<ArrowRight className="rtl:rotate-180" />

// Numbers in RTL
<span dir="ltr" className="inline-block">
  {price.toLocaleString('he-IL')}
</span>
```

### 7.4 Standalone Mode Detection

```typescript
// hooks/useStandaloneMode.ts
export function useStandaloneMode() {
  const [isStandalone, setIsStandalone] = useState(false);

  useEffect(() => {
    const standalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as any).standalone === true;

    setIsStandalone(standalone);
  }, []);

  return isStandalone;
}
```

```css
/* Standalone-specific styles */
@media (display-mode: standalone) {
  .browser-only { display: none; }

  .app-header {
    padding-top: env(safe-area-inset-top);
  }
}
```

---

## 8. SECURITY

### 8.1 Security Headers

```typescript
// next.config.ts
const securityHeaders = [
  { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains; preload' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-XSS-Protection', value: '1; mode=block' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
  { key: 'Cross-Origin-Opener-Policy', value: 'same-origin' },
  { key: 'Cross-Origin-Embedder-Policy', value: 'require-corp' },
];

export default {
  async headers() {
    return [{ source: '/(.*)', headers: securityHeaders }];
  },
};
```

### 8.2 CSP for PWA

```typescript
// proxy.ts
const cspHeader = `
  default-src 'self';
  script-src 'self' 'nonce-${nonce}' 'strict-dynamic';
  style-src 'self' 'unsafe-inline';
  img-src 'self' blob: data: https:;
  font-src 'self';
  connect-src 'self' https://api.example.com wss://realtime.example.com;
  frame-ancestors 'none';
  worker-src 'self';
  manifest-src 'self';
`.replace(/\s{2,}/g, ' ').trim();
```

### 8.3 Service Worker Kill Switch

```typescript
// Add to src/sw.ts
const KILL_SWITCH_URL = '/api/sw-status';

self.addEventListener('activate', async (event) => {
  event.waitUntil(
    (async () => {
      try {
        const response = await fetch(KILL_SWITCH_URL);
        const { disabled } = await response.json();

        if (disabled) {
          await self.registration.unregister();
          const cacheNames = await caches.keys();
          await Promise.all(cacheNames.map(name => caches.delete(name)));
        }
      } catch {
        // Continue if check fails
      }
    })()
  );
});
```

---

## 9. CUTTING-EDGE APIS

### 9.1 View Transitions API

```css
/* Enable cross-document transitions */
@view-transition {
  navigation: auto;
}

::view-transition-old(root) {
  animation: fade-out 0.25s ease-out forwards;
}

::view-transition-new(root) {
  animation: fade-in 0.25s ease-in forwards;
}
```

```typescript
// Same-document transitions
function navigateWithTransition(updateFn: () => void) {
  if (!('startViewTransition' in document)) {
    updateFn();
    return;
  }

  document.startViewTransition(updateFn);
}
```

### 9.2 Speculation Rules (Prerendering)

```html
<script type="speculationrules">
{
  "prerender": [
    {
      "where": { "href_matches": "/products/*" },
      "eagerness": "moderate"
    }
  ],
  "prefetch": [
    {
      "where": { "href_matches": "/*" },
      "eagerness": "conservative"
    }
  ]
}
</script>
```

### 9.3 OPFS (Fast File Storage)

```typescript
// Origin Private File System - 5-10x faster than IndexedDB
const root = await navigator.storage.getDirectory();
const fileHandle = await root.getFileHandle('data.json', { create: true });

// Write
const writable = await fileHandle.createWritable();
await writable.write(JSON.stringify(data));
await writable.close();

// Read
const file = await fileHandle.getFile();
const content = await file.text();
```

### 9.4 Screen Wake Lock

```typescript
let wakeLock: WakeLockSentinel | null = null;

export async function requestWakeLock() {
  if (!('wakeLock' in navigator)) return null;

  try {
    wakeLock = await navigator.wakeLock.request('screen');
    return wakeLock;
  } catch {
    return null;
  }
}

// Re-acquire on visibility change
document.addEventListener('visibilitychange', async () => {
  if (document.visibilityState === 'visible' && !wakeLock) {
    await requestWakeLock();
  }
});
```

### 9.5 Feature Detection Utility

```typescript
// lib/featureDetection.ts
export const pwaFeatures = {
  serviceWorker: () => 'serviceWorker' in navigator,
  pushManager: () => 'PushManager' in window,
  notification: () => 'Notification' in window,
  backgroundSync: () => 'SyncManager' in window,
  periodicSync: () => 'PeriodicSyncManager' in window,
  share: () => 'share' in navigator,
  badging: () => 'setAppBadge' in navigator,
  wakeLock: () => 'wakeLock' in navigator,
  opfs: () => 'storage' in navigator && 'getDirectory' in navigator.storage,
  viewTransitions: () => 'startViewTransition' in document,
  speculationRules: () => HTMLScriptElement.supports?.('speculationrules') ?? false,
  webgpu: () => 'gpu' in navigator,
  networkInfo: () => 'connection' in navigator,
};

export function getSupportedFeatures(): string[] {
  return Object.entries(pwaFeatures)
    .filter(([, check]) => check())
    .map(([name]) => name);
}
```

---

## 10. TESTING CHECKLIST

### 10.1 PWA Gate Matrix

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-PWA-1 | SW_REGISTERED | SW active in DevTools | State: activated |
| G-PWA-2 | MANIFEST_VALID | Lighthouse check | 0 errors |
| G-PWA-3 | OFFLINE_WORKS | Offline mode | Page loads |
| G-PWA-4 | INSTALLABLE | Install prompt | beforeinstallprompt fires |
| G-PWA-5 | ICONS_CORRECT | All sizes | 192, 512, maskable |
| G-PWA-6 | LIGHTHOUSE_100 | PWA score | 100/100 |
| G-PWA-7 | SECURITY_HEADERS | CSP, COOP/COEP | A+ rating |

### 10.2 Offline Mode Testing

```markdown
### Offline Checklist
- [ ] App loads when offline
- [ ] Offline page shows for uncached routes
- [ ] No console errors offline
- [ ] Queued mutations sync when online
- [ ] Data persists across sessions
- [ ] Clear error messages for offline state
```

### 10.3 Slow 3G Simulation

```markdown
### Slow Network Checklist
- [ ] App shell loads < 3s
- [ ] Skeleton loaders visible
- [ ] No layout shift on content load
- [ ] Images lazy load correctly
- [ ] API calls show loading states
- [ ] Timeouts handled gracefully
```

### 10.4 Install/Uninstall Cycle

```markdown
### Installation Checklist
- [ ] Install prompt appears (Android Chrome)
- [ ] iOS Add to Home Screen works
- [ ] Correct name and icon displayed
- [ ] Opens in standalone mode
- [ ] App updates after reinstall
- [ ] Data persists after uninstall/reinstall
```

### 10.5 Push Notification Testing

```markdown
### Push Notification Checklist
- [ ] Permission prompt appears
- [ ] Notification received when app closed
- [ ] Click opens correct page
- [ ] Badge updates (where supported)
- [ ] Silent push works for data sync
- [ ] Android 13+ permission flow works
- [ ] iOS 16.4+ PWA notifications work
```

### 10.6 Cross-Platform Matrix

| Test | iOS Safari | Android Chrome | Desktop Chrome |
|------|------------|----------------|----------------|
| Install | Manual | Prompt | Prompt |
| Offline | SW | SW | SW |
| Push | 16.4+ | Full | Full |
| Badging | No | Yes | Yes |
| Background Sync | No | Yes | Yes |
| Safe Areas | Yes | Some | No |

### 10.7 Lighthouse Audit Command

```bash
npx lighthouse https://your-app.com \
  --only-categories=pwa,performance,best-practices \
  --output=html \
  --output-path=./lighthouse-report.html
```

### 10.8 Complete Pre-Production Checklist

```markdown
### Manifest
- [ ] name and short_name defined
- [ ] start_url set to "/"
- [ ] display: standalone
- [ ] theme_color matches app
- [ ] background_color set
- [ ] 192x192 icon present
- [ ] 512x512 icon present
- [ ] Maskable icon (separate file)
- [ ] dir and lang set for RTL

### Service Worker
- [ ] Registers successfully
- [ ] Offline fallback configured
- [ ] Update flow implemented
- [ ] Cache strategies appropriate
- [ ] Background sync configured
- [ ] Push handlers implemented

### Performance
- [ ] LCP < 1.5s
- [ ] CLS = 0
- [ ] INP < 100ms
- [ ] Bundle < 100KB target | < 120KB critical initial

### Security
- [ ] HTTPS enforced
- [ ] CSP configured
- [ ] Security headers A+ rating
- [ ] No sensitive data in cache

### Cross-Platform
- [ ] iOS Safari tested
- [ ] Android Chrome tested
- [ ] Safe areas handled
- [ ] RTL layout correct
- [ ] Touch targets 44px minimum
```

---

## 11. OLD ANDROID COMPATIBILITY

> **Deep Dive:** See `~/.claude/skills/pwa-expert/references/pwa-android-optimization.md` for complete patterns and code examples.

### 11.1 Chrome < 84 Limitations

Older Chrome versions (pre-84) have significant PWA limitations:

| Feature | Chrome 70-83 | Chrome 84+ | Notes |
|---------|--------------|------------|-------|
| Web Share API | Partial | Full | No file sharing < 80 |
| Background Sync | Basic | Full | Limited retry logic < 76 |
| Content Indexing | No | Yes | Requires 84+ |
| App Shortcuts | No | Yes | Requires 84+ |
| Screen Wake Lock | No | Yes | Requires 84+ |
| Periodic Background Sync | No | Limited | Requires 80+ |
| File System Access | No | Yes | Requires 86+ |
| Web Share Target | Basic | Full | Level 2 requires 76+ |

**Critical:** Always use feature detection, NEVER user agent sniffing.

```typescript
// CORRECT: Feature detection
if ('wakeLock' in navigator) {
  await navigator.wakeLock.request('screen');
}

// WRONG: User agent sniffing
if (parseInt(getChromeVersion()) >= 84) { // DON'T DO THIS
  // ...
}
```

### 11.2 WebView vs Chrome Differences

Android WebView (used in embedded browsers and TWAs) behaves differently from Chrome:

| Aspect | Chrome | WebView | Impact |
|--------|--------|---------|--------|
| Update cycle | Automatic | Tied to Android | WebView may lag months behind |
| Service Worker | Full | Full (7.0+) | Android < 7 has no SW in WebView |
| Push Notifications | Full | Limited | Often blocked by OEMs |
| Install Prompt | beforeinstallprompt | None | WebView cannot install PWAs |
| Camera/Mic | Full | Requires permissions | OEM-specific permission dialogs |
| Geolocation | Full | Requires HTTPS + permissions | May fail silently |
| Background Sync | Full | Often killed | Aggressive battery optimization |

**WebView Detection:**

```typescript
// Detect if running in WebView vs Chrome
export function isWebView(): boolean {
  const ua = navigator.userAgent;

  // Android WebView indicators
  if (/wv|WebView/i.test(ua)) return true;

  // In-app browsers (Facebook, Instagram, etc.)
  if (/FBAN|FBAV|Instagram|Line|Twitter/i.test(ua)) return true;

  // Missing standalone capability suggests WebView
  if (/Android/.test(ua) && !window.matchMedia('(display-mode: standalone)').matches) {
    // Check if beforeinstallprompt is available
    if (!('BeforeInstallPromptEvent' in window)) return true;
  }

  return false;
}

// Provide fallback experience for WebView users
if (isWebView()) {
  // Show "Open in Chrome" button for full PWA features
  showOpenInBrowserPrompt();
}
```

### 11.3 OEM-Specific Android Issues

Different Android manufacturers have unique PWA challenges:

| OEM | Issue | Workaround |
|-----|-------|------------|
| **Samsung** | Different install prompt timing | Listen for longer, Samsung Internet has own UX |
| **Xiaomi/MIUI** | Aggressive battery kill | Guide users to disable battery optimization |
| **Huawei** | No Google Play Services | Use Web Push, not FCM |
| **OnePlus** | Background process limits | Implement retry logic for sync |
| **Oppo/Realme** | Similar to Xiaomi | Battery optimization guidance |

```typescript
// OEM detection for tailored guidance
export function getOEMGuidance(): string | null {
  const ua = navigator.userAgent.toLowerCase();

  if (/xiaomi|redmi|mi\s/i.test(ua)) {
    return 'לביצועים מיטביים, כבה "חיסכון בסוללה" עבור האפליקציה בהגדרות';
  }

  if (/huawei|honor/i.test(ua)) {
    return 'התראות Push פועלות באופן מלא ללא שירותי Google';
  }

  return null;
}
```

### 11.4 Memory & Performance on Old Devices

Old Android devices (2-4GB RAM) require special handling:

```typescript
// Detect low-end devices
export function isLowEndAndroid(): boolean {
  // Device Memory API (Chrome 63+)
  const memory = (navigator as any).deviceMemory;
  if (memory !== undefined && memory <= 2) return true;

  // Hardware Concurrency fallback
  const cores = navigator.hardwareConcurrency;
  if (cores !== undefined && cores <= 2) return true;

  return false;
}

// Adaptive loading based on device capability
export function getOptimizationLevel(): 'aggressive' | 'moderate' | 'none' {
  if (isLowEndAndroid()) return 'aggressive';

  const memory = (navigator as any).deviceMemory ?? 4;
  if (memory <= 4) return 'moderate';

  return 'none';
}
```

**Optimization strategies by level:**

| Level | Actions |
|-------|---------|
| **Aggressive** | No blur/backdrop-filter, reduce animations, limit list items (20), disable prefetch |
| **Moderate** | Simplified animations, limit list items (50), lazy load images |
| **None** | Full experience |

### 11.5 CSS Performance on Old Android

**CRITICAL:** These CSS properties cause severe jank on old Android:

```css
/* AVOID on old Android - causes CPU rendering */
.bad-performance {
  backdrop-filter: blur(10px);      /* GPU -> CPU fallback */
  filter: blur(5px);                /* Expensive */
  box-shadow: 0 20px 40px rgba();   /* Animated = death */
  will-change: transform, opacity;  /* Overuse = memory leak */
}

/* RECOMMENDED - GPU-accelerated only */
.good-performance {
  background-color: rgba(255, 255, 255, 0.95); /* Solid, fast */
  transform: translateZ(0);                     /* Force GPU */
  opacity: 0.9;                                 /* GPU-accelerated */
}
```

```typescript
// Apply solid backgrounds on Android
const isAndroid = /Android/i.test(navigator.userAgent);

<div className={cn(
  "transition-colors",
  isAndroid
    ? "bg-white/95 dark:bg-gray-900/95"
    : "backdrop-blur-md bg-white/80"
)}>
```

### 11.6 Old Android Quick Checklist

```markdown
### Pre-Release Old Android Verification

#### Feature Detection (NOT User Agent)
- [ ] All APIs wrapped in feature detection
- [ ] No `parseInt(getChromeVersion())` patterns
- [ ] Graceful degradation for missing features

#### Performance
- [ ] No `backdrop-filter` on Android (use solid backgrounds)
- [ ] All scroll listeners use `{ passive: true }`
- [ ] Memory cleanup in all useEffect hooks
- [ ] LRU cache with size limits (not unbounded Maps)
- [ ] Bundle < 100KB gzipped

#### Service Worker
- [ ] Registers on Android 7+
- [ ] Offline fallback works
- [ ] Background sync has retry logic
- [ ] Update check on visibility change

#### Device Testing
- [ ] Tested on Android 7-8 device (2GB RAM)
- [ ] Tested on mid-range Android 10-11 (4GB RAM)
- [ ] Tested in Samsung Internet browser
- [ ] Tested with airplane mode

#### OEM Handling
- [ ] Battery optimization guidance for Xiaomi/MIUI
- [ ] Web Push works on Huawei (no FCM dependency)
- [ ] Install prompt works in Samsung Internet

#### WebView Handling
- [ ] Detected WebView shows "Open in Chrome" prompt
- [ ] Core functionality works without SW
- [ ] No install prompt in WebView (graceful handling)
```

### 11.7 Minimum Version Matrix

| Feature | Minimum Android | Minimum Chrome | Notes |
|---------|-----------------|----------------|-------|
| Service Worker | 7.0 | 58 | WebView needs Android 7.0+ |
| Push Notifications | 7.0 | 58 | OEM-dependent |
| Add to Home Screen | 6.0 | 44 | Basic prompt only |
| Web App Manifest | 5.0 | 42 | Limited features |
| Background Sync | 7.0 | 49 | Basic support |
| Share Target | 8.0 | 71 | Level 2 requires 76+ |
| Shortcuts API | 10.0 | 84 | App shortcuts |
| Screen Wake Lock | 10.0 | 84 | Keep screen on |
| File System Access | 11.0 | 86 | OPFS |

**Recommendation:** Target Android 7.0+ (Chrome 58+) as minimum for full PWA experience. Provide degraded experience for Android 5-6.

---

## 12. STORAGE QUOTA MANAGEMENT

> **Gate PWA-20: Persistent Storage** - Request persistent storage to prevent IndexedDB eviction under storage pressure.

### 12.1 Check Available Storage Quota

```typescript
// lib/storageQuota.ts

export interface StorageEstimate {
  usage: number;
  quota: number;
  usagePercent: number;
  available: number;
}

/**
 * Get storage estimate for the origin
 * Works in Chrome, Edge, Firefox, Safari 16.4+
 */
export async function getStorageEstimate(): Promise<StorageEstimate | null> {
  if (!('storage' in navigator) || !('estimate' in navigator.storage)) {
    console.warn('Storage API not supported');
    return null;
  }

  try {
    const estimate = await navigator.storage.estimate();
    const usage = estimate.usage ?? 0;
    const quota = estimate.quota ?? 0;

    return {
      usage,
      quota,
      usagePercent: quota > 0 ? (usage / quota) * 100 : 0,
      available: quota - usage,
    };
  } catch (error) {
    console.error('Failed to get storage estimate:', error);
    return null;
  }
}

/**
 * Format bytes to human-readable string
 */
export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
}

/**
 * Check if storage is persisted (won't be evicted)
 */
export async function isStoragePersisted(): Promise<boolean> {
  if (!('storage' in navigator) || !('persisted' in navigator.storage)) {
    return false;
  }
  return navigator.storage.persisted();
}

/**
 * PWA-20: Request persistent storage (prevents browser eviction)
 *
 * CRITICAL: Browsers can evict IndexedDB data under storage pressure.
 * Call after user engagement (login, PWA install, first data sync).
 * Chrome auto-grants for installed PWAs, Safari may prompt user.
 */
export async function requestPersistentStorage(): Promise<boolean> {
  if (!('storage' in navigator) || !('persist' in navigator.storage)) {
    console.warn('[PWA-20] Storage API not supported');
    return false;
  }

  // Check if already persisted
  const isPersisted = await navigator.storage.persisted();
  if (isPersisted) {
    console.log('[PWA-20] Storage already persisted');
    return true;
  }

  try {
    const granted = await navigator.storage.persist();
    console.log(`[PWA-20] Persistent storage ${granted ? 'granted' : 'denied'}`);
    return granted;
  } catch {
    return false;
  }
}
```

### 12.2 Detailed Storage Breakdown

```typescript
// lib/storageBreakdown.ts
import { openDB } from 'idb';

export interface StorageBreakdown {
  cacheStorage: number;
  indexedDB: number;
  serviceWorker: number;
  total: number;
}

/**
 * Get detailed storage breakdown by type
 * Note: This is an approximation - Chrome doesn't expose exact per-type usage
 */
export async function getStorageBreakdown(): Promise<StorageBreakdown> {
  let cacheStorage = 0;
  let indexedDB = 0;

  // Measure Cache Storage
  if ('caches' in self) {
    try {
      const cacheNames = await caches.keys();
      for (const name of cacheNames) {
        const cache = await caches.open(name);
        const requests = await cache.keys();

        for (const request of requests) {
          const response = await cache.match(request);
          if (response) {
            const blob = await response.clone().blob();
            cacheStorage += blob.size;
          }
        }
      }
    } catch (e) {
      console.error('Error measuring cache storage:', e);
    }
  }

  // Measure IndexedDB (approximation via serialization)
  if ('indexedDB' in self) {
    try {
      const databases = await indexedDB.databases?.() ?? [];
      for (const dbInfo of databases) {
        if (!dbInfo.name) continue;

        const db = await openDB(dbInfo.name);
        const storeNames = Array.from(db.objectStoreNames);

        for (const storeName of storeNames) {
          const tx = db.transaction(storeName, 'readonly');
          const store = tx.objectStore(storeName);
          const count = await store.count();

          // Estimate ~1KB per record (rough approximation)
          indexedDB += count * 1024;
        }
        db.close();
      }
    } catch (e) {
      console.error('Error measuring IndexedDB:', e);
    }
  }

  return {
    cacheStorage,
    indexedDB,
    serviceWorker: 0, // SW scripts are negligible
    total: cacheStorage + indexedDB,
  };
}
```

### 12.3 Cache Cleanup Strategies

```typescript
// lib/cacheCleanup.ts

const CACHE_VERSION = 'v1';
const MAX_CACHE_AGE_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
const MAX_CACHE_SIZE = 50 * 1024 * 1024; // 50MB target
const MIN_FREE_SPACE_PERCENT = 20; // Keep 20% free

interface CacheEntry {
  cacheName: string;
  url: string;
  size: number;
  timestamp: number;
}

/**
 * Clean old caches (version-based)
 */
export async function cleanOldVersionCaches(): Promise<string[]> {
  const cacheNames = await caches.keys();
  const deleted: string[] = [];

  for (const name of cacheNames) {
    if (!name.includes(CACHE_VERSION)) {
      await caches.delete(name);
      deleted.push(name);
    }
  }

  return deleted;
}

/**
 * Clean expired entries based on timestamp header
 */
export async function cleanExpiredEntries(): Promise<number> {
  const now = Date.now();
  let deletedCount = 0;

  const cacheNames = await caches.keys();

  for (const name of cacheNames) {
    const cache = await caches.open(name);
    const requests = await cache.keys();

    for (const request of requests) {
      const response = await cache.match(request);
      if (!response) continue;

      // Check custom timestamp header
      const timestamp = response.headers.get('x-sw-cache-timestamp');
      if (timestamp && now - parseInt(timestamp) > MAX_CACHE_AGE_MS) {
        await cache.delete(request);
        deletedCount++;
      }
    }
  }

  return deletedCount;
}

/**
 * LRU cache cleanup - remove least recently used entries
 */
export async function lruCacheCleanup(targetFreeBytes: number): Promise<number> {
  const entries: CacheEntry[] = [];
  const cacheNames = await caches.keys();

  // Collect all entries with size and timestamp
  for (const cacheName of cacheNames) {
    const cache = await caches.open(cacheName);
    const requests = await cache.keys();

    for (const request of requests) {
      const response = await cache.match(request);
      if (!response) continue;

      const blob = await response.clone().blob();
      const timestamp = parseInt(response.headers.get('x-sw-cache-timestamp') ?? '0') || 0;

      entries.push({
        cacheName,
        url: request.url,
        size: blob.size,
        timestamp,
      });
    }
  }

  // Sort by timestamp (oldest first)
  entries.sort((a, b) => a.timestamp - b.timestamp);

  let freedBytes = 0;
  let deletedCount = 0;

  for (const entry of entries) {
    if (freedBytes >= targetFreeBytes) break;

    const cache = await caches.open(entry.cacheName);
    await cache.delete(entry.url);
    freedBytes += entry.size;
    deletedCount++;
  }

  return deletedCount;
}

/**
 * Automatic cleanup when quota is low
 */
export async function autoCleanupIfNeeded(): Promise<void> {
  const estimate = await navigator.storage.estimate();
  if (!estimate.quota || !estimate.usage) return;

  const freePercent = ((estimate.quota - estimate.usage) / estimate.quota) * 100;

  if (freePercent < MIN_FREE_SPACE_PERCENT) {
    console.log(`[Storage] Low space (${freePercent.toFixed(1)}% free), running cleanup...`);

    // Step 1: Clean old version caches
    await cleanOldVersionCaches();

    // Step 2: Clean expired entries
    await cleanExpiredEntries();

    // Step 3: If still low, run LRU cleanup
    const newEstimate = await navigator.storage.estimate();
    const newFreePercent = ((newEstimate.quota! - newEstimate.usage!) / newEstimate.quota!) * 100;

    if (newFreePercent < MIN_FREE_SPACE_PERCENT) {
      const targetFree = (MIN_FREE_SPACE_PERCENT / 100) * newEstimate.quota!;
      const currentFree = newEstimate.quota! - newEstimate.usage!;
      await lruCacheCleanup(targetFree - currentFree);
    }
  }
}
```

### 12.4 Handle Quota Exceeded Errors

```typescript
// lib/quotaErrorHandler.ts

export class QuotaExceededError extends Error {
  constructor(message = 'Storage quota exceeded') {
    super(message);
    this.name = 'QuotaExceededError';
  }
}

/**
 * Safe cache put with quota error handling
 */
export async function safeCachePut(
  cacheName: string,
  request: Request | string,
  response: Response
): Promise<boolean> {
  try {
    const cache = await caches.open(cacheName);
    await cache.put(request, response);
    return true;
  } catch (error) {
    if (error instanceof DOMException && error.name === 'QuotaExceededError') {
      console.warn('[Storage] Quota exceeded, attempting cleanup...');

      // Try cleanup and retry once
      await autoCleanupIfNeeded();

      try {
        const cache = await caches.open(cacheName);
        await cache.put(request, response);
        return true;
      } catch (retryError) {
        console.error('[Storage] Still exceeded after cleanup');
        throw new QuotaExceededError();
      }
    }
    throw error;
  }
}

/**
 * Safe IndexedDB put with quota handling
 */
export async function safeIndexedDBPut<T>(
  dbName: string,
  storeName: string,
  data: T
): Promise<boolean> {
  try {
    const db = await openDB(dbName);
    await db.put(storeName, data);
    return true;
  } catch (error) {
    if (error instanceof DOMException && error.name === 'QuotaExceededError') {
      console.warn('[Storage] IndexedDB quota exceeded');

      // Clean old IndexedDB entries
      await cleanOldIndexedDBEntries(dbName, storeName);

      // Retry
      try {
        const db = await openDB(dbName);
        await db.put(storeName, data);
        return true;
      } catch {
        throw new QuotaExceededError();
      }
    }
    throw error;
  }
}

async function cleanOldIndexedDBEntries(dbName: string, storeName: string): Promise<void> {
  const db = await openDB(dbName);
  const tx = db.transaction(storeName, 'readwrite');
  const store = tx.objectStore(storeName);

  // If store has timestamp index, delete oldest 20%
  if (store.indexNames.contains('timestamp')) {
    const index = store.index('timestamp');
    const count = await store.count();
    const deleteCount = Math.ceil(count * 0.2);

    let deleted = 0;
    let cursor = await index.openCursor();

    while (cursor && deleted < deleteCount) {
      await cursor.delete();
      deleted++;
      cursor = await cursor.continue();
    }
  }
}
```

### 12.5 Combined IndexedDB + Cache Storage Management

```typescript
// lib/unifiedStorageManager.ts

export interface StorageConfig {
  maxTotalSize: number; // Total max size in bytes
  cachePriority: number; // 0-1, percentage for cache vs IndexedDB
  criticalCaches: string[]; // Cache names that should never be cleaned
  criticalStores: string[]; // IndexedDB stores that should never be cleaned
}

const DEFAULT_CONFIG: StorageConfig = {
  maxTotalSize: 100 * 1024 * 1024, // 100MB
  cachePriority: 0.6, // 60% for cache, 40% for IndexedDB
  criticalCaches: ['static-assets', 'offline-pages'],
  criticalStores: ['user-data', 'sync-queue'],
};

export class UnifiedStorageManager {
  private config: StorageConfig;

  constructor(config: Partial<StorageConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  async getStatus(): Promise<{
    total: number;
    cache: number;
    indexedDB: number;
    available: number;
    healthy: boolean;
  }> {
    const estimate = await navigator.storage.estimate();
    const breakdown = await getStorageBreakdown();

    const total = estimate.usage ?? 0;
    const available = (estimate.quota ?? 0) - total;
    const healthy = total < this.config.maxTotalSize * 0.9;

    return {
      total,
      cache: breakdown.cacheStorage,
      indexedDB: breakdown.indexedDB,
      available,
      healthy,
    };
  }

  async balanceStorage(): Promise<void> {
    const status = await this.getStatus();

    if (status.healthy) return;

    const targetCacheSize = this.config.maxTotalSize * this.config.cachePriority;
    const targetIDBSize = this.config.maxTotalSize * (1 - this.config.cachePriority);

    // Clean cache if over limit
    if (status.cache > targetCacheSize) {
      const toFree = status.cache - targetCacheSize;
      await this.cleanCacheStorage(toFree);
    }

    // Clean IndexedDB if over limit
    if (status.indexedDB > targetIDBSize) {
      const toFree = status.indexedDB - targetIDBSize;
      await this.cleanIndexedDBStorage(toFree);
    }
  }

  private async cleanCacheStorage(bytesToFree: number): Promise<void> {
    const cacheNames = await caches.keys();
    const cleanable = cacheNames.filter(
      (name) => !this.config.criticalCaches.includes(name)
    );

    let freed = 0;
    for (const name of cleanable) {
      if (freed >= bytesToFree) break;

      const cache = await caches.open(name);
      const requests = await cache.keys();

      for (const request of requests) {
        if (freed >= bytesToFree) break;

        const response = await cache.match(request);
        if (response) {
          const blob = await response.blob();
          await cache.delete(request);
          freed += blob.size;
        }
      }
    }
  }

  private async cleanIndexedDBStorage(bytesToFree: number): Promise<void> {
    // Implementation depends on specific DB schema
    // This is a simplified example
    console.log(`[Storage] Need to free ${formatBytes(bytesToFree)} from IndexedDB`);
  }
}

// Export singleton
export const storageManager = new UnifiedStorageManager();
```

### 12.6 Storage Status Hook

```typescript
// hooks/useStorageStatus.ts
import { useState, useEffect } from 'react';
import { getStorageEstimate, formatBytes, type StorageEstimate } from '@/lib/storageQuota';
import { storageManager } from '@/lib/unifiedStorageManager';

export function useStorageStatus() {
  const [status, setStatus] = useState<StorageEstimate | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // React Compiler auto-memoizes — no manual useCallback needed
  const refresh = async () => {
    setIsLoading(true);
    try {
      const estimate = await getStorageEstimate();
      setStatus(estimate);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e : new Error('Unknown error'));
    } finally {
      setIsLoading(false);
    }
  };

  const cleanup = async () => {
    await storageManager.balanceStorage();
    await refresh();
  };

  useEffect(() => {
    refresh();
  }, []);

  return {
    status,
    isLoading,
    error,
    refresh,
    cleanup,
    formatted: status
      ? {
          usage: formatBytes(status.usage),
          quota: formatBytes(status.quota),
          available: formatBytes(status.available),
          percent: `${status.usagePercent.toFixed(1)}%`,
        }
      : null,
  };
}
```

---

## 13. TREE SHAKING & BUNDLE OPTIMIZATION

### 13.1 Vite/Rollup Tree Shaking Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    react(),
    // Bundle analyzer - run with ANALYZE=true pnpm run build
    process.env.ANALYZE &&
      visualizer({
        open: true,
        filename: 'dist/stats.html',
        gzipSize: true,
        brotliSize: true,
      }),
  ].filter(Boolean),

  build: {
    target: 'esnext',
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true, // Remove console.log in production
        drop_debugger: true,
        pure_funcs: ['console.log', 'console.info', 'console.debug'],
      },
      mangle: {
        safari10: true, // iOS 10 Safari compatibility
      },
    },

    rollupOptions: {
      output: {
        // Manual chunk splitting for optimal caching
        manualChunks: {
          // Vendor chunks
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-query': ['@tanstack/react-query'],
          'vendor-ui': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
          'vendor-forms': ['react-hook-form', 'zod', '@hookform/resolvers'],

          // Heavy feature chunks
          'feature-charts': ['recharts'],
          'feature-dates': ['date-fns'],
        },

        // Hash-based filenames for cache busting
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]',
      },

      // External CDN dependencies (if using)
      // external: ['react', 'react-dom'],
    },

    // Chunk size warnings
    chunkSizeWarningLimit: 500, // KB

    // Enable source maps for debugging (disable in production)
    sourcemap: process.env.NODE_ENV !== 'production',
  },

  // Optimize dependencies
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      '@tanstack/react-query',
    ],
    exclude: [
      // Large libraries that should be dynamically imported
      'recharts',
      '@sentry/react',
    ],
  },
});
```

### 13.2 Side-Effect Free package.json

```json
{
  "name": "my-pwa",
  "version": "1.0.0",
  "sideEffects": [
    "**/*.css",
    "**/*.scss",
    "./src/lib/polyfills.ts",
    "./src/lib/sentry.ts"
  ],
  "main": "src/index.ts",
  "module": "src/index.ts",
  "types": "src/index.d.ts"
}
```

```typescript
// lib/utils.ts - Mark individual exports as side-effect free
// Using @__PURE__ annotation for tree-shaking hints

export const formatDate = /*@__PURE__*/ (date: Date): string => {
  return new Intl.DateTimeFormat('he-IL').format(date);
};

export const formatCurrency = /*@__PURE__*/ (amount: number): string => {
  return new Intl.NumberFormat('he-IL', {
    style: 'currency',
    currency: 'ILS',
  }).format(amount);
};

// Factory function with pure annotation
export const createFormatter = /*@__PURE__*/ (locale: string) => {
  return {
    date: new Intl.DateTimeFormat(locale),
    number: new Intl.NumberFormat(locale),
  };
};
```

### 13.3 Dynamic Import Patterns

```typescript
// Lazy loading components with proper chunking

// 1. Route-based code splitting
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const Analytics = lazy(() =>
  import('./pages/Analytics').then((module) => ({
    default: module.AnalyticsPage,
  }))
);

// 2. Feature-based dynamic imports
async function loadChartLibrary() {
  const { LineChart, BarChart } = await import(
    /* webpackChunkName: "charts" */
    /* webpackPrefetch: true */
    'recharts'
  );
  return { LineChart, BarChart };
}

// 3. Conditional loading based on feature flags
async function loadOptionalFeature(featureName: string) {
  if (featureName === 'analytics') {
    return import('./features/analytics');
  }
  if (featureName === 'export') {
    return import('./features/export');
  }
  return null;
}

// 4. Prefetch on hover pattern
function ProductCard({ productId }: { productId: string }) {
  const prefetchDetails = () => {
    import('./pages/ProductDetails');
  };

  return (
    <Link
      to={`/product/${productId}`}
      onMouseEnter={prefetchDetails}
      onFocus={prefetchDetails}
    >
      View Product
    </Link>
  );
}

// 5. Intersection Observer for lazy loading
function useLazyComponent<T extends React.ComponentType<Record<string, unknown>>>(
  importFn: () => Promise<{ default: T }>
) {
  const [Component, setComponent] = useState<T | null>(null);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          importFn().then((module) => {
            setComponent(() => module.default);
          });
          observer.disconnect();
        }
      },
      { rootMargin: '200px' }
    );

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, [importFn]);

  return { Component, ref };
}
```

### 13.4 Bundle Analyzer Usage

```bash
# Install visualizer
pnpm add -D rollup-plugin-visualizer

# Run analysis
ANALYZE=true pnpm run build

# Or use vite-bundle-analyzer
pnpm add -D vite-bundle-analyzer
```

```typescript
// vite.config.ts - Alternative analyzer
import { analyzer } from 'vite-bundle-analyzer';

export default defineConfig({
  plugins: [
    analyzer({
      analyzerMode: 'static',
      fileName: 'bundle-report',
    }),
  ],
});
```

```bash
# Check bundle size with size-limit
pnpm add -D size-limit @size-limit/preset-app

# package.json
{
  "size-limit": [
    {
      "path": "dist/assets/*.js",
      "limit": "100 KB",
      "gzip": true
    },
    {
      "path": "dist/assets/vendor-*.js",
      "limit": "50 KB",
      "gzip": true
    }
  ],
  "scripts": {
    "size": "size-limit",
    "size:why": "size-limit --why"
  }
}
```

### 13.5 Common Tree-Shaking Blockers

```typescript
// BLOCKER 1: Barrel exports (index.ts re-exports)
// BAD - imports everything
import { Button } from '@/components';

// GOOD - direct imports
import { Button } from '@/components/ui/button';

// BLOCKER 2: CommonJS modules
// BAD - lodash full bundle
import _ from 'lodash';
_.debounce(fn, 300);

// GOOD - ES module import
import debounce from 'lodash-es/debounce';
// OR use dedicated package
import { debounce } from 'lodash-es';

// BLOCKER 3: Side effects in module scope
// BAD
const analytics = initAnalytics(); // Runs on import
export const track = (event) => analytics.track(event);

// GOOD - lazy initialization
let analytics: Analytics | null = null;
export const track = (event) => {
  if (!analytics) analytics = initAnalytics();
  analytics.track(event);
};

// BLOCKER 4: Class with static properties
// BAD - entire class imported
class Utils {
  static formatDate(d: Date) { ... }
  static formatCurrency(n: number) { ... }
  static doExpensiveThing() { ... }
}

// GOOD - individual functions
export const formatDate = (d: Date) => { ... };
export const formatCurrency = (n: number) => { ... };

// BLOCKER 5: Dynamic property access
// BAD - prevents tree shaking
const icons = { home: HomeIcon, settings: SettingsIcon };
const Icon = icons[iconName];

// GOOD - explicit imports
const iconMap = {
  home: lazy(() => import('./icons/home')),
  settings: lazy(() => import('./icons/settings')),
};
```

### 13.6 Dependency Optimization Checklist

```markdown
### Bundle Optimization Checklist

#### Package Selection
- [ ] Use `date-fns` instead of `moment` (tree-shakeable)
- [ ] Use `lodash-es` instead of `lodash`
- [ ] Check bundlephobia.com before adding dependencies
- [ ] Prefer native APIs over polyfills when possible

#### Import Patterns
- [ ] Direct imports, not barrel exports
- [ ] Dynamic imports for heavy features
- [ ] Lazy load routes with React.lazy

#### Configuration
- [ ] `sideEffects: false` in package.json
- [ ] Terser compression enabled
- [ ] console.log removed in production
- [ ] Source maps disabled in production

#### Monitoring
- [ ] Bundle analyzer in CI
- [ ] size-limit checks on PR
- [ ] Target: < 100KB initial JS (gzipped)
```

---

## 14. CONTENT INDEXING API

### 14.1 Register Searchable Content

```typescript
// lib/contentIndexing.ts

interface ContentDescription {
  id: string;
  title: string;
  description: string;
  category: string;
  url: string;
  icons?: {
    src: string;
    sizes: string;
    type: string;
  }[];
  launchUrl?: string;
}

/**
 * Check if Content Indexing API is supported
 */
export function isContentIndexingSupported(): boolean {
  return 'index' in (navigator.serviceWorker?.controller ?? {});
}

/**
 * Add content to the device's content index
 * Makes content searchable and discoverable offline
 */
export async function addToContentIndex(
  content: ContentDescription
): Promise<boolean> {
  if (!isContentIndexingSupported()) {
    console.warn('Content Indexing API not supported');
    return false;
  }

  try {
    const registration = await navigator.serviceWorker.ready;

    // Access the index on the registration
    const index = (registration as any).index;

    await index.add({
      id: content.id,
      title: content.title,
      description: content.description,
      category: content.category,
      url: content.url,
      icons: content.icons ?? [
        {
          src: '/icons/icon-192.png',
          sizes: '192x192',
          type: 'image/png',
        },
      ],
    });

    console.log(`[ContentIndex] Added: ${content.title}`);
    return true;
  } catch (error) {
    console.error('[ContentIndex] Failed to add:', error);
    return false;
  }
}

/**
 * Add multiple content items in batch
 */
export async function addBatchToContentIndex(
  items: ContentDescription[]
): Promise<{ success: number; failed: number }> {
  let success = 0;
  let failed = 0;

  for (const item of items) {
    const result = await addToContentIndex(item);
    if (result) success++;
    else failed++;
  }

  return { success, failed };
}
```

### 14.2 Update Content Index

```typescript
/**
 * Update existing content in the index
 * Content Indexing API uses upsert semantics - same ID replaces
 */
export async function updateContentIndex(
  content: ContentDescription
): Promise<boolean> {
  // Content Indexing uses upsert - add with same ID updates
  return addToContentIndex(content);
}

/**
 * Sync content index with server data
 */
export async function syncContentIndex(
  serverContent: ContentDescription[]
): Promise<void> {
  if (!isContentIndexingSupported()) return;

  try {
    const registration = await navigator.serviceWorker.ready;
    const index = (registration as any).index;

    // Get current indexed content
    const currentItems: { id: string }[] = await index.getAll();
    const currentIds = new Set(currentItems.map((item) => item.id));
    const serverIds = new Set(serverContent.map((item) => item.id));

    // Remove items no longer on server
    for (const id of currentIds) {
      if (!serverIds.has(id)) {
        await index.delete(id);
        console.log(`[ContentIndex] Removed: ${id}`);
      }
    }

    // Add/update items from server
    for (const item of serverContent) {
      await addToContentIndex(item);
    }

    console.log(`[ContentIndex] Synced ${serverContent.length} items`);
  } catch (error) {
    console.error('[ContentIndex] Sync failed:', error);
  }
}
```

### 14.3 Delete from Index

```typescript
/**
 * Remove content from the index
 */
export async function removeFromContentIndex(id: string): Promise<boolean> {
  if (!isContentIndexingSupported()) return false;

  try {
    const registration = await navigator.serviceWorker.ready;
    const index = (registration as any).index;

    await index.delete(id);
    console.log(`[ContentIndex] Removed: ${id}`);
    return true;
  } catch (error) {
    console.error('[ContentIndex] Failed to remove:', error);
    return false;
  }
}

/**
 * Clear all content from the index
 */
export async function clearContentIndex(): Promise<boolean> {
  if (!isContentIndexingSupported()) return false;

  try {
    const registration = await navigator.serviceWorker.ready;
    const index = (registration as any).index;

    const items: { id: string }[] = await index.getAll();

    for (const item of items) {
      await index.delete(item.id);
    }

    console.log(`[ContentIndex] Cleared ${items.length} items`);
    return true;
  } catch (error) {
    console.error('[ContentIndex] Failed to clear:', error);
    return false;
  }
}

/**
 * Get all indexed content
 */
export async function getIndexedContent(): Promise<ContentDescription[]> {
  if (!isContentIndexingSupported()) return [];

  try {
    const registration = await navigator.serviceWorker.ready;
    const index = (registration as any).index;

    return await index.getAll();
  } catch (error) {
    console.error('[ContentIndex] Failed to get content:', error);
    return [];
  }
}
```

### 14.4 Integration with Offline Search

```typescript
// lib/offlineSearch.ts
import { openDB, DBSchema } from 'idb';
import { addToContentIndex, removeFromContentIndex } from './contentIndexing';

interface SearchableContent {
  id: string;
  title: string;
  description: string;
  body: string;
  category: string;
  url: string;
  keywords: string[];
  updatedAt: string;
}

interface SearchDB extends DBSchema {
  content: {
    key: string;
    value: SearchableContent;
    indexes: {
      'by-category': string;
      'by-updated': string;
    };
  };
}

/**
 * Add content to both IndexedDB (for full search) and Content Index (for system search)
 */
export async function indexContent(content: SearchableContent): Promise<void> {
  const db = await openDB<SearchDB>('search-db', 1, {
    upgrade(db) {
      const store = db.createObjectStore('content', { keyPath: 'id' });
      store.createIndex('by-category', 'category');
      store.createIndex('by-updated', 'updatedAt');
    },
  });

  // Save to IndexedDB for full-text search
  await db.put('content', content);

  // Add to Content Index for system-level discovery
  await addToContentIndex({
    id: content.id,
    title: content.title,
    description: content.description,
    category: content.category,
    url: content.url,
  });
}

/**
 * Search content offline
 */
export async function searchOffline(query: string): Promise<SearchableContent[]> {
  if (!query.trim()) return [];

  const db = await openDB<SearchDB>('search-db', 1);
  const allContent = await db.getAll('content');

  const lowerQuery = query.toLowerCase();

  return allContent.filter((item) => {
    return (
      item.title.toLowerCase().includes(lowerQuery) ||
      item.description.toLowerCase().includes(lowerQuery) ||
      item.body.toLowerCase().includes(lowerQuery) ||
      item.keywords.some((kw) => kw.toLowerCase().includes(lowerQuery))
    );
  });
}

/**
 * Remove content from both indexes
 */
export async function removeContent(id: string): Promise<void> {
  const db = await openDB<SearchDB>('search-db', 1);
  await db.delete('content', id);
  await removeFromContentIndex(id);
}
```

### 14.5 Content Indexing Hook

```typescript
// hooks/useContentIndex.ts
import { useState, useEffect } from 'react';
import {
  isContentIndexingSupported,
  getIndexedContent,
  addToContentIndex,
  removeFromContentIndex,
  syncContentIndex,
  type ContentDescription,
} from '@/lib/contentIndexing';

export function useContentIndex() {
  const [isSupported] = useState(isContentIndexingSupported);
  const [content, setContent] = useState<ContentDescription[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // React Compiler auto-memoizes — no manual useCallback needed
  const refresh = async () => {
    if (!isSupported) return;
    setIsLoading(true);
    const items = await getIndexedContent();
    setContent(items);
    setIsLoading(false);
  };

  const add = async (item: ContentDescription) => {
    const success = await addToContentIndex(item);
    if (success) await refresh();
    return success;
  };

  const remove = async (id: string) => {
    const success = await removeFromContentIndex(id);
    if (success) await refresh();
    return success;
  };

  const sync = async (serverContent: ContentDescription[]) => {
    await syncContentIndex(serverContent);
    await refresh();
  };

  useEffect(() => {
    refresh();
  }, []);

  return {
    isSupported,
    content,
    isLoading,
    add,
    remove,
    sync,
    refresh,
  };
}
```

---

## 15. BADGE API

### 15.1 setAppBadge() Implementation

```typescript
// lib/badgeApi.ts

/**
 * Check if Badge API is supported
 */
export function isBadgeSupported(): boolean {
  return 'setAppBadge' in navigator;
}

/**
 * Set app badge with count
 * @param count - Number to display (0 clears badge on some platforms)
 */
export async function setAppBadge(count: number): Promise<boolean> {
  if (!isBadgeSupported()) {
    console.warn('Badge API not supported');
    return false;
  }

  try {
    // Ensure count is a positive integer
    const sanitizedCount = Math.max(0, Math.floor(count));

    await navigator.setAppBadge(sanitizedCount);
    console.log(`[Badge] Set to ${sanitizedCount}`);
    return true;
  } catch (error) {
    // Handle permission denial gracefully
    if (error instanceof DOMException && error.name === 'NotAllowedError') {
      console.warn('[Badge] Permission denied');
      return false;
    }
    console.error('[Badge] Failed to set:', error);
    return false;
  }
}

/**
 * Set badge without specific count (shows indicator dot)
 */
export async function setAppBadgeIndicator(): Promise<boolean> {
  if (!isBadgeSupported()) return false;

  try {
    await navigator.setAppBadge();
    console.log('[Badge] Indicator set');
    return true;
  } catch (error) {
    console.error('[Badge] Failed to set indicator:', error);
    return false;
  }
}
```

### 15.2 clearAppBadge() Implementation

```typescript
/**
 * Clear app badge
 */
export async function clearAppBadge(): Promise<boolean> {
  if (!isBadgeSupported()) return false;

  try {
    await navigator.clearAppBadge();
    console.log('[Badge] Cleared');
    return true;
  } catch (error) {
    if (error instanceof DOMException && error.name === 'NotAllowedError') {
      console.warn('[Badge] Permission denied for clear');
      return false;
    }
    console.error('[Badge] Failed to clear:', error);
    return false;
  }
}

/**
 * Update badge based on unread count from server/local storage
 */
export async function syncBadgeWithUnreadCount(): Promise<void> {
  // Get unread count from your data source
  const unreadCount = await getUnreadNotificationCount();

  if (unreadCount > 0) {
    await setAppBadge(unreadCount);
  } else {
    await clearAppBadge();
  }
}

async function getUnreadNotificationCount(): Promise<number> {
  // Implement based on your data source
  // Example: from IndexedDB
  const db = await openDB('notifications-db', 1);
  const unread = await db.getAllFromIndex('notifications', 'by-read', false);
  return unread.length;
}
```

### 15.3 Permission Handling

```typescript
/**
 * Badge API doesn't require explicit permission request
 * but may be denied in certain contexts
 */
export async function checkBadgePermission(): Promise<'granted' | 'denied' | 'unsupported'> {
  if (!isBadgeSupported()) {
    return 'unsupported';
  }

  // Try to set a badge to check permission
  try {
    await navigator.setAppBadge(0);
    await navigator.clearAppBadge();
    return 'granted';
  } catch (error) {
    if (error instanceof DOMException && error.name === 'NotAllowedError') {
      return 'denied';
    }
    // Other errors might indicate temporary issues
    return 'granted';
  }
}

/**
 * Badge works best when triggered from:
 * 1. User interaction (click handlers)
 * 2. Push notification handlers
 * 3. Service worker events
 */
export function setupBadgeFromServiceWorker() {
  // In sw.ts - update badge on push
  self.addEventListener('push', async (event) => {
    const data = event.data?.json() ?? {};

    // Update badge count from push payload
    if (typeof data.unreadCount === 'number') {
      await self.navigator.setAppBadge(data.unreadCount);
    }
  });
}
```

### 15.4 iOS vs Android Differences

```typescript
// lib/badgePlatform.ts

interface BadgePlatformSupport {
  platform: 'ios' | 'android' | 'desktop' | 'unknown';
  supported: boolean;
  limitations: string[];
}

/**
 * Get platform-specific badge support info
 */
export function getBadgePlatformSupport(): BadgePlatformSupport {
  const ua = navigator.userAgent;

  // iOS (Safari 16.4+ on iOS, PWA only)
  if (/iPad|iPhone|iPod/.test(ua)) {
    const isPWA = (window.navigator as any).standalone === true;
    return {
      platform: 'ios',
      supported: isPWA && isBadgeSupported(),
      limitations: [
        'Only works in installed PWA (Add to Home Screen)',
        'Requires Safari 16.4+ / iOS 16.4+',
        'Badge clears when app opens',
      ],
    };
  }

  // Android (Chrome 81+)
  if (/Android/.test(ua)) {
    return {
      platform: 'android',
      supported: isBadgeSupported(),
      limitations: [
        'Only works in installed PWA',
        'Max count display varies by launcher',
        'Some launchers ignore badge API',
      ],
    };
  }

  // Desktop (Chrome 81+, Edge 81+)
  return {
    platform: 'desktop',
    supported: isBadgeSupported(),
    limitations: [
      'Windows: Taskbar badge (installed PWA)',
      'macOS: Dock badge (installed PWA)',
      'Linux: Limited support',
    ],
  };
}

/**
 * Safe badge update with platform awareness
 */
export async function updateBadgeSafely(count: number): Promise<void> {
  const platformInfo = getBadgePlatformSupport();

  if (!platformInfo.supported) {
    console.log(`[Badge] Not supported on ${platformInfo.platform}`);
    return;
  }

  // Platform-specific handling
  if (platformInfo.platform === 'android') {
    // Some Android launchers only show "has notification" vs specific count
    // Consider using setAppBadge() without count for consistency
    if (count > 0) {
      await setAppBadge(count);
    } else {
      await clearAppBadge();
    }
  } else {
    // iOS and desktop handle counts well
    if (count > 0) {
      await setAppBadge(count);
    } else {
      await clearAppBadge();
    }
  }
}
```

### 15.5 Badge Hook

```typescript
// hooks/useBadge.ts
import { useState, useEffect } from 'react';
import {
  isBadgeSupported,
  setAppBadge,
  clearAppBadge,
  checkBadgePermission,
  getBadgePlatformSupport,
} from '@/lib/badgeApi';

export function useBadge() {
  const [isSupported] = useState(isBadgeSupported);
  const [permission, setPermission] = useState<'granted' | 'denied' | 'unsupported'>('unsupported');
  const [currentCount, setCurrentCount] = useState(0);
  const [platformInfo] = useState(getBadgePlatformSupport);

  useEffect(() => {
    checkBadgePermission().then(setPermission);
  }, []);

  // React Compiler auto-memoizes — no manual useCallback needed
  const setBadge = async (count: number) => {
    const success = await setAppBadge(count);
    if (success) setCurrentCount(count);
    return success;
  };

  const clearBadge = async () => {
    const success = await clearAppBadge();
    if (success) setCurrentCount(0);
    return success;
  };

  const incrementBadge = async () => {
    const newCount = currentCount + 1;
    return setBadge(newCount);
  };

  const decrementBadge = async () => {
    const newCount = Math.max(0, currentCount - 1);
    if (newCount === 0) {
      return clearBadge();
    }
    return setBadge(newCount);
  };

  return {
    isSupported,
    permission,
    currentCount,
    platformInfo,
    setBadge,
    clearBadge,
    incrementBadge,
    decrementBadge,
  };
}
```

---

## 16. PERIODIC BACKGROUND SYNC

### 16.1 Register Periodic Sync

```typescript
// lib/periodicSync.ts

/**
 * Check if Periodic Background Sync is supported
 * Requires: Chrome 80+, installed PWA, site engagement
 */
export function isPeriodicSyncSupported(): boolean {
  return 'periodicSync' in (navigator.serviceWorker?.controller ?? {}) ||
    ('serviceWorker' in navigator && 'PeriodicSyncManager' in window);
}

/**
 * Check permission status for periodic sync
 */
export async function getPeriodicSyncPermission(): Promise<PermissionState> {
  try {
    const status = await navigator.permissions.query({
      name: 'periodic-background-sync' as PermissionName,
    });
    return status.state;
  } catch {
    return 'denied';
  }
}

/**
 * Register a periodic background sync task
 * @param tag - Unique identifier for the sync task
 * @param minInterval - Minimum interval in milliseconds (browser may increase)
 */
export async function registerPeriodicSync(
  tag: string,
  minInterval: number = 24 * 60 * 60 * 1000 // Default: 24 hours
): Promise<boolean> {
  if (!isPeriodicSyncSupported()) {
    console.warn('Periodic Background Sync not supported');
    return false;
  }

  try {
    const registration = await navigator.serviceWorker.ready;
    const periodicSync = (registration as any).periodicSync;

    if (!periodicSync) {
      console.warn('Periodic sync not available on registration');
      return false;
    }

    // Check permission first
    const permission = await getPeriodicSyncPermission();
    if (permission !== 'granted') {
      console.warn(`Periodic sync permission: ${permission}`);
      return false;
    }

    await periodicSync.register(tag, {
      minInterval,
    });

    console.log(`[PeriodicSync] Registered: ${tag} (min interval: ${minInterval}ms)`);
    return true;
  } catch (error) {
    console.error('[PeriodicSync] Registration failed:', error);
    return false;
  }
}

/**
 * Unregister a periodic sync task
 */
export async function unregisterPeriodicSync(tag: string): Promise<boolean> {
  if (!isPeriodicSyncSupported()) return false;

  try {
    const registration = await navigator.serviceWorker.ready;
    const periodicSync = (registration as any).periodicSync;

    await periodicSync.unregister(tag);
    console.log(`[PeriodicSync] Unregistered: ${tag}`);
    return true;
  } catch (error) {
    console.error('[PeriodicSync] Unregistration failed:', error);
    return false;
  }
}

/**
 * Get all registered periodic sync tags
 */
export async function getPeriodicSyncTags(): Promise<string[]> {
  if (!isPeriodicSyncSupported()) return [];

  try {
    const registration = await navigator.serviceWorker.ready;
    const periodicSync = (registration as any).periodicSync;

    const tags = await periodicSync.getTags();
    return tags;
  } catch (error) {
    console.error('[PeriodicSync] Failed to get tags:', error);
    return [];
  }
}
```

### 16.2 Handle Sync Event in Service Worker

```typescript
// Add to sw.ts

declare const self: ServiceWorkerGlobalScope;

// Periodic sync event handler
self.addEventListener('periodicsync', (event: ExtendableEvent & { tag: string }) => {
  const tag = event.tag;

  console.log(`[SW] Periodic sync triggered: ${tag}`);

  if (tag === 'content-sync') {
    event.waitUntil(syncContent());
  }

  if (tag === 'analytics-sync') {
    event.waitUntil(syncAnalytics());
  }

  if (tag === 'cache-refresh') {
    event.waitUntil(refreshCriticalCache());
  }
});

async function syncContent(): Promise<void> {
  try {
    // Fetch latest content from server
    const response = await fetch('/api/content/latest');
    const content = await response.json();

    // Update IndexedDB
    const db = await openDB('content-db', 1);
    for (const item of content.items) {
      await db.put('content', item);
    }

    // Update cache
    const cache = await caches.open('content-cache');
    for (const item of content.items) {
      const itemResponse = await fetch(item.url);
      await cache.put(item.url, itemResponse);
    }

    console.log(`[SW] Synced ${content.items.length} content items`);
  } catch (error) {
    console.error('[SW] Content sync failed:', error);
    throw error; // Retry on next sync
  }
}

async function syncAnalytics(): Promise<void> {
  try {
    const db = await openDB('analytics-db', 1);
    const pendingEvents = await db.getAll('pending-events');

    if (pendingEvents.length === 0) return;

    // Batch send to server
    const response = await fetch('/api/analytics/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ events: pendingEvents }),
    });

    if (response.ok) {
      // Clear sent events
      const tx = db.transaction('pending-events', 'readwrite');
      await tx.objectStore('pending-events').clear();
      await tx.done;

      console.log(`[SW] Synced ${pendingEvents.length} analytics events`);
    }
  } catch (error) {
    console.error('[SW] Analytics sync failed:', error);
    throw error;
  }
}

async function refreshCriticalCache(): Promise<void> {
  const criticalUrls = [
    '/',
    '/offline',
    '/manifest.json',
  ];

  const cache = await caches.open('critical-cache');

  for (const url of criticalUrls) {
    try {
      const response = await fetch(url, { cache: 'no-cache' });
      if (response.ok) {
        await cache.put(url, response);
      }
    } catch {
      // Ignore failures - keep existing cache
    }
  }

  console.log('[SW] Refreshed critical cache');
}
```

### 16.3 Quotas and Limitations

```typescript
// lib/periodicSyncLimits.ts

/**
 * Periodic Background Sync limitations and quotas
 */
export const PERIODIC_SYNC_LIMITS = {
  // Minimum intervals by site engagement score
  // Browser may increase these based on actual engagement
  intervals: {
    highEngagement: 12 * 60 * 60 * 1000, // 12 hours minimum
    mediumEngagement: 24 * 60 * 60 * 1000, // 24 hours minimum
    lowEngagement: 7 * 24 * 60 * 60 * 1000, // 7 days or disabled
  },

  // Maximum number of registered syncs
  maxRegistrations: 10,

  // Battery and network requirements
  requirements: {
    requiresCharging: false, // Browser decides
    requiresNetwork: true, // Must have connectivity
    requiresIdle: false, // Browser decides
  },
};

/**
 * Get recommended sync interval based on content type
 */
export function getRecommendedInterval(contentType: string): number {
  const intervals: Record<string, number> = {
    // Critical updates - shortest allowed
    news: 12 * 60 * 60 * 1000, // 12 hours

    // Regular updates
    content: 24 * 60 * 60 * 1000, // 24 hours
    analytics: 24 * 60 * 60 * 1000, // 24 hours

    // Infrequent updates
    cache: 7 * 24 * 60 * 60 * 1000, // 7 days
    cleanup: 7 * 24 * 60 * 60 * 1000, // 7 days
  };

  return intervals[contentType] ?? 24 * 60 * 60 * 1000;
}

/**
 * Check if device conditions are suitable for sync
 */
export async function isSyncConditionsMet(): Promise<boolean> {
  // Check network
  if (!navigator.onLine) return false;

  // Check connection type (if available)
  const connection = (navigator as any).connection;
  if (connection) {
    // Avoid sync on slow connections
    if (connection.effectiveType === 'slow-2g' || connection.effectiveType === '2g') {
      return false;
    }

    // Avoid sync if data saver is enabled
    if (connection.saveData) {
      return false;
    }
  }

  // Check battery (if available)
  if ('getBattery' in navigator) {
    try {
      const battery = await (navigator as any).getBattery();
      // Skip sync if battery < 20% and not charging
      if (battery.level < 0.2 && !battery.charging) {
        return false;
      }
    } catch {
      // Battery API not available, continue
    }
  }

  return true;
}
```

### 16.4 Fallback Strategies

```typescript
// lib/syncFallback.ts

interface SyncOptions {
  tag: string;
  minInterval: number;
  syncFn: () => Promise<void>;
}

/**
 * Register sync with automatic fallback
 * Falls back to:
 * 1. Regular Background Sync (on network change)
 * 2. Visibility-based sync (on page visible)
 * 3. Manual timer (worst case)
 */
export async function registerSyncWithFallback(options: SyncOptions): Promise<void> {
  const { tag, minInterval, syncFn } = options;

  // Try Periodic Background Sync first
  const periodicSyncSuccess = await registerPeriodicSync(tag, minInterval);

  if (periodicSyncSuccess) {
    console.log(`[Sync] Using Periodic Background Sync for ${tag}`);
    return;
  }

  // Fallback 1: Regular Background Sync on network change
  if ('SyncManager' in window) {
    console.log(`[Sync] Falling back to Background Sync for ${tag}`);
    setupBackgroundSyncFallback(tag, syncFn);
    return;
  }

  // Fallback 2: Visibility-based sync
  console.log(`[Sync] Falling back to visibility-based sync for ${tag}`);
  setupVisibilityFallback(tag, minInterval, syncFn);
}

function setupBackgroundSyncFallback(tag: string, syncFn: () => Promise<void>): void {
  // Register one-time sync on network events
  window.addEventListener('online', async () => {
    try {
      const registration = await navigator.serviceWorker.ready;
      await (registration as any).sync.register(`fallback-${tag}`);
    } catch {
      // Direct execution fallback
      await syncFn();
    }
  });

  // Also sync on visibility change
  document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState === 'visible' && navigator.onLine) {
      await syncFn();
    }
  });
}

function setupVisibilityFallback(
  tag: string,
  minInterval: number,
  syncFn: () => Promise<void>
): void {
  const STORAGE_KEY = `last-sync-${tag}`;

  const checkAndSync = async () => {
    const lastSync = parseInt(localStorage.getItem(STORAGE_KEY) ?? '0');
    const now = Date.now();

    if (now - lastSync >= minInterval) {
      try {
        await syncFn();
        localStorage.setItem(STORAGE_KEY, now.toString());
      } catch (error) {
        console.error(`[Sync] Fallback sync failed for ${tag}:`, error);
      }
    }
  };

  // Sync on visibility change
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      checkAndSync();
    }
  });

  // Sync on focus
  window.addEventListener('focus', checkAndSync);

  // Initial check
  checkAndSync();
}

/**
 * Manual sync trigger with debouncing
 */
export function createManualSync(syncFn: () => Promise<void>, debounceMs = 5000) {
  let lastSync = 0;
  let pending = false;

  return async () => {
    const now = Date.now();

    if (pending) return;
    if (now - lastSync < debounceMs) return;

    pending = true;
    try {
      await syncFn();
      lastSync = Date.now();
    } finally {
      pending = false;
    }
  };
}
```

### 16.5 Periodic Sync Hook

```typescript
// hooks/usePeriodicSync.ts
import { useState, useEffect } from 'react';
import {
  isPeriodicSyncSupported,
  registerPeriodicSync,
  unregisterPeriodicSync,
  getPeriodicSyncTags,
  getPeriodicSyncPermission,
} from '@/lib/periodicSync';

interface PeriodicSyncConfig {
  tag: string;
  minInterval: number;
  enabled: boolean;
}

export function usePeriodicSync(configs: PeriodicSyncConfig[]) {
  const [isSupported] = useState(isPeriodicSyncSupported);
  const [permission, setPermission] = useState<PermissionState>('prompt');
  const [registeredTags, setRegisteredTags] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // React Compiler auto-memoizes — no manual useCallback needed
  const refresh = async () => {
    setIsLoading(true);
    const [perm, tags] = await Promise.all([
      getPeriodicSyncPermission(),
      getPeriodicSyncTags(),
    ]);
    setPermission(perm);
    setRegisteredTags(tags);
    setIsLoading(false);
  };

  const syncConfigs = async () => {
    if (!isSupported) return;

    for (const config of configs) {
      if (config.enabled) {
        await registerPeriodicSync(config.tag, config.minInterval);
      } else {
        await unregisterPeriodicSync(config.tag);
      }
    }

    await refresh();
  };

  const register = async (tag: string, minInterval: number) => {
    const success = await registerPeriodicSync(tag, minInterval);
    if (success) await refresh();
    return success;
  };

  const unregister = async (tag: string) => {
    const success = await unregisterPeriodicSync(tag);
    if (success) await refresh();
    return success;
  };

  useEffect(() => {
    refresh();
  }, []);

  return {
    isSupported,
    permission,
    registeredTags,
    isLoading,
    register,
    unregister,
    syncConfigs,
    refresh,
  };
}
```

### 16.6 Periodic Sync Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| Chrome Android | 80+ | Requires PWA install + site engagement |
| Chrome Desktop | 80+ | Requires PWA install + site engagement |
| Edge | 80+ | Same as Chrome |
| Firefox | No | No plans announced |
| Safari | No | No plans announced |
| Samsung Internet | No | Not implemented |

**Key Requirements for Periodic Sync:**
1. PWA must be installed (Add to Home Screen)
2. Site must have sufficient user engagement score
3. Permission must be granted (automatic based on engagement)
4. Browser controls actual interval (may be longer than requested)
5. Sync only fires when device has network connectivity

---

## 17. ADVANCED MANIFEST APIs

These cutting-edge manifest APIs enable desktop-class experiences in PWAs, allowing deep OS integration for file handling, custom protocols, window customization, and navigation control.

> **Note:** Due to document size constraints, refer to the comprehensive reference at:
> `~/.claude/skills/pwa-expert/references/pwa-manifest-complete.md`

### 17.1 File Handling API - Enables PWA registration as file handler
### 17.2 Protocol Handlers - Custom URL protocol support
### 17.3 Window Controls Overlay (WCO) - Custom title bar
### 17.4 Scope Extensions - Multi-origin PWA support
### 17.5 Declarative Link Capturing - Control external link behavior
### 17.6 Complete Advanced Manifest Example
### 17.7 Feature Detection Pattern

---

## 18. REFLEXION LOOP INTEGRATION

> **SINGULARITY FORGE v24.5.0 - Reflexion Loop Protocol**

### 18.1 Reflexion Loop for PWA Development

The Reflexion Loop ensures continuous improvement and self-correction in PWA implementation.

```typescript
// lib/pwa/reflexionLoop.ts

interface ReflexionResult {
  phase: 'analyze' | 'implement' | 'verify' | 'improve';
  findings: string[];
  actions: string[];
  success: boolean;
}

/**
 * PWA Reflexion Loop Implementation
 * Self-correcting development pattern
 */
export async function runPWAReflexion(): Promise<ReflexionResult[]> {
  const results: ReflexionResult[] = [];

  // Phase 1: Analyze current PWA state
  results.push(await analyzePhase());

  // Phase 2: Implement improvements
  results.push(await implementPhase(results[0]));

  // Phase 3: Verify changes
  results.push(await verifyPhase());

  // Phase 4: Document learnings
  results.push(await improvePhase(results));

  return results;
}

async function analyzePhase(): Promise<ReflexionResult> {
  const findings: string[] = [];

  // Check SW registration
  if ('serviceWorker' in navigator) {
    const reg = await navigator.serviceWorker.getRegistration();
    if (!reg) findings.push('Service Worker not registered');
    if (reg?.waiting) findings.push('Service Worker update pending');
  }

  // Check manifest
  const link = document.querySelector('link[rel="manifest"]');
  if (!link) findings.push('Manifest link missing');

  // Check offline capability
  if (!navigator.onLine) {
    findings.push('Currently offline - testing offline mode');
  }

  return {
    phase: 'analyze',
    findings,
    actions: findings.map(f => `Address: ${f}`),
    success: findings.length === 0,
  };
}
```

### 18.2 Self-Correcting Error Handler

```typescript
// lib/pwa/selfCorrectingHandler.ts

/**
 * Self-correcting error handler with reflexion
 */
export function createSelfCorrectingHandler() {
  const errorLog: Array<{ error: Error; timestamp: number; corrected: boolean }> = [];

  return {
    handle: async (error: Error, context: string) => {
      errorLog.push({ error, timestamp: Date.now(), corrected: false });

      // Attempt self-correction based on error type
      if (error.name === 'QuotaExceededError') {
        await autoCleanupIfNeeded();
        errorLog[errorLog.length - 1].corrected = true;
      }

      if (error.message.includes('ServiceWorker')) {
        await navigator.serviceWorker.getRegistration()
          .then(reg => reg?.update());
        errorLog[errorLog.length - 1].corrected = true;
      }

      // Log for future reflexion
      console.warn(`[Reflexion] Error in ${context}:`, error.message);
    },

    getErrorPatterns: () => {
      // Analyze error patterns for improvement
      return errorLog.reduce((acc, { error }) => {
        acc[error.name] = (acc[error.name] || 0) + 1;
        return acc;
      }, {} as Record<string, number>);
    },
  };
}
```

---

## 19. MEMORY MCP INTEGRATION

> **SINGULARITY FORGE v24.5.0 - Memory MCP Protocol**

### 19.1 PWA State Persistence with Memory MCP

```typescript
// lib/pwa/memoryMCP.ts

interface PWAMemoryState {
  lastSWUpdate: string;
  cacheVersion: string;
  offlinePages: string[];
  syncQueue: number;
  installDate: string | null;
  featureUsage: Record<string, number>;
}

/**
 * Memory MCP Integration for PWA
 * Persists critical state across sessions
 */
export const pwaMemoryMCP = {
  /**
   * Save PWA state to Memory MCP
   */
  async save(state: Partial<PWAMemoryState>): Promise<void> {
    const current = await this.load();
    const merged = { ...current, ...state, lastUpdated: new Date().toISOString() };

    // Store in IndexedDB for offline access
    const db = await openDB('pwa-memory', 1, {
      upgrade(db) {
        db.createObjectStore('state', { keyPath: 'id' });
      },
    });

    await db.put('state', { id: 'pwa-state', ...merged });

    // Also notify Memory MCP if available
    if (typeof window !== 'undefined' && (window as any).memoryMCP) {
      await (window as any).memoryMCP.store('pwa-state', merged);
    }
  },

  /**
   * Load PWA state from Memory MCP
   */
  async load(): Promise<PWAMemoryState> {
    const defaults: PWAMemoryState = {
      lastSWUpdate: '',
      cacheVersion: '1.0.0',
      offlinePages: [],
      syncQueue: 0,
      installDate: null,
      featureUsage: {},
    };

    try {
      const db = await openDB('pwa-memory', 1);
      const stored = await db.get('state', 'pwa-state');
      return stored ? { ...defaults, ...stored } : defaults;
    } catch {
      return defaults;
    }
  },

  /**
   * Track feature usage for optimization
   */
  async trackFeature(feature: string): Promise<void> {
    const state = await this.load();
    state.featureUsage[feature] = (state.featureUsage[feature] || 0) + 1;
    await this.save({ featureUsage: state.featureUsage });
  },
};
```

---

## 20. CONTEXT7 PROTOCOL

> **SINGULARITY FORGE v24.5.0 - Context7 Protocol**

### 20.1 Context7 for PWA Documentation Lookup

```typescript
// lib/pwa/context7.ts

/**
 * Context7 Protocol for PWA
 * Provides accurate, up-to-date API documentation
 */
export const context7PWA = {
  /**
   * Get documentation for PWA APIs
   */
  async getDocumentation(api: string): Promise<string> {
    const docs: Record<string, string> = {
      'service-worker': `
        Service Worker Lifecycle:
        1. Register: navigator.serviceWorker.register('/sw.js')
        2. Install: self.addEventListener('install', ...)
        3. Activate: self.addEventListener('activate', ...)
        4. Fetch: self.addEventListener('fetch', ...)
      `,
      'push-api': `
        Push Notification Flow:
        1. Request permission: Notification.requestPermission()
        2. Subscribe: registration.pushManager.subscribe()
        3. Handle push: self.addEventListener('push', ...)
        4. Show notification: self.registration.showNotification()
      `,
      'background-sync': `
        Background Sync Pattern:
        1. Register: registration.sync.register('sync-tag')
        2. Handle: self.addEventListener('sync', ...)
        3. Retry: throw error to retry later
      `,
    };

    return docs[api] || 'Documentation not found. Use `/skill pwa-expert` for full reference.';
  },

  /**
   * Resolve library versions for PWA dependencies
   */
  async resolveLibrary(name: string): Promise<{ version: string; docs: string }> {
    const libraries: Record<string, { version: string; docs: string }> = {
      'serwist': { version: '9.x', docs: 'https://serwist.pages.dev' },
      'idb': { version: '8.x', docs: 'https://github.com/jakearchibald/idb' },
      '@tanstack/react-query': { version: '5.x', docs: 'https://tanstack.com/query' },
    };

    return libraries[name] || { version: 'unknown', docs: '' };
  },
};
```

---

## 21. 30-GATE VERIFICATION

> **SINGULARITY FORGE v24.5.0 - 30-Gate Matrix**

### 21.1 PWA-Specific Gate Verification

| Gate | Category | PWA Requirement | Validation |
|------|----------|-----------------|------------|
| G-PWA-01 | Core | Service Worker registered | `navigator.serviceWorker.controller` |
| G-PWA-02 | Core | Manifest valid | Lighthouse PWA audit |
| G-PWA-03 | Core | HTTPS enforced | `location.protocol === 'https:'` |
| G-PWA-04 | Offline | Offline fallback works | Network simulation test |
| G-PWA-05 | Offline | Cache strategies correct | Manual verification |
| G-PWA-06 | Install | Installable | beforeinstallprompt fires |
| G-PWA-07 | Install | Icons all sizes | 192, 512, maskable |
| G-PWA-08 | Performance | Bundle < 100KB | Build analysis |
| G-PWA-09 | Performance | LCP < 1.5s | Lighthouse |
| G-PWA-10 | Security | CSP configured | Header check |
| G-PWA-11 | RTL | dir="rtl" in manifest | Manifest validation |
| G-PWA-12 | RTL | Logical properties used | Code review |
| G-PWA-13 | Memory | RAM-tier strategies active | Device memory check |
| G-PWA-14 | Platform | UI identical iOS/Android | Visual regression test |
| G-PWA-15 | WebView | "Open in Browser" shown | WebView detection |
| G-PWA-16 | Battery | OEM whitelist guidance shown | Battery API check |
| G-PWA-17 | NVIDIA | Navigation preload enabled | SW configuration |
| G-PWA-18 | NVIDIA | Streaming responses active | Response type check |
| G-PWA-19 | NVIDIA | Brotli compression enabled | Content-Encoding check |
| G-PWA-20 | NVIDIA | Module preload optimized | Link preload audit |
| G-PWA-21 | Advanced | BFCache compatible | bfcache test |
| G-PWA-22 | Advanced | Speculation rules active | Document rules check |

### 21.2 Automated Gate Checker

```typescript
// lib/pwa/gateChecker.ts

interface GateResult {
  gate: string;
  passed: boolean;
  message: string;
}

export async function runPWAGates(): Promise<GateResult[]> {
  const results: GateResult[] = [];

  // G-PWA-01: Service Worker
  results.push({
    gate: 'G-PWA-01',
    passed: !!navigator.serviceWorker?.controller,
    message: navigator.serviceWorker?.controller
      ? 'Service Worker active'
      : 'Service Worker not controlling page',
  });

  // G-PWA-03: HTTPS
  results.push({
    gate: 'G-PWA-03',
    passed: location.protocol === 'https:' || location.hostname === 'localhost',
    message: location.protocol === 'https:' ? 'HTTPS enforced' : 'Not using HTTPS',
  });

  // G-PWA-06: Installable
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
  results.push({
    gate: 'G-PWA-06',
    passed: isStandalone || 'BeforeInstallPromptEvent' in window,
    message: isStandalone ? 'Already installed' : 'Installable',
  });

  return results;
}
```

---

## 22. RTL-FIRST COMPLIANCE (Law #5)

> **APEX Law #5: RTL-First - COMPASS**

### 22.1 PWA RTL Checklist

| Element | RTL Requirement | Implementation |
|---------|-----------------|----------------|
| Manifest | `dir: 'rtl'` | Set in manifest.ts |
| Manifest | `lang: 'he'` | Set in manifest.ts |
| HTML | `dir="rtl"` on html | layout.tsx |
| Spacing | `ms-`/`me-` not `ml-`/`mr-` | All components |
| Text | `text-start`/`text-end` | All text alignment |
| Icons | `rtl:rotate-180` | Directional icons |
| Numbers | `dir="ltr"` wrapper | Price, date, phone |
| Notifications | `dir: 'rtl'` | Push handler |

### 22.2 RTL Validation for PWA

```typescript
// lib/pwa/rtlValidation.ts

export function validateRTLCompliance(): string[] {
  const issues: string[] = [];

  // Check HTML dir attribute
  if (document.documentElement.dir !== 'rtl') {
    issues.push('HTML dir attribute should be "rtl"');
  }

  // Check for physical properties in stylesheets
  const sheets = document.styleSheets;
  for (let i = 0; i < sheets.length; i++) {
    try {
      const rules = sheets[i].cssRules;
      for (let j = 0; j < rules.length; j++) {
        const cssText = (rules[j] as CSSStyleRule).cssText || '';
        if (/margin-left|margin-right|padding-left|padding-right/.test(cssText)) {
          issues.push(`Physical property found: ${cssText.slice(0, 50)}...`);
        }
      }
    } catch {
      // Cross-origin stylesheet, skip
    }
  }

  return issues;
}
```

---

## 23. RESPONSIVE COMPLIANCE (Law #6)

> **APEX Law #6: Responsive - WATER**

### 23.1 PWA Responsive Requirements

| Requirement | Target | Implementation |
|-------------|--------|----------------|
| Touch targets | 44x44px minimum | `min-h-11 min-w-11` |
| Spacing | 8pt grid | 4, 8, 12, 16, 24, 32, 48, 64px |
| Font size | 16px minimum | Prevent iOS zoom |
| Breakpoints | Mobile-first | base -> sm -> md -> lg -> xl |
| Safe areas | env() support | `safe-area-inset-*` |
| Viewport | `viewport-fit: cover` | layout.tsx |

### 23.2 Responsive PWA Validation

```typescript
// lib/pwa/responsiveValidation.ts

export function validateResponsiveCompliance(): string[] {
  const issues: string[] = [];

  // Check touch targets
  const buttons = document.querySelectorAll('button, a, [role="button"]');
  buttons.forEach((el) => {
    const rect = el.getBoundingClientRect();
    if (rect.width < 44 || rect.height < 44) {
      issues.push(`Touch target too small: ${el.textContent?.slice(0, 20)} (${rect.width}x${rect.height})`);
    }
  });

  // Check font sizes
  const inputs = document.querySelectorAll('input, textarea, select');
  inputs.forEach((el) => {
    const fontSize = parseFloat(getComputedStyle(el).fontSize);
    if (fontSize < 16) {
      issues.push(`Input font size < 16px may cause iOS zoom: ${fontSize}px`);
    }
  });

  // Check viewport meta
  const viewport = document.querySelector('meta[name="viewport"]');
  if (!viewport?.getAttribute('content')?.includes('viewport-fit=cover')) {
    issues.push('Missing viewport-fit=cover for safe area support');
  }

  return issues;
}
```

### 23.3 Combined PWA Compliance Check

```typescript
// lib/pwa/complianceCheck.ts

export async function runFullPWAComplianceCheck(): Promise<{
  gates: GateResult[];
  rtl: string[];
  responsive: string[];
  score: number;
}> {
  const gates = await runPWAGates();
  const rtl = validateRTLCompliance();
  const responsive = validateResponsiveCompliance();

  const totalChecks = gates.length + rtl.length + responsive.length;
  const passed = gates.filter(g => g.passed).length;
  const score = Math.round((passed / gates.length) * 100);

  return { gates, rtl, responsive, score };
}
```

---

## 24. INP OPTIMIZATION

> **Target: < 100ms INP** | Interaction to Next Paint

### 24.1 scheduler.yield() Pattern

Break up long tasks to maintain responsiveness.

```typescript
// lib/performance/schedulerYield.ts

/**
 * Process large arrays without blocking the main thread
 * Uses scheduler.yield() to allow browser to handle pending interactions
 */
async function processLargeArray<T>(
  items: T[],
  processFn: (item: T) => void,
  yieldEvery: number = 5
): Promise<void> {
  for (let i = 0; i < items.length; i++) {
    processFn(items[i]);

    // Yield to main thread periodically
    if (i % yieldEvery === 0) {
      await scheduler.yield();
    }
  }
}

/**
 * Polyfill for scheduler.yield()
 * Falls back to setTimeout for browsers without native support
 */
async function yieldToMain(): Promise<void> {
  if ('scheduler' in globalThis && 'yield' in (globalThis as any).scheduler) {
    return (globalThis as any).scheduler.yield();
  }

  // Fallback: setTimeout with 0ms yields to event loop
  return new Promise((resolve) => setTimeout(resolve, 0));
}

/**
 * Process with priority hints
 */
async function processWithPriority<T>(
  items: T[],
  processFn: (item: T) => void,
  priority: 'user-blocking' | 'user-visible' | 'background' = 'user-visible'
): Promise<void> {
  const scheduler = (globalThis as any).scheduler;

  for (const item of items) {
    await scheduler.postTask(
      () => processFn(item),
      { priority }
    );
  }
}

// Usage example
async function renderLargeList(items: Item[]) {
  const container = document.getElementById('list');

  for (let i = 0; i < items.length; i++) {
    const element = createListItem(items[i]);
    container?.appendChild(element);

    // Yield every 5 items to keep INP low
    if (i % 5 === 0) {
      await yieldToMain();
    }
  }
}
```

### 24.2 Long Task Observer

Detect and log tasks that block the main thread for > 50ms.

```typescript
// lib/performance/longTaskObserver.ts

interface LongTaskEntry {
  duration: number;
  startTime: number;
  name: string;
  attribution: string[];
}

/**
 * Monitor for long tasks that impact INP
 * Long task = any task > 50ms
 */
export function setupLongTaskObserver(
  onLongTask?: (entry: LongTaskEntry) => void
): PerformanceObserver | null {
  if (!('PerformanceObserver' in window)) {
    console.warn('PerformanceObserver not supported');
    return null;
  }

  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (entry.duration > 50) {
        const taskInfo: LongTaskEntry = {
          duration: entry.duration,
          startTime: entry.startTime,
          name: entry.name,
          attribution: (entry as unknown as { attribution?: Array<{ containerType?: string; name?: string }> }).attribution?.map(
            (a: { containerType?: string; name?: string }) => a.containerType || a.name || 'unknown'
          ) || [],
        };

        console.warn(
          `[LongTask] ${entry.duration.toFixed(2)}ms`,
          taskInfo.attribution.join(' > ')
        );

        onLongTask?.(taskInfo);
      }
    }
  });

  try {
    observer.observe({ entryTypes: ['longtask'] });
    console.log('[LongTaskObserver] Monitoring started');
  } catch (error) {
    console.warn('[LongTaskObserver] Failed to observe:', error);
    return null;
  }

  return observer;
}

/**
 * Aggregate long task metrics for reporting
 */
export function createLongTaskReporter() {
  const tasks: LongTaskEntry[] = [];

  const observer = setupLongTaskObserver((entry) => {
    tasks.push(entry);
  });

  return {
    observer,
    getTasks: () => [...tasks],
    getStats: () => ({
      count: tasks.length,
      totalDuration: tasks.reduce((sum, t) => sum + t.duration, 0),
      maxDuration: Math.max(...tasks.map(t => t.duration), 0),
      avgDuration: tasks.length > 0
        ? tasks.reduce((sum, t) => sum + t.duration, 0) / tasks.length
        : 0,
    }),
    clear: () => tasks.length = 0,
  };
}
```

### 24.3 React startTransition Pattern

Mark non-urgent updates to prevent blocking user interactions.

```typescript
// lib/performance/reactOptimizations.ts
import { startTransition, useTransition, useDeferredValue } from 'react';

/**
 * Use startTransition for non-urgent state updates
 * This prevents blocking user interactions
 */
function SearchComponent() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Item[]>([]);
  const [isPending, startSearchTransition] = useTransition();

  const handleSearch = (value: string) => {
    // Urgent: Update input immediately
    setQuery(value);

    // Non-urgent: Search can be interrupted
    startSearchTransition(() => {
      const filtered = performExpensiveSearch(value);
      setResults(filtered);
    });
  };

  return (
    <div>
      <input
        type="search"
        value={query}
        onChange={(e) => handleSearch(e.target.value)}
        className="min-h-11" // Touch target
      />
      {isPending && <LoadingSpinner />}
      <ResultsList results={results} />
    </div>
  );
}

/**
 * Use useDeferredValue for expensive renders
 */
function HeavyListComponent({ items }: { items: Item[] }) {
  // Defer the value - allows React to delay this update
  const deferredItems = useDeferredValue(items);

  // Show stale indicator when deferred
  const isStale = deferredItems !== items;

  return (
    <div className={isStale ? 'opacity-70' : ''}>
      {deferredItems.map((item) => (
        <ExpensiveListItem key={item.id} item={item} />
      ))}
    </div>
  );
}

/**
 * Wrap state updates that don't need immediate feedback
 */
function handleNonUrgentAction(action: () => void) {
  startTransition(() => {
    action();
  });
}

// Example: Tab switching with heavy content
function TabPanel() {
  const [activeTab, setActiveTab] = useState(0);
  const [isPending, startTabTransition] = useTransition();

  const switchTab = (tabIndex: number) => {
    startTabTransition(() => {
      setActiveTab(tabIndex);
    });
  };

  return (
    <div>
      <TabList
        activeTab={activeTab}
        onTabChange={switchTab}
        isPending={isPending}
      />
      <TabContent
        tab={activeTab}
        className={isPending ? 'opacity-50' : ''}
      />
    </div>
  );
}
```

### 24.4 INP Optimization Checklist

```markdown
### INP Optimization Checklist (Target: < 100ms)

#### Event Handlers
- [ ] All click handlers complete < 50ms
- [ ] Use requestAnimationFrame for visual updates
- [ ] Debounce rapid-fire events (scroll, resize)
- [ ] Use passive event listeners for scroll/touch

#### Long Tasks
- [ ] No synchronous operations > 50ms
- [ ] Use scheduler.yield() for loops > 5 iterations
- [ ] Web Workers for heavy computations
- [ ] LongTaskObserver monitoring in production

#### React Specific
- [ ] startTransition for non-urgent updates
- [ ] useDeferredValue for heavy list renders
- [ ] Suspense boundaries for code splitting
- [ ] React Compiler enabled (auto-memoizes — no manual useMemo/useCallback/memo)
- [ ] No manual useMemo/useCallback/React.memo (React Compiler handles it)

#### PWA Specific
- [ ] Service Worker fetch handlers are fast
- [ ] Cache strategies don't block render
- [ ] Background sync for heavy operations
- [ ] IndexedDB operations off main thread
```

---

## 25. FIELD VS LAB DATA

> **Field Data**: Real User Monitoring (RUM) from actual users
> **Lab Data**: Synthetic tests in controlled environments

### 25.1 CrUX API Integration

Get real field data from Chrome User Experience Report.

```typescript
// lib/performance/cruxApi.ts

interface CrUXMetric {
  histogram: Array<{ start: number; end: number; density: number }>;
  percentiles: { p75: number };
}

interface CrUXResponse {
  record: {
    key: { url?: string; origin?: string };
    metrics: {
      largest_contentful_paint?: CrUXMetric;
      interaction_to_next_paint?: CrUXMetric;
      cumulative_layout_shift?: CrUXMetric;
      first_contentful_paint?: CrUXMetric;
      first_input_delay?: CrUXMetric;
      time_to_first_byte?: CrUXMetric;
    };
  };
}

/**
 * Fetch Chrome User Experience Report data
 * Provides real field metrics from actual Chrome users
 */
export async function getCrUXData(
  url: string,
  apiKey: string,
  formFactor?: 'PHONE' | 'DESKTOP' | 'TABLET'
): Promise<CrUXResponse | null> {
  const endpoint = 'https://chromeuxreport.googleapis.com/v1/records:queryRecord';

  try {
    const response = await fetch(`${endpoint}?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        url,
        formFactor,
        metrics: [
          'largest_contentful_paint',
          'interaction_to_next_paint',
          'cumulative_layout_shift',
          'first_contentful_paint',
          'time_to_first_byte',
        ],
      }),
    });

    if (!response.ok) {
      // Try origin-level data if URL-level not available
      const originResponse = await fetch(`${endpoint}?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          origin: new URL(url).origin,
          formFactor,
          metrics: [
            'largest_contentful_paint',
            'interaction_to_next_paint',
            'cumulative_layout_shift',
          ],
        }),
      });

      if (!originResponse.ok) return null;
      return originResponse.json();
    }

    return response.json();
  } catch (error) {
    console.error('[CrUX] Failed to fetch:', error);
    return null;
  }
}

/**
 * Format CrUX data for display
 */
export function formatCrUXMetrics(data: CrUXResponse): {
  lcp: string;
  inp: string;
  cls: string;
  rating: 'good' | 'needs-improvement' | 'poor';
} {
  const metrics = data.record.metrics;

  const lcp = metrics.largest_contentful_paint?.percentiles.p75 ?? 0;
  const inp = metrics.interaction_to_next_paint?.percentiles.p75 ?? 0;
  const cls = metrics.cumulative_layout_shift?.percentiles.p75 ?? 0;

  // Determine overall rating
  let rating: 'good' | 'needs-improvement' | 'poor' = 'good';
  if (lcp > 4000 || inp > 500 || cls > 0.25) rating = 'poor';
  else if (lcp > 2500 || inp > 200 || cls > 0.1) rating = 'needs-improvement';

  return {
    lcp: `${(lcp / 1000).toFixed(2)}s`,
    inp: `${inp}ms`,
    cls: cls.toFixed(3),
    rating,
  };
}
```

### 25.2 web-vitals RUM Integration

Real User Monitoring with the web-vitals library.

```typescript
// lib/performance/webVitalsRUM.ts
import { onLCP, onINP, onCLS, onFCP, onTTFB, type Metric } from 'web-vitals';

interface VitalMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  delta: number;
  id: string;
  navigationType: string;
}

/**
 * Initialize web-vitals Real User Monitoring
 * Reports metrics to your analytics endpoint
 */
export function initWebVitalsRUM(
  reportEndpoint: string,
  options?: {
    debug?: boolean;
    sampleRate?: number;
  }
): void {
  const { debug = false, sampleRate = 1 } = options ?? {};

  // Sample rate check
  if (Math.random() > sampleRate) {
    console.log('[WebVitals] Skipped due to sample rate');
    return;
  }

  const reportMetric = (metric: Metric) => {
    const vital: VitalMetric = {
      name: metric.name,
      value: metric.value,
      rating: metric.rating,
      delta: metric.delta,
      id: metric.id,
      navigationType: metric.navigationType,
    };

    if (debug) {
      console.log(`[WebVitals] ${metric.name}:`, vital);
    }

    // Report to analytics
    sendToAnalytics(reportEndpoint, vital);
  };

  // Core Web Vitals
  onLCP(reportMetric);
  onINP(reportMetric);
  onCLS(reportMetric);

  // Additional metrics
  onFCP(reportMetric);
  onTTFB(reportMetric);

  console.log('[WebVitals] RUM initialized');
}

/**
 * Send metric to analytics endpoint
 */
async function sendToAnalytics(
  endpoint: string,
  metric: VitalMetric
): Promise<void> {
  // Use sendBeacon for reliability
  if ('sendBeacon' in navigator) {
    const blob = new Blob([JSON.stringify(metric)], {
      type: 'application/json',
    });
    navigator.sendBeacon(endpoint, blob);
    return;
  }

  // Fallback to fetch with keepalive
  try {
    await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(metric),
      keepalive: true,
    });
  } catch {
    // Silent fail - don't impact user experience
  }
}

/**
 * React hook for web-vitals
 */
export function useWebVitals() {
  const [vitals, setVitals] = useState<Record<string, VitalMetric>>({});

  useEffect(() => {
    const updateVital = (metric: Metric) => {
      setVitals((prev) => ({
        ...prev,
        [metric.name]: {
          name: metric.name,
          value: metric.value,
          rating: metric.rating,
          delta: metric.delta,
          id: metric.id,
          navigationType: metric.navigationType,
        },
      }));
    };

    onLCP(updateVital);
    onINP(updateVital);
    onCLS(updateVital);
    onFCP(updateVital);
    onTTFB(updateVital);
  }, []);

  return vitals;
}
```

### 25.3 Field vs Lab Comparison

| Aspect | Lab Data | Field Data |
|--------|----------|------------|
| **Source** | Lighthouse, WebPageTest | CrUX, RUM (web-vitals) |
| **Environment** | Controlled, simulated | Real user devices/networks |
| **Consistency** | Reproducible | Variable |
| **Coverage** | Single test point | All users |
| **Debugging** | Detailed insights | Aggregated metrics |
| **Use Case** | Development, CI | Monitoring, business decisions |
| **INP** | Simulated interactions | Real user interactions |

### 25.4 When to Use Each

```markdown
### Lab Data (Lighthouse, WebPageTest)
- During development for quick feedback
- CI/CD pipeline gates
- Debugging specific issues
- A/B testing implementations
- Pre-launch performance audits

### Field Data (CrUX, RUM)
- Production monitoring
- Understanding real user experience
- Business impact analysis
- Geographic/device segmentation
- Core Web Vitals for SEO (Google uses field data)
```

---

## 26. MODERN APIS (2025-2026)

> **Project Fugu**: Web platform capabilities for native-like experiences

### 26.1 Modern PWA APIs Matrix

| API | Status | Chrome | Use Case |
|-----|--------|--------|----------|
| Navigation API | Baseline 2025 | 102+ | SPA navigation control |
| Launch Handler | Chrome 110+ | 110+ | Control PWA launch mode |
| File Handling | Chrome 102+ | 102+ | PWA as file handler |
| Protocol Handler | Chrome 96+ | 96+ | Custom URL protocols |
| App Badges | Chrome 81+ | 81+ | Notification count |
| Content Indexing | Chrome 84+ | 84+ | Searchable offline content |
| Periodic Background Sync | Chrome 80+ | 80+ | Scheduled tasks |
| Share Target | Chrome 71+ | 71+ | Handle shared content |
| Shortcuts | Chrome 84+ | 84+ | App shortcuts |
| Screenshots | Chrome 91+ | 91+ | Rich install UI |
| Window Controls Overlay | Chrome 105+ | 105+ | Custom title bar |
| Declarative Link Capturing | Chrome 121+ | 121+ | Capture link clicks |

### 26.2 Navigation API

Modern SPA navigation with full browser history control.

```typescript
// lib/modern/navigationApi.ts

/**
 * Navigation API - Modern SPA navigation control
 * Baseline 2025 - Safe to use
 */
export function setupNavigationAPI(): void {
  if (!('navigation' in window)) {
    console.warn('Navigation API not supported');
    return;
  }

  // Navigation API (experimental, no stable types yet)
  const navigation = (window as unknown as { navigation: EventTarget & Record<string, unknown> }).navigation;

  // Intercept navigation events
  navigation.addEventListener('navigate', (event: Event & { canIntercept?: boolean; hashChange?: boolean; destination?: { url: string }; intercept?: (opts: { handler: () => Promise<void> }) => void }) => {
    // Only handle same-origin navigations
    if (!event.canIntercept || event.hashChange) return;

    const url = new URL(event.destination.url);

    // Handle app routes
    if (url.pathname.startsWith('/app/')) {
      event.intercept({
        handler: async () => {
          // Custom navigation handling
          await loadRoute(url.pathname);

          // Update document
          document.title = getRouteTitle(url.pathname);
        },
      });
    }
  });

  // Handle back/forward
  navigation.addEventListener('navigatesuccess', () => {
    // Scroll restoration, analytics, etc.
    window.scrollTo(0, 0);
  });

  console.log('[NavigationAPI] Initialized');
}

/**
 * Programmatic navigation with Navigation API
 */
export async function navigateTo(
  url: string,
  options?: { history?: 'push' | 'replace'; state?: unknown }
): Promise<void> {
  const { history = 'push', state } = options ?? {};

  if ('navigation' in window) {
    // Navigation API (experimental, no stable types yet)
    const navigation = (window as unknown as { navigation: { navigate: (url: string, opts: { history: string; state: unknown }) => { finished: Promise<void> } } }).navigation;
    await navigation.navigate(url, {
      history,
      state,
    }).finished;
  } else {
    // Fallback
    if (history === 'replace') {
      window.history.replaceState(state, '', url);
    } else {
      window.history.pushState(state, '', url);
    }
  }
}
```

### 26.3 Launch Handler

Control how the PWA launches when opened.

```typescript
// app/manifest.ts - Manifest configuration
export default function manifest(): MetadataRoute.Manifest {
  return {
    // ... other manifest fields

    // Launch Handler - Control PWA launch behavior
    launch_handler: {
      // Focus existing window instead of opening new one
      client_mode: ['focus-existing', 'auto'],
    },
  };
}

// lib/modern/launchHandler.ts

/**
 * Handle launch queue for file/protocol launches
 */
export function setupLaunchHandler(): void {
  if (!('launchQueue' in window)) {
    console.warn('Launch Queue API not supported');
    return;
  }

  // Launch Handler API (experimental, no stable types yet)
  const launchQueue = (window as unknown as { launchQueue: { setConsumer: (cb: (params: { files?: Array<{ getFile: () => Promise<Blob> }>; targetURL?: string }) => Promise<void>) => void } }).launchQueue;

  launchQueue.setConsumer(async (launchParams: { files?: Array<{ getFile: () => Promise<Blob> }>; targetURL?: string }) => {
    // Handle files launched with the PWA
    if (launchParams.files?.length > 0) {
      for (const file of launchParams.files) {
        const blob = await file.getFile();
        await handleLaunchedFile(blob);
      }
    }

    // Handle URL launches
    if (launchParams.targetURL) {
      await handleLaunchedURL(launchParams.targetURL);
    }
  });

  console.log('[LaunchHandler] Consumer set');
}

async function handleLaunchedFile(file: File): Promise<void> {
  console.log(`[Launch] File: ${file.name} (${file.type})`);
  // Process the file
}

async function handleLaunchedURL(url: string): Promise<void> {
  console.log(`[Launch] URL: ${url}`);
  // Navigate or process the URL
}
```

### 26.4 App Badges

Display notification count on app icon.

```typescript
// lib/modern/appBadges.ts

/**
 * Update app badge with unread count
 */
export async function updateAppBadge(count: number): Promise<boolean> {
  if (!('setAppBadge' in navigator)) {
    console.warn('Badge API not supported');
    return false;
  }

  try {
    if (count > 0) {
      await navigator.setAppBadge(count);
    } else {
      await navigator.clearAppBadge();
    }
    return true;
  } catch (error) {
    console.error('[Badge] Failed:', error);
    return false;
  }
}

/**
 * Badge from Service Worker (push notifications)
 */
// In sw.ts
self.addEventListener('push', async (event) => {
  const data = event.data?.json() ?? {};

  // Update badge from push payload
  if (typeof data.unreadCount === 'number') {
    await (self.navigator as any).setAppBadge(data.unreadCount);
  }
});
```

### 26.5 Content Indexing

Make offline content searchable by the system.

```typescript
// lib/modern/contentIndexing.ts

interface IndexableContent {
  id: string;
  title: string;
  description: string;
  url: string;
  category: 'article' | 'video' | 'audio' | '';
  icons?: Array<{ src: string; sizes: string; type: string }>;
}

/**
 * Add content to device's search index
 */
export async function addToIndex(content: IndexableContent): Promise<boolean> {
  if (!('index' in (await navigator.serviceWorker.ready))) {
    console.warn('Content Indexing not supported');
    return false;
  }

  try {
    const registration = await navigator.serviceWorker.ready;
    const index = (registration as any).index;

    await index.add({
      id: content.id,
      title: content.title,
      description: content.description,
      url: content.url,
      category: content.category || '',
      icons: content.icons ?? [
        { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
      ],
    });

    console.log(`[ContentIndex] Added: ${content.title}`);
    return true;
  } catch (error) {
    console.error('[ContentIndex] Failed:', error);
    return false;
  }
}

/**
 * Get all indexed content
 */
export async function getIndexedContent(): Promise<IndexableContent[]> {
  try {
    const registration = await navigator.serviceWorker.ready;
    const index = (registration as any).index;
    return await index.getAll();
  } catch {
    return [];
  }
}
```

### 26.6 Shortcuts

App shortcuts for quick actions.

```typescript
// app/manifest.ts
export default function manifest(): MetadataRoute.Manifest {
  return {
    // ... other manifest fields

    // App Shortcuts - Quick actions from app icon
    shortcuts: [
      {
        name: 'הזמנה חדשה',
        short_name: 'הזמנה',
        description: 'צור הזמנה חדשה',
        url: '/orders/new',
        icons: [{ src: '/icons/shortcut-new-order.png', sizes: '96x96' }],
      },
      {
        name: 'סריקת ברקוד',
        short_name: 'סריקה',
        description: 'סרוק ברקוד מוצר',
        url: '/scan',
        icons: [{ src: '/icons/shortcut-scan.png', sizes: '96x96' }],
      },
      {
        name: 'דוחות',
        short_name: 'דוחות',
        description: 'צפה בדוחות',
        url: '/reports',
        icons: [{ src: '/icons/shortcut-reports.png', sizes: '96x96' }],
      },
    ],
  };
}
```

### 26.7 Screenshots for Rich Install UI

Enhance install prompt with screenshots.

```typescript
// app/manifest.ts
export default function manifest(): MetadataRoute.Manifest {
  return {
    // ... other manifest fields

    // Screenshots - Shown in install dialog
    screenshots: [
      {
        src: '/screenshots/mobile-home.png',
        sizes: '750x1334',
        type: 'image/png',
        form_factor: 'narrow', // Mobile
        label: 'מסך הבית',
      },
      {
        src: '/screenshots/mobile-orders.png',
        sizes: '750x1334',
        type: 'image/png',
        form_factor: 'narrow',
        label: 'ניהול הזמנות',
      },
      {
        src: '/screenshots/desktop-dashboard.png',
        sizes: '1280x720',
        type: 'image/png',
        form_factor: 'wide', // Desktop
        label: 'לוח בקרה',
      },
    ],
  };
}
```

### 26.8 Feature Detection Utility

```typescript
// lib/modern/featureDetection.ts

export const modernAPIs = {
  navigation: () => 'navigation' in window,
  launchHandler: () => 'launchQueue' in window,
  fileHandling: () => 'launchQueue' in window,
  protocolHandler: () => 'registerProtocolHandler' in navigator,
  appBadge: () => 'setAppBadge' in navigator,
  contentIndexing: async () => {
    const reg = await navigator.serviceWorker?.ready;
    return 'index' in (reg ?? {});
  },
  periodicSync: async () => {
    const reg = await navigator.serviceWorker?.ready;
    return 'periodicSync' in (reg ?? {});
  },
  shareTarget: () => true, // Manifest-only
  shortcuts: () => true, // Manifest-only
  screenshots: () => true, // Manifest-only
  windowControlsOverlay: () => 'windowControlsOverlay' in navigator,
};

export async function getSupportedModernAPIs(): Promise<string[]> {
  const supported: string[] = [];

  for (const [name, check] of Object.entries(modernAPIs)) {
    try {
      const result = await check();
      if (result) supported.push(name);
    } catch {
      // API check failed
    }
  }

  return supported;
}
```

---

## 27. 9-DIMENSION ALIGNMENT

> **SINGULARITY FORGE v24.5.0 - 9-Dimension Framework**

### 27.1 PWA Dimension Matrix

| Dim | Name | PWA Application | Implementation |
|-----|------|-----------------|----------------|
| 1 | STRUCTURE | Modular SW < 150 lines/file | Split SW into focused modules |
| 2 | SENSATION | 144fps transitions, WCAG AAA | View Transitions, a11y testing |
| 3 | DESIGN | 8pt grid, color tokens | CSS custom properties, spacing scale |
| 4 | INTEGRITY | Cache validation, Zod schemas | SW cache versioning, API validation |
| 5 | SCALE | LCP < 1.0s, Bundle < 100KB | Code splitting, precache optimization |
| 6 | NEURAL | MCP integration | Memory MCP for PWA state |
| 7 | ORACLE | PWA metrics tracking | CrUX, web-vitals RUM |
| 8 | ALCHEMIST | Token budget for SW | Minimize SW payload |
| 9 | EXORCIST | Dead code purge | Tree shaking, unused cache cleanup |

### 27.2 Dimension Implementation

```typescript
// lib/pwa/dimensionAlignment.ts

interface DimensionScore {
  dimension: number;
  name: string;
  score: number; // 0-100
  findings: string[];
}

/**
 * Verify PWA alignment with 9-Dimension Framework
 */
export async function verifyDimensionAlignment(): Promise<DimensionScore[]> {
  const scores: DimensionScore[] = [];

  // D1: STRUCTURE - Modular code
  const d1 = await checkStructure();
  scores.push({ dimension: 1, name: 'STRUCTURE', ...d1 });

  // D2: SENSATION - Performance & accessibility
  const d2 = await checkSensation();
  scores.push({ dimension: 2, name: 'SENSATION', ...d2 });

  // D3: DESIGN - Consistent spacing & colors
  const d3 = await checkDesign();
  scores.push({ dimension: 3, name: 'DESIGN', ...d3 });

  // D4: INTEGRITY - Data validation
  const d4 = await checkIntegrity();
  scores.push({ dimension: 4, name: 'INTEGRITY', ...d4 });

  // D5: SCALE - Performance targets
  const d5 = await checkScale();
  scores.push({ dimension: 5, name: 'SCALE', ...d5 });

  // D6: NEURAL - MCP integration
  const d6 = await checkNeural();
  scores.push({ dimension: 6, name: 'NEURAL', ...d6 });

  // D7: ORACLE - Metrics tracking
  const d7 = await checkOracle();
  scores.push({ dimension: 7, name: 'ORACLE', ...d7 });

  // D8: ALCHEMIST - Resource optimization
  const d8 = await checkAlchemist();
  scores.push({ dimension: 8, name: 'ALCHEMIST', ...d8 });

  // D9: EXORCIST - Dead code removal
  const d9 = await checkExorcist();
  scores.push({ dimension: 9, name: 'EXORCIST', ...d9 });

  return scores;
}

async function checkStructure(): Promise<{ score: number; findings: string[] }> {
  const findings: string[] = [];
  let score = 100;

  // Check SW registration
  const reg = await navigator.serviceWorker?.getRegistration();
  if (!reg) {
    findings.push('Service Worker not registered');
    score -= 50;
  }

  return { score, findings };
}

async function checkSensation(): Promise<{ score: number; findings: string[] }> {
  const findings: string[] = [];
  let score = 100;

  // Check View Transitions support
  if (!('startViewTransition' in document)) {
    findings.push('View Transitions not supported');
    score -= 20;
  }

  // Check touch targets
  const buttons = document.querySelectorAll('button, a');
  let smallTargets = 0;
  buttons.forEach((el) => {
    const rect = el.getBoundingClientRect();
    if (rect.width < 44 || rect.height < 44) smallTargets++;
  });
  if (smallTargets > 0) {
    findings.push(`${smallTargets} touch targets < 44px`);
    score -= Math.min(smallTargets * 5, 30);
  }

  return { score, findings };
}

async function checkScale(): Promise<{ score: number; findings: string[] }> {
  const findings: string[] = [];
  let score = 100;

  // Check performance metrics
  const lcp = performance.getEntriesByType('largest-contentful-paint')[0] as any;
  if (lcp && lcp.startTime > 1000) {
    findings.push(`LCP: ${lcp.startTime.toFixed(0)}ms (target: < 1000ms)`);
    score -= 30;
  }

  return { score, findings };
}

// Additional dimension checks...
async function checkDesign() { return { score: 100, findings: [] }; }
async function checkIntegrity() { return { score: 100, findings: [] }; }
async function checkNeural() { return { score: 100, findings: [] }; }
async function checkOracle() { return { score: 100, findings: [] }; }
async function checkAlchemist() { return { score: 100, findings: [] }; }
async function checkExorcist() { return { score: 100, findings: [] }; }
```

---

## 28. HAPTIC FEEDBACK

> **Native-like tactile feedback for PWA interactions**

### 28.1 Vibration API Integration

```typescript
// lib/haptics/vibration.ts

/**
 * Haptic feedback patterns for different interactions
 */
export const hapticPatterns = {
  // Light tap - button press
  tap: [10],

  // Double tap - success confirmation
  success: [100, 50, 100],

  // Error feedback
  error: [100, 100, 100, 100, 100],

  // Warning
  warning: [200, 100, 200],

  // Selection change
  selection: [5],

  // Long press confirmation
  longPress: [0, 50, 100],

  // Notification received
  notification: [100, 50, 100, 50, 100],
};

/**
 * Trigger haptic feedback
 */
export function haptic(
  pattern: keyof typeof hapticPatterns | number[]
): boolean {
  if (!('vibrate' in navigator)) {
    return false;
  }

  try {
    const vibrationPattern = Array.isArray(pattern)
      ? pattern
      : hapticPatterns[pattern];

    return navigator.vibrate(vibrationPattern);
  } catch {
    return false;
  }
}

/**
 * Check haptic support
 */
export function isHapticSupported(): boolean {
  return 'vibrate' in navigator;
}

/**
 * Cancel ongoing vibration
 */
export function cancelHaptic(): boolean {
  if (!('vibrate' in navigator)) return false;
  return navigator.vibrate(0);
}
```

### 28.2 PWA Install Success Haptics

```typescript
// lib/haptics/installHaptics.ts

/**
 * Haptic feedback on PWA install success
 */
export async function onInstallSuccess(): Promise<void> {
  // Vibration feedback
  if ('vibrate' in navigator) {
    navigator.vibrate([100, 50, 100]);
  }

  // Clear badge (fresh start)
  if ('setAppBadge' in navigator) {
    await navigator.setAppBadge(0);
  }

  // Log to Memory MCP
  await pwaMemoryMCP.save({
    installDate: new Date().toISOString(),
  });

  console.log('[PWA] Install success with haptic feedback');
}

/**
 * Haptic feedback for different PWA events
 */
export const pwaHaptics = {
  // When app is installed
  installed: () => haptic('success'),

  // When offline mode is detected
  offline: () => haptic('warning'),

  // When back online
  online: () => haptic('tap'),

  // When update is available
  updateAvailable: () => haptic('notification'),

  // When sync completes
  syncComplete: () => haptic('success'),

  // When push notification received (foreground)
  notificationReceived: () => haptic('notification'),

  // When action fails
  actionFailed: () => haptic('error'),
};
```

### 28.3 Haptic Hook for React

```typescript
// hooks/useHaptic.ts
import { useState, useEffect } from 'react';
import { haptic, isHapticSupported, hapticPatterns } from '@/lib/haptics/vibration';

export function useHaptic() {
  const [isSupported] = useState(isHapticSupported);
  const [isEnabled, setIsEnabled] = useState(true);

  // Respect user preference
  useEffect(() => {
    const stored = localStorage.getItem('haptic-enabled');
    if (stored !== null) {
      setIsEnabled(stored === 'true');
    }
  }, []);

  // React Compiler auto-memoizes — no manual useCallback needed
  const toggleHaptic = () => {
    const newValue = !isEnabled;
    setIsEnabled(newValue);
    localStorage.setItem('haptic-enabled', String(newValue));
  };

  const trigger = (pattern: keyof typeof hapticPatterns | number[]) => {
    if (!isSupported || !isEnabled) return false;
    return haptic(pattern);
  };

  return {
    isSupported,
    isEnabled,
    toggleHaptic,
    trigger,
    patterns: hapticPatterns,
  };
}
```

### 28.4 Haptic Button Component

```typescript
// components/HapticButton.tsx
'use client';

import { useHaptic } from '@/hooks/useHaptic';
import { type ComponentProps } from 'react';

interface HapticButtonProps extends ComponentProps<'button'> {
  hapticPattern?: keyof typeof hapticPatterns | number[];
}

export function HapticButton({
  hapticPattern = 'tap',
  onClick,
  children,
  ...props
}: HapticButtonProps) {
  const { trigger } = useHaptic();

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    trigger(hapticPattern);
    onClick?.(e);
  };

  return (
    <button
      onClick={handleClick}
      className="min-h-11 min-w-11" // Touch target
      {...props}
    >
      {children}
    </button>
  );
}

// Usage
<HapticButton
  hapticPattern="success"
  onClick={handleSubmit}
>
  שלח הזמנה
</HapticButton>
```

### 28.5 Platform-Specific Haptics

```typescript
// lib/haptics/platformHaptics.ts

interface HapticConfig {
  pattern: number[];
  iosAlternative?: boolean; // Use sound instead on iOS
}

/**
 * Platform-aware haptic feedback
 * iOS: Limited vibration API, consider audio feedback
 * Android: Full vibration support
 */
export function platformHaptic(
  type: 'light' | 'medium' | 'heavy' | 'success' | 'error'
): void {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);

  const configs: Record<string, HapticConfig> = {
    light: { pattern: [10], iosAlternative: true },
    medium: { pattern: [50] },
    heavy: { pattern: [100] },
    success: { pattern: [100, 50, 100] },
    error: { pattern: [100, 100, 100] },
  };

  const config = configs[type];

  if ('vibrate' in navigator) {
    navigator.vibrate(config.pattern);
  } else if (isIOS && config.iosAlternative) {
    // iOS fallback: subtle audio cue
    // Note: Requires user gesture to play audio
    console.log('[Haptic] iOS fallback - consider audio feedback');
  }
}

/**
 * Haptic feedback with reduced motion respect
 */
export function accessibleHaptic(pattern: number[]): void {
  // Respect reduced motion preference
  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  if (prefersReducedMotion) {
    // Use shorter, less intense pattern
    const reducedPattern = pattern.map((v) => Math.round(v * 0.5));
    navigator.vibrate?.(reducedPattern);
  } else {
    navigator.vibrate?.(pattern);
  }
}
```

---

## 29. NVIDIA-Level Optimizations (35 Total)

> **v24.5.0 SINGULARITY FORGE** - Performance optimization matrix

### 6 Tiers Overview

| Tier | Count | Focus | Impact |
|------|-------|-------|--------|
| 1: Build | 7 | Brotli, tree-shaking, chunks | 59% bundle reduction |
| 2: Service Worker | 4 | Streaming, preload, sync | 200-500ms faster |
| 3: HTML | 3 | fetchpriority, fonts, Partytown | 50% INP improvement |
| 4: Runtime Hooks | 5 | Lifecycle, idle, bfcache | Better UX |
| 5: CSS | 2 | content-visibility, containment | 7x render speed |
| 6: Advanced | 14 | View Transitions, scheduler | Future-ready |

### Key Patterns

**Brotli Compression (25-30% smaller than gzip):**
```typescript
import viteCompression from "vite-plugin-compression";
viteCompression({ algorithm: "brotliCompress", ext: ".br", threshold: 1024 })
```

**Streaming Responses (200-500ms faster on 3G):**
```typescript
const reader = response.body.getReader();
const stream = new ReadableStream({
  async start(controller) {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      controller.enqueue(value);
    }
    controller.close();
  },
});
return new Response(stream, { status: response.status, headers: response.headers });
```

**Partytown Analytics Offload (50% INP improvement):**
```typescript
import { partytownVite } from "@builder.io/partytown/utils";
partytownVite({ dest: path.join(__dirname, "dist", "~partytown") })
```

### Reference Files
- `references/nvidia-level-optimizations.md` - All 35 optimizations with code
- `references/vite-pwa-nvidia-config.md` - Complete Vite configuration
- `references/pwa-runtime-hooks.md` - All PWA React hooks

---

## 30. Android Rendering Fixes (8 Critical Issues)

> **NEW in v24.5.0** - Based on Cash App deep research (Jan 2026)

These fixes address critical Android rendering issues that are NOT caught by Lighthouse:

| Gate | Issue | Symptom | Fix |
|------|-------|---------|-----|
| G-ARF-1 | content-visibility:auto | Elements disappear during scroll | Disable for `.is-android` |
| G-ARF-2 | strokeWidth inconsistent | Icons look different | Standardize to 2.5 |
| G-ARF-3 | View Transitions | Jank on old Android | Disable for Chrome < 111 |
| G-ARF-4 | will-change conflict | Rendering issues | Single source of truth |
| G-ARF-5 | scrollMargin race | Virtual list offset wrong | useState+useLayoutEffect |
| G-ARF-6 | Touch targets < 44px | Hard to tap | Wrapper div min-h-11 |
| G-ARF-7 | z-index: 9999 | Scale animations break | Max z-index: 50 |
| G-ARF-8 | Network timeout 3s | Requests fail on slow | Increase to 10s |

### Quick Fix Commands

```bash
/pwa android-rendering-audit    # Full audit
/pwa fix-content-visibility     # Fix disappearing elements
/pwa fix-stroke-width           # Fix icon consistency
/pwa fix-touch-targets          # Fix small touch areas
```

### Detection Setup (MANDATORY)

```typescript
// Add to main.tsx before React renders
const isAndroid = /Android/.test(navigator.userAgent);
if (isAndroid) {
  document.documentElement.classList.add('is-android');
  const chromeVersion = parseInt(navigator.userAgent.match(/Chrome\/(\d+)/)?.[1] || '999');
  if (chromeVersion < 90) document.documentElement.classList.add('is-android-old');
}
```

### CSS Override (MANDATORY for Android)

```css
/* Disable content-visibility on Android */
.is-android [class*="cv-"] {
  content-visibility: visible !important;
  contain-intrinsic-size: none !important;
}

/* Disable View Transitions on Android */
.is-android ::view-transition-old(root),
.is-android ::view-transition-new(root) {
  animation: none !important;
}
```

### Reference File
- `references/android-rendering-fixes.md` - Complete 8-gate fix guide

---

## Related Documents

- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-checklist.md` - Core requirements (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-advanced.md` - Advanced patterns (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-performance.md` - Performance (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-security.md` - Security (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-cross-platform-ui.md` - UI consistency (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-android-compatibility.md` - Android WebView/TWA (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-view-transitions.md` - View Transitions (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-navigation.md` - Navigation/Prefetch (archived)
- `~/.claude/skills/_archive/batch-2026-02-19/apex-mobile/references/pwa-cutting-edge.md` - Project Fugu APIs (archived)
- `~/.claude/skills/pwa-expert/references/pwa-android-optimization.md` - **Android Performance Deep Dive**
- `~/.claude/skills/pwa-expert/references/android-rendering-fixes.md` - **Android Rendering Fixes (NEW v24.5.0)**

<!-- PWA-EXPERT v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->

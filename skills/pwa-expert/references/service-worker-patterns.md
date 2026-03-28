# SERVICE-WORKER-PATTERNS v24.5.0 SINGULARITY FORGE

> The Workbox Master & Caching Strategy Engine

---

## 1. PURPOSE

Service Worker engine. Comprehensive patterns for Service Worker implementation using vite-plugin-pwa + Workbox 7.x. Covers caching strategies, background sync, push notifications, and offline-first architecture.

**Stack:** Vite 7 + vite-plugin-pwa + Workbox 7.x (NOT Serwist)

**Cash App Architecture:** Modular SW with 13 files under `src/sw/`, custom injectManifest strategy, NetworkFirst navigation with 3s timeout + Navigation Preload.

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/sw setup` | Setup Serwist service worker | ~3min |
| `/sw cache` | Configure caching strategies | ~2min |
| `/sw sync` | Setup background sync | ~2min |
| `/sw push` | Configure push notifications | ~3min |
| `/sw debug` | Debug SW issues | ~5min |

---

## 3. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-SW-1 | REGISTERED | SW is active | State: activated |
| G-SW-2 | CACHE_STRATEGY | Proper strategies | CacheFirst/NetworkFirst |
| G-SW-3 | OFFLINE_FALLBACK | Offline works | Page loads offline |
| G-SW-4 | CACHE_CLEANUP | Old caches removed | No stale data |
| G-SW-5 | UPDATE_FLOW | SW updates work | Skip waiting + refresh |

---

## 4. QUICK REFERENCE

| Feature | Strategy | Use Case |
|---------|----------|----------|
| Static Assets | CacheFirst | Images, fonts (long TTL) |
| API Calls | NetworkFirst | Fresh data with offline fallback |
| JS/CSS | StaleWhileRevalidate | Instant load + background update |
| Navigation | StaleWhileRevalidate | Fast page loads |
| Push | Event listener | Real-time notifications |
| Background Sync | SyncManager | Offline queue processing |

---

## 5. WORKBOX CONFIGURATION

### vite-plugin-pwa Setup (vite.config.ts)

```typescript
import { defineConfig } from "vite";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig(({ mode }) => ({
  plugins: [
    VitePWA({
      // Auto-update without user prompt
      registerType: "autoUpdate",

      // Use custom service worker (injectManifest)
      // Alternative: "generateSW" for auto-generated SW
      strategies: "injectManifest",

      // Location of custom SW file
      srcDir: "src",
      filename: "sw.ts",

      // Don't auto-inject registration (we handle it manually)
      injectRegister: false,

      // Assets to precache (available offline immediately)
      includeAssets: [
        "favicon.ico",
        "logo.svg",
        "apple-touch-icon.png",
        "pwa-192x192.png",
        "pwa-512x512.png",
        "robots.txt",
      ],

      // Use external manifest.json (false) or generate (object)
      manifest: false,

      // InjectManifest options
      injectManifest: {
        // Files to precache
        globPatterns: ["**/*.{js,css,html,ico,png,svg,woff2,woff,ttf,json}"],
        // Max file size (10MB)
        maximumFileSizeToCacheInBytes: 10 * 1024 * 1024,
      },

      // Development options
      devOptions: {
        enabled: true, // Enable SW in dev mode
        type: "module", // ES modules
        navigateFallback: "index.html",
      },
    }),
  ],
}));
```

### Alternative: generateSW Strategy

```typescript
VitePWA({
  registerType: "autoUpdate",
  strategies: "generateSW", // Auto-generate SW

  workbox: {
    // Runtime caching rules
    runtimeCaching: [
      {
        urlPattern: /^https:\/\/api\.example\.com\/.*/i,
        handler: "NetworkFirst",
        options: {
          cacheName: "api-cache",
          networkTimeoutSeconds: 5,
          expiration: {
            maxEntries: 100,
            maxAgeSeconds: 60 * 60, // 1 hour
          },
        },
      },
    ],
    // Files to skip
    navigateFallbackDenylist: [/^\/api\//],
  },
})
```

---

## 6. SERVICE WORKER BASE SETUP

### TypeScript Service Worker (src/sw.ts)

```typescript
/// <reference lib="webworker" />
import { precacheAndRoute, cleanupOutdatedCaches } from "workbox-precaching";
import { registerRoute, NavigationRoute, Route } from "workbox-routing";
import {
  CacheFirst,
  NetworkFirst,
  StaleWhileRevalidate,
} from "workbox-strategies";
import { ExpirationPlugin } from "workbox-expiration";
import { CacheableResponsePlugin } from "workbox-cacheable-response";

// TypeScript global scope declaration
declare const self: ServiceWorkerGlobalScope;

// Precache all assets from build manifest
precacheAndRoute(self.__WB_MANIFEST);

// Clean up old caches from previous versions
cleanupOutdatedCaches();

// Version management
const CACHE_VERSION = "v1";
const BUILD_TIMESTAMP = Date.now();

export {};
```

---

## 7. CACHE STRATEGY IMPLEMENTATIONS

### CacheFirst with Expiration (Images, Fonts)

```typescript
// Images - Cache First with 7-day expiration
registerRoute(
  ({ request }) => request.destination === "image",
  new CacheFirst({
    cacheName: "images-v1",
    plugins: [
      new ExpirationPlugin({
        maxEntries: 200,           // Max 200 images
        maxAgeSeconds: 7 * 24 * 60 * 60, // 7 days
        purgeOnQuotaError: true,   // Remove if storage quota exceeded
      }),
      new CacheableResponsePlugin({
        statuses: [0, 200],        // Cache opaque and successful responses
      }),
    ],
  }),
);

// Fonts - Cache First with 1-year expiration
registerRoute(
  ({ request }) => request.destination === "font",
  new CacheFirst({
    cacheName: "fonts-v1",
    plugins: [
      new ExpirationPlugin({
        maxEntries: 30,
        maxAgeSeconds: 365 * 24 * 60 * 60, // 1 year
      }),
      new CacheableResponsePlugin({ statuses: [0, 200] }),
    ],
  }),
);

// Google Fonts - Cache First
registerRoute(
  ({ url }) =>
    url.origin === "https://fonts.googleapis.com" ||
    url.origin === "https://fonts.gstatic.com",
  new CacheFirst({
    cacheName: "google-fonts-v1",
    plugins: [
      new ExpirationPlugin({
        maxEntries: 30,
        maxAgeSeconds: 365 * 24 * 60 * 60,
      }),
    ],
  }),
);
```

### NetworkFirst with Timeout (API Calls)

```typescript
// API calls - Network First with 3-second timeout
registerRoute(
  ({ url }) =>
    url.hostname.includes("supabase.co") &&
    url.pathname.startsWith("/rest/"),
  new NetworkFirst({
    cacheName: "api-v1",
    networkTimeoutSeconds: 3, // Fall back to cache after 3s
    plugins: [
      new ExpirationPlugin({
        maxEntries: 300,
        maxAgeSeconds: 5 * 60, // 5 minutes
      }),
      new CacheableResponsePlugin({ statuses: [0, 200] }),
    ],
  }),
);

// SVG assets - Network First for quick updates
registerRoute(
  ({ url }) => url.pathname.endsWith(".svg"),
  new NetworkFirst({
    cacheName: "svg-v1",
    networkTimeoutSeconds: 3,
    plugins: [
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 24 * 60 * 60, // 1 day
        purgeOnQuotaError: true,
      }),
      new CacheableResponsePlugin({ statuses: [0, 200] }),
    ],
  }),
);
```

### StaleWhileRevalidate (JS/CSS, Navigation)

```typescript
// JS & CSS - Instant load with background update
registerRoute(
  ({ request }) =>
    request.destination === "script" ||
    request.destination === "style",
  new StaleWhileRevalidate({
    cacheName: "static-v1",
    plugins: [
      new ExpirationPlugin({
        maxEntries: 100,
        maxAgeSeconds: 7 * 24 * 60 * 60, // 7 days
        purgeOnQuotaError: true,
      }),
      new CacheableResponsePlugin({ statuses: [0, 200] }),
    ],
  }),
);

// Navigation - Fast page loads
const navigationHandler = new StaleWhileRevalidate({
  cacheName: "pages-v1",
  plugins: [
    new ExpirationPlugin({
      maxEntries: 50,
      maxAgeSeconds: 24 * 60 * 60, // 1 day
      purgeOnQuotaError: true,
    }),
    new CacheableResponsePlugin({ statuses: [0, 200] }),
  ],
});

registerRoute(
  new NavigationRoute(navigationHandler, {
    // Exclude these paths from caching
    denylist: [/^\/_/, /\/api\//],
  }),
);
```

---

## 8. UPDATE MECHANISMS

### Force Update Pattern (Aggressive)

Use when critical updates must be applied immediately.

```typescript
// Current cache version - bump on ANY deployment
const CACHE_VERSION = "v6";
const BUILD_TIMESTAMP = Date.now();

// FORCE UPDATE: Skip waiting and clear all caches
self.addEventListener("install", (event) => {
  event.waitUntil(
    Promise.all([
      // Activate immediately without waiting for old SW to finish
      self.skipWaiting(),

      // Clear ALL caches to ensure fresh content
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => caches.delete(cacheName)),
        );
      }),
    ]),
  );
});

// CRITICAL: On activate, claim all clients and notify them
self.addEventListener("activate", (event) => {
  event.waitUntil(
    Promise.all([
      // Take control of all clients immediately
      self.clients.claim(),

      // Clear any remaining caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => caches.delete(cacheName)),
        );
      }),
    ]).then(async () => {
      // Notify all clients about the new version
      const clients = await self.clients.matchAll({ type: "window" });
      for (const client of clients) {
        client.postMessage({
          type: "SW_UPDATED",
          version: CACHE_VERSION,
          timestamp: BUILD_TIMESTAMP,
        });
      }
    }),
  );
});
```

### Soft Update Pattern (User-Friendly)

Use when updates can wait for user action.

```typescript
// sw.ts - Wait for user confirmation
self.addEventListener("install", (event) => {
  // Don't skip waiting - wait for user to accept update
  console.log("[SW] New version available, waiting for user action");
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") {
    // User accepted update - activate new SW
    self.skipWaiting();
  }
});

// Client-side: Show update toast
// src/hooks/useServiceWorkerUpdate.ts
import { useEffect, useState } from "react";

export function useServiceWorkerUpdate() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [registration, setRegistration] = useState<ServiceWorkerRegistration | null>(null);

  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;

    navigator.serviceWorker.ready.then((reg) => {
      setRegistration(reg);

      // Check for updates
      reg.addEventListener("updatefound", () => {
        const newWorker = reg.installing;
        if (!newWorker) return;

        newWorker.addEventListener("statechange", () => {
          if (newWorker.state === "installed" && navigator.serviceWorker.controller) {
            // New version available
            setUpdateAvailable(true);
          }
        });
      });
    });

    // Listen for SW update messages
    navigator.serviceWorker.addEventListener("message", (event) => {
      if (event.data?.type === "SW_UPDATED") {
        console.log(`[App] SW updated to ${event.data.version}`);
      }
    });
  }, []);

  const acceptUpdate = () => {
    if (registration?.waiting) {
      registration.waiting.postMessage({ type: "SKIP_WAITING" });
      // Reload after new SW takes over
      navigator.serviceWorker.addEventListener("controllerchange", () => {
        window.location.reload();
      });
    }
  };

  return { updateAvailable, acceptUpdate };
}

// Usage in component
function UpdateToast() {
  const { updateAvailable, acceptUpdate } = useServiceWorkerUpdate();

  if (!updateAvailable) return null;

  return (
    <div className="fixed bottom-4 inset-e-4 bg-primary text-primary-foreground p-4 rounded-lg shadow-lg">
      <p>גרסה חדשה זמינה!</p>
      <button onClick={acceptUpdate} className="mt-2 underline">
        עדכן עכשיו
      </button>
    </div>
  );
}
```

---

## 9. BACKGROUND SYNC

### IndexedDB Helpers

```typescript
const DB_NAME = "app-offline-db";
const DB_VERSION = 2;

// Open IndexedDB connection
function openSyncDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;

      // Create stores if they don't exist
      if (!db.objectStoreNames.contains("syncQueue")) {
        db.createObjectStore("syncQueue", { keyPath: "id", autoIncrement: true });
      }
      if (!db.objectStoreNames.contains("metadata")) {
        db.createObjectStore("metadata", { keyPath: "key" });
      }
    };
  });
}

// Get all items from a store
async function getAllFromStore<T>(storeName: string): Promise<T[]> {
  const db = await openSyncDB();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(storeName, "readonly");
    const store = transaction.objectStore(storeName);
    const request = store.getAll();

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    transaction.oncomplete = () => db.close();
  });
}

// Delete item from store
async function deleteFromStore(storeName: string, id: string | number): Promise<void> {
  const db = await openSyncDB();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(storeName, "readwrite");
    const store = transaction.objectStore(storeName);
    const request = store.delete(id);

    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
    transaction.oncomplete = () => db.close();
  });
}

// Get metadata value
async function getMetadata(key: string): Promise<string | undefined> {
  const db = await openSyncDB();
  return new Promise((resolve, reject) => {
    const transaction = db.transaction("metadata", "readonly");
    const store = transaction.objectStore("metadata");
    const request = store.get(key);

    request.onsuccess = () => resolve(request.result?.value);
    request.onerror = () => reject(request.error);
    transaction.oncomplete = () => db.close();
  });
}
```

### Queue Management with Retry

```typescript
interface SyncQueueItem {
  id: number;
  type: "create" | "update" | "delete";
  table: string;
  data: Record<string, unknown>;
  timestamp: number;
  retryCount: number;
}

const MAX_RETRIES = 3;

// Listen for sync events
self.addEventListener("sync", (event) => {
  if (event.tag === "sync-data") {
    event.waitUntil(processQueue());
  }
});

// Process all queued operations
async function processQueue(): Promise<void> {
  try {
    // Get API credentials from IndexedDB
    const apiUrl = await getMetadata("apiUrl");
    const apiKey = await getMetadata("apiKey");

    if (!apiUrl || !apiKey) {
      await notifyClients({
        type: "SYNC_NEEDED",
        reason: "missing_credentials",
      });
      return;
    }

    const queue = await getAllFromStore<SyncQueueItem>("syncQueue");

    if (queue.length === 0) {
      return;
    }

    let successCount = 0;
    let errorCount = 0;

    for (const operation of queue) {
      try {
        await processSyncOperation(operation, apiUrl, apiKey);

        // Remove successful operation from queue
        if (operation.id) {
          await deleteFromStore("syncQueue", operation.id);
        }
        successCount++;
      } catch (error) {
        errorCount++;
        console.error("[SW] Sync operation failed:", error);

        // Remove after max retries
        if (operation.retryCount >= MAX_RETRIES && operation.id) {
          await deleteFromStore("syncQueue", operation.id);
          // Optionally move to failed queue for manual retry
        }
      }
    }

    // Notify clients of sync completion
    await notifyClients({
      type: "SYNC_COMPLETE",
      successCount,
      errorCount,
    });
  } catch (error) {
    console.error("[SW] Background sync failed:", error);
    await notifyClients({ type: "SYNC_ERROR", error: String(error) });
  }
}

// Process a single sync operation
async function processSyncOperation(
  operation: SyncQueueItem,
  apiUrl: string,
  apiKey: string,
): Promise<void> {
  const { type, table, data } = operation;

  const headers = {
    "Content-Type": "application/json",
    "apikey": apiKey,
    "Authorization": `Bearer ${apiKey}`,
    "Prefer": "return=representation",
  };

  const baseUrl = `${apiUrl}/rest/v1/${table}`;

  switch (type) {
    case "create": {
      const cleanData = { ...data };
      // Remove temp ID for server-generated ID
      if (typeof cleanData.id === "string" && cleanData.id.startsWith("temp_")) {
        delete cleanData.id;
      }

      const response = await fetch(baseUrl, {
        method: "POST",
        headers,
        body: JSON.stringify(cleanData),
      });

      if (!response.ok) {
        throw new Error(`Create failed: ${response.status}`);
      }
      break;
    }

    case "update": {
      const response = await fetch(`${baseUrl}?id=eq.${data.id}`, {
        method: "PATCH",
        headers,
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`Update failed: ${response.status}`);
      }
      break;
    }

    case "delete": {
      const response = await fetch(`${baseUrl}?id=eq.${data.id}`, {
        method: "DELETE",
        headers,
      });

      if (!response.ok) {
        throw new Error(`Delete failed: ${response.status}`);
      }
      break;
    }
  }
}
```

### Client-Side: Add to Sync Queue

```typescript
// src/lib/offline-queue.ts
export async function addToSyncQueue(
  type: "create" | "update" | "delete",
  table: string,
  data: Record<string, unknown>,
): Promise<void> {
  const db = await openDB();

  return new Promise((resolve, reject) => {
    const transaction = db.transaction("syncQueue", "readwrite");
    const store = transaction.objectStore("syncQueue");

    const item = {
      type,
      table,
      data,
      timestamp: Date.now(),
      retryCount: 0,
    };

    const request = store.add(item);
    request.onsuccess = () => {
      // Request background sync
      if ("serviceWorker" in navigator && "sync" in (window as any).SyncManager) {
        navigator.serviceWorker.ready.then((reg) => {
          reg.sync.register("sync-data");
        });
      }
      resolve();
    };
    request.onerror = () => reject(request.error);
  });
}
```

---

## 10. PERIODIC BACKGROUND SYNC

### Service Worker Handler

```typescript
// Extend global scope for Periodic Sync API
interface PeriodicSyncEvent extends ExtendableEvent {
  tag: string;
}

interface ServiceWorkerGlobalScopeWithSync extends ServiceWorkerGlobalScope {
  addEventListener(
    type: "periodicsync",
    listener: (event: PeriodicSyncEvent) => void,
  ): void;
}

declare const self: ServiceWorkerGlobalScopeWithSync;

// Listen for periodic sync events
self.addEventListener("periodicsync", (event: PeriodicSyncEvent) => {
  if (event.tag === "refresh-data") {
    event.waitUntil(refreshData());
  }
});

// Periodic background refresh
async function refreshData(): Promise<void> {
  try {
    const apiUrl = await getMetadata("apiUrl");
    const apiKey = await getMetadata("apiKey");

    if (!apiUrl || !apiKey) {
      return;
    }

    const headers = {
      "apikey": apiKey,
      "Authorization": `Bearer ${apiKey}`,
    };

    // Prefetch important data
    const response = await fetch(
      `${apiUrl}/rest/v1/items?select=id,name,status&order=updated_at.desc&limit=50`,
      { headers },
    );

    if (response.ok) {
      // Cache the response for offline use
      const cache = await caches.open("api-v1");
      await cache.put(
        new Request(`${apiUrl}/rest/v1/items`),
        response.clone(),
      );
    }

    // Notify clients that fresh data is available
    await notifyClients({ type: "DATA_REFRESHED" });
  } catch (error) {
    console.error("[SW] Periodic refresh failed:", error);
  }
}
```

### Client-Side: Register Periodic Sync

```typescript
// src/lib/periodic-sync.ts
export async function registerPeriodicSync(): Promise<boolean> {
  if (!("serviceWorker" in navigator)) return false;
  if (!("periodicSync" in ServiceWorkerRegistration.prototype)) return false;

  try {
    const registration = await navigator.serviceWorker.ready;

    // Check permission
    const status = await navigator.permissions.query({
      name: "periodic-background-sync" as PermissionName,
    });

    if (status.state !== "granted") {
      console.log("[App] Periodic sync permission not granted");
      return false;
    }

    // Register for periodic sync (minimum interval varies by browser)
    await registration.periodicSync.register("refresh-data", {
      minInterval: 12 * 60 * 60 * 1000, // 12 hours minimum
    });

    console.log("[App] Periodic sync registered");
    return true;
  } catch (error) {
    console.error("[App] Periodic sync registration failed:", error);
    return false;
  }
}
```

---

## 11. PUSH NOTIFICATIONS

### Complete Push Implementation

```typescript
// Push notification data interface
interface PushData {
  title?: string;
  body?: string;
  icon?: string;
  badge?: string;
  url?: string;
  tag?: string;
  requireInteraction?: boolean;
  vibrate?: number[];
  timestamp?: number;
  actions?: Array<{ action: string; title: string; icon?: string }>;
}

// Handle incoming push messages
self.addEventListener("push", (event) => {
  if (!event.data) return;

  try {
    const data: PushData = event.data.json();

    const options: NotificationOptions = {
      body: data.body || "",
      icon: data.icon || "/logo.svg",
      badge: data.badge || "/logo.svg",
      tag: data.tag || `notification-${Date.now()}`,
      data: { url: data.url || "/" },
      requireInteraction: data.requireInteraction !== false,
      vibrate: data.vibrate || [200, 100, 200],
      timestamp: data.timestamp || Date.now(),
      actions: data.actions || [
        { action: "open", title: "Open" },
        { action: "dismiss", title: "Dismiss" },
      ],
    } as NotificationOptions & { vibrate?: number[] };

    event.waitUntil(
      self.registration.showNotification(
        data.title || "New Notification",
        options,
      ),
    );
  } catch {
    // Fallback for plain text
    const text = event.data?.text() || "New update";
    event.waitUntil(
      self.registration.showNotification("Notification", {
        body: text,
        icon: "/logo.svg",
        badge: "/logo.svg",
      }),
    );
  }
});

// Handle notification clicks
// SECURITY: Always validate URL origin before navigating — open redirect risk
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  // Handle dismiss action
  if (event.action === "dismiss") return;

  // SECURITY: Validate URL to prevent open redirect attacks
  // Attacker-controlled push payload could set url = 'https://evil.com'
  const rawUrl = (event.notification.data as { url?: string })?.url;
  let safePath = "/"; // default to home
  if (rawUrl) {
    try {
      const parsed = new URL(rawUrl, self.location.origin);
      // Only allow same-origin navigation — block external URLs
      if (parsed.origin === self.location.origin) {
        safePath = parsed.pathname + parsed.search + parsed.hash;
      }
      // else: silently fall back to "/" — do NOT navigate to external origin
    } catch {
      // Invalid URL — use default
    }
  }

  event.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList) => {
        // Focus existing window if available
        for (const client of clientList) {
          if ("focus" in client) {
            client.focus();
            if ("navigate" in client) {
              return (client as WindowClient).navigate(safePath);
            }
            return client;
          }
        }
        // Open new window if none exists
        if (self.clients.openWindow) {
          return self.clients.openWindow(safePath);
        }
      }),
  );
});

// Handle notification close (user dismissed)
self.addEventListener("notificationclose", (event) => {
  // Track analytics or update state
  console.log("[SW] Notification closed:", event.notification.tag);
});
```

### Client-Side: Push Subscription

```typescript
// src/lib/push-notifications.ts

// Your VAPID public key (generate with web-push library)
const VAPID_PUBLIC_KEY = "YOUR_VAPID_PUBLIC_KEY";

// Convert base64 to Uint8Array for applicationServerKey
function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding)
    .replace(/-/g, "+")
    .replace(/_/g, "/");
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export async function subscribeToPush(): Promise<PushSubscription | null> {
  if (!("serviceWorker" in navigator)) {
    console.log("Service Worker not supported");
    return null;
  }

  if (!("PushManager" in window)) {
    console.log("Push notifications not supported");
    return null;
  }

  try {
    // Request notification permission
    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      console.log("Notification permission denied");
      return null;
    }

    const registration = await navigator.serviceWorker.ready;

    // Check for existing subscription
    let subscription = await registration.pushManager.getSubscription();

    if (!subscription) {
      // Create new subscription
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true, // Required: must show notification for each push
        applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
      });
    }

    // Send subscription to your server
    await fetch("/api/push/subscribe", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(subscription.toJSON()),
    });

    return subscription;
  } catch (error) {
    console.error("Push subscription failed:", error);
    return null;
  }
}

export async function unsubscribeFromPush(): Promise<boolean> {
  try {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.getSubscription();

    if (subscription) {
      // Notify server
      await fetch("/api/push/unsubscribe", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ endpoint: subscription.endpoint }),
      });

      // Unsubscribe locally
      await subscription.unsubscribe();
    }

    return true;
  } catch (error) {
    console.error("Push unsubscription failed:", error);
    return false;
  }
}
```

### Server-Side: Send Push (Node.js/Edge Function)

```typescript
// Using web-push library (Node.js) or fetch (Edge Function)
import webpush from "web-push";

// Configure VAPID keys
webpush.setVapidDetails(
  "mailto:admin@example.com",
  process.env.VAPID_PUBLIC_KEY!,
  process.env.VAPID_PRIVATE_KEY!,
);

export async function sendPushNotification(
  subscription: PushSubscription,
  payload: {
    title: string;
    body: string;
    url?: string;
    tag?: string;
  },
): Promise<void> {
  await webpush.sendNotification(subscription, JSON.stringify(payload));
}
```

---

## 12. SHARE TARGET

### Manifest Configuration (manifest.json)

```json
{
  "name": "My App",
  "short_name": "App",
  "share_target": {
    "action": "/?share-target",
    "method": "POST",
    "enctype": "multipart/form-data",
    "params": {
      "title": "title",
      "text": "text",
      "url": "url",
      "files": [
        {
          "name": "images",
          "accept": ["image/*"]
        }
      ]
    }
  }
}
```

### Service Worker Handler

```typescript
// Handle share target requests
self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  // Check if this is a share target request
  if (url.pathname === "/" && url.searchParams.has("share-target")) {
    event.respondWith(handleShareTarget(event.request));
  }
});

async function handleShareTarget(request: Request): Promise<Response> {
  try {
    const formData = await request.formData();

    const title = formData.get("title") as string | null;
    const text = formData.get("text") as string | null;
    const url = formData.get("url") as string | null;

    // Handle file shares
    const files = formData.getAll("images") as File[];

    if (files.length > 0) {
      // Store files temporarily for the app to process
      const cache = await caches.open("share-target-files");
      for (const file of files) {
        const response = new Response(file);
        await cache.put(`/shared-file-${Date.now()}`, response);
      }
    }

    // Redirect to app with shared data
    const redirectUrl = new URL("/", request.url);
    redirectUrl.searchParams.set("shared", "true");
    if (title) redirectUrl.searchParams.set("title", title);
    if (text) redirectUrl.searchParams.set("text", text);
    if (url) redirectUrl.searchParams.set("url", url);
    if (files.length > 0) redirectUrl.searchParams.set("files", String(files.length));

    return Response.redirect(redirectUrl.toString(), 303);
  } catch (error) {
    console.error("[SW] Share target handling failed:", error);
    return Response.redirect("/", 303);
  }
}
```

### Client-Side: Handle Shared Content

```typescript
// src/hooks/useShareTarget.ts
import { useEffect, useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";

interface SharedContent {
  title?: string;
  text?: string;
  url?: string;
  files?: File[];
}

export function useShareTarget() {
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();
  const [sharedContent, setSharedContent] = useState<SharedContent | null>(null);

  useEffect(() => {
    if (searchParams.get("shared") === "true") {
      const content: SharedContent = {
        title: searchParams.get("title") || undefined,
        text: searchParams.get("text") || undefined,
        url: searchParams.get("url") || undefined,
      };

      // Load files from cache if any were shared
      const fileCount = parseInt(searchParams.get("files") || "0");
      if (fileCount > 0) {
        loadSharedFiles().then((files) => {
          content.files = files;
          setSharedContent(content);
        });
      } else {
        setSharedContent(content);
      }

      // Clear share params from URL
      searchParams.delete("shared");
      searchParams.delete("title");
      searchParams.delete("text");
      searchParams.delete("url");
      searchParams.delete("files");
      setSearchParams(searchParams, { replace: true });
    }
  }, [searchParams, setSearchParams]);

  return sharedContent;
}

async function loadSharedFiles(): Promise<File[]> {
  const cache = await caches.open("share-target-files");
  const keys = await cache.keys();
  const files: File[] = [];

  for (const request of keys) {
    const response = await cache.match(request);
    if (response) {
      const blob = await response.blob();
      files.push(new File([blob], request.url.split("/").pop() || "shared-file"));
      await cache.delete(request);
    }
  }

  return files;
}
```

---

## 13. CLIENT COMMUNICATION

### postMessage Patterns

```typescript
// Notify all clients utility
async function notifyClients(message: Record<string, unknown>): Promise<void> {
  const clients = await self.clients.matchAll({ type: "window" });
  for (const client of clients) {
    client.postMessage(message);
  }
}

// Message types
type SWMessage =
  | { type: "SW_UPDATED"; version: string; timestamp: number }
  | { type: "DATA_REFRESHED" }
  | { type: "SYNC_COMPLETE"; successCount: number; errorCount: number }
  | { type: "SYNC_ERROR"; error: string }
  | { type: "SYNC_NEEDED"; reason: string }
  | { type: "CACHE_COMPLETE"; urls: string[] };

// Listen for messages from clients
self.addEventListener("message", (event) => {
  const data = event.data as { type: string; [key: string]: unknown };

  switch (data.type) {
    case "SKIP_WAITING":
      self.skipWaiting();
      break;

    case "CACHE_URLS":
      // Prefetch specific URLs on demand
      const urls = data.urls as string[];
      event.waitUntil(
        caches.open("prefetch-v1")
          .then((cache) => cache.addAll(urls))
          .then(() => notifyClients({ type: "CACHE_COMPLETE", urls })),
      );
      break;

    case "GET_VERSION":
      // Respond with current version
      event.source?.postMessage({
        type: "VERSION_INFO",
        version: CACHE_VERSION,
        timestamp: BUILD_TIMESTAMP,
      });
      break;

    case "CLEAR_CACHE":
      // Manual cache clear
      event.waitUntil(
        caches.keys()
          .then((names) => Promise.all(names.map((name) => caches.delete(name))))
          .then(() => notifyClients({ type: "CACHE_CLEARED" })),
      );
      break;
  }
});
```

### Client-Side: Listen for Messages

```typescript
// src/hooks/useServiceWorkerMessages.ts
import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

type SWMessageHandler = {
  SW_UPDATED?: (data: { version: string; timestamp: number }) => void;
  DATA_REFRESHED?: () => void;
  SYNC_COMPLETE?: (data: { successCount: number; errorCount: number }) => void;
  SYNC_ERROR?: (data: { error: string }) => void;
};

export function useServiceWorkerMessages(handlers: SWMessageHandler = {}) {
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;

    const handleMessage = (event: MessageEvent) => {
      const { type, ...data } = event.data;

      switch (type) {
        case "SW_UPDATED":
          handlers.SW_UPDATED?.(data as { version: string; timestamp: number });
          toast.info("Application updated. Refresh to see changes.");
          break;

        case "DATA_REFRESHED":
          handlers.DATA_REFRESHED?.();
          // Invalidate queries to refetch from updated cache
          queryClient.invalidateQueries();
          break;

        case "SYNC_COMPLETE":
          handlers.SYNC_COMPLETE?.(data as { successCount: number; errorCount: number });
          toast.success(`Synced ${data.successCount} items`);
          queryClient.invalidateQueries();
          break;

        case "SYNC_ERROR":
          handlers.SYNC_ERROR?.(data as { error: string });
          toast.error("Sync failed. Will retry later.");
          break;
      }
    };

    navigator.serviceWorker.addEventListener("message", handleMessage);
    return () => {
      navigator.serviceWorker.removeEventListener("message", handleMessage);
    };
  }, [handlers, queryClient]);
}

// Usage
function App() {
  useServiceWorkerMessages({
    DATA_REFRESHED: () => {
      console.log("Background data refresh completed");
    },
  });

  return <div>...</div>;
}
```

---

## 14. DEBUGGING

### Chrome DevTools Application Tab

1. **Service Workers panel**
   - View registered workers
   - Update, unregister, or skip waiting
   - Check status (activated, waiting, installing)

2. **Cache Storage panel**
   - Inspect cached responses
   - Delete individual cache entries
   - Clear all caches

3. **Background Services panel**
   - Monitor background sync events
   - View periodic sync registrations
   - Test push notifications

### Workbox Debug Logging

```typescript
// Enable debug logging in development
import { setCacheNameDetails } from "workbox-core";

// Set prefix for cache names (helpful for debugging)
setCacheNameDetails({
  prefix: "my-app",
  suffix: "v1",
  precache: "precache",
  runtime: "runtime",
});

// In sw.ts - enable debug mode
if (process.env.NODE_ENV === "development") {
  console.log("[SW] Debug mode enabled");

  // Log all cache operations
  self.addEventListener("fetch", (event) => {
    console.log("[SW] Fetch:", event.request.url);
  });
}
```

### Network Request Tracking

```typescript
// Add to sw.ts for debugging network issues
const originalFetch = self.fetch;

self.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
  const request = input instanceof Request ? input : new Request(input);
  const startTime = performance.now();

  try {
    const response = await originalFetch(input, init);
    const duration = performance.now() - startTime;

    console.log(`[SW] ${request.method} ${request.url} - ${response.status} (${duration.toFixed(0)}ms)`);

    return response;
  } catch (error) {
    console.error(`[SW] ${request.method} ${request.url} - FAILED`, error);
    throw error;
  }
};
```

### Cache Inspection Utility

```typescript
// Add to sw.ts or run in console
async function inspectCaches(): Promise<void> {
  const cacheNames = await caches.keys();

  for (const name of cacheNames) {
    const cache = await caches.open(name);
    const keys = await cache.keys();

    console.group(`Cache: ${name} (${keys.length} entries)`);
    for (const request of keys) {
      const response = await cache.match(request);
      console.log(`  ${request.url} - ${response?.status || "missing"}`);
    }
    console.groupEnd();
  }
}

// Expose for debugging
(self as any).inspectCaches = inspectCaches;
```

### Testing Tips

```typescript
// 1. Simulate offline mode
// In DevTools: Network tab > Throttling > Offline

// 2. Test background sync
// In DevTools: Application > Service Workers > Sync

// 3. Force update service worker
// In DevTools: Application > Service Workers > Update

// 4. Clear all storage
// In DevTools: Application > Storage > Clear site data

// 5. Test push notifications
navigator.serviceWorker.ready.then((reg) => {
  reg.showNotification("Test", { body: "Test notification" });
});
```

---

## 15. EVENT LIFECYCLE REFERENCE

```
1. Registration
   navigator.serviceWorker.register('/sw.js')

2. Installation
   install event -> precache assets -> waitUntil()

3. Waiting (if old SW still active)
   skipWaiting() or user closes all tabs

4. Activation
   activate event -> clean old caches -> clients.claim()

5. Running
   fetch events -> apply cache strategies
   push events -> show notifications
   sync events -> process background queue
   message events -> client communication
```

---

## 16. OLD ANDROID & WEBVIEW COMPATIBILITY

### Service Worker Support Matrix

| Platform | SW Support | Notes |
|----------|------------|-------|
| Chrome Android 40+ | Full | Standard support |
| Android WebView 40+ | Full | Capacitor uses system WebView |
| Android 5.0-5.1 (WebView) | Partial | Bugs with fetch events |
| Android 4.x | None | No SW support at all |
| Samsung Internet 4+ | Full | Popular on Samsung devices |
| UC Browser | Limited | Some features missing |

### Detecting WebView vs Browser

```typescript
// Check if running in WebView (Capacitor/Cordova)
function isWebView(): boolean {
  const ua = navigator.userAgent.toLowerCase();

  // Android WebView
  if (ua.includes("wv") || ua.includes("webview")) return true;

  // Capacitor
  if ((window as any).Capacitor) return true;

  // Cordova
  if ((window as any).cordova) return true;

  // iOS WKWebView (older detection)
  if (ua.includes("iphone") && !ua.includes("safari")) return true;

  return false;
}

// Check SW support before registering
function canUseServiceWorker(): boolean {
  // Basic feature detection
  if (!("serviceWorker" in navigator)) return false;

  // Check for caches API (required for caching strategies)
  if (!("caches" in window)) return false;

  // Android WebView version check (optional)
  const androidMatch = navigator.userAgent.match(/Android\s([0-9.]+)/);
  if (androidMatch) {
    const version = parseFloat(androidMatch[1]);
    // Android < 5.0 has unreliable SW support
    if (version < 5.0) return false;
  }

  return true;
}
```

### Cache API Limitations

#### Storage Quotas by Platform

| Platform | Available Storage | Eviction Policy |
|----------|-------------------|-----------------|
| Chrome Desktop | 80% of disk | LRU when full |
| Chrome Android | ~100MB guaranteed | LRU, aggressive on low storage |
| Android WebView | Varies by device | More aggressive eviction |
| Old Android (5.x) | ~50MB typical | Very aggressive |
| iOS Safari | 50MB initial, up to 500MB | Per-origin, strict |

#### Handling Quota Errors

```typescript
// Safe caching with quota handling
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
    // QuotaExceededError - storage is full
    if (error instanceof DOMException && error.name === "QuotaExceededError") {
      console.warn("[SW] Storage quota exceeded, cleaning old caches");
      await cleanOldCaches();

      // Retry once after cleanup
      try {
        const cache = await caches.open(cacheName);
        await cache.put(request, response);
        return true;
      } catch {
        return false;
      }
    }
    throw error;
  }
}

// Clean old caches when quota exceeded
async function cleanOldCaches(): Promise<void> {
  const cacheNames = await caches.keys();

  // Delete oldest/largest caches first
  const cacheInfo = await Promise.all(
    cacheNames.map(async (name) => {
      const cache = await caches.open(name);
      const keys = await cache.keys();
      return { name, count: keys.length };
    }),
  );

  // Sort by entry count (largest first)
  cacheInfo.sort((a, b) => b.count - a.count);

  // Delete half of the largest cache
  if (cacheInfo.length > 0) {
    const largest = cacheInfo[0];
    const cache = await caches.open(largest.name);
    const keys = await cache.keys();
    const toDelete = keys.slice(0, Math.floor(keys.length / 2));

    for (const key of toDelete) {
      await cache.delete(key);
    }
  }
}

// Check available storage (where supported)
async function getStorageEstimate(): Promise<{
  quota?: number;
  usage?: number;
  available?: number;
}> {
  if ("storage" in navigator && "estimate" in navigator.storage) {
    const estimate = await navigator.storage.estimate();
    return {
      quota: estimate.quota,
      usage: estimate.usage,
      available: estimate.quota && estimate.usage
        ? estimate.quota - estimate.usage
        : undefined,
    };
  }
  return {};
}
```

#### Old Android Cache API Bugs

```typescript
// Workaround: Some old Android versions have issues with cache.match()
// returning undefined even when the item exists
async function safeCacheMatch(
  cacheName: string,
  request: Request | string,
): Promise<Response | undefined> {
  try {
    const cache = await caches.open(cacheName);
    let response = await cache.match(request);

    // Workaround for old Android bug: try with ignoreSearch
    if (!response && typeof request === "string") {
      response = await cache.match(request, { ignoreSearch: true });
    }

    return response;
  } catch (error) {
    console.error("[SW] Cache match failed:", error);
    return undefined;
  }
}

// Old Android may not support all Response properties
function isCacheableResponse(response: Response): boolean {
  // Check status (0 is opaque, 200 is success)
  if (response.status !== 0 && response.status !== 200) return false;

  // Some old Android versions have issues with certain response types
  try {
    // Attempt to clone - fails on some corrupted responses
    response.clone();
    return true;
  } catch {
    return false;
  }
}
```

### Background Sync Limitations

#### Browser Support Matrix

| Feature | Chrome Android | Samsung Internet | Firefox Android | iOS Safari |
|---------|----------------|------------------|-----------------|------------|
| Background Sync | Yes (40+) | Yes (4+) | No | No |
| Periodic Sync | Yes (80+, high engagement) | No | No | No |
| Sync retry | Automatic | Automatic | N/A | N/A |

#### Fallback for Unsupported Browsers

```typescript
// Client-side: Check Background Sync support and provide fallback
export async function queueOfflineOperation(
  type: "create" | "update" | "delete",
  table: string,
  data: Record<string, unknown>,
): Promise<void> {
  // Always save to IndexedDB first
  await addToIndexedDBQueue(type, table, data);

  // Check if Background Sync is supported
  if ("serviceWorker" in navigator && "sync" in ServiceWorkerRegistration.prototype) {
    try {
      const registration = await navigator.serviceWorker.ready;
      await registration.sync.register("sync-data");
      console.log("[App] Background Sync registered");
    } catch (error) {
      console.warn("[App] Background Sync failed, using fallback:", error);
      // Fallback: try immediate sync
      await attemptImmediateSync();
    }
  } else {
    console.log("[App] Background Sync not supported, using online listener");
    // Fallback: sync when online
    setupOnlineListener();
  }
}

// Fallback 1: Immediate sync attempt
async function attemptImmediateSync(): Promise<void> {
  if (!navigator.onLine) {
    console.log("[App] Offline - will sync when online");
    setupOnlineListener();
    return;
  }

  try {
    // Notify SW to process queue immediately
    const registration = await navigator.serviceWorker.ready;
    registration.active?.postMessage({ type: "PROCESS_SYNC_QUEUE" });
  } catch (error) {
    console.error("[App] Immediate sync failed:", error);
  }
}

// Fallback 2: Online event listener
let onlineListenerSetup = false;
function setupOnlineListener(): void {
  if (onlineListenerSetup) return;
  onlineListenerSetup = true;

  window.addEventListener("online", async () => {
    console.log("[App] Back online - syncing queued operations");
    await attemptImmediateSync();
    // NOTE: reloadOnOnline: false - preserves form data
  });
}
```

> **CRITICAL**: Never set `reloadOnOnline: true` in your PWA configuration - it causes form data loss when connection is restored! Always use `reloadOnOnline: false` to preserve user input.

```typescript
// PWA Configuration Example
{
  reloadOnOnline: false,  // CORRECT - Preserves form data
  // reloadOnOnline: true,  // WRONG - Causes form data loss!
}

// SW side: Handle fallback sync request
self.addEventListener("message", (event) => {
  if (event.data?.type === "PROCESS_SYNC_QUEUE") {
    event.waitUntil(processQueue());
  }
});
```

#### Periodic Background Sync Limitations

```typescript
// Periodic Sync has very limited support
// Only Chrome 80+ with high site engagement
async function registerPeriodicSyncSafe(): Promise<{
  supported: boolean;
  registered: boolean;
  fallbackActive: boolean;
}> {
  const result = {
    supported: false,
    registered: false,
    fallbackActive: false,
  };

  // Check if Periodic Sync is available
  if (!("periodicSync" in ServiceWorkerRegistration.prototype)) {
    console.log("[App] Periodic Sync not supported - using interval fallback");
    setupIntervalFallback();
    result.fallbackActive = true;
    return result;
  }

  result.supported = true;

  try {
    const registration = await navigator.serviceWorker.ready;

    // Check permission
    const status = await navigator.permissions.query({
      name: "periodic-background-sync" as PermissionName,
    });

    if (status.state === "granted") {
      await registration.periodicSync.register("refresh-data", {
        minInterval: 12 * 60 * 60 * 1000, // 12 hours
      });
      result.registered = true;
    } else {
      console.log("[App] Periodic Sync permission not granted - using fallback");
      setupIntervalFallback();
      result.fallbackActive = true;
    }
  } catch (error) {
    console.warn("[App] Periodic Sync registration failed:", error);
    setupIntervalFallback();
    result.fallbackActive = true;
  }

  return result;
}

// Fallback: Use setInterval when page is active
function setupIntervalFallback(): void {
  // Refresh data every 15 minutes when app is active
  setInterval(async () => {
    if (document.visibilityState === "visible" && navigator.onLine) {
      console.log("[App] Interval fallback - refreshing data");
      // Trigger data refresh
      window.dispatchEvent(new CustomEvent("refresh-data"));
    }
  }, 15 * 60 * 1000);

  // Also refresh on visibility change
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible" && navigator.onLine) {
      window.dispatchEvent(new CustomEvent("refresh-data"));
    }
  });
}
```

### Push Notification Differences

#### Platform Comparison

| Feature | Chrome Android | Samsung Internet | Firefox Android | iOS Safari (16.4+) |
|---------|----------------|------------------|-----------------|---------------------|
| Push API | Full | Full | Full | Limited |
| VAPID | Required | Required | Required | Required |
| Silent Push | No | No | No | No |
| Vibration | Yes | Yes | Yes | No |
| Actions | 2 max | 2 max | 2 max | No |
| Images | Yes | Yes | Yes | No |
| Badge | Yes | Yes | Yes | No |
| Persistent | Yes | Yes | Yes | No |
| requireInteraction | Yes | Yes | Yes | No |

#### Cross-Platform Push Implementation

```typescript
// Push handler with platform-specific options
self.addEventListener("push", (event) => {
  if (!event.data) return;

  const data: PushData = event.data.json();

  // Detect platform for feature support
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
  const isAndroid = /Android/.test(navigator.userAgent);

  // Base options (cross-platform safe)
  const options: NotificationOptions = {
    body: data.body || "",
    icon: data.icon || "/logo-192.png",
    tag: data.tag || `notification-${Date.now()}`,
    data: { url: data.url || "/" },
  };

  // Android-specific enhancements
  if (isAndroid) {
    Object.assign(options, {
      badge: data.badge || "/badge-72.png",
      vibrate: data.vibrate || [100, 50, 100],
      requireInteraction: data.requireInteraction ?? true,
      actions: [
        { action: "open", title: "פתח" },
        { action: "dismiss", title: "סגור" },
      ],
    });
  }

  // iOS limitations - simpler notification
  if (isIOS) {
    // iOS Safari (16.4+) has limited notification support
    // - No vibration
    // - No actions
    // - No badge
    // - No images in notification body
    // Keep options minimal for reliability
    delete (options as any).badge;
    delete (options as any).vibrate;
    delete (options as any).actions;
    delete (options as any).requireInteraction;
  }

  event.waitUntil(
    self.registration.showNotification(data.title || "הודעה חדשה", options),
  );
});

// iOS Safari push subscription differences
export async function subscribeToPushCrossPlatform(): Promise<{
  subscription: PushSubscription | null;
  platform: "android" | "ios" | "desktop";
  limitations: string[];
}> {
  const result = {
    subscription: null as PushSubscription | null,
    platform: "desktop" as "android" | "ios" | "desktop",
    limitations: [] as string[],
  };

  // Detect platform
  const ua = navigator.userAgent;
  if (/iPad|iPhone|iPod/.test(ua)) {
    result.platform = "ios";
    result.limitations = [
      "No vibration patterns",
      "No action buttons",
      "No badge icons",
      "No persistent notifications",
      "Must be installed as PWA",
    ];
  } else if (/Android/.test(ua)) {
    result.platform = "android";
    result.limitations = [
      "Max 2 action buttons",
      "Battery optimization may delay notifications",
    ];
  }

  // iOS Safari requires PWA to be installed for push
  if (result.platform === "ios") {
    const isStandalone = (window.navigator as any).standalone === true ||
      window.matchMedia("(display-mode: standalone)").matches;

    if (!isStandalone) {
      result.limitations.push("App must be installed to home screen for push");
      console.warn("[Push] iOS requires PWA installation for push notifications");
    }
  }

  // Standard push subscription
  try {
    const registration = await navigator.serviceWorker.ready;
    result.subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
    });
  } catch (error) {
    console.error("[Push] Subscription failed:", error);
  }

  return result;
}
```

#### Android Battery Optimization Impact

```typescript
// Android Doze mode and battery optimization can delay notifications
// Inform users about potential delays

export function checkAndroidBatteryOptimization(): {
  mayBeAffected: boolean;
  guidance: string;
} {
  const isAndroid = /Android/.test(navigator.userAgent);

  if (!isAndroid) {
    return { mayBeAffected: false, guidance: "" };
  }

  // Can't directly check battery optimization status from web
  // But we can provide guidance to users
  return {
    mayBeAffected: true,
    guidance: `
      לקבלת התראות בזמן אמת:
      1. פתח הגדרות -> אפליקציות -> Cash
      2. לחץ על "סוללה"
      3. בחר "ללא אופטימיזציה" או "ללא הגבלה"
    `,
  };
}

// Test push delivery with round-trip timing
export async function testPushDelivery(): Promise<{
  sent: number;
  received: number | null;
  latency: number | null;
}> {
  const sentTime = Date.now();

  return new Promise((resolve) => {
    const timeout = setTimeout(() => {
      resolve({
        sent: sentTime,
        received: null,
        latency: null,
      });
    }, 30000); // 30 second timeout

    // Listen for test push from SW
    navigator.serviceWorker.addEventListener("message", function handler(event) {
      if (event.data?.type === "PUSH_TEST_RECEIVED") {
        clearTimeout(timeout);
        navigator.serviceWorker.removeEventListener("message", handler);

        const receivedTime = Date.now();
        resolve({
          sent: sentTime,
          received: receivedTime,
          latency: receivedTime - sentTime,
        });
      }
    });

    // Request test push from server
    fetch("/api/push/test", { method: "POST" });
  });
}
```

### IndexedDB Quirks on Old Android

```typescript
// Old Android IndexedDB issues and workarounds

// Issue 1: Transaction may close prematurely
// Solution: Complete all operations synchronously within transaction
async function safeIDBTransaction<T>(
  storeName: string,
  mode: IDBTransactionMode,
  operations: (store: IDBObjectStore) => IDBRequest<T>[],
): Promise<T[]> {
  const db = await openDB();

  return new Promise((resolve, reject) => {
    const transaction = db.transaction(storeName, mode);
    const store = transaction.objectStore(storeName);
    const requests = operations(store);
    const results: T[] = [];

    let completed = 0;
    requests.forEach((request, index) => {
      request.onsuccess = () => {
        results[index] = request.result;
        completed++;
        if (completed === requests.length) {
          // All done
        }
      };
      request.onerror = () => reject(request.error);
    });

    transaction.oncomplete = () => {
      db.close();
      resolve(results);
    };
    transaction.onerror = () => {
      db.close();
      reject(transaction.error);
    };
  });
}

// Issue 2: Database may not open on first try (race condition)
// Solution: Retry with exponential backoff
async function openDBWithRetry(
  maxRetries = 3,
  baseDelay = 100,
): Promise<IDBDatabase> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await openSyncDB();
    } catch (error) {
      lastError = error as Error;

      // Wait before retry (exponential backoff)
      const delay = baseDelay * Math.pow(2, attempt);
      await new Promise((r) => setTimeout(r, delay));

      console.warn(`[IDB] Retry ${attempt + 1}/${maxRetries} after ${delay}ms`);
    }
  }

  throw lastError;
}

// Issue 3: Storage may be cleared unexpectedly on low storage
// Solution: Request persistent storage
async function requestPersistentStorage(): Promise<boolean> {
  if (!navigator.storage?.persist) {
    console.log("[Storage] Persistent storage API not available");
    return false;
  }

  // Check if already persistent
  const isPersisted = await navigator.storage.persisted();
  if (isPersisted) {
    console.log("[Storage] Already using persistent storage");
    return true;
  }

  // Request persistent storage
  const granted = await navigator.storage.persist();
  console.log(`[Storage] Persistent storage ${granted ? "granted" : "denied"}`);

  return granted;
}
```

### Feature Detection Utility

```typescript
// Comprehensive SW feature detection for old Android compatibility
export interface SWFeatures {
  serviceWorker: boolean;
  cacheAPI: boolean;
  backgroundSync: boolean;
  periodicSync: boolean;
  pushManager: boolean;
  notifications: boolean;
  persistentStorage: boolean;
  indexedDB: boolean;
  storageEstimate: boolean;
}

export async function detectSWFeatures(): Promise<SWFeatures> {
  const features: SWFeatures = {
    serviceWorker: "serviceWorker" in navigator,
    cacheAPI: "caches" in window,
    backgroundSync: false,
    periodicSync: false,
    pushManager: "PushManager" in window,
    notifications: "Notification" in window,
    persistentStorage: !!navigator.storage?.persist,
    indexedDB: "indexedDB" in window,
    storageEstimate: !!navigator.storage?.estimate,
  };

  // Check Background Sync (requires SW registration)
  if (features.serviceWorker) {
    features.backgroundSync = "sync" in ServiceWorkerRegistration.prototype;
    features.periodicSync = "periodicSync" in ServiceWorkerRegistration.prototype;
  }

  return features;
}

// Log feature support on startup
export async function logFeatureSupport(): Promise<void> {
  const features = await detectSWFeatures();

  console.group("[PWA] Feature Support");
  Object.entries(features).forEach(([feature, supported]) => {
    console.log(`${supported ? "+" : "-"} ${feature}`);
  });
  console.groupEnd();

  // Warn about critical missing features
  if (!features.serviceWorker) {
    console.warn("[PWA] Service Worker not supported - offline mode unavailable");
  }
  if (!features.backgroundSync) {
    console.warn("[PWA] Background Sync not supported - using online listener fallback");
  }
  if (!features.pushManager) {
    console.warn("[PWA] Push notifications not supported");
  }
}
```

---

## 17. PASSIVE EVENT LISTENERS (MANDATORY)

For smooth scrolling on mobile, ALL touch/scroll events MUST use passive listeners.

### Why Passive Listeners Matter

Non-passive touch event listeners block the browser's main thread while waiting to see if `preventDefault()` will be called. This causes scroll jank and poor touch responsiveness, especially on mobile devices.

### Implementation

```typescript
// WRONG - Blocks scrolling on mobile
element.addEventListener('touchstart', handler);
element.addEventListener('touchmove', handler);
element.addEventListener('wheel', handler);
element.addEventListener('scroll', handler);

// CORRECT - Smooth scrolling with passive listeners
element.addEventListener('touchstart', handler, { passive: true });
element.addEventListener('touchmove', handler, { passive: true });
element.addEventListener('wheel', handler, { passive: true });
element.addEventListener('scroll', handler, { passive: true });
```

### Events That MUST Be Passive

| Event | Reason |
|-------|--------|
| `touchstart` | Scroll start detection |
| `touchmove` | Scroll tracking |
| `wheel` | Mouse wheel scrolling |
| `scroll` | Scroll position updates |

### When You Need preventDefault()

If you must call `preventDefault()` (e.g., to prevent pull-to-refresh), use `{ passive: false }` explicitly and document why:

```typescript
// Only use passive: false when you MUST prevent default behavior
// Document the reason for future maintainers
element.addEventListener('touchmove', (e) => {
  // Prevent pull-to-refresh on this specific element
  if (shouldPreventRefresh) {
    e.preventDefault();
  }
}, { passive: false }); // Required for preventDefault()
```

### React/Preact Consideration

React's synthetic events are passive by default for touch events in React 17+. However, when using `addEventListener` directly (e.g., in `useEffect`), always specify `{ passive: true }`:

```typescript
useEffect(() => {
  const handler = (e: TouchEvent) => {
    // Handle touch
  };

  element.addEventListener('touchstart', handler, { passive: true });

  return () => {
    element.removeEventListener('touchstart', handler);
  };
}, []);
```

### Service Worker Fetch Events

Note: The `fetch` event in Service Workers cannot be made passive as it requires `event.respondWith()` to handle requests. This is expected behavior.

---

## 18. iOS BACKGROUND SYNC FALLBACK (CRITICAL)

### The Problem

iOS does NOT support the Background Sync API. Operations queued for background sync will NEVER execute on iOS. This affects:
- Offline form submissions
- Data synchronization
- Pending uploads
- Any operation using `registration.sync.register()`

### Solution: Visibility-Based Sync

Instead of Background Sync, use document visibility changes to sync when the app returns to foreground.

```typescript
// Platform-aware sync manager
class CrossPlatformSync {
  private pendingOperations: PendingOperation[] = [];
  private isIOS: boolean;

  constructor() {
    this.isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

    this.loadPendingOperations();
    this.setupSyncTriggers();
  }

  private loadPendingOperations() {
    const stored = localStorage.getItem('pending-sync-operations');
    if (stored) {
      this.pendingOperations = JSON.parse(stored);
    }
  }

  private savePendingOperations() {
    localStorage.setItem(
      'pending-sync-operations',
      JSON.stringify(this.pendingOperations)
    );
  }

  private setupSyncTriggers() {
    // iOS: Use visibility change
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        this.processPendingOperations();
      }
    });

    // Also sync on online event
    window.addEventListener('online', () => {
      this.processPendingOperations();
    });

    // Initial sync on load
    if (navigator.onLine) {
      this.processPendingOperations();
    }
  }

  async queueOperation(operation: PendingOperation) {
    // Add to pending queue
    this.pendingOperations.push({
      ...operation,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      retryCount: 0,
    });

    this.savePendingOperations();

    // Try to sync immediately if online
    if (navigator.onLine) {
      // On iOS or if Background Sync not supported: sync now
      if (this.isIOS || !('sync' in ServiceWorkerRegistration.prototype)) {
        await this.processPendingOperations();
      } else {
        // Android: Use Background Sync
        const registration = await navigator.serviceWorker.ready;
        await registration.sync.register('sync-operations');
      }
    }
  }

  async processPendingOperations() {
    if (!navigator.onLine || this.pendingOperations.length === 0) {
      return;
    }

    const operations = [...this.pendingOperations];

    for (const op of operations) {
      try {
        await this.executeOperation(op);

        // Remove successful operation
        this.pendingOperations = this.pendingOperations.filter(
          p => p.id !== op.id
        );
      } catch (error) {
        // Increment retry count
        const index = this.pendingOperations.findIndex(p => p.id === op.id);
        if (index !== -1) {
          this.pendingOperations[index].retryCount++;

          // Remove after too many retries
          if (this.pendingOperations[index].retryCount > 5) {
            this.pendingOperations.splice(index, 1);
            console.error('Operation failed after 5 retries:', op);
          }
        }
      }
    }

    this.savePendingOperations();
  }

  private async executeOperation(op: PendingOperation): Promise<void> {
    const response = await fetch(op.url, {
      method: op.method,
      headers: op.headers,
      body: op.body,
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
  }
}

interface PendingOperation {
  id?: string;
  url: string;
  method: string;
  headers: Record<string, string>;
  body?: string;
  timestamp?: number;
  retryCount?: number;
}

// Global instance
export const syncManager = new CrossPlatformSync();

// Usage
async function submitForm(data: FormData) {
  try {
    // Try immediate submission
    const response = await fetch('/api/submit', {
      method: 'POST',
      body: data,
    });

    if (response.ok) return;
    throw new Error('Failed');
  } catch {
    // Queue for later
    await syncManager.queueOperation({
      url: '/api/submit',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(Object.fromEntries(data)),
    });

    // Show user feedback
    showToast('הנתונים יישלחו כשתהיה חיבור');
  }
}
```

### React Hook for Cross-Platform Sync

```typescript
import { useEffect, useState } from 'react';

function useCrossPlatformSync() {
  const [pendingCount, setPendingCount] = useState(0);
  const [isSyncing, setIsSyncing] = useState(false);

  useEffect(() => {
    // Update pending count
    const updateCount = () => {
      const stored = localStorage.getItem('pending-sync-operations');
      const operations = stored ? JSON.parse(stored) : [];
      setPendingCount(operations.length);
    };

    updateCount();

    // Listen for storage changes
    window.addEventListener('storage', updateCount);

    // Listen for visibility changes
    document.addEventListener('visibilitychange', updateCount);

    return () => {
      window.removeEventListener('storage', updateCount);
      document.removeEventListener('visibilitychange', updateCount);
    };
  }, []);

  const sync = async () => {
    setIsSyncing(true);
    await syncManager.processPendingOperations();
    setIsSyncing(false);
  };

  return { pendingCount, isSyncing, sync };
}
```

### Service Worker Handler (Android)

```typescript
// In service worker - Android only
self.addEventListener('sync', (event: SyncEvent) => {
  if (event.tag === 'sync-operations') {
    event.waitUntil(processPendingOperations());
  }
});

async function processPendingOperations() {
  // Get pending operations from IndexedDB (not localStorage in SW)
  const db = await openDB('sync-db', 1);
  const operations = await db.getAll('pending');

  for (const op of operations) {
    try {
      const response = await fetch(op.url, {
        method: op.method,
        headers: op.headers,
        body: op.body,
      });

      if (response.ok) {
        await db.delete('pending', op.id);
      }
    } catch {
      // Will retry on next sync
    }
  }
}
```

### Detection Helper

```typescript
function supportsBackgroundSync(): boolean {
  // iOS never supports Background Sync
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  if (isIOS) return false;

  return 'serviceWorker' in navigator &&
    'sync' in ServiceWorkerRegistration.prototype;
}
```

---


## 18.1 MEMORY LEAK PREVENTION IN SERVICE WORKERS

### Common Memory Leak Sources

Service Workers persist across page navigations, making memory leaks critical:

1. **Event listener accumulation** - Adding listeners without removal
2. **Cache size growth** - Unbounded cache storage
3. **Promise chains** - Unresolved promises holding references
4. **Message channel leaks** - Unclosed MessagePorts
5. **IndexedDB connections** - Open database connections

### Prevention Patterns

```typescript
// 1. Properly scoped event listeners
const handlers = new Map<string, EventListener>();

function addHandler(event: string, handler: EventListener) {
  // Remove existing handler if any
  if (handlers.has(event)) {
    self.removeEventListener(event, handlers.get(event)!);
  }
  handlers.set(event, handler);
  self.addEventListener(event, handler);
}

// 2. Bounded cache with automatic cleanup
const MAX_CACHE_ITEMS = 200;
const MAX_CACHE_AGE = 7 * 24 * 60 * 60 * 1000; // 7 days

async function pruneCache(cacheName: string): Promise<void> {
  const cache = await caches.open(cacheName);
  const keys = await cache.keys();
  
  // Remove oldest entries if over limit
  if (keys.length > MAX_CACHE_ITEMS) {
    const toDelete = keys.slice(0, keys.length - MAX_CACHE_ITEMS);
    await Promise.all(toDelete.map(key => cache.delete(key)));
  }
}

// Run cache pruning periodically
setInterval(() => {
  caches.keys().then(names => {
    names.forEach(name => pruneCache(name));
  });
}, 60 * 60 * 1000); // Every hour

// 3. Promise timeout wrapper
function withTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number,
  timeoutError = 'Operation timed out'
): Promise<T> {
  let timeoutId: ReturnType<typeof setTimeout>;
  
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeoutId = setTimeout(() => reject(new Error(timeoutError)), timeoutMs);
  });
  
  return Promise.race([promise, timeoutPromise]).finally(() => {
    clearTimeout(timeoutId);
  });
}

// 4. IndexedDB connection management
class IDBConnectionPool {
  private connections = new Map<string, IDBDatabase>();
  private connectionTimeout = 30000; // 30 seconds
  
  async getConnection(dbName: string): Promise<IDBDatabase> {
    if (this.connections.has(dbName)) {
      return this.connections.get(dbName)!;
    }
    
    const db = await this.openDB(dbName);
    this.connections.set(dbName, db);
    
    // Auto-close after timeout
    setTimeout(() => this.closeConnection(dbName), this.connectionTimeout);
    
    return db;
  }
  
  closeConnection(dbName: string): void {
    const db = this.connections.get(dbName);
    if (db) {
      db.close();
      this.connections.delete(dbName);
    }
  }
  
  closeAll(): void {
    this.connections.forEach((db, name) => {
      db.close();
    });
    this.connections.clear();
  }
  
  private openDB(name: string): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(name);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }
}

const dbPool = new IDBConnectionPool();

// 5. MessagePort cleanup
const activePorts = new Set<MessagePort>();

self.addEventListener('message', (event) => {
  if (event.ports.length > 0) {
    const port = event.ports[0];
    activePorts.add(port);
    
    port.onmessage = handlePortMessage;
    port.onmessageerror = () => {
      activePorts.delete(port);
      port.close();
    };
  }
});

// Cleanup on SW termination
self.addEventListener('deactivate', () => {
  activePorts.forEach(port => port.close());
  activePorts.clear();
  dbPool.closeAll();
});
```

### Memory Monitoring

```typescript
// Monitor memory usage (where available)
async function checkMemoryUsage(): Promise<void> {
  if ('memory' in performance) {
    const memory = (performance as any).memory;
    const usedMB = Math.round(memory.usedJSHeapSize / 1024 / 1024);
    const totalMB = Math.round(memory.totalJSHeapSize / 1024 / 1024);
    
    console.log(`[SW] Memory: ${usedMB}MB / ${totalMB}MB`);
    
    // Warn if memory is high
    if (usedMB > 50) {
      console.warn('[SW] High memory usage detected');
      // Trigger cleanup
      await cleanupMemory();
    }
  }
}

async function cleanupMemory(): Promise<void> {
  // Clear non-essential caches
  const cacheNames = await caches.keys();
  const nonEssential = cacheNames.filter(name => 
    !name.includes('precache') && !name.includes('critical')
  );
  
  await Promise.all(nonEssential.map(name => caches.delete(name)));
  
  // Close idle DB connections
  dbPool.closeAll();
}

// Run memory check periodically
setInterval(checkMemoryUsage, 5 * 60 * 1000); // Every 5 minutes
```

---

## 18.2 SERVICE WORKER REGISTRATION EDGE CASES

### Registration Failure Scenarios

```typescript
interface RegistrationResult {
  success: boolean;
  registration?: ServiceWorkerRegistration;
  error?: string;
  shouldRetry: boolean;
}

async function registerServiceWorkerSafely(): Promise<RegistrationResult> {
  // Check for basic support
  if (!('serviceWorker' in navigator)) {
    return {
      success: false,
      error: 'Service Worker not supported',
      shouldRetry: false,
    };
  }
  
  // Check for secure context (HTTPS or localhost)
  if (!window.isSecureContext) {
    return {
      success: false,
      error: 'Requires HTTPS',
      shouldRetry: false,
    };
  }
  
  // Check if private browsing (incognito)
  try {
    const test = indexedDB.open('sw-test');
    test.onerror = () => {
      // IndexedDB blocked - likely private browsing
      console.warn('[SW] IndexedDB blocked - private browsing mode?');
    };
  } catch {
    return {
      success: false,
      error: 'Private browsing detected',
      shouldRetry: false,
    };
  }
  
  // Check storage availability
  if ('storage' in navigator && 'estimate' in navigator.storage) {
    const { quota, usage } = await navigator.storage.estimate();
    if (quota && usage && (quota - usage) < 10 * 1024 * 1024) {
      console.warn('[SW] Low storage space');
    }
  }
  
  // Attempt registration with timeout
  try {
    const registration = await Promise.race([
      navigator.serviceWorker.register('/sw.js', {
        scope: '/',
        updateViaCache: 'none', // Always check for updates
      }),
      new Promise<never>((_, reject) => 
        setTimeout(() => reject(new Error('Registration timeout')), 10000)
      ),
    ]);
    
    return { success: true, registration, shouldRetry: false };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    
    // Determine if retry is appropriate
    const shouldRetry = 
      message.includes('timeout') ||
      message.includes('network') ||
      message.includes('fetch');
    
    return {
      success: false,
      error: message,
      shouldRetry,
    };
  }
}

// Registration with retry logic
async function registerWithRetry(
  maxRetries = 3,
  delayMs = 2000
): Promise<ServiceWorkerRegistration | null> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const result = await registerServiceWorkerSafely();
    
    if (result.success) {
      console.log('[SW] Registered successfully');
      return result.registration!;
    }
    
    console.warn(`[SW] Registration attempt ${attempt + 1} failed:`, result.error);
    
    if (!result.shouldRetry) {
      console.error('[SW] Registration failed permanently');
      return null;
    }
    
    // Wait before retry with exponential backoff
    await new Promise(resolve => 
      setTimeout(resolve, delayMs * Math.pow(2, attempt))
    );
  }
  
  return null;
}
```

### Handling Existing Registrations

```typescript
async function handleExistingRegistrations(): Promise<void> {
  const registrations = await navigator.serviceWorker.getRegistrations();
  
  for (const registration of registrations) {
    // Check for stale/orphaned SWs
    if (registration.scope !== window.location.origin + '/') {
      console.log('[SW] Unregistering stale SW:', registration.scope);
      await registration.unregister();
    }
  }
}

// Handle controller changes
navigator.serviceWorker.addEventListener('controllerchange', () => {
  // New SW took control - may need to reload
  console.log('[SW] Controller changed');
  
  // Option 1: Silent reload
  // window.location.reload();
  
  // Option 2: Notify user
  // showUpdateBanner();
});
```

---

## 18.3 FETCH HANDLER EDGE CASES

### Handling Problematic Requests

```typescript
// Requests that should NOT be handled by SW
const BYPASS_PATTERNS = [
  /^chrome-extension:\/\//,
  /^moz-extension:\/\//,
  /^safari-extension:\/\//,
  /^devtools:\/\//,
  /\/__webpack_hmr/,
  /\/hot-update\./,
  /\/sockjs-node\//,
  /\.map$/,
];

const BYPASS_METHODS = ['PUT', 'DELETE', 'PATCH'];

self.addEventListener('fetch', (event: FetchEvent) => {
  const request = event.request;
  const url = new URL(request.url);
  
  // 1. Skip non-HTTP(S) requests
  if (!url.protocol.startsWith('http')) {
    return;
  }
  
  // 2. Skip requests matching bypass patterns
  if (BYPASS_PATTERNS.some(pattern => pattern.test(request.url))) {
    return;
  }
  
  // 3. Skip mutation methods (unless specifically handling)
  if (BYPASS_METHODS.includes(request.method)) {
    return;
  }
  
  // 4. Skip range requests (video/audio seeking)
  if (request.headers.get('range')) {
    return; // Let browser handle natively
  }
  
  // 5. Skip requests with credentials to different origins
  if (request.credentials === 'include' && url.origin !== location.origin) {
    return;
  }
  
  // Handle the request
  event.respondWith(handleFetch(request));
});

async function handleFetch(request: Request): Promise<Response> {
  try {
    // Attempt network first for navigation
    if (request.mode === 'navigate') {
      return await handleNavigationRequest(request);
    }
    
    // Apply caching strategy
    return await applyCacheStrategy(request);
    
  } catch (error) {
    console.error('[SW] Fetch error:', error);
    
    // Return offline page for navigation
    if (request.mode === 'navigate') {
      const offlinePage = await caches.match('/offline.html');
      if (offlinePage) return offlinePage;
    }
    
    // Return error response
    return new Response('Network error', {
      status: 503,
      statusText: 'Service Unavailable',
    });
  }
}

// Handle navigation with proper fallbacks
async function handleNavigationRequest(request: Request): Promise<Response> {
  try {
    // Try network with timeout
    const networkResponse = await withTimeout(
      fetch(request),
      5000,
      'Navigation timeout'
    );
    
    // Cache successful responses
    if (networkResponse.ok) {
      const cache = await caches.open('pages-v1');
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
    
  } catch {
    // Try cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) return cachedResponse;
    
    // Return offline page
    const offlinePage = await caches.match('/offline.html');
    return offlinePage || new Response('Offline', { status: 503 });
  }
}
```

### Handling Opaque Responses

```typescript
// Opaque responses (no-cors) have limitations
async function handleOpaqueResponse(response: Response): Promise<Response> {
  // Can't read status, headers, or body of opaque responses
  // But we can still cache them
  
  if (response.type === 'opaque') {
    // Clone before caching (can only read once)
    const cache = await caches.open('opaque-v1');
    
    // Be careful - opaque responses count as large towards quota
    // Only cache if necessary
    const url = response.url;
    if (shouldCacheOpaque(url)) {
      await cache.put(url, response.clone());
    }
  }
  
  return response;
}

function shouldCacheOpaque(url: string): boolean {
  // Only cache known CDN resources
  const trustedOrigins = [
    'fonts.googleapis.com',
    'fonts.gstatic.com',
    'cdn.example.com',
  ];
  
  return trustedOrigins.some(origin => url.includes(origin));
}
```

---

## 18.4 CACHE STORAGE LIMITS TABLE

### Browser Cache Limits

| Browser/Platform | Total Quota | Per-Origin Limit | Eviction Policy | Notes |
|-----------------|-------------|------------------|-----------------|-------|
| Chrome Desktop | 80% of disk | Up to 60% of total quota | LRU, persistent available | Request persist via `navigator.storage.persist()` |
| Chrome Android | ~100MB guaranteed | ~6% of disk space | LRU, aggressive on low storage | Varies by device storage |
| Firefox Desktop | 50% of disk | 2GB per origin | LRU by origin | Prompts user at 50% |
| Firefox Android | ~50% of available | ~500MB per origin | Aggressive LRU | More limited than desktop |
| Safari Desktop | ~1GB initial | Increases with use | 7-day expiry for cache | ITP affects third-party |
| Safari iOS | ~50MB initial | Up to 500MB | 7-day expiry, aggressive | Purged in low storage |
| Samsung Internet | Similar to Chrome | ~100MB guaranteed | LRU | Uses Chrome engine |
| Android WebView | Device dependent | ~50-100MB | Very aggressive | Limited in low-end devices |

### Low-Memory Device Strategy

```typescript
interface CacheBudget {
  maxSize: number;      // Maximum total cache size in bytes
  maxEntries: number;   // Maximum entries per cache
  maxAge: number;       // Maximum age in seconds
}

function getCacheBudget(): CacheBudget {
  const deviceMemory = (navigator as any).deviceMemory ?? 4;
  
  if (deviceMemory <= 1) {
    // Ultra low-end: 1GB RAM
    return {
      maxSize: 10 * 1024 * 1024,    // 10MB
      maxEntries: 30,
      maxAge: 24 * 60 * 60,          // 1 day
    };
  }
  
  if (deviceMemory <= 2) {
    // Low-end: 2GB RAM
    return {
      maxSize: 25 * 1024 * 1024,    // 25MB
      maxEntries: 50,
      maxAge: 3 * 24 * 60 * 60,      // 3 days
    };
  }
  
  if (deviceMemory <= 4) {
    // Mid-range: 4GB RAM
    return {
      maxSize: 50 * 1024 * 1024,    // 50MB
      maxEntries: 100,
      maxAge: 7 * 24 * 60 * 60,      // 7 days
    };
  }
  
  // High-end: 8GB+ RAM
  return {
    maxSize: 100 * 1024 * 1024,   // 100MB
    maxEntries: 200,
    maxAge: 30 * 24 * 60 * 60,     // 30 days
  };
}
```

---

## 18.5 BACKGROUND OPERATION LIMITS TABLE

### Background API Support & Limits

| Feature | Chrome Android | Safari iOS | Firefox Android | Samsung | Limits |
|---------|---------------|------------|-----------------|---------|--------|
| Background Sync | Yes (40+) | No | No | Yes | 3 retries default |
| Periodic Sync | Yes (80+)* | No | No | No | Min 12h interval, engagement required |
| Background Fetch | Yes (74+) | No | No | Yes | 10MB+ downloads |
| Push Messages | Yes (50+) | Yes (16.4+) | Yes (44+) | Yes | Must show notification |
| Silent Push | No | No | No | No | Not allowed |
| Notification Actions | Yes (48+) | No | Yes | Yes | Max 2 actions |

*Periodic Sync requires "high" site engagement score

### Background Sync Retry Behavior

```typescript
interface SyncRetryConfig {
  maxRetries: number;
  minDelay: number;
  maxDelay: number;
  backoffFactor: number;
}

// Browser defaults (approximate)
const SYNC_DEFAULTS: Record<string, SyncRetryConfig> = {
  chrome: {
    maxRetries: 3,
    minDelay: 5 * 60 * 1000,      // 5 minutes
    maxDelay: 60 * 60 * 1000,     // 1 hour
    backoffFactor: 2,
  },
  // Samsung Internet follows Chrome
  samsung: {
    maxRetries: 3,
    minDelay: 5 * 60 * 1000,
    maxDelay: 60 * 60 * 1000,
    backoffFactor: 2,
  },
};

// Custom retry logic for unsupported browsers
async function backgroundSyncWithFallback(
  tag: string,
  operation: () => Promise<void>
): Promise<void> {
  const hasBackgroundSync = 'sync' in ServiceWorkerRegistration.prototype;
  
  if (hasBackgroundSync) {
    const registration = await navigator.serviceWorker.ready;
    await registration.sync.register(tag);
    return;
  }
  
  // Fallback: immediate retry with exponential backoff
  let attempt = 0;
  const maxAttempts = 5;
  
  while (attempt < maxAttempts) {
    try {
      await operation();
      return; // Success
    } catch (error) {
      attempt++;
      if (attempt < maxAttempts) {
        const delay = Math.min(
          1000 * Math.pow(2, attempt),
          5 * 60 * 1000  // Max 5 minutes
        );
        await new Promise(r => setTimeout(r, delay));
      }
    }
  }
  
  // Queue for later if all retries failed
  await queueForVisibilitySync(tag, operation);
}
```

### Periodic Sync Limitations

```typescript
// Periodic Background Sync has strict requirements
async function checkPeriodicSyncEligibility(): Promise<{
  eligible: boolean;
  reason: string;
}> {
  // 1. Check API support
  if (!('periodicSync' in ServiceWorkerRegistration.prototype)) {
    return { eligible: false, reason: 'API not supported' };
  }
  
  // 2. Check permission
  const permission = await navigator.permissions.query({
    name: 'periodic-background-sync' as PermissionName,
  });
  
  if (permission.state === 'denied') {
    return { eligible: false, reason: 'Permission denied' };
  }
  
  if (permission.state === 'prompt') {
    return { 
      eligible: false, 
      reason: 'Requires higher site engagement' 
    };
  }
  
  // 3. Granted - but still have minimum interval
  return { 
    eligible: true, 
    reason: 'Minimum interval: 12 hours' 
  };
}

// Register with fallback to interval
async function registerPeriodicRefresh(): Promise<void> {
  const eligibility = await checkPeriodicSyncEligibility();
  
  if (eligibility.eligible) {
    const registration = await navigator.serviceWorker.ready;
    await registration.periodicSync.register('refresh-data', {
      minInterval: 12 * 60 * 60 * 1000, // 12 hours minimum
    });
    console.log('[Sync] Periodic sync registered');
  } else {
    console.log('[Sync] Fallback to visibility refresh:', eligibility.reason);
    
    // Fallback: refresh on visibility
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        dispatchEvent(new CustomEvent('refresh-data'));
      }
    });
  }
}
```

---

## 20. CHECKLIST

- [ ] Configure vite-plugin-pwa with appropriate strategy
- [ ] Set up precaching for critical assets
- [ ] Implement cache strategies per resource type
- [ ] Choose update mechanism (force vs soft)
- [ ] Implement background sync for offline operations
- [ ] Set up push notification handling (if needed)
- [ ] Add share target support (if needed)
- [ ] Implement client communication patterns
- [ ] Add debugging utilities for development
- [ ] Test offline scenarios thoroughly
- [ ] Monitor cache sizes in production
- [ ] **Test on old Android devices (5.x, 6.x)**
- [ ] **Implement Background Sync fallbacks**
- [ ] **Handle Cache API quota errors**
- [ ] **Add platform-specific push notification options**
- [ ] **Request persistent storage for critical data**

---

## 21. VERIFICATION SEAL

```
OMEGA_v24.5.0 | SERVICE_WORKER_PATTERNS
Gates: 6 | Commands: 5 | Phase: 2.4
SERWIST | WORKBOX | OFFLINE_FIRST
PASSIVE_LISTENERS: MANDATORY
IOS_SYNC_FALLBACK: VISIBILITY_BASED
```

---

*Last updated: 2026-01-30 | Based on Workbox 7.x and vite-plugin-pwa 0.20+*

<!-- PWA-EXPERT/SERVICE-WORKER v24.5.0 | Updated: 2026-02-19 -->

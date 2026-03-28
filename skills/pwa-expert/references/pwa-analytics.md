# PWA-ANALYTICS v24.5.0 SINGULARITY FORGE

> Master of PWA Installation Tracking, Feature Usage Metrics, Performance Monitoring, A/B Testing, and Error Tracking

---

## 1. PURPOSE

Complete reference for tracking PWA installations, feature usage, performance, A/B testing, and error monitoring. Includes full implementation code for production use with special focus on old Android device compatibility tracking.

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/pwa analytics setup` | Initialize complete PWA analytics | ~5min |
| `/pwa analytics install` | Setup installation tracking | ~2min |
| `/pwa analytics offline` | Setup offline usage tracking | ~3min |
| `/pwa analytics performance` | Setup Core Web Vitals tracking | ~2min |
| `/pwa analytics ab-test` | Configure A/B testing for install prompts | ~5min |
| `/pwa analytics dashboard` | Generate dashboard data queries | ~3min |
| `/pwa analytics sentry` | Setup Sentry PWA integration | ~2min |
| `/pwa analytics old-android` | Setup old Android device tracking | ~5min |

---

## 3. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-ANA-1 | INSTALL_TRACKING | Install events captured | All events logged |
| G-ANA-2 | OFFLINE_TRACKING | Offline/online transitions | Events synced on reconnect |
| G-ANA-3 | PERFORMANCE | Web Vitals tracked | PWA context included |
| G-ANA-4 | AB_TESTING | Variants assigned | Statistical tracking |
| G-ANA-5 | ERROR_TRACKING | Sentry configured | PWA tags present |
| G-ANA-6 | OLD_ANDROID | Device detection | Category classification |
| G-ANA-7 | DASHBOARD | Data aggregation | Queries functional |

---

## 4. INSTALLATION TRACKING

### 4.1 Detect PWA vs Browser

```typescript
// lib/pwa/analytics.ts
export type InstallSource =
  | "pwa-installed"
  | "twa"
  | "browser"
  | "ios-standalone";

export function getInstallSource(): InstallSource {
  // Check iOS standalone mode
  if (
    (navigator as any).standalone ||
    window.matchMedia("(display-mode: standalone)").matches
  ) {
    // Distinguish between iOS and Android/Desktop PWA
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    return isIOS ? "ios-standalone" : "pwa-installed";
  }

  // Check if launched from TWA (Trusted Web Activity)
  if (
    document.referrer.includes("android-app://") ||
    (window as any).matchMedia?.("(display-mode: fullscreen)").matches
  ) {
    return "twa";
  }

  // Check minimal-ui mode (some Android browsers)
  if (window.matchMedia("(display-mode: minimal-ui)").matches) {
    return "pwa-installed";
  }

  return "browser";
}

// Enhanced detection with caching
let cachedInstallSource: InstallSource | null = null;

export function getInstallSourceCached(): InstallSource {
  if (cachedInstallSource) return cachedInstallSource;

  cachedInstallSource = getInstallSource();

  // Listen for display mode changes
  const mediaQuery = window.matchMedia("(display-mode: standalone)");
  mediaQuery.addEventListener("change", () => {
    cachedInstallSource = getInstallSource();
  });

  return cachedInstallSource;
}
```

### 4.2 Track Install Events

```typescript
// lib/pwa/install-tracking.ts
import { analytics } from "@/lib/analytics";

interface InstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed"; platform: string }>;
}

// Store the deferred prompt
let deferredPrompt: InstallPromptEvent | null = null;

export function initInstallTracking() {
  // Track when install prompt is available
  window.addEventListener("beforeinstallprompt", (e: Event) => {
    const event = e as InstallPromptEvent;
    e.preventDefault();
    deferredPrompt = event;

    analytics.track("pwa_install_prompt_available", {
      timestamp: Date.now(),
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
    });
  });

  // Track successful installation
  window.addEventListener("appinstalled", () => {
    deferredPrompt = null;

    analytics.track("pwa_installed", {
      timestamp: Date.now(),
      source: document.referrer || "direct",
      installTime: performance.now(),
    });

    // Store installation date for retention analysis
    localStorage.setItem("pwa_install_date", new Date().toISOString());
  });
}

// Trigger install prompt with tracking
export async function triggerInstallPrompt(promptVariant: string) {
  if (!deferredPrompt) {
    analytics.track("pwa_install_prompt_unavailable", {
      reason: "no_deferred_prompt",
    });
    return { success: false, reason: "no_deferred_prompt" };
  }

  analytics.track("pwa_install_prompt_shown", {
    variant: promptVariant,
    timestamp: Date.now(),
  });

  try {
    await deferredPrompt.prompt();
    const { outcome, platform } = await deferredPrompt.userChoice;

    analytics.track("pwa_install_prompt_response", {
      variant: promptVariant,
      outcome,
      platform,
      timestamp: Date.now(),
    });

    deferredPrompt = null;
    return { success: true, outcome, platform };
  } catch (error) {
    analytics.track("pwa_install_prompt_error", {
      error: String(error),
    });
    return { success: false, reason: "prompt_error" };
  }
}

// Check if install prompt is available
export function isInstallPromptAvailable(): boolean {
  return deferredPrompt !== null;
}
```

### 4.3 Track Launch Source

```typescript
// lib/pwa/launch-tracking.ts
import { analytics } from "@/lib/analytics";
import { getInstallSourceCached } from "./analytics";

export function trackPWALaunch() {
  const installSource = getInstallSourceCached();
  const urlParams = new URLSearchParams(window.location.search);

  const launchData = {
    source: installSource,
    utmSource: urlParams.get("utm_source"),
    utmMedium: urlParams.get("utm_medium"),
    utmCampaign: urlParams.get("utm_campaign"),
    referrer: document.referrer || "direct",
    timestamp: Date.now(),
    isFirstLaunch: !localStorage.getItem("pwa_first_launch"),
    daysSinceInstall: getDaysSinceInstall(),
    displayMode: getDisplayMode(),
  };

  analytics.track("pwa_launch", launchData);

  // Mark first launch
  if (!localStorage.getItem("pwa_first_launch")) {
    localStorage.setItem("pwa_first_launch", new Date().toISOString());
    analytics.track("pwa_first_launch", launchData);
  }

  // Track session start
  trackSessionStart();
}

function getDaysSinceInstall(): number | null {
  const installDate = localStorage.getItem("pwa_install_date");
  if (!installDate) return null;

  const diff = Date.now() - new Date(installDate).getTime();
  return Math.floor(diff / (1000 * 60 * 60 * 24));
}

function getDisplayMode(): string {
  if (window.matchMedia("(display-mode: standalone)").matches)
    return "standalone";
  if (window.matchMedia("(display-mode: fullscreen)").matches)
    return "fullscreen";
  if (window.matchMedia("(display-mode: minimal-ui)").matches)
    return "minimal-ui";
  return "browser";
}

// Session tracking
let sessionStartTime: number;

function trackSessionStart() {
  sessionStartTime = Date.now();

  // Track session end on visibility change or unload
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "hidden") {
      trackSessionEnd();
    }
  });

  window.addEventListener("beforeunload", trackSessionEnd);
}

function trackSessionEnd() {
  const sessionDuration = Date.now() - sessionStartTime;

  // Use sendBeacon for reliability
  const data = JSON.stringify({
    event: "pwa_session_end",
    duration: sessionDuration,
    source: getInstallSourceCached(),
    pagesViewed: performance.getEntriesByType("navigation").length,
  });

  if (navigator.sendBeacon) {
    navigator.sendBeacon("/api/analytics", data);
  }
}
```

---

## 5. FEATURE USAGE METRICS

### 5.1 Offline Mode Tracking

```typescript
// lib/pwa/offline-tracking.ts
import { analytics } from "@/lib/analytics";

interface OfflineSession {
  startTime: number;
  endTime?: number;
  actions: OfflineAction[];
}

interface OfflineAction {
  type: string;
  timestamp: number;
  data?: Record<string, unknown>;
}

let currentOfflineSession: OfflineSession | null = null;
const pendingOfflineEvents: OfflineAction[] = [];

export function initOfflineTracking() {
  // Track online/offline transitions
  window.addEventListener("online", handleOnline);
  window.addEventListener("offline", handleOffline);

  // Initialize based on current state
  if (!navigator.onLine) {
    handleOffline();
  }

  // Sync pending events when online
  if (navigator.onLine && pendingOfflineEvents.length > 0) {
    syncOfflineEvents();
  }
}

function handleOffline() {
  currentOfflineSession = {
    startTime: Date.now(),
    actions: [],
  };

  // Store in IndexedDB for persistence
  storeOfflineSession(currentOfflineSession);

  analytics.track("pwa_went_offline", {
    timestamp: Date.now(),
    pendingActions: getSyncQueueSize(),
  });
}

function handleOnline() {
  if (currentOfflineSession) {
    currentOfflineSession.endTime = Date.now();
    const duration = currentOfflineSession.endTime - currentOfflineSession.startTime;

    analytics.track("pwa_went_online", {
      offlineDuration: duration,
      actionsPerformed: currentOfflineSession.actions.length,
      timestamp: Date.now(),
    });

    // Sync offline events
    syncOfflineEvents();
    currentOfflineSession = null;
  }
}

// Track actions performed while offline
export function trackOfflineAction(type: string, data?: Record<string, unknown>) {
  const action: OfflineAction = {
    type,
    timestamp: Date.now(),
    data,
  };

  if (currentOfflineSession) {
    currentOfflineSession.actions.push(action);
    storeOfflineSession(currentOfflineSession);
  }

  pendingOfflineEvents.push(action);
  storePendingEvents(pendingOfflineEvents);
}

// Sync offline events to analytics
async function syncOfflineEvents() {
  if (pendingOfflineEvents.length === 0) return;

  try {
    const events = [...pendingOfflineEvents];
    pendingOfflineEvents.length = 0;

    for (const event of events) {
      analytics.track("pwa_offline_action", {
        actionType: event.type,
        actionTimestamp: event.timestamp,
        syncedAt: Date.now(),
        ...event.data,
      });
    }

    clearStoredPendingEvents();

    analytics.track("pwa_offline_sync_complete", {
      eventCount: events.length,
    });
  } catch (error) {
    analytics.track("pwa_offline_sync_error", {
      error: String(error),
      pendingCount: pendingOfflineEvents.length,
    });
  }
}

// Get sync queue size from service worker
async function getSyncQueueSize(): Promise<number> {
  if (!("serviceWorker" in navigator)) return 0;

  try {
    const registration = await navigator.serviceWorker.ready;
    // This requires a custom message handler in your service worker
    return new Promise((resolve) => {
      const channel = new MessageChannel();
      channel.port1.onmessage = (event) => resolve(event.data.queueSize || 0);
      registration.active?.postMessage(
        { type: "GET_SYNC_QUEUE_SIZE" },
        [channel.port2]
      );
      setTimeout(() => resolve(0), 1000);
    });
  } catch {
    return 0;
  }
}

// IndexedDB helpers
function storeOfflineSession(session: OfflineSession) {
  localStorage.setItem("pwa_offline_session", JSON.stringify(session));
}

function storePendingEvents(events: OfflineAction[]) {
  localStorage.setItem("pwa_pending_events", JSON.stringify(events));
}

function clearStoredPendingEvents() {
  localStorage.removeItem("pwa_pending_events");
}
```

### 5.2 Push Notifications Tracking

```typescript
// lib/pwa/push-tracking.ts
import { analytics } from "@/lib/analytics";

export async function trackPushPermissionRequest() {
  const startTime = Date.now();

  analytics.track("push_permission_requested", {
    timestamp: startTime,
    currentPermission: Notification.permission,
  });

  try {
    const result = await Notification.requestPermission();
    const responseTime = Date.now() - startTime;

    analytics.track("push_permission_response", {
      result,
      responseTime,
      timestamp: Date.now(),
    });

    return result;
  } catch (error) {
    analytics.track("push_permission_error", {
      error: String(error),
    });
    throw error;
  }
}

export function trackPushSubscription(
  action: "subscribe" | "unsubscribe",
  success: boolean,
  error?: string
) {
  analytics.track(`push_${action}`, {
    success,
    error,
    timestamp: Date.now(),
    permission: Notification.permission,
  });
}

// Track notification interactions (called from service worker)
export function trackNotificationInteraction(
  action: "click" | "close" | "action",
  notificationData: {
    tag?: string;
    title?: string;
    actionId?: string;
    deliveredAt?: number;
  }
) {
  const now = Date.now();

  analytics.track("push_notification_interaction", {
    action,
    tag: notificationData.tag,
    title: notificationData.title,
    actionId: notificationData.actionId,
    timeToInteraction: notificationData.deliveredAt
      ? now - notificationData.deliveredAt
      : undefined,
    timestamp: now,
  });
}

// Service worker integration for push tracking
export function initPushTrackingInSW() {
  // Add this to your service worker
  return `
    self.addEventListener('push', (event) => {
      const data = event.data?.json() || {};

      // Store delivery time for interaction tracking
      const deliveryData = {
        deliveredAt: Date.now(),
        ...data
      };

      // Track delivery
      fetch('/api/analytics', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event: 'push_notification_delivered',
          data: deliveryData
        })
      }).catch(() => {});
    });

    self.addEventListener('notificationclick', (event) => {
      const notification = event.notification;
      const action = event.action;

      fetch('/api/analytics', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event: 'push_notification_click',
          data: {
            tag: notification.tag,
            action: action || 'main',
            timestamp: Date.now()
          }
        })
      }).catch(() => {});
    });

    self.addEventListener('notificationclose', (event) => {
      fetch('/api/analytics', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event: 'push_notification_dismissed',
          data: {
            tag: event.notification.tag,
            timestamp: Date.now()
          }
        })
      }).catch(() => {});
    });
  `;
}

// Push notification metrics dashboard helper
export async function getPushMetrics(): Promise<{
  permissionRate: number;
  clickThroughRate: number;
  optOutRate: number;
}> {
  // This would typically come from your analytics backend
  // Placeholder implementation
  return {
    permissionRate: 0,
    clickThroughRate: 0,
    optOutRate: 0,
  };
}
```

### 5.3 Background Sync Tracking

```typescript
// lib/pwa/sync-tracking.ts
import { analytics } from "@/lib/analytics";

interface SyncEvent {
  id: string;
  tag: string;
  queuedAt: number;
  completedAt?: number;
  retryCount: number;
  success?: boolean;
  error?: string;
}

const syncEvents = new Map<string, SyncEvent>();

export function trackSyncQueued(tag: string, id: string) {
  const event: SyncEvent = {
    id,
    tag,
    queuedAt: Date.now(),
    retryCount: 0,
  };

  syncEvents.set(id, event);

  analytics.track("background_sync_queued", {
    tag,
    id,
    queueSize: syncEvents.size,
    timestamp: Date.now(),
  });
}

export function trackSyncRetry(id: string) {
  const event = syncEvents.get(id);
  if (event) {
    event.retryCount++;

    analytics.track("background_sync_retry", {
      id,
      tag: event.tag,
      retryCount: event.retryCount,
      timeSinceQueued: Date.now() - event.queuedAt,
    });
  }
}

export function trackSyncCompleted(id: string, success: boolean, error?: string) {
  const event = syncEvents.get(id);
  if (event) {
    event.completedAt = Date.now();
    event.success = success;
    event.error = error;

    analytics.track("background_sync_completed", {
      id,
      tag: event.tag,
      success,
      error,
      duration: event.completedAt - event.queuedAt,
      retryCount: event.retryCount,
    });

    syncEvents.delete(id);
  }
}

// Sync queue metrics
export function getSyncQueueMetrics() {
  const events = Array.from(syncEvents.values());

  return {
    queueSize: events.length,
    oldestItemAge: events.length > 0
      ? Date.now() - Math.min(...events.map(e => e.queuedAt))
      : 0,
    totalRetries: events.reduce((sum, e) => sum + e.retryCount, 0),
    byTag: events.reduce(
      (acc, e) => {
        acc[e.tag] = (acc[e.tag] || 0) + 1;
        return acc;
      },
      {} as Record<string, number>
    ),
  };
}
```

---

## 6. PERFORMANCE MONITORING

### 6.1 Core Web Vitals for PWA

```typescript
// lib/pwa/performance.ts
import { onCLS, onINP, onLCP, onFCP, onTTFB } from "web-vitals";
import { analytics } from "@/lib/analytics";
import { getInstallSourceCached } from "./analytics";

interface PWAPerformanceMetric {
  name: string;
  value: number;
  rating: "good" | "needs-improvement" | "poor";
  source: string;
  isStandalone: boolean;
  serviceWorkerActive: boolean;
}

export function initPWAPerformanceTracking() {
  const isStandalone =
    window.matchMedia("(display-mode: standalone)").matches;
  const source = getInstallSourceCached();

  const trackMetric = async (metric: {
    name: string;
    value: number;
    rating: "good" | "needs-improvement" | "poor";
  }) => {
    const swActive = await isServiceWorkerActive();

    const pwaMetric: PWAPerformanceMetric = {
      ...metric,
      source,
      isStandalone,
      serviceWorkerActive: swActive,
    };

    analytics.track("pwa_web_vital", pwaMetric);

    // Send to custom endpoint for PWA-specific dashboard
    sendToPerformanceEndpoint(pwaMetric);
  };

  onLCP((metric) => trackMetric(metric));
  onCLS((metric) => trackMetric(metric));
  onINP((metric) => trackMetric(metric));
  onFCP((metric) => trackMetric(metric));
  onTTFB((metric) => trackMetric(metric));

  // Track PWA-specific metrics
  trackPWASpecificMetrics();
}

async function isServiceWorkerActive(): Promise<boolean> {
  if (!("serviceWorker" in navigator)) return false;

  try {
    const registration = await navigator.serviceWorker.getRegistration();
    return !!registration?.active;
  } catch {
    return false;
  }
}

function sendToPerformanceEndpoint(metric: PWAPerformanceMetric) {
  const body = JSON.stringify({
    ...metric,
    url: window.location.pathname,
    timestamp: Date.now(),
    connection: (navigator as any).connection?.effectiveType || "unknown",
    deviceMemory: (navigator as any).deviceMemory || "unknown",
  });

  if (navigator.sendBeacon) {
    navigator.sendBeacon("/api/pwa-performance", body);
  } else {
    fetch("/api/pwa-performance", {
      method: "POST",
      body,
      keepalive: true,
    });
  }
}

// PWA-specific performance metrics
async function trackPWASpecificMetrics() {
  // App shell load time (time to interactive after SW takes over)
  const appShellLoadTime = await measureAppShellLoad();

  analytics.track("pwa_app_shell_load", {
    duration: appShellLoadTime,
    cached: appShellLoadTime < 100, // Likely cached if very fast
  });

  // Track time to first meaningful paint from cache
  trackCachePerformance();
}

async function measureAppShellLoad(): Promise<number> {
  return new Promise((resolve) => {
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();
      const lastEntry = entries[entries.length - 1];
      observer.disconnect();
      resolve(lastEntry.startTime);
    });

    observer.observe({ type: "largest-contentful-paint", buffered: true });

    // Fallback timeout
    setTimeout(() => {
      observer.disconnect();
      resolve(-1);
    }, 10000);
  });
}

function trackCachePerformance() {
  const resources = performance.getEntriesByType("resource") as PerformanceResourceTiming[];

  const cacheStats = resources.reduce(
    (acc, resource) => {
      // Resources with 0 transferSize but positive decodedBodySize are cached
      const isCached = resource.transferSize === 0 && resource.decodedBodySize > 0;

      if (isCached) {
        acc.cachedCount++;
        acc.cachedSize += resource.decodedBodySize;
        acc.cachedLoadTime += resource.responseEnd - resource.fetchStart;
      } else {
        acc.networkCount++;
        acc.networkSize += resource.transferSize;
        acc.networkLoadTime += resource.responseEnd - resource.fetchStart;
      }

      return acc;
    },
    {
      cachedCount: 0,
      networkCount: 0,
      cachedSize: 0,
      networkSize: 0,
      cachedLoadTime: 0,
      networkLoadTime: 0,
    }
  );

  const cacheHitRate =
    cacheStats.cachedCount / (cacheStats.cachedCount + cacheStats.networkCount) || 0;

  analytics.track("pwa_cache_performance", {
    cacheHitRate,
    ...cacheStats,
  });
}
```

### 6.2 Service Worker Metrics

```typescript
// lib/pwa/sw-metrics.ts
import { analytics } from "@/lib/analytics";

interface ServiceWorkerMetrics {
  registered: boolean;
  active: boolean;
  installing: boolean;
  waiting: boolean;
  updateFound: boolean;
  version: string | null;
  cacheNames: string[];
  cacheSize: number;
}

export async function trackServiceWorkerMetrics() {
  if (!("serviceWorker" in navigator)) {
    analytics.track("pwa_sw_not_supported", {});
    return;
  }

  try {
    const registration = await navigator.serviceWorker.getRegistration();

    if (!registration) {
      analytics.track("pwa_sw_not_registered", {});
      return;
    }

    const metrics: ServiceWorkerMetrics = {
      registered: true,
      active: !!registration.active,
      installing: !!registration.installing,
      waiting: !!registration.waiting,
      updateFound: false,
      version: await getSWVersion(registration),
      cacheNames: await getCacheNames(),
      cacheSize: await estimateCacheSize(),
    };

    analytics.track("pwa_sw_metrics", metrics);

    // Track update events
    registration.addEventListener("updatefound", () => {
      analytics.track("pwa_sw_update_found", {
        previousVersion: metrics.version,
        timestamp: Date.now(),
      });

      registration.installing?.addEventListener("statechange", (e) => {
        const sw = e.target as ServiceWorker;
        analytics.track("pwa_sw_state_change", {
          state: sw.state,
          timestamp: Date.now(),
        });
      });
    });
  } catch (error) {
    analytics.track("pwa_sw_metrics_error", {
      error: String(error),
    });
  }
}

async function getSWVersion(
  registration: ServiceWorkerRegistration
): Promise<string | null> {
  return new Promise((resolve) => {
    if (!registration.active) {
      resolve(null);
      return;
    }

    const channel = new MessageChannel();
    channel.port1.onmessage = (event) => {
      resolve(event.data?.version || null);
    };

    registration.active.postMessage({ type: "GET_VERSION" }, [channel.port2]);
    setTimeout(() => resolve(null), 1000);
  });
}

async function getCacheNames(): Promise<string[]> {
  try {
    return await caches.keys();
  } catch {
    return [];
  }
}

async function estimateCacheSize(): Promise<number> {
  if (!("storage" in navigator && "estimate" in navigator.storage)) {
    return -1;
  }

  try {
    const estimate = await navigator.storage.estimate();
    return estimate.usage || 0;
  } catch {
    return -1;
  }
}

// Track SW update flow
export function trackSWUpdateFlow() {
  if (!("serviceWorker" in navigator)) return;

  navigator.serviceWorker.ready.then((registration) => {
    // Check for waiting worker (update available)
    if (registration.waiting) {
      analytics.track("pwa_sw_update_available", {
        timestamp: Date.now(),
      });
    }

    // Listen for controller change (update activated)
    let refreshing = false;
    navigator.serviceWorker.addEventListener("controllerchange", () => {
      if (refreshing) return;
      refreshing = true;

      analytics.track("pwa_sw_update_activated", {
        timestamp: Date.now(),
      });
    });
  });
}

// Track cache operations
export function createCacheTracker() {
  return {
    trackCacheHit(cacheName: string, url: string) {
      analytics.track("pwa_cache_hit", { cacheName, url: new URL(url).pathname });
    },

    trackCacheMiss(cacheName: string, url: string) {
      analytics.track("pwa_cache_miss", { cacheName, url: new URL(url).pathname });
    },

    trackCacheUpdate(cacheName: string, addedUrls: string[], removedUrls: string[]) {
      analytics.track("pwa_cache_update", {
        cacheName,
        added: addedUrls.length,
        removed: removedUrls.length,
      });
    },
  };
}
```

---

## 7. OLD ANDROID DEVICE TRACKING

### 7.1 Device Detection and Segmentation

```typescript
// lib/pwa/device-detection.ts

export interface DeviceInfo {
  os: "android" | "ios" | "windows" | "macos" | "linux" | "unknown";
  osVersion: string;
  osVersionMajor: number;
  browser: string;
  browserVersion: string;
  browserVersionMajor: number;
  isOldAndroid: boolean;
  androidApiLevel: number | null;
  deviceCategory: "old-android" | "modern-android" | "ios" | "desktop" | "unknown";
  webViewVersion: string | null;
  supportsModernPWA: boolean;
}

// Android version to API level mapping
const ANDROID_API_LEVELS: Record<string, number> = {
  "5.0": 21, "5.1": 22,
  "6.0": 23,
  "7.0": 24, "7.1": 25,
  "8.0": 26, "8.1": 27,
  "9": 28,
  "10": 29,
  "11": 30,
  "12": 31, "12.1": 32,
  "13": 33,
  "14": 34,
  "15": 35,
};

export function detectDevice(): DeviceInfo {
  const ua = navigator.userAgent;

  // Detect OS and version
  let os: DeviceInfo["os"] = "unknown";
  let osVersion = "0";
  let osVersionMajor = 0;
  let androidApiLevel: number | null = null;

  const androidMatch = ua.match(/Android\s+([\d.]+)/i);
  if (androidMatch) {
    os = "android";
    osVersion = androidMatch[1];
    osVersionMajor = parseInt(osVersion.split(".")[0], 10);

    // Calculate API level
    const versionKey = Object.keys(ANDROID_API_LEVELS).find(
      (v) => osVersion.startsWith(v)
    );
    androidApiLevel = versionKey ? ANDROID_API_LEVELS[versionKey] : null;
  } else if (/iPad|iPhone|iPod/.test(ua)) {
    os = "ios";
    const iosMatch = ua.match(/OS\s+([\d_]+)/i);
    if (iosMatch) {
      osVersion = iosMatch[1].replace(/_/g, ".");
      osVersionMajor = parseInt(osVersion.split(".")[0], 10);
    }
  } else if (/Windows/.test(ua)) {
    os = "windows";
    const winMatch = ua.match(/Windows NT\s+([\d.]+)/);
    if (winMatch) osVersion = winMatch[1];
  } else if (/Mac OS X/.test(ua)) {
    os = "macos";
    const macMatch = ua.match(/Mac OS X\s+([\d_]+)/);
    if (macMatch) osVersion = macMatch[1].replace(/_/g, ".");
  } else if (/Linux/.test(ua)) {
    os = "linux";
  }

  // Detect browser
  let browser = "unknown";
  let browserVersion = "0";
  let browserVersionMajor = 0;

  if (/Chrome/.test(ua) && !/Edg/.test(ua)) {
    browser = "chrome";
    const chromeMatch = ua.match(/Chrome\/([\d.]+)/);
    if (chromeMatch) {
      browserVersion = chromeMatch[1];
      browserVersionMajor = parseInt(browserVersion.split(".")[0], 10);
    }
  } else if (/Firefox/.test(ua)) {
    browser = "firefox";
    const ffMatch = ua.match(/Firefox\/([\d.]+)/);
    if (ffMatch) {
      browserVersion = ffMatch[1];
      browserVersionMajor = parseInt(browserVersion.split(".")[0], 10);
    }
  } else if (/Safari/.test(ua) && !/Chrome/.test(ua)) {
    browser = "safari";
    const safariMatch = ua.match(/Version\/([\d.]+)/);
    if (safariMatch) {
      browserVersion = safariMatch[1];
      browserVersionMajor = parseInt(browserVersion.split(".")[0], 10);
    }
  } else if (/Edg/.test(ua)) {
    browser = "edge";
    const edgeMatch = ua.match(/Edg\/([\d.]+)/);
    if (edgeMatch) {
      browserVersion = edgeMatch[1];
      browserVersionMajor = parseInt(browserVersion.split(".")[0], 10);
    }
  } else if (/SamsungBrowser/.test(ua)) {
    browser = "samsung";
    const samsungMatch = ua.match(/SamsungBrowser\/([\d.]+)/);
    if (samsungMatch) {
      browserVersion = samsungMatch[1];
      browserVersionMajor = parseInt(browserVersion.split(".")[0], 10);
    }
  }

  // Detect WebView version (for Android)
  let webViewVersion: string | null = null;
  if (os === "android") {
    const webViewMatch = ua.match(/Chrome\/([\d.]+)/);
    webViewVersion = webViewMatch ? webViewMatch[1] : null;
  }

  // Determine if old Android (Android < 10 or Chrome < 80)
  const isOldAndroid =
    os === "android" &&
    (osVersionMajor < 10 ||
      (browser === "chrome" && browserVersionMajor < 80) ||
      (androidApiLevel !== null && androidApiLevel < 29));

  // Determine device category
  let deviceCategory: DeviceInfo["deviceCategory"] = "unknown";
  if (os === "android") {
    deviceCategory = isOldAndroid ? "old-android" : "modern-android";
  } else if (os === "ios") {
    deviceCategory = "ios";
  } else if (os === "windows" || os === "macos" || os === "linux") {
    deviceCategory = "desktop";
  }

  // Check if device supports modern PWA features
  const supportsModernPWA =
    "serviceWorker" in navigator &&
    "PushManager" in window &&
    "Notification" in window &&
    !isOldAndroid;

  return {
    os,
    osVersion,
    osVersionMajor,
    browser,
    browserVersion,
    browserVersionMajor,
    isOldAndroid,
    androidApiLevel,
    deviceCategory,
    webViewVersion,
    supportsModernPWA,
  };
}

// Cache device info
let cachedDeviceInfo: DeviceInfo | null = null;

export function getDeviceInfo(): DeviceInfo {
  if (!cachedDeviceInfo) {
    cachedDeviceInfo = detectDevice();
  }
  return cachedDeviceInfo;
}
```

### 7.2 Performance Metrics by Device Type

```typescript
// lib/pwa/device-performance.ts
import { analytics } from "@/lib/analytics";
import { getDeviceInfo, type DeviceInfo } from "./device-detection";
import { onCLS, onINP, onLCP, onFCP, onTTFB } from "web-vitals";

interface DevicePerformanceMetric {
  metricName: string;
  value: number;
  rating: "good" | "needs-improvement" | "poor";
  deviceCategory: DeviceInfo["deviceCategory"];
  osVersion: string;
  browserVersion: string;
  isOldAndroid: boolean;
  androidApiLevel: number | null;
  connection: string;
  deviceMemory: number | null;
  hardwareConcurrency: number | null;
}

// Performance thresholds by device category
const PERFORMANCE_THRESHOLDS = {
  "old-android": {
    LCP: { good: 1000, poor: 6000 },      // More lenient for old Android
    INP: { good: 100, poor: 600 },
    CLS: { good: 0.15, poor: 0.3 },
    FCP: { good: 3000, poor: 4500 },
    TTFB: { good: 1000, poor: 2000 },
  },
  "modern-android": {
    LCP: { good: 2500, poor: 4000 },
    INP: { good: 200, poor: 500 },
    CLS: { good: 0.1, poor: 0.25 },
    FCP: { good: 1800, poor: 3000 },
    TTFB: { good: 600, poor: 1200 },
  },
  "ios": {
    LCP: { good: 2500, poor: 4000 },
    INP: { good: 200, poor: 500 },
    CLS: { good: 0.1, poor: 0.25 },
    FCP: { good: 1800, poor: 3000 },
    TTFB: { good: 600, poor: 1200 },
  },
  "desktop": {
    LCP: { good: 2500, poor: 4000 },
    INP: { good: 200, poor: 500 },
    CLS: { good: 0.1, poor: 0.25 },
    FCP: { good: 1800, poor: 3000 },
    TTFB: { good: 600, poor: 1200 },
  },
  "unknown": {
    LCP: { good: 2500, poor: 4000 },
    INP: { good: 200, poor: 500 },
    CLS: { good: 0.1, poor: 0.25 },
    FCP: { good: 1800, poor: 3000 },
    TTFB: { good: 600, poor: 1200 },
  },
};

export function initDevicePerformanceTracking() {
  const deviceInfo = getDeviceInfo();
  const thresholds = PERFORMANCE_THRESHOLDS[deviceInfo.deviceCategory];

  const createMetric = (
    name: string,
    value: number,
    rating: "good" | "needs-improvement" | "poor"
  ): DevicePerformanceMetric => ({
    metricName: name,
    value,
    rating,
    deviceCategory: deviceInfo.deviceCategory,
    osVersion: deviceInfo.osVersion,
    browserVersion: deviceInfo.browserVersion,
    isOldAndroid: deviceInfo.isOldAndroid,
    androidApiLevel: deviceInfo.androidApiLevel,
    connection: getConnectionType(),
    deviceMemory: getDeviceMemory(),
    hardwareConcurrency: navigator.hardwareConcurrency ?? null,
  });

  const getRating = (
    name: string,
    value: number
  ): "good" | "needs-improvement" | "poor" => {
    const threshold = thresholds[name as keyof typeof thresholds];
    if (!threshold) return "good";
    if (value <= threshold.good) return "good";
    if (value <= threshold.poor) return "needs-improvement";
    return "poor";
  };

  // Track each web vital with device context
  onLCP((metric) => {
    const deviceMetric = createMetric(
      "LCP",
      metric.value,
      getRating("LCP", metric.value)
    );
    trackDevicePerformance(deviceMetric);
  });

  onCLS((metric) => {
    const deviceMetric = createMetric(
      "CLS",
      metric.value,
      getRating("CLS", metric.value)
    );
    trackDevicePerformance(deviceMetric);
  });

  onINP((metric) => {
    const deviceMetric = createMetric(
      "INP",
      metric.value,
      getRating("INP", metric.value)
    );
    trackDevicePerformance(deviceMetric);
  });

  onFCP((metric) => {
    const deviceMetric = createMetric(
      "FCP",
      metric.value,
      getRating("FCP", metric.value)
    );
    trackDevicePerformance(deviceMetric);
  });

  onTTFB((metric) => {
    const deviceMetric = createMetric(
      "TTFB",
      metric.value,
      getRating("TTFB", metric.value)
    );
    trackDevicePerformance(deviceMetric);
  });

  // Track device-specific performance issues for old Android
  if (deviceInfo.isOldAndroid) {
    trackOldAndroidPerformance();
  }
}

function trackDevicePerformance(metric: DevicePerformanceMetric) {
  analytics.track("pwa_device_performance", metric);

  // Special tracking for old Android with poor performance
  if (metric.isOldAndroid && metric.rating === "poor") {
    analytics.track("pwa_old_android_poor_performance", {
      ...metric,
      timestamp: Date.now(),
    });
  }
}

function trackOldAndroidPerformance() {
  // Track memory pressure on old Android
  if ("memory" in performance) {
    const memory = (performance as any).memory;
    analytics.track("pwa_old_android_memory", {
      usedJSHeapSize: memory?.usedJSHeapSize,
      totalJSHeapSize: memory?.totalJSHeapSize,
      jsHeapSizeLimit: memory?.jsHeapSizeLimit,
      timestamp: Date.now(),
    });
  }

  // Track long tasks (> 50ms) which affect old Android more
  if ("PerformanceObserver" in window) {
    try {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          if (entry.duration > 100) {
            // Extra long task threshold for old Android
            analytics.track("pwa_old_android_long_task", {
              duration: entry.duration,
              startTime: entry.startTime,
              timestamp: Date.now(),
            });
          }
        }
      });
      observer.observe({ entryTypes: ["longtask"] });
    } catch {
      // Long task observer not supported
    }
  }
}

function getConnectionType(): string {
  const connection =
    (navigator as any).connection ||
    (navigator as any).mozConnection ||
    (navigator as any).webkitConnection;
  return connection?.effectiveType ?? "unknown";
}

function getDeviceMemory(): number | null {
  return (navigator as any).deviceMemory ?? null;
}
```

### 7.3 Feature Detection and Fallback Tracking

```typescript
// lib/pwa/feature-tracking.ts
import { analytics } from "@/lib/analytics";
import { getDeviceInfo } from "./device-detection";

interface FeatureSupport {
  feature: string;
  supported: boolean;
  usedFallback: boolean;
  fallbackType?: string;
  deviceCategory: string;
  isOldAndroid: boolean;
}

// Feature detection results cache
const featureCache = new Map<string, boolean>();

// PWA features to track
const PWA_FEATURES = {
  serviceWorker: () => "serviceWorker" in navigator,
  pushManager: () => "PushManager" in window,
  notification: () => "Notification" in window,
  backgroundSync: () => "sync" in ServiceWorkerRegistration.prototype,
  periodicSync: () => "periodicSync" in ServiceWorkerRegistration.prototype,
  backgroundFetch: () => "BackgroundFetchManager" in window,
  persistentStorage: () => navigator.storage?.persist !== undefined,
  storageEstimate: () => navigator.storage?.estimate !== undefined,
  indexedDB: () => "indexedDB" in window,
  cacheAPI: () => "caches" in window,
  webShare: () => "share" in navigator,
  webShareTarget: () => "launchQueue" in window,
  beforeInstallPrompt: () => "BeforeInstallPromptEvent" in window,
  displayModeStandalone: () =>
    window.matchMedia("(display-mode: standalone)").matches,
  badging: () => "setAppBadge" in navigator,
  wakeLock: () => "wakeLock" in navigator,
  fileSystemAccess: () => "showOpenFilePicker" in window,
  clipboardRead: () => "clipboard" in navigator && "read" in navigator.clipboard,
  clipboardWrite: () =>
    "clipboard" in navigator && "writeText" in navigator.clipboard,
  webBluetooth: () => "bluetooth" in navigator,
  webUSB: () => "usb" in navigator,
  webNFC: () => "NDEFReader" in window,
  geolocation: () => "geolocation" in navigator,
  mediaDevices: () => "mediaDevices" in navigator,
  speechRecognition: () =>
    "SpeechRecognition" in window || "webkitSpeechRecognition" in window,
  vibration: () => "vibrate" in navigator,
  batteryAPI: () => "getBattery" in navigator,
  networkInformation: () => "connection" in navigator,
  deviceOrientation: () => "DeviceOrientationEvent" in window,
  pointerEvents: () => "PointerEvent" in window,
  touchEvents: () => "ontouchstart" in window,
  intersectionObserver: () => "IntersectionObserver" in window,
  resizeObserver: () => "ResizeObserver" in window,
  mutationObserver: () => "MutationObserver" in window,
  webGL: () => {
    try {
      const canvas = document.createElement("canvas");
      return !!(
        canvas.getContext("webgl") || canvas.getContext("experimental-webgl")
      );
    } catch {
      return false;
    }
  },
  webGL2: () => {
    try {
      const canvas = document.createElement("canvas");
      return !!canvas.getContext("webgl2");
    } catch {
      return false;
    }
  },
  webWorker: () => "Worker" in window,
  sharedWorker: () => "SharedWorker" in window,
  webAssembly: () => "WebAssembly" in window,
};

export function detectFeatureSupport(feature: string): boolean {
  if (featureCache.has(feature)) {
    return featureCache.get(feature)!;
  }

  const detector = PWA_FEATURES[feature as keyof typeof PWA_FEATURES];
  const supported = detector ? detector() : false;
  featureCache.set(feature, supported);
  return supported;
}

export function trackFeatureUsage(
  feature: string,
  usedFallback: boolean,
  fallbackType?: string
) {
  const deviceInfo = getDeviceInfo();
  const supported = detectFeatureSupport(feature);

  const featureSupport: FeatureSupport = {
    feature,
    supported,
    usedFallback,
    fallbackType,
    deviceCategory: deviceInfo.deviceCategory,
    isOldAndroid: deviceInfo.isOldAndroid,
  };

  analytics.track("pwa_feature_usage", featureSupport);

  // Special tracking for old Android fallbacks
  if (deviceInfo.isOldAndroid && usedFallback) {
    analytics.track("pwa_old_android_fallback", {
      feature,
      fallbackType,
      osVersion: deviceInfo.osVersion,
      browserVersion: deviceInfo.browserVersion,
      androidApiLevel: deviceInfo.androidApiLevel,
      timestamp: Date.now(),
    });
  }
}

// Initialize and report all feature support
export function initFeatureTracking() {
  const deviceInfo = getDeviceInfo();
  const featureReport: Record<string, boolean> = {};

  for (const [feature] of Object.entries(PWA_FEATURES)) {
    featureReport[feature] = detectFeatureSupport(feature);
  }

  analytics.track("pwa_feature_support", {
    features: featureReport,
    deviceCategory: deviceInfo.deviceCategory,
    isOldAndroid: deviceInfo.isOldAndroid,
    osVersion: deviceInfo.osVersion,
    browserVersion: deviceInfo.browserVersion,
    androidApiLevel: deviceInfo.androidApiLevel,
    timestamp: Date.now(),
  });

  // Track missing critical features for old Android
  if (deviceInfo.isOldAndroid) {
    const criticalFeatures = [
      "serviceWorker",
      "pushManager",
      "notification",
      "backgroundSync",
      "indexedDB",
      "cacheAPI",
    ];

    const missingCritical = criticalFeatures.filter(
      (f) => !featureReport[f]
    );

    if (missingCritical.length > 0) {
      analytics.track("pwa_old_android_missing_features", {
        missingFeatures: missingCritical,
        osVersion: deviceInfo.osVersion,
        browserVersion: deviceInfo.browserVersion,
        androidApiLevel: deviceInfo.androidApiLevel,
        timestamp: Date.now(),
      });
    }
  }

  return featureReport;
}

// Wrapper to track fallback usage
export function withFallbackTracking<T>(
  feature: string,
  primaryFn: () => T,
  fallbackFn: () => T,
  fallbackType: string
): T {
  const supported = detectFeatureSupport(feature);

  if (supported) {
    try {
      const result = primaryFn();
      trackFeatureUsage(feature, false);
      return result;
    } catch (error) {
      // Primary failed, use fallback
      trackFeatureUsage(feature, true, `error-${fallbackType}`);
      return fallbackFn();
    }
  } else {
    // Feature not supported, use fallback
    trackFeatureUsage(feature, true, fallbackType);
    return fallbackFn();
  }
}
```

---

## 8. A/B TESTING INSTALL PROMPTS

### 8.1 A/B Test Framework

```typescript
// lib/pwa/ab-testing.ts
import { analytics } from "@/lib/analytics";

interface ABTestVariant {
  id: string;
  name: string;
  weight: number;
}

interface ABTest {
  id: string;
  name: string;
  variants: ABTestVariant[];
}

interface ABTestAssignment {
  testId: string;
  variantId: string;
  assignedAt: number;
}

// Install prompt A/B tests
const installPromptTests: ABTest[] = [
  {
    id: "install_timing",
    name: "Install Prompt Timing",
    variants: [
      { id: "immediate", name: "Immediate", weight: 25 },
      { id: "30s", name: "After 30 seconds", weight: 25 },
      { id: "engagement", name: "After engagement", weight: 25 },
      { id: "scroll", name: "After scroll", weight: 25 },
    ],
  },
  {
    id: "install_ui",
    name: "Install Prompt UI",
    variants: [
      { id: "banner", name: "Bottom Banner", weight: 33 },
      { id: "modal", name: "Center Modal", weight: 33 },
      { id: "inline", name: "Inline Card", weight: 34 },
    ],
  },
  {
    id: "install_copy",
    name: "Install Prompt Copy",
    variants: [
      { id: "benefit", name: "Benefit-focused", weight: 50 },
      { id: "action", name: "Action-focused", weight: 50 },
    ],
  },
];

export function getABTestVariant(testId: string): string {
  // Check for existing assignment
  const stored = getStoredAssignment(testId);
  if (stored) {
    return stored.variantId;
  }

  // Find test
  const test = installPromptTests.find((t) => t.id === testId);
  if (!test) {
    console.warn(`A/B test not found: ${testId}`);
    return "control";
  }

  // Assign variant based on weights
  const variant = assignVariant(test.variants);

  // Store assignment
  storeAssignment({
    testId,
    variantId: variant.id,
    assignedAt: Date.now(),
  });

  // Track assignment
  analytics.track("ab_test_assigned", {
    testId,
    testName: test.name,
    variantId: variant.id,
    variantName: variant.name,
  });

  return variant.id;
}

function assignVariant(variants: ABTestVariant[]): ABTestVariant {
  const totalWeight = variants.reduce((sum, v) => sum + v.weight, 0);
  const random = Math.random() * totalWeight;

  let cumulative = 0;
  for (const variant of variants) {
    cumulative += variant.weight;
    if (random <= cumulative) {
      return variant;
    }
  }

  return variants[variants.length - 1];
}

function getStoredAssignment(testId: string): ABTestAssignment | null {
  try {
    const stored = localStorage.getItem(`ab_test_${testId}`);
    return stored ? JSON.parse(stored) : null;
  } catch {
    return null;
  }
}

function storeAssignment(assignment: ABTestAssignment) {
  localStorage.setItem(
    `ab_test_${assignment.testId}`,
    JSON.stringify(assignment)
  );
}

// Track A/B test conversion
export function trackABTestConversion(
  testId: string,
  conversionType: "install" | "dismiss" | "later"
) {
  const assignment = getStoredAssignment(testId);
  if (!assignment) return;

  analytics.track("ab_test_conversion", {
    testId,
    variantId: assignment.variantId,
    conversionType,
    timeSinceAssignment: Date.now() - assignment.assignedAt,
  });
}
```

### 8.2 Install Prompt Variants

```tsx
// components/pwa/InstallPrompt.tsx
"use client";

import { useEffect, useState } from "react";
import { getABTestVariant, trackABTestConversion } from "@/lib/pwa/ab-testing";
import { triggerInstallPrompt, isInstallPromptAvailable } from "@/lib/pwa/install-tracking";

type UIVariant = "banner" | "modal" | "inline";
type CopyVariant = "benefit" | "action";

const copyVariants: Record<CopyVariant, { title: string; description: string; cta: string }> = {
  benefit: {
    title: "Get the Full Experience",
    description: "Install our app for faster loading, offline access, and push notifications.",
    cta: "Install App",
  },
  action: {
    title: "Install Now",
    description: "Add to your home screen for quick access anytime.",
    cta: "Add to Home Screen",
  },
};

export function InstallPrompt() {
  const [showPrompt, setShowPrompt] = useState(false);
  const [uiVariant, setUIVariant] = useState<UIVariant>("banner");
  const [copyVariant, setCopyVariant] = useState<CopyVariant>("benefit");

  useEffect(() => {
    // Get A/B test assignments
    const ui = getABTestVariant("install_ui") as UIVariant;
    const copy = getABTestVariant("install_copy") as CopyVariant;
    const timing = getABTestVariant("install_timing");

    setUIVariant(ui);
    setCopyVariant(copy);

    // Handle timing variant
    switch (timing) {
      case "immediate":
        if (isInstallPromptAvailable()) setShowPrompt(true);
        break;
      case "30s":
        setTimeout(() => {
          if (isInstallPromptAvailable()) setShowPrompt(true);
        }, 30000);
        break;
      case "engagement":
        trackEngagement(() => {
          if (isInstallPromptAvailable()) setShowPrompt(true);
        });
        break;
      case "scroll":
        trackScroll(() => {
          if (isInstallPromptAvailable()) setShowPrompt(true);
        });
        break;
    }
  }, []);

  const handleInstall = async () => {
    const result = await triggerInstallPrompt(`${uiVariant}_${copyVariant}`);

    if (result.outcome === "accepted") {
      trackABTestConversion("install_ui", "install");
      trackABTestConversion("install_copy", "install");
      trackABTestConversion("install_timing", "install");
    } else {
      trackABTestConversion("install_ui", "dismiss");
      trackABTestConversion("install_copy", "dismiss");
      trackABTestConversion("install_timing", "dismiss");
    }

    setShowPrompt(false);
  };

  const handleDismiss = () => {
    trackABTestConversion("install_ui", "later");
    trackABTestConversion("install_copy", "later");
    trackABTestConversion("install_timing", "later");
    setShowPrompt(false);
  };

  if (!showPrompt) return null;

  const copy = copyVariants[copyVariant];

  // Render based on UI variant
  switch (uiVariant) {
    case "banner":
      return (
        <div className="fixed inset-x-0 bottom-0 z-50 bg-primary p-4 text-primary-foreground shadow-lg">
          <div className="container mx-auto flex items-center justify-between gap-4">
            <div>
              <h3 className="font-semibold">{copy.title}</h3>
              <p className="text-sm opacity-90">{copy.description}</p>
            </div>
            <div className="flex gap-2">
              <button
                onClick={handleDismiss}
                className="rounded-md px-4 py-2 text-sm hover:bg-white/10"
              >
                Later
              </button>
              <button
                onClick={handleInstall}
                className="rounded-md bg-white px-4 py-2 text-sm font-medium text-primary"
              >
                {copy.cta}
              </button>
            </div>
          </div>
        </div>
      );

    case "modal":
      return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-sm rounded-lg bg-background p-6 shadow-xl">
            <h3 className="text-lg font-semibold">{copy.title}</h3>
            <p className="mt-2 text-muted-foreground">{copy.description}</p>
            <div className="mt-6 flex justify-end gap-2">
              <button
                onClick={handleDismiss}
                className="rounded-md px-4 py-2 text-sm hover:bg-muted"
              >
                Later
              </button>
              <button
                onClick={handleInstall}
                className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground"
              >
                {copy.cta}
              </button>
            </div>
          </div>
        </div>
      );

    case "inline":
      return (
        <div className="mx-auto my-4 max-w-md rounded-lg border bg-card p-4 shadow-sm">
          <h3 className="font-semibold">{copy.title}</h3>
          <p className="mt-1 text-sm text-muted-foreground">{copy.description}</p>
          <div className="mt-4 flex gap-2">
            <button
              onClick={handleInstall}
              className="flex-1 rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground"
            >
              {copy.cta}
            </button>
            <button
              onClick={handleDismiss}
              className="rounded-md px-4 py-2 text-sm hover:bg-muted"
            >
              Later
            </button>
          </div>
        </div>
      );
  }
}

// Helper functions for timing variants
function trackEngagement(callback: () => void) {
  let interactions = 0;
  const threshold = 3;

  const handler = () => {
    interactions++;
    if (interactions >= threshold) {
      document.removeEventListener("click", handler);
      callback();
    }
  };

  document.addEventListener("click", handler);
}

function trackScroll(callback: () => void) {
  let called = false;

  const handler = () => {
    if (called) return;

    const scrollPercent =
      window.scrollY / (document.body.scrollHeight - window.innerHeight);

    if (scrollPercent > 0.5) {
      called = true;
      window.removeEventListener("scroll", handler);
      callback();
    }
  };

  window.addEventListener("scroll", handler, { passive: true });
}
```

---

## 9. DASHBOARD AND ANALYTICS INTEGRATION

### 9.1 Dashboard Data Fetching

```typescript
// lib/pwa/dashboard.ts
import { supabase } from "@/integrations/supabase/client";

export interface PWADashboardData {
  overview: {
    totalInstalls: number;
    installsToday: number;
    installsThisWeek: number;
    retention7d: number;
    retention30d: number;
  };
  installFunnel: {
    promptsShown: number;
    promptsAccepted: number;
    promptsDismissed: number;
    conversionRate: number;
  };
  featureAdoption: {
    pushEnabled: number;
    offlineUsage: number;
    backgroundSyncUsage: number;
  };
  performance: {
    avgLCP: number;
    avgCLS: number;
    avgINP: number;
    cacheHitRate: number;
  };
  abTestResults: ABTestResult[];
}

export interface ABTestResult {
  testId: string;
  testName: string;
  variants: {
    id: string;
    name: string;
    impressions: number;
    conversions: number;
    conversionRate: number;
  }[];
  winner: string | null;
  significance: number;
}

export async function fetchPWADashboardData(
  dateRange: { start: Date; end: Date }
): Promise<PWADashboardData> {
  const [
    overviewData,
    funnelData,
    featureData,
    performanceData,
    abTestData,
  ] = await Promise.all([
    fetchOverviewMetrics(dateRange),
    fetchInstallFunnel(dateRange),
    fetchFeatureAdoption(dateRange),
    fetchPerformanceMetrics(dateRange),
    fetchABTestResults(dateRange),
  ]);

  return {
    overview: overviewData,
    installFunnel: funnelData,
    featureAdoption: featureData,
    performance: performanceData,
    abTestResults: abTestData,
  };
}
```

### 9.2 Google Analytics 4 Integration

```typescript
// lib/pwa/ga4-integration.ts

declare global {
  interface Window {
    gtag: (...args: unknown[]) => void;
    dataLayer: unknown[];
  }
}

export function initGA4PWATracking(measurementId: string) {
  // Initialize GA4
  window.dataLayer = window.dataLayer || [];
  window.gtag = function gtag() {
    window.dataLayer.push(arguments);
  };
  window.gtag("js", new Date());
  window.gtag("config", measurementId, {
    // Custom dimensions for PWA
    custom_map: {
      dimension1: "install_source",
      dimension2: "display_mode",
      dimension3: "service_worker_status",
    },
  });

  // Set PWA-specific user properties
  const installSource = getInstallSourceCached();
  const displayMode = getDisplayMode();

  window.gtag("set", "user_properties", {
    pwa_installed: installSource !== "browser",
    install_source: installSource,
    display_mode: displayMode,
  });
}

// Track PWA events in GA4
export const ga4PWAEvents = {
  trackInstall() {
    window.gtag("event", "pwa_install", {
      event_category: "PWA",
      event_label: "Installation Complete",
    });
  },

  trackInstallPromptShown(variant: string) {
    window.gtag("event", "pwa_install_prompt_shown", {
      event_category: "PWA",
      event_label: variant,
    });
  },

  trackInstallPromptResponse(outcome: "accepted" | "dismissed") {
    window.gtag("event", "pwa_install_prompt_response", {
      event_category: "PWA",
      event_label: outcome,
      value: outcome === "accepted" ? 1 : 0,
    });
  },

  trackOfflineUsage(durationMs: number, actionsCount: number) {
    window.gtag("event", "pwa_offline_usage", {
      event_category: "PWA",
      value: durationMs,
      offline_actions: actionsCount,
    });
  },

  trackPushPermission(result: NotificationPermission) {
    window.gtag("event", "pwa_push_permission", {
      event_category: "PWA",
      event_label: result,
    });
  },

  trackWebVital(name: string, value: number, rating: string) {
    window.gtag("event", name, {
      event_category: "Web Vitals",
      value: Math.round(name === "CLS" ? value * 1000 : value),
      metric_rating: rating,
      non_interaction: true,
    });
  },
};
```

---

## 10. ERROR TRACKING

### 10.1 Sentry PWA Integration

```typescript
// lib/pwa/sentry.ts
import * as Sentry from "@sentry/react";
import { getInstallSourceCached } from "./analytics";

export function initSentryPWA() {
  Sentry.init({
    dsn: import.meta.env.VITE_SENTRY_DSN,
    environment: import.meta.env.MODE,
    tracesSampleRate: import.meta.env.PROD ? 0.1 : 1.0,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,

    // PWA-specific configuration
    beforeSend(event, hint) {
      // Add PWA context
      event.tags = {
        ...event.tags,
        install_source: getInstallSourceCached(),
        display_mode: getDisplayMode(),
        service_worker: hasServiceWorker() ? "active" : "inactive",
        online: navigator.onLine ? "yes" : "no",
      };

      // Filter known non-actionable errors
      const error = hint.originalException;
      if (error instanceof Error) {
        // Ignore network errors when offline
        if (
          !navigator.onLine &&
          (error.message.includes("Failed to fetch") ||
            error.message.includes("NetworkError"))
        ) {
          return null;
        }

        // Ignore service worker update errors
        if (error.message.includes("ServiceWorker")) {
          event.level = "warning";
        }
      }

      return event;
    },

    integrations: [
      Sentry.browserTracingIntegration(),
      Sentry.replayIntegration({
        maskAllText: false,
        blockAllMedia: false,
      }),
    ],
  });

  // Set PWA context
  Sentry.setContext("pwa", {
    installSource: getInstallSourceCached(),
    displayMode: getDisplayMode(),
    serviceWorkerSupported: "serviceWorker" in navigator,
    pushSupported: "PushManager" in window,
    notificationSupported: "Notification" in window,
  });

  // Track service worker errors
  trackServiceWorkerErrors();
}

function getDisplayMode(): string {
  if (window.matchMedia("(display-mode: standalone)").matches)
    return "standalone";
  if (window.matchMedia("(display-mode: fullscreen)").matches)
    return "fullscreen";
  return "browser";
}

function hasServiceWorker(): boolean {
  return "serviceWorker" in navigator && !!navigator.serviceWorker.controller;
}

// Track service worker specific errors
function trackServiceWorkerErrors() {
  if (!("serviceWorker" in navigator)) return;

  navigator.serviceWorker.addEventListener("error", (event) => {
    Sentry.captureException(new Error("Service Worker Error"), {
      extra: {
        filename: event.filename,
        lineno: event.lineno,
        message: event.message,
      },
      tags: {
        error_source: "service_worker",
      },
    });
  });

  // Listen for messages from service worker
  navigator.serviceWorker.addEventListener("message", (event) => {
    if (event.data?.type === "SW_ERROR") {
      Sentry.captureException(new Error(event.data.message), {
        extra: event.data.extra,
        tags: {
          error_source: "service_worker",
        },
      });
    }
  });
}
```

---

## 11. INITIALIZATION

### 11.1 Complete Setup

```typescript
// lib/pwa/init.ts
import { initInstallTracking } from "./install-tracking";
import { trackPWALaunch } from "./launch-tracking";
import { initOfflineTracking } from "./offline-tracking";
import { initPWAPerformanceTracking } from "./performance";
import { trackServiceWorkerMetrics, trackSWUpdateFlow } from "./sw-metrics";
import { initSentryPWA } from "./sentry";
import { initGA4PWATracking } from "./ga4-integration";

export async function initPWAAnalytics(options: {
  sentryDsn?: string;
  ga4MeasurementId?: string;
  enableABTesting?: boolean;
}) {
  // 1. Initialize error tracking first
  if (options.sentryDsn) {
    initSentryPWA();
  }

  // 2. Initialize GA4
  if (options.ga4MeasurementId) {
    initGA4PWATracking(options.ga4MeasurementId);
  }

  // 3. Track installation events
  initInstallTracking();

  // 4. Track PWA launch
  trackPWALaunch();

  // 5. Initialize offline tracking
  initOfflineTracking();

  // 6. Initialize performance tracking
  initPWAPerformanceTracking();

  // 7. Track service worker metrics
  await trackServiceWorkerMetrics();
  trackSWUpdateFlow();

  console.log("[PWA Analytics] Initialized");
}
```

### 11.2 React Integration

```tsx
// components/pwa/PWAAnalyticsProvider.tsx
"use client";

import { useEffect } from "react";
import { initPWAAnalytics } from "@/lib/pwa/init";

interface PWAAnalyticsProviderProps {
  children: React.ReactNode;
  sentryDsn?: string;
  ga4MeasurementId?: string;
}

export function PWAAnalyticsProvider({
  children,
  sentryDsn,
  ga4MeasurementId,
}: PWAAnalyticsProviderProps) {
  useEffect(() => {
    initPWAAnalytics({
      sentryDsn,
      ga4MeasurementId,
      enableABTesting: true,
    });
  }, [sentryDsn, ga4MeasurementId]);

  return <>{children}</>;
}

// Usage in App.tsx
export function App() {
  return (
    <PWAAnalyticsProvider
      sentryDsn={import.meta.env.VITE_SENTRY_DSN}
      ga4MeasurementId={import.meta.env.VITE_GA4_ID}
    >
      <Routes />
    </PWAAnalyticsProvider>
  );
}
```

---

## 12. CHECKLIST

```markdown
## PWA Analytics Implementation Checklist

### Installation Tracking
- [ ] Detect PWA vs browser launch
- [ ] Track beforeinstallprompt events
- [ ] Track appinstalled events
- [ ] Track install prompt outcomes
- [ ] Store installation date for retention

### Feature Usage
- [ ] Track offline/online transitions
- [ ] Track offline actions performed
- [ ] Sync offline events when online
- [ ] Track push permission requests
- [ ] Track notification interactions
- [ ] Track background sync queue

### Performance
- [ ] Track Core Web Vitals with PWA context
- [ ] Track cache hit rate
- [ ] Track service worker metrics
- [ ] Track app shell load time

### A/B Testing
- [ ] Implement variant assignment
- [ ] Track prompt timing variants
- [ ] Track UI variants
- [ ] Track copy variants
- [ ] Calculate statistical significance

### Dashboard
- [ ] Set up overview metrics
- [ ] Set up install funnel
- [ ] Set up feature adoption rates
- [ ] Set up performance trends
- [ ] Set up A/B test results

### Error Tracking
- [ ] Initialize Sentry with PWA context
- [ ] Track service worker errors
- [ ] Track offline action failures
- [ ] Track sync errors
- [ ] Track push notification errors

### Old Android Device Tracking
- [ ] Implement device detection (OS, browser, API level)
- [ ] Classify devices as old-android/modern-android/ios/desktop
- [ ] Track performance metrics by device category
- [ ] Set device-specific performance thresholds
- [ ] Track feature support across device types
- [ ] Track fallback usage when features unavailable
- [ ] Capture old Android specific errors
- [ ] Classify errors by type (syntax, memory, service worker, etc.)
- [ ] Monitor FPS and scroll jank on old Android
- [ ] Track memory pressure on old Android
- [ ] Set up old Android dashboard
```

---

## 13. RELATED DOCUMENTS

- [Core Web Vitals](../../_archive/batch-2026-02-19/apex-perf/references/core-web-vitals.md) (archived from apex-perf)
- [Sentry Setup](../../_archive/batch-2026-02-19/apex-monitor/references/sentry-setup.md) (archived from apex-monitor)
- [Offline-First Patterns](../../_archive/batch-2026-02-19/flutter-data/references/sync-strategies.md) (archived from flutter-data)
- [PWA Master Checklist](./pwa-master-checklist.md)

---

## 14. VERIFICATION SEAL

```
OMEGA_v24.5.0 SINGULARITY FORGE | PWA_ANALYTICS
Gates: 7 | Commands: 8 | Phase: 2.4
INSTALL_TRACKING | OFFLINE_TRACKING | PERFORMANCE_MONITORING
AB_TESTING | ERROR_TRACKING | OLD_ANDROID_DETECTION
```

<!-- PWA-EXPERT/ANALYTICS v24.5.0 | Updated: 2026-02-19 -->

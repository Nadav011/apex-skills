# PWA iOS Limitations v24.5.0 SINGULARITY FORGE

> iOS/Safari PWA platform-specific limitations, detection patterns, and production-ready workarounds

---

## 1. PURPOSE

This skill documents all critical iOS PWA limitations and provides:
- Comprehensive platform detection functions
- Storage quota management for 50MB limit
- Background sync alternatives (iOS lacks Background Sync API)
- Push notification requirements (iOS 16.4+, PWA-only)
- Service worker persistence strategies
- Safe area handling for notched devices

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/pwa ios-detect` | Run iOS/PWA detection diagnostics | ~5s |
| `/pwa ios-storage` | Check and manage storage quota | ~10s |
| `/pwa ios-sync` | Setup visibility-based sync for iOS | ~2min |
| `/pwa ios-push` | Configure iOS 16.4+ push notifications | ~3min |
| `/pwa ios-icons` | Generate apple-touch-icon and splash screens | ~1min |
| `/pwa ios-audit` | Full iOS PWA compatibility audit | ~1min |

---

## 3. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-IOS-1 | PLATFORM_DETECT | `isIOSPWA()` function exists | Correct detection |
| G-IOS-2 | STORAGE_QUOTA | Storage usage < 80% | No quota errors |
| G-IOS-3 | SYNC_FALLBACK | Visibility-based sync implemented | Offline actions sync |
| G-IOS-4 | PUSH_16_4 | Push permission flow for iOS 16.4+ | Permission granted |
| G-IOS-5 | SW_HEALTH | Service worker recovery implemented | SW survives 3+ days |
| G-IOS-6 | SAFE_AREA | viewport-fit=cover + CSS env() | No content clipping |
| G-IOS-7 | INPUT_ZOOM | All inputs font-size >= 16px | No zoom on focus |
| G-IOS-8 | SPLASH_SCREENS | apple-touch-startup-image for all sizes | Fast launch |

---

## 4. OVERVIEW

Progressive Web Apps on iOS/Safari face significant platform-specific limitations compared to Android/Chrome. This skill documents all critical limitations, detection patterns, and production-ready workarounds for building robust PWAs that work reliably on Apple devices.

---

## 5. PLATFORM DETECTION

### Core Detection Functions

```typescript
// lib/pwa/platform-detection.ts

/**
 * Comprehensive iOS PWA detection
 */
export const iosPwaDetection = {
  /**
   * Check if running on iOS (iPhone, iPad, iPod)
   */
  isIOS(): boolean {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
      (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  },

  /**
   * Check if running as installed PWA (standalone mode)
   */
  isStandalone(): boolean {
    return window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as any).standalone === true;
  },

  /**
   * Check if running as iOS PWA specifically
   */
  isIOSPWA(): boolean {
    return this.isIOS() && this.isStandalone();
  },

  /**
   * Get iOS version
   */
  getIOSVersion(): number | null {
    const match = navigator.userAgent.match(/OS (\d+)_(\d+)_?(\d+)?/);
    if (!match) return null;
    return parseInt(match[1], 10);
  },

  /**
   * Check if running in Safari browser (not PWA)
   */
  isSafariBrowser(): boolean {
    return this.isIOS() && !this.isStandalone() &&
      /Safari/.test(navigator.userAgent) &&
      !/CriOS|FxiOS|OPiOS/.test(navigator.userAgent);
  },

  /**
   * Check if push notifications are supported
   * Only available in iOS 16.4+ PWA mode
   */
  supportsPushNotifications(): boolean {
    const iosVersion = this.getIOSVersion();
    return this.isIOSPWA() &&
      iosVersion !== null &&
      iosVersion >= 16 &&
      'PushManager' in window;
  },

  /**
   * Check if Background Sync is supported (NOT on iOS)
   */
  supportsBackgroundSync(): boolean {
    return 'serviceWorker' in navigator &&
      'sync' in (window as any).ServiceWorkerRegistration?.prototype &&
      !this.isIOS();
  },

  /**
   * Check if Periodic Background Sync is supported (NOT on iOS)
   */
  supportsPeriodicSync(): boolean {
    return 'serviceWorker' in navigator &&
      'periodicSync' in (window as any).ServiceWorkerRegistration?.prototype &&
      !this.isIOS();
  },

  /**
   * Check if Badge API is supported (NOT on iOS)
   */
  supportsBadging(): boolean {
    return 'setAppBadge' in navigator && !this.isIOS();
  },

  /**
   * Check if File Handling API is supported (NOT on iOS)
   */
  supportsFileHandling(): boolean {
    return 'launchQueue' in window && !this.isIOS();
  },
};

// React hook version
export function useIOSPWA() {
  const [state, setState] = useState({
    isIOS: false,
    isStandalone: false,
    isIOSPWA: false,
    iosVersion: null as number | null,
    supportsPush: false,
    supportsBackgroundSync: false,
  });

  useEffect(() => {
    setState({
      isIOS: iosPwaDetection.isIOS(),
      isStandalone: iosPwaDetection.isStandalone(),
      isIOSPWA: iosPwaDetection.isIOSPWA(),
      iosVersion: iosPwaDetection.getIOSVersion(),
      supportsPush: iosPwaDetection.supportsPushNotifications(),
      supportsBackgroundSync: iosPwaDetection.supportsBackgroundSync(),
    });
  }, []);

  return state;
}
```

---

## 6. STORAGE QUOTA LIMITATION (50MB)

### The Problem

iOS Safari and PWAs have a strict 50MB per-domain storage limit that includes:
- IndexedDB
- Cache API (Service Worker caches)
- localStorage
- sessionStorage

There is **no way to request more storage** on iOS.

### Detection

```typescript
// lib/pwa/storage-quota.ts

export async function getStorageEstimate(): Promise<{
  usage: number;
  quota: number;
  percentUsed: number;
  isLow: boolean;
}> {
  if ('storage' in navigator && 'estimate' in navigator.storage) {
    const estimate = await navigator.storage.estimate();
    const usage = estimate.usage || 0;
    const quota = estimate.quota || 0;
    const percentUsed = quota > 0 ? (usage / quota) * 100 : 0;

    return {
      usage,
      quota,
      percentUsed,
      isLow: percentUsed > 80,
    };
  }

  // Fallback for older browsers
  return {
    usage: 0,
    quota: 50 * 1024 * 1024, // Assume 50MB on iOS
    percentUsed: 0,
    isLow: false,
  };
}

export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
```

### Workarounds

```typescript
// lib/pwa/storage-cleanup.ts

interface CleanupStrategy {
  maxAge?: number; // Max age in milliseconds
  maxSize?: number; // Max size in bytes
  priority?: 'fifo' | 'lru' | 'size'; // Cleanup priority
}

export class StorageManager {
  private readonly STORAGE_KEY = 'pwa_storage_metadata';

  /**
   * Track item for cleanup
   */
  async trackItem(
    storeName: string,
    key: string,
    size: number
  ): Promise<void> {
    const metadata = await this.getMetadata();
    metadata.items[`${storeName}:${key}`] = {
      size,
      createdAt: Date.now(),
      lastAccessed: Date.now(),
    };
    await this.saveMetadata(metadata);
  }

  /**
   * Mark item as accessed (for LRU)
   */
  async touchItem(storeName: string, key: string): Promise<void> {
    const metadata = await this.getMetadata();
    const itemKey = `${storeName}:${key}`;
    if (metadata.items[itemKey]) {
      metadata.items[itemKey].lastAccessed = Date.now();
      await this.saveMetadata(metadata);
    }
  }

  /**
   * Cleanup old/large items based on strategy
   */
  async cleanup(
    db: IDBDatabase,
    strategy: CleanupStrategy = {}
  ): Promise<{ freedBytes: number; itemsRemoved: number }> {
    const { maxAge = 7 * 24 * 60 * 60 * 1000, priority = 'lru' } = strategy;
    const metadata = await this.getMetadata();
    const now = Date.now();

    let items = Object.entries(metadata.items);
    let freedBytes = 0;
    let itemsRemoved = 0;

    // Sort based on priority
    switch (priority) {
      case 'fifo':
        items.sort((a, b) => a[1].createdAt - b[1].createdAt);
        break;
      case 'lru':
        items.sort((a, b) => a[1].lastAccessed - b[1].lastAccessed);
        break;
      case 'size':
        items.sort((a, b) => b[1].size - a[1].size);
        break;
    }

    // Remove old items first
    for (const [key, item] of items) {
      if (now - item.createdAt > maxAge) {
        const [storeName, itemKey] = key.split(':');
        await this.deleteFromStore(db, storeName, itemKey);
        freedBytes += item.size;
        itemsRemoved++;
        delete metadata.items[key];
      }
    }

    await this.saveMetadata(metadata);
    return { freedBytes, itemsRemoved };
  }

  /**
   * Aggressive cleanup when storage is critically low
   */
  async emergencyCleanup(db: IDBDatabase): Promise<void> {
    const estimate = await getStorageEstimate();

    if (estimate.percentUsed > 90) {
      // Clear all caches except critical ones
      const cacheNames = await caches.keys();
      for (const cacheName of cacheNames) {
        if (!cacheName.includes('critical')) {
          await caches.delete(cacheName);
        }
      }

      // Clear old IndexedDB data
      await this.cleanup(db, {
        maxAge: 24 * 60 * 60 * 1000, // 1 day
        priority: 'lru',
      });
    }
  }

  private async getMetadata(): Promise<StorageMetadata> {
    try {
      const data = localStorage.getItem(this.STORAGE_KEY);
      return data ? JSON.parse(data) : { items: {} };
    } catch {
      return { items: {} };
    }
  }

  private async saveMetadata(metadata: StorageMetadata): Promise<void> {
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(metadata));
  }

  private async deleteFromStore(
    db: IDBDatabase,
    storeName: string,
    key: string
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const tx = db.transaction(storeName, 'readwrite');
        const store = tx.objectStore(storeName);
        store.delete(key);
        tx.oncomplete = () => resolve();
        tx.onerror = () => reject(tx.error);
      } catch {
        resolve(); // Store might not exist
      }
    });
  }
}

interface StorageMetadata {
  items: {
    [key: string]: {
      size: number;
      createdAt: number;
      lastAccessed: number;
    };
  };
}
```

### Storage Warning Component

```tsx
// components/StorageWarning.tsx

export function StorageWarning() {
  const [storage, setStorage] = useState<{
    usage: number;
    quota: number;
    percentUsed: number;
  } | null>(null);

  useEffect(() => {
    getStorageEstimate().then(setStorage);
  }, []);

  if (!storage || storage.percentUsed < 80) return null;

  return (
    <div
      className={cn(
        'fixed bottom-4 inset-s-4 inset-e-4 p-4 rounded-lg z-50',
        storage.percentUsed > 90
          ? 'bg-red-100 dark:bg-red-900'
          : 'bg-yellow-100 dark:bg-yellow-900'
      )}
      dir="rtl"
    >
      <div className="flex items-center gap-3">
        <AlertTriangle className="h-5 w-5 flex-shrink-0" />
        <div className="flex-1">
          <p className="font-medium">
            {storage.percentUsed > 90 ? 'אחסון כמעט מלא' : 'אחסון נמוך'}
          </p>
          <p className="text-sm opacity-80">
            {formatBytes(storage.usage)} / {formatBytes(storage.quota)}
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            // Trigger cleanup
          }}
        >
          נקה
        </Button>
      </div>
    </div>
  );
}
```

---

## 7. NO BACKGROUND SYNC API

### The Problem

iOS Safari does NOT support the Background Sync API (`sync` event). This means:
- No guaranteed delivery of offline actions
- No automatic retry when connection is restored
- Service Worker cannot wake up to sync data

### Detection

```typescript
const supportsBackgroundSync = 'serviceWorker' in navigator &&
  'sync' in ServiceWorkerRegistration.prototype &&
  !iosPwaDetection.isIOS();
```

### Workaround: Visibility-Based Sync

```typescript
// lib/pwa/ios-sync.ts

export class IOSSyncManager {
  private pendingQueue: PendingAction[] = [];
  private readonly QUEUE_KEY = 'ios_sync_queue';

  constructor() {
    this.loadQueue();
    this.setupVisibilitySync();
    this.setupOnlineSync();
  }

  /**
   * Queue action for sync
   */
  async queueAction(action: PendingAction): Promise<void> {
    this.pendingQueue.push({
      ...action,
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      retryCount: 0,
    });
    await this.saveQueue();

    // Try to sync immediately if online
    if (navigator.onLine) {
      await this.processQueue();
    }
  }

  /**
   * Sync when app becomes visible
   */
  private setupVisibilitySync(): void {
    document.addEventListener('visibilitychange', async () => {
      if (document.visibilityState === 'visible' && navigator.onLine) {
        await this.processQueue();
      }
    });
  }

  /**
   * Sync when coming online
   */
  private setupOnlineSync(): void {
    window.addEventListener('online', async () => {
      await this.processQueue();
    });
  }

  /**
   * Process pending queue
   */
  async processQueue(): Promise<{
    processed: number;
    failed: number;
  }> {
    if (this.pendingQueue.length === 0) {
      return { processed: 0, failed: 0 };
    }

    let processed = 0;
    let failed = 0;
    const failedActions: PendingAction[] = [];

    for (const action of this.pendingQueue) {
      try {
        await this.executeAction(action);
        processed++;
      } catch (error) {
        action.retryCount++;
        action.lastError = String(error);

        if (action.retryCount < 3) {
          failedActions.push(action);
        } else {
          failed++;
          // Move to dead letter queue
          await this.moveToDeadLetter(action);
        }
      }
    }

    this.pendingQueue = failedActions;
    await this.saveQueue();

    return { processed, failed };
  }

  private async executeAction(action: PendingAction): Promise<void> {
    const response = await fetch(action.url, {
      method: action.method,
      headers: action.headers,
      body: action.body ? JSON.stringify(action.body) : undefined,
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
  }

  private loadQueue(): void {
    try {
      const data = localStorage.getItem(this.QUEUE_KEY);
      this.pendingQueue = data ? JSON.parse(data) : [];
    } catch {
      this.pendingQueue = [];
    }
  }

  private async saveQueue(): Promise<void> {
    localStorage.setItem(this.QUEUE_KEY, JSON.stringify(this.pendingQueue));
  }

  private async moveToDeadLetter(action: PendingAction): Promise<void> {
    const deadLetter = JSON.parse(
      localStorage.getItem('ios_sync_dead_letter') || '[]'
    );
    deadLetter.push({
      ...action,
      failedAt: Date.now(),
    });
    localStorage.setItem('ios_sync_dead_letter', JSON.stringify(deadLetter));
  }

  /**
   * Get queue status
   */
  getStatus(): {
    pending: number;
    failed: number;
  } {
    const deadLetter = JSON.parse(
      localStorage.getItem('ios_sync_dead_letter') || '[]'
    );
    return {
      pending: this.pendingQueue.length,
      failed: deadLetter.length,
    };
  }
}

interface PendingAction {
  id?: string;
  url: string;
  method: string;
  headers?: Record<string, string>;
  body?: unknown;
  timestamp?: number;
  retryCount?: number;
  lastError?: string;
}
```

### React Hook for iOS Sync

```tsx
// hooks/useIOSSync.ts

export function useIOSSync() {
  const syncManager = new IOSSyncManager();
  const [status, setStatus] = useState({ pending: 0, failed: 0 });
  const [isSyncing, setIsSyncing] = useState(false);

  const queueAction = async (action: PendingAction) => {
    await syncManager.queueAction(action);
    setStatus(syncManager.getStatus());
  };

  const forceSync = async () => {
    setIsSyncing(true);
    try {
      await syncManager.processQueue();
      setStatus(syncManager.getStatus());
    } finally {
      setIsSyncing(false);
    }
  };

  useEffect(() => {
    setStatus(syncManager.getStatus());
  }, [syncManager]);

  return {
    queueAction,
    forceSync,
    status,
    isSyncing,
  };
}
```

---

## 8. NO PERIODIC BACKGROUND SYNC

### The Problem

iOS does NOT support Periodic Background Sync (`periodicSync`). This means:
- No scheduled background tasks
- No periodic data refresh
- App cannot fetch updates in background

### Workaround: App Launch Sync

```typescript
// lib/pwa/periodic-sync-fallback.ts

export class PeriodicSyncFallback {
  private readonly LAST_SYNC_KEY = 'last_periodic_sync';
  private readonly MIN_INTERVAL = 60 * 60 * 1000; // 1 hour minimum

  constructor(
    private syncCallback: () => Promise<void>,
    private interval: number = 4 * 60 * 60 * 1000 // 4 hours
  ) {
    this.checkAndSync();
    this.setupVisibilityCheck();
  }

  /**
   * Check if sync is needed and execute
   */
  async checkAndSync(): Promise<boolean> {
    const lastSync = this.getLastSyncTime();
    const now = Date.now();

    if (now - lastSync >= this.interval) {
      try {
        await this.syncCallback();
        this.setLastSyncTime(now);
        return true;
      } catch (error) {
        console.error('Periodic sync failed:', error);
        return false;
      }
    }

    return false;
  }

  /**
   * Force sync regardless of interval
   */
  async forceSync(): Promise<void> {
    await this.syncCallback();
    this.setLastSyncTime(Date.now());
  }

  /**
   * Check sync on visibility change (app comes to foreground)
   */
  private setupVisibilityCheck(): void {
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        this.checkAndSync();
      }
    });

    // Also check on focus
    window.addEventListener('focus', () => {
      this.checkAndSync();
    });
  }

  private getLastSyncTime(): number {
    return parseInt(localStorage.getItem(this.LAST_SYNC_KEY) || '0', 10);
  }

  private setLastSyncTime(time: number): void {
    localStorage.setItem(this.LAST_SYNC_KEY, String(time));
  }

  /**
   * Get time until next sync
   */
  getTimeUntilNextSync(): number {
    const lastSync = this.getLastSyncTime();
    const nextSync = lastSync + this.interval;
    return Math.max(0, nextSync - Date.now());
  }
}

// Usage
const periodicSync = new PeriodicSyncFallback(
  async () => {
    // Fetch latest data
    await fetchLatestData();
    // Update caches
    await updateCaches();
  },
  4 * 60 * 60 * 1000 // Every 4 hours
);
```

---

## 9. SERVICE WORKER PERSISTENCE

### The Problem

iOS terminates Service Workers after ~3 days of app inactivity. This means:
- Cached data may be lost
- SW needs re-registration
- First load after termination is slower

### Workaround: SW Health Check

```typescript
// lib/pwa/sw-health.ts

export class ServiceWorkerHealth {
  private readonly LAST_ACTIVE_KEY = 'sw_last_active';
  private readonly MAX_INACTIVE_DAYS = 2;

  constructor() {
    this.setupActivityTracking();
  }

  /**
   * Check if SW might have been terminated
   */
  async checkHealth(): Promise<{
    isHealthy: boolean;
    reason?: string;
    action?: 'refresh' | 'reinstall';
  }> {
    const lastActive = this.getLastActiveTime();
    const daysSinceActive = (Date.now() - lastActive) / (24 * 60 * 60 * 1000);

    if (daysSinceActive > this.MAX_INACTIVE_DAYS) {
      // SW might have been terminated
      const registration = await navigator.serviceWorker.getRegistration();

      if (!registration) {
        return {
          isHealthy: false,
          reason: 'SW terminated after inactivity',
          action: 'reinstall',
        };
      }

      if (!registration.active) {
        return {
          isHealthy: false,
          reason: 'SW not active',
          action: 'refresh',
        };
      }
    }

    return { isHealthy: true };
  }

  /**
   * Attempt to recover SW
   */
  async recover(): Promise<void> {
    const health = await this.checkHealth();

    if (!health.isHealthy) {
      if (health.action === 'reinstall') {
        // Force re-registration
        const registrations = await navigator.serviceWorker.getRegistrations();
        for (const reg of registrations) {
          await reg.unregister();
        }
        // Re-register (handled by SW registration code)
        window.location.reload();
      } else if (health.action === 'refresh') {
        window.location.reload();
      }
    }
  }

  /**
   * Track app activity
   */
  private setupActivityTracking(): void {
    // Update on any user activity
    const updateActivity = () => {
      localStorage.setItem(this.LAST_ACTIVE_KEY, String(Date.now()));
    };

    // Track visibility
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        updateActivity();
        this.checkHealth();
      }
    });

    // Track interactions
    ['click', 'touchstart', 'keydown'].forEach((event) => {
      document.addEventListener(event, updateActivity, { passive: true });
    });

    // Initial update
    updateActivity();
  }

  private getLastActiveTime(): number {
    return parseInt(localStorage.getItem(this.LAST_ACTIVE_KEY) || '0', 10);
  }
}
```

### Critical Data Persistence

```typescript
// lib/pwa/critical-data.ts

/**
 * Store critical data redundantly across multiple storage mechanisms
 */
export class CriticalDataStore<T> {
  constructor(
    private key: string,
    private validator: (data: unknown) => data is T
  ) {}

  async save(data: T): Promise<void> {
    const serialized = JSON.stringify(data);

    // Save to multiple locations
    await Promise.all([
      this.saveToLocalStorage(serialized),
      this.saveToIndexedDB(serialized),
      this.saveToSessionStorage(serialized),
    ]);
  }

  async load(): Promise<T | null> {
    // Try sources in order of reliability
    const sources = [
      () => this.loadFromLocalStorage(),
      () => this.loadFromIndexedDB(),
      () => this.loadFromSessionStorage(),
    ];

    for (const source of sources) {
      try {
        const data = await source();
        if (data && this.validator(data)) {
          return data;
        }
      } catch {
        continue;
      }
    }

    return null;
  }

  private async saveToLocalStorage(data: string): Promise<void> {
    localStorage.setItem(this.key, data);
  }

  private loadFromLocalStorage(): unknown {
    const data = localStorage.getItem(this.key);
    return data ? JSON.parse(data) : null;
  }

  private async saveToIndexedDB(data: string): Promise<void> {
    const db = await this.openDB();
    const tx = db.transaction('critical', 'readwrite');
    tx.objectStore('critical').put({ key: this.key, value: data });
  }

  private async loadFromIndexedDB(): Promise<unknown> {
    const db = await this.openDB();
    const tx = db.transaction('critical', 'readonly');
    const result = await new Promise<{ value: string } | undefined>(
      (resolve) => {
        const request = tx.objectStore('critical').get(this.key);
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => resolve(undefined);
      }
    );
    return result ? JSON.parse(result.value) : null;
  }

  private async saveToSessionStorage(data: string): Promise<void> {
    sessionStorage.setItem(this.key, data);
  }

  private loadFromSessionStorage(): unknown {
    const data = sessionStorage.getItem(this.key);
    return data ? JSON.parse(data) : null;
  }

  private async openDB(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('critical_store', 1);
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
      request.onupgradeneeded = () => {
        request.result.createObjectStore('critical', { keyPath: 'key' });
      };
    });
  }
}
```

---

## 10. PUSH NOTIFICATIONS (iOS 16.4+)

### The Problem

Push notifications on iOS have strict requirements:
- Only work in **installed PWA** (not Safari browser)
- Only available on **iOS 16.4+**
- Require **user gesture** to subscribe
- Limited notification options (no images, limited actions)

### Detection and Setup

```typescript
// lib/pwa/ios-push.ts

export class IOSPushManager {
  /**
   * Check if push is available
   */
  static isAvailable(): boolean {
    return iosPwaDetection.supportsPushNotifications();
  }

  /**
   * Check if we can request permission
   * MUST be called from user gesture on iOS
   */
  static canRequestPermission(): boolean {
    return this.isAvailable() && Notification.permission === 'default';
  }

  /**
   * Request push permission
   * MUST be triggered by user click/tap
   */
  static async requestPermission(): Promise<NotificationPermission> {
    if (!this.isAvailable()) {
      throw new Error('Push notifications not available on this device');
    }

    // iOS requires this to be in a user gesture handler
    const permission = await Notification.requestPermission();
    return permission;
  }

  /**
   * Subscribe to push notifications
   * @param vapidPublicKey - Your VAPID public key
   */
  static async subscribe(
    vapidPublicKey: string
  ): Promise<PushSubscription | null> {
    if (Notification.permission !== 'granted') {
      return null;
    }

    const registration = await navigator.serviceWorker.ready;

    try {
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey),
      });

      return subscription;
    } catch (error) {
      console.error('Push subscription failed:', error);
      return null;
    }
  }

  private static urlBase64ToUint8Array(base64String: string): Uint8Array {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }
}

/**
 * iOS-safe notification with limited options
 */
export function createIOSNotification(
  title: string,
  options: IOSNotificationOptions
): Notification {
  // iOS ignores most advanced options
  return new Notification(title, {
    body: options.body,
    tag: options.tag,
    // iOS ignores: image, actions, badge, icon (uses app icon)
  });
}

interface IOSNotificationOptions {
  body?: string;
  tag?: string;
}
```

### Push Permission UI

```tsx
// components/PushPermissionButton.tsx

export function PushPermissionButton() {
  const [status, setStatus] = useState<'unsupported' | 'default' | 'granted' | 'denied'>('default');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!IOSPushManager.isAvailable()) {
      setStatus('unsupported');
    } else {
      setStatus(Notification.permission as any);
    }
  }, []);

  const handleRequest = async () => {
    setIsLoading(true);
    try {
      const permission = await IOSPushManager.requestPermission();
      setStatus(permission as any);

      if (permission === 'granted') {
        const subscription = await IOSPushManager.subscribe(
          import.meta.env.VITE_VAPID_PUBLIC_KEY
        );
        if (subscription) {
          // Send subscription to server
          await sendSubscriptionToServer(subscription);
        }
      }
    } finally {
      setIsLoading(false);
    }
  };

  if (status === 'unsupported') {
    return (
      <div className="text-sm text-muted-foreground" dir="rtl">
        התראות זמינות רק באפליקציה המותקנת (iOS 16.4+)
      </div>
    );
  }

  if (status === 'granted') {
    return (
      <div className="flex items-center gap-2 text-green-600" dir="rtl">
        <Check className="h-4 w-4" />
        <span>התראות מופעלות</span>
      </div>
    );
  }

  if (status === 'denied') {
    return (
      <div className="text-sm text-muted-foreground" dir="rtl">
        התראות נחסמו. יש לאפשר בהגדרות המכשיר.
      </div>
    );
  }

  return (
    <Button
      onClick={handleRequest}
      disabled={isLoading}
      className="min-h-11"
    >
      {isLoading ? (
        <Loader2 className="h-4 w-4 animate-spin" />
      ) : (
        'אפשר התראות'
      )}
    </Button>
  );
}
```

---

## 11. NO BADGE API

### The Problem

iOS Safari does not support `navigator.setAppBadge()`. There is no way to show badge numbers on the app icon.

### Workaround: In-App Badge Indicator

```tsx
// components/BadgeIndicator.tsx

/**
 * In-app badge indicator since iOS doesn't support app badges
 */
export function BadgeIndicator({
  count,
  className,
}: {
  count: number;
  className?: string;
}) {
  if (count === 0) return null;

  return (
    <span
      className={cn(
        'absolute -top-1 -inset-e-1 flex h-5 min-w-5 items-center justify-center',
        'rounded-full bg-red-500 text-xs font-medium text-white',
        'px-1',
        className
      )}
      dir="ltr"
    >
      {count > 99 ? '99+' : count}
    </span>
  );
}

// Usage with navigation icon
export function NotificationIcon() {
  const { pendingCount } = usePendingNotifications();

  return (
    <div className="relative">
      <Bell className="h-6 w-6" />
      <BadgeIndicator count={pendingCount} />
    </div>
  );
}
```

### Badge via Favicon (Browser Tab)

```typescript
// lib/pwa/favicon-badge.ts

export function setFaviconBadge(count: number): void {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d')!;
  const img = new Image();

  canvas.width = 32;
  canvas.height = 32;

  img.onload = () => {
    ctx.drawImage(img, 0, 0, 32, 32);

    if (count > 0) {
      // Draw badge circle
      ctx.fillStyle = '#ef4444';
      ctx.beginPath();
      ctx.arc(24, 8, 8, 0, 2 * Math.PI);
      ctx.fill();

      // Draw badge text
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 10px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(count > 9 ? '9+' : String(count), 24, 8);
    }

    // Update favicon
    const link =
      document.querySelector<HTMLLinkElement>("link[rel='icon']") ||
      document.createElement('link');
    link.rel = 'icon';
    link.href = canvas.toDataURL();
    document.head.appendChild(link);
  };

  img.src = '/favicon.png';
}
```

---

## 12. NO FILE HANDLING API

### The Problem

iOS does not support the File Handling API (`file_handlers` in manifest). PWAs cannot register to handle file types.

### Workaround: Share Target

```json
// manifest.json
{
  "share_target": {
    "action": "/share-target",
    "method": "POST",
    "enctype": "multipart/form-data",
    "params": {
      "files": [
        {
          "name": "files",
          "accept": ["image/*", "application/pdf"]
        }
      ]
    }
  }
}
```

```typescript
// pages/share-target.tsx (or route handler)

export async function handleShareTarget(request: Request) {
  const formData = await request.formData();
  const files = formData.getAll('files') as File[];

  // Process shared files
  for (const file of files) {
    await processFile(file);
  }

  // Redirect to main app
  return Response.redirect('/', 303);
}
```

---

## 13. NO WINDOW CONTROLS OVERLAY

### The Problem

iOS does not support `display_override: ["window-controls-overlay"]`. PWAs cannot customize the title bar area.

### Workaround: Safe Area Handling

```css
/* Safe area insets for iOS */
:root {
  --safe-area-top: env(safe-area-inset-top, 0px);
  --safe-area-bottom: env(safe-area-inset-bottom, 0px);
  --safe-area-left: env(safe-area-inset-left, 0px);
  --safe-area-right: env(safe-area-inset-right, 0px);
}

/* Header with safe area */
.app-header {
  padding-top: calc(var(--safe-area-top) + 1rem);
  padding-inline-start: calc(var(--safe-area-left) + 1rem);
  padding-inline-end: calc(var(--safe-area-right) + 1rem);
}

/* Bottom navigation with safe area */
.bottom-nav {
  padding-bottom: var(--safe-area-bottom);
}
```

---

## 14. SAFE AREA HANDLING

### Complete Safe Area Solution

```tsx
// components/SafeAreaProvider.tsx

const SafeAreaContext = createContext({
  top: 0,
  bottom: 0,
  left: 0,
  right: 0,
});

export function SafeAreaProvider({ children }: { children: ReactNode }) {
  const [safeAreas, setSafeAreas] = useState({
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
  });

  useEffect(() => {
    const updateSafeAreas = () => {
      const style = getComputedStyle(document.documentElement);
      setSafeAreas({
        top: parseInt(style.getPropertyValue('--safe-area-top') || '0', 10),
        bottom: parseInt(style.getPropertyValue('--safe-area-bottom') || '0', 10),
        left: parseInt(style.getPropertyValue('--safe-area-left') || '0', 10),
        right: parseInt(style.getPropertyValue('--safe-area-right') || '0', 10),
      });
    };

    updateSafeAreas();
    window.addEventListener('resize', updateSafeAreas);
    return () => window.removeEventListener('resize', updateSafeAreas);
  }, []);

  return (
    <SafeAreaContext value={safeAreas}>
      {children}
    </SafeAreaContext>
  );
}

export function useSafeArea() {
  return useContext(SafeAreaContext);
}
```

### Meta Tags for Safe Area

```html
<!-- index.html -->
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
<meta name="apple-mobile-web-app-capable" content="yes" />
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
```

---

## 15. INPUT ZOOM PREVENTION

### The Problem

iOS Safari zooms in on input fields with font-size smaller than 16px.

### Solution

```css
/* Prevent iOS zoom on inputs */
input,
textarea,
select {
  font-size: 16px;
}

/* Or use transform for visual scaling */
input.small-input {
  font-size: 16px;
  transform: scale(0.875);
  transform-origin: left top;
}
```

```tsx
// components/Input.tsx

export function Input({ className, ref, ...props }: InputProps & { ref?: React.Ref<HTMLInputElement> }) {
  return (
    <input
      ref={ref}
      className={cn(
        'h-11 w-full rounded-md border px-3',
        // Force 16px to prevent iOS zoom
        'text-base',
        className
      )}
      {...props}
    />
  );
}
```

---

## 16. SPLASH SCREEN REQUIREMENTS

### apple-touch-startup-image Sizes

```html
<!-- iPhone 15 Pro Max, 14 Pro Max -->
<link rel="apple-touch-startup-image"
      href="/splash-1290x2796.png"
      media="(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3)" />

<!-- iPhone 15 Pro, 14 Pro -->
<link rel="apple-touch-startup-image"
      href="/splash-1179x2556.png"
      media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3)" />

<!-- iPhone 15, 15 Plus, 14, 14 Plus -->
<link rel="apple-touch-startup-image"
      href="/splash-1170x2532.png"
      media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3)" />

<!-- iPhone SE (3rd gen), 8, 7, 6s -->
<link rel="apple-touch-startup-image"
      href="/splash-750x1334.png"
      media="(device-width: 375px) and (device-height: 667px) and (-webkit-device-pixel-ratio: 2)" />

<!-- iPad Pro 12.9" -->
<link rel="apple-touch-startup-image"
      href="/splash-2048x2732.png"
      media="(device-width: 1024px) and (device-height: 1366px) and (-webkit-device-pixel-ratio: 2)" />

<!-- iPad Pro 11" -->
<link rel="apple-touch-startup-image"
      href="/splash-1668x2388.png"
      media="(device-width: 834px) and (device-height: 1194px) and (-webkit-device-pixel-ratio: 2)" />
```

### Splash Screen Generator Script

```typescript
// scripts/generate-splash.ts
import sharp from 'sharp';

const SPLASH_SIZES = [
  { width: 1290, height: 2796, name: 'splash-1290x2796.png' },
  { width: 1179, height: 2556, name: 'splash-1179x2556.png' },
  { width: 1170, height: 2532, name: 'splash-1170x2532.png' },
  { width: 750, height: 1334, name: 'splash-750x1334.png' },
  { width: 2048, height: 2732, name: 'splash-2048x2732.png' },
  { width: 1668, height: 2388, name: 'splash-1668x2388.png' },
];

async function generateSplashScreens(logoPath: string, backgroundColor: string) {
  for (const size of SPLASH_SIZES) {
    await sharp({
      create: {
        width: size.width,
        height: size.height,
        channels: 4,
        background: backgroundColor,
      },
    })
      .composite([
        {
          input: logoPath,
          gravity: 'center',
        },
      ])
      .png()
      .toFile(`public/${size.name}`);
  }
}
```

---

## 17. APP ICON REQUIREMENTS

### apple-touch-icon

```html
<!-- Primary icon (180x180 required) -->
<link rel="apple-touch-icon" href="/apple-touch-icon.png" />

<!-- Alternative sizes -->
<link rel="apple-touch-icon" sizes="152x152" href="/apple-touch-icon-152x152.png" />
<link rel="apple-touch-icon" sizes="167x167" href="/apple-touch-icon-167x167.png" />
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon-180x180.png" />
```

**Note:** iOS does NOT support maskable icons. Use a standard square icon with built-in padding.

---

## 18. FEATURE SUPPORT MATRIX

| Feature | iOS Safari | iOS PWA | Android Chrome |
|---------|-----------|---------|----------------|
| Storage Quota | 50MB | 50MB | Device dependent |
| Background Sync | No | No | Yes |
| Periodic Background Sync | No | No | Yes |
| Push Notifications | No | Yes (16.4+) | Yes |
| Badge API | No | No | Yes |
| File Handling | No | No | Yes |
| Window Controls Overlay | No | No | Yes |
| Service Worker | Yes | Yes* | Yes |
| Cache API | Yes | Yes | Yes |
| IndexedDB | Yes | Yes | Yes |
| Share Target | Yes | Yes | Yes |

*Service Worker may be terminated after ~3 days of inactivity

---

## 19. iOS PWA CHECKLIST

- [ ] Detect iOS and adjust features accordingly
- [ ] Implement storage cleanup for 50MB limit
- [ ] Use visibility-based sync instead of Background Sync
- [ ] Check SW health on app launch
- [ ] Store critical data redundantly
- [ ] Handle push notification limitations (iOS 16.4+, PWA only)
- [ ] Use in-app badges instead of app badges
- [ ] Implement Share Target as file handling alternative
- [ ] Add all apple-touch-startup-image sizes
- [ ] Include proper apple-touch-icon
- [ ] Set viewport-fit=cover for safe areas
- [ ] Use 16px minimum font for inputs
- [ ] Test in installed PWA mode, not Safari browser

---

## 20. VERIFICATION SEAL

```
OMEGA_v24.5.0 SINGULARITY FORGE | PWA_IOS_LIMITATIONS
Gates: 8 | Commands: 6 | Phase: 2.4
IOS_16_4_PUSH | 50MB_STORAGE | VISIBILITY_SYNC
RTL_FIRST: MANDATORY | RESPONSIVE: MANDATORY
```

<!-- PWA-EXPERT/IOS-LIMITS v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->

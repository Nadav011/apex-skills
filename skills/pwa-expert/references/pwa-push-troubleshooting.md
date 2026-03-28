# PWA Push Troubleshooting v24.5.0 SINGULARITY FORGE

> Comprehensive push notification debugging across browsers, platforms, and OEM-specific issues

---

## 1. PURPOSE

This skill provides complete troubleshooting for PWA push notifications:
- Permission denied recovery strategies
- iOS 16.4+ PWA-specific requirements
- Android OEM battery optimization workarounds (Xiaomi, Huawei, Samsung, etc.)
- VAPID key management and rotation
- WebView detection and user guidance
- Background data and network quality handling
- Complete debug dashboard implementation

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/push diagnose` | Run full push notification diagnostics | ~10s |
| `/push permission` | Check and guide permission recovery | ~5s |
| `/push ios-check` | Validate iOS 16.4+ PWA requirements | ~5s |
| `/push vapid-rotate` | Rotate VAPID keys and resubscribe users | ~5min |
| `/push oem-guide` | Generate OEM-specific battery settings guide | ~5s |
| `/push webview-detect` | Check if running in WebView and guide user | ~5s |
| `/push test-send` | Send test push notification | ~10s |
| `/push debug-dashboard` | Generate debug dashboard component | ~2min |

---

## 3. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-PUSH-1 | PERMISSION_GRANTED | `Notification.permission === 'granted'` | Permission obtained |
| G-PUSH-2 | SW_ACTIVE | `registration.active !== null` | Service worker active |
| G-PUSH-3 | SUBSCRIPTION_VALID | `pushManager.getSubscription()` | Valid subscription |
| G-PUSH-4 | VAPID_MATCH | Compare applicationServerKey | Keys match |
| G-PUSH-5 | CLICK_NAVIGATES | `event.waitUntil()` used | Click opens correct URL |
| G-PUSH-6 | IOS_PWA_MODE | `isIOSPWA() && iosVersion >= 16.4` | iOS requirements met |
| G-PUSH-7 | NOT_WEBVIEW | `!isWebView()` | Not in embedded browser |
| G-PUSH-8 | BATTERY_EXEMPT | OEM battery optimization disabled | Notifications arrive |

---

## 4. PERMISSION DENIED AFTER DISMISSAL

### Problem
User dismissed or denied the permission prompt. Chrome blocks re-prompting for 90 days.

### Detection
```typescript
async function checkNotificationPermission(): Promise<{
  status: 'granted' | 'denied' | 'default';
  canPrompt: boolean;
}> {
  if (!('Notification' in window)) {
    return { status: 'denied', canPrompt: false };
  }

  const permission = Notification.permission;

  return {
    status: permission,
    canPrompt: permission === 'default', // Only 'default' can be prompted
  };
}
```

### Solution: Custom Pre-Permission UI
```tsx
function PushPermissionRequest() {
  const [showPrompt, setShowPrompt] = useState(false);
  const [permissionState, setPermissionState] = useState<PermissionState>('prompt');

  useEffect(() => {
    // Check current state
    navigator.permissions?.query({ name: 'notifications' })
      .then(result => {
        setPermissionState(result.state);
        result.onchange = () => setPermissionState(result.state);
      });
  }, []);

  const requestPermission = async () => {
    const result = await Notification.requestPermission();
    if (result === 'granted') {
      await subscribeToPush();
    }
  };

  // Don't show if already granted or permanently denied
  if (permissionState === 'granted') return null;

  if (permissionState === 'denied') {
    return (
      <div className="p-4 bg-amber-50 rounded-lg">
        <p className="text-amber-800">
          Notifications are blocked. To enable:
        </p>
        <ol className="list-decimal ms-4 mt-2 text-sm text-amber-700">
          <li>Click the lock icon in the address bar</li>
          <li>Find "Notifications" setting</li>
          <li>Change to "Allow"</li>
          <li>Refresh the page</li>
        </ol>
      </div>
    );
  }

  // Show custom UI first, then browser prompt
  return (
    <div className="p-4 bg-blue-50 rounded-lg">
      <h3 className="font-medium">Enable Notifications</h3>
      <p className="text-sm text-gray-600 mt-1">
        Get instant updates when deliveries arrive or status changes.
      </p>
      <div className="flex gap-2 mt-3">
        <Button onClick={requestPermission}>Enable</Button>
        <Button variant="ghost" onClick={() => setShowPrompt(false)}>
          Not Now
        </Button>
      </div>
    </div>
  );
}
```

### Recovery: Guide User to Settings
```typescript
function getSettingsInstructions(userAgent: string): string {
  if (/Chrome/.test(userAgent)) {
    return 'Click the lock icon (left of URL) > Site settings > Notifications > Allow';
  }
  if (/Firefox/.test(userAgent)) {
    return 'Click the lock icon > Connection secure > More Information > Permissions > Notifications';
  }
  if (/Safari/.test(userAgent)) {
    return 'Safari > Settings for This Website > Notifications > Allow';
  }
  return 'Check your browser settings to enable notifications for this site.';
}
```

---

## 5. iOS PWA PUSH NOT WORKING

### Requirements
- iOS 16.4+ required
- **MUST** be installed as PWA (Add to Home Screen)
- Safari browser alone NEVER supports push
- Requires user interaction to request permission

### Detection Code
```typescript
interface IOSPushSupport {
  isIOS: boolean;
  isPWA: boolean;
  iOSVersion: number | null;
  supportsPush: boolean;
  reason: string;
}

function checkIOSPushSupport(): IOSPushSupport {
  const ua = navigator.userAgent;
  const isIOS = /iPad|iPhone|iPod/.test(ua) && !(window as any).MSStream;

  if (!isIOS) {
    return {
      isIOS: false,
      isPWA: false,
      iOSVersion: null,
      supportsPush: 'Notification' in window,
      reason: 'Not iOS device',
    };
  }

  // Extract iOS version
  const match = ua.match(/OS (\d+)_(\d+)/);
  const iOSVersion = match ? parseFloat(`${match[1]}.${match[2]}`) : null;

  // Check if running as installed PWA
  const isPWA =
    (window.navigator as any).standalone === true || // iOS Safari
    window.matchMedia('(display-mode: standalone)').matches;

  // Determine support
  let supportsPush = false;
  let reason = '';

  if (iOSVersion && iOSVersion < 16.4) {
    reason = `iOS ${iOSVersion} does not support push. Requires iOS 16.4+`;
  } else if (!isPWA) {
    reason = 'Must be installed as PWA (Add to Home Screen)';
    supportsPush = false;
  } else {
    reason = 'Push notifications supported';
    supportsPush = 'Notification' in window && 'PushManager' in window;
  }

  return { isIOS, isPWA, iOSVersion, supportsPush, reason };
}
```

### iOS PWA Install Prompt
```tsx
function IOSInstallPrompt() {
  const [showPrompt, setShowPrompt] = useState(false);
  const support = checkIOSPushSupport();

  useEffect(() => {
    // Show prompt if iOS but not PWA
    if (support.isIOS && !support.isPWA) {
      setShowPrompt(true);
    }
  }, []);

  if (!showPrompt) return null;

  return (
    <div className="fixed bottom-0 inset-s-0 inset-e-0 p-4 bg-white shadow-lg border-t z-50">
      <div className="flex items-start gap-3">
        <div className="p-2 bg-blue-100 rounded-lg">
          <ShareIcon className="w-6 h-6 text-blue-600" />
        </div>
        <div className="flex-1">
          <h3 className="font-medium">Install App</h3>
          <p className="text-sm text-gray-600 mt-1">
            To receive notifications, install this app:
          </p>
          <ol className="text-sm text-gray-600 mt-2 space-y-1">
            <li>1. Tap the Share button <ShareIcon className="inline w-4 h-4" /></li>
            <li>2. Scroll down and tap "Add to Home Screen"</li>
            <li>3. Tap "Add" to confirm</li>
          </ol>
        </div>
        <button onClick={() => setShowPrompt(false)}>
          <XIcon className="w-5 h-5 text-gray-400" />
        </button>
      </div>
    </div>
  );
}
```

---

## 6. NOTIFICATIONS DON'T APPEAR

### Diagnostic Checklist
```typescript
async function diagnoseNotificationIssues(): Promise<{
  issue: string;
  solution: string;
}[]> {
  const issues: { issue: string; solution: string }[] = [];

  // 1. Check API support
  if (!('Notification' in window)) {
    issues.push({
      issue: 'Notification API not supported',
      solution: 'Use a modern browser (Chrome, Firefox, Safari 16.4+)',
    });
  }

  // 2. Check permission
  if (Notification.permission !== 'granted') {
    issues.push({
      issue: `Permission is "${Notification.permission}"`,
      solution: Notification.permission === 'denied'
        ? 'User must enable in browser settings'
        : 'Request permission with Notification.requestPermission()',
    });
  }

  // 3. Check service worker
  if (!('serviceWorker' in navigator)) {
    issues.push({
      issue: 'Service Worker not supported',
      solution: 'Use HTTPS and a modern browser',
    });
  } else {
    const registration = await navigator.serviceWorker.getRegistration();
    if (!registration) {
      issues.push({
        issue: 'Service Worker not registered',
        solution: 'Register SW: navigator.serviceWorker.register("/sw.js")',
      });
    } else if (!registration.active) {
      issues.push({
        issue: 'Service Worker not active',
        solution: 'Wait for SW activation or reload page',
      });
    }
  }

  // 4. Check push subscription
  if ('PushManager' in window) {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.getSubscription();
    if (!subscription) {
      issues.push({
        issue: 'No push subscription',
        solution: 'Subscribe with pushManager.subscribe()',
      });
    }
  }

  // 5. Check if browser is focused (notifications may be suppressed)
  if (document.visibilityState === 'visible') {
    issues.push({
      issue: 'Page is in foreground',
      solution: 'Use requireInteraction: true or handle in-app notifications',
    });
  }

  return issues;
}
```

### VAPID Key Mismatch Detection
```typescript
async function validateVAPIDSubscription(
  expectedPublicKey: string
): Promise<{ valid: boolean; error?: string }> {
  try {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.getSubscription();

    if (!subscription) {
      return { valid: false, error: 'No subscription found' };
    }

    // Get the key from existing subscription
    const subscriptionKey = subscription.options?.applicationServerKey;
    if (!subscriptionKey) {
      return { valid: false, error: 'Subscription has no applicationServerKey' };
    }

    // Convert expected key to same format
    const expectedKeyBuffer = urlBase64ToUint8Array(expectedPublicKey);
    const subscriptionKeyArray = new Uint8Array(subscriptionKey as ArrayBuffer);

    // Compare keys
    if (expectedKeyBuffer.length !== subscriptionKeyArray.length) {
      return { valid: false, error: 'VAPID key length mismatch - resubscribe required' };
    }

    for (let i = 0; i < expectedKeyBuffer.length; i++) {
      if (expectedKeyBuffer[i] !== subscriptionKeyArray[i]) {
        return { valid: false, error: 'VAPID key mismatch - resubscribe required' };
      }
    }

    return { valid: true };
  } catch (error) {
    return { valid: false, error: String(error) };
  }
}

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/-/g, '+')
    .replace(/_/g, '/');
  const rawData = window.atob(base64);
  return Uint8Array.from(rawData, char => char.charCodeAt(0));
}
```

### Force Notification Visibility
```typescript
// In service worker (sw.js)
self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};

  const options: NotificationOptions = {
    body: data.body || 'New notification',
    icon: '/icon-192.png',
    badge: '/badge-72.png',
    tag: data.tag || 'default',

    // CRITICAL: Force notification to stay visible
    requireInteraction: true,

    // Vibrate pattern (mobile)
    vibrate: [200, 100, 200],

    // Data for click handling
    data: {
      url: data.url || '/',
      timestamp: Date.now(),
    },

    // Actions (Android/Desktop)
    actions: data.actions || [],
  };

  event.waitUntil(
    self.registration.showNotification(data.title || 'Notification', options)
  );
});
```

---

## 7. CLICK DOESN'T NAVIGATE

### Problem
Clicking notification doesn't open the app or navigate to correct URL.

### Common Mistakes
1. Not using `event.waitUntil()`
2. URL not in service worker scope
3. Not properly focusing existing client

### Correct Implementation
```typescript
// In service worker (sw.js)
self.addEventListener('notificationclick', (event) => {
  // Close the notification
  event.notification.close();

  // Get target URL
  const targetUrl = event.notification.data?.url || '/';
  const urlToOpen = new URL(targetUrl, self.location.origin).href;

  // CRITICAL: Use waitUntil to keep SW alive
  event.waitUntil(
    (async () => {
      // Get all window clients
      const clientList = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });

      // Check if app is already open
      for (const client of clientList) {
        const clientUrl = new URL(client.url);

        // If we find a matching client, focus it and navigate
        if (clientUrl.origin === self.location.origin) {
          await client.focus();

          // Navigate to target URL if different
          if (client.url !== urlToOpen) {
            await client.navigate(urlToOpen);
          }
          return;
        }
      }

      // No existing window, open new one
      await self.clients.openWindow(urlToOpen);
    })()
  );
});

// Handle action buttons
self.addEventListener('notificationclick', (event) => {
  if (event.action) {
    // Handle specific action
    switch (event.action) {
      case 'view':
        event.waitUntil(
          self.clients.openWindow(event.notification.data?.url || '/')
        );
        break;
      case 'dismiss':
        // Just close, already handled above
        break;
      case 'reply':
        // Handle inline reply (if supported)
        const reply = event.reply;
        if (reply) {
          event.waitUntil(
            sendReplyToServer(event.notification.data?.id, reply)
          );
        }
        break;
    }
  }

  event.notification.close();
});
```

### Scope Issues
```typescript
// Check if URL is within scope
function isUrlInScope(url: string, scope: string): boolean {
  try {
    const urlObj = new URL(url, self.location.origin);
    const scopeObj = new URL(scope, self.location.origin);
    return urlObj.pathname.startsWith(scopeObj.pathname);
  } catch {
    return false;
  }
}

// In notification click handler
const targetUrl = event.notification.data?.url || '/';
const swScope = self.registration.scope;

if (!isUrlInScope(targetUrl, swScope)) {
  console.warn(`URL ${targetUrl} is outside SW scope ${swScope}`);
  // For external URLs, use openWindow directly
  await self.clients.openWindow(targetUrl);
  return;
}
```

---

## 8. BADGE NOT UPDATING

### Badge API Support Check
```typescript
function isBadgeSupported(): boolean {
  return 'setAppBadge' in navigator && 'clearAppBadge' in navigator;
}

async function updateBadge(count: number): Promise<void> {
  if (!isBadgeSupported()) {
    console.log('Badge API not supported');
    return;
  }

  try {
    if (count > 0) {
      await navigator.setAppBadge(count);
    } else {
      await navigator.clearAppBadge();
    }
  } catch (error) {
    // Badge API may fail silently in some contexts
    console.warn('Failed to update badge:', error);
  }
}
```

### Clear Badge on App Open
```typescript
// In main app entry point
useEffect(() => {
  // Clear badge when app becomes visible
  const handleVisibilityChange = () => {
    if (document.visibilityState === 'visible') {
      navigator.clearAppBadge?.();
    }
  };

  document.addEventListener('visibilitychange', handleVisibilityChange);

  // Also clear on initial load
  navigator.clearAppBadge?.();

  return () => {
    document.removeEventListener('visibilitychange', handleVisibilityChange);
  };
}, []);
```

### Service Worker Badge Update
```typescript
// In service worker - update badge with push
self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};

  event.waitUntil(
    (async () => {
      // Show notification
      await self.registration.showNotification(data.title, {
        body: data.body,
        // ... other options
      });

      // Update badge count
      if (data.badgeCount !== undefined) {
        try {
          await navigator.setAppBadge(data.badgeCount);
        } catch (e) {
          // Ignore badge errors
        }
      }
    })()
  );
});
```

### iOS Badge Limitation
```typescript
// iOS does not support Badge API for PWAs
// Use in-app badge indicators instead

function BadgeIndicator({ count }: { count: number }) {
  if (count === 0) return null;

  return (
    <span className="absolute -top-1 -inset-e-1 min-w-5 h-5 flex items-center justify-center rounded-full bg-red-500 text-white text-xs font-medium">
      <span dir="ltr">{count > 99 ? '99+' : count}</span>
    </span>
  );
}
```

---

## 9. SILENT PUSH FAILS

### Data-Only Push Requirements
```typescript
// Silent push (data-only) has strict requirements:
// 1. Must show notification within ~30 seconds
// 2. Quota limits apply (varies by browser)
// 3. May be throttled if app not used recently

self.addEventListener('push', (event) => {
  const data = event.data?.json() ?? {};

  if (data.silent) {
    // Silent push - sync data without showing notification
    event.waitUntil(
      (async () => {
        try {
          // Perform background sync
          await syncDataInBackground(data);

          // IMPORTANT: Chrome may still require showing a notification
          // Check if we've exceeded silent push quota
          if (shouldShowNotification()) {
            await self.registration.showNotification('Sync complete', {
              body: 'Data updated in background',
              silent: true, // No sound
              tag: 'background-sync',
            });
          }
        } catch (error) {
          console.error('Silent push failed:', error);
        }
      })()
    );
  } else {
    // Regular push - show notification
    event.waitUntil(
      self.registration.showNotification(data.title, {
        body: data.body,
        // ... options
      })
    );
  }
});
```

### Background Sync Alternative
```typescript
// Use Background Sync API for more reliable data sync
// This is triggered when network is available

// Register sync
async function requestBackgroundSync(tag: string): Promise<void> {
  const registration = await navigator.serviceWorker.ready;

  if ('sync' in registration) {
    await registration.sync.register(tag);
  } else {
    // Fallback: sync immediately
    await performSync(tag);
  }
}

// In service worker
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-deliveries') {
    event.waitUntil(syncDeliveries());
  }
});

async function syncDeliveries(): Promise<void> {
  // Get pending operations from IndexedDB
  const pending = await getPendingOperations();

  for (const op of pending) {
    try {
      await sendToServer(op);
      await markAsCompleted(op.id);
    } catch (error) {
      // Will retry on next sync
      throw error;
    }
  }
}
```

### Quota Limitations
```typescript
// Check push quota (not widely supported)
async function checkPushQuota(): Promise<{
  used: number;
  remaining: number;
} | null> {
  try {
    const registration = await navigator.serviceWorker.ready;

    // Note: This is experimental and not widely supported
    if ('getNotifications' in registration) {
      const notifications = await registration.getNotifications();
      return {
        used: notifications.length,
        remaining: 50 - notifications.length, // Approximate limit
      };
    }
  } catch {
    return null;
  }
  return null;
}
```

---

## 10. VAPID KEY ISSUES

### Key Rotation Procedure
```typescript
// Server-side: Generate new VAPID keys
import webpush from 'web-push';

const vapidKeys = webpush.generateVAPIDKeys();
console.log('Public Key:', vapidKeys.publicKey);
console.log('Private Key:', vapidKeys.privateKey);

// Store these securely:
// - Public key: Can be in client code
// - Private key: MUST be in environment variables only
```

### Re-subscription After Key Change
```typescript
async function resubscribeWithNewKey(newPublicKey: string): Promise<PushSubscription | null> {
  try {
    const registration = await navigator.serviceWorker.ready;

    // Unsubscribe from old subscription
    const oldSubscription = await registration.pushManager.getSubscription();
    if (oldSubscription) {
      await oldSubscription.unsubscribe();

      // Notify server to remove old subscription
      await fetch('/api/push/unsubscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ endpoint: oldSubscription.endpoint }),
      });
    }

    // Subscribe with new key
    const newSubscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(newPublicKey),
    });

    // Send new subscription to server
    await fetch('/api/push/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(newSubscription.toJSON()),
    });

    return newSubscription;
  } catch (error) {
    console.error('Resubscription failed:', error);
    return null;
  }
}
```

### Migration Strategy
```typescript
// Store VAPID public key version in subscription metadata
interface SubscriptionMetadata {
  endpoint: string;
  vapidKeyVersion: number;
  createdAt: string;
}

// Check and migrate on app load
async function checkVAPIDMigration(): Promise<void> {
  const CURRENT_VAPID_VERSION = 2; // Increment when rotating keys

  const storedVersion = localStorage.getItem('vapidKeyVersion');

  if (storedVersion && parseInt(storedVersion) < CURRENT_VAPID_VERSION) {
    console.log('VAPID key rotated, resubscribing...');

    const newSubscription = await resubscribeWithNewKey(
      import.meta.env.VITE_VAPID_PUBLIC_KEY
    );

    if (newSubscription) {
      localStorage.setItem('vapidKeyVersion', String(CURRENT_VAPID_VERSION));
    }
  }
}
```

---

## 11. SUBSCRIPTION TIMEOUT

### Retry with Exponential Backoff
```typescript
interface RetryConfig {
  maxAttempts: number;
  baseDelayMs: number;
  maxDelayMs: number;
}

async function subscribeWithRetry(
  publicKey: string,
  config: RetryConfig = { maxAttempts: 5, baseDelayMs: 1000, maxDelayMs: 30000 }
): Promise<PushSubscription | null> {
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= config.maxAttempts; attempt++) {
    try {
      const registration = await navigator.serviceWorker.ready;

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(publicKey),
      });

      console.log(`Push subscription successful on attempt ${attempt}`);
      return subscription;
    } catch (error) {
      lastError = error as Error;
      console.warn(`Push subscription attempt ${attempt} failed:`, error);

      if (attempt < config.maxAttempts) {
        // Calculate delay with exponential backoff + jitter
        const delay = Math.min(
          config.baseDelayMs * Math.pow(2, attempt - 1) + Math.random() * 1000,
          config.maxDelayMs
        );

        console.log(`Retrying in ${Math.round(delay)}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  console.error('Push subscription failed after all attempts:', lastError);
  return null;
}
```

### Network Issue Detection
```typescript
async function checkPushServiceReachability(): Promise<{
  reachable: boolean;
  error?: string;
}> {
  // Check basic connectivity
  if (!navigator.onLine) {
    return { reachable: false, error: 'Device is offline' };
  }

  // Try to reach push service endpoints
  const endpoints = [
    'https://fcm.googleapis.com', // Firebase/Chrome
    'https://updates.push.services.mozilla.com', // Firefox
  ];

  for (const endpoint of endpoints) {
    try {
      const response = await fetch(endpoint, {
        method: 'HEAD',
        mode: 'no-cors',
        cache: 'no-store',
      });
      // no-cors means we can't read response, but no error = reachable
      return { reachable: true };
    } catch {
      // Try next endpoint
    }
  }

  return { reachable: false, error: 'Push services unreachable' };
}
```

---

## 12. ANDROID LEGACY ISSUES (Pre-Android 13)

### Battery Optimization Killing Push

Android aggressively kills background processes to save battery. This can prevent push notifications from being delivered.

### Detection
```typescript
interface BatteryOptimizationStatus {
  isExempt: boolean;
  canRequest: boolean;
  manufacturer: string;
}

async function checkBatteryOptimization(): Promise<BatteryOptimizationStatus> {
  const ua = navigator.userAgent.toLowerCase();

  // Detect manufacturer
  let manufacturer = 'unknown';
  if (ua.includes('xiaomi') || ua.includes('redmi') || ua.includes('poco')) {
    manufacturer = 'xiaomi';
  } else if (ua.includes('huawei') || ua.includes('honor')) {
    manufacturer = 'huawei';
  } else if (ua.includes('samsung') || ua.includes('sm-')) {
    manufacturer = 'samsung';
  } else if (ua.includes('oppo')) {
    manufacturer = 'oppo';
  } else if (ua.includes('vivo')) {
    manufacturer = 'vivo';
  } else if (ua.includes('oneplus')) {
    manufacturer = 'oneplus';
  }

  // Note: Web APIs cannot check battery optimization status
  // This requires native Capacitor plugin
  return {
    isExempt: false, // Assume not exempt
    canRequest: true,
    manufacturer,
  };
}
```

### Capacitor Battery Optimization Check
```typescript
import { Capacitor } from '@capacitor/core';

// Custom plugin for battery optimization
// Requires native Android code
interface BatteryOptimizationPlugin {
  isIgnoringBatteryOptimizations(): Promise<{ isIgnoring: boolean }>;
  requestIgnoreBatteryOptimizations(): Promise<{ success: boolean }>;
}

async function handleBatteryOptimization(): Promise<void> {
  if (Capacitor.getPlatform() !== 'android') return;

  try {
    // This requires a custom Capacitor plugin
    const BatteryOptimization = (window as any).Capacitor?.Plugins?.BatteryOptimization as BatteryOptimizationPlugin;

    if (!BatteryOptimization) {
      console.log('BatteryOptimization plugin not available');
      return;
    }

    const { isIgnoring } = await BatteryOptimization.isIgnoringBatteryOptimizations();

    if (!isIgnoring) {
      // Request to disable battery optimization
      await BatteryOptimization.requestIgnoreBatteryOptimizations();
    }
  } catch (error) {
    console.warn('Battery optimization check failed:', error);
  }
}
```

---

## 13. OEM-SPECIFIC PUSH ISSUES

### Problem
Chinese OEMs (Xiaomi, Huawei, Oppo, Vivo, OnePlus) have aggressive battery management that kills background apps and blocks push notifications.

### OEM-Specific Settings Detection
```typescript
interface OEMSettings {
  manufacturer: string;
  settingsPath: string;
  hebrewInstructions: string;
  englishInstructions: string;
}

function getOEMSettings(userAgent: string): OEMSettings | null {
  const ua = userAgent.toLowerCase();

  // Xiaomi / Redmi / POCO
  if (ua.includes('xiaomi') || ua.includes('redmi') || ua.includes('poco') || ua.includes('miui')) {
    return {
      manufacturer: 'Xiaomi',
      settingsPath: 'Settings > Apps > Manage apps > [App] > Battery saver > No restrictions',
      hebrewInstructions: `
כדי לקבל התראות ב-Xiaomi:
1. פתח הגדרות > אפליקציות > נהל אפליקציות
2. מצא את האפליקציה שלנו
3. לחץ על "חיסכון בסוללה"
4. בחר "ללא הגבלות"
5. חזור והפעל "הפעלה אוטומטית"
      `.trim(),
      englishInstructions: `
To receive notifications on Xiaomi:
1. Open Settings > Apps > Manage apps
2. Find our app
3. Tap "Battery saver"
4. Select "No restrictions"
5. Go back and enable "Autostart"
      `.trim(),
    };
  }

  // Huawei / Honor
  if (ua.includes('huawei') || ua.includes('honor') || ua.includes('emui')) {
    return {
      manufacturer: 'Huawei',
      settingsPath: 'Settings > Battery > App launch > [App] > Manage manually',
      hebrewInstructions: `
כדי לקבל התראות ב-Huawei:
1. פתח הגדרות > סוללה > הפעלת אפליקציה
2. מצא את האפליקציה שלנו
3. כבה את "נהל אוטומטית"
4. הפעל את כל שלוש האפשרויות:
   - הפעלה אוטומטית
   - הפעלה משנית
   - פעילות ברקע
      `.trim(),
      englishInstructions: `
To receive notifications on Huawei:
1. Open Settings > Battery > App launch
2. Find our app
3. Turn off "Manage automatically"
4. Enable all three options:
   - Auto-launch
   - Secondary launch
   - Run in background
      `.trim(),
    };
  }

  // Samsung
  if (ua.includes('samsung') || ua.includes('sm-')) {
    return {
      manufacturer: 'Samsung',
      settingsPath: 'Settings > Apps > [App] > Battery > Unrestricted',
      hebrewInstructions: `
כדי לקבל התראות ב-Samsung:
1. פתח הגדרות > אפליקציות
2. מצא את האפליקציה שלנו
3. לחץ על "סוללה"
4. בחר "ללא הגבלות"
5. בנוסף: הגדרות > טיפול במכשיר > סוללה > הגדרות נוספות
6. כבה את "אופטימיזציה אדפטיבית של סוללה"
      `.trim(),
      englishInstructions: `
To receive notifications on Samsung:
1. Open Settings > Apps
2. Find our app
3. Tap "Battery"
4. Select "Unrestricted"
5. Also: Settings > Device care > Battery > More settings
6. Disable "Adaptive battery optimization"
      `.trim(),
    };
  }

  // Oppo / Realme
  if (ua.includes('oppo') || ua.includes('realme') || ua.includes('coloros')) {
    return {
      manufacturer: 'Oppo',
      settingsPath: 'Settings > Battery > [App] > Allow background activity',
      hebrewInstructions: `
כדי לקבל התראות ב-Oppo:
1. פתח הגדרות > סוללה
2. מצא את האפליקציה שלנו
3. הפעל "אפשר פעילות ברקע"
4. בנוסף: הגדרות > ניהול אפליקציות > [אפליקציה]
5. הפעל "הפעלה אוטומטית"
      `.trim(),
      englishInstructions: `
To receive notifications on Oppo:
1. Open Settings > Battery
2. Find our app
3. Enable "Allow background activity"
4. Also: Settings > App Management > [App]
5. Enable "Auto-start"
      `.trim(),
    };
  }

  // Vivo
  if (ua.includes('vivo')) {
    return {
      manufacturer: 'Vivo',
      settingsPath: 'Settings > Battery > High background power consumption',
      hebrewInstructions: `
כדי לקבל התראות ב-Vivo:
1. פתח הגדרות > סוללה
2. לחץ על "צריכת אנרגיה גבוהה ברקע"
3. מצא את האפליקציה שלנו והפעל אותה
4. בנוסף: הגדרות > עוד הגדרות > ניהול הרשאות > הפעלה אוטומטית
5. הפעל את האפליקציה שלנו
      `.trim(),
      englishInstructions: `
To receive notifications on Vivo:
1. Open Settings > Battery
2. Tap "High background power consumption"
3. Find our app and enable it
4. Also: Settings > More settings > Permission management > Autostart
5. Enable our app
      `.trim(),
    };
  }

  // OnePlus
  if (ua.includes('oneplus')) {
    return {
      manufacturer: 'OnePlus',
      settingsPath: 'Settings > Battery > Battery optimization > [App] > Don\'t optimize',
      hebrewInstructions: `
כדי לקבל התראות ב-OnePlus:
1. פתח הגדרות > סוללה > אופטימיזציית סוללה
2. לחץ על הנקודות בפינה ובחר "כל האפליקציות"
3. מצא את האפליקציה שלנו
4. בחר "לא לבצע אופטימיזציה"
      `.trim(),
      englishInstructions: `
To receive notifications on OnePlus:
1. Open Settings > Battery > Battery optimization
2. Tap the dots in corner and select "All apps"
3. Find our app
4. Select "Don't optimize"
      `.trim(),
    };
  }

  return null;
}
```

### OEM Settings UI Component
```tsx
function OEMPushSettingsGuide() {
  const [oemSettings, setOemSettings] = useState<OEMSettings | null>(null);
  const [language, setLanguage] = useState<'he' | 'en'>('he');

  useEffect(() => {
    const settings = getOEMSettings(navigator.userAgent);
    setOemSettings(settings);

    // Detect language from document
    setLanguage(document.documentElement.lang === 'he' ? 'he' : 'en');
  }, []);

  if (!oemSettings) return null;

  const instructions = language === 'he'
    ? oemSettings.hebrewInstructions
    : oemSettings.englishInstructions;

  return (
    <div className="p-4 bg-amber-50 rounded-lg border border-amber-200">
      <div className="flex items-start gap-3">
        <AlertTriangleIcon className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
        <div className="flex-1">
          <h3 className="font-medium text-amber-900">
            {language === 'he'
              ? `הגדרות נדרשות ל-${oemSettings.manufacturer}`
              : `Required settings for ${oemSettings.manufacturer}`}
          </h3>
          <pre className="mt-2 text-sm text-amber-800 whitespace-pre-wrap font-sans">
            {instructions}
          </pre>
        </div>
      </div>
    </div>
  );
}
```

### dontkillmyapp.com Integration
```typescript
// Reference: https://dontkillmyapp.com/
// This site tracks OEM-specific battery optimization issues

const DONT_KILL_MY_APP_URLS: Record<string, string> = {
  xiaomi: 'https://dontkillmyapp.com/xiaomi',
  huawei: 'https://dontkillmyapp.com/huawei',
  samsung: 'https://dontkillmyapp.com/samsung',
  oppo: 'https://dontkillmyapp.com/oppo',
  vivo: 'https://dontkillmyapp.com/vivo',
  oneplus: 'https://dontkillmyapp.com/oneplus',
  realme: 'https://dontkillmyapp.com/realme',
  nokia: 'https://dontkillmyapp.com/nokia',
};

function getDontKillMyAppUrl(userAgent: string): string | null {
  const ua = userAgent.toLowerCase();

  for (const [brand, url] of Object.entries(DONT_KILL_MY_APP_URLS)) {
    if (ua.includes(brand)) {
      return url;
    }
  }

  return null;
}
```

---

## 14. WEBVIEW PUSH LIMITATIONS

### Problem
Push notifications do NOT work in WebViews (in-app browsers). This affects:
- Facebook/Instagram in-app browser
- Twitter/X in-app browser
- LinkedIn in-app browser
- Any custom WebView (android.webkit.WebView)

### Detection
```typescript
interface WebViewInfo {
  isWebView: boolean;
  type: 'facebook' | 'instagram' | 'twitter' | 'linkedin' | 'generic' | 'browser';
  supportsPush: boolean;
  hebrewMessage: string;
  englishMessage: string;
}

function detectWebView(): WebViewInfo {
  const ua = navigator.userAgent.toLowerCase();
  const standalone = (window.navigator as any).standalone;

  // Check for specific in-app browsers
  if (ua.includes('fban') || ua.includes('fbav')) {
    return {
      isWebView: true,
      type: 'facebook',
      supportsPush: false,
      hebrewMessage: 'פתח את האפליקציה בדפדפן רגיל (Chrome/Safari) כדי לקבל התראות. לחץ על ... ובחר "פתח בדפדפן".',
      englishMessage: 'Open the app in a regular browser (Chrome/Safari) to receive notifications. Tap ... and select "Open in Browser".',
    };
  }

  if (ua.includes('instagram')) {
    return {
      isWebView: true,
      type: 'instagram',
      supportsPush: false,
      hebrewMessage: 'פתח את הקישור בדפדפן רגיל. לחץ על ... ובחר "פתח בדפדפן חיצוני".',
      englishMessage: 'Open the link in a regular browser. Tap ... and select "Open in external browser".',
    };
  }

  if (ua.includes('twitter') || ua.includes(' x/')) {
    return {
      isWebView: true,
      type: 'twitter',
      supportsPush: false,
      hebrewMessage: 'לחץ על הקישור והעתק אותו לדפדפן רגיל כדי לקבל התראות.',
      englishMessage: 'Copy the link and open it in a regular browser to receive notifications.',
    };
  }

  if (ua.includes('linkedin')) {
    return {
      isWebView: true,
      type: 'linkedin',
      supportsPush: false,
      hebrewMessage: 'פתח את האתר בדפדפן רגיל כדי להפעיל התראות.',
      englishMessage: 'Open the site in a regular browser to enable notifications.',
    };
  }

  // Generic WebView detection
  // Android WebView
  const isAndroidWebView = ua.includes('wv') ||
    (ua.includes('android') && ua.includes('version/'));

  // iOS WebView (not Safari or Chrome)
  const isIOSWebView = /iphone|ipad|ipod/.test(ua) &&
    !ua.includes('safari') &&
    !standalone;

  if (isAndroidWebView || isIOSWebView) {
    return {
      isWebView: true,
      type: 'generic',
      supportsPush: false,
      hebrewMessage: 'האתר פתוח בדפדפן מוטמע. פתח ב-Chrome או Safari כדי לקבל התראות.',
      englishMessage: 'Site is open in embedded browser. Open in Chrome or Safari to receive notifications.',
    };
  }

  // Regular browser
  return {
    isWebView: false,
    type: 'browser',
    supportsPush: 'Notification' in window && 'PushManager' in window,
    hebrewMessage: '',
    englishMessage: '',
  };
}
```

### WebView Warning Component
```tsx
function WebViewWarning() {
  const [webViewInfo, setWebViewInfo] = useState<WebViewInfo | null>(null);
  const language = document.documentElement.lang === 'he' ? 'he' : 'en';

  useEffect(() => {
    const info = detectWebView();
    if (info.isWebView) {
      setWebViewInfo(info);
    }
  }, []);

  if (!webViewInfo) return null;

  const message = language === 'he'
    ? webViewInfo.hebrewMessage
    : webViewInfo.englishMessage;

  return (
    <div className="fixed bottom-0 inset-s-0 inset-e-0 p-4 bg-blue-600 text-white z-50">
      <div className="flex items-start gap-3">
        <ExternalLinkIcon className="w-5 h-5 flex-shrink-0 mt-0.5" />
        <div className="flex-1">
          <p className="text-sm">{message}</p>
          <button
            onClick={() => {
              // Copy current URL to clipboard
              navigator.clipboard?.writeText(window.location.href);
            }}
            className="mt-2 text-xs underline"
          >
            {language === 'he' ? 'העתק קישור' : 'Copy link'}
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## 15. BACKGROUND DATA RESTRICTIONS

### Problem
Android allows users to restrict background data per-app, which blocks push notifications.

### Detection (Capacitor)
```typescript
// Check network status and connection type
async function checkBackgroundDataStatus(): Promise<{
  online: boolean;
  connectionType: string;
  saveData: boolean;
  effectiveType: string;
}> {
  const connection = (navigator as any).connection ||
                     (navigator as any).mozConnection ||
                     (navigator as any).webkitConnection;

  return {
    online: navigator.onLine,
    connectionType: connection?.type || 'unknown',
    saveData: connection?.saveData || false,
    effectiveType: connection?.effectiveType || 'unknown',
  };
}

// Monitor for connection changes
function useNetworkStatus() {
  const [status, setStatus] = useState(() => ({
    online: navigator.onLine,
    saveData: false,
  }));

  useEffect(() => {
    const connection = (navigator as any).connection;

    const updateStatus = () => {
      setStatus({
        online: navigator.onLine,
        saveData: connection?.saveData || false,
      });
    };

    window.addEventListener('online', updateStatus);
    window.addEventListener('offline', updateStatus);
    connection?.addEventListener('change', updateStatus);

    return () => {
      window.removeEventListener('online', updateStatus);
      window.removeEventListener('offline', updateStatus);
      connection?.removeEventListener('change', updateStatus);
    };
  }, []);

  return status;
}
```

### Background Data Warning
```tsx
function BackgroundDataWarning() {
  const { online, saveData } = useNetworkStatus();
  const language = document.documentElement.lang === 'he' ? 'he' : 'en';

  if (online && !saveData) return null;

  const messages = {
    offline: {
      he: 'אין חיבור לאינטרנט. התראות יתקבלו כשהחיבור יחזור.',
      en: 'No internet connection. Notifications will arrive when connection is restored.',
    },
    saveData: {
      he: 'מצב חיסכון בנתונים פעיל. התראות עלולות להתעכב.',
      en: 'Data saver mode is active. Notifications may be delayed.',
    },
  };

  const message = !online
    ? messages.offline[language]
    : messages.saveData[language];

  return (
    <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-800">
      <div className="flex items-center gap-2">
        <WifiOffIcon className="w-4 h-4" />
        <span>{message}</span>
      </div>
    </div>
  );
}
```

---

## 16. ANDROID 13+ PERMISSION

### Runtime Permission Required
Starting with Android 13 (API 33), `POST_NOTIFICATIONS` permission must be requested at runtime.

### Capacitor Implementation
```typescript
import { LocalNotifications } from '@capacitor/local-notifications';
import { PushNotifications } from '@capacitor/push-notifications';
import { Capacitor } from '@capacitor/core';

async function requestAndroidNotificationPermission(): Promise<boolean> {
  if (!Capacitor.isNativePlatform()) {
    // Web platform - use standard API
    const result = await Notification.requestPermission();
    return result === 'granted';
  }

  // Check current status
  let permStatus = await PushNotifications.checkPermissions();

  if (permStatus.receive === 'prompt') {
    // Request permission
    permStatus = await PushNotifications.requestPermissions();
  }

  if (permStatus.receive !== 'granted') {
    // Permission denied - guide user to settings
    console.log('Push notification permission denied');
    return false;
  }

  // Register for push
  await PushNotifications.register();
  return true;
}
```

### Best Practices for Timing
```typescript
function useNotificationPermission() {
  const [status, setStatus] = useState<'prompt' | 'granted' | 'denied'>('prompt');
  const [hasInteracted, setHasInteracted] = useState(false);

  // Check on mount
  useEffect(() => {
    PushNotifications.checkPermissions().then(result => {
      setStatus(result.receive as 'prompt' | 'granted' | 'denied');
    });
  }, []);

  // Request after meaningful user interaction
  const requestPermission = async () => {
    // Don't request if already decided
    if (status !== 'prompt') return status === 'granted';

    // Don't request on first app open - wait for engagement
    if (!hasInteracted) {
      console.log('Waiting for user engagement before requesting permission');
      return false;
    }

    const granted = await requestAndroidNotificationPermission();
    setStatus(granted ? 'granted' : 'denied');
    return granted;
  };

  const markInteraction = () => setHasInteracted(true);

  return { status, requestPermission, markInteraction };
}

// Usage: Request after user completes key action
function DeliveryCreatedSuccess() {
  const { requestPermission, markInteraction } = useNotificationPermission();

  useEffect(() => {
    // User just created a delivery - good time to ask
    markInteraction();

    // Show permission request after success message
    const timer = setTimeout(() => {
      requestPermission();
    }, 2000);

    return () => clearTimeout(timer);
  }, []);

  return <SuccessMessage />;
}
```

---

## 17. DEBUG TOOLS

### Chrome DevTools Application Tab
```typescript
// Debug utilities to run in console

// Check service worker status
async function debugServiceWorker() {
  const registrations = await navigator.serviceWorker.getRegistrations();
  console.table(registrations.map(r => ({
    scope: r.scope,
    active: !!r.active,
    waiting: !!r.waiting,
    installing: !!r.installing,
  })));
}

// Check push subscription
async function debugPushSubscription() {
  const reg = await navigator.serviceWorker.ready;
  const sub = await reg.pushManager.getSubscription();

  if (sub) {
    console.log('Subscription:', {
      endpoint: sub.endpoint,
      expirationTime: sub.expirationTime,
      keys: sub.toJSON().keys,
    });
  } else {
    console.log('No push subscription');
  }
}

// Test local notification
async function testNotification() {
  const reg = await navigator.serviceWorker.ready;
  await reg.showNotification('Test Notification', {
    body: 'This is a test notification',
    icon: '/icon-192.png',
    tag: 'test',
    data: { url: '/' },
  });
}
```

### Push API Testing
```typescript
// Test push from server (Node.js)
import webpush from 'web-push';

webpush.setVapidDetails(
  'mailto:admin@example.com',
  process.env.VAPID_PUBLIC_KEY!,
  process.env.VAPID_PRIVATE_KEY!
);

async function sendTestPush(subscription: PushSubscription) {
  try {
    const result = await webpush.sendNotification(
      subscription,
      JSON.stringify({
        title: 'Test Push',
        body: 'Push notification is working!',
        url: '/',
      })
    );
    console.log('Push sent:', result);
  } catch (error) {
    console.error('Push failed:', error);

    // Check error type
    if ((error as any).statusCode === 410) {
      console.log('Subscription expired - remove from database');
    } else if ((error as any).statusCode === 404) {
      console.log('Subscription not found - remove from database');
    }
  }
}
```

### Service Worker Console Logging
```typescript
// In service worker (sw.js)
// Add detailed logging for debugging

self.addEventListener('push', (event) => {
  console.group('Push Event');
  console.log('Timestamp:', new Date().toISOString());
  console.log('Has data:', !!event.data);

  if (event.data) {
    try {
      const json = event.data.json();
      console.log('Data:', json);
    } catch {
      console.log('Text:', event.data.text());
    }
  }
  console.groupEnd();

  // ... handle push
});

self.addEventListener('notificationclick', (event) => {
  console.group('Notification Click');
  console.log('Action:', event.action || '(none)');
  console.log('Tag:', event.notification.tag);
  console.log('Data:', event.notification.data);
  console.groupEnd();

  // ... handle click
});

// Log unhandled errors
self.addEventListener('error', (event) => {
  console.error('SW Error:', event.error);
});

self.addEventListener('unhandledrejection', (event) => {
  console.error('SW Unhandled Rejection:', event.reason);
});
```

### Complete Debug Dashboard
```tsx
function PushDebugDashboard() {
  const [diagnostics, setDiagnostics] = useState<PushDiagnostics | null>(null);

  const runDiagnostics = async () => {
    const results = {
      browser: navigator.userAgent,
      notificationSupport: 'Notification' in window,
      pushManagerSupport: 'PushManager' in window,
      serviceWorkerSupport: 'serviceWorker' in navigator,
      permission: Notification.permission,
      online: navigator.onLine,
      ios: checkIOSPushSupport(),
      swRegistration: null as ServiceWorkerRegistration | null,
      pushSubscription: null as PushSubscription | null,
      issues: [] as string[],
    };

    // Check SW registration
    if ('serviceWorker' in navigator) {
      const reg = await navigator.serviceWorker.getRegistration();
      results.swRegistration = reg ? {
        scope: reg.scope,
        active: !!reg.active,
        waiting: !!reg.waiting,
      } : null;

      // Check push subscription
      if (reg) {
        const sub = await reg.pushManager.getSubscription();
        results.pushSubscription = sub ? {
          endpoint: sub.endpoint.substring(0, 50) + '...',
          expirationTime: sub.expirationTime,
        } : null;
      }
    }

    // Run issue detection
    results.issues = await diagnoseNotificationIssues();

    setDiagnostics(results);
  };

  return (
    <div className="p-4 space-y-4">
      <Button onClick={runDiagnostics}>Run Diagnostics</Button>

      {diagnostics && (
        <pre className="p-4 bg-gray-100 rounded-lg text-xs overflow-auto">
          {JSON.stringify(diagnostics, null, 2)}
        </pre>
      )}
    </div>
  );
}
```

---

## 18. QUICK REFERENCE TABLE

| Issue | Quick Check | Solution |
|-------|-------------|----------|
| Permission denied | `Notification.permission` | Guide to settings |
| iOS not working | Check iOS 16.4+ and PWA | Install as PWA |
| No notifications | Run `diagnoseNotificationIssues()` | Fix detected issues |
| Click fails | Check SW console | Use `waitUntil()` |
| Badge not updating | `'setAppBadge' in navigator` | Use fallback UI |
| Silent push fails | Check quota | Use Background Sync |
| VAPID mismatch | Compare keys | Resubscribe |
| Subscription timeout | Check network | Retry with backoff |
| Battery optimization | Check OEM | Disable optimization |
| OEM killing app | Check manufacturer | OEM-specific settings |
| WebView browser | Detect `wv`/`fban` | Open in Chrome/Safari |
| Background data | Check `saveData` | Enable background data |
| Android 13+ | Check permissions | Request at runtime |

---

## 19. RELATED SKILLS

- `/skill pwa-ios-limitations` - iOS PWA platform limitations
- `/skill pwa-lighthouse-fixes` - Lighthouse PWA audit fixes
- `/skill offline-first-reference` - Offline-first architecture

---

## 20. VERIFICATION SEAL

```
OMEGA_v24.5.0 | PWA_PUSH_TROUBLESHOOTING
Gates: 8 | Commands: 8 | Phase: 2.4
IOS_16_4 | OEM_BATTERY | VAPID_ROTATION | WEBVIEW_DETECT
RTL_FIRST: MANDATORY | RESPONSIVE: MANDATORY
```

<!-- PWA-EXPERT/PUSH v24.5.0 | Updated: 2026-02-19 -->

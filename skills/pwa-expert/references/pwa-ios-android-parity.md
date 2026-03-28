# PWA iOS/Android Parity - Complete Platform Comparison

> **v24.5.0 SINGULARITY FORGE** | PWA Expert Skill
> **Critical for:** Consistent UX across all platforms

---

## GATE PWA-14: iOS/Android Parity

### Complete Feature Comparison Matrix

| Feature | iOS Safari | iOS PWA | Android Chrome | Android TWA |
|---------|------------|---------|----------------|-------------|
| Install Prompt | Manual (Share > Add) | N/A | `beforeinstallprompt` | Auto |
| Push Notifications | iOS 16.4+ PWA only | iOS 16.4+ | Full support | Full support |
| Background Sync | NO | NO | Full support | Full support |
| Periodic Sync | NO | NO | Limited (12h+) | Limited |
| Badging API | NO | NO | Full support | Full support |
| Screen Wake Lock | iOS 16.4+ | iOS 16.4+ | Full support | Full support |
| Web Share | Full | Full | Full | Full |
| File System Access | NO | NO | Full | Full |
| Contacts Picker | NO | NO | Full | Full |
| Storage Quota | ~50MB initial | ~50MB | Origin-based | Origin-based |
| 7-Day Eviction | YES (Safari) | NO (PWA) | NO | NO |
| Persistent Storage | Request available | Request available | Request available | Request available |
| Service Worker | Full | Full | Full | Full |
| WebGL | Full | Full | Full | Full |
| WebRTC | Full | Full | Full | Full |
| Geolocation | Prompt each time | Single prompt | Single prompt | Single prompt |
| Orientation Lock | NO | NO | Full | Full |
| Fullscreen API | NO | Standalone mode | Full | Full |

---

## Platform Detection Utility (COMPLETE)

```typescript
// Comprehensive platform detection for PWAs
export const pwaDetection = {
  // ==========================================
  // DEVICE DETECTION
  // ==========================================

  isIOS: (): boolean => {
    // Check for iPad on iOS 13+ (reports as MacIntel)
    const isIPadOS = navigator.platform === 'MacIntel' &&
                     navigator.maxTouchPoints > 1;

    return /iPad|iPhone|iPod/.test(navigator.userAgent) || isIPadOS;
  },

  isAndroid: (): boolean => {
    return /Android/i.test(navigator.userAgent);
  },

  isMobile: (): boolean => {
    return pwaDetection.isIOS() || pwaDetection.isAndroid();
  },

  isDesktop: (): boolean => {
    return !pwaDetection.isMobile();
  },

  isSafari: (): boolean => {
    const ua = navigator.userAgent;
    return /Safari/i.test(ua) && !/Chrome|CriOS|Chromium/i.test(ua);
  },

  isChrome: (): boolean => {
    return /Chrome|CriOS/i.test(navigator.userAgent) &&
           !/Edge|Edg|OPR|Opera/i.test(navigator.userAgent);
  },

  isFirefox: (): boolean => {
    return /Firefox|FxiOS/i.test(navigator.userAgent);
  },

  isSamsungBrowser: (): boolean => {
    return /SamsungBrowser/i.test(navigator.userAgent);
  },

  // ==========================================
  // PWA STATE DETECTION
  // ==========================================

  isStandalone: (): boolean => {
    // Check display-mode media query
    const standaloneQuery = window.matchMedia('(display-mode: standalone)');
    if (standaloneQuery.matches) return true;

    // Check fullscreen mode
    const fullscreenQuery = window.matchMedia('(display-mode: fullscreen)');
    if (fullscreenQuery.matches) return true;

    // Check iOS standalone (Safari-specific)
    if ((navigator as any).standalone === true) return true;

    // Check minimal-ui (rare but possible)
    const minimalQuery = window.matchMedia('(display-mode: minimal-ui)');
    if (minimalQuery.matches) return true;

    return false;
  },

  isIOSPWA: (): boolean => {
    return pwaDetection.isIOS() && pwaDetection.isStandalone();
  },

  isAndroidPWA: (): boolean => {
    return pwaDetection.isAndroid() && pwaDetection.isStandalone();
  },

  isTWA: (): boolean => {
    // Trusted Web Activity detection
    return document.referrer.includes('android-app://') ||
           (pwaDetection.isAndroid() && pwaDetection.isStandalone());
  },

  // ==========================================
  // VERSION DETECTION
  // ==========================================

  getIOSVersion: (): number | null => {
    const match = navigator.userAgent.match(/OS (\d+)_(\d+)(?:_(\d+))?/);
    if (!match) return null;
    return parseFloat(`${match[1]}.${match[2]}`);
  },

  getAndroidVersion: (): number | null => {
    const match = navigator.userAgent.match(/Android (\d+(?:\.\d+)?)/);
    return match ? parseFloat(match[1]) : null;
  },

  getChromeVersion: (): number | null => {
    const match = navigator.userAgent.match(/Chrome\/(\d+)/);
    return match ? parseInt(match[1], 10) : null;
  },

  getSafariVersion: (): number | null => {
    const match = navigator.userAgent.match(/Version\/(\d+(?:\.\d+)?)/);
    return match ? parseFloat(match[1]) : null;
  },

  // ==========================================
  // CAPABILITY FLAGS
  // ==========================================

  isOldAndroid: (): boolean => {
    const chromeVersion = pwaDetection.getChromeVersion();
    const androidVersion = pwaDetection.getAndroidVersion();

    // Chrome < 84 or Android < 8
    return pwaDetection.isAndroid() && (
      (chromeVersion !== null && chromeVersion < 84) ||
      (androidVersion !== null && androidVersion < 8)
    );
  },

  isOldIOS: (): boolean => {
    const version = pwaDetection.getIOSVersion();
    // iOS < 15 is considered "old"
    return pwaDetection.isIOS() && version !== null && version < 15;
  },

  isLowRAM: (): boolean => {
    const memory = (navigator as any).deviceMemory;
    return memory !== undefined && memory <= 2;
  },

  isLowCPU: (): boolean => {
    return navigator.hardwareConcurrency !== undefined &&
           navigator.hardwareConcurrency <= 2;
  },

  isLowEndDevice: (): boolean => {
    return pwaDetection.isLowRAM() || pwaDetection.isLowCPU();
  },

  // ==========================================
  // FEATURE SUPPORT
  // ==========================================

  supportsServiceWorker: (): boolean => {
    return 'serviceWorker' in navigator;
  },

  supportsBackgroundSync: (): boolean => {
    // iOS does NOT support Background Sync
    if (pwaDetection.isIOS()) return false;

    return 'serviceWorker' in navigator &&
           'sync' in (ServiceWorkerRegistration?.prototype ?? {});
  },

  supportsPeriodicSync: (): boolean => {
    // iOS does NOT support Periodic Sync
    if (pwaDetection.isIOS()) return false;

    return 'serviceWorker' in navigator &&
           'periodicSync' in (ServiceWorkerRegistration?.prototype ?? {});
  },

  supportsPushNotifications: (): boolean => {
    // iOS 16.4+ in PWA mode only
    if (pwaDetection.isIOS()) {
      const version = pwaDetection.getIOSVersion();
      return pwaDetection.isIOSPWA() &&
             version !== null &&
             version >= 16.4 &&
             'PushManager' in window;
    }

    return 'PushManager' in window;
  },

  supportsBadging: (): boolean => {
    // iOS does NOT support Badging API
    if (pwaDetection.isIOS()) return false;

    return 'setAppBadge' in navigator;
  },

  supportsWakeLock: (): boolean => {
    return 'wakeLock' in navigator;
  },

  supportsWebShare: (): boolean => {
    return 'share' in navigator;
  },

  supportsWebShareFiles: (): boolean => {
    return 'canShare' in navigator &&
           navigator.canShare({ files: [new File([], 'test.txt')] });
  },

  supportsFileSystemAccess: (): boolean => {
    // iOS does NOT support File System Access API
    if (pwaDetection.isIOS()) return false;

    return 'showOpenFilePicker' in window;
  },

  supportsContactsPicker: (): boolean => {
    // iOS does NOT support Contacts Picker
    if (pwaDetection.isIOS()) return false;

    return 'contacts' in navigator && 'select' in (navigator as any).contacts;
  },

  supportsScreenCapture: (): boolean => {
    return 'getDisplayMedia' in (navigator.mediaDevices ?? {});
  },

  supportsOrientationLock: (): boolean => {
    // iOS does NOT support orientation lock
    if (pwaDetection.isIOS()) return false;

    return 'orientation' in screen && 'lock' in (screen.orientation ?? {});
  },

  supportsInstallPrompt: (): boolean => {
    // iOS uses manual install (Share > Add to Home Screen)
    if (pwaDetection.isIOS()) return false;

    // Android supports beforeinstallprompt
    return pwaDetection.isAndroid();
  },

  supportsPersistentStorage: (): boolean => {
    return 'storage' in navigator && 'persist' in navigator.storage;
  },

  supportsStorageEstimate: (): boolean => {
    return 'storage' in navigator && 'estimate' in navigator.storage;
  },

  // ==========================================
  // GET ALL CAPABILITIES
  // ==========================================

  getCapabilities: () => ({
    device: {
      isIOS: pwaDetection.isIOS(),
      isAndroid: pwaDetection.isAndroid(),
      isMobile: pwaDetection.isMobile(),
      isDesktop: pwaDetection.isDesktop(),
      isSafari: pwaDetection.isSafari(),
      isChrome: pwaDetection.isChrome(),
      isOldAndroid: pwaDetection.isOldAndroid(),
      isOldIOS: pwaDetection.isOldIOS(),
      isLowEndDevice: pwaDetection.isLowEndDevice(),
    },
    pwa: {
      isStandalone: pwaDetection.isStandalone(),
      isIOSPWA: pwaDetection.isIOSPWA(),
      isAndroidPWA: pwaDetection.isAndroidPWA(),
      isTWA: pwaDetection.isTWA(),
    },
    versions: {
      ios: pwaDetection.getIOSVersion(),
      android: pwaDetection.getAndroidVersion(),
      chrome: pwaDetection.getChromeVersion(),
      safari: pwaDetection.getSafariVersion(),
    },
    features: {
      serviceWorker: pwaDetection.supportsServiceWorker(),
      backgroundSync: pwaDetection.supportsBackgroundSync(),
      periodicSync: pwaDetection.supportsPeriodicSync(),
      pushNotifications: pwaDetection.supportsPushNotifications(),
      badging: pwaDetection.supportsBadging(),
      wakeLock: pwaDetection.supportsWakeLock(),
      webShare: pwaDetection.supportsWebShare(),
      webShareFiles: pwaDetection.supportsWebShareFiles(),
      fileSystemAccess: pwaDetection.supportsFileSystemAccess(),
      contactsPicker: pwaDetection.supportsContactsPicker(),
      orientationLock: pwaDetection.supportsOrientationLock(),
      installPrompt: pwaDetection.supportsInstallPrompt(),
      persistentStorage: pwaDetection.supportsPersistentStorage(),
    },
  }),
};

// Export type for capabilities
export type PWACapabilities = ReturnType<typeof pwaDetection.getCapabilities>;
```

---

## iOS Splash Screens (ALL Device Sizes)

### Complete iOS Splash Screen Meta Tags

```html
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <!-- iOS PWA Configuration -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="App Name">

  <!-- iOS Touch Icons -->
  <link rel="apple-touch-icon" href="/icons/apple-touch-icon.png">
  <link rel="apple-touch-icon" sizes="152x152" href="/icons/apple-touch-icon-152x152.png">
  <link rel="apple-touch-icon" sizes="167x167" href="/icons/apple-touch-icon-167x167.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/icons/apple-touch-icon-180x180.png">

  <!-- ========================================== -->
  <!-- iOS SPLASH SCREENS - ALL DEVICE SIZES -->
  <!-- ========================================== -->

  <!-- iPhone 15 Pro Max, 14 Pro Max (430x932 @3x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1290-2796.png"
        media="(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2796-1290.png"
        media="(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">

  <!-- iPhone 15 Pro, 14 Pro (393x852 @3x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1179-2556.png"
        media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2556-1179.png"
        media="(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">

  <!-- iPhone 15, 15 Plus, 14, 14 Plus, 13, 13 Pro, 12, 12 Pro (390x844 @3x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1170-2532.png"
        media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2532-1170.png"
        media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">

  <!-- iPhone 14 Plus, 13 Pro Max, 12 Pro Max (428x926 @3x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1284-2778.png"
        media="(device-width: 428px) and (device-height: 926px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2778-1284.png"
        media="(device-width: 428px) and (device-height: 926px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">

  <!-- iPhone 13 mini, 12 mini (375x812 @3x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1125-2436.png"
        media="(device-width: 375px) and (device-height: 812px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2436-1125.png"
        media="(device-width: 375px) and (device-height: 812px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">

  <!-- iPhone 11 Pro Max, XS Max (414x896 @3x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1242-2688.png"
        media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2688-1242.png"
        media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">

  <!-- iPhone 11, XR (414x896 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-828-1792.png"
        media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1792-828.png"
        media="(device-width: 414px) and (device-height: 896px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPhone 11 Pro, X, XS (375x812 @3x) - same as 13 mini -->
  <!-- Already covered above -->

  <!-- iPhone SE 3rd/2nd Gen, 8, 7, 6s (375x667 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-750-1334.png"
        media="(device-width: 375px) and (device-height: 667px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1334-750.png"
        media="(device-width: 375px) and (device-height: 667px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPhone 8 Plus, 7 Plus, 6s Plus (414x736 @3x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1242-2208.png"
        media="(device-width: 414px) and (device-height: 736px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2208-1242.png"
        media="(device-width: 414px) and (device-height: 736px) and (-webkit-device-pixel-ratio: 3) and (orientation: landscape)">

  <!-- iPad Pro 12.9" (1024x1366 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2048-2732.png"
        media="(device-width: 1024px) and (device-height: 1366px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2732-2048.png"
        media="(device-width: 1024px) and (device-height: 1366px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPad Pro 11" (834x1194 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1668-2388.png"
        media="(device-width: 834px) and (device-height: 1194px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2388-1668.png"
        media="(device-width: 834px) and (device-height: 1194px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPad Air 10.9", iPad 10th Gen (820x1180 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1640-2360.png"
        media="(device-width: 820px) and (device-height: 1180px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2360-1640.png"
        media="(device-width: 820px) and (device-height: 1180px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPad Pro 10.5", iPad Air 3 (834x1112 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1668-2224.png"
        media="(device-width: 834px) and (device-height: 1112px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2224-1668.png"
        media="(device-width: 834px) and (device-height: 1112px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPad 9th Gen, 8th Gen, 7th Gen (810x1080 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1620-2160.png"
        media="(device-width: 810px) and (device-height: 1080px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2160-1620.png"
        media="(device-width: 810px) and (device-height: 1080px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPad Mini 6th Gen (744x1133 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1488-2266.png"
        media="(device-width: 744px) and (device-height: 1133px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2266-1488.png"
        media="(device-width: 744px) and (device-height: 1133px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">

  <!-- iPad Mini 5th Gen and earlier (768x1024 @2x) -->
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-1536-2048.png"
        media="(device-width: 768px) and (device-height: 1024px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)">
  <link rel="apple-touch-startup-image"
        href="/splash/apple-splash-2048-1536.png"
        media="(device-width: 768px) and (device-height: 1024px) and (-webkit-device-pixel-ratio: 2) and (orientation: landscape)">
</head>
</html>
```

### Splash Screen Generator Script

```typescript
// Script to generate all iOS splash screen sizes
// Run with: npx ts-node generate-splashes.ts

import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';

interface SplashConfig {
  width: number;
  height: number;
  name: string;
}

const SPLASH_CONFIGS: SplashConfig[] = [
  // iPhone Portrait
  { width: 1290, height: 2796, name: 'apple-splash-1290-2796' },
  { width: 1179, height: 2556, name: 'apple-splash-1179-2556' },
  { width: 1170, height: 2532, name: 'apple-splash-1170-2532' },
  { width: 1284, height: 2778, name: 'apple-splash-1284-2778' },
  { width: 1125, height: 2436, name: 'apple-splash-1125-2436' },
  { width: 1242, height: 2688, name: 'apple-splash-1242-2688' },
  { width: 828, height: 1792, name: 'apple-splash-828-1792' },
  { width: 750, height: 1334, name: 'apple-splash-750-1334' },
  { width: 1242, height: 2208, name: 'apple-splash-1242-2208' },
  // iPhone Landscape
  { width: 2796, height: 1290, name: 'apple-splash-2796-1290' },
  { width: 2556, height: 1179, name: 'apple-splash-2556-1179' },
  { width: 2532, height: 1170, name: 'apple-splash-2532-1170' },
  { width: 2778, height: 1284, name: 'apple-splash-2778-1284' },
  { width: 2436, height: 1125, name: 'apple-splash-2436-1125' },
  { width: 2688, height: 1242, name: 'apple-splash-2688-1242' },
  { width: 1792, height: 828, name: 'apple-splash-1792-828' },
  { width: 1334, height: 750, name: 'apple-splash-1334-750' },
  { width: 2208, height: 1242, name: 'apple-splash-2208-1242' },
  // iPad Portrait
  { width: 2048, height: 2732, name: 'apple-splash-2048-2732' },
  { width: 1668, height: 2388, name: 'apple-splash-1668-2388' },
  { width: 1640, height: 2360, name: 'apple-splash-1640-2360' },
  { width: 1668, height: 2224, name: 'apple-splash-1668-2224' },
  { width: 1620, height: 2160, name: 'apple-splash-1620-2160' },
  { width: 1488, height: 2266, name: 'apple-splash-1488-2266' },
  { width: 1536, height: 2048, name: 'apple-splash-1536-2048' },
  // iPad Landscape
  { width: 2732, height: 2048, name: 'apple-splash-2732-2048' },
  { width: 2388, height: 1668, name: 'apple-splash-2388-1668' },
  { width: 2360, height: 1640, name: 'apple-splash-2360-1640' },
  { width: 2224, height: 1668, name: 'apple-splash-2224-1668' },
  { width: 2160, height: 1620, name: 'apple-splash-2160-1620' },
  { width: 2266, height: 1488, name: 'apple-splash-2266-1488' },
  { width: 2048, height: 1536, name: 'apple-splash-2048-1536' },
];

async function generateSplashScreens(
  logoPath: string,
  backgroundColor: string,
  outputDir: string
) {
  await fs.mkdir(outputDir, { recursive: true });

  const logo = await sharp(logoPath).metadata();
  const logoBuffer = await sharp(logoPath).toBuffer();

  for (const config of SPLASH_CONFIGS) {
    // Calculate logo size (40% of smallest dimension)
    const logoSize = Math.min(config.width, config.height) * 0.4;

    // Calculate logo position (centered)
    const logoX = Math.round((config.width - logoSize) / 2);
    const logoY = Math.round((config.height - logoSize) / 2);

    // Resize logo
    const resizedLogo = await sharp(logoBuffer)
      .resize(Math.round(logoSize), Math.round(logoSize), { fit: 'contain' })
      .toBuffer();

    // Create splash screen
    await sharp({
      create: {
        width: config.width,
        height: config.height,
        channels: 4,
        background: backgroundColor,
      },
    })
      .composite([
        {
          input: resizedLogo,
          left: logoX,
          top: logoY,
        },
      ])
      .png()
      .toFile(path.join(outputDir, `${config.name}.png`));

    console.log(`Generated: ${config.name}.png`);
  }
}

// Usage
generateSplashScreens(
  './public/logo.png',
  '#ffffff',
  './public/splash'
);
```

---

## Status Bar Styling

### iOS Status Bar

```html
<!-- iOS Status Bar Styles -->

<!-- Default: Black text on white background -->
<meta name="apple-mobile-web-app-status-bar-style" content="default">

<!-- Black text on transparent (content extends behind) -->
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">

<!-- White text on black background -->
<meta name="apple-mobile-web-app-status-bar-style" content="black">
```

### Android Status Bar (theme_color)

```json
// manifest.json
{
  "theme_color": "#1a1a2e",
  "background_color": "#1a1a2e"
}
```

```html
<!-- HTML meta tag (fallback) -->
<meta name="theme-color" content="#1a1a2e">

<!-- Dynamic theme color based on color scheme -->
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#1a1a2e" media="(prefers-color-scheme: dark)">
```

---

## CSS Rendering Differences

### Backdrop-Filter (CRITICAL)

```css
/* iOS: GPU accelerated, smooth */
/* Android: CPU, can be janky on old devices */

/* Safe implementation with fallback */
.glass-effect {
  /* Fallback: solid background */
  background: hsl(var(--background) / 0.95);
}

/* Apply blur only if supported */
@supports (backdrop-filter: blur(12px)) {
  .glass-effect {
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    background: hsl(var(--background) / 0.8);
  }
}

/* Disable on Android via JS class */
.is-android .glass-effect {
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  background: hsl(var(--background) / 0.95) !important;
}
```

```typescript
// Add Android class for CSS targeting
if (pwaDetection.isAndroid()) {
  document.documentElement.classList.add('is-android');
}

if (pwaDetection.isIOS()) {
  document.documentElement.classList.add('is-ios');
}
```

### Input Zoom Prevention (iOS)

```css
/* iOS zooms on inputs with font-size < 16px */
/* PREVENT by ensuring minimum 16px */

input,
select,
textarea {
  font-size: 16px !important;
}

/* Or use max() to ensure minimum */
input,
select,
textarea {
  font-size: max(16px, 1rem);
}

/* Tailwind: Use text-base (16px) */
@layer base {
  input,
  select,
  textarea {
    @apply text-base;
  }
}
```

### Safe Area Handling

```css
/* iOS: env() returns actual inset values */
/* Android: env() often returns 0 (no notch handling) */

/* Always use RTL-aware logical properties with fallback */
.safe-container {
  padding-top: max(1rem, env(safe-area-inset-top, 0px));
  padding-bottom: max(1rem, env(safe-area-inset-bottom, 0px));
  padding-inline-start: max(1rem, env(safe-area-inset-left, 0px));
  padding-inline-end: max(1rem, env(safe-area-inset-right, 0px));
}

/* Viewport meta for safe area support */
```

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

### Scrollbar Visibility

```css
/* iOS: Hidden by default */
/* Android: Visible by default */

/* Normalize: Hide on both */
* {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* IE/Edge */
}

*::-webkit-scrollbar {
  display: none; /* Chrome/Safari/Opera */
}

/* Or show on both with custom styling */
* {
  scrollbar-width: thin;
  scrollbar-color: hsl(var(--muted)) transparent;
}

*::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

*::-webkit-scrollbar-track {
  background: transparent;
}

*::-webkit-scrollbar-thumb {
  background: hsl(var(--muted));
  border-radius: 3px;
}
```

---

## Push Notification Differences

```typescript
// iOS 16.4+ PWA only push notifications
async function requestPushPermission(): Promise<boolean> {
  // Check if supported first
  if (!pwaDetection.supportsPushNotifications()) {
    if (pwaDetection.isIOS() && !pwaDetection.isIOSPWA()) {
      console.log('Push requires iOS PWA mode (Add to Home Screen)');
      return false;
    }
    console.log('Push notifications not supported');
    return false;
  }

  // Request permission
  const permission = await Notification.requestPermission();
  return permission === 'granted';
}

// Subscribe to push with platform-specific handling
async function subscribeToPush(): Promise<PushSubscription | null> {
  if (!pwaDetection.supportsPushNotifications()) {
    return null;
  }

  try {
    const registration = await navigator.serviceWorker.ready;

    // iOS requires specific options
    const options: PushSubscriptionOptionsInit = {
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
    };

    const subscription = await registration.pushManager.subscribe(options);

    // Send to server
    await sendSubscriptionToServer(subscription);

    return subscription;
  } catch (error) {
    console.error('Push subscription failed:', error);
    return null;
  }
}
```

---

## Storage Quota Differences

```typescript
// Check available storage
async function checkStorageQuota(): Promise<{
  usage: number;
  quota: number;
  percentUsed: number;
  isLow: boolean;
}> {
  if (!pwaDetection.supportsStorageEstimate()) {
    return {
      usage: 0,
      quota: 0,
      percentUsed: 0,
      isLow: false,
    };
  }

  const { usage = 0, quota = 0 } = await navigator.storage.estimate();
  const percentUsed = quota > 0 ? (usage / quota) * 100 : 0;

  // iOS has ~50MB initial quota (can grow)
  // Android has origin-based quota (usually much larger)
  const isLow = pwaDetection.isIOS()
    ? usage > 40 * 1024 * 1024 // 40MB on iOS
    : percentUsed > 80; // 80% on Android

  return { usage, quota, percentUsed, isLow };
}

// Request persistent storage
async function requestPersistentStorage(): Promise<boolean> {
  if (!pwaDetection.supportsPersistentStorage()) {
    return false;
  }

  // Check if already persisted
  const isPersisted = await navigator.storage.persisted();
  if (isPersisted) {
    return true;
  }

  // Request persistence
  // Note: iOS may auto-grant, Android shows prompt
  const granted = await navigator.storage.persist();
  return granted;
}
```

---

## WebSocket Reconnection (iOS Background)

```typescript
// iOS kills WebSocket connections after ~30 seconds in background
// Must implement reconnection on visibility change

class ReliableWebSocket {
  private ws: WebSocket | null = null;
  private url: string;
  private heartbeatInterval: ReturnType<typeof setInterval> | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 10;
  private listeners: Map<string, Set<(data: unknown) => void>> = new Map();

  constructor(url: string) {
    this.url = url;
    this.setupVisibilityHandler();
  }

  private setupVisibilityHandler() {
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        // App returned to foreground
        if (!this.isConnected()) {
          console.log('App visible, reconnecting WebSocket...');
          this.reconnect();
        }
      } else {
        // App going to background
        // On iOS, connection will likely die
        // Could send a "going away" message here
      }
    });
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(this.url);

        this.ws.onopen = () => {
          console.log('WebSocket connected');
          this.reconnectAttempts = 0;
          this.startHeartbeat();
          resolve();
        };

        this.ws.onclose = (event) => {
          console.log('WebSocket closed:', event.code, event.reason);
          this.stopHeartbeat();

          // Auto-reconnect if not intentional close
          if (event.code !== 1000) {
            this.scheduleReconnect();
          }
        };

        this.ws.onerror = (error) => {
          console.error('WebSocket error:', error);
          reject(error);
        };

        this.ws.onmessage = (event) => {
          this.handleMessage(event.data);
        };
      } catch (error) {
        reject(error);
      }
    });
  }

  private startHeartbeat() {
    // iOS times out at ~30s, send ping every 25s
    this.heartbeatInterval = setInterval(() => {
      if (this.isConnected()) {
        this.send({ type: 'ping', timestamp: Date.now() });
      }
    }, 25000);
  }

  private stopHeartbeat() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }
  }

  private scheduleReconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnect attempts reached');
      return;
    }

    // Exponential backoff: 1s, 2s, 4s, 8s, max 30s
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
    this.reconnectAttempts++;

    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

    setTimeout(() => {
      this.reconnect();
    }, delay);
  }

  private async reconnect() {
    this.disconnect();

    try {
      await this.connect();
    } catch (error) {
      console.error('Reconnect failed:', error);
    }
  }

  isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
  }

  send(data: object): void {
    if (this.isConnected()) {
      this.ws!.send(JSON.stringify(data));
    } else {
      console.warn('Cannot send, WebSocket not connected');
    }
  }

  on(event: string, callback: (data: unknown) => void): () => void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);

    // Return unsubscribe function
    return () => {
      this.listeners.get(event)?.delete(callback);
    };
  }

  private handleMessage(raw: string) {
    try {
      const data = JSON.parse(raw);
      const event = data.type || 'message';

      this.listeners.get(event)?.forEach(cb => cb(data));
      this.listeners.get('*')?.forEach(cb => cb(data));
    } catch (error) {
      console.error('Failed to parse WebSocket message:', error);
    }
  }

  disconnect() {
    this.stopHeartbeat();

    if (this.ws) {
      this.ws.close(1000, 'Client disconnect');
      this.ws = null;
    }
  }
}

// Usage
const ws = new ReliableWebSocket('wss://api.example.com/ws');

await ws.connect();

ws.on('message', (data) => {
  console.log('Received:', data);
});

ws.send({ type: 'subscribe', channel: 'updates' });
```

---

## Install Prompt Handling

```typescript
// Store the beforeinstallprompt event
let deferredPrompt: BeforeInstallPromptEvent | null = null;

// Android: Capture the event
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e as BeforeInstallPromptEvent;

  // Show your custom install UI
  showInstallButton();
});

// Trigger install prompt
async function promptInstall(): Promise<boolean> {
  // iOS: Show instructions
  if (pwaDetection.isIOS()) {
    showIOSInstallInstructions();
    return false;
  }

  // Android: Use captured event
  if (!deferredPrompt) {
    console.log('Install prompt not available');
    return false;
  }

  deferredPrompt.prompt();

  const { outcome } = await deferredPrompt.userChoice;

  deferredPrompt = null;

  return outcome === 'accepted';
}

// iOS install instructions component
function IOSInstallInstructions() {
  return (
    <div className="ios-install-modal">
      <h2>התקנה ל-iPhone</h2>
      <ol dir="rtl">
        <li>
          לחץ על כפתור השיתוף
          <ShareIcon className="rtl:rotate-180" />
        </li>
        <li>גלול למטה ובחר "הוסף למסך הבית"</li>
        <li>לחץ "הוסף" בפינה הימנית העליונה</li>
      </ol>
    </div>
  );
}
```

---

## Audio/Video Playsinline

```html
<!-- iOS requires playsinline for inline video playback -->
<video
  playsinline
  webkit-playsinline
  autoplay
  muted
  loop
>
  <source src="video.mp4" type="video/mp4">
</video>
```

```typescript
// Programmatic video with iOS support
function createVideo(src: string): HTMLVideoElement {
  const video = document.createElement('video');

  video.src = src;
  video.playsInline = true; // Critical for iOS
  video.setAttribute('webkit-playsinline', ''); // Legacy iOS
  video.muted = true; // Required for autoplay on both platforms
  video.autoplay = true;
  video.loop = true;

  return video;
}
```

<!-- PWA-EXPERT/IOS-ANDROID-PARITY v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->

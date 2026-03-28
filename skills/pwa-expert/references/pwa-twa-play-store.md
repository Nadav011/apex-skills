# PWA-TWA-PLAY-STORE v24.5.0 SINGULARITY FORGE

> Master of Trusted Web Activities, Play Store Distribution, Digital Asset Links, and Android App Packaging

---

## 1. PURPOSE

Comprehensive guide for publishing Progressive Web Apps (PWAs) to the Google Play Store as Trusted Web Activities (TWA). Covers the complete workflow from PWA prerequisites through Play Store submission, including Digital Asset Links verification, Bubblewrap/PWABuilder tooling, and Android version compatibility.

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/twa init` | Initialize TWA project with Bubblewrap | ~5min |
| `/twa build` | Build signed APK/AAB | ~2min |
| `/twa assetlinks` | Generate and verify Digital Asset Links | ~3min |
| `/twa verify` | Verify DAL and manifest requirements | ~1min |
| `/twa deploy` | Deploy to Play Store internal track | ~5min |
| `/twa troubleshoot` | Debug common TWA issues | ~5min |
| `/twa update` | Update existing TWA version | ~3min |
| `/twa icons` | Generate all required icon sizes | ~2min |

---

## 3. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-TWA-1 | PWA_READY | Lighthouse PWA audit | Score 90+ |
| G-TWA-2 | MANIFEST_VALID | manifest.json complete | All required fields |
| G-TWA-3 | HTTPS_ENABLED | SSL certificate | Valid HTTPS |
| G-TWA-4 | DAL_VERIFIED | Asset links validation | Google tool passes |
| G-TWA-5 | ICONS_COMPLETE | All icon sizes | 192, 512, maskable |
| G-TWA-6 | SIGNED_BUILD | APK/AAB signed | Valid keystore |
| G-TWA-7 | PLAY_READY | Store listing complete | All assets uploaded |

---

## 4. WHEN TO USE TWA VS PWA-ONLY

| Factor | PWA Only | TWA (Play Store) |
|--------|----------|------------------|
| Discoverability | Web search, direct URL | Play Store search, featured listings |
| Installation | Browser prompt, manual | One-tap Play Store install |
| Monetization | Limited | In-app purchases, subscriptions |
| User Trust | Medium | High (verified by Google) |
| Push Notifications | Web Push | FCM (more reliable) |
| Updates | Automatic (instant) | Web: instant, APK: requires republish |
| Offline | Service worker | Service worker |
| Device APIs | Limited | Extended via Capacitor/plugins |

### Choose TWA When:
- Play Store presence is important for your market
- Users expect to find you in the Play Store
- You need Google Play billing for monetization
- Brand credibility from Play Store verification matters
- You want to leverage Play Store ratings and reviews

### Stick with PWA-Only When:
- Quick iteration is critical (no review process)
- Target audience is comfortable with web apps
- No monetization through Play Store needed
- iOS is your primary market (no TWA equivalent)

---

## 5. PREREQUISITES CHECKLIST

Before starting, ensure your PWA meets these requirements:

### Technical Requirements

- [ ] **HTTPS**: Site must be served over HTTPS (required for service workers)
- [ ] **Service Worker**: Registered and functional with offline support
- [ ] **Web App Manifest**: Complete manifest.json with all required fields
- [ ] **Lighthouse PWA Score**: 90+ on Lighthouse PWA audit
- [ ] **Responsive Design**: Works on all screen sizes
- [ ] **Fast Loading**: LCP < 1.0s (APEX target), INP < 100ms

### Web App Manifest (Complete Example)

```json
{
  "name": "Cash Delivery Management",
  "short_name": "Cash",
  "description": "Delivery tracking and management system",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#ffffff",
  "theme_color": "#1a1a2e",
  "lang": "he",
  "dir": "rtl",
  "scope": "/",
  "icons": [
    {
      "src": "/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "screenshots": [
    {
      "src": "/screenshots/home.png",
      "sizes": "1080x1920",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "Home screen"
    },
    {
      "src": "/screenshots/dashboard.png",
      "sizes": "1080x1920",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "Dashboard"
    }
  ],
  "categories": ["business", "productivity"],
  "shortcuts": [
    {
      "name": "New Delivery",
      "short_name": "New",
      "description": "Create a new delivery",
      "url": "/deliveries/new",
      "icons": [{ "src": "/icons/shortcut-new.png", "sizes": "96x96" }]
    }
  ]
}
```

### Lighthouse PWA Audit

Run before proceeding:

```bash
# Using Lighthouse CLI
npx lighthouse https://your-app.com --view --preset=desktop

# Or in Chrome DevTools:
# 1. Open DevTools (F12)
# 2. Go to Lighthouse tab
# 3. Select "Progressive Web App" category
# 4. Click "Analyze page load"
```

**Must Pass:**
- Installable
- PWA Optimized
- Fast and reliable
- All PWA checklist items

---

## 6. ANDROID VERSION COMPATIBILITY

Understanding Android version requirements is critical for TWA success.

### Minimum Requirements Matrix

| Feature | Min Android | Min Chrome | Notes |
|---------|-------------|------------|-------|
| TWA (basic) | 7.0 (API 24) | 72+ | Full TWA experience |
| Custom Tabs fallback | 5.0 (API 21) | 45+ | Browser UI visible |
| WebView fallback | 4.4 (API 19) | N/A | Limited features |
| Splash screens | 7.0 (API 24) | 72+ | Native splash |
| Web Share Target | 8.0 (API 26) | 76+ | Share to app |
| Shortcuts | 7.1 (API 25) | 84+ | Home screen shortcuts |
| Maskable icons | 8.0 (API 26) | 78+ | Adaptive icons |

### Recommended minSdkVersion Settings

```json
// twa-manifest.json
{
  "minSdkVersion": 23,    // Android 6.0 - Good balance of features/reach
  // OR
  "minSdkVersion": 24,    // Android 7.0 - Full TWA, loses ~3% users
  // OR
  "minSdkVersion": 21     // Android 5.0 - Maximum reach, uses Custom Tabs
}
```

### Android Version Market Share (2026)

| Version | API Level | Market Share | Recommendation |
|---------|-----------|--------------|----------------|
| Android 14+ | 34+ | ~25% | Full support |
| Android 13 | 33 | ~20% | Full support |
| Android 12 | 31-32 | ~18% | Full support |
| Android 11 | 30 | ~15% | Full support |
| Android 10 | 29 | ~10% | Full support |
| Android 9 | 28 | ~5% | Full support |
| Android 8.x | 26-27 | ~4% | Minor limitations |
| Android 7.x | 24-25 | ~2% | TWA works |
| Android 6.0 | 23 | ~1% | Custom Tabs only |
| Below 6.0 | <23 | <1% | Not recommended |

### Chrome Version Detection

```javascript
// Detect Chrome version in your PWA
function getChromeVersion() {
  const match = navigator.userAgent.match(/Chrome\/(\d+)/);
  return match ? parseInt(match[1], 10) : 0;
}

// Check TWA compatibility
function isTWACompatible() {
  const chromeVersion = getChromeVersion();
  const isAndroid = /Android/.test(navigator.userAgent);
  return isAndroid && chromeVersion >= 72;
}
```

### Fallback Strategy Decision Tree

```
User opens app
     |
     +- Android 7.0+ AND Chrome 72+?
     |       |
     |       +- YES -> Full TWA experience (no browser UI)
     |       |
     |       +- NO -> Chrome installed?
     |               |
     |               +- YES -> Chrome Custom Tabs (browser UI visible)
     |               |
     |               +- NO -> WebView fallback (limited)
     |
     +- Android 5.0-6.x?
             |
             +- Chrome Custom Tabs only (configure fallbackType)
```

### Old Device Issues and Solutions

| Issue | Affected Devices | Solution |
|-------|------------------|----------|
| Chrome not installed | All Android | Configure `fallbackType: "webview"` |
| Chrome outdated | Older devices | Prompt Chrome update or use Custom Tabs |
| WebView crashes | Android 5.0-5.1 | Set `minSdkVersion: 23` |
| Memory issues | Low RAM devices | Optimize bundle size < 100KB |
| Slow splash | Older CPUs | Reduce `splashScreenFadeOutDuration` |
| Push not working | Android < 8.0 | Fallback to in-app notifications |

### Configuring Fallback Behavior

```json
// twa-manifest.json - Complete fallback configuration
{
  "minSdkVersion": 23,
  "fallbackType": "customtabs",
  "features": {
    "locationDelegation": {
      "enabled": true
    }
  },
  "alphaDependencies": {
    "enabled": false
  }
}
```

**Fallback Type Options:**

| Type | Behavior | When to Use |
|------|----------|-------------|
| `customtabs` | Opens in Chrome Custom Tab with minimal UI | Default, most compatible |
| `webview` | Opens in Android WebView | When Chrome not available |

---

## 7. DIGITAL ASSET LINKS

Digital Asset Links verify ownership between your website and Android app. This is **critical** for TWA to work without showing browser UI.

### Step 1: Generate Signing Key Fingerprint

```bash
# For debug keystore (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore (production)
keytool -list -v -keystore your-release-key.keystore -alias your-alias

# Output includes SHA256 fingerprint like:
# SHA256: 14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5
```

### Step 2: Create assetlinks.json

Create the file at `/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.yourcompany.yourapp",
      "sha256_cert_fingerprints": [
        "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"
      ]
    }
  }
]
```

**Multiple Fingerprints** (debug + release + Play Store):

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.yourcompany.yourapp",
      "sha256_cert_fingerprints": [
        "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5",
        "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99",
        "11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00"
      ]
    }
  }
]
```

### Step 3: Deploy and Verify

1. Deploy the file to your web server
2. Verify it's accessible at: `https://your-app.com/.well-known/assetlinks.json`
3. Use Google's verification tool:

```bash
# Digital Asset Links API verification
curl -s "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://your-app.com&relation=delegate_permission/common.handle_all_urls"
```

Or use the web tool: https://developers.google.com/digital-asset-links/tools/generator

### Vite/Next.js Configuration

**Vite (public folder):**
```
public/
  .well-known/
    assetlinks.json
```

**Next.js (static serving via App Router):**
```typescript
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: '/.well-known/assetlinks.json',
        destination: '/api/assetlinks',
      },
    ];
  },
};

export default nextConfig;

// app/api/assetlinks/route.ts
export function GET() {
  return Response.json([
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: 'com.yourcompany.yourapp',
        sha256_cert_fingerprints: ['YOUR_FINGERPRINT'],
      },
    },
  ], {
    headers: { 'Content-Type': 'application/json' },
  });
}
```

### Common Digital Asset Links Issues

#### Issue 1: Wrong Content-Type Header

```bash
# Check headers
curl -I https://your-app.com/.well-known/assetlinks.json

# MUST return:
# Content-Type: application/json
# NOT: text/plain, text/html, application/octet-stream
```

**Fix for Vercel:**
```json
// vercel.json
{
  "headers": [
    {
      "source": "/.well-known/assetlinks.json",
      "headers": [
        { "key": "Content-Type", "value": "application/json" }
      ]
    }
  ]
}
```

**Fix for Nginx:**
```nginx
location /.well-known/assetlinks.json {
    default_type application/json;
}
```

#### Issue 2: CORS/Access Issues

```bash
# Verify accessibility (no redirects, no auth)
curl -v https://your-app.com/.well-known/assetlinks.json

# Must NOT:
# - Redirect to HTTPS (should already be HTTPS)
# - Require authentication
# - Return 301/302 redirects
# - Be blocked by firewall
```

#### Issue 3: Package Name Mismatch

```json
// assetlinks.json - Package name MUST match exactly
{
  "target": {
    "namespace": "android_app",
    "package_name": "com.yourcompany.yourapp",  // Must match twa-manifest.json
    ...
  }
}
```

```json
// twa-manifest.json
{
  "packageId": "com.yourcompany.yourapp"  // Must match assetlinks.json
}
```

#### Issue 4: Missing Play App Signing Fingerprint

When using Play App Signing (recommended), Google re-signs your app. You need BOTH fingerprints:

```json
// assetlinks.json with BOTH fingerprints
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.yourcompany.yourapp",
      "sha256_cert_fingerprints": [
        "YOUR_UPLOAD_KEY_FINGERPRINT",
        "PLAY_APP_SIGNING_FINGERPRINT"
      ]
    }
  }
]
```

**Get Play App Signing fingerprint:**
1. Play Console > Your App > Setup > App signing
2. Copy "SHA-256 certificate fingerprint" under "App signing key certificate"

### DAL Verification Checklist

- [ ] File accessible at `/.well-known/assetlinks.json`
- [ ] Returns HTTP 200 (not 301, 302, 404)
- [ ] Content-Type is `application/json`
- [ ] Valid JSON syntax (no trailing commas)
- [ ] Package name matches exactly
- [ ] Both upload and Play signing fingerprints included
- [ ] No auth required to access file
- [ ] HTTPS (not HTTP)
- [ ] Google verification tool passes

**Verification Command:**
```bash
# Quick verification
curl -s "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://your-app.com&relation=delegate_permission/common.handle_all_urls" | jq
```

---

## 8. BUBBLEWRAP SETUP

Bubblewrap is Google's official CLI tool for generating TWA projects.

### Installation

```bash
# Install Bubblewrap globally
npm install -g @anthropic-ai/anthropic bubblewrap

# Verify installation
bubblewrap --version
```

### Initialize TWA Project

```bash
# Create new TWA project
mkdir my-twa && cd my-twa
bubblewrap init --manifest https://your-app.com/manifest.json
```

### twa-manifest.json Configuration

Complete configuration file:

```json
{
  "packageId": "com.yourcompany.yourapp",
  "host": "your-app.com",
  "name": "Cash Delivery Management",
  "launcherName": "Cash",
  "display": "standalone",
  "themeColor": "#1a1a2e",
  "navigationColor": "#1a1a2e",
  "navigationColorDark": "#0d0d1a",
  "navigationDividerColor": "#1a1a2e",
  "navigationDividerColorDark": "#0d0d1a",
  "backgroundColor": "#ffffff",
  "enableNotifications": true,
  "startUrl": "/",
  "iconUrl": "https://your-app.com/icons/icon-512x512.png",
  "maskableIconUrl": "https://your-app.com/icons/icon-512x512-maskable.png",
  "splashScreenFadeOutDuration": 300,
  "signingKey": {
    "path": "./android.keystore",
    "alias": "android"
  },
  "appVersionCode": 1,
  "appVersionName": "1.0.0",
  "shortcuts": [
    {
      "name": "New Delivery",
      "shortName": "New",
      "url": "/deliveries/new",
      "icons": [
        {
          "src": "https://your-app.com/icons/shortcut-new.png",
          "sizes": "96x96"
        }
      ]
    }
  ],
  "generatorApp": "bubblewrap-cli",
  "webManifestUrl": "https://your-app.com/manifest.json",
  "fallbackType": "customtabs",
  "features": {
    "locationDelegation": {
      "enabled": true
    },
    "playBilling": {
      "enabled": false
    }
  },
  "alphaDependencies": {
    "enabled": false
  },
  "enableSiteSettingsShortcut": true,
  "isChromeOSOnly": false,
  "isMetaQuest": false,
  "fullScopeUrl": "https://your-app.com/",
  "minSdkVersion": 23,
  "orientation": "portrait",
  "fingerprints": [
    {
      "name": "release",
      "value": "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"
    }
  ]
}
```

### Build the APK

```bash
# Build debug APK
bubblewrap build

# Build release APK (signed)
bubblewrap build --release

# Output location
# ./app-release-signed.apk
# ./app-release-bundle.aab (for Play Store)
```

### Signing Configuration

**Create a new keystore:**

```bash
keytool -genkey -v -keystore android.keystore -alias android -keyalg RSA -keysize 2048 -validity 10000
```

**Important:** Store your keystore securely! If lost, you cannot update your app.

**Recommended storage:**
- Encrypted backup in secure cloud storage
- Password manager for keystore password
- Never commit to version control

---

## 9. PWABUILDER ALTERNATIVE

PWABuilder provides a visual interface for generating TWA packages.

### Step-by-Step Guide

1. **Visit PWABuilder**: https://www.pwabuilder.com/

2. **Enter Your URL**: Input your PWA URL and click "Start"

3. **Review Report**: PWABuilder analyzes your PWA and shows:
   - Manifest score
   - Service worker status
   - Security requirements
   - Suggested improvements

4. **Package for Android**:
   - Click "Package for stores"
   - Select "Android"
   - Choose "Google Play" (TWA)

5. **Configure Options**:

```yaml
Package ID: com.yourcompany.yourapp
App name: Cash Delivery Management
Short name: Cash
Display mode: Standalone
Status bar color: #1a1a2e
Navigation bar color: #1a1a2e
Splash screen color: #ffffff
Splash fade duration: 300ms
Enable notifications: Yes
Signing key: Upload or generate
```

6. **Generate and Download**:
   - Click "Generate"
   - Download the ZIP file containing:
     - `app-release-signed.apk`
     - `app-release-bundle.aab`
     - `assetlinks.json`
     - `store-listing/` assets

### PWABuilder vs Bubblewrap

| Feature | PWABuilder | Bubblewrap |
|---------|------------|------------|
| Interface | Visual/Web | CLI |
| Learning curve | Low | Medium |
| Customization | Limited | Full |
| CI/CD integration | Manual | Easy |
| Advanced features | Some | All |
| Updates | Re-upload | `bubblewrap update` |

**Recommendation:** Start with PWABuilder for first release, migrate to Bubblewrap for CI/CD automation.

---

## 10. PLAY STORE SUBMISSION

### Required Assets

| Asset | Dimensions | Format | Required |
|-------|------------|--------|----------|
| App icon | 512x512 | PNG (32-bit) | Yes |
| Feature graphic | 1024x500 | PNG/JPEG | Yes |
| Phone screenshots | 16:9 or 9:16 | PNG/JPEG | Yes (2-8) |
| Tablet screenshots | 16:9 or 9:16 | PNG/JPEG | If tablet support |
| TV banner | 1280x720 | PNG/JPEG | If TV support |

### App Icon Requirements

```
- 512x512 pixels
- 32-bit PNG (with alpha)
- No rounded corners (Play Store applies them)
- No badge or text (except brand name)
- Consistent with web app icon
```

### Feature Graphic

```
- 1024x500 pixels
- JPEG or 24-bit PNG (no alpha)
- Shows app branding and key features
- Text readable at small sizes
- No device frames
```

### Screenshots

```
- Minimum 2, maximum 8 per device type
- JPEG or 24-bit PNG
- Minimum 320px, maximum 3840px per side
- Aspect ratio: 16:9 or 9:16
- Show actual app functionality
- Include Hebrew/RTL content for RTL apps
```

### Store Listing Content

```yaml
Title: Cash - Delivery Management (max 30 characters)

Short description: (max 80 characters)
"Track deliveries, manage contacts, and monitor cash flow in real-time."

Full description: (max 4000 characters)
"""
Cash is a comprehensive delivery management system designed for businesses
that need to track deliveries, manage contacts, and monitor cash flow.

Key Features:
- Real-time delivery tracking
- Contact management
- Cash flow monitoring
- Offline support
- Hebrew RTL interface

Perfect for:
- Delivery services
- Small businesses
- Field sales teams
"""

Category: Business
Content rating: Everyone
Contact email: support@your-app.com
Privacy policy URL: https://your-app.com/privacy
```

### Submission Process

1. **Create Developer Account**: https://play.google.com/console (one-time $25 fee)

2. **Create App**:
   - Click "Create app"
   - Fill in app name, language, app/game, free/paid

3. **Set Up Store Listing**:
   - App details
   - Graphics
   - Categorization

4. **Complete App Content**:
   - Privacy policy
   - App access
   - Ads declaration
   - Content rating
   - Target audience
   - Data safety

5. **Upload AAB/APK**:
   - Production > Create new release
   - Upload `.aab` file (preferred) or `.apk`
   - Add release notes

6. **Review and Publish**:
   - Review summary
   - Click "Start rollout to Production"
   - Wait for review (typically 1-7 days)

---

## 11. UPDATES AND MAINTENANCE

### How TWA Updates Work

**Web Content (Automatic):**
- PWA updates are instant
- No Play Store review needed
- Users get new features immediately
- Service worker handles caching

**APK/AAB Updates (Manual):**
Required when changing:
- Package name
- Signing key
- Android-specific features
- Target SDK version
- App icon (in APK)

### When to Republish APK

| Change | Republish Needed |
|--------|------------------|
| Web content update | No |
| Bug fixes in PWA | No |
| New web features | No |
| Icon change | Yes |
| Name change | Yes |
| New Android permissions | Yes |
| Target SDK update | Yes |
| Play Billing integration | Yes |

### Version Management

```json
// twa-manifest.json
{
  "appVersionCode": 2,      // Integer, must increment
  "appVersionName": "1.1.0" // Semantic version for display
}
```

**Version code rules:**
- Must be unique
- Must be higher than previous
- Cannot be reused after rollback

### Update Process

```bash
# 1. Update twa-manifest.json version
# 2. Rebuild
bubblewrap build --release

# 3. Upload to Play Console
# Production > Create new release > Upload AAB

# 4. Add release notes
# 5. Review and rollout
```

### Staged Rollouts

```yaml
# Recommended rollout strategy:
Day 1: 10% of users
Day 3: 25% of users (if no issues)
Day 5: 50% of users
Day 7: 100% of users
```

---

## 12. TROUBLESHOOTING

### Digital Asset Links Verification Failed

**Symptoms:**
- Browser UI shows instead of fullscreen
- Address bar visible in app

**Solutions:**

1. **Verify assetlinks.json is accessible:**
```bash
curl -I https://your-app.com/.well-known/assetlinks.json
# Should return 200 OK with Content-Type: application/json
```

2. **Check fingerprint matches:**
```bash
# Get fingerprint from APK
keytool -printcert -jarfile app-release.apk | grep SHA256
# Compare with assetlinks.json
```

3. **Clear Chrome data:**
```bash
# On device: Settings > Apps > Chrome > Clear Data
# Then reinstall TWA
```

4. **Wait for propagation:**
- CDN cache may delay updates
- Wait 24-48 hours after changes

5. **Verify with Google's tool:**
https://developers.google.com/digital-asset-links/tools/generator

### Chrome Custom Tabs Fallback

Chrome Custom Tabs (CCT) is the fallback mechanism when full TWA cannot be used.

**When fallback activates:**
- Digital Asset Links verification fails
- Chrome not installed or outdated (< v72)
- First launch while DAL verification in progress
- Android version < 7.0 (API 24)
- Chrome disabled or restricted

**Detecting Fallback Mode in PWA:**

```javascript
// Detect if running in TWA vs Custom Tabs
function detectDisplayMode() {
  // Check if launched from TWA
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches;

  // Check for TWA-specific referrer
  const isTWA = document.referrer.includes('android-app://');

  // Check if browser UI is visible (Custom Tabs shows URL bar)
  const hasMinimalUI = window.matchMedia('(display-mode: minimal-ui)').matches;

  if (isStandalone && !hasMinimalUI) {
    return 'twa';  // Full TWA experience
  } else if (hasMinimalUI || isTWA) {
    return 'custom-tabs';  // Chrome Custom Tabs fallback
  }
  return 'browser';  // Regular browser
}

// Usage
const mode = detectDisplayMode();
if (mode === 'custom-tabs') {
  console.log('Running in Custom Tabs fallback mode');
  // Optionally show a banner explaining the reduced experience
}
```

### Splash Screen Issues

**White flash before splash:**
```json
// twa-manifest.json
{
  "splashScreenFadeOutDuration": 0,
  "backgroundColor": "#1a1a2e"  // Match app background
}
```

**Splash not showing:**
- Ensure `backgroundColor` is set in manifest
- Check `splashScreenFadeOutDuration` > 0 for animation
- Verify icon URL is accessible

### Service Worker Not Working

**Check registration:**
```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(registrations => {
    console.log('Registered service workers:', registrations);
  });
}
```

### Push Notifications Not Working

**Verify configuration:**
```json
// twa-manifest.json
{
  "enableNotifications": true
}
```

**Request permission in PWA:**
```javascript
const permission = await Notification.requestPermission();
if (permission === 'granted') {
  // Subscribe to push
}
```

---

## 13. CI/CD INTEGRATION

### GitHub Actions Workflow

```yaml
name: Build and Deploy TWA

on:
  push:
    tags:
      - 'v*'

jobs:
  build-twa:
    runs-on: [self-hosted, linux, x64, pop-os]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '24'

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Install Bubblewrap
        run: npm install -g @anthropic-ai/anthropic bubblewrap

      - name: Decode Keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android.keystore

      - name: Build TWA
        run: |
          bubblewrap build --release
        env:
          SIGNING_KEY_PASSWORD: ${{ secrets.SIGNING_KEY_PASSWORD }}
          SIGNING_STORE_PASSWORD: ${{ secrets.SIGNING_STORE_PASSWORD }}

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.yourcompany.yourapp
          releaseFiles: app-release-bundle.aab
          track: production
          status: completed
```

### Secrets Required

```bash
# Encode keystore for GitHub Secrets
base64 -i android.keystore -o keystore.txt
# Copy contents to ANDROID_KEYSTORE_BASE64 secret

# Other secrets:
SIGNING_KEY_PASSWORD=your-key-password
SIGNING_STORE_PASSWORD=your-store-password
PLAY_STORE_SERVICE_ACCOUNT=json-service-account-content
```

---

## 14. QUICK REFERENCE COMMANDS

```bash
# Initialize new TWA project
bubblewrap init --manifest https://your-app.com/manifest.json

# Build debug APK
bubblewrap build

# Build release AAB (for Play Store)
bubblewrap build --release

# Update existing project
bubblewrap update

# Validate Digital Asset Links
curl "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://your-app.com&relation=delegate_permission/common.handle_all_urls"

# Get keystore fingerprint
keytool -list -v -keystore android.keystore -alias android

# Verify APK signing
jarsigner -verify -verbose -certs app-release.apk

# Install APK on connected device
adb install app-release.apk
```

---

## 15. ANDROID COMPATIBILITY QUICK REFERENCE

| Requirement | Minimum | Recommended | Notes |
|-------------|---------|-------------|-------|
| Android Version | 5.0 (API 21) | 7.0 (API 24) | Full TWA requires 7.0+ |
| Chrome Version | 45+ | 72+ | Full TWA requires 72+ |
| minSdkVersion | 21 | 23 | Balance reach vs features |
| targetSdkVersion | 33 (2024) | Latest | Required by Play Store |

---

## 16. RELATED DOCUMENTS

- [PWA Master Checklist](./pwa-master-checklist.md)
- [PWA Analytics](./pwa-analytics.md)
- [Offline-First Patterns](./offline-first-reference.md)
- [CI/CD Reference](./cicd-reference.md)

---

## 17. VERIFICATION SEAL

```
OMEGA_v24.5.0 | PWA_TWA_PLAY_STORE
Gates: 7 | Commands: 8 | Phase: 2.4
DIGITAL_ASSET_LINKS | BUBBLEWRAP | PWABUILDER
ANDROID_COMPATIBILITY | PLAY_STORE_SUBMISSION
```

<!-- PWA-EXPERT/TWA v24.5.0 | Updated: 2026-02-19 -->

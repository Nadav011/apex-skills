# PWA Edge Cases - WebViews, OEM, Network, Storage, Time

> **v24.5.0 SINGULARITY FORGE** | PWA Expert Skill
> **Critical for:** Real-world production reliability

---

## GATE PWA-15: WebView Escape (In-App Browsers)

### The WebView Problem

**CRITICAL:** PWA features DON'T WORK in social media in-app browsers!

When users open your link from Facebook, Instagram, TikTok, etc., they're in a WebView - NOT a real browser. Most PWA features are broken or unavailable.

| Browser | User Agent Pattern | PWA Support | Notes |
|---------|-------------------|-------------|-------|
| Facebook | `FBAN\|FBAV` | NO install, NO push | Very common |
| Instagram | `Instagram` | NO install, NO push | Very common |
| TikTok | `BytedanceWebview\|TikTok` | NO install | Growing |
| WeChat | `MicroMessenger` | NO install | China |
| Line | `Line\/` | Limited | Asia |
| LinkedIn | `LinkedInApp` | Limited | B2B |
| Twitter/X | `Twitter` | Limited | |
| Snapchat | `Snapchat` | NO | |
| Pinterest | `Pinterest` | Limited | |
| Telegram | `TelegramBot` | NO install | |
| WhatsApp | (Opens system browser) | OK | Good! |

### WebView/In-App Browser Detection

```typescript
interface InAppBrowserInfo {
  isInAppBrowser: boolean;
  browser: string | null;
  canInstall: boolean;
  canPush: boolean;
  escapeUrl: string | null;
}

function detectInAppBrowser(): InAppBrowserInfo {
  const ua = navigator.userAgent;

  const browsers: Record<string, {
    pattern: RegExp;
    canInstall: boolean;
    canPush: boolean;
  }> = {
    facebook: {
      pattern: /FBAN|FBAV/i,
      canInstall: false,
      canPush: false,
    },
    instagram: {
      pattern: /Instagram/i,
      canInstall: false,
      canPush: false,
    },
    tiktok: {
      pattern: /BytedanceWebview|TikTok/i,
      canInstall: false,
      canPush: false,
    },
    wechat: {
      pattern: /MicroMessenger/i,
      canInstall: false,
      canPush: false,
    },
    line: {
      pattern: /Line\//i,
      canInstall: false,
      canPush: false,
    },
    linkedin: {
      pattern: /LinkedInApp/i,
      canInstall: false,
      canPush: false,
    },
    twitter: {
      pattern: /Twitter/i,
      canInstall: false,
      canPush: false,
    },
    snapchat: {
      pattern: /Snapchat/i,
      canInstall: false,
      canPush: false,
    },
    pinterest: {
      pattern: /Pinterest/i,
      canInstall: false,
      canPush: false,
    },
    telegram: {
      pattern: /TelegramBot/i,
      canInstall: false,
      canPush: false,
    },
  };

  for (const [name, config] of Object.entries(browsers)) {
    if (config.pattern.test(ua)) {
      return {
        isInAppBrowser: true,
        browser: name,
        canInstall: config.canInstall,
        canPush: config.canPush,
        escapeUrl: generateEscapeUrl(),
      };
    }
  }

  return {
    isInAppBrowser: false,
    browser: null,
    canInstall: true,
    canPush: true,
    escapeUrl: null,
  };
}

// Generate URL that forces opening in system browser
function generateEscapeUrl(): string {
  const currentUrl = window.location.href;

  // Different escape methods for different platforms
  if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
    // iOS: Use x-safari scheme or googlechrome scheme
    return `googlechrome://${currentUrl.replace(/^https?:\/\//, '')}`;
  }

  // Android: Use intent URL
  const intentUrl = `intent://${currentUrl.replace(/^https?:\/\//, '')}#Intent;scheme=https;package=com.android.chrome;end`;
  return intentUrl;
}

// Alternative: Copy URL to clipboard
function copyUrlToClipboard(): Promise<boolean> {
  return navigator.clipboard.writeText(window.location.href)
    .then(() => true)
    .catch(() => false);
}
```

### "Open in Browser" UI Component

```typescript
// React component for in-app browser escape
function InAppBrowserBanner() {
  const [browserInfo, setBrowserInfo] = useState<InAppBrowserInfo | null>(null);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    const info = detectInAppBrowser();
    if (info.isInAppBrowser) {
      setBrowserInfo(info);
    }
  }, []);

  if (!browserInfo || dismissed) {
    return null;
  }

  const handleOpenInBrowser = async () => {
    // Try to open in system browser
    if (browserInfo.escapeUrl) {
      window.location.href = browserInfo.escapeUrl;
    }

    // Fallback: Show instructions
    setTimeout(() => {
      showManualInstructions();
    }, 500);
  };

  const handleCopyUrl = async () => {
    const success = await copyUrlToClipboard();
    if (success) {
      alert('הקישור הועתק! הדבק אותו בדפדפן Chrome או Safari');
    }
  };

  return (
    <div className="fixed top-0 inset-x-0 z-50 bg-yellow-500 text-yellow-900 p-4">
      <div className="flex items-center justify-between gap-4">
        <div className="flex-1">
          <p className="font-medium text-sm">
            לחוויה מלאה, פתח באפליקציית הדפדפן
          </p>
          <p className="text-xs opacity-80">
            חלק מהתכונות לא זמינות ב-{browserInfo.browser}
          </p>
        </div>

        <div className="flex gap-2">
          <button
            onClick={handleOpenInBrowser}
            className="px-3 py-1.5 bg-yellow-900 text-yellow-50 rounded-lg text-sm font-medium"
          >
            פתח בדפדפן
          </button>
          <button
            onClick={handleCopyUrl}
            className="px-3 py-1.5 border border-yellow-900 rounded-lg text-sm"
          >
            העתק קישור
          </button>
          <button
            onClick={() => setDismissed(true)}
            className="p-1.5"
            aria-label="סגור"
          >
            <XIcon className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}

// Manual instructions modal
function ManualInstructionsModal({ browser }: { browser: string }) {
  const instructions: Record<string, string[]> = {
    facebook: [
      'לחץ על שלוש הנקודות (...) בפינה',
      'בחר "פתח בדפדפן" או "Open in Browser"',
    ],
    instagram: [
      'לחץ על שלוש הנקודות (...) בפינה',
      'בחר "פתח בדפדפן" או "Open in Browser"',
    ],
    tiktok: [
      'לחץ על שלוש הנקודות (...) בפינה',
      'בחר "פתח בדפדפן" או "Open in Browser"',
    ],
    default: [
      'חפש את תפריט האפשרויות (⋮ או ...)',
      'בחר "פתח בדפדפן" או "Open in Browser"',
      'או העתק את הקישור והדבק ב-Chrome/Safari',
    ],
  };

  const steps = instructions[browser] || instructions.default;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white rounded-xl p-6 m-4 max-w-sm">
        <h2 className="text-lg font-bold mb-4">איך לפתוח בדפדפן</h2>
        <ol className="space-y-3 text-sm">
          {steps.map((step, i) => (
            <li key={i} className="flex gap-3">
              <span className="flex-shrink-0 w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center text-xs">
                {i + 1}
              </span>
              <span>{step}</span>
            </li>
          ))}
        </ol>
      </div>
    </div>
  );
}
```

---

## GATE PWA-16: OEM Battery Optimization

### The Problem

Android OEMs (Samsung, Xiaomi, Huawei, etc.) add aggressive battery optimization that KILLS background processes - including Service Workers!

| OEM | Severity | Issue | Settings Path |
|-----|----------|-------|---------------|
| Samsung | CRITICAL | "Sleeping apps" after 3 days | Settings > Battery > Background usage limits |
| Xiaomi | CRITICAL | MIUI kills everything | Settings > Apps > Manage apps > [App] > Battery saver |
| Huawei | CRITICAL | EMUI very aggressive | Settings > Battery > App launch |
| OnePlus | HIGH | OxygenOS optimization | Settings > Battery > Battery optimization |
| Oppo | HIGH | ColorOS restrictions | Settings > Battery > More settings |
| Vivo | HIGH | FunTouchOS restrictions | Settings > Battery > Background power consumption |
| Realme | HIGH | Same as Oppo | Settings > Battery > App Quick Freeze |
| Honor | HIGH | Same as Huawei | Settings > Battery > App launch |

### OEM Detection

```typescript
interface OEMInfo {
  manufacturer: string;
  model: string;
  isProblematic: boolean;
  severity: 'critical' | 'high' | 'medium' | 'low';
  settingsPath: string;
  instructions: string[];
}

function detectOEM(): OEMInfo | null {
  // navigator.userAgentData is more reliable when available
  const uaData = (navigator as any).userAgentData;

  let manufacturer = '';
  let model = '';

  if (uaData?.platform === 'Android') {
    // Modern API (Chrome 90+)
    manufacturer = uaData.brands?.find((b: { brand: string }) =>
      /samsung|xiaomi|huawei|oppo|vivo|oneplus|realme|honor/i.test(b.brand)
    )?.brand || '';
  }

  // Fallback to user agent parsing
  const ua = navigator.userAgent.toLowerCase();

  const oemPatterns: Record<string, {
    pattern: RegExp;
    severity: 'critical' | 'high' | 'medium' | 'low';
    settingsPath: string;
    instructions: string[];
  }> = {
    samsung: {
      pattern: /samsung|sm-[a-z]/i,
      severity: 'critical',
      settingsPath: 'הגדרות > סוללה > מגבלות שימוש ברקע',
      instructions: [
        'פתח את הגדרות המכשיר',
        'לחץ על "סוללה"',
        'לחץ על "מגבלות שימוש ברקע"',
        'הסר את האפליקציה מרשימת "אפליקציות ישנות"',
        'או: אפליקציות > [האפליקציה] > סוללה > "ללא הגבלה"',
      ],
    },
    xiaomi: {
      pattern: /xiaomi|redmi|poco|miui/i,
      severity: 'critical',
      settingsPath: 'הגדרות > אפליקציות > ניהול אפליקציות',
      instructions: [
        'פתח את הגדרות המכשיר',
        'לחץ על "אפליקציות" > "ניהול אפליקציות"',
        'חפש את האפליקציה ולחץ עליה',
        'לחץ על "חיסכון בסוללה" > "ללא הגבלות"',
        'הפעל "הפעלה אוטומטית"',
        'בתפריט "אבטחה": סוללה > ללא הגבלות',
      ],
    },
    huawei: {
      pattern: /huawei|honor|hms/i,
      severity: 'critical',
      settingsPath: 'הגדרות > סוללה > הפעלת אפליקציות',
      instructions: [
        'פתח את הגדרות המכשיר',
        'לחץ על "סוללה"',
        'לחץ על "הפעלת אפליקציות"',
        'מצא את האפליקציה והעבר ל"ידני"',
        'הפעל: הפעלה אוטומטית, פעילות משנית, פעילות ברקע',
      ],
    },
    oneplus: {
      pattern: /oneplus/i,
      severity: 'high',
      settingsPath: 'הגדרות > סוללה > אופטימיזציית סוללה',
      instructions: [
        'פתח את הגדרות המכשיר',
        'לחץ על "סוללה"',
        'לחץ על "אופטימיזציית סוללה"',
        'מצא את האפליקציה > "אל תבצע אופטימיזציה"',
      ],
    },
    oppo: {
      pattern: /oppo|coloros/i,
      severity: 'high',
      settingsPath: 'הגדרות > סוללה > הגדרות נוספות',
      instructions: [
        'פתח את הגדרות המכשיר',
        'לחץ על "סוללה"',
        'לחץ על "הגדרות נוספות" או "ניהול אפליקציות"',
        'מצא את האפליקציה > "אפשר פעילות ברקע"',
      ],
    },
    vivo: {
      pattern: /vivo/i,
      severity: 'high',
      settingsPath: 'הגדרות > סוללה > צריכת חשמל ברקע',
      instructions: [
        'פתח את הגדרות המכשיר',
        'לחץ על "סוללה"',
        'לחץ על "צריכת חשמל גבוהה ברקע"',
        'הוסף את האפליקציה לרשימה',
      ],
    },
    realme: {
      pattern: /realme/i,
      severity: 'high',
      settingsPath: 'הגדרות > סוללה > הקפאה מהירה',
      instructions: [
        'פתח את הגדרות המכשיר',
        'לחץ על "סוללה"',
        'לחץ על "הקפאה מהירה של אפליקציות"',
        'הסר את האפליקציה מהרשימה',
      ],
    },
  };

  for (const [name, config] of Object.entries(oemPatterns)) {
    if (config.pattern.test(ua)) {
      // Try to extract model
      const modelMatch = ua.match(/(?:sm-[a-z0-9]+|[a-z]+-[a-z0-9]+)/i);
      model = modelMatch?.[0] || '';

      return {
        manufacturer: name,
        model,
        isProblematic: true,
        severity: config.severity,
        settingsPath: config.settingsPath,
        instructions: config.instructions,
      };
    }
  }

  return null;
}
```

### OEM Battery Settings UI

```typescript
// React component for OEM battery optimization guidance
function OEMBatteryGuide() {
  const [oemInfo, setOemInfo] = useState<OEMInfo | null>(null);
  const [showGuide, setShowGuide] = useState(false);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    // Only check on Android
    if (!/Android/i.test(navigator.userAgent)) return;

    const info = detectOEM();
    if (info?.isProblematic) {
      setOemInfo(info);

      // Check if already dismissed
      const key = `oem-guide-dismissed-${info.manufacturer}`;
      const wasDismissed = localStorage.getItem(key);
      if (!wasDismissed) {
        // Show after user has been in app for a bit
        setTimeout(() => setShowGuide(true), 30000);
      }
    }
  }, []);

  const handleDismiss = () => {
    setShowGuide(false);
    setDismissed(true);

    if (oemInfo) {
      localStorage.setItem(`oem-guide-dismissed-${oemInfo.manufacturer}`, 'true');
    }
  };

  const handleNeverShow = () => {
    handleDismiss();
    localStorage.setItem('oem-guide-never-show', 'true');
  };

  if (!showGuide || !oemInfo || dismissed) {
    return null;
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50">
      <div className="bg-white rounded-t-xl sm:rounded-xl p-6 m-0 sm:m-4 w-full max-w-md max-h-[80vh] overflow-y-auto">
        <div className="flex items-start justify-between mb-4">
          <div>
            <h2 className="text-lg font-bold">הגדרות סוללה חשובות</h2>
            <p className="text-sm text-muted-foreground">
              מכשיר {oemInfo.manufacturer} שלך עלול להפסיק התראות ברקע
            </p>
          </div>
          <button onClick={handleDismiss} className="p-1">
            <XIcon className="w-5 h-5" />
          </button>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 mb-4">
          <p className="text-sm text-yellow-800">
            <strong>נתיב:</strong> {oemInfo.settingsPath}
          </p>
        </div>

        <ol className="space-y-3 mb-6">
          {oemInfo.instructions.map((step, i) => (
            <li key={i} className="flex gap-3 text-sm">
              <span className="flex-shrink-0 w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center text-xs font-medium">
                {i + 1}
              </span>
              <span>{step}</span>
            </li>
          ))}
        </ol>

        <div className="flex flex-col gap-2">
          <button
            onClick={handleDismiss}
            className="w-full py-3 bg-primary text-white rounded-lg font-medium"
          >
            הבנתי, אעשה את זה
          </button>
          <button
            onClick={handleNeverShow}
            className="w-full py-2 text-sm text-muted-foreground"
          >
            אל תציג שוב
          </button>
        </div>
      </div>
    </div>
  );
}
```

### Samsung DeX Mode Detection

```typescript
// Samsung DeX changes the user experience significantly
function isSamsungDeX(): boolean {
  const ua = navigator.userAgent;

  // In DeX mode, UA contains "SamsungBrowser" but NOT "SAMSUNG"
  // Regular Samsung phone has both
  const isSamsungBrowser = /SamsungBrowser/i.test(ua);
  const hasSamsungDevice = /SAMSUNG/i.test(ua);

  // Also check screen size - DeX is typically large screen
  const isLargeScreen = window.innerWidth > 1200;

  return isSamsungBrowser && !hasSamsungDevice && isLargeScreen;
}

// Adjust layout for DeX
function useDeXMode() {
  const [isDeX, setIsDeX] = useState(false);

  useEffect(() => {
    setIsDeX(isSamsungDeX());

    // Re-check on resize (user might connect/disconnect DeX)
    const handleResize = () => {
      setIsDeX(isSamsungDeX());
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return isDeX;
}
```

---

## Network Edge Cases

### GATE PWA-17: navigator.onLine Unreliability (CRITICAL)

> **9D Alignment:** D1 (Type Safety), D2 (Performance), D3 (Security), D4 (UX)
> **Laws:** #1 (ZERO TRUST - never trust browser APIs blindly)
> **Severity:** CRITICAL | **Fix Time:** 15 min | **Impact:** User sees false "offline" errors

**CRITICAL BUG:** `navigator.onLine` is UNRELIABLE! It can be stale or incorrect.

Common scenarios where `navigator.onLine` lies:
- Returns `true` but WiFi has no internet (captive portal, router issue)
- Returns `false` but cellular data works fine
- Stays stale after network changes
- Different behavior on iOS vs Android vs Desktop
- Returns `true` after losing connection (up to 30s stale on some devices)

**THE FIX:** Always verify with an actual fetch request!

```typescript
/**
 * NEVER trust navigator.onLine alone!
 * Always do a real connectivity check.
 */
export async function checkRealConnectivity(): Promise<boolean> {
  // SSR safety check
  if (typeof window === "undefined") {
    return true;
  }

  try {
    // CRITICAL: Don't return early if navigator.onLine is false!
    // It can be wrong - always do the actual fetch.

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    // Fetch a small, always-available resource with cache-busting
    const response = await fetch(`/logo.svg?_=${Date.now()}`, {
      method: "HEAD",
      cache: "no-store",
      mode: "same-origin",
      signal: controller.signal,
    });

    clearTimeout(timeoutId);
    return response.ok;
  } catch {
    return false;
  }
}

// React hook with periodic verification
function useRealNetworkStatus() {
  const [isOnline, setIsOnline] = useState(true);
  const verifyingRef = useRef(false);

  const verifyConnectivity = async () => {
    if (verifyingRef.current) return;
    verifyingRef.current = true;

    try {
      const reallyOnline = await checkRealConnectivity();
      const browserOnline = navigator.onLine;

      // CORRECT the browser's stale state
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
    const intervalId = setInterval(verifyConnectivity, 10000);

    // Also verify on browser events (but don't trust them alone)
    const handleOnline = () => verifyConnectivity();
    const handleOffline = () => verifyConnectivity();

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      clearInterval(intervalId);
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, [verifyConnectivity]);

  return isOnline;
}
```

**Offline Page Best Practice:**

```html
<!-- public/offline.html -->
<script>
  // Don't just show "no internet" - verify first!
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

  // Check immediately and redirect if we have connectivity
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

**Test Patterns (Vitest):**

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { checkRealConnectivity } from './networkUtils';

describe('PWA-17: Real Connectivity Check', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('should return true when fetch succeeds', async () => {
    global.fetch = vi.fn().mockResolvedValue({ ok: true });
    const result = await checkRealConnectivity();
    expect(result).toBe(true);
  });

  it('should return false when fetch fails', async () => {
    global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));
    const result = await checkRealConnectivity();
    expect(result).toBe(false);
  });

  it('should timeout after 5 seconds', async () => {
    global.fetch = vi.fn().mockImplementation(() => new Promise(() => {}));
    const resultPromise = checkRealConnectivity();
    vi.advanceTimersByTime(5000);
    const result = await resultPromise;
    expect(result).toBe(false);
  });

  it('should use cache-busting query param', async () => {
    global.fetch = vi.fn().mockResolvedValue({ ok: true });
    await checkRealConnectivity();
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringMatching(/\/logo\.svg\?_=\d+/),
      expect.any(Object)
    );
  });

  it('should NOT trust navigator.onLine when false but fetch succeeds', async () => {
    Object.defineProperty(navigator, 'onLine', { value: false, configurable: true });
    global.fetch = vi.fn().mockResolvedValue({ ok: true });
    const result = await checkRealConnectivity();
    expect(result).toBe(true); // Real check overrides browser state
  });
});
```

**Verification Checklist:**

- [ ] `checkRealConnectivity()` function exists
- [ ] Function does NOT early-return based on `navigator.onLine`
- [ ] Timeout is implemented (5s max)
- [ ] Cache-busting query parameter added to fetch URL
- [ ] Hook cleans up interval on unmount
- [ ] Offline page also verifies real connectivity before showing error

---

### GATE PWA-18: Service Worker Double Reload Prevention (CRITICAL)

> **9D Alignment:** D2 (Performance), D4 (UX), D5 (Stability)
> **Laws:** #4 (ROI - prevent wasted reloads)
> **Severity:** CRITICAL | **Fix Time:** 10 min | **Impact:** App reloads twice unexpectedly

**BUG:** During SW updates, BOTH `SW_UPDATED` message AND `controllerchange` event can fire, causing **double reloads**!

```typescript
// ❌ BAD: Can cause double reload
navigator.serviceWorker.addEventListener("message", (event) => {
  if (event.data?.type === "SW_UPDATED") {
    window.location.reload(); // First reload
  }
});

navigator.serviceWorker.addEventListener("controllerchange", () => {
  window.location.reload(); // Second reload!
});
```

**THE FIX:** Use a reload guard:

```typescript
// IMPROVED: sessionStorage-based cooldown (survives in-page state resets)
const RELOAD_GUARD_KEY = "sw-reload-ts";
const RELOAD_COOLDOWN_MS = 5000; // 5 seconds between reloads

function reloadForUpdate(reason: string): void {
  const lastReload = Number(sessionStorage.getItem(RELOAD_GUARD_KEY) || "0");
  const now = Date.now();

  if (now - lastReload < RELOAD_COOLDOWN_MS) {
    // Cooldown active — skip this reload
    return;
  }

  sessionStorage.setItem(RELOAD_GUARD_KEY, String(now));
  window.location.reload();
}

function setupServiceWorkerUpdates(): void {
  if (!("serviceWorker" in navigator)) return;

  // Listen for SW_UPDATED messages (informational only — no reload here)
  navigator.serviceWorker.addEventListener("message", (event) => {
    if (event.data?.type === "SW_UPDATED") {
      // Log but don't reload — controllerchange handles it
    }
  });

  // Check for updates on page load + every 5 minutes
  navigator.serviceWorker.ready.then((registration) => {
    registration.update().catch(() => {});
    setInterval(() => {
      registration.update().catch(() => {});
    }, 300000); // 5 minutes
  });

  // Handle controller change (new SW activated) — auto-reload
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    reloadForUpdate("controllerchange");
  });
}
```

**Alternative Pattern: Debounced Reload**

```typescript
// Alternative: sessionStorage cooldown with cleanup
// The cooldown approach is superior to boolean guards because:
// 1. Survives in-page state resets (boolean gets lost)
// 2. Time-based — allows reload after cooldown expires
// 3. Works across SW update + controllerchange race
// 4. Cleanup handled via pagehide event listener
```

**Test Patterns (Vitest):**

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

describe('PWA-18: SW Double Reload Prevention', () => {
  let reloadSpy: ReturnType<typeof vi.spyOn>;
  let isReloading: boolean;

  beforeEach(() => {
    isReloading = false;
    // Mock window.location.reload
    reloadSpy = vi.fn();
    Object.defineProperty(window, 'location', {
      value: { reload: reloadSpy },
      writable: true,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should only reload once when both events fire', () => {
    const safeReload = (reason: string) => {
      if (isReloading) return;
      isReloading = true;
      window.location.reload();
    };

    // Simulate both events firing
    safeReload('SW_UPDATED');
    safeReload('controllerchange');

    expect(reloadSpy).toHaveBeenCalledTimes(1);
  });

  it('should allow reload after page actually reloads', () => {
    let reloadCount = 0;
    const safeReload = () => {
      if (isReloading) return;
      isReloading = true;
      reloadCount++;
    };

    safeReload();
    expect(reloadCount).toBe(1);

    // Simulate new page load
    isReloading = false;
    safeReload();
    expect(reloadCount).toBe(2);
  });
});
```

**Verification Checklist:**

- [ ] `RELOAD_GUARD_KEY` constant defined for sessionStorage key
- [ ] `RELOAD_COOLDOWN_MS` set to 5000ms
- [ ] `reloadForUpdate()` checks sessionStorage timestamp before reloading
- [ ] Timestamp written to sessionStorage BEFORE `window.location.reload()`
- [ ] `controllerchange` is the only event that triggers reload
- [ ] `SW_UPDATED` message is logged but does NOT trigger reload
- [ ] SW update polling runs every 5 minutes via `registration.update()`
- [ ] Cleanup via `pagehide` event clears polling interval

---

### GATE PWA-19: Dark Mode Flash Prevention (FOUC)

> **9D Alignment:** D4 (UX), D2 (Performance - no JS needed for initial state)
> **Laws:** #6 (RESPONSIVE - visual consistency)
> **Severity:** MEDIUM | **Fix Time:** 5 min | **Impact:** Visual flash on page load

**BUG:** Initial page load shows light mode briefly before dark mode kicks in.

**THE FIX:** Add `class="dark"` to HTML tag in index.html:

```html
<!-- index.html -->
<html lang="he" dir="rtl" class="dark">
```

**Why this works:**
- CSS applies immediately before React hydrates
- No JavaScript needed for initial dark state
- Theme toggle can then add/remove the class

**Full Solution with Theme Persistence:**

```html
<!-- In <head> - runs before body renders -->
<script>
  // Apply saved theme immediately to prevent flash
  (function() {
    const theme = localStorage.getItem('theme');
    if (theme === 'dark' || (!theme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      document.documentElement.classList.add('dark');
    }
  })();
</script>
```

```typescript
// React theme hook
function useTheme() {
  const [theme, setTheme] = useState<'light' | 'dark'>(() => {
    if (typeof window === 'undefined') return 'dark';
    return document.documentElement.classList.contains('dark') ? 'dark' : 'light';
  });

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    document.documentElement.classList.toggle('dark', newTheme === 'dark');
    localStorage.setItem('theme', newTheme);
  };

  return { theme, toggleTheme };
}
```

**Vite/React Specific Solution:**

```html
<!-- index.html for Vite apps -->
<!DOCTYPE html>
<html lang="he" dir="rtl" class="dark">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <!-- Theme script MUST be in head, before body renders -->
    <script>
      // Check localStorage for saved theme preference
      // This runs synchronously before any rendering
      (function() {
        try {
          const savedTheme = localStorage.getItem('theme');
          const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

          if (savedTheme === 'light') {
            document.documentElement.classList.remove('dark');
          } else if (savedTheme === 'dark' || prefersDark) {
            document.documentElement.classList.add('dark');
          }
        } catch (e) {
          // localStorage may be unavailable (private browsing)
          // Default to dark mode if class already present
        }
      })();
    </script>
    <!-- CSS must come after theme script -->
    <link rel="stylesheet" href="/src/index.css" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

**Test Patterns (Playwright E2E):**

```typescript
import { test, expect } from '@playwright/test';

test.describe('PWA-19: Dark Mode Flash Prevention', () => {
  test('should NOT flash light mode on initial load', async ({ page }) => {
    // Clear localStorage to simulate fresh visit
    await page.evaluate(() => localStorage.clear());

    // Navigate with network throttling to exaggerate any flash
    await page.goto('/', { waitUntil: 'domcontentloaded' });

    // Check HTML has dark class immediately
    const htmlClass = await page.evaluate(() =>
      document.documentElement.classList.contains('dark')
    );
    expect(htmlClass).toBe(true);
  });

  test('should respect saved light theme preference', async ({ page }) => {
    await page.evaluate(() => localStorage.setItem('theme', 'light'));
    await page.goto('/', { waitUntil: 'domcontentloaded' });

    const htmlClass = await page.evaluate(() =>
      document.documentElement.classList.contains('dark')
    );
    expect(htmlClass).toBe(false);
  });

  test('should respect system dark mode preference', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.evaluate(() => localStorage.removeItem('theme'));
    await page.goto('/', { waitUntil: 'domcontentloaded' });

    const htmlClass = await page.evaluate(() =>
      document.documentElement.classList.contains('dark')
    );
    expect(htmlClass).toBe(true);
  });
});
```

**Verification Checklist:**

- [ ] `index.html` has `class="dark"` on `<html>` tag (for dark-first apps)
- [ ] Theme detection script is in `<head>`, BEFORE any CSS or body
- [ ] Script is synchronous (no async/defer)
- [ ] Script handles localStorage errors (private browsing)
- [ ] CSS file loads AFTER theme script
- [ ] React hook reads initial state from DOM, not localStorage
- [ ] No visible flash when testing on slow 3G

---

### GATE PWA-20: Persistent Storage Request (MEDIUM)

> **9D Alignment:** D2 (Performance), D4 (UX - data persistence), D3 (Security - data integrity)
> **Laws:** #1 (ZERO TRUST - verify storage is persisted), #4 (ROI - prevent data loss)
> **Severity:** MEDIUM | **Fix Time:** 10 min | **Impact:** IndexedDB data evicted under storage pressure

**BUG:** Browsers can evict IndexedDB data when device is under storage pressure. Users lose offline data without warning!

**THE FIX:** Request persistent storage on app startup to prevent eviction:

```typescript
// lib/pwa/persistentStorage.ts

/**
 * PWA-20: Request persistent storage to prevent browser eviction
 *
 * Browsers can evict IndexedDB data under storage pressure (especially on iOS).
 * Persistent storage tells the browser "this data is important, don't delete it."
 *
 * Call on app startup after user engagement (first interaction or after login).
 */
export async function requestPersistentStorage(): Promise<boolean> {
  // Feature detection
  if (!navigator.storage?.persist) {
    console.warn('[PWA-20] Storage API not supported');
    return false;
  }

  // Check if already persisted
  const isPersisted = await navigator.storage.persisted();
  if (isPersisted) {
    console.log('[PWA-20] Storage already persisted');
    return true;
  }

  // Request persistence
  // Note: Chrome auto-grants for installed PWAs, Safari may prompt user
  const granted = await navigator.storage.persist();
  console.log(`[PWA-20] Persistent storage ${granted ? 'granted' : 'denied'}`);

  return granted;
}

/**
 * Check current storage persistence status
 */
export async function isStoragePersisted(): Promise<boolean> {
  if (!navigator.storage?.persisted) {
    return false;
  }
  return navigator.storage.persisted();
}

/**
 * Get storage estimate with persistence info
 */
export async function getStorageInfo(): Promise<{
  usage: number;
  quota: number;
  usagePercent: number;
  isPersisted: boolean;
} | null> {
  if (!navigator.storage?.estimate) {
    return null;
  }

  const [estimate, isPersisted] = await Promise.all([
    navigator.storage.estimate(),
    isStoragePersisted(),
  ]);

  const usage = estimate.usage ?? 0;
  const quota = estimate.quota ?? 0;

  return {
    usage,
    quota,
    usagePercent: quota > 0 ? (usage / quota) * 100 : 0,
    isPersisted,
  };
}
```

**React Integration:**

```typescript
// hooks/usePersistentStorage.ts
import { useEffect, useState } from 'react';
import { requestPersistentStorage, getStorageInfo } from '@/lib/pwa/persistentStorage';

export function usePersistentStorage() {
  const [isPersisted, setIsPersisted] = useState<boolean | null>(null);
  const [storageInfo, setStorageInfo] = useState<{
    usage: number;
    quota: number;
    usagePercent: number;
  } | null>(null);

  useEffect(() => {
    async function init() {
      // Request persistence on mount (after user engagement)
      const persisted = await requestPersistentStorage();
      setIsPersisted(persisted);

      // Get storage info
      const info = await getStorageInfo();
      if (info) {
        setStorageInfo({
          usage: info.usage,
          quota: info.quota,
          usagePercent: info.usagePercent,
        });
      }
    }

    init();
  }, []);

  return { isPersisted, storageInfo };
}

// Usage in App.tsx
function App() {
  const { isPersisted, storageInfo } = usePersistentStorage();

  // Show warning if storage not persisted and usage > 50%
  const showWarning = !isPersisted && storageInfo && storageInfo.usagePercent > 50;

  return (
    <>
      {showWarning && (
        <Banner variant="warning">
          נתונים עשויים להימחק. התקן את האפליקציה לשמירה קבועה.
        </Banner>
      )}
      {/* ... */}
    </>
  );
}
```

**When to Request:**
- After app install (PWA installed)
- After user login (engaged user)
- After first data sync (has important data)
- NOT on first visit (may be denied)

**Verification Checklist:**

- [ ] `requestPersistentStorage()` called on app startup
- [ ] Called after user engagement, not immediately on first visit
- [ ] Handles `navigator.storage` not being available
- [ ] Checks `persisted()` before requesting
- [ ] Logs result for debugging
- [ ] Shows UI warning if not persisted and high storage usage

---

### GATE PWA-21: In-App Browser Detection (CRITICAL)

> **9D Alignment:** D4 (UX), D2 (Performance), D3 (Security)
> **Laws:** #1 (ZERO TRUST - detect environment), #6 (RESPONSIVE - adapt to platform)
> **Severity:** CRITICAL | **Fix Time:** 30 min | **Impact:** PWA features broken in social app WebViews

**BUG:** When users open your PWA link from Facebook, Instagram, TikTok, etc., it opens in a crippled in-app browser (WebView) that:
- Cannot install PWA
- May not support Service Workers properly
- Has limited storage
- Has different cookie behavior
- Cannot be "added to home screen"

**THE FIX:** Detect in-app browsers and show escape UI:

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
  { pattern: /Snapchat/i, name: 'Snapchat' },
  { pattern: /WeChat|MicroMessenger/i, name: 'WeChat' },
  { pattern: /Telegram/i, name: 'Telegram' },
  { pattern: /WhatsApp/i, name: 'WhatsApp' },
] as const;

/**
 * PWA-21: Detect if running in an in-app browser (WebView)
 *
 * Social apps open links in their own crippled browsers.
 * PWA features won't work properly - need to escape to real browser.
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
 * Opens the current URL in Chrome instead of WebView
 */
export function getChromeIntentUrl(url: string = window.location.href): string {
  const encodedUrl = encodeURIComponent(url);
  return `intent://${url.replace(/^https?:\/\//, '')}#Intent;scheme=https;package=com.android.chrome;end`;
}

/**
 * Copy URL to clipboard
 */
export async function copyUrlToClipboard(url: string = window.location.href): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(url);
    return true;
  } catch {
    // Fallback for older browsers
    const textarea = document.createElement('textarea');
    textarea.value = url;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    const success = document.execCommand('copy');
    document.body.removeChild(textarea);
    return success;
  }
}
```

**React Component:**

```tsx
// components/InAppBrowserBanner.tsx
import { useEffect, useState } from 'react';
import {
  detectInAppBrowser,
  getChromeIntentUrl,
  copyUrlToClipboard,
} from '@/lib/pwa/inAppBrowserDetection';

export function InAppBrowserBanner() {
  const [browserInfo, setBrowserInfo] = useState<ReturnType<typeof detectInAppBrowser> | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    setBrowserInfo(detectInAppBrowser());
  }, []);

  if (!browserInfo?.isInAppBrowser) return null;

  const handleCopy = async () => {
    const success = await copyUrlToClipboard();
    if (success) {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleOpenChrome = () => {
    window.location.href = getChromeIntentUrl();
  };

  return (
    <div
      className="fixed inset-x-0 top-0 z-50 bg-yellow-500 text-black p-4 text-center"
      dir="rtl"
    >
      <p className="font-medium mb-2">
        האפליקציה פועלת בדפדפן {browserInfo.browserName}.
        לחוויה מלאה, פתח בדפדפן רגיל.
      </p>

      {browserInfo.escapeMethod === 'copy' ? (
        <button
          onClick={handleCopy}
          className="bg-black text-white px-4 py-2 rounded-lg font-medium min-h-11"
        >
          {copied ? 'הקישור הועתק!' : 'העתק קישור'}
        </button>
      ) : (
        <button
          onClick={handleOpenChrome}
          className="bg-black text-white px-4 py-2 rounded-lg font-medium min-h-11"
        >
          פתח ב-Chrome
        </button>
      )}

      <p className="text-xs mt-2 opacity-80">
        {browserInfo.escapeMethod === 'copy'
          ? 'העתק את הקישור והדבק ב-Safari'
          : 'לחץ לפתיחה בדפדפן Chrome'}
      </p>
    </div>
  );
}

// Usage in App.tsx or layout
function App() {
  return (
    <>
      <InAppBrowserBanner />
      {/* Rest of app */}
    </>
  );
}
```

**Test Patterns:**

```typescript
import { describe, it, expect, vi } from 'vitest';
import { detectInAppBrowser } from '@/lib/pwa/inAppBrowserDetection';

describe('PWA-21: In-App Browser Detection', () => {
  const originalNavigator = global.navigator;

  afterEach(() => {
    Object.defineProperty(global, 'navigator', { value: originalNavigator });
  });

  function mockUserAgent(ua: string) {
    Object.defineProperty(global, 'navigator', {
      value: { userAgent: ua },
      writable: true,
    });
  }

  it('should detect Facebook in-app browser', () => {
    mockUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBAV/330.0.0.37.65]');

    const result = detectInAppBrowser();

    expect(result.isInAppBrowser).toBe(true);
    expect(result.browserName).toBe('Facebook');
    expect(result.escapeMethod).toBe('copy'); // iOS
  });

  it('should detect Instagram in-app browser on Android', () => {
    mockUserAgent('Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 Instagram 195.0.0.31.123');

    const result = detectInAppBrowser();

    expect(result.isInAppBrowser).toBe(true);
    expect(result.browserName).toBe('Instagram');
    expect(result.escapeMethod).toBe('intent'); // Android
  });

  it('should detect TikTok in-app browser', () => {
    mockUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 BytedanceWebview');

    const result = detectInAppBrowser();

    expect(result.isInAppBrowser).toBe(true);
    expect(result.browserName).toBe('TikTok');
  });

  it('should NOT detect regular Chrome as in-app browser', () => {
    mockUserAgent('Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36');

    const result = detectInAppBrowser();

    expect(result.isInAppBrowser).toBe(false);
    expect(result.browserName).toBeNull();
  });

  it('should NOT detect Safari as in-app browser', () => {
    mockUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1');

    const result = detectInAppBrowser();

    expect(result.isInAppBrowser).toBe(false);
  });
});
```

**Verification Checklist:**

- [ ] `detectInAppBrowser()` runs on app mount
- [ ] Banner shown only in WebView environments
- [ ] iOS shows "Copy URL" button
- [ ] Android shows "Open in Chrome" button with intent://
- [ ] Banner is dismissible (optional)
- [ ] Tested with Facebook, Instagram, TikTok user agents
- [ ] Regular Safari/Chrome NOT detected as in-app browser

---

### GATE PWA-22: iOS Service Worker Health Check (CRITICAL)

> **9D Alignment:** D2 (Performance), D4 (UX), D3 (Security - SW state verification)
> **Laws:** #1 (ZERO TRUST - verify SW is alive), #4 (ROI - prevent broken offline)
> **Severity:** CRITICAL | **Fix Time:** 30 min | **Impact:** PWA stops working after ~3 days on iOS

**BUG:** iOS Safari kills Service Workers after ~3 days of app inactivity! When user returns:
- SW is dead
- Offline mode broken
- Push notifications stop working
- Caching strategies fail silently

**THE FIX:** Implement SW health check with ping/pong and auto-recovery:

**Service Worker Side:**

```typescript
// sw.ts - Add to your service worker

// PWA-22: Respond to health check pings from main app
self.addEventListener('message', (event) => {
  if (event.data?.type === 'SW_PING' && event.ports[0]) {
    // Respond with pong to prove we're alive
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

const SW_PING_TIMEOUT = 3000; // 3 seconds

/**
 * PWA-22: Ping the Service Worker to check if it's alive
 *
 * iOS Safari kills SW after ~3 days of inactivity.
 * This function verifies the SW is responsive.
 */
export async function pingServiceWorker(): Promise<HealthCheckResult> {
  // Check if SW is supported and registered
  if (!('serviceWorker' in navigator)) {
    return { isHealthy: false, error: 'Service Worker not supported' };
  }

  try {
    const registration = await navigator.serviceWorker.ready;

    if (!registration.active) {
      return { isHealthy: false, error: 'No active Service Worker' };
    }

    const startTime = Date.now();

    // Use MessageChannel for two-way communication
    return new Promise<HealthCheckResult>((resolve) => {
      const channel = new MessageChannel();

      // Set timeout for unresponsive SW
      const timeout = setTimeout(() => {
        resolve({ isHealthy: false, error: 'Service Worker unresponsive (timeout)' });
      }, SW_PING_TIMEOUT);

      // Listen for pong response
      channel.port1.onmessage = (event) => {
        clearTimeout(timeout);
        const responseTime = Date.now() - startTime;

        if (event.data?.type === 'SW_PONG') {
          resolve({ isHealthy: true, responseTime });
        } else {
          resolve({ isHealthy: false, error: 'Invalid SW response' });
        }
      };

      // Send ping with response port
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
  if (!('serviceWorker' in navigator)) {
    return false;
  }

  try {
    // Unregister all existing SWs
    const registrations = await navigator.serviceWorker.getRegistrations();
    for (const reg of registrations) {
      await reg.unregister();
    }

    // Re-register (assumes SW path is /sw.js)
    await navigator.serviceWorker.register('/sw.js');

    // Wait for it to be ready
    await navigator.serviceWorker.ready;

    console.log('[PWA-22] Service Worker recovered');
    return true;
  } catch (error) {
    console.error('[PWA-22] Failed to recover Service Worker:', error);
    return false;
  }
}

/**
 * Run health check and auto-recover if needed
 */
export async function healthCheckWithRecovery(): Promise<{
  wasHealthy: boolean;
  recovered: boolean;
}> {
  const result = await pingServiceWorker();

  if (result.isHealthy) {
    return { wasHealthy: true, recovered: false };
  }

  console.warn('[PWA-22] Service Worker unhealthy:', result.error);

  // Attempt recovery
  const recovered = await recoverServiceWorker();

  if (recovered) {
    // Verify recovery worked
    const retryResult = await pingServiceWorker();
    return { wasHealthy: false, recovered: retryResult.isHealthy };
  }

  return { wasHealthy: false, recovered: false };
}
```

**React Hook:**

```typescript
// hooks/useServiceWorkerHealth.ts
import { useEffect, useRef } from 'react';
import { healthCheckWithRecovery, pingServiceWorker } from '@/lib/pwa/swHealthCheck';

const HEALTH_CHECK_INTERVAL = 60 * 60 * 1000; // 1 hour

export function useServiceWorkerHealth() {
  const lastCheckRef = useRef<number>(0);

  const runHealthCheck = async () => {
    const now = Date.now();

    // Don't check more than once per hour
    if (now - lastCheckRef.current < HEALTH_CHECK_INTERVAL) {
      return;
    }

    lastCheckRef.current = now;

    const result = await healthCheckWithRecovery();

    if (!result.wasHealthy) {
      if (result.recovered) {
        console.log('[PWA-22] Service Worker was dead but recovered');
      } else {
        console.error('[PWA-22] Service Worker is dead and could not be recovered');
        // Optionally show user a message to reload
      }
    }
  };

  useEffect(() => {
    // Check on mount
    runHealthCheck();

    // Check periodically
    const intervalId = setInterval(runHealthCheck, HEALTH_CHECK_INTERVAL);

    // Check on visibility change (app comes to foreground)
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        runHealthCheck();
      }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);

    // Check on focus (tab becomes active)
    const handleFocus = () => runHealthCheck();
    window.addEventListener('focus', handleFocus);

    return () => {
      clearInterval(intervalId);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', handleFocus);
    };
  }, [runHealthCheck]);
}

// Usage in App.tsx
function App() {
  useServiceWorkerHealth();
  // ...
}
```

**Test Patterns:**

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { pingServiceWorker, recoverServiceWorker } from '@/lib/pwa/swHealthCheck';

describe('PWA-22: iOS Service Worker Health Check', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('should return healthy when SW responds to ping', async () => {
    // Mock healthy SW
    const mockPostMessage = vi.fn((message, transfer) => {
      const port = transfer[0] as MessagePort;
      setTimeout(() => {
        port.postMessage({ type: 'SW_PONG', timestamp: Date.now() });
      }, 10);
    });

    Object.defineProperty(navigator, 'serviceWorker', {
      value: {
        ready: Promise.resolve({
          active: { postMessage: mockPostMessage },
        }),
      },
      writable: true,
    });

    const resultPromise = pingServiceWorker();
    vi.runAllTimers();
    const result = await resultPromise;

    expect(result.isHealthy).toBe(true);
    expect(result.responseTime).toBeDefined();
  });

  it('should return unhealthy when SW times out', async () => {
    // Mock unresponsive SW
    const mockPostMessage = vi.fn(); // Never responds

    Object.defineProperty(navigator, 'serviceWorker', {
      value: {
        ready: Promise.resolve({
          active: { postMessage: mockPostMessage },
        }),
      },
      writable: true,
    });

    const resultPromise = pingServiceWorker();
    vi.advanceTimersByTime(4000); // Past 3s timeout
    const result = await resultPromise;

    expect(result.isHealthy).toBe(false);
    expect(result.error).toContain('timeout');
  });

  it('should return unhealthy when no active SW', async () => {
    Object.defineProperty(navigator, 'serviceWorker', {
      value: {
        ready: Promise.resolve({
          active: null, // No active SW
        }),
      },
      writable: true,
    });

    const result = await pingServiceWorker();

    expect(result.isHealthy).toBe(false);
    expect(result.error).toContain('No active Service Worker');
  });
});
```

**Verification Checklist:**

- [ ] SW has `message` event listener for `SW_PING`
- [ ] SW responds with `SW_PONG` through MessageChannel
- [ ] Main app has `pingServiceWorker()` function
- [ ] Health check runs on:
  - [ ] App mount
  - [ ] Every hour (interval)
  - [ ] On visibility change (app foreground)
  - [ ] On window focus
- [ ] Auto-recovery attempted when SW is dead
- [ ] Tested on iOS Safari with 3+ days of inactivity

---

### Captive Portal Detection

**CRITICAL:** Service Worker can BLOCK captive portal detection!

Captive portals (hotel WiFi, airport, etc.) work by intercepting HTTP requests. If your SW caches everything, users can't connect to WiFi!

```typescript
// URLs that captive portal detection uses - NEVER CACHE THESE!
const CAPTIVE_PORTAL_URLS = [
  // Apple
  'captive.apple.com',
  'www.apple.com/library/test/success.html',

  // Google/Android
  'connectivitycheck.gstatic.com',
  'clients3.google.com',
  'www.google.com/generate_204',

  // Microsoft
  'www.msftconnecttest.com',
  'www.msftncsi.com',

  // Firefox
  'detectportal.firefox.com',

  // Generic
  'network-test.debian.org',
];

// Service Worker: Exclude captive portal URLs
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Never intercept captive portal checks
  if (CAPTIVE_PORTAL_URLS.some(domain => url.hostname.includes(domain))) {
    return; // Let request pass through to network
  }

  // Normal SW handling...
  event.respondWith(handleFetch(event.request));
});
```

### Network Change Detection

```typescript
// Detect network changes and reconnect
interface NetworkInfo {
  isOnline: boolean;
  type: 'wifi' | 'cellular' | 'ethernet' | 'unknown';
  effectiveType: '4g' | '3g' | '2g' | 'slow-2g' | 'unknown';
  downlink: number; // Mbps estimate
  rtt: number; // Round trip time in ms
  saveData: boolean;
}

function getNetworkInfo(): NetworkInfo {
  const connection = (navigator as any).connection ||
                     (navigator as any).mozConnection ||
                     (navigator as any).webkitConnection;

  return {
    isOnline: navigator.onLine,
    type: connection?.type || 'unknown',
    effectiveType: connection?.effectiveType || 'unknown',
    downlink: connection?.downlink || 0,
    rtt: connection?.rtt || 0,
    saveData: connection?.saveData || false,
  };
}

// React hook for network state
function useNetworkState() {
  const [network, setNetwork] = useState<NetworkInfo>(getNetworkInfo);

  useEffect(() => {
    const updateNetwork = () => setNetwork(getNetworkInfo());

    // Online/offline events
    window.addEventListener('online', updateNetwork);
    window.addEventListener('offline', updateNetwork);

    // Connection change event (Chrome)
    const connection = (navigator as any).connection;
    if (connection) {
      connection.addEventListener('change', updateNetwork);
    }

    return () => {
      window.removeEventListener('online', updateNetwork);
      window.removeEventListener('offline', updateNetwork);
      connection?.removeEventListener('change', updateNetwork);
    };
  }, []);

  return network;
}

// Actions on network change
function useNetworkActions(callbacks: {
  onOnline?: () => void;
  onOffline?: () => void;
  onSlowConnection?: () => void;
}) {
  const network = useNetworkState();
  const prevNetworkRef = useRef(network);

  useEffect(() => {
    const prev = prevNetworkRef.current;
    prevNetworkRef.current = network;

    // Went online
    if (!prev.isOnline && network.isOnline) {
      callbacks.onOnline?.();
    }

    // Went offline
    if (prev.isOnline && !network.isOnline) {
      callbacks.onOffline?.();
    }

    // Connection became slow
    if (network.effectiveType === '2g' || network.effectiveType === 'slow-2g') {
      callbacks.onSlowConnection?.();
    }
  }, [network, callbacks]);

  return network;
}

// Usage
function App() {
  const network = useNetworkActions({
    onOnline: () => {
      // Reconnect WebSockets
      websocket.reconnect();
      // Sync pending data
      syncPendingData();
    },
    onOffline: () => {
      // Show offline indicator
      showOfflineBanner();
    },
    onSlowConnection: () => {
      // Reduce image quality
      setImageQuality('low');
    },
  });

  return (
    <div>
      {!network.isOnline && <OfflineBanner />}
      {network.saveData && <DataSaverBanner />}
      {/* ... */}
    </div>
  );
}
```

### VPN Interference Handling

```typescript
// VPNs can cause intermittent failures - implement robust retry
async function fetchWithRetry(
  url: string,
  options: RequestInit = {},
  maxRetries = 3
): Promise<Response> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const response = await fetch(url, {
        ...options,
        // Add timeout
        signal: AbortSignal.timeout(10000),
      });

      if (response.ok) {
        return response;
      }

      // VPN might cause 403/502/503
      if ([403, 502, 503].includes(response.status)) {
        console.warn(`VPN-like error (${response.status}), retrying...`);
        await sleep(1000 * Math.pow(2, attempt));
        continue;
      }

      return response;
    } catch (error) {
      lastError = error as Error;

      // Network errors are often VPN-related
      if (error instanceof TypeError && error.message.includes('Failed to fetch')) {
        console.warn('Network error, might be VPN - retrying...');
        await sleep(1000 * Math.pow(2, attempt));
        continue;
      }

      throw error;
    }
  }

  throw lastError || new Error('Max retries reached');
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Metered Connection Handling

```typescript
// Respect user's data saving preferences
function shouldReduceData(): boolean {
  const connection = (navigator as any).connection;

  if (!connection) return false;

  // User enabled data saver
  if (connection.saveData) return true;

  // Slow connection
  if (connection.effectiveType === '2g' || connection.effectiveType === 'slow-2g') {
    return true;
  }

  // High cost connection (some browsers expose this)
  if (connection.type === 'cellular') {
    return true;
  }

  return false;
}

// Adjust app behavior based on connection
function getResourceQuality(): 'high' | 'medium' | 'low' {
  if (shouldReduceData()) {
    return 'low';
  }

  const connection = (navigator as any).connection;

  if (connection?.effectiveType === '3g') {
    return 'medium';
  }

  return 'high';
}

// Image loading with data awareness
function getImageUrl(baseUrl: string, quality: 'high' | 'medium' | 'low'): string {
  const sizes = {
    high: 1200,
    medium: 800,
    low: 400,
  };

  const formats = {
    high: 'webp',
    medium: 'webp',
    low: 'jpeg',
  };

  return `${baseUrl}?w=${sizes[quality]}&fm=${formats[quality]}&q=${quality === 'low' ? 60 : 80}`;
}
```

---

## Storage Edge Cases

### Private Browsing Detection

```typescript
// Private/incognito mode has limited storage
async function isPrivateBrowsing(): Promise<boolean> {
  // Method 1: Storage estimate (most reliable)
  if (navigator.storage?.estimate) {
    try {
      const { quota } = await navigator.storage.estimate();
      // Private mode typically has < 120MB quota
      if (quota && quota < 120_000_000) {
        return true;
      }
    } catch {
      // Might throw in private mode
    }
  }

  // Method 2: Try to use IndexedDB (fails in some private modes)
  try {
    const testDB = indexedDB.open('__test_private__');
    await new Promise((resolve, reject) => {
      testDB.onerror = () => reject(new Error('IndexedDB blocked'));
      testDB.onsuccess = () => {
        testDB.result.close();
        indexedDB.deleteDatabase('__test_private__');
        resolve(true);
      };
    });
  } catch {
    return true;
  }

  // Method 3: Try localStorage with a large item
  try {
    const testKey = '__test_private__';
    localStorage.setItem(testKey, new Array(1024).join('a'));
    localStorage.removeItem(testKey);
  } catch {
    return true;
  }

  return false;
}

// Show warning in private mode
function PrivateModeWarning() {
  const [isPrivate, setIsPrivate] = useState(false);

  useEffect(() => {
    isPrivateBrowsing().then(setIsPrivate);
  }, []);

  if (!isPrivate) return null;

  return (
    <div className="bg-yellow-100 border border-yellow-300 p-4 rounded-lg mb-4">
      <h3 className="font-medium">מצב גלישה פרטית</h3>
      <p className="text-sm text-yellow-800">
        חלק מהתכונות עשויות לא לעבוד במצב גלישה פרטית.
        הנתונים שלך לא יישמרו לאחר סגירת הדפדפן.
      </p>
    </div>
  );
}
```

### iOS 7-Day Cache Eviction

```typescript
// Safari evicts unused caches after 7 days
// Solution: Request persistent storage + refresh cache on load

async function maintainCache() {
  // 1. Request persistent storage
  if (navigator.storage?.persist) {
    const isPersisted = await navigator.storage.persisted();
    if (!isPersisted) {
      const granted = await navigator.storage.persist();
      console.log('Persistent storage:', granted ? 'granted' : 'denied');
    }
  }

  // 2. Refresh critical cache items on app load
  const sw = await navigator.serviceWorker.ready;
  sw.active?.postMessage({
    type: 'REFRESH_CRITICAL_CACHE',
    urls: [
      '/',
      '/offline.html',
      '/manifest.json',
      // Add other critical resources
    ],
  });
}

// Service Worker handler
self.addEventListener('message', async (event) => {
  if (event.data.type === 'REFRESH_CRITICAL_CACHE') {
    const cache = await caches.open('critical-v1');
    const urls = event.data.urls;

    // Touch each item to update access time
    for (const url of urls) {
      try {
        const response = await fetch(url, { cache: 'reload' });
        if (response.ok) {
          await cache.put(url, response);
        }
      } catch {
        // Item will remain in cache if network fails
      }
    }
  }
});
```

### Storage Partitioning (Chrome 115+)

```typescript
// Chrome 115+ partitions storage by top-level site
// Third-party iframes have separate storage

// Check if running in iframe
function isInIframe(): boolean {
  try {
    return window.self !== window.top;
  } catch {
    // Cross-origin iframe
    return true;
  }
}

// Request storage access for third-party context
async function requestStorageAccess(): Promise<boolean> {
  if (!document.hasStorageAccess) {
    return true; // API not supported, assume access
  }

  const hasAccess = await document.hasStorageAccess();
  if (hasAccess) return true;

  try {
    await document.requestStorageAccess();
    return true;
  } catch {
    return false;
  }
}

// Use in iframe
if (isInIframe()) {
  const hasAccess = await requestStorageAccess();
  if (!hasAccess) {
    console.warn('Storage access denied in third-party context');
  }
}
```

### Low Storage Cleanup

```typescript
// Aggressive cleanup when storage is low
async function handleLowStorage(): Promise<void> {
  const estimate = await navigator.storage?.estimate();
  if (!estimate?.quota || !estimate.usage) return;

  const percentUsed = (estimate.usage / estimate.quota) * 100;

  if (percentUsed < 80) return;

  console.warn(`Storage at ${percentUsed.toFixed(1)}%, cleaning up...`);

  // 1. Clear old caches
  const cacheNames = await caches.keys();
  const oldCaches = cacheNames.filter(name => name.includes('-v') && !name.includes('-v3'));
  await Promise.all(oldCaches.map(name => caches.delete(name)));

  // 2. Clear expired IndexedDB data
  const db = await openDB('app-db', 1);
  const tx = db.transaction('cache', 'readwrite');
  const store = tx.objectStore('cache');
  const now = Date.now();

  for await (const cursor of store) {
    if (cursor.value.expires && cursor.value.expires < now) {
      cursor.delete();
    }
  }

  // 3. Clear image cache
  imageCache.clear();

  // 4. Report new usage
  const newEstimate = await navigator.storage.estimate();
  console.log(`Storage after cleanup: ${((newEstimate.usage || 0) / (newEstimate.quota || 1) * 100).toFixed(1)}%`);
}
```

---

## Time/Date Edge Cases

### Timezone Change Detection

```typescript
// User might change timezone (travel, manual change)
function detectTimezoneChange(): void {
  const storedTimezone = localStorage.getItem('user-timezone');
  const currentTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  if (storedTimezone && storedTimezone !== currentTimezone) {
    console.log(`Timezone changed: ${storedTimezone} -> ${currentTimezone}`);

    // Refresh cached dates
    refreshCachedDates();

    // Notify user if relevant
    if (shouldNotifyTimezoneChange()) {
      showTimezoneChangeNotification(storedTimezone, currentTimezone);
    }
  }

  localStorage.setItem('user-timezone', currentTimezone);
}

// Check on visibility change (app returns to foreground)
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') {
    detectTimezoneChange();
  }
});
```

### DST Transition Handling

```typescript
// Store dates in UTC, format locally
function formatLocalDate(utcDate: Date | string): string {
  const date = typeof utcDate === 'string' ? new Date(utcDate) : utcDate;

  return new Intl.DateTimeFormat('he-IL', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  }).format(date);
}

// Check for DST "impossible" times
function isValidLocalTime(year: number, month: number, day: number, hour: number): boolean {
  const date = new Date(year, month - 1, day, hour);
  return date.getHours() === hour;
}

// Example: March 27, 2026 02:30 doesn't exist in Israel (clocks skip from 02:00 to 03:00)
console.log(isValidLocalTime(2026, 3, 27, 2)); // false
```

### Clock Skew Detection

```typescript
// Detect if device clock is wrong (affects JWT, caching, etc.)
async function detectClockSkew(): Promise<number> {
  try {
    const response = await fetch('/api/time', { cache: 'no-store' });
    const serverDate = response.headers.get('Date');

    if (!serverDate) return 0;

    const serverTime = new Date(serverDate).getTime();
    const clientTime = Date.now();
    const skew = clientTime - serverTime;

    // Skew > 5 minutes is problematic
    if (Math.abs(skew) > 5 * 60 * 1000) {
      console.warn(`Clock skew detected: ${(skew / 1000 / 60).toFixed(1)} minutes`);
      reportClockSkew(skew);
    }

    return skew;
  } catch {
    return 0;
  }
}

// Adjust timestamps when clock skew detected
function adjustForClockSkew(timestamp: number, skew: number): number {
  return timestamp - skew;
}
```

---

## Accessibility Edge Cases

### Screen Reader Focus Management

```typescript
// Announce route changes for screen readers
function announceRouteChange(pageTitle: string) {
  // Create or find announcer element
  let announcer = document.getElementById('route-announcer');

  if (!announcer) {
    announcer = document.createElement('div');
    announcer.id = 'route-announcer';
    announcer.setAttribute('role', 'status');
    announcer.setAttribute('aria-live', 'polite');
    announcer.setAttribute('aria-atomic', 'true');
    announcer.className = 'sr-only';
    document.body.appendChild(announcer);
  }

  // Announce the new page
  announcer.textContent = `עברת לדף: ${pageTitle}`;
}

// Next.js App Router integration
'use client';

import { usePathname } from 'next/navigation';
import { useEffect } from 'react';

export function RouteAnnouncer() {
  const pathname = usePathname();

  useEffect(() => {
    // Small delay to ensure title is updated
    const timer = setTimeout(() => {
      announceRouteChange(document.title);
    }, 100);

    return () => clearTimeout(timer);
  }, [pathname]);

  return null;
}
```

### Reduced Motion Support

```css
/* Always respect user preference */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```typescript
// Check preference in JS
function prefersReducedMotion(): boolean {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

// React hook
function usePrefersReducedMotion(): boolean {
  const [prefersReduced, setPrefersReduced] = useState(false);

  useEffect(() => {
    const query = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReduced(query.matches);

    const handler = (e: MediaQueryListEvent) => setPrefersReduced(e.matches);
    query.addEventListener('change', handler);

    return () => query.removeEventListener('change', handler);
  }, []);

  return prefersReduced;
}
```

### Voice Control Support

```tsx
// Ensure all interactive elements have accessible names
function AccessibleButton({
  children,
  ariaLabel,
  ...props
}: {
  children: React.ReactNode;
  ariaLabel?: string;
} & React.ButtonHTMLAttributes<HTMLButtonElement>) {
  // If children is just an icon, ariaLabel is required
  const needsLabel = typeof children !== 'string';

  if (needsLabel && !ariaLabel) {
    console.warn('Button with non-text children needs aria-label');
  }

  return (
    <button aria-label={ariaLabel} {...props}>
      {children}
    </button>
  );
}

<!-- PWA-EXPERT/EDGE-CASES v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->
```


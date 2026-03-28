# ANDROID-RENDERING-FIXES v24.5.0 SINGULARITY FORGE

> Critical Android Rendering Fixes Discovered in Production
> Based on Cash App deep research (Jan 2026)

---

## 1. PURPOSE

This reference documents critical Android rendering issues discovered through deep research on production PWAs. These issues cause:
- Elements disappearing during scroll
- Icons looking different than expected
- Components flickering or janking
- Slow first load on old devices
- Touch targets being too small

**CRITICAL**: These issues are NOT caught by Lighthouse or standard testing. They only appear on real Android devices.

---

## 2. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-ARF-1 | CONTENT_VISIBILITY | No content-visibility:auto on Android | CSS override present |
| G-ARF-2 | STROKE_WIDTH | SVG strokeWidth consistent | All icons use same value |
| G-ARF-3 | VIEW_TRANSITIONS | Disabled on old Android | CSS/JS guard present |
| G-ARF-4 | WILL_CHANGE | No conflicting rules | Single source of truth |
| G-ARF-5 | SCROLL_MARGIN | No race condition | useState+useLayoutEffect |
| G-ARF-6 | TOUCH_TARGETS | 44px minimum | Wrapper div present |
| G-ARF-7 | Z_INDEX_LIMITS | No z-index:9999 | Max z-index:50 |
| G-ARF-8 | NETWORK_TIMEOUT | Generous timeout | 10s minimum |

---

## 3. CRITICAL FIXES

### 3.1 content-visibility: auto (ELEMENTS DISAPPEAR)

**Problem**: `content-visibility: auto` causes elements to disappear and reappear during scroll on Android Chrome < 90.

**Root Cause**: Android Chrome's implementation of content-visibility has bugs where elements are not rendered back after becoming visible.

**Fix**: Disable content-visibility for Android:

```css
/* ===== ANDROID: DISABLE CONTENT-VISIBILITY ===== */
/* content-visibility: auto causes scroll disappearing on Android Chrome < 90 */
.is-android .cv-card,
.is-android .cv-delivery-card,
.is-android .cv-section,
.is-android .cv-contact-card,
.is-android .cv-modal,
.is-android .content-visibility-auto,
.is-android [class*="cv-"] {
  content-visibility: visible !important;
  contain-intrinsic-size: none !important;
}

/* Also disable for old Android specifically */
.is-android-old [class*="cv-"] {
  content-visibility: visible !important;
  contain-intrinsic-size: none !important;
}
```

**Detection**: Add `is-android` class to document root:

```typescript
// See Section 4 for full detection setup in index.html
// Classes set: is-android, is-android-old, is-ios, is-in-app-browser
// Detection MUST be in inline <script> in index.html, NOT in React code
```

---

### 3.2 SVG strokeWidth Inconsistency (ICONS LOOK DIFFERENT)

**Problem**: Custom SVG icons look different from lucide-react icons because of inconsistent strokeWidth values.

**Root Cause**:
- CSS forces `stroke-width: 2.5` for `.lucide` class icons
- Custom SVGs use `strokeWidth="2"` or `strokeWidth={3}`
- Result: Inconsistent icon weights across the app

**Fix**:

1. **CSS Global Rule** (for lucide icons):
```css
svg[class*="lucide"] path,
svg[class*="icon"] path,
svg[class*="Icon"] path {
  stroke-width: 2.5;
  stroke-linecap: round;
  stroke-linejoin: round;
  vector-effect: non-scaling-stroke;
}
```

2. **Custom SVGs** - Use same strokeWidth:
```tsx
// ❌ BAD - Inconsistent with lucide
<svg strokeWidth="2">...</svg>

// ✅ GOOD - Matches lucide
<svg strokeWidth="2.5">...</svg>
```

3. **Checkbox Exception** - Preserve specific values:
```css
/* Checkbox needs thicker stroke for visibility */
[data-state="checked"] path,
.checkbox path {
  stroke-width: 3 !important;
}
```

---

### 3.3 View Transitions API (JANK ON OLD ANDROID)

**Problem**: View Transitions API causes jank and visual glitches on old Android devices.

**Root Cause**: View Transitions API requires Chrome 111+. Old Android has Chrome < 111.

**Fix**: Disable View Transitions for Android:

```css
/* ANDROID: Disable view transitions - causes jank on older devices */
/* View Transitions API requires Chrome 111+ */
.is-android ::view-transition-old(root),
.is-android ::view-transition-new(root) {
  animation: none !important;
}

.is-android-old ::view-transition-old(root),
.is-android-old ::view-transition-new(root) {
  animation: none !important;
}
```

**JavaScript Guard**:
```typescript
// useNavigateWithTransition.ts
// React Compiler auto-memoizes — no manual useCallback needed
export function useNavigateWithTransition() {
  const navigate = useNavigate();

  return (to: string) => {
    // Skip View Transitions on Android
    const isAndroid = /Android/.test(navigator.userAgent);

    if (!isAndroid && 'startViewTransition' in document) {
      document.startViewTransition(() => navigate(to));
    } else {
      navigate(to);
    }
  };
}
```

---

### 3.4 will-change CSS Conflict

**Problem**: Conflicting `will-change` rules cause rendering issues.

**Root Cause**: One rule disables `will-change` for Android, another rule enables it.

**Example Conflict**:
```css
/* Line 2508 - DISABLES */
.is-android [class*="will-change"] {
  will-change: auto !important;
}

/* Line 2840 - ENABLES (CONFLICT!) */
.scroll-container {
  will-change: scroll-position;
}
```

**Fix**: Single source of truth - if disabling for Android, don't enable elsewhere:

```css
/* Use only when needed, with Android exception */
.scroll-container {
  will-change: scroll-position;
}

/* Override for Android */
.is-android .scroll-container {
  will-change: auto;
}
```

---

### 3.5 scrollMargin Race Condition (TANSTACK VIRTUAL)

**Problem**: `scrollMargin` in TanStack Virtual always returns 0 because ref is null on first render.

**Root Cause**: React refs are assigned after render, not during initialization.

**Bad Code**:
```typescript
// ❌ RACE CONDITION - ref is null!
const virtualizer = useWindowVirtualizer({
  count: items.length,
  estimateSize: () => 100,
  scrollMargin: listRef.current?.offsetTop ?? 0, // ALWAYS 0!
});
```

**Fix**: Use useState + useLayoutEffect:

```typescript
// ✅ FIXED - Properly synchronized
const listRef = useRef<HTMLDivElement>(null);
const [scrollMargin, setScrollMargin] = useState(0);

useLayoutEffect(() => {
  if (listRef.current) {
    setScrollMargin(listRef.current.offsetTop);
  }
}, []); // Measure once on mount

const virtualizer = useWindowVirtualizer({
  count: items.length,
  estimateSize: () => 100,
  scrollMargin, // Now correct value from state
});
```

---

### 3.6 Touch Targets Below 44px (LAW #6 VIOLATION)

**Problem**: Interactive elements smaller than 44x44px are hard to tap on mobile.

**Root Cause**: Component visual size doesn't match touch target size.

**Example - Switch Component**:
```tsx
// ❌ BAD - Only 20x36px touch target
<SwitchPrimitives.Root className="h-5 w-9">
  ...
</SwitchPrimitives.Root>

// ✅ GOOD - 44x44px touch target wrapper
<div className="relative min-h-11 min-w-11 flex items-center justify-center">
  <SwitchPrimitives.Root className="h-5 w-9">
    ...
  </SwitchPrimitives.Root>
</div>
```

**Alternative - Invisible Touch Area**:
```tsx
// Button with extended touch area
<button className="relative h-6 w-6 before:absolute before:inset-[-12px]">
  <Icon />
</button>
```

---

### 3.7 z-index: 9999 Breaking Scale Animations

**Problem**: `z-index: 9999` causes visual glitches with CSS scale transforms.

**Root Cause**: Extremely high z-index values create new stacking contexts that interfere with transform animations.

**Fix**: Use reasonable z-index values:

```css
/* ❌ BAD */
.modal {
  z-index: 9999;
}

/* ✅ GOOD */
.modal {
  z-index: 50;
}

/* Z-index scale recommendation:
   - Base content: 0
   - Dropdowns: 10
   - Sticky headers: 20
   - Modals: 30-40
   - Tooltips: 50
   - Notifications: 60
*/
```

---

### 3.8 Network Timeout Strategy

**Navigation requests**: Use 3s timeout with cache fallback. The SW navigationHandler uses NetworkFirst with a 3-second timeout -- if the network is slow, it falls back to cached HTML (which has the correct bundle hashes). This gives fast perceived performance.

**API requests**: Use 5-10s timeout depending on endpoint. API data is more critical and can't easily fall back.

```typescript
// Navigation: 3s timeout, fall back to cache
const NAVIGATION_TIMEOUT_MS = 3000;

// API: Longer timeout for data requests
const API_TIMEOUT_MS = 10_000;
```

---

## 4. DETECTION SETUP

Add this to your `index.html` as an inline script BEFORE the main React bundle loads. This runs synchronously so CSS classes are available immediately.

**CRITICAL**: Detection must happen in an inline `<script>` in index.html, NOT in main.tsx or a separate module. The CSS classes must be present before React renders to avoid FOUC (Flash of Unstyled Content).

```html
<!-- index.html — before </body>, before the React entry script -->
<script>
  (function () {
    const root = document.documentElement;
    const ua = navigator.userAgent;

    // PLATFORM DETECTION - Add classes for platform-specific CSS
    const isAndroid = /Android/i.test(ua);
    const isIOS = /iPad|iPhone|iPod/i.test(ua);

    // Chrome version detection (Chrome < 84 doesn't support flexbox gap)
    const chromeMatch = ua.match(/Chrome\/(\d+)/);
    const chromeVersion = chromeMatch ? parseInt(chromeMatch[1], 10) : 999;
    const isOldChrome = chromeVersion < 84;

    // Android version detection
    const androidMatch = ua.match(/Android\s+(\d+)/);
    const androidVersion = androidMatch ? parseInt(androidMatch[1], 10) : 999;
    const isOldAndroidVersion = androidVersion < 10;

    if (isAndroid) {
      root.classList.add('is-android');
      // Old Android: Chrome < 84 OR Android < 10
      if (isOldChrome || isOldAndroidVersion) {
        root.classList.add('is-android-old');
      }
    }
    if (isIOS) {
      root.classList.add('is-ios');
    }

    // In-app browser detection (Instagram, Facebook, etc.)
    if (/FBAN|FBAV|Instagram|Line|Twitter|Snapchat/i.test(ua)) {
      root.classList.add('is-in-app-browser');
    }

    // Fix for old Android viewport height (dvh not supported)
    const setVH = () => {
      const vh = window.innerHeight * 0.01;
      root.style.setProperty('--vh', `${vh}px`);
    };
    window.addEventListener('resize', setVH);
    window.addEventListener('orientationchange', setVH);
    setVH();
  })();
</script>
```

**Classes Set:**

| Class | Condition | Purpose |
|-------|-----------|---------|
| `is-android` | Android UA detected | All Android-specific CSS |
| `is-android-old` | Chrome < 84 OR Android < 10 | Flexbox gap fallbacks, content-visibility fix |
| `is-ios` | iOS UA detected | iOS-specific CSS (safe areas, etc.) |
| `is-in-app-browser` | Social media WebView | Show "open in browser" banner |

**CSS Variable:**

| Variable | Value | Usage |
|----------|-------|-------|
| `--vh` | `window.innerHeight * 0.01` | Use `calc(var(--vh, 1vh) * 100)` instead of `100dvh` on old Android |

**Why inline script, not a module?**
- Synchronous execution guarantees classes exist before first paint
- No module loading delay -- critical for preventing FOUC
- CSS can immediately use `.is-android` selectors without waiting for React

---

## 5. VERIFICATION CHECKLIST

Run these checks after implementing fixes:

```bash
# Search for content-visibility without Android override
grep -r "content-visibility: auto" src/ --include="*.css" --include="*.tsx"

# Search for inconsistent strokeWidth
grep -r 'strokeWidth="2"' src/ --include="*.tsx"
grep -r "strokeWidth={2}" src/ --include="*.tsx"

# Search for z-index: 9999
grep -r "z-index: 9999" src/ --include="*.css"
grep -r "z-\[9999\]" src/ --include="*.tsx"

# Search for scrollMargin race condition
grep -r "scrollMargin.*listRef.current" src/ --include="*.tsx"

# Search for touch targets below 44px
grep -r "h-5 w-9" src/components/ui/ --include="*.tsx"
```

---

## 6. TESTING MATRIX

| Issue | How to Test | Expected Result |
|-------|-------------|-----------------|
| content-visibility | Scroll fast on Android | No disappearing elements |
| strokeWidth | Compare icons | All icons same weight |
| View Transitions | Navigate on old Android | No jank/flash |
| will-change | Profile animations | Smooth 60fps |
| scrollMargin | Check virtual list position | Correct offset |
| Touch targets | Tap small elements | Easy to activate |
| z-index | Use scale animations | No visual glitches |
| Network timeout | Test on slow 3G | Requests complete |

---

## 7. QUICK FIX COMMANDS

```bash
# Run full Android audit
/pwa android-rendering-audit

# Auto-fix content-visibility
/pwa fix-content-visibility

# Auto-fix strokeWidth
/pwa fix-stroke-width

# Auto-fix touch targets
/pwa fix-touch-targets
```

---

<!-- ANDROID-RENDERING-FIXES v24.5.0 | Updated: 2026-02-19 | Synced with Cash App actual implementation -->

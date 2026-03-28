# OLD-ANDROID-CSS-COMPAT v24.5.0 SINGULARITY FORGE

> The Legacy Android CSS Fallback Engine & Chrome < 84 Compatibility Master

> **See Also:** `android-rendering-fixes.md` for additional rendering issues (content-visibility, strokeWidth, View Transitions, etc.)

---

## 1. PURPOSE

Phase 2.4.1 Android CSS Compatibility engine. Definitive reference for CSS compatibility on old Android devices (Chrome < 84, Android 7-9, old WebView). Enforces fallbacks for flexbox gap, viewport units, hover states, and all modern CSS features.

---

## 2. COMMANDS

| Command | Description | Time |
|---------|-------------|------|
| `/css old-android-audit` | Audit for old Android CSS issues | ~2min |
| `/css gap-fallback` | Add flexbox gap fallbacks | ~1min |
| `/css viewport-fallback` | Add dvh/svh fallbacks | ~1min |
| `/css hover-fix` | Fix sticky hover states | ~1min |

---

## 3. GATE MATRIX

| Gate | Name | Validation | Pass Criteria |
|------|------|------------|---------------|
| G-CSS-1 | GAP_FALLBACK | Flexbox gap has margin fallback | Works on Chrome < 84 |
| G-CSS-2 | VIEWPORT_FALLBACK | dvh/svh has vh fallback | Works on old Android |
| G-CSS-3 | HOVER_PROTECTED | hover: wrapped in @media | No sticky hover |
| G-CSS-4 | ICONS_SHRINK | Icons have shrink-0 | No squished icons |
| G-CSS-5 | SCROLL_TOUCH | -webkit-overflow-scrolling | Momentum scroll |
| G-CSS-6 | SAFE_AREA | env() with fallbacks | No overlap |
| G-CSS-7 | FONT_SIZE | Min 12px enforced | Readable text |
| **G-CSS-8** | **CONTAINMENT_DISABLED** | **contain-content disabled on Android** | **Elements don't disappear** |

---

## 4. BROWSER SUPPORT MATRIX

| Feature | Chrome 84+ | Chrome < 84 | Old WebView | Solution |
|---------|------------|-------------|-------------|----------|
| `dvh/svh/lvh` | Yes | No | No | JS --vh variable |
| Flexbox `gap` | Yes | No | No | Margin fallback |
| CSS `:has()` | Yes (105+) | No | No | JS class toggle |
| `aspect-ratio` | Yes | No | No | Padding-top hack |
| `@container` | Yes (105+) | No | No | Media queries |
| `backdrop-filter` | Yes | Partial | No | Solid background |
| **`contain-content`** | Yes (90+) | **BUGGY** | **BUGGY** | **CSS override** |
| `overscroll-behavior` | Yes | No | No | JS prevention |
| `scroll-snap` | Yes | Partial | Partial | Polyfill/JS |
| `env()` safe-area | Yes | Partial | Partial | Fallback values |
| `clamp()` | Yes | No | No | CSS calc() fallback |
| Logical properties | Yes | Partial | Partial | Physical fallback |

---

## 5. DETECTION CODE

### 5.1 JavaScript Detection

```javascript
/**
 * Comprehensive Old Android Detection
 * Detects Chrome < 84 on Android, old WebView, and Samsung Internet
 */

// Basic detection
const isOldAndroid = /Android [4-9]/.test(navigator.userAgent) &&
  parseInt(navigator.userAgent.match(/Chrome\/(\d+)/)?.[1] || '999') < 84;

// More comprehensive detection including WebView and Samsung Internet
function detectOldAndroid() {
  const ua = navigator.userAgent;

  // Check if Android
  const isAndroid = /Android/.test(ua);
  if (!isAndroid) return { isOld: false, reason: 'not-android' };

  // Extract Android version
  const androidVersionMatch = ua.match(/Android (\d+(?:\.\d+)?)/);
  const androidVersion = androidVersionMatch
    ? parseFloat(androidVersionMatch[1])
    : 999;

  // Extract Chrome version
  const chromeVersionMatch = ua.match(/Chrome\/(\d+)/);
  const chromeVersion = chromeVersionMatch
    ? parseInt(chromeVersionMatch[1])
    : null;

  // Check for WebView
  const isWebView = ua.includes('wv') ||
    (ua.includes('Version/') && ua.includes('Chrome/'));

  // Check for Samsung Internet
  const samsungMatch = ua.match(/SamsungBrowser\/(\d+)/);
  const samsungVersion = samsungMatch ? parseInt(samsungMatch[1]) : null;

  // Determine if old
  const isOld =
    // Old Chrome
    (chromeVersion !== null && chromeVersion < 84) ||
    // Old Android (7-9 often has old WebView)
    (androidVersion >= 7 && androidVersion < 10 && isWebView) ||
    // Old Samsung Internet (< 14 lacks many features)
    (samsungVersion !== null && samsungVersion < 14) ||
    // Very old Android
    (androidVersion < 7);

  return {
    isOld,
    androidVersion,
    chromeVersion,
    samsungVersion,
    isWebView,
    reason: isOld ? 'old-browser' : 'modern-browser'
  };
}

// Apply class to document
const androidInfo = detectOldAndroid();
if (androidInfo.isOld) {
  document.documentElement.classList.add('is-android-old');
  document.documentElement.dataset.androidVersion = androidInfo.androidVersion;
  document.documentElement.dataset.chromeVersion = androidInfo.chromeVersion || 'unknown';
}

// Export for use in React/Vue
export { detectOldAndroid, isOldAndroid };
```

### 5.2 React Hook for Detection

```typescript
// hooks/useOldAndroid.ts
import { useState, useEffect } from 'react';

interface AndroidInfo {
  isOld: boolean;
  androidVersion: number;
  chromeVersion: number | null;
  samsungVersion: number | null;
  isWebView: boolean;
  reason: string;
}

export function useOldAndroid(): AndroidInfo {
  const [info, setInfo] = useState<AndroidInfo>(() => {
    // SSR-safe initial value
    if (typeof window === 'undefined') {
      return {
        isOld: false,
        androidVersion: 999,
        chromeVersion: null,
        samsungVersion: null,
        isWebView: false,
        reason: 'ssr'
      };
    }
    return detectOldAndroid();
  });

  useEffect(() => {
    setInfo(detectOldAndroid());
  }, []);

  return info;
}

// Usage in component
function MyComponent() {
  const { isOld, chromeVersion } = useOldAndroid();

  return (
    <div className={isOld ? 'legacy-layout' : 'modern-layout'}>
      {isOld && <p>Using compatibility mode (Chrome {chromeVersion})</p>}
    </div>
  );
}
```

### 5.3 CSS Feature Detection

```css
/* Feature detection using @supports */

/* Flexbox gap support */
@supports not (gap: 1rem) {
  .flex-container > * + * {
    margin-inline-start: 1rem;
  }
}

/* dvh support */
@supports not (height: 100dvh) {
  .full-height {
    height: 100vh;
    height: var(--vh-full, 100vh);
  }
}

/* :has() support - cannot detect with @supports, use JS */
.is-android-old .parent-needs-has-alternative {
  /* Fallback styles */
}

/* aspect-ratio support */
@supports not (aspect-ratio: 16/9) {
  .video-container {
    position: relative;
    padding-top: 56.25%; /* 16:9 */
  }
  .video-container > * {
    position: absolute;
    inset: 0;
  }
}

/* clamp() support */
@supports not (font-size: clamp(1rem, 2vw, 2rem)) {
  .responsive-text {
    font-size: 1rem;
  }
  @media (min-width: 768px) {
    .responsive-text {
      font-size: 1.5rem;
    }
  }
  @media (min-width: 1200px) {
    .responsive-text {
      font-size: 2rem;
    }
  }
}
```

---

## 6. VIEWPORT UNITS (dvh/svh/lvh Not Supported)

### 6.1 The Problem

Old Android browsers do not support dynamic viewport units (`dvh`, `svh`, `lvh`). Using `100vh` causes content to be hidden behind the address bar when it shows/hides, creating a jumpy experience.

### 6.2 CSS Fallback with Custom Property

```css
/* Root CSS - applied by JS */
:root {
  --vh: 1vh; /* Fallback */
  --vh-full: 100vh;
  --svh: 1vh;
  --svh-full: 100vh;
  --dvh: 1vh;
  --dvh-full: 100vh;
}

/* Modern browsers */
@supports (height: 100dvh) {
  :root {
    --vh: 1dvh;
    --vh-full: 100dvh;
    --svh: 1svh;
    --svh-full: 100svh;
    --dvh: 1dvh;
    --dvh-full: 100dvh;
  }
}

/* Usage */
.full-screen {
  /* Fallback for very old browsers */
  height: 100vh;
  /* Modern browsers */
  height: 100dvh;
  /* JS-calculated for old Android */
  height: var(--vh-full);
}

.half-screen {
  height: 50vh;
  height: 50dvh;
  height: calc(var(--vh) * 50);
}

/* Fixed bottom element accounting for keyboard */
.bottom-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  /* Move up when keyboard opens */
  transform: translateY(calc(-1 * var(--keyboard-height, 0px)));
  transition: transform 0.3s ease;
}
```

### 6.3 JavaScript Viewport Calculation

```javascript
/**
 * Viewport Height Calculator for Old Android
 * Handles address bar show/hide and virtual keyboard
 */

class ViewportHeightManager {
  constructor() {
    this.vh = 0;
    this.svh = 0; // Small viewport (with address bar)
    this.lvh = 0; // Large viewport (without address bar)
    this.keyboardHeight = 0;
    this.isKeyboardOpen = false;

    this.init();
  }

  init() {
    // Initial calculation
    this.calculate();

    // Recalculate on resize
    window.addEventListener('resize', this.debounce(() => {
      this.calculate();
    }, 100));

    // Handle orientation change
    window.addEventListener('orientationchange', () => {
      // Wait for orientation change to complete
      setTimeout(() => this.calculate(), 300);
    });

    // Detect keyboard
    this.setupKeyboardDetection();
  }

  calculate() {
    // Current viewport height
    const vh = window.innerHeight * 0.01;

    // Store initial height as svh (small viewport - with UI)
    if (this.svh === 0) {
      this.svh = vh;
    }

    // Update lvh if current is larger (address bar hidden)
    if (vh > this.lvh) {
      this.lvh = vh;
    }

    // Current dynamic height
    this.vh = vh;

    // Apply CSS custom properties
    this.applyCSSProperties();
  }

  applyCSSProperties() {
    const root = document.documentElement;

    root.style.setProperty('--vh', `${this.vh}px`);
    root.style.setProperty('--vh-full', `${this.vh * 100}px`);
    root.style.setProperty('--svh', `${this.svh}px`);
    root.style.setProperty('--svh-full', `${this.svh * 100}px`);
    root.style.setProperty('--lvh', `${this.lvh}px`);
    root.style.setProperty('--lvh-full', `${this.lvh * 100}px`);
    root.style.setProperty('--keyboard-height', `${this.keyboardHeight}px`);
  }

  setupKeyboardDetection() {
    // Use visualViewport API if available
    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', () => {
        const keyboardHeight = window.innerHeight - window.visualViewport.height;
        this.handleKeyboardChange(keyboardHeight);
      });
    } else {
      // Fallback: detect based on focus events
      document.addEventListener('focusin', (e) => {
        if (this.isInputElement(e.target)) {
          // Estimate keyboard height
          setTimeout(() => {
            const estimatedHeight = window.innerHeight * 0.4;
            this.handleKeyboardChange(estimatedHeight);
          }, 300);
        }
      });

      document.addEventListener('focusout', () => {
        setTimeout(() => {
          this.handleKeyboardChange(0);
        }, 100);
      });
    }
  }

  handleKeyboardChange(height) {
    this.keyboardHeight = Math.max(0, height);
    this.isKeyboardOpen = height > 50;

    document.documentElement.classList.toggle('keyboard-open', this.isKeyboardOpen);
    this.applyCSSProperties();

    // Dispatch custom event
    window.dispatchEvent(new CustomEvent('keyboardchange', {
      detail: { height: this.keyboardHeight, isOpen: this.isKeyboardOpen }
    }));
  }

  isInputElement(element) {
    if (!element) return false;
    const tagName = element.tagName.toLowerCase();
    return tagName === 'input' ||
           tagName === 'textarea' ||
           element.isContentEditable;
  }

  debounce(func, wait) {
    let timeout;
    return (...args) => {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }
}

// Initialize
const viewportManager = new ViewportHeightManager();

export { viewportManager, ViewportHeightManager };
```

### 6.4 React Hook for Viewport Height

```typescript
// hooks/useViewportHeight.ts
import { useState, useEffect } from 'react';

interface ViewportHeight {
  vh: number;
  svh: number;
  lvh: number;
  vhFull: string;
  svhFull: string;
  lvhFull: string;
  keyboardHeight: number;
  isKeyboardOpen: boolean;
}

export function useViewportHeight(): ViewportHeight {
  const [state, setState] = useState<ViewportHeight>({
    vh: typeof window !== 'undefined' ? window.innerHeight * 0.01 : 0,
    svh: 0,
    lvh: 0,
    vhFull: '100vh',
    svhFull: '100vh',
    lvhFull: '100vh',
    keyboardHeight: 0,
    isKeyboardOpen: false,
  });

  useEffect(() => {
    let svh = window.innerHeight * 0.01;
    let lvh = svh;

    const calculate = () => {
      const vh = window.innerHeight * 0.01;
      if (vh > lvh) lvh = vh;

      setState(prev => ({
        ...prev,
        vh,
        svh,
        lvh,
        vhFull: `${vh * 100}px`,
        svhFull: `${svh * 100}px`,
        lvhFull: `${lvh * 100}px`,
      }));
    };

    const handleKeyboard = (e: CustomEvent) => {
      setState(prev => ({
        ...prev,
        keyboardHeight: e.detail.height,
        isKeyboardOpen: e.detail.isOpen,
      }));
    };

    calculate();
    window.addEventListener('resize', calculate);
    window.addEventListener('keyboardchange', handleKeyboard as EventListener);

    return () => {
      window.removeEventListener('resize', calculate);
      window.removeEventListener('keyboardchange', handleKeyboard as EventListener);
    };
  }, []);

  return state;
}

// Usage
function FullScreenModal() {
  const { vhFull, isKeyboardOpen } = useViewportHeight();

  return (
    <div
      className="fixed inset-0"
      style={{ height: vhFull }}
    >
      <div className={`content ${isKeyboardOpen ? 'keyboard-open' : ''}`}>
        {/* Modal content */}
      </div>
    </div>
  );
}
```

### 6.5 Tailwind Plugin for Viewport Units

```typescript
// NOTE: Tailwind v4 uses CSS-first config (@theme in globals.css).
// This plugin pattern is for legacy Tailwind v3 projects or custom plugin files.
// tailwind-vh-plugin.ts
import plugin from 'tailwindcss/plugin';

export default {
  plugins: [
    plugin(function({ addUtilities }) {
      const heights = {
        'screen-vh': 'var(--vh-full, 100vh)',
        'screen-svh': 'var(--svh-full, 100vh)',
        'screen-dvh': 'var(--vh-full, 100vh)',
        'screen-lvh': 'var(--lvh-full, 100vh)',
      };

      const newUtilities: Record<string, Record<string, string>> = {};

      // Height utilities
      Object.entries(heights).forEach(([name, value]) => {
        newUtilities[`.h-${name}`] = { height: value };
        newUtilities[`.min-h-${name}`] = { minHeight: value };
        newUtilities[`.max-h-${name}`] = { maxHeight: value };
      });

      // Fractional heights
      [25, 50, 75].forEach(percent => {
        newUtilities[`.h-${percent}vh`] = {
          height: `calc(var(--vh, 1vh) * ${percent})`
        };
      });

      addUtilities(newUtilities);
    }),
  ],
};
```

---

## 7. FLEXBOX GAP (Not Supported in Chrome < 84)

### 7.1 The Problem

Flexbox `gap` property is not supported in Chrome < 84. Must use margin-based fallbacks.

### 7.2 Complete Margin-Based Fallback System

```css
/*
 * Flexbox Gap Fallback System
 * RTL-aware using margin-inline-start
 * Covers gap-1 through gap-16
 */

/* Detection - old Android gets fallback */
@supports not (gap: 1rem) {
  /* Row gap fallback (flex-row) */
  .flex-row.gap-1 > * + * { margin-inline-start: 0.25rem; }
  .flex-row.gap-2 > * + * { margin-inline-start: 0.5rem; }
  .flex-row.gap-3 > * + * { margin-inline-start: 0.75rem; }
  .flex-row.gap-4 > * + * { margin-inline-start: 1rem; }
  .flex-row.gap-5 > * + * { margin-inline-start: 1.25rem; }
  .flex-row.gap-6 > * + * { margin-inline-start: 1.5rem; }
  .flex-row.gap-8 > * + * { margin-inline-start: 2rem; }
  .flex-row.gap-10 > * + * { margin-inline-start: 2.5rem; }
  .flex-row.gap-12 > * + * { margin-inline-start: 3rem; }
  .flex-row.gap-16 > * + * { margin-inline-start: 4rem; }

  /* Column gap fallback (flex-col) */
  .flex-col.gap-1 > * + * { margin-top: 0.25rem; }
  .flex-col.gap-2 > * + * { margin-top: 0.5rem; }
  .flex-col.gap-3 > * + * { margin-top: 0.75rem; }
  .flex-col.gap-4 > * + * { margin-top: 1rem; }
  .flex-col.gap-5 > * + * { margin-top: 1.25rem; }
  .flex-col.gap-6 > * + * { margin-top: 1.5rem; }
  .flex-col.gap-8 > * + * { margin-top: 2rem; }
  .flex-col.gap-10 > * + * { margin-top: 2.5rem; }
  .flex-col.gap-12 > * + * { margin-top: 3rem; }
  .flex-col.gap-16 > * + * { margin-top: 4rem; }

  /* Default flex (row) */
  .flex:not(.flex-col).gap-1 > * + * { margin-inline-start: 0.25rem; }
  .flex:not(.flex-col).gap-2 > * + * { margin-inline-start: 0.5rem; }
  .flex:not(.flex-col).gap-3 > * + * { margin-inline-start: 0.75rem; }
  .flex:not(.flex-col).gap-4 > * + * { margin-inline-start: 1rem; }
  .flex:not(.flex-col).gap-5 > * + * { margin-inline-start: 1.25rem; }
  .flex:not(.flex-col).gap-6 > * + * { margin-inline-start: 1.5rem; }
  .flex:not(.flex-col).gap-8 > * + * { margin-inline-start: 2rem; }
  .flex:not(.flex-col).gap-10 > * + * { margin-inline-start: 2.5rem; }
  .flex:not(.flex-col).gap-12 > * + * { margin-inline-start: 3rem; }
  .flex:not(.flex-col).gap-16 > * + * { margin-inline-start: 4rem; }

  /* Separate x and y gaps */
  .gap-x-1 > * + * { margin-inline-start: 0.25rem; }
  .gap-x-2 > * + * { margin-inline-start: 0.5rem; }
  .gap-x-3 > * + * { margin-inline-start: 0.75rem; }
  .gap-x-4 > * + * { margin-inline-start: 1rem; }
  .gap-x-6 > * + * { margin-inline-start: 1.5rem; }
  .gap-x-8 > * + * { margin-inline-start: 2rem; }

  .gap-y-1 > * + * { margin-top: 0.25rem; }
  .gap-y-2 > * + * { margin-top: 0.5rem; }
  .gap-y-3 > * + * { margin-top: 0.75rem; }
  .gap-y-4 > * + * { margin-top: 1rem; }
  .gap-y-6 > * + * { margin-top: 1.5rem; }
  .gap-y-8 > * + * { margin-top: 2rem; }
}

/* Explicit class for old Android (when JS-detected) */
.is-android-old {
  /* Row gaps */
  .flex-row.gap-1 > * + * { margin-inline-start: 0.25rem; }
  .flex-row.gap-2 > * + * { margin-inline-start: 0.5rem; }
  .flex-row.gap-3 > * + * { margin-inline-start: 0.75rem; }
  .flex-row.gap-4 > * + * { margin-inline-start: 1rem; }
  .flex-row.gap-5 > * + * { margin-inline-start: 1.25rem; }
  .flex-row.gap-6 > * + * { margin-inline-start: 1.5rem; }
  .flex-row.gap-8 > * + * { margin-inline-start: 2rem; }

  /* Column gaps */
  .flex-col.gap-1 > * + * { margin-top: 0.25rem; }
  .flex-col.gap-2 > * + * { margin-top: 0.5rem; }
  .flex-col.gap-3 > * + * { margin-top: 0.75rem; }
  .flex-col.gap-4 > * + * { margin-top: 1rem; }
  .flex-col.gap-5 > * + * { margin-top: 1.25rem; }
  .flex-col.gap-6 > * + * { margin-top: 1.5rem; }
  .flex-col.gap-8 > * + * { margin-top: 2rem; }
}
```

### 7.3 Tailwind Plugin for Gap Fallback

```typescript
// tailwind-gap-fallback.ts
// NOTE: Tailwind v4 uses CSS-first config (@theme in globals.css).
// This plugin pattern is for legacy Tailwind v3 projects or custom plugin files.
import plugin from 'tailwindcss/plugin';

export default plugin(function({ addVariant, addUtilities, theme }) {
  // Add @supports variant
  addVariant('no-gap', '@supports not (gap: 1rem)');

  // Add old-android variant (requires JS class)
  addVariant('old-android', '.is-android-old &');

  // Generate gap fallback utilities
  const spacing = theme('spacing');
  const gapFallbacks: Record<string, Record<string, string>> = {};

  Object.entries(spacing).forEach(([key, value]) => {
    // Skip non-numeric keys
    if (isNaN(parseFloat(key))) return;

    // Row gap (horizontal)
    gapFallbacks[`.gap-fallback-x-${key} > * + *`] = {
      'margin-inline-start': value,
    };

    // Column gap (vertical)
    gapFallbacks[`.gap-fallback-y-${key} > * + *`] = {
      'margin-top': value,
    };
  });

  addUtilities(gapFallbacks);
});

// Usage in tailwind config (ESM):
// import gapFallback from './tailwind-gap-fallback';
// export default { plugins: [gapFallback] };
```

### 7.4 CSS-in-JS Gap Fallback Utility

```typescript
// utils/gapFallback.ts

type GapSize = 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | 12 | 16;

const gapValues: Record<GapSize, string> = {
  1: '0.25rem',
  2: '0.5rem',
  3: '0.75rem',
  4: '1rem',
  5: '1.25rem',
  6: '1.5rem',
  8: '2rem',
  10: '2.5rem',
  12: '3rem',
  16: '4rem',
};

interface GapFallbackStyles {
  gap: string;
  // Fallback styles for child elements
  '& > * + *'?: {
    marginInlineStart?: string;
    marginTop?: string;
  };
}

export function flexRowGap(size: GapSize): GapFallbackStyles {
  return {
    gap: gapValues[size],
    '& > * + *': {
      marginInlineStart: gapValues[size],
    },
  };
}

export function flexColGap(size: GapSize): GapFallbackStyles {
  return {
    gap: gapValues[size],
    '& > * + *': {
      marginTop: gapValues[size],
    },
  };
}

// Usage with styled-components or emotion
const FlexRow = styled.div`
  display: flex;
  flex-direction: row;
  ${flexRowGap(4)}

  @supports (gap: 1rem) {
    & > * + * {
      margin-inline-start: 0;
    }
  }
`;
```

### 7.5 React Component with Gap Fallback

```tsx
// components/FlexGap.tsx
import { ReactNode, CSSProperties } from 'react';
import { cn } from '@/lib/utils';

interface FlexGapProps {
  children: ReactNode;
  direction?: 'row' | 'col';
  gap?: 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | 12 | 16;
  className?: string;
  style?: CSSProperties;
  wrap?: boolean;
  align?: 'start' | 'center' | 'end' | 'stretch';
  justify?: 'start' | 'center' | 'end' | 'between' | 'around';
}

const gapClasses = {
  1: 'gap-1',
  2: 'gap-2',
  3: 'gap-3',
  4: 'gap-4',
  5: 'gap-5',
  6: 'gap-6',
  8: 'gap-8',
  10: 'gap-10',
  12: 'gap-12',
  16: 'gap-16',
};

/**
 * Flex container with automatic gap fallback for old Android
 * Uses margin-based fallback when gap is not supported
 */
export function FlexGap({
  children,
  direction = 'row',
  gap = 4,
  className,
  style,
  wrap = false,
  align = 'stretch',
  justify = 'start',
  ref,
}: FlexGapProps & { ref?: React.Ref<HTMLDivElement> }) {
  return (
    <div
      ref={ref}
      className={cn(
        'flex',
        direction === 'col' ? 'flex-col' : 'flex-row',
        gapClasses[gap],
        wrap && 'flex-wrap',
        {
          'items-start': align === 'start',
          'items-center': align === 'center',
          'items-end': align === 'end',
          'items-stretch': align === 'stretch',
          'justify-start': justify === 'start',
          'justify-center': justify === 'center',
          'justify-end': justify === 'end',
          'justify-between': justify === 'between',
          'justify-around': justify === 'around',
        },
        className
      )}
      style={style}
    >
      {children}
    </div>
  );
}

// Usage
function Example() {
  return (
    <FlexGap direction="row" gap={4} align="center">
      <span>Item 1</span>
      <span>Item 2</span>
      <span>Item 3</span>
    </FlexGap>
  );
}
```

### 7.6 Handling Wrapped Flex with Gap

```css
/*
 * Wrapped flex gap is more complex - need negative margin trick
 * This handles both row and column gaps in wrapped flex
 */

@supports not (gap: 1rem) {
  .flex-wrap-gap-4 {
    /* Negative margin on container */
    margin: -0.5rem;
  }

  .flex-wrap-gap-4 > * {
    /* Positive margin on all sides of children */
    margin: 0.5rem;
  }
}

/* More complete solution */
.flex-wrap-container {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem; /* Modern browsers */
}

/* Fallback for old browsers */
@supports not (gap: 1rem) {
  .flex-wrap-container {
    margin: -0.5rem;
  }

  .flex-wrap-container > * {
    margin: 0.5rem;
  }
}

/* RTL-aware version for non-wrapped flex */
[dir="rtl"] .flex-row.gap-4 > * + * {
  margin-inline-start: 1rem;
  margin-inline-end: 0;
}
```

---

## 8. CSS CONTAINMENT - CRITICAL BUG

### 8.1 The Problem

CSS `contain-content`, `contain-layout`, `contain-paint`, and `contain-strict` properties cause **elements to DISAPPEAR** during scroll on old Android Chrome (<90). This is a known rendering bug in Chrome's compositor.

**Symptoms:**
- Elements disappear and reappear while scrolling
- Components flicker or vanish temporarily
- Layout seems to "reset" during fast scrolling
- Elements only appear after scrolling stops

**Why it happens:** CSS containment creates optimization hints for the browser, but old Chrome's compositor has bugs that cause it to incorrectly cull (hide) contained elements that are still in the viewport.

### 8.2 Files Commonly Affected

Any component using Tailwind's `contain-content` class for performance optimization:
- Cards and list items
- Grid cells
- Data table rows
- Timeline entries
- Stats components

### 8.3 CSS Fix - MANDATORY for Android

Add to your `index.css` or `globals.css`:

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

### 8.4 JavaScript Detection (Required)

Ensure your Android detection in `index.html` adds the `.is-android` class:

```html
<script>
  // Android detection - add before closing </head>
  if (/Android/i.test(navigator.userAgent)) {
    document.documentElement.classList.add('is-android');
    const chromeVersion = parseInt(navigator.userAgent.match(/Chrome\/(\d+)/)?.[1] || '999');
    if (chromeVersion < 84) {
      document.documentElement.classList.add('is-android-old');
    }
  }
</script>
```

### 8.5 Verification

```bash
# Check for contain-content usage in components
grep -r "contain-content\|contain-layout\|contain-paint" --include="*.tsx" src/

# Verify CSS override is in place
grep -r "contain: none" src/index.css

# Test on Android device or emulator
# Scroll quickly through lists - elements should NOT disappear
```

### 8.6 When You CAN Use Containment

Containment is safe to use when:
- The app only targets modern browsers (Chrome 90+)
- You have feature detection and disable on old browsers
- Elements are always fully visible (not in scrollable containers)

### 8.7 Alternative Performance Optimizations

Instead of `contain-content`, use:

```css
/* For scroll performance */
.scroll-item {
  transform: translateZ(0); /* Force GPU layer - but use sparingly */
}

/* For paint containment without the bug */
.card {
  isolation: isolate; /* Creates stacking context without containment */
}

/* Virtual scrolling - better solution for long lists */
/* Use react-window or @tanstack/react-virtual */
```

---

## 9. CSS :has() (Not Supported)

### 8.1 The Problem

CSS `:has()` selector is not supported in any browser before Chrome 105. Need JavaScript alternatives.

### 8.2 JavaScript Alternatives

```javascript
/**
 * :has() Polyfill-like Solutions
 * Applies classes to parent elements based on child conditions
 */

// Solution 1: MutationObserver for dynamic content
class HasPolyfill {
  constructor() {
    this.rules = [];
    this.observer = null;
    this.init();
  }

  init() {
    // Check if :has() is supported
    try {
      document.querySelector(':has(*)');
      return; // Supported, no polyfill needed
    } catch {
      // Not supported, set up polyfill
      this.setupObserver();
    }
  }

  /**
   * Register a :has() rule
   * @param parentSelector - Selector for parent element
   * @param childSelector - Selector for child element
   * @param className - Class to add when child exists
   */
  register(parentSelector, childSelector, className) {
    this.rules.push({ parentSelector, childSelector, className });
    this.apply();
  }

  apply() {
    this.rules.forEach(({ parentSelector, childSelector, className }) => {
      // Find all matching parents
      document.querySelectorAll(parentSelector).forEach(parent => {
        const hasChild = parent.querySelector(childSelector) !== null;
        parent.classList.toggle(className, hasChild);
      });
    });
  }

  setupObserver() {
    this.observer = new MutationObserver(() => {
      this.apply();
    });

    this.observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class', 'disabled', 'checked', 'data-state'],
    });
  }

  destroy() {
    this.observer?.disconnect();
  }
}

// Initialize
const hasPolyfill = new HasPolyfill();

// Register rules
// Example: .card:has(.card-image) -> .card.has-image
hasPolyfill.register('.card', '.card-image', 'has-image');

// Example: .form-group:has(input:invalid) -> .form-group.has-invalid
hasPolyfill.register('.form-group', 'input:invalid', 'has-invalid');

// Example: .nav-item:has(.active) -> .nav-item.has-active-child
hasPolyfill.register('.nav-item', '.active', 'has-active-child');

export { hasPolyfill, HasPolyfill };
```

### 8.3 React Hook for :has() Alternative

```typescript
// hooks/useHas.ts
import { useEffect, useRef, useState } from 'react';

/**
 * Hook that mimics :has() behavior
 * Returns true if the ref element contains a matching child
 */
export function useHas<T extends HTMLElement>(
  selector: string
): [React.RefObject<T>, boolean] {
  const ref = useRef<T>(null);
  const [hasMatch, setHasMatch] = useState(false);

  useEffect(() => {
    if (!ref.current) return;

    const check = () => {
      const match = ref.current?.querySelector(selector) !== null;
      setHasMatch(match);
    };

    check();

    // Observe changes
    const observer = new MutationObserver(check);
    observer.observe(ref.current, {
      childList: true,
      subtree: true,
      attributes: true,
    });

    return () => observer.disconnect();
  }, [selector]);

  return [ref, hasMatch];
}

// Usage
function Card() {
  const [cardRef, hasImage] = useHas<HTMLDivElement>('.card-image');

  return (
    <div
      ref={cardRef}
      className={cn('card', hasImage && 'has-image')}
    >
      {/* children */}
    </div>
  );
}
```

### 8.4 CSS Patterns Without :has()

```css
/* Instead of: .card:has(.card-image) { padding: 0; } */

/* Option 1: Add class via JS */
.card.has-image {
  padding: 0;
}

/* Option 2: Reverse the logic - style from child */
.card {
  padding: 1rem;
}

.card-image {
  /* Negative margin to "remove" parent padding */
  margin: -1rem;
  margin-bottom: 0;
}

/* Option 3: Use data attributes */
.card[data-has-image="true"] {
  padding: 0;
}

/* Instead of: .form-group:has(input:focus) */
/* Use focus-within (well supported) */
.form-group:focus-within {
  border-color: blue;
}

/* Instead of: .table-row:has(input:checked) */
/* Option 1: Adjacent sibling from input */
input:checked + .table-row-content {
  background: yellow;
}

/* Option 2: JS-applied class */
.table-row.is-checked {
  background: yellow;
}
```

### 8.5 Common :has() Replacements

```css
/*
 * Common :has() patterns and their fallbacks
 */

/* 1. Parent styling based on empty/non-empty state */
/* :has() version: .container:has(> *) { display: block; } */
/* Fallback: Use :empty pseudo-class */
.container:empty {
  display: none;
}
.container:not(:empty) {
  display: block;
}

/* 2. Form validation styling */
/* :has() version: .field:has(input:invalid) { border-color: red; } */
/* Fallback: Use focus-within + JS class */
.field.has-error {
  border-color: red;
}

/* 3. Navigation active state */
/* :has() version: .nav-item:has(.active) { font-weight: bold; } */
/* Fallback: Add class to parent in router */
.nav-item.is-active {
  font-weight: bold;
}

/* 4. Quantity-based styling */
/* :has() version: .list:has(> *:nth-child(4)) { grid-template-columns: repeat(2, 1fr); } */
/* Fallback: Add data attribute via JS */
.list[data-count="4"],
.list[data-count="5"],
.list[data-count="6"] {
  grid-template-columns: repeat(2, 1fr);
}

/* 5. Sibling-based styling */
/* :has() version: .card:has(+ .card) { margin-bottom: 1rem; } */
/* Fallback: Adjacent sibling selector (reversed logic) */
.card + .card {
  margin-top: 1rem;
}
```

---

## 9. ICONS IN FLEX (shrink-0)

### 9.1 The Problem

Icons and fixed-width elements in flex containers can shrink when there's not enough space. Old Android may have additional issues with SVG sizing.

### 9.2 Preventing Icon Squishing

```css
/* Base icon protection */
.icon,
.flex > svg,
.flex > img[src$=".svg"],
.inline-flex > svg {
  flex-shrink: 0;
  min-width: max-content;
}

/* Explicit icon sizes */
.icon-sm {
  width: 1rem;
  height: 1rem;
  flex-shrink: 0;
}

.icon-md {
  width: 1.25rem;
  height: 1.25rem;
  flex-shrink: 0;
}

.icon-lg {
  width: 1.5rem;
  height: 1.5rem;
  flex-shrink: 0;
}

/* Icon in button pattern */
.btn-icon {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

.btn-icon > svg,
.btn-icon > .icon {
  flex-shrink: 0;
  width: 1.25rem;
  height: 1.25rem;
}

/* Old Android SVG fixes */
.is-android-old svg {
  /* Force dimensions */
  min-width: 1em;
  min-height: 1em;
}

.is-android-old .icon {
  /* Explicit dimensions for old WebView */
  display: inline-block;
  width: 1.25rem;
  height: 1.25rem;
  line-height: 1;
}
```

### 9.3 React Icon Component with Protection

```tsx
// components/Icon.tsx
import { SVGProps, ComponentType } from 'react';
import { cn } from '@/lib/utils';

type IconSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

interface IconProps extends SVGProps<SVGSVGElement> {
  icon: ComponentType<SVGProps<SVGSVGElement>>;
  size?: IconSize;
  className?: string;
}

const sizeClasses: Record<IconSize, string> = {
  xs: 'w-3 h-3',
  sm: 'w-4 h-4',
  md: 'w-5 h-5',
  lg: 'w-6 h-6',
  xl: 'w-8 h-8',
};

/**
 * Icon component with flex-shrink protection
 * Prevents icons from being squished in flex containers
 */
export function Icon({ icon: IconComponent, size = 'md', className, ref, ...props }: IconProps & { ref?: React.Ref<SVGSVGElement> }) {
  return (
    <IconComponent
      ref={ref}
      className={cn(
        // Prevent shrinking
        'shrink-0',
        // Explicit size
        sizeClasses[size],
        // Custom classes
        className
      )}
      aria-hidden="true"
      {...props}
    />
  );
}

// Usage
import { ChevronRight, Check, X } from 'lucide-react';

function Example() {
  return (
    <button className="flex items-center gap-2">
      <Icon icon={Check} size="sm" />
      <span className="truncate">Very long button text that might cause issues</span>
      <Icon icon={ChevronRight} size="sm" className="rtl:rotate-180" />
    </button>
  );
}
```

### 9.4 Button with Icon Pattern

```tsx
// components/ButtonIcon.tsx
import { ReactNode, ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface ButtonIconProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  startIcon?: ReactNode;
  endIcon?: ReactNode;
  children: ReactNode;
}

export function ButtonIcon({ startIcon, endIcon, children, className, ref, ...props }: ButtonIconProps & { ref?: React.Ref<HTMLButtonElement> }) {
  return (
    <button
      ref={ref}
      className={cn(
        'inline-flex items-center justify-center gap-2',
        'min-h-11 px-4 py-2',
        'rounded-md font-medium',
        'transition-colors',
        className
      )}
      {...props}
    >
      {startIcon && (
        <span className="shrink-0 w-5 h-5 flex items-center justify-center">
          {startIcon}
        </span>
      )}
      <span className="truncate min-w-0">{children}</span>
      {endIcon && (
        <span className="shrink-0 w-5 h-5 flex items-center justify-center rtl:rotate-180">
          {endIcon}
        </span>
      )}
    </button>
  );
}
```

### 9.5 List Item with Icon Pattern

```css
/* List item with icon that won't shrink */
.list-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  min-height: 3rem; /* 48px touch target */
}

.list-item-icon {
  flex-shrink: 0;
  width: 1.5rem;
  height: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.list-item-content {
  flex: 1;
  min-width: 0; /* Enable text truncation */
}

.list-item-content-title {
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.list-item-content-subtitle {
  font-size: 0.875rem;
  color: var(--muted-foreground);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.list-item-action {
  flex-shrink: 0;
  margin-inline-start: auto;
}
```

---

## 10. SCROLL CONTAINERS

### 10.1 The Problem

Old Android has issues with:
- Momentum scrolling
- Nested scrollable areas
- Overscroll behavior
- Scroll snap

### 10.2 Momentum Scrolling Fix

```css
/* Enable momentum scrolling on old Android/iOS */
.scroll-container {
  overflow-y: auto;
  overflow-x: hidden;

  /* iOS momentum scrolling */
  -webkit-overflow-scrolling: touch;

  /* Prevent scroll chaining */
  overscroll-behavior: contain;
}

/* Fallback for overscroll-behavior */
@supports not (overscroll-behavior: contain) {
  .scroll-container {
    /* Will need JS solution for scroll containment */
  }
}

/* Scrollbar styling (works on most Android) */
.scroll-container::-webkit-scrollbar {
  width: 4px;
}

.scroll-container::-webkit-scrollbar-track {
  background: transparent;
}

.scroll-container::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 2px;
}

/* Hide scrollbar but keep functionality */
.scroll-hidden::-webkit-scrollbar {
  display: none;
}

.scroll-hidden {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
```

### 10.3 Nested Scroll Fix

```css
/*
 * Nested scroll containers need min-h-0 to work properly
 * This is the most common issue on old Android
 */

/* Parent flex container */
.outer-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  /* Or explicit height */
  height: var(--vh-full, 100vh);
}

.header {
  flex-shrink: 0;
  height: 3.5rem;
}

/* This is the key - min-h-0 allows content to scroll */
.scrollable-content {
  flex: 1;
  min-height: 0; /* CRITICAL for nested scroll */
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

/* Common pattern: Page with fixed header and footer */
.page-layout {
  display: flex;
  flex-direction: column;
  height: var(--vh-full, 100vh);
}

.page-header {
  flex-shrink: 0;
}

.page-content {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

.page-footer {
  flex-shrink: 0;
}
```

### 10.4 JavaScript Scroll Containment

```javascript
/**
 * Scroll containment for old Android
 * Prevents scroll from propagating to parent/body
 */

class ScrollContainment {
  constructor(element) {
    this.element = element;
    this.startY = 0;
    this.init();
  }

  init() {
    // Check if overscroll-behavior is supported
    if (CSS.supports('overscroll-behavior', 'contain')) {
      this.element.style.overscrollBehavior = 'contain';
      return;
    }

    // Fallback: Manual scroll containment
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true });
    this.element.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: false });
  }

  handleTouchStart(e) {
    this.startY = e.touches[0].clientY;
  }

  handleTouchMove(e) {
    const currentY = e.touches[0].clientY;
    const deltaY = this.startY - currentY;

    const { scrollTop, scrollHeight, clientHeight } = this.element;
    const isAtTop = scrollTop <= 0;
    const isAtBottom = scrollTop + clientHeight >= scrollHeight;

    // Prevent scroll if at boundary and trying to scroll further
    if ((isAtTop && deltaY < 0) || (isAtBottom && deltaY > 0)) {
      e.preventDefault();
    }
  }

  destroy() {
    this.element.removeEventListener('touchstart', this.handleTouchStart);
    this.element.removeEventListener('touchmove', this.handleTouchMove);
  }
}

// Usage
const scrollElement = document.querySelector('.scroll-container');
const containment = new ScrollContainment(scrollElement);

// Cleanup
// containment.destroy();
```

### 10.5 React Hook for Scroll Containment

```typescript
// hooks/useScrollContainment.ts
import { useEffect, useRef } from 'react';

export function useScrollContainment<T extends HTMLElement>() {
  const ref = useRef<T>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    // Check native support
    if (CSS.supports('overscroll-behavior', 'contain')) {
      element.style.overscrollBehavior = 'contain';
      return;
    }

    let startY = 0;

    const handleTouchStart = (e: TouchEvent) => {
      startY = e.touches[0].clientY;
    };

    const handleTouchMove = (e: TouchEvent) => {
      const currentY = e.touches[0].clientY;
      const deltaY = startY - currentY;

      const { scrollTop, scrollHeight, clientHeight } = element;
      const isAtTop = scrollTop <= 0;
      const isAtBottom = scrollTop + clientHeight >= scrollHeight;

      if ((isAtTop && deltaY < 0) || (isAtBottom && deltaY > 0)) {
        e.preventDefault();
      }
    };

    element.addEventListener('touchstart', handleTouchStart, { passive: true });
    element.addEventListener('touchmove', handleTouchMove, { passive: false });

    return () => {
      element.removeEventListener('touchstart', handleTouchStart);
      element.removeEventListener('touchmove', handleTouchMove);
    };
  }, []);

  return ref;
}

// Usage
function ScrollableList() {
  const scrollRef = useScrollContainment<HTMLDivElement>();

  return (
    <div
      ref={scrollRef}
      className="overflow-y-auto h-64"
    >
      {/* Scrollable content */}
    </div>
  );
}
```

### 10.6 Pull-to-Refresh Pattern

```css
/* Disable browser pull-to-refresh on scroll containers */
.disable-pull-refresh {
  overscroll-behavior-y: contain;
}

/* Fallback */
@supports not (overscroll-behavior-y: contain) {
  html, body {
    overflow: hidden;
    position: fixed;
    width: 100%;
    height: 100%;
  }

  .app-container {
    overflow-y: auto;
    height: 100%;
    -webkit-overflow-scrolling: touch;
  }
}
```

---

## 11. HOVER STATES

### 11.1 The Problem

Touch devices don't have true hover. On old Android, hover states can become "stuck" after touch.

### 11.2 Media Query Pattern

```css
/* Only apply hover styles on devices that support hover */
@media (hover: hover) and (pointer: fine) {
  .button:hover {
    background-color: var(--hover-bg);
    transform: translateY(-1px);
  }

  .card:hover {
    box-shadow: var(--shadow-lg);
  }

  .link:hover {
    color: var(--link-hover);
    text-decoration: underline;
  }
}

/* Touch devices get active states instead */
@media (hover: none) {
  .button:active {
    background-color: var(--active-bg);
    transform: scale(0.98);
  }

  .card:active {
    background-color: var(--card-active);
  }

  .link:active {
    color: var(--link-active);
  }
}

/* Fallback for browsers that don't support hover media query */
.is-android-old .button:active {
  background-color: var(--active-bg);
}

/* Prevent sticky hover on touch */
@media (hover: none) {
  .button:hover {
    /* Reset hover styles on touch devices */
    background-color: inherit;
    transform: none;
  }
}
```

### 11.3 JavaScript Hover Fix for Old Android

```javascript
/**
 * Fix sticky hover on touch devices
 * Removes hover state after touch ends
 */

class TouchHoverFix {
  constructor() {
    this.init();
  }

  init() {
    // Check if device supports touch
    if (!('ontouchstart' in window)) return;

    // Add touch detection class
    document.documentElement.classList.add('touch-device');

    // Fix stuck hover states
    document.addEventListener('touchend', this.clearHover.bind(this), { passive: true });
  }

  clearHover(e) {
    const target = e.target;
    if (!target) return;

    // Force re-render by temporarily adding/removing a class
    target.classList.add('touch-release');
    requestAnimationFrame(() => {
      target.classList.remove('touch-release');
    });
  }
}

// Initialize
new TouchHoverFix();

// CSS to use with this
/*
.touch-device .button:hover {
  // Don't apply hover on touch devices
  background-color: inherit;
}

.button:active,
.touch-release.button {
  background-color: var(--active-bg);
}
*/
```

### 11.4 Complete Hover/Active Pattern

```css
/*
 * Complete hover/active pattern for cross-device compatibility
 */

/* Base button styles */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.75rem 1.5rem;
  background-color: var(--btn-bg);
  color: var(--btn-text);
  border-radius: 0.5rem;
  transition: background-color 0.15s, transform 0.1s;
  cursor: pointer;

  /* Prevent text selection on double-tap */
  user-select: none;
  -webkit-user-select: none;

  /* Prevent tap highlight on mobile */
  -webkit-tap-highlight-color: transparent;
}

/* Hover for mouse devices only */
@media (hover: hover) and (pointer: fine) {
  .btn:hover:not(:disabled) {
    background-color: var(--btn-hover);
  }
}

/* Active state for all devices */
.btn:active:not(:disabled) {
  background-color: var(--btn-active);
  transform: scale(0.98);
}

/* Focus state for keyboard navigation */
.btn:focus-visible {
  outline: 2px solid var(--focus-ring);
  outline-offset: 2px;
}

/* Disabled state */
.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Touch device specific - larger tap target */
@media (pointer: coarse) {
  .btn {
    min-height: 44px;
    min-width: 44px;
  }
}
```

### 11.5 React Component with Proper States

```tsx
// components/TouchButton.tsx
import { ButtonHTMLAttributes, useState } from 'react';
import { cn } from '@/lib/utils';

interface TouchButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost';
}

export function TouchButton({ className, variant = 'primary', children, ref, ...props }: TouchButtonProps & { ref?: React.Ref<HTMLButtonElement> }) {
  const [isPressed, setIsPressed] = useState(false);

  return (
    <button
      ref={ref}
      className={cn(
        // Base styles
        'inline-flex items-center justify-center',
        'px-4 py-2 rounded-md font-medium',
        'min-h-11 min-w-[44px]', // Touch target
        'transition-colors duration-150',
        'select-none', // Prevent text selection

        // Variant styles
        variant === 'primary' && 'bg-primary text-primary-foreground',
        variant === 'secondary' && 'bg-secondary text-secondary-foreground',
        variant === 'ghost' && 'bg-transparent hover:bg-accent',

        // Pressed state (works on all devices)
        isPressed && 'scale-[0.98] opacity-90',

        // Disabled
        'disabled:opacity-50 disabled:pointer-events-none',

        className
      )}
      onTouchStart={() => setIsPressed(true)}
      onTouchEnd={() => setIsPressed(false)}
      onTouchCancel={() => setIsPressed(false)}
      onMouseDown={() => setIsPressed(true)}
      onMouseUp={() => setIsPressed(false)}
      onMouseLeave={() => setIsPressed(false)}
      {...props}
    >
      {children}
    </button>
  );
}
```

---

## 12. TYPOGRAPHY

### 12.1 The Problem

Old Android has issues with:
- Very small fonts being scaled up
- Text truncation in flex containers
- Font rendering differences
- Line height inconsistencies

### 12.2 Minimum Font Size

```css
/*
 * Old Android may force minimum font size of 12px
 * Design with this in mind
 */

/* Base typography - never go below 12px */
:root {
  --text-xs: 0.75rem;   /* 12px - minimum safe size */
  --text-sm: 0.875rem;  /* 14px */
  --text-base: 1rem;    /* 16px */
  --text-lg: 1.125rem;  /* 18px */
  --text-xl: 1.25rem;   /* 20px */
  --text-2xl: 1.5rem;   /* 24px */
}

/* If you MUST use smaller text, use scale transform */
.text-xxs {
  font-size: 0.75rem; /* 12px base */
  transform: scale(0.833); /* Scales to ~10px visually */
  transform-origin: top start;
}

/* For labels and captions */
.caption {
  font-size: max(0.75rem, 12px); /* Never below 12px */
  line-height: 1.4;
}

/* Input labels - ensure readability */
.label {
  font-size: 0.875rem; /* 14px */
  font-weight: 500;
}

/* Old Android line-height fix */
.is-android-old {
  /* More generous line-height for readability */
  line-height: 1.6;
}

.is-android-old p,
.is-android-old li {
  line-height: 1.7;
}
```

### 12.3 Text Truncation with min-w-0

```css
/*
 * Text truncation in flex requires min-w-0
 * This is especially problematic on old Android
 */

/* Basic truncation */
.truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Truncation in flex - MUST have min-w-0 */
.flex-item-truncate {
  min-width: 0; /* CRITICAL */
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Multi-line truncation (webkit only - works on Android) */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Flex container with truncating text */
.list-item-with-truncate {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.list-item-icon {
  flex-shrink: 0;
  width: 1.5rem;
  height: 1.5rem;
}

.list-item-text {
  flex: 1;
  min-width: 0; /* Enable truncation */
}

.list-item-title {
  font-size: 1rem;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.list-item-subtitle {
  font-size: 0.875rem;
  color: var(--muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
```

### 12.4 Font Loading for Old Android

```css
/*
 * Font loading with fallback for old Android
 * Use font-display: swap to prevent FOIT
 */

@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2'),
       url('/fonts/custom.woff') format('woff'); /* Fallback for old browsers */
  font-weight: 400;
  font-style: normal;
  font-display: swap; /* Show fallback immediately, swap when loaded */
}

/* System font stack as fallback */
:root {
  --font-sans: 'CustomFont', -apple-system, BlinkMacSystemFont,
    'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;

  --font-hebrew: 'CustomFont', 'Segoe UI', Roboto, 'Arial Hebrew',
    'Noto Sans Hebrew', sans-serif;
}

/* Hebrew-specific font settings */
[lang="he"] {
  font-family: var(--font-hebrew);
}

/* Number display (always LTR) */
.number {
  font-variant-numeric: tabular-nums;
  direction: ltr;
  display: inline-block;
}
```

### 12.5 React Typography Component

```tsx
// components/Text.tsx
import { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

type TextVariant = 'body' | 'caption' | 'label' | 'heading';
type TextSize = 'xs' | 'sm' | 'base' | 'lg' | 'xl' | '2xl';

interface TextProps extends HTMLAttributes<HTMLSpanElement> {
  as?: 'span' | 'p' | 'div' | 'label';
  variant?: TextVariant;
  size?: TextSize;
  truncate?: boolean | number; // true for single line, number for line-clamp
  weight?: 'normal' | 'medium' | 'semibold' | 'bold';
}

const sizeClasses: Record<TextSize, string> = {
  xs: 'text-xs', // 12px minimum
  sm: 'text-sm',
  base: 'text-base',
  lg: 'text-lg',
  xl: 'text-xl',
  '2xl': 'text-2xl',
};

const variantClasses: Record<TextVariant, string> = {
  body: 'text-foreground leading-relaxed',
  caption: 'text-muted-foreground text-sm',
  label: 'text-foreground font-medium',
  heading: 'text-foreground font-semibold tracking-tight',
};

export function Text({
  as: Component = 'span',
  variant = 'body',
  size = 'base',
  truncate,
  weight,
  className,
  children,
  ref,
  ...props
}: TextProps & { ref?: React.Ref<HTMLSpanElement> }) {
  const truncateClass = truncate === true
    ? 'truncate min-w-0'
    : typeof truncate === 'number'
      ? `line-clamp-${truncate} min-w-0`
      : '';

  return (
    <Component
      ref={ref}
      className={cn(
        variantClasses[variant],
        sizeClasses[size],
        truncateClass,
        weight === 'medium' && 'font-medium',
        weight === 'semibold' && 'font-semibold',
        weight === 'bold' && 'font-bold',
        className
      )}
      {...props}
    >
      {children}
    </Component>
  );
}

// Usage
function Example() {
  return (
    <div className="flex items-center gap-3">
      <span className="shrink-0">Icon</span>
      <div className="flex-1 min-w-0">
        <Text variant="label" truncate>
          Very long title that needs to be truncated on small screens
        </Text>
        <Text variant="caption" truncate={2}>
          Multi-line description that can span up to two lines before being truncated
        </Text>
      </div>
    </div>
  );
}
```

---

## 13. SAFE AREAS

### 13.1 The Problem

Old Android may not fully support `env()` safe area insets, causing content to be hidden behind notches or navigation bars.

### 13.2 CSS with Fallbacks

```css
/*
 * Safe area handling with fallbacks for old Android
 */

:root {
  /* Default safe area values (for devices without notches) */
  --safe-area-inset-top: 0px;
  --safe-area-inset-right: 0px;
  --safe-area-inset-bottom: 0px;
  --safe-area-inset-left: 0px;

  /* Try to use env() if available */
  --safe-area-inset-top: env(safe-area-inset-top, 0px);
  --safe-area-inset-right: env(safe-area-inset-right, 0px);
  --safe-area-inset-bottom: env(safe-area-inset-bottom, 0px);
  --safe-area-inset-left: env(safe-area-inset-left, 0px);
}

/* Viewport meta tag must include viewport-fit=cover */
/* <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"> */

/* Header with safe area */
.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 50;

  /* Fallback padding */
  padding-top: 0.75rem;
  /* Add safe area padding */
  padding-top: calc(0.75rem + var(--safe-area-inset-top));

  /* For very old browsers, use padding-top directly */
  padding-top: calc(0.75rem + env(safe-area-inset-top, 0px));
}

/* Bottom navigation with safe area */
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 50;

  /* Base padding */
  padding-bottom: 0.5rem;
  /* Add safe area */
  padding-bottom: calc(0.5rem + var(--safe-area-inset-bottom));
  padding-bottom: calc(0.5rem + env(safe-area-inset-bottom, 0px));
}

/* Avoid double padding - common mistake */
.page-content {
  /* Don't add safe area here if header/footer already have it */
  padding-top: 3.5rem; /* Header height only */
  padding-bottom: 4rem; /* Footer height only */
}

/* Full page with safe areas */
.safe-page {
  min-height: 100vh;
  min-height: var(--vh-full, 100vh);

  padding-top: var(--safe-area-inset-top);
  padding-bottom: var(--safe-area-inset-bottom);
  padding-left: var(--safe-area-inset-left);
  padding-right: var(--safe-area-inset-right);
}

/* RTL-aware safe areas */
[dir="rtl"] {
  --safe-area-inset-start: var(--safe-area-inset-right);
  --safe-area-inset-end: var(--safe-area-inset-left);
}

[dir="ltr"] {
  --safe-area-inset-start: var(--safe-area-inset-left);
  --safe-area-inset-end: var(--safe-area-inset-right);
}

.sidebar {
  padding-inline-start: calc(1rem + var(--safe-area-inset-start));
}
```

### 13.3 JavaScript Safe Area Detection

```javascript
/**
 * Safe area detection and application for old Android
 */

class SafeAreaManager {
  constructor() {
    this.insets = {
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    };
    this.init();
  }

  init() {
    // Try to detect safe areas via CSS
    this.detectFromCSS();

    // Listen for orientation changes
    window.addEventListener('orientationchange', () => {
      setTimeout(() => this.detectFromCSS(), 100);
    });

    // Apply to CSS variables
    this.applyCSSVariables();
  }

  detectFromCSS() {
    // Create a test element
    const testEl = document.createElement('div');
    testEl.style.cssText = `
      position: fixed;
      top: env(safe-area-inset-top, 0px);
      right: env(safe-area-inset-right, 0px);
      bottom: env(safe-area-inset-bottom, 0px);
      left: env(safe-area-inset-left, 0px);
      pointer-events: none;
      visibility: hidden;
    `;
    document.body.appendChild(testEl);

    const computed = getComputedStyle(testEl);

    this.insets = {
      top: parseFloat(computed.top) || 0,
      right: parseFloat(computed.right) || 0,
      bottom: parseFloat(computed.bottom) || 0,
      left: parseFloat(computed.left) || 0,
    };

    document.body.removeChild(testEl);
    this.applyCSSVariables();
  }

  applyCSSVariables() {
    const root = document.documentElement;
    root.style.setProperty('--safe-area-top', `${this.insets.top}px`);
    root.style.setProperty('--safe-area-right', `${this.insets.right}px`);
    root.style.setProperty('--safe-area-bottom', `${this.insets.bottom}px`);
    root.style.setProperty('--safe-area-left', `${this.insets.left}px`);

    // Also set has-notch class if top inset exists
    root.classList.toggle('has-notch', this.insets.top > 20);
    root.classList.toggle('has-home-indicator', this.insets.bottom > 20);
  }

  getInsets() {
    return { ...this.insets };
  }
}

const safeAreaManager = new SafeAreaManager();
export { safeAreaManager, SafeAreaManager };
```

### 13.4 React Hook for Safe Areas

```typescript
// hooks/useSafeArea.ts
import { useState, useEffect } from 'react';

interface SafeAreaInsets {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

export function useSafeArea(): SafeAreaInsets {
  const [insets, setInsets] = useState<SafeAreaInsets>({
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
  });

  useEffect(() => {
    const detect = () => {
      const testEl = document.createElement('div');
      testEl.style.cssText = `
        position: fixed;
        top: env(safe-area-inset-top, 0px);
        right: env(safe-area-inset-right, 0px);
        bottom: env(safe-area-inset-bottom, 0px);
        left: env(safe-area-inset-left, 0px);
        pointer-events: none;
        visibility: hidden;
      `;
      document.body.appendChild(testEl);

      const computed = getComputedStyle(testEl);

      setInsets({
        top: parseFloat(computed.top) || 0,
        right: parseFloat(computed.right) || 0,
        bottom: parseFloat(computed.bottom) || 0,
        left: parseFloat(computed.left) || 0,
      });

      document.body.removeChild(testEl);
    };

    detect();
    window.addEventListener('orientationchange', detect);
    return () => window.removeEventListener('orientationchange', detect);
  }, []);

  return insets;
}

// Usage
function Header() {
  const { top } = useSafeArea();

  return (
    <header
      className="fixed top-0 inset-x-0 z-50 bg-background"
      style={{ paddingTop: `calc(0.75rem + ${top}px)` }}
    >
      {/* Header content */}
    </header>
  );
}
```

---

## 14. TESTING CHECKLIST

### 14.1 Device Testing Matrix

| Device Type | Android Version | Chrome Version | Priority |
|-------------|-----------------|----------------|----------|
| Budget phone 2020 | Android 9 | Chrome 80-83 | High |
| Budget phone 2019 | Android 8 | Chrome 75-79 | High |
| Old tablet | Android 7 | Chrome 70-74 | Medium |
| WebView app | Android 8-9 | WebView 75-83 | High |
| Samsung mid-range | Android 9 | Samsung Browser 12-13 | Medium |

### 14.2 Chrome DevTools Emulation

```javascript
// Add to Chrome DevTools Console to simulate old Android
Object.defineProperty(navigator, 'userAgent', {
  get: function() {
    return 'Mozilla/5.0 (Linux; Android 8.1.0; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Mobile Safari/537.36';
  }
});

// Reload the page for changes to take effect
location.reload();
```

### 14.3 Testing Script

```javascript
/**
 * Old Android Compatibility Testing Script
 * Run in browser console to check for issues
 */

const CompatibilityChecker = {
  results: [],

  check(name, test, fix) {
    const result = { name, passed: false, fix };
    try {
      result.passed = test();
    } catch (e) {
      result.error = e.message;
    }
    this.results.push(result);
    return result;
  },

  run() {
    this.results = [];

    // 1. Check for gap usage
    this.check(
      'Flexbox gap fallback',
      () => {
        const elements = document.querySelectorAll('[class*="gap-"]');
        const hasGapFallback = CSS.supports('gap', '1rem') ||
          document.querySelector('.is-android-old') !== null;
        return elements.length === 0 || hasGapFallback;
      },
      'Add margin-based fallback for gap utilities'
    );

    // 2. Check for dvh/svh usage
    this.check(
      'Viewport units fallback',
      () => {
        const styles = Array.from(document.styleSheets)
          .flatMap(sheet => {
            try {
              return Array.from(sheet.cssRules);
            } catch {
              return [];
            }
          })
          .map(rule => rule.cssText || '');

        const hasDvh = styles.some(s => /\d+dvh|\d+svh|\d+lvh/.test(s));
        const hasVhVar = document.documentElement.style.getPropertyValue('--vh');

        return !hasDvh || hasVhVar;
      },
      'Add --vh CSS variable fallback'
    );

    // 3. Check for :has() usage
    this.check(
      'No :has() selector',
      () => {
        const styles = Array.from(document.styleSheets)
          .flatMap(sheet => {
            try {
              return Array.from(sheet.cssRules);
            } catch {
              return [];
            }
          })
          .map(rule => rule.cssText || '');

        return !styles.some(s => /:has\(/.test(s));
      },
      'Replace :has() with JS class toggles'
    );

    // 4. Check for icons in flex
    this.check(
      'Icons have shrink-0',
      () => {
        const icons = document.querySelectorAll('.flex svg, .inline-flex svg');
        return Array.from(icons).every(icon => {
          const style = getComputedStyle(icon);
          return style.flexShrink === '0';
        });
      },
      'Add shrink-0 class to icons in flex containers'
    );

    // 5. Check touch targets
    this.check(
      'Touch targets >= 44px',
      () => {
        const interactives = document.querySelectorAll('button, a, input, [role="button"]');
        return Array.from(interactives).every(el => {
          const rect = el.getBoundingClientRect();
          return rect.width >= 44 && rect.height >= 44;
        });
      },
      'Increase touch target size to minimum 44x44px'
    );

    // 6. Check for hover-only styles
    this.check(
      'No hover-only interactions',
      () => {
        // This is a heuristic check
        const buttons = document.querySelectorAll('button');
        return Array.from(buttons).every(btn => {
          const style = getComputedStyle(btn);
          // Check if there's an active state different from base
          return true; // Would need more sophisticated checking
        });
      },
      'Add :active styles alongside :hover'
    );

    // 7. Check text truncation
    this.check(
      'Truncated text has min-w-0',
      () => {
        const truncated = document.querySelectorAll('.truncate, [class*="line-clamp"]');
        return Array.from(truncated).every(el => {
          const parent = el.parentElement;
          if (!parent) return true;
          const parentStyle = getComputedStyle(parent);
          if (parentStyle.display !== 'flex') return true;
          const style = getComputedStyle(el);
          return style.minWidth === '0px';
        });
      },
      'Add min-w-0 to truncated text in flex containers'
    );

    // 8. Check minimum font size
    this.check(
      'Font sizes >= 12px',
      () => {
        const textElements = document.querySelectorAll('p, span, div, a, button, label');
        return Array.from(textElements).every(el => {
          const style = getComputedStyle(el);
          const fontSize = parseFloat(style.fontSize);
          return fontSize >= 12;
        });
      },
      'Increase font sizes to minimum 12px'
    );

    // Print results
    console.group('Old Android Compatibility Check');
    this.results.forEach(r => {
      const icon = r.passed ? 'PASS' : 'FAIL';
      console.log(`${icon} ${r.name}`);
      if (!r.passed && r.fix) {
        console.log(`   Fix: ${r.fix}`);
      }
      if (r.error) {
        console.log(`   Error: ${r.error}`);
      }
    });
    console.groupEnd();

    const passed = this.results.filter(r => r.passed).length;
    const total = this.results.length;
    console.log(`\nPassed: ${passed}/${total}`);

    return this.results;
  }
};

// Run the checker
CompatibilityChecker.run();
```

### 14.4 Real Device Testing Setup

```bash
# 1. Enable USB debugging on Android device
# Settings > Developer options > USB debugging

# 2. Connect device via USB

# 3. Open Chrome on desktop, navigate to:
# chrome://inspect/#devices

# 4. Click "Inspect" next to your device's browser tab

# 5. Use DevTools remotely to debug
```

### 14.5 BrowserStack/Sauce Labs Configuration

```json
{
  "capabilities": [
    {
      "browserName": "chrome",
      "browserVersion": "80.0",
      "platformName": "Android",
      "platformVersion": "9.0",
      "deviceName": "Samsung Galaxy S9"
    },
    {
      "browserName": "chrome",
      "browserVersion": "75.0",
      "platformName": "Android",
      "platformVersion": "8.0",
      "deviceName": "Google Pixel 2"
    },
    {
      "browserName": "samsung",
      "browserVersion": "12.0",
      "platformName": "Android",
      "platformVersion": "9.0",
      "deviceName": "Samsung Galaxy A50"
    }
  ]
}
```

### 14.6 Playwright Testing for Old Android

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  projects: [
    // Modern Chrome (baseline)
    {
      name: 'chrome',
      use: { ...devices['Pixel 5'] },
    },
    // Simulated old Android
    {
      name: 'old-android',
      use: {
        ...devices['Pixel 5'],
        userAgent: 'Mozilla/5.0 (Linux; Android 8.1.0; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Mobile Safari/537.36',
      },
    },
  ],
});

// test/old-android.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Old Android Compatibility', () => {
  test('page loads without errors', async ({ page }) => {
    await page.goto('/');

    // Check for JS errors
    const errors: string[] = [];
    page.on('pageerror', error => errors.push(error.message));

    await page.waitForLoadState('networkidle');
    expect(errors).toHaveLength(0);
  });

  test('touch targets are adequate size', async ({ page }) => {
    await page.goto('/');

    const buttons = await page.locator('button, a[href], [role="button"]').all();

    for (const button of buttons) {
      const box = await button.boundingBox();
      if (box) {
        expect(box.width).toBeGreaterThanOrEqual(44);
        expect(box.height).toBeGreaterThanOrEqual(44);
      }
    }
  });

  test('icons do not shrink in flex', async ({ page }) => {
    await page.goto('/');

    const icons = await page.locator('.flex svg, .inline-flex svg').all();

    for (const icon of icons) {
      const flexShrink = await icon.evaluate(
        el => getComputedStyle(el).flexShrink
      );
      expect(flexShrink).toBe('0');
    }
  });

  test('text is not too small', async ({ page }) => {
    await page.goto('/');

    const textElements = await page.locator('p, span, a, button, label').all();

    for (const el of textElements) {
      const fontSize = await el.evaluate(
        el => parseFloat(getComputedStyle(el).fontSize)
      );
      expect(fontSize).toBeGreaterThanOrEqual(12);
    }
  });
});
```

---

## 15. 300ms TAP DELAY REMOVAL (CRITICAL)

### The Problem

Old Android browsers (and iOS Safari) have a 300ms delay between tap and click events. This was originally designed to detect double-tap-to-zoom, but it makes apps feel sluggish.

### Solution: touch-action: manipulation

```css
/* Global fix - Apply to all interactive elements */
html {
  touch-action: manipulation;
}

/* Or target specific elements */
button,
a,
input,
select,
textarea,
[role="button"],
[role="link"],
[tabindex] {
  touch-action: manipulation;
}
```

### What touch-action: manipulation Does

| Behavior | Default | With manipulation |
|----------|---------|-------------------|
| Single tap | 300ms delay | Instant |
| Double tap to zoom | Enabled | Disabled |
| Pinch zoom | Enabled | Enabled |
| Pan/scroll | Enabled | Enabled |

### Tailwind CSS Plugin

```typescript
// tailwind.config.ts
import plugin from 'tailwindcss/plugin';

export default {
  plugins: [
    plugin(({ addBase }) => {
      addBase({
        // Remove 300ms tap delay globally
        'html': {
          'touch-action': 'manipulation',
        },
        // Ensure buttons respond instantly
        'button, [role="button"]': {
          'touch-action': 'manipulation',
        },
      });
    }),
  ],
};
```

### Complete Touch Optimization CSS

```css
/* Complete touch optimization for old Android */
html {
  /* Remove 300ms tap delay */
  touch-action: manipulation;

  /* Disable text selection during touch */
  -webkit-tap-highlight-color: transparent;
}

/* Prevent accidental zooming on inputs (iOS) */
input,
select,
textarea {
  font-size: 16px; /* Prevents iOS zoom */
  touch-action: manipulation;
}

/* Fast buttons */
button,
[role="button"],
a {
  touch-action: manipulation;
  -webkit-tap-highlight-color: transparent;
  cursor: pointer;
}

/* Scrollable areas - allow pan but keep other gestures */
.scrollable {
  touch-action: pan-y;
  -webkit-overflow-scrolling: touch;
}

/* Horizontal scroll */
.horizontal-scroll {
  touch-action: pan-x;
  -webkit-overflow-scrolling: touch;
}
```

### Testing Tap Delay

```typescript
// Measure tap delay in development
if (import.meta.env.DEV) {
  let touchStartTime = 0;

  document.addEventListener('touchstart', () => {
    touchStartTime = performance.now();
  }, { passive: true });

  document.addEventListener('click', () => {
    const delay = performance.now() - touchStartTime;
    if (delay > 100) {
      console.warn(`Tap delay detected: ${delay.toFixed(0)}ms`);
    }
  });
}
```

### Verification

| Check | Expected | Action if Failing |
|-------|----------|-------------------|
| Tap-to-click delay | < 100ms | Add touch-action: manipulation |
| Input focus delay | < 100ms | Ensure 16px font-size |
| Button response | Instant | Check tap-highlight disabled |

---

## 16. QUICK REFERENCE CARD

### 15.1 CSS Properties to Avoid

| Property | Chrome Support | Alternative |
|----------|----------------|-------------|
| `gap` (flexbox) | 84+ | Margin fallback |
| `dvh/svh/lvh` | 108+ | JS --vh variable |
| `:has()` | 105+ | JS class toggle |
| `aspect-ratio` | 88+ | Padding-top hack |
| `@container` | 105+ | Media queries |
| `clamp()` | 79+ | Media queries |
| `overscroll-behavior` | 63+ | JS prevention |
| `backdrop-filter` | 76+ | Solid background |

### 15.2 CSS Properties Safe to Use

| Property | Chrome Support | Notes |
|----------|----------------|-------|
| Flexbox | 21+ | Prefixed in very old |
| Grid | 57+ | Safe on Android 8+ |
| CSS Variables | 49+ | Safe on Android 7+ |
| `position: sticky` | 56+ | Safe on Android 8+ |
| `:focus-within` | 60+ | Safe on Android 8+ |
| `object-fit` | 32+ | Always safe |
| `transform` | 36+ | Always safe |

### 15.3 Quick Fix Patterns

```css
/* Flexbox gap */
.flex.gap-4 > * + * { margin-inline-start: 1rem; }

/* Viewport height */
height: 100vh;
height: var(--vh-full, 100vh);

/* Icons in flex */
.icon { flex-shrink: 0; }

/* Text truncation */
.truncate { min-width: 0; }

/* Safe area */
padding-bottom: calc(1rem + env(safe-area-inset-bottom, 0px));

/* Hover fallback */
@media (hover: hover) { .btn:hover { ... } }
```

---


## 17. SCROLLBAR VISIBILITY NORMALIZATION

### The Problem

Old Android browsers have inconsistent scrollbar rendering:
- Scrollbars may not appear at all
- Scrollbars may flash then disappear
- Scrollbar width varies between devices
- Touch scrolling areas are unpredictable

### CSS Normalization

```css
/* Normalize scrollbar appearance across Android devices */

/* Force scrollbar visibility */
.scroll-container {
  overflow-y: auto;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
  
  /* Thin scrollbar for modern browsers */
  scrollbar-width: thin;
  scrollbar-color: rgba(0, 0, 0, 0.3) transparent;
}

/* Webkit scrollbar styling (Chrome/Android) */
.scroll-container::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

.scroll-container::-webkit-scrollbar-track {
  background: transparent;
}

.scroll-container::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, 0.3);
  border-radius: 3px;
}

.scroll-container::-webkit-scrollbar-thumb:hover {
  background-color: rgba(0, 0, 0, 0.5);
}

/* Hide scrollbar but keep functionality */
.scroll-hidden {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scroll-hidden::-webkit-scrollbar {
  display: none;
}

/* Old Android: Force scrollbar always visible */
.is-android-old .scroll-always-visible {
  overflow-y: scroll !important;
}

.is-android-old .scroll-always-visible::-webkit-scrollbar {
  width: 8px;
  -webkit-appearance: scrollbar;
}
```

### JavaScript Detection

```typescript
// Detect scrollbar width for layout calculations
function getScrollbarWidth(): number {
  const outer = document.createElement('div');
  outer.style.cssText = 'visibility:hidden;overflow:scroll;width:100px';
  document.body.appendChild(outer);
  
  const inner = document.createElement('div');
  inner.style.width = '100%';
  outer.appendChild(inner);
  
  const scrollbarWidth = outer.offsetWidth - inner.offsetWidth;
  document.body.removeChild(outer);
  
  return scrollbarWidth;
}

// Apply scrollbar width CSS variable
document.documentElement.style.setProperty(
  '--scrollbar-width',
  `${getScrollbarWidth()}px`
);
```

---

## 18. SELECT/DROPDOWN STYLING

### The Problem

Native `<select>` elements render differently across Android versions and browsers:
- Default arrow styling varies
- Background colors may be ignored
- Font sizes may be forced
- Touch targets may be too small

### CSS Normalization

```css
/* Select element normalization */
select {
  /* Reset appearance */
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
  
  /* Base styling */
  display: block;
  width: 100%;
  min-height: 44px; /* Touch target */
  padding: 0.75rem 2.5rem 0.75rem 1rem;
  
  /* Font */
  font-size: 16px; /* Prevent iOS zoom */
  font-family: inherit;
  line-height: 1.5;
  
  /* Border & Background */
  background-color: var(--background, #fff);
  border: 1px solid var(--border, #e2e8f0);
  border-radius: 0.5rem;
  
  /* Custom arrow */
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  background-size: 1rem;
  
  /* RTL support */
  [dir="rtl"] & {
    padding: 0.75rem 1rem 0.75rem 2.5rem;
    background-position: left 0.75rem center;
  }
}

/* Remove default arrow in IE/Edge */
select::-ms-expand {
  display: none;
}

/* Focus state */
select:focus {
  outline: none;
  border-color: var(--primary, #3b82f6);
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

/* Disabled state */
select:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background-color: var(--muted, #f1f5f9);
}

/* Old Android fixes */
.is-android-old select {
  /* Force font size */
  font-size: 16px !important;
  
  /* Ensure padding works */
  padding-block: 12px;
}

/* Select wrapper for additional styling */
.select-wrapper {
  position: relative;
  display: inline-block;
  width: 100%;
}

.select-wrapper::after {
  content: '';
  position: absolute;
  inset-inline-end: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
  
  /* Custom arrow icon */
  width: 1rem;
  height: 1rem;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: center;
}
```

### Multi-select Styling

```css
/* Multi-select (shows multiple options) */
select[multiple] {
  height: auto;
  min-height: 100px;
  padding: 0.5rem;
  background-image: none;
}

select[multiple] option {
  padding: 0.5rem;
  margin: 0.125rem 0;
  border-radius: 0.25rem;
}

select[multiple] option:checked {
  background: var(--primary, #3b82f6);
  color: white;
}
```

---

## 19. FONT RENDERING FIXES (ANTIALIASING)

### The Problem

Old Android browsers may have:
- Pixelated text rendering
- Inconsistent font weights
- Subpixel rendering issues
- Blurry text at certain sizes

### CSS Antialiasing Fixes

```css
/* Global font rendering optimization */
html {
  /* Smooth font rendering */
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  
  /* Prevent text size adjustment */
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
}

body {
  /* Optimize text rendering */
  text-rendering: optimizeLegibility;
  
  /* Enable font features */
  font-feature-settings: "kern" 1, "liga" 1;
}

/* Specific fixes for old Android */
.is-android-old {
  /* Force antialiasing */
  -webkit-font-smoothing: antialiased;
  
  /* Simpler text rendering (better on old GPUs) */
  text-rendering: optimizeSpeed;
  
  /* Disable subpixel positioning (can cause blur) */
  font-smooth: always;
}

/* Fix for thin fonts appearing too light */
.is-android-old .font-light,
.is-android-old [class*="font-"][class*="light"] {
  font-weight: 400; /* Bump up light to regular */
}

/* Fix for very thin text */
.is-android .thin-text {
  -webkit-text-stroke: 0.2px;
}

/* Prevent font scaling issues */
.no-scale {
  font-size: 16px !important;
  -webkit-text-size-adjust: none;
}

/* Heading optimization */
h1, h2, h3, h4, h5, h6 {
  text-rendering: optimizeLegibility;
  font-feature-settings: "kern" 1;
}

/* Numbers - tabular for alignment */
.tabular-nums {
  font-variant-numeric: tabular-nums;
  font-feature-settings: "tnum" 1;
}

/* Fix text blur on transform */
.gpu-text {
  transform: translateZ(0);
  backface-visibility: hidden;
}
```

### Font Loading Optimization

```css
/* Font-face with optimal loading */
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2'),
       url('/fonts/custom.woff') format('woff');
  font-weight: 400;
  font-style: normal;
  font-display: swap; /* Show fallback immediately */
}

/* System font stack as fallback */
:root {
  --font-system: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    "Helvetica Neue", Arial, sans-serif;
  --font-mono: ui-monospace, "SF Mono", Menlo, Monaco, "Cascadia Code",
    "Source Code Pro", monospace;
}

/* Hebrew-optimized stack */
:root[lang="he"],
[dir="rtl"] {
  --font-system: "Segoe UI", Roboto, "Noto Sans Hebrew", 
    "Helvetica Neue", Arial, sans-serif;
}
```

### JavaScript Font Loading

```typescript
// Detect when fonts are loaded
document.fonts.ready.then(() => {
  document.documentElement.classList.add('fonts-loaded');
});

// FOUT prevention class
// Add .fonts-loading to html initially
// Remove when fonts loaded
if (document.fonts) {
  document.documentElement.classList.add('fonts-loading');
  
  document.fonts.ready.then(() => {
    document.documentElement.classList.remove('fonts-loading');
    document.documentElement.classList.add('fonts-loaded');
  });
}
```

```css
/* Hide text until fonts load (optional, prevents FOUT) */
.fonts-loading body {
  opacity: 0;
}

.fonts-loaded body {
  opacity: 1;
  transition: opacity 0.1s ease-out;
}

/* Alternative: show system font immediately */
.fonts-loading {
  font-family: var(--font-system);
}

.fonts-loaded {
  font-family: 'CustomFont', var(--font-system);
}
```

### Verification Checklist

- [ ] `-webkit-font-smoothing: antialiased` applied globally
- [ ] `text-rendering` set appropriately
- [ ] Font weights not too thin on Android (min 400)
- [ ] No text blur from transforms
- [ ] Font loading handled gracefully
- [ ] System font fallbacks defined
- [ ] RTL fonts specified for Hebrew/Arabic

---

## 20. RELATED SKILLS

- `/skill rtl-patterns` - RTL-first development
- `/skill responsive-reference` - Mobile-first responsive design
- `/skill testing-patterns` - Cross-browser testing strategies
- `/skill performance-reference` - Performance optimization

---

## 21. VERIFICATION SEAL

```
OMEGA_v24.5.0 | OLD_ANDROID_CSS_COMPAT
Gates: 8 | Commands: 4 | Phase: 2.4.1
CHROME_84_COMPAT | FLEXBOX_GAP | VIEWPORT_UNITS | 300MS_TAP_DELAY
```

<!-- PWA-EXPERT/OLD-ANDROID-CSS v24.5.0 | Updated: 2026-02-19 -->

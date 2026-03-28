# CSS Performance - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/CSS
> Consolidates: css-containment, content-visibility, render-blocking, scroll-animations

---

## 1. CSS CONTAINMENT

### The `contain` Property

CSS containment allows the browser to isolate parts of the page, limiting the scope of style recalculations, layout, and paint operations.

| Value | Effect | Use Case |
|-------|--------|----------|
| `layout` | Isolates layout | Cards, list items |
| `paint` | Isolates paint | Elements with overflow |
| `size` | Element doesn't depend on children for size | Known-size containers |
| `style` | Isolates counter/quotes | Numbered sections |
| `content` | `layout paint style` combined | Most common usage |
| `strict` | `layout paint size style` | Fixed-size containers |

### Usage Examples

```css
/* Card grid -- each card's layout is independent */
.card {
  contain: content;
}

/* Known-size widget */
.widget {
  contain: strict;
  width: 300px;
  height: 200px;
}

/* List items -- isolate each for performance */
.list-item {
  contain: layout paint;
}
```

### Tailwind Integration

```tsx
// Custom utility for CSS containment
<div className="[contain:content]">
  <ExpensiveComponent />
</div>

// Or add to Tailwind config
// In CSS (Tailwind 4.2):
@utility contain-content {
  contain: content;
}
@utility contain-strict {
  contain: strict;
}
@utility contain-layout {
  contain: layout;
}
@utility contain-paint {
  contain: paint;
}
```

---

## 2. CONTENT-VISIBILITY

### content-visibility: auto

The most impactful CSS performance property. Tells the browser to skip rendering of off-screen content.

```css
/* Skip rendering of off-screen sections */
.section {
  content-visibility: auto;
  contain-intrinsic-size: 0 500px; /* Estimated height */
}

/* Results: Up to 87% rendering time improvement on long pages */
```

### Performance Impact

```
Page with 20 sections, 5 visible:
├── Without content-visibility: Render ALL 20 sections
│   └── Render time: ~800ms
├── With content-visibility: auto: Render only 5 visible
│   └── Render time: ~100ms (87% faster)
└── Savings: 700ms on initial render
```

### Implementation Patterns

```tsx
// Component with content-visibility
function LazySection({ children, estimatedHeight = 500 }: {
  children: React.ReactNode;
  estimatedHeight?: number;
}) {
  return (
    <section
      style={{
        contentVisibility: 'auto',
        containIntrinsicSize: `0 ${estimatedHeight}px`,
      }}
    >
      {children}
    </section>
  );
}

// Usage
export default function LongPage() {
  return (
    <div>
      {/* Above fold -- no content-visibility */}
      <HeroSection />

      {/* Below fold -- skip rendering when off-screen */}
      <LazySection estimatedHeight={600}>
        <FeaturesSection />
      </LazySection>

      <LazySection estimatedHeight={400}>
        <TestimonialsSection />
      </LazySection>

      <LazySection estimatedHeight={300}>
        <FAQSection />
      </LazySection>

      <LazySection estimatedHeight={200}>
        <FooterSection />
      </LazySection>
    </div>
  );
}
```

### contain-intrinsic-size Strategies

```css
/* Fixed estimate */
.section {
  content-visibility: auto;
  contain-intrinsic-size: 0 500px;
}

/* Auto with last-known size (remembers after first render) */
.section {
  content-visibility: auto;
  contain-intrinsic-size: auto 500px;
}

/* Width and height estimates */
.card {
  content-visibility: auto;
  contain-intrinsic-size: 300px 200px;
}
```

---

## 3. RENDER-BLOCKING RESOURCES

### Identifying Render-Blocking Resources

```
Critical Rendering Path:
HTML → [CSS (render-blocking)] → [JS (parser-blocking)] → First Paint

Render-blocking resources delay first paint:
├── Synchronous CSS in <head>
├── Synchronous <script> in <head>
├── @import in CSS files
└── @font-face without font-display
```

### Elimination Strategies

```html
<!-- 1. Defer non-critical CSS -->
<link rel="stylesheet" href="/critical.css" />
<link rel="stylesheet" href="/non-critical.css" media="print" onload="this.media='all'" />

<!-- 2. Async scripts -->
<script src="/analytics.js" async></script>
<script src="/non-critical.js" defer></script>

<!-- 3. Inline critical CSS -->
<style>
  /* Critical above-the-fold styles inlined */
  .hero { ... }
  .nav { ... }
</style>

<!-- 4. Preload critical resources -->
<link rel="preload" as="style" href="/critical.css" />
<link rel="preload" as="font" href="/font.woff2" type="font/woff2" crossorigin />
```

### Next.js Critical CSS

```typescript
// next.config.ts
module.exports = {
  experimental: {
    optimizeCss: true, // Extract and inline critical CSS
  },
};
```

### Font Display Impact

```css
/* BLOCKING: Invisible text for up to 3 seconds */
@font-face {
  font-family: 'Heebo';
  font-display: block; /* BAD for performance */
}

/* NON-BLOCKING: Shows fallback font immediately */
@font-face {
  font-family: 'Heebo';
  font-display: swap; /* GOOD: immediate text visibility */
}

/* OPTIMAL: Shows fallback, may skip web font if slow */
@font-face {
  font-family: 'Heebo';
  font-display: optional; /* BEST for non-critical fonts */
}
```

---

## 4. SCROLL-DRIVEN ANIMATIONS

### CSS Scroll-Driven Animations (Chrome 115+)

```css
/* Scroll-linked animation (no JavaScript needed) */
@keyframes fade-in {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.reveal-on-scroll {
  animation: fade-in linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}

/* Progress bar linked to page scroll */
.scroll-progress {
  position: fixed;
  top: 0;
  inset-inline-start: 0;
  width: 100%;
  height: 4px;
  background: var(--primary);
  transform-origin: 0 0;
  animation: scale-x linear both;
  animation-timeline: scroll();
}

@keyframes scale-x {
  from { transform: scaleX(0); }
  to { transform: scaleX(1); }
}
```

### Performance Benefits vs JS Scroll

```
JavaScript scroll handlers:
├── Runs on main thread
├── Can cause jank (>16ms = dropped frame)
├── Requires throttle/debounce
└── requestAnimationFrame needed

CSS scroll-driven animations:
├── Runs on compositor thread
├── Cannot jank main thread
├── No throttle needed
└── GPU-accelerated automatically
```

### Intersection Observer Alternative

```typescript
// For browsers without scroll-driven animations
// Use IntersectionObserver + CSS classes
function useScrollReveal() {
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('revealed');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.1 },
    );

    document.querySelectorAll('.scroll-reveal').forEach((el) => {
      observer.observe(el);
    });

    return () => observer.disconnect();
  }, []);
}
```

---

## 5. CSS ANIMATION PERFORMANCE

### Transform & Opacity Only

```css
/* GOOD: Only composite properties (GPU-accelerated) */
.animate-good {
  transition: transform 300ms ease, opacity 300ms ease;
}

/* BAD: Layout-triggering properties */
.animate-bad {
  transition: width 300ms, height 300ms, top 300ms, left 300ms;
  /* Triggers layout recalculation every frame */
}

/* GOOD: Use transform instead of position */
.slide-in {
  transform: translateX(0);
  transition: transform 300ms ease;
}
.slide-in.hidden {
  transform: translateX(100%);
}

/* GOOD: will-change for known animations */
.will-animate {
  will-change: transform, opacity;
}
/* Remove will-change after animation completes */
```

### Animation Performance Tiers

| Tier | Properties | Cost | GPU |
|------|-----------|------|-----|
| Composite | transform, opacity | Cheapest | Yes |
| Paint | color, background, box-shadow | Medium | No |
| Layout | width, height, top, left, margin, padding | Expensive | No |

---

## 6. CSS PERFORMANCE PATTERNS

### Efficient Selectors

```css
/* GOOD: Low specificity, fast matching */
.card-title { ... }
.nav-link { ... }

/* BAD: Deep nesting, slow matching */
body > main > section > article > div > h2 { ... }

/* BAD: Universal selector in complex context */
.container * { ... }

/* GOOD: Direct child selector when needed */
.container > .item { ... }
```

### Avoid Expensive Properties in Large Lists

```css
/* BAD: Expensive on 1000 list items */
.list-item {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  filter: blur(0);
  backdrop-filter: blur(10px);
}

/* GOOD: Simpler styling for list items */
.list-item {
  border-bottom: 1px solid var(--border);
}

/* Apply expensive styles only on hover */
.list-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}
```

### CSS Layers for Performance

```css
/* CSS layers help browser optimize cascade resolution */
@layer base, components, utilities;

@layer base {
  /* Reset and base styles */
}

@layer components {
  /* Component styles */
}

@layer utilities {
  /* Utility overrides */
}
```

---

## 7. MEASUREMENT

### Measuring CSS Performance

```typescript
// Measure style recalculation time
interface LoAFScriptTiming {
  forcedStyleAndLayoutDuration: number;
  sourceURL: string;
}

interface LoAFEntry extends PerformanceEntry {
  scripts: LoAFScriptTiming[];
}

function measureStyleRecalc(): void {
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries() as LoAFEntry[]) {
      if (entry.scripts) {
        for (const script of entry.scripts) {
          if (script.forcedStyleAndLayoutDuration > 10) {
            console.warn('Expensive style recalc:', {
              forcedDuration: `${script.forcedStyleAndLayoutDuration.toFixed(0)}ms`,
              source: script.sourceURL,
            });
          }
        }
      }
    }
  });

  observer.observe({ type: 'long-animation-frame', buffered: true });
}

// Chrome DevTools:
// Performance tab -> Enable "Rendering" -> Check:
// - Paint flashing (green = repaint)
// - Layout shift regions (blue = layout)
// - Layer borders (orange = composited layers)
```

---

## 8. CHECKLIST

```markdown
## CSS Performance Checklist

### Containment
- [ ] contain: content on independent components (cards, list items)
- [ ] content-visibility: auto on off-screen sections
- [ ] contain-intrinsic-size set with auto keyword
- [ ] contain: strict on fixed-size containers

### Render-Blocking
- [ ] Critical CSS inlined or preloaded
- [ ] Non-critical CSS deferred (media="print" trick)
- [ ] No @import in CSS (use <link> instead)
- [ ] font-display: swap on all fonts
- [ ] optimizeCss enabled in Next.js

### Animations
- [ ] Only transform/opacity in transitions
- [ ] will-change only on actively animating elements
- [ ] Scroll-driven animations for scroll-linked effects
- [ ] prefers-reduced-motion respected
- [ ] RTL-aware animation direction

### Selectors & Properties
- [ ] Flat selectors (low specificity)
- [ ] No universal selectors in complex contexts
- [ ] Expensive properties (shadow, blur) minimized
- [ ] CSS layers for cascade optimization
```

---

<!-- CSS_PERFORMANCE v24.7.0 | Containment, content-visibility, render-blocking, scroll animations -->

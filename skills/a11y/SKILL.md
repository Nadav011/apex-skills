---
name: a11y
description: "Use when user wants to run accessibility audits for WCAG AAA compliance, ARIA patterns, cognitive accessibility, motion/contrast sensitivity, and inclusive design"
---
# Accessibility Skill — /a11y

> **v24.6.0** | WCAG 2.2 AAA | WAI-ARIA 1.2/1.3 | Web + Flutter + PWA
> References: 13 files in `references/` — see References section below

---

## WCAG 2.2 Key Criteria

| SC | Name | Level | Implementation |
|----|------|-------|----------------|
| 1.4.11 | Non-text Contrast | AA | UI components + focus indicators 3:1 against adjacent |
| 1.4.12 | Text Spacing | AA | CSS custom props for line-height/letter-spacing/word-spacing override |
| 1.4.13 | Content on Hover/Focus | AA | Dismissible (Esc), hoverable, persistent until dismissed/invalid |
| 2.2.1 | Timing Adjustable | A | Warn before timeout, allow extend, 20hr exception |
| 2.4.11 | Focus Not Obscured Min | AA | Focused item not entirely hidden by author-created content |
| 2.4.12 | Focus Not Obscured Enh | AAA | Focused item fully visible (no partial occlusion) |
| 2.4.13 | Focus Appearance | AAA | 2px outline, 3:1 contrast, encloses area >= 1px border of unfocused |
| 2.5.5 | Target Size Enhanced | AAA | 44x44 CSS px minimum |
| 2.5.7 | Dragging Movements | AA | Single-pointer alternative for every drag operation |
| 2.5.8 | Target Size Minimum | AA | 24x24 CSS px minimum (spacing exception) |
| 3.1.5 | Reading Level | AAA | Lower secondary education reading level or supplemental version |
| 3.2.3 | Consistent Navigation | AA | Nav components in same relative order across pages |
| 3.2.6 | Consistent Help | A | Help mechanisms in same relative order across pages |
| 3.3.4 | Error Prevention | AA | Reversible, checked, or confirmed for legal/financial/data |
| 3.3.7 | Redundant Entry | A | Auto-populate previously entered info (same session) |
| 3.3.8 | Accessible Auth Min | AA | No cognitive function test; allow copy-paste, password managers |
| 3.3.9 | Accessible Auth Enh | AAA | No cognitive function test at all (no object/image recognition) |

---

## prefers-* Media Queries

| Query | Values | Support | Implementation |
|-------|--------|---------|----------------|
| `prefers-reduced-motion` | `reduce`, `no-preference` | Full (~97%) | CSS: `@media`, TW: `motion-reduce:`, JS: `matchMedia()`, Framer: `useReducedMotion()` |
| `prefers-contrast` | `more`, `less`, `custom`, `no-preference` | Full (since May 2022) | TW: `contrast-more:`, increase borders, remove transparency |
| `prefers-color-scheme` | `dark`, `light` | Full (~97%) | TW: `dark:`, CSS: `@media`, meta: `color-scheme` |
| `prefers-reduced-data` | `reduce`, `no-preference` | Chrome ~75% | Adaptive loading: skip hero video, compress images, defer non-critical |
| `prefers-reduced-transparency` | `reduce`, `no-preference` | ~71% (needs fallback) | Replace `backdrop-blur`, `opacity` overlays with solid backgrounds |
| `forced-colors: active` | — | All (Win High Contrast) | System keywords: `ButtonText`, `Canvas`, `CanvasText`, `LinkText`, `Field`, `FieldText`, `Mark`, `MarkText`, `SelectedItem`, `SelectedItemText` |
| `inverted-colors` | `inverted`, `none` | Safari only (being standardized) | Avoid double-inversion on images, check shadows |

### Reduced Motion — Mandatory Pattern

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```typescript
// View Transitions — MUST guard
if (!matchMedia('(prefers-reduced-motion: reduce)').matches) {
  document.startViewTransition(() => updateDOM());
}
```

---

## Modern HTML/API Accessibility

### HTML `inert` Attribute
Modern focus trap replacement. Elements with `inert` are removed from tab order + AT tree.
```html
<main inert={isDialogOpen}>...</main>
<dialog open>...</dialog>
```

### Native `<dialog>`
- `showModal()`: auto-inerts background, auto-focuses first focusable, traps focus, closes on Esc
- Place close button below heading for SR reading order
- No `aria-modal` needed with `showModal()` (browser handles it)
- TalkBack Android 12 bug: virtual cursor escapes `<dialog>` — test on Android 13+
- `scrollbar-gutter: stable` on `<body>` to prevent layout shift when dialog opens

### Popover API

| Built-in (free) | Developer responsibility |
|-----------------|------------------------|
| Light dismiss (click outside) | `role` attribute (e.g., `role="menu"`) |
| Top layer rendering | `aria-label` or `aria-labelledby` |
| Auto `id` association | Keyboard navigation inside popover |
| Esc to close | Focus trap if needed |
| — | Focus return on close |

### View Transitions API
- MUST wrap in `prefers-reduced-motion` guard
- Duration <400ms for accessibility
- Support: >85% browsers
- `::view-transition-*` pseudo-elements need reduced-motion override
- Cross-document: `@view-transition { navigation: auto; }` — same motion rules apply
- Focus management after DOM update — verify focus target still exists

### React 19 Suspense + `use()`
```tsx
{/* aria-live OUTSIDE Suspense boundary — persistent in DOM */}
<div aria-live="polite" aria-atomic="true" id="status-region">
  {statusText}
</div>
<Suspense fallback={<Skeleton aria-busy="true" aria-label="Loading content" />}>
  <AsyncComponent />
</Suspense>
```
- Mutate text content, not replace nodes (SR misses node replacement)
- `polite` for loading, `assertive` only for critical failures
- Manage focus after async resolution — focus first meaningful element

### Next.js 16 Route Announcer
Announces page changes to screen readers. Reads: `<title>` > `<h1>` > `pathname`.
Ensure every page has a meaningful `<title>` and `<h1>`.

---

## Standards & Compliance

### WAI-ARIA 1.2 (Stable) + 1.3 (Working Draft)

**ARIA 1.3 new features:**
- `suggestion` role — marks proposed changes
- `comment` role — marks annotations
- `mark` role — highlighted content
- `aria-description` — longer description (beyond `aria-label`)
- `aria-braillelabel` / `aria-brailleroledescription` — braille display overrides

**Rule:** Use native HTML first. ARIA only when no native equivalent exists.

### WCAG 3.0 (Feb 19 2026 Editor's Draft)
- Bronze / Silver / Gold conformance (replaces A/AA/AAA)
- 0-4 scoring scale per outcome
- Estimated stable: ~late 2029
- **Not for production compliance yet — continue targeting WCAG 2.2 AAA**

### APCA Contrast
- Advanced Perceptual Contrast Algorithm by Myndex
- Supplementary use only — NOT referenced in WCAG 3.0 draft
- Better for dark mode and colored backgrounds than WCAG 2.x formula
- Use alongside WCAG 2.2 contrast ratios, not as replacement

### European Accessibility Act (EAA)
- **In force since June 28, 2025**
- Applies to: e-commerce, banking, transport, e-books, telecom
- Penalties: up to 100,000 EUR or 4% of annual revenue
- Aligns with EN 301 549 (maps to WCAG 2.1 AA minimum)

### COGA (Cognitive Accessibility)
Principles: clear language, consistent UI, error prevention, minimal memory load, predictable behavior.
Mapped WCAG criteria: 2.2.1 (timing), 3.1.5 (reading level), 3.2.3 (consistent nav), 3.3.4 (error prevention), 3.3.7 (redundant entry).

---

## Touch Targets

| Platform | Minimum | Recommended | Tailwind |
|----------|---------|-------------|----------|
| Web (WCAG 2.5.8 AA) | 24x24px | 44x44px (2.5.5 AAA) | `min-h-11 min-w-11` |
| Flutter (Material 3) | 48dp | 48dp | `ConstrainedBox(minWidth: 48, minHeight: 48)` |
| iOS (HIG) | 44pt | 44pt | — |
| Android (Material) | 48dp | 48dp | — |

---

## Dynamic Type / Font Scaling

| Platform | Unit | API | Max Scale |
|----------|------|-----|-----------|
| Web | `rem` | `font-size: 100%` on html | Browser zoom (no cap) |
| iOS | pt (Dynamic Type) | `UIFontMetrics` | XXXL (~3.1x) |
| Android | sp | `Configuration.fontScale` | ~2.0x typical |
| Flutter | logical px | `MediaQuery.textScalerOf(context)` | Device-dependent |

**Web:** Use `rem` for font sizes, container queries for zoom-safe layout.
**Flutter:** `MediaQuery.textScalerOf(context)` (NOT deprecated `textScaleFactorOf`).

---

## Screen Readers

| Reader | Platform | Engine | Activation |
|--------|----------|--------|-----------|
| VoiceOver | iOS, macOS | Native | Settings > Accessibility > VoiceOver |
| TalkBack | Android | Native | Settings > Accessibility > TalkBack |
| NVDA | Windows | Open source | Download from nvaccess.org |
| JAWS | Windows | Commercial | Freedom Scientific license |
| ChromeVox | ChromeOS | Extension | Settings > Accessibility |
| Orca | Linux/GNOME | Open source | `orca` command |

---

## 2026 Trends

1. **Shift-left accessibility** — a11y in design systems + component libraries, not end-of-sprint audit
2. **Native HTML revival** — `<dialog>`, Popover API, `inert` replacing JS solutions
3. **User preference systems** — `prefers-*` media queries driving adaptive UX
4. **AI augments, not replaces** — AI generates alt text drafts, humans review; AI finds issues, humans validate
5. **Legal enforcement** — EAA active, DOJ Title II (US), increased litigation
6. **ARIA 1.3 adoption** — `suggestion`, `comment`, `aria-description` entering production

---

## Cross-Skill Links

| Need | Skill | Command |
|------|-------|---------|
| Verification gates A1-A15 | verify-app | `/verify-app a11y` |
| Flutter semantics + focus | flutter-rules | `/flutter-rules` |
| PWA offline + push a11y | pwa-expert | `/pwa-expert` |
| axe-core + Playwright testing | testing-rules | `/testing-rules` |
| RTL + i18n patterns | Built-in rules | `rules/quality/rtl-i18n.md` |

---

## References

| File | Content |
|------|---------|
| `references/web-a11y.md` | Core web accessibility patterns, ARIA, keyboard, forms, RTL |
| `references/mobile-a11y.md` | Mobile accessibility — iOS VoiceOver, Android TalkBack, touch targets |
| `references/flutter-a11y.md` | Flutter Semantics, focus traversal, screen reader testing |
| `references/pwa-a11y.md` | PWA accessibility — install prompts, offline, push notifications |
| `references/a11y-testing.md` | axe-core + Playwright testing patterns, automated audits |
| `references/wcag3-apca.md` | WCAG 3.0 readiness, Bronze/Silver/Gold model, APCA contrast |
| `references/cognitive-a11y.md` | Cognitive accessibility (COGA) patterns, progressive disclosure |
| `references/motion-contrast-modes.md` | Reduced motion, forced-colors, prefers-contrast, dark mode a11y |
| `references/dialog-popover-a11y.md` | `<dialog>` + Popover API accessibility, browser bugs, patterns |
| `references/async-content-a11y.md` | React 19 Suspense, infinite scroll, real-time data, toasts |
| `references/view-transitions-a11y.md` | View Transitions API with mandatory motion guards |
| `references/nextjs-a11y.md` | Next.js 16 route announcer, skip links, server components |
| `references/container-responsive-a11y.md` | Container queries, zoom-safe typography, responsive touch targets |

---

<!-- A11Y_SKILL v24.6.0 | Updated: 2026-02-24 | WCAG 2.2 AAA + ARIA 1.2/1.3 + EAA + COGA + WCAG 3.0 readiness + 13 reference files -->

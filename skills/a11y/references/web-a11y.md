# Web Accessibility Reference

> **v24.6.0** | WCAG 2.2 AAA | WAI-ARIA 1.2/1.3 | Modern HTML APIs
> RTL-FIRST: `inset-s-*`/`inset-e-*` for positioning (TW 4.2; `start-*`/`end-*` deprecated for inset)

---

## APG Component Patterns

### Dialog (Modal)

```html
<dialog id="confirm-dialog">
  <h2 id="dialog-title">Confirm</h2>
  <button autofocus>Close</button>
</dialog>
```

- `showModal()`: auto-inerts background, traps focus, Esc closes
- No `aria-modal` or `role="dialog"` needed with `showModal()`
- Close button below heading — SR reads heading first
- `autofocus` on close button (Chrome macOS bug: may skip without it)
- Focus returns to trigger element on `close()` automatically
- TalkBack Android 12: virtual cursor escapes — test on 13+
- `scrollbar-gutter: stable` on `<body>` prevents layout shift

### Tabs

```html
<div role="tablist" aria-label="Settings">
  <button role="tab" aria-selected="true" aria-controls="panel-1" id="tab-1">General</button>
  <button role="tab" aria-selected="false" aria-controls="panel-2" id="tab-2" tabindex="-1">Advanced</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">...</div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" hidden>...</div>
```

- Arrow keys navigate tabs, Tab moves to panel
- `aria-orientation="vertical"` for vertical tabs (Up/Down instead)
- Active tab: `tabindex="0"`, inactive: `tabindex="-1"`
- RTL: Arrow keys auto-reverse with `dir="rtl"`

### Toast / Status

```html
<div role="status" aria-live="polite" aria-atomic="true" class="fixed inset-e-4 bottom-4">
  {message}
</div>
```

- `role="status"` implies `aria-live="polite"` — but be explicit for older SR
- Use `aria-atomic="true"` so entire region is re-read
- Position with `inset-e-*` (not `right-*`) for RTL
- Auto-dismiss: include visible timer, minimum 5s for reading

### Combobox (Autocomplete)

```html
<label for="city-input">City</label>
<input id="city-input" role="combobox" aria-expanded="false"
  aria-autocomplete="list" aria-controls="city-listbox" aria-activedescendant="">
<ul id="city-listbox" role="listbox" hidden>
  <li role="option" id="opt-1">Tel Aviv</li>
</ul>
```

- `aria-expanded`: toggles with listbox visibility
- `aria-activedescendant`: points to highlighted option id
- Enter selects, Escape closes, Arrow keys navigate options
- Type-ahead: filter as user types

### Live Regions

| Politeness | Use Case | Behavior |
|-----------|----------|----------|
| `polite` | Status, toast, loading complete | Waits for SR to finish current speech |
| `assertive` | Critical errors, urgent alerts | Interrupts current speech |
| `off` | Disable announcements | No announcement |

- `aria-atomic="true"`: re-reads entire region on change
- `aria-relevant="additions text"`: only announces new content + text changes
- RTL: add `dir="auto"` on live regions for mixed content

### Landmarks

```html
<header><!-- role="banner" implied --></header>
<nav aria-label="Main"><!-- role="navigation" --></nav>
<main><!-- role="main" --></main>
<aside><!-- role="complementary" --></aside>
<footer><!-- role="contentinfo" implied --></footer>
```

- Multiple `<nav>`: differentiate with `aria-label`
- `<main>`: exactly one per page
- Nested landmarks need labels

### Skip Links

```tsx
<a href="#main-content"
  className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:inset-s-4 focus:z-50 focus:bg-background focus:px-4 focus:py-2 focus:rounded-md">
  Skip to main content
</a>
<main id="main-content" tabIndex={-1}>{children}</main>
```

### Accordion / Disclosure

```html
<h3>
  <button aria-expanded="false" aria-controls="section-1">Section Title</button>
</h3>
<div id="section-1" role="region" aria-labelledby="heading-1" hidden>Content</div>
```

- Native `<details>`/`<summary>` is simpler when styling allows
- `aria-expanded` on trigger, not panel
- Enter/Space toggles

### Alert / Alert Dialog

```html
<!-- Alert (informational) -->
<div role="alert">Form submitted successfully.</div>

<!-- Alert Dialog (requires action) -->
<dialog role="alertdialog" aria-labelledby="alert-title" aria-describedby="alert-desc">
  <h2 id="alert-title">Delete item?</h2>
  <p id="alert-desc">This cannot be undone.</p>
  <button autofocus>Cancel</button>
  <button>Delete</button>
</dialog>
```

- `role="alert"` implies `aria-live="assertive"` — immediate announcement
- Alert dialog: focus trap + requires user action

### Breadcrumb

```html
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li aria-current="page">Products</li>
  </ol>
</nav>
```

- `aria-current="page"` on current item
- Separators via CSS `::before` (not in DOM) to avoid SR reading them
- RTL: separators auto-reverse with CSS logical properties

### Feed (Infinite Scroll)

```html
<div role="feed" aria-label="News articles" aria-busy="false">
  <article aria-posinset="1" aria-setsize="-1" tabindex="0">...</article>
  <article aria-posinset="2" aria-setsize="-1" tabindex="0">...</article>
</div>
```

- `aria-setsize="-1"`: total unknown (infinite)
- Set `aria-busy="true"` while loading more
- Each article focusable with `tabindex="0"`
- Announce "Loading more items" via live region

### Listbox

```html
<label id="color-label">Color</label>
<ul role="listbox" aria-labelledby="color-label" tabindex="0">
  <li role="option" aria-selected="true">Red</li>
  <li role="option" aria-selected="false">Blue</li>
</ul>
```

- Single select: `aria-selected` on one option
- Multi select: add `aria-multiselectable="true"`
- Arrow keys navigate, Space/Enter selects

### Menu / Menubar / Menu Button

```html
<button aria-haspopup="true" aria-expanded="false" aria-controls="actions-menu">Actions</button>
<ul role="menu" id="actions-menu" hidden>
  <li role="menuitem">Edit</li>
  <li role="menuitem">Delete</li>
  <li role="separator"></li>
  <li role="menuitemcheckbox" aria-checked="false">Archive</li>
</ul>
```

- Arrow keys navigate items, Enter/Space activates
- Escape closes menu, returns focus to trigger
- Type-ahead: first letter focuses matching item

### Switch / Toggle

```html
<button role="switch" aria-checked="false" aria-label="Dark mode">
  <span aria-hidden="true">Off</span>
</button>
```

- `aria-checked` toggles `"true"`/`"false"`
- Space/Enter toggles (not just click)
- Visually indicate state beyond color alone

### Tooltip

```html
<button aria-describedby="tip-1">Info
  <div role="tooltip" id="tip-1" popover>Additional details here</div>
</button>
```

- WCAG 1.4.13: tooltip must be hoverable, dismissible (Esc), persistent
- Do not put interactive content in tooltips
- Show on focus AND hover (not just hover)
- Minimum visible: 1.5s after trigger

### Carousel

```html
<section aria-roledescription="carousel" aria-label="Featured products">
  <div aria-live="off"><!-- off during auto-play, polite during manual -->
    <div role="group" aria-roledescription="slide" aria-label="1 of 5">...</div>
  </div>
  <button aria-label="Previous slide">...</button>
  <button aria-label="Next slide">...</button>
  <button aria-label="Pause auto-play">...</button>
</section>
```

- Pause/play control mandatory for auto-advancing
- `aria-live="off"` during auto-play, `"polite"` during manual nav
- prefers-reduced-motion: disable auto-advance

### Radio Group

```html
<fieldset>
  <legend>Payment method</legend>
  <label><input type="radio" name="pay" value="card" checked> Credit Card</label>
  <label><input type="radio" name="pay" value="bank"> Bank Transfer</label>
</fieldset>
```

- Native `<fieldset>` + `<legend>` preferred over ARIA `role="radiogroup"`
- Arrow keys cycle within group, Tab moves out

---

## Popover API Testing Checklist

| Test | Expected |
|------|----------|
| Tab to trigger | Popover opens on Enter/Space |
| Esc while open | Popover closes |
| Click outside | Popover closes (light dismiss) |
| Tab within popover | Focus cycles through content |
| SR announcement | Role + label announced |
| Mobile: swipe to trigger | Double-tap opens |
| Mobile: dismiss | Two-finger Z (VoiceOver) / Back gesture (TalkBack) |

---

## View Transitions

```css
/* MUST disable for reduced motion */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-group(*),
  ::view-transition-old(*),
  ::view-transition-new(*) {
    animation: none !important;
  }
}

/* Cross-document view transitions */
@view-transition { navigation: auto; }
```

```typescript
// JS guard
function navigateWithTransition(url: string) {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
    window.location.href = url;
    return;
  }
  document.startViewTransition(() => {
    window.location.href = url;
  });
}
```

- `view-transition-name`: unique per element, enables matched animations
- Duration <400ms — longer feels sluggish and fails vestibular users
- After DOM update: verify focus target still exists, refocus if needed

---

## React 19 Suspense aria-live

```tsx
{/* PERSISTENT live region — OUTSIDE Suspense boundary */}
<div aria-live="polite" aria-atomic="true" className="sr-only" id="async-status">
  {isLoading ? 'Loading data...' : 'Data loaded'}
</div>

<Suspense fallback={
  <div aria-busy="true" aria-label="Loading content" role="status">
    <Skeleton />
  </div>
}>
  <DataComponent />
</Suspense>
```

**Rules:**
- Live region must be in DOM before content changes (not inside Suspense)
- Mutate text content of existing node — do NOT replace the node
- `polite` for loading states, `assertive` only for critical failures
- After async resolution: focus first meaningful element in loaded content

---

## Dynamic Content Patterns

### Skeleton Screen A11y

```html
<div aria-busy="true" aria-label="Loading 5 items" role="status">
  <div aria-hidden="true" class="skeleton">...</div>
</div>
```

### Infinite Scroll + Focus

```html
<div role="feed" aria-busy={loading}>
  {items.map((item, i) => (
    <article key={item.id} aria-posinset={i + 1} aria-setsize={-1} tabindex={0}>
      {item.content}
    </article>
  ))}
</div>
<div aria-live="polite">{loading ? 'Loading more items...' : ''}</div>
```

- Focus new items after load (first new item)
- Provide "Load more" button as alternative to scroll trigger

### Data Table

- `<caption>` describes table purpose; `<th scope="col">` / `<th scope="row">` for headers
- Complex tables: use `headers` attribute; numbers: `dir="ltr"` in RTL contexts
- Sortable: `aria-sort="ascending"` / `"descending"` / `"none"` on `<th>`

### Real-Time Updates (sportchat_ultimate)

```html
<div role="log" aria-live="polite" aria-relevant="additions" aria-label="Match updates">
  <p>Goal! Team A 2-1 at 78'</p>
</div>
```

- `role="log"`: new items added, old preserved
- `aria-relevant="additions"`: only announce new messages
- Throttle announcements: max 1 per 3-5 seconds to avoid SR overload

---

## Error Handling A11y

**Inline:** `<input aria-invalid="true" aria-describedby="email-error" />` + `<span id="email-error" role="alert">...</span>`

**Form-level:** `role="alert" aria-live="assertive" tabindex="-1"` summary with links to each errored field. Focus summary on submit failure. COGA: clear non-technical language. Validate on blur, summarize on submit.

---

## Accessible Animations

### Scroll-Driven Animations

```css
@media (prefers-reduced-motion: no-preference) {
  .parallax {
    animation: parallax-move linear;
    animation-timeline: scroll();
  }
}
/* No animation at all for reduce preference — no fallback needed */
```

### Microinteractions

```css
@media (prefers-reduced-motion: no-preference) {
  .button-press { transition: scale 0.1s ease; }
  .button-press:active { scale: 0.97; }
}
@media (prefers-reduced-motion: reduce) {
  .button-press:active { opacity: 0.8; } /* Subtle non-motion feedback */
}
```

---

## Focus Indicators (WCAG 2.4.12 / 2.4.13)

```css
/* AAA enhanced (2.4.13): 3px outline, 3:1 contrast, visible against ALL backgrounds */
:focus-visible {
  outline: 3px solid var(--ring);
  outline-offset: 3px;
  box-shadow: 0 0 0 6px rgba(var(--ring-rgb), 0.2);
}
```

- 2.4.12 (AA): not entirely obscured by sticky headers/footers
- 2.4.13 (AAA): fully visible, 2px min outline, encloses area >= 1px border of unfocused

---

## Text Spacing (1.4.12) + Content on Hover (1.4.13)

**1.4.12:** Support user override via CSS custom properties. No content loss at: line-height 1.5x, letter-spacing 0.12em, word-spacing 0.16em, paragraph-spacing 2x.

**1.4.13:** Content on hover/focus must be: (1) dismissible with Esc, (2) hoverable (pointer can move to it), (3) persistent until dismissed/pointer-leaves/invalid. Use `pointer-events: auto` on tooltip content.

---

## RTL + A11y Integration

- `dir="auto"` on user-generated content and live regions
- Numbers/dates: `<span dir="ltr">{number}</span>`
- Directional icons: `className="rtl:rotate-180"`
- Gradients: `bg-gradient-to-r rtl:bg-gradient-to-l`
- Positioning: `inset-s-*`/`inset-e-*` (NOT `start-*`/`end-*` for inset in TW 4.2)
- Container queries for zoom-safe typography: `@container` with `cqi` units

---

<!-- WEB_A11Y v24.6.0 | 18 APG patterns, native dialog, popover, view transitions, React 19, RTL -->

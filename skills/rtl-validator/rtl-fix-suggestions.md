# RTL Fix Suggestions Guide

## Common Violations and Their Fixes

This guide provides before/after examples for fixing RTL violations in your codebase.

---

## Tailwind CSS Fixes

### Margin Violations

#### ml-* / mr-* (Margin Left/Right)

```tsx
// BEFORE (WRONG)
<div className="ml-4">Content</div>
<div className="mr-2">Content</div>
<div className="ml-auto">Content</div>
<div className="ml-[20px] mr-[10px]">Content</div>

// AFTER (CORRECT)
<div className="ms-4">Content</div>      // margin-start
<div className="me-2">Content</div>      // margin-end
<div className="ms-auto">Content</div>   // margin-start auto
<div className="ms-[20px] me-[10px]">Content</div>
```

### Padding Violations

#### pl-* / pr-* (Padding Left/Right)

```tsx
// BEFORE (WRONG)
<div className="pl-4">Content</div>
<div className="pr-2">Content</div>
<div className="pl-6 pr-6">Content</div>

// AFTER (CORRECT)
<div className="ps-4">Content</div>      // padding-start
<div className="pe-2">Content</div>      // padding-end
<div className="px-6">Content</div>      // Or use px-* for both sides
```

### Position Violations

#### left-* / right-* (Position)

```tsx
// BEFORE (WRONG)
<div className="absolute left-0">Content</div>
<div className="fixed right-4 top-4">Content</div>
<div className="left-1/2 -translate-x-1/2">Centered</div>

// AFTER (CORRECT — inset-s-*/inset-e-* generate inset-inline-start/end in TW 4.2)
<div className="absolute inset-s-0">Content</div>
<div className="fixed inset-e-4 top-4">Content</div>
<div className="inset-s-1/2 -translate-x-1/2">Centered</div>
// NOTE: start-*/end-* are deprecated in TW 4.2 (still work, gradual phase-out)
```

### Text Alignment Violations

```tsx
// BEFORE (WRONG)
<p className="text-left">Paragraph</p>
<p className="text-right">Paragraph</p>

// AFTER (CORRECT)
<p className="text-start">Paragraph</p>   // Aligns to start (right in RTL)
<p className="text-end">Paragraph</p>     // Aligns to end (left in RTL)
```

### Border Violations

```tsx
// BEFORE (WRONG)
<div className="border-l-2 border-gray-300">Content</div>
<div className="border-r-4 border-blue-500">Content</div>
<div className="rounded-l-lg">Content</div>
<div className="rounded-r-xl">Content</div>

// AFTER (CORRECT)
<div className="border-s-2 border-gray-300">Content</div>  // border-start
<div className="border-e-4 border-blue-500">Content</div>  // border-end
<div className="rounded-s-lg">Content</div>   // rounded-start
<div className="rounded-e-xl">Content</div>   // rounded-end
```

### Combined Example

```tsx
// BEFORE (WRONG)
<div className="flex items-center pl-4 pr-2 ml-auto border-l-2">
  <span className="text-left mr-2">Label</span>
  <button className="ml-4">Action</button>
</div>

// AFTER (CORRECT)
<div className="flex items-center ps-4 pe-2 ms-auto border-s-2">
  <span className="text-start me-2">Label</span>
  <button className="ms-4">Action</button>
</div>
```

---

## CSS Property Fixes

### Margin Properties

```css
/* BEFORE (WRONG) */
.element {
  margin-left: 16px;
  margin-right: 8px;
}

/* AFTER (CORRECT) */
.element {
  margin-inline-start: 16px;
  margin-inline-end: 8px;
}

/* Or use shorthand */
.element {
  margin-inline: 8px 16px; /* end start in RTL context */
}
```

### Padding Properties

```css
/* BEFORE (WRONG) */
.container {
  padding-left: 24px;
  padding-right: 24px;
}

/* AFTER (CORRECT) */
.container {
  padding-inline-start: 24px;
  padding-inline-end: 24px;
}

/* Or use shorthand */
.container {
  padding-inline: 24px; /* Both sides equal */
}
```

### Position Properties

```css
/* BEFORE (WRONG) */
.tooltip {
  position: absolute;
  left: 0;
  right: auto;
}

/* AFTER (CORRECT) */
.tooltip {
  position: absolute;
  inset-inline-start: 0;
  inset-inline-end: auto;
}
```

### Text Alignment

```css
/* BEFORE (WRONG) */
.title {
  text-align: left;
}

.price {
  text-align: right;
}

/* AFTER (CORRECT) */
.title {
  text-align: start;
}

.price {
  text-align: end;
}
```

### Float

```css
/* BEFORE (WRONG) */
.image {
  float: left;
}

.sidebar {
  float: right;
}

/* AFTER (CORRECT) */
.image {
  float: inline-start;
}

.sidebar {
  float: inline-end;
}
```

### Border

```css
/* BEFORE (WRONG) */
.card {
  border-left: 4px solid blue;
  border-top-left-radius: 8px;
  border-bottom-left-radius: 8px;
}

/* AFTER (CORRECT) */
.card {
  border-inline-start: 4px solid blue;
  border-start-start-radius: 8px;
  border-end-start-radius: 8px;
}
```

---

## Inline Style Fixes (React/JSX)

### Style Objects

```tsx
// BEFORE (WRONG)
<div style={{ marginLeft: 16, paddingRight: 8 }}>
  Content
</div>

// AFTER (CORRECT)
<div style={{ marginInlineStart: 16, paddingInlineEnd: 8 }}>
  Content
</div>
```

### Dynamic Styles

```tsx
// BEFORE (WRONG)
const styles = {
  container: {
    paddingLeft: spacing.md,
    marginRight: spacing.sm,
    borderLeft: '2px solid red',
  }
};

// AFTER (CORRECT)
const styles = {
  container: {
    paddingInlineStart: spacing.md,
    marginInlineEnd: spacing.sm,
    borderInlineStart: '2px solid red',
  }
};
```

---

## Special Cases

### Numbers (Keep LTR)

Numbers should always read left-to-right, even in RTL contexts:

```tsx
// CORRECT: Wrap numbers in LTR container
<p>
  המחיר: <span dir="ltr" className="inline-block">₪1,234.56</span>
</p>

// CORRECT: Phone numbers
<a href="tel:+972501234567">
  <span dir="ltr">+972-50-123-4567</span>
</a>

// CORRECT: Dates
<time dir="ltr">18/01/2026</time>
```

### Code Blocks (Keep LTR)

Code should always be LTR:

```tsx
// CORRECT: Code snippets
<pre dir="ltr" className="text-start">
  <code>pnpm add @package/name</code>
</pre>

// CORRECT: Inline code
<p>
  השתמש בפקודה <code dir="ltr" className="inline-block">git commit</code>
</p>
```

### Icons That Should Flip — HORIZONTAL direction only

`rtl:rotate-180` applies ONLY to icons pointing left/right. Vertical icons (ChevronUp/Down, ArrowUp/Down) MUST NOT have `rtl:rotate-180`.

```tsx
// CORRECT: Horizontal arrow/chevron icons flip in RTL
<button className="flex items-center gap-2">
  <span>הבא</span>
  <ChevronRightIcon className="h-4 w-4 rtl:rotate-180" />
</button>

// CORRECT: Back button
<button className="flex items-center gap-2">
  <ArrowLeftIcon className="h-4 w-4 rtl:rotate-180" />
  <span>חזרה</span>
</button>

// CORRECT: Progress indicator
<div className="flex items-center">
  <span>התקדמות</span>
  <ArrowRightIcon className="h-4 w-4 rtl:rotate-180 animate-pulse" />
</div>
```

### Icons That Should NOT Flip — vertical icons AND non-directional icons

```tsx
// CORRECT: Vertical icons do NOT flip (up/down has no RTL mirror)
<ChevronUpIcon className="h-4 w-4" />    // Accordion open — NO rtl:rotate-180
<ChevronDownIcon className="h-4 w-4" />  // Accordion close — NO rtl:rotate-180
<ArrowUpIcon className="h-4 w-4" />      // Scroll to top — NO rtl:rotate-180
<ArrowDownIcon className="h-4 w-4" />    // Expand/download — NO rtl:rotate-180

// CORRECT: Non-directional icons do NOT flip
<CheckIcon className="h-4 w-4" />      // Checkmark
<XIcon className="h-4 w-4" />          // Close
<PlusIcon className="h-4 w-4" />       // Plus
<SearchIcon className="h-4 w-4" />     // Search
<MenuIcon className="h-4 w-4" />       // Hamburger menu
<SettingsIcon className="h-4 w-4" />   // Settings gear
```

### Email/URL Inputs

Form fields that contain LTR content:

```tsx
// CORRECT: Email input
<input
  type="email"
  dir="ltr"
  className="text-start"
  placeholder="user@example.com"
/>

// CORRECT: URL input
<input
  type="url"
  dir="ltr"
  className="text-start"
  placeholder="https://example.com"
/>

// CORRECT: Hebrew text input (default RTL)
<input
  type="text"
  placeholder="הזן שם מלא"
/>
```

### Mixed Language Content

```tsx
// CORRECT: English brand name in Hebrew sentence
<p>
  אנחנו משתמשים ב-<bdi dir="ltr">Next.js</bdi> ו-<bdi dir="ltr">React</bdi>
</p>

// CORRECT: Technical terms
<p>
  הפקודה <bdi dir="ltr">pnpm install</bdi> תתקין את החבילה
</p>
```

---

## Component Patterns

### RTL-Aware Button Group

```tsx
// CORRECT: Button with icon
function Button({ children, icon: Icon, iconPosition = 'end' }) {
  return (
    <button className="flex items-center gap-2">
      {iconPosition === 'start' && Icon && (
        <Icon className="h-4 w-4 rtl:rotate-180" />
      )}
      <span>{children}</span>
      {iconPosition === 'end' && Icon && (
        <Icon className="h-4 w-4 rtl:rotate-180" />
      )}
    </button>
  );
}
```

### RTL-Aware Card

```tsx
// CORRECT: Card with accent border
function Card({ children, accent = 'start' }) {
  return (
    <div className={cn(
      'rounded-lg bg-white p-4 shadow',
      accent === 'start' && 'border-s-4 border-blue-500',
      accent === 'end' && 'border-e-4 border-blue-500'
    )}>
      {children}
    </div>
  );
}
```

### RTL-Aware Navigation

```tsx
// CORRECT: Sidebar navigation
function Sidebar() {
  return (
    <nav className="w-64 border-e bg-gray-50 ps-4 pe-2">
      <ul className="space-y-2">
        <li>
          <a href="/" className="flex items-center gap-2 rounded-lg px-3 py-2">
            <HomeIcon className="h-5 w-5" />
            <span>בית</span>
          </a>
        </li>
        <li>
          <a href="/settings" className="flex items-center gap-2 rounded-lg px-3 py-2">
            <SettingsIcon className="h-5 w-5" />
            <span>הגדרות</span>
          </a>
        </li>
      </ul>
    </nav>
  );
}
```

---

## Migration Checklist

When migrating an existing LTR codebase to RTL-first:

1. **Layout Setup**
   - [ ] Add `dir="rtl"` to `<html>` element
   - [ ] Add `lang="he"` (or `lang="ar"`) attribute
   - [ ] Configure RTL-friendly font (Heebo for Hebrew)

2. **Tailwind Classes**
   - [ ] Replace all `ml-*` with `ms-*`
   - [ ] Replace all `mr-*` with `me-*`
   - [ ] Replace all `pl-*` with `ps-*`
   - [ ] Replace all `pr-*` with `pe-*`
   - [ ] Replace all `left-*` with `inset-s-*` (generates `inset-inline-start` for positioning). `start-*` deprecated in TW 4.2.
   - [ ] Replace all `right-*` with `inset-e-*` (generates `inset-inline-end` for positioning). `end-*` deprecated in TW 4.2.
   - [ ] Replace `text-left` with `text-start`
   - [ ] Replace `text-right` with `text-end`
   - [ ] Replace `border-l-*` with `border-s-*`
   - [ ] Replace `border-r-*` with `border-e-*`
   - [ ] Replace `rounded-l-*` with `rounded-s-*`
   - [ ] Replace `rounded-r-*` with `rounded-e-*`

3. **CSS Properties**
   - [ ] Replace `margin-left/right` with `margin-inline-start/end`
   - [ ] Replace `padding-left/right` with `padding-inline-start/end`
   - [ ] Replace `left/right` positioning with `inset-inline-start/end`
   - [ ] Replace `text-align: left/right` with `start/end`
   - [ ] Replace `float: left/right` with `inline-start/inline-end`

4. **Icons**
   - [ ] Add `rtl:rotate-180` to HORIZONTAL directional icons only (ChevronLeft/Right, ArrowLeft/Right)
   - [ ] Verify vertical icons (ChevronUp/Down, ArrowUp/Down) do NOT have `rtl:rotate-180`
   - [ ] Verify non-directional icons (Search, Menu, Settings, Check, X) don't flip

5. **Special Content**
   - [ ] Wrap numbers in `dir="ltr"` containers
   - [ ] Wrap code blocks in `dir="ltr"` containers
   - [ ] Set `dir="ltr"` on email/URL inputs

6. **Testing**
   - [ ] Run RTL audit script
   - [ ] Visual QA in RTL mode
   - [ ] Test form inputs
   - [ ] Test navigation flows

---

## Quick Find & Replace

Use these regex patterns for bulk fixes (use with caution, review changes):

```bash
# Tailwind margin (ml/mr)
find . -name "*.tsx" -exec sed -i 's/\bml-/ms-/g; s/\bmr-/me-/g' {} \;

# Tailwind padding (pl/pr)
find . -name "*.tsx" -exec sed -i 's/\bpl-/ps-/g; s/\bpr-/pe-/g' {} \;

# Tailwind position (TW 4.2: inset-s-*/inset-e-* replaces deprecated start-*/end-*)
find . -name "*.tsx" -exec sed -i 's/\bleft-/inset-s-/g; s/\bright-/inset-e-/g' {} \;

# Tailwind text alignment
find . -name "*.tsx" -exec sed -i 's/\btext-left\b/text-start/g; s/\btext-right\b/text-end/g' {} \;

# Tailwind border
find . -name "*.tsx" -exec sed -i 's/\bborder-l-/border-s-/g; s/\bborder-r-/border-e-/g' {} \;
find . -name "*.tsx" -exec sed -i 's/\brounded-l-/rounded-s-/g; s/\brounded-r-/rounded-e-/g' {} \;
```

**Always review changes before committing!**

---

*Version: 24.5.0 | Last Updated: 2026-02-19*

# RTL Fix Examples

> **Parent:** `../SKILL.md`
> **Purpose:** Before/after examples for common RTL violations

## Margin Fixes

### Basic Margin

```tsx
// BEFORE (violation)
<div className="ml-4 mr-2">Content</div>

// AFTER (fixed)
<div className="ms-4 me-2">Content</div>
```

### Auto Margin

```tsx
// BEFORE (violation)
<div className="ml-auto">Push to right</div>

// AFTER (fixed)
<div className="ms-auto">Push to end</div>
```

### Negative Margin

```tsx
// BEFORE (violation)
<div className="-ml-4 -mr-2">Overlap</div>

// AFTER (fixed)
<div className="-ms-4 -me-2">Overlap</div>
```

---

## Padding Fixes

### Basic Padding

```tsx
// BEFORE (violation)
<button className="pl-6 pr-4">Button</button>

// AFTER (fixed)
<button className="ps-6 pe-4">Button</button>
```

### Asymmetric Padding

```tsx
// BEFORE (violation)
<div className="pl-8 pr-4 py-2">Card</div>

// AFTER (fixed)
<div className="ps-8 pe-4 py-2">Card</div>
```

---

## Position Fixes

### Absolute Position

```tsx
// BEFORE (violation)
<span className="absolute left-0 top-0">Badge</span>

// AFTER (fixed — inset-s-* generates inset-inline-start in TW 4.2; start-* deprecated)
<span className="absolute inset-s-0 top-0">Badge</span>
```

### Fixed Sidebar

```tsx
// BEFORE (violation)
<aside className="fixed left-0 top-0 w-64 h-screen">
  Sidebar
</aside>

// AFTER (fixed — inset-s-* generates inset-inline-start in TW 4.2; start-* deprecated)
<aside className="fixed inset-s-0 top-0 w-64 h-screen">
  Sidebar
</aside>
```

### Tooltip Position

```tsx
// BEFORE (violation)
<div className="absolute right-full mr-2">
  Tooltip
</div>

// AFTER (fixed — inset-e-* generates inset-inline-end in TW 4.2; end-* deprecated)
<div className="absolute inset-e-full me-2">
  Tooltip
</div>
```

---

## Text Alignment Fixes

### Heading Alignment

```tsx
// BEFORE (violation)
<h1 className="text-left text-2xl">Title</h1>

// AFTER (fixed)
<h1 className="text-start text-2xl">Title</h1>
```

### Price Alignment

```tsx
// BEFORE (violation)
<td className="text-right font-mono">
  <span dir="ltr">₪1,234</span>
</td>

// AFTER (fixed)
<td className="text-end font-mono">
  <span dir="ltr">₪1,234</span>
</td>
```

---

## Border Fixes

### Left Border Accent

```tsx
// BEFORE (violation)
<div className="border-l-4 border-l-blue-500 pl-4">
  Highlighted content
</div>

// AFTER (fixed)
<div className="border-s-4 border-s-blue-500 ps-4">
  Highlighted content
</div>
```

### Divider

```tsx
// BEFORE (violation)
<div className="border-r border-gray-200 pr-4 mr-4">
  Left section
</div>

// AFTER (fixed)
<div className="border-e border-gray-200 pe-4 me-4">
  Start section
</div>
```

---

## Border Radius Fixes

### Rounded Side

```tsx
// BEFORE (violation)
<div className="rounded-l-lg">Left rounded</div>

// AFTER (fixed)
<div className="rounded-s-lg">Start rounded</div>
```

### Tab Button

```tsx
// BEFORE (violation)
<button className="rounded-tl-lg rounded-bl-lg">
  Tab
</button>

// AFTER (fixed)
<button className="rounded-ss-lg rounded-es-lg">
  Tab
</button>
```

### Card with One Rounded Corner

```tsx
// BEFORE (violation)
<div className="rounded-tr-2xl rounded-bl-2xl">
  Diagonal card
</div>

// AFTER (fixed)
<div className="rounded-se-2xl rounded-es-2xl">
  Diagonal card
</div>
```

---

## Icon Fixes

### Navigation Arrow

```tsx
// BEFORE (violation - no flip)
<button>
  <span>הבא</span>
  <ChevronRight className="h-5 w-5" />
</button>

// AFTER (fixed)
<button className="flex items-center gap-2">
  <span>הבא</span>
  <ChevronRight className="h-5 w-5 rtl:rotate-180" />
</button>
```

### Back Button

```tsx
// BEFORE (violation - no flip)
<button>
  <ArrowLeft className="h-5 w-5" />
  <span>חזרה</span>
</button>

// AFTER (fixed)
<button className="flex items-center gap-2">
  <ArrowLeft className="h-5 w-5 rtl:rotate-180" />
  <span>חזרה</span>
</button>
```

### Breadcrumb Separator

```tsx
// BEFORE (violation)
<nav className="flex items-center">
  <a href="/">בית</a>
  <ChevronRight className="mx-2 h-4 w-4" />
  <a href="/products">מוצרים</a>
</nav>

// AFTER (fixed)
<nav className="flex items-center gap-2">
  <a href="/">בית</a>
  <ChevronRight className="h-4 w-4 rtl:rotate-180" />
  <a href="/products">מוצרים</a>
</nav>
```

---

## CSS-in-JS Fixes

### Styled Components

```tsx
// BEFORE (violation)
const Card = styled.div`
  margin-left: 16px;
  padding-right: 24px;
`;

// AFTER (fixed)
const Card = styled.div`
  margin-inline-start: 16px;
  padding-inline-end: 24px;
`;
```

### Inline Styles

```tsx
// BEFORE (violation)
<div style={{ marginLeft: '16px', paddingRight: '24px' }}>
  Content
</div>

// AFTER (fixed)
<div style={{ marginInlineStart: '16px', paddingInlineEnd: '24px' }}>
  Content
</div>
```

### Emotion CSS

```tsx
// BEFORE (violation)
const styles = css`
  left: 0;
  border-left: 2px solid blue;
`;

// AFTER (fixed)
const styles = css`
  inset-inline-start: 0;
  border-inline-start: 2px solid blue;
`;
```

---

## Complex Component Fixes

### Card with Badge

```tsx
// BEFORE (violation)
<div className="relative rounded-lg border p-4">
  <span className="absolute -top-2 -right-2 rounded-full bg-red-500 px-2">
    New
  </span>
  <h3 className="text-left font-bold">Title</h3>
  <p className="ml-4">Description</p>
</div>

// AFTER (fixed)
<div className="relative rounded-lg border p-4">
  <span className="absolute -top-2 -inset-e-2 rounded-full bg-red-500 px-2">
    New
  </span>
  <h3 className="text-start font-bold">Title</h3>
  <p className="ms-4">Description</p>
</div>
```

### Navigation Menu

```tsx
// BEFORE (violation)
<nav className="fixed left-0 top-0 h-full w-64 border-r bg-white">
  <ul>
    <li className="border-l-4 border-l-blue-500 pl-4">Active</li>
    <li className="pl-4">Item 2</li>
  </ul>
</nav>

// AFTER (fixed)
<nav className="fixed inset-s-0 top-0 h-full w-64 border-e bg-white">
  <ul>
    <li className="border-s-4 border-s-blue-500 ps-4">Active</li>
    <li className="ps-4">Item 2</li>
  </ul>
</nav>
```

### Form Layout

```tsx
// BEFORE (violation)
<form>
  <div className="flex items-center">
    <label className="w-32 text-right pr-4">שם:</label>
    <input className="flex-1 rounded-l-none rounded-r-lg border" />
  </div>
</form>

// AFTER (fixed)
<form>
  <div className="flex items-center gap-4">
    <label className="w-32 text-end">שם:</label>
    <input className="flex-1 rounded-s-none rounded-e-lg border" />
  </div>
</form>
```

---

## Quick Fix Patterns

Use these search-and-replace patterns:

| Find | Replace |
|------|---------|
| `ml-` | `ms-` |
| `mr-` | `me-` |
| `pl-` | `ps-` |
| `pr-` | `pe-` |
| `left-` | `inset-s-` (generates `inset-inline-start`; TW 4.2) |
| `right-` | `inset-e-` (generates `inset-inline-end`; TW 4.2) |
| `text-left` | `text-start` |
| `text-right` | `text-end` |
| `border-l` | `border-s` |
| `border-r` | `border-e` |
| `rounded-l` | `rounded-s` |
| `rounded-r` | `rounded-e` |
| `rounded-tl` | `rounded-ss` |
| `rounded-tr` | `rounded-se` |
| `rounded-bl` | `rounded-es` |
| `rounded-br` | `rounded-ee` |

---

<!-- RTL_FIX_EXAMPLES v24.5.0 | Updated: 2026-02-19 -->

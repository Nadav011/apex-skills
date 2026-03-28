# Tailwind RTL Class Mapping

> **Parent:** `../SKILL.md`
> **Purpose:** Complete Tailwind class translations for RTL-first development

## Margin Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `ml-0` through `ml-96` | `ms-0` through `ms-96` | `margin-inline-start` |
| `mr-0` through `mr-96` | `me-0` through `me-96` | `margin-inline-end` |
| `ml-auto` | `ms-auto` | `margin-inline-start: auto` |
| `mr-auto` | `me-auto` | `margin-inline-end: auto` |
| `ml-px` | `ms-px` | `margin-inline-start: 1px` |
| `mr-px` | `me-px` | `margin-inline-end: 1px` |
| `-ml-*` | `-ms-*` | Negative start margin |
| `-mr-*` | `-me-*` | Negative end margin |

### Margin Examples

```tsx
// WRONG
<div className="ml-4 mr-2">Content</div>

// CORRECT
<div className="ms-4 me-2">Content</div>

// WRONG - negative margin
<div className="-ml-4">Overlap</div>

// CORRECT - negative margin
<div className="-ms-4">Overlap</div>
```

---

## Padding Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `pl-0` through `pl-96` | `ps-0` through `ps-96` | `padding-inline-start` |
| `pr-0` through `pr-96` | `pe-0` through `pe-96` | `padding-inline-end` |
| `pl-px` | `ps-px` | `padding-inline-start: 1px` |
| `pr-px` | `pe-px` | `padding-inline-end: 1px` |

### Padding Examples

```tsx
// WRONG
<button className="pl-4 pr-4">Button</button>

// CORRECT
<button className="ps-4 pe-4">Button</button>

// Or use symmetric padding (works in both directions)
<button className="px-4">Button</button>
```

---

## Position Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `left-0` through `left-full` | `inset-s-0` through `inset-s-full` | `inset-inline-start` |
| `right-0` through `right-full` | `inset-e-0` through `inset-e-full` | `inset-inline-end` |
| `left-auto` | `inset-s-auto` | `inset-inline-start: auto` |
| `right-auto` | `inset-e-auto` | `inset-inline-end: auto` |
| `left-1/2` | `inset-s-1/2` | `inset-inline-start: 50%` |
| `right-1/2` | `inset-e-1/2` | `inset-inline-end: 50%` |
| `-left-*` | `-inset-s-*` | Negative start position |
| `-right-*` | `-inset-e-*` | Negative end position |

> **TW 4.2:** Use `inset-s-*`/`inset-e-*` for inset positioning — these generate `inset-inline-start`/`inset-inline-end`.
> `start-*`/`end-*` are deprecated in TW 4.2 (still work, gradual phase-out). Prefer `inset-s-*`/`inset-e-*`.
> `ms-*`/`me-*`/`ps-*`/`pe-*`/`text-start`/`text-end`/`inset-s-*`/`inset-e-*` are all correct logical property classes.

### Position Examples

```tsx
// WRONG - Absolute positioning
<div className="absolute left-0 top-0">Badge</div>

// CORRECT (TW 4.2) - inset-s-* generates inset-inline-start
<div className="absolute inset-s-0 top-0">Badge</div>

// WRONG - Sticky sidebar
<aside className="fixed left-0 top-0 h-full">Sidebar</aside>

// CORRECT (TW 4.2) - inset-s-* generates inset-inline-start
<aside className="fixed inset-s-0 top-0 h-full">Sidebar</aside>
```

---

## Text Alignment Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `text-left` | `text-start` | `text-align: start` |
| `text-right` | `text-end` | `text-align: end` |

### Text Alignment Examples

```tsx
// WRONG
<p className="text-left">Paragraph</p>

// CORRECT
<p className="text-start">Paragraph</p>

// Note: text-center and text-justify work in both directions
<p className="text-center">Centered text</p>
```

---

## Border Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `border-l` | `border-s` | `border-inline-start-width` |
| `border-r` | `border-e` | `border-inline-end-width` |
| `border-l-0` through `border-l-8` | `border-s-0` through `border-s-8` | Start border width |
| `border-r-0` through `border-r-8` | `border-e-0` through `border-e-8` | End border width |
| `border-l-{color}` | `border-s-{color}` | Start border color |
| `border-r-{color}` | `border-e-{color}` | End border color |

### Border Examples

```tsx
// WRONG
<div className="border-l-4 border-l-blue-500">Card</div>

// CORRECT
<div className="border-s-4 border-s-blue-500">Card</div>
```

---

## Border Radius Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `rounded-l` | `rounded-s` | Start corners |
| `rounded-r` | `rounded-e` | End corners |
| `rounded-l-none` through `rounded-l-full` | `rounded-s-none` through `rounded-s-full` | Start corner radius |
| `rounded-r-none` through `rounded-r-full` | `rounded-e-none` through `rounded-e-full` | End corner radius |
| `rounded-tl-*` | `rounded-ss-*` | Start-start corner |
| `rounded-tr-*` | `rounded-se-*` | Start-end corner |
| `rounded-bl-*` | `rounded-es-*` | End-start corner |
| `rounded-br-*` | `rounded-ee-*` | End-end corner |

### Border Radius Examples

```tsx
// WRONG
<div className="rounded-l-lg">Card</div>

// CORRECT
<div className="rounded-s-lg">Card</div>

// WRONG - specific corner
<div className="rounded-tl-lg rounded-br-lg">Diagonal</div>

// CORRECT - specific corner
<div className="rounded-ss-lg rounded-ee-lg">Diagonal</div>
```

---

## Space Between Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `space-x-*` with manual RTL | Use `gap-*` instead | N/A |

### Spacing Examples

```tsx
// AVOID - space-x can have RTL issues
<div className="flex space-x-4">
  <div>Item 1</div>
  <div>Item 2</div>
</div>

// PREFERRED - gap works correctly in both directions
<div className="flex gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
</div>
```

---

## Divide Classes

| Physical (FORBIDDEN) | Logical (REQUIRED) | CSS Property |
|---------------------|-------------------|--------------|
| `divide-x` | Works correctly | Border between horizontal items |

Divide classes generally work correctly in both directions when using flexbox or grid.

---

## Transform Classes

| Class | RTL Behavior | Notes |
|-------|--------------|-------|
| `translate-x-*` | Does NOT auto-flip | Use with `rtl:-translate-x-*` if needed |
| `rotate-*` | Same in both directions | Use `rtl:rotate-180` for HORIZONTAL directional icons only (ChevronLeft/Right, ArrowLeft/Right). NEVER for vertical icons (ChevronUp/Down, ArrowUp/Down). |
| `scale-x-*` | Same in both directions | - |

### Transform Examples

```tsx
// Directional icon that needs flipping
<ChevronRight className="rtl:rotate-180" />

// Transform that needs RTL variant
<div className="translate-x-4 rtl:-translate-x-4">Slide</div>
```

---

## Quick Reference Regex Patterns

For finding violations in code:

```regex
# Margin violations
\bm[lr]-\d+
\bm[lr]-auto
\bm[lr]-px
\b-m[lr]-

# Padding violations
\bp[lr]-\d+
\bp[lr]-px

# Position violations (physical — use inset-s-*/inset-e-* instead; start-*/end-* deprecated in TW 4.2)
\b(left|right)-\d+
\b(left|right)-auto
\b(left|right)-full
\b(left|right)-1/

# Text alignment violations
\btext-(left|right)\b

# Border violations
\bborder-[lr](-\d+)?
\brounded-[lr]
\brounded-[tb][lr]
```

---

<!-- RTL_TAILWIND_MAPPING v24.5.0 | Updated: 2026-02-19 -->

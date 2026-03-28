# CSS Logical Properties Reference

> **Parent:** `../SKILL.md`
> **Purpose:** Complete CSS logical properties for RTL-first development

## CSS Property Mapping

### Margin Properties

| Physical (Avoid) | Logical (Use) | Description |
|------------------|---------------|-------------|
| `margin-left` | `margin-inline-start` | Start margin (left in LTR, right in RTL) |
| `margin-right` | `margin-inline-end` | End margin (right in LTR, left in RTL) |
| `margin-top` | `margin-block-start` | Block start margin |
| `margin-bottom` | `margin-block-end` | Block end margin |

### Padding Properties

| Physical (Avoid) | Logical (Use) | Description |
|------------------|---------------|-------------|
| `padding-left` | `padding-inline-start` | Start padding |
| `padding-right` | `padding-inline-end` | End padding |
| `padding-top` | `padding-block-start` | Block start padding |
| `padding-bottom` | `padding-block-end` | Block end padding |

### Position Properties

| Physical (Avoid) | Logical (Use) | Description |
|------------------|---------------|-------------|
| `left` | `inset-inline-start` | Start position |
| `right` | `inset-inline-end` | End position |
| `top` | `inset-block-start` | Block start position |
| `bottom` | `inset-block-end` | Block end position |

### Border Properties

| Physical (Avoid) | Logical (Use) | Description |
|------------------|---------------|-------------|
| `border-left` | `border-inline-start` | Start border |
| `border-right` | `border-inline-end` | End border |
| `border-top-left-radius` | `border-start-start-radius` | Start-start corner |
| `border-top-right-radius` | `border-start-end-radius` | Start-end corner |
| `border-bottom-left-radius` | `border-end-start-radius` | End-start corner |
| `border-bottom-right-radius` | `border-end-end-radius` | End-end corner |

### Text Properties

| Physical (Avoid) | Logical (Use) | Description |
|------------------|---------------|-------------|
| `text-align: left` | `text-align: start` | Align to start |
| `text-align: right` | `text-align: end` | Align to end |

### Float Properties

| Physical (Avoid) | Logical (Use) | Description |
|------------------|---------------|-------------|
| `float: left` | `float: inline-start` | Float to start |
| `float: right` | `float: inline-end` | Float to end |

---

## Layout Setup

### HTML Document

```html
<!DOCTYPE html>
<html lang="he" dir="rtl">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  </head>
  <body>
    <!-- Content renders RTL by default -->
  </body>
</html>
```

### Next.js App Router

```tsx
// app/layout.tsx
import { Heebo } from 'next/font/google';

const heebo = Heebo({
  subsets: ['hebrew', 'latin'],
  variable: '--font-heebo',
});

export default function RootLayout({ 
  children 
}: { 
  children: React.ReactNode 
}) {
  return (
    <html lang="he" dir="rtl">
      <body className={`${heebo.variable} font-heebo antialiased`}>
        {children}
      </body>
    </html>
  );
}
```

### Tailwind CSS Configuration

```css
/* app/globals.css — Tailwind v4 CSS-first config */
@import "tailwindcss";

@theme {
  --font-heebo: "Heebo", sans-serif;
}
```

> **Note:** The `tailwindcss-rtl` plugin is no longer needed in Tailwind v4. Logical properties (`ms-`, `me-`, `ps-`, `pe-`, `text-start`, `text-end`, `inset-s-`, `inset-e-`, etc.) are built-in. (`start-`/`end-` deprecated in TW 4.2; use `inset-s-`/`inset-e-` instead.)

### CSS Custom Properties for RTL

```css
/* Global RTL-aware custom properties */
:root {
  --spacing-start: var(--spacing-inline-start);
  --spacing-end: var(--spacing-inline-end);
}

/* RTL-aware container */
.container-rtl {
  padding-inline-start: 1rem;
  padding-inline-end: 1rem;
  margin-inline: auto;
}

/* RTL-aware flex */
.flex-rtl {
  display: flex;
  gap: 1rem;
  /* gap works correctly in both directions */
}
```

---

## Browser Support

CSS Logical Properties have excellent browser support (95%+):

| Browser | Version | Support |
|---------|---------|---------|
| Chrome | 69+ | Full |
| Firefox | 41+ | Full |
| Safari | 12.1+ | Full |
| Edge | 79+ | Full |

---

## Resources

- [MDN: CSS Logical Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values)
- [Can I Use: CSS Logical Properties](https://caniuse.com/css-logical-props)
- [W3C CSS Logical Properties Spec](https://www.w3.org/TR/css-logical-1/)

---

<!-- RTL_CSS_PATTERNS v24.5.0 | Updated: 2026-02-19 -->

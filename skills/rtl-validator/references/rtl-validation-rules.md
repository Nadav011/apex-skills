# RTL Validation Rules

> **Parent:** `../SKILL.md`
> **Purpose:** Detailed validation rules, icon handling, and special cases

## Violation Severity Levels

| Level | Pattern | Description | Action |
|-------|---------|-------------|--------|
| ERROR | `ml-*`, `mr-*`, `pl-*`, `pr-*` | Direct physical Tailwind classes | Must fix before merge |
| ERROR | `left-*`, `right-*` | Physical position classes | Must fix before merge |
| ERROR | `text-left`, `text-right` | Physical text alignment | Must fix before merge |
| ERROR | `border-l-*`, `border-r-*` | Physical border classes | Must fix before merge |
| ERROR | `rounded-l-*`, `rounded-r-*` | Physical border radius | Must fix before merge |
| WARNING | `marginLeft`, `marginRight` | CSS-in-JS physical properties | Review and fix |
| WARNING | `paddingLeft`, `paddingRight` | CSS-in-JS physical properties | Review and fix |
| WARNING | Horizontal directional icon without flip | Missing `rtl:rotate-180` on left/right icon | Review and fix |
| INFO | `space-x-*` usage | Consider using `gap-*` | Consider fixing |

---

## Icon Flipping Rules

> **KEY RULE:** `rtl:rotate-180` applies ONLY to icons that point horizontally (left/right). Icons that point vertically (up/down) have no RTL semantic and MUST NOT receive `rtl:rotate-180`. Flagging ChevronUp/ChevronDown/ArrowUp/ArrowDown for `rtl:rotate-180` is a **false positive**.

### Icons That MUST Flip — HORIZONTAL direction only

These icons indicate left/right direction and must include `rtl:rotate-180`:

| Icon Type | Examples | Reason |
|-----------|----------|--------|
| Horizontal Arrows | `ArrowLeft`, `ArrowRight`, `ArrowBack`, `ArrowForward` | Horizontal direction indication |
| Horizontal Chevrons | `ChevronLeft`, `ChevronRight` | Horizontal navigation direction |
| Horizontal Carets | `CaretLeft`, `CaretRight` | Horizontal dropdown/expand direction |
| Navigation | `NavigateNext`, `NavigateBefore` | Page navigation (horizontal) |
| Progress | `SkipNext`, `SkipPrevious` | Media controls (horizontal) |
| Undo/Redo | `Undo`, `Redo` | Action direction (horizontal) |

```tsx
// CORRECT - Horizontal directional icons flip
<ArrowLeft className="h-5 w-5 rtl:rotate-180" />
<ChevronRight className="h-5 w-5 rtl:rotate-180" />
<ArrowBack className="h-5 w-5 rtl:rotate-180" />
```

### Icons That NEVER Flip — vertical icons AND non-directional icons

These icons must NOT have `rtl:rotate-180`:

| Icon Type | Examples | Reason |
|-----------|----------|--------|
| **Vertical Arrows** | `ArrowUp`, `ArrowDown` | Up/down has no RTL mirror — FALSE POSITIVE to flag these |
| **Vertical Chevrons** | `ChevronUp`, `ChevronDown` | Up/down has no RTL mirror — FALSE POSITIVE to flag these |
| **Vertical Carets** | `CaretUp`, `CaretDown` | Up/down has no RTL mirror — FALSE POSITIVE to flag these |
| Checkmarks | `Check`, `CheckCircle`, `CheckSquare` | Universal meaning |
| Close | `X`, `Close`, `XCircle` | Universal meaning |
| Math | `Plus`, `Minus`, `Divide` | Universal symbols |
| Social | `Facebook`, `Twitter`, `Instagram` | Brand logos |
| Currency | `DollarSign`, `Euro` | Standard symbols |
| Time | `Clock`, `Calendar` | Universal reading |
| Actions | `Search`, `Settings`, `Menu`, `Filter` | Non-directional |
| Media | `Play`, `Pause`, `Stop` | Universal controls |
| Files | `File`, `Folder`, `Download`, `Upload` | Non-directional |

```tsx
// CORRECT - Vertical icons do NOT flip (up/down has no RTL mirror)
<ChevronUp className="h-5 w-5" />       // accordion open — NO rtl:rotate-180
<ChevronDown className="h-5 w-5" />     // accordion close — NO rtl:rotate-180
<ArrowUp className="h-5 w-5" />         // scroll to top — NO rtl:rotate-180
<ArrowDown className="h-5 w-5" />       // expand/download — NO rtl:rotate-180

// CORRECT - Non-directional icons do NOT flip
<CheckIcon className="h-5 w-5" />
<XIcon className="h-5 w-5" />
<SearchIcon className="h-5 w-5" />
<MenuIcon className="h-5 w-5" />
```

### Icon Decision Tree

```
Is the icon indicating direction?
├── YES → Does it point LEFT or RIGHT (horizontal axis)?
│   ├── YES → Add rtl:rotate-180
│   └── NO (up/down vertical axis) → NO flip — vertical icons are RTL-neutral
└── NO → Do NOT add flip class
```

---

## Special Cases

### Numbers and Prices

Numbers, prices, and phone numbers should remain LTR:

```tsx
// Phone numbers
<span dir="ltr" className="inline-block">
  +972-50-123-4567
</span>

// Prices
<span dir="ltr" className="inline-block">
  ₪1,234.56
</span>

// Percentages
<span dir="ltr" className="inline-block">
  15.5%
</span>

// Dates (numeric format)
<span dir="ltr" className="inline-block">
  2026-01-21
</span>
```

### Code and Technical Content

Code blocks, URLs, and file paths should remain LTR:

```tsx
// Code blocks
<pre dir="ltr" className="text-start">
  pnpm add package-name
</pre>

// Inline code
<code dir="ltr" className="inline-block">
  const x = 42;
</code>

// URLs
<a href="https://example.com" dir="ltr">
  https://example.com
</a>

// File paths
<span dir="ltr" className="inline-block">
  /home/user/documents/file.txt
</span>
```

### Mixed Content (BiDi)

English terms embedded in Hebrew text:

```tsx
// Using <bdi> for isolation
<p>
  אנחנו משתמשים ב-<bdi dir="ltr">Next.js</bdi> לפיתוח האפליקציה
</p>

// Brand names
<p>
  החברה שלנו עובדת עם <bdi dir="ltr">Google Cloud</bdi>
</p>

// Technical terms
<p>
  הפונקציה מחזירה <bdi dir="ltr">Promise&lt;void&gt;</bdi>
</p>
```

### Form Inputs

Different input types require different direction handling:

```tsx
// Email - always LTR
<input
  type="email"
  dir="ltr"
  className="text-start"
  placeholder="email@example.com"
/>

// URL - always LTR
<input
  type="url"
  dir="ltr"
  className="text-start"
  placeholder="https://"
/>

// Phone - always LTR
<input
  type="tel"
  dir="ltr"
  className="text-start"
  placeholder="+972-50-000-0000"
/>

// Hebrew text - RTL (default)
<input
  type="text"
  placeholder="שם מלא"
/>

// Numbers - LTR
<input
  type="number"
  dir="ltr"
  className="text-start"
/>

// Password - LTR (for consistency)
<input
  type="password"
  dir="ltr"
  className="text-start"
/>
```

### Tables

Tables with mixed content:

```tsx
<table dir="rtl">
  <thead>
    <tr>
      <th className="text-start">שם</th>
      <th className="text-start">אימייל</th>
      <th className="text-end">מחיר</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>ישראל ישראלי</td>
      <td dir="ltr" className="text-start">israel@example.com</td>
      <td dir="ltr" className="text-end">₪1,234</td>
    </tr>
  </tbody>
</table>
```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/rtl-check.yml
name: RTL Validation

on:
  pull_request:
    paths:
      - '**.tsx'
      - '**.ts'
      - '**.css'

jobs:
  rtl-check:
    runs-on: [self-hosted, linux, x64, pop-os]
    steps:
      - uses: actions/checkout@v4
      
      - name: RTL Validation
        run: |
          chmod +x ~/.claude/skills/rtl-validator/rtl-audit.sh
          ~/.claude/skills/rtl-validator/rtl-audit.sh ./src
```

### Pre-commit Hook

```bash
#!/bin/bash
# .husky/pre-commit

# Run RTL validation on staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(tsx?|css)$')

if [ -n "$STAGED_FILES" ]; then
  echo "Running RTL validation..."
  ~/.claude/skills/rtl-validator/rtl-audit.sh ./src || exit 1
fi
```

### Biome Integration

Biome 2.4.4 is the project linter (replaces ESLint). RTL violations from physical CSS classes
are caught by the rtl-audit.sh script and the tool-guard-hybrid.py hook. To suppress a
specific RTL-ok instance inline, use the override comment:

```tsx
// biome-ignore lint: rtl-ok — intentional LTR layout for this numeric table column
<td className="text-right">
```

For CI enforcement, the `rtl-audit.sh` script runs independently of Biome and provides
RTL-specific pattern detection that complements Biome's general linting rules.

---

## Testing RTL

### Manual Testing Checklist

- [ ] Toggle `dir="ltr"` on `<html>` to verify layout flips correctly
- [ ] Check all directional icons flip appropriately
- [ ] Verify numbers/prices remain LTR
- [ ] Test form inputs with mixed content
- [ ] Check tables with numeric data
- [ ] Verify scrollbars appear on correct side

### Automated Testing

```typescript
// rtl.test.tsx
import { render } from '@testing-library/react';

describe('RTL Support', () => {
  it('should render correctly in RTL', () => {
    const { container } = render(
      <div dir="rtl">
        <Component />
      </div>
    );
    
    // Check no physical classes
    expect(container.innerHTML).not.toMatch(/\bml-\d/);
    expect(container.innerHTML).not.toMatch(/\bmr-\d/);
  });
});
```

---

<!-- RTL_VALIDATION_RULES v24.5.0 | Updated: 2026-02-19 -->

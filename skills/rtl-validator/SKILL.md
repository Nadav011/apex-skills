---
name: rtl-validator
description: "Use when user wants to RTL-VALIDATOR enforces APEX Law #5: RTL-FIRST with zero tolerance for physical directional properties. This skill scans, detects, reports, and auto-fixes RTL..."
---

# RTL-VALIDATOR v24.7.0

> **APEX Law #5 Enforcement System**
> **Inherits:** `~/.claude/CLAUDE.md` (v24.7.0)
> **Authority:** LAW_5_GUARDIAN | Zero-Tolerance RTL Compliance

---

## PURPOSE

RTL-VALIDATOR enforces **APEX Law #5: RTL-FIRST** with zero tolerance for physical directional properties. This skill scans, detects, reports, and auto-fixes RTL violations across all frontend code (React, Next.js, Flutter, CSS).

**Core Mission:** Ensure Hebrew/Arabic applications render correctly in RTL mode by enforcing logical CSS properties throughout the codebase.

### Prime Directives

| ID | Directive | Severity |
|----|-----------|----------|
| PD1 | Zero physical properties (ml/mr/pl/pr/left/right) | BLOCKING |
| PD2 | Logical properties only (ms/me/ps/pe/inset-s/inset-e; `start-`/`end-` deprecated for inset in TW 4.2) | BLOCKING |
| PD3 | HORIZONTAL directional icons must have rtl:rotate-180 (VERTICAL icons up/down NEVER flip) | WARNING |
| PD4 | LTR content (numbers, URLs) wrapped in dir="ltr" | WARNING |
| PD5 | English in Hebrew uses `<bdi>` isolation | INFO |
| PD6 | CSS-in-JS uses logical properties | WARNING |
| PD7 | Form inputs (email/url/tel) have dir="ltr" | WARNING |
| PD8 | Prefer gap-* over space-x-* | INFO |

---

## COMMANDS

### `/rtl scan [path]`
Scan code for RTL violations.

```bash
# Scan directory
/rtl scan ./src

# Scan with verbose output
/rtl scan ./src --verbose

# JSON output for CI
/rtl scan ./src --json
```

### `/rtl fix [path]`
Auto-fix RTL violations in place.

```bash
# Fix all violations
/rtl fix ./src

# Preview fixes without applying
/rtl fix ./src --dry-run

# Interactive mode (confirm each fix)
/rtl fix ./src --interactive
```

### `/rtl audit [path]`
Full RTL compliance audit with detailed report.

```bash
# Full audit
/rtl audit ./src

# CI mode (exit 1 on violations)
/rtl audit ./src --ci

# Generate markdown report
/rtl audit ./src --report
```

### `/rtl check [path]`
Quick RTL check (errors only, fast).

```bash
/rtl check ./src/components/Button.tsx
```

### `/rtl report [path]`
Generate RTL compliance report.

```bash
# Markdown report
/rtl report ./src --format=md

# JSON report
/rtl report ./src --format=json
```

### `/rtl rules`
Display RTL mapping rules reference.

### `/rtl icons`
Show icon flipping guidelines.

---

## WORKFLOW

### 1. Detection Phase

```
Input Code
    |
    v
[AST Parser] --> Parse TSX/JSX/CSS
    |
    v
[Pattern Matcher] --> Check violation patterns
    |
    v
[Severity Classifier] --> ERROR | WARNING | INFO
    |
    v
Output Violations
```

### 2. Fix Phase

```
Violation Detected
    |
    v
[Lookup Fix Mapping] --> ml- -> ms-, etc.
    |
    v
[Apply Transformation] --> Update source
    |
    v
[Validate Fix] --> Ensure no regression
    |
    v
Output Fixed Code
```

### 3. Integration Phase

**Pre-Commit Hook:**
```bash
# .husky/pre-commit
~/.claude/skills/rtl-validator/rtl-audit.sh ./src || exit 1
```

**GitHub Actions:**
```yaml
- name: RTL Validation
  run: ~/.claude/skills/rtl-validator/rtl-audit.sh ./src --ci --json
```

---

## QUICK REFERENCE

### Forbidden -> Required Mappings

| FORBIDDEN | REQUIRED | Type |
|-----------|----------|------|
| `ml-*` | `ms-*` | Margin Start |
| `mr-*` | `me-*` | Margin End |
| `pl-*` | `ps-*` | Padding Start |
| `pr-*` | `pe-*` | Padding End |
| `left-*` | `inset-s-*` | Inset Inline Start |
| `right-*` | `inset-e-*` | Inset Inline End |
| `text-left` | `text-start` | Text Align Start |
| `text-right` | `text-end` | Text Align End |
| `border-l-*` | `border-s-*` | Border Start |
| `border-r-*` | `border-e-*` | Border End |
| `rounded-l-*` | `rounded-s-*` | Radius Start |
| `rounded-r-*` | `rounded-e-*` | Radius End |
| `rounded-tl-*` | `rounded-ss-*` | Radius Start-Start |
| `rounded-tr-*` | `rounded-se-*` | Radius Start-End |
| `rounded-bl-*` | `rounded-es-*` | Radius End-Start |
| `rounded-br-*` | `rounded-ee-*` | Radius End-End |

> **TW 4.2:** Use `inset-s-*`/`inset-e-*` for inset positioning -- these generate `inset-inline-start`/`inset-inline-end` and are the correct logical property classes.
> `start-*`/`end-*` are deprecated in TW 4.2 (still functional, gradual phase-out). `inline-s-*`/`inline-e-*` NEVER existed -- do NOT use.
> All of `ms-*`/`me-*`/`ps-*`/`pe-*`/`text-start`/`text-end`/`inset-s-*`/`inset-e-*` are valid and required.

### CSS Logical Properties

| Physical (Avoid) | Logical (Use) |
|------------------|---------------|
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-left` | `padding-inline-start` |
| `padding-right` | `padding-inline-end` |
| `left` | `inset-inline-start` |
| `right` | `inset-inline-end` |
| `text-align: left` | `text-align: start` |
| `text-align: right` | `text-align: end` |

### Icon Rules

**MUST Flip (add `rtl:rotate-180`) — HORIZONTAL directional icons only:**
- Arrows: ArrowLeft, ArrowRight, ArrowBack, ArrowForward
- Chevrons: ChevronLeft, ChevronRight
- Navigation: NavigateNext, NavigateBefore
- Undo/Redo icons

**NEVER Flip — vertical icons and non-directional icons:**
- **Vertical chevrons/arrows: ChevronUp, ChevronDown, ArrowUp, ArrowDown** — up/down has no RTL mirror
- Check, X, Plus, Minus
- Search, Settings, Menu, Filter
- Play, Pause, Stop
- Social media icons
- Currency symbols

> **CRITICAL:** `rtl:rotate-180` applies ONLY to icons pointing left/right (horizontal axis). Icons pointing up/down (ChevronUp, ChevronDown, ArrowUp, ArrowDown) are NOT directional in the RTL sense — they MUST NOT receive `rtl:rotate-180`. Flagging vertical icons is a false positive.

```tsx
// Correct: Directional icon with flip
<ChevronRight className="h-5 w-5 rtl:rotate-180" />

// Correct: Non-directional icon without flip
<CheckIcon className="h-5 w-5" />
```

### Special Content

```tsx
// Numbers - Always LTR
<span dir="ltr">₪1,234.56</span>

// Phone numbers - Always LTR
<span dir="ltr">+972-50-123-4567</span>

// English terms in Hebrew - Use bdi
<p>אנחנו משתמשים ב-<bdi dir="ltr">Next.js</bdi></p>

// Form inputs - LTR types
<input type="email" dir="ltr" />
<input type="url" dir="ltr" />
<input type="tel" dir="ltr" />
```

---

## VERIFICATION GATES

### Gate G17: RTL_STRICT
| Attribute | Value |
|-----------|-------|
| Threshold | 0 violations |
| Blocking | YES |
| Check | Zero ml/mr/pl/pr/left/right classes |

```bash
# Verify Gate G17
/rtl audit ./src --ci
# Exit code 0 = PASS, 1 = FAIL
```

### Gate G50: SPACING_SCALE
| Attribute | Value |
|-----------|-------|
| Threshold | 8pt grid |
| Blocking | NO |
| Check | Spacing uses 4,8,12,16,24,32,48,64 |

### Verification Checklist

- [ ] No physical Tailwind classes (ml/mr/pl/pr/left/right)
- [ ] No physical CSS properties (margin-left/right, padding-left/right)
- [ ] Horizontal directional icons (ChevronLeft/Right, ArrowLeft/Right) have rtl:rotate-180 — vertical icons (ChevronUp/Down, ArrowUp/Down) must NOT have rtl:rotate-180
- [ ] Numbers/prices wrapped in dir="ltr"
- [ ] Form inputs (email/url/tel) have dir="ltr"
- [ ] English terms in Hebrew use `<bdi>`
- [ ] Using gap-* instead of space-x-* where possible
- [ ] Root layout has `<html lang="he" dir="rtl">`

---

## CLI USAGE

```bash
# Direct script usage
~/.claude/skills/rtl-validator/rtl-audit.sh ./src

# With options
~/.claude/skills/rtl-validator/rtl-audit.sh ./src --json
~/.claude/skills/rtl-validator/rtl-audit.sh ./src --fix
~/.claude/skills/rtl-validator/rtl-audit.sh ./src --ci
~/.claude/skills/rtl-validator/rtl-audit.sh ./src --verbose

# Exit codes
# 0 = No violations
# 1 = Violations found
# 2 = Script error
```

---

## REFERENCE FILES

| File | Purpose |
|------|---------|
| `references/rtl-css-patterns.md` | CSS logical properties |
| `references/rtl-tailwind-mapping.md` | Tailwind class mappings |
| `references/rtl-validation-rules.md` | Validation rules & CI/CD |
| `references/rtl-fix-examples.md` | Before/after examples |
| `templates/layout.tsx` | Next.js RTL layout |
| `templates/main.dart` | Flutter RTL setup |
| `templates/globals.css` | RTL global styles |

---

## RESOURCES

- [MDN: CSS Logical Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values)
- [Tailwind CSS RTL Support](https://tailwindcss.com/docs/hover-focus-and-other-states#rtl-support)
- [RTL Styling Best Practices](https://rtlstyling.com/)
- [W3C CSS Logical Properties](https://www.w3.org/TR/css-logical-1/)

---

## RESPONSIVE COMPLIANCE (Law #6)

> **APEX Law #6: RESPONSIVE** - Mobile-first, 44x44px touch targets

### Touch Target Requirements

| Element | Minimum Size | Tailwind Classes |
|---------|--------------|------------------|
| Buttons | 44x44px | `min-h-11 min-w-11` |
| Icon buttons | 44x44px | `h-11 w-11` |
| Links (tappable) | 44px height | `min-h-11 py-2` |
| Form inputs | 44px height | `h-11` |
| Checkbox/Radio | 44x44px tap area | `h-11 w-11` or padding |
| List items (tappable) | 44px height | `min-h-11` |

### Responsive Breakpoints

| Breakpoint | Width | Tailwind Prefix | Use Case |
|------------|-------|-----------------|----------|
| Mobile (default) | 0-639px | (none) | Base styles, mobile-first |
| Tablet | 640px+ | `sm:` | Small tablets |
| Tablet landscape | 768px+ | `md:` | Tablets, small laptops |
| Desktop | 1024px+ | `lg:` | Laptops, desktops |
| Large desktop | 1280px+ | `xl:` | Large screens |
| Extra large | 1536px+ | `2xl:` | Ultra-wide displays |

### 8pt Grid Spacing Scale

| Tailwind | Pixels | Use Case |
|----------|--------|----------|
| 1 | 4px | Minimal spacing |
| 2 | 8px | Compact spacing |
| 3 | 12px | Tight spacing |
| 4 | 16px | Default spacing |
| 6 | 24px | Medium spacing |
| 8 | 32px | Section spacing |
| 12 | 48px | Large spacing |
| 16 | 64px | Major section spacing |

### Responsive Patterns

```tsx
// Mobile-first button with proper touch target
<button className="min-h-11 min-w-11 px-4 py-2 sm:px-6 md:px-8">
  Submit
</button>

// Responsive grid layout
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
  {items.map(item => <Card key={item.id} />)}
</div>

// Responsive typography
<h1 className="text-2xl sm:text-3xl lg:text-4xl">Heading</h1>

// Hidden on mobile, visible on desktop
<nav className="hidden md:flex">...</nav>
```

### Gate G51: TOUCH_TARGETS

| Attribute | Value |
|-----------|-------|
| Threshold | 44px minimum |
| Blocking | YES |
| Check | All interactive elements meet 44x44px |

### Gate G52: MOBILE_FIRST

| Attribute | Value |
|-----------|-------|
| Threshold | Base styles target mobile |
| Blocking | NO |
| Check | No desktop-first responsive patterns |

### Responsive Verification Checklist

- [ ] All buttons have `min-h-11 min-w-11`
- [ ] All form inputs have `h-11`
- [ ] All tappable icons have `h-11 w-11`
- [ ] Spacing uses 8pt grid (4,8,12,16,24,32,48,64)
- [ ] Base styles target mobile (no min-width first)
- [ ] Breakpoints follow sm:, md:, lg:, xl:, 2xl: order
- [ ] Touch targets have adequate spacing (no overlap)
- [ ] Text remains readable at all breakpoints

---

## REFLEXION LOOP INTEGRATION

**Actor-Evaluator-Reflect Pattern:**
1. **ACTOR**: Scan codebase for RTL violations
2. **EVALUATOR**: Validate detection accuracy, check false positives
3. **REFLECT**: Analyze missed violations, improve patterns
4. **MEMORY**: Store common violation patterns by project
5. **RETRY**: Re-scan after fixes to ensure compliance (max 3 iterations)

**Reflexion Triggers:**
- Detection confidence < 0.9
- High false positive rate (>5%)
- New CSS framework or pattern encountered
- User reports missed violation

---

## MEMORY MCP INTEGRATION

**RTL Validator Memory Operations:**
- `mcp__plugin_claude-mem_mcp-search__save_observation`: Store violation patterns per project
- `mcp__plugin_claude-mem_mcp-search__search`: Recall project-specific RTL conventions
- `mcp__plugin_claude-mem_mcp-search__save_observation`: Link components to RTL requirements (note: relations not supported; use observation text)

**Memory Patterns:**
- Store custom component RTL requirements
- Track historical violations and fixes per file
- Remember project-specific exception patterns
- Cache framework-specific RTL patterns (Next.js, Flutter, etc.)

---

## CONTEXT7 PROTOCOL

**Research Triggers:**
- Query RTL best practices when encountering new pattern
- Search for CSS logical properties when uncertain
- Look up framework-specific RTL support (Tailwind v4, CSS-in-JS)

**Context7 Queries:**
- `mcp__plugin_context7_context7__query-docs`: "CSS logical properties best practices"
- `mcp__plugin_context7_context7__query-docs`: "Tailwind RTL support 2026"
- `mcp__plugin_context7_context7__query-docs`: "React RTL patterns"
- `mcp__plugin_context7_context7__query-docs`: "Flutter directional widgets"

**Uncertainty Signals:**
- Unknown CSS property encountered
- Framework-specific RTL pattern not in knowledge base
- Ambiguous directional property (could be intentional)
- Custom utility class that might be RTL-safe

---

## 70-GATE VERIFICATION

**RTL Validator Maps to Gates:**
- **Gate 17 (RTL_Strict)**: Zero physical directional properties
- **Gate 50 (Spacing_Scale)**: 8pt grid compliance
- **Gate 51 (Touch_Targets)**: 44x44px minimum for interactive elements
- **Gate 52 (Mobile_First)**: Mobile-first responsive patterns

**Gate Thresholds:**
- RTL violations: 0 tolerance (BLOCKING)
- Spacing deviations: Warning only
- Touch target violations: BLOCKING on mobile
- Mobile-first violations: Warning

---

## SELF-EVOLUTION PROTOCOL

Every 30 days or on `/rtl --self-evolve`:
1. **RESEARCH** latest RTL/CSS logical properties via WebSearch
2. **ANALYZE** self against findings (new Tailwind RTL, CSS features)
3. **GAP REPORT** - identify new RTL validation capabilities needed
4. **UPGRADE** - implement improvements to detection patterns

---

## RESEARCH-FIRST WORKFLOW

| Step | Action | Tool |
|------|--------|------|
| 0.1 | Research latest CSS logical properties patterns | WebSearch |
| 0.2 | Query Tailwind RTL, MDN logical properties docs | Context7 MCP |
| 0.3 | Search past RTL violation patterns | Memory MCP |

---

## UNCERTAINTY DETECTION

| Signal | Threshold | Action |
|--------|-----------|--------|
| Confidence < 0.7 | Low | Trigger RTL research |
| Pattern unfamiliar | True | WebSearch + Context7 for CSS guidance |
| Outdated > 6 months | True | Search for updated Tailwind RTL features |
| New CSS property | True | Research via MDN/W3C docs |

---

<!-- RTL_VALIDATOR v24.7.0 | Updated: 2026-02-19 -->


---

## COMPLETION VERIFICATION GATES

> **v24.7.0** | Mandatory verification before claiming completion

### Pre-Execution Gates
- [ ] User requirements clearly understood
- [ ] Relevant files and context identified
- [ ] Existing patterns and conventions reviewed

### Post-Execution Gates
- [ ] `pnpm run typecheck` passes (0 errors)
- [ ] `pnpm run lint` passes (0 errors)
- [ ] No `any` types introduced
- [ ] No `console.log` statements in production code
- [ ] No TODO/FIXME/HACK comments in new code
- [ ] RTL compliance verified (ms/me not ml/mr)
- [ ] All user requirements fulfilled with evidence
- [ ] Edge cases identified and handled
- [ ] Error handling complete

### Completion Criteria

**NEVER claim "done", "complete", "finished", or "ready" without:**

1. **Running Verification Commands:**
   ```bash
   pnpm run typecheck && pnpm run lint && pnpm run test
   ```

2. **Showing Output as Proof:**
   - Paste actual command output
   - Show pass/fail status

3. **Requirements Checklist:**
   ```
   Requirements from original request:
   1. [requirement 1] - ✅/❌
   2. [requirement 2] - ✅/❌
   ...
   ```

4. **Self-Interrogation:**
   - "Did I miss any implicit requirements?"
   - "What edge cases did I not handle?"
   - "If user asks 'are you sure?', what would I find missing?"

---

<!-- VERIFICATION_GATES v24.7.0 | Updated: 2026-02-19 -->

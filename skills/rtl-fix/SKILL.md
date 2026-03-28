---
name: rtl-fix
description: "Use when user wants to auto-fix RTL violations in code. Replaces physical directional Tailwind classes and CSS properties with logical equivalents (ms/me/ps/pe/inset-s/inset-e). Handles React/Next.js/CSS and Flutter. Also adds rtl:rotate-180 to horizontal directional icons."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# RTL-FIX v24.8.0

> **APEX Law #5 Auto-Fixer**
> **Authority:** LAW_5_GUARDIAN | Zero-Tolerance RTL Compliance
> **Scope:** React, Next.js, CSS, Flutter/Dart

---

## PURPOSE

RTL-FIX **automatically applies** RTL fixes enforcing **APEX Law #5: RTL-FIRST**. Unlike `rtl-validator` (which detects and reports), this skill **mutates source files** to replace every physical directional property with its logical equivalent.

**Core Mission:** Transform a non-RTL-compliant codebase into a fully RTL-safe one in a single pass, with zero manual edits required for mechanical replacements.

---

## EXECUTION PROTOCOL

### Step 1 — Identify Scope
```bash
# Determine files to scan
SCOPE="${1:-./src}"
echo "Fixing RTL violations in: $SCOPE"
```

### Step 2 — Count Violations Before Fix
Run `rtl-validator` scan (or grep) to establish a before-count. Report it.

### Step 3 — Apply All Fixes (ordered by safety)
Apply fixes in this order: safest (prefix-based) → context-dependent (inset) → icon additions.

### Step 4 — Report After-Count
Re-scan and show: `Fixed: N violations | Remaining: M (manual review needed)`.

### Step 5 — Verify
Run `pnpm run typecheck` (web) or `flutter analyze` (Flutter) to confirm no regressions.

---

## COMPLETE FIX MAPPING

### Tailwind Web — Mechanical (100% safe, always apply)

| Pattern | Fix | Notes |
|---------|-----|-------|
| `ml-*` → `ms-*` | Margin inline-start | Any suffix: ml-4, ml-auto, ml-[16px] |
| `mr-*` → `me-*` | Margin inline-end | Any suffix |
| `pl-*` → `ps-*` | Padding inline-start | Any suffix |
| `pr-*` → `pe-*` | Padding inline-end | Any suffix |
| `text-left` → `text-start` | Text align start | Exact match only |
| `text-right` → `text-end` | Text align end | Exact match only |
| `float-left` → `float-start` | Float start | Exact match only |
| `float-right` → `float-end` | Float end | Exact match only |
| `rounded-l-*` → `rounded-s-*` | Border radius start | Any suffix |
| `rounded-r-*` → `rounded-e-*` | Border radius end | Any suffix |
| `rounded-tl-*` → `rounded-ss-*` | Radius start-start | Any suffix |
| `rounded-tr-*` → `rounded-se-*` | Radius start-end | Any suffix |
| `rounded-bl-*` → `rounded-es-*` | Radius end-start | Any suffix |
| `rounded-br-*` → `rounded-ee-*` | Radius end-end | Any suffix |
| `border-l-*` → `border-s-*` | Border inline-start | Any suffix |
| `border-r-*` → `border-e-*` | Border inline-end | Any suffix |

> **TW 4.2 note:** `inset-s-*`/`inset-e-*` are CORRECT for inset positioning. `start-*`/`end-*` are deprecated (still functional). `inline-s-*`/`inline-e-*` NEVER existed — do NOT generate these.

### Tailwind Web — Context-Dependent (requires AI judgment)

| Pattern | Fix | Condition |
|---------|-----|-----------|
| `left-*` (positional) → `inset-s-*` | Inset inline-start | ONLY when used as `position: absolute/fixed/sticky` offset, NOT when `inset-x-*` is RTL-safe |
| `right-*` (positional) → `inset-e-*` | Inset inline-end | Same condition |

> **CRITICAL:** `inset-x-*` maps to `inset-inline` (RTL-safe) — do NOT replace it. Only replace bare `left-N`/`right-N` that are directional position offsets.

### CSS-in-JS / Raw CSS — Mechanical

| Physical | Logical |
|----------|---------|
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-left` | `padding-inline-start` |
| `padding-right` | `padding-inline-end` |
| `left:` (positioned) | `inset-inline-start:` |
| `right:` (positioned) | `inset-inline-end:` |
| `text-align: left` | `text-align: start` |
| `text-align: right` | `text-align: end` |
| `border-left` | `border-inline-start` |
| `border-right` | `border-inline-end` |

### Icon RTL Rotation — Additive Fix

**ADD `rtl:rotate-180`** to HORIZONTAL directional icons that are missing it:

```tsx
// BEFORE (missing flip)
<ChevronRight className="h-5 w-5" />
<ArrowLeft className="h-4 w-4" />

// AFTER (correct)
<ChevronRight className="h-5 w-5 rtl:rotate-180" />
<ArrowLeft className="h-4 w-4 rtl:rotate-180" />
```

**Icons that MUST get `rtl:rotate-180`** (horizontal axis only):
- `ChevronLeft`, `ChevronRight`
- `ArrowLeft`, `ArrowRight`, `ArrowBack`, `ArrowForward`
- `NavigateNext`, `NavigateBefore`

**Icons that MUST NEVER get `rtl:rotate-180`** (vertical or non-directional):
- `ChevronUp`, `ChevronDown` — vertical, no RTL mirror
- `ArrowUp`, `ArrowDown` — vertical, no RTL mirror
- `Check`, `X`, `Plus`, `Minus`, `Search`, `Settings`, `Menu`
- `Play`, `Pause`, `Stop`, social media icons

> **CRITICAL:** Vertical icons (`Up`/`Down`) receiving `rtl:rotate-180` is a **false positive and a bug**. Never add it to vertical icons.

### Flutter/Dart Fixes — Mechanical

| Physical | Logical |
|----------|---------|
| `EdgeInsets.only(left: x)` | `EdgeInsetsDirectional.only(start: x)` |
| `EdgeInsets.only(right: x)` | `EdgeInsetsDirectional.only(end: x)` |
| `EdgeInsets.only(left: x, right: y)` | `EdgeInsetsDirectional.only(start: x, end: y)` |
| `EdgeInsets.fromLTRB(l,t,r,b)` | `EdgeInsetsDirectional.fromSTEB(l,t,r,b)` (or explicit start/end) |
| `Alignment.topLeft` | `AlignmentDirectional.topStart` |
| `Alignment.topRight` | `AlignmentDirectional.topEnd` |
| `Alignment.bottomLeft` | `AlignmentDirectional.bottomStart` |
| `Alignment.bottomRight` | `AlignmentDirectional.bottomEnd` |
| `Alignment.centerLeft` | `AlignmentDirectional.centerStart` |
| `Alignment.centerRight` | `AlignmentDirectional.centerEnd` |
| `Positioned(left: x)` | `PositionedDirectional(start: x)` |
| `Positioned(right: x)` | `PositionedDirectional(end: x)` |
| `BorderRadius.only(topLeft: x)` | `BorderRadiusDirectional.only(topStart: x)` |
| `BorderRadius.only(topRight: x)` | `BorderRadiusDirectional.only(topEnd: x)` |
| `BorderRadius.only(bottomLeft: x)` | `BorderRadiusDirectional.only(bottomStart: x)` |
| `BorderRadius.only(bottomRight: x)` | `BorderRadiusDirectional.only(bottomEnd: x)` |
| `TextAlign.left` | `TextAlign.start` |
| `TextAlign.right` | `TextAlign.end` |
| `CrossAxisAlignment.start` with hardcoded `TextDirection.ltr` | Remove `TextDirection.ltr` hardcode |

---

## EXECUTION SCRIPT

Claude applies these fixes programmatically using Edit/Write tools. For large codebases, the shell script at `~/.claude/scripts/rtl-fix.sh` handles Phase 1 (mechanical sed-based fixes). Claude handles Phase 2 (context-dependent inset fixes) and Phase 3 (icon additions) using Grep + Edit.

### Phase 1 — Shell (mechanical, safe)
```bash
bash ~/.claude/scripts/rtl-fix.sh <project_dir>
```

### Phase 2 — AI-assisted (context-dependent)
For each `left-N`/`right-N` grep hit:
1. Read surrounding context (is it inside `absolute`/`fixed`/`sticky`?)
2. If positional offset → replace with `inset-s-N`/`inset-e-N`
3. If not positional → leave as-is, flag for review

### Phase 3 — Icon additions
```bash
# Find horizontal directional icons missing rtl:rotate-180
grep -rn "ChevronRight\|ChevronLeft\|ArrowLeft\|ArrowRight" src/ \
  --include="*.tsx" --include="*.jsx" | grep -v "rtl:rotate-180"
```
For each hit: add `rtl:rotate-180` to the className, verify it's not a vertical icon.

---

## COMMANDS

### `/rtl-fix [path]`
Auto-fix all RTL violations in `path` (default: `./src`).

```bash
/rtl-fix ./src
/rtl-fix ./src --dry-run        # Preview changes without applying
/rtl-fix ./src --flutter        # Flutter/Dart mode
/rtl-fix ./src --phase=1        # Mechanical fixes only (no icon additions)
/rtl-fix ./src --phase=all      # Full fix including icons (default)
```

### `/rtl-fix --check [path]`
Same as rtl-validator scan — report violations without fixing.

---

## WHAT THIS SKILL DOES NOT FIX

These require human judgment and are flagged but not auto-fixed:
- `inset-x-*` — already RTL-safe (logical), do NOT replace
- `space-x-*` → `gap-*` — functional difference, not mechanical replacement
- Decorative positional elements where physical left/right is intentional (e.g., `left-0 right-0` for full-width)
- Numbers, dates, prices in RTL context — use `<span dir="ltr">` (structural, not class-based)
- Form inputs — `dir="ltr"` must be added as JSX attribute, not class

---

## VERIFICATION

After applying fixes:

```bash
# Web (React/Next.js)
pnpm run typecheck
pnpm run lint

# Flutter
flutter analyze lib/

# Zero remaining violations check
grep -rE "\b(ml-|mr-|pl-|pr-|text-left\b|text-right\b|float-left\b|float-right\b)" src/ \
  --include="*.tsx" --include="*.ts" --include="*.css" | wc -l
# Must be 0
```

**NEVER claim "done" without showing:**
1. Before count (N violations found)
2. After count (0 or M remaining with explanation)
3. `typecheck` output (0 errors)

---

## RELATED SKILLS

| Skill | Purpose |
|-------|---------|
| `rtl-validator` | Scan and detect violations (no mutations) |
| `rtl-fix` | THIS — detect + auto-fix violations |
| `a11y` | Accessibility audit (includes some RTL checks) |

---

## REFERENCE

- RTL mapping rules: `~/.claude/rules/quality/rtl-i18n.md`
- Shell fixer script: `~/.claude/scripts/rtl-fix.sh`
- Autoresearch scripts: `~/.claude/autoresearch/rtl-fixer-web.sh`, `rtl-fixer-flutter.sh`
- Full examples: `~/.claude/skills/rtl-validator/references/rtl-fix-examples.md`

<!-- RTL_FIX v24.8.0 | Updated: 2026-03-28 -->

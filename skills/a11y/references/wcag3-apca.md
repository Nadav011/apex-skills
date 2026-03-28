# WCAG 3.0 Readiness & APCA Contrast

> **v24.6.0** | WCAG 3.0 Editor's Draft (Jan 5, 2026 W3C) | APCA by Myndex
> NOT for production compliance — continue targeting WCAG 2.2 AAA

---

## WCAG 3.0 Overview

### Status & Timeline

| Milestone | Date | Status |
|-----------|------|--------|
| Editor's Draft | Jan 5, 2026 | Current |
| First Public Working Draft | TBD 2026 | Pending |
| Candidate Recommendation | TBD 2027–2028 | Future |
| W3C Recommendation (stable) | ~Late 2029 | Future |

**Production stance:** Do NOT target WCAG 3.0 for compliance. Continue targeting WCAG 2.2 AAA. Begin preparing mappings once CR is published.

### Conformance Model: Bronze / Silver / Gold

Replaces the A / AA / AAA tiered system. Each outcome receives a score from 0–4:

| Score | Label | Meaning |
|-------|-------|---------|
| 0 | Very Poor | Fails outcome entirely |
| 1 | Poor | Minimal partial pass |
| 2 | Adequate | Meets foundational threshold |
| 3 | Good | Meets enhanced threshold |
| 4 | Excellent | Full outcome satisfaction |

**Conformance levels:**

| Level | Requirements |
|-------|-------------|
| Bronze | Scores meeting foundational thresholds — roughly maps to WCAG 2.2 AA |
| Silver | Higher scores across more outcomes — roughly maps to WCAG 2.2 AAA |
| Gold | Highest scores including user research, testing with disabled users |

### Structure Hierarchy

```
Guideline
  └── Requirement
        └── Assertion (testable statement)
              └── Method (technique to satisfy assertion)
```

174 outcomes unveiled in the Jan 5 2026 Editor's Draft, spanning:
- Modern web apps and interactive components
- Streaming media and VR/immersive environments
- Authoring tools (content creation tools must produce accessible output)
- Cognitive, language, and learning disabilities (dedicated COGA section)

### WCAG 2.2 → WCAG 3.0 Transition Path

```
Now:         WCAG 2.2 AA (legal minimum, EAA)
Recommended: WCAG 2.2 AAA (production target)
Prep:        Map existing components to WCAG 3.0 outcomes
             Adopt APCA as supplementary contrast check
             Add user testing with disabled users (required for Gold)
Future CR:   Validate mappings against stable CR
~2029:       Full WCAG 3.0 adoption when W3C Recommendation published
```

---

## APCA (Advanced Perceptual Contrast Algorithm)

### What APCA Is (and Is Not)

| Claim | Reality |
|-------|---------|
| APCA is part of WCAG 3.0 | FALSE — NOT referenced in WCAG 3.0 Jan 2026 draft |
| APCA replaces WCAG 2.x ratios | FALSE — supplementary check only |
| APCA is better for dark mode | TRUE — perceptual model accounts for background luminance |
| APCA is better for colored backgrounds | TRUE — relative luminance formula handles hue |
| APCA should be used in production now | YES — as an additional check alongside WCAG 2.2 ratios |

### APCA Lc Value Thresholds

| Use Case | Minimum Lc | Notes |
|----------|-----------|-------|
| Body text (14–18px normal weight) | Lc 75 | Primary readable content |
| Large text (24px+ or 18px+ bold) | Lc 60 | Headings, display text |
| Non-text UI (icons, borders, focus indicators) | Lc 45 | Interactive controls |
| Placeholder text | Lc 30 | Minimum — prefer Lc 45+ |
| Decorative / disabled | Lc 15 | No requirement |
| Fluent text (small body, footnotes) | Lc 90 | Highest legibility need |

Lc values are unsigned (absolute); polarity matters for text-on-background directionality.

### WCAG 2.x Ratio vs APCA Lc Comparison

| WCAG 2.x Ratio | Typical Lc Equivalent | Context |
|---------------|----------------------|---------|
| 3:1 (AA large, non-text) | Lc 45–50 | Large text, UI components |
| 4.5:1 (AA normal) | Lc 60–65 | Standard body text |
| 7:1 (AAA normal) | Lc 75–80 | High-legibility body text |

Note: Equivalences are approximations — APCA and WCAG 2.x use different algorithms. White text on black is not equivalent to black text on white in APCA (it models human visual system asymmetry).

### APCA Programmatic Check

```typescript
// npm install apca-w3 (0.1.9+)
import { APCAcontrast, sRGBtoY } from 'apca-w3';

interface ColorRGB {
  r: number; // 0–255
  g: number;
  b: number;
}

function getApcaLc(textColor: ColorRGB, bgColor: ColorRGB): number {
  const textY = sRGBtoY([textColor.r, textColor.g, textColor.b]);
  const bgY = sRGBtoY([bgColor.r, bgColor.g, bgColor.b]);
  return APCAcontrast(textY, bgY);
}

function meetsApcaThreshold(
  textColor: ColorRGB,
  bgColor: ColorRGB,
  useCase: 'body' | 'large' | 'ui' | 'placeholder'
): boolean {
  const thresholds = { body: 75, large: 60, ui: 45, placeholder: 30 } as const;
  const lc = Math.abs(getApcaLc(textColor, bgColor));
  return lc >= thresholds[useCase];
}

// Usage
const passes = meetsApcaThreshold(
  { r: 34, g: 34, b: 34 },   // text: #222
  { r: 255, g: 255, b: 255 }, // bg: #fff
  'body'
);
// → true (Lc ~106)
```

### APCA + WCAG 2.2 Dual Check Pattern

```typescript
import { APCAcontrast, sRGBtoY } from 'apca-w3';

interface ContrastResult {
  wcag2Ratio: number;
  apcaLc: number;
  wcag2Passes: boolean; // AA: 4.5:1, AAA: 7:1
  apcaPasses: boolean;  // body: Lc 75
}

function hexToRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.replace('#', ''), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function relativeLuminance(r: number, g: number, b: number): number {
  const [rs, gs, bs] = [r, g, b].map((c) => {
    const s = c / 255;
    return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}

function checkContrast(textHex: string, bgHex: string): ContrastResult {
  const textRgb = hexToRgb(textHex);
  const bgRgb = hexToRgb(bgHex);

  const L1 = relativeLuminance(...textRgb);
  const L2 = relativeLuminance(...bgRgb);
  const lighter = Math.max(L1, L2);
  const darker = Math.min(L1, L2);
  const wcag2Ratio = (lighter + 0.05) / (darker + 0.05);

  const textY = sRGBtoY(textRgb);
  const bgY = sRGBtoY(bgRgb);
  const apcaLc = Math.abs(APCAcontrast(textY, bgY));

  return {
    wcag2Ratio,
    apcaLc,
    wcag2Passes: wcag2Ratio >= 4.5,
    apcaPasses: apcaLc >= 75,
  };
}
```

### Tools

| Tool | URL | Use |
|------|-----|-----|
| APCA Contrast Calculator | apcacontrast.com | Manual check, visual comparison |
| Myndex Contrast Checker | myndex.com/APCA/ | Reference implementation |
| polished-css/apca | npm install @polished/apca | Programmatic (browser only) |
| apca-w3 | npm install apca-w3 | Node.js + browser, W3C reference |
| Colour Contrast Analyser | paciellogroup.com | Desktop, shows both APCA + WCAG 2.x |
| Sa11y browser extension | sa11y.netlify.app | In-page APCA overlay |

### When to Use APCA

```
DO:   Use APCA as a supplementary check for dark-mode color palettes
DO:   Use APCA when building design tokens to catch WCAG 2.x false-passes
DO:   Include both WCAG 2.2 ratio and APCA Lc in design system contrast docs
DO:   Fail a color pair if EITHER WCAG 2.x OR APCA fails at target threshold
WAIT: Do not replace WCAG 2.2 ratios with APCA for compliance reporting
WAIT: Do not cite APCA in accessibility conformance reports (ACRs/VPATs)
```

---

## Cross-References

- WCAG 2.2 criteria table: `~/.claude/skills/a11y/SKILL.md`
- Media query patterns (dark mode contrast): `references/motion-contrast-modes.md`
- Cognitive accessibility (COGA in WCAG 3.0): `references/cognitive-a11y.md`
- Testing contrast with Playwright: `references/a11y-testing.md`

---

<!-- WCAG3_APCA v24.6.0 | Updated: 2026-02-24 | WCAG 3.0 ED Jan 5 2026 | APCA Myndex supplementary -->

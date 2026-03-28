# Dev.to Article Outline

**Title:** How I maintain 18 production projects without manual CI debugging (open-source AI skill system)

**Tags:** claudeai, productivity, opensource, devops

**Cover image:** Terminal dashboard screenshot showing APEX Command Center with all 18 projects green

---

## Outline

### Hook (200 words)
- The moment I realized I hadn't manually debugged a CI failure in 3 weeks
- Not because nothing broke — things break constantly
- Because the system fixed them before I noticed

### Section 1: The Problem — Solo Dev Maintenance Hell (300 words)
- 18 projects. React, Next.js, Flutter, Python.
- Each has: CI, linting, testing, security scanning, bundle monitoring, accessibility
- The math: 18 projects × 2 hours/week maintenance = 36 hours/week just keeping things alive
- That's not feature work. That's just staying in place.
- The alternative: let things rot. I watched that happen to 3 projects in 2024.

### Section 2: The Architecture — APEX (400 words)
- Skills layer (Claude Code) — 86 skills total, 15 open-sourced
- Hydra v2 (orchestrator) — routes tasks to best AI provider based on Bayesian scores
- Self-healing CI — detects failures, runs skills, opens draft PRs
- Diagram: Task → Hydra routes → Provider executes → Skills verify → PR opened

**Code snippet:** Example skill invocation and output

### Section 3: The 15 Open-Source Skills (600 words)
Cover the 5 most impactful with real numbers:

**1. /rtl-fix — The RTL enforcement nobody built**
- Problem: Tailwind 4.2 broke all `start-`/`end-` classes, replaced with `inset-s-`/`inset-e-`
- Problem 2: AI models hallucinate `inline-s-*` classes that never existed (found 91 instances in one project)
- What the skill does: audits entire codebase, fixes all violations, handles Flutter + Next.js + Tailwind
- Numbers: fixed 60+ files in Shifts project in one run

**2. /bundle-analyze — Real bundle savings**
- Recharts `import * as RechartsPrimitive` blocks ALL tree-shaking → 312KB extra
- Sentry 270KB stub replacement pattern
- How the skill finds and fixes these automatically

**3. /owasp-security — RLS audit that catches what humans miss**
- The `auth.uid() IS NULL` bypass that was active in 3 projects for months
- `raw_user_meta_data` role privilege escalation (any user can sign up as admin)
- How Supabase's auth schema prevents inline queries in RLS

**4. /a11y — WCAG 2.2 for EU compliance**
- EAA enforcement: June 28, 2025. €100K max penalty.
- 4 new WCAG 2.2 criteria: Focus Appearance, Target Size 24px min, Accessible Auth
- Flutter: `accessibility_tools ^2.8.0` runtime + `flutter_a11y_lints` static

**5. /test-gen — Vitest 4 patterns that actually work**
- The `vi.hoisted()` requirement for mock variables
- 3-trap Proxy for icon libraries
- Pool rework migration (nested `poolOptions` → top-level, causes deadlocks)

### Section 4: The Multi-Model Reality (400 words)
- 6 months of production data on 4 providers
- Bayesian scores after 200+ tasks (table format)
- Surprising findings:
  - Codex GPT-5.4 genuinely better at security reasoning than Claude
  - Gemini Reasoning Overload: thinkingBudget > 2048 burns quota silently
  - MiniMax 50-concurrent batch: 100% success rate, 2x faster than regular model
  - Kimi CSS fidelity: best for playground-to-implementation

### Section 5: Installing and Using the Skills (300 words)
```bash
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```
- Walk through first use of /rtl-fix
- Walk through first use of /owasp-security
- How to chain skills in a workflow

### Section 6: What's Coming (200 words)
- Open-sourcing Hydra v2 (orchestrator) — timeline TBD
- APEX Dashboard (already built, CF Pages)
- Community skill submissions

### CTA
- GitHub: https://github.com/Nadav011/apex-skills
- Star if useful, PRs welcome for new skills
- Questions in comments — especially about RTL or multi-model orchestration

---

## Notes for writing
- Use concrete numbers throughout (312KB, 91 instances, 18 projects, $300/month)
- Avoid "revolutionary" / "game-changing" language — let the numbers speak
- Include real code snippets from actual fixes
- Screenshots: terminal dashboard, skill output, before/after bundle sizes
- Target length: 2,000-2,500 words (Dev.to sweet spot for technical content)

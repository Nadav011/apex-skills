# Reddit r/ClaudeAI Post

**Title:** I open-sourced 15 Claude Code skills that keep 18 production projects on autopilot

---

**Body:**

Hey r/ClaudeAI,

I've been building on top of Claude Code for about 6 months now, and I finally feel like the system is solid enough to share publicly.

**What I built:** APEX — a personal AI engineering system. I maintain 18 production apps (React, Next.js, Flutter, Python) and since March 2026 I have not manually debugged a single CI failure. The system catches regressions, opens draft PRs with fixes, and enforces code quality automatically.

I'm open-sourcing 15 of the skills today: https://github.com/Nadav011/apex-skills

**The skills cover:**

- `/rtl-fix` — enforces RTL (right-to-left) layout for Hebrew/Arabic apps across Tailwind, Flutter, and Next.js. This is the only production-grade RTL toolkit I know of.
- `/owasp-security` — automated OWASP Top 10 audit with Supabase RLS checks
- `/bundle-analyze` — finds and fixes bundle bloat (saved 312KB by fixing one Recharts import pattern)
- `/a11y` — WCAG 2.2 AA audit, now required for the EU market since June 2025
- `/test-gen` — generates Vitest 4 + Playwright tests with proper mocking patterns
- And 10 more (perf, edge-case hunting, code review, schema, deployment)

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```

**What makes these different from typical Claude prompts:**

1. They're battle-tested on real production codebases — not toy examples
2. RTL skills are unique — I couldn't find anything else that handles Tailwind 4.2 logical properties + Flutter DirectionalPadding + Next.js in one place
3. Each skill has a verification gate — it doesn't just make changes, it checks them

**The bigger system (not open-sourced yet):**
- Hydra v2: LangGraph orchestrator that routes tasks to Claude, Codex, Gemini, or MiniMax based on Bayesian scores
- Self-healing CI: GitHub Actions that detect failures, run relevant skills, and open draft PRs

Happy to answer questions about Claude Code architecture, multi-model orchestration, or the RTL patterns specifically.

---

*Links: [GitHub](https://github.com/Nadav011/apex-skills) | Install: one curl command above*

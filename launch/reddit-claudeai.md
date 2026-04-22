# Reddit r/ClaudeAI Post

**Title:** I open-sourced 17 Claude Code skills that block AI from writing bad code — RTL bugs, `: any`, eval(), and more

---

**Body:**

Hey r/ClaudeAI,

After two years of running a personal enforcement system across 18 production apps, I finally distilled it down to 17 portable skills worth sharing publicly.

**The problem they solve:** Claude Code (and most AI coding assistants) will happily write code that passes a quick glance but fails in production — RTL-unsafe CSS like `ml-4` instead of `ms-4`, TypeScript shortcuts with `: any`, insecure `eval()` calls, or even attempt to push directly to main. These skills block all of that at the source.

**Install in one line:**
```bash
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```

Works with Claude Code, Gemini CLI, Kiro, and Cursor.

**The 17 skills cover:**

- `/rtl-fix` — enforces RTL layout for Hebrew/Arabic apps (Tailwind logical properties, Flutter DirectionalPadding, Next.js). The only production-grade RTL toolkit I know of.
- `/owasp-security` — OWASP Top 10 audit with Supabase RLS checks
- `/bundle-analyze` — finds and fixes bundle bloat (saved 312KB once by catching a single Recharts import pattern)
- `/a11y` — WCAG 2.2 AA audit (required for EU market since June 2025)
- `/test-gen` — generates Vitest 4 + Playwright tests with proper mocking patterns
- `/no-any` — blocks TypeScript `: any` shortcuts and suggests correct types
- `/block-main-push` — prevents direct pushes to main/master, enforces branch workflow
- And 10 more across perf, edge-case hunting, code review, schema validation, and deployment

**What makes these different:**

1. Battle-tested on 18 real production codebases — not toy examples
2. Cross-platform: same skill works in Claude Code, Gemini CLI, Kiro, and Cursor
3. Each skill has a verification gate — it doesn't just make changes, it confirms them
4. RTL support is unique — I've never found anything else handling Tailwind 4.2 + Flutter + Next.js together

**The full system (193 skills, 70/70 quality score):** nadavc.ai/apex

Happy to answer questions about Claude Code skill architecture, cross-platform compatibility, or the RTL patterns.

---

*GitHub: https://github.com/Nadav011/apex-skills*

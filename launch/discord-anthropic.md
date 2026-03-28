# Anthropic Discord Post

**Channel:** #show-and-tell (or #claude-code)

---

Hey everyone! Just open-sourced something I've been building for 6 months.

**APEX Skills** — 15 production-grade Claude Code skills for maintaining real projects at scale.

https://github.com/Nadav011/apex-skills

**What's included:**

`/rtl-fix` — RTL enforcement for Hebrew/Arabic apps. Tailwind 4.2 logical properties, Flutter DirectionalPadding, Next.js patterns. Catches the 3 hallucinated Tailwind classes (`inline-s-*`) that don't exist.

`/owasp-security` — OWASP Top 10 + Supabase RLS audit. Catches auth bypass patterns including the `auth.uid() IS NULL` escape and `raw_user_meta_data` privilege escalation.

`/bundle-analyze` — Finds real bundle savings. Found 312KB from one Recharts import pattern, 270KB from Sentry stub pattern.

`/a11y` — WCAG 2.2 AA audit. Matters now — EU Accessibility Act enforcement started June 28, 2025.

`/test-gen` — Vitest 4 + Playwright tests with correct mock patterns. Handles the `vi.hoisted()` requirement, 3-trap Proxy for lucide-react, `../` depth fix from `__tests__/`.

`/edge-case-hunter`, `/perf`, `/schema`, `/secure`, `/deploy`, and 5 more.

**Install:**
```
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```

The system behind it (Hydra v2 — LangGraph orchestrator routing between Claude, Codex, Gemini, MiniMax) isn't open-source yet, but the skills work standalone with Claude Code.

Happy to answer questions! The RTL stuff especially — there's basically nothing else out there for production Hebrew/Arabic web + mobile.

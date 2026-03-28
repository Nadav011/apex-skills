# Twitter/X Thread — 10 Tweets

**Hook tweet (1/10):**
> I maintain 18 production apps as a solo dev.
>
> Since March 2026, I haven't manually debugged a single CI failure.
>
> Here's the system I built — and I'm open-sourcing part of it today 🧵
>
> [SCREENSHOT: APEX terminal dashboard showing 18 projects, all green]

---

**Tweet 2/10 — The problem:**
> The math on solo dev maintenance is brutal:
>
> 18 projects × 2hr/week = 36hr/week just keeping things alive
>
> That's not feature work. That's staying in place.
>
> So I built a system to handle it automatically.

---

**Tweet 3/10 — Architecture overview:**
> APEX has 3 layers:
>
> 1. Skills (Claude Code) — 86 total, 15 open-sourced today
> 2. Hydra v2 — AI orchestrator routing tasks to best provider via Bayesian scores
> 3. Self-healing CI — detects failures, runs skills, opens draft PRs
>
> [SCREENSHOT: Architecture diagram / Hydra routing diagram]

---

**Tweet 4/10 — RTL skill (most unique):**
> The skill I'm most proud of: /rtl-fix
>
> Hebrew/Arabic dev is invisible to most tools. So I built the only production RTL toolkit I know of:
>
> • Tailwind 4.2 logical properties (inset-s-/inset-e-, NOT start-/end-)
> • Flutter DirectionalPadding
> • Catches 3 hallucinated Tailwind classes that AI models invent (inline-s-* — never existed)
>
> Fixed 91 phantom classes in one project.
>
> [SCREENSHOT: rtl-fix output showing violations found and fixed]

---

**Tweet 5/10 — Security skill:**
> /owasp-security caught this in 3 of my projects:
>
> ```sql
> USING (auth.uid() IS NULL OR user_id = auth.uid())
> ```
>
> That `IS NULL` check lets EVERY unauthenticated request through.
>
> It was live in production. For months.
>
> The skill scans all RLS policies and flags this pattern automatically.
>
> [SCREENSHOT: security skill output with RLS violations]

---

**Tweet 6/10 — Bundle skill:**
> /bundle-analyze real numbers:
>
> • Recharts `import * as RechartsPrimitive` → blocks all tree-shaking → +312KB
> • Sentry full SDK → replace with 2KB fetch stub → -270KB
>
> One pattern. One import line. 312KB.
>
> [SCREENSHOT: before/after bundle size chart]

---

**Tweet 7/10 — Multi-model reality:**
> 6 months of routing tasks between Claude, Codex, Gemini, MiniMax.
>
> What surprised me:
>
> • Codex GPT-5.4 is genuinely better at security reasoning than Claude
> • Gemini "Reasoning Overload" — thinkingBudget > 2048 burns quota on invisible tokens silently
> • MiniMax 50-concurrent batch: 100% success, 2x faster than regular model
>
> The Bayesian router learned these priors automatically over ~200 tasks.

---

**Tweet 8/10 — Self-healing CI:**
> The self-healing CI flow:
>
> 1. CI fails on push
> 2. Webhook fires → Hydra receives task
> 3. Hydra routes to best provider for that failure type
> 4. Provider runs, skill verifies output
> 5. Draft PR opened with fix
> 6. I review in 2 minutes instead of debugging for 2 hours
>
> [SCREENSHOT: GitHub PR opened automatically by the system]

---

**Tweet 9/10 — Install:**
> Open-sourcing 15 of the skills today.
>
> Install:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
> ```
>
> Works with any Claude Code setup. No config required.
>
> Includes: RTL, security, bundle analysis, a11y, test generation, performance, schema, deployment, and more.
>
> github.com/Nadav011/apex-skills

---

**Tweet 10/10 — CTA:**
> If you're a solo dev maintaining multiple projects, this is the biggest force multiplier I've found.
>
> Cost: ~$300/month infra
> Saves: ~$3,200/month debugging time (my estimate)
>
> Star the repo if useful ⭐
> Questions in replies — especially about RTL or multi-model orchestration.
>
> github.com/Nadav011/apex-skills

---

## Thread Notes
- Post tweets 1-3 back to back (first 3 set the hook)
- Space remaining tweets 30-60 min apart for algorithmic boost
- Reply to tweet 1 with the thread continuation (not quote-tweet)
- Pin tweet 1 to profile during launch week
- Screenshots needed: dashboard, rtl-fix output, security scan output, bundle chart, auto-PR example

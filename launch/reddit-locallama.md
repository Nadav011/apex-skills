# Reddit r/LocalLLaMA Post

**Title:** Multi-model AI orchestration for solo devs: routing tasks between Claude, Codex, Gemini, and MiniMax with Bayesian scoring — open-sourcing 15 skills

---

**Body:**

Been lurking here for a while. Built something I think this community will appreciate.

**TL;DR:** I built a production AI engineering system that routes coding tasks to different LLMs based on which model has the best empirical track record for that task type. Open-sourcing the Claude Code skills layer today.

---

**The Architecture (Hydra v2)**

```
Task arrives → Hydra routes to best provider
  ├── Claude Opus 4.6    → code review, architecture decisions
  ├── Codex (GPT-5.4)    → security audits (xhigh reasoning, sandbox)
  ├── Gemini 3.1 Pro     → 2M context analysis, large codebase work
  ├── Kimi               → UI/CSS work
  └── MiniMax M2.7       → batch test generation (50 concurrent)
```

Routing uses Beta distribution (Bayesian scoring) — each provider has win/loss counts per task category. After ~50 tasks, the system has strong priors. Codex currently wins security at 0.82, MiniMax wins test batch at 0.91.

**Stack:**
- LangGraph Python (StateGraph, SqliteSaver for crash recovery)
- LanceDB for cognitive memory (scope-based semantic recall with recency decay)
- FastAPI wrapper for HTTP dispatch
- SIGTERM → graceful shutdown → resume with `--resume --task-id`

**What I'm open-sourcing:** 15 Claude Code skills that are the "last mile" — they run after Hydra routes and executes a task, to verify and enforce quality.

GitHub: https://github.com/Nadav011/apex-skills

**Skills of note for this community:**

`/rtl-fix` — The only production RTL (right-to-left) enforcement toolkit for Tailwind 4.2 + Flutter. Tailwind removed `start-`/`end-` in 4.2, replaced with `inset-s-`/`inset-e-`. There are also 3 classes that AI models hallucinate (`inline-s-*`) that never existed. This skill catches all of it.

`/bundle-analyze` — Has found 200-312KB savings in multiple projects by catching: Recharts `import *` that blocks tree-shaking, Sentry 270KB that can be replaced with a 2KB fetch reporter stub, Turbopack's hardcoded 109KB polyfill floor.

`/owasp-security` — Supabase RLS audit that catches: `auth.uid() IS NULL` bypass, `raw_user_meta_data` role privilege escalation, `SECURITY DEFINER` missing on role helpers.

**Numbers:**
- 18 production projects maintained
- 0 manual CI debugging since March 2026
- ~$300/month infra cost
- Estimated ~$3,200/month saved in debugging time

**Multi-model observations after 6 months of production use:**

- Claude Opus: best for architecture decisions and code review. Worst for batch repetitive work.
- Codex GPT-5.4: genuinely the best for security reasoning. `xhigh` effort finds things Claude misses.
- Gemini 3.1 Pro with 2M context: only real option for whole-codebase analysis. thinkingBudget above 2048 causes Reasoning Overload (the model burns quota on invisible tokens before responding — drop to 1024).
- MiniMax M2.7-highspeed: 50 concurrent test file generation. Instruction following is ~65%, needs explicit format prompts.
- Kimi: best at CSS fidelity. Needs `--quiet --yolo -p` flags (stdin pipe causes it to exit immediately).

Questions welcome on the orchestration, Bayesian routing, or any of the technical patterns.

---

*GitHub: https://github.com/Nadav011/apex-skills*
*Install: `curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash`*

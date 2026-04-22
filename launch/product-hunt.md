# Product Hunt Launch

**Tagline (under 60 chars):**
17 skills that stop your AI from writing bad code

---

**Description:**

**Paragraph 1 — What it is:**
APEX Skills is a collection of 17 portable enforcement skills for AI coding assistants. They block the class of mistakes that AI tools make confidently: RTL-unsafe CSS (`ml-4` instead of `ms-4` in Hebrew/Arabic apps), TypeScript `: any` shortcuts, insecure `eval()` calls, direct pushes to main, and more. The skills work as guardrails — installed once, enforced automatically every time your AI writes code.

**Paragraph 2 — Who it's for:**
Built for developers who use Claude Code, Gemini CLI, Kiro, or Cursor to ship real production code — especially those building for RTL markets (Hebrew, Arabic, Urdu, Farsi) or working in regulated industries where security and accessibility aren't optional. If you've ever had Claude confidently write `margin-left` in a Hebrew app, or accepted a `: any` just to get past a TypeScript error, these skills are for you.

**Paragraph 3 — How to install:**
One curl command installs all 17 skills and configures them for your active AI tools:
```
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```
No dependencies, no config files to edit by hand. The skills self-register with Claude Code, Gemini CLI, Kiro, and Cursor. The full 193-skill system that powers 18 production projects is documented at nadavc.ai/apex.

---

**What makes it different:**

- **Production-tested, not toy examples** — evolved over two years across 18 real apps (React, Next.js, Flutter, Python), reaching a 70/70 automated quality score
- **Cross-platform** — the same skill file works in Claude Code, Gemini CLI, Kiro, and Cursor without modification
- **RTL-first** — the only toolkit that enforces RTL layout across Tailwind 4.2 logical properties, Flutter DirectionalPadding, and Next.js simultaneously
- **Verification gates** — skills don't just apply changes, they confirm correctness before finishing
- **Open source, MIT licensed** — fork, extend, and contribute back

---

**Links:**
- GitHub: https://github.com/Nadav011/apex-skills
- Full system docs: https://nadavc.ai/apex
- RTL Dev Kit: https://github.com/Nadav011/rtl-first-dev-kit

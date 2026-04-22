# APEX Skills

Your AI assistant just wrote `ml-4` in your RTL app. Again.

You told it about RTL last week. You fixed it in code review. It doesn't remember. It doesn't care. It will do it again the next time you open a new chat.

This is a collection of portable AI skills — structured instruction files that make your AI coding assistant enforce real engineering standards, session after session, without you repeating yourself.

**5-second install. Zero config. Works with any codebase.**

```bash
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```

One install. Works on Claude Code, Gemini CLI, Kiro, Cursor, and Codex.

---

## The Problem

AI assistants write code that looks right. It compiles. It passes a quick review. Then it breaks in Arabic, leaks a secret, ignores your TypeScript config, or ships a 400KB first load.

Not because the AI is bad — because it has no persistent standards. Every session starts from scratch.

---

## Before / After

### RTL — Physical classes break in Arabic and Hebrew

```tsx
// What your AI writes (breaks in RTL locales)
<div className="ml-4 pl-6 text-left">
  <ChevronRight className="h-5 w-5" />
</div>

// What it should write (works in all directions)
<div className="ms-4 ps-6 text-start">
  <ChevronRight className="h-5 w-5 rtl:rotate-180" />
</div>
```

### TypeScript — `: any` disables your type checker

```typescript
// What your AI writes (the type checker is now blind here)
async function processUser(user: any) {
  return user.name.toUpperCase();
}

// What it should write (type-safe, crashes prevented at compile time)
async function processUser(user: unknown): Promise<string> {
  if (!isUser(user)) throw new TypeError('Invalid user shape');
  return user.name.toUpperCase();
}
```

### Security — `eval()` on user input is a code injection

```typescript
// What your AI writes (remote code execution vulnerability)
const result = eval(userProvidedExpression);

// What it should write (safe, sandboxed evaluation)
const result = new Function('x', `return ${sanitizedExpression}`)(inputValue);
// Or better: use a purpose-built parser for your domain
```

### Git — Uninformative commits break `git bisect` and changelogs

```bash
# What your AI writes
git commit -m "wip"
git commit -m "fixes"
git commit -m "updated stuff"

# What it should write
git commit -m "fix(auth): prevent double-submit on slow connections"
git commit -m "feat(dashboard): add real-time activity feed"
```

---

## How It Works

Three steps, nothing to configure:

```
1. Install     →  curl ... | bash  copies 28 SKILL.md files to your AI's context directory
2. You type    →  "review this component for RTL safety"  (or any trigger keyword)
3. AI loads    →  the matching skill enforces its rules for the entire session
```

Each skill is a `SKILL.md` file in a named folder. The AI reads it as context before writing code.

```
skills/
  rtl-fix/
    SKILL.md     ← the rules, with before/after examples
  typescript-strict/
    SKILL.md
  git-discipline/
    SKILL.md
```

A skill file has a YAML frontmatter block that declares its name, description, and trigger words:

```markdown
---
name: typescript-strict
description: TypeScript strict-mode rules — eliminate any, enforce branded types.
triggers:
  - typescript
  - any type
  - type safety
---

# TypeScript Strict Mode

## Rule 1 — Never `: any`
...
```

When you mention a trigger word in your prompt, the AI loads the relevant skill. The rules apply for the entire session.

There are no daemons, no background processes, no cloud services. The skill files are just Markdown.

---

## What's Included (28 Skills)

| Category | Skill | What It Enforces |
|----------|-------|-----------------|
| **RTL** | `rtl-fix` | Replaces `ml-*` → `ms-*`, `pl-*` → `ps-*`, adds `rtl:rotate-180` to directional icons |
| **RTL** | `rtl-validator` | Scans for physical directional classes, reports all violations |
| **Security** | `owasp-security` | OWASP Top 10:2025, ASVS 5.0, blocks `eval()`, SQL injection, XSS |
| **Security** | `security-rules` | Blocks hardcoded credentials, enforces env var usage |
| **Security** | `env-validation` | Validates all env vars at startup via Zod, t3-env createEnv pattern |
| **TypeScript** | `typescript-strict` | Bans `: any`, enforces branded IDs, strict tsconfig, Zod at boundaries |
| **TypeScript** | `zod-patterns` | Zod 4 schemas, safeParse, runtime type validation |
| **Testing** | `testing-rules` | Test pyramid, Vitest 4, Playwright MCP, coverage strategy |
| **Testing** | `edge-case-hunter` | Probes 12 failure dimensions: empty states, race conditions, overflow |
| **Testing** | `adversarial-review` | Attacks your code before production does |
| **Git** | `git-discipline` | Conventional commits, branch naming, no direct main pushes |
| **Git** | `commit` | Full OMEGA flow: purge → audit → atomic → security → release |
| **Framework** | `react-patterns` | Server vs Client decision tree, error boundaries, Suspense, custom hooks |
| **Framework** | `nextjs-patterns` | File conventions, Server Actions with Zod, image/font optimization |
| **Framework** | `flutter-rules` | Flutter directional APIs, `EdgeInsetsDirectional`, `AlignmentDirectional` |
| **Framework** | `pwa-expert` | Manifest, caching strategies, push notifications, auto-update patterns |
| **Architecture** | `api-design` | REST/RPC conventions, versioning, error shapes, pagination |
| **Architecture** | `backend-rules` | Query safety, connection pooling, error handling, structured logging |
| **Architecture** | `frontend-rules` | Component architecture, CSS logical properties, design tokens |
| **Architecture** | `error-handling` | Error boundary hierarchy, typed errors, user-facing messages |
| **Architecture** | `logging-patterns` | Structured JSON logging, PII scrubbing, log levels |
| **Quality** | `a11y` | WCAG 2.2 AA, touch targets, screen reader patterns |
| **Quality** | `apex-guards` | 8-gate verification: typecheck, lint, tests, secrets, RTL, bundle, types, touch targets |
| **Quality** | `bundle-analyze` | Tracks First Load JS, flags pages over 100KB |
| **Quality** | `perf-expert` | Core Web Vitals, React rendering, bundle splitting |
| **Quality** | `code-review-checklist` | Security, correctness, performance, maintainability checklist for every PR |
| **Database** | `database-patterns` | N+1 prevention, indexing, connection pooling, migration safety, Prisma/Drizzle |
| **DevOps** | `docker-best-practices` | Multi-stage builds, non-root users, secrets management, health checks |

---

## Platform Support

| Platform | Status | Install Path | Notes |
|----------|--------|-------------|-------|
| Claude Code | Full | `~/.claude/skills/` | Native SKILL.md support |
| Gemini CLI | Full | `~/.gemini/skills/` | Reads SKILL.md as context |
| Kiro | Full | `~/.kiro/agents/` | Spec-compatible format |
| Codex | Full | `~/.codex/skills/` | Reads markdown context files |
| Cursor | Partial | `.cursor/rules/` (project) | Works as `.cursorrules` content |

The installer auto-detects your platform and copies to the right directory. To target a specific platform:

```bash
bash install.sh --platform gemini
bash install.sh --platform kiro
bash install.sh --platform cursor
```

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```

The installer copies skill files into your AI assistant's context directory and prints exactly what was installed.

To install a single skill manually:

```bash
# Clone the repo
git clone https://github.com/Nadav011/apex-skills.git

# Copy one skill
cp -r apex-skills/skills/typescript-strict ~/.claude/skills/
```

---

## Why This Exists

This is the public, portable core of a 193-skill private system built across 18 production projects and 528,000+ lines of code. Every skill in this repo has been extracted from a real bug that made it into code review — or worse, production.

The RTL rules come from a Hebrew/Arabic SaaS where `ml-4` broke layouts for 40% of users.

The TypeScript rules come from a production incident where `: any` hid a null pointer that took four hours to trace.

The git rules come from a `git bisect` session that took 45 minutes because commit messages were `"stuff"` and `"wip"`.

You don't need 193 skills to start. These 28 cover the highest-frequency bugs that AI assistants introduce.

---

## Contributing

To add a skill:

1. Copy `skills/portable-skill-template.md` as your starting point — it has the required frontmatter fields and the mandatory security guardrail comment.
2. Create `skills/<your-skill-name>/SKILL.md` in a fork of this repo.
3. Add your skill to the table in this README.
4. Open a PR with a description of what the skill enforces and which project(s) you run it on.

Requirements before submitting:
- The skill must prevent a real, high-frequency bug — not a hypothetical
- Must work on Claude Code, Gemini CLI, Kiro, and Cursor without modification
- No platform-specific frontmatter fields (`allowed-tools`, `context:`, `effort:`, `model:`, `agent:`)
- Must include at least one before/after code example
- Must include the security guardrail comment immediately after the frontmatter closing `---`

Full details: [CONTRIBUTING.md](CONTRIBUTING.md) | Skill template: [skills/portable-skill-template.md](skills/portable-skill-template.md)

---

## Want the Full System?

The complete 193-skill pack includes deep rules for:
- Full authentication flows (NextAuth, Supabase Auth, Clerk)
- Database patterns (Prisma, DrizzleORM, query optimization)
- CI/CD enforcement (GitHub Actions, bundle budgets, deployment gates)
- Mobile (React Native, Flutter — directional APIs, platform conventions)
- Advanced security (OWASP ASVS 5.0, CSP, rate limiting)
- And 170+ more

**[Get the full APEX system at nadavc.ai/apex](https://nadavc.ai/apex)**

---

## License

MIT. Use freely, attribution appreciated.

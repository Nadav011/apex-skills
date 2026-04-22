# APEX Skills

Your AI assistant just wrote `ml-4` in your RTL app. Again.

You told it about RTL last week. You fixed it in code review. It doesn't remember. It doesn't care. It will do it again the next time you open a new chat.

This is a collection of portable AI skills — structured instruction files that make your AI coding assistant enforce real engineering standards, session after session, without you repeating yourself.

One install. Works on Claude Code, Gemini CLI, Kiro, Cursor, and Codex.

```bash
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```

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

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Claude Code | ✅ Full | Native SKILL.md support |
| Gemini CLI | ✅ Full | Reads SKILL.md as context |
| Kiro | ✅ Full | Spec-compatible format |
| Cursor | ⚠️ Partial | Works as `.cursorrules` content |
| Codex | ✅ Full | Reads markdown context files |

---

## Skills Included (22)

| Skill | Triggers | What It Enforces |
|-------|----------|-----------------|
| `rtl-fix` | RTL, direction, tailwind | Replaces `ml-*` → `ms-*`, `pl-*` → `ps-*`, adds `rtl:rotate-180` to directional icons |
| `rtl-validator` | RTL audit, check direction | Scans for physical directional classes, reports violations |
| `typescript-strict` | typescript, any type, type safety | Bans `: any`, enforces branded IDs, strict tsconfig, Zod at boundaries |
| `react-patterns` | react, component, hook, use client | Server vs Client decision tree, error boundaries, Suspense, custom hooks |
| `nextjs-patterns` | next.js, app router, server action | File conventions, Server Actions with Zod, image/font optimization |
| `git-discipline` | git, commit, branch, pr | Conventional commits, branch naming, no direct main pushes |
| `env-validation` | env, process.env, dotenv | Validates all env vars at startup via Zod, t3-env createEnv pattern |
| `owasp-security` | security, auth, input | OWASP Top 10:2025, ASVS 5.0, blocks `eval()`, SQL injection, XSS |
| `security-rules` | secret, token, api key | Blocks hardcoded credentials, enforces env var usage |
| `testing-rules` | test, vitest, playwright | Test pyramid, Vitest 4, Playwright MCP, coverage strategy |
| `zod-patterns` | zod, validation, schema | Zod 4 schemas, safeParse, runtime type validation |
| `a11y` | accessibility, a11y, aria | WCAG 2.2 AA, touch targets, screen reader patterns |
| `apex-guards` | quality gate, pre-commit | 8-gate verification: typecheck, lint, tests, secrets, RTL, bundle, types, touch targets |
| `commit` | commit, conventional commits | Full OMEGA flow: purge → audit → atomic → security → release |
| `bundle-analyze` | bundle size, first load | Tracks First Load JS, flags pages over 100KB |
| `perf-expert` | performance, LCP, CLS | Core Web Vitals, React rendering, bundle splitting |
| `pwa-expert` | PWA, service worker, offline | Manifest, caching strategies, push notifications |
| `frontend-rules` | frontend, component, styling | Component architecture, CSS logical properties, design tokens |
| `backend-rules` | backend, API, database | API design, query safety, error handling |
| `edge-case-hunter` | edge cases, what could go wrong | Probes 12 failure dimensions: empty states, race conditions, overflow |
| `adversarial-review` | code review, adversarial | Attacks your code before production does |
| `flutter-rules` | flutter, dart, widget | Flutter directional APIs, `EdgeInsetsDirectional`, `AlignmentDirectional` |

---

## How It Works

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

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
```

The installer copies skill files into your AI assistant's context directory. For Claude Code: `~/.claude/skills/`. For others, it follows the platform's convention.

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

You don't need 193 skills to start. These 22 cover the highest-frequency bugs that AI assistants introduce.

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

## Contributing

Contributions that meet the bar:

1. The skill must prevent a real, high-frequency bug — not a hypothetical
2. Must work on Claude Code, Gemini CLI, Kiro, and Cursor
3. No platform-specific frontmatter fields (`allowed-tools`, `context:`, `effort:`, `model:`, `agent:`)
4. Must include at least one before/after code example
5. Must include the security guardrail comment after frontmatter

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full checklist and the skill template.

---

## License

MIT. Use freely, attribution appreciated.

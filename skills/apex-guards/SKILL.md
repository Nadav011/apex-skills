---
name: apex-guards
description: Use when user wants to APEX behavioral guards — replaces CLI hooks. RTL enforcement, security scanning, verification gates, knowledge capture. Apply these checks BEFORE every file write and BEFORE claiming done.
---

# APEX Behavioral Guards v24.7.0

> **Replaces Claude Code hooks for non-CLI environments (Antigravity, etc.)**
> Apply these checks mentally BEFORE every action.

## Pre-Write Guard (Before EVERY file write/edit)

### Security (BLOCKING)
- **No Secrets:** Block `sk-`, `pk_live_`, `AKIA*`, `ghp_`, private keys. Exception: `.env.example`
- **No eval():** Block `eval()`, `new Function()` — always blocked, no exceptions
- **No Destructive Commands:** Never `rm -rf /`, `git push --force` to main, `curl|bash`
- **Protected Files:** Never write `~/.ssh/*`, `.env`/`.env.local` (unless explicit), `node_modules/`

### APEX Laws (BLOCKING)
- **No RTL Physical Properties:** Block `ml-`/`mr-`/`pl-`/`pr-`/`text-left`/`text-right`/`left-`/`right-` in TSX/JSX/CSS. Override: `// rtl-ok`
- **No `any` Types:** Block `: any`, `as unknown as`, `@ts-ignore` (without explanation). Override: `// type-ok`
- **No Console/Print:** Block `console.*` in .ts/.tsx, `print()`/`debugPrint()` in .dart. Override: `// DEBUG`
- **No Large Fixed Dimensions:** Block width >300px, height >500px. Override: `// responsive-ok`

## Pre-Completion Gate — L10+ ELITE (Before claiming "done")

Run mentally (or actually) before any completion claim:

1. **TypeScript:** `pnpm run typecheck` — 0 errors
2. **Lint:** `pnpm run lint` — 0 errors
3. **Tests:** `pnpm run test` — all pass
4. **Anti-patterns:** Scan for `: any`, `console.log`, `TODO`/`FIXME`
5. **RTL scan:** Scan for `ml-`/`mr-`/`text-left`/`text-right` (excluding `// rtl-ok`)
6. **Flutter:** `flutter analyze` must pass (if `pubspec.yaml` exists)
7. **Self-verify:** Re-read request, list all requirements with pass/fail
8. **L10+ Elite Review (16 Dimensions):** "What would a Distinguished Fellow (L10+) at NVIDIA/Google/Meta reject?" — (1) correctness proof (2) failure cascades (3) systemic risk (4) API/Hyrum's Law (5) resource efficiency (6) observability/SRE (7) security adversarial (8) concurrency (9) type-theoretic (10) information density (11) mechanical sympathy (12) tail latency p99.9 (13) backpressure (14) idempotency (15) blast radius (16) cognitive load

**BLOCK if:** TypeScript errors, `any` types without override, lint errors
**WARN if:** console.log, TODO/FIXME, RTL violations

## Knowledge Capture

When discovering a reusable pattern, log it:
```bash
echo "LEARNED: [insight here]"
```
This saves to `~/.claude/knowledge/learned.jsonl` for future recall.

## Clarify Vague Requests

Before acting on short/ambiguous requests (<30 chars), ask for clarification:
- What specifically needs to be done?
- What files/components are involved?
- What is the expected behavior?

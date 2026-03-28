# Portable Skills

This directory now contains the first local export pass of 14 portable skill folders.

Each exported skill includes its own `SKILL.md` and any supporting directories that were already part of the source skill. The goal here is portability, not aggressive cleanup or repackaging in the same pass.

## Candidate Rules

- Keep the portable set limited to skills that do not depend on a specific repo path.
- Remove `model:` from frontmatter when exporting skills for reuse.
- Prefer short, reusable skill descriptions over marketing copy.
- Keep any per-skill assets inside the skill folder.
- Treat this directory as local working state until the Phase 2 rollout is actually verified.

## Exported Set

- `a11y`
- `adversarial-review`
- `apex-guards`
- `backend-rules`
- `edge-case-hunter`
- `flutter-rules`
- `frontend-rules`
- `owasp-security`
- `perf-expert`
- `pwa-expert`
- `rtl-validator`
- `security-rules`
- `testing-rules`
- `zod-patterns`

## Suggested Working Files

- `candidate-list.md` - the shortlist plus missing-skill notes
- `portable-skill-template.md` - a local scratch template for future exports

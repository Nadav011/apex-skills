# Portable Skill Candidate List

This is a local shortlist for the first export pass. Keep it conservative until the repository and publication flow are both verified.

## Candidate Set

- `rtl-validator`
- `rtl-fix`
- `testing-rules`
- `security-rules`
- `frontend-rules`
- `backend-rules`
- `adversarial-review`
- `edge-case-hunter`
- `apex-guards`
- `a11y`
- `pwa-expert`
- `perf-expert`
- `flutter-rules`
- `zod-patterns`
- `owasp-security`

## Export Notes

- Exported now: all listed skills except `rtl-fix`.
- `rtl-fix` is currently missing from local `~/.claude/skills/`, so it needs a separate restore/create/remove decision.
- Strip Claude-specific `model:` frontmatter fields when exporting.
- Keep each skill folder self-contained.
- Validate the final set before any public publication step.
- Do not expand the shortlist with repo-specific skills until the public packaging flow is confirmed.

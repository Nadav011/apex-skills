# APEX Skills

Local scaffold for the future public skill pack. This repository is intentionally conservative: it records structure, working notes, and draft copy only.

## Status

This repo is a local draft. It does not claim publication, installability, marketplace listing, production adoption, or revenue results.

## Current Scope

- Curate a first portable skill set from local `~/.claude/skills/`.
- Strip Claude-specific frontmatter fields when exporting.
- Keep each exported skill self-contained and dependency-light.
- Keep launch copy tied to verified local state only.

## Included Skills

The current local export pass includes 14 portable skill folders:

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

`rtl-fix` is still missing from the local `~/.claude/skills/` tree, so it was not exported into this pass.

## Layout

- `skills/` - portable skill copies, shortlist, and export template
- `blog/` - launch draft and supporting notes

## Working Files

- `skills/README.md` - export rules and candidate guidance
- `skills/candidate-list.md` - shortlist for the first export pass
- `skills/portable-skill-template.md` - local scratch template for exports
- `blog/launch-post.md` - conservative launch draft outline

## Suggested Repo Shape

```text
apex-skills/
├── README.md
├── blog/
│   └── launch-post.md
└── skills/
    ├── README.md
    ├── candidate-list.md
    └── portable-skill-template.md
```

## Next Steps

1. Review the copied skill folders for any remaining local-path assumptions.
2. Decide whether `rtl-fix` should be created, restored, or removed from the shortlist.
3. Keep the blog draft conservative until the operational rollout is actually verified.

# APEX Skills

Local scaffold for the future public skill pack. This repository is intentionally conservative: it records structure, working notes, and draft copy only.

## Status

This repo is a local draft. It does not claim publication, installability, marketplace listing, production adoption, or revenue results.

## Current Scope

- Curate a first portable skill set from local `~/.claude/skills/`.
- Strip Claude-specific frontmatter fields when exporting.
- Keep each exported skill self-contained and dependency-light.
- Keep launch copy tied to verified local state only.

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

1. Copy the selected portable skills into `skills/`.
2. Strip Claude-specific frontmatter fields where needed.
3. Keep the blog draft conservative until the Phase 2 self-healing rollout is actually verified.

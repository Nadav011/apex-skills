# APEX Skills

Local scaffold for the public skill pack planned in Phase 3.

## Status

This repository is a workspace stub. It is intentionally conservative and does not claim production readiness, publication, installability, or revenue results.

## Layout

- `skills/` - portable skill copies to be curated later
- `blog/` - launch writing and supporting notes

## Current Scope

- Curate the first portable skill set from local `~/.claude/skills/`.
- Strip Claude-specific frontmatter fields where needed.
- Keep every exported skill self-contained and dependency-light.
- Keep launch copy tied to verified local state only.

## Suggested Repo Shape

```text
apex-skills/
├── README.md
├── blog/
│   └── launch-post.md
└── skills/
    ├── README.md
    ├── portable-skill-template.md
    └── candidate-list.md
```

## Next Steps

1. Copy the selected portable skills into `skills/`.
2. Strip Claude-specific frontmatter fields where needed.
3. Replace placeholders with the final publication copy only after the Phase 2 self-healing rollout is verified.

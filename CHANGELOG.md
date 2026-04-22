# Changelog

All notable changes to apex-skills are documented here.

## [2.1.0] — 2026-04-22
### Added
- 3 new universal skills: `error-handling`, `logging-patterns`, `api-design`
- `examples/` directory with real before/after code for all 25 skills
- ESM module format for the CLI (Node 18+ native)

## [2.0.0] — 2026-04-22
### Added
- 17 new skills: `a11y`, `adversarial-review`, `apex-guards`, `backend-rules`, `bundle-analyze`, `edge-case-hunter`, `env-validation`, `flutter-rules`, `git-discipline`, `nextjs-patterns`, `react-patterns`, `rtl-fix`, `security-rules`, `typescript-strict`, `zod-patterns`, `perf-expert`, `pwa-expert`
- `npx apex-skills` CLI installer (Node.js)
- Multi-platform: Claude Code, Gemini CLI, Kiro, Codex, Cursor
- Diff-aware install (shows new vs updated)

### Changed
- Rewrote `install.sh` — self-updating cache, diff-aware, platform detection
- All skills ported to portable format (no platform-specific directives)

## [1.0.0] — 2026-04-01
### Added
- Initial release: 8 skills — `rtl-validator`, `commit`, `apex-guards`, `pwa-expert`, `testing-rules`, `security-rules`, `zod-patterns`, `rtl-fix`

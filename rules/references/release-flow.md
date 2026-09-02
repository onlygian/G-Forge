# Release flow — the full sequence (G-RULES §D companion)

Load trigger: read this at release time — a version bump, a milestone close reaching MERGE READY, or a hotfix. Mandatory at that moment. The versioning core (format, bump rules, version sources) lives in `.claude/rules/g-rules-D-code-quality.md`; this file holds the release-time procedure moved out of it (v2.6 token diet).

## Release commit sequence

1. All milestone work merged to `main` and MERGE READY
2. Update version in `plugin.json` and `marketplace.json`
3. Add CHANGELOG entry under the new version heading (Keep a Changelog format)
4. Update README if skill/profile counts, command lists, or capability descriptions changed
5. Grep the literal fact being released (old version string, "candidate"/"pending"/status word, milestone token) across every live surface — never walk a typed site list (ADR-012, ADR-013). The v2.4.1 cut missed live carriers this way.
6. Single commit: `chore: bump to vX.Y.Z` or `vX.Y.Z — <milestone summary>`
7. Push immediately — never leave a version bump unpushed
8. Run `/g-update` on any downstream projects to sync installed files
9. If this repo self-hosts the plugin, resolve any `Installed-copy drift:` line flagged by the review record before tagging — realign `.claude/` from source (`/g-update`) or hand-sync the drifted file; never tag a release over unresolved self-host drift
10. Tag the release commit `vX.Y.Z` (lightweight) and cut the GitHub release with that version's CHANGELOG section as the body — from v2.4.0 onward, per *Git tags* below

## Hotfix flow

Hotfix patches (`a` suffix) bypass the milestone cycle: fix on `main`, bump `PATCH` + append `a`, commit, push. Used when a critical fix must ship without bundling into the next planned release.

## Git tags

Used from **v2.4.0 onward**, for GitHub releases only. Tag the release commit as `vX.Y.Z` (lightweight tag, no GPG) and cut the release with the CHANGELOG section for that version as the body. The CHANGELOG heading `## [X.Y.Z] — YYYY-MM-DD` remains the **authoritative** version record; the tag is a convenience for `git describe` and the GitHub releases page, never a second source of truth. Versions released before v2.4.0 are deliberately un-tagged and un-released — backfilling them would notify watchers with fictional dates.

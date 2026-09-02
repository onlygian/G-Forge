# One registrar — why hooks live only in .claude/settings.json (Step 7)

Load this when a maintainer asks why the plugin manifest registers no hooks. (Rationale is also summarized in README and `hooks/hooks.json`'s own description — those stay in place; this is the install-time copy.)

`.claude/settings.json` (project-local settings) is the **single** place G-Forge hooks are registered. The plugin manifest (`hooks/hooks.json`) deliberately registers **none** — a manifest registers hooks globally for every session, which would double-fire against this per-project registration (Claude Code only de-dupes *identical* command strings, and the manifest path differs from the project path) and would run the commit gate in non-G-Forge projects. One registrar, no duplication.

The idempotent merge (check before you add, never append a duplicate) is what keeps re-running `/g-init` or installing from more than one entry point safe.

# Step 7 background — hook realignment rationale

Load when editing Step 7 or when a developer asks why the realign rules are
shaped this way. The realign table, the operational matcher rule, and the
de-dup procedure stay in SKILL.md Step 7 — this file holds the why.

## Why the matcher must be `Bash|PowerShell`, never bare `Bash`

Claude Code on Windows executes shell commands through the PowerShell tool. A
`Bash`-only matcher never fires on a PowerShell tool call, which silently
disables the commit gate, sentinel cleanup, and observer on every Windows
consumer — a fail-open, not a crash, so nothing surfaces it. That is why Step 7
actively *corrects* a bare `Bash` matcher found in a project's
`.claude/settings.json` (widen and report) rather than merely installing new
entries correctly.

## Single registrar — the manifest registers no hooks

`.claude/settings.json` is the **single** registrar for G-Forge hooks. The
plugin manifest (`hooks/hooks.json`) deliberately registers none — a non-empty
manifest would register hooks globally for every session on top of the
per-project registration, double-firing the commit gate. So there is never a
manifest-vs-project duplicate by construction, and any duplicate found in a
project came from an older version or a second install path — which is exactly
what Step 7's de-dup pass repairs ("check and update, don't duplicate").
Stale entries whose command points at a path that no longer exists (an old
hooks location, or a `${CLAUDE_PLUGIN_ROOT}` reference from when the manifest
still registered hooks) are removed on the same pass. Hooks the developer
added themselves are never touched.

## Which hooks source which libs

The `lib/` scripts are `source`d at runtime, never invoked directly, and have
no `settings.json` event of their own — realign-content-only:

- `lib/commit-detect.sh` — sourced by check-commit.sh, observe.sh,
  post-commit-cleanup.sh.
- `lib/worktree-resolve.sh` — sourced by all seven top-level hooks and the
  native `pre-commit` hook.
- `lib/classify-changeset.sh` — sourced by check-commit.sh and the native
  `pre-commit` hook.
- `lib/sentinel-read.sh` — sourced by pre-commit and workflow-checkpoint.sh.
- `lib/stdin-read.sh` — sourced by all seven top-level hooks.
- `lib/semver-compare.sh` — sourced by workflow-checkpoint.sh (and by
  `scripts/preflight.sh` in this skill).

The libs also sourced by the native `pre-commit` hook (`worktree-resolve.sh`,
`classify-changeset.sh`, `sentinel-read.sh`) additionally need a copy at
`<hooks-dir>/lib/<filename>` — the directory `pre-commit` actually sources
from at runtime, distinct from `.claude/hooks/lib/`. That copy is realigned in
Step 7a, not Step 7 — Step 7 is the Claude-Code-invoked-hook side only.

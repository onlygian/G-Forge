---
name: g-update
description: Fix G-Forge-managed files via Step 0 staleness preflight (stops with zero writes if cache lags GitHub, directs to `/plugins` first), then realigns CLAUDE.md Rules, agents, architecture rules, hooks, and native pre-commit gate. Safe — G-Forge markers only.
---

**Announce:** "Using g-update to pull the latest plugin from GitHub and realign project files."

Sync G-Forge-managed content in this project from the plugin cache — or, in self-host mode (this project IS the plugin source), from the working tree itself, which has no cache to update. Touch only content G-Forge originally injected — never user-written content.

## Step 0 — Staleness preflight

Run `scripts/preflight.sh` from the project root (via the plugin-cache Glob `~/.claude/plugins/cache/g-forge/g-forge/*/skills/g-update/scripts/preflight.sh`; self-host: the repo copy). Reprint every `NOTE:` line, then act on its keys:

- `SELF_HOST: on` → jump to Step 1.
- `COMPARE: cache-stale` → reprint the block between `BANNER_BEGIN: stale` and `BANNER_END` verbatim and **STOP — zero writes to the project this run.** Only `/plugins` can update the cache. (`/g-doctor` Check 23 is the standalone read-only version diagnosis.)
- `COMPARE: github-unreachable` or `COMPARE: cannot-compare` → reprint the degrade banner/notes verbatim, then continue — comparing installed content against the cache only.
- `GTEAM: found` → reprint the g-team banner verbatim and stop — never delete another plugin's files yourself.

Step 0a — legacy g-team detection is part of the preflight script.

Rationale (stale-cache stop, self-host/ADR-008, ADR-009): read `references/preflight-rationale.md` when the preflight stops or degrades and the developer asks why, or when editing Step 0.

## Step 1 — Locate the plugin root

`[plugin-root]` = the script's `PLUGIN_ROOT` (self-host: the project root; consumer: the parent of `skills/` under the cache Glob). On `PLUGIN_ROOT: MISSING`, tell the developer: "Could not find the G-Forge plugin in ~/.claude/plugins/cache/. Run `/plugin update g-forge` first." and stop.

## Step 2 — Inventory and confirm

Run `scripts/inventory.sh` and render its rows into this frame:

```
Installed G-Forge content:

  CLAUDE.md:
    G-Forge Rules block:  [present / not found]
    Architecture stacks:  [vue-pinia, fastapi, ... / none]

  .claude/agents/:         [vue-architect.md, fastapi-architect.md, ... / none]
  .claude/rules/:          [architecture-vue-pinia.md, ... / none]
  .claude/hooks/:          [check-commit.sh present / not found] [workflow-checkpoint.sh present / not found]
  G-RULES.md:              [present / not found]
```

Ask: **"Ready to update all of the above to the current plugin version? (y/n)"** — wait for confirmation.

## Step 3 — Update G-Forge Rules block in CLAUDE.md

From `[plugin-root]/skills/g-init/SKILL.md`, extract everything between `<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->` and `<!-- End G-Forge Rules -->` (inclusive of both marker lines). Replace the same marker block in `CLAUDE.md`; append at the end if absent. Report: `✓ CLAUDE.md — G-Forge Rules updated`

## Step 3a — Update G-RULES.md

Overwrite project-root `G-RULES.md` from `[plugin-root]/G-RULES.md` (copy it if missing, and ensure `@G-RULES.md` appears near the top of `CLAUDE.md`). Report: `✓ G-RULES.md — realigned`

## Step 4 — Migrate and verify architecture rules format

For each `<!-- G-Forge [stack] Architecture Rules` block found in Step 2:

- **New format** — the block is the single line `@.claude/rules/architecture-[stack].md`: verify the target exists; recreate from the plugin if missing. Report: `✓ CLAUDE.md — [stack] rules reference verified`
- **Legacy format** — full rules inline (more than 3 non-empty lines): write the inline content to `.claude/rules/architecture-[stack].md` (create the dir if needed), replace everything between the markers with that single `@` line. Report: `✓ CLAUDE.md — [stack] rules extracted to .claude/rules/ · CLAUDE.md compacted`
- **Profile removed from the plugin** — tell the developer and skip; never delete the block or the rules file.

Content updates happen in Step 6.

## Step 5 — Update architect and implementer agents in .claude/agents/

**Architect agents** — for each found in Step 2, match its `name:` frontmatter against `[plugin-root]/profiles/*/agents/*.md` and replace the file content with the plugin version. No match → "Could not find a current profile for `[name]` — skipping. It may have been renamed or removed." — never delete the file.

**Implementer agents** — if Step 2 reported any `*-implementer` agent (skip `feature-implementer` — a shipped agent, not a per-stack one), read `references/implementer-rerender.md` and re-render each from the current template per that reference (same skip line when its stack profile is gone).

Report: `✓ .claude/agents/[filename] — updated` for each agent.

## Step 6 — Update .claude/rules/ files

**6a** — for each file in `[plugin-root]/rules/g-rules/`, overwrite the project copy at `.claude/rules/g-rules-<letter>-<name>.md` — only sections already installed (a trimmed preset keeps its trim). Report: `✓ .claude/rules/g-rules-*.md — [N] rule section files updated`

**6b** — match each remaining `.claude/rules/` file to `[plugin-root]/profiles/*/rules/architecture.md` by content signature (first heading / stack keywords); replace if matched, else report: "Skipping `.claude/rules/[filename]` — does not appear to be G-Forge managed." Report `✓ .claude/rules/[filename] — updated` per update.

**6c** — installed architecture-skill copies at `.claude/skills/architecture-[stack]/SKILL.md` (written by `/g-specialize`, its "Also after writing each agent file" step). Enumerate instances from disk — `ls -d .claude/skills/architecture-*/` — never from a stack list. Per instance: keep the existing frontmatter (through the closing `---`), replace the body verbatim with `[plugin-root]/profiles/<stack>/rules/architecture.md`. Missing profile → "Could not find a current profile for `architecture-<stack>` — skipping. It may have been renamed or removed." No closing `---` fence → report it malformed and skip — don't guess; `/g-specialize` regenerates it cleanly. No instances → `ℹ no installed architecture skills — nothing to realign`. Report: `✓ .claude/skills/architecture-[stack]/SKILL.md — realigned` per update.

Realign scope note: installed surfaces now also include skills' `scripts/` and `references/` directories, `rules/references/`, and `.claude/rules/g-dispatch-matrix.md` — realign plugin-managed copies of these the same overwrite-only-where-already-installed way.

## Step 7 — Update hook scripts

Canonical hook bodies live in `[plugin-root]/hooks/`; `.claude/settings.json` is the **single** registrar (background: `references/hook-realign-notes.md`). For each table row, realign `.claude/hooks/<file>`:

- **Exists:** replace its contents. Report: `✓ .claude/hooks/<file> — updated`
- **Missing:** create it (plus `.claude/hooks/` and `.claude/hooks/lib/` as needed) AND register each of its events in `.claude/settings.json` — merge-not-overwrite, template JSON from `[plugin-root]/skills/g-init/SKILL.md` Step 7. Report: `✓ .claude/hooks/<file> — created and registered`

In both cases verify a registration exists for every event the hook uses; add any missing one and report `✓ .claude/settings.json — <Event> hook verified`. The `lib/` rows realign content-only to `.claude/hooks/lib/<filename>` — they are `source`d at runtime, never registered; skip the registration clause for them.

| Hook | settings.json event(s) | invocation |
|------|------------------------|------------|
| `check-commit.sh` | PreToolUse (matcher `Bash\|PowerShell`) | `check-commit.sh` |
| `post-commit-cleanup.sh` | PostToolUse (matcher `Bash\|PowerShell`) | `post-commit-cleanup.sh` |
| `observe.sh` | PostToolUse (matcher `Bash\|PowerShell`) + SessionStart | `observe.sh log` / `observe.sh session` |
| `agent-lifecycle.sh` | SubagentStart + SubagentStop | `agent-lifecycle.sh start` / `agent-lifecycle.sh stop` |
| `pre-compact.sh` | PreCompact | `pre-compact.sh` |
| `session-start.sh` | SessionStart | `session-start.sh` |
| `workflow-checkpoint.sh` | UserPromptSubmit | `workflow-checkpoint.sh` |
| `lib/commit-detect.sh` | — (sourced, not registered) | sourced by top-level hooks — never invoked directly |
| `lib/worktree-resolve.sh` | — (sourced, not registered) | sourced by top-level hooks + native `pre-commit` — never invoked directly |
| `lib/classify-changeset.sh` | — (sourced, not registered) | sourced by top-level hooks + native `pre-commit` — never invoked directly |
| `lib/sentinel-read.sh` | — (sourced, not registered) | sourced by top-level hooks + native `pre-commit` — never invoked directly |
| `lib/stdin-read.sh` | — (sourced, not registered) | sourced by top-level hooks — never invoked directly |
| `lib/semver-compare.sh` | — (sourced, not registered) | sourced by top-level hooks — never invoked directly |

The shell-tool matcher must be `Bash|PowerShell`, never bare `Bash` (Windows fail-open — see `references/hook-realign-notes.md`, which also maps which hooks source which libs). If any shell-matched row carries a bare `Bash` matcher in `.claude/settings.json`, widen it and report `✓ .claude/settings.json — shell matcher widened to Bash|PowerShell`. The libs also sourced by the native `pre-commit` hook additionally need a copy at `<hooks-dir>/lib/<filename>` — realigned in Step 7a, not here.

**De-dup:** exactly one entry per G-Forge script per event — remove extras and stale-path entries (old hook locations, `${CLAUDE_PLUGIN_ROOT}` leftovers); leave non-G-Forge hooks untouched. Report `✓ .claude/settings.json — removed [N] duplicate hook registration(s)` only if any were removed.

## Step 7a — Realign the native pre-commit gate

The commit gate's authoritative enforcement site is the native git hook `[plugin-root]/hooks/pre-commit`, installed into the repo's real git hooks directory — never into `.claude/hooks/` (rationale, ADR-004/ADR-011 history: `references/native-gate-notes.md`).

1. Resolve `<hooks-dir>` with `git rev-parse --git-path hooks` — never assume `.git/hooks/` (worktrees, `core.hooksPath`).
2. At `<hooks-dir>/pre-commit`:
   - **Absent:** copy from `[plugin-root]/hooks/pre-commit`, make executable (`chmod +x`, best effort). Report: `✓ <hooks-dir>/pre-commit — installed (canonical from plugin cache)`
   - **First lines contain `G-Forge commit gate`:** G-Forge-managed — overwrite from the plugin and re-verify executable. Report: `✓ <hooks-dir>/pre-commit — realigned`
   - **Foreign (marker absent):** never overwrite. Report: `⚠ <hooks-dir>/pre-commit — left untouched (not G-Forge-managed); G-Forge's commit gate is not enforced here. Back it up and remove it, then re-run /g-update, if you want the gate installed natively.`
3. **Non-foreign branches only** — realign `<hooks-dir>/lib/`: create the directory if needed, enumerate the canonical set from disk (`ls [plugin-root]/hooks/lib/*.sh` — never a typed list), overwrite each `<hooks-dir>/lib/<file>` from the plugin. Report: `✓ <hooks-dir>/lib/*.sh — realigned`
4. `pre-commit` gets **no** `.claude/settings.json` entry, ever.

## Step 8 — Report

```
g-forge update complete ✓

  [one ✓ or [skipped] row per touched surface — exactly the report lines emitted in Steps 3–7a]

All G-Forge-managed content is now at plugin version [read version from plugin-root/.claude-plugin/plugin.json].
```

If nothing needed updating (all content already matched): "All G-Forge-managed content is already up to date."

## Rules

- Never modify content outside G-Forge markers in CLAUDE.md.
- Never delete or overwrite files not identified as G-Forge-managed.
- Never run without developer confirmation from Step 2.
- If the plugin root cannot be found, stop and tell the developer.
- Step 0 sets `[plugin-root]` once — never hardcode the cache path anywhere else.
- A stale cache (cache < GitHub latest) means zero project writes this run — only `/plugins` can fix the cache, never this skill.
- Version ordering always comes from `hooks/lib/semver-compare.sh`'s `gf_semver_compare` (ADR-009: one ordering contract, shared with the checkpoint hook and `/g-doctor` Check 23) — never hand-roll a compare or lean on `sort -V`; a malformed result degrades loudly, never to "assume current".
- Read the plugin files fresh each run — never use cached or assumed content.

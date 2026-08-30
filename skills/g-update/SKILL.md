---
name: g-update
description: Fix G-Forge-managed files via Step 0 staleness preflight (stops with zero writes if cache lags GitHub, directs to `/plugins` first), then realigns CLAUDE.md Rules, agents, architecture rules, hooks, and native pre-commit gate. Safe — G-Forge markers only.
---

**Announce:** "Using g-update to pull the latest plugin from GitHub and realign project files."

You are first updating the plugin cache from GitHub, then syncing G-Forge-managed content in this project against it — unless this project is the plugin source itself (self-host mode, Step 0), in which case the working tree already IS the current source and there is no cache to update first. You only touch content that G-Forge originally injected — never user-written content.

---

## Step 0 — Staleness preflight

**Self-host detection:** root `.claude-plugin/plugin.json` exists AND its `name` matches the plugin's own name (`g-forge`) → the source root flips from the plugin cache to the working tree (self-host mode); every plugin-cache Glob below resolves through this detected source root instead. Consumer projects (no root `.claude-plugin/plugin.json`) are structurally unaffected — detection cannot fire there, and the plugin-cache path is the fallback branch, unchanged.

Check this now, before anything else in this skill. Read `.claude-plugin/plugin.json` at the project root (the working tree you are running in — not the cache) if it exists, and compare its `name` field. Store the result as **self-host mode: on/off** — every step below that references `[plugin-root]` or "the plugin cache" uses this result.

- **Self-host mode on:** report `✓ Self-host mode detected — working tree is source, skipping cache version check.` and skip directly to Step 1 (which sets `[plugin-root]` to the project root, no Glob needed). The staleness preflight below does not apply to self-host mode at all — there is no separate cache copy that can be behind GitHub; the working tree IS the source.
- **Self-host mode off (fallback branch — every consumer project):** run the staleness preflight below before anything else in this skill.

### The staleness preflight (consumer projects only)

`/g-update` cannot update the plugin cache itself — the cache is owned by Claude Code's plugin manager (`/plugins`), not by this skill. If the cache is behind GitHub, syncing this project from it would silently install OLD files into the project while reporting success. This preflight exists to catch that *before* any write happens.

1. **Resolve the version triple:**
   - **Cache version** — Glob `~/.claude/plugins/cache/g-forge/g-forge/` for subdirectories, pick the highest semver, read its `.claude-plugin/plugin.json`, extract the version. If nothing is found, there is no cache to be stale — report so and continue to Step 0a (Step 1 will report the missing-plugin error).
   - **GitHub latest version** — fetch it:
     ```bash
     curl -sf --max-time 10 https://raw.githubusercontent.com/onlygian/G-Forge/main/.claude-plugin/plugin.json | grep '"version"'
     ```
   - **Project-installed version** — what this project's G-Forge-managed files were last synced from. There is currently no version stamp recorded anywhere in the project (Step 2's inventory records file/block *presence*, not a version number) — report this as `unknown` unless a future manifest resolves it.

2. **Cache found + GitHub reachable — compare cache vs. GitHub latest.** Source every ordering from `hooks/lib/semver-compare.sh`'s `gf_semver_compare` — never hand-roll the comparison (ADR-009: one ordering contract, shared by the checkpoint hook, `/g-doctor` Check 23, and this preflight):
     ```bash
     . [plugin-root]/hooks/lib/semver-compare.sh
     gf_semver_compare "[cache]" "[latest]"
     ```
     `gf_semver_compare A B` prints `-1`/`0`/`1` (A older/equal/newer than B). On malformed input it prints `0` and returns exit status 1 — treat that as "cannot compare", degrade like the GitHub-unreachable branch below rather than assuming the cache is current.
   - **Cache ≥ GitHub latest** (compare returns `0` or `1`)**:** report `✓ Plugin cache already at latest (v[cache]) — proceeding with project sync.` and continue to Step 0a.
   - **Cache < GitHub latest** (compare returns `-1`)**— STOP. Zero writes to the project this run.** Report the full version triple and stop *before* Step 0a or any later step runs — no file in this project is read for writing, no CLAUDE.md/agent/hook/rules content is touched:
     ```
     ⚠ Cannot sync — plugin cache is behind GitHub (v[cache] installed, v[latest] available).
       Project-installed version: v[installed-or-unknown]

     /g-update cannot fix this itself — it only syncs this project from the cache, and the
     cache is behind. Syncing now would silently install OLD files into this project.

     Update the plugin cache first:
       /plugins  →  Installed  →  g-forge  →  Update now

     Then re-run /g-update to sync your project files.
     ```
     For a standalone, read-only diagnosis of version alignment at any time (not just before a sync) — including which side is behind and why — see `/g-doctor` Check 23. This gate only decides whether *this run* may write.

3. **GitHub unreachable (curl fails) — degrade loudly, never silently proceed:**
   ```
   ⚠ GitHub unreachable — cannot confirm the cache is current.
     Cache version:              v[cache]
     Project-installed version:  v[installed-or-unknown]

   Proceeding from a cache-vs-installed comparison only — this cannot detect a stale cache.
   If you suspect the cache is behind, update it via /plugins before trusting this sync.
   ```
   Continue to Step 0a and the rest of the skill, comparing the project's installed content against the cache only, exactly as Steps 2–7 already do.

---

## Step 0a — Detect a leftover legacy `g-team` plugin

G-Forge was formerly named **g-team**. Claude Code keys plugins by name, so the rename created a *new* plugin (`g-forge`) — it does not replace an old `g-team` install. If both are enabled, **every `/g-*` command appears twice** (one copy from each plugin's `commands/`). Check for the leftover:

```bash
ls -d ~/.claude/plugins/cache/g-team 2>/dev/null
grep -l '"g-team"' ~/.claude/plugins/config.json ~/.claude/settings.json 2>/dev/null
```

If a `g-team` plugin or marketplace entry is found, stop and tell the developer (this is the fix for duplicated commands):

```
⚠ Legacy "g-team" plugin still installed — it duplicates every /g-* command.
  g-team was renamed to g-forge; the old plugin must be removed.

  Remove it:
    /plugin  →  Installed  →  g-team  →  Uninstall
    (or: /plugin uninstall g-team, then remove any g-team marketplace entry)

  Then re-run /g-update.
```

Do not attempt to delete another plugin's files yourself — only the developer (via `/plugin`) can uninstall it cleanly. If no `g-team` install is found, report `✓ No legacy g-team plugin — commands are g-forge only.` and continue.

---

## Step 1 — Locate the plugin root

**Self-host mode on** (detected in Step 0): `[plugin-root]` = the project root — the working tree itself. There is nothing to locate; skip the Glob below entirely.

**Self-host mode off (fallback branch — every consumer project):** Use Glob to find the plugin's skill files:
```
~/.claude/plugins/cache/g-forge/g-forge/*/skills/g-init/SKILL.md
```

The parent of the `skills/` directory is the plugin root. Store this path as `[plugin-root]` — you will need it throughout.

If not found, tell the developer: "Could not find the G-Forge plugin in ~/.claude/plugins/cache/. Run `/plugin update g-forge` first." and stop.

---

## Step 2 — Inventory what's installed in this project

Read and record:

**CLAUDE.md:**
- Does `<!-- G-Forge Rules` marker exist? Note current content between markers.
- How many `<!-- G-Forge [stack] Architecture Rules` blocks exist? List each stack name found.

**.claude/agents/:**
- List all `.md` files. For each, read the `name:` field from frontmatter.
- Flag any whose name matches a known G-Forge architect pattern: `*-architect` or `node-architect`.
- Flag any whose name matches the stack-implementer pattern `*-implementer` (e.g. `vue-implementer`, `fastapi-implementer`). These are installed by `/g-specialize` from the implementer template and are updated in Step 5.

**.claude/rules/:**
- List all `.md` files if directory exists.

**.claude/hooks/check-commit.sh:**
- Note if present.

**.claude/hooks/workflow-checkpoint.sh:**
- Note if present.

**G-RULES.md:**
- Note if present at project root.

Present a summary:
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

Ask: **"Ready to update all of the above to the current plugin version? (y/n)"**

Wait for confirmation.

---

## Step 3 — Update G-Forge Rules block in CLAUDE.md

Read `[plugin-root]/skills/g-init/SKILL.md`.

Extract the content between:
```
<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->
```
and:
```
<!-- End G-Forge Rules -->
```
(inclusive of both marker lines).

Read `CLAUDE.md`. Find the same marker block. Replace it entirely with the extracted content from the plugin.

If the marker is not present in CLAUDE.md, append the block at the end of the file.

Report: `✓ CLAUDE.md — G-Forge Rules updated`

---

## Step 3a — Update G-RULES.md

Read `[plugin-root]/G-RULES.md`.

If `G-RULES.md` exists at the project root: overwrite it with the plugin version.
If it does not exist: copy it from the plugin. Also ensure `CLAUDE.md` has `@G-RULES.md` near the top.

Report: `✓ G-RULES.md — realigned`

---

## Step 4 — Migrate and verify architecture rules format

Architecture rules should live in `.claude/rules/architecture-[stack].md` files, with CLAUDE.md holding only a one-line `@reference` per profile. This step migrates any legacy inline blocks to that format, then verifies the references are correct. The actual content update happens in Step 6.

For each `<!-- G-Forge [stack] Architecture Rules` block found in Step 2:

1. Extract the stack name from the marker.
2. Read everything between the opening and closing marker lines.
3. **Detect the format:**

**New format** — the block contains only `@.claude/rules/architecture-[stack].md` (one line, possibly with surrounding whitespace):
- Verify `.claude/rules/architecture-[stack].md` exists in the project. If missing, recreate it from the plugin. Report: `✓ CLAUDE.md — [stack] rules reference verified`.
- Content update is handled by Step 6 — nothing more to do here.

**Legacy format** — the block contains the full rules content inline (more than 3 non-empty lines):
- Write the inline content to `.claude/rules/architecture-[stack].md` (create `.claude/rules/` if needed).
- Replace everything between the markers with the single line: `@.claude/rules/architecture-[stack].md`
- Report: `✓ CLAUDE.md — [stack] rules extracted to .claude/rules/ · CLAUDE.md compacted`
- Step 6 will then update `.claude/rules/architecture-[stack].md` to the current plugin version.

If a stack's profile no longer exists in the plugin (removed), tell the developer and skip it — do not delete the block or the rules file.

---

## Step 5 — Update architect and implementer agents in .claude/agents/

**Architect agents** — for each G-Forge architect agent file found in Step 2:

1. Determine which profile it came from by matching the `name:` frontmatter field against the plugin's profile agent filenames:
   - Read each file in `[plugin-root]/profiles/*/agents/*.md`
   - Match by `name:` field
2. Replace the file content with the current version from the plugin.

If a match cannot be found (agent name doesn't match any current profile), tell the developer: "Could not find a current profile for `[name]` — skipping. It may have been renamed or removed." Do not delete the file.

**Implementer agents** — for each `*-implementer` agent file found in Step 2 (skip `feature-implementer` — that is a shipped agent, not a per-stack one): re-render it from the current implementer template so template improvements propagate.

1. Read the implementer template `[plugin-root]/templates/stack-implementer.md`.
2. Recover the substitutions from the installed file's frontmatter: `{{IMPLEMENTER_NAME}}` is its `name:`; `{{ARCHITECTURE_SKILL}}` is its existing `skills:` entry; `{{ARCHITECT_NAME}}` is the implementer name with `-implementer` → `-architect`; `{{STACK_LABEL}}` from its description (or the matching architect's). Re-derive `{{OWNS_GLOBS}}` from the stack's **current** plugin architecture rules (`[plugin-root]/profiles/[stack]/rules/architecture.md`) using the same layer-map → glob conversion as `/g-specialize` Step 6, so rule changes propagate (remove the `owns:` key if none can be derived).
3. Substitute, strip the leading template-usage comment, and overwrite the file.

If an implementer's stack skill no longer exists in the plugin, tell the developer: "Could not find a current profile for `[name]` — skipping." Do not delete the file.

Report: `✓ .claude/agents/[filename] — updated` for each agent.

---

## Step 6 — Update .claude/rules/ files

**6a — G-rules section files (plugin-managed by definition).** For each file in `[plugin-root]/rules/g-rules/` (`A-session.md` … `J-memory.md`), overwrite the project copy at `.claude/rules/g-rules-<letter>-<name>.md` — the same mapping `/g-init` installs. Only sync sections the project already has installed (a project trimmed to a preset like A–D keeps its trim — do not add sections `/g-init` never installed there).

Report: `✓ .claude/rules/g-rules-*.md — [N] rule section files updated`

**6b — Architecture rules.** For each remaining file in `.claude/rules/`:

1. Try to match it to a profile rules file in `[plugin-root]/profiles/*/rules/architecture.md` by reading the file content and comparing stack signatures (first heading or content keywords).
2. If matched, replace with the current plugin version.
3. If not matched (user-created rule file), skip it and report: "Skipping `.claude/rules/[filename]` — does not appear to be G-Forge managed."

Report: `✓ .claude/rules/[filename] — updated` for each updated file.

**6c — Installed architecture-skill copies.** `/g-specialize` also writes `.claude/skills/architecture-[stack]/SKILL.md` per specialized stack — a frontmatter block (`name: architecture-[stack]`, `description: ...`) followed by the full unmodified content of `profiles/[stack]/rules/architecture.md` as the body (`skills/g-specialize/SKILL.md` "Also after writing each agent file" step). Enumerate installed instances from disk (`ls -d .claude/skills/architecture-*/`), never from a hardcoded stack list. For each instance found:

1. Derive `<stack>` from the directory name (`architecture-<stack>`).
2. Read the installed file's existing frontmatter (everything through the closing `---` line) and keep it unchanged.
3. Replace the body with the current `[plugin-root]/profiles/<stack>/rules/architecture.md` content, verbatim.
4. If `[plugin-root]/profiles/<stack>/rules/architecture.md` no longer exists (profile renamed or removed), skip it and report: "Could not find a current profile for `architecture-<stack>` — skipping. It may have been renamed or removed." Do not delete the file.

Report: `✓ .claude/skills/architecture-[stack]/SKILL.md — realigned` for each updated file.

---

## Step 7 — Update hook scripts

The canonical hook bodies live in `[plugin-root]/hooks/` (the same files `/g-init` copies). `.claude/settings.json` is the **single** registrar — the plugin manifest (`hooks/hooks.json`) registers no hooks, so there is never a manifest-vs-project duplicate. For each of the G-Forge-managed hooks and shared `lib/` scripts in the table below, realign `.claude/hooks/<file>` to the plugin source:

- **File exists:** Replace its contents with `[plugin-root]/hooks/<file>`. Report: `✓ .claude/hooks/<file> — updated`.
- **File does not exist:** Create it (along with `.claude/hooks/` — and `.claude/hooks/lib/` too, when it does not yet exist — if needed) from the plugin source, AND register its hook entry in `.claude/settings.json` for every event it uses, if not already present. Report: `✓ .claude/hooks/<file> — created and registered`.

In **both** cases, after writing the file, verify `.claude/settings.json` contains a registration for every event the hook uses; if any is missing, add it with the merge-not-overwrite pattern (read the current JSON, insert under the event key, write back without touching other keys) and report `✓ .claude/settings.json — <Event> hook verified`. The six `lib/` scripts below have no `settings.json` event of their own — they are `source`d at runtime by the top-level hooks (and, for some, by the native `pre-commit` hook), never invoked directly — so for them this step is realign-content-only; skip the registration-verification clause.

| Hook | settings.json event(s) | invocation |
|------|------------------------|------------|
| `check-commit.sh` | PreToolUse (matcher `Bash\|PowerShell`) | `check-commit.sh` |
| `post-commit-cleanup.sh` | PostToolUse (matcher `Bash\|PowerShell`) | `post-commit-cleanup.sh` |
| `observe.sh` | PostToolUse (matcher `Bash\|PowerShell`) + SessionStart | `observe.sh log` / `observe.sh session` |

The shell-tool matcher must be `Bash|PowerShell`, never `Bash` alone — Claude Code on Windows executes shell commands through the PowerShell tool, and a Bash-only matcher silently disables the commit gate, sentinel cleanup, and observer there (fail-open). If a project's `.claude/settings.json` still carries a bare `Bash` matcher on any of these three rows, correct it during this step and report `✓ .claude/settings.json — shell matcher widened to Bash|PowerShell`.
| `agent-lifecycle.sh` | SubagentStart + SubagentStop | `agent-lifecycle.sh start` / `agent-lifecycle.sh stop` |
| `pre-compact.sh` | PreCompact | `pre-compact.sh` |
| `session-start.sh` | SessionStart | `session-start.sh` |
| `workflow-checkpoint.sh` | UserPromptSubmit | `workflow-checkpoint.sh` |
| `lib/commit-detect.sh` | — (sourced, not registered) | sourced by check-commit.sh, observe.sh, post-commit-cleanup.sh — never invoked directly |
| `lib/worktree-resolve.sh` | — (sourced, not registered) | sourced by all seven top-level hooks and the native `pre-commit` hook — never invoked directly |
| `lib/classify-changeset.sh` | — (sourced, not registered) | sourced by check-commit.sh and the native `pre-commit` hook — never invoked directly |
| `lib/sentinel-read.sh` | — (sourced, not registered) | sourced by pre-commit and workflow-checkpoint.sh — never invoked directly |
| `lib/stdin-read.sh` | — (sourced, not registered) | sourced by all seven top-level hooks — never invoked directly |
| `lib/semver-compare.sh` | — (sourced, not registered) | sourced by workflow-checkpoint.sh — never invoked directly |

The `lib/` rows realign to `.claude/hooks/lib/<filename>` (create `.claude/hooks/lib/` first if it does not exist) — same file-exists/file-does-not-exist branching as above, minus the settings.json step. This is the Claude-Code-invoked-hook side only: the libs also sourced by the native `pre-commit` hook (`worktree-resolve.sh`, `classify-changeset.sh`, `sentinel-read.sh`) additionally need a copy at `<hooks-dir>/lib/<filename>` — the directory `pre-commit` actually sources from at runtime, distinct from `.claude/hooks/lib/`. That copy is realigned in Step 7a below, not here.

Use the exact registration JSON in `[plugin-root]/skills/g-init/SKILL.md` Step 7 as the template for any entry you add.

### De-duplicate — enforce the single-registrar guarantee

After realigning, ensure `.claude/settings.json` has **exactly one** entry per G-Forge script per event. This is the "check and update, don't duplicate" guarantee — `/g-update` is the tool that repairs a project that picked up duplicates from an older version or a second install path:
- If any G-Forge script is registered more than once under the same event (a legacy entry plus a new one, or two different command paths for the same script), remove the extras — keep the single entry matching the canonical invocation above.
- Remove any stale G-Forge hook entry whose command points at a path that no longer exists (e.g. an old hooks location, or a duplicate that referenced `${CLAUDE_PLUGIN_ROOT}` from when the manifest still registered hooks).
- Leave non-G-Forge hooks the developer added untouched.

Report `✓ .claude/settings.json — removed [N] duplicate hook registration(s)` only if you removed any.

---

## Step 7a — Realign the native pre-commit gate

The commit gate's authoritative enforcement site (ADR-004) is a **native git hook**, `[plugin-root]/hooks/pre-commit` — it is installed straight into the consumer repo's real git hooks directory, never into `.claude/hooks/`. `.claude/hooks/` only ever holds Claude-Code-invoked scripts (the ones registered in `.claude/settings.json` above); a native git hook is invoked by `git` itself and `.claude/settings.json` has no say over it, so it needs its own realignment pass here.

1. **Resolve the real git hooks directory** — do not assume `.git/hooks/`. Run:
   ```bash
   git rev-parse --git-path hooks
   ```
   This resolves correctly even when the project has a custom `core.hooksPath` configured, or when the working tree is a linked worktree (where `.git` is a file, not a directory). Call the result `<hooks-dir>`.

2. **Detect what's currently at `<hooks-dir>/pre-commit`:**
   - **Absent:** safe to install. Copy `[plugin-root]/hooks/pre-commit` to `<hooks-dir>/pre-commit` and make it executable (`chmod +x`, best effort). Report: `✓ <hooks-dir>/pre-commit — installed (canonical from plugin cache)`.
   - **Present and G-Forge-managed:** read the first few lines of the existing file. If they contain the literal string `G-Forge commit gate`, it is a G-Forge-installed hook — safe to realign. Overwrite it with `[plugin-root]/hooks/pre-commit` and re-verify it is executable. Report: `✓ <hooks-dir>/pre-commit — realigned`.
   - **Present and NOT G-Forge-managed:** the first lines do not contain `G-Forge commit gate` — this is a hook the developer (or another tool) wrote. **Never overwrite it.** Leave it untouched and report: `⚠ <hooks-dir>/pre-commit — left untouched (not G-Forge-managed); G-Forge's commit gate is not enforced here. Back it up and remove it, then re-run /g-update, if you want the gate installed natively.`

3. **Realign `<hooks-dir>/lib/`** — the native `pre-commit` hook sources its shared libs from its own directory at runtime (the set is whatever `hooks/pre-commit`'s `. "$_GF_HOOK_DIR/lib/…"` lines name — read them, never restate them here), denying every commit with an internal error if any is missing. This runs on the **Absent** and **Present and G-Forge-managed** branches above only — never when the existing `pre-commit` is foreign:
   - Create `<hooks-dir>/lib/` if it does not already exist.
   - Enumerate the canonical set **from disk** — `ls [plugin-root]/hooks/lib/*.sh` — never a typed list of lib names (ADR-011 derive-don't-type; a hardcoded list is exactly how `/g-init` once shipped a 4-of-6 lib install undetected).
   - Overwrite each `<hooks-dir>/lib/<file>` from `[plugin-root]/hooks/lib/<file>` for every file the enumeration finds.
   - Report: `✓ <hooks-dir>/lib/*.sh — realigned`.

4. `pre-commit` needs **no** `.claude/settings.json` registration — git invokes it natively on every `git commit`, the same way it invokes any other native git hook. Do not add an entry for it anywhere in `.claude/settings.json`; doing so would be a no-op at best and a confusing duplicate at worst.

---

## Step 8 — Report

```
g-forge update complete ✓

  ✓ CLAUDE.md — G-Forge Rules realigned
  ✓ G-RULES.md — realigned
  ✓ CLAUDE.md — vue-pinia architecture rules realigned
  ✓ .claude/agents/vue-architect.md — realigned
  ✓ .claude/skills/architecture-vue-pinia/SKILL.md — realigned
  ✓ .claude/hooks/check-commit.sh — realigned
  ✓ .claude/hooks/workflow-checkpoint.sh — realigned
  ✓ .claude/hooks/lib/*.sh — realigned
  ✓ <hooks-dir>/pre-commit — realigned | skipped (user hook preserved)
  ✓ <hooks-dir>/lib/*.sh — realigned | skipped (user hook preserved)
  [skipped] .claude/rules/my-custom-rules.md — not G-Forge managed

All G-Forge-managed content is now at plugin version [read version from plugin-root/.claude-plugin/plugin.json].
```

If nothing needed updating (all content already matched): "All G-Forge-managed content is already up to date."

---

## Rules

- Never modify content outside G-Forge markers in CLAUDE.md.
- Never delete or overwrite files not identified as G-Forge-managed.
- Never run without developer confirmation from Step 2.
- If the plugin root cannot be found, stop and tell the developer.
- Step 0's self-host detection is the single source-root resolution point — `[plugin-root]` is set once (Step 0/1) and reused everywhere; never hardcode `~/.claude/plugins/cache/...` outside that fallback branch.
- Step 0's staleness preflight gates every write below it on consumer projects — a stale cache (cache < GitHub latest) means zero project writes this run; only `/plugins` can fix a stale cache, never this skill. Never sync a project against a cache known to be behind GitHub.
- Step 0's cache-vs-latest comparison is always sourced from `hooks/lib/semver-compare.sh`'s `gf_semver_compare` (ADR-009: one ordering contract, shared with the checkpoint hook and `/g-doctor` Check 23) — never hand-roll a version compare or lean on `sort -V` here. A malformed/uncomparable result degrades to the loud offline branch, never to a silent "assume current".
- Read the plugin files fresh each time — never use cached or assumed content.

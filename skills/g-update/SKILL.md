---
name: g-update
description: Realign all G-Forge-managed files in this project to the current plugin version. Updates the G-Forge Rules block in CLAUDE.md, all installed architect and implementer agents, all installed architecture rules, and all seven G-Forge hooks. Safe — only touches content between G-Forge markers.
---

**Announce:** "Using g-update to pull the latest plugin from GitHub and realign project files."

You are first updating the plugin cache from GitHub, then syncing G-Forge-managed content in this project against it. You only touch content that G-Forge originally injected — never user-written content.

---

## Step 0 — Check plugin version

1. Fetch the latest version from GitHub:
   ```bash
   curl -sf --max-time 10 https://raw.githubusercontent.com/onlygian/G-Forge/main/.claude-plugin/plugin.json | grep '"version"'
   ```
   If curl fails (no network, timeout), report: "⚠ Could not reach GitHub — skipping version check, syncing from installed cache." and continue to Step 1.

2. Find the installed version: Glob `~/.claude/plugins/cache/g-forge/g-forge/` for subdirectories, pick the highest semver, read its `.claude-plugin/plugin.json`, extract the version. If nothing found, continue to Step 1.

3. If versions match: report `✓ Plugin already at latest (v[version]) — proceeding with project sync.` and continue to Step 1.

4. If they differ, stop immediately:
   ```
   ⚠ Plugin is at v[installed] — v[latest] is available.

   Update it first:
     /plugin  →  Installed  →  g-forge  →  Update now

   Then re-run /g-update to sync your project files.
   ```
   Do not proceed to Step 1.

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

Use Glob to find the plugin's skill files:
```
~/.claude/plugins/cache/g-forge/g-forge/*/skills/g-init/SKILL.md
```

The parent of the `skills/` directory is the plugin root. Store this path — you will need it throughout.

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

---

## Step 7 — Update hook scripts

The canonical hook bodies live in `[plugin-root]/hooks/` (the same files `/g-init` copies). `.claude/settings.json` is the **single** registrar — the plugin manifest (`hooks/hooks.json`) registers no hooks, so there is never a manifest-vs-project duplicate. For each of the seven G-Forge-managed hooks in the table below, realign `.claude/hooks/<file>` to the plugin source:

- **File exists:** Replace its contents with `[plugin-root]/hooks/<file>`. Report: `✓ .claude/hooks/<file> — updated`.
- **File does not exist:** Create it (along with `.claude/hooks/` if needed) from the plugin source, AND register its hook entry in `.claude/settings.json` for every event it uses, if not already present. Report: `✓ .claude/hooks/<file> — created and registered`.

In **both** cases, after writing the file, verify `.claude/settings.json` contains a registration for every event the hook uses; if any is missing, add it with the merge-not-overwrite pattern (read the current JSON, insert under the event key, write back without touching other keys) and report `✓ .claude/settings.json — <Event> hook verified`.

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

Use the exact registration JSON in `[plugin-root]/skills/g-init/SKILL.md` Step 7 as the template for any entry you add.

### De-duplicate — enforce the single-registrar guarantee

After realigning, ensure `.claude/settings.json` has **exactly one** entry per G-Forge script per event. This is the "check and update, don't duplicate" guarantee — `/g-update` is the tool that repairs a project that picked up duplicates from an older version or a second install path:
- If any G-Forge script is registered more than once under the same event (a legacy entry plus a new one, or two different command paths for the same script), remove the extras — keep the single entry matching the canonical invocation above.
- Remove any stale G-Forge hook entry whose command points at a path that no longer exists (e.g. an old hooks location, or a duplicate that referenced `${CLAUDE_PLUGIN_ROOT}` from when the manifest still registered hooks).
- Leave non-G-Forge hooks the developer added untouched.

Report `✓ .claude/settings.json — removed [N] duplicate hook registration(s)` only if you removed any.

---

## Step 8 — Report

```
g-forge update complete ✓

  ✓ CLAUDE.md — G-Forge Rules realigned
  ✓ G-RULES.md — realigned
  ✓ CLAUDE.md — vue-pinia architecture rules realigned
  ✓ .claude/agents/vue-architect.md — realigned
  ✓ .claude/hooks/check-commit.sh — realigned
  ✓ .claude/hooks/workflow-checkpoint.sh — realigned
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
- Read the plugin files fresh each time — never use cached or assumed content.

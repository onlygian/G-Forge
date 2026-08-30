---
name: g-init
description: The single G-Forge front door — run once after installing the plugin. Detects what's here and routes to /g-onboard (existing codebase) or /g-kickoff (new project) for the brief, scaffolds CLAUDE.md (compact G-rules), g-docs/ROADMAP.md (with the Active Session handoff), g-docs/milestones/, g-docs/todo.md, the commit/workflow hooks (plus their shared lib/ scripts) and the native pre-commit gate, then runs /g-specialize for the stack — leaving you ready to /g-plan.
---

**Announce:** "Using g-init to set up G-Forge."

`/g-init` is the **single front door**. You run it once and it takes the project from wherever it is to ready-to-work: it detects what's already here, routes to `/g-onboard` (existing codebase) or `/g-kickoff` (new project) for the brief, scaffolds the G-Forge structure, then runs `/g-specialize` for the stack. The developer doesn't have to know which command to run first — this is it. Execute the steps in order; skip a step only when its detection says it's already satisfied.

## Step 1 — Confirm project root

The project root is the current working directory. If uncertain, ask the developer to confirm before creating any files.

## Step 1a — Detect self-host source root

**Self-host detection:** root `.claude-plugin/plugin.json` exists AND its `name` matches the plugin's own name (`g-forge`) → the source root flips from the plugin cache to the working tree (self-host mode); every plugin-cache Glob below resolves through this detected source root instead. Consumer projects (no root `.claude-plugin/plugin.json`) are structurally unaffected — detection cannot fire there, and the plugin-cache path is the fallback branch, unchanged.

Check this now, before any Glob below runs. Read `.claude-plugin/plugin.json` at the project root (the working tree you are running in) if it exists, and compare its `name` field.

- **Self-host mode on:** `[plugin-root]` = the project root itself. Every step below that references `[plugin-root]` or "the plugin cache" uses this working-tree path directly — no Glob into `~/.claude/plugins/cache/` is needed.
- **Self-host mode off (fallback branch — every consumer project):** `[plugin-root]` resolves per-step via Glob into `~/.claude/plugins/cache/g-forge/g-forge/`, exactly as before this step existed.

## Step 1b — Detect state and route to intake

Before scaffolding anything, figure out the situation and get a `g-docs/project_brief.md` in place via the right intake skill.

1. **Already a G-Forge project?** If `.claude/integration-tier` exists **and** `CLAUDE.md` contains `<!-- G-Forge Rules`, G-Forge is already initialized here. Don't re-scaffold — tell the developer: "G-Forge is already set up here. Run `/g-update` to re-sync to the current plugin version, or `/g-plan` to start working." Then stop.

2. **Does a `g-docs/project_brief.md` already exist?** If yes, intake is done — skip to Step 2 (scaffold).

3. **Otherwise classify the directory and run the matching intake skill, then continue to Step 2 when it returns:**
   - **Existing codebase** — there is real source beyond docs: a dependency manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, `pubspec.yaml`, `*.csproj`, `pom.xml`/`build.gradle`), or source directories, or more than a couple of commits of real code → run **`/g-onboard`**. Locate `skills/g-onboard/SKILL.md` under `[plugin-root]` (resolved in Step 1a — self-host: read `[plugin-root]/skills/g-onboard/SKILL.md` directly; fallback: Glob `~/.claude/plugins/cache/g-forge/g-forge/*/skills/g-onboard/SKILL.md`) and follow it. It deep-reads the repo, resolves any existing-G-Forge-state conflicts (so the scaffold and `/g-specialize` don't clobber the developer's files), and writes `g-docs/project_brief.md`. **Carry its recorded conflict preferences forward** — if the developer chose to skip CLAUDE.md injection, the existing `g-docs/todo.md` schema, or rules/agents installation, honor that in Steps 2–7.
   - **New / greenfield** — empty, or only docs/README, no real source → run **`/g-kickoff`**. Locate `skills/g-kickoff/SKILL.md` under `[plugin-root]` (self-host: `[plugin-root]/skills/g-kickoff/SKILL.md` directly; fallback: Glob `~/.claude/plugins/cache/g-forge/g-forge/*/skills/g-kickoff/SKILL.md`) and follow it (interview → goals/stack → `g-docs/project_brief.md`).
   - If it's genuinely ambiguous, ask the developer one question: "Is this an existing codebase to onboard, or a fresh project to scaffold?" and route accordingly.

   (When `/g-onboard` or `/g-kickoff` finishes by suggesting `/g-init`, ignore that — you're already in it. Continue to Step 2.)

## Step 2 — Create or update CLAUDE.md

Check if `CLAUDE.md` exists at the project root.

**If it does not exist:**
1. Locate `templates/CLAUDE.md` under `[plugin-root]` (resolved in Step 1a) — self-host: read `[plugin-root]/templates/CLAUDE.md` directly; fallback: Glob `~/.claude/plugins/cache/g-forge/g-forge/*/templates/CLAUDE.md` and use the highest version found.
2. Read the template file.
3. Replace `[Project Name]` with the actual project name (use the directory name, or ask if unclear).
4. Write the result to `CLAUDE.md` at the project root.
5. Tell the developer: "Fill in the project description, stack table, and conventions sections in CLAUDE.md before proceeding."
6. Report: `✓ CLAUDE.md — created from template`

**If it exists:** Read it. If the text `<!-- G-Forge Rules` is not present, append this block at the end of the file:

```
<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->
<!-- (rules loaded via @G-RULES.md at top of file) -->
<!-- End G-Forge Rules -->
```

Report: `✓ CLAUDE.md — verified`

## Step 2a — Install G-RULES.md and rule section files

`[plugin-root]` was resolved in Step 1a — self-host mode points it at the working tree; fallback mode points it at `~/.claude/plugins/cache/g-forge/g-forge/` (confirm the exact versioned path there via Glob).

1. Copy `[plugin-root]/G-RULES.md` to the project root as `G-RULES.md`. Overwrite if it exists — G-Forge managed.

2. Create `.claude/rules/` directory if it does not exist.

3. For each file in `[plugin-root]/rules/g-rules/`, copy it to `.claude/rules/` prefixed with `g-rules-`. Overwrite if it exists — G-Forge managed.

   | Source | Destination |
   |--------|-------------|
   | `rules/g-rules/A-session.md` | `.claude/rules/g-rules-A-session.md` |
   | `rules/g-rules/B-workflow.md` | `.claude/rules/g-rules-B-workflow.md` |
   | `rules/g-rules/C-agent-discipline.md` | `.claude/rules/g-rules-C-agent-discipline.md` |
   | `rules/g-rules/D-code-quality.md` | `.claude/rules/g-rules-D-code-quality.md` |
   | `rules/g-rules/E-architecture-gate.md` | `.claude/rules/g-rules-E-architecture-gate.md` |
   | `rules/g-rules/F-design-patterns.md` | `.claude/rules/g-rules-F-design-patterns.md` |
   | `rules/g-rules/G-documentation.md` | `.claude/rules/g-rules-G-documentation.md` |
   | `rules/g-rules/H-testing.md` | `.claude/rules/g-rules-H-testing.md` |
   | `rules/g-rules/I-project-tracking.md` | `.claude/rules/g-rules-I-project-tracking.md` |
   | `rules/g-rules/J-memory.md` | `.claude/rules/g-rules-J-memory.md` |

4. Ensure `CLAUDE.md` contains `@G-RULES.md` near the top (after the title, before any other content):
   ```
   @G-RULES.md
   ```

Report:
```
✓ G-RULES.md — installed
✓ .claude/rules/g-rules-*.md — 10 rule section files installed
```

## Step 3 — Create g-docs/ROADMAP.md

Create the `g-docs/` directory if it does not exist, then create `g-docs/ROADMAP.md` if it does not exist. It carries the **`## Active Session` handoff** — the single canonical cold-start the whole workflow reads (`workflow-checkpoint.sh`, `/g-resume`, `pre-compact.sh`, `/g-retro`). `g-docs/todo.md` never holds a handoff. Write the handoff block raw under the heading (no code fence), so the `━` separators and the `Active context:` line are greppable:

```
# Roadmap

## Active Session

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — [project] | branch: [branch]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · (nothing yet)
Next up:          · Define M1 scope in g-docs/milestones/M1.md
Active context:   · Fresh project, just initialized
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Milestones

### M1 — [Define milestone name]
**Status:** 🔄 In progress
**Goal:** [one line — what M1 delivers]
**Scope:**
- [ ] Task 1

## Backlog
- M2 — [Define next milestone]
```

Use the same skeleton `/g-roadmap` writes — `## Milestones` with a `### MN` block per milestone — and the same status key: ⬜ Not started · 🔄 In progress · ✅ Complete. Completed milestones stay under `## Milestones` marked ✅ (there is no separate `## Done` section).

If a `g-docs/project_brief.md` exists, read it and use the project goals to fill in M1 and M2 with meaningful content.

## Step 4 — Create g-docs/milestones/M1.md

Create the `g-docs/milestones/` directory if it does not exist.
Create `g-docs/milestones/M1.md` if it does not exist:

```
# M1 — [Milestone Name]

## Goal
[One sentence describing what this milestone delivers]

## Scope
- [ ] Task 1
- [ ] Task 2

## Done condition
[Specific, mechanically checkable condition]

## Status
🔄 In progress
```

## Step 5 — Create g-docs/todo.md

Create `g-docs/todo.md` if it does not exist. It is the tactical task ledger only — **no handoff block** (the handoff lives in `g-docs/ROADMAP.md`'s `## Active Session`):

```
## Tasks
| # | Task | Notes |
|---|------|-------|
| 1 | Define M1 scope | Update g-docs/milestones/M1.md |

## Details
```

## Step 5a — Define the project `.gitignore`

G-Forge generates two kinds of files, and the `.gitignore` is what keeps them straight: **tracked project record** (commit these — they ARE the project) versus **runtime/dev artifacts** (never commit — per-developer, ephemeral, secret, or regenerable). Getting this boundary right is what makes a clone reproducible and a diff readable. Establish it now so the first commit lands clean.

**Track (do NOT ignore) — the project and its shared enforcement:**
- Source code and the project's own build/config.
- `CLAUDE.md`, `G-RULES.md`, `CHANGELOG.md`, `README.md`.
- The `g-docs/` project record: `g-docs/ROADMAP.md`, `g-docs/todo.md`, `g-docs/todo-done.md`, `g-docs/milestones/`, `g-docs/project_brief.md`, and `g-docs/decisions/ retros/ forecasts/ telemetry/ blast-radius/ alignment/ patterns/ inbox/adversarial/`.
- `g-wiki/` — committed human-facing content.
- Shared G-Forge config so teammates inherit the same gates: `.claude/hooks/`, `.claude/settings.json`, `.claude/rules/`, `.claude/agents/`.

**Ignore — runtime/dev artifacts:**
- OS/editor: `.DS_Store`, `Thumbs.db`, `*.swp`.
- Secrets/local: `.env`, `.env.*` (but not `.env.example`), `*.local`.
- Worktrees: `.worktrees/`.
- Per-developer + ephemeral G-Forge state under `.claude/`: the two commit-gate sentinels, the observer journal, and the session/runtime counters and caches.
- Regenerable raw output: `g-docs/agent-output/`.

Read `.gitignore` if it exists; if not, start empty. **Merge idempotently** — add only the lines below that are not already present (match on the exact pattern); never remove or reorder a developer's existing entries, and never ignore a tracked-by-design path above. Append under a labelled block:

```
# ── OS / editor ──
.DS_Store
Thumbs.db
*.swp

# ── Secrets / local env ──
.env
.env.*
!.env.example
*.local

# ── Worktrees ──
.worktrees/

# ── G-Forge runtime state (per-developer / ephemeral — never shared) ──
.claude/g-forge-approved
.claude/g-forge-docs-approved
.claude/journal/
.claude/compact-state.md
.claude/reentry.md
.claude/session-prompt-count*
.claude/session-compaction-count
.claude/context-threshold-offset
.claude/review-holds
.claude/tier3-active
.claude/training-mode
.claude/training-progress.md
.claude/telemetry-coverage
.claude/last-trim
.claude/last-align
.claude/coverage-nudge-stamp
.claude/coverage-nudge-index
.claude/agent-memory-local/

# ── G-Forge regenerable output (not project record) ──
g-docs/agent-output/
```

Note for the developer: shared G-Forge config (`.claude/hooks/`, `.claude/settings.json`, `.claude/rules/`, `.claude/agents/`) is intentionally **left tracked** so the whole team inherits the same hooks and gates. If this project prefers each developer to run `/g-init` themselves, they can add `.claude/` to `.gitignore` — but then teammates won't get the commit gate from a clone.

Report: `✓ .gitignore — project artifacts excluded, project record tracked`

## Step 6 — Set up commit enforcement hooks

Create `.claude/hooks/` directory if it does not exist.

**Mark the project as G-Forge-managed first.** Every hook self-guards on `.claude/integration-tier` and stays inert without it (this is what keeps the global plugin from gating commits in non-G-Forge repos). So before wiring any hooks, if `.claude/integration-tier` does not already exist, write `full` to it now — Step 7a refines it from the developer's answer. This guarantees the marker exists the moment the hooks are registered, even if onboarding (Step 7a) is interrupted.

All hook scripts are **copied verbatim from the plugin cache** rather than inlined here, so a fresh `/g-init` installs the same canonical hook bodies that `/g-update` and `hooks/*.sh` in the plugin source ship. Inlining them here previously caused divergence — new projects ran the pre-M15 hooks until `/g-update` was run.

Plugin hooks directory: `<plugin-hooks>` = `[plugin-root]/hooks/` — `[plugin-root]` was resolved in Step 1a. Self-host mode: this is the working tree's own `hooks/` directly. Fallback mode: Glob the highest-versioned entry under `~/.claude/plugins/cache/g-forge/g-forge/*/hooks/`.

Create `.claude/hooks/lib/` too: `mkdir -p .claude/hooks/lib/` — the six shared libraries below live there, and every top-level hook now sources from that path at runtime, so skipping it produces a broken install.

For each of the following files, copy from `<plugin-hooks>/<relative-path>` to `.claude/hooks/<relative-path>`. If the file already exists at the destination, overwrite it — these scripts are g-forge managed and must stay in sync with the plugin cache.

| Hook | Source | Destination |
|------|--------|-------------|
| `check-commit.sh` | `<plugin-hooks>/check-commit.sh` | `.claude/hooks/check-commit.sh` |
| `post-commit-cleanup.sh` | `<plugin-hooks>/post-commit-cleanup.sh` | `.claude/hooks/post-commit-cleanup.sh` |
| `observe.sh` | `<plugin-hooks>/observe.sh` | `.claude/hooks/observe.sh` |
| `agent-lifecycle.sh` | `<plugin-hooks>/agent-lifecycle.sh` | `.claude/hooks/agent-lifecycle.sh` |
| `pre-compact.sh` | `<plugin-hooks>/pre-compact.sh` | `.claude/hooks/pre-compact.sh` |
| `session-start.sh` | `<plugin-hooks>/session-start.sh` | `.claude/hooks/session-start.sh` |
| `workflow-checkpoint.sh` | `<plugin-hooks>/workflow-checkpoint.sh` | `.claude/hooks/workflow-checkpoint.sh` |
| `lib/commit-detect.sh` | `<plugin-hooks>/lib/commit-detect.sh` | `.claude/hooks/lib/commit-detect.sh` |
| `lib/worktree-resolve.sh` | `<plugin-hooks>/lib/worktree-resolve.sh` | `.claude/hooks/lib/worktree-resolve.sh` |
| `lib/classify-changeset.sh` | `<plugin-hooks>/lib/classify-changeset.sh` | `.claude/hooks/lib/classify-changeset.sh` |
| `lib/sentinel-read.sh` | `<plugin-hooks>/lib/sentinel-read.sh` | `.claude/hooks/lib/sentinel-read.sh` |
| `lib/stdin-read.sh` | `<plugin-hooks>/lib/stdin-read.sh` | `.claude/hooks/lib/stdin-read.sh` |
| `lib/semver-compare.sh` | `<plugin-hooks>/lib/semver-compare.sh` | `.claude/hooks/lib/semver-compare.sh` |

After copying each top-level hook file, ensure it is executable: `chmod +x .claude/hooks/<filename>` (best effort — on Windows, file mode bits may not apply but Claude Code still runs the script via bash). The six `lib/` files do not need this — they are `source`d by the top-level hooks, never executed directly, so the executable bit is optional for them.

The commit gate now has **two sentinels**: `post-commit-cleanup.sh` deletes both `.claude/g-forge-approved` (the code-review gate, written by `/g-review` on MERGE READY) and `.claude/g-forge-docs-approved` (the doc-review gate, written by `/g-doc-review` on DOCS READY) after every successful commit, so both gates reset together.

Report:
```
  ✓ .claude/hooks/check-commit.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/post-commit-cleanup.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/observe.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/agent-lifecycle.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/pre-compact.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/session-start.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/workflow-checkpoint.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/lib/commit-detect.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/lib/worktree-resolve.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/lib/classify-changeset.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/lib/sentinel-read.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/lib/stdin-read.sh — installed (canonical from plugin cache)
  ✓ .claude/hooks/lib/semver-compare.sh — installed (canonical from plugin cache)
```

If the plugin cache does not contain any of the thirteen files above (the top-level hooks plus the `lib/` scripts), stop and report:
```
✗ Plugin cache missing hook file: <plugin-hooks>/<relative-path>
  Reinstall the plugin: /plugin install g-forge
```

## Step 6a — Install the native pre-commit gate and its lib/

ADR-004 makes the native git `pre-commit` hook (`<plugin-hooks>/pre-commit`) — not the PreToolUse `check-commit.sh` hook installed in Step 6 — the authoritative enforcement site for the commit gate: it fires after `git commit` has already staged the true to-be-committed tree, so it sees things PreToolUse cannot (e.g. `git commit -a`/`-p`, raw-terminal commits). It has never been installed by `/g-init` until now. Installing the `pre-commit` script by itself is not the full deliverable: it `source`s several `lib/` scripts from its own directory at runtime and denies every commit with an internal-error message if any is missing — so this step also installs `<git-hooks-dir>/lib/`.

1. Resolve the real git hooks directory — do not assume a fixed default path: run `git rev-parse --git-path hooks` and use its output as `<git-hooks-dir>`. This honors `core.hooksPath` overrides and, in a linked worktree, correctly resolves to the primary checkout's shared hooks directory rather than a per-worktree path.

2. Check what's at `<git-hooks-dir>/pre-commit`:
   - **Absent** — copy `<plugin-hooks>/pre-commit` to `<git-hooks-dir>/pre-commit`, then `chmod +x` it (best effort, same as Step 6).
   - **Present and G-Forge-managed** — read its first lines; if they contain the literal string `G-Forge commit gate` (the canonical `hooks/pre-commit`'s own line-2 header), it is a previous G-Forge install. Overwrite it with `<plugin-hooks>/pre-commit` and `chmod +x` it, same as a fresh install.
   - **Present and NOT G-Forge-managed** — a developer- or another-tool-installed `pre-commit` already exists. **Leave it untouched — never overwrite a foreign hook.** Surface a warning naming the path instead:
     ```
     ⚠ <git-hooks-dir>/pre-commit already exists and is not G-Forge-managed — left untouched.
       G-Forge's commit gate is enforced at the PreToolUse layer only (.claude/hooks/check-commit.sh).
       To let G-Forge also enforce natively, back up and remove the existing hook, then re-run /g-init.
     ```

3. **Install `<git-hooks-dir>/lib/`** — the native `pre-commit` hook sources its shared libs from its own directory at runtime (the set is whatever `hooks/pre-commit`'s `. "$_GF_HOOK_DIR/lib/…"` lines name — read them, never restate them here), denying every commit with an internal error if any is missing. This runs on **both** the Absent and Present-and-G-Forge-managed branches above — never on the Present-and-NOT-G-Forge-managed branch, where nothing is installed:
   - Create `<git-hooks-dir>/lib/` if it does not already exist.
   - Enumerate the canonical set **from disk** — `ls <plugin-hooks>/lib/*.sh` — never a typed list of lib names (ADR-011 derive-don't-type; a hardcoded list is exactly how `/g-init` once shipped a 4-of-6 lib install undetected, because every reader of that list iterated the same short set — `tests/test-lib-install-completeness.sh` pins this).
   - Copy every `<plugin-hooks>/lib/*.sh` file the enumeration finds to `<git-hooks-dir>/lib/<file>`.

Report:
```
  ✓ <git-hooks-dir>/pre-commit — installed (canonical from plugin cache)
  ✓ <git-hooks-dir>/lib/*.sh — installed (canonical from plugin cache)
```
or, if the existing `pre-commit` was left untouched:
```
  ⚠ <git-hooks-dir>/pre-commit — not overwritten (existing non-G-Forge hook preserved)
```

## Step 7 — Register hooks in .claude/settings.json

`.claude/settings.json` (project-local settings) is the **single** place G-Forge hooks are registered. The plugin manifest (`hooks/hooks.json`) deliberately registers **none** — a manifest registers hooks globally for every session, which would double-fire against this per-project registration (Claude Code only de-dupes *identical* command strings, and the manifest path differs from the project path) and would run the commit gate in non-G-Forge projects. One registrar, no duplication.

Register **idempotently — check before you add, never append a duplicate** (this is what keeps re-running `/g-init` or installing from more than one entry point safe):

Read `.claude/settings.json` if it exists. If it does not exist, start with `{}`.

For each hook entry below, look under its event key (e.g. `hooks.PreToolUse`) for an existing command that references the same script basename (e.g. `check-commit.sh`):
- **A matching entry already exists:** leave it — or, if its command string differs from the canonical one below, replace that single entry in place. Never add a second entry for the same script + event.
- **No matching entry exists:** add it.

Preserve any hooks the developer added that are not G-Forge scripts — merge into the `hooks` object, never overwrite it.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/workflow-checkpoint.sh\"'",
            "timeout": 5000
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash|PowerShell",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/check-commit.sh\"'",
            "timeout": 5000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash|PowerShell",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/post-commit-cleanup.sh\"'",
            "timeout": 5000
          },
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/observe.sh\" log'",
            "timeout": 5000
          }
        ]
      }
    ],
    "SubagentStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/agent-lifecycle.sh\" start'"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/agent-lifecycle.sh\" stop'"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/pre-compact.sh\"'",
            "timeout": 5000
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/session-start.sh\"'",
            "timeout": 8000
          },
          {
            "type": "command",
            "command": "bash -c 'bash \"$(git rev-parse --git-common-dir)/../.claude/hooks/observe.sh\" session'",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

Write the merged result back to `.claude/settings.json`.

## Step 7a — First-chat onboarding (voice + tier)

Ask the developer two short questions to set up `.claude/voice-profile` and `.claude/integration-tier`. Ask one at a time, wait for each answer.

**Question 1 (voice):**
> "How should I talk to you?
>   1) **dev** — terse, assumes you know the jargon (default)
>   2) **mid** — same info, one sentence of context per major result
>   3) **eli5** — plain language, no jargon, conversational
>
> Pick one (default: dev). You can change anytime with /g-voice."

Wait for the answer. Map `1`/`d`/`dev` → `dev`; `2`/`m`/`mid` → `mid`; `3`/`e`/`eli5` → `eli5`; anything else or empty → `dev`. Write the resolved value to `.claude/voice-profile`.

**Question 2 (integration tier):**
> "How present should G-Forge be?
>   1) **full** — all hooks fire; /g-plan, /g-execute, /g-review auto-trigger (default)
>   2) **balanced** — state info only; you invoke skills manually; commit gate still on
>   3) **light** — workflow-checkpoint only; commit gate off (opt-out mode)
>
> Pick one (default: full). You can change anytime with /g-tier."

Wait for the answer. Map `1`/`f`/`full` → `full`; `2`/`b`/`balanced` → `balanced`; `3`/`l`/`light` → `light`; anything else or empty → `full`. Write the resolved value to `.claude/integration-tier`.

If the developer chose `light` for the tier, surface the consequence in the active voice profile:
- `dev`: `⚠ Light tier — commit gate off. Manual mode.`
- `mid`: `⚠ Light tier selected — the commit gate is off. You can git commit without /g-review.`
- `eli5`: `Got it. You picked the minimal mode. I won't block your commits and I won't auto-suggest steps. You're driving; I'll be available when you call me.`

Report:
```
  ✓ .claude/voice-profile — [resolved]
  ✓ .claude/integration-tier — [resolved]
```

## Step 7b — Specialize for the stack

The structure is in place; now fit it to the project's stack so the right architect agent and architecture rules are installed. Run **`/g-specialize`** — locate `skills/g-specialize/SKILL.md` under `[plugin-root]` (resolved in Step 1a — self-host: `[plugin-root]/skills/g-specialize/SKILL.md` directly; fallback: Glob `~/.claude/plugins/cache/g-forge/g-forge/*/skills/g-specialize/SKILL.md`) and follow it. It detects the stack (from the brief + dependency manifests), confirms with the developer, and installs the matching architect agent + rules.

Honor any conflict preference recorded in Step 1b: if the developer chose to **skip** or **overlay** rules/agents installation during `/g-onboard`, pass that through — do not overwrite existing `.claude/agents/` or `.claude/rules/` files without the permission they already gave. If no stack is detectable (e.g. a brand-new empty project), skip specialization and note that `/g-specialize` can be run later once the stack exists.

## Step 8 — Report

After all steps, report:

```
G-Forge ready ✓

  ✓ g-docs/project_brief.md — [via /g-onboard | via /g-kickoff | already present]
  ✓ CLAUDE.md — G-Forge rules injected
  ✓ G-RULES.md — installed
  ✓ .claude/rules/g-rules-*.md — 10 rule section files installed
  ✓ g-docs/ROADMAP.md — created with the Active Session handoff (or already existed)
  ✓ g-docs/milestones/M1.md — created (or already existed)
  ✓ g-docs/todo.md — created (or already existed)
  ✓ .gitignore — project artifacts excluded, project record tracked
  ✓ .claude/hooks/ — 7 hooks + 6 lib/ scripts installed (check-commit, post-commit-cleanup, observe, agent-lifecycle, pre-compact, session-start, workflow-checkpoint, lib/commit-detect, lib/worktree-resolve, lib/classify-changeset, lib/sentinel-read, lib/stdin-read, lib/semver-compare)
  ✓ <git-hooks-dir>/pre-commit — installed | not overwritten (existing hook preserved)
  ✓ <git-hooks-dir>/lib/*.sh — installed | skipped (foreign pre-commit preserved)
  ✓ .claude/settings.json — hooks registered
  ✓ .claude/voice-profile — [chosen voice]
  ✓ .claude/integration-tier — [chosen tier]
  ✓ Stack — [specialized: <stack> architect + rules installed | no stack detected yet — run /g-specialize once it exists]

You're set up and ready to work. Next: run /g-plan with your first feature request, or edit g-docs/milestones/M1.md to define your scope.
Tip: run /g-wiki anytime to start a human-facing project wiki in g-wiki/ — it's also refreshed automatically at the end of every milestone.

**Recommended MCPs** — install these in Claude Code for best results with G-Forge:
- `context7` — pulls current library docs into context, eliminates stale-training hallucinations
- `github` — read PRs, diffs, issues directly from chat
- `supabase` — SQL, migrations, schemas from chat (install if your project uses Supabase)

To install: Claude Code → Settings → MCP Servers, or add to `~/.claude/settings.json` under `mcpServers`.
```

## Rules
- Never create a file that already exists without reading it first.
- If g-docs/project_brief.md exists at the project root, use its content to pre-fill g-docs/ROADMAP.md and g-docs/milestones/M1.md.
- Settings.json merge must never drop existing hooks — read before writing.
- Step 1a's self-host detection is the single source-root resolution point — `[plugin-root]` is resolved there and reused everywhere; never hardcode `~/.claude/plugins/cache/...` outside that step's fallback branch.

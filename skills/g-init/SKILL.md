---
name: g-init
description: The single G-Forge front door — run once after installing the plugin. Detects what's here and routes to /g-onboard (existing codebase) or /g-kickoff (new project) for the brief, scaffolds CLAUDE.md (compact G-rules), g-docs/ROADMAP.md (with the Active Session handoff), g-docs/milestones/, g-docs/todo.md, the commit/workflow hooks (plus their shared lib/ scripts) and the native pre-commit gate, then runs /g-specialize for the stack — leaving you ready to /g-plan.
---

**Announce:** "Using g-init to set up G-Forge."

`/g-init` is the **single front door**: run once, it takes the project from wherever it is to ready-to-work. Execute the steps in order; skip a step only when its detection says it's already satisfied.

## Step 1 — Confirm project root

The project root is the current working directory. If uncertain, ask the developer to confirm before creating any files.

## Step 1a — Detect self-host source root

Run `scripts/detect-state.sh` and interpret its `KEY: value` lines (full contract in the script header):
- `SELF_HOST: on` → `[plugin-root]` = the project root itself (working tree); every plugin-cache lookup below uses it directly.
- `SELF_HOST: off` → `[plugin-root]` = the `PLUGIN_ROOT:` path (the highest-versioned entry under `~/.claude/plugins/cache/g-forge/g-forge/`). On `CACHE_MISSING: yes`, stop: tell the developer to reinstall with `/plugin install g-forge`.

`[plugin-root]` is resolved once here and reused by every later step. Rationale for the consumer-vs-self-host split: `references/self-host.md` (read only if detection looks wrong or a maintainer asks).

## Step 1b — Detect state and route to intake

From the same script output:

1. `INITIALIZED: yes` → don't re-scaffold — tell the developer: "G-Forge is already set up here. Run `/g-update` to re-sync to the current plugin version, or `/g-plan` to start working." Then stop.
2. `BRIEF: present` → intake is done — skip to Step 2.
3. Otherwise route by `CLASS:` (the `MANIFEST:` and `COMMITS:` lines are the evidence). `CLASS:` is a signal, not a verdict — the script's source-dir set (`src`/`app`/`source`) and its commits heuristic are not exhaustive, so override `ambiguous` with your own judgment when the tree plainly holds an existing codebase (real source in other dirs like `lib/` or `cmd/`, or more than a couple of commits of real code):
   - `existing` → run **`/g-onboard`**: read `[plugin-root]/skills/g-onboard/SKILL.md` and follow it (deep-reads the repo, resolves existing-G-Forge-state conflicts, writes `g-docs/project_brief.md`). **Carry its recorded conflict preferences forward** — a skipped CLAUDE.md injection, an existing `g-docs/todo.md` schema, or skipped rules/agents installation is honored in Steps 2–7.
   - `greenfield` → run **`/g-kickoff`**: read `[plugin-root]/skills/g-kickoff/SKILL.md` and follow it (interview → goals/stack → `g-docs/project_brief.md`).
   - `ambiguous` → ask one question: "Is this an existing codebase to onboard, or a fresh project to scaffold?" and route accordingly.

   (When `/g-onboard` or `/g-kickoff` finishes by suggesting `/g-init`, ignore that — you're already in it. Continue to Step 2.)

## Step 2 — Create or update CLAUDE.md

Run `scripts/scaffold.sh [plugin-root]` now — it also performs Steps 2a/3/4/5; interpret its lines in each step. **If Step 1b recorded a skipped rules/agents installation preference, pass the matching flag(s)** — `scripts/scaffold.sh --skip-rules --skip-agents [plugin-root]` — and the script honors them (`SKIPPED:` lines confirm). For CLAUDE.md itself the writes stay with you (to honor Step 1b conflict preferences); act on `CLAUDEMD:`:

- `missing` → read `[plugin-root]/templates/CLAUDE.md`, replace `[Project Name]` with the actual project name (directory name, or ask), write it to `CLAUDE.md`, and tell the developer: "Fill in the project description, stack table, and conventions sections in CLAUDE.md before proceeding." Report: `✓ CLAUDE.md — created from template`
- `no-marker` → append this block at the end of the file:

```
<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->
<!-- (rules loaded via @G-RULES.md at top of file) -->
<!-- End G-Forge Rules -->
```

- `no-import` → handled in Step 2a.
- `ok` → Report: `✓ CLAUDE.md — verified`

## Step 2a — Install G-RULES.md and rule section files

Unless `--skip-rules` was passed (on `SKIPPED: rules`, report `⚠ rules install skipped (onboarding preference)` and continue to Step 3), `scripts/scaffold.sh` already copied (overwriting — G-Forge managed): `[plugin-root]/G-RULES.md` → project root; every `rules/g-rules/*.md` → `.claude/rules/g-rules-<name>.md`; `rules/references/*.md` → `.claude/rules/references/` (NOT @-imported — loaded on demand); `rules/dispatch-matrix.md` → `.claude/rules/g-dispatch-matrix.md` (NOT @-imported).

Ensure `CLAUDE.md` contains `@G-RULES.md` near the top (after the title, before any other content) — the one @-import the scaffold requires (`CLAUDEMD: no-import` means it's absent).

Report:
```
✓ G-RULES.md — installed
✓ .claude/rules/g-rules-*.md — [RULES_INSTALLED] rule section files installed
```

## Step 3 — Create g-docs/ROADMAP.md

The script created it if absent (`CREATED:`/`EXISTS:` line). It carries the **`## Active Session` handoff** — the single canonical cold-start the whole workflow reads; the handoff lives in `g-docs/ROADMAP.md`, `g-docs/todo.md` never holds one. The skeleton matches `/g-roadmap`'s shape and status key: ⬜ Not started · 🔄 In progress · ✅ Complete (completed milestones stay under `## Milestones` marked ✅).

If `g-docs/project_brief.md` exists, read it and fill in M1 and M2 with meaningful content.

## Step 4 — Create g-docs/milestones/M1.md

Created by the script if absent (`CREATED:`/`EXISTS:` line). Pre-fill from the brief as in Step 3.

## Step 5 — Create g-docs/todo.md

Created by the script if absent. It is the tactical task ledger only — **no handoff block**.

## Step 5a — Define the project `.gitignore`

Run `scripts/merge-gitignore.sh`. It appends only missing patterns under a labelled block (exact-pattern match) and never removes or reorders a developer's existing entries; interpret `GITIGNORE:` / `ADDED:` / `PRESENT:` lines. The boundary in one sentence: the **tracked project record** (source, CLAUDE.md/G-RULES.md, the `g-docs/` record, `g-wiki/`, shared `.claude/` config) stays committed; **per-developer/ephemeral runtime state and regenerable output** are ignored. If the developer questions the boundary or an existing `.gitignore` conflicts, read `references/tracked-vs-ignored.md`.

Always surface this note to the developer: shared G-Forge config (`.claude/hooks/`, `.claude/settings.json`, `.claude/rules/`, `.claude/agents/`) is intentionally **left tracked** so the whole team inherits the same hooks and gates. If this project prefers each developer to run `/g-init` themselves, they can add `.claude/` to `.gitignore` — but then teammates won't get the commit gate from a clone.

Report: `✓ .gitignore — project artifacts excluded, project record tracked`

## Step 6 — Set up commit enforcement hooks

Run `scripts/install-hooks.sh [plugin-root]`. **It marks the project G-Forge-managed first**: `.claude/integration-tier` is written (`full`) before any hook is copied — every hook self-guards on that marker and stays inert without it, and Step 7a refines the value from the developer's answer. It then copies every hook and `lib/` script verbatim from `[plugin-root]/hooks/` into `.claude/hooks/` (enumerated from disk, chmod +x on the top-level hooks; why verbatim copies and the two-sentinel design: `references/hook-install-notes.md`). The canonical install set:

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

(`<plugin-hooks>` = `[plugin-root]/hooks/`.) On all `COPIED:` lines, report:
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

Then verify **per file** — a partial cache must never install silently: if the script prints any `MISSING:` line, **or** any row of the table above has no matching `COPIED:` line, the plugin cache does not contain one of the thirteen files above (the top-level hooks plus the `lib/` scripts) — stop and report (naming each missing file):
```
✗ Plugin cache missing hook file: <plugin-hooks>/<relative-path>
  Reinstall the plugin: /plugin install g-forge
```

## Step 6a — Install the native pre-commit gate and its lib/

The same script run installs the native git `pre-commit` hook — per ADR-004 the authoritative enforcement site for the commit gate — plus `<git-hooks-dir>/lib/`, the shared libs it sources from its own directory at runtime (set derived from disk per ADR-011, never typed; history and rationale: `references/hook-install-notes.md`). Interpret:

- `GITHOOKS_DIR:` — the real hooks directory, resolved via `git rev-parse --git-path hooks` (honors `core.hooksPath` and linked worktrees).
- `PRECOMMIT: installed` or `updated` (a previous G-Forge install, recognized by its `G-Forge commit gate` header, overwritten) — report:
```
  ✓ <git-hooks-dir>/pre-commit — installed (canonical from plugin cache)
  ✓ <git-hooks-dir>/lib/*.sh — installed (canonical from plugin cache)
```
- `PRECOMMIT: foreign` — a developer- or another-tool-installed hook exists; the script left it untouched and installed nothing there (lib/ included). Report:
```
  ⚠ <git-hooks-dir>/pre-commit — not overwritten (existing non-G-Forge hook preserved)
```
  and surface the warning:
```
⚠ <git-hooks-dir>/pre-commit already exists and is not G-Forge-managed — left untouched.
  G-Forge's commit gate is enforced at the PreToolUse layer only (.claude/hooks/check-commit.sh).
  To let G-Forge also enforce natively, back up and remove the existing hook, then re-run /g-init.
```

## Step 7 — Register hooks in .claude/settings.json

`.claude/settings.json` (project-local) is the single place G-Forge hooks are registered — the plugin manifest deliberately registers none (why: `references/hook-registration.md`).

Register **idempotently — check before you add, never append a duplicate**: read `.claude/settings.json` (start with `{}` if absent). For each hook entry below, look under its event key (e.g. `hooks.PreToolUse`) for an existing command referencing the same script basename: matching entry exists → leave it, or replace that single entry in place if its command string differs from the canonical one; none → add it. Preserve any non-G-Forge hooks the developer added — merge into the `hooks` object, never overwrite it.

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

Ask two short questions, one at a time; wait for each answer.

**Question 1 (voice):**
> "How should I talk to you?
>   1) **dev** — terse, assumes you know the jargon (default)
>   2) **mid** — same info, one sentence of context per major result
>   3) **eli5** — plain language, no jargon, conversational
>
> Pick one (default: dev). You can change anytime with /g-voice."

Map `1`/`d`/`dev` → `dev` · `2`/`m`/`mid` → `mid` · `3`/`e`/`eli5` → `eli5` · anything else/empty → `dev`. Write to `.claude/voice-profile`.

**Question 2 (integration tier):**
> "How present should G-Forge be?
>   1) **full** — all hooks fire; /g-plan, /g-execute, /g-review auto-trigger (default)
>   2) **balanced** — state info only; you invoke skills manually; commit gate still on
>   3) **light** — workflow-checkpoint only; commit gate off (opt-out mode)
>
> Pick one (default: full). You can change anytime with /g-tier."

Map `1`/`f`/`full` → `full` · `2`/`b`/`balanced` → `balanced` · `3`/`l`/`light` → `light` · anything else/empty → `full`. Write to `.claude/integration-tier`. On `light`, print the consequence line for the active voice profile from `references/onboarding.md`.

Report:
```
  ✓ .claude/voice-profile — [resolved]
  ✓ .claude/integration-tier — [resolved]
```

## Step 7b — Specialize for the stack

Run **`/g-specialize`** — read `[plugin-root]/skills/g-specialize/SKILL.md` and follow it. It detects the stack (brief + dependency manifests), confirms with the developer, and installs the matching architect agent + rules. Honor any conflict preference recorded in Step 1b (skip/overlay rules/agents — never overwrite existing `.claude/agents/` or `.claude/rules/` files without the permission already given). No detectable stack → skip and note `/g-specialize` can run later.

## Step 8 — Report

```
G-Forge ready ✓

  ✓ g-docs/project_brief.md — [via /g-onboard | via /g-kickoff | already present]
  ✓ CLAUDE.md — G-Forge rules injected
  ✓ G-RULES.md — installed
  ✓ .claude/rules/g-rules-*.md — [RULES_INSTALLED] rule section files installed
  ✓ g-docs/ROADMAP.md — created with the Active Session handoff (or already existed)
  ✓ g-docs/milestones/M1.md — created (or already existed)
  ✓ g-docs/todo.md — created (or already existed)
  ✓ .gitignore — project artifacts excluded, project record tracked
  ✓ .claude/hooks/ — hooks + lib/ scripts installed (canonical from plugin cache)
  ✓ <git-hooks-dir>/pre-commit — installed | not overwritten (existing hook preserved)
  ✓ <git-hooks-dir>/lib/*.sh — installed | skipped (foreign pre-commit preserved)
  ✓ .claude/settings.json — hooks registered
  ✓ .claude/voice-profile — [chosen voice]
  ✓ .claude/integration-tier — [chosen tier]
  ✓ Stack — [specialized: <stack> architect + rules installed | no stack detected yet — run /g-specialize once it exists]

You're set up and ready to work. Next: run /g-plan with your first feature request, or edit g-docs/milestones/M1.md to define your scope.
Tip: run /g-wiki anytime to start a human-facing project wiki in g-wiki/ — it's also refreshed automatically at the end of every milestone.
```

Then print the MCP recommendations from `references/recommended-mcps.md`.

## Rules
- Never create a file that already exists without reading it first (the scripts follow the same rule — skeletons are create-only, G-Forge-managed copies overwrite).
- If g-docs/project_brief.md exists at the project root, use its content to pre-fill g-docs/ROADMAP.md and g-docs/milestones/M1.md.
- Settings.json merge must never drop existing hooks — read before writing.
- Step 1a's self-host detection is the single source-root resolution point — `[plugin-root]` is resolved there and reused everywhere; never hardcode `~/.claude/plugins/cache/...` outside that step's fallback branch.

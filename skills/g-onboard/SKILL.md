---
name: g-onboard
description: Onboard G-Forge onto an existing codebase. Reads deeply before asking anything — treats existing CLAUDE.md, rules, agents, and task ledgers as first-class inputs. Only interviews for what it genuinely doesn't know yet. Produces or updates g-docs/project_brief.md.
---

**Announce:** "Using g-onboard to onboard this codebase."

You read before you ask. Questions are grounded in what you observed, targeted to what you don't yet know. Never ask for information already visible in the project.

---

## Step 1 — Deep read

Read every source that exists — skip silently if absent.

**Directory structure:**
List the project root (top 2 levels). Note top-level directories and their apparent purpose.

**Core files:**
- `README.md`
- `CLAUDE.md` — read fully if present; note length, structure, and whether G-Forge rules are embedded
- `g-docs/project_brief.md` — read fully if present
- `package.json` / `pyproject.toml` / `Cargo.toml` / `build.gradle` / `pubspec.yaml` — whichever exist
- `requirements.txt`
- `g-docs/ROADMAP.md` — note milestone status
- `g-docs/todo.md` — read fully if present; note schema, blocked tasks, active branch references
- `g-docs/todo-done.md` — note if present (signals an active task ledger convention)

**G-Forge state:**
- `.claude/rules/` — list all files if directory exists
- `.claude/agents/` — list all files if directory exists
- `.claude/settings.json` — check if commit hook is registered

**Version / branch signals:**
- Run `git log --oneline -5` — note recent commit messages and cadence
- Run `git branch --show-current` — note active branch name
- Run `git status --short` — note uncommitted changes

**Test structure:**
Look for `tests/`, `test/`, `__tests__/`, `spec/` directories. Note framework and file count.

**Architecture signals:**
Look for layer directories: `routes/`, `controllers/`, `services/`, `repositories/`, `models/`, `stores/`, `composables/`, `schemas/`, `middleware/`.

---

## Step 2 — Assess project maturity

Before presenting findings or asking anything, classify the project:

**Mature** — ANY of these are true:
- `CLAUDE.md` is >100 lines
- `.claude/rules/` has files
- `.claude/agents/` has files
- `g-docs/project_brief.md` exists and is complete
- `g-docs/ROADMAP.md` shows multiple completed milestones
- `git log` shows >20 commits

**Early-stage** — project exists but is sparse: CLAUDE.md present but thin, <20 commits, no rules/agents, no brief.

**Greenfield** — essentially empty: no CLAUDE.md, no brief, no meaningful structure yet.

This classification changes what you do in Steps 3 and 4.

---

## Step 3 — Present findings

Present a concise picture. Use this format:

```
Codebase read ✓

Stack:           [detected stack]
Entry point:     [file — or "not found"]
Architecture:    [layers found — or "flat" — or "see CLAUDE.md"]
Tests:           [framework · N files — or "no test directory found"]
Branch:          [current branch name]
Commits:         [e.g. "active — 3 commits today" or "last commit 6 days ago"]

G-Forge state:
  CLAUDE.md:     [Not present / Thin (<50 lines) / Detailed (Nnn lines, G-rules embedded)]
  .claude/rules: [Not present / N files: rule1.md, rule2.md]
  .claude/agents:[Not present / N files: agent1.md, agent2.md]
  Commit gate:   [Registered in settings.json / Not registered]
  project_brief: [Not found / Found (Nnn lines)]
  Task ledger:   [Not found / g-docs/todo.md found (N tasks, N blocked)]
```

Then — **for mature projects only** — add a targeted observations block:

```
Observations:
  - [e.g. "Active branch 'feat/audio-pipeline-fixes' — should this merge before new work?"]
  - [e.g. "g-docs/todo.md shows tasks #4 and #5 blocked on external input — are those the active scope?"]
  - [e.g. ".claude/agents/architecture-review.md already exists — specialize should not overwrite it"]
  - [e.g. "CLAUDE.md is 400 lines with architecture + rules — g-docs/project_brief.md may be redundant"]
```

Only include observations that are genuinely actionable. Omit the block entirely for greenfield projects.

Ask: **"Does this match what you're working with? Anything to correct?"**

Wait for confirmation before continuing.

---

## Step 4 — Resolve G-Forge state conflicts

Before interviewing, resolve any existing G-Forge infrastructure so specialize doesn't clobber it.

**If `.claude/rules/` has files:**
> "I found existing rules in `.claude/rules/`: [list files]. When we run `/g-specialize`, it will install architect rules. Should it overlay (append to existing), replace, or skip rules installation entirely?"

Wait for answer. Record preference.

**If `.claude/agents/` has files:**
> "I found existing agents in `.claude/agents/`: [list files]. When we run `/g-specialize`, it will install a stack-specific architect agent. Should it overlay, replace, or skip agent installation?"

Wait for answer. Record preference.

**If `CLAUDE.md` is >100 lines and G-Forge rules are already embedded:**
> "Your CLAUDE.md already has G-Forge rules embedded. `/g-init` would normally inject them — should I skip that injection and treat your current CLAUDE.md as authoritative?"

Wait for answer.

**If `g-docs/todo.md` exists with an established schema:**
> "I see a `g-docs/todo.md` already in use with its own schema. G-Forge's init scaffold would normally create one. Should I: (a) integrate with your existing g-docs/todo.md, (b) scaffold alongside it, or (c) skip g-docs/todo.md scaffolding?"

Wait for answer.

**If `g-docs/project_brief.md` already exists and CLAUDE.md is detailed (>100 lines):**
> "You have both a `g-docs/project_brief.md` and a detailed `CLAUDE.md`. Should I treat `CLAUDE.md` as the brief, update `g-docs/project_brief.md` from it, or keep both?"

Wait for answer.

Skip any of the above that don't apply.

---

## Step 5 — Interview: only what you don't know yet

**For mature projects** — the stack, architecture, and history are visible. Ask only what the files can't tell you:

Build the interview from what you actually observed. Examples:

- If branch name is `feat/X` or `fix/Y`: "You're on `[branch]` — are you merging that before planning new work, or should I scope the brief around it?"
- If g-docs/todo.md has blocked tasks: "g-docs/todo.md shows [task N] blocked on [reason] — is that still blocked, or should I treat it as active scope?"
- If g-docs/ROADMAP.md shows a milestone in progress: "ROADMAP shows [M-N] is in progress — is that still the active milestone, or has scope shifted?"
- If no explicit goal is inferable: "What do you want to do next with this project?"

Do not ask questions whose answers are already visible. Do not run Group 1–4 as a script — pick only the questions that apply.

**For early-stage and greenfield projects** — run the full interview:

**Group 1 — The work**
> "What do you want to do with this codebase?"

Follow up: new feature → "What specifically?", refactor → "Which area, what's driving it?", performance → "Where is it slow?"

**Group 2 — Constraints**
> "What constraints matter? Timeline, team size, areas that are fragile or off-limits."

**Group 3 — Existing problems**
> "Any known bugs, tech debt, or fragile areas to avoid building on top of?"

**Group 4 — Stack confirmation** (only if ambiguous)
> "I detected [stack]. Accurate? Any other runtimes or services I should know about?"

---

## Step 6 — Optional architecture audit

Ask:
> "Should I dispatch code-lead to audit the current architecture before planning? Worth it if you're planning significant changes. (y/n)"

**If yes:** dispatch `code-lead` with the structure, stack, architecture signals, and planned work. Ask it to flag violations at code-lead's own severity scale — Critical / Major / Minor. Present findings. Ask: "Address these first, or factor them into the brief as known risks?"

**If no:** proceed.

---

## Step 7 — Produce or update g-docs/project_brief.md

**If CLAUDE.md is the agreed source of truth** (developer chose that in Step 4): synthesize a brief from it rather than re-interviewing. Extract: stack, architecture, current goals, constraints. Write a short `g-docs/project_brief.md` that summarises what CLAUDE.md contains — don't duplicate it wholesale.

**Otherwise:** write `g-docs/project_brief.md` with:

```markdown
# [Project name]

## Current state

**Stack:** [detected]
**Architecture:** [layers observed or "see CLAUDE.md"]
**Tests:** [framework · count]
**Entry point:** [file]

## Problem / Goal

[What the developer wants to accomplish]

## Scope

### In scope
[Confirmed features or changes]

### Out of scope
[Constraints, fragile areas, off-limits]

### Known risks / existing issues
[Tech debt, fragile areas, architecture audit findings]

## Tech decisions

| Component | Choice | Rationale | Risk | Code-lead note |
|-----------|--------|-----------|------|----------------|

## Technical constraints

[Deadline, team size, off-limits areas]
```

If `g-docs/project_brief.md` already existed, merge — preserve accurate existing content.

---

## Step 8 — Report and next steps

```
g-docs/project_brief.md written ✓

Suggested next steps:
```

Build the next-steps list based on what's actually missing — don't suggest steps that are already done:

- Include `/g-forge init` only if: commit gate not registered OR CLAUDE.md is missing OR g-docs/ROADMAP.md is missing
- Include `/g-forge specialize` only if: no stack-specific architect agent is installed yet (or developer chose overlay/replace in Step 4)
- Always include `/g-forge plan` when ready to start the work described in the brief

If architecture audit found BLOCKING or HIGH issues, add: "Before `/g-forge plan`, consider addressing the architecture issues code-lead flagged."

---

## Rules

- Never write `g-docs/project_brief.md` before Steps 4 and 5 are complete.
- Never ask for information already visible in the project files.
- Never suggest `/g-forge init` or `/g-forge specialize` steps that are already done.
- Never overwrite existing `.claude/agents/` or `.claude/rules/` files without explicit developer permission from Step 4.
- Mature project interview is targeted — not a script. Only ask what you genuinely don't know.
- If the developer corrects your Step 3 reading, update before continuing.

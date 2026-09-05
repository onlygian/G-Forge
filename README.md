# G-Forge

> **Educated, enforced project management for AI development.** Make any model ship like a senior team — planned, reviewed, and context-clean.

**Version 2.6.1** · [Changelog](CHANGELOG.md) · [Roadmap](g-docs/ROADMAP.md)

G-Forge installs a structured engineering *process* into any Claude Code project: a project-manager layer that challenges scope and sequences risk, parallel implementation waves, and a commit gate that **can't be skipped** — only opened by code-lead review. The point isn't a smarter model; it's discipline that lets the model you already have punch above its weight.

---

## Evidence

G-Forge runs on its own repository, so the records below are the ones it produced about itself. They are linked as-is, including the parts that did not go well.

- **[Benchmark methodology](g-docs/benchmark.md)**: the falsifiable design for testing whether the process actually raises a model's task-success and hygiene rates against the same model run raw, plus the [2026-08-13 pilot](g-docs/benchmark-pilot-2026-08-13.md) that gated it. The pilot verdict was *do not fund n ≥ 20 on this design*; the methodology stands superseded-pending-revision, and no lift figure is claimed anywhere in this README.
- **[Telemetry metrics](g-docs/telemetry-metrics.md)**: definitions, sources and formulas for the 8 reliability metrics `/g-telemetry` computes (hallucination, review catch, regression, rework, spec deviation, escalation, token efficiency, retry dependency), derived from a project's own retros, forecasts, closed-task archive and git log. Session-local, no remote collection.
- **[Architectural decision records](g-docs/decisions/)**: 13 numbered ADRs covering the decisions that shaped the current design, each with its context, the alternatives rejected, and its consequences.
- **[Adversarial inbox](g-docs/inbox/adversarial/)** (consumed verdicts move to [`g-docs/archive/inbox-adversarial/`](g-docs/archive/inbox-adversarial/)): verdicts on G-Forge's own pattern reports, written into this repo by an n8n workflow running OpenAI's `gpt-4o` — a deliberately non-Anthropic second opinion, so the adversarial pass isn't the same model family grading its own homework. The integration is experimental; the verdicts so far have all been REJECT and mostly generic, which is itself a recorded finding. `/g-patterns` reads them during its resolve phase, screens them as untrusted data rather than instructions, and weighs them against the developer's judgement. They are advisory and never authoritative.

---

## Where G-Forge is headed

**G-Forge 2.5 is the last feature release.** Where I want to take this next needs a rework deep enough that I couldn't honestly promise stable releases while it was underway. Quietly destabilising something people rely on is worse than drawing a clean line, so this is the line.

Frozen isn't abandoned. I run G-Forge on my own projects, so its bugs are my bugs and they'll keep getting fixed — that's what GitHub issues on this repo are for: when something breaks or gets in your way, file an issue, and reasonable feature feedback travels the same route. And 2.5 is the version I'll build the next thing with, which is the real reason for freezing it: you want something stable under your feet while you're building its successor.

### What's next

Three things G-Forge kept running into and can't reach from where it stands.

**Knowing how much something matters.** Every part of the system currently judges importance on its own, mostly by feel. Priority, severity, impact and relevance should be one shared idea the whole system reasons with.

**Memory that behaves like memory.** Today the record is a well-organised pile of documents. It should be something a session can walk and follow, pulling exactly the slice the task needs.

**More than one of you.** One project, several people or several sessions, working at once without silently colliding.

Each of those is a layer that has to run through everything the system does, and you don't retrofit that. That's the rebuild, and it's called G-Proof. There's more to it than these three, and it isn't ready to be described. No date.

### What shipped in 2.5

**Planning that doesn't invent work.** Task breakdown used to split jobs that belong together and hand each fragment to its own agent. The sizing fix is in, so you stop paying for coordination you never needed.

**Reference material stops being mis-gated.** Committed reference material a project builds against was being blocked as though G-Forge owned it. That's fixed.

**Forecast risk replaces a percentage that nobody believed.** Plan-time risk estimates now show what the formula actually predicts instead of a percentage you've learned to ignore.

**Documentation that can't quietly rot.** The health check now flags hand-typed facts in your CLAUDE.md that aren't sourced from a file (unless you've explicitly marked them as local). That's how those facts go stale without anyone noticing.

---

## Why G-Forge

Most AI coding tools are built around a single idea: automate as much as possible and get the human out of the loop. The result is tools that are complex to configure, fragmented across a dozen commands, and optimised for the appearance of productivity — not for whether the project actually succeeds.

G-Forge is built on a different assumption: **the human is the most valuable part of the loop.** Claude handles the structured, repetitive, and cost-optimisable work. The decisions that determine whether a project succeeds — what to build, in what order, and whether it's actually done — stay with you.

Most tools in this space are **agent orchestrators** — they dispatch and review agents. G-Forge is something else: a **governance layer**. Three pillars carry it:

- **Educated** — a PM that *reasons*: it challenges scope before it's a commitment, sequences milestones by dependency, runs a premortem when the plan changes, and checks drift against the brief. Judgment-shaped, not a template.
- **Enforced** — gates with *teeth*. The commit gate is a git hook, not a suggestion: nothing merges until code-lead issues MERGE READY. Every comparable workflow enforces review advisorily; G-Forge enforces it infrastructurally.
- **Context-clean** — reliability held session-wide. Single-use agents, off-context decision deliberation, and a depth gate that resets *before* the window compacts keep the model trustworthy deeper into the work.

The result is the bet: discipline lets a cheaper or smaller model ship at a higher success and hygiene rate than it would raw. Not a smarter model — a better-run one. *(It is a bet, not a measurement: [g-docs/benchmark.md](g-docs/benchmark.md) holds the head-to-head methodology written to test it, and the pilot that sent that methodology back for revision before any number was produced.)*

That means:

- **Project management is a first-class concern.** `/g-roadmap` doesn't fill in a template — it challenges your feature list, narrates its grouping assumptions, justifies the milestone sequence, and plans version targets before writing a single line. `/g-kickoff` questions scope before it becomes a commitment. The plan approval gate means nothing executes until you've seen the full wave schedule and said yes.
- **Every merge decision requires human sign-off.** The commit gate is locked until `/g-review` issues MERGE READY. HOLD means fix everything listed, no partial merges. Tier 3 smoke testing is yours — Claude collects findings but never substitutes your judgment on whether the app actually works.
- **Token cost is optimised, not token count.** Haiku handles reads and searches, Sonnet implements, Opus reviews. The same work costs less because it lands on the right model tier. Structured planning eliminates the back-and-forth and rework cycles that burn expensive tokens without producing output.

The goal isn't to automate your project. It's to give it a better chance of succeeding.

---

## How G-Forge works

Six concepts explain almost everything.

### 1. Skills vs Agents

**Skills** are commands you type (`/g-forge plan`, `/g-forge review`, etc.). They run in the main Claude session — the one you're talking to. Skills read the project state, make decisions, and coordinate work. You interact with them directly.

**Agents** are spawned subagents. Skills dispatch agents to do the actual work — implementing, reviewing, writing tests. Agents run in isolated sessions and return a compact summary. You never talk to an agent directly.

The main session stays thin. Agent sessions spend tokens doing work.

### 2. HQ and the wave model

The main session is HQ. HQ decomposes a task into atomic pieces (via `task-decomposer`), schedules them into parallel waves (via `wave-planner`), dispatches agents to run each wave, and checks results. HQ never implements. Agents never commit.

A **wave** is a batch of tasks that can run in parallel without depending on each other. Wave 1 must fully complete before Wave 2 starts. Within a wave, all tasks are dispatched simultaneously. A BLOCKED result in any task halts the wave immediately — the session surfaces the blocker with a diagnosed fix strategy before proceeding.

### 3. The commit gate

Every `git commit` in a G-Forge project is blocked by a pre-commit hook. The hook classifies the staged file set into one of five buckets: **code** (code only), **doc** (documentation only), **mixed** (both), **reference** (reference material only — exempt with an advisory, no sentinel), or **none** (empty staged set — fall through to the code gate). Based on the classification, it requires the matching review sentinel:

- **Code commits** require `.claude/g-forge-approved`, written only when `/g-review` issues a **MERGE READY** verdict after the full review pipeline passes.
- **Doc-only commits** (README, `g-wiki/`, ADRs, etc.) require `.claude/g-forge-docs-approved`, written only when `/g-doc-review` issues a **DOCS READY** verdict — so documentation is gated even when there's no code change.
- **Mixed commits** require **both** sentinels.

Both sentinels are consumed (deleted) on every successful commit, so each commit cycle requires a fresh review.

### 4. G-RULES.md

`/g-init` installs `G-RULES.md` at the project root and wires it into `CLAUDE.md` via `@G-RULES.md`. Every session loads it. It governs model selection, planning discipline, the wave model, review requirements, code quality rules, architecture constraints, testing protocol, and memory management — ten sections in total. Claude follows it without prompting.

You don't configure G-Forge per session. You configure it once via G-RULES.md and it stays consistent.

### 5. Hooks

Seven shell scripts registered in `.claude/settings.json` keep Claude oriented automatically:

- **UserPromptSubmit** (`workflow-checkpoint.sh`) — fires on every message. Reports branch, milestone context, active wave, review gate status, and context depth. Claude reads this output and auto-triggers the right skill (`/g-plan` for a new task, `/g-execute` once a plan is approved, `/g-review` when waves finish).
- **PreToolUse** (`check-commit.sh`) — classifies the staged file set (code / doc / mixed / reference / none) and blocks `git commit` unless the matching review sentinel exists; reference-only commits are exempt with an advisory note.
- **PostToolUse** (`post-commit-cleanup.sh`, `observe.sh`) — clears both sentinels after a successful commit, and runs the **silent observer**, which journals meaningful events (commits, branches, tests, pushes, reverts) to `.claude/journal/YYYY-MM-DD.jsonl`.
- **SessionStart** (`session-start.sh`, `observe.sh`) — checks local and remote git state (uncommitted changes, stash count, ahead/behind), marks the session open in the journal, and resets the context-depth counters on a genuine open — carrying them across a `compact` or `resume` restart so auto-compaction (or a reloaded transcript) can't silently reset the gate.
- **SubagentStart / SubagentStop** (`agent-lifecycle.sh`) — records every agent dispatch into the same journal.
- **PreCompact** (`pre-compact.sh`) — writes a handoff snapshot before context compaction so the next session knows exactly where to resume, and records the compaction so the context gate tightens to prevent the next one.

The hooks are the reason you don't have to type commands for the day-to-day loop. Claude sees the state on every message and responds to it.

They're registered in exactly one place — your project's `.claude/settings.json`, by `/g-init` (and realigned by `/g-update`) — **not** the plugin manifest, so they never double-fire. Each script also self-guards on `.claude/integration-tier`, so it stays completely inert in any repo that hasn't run `/g-init`: no commit gate, no output, nothing. `/g-doctor` diagnoses issues read-only (Check 23 flags plugin version lag, directing to `/plugins` or `/g-update` by direction) and detects any accidental duplicate registration.

### 6. The silent observer

The observer is a passive recorder, not a participant. As you work, it appends a one-line-per-event journal to `.claude/journal/` — what was committed, what branch you cut, when tests ran, which agents were dispatched, any revert or destructive command. It writes **nothing** to the chat and never interrupts. When you run `/g-retro`, it synthesizes the retrospective from that journal plus git and `g-docs/todo.md` — no end-of-session interview. You verify the output instead of reconstructing the session from memory. The observer is off on the `light` tier.

---

## Documentation Index

The G-wiki provides deeper dives into everything G-Forge does:

- **[g-wiki/README.md](g-wiki/README.md)** — Wiki home
- **[g-wiki/usage.md](g-wiki/usage.md)** — Getting Started: install lifecycle, per-task workflows, session rhythm
- **[g-wiki/reference.md](g-wiki/reference.md)** — Reference: full catalog of skills, agents, stack profiles
- **[g-wiki/commit-gate.md](g-wiki/commit-gate.md)** — Commit Gate: enforcement, sentinel flow, hook architecture
- **[g-wiki/architecture.md](g-wiki/architecture.md)** — Architecture: layer model, skills vs agents, dispatch matrix

---

## Install

### Prerequisites

- **Claude Code** — desktop app, CLI, or IDE extension. [claude.ai/code](https://claude.ai/code)
- **Git** — required for commit enforcement hooks
- **`jq`, Python 3, or Node**: the hooks parse their stdin JSON with `jq` when it is present, and fall back to `python3` (and, in `observe.sh`, to `node`). Any one of the three is enough, and Python 3 is pre-installed on most systems

### Install the plugin

#### Via CLI

`/plugin` is only available in the Claude Code CLI. Open a terminal and run `claude`, then:

```bash
/plugin marketplace add onlygian/G-Forge
/plugin install g-forge
```

All **19** G-Forge agents, **38** skills, 48 stack profiles, 7 combo profiles, and 1 supplementary profile (frontend-data-flow) become available globally across all your projects.

#### Desktop app, VS Code, JetBrains

`/plugin` is not available in these interfaces. Use the CLI to install — the plugin is registered globally and will be available in all Claude Code interfaces once installed:

```bash
# In a terminal:
claude
/plugin marketplace add onlygian/G-Forge
/plugin install g-forge
```

Then open the desktop app or IDE extension as normal — the agents and skills will be available.

### Update the plugin

Run `/g-forge update` inside any project that uses G-Forge. It does everything in one pass:

1. **Staleness preflight** (Step 0) — compares the plugin cache version against GitHub latest. If the cache is behind, `/g-update` **stops with zero writes** and directs you to `/plugins` → Installed → g-forge → Update now — then re-run `/g-update` to sync once the cache is current.
2. Syncs all project-level files (hooks, CLAUDE.md rules, G-RULES.md, architect agents, architecture rules) to the current cache version.

The `workflow-checkpoint.sh` hook fetches the latest version from GitHub once per day (background, zero latency) and surfaces a notice in every session until you update:

```
⚡ G-Forge update available: 2.0.0 → 2.1.0 — run /g-update to pull and sync
```

For a read-only diagnosis of version alignment at any time (not just before a sync) — including which leg is behind and why — run `/g-doctor` Check 23. It never writes and points at the right direction (`/plugins` or `/g-update`).

#### Load per-session (without installing)

For development or one-off use, load directly via the `--plugin-dir` flag:

```bash
git clone https://github.com/onlygian/G-Forge.git
claude --plugin-dir ./G-Forge
```

This loads G-Forge for that session only. Re-run with `--plugin-dir` each time, or use the CLI install above for permanent access.

### Verify

Type `/g-forge help` in any Claude Code session (or the direct form `/g-forge:g-help`). You should see the current project state and a full command reference. Every skill is invoked either as a `/g-forge <token>` subcommand or via its direct per-skill registration `/g-forge:g-<name>` — tokens: `help`, `status`, `resume`, `doctor`, `audit`, `init`, `kickoff`, `onboard`, `brief`, `roadmap`, `intake`, `plan`, `forecast`, `blast-radius`, `execute`, `review`, `doc-review`, `align`, `afk`, `specialize`, `update`, `skill-design`, `skill-validate`, `adr`, `docs`, `wiki`, `patterns`, `telemetry`, `identity`, `retro`, `listen`, `optimize`, `refactor`, `train`, `trim`, `tier`, `voice`, `roundtable`.

### Set up — new or existing project

Run **one** command in your project directory:

```bash
/g-forge init # the single front door
```

`/g-init` detects what's there and drives the whole setup itself — you don't have to know which command comes first:

1. **Intake** — routes to `/g-kickoff` (new/empty project: interview → brief) or `/g-onboard` (existing codebase: deep-read the repo → resolve conflicts → brief). Skipped if a `g-docs/project_brief.md` already exists.
2. **Scaffold** — CLAUDE.md (G-rules injected), G-RULES.md, g-docs/ROADMAP.md (with the `## Active Session` handoff), g-docs/milestones/, g-docs/todo.md, seven event hooks, six shared lib scripts, and the native git `pre-commit` gate.
3. **Specialize** — runs `/g-specialize` to detect your stack and install the architect agent, the matching implementer agent, and architecture rules.

You end up ready to `/g-plan`. After `/g-init`, `git commit` is gated — it blocks until `/g-review` issues MERGE READY.

<details>
<summary>What <code>/g-init</code> writes into <code>.claude/hooks/</code></summary>

```
.claude/hooks/session-start.sh          (SessionStart — repo sync + context reset)
.claude/hooks/workflow-checkpoint.sh    (UserPromptSubmit — state + context depth)
.claude/hooks/check-commit.sh           (PreToolUse — commit gate)
.claude/hooks/post-commit-cleanup.sh    (PostToolUse — sentinel cleanup)
.claude/hooks/observe.sh                (PostToolUse + SessionStart — silent-observer journal)
.claude/hooks/agent-lifecycle.sh        (SubagentStart/Stop — agent journal)
.claude/hooks/pre-compact.sh            (PreCompact — handoff snapshot)
.claude/hooks/lib/commit-detect.sh      (commit detection, shared)
.claude/hooks/lib/worktree-resolve.sh   (worktree resolution, shared)
.claude/hooks/lib/classify-changeset.sh (changeset classification, shared)
.claude/hooks/lib/sentinel-read.sh      (sentinel stamp parsing, shared)
.claude/hooks/lib/stdin-read.sh         (stdin read-timeout guard, shared)
.claude/hooks/lib/semver-compare.sh     (version ordering, shared)
```

All seven event hooks are registered in `.claude/settings.json` (the plugin manifest registers none), and the native git `pre-commit` hook is installed into the repository's git hooks path with a clobber guard.
</details>

Each sub-step is still available standalone if you want manual control: `/g-forge kickoff`, `/g-forge onboard`, `/g-forge roadmap`, `/g-forge specialize`.

### Uninstall

```bash
/plugin uninstall g-forge
```

Removes the plugin globally. Per-project commit hooks (installed in `.claude/hooks/` and registered in `.claude/settings.json`) must be removed manually from each project.

---

## G-RULES.md

`/g-init` installs `G-RULES.md` at the project root and references it via `@G-RULES.md` in `CLAUDE.md`. This gives every session full project discipline without bloating `CLAUDE.md`. The ten sections (Session Rules, G-Forge Workflow, Agent Discipline, Code Quality, Architecture Gate, Design Patterns, Documentation, Testing Protocol, Project Tracking, and Memory) can be imported individually to reduce per-session token cost — a minimal project needs only sections A, B, C, and D. Full rules reference, presets, and design pattern details: [g-wiki/reference.md](g-wiki/reference.md).

---

## Workflow

```
New project:
/g-forge kickoff →   g-docs/project_brief.md  (goals, scope, tech decisions)

Existing project:
/g-forge onboard →   g-docs/project_brief.md  (current state + planned work)

Then for both:
/g-forge init  →   scaffolded project + commit gate + workflow hooks
/g-forge roadmap →   features → milestones → g-docs/ROADMAP.md
/g-forge specialize →   stack architect + implementer agents + architecture rules

Day-to-day (auto-triggered — no command needed):
/g-forge plan  →   approved wave schedule  →  saved to g-docs/plans/
/g-forge execute →   parallel agent swarming, wave by wave
/g-forge review →   MERGE READY or HOLD  →  milestone tasks auto-closed → /g-retro auto-runs → /g-doctor every other milestone
git commit          →   gate clears, sentinel removed

Unattended execution (requires approved plan):
/g-forge afk   →   all waves + review, no check-ins  →  handoff report when done

Project hygiene:
/g-forge brief →   refresh g-docs/project_brief.md as project evolves
/g-forge help  →   where am I + what to do next
/g-forge status →   fast state snapshot
/g-forge doctor →   verify hooks, settings, rules block, and drift — 25 checks (16 required + 9 advisory)
/g-forge update →   pull latest G-Forge rules into this project
```

Full orchestration pattern reference: [g-docs/orchestration-patterns.md](g-docs/orchestration-patterns.md)

---

## Commit Enforcement

When you run `/g-init`, seven event hooks plus six shared lib scripts are installed into `.claude/hooks/`, and a native git `pre-commit` gate is installed into your repository. These enforce code and documentation review, track context depth, and maintain a silent journal of meaningful events. All hooks are registered in `.claude/settings.json` (never the plugin manifest), so they can't double-fire; each self-guards on `.claude/integration-tier` and stays inert outside G-Forge projects. Details: [g-wiki/commit-gate.md](g-wiki/commit-gate.md).

---

## Skills

All **38** G-Forge skills are listed in [g-wiki/reference.md](g-wiki/reference.md).

---

## Agents

**19** agents ship with every install. Full reference: [g-docs/agents.md](g-docs/agents.md)

For a complete agent catalog with descriptions, dispatch rules, output architecture, and single-use discipline, see [g-wiki/reference.md](g-wiki/reference.md).

---

## Token cost saving strategy

G-Forge applies cost controls at every layer: model tiering (Haiku for reads, Sonnet for planning, Opus for review), selective G-RULES loading (import only sections your project needs), compact agent returns (70 tokens per agent instead of 1,500+), context depth gates that reset before compaction, pre-plan budget checks, and wave-based parallelism. Each control compounds with the others. Full technical explanation: [g-wiki/architecture.md](g-wiki/architecture.md).

---

## Stack Profiles

48 stack profiles ship with the plugin, auto-detected from your project's dependencies when you run `/g-specialize`. Each adds architect and implementer agents plus architecture rules. See [g-wiki/reference.md](g-wiki/reference.md) for the complete catalog.

---

## First steps

Run these commands in order in your first session:

1. `/g-forge kickoff` (new project) or `/g-forge onboard` (existing project)
2. `/g-forge init` — scaffolds CLAUDE.md, hooks, commit gate
3. `/g-forge roadmap` — plan features into milestones
4. `/g-forge plan` — create your first wave
5. `/g-forge execute` — run the plan

For detailed per-workflow instructions (refactoring, debugging, training mode, performance audits, dependency checks, and more), see [g-wiki/usage.md](g-wiki/usage.md).

---

## Roadmap

| Milestone | Status |
|-----------|--------|
| M1 — Foundation | ✅ Done |
| M2 — Agent Roster | ✅ Done |
| M3 — Skills & Orchestration | ✅ Done |
| M4 — Stack Profiles | ✅ Done |
| M5 — Publish | ✅ Done |
| M6 — Auto-trigger & Project Hygiene | ✅ Done |
| M7 — Correctness, Validation & Polish | ✅ Done |
| M8 — Deploy & Use | ✅ Done |
| M9 — Intelligence Foundation | ✅ Done |
| M10 — Organizational Learning Loop | ✅ Done |
| M11 — Planning Intelligence | ✅ Done |
| M12 — Reliability & Adaptive Systems | ✅ Done |
| M13 — Profile Additions | ✅ Done |
| M14 — Advanced Production Modeling | ✅ Done |
| M15 — Hook / Behavioral Integration Pass | ✅ Done — **v1.0.0** |
| M16 — Agent Hardening & Rules Decentralization | ✅ Done — **v1.2.0** |
| M17 — Token Optimization & Session Sync | ✅ Done — **v1.3.3** |
| M18 — Compact Return Architecture & Plan Derisking | ✅ Done — **v1.5.0** |
| M19 — Ambient Proactivity (silent observer · brief alignment · feature triage) | ✅ Done — **v1.6.0** |
| M20 — Single-Use Agent Doctrine (FAILED + learnings retry loop · context-poisoning fix) | ✅ Done — **v1.7.0** |
| M21 — Decision Hygiene Loop (off-context ADR deliberation · post-decision session reset) | ✅ Done — **v1.8.0** |
| M22 — Session Re-entry (`/g-resume` · selective re-hydration of the durable record) | ✅ Done — **v1.9.0** |
| M23 — G-Forge 2.0 (production-readiness audit · hooks reconciliation · consistency sweep) | ✅ Done — **v2.0.0** |
| M24 — Positioning & Reliability Methodology (+ stack implementers) | ✅ Done — **v2.0.1** |
| M27 — Documentation Review Gate | ✅ Done — **v2.1.0** |
| M28 — g-docs as the canonical home for all G-Forge documents | ✅ Done — **v2.2.0** |
| M-audit — Forge Integrity (technical debt audit · native pre-commit gate) | ✅ Done — **v2.3.0** |
| M46 — Update Integrity (detect / diagnose / fix split) | ✅ Done — **v2.4.0** |
| M47 — Planning-Pipeline Honesty | ✅ Done — **v2.4.1** |
| M48 — Review-Pipeline Hardening | ✅ Done — **v2.4.1** |
| M52 — v2.5 Minimal Freeze (hand-cut release; shipped under the then-standing "final release" decision, [ADR-012](g-docs/decisions/012-g-forge-2.5-final-release-scope.md)) | ✅ Done — **v2.5.0** |
| M53 — Token Diet ([ADR-014](g-docs/decisions/014-v26-token-diet-reopens-after-freeze.md) reopens development after the freeze): same governance, a fraction of the tokens — prose→scripts, lazy references, review pack + delta rounds, model economy | ✅ Done — **v2.6.0** |
| The **G-Proof** rebuild remains the successor plan, unscheduled (versioning restarts at G-Proof 1.0; there is no G-Forge 3.0) | — |

---

## License

G-Forge is free, open-source software, released under the **GNU General Public License v3.0** (GPL-3.0) — see [LICENSE](LICENSE).

Copyright © 2026 Gianmarco Palma. You're free to use, study, modify, and redistribute it under the GPL-3.0 terms; derivative works must stay under GPL-3.0 and preserve this notice. Full license text: <https://www.gnu.org/licenses/gpl-3.0.txt>.

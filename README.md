# G-Forge

> **Educated, enforced project management for AI development.** Make any model ship like a senior team — planned, reviewed, and context-clean.

**Version 2.4.1** · [Changelog](CHANGELOG.md) · [Roadmap](g-docs/ROADMAP.md)

G-Forge installs a structured engineering *process* into any Claude Code project: a project-manager layer that challenges scope and sequences risk, parallel implementation waves, and a commit gate that **can't be skipped** — only opened by a full multi-agent review. The point isn't a smarter model; it's discipline that lets the model you already have punch above its weight.

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

Frozen isn't abandoned. I run G-Forge on my own projects, so its bugs are my bugs and they'll keep getting fixed — that's what `/g-report` (ships in 2.5) is for: when something breaks or gets in your way, it writes a scrubbed report you can send me, and reasonable feature feedback travels the same route. And 2.5 is the version I'll build the next thing with, which is the real reason for freezing it: you want something stable under your feet while you're building its successor.

### What's next

Three things G-Forge kept running into and can't reach from where it stands.

**Knowing how much something matters.** Every part of the system currently judges importance on its own, mostly by feel. Priority, severity, impact and relevance should be one shared idea the whole system reasons with.

**Memory that behaves like memory.** Today the record is a well-organised pile of documents. It should be something a session can walk and follow, pulling exactly the slice the task needs.

**More than one of you.** One project, several people or several sessions, working at once without silently colliding.

Each of those is a layer that has to run through everything the system does, and you don't retrofit that. That's the rebuild, and it's called G-Proof. There's more to it than these three, and it isn't ready to be described. No date.

### What's coming in 2.5

**Lighter where you feel it most.** The review gate runs before every commit, and today it's one enormous pass that costs a fortune and starts losing the thread by the time it reaches the last thing it checks. 2.5 scopes it to what actually changed and splits it into small parallel passes with a cheap assembly step at the end. This one is measured, not promised: on this repo, an unscoped review ran ~3 hours and ~130k tokens before being killed; the same gate scoped ran 11 tool calls, 79k tokens, one round — and still caught a real blocker ([2026-08-17 retro](g-docs/retros/2026-08-17-m50-scope-and-scoped-review.md)).

**Planning that doesn't invent work.** Task breakdown currently splits jobs that belong together and hands each fragment to its own agent. 2.5 fixes the sizing, so you stop paying for coordination you never needed. *(Already shipped early — in v2.4.1.)*

**Every setting in one place you can see.** `/g-settings` lists every variable that governs G-Forge's behaviour: what it's set to, what writes it, and what it changes. Safe edits go through it. No more hidden files quietly deciding how your sessions run.

**A way to tell me when it breaks.** `/g-report` fires when something actually goes wrong, or whenever you call it. It asks what you want to report, writes it against an incident template, scrubs your project's specifics out, and hands you a file to send. Bugs and reasonable feature requests travel the same route.

**Gates that stop misfiring.** A passing review could fail to unlock the commit gate on some machines, which reads as G-Forge being broken. Committed reference material a project builds against was getting blocked as though G-Forge owned it. Both fixed. Plan-time risk percentages get recalibrated too, because a number you've learned to ignore is worse than no number at all. *(The recalibration already shipped early — in v2.4.1; the rest of this item is still coming.)*

**Instruments that measure what they claim.** G-Forge grades itself with telemetry, risk forecasts and coverage reports — and some of those gauges turned out structurally unable to register the failures they exist to catch (the agent-coverage table couldn't count two of the agents). 2.5 makes each instrument read the live ground truth it reports on, with tests that go red the moment the two drift apart.

**Documentation that can't quietly rot.** The health check now flags anything in your CLAUDE.md that's a hand-typed fact rather than one sourced from a file. That's how those facts go stale without anyone noticing. *(Already shipped early — in v2.4.1.)*

**Releases in one step.** Cutting a release stops being a manual walk through several files that has to be remembered correctly every time.

---

## Why G-Forge

Most AI coding tools are built around a single idea: automate as much as possible and get the human out of the loop. The result is tools that are complex to configure, fragmented across a dozen commands, and optimised for the appearance of productivity — not for whether the project actually succeeds.

G-Forge is built on a different assumption: **the human is the most valuable part of the loop.** Claude handles the structured, repetitive, and cost-optimisable work. The decisions that determine whether a project succeeds — what to build, in what order, and whether it's actually done — stay with you.

Most tools in this space are **agent orchestrators** — they dispatch and review agents. G-Forge is something else: a **governance layer**. Three pillars carry it:

- **Educated** — a PM that *reasons*: it challenges scope before it's a commitment, sequences milestones by dependency, runs a premortem when the plan changes, and checks drift against the brief. Judgment-shaped, not a template.
- **Enforced** — gates with *teeth*. The commit gate is a git hook, not a suggestion: nothing merges until a full review pipeline issues MERGE READY. Every comparable workflow enforces review advisorily; G-Forge enforces it infrastructurally.
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

**Agents** are spawned subagents. Skills dispatch agents to do the actual work — implementing, reviewing, writing tests. Agents run in isolated sessions, write their output to disk, and return a compact summary. You never talk to an agent directly.

The main session stays thin. Agent sessions spend tokens doing work.

### 2. HQ and the wave model

The main session is HQ. HQ decomposes a task into atomic pieces (via `task-decomposer`), schedules them into parallel waves (via `wave-planner`), dispatches agents to run each wave, and checks results. HQ never implements. Agents never commit.

A **wave** is a batch of tasks that can run in parallel without depending on each other. Wave 1 must fully complete before Wave 2 starts. Within a wave, all tasks are dispatched simultaneously. A BLOCKED result in any task halts the wave immediately — the session surfaces the blocker with a diagnosed fix strategy before proceeding.

### 3. The commit gate

Every `git commit` in a G-Forge project is blocked by a pre-commit hook. The hook classifies the staged file set as **code**, **doc**, or **mixed** and requires the matching review sentinel:

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
- **PreToolUse** (`check-commit.sh`) — classifies the staged file set (code / doc / mixed) and blocks `git commit` unless the matching review sentinel exists.
- **PostToolUse** (`post-commit-cleanup.sh`, `observe.sh`) — clears both sentinels after a successful commit, and runs the **silent observer**, which journals meaningful events (commits, branches, tests, pushes, reverts) to `.claude/journal/YYYY-MM-DD.jsonl`.
- **SessionStart** (`session-start.sh`, `observe.sh`) — checks local and remote git state (uncommitted changes, stash count, ahead/behind), marks the session open in the journal, and resets the context-depth counters on a genuine open — carrying them across a `compact` or `resume` restart so auto-compaction (or a reloaded transcript) can't silently reset the gate.
- **SubagentStart / SubagentStop** (`agent-lifecycle.sh`) — records every agent dispatch into the same journal.
- **PreCompact** (`pre-compact.sh`) — writes a handoff snapshot before context compaction so the next session knows exactly where to resume, and records the compaction so the context gate tightens to prevent the next one.

The hooks are the reason you don't have to type commands for the day-to-day loop. Claude sees the state on every message and responds to it.

They're registered in exactly one place — your project's `.claude/settings.json`, by `/g-init` (and realigned by `/g-update`) — **not** the plugin manifest, so they never double-fire. Each script also self-guards on `.claude/integration-tier`, so it stays completely inert in any repo that hasn't run `/g-init`: no commit gate, no output, nothing. `/g-doctor` diagnoses issues read-only (Check 23 flags plugin version lag, directing to `/plugins` or `/g-update` by direction) and detects any accidental duplicate registration.

### 6. The silent observer

The observer is a passive recorder, not a participant. As you work, it appends a one-line-per-event journal to `.claude/journal/` — what was committed, what branch you cut, when tests ran, which agents were dispatched, any revert or destructive command. It writes **nothing** to the chat and never interrupts. When you run `/g-retro`, it synthesizes the retrospective from that journal plus git and `g-docs/todo.md` — no end-of-session interview. You verify the output instead of reconstructing the session from memory. The observer is off on the `light` tier.

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

Each sub-step is still available standalone if you want manual control: `/g-forge kickoff`, `/g-forge onboard`, `/g-forge roadmap`, `/g-forge specialize`.

### Uninstall

```bash
/plugin uninstall g-forge
```

Removes the plugin globally. Per-project commit hooks (installed in `.claude/hooks/` and registered in `.claude/settings.json`) must be removed manually from each project.

---

## G-RULES.md

`/g-init` installs `G-RULES.md` at the project root and references it from `CLAUDE.md` via `@G-RULES.md`. This gives Claude full session discipline without bloating `CLAUDE.md`.

G-RULES.md has ten sections, each stored as a separate `@`-referenced file in `.claude/rules/`. This keeps the monolithic load optional — reference individual sections in `CLAUDE.md` to reduce per-session token cost.

| Section | What it governs |
|---------|----------------|
| **A — Session Rules** | Model selection, planning discipline, token optimisation, delivery standards, Three-Strikes escalation |
| **B — G-Forge Workflow** | Project lifecycle (kickoff → roadmap → init → specialize); per-task auto-trigger loop (plan/execute/review); maintenance skills reference table; hard stops |
| **C — Agent Discipline** | HQ vs. agent boundaries; wave model; when to spawn vs. inline; agent prompt requirements; agent caps |
| **D — Code Quality** | Style (const/let/var), naming conventions, comments, error handling, testing standards, component structure, branch discipline, versioning & release flow |
| **E — Architecture Gate** | Mandatory plan-first sequence for non-trivial changes; import direction validation; state ownership; hard stops |
| **F — Design Patterns** | Universal principles and anti-patterns (see below) |
| **G — Documentation** | What must be documented, currency rule, documentation ownership model |
| **H — Testing Protocol** | Three-tier test model (automated gates / tooling-assisted / human-driven); falsifiability rule for guard/negative tests (scratch-copy probe, provenance marker, Major finding if absent); QA panel integration and currency enforcement; Tier 3 listen-mode protocol |
| **I — Project Tracking** | File hierarchy, commit gate infrastructure, g-docs/todo.md structure |
| **J — Memory** | Six-tier memory layer taxonomy |

### Section F — Design Patterns

Section F encodes six universal principles: **composition over inheritance**, **explicit over implicit**, **YAGNI**, **fail-fast at boundaries**, **observer/event-driven**, and **state machine for discrete modes**. It also lists eight anti-patterns to refuse by default (god object, prop drilling, business logic in UI, mutable module-level state, premature abstraction, magic values, circular dependencies, catch-and-continue).

Stack-specific patterns — including object pooling rules for game-dev profiles and framework-specific idioms for web, mobile, and systems targets — live in `.claude/rules/architecture-<stack>.md`, installed by `/g-specialize`.

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

Once `/g-init` is run in a project, seven event hooks plus six shared lib scripts are installed into `.claude/hooks/`, and the native git `pre-commit` commit-gate hook is installed into the git hooks path with a clobber guard that never overwrites an existing user hook (all registered only in the project's `.claude/settings.json` — never the plugin manifest — so they can't double-fire; each also self-guards on `.claude/integration-tier` and stays inert outside a G-Forge project):

**`session-start.sh`** (`SessionStart`) — fires when a session opens. Runs `git fetch` in the background while checking local state, then reports: branch, uncommitted changes, stashed work, commits behind/ahead vs remote, and whether a feature branch has drifted behind `origin/main`. Resets the per-session prompt + compaction counters used for context-depth tracking — **except on a `compact` or `resume` start** (the same session continuing, after auto-compaction or with a prior transcript reloaded), where the counters carry across so the gate isn't silently zeroed.

**`workflow-checkpoint.sh`** (`UserPromptSubmit`) — fires on every message. Reports the current branch (warns if on `main`), active milestone context, review gate status, listen mode item count, context depth, and any available plugin update. Claude reads this and auto-triggers `/g-plan`, `/g-execute`, or `/g-review` based on current state.

Context depth uses mode-aware thresholds. **The goal is to reset before the window ever compacts** — a compaction means the gate fired too late. Sessions are classified as `implementation` (recent commits, dirty tree, or active plan files) or `conversation` (clean). Baselines start lenient and **auto-calibrate downward per project** — each compaction grows a persistent offset (floored) so the gate fires earlier next time until compaction stops:

| Mode | 🟡 Amber (baseline) | 🔴 Red (baseline) |
|---|---|---|
| implementation | ~30 exchanges | ~45 exchanges |
| conversation | ~45 exchanges | ~65 exchanges |

Amber is **active monitoring**, not a one-time warning: Claude runs `/context` every turn and resets the moment remaining capacity drops below ~25% — capacity-driven, not waiting for the red exchange count (only `/context` reads true context pressure, and only the model can run it). `/g-execute` adds the same `/context` check at every wave boundary — the heaviest token-burn point — catching fast-burning sessions the exchange count misses. At red it's enforced: no new scope, `/g-retro` auto-triggers, the user is told to open a fresh session. If a compaction still slips through, it's recorded as a backstop and tightens the threshold so it doesn't recur.

**`check-commit.sh`** (`PreToolUse`) — classifies the staged file set (code / doc / mixed) and blocks `git commit` unless the matching sentinel exists: `.claude/g-forge-approved` for code, `.claude/g-forge-docs-approved` for docs, both for mixed. Prints a non-blocking advisory when committing directly to `main` with approval.

**`post-commit-cleanup.sh`** (`PostToolUse`) — clears both sentinels after a successful commit.

**`observe.sh`** (`PostToolUse` + `SessionStart`) — the **silent observer**: journals meaningful events (commits, branches, tests, pushes, reverts) and session opens to `.claude/journal/YYYY-MM-DD.jsonl`. Writes nothing to chat; `/g-retro` synthesizes from it.

**`agent-lifecycle.sh`** (`SubagentStart` / `SubagentStop`) — records every agent dispatch into the same journal.

**`pre-compact.sh`** (`PreCompact`) — fires before context compression. Writes `.claude/compact-state.md` with the current branch, last 5 commits, and the `## Active Session` handoff block from `g-docs/ROADMAP.md`. Also records the compaction: it bumps a per-session count (the red backstop) and grows the persistent calibration offset so the context gate fires earlier next time.

The sentinel is written by `/g-review` only on a MERGE READY verdict, and removed automatically after each commit. Every commit goes through the full review pipeline — no exceptions. Subagents are prohibited from committing; HQ commits once after MERGE READY.

To bypass in an emergency (not recommended) — the gate is two layers, both must go:

```bash
rm .claude/hooks/check-commit.sh                        # PreToolUse layer only — commits still blocked
rm "$(git rev-parse --git-path hooks)/pre-commit"       # the authoritative native git gate (ADR-004)
```

### Consumer CLAUDE.md local-only marker convention

Projects that track `CLAUDE.md` as committed project record (consumer projects, as opposed to this repo where it's gitignored) may bracket hand-written local content — such as personal environment setup, development notes, or machine-specific paths — in a marker-delimited block:

```
<!-- G-Forge local-only: <slug> -->
...content...
<!-- End G-Forge local-only: <slug> -->
```

`<slug>` is a pairing key in lowercase kebab-case (e.g. `my-dev-setup`, `local-paths`). `/g-doctor` Check 24 uses this marker to classify declarations and detects unpaired or unclosed markers as advisory findings.

---

## Skills

| Skill | What it does |
|-------|-------------|
| `/g-forge help` | Context-aware state reader — detects current phase and outputs next action + full command reference |
| `/g-forge status` | Fast structured snapshot: milestone · active plan/wave · review gate · handoff line |
| `/g-forge resume` | Re-hydrate a fresh session with the right slice of the durable record — syncs with origin first (fast-forwarding only when safely possible, and only on session-start runs — a mid-session re-run compares and reports, never pulls), then selectively pulls the relevant retro, in-force ADRs, journal tail, and handoff into a clean window keyed to the first task, then points at the next action (offers the clean-slate ADR verification when one was handed off). The read side of the §A7 reset; auto-nudged on the first prompt of a session with a pending handoff |
| `/g-forge doctor` | 25-point health check (16 required + 9 advisory): 7 hooks + 6 lib scripts + native pre-commit hook installed and registered in settings.json, no double-firing, G-Forge Rules block, G-RULES.md present and referenced, no stale sentinel, installed-copy drift detection, plugin version lag (Check 23 read-only, points at `/plugins` or `/g-update` by direction), CLAUDE.md injection-rule compliance (Check 24, advisory), and integration-tier guard file (Check 25, advisory) — ✓/✗/⚠/ℹ with fix instructions |
| `/g-forge kickoff` | Interview → scope challenge → stack deep dive → g-docs/project_brief.md |
| `/g-forge onboard` | Read existing repo → present findings → interview → optional architecture audit → g-docs/project_brief.md |
| `/g-forge roadmap` | Milestone planner: feature dump → cluster (narrated) → sequence with dependency + version justification → **premortem & re-prioritize** → approve → g-docs/ROADMAP.md. Assigns a target semver version to every milestone and writes a version plan. Whenever a milestone is added or modified it runs a premortem on the change and re-prioritizes the whole sequence before the buy-in gate. Auto-triggers on any feature idea or empty milestone list. |
| `/g-forge intake` | Proactive feature-drop triage — when you drop a single feature mid-stream, classifies it against the brief (on-brief / scope-creep / out-of-scope), proposes placement + version impact + risk hint, then asks before writing. The lightweight front-end to `/g-roadmap`. Auto-triggers on any single feature idea. |
| `/g-forge align` | Brief-deviation check — compares the project's actual trajectory (ROADMAP progress, recent commits, observer journal) against `g-docs/project_brief.md` (goals, non-goals, MVP, tech decisions) and reports ALIGNED or DRIFTING with evidence. Advisory — never blocks. Auto-runs at each milestone close; nudged between milestones. |
| `/g-forge brief` | Refresh g-docs/project_brief.md incrementally — reads current state, targeted Q&A, no full re-onboard |
| `/g-forge init` | **The single front door.** Detects what's here → routes to `/g-onboard` (existing codebase) or `/g-kickoff` (new project) for the brief → scaffolds CLAUDE.md (G-rules injected), G-RULES.md, g-docs/ROADMAP.md (with the Active Session handoff), g-docs/milestones/, g-docs/todo.md, seven event hooks, six lib scripts, and the native `pre-commit` hook → runs `/g-specialize` for the stack. One command, ready to `/g-plan`. |
| `/g-forge specialize [stack]` | Detect stack from brief + deps → install architect + implementer agents + rules |
| `/g-forge plan` | QA scope prerequisite (compile g-docs/qa-scope/<milestone>.md) → project-manager challenge gate → task-decomposer → wave-planner → approval gate → saves plan to g-docs/plans/ |
| `/g-forge execute [wave]` | Dispatch parallel agents per wave; hold boundary until each wave completes; resume from a specific wave |
| `/g-forge review` | test suite → code-lead → full review pipeline → Tier 3 smoke test (listen mode) → MERGE READY or HOLD → auto-closes milestone tasks |
| `/g-forge doc-review` | Standalone documentation-review gate — own verdict (DOCS READY / DOCS HOLD), distinct from code review. Read-only `doc-reviewer` lens: accuracy-vs-code, currency (docs that contradict the code), completeness (public exports, README sections, env vars, ADR/CHANGELOG coverage), clarity, volatile in-flight state. Gates doc-only and mixed commits; may recommend `/g-docs`, never writes |
| `/g-forge update` | **Staleness preflight** — verifies plugin cache is current (if not, stops with zero writes and directs to `/plugins`); then realigns all G-Forge-managed files (CLAUDE.md rules, G-RULES.md, agents, architecture rules, hooks) to the current version. Self-host mode skips preflight. For read-only version diagnosis, see `/g-doctor` Check 23. |
| `/g-forge afk` | Autonomous milestone executor — runs all pending waves + review unattended. Requires approved plan. Safety net blocks remote push, recursive delete, and publish commands. Structured cycle-break report on any stop. |
| `/g-forge listen` | Enter listen mode — collect notes, issues, or observations without acting; triage everything when you say "done" |
| `/g-forge skill-design` | Design a new G-Forge skill from scratch — requirements gathering, step drafting, SKILL.md (the sole authored source, ADR-007) + bare-token router line |
| `/g-forge skill-validate [name]` | Validate a skill or agent against structural rules — ✓/✗ checklist, VALID or NEEDS FIXES verdict |
| `/g-forge audit [path]` | Full-codebase or targeted code quality audit — SOLID violations, code smells, architectural drift, dead code, test coverage gaps. Targeted scope produces an inline report; whole-codebase scope produces a prioritised roadmap milestone |
| `/g-forge optimize [path]` | Full-codebase or targeted performance audit — algorithmic complexity, N+1 queries, re-render waste, resource leaks, caching opportunities. Targeted scope produces an inline report; whole-codebase scope produces a prioritised roadmap milestone |
| `/g-forge refactor [path\|milestone]` | Guided refactor workflow — identify target, pre-analyse, spec, approve, execute, review gate. Accepts a scope path or an audit milestone file. Checks test coverage before execution and runs the full review gate after |
| `/g-forge docs [path]` | Documentation audit and generation — scans for missing or stale code docs, README gaps, undocumented env vars, CHANGELOG gaps, and ADR omissions. Targeted scope fixes gaps immediately via doc-writer; whole-codebase scope produces a prioritised documentation debt report |
| `/g-forge wiki [area]` | Build and maintain the human-facing project wiki in a **committed** `g-wiki/` folder — narrative architecture + per-area pages + how-to, synthesized from the codebase, ROADMAP, ADRs, and brief via doc-writer. Run anytime; offered at `/g-init` and refreshed automatically at the end of every milestone. Distinct from `/g-docs` (code-level doc hygiene) and the committed `g-docs/` operational records (of which only `g-docs/agent-output/` and local `g-docs/plans/` scratch are git-ignored) |
| `/g-forge adr [title]` | Capture an architectural decision record. **Triages first** — ADR, a one-line brief tech-decisions entry, or nothing — so the corpus stays rare and high-signal. Then either captures pre-deliberated reasoning (asking only about gaps) or interviews from scratch, **offloads the weighing to a throwaway deliberation subagent** (keeps HQ's context clean), and promotes only the finalized draft to `g-docs/decisions/NNN-title.md`. Runs a mandatory **reversibility check + premortem** (premortem depth scales with reversibility) before close, so you have the full picture before building. On a consequential decision it **closes the loop** — runs `/g-retro` and recommends a fresh session whose first task is verifying the ADR against ground truth (reusing the §A7 context-gate reset path). Run when making a significant technical choice |
| `/g-forge retro` | Synthesize a session retrospective to `g-docs/retros/YYYY-MM-DD-topic.md` from the silent-observer journal — no interview. Reads `.claude/journal/`, git history, and g-docs/todo.md; infers what was done, decisions, patterns, and cold-start context. The developer verifies, they don't recall. |
| `/g-forge patterns` | Two-phase pattern lifecycle. **Mine** reads `g-docs/retros/` and `g-docs/todo-done.md` for recurring patterns (≥2 frequency), saves an abstracted, principle-level report to `g-docs/patterns/latest.md` (stable path for external automation; renamed to resolution date YYYY-MM-DD.md when resolved), records patterns PENDING — **applies no edits**. **Resolve** runs in a fresh session (entered via `## Active Session` handoff), checks `g-docs/inbox/adversarial/` for external counter-reports (advisory only, human-weighed), then apply/defer/dismiss/withdraw per developer. When an applied fix lands in shipped source, Resolve also appends a `CHANGELOG.md` entry under an existing `## [Unreleased]` heading (never creating the file or the heading, never touching a machine-generated changelog — it reports the gap instead). |
| `/g-forge roundtable` | Bind the session to **the Roundtable** — a shared live Doc that is the human-facing communication layer (you + non-programmers + the session). `start` binds a Doc (create-from-template or attach-by-URL); `sync` reads it at boundaries and writes only salient deltas (the salience gate); `close` distills the live Doc into the durable record (handoff + ADRs + todo) on a human nod. Works solo or shared; surface-agnostic (ADR-001). **Off by default** — no Roundtable configured means every path is a no-op and behaviour is byte-identical to today. (M33 Phase A) |
| `/g-forge forecast [plan-slug]` | Premortem and scope-realism pass on a plan. Outputs complexity score (0–10), quantified miss-risk percentage, and ranked top-5 failure scenarios seeded by `/g-patterns` history. Miss-risk is calibrated against the project's own forecast-vs-outcome corpus (`g-docs/forecasts/*.md` `## Outcome` cells, reconciled by `/g-retro`): a bounded adjustment (±10 points, folded into the final 0–95% score) that can raise or lower the raw estimate depending on whether past forecasts over- or under-predicted, and only applies once at least 5 confirmed outcomes are on record — below that floor it reports the raw score with a neutral (zero) adjustment. Auto-invoked by `/g-plan` Step 3b. Advisory — never blocks approval. Persists `g-docs/forecasts/<slug>.md`. |
| `/g-forge telemetry` | Compute 8 reliability metrics (hallucination, review catch, regression, rework, spec deviation, escalation, token efficiency, retry dependency); classify health profile (stable / cautious / defensive / recovery); write `.claude/telemetry-profile` for adaptive orchestration. `/g-execute` and `/g-review` Step 0 read the profile and scale wave size, model tier, and reviewer count accordingly. |
| `/g-forge blast-radius [file\|plan\|feature]` | Map forward + reverse dependencies for a planned change; compute per-file volatility from git history; output aggregate rating (Narrow / Moderate / Wide). Persists `g-docs/blast-radius/<slug>.md` for `/g-forecast` Step 2b integration. |
| `/g-forge identity` | Narrative synthesis of the project's operational personality from accumulated retros, forecasts, telemetry, ADRs, blast-radius reports, CHANGELOG, ROADMAP, and git history. Produces `g-docs/identity.md` covering what the project is, how it ships, what it does well, where it struggles, and what it's becoming. Qualitative complement to `/g-telemetry`. |
| `/g-forge tier [full\|balanced\|light]` | Switch the integration tier. `full` (default) = all hooks + auto-triggers; `balanced` = state info only, commit gate on, no auto-triggers; `light` = workflow-checkpoint only, commit gate off (opt-out mode). Switching to `light` requires confirmation. Writes `.claude/integration-tier`. See `g-docs/integration-tiers.md`. |
| `/g-forge voice [dev\|mid\|eli5]` | Set the communication style. With no argument: runs a 2-question plain-language intake and sets the right profile automatically — no tier names to memorise. With `dev`, `mid`, or `eli5`: applies that profile directly. Same facts, same verdicts — rendering changes. Auto-runs during `/g-kickoff` if no profile is set. Writes `.claude/voice-profile`. |
| `/g-forge train [project idea]` | Training mode — learn software development by building a real project. Sets up the learner profile, confirms the project, and writes `.claude/training-mode`. From that point on, PM runs the session in **mentor register** — a genuinely distinct mode: explains the "why" before every step, assigns you tasks alongside the agent swarms, checks in after each wave, and logs your progress to `.claude/training-progress.md`. The workflow is unchanged; the framing is different. Three training levels: `foundational` (new to coding), `developing` (has built things, hasn't shipped), `intermediate` (has shipped, wants structured practice). `/g-kickoff` offers training mode automatically when the voice intake identifies a learner profile. |
| `/g-forge trim` | Weekly read-only audit of `CLAUDE.md`, its `@`-import targets, and agent memory files. Surfaces orphaned `@references`, duplicate rules, stale content, dead file refs in MEMORY.md files, overlong memory entries, and any sunset/activation conditions in committed imported sources — all flagged for human review, never auto-modified. The only file it writes is `.claude/last-trim`. The workflow-checkpoint hook surfaces a nudge when 7 days have passed since the last audit. |

---

## Agents

**19** agents ship with every install. Full reference: [g-docs/agents.md](g-docs/agents.md)

| Agent | Tier | Role |
|-------|------|------|
| `task-decomposer` | Sonnet | Atomic task breakdown with done conditions |
| `wave-planner` | Sonnet | Parallel wave schedule from task list |
| `spec-writer` | Sonnet | Precise implementation specs for executor agents |
| `code-reviewer` | Opus | Code quality, logic errors, DRY violations |
| `security-auditor` | Opus | OWASP Top 10, injection, secrets, auth flaws |
| `architecture-enforcer` | Opus | Layer boundaries, import directions, SRP |
| `performance-auditor` | Sonnet | N+1 queries, O(n²) paths, hot-path issues |
| `debugger` | Sonnet | Root cause analysis, fix strategy |
| `error-detective` | Sonnet | Log and stack trace pattern analysis |
| `project-manager` | Sonnet | Primary user interface for every session — challenge gate, roadmap ownership, lifecycle coordination. Shifts to mentor register in training mode. Checks for plugin updates weekly. |
| `review-orchestrator` | Sonnet | Parallel review pipeline aggregation. Must run in the main session or from a skill (depth-0) — spawning it as a nested subagent silently blocks reviewer dispatch. |
| `code-lead` | Opus | Technical sign-off, merge gate verdict |
| `test-writer` | Haiku | Unit, integration, and e2e tests from specs; fixed data only |
| `doc-writer` | Haiku | Inline docs explaining WHY not WHAT |
| `doc-reviewer` | Opus | Documentation-review gate — accuracy-vs-code, currency, completeness, clarity, volatile in-flight state; DOCS READY / DOCS HOLD verdict |
| `pr-writer` | Haiku | PR descriptions from git diff |
| `refactor-executor` | Haiku | Spec-exact refactoring, no scope creep |
| `feature-implementer` | Sonnet | Generic wave implementer — the fallback executor when no stack implementer matches |
| `dependency-auditor` | Sonnet | Manifest security advisories, deprecations, license conflicts, unused declarations |

### Agent output architecture

All 17 specialist agents that use the compact-return format — every agent except the two user-facing ones (`project-manager`, `pr-writer`) — write their full findings to disk (`g-docs/agent-output/wave-N/<task-slug>.md` for wave agents; `g-docs/agent-output/review/<agent>-YYYY-MM-DD.md` for review agents) and return a compact summary to the calling session:

```
RESULT: DONE|FAILED|BLOCKED  (or PASS|HOLD for review agents)
ISSUES: N critical · M major · K minor
SUMMARY: [one sentence]
FILES: [files changed]
LEARNINGS: [FAILED only — approach tried, why it broke, what's ruled out, recommended different approach]
DETAIL: [output file path]
```

The calling session reads the detail file only when the result is HOLD, FAILED, or BLOCKED. This keeps main-session context growth at ~70 tokens per agent return rather than 1,500–3,000 tokens of inline output — larger waves stay within budget, and the full audit trail is preserved on disk.

### Single-use agents — one approach, one attempt

Agents are **single-use**. Each gets one approach and one attempt. If it works, the agent returns `DONE`; if the approach doesn't work, the agent returns `FAILED` with a **learnings report** (what it tried, why it broke, what's ruled out, a recommended different approach) and is **discarded** — never re-prompted. HQ reads the learnings, picks a different mechanism, and deploys a *fresh* agent seeded only by that distilled lesson, never the dead agent's context.

This is deliberate. A context window conditions on everything in it, so a failed exploration left inside an executor degrades its next output — it anchors on rejected options, hedges, and clings to wrong first guesses. G-Forge calls this **context poisoning**, and single-use agents make it structurally impossible: the mess dies with the agent, and only a clean contract crosses back. The retry loop is bounded by Three-Strikes — three fresh attempts with different mechanisms, escalating the model tier before the third, then it stops and hands you the full learnings trail. `FAILED` (approach didn't work → HQ retries) is distinct from `BLOCKED` (external dependency → straight to you). It's the same airtight-handoff discipline the planner/executor split already uses for first attempts, extended to retries.

---

## Token cost saving strategy

G-Forge applies cost controls at every layer of the stack. Here's what each one does and how they compound.

### Model tiering

Every agent targets the minimum model tier that can do its job reliably:

| Tier | Used for |
|------|---------|
| Haiku | Reads, searches, doc generation, test writing, refactors from spec — tasks with a clear mechanical outcome |
| Sonnet | Planning, decomposition, wave coordination, debugging, analysis — tasks requiring reasoning but not judgment |
| Opus | Review, merge gate, architecture enforcement — tasks where correctness and missed findings have real cost |

Most implementation work lands on Sonnet. Opus is reserved for the review pipeline where a missed critical issue is expensive.

### G-RULES.md selective loading

The full `G-RULES.md` is ~9,000 tokens and loads on every session that references `@G-RULES.md`. For projects that only need a subset of the rules, `/g-init` also installs each of the ten sections as a standalone `@`-referenced file in `.claude/rules/` (prefixed `g-rules-`). Reference only the sections your project needs in `CLAUDE.md` — a minimal project referencing `g-rules-A-session.md`, `g-rules-D-code-quality.md`, and `g-rules-I-project-tracking.md` saves ~5,400 tokens per session vs the full load.

### Agent compact returns

Agents write full findings to `g-docs/agent-output/` and return a five-line summary. The main session reads the detail file only on HOLD or BLOCKED. This reduces per-agent context growth from ~1,500–3,000 tokens (inline output) to ~70 tokens (compact block). A six-agent review wave that previously added ~12,000 tokens to main-session context now adds ~420 tokens.

### Context depth management

A prompt counter in `.claude/session-prompt-count.<session-id>` (bare `session-prompt-count` only when no session id reaches the hook) is incremented on every message. It is reset on a genuine session open (startup/resume/clear) but **carries across a `compact` start** — so a session that auto-compacts no longer silently zeroes the counter that triggers its own reset. The session is classified as `implementation` or `conversation` based on git signals; baselines start lenient and auto-calibrate downward (each compaction grows a persistent, floored offset in `.claude/context-threshold-offset`):

| Mode | 🟡 Amber (baseline) | 🔴 Red (baseline) |
|------|---------|-------|
| Implementation | 30 exchanges | 45 exchanges |
| Conversation | 45 exchanges | 65 exchanges |

The goal is to reset **before** the window compacts, never after. Amber is active monitoring: Claude runs `/context` every turn and resets the moment remaining capacity drops below ~25% — capacity-driven rather than waiting for the red exchange count, since only `/context` reads true context pressure. `/g-execute` runs the same check at every wave boundary (the heaviest token-burn event), catching fast-burning sessions the exchange count misses. At red it's enforced: no new scope, `/g-retro` auto-triggers, and a handoff block is written before the session ends. This prevents the worst-case scenario — a mid-wave context exhaustion that leaves implementation in an inconsistent state.

### Pre-plan context budget check

Before a plan is approved, `/g-plan` estimates its execution cost in exchanges using `5 + waves×3 + agents×2 + tasks×1 + tasks×4` — the last term prices the review chain that follows implementation, a rate derived from G-Forge's own task/review-round records (`g-docs/todo-done.md`) and confirmed at a different scale by a field report showing review chains running 3–10x the implementation estimate — and compares it against the remaining budget. Plans that would push the session into red mid-execution are flagged, and the developer chooses between splitting the milestone (via `/g-roadmap`) or accepting the handoff risk; a milestone that is already the product of a prior split (depth ≥ 1) has the split option withheld, and the developer instead chooses between proceeding with the handoff risk or escalating for a manual re-scope. This eliminates surprise context exhaustion mid-wave.

### Wave-based parallelism

Running 6 agents in parallel in one wave costs the main session one round-trip of context growth (one dispatch + one set of compact returns = ~500 tokens). Running the same 6 tasks serially would cost 6 round-trips plus accumulated reasoning context between tasks. Wave size is the primary lever for keeping execution cost proportional to work done rather than to the number of tasks.

---

## Stack Profiles

Installed per-project by `/g-specialize`. Each profile adds a stack-specific **architect** agent (read-side, reviews for layer violations) and a matching **implementer** agent (write-side, executes wave tasks in the stack's idioms — wave-planner routes implementation tasks to it), and appends architecture rules to `CLAUDE.md`. Both agents preload the same architecture rules. Once installed, they are project-native — no plugin required at runtime.

48 stack profiles ship with the plugin, plus 1 supplementary profile (`frontend-data-flow`) that auto-installs alongside any component-framework stack. Auto-detected from your project's dependency files when you run `/g-specialize`.

**Web Frontend**
`react` · `next-js` · `nuxt` · `vue-pinia` · `sveltekit` · `angular` · `astro` · `remix`

**Node / Go / Rust Backend**
`node-ts` · `express` · `nest-js` · `go-gin` · `go-fiber` · `rust-axum` · `hono` · `bun`

**Python / Ruby / PHP**
`fastapi` · `django` · `flask` · `laravel` · `rails` · `python-textual` · `python-cli` · `python-ml` · `python-data`

**JVM / .NET**
`spring-boot` · `asp-net-core` · `kotlin-ktor` · `kotlin-android` · `phoenix-liveview` · `wpf-csharp` · `maui` · `xamarin` (legacy)

**Mobile / Desktop**
`react-native` · `flutter` · `swift-ios` · `electron` · `tauri` · `capacitor`

**Game Dev + Systems**
`unity` · `unreal` · `godot-gdscript` · `godot-csharp` · `pygame` · `cpp-cmake` · `rust-cli` · `c-embedded`

**Claude Code Plugin**
`claude-plugin` — architect agent + architecture rules for Claude Code plugin development (skill structure, command routing, agent format, hook design, manifest validation)

Game-dev profiles (`unity`, `unreal`, `godot-gdscript`, `godot-csharp`, `pygame`, `cpp-cmake`) include object pooling rules and state machine patterns aligned with Section F of G-RULES.md.

### Supplementary profiles

`frontend-data-flow` ships its own architect agent and rules covering the two-network model (read/write) and the four canonical frontend violations (HTTP in components, shadow-state ref sync, watch-as-dispatch, caller-follows-truck). It auto-installs alongside any component-framework profile (`react`, `vue-pinia`, `nuxt`, `next-js`, `sveltekit`, `angular`, `remix`, `astro`, or any astro-* combo) — never replaces the per-framework architect.

### Combo Profiles

7 combo profiles are detected automatically by `/g-specialize` when your project uses two stacks that have emergent cross-stack patterns — patterns that aren't in either tool's docs alone.

| Combo | Required stacks | Patterns covered |
|-------|-----------------|-----------------|
| `electron-react` | electron + react | contextBridge API layer, IPC channel constants, cross-window state |
| `electron-vue-pinia` | electron + vue-pinia | contextBridge + Pinia IPC integration, cross-window state |
| `react-tauri` | react + tauri | `invoke()` typed API layer, Tauri event hooks in React, capability scoping |
| `tauri-vue-pinia` | tauri + vue-pinia | `invoke()` typed API layer, Pinia + Tauri event subscriptions, capability scoping |
| `astro-react` | astro + react | Island isolation, serializable prop contract, cross-island state via nanostores, React hydration directives |
| `astro-vue` | astro + vue-pinia | Island isolation, serializable prop contract, cross-island state via nanostores, Vue hydration directives |
| `astro-svelte` | astro + sveltekit | Island isolation, serializable prop contract, native Svelte store sharing across islands, hydration directives |

Combo profiles install rules only — no architect agent. Detected automatically; no explicit argument needed.

---

## Playbook

Quick reference for the most common workflows.

### Starting a new project

```
/g-forge kickoff Groups 1–4: problem → scope → stack surface → stack deep dive + integration map
                     Challenges each feature and tech choice honestly
                     Dispatches project-manager (scope) + code-lead (stack validation)
                     Produces g-docs/project_brief.md with tech decisions table

/g-forge init   Creates CLAUDE.md with G-rules, G-RULES.md, g-docs/ROADMAP.md, g-docs/milestones/M1.md, g-docs/todo.md
                     Installs .claude/hooks/session-start.sh (SessionStart — repo sync + context reset)
                               .claude/hooks/workflow-checkpoint.sh (UserPromptSubmit — state + context depth)
                               .claude/hooks/check-commit.sh (PreToolUse — commit gate)
                               .claude/hooks/post-commit-cleanup.sh (PostToolUse — sentinel cleanup)
                               .claude/hooks/observe.sh (PostToolUse + SessionStart — silent-observer journal)
                               .claude/hooks/agent-lifecycle.sh (SubagentStart/Stop — agent journal)
                               .claude/hooks/pre-compact.sh (PreCompact — handoff snapshot)
                               .claude/hooks/lib/commit-detect.sh (commit detection, shared)
                               .claude/hooks/lib/worktree-resolve.sh (worktree resolution, shared)
                               .claude/hooks/lib/classify-changeset.sh (changeset classification, shared)
                               .claude/hooks/lib/sentinel-read.sh (sentinel stamp parsing, shared)
                               .claude/hooks/lib/stdin-read.sh (stdin read-timeout guard, shared)
                               .claude/hooks/lib/semver-compare.sh (version ordering, shared)
                     Registers all seven event hooks in .claude/settings.json (the plugin manifest registers none)
                     Installs native git pre-commit hook into the repository's git hooks path with clobber guard

/g-forge specialize Reads g-docs/project_brief.md → detects stacks → confirms → installs architect + implementer agents
```

### Planning the roadmap

```
/g-forge roadmap Feature dump: tell it everything you want to build, in any order
                     PM groups features into clusters and narrates why — common
                       surfaces, shared deps, release cohesion
                     Sequences clusters into milestones and explains every ordering
                       decision — what blocks what, where the MVP cut is
                     Four gated phases: dump → cluster → sequence → approve
                     Writes g-docs/ROADMAP.md only after you type "approve"

                     Reads current version (plugin.json / package.json /
                       pyproject.toml / Cargo.toml) as the baseline
                     Assigns a target version to every milestone during
                       sequencing — minor for new capabilities, patch for
                       fixes, major for breaking changes
                     Buy-in gate shows the full version plan:
                       v[current] → v[M1] → v[M2] → ...
                     Writes **Version:** field to each milestone in g-docs/ROADMAP.md

Auto-triggers:  — no g-docs/ROADMAP.md exists in the project
                — no active (🔄) or unstarted (⬜) milestones in g-docs/ROADMAP.md
                — any feature idea is mentioned in conversation
```

### Onboarding an existing project

```
/g-forge onboard Reads the repo first: stack, structure, tests, entry points
                     Presents findings and asks you to confirm before continuing
                     Interviews: what's next, constraints, known fragile areas
                     Optional: dispatches code-lead for architecture audit
                     Produces g-docs/project_brief.md with current state + planned work

/g-forge init   Installs commit enforcement, injects G-rules into CLAUDE.md, installs G-RULES.md
/g-forge specialize Reads g-docs/project_brief.md → installs architect + implementer agents + rules
```

### Where am I?

```
/g-forge help   Reads project state (g-docs/todo.md, g-docs/ROADMAP.md, plan files, hooks)
                     Detects current phase and outputs one clear next action
                     + full command reference

/g-forge status Fast structured snapshot — no narrative, just facts:
                     Milestone · Active plan + wave · Review gate · Handoff line

/g-forge doctor 25-point health check (16 required, 9 advisory) — 7 hooks + 6 lib
                     scripts + native pre-commit hook installed and registered in
                     settings.json, G-Forge Rules block, G-RULES.md present and
                     referenced, no stale sentinel, installed-copy drift detection,
                     plugin version lag, and CLAUDE.md injection-rule compliance
                     Reports ✓/✗/⚠/ℹ per check with fix instructions
```

### Planning a feature

`/g-plan`, `/g-execute`, and `/g-review` are **auto-triggered** — Claude detects task complexity and initiates them without you typing the commands. The `workflow-checkpoint.sh` hook fires on every message and reports current state (including active wave progress); G-RULES.md tells Claude what to do with it.

You can still invoke them manually if needed:

```
/g-forge plan   Step 0: QA scope prerequisite — confirm or compile
                       g-docs/qa-scope/<milestone>.md (Tier 3 DoD for the milestone)
                     Step 1: project-manager challenges the feature request (3 questions,
                       one verdict — bug fixes and refactors skip this gate)
                     Dispatches task-decomposer → wave-planner
                     Step 3c: context budget check — estimates execution cost
                       (5 + waves×3 + agents×2 + tasks×1 + tasks×4 exchanges) vs
                       remaining session budget; offers /g-roadmap split if over
                       limit (withheld once already split — depth ≥ 1 offers
                       proceed-with-risk or manual re-scope instead)
                     Step 3d: wave dependency validation — checks same-wave file
                       conflicts (blocking), missing source files for mutation tasks
                       (blocking), cross-wave ordering violations (warning)
                     Runs /g-forecast premortem (complexity score + miss-risk)
                     Presents wave schedule + budget + forecast for approval
                     Saves approved plan to g-docs/plans/<feature-slug>.md
                     On approval: hands off to /g-execute

/g-forge execute Dispatches all Wave 1 tasks in parallel, waits for completion
                     Then Wave 2, Wave 3, etc. — holds boundary between waves
                     Stops immediately on any BLOCKED signal
                     Resume a partial run: /g-forge execute 2

/g-forge review Step 1: runs the test suite — failures block with HOLD immediately
                       No test suite? Must dispatch test-writer or explicitly override
                     Dispatches code-lead → review-orchestrator → parallel reviewers
                     On MERGE READY: enters Tier 3 listen mode — prompts smoke test
                       against QA panel; collects bug reports; triages after "done this round"
                       Repeats until a clean round, then writes sentinel
                     Issues MERGE READY or HOLD with fix list
                     On MERGE READY: auto-closes completed milestone tasks in g-docs/ROADMAP.md
```

### Keeping the brief current

```
/g-forge brief  Refresh g-docs/project_brief.md as the project evolves
                     Reads current g-docs/ROADMAP.md, g-docs/todo.md, recent git log
                     Asks at most 4 targeted questions — no full re-onboard
```

### Going AFK — unattended milestone execution

```
/g-forge afk    Pre-checks: approved plan must exist in g-docs/plans/
                     Configures permissions.allow (no tool prompts) +
                       permissions.deny (safety net):
                       blocks git push, rm -rf, all publish commands,
                       and writes outside the project folder
                     One final confirmation, then goes heads-down:
                       executes all pending waves in sequence
                       runs /g-review automatically after the last wave
                     Only stops for: BLOCKED task or safety violation
                     Both produce a structured cycle-break report:
                       what completed · what was written · exact violation ·
                       two resume options
                     Ends with full handoff: verdict · Tier 3 test plan ·
                       open items

Tip: for fully unattended mode (no prompts at all), start the session with:
  claude --dangerously-skip-permissions
then run /g-forge afk
```

### Day-to-day commit flow

```
git checkout -b feat/<slug>   # branch before non-trivial work
[implement feature or fix]
/g-forge review → runs tests, then full pipeline → MERGE READY unlocks the gate
git commit -m "..."  → gate clears, sentinel auto-removed
git merge main       → or open a PR
git push
```

### Debugging a bug

```
1. Dispatch error-detective with the stack trace or log output
2. Dispatch debugger with error-detective's findings + relevant source files
3. Dispatch test-writer with debugger's fix strategy
4. Implement the fix
5. /g-forge review → commit
```

### Refactoring safely

```
1. Dispatch spec-writer with the refactor description and scope boundary
2. Dispatch architecture-enforcer with the spec + layer map
3. Dispatch refactor-executor with the approved spec
4. Dispatch code-reviewer with the resulting diff
5. /g-forge review → commit
```

### Common single-agent dispatches

| What you need | Agent | Give it |
|---------------|-------|---------|
| Write a PR description | `pr-writer` | `git diff` output |
| Find security issues | `security-auditor` | files to audit + data flow context |
| Write tests (unit/integration/e2e) | `test-writer` | implementation or spec + test framework |
| Root cause an error | `error-detective` | stack trace or log output |
| Investigate a specific bug | `debugger` | error-detective findings + relevant source files |
| Write a precise implementation spec | `spec-writer` | feature or refactor description + constraints |
| Write docs for a module | `doc-writer` | the file + any design intent notes |
| Check architecture violations | `architecture-enforcer` | diff + layer map |
| Review a diff for code quality | `code-reviewer` | the diff + any relevant context |
| Audit for performance issues | `performance-auditor` | files or paths to scan + any known bottlenecks |
| Audit dependencies | `dependency-auditor` | package manifest(s) — `package.json`, `requirements.txt`, `Cargo.toml`, etc. |
| Break down a task | `task-decomposer` | feature description + constraints |
| Schedule parallel work | `wave-planner` | task list from task-decomposer |

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
| **v2.5.0 — the final G-Forge release** ([ADR-012](g-docs/decisions/012-g-forge-2.5-final-release-scope.md)): M47 Planning-Pipeline Honesty · M48 Review-Pipeline Hardening · M51 Release Reliability (M45-lite, absorbing M45) · M50 Eval-Chain Integrity · M38 G-Report · M40 Reference Convention · M43 Operator Controls · M49 Devil's-Advocate Agent · M41 Release Machinery (cuts the release) | 🔄 In progress |
| After v2.5.0: this repo freezes (maintenance-only) and the successor — **G-Proof** — follows. Versioning restarts at G-Proof 1.0; there is no G-Forge 3.0. | — |

---

## License

G-Forge is free, open-source software, released under the **GNU General Public License v3.0** (GPL-3.0) — see [LICENSE](LICENSE).

Copyright © 2026 Gianmarco Palma. You're free to use, study, modify, and redistribute it under the GPL-3.0 terms; derivative works must stay under GPL-3.0 and preserve this notice. Full license text: <https://www.gnu.org/licenses/gpl-3.0.txt>.

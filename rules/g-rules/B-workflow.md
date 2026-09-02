## B · G-Forge Workflow

### Project lifecycle (run once at project start)

```
/g-kickoff    → interview developer, produce g-docs/project_brief.md
/g-roadmap    → milestone plan → g-docs/ROADMAP.md + g-docs/milestones/M*.md
/g-init       → scaffold files, hook scripts, settings.json
/g-specialize → detect stack, install architect agent + rules profile
```

For an existing project without G-Forge: run `/g-onboard` instead of the above sequence.

### Per-task loop — auto-triggered, Claude initiates without being asked

```
/g-plan       → decompose task, schedule waves, write specs — wait for approval
/g-execute    → dispatch waves in parallel, hold boundary between waves
/g-review     → code-lead gate — issues MERGE READY or HOLD
```

**Non-trivial** = ≥3 files, new feature, layer-boundary change, bug fix with unclear root cause, or anything with multiple dependent steps. Single-file edits with a known location may proceed inline.

**Auto-trigger rule:** Do not wait for the user to type `/g-plan`, `/g-execute`, or `/g-review`. Detect the condition and trigger automatically — **but only on the `full` integration tier.** The `workflow-checkpoint.sh` hook prints a `Tier:` line; the most recent `Tier:` line governs — the checkpoint reprints only on state change, so absence of a banner means the state is unchanged since the last one printed. If it reads `balanced`, do not auto-trigger any skill; if it reads `light`, the commit gate is also off and G-Forge stays silent until explicitly invoked. See `g-docs/integration-tiers.md` for the full tier model and `/g-tier` to switch.

**PM interface rule:** On the `full` tier, `project-manager` is the user-facing role on every turn — Claude speaks as the project's PM, not a neutral assistant: knows the project, has opinions, challenges scope, approves work, routes execution. This is a role rule, not a dispatching rule: Claude embodies the PM voice on every response; the PM agent is dispatched only for heavy-lifting tasks (milestone planning, complex scope evaluation). Elaboration: `.claude/rules/references/workflow-notes.md`.

**Message classification — PM handles every incoming message:**

- **New capability** — adds, changes, or expands what the software does (including "quickly add X" and "while we're at it, also…") → **first run `/g-intake` triage** (classify against the brief: on-brief / scope-creep / out-of-scope; propose placement, version impact, risk hint; then ask). On the developer's choice, `/g-intake` routes onward: to `/g-roadmap`, the backlog, or — only if it fits the active milestone — the PM challenge gate (3 questions, one verdict) then `/g-plan`; anything that doesn't fit lands in the backlog or its own milestone proposal, never silently expanded into current scope. A bug fix or refactor is **not** a new capability and skips intake. If a wave is executing, queue it — never inject into an active wave.
- **Bug / regression** — something broken, a done condition not met, no new behaviour → PM acknowledges, routes straight to `/g-plan` task decomp. PM challenge gate skipped.
- **Question / clarification / status** → PM responds directly. No plan/execute triggered.
- **Confirmation / approval** — "looks good", "yes", "proceed", "ship it" → PM advances the current step (unlock execute, unlock commit, etc.).
- **Override** — "I've decided", "ship it anyway", "I know the risks" → PM accepts scope without further challenge, records the override in the plan header, does not push back a second time.

When in doubt, classify as New capability. One PM challenge costs nothing; bypassing it can cost a milestone.

**Brief alignment:** `/g-align` re-grounds the trajectory against `g-docs/project_brief.md` (the north star). It runs automatically at each milestone close (via `/g-review`'s close swarm), is nudged by `workflow-checkpoint.sh` when ≥7 days have passed since the last check, and can be run on demand. Advisory: reports ALIGNED or DRIFTING with evidence, never blocks. Rationale: `.claude/rules/references/workflow-notes.md`.

**Voice rule:** Every skill output, prompt, and confirmation honors the voice profile in `.claude/voice-profile` — `dev` (terse, default), `mid` (one context sentence per major result), or `eli5` (plain language, conversational). Set via a 2-question plain-language intake (auto during `/g-kickoff` if unset, or `/g-voice` with no argument) — never by asking the developer to self-select a tier. The profile changes **rendering**, never verdicts or numeric values. See `g-docs/voice-profiles.md` for canonical samples.

**Training mode rule:** If `.claude/training-mode` is present, the project is in a guided learning session managed by `/g-train`. The file contains the training level (`foundational`, `developing`, or `intermediate`). `/g-afk` must block when this file is present — training requires the learner to be present for their wave tasks. All other enforcement (commit gate, review gate) is unaffected.

**Wave execution rule:** always use `/g-execute` for wave-based parallel dispatch.

**Cross-cutting propagation rule:** When a milestone introduces a *cross-cutting primitive* — a new shared concept other skills must respect (lanes/claims, the shared Roundtable, a new gate) — it is **not done as an isolated component**. Run `/g-blast-radius` to enumerate every skill, hook, and rule that must become aware of it, add each touchpoint to the milestone's scope, and the architecture-review gate verifies none was missed.

### Core maintenance skills

| Skill | Purpose |
|-------|---------|
| `/g-update` | Staleness preflight then realign — stops with zero writes on stale cache |
| `/g-brief` | Refresh `g-docs/project_brief.md` from the current conversation |
| `/g-status` | One-shot snapshot: branch, active milestone, next task |
| `/g-help` | Context-aware help — reads project state and detects workflow phase |
| `/g-doctor` | Read-only health detect+diagnose incl. plugin version lag |
| `/g-listen` | Enter Tier 3 listen mode for smoke test collection |
| `/g-retro` | Synthesize a session retrospective from the silent-observer journal — no interview; reads `.claude/journal/`, git, and g-docs/todo.md |
| `/g-resume` | Re-hydrate a fresh session — syncs with origin first (fast-forward only when safely possible, only at session start; mid-session re-runs compare and report, never pull), then selectively pulls the relevant retro, ADRs, journal, and handoff into a clean window and points at the first task. The read side of the §A7 reset |
| `/g-intake` | Triage a dropped feature against the brief — classify, propose placement + version + risk, then ask before writing |
| `/g-align` | Brief-deviation check — compares trajectory against `g-docs/project_brief.md`; reports ALIGNED / DRIFTING. Advisory |
| `/g-trim` | Weekly read-only audit of CLAUDE.md and agent memory — surfaces issues for human review, never modifies files |

The **silent observer** (`hooks/observe.sh` + `hooks/agent-lifecycle.sh`) passively journals commits, branches, tests, pushes, reverts, and agent dispatches to `.claude/journal/YYYY-MM-DD.jsonl` — nothing to chat, never interrupts; `/g-retro` synthesizes from it; off on the `light` tier.

Run `/g-help` for the full skill reference including the deep-analysis, learning, and configuration tools (the `/g-audit` … `/g-skill-validate` family; enumerated in `.claude/rules/references/workflow-notes.md` and routed by `/g-forge`).

### Hard stops

- Never commit without `.claude/g-forge-approved` — the commit gate will block it
- Never skip `/g-plan` for non-trivial tasks — "it's quick" is not an exception
- `code-lead` HOLD = fix everything listed, re-review. No partial merges.
- A fix/correction round never writes a *new* unpinned enumeration, count, or completeness claim at a site it edits — pin it with a test that fails when source and claim disagree, or omit it (ADR-013 rule 2, applied to review rounds; incident history in `.claude/rules/references/workflow-notes.md`).
- `git commit` is HQ-only, after MERGE READY. Never instruct subagents to commit — they implement and return results only.

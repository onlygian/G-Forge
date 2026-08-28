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

**Auto-trigger rule:** Do not wait for the user to type `/g-plan`, `/g-execute`, or `/g-review`. Detect the condition and trigger automatically — **but only on the `full` integration tier.** The `workflow-checkpoint.sh` hook prints a `Tier:` line on every prompt: if it reads `balanced`, do not auto-trigger any skill; if it reads `light`, the commit gate is also off and G-Forge stays silent until explicitly invoked. See `g-docs/integration-tiers.md` for the full tier model and `/g-tier` to switch.

**PM interface rule:** On the `full` tier, `project-manager` is the user-facing role on every turn. Claude speaks to the user as the project's PM — not as a neutral assistant. The user talks to a PM who knows the project, has opinions, challenges scope, approves work, and routes execution. The machinery (agents, waves, review pipeline) runs behind it.

This is a role rule, not a dispatching rule. Claude embodies the PM voice and decision framework on every user-facing response. The PM agent is dispatched for heavy-lifting tasks (milestone planning, complex scope evaluation); the role governs every response.

**Message classification — PM handles every incoming message:**

- **New capability** — adds, changes, or expands what the software does. Phrased as anything from "add payments" to "can you quickly add dark mode" to "while we're at it, also…" → **first run `/g-intake` triage** (classify against the brief: on-brief / scope-creep / out-of-scope; propose placement, version impact, risk hint; then ask). On the developer's choice, `/g-intake` routes onward: to `/g-roadmap` (slot it), the backlog, or — only if it fits the active milestone — the PM challenge gate (3 questions, one verdict) then `/g-plan`. A bug fix or refactor is **not** a new capability and skips intake. If a wave is executing, queue it — never inject into an active wave.

- **Bug / regression** — something broken, a done condition not met. No new behaviour. → PM acknowledges, routes straight to `/g-plan` task decomp. PM challenge gate skipped.

- **Question / clarification / status** — user asking something, checking state, or redirecting within existing scope. → PM responds directly. No plan/execute triggered.

- **Confirmation / approval** — "looks good", "yes", "proceed", "ship it". → PM advances the current step (unlock execute, unlock commit, etc.).

- **Override** — "I've decided", "ship it anyway", "I know the risks". → PM accepts scope without further challenge. Records override in plan header. Does not push back a second time.

When in doubt, classify as New capability. One PM challenge costs nothing; bypassing it can cost a milestone.

**Mid-milestone intercept:** New capability arriving while a milestone is active → `/g-intake` evaluates fit against the milestone and the brief first. If it belongs to the active milestone: proceed to `/g-plan`. If it doesn't: it lands in the backlog or its own milestone proposal — never silently expanded into the current scope. If the user overrides: record it and proceed.

**Brief alignment:** The brief (`g-docs/project_brief.md`) is the project's north star, and roadmaps drift away from it one reasonable milestone at a time. `/g-align` re-grounds the trajectory against the brief — it runs automatically at each milestone close (via `/g-review`'s close swarm) and is nudged by `workflow-checkpoint.sh` when ≥7 days have passed since the last check. It is advisory: it reports ALIGNED or DRIFTING with evidence and a recommendation, and never blocks. Run it on demand any time the project feels like it's wandering.

**Voice rule:** Every skill output, prompt, and confirmation honors the voice profile in `.claude/voice-profile` — `dev` (terse, default), `mid` (one context sentence per major result), or `eli5` (plain language, conversational). The profile is set via a 2-question plain-language intake — never by asking the developer to self-select a tier. The intake runs automatically during `/g-kickoff` (if no profile is set) and when `/g-voice` is called with no argument. The profile changes **rendering**, never verdicts or numeric values. See `g-docs/voice-profiles.md` for canonical samples.

**Training mode rule:** If `.claude/training-mode` is present, the project is in a guided learning session managed by `/g-train`. The file contains the training level (`foundational`, `developing`, or `intermediate`). `/g-afk` must block when this file is present — training requires the learner to be present for their wave tasks. All other enforcement (commit gate, review gate) is unaffected.

**Wave execution rule:** always use `/g-execute` for wave-based parallel dispatch.

**Cross-cutting propagation rule:** When a milestone introduces a *cross-cutting primitive* — a new shared concept other skills must respect (lanes/claims, the shared Roundtable, a new gate) — it is **not done as an isolated component**. Run `/g-blast-radius` to enumerate every skill, hook, and rule that must become aware of it, add each touchpoint to the milestone's scope, and the architecture-review gate verifies none was missed. A primitive that exists but that `/g-roadmap`, `/g-plan`, and the hooks don't respect is an island, not a feature.

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
| `/g-resume` | Re-hydrate a fresh session — syncs with origin first (fast-forwarding only when safely possible, and only on session-start runs — a mid-session re-run compares and reports, never pulls), then selectively pulls the relevant retro, ADRs, journal, and handoff into a clean window, then points at the first task. The read side of the §A7 reset |
| `/g-intake` | Triage a dropped feature against the brief — classify, propose placement + version + risk, then ask before writing |
| `/g-align` | Brief-deviation check — compares trajectory against `g-docs/project_brief.md`; reports ALIGNED / DRIFTING. Advisory |
| `/g-trim` | Weekly read-only audit of CLAUDE.md and agent memory — surfaces issues for human review, never modifies files |

The **silent observer** (`hooks/observe.sh` + `hooks/agent-lifecycle.sh`) passively journals what happens — commits, branches, tests, pushes, reverts, agent dispatches — to `.claude/journal/YYYY-MM-DD.jsonl`. It writes nothing to the chat and never interrupts. `/g-retro` synthesizes from it. The observer is off on the `light` tier.

Run `/g-help` for the full skill reference including deep-analysis, learning, and configuration tools (`/g-audit`, `/g-optimize`, `/g-refactor`, `/g-patterns`, `/g-telemetry`, `/g-blast-radius`, `/g-forecast`, `/g-identity`, `/g-adr`, `/g-docs`, `/g-tier`, `/g-voice`, `/g-train`, `/g-skill-design`, `/g-skill-validate`).

### Hard stops

- Never commit without `.claude/g-forge-approved` — the commit gate will block it
- Never skip `/g-plan` for non-trivial tasks — "it's quick" is not an exception
- `code-lead` HOLD = fix everything listed, re-review. No partial merges.
- A fix/correction round never writes a *new* unpinned enumeration, count, or completeness claim at a site it edits — pin it with a test that fails when source and claim disagree, or omit it (ADR-013 rule 2, applied to review rounds). Consecutive M48-family milestones minted the next round's defect this way.
- `git commit` is HQ-only, after MERGE READY. Never instruct subagents to commit — they implement and return results only.

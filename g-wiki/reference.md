# G-Forge Reference

Complete catalog of G-Forge skills, agents, and stack profiles.

---

## Skills

**38 skills** — derived from `skills/*/SKILL.md` frontmatter.

| Skill | What it does |
|-------|------------|
| `/g-forge init` | The single G-Forge front door — run once after installing the plugin. Detects what's here and routes to /g-onboard (existing codebase) or /g-kickoff (new project) for the brief, scaffolds CLAUDE.md (compact G-rules), g-docs/ROADMAP.md (with the Active Session handoff), g-docs/milestones/, g-docs/todo.md, the commit/workflow hooks (plus their shared lib/ scripts) and the native pre-commit gate, then runs /g-specialize for the stack — leaving you ready to /g-plan. |
| `/g-forge kickoff` | Interview the developer about their project goals, constraints, and stack. Challenges scope and every tech choice honestly. Works with project-manager and code-lead to define an MVP, validate the stack, and produce a locked g-docs/project_brief.md with a tech decisions table. |
| `/g-forge onboard` | Onboard G-Forge onto an existing codebase. Reads deeply before asking anything — treats existing CLAUDE.md, rules, agents, and task ledgers as first-class inputs. Only interviews for what it genuinely doesn't know yet. Produces or updates g-docs/project_brief.md. |
| `/g-forge roadmap` | Project-manager-driven milestone planner. Gated phases — feature dump → cluster → sequence → premortem & re-prioritize → approve → write. Narrates reasoning at every step, and runs a premortem + re-prioritization of the whole roadmap whenever a milestone is added or modified. Auto-triggers when no g-docs/ROADMAP.md exists, no active milestone is present, or the developer drops an explicit multi-feature dump or asks for a full re-plan (a single dropped idea routes via /g-intake first). Never writes g-docs/ROADMAP.md until the developer explicitly approves. |
| `/g-forge specialize` | Determine which stack profiles to apply by reading the project brief, roadmap, and dependency files. Handles multi-stack projects. Detects known stack combos and installs combo architecture rules covering emergent cross-stack patterns. Consults code-lead when the picture is ambiguous or risky. Installs architect agents, a write-side implementer agent per stack, and architecture rules. Supported stacks: angular, asp-net-core, astro, bun, c-embedded, capacitor, cpp-cmake, django, electron, express, fastapi, flask, flutter, go-fiber, go-gin, godot-csharp, godot-gdscript, hono, kotlin-android, kotlin-ktor, laravel, maui, nest-js, next-js, node-ts, nuxt, phoenix-liveview, pygame, python-cli, python-data, python-ml, python-textual, rails, react, react-native, remix, rust-axum, rust-cli, spring-boot, sveltekit, swift-ios, tauri, unity, unreal, vue-pinia, wpf-csharp, xamarin, claude-plugin. Supplementary: frontend-data-flow (auto-installed alongside component frameworks). |
| `/g-forge intake` | Proactive feature-drop triage. When the developer drops a feature idea mid-stream, classify it against the brief (on-brief / scope-creep / out-of-scope), propose where it belongs (existing milestone, new milestone, or backlog) with a version impact and a one-line risk hint — then ask before writing anything. The fast front-end to /g-roadmap for single ideas. |
| `/g-forge brief` | Refresh g-docs/project_brief.md as the project evolves — reads current state, asks targeted questions, and updates the brief without a full re-onboard. |
| `/g-forge align` | Brief-deviation check. Compares the project's actual trajectory (ROADMAP progress, recent commits, the observer journal) against the original g-docs/project_brief.md — goals, non-goals, MVP, tech decisions — and reports whether the work is still serving the brief. Advisory, never blocks. Auto-runs at milestone close; nudged periodically between milestones. |
| `/g-forge plan` | Decompose the current request into atomic tasks and produce a parallel wave schedule. Runs task-decomposer then wave-planner. Use at the start of any multi-step implementation. |
| `/g-forge execute` | Execute an approved wave plan by dispatching parallel subagents per wave. Use after /g-plan is approved, or to resume a plan that was interrupted. Argument: optional wave number to start from (default: Wave 1). |
| `/g-forge review` | Run the review gate on the current branch diff. Runs the test suite, captures the diff, and dispatches code-lead, which verifies done conditions and reviews the diff itself. Issues MERGE READY or HOLD. |
| `/g-forge doc-review` | Documentation review gate. Dispatches the doc-reviewer agent on the changed file set to check documentation currency against the code it describes, then issues a standalone DOCS READY or DOCS HOLD verdict. On DOCS READY it writes the doc-approval sentinel that the commit gate checks for doc/mixed commits. Read-only on project content — it judges and gates, never writes docs. Distinct from /g-review (code review) and /g-docs (audits and generates docs). |
| `/g-forge afk` | Autonomous milestone executor. Requires an approved plan. Runs all pending waves and auto-review with no between-step check-ins. Uses an Opus-class or newer top-tier model for orchestration. Ends with a structured handoff telling the user what to test and review. |
| `/g-forge listen` | Enter listen mode — collect user reports and information without acting, then synthesize and triage when the user signals done |
| `/g-forge help` | Context-aware help. With no argument, reads current project state and tells you where you are and what to do next, plus a map of every archive. With a topic or question argument (`/g-forge help <topic>`), answers it and points you at the right command or archive. |
| `/g-forge status` | Quick one-shot snapshot of current workflow state: active plan, wave progress, review gate, current milestone. |
| `/g-forge resume` | Re-hydrate a fresh session with the right slice of the durable record. The read-side counterpart to /g-retro — selectively retrieves the relevant retro, ADRs, journal, and handoff keyed by the current branch/milestone/first-task, and assembles a focused re-entry briefing. Loads distilled context into a clean window, not a poisoned transcript. Auto-nudged on the first prompt of a session when a handoff is pending. Verifies the clone is current with origin first — fast-forwarding only at session start, when strictly behind on a clean tree — before any file is read. |
| `/g-forge forecast` | Run scope-realism analysis and premortem on an approved-or-pending plan. Outputs a complexity score, a quantified likelihood that ≥1 premortem scenario fires, and a ranked list of likely failure scenarios seeded by /g-patterns history. Plan-time gate, never blocks — surfaces risk for human judgment. |
| `/g-forge blast-radius` | Analyse the blast radius of a planned change. Inputs a file path, feature name, or list of paths from a plan. Outputs the set of dependent files (forward and reverse references), a per-file volatility score (commit frequency proxy), and a total blast-radius rating (low / moderate / wide). Read-only. |
| `/g-forge refactor` | Guided refactor workflow — identify target, pre-analyse, spec, approve, execute, review. Accepts a scope path, an audit milestone file, or runs interactively. Safe-by-default: checks test coverage before execution and runs the full review gate after. |
| `/g-forge retro` | Synthesize a session retrospective from the silent-observer journal — no interview. Reads the passive activity log (.claude/journal/), git history, and g-docs/todo.md, and writes g-docs/retros/YYYY-MM-DD-topic.md with what happened, decisions inferred, patterns, and cold-start context. |
| `/g-forge patterns` | Two-phase pattern lifecycle. MINE — read g-docs/retros/ and g-docs/todo-done.md for recurring failure patterns, print a detailed chat report, and save an abstracted, externally-shareable report to g-docs/patterns/ for any pattern observed ≥2 times. RESOLVE — in a later, fresh session, check g-docs/inbox/adversarial/ for external counter-reports, re-derive each pending pattern's concrete edit from source, and apply/defer/dismiss (or withdraw, when an external counter-report is presented alongside it) with developer approval. |
| `/g-forge adr` | Capture an architectural decision record. First triages whether the decision merits an ADR or just a one-line entry in the brief's tech-decisions table (keeping the corpus rare and high-signal). Captures pre-deliberated reasoning or interviews from scratch, offloads the high-branching weighing to a throwaway deliberation subagent (keeps HQ's context clean), and promotes only the finalized draft to g-docs/decisions/NNN-title.md. Runs a mandatory reversibility check + premortem (premortem depth scales with reversibility) so the developer has the full picture before building. On a consequential decision it closes the loop — runs /g-retro and recommends a fresh session whose first task is verifying the ADR. Run when making a significant technical choice. |
| `/g-forge roundtable` | Bind the session to "the Roundtable" — a shared live Doc that is the human-facing communication layer between you, non-programmers (PMs, collaborators), and the session. start binds a Doc (create-from-template or attach-by-URL); sync reads the Roundtable at a boundary and writes only salient deltas; close distills the live Doc into the durable record (handoff + ADRs + action list) on a human nod. Works solo or shared. Off by default — when no Roundtable is configured every path is a no-op and behaviour is byte-identical to today. |
| `/g-forge telemetry` | Compute the 8 reliability metrics defined in g-docs/telemetry-metrics.md, derive a health profile (stable / cautious / defensive / recovery), and write it to .claude/telemetry-profile for adaptive orchestration in /g-execute and /g-review. Read-only on history; never modifies retros, forecasts, or git state. |
| `/g-forge identity` | Synthesise the project's operational identity from accumulated history — recurring risks, architectural personality, delivery cadence, characteristic strengths and friction points. Output is a narrative summary written to g-docs/identity.md plus a printed snapshot. Read-only. |
| `/g-forge audit` | Full-codebase or targeted code quality audit. Detects SOLID violations, code smells, architectural drift, dead code, and test coverage gaps. Targeted scope produces an inline report. Whole-codebase scope produces a prioritised roadmap milestone. |
| `/g-forge optimize` | Full-codebase or targeted performance audit. Detects algorithmic complexity problems, N+1 queries, re-render waste, resource leaks, and caching opportunities. Targeted scope produces an inline report. Whole-codebase scope produces a prioritised roadmap milestone. |
| `/g-forge docs` | Documentation audit and generation. Scans for missing or stale code docs, missing README sections, undocumented env vars, CHANGELOG gaps, and architectural decisions without ADRs. Targeted scope fixes gaps immediately via doc-writer. Whole-codebase scope produces a prioritised documentation debt report and optional roadmap entry. |
| `/g-forge wiki` | Build and maintain a human-facing project wiki in g-wiki/ — narrative documentation of what the project is, how it's architected, how each major area works, and how to use it. Synthesizes from the codebase, ROADMAP, ADRs, and brief via the doc-writer agent. Run anytime; queued as a task at the end of every milestone so the wiki tracks the product. Distinct from /g-docs (which audits code-level doc hygiene — docstrings, READMEs, env vars, ADRs). |
| `/g-forge doctor` | Read-only health diagnostics for G-Forge projects — 25 checks including hook registration, installed-copy drift, Check 23 plugin-version-lag, Check 24 CLAUDE.md injection-rule compliance, and Check 25 integration-tier guard. Recommends `/plugins` or `/g-update` by direction. Never writes. |
| `/g-forge update` | Fix G-Forge-managed files via Step 0 staleness preflight (stops with zero writes if cache lags GitHub, directs to `/plugins` first), then realigns CLAUDE.md Rules, agents, architecture rules, hooks, and native pre-commit gate. Safe — G-Forge markers only. |
| `/g-forge tier` | Switch the G-Forge integration tier between `full` (default — all hooks fire, all workflows auto-trigger), `balanced` (state hooks only, no auto-triggers, commit gate still on), and `light` (workflow-checkpoint only, commit gate off — opt-out mode). Writes `.claude/integration-tier`. |
| `/g-forge voice` | Set how G-Forge communicates with you. With no argument, runs a short 2-question intake and sets the right profile automatically — you never need to know the tier names. With `dev`, `mid`, or `eli5` as an argument, applies that profile directly. Writes `.claude/voice-profile`. Every G-Forge skill reads this and renders its output accordingly. |
| `/g-forge train` | Activates training mode. Establishes the learner profile, confirms or generates a project idea, and writes .claude/training-mode. PM then takes the session from there — in training mode, PM is the mentor: explains why each step exists, assigns tasks alongside waves, and runs post-wave check-ins. The full G-Forge workflow applies unchanged. |
| `/g-forge trim` | Use proactively once a week. Read-only audit of CLAUDE.md, its @-import targets, and agent memory for bloat, orphaned references, duplicate rules, and stale content. Reports issues for human review — never modifies any file. Writes .claude/last-trim on completion. |
| `/g-forge skill-design` | Design a new G-Forge skill from scratch. Gathers requirements, drafts SKILL.md with correct structure, and registers the new skill's bare token on all three router surfaces. |
| `/g-forge skill-validate` | Validate a skill or agent file against G-Forge structural rules. Checks SKILL.md format, retired-shim absence, router registration, and agent frontmatter. Issues VALID or NEEDS FIXES verdict. |

---

## Agents

**19 agents** — from `g-docs/agents.md`. Stack-specific architect and implementer agents are installed per-project by `/g-specialize` and are not listed here.

| Agent | Tier | Role |
|-------|------|------|
| `task-decomposer` | Sonnet | Breaks any request into atomic, verifiable tasks with mechanically checkable done conditions. |
| `wave-planner` | Sonnet | Takes a task list and produces a parallel wave execution schedule by mapping dependencies. |
| `spec-writer` | Sonnet | Produces a precise implementation spec from a brief or task — precise enough for a Haiku agent to execute without making judgment calls. |
| `feature-implementer` | Sonnet | Generic, stack-agnostic wave implementer — implements one wave task to its done condition using a single committed approach. |
| `code-reviewer` | Opus | Reviews code changes for quality, logic errors, and DRY violations. |
| `architecture-enforcer` | Opus | Enforces layer boundaries, import directions, and single responsibility. |
| `security-auditor` | Opus | Audits code for OWASP Top 10, injection, secrets, and auth flaws. |
| `code-lead` | Opus | Guards technical quality at every level — milestone feasibility, commit reviews, and merge gates. |
| `performance-auditor` | Sonnet | Audits code for N+1 queries, O(n²) paths, and hot-path issues. |
| `debugger` | Sonnet | Root cause analysis and fix strategy from error traces. |
| `error-detective` | Sonnet | Log and stack trace pattern analysis. |
| `test-writer` | Haiku | Writes unit, integration, and e2e tests from specs. |
| `doc-writer` | Haiku | Writes inline documentation explaining WHY, not WHAT. |
| `doc-reviewer` | Opus | Documentation review gate — checks accuracy vs code, currency, completeness, and clarity. |
| `pr-writer` | Haiku | Writes PR descriptions from git diff. |
| `refactor-executor` | Haiku | Executes a refactor spec exactly — no scope creep, no judgment calls. |
| `dependency-auditor` | Sonnet | Audits manifests for security advisories, deprecations, license conflicts, and unused declarations. |
| `project-manager` | Sonnet | Governs the session's PM voice and challenges scope — maintains milestones, breaks product goals into wave plans. |
| `review-orchestrator` | Sonnet | (Shipped but not currently dispatched) Coordinates the full review pipeline and aggregates findings. |

---

## Stack Profiles

**48 stack profiles** — from `profiles/*/rules/architecture.md`. Each profile adds a stack-specific architect agent (read-side) and a matching implementer agent (write-side), plus architecture rules. Installed per-project by `/g-specialize`.

### Web Frontend (8 profiles)

`react` · `next-js` · `nuxt` · `vue-pinia` · `sveltekit` · `angular` · `astro` · `remix`

### Node / Go / Rust Backend (8 profiles)

`node-ts` · `express` · `nest-js` · `go-gin` · `go-fiber` · `rust-axum` · `hono` · `bun`

### Python / Ruby / PHP (9 profiles)

`fastapi` · `django` · `flask` · `laravel` · `rails` · `python-textual` · `python-cli` · `python-ml` · `python-data`

### JVM / .NET (8 profiles)

`spring-boot` · `asp-net-core` · `kotlin-ktor` · `kotlin-android` · `phoenix-liveview` · `wpf-csharp` · `maui` · `xamarin` (legacy)

### Mobile / Desktop (6 profiles)

`react-native` · `flutter` · `swift-ios` · `electron` · `tauri` · `capacitor`

### Game Dev + Systems (8 profiles)

`unity` · `unreal` · `godot-gdscript` · `godot-csharp` · `pygame` · `cpp-cmake` · `rust-cli` · `c-embedded`

### Claude Code Plugin (1 profile)

`claude-plugin` — architect agent + architecture rules for Claude Code plugin development

---

## Supplementary Profiles

**1 supplementary profile**:

| Profile | Coverage |
|---------|----------|
| `frontend-data-flow` | Covers the two-network model (read/write) and the four canonical frontend violations (HTTP in components, shadow-state ref sync, watch-as-dispatch, caller-follows-truck). Auto-installs alongside any component-framework profile (react, vue-pinia, nuxt, next-js, sveltekit, angular, remix, astro, or any astro-* combo) — never replaces the per-framework architect. |

---

## Combo Profiles

**7 combo profiles** — auto-detected by `/g-specialize` when your project uses two stacks that have emergent cross-stack patterns. Combo profiles install rules only — no architect agent.

| Combo | Required stacks | Patterns covered |
|-------|-----------------|-----------------|
| `electron-react` | electron + react | contextBridge API layer, IPC channel constants, cross-window state |
| `electron-vue-pinia` | electron + vue-pinia | contextBridge + Pinia IPC integration, cross-window state |
| `react-tauri` | react + tauri | `invoke()` typed API layer, Tauri event hooks in React, capability scoping |
| `tauri-vue-pinia` | tauri + vue-pinia | `invoke()` typed API layer, Pinia + Tauri event subscriptions, capability scoping |
| `astro-react` | astro + react | Island isolation, serializable prop contract, cross-island state via nanostores, React hydration directives |
| `astro-vue` | astro + vue-pinia | Island isolation, serializable prop contract, cross-island state via nanostores, Vue hydration directives |
| `astro-svelte` | astro + sveltekit | Island isolation, serializable prop contract, native Svelte store sharing across islands, hydration directives |

---

## See also

- **Full agent reference:** `../g-docs/agents.md`
- **Architecture rules and constraints:** Each stack profile's `profiles/<name>/rules/architecture.md`
- **Stack implementer agents:** `profiles/<stack>/agents/<stack>-implementer.md` (installed per-project)

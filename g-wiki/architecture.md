# G-Forge Architecture (v2.6)

G-Forge installs an enforced engineering process into any Claude Code project. The system layers stack as follows.

## System Layers

### Command Router → Skills → Agents → Enforcement

**`commands/g-forge.md`** — Single hand-maintained umbrella. Contains bare-token subcommand list only; routes to `skills/<name>/SKILL.md` at dispatch. No per-skill prose duplication — [ADR-007](../g-docs/decisions/007-one-command-per-skill-retire-shims.md) enforces one skill, one file, one visible entry.

**`skills/<name>/SKILL.md`** — Workflow definitions. Each skill is the sole authored source of its behavior: YAML frontmatter (name, description, memory-layer declarations per [G-RULES §J](../G-RULES.md)), an `**Announce:**` line, numbered workflow steps, and a `## Rules` section. Skills invoke no `Skill()` calls; they are pure instructions for a Claude session to follow. The repo ships 38 skills covering the full lifecycle: `/g-kickoff` (discovery interview), `/g-roadmap` (planning), `/g-plan` (decompose), `/g-execute` (parallel dispatch), `/g-review` (merge gate), `/g-retro` (synthesis), plus analysis and configuration tools.

**`agents/`** — Single-use, tool-bounded agents that surface findings without implementing fixes (except implementer roles). Each agent receives one task, one attempt. On failure: return `FAILED` + `LEARNINGS:` distilling the mechanism and failure point; HQ deploys a fresh agent with a different approach, seeded only by learnings. Prevents **context poisoning** (a failed exploration's crossed-out reasoning poisons a reused agent's window).

The 19 agents ([`rules/dispatch-matrix.md`](../rules/dispatch-matrix.md) canonical list) split into classes:
- **Judgment reviewers** (code-lead, doc-reviewer, security-auditor, code-reviewer, architecture-enforcer) — Read/Glob/Grep only; surface findings with severity; emit verdict.
- **Diagnostics** (debugger, error-detective, dependency-auditor, performance-auditor) — Add Bash; verify, reproduce, confirm fixes work.
- **Implementers** (feature-implementer, stack implementers, refactor-executor, test-writer, doc-writer, pr-writer) — Add Write/Edit; scope to their own output files.

Frontmatter specifies `model:` and `effort:` per [ADR-016](../g-docs/decisions/016-model-economy-dispatch-matrix.md); skill dispatch reads [`rules/dispatch-matrix.md`](../rules/dispatch-matrix.md) lazily to recommend model scaling and per-lane escalation bounds.

**`profiles/<stack>/`** — Stack-specific architect agents and layer rules, installed per-project by `/g-specialize`. Enforce import directions, state ownership, and side-effect boundaries. Read-only verification only; kept and dieted per [ADR-015](../g-docs/decisions/015-g-specialize-diet-not-regenerate.md) — deterministic logic moved to `scripts/detect-stack.sh` and `scripts/derive-owns.sh`.

## Three Layers Added in v2.6

v2.6 (the token-diet release, [ADR-014](../g-docs/decisions/014-v26-token-diet-reopens-after-freeze.md)) moved prose and logic out of skill cores to three disk layers, loaded on demand rather than shipped in every session:

### Lazy `references/` Layer

Essays, edge-case notes, and rationale that fires only when a specific condition arises, never @-imported. Structured under three homes:

- **`skills/*/references/*.md`** — Skill-specific notes. Example: `skills/g-review/references/round-consolidation.md` (procedure when Critical/Major findings recur across rounds); `skills/g-doctor/references/check-16-drift.md` (architect drift hash-comparison logic).
- **`rules/references/*.md`** — Cross-cutting doctrine moved out of the rules chain. Example: `rules/references/context-gate.md` (context capacity reasoning, loaded on amber/red gate fire); `rules/references/workflow-notes.md` (orchestration patterns).
- **No agent references** — the 19 agents' full text remains in-tool (they are infrequently dispatched and rarely re-prompted; context poisoning risk is per-agent, not per-session).

The repo ships 63 skill reference files + 9 rule reference files — 72 total, ~37.5k words preserved; none are read during normal execution ([M53 measured words](../g-docs/milestones/M53-v2.6-token-diet.md)). Counts derived 2026-09-02 from `ls skills/*/references/*.md rules/references/*.md` and `cat … | wc -w` at `c24d594`.

### Scripts Layer

Deterministic decision logic and I/O parsing moved out of skill prose into shell scripts with a `KEY: value` output contract, always exiting 0. Supports bash-only dispatch (e.g., `/g-resume` can check repo state without model):

- **`skills/*/scripts/*.sh`** — 26 scripts across the skill tree. Example: `skills/g-init/scripts/scaffold.sh` (deterministic g-docs skeleton creation); `skills/g-review/scripts/build-review-pack.sh` (single source for pack building, used by all five reviewers); `skills/g-doctor/scripts/checks.sh` (all 25 diagnostic checks — 16 required + 9 advisory, derived 2026-09-02 from `skills/g-doctor/SKILL.md`, indexed by skill).

Every script carries a bash header documenting its output contract. Skills read these outputs via e.g. `"$(skills/g-init/scripts/detect-state.sh)"` and interpret KEY: value pairs ([G-RULES §A3](../G-RULES.md)).

### Dispatch Matrix & Haiku-Executability Standard

Every agent carries pinned `model:` and `effort:` frontmatter; the canonical table lives in `rules/dispatch-matrix.md`, installed as `.claude/rules/g-dispatch-matrix.md` (never @-imported — read lazily by `/g-execute` and `/g-refactor` dispatch). [ADR-016](../g-docs/decisions/016-model-economy-dispatch-matrix.md) pins 19 agents across five role lanes; the matrix governs both model recommendations and per-lane escalation bounds. Judgment reviewers (code-lead, doc-reviewer, security-auditor) stay at the top tier — quality loss is the forbidden trade; mechanical work (refactor-executor, pr-writer) run on Haiku with an upfront gate.

The **Haiku-Executability Standard (HES)** — six items all present: exact paths, closed steps, command-verifiable done, zero unstated context, no judgment residue, bounded scope — gates every dispatch to a haiku-tier implementation executor. Task specs failing HES escalate via one spec-tightening round; still failing → re-tag to a mid-tier executor ([`rules/dispatch-matrix.md` §Haiku-Executability Standard](../rules/dispatch-matrix.md)).

## Enforcement: Two Hook Classes

G-Forge enforcement lives in `hooks/` — standalone POSIX bash scripts with zero Claude runtime dependency. Two contract classes coexist (why: [ADR-003](../g-docs/decisions/003-why-two-gate-sites.md)):

**Plugin hooks** (Claude Code) — registered in `.claude/settings.json`, fire on `PreToolUse`, `SessionStart`, `PostToolUse`, `PreCompact`, `UserPromptSubmit`:
- **`check-commit.sh`** (PreToolUse) — blocks commits missing `.claude/g-forge-approved` sentinel.
- **`session-start.sh`** (SessionStart) — prints workflow banner, surfaces ahead/behind vs. origin; nudges `/g-resume` on pending handoff.
- **`workflow-checkpoint.sh`** (UserPromptSubmit) — reads branch/milestone state on every prompt; surfaces in system reminder; nudges `/g-resume` or next step auto-trigger.
- **`observe.sh`** + **`agent-lifecycle.sh`** (PostToolUse) — silent observer, journals commits, agent dispatch, tests to `.claude/journal/YYYY-MM-DD.jsonl`.
- **`pre-compact.sh`** (PreCompact) — snapshots context-gate state, tightens thresholds on compaction.

**Native git hook** — **`hooks/pre-commit`** ([ADR-004](../g-docs/decisions/004-two-truths-of-the-gate.md)) — installed into `.git/hooks/`, fires natively on every `git commit`. Verifies `git write-tree` hash against the review sentinel; denies on mismatch (edit-after-approval, stale sentinel, unreviewed content). This is the **authoritative enforcement site** because git has already staged modifications — the hook sees exactly what will commit.

**Why two classes:** PreToolUse runs *before* staging so it cannot see `-a`/`-p` modifications; the native hook runs *after* staging with full visibility. Together: rich messaging (model can explain the denial) + mathematical correctness (hook sees staged tree).

### Sentinel & Classification

**`hooks/lib/classify-changeset.sh`** — Single classification engine used by both enforcement sites. Buckets a changeset into CODE, DOC, or MIXED by examining file paths against consistent rules. Ensures whatever code-lead review sees, the gate guards.

**`.claude/g-forge-approved`** — Ephemeral approval sentinel, stamped by `/g-review` with `git write-tree` hash (proof of which tree was reviewed) + HEAD sha (proof of review). Consumed by `pre-commit` on match, deleted by `post-commit-cleanup.sh` after each commit. Per-worktree keying prevents laundering unreviewed code across linked trees ([ADR-005](../g-docs/decisions/005-per-worktree-approval-keying.md)).

## Project Record & Configuration

**`.claude-plugin/`** — `plugin.json` + `marketplace.json` with identical version numbers (a release blocker if they diverge). Current: v2.6.1.

**`g-docs/`** — Canonical home for all G-Forge-generated project records:
- `ROADMAP.md` — Milestone plan + `## Active Session` handoff (the single cold-start for a fresh session).
- `milestones/M*.md` — Per-milestone scope, tasks, done conditions.
- `decisions/NNN-*.md` — Architectural Decision Records (16 to date, 001–016) covering core design choices and trade-offs. New in v2.6: [ADR-014](../g-docs/decisions/014-v26-token-diet-reopens-after-freeze.md) (token diet rationale), [ADR-015](../g-docs/decisions/015-g-specialize-diet-not-regenerate.md) (g-specialize decision), [ADR-016](../g-docs/decisions/016-model-economy-dispatch-matrix.md) (dispatch matrix).
- `agent-output/` — Timestamped subdirectories by wave/task, containing dispatch prompts, agent outputs, and synthesized findings.
- `retros/YYYY-MM-DD.md` — Session retrospectives auto-synthesized by `/g-retro` from the silent observer journal.
- `todo.md` + `todo-done.md` — Tactical task ledger (committed; closed tasks moved to todo-done each pass).

**`G-RULES.md`** — Installed at project root by `/g-init`; rule chain split in v2.6:
- Normative cores (§A–J) stay @-imported in `CLAUDE.md` — `rules/g-rules/A-session.md` … `J-memory.md`, ~7.1k words total (derived 2026-09-02 from `cat rules/g-rules/*.md | wc -w` at `c24d594`).
- Essays and edge-case doctrine move to `rules/references/` (loaded on demand, never imported).

## Why This Shape

### Enforcement travels in the repo

G-Forge's spine is **enforcement that travels**: every clone inherits the gate from committed `.claude/settings.json` + `.claude/rules/` + `.claude/hooks/` (via `/g-init` synchronization). A project cannot opt out of the gate — the gate is automatic on every commit. This is the load-bearing differentiator vs. advisory process ([ADR-003](../g-docs/decisions/003-why-two-gate-sites.md) documents why Cowork, which doesn't fire hooks, cannot host G-Forge).

### Dogfooding the plugin itself

G-Forge installs on its own source repo (this repo). All hooks + rules + skills must work on G-Forge's own code before shipping. **Self-hosting is split by hook class** ([ADR-008](../g-docs/decisions/008-self-host-split.md)):

- **Non-gating components** (observers, checkpoint, rules files, profile agents) install eagerly at slice-close — degrade-silent by design.
- **Gating components** (`check-commit.sh`, native `pre-commit`) install at verified checkpoints in a scratch clone, exercised against real commits before touching the live repo.

The `/g-update` skill self-detects when it runs on the plugin source itself (`.claude-plugin/plugin.json` present) and installs from the working tree instead of the marketplace cache.

### Token diet architecture

v2.6 reduces per-session context bloat while preserving zero quality loss. The three-layer addition (scripts, lazy references, dispatch matrix) moves execution logic and reasoning essays off the hot path:

- **Scripts** execute bash-native decisions (no model inference).
- **References** load on-demand when their specific edge fires, never in the default path.
- **Dispatch matrix** moves model economy logic out of prose into a data table, read once per skill invocation.

The result: 38 SKILL.md cores dropped −43% (median), from 84k → 48k words ([M53 measured](../g-docs/milestones/M53-v2.6-token-diet.md)), with zero gate removed, no round count capped, identical verdicts. The 27× token multiplier vs. ungoverned process is accepted as the price of quality; v2.6 pays half that price.

### Single-use agents, fresh per attempt

Agents are never reused or re-prompted ([G-RULES §C](../G-RULES.md)). Each agent gets one approach. If it fails, it returns `FAILED` + `LEARNINGS:` (distilled mechanism, failure point) and is discarded. HQ deploys a **fresh agent** with a different mechanism, seeded only by learnings — never the dead agent's context. **Three-Strikes rule:** Same bug class × 3 failed agents = stop, escalate, name the mechanism.

## Reference Documents

The following g-docs files document specific operational patterns and are reachable from this architecture:

- [../g-docs/env-vars.md](../g-docs/env-vars.md) — Environment variable contracts for hooks and tests.
- [../g-docs/memory-taxonomy.md](../g-docs/memory-taxonomy.md) — Memory layer lifetime, audience, and content classification (Tiers 1–5).
- [../g-docs/orchestration-patterns.md](../g-docs/orchestration-patterns.md) — Standard four workflows built from G-Forge agents (auto-trigger, manual dispatch, escalation ladder, reset).

## Key Constraints

1. **No build step, no package manager** — G-Forge is markdown (skills/commands) + bash hooks. Sync-at-build is unavailable; [ADR-007](../g-docs/decisions/007-one-command-per-skill-retire-shims.md) exemplifies: delete redundant two files, keep one source.

2. **Portable POSIX shell only** — Hooks run cross-platform (Windows, macOS, Linux) in git-bash. Forces `git write-tree`/`git rev-parse`/`git hash-object` over any crypto; JSON via jq; no external CLIs beyond core git.

3. **Fail toward enforcement** — Any ambiguity in the gate denies, never silently passes. A non-blocking gate is a shipped bug.

4. **Doctrines over mechanisms** — When an approach cannot be structurally enforced (e.g., agents not thrashing a failed context), embed the rule in the skill's plain-language instructions and check it via agent-side output format (learnings, done conditions).

5. **Quality outranks token savings** — [ADR-016](../g-docs/decisions/016-model-economy-dispatch-matrix.md) §Decision: judgment reviewers (code-lead, doc-reviewer, security-auditor) stay at top tier. A reviewer that misses real bugs is the forbidden quality loss; "inert dispatch surface" arguments fail because proactive agent descriptions allow auto-dispatch in real projects.

## Links

- [Usage](usage.md) — Workflow from the user's perspective.
- [Commit Gate](commit-gate.md) — Approval sentinel and gate mechanics.
- [README](README.md) — Quick start and skill index.
- [g-docs/ROADMAP.md](../g-docs/ROADMAP.md) — Full milestone plan.
- [g-docs/decisions/](../g-docs/decisions/) — 16 Architectural Decision Records; v2.6 introduces ADR-014 (token diet), ADR-015 (g-specialize), ADR-016 (dispatch matrix).
- [../CLAUDE.md](../CLAUDE.md) — Project rules and quick commands.

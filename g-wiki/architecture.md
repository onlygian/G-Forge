# G-Forge Architecture

## System Layers

G-Forge installs an enforced engineering process into any Claude Code project. The system layers stack as follows:

### Command Router → Skills → Agents → Enforcement

**`commands/g-forge.md`** — Single hand-maintained umbrella (per [ADR-007](../g-docs/decisions/007-one-command-per-skill-retire-shims.md)). Contains bare-token subcommand list only; routes to `skills/<name>/SKILL.md` at dispatch. No per-skill prose or duplicated descriptions — one skill, one file, one visible entry.

**`skills/<name>/SKILL.md`** — Multi-step workflow definitions. Each skill is the **sole authored source** of its behavior: YAML frontmatter (name, description, optional memory layers per G-RULES §J), `**Announce:**` line, numbered steps, and a `## Rules` section. Skills invoke no `Skill()` calls; they are pure instructions for a Claude session to follow. ~38 shipped skills cover the full lifecycle: `/g-kickoff` (interview), `/g-roadmap` (plan), `/g-plan` (decompose), `/g-execute` (parallel dispatch), `/g-review` (gate), `/g-retro` (reflect), plus deep-analysis and configuration tools.

**`agents/`** — Single-use reviewer agents that surface findings without implementing fixes. Three tool classes exist:
- **Reviewer** (Read, Glob, Grep) — analyzes code, searches patterns, reports findings.
- **Diagnostic** (+ Bash) — runs verification, reproduces bugs, confirms fixes work.
- **Writer** (+ Write/Edit) — authors documentation, tests, or implementations scoped to their own record files. Implementer agents own `/g-execute` wave output files only; they never touch review artifacts or the durable record.

All agents include name, description, model, and tools in frontmatter. Reviewer severity follows the tested contract: code-reviewer, performance-auditor, and dependency-auditor report Critical/Major/Minor with a `RESULT: PASS|HOLD` verdict line; security-auditor keeps its native Critical/High/Medium/Low (the orchestrator normalizes it); architecture-enforcer emits the verdict with a violations list, no severity ladder; doc-reviewer uses BLOCKING/WARNING.

**`profiles/<stack>/`** — Stack-specific architect agents and layer rules, installed per-project by `/g-specialize`. Enforce import directions, state ownership, and side-effect boundaries. Read-only verification only.

### Enforcement: Two Hook Classes

G-Forge enforcement lives in **`hooks/`** — standalone POSIX bash scripts with zero Claude runtime dependency. Two contract classes coexist:

**Plugin hooks** (Claude Code) — registered in `.claude/settings.json`, fire on `PreToolUse`, `SessionStart`, `PostToolUse`, `PreCompact`, `Stop`. Read stdin JSON; deny via JSON object on stdout + `exit 2`. Cover:
- **`check-commit.sh`** (PreToolUse) — blocks commits missing `.claude/g-forge-approved` sentinel.
- **`session-start.sh`** (SessionStart) — prints the session banner, resets the per-session counters, and surfaces an advisory behind/ahead line against `origin/<branch>`.
- **`observe.sh`** + **`agent-lifecycle.sh`** (PostToolUse) — silent observer: journals commits, agent dispatch, tests to `.claude/journal/YYYY-MM-DD.jsonl`. No chat output.
- **`pre-compact.sh`** (PreCompact) — snapshots context gate state, tightens thresholds on evidence.
- **`workflow-checkpoint.sh`** (UserPromptSubmit) — reads branch, milestone, integration tier on every prompt; surfaces in system reminder. Nudges (prints a suggestion, never triggers) `/g-resume` on a pending handoff — and `/g-resume` syncs with origin first, fast-forwarding only when safely possible at session start, before re-hydrating.

**Native git hook** — **`hooks/pre-commit`** (ADR-004). Installs into `.git/hooks/`, fires natively on every `git commit`, never bypassed by Claude Code hook changes. Verifies `git write-tree` hash against the review sentinel; denies on mismatch (edit-after-approval, stale sentinel, or unreviewed content). This is the **authoritative enforcement site** because git has already staged modifications — the hook sees exactly what will commit.

**Why two classes:** PreToolUse is rich (model can explain why a commit was denied) but runs *before* staging so it cannot see `-a`/`-p` modifications. The native hook runs *after* staging with full visibility. Together: rich messaging + mathematical correctness. (ADR-003 notes that Cowork does not fire either class, so G-Forge governance is inert there — a documented non-host.)

### Sentinel & Classification: Single Source of Truth

**`hooks/lib/classify-changeset.sh`** — Single classification engine used by both enforcement sites. Buckets a changeset into CODE, DOC, or MIXED by examining file paths against consistent rules. The **single-classifier invariant** ensures that whatever code-lead review sees, the gate guards. Shared library, one source.

**`.claude/g-forge-approved`** — Ephemeral approval sentinel, stamped by `/g-review` with `git write-tree` hash (what will commit) + HEAD sha (proof it was reviewed). Consumed by `pre-commit` on match, deleted by `post-commit-cleanup.sh` after each commit. The stamp binds approval to the exact tree — post-review edits invalidate it (ADR-004). Per-worktree keying prevents one approval from laundering unreviewed code across linked trees (ADR-005).

### Project Record & Configuration

**`.claude-plugin/`** — `plugin.json` + `marketplace.json` with identical version numbers (a release blocker if they diverge).

**`g-docs/`** — Canonical home for all G-Forge-generated project records:
- `ROADMAP.md` — Milestone plan + `## Active Session` handoff (committed, the single cold-start document for a fresh session).
- `milestones/M*.md` — Per-milestone scope, tasks, done conditions.
- `decisions/NNN-*.md` — Architectural Decision Records (13 to date, 001–013) covering the core design choices.
- `retros/YYYY-MM-DD.md` — Session retrospectives auto-synthesized by `/g-retro` from the silent observer journal.
- `todo.md` + `todo-done.md` — Tactical task ledger (committed; closed tasks moved to todo-done each pass).

## Why This Shape

### Enforcement travels in the repo

G-Forge's spine is **enforcement that travels**: every clone of the repo inherits the gate from committed `.claude/settings.json` + `.claude/g-rules/` + `.claude/rules/` + `.claude/hooks/` (via `/g-init` synchronization). A project cannot opt out of the gate by ignoring a prompt — the gate is automatic on every commit. This is the load-bearing differentiator vs. advisory process. (ADR-003 documents why Cowork, which doesn't fire hooks, cannot host G-Forge.)

### Dogfooding the plugin itself

G-Forge installs on its own source repo (this repo). All hooks + rules + skills must work on G-Forge's own code before shipping. **Self-hosting is split by hook class** (ADR-008):

- **Non-gating components** (observers, checkpoint, rules files, profile agents) install eagerly at slice-close — degrade-silent by design.
- **Gating components** (`check-commit.sh`, native `pre-commit`) install at verified checkpoints in a scratch clone, exercised against real commits before touching the live repo.

The `/g-update` skill self-detects when it runs on the plugin source itself (`.claude-plugin/plugin.json` present) and installs from the working tree instead of the marketplace cache. This closes the gap where the repo was developing v*N* while running v*N−1*, and bugs were found downstream in consumer projects first.

### Single-use agents, fresh per attempt

Agents are **never reused or re-prompted** (G-RULES §C). Each agent gets one approach. If it fails, it returns a `FAILED` + `LEARNINGS:` block (distilled mechanism + failure point) and is discarded. HQ deploys a **fresh agent** with a different mechanism, seeded only by the learnings — never the dead agent's context. This prevents **context poisoning**: a failed exploration's crossed-out reasoning poisons a reused agent's window, causing it to hedge and cling to rejected ideas. Fresh agents = clean starting points.

**Three-Strikes rule:** Same bug class × 3 failed agents = stop. Name the mechanism, escalate model, find a different approach. Retries are bounded and auditable.

## Coordination & The Multiplayer Arc

G-Forge is designed for solo development today. The multiplayer arc was designed but **is not on the G-Forge roadmap** — as of [ADR-012](../g-docs/decisions/012-g-forge-2.5-final-release-scope.md) (2026-08-10) M29, M30–M32, M33 and M34 are **fork-bound**: they leave with the G-Proof fork and are tracked in a local-only file, not in the committed roadmap. Only M33's Phase A (the Roundtable adapter, off by default) was ever built here. The design below is recorded because it shaped the architecture that *did* ship, not as work in flight:

- **M29** (Claim/lease register) — Shared resource claims with heartbeat decay, enabling concurrent sessions to signal occupancy without collisions.
- **M33** (The Roundtable) — A shared live Doc (Google Docs, Confluence, or Gmail depending on surface capability tier; ADR-001) that surfaces live state, feeds, and decisions. Humans write, sessions read/append. **Off by default** (gitignored `.claude/roundtable` binding file).
- **M34** (Cross-session orchestration) — Assignment, suggestion routing, and reconciliation (dependent on M29).
- **ADR-002** pins M33's design: one human orchestrator seat (the PM role), rotatable by handoff, holds the gavel for roadmap writes and tie-breaks.

These layers compose with the core enforcement: M29/M33 are **surface and communication**, not **gating**. The commit gate stays per-tree (local `pre-commit`), the review gate stays per-session. M29 prevents collisions; M33 surfaces coordination; M34 routes suggestions. Nothing bypasses local enforcement.

### Optimistic wave concurrency

**Parallel agents share one physical working tree.** ADR-006 adopts **optimistic concurrency**: agents run unrestricted; collisions are detected and absorbed at the wave boundary via a flight recorder (hashed file content + who wrote it) and mechanical restore. The mechanism is **effects-based** (content hashes), never command-string classification (the #21 anti-pattern). Absorbed collisions drop from incident to log line; a quantitative trigger (5% wave-token cost over 5 waves) gates future migration to per-agent worktree isolation. **Status: decided but not yet implemented** — ADR-006 is accepted, and its flight-recorder/restore mechanism is a planned post-M-audit milestone slice; today wave-close integrity is verified manually by HQ at each wave boundary.

## Key Constraints

1. **No build step, no package manager** — G-Forge is markdown (skills/commands) + bash hooks. Sync-at-build is unavailable; structural impossibility (delete duplicates) beats enforced discipline (police copies). ADR-007 exemplifies: instead of syncing command descriptions across three files, delete the redundant two and keep one source.

2. **Portable POSIX shell only** — Hooks run cross-platform (Windows, macOS, Linux) in git-bash on Windows. Forces `git write-tree`/`git rev-parse`/`git hash-object` over any crypto; JSON via jq; no external CLIs.

3. **Fail toward enforcement** — Any ambiguity in the gate denies, never silently no-ops. A non-blocking gate is a shipped bug (the pre-ADR-004 "edit-after-MERGE-READY" hole).

4. **Doctrines over mechanisms** — When an approach cannot be structurally enforced (e.g., agents never thrashing a failed context), embed the rule in the skill's plain-language instructions and check it via agent-side output format (learnings, done conditions), not automated verification.

## Links

- [Usage](usage.md) — Workflow from the user's perspective
- [Commit Gate](commit-gate.md) — How the approval sentinel works
- [README](README.md) — Quick start
- [g-docs/ROADMAP.md](../g-docs/ROADMAP.md) — Full milestone plan
- [g-docs/decisions/](../g-docs/decisions/) — all 13 ADRs (001–013); ADR-010 and ADR-012 govern the freeze/fork and the 2.5 scope
- [CLAUDE.md](../CLAUDE.md) — Project rules and quick commands

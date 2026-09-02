# ADR-016: Model economy — pinned dispatch tiers, the Haiku-executability standard, and rules that govern the governance

**Date:** 2026-09-02
**Status:** Accepted
**Reversibility:** two-way door (frontmatter keys and rule text; reversing is an ordinary edit plus one test update).
**Context:** v2.6, developer-requested: token preservation enforced at the model-suggestion level. Synthesized from two independent designs run from opposite priors (cost-first arguing agents up from haiku; quality-first arguing them down from top-tier), tie-broken by the v2.6 rule that quality outranks savings.

## Decision

**1. The dispatch matrix.** Every agent carries pinned `model:` + `effort:` frontmatter; the canonical table lives in `rules/dispatch-matrix.md`, installed as `.claude/rules/g-dispatch-matrix.md` and read lazily — never @-imported. Session tier is never inherited by dispatched agents. v2.6 changes zero `model:` values — all five gate/reviewer agents stay opus/xhigh (a reviewer that misses real bugs is the forbidden quality loss, and "inert dispatch surface" arguments fail because proactive agent descriptions allow auto-dispatch in real projects) — and pins `effort:` everywhere: mechanical apply=low, constrained procedure=medium, planning/diagnosis=high, gates=xhigh, never max (measured overthinking regression).

**2. The Haiku-executability standard (HES).** Six items — exact paths, closed steps, command-verifiable done, zero unstated context, no judgment residue, bounded scope — gate every dispatch to a haiku-tier implementation executor. spec-writer self-scores (`TARGET_TIER:` return line); `/g-execute` and `/g-refactor` verify before dispatch. On failure: one spec-tightening round, then re-tag to the sonnet implementer. **Escalating the model is the honest resolution of an open spec; degrading the spec is quality loss and forbidden.** Tier-gate events log to `.claude/tier-gate-log` — separate from `.claude/escalation-log`, whose telemetry metric must not be polluted.

**3. Per-lane escalation bounds** replace blanket profile inflation: defensive/recovery profiles bump judgment/diagnostic/executor lanes one tier; the mechanical lane bumps at most haiku→sonnet in recovery (a template fill does not get better at opus). Failed mechanical tasks escalate via HES/FAILED, not via profile.

**4. Downgrade unlocks are evidence-gated, not vibes-gated:** replay ≥10 real archived dispatches at the candidate tier, 0 missed Critical/Major across 2 independent sessions, verdict recorded as an ADR. Ranked candidates recorded in the matrix file (doc-reviewer and architecture-enforcer opus→sonnet first).

## Why

The 27× multiplier is partly tier-shaped: a top-tier session inheriting into 19 subagents re-prices mechanical work at judgment rates, and the recovery profile's "opus on every dispatch" was the same failure by policy. The repo already concentrates judgment into few seams (spec-writer closes judgment; code-lead holds the gate) — the matrix makes that architecture priced.

## Rejected

- **Demoting inert reviewers** (code-reviewer, architecture-enforcer opus→sonnet; review-orchestrator→haiku) — savings ~zero, auto-dispatch surface non-zero, evidence absent.
- **Effort restated per dispatch as the norm** — frontmatter is authoritative; a skill adds one advisory `Effort:` line only when a stage genuinely deviates.
- **HES canonical in spec-writer.md** — producer-owned copy exists there verbatim, but the canonical home is the matrix file: the single seam the future G-Agent fleet port maps onto (tier column ↔ planner/builder/executor/worker roles).

## Consequences

`tests/test-dispatch-matrix.sh` derives the agent list from disk (ADR-013) and fails on any frontmatter↔matrix mismatch and on HES copy divergence. Model/effort keys are recommendations the harness applies to subagents; sessions on any model run every skill unchanged.

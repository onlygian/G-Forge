# ADR-014: v2.6 token diet — development reopens after the v2.5 freeze

**Date:** 2026-09-01
**Status:** Accepted
**Reversibility:** one-way door for the release itself (published versions don't unpublish); two-way for every mechanism inside it (each is a repo-local convention reversible by ordinary edits).
**Context:** Decided by the developer on 2026-09-01, superseding ADR-012's "final G-Forge release" framing. Measured motive: the governance harness burns roughly 27× the tokens of an ungoverned process; the developer's verdict was that at that price the quality is not worth it.

## Decision

**1. v2.5.0 is no longer the final release.** ADR-012's minimal-freeze scope stands for what 2.5 contained; its finality claim is superseded. Development resumes with v2.6.

**2. v2.6 is a quality-preserving token diet: same checks, same verdicts, cheaper execution.** No gate is removed, no round count capped, no verdict literal changed, no knowledge deleted. Four mechanisms:
- **Prose→scripts** — deterministic decision logic in skills becomes `skills/<name>/scripts/*.sh` (KEY:-value output contracts, always exit 0), exemplar `skills/g-resume/scripts/sync-check.sh`.
- **Lazy references** — rationale essays move from SKILL.md cores to `skills/<name>/references/*.md`, loaded only when their edge fires. Same split applied to `rules/g-rules/` (normative core stays @-imported; essays to `rules/references/`, never imported).
- **Review-pipeline pack + delta rounds** — one deterministic pack builder replaces four independent derivations of the same diff; HOLD rounds re-review prior findings + the fix delta, with a closed-set escape back to full review. Sentinel semantics unchanged (pack tree = ADR-004 write-tree).
- **Model economy** — per-agent `model:`/`effort:` pins, the Haiku-executability standard, and per-lane escalation bounds (ADR-016).

**3. Process exception, this milestone only.** v2.6 was planned and executed by the session model directly with workflow orchestration, not through the `/g-*` pipeline — the one milestone where dogfooding would have meant executing skills while rewriting them, at the very burn rate under repair. The commit gate, test suites, and the durable record still apply. G-Forge-managed process resumes after the release.

## Why

The 772/772-green baseline plus the v2.5 gate arcs (a one-line awk fix shipping through 4 code rounds + 4 doc rounds) made both halves measurable: the quality machinery works, and its execution cost is dominated by re-reading, re-derivation, and instruction weight — none of which is where the quality lives.

## Rejected

- **Skipping reviewers / capping rounds** — trades scrutiny; forbidden by the quality-preserving premise.
- **Agent consolidation** — merging mandates risks blind spots; deferred.
- **Fleet offload to local models** — future goal per the developer; not in v2.6.

## Consequences

Proof obligation: all 24 suites green before and after, plus new suites for every new script. Consumer projects see installed-copy drift flags until `/g-update` re-syncs (by design). The 27× figure is a felt estimate, not instrumented; token accounting lands as roadmap backlog, so v2.6's measured claim is payload word counts, not a live multiplier.

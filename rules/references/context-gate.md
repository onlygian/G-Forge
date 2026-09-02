# Context gate — rationale and mechanics (G-RULES §A7 companion)

Load trigger: read this when the §A7 gate fires (amber or red), when a compaction occurs, or when editing the gate's thresholds or reset path. The normative rule lives in `.claude/rules/g-rules-A-session.md` §A7; this file holds the reasoning moved out of it (v2.6 token diet).

## Why the exchange count is only a proxy

The goal is to reset *before* the window ever compacts; a compaction means the gate fired too late. The exchange count is only a coarse proxy — actual ground truth is `/context`, and only the model can read it. That is why amber is **active monitoring**, not a one-time warning: capacity-driven reset is the actual prevention; the exchange count only decides when to start polling. Start lenient, tighten on evidence.

## Auto-calibration

The gate starts with lenient baseline thresholds (impl 30/45, conv 45/65) and auto-calibrates downward per project: every compaction grows a persistent offset (`.claude/context-threshold-offset`) subtracted from the baselines (floored), so the gate fires earlier next time until compaction stops recurring.

## Why the wave-boundary check is free and load-bearing

A wave (`/g-execute`) is the heaviest token-burn event there is and already a hold point, so checking `/context` right after each wave completes is essentially free — and it catches fast-burning sessions the exchange count misses.

## Compaction = gate failure, handled as a backstop

If a compaction still happens, the depth counter carries across the (non-fresh) `compact` SessionStart rather than resetting, `pre-compact.sh` records it and tightens the threshold, and `workflow-checkpoint.sh` surfaces the red reset off the count. A compaction is never a clean slate — it carries the same residue a deep session does — and each one teaches the gate to fire earlier so it doesn't recur.

## The two-sided reset

Promoting the clean record *out* — `/g-retro` + the `## Active Session` handoff — is one side. Pulling the right slice back *in* is `/g-resume`, run on the first prompt of the fresh session: it first verifies the clone is current with origin, then selectively re-hydrates the new clean window from the durable record (relevant retro, in-force ADRs, journal, handoff) keyed to the first task, so the new session inherits the knowledge without the residue. `workflow-checkpoint.sh` nudges `/g-resume` automatically when a session opens with a pending handoff. The same `/g-resume` re-entry serves both triggers of the reset — the quantitative red gate, and the semantic ADR-finalized trigger in §C.

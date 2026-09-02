# HOLD fix rounds — the bounded autonomous fix loop (loaded on any HOLD verdict)

/g-afk Step 4 loads this file when auto-review returns HOLD. The bound (max 3
rounds) and the Three-Strikes escalation live in the SKILL.md core; this file
carries the procedure and the [If HOLD:] handoff sub-block.

## The fix round (round 1 of max 3, directive 2026-08-22)

1. Dispatch scoped fix agents per the review findings — file scope bound to what each finding names.
2. Before each fix dispatch, sweep the restatement surface: grep the repo for every literal fact the fix is about to change, so the fix doesn't correct one carrier and leave a sibling stale.
3. Re-run `/g-review` — the pack builder enters delta mode automatically (the prior round's findings and the fix delta are the verdict scope); a `DELTA_INELIGIBLE` line means the fix escaped the reviewed set and the round runs full.
4. **MERGE READY** → continue to Step 5. **HOLD again** → repeat from (1), round + 1.
5. **Round 3 finishes without MERGE READY** → stop. Three-Strikes applies to reviews the same as any other bug class (G-RULES §A8) — do not attempt a 4th round. Escalate to the developer in Step 5's handoff with the full findings trail from all three rounds, not a fix list.

## Step 5 handoff — the [If HOLD:] sub-block (render byte-identical)

```
[If HOLD:]
  Review did not converge in 3 fix rounds — Three-Strikes applies (G-RULES §A8).
  Findings trail (all rounds):
    [List each round's review records under g-docs/agent-output/review/*-r<N>.md —
     the findings themselves — and each round's fix record under
     g-docs/agent-output/<wave>/fix-round-N-*.md, with what each round closed or
     carried forward.]
  Next:         developer decision required — this is not a fix list and not an
                instruction to run /g-review again. Review the trail above and
                choose: fix manually, re-scope, or accept the carried risk.
```

# Forecast: M48c — Code-gate teeth & new suites

> Created: 2026-08-21
> Plan: g-docs/plans/m48c-code-gate-teeth-and-new-suites.md
> Mode: regular

## Complexity
- Score: 7/10
- Breakdown: files 3 (11 distinct), waves 2 (5 waves), boundaries 1 (skill ↔ agent review-gate contract), new surface 1 (two new test suites), rule edits 0

## Miss-risk: 85% — High
- Raw score (pre-calibration): 89.5%
- Calibration: adjustment −4, N=59 confirmed outcomes, M=3 mitigation-held (sample floor met; hit_rate 0.28 — corpus over-predicts, adjustment negative)

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | Fix/count edit mints the next defect — tasks 8/9 restate suite counts and CHANGELOG facts; tasks 1/2 edit gate prose; every recent pass that edited enumerations minted a fresh stale claim | 5 | 3 | 15 | ADR-013 discipline in every prompt: counts only from the attested run's Results lines, same-turn grep of every changed literal (incl. the CHANGELOG entry describing the fix), pointer-or-omission over new completeness claims | retros/2026-08-21, 2026-08-20-m48a; forecasts m48a/m48b Outcome scenario 1 (hit 3 passes running) |
| 2 | New fast timing bound breaks under real MSYS load — GF_FAST_STDIN_GUARD_MS set from too-few or too-quiet runs, suite goes red intermittently after merge | 4 | 3 | 12 | Task 5 measures repeated runs incl. under normal machine load, ≥2× worst observed, WHY comment records basis; never run task 8's full suite concurrently with task 5's measurement | patterns-deferred timing-bounds-without-platform-headroom (weighted 3); GUARD_WINDOW_MS 8000→20000 history |
| 3 | Guard test green-while-broken — override wiring or new suites' RED scenarios inert (asserts nothing, passes vacuously); M48b shipped exactly one inert assertion | 3 | 4 | 12 | Falsifiability probe mandatory per done condition: scratch-copy neuter → confirmed RED → dated comment; probe output pasted in the pass record, HQ checks it before accepting DONE | rules/g-rules/H-testing.md; m48b Outcome scenario 2 (partial) |
| 4 | Session budget forces mid-plan handoff — estimate ~43 vs ~35 remaining | 3 | 3 | 9 | Planned seam after Wave 2 (developer-approved): Waves 3–5 are serial HQ work that resumes cleanly; /context at every wave boundary per §A7 | this plan's budget gate; w1-5e Outcome scenario 2 ("on fumes") |
| 5 | Subagent record-write stall (~1-in-3 observed) across 7 dispatched slots | 4 | 2 | 8 | One SendMessage resume per stall (Interrupted ≠ FAILED); never redeploy | m48b Outcome scenario 4 (three stalls, all resumed) |

## Recommendations

Re-scope before approving — formula verdict at 85%. Context that goes with the number: the calibration corpus says these forecasts over-predict (hit-rate 0.28 across 59 reconciled outcomes), and scenarios 4–5 have proven, cheap mitigations already wired into the plan. The load-bearing risks are scenarios 1–3; their mitigations are done-condition-level (ADR-013 count discipline, probe-proven RED, measured timing basis), not optional advice. Forecast assumes the historical pattern set is representative.

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | happened (r3+r4 records) | The class fired repeatedly: M48c documentation went stale inside its own changeset (r3 items 1,5,12-14), and the fix round minted r4 item 3 (CHANGELOG path literal). Mitigation partially held: the new code-side sweep (first live firing, r4) swept 8 facts and caught the 3 survivors — the catcher worked; authoring discipline did not prevent. |
| 2 | yes | happened, caught pre-merge (r3 item 3) | Quiet-only validation left ~2.1s margin: loaded worst 12849ms vs 15000 bound. The mitigation clause ("incl. under normal machine load") was not executed in task 5 and review forced it; loaded re-measure under 16-core saturation → bound 30000 (2× 25698 rounded). Caught in review, never merged red. |
| 3 | yes | mitigation held (mostly) | All guard probes RED-proven in scratch (class-split 5-FAIL+1-green, check-commit 23/25, router typo target, version-agreement synthetic mismatch). One assert-nothing case exists (version-agreement Test 1, helper-defined check) — flagged by r3/r4 as non-blocking and carried, not shipped silently. |
| 4 | yes | happened (journal) | mitigation-held: amber gate fired at the exact pre-approved Wave 2/3 seam; planned handoff taken (retro + refreshed handoff), never a forced mid-wave one. Filled early — observed live; waves 3-5 resume clean. |
| 5 | yes | happened (journal) | Two record-write stalls across the session: T3 feature-implementer (waves) and the override-fixtures agent (F1 fix wave, stalled twice, both resumed); SendMessage resume recovered every one — within the ~1-in-3 class. Reconciled at close. |

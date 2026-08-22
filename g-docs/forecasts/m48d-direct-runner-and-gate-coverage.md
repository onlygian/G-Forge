# Forecast: M48d — Direct runner & the big hole

> Created: 2026-08-21
> Plan: g-docs/plans/m48d-direct-runner-and-gate-coverage.md (pending approval at forecast time)
> Mode: regular

## Complexity
- Score: 7/10
- Breakdown: files 3 (7 distinct paths), waves 2 (4 waves), boundaries 1 (skill layer ↔ test/hook layer), new surface 1 (one new suite), rule edits 0

## Miss-risk: 85% — High
- Raw score (pre-calibration): 85%
- Calibration: adjustment −2, N=10 confirmed outcomes, M=3 mitigation-held (sample floor met; hit_rate 0.40 — corpus mildly over-predicts, adjustment rounds away in headline)

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | Stale-count drift — 21→22 bump + re-summed totals leave stale "21 suites"/"592" literals somewhere the plan doesn't name (dominant defect class, recurrence #4+) | 5 | 3 | 15 | Task 6 greps the whole repo for the old literals (absence grep: `21 suites`, `592`), not just the three named files; derive-at-the-end, never fix-as-you-go | retros/2026-08-21-m48c-close, 2026-08-20-m48a-review-close, m46 forecast outcome 1 |
| 2 | MSYS platform semantics break the new pre-commit fixtures — timing/subprocess overhead false-fails or false-passes on the very platform that matters (GUARD_WINDOW_MS class fired twice: 8000→20000, 15000→30000) | 4 | 3 | 12 | New suite avoids timing bounds where possible; any bound authored ≥2× loaded-worst per architecture profile note; attest on this Windows machine | hook-stdin-hang-guard forecast outcome 2; tests/lib/timing-bounds.sh history |
| 3 | Synthetic-fixture/live-path divergence — new suite's fixtures pass while the real hook path differs on a format detail (H5 class: attempts 1-2 green on synthetic, broken live) | 3 | 3 | 9 | Fixtures exercise the production sentinel format verbatim (real `git write-tree` output, real stamp lines per ADR-004); §H probes prove RED against the real hook copy | retros/2026-08-21-m48c-waves-1-2 |
| 4 | Confabulated attestation totals — hand-sum vs runner total mismatch papered over (claim-vs-data recurrence #3) | 3 | 3 | 9 | Task 5's done condition already requires independent hand-sum = runner total; discrepancy recorded, summed table wins | m48 forecast outcome 1 (held); W3 Pass 3 (568/650) |
| 5 | Suite-run tooling loss — background full run reaped or output lost to a trailing pipe (observed twice) | 3 | 2 | 6 | nohup+disown + Monitor on the log; never trail a pipe (standing handoff rule) | retros/2026-08-21-m48b-and-m51-slotting |

## Recommendations

High risk — strongly consider re-scoping before approval. (Advisory; formula context: the headline is driven by the top-3 scenarios all being well-evidenced repeat classes, but 4 of 5 carry mitigations already embedded in the plan's done conditions, and the outcome corpus shows mitigations holding 3/4 times when shipped in the dispatch. Forecast assumes the historical pattern set is representative.)

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | | |
| 2 | yes | | |
| 3 | yes | | |
| 4 | yes | | |
| 5 | yes | | |

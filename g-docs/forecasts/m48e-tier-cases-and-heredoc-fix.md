# Forecast: M48e — Tier cases & heredoc fix

> Created: 2026-08-23
> Plan: g-docs/plans/m48e-tier-cases-and-heredoc-fix.md (pending approval at forecast time)
> Mode: regular (calibrated)

## Complexity
- Score: 5/10
- Breakdown: files 3 (7 distinct paths), waves 2 (4 waves), boundaries 0, new surface 0, rule edits 0
- Blast-radius file: none (skipped)

## Miss-risk: 70% — Elevated

- Raw score 76 (10 + complexity 15 + scenario contribution 51), calibration −4 (hit_rate 0.30 over N=65 confirmed outcome rows, M=1 mitigation-credited), rounded once at the end.
- Heuristic, not a prediction — assumes the historical pattern set is representative. Note the calibration direction: the corpus says past forecasts over-predicted (hit_rate 0.30), which is exactly the alarm-fatigue pattern already on record.

## Estimated token cost: 30k–90k (Medium)

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | Counted claim re-minted at an edited site (count pins T7, CHANGELOG T5, header comments T1/T3) | 4 | 3 | 12 | Every count derived from the T6 run's Results: lines at write time, command recorded; no count typed from memory | retros 2026-08-20/21/22 (three consecutive milestones) |
| 2 | Agent claims a write that never lands (lost-write class) | 4 | 3 | 12 | Executors must read back every claimed write (grep/Read the target) before reporting DONE; HQ spot-verifies claimed files exist before accepting | 3 sightings 2026-08-22/23: /g-afk CHANGELOG entry, decomposer scratch list, m48d forecast Outcome table |
| 3 | extract_pathspecs fix over-strips and flips the gate fail-safe (false ALLOW on a real pathspec commit) | 2 | 5 | 10 | T3 regression cases must cover both directions: heredoc body ignored AND legitimate `git commit -m x path` pathspecs still detected; §H scratch-revert probe proves the new cases can fail | audit-7 green-while-broken class (§H origin) |
| 4 | Long suite run lost or corrupted mid-flight (T6, >10 min) | 2 | 3 | 6 | nohup+disown+polled log, never a trailing pipe (standing rule, held in m48d) | m48b/c retros, forecast #5 mitigation-held |
| 5 | Sweep site silently skipped in T4 (four ROADMAP pointers) | 2 | 2 | 4 | Done condition requires per-site verdict: corrected or explicitly justified — silence is a review finding | r1→r2 silent-drop class (code-lead r2 record) |

## Recommendations

Elevated — apply at least the top-2 mitigations before approving. Both are already baked into the plan header (count-derivation rule; read-back-before-DONE rule), so the residual decision is approval itself. Watch-point: scenario 3 is the only false-ALLOW path in the plan — do not let the heredoc fix ship without the both-directions regression cases.

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | | |
| 2 | yes | | |
| 3 | yes | | |
| 4 | yes | | |
| 5 | yes | | |

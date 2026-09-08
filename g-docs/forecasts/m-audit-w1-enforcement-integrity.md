# Forecast: M-audit-2026-07 Wave 1 — P0 Enforcement Integrity

> Created: 2026-07-02
> Plan: g-docs/plans/.pending-forecast.md (pre-approval handoff; saved as m-audit-w1-enforcement-integrity.md on approval)
> Mode: regular

## Complexity
- Score: 8/10
- Breakdown: files 3 (≈16 distinct), waves 2 (5 waves), boundaries 2 (skill↔hook contract: g-review↔check-commit sentinel, g-doctor↔hooks drift check), new surface 1 (sentinel content-binding contract + new doctor check), rule edits 0

## Miss-risk: 80% — High

Driver note: the percentage is impact-inflated, not sprawl-inflated — the plan touches the enforcement spine (the gate that gates this very repo), so every scenario's impact scores high. The wave is already design-first (tasks 7/9/11), which is the main structural mitigation.

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | Gate-semantics under-specified before review — sentinel content-binding misses an edge case (amend, rebase, mixed doc+code stage, --amend after MERGE READY) and ships a hole or a false-block | 3 | 4 | 12 | Design notes 008/009 must include an explicit edge-case matrix (amend / rebase / mixed stage / empty index / both sentinels) BEFORE Wave 4 implementation; reviewer checks the matrix, not just the happy path | 2026-05-19-m10-m14 retro ("sub-batch semantics under-specified"); M-audit item 8 |
| 2 | Windows/PowerShell blind spot reproduced in new test suites — bash-run suites assert Bash-shaped payloads only, re-creating the exact fail-open class W0 just fixed | 3 | 4 | 12 | Every new test suite (tasks 12–16, plus 3/6 cases) must include at least one PowerShell-shaped payload case, mirroring tests 17–18 in test-check-commit.sh | memory windows-hook-gotchas; W0 findings; 4158ffa |
| 3 | Self-gating regression — a bad check-commit.sh edit mid-wave blocks (or fail-opens) this repo's own commits, stalling the remaining waves | 2 | 4 | 8 | Run tests/test-check-commit.sh after EVERY task touching check-commit.sh (3, 6, 8) before the wave boundary closes; keep one-task-per-wave serialization on that file (already scheduled) | Bug A history (v2.2.1 CHANGELOG); audit headline |
| 4 | Doc/count/CHANGELOG currency drift at the v2.2.2 release pass | 4 | 2 | 8 | Include a release cross-check (README, CHANGELOG, plugin.json+marketplace.json agreement) as the explicit last step before the version bump | 2026-05-19-m10-m14 retro (×3 bullets); m27 count re-derivation |
| 5 | Base drift across the expected mid-plan handoff — plan exceeds session budget (accepted), fresh session resumes on a moved main | 2 | 3 | 6 | At every wave boundary and at /g-resume re-entry: git fetch + check origin/main divergence before dispatching | 2026-06-29-m27 retro |

## Recommendations

High (80%) — strongly consider re-scoping before approval. (Advisory — developer approval is authoritative.) If proceeding: apply mitigations 1–3 as hard done-condition amendments (edge-case matrix in 008/009; PowerShell payload case in every new suite; check-commit test run after tasks 3/6/8). The design-first structure and file-serialized chains already absorb most of the structural risk; the residual risk is concentrated in Wave 4 (task 8).

Forecast assumes the historical pattern set is representative.

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | | |
| 2 | yes | | |
| 3 | yes | | |
| 4 | yes | | |
| 5 | yes | | |

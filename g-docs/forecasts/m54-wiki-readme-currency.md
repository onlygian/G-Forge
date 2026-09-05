# Forecast: M54 — Wiki & README Currency Pass

> Created: 2026-09-02
> Plan: g-docs/plans/.pending-forecast.md (pending-handoff; saved as g-docs/plans/m54-wiki-readme-currency.md on approval)
> Mode: regular

## Complexity
- Score: 7/10
- Breakdown: files 3 (6 distinct paths — `g-wiki/architecture.md`, `commit-gate.md`, `usage.md`, `reference.md`, `README.md`, root `README.md`), waves 2 (4 waves), boundaries 0 (documentation surface only, no code layer crossed), new surface 2 (`g-wiki/reference.md` is a new public page and the root README front door is restructured — `g-docs/ROADMAP.md:613` calls it adopter-visible), rule edits 0 (no G-RULES or `rules/` change)
- Blast-radius adjustment: none — no `g-docs/blast-radius/m54-*.md` exists

## Likelihood ≥1 premortem scenario fires: 90% — High
- Raw score (pre-calibration): 94%
- Calibration: adjustment −2, N=78 confirmed outcomes, M=9 mitigation-held (sample floor met; M does not dominate N, so the number is usable as-is)

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | **False or unpinned claim minted in the new prose.** The pass rewrites ~2,000+ words across six files, every one of which must cite a source path. This is the repo's single most frequent recurring defect and this plan is its maximum-exposure shape. | 5 | 4 | 20 | Every structural claim is written by *deriving it from the file at write time*, never from memory or from the prose being replaced. Prefer "write the minimal true statement or none" — the D1 retro records that deletion-form fixes closed the arc and rewording never did. HQ spot-checks each Wave 2 return against source before Wave 3 opens. | `retros/2026-08-31-...-session-d1.md` ("Five false/unpinned claims across the gate arc… four minted in a round's own fix prose"); `retros/2026-08-30-...-session-c.md` ("4th consecutive session of forecast scenario 1"); `todo-done.md:31` (count drift ×5) |
| 2 | **doc-writer overreach — an edit outside the named scope, unnoticed.** Task 5 surgically edits an 801-line README containing three sentences pinned byte-identical by regex. A doc-writer that "improves" README:150, :277 or :382 breaks `tests/test-readme-counts.sh`. | 4 | 4 | 16 | Task 5's dispatch quotes the three pinned sentences verbatim as untouchable literals. Recovery on any suspected overreach is a **full-file `git diff`**, not a spot-revert. Wave 4's 6b runs `git diff --stat tests/test-readme-counts.sh` precisely to catch a silent test edit. | `retros/2026-08-29-...-session-b.md` ("The W1.5d doc-writer event destroyed the finding-#20 CHANGELOG bullet header *in addition to* the count edit… the recovery step is a full-file diff") |
| 3 | **Dispatch sized over the doc-writer budget cap.** Task 3 must produce ≥1800 words of new instructional content after reading several skills; Task 5 restructures 801 lines. Both plausibly exceed the ≈10 calls / ≈6 edits doc-writer budget. | 4 | 3 | 12 | Split Task 3 or Task 5 into sub-dispatches at the first sign of cap pressure rather than letting a truncated return look like a completed one. Verify each Wave 2 return actually wrote its file before opening Wave 3. | `retros/2026-08-31-...-session-f3.md` ("Size dispatches under the cap… doc-writer/doc-reviewer budget ≈ 10 calls ≈ 6 edits", violated by T44 at 2 caps) |
| 4 | **Stale cross-reference / line-ref rot.** Adding a ToC and relocating three blocks shifts every line number in README, and the new wiki prose will cite into `skills/` files that M53 rewrote wholesale six days ago. | 4 | 3 | 12 | Cite the *sentence or symbol*, not only the line number, wherever a site is about to be edited. Re-derive every `file:line` cite against the current tree at write time; never carry one forward from the page being replaced. | `retros/2026-08-31-...-session-d1.md` ("Handoff line refs go stale on insertion"); `todo-done.md:31` (stale/false cross-references ×4) |
| 5 | **The doc gate is scoped by authorship, not dependency.** Task 6c scopes `/g-doc-review` to `README.md` + `g-wiki/*.md` — but every claim in those files is *about* `skills/`, `agents/`, `rules/` and `g-docs/`. A gate reading only the changed files verifies internal consistency, not truth against source. | 3 | 4 | 12 | Dispatch 6c with the explicit instruction to verify each claim against the source file it names, per ADR-013 rule 2 — check claims against source, not plausibility. Consider `/g-blast-radius` on the claim set if 6c returns thin. | `retros/2026-08-30-...-session-c.md` ("Scope the review by DEPENDENCY, not by AUTHORSHIP"); `g-docs/decisions/013-derive-in-consumers-keep-counts-in-prose.md` rule 2 |

Runner-up, not in the top 5 but structurally present: **partial-enumeration fix** (`todo-done.md:31`, ×3) — README:150 and README:382 are literal twin count claims, the exact duplicated-claim shape where correcting one and leaving the other is "the original bug committed inside its own fix."

## Recommendations

Re-scope before approving. Cut the highest-impact items or move to a follow-up milestone.

HQ's reading of that verdict for this specific plan: the High tag is driven by scenario 1, whose likelihood is high because the *volume of new prose* is high — not because any task is ill-defined. The re-scoping lever that actually moves the number is reducing how much net-new unsourced prose is minted in one pass, principally Task 3's ≥1800-word target and Task 5's full-README rewrite. Splitting M54 into a wiki-currency half (Tasks 1, 2, 4) and a README/usage-authoring half (Tasks 3, 5) would halve the per-pass minting exposure and let the first half's doc gate calibrate the second. Advisory only — the developer's approval is authoritative, and proceeding whole with mitigations 1 and 2 applied is a defensible call.

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | | |
| 2 | yes | | |
| 3 | yes | | |
| 4 | yes | | |
| 5 | yes | | |

# Calibration notes — rationale behind `scripts/calibration.sh` (Step 5b) and Step 6's display rules

Load this when the developer questions the calibration number, when `M` is a large share of `N`, or when an outcome row parses ambiguously. The operative arithmetic lives in `scripts/calibration.sh`; this file carries the reasoning the script's rules encode.

## What the corpus is and who writes it

Most `## Outcome` tables are still empty — `/g-retro` reconciles the active plan's forecast at retro time, keyed to the branch slug (its `## Step 4 — Forecast outcome reconciliation` block; formerly `skills/g-retro/SKILL.md:49-59`), not only when a milestone closes. An unfilled row has a blank `Actually happened?` cell and is not a signal: skip it, the same way Step 3 discards `None recorded.` / `None.` / `(none)` sentinels — absence of evidence is not evidence.

For rows that ARE filled in, the verdict and evidence tag `/g-retro` writes into the `Actually happened?` cell (formerly `skills/g-retro/SKILL.md:58`) are: a verdict phrase (`happened`, `happened — variant`, `yes`, `did not happen`, `no`, `partial`) usually followed by a one-word evidence tag in parentheses (`journal` / `git` / `unverified`, or a session-pass label like `Pass 1`). Tolerate markdown emphasis wrapping the cell (e.g. `**happened (git)**` reads identically to `happened (git)`). The pass-reference arm accepts arbitrary non-`unverified` parenthesized tags — the live corpus carries `review record r1`, `attestation`, `task4 record`, `retro 2026-08-22` — mirroring the prose's "or explicit pass-reference", never a hardcoded whitelist.

## Confirm/discard rule — one rule, no exceptions

- A cell that is bare `unverified`, or whose evidence tag is `(unverified)`, carries no evidence — **discard** it.
- A cell carrying a `journal`, `git`, or explicit pass-reference tag — **confirmed**.
- A cell with a verdict phrase and **no tag at all** counts as **confirmed-legacy**: a recorded verdict with no tag is still a recorded verdict, not an absence of evidence, so it counts as confirmed. Only the two explicit-`unverified` forms above are discarded.
- `N` (used by the sample floor and `hit_rate`) depends on this rule — the script applies it before counting rows.

## Mitigation half-credit — a deliberate compromise, and its limitation

A `did not happen` / `no` row whose Notes column **begins** with the literal marker `mitigation-held:` is credited `0.5` instead of `0`. `/g-retro`'s outcome-writing step writes this marker when the predicted mitigation was applied and held. A marked row is evidence the forecast correctly flagged a real risk that was then prevented — not evidence the forecast was wrong. Rows without the marker — including every row written before this convention existed — take the unmodified `0` mechanically. No free-text interpretation of the Notes column is performed; the marker is either present or it isn't. The match is a **prefix** of the Notes cell only, never a substring anywhere in the row — a live counter-example exists in the corpus where `mitigation-held` appears mid-text in a Mitigation column and must not match.

**Limitation, stated explicitly:** the half-credit is a compromise, not a full excuse. A held mitigation proves the forecast caught something worth catching; it does not prove the risk would have manifested without intervention, so it earns half credit, not full. This must never quietly reward alarm-silencing — if marker-credited rows come to dominate `N` and `calibration_adjustment` still trends negative, treat that as a prompt to inspect mitigation quality, not as license to trust the number blindly. `M` (the marker-credited count within `N`) is surfaced in Step 7/8, derived at runtime from the same corpus, precisely so this condition is checkable rather than decorative.

## Why 0.5 is the neutral midpoint

Premortem scenarios are candidate failures, not certainties, so a 50% observed hit rate means the corpus is, on average, neither over- nor under-predicting. A `hit_rate` above 0.5 (predicted scenarios happen more often than not — the corpus has been under-predicting risk) raises the future likelihood ≥1 premortem scenario fires (`calibration_adjustment` positive, up to `+10`). A `hit_rate` below 0.5 (predicted scenarios mostly did NOT happen — the corpus has been over-predicting risk) lowers it (negative, down to `-10`). The `clamp(-10, 10, round(deviation × 20))` is a defensive no-op: `hit_rate ∈ [0,1]` already bounds `deviation × 20` to `[-10,10]`; it is kept explicit rather than relied-upon. This recomputes from the live corpus every run, so it moves as `/g-retro` reconciles more forecasts — it is never a fixed constant.

The sample floor (`N ≥ 5`) mirrors the cold-start pattern (too little evidence means no adjustment in either direction, not a guessed one) but is a separate condition — cold-start is Step 3 finding no retro/pattern/git signals at all; the floor is Step 5b finding too few *reconciled outcomes* even when past forecasts exist. See `references/cold-start.md`.

## Rounding visibility

Round only the final `miss_risk` value (already computed with `calibration_adjustment` added and clamped) to the nearest 5% — never round `raw_score` on its own first. A small non-zero `calibration_adjustment` (±1–4) can still round away in the final headline number — that is expected, not a bug — so Step 7's `Calibration:` line always prints the unrounded raw-score display value, the exact `±A` adjustment, `N`, and `M` alongside the rounded `miss_risk`, specifically so the calibration signal stays visible even when rounding masks its effect on the headline percentage.

## Display clamp — `raw_score` can exceed 100

`raw_score` has no upper bound in the formula (a high-complexity plan with several severe scenarios can reach triple digits), and printing it unclamped reads as an impossible percentage. For Step 7 and Step 8 display only, print `raw_score_display = clamp(0, 100, raw_score)` — never the unclamped `raw_score`. `miss_risk` itself is unaffected by this display clamp: it is already bounded to `[0, 95]` by its own clamp regardless of how large `raw_score` gets. When the clamp binds (`raw_score > 100`), the script prints `RAW_DISPLAY: >=100` — a saturation marker, so a genuinely-computed 100 and a clamped-down triple-digit score never read as the same thing; render it as `≥100` in the report.

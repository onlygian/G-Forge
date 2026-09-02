# Cold-start treatment — fresh projects with no history

Load this when `scripts/calibration.sh` prints `COLD_START: yes` (Step 3 produced no signals: empty `g-docs/retros/`, no `g-docs/patterns-deferred.md`, no rework markers in the git log).

## Formula

Run `scripts/forecast-calc.sh cold --complexity <X>`, which computes:

```
miss_risk_cold = clamp(15, 60, 15 + complexity_score × 3)
```

The cold-start formula has a higher floor (15%) and a lower ceiling (60%) than the regular formula: no history means no evidence of low-risk patterns either, so confidence is intentionally narrow.

## Never calibrate on cold-start

Cold-start never applies `calibration_adjustment` — cold-start already means "no evidence at all," and calibration data (Step 5b) cannot rescue a formula with no scenario evidence to calibrate. Cold-start never computes `raw_score` or `calibration_adjustment` either.

## Single-scenario emission

Emit a single scenario `cold-start — no history yet` with likelihood 3, impact derived from complexity, and a `★ Confidence: low` annotation in the report. Note in Recommendations that confidence is low until history accumulates — premortem operates on plan surface only.

## Report lines

- Step 7's `Calibration:` line on this path is printed as `Calibration:   n/a — cold-start (no history to calibrate against)`.
- Step 8's schema `> Mode: [regular / cold-start]` records `cold-start`; its Raw-score and Calibration lines record `n/a on cold-start`.

## Independence note

Cold-start (Step 3, no retro/pattern/git signals) and the corpus-too-thin case (Step 5b, `N < 5` confirmed outcomes) are independent conditions — a plan can hit either, both, or neither. The `N < 5` floor zeroes only the calibration adjustment while the regular formula still runs; cold-start replaces the formula entirely.

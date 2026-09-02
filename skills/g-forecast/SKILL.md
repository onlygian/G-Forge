---
name: g-forecast
description: Run scope-realism analysis and premortem on an approved-or-pending plan. Outputs a complexity score, a quantified likelihood that ≥1 premortem scenario fires, and a ranked list of likely failure scenarios seeded by /g-patterns history. Plan-time gate, never blocks — surfaces risk for human judgment.
context: [task, sprint, architectural, institutional]
---

**Announce:** "Using g-forecast to analyse scope realism and run a premortem."

A forward-looking risk pass on a plan before it executes. Output is advisory — never blocks approval. This skill's `scripts/` and `references/` paths are relative to its own directory; run every script with Bash from the project root.

## Step 1 — Identify the target plan

Run `scripts/find-plan.sh "$ARGUMENTS"`. Its case order is contractual: **1** pending-handoff `g-docs/plans/.pending-forecast.md` (written by `/g-plan` Step 3a), **2** developer-passed slug or path, **3** most-recent `g-docs/plans/*.md` with a `pending` wave. On `EXIT: no-plan`, print exactly:
```
✗ No plan to forecast. Run /g-plan first, or pass a plan slug as argument.
```
and stop. Record the plan-slug (`SLUG:`; on case 1, derive it from the plan's title) — Step 8 uses it for the output filename.

## Step 2 — Score complexity

Load the normative measurement thresholds in `references/scoring-notes.md` (its `## Step 2` section — always, before scoring), then compute a 0–10 score from the plan:

| Signal | Weight |
|--------|--------|
| File count touched | 0–3 |
| Wave count | 0–2 |
| Layer-boundary crossings | 0–2 |
| New external dependency / new public surface | 0–2 |
| Architecture rule changes | 0–1 |

Sum, clamp to 0–10, record the breakdown.

## Step 2b — Incorporate blast-radius signal (if available)

If `g-docs/blast-radius/<plan-slug>.md` exists, pass its rating to Step 6's script call as `--blast` — the Narrow/Moderate/Wide adjustment mapping lives in `scripts/forecast-calc.sh`. Record the original score, the rating, and the adjusted score; both surface in Step 7. If no file exists, skip silently.

## Step 2c — Estimate token cost band

Run `scripts/forecast-calc.sh tokens --tasks <sum of task counts over waves> --files <files touched>` — the formula and band-tag literals live in the script. Surface as `Estimated token cost: low – high (tag)` in Step 7. Advisory — never blocks.

## Step 3 — Pull historical patterns

Read the corpus for premortem seeding: every `Avoid / do differently` bullet in `g-docs/retros/` (apply the same sentinel filter as `/g-patterns`: discard `None recorded.`, `None.`, `(none)`); `g-docs/patterns-deferred.md` if it exists (every deferred suggestion is a known unresolved failure mode); rework markers (`revert:`, `fix-of-fix`, `take 2`, `retry`) in `git log --oneline -50`. Build a candidate-failure list, each tagged with its frequency (count of distinct source files).

## Step 4 — Match candidates to plan surface

Judge whether the plan exposes each candidate's surface; keep matches, drop the rest. Example matches live in `references/scoring-notes.md`.

## Step 5 — Score and rank failure scenarios

Score each survivor: **Likelihood** (1–5, frequency + exposure) × **Impact** (1–5) = score. Sort descending, keep the top 5.

## Step 5b — Read forecast-outcome corpus

Run `scripts/calibration.sh` — it parses every `## Outcome` table under `g-docs/forecasts/` (the track record `/g-retro` reconciles) and prints per-row `OUTCOME:` lines plus `N:`, `M:`, `HIT_RATE:`, `CALIBRATION:`, `COLD_START:`. Carry `hit_rate`, `N`, `M`, and `calibration_adjustment` into Step 6.

Floor rule: when `N < 5` the script prints `CALIBRATION: 0` — record `insufficient calibration data — neutral signal (N=[N] confirmed, floor is 5)` for Step 7/8 to surface. Caveat: if marker-credited rows (`M`) dominate `N`, inspect mitigation quality rather than trusting the number blindly. Load `references/calibration-notes.md` when interpreting the number, when `M` dominates, or when a row parses ambiguously.

## Step 6 — Compute the likelihood ≥1 premortem scenario fires

Run `scripts/forecast-calc.sh score --complexity <X> --scenario-scores <top-3, comma-separated> --calibration <A> [--blast narrow|moderate|wide]` — formula, round-once rule, [0,95] clamp, and the ≥100 saturation marker live in the script. If Step 5b printed `COLD_START: yes`, run `scripts/forecast-calc.sh cold --complexity <X> [--blast narrow|moderate|wide]` instead (same `--blast` flag when Step 2b applies) and load `references/cold-start.md`.

Tag the result:
- 0–25% — Low risk
- 26–50% — Moderate risk
- 51–75% — Elevated risk — premortem mitigations recommended before approval
- 76–95% — High risk — strongly consider re-scoping before approval

## Step 7 — Emit the forecast report

`Scenario-fire:` in the template below is the likelihood ≥1 premortem scenario fires during this pass — not a prediction that the plan overall fails.

Print exactly:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
G-FORECAST — [plan name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Complexity:    [X/10]   (files [F] · waves [W] · boundaries [B] · new surface [S] · rule edits [R][ + blast-radius adjustment if applied])
Scenario-fire: [P]%    ([Low / Moderate / Elevated / High])
Calibration:   raw [RAW]% → adjusted [P]%   (adjustment [±A], N=[N] confirmed outcomes[, M=[M] mitigation-held][ — floor not met, neutral if N<5])
Est. tokens:   [low]–[high]   ([Small / Medium / Large / Very Large])

Premortem — top failure scenarios:
  1. [scenario label]       likelihood [L] · impact [I] · score [LxI]
     Mitigation: [one concrete action — what to do before or during execution]
     Source: [retro filenames or git refs that surfaced this pattern]
  2. ...

Recommendations:
  [if Low / Moderate]      Proceed as planned. Note scenarios above as watch-points.
  [if Elevated]            Apply at least the top-2 mitigations before approving. Consider splitting the largest wave.
  [if High]                Re-scope before approving. Cut the highest-impact items or move to a follow-up milestone.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

`[RAW]` is the script's `RAW_DISPLAY` value — a distinct placeholder from the Complexity line's `[R]` (rule edits). Print the `M=` clause only when `M > 0`. On the cold-start path, print the `Calibration:` line per `references/cold-start.md`.

## Step 8 — Persist the forecast for the feedback loop

Write the forecast to `g-docs/forecasts/<plan-slug>.md` (create directory if missing). Use this schema so `/g-retro` and `/g-patterns` can mine it later:

````markdown
# Forecast: [Plan Name]

> Created: [YYYY-MM-DD]
> Plan: [path to plan file]
> Mode: [regular / cold-start]

## Complexity
- Score: [X/10]
- Breakdown: files [F], waves [W], boundaries [B], new surface [S], rule edits [R]

## Likelihood ≥1 premortem scenario fires: [P]% — [tag]
- Raw score (pre-calibration): [RAW]% ([n/a on cold-start])
- Calibration: adjustment [±A], N=[N] confirmed outcomes, M=[M] mitigation-held ([sample floor met / insufficient data — neutral] / [n/a on cold-start])

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | ... | ... | ... | ... | ... | ... |
| 2 | ... | ... | ... | ... | ... | ... |

## Recommendations

[Verbatim Recommendations block from Step 7 — preserved so `/g-patterns` and `/g-retro` can re-surface the original mitigation advice after the session ends.]

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | [yes / no / partial] | |
| 2 | yes | | |
````

The `Outcome` table is intentionally empty at forecast time — `/g-retro` fills it in when it reconciles the active plan's forecast (keyed to the branch slug, per Step 5b), closing the feedback loop: `/g-patterns` → premortem (`/g-forecast`) → `/g-retro` → `/g-patterns`.

## Step 9 — Return to caller

Invoked standalone: stop here — the developer reads the report and decides. Invoked from `/g-plan` (its Step 3b): return with the forecast summary so the approval gate can display it alongside the plan.

## Rules
- This skill never blocks approval — its job is to surface risk, not gate it. The developer always decides whether the risk is acceptable.
- Always persist the forecast to `g-docs/forecasts/<plan-slug>.md` — the feedback loop with `/g-retro` and `/g-patterns` depends on this file.
- Apply the same `None recorded.` sentinel filter as `/g-patterns` when reading retros — never seed scenarios from empty signals.
- On cold-start (Step 3 finds no history at all), premortem operates on plan surface only — single low-confidence scenario, narrower formula, never calibrated; operational body in `references/cold-start.md`.
- Never modify the plan file itself. The forecast is advisory — re-scoping is a developer decision communicated back to `/g-plan`.
- The likelihood ≥1 premortem scenario fires is a heuristic, not a prediction — present it as such ("forecast assumes the historical pattern set is representative").

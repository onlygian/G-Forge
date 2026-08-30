---
name: g-forecast
description: Run scope-realism analysis and premortem on an approved-or-pending plan. Outputs a complexity score, a quantified likelihood that ≥1 premortem scenario fires, and a ranked list of likely failure scenarios seeded by /g-patterns history. Plan-time gate, never blocks — surfaces risk for human judgment.
context: [task, sprint, architectural, institutional]
---

**Announce:** "Using g-forecast to analyse scope realism and run a premortem."

You are running a forward-looking risk pass on a plan before it executes. Output is advisory — never blocks approval — but it tells the developer where this plan is most likely to fail and what to mitigate before starting.

## Step 1 — Identify the target plan

Determine the plan to forecast against in this strict order:

1. **Explicit pending-plan handoff from `/g-plan`** — if `g-docs/plans/.pending-forecast.md` exists, read it (this is the temporary plan file `/g-plan` Step 3a writes before approval to hand a not-yet-saved plan over to `/g-forecast`). Use its contents as the plan.
2. **Developer-passed slug or path** — if `$ARGUMENTS` is non-empty and resolves to `g-docs/plans/<arg>.md` or a path to an existing `.md` file, read it.
3. **Most-recent pending plan** — Glob `g-docs/plans/*.md`, find the most recently modified plan file whose Progress table has any `pending` wave; use that.

If none of the above resolves to a plan:
```
✗ No plan to forecast. Run /g-plan first, or pass a plan slug as argument.
```
Stop.

Record the chosen plan-slug — Step 8 uses it for the output filename.

## Step 2 — Score complexity

Compute a 0–10 complexity score from these signals (read directly from the plan or compute from referenced files):

| Signal | Weight | How to measure |
|--------|--------|----------------|
| File count touched | 0–3 | sum of distinct file paths in the Scope columns: 1 (≤2 files), 2 (3–5), 3 (≥6) |
| Wave count | 0–2 | 1 wave: 0; 2 waves: 1; 3+ waves: 2 |
| Layer-boundary crossings | 0–2 | grep plan Scope columns for cross-layer paths (e.g. UI ↔ service, agent ↔ skill): 0 (none), 1 (one boundary), 2 (multiple) |
| New external dependency / new public surface | 0–2 | 0 (none), 1 (one new skill/agent/dep), 2 (multiple or new public API) |
| Architecture rule changes | 0–1 | 0 (no rule edits), 1 (G-RULES or architecture rules modified) |

Sum the components and clamp to 0–10. Record the breakdown.

## Step 2b — Incorporate blast-radius signal (if available)

Check whether `g-docs/blast-radius/<plan-slug>.md` exists. If it does, read its rating and adjust the complexity score from Step 2:

| Blast-radius rating | Complexity adjustment |
|---------------------|------------------------|
| ✓ Narrow | +0 |
| ⚠ Moderate | +1 |
| ✗ Wide | +2 |

Re-clamp the resulting complexity score to 0–10. Record the original score, the blast-radius rating, and the final adjusted score in the breakdown — both are surfaced in Step 7's report.

If no blast-radius file exists, skip this step silently. The developer can run `/g-blast-radius` separately and re-run `/g-forecast` to incorporate the signal.

## Step 2c — Estimate token cost band

Compute a rough token-cost band for executing the plan. This is intentionally a band, not a point estimate — token consumption is governed by agent dispatch counts and diff sizes, both of which vary widely.

```
agent_dispatches_estimate = sum over waves of (task_count_in_wave)
diff_size_estimate        = files_touched × 80   // 80 lines per file is the historical median
review_overhead           = base 6000 tokens + 2000 per agent dispatched
total_estimate            = agent_dispatches_estimate × 4000 + diff_size_estimate × 4 + review_overhead
```

Express as a band: `low = total × 0.6`, `high = total × 1.8`. Round to nearest 1k.

Tag by absolute size of the high estimate:
- < 50k tokens — `Small`
- 50–200k tokens — `Medium`
- 200–800k tokens — `Large`
- > 800k tokens — `Very Large — consider re-scoping`

This estimate is surfaced in the Step 7 report as `Estimated token cost: low – high (tag)`. It is advisory — never blocks approval.

## Step 3 — Pull historical patterns

Read the corpus the same way `/g-patterns` does, but only for premortem seeding:

- All files in `g-docs/retros/` — extract every `Avoid / do differently` bullet (apply the same sentinel filter as `/g-patterns`: discard `None recorded.`, `None.`, `(none)`)
- `g-docs/patterns-deferred.md` if it exists — every deferred suggestion is a known unresolved failure mode
- `git log --oneline -50` — note any rework markers (`revert:`, `fix-of-fix`, `take 2`, `retry`)

Build a candidate-failure list: every distinct failure mode observed in the corpus is a candidate. Tag each with its observed frequency (count of distinct source files).

## Step 4 — Match candidates to plan surface

For each candidate failure mode, judge whether the current plan exposes that surface. Examples:

| Past failure | Triggered if plan touches… |
|--------------|---------------------------|
| `commit-without-tests` | adds business logic or public API in a stack with no tests |
| `wave-split-across-messages` | has ≥3 waves with parallel tasks |
| `layer-boundary-skip` | crosses architecture layers (any `core ↔ ui`, `agent ↔ skill`, `service ↔ component` mix) |
| `agent-given-write-tool` | new agents in scope |
| `version-mismatch-plugin-vs-marketplace` | version bump touches one but not both manifest files |
| `stale-handoff-block` | release pass touches g-docs/ROADMAP.md |

Keep candidates that match the plan's surface; drop the rest.

## Step 5 — Score and rank failure scenarios

For each surviving candidate, score:

- **Likelihood** (1–5): frequency in corpus + how directly the plan exposes the surface
- **Impact** (1–5): blast radius if it happens (1 = small annoyance, 5 = milestone slip / rework wave)
- **Score** = likelihood × impact

Sort descending. Keep the top 5 scenarios.

## Step 5b — Read forecast-outcome corpus

Before scoring the likelihood ≥1 premortem scenario fires (Step 6), read the observed track record of past forecasts so the formula can calibrate against what actually happened, not just complexity + scenario signals.

- Glob `g-docs/forecasts/*.md` and read the `## Outcome` table in each.
- Most `## Outcome` tables are still empty — `/g-retro` reconciles the active plan's forecast at retro time, keyed to the branch slug (`skills/g-retro/SKILL.md:49-59`), not only when a milestone closes. An unfilled row has a blank `Actually happened?` cell and is not a signal: skip it, the same way Step 3 discards `None recorded.` / `None.` / `(none)` sentinels — absence of evidence is not evidence.
- For rows that ARE filled in, read the verdict and evidence tag `/g-retro` writes into the `Actually happened?` cell (`skills/g-retro/SKILL.md:58`): a verdict phrase (`happened`, `happened — variant`, `yes`, `did not happen`, `no`, `partial`) usually followed by a one-word evidence tag in parentheses (`journal` / `git` / `unverified`, or a session-pass label like `Pass 1`). Tolerate markdown emphasis wrapping the cell (e.g. `**happened (git)**` reads identically to `happened (git)`).
- **Confirm/discard rule — one rule, stated once, no exceptions:**
  - A cell that is bare `unverified`, or whose evidence tag is `(unverified)`, carries no evidence — **discard** it.
  - A cell carrying a `journal`, `git`, or explicit pass-reference tag (e.g. `(journal)`, `(git)`, `Pass 1`) — **confirmed**.
  - A cell with a verdict phrase and **no tag at all** counts as **confirmed-legacy**: a recorded verdict with no tag is still a recorded verdict, not an absence of evidence, so it counts as confirmed. Only the two explicit-`unverified` forms above are discarded.
  - `N` (used by the sample floor and `hit_rate` below) depends on this rule — apply it before counting rows.
- Classify each confirmed row's credit by verdict:
  - `happened` / `yes` (any phrasing, e.g. `happened`, `happened — variant`, `yes`) → `1`
  - `partial` → `0.5`
  - `did not happen` / `no` → `0` — **unless** the row's Notes column begins with the literal marker `mitigation-held:`. `/g-retro`'s outcome-writing step writes this marker when the predicted mitigation was applied and held. A marked row is evidence the forecast correctly flagged a real risk that was then prevented — not evidence the forecast was wrong — so credit it `0.5` instead of `0`. Rows without the marker — including every row written before this convention existed — take the unmodified `0` mechanically. No free-text interpretation of the Notes column is performed; the marker is either present or it isn't.
  - **Limitation, stated explicitly:** the mitigation half-credit above is a deliberate compromise, not a full excuse. A held mitigation proves the forecast caught something worth catching; it does not prove the risk would have manifested without intervention, so it earns half credit, not full. This must never quietly reward alarm-silencing — if marker-credited rows come to dominate `N` and `calibration_adjustment` still trends negative, treat that as a prompt to inspect mitigation quality, not as license to trust the number blindly. Let `M` = count of marker-credited rows within `N`; Step 7/8 surface `M` alongside `N` (derived at runtime from the same Glob) so this condition is checkable rather than decorative.
- Let `N` = confirmed-row count (per the confirm/discard rule above). **Check the sample floor before dividing** — do this before computing `hit_rate`, so a thin or empty corpus never divides by zero.

**Minimum sample floor.** `N` must be at least **5** confirmed rows before the signal is trusted. If `N < 5`:
```
calibration_adjustment = 0
```
Record `insufficient calibration data — neutral signal (N=[N] confirmed, floor is 5)` for Step 7/8 to surface. This mirrors the cold-start pattern below (too little evidence means no adjustment in either direction, not a guessed one) but is a separate condition — cold-start is Step 3 finding no retro/pattern/git signals at all; this floor is Step 5b finding too few *reconciled outcomes* even when past forecasts exist.

If `N ≥ 5`, sum the credits and divide by `N` to get `hit_rate` (0.0–1.0), then compute the calibration signal:
```
deviation              = hit_rate - 0.5
calibration_adjustment = clamp(-10, 10, round(deviation × 20))   // defensive no-op: hit_rate ∈ [0,1] already bounds deviation × 20 to [-10,10]; kept explicit rather than relied-upon
```
0.5 is the neutral midpoint — premortem scenarios are candidate failures, not certainties, so a 50% observed hit rate means the corpus is, on average, neither over- nor under-predicting. A `hit_rate` above 0.5 (predicted scenarios happen more often than not — the corpus has been under-predicting risk) raises the future likelihood ≥1 premortem scenario fires (`calibration_adjustment` positive, up to `+10`). A `hit_rate` below 0.5 (predicted scenarios mostly did NOT happen — the corpus has been over-predicting risk) lowers it (negative, down to `-10`). This recomputes from the live corpus every run, so it moves as `/g-retro` reconciles more forecasts — it is never a fixed constant.

Carry `hit_rate`, `N`, `M`, and `calibration_adjustment` into Step 6.

## Step 6 — Compute the likelihood ≥1 premortem scenario fires

A rough quantified estimate of "likelihood ≥1 premortem scenario fires during this plan's first execution pass":

```
scenario_contribution = sum over top-3 scenarios of min(scenario_score, 15) × 1.5
raw_score             = 10 + complexity_score × 3 + scenario_contribution
miss_risk             = clamp(0, 95, raw_score + calibration_adjustment)
```

`calibration_adjustment` is Step 5b's output — the observed over/under-prediction signal from the forecast-outcome corpus (`0` when the corpus is below Step 5b's sample floor, so the formula is unaffected until there is enough evidence to trust). Each scenario's contribution is capped at 22.5 (15 × 1.5) so no single severe pattern alone drives the result into High territory on a trivial plan. The complexity multiplier is tuned so a max-complexity plan (10/10) contributes 30 percentage points before scenario evidence.

**Rounding rule — apply once, at the end, after calibration.** Round only the final `miss_risk` value (already computed with `calibration_adjustment` added and clamped) to the nearest 5%. Never round `raw_score` on its own first. A small non-zero `calibration_adjustment` (±1–4) can still round away in the final headline number — that is expected, not a bug — so Step 7's `Calibration:` line always prints the unrounded raw-score display value, the exact `±A` adjustment, `N`, and `M` alongside the rounded `miss_risk`, specifically so the calibration signal stays visible even when rounding masks its effect on the headline percentage.

**Display clamp — `raw_score` can exceed 100.** `raw_score` has no upper bound in the formula above (a high-complexity plan with several severe scenarios can reach triple digits), and printing it unclamped reads as an impossible percentage. For Step 7 and Step 8 display only, compute `raw_score_display = clamp(0, 100, raw_score)` and print that — never the unclamped `raw_score`. `miss_risk` itself is unaffected by this display clamp: it is already bounded to `[0, 95]` by its own clamp regardless of how large `raw_score` gets. **When the clamp binds** (`raw_score > 100`), print `[RAW]` as `≥100` rather than `100` — a saturation marker, so a genuinely-computed 100 and a clamped-down triple-digit score never read as the same thing.

**Cold-start formula** — if Step 3 produced no signals (empty `g-docs/retros/`, no `g-docs/patterns-deferred.md`, no rework in git log):

```
miss_risk_cold = clamp(15, 60, 15 + complexity_score × 3)
```

The cold-start formula has a higher floor (15%) and a lower ceiling (60%) than the regular formula: no history means no evidence of low-risk patterns either, so confidence is intentionally narrow. It never applies `calibration_adjustment` — cold-start already means "no evidence at all," calibration data (Step 5b) cannot rescue a formula with no scenario evidence to calibrate. Emit a single scenario `cold-start — no history yet` with likelihood 3, impact derived from complexity, and a `★ Confidence: low` annotation in the report.

Cold-start (Step 3, no retro/pattern/git signals) and the corpus-too-thin case (Step 5b, `N < 5` confirmed outcomes) are independent conditions — a plan can hit either, both, or neither.

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

`[RAW]` is `raw_score_display` (Step 6's display-clamped value) — deliberately a distinct placeholder from the Complexity line's `[R]` (rule edits) above, since the two are unrelated numbers inside the same template. `[M]` is Step 5b's marker-credited row count, derived at runtime from the same corpus Glob as `N` — print the `M=` clause only when `M > 0`; omit it when no row in the corpus was marker-credited.

On the cold-start path (Step 6's `miss_risk_cold`), print the `Calibration:` line as `Calibration:   n/a — cold-start (no history to calibrate against)` instead — cold-start never computes `raw_score` or `calibration_adjustment`.

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

The `Outcome` table is intentionally empty at forecast time — `/g-retro` fills it in when it reconciles the active plan's forecast (keyed to the branch slug, per Step 5b above), closing the feedback loop: `/g-patterns` → premortem (`/g-forecast`) → `/g-retro` → `/g-patterns`.

## Step 9 — Return to caller

If invoked standalone by the developer: stop here. They read the report and decide what to do.

If invoked from `/g-plan` (Step 3b of g-plan): return to `/g-plan` with the forecast summary so the approval gate can display it alongside the plan.

## Rules
- This skill never blocks approval — its job is to surface risk, not gate it. The developer always decides whether the risk is acceptable.
- Always persist the forecast to `g-docs/forecasts/<plan-slug>.md` — the feedback loop with `/g-retro` and `/g-patterns` depends on this file.
- Apply the same `None recorded.` sentinel filter as `/g-patterns` when reading retros — never seed scenarios from empty signals.
- If `g-docs/retros/` is empty and `g-docs/patterns-deferred.md` is missing, premortem operates on plan surface only: emit a single scenario `cold-start — no history yet` with likelihood derived from complexity alone, and note in Recommendations that confidence is low until history accumulates.
- Never modify the plan file itself. The forecast is advisory — re-scoping is a developer decision communicated back to `/g-plan`.
- The likelihood ≥1 premortem scenario fires is a heuristic, not a prediction — present it as such ("forecast assumes the historical pattern set is representative").

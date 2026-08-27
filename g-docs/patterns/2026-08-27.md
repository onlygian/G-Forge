# Pattern Report — 2026-08-14

## Systemic (≥3)
- **Label:** summary-disagrees-with-own-detail | **Weighted count:** 3 | **Sources:** 3 retrospectives
  **Failure class:** An automated worker reports a summary total that disagrees with the detailed table it claims to summarize. The summary is generated independently of the detail rather than derived from it, so the headline number can drift from the evidence while looking authoritative. Downstream consumers who trust the headline inherit the error.
  **Proposed fix intent:** Require every consumer of a summarized result to re-derive the total from the detailed data and treat the detail as authoritative on any disagreement.
  **Status:** DEFERRED — the drafted rule text failed review on the trigger condition (it bound the requirement to the restated figure changing, rather than to the underlying detail changing, so it could not fire on the very case it was mined from). The pattern stands; the wording needs authoring fresh.

- **Label:** timing-bounds-without-platform-headroom | **Weighted count:** 3 | **Sources:** 1 retrospective, 1 forecast
  **Failure class:** Time-based assertions are authored against the fastest environment observed, then fail intermittently on slower or emulated platforms where fixed overhead is several times larger. The failures read as regressions but are calibration errors, and they only appear under load or on other machines — the author's machine keeps passing.
  **Proposed fix intent:** Require every time bound to carry at least double the worst observed duration on the slowest supported platform, recorded as a named constant with its justification.
  **Status:** DEFERRED — the doubling and named-constant requirements already existed; only the measurement basis was missing, and the drafted wording failed review as unsatisfiable on shared or hosted build machines, where the required quiet conditions cannot be guaranteed and the rule left no alternative evidence path. Needs a formulation that degrades on shared infrastructure.

## Emerging (2)
- **Label:** static-risk-numbers-get-ignored | **Weighted count:** 2 | **Sources:** 1 retrospective, 1 forecast
  **Failure class:** Quantified risk estimates surfaced at planning time read as high and never move between plans, so the audience habituates and stops reading them — alarm fatigue turns a governance signal into noise. The number is produced by a fixed formula rather than calibrated against recorded outcomes.
  **Proposed fix intent:** Derive risk figures from the recorded history of predictions versus outcomes so the number visibly moves with evidence, and display the correction alongside the headline figure.
  **Status:** DEFERRED — half-resolved. The planning-time estimate this was mined from covers two separate numbers; one now derives from recorded outcomes, the other is still a fixed carried constant. Deferred to the self-improvement track that owns calibration-from-history.

## Isolated (1)
- **Label:** shared-text-block-with-divergent-parsers | **Sources:** 1 | **Status:** —
- **Label:** deferred-cleanup-of-per-session-state-files | **Sources:** 1 | **Status:** —

## Reinforced
- **Label:** verify-claims-against-source-not-reporter | **Sources:** 3 | **Status:** —
- **Label:** fresh-context-for-applying-deliberated-decisions | **Sources:** 2 | **Status:** —

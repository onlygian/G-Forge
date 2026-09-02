# forecast-reconciliation — the Step 4 procedure

Load this whenever Step 4 finds a forecast file — unconditionally, before writing anything to it. The `mitigation-held:` token below is a parsed closed-set literal; a reconciliation written without this file open risks an unparseable marker.

Reconcile the forecast's predicted scenarios against the journal evidence rather than asking the developer:

- For each predicted scenario, mark `happened` / `did not happen` / `unverified` based on journal + git signals (e.g. a forecasted "auth refactor will cause regressions" is `happened` if reverts or HOLD-related rework appear around the auth files).
- Update the `## Outcome` table in the forecast file with the verdict **and** a one-word evidence tag (`journal` / `git` / `unverified`). This keeps the `/g-patterns` feedback loop running without a manual interview. Mark anything you cannot substantiate as `unverified` — never guess a positive.
- **`mitigation-held:` marker.** If the verdict for a row is `did not happen` / `no` (the scenario did NOT materialize) AND the forecast's recorded `Mitigation` for that scenario was demonstrably applied during the pass and held — journal, git, or record evidence shows the mitigating action was taken and the predicted failure never occurred — begin that row's Notes cell with the literal token `mitigation-held:` followed by the evidence (e.g. `mitigation-held: tests run before every commit this pass (journal)`). This is the only condition that earns the marker; a scenario that simply didn't happen with no applied mitigation gets no marker. `/g-forecast` Step 5b reads this token verbatim to award half credit instead of zero — do not paraphrase or omit the leading token.

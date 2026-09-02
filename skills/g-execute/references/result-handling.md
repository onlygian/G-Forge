# Non-DONE result handling — WRITTEN / FAILED / BLOCKED / partial

Load trigger: /g-execute Step 3's wave completion gate, whenever any agent in
the wave returns anything other than a verified `DONE`. Follow the matching
ladder below **before** touching the Progress table.

- **`WRITTEN`** — returned by `test-writer`: the tests are **authored but NOT executed** (that agent has no run tool). This is **not** a completed task. Before marking it done, **you (HQ) run the suite yourself** — HQ has execution tools — and record the real runner output (framework, pass/fail counts). A **green** run marks the task complete and becomes the attestation code-lead/`/g-review` will require (Tier-1 evidence per g-rules-H). A **red** run starts the fix loop: dispatch a fresh `feature-implementer` (to fix the code) or `test-writer` (to fix a broken test) seeded with the failing output, then re-run. Never mark a `WRITTEN` task complete on the compact block alone — an unrun suite reported as done is finding #20.
- **`FAILED`** — the agent's single approach didn't work; the agent is spent. **Never re-prompt it** — single-use agents are discarded on failure (G-RULES §C). Run the redeploy loop:
  1. Read the `LEARNINGS:` block (and the `DETAIL:` file if you need specifics). This is the only thing that crosses back — the failed agent's context is gone, and that's the point: it can't poison the retry.
  2. Track an attempt counter for this task (start at 1 for the original dispatch). This is the `FAILED` count + 1.
  3. **If this is attempt 1 or 2:** analyze the learnings — optionally dispatch `error-detective` / `debugger` on the learnings to identify a *different* mechanism. Before redeploying, hand the next agent a clean starting point: revert the failed attempt's partial changes (`git restore`/`git checkout --` on the scoped files), or describe the exact working-tree state, so it conditions on ground truth, not residue. Escalate the model tier before attempt 3 (per §A8). Then dispatch a **fresh** single-use agent for the same task, seeded **only** by the revised approach + the accumulated learnings — never the dead agent's output file as context. Append a line to `.claude/escalation-log` (`YYYY-MM-DD <task-label> retry-N`).
  4. **If attempt 3 also returns `FAILED`:** STOP. Do not deploy a fourth. Escalate to the developer with the full learnings trail:
     ```
     ✗ Wave [N] — [task name]: 3 approaches failed.
     Attempt 1: [approach] — [why it broke]
     Attempt 2: [approach] — [why it broke]
     Attempt 3: [approach] — [why it broke]
     Ruled out: [union of ruled-out approaches]
     Need your call on direction before I spend a fourth attempt.
     ```
     Do not proceed to the next wave.
- **`BLOCKED`** — an external dependency makes the task impossible to proceed; a different approach won't help. Read the full detail file at the `DETAIL:` path. Then dispatch `error-detective` with the detail file contents and any error messages or stack traces present. Then dispatch `debugger` with error-detective's findings and the relevant source files. Present both diagnoses alongside the block report:
  ```
  ⛔ Wave [N] blocked on: [task name]
  Reason: [agent's reported blocker]

  error-detective: [root cause summary]
  debugger: [fix strategy]

  Fix the blocker using the diagnosis above, then resume with: /g-execute [N]
  ```
  Do not proceed to the next wave.
- **Partial / unclear** → flag it but continue unless it affects a dependency

> As-is inconsistency, carried faithfully (flagged for a future pass, not
> silently reconciled): step 3 above appends `YYYY-MM-DD <task-label> retry-N`
> to `.claude/escalation-log`, while the SKILL.md Rules bullet states the format
> as `YYYY-MM-DD <task-label>` without the suffix. `/g-telemetry` only counts
> lines (`wc -l`), so both satisfy the metric.

# Forecast: M53.1 — v2.6.2 Patch: dogfooding defects + voice honesty

> Created: 2026-09-03
> Plan: `g-docs/plans/m53-1-dogfooding-defects-voice-honesty.md`
> Milestone: `g-docs/ROADMAP.md:611-627` · Version target: v2.6.2 (patch)

## Complexity

**5 / 10** — files touched 7 (≥6) = 3 · waves 2 = 1 · layer-boundary crossings 1 (the plugin manifest becomes authoritative over the agents layer) = 1 · new external dependency / public surface 0 · architecture rule changes 0. No blast-radius file exists for this slug, so no adjustment.

Estimated token cost: 23k – 69k (Medium).

## Likelihood ≥1 premortem scenario fires: 85% — High

Calibration: hit rate 0.39 over N=78 confirmed outcome rows (M=9 marker-credited), adjustment −2 applied. Not a cold start.

The headline number is driven by scenario 1, which is unusual: this plan's central fix is *verified only by a check that itself might be testing the wrong thing*, and the mechanism it relies on was read out of a binary rather than documentation.

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | **The fix silently does nothing, and the test says it worked.** Task 1's pinning test asserts the manifest array agrees with `ls agents/*.md` — a claim about two lists, not about the loader. If Claude Code ignores the `agents` key (wrong key name, wrong path form, version-gated, or manifest-plus-directory rather than manifest-exclusive), the test is green, the array is correct, and all 15 `g-forge:references:*` types are still dispatchable. The defect ships as fixed. | 4 | 5 | 20 | The live roster check is the *only* assertion that pins the claim we care about, so it is a done condition, not a nicety: the executor confirms the roster drops to 19 with no `g-forge:references:*` types and pastes the evidence. On failure it returns `FAILED` with that evidence and HQ re-opens the routing decision — it must not fall back to the directory move on its own judgment. | `retros/2026-08-30-...-session-f2.md` ("A mechanical check verifies the claim it tests, not the claim you care about"); G-RULES §H instrument-claim rule |
| 2 | **The guard test is green because it tests nothing.** Task 1 authors a guard/negative test — the exact class the falsifiability rule exists for. A fixture that does not contain what the unguarded path would find passes for the wrong reason, and this repo has already shipped one (probe C stayed green because nothing sat at `$ROOT/SNAPSHOT.md`). | 4 | 4 | 16 | Falsifiability probe is mandatory and its *pasted output* goes in the pass record, not just the in-file marker: copy to a scratch location, neuter the guard in the copy, confirm RED, discard. Nothing in the production tree is mutated. The marker comment carries the date and is re-proved if the assertion later changes. | `retros/2026-08-30-...-session-f1.md` ("A guard test's fixture must contain what the unguarded path would find"); G-RULES §H falsifiability rule |
| 3 | **A fix moves one carrier and leaves its siblings standing.** `M1.md` appears at four sites in `scaffold.sh` (the :136 existence check plus generated output at :118, the :124-155 skeleton heredoc, and the :165 todo row); the roadmap detection source appears at three in `detect-stack.sh` (:26 comment, :254-257 block, :265 emission). Correcting the flagged line and leaving its twin is this repo's most-repeated defect shape, and it has been committed *inside its own fix* before. | 4 | 3 | 12 | Sweep the string class, never the flagged line: each executor greps its own file for every occurrence of the token before declaring done, and cites the pre-fix count taken at task start. Prefer deletion over rewording — the D1 arc closed on deletion-form fixes and never on rewording. | `retros/2026-08-31-...-session-d1.md` ("A fix moves a fact and leaves a carrier standing"); M54 handoff ("two of HQ's four inline corrections left uncorrected twins") |
| 4 | **The roster narrowing drops the executor that runs the gate.** Task 1 narrows dispatchability on the repo that is executing its own waves. `g-forge-dev` sits at `.claude/agents/g-forge-dev.md`, outside `agents/` and outside the 19 declared paths; its independence from the manifest is inferred from this repo's architecture note, not proven at runtime. If loading turns out to be manifest-exclusive, Wave 2 has no executor. | 2 | 4 | 8 | HQ confirms `g-forge-dev` is still dispatchable immediately after Task 1 lands and before Wave 2 opens — a deliberate glance, not an assumption. Task 1's own live check may surface it first. | wave-planner flagged consequence, 2026-09-03; `forecasts/w1-5g-self-host-integrity.md` |
| 5 | **A dispatch caps mid-task having written nothing.** Already fired once this session: the decomposer stopped at its 12-turn limit with no file on disk. Wave 1 sends four dispatches that each end in a write plus verification runs — the shape that caps. | 4 | 2 | 8 | Hand each executor its source set pre-derived (paths and line numbers are already in the plan) so research budget is not spent rediscovering them. Budget one resume round-trip per dispatch; resume by telling the agent to verify its own state, never by asserting its progress. Verify each file exists on disk before accepting a `DONE`. | `retros/2026-08-31-...-session-f3.md` ("A resume message must never assert a delegate's per-item progress"; "size dispatches under the cap"); M54 record (doc-writer capped 5 of 5) |

## Recommendations

- **Scenario 1 is the one to watch.** Everything else on this list is a familiar shape with a known mitigation; scenario 1 is the plan's load-bearing assumption. It is cheap to falsify early — if the live roster check is run first, before the test is even authored, the routing decision is settled on evidence for the cost of one reload.
- The forecast does **not** recommend re-scoping. Five tasks across two waves with disjoint file sets is an honest patch shape, and the manifest route already removed the larger risk (a 23-site citation churn colliding with M54's in-flight corrections).
- Budget is the real constraint, not scope: `/g-plan`'s check returned `tight` (~44 estimated against ~39 remaining). Expect to reset before the M54 fix round rather than after it.

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | | |
| 2 | yes | | |
| 3 | yes | | |
| 4 | yes | | |
| 5 | yes | | |

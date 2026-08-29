# G-Forge incident report — telemetry, pattern-mining, and fix-target durability, from a session on `G-Sharp`

For Gianmarco, maintainer of G-Forge. Written from a Claude Code session on the `G-Sharp` project (5 retros, 117 commits, running G-Forge on the `full` tier since M0). Plugin version at time of writing: **2.4.1** (cache current with `origin/main`; the project's installed hook copy lagged at v2.2.1, which is incidental to this report).

This is not a crash report. It is a report that **the telemetry subsystem produced a health profile that was never actually computed**, and that a second, independent defect makes the profile ratchet monotonically toward `recovery` over a project's lifetime. Sections 4-6 add three further findings from a `/g-patterns` pass run in the same session - including one that leaves a consumer project with no durable way to fix a rule at all. All are live in 2.4.1.

Everything below is sourced from `g-docs/telemetry-metrics.md` (as shipped), `g-docs/telemetry/2026-08-07.md` (the prior run's own snapshot), and direct measurement against G-Sharp's retro corpus and git history.

---

## TL;DR

1. **Five of the eight reliability metrics have literally empty sources.** The label tokens `telemetry-metrics.md` greps for (`hallucinated-`, `nonexistent-`, `wrong-api`, `bad-citation`, `re-dispatched`, `agent returned empty`, `review caught`, `scope creep`, `escalated`) appear in **zero** retro files. `/g-retro` does not emit them, and never has. The metric spec and the retro-writing skill were never wired to a shared vocabulary.
2. **Consequence: the numbers get filled in by judgment and presented as measurements.** G-Sharp's 2026-08-07 snapshot reported `20% hallucination` and `80% retry dependency` — both derived by a model reading retro prose semantically, then rendered in a table alongside genuinely computed git metrics with no marking to distinguish them. That produced a `defensive` profile which escalated every `/g-review` for three weeks.
3. **`.claude/review-holds` is a latch.** It is incremented on every HOLD, has **no decrement path on resolution**, and is reset *only* when `/g-telemetry` derives `stable` — which requires all 8 metrics in range. Any single ⚠ freezes the counter permanently. It can only grow, which inflates rework rate, which guarantees a ⚠, which prevents the reset. Positive feedback loop.
4. On G-Sharp this meant a HOLD **raised and resolved on 2026-07-12** (fixed in `79eabb0`, milestone shipped as v0.3.0 in the next commit) was still inflating the rework metric **47 days later**.
5. `/g-doc-review`'s `DOCS HOLD` does not increment the counter at all, so the doc-side gate is invisible to rework telemetry. Noted in G-Sharp's own snapshot as a spec gap; repeating it here because it is the same root issue — the counter has no coherent owner.
6. **Two G-RULES gaps found by pattern mining** (2 source retros each): a missing agent return block is treated as a resume-nudge rather than a failure, and derived figures about the project are recorded from recollection and then propagate across documents.
7. **`/g-patterns` Step 5 names a fix target that `/g-update` destroys.** In a consumer project it directs fixes to the installed `.claude/` copies - but `/g-update` overwrites every plugin-managed one wholesale. A consumer project therefore has no durable path to fix a rule-level pattern it discovers.
8. **Retro section headings vary enough to defeat both mining passes** - three different structures across five retros, so `/g-patterns` and `/g-telemetry` each silently see a subset of the corpus.

---

## 1. The vocabulary mismatch

### What the spec asks for

`g-docs/telemetry-metrics.md` sources five of eight metrics from retro prose by literal token match:

| # | Metric | Tokens the spec greps for |
|---|---|---|
| 1 | Hallucination rate | `hallucinated-`, `nonexistent-`, `wrong-api`, `bad-citation` |
| 2 | Review catch rate | `review caught`, `code-lead caught`, `architect caught` |
| 5 | Spec deviation | `scope creep`, `unscoped`, `refactored adjacent`, `out of plan`, `deviated` |
| 6 | Escalation frequency | `escalated`, `bumped to opus`, `three-strikes` (fallback when `.claude/escalation-log` absent) |
| 8 | Retry dependency | `re-dispatched`, `wave 2 take 2`, `had to retry the agent`, `agent returned empty` |

Metrics 1 and 5 further restrict the search to bullets **under the `## Avoid / do differently` heading**.

### What the corpus actually contains

Measured across all 5 G-Sharp retros:

```
grep -ilE 'hallucinated-|nonexistent-|wrong-api|bad-citation'                 → 0 files
grep -ilE 're-dispatch|wave 2 take 2|had to retry the agent|agent returned empty' → 0 files
grep -ilE 'review caught|code-lead caught|architect caught'                   → 0 files
grep -ilE 'scope creep|unscoped|refactored adjacent|out of plan|deviated'     → 0 files
grep -ilE 'escalated|bumped to opus|three-strikes'                            → 0 files
```

Zero matches, across every metric, in every file.

Worse, the heading those metrics scope to is not even consistently present:

```
2026-07-06-m1-engine-hardening.md          : 0   ← no "## Avoid / do differently"
2026-07-08-m2-inline-pass.md               : 0   ← no heading
2026-07-16-m3b-h-export-simplification.md  : 0   ← no heading
2026-07-17-m4-mcp-co-writing.md            : 1
2026-08-06-m5-midi-export-refinement.md    : 1
```

Only 2 of 5 retros carry the heading that metrics 1 and 5 require. The other three predate it or use different section names.

### Why this is worse than "a metric returns zero"

`/g-telemetry` Step 3 says: *"If a metric's source is empty … record `n/a — insufficient data` and do not flag as ⚠."* Followed literally, G-Sharp has **3 computable metrics** (all git-derived: regression, rework, token efficiency) and 5 `n/a`.

But that is not what happened on 2026-08-07. The run reported all 8 as computed, with hallucination at 20% and retry dependency at 80%, each with a plausible "Source" citation naming retro files and describing events in prose. Those events are *real* — the M5 retro genuinely narrates a false "VexFlow seam remains in-tree" claim. But they were located by **semantic reading, not by the spec's stated mechanism**, and the resulting table draws no distinction between a number derived from `git log` arithmetic and a number derived from a model's interpretation of narrative text.

That is the actual defect: **the subsystem has no way to fail loudly.** When its sources are empty it does not report a measurement vacuum — it quietly substitutes judgment and returns a confident profile. A downstream project then runs for weeks at an escalated review posture on the strength of it.

The 2026-08-07 snapshot deserves credit here: its own Notes section flagged two of the three ⚠ metrics as "stale or denominator-thin, not live signal" and explicitly warned "read these before acting on the profile." The prose was honest. The machine-readable output — `.claude/telemetry-profile` containing `defensive`, which is the only part `/g-review` Step 0 and `/g-execute` Step 0 actually consume — was not. **The caveats never reach the consumer.**

### Suggested fix

Pick one direction; either works, but they must agree:

- **(a) Make `/g-retro` emit the labels.** Add the tag vocabulary to the retro template so `## Avoid / do differently` bullets are written as `hallucinated-api: …`, `re-dispatched: …`. Cheap, but only fixes retros written *after* the change — the existing corpus stays unmeasurable, so metrics stay `n/a` for another 5 milestones.
- **(b) Make the spec match how retros are actually written.** Replace literal-token grep with a stated interpretive pass, and **mark interpreted metrics distinctly in the output table** (e.g. `20% ~` vs `0% ✓`) so the difference between measured and judged is visible in the artifact.
- **(c) Minimum viable, regardless of the above:** when a retro-sourced metric's literal source is empty, `/g-telemetry` must emit `n/a` and say so in the summary block — never silently fill it. And the derivation should refuse to emit a confident profile when a majority of metrics are `n/a`; a `computable < 5` case is a measurement vacuum, not a health verdict.

Note that the `computable < 3 → force stable` floor does not catch this. G-Sharp landed at exactly 3 computable, one above the floor, and all three were git hygiene metrics that say nothing about agent reliability.

---

## 2. The `review-holds` reset latch

### The mechanism

From `telemetry-metrics.md`:

- Metric 4: `rework_signal = fix_after_feat + review_holds`, `rework_rate = rework_signal / max(feat_commits, 1) * 100`, ⚠ above 20%.
- Line 82 / line 175 — **Reset policy:** `.claude/review-holds` resets to `0` *only* when `/g-telemetry` derives a `stable` profile.
- `stable` requires `warn_ratio == 0` — **all** computable metrics in range.
- `/g-review` Step 4 increments the counter on every HOLD, unconditionally.

There is no decrement on resolution. A HOLD that is raised, fixed, re-reviewed and merged leaves the counter permanently incremented. The only clearing mechanism requires a perfect scorecard across every metric — including the five that, per §1, may be unmeasurable or interpreted.

So: **HOLDs accumulate forever → rework rate climbs → a ⚠ appears → `stable` becomes unreachable → the counter can never reset → rework climbs further.** The subsystem drives every long-running project toward `recovery` as a function of age, independent of actual quality.

### Observed on G-Sharp

`.claude/review-holds` = `1`, mtime `2026-07-12 23:19`. That HOLD was raised during M3a's review round and resolved the same day — `79eabb0` ("M3a: review fixes — byte-identity tests, empty-guard, DRY extraction"), with the milestone shipping as v0.3.0 in the immediately following commit `53d71ff`.

The work was done, reviewed, merged and released. The counter never moved. With `feat_commits = 3` (this project only adopted conventional prefixes at v0.5.1, so the denominator is tiny), that single stale increment produced `1/3 = 33%` — over the 20% threshold — which alone was sufficient to prevent `stable`, which alone was sufficient to prevent the reset. The latch closed on itself on day one and stayed shut for 47 days.

Clearing it by hand and recomputing drops rework to **0%** (`fix_after_feat` = 0, genuinely).

### Suggested fix

- Decrement `review-holds` when a HOLD is subsequently resolved — `/g-review` already knows it is re-reviewing after a HOLD (Step 4b's fix-closure sweep is keyed on exactly that claim). That is the natural hook.
- Or make the counter windowed rather than cumulative (HOLDs in the last N commits / last N days), which removes the need for a reset policy entirely and gives the metric the recency weighting §3 below also wants.
- Decouple the reset from `stable`. Requiring an 8/8 perfect score to clear an unrelated counter is what creates the latch. Nothing about "one metric is ⚠" implies "the accumulated HOLD count is still representative."
- Decide who owns the counter, then make it consistent: `/g-doc-review`'s `DOCS HOLD` currently does not increment it, so identical process failures are counted or not depending on which gate caught them. Either split it (code HOLDs vs doc HOLDs) or have both gates write it.

---

## 3. Smaller item: no recency weighting on retro-sourced metrics

`retry_dependency = count(matching_bullets) / count(retros) * 100` sums over the entire corpus with no decay. On G-Sharp, all 4 contributing bullets came from M1 and M3b; M2, M4 and M5 recorded zero agent re-dispatches. A problem that was fixed three milestones ago keeps scoring at full weight until enough clean retros accumulate to dilute it — and since the denominator is retro *count*, each clean milestone moves the number only slightly.

The same applies to metrics 1 and 5. A windowed denominator (last N retros) or exponential decay would make these track current behaviour instead of project history. This is less urgent than §1 and §2 but shares their character: the metric describes the past and is consumed as though it describes the present.

---
## 4. Two rule gaps found by pattern mining — and a target that cannot hold a fix

A `/g-patterns` MINE pass over the same 5-retro corpus surfaced two Emerging patterns (2 distinct source retros each). Both are recorded here rather than applied locally, for the reason in §5.

**4a — A missing agent return block is treated as a nudge, not a failure.** Two retros record delegated executors self-reporting `RESULT: DONE` while lint and build were still red, and separately stopping mid-task with no structured result at all — in one case the coordinator reconstructed the outcome by hand from the working tree, and in another 4 of 9 dispatches needed a resume nudge. G-RULES §C defines the `DONE`/`FAILED` return contract but never states what happens when *no* block comes back, so the coordinator improvises: it nudges, or it reconstructs. Both moves violate the single-use doctrine §C is built on — the nudge continues a poisoned context, and the reconstruction accepts unverified work. Suggested addition to §C's `**Results flow:**`:

> **A missing return block is a `FAILED`, not a nudge.** HQ never resumes an agent that stopped without its `RESULT:` block and never reconstructs the outcome from the working tree — it discards the agent and redeploys fresh per the single-use contract. A self-reported `DONE` is accepted only after HQ independently re-runs the gates.

**4b — Derived figures are recorded from recollection and propagate.** One retro records a `grep -c "it("` heuristic over-counting (it matches `edit(`, `commit(`, `wait(`) and producing a wrong test-count baseline that reached four documents before an agent caught it. A later retro records the *correction* landing in two documents but missing a third, with the count drifting again in the same session. The pattern recurred a third time during this very session: the `## Active Session` handoff asserted "2 occurrences each" for four pattern proposals, and two of the four did not survive re-counting against source — one had a single source retro, one had no signal in any mined section at all. §G's Currency rule covers documentation that changes *alongside code*, but says nothing about figures derived *about* the project. Suggested addition to §G's `### Currency rule`:

> **Derived figures are sourced, never recalled.** Any count or metric about the project must be produced by running its authoritative command at the moment of writing. When such a figure changes, grep the whole repo for the previous value before declaring the update done — a fix that lands in some documents but not all leaves the record contradicting itself.

## 5. `/g-patterns` Step 5 names a target that `/g-update` destroys

Step 5 resolves fix targets and states that in a **consumer project** (no plugin source tree) the installed copies under `.claude/` "are the only targets and are the correct ones," listing `.claude/rules/g-rules-<X>.md`, `.claude/rules/architecture-<stack>.md`, and `.claude/agents/<agent>.md` among them.

That is true for user-authored rule files and false for every plugin-managed one. `/g-update` Step 6a overwrites **every** `g-rules-*.md` wholesale from the plugin cache, Step 6b does the same for matched architecture rules, and Step 5 does it for architect agents. So a `/g-patterns` fix applied to any of those in a consumer project is destroyed at the next `/g-update` — silently, with the rule reading as fixed right up until the resync.

This is the same shape as §1 and §2: the subsystem is coherent in isolation but its fix location is not writable in a way that survives. It also means a consumer project has **no** durable path to fix a G-RULES-level pattern it discovers — which is precisely why both patterns in §4 are in this report instead of in the rules files where they belong.

Step 5's consumer-project branch needs to distinguish plugin-managed targets from user-authored ones, and route the former the way this report is routed — upstream, not locally. Worth noting that the two patterns in §4 were *mined locally but can only be fixed upstream*, so without that routing the loop never closes for anyone but the maintainer.

## 6. Smaller: retro section headings vary enough to defeat both mining passes

The 5 retros in this corpus use three different structures for the same content — `## Patterns` with `### Worked well` / `### Avoid / do differently` subheadings; a merged `## Patterns / avoid next time`; and a bare top-level `## Avoid / do differently` with no `## Patterns` parent. `/g-patterns` Step 3a scopes its extraction to `## Patterns → ### Avoid / do differently`, and `/g-telemetry` metrics 1 and 5 scope to `## Avoid / do differently`; each therefore silently misses whichever retros use a different shape. Two of four forecasts also have entirely unfilled `## Outcome` tables, so the forecast-outcome signal path (Step 3d) contributes nothing.

Pinning the retro template's headings — and having `/g-retro` fill the forecast Outcome table it is specified to fill — would make both passes see the whole corpus instead of a subset.

---
## What this project did

Followed the spec literally — 3 computable metrics, `warn_ratio = 0`, profile persisted as `stable`, with the measurement vacuum recorded in the snapshot Notes and in the session handoff so the next session does not read `stable` as a clean bill of health. The stale HOLD was cleared by hand against the `79eabb0` evidence above.

Flagging it here rather than patching `g-docs/telemetry-metrics.md` locally, because a local patch drifts from the plugin and `/g-update` would overwrite it — and because the same latch is running in every other project on 2.4.x.


---

*Written 2026-08-28 from a G-Sharp session. Measurements reproducible against `G-Sharp@38a08a6`, plugin `g-forge 2.4.1`. The metrics spec is byte-identical across cached 2.4.0 and 2.4.1, so neither defect is fixed by updating.*

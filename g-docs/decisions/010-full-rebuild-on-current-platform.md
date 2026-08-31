# ADR-010: Full rebuild of G-Forge on the current Claude Code platform

**Date:** 2026-07-26
**Status:** Accepted — with R3 (execution rebuild) conditional on the GF-20 spike, and all scope beyond R0 deferred to R0's own output
**Reversibility:** two-way at the product level — frozen v2.5 persists as the fallback; one-way only inside the new repo's own trajectory (see Reversibility below)
**Context:** G-Forge — whole-product architecture, supersedes the additive-integration posture of the 2026-07 external modernization report

## Context

G-Forge is a Claude Code plugin at v2.4.0, effectively 100% bash and markdown. Through 2026 the platform absorbed capability G-Forge had hand-built: dynamic workflow scripts, background subagents, worktree isolation, schema-structured agent returns, native `/code-review` (including "ultra") plus vendor vuln-scan plugins, `/context` and statusline, `/goal` + sandbox + auto mode, OTel telemetry and `/usage`, plugin dependency constraints, a `SessionEnd` hook, `Tool(param:value)` permission matching, and a 1M-context default model.

An externally-authored modernization report was intaken, ground-truthed against live documentation, corrected on two factual points, and superseded for planning purposes by an in-repo rebuild report and component rebuild map (`g-docs/audits/`).

The developer's governing directive reframed the exercise mid-cycle: **this is not feature integration.** The question is *"if G-Forge were built today, on this platform, what would it be?"* The unit of analysis is the G-Forge component, not the platform feature. For each component: does a native feature — or a *combination* of them — now do the job? If yes, the component dies or transforms, and the cascade follows the blast radius. Nothing is grandfathered for existing.

The thesis the audit cycle converged on, and which this decision encodes: **the opinions are the product; the mechanisms are rented time.**

## Decision

**Rebuild G-Forge on the native platform foundation** rather than staying shell-only or maintaining an optional JS tier alongside the existing implementation. Native is the foundation; G-Forge keeps only what the platform cannot say.

Three qualifications are part of the decision, not caveats on it:

1. **The commit gate is outside this decision at every layer.** It decomposes into three independent enforcement sites, and none of them is governed by the language surface:
   - **Door 2 — the native git `pre-commit` hook.** Already the authoritative enforcement site per [ADR-004](004-bind-sentinel-to-reviewed-tree.md): it fires from inside `git commit`, sees the true to-be-committed tree, and catches raw-terminal commits the plugin layer never observes. Bound to git's presence, not to Claude Code's and not to any chosen runtime. **Untouched by the rebuild.**
   - **Door 1 — the Claude Code `PreToolUse` hook.** Already non-authoritative per ADR-004, retained only for its rich model-facing deny message. Shrinks, stays local, remains inside the plugin layer.
   - **Door 3 — a CI-side gate.** Retired; see Rejected Alternatives and the 2026-07-26 **bypass-posture** entry in `g-docs/project_brief.md` (that date now carries two entries — the other is this ADR's own).

   Consequently the language surface governs the **execution and review layers only**. The product's one load-bearing differentiator carries zero rebuild risk.

2. **R3 (execution rebuild) is conditional.** The deletion of the wave engine is priced by the GF-20 spike — re-running one closed milestone as a workflow script against the wave record, measuring tokens, wall-clock, HQ context, and induced-failure behaviour. If the spike refutes, R3 does not proceed and the wave engine survives on a foundation partly chosen to delete it. No other R-band waits on it.

3. **Only R0 is authorized to execute.** "Full rebuild" is the posture, not a scoped body of work. What this ADR authorizes now is a **scoping-and-spike milestone (R0)** whose deliverable is the breakdown, sequence, and cost of everything else — including a counter-estimate of the rebuild's own cost against the maintenance cost it claims to shed. R1–R6 as sketched in the rebuild report are candidate shapes, not commitments. Nothing structural moves until R0 returns.

R0's content: the GF-20 spike · the GF-23 verification (does native review inherit reviewer-lens rules content via `CLAUDE.md`) · the GF-70 test (whether the Windows failure is "no bash on the host" or "Claude Code does not route through bash" — materially different findings) · whether [ADR-008](008-self-host-working-tree-split-cadence.md)'s Spike S1 dev-install path is still a prerequisite once the rebuild lives in a separate repo (the self-host flip may partly dissolve — re-check, do not assume) · the GF-40 invocation × scheduling ADR (not yet written) · the regression-defence plan for the new repo · **the tightening-pass cadence, and what process governs G-Proof's own construction** (see below) · the scoped breakdown and estimate.

### Delivery shape — freeze, split, and why

The rebuild does **not** happen in this repo. Recorded as part of this decision (developer, 2026-07-26):

- **v2.5 ships and this repo freezes** — maintenance on bug reports only, stated publicly. The announcement is honest about the cause: drift from platform capability, genuine overlap, real improvement opportunity. **No roadmap is published with it** — the announcement does the job, so no public commitment exists that an unrun spike could invalidate.
- **v2.5 is forked into a new repo and transformed into G-Proof** — not a greenfield build. The new repo starts as the v2.5 tree, tests included, and is transformed component by component. It surfaces later with migration processes. It is **G-Proof**, first released as **1.0**, not a 2.x release — which resolves the M44 pull-forward question outright: the rebrand is the rebuild's release vehicle, not a milestone competing for a slot.

  *This is what makes the strangler ordering work rather than compromise.* The strangler pattern was rejected as a mandate because there is no stable seam to strangle through while the old path must keep serving a live release. Fork-and-transform removes that constraint: the old path keeps working **in the frozen repo**, so the new tree is free to strangle without any obligation to stay serviceable mid-transform. R0–R6 phasing is therefore the method, not a concession.
- **Early adopters (Fra) are pulled onto nightly builds** of the new repo when comfortable — external field signal arriving *during* construction rather than after release, which this project has never had.

**The driving constraint is working conditions, not distribution.** A stable release and a rebuild under recurring tightening passes have incompatible change economics. v2.5 wants every change gated, minimal, and justified against a published contract, because regression is the enemy. The rebuild wants fast iteration, repeated churn of the same files, and willingness to throw work away, because being wrong quickly is the point. Run both in one tree under one gate and you either strangle the rebuild or destabilise the release. The split is what makes recurring tightening passes possible at all.

This carries a consequence R0 must resolve: **G-Forge's own process is optimised for the wrong thing for its own rebuild.** Plan → execute → review → commit-gate exists to protect a stable product from regression; a continuous transform under tightening passes wants a different rhythm. What process governs G-Proof's construction is therefore an open R0 question, and full-tier G-Forge 2.5 is not the assumed answer.

### Core-functionality check at every review

Under continuous transformation the dangerous failure is not "this diff is wrong" — it is **"the system quietly stopped being whole."** Every diff can be individually correct while the ecosystem loses a limb: a hook that still exists but is no longer registered, a router token pointing at a deleted skill, a lib nobody sources, an agent referenced by a skill that no longer exists. Diff review cannot see any of it.

**The mechanism is a `/g-doctor` run inside the review process, not at health-check time.** Nothing about `/g-doctor` changes — same checks, same read-only report, same role. What is new is *when it runs* and *who consumes it*: the review pipeline takes its report as an input, and `code-lead` — which already holds the MERGE READY / HOLD verdict — reads it and can refuse to advance. The blocking is code-lead's, where blocking already lives. No producer gains a new power and no existing contract is amended; a second caller and a second moment are added.

What the report must cover for this purpose (the wholeness set, distinct from health): every hook present **and** registered · every router token resolving to a skill and every skill reachable from the router · every agent referenced by a skill existing · every lib sourced by a hook existing · both gate doors present and installed · manifest version parity · **orphans in both directions** — referenced-but-missing and present-but-unreferenced. The second orphan class is the common one during a transform: a caller is deleted and the callee sits there looking alive.

Expect this to HOLD reviews that diff review would pass. That is the purpose.

**This rule is time-boxed and lives operatively as transitional rule T1 in `g-docs/transitional-rules.md`** — committed, canonical, and `@`-imported by `CLAUDE.md`, which holds a pointer and no copy of the rule text. (It was written directly into `CLAUDE.md` when first captured; extracted the same day, because `CLAUDE.md` is a gitignored install artifact in this repo and a rule living only there survives a folder copy but not a clone — that file has already been lost once, 2026-07-10.) An ADR records why; something has to say *do this at every review*. T1 carries an activation condition (the fork — it is inert while v2.5 is frozen and unchanging) and a sunset condition (G-Proof 1.0, when continuous transformation ends), plus a tripwire at each end. **On:** the fork carries the rule automatically by git, so the fork-checklist first act is wiring the one-line `@`-import that makes a session read it. **Off:** ~~the sunset detector is **not yet implemented**~~ *(Done 2026-08-11 back-stamp — `/g-trim` check 5 (`skills/g-trim/SKILL.md:18`) now follows every committed `@`-import target, including `g-docs/transitional-rules.md`, and scans each for stated sunset/activation conditions, flagging met/ambiguous ones; `g-docs/transitional-rules.md` Tripwires records the off-tripwire as implemented. The former R0 fork-checklist item reduces to confirming `/g-trim` survives the rebuild.)* At sunset the rule is retired or promoted by explicit decision — never allowed to lapse silently or persist unexamined. G-Forge has had no category for a rule with a lifetime; T1 establishes one.

## Alternatives considered

| Option | Why rejected |
|--------|-------------|
| **Stay shell-only** — freeze the language surface, keep every hand-built mechanism, accept a smaller adoption set | Answers a syntax question when the problem is a count question. The cost driver is the number of rented mechanisms a solo maintainer owns, and shell-only preserves the wave engine, review swarm, context estimator, telemetry collector and update poller in full — each independently scored DIES or TRANSFORMS against a native combination that already exists. Also forfeits workflow scripts, the only credible substrate for the wave-engine transform. |
| **Optional JS/Bun tier with graceful degradation** | Doubles the surface it was meant to bound. Every execution and review path acquires two implementations that must stay behaviourally identical, on a project with no CI and one maintainer — the drift shape ADR-008 already measured. A fallback is a degraded path stated honestly; it is not a parallel implementation. Looks like the safe option; is the most expensive one in the set. |
| **Incremental strangler-fig** — replace component-by-component behind stable interfaces, no wholesale cut | The closest runner-up, rejected on narrower grounds. A strangler needs a stable seam to strangle *through*, and here the seams are what die: `/g-plan` emitting a workflow script changes the plan artifact, which cascades through `/g-execute`, `/g-forecast`, `/g-blast-radius`, G-RULES §C's wave model and the telemetry wave metrics at once. A strangler run also needs a regression harness holding both sides honest, and the harness here is a bash suite scoped to the mechanisms being removed. **The phasing survives the rejection** — R0→R6 is a strangler ordering under a rebuild mandate. What is rejected is strangler-as-mandate. |
| **Rebuild execution + review only, freeze the rest** | Under-drawn rather than wrong. It draws the line by subsystem instead of by the per-component test, re-grandfathering the context estimator, telemetry collection, update polling and session bookkeeping — all independently scored DIES or SHRINKS. Keeps exactly the maintenance the decision exists to shed, and leaves a proxy exchange-counter running against a 1M-context default model. |
| **Wait for the GF-20 spike before deciding anything** | The spike prices one deletion. The compat floor, context truth, review and unattended bands are independently evidenced and none waits on it. Blocking the whole decision on a single gate is deferral with a measured cost: the external report was stale within weeks, and a coverage sweep found 15 unaudited weekly digests. Retained as a gate on R3, rejected as a gate on the decision. |
| **Additive integration** — adopt native features alongside the hand-built ones (the external report's posture) | Rejected on arithmetic: the surface only grows. You acquire the native dependency *and* retain the mechanism it replaces, producing a tree where two systems both claim to schedule waves and both claim to review diffs, with no rule for which wins. |
| **Collapse to a rules-and-gate pack** — retire the plugin surface, ship G-RULES plus the two gate doors | Directionally right, over-shot. PM discipline, intake and challenge, the retro→handoff→resume seam and the doc/test/spec contracts are executable workflows with no native equivalent. This keeps the opinions and discards their enforcement, which is the product claim. |
| **Rebuild off-platform as a standalone framework or CLI** | Explicit brief non-goal ("not a general framework — specifically a Claude Code plugin"), and it re-acquires every mechanism the thesis just shed. |

## Consequences

**Easier:**
- Maintenance surface collapses — hypothesis per the rebuild map (`g-docs/audits/2026-07-rebuild-map.md:85`): 4 agents die outright, 1 transforms, ~6 shrink — plus `architecture-enforcer`, whose row carries a *conditional* TRANSFORMS gated on the unrun GF-23 verification and is counted as SURVIVES until that resolves; the four heaviest skills transform; hooks thin to gate, slim state banner, and lifecycle relays. Each deletion is maintenance a solo developer stops paying personally.
- Platform velocity inverts from threat to asset. Native improvements to review, workflows, worktrees and `/goal` land inside G-Forge for free; the weekly platform sync becomes a delta feed against the rebuild map rather than a staleness alarm.
- Review gets better than G-Forge could make it. `code-lead` keeps what is actually an opinion — done conditions against a milestone's scope, attested Tier-1 runs, MERGE READY/HOLD with no-partial-merge semantics, sentinel write — and stops duplicating diff reading.
- Context policy runs on measurement rather than a proxy. G-RULES §A7's policy survives intact on real input.
- The gate is untouched by the decision that touches everything else. The rebuild's worst case cannot reach the product claim.

**Harder / constrained:**
- Two runtimes in one tree, permanently and deliberately. The gate doors stay shell; execution and review move. `/g-doctor` must become the feature-detect authority (Git Bash, sandbox, runtime, API surface), not a drift checker with a health banner.
- Every DIES verdict owes a documented degraded path for platform-gated hosts — honest prose about where the tool is weaker, which is harder to write than fallback code.
- **The test suite erodes as its subjects die.** The fork carries all 523 tests (17 suites, full run green 2026-07-26, summed from that run's own per-suite `Results:` lines), **but much of what they encode is scoped to mechanisms being deleted.** Gate suites survive whole; mechanism suites die with their subjects. The suite shrinks as the transform proceeds while continuing to report green, so regression defence degrades without ever failing — and during the transform the rebuilt layers have neither the old pins nor new ones. **The count is also not self-evidently trustworthy as a baseline:** the previously-quoted 522 was the exact sum of `CLAUDE.md`'s own per-suite table and matched the attested M46 run, but the suite had since gained one assertion in `test-workflow-checkpoint.sh` (declared header 80, runner-observed 81 — corrected 2026-07-26) so the real total had moved *up* without anyone re-summing. Note the per-suite headers are **not** a complete detector: two suites (`test-g-doctor-drift.sh`, `test-worktree-resolve.sh`) declare no `# Total assertions:` header at all, covering 59 assertions, and `test-classify-changeset.sh` declares twice — so a header sum is neither exhaustive nor unambiguous, and only a run is authoritative. An erosion detector watching only for a falling total would never have fired. The baseline must be derived from a run, and the detector must be direction-agnostic.
- Consumers must be migrated, not merely updated — a cross-repo migration path, not a `/g-update` realign.
- ADR-008's scope ceiling may or may not still bind: shipped skills and agents are cache-pinned by construction, but with the rebuild in a separate repo consuming v2.5 as a normal install, the self-host flip that made Spike S1 a prerequisite may no longer apply. R0 re-checks rather than assumes.
- The roadmap queue was explicitly closed ahead of M29. This enters as a recorded **re-sequence** with rationale, not as an insertion — otherwise the next `/g-align` correctly reports DRIFTING.

**Follow-up decisions:**
- GF-40 — the invocation × scheduling split ADR, still open and independently gating.
- GF-23 verification — gates two rebuild-map rows directly (`code-reviewer` DIES, `architecture-enforcer`'s conditional TRANSFORMS); the other two DIES verdicts in the reviewer cluster rest on different evidence (`security-auditor` on GF-74, `wave-planner` on GF-20).
- GF-70 test — decides how expensive the compat floor is, and may *strengthen* this decision for a reason not yet argued.
- Door 1's per-call tax — measure before deciding its fate.
- The bash test suite's disposition: migrate, split by subject, or partially retire.
- ~~Version and name~~ — **decided** (see Delivery shape): the 2.x line ends at the v2.5 freeze; the rebuild is **G-Proof, first released as 1.0**, in a new repo, and M44 is its release vehicle rather than a competing milestone. The `1.0` (not `3.0`) is the standing brief decision of 2026-07-18/19 — versioning restarts under the new name and no mid-arc `3.0.0` ships (the brief's Naming/version strategy row, `g-docs/project_brief.md:52` as of 2026-08-10); a first release of a differently-named product does not inherit the predecessor's major. An earlier draft of this ADR said "G-Proof 3.0", which contradicted that row and left T1's "sunset at G-Proof 1.0" unable to fire; corrected 2026-07-26, brief row reaffirmed rather than amended. What the ADR *does* retire from that plan is M44's **gating** (it no longer waits on M35–M37, M29/M33/M34 or M38/M39), not its version identity. ~~What remains open is which items land in v2.5 before the freeze~~ — **decided 2026-08-10, [ADR-012](012-g-forge-2.5-final-release-scope.md)**, ~~v2.5 ships the full announced scope (M47 → M48 → M45 → M38 → M40 → M43 → M41)~~ — **re-decided 2026-08-28, ADR-012 amendment 4:** v2.5 is a **minimal freeze**. It ships M47 ✅ + M48 ✅ (both already cut in v2.4.1) plus **M52**, which absorbs only the slimmed M51/M40 items that survive this rebuild or fix something an adopter hits; M38, M40 Waves 2–3, M41, M43, M49, M50 and M51 items 1/7/10 are **dropped** to `g-docs/archive/roadmap-dropped-2026-08-28.md` as G-Proof candidates, decided at R0. **The filter was this ADR's own rebuild map** (`g-docs/audits/2026-07-rebuild-map.md` verdict column) — work built on a component the map marks DIES/TRANSFORMS is not worth shipping for one day. That reduced list is the last thing the 2.x line ever receives.
- The bug-report maintenance policy for frozen v2.5: what qualifies for a `2.5.x` patch and what is answered with "fixed in G-Proof."
- Telemetry continuity across the cut — whether the historical series joins up when inputs move from hand-counted to OTel.

**Risks:**
- GF-20 refutes and R3 collapses; the wave engine survives on a foundation chosen partly to delete it.
- GF-23 refutes and the review rebuild degrades from "delete `code-reviewer` and transform `architecture-enforcer`" to "keep both and add a delegation option." Blast radius is two rows, not four — `security-auditor`'s DIES rests on GF-74 and `wave-planner`'s on GF-20, and `wave-planner` is not a reviewer at all.
- Rented things get repriced. Ultra review is billed and user-triggered only; adjacent surfaces are preview and runtime-bound; subagent nesting already flipped from default-on to opt-in once. Every DIES verdict bets that a native capability stays available at the same tier and price.
- ~~Rebuilding the process while running it.~~ **Removed by the repo split** — the rebuild is governed by frozen v2.5 installed as a normal consumer, not by the half-rebuilt tree. This was the top-ranked premortem failure mode and the delivery shape eliminates it structurally rather than mitigating it.
- Tacit knowledge dies with the mechanisms — the tests that remember why a timing bound is 20000ms and not 8000ms are attached to code being deleted, and that knowledge was expensive to acquire.
- Demo surface shrinks. A 19-agent roster demonstrates itself; a gate plus a rules pack plus delegated native review does not, even when strictly better.

**Premortem — ranked failure modes with tripwires.** Each is stated with the earliest observable sign, so it can be detected rather than merely worried about.

| # | Failure mode | Earliest warning sign |
|---|---|---|
| 1 | ~~**Dogfooding deadlock**~~ — **structurally removed by the repo split.** The rebuild is governed by frozen v2.5 installed as a consumer, not by the tree being rebuilt. Retained in the record because it was the top-ranked mode and because the mitigation is the delivery shape itself: if the split is ever collapsed for convenience, this returns immediately. | Any proposal to develop G-Proof inside the frozen repo, or to install the in-progress rebuild over the working v2.5 that governs it |
| 2 | **Regression defence erodes at peak change volume** — the fork carries the suite across, but deleting a mechanism deletes its tests, so the suite shrinks silently while the green bar keeps reading green. Not a visible failure; a slow loss of the ability to detect breakage, during the highest-churn period the project will ever have. | A milestone where total test count drops and the delta is not recorded as coverage loss; a handoff quoting a suite total lower than the previous one with no note |
| 3 | **The spike is skipped, degraded, or rigged** — the posture is declared while the heaviest deletion waits on an unrun experiment, and that asymmetry resolves one way in practice. A replay against the historical wave record also flatters the new path, since the record was produced under the old orchestration. | R0 output describing the spike's *design* rather than its *results*; induced-failure behaviour marked deferred or partial; any reframing from go/no-go gate to "baseline measurement" |
| 4 | **The rebuild's cost overruns the maintenance it sheds and the project stalls half-migrated** — both implementations alive, neither complete, maintenance roughly doubled. Failure is an indefinite middle state, not day-one abandonment. | R0's counter-estimate coming in above the maintenance saving and the response being to rescope the accounting rather than the rebuild; a native replacement shipping while the original is kept "for now" with no dated deletion condition |
| 5 | **Platform coupling flips from asset to liability** — native primitives shift under a product that no longer has its own implementation to fall back to. Bash was slow but inert; a native-founded product inherits the platform's release cadence. The commit gate is insulated by construction; nothing else is. | A platform update silently changing a return shape, measurement unit or subagent default, discovered by using the tool rather than by a test failing — i.e. no contract test or version pin around any native primitive the rebuild depends on |

## Rejected Alternatives

| Alternative | Deciding factor |
|-------------|-----------------|
| Stay shell-only | Preserves the entire rented-mechanism inventory; treats syntax as if it were scope |
| Optional JS/Bun tier | Two behaviourally-identical implementations, no CI, one maintainer — the drift shape already measured |
| Strangler-fig as the mandate | No stable seam to strangle through; the harness for both sides is the suite being deleted. Phasing survives as R0–R6; the mandate does not |
| Execution + review only, freeze the rest | Line drawn by subsystem instead of the per-component test; re-grandfathers four components independently scored DIES or SHRINKS |
| Wait for GF-20 before deciding | Prices one deletion; deferral has a measured cost. Retained as a gate on R3 only |
| Additive integration | Surface only grows; no rule for which of two competing systems wins |
| Rules-and-gate pack | Keeps the opinions, discards their enforcement — which is the product claim |
| Off-platform standalone framework | Explicit brief non-goal; re-acquires every shed mechanism |
| Replace door 1 with a native `Tool(param:value)` permission rule | Permission rules are static config; the gate is conditional on a review sentinel. Static config cannot express "deny unless approved." GF-71 is defense-in-depth, never a replacement |
| Door 3 — CI-side gate as **enforcer** (GF-43) | Premise false: `/g-tier light` already disables the gate as a supported operation, so deleting a hook is an ignorant form of a shipped feature, not a bypass. Collides with two brief non-goals. Reopening requires amending the brief first |
| Door 3 — CI-side gate as **reporter** (advisory status, human decides) | Not rejected. Brief-compatible; parked against the multiplayer arc, where a second person's commits first exist |

## Assumptions That Held

- **The commit gate is language-independent at all three doors.** *Fragility:* the newest assumption in the set and the one carrying the most weight — it is what makes the rebuild's worst case survivable. It holds only while door 2 is genuinely installed and genuinely authoritative. A door 2 authoritative on paper but absent on disk returns the whole gate to door 1, which is inside the blast radius.
- **Dynamic workflow scripts are stable and non-preview.** *Fragility:* the entire execution rebuild rests on it, and adjacent surfaces are demonstrably less stable. Verify per release; a preview reclassification is an R3 stop.
- **Native review can inherit reviewer-lens rules content via `CLAUDE.md`.** *Fragility:* unverified, load-bearing for two rebuild-map rows (`code-reviewer` DIES, `architecture-enforcer` conditional). The cheapest assumption to test and the most expensive to be wrong about.
- **Worktrees plus background subagents cover wave isolation.** *Fragility:* moderate — the base exists. Untested is whether worktree isolation retires the same-wave conflict validator or merely relocates the collision; [ADR-006](006-optimistic-wave-concurrency-collisions-absorbed.md) needs re-reading against the new substrate.
- **Statusline, `/context` and a 1M-context default obsolete the hand-rolled estimator.** *Fragility:* low on the mechanism, higher on the policy — §A7's thresholds and §A1's tier table were calibrated against a smaller window and the recalibration has not happened.
- **The GF-20 spike will confirm rather than refute.** *Fragility:* an unrun experiment assumed in the direction the decision prefers. This is why R3 is conditional in the Decision rather than treated as priced.
- **Checkpointing does not restore subagent edits, so wave recovery is git-snapshot-before-dispatch.** *Fragility:* low — a live-doc-verified correction that narrows scope. Watch only for the platform closing the gap.
- **The SURVIVES set is genuinely native-free.** *Fragility:* a point-in-time claim on a platform that moved repeatedly during the audit. The weekly platform sync exists because this assumption decays continuously.
- **Native capabilities stay available at the same tier and price.** *Fragility:* already partly false — ultra review is billed and user-triggered only.
- **GF-70's Windows finding is directionally real even if imprecisely stated.** *Fragility:* unverified, and it shaped the constraint set. Needs a test, not a restatement.

## Constraints That Drove This Decision

- **Solo developer maintaining the entire surface.** Every hand-built mechanism is maintenance paid personally, forever. This is what makes "rent the mechanisms" a survival argument rather than an aesthetic one, and what disqualifies the two-implementation option outright.
- **Platform velocity outruns the audit cycle.** The external report was stale within weeks; 15 weekly digests were unaudited. Any strategy with a months-long transition window is written against a moving target.
- **The gate must stay dependency-light and act before the local commit completes** (ADR-004). This is what forces the gate *out* of the language decision rather than being solved by it.
- **Brief goal: stay opinionated but degradable.** Three integration tiers, and with the plugin inert the repo behaves byte-identically to a plain project. Every DIES verdict must ship a documented degraded path.
- **Brief non-goals bound the solution space.** "Not a CI/build system or a git replacement" and "not defence against a user who breaks the tool they adopted" jointly retire door 3's enforcer variant; "not a general framework" retires the off-platform rebuild. Reopening either requires amending the brief first.
- **Windows host with a bash-dependent hook layer.** Host portability of the enforcement layer is a first-class constraint, not a footnote.
- **No CI, and the repo dogfoods itself.** ADR-008's split cadence is in force, and the rebuild inherits both it and its scope ceiling.
- **The bash test suite is the only decay defence.** Whatever the rebuild does to it, it cannot leave the project with less decay defence than it has now.
- **Roadmap queue closed ahead of M29.** The rebuild enters as a recorded re-sequence with rationale, not as an insertion.

## Reversibility

The verdict changed once the delivery shape was recorded, and the change is load-bearing.

**Two-way at the product level.** The freeze-and-split means the old artifact never stops existing: v2.5 ships, stays published, and stays maintained on bug reports in its own repo. If G-Proof stalls, refutes, or is abandoned, the cost is G-Proof — not G-Forge. There is always something working to fall back to, and it is the thing users already have.

**Two-way per component row inside the new repo.** Individual verdicts remain reversible: DIES does not mean deleted today, and any component can be restored from history.

**One-way only inside the new repo's own trajectory.** Once G-Proof's execution layer commits to workflow scripts, reverting *within G-Proof* means rebuilding a deleted mechanism without its evidence base. That local asymmetry is why R0 exists as a separate authorized milestone: it buys the scope and the estimate before the irreversible cut, and its spikes can still refute the bands that depend on them.

Recorded because it inverts the original reading. Assessed against the tree alone, this was a one-way door. Assessed against the delivery shape, the riskiest-looking decision in the project's history is the one with the cleanest fallback.

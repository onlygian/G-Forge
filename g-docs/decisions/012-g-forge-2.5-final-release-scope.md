# ADR-012: G-Forge 2.5 ships the full announced scope

**Date:** 2026-08-10
**Status:** Accepted
**Amended:** 2026-08-14 — M49 (Devil's-Advocate Agent, internal adversarial pattern review) folded into the 2.5 scope; see "Amendment — 2026-08-14" below.
**Amended:** 2026-08-17 — M50 (Eval-Chain Integrity) folded into the 2.5 scope, sequenced **third** (after M48, before M45); see "Amendment — 2026-08-17" below.
**Amended:** 2026-08-20 — M51 (Release Reliability / M45-lite) inserted **third** in the build order, absorbing M45 (Review Pipeline Rework); M50 moves to fourth. See "Amendment — 2026-08-20" below.
**Amended:** 2026-08-22 — intermediate patch/minor releases cut at milestone-family closes; 2.5 scope and freeze identity unchanged; see "Amendment — 2026-08-22" below.
**Amended:** 2026-08-24 — rendering rule for the README's "What's coming in 2.5" copy at intermediate cuts: shipped bullets are marked in place; see "Amendment — 2026-08-24" below.
**Reversibility:** two-way door, narrowing (scope can be re-cut before 2.5.0 ships, but the §3c copy has been on the README since 2026-08-10 under a hedged "What's coming in 2.5" heading — cutting an announced item now means editing published copy, a developer decision; at release the heading goes present-tense and the door closes)
**Context:** G-Forge plugin source repo. Decision made by the developer in session, 2026-08-10 — this ADR captures it; the deliberation was the session's intake + triage, not a subagent pass.

## Amendment — 2026-08-24: "What's coming in 2.5" rendering at intermediate cuts

Developer decision (session record, 2026-08-24, at the v2.4.1 doc gate): when an intermediate cut ships an item the README's `### What's coming in 2.5` copy still announces as future, the affected bullet is **marked in place** with a short shipped tag (e.g. *"(Already shipped early — in v2.4.1.)"*) — the section keeps its approved shape and the promise list stays visible; bullets are never silently removed or moved to a separate block. A bullet that mixes shipped and unshipped claims gets the tag scoped to the shipped sentence only. This resolves the gap the 2026-08-22 amendment left open (it introduced intermediate cuts without addressing this copy), first hit at the v2.4.1 cut (`README.md:44,:50`); the rule applies at every subsequent family close. At the 2.5.0 release the heading goes present-tense per the original decision and the tags dissolve with it.

## Amendment — 2026-08-22: intermediate releases on the road to 2.5

Developer directive (session record, 2026-08-22): the 2.5 scope and the freeze-release identity are unchanged, but the road to it now cuts **intermediate patch/minor releases at milestone-family closes** — first candidate v2.4.1 at the M48-family close (M47 + M48a–e). Rationale: the project's own testing model is release-and-dogfood, and a monolithic 2.5 starves the field-validation loop for months — everything hardened since v2.4.0 was un-dogfoodable outside this repo. v2.5.0 remains the final G-Forge label — **M41 cuts it** (sequenced last in the build order, `g-docs/ROADMAP.md:451`); **M51 defines the release condition** it must meet ("a reliable and very usable harness," not a doc patch — `g-docs/ROADMAP.md:622`) — cumulatively containing everything this ADR promises; the intermediate cuts change delivery cadence, not scope. Standard release flow (§D) applies to each cut: both manifests, CHANGELOG, tag, GitHub release.

**Surface set updated for this amendment** — this ADR (header + this section + the "one release vehicle" claim, amended in place at what is now `:70` below) · `CHANGELOG.md:11` · `g-docs/ROADMAP.md`'s Version Plan (`:667`) · M47's and M48's `**Version:**` stamps (`:517`, `:547`). No typed site list is authoritative — this one included: the complete set is found only by sweeping.

## Amendment — 2026-08-20

**M51 (Release Reliability, M45-lite) is added to the v2.5 scope and absorbs M45 (Review Pipeline Rework)**, decided by the developer 2026-08-20 — the v2.5 release-condition scope change. Evidence base: two external 2026-08-20 audit reports (a gaps-and-fixes report enumerating A1–A10/B1–B12, and a benchmark pilot report); every acted-on claim from those reports was re-verified against the current tree at intake (code-lead holds no Agent grant; the jq rc-only check at `hooks/agent-lifecycle.sh:89-91` is live; `g-docs/g-proof-roadmap.md` is gitignored at `.gitignore:67`).

Sequenced **third** in the build order — after the M48 family, before M50 — because the review panel M51 wires is exactly the machine M50's own review-pipeline measurements need to already be pointed at; measuring it before M51 rewires it would measure the wrong machine. M50 moves from third to **fourth**.

**Why M51 absorbs M45 rather than the two running side by side.** The review panel has been solo-review since `daf15e3` removed `code-lead`'s Agent grant, with `51e5220` re-adding AXES language without restoring the grant — a wiring gap, not a design gap. The developer's decision (2026-08-20) is to wire the panel directly rather than doc-fix around the hole: `review-orchestrator` dispatched from `/g-review` at depth 0. This executes M45's design-ADR core as "M45-lite" — the reviewer record-write question (scoped-Write grants vs HQ-writes-records) is settled by directive (the doc-reviewer/task-decomposer scoped-Write precedent), not deferred to a separate design ADR, and review scope is fixed as diff + blast radius rather than left open. M45's own entry is retained as the design record (`Status: 🔀 Folded into M51`) rather than deleted.

The scope table below replaces the M45 row with an M51 row — nine rows remain (M45 is folded, not a tenth addition), so the two derived milestone counts (Consequences → Harder, and Risks) are unchanged by this amendment.

**Surface set updated for this amendment** — extends the 2026-08-17 list for M51, and corrects that list's own claim about `CHANGELOG.md:11`: this ADR (header + this section + scope table) · `ROADMAP.md`'s Version Plan build-order line, M41's `Depends on:` precedence list, M50's `Depends on:`/`Feeds:` lines, and M45's `Status:`/`Depends on:` fold note · `project_brief.md`'s v2.5 roadmap row and standing-state bullet · `README.md`'s v2.5.0 milestone list · `g-wiki/README.md`'s build-order line · `g-docs/milestones/M41.md`'s precedence list · `CHANGELOG.md:11`'s `[Unreleased]` announcement line, which the 2026-08-17 amendment recorded as not enumerating the milestone order — that record was wrong (it does, and was stale on both the M50 and M45→M51 folds); corrected here · `g-docs/todo.md` rows citing the folded milestone · every `ROADMAP.md` line naming the folded milestone as a live requirer or sequencing anchor. No typed site list is authoritative — this one included: the complete set is found only by sweeping, and the sweep needs BOTH the bare milestone token AND the ordinal/sequence words ("third", "fourth", "sequenced", "pinned", "before M", "after M" — examples, not a complete set), because a sequencing claim can name no milestone token at all.

## Amendment — 2026-08-17

**M50 (Eval-Chain Integrity) is folded into the v2.5 scope**, decided by the developer in session at the `/g-intake` triage that followed the 2026-08-17 `/g-telemetry` run. Sequenced **after M48, before M45** in the build order — M45's design ADR needs M50's agent contract map as an input, so ordering them the other way makes M45 guess. *(Superseded 2026-08-20 — M51 now sequenced third, absorbing M45; M50 moved to fourth. See "Amendment — 2026-08-20" above.)* The scope table below gains a **ninth** row for M50; the two derived milestone counts (Consequences → Harder, and Risks) go from eight to nine accordingly. M45's `Depends on:` moves from *third* to *fourth*. Nothing else in this ADR's decision or constraints changes.

**Why it is in 2.5 rather than the fork.** A 2.5/G-Proof split was proposed — fix the instrument *definitions* in 2.5, defer the *rewiring* to the rebuild, on the reasoning that ADR-010 replaces the current agent/hook layer anyway. The developer overrode it: **2.5 is a maintained freeze with real users, so it must do what it says at the best of its capabilities**, and "it gets rebuilt later" is not a reason to ship a release whose self-governance instruments do not measure what they claim. The override is recorded because it inverts the ADR-010 cost argument, and a future reader will otherwise re-derive the split and reach the wrong answer.

**What triggered it.** The `/g-telemetry` run of 2026-08-17 returned a clean-looking `cautious` profile while four of its own gauges were structurally incapable of registering the failures this project keeps recording — most starkly, coverage scored `code-reviewer` as `never` on a day the journal records it starting and stopping (`g-forge:code-reviewer start a8e145c2`, 2026-08-16). A fifth defect is user-facing: `g-docs/telemetry-metrics.md`, the skill's declared authoritative spec, **has no ship vehicle at all** — no skill creates it, so `/g-telemetry` reads a missing file on every consumer project.

**Surface set updated for this amendment** — the same list the 2026-08-14 amendment established as complete: this ADR (header + this section + scope table + both derived counts) · `ROADMAP.md`'s Version Plan build-order line, M41's `Depends on:` precedence list, and M45's `Depends on:` sequence position · `project_brief.md`'s v2.5 roadmap row · `README.md`'s v2.5.0 milestone list. `CHANGELOG.md:11` and the local-only `g-proof-roadmap.md:255` were **checked and require no edit** — neither enumerates the milestone list; they were in the 2026-08-14 set for unrelated reasons (freeze announcement, fork boundary). Recording the check so a future reader does not read their absence as an oversight. *(Superseded 2026-08-20 — the `CHANGELOG.md:11` half of that check was wrong: it does enumerate the order and was stale on two folds; see the 2026-08-20 amendment's surface-set correction.)*

## Amendment — 2026-08-14

**M49 (Devil's-Advocate Agent, internal adversarial pattern review) is folded into the v2.5 scope**, decided by the developer in session at the `/g-patterns` lifecycle intake. Sequenced **after M43, before M41** in the build order — the release-cutting milestone still runs last. The scope table below (originally seven rows + `shipped`) gains an eighth row for M49; the table and the two derived milestone counts below (Consequences → Harder, and Risks) are updated to eight accordingly — nothing else in this ADR's decision or constraints changes. `ROADMAP.md`'s Version Plan build-order line (`:570`) and M41's `Depends on:` precedence list (`:452`), `project_brief.md:38`, `README.md:766`, `CHANGELOG.md:11`, and the local-only `g-proof-roadmap.md:255` stamp all record the same amendment — this is the complete surface set for any future 2.5 scope change. This is the ADR-side entry the M49 review finding (MAJ-1, `code-lead-2026-08-14-patterns.md`) required.

## Context

ADR-010 set the delivery shape (v2.5 ships from this repo, the repo freezes, the tree forks into G-Proof, which ships as 1.0) but left the 2.5 contents open — the roadmap recorded "only M41 is a candidate" while the approved 2026-07-28 communication plan (`g-docs/communication-plan-2.5.md` §3c) promised seven concrete items, four of which the roadmap still assigned to v2.6.0–v2.15.0. The 2026-08-10 intake added two more milestones (M47 decomposer + calibration, M48 review hardening — both seeded by this repo's own nine-round fix-loop and the keyline field report, `g-docs/field-reports/2026-08-10-keyline-francesco.md`). The scope had to be settled in the record before anything else could be sequenced honestly.

## Decision

**G-Forge 2.5 ships everything the approved copy promises.** The 2.5 scope is:

| In 2.5 | What it is |
|---|---|
| M47 | Planning-Pipeline Honesty (decomposer sizing + seam return, forecast calibration, review-chain cost term) |
| M48 | Review-Pipeline Hardening (grep-sweep required step, round-3 consolidation, volatile-fact heuristic, falsifiability rule) |
| M51 | Release Reliability / M45-lite (review panel wiring, gate execution coverage, CI, A6 grants, A7 re-sync, S-fixes, context-estimator deletion) — **added 2026-08-20**, absorbs M45 (Review Pipeline Rework, folded — retained as design record), see Amendment above |
| M50 | Eval-Chain Integrity (telemetry/coverage measure ground truth, agent contract map, firing audit) — **folded in 2026-08-17**, see Amendment above |
| M38 | G-Report (`/g-report` — the maintenance channel the freeze story leans on) |
| M40 | Reference Convention (committed reference material stops being mis-gated) |
| M43 | Operator Controls (`/g-settings` + inspection cadence) |
| M49 | Devil's-Advocate Agent (internal adversarial pattern review) — **folded in 2026-08-14**, see Amendment above |
| M41 | Release Machinery + README Currency — **cuts the 2.5.0 release, sequenced last** |
| shipped | Check 24 injection detector; `/g-init` lib-install fix (`ec9bf8a`) |

All in-2.5 milestones ship cumulatively in **v2.5.0**, the single final G-Forge release label — no v2.6+ ever ships from this repo. Intermediate patch/minor releases below that label (v2.4.x) may cut at milestone-family closes — **amended 2026-08-22**, see "Amendment — 2026-08-22" above.

**Everything else forks to G-Proof:** M25, M26, M29–M37, M39, M42, M44, plus both backlog candidates (multiplayer orchestration, unified provenance). Their entries move to `g-docs/g-proof-roadmap.md` — **a gitignored, local-only file by explicit developer choice** (2026-08-10), carried to the fork by hand. The committed pointer in `ROADMAP.md`'s Backlog section is the record that the file exists; carrying it across the fork is a named fork-checklist item, because a gitignored planning file has been lost in this repo once before (CLAUDE.md, regenerated 2026-07-10).

Related calls made the same day:

- **M41 stays in 2.5** (developer, over the session's recommendation to hand-cut the release) — the freeze release itself goes through the gated pipeline M41 builds.
- **README carries the full 2.5 comms treatment** — published 2026-08-10, ahead of the release, by an explicit developer **override** of the plan's §4 publish-at-release rule (the override and its two sanctioned copy edits are recorded in `communication-plan-2.5.md`'s header). Remaining surfaces (CHANGELOG 2.5.0 heading, announcement) still publish at release.
- **M38's delivery reconciliation stays open** (§7 item 2: "hands you a file" vs via-git) — decided at M38 plan time, not here. The keyline report arriving as a hand-written file is standing evidence the file path works.

## Constraints That Drove This Decision

- **The approved copy is a commitment.** `communication-plan-2.5.md`'s §3c copy (developer-approved 2026-07-28, changes are a developer decision) promises seven concrete items. Any 2.5 scope thinner than the copy forces a copy rewrite; any scope statement that ignores the copy leaves the record contradicting the announcement.
- **§3a structurally depends on `/g-report`.** The freeze story's maintenance commitment names its channel ("That's what `/g-report` is for") — a 2.5 without M38 breaks the announcement's load-bearing sentence, not just a feature bullet.
- **ADR-010 is fixed ground:** v2.5 is the last release, the repo freezes, G-Proof ships 1.0 from a fork, no G-Forge 3.0. This decision chooses 2.5's *contents*, never its *identity*.
- **The roadmap contradicted itself:** "only M41" in three places vs. four §3c items stamped v2.6.0–v2.15.0 — an unsettled scope was blocking the comms plan, the audit, and all sequencing.

## Alternatives Considered

1. **Minimal freeze — M41 + M47 + M48 only, fork everything else.** Fastest path to the fork. **Rejected (developer):** cuts four of §3c's seven bullets *and* breaks §3a's `/g-report` sentence — the biggest copy rewrite and the weakest freeze story.
2. **Middle scope — M41 + M38 + M47 + M48** (the session's recommendation: keep what the freeze story needs, fork M45/M43/M40). **Rejected (developer):** still cuts three announced items; the copy would be rewritten around a thinner release instead of the release honoring the copy.
3. **Hand-cut the release, fork M41 too** (session's pushback: machinery built for a single use). **Rejected (developer):** the freeze release itself goes through the gated pipeline — the last release is exactly the one that should not be hand-walked.
4. **Full copy scope** — **chosen.** The release ships what the announcement says, verbatim.

## Consequences

**Easier:**
- The announcement stays true word-for-word — no copy renegotiation, no §3c rewrite, no weakened freeze story.
- Every 2.5 milestone now carries the same version stamp and one recorded build order — planning and release sequencing read from one place.
- `communication-plan-2.5.md` §7 blocking findings 1 and 3 close with the re-scope pass this ADR anchors.

**Harder:**
- The freeze date moves out: nine milestones ship before the fork, not one. Accepted knowingly.
- The G-Proof start date moves with it — every fork-bound milestone waits behind the full 2.5 arc.

**Follow-up work:**
- Finding 2 (M38 delivery: "hands you a file" vs via-git, + hook-trigger/report-menu scope) is carried to M38's plan gate.
- "Only M41" retired in the committed record — `ROADMAP.md` Version Plan, `project_brief.md`, `M41.md`, `communication-plan-2.5.md` (header + §7, swept 2026-08-10 after doc-review caught two survivors). One historical occurrence survives **by design** inside the M44 ADR-010 stamp in `g-proof-roadmap.md` (local-only) — struck through and stamped superseded rather than rewritten, because that stamp is ADR-010's dated text.
- The Version Plan's v2.6.0–v2.15.0 tail is deleted, not re-stamped — those numbers never ship; versioning restarts as G-Proof 1.0 per ADR-010 (unamended).

**Risks:**
- *Scope fatigue* — nine milestones under one version invites mid-arc re-cuts; any narrowing after release copy is published falsifies the announcement (this is the one-way edge of this two-way door).
- *The gitignored `g-proof-roadmap.md` gets lost* — machine-local by developer choice; mitigated by the committed pointer in `ROADMAP.md`'s Backlog, the git-history recovery path, and the named fork-checklist item.

## Assumptions That Held (verify at 2.5 close)

- The §3c copy's per-item claims still match what each milestone actually shipped (§7 "re-verify at publish time" list — especially "same verdict, a fraction of the cost" — originally pending M45's A/B; M45 folded into M51 (2026-08-20), so the obligation transfers to M51's panel wiring, which must demonstrate verdict-equivalence (or record the trade) before this claim publishes, and "recalibrated" requiring genuine ground-truth calibration in M47).
- `g-docs/g-proof-roadmap.md` still exists on the working machine at fork time and is on the fork checklist.

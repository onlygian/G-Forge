# Communication Plan — G-Forge 2.5 (final feature release)

> **Status:** **ACTIVE — copy approved 2026-07-28; scope recorded 2026-08-10 ([ADR-012](decisions/012-g-forge-2.5-final-release-scope.md)).**
> **§4's publish-at-release rule was OVERRIDDEN by the developer 2026-08-10:** the §3a+§3b+§3c copy went onto the README ahead of the 2.5.0 release, knowingly (§3c under a "What's coming in 2.5" heading until release). Two copy edits landed with that decision (both developer-decided 2026-08-10): §3a's "four other projects" → "my own projects" (the count could not be stood behind), and a "(ships in 2.5)" clarifier on `/g-report` (the command does not exist at v2.4.0 — publishing early forced the truth fix). Freeze-cause narrowing to the single improvement-opportunity cause is **deliberate** (developer, same date) — ADR-010's other two causes stay in the record, not the announcement.
> **Owner:** HQ. Changes to the copy below are a developer decision, not an editing pass.
> **Anchors:** [ADR-010](decisions/010-full-rebuild-on-current-platform.md) (rebuild + version identity: G-Proof ships as 1.0, there is no G-Forge 3.0).
>
> **§7 records the decision trail.** ~~The 2.5 scope described in §3c is in the committed record as of 2026-08-10 — [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) plus the roadmap re-scope pass: all eight milestones stamped v2.5.0, M47/M48 recorded, the "only M41" framing retired.~~ **Superseded 2026-08-28 ([ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) amendment 4):** 2.5 is a minimal freeze — M47 ✅ + M48 ✅ (shipped v2.4.1) + M52, hand-cut 2026-08-30. §3c is rewritten to match; see the 2026-08-28 re-scope block in §7. §7's formerly-blocking findings are closed or carried; one item (M38's delivery reconciliation) is decided at M38's plan gate.

---

## 1. What this plan says

G-Forge 2.5 is the **last feature release**. From there the project is maintenance-only, deliberately, so the developer can build its successor (**G-Proof**) on a stable base while continuing to run G-Forge on their own live projects. *(Count dropped 2026-08-10 per §7 — the copy says "my own projects".)*

Three things must land together or the message reads wrong:

1. **The freeze is a choice, not a wind-down.** The reason is honest and specific: the intended direction needs a rework deep enough that stable releases and predictable maintenance could not be promised while it was underway.
2. **Maintenance is a real commitment**, backed by a real reason (the developer depends on it daily) and a real channel (GitHub issues on this repo — `/g-report` was dropped 2026-08-28, ADR-012 amendment 4).
3. **G-Proof is tangible but unpromised.** Three named directions, an explicit "there's more I'm not describing", no date, no feature list.

**The freeze paragraph does not justify itself.** The "What's next" block does. Publish them adjacent, in that order.

---

## 2. Audience

| Audience | Cares about | Reads |
|---|---|---|
| Existing users (few, dogfooding) | Am I stranded? Do my bugs get fixed? | README freeze + maintenance commitment, GitHub issues |
| Prospective users | Is it worth adopting something frozen? | "What's in 2.5" concrete list, maintenance commitment |
| The developer, later | Why was this decided this way | This file + ADR-010 |

Nobody in this set wants marketing. Plain, specific, no hype.

---

## 3. Approved copy

Lift verbatim. Sub-headings are part of the copy.

### 3a — The freeze (README, announcement)

> **G-Forge 2.5 is the last feature release.** From here it's maintenance, and that's deliberate.
>
> Where I want to take this next needs a rework deep enough that I couldn't honestly promise stable releases or predictable maintenance while it was underway. Quietly destabilising something people rely on is worse than drawing a clean line, so this is the line.
>
> Frozen isn't abandoned. I run G-Forge on my own projects, so its bugs are my bugs and they'll keep getting fixed. That's what GitHub issues on this repo are for: when something breaks or gets in your way, file an issue. Reasonable feature feedback travels the same route.
>
> And 2.5 is the version I'll build the next thing with. That's the real reason for freezing it. You want something stable under your feet while you're building its successor.

### 3b — What's next (README, immediately after 3a)

> Three things G-Forge kept running into and can't reach from where it stands.
>
> **Knowing how much something matters.** Every part of the system currently judges importance on its own, mostly by feel. Priority, severity, impact and relevance should be one shared idea the whole system reasons with.
>
> **Memory that behaves like memory.** Today the record is a well-organised pile of documents. It should be something a session can walk and follow, pulling exactly the slice the task needs.
>
> **More than one of you.** One project, several people or several sessions, working at once without silently colliding.
>
> Each of those is a layer that has to run through everything the system does, and you don't retrofit that. That's the rebuild, and it's called G-Proof. There's more to it than these three, and it isn't ready to be described. No date.

### 3c — What's in 2.5 (release notes, CHANGELOG intro)

> **Planning that doesn't invent work.** Task breakdown used to split jobs that belong together and hand each fragment to its own agent. The sizing fix is in — *already shipped early, in v2.4.1* — so you stop paying for coordination you never needed.
>
> **Reference material stops being mis-gated.** Committed reference material a project builds against was being blocked as though G-Forge owned it. That's fixed.
>
> **Forecast risk replaces a percentage that nobody believed.** Plan-time risk estimates now show what the formula actually predicts instead of a percentage you've learned to ignore.
>
> **Documentation that can't quietly rot.** The health check now flags anything in your CLAUDE.md that's a hand-typed fact rather than one sourced from a file. That's how those facts go stale without anyone noticing.

---

## 4. Placement

| Surface | Carries | Note |
|---|---|---|
| `README.md` | 3a then 3b (adjacent, in that order) then 3c as "What's in 2.5" | 3b is what makes 3a land; 3c placement per the §7 resolution, published 2026-08-10. **Heading updated 2026-08-28** (re-scope below): the hedged "What's coming in 2.5" is retired — §3c `:64` and `README.md:40` both read "What's in 2.5" |
| `CHANGELOG.md` under `## [2.5.0]` | 3c, then the itemised entries | Keep-a-Changelog format below the prose |
| Release announcement (wherever it goes) | 3a + 3c, 3b condensed to its closing paragraph | |
| `.claude-plugin/marketplace.json` description | Neither. One line, unchanged in tone | Not a place for the freeze story |

Publish nothing before 2.5.0 ships. A freeze announced ahead of the release that justifies it reads as abandonment. *(OVERRIDDEN for the README surface only — developer, 2026-08-10, recorded in this file's header; CHANGELOG 2.5.0 heading and the announcement still wait for release.)*

---

## 5. Boundaries — what this plan does not say

- **No date for G-Proof.** Not "soon", not "next year", not "after 2.5". None.
- **No G-Proof feature list.** The three directions in 3b are hints. Everything else stays undescribed, and 3b says so explicitly. Do not extend the list because a fourth item seems safe.
- **No claim about how G-Proof gets built.** Whether the dogfooding pattern repeats is undecided. It is not mentioned publicly either way.
- **No G-Forge 3.0, ever.** Per ADR-010 the 2.x line simply ends and versioning **restarts** under the new name: a first release of a differently-named product does not inherit the predecessor's major. A 3.0 here would make the successor's 1.0 read as a downgrade.
- **No promise of feature work after 2.5.** Maintenance means fixes. GitHub issues accept feature feedback; accepting them is not committing to them.
- **No apology framing.** The freeze is a decision with a reason, delivered once, not hedged or revisited.

---

## 6. Why the message is shaped this way

Two failure modes drove the wording.

**"Frozen" reads as "dead" unless maintenance is concrete.** Abstract reassurance does not survive contact with a user deciding whether to adopt. The specifics carry it: the developer runs G-Forge on their own live projects daily, so the bugs are the developer's own, and a named channel that ships in the same release. *(The count was dropped from the copy 2026-08-10 — see §7.)*

**A freeze with no visible successor reads as giving up.** Hence 3b sitting directly under 3a. The three directions are chosen to be individually understandable and to make the same point in three ways: each is a layer that runs through everything, which is precisely what a rework of the current body cannot deliver. That argument justifies the freeze better than the freeze paragraph does.

The 2.5 feature copy is deliberately concrete rather than thematic. An earlier draft summarised the release as "costs less, lies less, reports its own failures" — true, and useless to someone deciding whether to upgrade. Every item in 3c names the thing that was wrong and what changes.

---

## 7. Record status and open decisions

This file was gated by `/g-doc-review` on 2026-07-28: **DOCS HOLD, 3 blocking · 8 warning**. The blocking three all reduce to one cause — the 2.5 scope lives in session context, not in the committed record — and all three close when the roadmap re-scope pass runs. The copy itself was not the problem; §3b's three G-Proof directions, the ADR-010 freeze premise, and five of §3c's seven items all verified clean against the repo.

The arithmetic below is coincidental, not a mapping: of the eight warnings returned, one (the "reserves the next major" mechanism error) was **fixed in place** rather than carried, and the §2-vs-§4 mismatch was split out of the §4 finding into a row of its own. Eight returned, eight open, different eights.

**Formerly blocking — closed by the 2026-08-10 re-scope pass (ADR-012), except as noted:**

1. ~~**§3c scope vs `ROADMAP.md`.**~~ **RESOLVED 2026-08-10.** All four items re-stamped v2.5.0 in `ROADMAP.md` (M45, M38, M40, M43); M47 records the task-decomposer work; the "only M41" framing is retired in the Version Plan, `project_brief.md`, and `M41.md`. (The original finding's `ROADMAP.md:750`/`:799` cites are dead — the file was reshaped by the same pass.)
2. **M38 redesign — CARRIED, not closed.** The hook-trigger + report-type-menu scope and the delivery reconciliation ("hands you a file to send" vs via-git) are both decided at **M38's plan gate** — recorded on M38's Version line in `ROADMAP.md` and in ADR-012. One of the two delivery claims is wrong and the record decides which, there.
3. ~~**No inbound reference.**~~ **RESOLVED 2026-08-10.** The roadmap's Version Plan 2.5 entry points here, and `g-docs/milestones/M41.md` carried the read-this-first precondition line. *(Updated 2026-08-28: M41 is dropped and its file archived to `g-docs/archive/milestones/M41.md`. The precondition moved with the release itself — it now sits on M52's Session D line in `ROADMAP.md`, which is what cuts v2.5.0.)*

**Developer decisions — resolved 2026-08-10 except where noted:**

- ~~**"Four other projects" (§3a).**~~ **RESOLVED: number dropped** — copy now reads "my own projects". The commitment stands without a count to defend.
- ~~**Freeze cause set (§1).**~~ **RESOLVED: single cause, deliberate.** ADR-010's full three-cause set (platform drift, genuine overlap, improvement opportunity) stays in the record; the announcement carries the third only.
- **Announcement block order (§4) — STILL OPEN.** The announcement row orders 3a + 3c then 3b, which breaks the adjacency rule §1 and §6 both call load-bearing; and "3b condensed to its closing paragraph" leaves "Each of those is a layer…" without an antecedent. Decide at announcement time (release).
- ~~**§2 vs §4.**~~ **RESOLVED: README carries 3c** (as "What's coming in 2.5" until release, present-tense at release) — per the developer's full-treatment decision, 2026-08-10.
- **`/g-report` clarifier — RESOLVED 2026-08-10.** Publishing §3a ahead of release forced a truth fix: the command does not exist at v2.4.0, so the copy gains "(ships in 2.5)" — applied to the §3a block itself, so any verbatim lift (README now, announcement at release) carries it. Drop the clarifier at release if 2.5.0 ships `/g-report`, as a deliberate copy edit.

**2026-08-28 re-scope — copy rewritten to precede release with actual scope:**

The 2026-08-10 full-scope decision is amended per [ADR-012 amendment 2026-08-28](decisions/012-g-forge-2.5-final-release-scope.md#amendment--2026-08-28-minimal-freeze). The sole adopter accepted the thinner 2.5; the §3c copy published on the README from 2026-08-10 bound no outside reader, because throughout that window it carried the hedged, future-tense "What's coming in 2.5" heading. That is what dissolved the commitment — and this re-scope is also what retires the heading: §3c `:64` and `README.md:40` now read "What's in 2.5", and §4's placement row is updated to match. Copy rewritten to describe what M47 + M48 + slimmed M51/M40 ship, not what was planned:
- ~~"Lighter where you feel it most" (M45/M51 review panel — DIES in rebuild).~~ **DROPPED.**
- ~~"Every setting in one place you can see" (M43 `/g-settings` — TRANSFORMS/DIES).~~ **DROPPED.**
- ~~"A way to tell me when it breaks" (M38 `/g-report` — TRANSFORMS to GitHub issues in the announcement).~~ **DROPPED** and **replaced in §3a with GitHub issues routing**.
- ~~"Releases in one step" (M41 `/g-release` — replaced by M52 hand-cut release).~~ **DROPPED.**
- **§3a `"/g-report" → GitHub issues`** — M38 transforms; the freeze story now names GitHub issues as the maintenance channel.
- "Planning that doesn't invent work" **kept as-is** (M47, shipped v2.4.1).
- "Reference material stops being mis-gated" **re-titled from "Gates that stop misfiring"** to name only what ships: M40 Wave 1. Prior clause about review-gate unlock removed (not shipped in 2.4.0/2.4.1 per CHANGELOG audit; see `Review-Pipeline Hardening` section of v2.4.1 for the actual 2.5 hardening).
- "Forecast risk replaces a percentage..." **new bullet from M47 item 8** (forecast relabel to prediction formula, not a percentage).
- "Documentation that can't quietly rot" **kept as-is** (Check 24, already shipped v2.4.1).

**Re-verify at publish time (claims that outrun their evidence today):**

- **"Same verdict, a fraction of the cost" (§3c).** M51's panel wiring (inheriting folded-M45's obligation, 2026-08-20 fold) treats verdict-equivalence as unproven until demonstrated on a real changeset — its done condition per the M51 ROADMAP entry. If the fallback is still live at release, this sentence asserts a property the milestone has not returned.
- **"Risk percentages get recalibrated" (§3c).** The recorded field report offers two fixes: a cheap relabel that changes no number, and genuine calibration from ground truth. Only the second earns the word "recalibrated".
- **Check 24 description (§3c).** Accurate for BARE-PROSE, imprecise for DECLARED-LOCAL: content inside a local-only block is hand-typed and not file-sourced, and is counted rather than flagged.
- **§3b vs R0 (§5).** ADR-010 authorizes R0 only and states no rebuild roadmap is published with it. Three named directions are the closest this plan comes to the public commitment the ADR exists to avoid; the "no date, not ready to describe" hedges are what keep it on the right side.

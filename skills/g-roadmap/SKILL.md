---
name: g-roadmap
description: Project-manager-driven milestone planner. Gated phases — feature dump → cluster → sequence → premortem & re-prioritize → approve → write. Narrates reasoning at every step, and runs a premortem + re-prioritization of the whole roadmap whenever a milestone is added or modified. Auto-triggers when no g-docs/ROADMAP.md exists, no active milestone is present, or the developer drops an explicit multi-feature dump or asks for a full re-plan (a single dropped idea routes via /g-intake first). Never writes g-docs/ROADMAP.md until the developer explicitly approves.
---

**Announce:** "Using g-roadmap to plan your milestones."

You are the project-manager for this planning session. Your job is to turn ideas into a realistic, sequenced roadmap — and to narrate your reasoning out loud at every step so the developer can catch wrong assumptions early.

The developer brings the vision. You bring structure, risk awareness, and honest pushback. Every idea the developer mentions belongs in this roadmap — either in a milestone or in the backlog. Nothing gets quietly dropped.

## Step 0 — Check context

Read `g-docs/ROADMAP.md` if it exists. Scan for:
- Any milestone marked 🔄 (active / in progress)
- Any milestone marked ✅ (complete)
- The backlog section

Note the current state:
- `roadmap_exists`: true / false
- `active_milestone`: [milestone title] / none
- `completed_milestones`: [list] / none
- `backlog_items`: [list] / none

Read `g-docs/project_brief.md` if it exists — extract the goal, constraints, and tech decisions.

**Read the current version.** Check (in order): `.claude-plugin/plugin.json`, `package.json`, `pyproject.toml`, `Cargo.toml`. Record it as `current_version`. If none found, record `current_version: unversioned` and note that the developer will need to establish a starting version.

**Baseline dependency scan.** If any manifest file is present (`package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Pipfile`, `pyproject.toml`, `pom.xml`, `build.gradle`), dispatch `dependency-auditor` now — in parallel with reading `g-docs/project_brief.md`. This scan runs before the feature dump so its findings can influence milestone prioritisation.

If dependency-auditor returns any HIGH severity findings, surface them at the top of Step 1 before asking for feature ideas:
> "⚠ Before we plan new features — your current dependencies have [N] HIGH severity issue(s): [brief list]. These should be a milestone in the roadmap, likely early. I'll flag this during sequencing."

LOW/MEDIUM findings are noted but not surfaced until Step 3 (sequencing), where a dependency-hygiene milestone can be placed appropriately. Do not block the feature dump for any finding — surface as context that shapes prioritisation.

If an active milestone exists, tell the developer:
> "There's an active milestone: **[title]**. Are you adding new ideas to the plan, or is this a full re-plan from scratch?"

Wait for their answer before continuing. If adding to the current plan, carry existing milestones and backlog into Step 1 as context.

## Step 1 — Feature dump intake

Say:
> "Tell me everything you want to build — in any order, any level of detail. Don't filter. Every idea goes in, whether it's core today or nice-to-have someday. I'll sort it out."

Wait for the developer's full response. Do not interrupt or ask follow-up questions mid-dump.

Once they've finished, acknowledge everything you heard:
> "Here's what I captured — tell me if I missed or misrepresented anything:"

List every idea, numbered, phrased back in plain terms. If carrying over items from an existing roadmap/backlog, include them in the list with a `(existing)` note.

Ask: "Anything missing before we start grouping?"

Wait for their answer. Update the list. Do not proceed to Step 2 until the developer says the list is complete.

## Step 2 — Cluster with narrated reasoning

Group the features into **3–7 natural clusters** based on:
- The user-facing surface they affect
- Shared technical dependency
- Cohesion of release value — what makes sense to ship together as a unit

For each cluster, narrate out loud:
> **Cluster: [Name]**
> Why I grouped these: [1–2 sentences — the common thread]
> Items: [list]
> Risk flag (if any): [specific concern about scope, complexity, or dependency]

After presenting all clusters, surface your key assumptions:
> "My grouping assumes [state 2–3 assumptions]. If any of these are wrong, the grouping changes."

Wait for the developer to accept or push back. Revise clusters if needed. Do not proceed to Step 3 until the developer says the clusters look right.

## Step 3 — Sequence with dependency and version justification

Take the approved clusters and arrange them into a milestone sequence. Version planning is part of sequencing — every milestone gets a target version and a reason for that version increment.

**Semver rules for milestone versioning:**
- New user-facing capability, new public API, new skill/command → **minor** bump (x.Y.0)
- Bug fixes, internal refactors, polish, dependency updates → **patch** bump (x.y.Z)
- Breaking change to public API, incompatible behaviour change → **major** bump (X.0.0)
- First release of a new project → start at v0.1.0 (or ask the developer for their preferred baseline)

**Split-lineage naming (only when this run is breaking an existing, already-milestoned scope into sub-milestones — whether invoked from `/g-plan`'s Step 3c context-budget gate or run manually for the same reason):** the milestone/plan ID being split may already carry a trailing `-split<N>` marker (e.g. `M47-split1`) from an earlier split. Grep the parent ID/slug for `-split[0-9]+` before naming the sub-milestones. No existing marker → each sub-milestone ID gets `-split1` appended. An existing `-split<N>` marker → each sub-milestone ID has that marker replaced with `-split<N+1>` (parent depth + 1). This is the only writer of the `-split<N>` convention; `/g-plan`'s Step 3c budget check reads it back to decide whether a further automatic split is offered, so the suffix must land on the ID regardless of which surface triggered this run.

For each ordering decision, narrate both the dependency reason and the version logic:
> **Why [Cluster A] before [Cluster B]:** [dependency / risk / value reason]
> **Version logic:** [Cluster A] is a [minor/patch/major] bump because [what it adds or fixes]. [Cluster B] follows as a [minor/patch] because [reason].

Flag blocking dependencies explicitly:
> "⚠ [Milestone B] cannot start until [Milestone A] ships [specific thing]."

Identify the MVP cut: the minimum set of milestones that delivers usable value. State which milestones are MVP and which are post-MVP, and why.

Present the full proposed sequence:

```
M1[-split<N>] — [Title]  [MVP / post-MVP]
     Goal: ...
     Scope: ...
     Depends on: —
     Version: v[x.y.z]  ([minor/patch/major] — [one-line reason])
     Risk: ...

M2[-split<N>] — [Title]  [MVP / post-MVP]
     Goal: ...
     Scope: ...
     Depends on: M1
     Version: v[x.y.z]  ([minor/patch/major] — [one-line reason])
     Risk: ...

...

Backlog (no milestone assigned yet):
     · [items that don't clearly belong to any milestone]
```

`[-split<N>]` — append per the split-lineage naming rule above only when this run is breaking an existing milestone into sub-milestones; omit it entirely for a normal milestone ID.

Ask the developer to confirm or adjust the version targets before proceeding.

State your sequencing assumptions:
> "I sequenced this assuming [2–3 key assumptions]. Tell me where I got it wrong."

Wait for the developer's response. Revise if needed. Do not proceed to Step 4 until the developer says the sequence is right.

## Step 3b — Premortem & re-prioritization (mandatory whenever a milestone is added or modified)

Any time this run **adds a new milestone or changes an existing one** — the Step 0 "adding to the plan" path, or an edit to a milestone's scope/version on an existing roadmap — run a premortem and re-prioritize *before* the buy-in gate. A new or changed milestone shifts risk and ordering across the whole roadmap; never just append it. (On a full from-scratch plan, the sequencing in Step 3 already covers this — run the premortem here once, then proceed.)

1. **Premortem each added/modified milestone.** Imagine it's later and this milestone went badly. For each, surface the top 3 failure scenarios — scope blow-up, hidden dependency, volatile/repeatedly-touched systems, unclear done condition — with a likelihood (low / med / high) and a one-line mitigation. Seed the scenarios from `/g-patterns` history (`g-docs/retros/`, `g-docs/todo-done.md`), any `dependency-auditor` findings from Step 0, and any existing `g-docs/forecasts/*.md` or `g-docs/blast-radius/*.md` for related work. Only premortem the changed milestones — leave stable ones alone.

2. **Re-prioritize the full sequence.** Given the premortem, re-evaluate ordering across **all non-completed** milestones (completed ✅ are frozen — never reorder history):
   - Does the new/changed milestone add a dependency that forces something earlier or later?
   - Does a high-likelihood failure scenario argue for de-risking it earlier (spike first) or deferring it until a prerequisite is solid?
   - Re-derive the MVP cut and the version targets if they shifted.
   Narrate every change — `> Moved M[X] before M[Y]: [premortem/dependency reason].` If nothing moves, say so explicitly — `> Re-prioritization: order unchanged — M[N] slots in at position [k] without disturbing the sequence.`

3. Present the re-prioritized sequence (same format as Step 3), each changed milestone carrying a short **Premortem** block (its top scenarios + mitigations). Then continue to the buy-in gate — the developer approves the *re-prioritized* roadmap, not just the addition.

4. **Cross-cutting propagation check (G-RULES §B).** If an added/modified milestone introduces a *cross-cutting primitive* — a shared concept other skills must respect (lanes/claims, the shared Roundtable, a new gate) — it is not done as an isolated component. Run `/g-blast-radius` to enumerate every skill, hook, and rule that must become aware of it, fold each touchpoint into the milestone's scope, and note the done condition is incomplete until the architecture-review gate confirms none was missed. If the milestone adds no cross-cutting primitive, say so in one line and skip.

## Step 4 — Buy-in gate

Present the complete roadmap in its final form:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROPOSED ROADMAP — [Project Name]
Current version: v[x.y.z]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M1 — [Title]  [MVP]  → v[x.y.z]
  Goal: [one line]
  Scope:
    · [item]
    · [item]
  Depends on: —

M2 — [Title]  [post-MVP]  → v[x.y.z]
  Goal: [one line]
  Scope:
    · [item]
  Depends on: M1

...

Backlog:
  · [item]

Version plan:  v[current] → v[M1] → v[M2] → ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask:
> "Ready to write g-docs/ROADMAP.md? Once written, this becomes the project's source of truth for milestone planning. Type **approve** to confirm, or tell me what to change."

Do not write any files until the developer types "approve" or an explicit equivalent ("yes", "looks good, write it", etc.).

If they request changes, make them and re-present. Loop until explicit approval.

## Step 5 — Write g-docs/ROADMAP.md

Only after explicit approval:

Write `g-docs/ROADMAP.md` with this structure:

```markdown
# Roadmap

## Milestones

### M1[-split<N>] — [Title]
**Status:** ⬜ Not started
**Version:** v[x.y.z]
**Goal:** [one line]
**Scope:**
- [item]
- [item]

**Depends on:** —

---

### M2[-split<N>] — [Title]
**Status:** ⬜ Not started
**Version:** v[x.y.z]
...

## Backlog
- [item]
```

`[-split<N>]` — same conditional as the Step 3 template above: append only when this run is breaking an existing, already-milestoned scope into sub-milestones; omit for a normal milestone ID.

If `g-docs/ROADMAP.md` already exists and contains completed milestones (✅), preserve them above the newly written milestones — never remove history.

Milestone status key: ⬜ Not started · 🔄 In progress · ✅ Complete

After writing, confirm:
> "g-docs/ROADMAP.md written. M1 is your next active milestone. When you're ready to start, run `/g-plan` with the M1 scope and I'll break it into tasks and a wave schedule."

## Rules
- Never write g-docs/ROADMAP.md before explicit developer approval in Step 4. "Looks good" or silence is not approval.
- Narrate reasoning at every cluster, sequence, and assumption — results without reasoning are just output.
- Surface assumptions explicitly at each phase so the developer can correct them early.
- Do not advance between phases without explicit developer sign-off.
- If the developer wants to skip a phase: explain briefly why it matters, then ask once more. One pushback only — if they still want to skip, respect it and note what was skipped.
- Every idea the developer mentions must end up somewhere — in a milestone scope or in the backlog. Nothing is silently dropped.
- Existing completed milestones (✅) are never modified — only append.
- Backlog items that don't clearly fit a milestone stay in the backlog section.
- This skill owns roadmap structure. `/g-plan` owns task breakdown within a single milestone.
- Adding or modifying a milestone is never a silent append — Step 3b (premortem + re-prioritization across all non-completed milestones) is mandatory before the buy-in gate whenever the roadmap changes.
- Every milestone must have a target version. Version planning is part of sequencing, not an afterthought — reason about it the same way you reason about dependencies.
- When splitting an existing milestone into sub-milestones, always apply the split-lineage naming rule in Step 3 — the `-split<N>` suffix on each sub-milestone ID is what lets `/g-plan`'s Step 3c budget check recognize an already-split milestone, on any invocation path, not just the one that triggered this run.
- Auto-trigger conditions (full tier only — Claude detects and initiates without being asked):
  - No `g-docs/ROADMAP.md` exists in the project
  - `g-docs/ROADMAP.md` exists but contains no active (🔄) or unstarted (⬜) milestones
  - The developer drops an explicit multi-feature dump or asks for a full re-plan. A single dropped idea is `/g-intake`'s trigger (G-RULES §B); it reaches this skill only when the developer picks the roadmap route from intake.

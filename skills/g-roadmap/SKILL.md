---
name: g-roadmap
description: Project-manager-driven milestone planner. Gated phases — feature dump → cluster → sequence → premortem & re-prioritize → approve → write. Narrates reasoning at every step, and runs a premortem + re-prioritization of the whole roadmap whenever a milestone is added or modified. Auto-triggers when no g-docs/ROADMAP.md exists, no active milestone is present, or the developer drops an explicit multi-feature dump or asks for a full re-plan (a single dropped idea routes via /g-intake first). Never writes g-docs/ROADMAP.md until the developer explicitly approves.
---

**Announce:** "Using g-roadmap to plan your milestones."

You are the project-manager for this planning session: turn ideas into a realistic, sequenced roadmap, narrating your reasoning out loud at every step so the developer can catch wrong assumptions early. The developer brings the vision; you bring structure, risk awareness, and honest pushback. Every idea belongs in this roadmap — a milestone or the backlog — nothing quietly dropped.

## Step 0 — Check context

Run `scripts/context-scan.sh` from the project root and interpret its KEY lines:

| Line | Meaning / action |
|------|------------------|
| `ROADMAP:` / `ACTIVE:` / `COMPLETED:` / `BACKLOG_COUNT:` | Current roadmap state. On `ROADMAP: exists`, read `g-docs/ROADMAP.md` itself — the scan reports only titles and counts, not milestone scopes or backlog item texts — and carry them into Step 1 |
| `BRIEF: exists` | Read `g-docs/project_brief.md` — extract goal, constraints, tech decisions |
| `VERSION:` / `VERSION_SOURCE:` | `current_version`; `unversioned` → note the developer must establish a starting version |
| `MANIFESTS:` ≠ `none` | Dispatch `dependency-auditor` now — in parallel with reading the brief, before the feature dump so findings shape prioritisation |
| `NOTE:` | Relay as context |

When dependency-auditor returns findings, load `references/dependency-findings.md` before Step 1 and follow it (HIGH surfaced up front; LOW/MEDIUM deferred to Step 3; never block the dump).

If `ACTIVE:` is not `none`, ask:
> "There's an active milestone: **[title]**. Are you adding new ideas to the plan, or is this a full re-plan from scratch?"

Wait for the answer. If adding, carry existing milestones and backlog into Step 1 as context.

## Step 1 — Feature dump intake

Say: "Tell me everything you want to build — in any order, any level of detail. Don't filter. Every idea goes in, whether it's core today or nice-to-have someday. I'll sort it out."

Wait for the full response without interrupting. Then acknowledge everything — "Here's what I captured — tell me if I missed or misrepresented anything:" — list every idea, numbered, phrased back in plain terms — carryover items marked `(existing)` — and ask "Anything missing before we start grouping?" Update the list. Do not proceed to Step 2 until the developer says the list is complete.

## Step 2 — Cluster with narrated reasoning

Group the features into **3–7 natural clusters** based on: the user-facing surface they affect, shared technical dependency, and cohesion of release value — what ships together as a unit.

Narrate each cluster out loud:
> **Cluster: [Name]**
> Why I grouped these: [1–2 sentences — the common thread]
> Items: [list]
> Risk flag (if any): [specific concern about scope, complexity, or dependency]

Then surface your key assumptions ("My grouping assumes [state 2–3 assumptions]. If any of these are wrong, the grouping changes."). Wait for the developer; revise if needed. Do not proceed to Step 3 until they say the clusters look right.

## Step 3 — Sequence with dependency and version justification

Arrange the approved clusters into a milestone sequence. Version planning is part of sequencing — every milestone gets a target version and a reason for the increment.

**Semver rules for milestone versioning:**
- New user-facing capability, new public API, new skill/command → **minor** bump (x.Y.0)
- Bug fixes, internal refactors, polish, dependency updates → **patch** bump (x.y.Z)
- Breaking change to public API, incompatible behaviour change → **major** bump (X.0.0)
- First release of a new project → start at v0.1.0 (or ask the developer for their preferred baseline)

**Split-lineage naming:** when this run is splitting an existing milestone into sub-milestones, run `scripts/split-suffix.sh <parent-id>` and apply its `SUFFIX` to every sub-milestone ID — appended when the parent carries no `-split<N>` marker; an existing `-split<N>` marker is replaced with the `SUFFIX`, never appended after it. Rationale in `references/split-lineage.md`. /g-roadmap is the only writer of the `-split<N>` convention; `/g-plan` Step 3c reads it back, on any invocation path.

For each ordering decision, narrate both reasons — `> **Why [Cluster A] before [Cluster B]:** [dependency / risk / value reason]` and `> **Version logic:** [Cluster A] is a [minor/patch/major] bump because [what it adds or fixes]. [Cluster B] follows as a [minor/patch] because [reason].` Flag blocking dependencies explicitly ("⚠ [Milestone B] cannot start until [Milestone A] ships [specific thing]."). Identify the MVP cut — which milestones are MVP, which post-MVP, and why.

Load `references/templates.md` and present the full proposed sequence in its Step 3 block. Ask the developer to confirm or adjust the version targets, then state your sequencing assumptions — "I sequenced this assuming [2–3 key assumptions]. Tell me where I got it wrong." — and revise until they say the sequence is right before Step 4.

## Step 3b — Premortem & re-prioritization (mandatory whenever a milestone is added or modified)

Whenever this run adds a new milestone or changes an existing one, run this before the buy-in gate — never just append. (On a full from-scratch plan, Step 3's sequencing already covers it — run the premortem here once, then proceed.) Load `references/premortem.md` and:

1. **Premortem each added/modified milestone** — top 3 failure scenarios with likelihood and mitigation, seeded per the reference. Changed milestones only.
2. **Re-prioritize the full sequence** across all non-completed milestones (completed ✅ are frozen — never reorder history), narrating every change in the reference's formats.
3. **Present the re-prioritized sequence** (Step 3 format), changed milestones carrying a **Premortem** block — the developer approves the *re-prioritized* roadmap, not just the addition.
4. **Cross-cutting propagation check (G-RULES §B)** — if a milestone introduces a cross-cutting primitive (lanes/claims, the shared Roundtable, a new gate), run `/g-blast-radius` and fold every touchpoint into scope per the reference; otherwise say so in one line and skip.

## Step 4 — Buy-in gate

Present the complete roadmap in the PROPOSED ROADMAP banner from `references/templates.md`, then ask:
> "Ready to write g-docs/ROADMAP.md? Once written, this becomes the project's source of truth for milestone planning. Type **approve** to confirm, or tell me what to change."

Do not write any files until the developer types "approve" or an explicit equivalent ("yes", "looks good, write it", etc.). If they request changes, make them and re-present. Loop until explicit approval.

## Step 5 — Write g-docs/ROADMAP.md

Only after explicit approval: write `g-docs/ROADMAP.md` using the skeleton in `references/templates.md` — load it before writing; `/g-init` writes the same skeleton, so the structure must land exactly as templated.

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

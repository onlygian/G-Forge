---
name: g-plan
description: Decompose the current request into atomic tasks and produce a parallel wave schedule. Runs task-decomposer then wave-planner. Use at the start of any multi-step implementation.
context: [task, sprint, architectural]
---

**Announce:** "Using g-plan to decompose and schedule the task."

You are driving the planning phase. Execute these steps in order.

For a trivial edit — one file, known location, no design decision — `/g-plan` is the wrong tool: switch to the `light` tier (`/g-tier light`) or edit inline, and return to `full` afterwards; the full pipeline on a trivial task costs an order of magnitude more than the edit itself.

## Step 0a — Identify the task

Determine what is being planned before asking anything else:

1. **Check the triggering message.** If the developer's message describes a task, feature, or bug fix — use that. No question needed.
2. **If the message is just `/g-plan` with no description:** Read `g-docs/ROADMAP.md` and `g-docs/todo.md` (if present) to find the active milestone and next task.
   - If one active item is clearly next: announce "Planning: [item]" and proceed — do not ask.
   - If multiple items are equally valid: ask one specific question: "Should I plan [X] or [Y]?" Never ask an open-ended "what do you want to plan?"
   - Any row carried from a prior plan, handoff, or milestone one-liner is probed against current source (git log, `g-docs/todo-done.md`, the file it names) before it re-enters the task list — "re-confirmed, no change" is a valid close; a row the evidence shows already closed or misdiagnosed is dropped or re-diagnosed, never carried unverified.
3. **Proceed.** Once the task is established, continue to Step 0. Do not ask the developer to confirm what is already clear from context.

## Step 0 — Tier 3 DoD prerequisite

Ask the developer: "Does this project have a QA panel or structured manual test UI?"

**If yes:** Ask which groups or areas are impacted by this milestone's changes. Then ask what passing looks like for each in-scope group. Compile a QA scope document at `g-docs/qa-scope/<milestone-slug>.md` using the schema in the **QA Scope Format** section below. This becomes the Tier 3 DoD for the milestone.

**If no:** Ask the developer to state the Tier 3 DoD for this milestone in one or two sentences. Record it in the plan header under `> Tier 3 DoD:`.

Do not proceed to Step 1 until a Tier 3 DoD is defined and written down.

## Step 1 — Challenge the request (feature requests only)

**Skip this step entirely if the request is a bug fix or a refactor of existing behaviour (not a new capability) — go straight to Step 2.**

Dispatch the `project-manager` agent with the full feature request as described by the developer.

Tell project-manager:
> "A developer wants to build the following: [feature request]. Apply your Feature Challenge gate. Ask the three challenge questions, wait for the developer's answers, then return one of: SCOPE ACCEPTED — [one-line summary], or SCOPE CONCERN — [reason] — DEVELOPER OVERRIDE."

Present project-manager's questions to the developer verbatim. Wait for the developer's answers. Pass the answers back to project-manager to get its verdict.

- **If verdict is SCOPE ACCEPTED:** proceed to Step 2.
- **If verdict is SCOPE CONCERN — DEVELOPER OVERRIDE:** note the concern in the plan header as a risk, then proceed to Step 2.

## Step 2 — Dispatch task-decomposer

Dispatch the `task-decomposer` agent. Provide:
- The full feature request or task description
- Any known file paths or constraints
- Any done conditions already specified
- Whether the project has a QA panel (from Step 0) — if yes, instruct task-decomposer that any task adding or changing user-facing surface must include "QA panel updated" as an explicit done condition
- An `output_file` path, following the `g-docs/agent-output/` convention: `g-docs/agent-output/g-plan/task-decomposer-[YYYY-MM-DD]-[request-slug].md`, where `[request-slug]` is a short slugified form of the task/feature description being planned right now — the same slugify convention Step 4a uses for the saved plan filename, minted here at dispatch time instead of deferred to Step 4a's approval-gated slug. The path is discriminated per run, not just per day, so two `/g-plan` runs on the same day for different requests never share a file. Create the `g-docs/agent-output/g-plan/` directory first if it does not exist. **Before dispatching, check whether a file already exists at this exact path** (a same-day retry reusing the same request-slug) — if so, delete it first, so a stale prior run's content can never be mistaken for this run's output.

Wait for the task list before proceeding. Do not proceed if task-decomposer returns any "Clarify:" items — resolve those with the developer first.

**Fallback if the return is empty or malformed:** task-decomposer's own Return format (its `DETAIL:` line) writes the full task list to the `output_file` path assigned above, using its own `Write` tool grant (scoped to that record path), before it ever emits the compact return block. If the final message comes back empty, truncated, or fails to parse as the expected `RESULT/TASKS/SUMMARY/DETAIL` block, do not assume recovery — read that `output_file` path directly (HQ assigned it when constructing the dispatch prompt above) and validate its content before using it: the file must (1) exist and be non-empty, (2) parse as a `## Task List` section carrying the `| # | Task | Files | Done condition |` table header, and (3) plausibly describe *this* request — cross-check at least one task's Files or Task text against a keyword from the request or a file path named in the dispatch prompt. Any failure of (1)–(3) — including a well-formed task list for a different request — is genuinely failed, never a recovery; do not proceed on mismatched content. Step 3's wave-planner input contract is unchanged either way — it receives the same task-list shape regardless of which path produced it.

## Step 2a — Dependency scan for planned additions

Scan the task list returned by task-decomposer for any task that explicitly mentions installing, adding, or integrating a new external package or library — e.g. "add Stripe SDK", "install redis-py", "integrate the OpenAI client", "add [package name] dependency".

If any such tasks are found, dispatch `dependency-auditor` **in parallel with Step 3** (wave-planner dispatch). Provide it the identified package names and the project stack context.

If dependency-auditor returns any HIGH severity findings for a planned new package:
- Add a `⚠ Dependency risk: [package] — [issue]` line to the plan header before the wave schedule
- The developer sees this in the Step 4 approval gate alongside the wave schedule and forecast
- If the developer approves despite the warning, record it as an accepted risk in the plan file header

MEDIUM and LOW findings are included in the plan header as notes — informational, never blocking.

If no tasks mention new packages, skip silently.

## Step 2b — Cross-cutting propagation scan (G-RULES §B)

Scan the task list for any task that touches a *cross-cutting primitive* — a shared concept other skills must respect (lanes/claims, the shared Table, a new gate or sentinel). If the work introduces or extends one, it is not done as an isolated wave: run `/g-blast-radius` to enumerate the skills, hooks, and rules that must become aware of it, and add the missing touchpoints to the task list (so wave-planner schedules them) before Step 3. Note any deferred touchpoint as carry-over in the plan header. If the task touches no cross-cutting primitive, skip silently.

## Step 3 — Dispatch wave-planner

Dispatch the `wave-planner` agent with the complete task list from task-decomposer. Provide:
- An `output_file` path, following the same `g-docs/agent-output/g-plan/` convention as Step 2, reusing the same `[request-slug]` minted there: `g-docs/agent-output/g-plan/wave-planner-[YYYY-MM-DD]-[request-slug].md`. The `g-docs/agent-output/g-plan/` directory already exists from Step 2's dispatch.

wave-planner is read-only (`tools: Read, Glob` — it holds no `Write` grant), so unlike task-decomposer it cannot write this file itself: its Return format returns the full wave schedule inline in its result block, and HQ writes that returned content to the `output_file` path using HQ's own `Write` tool once the schedule is confirmed well-formed.

Wait for the wave schedule before proceeding.

**Fallback if the return is empty or malformed:** there is no on-disk copy to recover from — wave-planner never held the tool to write one. If the final message comes back empty, truncated, or fails to parse as the expected `RESULT/WAVES/TASKS/SUMMARY` + `## Wave Schedule` block, this is a genuine failure, not a recovery case: report it and re-dispatch wave-planner with the same task-list input rather than proceeding on partial content.

## Step 3c — Context budget check

Estimate whether this plan fits within the remaining session context budget.

**Calculate estimated cost in exchanges:**

```
base              = 5    (plan/review infrastructure constant)
per wave          = 3    (dispatch + result collection)
per agent         = 2    (each agent slot across all waves)
per task          = 1    (file reads, edits, and tool calls per task)
per-task review   = 4    (exchanges charged per task for the review chain; derived below as the observed rounds-per-task rate × 4 exchanges-per-round, where a round is one dispatch + findings + fix + re-verify cycle — that 4-exchange round cost is a different number from the coefficient, which happens to also come out to 4)

estimated = 5 + (wave_count × 3) + (total_agent_slots × 2) + (task_count × 1) + (task_count × 4)
```

> **Review-chain term — basis and derivation, stated once:** `task_count` means the row count of the plan's *final* Tasks table, written by Step 4a — not task-decomposer's raw pre-collapse emission from Step 2 (the two can differ when a same-file serial chain is later collapsed into one task; see the task-decomposer Rules carve-out for same-file serial chains). wave-planner (Step 3) groups the finalized tasks into agent slots for the Wave Schedule; it does not rewrite the Tasks table itself — `wave_count` and `total_agent_slots` come from its schedule, `task_count` comes from the Tasks table that schedule is built against. Two primary-source pairs, re-derived here rather than copied from a prior review record: G-Forge's own Check-24 pass — 7 tasks in its final Tasks table (`g-docs/plans/check-24-injection-detector.md`, `## Tasks`) — took 4 HOLD rounds to reach MERGE READY (`g-docs/todo-done.md`, the "Pass report — 2026-07-28 — Check 24 injection-rule detector" pass report); the `ec9bf8a` lib-install-completeness pass — 5 tasks (`g-docs/todo-done.md`, the "2.5 bug sweep — slot 1" pass report) — took 9 review rounds, 6 code-lead + 3 doc-reviewer (same pass report). The two records are not measured on the same definition of "round": the Check-24 figure (4) counts only rounds that surfaced a defect (HOLD rounds), the lib-install figure (9) counts every review round regardless of outcome (7 of the 9 found a defect). Normalized to one definition consistently, they do not land on the shipped coefficient: read as defect-finding rounds only, Check-24 is 4/7 ≈ 0.57 and lib-install is 7/5 = 1.4, averaging ≈ 0.99 rounds/task (× 4 ≈ 3.9, floors to **3**); read as total review rounds, Check-24 is 5/7 ≈ 0.71 (the 4 HOLD rounds plus the closing MERGE READY round) and lib-install is 9/5 = 1.8, averaging ≈ 1.26 rounds/task (× 4 ≈ 5.0, rounds to **5**). The `4` used below is neither of those consistently-normalized figures — it is what the two records give on their own mismatched counts (HOLD-only for one, total for the other) and is carried forward unchanged this round rather than presented as a clean midpoint; a consistent basis would move it to 3 or 5, not settle at 4. A field report (`g-docs/field-reports/2026-08-10-keyline-francesco.md`, read 2026-08-12) independently confirms the same shape at a different scale: across its corpus, review chains have repeatedly cost 3–10x the implementation estimate (§2, `:56`). A separate figure from the same report — on the order of 20 review-agent dispatches to land one milestone's code and its own closing documentation — is that one milestone's own count, not a corpus-wide one (§1, `:36`), and is cited here only as that, never folded into the 3–10x figure. The term is keyed on `task_count`, not `wave_count`, deliberately: task count is conserved when a milestone is genuinely split into sub-milestones (the sum of the sub-milestones' task counts equals the parent's), so splitting does not shrink the *total* predicted review cost the way a wave-count-based term would — it only distributes the same total across smaller sessions, which is the point of splitting for budget reasons, not a way to make the underlying review work cheaper.

Use the wave schedule from Step 3 for `wave_count` and `total_agent_slots`; use Step 2's task list (as amended by Steps 2a/2b) for `task_count` — the plan's finalized Tasks table (Step 4a) is the concept this approximates, but it does not exist yet when Step 3c runs, so Step 2's list is what is actually read here, and the two are normally identical. wave-planner (Tools: Read, Glob) groups tasks into waves and agent slots — it cannot rewrite, merge, or drop a task, so it is not a backstop for a failed collapse: if task-decomposer fails to collapse a same-file serial chain per its Rules carve-out, that inflated count carries straight through to the Tasks table and into `task_count`, uncorrected.

**Re-derive the coefficient before using it.** Before applying the `per-task review` coefficient above, check `g-docs/todo-done.md` for pass reports newer than the two records its derivation cites; if three or more new task-count / review-round pairs exist, recompute the coefficient on one consistent round definition using the method the derivation note already states, update the number here, and cite the new pass reports as the basis. "Carried forward unchanged" is a one-round exception, never a standing state — the reset side of §A7 auto-calibrates from measured compactions and the estimate side must not lag it.

**Read remaining budget:**

Read the current depth from the prompt counter. The hooks key it by session id — `workflow-checkpoint.sh` and `session-start.sh` write `session-prompt-count.<session-id>` under the governing `.claude/` directory (local, else the resolved primary tree's — the same ADR-005 resolution the hooks use; in a linked worktree the counter lives in the primary's `.claude/`), and the bare `session-prompt-count` only on the no-session-id degrade path. Take the current session's keyed file if the session id is knowable; otherwise the **most recently modified** file matching `session-prompt-count*` there (never assume the bare name; a bare-name file may be stale litter from an old session).

Derive the red threshold the same way the hook does — never restate a literal: once a plan is executing the session is `implementation` mode, so `red = 45 − offset`, where `offset` is the integer in `.claude/context-threshold-offset` (0 if absent), floored at 25 (`hooks/workflow-checkpoint.sh` BASE_RED/FLOOR_RED). `remaining = red − current_depth`.

**Evaluate:**

- `estimated ≤ remaining × 1.0` → budget fine. Add `> Cost estimate: ~[N] exchanges` to the plan header and proceed to Step 3a.
- `estimated > remaining × 1.0` and `estimated ≤ remaining × 2.0` → tight fit. Add `> ⚠ Cost estimate: ~[N] exchanges (~[remaining] remaining — tight)` to the plan header. Warn the developer in Step 4 but proceed.
- `estimated > remaining × 2.0` → plan exceeds budget. Stop. Do not proceed to Step 3a.

> **Bands re-tuned for the review-chain term, checked against a real pass:** the prior 0.8/1.2 bands were set when `estimated` reflected implementation only (`tasks×1`, no review term). With `tasks×4` added, the marginal cost of one task rose 5x (1 → 1+4 = 5), so the old bands would hard-stop most non-trivial plans, including ones that ran fine. Worked example, G-Forge's own Check-24 pass — 7 tasks / 4 waves / 6 agent slots: `estimated` = 5 + 4×3 + 6×2 + 7×1 + 7×4 = 64. Its plan header recorded `~30 remaining` at the time (`g-docs/plans/check-24-injection-detector.md`, its `> Cost estimate:` header line), computed against the stale literal-40 red threshold this skill's own threshold derivation (above) has since replaced with `45 − offset`; recomputed under the corrected formula at the same depth, `remaining` ≈ 35. Under the old bands, 64 > 35 × 1.2 = 42 — hard stop, despite the pass reaching MERGE READY in the run it was planned in. Under the re-tuned bands, 35 × 1.0 = 35 < 64 ≤ 35 × 2.0 = 70 — tight fit, matching the "tight" the plan header already recorded under the old formula, not a hard stop. A materially larger plan still hard-stops at the same remaining budget (e.g. 20 tasks / 5 waves / 8 agents: `estimated` = 5 + 15 + 16 + 20 + 80 = 136 ≫ 70), so the gate still fires on genuinely oversized plans — it no longer fires on a routine one. The lower boundary's own headroom is intentionally gone in this re-tune — a plan estimated at exactly `remaining × 1.0` now proceeds with no warning — and the "tight" label at the upper bound spans a wide range, from just over budget up to 2× `remaining`; both are accepted consequences of pricing the review-chain term realistically, not oversights left uncorrected.

> **Split target — basis stated separately from the bands:** the split target is not one of the evaluate bands and is not derived from the same worked example; it answers a different question — how large a sub-milestone the split should produce, not whether the current plan fits. It carries its own headroom margin, below 1.0, because the split is performed by a `/g-roadmap` run inside the *current* session, and the first sub-milestone's own `/g-plan` re-run happens later at a strictly smaller `remaining` than `M` — session depth has advanced by the time it runs. The target is `floor(M × 0.8)`, reusing the 0.8 headroom the lower evaluate band carried before this round's re-tune, so a sub-milestone sized to the target still sits under the `× 1.0` "budget fine" boundary even after the budget it was sized against has shrunk — so long as it has not shrunk by more than the 20% margin the 0.8 multiplier provides.

**Split-depth check (run before presenting options):** determine the identifier to check for a prior split — the milestone ID being planned (from `g-docs/ROADMAP.md`) if one exists, else the slug of a plan being re-planned from a prior save at `g-docs/plans/<slug>.md`. For an ad-hoc `/g-plan` run with neither (no milestone, no prior save — Step 4a only mints a slug after approval), there is no identifier to check: **treat this as depth 0** by definition. When an identifier exists, grep it for the pattern `-split[0-9]+` (not end-anchored — a split suffix followed by further slug text, e.g. `M47-split1-auth`, still reads as split-depth ≥ 1). A match means this plan is already the product of one prior split — depth ≥ 1. No match (or no identifier) means depth 0.

**Present the budget-exceeded prompt.** One block, both depths — only the availability of option 1 and the presence of option 3 change, so option numbers never change meaning between a depth-0 and a depth-≥1 answer:

```
⚠ Context budget exceeded

  Estimated cost:   ~[N] exchanges
  Remaining budget: ~[M] exchanges  (derived red threshold [R] − current depth [C])
  Shortfall:        ~[N−M] exchanges

  Running this plan would push the session into red mid-execution,
  forcing an incomplete-wave handoff.
  [depth ≥ 1 only, appended:] This milestone is already a split
  product — a prior lineage re-split 3 levels deep from one original
  unit with no benefit (derived 2026-08-12 from a field report).

  Options:
  1. Split — invoke /g-roadmap to break this milestone into
     sub-milestones that each fit within ~[floor(M × 0.8)] exchanges.
     [depth ≥ 1 only:] — unavailable at this depth; see option 3.
  2. Proceed — accept the mid-plan handoff risk. Execution will pause
     at red and require a fresh session to resume incomplete waves.
  3. [depth ≥ 1 only:] Escalate to the developer for a manual
     re-scope — the plan's actual shape, not another mechanical
     split, is the likely fix at this depth.

  Which would you prefer?
```

Splitting cannot game this estimate down: the split target is evaluated with the identical five-term formula, and `task_count` is conserved across a genuine split (the sub-milestones' task counts sum to the parent's) — the split-depth cap above stops the same lineage from re-splitting a second time for the same reason.

**If the developer chooses option 1 — split (depth 0 only; unavailable at depth ≥ 1):**

Use Glob to find `skills/g-roadmap/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it. Run `/g-roadmap` with the following framing passed as context:

> "The current milestone task list is [task list]. The session context budget is ~[M] exchanges per sub-milestone. Split this milestone into sub-milestones where each sub-milestone's estimated cost (base 5 + waves×3 + agents×2 + tasks×1 + tasks×4) does not exceed [floor(M × 0.8)] exchanges. Name each sub-milestone ID/slug with a trailing `-split<N>` suffix (no existing suffix on the parent → `-split1`; parent already `-split<N>` → replace it with `-split<N+1>`) so a future Step 3c pass can detect that it is already a split product. Produce a revised g-docs/ROADMAP.md with the sub-milestones sequenced in dependency order."

After `/g-roadmap` completes, stop the current `/g-plan` run. Tell the developer: "g-docs/ROADMAP.md updated with sub-milestones. Run /g-plan on the first sub-milestone to begin."

**If the developer chooses option 2 — proceed (either depth):**

Add `> ⚠ Risk: estimated ~[N] exchanges exceeds session budget — mid-plan handoff likely` to the plan header. Proceed to Step 3d.

**If the developer chooses option 3 — manual re-scope (depth ≥ 1 only):** stop the current `/g-plan` run and hand back to the developer — do not invoke `/g-roadmap` automatically at this depth.

**If the developer answers "1" at depth ≥ 1** (where option 1 is printed but annotated unavailable): do not invoke `/g-roadmap`. Tell the developer split is withheld at this depth, and treat the answer as option 3 — hand back for a manual re-scope.

## Step 3d — Wave dependency validation

Before writing the forecast handoff, validate that the wave schedule is internally safe to execute. Run these three checks using Glob, Grep, and Read — do not dispatch an agent for this.

### Check 1 — Same-wave file conflicts

For each wave, compare the `Files in scope` lists across all tasks in that wave. If two tasks in the same wave declare the same file, they would run in parallel and write to the same file simultaneously.

Flag each collision:
```
⚠ Parallel write conflict — Wave [N]: [Task A] and [Task B] both scope [file]
```

For each collision, ask wave-planner to split the conflicting tasks into sequential waves. Do not proceed to Step 3a until wave-planner has revised the schedule and the conflict is resolved.

### Check 2 — Missing source files for mutation tasks

For each task whose description contains an action word that implies an existing file (`update`, `modify`, `extend`, `refactor`, `fix`, `edit`, `change`), use Glob to verify the scoped files exist on disk.

If a scoped file does not exist:

- **If an earlier wave in the schedule creates it** (task description contains `create`, `generate`, `scaffold`, `add`, `write`, or `init` for that filename) — ordering is correct, no action.
- **If no earlier wave creates it** — flag as a blocker:
  ```
  ✗ Missing source — [task name]: [file] does not exist and no prior wave creates it
  ```

Blockers must be resolved before proceeding. Present them to the developer with two options: (a) add a prerequisite task to the wave schedule, or (b) confirm the file will exist at execution time (developer override — recorded in plan header as accepted risk).

### Check 3 — Cross-wave output dependency ordering

For tasks that reference another task's output by name or file path in their description (e.g. "using the schema generated in the previous task", "after [task name] completes"), verify the referenced task is in an earlier wave. If it is in the same wave or a later wave, flag it:
```
⚠ Ordering risk — [task name] references output from [other task] but both are in Wave [N]
```

Surface ordering risks to wave-planner for a schedule revision. These are not hard blockers — if the developer is confident the tasks are independent, they may override.

### Validation summary

After all three checks, report inline:

```
Wave dependency check:
  ✓ No parallel write conflicts
  ✓ All source files present (or creation-ordered)
  ✓ No cross-wave ordering violations

  — or —

  ✗ [N] blocker(s) — listed above. Resolve before proceeding.
  ⚠ [M] warning(s) — listed above. Carried forward to approval gate.
```

Blockers halt the plan. Warnings are included in the Step 4 approval gate under a `### Dependency risks` line so the developer sees them before approving.

Once all blockers are resolved (either fixed or explicitly overridden), proceed to Step 3a.

## Step 3a — Write the pending-forecast handoff

Before invoking `/g-forecast`, write the in-memory task list and wave schedule to `g-docs/plans/.pending-forecast.md` using the same Plan File Format defined later in this skill. This is a temporary handoff file — `/g-forecast` Step 1 reads it preferentially when present, so the forecast targets *this* plan (which has not yet been approved or saved as the official `<slug>.md`) and not a stale older plan.

Delete `g-docs/plans/.pending-forecast.md` at the end of Step 4 — whether the developer approves, edits, or rejects the plan. It must never persist past the approval gate.

## Step 3b — Run `/g-forecast` for scope-realism and premortem

Use Glob to find `skills/g-forecast/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it, then follow its instructions. `/g-forecast` will pick up `g-docs/plans/.pending-forecast.md` per its Step 1 case 1.

The forecast returns: a complexity score (0–10), a risk band (Low / Moderate / Elevated / High) for the likelihood that ≥1 premortem scenario fires, and a ranked top-5 premortem of likely failure scenarios with mitigations. It is **advisory** — it never blocks the approval gate. Its job is to surface risk so the developer can decide whether to proceed, mitigate, or re-scope.

Carry the forecast summary forward into Step 4 so the developer sees it alongside the plan.

If `/g-forecast` returns High risk, surface this prominently in Step 4 and add a one-line recommendation that the developer consider re-scoping — but do not block. The developer's approval is still authoritative.

## Step 4 — Present plan and wait for approval

Present the full output to the developer:

```
## Plan: [feature name]

[task list table from task-decomposer]

[wave schedule from wave-planner]

### Budget

Context cost: ~[N] exchanges   Remaining: ~[M]   [✓ fits / ⚠ tight / from plan header]

### Forecast (advisory)

Complexity: [X/10]   Risk: [Low / Moderate / Elevated / High] — likelihood ≥1 premortem scenario fires

Top premortem scenarios:
  1. [scenario] — mitigation: [one line]
  2. [scenario] — mitigation: [one line]
  3. [scenario] — mitigation: [one line]

[if High risk] ⚠ This plan carries a High risk that ≥1 premortem scenario fires. Consider re-scoping before approval. (Advisory only — your approval is still authoritative.)

### Dependency risks

[omit this section if Step 3d found no warnings]
⚠ [warning text from Step 3d — one line per warning]

---
Ready to execute? Reply 'approved' to begin, or describe changes.
```

**Do not proceed without explicit developer approval.** If the developer requests changes, update the plan and re-present. Repeat until approved.

When the developer responds (approval, edit, or reject), delete `g-docs/plans/.pending-forecast.md` if it exists — the handoff file from Step 3a must never persist past this gate.

## Step 4a — Save approved plan to disk

Once the developer approves, immediately write the plan to `g-docs/plans/<feature-slug>.md` using the schema defined in the **Plan File Format** section below. Slugify the feature name for the filename (e.g. `user-auth-flow.md`). Create the `g-docs/plans/` directory if it does not exist. Do this before handing off to g-execute.

## Step 5 — On approval

Once the developer approves, use Glob to find `skills/g-execute/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it, then follow its instructions to run the waves.

## Plan File Format

All plans produced by this skill are saved to `g-docs/plans/<feature-slug>.md` immediately after developer approval (before execution begins). Use the feature name slugified as the filename (e.g. `user-auth-flow.md`).

### Schema

````markdown
# Plan: [Feature Name]

> Created: [date]

## Tasks

| # | Task | Scope | Done condition |
|---|------|-------|----------------|
| 1 | [task name] | [files/area] | [verifiable condition] |
| 2 | ... | ... | ... |

## Wave Schedule

### Wave 1
- Task 1 — [task name] (agent: feature-implementer)
- Task 2 — [task name] (agent: test-writer)

### Wave 2
- Task 3 — [task name] (agent: vue-implementer)

## Progress

| Wave | Status | Notes |
|------|--------|-------|
| 1 | pending | |
| 2 | pending | |
````

## QA Scope Format

Written to `g-docs/qa-scope/<milestone-slug>.md`. One file per milestone, compiled through conversation with the developer.

````markdown
# QA Scope: [Milestone Name]

> Updated: [date]
> Tier 3 DoD: all in-scope groups reach ✓ pass or ~ partial with no blocking fails

## In-Scope Groups

### [Group Name]
- What changed: [brief description of what this milestone touches in this group]
- Must pass: [specific behaviours that must reach ✓]
- Acceptable partial: [behaviours where ~ is OK for this milestone]

### [Group Name]
...

## Always-True (never regress regardless of milestone)
- [core flow that must always pass]
````

## Rules
- Never skip Step 0. No Tier 3 DoD defined = milestone not started.
- Never skip the approval gate.
- Never suggest implementation approaches — that is the executor's job.
- Wave execution always goes through g-execute — never inline, never via superpowers.
- If any agent returns BLOCKED during execution, stop and report to the developer before continuing.

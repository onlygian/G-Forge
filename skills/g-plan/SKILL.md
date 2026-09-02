---
name: g-plan
description: Decompose the current request into atomic tasks and produce a parallel wave schedule. Runs task-decomposer then wave-planner. Use at the start of any multi-step implementation.
context: [task, sprint, architectural]
---

**Announce:** "Using g-plan to decompose and schedule the task."

You drive the planning phase — execute these steps in order. A trivial edit (one file, known location, no design decision) doesn't belong here: `/g-tier light` or edit inline, return to `full` after. `scripts/` and `references/` sit beside this SKILL.md — Glob them inside `~/.claude/plugins/cache/g-forge/g-forge/skills/g-plan/` when needed.

## Step 0a — Identify the task

1. The triggering message wins — if it describes a task, use it; no question.
2. Bare `/g-plan`: read `g-docs/ROADMAP.md` + `g-docs/todo.md`. One clearly-next item → announce "Planning: [item]" and proceed; several → ask "Should I plan [X] or [Y]?", never open-ended. Rows carried from a prior plan, handoff, or milestone one-liner are probed against current source (git log, `g-docs/todo-done.md`, the named file) before re-entry — never carried unverified; evidence-closed rows drop or get re-diagnosed.
3. Never ask what is already clear from context.

## Step 0 — Tier 3 DoD prerequisite

Ask: "Does this project have a QA panel or structured manual test UI?" **Yes** → ask which groups this milestone impacts and what passing looks like for each; write `g-docs/qa-scope/<milestone-slug>.md` per the QA Scope Format in `references/plan-formats.md`. **No** → the developer states the Tier 3 DoD in one or two sentences; record it in the plan header under `> Tier 3 DoD:`. Do not proceed to Step 1 until a Tier 3 DoD is defined and written down.

## Step 1 — Challenge the request (feature requests only)

**Skip entirely for a bug fix or a refactor of existing behaviour — go straight to Step 2.** Otherwise dispatch `project-manager`:

> "A developer wants to build the following: [feature request]. Apply your Feature Challenge gate. Ask the three challenge questions, wait for the developer's answers, then return one of: SCOPE ACCEPTED — [one-line summary], or SCOPE CONCERN — [reason] — DEVELOPER OVERRIDE."

Relay its questions verbatim, pass back the answers, get the verdict. **SCOPE ACCEPTED** → Step 2. **SCOPE CONCERN — DEVELOPER OVERRIDE** → note the concern in the plan header as a risk, then Step 2.

## Step 2 — Dispatch task-decomposer

Run `scripts/prep-dispatch.sh "<short request description>"` — it mints output paths (slug: lowercase, hyphens — the same slug Step 4a uses for the plan filename) and deletes stale same-path files. Dispatch `task-decomposer` with:

- The full request, known file paths, constraints
- Done conditions already specified
- QA-panel status from Step 0 — if yes, tasks touching user-facing surface must include "QA panel updated" as an explicit done condition
- `output_file` = the printed `TD_FILE`

Wait for the task list; resolve any "Clarify:" items with the developer before proceeding. If the return is empty, truncated, or fails to parse as the `RESULT/TASKS/SUMMARY/DETAIL` block: run `scripts/validate-task-output.sh <TD_FILE>`, load `references/decomposer-fallback.md`, and follow it.

## Step 2a — Dependency scan for planned additions

If a task installs/adds/integrates a new external package, dispatch `dependency-auditor` **in parallel with Step 3** (package names + stack). HIGH → add `⚠ Dependency risk: [package] — [issue]` to the plan header (seen at the Step 4 gate; approval despite it = recorded accepted risk). MEDIUM/LOW → informational header notes, never blocking. None → skip silently.

## Step 2b — Cross-cutting propagation scan (G-RULES §B)

If a task introduces or extends a cross-cutting primitive (lanes/claims, the shared Roundtable, a new gate or sentinel), run `/g-blast-radius` and add the missing touchpoints to the task list before Step 3 (deferred ones noted as carry-over in the plan header). Otherwise skip silently.

## Step 3 — Dispatch wave-planner

Dispatch `wave-planner` with the complete task list; `output_file` = `WP_FILE` from Step 2. wave-planner is read-only (`Read`, `Glob` — no `Write`): it returns the schedule inline and HQ writes it to `WP_FILE` once well-formed. An empty/malformed return is a genuine failure with no on-disk copy — report and re-dispatch with the same input.

## Step 3c — Context budget check

Run `scripts/budget-check.sh --waves N --agents N --tasks N --id <milestone-id|plan-slug|''> --session <session-id|''>` — waves/agent slots from Step 3's schedule; tasks = the final Tasks-table row count (Step 2's list as amended by 2a/2b); id = ROADMAP milestone ID or re-planned plan slug, empty for ad-hoc (depth 0); session = the current session id when knowable (the hooks key the prompt counter by it — the script then reads this session's counter, never another's), empty otherwise (mtime fallback). Coefficient basis, worked examples, and the re-derivation duty: `references/budget-derivation.md` — the constants live in the script. Act on its lines, staleness first:

- `NEW_PASS_REPORTS:` 3 or more → the per-task-review coefficient is stale: load `references/budget-derivation.md`, follow its re-derivation duty, then re-run the script — before acting on the verdict.
- `VERDICT: fine` → add `> Cost estimate: ~[N] exchanges` to the plan header.
- `VERDICT: tight` → add `> ⚠ Cost estimate: ~[N] exchanges (~[remaining] remaining — tight)`; warn at Step 4 but proceed.
- `VERDICT: exceeded` → stop; load `references/budget-exceeded.md` and follow it.

## Step 3d — Wave dependency validation

Write the draft plan to `g-docs/plans/.pending-forecast.md` per the Plan File Format in `references/plan-formats.md`, then run `scripts/validate-waves.sh g-docs/plans/.pending-forecast.md` (Checks 1–2). `⚠ Parallel write conflict` → wave-planner splits the conflicting tasks into sequential waves; do not proceed until resolved. `✗ Missing source` → offer (a) add a prerequisite task, or (b) developer override — file will exist at execution time, recorded as accepted risk.

**Check 3 — cross-wave output ordering (model judgment):** for tasks referencing another task's output by name or file path, verify the referenced task is in an earlier wave; if not, flag `⚠ Ordering risk — [task name] references output from [other task] but both are in Wave [N]` and surface to wave-planner for revision — not a hard blocker; the developer may override if the tasks are independent.

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

Blockers halt the plan — before stopping, delete `g-docs/plans/.pending-forecast.md` so a later `/g-forecast` never picks up the invalid draft; warnings carry to the Step 4 gate under `### Dependency risks`.

## Step 3a — Pending-forecast handoff

The handoff file was written at the top of Step 3d so `/g-forecast` targets *this* plan. Delete `g-docs/plans/.pending-forecast.md` at the end of Step 4 — approve, edit, or reject — or at a Step 3d blocker halt; it never persists past the approval gate or a halted run.

## Step 3b — Run `/g-forecast` for scope-realism and premortem

Glob `skills/g-forecast/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/`, read it, follow it — it picks up `g-docs/plans/.pending-forecast.md` per its Step 1 case 1. The forecast is **advisory** — it never blocks the approval gate. Carry its summary into Step 4; on High risk, surface it prominently with a one-line re-scoping recommendation — the developer's approval is still authoritative.

## Step 4 — Present plan and wait for approval

Render the presentation template from `references/plan-formats.md`, ending `Ready to execute? Reply 'approved' to begin, or describe changes.` **Do not proceed without explicit developer approval** — on requested changes, update and re-present until approved. When the developer responds (approval, edit, or reject), delete `g-docs/plans/.pending-forecast.md` if it exists.

## Step 4a — Save approved plan to disk

On approval, immediately write the plan to `g-docs/plans/<feature-slug>.md` per the Plan File Format (feature name slugified, e.g. `user-auth-flow.md`; create the directory if missing) — before handing off to g-execute.

## Step 5 — On approval

Glob `skills/g-execute/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/`, read it, and follow its instructions to run the waves.

## Rules
- Never skip Step 0. No Tier 3 DoD defined = milestone not started.
- Never skip the approval gate.
- Never suggest implementation approaches — that is the executor's job.
- Wave execution always goes through g-execute — never inline, never via superpowers.
- If any agent returns BLOCKED during execution, stop and report to the developer before continuing.
- ADR-005 local-else-primary (owning statement): the governing .claude/ is the local tree's if it has one, else the resolved primary worktree's; in a linked worktree per-session counters live in the primary's .claude/. scripts/budget-check.sh implements this resolution.

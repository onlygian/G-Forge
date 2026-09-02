# g-plan formats — plan file, QA scope, and approval presentation

Load triggers: Step 0's QA branch (QA Scope Format), the Step 3d draft write and
Step 4a save (Plan File Format), and Step 4 (presentation template). The Progress
statuses and table headers below are parsed by g-execute Step 2, g-afk, and
g-forecast — every literal is byte-identical and must stay so.

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

Progress statuses are the closed set `pending` / `in progress` / `complete`.

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

## Step 4 presentation template

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

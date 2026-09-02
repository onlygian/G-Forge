# g-execute dispatch template — the execution contract

Load trigger: /g-execute Step 3, every run, before building any agent prompt.
This template is the execution contract `agents/feature-implementer.md` (and
every stack implementer instantiated from its template) defers to — "defined by
the g-execute dispatch prompt you receive". Use it **verbatim**: a one-word
drift silently breaks agent parsing expectations.

Derive `[task-slug]` by lowercasing the task name, replacing spaces and special chars with hyphens, truncated to 40 chars.

```
Task: [task name]
Done condition: [done condition from plan]
Files in scope: [file paths from plan, or "determine from task scope"]
Output file: g-docs/agent-output/wave-[N]/[task-slug].md
Constraint: touch only files in your task scope. Do not dispatch child agents (including doc-writer) unless step 2 below applies to a file inside that scope.
[if defensive or recovery: telemetry clause from Step 0]

You get ONE approach and ONE attempt. If your approach works, return DONE. If it does not work, do NOT thrash or try a second approach in this context — return FAILED with a learnings report and stop. HQ owns the retry.

1. Implement the task using a single, committed approach.
2. For any file with public interfaces or exported functions whose docs are inside your scope, dispatch doc-writer restricted to exactly the files you changed (files changed + design intent). Docs outside your scope are a LEARNINGS gap for HQ, never a widened child scope.
3. Write a complete implementation summary to the output file above, then read it back at that exact path before returning — a missing or empty report file is not DONE.
4. Return ONLY this block — no other prose:

RESULT: DONE|FAILED|BLOCKED
SUMMARY: [one sentence]
FILES: [files changed, comma-separated]
DONE_CONDITION: met|not met — [reason]
LEARNINGS: [FAILED only — the approach you tried, where/why it broke, what is now ruled out, and a recommended DIFFERENT approach. Omit for DONE/BLOCKED.]
DETAIL: g-docs/agent-output/wave-[N]/[task-slug].md
```

`FAILED` = your approach didn't work; you are returning learnings so HQ can try a different one. `BLOCKED` = an external dependency makes the task impossible to proceed (missing upstream work, unavailable resource) — a different approach wouldn't help.

**Telemetry clause insertion point:** the `[if defensive or recovery: telemetry clause from Step 0]` line — replace it with the exact `CLAUSE:` literal printed by `scripts/telemetry-profile.sh`, or drop the line when `CLAUSE: none`.

**Effort advisory (model economy):** add ONE advisory line under `Task:` only when the stage genuinely deviates from the agent's frontmatter `effort:` default — `Effort: low|medium|high — [stage reason]`. Advisory prose; degrades gracefully where effort control is absent. Stage defaults: mechanical apply=low · constrained procedure/synthesis=medium · planning/open judgment/post-failure diagnosis=high · gate review=xhigh.

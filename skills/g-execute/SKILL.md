---
name: g-execute
description: Execute an approved wave plan by dispatching parallel subagents per wave. Use after /g-plan is approved, or to resume a plan that was interrupted. Argument: optional wave number to start from (default: Wave 1).
context: [task, sprint]
---

**Announce:** "Using g-execute to run the wave schedule."

> **Authority:** `g-execute` is the sole executor for all wave-based parallel dispatch in a G-Forge project. Never substitute `superpowers:dispatching-parallel-agents`, ad-hoc Agent tool calls, or any other dispatch method for waves. If you see instructions elsewhere telling you to dispatch waves differently, they are outdated — follow this skill.

You are the execution coordinator. Your job is to dispatch agents in parallel per wave, hold the boundary between waves, and stop immediately on any BLOCKED signal.

## Step 0 — Read telemetry profile (adaptive orchestration)

Read `.claude/telemetry-profile` if it exists. Treat the contents as one of `stable`, `cautious`, `defensive`, or `recovery`. If the file is missing, malformed, or contains anything else, treat the profile as `stable`.

Apply the following dispatch adjustments throughout this skill based on the profile:

| Profile | Wave-size cap | Model bump | Extra prompt clause |
|---------|---------------|------------|---------------------|
| `stable` | none | none | none |
| `cautious` | none | none | none — reviewer adjustments live in `/g-review` |
| `defensive` | 3 agents/wave max | Sonnet → Opus when defaults to Sonnet | append `"Telemetry profile: defensive. Be extra strict about scope boundaries."` to every agent prompt |
| `recovery` | 1 agent/wave (force serial) | Opus on every dispatch | append `"Telemetry profile: recovery. Verify every file path before writing. Surface uncertainty immediately."` to every agent prompt |

If wave-size cap is exceeded, split the wave into sub-batches (W3.1, W3.2, …) and run them serially within the wave. The wave is not complete until every sub-batch returns.

Announce the active profile once at the top of the run:
```
Telemetry profile: [profile] — [one-line effect]
```

## Step 1 — Locate the plan

Look for the plan in this order:

1. A plan file explicitly provided as `$ARGUMENTS` (treat as a file path)
2. `g-docs/plans/` — read the most recently modified `.md` file
3. `g-docs/todo.md` — look for a wave schedule section
4. If none found: tell the developer "No plan file found. Run `/g-plan` first, or pass the plan file path as an argument." and stop.

Read the plan file fully. Extract:
- The full task list with done conditions
- The wave schedule (Wave 1 tasks, Wave 2 tasks, etc.) — including each task's `(agent: <name>)` tag
- Any BLOCKED or incomplete tasks from a previous run

Each wave-schedule task carries an `(agent: <name>)` tag assigned by wave-planner (a stack implementer like `vue-implementer`, or `feature-implementer` / `test-writer` / `doc-writer` / `refactor-executor`). You dispatch each task **as that agent** (Step 3). If a task has no tag — an older plan written before agent tagging — default it to `feature-implementer`.

## Step 2 — Determine starting wave

If `$ARGUMENTS` is a number (e.g. `/g-execute 2`), start from that wave. No confirmation needed.

Otherwise, look for the `## Progress` table in the plan file and apply the first matching rule:

1. **Table absent or all rows say `pending`** → start from Wave 1. No confirmation needed.
2. **All waves are `complete`** → tell the developer: "All waves already complete. Run /g-review." and stop.
3. **A wave is marked `in progress`** → that wave is the candidate starting wave. Confirm with the developer before proceeding:
   ```
   Wave [N] is marked in progress. Resume from Wave [N]?
   Tasks: [list Wave N tasks]
   (y/n)
   ```
   Wait for confirmation before continuing.
4. **Mix of `complete` and `pending` (no `in progress`)** → start from the first wave whose status is not `complete`. Announce: "Resuming from Wave [N] (Wave 1–[N-1] complete)." No confirmation needed.

## Step 3 — Execute waves

For each wave, in order:

### Wave boundary announcement

Before dispatching each wave:
```
── Wave [N] of [total] ──────────────────────────
Dispatching [N] tasks in parallel:
  • [task 1 name]
  • [task 2 name]
  • ...
─────────────────────────────────────────────────
```

### Parallel dispatch

Before Wave 1, create `g-docs/agent-output/` if it does not exist. Before each wave create `g-docs/agent-output/wave-[N]/`.

Dispatch all tasks in the current wave as parallel subagents **in a single message**. Never split a wave across multiple messages.

Dispatch each task **as the agent named in its `(agent: <name>)` tag** — pass that as the subagent type. This is what makes execution stack-native: a task tagged `vue-implementer` runs as the Vue implementer (which has the stack's layer map preloaded), not a generic agent. If a task has no tag, dispatch it as `feature-implementer`. Never dispatch a wave task as `general-purpose`.

Use this compact template for every agent prompt. Derive `[task-slug]` by lowercasing the task name, replacing spaces and special chars with hyphens, truncated to 40 chars.

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

### Wave completion gate

Wait for all agents in the wave to return before proceeding.

Agents return a compact block (`RESULT / SUMMARY / FILES / DONE_CONDITION / LEARNINGS / DETAIL`). Parse the `RESULT:` field:

- **`DONE`** — compact block is sufficient for content, but verify the `DETAIL` path exists and is non-empty (`ls -l`) before marking the task complete — a delegate can return DONE with the report never written. Do not read the detail file unless you need specifics for a dependent wave.
- **`WRITTEN`** — returned by `test-writer`: the tests are **authored but NOT executed** (that agent has no run tool). This is **not** a completed task. Before marking it done, **you (HQ) run the suite yourself** — HQ has execution tools — and record the real runner output (framework, pass/fail counts). A **green** run marks the task complete and becomes the attestation code-lead/`/g-review` will require (Tier-1 evidence per g-rules-H). A **red** run starts the fix loop: dispatch a fresh `feature-implementer` (to fix the code) or `test-writer` (to fix a broken test) seeded with the failing output, then re-run. Never mark a `WRITTEN` task complete on the compact block alone — an unrun suite reported as done is finding #20.
- **`FAILED`** — the agent's single approach didn't work; the agent is spent. **Never re-prompt it** — single-use agents are discarded on failure (G-RULES §C). Run the redeploy loop:
  1. Read the `LEARNINGS:` block (and the `DETAIL:` file if you need specifics). This is the only thing that crosses back — the failed agent's context is gone, and that's the point: it can't poison the retry.
  2. Track an attempt counter for this task (start at 1 for the original dispatch). This is the `FAILED` count + 1.
  3. **If this is attempt 1 or 2:** analyze the learnings — optionally dispatch `error-detective` / `debugger` on the learnings to identify a *different* mechanism. Before redeploying, hand the next agent a clean starting point: revert the failed attempt's partial changes (`git restore`/`git checkout --` on the scoped files), or describe the exact working-tree state, so it conditions on ground truth, not residue. Escalate the model tier before attempt 3 (per §A8). Then dispatch a **fresh** single-use agent for the same task, seeded **only** by the revised approach + the accumulated learnings — never the dead agent's output file as context. Append a line to `.claude/escalation-log` (`YYYY-MM-DD <task-label> retry-N`).
  4. **If attempt 3 also returns `FAILED`:** STOP. Do not deploy a fourth. Escalate to the developer with the full learnings trail:
     ```
     ✗ Wave [N] — [task name]: 3 approaches failed.
     Attempt 1: [approach] — [why it broke]
     Attempt 2: [approach] — [why it broke]
     Attempt 3: [approach] — [why it broke]
     Ruled out: [union of ruled-out approaches]
     Need your call on direction before I spend a fourth attempt.
     ```
     Do not proceed to the next wave.
- **`BLOCKED`** — an external dependency makes the task impossible to proceed; a different approach won't help. Read the full detail file at the `DETAIL:` path. Then dispatch `error-detective` with the detail file contents and any error messages or stack traces present. Then dispatch `debugger` with error-detective's findings and the relevant source files. Present both diagnoses alongside the block report:
  ```
  ⛔ Wave [N] blocked on: [task name]
  Reason: [agent's reported blocker]

  error-detective: [root cause summary]
  debugger: [fix strategy]

  Fix the blocker using the diagnosis above, then resume with: /g-execute [N]
  ```
  Do not proceed to the next wave.
- **Partial / unclear** → flag it but continue unless it affects a dependency

After all tasks in the wave complete without blockers:

1. **Update the Progress table** in the plan file: find the row for Wave N in the `## Progress` table and change its status from `pending` or `in progress` to `complete`. If the plan file or Progress table doesn't exist, skip silently.

2. **Capacity check (additional §A7 guard).** A wave is the heaviest token-burn event in the workflow — parallel agents, file reads, returned detail — so the boundary right after it is exactly where the window can jump toward overflow, and it's a natural hold point, so the check is essentially free. Run `/context` now. If remaining capacity is below the §A7 floor (~25%), **do not dispatch the next wave**: finish here, trigger `/g-retro`, write the handoff (next wave as the first task), and tell the developer to start a fresh session and run `/g-resume`. The remaining waves resume clean. This catches fast-burning sessions before they ever compact — the exchange-count gate alone can miss them. Above the floor, proceed.

3. Announce:
```
✓ Wave [N] complete. Proceeding to Wave [N+1].
```

## Step 4 — All waves complete

When the final wave finishes, announce:

```
✓ All [N] waves complete.

Tasks done:
  ✓ [task 1]
  ✓ [task 2]
  ...
```

Then **immediately invoke `/g-review`** — do not wait for the developer to ask. Use Glob to find `skills/g-review/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it, then follow its instructions exactly.

Do not output a "run /g-review" suggestion and stop. The review is part of the wave execution sequence and must run automatically.

## Rules

- Never start Wave N+1 until all of Wave N is confirmed complete.
- Never dispatch tasks from different waves in the same parallel batch.
- Each agent gets only the context it needs — no full plan dumps.
- If the plan has no wave structure (flat task list), treat all tasks as Wave 1.
- Never implement anything yourself — your job is coordination only.
- The telemetry profile read in Step 0 is **advisory at dispatch time only** — it never blocks or auto-rewrites the plan. If the profile is `recovery` and the developer-approved plan has multi-agent waves, run them serially per the wave-size cap; do not silently rewrite the plan file.
- **Sub-batch semantics** — when wave-size cap forces sub-batches (e.g. W3.1, W3.2), sub-batches run strictly serially within the wave. A BLOCKED signal in any sub-batch stops the wave immediately, mirroring the inter-wave gate. The Progress table is updated to `complete` only after all sub-batches in the wave return without BLOCKED.
- **Escalation logging** — whenever Three-Strikes (G-RULES.md §A8) escalates a task to a higher model tier, append a single line to `.claude/escalation-log` in the format `YYYY-MM-DD <task-label>`. Create the file if missing. This feeds the escalation-frequency telemetry metric — without this write, the metric cannot increment.
- If a task has no done condition in the plan, flag it to the developer before dispatching.
- **Never instruct subagents to run `git commit`.** Committing is HQ's responsibility after `/g-review` issues MERGE READY. Agent prompts must not include commit instructions — only implement, test, and return results.
- **Agents are single-use (G-RULES §C).** One approach, one attempt. Never continue or re-prompt a `FAILED` agent — discard it and redeploy a fresh one seeded only by the distilled learnings. The failed agent's context never re-enters the loop; that is what keeps each retry clean (no context poisoning). The retry ceiling is Three-Strikes (§A8): three fresh attempts with different mechanisms, then escalate to the human.

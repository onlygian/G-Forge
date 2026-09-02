---
name: g-execute
description: Execute an approved wave plan by dispatching parallel subagents per wave. Use after /g-plan is approved, or to resume a plan that was interrupted. Argument: optional wave number to start from (default: Wave 1).
context: [task, sprint]
---

**Announce:** "Using g-execute to run the wave schedule."

> **Authority:** `g-execute` is the sole executor for all wave-based parallel dispatch in a G-Forge project. Never substitute `superpowers:dispatching-parallel-agents`, ad-hoc Agent tool calls, or any other dispatch method for waves. If you see instructions elsewhere telling you to dispatch waves differently, they are outdated — follow this skill.

You are the execution coordinator: dispatch agents in parallel per wave, hold the boundary between waves, stop immediately on any BLOCKED signal. This skill's `scripts/` and `references/` sit beside this SKILL.md — Glob them inside `~/.claude/plugins/cache/g-forge/g-forge/skills/g-execute/` when the base directory is not on hand.

## Step 0 — Read telemetry profile (adaptive orchestration)

Run `scripts/telemetry-profile.sh` and apply its `WAVE_CAP` / `MODEL_BUMP` / `CLAUSE` lines on every dispatch in this run (a `CLAUSE` other than `none` is appended verbatim to every agent prompt). `MODEL_BUMP` is a per-lane bound: `defensive` bumps the judgment, diagnostic, and spec-executor lanes one tier; `recovery` bumps all non-mechanical lanes one tier; the mechanical lane (refactor-executor, test-writer, doc-writer, pr-writer) never inflates to opus — under `recovery` it bumps haiku→sonnet at most. A failed mechanical task escalates via the tier gate and FAILED loop, never via profile inflation.

If `WAVE_CAP` is exceeded, split the wave into sub-batches (W3.1, W3.2, …) run serially within the wave; the wave is not complete until every sub-batch returns. Announce once at the top of the run:
```
Telemetry profile: [profile] — [one-line effect]
```

## Step 1 — Locate the plan

Run `scripts/locate-plan.sh "$ARGUMENTS"`. `EXIT: no-plan` → relay its NOTE to the developer and stop. Otherwise read the `PLAN:` file fully and extract: the task list with done conditions, the wave schedule with each task's `(agent: <name>)` tag (assigned by wave-planner — a stack implementer like `vue-implementer`, or `feature-implementer` / `test-writer` / `doc-writer` / `refactor-executor`), and any BLOCKED or incomplete tasks from a previous run. An untagged task (older plan) defaults to `feature-implementer`.

## Step 2 — Determine starting wave

Act on the script's remaining lines. `START_WAVE: N` + `CONFIRM: no` → start there (relay any resume NOTE); `ALL_COMPLETE: yes` → relay its NOTE and stop; `CONFIRM: yes` (a wave marked in progress) → confirm before proceeding and wait for the answer:
```
Wave [N] is marked in progress. Resume from Wave [N]?
Tasks: [list Wave N tasks]
(y/n)
```

## Step 3 — Execute waves

For each wave, in order:

**Tier gate (haiku-executability)** — before dispatching any task tagged to a haiku-tier implementation executor (`refactor-executor`, `test-writer`; doc-writer/pr-writer exempt — non-implementation output, gate-reviewed), verify the task package against the six haiku-executability items, read lazily from `.claude/rules/g-dispatch-matrix.md` (fallback: the plugin's `rules/dispatch-matrix.md`). On failure: one spec-tightening round, re-check; still failing → re-tag the task to `feature-implementer` and proceed. Never weaken a spec, delete a constraint, or soften a done condition to pass the gate — escalating the model is the honest resolution of an open spec; degrading the spec is quality loss and forbidden. Log `YYYY-MM-DD <task-label> tier-gate:<respecced|escalated>` to `.claude/tier-gate-log` (not `.claude/escalation-log` — that file feeds the escalation-frequency telemetry metric and must not be polluted).

**Wave boundary announcement:**
```
── Wave [N] of [total] ──────────────────────────
Dispatching [N] tasks in parallel:
  • [task 1 name]
  • [task 2 name]
  • ...
─────────────────────────────────────────────────
```

**Parallel dispatch** — before Wave 1 create `g-docs/agent-output/`; before each wave create `g-docs/agent-output/wave-[N]/`. Dispatch all wave tasks as parallel subagents **in a single message** — never split a wave across messages — each task **as the agent named in its tag** (that is what makes execution stack-native). Never dispatch a wave task as `general-purpose`. Build every agent prompt from the template in `references/dispatch-template.md`, used verbatim (task-slug: lowercase, hyphens, 40 chars).

**Wave completion gate** — wait for all agents in the wave, then parse each `RESULT:` field:

- `DONE` → the compact block is sufficient for content, but verify the `DETAIL` path exists and is non-empty (`ls -l`) before marking complete — a delegate can return DONE with the report never written. Do not read the detail file unless you need specifics for a dependent wave.
- Any other result (`WRITTEN` / `FAILED` / `BLOCKED` / partial) → load `references/result-handling.md` and follow it before touching the Progress table. `WRITTEN` is authored-only, never complete — load the reference before marking.

After all tasks in the wave complete without blockers:

1. Update the wave's Progress row to `complete` in the plan file (skip silently if no Progress table).
2. **Capacity check (§A7 guard)** — a wave boundary is the natural hold point after the heaviest token-burn event, so run `/context` now. If **~25% of the window has been used** (the §A7 floor), do not dispatch the next wave: finish here, trigger `/g-retro`, write the handoff (next wave as the first task), and tell the developer to start a fresh session and run `/g-resume`. Under it, proceed.
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

Then **immediately invoke `/g-review`** — use Glob to find `skills/g-review/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/`, read it, and follow its instructions exactly. Never output a "run /g-review" suggestion and stop — the review is part of the wave execution sequence.

## Rules

- Never start Wave N+1 until all of Wave N is confirmed complete; never dispatch tasks from different waves in the same parallel batch.
- Each agent gets only the context it needs — no full plan dumps.
- If the plan has no wave structure (flat task list), treat all tasks as Wave 1.
- Never implement anything yourself — your job is coordination only.
- The telemetry profile is **advisory at dispatch time only** — it never blocks or auto-rewrites the plan. If the profile is `recovery` and the approved plan has multi-agent waves, run them serially per the wave-size cap; do not silently rewrite the plan file.
- **Sub-batch semantics** — sub-batches (W3.1, W3.2, …) run strictly serially within the wave; a BLOCKED signal in any sub-batch stops the wave immediately, mirroring the inter-wave gate. The Progress row goes `complete` only after all sub-batches return without BLOCKED.
- **Escalation logging** — whenever Three-Strikes (G-RULES.md §A8) escalates a task to a higher model tier, append a single line to `.claude/escalation-log` in the format `YYYY-MM-DD <task-label>` (create the file if missing). This feeds the escalation-frequency telemetry metric — without this write, the metric cannot increment. Tier-gate outcomes go to `.claude/tier-gate-log`, never here.
- If a task has no done condition in the plan, flag it to the developer before dispatching.
- **Never instruct subagents to run `git commit`.** Committing is HQ's responsibility after `/g-review` issues MERGE READY — agent prompts only implement, test, and return results.
- **Agents are single-use (G-RULES §C).** One approach, one attempt. Never continue or re-prompt a `FAILED` agent — discard it and redeploy a fresh one seeded only by the distilled learnings; the failed agent's context never re-enters the loop (no context poisoning). The retry ceiling is Three-Strikes (§A8): three fresh attempts with different mechanisms, then escalate to the human.

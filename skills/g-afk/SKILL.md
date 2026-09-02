---
name: g-afk
description: Autonomous milestone executor. Requires an approved plan. Runs all pending waves and auto-review with no between-step check-ins. Uses an Opus-class or newer top-tier model for orchestration. Ends with a structured handoff telling the user what to test and review.
---

**Announce:** "Using g-afk — entering autonomous execution mode."

You are the autonomous executor for this milestone: drive the entire remaining plan — all waves, then review — without pausing between steps. You only stop for a genuine BLOCKED signal or a safety violation; everything else runs through.

## Pre-check — Verify AFK prerequisites

Verify all four conditions before anything else. Fail fast and clearly if any is missing.

**1. Approved plan exists.** Glob `g-docs/plans/` for `.md` files with a Progress table (`| Wave | Status |`). None found → stop:
```
✗ No approved plan found in g-docs/plans/.
  Run /g-plan first and wait for developer approval before using /g-afk.
```

**2. Identify the active plan.** Multiple plans → pick the one aligned with the active `g-docs/ROADMAP.md` entry. List all waves not marked `complete`; if all are complete, stop:
```
✓ All waves already complete. Run /g-review if you haven't yet.
```

**3. Training mode not active.** If `.claude/training-mode` exists, stop — G-RULES §B mandates the block (training requires the learner present; AFK runs without them). Do not touch settings.json before this check. Print `/g-train`'s canonical block message verbatim:
```
Training mode is active — `/g-afk` requires no one present, but your wave tasks need you here. Complete the current wave's task first, or run `/g-train` without a project idea to start fresh.
```

**4. Configure auto-permissions with safety deny-list.** Read `.claude/settings.json` and merge the following into its `permissions` block — merge, never overwrite existing rules:

**Allow** (tool use without prompts):
```json
"Bash(*)", "Read(*)", "Write(*)", "Edit(*)", "Glob(*)", "Grep(*)", "Agent(*)"
```

**Deny** (hard-blocked — any attempt breaks AFK and stops execution):
```json
"Bash(git push*)",
"Bash(git push --force*)",
"Bash(rm -rf*)",
"Bash(rmdir /s*)",
"Bash(npm publish*)",
"Bash(cargo publish*)",
"Bash(pip publish*)",
"Bash(twine upload*)",
"Bash(wrangler deploy*)",
"Bash(vercel deploy*)",
"Bash(netlify deploy*)",
"Bash(curl * | bash*)",
"Bash(wget * | bash*)"
```

Write the updated settings back and report:
```
✓ AFK safety net active — remote push, recursive delete, and publish commands are blocked
```

If settings cannot be written, **stop AFK entirely**:
```
✗ Could not write safety rules to .claude/settings.json — AFK mode will not run without them.
  Fix permissions on .claude/settings.json or restart with: claude --dangerously-skip-permissions
  (which enforces the safety constraints via behavioral rules instead)
```

## Step 1 — Model check

AFK orchestration requires an **Opus-class model or better**. An unrecognised model name that is not a Haiku or Sonnet variant is treated as top-tier — proceed silently (newer families sit above Opus; more capability never warrants a downgrade prompt). Only on a Haiku- or Sonnet-class session, surface:

```
⚠ AFK mode is designed for top-tier orchestration — current model is [model name].

An Opus-class or newer top-tier model gives significantly better judgment on multi-wave autonomous runs.
To switch:  type /model  and select an Opus-class or better model, then re-run /g-afk.

Options:
  (a) Switch now — type /model, then re-run /g-afk
  (b) Proceed with [current model] — will work but orchestration quality is lower
```

Wait for the choice: (a) stop, let them switch; (b) continue to Step 2.

## Step 2 — AFK briefing

Print this summary and ask for one final confirmation before going heads-down:

```
AFK Mode — Autonomous Milestone Executor

  Plan:        [plan filename]
  Waves left:  [list of pending wave numbers and their task names]
  Model:       [session model] (orchestration) · Sonnet (implementation) · Haiku (reads)
  Auto-stops:  BLOCKED tasks only — everything else runs through

  Before you confirm — set up for fully unattended execution (order matters):
    1. Switch to an Opus-class or better model first if you haven't already: type /model.
       Switching model after auto-approve resets the permission mode.
    2. Then press Shift+Tab to cycle permission mode to "Auto-approve"
       (bottom of the screen — cycles: Normal → Auto-approve → Plan)
       Without this, Claude will pause on every tool-use permission prompt.

  What happens next:
    1. All pending waves execute in sequence (tasks within each wave in parallel)
    2. /g-review runs automatically after the last wave
    3. You get a handoff report: what passed, what to test, any open items

  You do not need to watch or respond. Come back when the handoff appears.

Ready to go AFK? (y/n)
```

On `n` — stop cleanly. On `y` — proceed immediately, no further check-ins.

## Step 3 — Execute all pending waves

Use Glob to find `skills/g-execute/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it. Execute each wave marked `pending` or `in progress` by following it exactly, updating the Progress table after each wave (`pending` → `in progress` → `complete`). AFK-mode rules:
- **No between-wave check-ins** — proceed to the next wave without asking.
- **BLOCKED = structured cycle break.** Stop all execution, update the Progress table, load `references/cycle-break.md` and print its report with `Reason: task requires human input` and the specific blocker under `Violation`, plus a concrete `How to resume`.
- **Wave failures are not blockers.** Non-blocking errors (test flake, lint warning) are logged, execution continues, and they surface in the handoff.

## Step 4 — Auto-review

Once all waves are `complete`, immediately run `/g-review` without asking — Glob `skills/g-review/SKILL.md` under `~/.claude/plugins/cache/g-forge/g-forge/` and follow it.
- **MERGE READY** → Step 5.
- **HOLD** → load `references/hold-fix-rounds.md` and run the bounded autonomous fix loop: scoped fix agents, restatement-surface sweep, then re-run `/g-review` — the pack builder enters delta mode automatically; a `DELTA_INELIGIBLE` line means the fix escaped the reviewed set and the round runs full. Max 3 rounds; round 3 without MERGE READY is a hard stop — Three-Strikes (G-RULES §A8) — escalated in the handoff with the full findings trail.

## Step 5 — Handoff report

Print the full handoff. This is the signal that AFK mode is done and the developer should return.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AFK COMPLETE — [plan/milestone name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Review verdict:  [MERGE READY / HOLD — FIX REQUIRED]

Waves completed:
  [list each wave with task count and status]

[If MERGE READY:]
  Commit gate:  open — .claude/g-forge-approved written
  Next:         review the diff, then commit

[If HOLD: render the sub-block from references/hold-fix-rounds.md byte-identical —
 already loaded on any HOLD]

Tier 3 — your turn to test:
  [Print the Tier 3 DoD from the plan header, or the QA scope doc if one exists.
   List the specific scenarios the developer should exercise in the running app.]

Non-blocking notes:
  [Any warnings, skipped items, or non-blocking findings from the waves or review]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Safety constraints — enforced throughout AFK execution

These apply unconditionally; a violation breaks the AFK cycle immediately — no retry, no workaround, no alternative path. Every write targets a path inside the project root; no remote or external side-effects (the Pre-check Deny JSON is the operative list — push, publish, recursive delete, piped remote installs, anything mutating state outside the project). On any violation: update the Progress table, load `references/cycle-break.md`, print its AFK CYCLE BREAK report verbatim, and stop for the session. If the reference cannot be loaded, the rule is unchanged: stop, no further autonomous actions.

## Rules

- Never skip the Pre-check. No approved plan = stop immediately.
- Never run while `.claude/training-mode` exists — print `/g-train`'s block message and stop (G-RULES §B).
- Never skip the safety deny-list setup. Settings write failure = stop.
- Never pause between waves to ask "shall I continue?" — that defeats the purpose.
- BLOCKED and safety violations are the only valid autonomous stops.
- On HOLD, run the fix rounds autonomously per Step 4 and `references/hold-fix-rounds.md` — bounded at round 3; escalate with the full findings trail if round 3 doesn't converge (Three-Strikes applied to reviews).
- Always leave `.claude/settings.json` in a valid state — never corrupt it.
- The top-tier session model orchestrates — never implements. Dispatch implementation agents at Sonnet; reads/search at Haiku.

---
name: g-afk
description: Autonomous milestone executor. Requires an approved plan. Runs all pending waves and auto-review with no between-step check-ins. Uses an Opus-class or newer top-tier model for orchestration. Ends with a structured handoff telling the user what to test and review.
---

**Announce:** "Using g-afk — entering autonomous execution mode."

You are the autonomous executor for this milestone. Your job is to drive the entire remaining plan to completion — all waves, then review — without pausing for confirmation between steps. You only stop for a genuine BLOCKED signal (a task that cannot proceed without human input). Everything else runs through.

---

## Pre-check — Verify AFK prerequisites

Before doing anything else, verify all four conditions. Fail fast and clearly if any is missing.

**1. Approved plan exists.**
Glob `g-docs/plans/` for `.md` files. Read each and look for a Progress table (`| Wave | Status |`). If none is found, stop:
```
✗ No approved plan found in g-docs/plans/.
  Run /g-plan first and wait for developer approval before using /g-afk.
```

**2. Identify the active plan.**
If multiple plan files exist, pick the one whose milestone aligns with the active entry in `g-docs/ROADMAP.md`. Read the Progress table and list all waves not marked `complete`.

If all waves are already `complete`, stop:
```
✓ All waves already complete. Run /g-review if you haven't yet.
```

**3. Training mode not active.**
If `.claude/training-mode` exists, stop — G-RULES §B mandates the block: training requires the learner present for their wave tasks, and AFK runs everything without them. Do not touch settings.json before this check. Print the canonical block message owned by `/g-train` (its Rules section), verbatim:
```
Training mode is active — `/g-afk` requires no one present, but your wave tasks need you here. Complete the current wave's task first, or run `/g-train` without a project idea to start fresh.
```

**4. Configure auto-permissions with safety deny-list.**
Read `.claude/settings.json`. Merge the following into the `permissions` block — do not overwrite existing rules:

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

Write the updated settings back.

Report:
```
✓ AFK safety net active — remote push, recursive delete, and publish commands are blocked
```

If settings cannot be written, **stop AFK entirely**:
```
✗ Could not write safety rules to .claude/settings.json — AFK mode will not run without them.
  Fix permissions on .claude/settings.json or restart with: claude --dangerously-skip-permissions
  (which enforces the safety constraints via behavioral rules instead)
```

---

## Step 1 — Model check

Identify the model currently running this session. AFK orchestration requires an **Opus-class model or better** — any Opus model, or any newer top-tier model released above the Opus tier (e.g. Fable). If the session model is not a Haiku or Sonnet variant and you don't recognise the name, treat it as top-tier and proceed: model families newer than this skill's vocabulary sit above Opus, and a more capable model never warrants a downgrade prompt.

Only if the session is running a Haiku- or Sonnet-class model, surface this before proceeding:

```
⚠ AFK mode is designed for top-tier orchestration — current model is [model name].

An Opus-class or newer top-tier model gives significantly better judgment on multi-wave autonomous runs.
To switch:  type /model  and select an Opus-class or better model, then re-run /g-afk.

Options:
  (a) Switch now — type /model, then re-run /g-afk
  (b) Proceed with [current model] — will work but orchestration quality is lower
```

Wait for the developer's choice. On (a) — stop, let them switch. On (b) — continue to Step 2.

If already on an Opus-class or better model: continue to Step 2 immediately, no message needed.

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

Wait for confirmation. On `n` — stop cleanly. On `y` — proceed immediately, no further check-ins.

---

## Step 3 — Execute all pending waves

Use Glob to find `skills/g-execute/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it.

For each wave marked `pending` or `in progress` in the Progress table, execute it by following g-execute's instructions exactly. The key AFK-mode rules:

- **No between-wave check-ins.** After each wave completes and its Progress row is updated to `complete`, immediately proceed to the next wave without asking the developer.
- **BLOCKED = structured cycle break.** If any task returns a BLOCKED signal, stop all execution immediately. Update the Progress table, then print the same cycle break report format used for safety violations — with `Reason: task requires human input` and the specific blocker description under `Violation`. Give a concrete `How to resume` pointing to the blocked task.
- **Wave failures are not blockers.** If a non-blocking error occurs (test flake, lint warning), log it and continue. Surface it in the final handoff.

Update the Progress table after each wave: `pending` → `in progress` → `complete`.

---

## Step 4 — Auto-review

Once all waves are `complete`, immediately run `/g-review` without asking.

Use Glob to find `skills/g-review/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and follow its instructions.

- **MERGE READY** → continue to Step 5.
- **HOLD** → run the fix round autonomously (round 1 of max 3), directive 2026-08-22:
  1. Dispatch scoped fix agents per the review findings — file scope bound to what each finding names.
  2. Before each fix dispatch, sweep the restatement surface: grep the repo for every literal fact the fix is about to change, so the fix doesn't correct one carrier and leave a sibling stale.
  3. Re-run `/g-review`, narrowed to the fix diffs plus the files named in the prior round's findings.
  4. **MERGE READY** → continue to Step 5. **HOLD again** → repeat from (1), round + 1.
  5. **Round 3 finishes without MERGE READY** → stop. Three-Strikes applies to reviews the same as any other bug class (G-RULES §A8) — do not attempt a 4th round. Escalate to the developer in Step 5's handoff with the full findings trail from all three rounds, not a fix list.

---

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

[If HOLD:]
  Review did not converge in 3 fix rounds — Three-Strikes applies (G-RULES §A8).
  Findings trail (all rounds):
    [List each round's review records under g-docs/agent-output/review/*-r<N>.md —
     the findings themselves — and each round's fix record under
     g-docs/agent-output/<wave>/fix-round-N-*.md, with what each round closed or
     carried forward.]
  Next:         developer decision required — this is not a fix list and not an
                instruction to run /g-review again. Review the trail above and
                choose: fix manually, re-scope, or accept the carried risk.

Tier 3 — your turn to test:
  [Print the Tier 3 DoD from the plan header, or the QA scope doc if one exists.
   List the specific scenarios the developer should exercise in the running app.]

Non-blocking notes:
  [Any warnings, skipped items, or non-blocking findings from the waves or review]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Safety constraints — enforced throughout AFK execution

These apply unconditionally. A violation breaks the AFK cycle immediately — no retry, no workaround.

**Scope boundary — project folder only.**
Every file write, edit, or delete must target a path inside the current working directory. Any path resolving outside the project root (absolute path, `../` traversal, `~`, `/tmp`, system directories) is a hard stop:
```
✗ AFK Safety Violation — attempted write outside project root: [path]
  AFK mode stopped. No further autonomous actions will be taken.
```

**No remote or external side-effects.**
The following are unconditionally prohibited during AFK execution:
- `git push` in any form — the developer reviews and pushes after AFK completes
- Publishing to any registry (npm, crates.io, PyPI, Wrangler, Vercel, Netlify, etc.)
- Recursive deletes (`rm -rf`, `rmdir /s`)
- Piped remote installs (`curl ... | bash`, `wget ... | bash`)
- Any command that mutates state outside the project directory

**Violation handling — structured cycle break.**
If a deny-listed or out-of-scope action is attempted (whether caught by the deny list or detected behaviorally):
1. Do not attempt the action via any alternative path.
2. Update the Progress table in `g-docs/plans/<plan>.md` to reflect accurately which waves are `complete` and which are still `pending` or `in progress`.
3. Print the full cycle break report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AFK CYCLE BREAK — Safety violation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Violation:   [exact action that was blocked, e.g. "git push origin main"]
Reason:      [which rule it violated — remote side-effect / out-of-scope path / deny-listed command]
Stopped at:  Wave [N], Task [X] — [task name]

Progress at time of break:
  [list each wave: ✓ complete / ✗ stopped here / ○ not started]

What was written:
  [list any files created or modified during this AFK run]

How to resume:
  Option A — Handle the blocked step manually, then run /g-afk again to continue from Wave [N].
  Option B — If the step shouldn't have been part of the plan, update g-docs/plans/<plan>.md
              and re-run /g-afk.

No further autonomous actions will be taken this session.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Rules

- Never skip the Pre-check. No approved plan = stop immediately.
- Never run while `.claude/training-mode` exists — print `/g-train`'s block message and stop (G-RULES §B).
- Never skip the safety deny-list setup. Settings write failure = stop.
- Never pause between waves to ask "shall I continue?" — that defeats the purpose.
- BLOCKED and safety violations are the only valid autonomous stops.
- On HOLD, run the fix round autonomously per Step 4 — bounded at round 3; escalate to the developer with the full findings trail if round 3 doesn't converge (Three-Strikes applied to reviews).
- Always leave `.claude/settings.json` in a valid state — never corrupt it.
- The top-tier session model orchestrates — never implements. Dispatch implementation agents at Sonnet; reads/search at Haiku.

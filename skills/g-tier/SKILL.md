---
name: g-tier
description: Switch the G-Forge integration tier between `full` (default — all hooks fire, all workflows auto-trigger), `balanced` (state hooks only, no auto-triggers, commit gate still on), and `light` (workflow-checkpoint only, commit gate off — opt-out mode). Writes `.claude/integration-tier`.
---

**Announce:** "Using g-tier to read or change the integration tier."

You manage the project's integration tier — how much of G-Forge fires automatically vs. waits for the developer to invoke it.

## Step 1 — Resolve intent

Inspect `$ARGUMENTS`:

1. **Empty** — read `.claude/integration-tier`. If absent, treat as `full`. Print a status block (Step 5 format) and stop without writing. **Do not proceed to Step 2.**
2. **One of `full` / `balanced` / `light`** — proceed to Step 2 with that value.
3. **Anything else** — print:
   ```
   ✗ Unknown tier '[arg]'. Valid: full, balanced, light.
   ```
   Stop.

## Step 2 — Confirm destructive switches

If the requested tier is `light`, the commit gate gets disabled. Prompt:

```
⚠ Switching to `light` disables the commit gate.

  You'll be able to `git commit` without /g-review's approval sentinel.
  The full skill catalog stays installed and invocable — G-Forge just
  stops blocking commits.

  This is the opt-out mode. Common reasons to choose it:
    · Throwaway / experimental branches
    · Solo work where the workflow discipline is more friction than value
    · Existing project being audited, not extended

  Confirm switch to `light`? (y/n)
```

Wait for the developer's answer. On `n`, stop and leave the tier unchanged. On `y`, continue to Step 3.

For `full` and `balanced`, no confirmation needed — those are non-destructive.

## Step 3 — Apply the switch

Create `.claude/` if missing. Write the tier name as a single bare word followed by a newline to `.claude/integration-tier`. Overwrite any existing content.

## Step 4 — Read the active voice profile

Read `.claude/voice-profile` if it exists; treat absent as `dev`. The Step 5 confirmation message is rendered according to the profile:

- `dev`: one-line confirmation (e.g. `Tier: balanced — auto-triggers off, commit gate on`).
- `mid`: two-line confirmation with a brief context sentence.
- `eli5`: three to five plain-language sentences explaining what just changed.

## Step 5 — Status block

Print a structured status block. Format depends on whether this was a read (Step 1 case 1) or a switch (Steps 2–4):

**Read mode:**
```
G-Forge tier status
  Active tier:  [full / balanced / light]
  Hooks:        [which hooks fire under the active tier — derived from g-docs/integration-tiers.md, never recalled]
  Auto-trigger: [yes / partial / no]
  Commit gate:  [on / off]
  Tier file:    .claude/integration-tier ([present / absent — using default])

  To switch:  /g-tier full   |   /g-tier balanced   |   /g-tier light
```

**Switch mode:**
```
✓ Switched to [tier].
  [rendering of "what changed" per active voice profile]

  Next hook output will reflect the new tier on your next prompt.
```

## Rules

- Never write to `.claude/integration-tier` without an explicit `$ARGUMENTS` matching one of the three valid values.
- `light` always requires confirmation — never silently switch.
- The skill modifies one file only: `.claude/integration-tier`. Do not touch hook scripts, settings.json, or other state.
- Honor the active voice profile (`.claude/voice-profile`) in the confirmation message. Never override the voice — even an `eli5` user gets the same factual switch, just rendered conversationally.
- If `.claude/` cannot be written to, report:
  ```
  ✗ Could not write to .claude/integration-tier. Check directory permissions.
  ```
  and exit without claiming success.
- This skill is **always available** regardless of the active tier — even at `light`, the developer must be able to switch back to `full` or `balanced` without re-installing.

# Integration Tiers

G-Forge can be configured to be more or less present in your project. The same toolkit ships in every install — the **tier** controls how much of it fires automatically vs. waiting for you to invoke it.

The active tier is stored in `.claude/integration-tier` as a single bare word: `full`, `balanced`, or `light`. Absent file is equivalent to `full` (backward compatibility — every project before M15 ran at `full`).

Switch tiers any time with `/g-tier full|balanced|light`. The change is local to the project and takes effect on the next prompt.

---

## `full` — the default

All hooks fire. Every workflow auto-triggers per the rules. Telemetry, forecast, blast-radius, and identity flow continuously. Reviewers spawn aggressively under defensive/recovery profiles.

**What auto-triggers:**
- `/g-plan` on any non-trivial task (≥3 files, new feature, layer-boundary change, unclear bug, public API change)
- `/g-execute` after plan approval
- `/g-review` when implementation completes or developer signals merge intent
- `/g-forecast` inside `/g-plan` Step 3b
- `/g-retro` after `/g-review` issues MERGE READY
- `/g-doctor` every other milestone close
- `workflow-checkpoint.sh` reports Branch, Active, Review, Health, Tier on every prompt

**Hook output (every prompt):**
```
[G-Forge Workflow Checkpoint]
  Branch: feat/foo
  Active: M3 — Auth refactor · 🚧 In progress
  Review: not yet approved — run /g-review before merging
  Health: ✓ clean
  Tier:   full
```

**Best for:** active feature development on a project where you want the rails on. The default for `/g-init`.

---

## `balanced` — informational, not directive

Hooks still report state — but they never auto-trigger workflows. Skills exist and are invocable; you decide when. The commit gate is still active (you can't accidentally commit without `/g-review`), but `/g-plan` and `/g-execute` only run when you call them.

**What still auto-triggers:**
- Commit gate (`.claude/g-forge-approved` required for any git commit)
- `workflow-checkpoint.sh` reports state on every prompt
- `/g-review` Step 0 still reads the telemetry profile
- `/g-execute` Step 0 still reads the telemetry profile

**What does NOT auto-trigger:**
- `/g-plan`, `/g-execute`, `/g-review` — developer must invoke them
- `/g-forecast` inside `/g-plan` — opt-in via a developer prompt
- `/g-retro` after MERGE READY — developer chooses to run it
- `/g-doctor` cadence — developer runs it on demand

**Hook output adds tier:**
```
[G-Forge Workflow Checkpoint]
  Branch: feat/foo
  Active: M3 — Auth refactor · 🚧 In progress
  Review: not yet approved — run /g-review when ready
  Health: ✓ clean
  Tier:   balanced — no auto-triggers; invoke skills manually
```

**Best for:** experienced developers who want the toolkit available but resent the rails. Common after the project stabilises and the developer has internalised the workflow.

---

## `light` — workflow-checkpoint only

The most minimal mode. The only hook that fires is `workflow-checkpoint.sh`, and even it limits itself to the Branch line. The commit gate is **off** — you can `git commit` without an approval sentinel. The full skill catalog is still installed and invocable, but G-Forge stays silent until you call it.

**What auto-triggers:**
- `workflow-checkpoint.sh` reports Branch only, plus the active tier line
- Nothing else

**What does NOT auto-trigger:**
- Commit gate is disabled — no sentinel check, no commit blocking
- No workflow auto-trigger of any kind
- No telemetry-driven model bumps or reviewer scaling (the profile is read but never applied)

**Hook output:**
```
[G-Forge Workflow Checkpoint]
  Branch: feat/foo
  Tier:   light — manual mode; commit gate off
```

**Best for:** solo experimental work, throwaway branches, or projects where the workflow discipline is more friction than value. The opt-out tier.

For a trivial edit — one file, known location, no design decision — `/g-plan` is the wrong tool: switch to the `light` tier (`/g-tier light`) or edit inline, and return to `full` afterwards; the full pipeline on a trivial task costs an order of magnitude more than the edit itself.

⚠ **Warning when switching to `light`:** `/g-tier light` prompts for confirmation because it disables the commit gate. This is intentional — bypassing the gate accidentally is the #1 reason to wish you hadn't.

---

## How hooks honor the tier

`hooks/workflow-checkpoint.sh` reads `.claude/integration-tier` at the start of every invocation and branches on the value. The Health line, the Listen-mode line, and the update-available line are emitted only on `full`; only the Branch + Tier line is emitted on `light`.

`hooks/check-commit.sh` reads `.claude/integration-tier` and exits 0 immediately if the value is `light` — the commit gate is off.

The skills (`/g-plan`, `/g-execute`, `/g-review`, etc.) don't read the tier themselves. The tier governs **whether they auto-fire**, not how they behave once running. A `/g-plan` you invoke manually under `balanced` behaves identically to one auto-triggered under `full`.

## Switching tiers

```
/g-tier              # show current tier
/g-tier full         # switch to full (default)
/g-tier balanced     # switch to balanced
/g-tier light        # switch to light (prompts for confirmation)
```

The switch is recorded in the current session's voice output: "Switched to balanced. Commit gate is still on; auto-triggers are off."

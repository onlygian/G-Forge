---
name: g-telemetry
description: Compute the 8 reliability metrics defined in g-docs/telemetry-metrics.md, derive a health profile (stable / cautious / defensive / recovery), and write it to .claude/telemetry-profile for adaptive orchestration in /g-execute and /g-review. Read-only on history; never modifies retros, forecasts, or git state.
context: [sprint, institutional, architectural]
---

**Announce:** "Using g-telemetry to compute reliability metrics and derive the project health profile."

You are running a reliability-assessment pass: read accumulated session history, compute 8 metrics, classify the project's current health profile, and persist that profile so downstream skills can adapt.

## Step 1 — Gather inputs

Read in parallel:

- All files in `g-docs/retros/` — for hallucination, review-catch, spec-deviation, retry-dependency signals, and the escalation fallback when `.claude/escalation-log` is absent
- `git log --oneline -200` via Bash — for regression and rework frequency, and for the escalation-frequency denominator
- `git log --stat -30` via Bash — for token-efficiency proxy (diff size)
- `.claude/escalation-log` if it exists — primary source for escalation count (one line per Three-Strikes event)
- `.claude/review-holds` if it exists — running HOLD counter; folds into rework rate per the spec
- `g-docs/telemetry-metrics.md` — the metric definitions (treat as authoritative spec)

Each metric uses the window described in its spec entry; do not assume one global window. The 200-commit history is the default for git-based metrics; if branch history is shorter, use what is available.

If retro count < 3 AND total commit count < 30, this is a bootstrapping project: skip computation, write `stable` to `.claude/telemetry-profile`, and report `cold-start — telemetry deferred until corpus accumulates`.

## Step 2 — Apply sentinel filter

Discard retro bullets matching the same sentinel filter used by `/g-patterns` and `/g-forecast`: `None recorded.`, `None.`, `(none)`, empty bullets. These never contribute to metrics.

## Step 3 — Compute each metric per g-docs/telemetry-metrics.md

Compute exactly what the spec file describes, in the order it lists them: hallucination rate, review catch rate, regression frequency, rework rate, spec deviation, escalation frequency, token efficiency, retry dependency.

For each metric, record:
- The numeric value (rounded to integer percentage)
- Whether it is `✓ in range` or `⚠ out of range` per the spec's range column
- The source artifacts that fed the calculation (filenames or git refs)

If a metric's source is empty (e.g. zero retros for retro-sourced metrics), record `n/a — insufficient data` and do not flag as ⚠.

## Step 4 — Derive health profile

Apply the ratio-based derivation defined in `g-docs/telemetry-metrics.md` — Health profile derivation:

```
computable = count of metrics whose status is ✓ or ⚠ (excludes n/a)
warn_ratio = ⚠ count / max(computable, 1)
```

| Profile | Trigger |
|---------|---------|
| `stable` | `warn_ratio == 0` |
| `cautious` | `0 < warn_ratio ≤ 0.25` |
| `defensive` | `0.25 < warn_ratio ≤ 0.50` |
| `recovery` | `warn_ratio > 0.50` |

Floor: if `computable < 3`, force `stable` regardless of ratio — too few signals to classify reliably.

If the derived profile is `stable`, also reset `.claude/review-holds` to `0` (write the single character `0` and a newline). This drops accumulated HOLDs that are no longer representative.

## Step 5 — Persist the profile

Write the chosen profile name as a single line to `.claude/telemetry-profile`. Overwrite any existing content. Create `.claude/` if it does not exist.

## Step 5b — Compute agent coverage

The 19 G-Forge agents are: `task-decomposer`, `wave-planner`, `spec-writer`, `code-reviewer`, `security-auditor`, `architecture-enforcer`, `performance-auditor`, `debugger`, `error-detective`, `project-manager`, `review-orchestrator`, `code-lead`, `test-writer`, `doc-writer`, `doc-reviewer`, `pr-writer`, `refactor-executor`, `dependency-auditor`, `feature-implementer`. (Per-project `<stack>-implementer` agents installed by `/g-specialize` are not counted here.)

Read all files in `g-docs/retros/` (up to the 10 most recent by filename date, or all if fewer). For each agent name, count how many retro files mention it at least once (case-insensitive, whole-word match).

Classify each agent:
- **never** — 0 mentions across all retros read
- **rarely** — mentioned in only 1 retro
- **used** — mentioned in 2 or more retros

Write `.claude/telemetry-coverage` with this format (bare text, no JSON):

```
never:dependency-auditor,performance-auditor
rarely:doc-writer
```

Omit a line entirely if the list for that category is empty. If all agents are `used`, write an empty file.

Also append a coverage section to the `g-docs/telemetry/YYYY-MM-DD.md` snapshot (taking the first free numeric suffix — `-2`, `-3`, … in numeric order — if a snapshot for today already exists; never silently overwrite a same-day run):

````markdown
## Agent coverage (last [N] retros)

| Agent | Retros mentioning it | Status |
|-------|---------------------|--------|
| task-decomposer | [N] | used / rarely / never |
| wave-planner | [N] | ... |
| spec-writer | [N] | ... |
| code-reviewer | [N] | ... |
| security-auditor | [N] | ... |
| architecture-enforcer | [N] | ... |
| performance-auditor | [N] | ... |
| debugger | [N] | ... |
| error-detective | [N] | ... |
| project-manager | [N] | ... |
| review-orchestrator | [N] | ... |
| code-lead | [N] | ... |
| test-writer | [N] | ... |
| doc-writer | [N] | ... |
| pr-writer | [N] | ... |
| refactor-executor | [N] | ... |
| dependency-auditor | [N] | ... |

**Never used:** [comma-separated list, or "none"]
**Rarely used:** [comma-separated list, or "none"]
````

## Step 6 — Print summary

Print this block exactly:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
G-FORGE TELEMETRY — [YYYY-MM-DD]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Profile: [stable / cautious / defensive / recovery]   ⚠ [N] of 8 metrics out of range

  1. Hallucination     [X%]   [✓ / ⚠ / n/a]
  2. Review catch      [X%]   [...]
  3. Regression        [X%]   [...]
  4. Rework            [X%]   [...]
  5. Spec deviation    [X%]   [...]
  6. Escalation        [X%]   [...]
  7. Token efficiency  [X/100][...]
  8. Retry dependency  [X%]   [...]

Effect on adaptive orchestration:
  [list the behavioural changes that apply to the chosen profile per g-docs/telemetry-metrics.md — e.g. for cautious: "/g-review will add one extra reviewer on next dispatch"]

Coverage: [N] of 19 agents used · never: [list or "none"] · rarely: [list or "none"]
  (workflow-checkpoint will surface suggestions for never-used agents once per day)

Snapshot written: g-docs/telemetry/[YYYY-MM-DD].md   (or [YYYY-MM-DD]-N.md on a same-day collision)
Profile persisted: .claude/telemetry-profile
Coverage persisted: .claude/telemetry-coverage

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Rules
- This skill is **read-only on historical artifacts** — never edit retros, forecasts, git history, or g-docs/todo-done.md.
- Always write the profile to `.claude/telemetry-profile` as a single bare word (no JSON, no newlines beyond trailing newline) — downstream skills parse this line directly.
- Always apply the same `None recorded.` sentinel filter as `/g-patterns` and `/g-forecast` — telemetry metrics never count empty signals.
- On a thin corpus, **never compute** — write `stable` and report `cold-start`. Forcing computation on insufficient data produces noise that triggers spurious model bumps.
- The 8 metric definitions live in `g-docs/telemetry-metrics.md`. If the spec changes, this skill follows the spec — do not duplicate the formulas inline.
- The `recovery` profile is the strongest signal — when computing it, double-check that ≥5 metrics are genuinely ⚠ and not artefacts of a thin corpus. If in doubt, downgrade to `defensive` and note the borderline in the snapshot Notes section.

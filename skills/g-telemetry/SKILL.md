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

**Empty means empty by the spec's own mechanism — never fill the gap by reading.** A retro-sourced metric is computed **only** from the literal match the spec defines for it (`g-docs/telemetry-metrics.md`, each metric's Source line). Run that match. If it returns zero hits, the metric is `n/a — insufficient data`, full stop: do **not** substitute a semantic reading of retro prose, do not infer a value from narrative that describes the same kind of event in different words, and do not carry a number over from a prior snapshot. A number reached by interpretation is not a measurement, and this table is consumed as measurements.

Why this rule is explicit: a 2026-08-28 adopter field report (`g-docs/field-reports/2026-08-28-g-sharp-telemetry.md`) records a run that reported all eight metrics as computed — including `20% hallucination` and `80% retry dependency` — on a corpus where every one of the spec's literal tokens matched **zero** files. The numbers were reached by reading the prose. The project then ran three weeks at an escalated review posture on the strength of them. The snapshot's own Notes flagged the doubt, but `.claude/telemetry-profile` carries one word and no caveats, so nothing reached the consumer.

**Measurement vacuum.** After computing all eight, count the computable ones (`✓` or `⚠`; `n/a` excluded). If `computable < 5`, the run is a **measurement vacuum**, not a health verdict: apply the forced-`stable` floor in Step 4 and state the vacuum in the Step 5 summary block, naming which metrics were `n/a` and why. A profile derived from a minority of the metrics is a floor, not an assessment, and must be reported as one.

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

Floor: if `computable < 5`, force `stable` regardless of ratio, and report the run as a **measurement vacuum** per Step 3 — too few signals to classify reliably. The forced `stable` is a floor, not an assessment; the Step 5 summary must say so and name the `n/a` metrics. *(Raised from `computable < 3` on 2026-08-28 — the old floor let a run with three git-derived metrics and five `n/a` present itself as a health verdict.)*

**Never write `.claude/review-holds`.** This skill is read-only on that counter — it folds the value into rework rate and nothing more. `/g-review` owns both the increment and the decrement (`g-docs/telemetry-metrics.md`, metric 4 counter policy).

*(Retired 2026-08-28: this step previously reset the counter to `0` on a `stable` profile. That was the write half of a latch — the counter only grew, growth forced a ⚠ on rework rate, a ⚠ made `stable` unreachable, and unreachable `stable` meant the reset never fired. Measured on this repo when it was found (2026-08-29): `fix_after_feat` 7 + `review_holds` 34 = 41, over 30 `feat:` commits — a 137% rework rate against a 20% threshold. Reported at `g-docs/field-reports/2026-08-28-g-sharp-telemetry.md` §2.)*

## Step 5 — Persist the profile

Write the chosen profile name as a single line to `.claude/telemetry-profile`. Overwrite any existing content. Create `.claude/` if it does not exist.

## Step 5b — Compute agent coverage

**Derive the agent roster from disk — never from a list typed here (ADR-013 rule 1).** Glob `agents/*.md` in the plugin source and take each file's basename without the extension; that set is the roster, however many it contains. Per-project `<stack>-implementer` agents installed by `/g-specialize` live in `.claude/agents/` and are **not** part of this set. *(Rewritten 2026-08-28: this step used to hand-type "The 19 G-Forge agents are: …" and then render a coverage table that listed only 17 of them — `doc-reviewer` and `feature-implementer` were missing, so two agents could never be reported as `never` used, which is precisely the blind spot this metric exists to surface. Deriving removes the count and the table from the set of things that can drift.)*

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
| [one row per agent in the derived roster, in `agents/*.md` glob order] | [N] | used / rarely / never |

Emit **one row per agent in the derived roster** — every agent, including any added since this file was last edited. Do not transcribe a row list from this template; the template shows the row shape, not the roster.

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
  [list the behavioural changes that apply to the chosen profile per g-docs/telemetry-metrics.md — e.g. for cautious: "/g-review announces the profile and passes it to code-lead, which scales its own scrutiny — no extra reviewer is dispatched as shipped"; for defensive/recovery, list the /g-execute effects (wave cap, model tier, prompt clause) — the /g-review fan-out effects are not wired as shipped, per the stamp under the spec's profile table]

Coverage: [N] of [M] agents used · never: [list or "none"] · rarely: [list or "none"]
  ([M] is the size of the roster derived in Step 5b — never a number typed from this template)
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

---
name: g-align
description: Brief-deviation check. Compares the project's actual trajectory (ROADMAP progress, recent commits, the observer journal) against the original g-docs/project_brief.md — goals, non-goals, MVP, tech decisions — and reports whether the work is still serving the brief. Advisory, never blocks. Auto-runs at milestone close; nudged periodically between milestones.
context: [sprint, architectural, institutional]
---

**Announce:** "Using g-align to check progress against the brief."

Roadmaps drift. A project that ships milestone after milestone can still walk away from the thing it set out to build — scope creeps in sideways, original goals get quietly deferred, the stack diverges from what was decided. Nobody notices because every individual milestone looked reasonable. This skill is the periodic re-grounding: it holds the **current trajectory** against the **original brief** and tells the developer, honestly, where they've drifted.

It is **advisory**. It never blocks a commit, a plan, or a milestone. Its only output is a report and a verdict.

## Step 1 — Load the brief (the anchor)

Read `g-docs/project_brief.md`. Extract:
- **What this builds** — the one-paragraph thesis.
- **Goals** — the measurable goals list.
- **Non-goals** — what was explicitly declared out of scope.
- **MVP** — the MVP feature set and done condition.
- **Roadmap** — the brief's original milestone table (`Milestone | Features | Rationale`).
- **Tech decisions** — the component → choice table.
- **Success metrics**.

If `g-docs/project_brief.md` does not exist, stop with one line: `No g-docs/project_brief.md — nothing to align against. Run /g-kickoff or /g-onboard to establish a brief first.` Do not fabricate an anchor.

## Step 2 — Observe the actual trajectory

Read in parallel:
- `g-docs/ROADMAP.md` — every milestone with status (✅ Complete · 🔄 In progress · ⬜ Not started) and its scope.
- `git log --oneline -40` via Bash — what has actually been built recently.
- The observer journal — `.claude/journal/*.jsonl`, last ~5 days — for the texture of recent work (commits, reverts, destructive flags, test cadence).
- The current manifest version (`.claude-plugin/plugin.json`, `package.json`, `pyproject.toml`, or `Cargo.toml`).
- `CHANGELOG.md` (last ~30 lines) if present — shipped-feature record.

## Step 3 — Compute deviation across four axes

For each axis, decide ALIGNED / DRIFTING and cite specific evidence. Never assert drift without naming the milestone, commit, or scope item that shows it.

1. **Goal service** — Is completed and in-progress work traceable to a stated Goal? List any Goal with no milestone or recent work advancing it (**neglected goal**). List any substantial body of work (a whole milestone) that maps to no Goal (**unanchored work**).
2. **Scope creep** — Is anything being built that the brief listed as a **Non-goal**, or that is nowhere in the brief's Goals/MVP/Roadmap? Name it and the milestone/commit it entered through.
3. **MVP integrity** — If the MVP is not yet shipped: is recent work advancing the MVP, or has the project moved on to post-MVP features while MVP done-conditions remain open? (Premature scope expansion is the most common real drift.)
4. **Tech-decision drift** — Do dependencies/commits show a stack choice that contradicts the brief's Tech-decisions table (e.g. brief says Postgres, commits add MongoDB) without a recorded override in `## Decisions and overrides`? Name the contradiction.

## Step 4 — Verdict and report

Compose an overall verdict:
- **ALIGNED** — no axis is drifting, or only cosmetic divergence with a recorded rationale.
- **DRIFTING** — one or more axes diverge from the brief without a recorded decision. Not a failure — a flag.

Write the report to `g-docs/alignment/YYYY-MM-DD-<milestone-or-slug>.md` (create `g-docs/alignment/` if needed; use the active milestone id as the slug, else `adhoc`; if that exact path already exists from an earlier run today, append the first free numeric suffix — `-2`, `-3`, … in numeric order — never overwrite a same-day report):

```markdown
# Alignment check — [YYYY-MM-DD] — [milestone or "ad-hoc"]

**Verdict:** ALIGNED | DRIFTING
**Brief dated:** [Created date from g-docs/project_brief.md]
**Version:** [current manifest version]

## Goal service
- [✓ / ⚠] [goal] — [evidence: milestone/commit advancing it, or "no work advancing this"]

## Scope creep
- [✓ none] or [⚠ <item> — entered via <milestone/commit>, brief lists it as <non-goal / not present>]

## MVP integrity
[one line: MVP shipped? if not, is recent work advancing it or bypassing it]

## Tech-decision drift
- [✓ none] or [⚠ brief: <choice> vs actual: <choice> — no recorded override]

## Recommendation
[1–3 sentences. If DRIFTING: the single most important realignment — e.g. "Finish MVP auth (M1 done-condition open) before M3 analytics," or "Record the Mongo decision as an override in the brief, or revert to Postgres." If ALIGNED: state that plainly and stop.]
```

## Step 5 — Surface

Print the verdict and the Recommendation verbatim, then the report path:

```
Alignment: [ALIGNED | DRIFTING]
[Recommendation line(s)]

Report: g-docs/alignment/YYYY-MM-DD-<slug>.md
```

If DRIFTING and the recommendation is to add/defer/record something, offer — do not perform:
> "Want me to (a) open /g-roadmap to re-sequence, (b) record the override in g-docs/project_brief.md via /g-brief, or (c) leave it as a flagged note? (a/b/c)"

Act only on the developer's choice. Touch the brief or roadmap **only** with explicit approval.

## Step 6 — Stamp

Write the current UTC date to `.claude/last-align` (used by the workflow-checkpoint nudge to pace between-milestone reminders). Overwrite any existing value.

## Rules
- Advisory only. Never write `.claude/g-forge-approved`, never block a commit, plan, or milestone close.
- Every drift claim must cite a milestone, commit, scope item, or dependency — no vibes.
- Never modify `g-docs/project_brief.md` or `g-docs/ROADMAP.md` from inside this skill without explicit developer approval (Step 5). This skill reports; the developer decides.
- A recorded override (in the brief's `## Decisions and overrides`) neutralizes the corresponding drift — divergence the developer already chose is not drift.
- If the brief is missing, stop in Step 1 — do not invent an anchor.
- Auto-trigger conditions (full tier only):
  - At milestone close — invoked by `/g-review`'s milestone close swarm.
  - When `workflow-checkpoint.sh` surfaces the between-milestone alignment nudge (≥7 days since `.claude/last-align`).

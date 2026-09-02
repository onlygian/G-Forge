# g-roadmap Step 3b — premortem elaborations

Load whenever Step 3b fires (a milestone was added or modified). The trigger rule and the four actions live in the SKILL.md core; this file carries the taxonomy, seeding sources, and narration formats.

## Scenario taxonomy

For each added/modified milestone, imagine it's later and the milestone went badly. Surface the top 3 failure scenarios — scope blow-up, hidden dependency, volatile/repeatedly-touched systems, unclear done condition — with a likelihood (low / med / high) and a one-line mitigation. Only premortem the changed milestones — leave stable ones alone.

## Seeding sources

Seed the scenarios from `/g-patterns` history (`g-docs/retros/`, `g-docs/todo-done.md`), any `dependency-auditor` findings from Step 0, and any existing `g-docs/forecasts/*.md` or `g-docs/blast-radius/*.md` for related work.

## Re-prioritization narration formats

Narrate every change — `> Moved M[X] before M[Y]: [premortem/dependency reason].` If nothing moves, say so explicitly — `> Re-prioritization: order unchanged — M[N] slots in at position [k] without disturbing the sequence.`

When re-prioritizing, ask of the full non-completed sequence:
- Does the new/changed milestone add a dependency that forces something earlier or later?
- Does a high-likelihood failure scenario argue for de-risking it earlier (spike first) or deferring it until a prerequisite is solid?
- Re-derive the MVP cut and the version targets if they shifted.

Present the re-prioritized sequence (same format as Step 3), each changed milestone carrying a short **Premortem** block (its top scenarios + mitigations).

## Cross-cutting propagation check (G-RULES §B)

A *cross-cutting primitive* is a shared concept other skills must respect — lanes/claims, the shared Roundtable, a new gate. If an added/modified milestone introduces one, it is not done as an isolated component: run `/g-blast-radius` to enumerate every skill, hook, and rule that must become aware of it, fold each touchpoint into the milestone's scope, and note the done condition is incomplete until the architecture-review gate confirms none was missed. If the milestone adds no cross-cutting primitive, say so in one line and skip.

# ADR file template (Step 6) — byte-identical structure

The Status and Reversibility closed sets and the section headings below are read by `/g-resume`, code-reviewer, and humans — nothing may drift.

```markdown
# ADR-[NNN]: [Title]

**Date:** [YYYY-MM-DD]
**Status:** [Accepted | Proposed | Deprecated | Superseded by ADR-NNN]
**Reversibility:** [two-way door (reversible) | one-way door (hard to reverse) — set in Step 8]
**Context:** [project name or area this applies to]

## Context

[Q1 — situation, problem, constraints. 2–5 sentences.]

## Decision

[Q2 — what was chosen, specifically. 1–3 sentences.]

## Alternatives considered

| Option | Why rejected |
|--------|-------------|
| [from the promoted draft] | [reason] |

## Consequences

**Easier:** [what this enables]
**Harder / constrained:** [what this makes more difficult or rules out]
**Follow-up decisions:** [any decisions this creates or defers — or "none"]
**Risks:** [known risks — or "none identified"]

## Rejected Alternatives

| Alternative | Why rejected |
|-------------|--------------|
| [name] | [deciding factor] |

## Assumptions That Held

- [assumption and its fragility]

## Constraints That Drove This Decision

- [constraint: time/team/compliance/cost/etc.]
```

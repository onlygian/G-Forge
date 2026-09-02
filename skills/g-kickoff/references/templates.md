# g-kickoff Steps 6 and 7 — output templates

Load at Step 6, before rendering the proposal, and keep for Step 7. Both templates are contracts: the brief's section headings are read by /g-align (`## Decisions and overrides`), /g-intake (Goals / Non-goals / MVP / Roadmap / Tech decisions), /g-brief, and /g-onboard — render them byte-identical.

## Step 6 — Kickoff Proposal template

```
## Kickoff Proposal — [Project Name]

### MVP
What ships first and proves the core value:
- [Feature 1] — [why it's in MVP]
- [Feature 2] — [why it's in MVP]

**MVP done condition:** [specific, observable thing that means MVP is working]

### Path to feature-complete
| Milestone | Features | Why this order |
|-----------|----------|----------------|
| M1 — MVP | [list] | Validates core value before investing further |
| M2 — [name] | [list] | [dependency or user feedback reason] |
| M3 — [name] | [list] | [dependency or user feedback reason] |

### Tech decisions
| Component | Choice | Rationale | Risk | Code-lead note |
|-----------|--------|-----------|------|----------------|
| [e.g. Frontend] | [e.g. Vue 3 + Pinia] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Backend] | [e.g. FastAPI] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Auth] | [e.g. Supabase Auth] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Database] | [e.g. Postgres via Supabase] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Deployment] | [e.g. Vercel + Railway] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |

### Honest notes
[List any features or stack choices that were challenged and why — e.g.:]
- [Feature X] moved to M2: premature without knowing if MVP gets traction
- [Stack choice Y]: noted risk — [concern]; developer confirmed intentional

### Open questions
- [Unresolved decision that affects scope, stack, or sequencing]
```

## Step 7 — g-docs/project_brief.md template

```
# Project Brief — [Project Name]

**Created:** [today's date]
**Status:** Approved

## What this builds
[One paragraph: what it is, what problem it solves, who uses it]

## Goals
- [Measurable goal 1]
- [Measurable goal 2]

## Non-goals (explicitly out of scope)
- [What we are NOT building, and why]

## MVP
[List of features in the MVP and the MVP done condition]

## Roadmap
| Milestone | Features | Rationale |
|-----------|----------|-----------|
| M1 — MVP | [list] | [why] |
| M2 | [list] | [why] |

## Tech decisions
| Component | Choice | Rationale | Risk | Code-lead note |
|-----------|--------|-----------|------|----------------|
| [Frontend] | [choice] | [why] | [risk] | [note or "None"] |
| [Backend] | [choice] | [why] | [risk] | [note or "None"] |
| [Auth] | [choice] | [why] | [risk] | [note or "None"] |
| [Database] | [choice] | [why] | [risk] | [note or "None"] |
| [File storage] | [choice or "None"] | [why] | [risk] | [note or "None"] |
| [Real-time] | [choice or "None"] | [why] | [risk] | [note or "None"] |
| [External APIs] | [list or "None"] | [why] | [risk] | [note or "None"] |
| [Deployment] | [choice] | [why] | [risk] | [note or "None"] |

## Success metrics
- [How we know MVP worked]
- [How we know the product is feature-complete]

## Decisions and overrides
[Any scope or stack decisions overridden by the developer, with brief reasoning]

## Open questions
- [Unresolved decisions that affect scope, stack, or sequencing]
```

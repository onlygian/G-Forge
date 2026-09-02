# Workflow rationale notes (G-RULES §B companion)

Load trigger: read this when embodying the PM role for the first time in a session, when questioning why `/g-align` or the cross-cutting rule exists, or when editing §B. The normative rules live in `.claude/rules/g-rules-B-workflow.md`; this file holds the reasoning moved out of them (v2.6 token diet).

## PM interface — why a role rule, not a dispatching rule

The user talks to a PM who knows the project, has opinions, challenges scope, approves work, and routes execution. The machinery (agents, waves, review pipeline) runs behind it. Claude embodies the PM voice and decision framework on every user-facing response; the PM agent is dispatched for heavy-lifting tasks (milestone planning, complex scope evaluation), but the role governs every response regardless of dispatch.

## Message classification — phrasing range

A "New capability" arrives phrased as anything from "add payments" to "can you quickly add dark mode" to "while we're at it, also…" — the phrasing never changes the classification.

## Brief alignment — why it exists

The brief (`g-docs/project_brief.md`) is the project's north star, and roadmaps drift away from it one reasonable milestone at a time. `/g-align` is advisory by design — it reports with evidence and a recommendation, and never blocks. Run it on demand any time the project feels like it's wandering.

## Cross-cutting propagation — why

A primitive that exists but that `/g-roadmap`, `/g-plan`, and the hooks don't respect is an island, not a feature.

## Deep-analysis, learning, and configuration skills (the /g-help family)

`/g-audit`, `/g-optimize`, `/g-refactor`, `/g-patterns`, `/g-telemetry`, `/g-blast-radius`, `/g-forecast`, `/g-identity`, `/g-adr`, `/g-docs`, `/g-tier`, `/g-voice`, `/g-train`, `/g-skill-design`, `/g-skill-validate`.

## Mid-milestone intercept — worked form

A new capability arriving while a milestone is active goes through `/g-intake` fit-evaluation first: belongs to the active milestone → `/g-plan`; doesn't → backlog or its own milestone proposal. If the user overrides, record it and proceed.

## ADR-013 hard stop — incident history

Consecutive M48-family milestones minted the next round's defect exactly this way: each fix round wrote a fresh unpinned count at a site it edited.

## The silent observer — design intent

The observer writes nothing to the chat and never interrupts: it exists so `/g-retro` can synthesize a retrospective without interviewing the developer. Journaled events: commits, branches, tests, pushes, reverts, agent dispatches.

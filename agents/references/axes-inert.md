# AXES / review panel — inert-as-shipped history (code-lead + review-orchestrator)

Maintainer-facing rationale. NOT read by dispatched agents — the operational
one-liners stay in the agent cores; this file holds the panel history behind
them and behind /g-review's Step 0 note
(`skills/g-review/references/panel-history.md` is the skill-side companion).

## INERT AS SHIPPED (stamped 2026-08-29)

No agent in the shipped pipeline produces an `AXES:` line: `/g-review`
dispatches `code-lead` directly and never dispatches `review-orchestrator`, and
code-lead holds no `Agent(` grant (see its `tools:` line), so it cannot
dispatch one either. **An absent `AXES:` line is not a holding axis** — code-lead
treats the axis clauses as satisfied and issues the verdict on the remaining
criteria; it does not block, and does not report a missing `AXES:` line as a
finding. Wiring the panel was M51 item 1, dropped 2026-08-28 with the minimal
freeze (ADR-012 — `g-docs/decisions/012-g-forge-2.5-final-release-scope.md` —
amendment 4); the review panel is a component the rebuild map marks DIES, so
G-Proof rebuilds it rather than 2.5 wiring it. The clauses are kept rather than
deleted because the rebuild restores the mechanism they describe — and because
`tests/test-review-severity.sh` pins the contract text so the fail-open below
cannot silently return if the panel is ever wired.

## Platform note (probed 2026-08-30)

Nested subagent dispatch works on the current platform — a dispatched agent
holding an `Agent(...)` grant can spawn its children, so the historical depth-0
constraint formerly asserted in review-orchestrator's body is obsolete. As of
2.5 no shipped skill dispatches review-orchestrator; it remains directly
invocable (`--agent review-orchestrator`).

## Why the AXES line is the second line of defense

The `AXES:` row carries each dispatched reviewer's native `RESULT` verbatim, so
the caller (code-lead) can HOLD on any axis HOLD even when the shared severity
buckets look clean. The historical bug this guards: a security **High** finding
bucketed below Critical and passed the gate — the fail-open the normalization
table ("Security is intentionally stricter"; High maps up to Critical, never
down) and the any-HOLD-forces-FAIL rule exist to close. An example of the class:
a `security-auditor=HOLD` on a security `High`, which normalizes to Critical.

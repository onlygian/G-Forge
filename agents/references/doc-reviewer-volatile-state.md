# doc-reviewer lens 5 — volatile in-flight state and ADR-013

Maintainer-facing rationale. NOT read by dispatched agents — the operational
remedy (pin-with-a-test-or-omit; pointer language only for unpinnable
must-state numbers; contradiction escalates to lens-2 Currency, BLOCKING) is
stated once in `agents/doc-reviewer.md`. Keep this file aligned with
`skills/g-doc-review/references/severity-edge-cases.md` — the two surfaces must
agree (audit F2-5/R-4 history).

A hardcoded number in a durable doc that describes process state still in
motion — round counts, commits-ahead/behind figures, "N dispatches so far",
agent counts mid-wave — is accurate the moment it's written and stale the
moment the process advances one more step. Every subsequent round's fix
falsifies the previous round's number, which is a repeat source of
review-round churn, not a one-off typo.

Per G-Forge ADR-013 ("documents keep their numbers" — replacing a count with a
pointer removes a useful fact nobody can then use), the remedy order is: if the
number matters enough to state, **pin it with a test first** — a test that
fails when the count and its source disagree — else leave the number out. That
pin-or-omit pair is ADR-013's own remedy. Pointer language (citing the file or
record that owns the number) is the review contract's **own addition**, not
part of the ADR: offered only for a number that must be stated but can't be
pinned. Never the default fix — ADR-013's Rejected list is exactly the
swap-count-for-pointer edit.

Lens 5 is a smell, not a contradiction check: when the hardcoded number already
disagrees with the record it points at (or should point at), that's lens 2
(Currency) and the existing contradiction rule applies — BLOCKING, not WARNING,
and not a new severity tier.

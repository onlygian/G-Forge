# Severity edge cases — volatile in-flight state (lens 5) and its escalation

Load when a finding involves a hardcoded volatile count/number, or when a
WARNING candidate looks like it contradicts the record it points at. The
closed-set literals BLOCKING / WARNING / PASS and the DOCS READY / DOCS HOLD
mapping stay in the SKILL.md core; this file carries the lens-5 remedy essay.
Keep this text aligned with `agents/doc-reviewer.md`'s inline lens-5/ADR-013
rule — both surfaces must agree (audit F2-5/R-4 history).

## Lens 5 — the remedy order
Volatile in-flight state hardcoded in a durable doc — round counts,
commits-ahead/behind figures, "N dispatches so far", agent counts mid-wave, any
figure that changes while the work it describes is still moving — is accurate
the moment it's written and stale the moment the process advances one more
step; every subsequent round's fix falsifies the previous round's number, a
repeat source of review-round churn, not a one-off typo.

Per G-Forge ADR-013 ("documents keep their numbers" — replacing a count with a
pointer removes a useful fact nobody can then use), flag it and recommend, in
order: if the number matters enough to state, **pin it with a test first** — a
test that fails when the count and its source disagree — else leave the number
out. That pin-with-a-test-or-omit pair is ADR-013's own remedy.

Record-citation **pointer language** (citing the file or record that owns the
number) is the review contract's own addition, not part of the ADR: offer it
only for a number that must be stated but can't be pinned. Never recommend
pointer language as the default fix — ADR-013's Rejected list is exactly the
swap-count-for-pointer edit.

## Escalation to Currency
Lens 5 is a smell, not a contradiction check by itself. It escalates to
BLOCKING only when the hardcoded number **already contradicts** the record it
should match — and then it is a lens-2 **Currency** finding, not lens 5: the
existing contradiction rule applies (BLOCKING, not WARNING), not a new severity
tier.

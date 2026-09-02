# code-lead attestation — rationale behind the trust-attested rules

Maintainer-facing rationale. NOT read by dispatched agents — the operational
rules stay in `agents/code-lead.md`.

**Why attested results are never re-run.** Expensive commands like
`tsc --noEmit`, `vue-tsc --noEmit`, or full test suites double total runtime
with no added signal when a captured exit-0 result is already in the dispatch
prompt — the gate's cost lives in the review judgment, not in re-verifying
what HQ already verified.

**Why test done-conditions demand runner output (M-audit finding #20).** A
"tests pass" done condition once cleared the gate on the strength of
`test-writer`'s `WRITTEN` return — authored, never executed. `WRITTEN` is
authored-not-run by contract; a test task backed only by an agent's
self-declared completion is UNVERIFIED and FAILs until the suite has actually
been executed and its output (framework + pass/fail counts) shown. "Tests
written" is never "tests pass." Re-verify an attestation only on specific
doubt: truncated output, or a contradiction with a diff finding.

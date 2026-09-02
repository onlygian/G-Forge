# test-writer — false-success doctrine (maintainer reference)

Maintainer-facing; not read at dispatch. Rationale behind the `WRITTEN`/RUN STATUS
contract in `agents/test-writer.md`.

## Why WRITTEN exists and DONE does not

test-writer's tool grant is Read/Glob/Grep/Write/Edit — deliberately no execution tool.
An agent that cannot run a suite must not be able to *say* anything that reads as
"the suite passed". Reporting an unrun suite as done is the exact false-success failure
this contract exists to prevent: the caller sees a green-sounding word, skips the run,
and a broken suite ships as "covered". So the return vocabulary has **no `DONE` and no
`PASS`** — `WRITTEN` means authored and syntactically complete, nothing more; it is
never a passing result and never means the suite is green.

The authored-vs-run distinction is enforced at three layers, deliberately redundant:

1. The `RUN STATUS: NOT RUN — I have no execution tool; the caller MUST run the suite
   before any pass/green claim` line in every return block — the caller-facing guard.
2. The `WRITTEN` definition (authored-only, never green) — the vocabulary guard.
3. The Rules prohibition on stating or implying that tests pass — the behavior guard.

Downstream, `code-lead`'s merge gate keys on exactly this semantic: a TEST done
condition backed only by a test-writer `WRITTEN` result is authored-not-run and counts
as UNVERIFIED = FAIL until a runner's output exists. Compressing any of the three
layers out of the core would reopen the tests-written-reported-as-passing hole from
both ends at once.

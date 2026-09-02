# Attestation doctrine — why the suite run is claim-checked, and how

Load when a summary total disagrees with its per-suite table, when an agent
self-declares "tests pass" without runner output, or when a suite must run
detached. The three operational imperatives live in the Step 1 core; this file
carries the why and the worked failure modes.

## Claim-vs-data doctrine
HQ sums the runner's per-suite table independently before accepting any total.
A summary total that disagrees with its own table is treated as confabulated —
the summed table wins, and the discrepancy is recorded in the review record
(claim-vs-data doctrine, three occurrences through M-audit). The runner's
`Results:` lines are data; any prose total is a claim about that data, and when
they disagree the data is authoritative.

## Finding #20 — UNVERIFIED rule background
A self-declared "tests pass" claim with no runner evidence is UNVERIFIED
(M-audit finding #20 doctrine) and is treated the same as a failed run. The
originating failure: a test task was reported complete on the strength of
`test-writer` returning `WRITTEN` — authored, never executed — and the green
claim propagated to the gate. "Tests written" is never "tests pass"; only
captured runner output (framework + pass/fail counts) attests a pass. This is
why the `.claude/agents/*-dev.md` fixture dispatch in Step 1 also requires
verbatim runner output before its result is folded into the attested materials.

## Detached runs — the nohup/no-trailing-pipe rationale
If the suite's expected runtime may exceed the shell tool's maximum timeout
(~10 min), run it detached — `nohup bash tests/run-all.sh > <logfile> 2>&1 &
disown` — then poll the log for the runner's final results line. Never trail a
pipe (e.g. `| tail`) onto a backgrounded suite run: it silently drops output or
fakes a hang — the pipe's reader exits before the suite finishes, the suite
blocks on a closed pipe or its output vanishes, and the session either waits on
nothing or reads an empty capture as a clean run.

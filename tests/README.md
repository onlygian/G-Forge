# Hook tests

Unit tests for the G-Forge hook scripts in `hooks/`. Pure bash — no test
framework, no dependencies beyond a POSIX shell and `git`.

The suite **set** is never hand-typed here — `tests/run-all.sh` derives it from
the `tests/test-*.sh` glob at runtime, per [ADR-013](../g-docs/decisions/013-derive-in-consumers-keep-counts-in-prose.md)
rule 1 (executable consumers derive their lists at runtime). This file is
prose, not a consumer, so per the same ADR's rule 2 it keeps its concrete
numbers rather than pointing at a directory: **22 suites** — pinned by
`tests/test-run-all.sh`'s suite-count baseline (`EXPECTED_SUITE_COUNT`), which
goes red if a suite is added or removed without updating it — carrying
**622 assertions** (attested 2026-08-28, summed independently from the run's
`Results:` lines per G-RULES §H; the assertion total is a dated attestation,
not test-pinned — re-sum after any suite change).

## Run

```bash
bash tests/run-all.sh
```

Derives the suite set from the `tests/test-*.sh` glob (never a hand-typed
list), then runs each suite serially — deliberately: reordering a serial run
cannot reduce total wall-clock, only perceived progress, so this is not a gap
to "fix" with `-j`. Each suite's output streams to a temp file rather than
being captured into a shell variable (capturing stalled on suites with
abandoned-stdin fixtures). The runner sums the per-suite `Results:` lines into a grand total. Two anomaly
axes are surfaced separately in the summary: suites with no parseable
`Results:` line (excluded from the summed total, since there is nothing to
sum) and suites that exited non-zero (still summed when they printed a
parseable `Results:` line, so a green-looking total with a red exit stays
visible). Any failure on either axis, or any failed assertion, makes the
runner exit non-zero. `GF_RUNALL_SUITE_DIR` overrides the suite directory for
test-only use; unset, behavior is unchanged.

Individual suites can still be run directly:

```bash
bash tests/test-check-commit.sh
bash tests/test-observe.sh
```

Each script prints one `PASS:`/`FAIL:` line per case and a `Results: N passed, M failed` summary, exiting non-zero if any case fails.

## Path resolution convention

Every suite resolves script/repo paths to **absolute, once, at the top** —
before any fixture `cd`. Suites must be invocation-form-insensitive: identical
results whether run as `bash tests/test-<name>.sh` from the repo root or via
an absolute path from any cwd. Lazy `dirname "$0"` re-derivation after a `cd`
is prohibited — a fixture `cd` invalidates a relative `$0`, silently breaking
path lookups that run after it.

Reference implementation: `tests/test-class-split-invariant.sh` lines 1-8 —
resolve `SCRIPT_DIR` and `HOOKS_DIR` via `cd "$(dirname "${BASH_SOURCE[0]}")" && pwd`
before the sandbox `cd`, never after.

This convention exists because the class-split invariant suite once returned
contradictory results under relative vs. absolute invocation — hook paths
were re-derived after a fixture `cd` (W1.5g finding, ADR-008 clause 6).

Attestation runs use the canonical invocation form (repo-root relative,
`bash tests/test-<name>.sh`); only an attested runner table is authoritative
for pass counts.

## Timing bounds — declared once, in `tests/lib/timing-bounds.sh`

A timing bound is **one fact**, and a suite must never carry its own copy of a
bound another suite also asserts. `tests/lib/timing-bounds.sh` holds every such
constant with its evidence; suites source it via their already-absolute
`$TESTS_DIR`/`$SCRIPT_DIR` and alias it locally if they want a suite-flavoured
name. `tests/lib/` is deliberately outside the `test-*.sh` glob, so it is never
mistaken for a suite by `for f in tests/test-*.sh`.

Authoring rule (`profiles/claude-plugin/rules/architecture.md`): at least **2×
the worst observed run** on MSYS/Git-Bash **measured under load** (never
quiet-machine idle alone), extracted to a named `*_MS` constant, dated WHY stated. Author generous, tighten on evidence. Every bound currently in that
file was first authored tight and later breached.

This convention exists because the abandoned-pipe bound lived in two suites at
once, was widened in one on fresh evidence, and the other went red on the next
run. A comment saying "keep these in step" is not enforcement.

## Matching non-ASCII output

Assertions that grep for output containing an **astral-plane** character —
anything above U+FFFF, which is every 4-byte emoji — must run their `grep` under
`LC_ALL=C`. Windows `wchar_t` is 16-bit, MSYS's `mbrtowc` cannot represent those
code points, and GNU grep 3.0's multibyte path then rejects the byte sequence
outright: the pattern silently never matches even though the character is
verifiably present in the captured output. 3-byte characters (`⚠ ✓ ⚑`) are
unaffected, which is what makes the failure look arbitrary. Reference
implementation: `check_match` in `tests/test-workflow-checkpoint.sh`.

The hook banners no longer print any astral-plane character — the decorative
emoji were removed and only `⚠`, `✓` and ASCII markers remain — so no assertion
currently depends on this. The rule stands for the next one that does: the
banner's marker set is a design choice that can change, the platform limit
cannot.

## PostToolUse skip-on-error boundary (characterized, accepted)

Claude Code does not fire PostToolUse hooks when the tool call exits non-zero.
Consequence: a real commit buried in a failing chain (`git commit … && false`)
lands in git but is invisible to the argv-based PostToolUse sites —
`observe.sh` never journals it and `post-commit-cleanup.sh` never clears
sentinels for it. `g-dev/fixtures/posttooluse-skip-boundary.sh` proves both
halves that are provable outside the platform: the class exists at git level,
and the hooks are correct when actually fed the payload (the gap is upstream,
not a parsing bug). Live evidence for the skip itself: W1.7's gated commits
absent from the 2026-07-22 journal (M-audit ledger W1.7ii, Task 28).

Decision (W2 task 21): **accepted, no code fix.** The sentinel lifecycle is
covered by the authoritative native `pre-commit` hook (consume-on-pass fires
in-process with the commit, immune to this skip); the journal is best-effort
by design (non-gating observer). Standing probe-hygiene rule: never chain
proof-steps into commit commands — run the commit as its own tool call.

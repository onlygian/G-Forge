#!/bin/bash
# tests/run-all.sh — suite runner. Groups per-suite output and sums totals
# without touching any production constant, timeout, or existing suite.
# Derives its suite set from tests/test-*.sh at run time (ADR-013: consumers
# derive their lists), never a typed list of names. GF_RUNALL_SUITE_DIR
# overrides the directory the glob runs against (unset = tests/, byte-
# identical to the pre-override behavior) — tests/test-run-all.sh is the
# only caller that ever sets it, to point the runner at fixture suites
# instead of the real tree.
#
# Total serial runtime is unchanged by this file: reordering below cannot
# reduce wall-clock, only change which suite reports first (this pass's own
# retro corrected the earlier claim that reordering was a wall-clock win —
# g-docs/retros/2026-08-19-m48-split-and-m48a-wave.md). The wall-clock
# lever is M48b/c's guard-window overrides, not reordering.
#
# Ordering is a HINT only. Basis: the two suites that would otherwise run last
# in glob order, both large (test-workflow-checkpoint.sh 81 and test-worktree-
# resolve.sh 42 assertions), are front-loaded so the big suites don't tail the
# run; the hint is NOT ranked by which suites hold the slow abandoned-stdin
# sleeper fixtures. Consequence accepted deliberately: pulling those two out of glob
# order leaves tests/test-stdin-read.sh (a sleeper suite) as the
# alphabetically-last unhinted suite, so it runs dead last. That used to
# matter — a trailing sleeper could stall the runner under the old capture
# mechanism (see the fix note in Step 3) — but with output no longer
# captured through a pipe, a suite finishing last no longer blocks
# run-all's return, so it is left out of the hint on that reasoning rather
# than added to it.
#
# The hint applies only to the default suite directory (tests/) — it is
# repo-specific knowledge about named suites, not a property that makes
# sense against an arbitrary fixture directory. It is self-checked as a
# subset of the derived set (a hinted name with no matching file fails the
# run loudly) and rejects duplicate entries (Step 2) rather than silently
# double-counting a suite. Any suite not in the hint runs after, in glob
# order. A new tests/test-*.sh file is picked up with zero edits here.
#
# Serial by design — see the Step 3 comment below for why -j / parallelism
# is not implemented (fixture-collision risk with the abandoned-stdin
# sleepers in test-check-commit.sh / test-class-split-invariant.sh).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

# --- Step 1: derive the full suite set from disk, never a typed list ---
SUITE_DIR="${GF_RUNALL_SUITE_DIR:-tests}"

SUITES=()
for f in "$SUITE_DIR"/test-*.sh; do
    [ -e "$f" ] || continue
    SUITES+=("$f")
done

if [ "${#SUITES[@]}" -eq 0 ]; then
    echo "run-all: no $SUITE_DIR/test-*.sh files found — nothing to run" >&2
    exit 1
fi

# --- Step 2: ordering hint — front-load the last-in-glob-order suites, self-checked ---
if [ "$SUITE_DIR" = "tests" ]; then
    HINT=(
        "$SUITE_DIR/test-workflow-checkpoint.sh"
        "$SUITE_DIR/test-worktree-resolve.sh"
    )
else
    # GF_RUNALL_SUITE_DIR override (fixture testing) — the hint is
    # repo-specific and does not apply; the validation loops below still
    # run against an empty HINT (a no-op) so the same code path executes
    # in both modes.
    HINT=()
fi

# Reject duplicate entries first — a duplicate would otherwise pass the
# subset check below (the second copy still "exists") and silently
# double-count that suite's Results line into the grand total (m2).
SEEN_HINT=()
for h in "${HINT[@]}"; do
    for s in "${SEEN_HINT[@]}"; do
        if [ "$s" = "$h" ]; then
            echo "run-all: ordering hint has a duplicate entry '$h' — fix run-all.sh" >&2
            exit 1
        fi
    done
    SEEN_HINT+=("$h")
done

for h in "${HINT[@]}"; do
    found=0
    for s in "${SUITES[@]}"; do
        [ "$s" = "$h" ] && { found=1; break; }
    done
    if [ "$found" -eq 0 ]; then
        echo "run-all: ordering hint '$h' has no matching file under $SUITE_DIR — hint is stale, fix run-all.sh" >&2
        exit 1
    fi
done

ORDERED=()
for h in "${HINT[@]}"; do
    ORDERED+=("$h")
done
for s in "${SUITES[@]}"; do
    skip=0
    for h in "${HINT[@]}"; do
        [ "$s" = "$h" ] && { skip=1; break; }
    done
    [ "$skip" -eq 0 ] && ORDERED+=("$s")
done

# --- Step 3: run each suite serially, capture its own Results line ---
# Serial (no -j): test-check-commit.sh and test-class-split-invariant.sh
# leave abandoned-stdin background sleepers (< <(sleep 300)) as deliberate
# fixtures. These sleepers are UNBOUNDED in lifetime (~300s each) — nothing
# reaps them (the reaping rider is still open, see g-docs/ROADMAP.md task
# 7). GUARD_WINDOW_MS (a local alias in test-class-split-invariant.sh of the
# tests/lib/timing-bounds.sh constants) bounds only the
# assertion window inside the suite under test — how long the hook under
# test may take to return — not the sleeper fixture's own lifetime.
# Running suites concurrently risks one suite's global process handling
# colliding with a sibling's in-flight fixture.
#
# Output capture: streamed to a temp file (`bash "$suite" >"$tmp" 2>&1`),
# never through a command substitution pipe. A command substitution
# (`OUT="$(bash "$suite" 2>&1)"`) binds the suite's fd 1 and fd 2 to a pipe
# that only returns on EOF — and the sleeper fixtures above inherit that
# pipe on fd 2 (their stderr), holding it open for their full ~300s
# lifetime even after the suite process itself has exited. run-all would
# not return from a suite until its last sleeper expired. A plain file
# redirect has no reader waiting on pipe EOF: run-all waits only on the
# suite's own process and returns as soon as it exits, regardless of what
# background children it left running.
START_EPOCH=$(date +%s)

declare -a RESULT_LINES=()
declare -a SUITE_PASS=()
declare -a SUITE_FAIL=()
declare -a NONZERO_EXIT_NAMES=()
declare -a NO_RESULTS_NAMES=()
ANY_NONZERO_EXIT=0
ANY_NO_RESULTS=0

for suite in "${ORDERED[@]}"; do
    name="$(basename "$suite")"
    echo "==================================================================="
    echo "== $name"
    echo "==================================================================="

    tmp="$(mktemp)" || { echo "run-all: mktemp failed" >&2; exit 1; }
    suite_start=$(date +%s)
    bash "$suite" >"$tmp" 2>&1
    rc=$?
    suite_end=$(date +%s)
    dur=$((suite_end - suite_start))
    OUT="$(cat "$tmp")"
    rm -f "$tmp"
    echo "$OUT"

    if [ "$rc" -ne 0 ]; then
        NONZERO_EXIT_NAMES+=("$name")
        ANY_NONZERO_EXIT=1
    fi

    line="$(printf '%s\n' "$OUT" | grep -E '^Results: [0-9]+ passed, [0-9]+ failed$' | tail -1)"

    if [ -z "$line" ]; then
        echo "run-all: $name — no 'Results: N passed, M failed' line found in output" >&2
        NO_RESULTS_NAMES+=("$name")
        ANY_NO_RESULTS=1
        RESULT_LINES+=("$name: NO RESULTS LINE (exit $rc, ${dur}s)")
        continue
    fi

    p="$(printf '%s' "$line" | sed -E 's/^Results: ([0-9]+) passed, ([0-9]+) failed$/\1/')"
    f="$(printf '%s' "$line" | sed -E 's/^Results: ([0-9]+) passed, ([0-9]+) failed$/\2/')"
    SUITE_PASS+=("$p")
    SUITE_FAIL+=("$f")
    RESULT_LINES+=("$name: $line (exit $rc, ${dur}s)")
done

END_EPOCH=$(date +%s)
ELAPSED=$((END_EPOCH - START_EPOCH))

# --- Step 4: re-emit per-suite lines, sum a grand total from them ---
echo "==================================================================="
echo "== Suite summary"
echo "==================================================================="
for line in "${RESULT_LINES[@]}"; do
    echo "$line"
done

# Pass/fail totals are a pure sum of observed Results lines — suites with
# no parseable Results line (NO_RESULTS_NAMES) are reported on their own
# axis below and excluded here, never synthesized into the sum (m3).
TOTAL_PASS=0
TOTAL_FAIL=0
for p in "${SUITE_PASS[@]}"; do
    TOTAL_PASS=$((TOTAL_PASS + p))
done
for f in "${SUITE_FAIL[@]}"; do
    TOTAL_FAIL=$((TOTAL_FAIL + f))
done

# Suite-count baseline: the expected count for tests/ is pinned by a test
# in tests/test-run-all.sh (ADR-013 rule 2 — pin it or say where it lives,
# never hardcode it here where ADR-013 rule 1 already makes it derived).
SUITE_COUNT="${#ORDERED[@]}"

echo "==================================================================="
echo "Grand total: $TOTAL_PASS passed, $TOTAL_FAIL failed across $SUITE_COUNT suites"
if [ "$ANY_NONZERO_EXIT" -eq 1 ]; then
    echo "Suites exiting non-zero: ${#NONZERO_EXIT_NAMES[@]} (${NONZERO_EXIT_NAMES[*]})"
fi
if [ "$ANY_NO_RESULTS" -eq 1 ]; then
    echo "Suites with no Results line: ${#NO_RESULTS_NAMES[@]} (${NO_RESULTS_NAMES[*]})"
fi
echo "Wall-clock: ${ELAPSED}s"
echo "==================================================================="

if [ "$TOTAL_FAIL" -ne 0 ] || [ "$ANY_NONZERO_EXIT" -eq 1 ] || [ "$ANY_NO_RESULTS" -eq 1 ]; then
    exit 1
fi

exit 0

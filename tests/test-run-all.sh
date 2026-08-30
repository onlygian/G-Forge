#!/bin/bash
# tests/test-run-all.sh — Unit tests for tests/run-all.sh (the suite runner).
#
# CRITICAL RECURSION HAZARD: run-all.sh's default suite dir is tests/, which
# this file itself matches (test-*.sh) — a scenario that lets run-all.sh
# glob its default dir AND executes suites from it would try to run this
# very file again. Scenarios (a)-(c) sidestep this with GF_RUNALL_SUITE_DIR,
# pointed at a throwaway fixture directory, never at tests/. Scenario (d)
# is the one exception: it intentionally uses the real default dir (it needs
# the real ordering HINT, which only applies there — see run-all.sh's Step 2
# comment), but it is safe because the duplicate-HINT rejection it exercises
# always exits before Step 3's suite-execution loop begins (verified below),
# so no suite — this one included — ever actually runs.
#
# Covers: missing-Results-line axis (m3), green-print/red-exit axis (M4),
# happy-path summed totals, HINT duplicate-entry rejection (m2), and the
# suite-count baseline pin (m6 — ADR-013 rule 2: this file IS where the
# tests/test-*.sh count baseline lives, referenced from run-all.sh's own
# comment rather than hardcoded there).
#
# Total assertions: 11
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line —
# the finding-#20 cross-check that catches a suite silently dropping cases.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNALL="$TESTS_DIR/run-all.sh"
[ -f "$RUNALL" ] || { echo "FAIL: $RUNALL not found"; exit 1; }

PASS=0
FAIL=0

# ── Scenario (a): missing-Results-line branch (m3) ──────────────────────────

FIXTURE_A="$(mktemp -d)"
cat > "$FIXTURE_A/test-noresults.sh" <<'EOF'
#!/bin/bash
echo "this suite never prints a Results line"
exit 0
EOF

tmp_a="$(mktemp)" || { echo "FAIL: mktemp failed for scenario (a)"; exit 1; }
GF_RUNALL_SUITE_DIR="$FIXTURE_A" bash "$RUNALL" >"$tmp_a" 2>&1
RC_A=$?
OUT_A="$(cat "$tmp_a")"
rm -f "$tmp_a"

if [ "$RC_A" -ne 0 ]; then
    echo "PASS: missing-Results-line branch — runner exits non-zero"
    PASS=$((PASS+1))
else
    echo "FAIL: missing-Results-line branch — expected non-zero exit, got 0"
    FAIL=$((FAIL+1))
fi

if printf '%s\n' "$OUT_A" | grep -qE '^Suites with no Results line: 1 \(test-noresults\.sh\)$'; then
    echo "PASS: missing-Results-line branch — reported on its own axis"
    PASS=$((PASS+1))
else
    echo "FAIL: missing-Results-line branch — 'Suites with no Results line' axis line not found"
    FAIL=$((FAIL+1))
fi

if printf '%s\n' "$OUT_A" | grep -qE '^Grand total: 0 passed, 0 failed across 1 suites$'; then
    echo "PASS: missing-Results-line branch — excluded from the summed pass/fail totals"
    PASS=$((PASS+1))
else
    echo "FAIL: missing-Results-line branch — grand total line wrong (expected 0 passed, 0 failed across 1 suites)"
    FAIL=$((FAIL+1))
fi

# falsifiability: 'if [ -z "$line" ]; then' forced to 'if false; then' in a
# scratch copy of run-all.sh, run against this same fixture — the neutered
# copy exits 0 with no no-Results axis line, confirming the guard above (not
# coincidence) produces the red exit and the report — 2026-08-20
rm -rf "$FIXTURE_A"

# ── Scenario (b): green-print/red-exit branch (M4) ──────────────────────────

FIXTURE_B="$(mktemp -d)"
cat > "$FIXTURE_B/test-redexit.sh" <<'EOF'
#!/bin/bash
echo "Results: 1 passed, 0 failed"
exit 3
EOF

tmp_b="$(mktemp)" || { echo "FAIL: mktemp failed for scenario (b)"; exit 1; }
GF_RUNALL_SUITE_DIR="$FIXTURE_B" bash "$RUNALL" >"$tmp_b" 2>&1
RC_B=$?
OUT_B="$(cat "$tmp_b")"
rm -f "$tmp_b"

if [ "$RC_B" -ne 0 ]; then
    echo "PASS: green-print/red-exit branch — runner exits non-zero despite a green Results line"
    PASS=$((PASS+1))
else
    echo "FAIL: green-print/red-exit branch — expected non-zero exit, got 0"
    FAIL=$((FAIL+1))
fi

if printf '%s\n' "$OUT_B" | grep -qE '^Suites exiting non-zero: 1 \(test-redexit\.sh\)$'; then
    echo "PASS: green-print/red-exit branch — banner carries the non-zero-exit line"
    PASS=$((PASS+1))
else
    echo "FAIL: green-print/red-exit branch — 'Suites exiting non-zero' axis line not found"
    FAIL=$((FAIL+1))
fi

# falsifiability: 'if [ "$rc" -ne 0 ]; then' (the NONZERO_EXIT_NAMES/
# ANY_NONZERO_EXIT assignment) forced to 'if false; then' in a scratch copy,
# run against this same fixture — the neutered copy exits 0 with the banner
# reading green and no non-zero-exit line, confirming the guard above
# produces the red exit and the visible line — 2026-08-20
rm -rf "$FIXTURE_B"

# ── Scenario (c): happy path — two green fixtures, summed totals ───────────

FIXTURE_C="$(mktemp -d)"
cat > "$FIXTURE_C/test-green-one.sh" <<'EOF'
#!/bin/bash
echo "Results: 3 passed, 0 failed"
exit 0
EOF
cat > "$FIXTURE_C/test-green-two.sh" <<'EOF'
#!/bin/bash
echo "Results: 5 passed, 0 failed"
exit 0
EOF

tmp_c="$(mktemp)" || { echo "FAIL: mktemp failed for scenario (c)"; exit 1; }
GF_RUNALL_SUITE_DIR="$FIXTURE_C" bash "$RUNALL" >"$tmp_c" 2>&1
RC_C=$?
OUT_C="$(cat "$tmp_c")"
rm -f "$tmp_c"

if [ "$RC_C" -eq 0 ]; then
    echo "PASS: happy path — runner exits zero for two green fixtures"
    PASS=$((PASS+1))
else
    echo "FAIL: happy path — expected exit 0, got $RC_C"
    FAIL=$((FAIL+1))
fi

if printf '%s\n' "$OUT_C" | grep -qE '^Grand total: 8 passed, 0 failed across 2 suites$'; then
    echo "PASS: happy path — summed totals correct (8 passed, 0 failed across 2 suites)"
    PASS=$((PASS+1))
else
    echo "FAIL: happy path — grand total line wrong (expected 8 passed, 0 failed across 2 suites)"
    FAIL=$((FAIL+1))
fi

rm -rf "$FIXTURE_C"

# ── Scenario (d): HINT duplicate-entry rejection (m2) ───────────────────────

# Pattern-based duplication (not a line number) so this stays correct if
# run-all.sh's line numbers shift; the HINT array line is the only line in
# the file containing this literal with a trailing quote (the header prose
# mentions the same filename without one) — verified before authoring this
# test by grepping run-all.sh for the exact string.
DUP_COPY="$TESTS_DIR/.scratch-dup-hint-$$.sh"
# Trap set BEFORE the copy is created: a normal exit, a failed assertion, or a
# caught signal between here and the final `rm -f` below still cleans up. A
# SIGKILL (external hard kill) skips any trap — for that case the backstop is
# the `tests/.scratch-*` gitignore rule, which keeps a leaked copy uncommittable.
trap 'rm -f "$DUP_COPY"' EXIT INT TERM
sed '/test-workflow-checkpoint\.sh"/{p}' "$RUNALL" > "$DUP_COPY"

tmp_d="$(mktemp)" || { echo "FAIL: mktemp failed for scenario (d)"; exit 1; }
timeout 10 bash "$DUP_COPY" >"$tmp_d" 2>&1
RC_D=$?
OUT_D="$(cat "$tmp_d")"
rm -f "$tmp_d" "$DUP_COPY"

if [ "$RC_D" -ne 0 ]; then
    echo "PASS: duplicate-HINT entry — runner exits non-zero"
    PASS=$((PASS+1))
else
    echo "FAIL: duplicate-HINT entry — expected non-zero exit, got 0"
    FAIL=$((FAIL+1))
fi

if printf '%s\n' "$OUT_D" | grep -q "ordering hint has a duplicate entry"; then
    echo "PASS: duplicate-HINT entry — rejected with the duplicate-entry message"
    PASS=$((PASS+1))
else
    echo "FAIL: duplicate-HINT entry — expected 'ordering hint has a duplicate entry' message"
    FAIL=$((FAIL+1))
fi

if ! printf '%s\n' "$OUT_D" | grep -q "^== "; then
    echo "PASS: duplicate-HINT entry — no suite banner printed (rejected before Step 3 execution)"
    PASS=$((PASS+1))
else
    echo "FAIL: duplicate-HINT entry — a suite banner was printed; rejection did not happen before execution"
    FAIL=$((FAIL+1))
fi

# falsifiability: the duplicate-detection loop's inner comparison
# ('if [ "$s" = "$h" ]; then') forced to 'if false; then' in a scratch copy,
# run against the same duplicated-HINT fixture — the neutered copy proceeds
# past Step 2 and starts executing the duplicated suite (observed: its
# banner printed before an external `timeout` killed the run), confirming
# the guard above — not an unrelated failure — is what rejects the
# duplicate before any suite runs — 2026-08-20
# (`timeout` bounds this run defensively; the guard is expected to reject
# in well under a second, same as the other scenarios above.)

# ── Scenario (e): suite-count baseline pin (m6, ADR-013 rule 2) ────────────

# Plain equality on a directory count — self-evidently falsifiable (any
# mismatch fails immediately), no neuter-a-guard exercise needed. Bump this
# deliberately when a tests/test-*.sh suite is added or removed.
EXPECTED_SUITE_COUNT=24  # 19 pre-existing suites + M48c: test-version-agreement.sh + test-router-skill-parity.sh; M48d: test-pre-commit.sh; M52: test-telemetry-contract.sh, test-readme-counts.sh
actual_count=0
for f in "$TESTS_DIR"/test-*.sh; do
    [ -e "$f" ] || continue
    actual_count=$((actual_count+1))
done

if [ "$actual_count" -eq "$EXPECTED_SUITE_COUNT" ]; then
    echo "PASS: suite-count baseline — tests/test-*.sh count is $EXPECTED_SUITE_COUNT as pinned"
    PASS=$((PASS+1))
else
    echo "FAIL: suite-count baseline — expected $EXPECTED_SUITE_COUNT, counted $actual_count (bump EXPECTED_SUITE_COUNT above if this is an intentional add/remove)"
    FAIL=$((FAIL+1))
fi

# ── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

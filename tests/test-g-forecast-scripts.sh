#!/bin/bash
# Unit tests for skills/g-forecast/scripts/ (v2.6 prose→scripts extraction):
#   find-plan.sh      — Step 1 target-plan resolution (case order contractual)
#   calibration.sh    — Step 5b outcome parsing, N/M, hit_rate, floor, cold-start
#   forecast-calc.sh  — Steps 2b/2c/6 arithmetic (tokens, score, cold modes)
#
# Fixture corpora are built in throwaway mktemp dirs; the repo's own live
# g-docs/forecasts/ corpus doubles as a regression fixture (its dated
# records carry recorded ground-truth Calibration lines — m48e raw 76/adj −4
# → 70 Elevated; v25 raw 104.5 → display ≥100 → 95 High). One §H
# falsifiability probe proves the mitigation-held PREFIX assert can go red
# (a substring-matching scratch copy is detected).
#
# Total assertions: 44
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
FIND_PLAN="$REPO_ROOT/skills/g-forecast/scripts/find-plan.sh"
CALIB="$REPO_ROOT/skills/g-forecast/scripts/calibration.sh"
CALC="$REPO_ROOT/skills/g-forecast/scripts/forecast-calc.sh"

PASS=0
FAIL=0

check() { # name expected actual
    if [ "$2" = "$3" ]; then echo "PASS: $1"; PASS=$((PASS+1));
    else echo "FAIL: $1 (expected '$2', got '$3')"; FAIL=$((FAIL+1)); fi
}
check_has() { # name needle haystack
    if printf '%s\n' "$3" | grep -qF -- "$2"; then echo "PASS: $1"; PASS=$((PASS+1));
    else echo "FAIL: $1 (missing '$2')"; FAIL=$((FAIL+1)); fi
}
check_not() { # name needle haystack
    if printf '%s\n' "$3" | grep -qF -- "$2"; then
        echo "FAIL: $1 (unexpectedly found '$2')"; FAIL=$((FAIL+1));
    else echo "PASS: $1"; PASS=$((PASS+1)); fi
}

# ── find-plan.sh ─────────────────────────────────────────────────────────────

DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/plans"

# Task 1: no plans at all → EXIT: no-plan
OUT=$(cd "$DIR" && bash "$FIND_PLAN")
check "find-plan: no plan resolves to EXIT: no-plan" "EXIT: no-plan" "$OUT"

# Task 2: case 3 — most-recent plan with a pending Progress wave wins over an older one
printf '# Plan old\n\n## Progress\n\n| Wave | Status | Notes |\n|------|--------|-------|\n| 1 | pending | |\n' > "$DIR/g-docs/plans/old-plan.md"
printf '# Plan done\n\n## Progress\n\n| Wave | Status | Notes |\n|------|--------|-------|\n| 1 | complete | |\n' > "$DIR/g-docs/plans/done-plan.md"
sleep 1
printf '# Plan new\n\n## Progress\n\n| Wave | Status | Notes |\n|------|--------|-------|\n| 1 | pending | |\n' > "$DIR/g-docs/plans/new-plan.md"
OUT=$(cd "$DIR" && bash "$FIND_PLAN")
check_has "find-plan: case 3 picks most-recent pending plan" "PLAN: g-docs/plans/new-plan.md" "$OUT"
check_has "find-plan: case 3 slug from filename" "SLUG: new-plan" "$OUT"
check_has "find-plan: case 3 source label" "SOURCE: most-recent-pending" "$OUT"

# Task 2b: "pending" in a table OUTSIDE the Progress section never selects a
# plan — a newer, fully-executed decoy with "pending review" in a task table
# must lose to the older plan with a real pending Progress wave
sleep 1
printf '# Plan decoy\n\n| Task | Status |\n|------|--------|\n| review | pending review |\n\n## Progress\n\n| Wave | Status | Notes |\n|------|--------|-------|\n| 1 | complete | |\n' > "$DIR/g-docs/plans/decoy-plan.md"
OUT=$(cd "$DIR" && bash "$FIND_PLAN")
check_has "find-plan: pending outside Progress table is not a pending wave" \
    "PLAN: g-docs/plans/new-plan.md" "$OUT"

# Task 3: case 2 — explicit slug argument beats case 3
OUT=$(cd "$DIR" && bash "$FIND_PLAN" old-plan)
check_has "find-plan: case 2 slug argument resolves" "PLAN: g-docs/plans/old-plan.md" "$OUT"
check_has "find-plan: case 2 source label" "SOURCE: argument" "$OUT"

# Task 4: case 1 — pending-handoff beats everything (contract with /g-plan Step 3b)
printf '# Handoff plan\n' > "$DIR/g-docs/plans/.pending-forecast.md"
OUT=$(cd "$DIR" && bash "$FIND_PLAN" old-plan)
check_has "find-plan: case 1 pending-handoff wins even over an argument" \
    "PLAN: g-docs/plans/.pending-forecast.md" "$OUT"
check_has "find-plan: case 1 source label" "SOURCE: pending-handoff" "$OUT"
rm -rf "$DIR"

# ── calibration.sh — fixture corpus ─────────────────────────────────────────

DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/forecasts" "$DIR/g-docs/retros"
cat > "$DIR/g-docs/forecasts/fixture-a.md" <<'EOF'
# Forecast: Fixture A

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | scenario-one | 3 | 3 | 9 | forecast #5 mitigation-held earlier | retro-x |

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | happened (git) | |
| 2 | yes | **happened** — long trailing text (r1 6B, r2 5B) | notes |
| 3 | yes | did not happen (git) | mitigation-held: probe held |
| 4 | yes | did not happen (git) | see the mitigation-held: discussion mid-text |
| 5 | yes | partial (journal) | |
| 6 | yes | unverified | |
| 7 | yes | did not happen (unverified) | |
| 8 | yes | happened — variant (git) | |
| 9 | yes | | |
| 10 | yes | [yes / no / partial] | |
| 11 | yes | no (journal) | |
| 12 | yes | yes | |
| 13 | yes | happened (Pass 1) | |
| 14 | yes | happened (git) | |
EOF
printf '## Patterns\n### Avoid / do differently\n- a real bullet\n' > "$DIR/g-docs/retros/2026-01-01-r.md"
OUT=$(cd "$DIR" && bash "$CALIB")

# Task 5: N counts confirmed rows only (discard rule + blank/placeholder skip)
check "calibration: N=10 (confirmed only)" "N: 10" "$(printf '%s\n' "$OUT" | grep '^N:')"
# Task 6: M counts only the prefix-marked row
check "calibration: M=1 (prefix marker only)" "M: 1" "$(printf '%s\n' "$OUT" | grep '^M:')"
# Task 7: hit_rate = 7.0/10
check "calibration: HIT_RATE 0.70" "HIT_RATE: 0.70" "$(printf '%s\n' "$OUT" | grep '^HIT_RATE:')"
# Task 8: adjustment = round(0.2 * 20) = 4
check "calibration: CALIBRATION 4" "CALIBRATION: 4" "$(printf '%s\n' "$OUT" | grep '^CALIBRATION:')"
# Task 9: mitigation-held prefix row credited 0.5 and flagged
check_has "calibration: prefix mitigation-held row credited 0.5" \
    "row=3 verdict=did-not-happen tag=git credit=0.5 mitigation-held" "$OUT"
# Task 10: mid-text mitigation-held in Notes is NOT a prefix — unmodified 0
check_has "calibration: mid-text marker takes credit=0" \
    "row=4 verdict=did-not-happen tag=git credit=0" "$OUT"
check_not "calibration: mid-text marker never flagged mitigation-held" \
    "row=4 verdict=did-not-happen tag=git credit=0 mitigation-held" "$OUT"
# Task 11: both unverified forms surface as tag=unverified (discarded from N)
check "calibration: two unverified rows printed, both discarded" "2" \
    "$(printf '%s\n' "$OUT" | grep -c 'tag=unverified')"
# Task 12: blank and placeholder cells print no OUTCOME line
check_not "calibration: blank cell row 9 prints nothing" "row=9" "$OUT"
check_not "calibration: placeholder cell row 10 prints nothing" "row=10" "$OUT"
# Task 13: no-tag verdict is confirmed-legacy (tag=none, credit 1)
check_has "calibration: bare verdict is confirmed-legacy" \
    "row=12 verdict=yes tag=none credit=1" "$OUT"
# Task 14: pass-reference tag arm accepts arbitrary non-unverified tags
check_has "calibration: 'Pass 1' lands in the pass arm" \
    "row=13 verdict=happened tag=pass credit=1" "$OUT"
# Task 15: retro present → not cold-start
check "calibration: retros present means COLD_START no" "COLD_START: no" \
    "$(printf '%s\n' "$OUT" | grep '^COLD_START:')"
rm -rf "$DIR"

# ── calibration.sh — sample floor and cold-start ────────────────────────────

DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/forecasts"
cat > "$DIR/g-docs/forecasts/thin.md" <<'EOF'
## Outcome

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | happened (git) | |
| 2 | yes | did not happen (git) | |
| 3 | yes | partial (git) | |
EOF
OUT=$(cd "$DIR" && bash "$CALIB")
# Task 16: N<5 → floor, no HIT_RATE
check "calibration: floor not met at N=3" "CALIBRATION: 0 (floor-not-met N=3)" \
    "$(printf '%s\n' "$OUT" | grep '^CALIBRATION:')"
check_not "calibration: no HIT_RATE below the floor" "HIT_RATE:" "$OUT"
# Task 17: no retros, no patterns-deferred, no git → cold-start yes
check "calibration: cold-start detected on empty history" "COLD_START: yes" \
    "$(printf '%s\n' "$OUT" | grep '^COLD_START:')"
rm -rf "$DIR"

# ── calibration.sh — live-corpus regression pins (dated records, immutable) ──

OUT=$(cd "$REPO_ROOT" && bash "$CALIB")
# Task 18: m48e row 3 — mitigation-held prefix on a dated record
check_has "calibration live: m48e row 3 mitigation-held" \
    "file=g-docs/forecasts/m48e-tier-cases-and-heredoc-fix.md row=3 verdict=did-not-happen tag=pass credit=0.5 mitigation-held" "$OUT"
# Task 19: m48d row 5 — pass-reference tag '(retro 2026-08-22)' confirmed
check_has "calibration live: m48d row 5 pass-reference confirmed" \
    "file=g-docs/forecasts/m48d-direct-runner-and-gate-coverage.md row=5 verdict=did-not-happen tag=pass credit=0.5 mitigation-held" "$OUT"
# Task 20: v25 row 1 — emphasis-wrapped **happened** reads identically
check_has "calibration live: v25 emphasis-wrapped happened" \
    "file=g-docs/forecasts/v25-minimal-freeze.md row=1 verdict=happened" "$OUT"

# ── §H falsifiability probe — the prefix assert can go red ──────────────────

DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/forecasts"
cat > "$DIR/g-docs/forecasts/probe.md" <<'EOF'
## Outcome

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | did not happen (git) | see the mitigation-held: discussion mid-text |
EOF
SCRATCH="$DIR/calibration-neutered.sh"
sed 's|/\^mitigation-held:/|/mitigation-held:/|' "$CALIB" > "$SCRATCH"
OUT_REAL=$(cd "$DIR" && bash "$CALIB" | grep '^OUTCOME:')
OUT_NEUT=$(cd "$DIR" && bash "$SCRATCH" | grep '^OUTCOME:')
# Task 21: real script keeps credit=0; the substring-matching scratch copy
# flips to 0.5 mitigation-held — proving the Task 10 assert is falsifiable
if printf '%s' "$OUT_REAL" | grep -q 'credit=0$' \
   && printf '%s' "$OUT_NEUT" | grep -q 'credit=0.5 mitigation-held'; then
    echo "PASS: §H probe — substring-matching scratch copy goes red where prefix rule holds"
    PASS=$((PASS+1))
else
    echo "FAIL: §H probe — expected real credit=0 vs neutered credit=0.5 (real='$OUT_REAL' neutered='$OUT_NEUT')"
    FAIL=$((FAIL+1))
fi
rm -rf "$DIR"

# ── forecast-calc.sh ────────────────────────────────────────────────────────

# Task 22: m48e regression — raw 76, adj −4, rounded once → 70 Elevated
OUT=$(bash "$CALC" score --complexity 5 --scenario-scores 12,12,10 --calibration -4)
check_has "calc score: m48e raw 76" "RAW: 76" "$OUT"
check_has "calc score: m48e miss_risk 70 (round once, at the end)" "MISS_RISK: 70" "$OUT"
check_has "calc score: m48e tag Elevated" "TAG: Elevated" "$OUT"

# Task 23: v25 regression — raw 104.5, display saturates, clamp 95 High
OUT=$(bash "$CALC" score --complexity 9 --scenario-scores 20,20,20 --calibration -3)
check_has "calc score: v25 unclamped raw 104.5" "RAW: 104.5" "$OUT"
check_has "calc score: v25 display saturation marker" "RAW_DISPLAY: >=100" "$OUT"
check_has "calc score: v25 miss_risk clamped to 95" "MISS_RISK: 95" "$OUT"

# Task 24: blast mapping re-clamped to 0-10 (wide on 9 → 10, not 11)
OUT=$(bash "$CALC" score --complexity 9 --scenario-scores 1 --calibration 0 --blast wide)
check_has "calc score: wide blast re-clamps complexity to 10" "COMPLEXITY_ADJ: 10" "$OUT"

# Task 25: tokens band — 4 tasks, 7 files → 19k–58k Medium
OUT=$(bash "$CALC" tokens --tasks 4 --files 7)
check "calc tokens: band and tag" "TOKENS: low=19k high=58k tag=Medium" "$OUT"

# Task 26: cold mode — 15 + 7*3 = 36, floor at complexity 0 = 15
OUT=$(bash "$CALC" cold --complexity 7)
check_has "calc cold: miss_risk 36" "MISS_RISK: 36" "$OUT"
check_has "calc cold: mode line" "MODE: cold-start" "$OUT"
OUT=$(bash "$CALC" cold --complexity 0)
check_has "calc cold: floor 15" "MISS_RISK: 15" "$OUT"

# Task 27: cold mode applies the blast-radius adjustment BEFORE the formula
# (HEAD Step 2b parity — the adjustment fired before any formula ran,
# cold-start included): complexity 5 + wide → adj 7 → 15 + 21 = 36
OUT=$(bash "$CALC" cold --complexity 5 --blast wide)
check_has "calc cold: wide blast adjusts complexity to 7" "COMPLEXITY_ADJ: 7" "$OUT"
check_has "calc cold: blast-adjusted miss_risk 36" "MISS_RISK: 36" "$OUT"
OUT=$(bash "$CALC" cold --complexity 9 --blast moderate)
check_has "calc cold: blast re-clamps complexity to 10" "COMPLEXITY_ADJ: 10" "$OUT"
check_has "calc cold: clamped complexity gives miss_risk 45" "MISS_RISK: 45" "$OUT"

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

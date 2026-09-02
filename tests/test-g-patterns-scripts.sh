#!/bin/bash
# Unit tests for skills/g-patterns/scripts/ (v2.6 prose→scripts extraction):
#   phase-gate.sh   — Step 1 routing (mine/resolve/self-heal), status census,
#                     archive-target computation (numeric suffix order)
#   corpus-scan.sh  — Step 2 corpus gate, Step 3c rework markers, Step 3d
#                     forecast-outcome signals
#   inbox-scan.sh   — Step 12 listing half (mtime order, display sanitization,
#                     portable-name flag, 50KB oversize flag)
#
# All fixtures live in throwaway mktemp dirs — the repo's own g-docs/ is
# never touched. Two §H falsifiability probes prove asserts can go red: a
# scratch copy blind to PENDING routes self-heal (Step 1 routing), and a
# window-blind scratch copy emits a distant revert (Step 3c 20-commit cutoff).
#
# Total assertions: 41
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
GATE="$REPO_ROOT/skills/g-patterns/scripts/phase-gate.sh"
CORPUS="$REPO_ROOT/skills/g-patterns/scripts/corpus-scan.sh"
INBOX="$REPO_ROOT/skills/g-patterns/scripts/inbox-scan.sh"

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

# ── phase-gate.sh ───────────────────────────────────────────────────────────

# Task 1: no report → mine
DIR=$(mktemp -d)
OUT=$(cd "$DIR" && bash "$GATE")
check_has "phase-gate: absent report reports absent" "REPORT: absent" "$OUT"
check_has "phase-gate: absent report routes mine" "ROUTE: mine" "$OUT"

# Task 2: PENDING rows → resolve, with census
mkdir -p "$DIR/g-docs/patterns"
cat > "$DIR/g-docs/patterns/latest.md" <<'EOF'
# Pattern Report — 2026-08-01

## Systemic (≥3)
- **Label:** a | **Status:** PENDING
- **Label:** b | **Status:** PENDING

## Emerging (2)
- **Label:** c | **Status:** DEFERRED

## Isolated (1)
- **Label:** d | **Sources:** 1 | **Status:** —
EOF
OUT=$(cd "$DIR" && bash "$GATE")
check_has "phase-gate: open report reported" "REPORT: open" "$OUT"
check_has "phase-gate: pending count" "PENDING: 2" "$OUT"
check_has "phase-gate: pending rows route resolve" "ROUTE: resolve" "$OUT"
check_has "phase-gate: status census" \
    "STATUS_CENSUS: pending=2 deferred=1 dismissed=0 applied=0 resolved=0 withdrawn=0 dash=1" "$OUT"
check_not "phase-gate: no archive target while pending" "ARCHIVE_TARGET:" "$OUT"

# Task 3: fully resolved (with trailing annotations from any SKILL version) → self-heal
cat > "$DIR/g-docs/patterns/latest.md" <<'EOF'
- **Label:** a | **Status:** APPLIED — refined an existing rule
- **Label:** b | **Status:** RESOLVED — no longer applicable
- **Label:** c | **Status:** WITHDRAWN — external counter-report received 2026-08-20
- **Label:** d | **Status:** DISMISSED
- **Label:** e | **Status:** —
EOF
OUT=$(cd "$DIR" && bash "$GATE")
TODAY=$(date +%Y-%m-%d)
check_has "phase-gate: resolved report routes self-heal" "ROUTE: self-heal" "$OUT"
check_has "phase-gate: annotated statuses bucketed by prefix" \
    "STATUS_CENSUS: pending=0 deferred=0 dismissed=1 applied=1 resolved=1 withdrawn=1 dash=1" "$OUT"
check_has "phase-gate: archive target uses today's date" \
    "ARCHIVE_TARGET: g-docs/patterns/$TODAY.md" "$OUT"

# Task 4: date collision — first free numeric suffix in NUMERIC order
touch "$DIR/g-docs/patterns/$TODAY.md"
for k in 2 3 4 5 6 7 8 9 10; do touch "$DIR/g-docs/patterns/$TODAY-$k.md"; done
OUT=$(cd "$DIR" && bash "$GATE")
check_has "phase-gate: numeric (not lexicographic) suffix order gives -11" \
    "ARCHIVE_TARGET: g-docs/patterns/$TODAY-11.md" "$OUT"

# Task 5: unknown status → NOTE, treated as unresolved (never self-heal)
cat > "$DIR/g-docs/patterns/latest.md" <<'EOF'
- **Label:** a | **Status:** APPLIED
- **Label:** b | **Status:** SHRUGGED
EOF
OUT=$(cd "$DIR" && bash "$GATE")
check_has "phase-gate: unknown status surfaces as NOTE" \
    "NOTE: unknown status 'SHRUGGED' — treated as unresolved" "$OUT"
check_has "phase-gate: unknown status routes resolve, never self-heal" "ROUTE: resolve" "$OUT"
rm -rf "$DIR"

# ── §H falsifiability probe — the routing assert can go red ─────────────────

DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/patterns"
printf -- '- **Label:** a | **Status:** PENDING\n' > "$DIR/g-docs/patterns/latest.md"
SCRATCH="$DIR/phase-gate-neutered.sh"
sed 's/PENDING\*)   pending=$((pending+1))/PENDING*)   applied=$((applied+1))/' "$GATE" > "$SCRATCH"
OUT_REAL=$(cd "$DIR" && bash "$GATE" | grep '^ROUTE:')
OUT_NEUT=$(cd "$DIR" && bash "$SCRATCH" | grep '^ROUTE:')
# Task 6: real routes resolve; a PENDING-blind scratch copy routes self-heal
if [ "$OUT_REAL" = "ROUTE: resolve" ] && [ "$OUT_NEUT" = "ROUTE: self-heal" ]; then
    echo "PASS: §H probe — PENDING-blind scratch copy goes red where the gate holds"
    PASS=$((PASS+1))
else
    echo "FAIL: §H probe — expected resolve vs self-heal (real='$OUT_REAL' neutered='$OUT_NEUT')"
    FAIL=$((FAIL+1))
fi
rm -rf "$DIR"

# ── corpus-scan.sh ──────────────────────────────────────────────────────────

# Task 7: thin corpus — no retros, no todo-done, no git
DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs"
OUT=$(cd "$DIR" && bash "$CORPUS")
check_has "corpus-scan: retros count 0" "RETROS: 0" "$OUT"
check_has "corpus-scan: todo-done missing" "TODO_DONE: missing" "$OUT"
check_has "corpus-scan: git commits 0 outside a repo" "GIT_COMMITS: 0" "$OUT"
check_has "corpus-scan: thin corpus" "CORPUS: thin" "$OUT"

# Task 8: partial corpus — todo-done present, retros still empty
printf 'closed tasks\n' > "$DIR/g-docs/todo-done.md"
OUT=$(cd "$DIR" && bash "$CORPUS")
check_has "corpus-scan: partial corpus" "CORPUS: partial" "$OUT"

# Task 9: ok corpus — a retro exists
mkdir -p "$DIR/g-docs/retros"
printf '## Patterns\n' > "$DIR/g-docs/retros/2026-01-01-r.md"
OUT=$(cd "$DIR" && bash "$CORPUS")
check_has "corpus-scan: ok corpus" "CORPUS: ok" "$OUT"
check_has "corpus-scan: retros counted" "RETROS: 1" "$OUT"

# Task 10: rework markers — closed set, matched case-insensitively per subject
(
    cd "$DIR" || exit 1
    git init -q
    git config user.email t@t; git config user.name t
    git commit -q --allow-empty -m "normal work"
    git commit -q --allow-empty -m "revert: broken thing"
    git commit -q --allow-empty -m "auth flow, take 2"
    git commit -q --allow-empty -m "plain feature"
)
OUT=$(cd "$DIR" && bash "$CORPUS")
check "corpus-scan: exactly 2 rework lines" "2" "$(printf '%s\n' "$OUT" | grep -c '^REWORK:')"
check_has "corpus-scan: revert marker caught with sha+subject" "revert: broken thing" \
    "$(printf '%s\n' "$OUT" | grep '^REWORK:')"
check_has "corpus-scan: take 2 marker caught" "auth flow, take 2" \
    "$(printf '%s\n' "$OUT" | grep '^REWORK:')"

# Task 10b: same-branch reverts within a 20-commit window — "This reverts
# commit <sha>" body-trailer detection, the 20-position cutoff, and dedup
# against the marker branch
(
    cd "$DIR" || exit 1
    PLAIN=$(git rev-parse HEAD)                      # "plain feature"
    for i in $(seq 1 22); do git commit -q --allow-empty -m "filler $i"; done
    git commit -q --allow-empty -m "undo distant work" -m "This reverts commit $PLAIN."
    git commit -q --allow-empty -m "introduce cache layer"
    CACHE=$(git rev-parse HEAD)
    git commit -q --allow-empty -m "back out cache layer" -m "This reverts commit $CACHE."
    git commit -q --allow-empty -m 'Revert "introduce cache layer"' -m "This reverts commit $CACHE."
)
OUT=$(cd "$DIR" && bash "$CORPUS")
check_has "corpus-scan: markerless same-branch revert caught via body trailer" \
    "back out cache layer" "$(printf '%s\n' "$OUT" | grep '^REWORK:')"
check_not "corpus-scan: revert beyond the 20-commit window not a signal" \
    "undo distant work" "$OUT"
check "corpus-scan: marker-matched revert not re-emitted by the trailer branch" "1" \
    "$(printf '%s\n' "$OUT" | grep -c 'Revert "introduce cache layer"')"
check "corpus-scan: 4 rework lines (2 markers + git-style revert + trailer)" "4" \
    "$(printf '%s\n' "$OUT" | grep -c '^REWORK:')"

# §H falsifiability probe — the 20-commit window cutoff can go red: a
# window-blind scratch copy emits the distant revert where the gate holds
SCRATCH="$DIR/corpus-scan-windowblind.sh"
sed 's/q > p && q - p <= 20/q > p/' "$CORPUS" > "$SCRATCH"
OUT_NEUT=$(cd "$DIR" && bash "$SCRATCH")
if ! printf '%s\n' "$OUT" | grep -q 'undo distant work' \
   && printf '%s\n' "$OUT_NEUT" | grep -q 'undo distant work'; then
    echo "PASS: §H probe — window-blind scratch copy goes red where the 20-commit cutoff holds"
    PASS=$((PASS+1))
else
    echo "FAIL: §H probe — expected distant revert only from the window-blind copy"
    FAIL=$((FAIL+1))
fi

# Task 11: forecast-outcome signals — yes=2, partial=1, no/blank discarded,
# label resolved from the Premortem table by rank
mkdir -p "$DIR/g-docs/forecasts"
cat > "$DIR/g-docs/forecasts/fx.md" <<'EOF'
# Forecast: FX

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | commit-without-tests | 4 | 4 | 16 | add tests | retro-a |
| 2 | stale-handoff-block | 3 | 3 | 9 | grep first | retro-b |
| 3 | layer-boundary-skip | 2 | 2 | 4 | review | retro-c |

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | **happened** (git) | |
| 2 | yes | partial (journal) | |
| 3 | yes | did not happen (git) | |
| 4 | yes | | |
EOF
OUT=$(cd "$DIR" && bash "$CORPUS")
check_has "corpus-scan: yes row weight 2 with resolved label" \
    'FORECAST_SIGNAL: file=g-docs/forecasts/fx.md scenario="commit-without-tests" outcome=yes weight=2' "$OUT"
check_has "corpus-scan: partial row weight 1" \
    'scenario="stale-handoff-block" outcome=partial weight=1' "$OUT"
check_not "corpus-scan: no row discarded" 'scenario="layer-boundary-skip"' "$OUT"
check "corpus-scan: exactly 2 forecast signals" "2" \
    "$(printf '%s\n' "$OUT" | grep -c '^FORECAST_SIGNAL:')"
rm -rf "$DIR"

# ── inbox-scan.sh ───────────────────────────────────────────────────────────

# Task 12: missing dir
DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/inbox"
OUT=$(cd "$DIR" && bash "$INBOX")
check "inbox-scan: missing dir" "INBOX: missing" "$OUT"

# Task 13: empty dir
mkdir -p "$DIR/g-docs/inbox/adversarial"
OUT=$(cd "$DIR" && bash "$INBOX")
check "inbox-scan: empty dir" "INBOX: empty" "$OUT"

# Task 14: portable file, mtime order most-recent-first, extension-blind
printf 'older\n' > "$DIR/g-docs/inbox/adversarial/counter-report.md"
touch -t 202601010000 "$DIR/g-docs/inbox/adversarial/counter-report.md"
printf 'newer drop, no extension\n' > "$DIR/g-docs/inbox/adversarial/drop2"
touch -t 202606010000 "$DIR/g-docs/inbox/adversarial/drop2"
OUT=$(cd "$DIR" && bash "$INBOX")
check_has "inbox-scan: counts regular files" "INBOX: 2" "$OUT"
check_has "inbox-scan: newest file is idx=1 (extension-less listed)" \
    "FILE: idx=1 name=drop2 portable=yes oversize=no" "$OUT"
check_has "inbox-scan: older file is idx=2" \
    "FILE: idx=2 name=counter-report.md portable=yes oversize=no" "$OUT"

# Task 15: non-portable name — flagged, display-sanitized to [A-Za-z0-9._/-]
BAD="$DIR/g-docs/inbox/adversarial/Adversarial review (REJECT) latest.md"
printf 'x\n' > "$BAD"
touch -t 202607010000 "$BAD"
OUT=$(cd "$DIR" && bash "$INBOX")
check_has "inbox-scan: non-portable flagged with sanitized display name" \
    "name=AdversarialreviewREJECTlatest.md portable=no" "$OUT"

# Task 16: name that sanitizes to nothing falls back to file #N
UGLY="$DIR/g-docs/inbox/adversarial/§§§"
printf 'x\n' > "$UGLY"
touch -t 202608010000 "$UGLY"
OUT=$(cd "$DIR" && bash "$INBOX")
check_has "inbox-scan: all-stripped name falls back to file #N" \
    "FILE: idx=1 name=file #1 portable=no" "$OUT"

# Task 17: oversize file (>50KB) flagged
rm -f "$UGLY" "$BAD"
head -c 51201 /dev/zero > "$DIR/g-docs/inbox/adversarial/big.md"
touch -t 202609010000 "$DIR/g-docs/inbox/adversarial/big.md"
OUT=$(cd "$DIR" && bash "$INBOX")
check_has "inbox-scan: oversize flagged at >51200 bytes" \
    "name=big.md portable=yes oversize=yes size=51201" "$OUT"
rm -rf "$DIR"

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

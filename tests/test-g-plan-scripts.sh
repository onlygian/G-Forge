#!/bin/bash
# Contract guard for the /g-plan helper scripts introduced by the v2.6 token
# diet (prose→scripts, mechanism 1). Each script's KEY: value output contract
# is pinned here against fixtures, including the closed-set literals the prose
# they replaced carried:
#
#   prep-dispatch.sh        TD_FILE/WP_FILE minting, slugify convention,
#                           stale-file deletion (DELETED: lines)
#   validate-task-output.sh FILE/HEADER/VERDICT lines; the '## Task List' +
#                           '| # | Task | Files | Done condition |' header
#                           contract with agents/task-decomposer.md
#   budget-check.sh         five-term formula (5/3/2/1/4), RED = 45-offset
#                           floored at 25, bands 1.0/2.0, split target 0.8,
#                           -split[0-9]+ depth detection, keyed-session-id
#                           primary depth branch (mtime fallback only when the
#                           session id is unknown; never borrows a sibling
#                           session's counter), NEW_PASS_REPORTS coefficient-
#                           staleness signal (baseline 4, fires at >= 3 new)
#   validate-waves.sh       Check 1/2 finding literals, ✓ lines, BLOCKERS/
#                           WARNINGS counts
#
# All scripts must always exit 0 — outcomes live in output, never exit codes.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/skills/g-plan/scripts"
PASS=0
FAIL=0

ok() { # name  test-cmd...
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "PASS: $name"; PASS=$((PASS+1));
    else echo "FAIL: $name"; FAIL=$((FAIL+1)); fi
}
no() { # name  test-cmd... (asserts the command does NOT succeed)
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "FAIL: $name"; FAIL=$((FAIL+1));
    else echo "PASS: $name"; PASS=$((PASS+1)); fi
}

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR" || exit 1
DATE=$(date +%Y-%m-%d)

# --- prep-dispatch.sh ----------------------------------------------------

OUT=$(bash "$SCRIPTS/prep-dispatch.sh" "Fix The Thing!"; echo "RC=$?")
ok  "prep-dispatch exits 0"                  grep -q '^RC=0$' <<<"$OUT"
ok  "prep-dispatch slugifies (lowercase, hyphens, trimmed)" \
    grep -qxF "TD_FILE: g-docs/agent-output/g-plan/task-decomposer-$DATE-fix-the-thing.md" <<<"$OUT"
ok  "prep-dispatch mints WP_FILE with the same slug" \
    grep -qxF "WP_FILE: g-docs/agent-output/g-plan/wave-planner-$DATE-fix-the-thing.md" <<<"$OUT"
ok  "prep-dispatch creates the output directory"  test -d g-docs/agent-output/g-plan
no  "prep-dispatch prints no DELETED line on a clean first run" \
    grep -q '^DELETED:' <<<"$OUT"

echo stale > "g-docs/agent-output/g-plan/task-decomposer-$DATE-fix-the-thing.md"
OUT=$(bash "$SCRIPTS/prep-dispatch.sh" "Fix The Thing!")
ok  "prep-dispatch deletes the stale same-path file and reports it" \
    grep -qxF "DELETED: g-docs/agent-output/g-plan/task-decomposer-$DATE-fix-the-thing.md" <<<"$OUT"
ok  "stale file is actually gone" \
    bash -c "! test -f 'g-docs/agent-output/g-plan/task-decomposer-$DATE-fix-the-thing.md'"

# --- validate-task-output.sh ---------------------------------------------

OUT=$(bash "$SCRIPTS/validate-task-output.sh" no-such-file.md; echo "RC=$?")
ok  "validate-task-output exits 0 on missing file"      grep -q '^RC=0$' <<<"$OUT"
ok  "missing file -> FILE: missing + VERDICT: failed" \
    bash -c 'grep -qx "FILE: missing" <<<"$1" && grep -qx "VERDICT: failed" <<<"$1"' _ "$OUT"

: > empty.md
OUT=$(bash "$SCRIPTS/validate-task-output.sh" empty.md)
ok  "empty file -> FILE: empty + VERDICT: failed" \
    bash -c 'grep -qx "FILE: empty" <<<"$1" && grep -qx "VERDICT: failed" <<<"$1"' _ "$OUT"

cat > good.md <<'EOF'
## Task List

| # | Task | Files | Done condition |
|---|------|-------|----------------|
| 1 | do a thing | a.sh | test passes |
EOF
OUT=$(bash "$SCRIPTS/validate-task-output.sh" good.md)
ok  "well-formed file -> FILE: exists, HEADER: ok, VERDICT: structural-pass" \
    bash -c 'grep -qx "FILE: exists" <<<"$1" && grep -qx "HEADER: ok" <<<"$1" && grep -qx "VERDICT: structural-pass" <<<"$1"' _ "$OUT"

printf 'some prose, no table\n' > headerless.md
OUT=$(bash "$SCRIPTS/validate-task-output.sh" headerless.md)
ok  "missing header -> HEADER: missing + VERDICT: failed" \
    bash -c 'grep -qx "HEADER: missing" <<<"$1" && grep -qx "VERDICT: failed" <<<"$1"' _ "$OUT"

# --- budget-check.sh -----------------------------------------------------

mkdir -p .claude
printf '10' > .claude/session-prompt-count.test-session

# 4 waves, 6 agents, 7 tasks: 5 + 12 + 12 + 7 + 28 = 64; red 45, depth 10 -> M=35 -> tight
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 4 --agents 6 --tasks 7; echo "RC=$?")
ok  "budget-check exits 0"                       grep -q '^RC=0$' <<<"$OUT"
ok  "five-term formula: 4w/6a/7t -> ESTIMATED: 64"   grep -qx "ESTIMATED: 64" <<<"$OUT"
ok  "depth read from keyed counter"                  grep -qx "DEPTH: 10" <<<"$OUT"
ok  "red threshold 45 with no offset"                grep -qx "RED: 45" <<<"$OUT"
ok  "remaining = red - depth"                        grep -qx "REMAINING: 35" <<<"$OUT"
ok  "64 in (35, 70] -> VERDICT: tight"               grep -qx "VERDICT: tight" <<<"$OUT"
ok  "split target floor(35*0.8) = 28"                grep -qx "SPLIT_TARGET: 28" <<<"$OUT"
ok  "no --id -> SPLIT_DEPTH: 0"                      grep -qx "SPLIT_DEPTH: 0" <<<"$OUT"

# fine band: 2 waves, 2 agents, 2 tasks: 5+6+4+2+8 = 25 <= 35
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 2 --agents 2 --tasks 2)
ok  "estimate at/under remaining -> VERDICT: fine"   grep -qx "VERDICT: fine" <<<"$OUT"

# exceeded band: 5 waves, 8 agents, 20 tasks: 5+15+16+20+80 = 136 > 70
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 5 --agents 8 --tasks 20)
ok  "estimate over 2x remaining -> VERDICT: exceeded" grep -qx "VERDICT: exceeded" <<<"$OUT"

# split-depth: -split suffix mid-slug must still match (not end-anchored)
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1 --id M47-split1-auth)
ok  "-split1 mid-identifier -> SPLIT_DEPTH: 1"       grep -qx "SPLIT_DEPTH: 1" <<<"$OUT"
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1 --id M47-plain)
ok  "no -split suffix -> SPLIT_DEPTH: 0"             grep -qx "SPLIT_DEPTH: 0" <<<"$OUT"

# offset floors at 25 (45 - 30 = 15 -> floor 25)
printf '30' > .claude/context-threshold-offset
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1)
ok  "offset 30 floors red at 25"                     grep -qx "RED: 25" <<<"$OUT"
rm -f .claude/context-threshold-offset

# no counter -> depth 0 with a NOTE
rm -f .claude/session-prompt-count.test-session
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1)
ok  "no counter -> DEPTH: 0 and a NOTE line" \
    bash -c 'grep -qx "DEPTH: 0" <<<"$1" && grep -q "^NOTE: " <<<"$1"' _ "$OUT"

# keyed-session primary branch: the current session's counter wins even when a
# sibling session's counter is more recently modified
printf '10' > .claude/session-prompt-count.mysess
printf '30' > .claude/session-prompt-count.other
touch -d '2030-01-01 00:00:00' .claude/session-prompt-count.other
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1 --session mysess)
ok  "--session prefers the keyed counter over a newer sibling" \
    grep -qx "DEPTH: 10" <<<"$OUT"

# session id unknown -> mtime fallback picks the newest match
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1)
ok  "no --session -> mtime fallback picks the newest counter" \
    grep -qx "DEPTH: 30" <<<"$OUT"

# session id known but its keyed file is missing -> depth 0, never borrows a
# sibling session's counter (conservative, mirrors sync-check.sh)
rm -f .claude/session-prompt-count.mysess
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1 --session mysess)
ok  "known session with no keyed counter -> DEPTH: 0 + never-borrow NOTE" \
    bash -c 'grep -qx "DEPTH: 0" <<<"$1" && grep -q "^NOTE: no counter for session .mysess. — never borrowing" <<<"$1"' _ "$OUT"
rm -f .claude/session-prompt-count.other

# coefficient staleness: no todo-done.md -> counts 0/0, no stale NOTE
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1)
ok  "no todo-done.md -> PASS_REPORTS: 0 + NEW_PASS_REPORTS: 0" \
    bash -c 'grep -qx "PASS_REPORTS: 0" <<<"$1" && grep -qx "NEW_PASS_REPORTS: 0" <<<"$1"' _ "$OUT"
no  "no stale-coefficient NOTE without new pass reports" \
    grep -q "re-derivation duty" <<<"$OUT"

# 6 markers = 2 beyond the baseline of 4 -> still quiet (RED probe: boundary)
mkdir -p g-docs
{ for i in 1 2 3; do printf '**Pass report (2026-0%s-01):** x\n' "$i"; done
  for i in 1 2 3; do printf '## Pass report — 2026-0%s-02 — y\n' "$i"; done
} > g-docs/todo-done.md
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1)
ok  "6 markers vs baseline 4 -> NEW_PASS_REPORTS: 2" \
    bash -c 'grep -qx "PASS_REPORTS: 6" <<<"$1" && grep -qx "NEW_PASS_REPORTS: 2" <<<"$1"' _ "$OUT"
no  "2 new pass reports stay below the 3-report trigger" \
    grep -q "re-derivation duty" <<<"$OUT"

# 7 markers = 3 beyond baseline -> staleness NOTE fires
printf '**Pass report (2026-09-01):** z\n' >> g-docs/todo-done.md
OUT=$(bash "$SCRIPTS/budget-check.sh" --waves 1 --agents 1 --tasks 1)
ok  "3 new pass reports -> NEW_PASS_REPORTS: 3 + re-derivation NOTE" \
    bash -c 'grep -qx "NEW_PASS_REPORTS: 3" <<<"$1" && grep -qF "NOTE: 3+ pass reports newer than the coefficient" <<<"$1"' _ "$OUT"
rm -f g-docs/todo-done.md

# --- validate-waves.sh ---------------------------------------------------

mkdir -p g-docs/plans src
printf 'x\n' > src/exists.sh

cat > g-docs/plans/.pending-forecast.md <<'EOF'
# Plan: Fixture

> Created: 2026-09-02

## Tasks

| # | Task | Scope | Done condition |
|---|------|-------|----------------|
| 1 | update src/exists.sh helper | src/exists.sh | ok |
| 2 | edit src/exists.sh again | src/exists.sh | ok |
| 3 | modify src/ghost.sh | src/ghost.sh | ok |

## Wave Schedule

### Wave 1
- Task 1 — update src/exists.sh helper (agent: feature-implementer)
- Task 2 — edit src/exists.sh again (agent: feature-implementer)

### Wave 2
- Task 3 — modify src/ghost.sh (agent: feature-implementer)

## Progress

| Wave | Status | Notes |
|------|--------|-------|
| 1 | pending | |
| 2 | pending | |
EOF

OUT=$(bash "$SCRIPTS/validate-waves.sh" g-docs/plans/.pending-forecast.md; echo "RC=$?")
ok  "validate-waves exits 0"                         grep -q '^RC=0$' <<<"$OUT"
ok  "Check 1 conflict literal with wave, tasks, file" \
    grep -qF "⚠ Parallel write conflict — Wave 1: update src/exists.sh helper and edit src/exists.sh again both scope src/exists.sh" <<<"$OUT"
ok  "Check 2 missing-source literal"  \
    grep -qF "✗ Missing source — modify src/ghost.sh: src/ghost.sh does not exist and no prior wave creates it" <<<"$OUT"
ok  "conflict + missing -> BLOCKERS: 2"              grep -qx "BLOCKERS: 2" <<<"$OUT"
ok  "script-level WARNINGS: 0 (Check 3 is model judgment)" grep -qx "WARNINGS: 0" <<<"$OUT"

cat > g-docs/plans/.pending-forecast.md <<'EOF'
# Plan: Clean fixture

## Tasks

| # | Task | Scope | Done condition |
|---|------|-------|----------------|
| 1 | create src/new.sh | src/new.sh | ok |
| 2 | update src/new.sh | src/new.sh | ok |
| 3 | update src/exists.sh | src/exists.sh | ok |

## Wave Schedule

### Wave 1
- Task 1 — create src/new.sh (agent: feature-implementer)

### Wave 2
- Task 2 — update src/new.sh (agent: feature-implementer)
- Task 3 — update src/exists.sh (agent: test-writer)

## Progress

| Wave | Status | Notes |
|------|--------|-------|
| 1 | pending | |
| 2 | pending | |
EOF

OUT=$(bash "$SCRIPTS/validate-waves.sh" g-docs/plans/.pending-forecast.md)
ok  "clean plan -> ✓ No parallel write conflicts" \
    grep -qF "✓ No parallel write conflicts" <<<"$OUT"
ok  "creation-ordered missing file is cleared (✓ line)" \
    grep -qF "✓ All source files present (or creation-ordered)" <<<"$OUT"
ok  "clean plan -> BLOCKERS: 0"                      grep -qx "BLOCKERS: 0" <<<"$OUT"

# bare extensionless scopes: on-disk files (Makefile) are checked like any
# path; a bare token not on disk is skipped with a NOTE, never silently
touch Makefile
cat > g-docs/plans/.pending-forecast.md <<'EOF'
# Plan: Bare-scope fixture

## Tasks

| # | Task | Scope | Done condition |
|---|------|-------|----------------|
| 1 | update Makefile targets | Makefile | ok |
| 2 | edit Makefile again | Makefile | ok |
| 3 | modify Dockerfile | Dockerfile | ok |

## Wave Schedule

### Wave 1
- Task 1 — update Makefile targets (agent: feature-implementer)
- Task 2 — edit Makefile again (agent: feature-implementer)

### Wave 2
- Task 3 — modify Dockerfile (agent: feature-implementer)
EOF

OUT=$(bash "$SCRIPTS/validate-waves.sh" g-docs/plans/.pending-forecast.md)
ok  "bare extensionless on-disk file -> Check 1 conflict flagged" \
    grep -qF "⚠ Parallel write conflict — Wave 1: update Makefile targets and edit Makefile again both scope Makefile" <<<"$OUT"
ok  "bare token not on disk -> skipped with a NOTE" \
    grep -qF "NOTE: scope token 'Dockerfile' has no '/' or '.' and is not on disk" <<<"$OUT"
ok  "skipped bare token is not a blocker -> BLOCKERS: 1" \
    grep -qx "BLOCKERS: 1" <<<"$OUT"
rm -f Makefile

OUT=$(bash "$SCRIPTS/validate-waves.sh" no-such-plan.md; echo "RC=$?")
ok  "missing plan file -> NOTE + exit 0" \
    bash -c 'grep -q "^RC=0$" <<<"$1" && grep -q "^NOTE: plan file missing" <<<"$1"' _ "$OUT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

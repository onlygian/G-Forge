#!/bin/bash
# Contract guard for the /g-execute helper scripts introduced by the v2.6 token
# diet (prose→scripts, mechanism 1):
#
#   telemetry-profile.sh  profile normalization (fail-OPEN to stable — a script
#                         error must never serialize waves), WAVE_CAP none|3|1,
#                         per-lane MODEL_BUMP bounds (v2.6 model economy:
#                         mechanical lane never inflates to opus), the two
#                         byte-frozen CLAUSE literals appended to agent
#                         prompts, and the cautious not-wired-as-shipped
#                         disclosure (M52 freeze).
#   locate-plan.sh        plan location order (dotfiles skipped), Progress-table
#                         parse, starting-wave rules 1-4, and the user-facing
#                         message literals carried in NOTE: lines.
#
# Both scripts must always exit 0 — outcomes live in output, never exit codes.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/skills/g-execute/scripts"
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

# --- telemetry-profile.sh ------------------------------------------------

OUT=$(bash "$SCRIPTS/telemetry-profile.sh"; echo "RC=$?")
ok  "no profile file -> PROFILE: stable (fail-open) + exit 0" \
    bash -c 'grep -q "^RC=0$" <<<"$1" && grep -qx "PROFILE: stable" <<<"$1"' _ "$OUT"
ok  "stable -> WAVE_CAP: none, MODEL_BUMP: none, CLAUSE: none" \
    bash -c 'grep -qx "WAVE_CAP: none" <<<"$1" && grep -qx "MODEL_BUMP: none" <<<"$1" && grep -qx "CLAUSE: none" <<<"$1"' _ "$OUT"

mkdir -p .claude
printf 'garbage-value\n' > .claude/telemetry-profile
OUT=$(bash "$SCRIPTS/telemetry-profile.sh")
ok  "malformed profile normalizes to stable"         grep -qx "PROFILE: stable" <<<"$OUT"

printf 'cautious\n' > .claude/telemetry-profile
OUT=$(bash "$SCRIPTS/telemetry-profile.sh")
ok  "cautious -> no cap, no bump" \
    bash -c 'grep -qx "PROFILE: cautious" <<<"$1" && grep -qx "WAVE_CAP: none" <<<"$1" && grep -qx "MODEL_BUMP: none" <<<"$1"' _ "$OUT"
ok  "cautious carries the not-wired-as-shipped disclosure (M52 freeze)" \
    grep -qxF "NOTE: cautious — /g-review reviewer adjustment not wired as shipped (skills/g-review/SKILL.md Step 0 note)" <<<"$OUT"

printf 'defensive\n' > .claude/telemetry-profile
OUT=$(bash "$SCRIPTS/telemetry-profile.sh")
ok  "defensive -> WAVE_CAP: 3"                       grep -qx "WAVE_CAP: 3" <<<"$OUT"
ok  "defensive bump is per-lane, mechanical excluded" \
    grep -qxF "MODEL_BUMP: one-tier — judgment/diagnostic/spec-executor lanes; mechanical lane no bump" <<<"$OUT"
ok  "defensive clause literal byte-identical" \
    grep -qxF "CLAUSE: Telemetry profile: defensive. Be extra strict about scope boundaries." <<<"$OUT"

printf 'recovery\n' > .claude/telemetry-profile
OUT=$(bash "$SCRIPTS/telemetry-profile.sh")
ok  "recovery -> WAVE_CAP: 1 (force serial)"         grep -qx "WAVE_CAP: 1" <<<"$OUT"
ok  "recovery bump caps mechanical at haiku-to-sonnet (never opus)" \
    grep -qxF "MODEL_BUMP: one-tier — non-mechanical lanes; mechanical haiku-to-sonnet at most" <<<"$OUT"
ok  "recovery clause literal byte-identical" \
    grep -qxF "CLAUSE: Telemetry profile: recovery. Verify every file path before writing. Surface uncertainty immediately." <<<"$OUT"
no  "recovery no longer prescribes opus on every dispatch" \
    grep -qi "opus on every dispatch" <<<"$OUT"
rm -f .claude/telemetry-profile

# --- locate-plan.sh ------------------------------------------------------

OUT=$(bash "$SCRIPTS/locate-plan.sh" ""; echo "RC=$?")
ok  "no plans at all -> EXIT: no-plan + exit 0" \
    bash -c 'grep -q "^RC=0$" <<<"$1" && grep -qx "EXIT: no-plan" <<<"$1"' _ "$OUT"
ok  "no-plan message literal preserved" \
    grep -qxF "NOTE: No plan file found. Run /g-plan first, or pass the plan file path as an argument." <<<"$OUT"

mkdir -p g-docs/plans
plan() { # path  s1 s2 s3
    cat > "$1" <<EOF
# Plan: Fixture

## Tasks

| # | Task | Scope | Done condition |
|---|------|-------|----------------|
| 1 | a | x | ok |

## Wave Schedule

### Wave 1
- Task 1 — a (agent: feature-implementer)

## Progress

| Wave | Status | Notes |
|------|--------|-------|
| 1 | $2 | |
| 2 | $3 | |
| 3 | $4 | |
EOF
}

plan g-docs/plans/feature.md pending pending pending
OUT=$(bash "$SCRIPTS/locate-plan.sh" "")
ok  "newest plan located"                            grep -qx "PLAN: g-docs/plans/feature.md" <<<"$OUT"
ok  "all pending -> START_WAVE: 1, CONFIRM: no" \
    bash -c 'grep -qx "START_WAVE: 1" <<<"$1" && grep -qx "CONFIRM: no" <<<"$1"' _ "$OUT"
ok  "WAVE rows echoed with statuses"                 grep -qx "WAVE: 1 pending" <<<"$OUT"

plan g-docs/plans/feature.md complete complete complete
OUT=$(bash "$SCRIPTS/locate-plan.sh" "")
ok  "all complete -> ALL_COMPLETE: yes"              grep -qx "ALL_COMPLETE: yes" <<<"$OUT"
ok  "all-complete message literal preserved" \
    grep -qxF "NOTE: All waves already complete. Run /g-review." <<<"$OUT"

plan g-docs/plans/feature.md complete "in progress" pending
OUT=$(bash "$SCRIPTS/locate-plan.sh" "")
ok  "in-progress wave is the candidate and requires confirmation" \
    bash -c 'grep -qx "START_WAVE: 2" <<<"$1" && grep -qx "CONFIRM: yes" <<<"$1"' _ "$OUT"

plan g-docs/plans/feature.md complete complete pending
OUT=$(bash "$SCRIPTS/locate-plan.sh" "")
ok  "complete/pending mix resumes at first non-complete, no confirmation" \
    bash -c 'grep -qx "START_WAVE: 3" <<<"$1" && grep -qx "CONFIRM: no" <<<"$1"' _ "$OUT"
ok  "resume announce literal (rule 4)" \
    grep -qxF "NOTE: Resuming from Wave 3 (Wave 1–2 complete)." <<<"$OUT"

OUT=$(bash "$SCRIPTS/locate-plan.sh" 2)
ok  "numeric argument forces the starting wave, no confirmation" \
    bash -c 'grep -qx "START_WAVE: 2" <<<"$1" && grep -qx "CONFIRM: no" <<<"$1"' _ "$OUT"

plan g-docs/plans/other.md pending pending pending
OUT=$(bash "$SCRIPTS/locate-plan.sh" "g-docs/plans/feature.md")
ok  "explicit path argument wins over mtime order"   grep -qx "PLAN: g-docs/plans/feature.md" <<<"$OUT"

rm -f g-docs/plans/feature.md g-docs/plans/other.md
printf '# temp\n' > g-docs/plans/.pending-forecast.md
OUT=$(bash "$SCRIPTS/locate-plan.sh" "")
ok  "a leftover .pending-forecast.md is never picked as the plan" \
    bash -c 'grep -qx "EXIT: no-plan" <<<"$1" && ! grep -q "PLAN: g-docs/plans/.pending-forecast.md" <<<"$1"' _ "$OUT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

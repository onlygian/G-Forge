#!/bin/bash
# Agent-lifecycle eventing suite — tests hook behaviors: wt-tagging on linked
# worktrees, light-tier journal suppression while log remains written, and
# start/stop event pairing in day-files. Non-gating contract: exit 0 always.
#
# Behaviors tested:
# 1. PRIMARY-TREE mode (IS_LINKED_WORKTREE=0): log + journal written WITHOUT "wt" field
# 2. LINKED-WORKTREE mode (IS_LINKED_WORKTREE=1): log + journal written WITH "wt" field
#    and "wt" value = the linked worktree's absolute --show-toplevel path
# 3. LIGHT-TIER mode (integration-tier="light"): journal SUPPRESSED, log STILL written
# 4. START/STOP PAIRING: start event + stop event for the same agent_id land in
#    the same day-file (.claude/journal/YYYY-MM-DD.jsonl) with matching detail format
# 5. EXIT CODE: hook exits 0 on all payloads (representative + garbage)
# 6. JSON VALIDITY: both log lines (.claude/g-forge-agent-log.jsonl) and journal lines
#    (.claude/journal/YYYY-MM-DD.jsonl) are well-formed JSON objects
# 7. CONTROL-CHAR ESCAPING (M-audit W3 sub-task 7): json_escape() strips the full C0
#    control-char range, not just CR/LF -- a validly-escaped JSON control-char
#    agent_type / last_assistant_message must never leave a raw control byte in the
#    emitted log or journal line
# 8. TIER-GATING IDIOM ALIGNMENT (M-audit W3 sub-task 8): agent-lifecycle's light-tier
#    check matches observe.sh's reference idiom across every integration-tier file
#    state (missing, "light", "light\n", "full") — journal-suppression outcome agrees
#    with observe.sh for each state
# 9. EMPTY/NULL JQ GUARD: jq's zero-invocation empty-stdin behavior (rc 0, no output)
#    never lets an empty payload masquerade as a real empty value ("unknown", not
#    "internal"); explicit JSON null agent_type/agent_id fields degrade the same way.
#    A scratch-only stub jq is put on PATH for this section since this runner has no
#    real jq installed, so the guarded code path is exercised deterministically.
#
# Total assertions: 42 (5 primary-tree + 6 linked-worktree wt-tagging + 5 light-tier +
#                       7 start/stop pairing + 4 exit-code invariant + 2 JSON validity +
#                       2 control-char escaping + 4 tier-gating idiom alignment +
#                       7 empty/null jq guard)
# jq-gated strict-parse checks (control-char section) are SKIP-credited 0 when jq is
# unavailable, per the same convention as the linked-worktree SKIP below — the count
# above is this environment's runner-observed total (jq absent), not a design ceiling.
# The count is the RUNNER-OBSERVED total, not a design target — it must equal the
# `Results:` line. A header that over-claims defeats the finding-#20 cross-check,
# which exists precisely to catch a suite silently dropping cases.

# Resolve script dir and hooks dir to ABSOLUTE paths exactly once, before any
# fixture cd. Relative $0 (as invoked from repo root) would otherwise break
# `dirname "$0"` after the sandbox cd below (W1.5g invocation-form-insensitive fix).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/../hooks" && pwd)"
SCRIPT="$HOOKS_DIR/agent-lifecycle.sh"

PASS=0
FAIL=0

# Helper: run the hook with stdin payload, event type, and return rc + outputs.
# Usage: hook_run <event> <payload> [fixture-path]
# Returns exit code and optionally writes log/journal to fixture.
hook_run() {
    local event="$1" payload="$2" fixture_path="${3:-.}"
    (
        cd "$fixture_path" || return 1
        printf '%s' "$payload" | bash "$SCRIPT" "$event" 2>&1
    )
    return $?
}

# Helper: extract JSON field from a line using sed (no jq dependency).
extract_json_field() {
    local line="$1" field="$2"
    sed -n "s/.*\"$field\":\s*\"\([^\"]*\)\".*/\1/p" <<< "$line"
}

# ============================================================================
# § 0. Sandbox setup (primary and linked-worktree tests use separate fixtures)
# ============================================================================

# Primary tree fixture (no worktree setup)
PRIMARY_FIXTURE="$(mktemp -d)"
cd "$PRIMARY_FIXTURE" || { echo "FAIL: could not create primary fixture"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

# Linked-worktree fixture (will create a linked worktree if git supports it)
WORKTREE_FIXTURE="$(mktemp -d)"
WORKTREE_PRIMARY="$WORKTREE_FIXTURE/primary"
WORKTREE_LINKED="$WORKTREE_FIXTURE/linked-wt"

# Cleanup trap: remove both fixtures
cleanup_trap() {
    cd / || true
    # Clean up linked worktrees before removing dirs (git worktree remove requires explicit cleanup)
    if [ -d "$WORKTREE_PRIMARY/.git" ]; then
        (
            cd "$WORKTREE_PRIMARY" 2>/dev/null || true
            git worktree list --porcelain 2>/dev/null | while read line; do
                case "$line" in
                    worktree\ *)
                        wt_path="${line#worktree }"
                        git worktree remove --force "$wt_path" 2>/dev/null || true
                        ;;
                esac
            done
        ) || true
    fi
    rm -rf "$PRIMARY_FIXTURE" "$WORKTREE_FIXTURE"
}
trap cleanup_trap EXIT

# ============================================================================
# § 1. Test helper: fixture setup for primary tree
# ============================================================================

setup_primary_fixture() {
    # Already done above; this is a placeholder for consistency.
    :
}

# ============================================================================
# § 2. Test helper: fixture setup for linked worktree (if supported)
# ============================================================================

setup_linked_worktree_fixture() {
    # Create primary repo at an absolute path with G-Forge guard
    mkdir -p "$WORKTREE_PRIMARY" || return 1
    (
        cd "$WORKTREE_PRIMARY"
        git init -q || return 1
        git config user.email "test@g-forge.local" || return 1
        git config user.name "test" || return 1
        mkdir -p .claude
        printf 'full\n' > .claude/integration-tier
        touch .gitkeep
        git add .gitkeep || return 1
        git -c commit.gpgsign=false commit -m "initial" >/dev/null 2>&1 || return 1
    ) || return 1

    # Create a linked worktree
    (
        cd "$WORKTREE_PRIMARY"
        git worktree add -b "wt-test" "$WORKTREE_LINKED" >/dev/null 2>&1 || return 1
    ) || return 1

    # Verify the linked worktree was created successfully. In a linked worktree
    # .git is a FILE (a `gitdir:` pointer), never a directory — test existence, not -d.
    [ -e "$WORKTREE_LINKED/.git" ] || return 1
}

# ============================================================================
# § 3. PRIMARY-TREE wt-tagging tests (no "wt" field expected)
# ============================================================================

# Test 3.1: start event in primary tree — no "wt" field in log
PAYLOAD_START='{"agent_type":"test-agent","agent_id":"a1234567890abc","hook_event_name":"SubagentStart"}'
hook_run "start" "$PAYLOAD_START" "$PRIMARY_FIXTURE" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
    echo "PASS: start event in primary tree — exit 0"; PASS=$((PASS+1))
else
    echo "FAIL: start event in primary tree — exit $rc (expected 0)"; FAIL=$((FAIL+1))
fi

LOG_FILE="$PRIMARY_FIXTURE/.claude/g-forge-agent-log.jsonl"
if [ -f "$LOG_FILE" ]; then
    echo "PASS: start event in primary tree — log file created"; PASS=$((PASS+1))
    # Check that log line does NOT contain "wt" field
    if grep -q '"wt"' "$LOG_FILE"; then
        echo "FAIL: start event in primary tree — log contains unexpected 'wt' field"; FAIL=$((FAIL+1))
    else
        echo "PASS: start event in primary tree — log does not contain 'wt' field"; PASS=$((PASS+1))
    fi
else
    echo "FAIL: start event in primary tree — log file not created"; FAIL=$((FAIL+1))
fi

# Test 3.2: stop event in primary tree — no "wt" field in log
PAYLOAD_STOP='{"agent_type":"test-agent","agent_id":"a1234567890abc","hook_event_name":"SubagentStop","last_assistant_message":"RESULT: DONE\nSUMMARY: test"}'
hook_run "stop" "$PAYLOAD_STOP" "$PRIMARY_FIXTURE" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
    echo "PASS: stop event in primary tree — exit 0"; PASS=$((PASS+1))
else
    echo "FAIL: stop event in primary tree — exit $rc (expected 0)"; FAIL=$((FAIL+1))
fi

if [ -f "$LOG_FILE" ]; then
    if grep -q '"wt"' "$LOG_FILE"; then
        echo "FAIL: stop event in primary tree — log contains unexpected 'wt' field"; FAIL=$((FAIL+1))
    else
        echo "PASS: stop event in primary tree — log does not contain 'wt' field"; PASS=$((PASS+1))
    fi
fi

# ============================================================================
# § 4. LINKED-WORKTREE wt-tagging tests (WITH "wt" field expected)
# ============================================================================

if setup_linked_worktree_fixture; then
    # Test 4.1: start event in linked worktree — "wt" field present and correct
    hook_run "start" "$PAYLOAD_START" "$WORKTREE_LINKED" >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "PASS: start event in linked worktree — exit 0"; PASS=$((PASS+1))
    else
        echo "FAIL: start event in linked worktree — exit $rc (expected 0)"; FAIL=$((FAIL+1))
    fi

    WT_LOG_FILE="$WORKTREE_PRIMARY/.claude/g-forge-agent-log.jsonl"
    if [ -f "$WT_LOG_FILE" ]; then
        echo "PASS: start event in linked worktree — log file created (at primary)"; PASS=$((PASS+1))
        # Check that log line CONTAINS "wt" field
        if grep -q '"wt"' "$WT_LOG_FILE"; then
            echo "PASS: start event in linked worktree — log contains 'wt' field"; PASS=$((PASS+1))
            # Verify the wt value identifies the linked worktree. Compare against the
            # key the hook actually derives (`rev-parse --show-toplevel`, per ADR-005),
            # NOT the raw mktemp path: on Windows git-bash show-toplevel returns the
            # native spelling (C:/Users/...) while mktemp -d returns the MSYS one
            # (/tmp/...) — same directory, two spellings, and a raw compare false-fails.
            WT_EXPECTED_KEY=$(git -C "$WORKTREE_LINKED" rev-parse --show-toplevel 2>/dev/null)
            if [ -n "$WT_EXPECTED_KEY" ] && grep -qF "$WT_EXPECTED_KEY" "$WT_LOG_FILE"; then
                echo "PASS: start event in linked worktree — 'wt' field value is correct"; PASS=$((PASS+1))
            else
                echo "FAIL: start event in linked worktree — 'wt' field value does not match worktree path"; FAIL=$((FAIL+1))
            fi
        else
            echo "FAIL: start event in linked worktree — log does not contain 'wt' field"; FAIL=$((FAIL+1))
        fi
    else
        echo "FAIL: start event in linked worktree — log file not created"; FAIL=$((FAIL+1))
    fi

    # Test 4.2: stop event in linked worktree — "wt" field present
    hook_run "stop" "$PAYLOAD_STOP" "$WORKTREE_LINKED" >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "PASS: stop event in linked worktree — exit 0"; PASS=$((PASS+1))
    else
        echo "FAIL: stop event in linked worktree — exit $rc (expected 0)"; FAIL=$((FAIL+1))
    fi

    if [ -f "$WT_LOG_FILE" ]; then
        if grep -q '"wt"' "$WT_LOG_FILE"; then
            echo "PASS: stop event in linked worktree — log contains 'wt' field"; PASS=$((PASS+1))
        else
            echo "FAIL: stop event in linked worktree — log does not contain 'wt' field"; FAIL=$((FAIL+1))
        fi
    fi
else
    # Linked worktree setup failed (git version too old or unsupported). A skip credits
    # NO passes — counting unrun assertions as green is the false-green trap W1.5b pinned.
    # The uncounted SKIP line makes the coverage gap visible in the runner output instead.
    echo "SKIP: linked worktree tests — git worktree not available (0 assertions credited)"
fi

# ============================================================================
# § 5. LIGHT-TIER journal suppression tests
# ============================================================================

LIGHT_FIXTURE="$(mktemp -d)"
cd "$LIGHT_FIXTURE" || { echo "FAIL: could not create light-tier fixture"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null
mkdir -p .claude
printf 'light\n' > .claude/integration-tier  # Set tier to 'light'

# Test 5.1: start event on light tier — log written, journal NOT written
hook_run "start" "$PAYLOAD_START" "$LIGHT_FIXTURE" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
    echo "PASS: start event on light tier — exit 0"; PASS=$((PASS+1))
else
    echo "FAIL: start event on light tier — exit $rc (expected 0)"; FAIL=$((FAIL+1))
fi

LIGHT_LOG_FILE="$LIGHT_FIXTURE/.claude/g-forge-agent-log.jsonl"
if [ -f "$LIGHT_LOG_FILE" ]; then
    echo "PASS: start event on light tier — log file created"; PASS=$((PASS+1))
else
    echo "FAIL: start event on light tier — log file not created"; FAIL=$((FAIL+1))
fi

LIGHT_JOURNAL_DIR="$LIGHT_FIXTURE/.claude/journal"
if [ -d "$LIGHT_JOURNAL_DIR" ]; then
    LIGHT_JOURNAL_FILE=$(ls "$LIGHT_JOURNAL_DIR"/*.jsonl 2>/dev/null | head -1)
    if [ -z "$LIGHT_JOURNAL_FILE" ]; then
        echo "PASS: start event on light tier — journal directory exists but no files (suppressed)"; PASS=$((PASS+1))
    else
        echo "FAIL: start event on light tier — journal file should not exist in light tier"; FAIL=$((FAIL+1))
    fi
else
    # Journal dir doesn't exist at all — journal was completely suppressed
    echo "PASS: start event on light tier — journal directory not created (suppressed)"; PASS=$((PASS+1))
fi

# Test 5.2: stop event on light tier — log written, journal NOT written
hook_run "stop" "$PAYLOAD_STOP" "$LIGHT_FIXTURE" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
    echo "PASS: stop event on light tier — exit 0"; PASS=$((PASS+1))
else
    echo "FAIL: stop event on light tier — exit $rc (expected 0)"; FAIL=$((FAIL+1))
fi

if [ -f "$LIGHT_LOG_FILE" ]; then
    # Count lines in log — should have 2 (start + stop)
    line_count=$(wc -l < "$LIGHT_LOG_FILE")
    if [ "$line_count" -eq 2 ]; then
        echo "PASS: stop event on light tier — log has 2 events (start + stop)"; PASS=$((PASS+1))
    else
        echo "FAIL: stop event on light tier — log has $line_count lines (expected 2)"; FAIL=$((FAIL+1))
    fi
fi

# Cleanup light-tier fixture
cd / || true
rm -rf "$LIGHT_FIXTURE"

# ============================================================================
# § 6. START/STOP event pairing tests
# ============================================================================

PAIR_FIXTURE="$(mktemp -d)"
cd "$PAIR_FIXTURE" || { echo "FAIL: could not create pairing fixture"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

# Fire start event
hook_run "start" "$PAYLOAD_START" "$PAIR_FIXTURE" >/dev/null 2>&1

# Fire stop event
hook_run "stop" "$PAYLOAD_STOP" "$PAIR_FIXTURE" >/dev/null 2>&1

# Test 6.1: both events in the same day-file
PAIR_JOURNAL_DIR="$PAIR_FIXTURE/.claude/journal"
if [ -d "$PAIR_JOURNAL_DIR" ]; then
    PAIR_JOURNAL_FILES=$(ls "$PAIR_JOURNAL_DIR"/*.jsonl 2>/dev/null | wc -l)
    if [ "$PAIR_JOURNAL_FILES" -eq 1 ]; then
        echo "PASS: start/stop pairing — both events in single day-file"; PASS=$((PASS+1))
    else
        echo "FAIL: start/stop pairing — expected 1 journal file, got $PAIR_JOURNAL_FILES"; FAIL=$((FAIL+1))
    fi

    # Resolve the day-file by listing, not by assigning a glob: a glob in an
    # assignment is NOT expanded, so `[ -f "<dir>/*.jsonl" ]` tests a literal
    # asterisk path, is always false, and silently skips every assertion below it.
    PAIR_JOURNAL_FILE=$(ls "$PAIR_JOURNAL_DIR"/*.jsonl 2>/dev/null | head -1)
    if [ -n "$PAIR_JOURNAL_FILE" ] && [ -f "$PAIR_JOURNAL_FILE" ]; then
        # Check that file has exactly 2 lines (start + stop)
        line_count=$(wc -l < "$PAIR_JOURNAL_FILE")
        if [ "$line_count" -eq 2 ]; then
            echo "PASS: start/stop pairing — day-file has 2 events"; PASS=$((PASS+1))
        else
            echo "FAIL: start/stop pairing — day-file has $line_count events (expected 2)"; FAIL=$((FAIL+1))
        fi

        # Test 6.2: verify start event line
        START_LINE=$(sed -n '1p' "$PAIR_JOURNAL_FILE")
        if echo "$START_LINE" | grep -q '"kind":"agent"'; then
            echo "PASS: start/stop pairing — start event has kind='agent'"; PASS=$((PASS+1))
        else
            echo "FAIL: start/stop pairing — start event missing kind='agent'"; FAIL=$((FAIL+1))
        fi

        if echo "$START_LINE" | grep -q '"detail":"test-agent start a1234567'; then
            echo "PASS: start/stop pairing — start event detail correct"; PASS=$((PASS+1))
        else
            echo "FAIL: start/stop pairing — start event detail incorrect: $START_LINE"; FAIL=$((FAIL+1))
        fi

        # Test 6.3: verify stop event line
        STOP_LINE=$(sed -n '2p' "$PAIR_JOURNAL_FILE")
        if echo "$STOP_LINE" | grep -q '"kind":"agent"'; then
            echo "PASS: start/stop pairing — stop event has kind='agent'"; PASS=$((PASS+1))
        else
            echo "FAIL: start/stop pairing — stop event missing kind='agent'"; FAIL=$((FAIL+1))
        fi

        if echo "$STOP_LINE" | grep -q '"detail":"test-agent stop a1234567'; then
            echo "PASS: start/stop pairing — stop event detail has agent type and event"; PASS=$((PASS+1))
        else
            echo "FAIL: start/stop pairing — stop event detail incorrect: $STOP_LINE"; FAIL=$((FAIL+1))
        fi

        if echo "$STOP_LINE" | grep -q 'DONE'; then
            echo "PASS: start/stop pairing — stop event detail includes RESULT token"; PASS=$((PASS+1))
        else
            echo "FAIL: start/stop pairing — stop event detail missing RESULT token"; FAIL=$((FAIL+1))
        fi
    fi
else
    echo "FAIL: start/stop pairing — journal directory not created"; FAIL=$((FAIL+1))
fi

# Cleanup pairing fixture
cd / || true
rm -rf "$PAIR_FIXTURE"

# ============================================================================
# § 7. EXIT CODE INVARIANT (all payloads exit 0)
# ============================================================================

EXIT_FIXTURE="$(mktemp -d)"
cd "$EXIT_FIXTURE" || { echo "FAIL: could not create exit-code fixture"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

# Test with various payloads and garbage
test_exit_code() {
    local name="$1" payload="$2"
    hook_run "start" "$payload" "$EXIT_FIXTURE" >/dev/null 2>&1
    local rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "PASS: exit code — $name"; PASS=$((PASS+1))
    else
        echo "FAIL: exit code — $name (exit $rc, expected 0)"; FAIL=$((FAIL+1))
    fi
}

test_exit_code "representative payload" '{"agent_type":"test","agent_id":"a123"}'
test_exit_code "empty stdin" ""
test_exit_code "garbage JSON" "not json at all"
test_exit_code "truncated JSON" '{"incomplete":'

# Cleanup exit-code fixture
cd / || true
rm -rf "$EXIT_FIXTURE"

# ============================================================================
# § 8. JSON VALIDITY checks (log and journal lines must be valid JSON)
# ============================================================================

JSON_FIXTURE="$(mktemp -d)"
cd "$JSON_FIXTURE" || { echo "FAIL: could not create JSON fixture"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

# Fire an event
hook_run "start" "$PAYLOAD_START" "$JSON_FIXTURE" >/dev/null 2>&1

# Test 8.1: log file lines are valid JSON (every non-empty line must be {...})
JSON_LOG_FILE="$JSON_FIXTURE/.claude/g-forge-agent-log.jsonl"
if [ -f "$JSON_LOG_FILE" ]; then
    invalid_log=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        # Check if line starts with { and ends with }
        case "$line" in
            '{'*'}')
                # Try to extract at least 'event' field to confirm JSON structure
                if ! echo "$line" | grep -q '"event"'; then
                    invalid_log=1
                    break
                fi
                ;;
            *)
                invalid_log=1
                break
                ;;
        esac
    done < "$JSON_LOG_FILE"

    if [ "$invalid_log" -eq 0 ]; then
        echo "PASS: JSON validity — log file is valid JSONL"; PASS=$((PASS+1))
    else
        echo "FAIL: JSON validity — log file contains invalid JSON"; FAIL=$((FAIL+1))
    fi
fi

# Test 8.2: journal file lines are valid JSON
JSON_JOURNAL_DIR="$JSON_FIXTURE/.claude/journal"
if [ -d "$JSON_JOURNAL_DIR" ]; then
    JSON_JOURNAL_FILE=$(ls "$JSON_JOURNAL_DIR"/*.jsonl 2>/dev/null | head -1)
    if [ -f "$JSON_JOURNAL_FILE" ]; then
        invalid_journal=0
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            # Check if line starts with { and ends with }
            case "$line" in
                '{'*'}')
                    # Try to extract at least 'kind' and 'detail' fields
                    if ! echo "$line" | grep -q '"kind"'; then
                        invalid_journal=1
                        break
                    fi
                    if ! echo "$line" | grep -q '"detail"'; then
                        invalid_journal=1
                        break
                    fi
                    ;;
                *)
                    invalid_journal=1
                    break
                    ;;
            esac
        done < "$JSON_JOURNAL_FILE"

        if [ "$invalid_journal" -eq 0 ]; then
            echo "PASS: JSON validity — journal file is valid JSONL"; PASS=$((PASS+1))
        else
            echo "FAIL: JSON validity — journal file contains invalid JSON"; FAIL=$((FAIL+1))
        fi
    fi
fi

# Cleanup JSON fixture
cd / || true
rm -rf "$JSON_FIXTURE"

# ============================================================================
# § 9. CONTROL-CHARACTER JSON ESCAPING (sub-task 7, M-audit W3)
# ============================================================================
# json_escape() used to strip only CR/LF (tr -d '\n\r'); any other C0 control
# byte (tab, \x01-\x1F) embedded in agent_type/agent_id/RESULT passed through
# raw into the emitted line, which strict JSON (`jq -e .`) rejects. Fail-
# before was confirmed by running the pre-fix committed hook (git show HEAD)
# against the same payload: the emitted log line contained a raw 0x09 byte.
# This suite runs only the pass-after check against the current hook, per
# the repo's existing convention of encoding the fixed behavior as the
# regression test rather than re-deriving the historical failure at runtime.

CTRL_FIXTURE="$(mktemp -d)"
cd "$CTRL_FIXTURE" || { echo "FAIL: could not create control-char fixture"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

# has_raw_ctrl <string> — true (rc 0) iff a raw C0 control byte (0x00-0x1F)
# is present. Implemented as a strip-and-compare with tr (same primitive the
# hook itself uses) rather than grep -P, which is not portable across the
# grep builds this suite runs under.
has_raw_ctrl() {
    local s="$1" stripped
    stripped=$(printf '%s' "$s" | tr -d '\000-\037')
    [ "$stripped" != "$s" ]
}

# Test 9.1: start event — agent_type carries a validly-escaped JSON
# \t sequence (the wire payload itself must stay valid JSON so the parser
# cascade decodes it rather than rejecting the document upstream of
# json_escape; decoding is what turns the escape into a RAW control byte
# in the shell variable). LOG line must contain no raw control byte.
CTRL_PAYLOAD_START='{"agent_type":"tab\tctrlagent","agent_id":"a1234567890abc","hook_event_name":"SubagentStart"}'
hook_run "start" "$CTRL_PAYLOAD_START" "$CTRL_FIXTURE" >/dev/null 2>&1

CTRL_LOG_FILE="$CTRL_FIXTURE/.claude/g-forge-agent-log.jsonl"
if [ -f "$CTRL_LOG_FILE" ]; then
    CTRL_LOG_LINE=$(tail -n 1 "$CTRL_LOG_FILE")
    if has_raw_ctrl "$CTRL_LOG_LINE"; then
        echo "FAIL: control-char escaping — log line still contains a raw control byte"; FAIL=$((FAIL+1))
    else
        echo "PASS: control-char escaping — log line has no raw control bytes"; PASS=$((PASS+1))
    fi
    if command -v jq >/dev/null 2>&1; then
        if printf '%s' "$CTRL_LOG_LINE" | jq -e . >/dev/null 2>&1; then
            echo "PASS: control-char escaping — log line parses with jq -e ."; PASS=$((PASS+1))
        else
            echo "FAIL: control-char escaping — log line does not parse with jq -e ."; FAIL=$((FAIL+1))
        fi
    else
        echo "SKIP: control-char escaping — jq not available, strict-parse check not credited (0 assertions credited)"
    fi
else
    echo "FAIL: control-char escaping — log file not created"; FAIL=$((FAIL+1))
fi

# Test 9.2: stop event — last_assistant_message's RESULT line carries
# a validly-escaped JSON \u0001\u0002 control-char pair after "RESULT: DONE"
# (again: valid JSON on the wire; the parser cascade decodes the escapes
# into RAW control bytes). JOURNAL detail (not the log) is what carries
# RESULT_VAL, so this exercises that field instead.
CTRL_PAYLOAD_STOP='{"agent_type":"test-agent","agent_id":"a1234567890abc","hook_event_name":"SubagentStop","last_assistant_message":"RESULT: DONE\u0001\u0002\nSUMMARY: test"}'
hook_run "stop" "$CTRL_PAYLOAD_STOP" "$CTRL_FIXTURE" >/dev/null 2>&1
CTRL_JOURNAL_DIR="$CTRL_FIXTURE/.claude/journal"
CTRL_JOURNAL_FILE=$(ls "$CTRL_JOURNAL_DIR"/*.jsonl 2>/dev/null | head -1)
if [ -n "$CTRL_JOURNAL_FILE" ] && [ -f "$CTRL_JOURNAL_FILE" ]; then
    CTRL_JOURNAL_LINE=$(tail -n 1 "$CTRL_JOURNAL_FILE")
    if has_raw_ctrl "$CTRL_JOURNAL_LINE"; then
        echo "FAIL: control-char escaping — journal line still contains a raw control byte"; FAIL=$((FAIL+1))
    else
        echo "PASS: control-char escaping — journal line has no raw control bytes"; PASS=$((PASS+1))
    fi
    if command -v jq >/dev/null 2>&1; then
        if printf '%s' "$CTRL_JOURNAL_LINE" | jq -e . >/dev/null 2>&1; then
            echo "PASS: control-char escaping — journal line parses with jq -e ."; PASS=$((PASS+1))
        else
            echo "FAIL: control-char escaping — journal line does not parse with jq -e ."; FAIL=$((FAIL+1))
        fi
    else
        echo "SKIP: control-char escaping — jq not available, strict-parse check not credited (0 assertions credited)"
    fi
else
    echo "FAIL: control-char escaping — journal file not created"; FAIL=$((FAIL+1))
fi

# Cleanup control-char fixture
cd / || true
rm -rf "$CTRL_FIXTURE"

# ============================================================================
# § 10. TIER-GATING IDIOM ALIGNMENT (sub-task 8, M-audit W3)
# ============================================================================
# observe.sh is a READ-ONLY reference in this suite (a separate agent owns it
# this wave) — invoked here only to compare journal-suppression behavior
# against agent-lifecycle.sh's tier check, never modified. Proves the two
# idioms agree across every integration-tier file state, including the one
# agent-lifecycle no longer special-cases (missing file — both hooks now
# rely solely on gf_guard_claude_dir, which already requires the file to
# exist before either tier check is ever reached).
OBSERVE_SCRIPT="$HOOKS_DIR/observe.sh"

# journal_written <fixture-dir> — prints 1 if a non-empty *.jsonl exists
# under <fixture-dir>/.claude/journal, else 0.
journal_written() {
    local dir="$1" f
    if [ -d "$dir/.claude/journal" ]; then
        f=$(ls "$dir/.claude/journal"/*.jsonl 2>/dev/null | head -1)
        if [ -n "$f" ] && [ -s "$f" ]; then
            printf '1'; return
        fi
    fi
    printf '0'
}

# tier_state_fixture <state> — creates an isolated git repo fixture for the
# given integration-tier state and prints its path. States: missing (repo
# exists, integration-tier absent — exercises gf_guard_claude_dir's own -f
# check rather than ambient-filesystem git ancestry) | light | light_nl
# (trailing newline) | full.
tier_state_fixture() {
    local state="$1" dir
    dir=$(mktemp -d)
    ( cd "$dir" && git init -q 2>/dev/null && git config user.email "test@g-forge.local" 2>/dev/null && git config user.name "test" 2>/dev/null )
    mkdir -p "$dir/.claude"
    case "$state" in
        missing)  : ;;
        light)    printf 'light' > "$dir/.claude/integration-tier" ;;
        light_nl) printf 'light\n' > "$dir/.claude/integration-tier" ;;
        full)     printf 'full\n' > "$dir/.claude/integration-tier" ;;
    esac
    printf '%s' "$dir"
}

for tier_state in missing light light_nl full; do
    TS_AL_DIR=$(tier_state_fixture "$tier_state")
    TS_OBS_DIR=$(tier_state_fixture "$tier_state")

    ( cd "$TS_AL_DIR" && printf '%s' "$PAYLOAD_START" | bash "$SCRIPT" start >/dev/null 2>&1 )
    ( cd "$TS_OBS_DIR" && printf '' | bash "$OBSERVE_SCRIPT" session >/dev/null 2>&1 )

    TS_AL_WRITTEN=$(journal_written "$TS_AL_DIR")
    TS_OBS_WRITTEN=$(journal_written "$TS_OBS_DIR")

    if [ "$TS_AL_WRITTEN" = "$TS_OBS_WRITTEN" ]; then
        echo "PASS: tier-gating idiom — journal suppression matches observe.sh for state '$tier_state' (written=$TS_AL_WRITTEN)"; PASS=$((PASS+1))
    else
        echo "FAIL: tier-gating idiom — journal suppression diverges for state '$tier_state' (agent-lifecycle=$TS_AL_WRITTEN observe=$TS_OBS_WRITTEN)"; FAIL=$((FAIL+1))
    fi

    rm -rf "$TS_AL_DIR" "$TS_OBS_DIR"
done

# ============================================================================
# § 11. EMPTY/NULL PAYLOAD DEFAULT GUARD (jq zero-invocation rc lie)
# ============================================================================
# jq exits 0 with zero output when its input stream has zero JSON documents
# -- i.e. a genuinely empty/timed-out payload -- which the extractor cascade
# (hooks/agent-lifecycle.sh extract_agent_type/extract_agent_id/extract_result)
# could otherwise mistake for a successful parse of a real empty value,
# letting an extraction failure masquerade as the documented "internal"
# (explicit empty string) case instead of "unknown" (genuine failure). This
# runner has no jq installed, so a minimal scratch-only stub is put on PATH
# for this section only, reproducing exactly the two real-jq behaviors these
# assertions need: the empty-stdin rc=0/no-output quirk, and (for the fixed
# null-fields payload below) jq's actual `// default` substitution on an
# explicit JSON null. It is not a general jq reimplementation -- only the two
# fixed payloads below are ever fed to it.

GUARD_STUB_DIR="$(mktemp -d)"
cat > "$GUARD_STUB_DIR/jq" <<'STUB_EOF'
#!/bin/bash
filt="$2"
input="$(cat)"
if [ -z "$input" ]; then
    exit 0
fi
case "$filt" in
    '.agent_type // "unknown"') echo "unknown" ;;
    '.agent_id // empty') : ;;
    '.last_assistant_message // empty') : ;;
    *) exit 5 ;;
esac
exit 0
STUB_EOF
chmod +x "$GUARD_STUB_DIR/jq"

GUARD_FIXTURE="$(mktemp -d)"
cd "$GUARD_FIXTURE" || { echo "FAIL: could not create guard fixture"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

GUARD_OLD_PATH="$PATH"
export PATH="$GUARD_STUB_DIR:$PATH"

# Test 11.0: instrument check — confirm the stub is actually what "jq"
# resolves to before trusting any assertion below on it.
GUARD_JQ_RESOLVED=$(command -v jq)
if [ "$GUARD_JQ_RESOLVED" = "$GUARD_STUB_DIR/jq" ]; then
    echo "PASS: empty/null jq guard — stub jq resolved on PATH"; PASS=$((PASS+1))
else
    echo "FAIL: empty/null jq guard — stub jq not resolved (got '$GUARD_JQ_RESOLVED')"; FAIL=$((FAIL+1))
fi

# Test 11.1-11.3: empty stdin payload, with jq present. Pre-guard, jq's
# rc=0/no-output on zero JSON docs would make extract_agent_type return ""
# instead of "unknown", which the AGENT="internal" fallback (agent-lifecycle.sh)
# would then render as "internal" — a genuine extraction failure misreported
# as a real internal-agent event.
hook_run "start" "" "$GUARD_FIXTURE" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
    echo "PASS: empty/null jq guard — empty payload exit 0"; PASS=$((PASS+1))
else
    echo "FAIL: empty/null jq guard — empty payload exit $rc (expected 0)"; FAIL=$((FAIL+1))
fi

GUARD_LOG_FILE="$GUARD_FIXTURE/.claude/g-forge-agent-log.jsonl"
if [ -f "$GUARD_LOG_FILE" ]; then
    GUARD_LOG_LINE=$(tail -n 1 "$GUARD_LOG_FILE")
    GUARD_AGENT=$(extract_json_field "$GUARD_LOG_LINE" "agent")
    # falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-29
    if [ "$GUARD_AGENT" = "unknown" ]; then
        echo "PASS: empty/null jq guard — empty payload logs agent='unknown'"; PASS=$((PASS+1))
    else
        echo "FAIL: empty/null jq guard — empty payload logged agent='$GUARD_AGENT' (expected 'unknown')"; FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: empty/null jq guard — empty payload log file not created"; FAIL=$((FAIL+1))
fi

GUARD_JOURNAL_DIR="$GUARD_FIXTURE/.claude/journal"
GUARD_JOURNAL_FILE=$(ls "$GUARD_JOURNAL_DIR"/*.jsonl 2>/dev/null | head -1)
if [ -n "$GUARD_JOURNAL_FILE" ] && [ -f "$GUARD_JOURNAL_FILE" ]; then
    GUARD_JOURNAL_LINE=$(tail -n 1 "$GUARD_JOURNAL_FILE")
    GUARD_DETAIL=$(sed -n 's/.*"detail":"\([^"]*\)".*/\1/p' <<< "$GUARD_JOURNAL_LINE")
    if [ "$GUARD_DETAIL" = "unknown start" ]; then
        echo "PASS: empty/null jq guard — empty payload journal detail is 'unknown start' (no agent_id/null leak)"; PASS=$((PASS+1))
    else
        echo "FAIL: empty/null jq guard — empty payload journal detail was '$GUARD_DETAIL' (expected 'unknown start')"; FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: empty/null jq guard — empty payload journal file not created"; FAIL=$((FAIL+1))
fi

# Test 11.4-11.6: explicit JSON null agent_type/agent_id, with jq present.
# jq's own `// default` already treats null as falsy, so this is coverage of
# already-correct behavior — proving the guard above didn't regress it.
NULL_FIELDS_PAYLOAD='{"agent_type": null, "agent_id": null}'
hook_run "start" "$NULL_FIELDS_PAYLOAD" "$GUARD_FIXTURE" >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
    echo "PASS: empty/null jq guard — null-fields payload exit 0"; PASS=$((PASS+1))
else
    echo "FAIL: empty/null jq guard — null-fields payload exit $rc (expected 0)"; FAIL=$((FAIL+1))
fi

if [ -f "$GUARD_LOG_FILE" ]; then
    GUARD_LOG_LINE2=$(tail -n 1 "$GUARD_LOG_FILE")
    GUARD_AGENT2=$(extract_json_field "$GUARD_LOG_LINE2" "agent")
    if [ "$GUARD_AGENT2" = "unknown" ]; then
        echo "PASS: empty/null jq guard — null-fields payload logs agent='unknown'"; PASS=$((PASS+1))
    else
        echo "FAIL: empty/null jq guard — null-fields payload logged agent='$GUARD_AGENT2' (expected 'unknown')"; FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: empty/null jq guard — null-fields payload log file not created"; FAIL=$((FAIL+1))
fi

if [ -n "$GUARD_JOURNAL_FILE" ] && [ -f "$GUARD_JOURNAL_FILE" ]; then
    GUARD_JOURNAL_LINE2=$(tail -n 1 "$GUARD_JOURNAL_FILE")
    GUARD_DETAIL2=$(sed -n 's/.*"detail":"\([^"]*\)".*/\1/p' <<< "$GUARD_JOURNAL_LINE2")
    if [ "$GUARD_DETAIL2" = "unknown start" ]; then
        echo "PASS: empty/null jq guard — null-fields payload journal detail is 'unknown start' (no literal 'null' leak)"; PASS=$((PASS+1))
    else
        echo "FAIL: empty/null jq guard — null-fields payload journal detail was '$GUARD_DETAIL2' (expected 'unknown start')"; FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: empty/null jq guard — null-fields payload journal file not created"; FAIL=$((FAIL+1))
fi

export PATH="$GUARD_OLD_PATH"
cd / || true
rm -rf "$GUARD_STUB_DIR" "$GUARD_FIXTURE"

# ============================================================================
# § Results
# ============================================================================

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

#!/bin/bash
# Class-split invariant suite — ADR-008 clause 6
#
# Resolve script dir / hooks dir to ABSOLUTE paths exactly once, before any
# fixture cd. Relative $0 (as invoked from repo root) would otherwise break
# `dirname "$0"` after the sandbox cd below.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/../hooks" && pwd)"
# Timing bounds are declared once, with their evidence, in tests/lib/ — the same
# abandoned-pipe bound governs test-check-commit.sh, and duplicating it drifted.
source "$SCRIPT_DIR/lib/timing-bounds.sh" || { echo "FAIL: could not source tests/lib/timing-bounds.sh"; exit 1; }
# Assertion: the six non-gating hooks (observe.sh, agent-lifecycle.sh,
# session-start.sh, pre-compact.sh, workflow-checkpoint.sh, post-commit-cleanup.sh)
# NEVER exit non-zero, even under garbage/malformed stdin payloads.
# Exit code 0 is guaranteed by design — these hooks degrade silently rather than
# blocking. The gating pair (hooks/check-commit.sh, hooks/pre-commit) is explicitly
# out of scope and must never silently migrate into the non-gating class.
#
# Total assertions: 38
# - Structural: 2 (gating pair exclusion, hook list completeness)
# - Exit-code invariant: 24 (all six hooks × 4 payload types: 1 representative + 3 garbage)
# - Abandoned-stdin invariant: 12 (all six hooks × 2 assertions: exit 0 + bounded wait time)

# ============================================================================
# § Structural assertions — gating pair exclusion
# ============================================================================

PASS=0
FAIL=0

# The suite's declared NON-GATING_HOOKS list is the authority for which
# hooks are tested. Verify it exists and is complete.
NON_GATING_HOOKS="observe.sh agent-lifecycle.sh session-start.sh pre-compact.sh workflow-checkpoint.sh post-commit-cleanup.sh"

# Guard: ensure exactly six hooks in the list (not five or seven).
HOOK_COUNT=$(printf '%s\n' $NON_GATING_HOOKS | wc -w | tr -d '[:space:]')
if [ "$HOOK_COUNT" -eq 6 ]; then
    echo "PASS: six non-gating hooks declared"; PASS=$((PASS+1))
else
    echo "FAIL: expected 6 non-gating hooks, got $HOOK_COUNT"; FAIL=$((FAIL+1))
fi

# Guard: gating pair not in the declared list.
if ! printf '%s' "$NON_GATING_HOOKS" | grep -qE 'check-commit|pre-commit[^-]'; then
    echo "PASS: gating pair (check-commit.sh, pre-commit) explicitly excluded"; PASS=$((PASS+1))
else
    echo "FAIL: gating pair found in non-gating list"; FAIL=$((FAIL+1))
fi

# ============================================================================
# § Fixture setup — sandbox for all hook tests
# ============================================================================

# All six hooks self-guard to G-Forge-managed projects (.claude/integration-tier).
# Create a fixture directory that simulates a G-Forge project so all hooks activate.
FIXTURE="$(mktemp -d)"
cd "$FIXTURE" || { echo "FAIL: could not enter fixture dir"; exit 1; }

# Initialize as a git repo (some hooks call git commands)
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null

# Mark as a G-Forge project so the guard passes
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

# ============================================================================
# § Representative payloads and garbage for each hook
# ============================================================================

# Test payloads — fixed data, no timestamps or UUIDs
OBSERVE_PAYLOAD='{"tool_input":{"command":"git commit -m test"}}'
AGENT_PAYLOAD='{"agent_type":"TestAgent","agent_id":"12345678","hook_event_name":"SubagentStart"}'
SESSION_PAYLOAD='{"source":"startup"}'
COMPACT_PAYLOAD='{}'  # pre-compact.sh discards stdin anyway
CHECKPOINT_PAYLOAD='{"tool_input":{"prompt":"test"}}'
POSTCOMMIT_PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"git commit -m test"}}'

# Garbage payloads — all hooks must tolerate these
GARBAGE_EMPTY=""
GARBAGE_NONTEXT="not json at all"
GARBAGE_TRUNCATED='{"incomplete":'

# ============================================================================
# § Test harness: exit-code invariant for each hook
# ============================================================================

# test_hook_exit_code <name> <hook-script> <payload> <description>
test_hook_exit_code() {
    local name="$1" script="$2" payload="$3" desc="$4"
    printf '%s' "$payload" | bash "$script" >/dev/null 2>&1
    local rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "PASS: $name — $desc (exit 0)"; PASS=$((PASS+1))
    else
        echo "FAIL: $name — $desc (exit $rc, expected 0)"; FAIL=$((FAIL+1))
    fi
}

# test_hook_abandoned_stdin <name> <hook-script> <description> [bound-ms]
# Invoke hook with stdin attached to an open pipe with NO writer and NO EOF
# (simulates orphaned tool call). Assert: exit 0 + return within guard window.
# WHY workflow-checkpoint is reliably the slowest of the six, and why that is a
# machine signal rather than a regression: subprocess fork count under load, not
# network. Its version-advisory curl is manifest-gated
# (hooks/workflow-checkpoint.sh:477), 24h rate-limited (:472), backgrounded with
# &, --max-time 5, output discarded and never waited on — the harness times a
# foreground child, so that call cannot enter the measurement at all. Its tail is
# 504 lines forking git/grep/find/ls children against post-commit-cleanup.sh's 110.
# GUARD_WINDOW_MS (the default when the optional 4th arg is omitted) sources
# GF_FAST_STDIN_GUARD_MS (tests/lib/timing-bounds.sh), not the production
# GF_HOOK_STDIN_GUARD_MS bound — five of the six calls in § 7 below run with
# GF_STDIN_TIMEOUT_OVERRIDE exported (hooks/lib/stdin-read.sh), so each of
# those hooks' internal stdin-read timeout is ~2s, not the production 5s. The
# sixth call passes GF_HOOK_STDIN_GUARD_MS explicitly and runs without the
# override — see the § 7 header comment for why.
GUARD_WINDOW_MS="$GF_FAST_STDIN_GUARD_MS"
test_hook_abandoned_stdin() {
    local name="$1" script="$2" desc="$3" bound_ms="${4:-$GUARD_WINDOW_MS}"
    local start_time end_time elapsed

    start_time=$(date +%s%3N)
    bash "$script" >/dev/null 2>&1 < <(sleep 300)
    local rc=$?
    end_time=$(date +%s%3N)
    elapsed=$((end_time - start_time))

    if [ "$rc" -eq 0 ]; then
        echo "PASS: $name — $desc (abandoned stdin, exit 0)"; PASS=$((PASS+1))
    else
        echo "FAIL: $name — $desc (abandoned stdin, exit $rc, expected 0)"; FAIL=$((FAIL+1))
    fi

    if [ "$elapsed" -lt "$bound_ms" ]; then
        echo "PASS: $name — $desc (abandoned stdin, returned in ${elapsed}ms, <${bound_ms}ms)"; PASS=$((PASS+1))
    else
        echo "FAIL: $name — $desc (abandoned stdin, took ${elapsed}ms, expected <${bound_ms}ms)"; FAIL=$((FAIL+1))
    fi
}

# ============================================================================
# § 1. observe.sh — silent observer, non-gating
# ============================================================================

OBSERVE_SCRIPT="$HOOKS_DIR/observe.sh"

# Representative payload (valid PostToolUse)
test_hook_exit_code "observe.sh/rep" "$OBSERVE_SCRIPT" "$OBSERVE_PAYLOAD" \
    "representative payload"

# Garbage: empty stdin
test_hook_exit_code "observe.sh/empty" "$OBSERVE_SCRIPT" "$GARBAGE_EMPTY" \
    "empty stdin"

# Garbage: non-JSON text
test_hook_exit_code "observe.sh/nontext" "$OBSERVE_SCRIPT" "$GARBAGE_NONTEXT" \
    "non-JSON text"

# Garbage: truncated JSON
test_hook_exit_code "observe.sh/truncated" "$OBSERVE_SCRIPT" "$GARBAGE_TRUNCATED" \
    "truncated JSON"

# ============================================================================
# § 2. agent-lifecycle.sh — agent event logger, non-gating
# ============================================================================

AGENT_SCRIPT="$HOOKS_DIR/agent-lifecycle.sh"

# Representative payload (valid SubagentStart)
test_hook_exit_code "agent-lifecycle.sh/rep" "$AGENT_SCRIPT" "$AGENT_PAYLOAD" \
    "representative payload"

# Garbage: empty stdin
test_hook_exit_code "agent-lifecycle.sh/empty" "$AGENT_SCRIPT" "$GARBAGE_EMPTY" \
    "empty stdin"

# Garbage: non-JSON text
test_hook_exit_code "agent-lifecycle.sh/nontext" "$AGENT_SCRIPT" "$GARBAGE_NONTEXT" \
    "non-JSON text"

# Garbage: truncated JSON
test_hook_exit_code "agent-lifecycle.sh/truncated" "$AGENT_SCRIPT" "$GARBAGE_TRUNCATED" \
    "truncated JSON"

# ============================================================================
# § 3. session-start.sh — session sync and health check, non-gating
# ============================================================================

SESSION_SCRIPT="$HOOKS_DIR/session-start.sh"

# Representative payload (valid SessionStart)
test_hook_exit_code "session-start.sh/rep" "$SESSION_SCRIPT" "$SESSION_PAYLOAD" \
    "representative payload"

# Garbage: empty stdin
test_hook_exit_code "session-start.sh/empty" "$SESSION_SCRIPT" "$GARBAGE_EMPTY" \
    "empty stdin"

# Garbage: non-JSON text
test_hook_exit_code "session-start.sh/nontext" "$SESSION_SCRIPT" "$GARBAGE_NONTEXT" \
    "non-JSON text"

# Garbage: truncated JSON
test_hook_exit_code "session-start.sh/truncated" "$SESSION_SCRIPT" "$GARBAGE_TRUNCATED" \
    "truncated JSON"

# ============================================================================
# § 4. pre-compact.sh — PreCompact hook, silently consumes stdin, non-gating
# ============================================================================

COMPACT_SCRIPT="$HOOKS_DIR/pre-compact.sh"

# Representative payload (pre-compact discards stdin, so any valid payload works)
test_hook_exit_code "pre-compact.sh/rep" "$COMPACT_SCRIPT" "$COMPACT_PAYLOAD" \
    "representative payload"

# Garbage: empty stdin
test_hook_exit_code "pre-compact.sh/empty" "$COMPACT_SCRIPT" "$GARBAGE_EMPTY" \
    "empty stdin"

# Garbage: non-JSON text
test_hook_exit_code "pre-compact.sh/nontext" "$COMPACT_SCRIPT" "$GARBAGE_NONTEXT" \
    "non-JSON text"

# Garbage: truncated JSON
test_hook_exit_code "pre-compact.sh/truncated" "$COMPACT_SCRIPT" "$GARBAGE_TRUNCATED" \
    "truncated JSON"

# ============================================================================
# § 5. workflow-checkpoint.sh — UserPromptSubmit checkpoint, non-gating
# ============================================================================

CHECKPOINT_SCRIPT="$HOOKS_DIR/workflow-checkpoint.sh"

# Representative payload (valid UserPromptSubmit)
test_hook_exit_code "workflow-checkpoint.sh/rep" "$CHECKPOINT_SCRIPT" "$CHECKPOINT_PAYLOAD" \
    "representative payload"

# Garbage: empty stdin
test_hook_exit_code "workflow-checkpoint.sh/empty" "$CHECKPOINT_SCRIPT" "$GARBAGE_EMPTY" \
    "empty stdin"

# Garbage: non-JSON text
test_hook_exit_code "workflow-checkpoint.sh/nontext" "$CHECKPOINT_SCRIPT" "$GARBAGE_NONTEXT" \
    "non-JSON text"

# Garbage: truncated JSON
test_hook_exit_code "workflow-checkpoint.sh/truncated" "$CHECKPOINT_SCRIPT" "$GARBAGE_TRUNCATED" \
    "truncated JSON"

# ============================================================================
# § 6. post-commit-cleanup.sh — PostToolUse sentinel cleanup, non-gating
# ============================================================================

POSTCOMMIT_SCRIPT="$HOOKS_DIR/post-commit-cleanup.sh"

# Representative payload (valid PostToolUse with commit command)
test_hook_exit_code "post-commit-cleanup.sh/rep" "$POSTCOMMIT_SCRIPT" "$POSTCOMMIT_PAYLOAD" \
    "representative payload"

# Garbage: empty stdin
test_hook_exit_code "post-commit-cleanup.sh/empty" "$POSTCOMMIT_SCRIPT" "$GARBAGE_EMPTY" \
    "empty stdin"

# Garbage: non-JSON text
test_hook_exit_code "post-commit-cleanup.sh/nontext" "$POSTCOMMIT_SCRIPT" "$GARBAGE_NONTEXT" \
    "non-JSON text"

# Garbage: truncated JSON
test_hook_exit_code "post-commit-cleanup.sh/truncated" "$POSTCOMMIT_SCRIPT" "$GARBAGE_TRUNCATED" \
    "truncated JSON"

# ============================================================================
# § 7. Abandoned-stdin fixture — all six hooks tolerate orphaned stdin
# ============================================================================
#
# Verifies the orphan-process class (66-min hangs on abandoned stdin found in
# field) is dead. Each hook sources hooks/lib/stdin-read.sh and calls
# gf_read_stdin_timeout 5, which bounds the wait via `read -t 5 -d ''`.
# This fixture invokes each hook with stdin attached to an open pipe with NO
# writer and NO EOF, simulating a harness crash or timeout that leaves stdin
# stranded. Assert: exit 0 + return within guard window.
#
# Five of the six hooks (observe.sh, agent-lifecycle.sh, session-start.sh,
# pre-compact.sh, workflow-checkpoint.sh) run under GF_STDIN_TIMEOUT_OVERRIDE
# (hooks/lib/stdin-read.sh consumes it in gf_read_stdin_timeout, replacing
# the 5s argument with this value before normalization), so `read -t 5 -d ''`
# becomes `read -t 2 -d ''` and each of those hooks' stdin read times out in
# ~2s instead of 5s. Those five are asserted against GUARD_WINDOW_MS
# (GF_FAST_STDIN_GUARD_MS). GF_STDIN_TIMEOUT_OVERRIDE is exported before
# section 1 and unset before section 6 so no other part of this suite is
# affected — production hooks never set this var (see the lib's own comment).
#
# The sixth, post-commit-cleanup.sh, deliberately runs WITHOUT the override —
# production mode, `gf_read_stdin_timeout 5` unmodified — and is asserted
# against GF_HOOK_STDIN_GUARD_MS (the production 65s bound) instead of
# GUARD_WINDOW_MS. This is the only case in the suite that exercises the real
# 5s stdin guard rather than the ~2s test-accelerated one; without it,
# GF_HOOK_STDIN_GUARD_MS has zero consumers and the production stdin-guard
# path — the one the 66-minute field orphan actually broke — carries no
# regression coverage at all (code-lead round r3, finding R-9). It runs
# post-commit-cleanup.sh specifically because that hook is the fastest of the
# six (smallest hook, no network, nothing after the read, per the WHY comment
# above test_hook_abandoned_stdin), which minimizes the fixed cost of running
# one case in production mode instead of fast mode.
#
# falsifiability: hooks/ and this test file + tests/lib/timing-bounds.sh
# copied whole to a scratch dir (relative sourcing paths preserved). In the
# scratch copy only: gf_read_stdin_timeout's
# `if [ -n "${GF_STDIN_TIMEOUT_OVERRIDE:-}" ]` branch forced to `if false`
# (override silently ignored, hooks fall back to their normal 5s argument),
# and GF_FAST_STDIN_GUARD_MS tightened to 4000 (the real bound — 15000 at
# probe time, raised to 30000 on loaded-machine evidence; the probe pins its
# own 4000ms scratch bound, so its conclusion is unaffected — has enough margin
# to absorb the ~2s-vs-5s delta without flipping, so a tight bound is needed
# to make the neutering observable). GF_HOOK_STDIN_GUARD_MS (65000) was left
# untouched — neutering the override makes post-commit-cleanup.sh's call
# identical to its already-production behavior, so there is nothing to flip
# there; its assertion is the control. Re-running the scratch suite then
# produced 5 FAILs — one "returned within guard window" assertion per
# override-mode hook, each measured well over the 4000ms bound: observe.sh
# 7012ms, agent-lifecycle.sh 8840ms, session-start.sh 7898ms, pre-compact.sh
# 6438ms, workflow-checkpoint.sh 9596ms — while post-commit-cleanup.sh's
# production-mode assertion stayed green at 7018ms against the untouched
# 65000ms bound, confirming the guard-window pass in the real suite
# (GF_FAST_STDIN_GUARD_MS, 15000 at probe time, now 30000) is not coincidental for the five
# override-mode calls, and that the sixth call is genuinely exercising the
# production path independent of the override. Scratch copy discarded
# after. Production tree (this file and hooks/) untouched by the probe —
# 2026-08-21.

export GF_STDIN_TIMEOUT_OVERRIDE="$GF_FAST_STDIN_OVERRIDE_S"

# ── 1. observe.sh with abandoned stdin ─────────────────────────────────────

test_hook_abandoned_stdin "observe.sh/abandoned" "$OBSERVE_SCRIPT" \
    "abandoned stdin (no writer, no EOF)"

# ── 2. agent-lifecycle.sh with abandoned stdin ─────────────────────────────

test_hook_abandoned_stdin "agent-lifecycle.sh/abandoned" "$AGENT_SCRIPT" \
    "abandoned stdin (no writer, no EOF)"

# ── 3. session-start.sh with abandoned stdin ───────────────────────────────

test_hook_abandoned_stdin "session-start.sh/abandoned" "$SESSION_SCRIPT" \
    "abandoned stdin (no writer, no EOF)"

# ── 4. pre-compact.sh with abandoned stdin ────────────────────────────────

test_hook_abandoned_stdin "pre-compact.sh/abandoned" "$COMPACT_SCRIPT" \
    "abandoned stdin (no writer, no EOF)"

# ── 5. workflow-checkpoint.sh with abandoned stdin ────────────────────────

test_hook_abandoned_stdin "workflow-checkpoint.sh/abandoned" "$CHECKPOINT_SCRIPT" \
    "abandoned stdin (no writer, no EOF)"

# ── 6. post-commit-cleanup.sh with abandoned stdin — production mode ──────
# Override unset BEFORE this call (not after, unlike calls 1-5): this is the
# one production-mode case in the block, verifying the real `gf_read_stdin_timeout 5`
# path — see the § 7 header comment above for why this call, alone, is not
# fast-mode.

unset GF_STDIN_TIMEOUT_OVERRIDE

test_hook_abandoned_stdin "post-commit-cleanup.sh/abandoned" "$POSTCOMMIT_SCRIPT" \
    "abandoned stdin, production guard (no writer, no EOF)" "$GF_HOOK_STDIN_GUARD_MS"

# ============================================================================
# § Cleanup and results
# ============================================================================

cd / && rm -rf "$FIXTURE"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

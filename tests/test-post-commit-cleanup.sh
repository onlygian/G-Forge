#!/bin/bash
# Unit tests for hooks/post-commit-cleanup.sh (PostToolUse hook).
# Verifies: review-approval sentinels (.claude/g-forge-approved,
# .claude/g-forge-docs-approved) are removed after a git commit.
# Runs entirely inside a throwaway fixture dir so the suite never mutates
# the repo's own .claude/ state.
#
# Total assertions: 11
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line — the
# finding-#20 cross-check that catches a suite silently dropping cases.

SCRIPT="$(cd "$(dirname "$0")" && pwd)/../hooks/post-commit-cleanup.sh"
SENTINEL_CODE=".claude/g-forge-approved"
SENTINEL_DOCS=".claude/g-forge-docs-approved"
PASS=0
FAIL=0

# run <name> <input-json>
# Invokes the hook with the given PostToolUse JSON payload and verifies that
# both sentinels are removed.
run() {
    local name="$1" input="$2"

    # Create fresh sentinel files before each test
    touch "$SENTINEL_CODE"
    touch "$SENTINEL_DOCS"

    # Feed the payload to the hook (exit code irrelevant; side effects matter)
    printf '%s' "$input" | bash "$SCRIPT" >/dev/null 2>&1

    # Check if BOTH sentinels were removed
    if [ ! -f "$SENTINEL_CODE" ] && [ ! -f "$SENTINEL_DOCS" ]; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        local code_status="exists" docs_status="exists"
        [ ! -f "$SENTINEL_CODE" ] && code_status="removed"
        [ ! -f "$SENTINEL_DOCS" ] && docs_status="removed"
        echo "FAIL: $name (g-forge-approved=$code_status, g-forge-docs-approved=$docs_status)"; FAIL=$((FAIL+1))
    fi
}

# run_no_cleanup <name> <input-json>
# Invokes the hook with the given JSON payload and verifies that sentinels
# are NOT removed (for non-commit commands or lack of guard file).
run_no_cleanup() {
    local name="$1" input="$2"

    # Create fresh sentinel files before each test
    touch "$SENTINEL_CODE"
    touch "$SENTINEL_DOCS"

    # Feed the payload to the hook
    printf '%s' "$input" | bash "$SCRIPT" >/dev/null 2>&1

    # Check if BOTH sentinels were NOT removed
    if [ -f "$SENTINEL_CODE" ] && [ -f "$SENTINEL_DOCS" ]; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        local code_status="exists" docs_status="exists"
        [ ! -f "$SENTINEL_CODE" ] && code_status="removed"
        [ ! -f "$SENTINEL_DOCS" ] && docs_status="removed"
        echo "FAIL: $name (g-forge-approved=$code_status, g-forge-docs-approved=$docs_status)"; FAIL=$((FAIL+1))
    fi
}

# Isolate all .claude state in a temp fixture — the hook resolves .claude
# relative to CWD, so running here keeps the real project untouched.
WORKDIR="$(mktemp -d)"
cd "$WORKDIR" || { echo "FAIL: could not enter fixture dir"; exit 1; }
mkdir -p .claude
# The hook self-guards to G-Forge-managed projects (presence of
# .claude/integration-tier). Mark this fixture as one so the guard is active.
printf 'full\n' > .claude/integration-tier

# Make the fixture a real git repo
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "g-forge-test" 2>/dev/null

# ── Wave 1 Hardening Tests (#6) ──────────────────────────────────────────

# 1: git -C <path> commit → removes both sentinels (hardening #6)
run "git -C /some/path commit removes both sentinels" \
    '{"tool_name":"Bash","tool_input":{"command":"git -C /some/path commit -m \"x\""}}'

# 2: git -c key=value commit → removes both sentinels (hardening #6)
run "git -c user.name=x commit removes both sentinels" \
    '{"tool_name":"Bash","tool_input":{"command":"git -c user.name=test commit -m \"x\""}}'

# 3: Plain git commit → removes both sentinels (baseline, should continue working)
run "git commit removes both sentinels" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}'

# 4: npm test (non-commit command) → sentinels remain
run_no_cleanup "non-commit command leaves sentinels intact" \
    '{"tool_name":"Bash","tool_input":{"command":"npm test"}}'

# ── Failed-commit retention (#37 bug 1) ──────────────────────────────────
# A sentinel stamped against the CURRENT HEAD means no commit has landed since
# the review, so a git-aborted commit (identity unknown, exit 128) must not
# erase it. A moved HEAD means the commit landed and the sentinel is spent.
GIT_COMMIT_PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}'
stamp() { printf 'commit_sentinel_ts=%s commit_sentinel_head=%s commit_sentinel_worktree=%s\n' "deadbeef" "$1" "$PWD"; }
check_state() { # <name> <expect: kept|cleared>
    local name="$1" expect="$2" got_c="cleared" got_d="cleared"
    [ -f "$SENTINEL_CODE" ] && got_c="kept"
    [ -f "$SENTINEL_DOCS" ] && got_d="kept"
    if [ "$got_c" = "$expect" ] && [ "$got_d" = "$expect" ]; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected $expect; g-forge-approved=$got_c, g-forge-docs-approved=$got_d)"; FAIL=$((FAIL+1))
    fi
}

# 6: unborn repo, stamp head empty, HEAD still unborn → commit did not land
stamp "" > "$SENTINEL_CODE"; stamp "" > "$SENTINEL_DOCS"
printf '%s' "$GIT_COMMIT_PAYLOAD" | bash "$SCRIPT" >/dev/null 2>&1
check_state "failed first commit (HEAD still unborn) keeps both sentinels" kept

# 7: first commit landed → HEAD now exists, stamp head empty → cleared
printf 'a\n' > f.txt; git add f.txt; git commit -qm first 2>/dev/null
printf '%s' "$GIT_COMMIT_PAYLOAD" | bash "$SCRIPT" >/dev/null 2>&1
check_state "landed first commit (HEAD born since stamp) clears both sentinels" cleared

# 8: stamp head == current HEAD → commit aborted → kept
HEAD_NOW=$(git rev-parse HEAD)
stamp "$HEAD_NOW" > "$SENTINEL_CODE"; stamp "$HEAD_NOW" > "$SENTINEL_DOCS"
printf '%s' "$GIT_COMMIT_PAYLOAD" | bash "$SCRIPT" >/dev/null 2>&1
check_state "aborted commit (HEAD unchanged since stamp) keeps both sentinels" kept

# 9: HEAD moved past the stamp → landed → cleared
printf 'b\n' > f.txt; git commit -qam second 2>/dev/null
printf '%s' "$GIT_COMMIT_PAYLOAD" | bash "$SCRIPT" >/dev/null 2>&1
check_state "landed commit (HEAD moved past stamp) clears both sentinels" cleared

# 10: unparseable stamp → cannot reason about it → old behaviour, cleared
printf 'garbage\n' > "$SENTINEL_CODE"; printf 'garbage\n' > "$SENTINEL_DOCS"
printf '%s' "$GIT_COMMIT_PAYLOAD" | bash "$SCRIPT" >/dev/null 2>&1
check_state "unparseable stamp falls back to clearing" cleared

# ── Sed-tier fallback parity (W1.4) ───────────────────────────────────────
# When jq/python3/node are all unavailable, extract_cmd() must fall back to
# the same portable sed extraction hooks/check-commit.sh uses (its 4th tier)
# instead of leaving the caller to fall through to the raw JSON payload —
# which is NOT reliably shell-tokenizable by is_git_commit()'s xargs -n1 walk
# (mixed quoted/unquoted JSON syntax with no separating whitespace collapses
# into one non-"git" token). Shadow all three parsers with exit-1 stubs
# *prepended* to the real PATH (same convention as tests/test-check-commit.sh)
# and confirm a clean (unescaped) commit command is still extracted and
# detected.
STUBDIR="$(mktemp -d)"
for p in jq python3 node; do
    printf '#!/bin/sh\nexit 1\n' > "$STUBDIR/$p"
    chmod +x "$STUBDIR/$p"
done
touch "$SENTINEL_CODE"
touch "$SENTINEL_DOCS"
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git commit -m test-sed-tier"}}' \
    | PATH="$STUBDIR:$PATH" bash "$SCRIPT" >/dev/null 2>&1
if [ ! -f "$SENTINEL_CODE" ] && [ ! -f "$SENTINEL_DOCS" ]; then
    echo "PASS: sed-tier fallback extracts command and clears sentinels when jq/python3/node are unavailable"; PASS=$((PASS+1))
else
    SED_CODE_STATUS="exists"; SED_DOCS_STATUS="exists"
    [ ! -f "$SENTINEL_CODE" ] && SED_CODE_STATUS="removed"
    [ ! -f "$SENTINEL_DOCS" ] && SED_DOCS_STATUS="removed"
    echo "FAIL: sed-tier fallback did not clear sentinels (g-forge-approved=$SED_CODE_STATUS, g-forge-docs-approved=$SED_DOCS_STATUS)"; FAIL=$((FAIL+1))
fi
rm -rf "$STUBDIR"

# ── Guard Behavior Test ──────────────────────────────────────────────────

# 5: Outside a G-Forge project (no .claude/integration-tier) → hook is inert
cd "$WORKDIR" || exit 1
rm -f .claude/integration-tier
touch "$SENTINEL_CODE"
touch "$SENTINEL_DOCS"
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}'  \
    | bash "$SCRIPT" >/dev/null 2>&1
if [ -f "$SENTINEL_CODE" ] && [ -f "$SENTINEL_DOCS" ]; then
    echo "PASS: hook is inert outside G-Forge projects (sentinels remain)"; PASS=$((PASS+1))
else
    echo "FAIL: hook fired outside G-Forge project guard"; FAIL=$((FAIL+1))
fi

# Restore the guard for remaining tests
printf 'full\n' > .claude/integration-tier

# Clean up the fixture
cd / && rm -rf "$WORKDIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

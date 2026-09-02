#!/bin/bash
# Workflow checkpoint behavioral suite — UserPromptSubmit hook.
#
# Verifies: integration-tier matrix (light/balanced/full), banner content,
# context depth thresholds (amber/red) and offset calibration, session-mode
# detection (conversation vs implementation), compaction escalation, milestone-
# health assembly, worktree-bound sentinel read (ADR-004/005), and non-gating
# exit-0 contract. Nudges tested: handoff (block-scoped ADR-variant vs
# generic, A-5), roundtable, listen mode — the coverage/trim/align nudge
# sentences are deliberately unasserted (free text). Direction-aware
# update-nudge cases (M46 W1 task 5): LATEST newer/equal/older, pinning
# post-fix semver-comparison behavior. Banner-on-delta (v2.6): session-keyed
# stable-slice suppression, escalation cadence, no-session_id degrade path.
#
# Assertion groups: numbered `# § N` section headings throughout the file body —
# derive the section set from the file itself, never from this header.
# See the Results line at the end of a run for the current total — not
# restated here as a fixed number (an unpinned count is a review finding,
# G-RULES §G/ADR-013).

# Resolve script dir / hooks dir to ABSOLUTE paths exactly once, before any
# fixture cd. Relative $0 would otherwise break after the sandbox cd below.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/../hooks" && pwd)"
CHECKPOINT_SCRIPT="$HOOKS_DIR/workflow-checkpoint.sh"

PASS=0
FAIL=0

check() { # name expected actual
    if [ "$2" = "$3" ]; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 (expected '$2', got '$3')"; FAIL=$((FAIL+1))
    fi
}

check_match() { # name pattern actual
    # LC_ALL=C forces byte-wise matching. WHY: Windows wchar_t is 16-bit, so
    # MSYS mbrtowc cannot represent any character above U+FFFF, and GNU grep 3.0
    # then rejects the sequence outright — every 4-byte emoji the hook printed at
    # the time silently failed to match while 3-byte ones (⚠ ✓) matched. Those
    # emoji have since been removed from the banner, but the guard stays: it is
    # what makes any future non-ASCII marker safe to assert on here.
    # Byte-wise is correct here anyway: every pattern below is literal text plus
    # `.*`, and none depends on `.` meaning one character rather than one byte.
    if printf '%s' "$3" | LC_ALL=C grep -q "$2"; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 (expected pattern '$2', got '$3')"; FAIL=$((FAIL+1))
    fi
}

check_no_match() { # name pattern actual — pins ABSENCE of pattern, not presence
    if printf '%s' "$3" | LC_ALL=C grep -q "$2"; then
        echo "FAIL: $1 (unexpected pattern '$2' found in output)"; FAIL=$((FAIL+1))
    else
        echo "PASS: $1"; PASS=$((PASS+1))
    fi
}

check_exit() { # name expected_code command...
    local name="$1"
    local expected="$2"
    shift 2
    # Capture $? immediately after command, before any other operations
    "$@" >/dev/null 2>&1
    local rc=$?
    if [ "$rc" -eq "$expected" ] 2>/dev/null; then
        echo "PASS: $name — exit $rc"; PASS=$((PASS+1))
    else
        echo "FAIL: $name — exit $rc (expected $expected)"; FAIL=$((FAIL+1))
    fi
}

# ============================================================================
# § 1. Project guard — no-op outside G-Forge project
# ============================================================================

echo "§ 1. Project guard"

# Outside a G-Forge project, the hook exits silently (0) with no output.
TEMP_NON_GFORGE=$(mktemp -d)
cd "$TEMP_NON_GFORGE" || { echo "FAIL: could not cd to temp"; exit 1; }
git init -q 2>/dev/null
git config user.email "test@test.local" 2>/dev/null
git config user.name "test" 2>/dev/null
OUTPUT=$( echo '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check "project guard: no-op outside G-Forge" "" "$OUTPUT"
cd / && rm -rf "$TEMP_NON_GFORGE"

# ============================================================================
# § 2. Fixture setup — G-Forge managed project
# ============================================================================

echo "§ 2. Fixture setup"

FIXTURE="$(mktemp -d)"
cd "$FIXTURE" || { echo "FAIL: could not enter fixture"; exit 1; }

# Initialize git repo
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "test" 2>/dev/null

# Mark as a G-Forge project (default to full tier)
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

# Create initial commit so branch operations work
mkdir -p g-docs
cat > g-docs/ROADMAP.md <<'EOF'
# Test Roadmap
## Active Session
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — test | branch: feat/test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · fixture setup
Next up:          · write tests
Active context:   · hooks/workflow-checkpoint.sh:60-70 tier resolution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
git add -A 2>/dev/null
git commit -q -m "init" 2>/dev/null

echo "PASS: fixture initialized"; PASS=$((PASS+1))

# ============================================================================
# § 3. Non-gating contract — exit 0 always
# ============================================================================

echo "§ 3. Non-gating contract"

# Even with garbage stdin, exit code must be 0
printf '%s' '{}' | bash "$CHECKPOINT_SCRIPT" >/dev/null 2>&1
check_exit "exit 0 on normal stdin" 0 bash -c "printf '{}' | bash '$CHECKPOINT_SCRIPT' >/dev/null 2>&1"

printf '%s' 'not json' | bash "$CHECKPOINT_SCRIPT" >/dev/null 2>&1
check_exit "exit 0 on malformed stdin" 0 bash -c "printf 'not json' | bash '$CHECKPOINT_SCRIPT' >/dev/null 2>&1"

printf '' | bash "$CHECKPOINT_SCRIPT" >/dev/null 2>&1
check_exit "exit 0 on empty stdin" 0 bash -c "printf '' | bash '$CHECKPOINT_SCRIPT' >/dev/null 2>&1"

# ============================================================================
# § 4. Header and banner structure
# ============================================================================

echo "§ 4. Header and banner"

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "header: [G-Forge Workflow Checkpoint]" "\\[G-Forge Workflow Checkpoint\\]" "$OUTPUT"
check_match "banner: Branch line" "Branch:" "$OUTPUT"
check_match "banner: Review line" "Review:" "$OUTPUT"

# ============================================================================
# § 5. Light tier — minimal output only
# ============================================================================

echo "§ 5. Light tier output"

printf 'light\n' > .claude/integration-tier
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "light tier: Branch line present" "Branch:" "$OUTPUT"
check_match "light tier: Tier line present" "light.*manual mode" "$OUTPUT"
check_match "light tier: commit gate off message" "commit gate off" "$OUTPUT"

# Verify Review and Active lines are NOT in light output
if printf '%s' "$OUTPUT" | grep -q "Review:"; then
    echo "FAIL: light tier should not show Review line"; FAIL=$((FAIL+1))
else
    echo "PASS: light tier omits Review line"; PASS=$((PASS+1))
fi

if printf '%s' "$OUTPUT" | grep -q "Active:"; then
    echo "FAIL: light tier should not show Active line"; FAIL=$((FAIL+1))
else
    echo "PASS: light tier omits Active line"; PASS=$((PASS+1))
fi

# ============================================================================
# § 6. Balanced tier — no auto-trigger advisory
# ============================================================================

echo "§ 6. Balanced tier output"

printf 'balanced\n' > .claude/integration-tier
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "balanced tier: Branch line present" "Branch:" "$OUTPUT"
check_match "balanced tier: Tier line present" "balanced.*no auto-triggers" "$OUTPUT"
check_match "balanced tier: Active line present" "Active:" "$OUTPUT"

# ADR-008 adjudication: on balanced tier, tolerate "no auto-triggers" in the Tier line,
# but verify that no separate auto-trigger ADVISORY lines appear (e.g., "Consider running /g-plan").
# The /g-trim nudge is explicitly tolerated (it's manual-invocation reminder, not auto-trigger).
# Narrow check: search for specific advisory pattern after "Tier:" line to exclude the Tier line itself.
if printf '%s' "$OUTPUT" | sed -n '/Tier:/,$p' | tail -n +2 | grep -qE '(Consider|auto-trigger.*advisory)'; then
    echo "FAIL: balanced tier should not show auto-trigger advisory"; FAIL=$((FAIL+1))
else
    echo "PASS: balanced tier omits auto-trigger advisory"; PASS=$((PASS+1))
fi

# ============================================================================
# § 7. Full tier — complete output
# ============================================================================

echo "§ 7. Full tier output"

printf 'full\n' > .claude/integration-tier
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "full tier: Branch line" "Branch:" "$OUTPUT"
check_match "full tier: Active line" "Active:" "$OUTPUT"
check_match "full tier: Review line" "Review:" "$OUTPUT"
check_match "full tier: Tier line" "full" "$OUTPUT"

# ============================================================================
# § 8. Active context line — from ROADMAP
# ============================================================================

echo "§ 8. Active context extraction"

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

# The fixture's ROADMAP has "Active context: hooks/workflow-checkpoint.sh:60-70 tier resolution"
check_match "active context extracted from ROADMAP" "hooks/workflow-checkpoint.sh:60-70" "$OUTPUT"

# Test missing ROADMAP
rm -f g-docs/ROADMAP.md
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "active context: 'none' when ROADMAP missing" "Active: none" "$OUTPUT"

# Restore ROADMAP for later tests
mkdir -p g-docs
cat > g-docs/ROADMAP.md <<'EOF'
# Test Roadmap
## Active Session
Active context:   · hooks/workflow-checkpoint.sh:60-70 tier resolution
EOF

# Anchor-strip regression: the label appears twice on the line — once as the
# leading label, once repeated inside the prose. A greedy `.*Active context:`
# strip removes through the LAST occurrence, serving garbage; the anchored
# `^Active context:` strip removes only the leading label and keeps the rest.
cat > g-docs/ROADMAP.md <<'EOF'
# Test Roadmap
## Active Session
Active context:   · note about the Active context: label itself · more state
EOF
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "active context: anchored strip keeps trailing prose when label repeats mid-line" "note about the Active context: label itself" "$OUTPUT"

# Restore ROADMAP for later tests (same content as above restore)
cat > g-docs/ROADMAP.md <<'EOF'
# Test Roadmap
## Active Session
Active context:   · hooks/workflow-checkpoint.sh:60-70 tier resolution
EOF

# ============================================================================
# § 9. Review approval status — sentinel detection
# ============================================================================

echo "§ 9. Review approval status"

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "review: not yet approved (no sentinel)" "not yet approved" "$OUTPUT"

# Write a legacy sentinel (bare format, no worktree binding)
printf 'approved_by_reviewer\n' > .claude/g-forge-approved
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "review: approved (legacy sentinel)" "approved.*commit gate open" "$OUTPUT"

# Test new-format sentinel with worktree binding (matching current worktree)
# Use --show-toplevel (same as hook's gf_worktree_key) to match the sentinel key format
CURRENT_WKT=$(git rev-parse --show-toplevel 2>/dev/null)
# Stamp must be ONE line, space-separated, worktree field TERMINAL — gf_parse_stamp
# (hooks/lib/sentinel-read.sh) rejects multi-line content as malformed, which routes
# to the advisory-presence fallback instead of the parser (r2 attestation §9 failure).
printf 'commit_sentinel_ts=2026-07-21T10:00:00Z commit_sentinel_head=abc123def456 commit_sentinel_worktree=%s\n' "$CURRENT_WKT" > .claude/g-forge-approved
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "review: approved (new-format sentinel, matching worktree)" "approved (commit gate open)" "$OUTPUT"

# Test new-format sentinel with DIFFERENT worktree (should not approve)
printf 'commit_sentinel_ts=2026-07-21T10:00:00Z commit_sentinel_head=abc123def456 commit_sentinel_worktree=/other/worktree/path\n' > .claude/g-forge-approved
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "review: not approved (different worktree)" "not yet approved" "$OUTPUT"

# Test malformed/partial sentinel — ADVISORY-PRESENCE CONTRAST (ADR-004/005, W1.6 task 13)
# When a new-format stamp has the worktree= field (triggering new-format parsing) but is missing
# commit_sentinel_ts or commit_sentinel_head, gf_parse_stamp fails; checkpoint's fallback
# (line 123 of workflow-checkpoint.sh) then sets REVIEW_APPROVED=true. This is ADVISORY-ONLY
# behavior: the checkpoint reports "approved" on mere field presence. However, the gating
# consumer (hooks/pre-commit's gf_validate_sentinel, which enforces the real commit gate) would
# DENY this same malformed stamp — it requires all three fields to be present and valid.
# This test pins that contrast: same corrupted-file input, different outcomes from the advisory
# vs gating layers. See hooks/workflow-checkpoint.sh:107-127 and hooks/lib/sentinel-read.sh.

# Case (a): malformed stamp with missing commit_sentinel_ts
cat > .claude/g-forge-approved <<EOF
commit_sentinel_worktree=$CURRENT_WKT
commit_sentinel_head=abc123def456
EOF
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "review: approved despite malformed stamp (missing ts; advisory presence-branch)" "approved (commit gate open)" "$OUTPUT"

# Case (b): malformed stamp with missing commit_sentinel_head
cat > .claude/g-forge-approved <<EOF
commit_sentinel_worktree=$CURRENT_WKT
commit_sentinel_ts=2026-07-21T10:00:00Z
EOF
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "review: approved despite malformed stamp (missing head; advisory presence-branch)" "approved (commit gate open)" "$OUTPUT"

# Clean up sentinel
rm -f .claude/g-forge-approved

# ============================================================================
# § 10. Main branch warning
# ============================================================================

echo "§ 10. Main branch warning"

git checkout -q -b main 2>/dev/null || git checkout -q main 2>/dev/null
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "main branch: warning on main" "on main.*feature branch" "$OUTPUT"

# Switch to feature branch to clear warning
git checkout -q -b feat/test 2>/dev/null || git checkout -q feat/test 2>/dev/null
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
if printf '%s' "$OUTPUT" | grep -q "on main"; then
    echo "FAIL: feature branch should not show main warning"; FAIL=$((FAIL+1))
else
    echo "PASS: feature branch omits main warning"; PASS=$((PASS+1))
fi

# ============================================================================
# § 11. Prompt count tracking and thresholds
# ============================================================================

echo "§ 11. Prompt count and thresholds"

rm -f .claude/session-prompt-count

# First prompt (count = 1)
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
if [ -f ".claude/session-prompt-count" ]; then
    COUNT=$(cat .claude/session-prompt-count 2>/dev/null)
    check "prompt count initialized" "1" "$COUNT"
else
    echo "FAIL: prompt count file not created"; FAIL=$((FAIL+1))
fi

# Second prompt (count = 2)
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
COUNT=$(cat .claude/session-prompt-count 2>/dev/null)
check "prompt count increments" "2" "$COUNT"

# ============================================================================
# § 12. Conversation vs implementation mode detection
# ============================================================================

echo "§ 12. Session mode detection"

rm -f .claude/session-prompt-count .claude/context-threshold-offset

# Make the fixture's initial commit "old" so it doesn't trigger implementation mode.
# The fixture setup at line 111 creates a recent commit; for the conversation-mode
# baseline test to work, that commit must not be "recent" (within 4 hours).
# Amending with an ancient date removes it from git log --since="4 hours ago".
GIT_COMMITTER_DATE="@946684800" git commit --amend --date="@946684800" --no-edit 2>/dev/null || true

# Conversation mode baseline test: prompt-count below amber threshold
# Conversation baseline: BASE_AMBER=45, BASE_RED=65
printf 'full\n' > .claude/integration-tier
printf '37\n' > .claude/session-prompt-count

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22 — mode detection, conversation baseline
# In conversation mode, 37 < 45 (BASE_AMBER), so amber message should NOT appear
if printf '%s' "$OUTPUT" | grep -q "⚠ Context depth.*ACTIVE MONITORING"; then
    echo "FAIL: conversation mode amber should not trigger at 37 (below 45 baseline)"
    FAIL=$((FAIL+1))
else
    echo "PASS: conversation mode silent at 37 (below 45 baseline)"
    PASS=$((PASS+1))
fi

# Trigger implementation mode: create a recent commit
touch .mode-trigger
git add .mode-trigger 2>/dev/null
git commit -q -m "mode trigger" 2>/dev/null || true

# Implementation mode test: same prompt-count, different baseline triggers amber
# Implementation baseline: BASE_AMBER=30, BASE_RED=45
rm -f .claude/session-prompt-count
printf '37\n' > .claude/session-prompt-count

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22 — mode detection, implementation baseline
# In implementation mode, 37 >= 30 (BASE_AMBER), so amber message SHOULD appear
check_match "implementation mode amber at 37 (>= 30 baseline)" \
    "⚠ Context depth.*ACTIVE MONITORING" "$OUTPUT"

# ============================================================================
# § 13. Threshold calibration — offset application
# ============================================================================

echo "§ 13. Threshold offset calibration"

rm -f .claude/context-threshold-offset .claude/session-prompt-count

# Establish this section's own implementation-mode baseline (same
# touch/add/commit mechanism §12 uses) instead of inheriting §12's leftover
# fixture commit — a future edit to §12 must not be able to silently change
# the mode this section runs in.
touch .mode-trigger-13
git add .mode-trigger-13 2>/dev/null
git commit -q -m "mode trigger (section 13)" 2>/dev/null || true

# Implementation baseline: BASE_AMBER=30
# Prompt-count=25 is below the baseline (no offset yet)
printf 'full\n' > .claude/integration-tier
printf '25\n' > .claude/session-prompt-count

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22 — offset calibration, no offset baseline
# Without offset: threshold = 30, so 25 < 30 means amber should NOT appear
if printf '%s' "$OUTPUT" | grep -q "⚠ Context depth.*ACTIVE MONITORING"; then
    echo "FAIL: without offset, amber should not trigger at 25 (below 30 baseline)"
    FAIL=$((FAIL+1))
else
    echo "PASS: without offset — silent at 25 (below 30 baseline)"
    PASS=$((PASS+1))
fi

# Apply offset=8, which lowers threshold from 30 to 22
printf '8\n' > .claude/context-threshold-offset
rm -f .claude/session-prompt-count
printf '25\n' > .claude/session-prompt-count

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22 — offset calibration, with offset applied
# With offset=8: threshold = 30 - 8 = 22, so 25 >= 22 means amber SHOULD appear
check_match "with offset=8, amber at 25 (threshold now 30-8=22)" \
    "⚠ Context depth.*ACTIVE MONITORING" "$OUTPUT"

# ============================================================================
# § 14. Amber threshold message
# ============================================================================

echo "§ 14. Amber threshold (context depth warning)"

rm -f .claude/context-threshold-offset .claude/session-prompt-count

# Fixture is in IMPLEMENTATION mode — the "mode trigger" commit made in §12
# (and §13's own "mode trigger (section 13)" commit) is
# still recent enough to signal implementation mode here.
# For implementation mode: BASE_AMBER=30, BASE_RED=45. We test the amber band
# by setting prompt count to 35 (30 <= 35 < 45, so amber triggers but not red).
# This pins the implementation-mode thresholds and the amber message flow.
printf 'full\n' > .claude/integration-tier
printf '35\n' > .claude/session-prompt-count

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "amber: warning marker" "⚠ Context depth" "$OUTPUT"
check_match "amber: ACTIVE MONITORING message" "ACTIVE MONITORING" "$OUTPUT"
check_match "amber: 25% of window USED direction (not remaining)" "of the window has been used" "$OUTPUT"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-30
check_no_match "amber: old 'remaining capacity' direction absent" "remaining capacity" "$OUTPUT"
check_no_match "amber: old 'drops below' direction absent" "drops below" "$OUTPUT"

# ============================================================================
# § 15. Red threshold message
# ============================================================================

echo "§ 15. Red threshold (enforced reset)"

rm -f .claude/session-prompt-count

# Simulate very high prompt count that triggers red (conversation mode red=65)
printf 'full\n' > .claude/integration-tier
printf '65\n' > .claude/session-prompt-count

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "red: enforced marker" "!! Context depth"  "$OUTPUT"
check_match "red: Context depth message" "Context depth" "$OUTPUT"
check_match "red: ENFORCED message" "ENFORCED" "$OUTPUT"
check_match "red: fresh session nudge" "start fresh session" "$OUTPUT"

# ============================================================================
# § 16. Compaction escalation
# ============================================================================

echo "§ 16. Compaction escalation"

rm -f .claude/session-prompt-count .claude/session-compaction-count

# With one auto-compaction
printf '1\n' > .claude/session-compaction-count

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "compaction: enforced marker" "!! Context compacted" "$OUTPUT"
check_match "compaction: count displayed" "compacted 1×" "$OUTPUT"
check_match "compaction: reset nudge" "fresh session" "$OUTPUT"

# ============================================================================
# § 17. Milestone health — clean
# ============================================================================

echo "§ 17. Milestone health"

rm -f .claude/session-compaction-count
printf 'full\n' > .claude/integration-tier

# Clean health (no rework, no blocked, no holds)
rm -f .claude/review-holds
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "health: clean status" "Health: ✓ clean" "$OUTPUT"

# ============================================================================
# § 18. Milestone health — degraded
# ============================================================================

echo "§ 18. Milestone health (degraded)"

# Create some health signals
printf '2\n' > .claude/review-holds

# Create a blocked task in todo.md
mkdir -p g-docs
cat > g-docs/todo.md <<'EOF'
| # | Task | Notes |
|----|------|-------|
| 1 | fix bug | BLOCKED: depends on #2 * |
EOF

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "health: warning emoji" "Health: ⚠" "$OUTPUT"
check_match "health: holds count" "2 holds" "$OUTPUT"
check_match "health: blocked count" "1 blocked" "$OUTPUT"

# Clean up
rm -f .claude/review-holds g-docs/todo.md

# ============================================================================
# § 19. Tier line display
# ============================================================================

echo "§ 19. Tier line output"

printf 'full\n' > .claude/integration-tier
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "tier line: full tier" "Tier:.*full" "$OUTPUT"

printf 'balanced\n' > .claude/integration-tier
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "tier line: balanced tier" "Tier:.*balanced" "$OUTPUT"

printf 'light\n' > .claude/integration-tier
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "tier line: light tier" "Tier:.*light" "$OUTPUT"

# Garbage/corrupted tier file: must default to full (never gate on it — this
# hook is non-gating) but surface the unrecognized value distinctly instead
# of silently reading identically to a clean, deliberate "full".
printf 'garbage\n' > .claude/integration-tier
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "tier line: unrecognized value defaults to full and surfaces distinctly" \
    "Tier:.*full (unrecognized value 'garbage' — defaulting)" "$OUTPUT"
check_exit "tier line: garbage tier value never exits non-zero" 0 \
    bash -c "printf '{}' | bash '$CHECKPOINT_SCRIPT'"

# ============================================================================
# § 20. Roundtable heartbeat (M33)
# ============================================================================

echo "§ 20. Roundtable heartbeat"

printf 'full\n' > .claude/integration-tier

# Without .claude/roundtable
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
if printf '%s' "$OUTPUT" | grep -q "Roundtable"; then
    echo "FAIL: roundtable line should not appear without binding"; FAIL=$((FAIL+1))
else
    echo "PASS: no roundtable line when unbound"; PASS=$((PASS+1))
fi

# With .claude/roundtable
cat > .claude/roundtable <<'EOF'
title=Test Surface
url=https://example.com
EOF

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "roundtable: heartbeat message" "· Roundtable bound" "$OUTPUT"
check_match "roundtable: title extracted" "Test Surface" "$OUTPUT"

rm -f .claude/roundtable

# ============================================================================
# § 21. Listen mode indicator
# ============================================================================

echo "§ 21. Listen mode (Tier 3)"

printf 'full\n' > .claude/integration-tier

# Without listen mode active
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
if printf '%s' "$OUTPUT" | grep -q "Listen mode"; then
    echo "FAIL: listen mode line should not appear when inactive"; FAIL=$((FAIL+1))
else
    echo "PASS: no listen mode line when inactive"; PASS=$((PASS+1))
fi

# With listen mode active
printf '3\n' > .claude/tier3-active

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "listen mode: active indicator" "Listen mode ACTIVE" "$OUTPUT"
check_match "listen mode: item count" "3 item" "$OUTPUT"

rm -f .claude/tier3-active

# ============================================================================
# § 22. Handoff nudge (first prompt)
# ============================================================================

echo "§ 22. Handoff nudge (fresh session re-entry)"

rm -f .claude/session-prompt-count .claude/compact-state.md

printf 'full\n' > .claude/integration-tier

# First prompt (count = 1) with handoff in ROADMAP
cat > g-docs/ROADMAP.md <<'EOF'
# ROADMAP
## Active Session
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — test | branch: feat/test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · fixture setup
Next up:          · write tests
Active context:   · hooks/workflow-checkpoint.sh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )

check_match "handoff: fresh session nudge" "Fresh session.*handoff" "$OUTPUT"
check_match "handoff: /g-resume recommendation" "/g-resume" "$OUTPUT"

# Duplicate-heading warning — the fixture above (line ~633) has exactly one
# '## Active Session' heading; confirm the warning does NOT fire on it (no
# false positive). Own capture — not borrowed from the handoff-nudge OUTPUT
# above, since this pins a distinct assertion against the same fixture.
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-27
DUP_HEADING_OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
if printf '%s' "$DUP_HEADING_OUTPUT" | grep -q "replace-never-append violated"; then
    echo "FAIL: duplicate-heading warning should not fire with a single heading"; FAIL=$((FAIL+1))
else
    echo "PASS: no duplicate-heading warning with a single Active Session heading"; PASS=$((PASS+1))
fi

# Now a fixture with TWO '## Active Session' headings — replace-never-append
# violated (G-RULES §I). Handoff residue accumulated across passes served a
# week-stale banner (retro 2026-07-23-m46-update-integrity).
cat > g-docs/ROADMAP.md <<'EOF'
# ROADMAP
## Active Session
Done this pass:   · fixture setup
## Active Session
Next up:          · write tests
EOF
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "duplicate-heading warning: fires with two Active Session headings" "replace-never-append violated" "$OUTPUT"

# Restore single-heading fixture for §23 onward (mirrors the anchored-strip
# restore at :242-247 — leaving the two-heading fixture in place would leak
# a replace-never-append violation into sections that assume a well-formed
# ROADMAP).
cat > g-docs/ROADMAP.md <<'EOF'
# ROADMAP
## Active Session
Active context:   · hooks/workflow-checkpoint.sh
EOF

# ============================================================================
# § 22b. Handoff nudge — block-scoped, not whole-file (audit 2026-08-30
# fable-f3-survives-skills-ledger Part 2 row 18 item 2 / A-5)
# ============================================================================
#
# Pre-fix, `grep -qi 'verify ADR' g-docs/ROADMAP.md .claude/compact-state.md`
# ran whole-file, so a `verify ADR` phrase anywhere in ROADMAP body prose (or
# a stale compact-state.md snapshot) printed the ADR-variant nudge on every
# fresh session regardless of whether the phrase was actually part of the
# handed-off Next-up item. Post-fix, only the `## Active Session` block's
# Next-up line(s) — and compact-state.md's mirrored "## Handoff at
# compaction" section — are tested.

echo "§ 22b. Handoff nudge — block-scoped Next-up test"

# (a) Next-up line itself carries "verify ADR-014" — ADR-variant fires.
rm -f .claude/session-prompt-count .claude/compact-state.md
cat > g-docs/ROADMAP.md <<'EOF'
# ROADMAP
## Active Session
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — test | branch: feat/test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · fixture setup
Next up:          · verify ADR-014 before continuing
Active context:   · hooks/workflow-checkpoint.sh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
# provenance: case (a) is the positive-path case -- the phrase legitimately
# IS in the Next-up line, so this assertion stays green under the pre-fix
# whole-file guard too (non-discriminating). The RED-proving probes are
# cases (b)/(c) below -- probe run 2026-08-31, task-46 record
# (task-46-checkpoint-nudge.md:86-90).
check_match "A-5 (a): Next-up carries 'verify ADR' — ADR-variant nudge fires" \
    "a handed-off ADR needs verifying first" "$OUTPUT"
# falsifiability: this check_no_match is guard-shaped (passes by the generic
# message NOT appearing) -- neutered the mutual exclusivity of the ADR/generic
# branches in a scratch copy of hooks/workflow-checkpoint.sh (both branches
# forced to always print), reproduced this fixture, confirmed RED: the
# generic-absent assertion failed with "re-hydrate context before new work"
# present in output while the ADR-variant assertion stayed green. Scratch
# probe run 2026-08-31, production tree untouched
# (g-docs/agent-output/wave-f3/task-49-marker-truth.md).
check_no_match "A-5 (a): generic-only variant absent when the ADR variant correctly fires" \
    "re-hydrate context before new work" "$OUTPUT"

# (b) "verify ADR" appears ONLY in ROADMAP body prose, outside the Active
# Session block — generic nudge fires, NOT the ADR variant.
rm -f .claude/session-prompt-count .claude/compact-state.md
cat > g-docs/ROADMAP.md <<'EOF'
# ROADMAP
## Active Session
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — test | branch: feat/test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · fixture setup
Next up:          · write tests
Active context:   · hooks/workflow-checkpoint.sh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Milestone Notes
Remember to verify ADR-009 before the next release cut — this line lives in
body prose, outside the Active Session block.
EOF
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-31
check_match "A-5 (b): generic nudge fires when 'verify ADR' is only in body prose outside the block" \
    "re-hydrate context before new work" "$OUTPUT"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-31
check_no_match "A-5 (b): ADR-variant absent when the phrase sits outside the Active Session block" \
    "a handed-off ADR needs verifying first" "$OUTPUT"

# (c) .claude/compact-state.md carries "verify ADR" outside its own Next-up
# line(s) (in the "## Recent commits" section) — generic nudge fires, NOT
# the ADR variant. ROADMAP itself is clean (no "verify ADR" anywhere) so
# only the compact-state.md path is under test here.
rm -f .claude/session-prompt-count
cat > g-docs/ROADMAP.md <<'EOF'
# ROADMAP
## Active Session
Active context:   · hooks/workflow-checkpoint.sh
EOF
cat > .claude/compact-state.md <<'EOF'
# Compact State — 2026-08-16T00:00:00Z

## Branch
main

## Recent commits
abc1234 verify ADR-014 fix

## Handoff at compaction
Done this pass:   · fixture setup
Next up:          · write tests
Active context:   · hooks/workflow-checkpoint.sh

---
*Written by pre-compact hook at 2026-08-16T00:00:00Z. Load this file at session start to recover context.*
EOF
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-31
check_match "A-5 (c): generic nudge fires when compact-state.md carries 'verify ADR' outside its Next-up line" \
    "re-hydrate context before new work" "$OUTPUT"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-31
check_no_match "A-5 (c): ADR-variant absent when the phrase sits outside compact-state.md's Next-up line" \
    "a handed-off ADR needs verifying first" "$OUTPUT"

# Clean up compact-state.md and restore the clean single-heading ROADMAP for
# §23 onward.
rm -f .claude/compact-state.md .claude/session-prompt-count
cat > g-docs/ROADMAP.md <<'EOF'
# ROADMAP
## Active Session
Active context:   · hooks/workflow-checkpoint.sh
EOF

# ============================================================================
# § 23. Non-gating with various malformed inputs
# ============================================================================

echo "§ 23. Robustness with malformed inputs"

# Malformed stdin should still exit 0
printf 'incomplete json {' | bash "$CHECKPOINT_SCRIPT" >/dev/null 2>&1
check_exit "malformed json stdin" 0 bash -c "printf 'incomplete json {' | bash '$CHECKPOINT_SCRIPT' >/dev/null 2>&1"

# Null bytes in stdin (unlikely but possible)
printf 'text\x00more' | bash "$CHECKPOINT_SCRIPT" >/dev/null 2>&1
check_exit "null byte in stdin" 0 bash -c "printf 'text\x00more' | bash '$CHECKPOINT_SCRIPT' >/dev/null 2>&1"

# ============================================================================
# § 24. Worktree prompt count file handling (F10 — ADR-005 contract pin)
# ============================================================================

echo "§ 24. Worktree prompt count file handling"

# W1.6 fix: PROMPT_COUNT_FILE should use $GF_CLAUDE_DIR to resolve the prompt
# count file in the PRIMARY tree's .claude/, not as a bare relative path.
# This pins the fix and ensures linked worktrees correctly increment the
# primary tree's session-prompt-count without "No such file or directory" errors.
#
# Test: simulate worktree environment by:
# 1. Create a subdirectory to represent a linked worktree
# 2. Set GF_CLAUDE_DIR to point to the primary tree's .claude
# 3. Run hook from the worktree directory
# 4. Verify no "No such file or directory" errors
# 5. Verify primary tree's prompt count increments

# Create a simulated linked worktree directory
mkdir -p "$FIXTURE/worktree" 2>/dev/null
cd "$FIXTURE/worktree" || { echo "FAIL: could not enter worktree dir"; FAIL=$((FAIL+1)); }

# Initialize git worktree linkage (mock)
mkdir -p .git/worktrees/mock 2>/dev/null

# Clear the primary tree's prompt count to establish baseline
rm -f "$FIXTURE/.claude/session-prompt-count"

# Run the hook from the worktree, with GF_CLAUDE_DIR pointing to primary tree
# (in a real integration, the hook's gf_guard_claude_dir would resolve this)
ERROR_OUTPUT=$(
    GF_CLAUDE_DIR="$FIXTURE/.claude" \
    bash "$CHECKPOINT_SCRIPT" 2>&1 >/dev/null
)

# Verify: no "No such file or directory" error for session-prompt-count on stderr
if printf '%s' "$ERROR_OUTPUT" | grep -q "session-prompt-count.*No such file or directory"; then
    echo "FAIL: worktree should not error writing prompt count"; FAIL=$((FAIL+1))
else
    echo "PASS: worktree prompt count write succeeds"; PASS=$((PASS+1))
fi

# Verify: primary tree's prompt count file exists and incremented
if [ -f "$FIXTURE/.claude/session-prompt-count" ]; then
    PRIMARY_COUNT=$(cat "$FIXTURE/.claude/session-prompt-count" 2>/dev/null)
    if [ "$PRIMARY_COUNT" = "1" ]; then
        echo "PASS: primary tree prompt count initialized"; PASS=$((PASS+1))
    else
        echo "FAIL: primary tree prompt count wrong (expected 1, got $PRIMARY_COUNT)"; FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: primary tree prompt count file not created"; FAIL=$((FAIL+1))
fi

# Return to fixture root for cleanup
cd "$FIXTURE" || true

# ============================================================================
# § 25. Session-scoped prompt counter (M-audit W3 task 14)
# ============================================================================

echo "§ 25. Session-scoped prompt counter"

printf 'full\n' > .claude/integration-tier
rm -f .claude/session-prompt-count .claude/session-prompt-count.*

# 25.1 With a session_id in the UserPromptSubmit payload, increments land in
# the SESSION-KEYED file, not the legacy bare one.
OUTPUT=$( printf '{"session_id":"sess-x"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
if [ -f ".claude/session-prompt-count.sess-x" ]; then
    COUNT=$(cat .claude/session-prompt-count.sess-x 2>/dev/null)
    check "session_id present: keyed counter file created and set to 1" "1" "$COUNT"
else
    echo "FAIL: keyed counter file .claude/session-prompt-count.sess-x not created"; FAIL=$((FAIL+1))
fi
if [ -f ".claude/session-prompt-count" ]; then
    echo "FAIL: legacy bare counter file should not be touched when session_id is present"; FAIL=$((FAIL+1))
else
    echo "PASS: legacy bare counter file untouched when session_id is present"; PASS=$((PASS+1))
fi

# 25.2 Two CONCURRENT sessions on the same project keep independent counts —
# incrementing session A's counter must never touch session B's (pre-fix, a
# single project-wide session-prompt-count file was shared/clobbered).
rm -f .claude/session-prompt-count.sess-x
printf '5\n' > .claude/session-prompt-count.sess-a
printf '9\n' > .claude/session-prompt-count.sess-b
OUTPUT=$( printf '{"session_id":"sess-a"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
A_COUNT=$(cat .claude/session-prompt-count.sess-a 2>/dev/null)
B_COUNT=$(cat .claude/session-prompt-count.sess-b 2>/dev/null)
check "concurrent sessions: session A's counter increments independently" "6" "$A_COUNT"
check "concurrent sessions: session B's counter untouched by A's prompt" "9" "$B_COUNT"

# 25.3 No session_id in payload — graceful fallback to the legacy bare
# filename (matches session-start.sh's fallback; single-session behavior
# identical to before this fix).
rm -f .claude/session-prompt-count .claude/session-prompt-count.sess-a .claude/session-prompt-count.sess-b
OUTPUT=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
if [ -f ".claude/session-prompt-count" ]; then
    COUNT=$(cat .claude/session-prompt-count 2>/dev/null)
    check "no session_id: falls back to legacy bare counter filename" "1" "$COUNT"
else
    echo "FAIL: legacy bare counter file not created when session_id absent"; FAIL=$((FAIL+1))
fi

rm -f .claude/session-prompt-count .claude/session-prompt-count.*

# ============================================================================
# § 26. Self-update check — plugin-cache path resolution (M-audit W3 task 13)
# ============================================================================

echo "§ 26. Self-update check — plugin-cache path resolution"

# The self-update nudge used to hardcode a bare two-segment path
# ($HOME/.claude/plugins/cache/g-forge/g-forge/.claude-plugin/plugin.json)
# with NO version-directory segment — but the real installed cache always
# nests plugin content under a version dir (e.g. .../g-forge/g-forge/0.3.3/
# .claude-plugin/plugin.json, per skills/g-update/SKILL.md Step 2), so the
# old path never matched a real install and the whole nudge was silently
# dead on every consumer project. These fixtures override HOME so
# $HOME/.claude is an isolated scratch dir, independent of the project
# fixture's own .claude/ (GF_CLAUDE_DIR) used by every other assertion here.
FAKE_HOME="$(mktemp -d)"
mkdir -p "$FAKE_HOME/.claude"
# Pre-touch the check-stamp so the hook never fires a real background curl
# during these fixtures (avoids network flakiness/latency in the suite).
touch "$FAKE_HOME/.claude/g-forge-check-stamp"

# 26.1 Realistic install shape (version dir present), versions MATCH — no
# update-available line.
mkdir -p "$FAKE_HOME/.claude/plugins/cache/g-forge/g-forge/0.3.3/.claude-plugin"
printf '{"name":"g-forge","version":"0.3.3"}' > "$FAKE_HOME/.claude/plugins/cache/g-forge/g-forge/0.3.3/.claude-plugin/plugin.json"
printf '0.3.3' > "$FAKE_HOME/.claude/g-forge-latest-version"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME" bash "$CHECKPOINT_SCRIPT" 2>&1 )
if printf '%s' "$OUTPUT" | grep -q "update available"; then
    echo "FAIL: matching versions should not show update-available line"; FAIL=$((FAIL+1))
else
    echo "PASS: matching versions show no update-available line"; PASS=$((PASS+1))
fi

# 26.2 FAIL-BEFORE/PASS-AFTER pin: same realistic shape, versions DIFFER —
# under the pre-fix hardcoded bare path this manifest is never found (no
# version dir in that path), so this line would never print regardless of
# version mismatch. Under the fix, the highest-version dir is resolved and
# the mismatch is correctly surfaced. (Verified empirically against the
# pre-fix hook during implementation: this exact fixture produced no
# update-available line at all before the fix.)
printf '9.9.9' > "$FAKE_HOME/.claude/g-forge-latest-version"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME" bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "version mismatch (realistic install shape) surfaces update line" \
    "g-forge update available: 0\\.3\\.3 → 9\\.9\\.9" "$OUTPUT"

# 26.3 Multiple version dirs present — the HIGHEST semver is selected, not
# an arbitrary/first one.
mkdir -p "$FAKE_HOME/.claude/plugins/cache/g-forge/g-forge/0.3.2/.claude-plugin"
printf '{"name":"g-forge","version":"0.3.2"}' > "$FAKE_HOME/.claude/plugins/cache/g-forge/g-forge/0.3.2/.claude-plugin/plugin.json"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME" bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "multiple version dirs: highest semver (0.3.3) is used, not 0.3.2" \
    "g-forge update available: 0\\.3\\.3 → 9\\.9\\.9" "$OUTPUT"

# 26.4 Legacy/malformed shape (manifest directly at the bare path, no
# version dir at all — the shape the OLD hardcoded path expected) must NOT
# be picked up: only a version-directory-nested manifest is recognized.
FAKE_HOME2="$(mktemp -d)"
mkdir -p "$FAKE_HOME2/.claude/plugins/cache/g-forge/g-forge/.claude-plugin"
printf '{"name":"g-forge","version":"0.3.3"}' > "$FAKE_HOME2/.claude/plugins/cache/g-forge/g-forge/.claude-plugin/plugin.json"
printf '9.9.9' > "$FAKE_HOME2/.claude/g-forge-latest-version"
touch "$FAKE_HOME2/.claude/g-forge-check-stamp"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME2" bash "$CHECKPOINT_SCRIPT" 2>&1 )
if printf '%s' "$OUTPUT" | grep -q "update available"; then
    echo "FAIL: bare non-versioned manifest path should not be recognized"; FAIL=$((FAIL+1))
else
    echo "PASS: bare non-versioned manifest path is correctly ignored"; PASS=$((PASS+1))
fi

# 26.5 No plugin cache at all (self-host / no consumer install) — exits 0,
# no update line, no crash.
FAKE_HOME3="$(mktemp -d)"
mkdir -p "$FAKE_HOME3/.claude"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME3" bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_exit "no plugin cache: exits 0" 0 bash -c "printf '{}' | HOME='$FAKE_HOME3' bash '$CHECKPOINT_SCRIPT' >/dev/null 2>&1"
if printf '%s' "$OUTPUT" | grep -q "update available"; then
    echo "FAIL: no plugin cache should not show update-available line"; FAIL=$((FAIL+1))
else
    echo "PASS: no plugin cache shows no update-available line"; PASS=$((PASS+1))
fi

# 26.6 Cache-dir pick routes through gf_semver_compare (ADR-009), not sort -V:
# hotfix-suffix dirs must order by the shared lib's grammar — 2.3.3a is NEWER
# than 2.3.3, so the hotfix dir wins the highest-version pick. Locks that the
# reduce loop consumes the lib and survives the repo's own version grammar.
FAKE_HOME4="$(mktemp -d)"
mkdir -p "$FAKE_HOME4/.claude/plugins/cache/g-forge/g-forge/2.3.3/.claude-plugin"
printf '{"name":"g-forge","version":"2.3.3"}' > "$FAKE_HOME4/.claude/plugins/cache/g-forge/g-forge/2.3.3/.claude-plugin/plugin.json"
mkdir -p "$FAKE_HOME4/.claude/plugins/cache/g-forge/g-forge/2.3.3a/.claude-plugin"
printf '{"name":"g-forge","version":"2.3.3a"}' > "$FAKE_HOME4/.claude/plugins/cache/g-forge/g-forge/2.3.3a/.claude-plugin/plugin.json"
printf '9.9.9' > "$FAKE_HOME4/.claude/g-forge-latest-version"
touch "$FAKE_HOME4/.claude/g-forge-check-stamp"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME4" bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "hotfix-suffix dirs: lib picks 2.3.3a (newer than 2.3.3) as highest" \
    "g-forge update available: 2\\.3\\.3a → 9\\.9\\.9" "$OUTPUT"

rm -rf "$FAKE_HOME" "$FAKE_HOME2" "$FAKE_HOME3" "$FAKE_HOME4"

# Restore fixture's own integration-tier for anything that follows.
printf 'full\n' > .claude/integration-tier

# ============================================================================
# § 27. Direction-aware update nudge — semver comparison (M46 W1 task 5)
# ============================================================================
#
# Post-fix (Wave-2 task 4): hook sources hooks/lib/semver-compare.sh and uses
# direction-aware semver comparison to decide update-line presence:
# - LATEST newer than INSTALLED → print update nudge line
# - LATEST equal to INSTALLED → no update line
# - LATEST older than INSTALLED → no update line + "cache lags repo" note instead
#
# These cases PIN that behavior. Case 27.3 (LATEST older) is authored to FAIL
# against the current (pre-fix) hook, which checks inequality without direction —
# it would incorrectly print "update available: 0.3.3 → 0.3.1" (backwards nudge).
# After Wave-2 task 4 lands, case 27.3 will PASS. Cases 27.1 and 27.2 PASS
# both pre- and post-fix (though pre-fix for different reasons: inequality vs
# semver-newer).

echo "§ 27. Direction-aware update nudge"

# Setup fresh fixture
FAKE_HOME_DIR_NEW="$(mktemp -d)"
mkdir -p "$FAKE_HOME_DIR_NEW/.claude"
touch "$FAKE_HOME_DIR_NEW/.claude/g-forge-check-stamp"

# 27.1 LATEST newer than INSTALLED — update line present
# Pre-fix: inequality check catches this → update line prints ✓
# Post-fix: semver-newer check catches this → update line prints ✓
mkdir -p "$FAKE_HOME_DIR_NEW/.claude/plugins/cache/g-forge/g-forge/0.3.3/.claude-plugin"
printf '{"name":"g-forge","version":"0.3.3"}' > "$FAKE_HOME_DIR_NEW/.claude/plugins/cache/g-forge/g-forge/0.3.3/.claude-plugin/plugin.json"
printf '0.4.0\n' > "$FAKE_HOME_DIR_NEW/.claude/g-forge-latest-version"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME_DIR_NEW" bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "27.1: LATEST newer (0.3.3 → 0.4.0) — update line present" \
    "g-forge update available: 0\\.3\\.3 → 0\\.4\\.0" "$OUTPUT"

# 27.2 LATEST equal to INSTALLED — no update line
# Pre-fix: inequality check rejects (equal) → no line ✓
# Post-fix: equal check rejects → no line ✓
printf '0.3.3\n' > "$FAKE_HOME_DIR_NEW/.claude/g-forge-latest-version"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME_DIR_NEW" bash "$CHECKPOINT_SCRIPT" 2>&1 )
if printf '%s' "$OUTPUT" | grep -q "update available"; then
    echo "FAIL: 27.2 — equal versions should not show update line"; FAIL=$((FAIL+1))
else
    echo "PASS: 27.2 — equal versions (0.3.3 == 0.3.3) show no update line"; PASS=$((PASS+1))
fi

# 27.3 LATEST older than INSTALLED — FAIL-BEFORE/PASS-AFTER pin
# Pre-fix: inequality check catches (0.3.1 != 0.3.3) → prints backwards "update available: 0.3.3 → 0.3.1" ✗ THIS FAILS
# Post-fix: semver-older check detects direction → no update line + "cache lags repo" note ✓
# This case is authored to RED/FAIL pre-fix; HQ captures this as fail-before evidence.
printf '0.3.1\n' > "$FAKE_HOME_DIR_NEW/.claude/g-forge-latest-version"
OUTPUT=$( printf '{}' | HOME="$FAKE_HOME_DIR_NEW" bash "$CHECKPOINT_SCRIPT" 2>&1 )

# Pre-fix expectation: this SHOULD FAIL (update line wrongly present)
if printf '%s' "$OUTPUT" | grep -q "update available: 0\\.3\\.3 → 0\\.3\\.1"; then
    # This is the EXPECTED FAIL pre-fix (backwards update nudge)
    echo "FAIL: 27.3 — LATEST older (0.3.3 > 0.3.1) — update line wrongly present (expected to fail pre-fix, pass post-fix after semver-compare.sh lands)"
    FAIL=$((FAIL+1))
else
    # Post-fix expectation: no update line + cache-lags-repo note
    if printf '%s' "$OUTPUT" | grep -q "cache lags repo"; then
        echo "PASS: 27.3 — LATEST older (0.3.1 < 0.3.3) — no update line, 'cache lags repo' note present (post-fix behavior)"
        PASS=$((PASS+1))
    else
        # Neither update line nor note — this means neither the pre-fix bug nor post-fix fix is in place
        echo "FAIL: 27.3 — LATEST older (0.3.1 < 0.3.3) — neither update line nor 'cache lags repo' note present (unexpected state)"
        FAIL=$((FAIL+1))
    fi
fi

rm -rf "$FAKE_HOME_DIR_NEW"

# ============================================================================
# § 28. Banner-on-delta — session-keyed stable-slice suppression (v2.6)
# ============================================================================
#
# The stable slice (header, Branch, Active, Review, Roundtable, Listen,
# Health, Tier) is hashed per prompt into .claude/banner-hash.<session_id>
# and suppressed when unchanged. The gate keys on session_id: every fixture
# above pipes a payload WITHOUT one, so those cases pin the always-print
# degrade path; the cases here supply a session_id and pin the delta path.
# Escalations (amber/red/compaction) keep their every-prompt cadence — the
# §A7 gate is a frequency contract, not a wording one.

echo "§ 28. Banner-on-delta suppression"

printf 'full\n' > .claude/integration-tier
rm -f .claude/session-prompt-count .claude/session-prompt-count.* \
      .claude/banner-hash.* .claude/g-forge-approved \
      .claude/session-compaction-count .claude/context-threshold-offset

# 28.1 With a session_id, two identical consecutive prompts: prompt 1 prints
# the full stable slice; prompt 2 (state unchanged) suppresses it entirely.
OUT1=$( printf '{"session_id":"sess-delta"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "28.1: prompt 1 with session_id prints full stable slice" "Branch:" "$OUT1"
OUT2=$( printf '{"session_id":"sess-delta"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
# falsifiability: PRINT_STABLE forced true in a scratch copy, cases confirmed red — 2026-09-02
check_no_match "28.1: prompt 2 unchanged state suppresses Branch line" "Branch:" "$OUT2"
check_no_match "28.1: prompt 2 unchanged state suppresses Review line" "Review:" "$OUT2"
check_no_match "28.1: prompt 2 unchanged state suppresses Tier line" "Tier:" "$OUT2"
check_exit "28.1: suppressed prompt still exits 0" 0 \
    bash -c "printf '{\"session_id\":\"sess-delta\"}' | bash '$CHECKPOINT_SCRIPT' >/dev/null 2>&1"

# 28.2 Banner-hash cache file uses the session-keyed name (and only that).
if [ -f ".claude/banner-hash.sess-delta" ]; then
    echo "PASS: 28.2: banner-hash file uses the session-keyed name"; PASS=$((PASS+1))
else
    echo "FAIL: 28.2: .claude/banner-hash.sess-delta not created"; FAIL=$((FAIL+1))
fi

# 28.3 Escalations still print on EVERY prompt while the stable slice is
# suppressed — and the header is re-printed so their output is not orphaned.
# The fixture is in implementation mode (recent §12/§13 commits): amber=30,
# red=45, so counts 41/42 sit in the amber band on both prompts.
rm -f .claude/session-prompt-count.sess-esc .claude/banner-hash.sess-esc
printf '40\n' > .claude/session-prompt-count.sess-esc
OUT1=$( printf '{"session_id":"sess-esc"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "28.3: amber escalation on the full-print prompt" \
    "⚠ Context depth.*ACTIVE MONITORING" "$OUT1"
OUT2=$( printf '{"session_id":"sess-esc"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "28.3: amber escalation repeats on the suppressed prompt" \
    "⚠ Context depth.*ACTIVE MONITORING" "$OUT2"
check_match "28.3: header re-printed when only escalations print (no orphan)" \
    "\\[G-Forge Workflow Checkpoint\\]" "$OUT2"
check_no_match "28.3: stable slice stays suppressed around the escalation" "Branch:" "$OUT2"

# 28.4 State change between prompts forces a full reprint: writing the review
# sentinel changes the Review line, so the hash differs and the slice returns.
rm -f .claude/session-prompt-count.sess-chg .claude/banner-hash.sess-chg
OUT1=$( printf '{"session_id":"sess-chg"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
OUT2=$( printf '{"session_id":"sess-chg"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_no_match "28.4: pre-change repeat prompt is suppressed" "Review:" "$OUT2"
printf 'approved_by_reviewer\n' > .claude/g-forge-approved
OUT3=$( printf '{"session_id":"sess-chg"}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "28.4: sentinel written between prompts — full reprint" "Branch:" "$OUT3"
check_match "28.4: reprint carries the new Review state" "approved (commit gate open)" "$OUT3"
rm -f .claude/g-forge-approved

# 28.5 No session_id — both consecutive prompts print in full (the degrade
# path every pre-v2.6 case runs), and no banner-hash cache file is written.
rm -f .claude/session-prompt-count .claude/banner-hash \
      .claude/session-prompt-count.sess-delta .claude/session-prompt-count.sess-esc \
      .claude/session-prompt-count.sess-chg
OUT1=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
OUT2=$( printf '{}' | bash "$CHECKPOINT_SCRIPT" 2>&1 )
check_match "28.5: no session_id — prompt 1 prints full slice" "Branch:" "$OUT1"
check_match "28.5: no session_id — repeat prompt still prints Branch" "Branch:" "$OUT2"
check_match "28.5: no session_id — repeat prompt still prints Review" "Review:" "$OUT2"
check_match "28.5: no session_id — repeat prompt still prints Tier" "Tier:" "$OUT2"
if [ -f ".claude/banner-hash" ]; then
    echo "FAIL: 28.5: bare banner-hash file must not be written without a session_id"; FAIL=$((FAIL+1))
else
    echo "PASS: 28.5: no bare banner-hash file without a session_id"; PASS=$((PASS+1))
fi

# §28 cleanup — leave no session-keyed state behind for future sections.
rm -f .claude/session-prompt-count .claude/session-prompt-count.* .claude/banner-hash.*

# ============================================================================
# § Cleanup and results
# ============================================================================

cd / && rm -rf "$FIXTURE"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

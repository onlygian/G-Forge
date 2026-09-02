#!/bin/bash
# test-resume-sync.sh — /g-resume Step 0 script (sync-check.sh) behavioral suite
# Verifies the KEY: value output contract against fixture repos:
# - every script-emittable Freshness closed-set value is reachable,
# - the fast-forward fires only when the prompt counter reads exactly 1
#   (conservative multi-candidate rule included),
# - the DIVERGED contract (no FRESHNESS line; the skill must ask),
# - the 0g Record-axis closed set, including the one silent case
#   (current branch IS the record branch) and the honest-unknown value.
# The script always exits 0 — outcomes live in output, never exit codes.
#
# Resolve script dir to an ABSOLUTE path exactly once, before any fixture cd.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC="$(cd "$SCRIPT_DIR/../skills/g-resume/scripts" && pwd)/sync-check.sh"

PASS=0
FAIL=0

# ============================================================================
# § Helper functions
# ============================================================================

# check_contains <name> <haystack> <needle> — fixed-string substring assert
check_contains() {
    local name="$1" haystack="$2" needle="$3"
    if printf '%s\n' "$haystack" | grep -qF -- "$needle"; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected to contain '$needle', got '$haystack')"; FAIL=$((FAIL+1))
    fi
}

# check_absent <name> <haystack> <needle> — fixed-string absence assert
check_absent() {
    local name="$1" haystack="$2" needle="$3"
    if printf '%s\n' "$haystack" | grep -qF -- "$needle"; then
        echo "FAIL: $name (expected NOT to contain '$needle', got '$haystack')"; FAIL=$((FAIL+1))
    else
        echo "PASS: $name"; PASS=$((PASS+1))
    fi
}

# check_line <name> <haystack> <line> — exact full-line assert
check_line() {
    local name="$1" haystack="$2" line="$3"
    if printf '%s\n' "$haystack" | grep -qxF -- "$line"; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected line '$line', got '$haystack')"; FAIL=$((FAIL+1))
    fi
}

# check_value <name> <expected> <actual>
check_value() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected '$expected', got '$actual')"; FAIL=$((FAIL+1))
    fi
}

run_sync() { (cd "$1" && bash "$SYNC" 2>/dev/null); }

gcfg() { git -C "$1" config user.email "test@g-forge.local"; git -C "$1" config user.name "test"; }

# make_world <dir> — bare upstream (main, one commit with g-docs/ROADMAP.md)
# plus clones "work" and "other", both with origin/HEAD set (clone semantics).
make_world() {
    local w="$1"
    git init -q --bare -b main "$w/up.git"
    git init -q -b main "$w/seed"; gcfg "$w/seed"
    mkdir -p "$w/seed/g-docs"
    printf '# ROADMAP\n' > "$w/seed/g-docs/ROADMAP.md"
    git -C "$w/seed" add -A; git -C "$w/seed" commit -qm init
    git -C "$w/seed" remote add origin "$w/up.git"
    git -C "$w/seed" push -qu origin main 2>/dev/null
    git clone -q "$w/up.git" "$w/work";  gcfg "$w/work"
    git clone -q "$w/up.git" "$w/other"; gcfg "$w/other"
}

# push_other_commit <world> [file] — one new commit on main via the other clone
push_other_commit() {
    local w="$1" f="${2:-extra.txt}"
    git -C "$w/other" pull -q origin main 2>/dev/null
    printf 'x\n' > "$w/other/$f"
    git -C "$w/other" add -A; git -C "$w/other" commit -qm "other: $f"
    git -C "$w/other" push -q origin main 2>/dev/null
}

# ============================================================================
# § Group 0 — invocation contract
# ============================================================================

# Test 0: the script is executable — SKILL.md Step 0 says "Run scripts/sync-check.sh",
# so direct invocation must work without a `bash` prefix.
if [ -x "$SYNC" ]; then
    echo "PASS: sync-check.sh is executable"; PASS=$((PASS+1))
else
    echo "FAIL: sync-check.sh is executable (mode is $(stat -c '%A' "$SYNC" 2>/dev/null || echo unknown))"; FAIL=$((FAIL+1))
fi

# ============================================================================
# § Group A — early exits (0a–0d bail outcomes)
# ============================================================================

# Test 1: existence gate — neither ROADMAP nor compact-state
FIX=$(mktemp -d)
OUT=$(run_sync "$FIX")
check_contains "existence gate emits EXIT" "$OUT" "EXIT: existence-gate"
check_absent   "existence gate emits no FRESHNESS" "$OUT" "FRESHNESS:"
rm -rf "$FIX"

# Test 2: not a git repo
FIX=$(mktemp -d); mkdir -p "$FIX/g-docs"; printf 'x\n' > "$FIX/g-docs/ROADMAP.md"
OUT=$(run_sync "$FIX")
check_contains "non-repo tree with ROADMAP" "$OUT" "FRESHNESS: unsynced — not a git repo"
rm -rf "$FIX"

WORLD=$(mktemp -d); make_world "$WORLD"

# Test 3: detached HEAD
git -C "$WORLD/work" checkout -q --detach
OUT=$(run_sync "$WORLD/work")
check_contains "detached HEAD" "$OUT" "FRESHNESS: unsynced — detached HEAD"
git -C "$WORLD/work" checkout -q main

# Test 4: local-only remote (branch.<b>.remote = .)
git -C "$WORLD/work" config branch.main.remote .
OUT=$(run_sync "$WORLD/work")
check_contains "remote-dot is local-only" "$OUT" "FRESHNESS: unsynced — local-only remote"
git -C "$WORLD/work" config branch.main.remote origin

# Test 5: configured remote not listed by `git remote`
FIX=$(mktemp -d)
git init -q -b main "$FIX"; gcfg "$FIX"; mkdir -p "$FIX/g-docs"
printf 'x\n' > "$FIX/g-docs/ROADMAP.md"
git -C "$FIX" add -A; git -C "$FIX" commit -qm init
git -C "$FIX" config branch.main.remote ghost
OUT=$(run_sync "$FIX")
check_contains "unlisted remote is no-remote" "$OUT" "FRESHNESS: unsynced — no remote"
rm -rf "$FIX"

# Test 6: fetch failed (origin URL points nowhere)
git -C "$WORLD/work" remote set-url origin /nonexistent/g-forge-test-void
OUT=$(run_sync "$WORLD/work")
check_contains "unreachable remote is fetch-failed" "$OUT" "FRESHNESS: unverified — fetch failed"
check_absent   "fetch failure skips the record axis" "$OUT" "RECORD_AXIS:"
git -C "$WORLD/work" remote set-url origin "$WORLD/up.git"

# Test 7: unborn HEAD
FIX=$(mktemp -d)
git init -q -b main "$FIX"; gcfg "$FIX"; mkdir -p "$FIX/g-docs"
printf 'x\n' > "$FIX/g-docs/ROADMAP.md"
git -C "$FIX" remote add origin "$WORLD/up.git"
OUT=$(run_sync "$FIX")
check_contains "zero-commit repo is unborn HEAD" "$OUT" "FRESHNESS: unsynced — unborn HEAD"
rm -rf "$FIX"

# Test 8: never-pushed branch, no tracking config → no upstream
git -C "$WORLD/work" checkout -qb feat/nope
OUT=$(run_sync "$WORLD/work")
check_contains "never-pushed branch is no-upstream" "$OUT" "FRESHNESS: unsynced — no upstream"
git -C "$WORLD/work" checkout -q main
git -C "$WORLD/work" branch -qD feat/nope

# Test 9: upstream branch deleted on the remote (pruned by 0c's own fetch)
git -C "$WORLD/work" checkout -qb feat/gone
git -C "$WORLD/work" push -qu origin feat/gone 2>/dev/null
git -C "$WORLD/other" push -q origin :feat/gone 2>/dev/null
git -C "$WORLD/work" config fetch.prune true
OUT=$(run_sync "$WORLD/work")
check_contains "deleted-on-remote branch is upstream-gone" "$OUT" "FRESHNESS: unsynced — upstream branch gone"
git -C "$WORLD/work" config --unset fetch.prune
git -C "$WORLD/work" checkout -q main
git -C "$WORLD/work" branch -qD feat/gone

# ============================================================================
# § Group B — classification rows and the 0e gates
# ============================================================================

# Test 10: level with upstream → synced; on the record branch → 0g silent
OUT=$(run_sync "$WORLD/work")
check_line "level clone is synced (exact line)" "$OUT" "FRESHNESS: synced"
check_absent   "record branch itself gets no RECORD_AXIS line" "$OUT" "RECORD_AXIS:"

# Test 11: ahead only → synced — N unpushed
printf 'l\n' > "$WORLD/work/local.txt"
git -C "$WORLD/work" add -A; git -C "$WORLD/work" commit -qm local
OUT=$(run_sync "$WORLD/work")
check_contains "ahead-only is unpushed" "$OUT" "FRESHNESS: synced — 1 unpushed"
git -C "$WORLD/work" push -q origin main 2>/dev/null

# Test 12: behind + dirty tracked file → why = dirty tree, no fast-forward
push_other_commit "$WORLD" b12.txt
printf 'dirty\n' >> "$WORLD/work/g-docs/ROADMAP.md"
OUT=$(run_sync "$WORLD/work")
check_contains "behind+dirty names dirty tree" "$OUT" "FRESHNESS: stale — 1 behind (not pulled: dirty tree)"
check_absent   "dirty tree never fast-forwards" "$OUT" "FF:"
git -C "$WORLD/work" checkout -q -- g-docs/ROADMAP.md

# Test 13: behind, clean, no counter anywhere → session phase unknown
OUT=$(run_sync "$WORLD/work")
check_contains "no counter is session-phase-unknown" "$OUT" "FRESHNESS: stale — 1 behind (not pulled: session phase unknown)"

# Test 14: counter reads 0 → session phase unknown (0 is never a first prompt)
mkdir -p "$WORLD/work/.claude"
printf '0\n' > "$WORLD/work/.claude/session-prompt-count.abc"
OUT=$(run_sync "$WORLD/work")
check_contains "counter 0 is session-phase-unknown" "$OUT" "(not pulled: session phase unknown)"

# Test 15: counter reads 3 → mid-session run
printf '3\n' > "$WORLD/work/.claude/session-prompt-count.abc"
OUT=$(run_sync "$WORLD/work")
check_contains "counter 3 is mid-session" "$OUT" "FRESHNESS: stale — 1 behind (not pulled: mid-session run)"
check_absent   "mid-session never fast-forwards" "$OUT" "FF:"

# Test 16: two concurrent counters, one reading 1 → conservative, no FF
printf '1\n' > "$WORLD/work/.claude/session-prompt-count.abc"
printf '1\n' > "$WORLD/work/.claude/session-prompt-count.def"
OUT=$(run_sync "$WORLD/work")
check_contains "multi-candidate counters stay conservative" "$OUT" "(not pulled: session phase unknown)"
check_absent   "multi-candidate counters never fast-forward" "$OUT" "FF:"
rm -f "$WORLD/work/.claude/session-prompt-count.def"

# Test 17: counter exactly 1 → fast-forward runs and upgrades Freshness
OUT=$(run_sync "$WORLD/work")
check_contains "counter 1 fast-forwards" "$OUT" "FF: ok"
check_contains "fast-forward upgrades Freshness" "$OUT" "FRESHNESS: synced — fast-forwarded 1"
check_value    "fast-forward landed on origin/main" \
    "$(git -C "$WORLD/work" rev-parse origin/main)" "$(git -C "$WORLD/work" rev-parse HEAD)"

# Test 18: behind, clean, counter 1, untracked collision → FF: failed
git -C "$WORLD/other" pull -q origin main 2>/dev/null
printf 'remote\n' > "$WORLD/other/clash.txt"
git -C "$WORLD/other" add -A; git -C "$WORLD/other" commit -qm clash
git -C "$WORLD/other" push -q origin main 2>/dev/null
printf 'local\n' > "$WORLD/work/clash.txt"
OUT=$(run_sync "$WORLD/work")
check_contains "collision reports FF failed" "$OUT" "FF: failed"
check_contains "collision Freshness names fast-forward, not pull" "$OUT" "FRESHNESS: stale — 1 behind (fast-forward failed)"
rm -f "$WORLD/work/clash.txt"
git -C "$WORLD/work" merge -q --ff-only origin/main >/dev/null 2>&1

# Test 19: behind with no tracking configuration → blocker beats counter, no FF
push_other_commit "$WORLD" b19.txt
git -C "$WORLD/work" config --unset branch.main.remote
git -C "$WORLD/work" config --unset branch.main.merge
OUT=$(run_sync "$WORLD/work")
check_contains "no-tracking blocker named" "$OUT" "FRESHNESS: stale — 1 behind (not pulled: no tracking configuration)"
check_absent   "no-@{u} path never fast-forwards" "$OUT" "FF:"

# Test 20: tracking remote set but no merge ref → upstream ref unresolved
git -C "$WORLD/work" config branch.main.remote origin
OUT=$(run_sync "$WORLD/work")
check_contains "sub-case (a) blocker named" "$OUT" "FRESHNESS: stale — 1 behind (not pulled: upstream ref unresolved)"
git -C "$WORLD/work" config branch.main.merge refs/heads/main
git -C "$WORLD/work" merge -q --ff-only origin/main >/dev/null 2>&1

# ============================================================================
# § Group C — diverged (0f contract)
# ============================================================================

# Test 21: behind and ahead → DIVERGED line, no FRESHNESS, no fast-forward
push_other_commit "$WORLD" b21.txt
printf 'mine\n' > "$WORLD/work/mine21.txt"
git -C "$WORLD/work" add -A; git -C "$WORLD/work" commit -qm mine
OUT=$(run_sync "$WORLD/work")
check_contains "diverged emits both counts" "$OUT" "DIVERGED: behind=1 ahead=1"
check_absent   "diverged emits no FRESHNESS (the skill asks)" "$OUT" "FRESHNESS:"
check_absent   "diverged never fast-forwards" "$OUT" "FF:"
rm -rf "$WORLD"

# ============================================================================
# § Group D — record axis (0g closed set)
# ============================================================================

WORLD=$(mktemp -d); make_world "$WORLD"

# Test 22: feature branch level with its upstream, record branch moved on
git -C "$WORLD/work" checkout -qb feat/x
git -C "$WORLD/work" push -qu origin feat/x 2>/dev/null
push_other_commit "$WORLD" b22.txt
OUT=$(run_sync "$WORLD/work")
check_line "feature branch stays synced on its own axis" "$OUT" "FRESHNESS: synced"
check_contains "record drift is reported on the record axis" "$OUT" \
    "RECORD_AXIS: 1 commits behind origin/main — the handoff you are re-hydrating from may be stale"

# Test 23: feature branch not behind the record branch
git -C "$WORLD/work" merge -q origin/main >/dev/null 2>&1
git -C "$WORLD/work" push -q origin feat/x 2>/dev/null
OUT=$(run_sync "$WORLD/work")
check_contains "level feature branch reads not-behind" "$OUT" "RECORD_AXIS: not behind origin/main"
rm -rf "$WORLD"

# Test 24: no origin/HEAD, no main/master on the remote → honest unknown
FIX=$(mktemp -d)
git init -q --bare -b develop "$FIX/up.git"
git init -q -b develop "$FIX/work"; gcfg "$FIX/work"
mkdir -p "$FIX/work/g-docs"; printf 'x\n' > "$FIX/work/g-docs/ROADMAP.md"
git -C "$FIX/work" add -A; git -C "$FIX/work" commit -qm init
git -C "$FIX/work" remote add origin "$FIX/up.git"
git -C "$FIX/work" push -qu origin develop 2>/dev/null
git -C "$FIX/work" checkout -qb feat/y
git -C "$FIX/work" push -qu origin feat/y 2>/dev/null
OUT=$(run_sync "$FIX/work")
check_contains "unresolvable record branch is emitted, never swallowed" "$OUT" \
    "RECORD_AXIS: record branch could not be resolved — cannot tell whether the handoff is current"
rm -rf "$FIX"

# ============================================================================
# § Results
# ============================================================================

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

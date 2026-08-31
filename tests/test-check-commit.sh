#!/bin/bash
# Unit tests for hooks/check-commit.sh
# Runs entirely inside a throwaway fixture dir so the suite never mutates the
# repo's own .claude/ (an earlier version deleted .claude/integration-tier in
# the repo root, silently disabling the hooks for the project).
#
# M52 F1 Task 25 addition: +3 cases (30-32) — F1-2 hook-skip bypass gate:
# --no-verify and -c core.hooksPath=... denied even with the code sentinel
# PRESENT (gf_commit_skips_hooks / gf_commit_overrides_hookspath deny before
# the sentinel check), plus a light-tier regression guard (gate off, so
# --no-verify passes too — the predicates are never reached on that path).
#
# Total assertions: runner-observed — see this file's own `Results:` line
# (previously 29; +3 added by Task 25, attested by a separate run, not this
# dispatch — re-derive after any further suite change, never hand-typed).
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line — the
# finding-#20 cross-check that catches a suite silently dropping cases.

# Resolve to ABSOLUTE paths once, before any fixture cd (tests/README.md).
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$TESTS_DIR/../hooks/check-commit.sh"
SENTINEL=".claude/g-forge-approved"
PASS=0
FAIL=0

# Timing bound for the abandoned-stdin fixtures (cases 23 and 25). Declared once
# in tests/lib/timing-bounds.sh with its evidence — the same bound governs
# test-class-split-invariant.sh, and duplicating it is what let it drift.
source "$TESTS_DIR/lib/timing-bounds.sh" || { echo "FAIL: could not source tests/lib/timing-bounds.sh"; exit 1; }
# STDIN_GUARD_WINDOW_MS sources GF_FAST_STDIN_GUARD_MS (tests/lib/timing-bounds.sh),
# not the production GF_HOOK_STDIN_GUARD_MS bound — cases 23 and 25 below run
# with GF_STDIN_TIMEOUT_OVERRIDE exported (hooks/lib/stdin-read.sh), so each
# hook's internal stdin-read timeout is ~2s, not the production 5s.
STDIN_GUARD_WINDOW_MS="$GF_FAST_STDIN_GUARD_MS"

run() {
    local name="$1" input="$2" expected="$3"
    echo "$input" | bash "$SCRIPT" >/dev/null 2>&1
    local actual=$?
    if [ "$actual" -eq "$expected" ]; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected exit $expected, got $actual)"; FAIL=$((FAIL+1))
    fi
}

# Isolate all .claude state in a temp fixture — the hook resolves .claude
# relative to CWD, so running here keeps the real project untouched.
WORKDIR="$(mktemp -d)"
cd "$WORKDIR" || { echo "FAIL: could not enter fixture dir"; exit 1; }
mkdir -p .claude
# The hook self-guards to G-Forge-managed projects (presence of
# .claude/integration-tier). Mark this fixture as one so the gate is active.
printf 'full\n' > .claude/integration-tier
rm -f "$SENTINEL"

# Make the fixture a real git repo so the hook's file-set classifier
# (git diff --cached --name-only) has an index to read. Tests that stage no
# files keep an empty index → classifier routes through the code gate, exactly
# the historical behavior the original cases above rely on.
git init -q 2>/dev/null
git config user.email "test@g-forge.local" 2>/dev/null
git config user.name "g-forge-test" 2>/dev/null

DOCS_SENTINEL=".claude/g-forge-docs-approved"

# stage <path>... — reset the index, create + stage the given paths so the
# hook's classifier sees a known staged file set for the next run() call.
stage() {
    git rm -r --cached --quiet . >/dev/null 2>&1
    local p
    for p in "$@"; do
        mkdir -p "$(dirname "$p")"
        printf 'x\n' > "$p"
        git add "$p" >/dev/null 2>&1
    done
}

# 1: git commit without sign-off → blocked
run "git commit blocked without sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: add feature\""}}' \
    2

# 2: git commit with sign-off → allowed
echo "approved" > "$SENTINEL"
run "git commit allowed with sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: add feature\""}}' \
    0
rm -f "$SENTINEL"

# 3: npm test → allowed without sign-off
run "non-commit command always passes" \
    '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' \
    0

# 4: git push → not blocked
run "git push not blocked" \
    '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' \
    0

# 5: git commit --amend → blocked without sign-off
run "git commit --amend blocked without sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit --amend --no-edit"}}' \
    2

# 6: Regression — when no JSON parser works (jq absent, python3 is the Windows
# Microsoft-Store stub, node absent) the hook must fall back to grepping the
# raw payload and still block. Shadow all three parsers with exit-1 stubs
# *prepended* to the real PATH. (Replacing PATH wholesale by symlinking
# coreutils breaks git-bash — bash.exe can't load its DLLs from a bare symlink
# dir — which is what made this test mis-report a fail-open on Windows.)
STUBDIR="$(mktemp -d)"
for p in jq python3 node; do
    printf '#!/bin/sh\nexit 1\n' > "$STUBDIR/$p"
    chmod +x "$STUBDIR/$p"
done
rm -f "$SENTINEL"
echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}' \
    | PATH="$STUBDIR:$PATH" bash "$SCRIPT" >/dev/null 2>&1
if [ $? -eq 2 ]; then
    echo "PASS: gate enforced when no JSON parser works (raw-payload fallback)"; PASS=$((PASS+1))
else
    echo "FAIL: gate fell OPEN with no working parser"; FAIL=$((FAIL+1))
fi
rm -rf "$STUBDIR"

# ── File-set classification gate (code / doc / mixed sentinels) ──────────────
# The hook classifies a commit by its staged file set and requires the matching
# sentinel(s): code paths → .claude/g-forge-approved; doc paths →
# .claude/g-forge-docs-approved; mixed → both. g-docs/* and root *.md are docs.

# 7: doc-only commit blocked when the doc sentinel is absent
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "g-docs/notes.md"
run "doc-only commit blocked without doc sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"docs: notes\""}}' \
    2

# 8: doc-only commit allowed when the doc sentinel is present
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
stage "g-docs/notes.md"
run "doc-only commit allowed with doc sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"docs: notes\""}}' \
    0
rm -f "$DOCS_SENTINEL"

# 9: doc-only commit blocked when only the CODE sentinel is present (wrong gate)
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$SENTINEL"
stage "README.md"
run "doc-only commit blocked when only code sign-off present" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"docs: readme\""}}' \
    2
rm -f "$SENTINEL"

# 10: mixed commit (code + doc) blocked when only the code sentinel is present
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$SENTINEL"
stage "hooks/thing.sh" "g-docs/notes.md"
run "mixed commit blocked with only code sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: code + docs\""}}' \
    2
rm -f "$SENTINEL"

# 11: mixed commit blocked when only the doc sentinel is present
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
stage "hooks/thing.sh" "g-docs/notes.md"
run "mixed commit blocked with only doc sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: code + docs\""}}' \
    2
rm -f "$DOCS_SENTINEL"

# 12: mixed commit allowed when BOTH sentinels are present
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
stage "hooks/thing.sh" "g-docs/notes.md"
run "mixed commit allowed with both sign-offs" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: code + docs\""}}' \
    0
rm -f "$SENTINEL" "$DOCS_SENTINEL"

# 13: code-only commit still allowed with only the code sentinel (regression)
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$SENTINEL"
stage "hooks/thing.sh"
run "code-only commit allowed with code sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: code\""}}' \
    0
rm -f "$SENTINEL"

# 14: code-only commit blocked when only the DOC sentinel is present (wrong gate)
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "code-only commit blocked when only doc sign-off present" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: code\""}}' \
    2
rm -f "$DOCS_SENTINEL"

# 15: THE REGRESSION GUARD — a blocked commit must actually BLOCK, not just warn.
# The historical bug: block paths used `exit 1`, which is a NON-blocking PreToolUse
# error (the commit runs anyway). This asserts the two things that make it a real
# block: (a) exit code 2, and (b) a stdout `permissionDecision":"deny"` JSON. The
# old exit-1/no-JSON gate fails BOTH — this is the test that would have caught it.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}' | bash "$SCRIPT" 2>/dev/null)
CODE=$?
if [ "$CODE" -eq 2 ] && printf '%s' "$OUT" | grep -q '"permissionDecision":"deny"'; then
    echo "PASS: blocked commit truly blocks (exit 2 + deny JSON on stdout)"; PASS=$((PASS+1))
else
    echo "FAIL: block is a no-op (got exit $CODE, deny-JSON $(printf '%s' "$OUT" | grep -q deny && echo present || echo ABSENT))"; FAIL=$((FAIL+1))
fi
rm -f "$SENTINEL"

# 16: an ALLOWED commit must NOT emit a deny decision (no false block).
echo "approved" > "$SENTINEL"
stage "hooks/thing.sh"
OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}' | bash "$SCRIPT" 2>/dev/null)
CODE=$?
if [ "$CODE" -eq 0 ] && ! printf '%s' "$OUT" | grep -q 'deny'; then
    echo "PASS: approved commit passes clean (exit 0, no deny)"; PASS=$((PASS+1))
else
    echo "FAIL: approved commit mis-gated (exit $CODE)"; FAIL=$((FAIL+1))
fi
rm -f "$SENTINEL"

# 17: PowerShell-tool payload — on Windows, Claude Code runs shell commands
# through the PowerShell tool, so the hook must gate its payloads identically
# to Bash ones (the matcher-level fix widens registration to Bash|PowerShell;
# this pins that the script itself is tool-agnostic on the payload).
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "PowerShell-tool git commit blocked without sign-off" \
    '{"tool_name":"PowerShell","tool_input":{"command":"git commit -m \"feat: from windows\""}}' \
    2

# 18: PowerShell-tool payload with sign-off → allowed
echo "approved" > "$SENTINEL"
run "PowerShell-tool git commit allowed with sign-off" \
    '{"tool_name":"PowerShell","tool_input":{"command":"git commit -m \"feat: from windows\""}}' \
    0
rm -f "$SENTINEL"

# 19: Regression — `git -C <path> commit` is now caught (commit #6 hardening).
# Previously, this would bypass the gate. Verify it is now blocked when no sentinel.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "git -C path commit blocked without sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git -C /tmp/subdir commit -m \"feat: from subdir\""}}' \
    2

# 20: Regression — `git -c key=value commit` is now caught (commit #6 hardening).
# Previously, this would bypass the gate. Verify it is now blocked when no sentinel.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "git -c config commit blocked without sign-off" \
    '{"tool_name":"Bash","tool_input":{"command":"git -c user.name=testuser commit -m \"feat: with config\""}}' \
    2

# 21: Regression — #7 `-a`/`--all` fix: `git commit -a` must consider
# modified-but-unstaged tracked files (not just the staged set). Scenario:
# a code file (hooks/thing.sh) exists and is modified but NOT staged, only
# the DOC sentinel is present. `git commit -a` should auto-stage the code
# file via the -a flag, then classify the commit as mixed or code, and block
# because the code sentinel is missing. Before fix #7, this would wrongly pass
# as doc-only because the classifier only looked at the staged set.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
# Create and track a code file, then modify it (without staging)
mkdir -p hooks
printf 'x\n' > hooks/thing.sh
git add hooks/thing.sh >/dev/null 2>&1
git commit -q -m "initial: track code file" 2>/dev/null
printf 'y\n' > hooks/thing.sh
# Unstage everything from prior cases (but keep tracked files tracked)
git reset -q 2>/dev/null
# Stage only a doc file; the code file is modified but unstaged
mkdir -p g-docs
printf 'x\n' > g-docs/notes.md
git add g-docs/notes.md >/dev/null 2>&1
run "git commit -a with unstaged code blocked when only doc sentinel present" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -a -m \"fix: code + docs\""}}' \
    2
rm -f "$DOCS_SENTINEL"

# 22: Regression — #7 explicit-pathspec fix: when `git commit <pathspec>` is used,
# the pathspec argument names code paths that the classifier must include in the
# file-set classification, even if the staged index alone is doc-only. Scenario:
# only the DOC sentinel is present (no CODE sentinel), hooks/thing.sh exists as
# a tracked file, only a doc file is staged, and `git commit hooks/thing.sh -m "fix"`
# is executed. The pathspec pulls hooks/thing.sh (code) into the classification,
# making it mixed (code + doc), so it should block due to missing CODE sentinel.
# Before fix #7, this would wrongly pass as doc-only because the classifier
# ignored the explicit pathspec and only inspected the staged set.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
# Ensure hooks/thing.sh is tracked (commit to history to make it tracked)
mkdir -p hooks
printf 'x\n' > hooks/thing.sh
git add hooks/thing.sh >/dev/null 2>&1
git commit -q -m "case 22: track code file" 2>/dev/null
# Use git reset -q to unstage but keep files tracked (not git rm -r --cached)
git reset -q 2>/dev/null
# Stage only a doc file; code file is tracked but unstaged
mkdir -p g-docs
printf 'x\n' > g-docs/notes.md
git add g-docs/notes.md >/dev/null 2>&1
# Run commit with explicit pathspec naming the code file — should block because
# the pathspec adds a code file to the staged-set union during classification
run "git commit with explicit code pathspec blocked when only doc sentinel present" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit hooks/thing.sh -m \"fix: code via pathspec\""}}' \
    2
rm -f "$DOCS_SENTINEL"

# 23: Abandoned-stdin fixture — timeout mechanism returns within guard window,
# exits 0 (fail-open polarity), and produces no deny JSON on stdout. This verifies
# that stdin-read.sh guards against indefinite hangs on orphaned stdin without
# incorrectly blocking legitimate commits.
#
# GF_STDIN_TIMEOUT_OVERRIDE is exported for this invocation only
# (hooks/lib/stdin-read.sh consumes it in gf_read_stdin_timeout, replacing
# the 5s argument with this value before normalization), so `read -t 5 -d ''`
# becomes `read -t 2 -d ''` and the hook's stdin read times out in ~2s
# instead of 5s. STDIN_GUARD_WINDOW_MS above is GF_FAST_STDIN_GUARD_MS to
# match. Unset immediately after so case 24 (guard-regression, no abandoned
# pipe) — which sits right after this one in the same process — never sees
# the override.
#
# falsifiability: hooks/, tests/test-check-commit.sh, and tests/lib/timing-bounds.sh
# copied whole to a scratch dir (relative sourcing paths preserved). In the
# scratch copy only: gf_read_stdin_timeout's
# `if [ -n "${GF_STDIN_TIMEOUT_OVERRIDE:-}" ]` branch forced to `if false`
# (override silently ignored, hook falls back to its normal 5s argument),
# and GF_FAST_STDIN_GUARD_MS tightened to 4000 (the real bound — 15000 at
# probe time, raised to 30000 on loaded-machine evidence; the probe pins its
# own 4000ms scratch bound, so its conclusion is unaffected — has enough margin
# to absorb the ~2s-vs-5s delta without flipping, so a tight bound is needed
# to make the neutering observable). Re-running the scratch suite then
# produced FAILs on cases 23 and 25 — both measured well over the 4000ms
# bound (5s guard plus MSYS overhead) — confirming the guard-window pass in
# the real suite (GF_FAST_STDIN_GUARD_MS, 15000 at probe time, now 30000) is not coincidental: it
# depends on GF_STDIN_TIMEOUT_OVERRIDE actually reaching the read and
# cutting the wait from 5s to ~2s. Scratch copy discarded after. Production
# tree (this file and hooks/) untouched by the probe — 2026-08-21
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"

export GF_STDIN_TIMEOUT_OVERRIDE="$GF_FAST_STDIN_OVERRIDE_S"
START_TIME=$(date +%s%3N)
OUT=$(bash "$SCRIPT" < <(sleep 300) 2>&1)
CODE=$?
END_TIME=$(date +%s%3N)
ELAPSED=$((END_TIME - START_TIME))
unset GF_STDIN_TIMEOUT_OVERRIDE

if [ "$CODE" -eq 0 ] && ! printf '%s' "$OUT" | grep -q 'deny'; then
    if [ "$ELAPSED" -lt "$STDIN_GUARD_WINDOW_MS" ]; then
        echo "PASS: stdin timeout (abandoned pipe) — exit 0, no deny, ${ELAPSED}ms <${STDIN_GUARD_WINDOW_MS}ms"; PASS=$((PASS+1))
    else
        echo "FAIL: stdin timeout took ${ELAPSED}ms, expected <${STDIN_GUARD_WINDOW_MS}ms (~2s override guard + MSYS overhead headroom)"; FAIL=$((FAIL+1))
    fi
else
    DENY_STATUS=$(printf '%s' "$OUT" | grep -q deny && echo "PRESENT" || echo "absent")
    echo "FAIL: stdin timeout (exit $CODE, deny $DENY_STATUS) — expected exit 0, no deny"; FAIL=$((FAIL+1))
fi

# 24: Guard regression — stdin-read.sh timeout wiring must not weaken the gate.
# Verify that a normal well-formed PreToolUse JSON payload with a git commit
# (no abandoned stdin) still produces deny behavior, proving the timeout
# mechanism didn't inadvertently open the gate for legitimate payloads.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: guard regression test\""}}' | bash "$SCRIPT" 2>/dev/null)
CODE=$?
if [ "$CODE" -eq 2 ] && printf '%s' "$OUT" | grep -q '"permissionDecision":"deny"'; then
    echo "PASS: guard regression — normal commit JSON still blocks (exit 2 + deny JSON)"; PASS=$((PASS+1))
else
    DENY_STATUS=$(printf '%s' "$OUT" | grep -q deny && echo "present" || echo "ABSENT")
    echo "FAIL: guard regression — timeout wiring weakened gate (exit $CODE, deny-JSON $DENY_STATUS)"; FAIL=$((FAIL+1))
fi
rm -f "$SENTINEL"

# 25: Second abandoned-stdin sample, honestly labeled: same fixture class as
# case 23 (the index still holds case 24's staged hooks/thing.sh — the reset
# comes after this case; and with no payload arriving, CMD is empty,
# is_git_commit is false, and no staged-set branch is ever reached). This is a
# distinct invocation, not distinct coverage — kept as an independent
# regression pin that the fail-open polarity (exit 0, bounded return) still
# holds immediately after the guard-wiring cases 23-24 ran in this process.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
# GF_STDIN_TIMEOUT_OVERRIDE re-exported for this invocation only, same
# mechanism and rationale as case 23 above; unset again immediately after so
# no later section of this suite is affected.
export GF_STDIN_TIMEOUT_OVERRIDE="$GF_FAST_STDIN_OVERRIDE_S"
START_TIME=$(date +%s%3N)
OUT=$(bash "$SCRIPT" < <(sleep 300) 2>&1)
CODE=$?
END_TIME=$(date +%s%3N)
ELAPSED=$((END_TIME - START_TIME))
unset GF_STDIN_TIMEOUT_OVERRIDE
if [ "$CODE" -eq 0 ] && [ "$ELAPSED" -lt "$STDIN_GUARD_WINDOW_MS" ]; then
    echo "PASS: stdin timeout, second sample — exit 0 in ${ELAPSED}ms <${STDIN_GUARD_WINDOW_MS}ms"; PASS=$((PASS+1))
else
    echo "FAIL: stdin timeout, second sample (exit $CODE, ${ELAPSED}ms — expected 0 within ${STDIN_GUARD_WINDOW_MS}ms)"; FAIL=$((FAIL+1))
fi

# ── Integration-tier gate (hooks/check-commit.sh:170-184) ────────────────────
# The commit gate itself is conditional on .claude/integration-tier: "light"
# disables it entirely (hook:181-184, exit 0 before any sentinel check);
# anything else enforces it (TIER defaults to "full" at hook:174, and the
# case statement at hook:177-179 only recognizes full|balanced|light — an
# unrecognized value never reassigns TIER, so it stays "full" and the gate
# stays on). These three cases pin that contract directly, independent of
# the sentinel-presence cases above.

# 26: light tier → gate OFF — a gated commit with NO sentinel present is
# allowed (exit 0). Allow-path case; no falsifiability probe needed (§H
# applies to deny-path guards, not allow paths).
printf 'light\n' > .claude/integration-tier
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "light tier: gated commit allowed with no sentinel (gate off)" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: light tier\""}}' \
    0
printf 'full\n' > .claude/integration-tier

# 27: balanced tier → gate ON — the same gated payload with no sentinel is
# denied, per the hook's PreToolUse deny convention (exit 2).
#
# falsifiability: hooks/ copied whole to a scratch dir (relative sourcing
# preserved). In the scratch copy only: check-commit.sh's
# `if [ "$TIER" = "light" ]; then` (hook:181) changed to
# `if [ "$TIER" = "light" ] || [ "$TIER" = "balanced" ]; then`, folding
# "balanced" into the gate-off bypass. Re-running this case's fixture
# (balanced tier, no sentinel, staged code file) against the neutered
# scratch hook produced exit 0 instead of 2 — RED, confirming the pass
# above depends on the hook actually keeping "balanced" on the enforcing
# path. Scratch copy discarded after. Production tree (this file and
# hooks/) untouched by the probe — 2026-08-23
printf 'balanced\n' > .claude/integration-tier
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "balanced tier: gated commit denied with no sentinel (gate on)" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: balanced tier\""}}' \
    2
printf 'full\n' > .claude/integration-tier

# 28: garbage/unknown tier value (e.g. "bananas") → gate ON, fail-safe — the
# case statement only recognizes full|balanced|light; anything else leaves
# TIER at its "full" default and the gate stays enforced (exit 2).
#
# falsifiability: hooks/ copied whole to a scratch dir. In the scratch copy
# only: check-commit.sh's tier `case "$_raw" in full|balanced|light)
# TIER="$_raw" ;; esac` (hook:177-179) given an added `*) TIER="light" ;;`
# branch, folding unrecognized values into the gate-off bypass instead of
# the fail-safe "full" default. Re-running this case's fixture (tier file
# containing "bananas", no sentinel, staged code file) against the
# neutered scratch hook produced exit 0 instead of 2 — RED, confirming the
# pass above depends on the fail-safe default actually holding. Scratch
# copy discarded after. Production tree (this file and hooks/) untouched
# by the probe — 2026-08-23
printf 'bananas\n' > .claude/integration-tier
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "garbage tier value: gated commit denied (fail-safe gate on)" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: garbage tier\""}}' \
    2
printf 'full\n' > .claude/integration-tier

# 29: REFERENCE class (M40 Task 17) — a marked reference/<bundle>/... commit
# (bundle dir contains SNAPSHOT.md) passes with NO sentinel at all — it is
# exempt-with-advisory, not a fourth thing requiring its own sign-off. The
# marker file (SNAPSHOT.md) physically exists on disk in the fixture (stage()
# both creates and stages it), which is what the lib's `[ -f ]` marker lookup
# needs — GF_CLASSIFY_ROOT defaults to "." (this fixture's cwd). Also asserts
# the advisory line reaches STDOUT (Session C fix round, lane A) — the
# exemption must stay visible, never a silent bypass; run()'s own stdout
# redirect (`>/dev/null 2>&1`) can't see it, so this uses the same sibling
# OUT=$(...) capture shape as cases 15/16 above instead.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "reference/mybundle/SNAPSHOT.md" "reference/mybundle/data.txt"
OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"chore: snapshot refresh\""}}' | bash "$SCRIPT" 2>/dev/null)
CODE=$?
if [ "$CODE" -eq 0 ] && printf '%s' "$OUT" | grep -qF 'reference-only commit — REFERENCE class, exempt from the review gate'; then
    echo "PASS: marked reference-only commit allowed with no sentinel (REFERENCE, exempt) + advisory line on stdout"; PASS=$((PASS+1))
else
    echo "FAIL: marked reference-only commit (expected exit 0 + advisory line on stdout; got exit $CODE, stdout: $OUT)"; FAIL=$((FAIL+1))
fi

# ── F1-2 hook-skip bypass gate (gf_commit_skips_hooks / gf_commit_overrides_hookspath) ─
# --no-verify/-n and -c core.hooksPath=... both skip the native ADR-004
# pre-commit hook entirely — sentinel CONTENT binding (tree hash, HEAD,
# worktree) lives solely there; this hook's own sentinel check is
# existence-only. So a present-but-stale sentinel would otherwise sail
# through this layer. These predicates (hooks/lib/commit-detect.sh) deny
# BEFORE the sentinel/classifier path, regardless of sentinel state.

# 30: --no-verify denied even with the code sentinel PRESENT — a present
# sentinel does not save a hook-skipping commit.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$SENTINEL"
stage "hooks/thing.sh"
OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git commit --no-verify -m \"x\""}}' | bash "$SCRIPT" 2>/dev/null)
CODE=$?
if [ "$CODE" -eq 2 ] && printf '%s' "$OUT" | grep -q '"permissionDecision":"deny"'; then
    echo "PASS: --no-verify denied even with code sentinel present (exit 2 + deny JSON)"; PASS=$((PASS+1))
else
    echo "FAIL: --no-verify not denied with sentinel present (exit $CODE, stdout: $OUT)"; FAIL=$((FAIL+1))
fi
rm -f "$SENTINEL"

# 31: -c core.hooksPath=... denied even with the code sentinel PRESENT.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$SENTINEL"
stage "hooks/thing.sh"
OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"git -c core.hooksPath=/tmp/x commit -m \"x\""}}' | bash "$SCRIPT" 2>/dev/null)
CODE=$?
if [ "$CODE" -eq 2 ] && printf '%s' "$OUT" | grep -q '"permissionDecision":"deny"'; then
    echo "PASS: -c core.hooksPath override denied even with code sentinel present (exit 2 + deny JSON)"; PASS=$((PASS+1))
else
    echo "FAIL: -c core.hooksPath override not denied with sentinel present (exit $CODE, stdout: $OUT)"; FAIL=$((FAIL+1))
fi
rm -f "$SENTINEL"

# 32: light tier — gate off entirely, so --no-verify passes too (tier-off
# stays off; the F1-2 predicates are never reached on this path since the
# light-tier exit returns before this code runs). Guard/negative assertion —
# probe: light-tier `exit 0` removed in a scratch copy of check-commit.sh.
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-30
printf 'light\n' > .claude/integration-tier
rm -f "$SENTINEL" "$DOCS_SENTINEL"
stage "hooks/thing.sh"
run "light tier: --no-verify commit allowed (gate off, predicate never evaluated)" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit --no-verify -m \"x\""}}' \
    0
printf 'full\n' > .claude/integration-tier

# 33: Regression — C-3 fix: `-a` inside an attached-value cluster
# (`-am"msg"`, no space before the glued message) is still detected as the
# -a form and widens the classifier to the modified-but-unstaged tracked
# file — same fixture shape as case 21. Before the C-3 fix, the cluster's
# trailing anchor required whitespace or end-of-string immediately after it,
# which a glued value never provides, so this would wrongly pass as doc-only.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
mkdir -p hooks
printf 'x\n' > hooks/thing.sh
git add hooks/thing.sh >/dev/null 2>&1
git commit -q -m "case 33: track code file" 2>/dev/null
printf 'y\n' > hooks/thing.sh
git reset -q 2>/dev/null
mkdir -p g-docs
printf 'x\n' > g-docs/notes.md
git add g-docs/notes.md >/dev/null 2>&1
run 'git commit -am"fix: code + docs" (attached-value -a cluster) blocked when only doc sentinel present' \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -am\"fix: code + docs\""}}' \
    2
rm -f "$DOCS_SENTINEL"

# 34: Regression — C-3 fix, space-separated variant: `-am msg` (the `m`
# value is a separate token, no glued value) already matched before the fix
# since the cluster is followed by whitespace — kept as an explicit
# regression pin alongside case 33's glued-value variant, same fixture shape,
# so both forms the C-3 fix note names stay pinned side by side.
rm -f "$SENTINEL" "$DOCS_SENTINEL"
echo "approved" > "$DOCS_SENTINEL"
mkdir -p hooks
printf 'x\n' > hooks/thing.sh
git add hooks/thing.sh >/dev/null 2>&1
git commit -q -m "case 34: track code file" 2>/dev/null
printf 'y\n' > hooks/thing.sh
git reset -q 2>/dev/null
mkdir -p g-docs
printf 'x\n' > g-docs/notes.md
git add g-docs/notes.md >/dev/null 2>&1
run "git commit -am msg (space-separated -a cluster) blocked when only doc sentinel present" \
    '{"tool_name":"Bash","tool_input":{"command":"git commit -am msg"}}' \
    2
rm -f "$DOCS_SENTINEL"

# Reset the index so any later cases see a clean (empty) staged set.
stage

cd / && rm -rf "$WORKDIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

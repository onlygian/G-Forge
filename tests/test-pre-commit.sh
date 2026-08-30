#!/bin/bash
# Unit tests for hooks/pre-commit — the native git commit-gate hook (ADR-004).
#
# Contract under test (see hooks/pre-commit header, hooks/pre-commit:1-43):
# a native git pre-commit hook, NOT a Claude Code PreToolUse hook. No stdin
# JSON. Deny = "G-Forge: <reason>" on stderr + exit 1. Allow = exit 0, no
# stderr. This is the OPPOSITE exit-code contract from
# hooks/check-commit.sh's PreToolUse "exit 2 to deny" convention — do not
# reuse that suite's run() semantics blindly (it does not assert stderr).
#
# House pattern reused from tests/test-check-commit.sh: mktemp git fixture,
# `git config user.*` set once, PASS/FAIL counters, `Results:` line, non-zero
# exit on any failure. Every helper below is a FUNCTION — `local` is only
# ever used inside one, never at script top level (a prior authoring attempt
# broke on this; see g-docs/agent-output/wave-1/test-pre-commit-suite.md and
# its attestation for the historical failure trace). File-set state is
# threaded through the fixture's real git index and plain string args —
# never a `local -n` nameref (the other historical break: bash's nameref
# cannot bind an array literal the way that attempt tried).
#
# Total assertions: 16. Count is the RUNNER-OBSERVED total and must equal the
# `Results:` line — the finding-#20 cross-check that catches a suite silently
# dropping cases.

# Resolve to ABSOLUTE paths once, before any fixture cd (tests/README.md).
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$TESTS_DIR/../hooks/pre-commit"
PASS=0
FAIL=0

# run <name> <expected_exit> — invoke $SCRIPT (no stdin payload — native git
# hooks receive none) and assert exit code only.
run() {
    local name="$1" expected="$2" actual err
    err=$(bash "$SCRIPT" 2>&1 1>/dev/null </dev/null)
    actual=$?
    if [ "$actual" -eq "$expected" ] && { [ "$expected" -ne 0 ] || [ -z "$err" ]; }; then
        echo "PASS: $name"; PASS=$((PASS+1))
    elif [ "$actual" -eq "$expected" ]; then
        echo "FAIL: $name (expected exit $expected with empty stderr per the file's own Allow contract, got exit $actual, stderr: $err)"; FAIL=$((FAIL+1))
    else
        echo "FAIL: $name (expected exit $expected, got $actual)"; FAIL=$((FAIL+1))
    fi
}

# run_deny <name> <expected_exit> <stderr_substring> — same, but also asserts
# the stderr text contains the hook's REAL deny reason (hooks/pre-commit's
# own wording, read directly off the source — never guessed).
run_deny() {
    local name="$1" expected="$2" needle="$3" actual out
    out=$(bash "$SCRIPT" </dev/null 2>&1 1>/dev/null)
    actual=$?
    if [ "$actual" -eq "$expected" ] && printf '%s' "$out" | grep -qF "$needle"; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected exit $expected + stderr containing \"$needle\"; got exit $actual, stderr: $out)"; FAIL=$((FAIL+1))
    fi
}

# Isolate all git/.claude state in a temp fixture — hooks/pre-commit resolves
# its own lib/ relative to $0 (its real, unmoved location under hooks/), but
# every OTHER path it touches (.claude/integration-tier, sentinels, the git
# index) is CWD-relative, so running from a throwaway fixture keeps the real
# repo (and its own live g-forge-approved gate) untouched.
WORKDIR="$(mktemp -d)"
cd "$WORKDIR" || { echo "FAIL: could not enter fixture dir"; exit 1; }
git init -q
git config user.email "test@g-forge.local"
git config user.name "g-forge-test"
mkdir -p .claude
printf 'full\n' > .claude/integration-tier

CODE_SENTINEL=".claude/g-forge-approved"
DOC_SENTINEL=".claude/g-forge-docs-approved"

# stage <path>... — reset the index, create + stage the given paths so the
# hook's classifier (git diff --cached --name-only, via
# hooks/lib/classify-changeset.sh) sees a known staged file set. No args =
# empty staged set (Group 3's default-to-code case).
stage() {
    git rm -r --cached --quiet . >/dev/null 2>&1
    local p
    for p in "$@"; do
        mkdir -p "$(dirname "$p")"
        printf 'x\n' > "$p"
        git add "$p" >/dev/null 2>&1
    done
}

# current_head — print the resolved HEAD sha, or an empty string on an
# unborn HEAD (mirrors hooks/pre-commit:194-198's own --verify -q guard, so
# the fixture's notion of "current HEAD" matches the hook's exactly).
current_head() {
    if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
        git rev-parse HEAD 2>/dev/null
    else
        printf ''
    fi
}

# stamp_valid <sentinel_path> — write a 3-field sentinel stamp that matches
# the fixture's CURRENT staged tree / HEAD / worktree exactly (ADR-004
# format, hooks/lib/sentinel-read.sh field names).
stamp_valid() {
    local sentinel="$1" tree head worktree
    tree=$(git write-tree 2>/dev/null)
    head=$(current_head)
    worktree=$(git rev-parse --show-toplevel 2>/dev/null)
    printf 'commit_sentinel_ts=%s commit_sentinel_head=%s commit_sentinel_worktree=%s\n' "$tree" "$head" "$worktree" > "$sentinel"
}

# ── Group 3 (partial): first-commit / unborn-HEAD edge ───────────────────
# Must run before ANY commit exists in the fixture, so HEAD is genuinely
# unborn and current_head() genuinely returns "" — the ONLY situation in
# which an empty commit_sentinel_head is a valid match (hooks/pre-commit:182-198).

# 1: first commit — valid sentinel with empty HEAD field on unborn HEAD
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/thing.sh"
stamp_valid "$CODE_SENTINEL"
run "first-commit sentinel with empty-head field matches unborn HEAD" 0

# Seed a real commit so subsequent cases have a resolvable, non-empty HEAD to
# validate against (and, for case 15, a base to branch and conflict from).
# Real `git commit` here is fixture setup INSIDE this script file, not a
# literal command handed to the Bash tool — the session's own commit gate
# (hooks/check-commit.sh) inspects only the outer tool_input.command string,
# never a sourced/invoked script's contents, so this does not trip it.
stage "seed.txt"
git commit -q -m "seed" 2>/dev/null
INITIAL_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"

# ── Group 1: valid pass-through (exit 0) ──────────────────────────────────

# 2: code-only, valid sentinel
stage "hooks/code1.sh"
stamp_valid "$CODE_SENTINEL"
run "code-only commit with valid sentinel" 0

# 3: doc-only, valid sentinel
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "g-docs/notes.md"
stamp_valid "$DOC_SENTINEL"
run "doc-only commit with valid sentinel" 0

# 4: mixed, both sentinels valid
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/code2.sh" "g-docs/notes2.md"
stamp_valid "$CODE_SENTINEL"
stamp_valid "$DOC_SENTINEL"
run "mixed commit with both valid sentinels" 0

# ── Group 2: sentinel 3-field validation deny (hooks/pre-commit:77-96) ────

# 5: tree hash mismatch
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/code3.sh"
stamp_valid "$CODE_SENTINEL"
sed -i 's/commit_sentinel_ts=[^ ]*/commit_sentinel_ts=deadbeef0000000000000000000000000000dead/' "$CODE_SENTINEL"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "code sentinel with tree hash mismatch" 1 "reviewed tree does not match the tree being committed"

# 6: HEAD mismatch
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/code4.sh"
stamp_valid "$CODE_SENTINEL"
sed -i 's/commit_sentinel_head=[^ ]*/commit_sentinel_head=deadbeef0000000000000000000000000000dead/' "$CODE_SENTINEL"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "code sentinel with HEAD mismatch" 1 "HEAD has moved since review"

# 7: worktree mismatch
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/code5.sh"
stamp_valid "$CODE_SENTINEL"
sed -i 's#commit_sentinel_worktree=.*#commit_sentinel_worktree=/not/the/real/worktree#' "$CODE_SENTINEL"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "code sentinel with worktree mismatch" 1 "recorded in a different worktree"

# 8: missing / unparseable sentinel
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/code6.sh"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "code sentinel missing entirely" 1 "missing or unparseable sentinel"

# ── Group 3: class / tier / inert edges ───────────────────────────────────

# 9: mixed commit, code sentinel missing (doc sentinel present)
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/code7.sh" "g-docs/notes3.md"
stamp_valid "$DOC_SENTINEL"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "mixed commit missing code sign-off" 1 "mixed commit missing code sign-off"

# 10: mixed commit, doc sentinel missing (code sentinel present)
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "hooks/code8.sh" "g-docs/notes4.md"
stamp_valid "$CODE_SENTINEL"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "mixed commit missing doc sign-off" 1 "mixed commit missing doc sign-off"

# 11: empty staged set — falls through to the code class default
# (hooks/pre-commit:171-174) and is denied for the same reason as case 8.
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "empty staged set defaults to code class and is denied" 1 "missing or unparseable sentinel"

# 12: light tier — gate bypassed entirely, no sentinel needed
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
printf 'light\n' > .claude/integration-tier
stage "hooks/code9.sh"
run "light integration tier bypasses the gate" 0
printf 'full\n' > .claude/integration-tier

# 13: no local tier + a cleanly-resolved, non-gated primary — inert
# (hooks/pre-commit:121-128's "genuinely non-gated" exit, not the ambiguous
# path — the fixture IS a resolvable standalone git repo, it simply has no
# G-Forge project marker anywhere in its resolution chain).
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL" .claude/integration-tier
stage "hooks/code10.sh"
run "no G-Forge project marker resolves inert" 0
printf 'full\n' > .claude/integration-tier

# 14: REFERENCE class (M40 Task 17) — a marked reference/<bundle>/... commit
# (bundle dir contains SNAPSHOT.md) passes with NO sentinel — exempt with
# advisory, no sign-off required. The marker file physically exists on disk
# (stage() creates + stages it), which is what the lib's `[ -f ]` marker
# lookup needs — GF_CLASSIFY_ROOT defaults to "." (this fixture's cwd).
# Placed HERE deliberately, before case 15 below commits "conflict.txt" (a
# file with unique, non-"x\n" content) to HEAD: every stage() call in this
# fixture writes literal "x\n" to every path, so up to this point ALL
# committed history is content-identical to whatever stage() creates next,
# and git's rename detection folds the old committed path into an R100
# rename with the new one instead of surfacing it as a stray deletion in
# `git diff --cached --name-only` — verified empirically (scratch repro,
# see this task's report) before picking this position. After case 15 seeds
# a differently-content tracked file, that invisibility no longer holds and
# a reference-only stage() there picks up an unrelated CODE-bucket deletion,
# silently turning the changeset mixed. Do not move this case past case 15.
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
stage "reference/mybundle/SNAPSHOT.md" "reference/mybundle/data.txt"
# Also asserts the advisory line reaches STDOUT (Session C fix round, lane A)
# — the exemption must stay visible, never a silent bypass. run()'s helper
# captures stderr only (`2>&1 1>/dev/null`), so this case captures stdout
# separately instead of reusing run().
STDOUT_OUT=$(bash "$SCRIPT" </dev/null 2>/dev/null)
STDOUT_CODE=$?
if [ "$STDOUT_CODE" -eq 0 ] && printf '%s' "$STDOUT_OUT" | grep -qF 'reference-only commit — REFERENCE class, exempt from the review gate'; then
    echo "PASS: marked reference-only commit allowed with no sentinel (REFERENCE, exempt) + advisory line on stdout"; PASS=$((PASS+1))
else
    echo "FAIL: marked reference-only commit (expected exit 0 + advisory line on stdout; got exit $STDOUT_CODE, stdout: $STDOUT_OUT)"; FAIL=$((FAIL+1))
fi
# Restore the local-tier-absent state case 13 left behind — case 15 below
# depends on it (see that case's own comment).
rm -f .claude/integration-tier

# ── Group 4: deny edges ────────────────────────────────────────────────────

# 15: ambiguous worktree/common-dir resolution. GIT_COMMON_DIR is a real git
# env var (not a G-Forge invention) that git rev-parse --git-common-dir
# honors; pointing it at a non-existent path makes the underlying `git
# rev-parse --git-common-dir` call fail outright, so
# hooks/lib/worktree-resolve.sh's gf_resolve_primary_claude_dir returns 1
# exactly as it would on a genuinely ambiguous nested-worktree/submodule
# resolution (hooks/pre-commit:110-120) — same local-tier-absent fixture
# state as case 13, scoped to this single invocation only (not exported), so
# it cannot leak into any later case.
stage "hooks/code11.sh"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
OUT=$(GIT_COMMON_DIR="/definitely/not/a/gitdir" bash "$SCRIPT" </dev/null 2>&1 1>/dev/null)
CODE=$?
if [ "$CODE" -eq 1 ] && printf '%s' "$OUT" | grep -qF "ambiguous git worktree/common-dir resolution"; then
    echo "PASS: ambiguous worktree resolution is denied, not guessed past"; PASS=$((PASS+1))
else
    echo "FAIL: ambiguous worktree resolution (expected exit 1 + stderr containing \"ambiguous git worktree/common-dir resolution\"; got exit $CODE, stderr: $OUT)"; FAIL=$((FAIL+1))
fi
printf 'full\n' > .claude/integration-tier

# 16: git write-tree failure on a genuinely unmerged/conflicted index
# (hooks/pre-commit:146-153). Built with a real add/add merge conflict on
# two branches off the seeded commit — confirmed via direct probe (this
# task's authoring notes) that `git write-tree` exits 128 with no stdout on
# such an index, which is exactly the condition hooks/pre-commit's
# `TREE=$(git write-tree 2>/dev/null) || deny "git write-tree failed..."`
# guards against. That `|| deny` at hooks/pre-commit:152 IS neuterable like
# any other guard in this suite (control falls through to :153's DIFFERENT
# deny message, "git write-tree returned nothing"), and it has now been
# probed per G-RULES §H: neutered in a scratch copy of the hook, re-run
# against this same case, confirmed RED on the substring assertion below —
# see g-docs/agent-output/wave-4/fix-round-2.md for the captured RED output.
rm -f "$CODE_SENTINEL" "$DOC_SENTINEL"
# stage()'s `git rm -r --cached --quiet .` only unstages — it leaves the
# now-untracked file sitting in the worktree (seed.txt included). Left in
# place, that untracked leftover collides with the checkout back to
# $INITIAL_BRANCH below (git refuses to overwrite an untracked file with a
# tracked one of the same path), which silently strands the script on
# conflict-branch instead of switching back — the merge that follows then
# merges a branch into itself and never conflicts. `git clean -fd` clears
# every prior case's worktree litter first so the branch switch is clean —
# `-e .claude` is required: .claude/ is itself untracked (never `git add`ed
# in this fixture) and a bare `git clean -fd` deletes it wholesale, silently
# wiping .claude/integration-tier and turning every case after this one into
# the "no G-Forge project" inert exit-0 path instead of the tier it was set
# to (caught by exactly this false pass the first time this case was run).
git clean -fd -e .claude >/dev/null 2>&1
git checkout -q -b conflict-branch 2>/dev/null
printf 'A\n' > conflict.txt
git add conflict.txt >/dev/null 2>&1
git commit -q -m "conflict branch change" 2>/dev/null
git checkout -q "$INITIAL_BRANCH" 2>/dev/null
printf 'B\n' > conflict.txt
git add conflict.txt >/dev/null 2>&1
git commit -q -m "main branch change" 2>/dev/null
git merge conflict-branch -q >/dev/null 2>&1
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-22
run_deny "git write-tree failure on unmerged/conflicted index is denied" 1 "git write-tree failed"
git merge --abort >/dev/null 2>&1

cd / && rm -rf "$WORKDIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

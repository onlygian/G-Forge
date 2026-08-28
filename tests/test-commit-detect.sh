#!/bin/bash
# Unit tests for hooks/lib/commit-detect.sh
# Tests the git-commit detection and pathspec extraction APIs.
# Encodes HQ-verified ground-truth table (2026-07-17, git-bash bash 5.2.37, GNU xargs 4.10.0).
# No temp repos — all tests call shell functions on fixed strings only.
#
# W1.6 additions: +6 tests (newline-boundary cases, quoted pathspec fidelity).
# W2.2 additions: +9 tests (HEREDOC group — M-audit finding #21 residual fix:
# heredoc-content false positive, characterized in
# g-docs/agent-output/wave-w2-1/heredoc-characterization.md).
# W3.2 additions: +7 tests (ALIAS group — ad-hoc `-c alias.NAME=VALUE` argv
# sub-case, M-audit W3 task 2; HEREDOC-h/i/j — opener-line suffix scan,
# M-audit W3 task 16).
# M48e additions: +5 tests (HEREDOC-PATHSPEC group — heredoc-pathspec fix,
# todo row 10 / 2026-08-16 live repro: operator+terminator no longer leak
# into extract_pathspecs' pathspec walk, and real pathspecs are never
# over-stripped).
# todo row 13 addition: +2 tests (HEREDOC-p — multi-heredoc-operator coverage
# gap, M48e fix round 1 code-lead r1 Minor 9; pins CURRENT unfixed behaviour,
# does not change hooks/lib/commit-detect.sh). One assertion pins the
# extract_pathspecs leak, a second pins that is_git_commit still detects the
# shape despite the leak (r1 Minor finding — the comment claimed this but no
# assertion pinned it).
# Total assertions: 72. Runner-attested (M48e: 70/70; HEREDOC-p added 2026-08-27, 2 assertions).

LIB="$(cd "$(dirname "$0")" && pwd)/../hooks/lib/commit-detect.sh"
source "$LIB" || { echo "FAIL: could not source $LIB"; exit 1; }

PASS=0
FAIL=0

# test_detected <name> <cmd> — assert is_git_commit returns 0
test_detected() {
    local name="$1" cmd="$2"
    if is_git_commit "$cmd"; then
        echo "PASS: $name"
        PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected detected, but was not)"
        FAIL=$((FAIL+1))
    fi
}

# test_not_detected <name> <cmd> — assert is_git_commit returns nonzero
test_not_detected() {
    local name="$1" cmd="$2"
    if ! is_git_commit "$cmd"; then
        echo "PASS: $name"
        PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected not detected, but was)"
        FAIL=$((FAIL+1))
    fi
}

# test_pathspecs <name> <cmd> <expected> — assert extract_pathspecs output matches
test_pathspecs() {
    local name="$1" cmd="$2" expected="$3"
    local actual
    actual=$(extract_pathspecs "$cmd")
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $name"
        PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected pathspecs: $(printf '%q' "$expected"), got: $(printf '%q' "$actual"))"
        FAIL=$((FAIL+1))
    fi
}

# ── Group P — pins, assert DETECTED, all pass today ────────────────────────────

test_detected "P: git commit -m x" "git commit -m x"
test_detected "P: git commit" "git commit"
test_detected "P: git -C /some/path commit -m x" "git -C /some/path commit -m x"
test_detected "P: git -c user.name=x commit" "git -c user.name=x commit"
test_detected "P: /usr/bin/git commit -m x" "/usr/bin/git commit -m x"
test_detected "P: FOO=bar git commit -m x (multi-char env var name)" "FOO=bar git commit -m x"
test_detected "P: FOO=bar BAZ2=q git commit (two multi-char prefixes)" "FOO=bar BAZ2=q git commit"
test_detected "P: env git commit -m x (bare env prefix)" "env git commit -m x"
# Partial tokenization on malformed input: unmatched double quote — GNU xargs emits partial tokens BEFORE erroring → DETECTED
# This is the fail-toward-deny direction and is CORRECT per HQ probe 2026-07-17.
test_detected "P: git commit -m \"unclosed (unmatched double quote, partial-tokenization)" 'git commit -m "unclosed'
test_detected "P: git commit -m 'unclosed (unmatched single quote, partial-tokenization)" "git commit -m 'unclosed"
test_detected "P: git commit with literal newline between tokens" $'git\ncommit -m x'

# ── Group NEWLINE-BOUNDARY — newline handling at command boundaries ──────────
# Ensure newlines at various positions don't confuse the tokenizer (M-audit W1.6 task 9)

test_detected "NEWLINE-BOUNDARY: git with newline before commit subcommand" $'git\ncommit -m x'
test_detected "NEWLINE-BOUNDARY: git with newline after commit subcommand" $'git commit\n-m x'
test_detected "NEWLINE-BOUNDARY: newline before git token" $'\ngit commit -m x'
test_detected "NEWLINE-BOUNDARY: multiple newlines in command" $'git\n\ncommit -m x'

# ── Group N — pins, assert NOT detected, all pass today ──────────────────────

test_not_detected "N: echo \"git commit\"" 'echo "git commit"'
test_not_detected "N: grep 'git commit -m x' somefile" "grep 'git commit -m x' somefile"
test_not_detected "N: for i in 1; do echo \"git commit\"; done" 'for i in 1; do echo "git commit"; done'
test_not_detected "N: echo hi && echo \"git commit\" (substring in chained segment)" 'echo hi && echo "git commit"'
test_not_detected "N: gitx commit" "gitx commit"
test_not_detected "N: git commitx" "git commitx"
test_not_detected "N: empty string" ""

# ── Group KNOWN-BUG-chains — assert DETECTED, all FAIL today (ledger finding #25) ─

test_detected "KNOWN-BUG-chains: cd /tmp && git commit -m x" "cd /tmp && git commit -m x"
test_detected "KNOWN-BUG-chains: echo hi; git commit -m x" "echo hi; git commit -m x"
test_detected "KNOWN-BUG-chains: true | git commit -m x" "true | git commit -m x"
test_detected "KNOWN-BUG-chains: false || git commit -m x" "false || git commit -m x"
test_detected "KNOWN-BUG-chains: git status && git commit -m x" "git status && git commit -m x"

# ── Group KNOWN-BUG-glued-chains — assert DETECTED, all FAIL before W1.5a (ledger finding #25, review r1) ─
# Chain operators glued directly onto a non-space word (no space on one or both
# sides) are not isolated as their own xargs token, so the boundary scan in
# _commit_detect_scan_segments never sees them and the chained `git commit`
# slips through. HQ-verified LIVE 2026-07-17 these three bypass pre-fix.

test_detected "KNOWN-BUG-glued-chains: x&&git commit -m z" "x&&git commit -m z"
test_detected "KNOWN-BUG-glued-chains: true|git commit -m z" "true|git commit -m z"
test_detected "KNOWN-BUG-glued-chains: echo hi;git commit -m z" "echo hi;git commit -m z"
test_detected "KNOWN-BUG-glued-chains: false||git commit -m z" "false||git commit -m z"
test_detected "KNOWN-BUG-glued-chains: a&git commit -m z" "a&git commit -m z"

# Regression guards: glued-operator normalization must not disturb quoting.
test_detected "KNOWN-BUG-glued-chains: git commit -m \"a && b\" (operator inside quoted message, real commit)" 'git commit -m "a && b"'
test_pathspecs "KNOWN-BUG-glued-chains: git commit -m \"a && b\" pathspecs empty (message not split)" 'git commit -m "a && b"' ""
test_not_detected "KNOWN-BUG-glued-chains: echo hi&&echo \"git commit\" (glued but committing text is a quoted echo arg)" 'echo hi&&echo "git commit"'

# ── Group KNOWN-BUG-globalflags — assert DETECTED, all FAIL today (W1.1 minor 2) ─

test_detected "KNOWN-BUG-globalflags: git --no-pager commit -m x" "git --no-pager commit -m x"
test_detected "KNOWN-BUG-globalflags: git -p commit -m x" "git -p commit -m x"
test_detected "KNOWN-BUG-globalflags: git --git-dir=/x commit -m x" "git --git-dir=/x commit -m x"
test_detected "KNOWN-BUG-globalflags: git --git-dir /x commit -m x" "git --git-dir /x commit -m x"
test_detected "KNOWN-BUG-globalflags: git --work-tree /x commit -m x" "git --work-tree /x commit -m x"
test_detected "KNOWN-BUG-globalflags: git --namespace ns commit -m x" "git --namespace ns commit -m x"

# ── Group KNOWN-BUG-envS — assert DETECTED, FAILS today (W1.1 minor 3) ───────────

test_detected "KNOWN-BUG-envS: env -S 'git commit -m x' (quoted -S value, not re-tokenized)" "env -S 'git commit -m x'"

# ── Group KNOWN-BUG-singlecharvar — assert DETECTED, all FAIL today (ledger finding #26) ─

test_detected "KNOWN-BUG-singlecharvar: A=1 git commit -m x" "A=1 git commit -m x"
test_detected "KNOWN-BUG-singlecharvar: A=1 B=2 git commit -m x" "A=1 B=2 git commit -m x"

# ── Group ALIAS — ad-hoc `-c alias.NAME=VALUE` argv sub-case (M-audit W3 task 2) ─
# Zero-cost, argv-string-only resolution — no git config read, no subprocess
# spawn. Full `.git/config` [alias] resolution stays DEFERRED (spike doc:
# g-docs/agent-output/wave-w3-1/alias-resolution-characterization.md).

test_detected "ALIAS: git -c alias.co=commit co (ad-hoc argv alias, zero-cost)" "git -c alias.co=commit co"
test_detected "ALIAS: git -c alias.cm=\"commit -m\" cm test2 (alias value carries embedded flag)" 'git -c alias.cm="commit -m" cm test2'
test_not_detected "ALIAS: git -c alias.co=status co (alias value is not commit)" "git -c alias.co=status co"
test_not_detected "ALIAS: git -c alias.co=commit status (alias defined but not invoked)" "git -c alias.co=commit status"

# ── Group PS — pathspec extraction contract, all pass today ──────────────────────

test_pathspecs "PS: git commit -m msg -- path1 path2" "git commit -m msg -- path1 path2" $'path1\npath2'
test_pathspecs "PS: git commit -m \"touch hooks/check-commit.sh and g-docs/x.md\" (message text never tokenized)" 'git commit -m "touch hooks/check-commit.sh and g-docs/x.md"' ""
test_pathspecs "PS: git commit -m msg file1.txt (positional pathspec without --)" "git commit -m msg file1.txt" "file1.txt"

# ── Group PS-QUOTED — pathspec fidelity with quoted filenames (M-audit W1.6 task 10) ─
# Verify that pathspecs with quoted special characters survive tokenization intact

test_pathspecs "PS-QUOTED: git commit -- \"file with spaces.txt\"" 'git commit -- "file with spaces.txt"' "file with spaces.txt"
test_pathspecs "PS-QUOTED: git commit with quoted pathspec containing shell chars" "git commit -- \"path/with\$vars.txt\"" "path/with\$vars.txt"

# ── Group HEREDOC — heredoc-content false positive, M-audit finding #21 residual ─
# Characterized in g-docs/agent-output/wave-w2-1/heredoc-characterization.md;
# fixed in hooks/lib/commit-detect.sh via _commit_detect_strip_heredocs.
# Letters (a)-(g) match the characterization's enumerated test plan.

# (a) fail-before: heredoc to cat/file-write containing a commit line — now NOT detected
test_not_detected "HEREDOC-a: cat heredoc body contains commit line (fail-before, fixed)" \
    $'cat > report.md <<EOF\ngit commit -m "test"\nEOF'

# (b) fail-before: heredoc with quoted delimiter <<'EOF' — now NOT detected
test_not_detected "HEREDOC-b: quoted delimiter <<'EOF' heredoc body contains commit line" \
    $'cat > report.md <<\'EOF\'\ngit commit -m "test"\nEOF'

# (c) fail-before: <<- indented terminator — now NOT detected
test_not_detected "HEREDOC-c: <<- indented terminator heredoc body contains commit line" \
    $'cat > report.md <<-EOF\n\tgit commit -m "test"\n\tEOF'

# (d) regression pin: bash <<EOF with commit body — interpreter guard, stays DETECTED
test_detected "HEREDOC-d: bash <<EOF interpreter-fed heredoc stays detected" \
    $'bash <<EOF\ngit commit -m "test"\nEOF'

# (e) regression pin: unterminated heredoc containing commit line — stays DETECTED
test_detected "HEREDOC-e: unterminated heredoc stays detected (fail-toward-deny)" \
    $'cat > report.md <<EOF\ngit commit -m "test"'

# (f) regression pin: plain newline evasion unaffected by heredoc fix (existing #25 class)
test_detected "HEREDOC-f: plain x\\ngit commit newline evasion unaffected" \
    $'x\ngit commit -m x'

# (g) regression pin: real git commit <<EOF on the opener line stays DETECTED
test_detected "HEREDOC-g: real git commit <<EOF on opener line stays detected" \
    $'git commit -m "hi" <<EOF\nbody text\nEOF'

# Additional interpreter-guard coverage beyond the enumerated (d): other
# shell interpreters/eval must also keep a heredoc body scanned.
test_detected "HEREDOC: eval <<EOF interpreter guard, commit body stays detected" \
    $'eval <<EOF\ngit commit -m "test"\nEOF'
test_detected "HEREDOC: sh <<EOF interpreter guard, commit body stays detected" \
    $'sh <<EOF\ngit commit -m "test"\nEOF'

# (h) M-audit W3 task 16: opener-line SUFFIX scan — a heredoc piped to an
# interpreter AFTER the operator (never in the prefix) must still keep the
# body scanned. Prefix alone (`cat`) would misclassify this as
# non-interpreter and strip the commit line; the suffix scan catches it.
test_detected "HEREDOC-h: cat <<EOF | bash (opener-line suffix interpreter) stays detected" \
    $'cat <<EOF | bash\ngit commit -m "test"\nEOF'

# Regression guard: a non-interpreter suffix (e.g. piped to grep) must NOT
# flip the verdict — only a real interpreter token in the suffix does.
test_not_detected "HEREDOC-i: cat <<EOF | grep foo (non-interpreter suffix) stays not detected" \
    $'cat <<EOF | grep foo\ngit commit -m "test"\nEOF'

# Path-qualified interpreter in the suffix (*/bash glob) also caught.
test_detected "HEREDOC-j: cat <<EOF | /bin/bash (path-qualified suffix interpreter) stays detected" \
    $'cat <<EOF | /bin/bash\ngit commit -m "test"\nEOF'

# ── Group HEREDOC-PATHSPEC — heredoc-pathspec fix, todo row 10 (2026-08-16 live
# repro) — _commit_detect_strip_heredocs now excises the `<<WORD` operator from
# the opener line (prefix+suffix emitted) and never re-emits the terminator
# line, so neither reaches extract_pathspecs' unflagged-token walk. Before the
# fix both leaked in as false CODE pathspecs on a doc-only heredoc commit,
# turning it into a false MIXED deny (hooks/lib/commit-detect.sh's
# `_commit_detect_strip_heredocs`, "todo row 10" fix-rationale comment block —
# content-anchored, not a bare line number, since inserts above it re-stale a
# fixed line cite).

# falsifiability: fix reverted in scratch copy, test confirmed red — 2026-08-23
# (a) fix works: quoted delimiter, -F - message body, doc-only content — no
# pathspecs (previously "MSG" leaked as an unflagged/CODE pathspec).
test_pathspecs "HEREDOC-k: git commit -F - <<'MSG' (quoted delim, doc-only body) emits no pathspecs" \
    $'git commit -F - <<\'MSG\'\nUpdate README docs only\nMSG' ""

# falsifiability: fix reverted in scratch copy, test confirmed red — 2026-08-23
# (a) fix works: unquoted delimiter variant of the same repro form.
test_pathspecs "HEREDOC-l: git commit -F - <<MSG (unquoted delim, doc-only body) emits no pathspecs" \
    $'git commit -F - <<MSG\nUpdate README docs only\nMSG' ""

# falsifiability: fix reverted in scratch copy, test confirmed red — 2026-08-23
# (a) fix works: -q -F - flag variant, one of the exact payload forms from the
# 2026-08-16 live repro (g-docs/todo.md row 10).
test_pathspecs "HEREDOC-m: git commit -q -F - <<'MSG' (-q -F - flag variant, doc-only body) emits no pathspecs" \
    $'git commit -q -F - <<\'MSG\'\nUpdate README docs only\nMSG' ""

# (b) no over-strip regression guard: a plain non-heredoc commit with a real
# positional pathspec must still emit it — a false ALLOW here is worse than
# the false DENY the fix above corrects.
test_pathspecs "HEREDOC-n: git commit -m \"x\" path/to/file (no heredoc) still emits path/to/file" \
    'git commit -m "x" path/to/file' "path/to/file"

# (b) no over-strip: a heredoc opener line carrying a REAL pathspec alongside
# the operator must still emit that pathspec — only the `<<WORD` operator
# match itself is excised, never the opener line's real command tokens.
test_pathspecs "HEREDOC-o: git commit -F - docs/README.md <<'MSG' (real pathspec on opener line) still emits docs/README.md" \
    $'git commit -F - docs/README.md <<\'MSG\'\nUpdate README docs only\nMSG' "docs/README.md"

# todo row 13 / M48e fix round 1, code-lead r1 Minor 9 (not blocking) —
# reviewer probe E4b: two `<<WORD` heredoc operators on one opener line
# (`cat <<A <<B` shape). _commit_detect_strip_heredocs' regex match finds
# only the FIRST `<<WORD` on a line (BASH_REMATCH is leftmost-match only), so
# the second operator, its body, and its terminator all survive into the
# opener line's suffix unstripped. This is not a gate weakness TODAY — the
# surviving tokens still classify CODE in check-commit.sh's unmatched-path
# default (fail-toward-deny), and is_git_commit still detects the `git
# commit` shape (pinned by the is_git_commit assertion below) — but the
# pathspec-extraction leak itself was unpinned, so nothing regression-locked
# that direction if the strip logic changed later. Empirically confirmed
# 2026-08-27: pins CURRENT behaviour only, does not change
# hooks/lib/commit-detect.sh.
test_pathspecs "HEREDOC-p: git commit -m x <<A <<B (two heredoc operators, one opener line) leaks second operator/body/terminator as unstripped pathspecs (fail-toward-deny)" \
    $'git commit -m x <<A <<B\nbody A line\nA\nbody B line\nB' $'<<B\nbody\nB\nline\nB'

# Same command string: is_git_commit must still return DETECTED despite the
# pathspec leak above — classification stays fail-toward-deny either way.
test_detected "HEREDOC-p: git commit -m x <<A <<B (two heredoc operators) is_git_commit still DETECTED" \
    $'git commit -m x <<A <<B\nbody A line\nA\nbody B line\nB'

# ── Summary ───────────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

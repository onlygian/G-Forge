#!/bin/bash
# Unit tests for hooks/lib/classify-changeset.sh
# Tests the file-set classification logic: CODE vs DOC bucket assignment.
# Encodes ground-truth from actual case-statement body (2026-07-18).
# No temp repos — all tests call the function on fixed strings via heredoc only.
#
# Attested 2026-07-18 (W1.5b): 42 passed, 0 failed — after the whitespace-only
# assertion was flipped to pin observed fail-toward-deny behavior (see the
# polarity note on that case; lib header corrected in the same pass).
# W1.6 additions: +5 tests (shadowed .md dirs, pathspec fidelity, pre-commit scan).
# M-audit W3 task 12 additions: +3 tests (README*/CHANGELOG*/LICENSE* non-root
# over-match fix).
# M40 Task 17 additions: +8 tests (REFERENCE bucket coverage: marked bundle
# file set via SNAPSHOT.md, marked via NOTE.md, unmarked-stays-CODE guard,
# code-extension-under-marked-bundle-stays-CODE guard x5 extensions).
# Session C fix round, lane A additions: +8 tests (allowlist-flip guard —
# extensionless/.ps1/.yml/Makefile/uppercase-.PDF under a marked bundle stay
# CODE, a bundle name containing ".." or empty never reaches the marker
# lookup, and a positive control confirming an allowlisted extension under a
# marked bundle still classifies REFERENCE).
# Session C code-gate r2 fix (HQ): +3 tests (dot-segment guard on the whole
# path — `..` below a marked bundle escaping reference/, and `.` segments as
# or below the bundle name, all stay CODE).
# C-4 fix (2026-08-31): +2 tests (backslash-pathspec normalization — a
# backslash path classifies into the same bucket its forward-slash twin
# would, instead of falling through to the *.md root-only DOC arm).
# See the Results line at the end of a run for the current total — not
# restated here as a fixed number (an unpinned count is a review finding,
# G-RULES §G/ADR-013).

LIB="$(cd "$(dirname "$0")" && pwd)/../hooks/lib/classify-changeset.sh"
source "$LIB" || { echo "FAIL: could not source $LIB"; exit 1; }

PASS=0
FAIL=0

# test_classify <name> <paths_string> <expected_has_code> <expected_has_doc> —
# Call gf_classify_changeset via heredoc with the given paths and assert
# the resulting HAS_CODE and HAS_DOC globals match expectations.
# This must use HEREDOC, not pipe, per the lib's call convention.
test_classify() {
    local name="$1" paths="$2" exp_code="$3" exp_doc="$4"
    # Initialize globals before each test to ensure they don't leak state
    HAS_CODE=0
    HAS_DOC=0
    # HEREDOC invocation — never a pipe, per lib's call convention
    gf_classify_changeset <<EOF
$paths
EOF
    # After the heredoc, check results
    local code_match=0 doc_match=0
    if [ "$HAS_CODE" -eq "$exp_code" ]; then
        code_match=1
    fi
    if [ "$HAS_DOC" -eq "$exp_doc" ]; then
        doc_match=1
    fi
    if [ "$code_match" -eq 1 ] && [ "$doc_match" -eq 1 ]; then
        echo "PASS: $name"
        PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected HAS_CODE=$exp_code HAS_DOC=$exp_doc, got HAS_CODE=$HAS_CODE HAS_DOC=$HAS_DOC)"
        FAIL=$((FAIL+1))
    fi
}

# ── Task 5: Bucket-rule coverage — one distinct assertion per rule path ───────

# DOC bucket: g-docs/* directory
test_classify "DOC: g-docs/test.md" "g-docs/test.md" 0 1
test_classify "DOC: g-docs/subdir/file.txt" "g-docs/subdir/file.txt" 0 1

# DOC bucket: g-wiki/* directory
test_classify "DOC: g-wiki/index.md" "g-wiki/index.md" 0 1
test_classify "DOC: g-wiki/posts/entry.md" "g-wiki/posts/entry.md" 0 1

# DOC bucket: docs/* directory
test_classify "DOC: docs/README.md" "docs/README.md" 0 1
test_classify "DOC: docs/api/guide.md" "docs/api/guide.md" 0 1

# DOC bucket: README*, CHANGELOG*, LICENSE* (root-level)
test_classify "DOC: README.md" "README.md" 0 1
test_classify "DOC: README_extended" "README_extended" 0 1
test_classify "DOC: CHANGELOG.md" "CHANGELOG.md" 0 1
test_classify "DOC: CHANGELOG.txt" "CHANGELOG.txt" 0 1
test_classify "DOC: LICENSE" "LICENSE" 0 1
test_classify "DOC: LICENSE.txt" "LICENSE.txt" 0 1

# CODE bucket: non-root paths whose top-level component merely starts with
# README/CHANGELOG/LICENSE — a bare `README*` glob matches the whole path
# string, so without a root check these were over-matching into DOC even
# though they are not the root doc file (M-audit W3 task 12). Pre-fix these
# failed (classified DOC, 0 1); post-fix they fall through to the unmatched
# CODE default (fail-toward-deny polarity unchanged).
test_classify "CODE: non-root path, top dir merely starts with README" "README-archive/notes.txt" 1 0
test_classify "CODE: non-root path, top dir merely starts with CHANGELOG" "CHANGELOGS/2020-01-01.md" 1 0
test_classify "CODE: non-root path, top dir merely starts with LICENSE" "LICENSE-checker/scan.sh" 1 0

# DOC bucket: *.md at repo root (no slash in path)
test_classify "DOC: root-level *.md (no slash)" "example.md" 0 1
test_classify "DOC: root-level *.md another example" "CONTRIBUTING.md" 0 1

# CODE bucket: nested *.md (contains a slash)
test_classify "CODE: nested *.md file" "some/dir/file.md" 1 0
test_classify "CODE: nested *.md in docs dir" "content/pages/article.md" 1 0

# CODE bucket: shadowed .md directory — directory name ends in .md but doesn't match
# special directory rules (g-docs, g-wiki, docs), so files inside fall through to CODE
# (M-audit W1.6 task 11)
test_classify "CODE: file in docs.md directory (no match)" "docs.md/README" 1 0
test_classify "CODE: file in api.md directory (no match)" "api.md/guide.txt" 1 0
test_classify "CODE: nested .md file in .md-named directory" "docs.md/file.md" 1 0

# CODE/DOC bucket: backslash pathspec normalization (C-4, 2026-08-30) — a
# Windows-style backslash path has no forward slash for the `*/*` nested
# split or the `skills/*` etc. CODE arms to match, so it fell through to the
# *.md root-only arm and misclassified DOC instead of nested CODE. The
# classifier now normalizes `\` to `/` before the case ladder; a backslash
# path classifies into the SAME bucket its forward-slash twin would.
test_classify "CODE: backslash pathspec normalizes to nested-md CODE (skills\\g-review\\SKILL.md)" "skills\\g-review\\SKILL.md" 1 0
test_classify "DOC: backslash pathspec classifies as its forward-slash twin (docs\\notes.md)" "docs\\notes.md" 0 1

# CODE bucket: hooks/* directory
test_classify "CODE: hooks/check-commit.sh" "hooks/check-commit.sh" 1 0
test_classify "CODE: hooks/lib/commit-detect.sh" "hooks/lib/commit-detect.sh" 1 0

# CODE bucket: skills/* directory
test_classify "CODE: skills/g-review/SKILL.md" "skills/g-review/SKILL.md" 1 0
test_classify "CODE: skills/g-init/SKILL.md" "skills/g-init/SKILL.md" 1 0

# CODE bucket: agents/* directory
test_classify "CODE: agents/architect.md" "agents/architect.md" 1 0
test_classify "CODE: agents/reviewer/check.md" "agents/reviewer/check.md" 1 0

# CODE bucket: commands/* directory
test_classify "CODE: commands/g-review.md" "commands/g-review.md" 1 0
test_classify "CODE: commands/g-init.md" "commands/g-init.md" 1 0

# CODE bucket: profiles/* directory
test_classify "CODE: profiles/stack/rules.md" "profiles/stack/rules.md" 1 0

# CODE bucket: tests/* directory
test_classify "CODE: tests/test-foo.sh" "tests/test-foo.sh" 1 0
test_classify "CODE: tests/fixtures/data.json" "tests/fixtures/data.json" 1 0

# CODE bucket: .claude-plugin/* directory
test_classify "CODE: .claude-plugin/plugin.json" ".claude-plugin/plugin.json" 1 0
test_classify "CODE: .claude-plugin/marketplace.json" ".claude-plugin/marketplace.json" 1 0

# CODE bucket: .claude/rules/* directory
test_classify "CODE: .claude/rules/g-rules-A.md" ".claude/rules/g-rules-A.md" 1 0
test_classify "CODE: .claude/rules/architecture.md" ".claude/rules/architecture.md" 1 0

# CODE bucket: unknown/unmatched path (default: stricter gate)
test_classify "CODE: unknown root file (no match)" "unknown.txt" 1 0
test_classify "CODE: unknown nested path" "random/dir/file" 1 0
test_classify "CODE: unknown extension" "file.xyz" 1 0

# CODE bucket: pathspec fidelity — unmatched/complex pathspecs fall through to CODE
# (M-audit W1.6 task 10) — verifies the stricter default gate behavior
test_classify "CODE: pathspec with quoted/escaped chars not matching DOC rules" "\"quoted-path\"/file.txt" 1 0
test_classify "CODE: pathspec with shell metacharacters not matching any rule" "path\$with\$vars/file" 1 0

# BOUNDARY: Empty input — neither flag set (both 0)
test_classify "EMPTY: empty input string" "" 0 0
# BOUNDARY: whitespace-only (non-empty) line is NOT skipped by the lib's
# `[ -z "$_f" ] && continue` guard — it falls through every case arm to the
# unmatched→CODE default. This is fail-toward-deny (an unparseable/garbage
# path gates as the stricter CODE bucket rather than silently vanishing) —
# see the lib's own header for the current (Session C-corrected) framing of
# this behavior; the stale "byte-identical to the pre-extraction inline loop"
# claim this comment used to carry was removed there, not restated here.
test_classify "WHITESPACE: whitespace-only line falls through to CODE (fail-toward-deny)" "
  " 1 0

# MIXED: One DOC path and one CODE path → both flags 1
test_classify "MIXED: g-docs path + hooks path" "g-docs/example.md
hooks/test.sh" 1 1
test_classify "MIXED: README + unknown file" "README.md
some/code/file.py" 1 1
test_classify "MIXED: nested .md + root .md" "dir/nested.md
root.md" 1 1

# ── Task 6: Single-classifier invariant — grep tests ──────────────────────────

echo ""
echo "── Task 6: Single-classifier invariant checks ────────────────────────────"

# Task 6a: Verify no other hooks contain DOC bucket classification patterns
# (except classify-changeset.sh itself). These patterns should NOT appear as
# case-statement or if-statement logic elsewhere — they belong in ONE place only.

DOC_PATTERNS=("g-docs/\*" "g-wiki/\*" "docs/\*" "README\*" "CHANGELOG\*" "LICENSE\*")

# Check that no hook file (except the lib itself) contains a case-statement
# matching the DOC bucket patterns. We search for the literal case patterns.
# If found outside of classify-changeset.sh, that's a duplicate rule violation.
# Scan both *.sh files AND the extensionless hooks/pre-commit (M-audit W1.6 task 12).

found_duplicate_rules=0

# Search for case statement patterns that match DOC buckets in other hooks
# Look for lines like `g-docs/*|` or `README*|` in case statements
for hook_file in hooks/*.sh hooks/pre-commit; do
    [ "$hook_file" = "hooks/lib/classify-changeset.sh" ] && continue
    [ -f "$hook_file" ] || continue
    # Search for DOC bucket case patterns (pipe-separated glob patterns in case statements)
    if grep -E 'g-docs/\*|g-wiki/\*|docs/\*|README\*|CHANGELOG\*|LICENSE\*' "$hook_file" | grep -qv "^[[:space:]]*#"; then
        # Check if it's in a case-statement (not just a comment)
        if grep 'case.*in' "$hook_file" | head -1 > /dev/null; then
            # This hook has a case statement and contains DOC bucket patterns
            # Likely a duplicate — but check more carefully by examining context
            if sed -n '/^[[:space:]]*case.*in/,/^[[:space:]]*esac/p' "$hook_file" | grep -E 'g-docs/\*|g-wiki/\*|docs/\*|README\*|CHANGELOG\*|LICENSE\*'; then
                echo "FAIL: Task 6a — found DOC bucket case-pattern duplicated in $hook_file (expected zero duplicates)"
                FAIL=$((FAIL+1))
                found_duplicate_rules=1
            fi
        fi
    fi
done

if [ "$found_duplicate_rules" -eq 0 ]; then
    echo "PASS: Task 6a — no DOC bucket classification patterns found in other hooks (including hooks/pre-commit)"
    PASS=$((PASS+1))
fi

# Task 6b: Verify that hooks/check-commit.sh sources classify-changeset.sh
# and actually calls gf_classify_changeset (via heredoc, not pipe)
if grep -q "^\. .*classify-changeset.sh" hooks/check-commit.sh && \
   grep -q "gf_classify_changeset <<" hooks/check-commit.sh; then
    echo "PASS: Task 6b-1 — hooks/check-commit.sh sources lib and calls gf_classify_changeset"
    PASS=$((PASS+1))
else
    echo "FAIL: Task 6b-1 — hooks/check-commit.sh missing lib source or call"
    FAIL=$((FAIL+1))
fi

# Task 6c: Verify that hooks/pre-commit sources classify-changeset.sh
# and actually calls gf_classify_changeset (via heredoc, not pipe)
if grep -q "^\. .*classify-changeset.sh" hooks/pre-commit && \
   grep -q "gf_classify_changeset <<" hooks/pre-commit; then
    echo "PASS: Task 6b-2 — hooks/pre-commit sources lib and calls gf_classify_changeset"
    PASS=$((PASS+1))
else
    echo "FAIL: Task 6b-2 — hooks/pre-commit missing lib source or call"
    FAIL=$((FAIL+1))
fi

# ── Task 7: REFERENCE bucket coverage (M40 Task 17) ────────────────────────────
#
# GF_CLASSIFY_ROOT points the marker lookup at a throwaway plain directory
# (no git init — the lib's marker check uses `[ -f ]`, never `git ls-files`,
# per the lib header) so these tests never touch this repo's own tree.
# Fixture layout:
#   $REF_ROOT/reference/marked/SNAPSHOT.md    (marker present — SNAPSHOT.md)
#   $REF_ROOT/reference/marked2/NOTE.md       (marker present — NOTE.md)
#   $REF_ROOT/reference/unmarked/             (no marker file)
REF_ROOT="$(mktemp -d)"
mkdir -p "$REF_ROOT/reference/marked" "$REF_ROOT/reference/marked2" "$REF_ROOT/reference/unmarked"
touch "$REF_ROOT/reference/marked/SNAPSHOT.md"
touch "$REF_ROOT/reference/marked2/NOTE.md"
# Markers planted where an UNGUARDED lookup for a `..` or empty bundle name
# would resolve ($ROOT/reference/../SNAPSHOT.md and $ROOT/reference//SNAPSHOT.md)
# so the dot-segment guard tests below (Case (5)) can actually go red when
# the guard is removed. The first probe of 2026-08-30 stayed green without these: a guard
# test that cannot fail proves nothing (G-RULES §H).
touch "$REF_ROOT/SNAPSHOT.md" "$REF_ROOT/reference/SNAPSHOT.md"

# test_classify_r <name> <paths_string> <exp_code> <exp_doc> <exp_reference> —
# same convention as test_classify, extended to also assert HAS_REFERENCE.
# `GF_CLASSIFY_ROOT=$REF_ROOT gf_classify_changeset` is a prefix assignment on
# a simple command — bash scopes it to this one function invocation only (and
# anything it calls), so REF_ROOT never leaks into any other test in this file.
test_classify_r() {
    local name="$1" paths="$2" exp_code="$3" exp_doc="$4" exp_ref="$5"
    HAS_CODE=0
    HAS_DOC=0
    HAS_REFERENCE=0
    GF_CLASSIFY_ROOT="$REF_ROOT" gf_classify_changeset <<EOF
$paths
EOF
    if [ "$HAS_CODE" -eq "$exp_code" ] && [ "$HAS_DOC" -eq "$exp_doc" ] && [ "$HAS_REFERENCE" -eq "$exp_ref" ]; then
        echo "PASS: $name"
        PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected HAS_CODE=$exp_code HAS_DOC=$exp_doc HAS_REFERENCE=$exp_ref, got HAS_CODE=$HAS_CODE HAS_DOC=$HAS_DOC HAS_REFERENCE=$HAS_REFERENCE)"
        FAIL=$((FAIL+1))
    fi
}

# Case (1): marked reference-only file set — both the bundle's own marker
# file (SNAPSHOT.md, which would otherwise hit the nested-*.md→CODE arm) and
# a plain companion file classify as REFERENCE, never CODE or DOC. The
# reference/*/* arm runs before the *.md arm specifically so this holds.
test_classify_r "REFERENCE: marked bundle file set (SNAPSHOT.md + data file)" \
"reference/marked/SNAPSHOT.md
reference/marked/data.txt" 0 0 1

# Second marker variant — NOTE.md also marks a bundle REFERENCE (not just
# SNAPSHOT.md).
test_classify_r "REFERENCE: marked bundle via NOTE.md marker" \
    "reference/marked2/data.txt" 0 0 1

# Case (2) — GUARD: an unmarked reference/<bundle>/... path (no SNAPSHOT.md or
# NOTE.md in its bundle dir) still classifies as CODE, not REFERENCE —
# fail-toward-deny, unmarked reference/ paths get no exemption.
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-30
test_classify_r "CODE: unmarked reference/<bundle> path stays CODE" \
    "reference/unmarked/data.txt" 1 0 0

# Case (3) — GUARD: a code-extension file under a MARKED bundle still
# classifies as CODE, never REFERENCE — the gate-softening-leaks premortem
# mitigation (a marked snapshot dir must not be able to smuggle an executable
# past the review gate). One assertion per representative extension named in
# the dispatch spec (sh, js, py, ts) plus one more from the full list (go) to
# exercise a later alternation member, not just the first.
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-30
test_classify_r "CODE: .sh file under marked bundle stays CODE" \
    "reference/marked/tool.sh" 1 0 0
test_classify_r "CODE: .js file under marked bundle stays CODE" \
    "reference/marked/tool.js" 1 0 0
test_classify_r "CODE: .py file under marked bundle stays CODE" \
    "reference/marked/tool.py" 1 0 0
test_classify_r "CODE: .ts file under marked bundle stays CODE" \
    "reference/marked/tool.ts" 1 0 0
test_classify_r "CODE: .go file under marked bundle stays CODE" \
    "reference/marked/tool.go" 1 0 0

# Case (4) — GUARD: Session C fix round, lane A — the inert-set under a marked
# bundle is now an ALLOWLIST (only .md/.markdown/.txt/.rst/.pdf/.png/.jpg/
# .jpeg/.gif/.webp/.svg/.csv/.json/.html/.xml reach the marker lookup), never
# a denylist — a denylist guarding this exemption could never make "must
# never smuggle an executable past the review gate" true. Everything NOT on
# the allowlist gates as CODE even under a marked bundle: extensionless
# files, .ps1/.bat/.yml, Makefile, and an uppercase extension (matching is
# case-sensitive by design — the safe direction).
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-30
test_classify_r "CODE: extensionless file under marked bundle stays CODE" \
    "reference/marked/pre-commit" 1 0 0
test_classify_r "CODE: .ps1 file under marked bundle stays CODE" \
    "reference/marked/run.ps1" 1 0 0
test_classify_r "CODE: .yml file under marked bundle stays CODE" \
    "reference/marked/ci.yml" 1 0 0
test_classify_r "CODE: Makefile under marked bundle stays CODE" \
    "reference/marked/Makefile" 1 0 0
test_classify_r "CODE: uppercase .PDF extension under marked bundle stays CODE (case-sensitive)" \
    "reference/marked/doc.PDF" 1 0 0

# Case (5) — GUARD: a path with a `..`, `.` or empty segment ANYWHERE in it
# (as the bundle name, or below a marked bundle) never reaches the marker
# lookup — each classifies as CODE outright (fail-toward-deny before the
# marker lookup is even attempted).
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-30
test_classify_r "CODE: bundle name containing .. never reaches marker lookup" \
    "reference/../marked/data.txt" 1 0 0
test_classify_r "CODE: empty bundle name never reaches marker lookup" \
    "reference//data.txt" 1 0 0
# Traversal BELOW a marked bundle (code-lead r2, 2026-08-30): the bundle name
# is clean, the marker exists, and the path escapes reference/ — the guard
# must look at every segment, not the first one.
test_classify_r "CODE: .. below a marked bundle escaping reference/ stays CODE" \
    "reference/marked/../../CLAUDE.md" 1 0 0
test_classify_r "CODE: . segment as bundle name stays CODE" \
    "reference/./data.txt" 1 0 0
test_classify_r "CODE: . segment below a marked bundle stays CODE" \
    "reference/marked/./data.txt" 1 0 0

# Positive control — an allowlisted extension under a marked bundle still
# classifies as REFERENCE, proving the allowlist flip didn't also break the
# exemption itself.
test_classify_r "REFERENCE: allowlisted .html file under marked bundle stays REFERENCE" \
    "reference/marked/spec.html" 0 0 1

rm -rf "$REF_ROOT"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

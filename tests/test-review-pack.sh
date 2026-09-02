#!/bin/bash
# Unit tests for skills/g-review/scripts/build-review-pack.sh — the shared
# deterministic context-pack builder behind /g-review and /g-doc-review (v2.6).
# Pins: round minting (highest-plus-one, never a count), the MODE: full|delta
# decision, all three data-driven DELTA_INELIGIBLE reasons plus `forced`, the
# --check freshness contract (PACK: fresh | stale old=<sha> new=<sha>), the
# PACK_TREE == hook write-tree identity (ADR-004 — the sentinel stamps the same
# value hooks/pre-commit hashes at commit time), the exit-0 invariant on every
# path, and the MANIFEST closed-set literal spellings.
#
# Fixture repos are built fresh per group under a scratch dir; per-group slugs
# keep the date-keyed round series independent.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/skills/g-review/scripts/build-review-pack.sh"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

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

DATE=$(date +%Y-%m-%d)
REVDIR=g-docs/agent-output/review

mkrepo() { # $1: dir name — fresh repo with one commit, dirty tracked change
    local d="$SANDBOX/$1"
    rm -rf "$d"; mkdir -p "$d"; cd "$d" || exit 1
    git init -q -b main . && git config user.email t@t && git config user.name t
    mkdir -p src g-docs/plans g-docs/milestones
    echo one > src/a.txt; echo two > src/b.txt; echo '{}' > package.json
    printf '# plan\n' > g-docs/plans/p1.md
    git add -A && git commit -qm init
}

# --- Group 1: not-a-repo + exit-0 invariant ---------------------------------
mkdir -p "$SANDBOX/norepo"; cd "$SANDBOX/norepo"
OUT=$(bash "$SCRIPT" 2>&1); RC=$?
ok  "not-a-repo: prints EXIT: not-a-repo"     grep -q '^EXIT: not-a-repo$' <<<"$OUT"
ok  "not-a-repo: exits 0"                     test "$RC" -eq 0

# --- Group 2: full build, MANIFEST mirror, PACK_TREE == hook write-tree -----
mkrepo g2
echo one-mod > src/a.txt; echo '{"x":1}' > package.json; echo readme > README.md
git add README.md   # staged new file joins the union
OUT=$(bash "$SCRIPT" --gate code --slug g2); RC=$?
PACK=$(sed -n 's/^PACK_DIR: //p' <<<"$OUT")
ok  "full build: exits 0"                     test "$RC" -eq 0
ok  "full build: ROUND: 1"                    grep -q '^ROUND: 1$' <<<"$OUT"
ok  "full build: MODE: full literal"          grep -q '^MODE: full$' <<<"$OUT"
ok  "full build: DIFF_SOURCE: staged-union"   grep -q '^DIFF_SOURCE: staged-union$' <<<"$OUT"
ok  "full build: OUTPUT_FILE minted for code-lead series" \
    grep -q "^OUTPUT_FILE: $REVDIR/code-lead-$DATE-g2-r1\.md$" <<<"$OUT"
ok  "full build: MANIFEST_CHANGED: true on package.json change" \
    grep -q '^MANIFEST_CHANGED: true$' <<<"$OUT"
ok  "full build: DOC_SURFACE names README.md" \
    grep -q '^DOC_SURFACE: README.md$' <<<"$OUT"
ok  "full build: diff.patch exists"           test -s "$PACK/diff.patch"
ok  "full build: files.txt exists"            test -s "$PACK/files.txt"
ok  "full build: slice carries full current content of src/a.txt" \
    grep -q one-mod "$PACK/slices/src__a.txt"
ok  "full build: MANIFEST mirrors the stdout KEY lines" \
    bash -c 'grep "^PACK_TREE: " "$1/MANIFEST" >/dev/null && grep "^MODE: full$" "$1/MANIFEST" >/dev/null' _ "$PACK"
# ADR-004 identity: the pack's tree is the exact write-tree the pre-commit hook
# will hash — stage the union for real and compare.
TREE=$(sed -n 's/^PACK_TREE: //p' <<<"$OUT")
git add -u
ok  "PACK_TREE equals git write-tree of the staged union (hook identity)" \
    test "$TREE" = "$(git write-tree)"
git reset -q

# --- Group 3: no-changes exit -----------------------------------------------
mkrepo g3
OUT=$(bash "$SCRIPT" --slug g3); RC=$?
ok  "clean tree on mainline: EXIT: no-changes" grep -q '^EXIT: no-changes$' <<<"$OUT"
ok  "clean tree: exits 0"                      test "$RC" -eq 0

# --- Group 4: mainline fallback ----------------------------------------------
mkrepo g4
git checkout -qb feat
echo feat-work > src/a.txt && git commit -qam feat-work   # committed, clean tree
OUT=$(bash "$SCRIPT" --slug g4)
ok  "committed-but-unreviewed branch: DIFF_SOURCE: mainline-fallback" \
    grep -q '^DIFF_SOURCE: mainline-fallback$' <<<"$OUT"
ok  "mainline fallback: MAINLINE resolved to main" \
    grep -q '^MAINLINE: main$' <<<"$OUT"

# --- Group 5: round minting is highest-plus-one, never a count ---------------
mkrepo g5
mkdir -p "$REVDIR"
: > "$REVDIR/code-lead-$DATE-g5-r5.md"     # hand-crafted high ordinal, middles absent
echo mod > src/a.txt
OUT=$(bash "$SCRIPT" --slug g5)
ok  "round minting: r5 record alone mints ROUND: 6 (highest-plus-one)" \
    grep -q '^ROUND: 6$' <<<"$OUT"
# falsifiability: guard neutered in scratch copy (ROUND=$((HI+1)) → ROUND=1), test confirmed red — 2026-09-02

# --- Group 6: delta eligibility ----------------------------------------------
mkrepo g6
echo mod-a > src/a.txt; echo '{"y":2}' > package.json
bash "$SCRIPT" --slug g6 >/dev/null                 # round 1 pack
: > "$REVDIR/code-lead-$DATE-g6-r1.md"              # reviewer record lands
printf 'finding 1: src/a.txt count stale\n' > "$SANDBOX/closes.txt"
echo mod-a-fixed > src/a.txt                        # fix inside the reviewed set
OUT=$(bash "$SCRIPT" --slug g6 --closes "$SANDBOX/closes.txt"); RC=$?
PACK2=$(sed -n 's/^PACK_DIR: //p' <<<"$OUT")
PRIOR_TREE=$(sed -n 's/^PACK_TREE: //p' "$REVDIR/pack-$DATE-g6-r1/MANIFEST")
ok  "delta: exits 0"                          test "$RC" -eq 0
ok  "delta: fix within prior set mints MODE: delta" grep -q '^MODE: delta$' <<<"$OUT"
ok  "delta: DELTA_BASE is the prior round's PACK_TREE" \
    grep -q "^DELTA_BASE: $PRIOR_TREE$" <<<"$OUT"
ok  "delta: fix-delta.patch exists"           test -s "$PACK2/fix-delta.patch"
ok  "delta: prior/records.txt lists the r1 record" \
    grep -q "code-lead-$DATE-g6-r1\.md" "$PACK2/prior/records.txt"
ok  "delta: prior/claimed-closed.txt is the verbatim --closes copy" \
    grep -q 'finding 1: src/a.txt count stale' "$PACK2/prior/claimed-closed.txt"
# falsifiability: guard neutered in scratch copy (MODE=delta branch forced to full), test confirmed red — 2026-09-02

# --- Group 7: DELTA_INELIGIBLE closed set ------------------------------------
# 7a: fix outside the reviewed set forces a full round
: > "$REVDIR/code-lead-$DATE-g6-r2.md"
echo new-src > src/new.txt; git add src/new.txt
OUT=$(bash "$SCRIPT" --slug g6)
ok  "ineligible: out-of-set fix prints fix-outside-reviewed-set <path>" \
    grep -q '^DELTA_INELIGIBLE: fix-outside-reviewed-set src/new.txt$' <<<"$OUT"
ok  "ineligible: out-of-set fix runs MODE: full" grep -q '^MODE: full$' <<<"$OUT"
git reset -q src/new.txt && rm -f src/new.txt

# 7b: forced (--force-full)
: > "$REVDIR/code-lead-$DATE-g6-r3.md"
echo mod-a-again > src/a.txt
OUT=$(bash "$SCRIPT" --slug g6 --force-full)
ok  "ineligible: --force-full prints DELTA_INELIGIBLE: forced" \
    grep -q '^DELTA_INELIGIBLE: forced$' <<<"$OUT"
ok  "forced round still runs MODE: full"      grep -q '^MODE: full$' <<<"$OUT"

# 7c: prior-record-missing — a listed r-record absent from the series
mkrepo g7c
echo mod > src/a.txt
bash "$SCRIPT" --slug g7c >/dev/null            # r1 pack, but NO r1 record written
echo mod2 > src/a.txt
OUT=$(bash "$SCRIPT" --slug g7c)
ok  "ineligible: absent prior record prints prior-record-missing" \
    grep -q '^DELTA_INELIGIBLE: prior-record-missing$' <<<"$OUT"

# 7d: no-prior-pack — records exist but the prior pack MANIFEST is unreadable
mkrepo g7d
echo mod > src/a.txt
bash "$SCRIPT" --slug g7d >/dev/null
: > "$REVDIR/code-lead-$DATE-g7d-r1.md"
rm -f "$REVDIR/pack-$DATE-g7d-r1/MANIFEST"      # fresh-clone / gitignored-dir-gone shape
echo mod2 > src/a.txt
OUT=$(bash "$SCRIPT" --slug g7d)
ok  "ineligible: unreadable prior MANIFEST prints no-prior-pack" \
    grep -q '^DELTA_INELIGIBLE: no-prior-pack$' <<<"$OUT"
# falsifiability: reasons swapped in scratch copy, all three 7* asserts confirmed red — 2026-09-02

# --- Group 8: --check freshness ----------------------------------------------
mkrepo g8
echo mod > src/a.txt
OUT=$(bash "$SCRIPT" --slug g8)
PACK8=$(sed -n 's/^PACK_DIR: //p' <<<"$OUT")
OUT=$(bash "$SCRIPT" --check "$PACK8"); RC=$?
ok  "check: unchanged tree is PACK: fresh"    grep -q '^PACK: fresh$' <<<"$OUT"
ok  "check: exits 0"                          test "$RC" -eq 0
echo drift > src/b.txt                        # post-build edit
OUT=$(bash "$SCRIPT" --check "$PACK8")
ok  "check: post-build edit is PACK: stale with old= and new= shas" \
    grep -qE '^PACK: stale old=[0-9a-f]{40} new=[0-9a-f]{40}$' <<<"$OUT"

# --- Group 9: doc gate + --reuse ---------------------------------------------
mkrepo g9
echo mod > src/a.txt
OUT=$(bash "$SCRIPT" --gate doc --slug g9)
ok  "doc gate: OUTPUT_FILE minted for doc-reviewer series" \
    grep -q "^OUTPUT_FILE: $REVDIR/doc-reviewer-$DATE-g9-r1\.md$" <<<"$OUT"
PACK9=$(sed -n 's/^PACK_DIR: //p' <<<"$OUT")
OUT=$(bash "$SCRIPT" --gate doc --slug g9b --reuse "$PACK9"); RC=$?
ok  "reuse: matching tree adopts the existing pack dir" \
    grep -q "^PACK_DIR: $PACK9$" <<<"$OUT"
ok  "reuse: notes the adoption"               grep -q 'reused code-gate pack' <<<"$OUT"
ok  "reuse: exits 0"                          test "$RC" -eq 0
echo drift > src/b.txt
OUT=$(bash "$SCRIPT" --gate doc --slug g9c --reuse "$PACK9")
ok  "reuse: stale pack declined, fresh pack built instead" \
    bash -c 'grep -q "reuse declined" <<<"$1" && grep -q "^MODE: full$" <<<"$1"' _ "$OUT"

# --- Group 9b: reuse minting is highest-plus-one across pack dirs AND records -
mkrepo g9r
echo mod > src/a.txt
OUT=$(bash "$SCRIPT" --gate code --slug g9r)
PACK9R=$(sed -n 's/^PACK_DIR: //p' <<<"$OUT")
mkdir -p "$REVDIR/pack-$DATE-g9rd-r3"           # stray pack-dir ordinal, no record
OUT=$(bash "$SCRIPT" --gate doc --slug g9rd --reuse "$PACK9R"); RC=$?
ok  "reuse minting: pack-dir ordinal counts — ROUND: 4 (highest-plus-one)" \
    grep -q '^ROUND: 4$' <<<"$OUT"
ok  "reuse minting: OUTPUT_FILE minted at r4 in the doc-reviewer series" \
    grep -q "^OUTPUT_FILE: $REVDIR/doc-reviewer-$DATE-g9rd-r4\.md$" <<<"$OUT"
ok  "reuse minting: exits 0"                  test "$RC" -eq 0
# falsifiability: pack-dir glob dropped from the reuse loop in scratch copy (record-only scan → ROUND: 1), both asserts confirmed red — 2026-09-02

# --- Group 11: unborn HEAD — initial-commit review (empty-tree diff base) -----
d="$SANDBOX/g11"; rm -rf "$d"; mkdir -p "$d"; cd "$d" || exit 1
git init -q -b main . && git config user.email t@t && git config user.name t
mkdir -p src
echo hello > src/first.txt
git add src/first.txt                            # staged content, HEAD unborn
OUT=$(bash "$SCRIPT" --slug g11); RC=$?
PACK11=$(sed -n 's/^PACK_DIR: //p' <<<"$OUT")
ok  "unborn HEAD: exits 0"                     test "$RC" -eq 0
ok  "unborn HEAD: PACK_HEAD: none"             grep -q '^PACK_HEAD: none$' <<<"$OUT"
ok  "unborn HEAD: DIFF_SOURCE: staged-union"   grep -q '^DIFF_SOURCE: staged-union$' <<<"$OUT"
ok  "unborn HEAD: FILES counts the staged file" grep -q '^FILES: 1$' <<<"$OUT"
ok  "unborn HEAD: files.txt names src/first.txt" grep -q 'src/first\.txt' "$PACK11/files.txt"
ok  "unborn HEAD: diff.patch carries the staged content" grep -q hello "$PACK11/diff.patch"
ok  "unborn HEAD: notes the empty-tree diff base" grep -q 'unborn HEAD' <<<"$OUT"
# ADR-004 identity holds on the unborn path too: the pack's tree is the exact
# write-tree the pre-commit hook will hash for the initial commit.
TREE11=$(sed -n 's/^PACK_TREE: //p' <<<"$OUT")
ok  "unborn HEAD: PACK_TREE equals git write-tree (hook identity)" \
    test "$TREE11" = "$(git write-tree)"
# falsifiability: DIFF_BASE reverted to bare HEAD in scratch copy (pre-fix shape → FILES: 0, empty diff.patch/files.txt), content asserts confirmed red — 2026-09-02

# --- Group 10: closed-set spelling guard on the script itself ----------------
ok  "script pins the DELTA_INELIGIBLE closed set in its contract header" \
    bash -c 'grep -q "fix-outside-reviewed-set <path> |" "$1" && grep -q "no-prior-pack | prior-record-missing | forced" "$1"' _ "$SCRIPT"
ok  "script contract names EXIT closed set not-a-repo | no-changes" \
    grep -q 'EXIT: not-a-repo | no-changes' "$SCRIPT"
ok  "script always exits 0 (no other exit codes present)" \
    bash -c '! grep -E "exit [1-9]" "$1"' _ "$SCRIPT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

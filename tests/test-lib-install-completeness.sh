#!/bin/bash
# Invariant tests for the hooks/lib/ install surface.
#
# WHY THIS SUITE EXISTS
# The install list is a HAND-MAINTAINED ENUMERATION in four separate documents
# (g-init's Step 6 table, g-update's realign table, g-doctor's Check 16, and
# README). Nothing asserted `installed ⊇ actually-sourced`, so when
# stdin-read.sh and semver-compare.sh were added to hooks/lib/ they were never
# added to any install list — /g-init shipped a 4-of-6 install through the
# commit gate, a full review pipeline, /g-doctor, and the v2.4.0 release. It
# was found by a human hand-walking the list, because the defect was never in a
# diff: it lived in an enumeration that drifted from what the code references.
#
# This suite derives the truth from the code (what hooks actually source, what
# is actually on disk) and asserts every document agrees — the same
# derive-don't-type doctrine ADR-011 applies to CLAUDE.md, pointed at the
# install list. Adding a lib without updating the docs fails here.
#
# Total assertions: 47 = 43 original (2 derivation-sanity + (6 libs x 4 doc surfaces)
# + 2 g-doctor-derives-from-disk + 6 reverse + 2 set-parity + 4
# count-coherence + 1 combined-file-count + 1 commit-gate matcher pin
# (audit-7 H3) + 1 hooks.json empty-manifest pin (audit-7 H9))
# + 4 skill lib-dir pins (F1-1 fix). Count is RUNNER-OBSERVED and must equal
# the `Results:` line — the finding-#20 cross-check that catches a suite
# silently dropping cases. It scales with the lib count: adding a lib adds 5
# assertions (4 surfaces + 1 reverse), so re-derive this header from a run,
# never by hand.
#
# g-doctor is deliberately NOT a per-lib surface. Its Check 16 was changed to
# enumerate `hooks/lib/*.sh` from disk rather than from a written list, because
# a hardcoded list cannot detect a lib missing from the list — that is what let
# the 4-of-6 install pass the check. So this suite asserts the OPPOSITE of the
# other four surfaces there: that Check 16 derives, and carries no lib names.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$REPO/hooks"
G_INIT="$REPO/skills/g-init/SKILL.md"
G_UPDATE="$REPO/skills/g-update/SKILL.md"
G_DOCTOR="$REPO/skills/g-doctor/SKILL.md"
README="$REPO/README.md"
PASS=0
FAIL=0

ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# assert_grep <file> <fixed-string> <name>
# Fixed-string match (-F) so lib basenames containing `.` can't act as regex
# wildcards and pass on a near-miss.
assert_grep() {
    if grep -qF -- "$2" "$1"; then ok "$3"; else bad "$3 (missing: $2)"; fi
}

# ── Derive ground truth from the code, never from a list ──────────────────

# Libs actually sourced by the top-level hooks and the native pre-commit hook.
SOURCED=$(grep -rhoE 'lib/[a-z0-9-]+\.sh' "$HOOKS"/*.sh "$HOOKS/pre-commit" 2>/dev/null \
          | sed 's|^lib/||' | sort -u)

# Libs actually present on disk.
ONDISK=$(cd "$HOOKS/lib" && ls -1 *.sh 2>/dev/null | sort)

# Top-level hook count (hooks/*.sh — lib/ is a subdir, pre-commit has no .sh).
HOOK_COUNT=$(ls -1 "$HOOKS"/*.sh 2>/dev/null | wc -l | tr -d ' ')
LIB_COUNT=$(printf '%s\n' "$ONDISK" | grep -c .)
TOTAL_FILES=$((HOOK_COUNT + LIB_COUNT))

# num_word <n> — spelled-out form, for docs that write counts as words.
# Covers the range the install surface can plausibly reach; an out-of-range
# count returns the digits so the assertion fails loudly rather than silently
# comparing against an empty string.
num_word() {
    case "$1" in
        3) echo three;;   4) echo four;;      5) echo five;;
        6) echo six;;     7) echo seven;;     8) echo eight;;
        9) echo nine;;   10) echo ten;;      11) echo eleven;;
       12) echo twelve;; 13) echo thirteen;; 14) echo fourteen;;
       15) echo fifteen;; 16) echo sixteen;;
        *) echo "$1";;
    esac
}
LIB_WORD=$(num_word "$LIB_COUNT")
TOTAL_WORD=$(num_word "$TOTAL_FILES")

echo "Derived: $HOOK_COUNT hooks + $LIB_COUNT libs = $TOTAL_FILES files"
echo ""

# ── Group 0 — derivation sanity, asserted before anything depends on it ───
# Without this the suite can report GREEN on ~14 assertions: if $HOOKS ever
# resolves wrong, Group A runs zero iterations and Group C's `comm` on two
# empty inputs finds no difference, so every remaining check passes
# vacuously. A silent green here is worse than any red — it is precisely the
# "nobody re-checks the enumeration" failure this suite exists to kill, aimed
# at the suite itself. Hard-exit rather than continue into hollow passes.

if [ -n "$SOURCED" ]; then
    ok "derivation: hooks source at least one lib"
else
    bad "derivation: no lib references found in $HOOKS — path resolution broken"
fi

if [ "$LIB_COUNT" -ge 1 ] && [ "$HOOK_COUNT" -ge 1 ]; then
    ok "derivation: hooks/ and hooks/lib/ both enumerate non-empty"
else
    bad "derivation: HOOK_COUNT=$HOOK_COUNT LIB_COUNT=$LIB_COUNT — expected both >= 1"
fi

if [ "$FAIL" -ne 0 ]; then
    echo ""
    echo "Results: $PASS passed, $FAIL failed"
    echo "ABORTED: ground truth could not be derived; remaining assertions would pass vacuously."
    exit 1
fi


# ── Group A — every sourced lib appears on all four doc surfaces ──────────
# This is the assertion whose absence let the 4-of-6 install ship.

for lib in $SOURCED; do
    assert_grep "$G_INIT"   "| \`lib/$lib\` |" \
        "g-init Step 6 install table lists lib/$lib"
    assert_grep "$G_INIT"   ".claude/hooks/lib/$lib — installed" \
        "g-init Step 6 report block lists lib/$lib"
    assert_grep "$G_UPDATE" "| \`lib/$lib\` |" \
        "g-update realign table lists lib/$lib"
    assert_grep "$README"   ".claude/hooks/lib/$lib" \
        "README install list names lib/$lib"
done

# ── Group A2 — g-doctor must DERIVE, not enumerate ────────────────────────
# The inverse invariant. Check 16 iterating a written list is the failure mode
# that let the short install pass; re-introducing one must fail here.

if grep -qF 'ls [plugin-root]/hooks/lib/*.sh' "$G_DOCTOR"; then
    ok "g-doctor Check 16 enumerates hooks/lib/ from disk"
else
    bad "g-doctor Check 16 no longer derives its lib set from disk"
fi

# Lib basenames must not appear in Check 16's drift bullet. Scope the scan to
# that bullet — `semver-compare.sh` legitimately appears elsewhere in the skill
# (Check 23 sources it by name for version ordering), and flagging that would
# be a false positive.
DRIFT_BULLET=$(awk '/^- \*\*`hooks\/lib\/` drift/,/^- \*\*Sourced-but-uninstalled/' "$G_DOCTOR")
HARDCODED=""
for lib in $ONDISK; do
    printf '%s' "$DRIFT_BULLET" | grep -qF -- "$lib" && HARDCODED="$HARDCODED $lib"
done
if [ -z "$HARDCODED" ]; then
    ok "g-doctor Check 16 drift bullet carries no hardcoded lib list"
else
    bad "g-doctor Check 16 drift bullet hardcodes lib names:$HARDCODED"
fi

# ── Group B — reverse direction: nothing in the install list is a ghost ───
# Catches the opposite drift — a lib deleted from hooks/lib/ but left in the
# table, which makes /g-init stop on "plugin cache missing hook file".

for listed in $(grep -oE '\| `lib/[a-z0-9-]+\.sh`' "$G_INIT" | sed 's|.*lib/||; s|`||'); do
    if [ -f "$HOOKS/lib/$listed" ]; then
        ok "g-init table entry lib/$listed exists on disk"
    else
        bad "g-init table entry lib/$listed has no file in hooks/lib/"
    fi
done

# ── Group C — set parity: sourced == on disk ──────────────────────────────

MISSING=$(comm -23 <(printf '%s\n' "$SOURCED") <(printf '%s\n' "$ONDISK"))
if [ -z "$MISSING" ]; then
    ok "every sourced lib exists in hooks/lib/"
else
    bad "hooks source libs with no file: $(echo $MISSING)"
fi

ORPHAN=$(comm -13 <(printf '%s\n' "$SOURCED") <(printf '%s\n' "$ONDISK"))
if [ -z "$ORPHAN" ]; then
    ok "every lib in hooks/lib/ is sourced by at least one hook"
else
    bad "hooks/lib/ holds unsourced libs: $(echo $ORPHAN)"
fi

# ── Group D — count coherence across the doc surfaces ─────────────────────
# Every prose lib-count claim must equal the derived count. Scanning for the
# claim SHAPE rather than a fixed list of line numbers is deliberate: the
# 4-of-6 bug shipped partly because a known-stale README site was named in a
# retro and still missed by the fix list twice. A count site added later is
# caught without editing this test.
#
# Two claim shapes: digits ("7 hooks + 6 lib", "the 6 canonical lib scripts")
# and words ("six shared lib scripts", "six `lib/` files"). "seven event
# hooks plus six shared lib scripts" contributes only its `six`, because the
# pattern anchors on the word immediately preceding `lib`.

check_counts() {
    local file="$1" label="$2" bad_hits="" hits=0

    # Digit-form claims: <n> [canonical ]lib
    for n in $(grep -oE '[0-9]+ (canonical )?lib' "$file" | grep -oE '^[0-9]+'); do
        hits=$((hits+1))
        [ "$n" = "$LIB_COUNT" ] || bad_hits="$bad_hits digit:$n"
    done

    # Word-form claims: <word> [shared |`lib/` ]lib
    # The alternation must stay in lockstep with num_word's range, or a count
    # above the highest listed word silently stops being checked — drift by
    # the exact mechanism this suite exists to catch.
    for w in $(grep -oiE '(three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen) (shared )?(`?lib)' "$file" \
               | awk '{print tolower($1)}'); do
        hits=$((hits+1))
        [ "$w" = "$LIB_WORD" ] || bad_hits="$bad_hits word:$w"
    done

    # Report zero-claim files distinctly. g-doctor legitimately carries no lib
    # count (it derives — see Group A2), so a "claims all read 6" PASS there
    # would assert something that does not exist. Naming the absence keeps the
    # assertion honest. Note it is NOT a guard against a count coming back: a
    # re-added count changes this line's text but not its verdict, since a
    # correct count still passes. Group A2 pins the basenames and the `ls`
    # literal, not the presence of a count — nothing here goes red for it.
    if [ -n "$bad_hits" ]; then
        bad "$label has stale lib-count claims (expected $LIB_COUNT/$LIB_WORD):$bad_hits"
    elif [ "$hits" -eq 0 ]; then
        ok "$label carries no lib-count claim (derives instead)"
    else
        ok "$label lib-count claims ($hits) all read $LIB_COUNT/$LIB_WORD"
    fi
}

check_counts "$G_INIT"   "g-init"
check_counts "$G_UPDATE" "g-update"
check_counts "$G_DOCTOR" "g-doctor"
check_counts "$README"   "README"

# g-init states the COMBINED file count ("any of the thirteen files above") as
# the stop condition for a missing plugin-cache file. That number is hooks +
# libs, so it drifts when either side changes — a different claim from the
# per-surface lib counts above, and the reason TOTAL_WORD is derived at all.
assert_grep "$G_INIT" "the $TOTAL_WORD files above" \
    "g-init combined file count reads $TOTAL_FILES/$TOTAL_WORD ($HOOK_COUNT hooks + $LIB_COUNT libs)"

# ── Group E — commit-gate matcher pin (audit-7 H3) ─────────────────────────
# g-init's Step 7 settings.json template registers the commit gate on BOTH
# PreToolUse and PostToolUse with matcher "Bash|PowerShell" — losing the
# |PowerShell alternation on either entry silently drops the commit gate for
# every Windows consumer, since a Bash-only matcher never fires on a
# PowerShell tool call. Pinned by content/occurrence-count, not by line
# number, per ADR-013 — the template is free to move in the file, the string
# is not free to lose the alternation or drop to a single occurrence.
# Falsifiability: in a scratch copy of this file, strip "|PowerShell" from
# one of the two matcher lines and point MATCHER_COUNT's grep at the scratch
# copy — the count drops to 1 and this assertion goes red. Proven in a
# scratch copy; skills/g-init/SKILL.md itself is never touched.
MATCHER_COUNT=$(grep -oF '"matcher": "Bash|PowerShell"' "$G_INIT" | wc -l | tr -d ' ')
if [ "$MATCHER_COUNT" -eq 2 ]; then
    ok "g-init Step 7 template: PreToolUse and PostToolUse both carry matcher Bash|PowerShell"
else
    bad "g-init Step 7 template: expected 2 occurrences of \"matcher\": \"Bash|PowerShell\", found $MATCHER_COUNT"
fi

# ── Group F — hooks.json empty-manifest invariant (audit-7 H9) ────────────
# hooks/hooks.json's own description documents the double-registration bug
# class this guards: a non-empty "hooks" key here would register hooks
# GLOBALLY for every session on top of /g-init's per-project registration in
# .claude/settings.json, double-firing the commit gate. Pinned on the exact
# empty-object content, not on file size or key presence, so any accidental
# entry — however small — trips it.
# Falsifiability: in a scratch copy of hooks/hooks.json, replace "hooks": {}
# with a non-empty object (e.g. "hooks": {"PreToolUse": []}) and point this
# assertion at the scratch copy — it goes red. Proven in a scratch copy;
# hooks/hooks.json itself is never touched.
assert_grep "$HOOKS/hooks.json" '"hooks": {}' \
    "hooks/hooks.json hooks key stays an empty object (double-registration guard)"

# ── Group G — skill lib-dir install surface pins (F1-1 fix) ───────────────
# These pins verify that the four skills documenting the install process name
# the git-hooks-dir and hooks-dir lib/ directories explicitly, so the suite
# catches a revert or a silence of the lib-install step. Each is a presence-grep
# of the literal directory name the skill mentions, not a completeness claim
# about the install logic itself.

assert_grep "$G_INIT" "<git-hooks-dir>/lib/" \
    "g-init Step 6a names <git-hooks-dir>/lib/ install"
assert_grep "$G_UPDATE" "<hooks-dir>/lib/" \
    "g-update Step 7a names <hooks-dir>/lib/ install"
assert_grep "$G_DOCTOR" "<hooks-dir>/lib/*.sh" \
    "g-doctor Check 16 names <hooks-dir>/lib/*.sh drift check"
assert_grep "$REPO/skills/g-review/SKILL.md" "<git-hooks-dir>/lib/" \
    "g-review Step 1 names <git-hooks-dir>/lib/ drift check"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

#!/bin/bash
# Contract guard for the telemetry subsystem fixes of 2026-08-28, raised by the
# adopter field report at g-docs/field-reports/2026-08-28-g-sharp-telemetry.md.
#
# Two defects are pinned here. Both are prose contracts across three files that
# have to agree; nothing about them is unit-testable at runtime, so what we pin
# is the agreement itself, derived from disk on BOTH sides wherever possible so
# an edit to either side fails the assertion (ADR-013 rule 2).
#
#   §2  The review-holds latch. The counter had an unconditional increment, no
#       decrement, and a single clearing path (/g-telemetry resetting it on a
#       `stable` profile) that its own growth made unreachable. Measured on this
#       repo 2026-08-29: fix_after_feat 7 + review_holds 34 = 41 over 30 feat
#       commits = a 137% rework rate against a 20% threshold. Pinned: the reset
#       is gone from both writers, /g-review owns
#       increment AND decrement, and exactly one skill writes the counter.
#
#   §1c The measurement vacuum. Five of eight metrics grep retro prose for
#       tokens /g-retro has never emitted, and a run filled them in by reading
#       the prose instead of reporting n/a. Pinned: the never-interpret rule,
#       the raised computable floor agreeing between spec and skill, and the
#       heading level the spec greps for matching the one /g-retro ships.
#
# Total assertions: 23
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line — the
# finding-#20 cross-check that catches a suite silently dropping cases.
#
# falsifiability: guards neutered in scratch copy, test confirmed red — 2026-08-29
# Five neuters against five of the guard assertions below, all confirmed RED against a GREEN
# baseline on the same copy. Probe output is in the pass record (plan Task 23 row).
# Not among the five: the single-owner count check ("exactly one skill declares
# ownership") — a plain `-eq 1` on a grep count, not a suppression or early exit.
# The first probe run FAILED THREE OF THESE GUARDS OPEN — they stayed green under
# neutering because two piped through a shell function invisible inside `bash -c`,
# and one used a `[^.]` class that could not cross the dot in `.claude/review-holds`.
# Both bugs are fixed below and re-probed. Re-prove and re-date this marker if a
# guard, a bound, or an assertion changes: a stale marker is worse than none.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok() { # name  test-cmd...
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "PASS: $name"; PASS=$((PASS+1));
    else echo "FAIL: $name"; FAIL=$((FAIL+1)); fi
}
no() { # name  test-cmd... (asserts the grep does NOT match)
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "FAIL: $name"; FAIL=$((FAIL+1));
    else echo "PASS: $name"; PASS=$((PASS+1)); fi
}

SPEC="$ROOT/g-docs/telemetry-metrics.md"
TELE="$ROOT/skills/g-telemetry/SKILL.md"
REVIEW="$ROOT/skills/g-review/SKILL.md"
RETRO="$ROOT/skills/g-retro/SKILL.md"

# --- files exist at the paths the contract names -------------------------

ok  "spec file exists at the path /g-telemetry calls authoritative" test -f "$SPEC"
ok  "g-telemetry skill exists"                                      test -f "$TELE"
ok  "g-review skill exists"                                         test -f "$REVIEW"
ok  "g-retro skill exists"                                          test -f "$RETRO"

# --- §2: the latch is dismantled -----------------------------------------
# The live-instruction greps below are scoped to lines that are NOT struck
# through or parenthesised history: the retirement notes deliberately quote the
# old policy, so a bare absence-grep would fail on the very text that records
# the fix. `^\*\(Retired` / `~~` / `Previous policy` mark those.

# NOTE: these filters are inlined, never factored into a shell function. A
# function defined here is not visible inside `bash -c`, so the inner command
# would die with "command not found", the grep would see no input, and an
# absence-assertion would record PASS on that failure — green forever, testing
# nothing. The 2026-08-29 falsifiability probe caught exactly that here.

no  "spec: no live instruction tying the counter reset to a stable profile" \
    bash -c 'grep -v "~~" "$0" | grep -v "^\*(Retired" | grep -v "Previous policy" | grep -qiE "reset to .0. (whenever|when) .{0,60}stable"' "$SPEC"
no  "g-telemetry: no live instruction to reset the counter on stable" \
    bash -c 'grep -v "~~" "$0" | grep -v "^\*(Retired" | grep -qiE "reset .{0,40}review-holds"' "$TELE"
ok  "g-telemetry states it never writes the counter" \
    grep -qi 'Never write .*review-holds' "$TELE"
ok  "spec: counter is defined as currently-unresolved, not a lifetime total" \
    grep -qi 'currently-unresolved' "$SPEC"
ok  "spec: counter policy names /g-review as the decrementing owner" \
    grep -qi 'decrement' "$SPEC"

ok  "g-review still increments on a HOLD verdict" \
    grep -qi 'increment .*review-holds. by 1' "$REVIEW"
ok  "g-review decrements when a prior HOLD is closed" \
    grep -qi 'decrement by 1 per closed HOLD round' "$REVIEW"
ok  "g-review floors the decrement at zero" \
    grep -qi 'floored at 0' "$REVIEW"
ok  "g-review gates the decrement on Step 4b closure evidence" \
    grep -qi 'unevidenced closure claim is not a closure' "$REVIEW"

# Single-writer invariant, derived from disk: exactly one shipped skill may
# declare ownership of the counter, and it must be /g-review. This is the
# assertion that catches a future skill quietly acquiring a second write path —
# the shape the original defect took, where /g-telemetry held a reset.
ok  "exactly one skill declares ownership of the counter" \
    bash -c '
      n=0
      for f in "$0"/skills/*/SKILL.md; do
        grep -qi "owns both sides of it" "$f" && n=$((n+1))
      done
      [ "$n" -eq 1 ]' "$ROOT"
ok  "the declared owner is /g-review" \
    grep -qi 'owns both sides of it' "$REVIEW"
# No skill other than the owner may carry a live write verb aimed at the file.
ok  "no non-owner skill carries a live write instruction for review-holds" \
    bash -c '
      for f in "$0"/skills/*/SKILL.md; do
        case "$f" in *g-review*) continue ;; esac
        # Drop struck-through history, retirement notes, and explicit
        # disclaimers ("Never write ...") before looking for a live write verb.
        if grep -v "~~" "$f" | grep -v "^\*(Retired" | grep -vi "Never write" \
           | grep -qiE "(write|reset|increment|decrement).{0,60}review-holds"; then
          exit 1
        fi
      done
      exit 0' "$ROOT"

# --- §1c: the measurement vacuum -----------------------------------------

ok  "g-telemetry forbids substituting a semantic reading for a literal match" \
    grep -qi 'never fill the gap by reading' "$TELE"
ok  "g-telemetry names the measurement-vacuum condition" \
    grep -qi 'measurement vacuum' "$TELE"
ok  "spec names the measurement-vacuum condition too" \
    grep -qi 'measurement vacuum' "$SPEC"

# The computable floor is stated in both files and they must agree. Both sides
# are read from disk and compared to each other — not to a number typed here —
# so raising the floor in one file without the other fails this assertion.
ok  "computable floor agrees between spec and g-telemetry skill" \
    bash -c '
      s=$(grep -oE "computable < [0-9]+" "$0" | head -1 | grep -oE "[0-9]+")
      t=$(grep -oE "computable < [0-9]+" "$1" | head -1 | grep -oE "[0-9]+")
      [ -n "$s" ] && [ -n "$t" ] && [ "$s" = "$t" ]' "$SPEC" "$TELE"

# The heading /g-retro actually ships must be one the spec says it will read.
# Both sides derived from disk: change the template's level, or narrow the
# spec's stated pattern, and this fails.
ok  "spec reads the Avoid-heading at the level /g-retro actually ships" \
    bash -c '
      lvl=$(grep -oE "^#{2,4} Avoid / do differently" "$1" | head -1 | grep -oE "^#+")
      [ -n "$lvl" ] || exit 1
      case "$lvl" in
        "##")  grep -qE "\`## \`" "$0" ;;
        "###") grep -qE "\`### \`" "$0" ;;
        *) exit 1 ;;
      esac' "$SPEC" "$RETRO"

ok  "spec records why five retro-sourced metrics read n/a today" \
    grep -qi 'never wired to a shared vocabulary' "$SPEC"
ok  "the field report that raised both defects is committed alongside the fix" \
    test -f "$ROOT/g-docs/field-reports/2026-08-28-g-sharp-telemetry.md"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

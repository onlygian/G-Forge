#!/bin/bash
# phase-gate.sh — deterministic implementation of /g-patterns Step 1
# (pending-resolution routing).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. READ-ONLY: on self-heal it computes the archive target and the
# MODEL performs the rename, preserving the human-visible decision trail.
# The same-session guard CANNOT live here — it tests in-context knowledge
# ("this session just mined") no script can see — and stays in the
# SKILL.md core.
#
# Status census is a CLOSED SET (matched by prefix, tolerating trailing
# annotations any prior SKILL version may have written, e.g.
# "APPLIED — refined an existing rule", "RESOLVED — no longer applicable",
# "WITHDRAWN — external counter-report received YYYY-MM-DD"). An unknown
# status string surfaces as a NOTE and is treated as UNRESOLVED — never
# bucketed as resolved, so it can never misroute to MINE while the
# single-open-report invariant is at stake.
#
# Output contract:
#   REPORT: absent|open
#   PENDING: N
#   STATUS_CENSUS: pending=N deferred=N dismissed=N applied=N resolved=N withdrawn=N dash=N
#       (printed only when the report is open)
#   NOTE: <text>              0+ human-readable notes
#   ROUTE: mine|resolve|self-heal
#   ARCHIVE_TARGET: g-docs/patterns/YYYY-MM-DD[-k].md
#       self-heal only — today's date, first free numeric suffix on
#       collision (-2, -3, … in NUMERIC order, not lexicographic)
set -u
LC_ALL=C

REPORT=g-docs/patterns/latest.md
if [ ! -f "$REPORT" ]; then
    echo "REPORT: absent"
    echo "PENDING: 0"
    echo "ROUTE: mine"
    exit 0
fi
echo "REPORT: open"

pending=0; deferred=0; dismissed=0; applied=0; resolved=0; withdrawn=0; dash=0; unknown=0
while IFS= read -r st; do
    case "$st" in
        PENDING*)   pending=$((pending+1)) ;;
        DEFERRED*)  deferred=$((deferred+1)) ;;
        DISMISSED*) dismissed=$((dismissed+1)) ;;
        APPLIED*)   applied=$((applied+1)) ;;
        RESOLVED*)  resolved=$((resolved+1)) ;;
        WITHDRAWN*) withdrawn=$((withdrawn+1)) ;;
        —*|-*)      dash=$((dash+1)) ;;
        *)          unknown=$((unknown+1))
                    echo "NOTE: unknown status '$st' — treated as unresolved" ;;
    esac
done < <(sed -n 's/.*\*\*Status:\*\* *//p' "$REPORT" | sed 's/[ \t]*$//')

echo "PENDING: $pending"
echo "STATUS_CENSUS: pending=$pending deferred=$deferred dismissed=$dismissed applied=$applied resolved=$resolved withdrawn=$withdrawn dash=$dash"

if [ $((pending + unknown)) -gt 0 ]; then
    echo "ROUTE: resolve"
else
    echo "ROUTE: self-heal"
    TODAY=$(date +%Y-%m-%d)
    TARGET="g-docs/patterns/$TODAY.md"
    if [ -e "$TARGET" ]; then
        k=2
        while [ -e "g-docs/patterns/$TODAY-$k.md" ]; do k=$((k+1)); done
        TARGET="g-docs/patterns/$TODAY-$k.md"
    fi
    echo "ARCHIVE_TARGET: $TARGET"
fi
exit 0

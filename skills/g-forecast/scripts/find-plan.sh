#!/bin/bash
# find-plan.sh — deterministic implementation of /g-forecast Step 1
# (target-plan resolution).
#
# Run from the project root: find-plan.sh [slug-or-path]
# Prints KEY: value lines for the skill to interpret; always exits 0 —
# every outcome is in the output, never the exit code.
# The case ORDER is contractual: skills/g-plan/SKILL.md Step 3b hands a
# not-yet-approved plan over via g-docs/plans/.pending-forecast.md and
# relies on "/g-forecast Step 1 case 1" picking it up first, always.
#
# Output contract:
#   PLAN: <path>          the resolved plan file
#   SLUG: <slug>          filename-derived (cases 2/3); case 1 prints
#                         "(derive from plan title)" — the handoff file is
#                         .pending-forecast.md and carries no slug of its
#                         own, so the skill derives one from the plan title
#   SOURCE: pending-handoff|argument|most-recent-pending
#   EXIT: no-plan         nothing resolved — the skill prints its stop block
set -u
LC_ALL=C

ARG="${1:-}"

# Case 1 — explicit pending-plan handoff from /g-plan Step 3a.
if [ -f g-docs/plans/.pending-forecast.md ]; then
    echo "PLAN: g-docs/plans/.pending-forecast.md"
    echo "SLUG: (derive from plan title)"
    echo "SOURCE: pending-handoff"
    exit 0
fi

# Case 2 — developer-passed slug or path.
if [ -n "$ARG" ]; then
    if [ -f "g-docs/plans/$ARG.md" ]; then
        echo "PLAN: g-docs/plans/$ARG.md"
        echo "SLUG: $ARG"
        echo "SOURCE: argument"
        exit 0
    fi
    case "$ARG" in
        *.md)
            if [ -f "$ARG" ]; then
                base=$(basename "$ARG")
                echo "PLAN: $ARG"
                echo "SLUG: ${base%.md}"
                echo "SOURCE: argument"
                exit 0
            fi ;;
    esac
fi

# Case 3 — most recently modified g-docs/plans/*.md whose Progress table
# has a pending wave: a table row carrying "pending" (case-insensitive)
# INSIDE the '## Progress' section only — "pending" in any other table
# (e.g. a task row's "pending review" note) never selects a plan. Section
# parsing mirrors skills/g-execute/scripts/locate-plan.sh.
OLDIFS=$IFS
IFS='
'
for f in $(ls -t g-docs/plans/*.md 2>/dev/null); do
    if awk 'BEGIN { p = 0 }
            /^## Progress/ { p = 1; next }
            /^## /         { p = 0 }
            p && /^\|/ && tolower($0) ~ /pending/ { found = 1; exit }
            END { exit found ? 0 : 1 }' "$f" 2>/dev/null; then
        IFS=$OLDIFS
        base=$(basename "$f")
        echo "PLAN: $f"
        echo "SLUG: ${base%.md}"
        echo "SOURCE: most-recent-pending"
        exit 0
    fi
done
IFS=$OLDIFS

echo "EXIT: no-plan"
exit 0

#!/bin/bash
# prep-dispatch.sh — deterministic implementation of /g-plan Step 2/3 output_file
# minting (g-docs/agent-output/ convention).
#
# Usage: prep-dispatch.sh <request-slug-or-short-description>
# Run from the project root. Prints KEY: value lines for the skill to interpret;
# always exits 0 — every outcome is in the output, never the exit code.
#
# Slugify convention (the same one /g-plan Step 4a uses for the saved plan
# filename, and g-review / g-doc-review cite as "same slugify convention /g-plan
# uses"): lowercase, every run of non-alphanumerics collapsed to one hyphen,
# leading/trailing hyphens trimmed.
#
# Output contract:
#   TD_FILE: g-docs/agent-output/g-plan/task-decomposer-YYYY-MM-DD-<slug>.md
#   WP_FILE: g-docs/agent-output/g-plan/wave-planner-YYYY-MM-DD-<slug>.md
#   DELETED: <path>       one line per stale same-path file removed (a same-day
#                         retry reusing the slug must never inherit stale output)
#   NOTE: <text>          0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

RAW="${1:-}"
SLUG=$(printf '%s' "$RAW" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//')
if [ -z "$SLUG" ]; then
    SLUG=request
    out "NOTE: empty request-slug — defaulted to 'request'; pass a short description of what is being planned"
fi

DATE=$(date +%Y-%m-%d)
DIR=g-docs/agent-output/g-plan
mkdir -p "$DIR" 2>/dev/null || out "NOTE: could not create $DIR — check permissions"

TD="$DIR/task-decomposer-$DATE-$SLUG.md"
WP="$DIR/wave-planner-$DATE-$SLUG.md"
for f in "$TD" "$WP"; do
    if [ -f "$f" ]; then
        rm -f "$f" 2>/dev/null && out "DELETED: $f"
    fi
done

out "TD_FILE: $TD"
out "WP_FILE: $WP"
exit 0

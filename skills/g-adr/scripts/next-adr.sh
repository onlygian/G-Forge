#!/bin/bash
# next-adr.sh [title] — deterministic implementation of /g-adr Step 5
# (next ADR number + filename derivation).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. ADR numbers are permanent, so determinism here is a quality
# gain: a wrong NEXT would mint a colliding ADR.
#
# Output contract:
#   DIR: g-docs/decisions
#   DIR_STATE: exists|created
#   LAST: <highest-numbered file basename|none>
#   NEXT: NNN                zero-padded to 3 digits; 001 when none exist
#   FILENAME: NNN-<kebab-title>.md
#                            printed only when a title argument was given
#   NOTE: <text>             0+ anomaly notes (e.g. non-numeric filenames)
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

out "DIR: g-docs/decisions"
if [ -d g-docs/decisions ]; then
    out "DIR_STATE: exists"
else
    mkdir -p g-docs/decisions
    out "DIR_STATE: created"
fi

# Find scoped exactly as the prose it replaces: */g-docs/decisions/*.md,
# excluding node_modules.
MAX=0
LAST=none
while IFS= read -r f; do
    b=$(basename "$f")
    n=$(printf '%s' "$b" | sed -n 's/^0*\([0-9][0-9]*\)-.*/\1/p')
    if [ -z "$n" ]; then
        out "NOTE: non-numeric or legacy filename ignored: $b"
        continue
    fi
    if [ "$n" -gt "$MAX" ] 2>/dev/null; then
        MAX=$n
        LAST=$b
    fi
done <<GF_EOF
$(find . -path "*/g-docs/decisions/*.md" -not -path "*/node_modules/*" 2>/dev/null | sort)
GF_EOF

out "LAST: $LAST"
NEXT=$(printf '%03d' $((MAX + 1)))
out "NEXT: $NEXT"

TITLE="${1:-}"
if [ -n "$TITLE" ]; then
    KEBAB=$(printf '%s' "$TITLE" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
    out "FILENAME: $NEXT-$KEBAB.md"
fi
exit 0

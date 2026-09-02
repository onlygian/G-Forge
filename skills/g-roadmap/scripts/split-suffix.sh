#!/bin/bash
# split-suffix.sh <parent-id> — split-lineage suffix computation for /g-roadmap
# Step 3.
#
# Greps the parent milestone/plan ID for a `-split[0-9]+` marker (deliberately
# NOT end-anchored: /g-plan Step 3c greps the identical pattern, so
# M47-split1-auth still reads depth 1). Prints KEY: value lines; always exits
# 0 — every outcome is in the output, never the exit code.
# /g-roadmap is the only writer of the -split<N> convention; /g-plan Step 3c
# reads it back — keep both surfaces on this exact pattern.
#
# Output contract:
#   PARENT: <id>                     the parent ID as given
#   DEPTH: <n>                       0 when the ID carries no -split marker
#   SUFFIX: -split<n+1>              apply to every sub-milestone ID: appended
#                                    when the parent carries no -split marker;
#                                    an existing -split<N> marker is replaced
#                                    by this, never appended after it
#   NOTE: <text>                     0+ lines; no argument → "no parent id
#                                    given" + SUFFIX: -split1; DEPTH > 0 →
#                                    replace-the-marker reminder line
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

if [ $# -lt 1 ] || [ -z "${1:-}" ]; then
    out "NOTE: no parent id given"
    out "SUFFIX: -split1"
    exit 0
fi

PARENT="$1"
out "PARENT: $PARENT"

MARKER=$(printf '%s\n' "$PARENT" | grep -o -- '-split[0-9]\+' | head -n1)
if [ -n "$MARKER" ]; then
    DEPTH=${MARKER#-split}
else
    DEPTH=0
fi
out "DEPTH: $DEPTH"
out "SUFFIX: -split$((DEPTH + 1))"
if [ "$DEPTH" -gt 0 ]; then
    out "NOTE: parent carries -split$DEPTH — replace that marker with SUFFIX, never append after it"
fi

exit 0

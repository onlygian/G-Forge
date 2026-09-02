#!/bin/bash
# locate-plan.sh — deterministic implementation of /g-execute Steps 1-2
# (plan location order + starting-wave rules 1-4).
#
# Usage: locate-plan.sh [argument]
#   argument = a plan file path (use it) · a wave number (start there, no
#   confirmation) · empty (newest g-docs/plans/*.md by mtime — dotfiles like
#   .pending-forecast.md skipped with a NOTE — else g-docs/todo.md if it holds
#   a wave schedule section).
# Run from the project root. Prints KEY: value lines; always exits 0.
#
# Progress statuses are the closed set pending / in progress / complete
# (Plan File Format — skills/g-plan/references/plan-formats.md).
#
# Output contract:
#   PLAN: <path>                     the located plan file
#   WAVE: N <status>                 one line per '## Progress' table row
#   then exactly one of:
#     START_WAVE: N  +  CONFIRM: yes|no    (yes only when a wave is marked
#                                           'in progress' — rule 3)
#     ALL_COMPLETE: yes  + NOTE: All waves already complete. Run /g-review.
#     EXIT: no-plan  + NOTE: No plan file found. Run /g-plan first, or pass the plan file path as an argument.
#   NOTE: <text>                     0+ additional notes (resume announce, skips)
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

ARG="${1:-}"
FORCED_WAVE=""
PLAN=""

case "$ARG" in
    '') : ;;
    *[!0-9]*) PLAN="$ARG" ;;   # non-numeric → treat as a file path
    *) FORCED_WAVE="$ARG" ;;   # numeric → starting wave; locate plan by default order
esac

if [ -n "$PLAN" ] && [ ! -f "$PLAN" ]; then
    out "NOTE: argument '$PLAN' is not a readable file — falling back to the default location order"
    PLAN=""
fi

if [ -z "$PLAN" ]; then
    for f in $(ls -1t g-docs/plans/*.md 2>/dev/null); do
        case "${f##*/}" in
            .*) out "NOTE: skipped dotfile ${f} (temporary handoff, not an executable plan)" ;;
            *) PLAN="$f"; break ;;
        esac
    done
fi
# ls glob above misses dotfiles by default, but guard explicitly anyway:
if [ -z "$PLAN" ] && [ -f g-docs/plans/.pending-forecast.md ]; then
    out "NOTE: skipped dotfile g-docs/plans/.pending-forecast.md (temporary handoff, not an executable plan)"
fi
if [ -z "$PLAN" ] && [ -f g-docs/todo.md ] && grep -qE '^#{2,3} .*Wave|^### Wave [0-9]' g-docs/todo.md; then
    PLAN="g-docs/todo.md"
fi
if [ -z "$PLAN" ]; then
    out "EXIT: no-plan"
    out "NOTE: No plan file found. Run /g-plan first, or pass the plan file path as an argument."
    exit 0
fi
out "PLAN: $PLAN"

# ── Parse the '## Progress' table ────────────────────────────────────────────
in_prog=0
ROWS=""       # "N:status" per line
while IFS= read -r line; do
    case "$line" in
        '## Progress'*) in_prog=1; continue ;;
        '## '*) in_prog=0 ;;
    esac
    [ "$in_prog" = 1 ] || continue
    case "$line" in \|*) : ;; *) continue ;; esac
    n=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}')
    case "$n" in ''|*[!0-9]*) continue ;; esac
    s=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}')
    out "WAVE: $n $s"
    ROWS="$ROWS$n:$s
"
done < "$PLAN"

if [ -n "$FORCED_WAVE" ]; then
    out "START_WAVE: $FORCED_WAVE"
    out "CONFIRM: no"
    exit 0
fi

# Rule 1 — table absent or all rows pending
if [ -z "$ROWS" ] || ! printf '%s' "$ROWS" | grep -qvE ':pending$'; then
    out "START_WAVE: 1"
    out "CONFIRM: no"
    exit 0
fi
# Rule 2 — all complete
if ! printf '%s' "$ROWS" | grep -qvE ':complete$'; then
    out "ALL_COMPLETE: yes"
    out "NOTE: All waves already complete. Run /g-review."
    exit 0
fi
# Rule 3 — a wave marked 'in progress' (confirm with the developer)
IP=$(printf '%s' "$ROWS" | grep -E ':in progress$' | head -n 1 | cut -d: -f1)
if [ -n "$IP" ]; then
    out "START_WAVE: $IP"
    out "CONFIRM: yes"
    exit 0
fi
# Rule 4 — mix of complete and pending: first non-complete row
FIRST=$(printf '%s' "$ROWS" | grep -vE ':complete$' | head -n 1 | cut -d: -f1)
[ -z "$FIRST" ] && FIRST=1
out "START_WAVE: $FIRST"
out "CONFIRM: no"
out "NOTE: Resuming from Wave $FIRST (Wave 1–$((FIRST - 1)) complete)."
exit 0

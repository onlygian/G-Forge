#!/bin/bash
# derive-owns.sh — deterministic {{OWNS_GLOBS}} derivation for /g-specialize
# Step 6 (stack-implementer install). /g-update Step 5 re-derives an installed
# implementer's owns: globs with this same script — one owner for the
# layer-map → glob conversion.
#
# Usage: derive-owns.sh <rules-file>
#   <rules-file> is a profile architecture-rules file
#   (profiles/<stack>/rules/architecture.md or an installed copy).
#
# Reads the `**Layer map:**` bullet section and converts EVERY backtick-quoted
# path in each bullet's layer-path segment — the text before the ` — `
# description separator (backticks after the dash are description code, not
# paths). Bullets may list alternate or paired paths ("`utils/` or
# `apps/common/`", "`ios/` and `android/`") — each becomes its own glob:
#   path ending in `/` (a directory)   → "<path>**"   (src/components/ → src/components/**)
#   path with a <placeholder> segment  → each <…> replaced with *
#                                        (apps/<feature>/views.py → apps/*/views.py)
#   a concrete file path               → kept verbatim (src/state.rs)
#
# Output contract (KEY: value lines; always exit 0):
#   OWNS: "<glob>"   one per extracted path, in file order — paste each value
#                    as one YAML list item
#   OWNS: none       no **Layer map:** section or no extractable paths — the
#                    caller must remove the entire owns: key from the rendered
#                    implementer (wave-planner falls back to stack-label routing)
#   NOTE: <text>     0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

f="${1:-}"
if [ -z "$f" ] || [ ! -f "$f" ]; then
    out "NOTE: rules file not found: ${f:-<no argument>}"
    out "OWNS: none"
    exit 0
fi

found=0
in_map=0
while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_map" -eq 0 ]; then
        case "$line" in
            *"**Layer map:**"*) in_map=1 ;;
        esac
        continue
    fi
    case "$line" in
        "- "*|"  - "*|"* "*)
            # layer-path segment: everything before the first " — " separator
            # (whole line when a bullet has no description dash)
            seg="${line%% — *}"
            paths=$(printf '%s\n' "$seg" | grep -o '`[^`][^`]*`' | sed 's/^`//; s/`$//')
            [ -n "$paths" ] || continue
            while IFS= read -r path; do
                glob=$(printf '%s\n' "$path" | sed 's/<[^>]*>/*/g')
                case "$glob" in
                    */) glob="${glob}**" ;;
                esac
                out "OWNS: \"$glob\""
                found=1
            done <<PATHS_EOF
$paths
PATHS_EOF
            ;;
        ""|" ")
            # blank line: tolerated before the first bullet, ends the section after
            [ "$found" -eq 1 ] && break
            ;;
        *)
            break
            ;;
    esac
done < "$f"

[ "$found" -eq 1 ] || out "OWNS: none"
exit 0

#!/bin/bash
# validate-waves.sh — deterministic implementation of /g-plan Step 3d Checks 1-2
# (same-wave file conflicts, missing source files for mutation tasks).
#
# Usage: validate-waves.sh <plan-file>       (Plan File Format — see
#        ../references/plan-formats.md; normally g-docs/plans/.pending-forecast.md)
# Run from the project root (file-existence checks are relative to it).
# Prints KEY: value and finding lines; always exits 0.
#
# Check 3 (cross-wave output dependency ordering) is model judgment and stays in
# the SKILL.md core — its '⚠ Ordering risk —' findings are warnings the skill
# adds on top of this output.
#
# Parsing: Tasks table rows under '## Tasks' ('| # | task | scope | done |');
# wave membership from '### Wave N' sections' '- Task N — ...' lines. Scope
# cells are split on commas; path-like tokens (containing '/' or '.') are
# checked, and so is a bare extensionless token that exists on disk (Makefile,
# LICENSE). Multi-word prose scopes ("auth module") are skipped; a bare
# extensionless token NOT on disk is indistinguishable from prose, so it is
# skipped from Checks 1-2 but marked with a NOTE.
# Closed verb sets (byte-identical to the prose they replace):
#   mutation: update modify extend refactor fix edit change
#   creation: create generate scaffold add write init
#
# Output contract:
#   ⚠ Parallel write conflict — Wave [N]: [Task A] and [Task B] both scope [file]
#   ✗ Missing source — [task name]: [file] does not exist and no prior wave creates it
#   ✓ No parallel write conflicts                       (Check 1 clean)
#   ✓ All source files present (or creation-ordered)    (Check 2 clean)
#   BLOCKERS: N     Check 1 + Check 2 finding count — blockers halt the plan
#   WARNINGS: N     always 0 here — Check 3 warnings come from the skill
#   NOTE: <text>    0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

PLAN="${1:-}"
if [ -z "$PLAN" ] || [ ! -f "$PLAN" ]; then
    out "NOTE: plan file missing ('$PLAN') — nothing validated; write the draft plan first"
    out "BLOCKERS: 0"
    out "WARNINGS: 0"
    exit 0
fi

declare -A TNAME TSCOPE WAVE_OF

# ── Parse the Tasks table (scoped to the '## Tasks' section) ─────────────────
in_tasks=0
while IFS= read -r line; do
    case "$line" in
        '## Tasks'*) in_tasks=1; continue ;;
        '## '*) in_tasks=0 ;;
    esac
    [ "$in_tasks" = 1 ] || continue
    case "$line" in
        \|*) : ;;
        *) continue ;;
    esac
    num=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}')
    case "$num" in ''|*[!0-9]*) continue ;; esac
    TNAME[$num]=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}')
    TSCOPE[$num]=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$4); print $4}')
done < "$PLAN"

# ── Parse wave membership ('### Wave N' → '- Task N — …') ────────────────────
wave=""
while IFS= read -r line; do
    case "$line" in
        '### Wave '*)
            wave=${line#\#\#\# Wave }
            wave=${wave%%[!0-9]*}
            ;;
        '- Task '*)
            [ -n "$wave" ] || continue
            num=${line#- Task }
            num=${num%%[!0-9]*}
            case "$num" in ''|*[!0-9]*) continue ;; esac
            WAVE_OF[$num]=$wave
            ;;
    esac
done < "$PLAN"

if [ ${#TNAME[@]} -eq 0 ]; then
    out "NOTE: no Tasks-table rows parsed — check the plan follows the Plan File Format"
fi
if [ ${#WAVE_OF[@]} -eq 0 ]; then
    out "NOTE: no wave schedule parsed ('### Wave N' + '- Task N —' lines) — flat task lists have nothing to cross-check"
fi

# path-like scope tokens for task $1, one per line
tokens_of() {
    printf '%s\n' "${TSCOPE[$1]:-}" | tr ',' '\n' | while IFS= read -r t; do
        t=$(printf '%s' "$t" | sed -e 's/^[ \t`]*//' -e 's/[ \t`]*$//')
        [ -n "$t" ] || continue
        case "$t" in
            *' '*) continue ;;      # prose, not a path
            *...*) continue ;;      # placeholder
            */*|*.*) printf '%s\n' "$t" ;;
            *) [ -e "$t" ] && printf '%s\n' "$t" ;;   # bare extensionless file (Makefile)
        esac
    done
}

# ── Bare extensionless tokens not on disk: skipped, but never silently ───────
SKIPPED=$(for n in "${!TNAME[@]}"; do
    printf '%s\n' "${TSCOPE[$n]:-}" | tr ',' '\n' | while IFS= read -r t; do
        t=$(printf '%s' "$t" | sed -e 's/^[ \t`]*//' -e 's/[ \t`]*$//')
        [ -n "$t" ] || continue
        case "$t" in ''|*' '*|*...*|*/*|*.*) continue ;; esac
        [ -e "$t" ] || printf '%s\n' "$t"
    done
done | sort -u)
if [ -n "$SKIPPED" ]; then
    while IFS= read -r t; do
        out "NOTE: scope token '$t' has no '/' or '.' and is not on disk — treated as prose, skipped by Checks 1-2 (verify by hand if it names a file)"
    done <<<"$SKIPPED"
fi

CONFLICTS=0
MISSING=0

# ── Check 1 — same-wave file conflicts ───────────────────────────────────────
waves=$(printf '%s\n' "${WAVE_OF[@]}" 2>/dev/null | sort -nu)
for w in $waves; do
    members=""
    for n in "${!WAVE_OF[@]}"; do
        [ "${WAVE_OF[$n]}" = "$w" ] && members="$members
$n"
    done
    members=$(printf '%s\n' "$members" | grep -v '^$' | sort -n)
    set -- $members
    while [ $# -ge 2 ]; do
        a=$1; shift
        for b in "$@"; do
            common=$(comm -12 <(tokens_of "$a" | sort -u) <(tokens_of "$b" | sort -u))
            for f in $common; do
                out "⚠ Parallel write conflict — Wave $w: ${TNAME[$a]:-Task $a} and ${TNAME[$b]:-Task $b} both scope $f"
                CONFLICTS=$((CONFLICTS + 1))
            done
        done
    done
done

# ── Check 2 — missing source files for mutation tasks ────────────────────────
for n in "${!TNAME[@]}"; do
    printf '%s' "${TNAME[$n]}" | grep -qiE '\b(update|modify|extend|refactor|fix|edit|change)\b' || continue
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        [ -e "$f" ] && continue
        created=0
        tw=${WAVE_OF[$n]:-}
        for m in "${!TNAME[@]}"; do
            mw=${WAVE_OF[$m]:-}
            [ -n "$tw" ] && [ -n "$mw" ] && [ "$mw" -lt "$tw" ] || continue
            printf '%s' "${TNAME[$m]}" | grep -qiE '\b(create|generate|scaffold|add|write|init)\b' || continue
            if tokens_of "$m" | grep -qxF "$f"; then created=1; break; fi
        done
        if [ "$created" = 0 ]; then
            out "✗ Missing source — ${TNAME[$n]}: $f does not exist and no prior wave creates it"
            MISSING=$((MISSING + 1))
        fi
    done < <(tokens_of "$n")
done

[ "$CONFLICTS" -eq 0 ] && out "✓ No parallel write conflicts"
[ "$MISSING" -eq 0 ] && out "✓ All source files present (or creation-ordered)"
out "BLOCKERS: $((CONFLICTS + MISSING))"
out "WARNINGS: 0"
out "NOTE: Check 3 (cross-wave output references) is model judgment — run it and count its ⚠ Ordering risk findings as warnings"
exit 0

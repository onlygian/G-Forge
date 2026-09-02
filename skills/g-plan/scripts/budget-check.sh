#!/bin/bash
# budget-check.sh — deterministic implementation of /g-plan Step 3c (context
# budget check): estimate, remaining budget, verdict, split target, split depth.
#
# Usage: budget-check.sh --waves N --agents N --tasks N [--id <identifier>]
#                        [--session <session-id>]
#   --waves   wave count from the Step 3 wave schedule
#   --agents  total agent slots across all waves (same schedule)
#   --tasks   final Tasks-table row count (Step 2's list as amended by 2a/2b)
#   --id      milestone ID or plan slug for the split-depth check; omit/empty
#             for an ad-hoc run (depth 0 by definition)
#   --session current session id when the caller knows it (the hooks key the
#             prompt counter by it); omit/empty when not knowable
# Run from the project root. Prints KEY: value lines; always exits 0.
#
# Coefficient basis, worked examples, and the re-derivation duty live in
# ../references/budget-derivation.md — read it before changing any constant
# here. Formula: estimated = 5 + waves*3 + agents*2 + tasks*1 + tasks*4
# (base / per-wave / per-agent / per-task / per-task review chain).
#
# Threshold cross-ref (one-owner note, do not re-tune here): RED = 45 - offset,
# floored at 25, mirrors hooks/workflow-checkpoint.sh BASE_RED/FLOOR_RED in
# implementation mode — once a plan is executing the session is implementation
# mode. A future hook re-tune must update this pair too.
#
# Governing .claude/ resolved per ADR-005 local-else-primary (owning statement:
# skills/g-plan/SKILL.md ## Rules, ADR-005 bullet) — same cascade as
# skills/g-resume/scripts/sync-check.sh. Depth prefers the current session's
# keyed session-prompt-count.<id> when --session is given (primary branch —
# never borrowing another session's counter when that keyed file is missing or
# unreadable, mirroring sync-check.sh's conservative handling); only when the
# session id is not knowable does it fall back to the most-recently-modified
# session-prompt-count* match: an mtime pick is allowed HERE because this use is
# read-only (g-resume's sync gate must not mtime-pick; the asymmetry is
# documented in skills/g-resume/SKILL.md).
#
# Output contract:
#   ESTIMATED: N              five-term estimate in exchanges
#   DEPTH: C                  current prompt depth (0 when no counter readable)
#   RED: R                    derived red threshold (45 - offset, floor 25)
#   REMAINING: M              R - C
#   VERDICT: fine|tight|exceeded   fine: est <= M*1.0 · tight: M*1.0 < est <= M*2.0
#                                  · exceeded: est > M*2.0
#   SPLIT_TARGET: floor(M*0.8)     sub-milestone sizing target for /g-roadmap
#   SPLIT_DEPTH: N            N from the last -split<N> suffix in --id (not
#                             end-anchored); 0 when no match or no --id
#   PASS_REPORTS: N           pass-report markers counted in g-docs/todo-done.md
#                             (0 when the file is missing)
#   NEW_PASS_REPORTS: N       pass reports beyond the baseline the per-task
#                             review coefficient was derived against; >= 3 means
#                             the coefficient is stale — the caller must load
#                             ../references/budget-derivation.md and follow its
#                             re-derivation duty before trusting ESTIMATED
#   NOTE: <text>              0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }
NOTES=""
note() { NOTES="${NOTES}NOTE: $*
"; }

WAVES="" AGENTS="" TASKS="" ID="" SESSION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --waves)   WAVES="${2:-}"   ;;
        --agents)  AGENTS="${2:-}"  ;;
        --tasks)   TASKS="${2:-}"   ;;
        --id)      ID="${2:-}"      ;;
        --session) SESSION="${2:-}" ;;
        *) note "unrecognized argument '$1' — ignored"; shift; continue ;;
    esac
    if [ $# -ge 2 ]; then shift 2; else shift; fi
done

case "$WAVES"  in ''|*[!0-9]*) note "--waves is not a number ('$WAVES') — treated as 0";   WAVES=0  ;; esac
case "$AGENTS" in ''|*[!0-9]*) note "--agents is not a number ('$AGENTS') — treated as 0"; AGENTS=0 ;; esac
case "$TASKS"  in ''|*[!0-9]*) note "--tasks is not a number ('$TASKS') — treated as 0";   TASKS=0  ;; esac

ESTIMATED=$((5 + WAVES * 3 + AGENTS * 2 + TASKS * 1 + TASKS * 4))

# ── Governing .claude/ — ADR-005 local-else-primary cascade ──────────────────
CDIR=""
if [ -d .claude ]; then CDIR=.claude
else
    COMMON=$(git rev-parse --git-common-dir 2>/dev/null)
    case "$COMMON" in
        "") : ;;
        /*) [ -d "$(dirname "$COMMON")/.claude" ] && CDIR="$(dirname "$COMMON")/.claude" ;;
        *)  [ -d "$(dirname "$PWD/$COMMON")/.claude" ] && CDIR="$(dirname "$PWD/$COMMON")/.claude" ;;
    esac
fi
[ -z "$CDIR" ] && note "no governing .claude/ directory found — depth and offset default to 0"

# ── Depth: current session's keyed counter first (primary branch); otherwise
#    most-recently-modified session-prompt-count* (read-only mtime fallback) ──
DEPTH=""
if [ -n "$CDIR" ]; then
    if [ -n "$SESSION" ]; then
        KEYED="$CDIR/session-prompt-count.$SESSION"
        if [ -f "$KEYED" ]; then
            DEPTH=$(cat "$KEYED" 2>/dev/null)
            case "$DEPTH" in
                ''|*[!0-9]*) DEPTH=""; note "prompt counter ${KEYED##*/} unreadable or non-numeric" ;;
            esac
        else
            note "no counter for session '$SESSION' — never borrowing another session's counter (mtime fallback is for an unknown session id only)"
        fi
    else
        NEWEST=$(ls -1t "$CDIR"/session-prompt-count* 2>/dev/null | head -n 1)
        if [ -n "$NEWEST" ] && [ -f "$NEWEST" ]; then
            DEPTH=$(cat "$NEWEST" 2>/dev/null)
            case "$DEPTH" in
                ''|*[!0-9]*) DEPTH=""; note "prompt counter ${NEWEST##*/} unreadable or non-numeric" ;;
            esac
        fi
    fi
fi
if [ -z "$DEPTH" ]; then
    DEPTH=0
    note "no readable prompt counter — depth treated as 0 (remaining = full red threshold; real remaining may be lower)"
fi

# ── Red threshold: 45 - offset, floored at 25 (implementation mode) ──────────
OFFSET=0
if [ -n "$CDIR" ] && [ -f "$CDIR/context-threshold-offset" ]; then
    V=$(cat "$CDIR/context-threshold-offset" 2>/dev/null)
    case "$V" in
        ''|*[!0-9]*) note "context-threshold-offset non-numeric — treated as 0" ;;
        *) OFFSET=$V ;;
    esac
fi
RED=$((45 - OFFSET))
[ "$RED" -lt 25 ] && RED=25
REMAINING=$((RED - DEPTH))
[ "$REMAINING" -le 0 ] && note "remaining budget is zero or negative — the session is already at or past red"

# ── Verdict bands: 1.0 / 2.0 ─────────────────────────────────────────────────
if [ "$ESTIMATED" -le "$REMAINING" ]; then VERDICT=fine
elif [ "$ESTIMATED" -le $((REMAINING * 2)) ]; then VERDICT=tight
else VERDICT=exceeded
fi

# ── Split target: floor(M * 0.8) ─────────────────────────────────────────────
ST=$((REMAINING * 8))
if [ "$ST" -ge 0 ]; then ST=$((ST / 10)); else ST=$(( (ST - 9) / 10 )); fi

# ── Split depth: last -split<N> suffix in the identifier (not end-anchored) ──
SPLIT_DEPTH=0
if [ -n "$ID" ]; then
    M=$(printf '%s\n' "$ID" | grep -oE -- '-split[0-9]+' | tail -n 1)
    [ -n "$M" ] && SPLIT_DEPTH=${M#-split}
fi

# ── Coefficient staleness: pass reports beyond the derivation's cited records ─
# BASELINE_PASS_REPORTS is the total count of pass-report markers in
# g-docs/todo-done.md as of the round the per-task-review coefficient (4) was
# last derived/carried (the two cited records live among them). Update it
# together with the coefficient constant above and the citations in
# ../references/budget-derivation.md — never alone.
BASELINE_PASS_REPORTS=4
PR_COUNT=0
if [ -f g-docs/todo-done.md ]; then
    PR_COUNT=$(grep -cE '^(\*\*Pass report|## Pass report)' g-docs/todo-done.md)
fi
NEW_PR=$((PR_COUNT - BASELINE_PASS_REPORTS))
[ "$NEW_PR" -lt 0 ] && NEW_PR=0
[ "$NEW_PR" -ge 3 ] && note "3+ pass reports newer than the coefficient's cited records — load references/budget-derivation.md and follow its re-derivation duty before trusting ESTIMATED"

out "ESTIMATED: $ESTIMATED"
out "DEPTH: $DEPTH"
out "RED: $RED"
out "REMAINING: $REMAINING"
out "VERDICT: $VERDICT"
out "SPLIT_TARGET: $ST"
out "SPLIT_DEPTH: $SPLIT_DEPTH"
out "PASS_REPORTS: $PR_COUNT"
out "NEW_PASS_REPORTS: $NEW_PR"
[ -n "$NOTES" ] && printf '%s' "$NOTES"
exit 0

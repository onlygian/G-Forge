#!/bin/bash
# G-Forge workflow checkpoint — UserPromptSubmit hook.
# Outputs current workflow state so Claude can auto-trigger the right step.

# Consume stdin payload — UserPromptSubmit delivers tool_input JSON here.
# We don't use it, but reading it prevents broken-pipe edge cases on some shells.
if [ ! -t 0 ]; then
    _STDIN_PAYLOAD=$(cat - 2>/dev/null || true)
    : "${_STDIN_PAYLOAD:=}"
fi

# G-Forge project guard — act only inside a G-Forge-managed project (one that ran
# /g-init, which writes .claude/integration-tier). Keeps the checkpoint inert
# everywhere else, so it never prints in a non-G-Forge project and so multiple
# registration sources never cause it to misfire.
[ -f ".claude/integration-tier" ] || exit 0

# Helper: emit a non-negative integer, defaulting to 0 on empty / non-numeric input.
to_int() {
    local v
    v=$(printf '%s' "$1" | tr -d '[:space:]')
    case "$v" in
        ''|*[!0-9]*) printf '0' ;;
        *) printf '%s' "$v" ;;
    esac
}

# Integration tier — `full` (default) emits everything; `balanced` skips the
# auto-trigger advisory; `light` emits only Branch + Tier.
TIER="full"
if [ -f ".claude/integration-tier" ]; then
    _t=$(tr -d '[:space:]' < .claude/integration-tier 2>/dev/null)
    case "$_t" in
        full|balanced|light) TIER="$_t" ;;
    esac
fi

ACTIVE_CONTEXT=""
if [ -f "g-docs/ROADMAP.md" ]; then
    ACTIVE_CONTEXT=$(grep -m1 'Active context:' g-docs/ROADMAP.md | sed 's/.*Active context:[[:space:]]*//')
fi

REVIEW_APPROVED=false
[ -f ".claude/g-forge-approved" ] && REVIEW_APPROVED=true

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

echo "[G-Forge Workflow Checkpoint]"
echo "  Branch: $CURRENT_BRANCH"

# Light tier — minimal output, then exit.
if [ "$TIER" = "light" ]; then
    echo "  Tier:   light — manual mode; commit gate off"
    exit 0
fi

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo "  ⚠  on main — non-trivial work should be on a feature branch (feat/<slug>, fix/<slug>)" >&2
fi
if [ -n "$ACTIVE_CONTEXT" ]; then
    echo "  Active: $ACTIVE_CONTEXT"
else
    echo "  Active: none"
fi
if [ "$REVIEW_APPROVED" = true ]; then
    echo "  Review: approved (commit gate open)"
else
    echo "  Review: not yet approved — run /g-review before merging"
fi

# Roundtable heartbeat (M33) — when a Roundtable is bound (.claude/roundtable present), nudge a
# boundary read/write. The null adapter (no .claude/roundtable) keeps this silent, so
# the no-Roundtable path is byte-identical to before. The light tier already exited
# above, so the heartbeat is off there too.
if [ -f ".claude/roundtable" ]; then
    _table_title=$(sed -n 's/^title=//p' .claude/roundtable 2>/dev/null | head -1)
    echo "  🪑 Roundtable bound${_table_title:+: $_table_title} — /g-roundtable sync at this boundary (read deltas, write only salient state)"
fi

if [ -f ".claude/tier3-active" ]; then
    ITEM_COUNT=$(cat ".claude/tier3-active" 2>/dev/null || echo 0)
    echo "  Listen mode ACTIVE — ${ITEM_COUNT} item(s) logged — no action until user says done"
fi

# Context depth counter — increments each prompt; thresholds vary by session mode.
# Reset to 0 by session-start.sh on a genuinely new session (startup/resume/clear);
# preserved across a `compact` SessionStart so it keeps climbing toward the gate.
PROMPT_COUNT_FILE=".claude/session-prompt-count"
PROMPT_COUNT=0
if [ -f "$PROMPT_COUNT_FILE" ]; then
    PROMPT_COUNT=$(cat "$PROMPT_COUNT_FILE" 2>/dev/null | tr -d '[:space:]')
    case "$PROMPT_COUNT" in ''|*[!0-9]*) PROMPT_COUNT=0 ;; esac
fi
PROMPT_COUNT=$((PROMPT_COUNT + 1))
printf '%d\n' "$PROMPT_COUNT" > "$PROMPT_COUNT_FILE" 2>/dev/null || true

# Detect session mode: implementation sessions burn context faster (tool calls,
# code reads, agent dispatches) than conversation/planning sessions.
# Signals: recent commits, dirty working tree, active plan file.
SESSION_MODE="conversation"
_recent=$(git log --oneline --since="4 hours ago" 2>/dev/null | wc -l | tr -d '[:space:]')
_dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d '[:space:]')
_plans=$(ls g-docs/plans/*.md 2>/dev/null | wc -l | tr -d '[:space:]')
case "$_recent" in ''|*[!0-9]*) _recent=0 ;; esac
case "$_dirty"  in ''|*[!0-9]*) _dirty=0  ;; esac
case "$_plans"  in ''|*[!0-9]*) _plans=0  ;; esac
if [ "$_recent" -gt 0 ] || [ "$_dirty" -gt 3 ] || [ "$_plans" -gt 0 ]; then
    SESSION_MODE="implementation"
fi

# Baseline thresholds — start LENIENT (the /context capacity floor at amber is the
# real guard, so we don't need to nag early). Auto-calibration tightens them per
# project: every compaction adds to .claude/context-threshold-offset, which is
# subtracted from these baselines (floored), so the gate fires earlier next time
# until compaction stops happening. Goal: prevent compaction, not react to it.
BASE_AMBER=45
BASE_RED=65
FLOOR_AMBER=20
FLOOR_RED=30
if [ "$SESSION_MODE" = "implementation" ]; then
    BASE_AMBER=30
    BASE_RED=45
    FLOOR_AMBER=15
    FLOOR_RED=25
fi

# Persistent calibration offset (never reset; grows with each compaction).
OFFSET=0
if [ -f ".claude/context-threshold-offset" ]; then
    OFFSET=$(to_int "$(cat .claude/context-threshold-offset 2>/dev/null)")
fi

AMBER_THRESHOLD=$((BASE_AMBER - OFFSET))
RED_THRESHOLD=$((BASE_RED - OFFSET))
[ "$AMBER_THRESHOLD" -lt "$FLOOR_AMBER" ] && AMBER_THRESHOLD=$FLOOR_AMBER
[ "$RED_THRESHOLD" -lt "$FLOOR_RED" ] && RED_THRESHOLD=$FLOOR_RED

# Capacity floor (% remaining): at amber the model polls /context every turn and
# resets the MOMENT remaining capacity drops below this — capacity-driven, before
# the window ever fills enough to compact. This, not the exchange count, is what
# actually prevents compaction; the count only decides when to start polling.
CAP_FLOOR_PCT=25

if [ "$PROMPT_COUNT" -ge "$RED_THRESHOLD" ]; then
    echo "  🔴 Context depth: ~${PROMPT_COUNT} exchanges [${SESSION_MODE}], threshold ${RED_THRESHOLD} — ENFORCED: finish task in flight, auto-trigger /g-retro, tell user to start fresh session NOW (do not let the window reach compaction)"
elif [ "$PROMPT_COUNT" -ge "$AMBER_THRESHOLD" ]; then
    echo "  🟡 Context depth: ~${PROMPT_COUNT} exchanges [${SESSION_MODE}], threshold ${AMBER_THRESHOLD} — ACTIVE MONITORING: run /context THIS turn and every turn from now; the moment remaining capacity drops below ${CAP_FLOOR_PCT}%, reset immediately (finish in-flight work, /g-retro, fresh session) — do not wait for the red exchange count. Goal: reset before compaction, never after."
fi

# Compaction escalation — auto-compaction is the strongest "context overloaded"
# signal there is, and the prompt counter alone misses it: the post-compaction
# SessionStart used to reset that counter, so a session could compact repeatedly
# without ever tripping the red gate above. pre-compact.sh now counts compactions
# (carried across the compact SessionStart by session-start.sh); surface the §A7
# reset directly off that count. Even one auto-compaction means the window is full.
COMPACTION_COUNT=0
if [ -f ".claude/session-compaction-count" ]; then
    COMPACTION_COUNT=$(to_int "$(cat .claude/session-compaction-count 2>/dev/null)")
fi
if [ "$COMPACTION_COUNT" -ge 1 ]; then
    echo "  🔴 Context compacted ${COMPACTION_COUNT}× this session — the window is overloaded; finish in-flight work, auto-trigger /g-retro, then start a fresh session (run /g-resume to re-hydrate)"
fi

# Milestone health — rework commits, blockers, review holds since main.
# Patterns kept in sync with /g-patterns Step 2c rework signals.
REWORK_COUNT=0
BLOCKED_COUNT=0
HOLD_COUNT=0
if git rev-parse --verify main >/dev/null 2>&1 && [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    _rework_raw=$(git log --oneline main..HEAD 2>/dev/null \
        | grep -ciE '(^[a-f0-9]+[[:space:]]+)?(revert:|^[a-f0-9]+[[:space:]]+revert "|fix-of-fix|take 2|retry|another attempt|re-do)' 2>/dev/null)
    REWORK_COUNT=$(to_int "$_rework_raw")
fi
if [ -f "g-docs/todo.md" ]; then
    _blocked_raw=$(grep -cE 'BLOCKED' g-docs/todo.md 2>/dev/null)
    BLOCKED_COUNT=$(to_int "$_blocked_raw")
fi
if [ -f ".claude/review-holds" ]; then
    _holds_raw=$(cat .claude/review-holds 2>/dev/null)
    HOLD_COUNT=$(to_int "$_holds_raw")
fi

if [ "$REWORK_COUNT" -eq 0 ] && [ "$BLOCKED_COUNT" -eq 0 ] && [ "$HOLD_COUNT" -eq 0 ]; then
    echo "  Health: ✓ clean"
else
    HEALTH_PARTS=""
    [ "$REWORK_COUNT" -gt 0 ] && HEALTH_PARTS="${HEALTH_PARTS}${REWORK_COUNT} rework · "
    [ "$BLOCKED_COUNT" -gt 0 ] && HEALTH_PARTS="${HEALTH_PARTS}${BLOCKED_COUNT} blocked · "
    [ "$HOLD_COUNT" -gt 0 ] && HEALTH_PARTS="${HEALTH_PARTS}${HOLD_COUNT} holds · "
    HEALTH_PARTS=${HEALTH_PARTS%· }
    echo "  Health: ⚠ ${HEALTH_PARTS}"
fi

# Tier line — surfaces the integration tier so the LLM knows whether
# auto-triggers are permitted (only on `full`). `light` already exited above.
if [ "$TIER" = "balanced" ]; then
    echo "  Tier:   balanced — no auto-triggers; invoke skills manually"
else
    echo "  Tier:   full"
fi

# Agent coverage nudge — surface one never-used agent suggestion, once per day.
# Populated by /g-telemetry Step 5b. Cycles through never-used agents one per day.
COVERAGE_FILE=".claude/telemetry-coverage"
NUDGE_STAMP=".claude/coverage-nudge-stamp"
NUDGE_INDEX=".claude/coverage-nudge-index"

if [ -f "$COVERAGE_FILE" ]; then
    NEEDS_NUDGE=true
    if [ -f "$NUDGE_STAMP" ] && find "$NUDGE_STAMP" -mmin -1440 2>/dev/null | grep -q .; then
        NEEDS_NUDGE=false
    fi

    if [ "$NEEDS_NUDGE" = true ]; then
        NEVER_LINE=$(grep '^never:' "$COVERAGE_FILE" 2>/dev/null | sed 's/^never://')
        if [ -n "$NEVER_LINE" ]; then
            # Build array of never-used agents and rotate through them by index
            NEVER_AGENTS=$(printf '%s' "$NEVER_LINE" | tr ',' '\n' | sed 's/^[[:space:]]*//' | grep -v '^$')
            AGENT_COUNT=$(printf '%s\n' "$NEVER_AGENTS" | wc -l | tr -d '[:space:]')
            IDX=0
            [ -f "$NUDGE_INDEX" ] && IDX=$(cat "$NUDGE_INDEX" 2>/dev/null | tr -d '[:space:]')
            case "$IDX" in ''|*[!0-9]*) IDX=0 ;; esac
            IDX=$((IDX % AGENT_COUNT))
            AGENT=$(printf '%s\n' "$NEVER_AGENTS" | sed -n "$((IDX + 1))p" | tr -d '[:space:]')
            if [ -n "$AGENT" ]; then
                echo "  💡 $AGENT has never been used in this project — dispatch it directly or see the Playbook"
                printf '%d\n' "$((IDX + 1))" > "$NUDGE_INDEX"
                touch "$NUDGE_STAMP"
            fi
        fi
    fi
fi

# Weekly g-trim nudge — prompt once after 7 days since last optimization pass.
TRIM_STAMP=".claude/last-trim"
NEEDS_TRIM=true
if [ -f "$TRIM_STAMP" ] && find "$TRIM_STAMP" -mmin -10080 2>/dev/null | grep -q .; then
    NEEDS_TRIM=false
fi
if [ "$NEEDS_TRIM" = true ]; then
    echo "  📋 Weekly optimization due — run /g-trim to compact CLAUDE.md and agent memory"
fi

# Session re-entry nudge — on the FIRST prompt of a session, if a handoff is
# pending (ROADMAP ## Active Session or a PreCompact snapshot), nudge /g-resume to
# re-hydrate the clean window with the right slice of the durable record.
# This is the read-side counterpart to the /g-retro reset; it's what makes
# "start a fresh session" cheap.
if [ "$PROMPT_COUNT" -eq 1 ]; then
    _has_handoff=false
    [ -f ".claude/compact-state.md" ] && _has_handoff=true
    if [ "$_has_handoff" = false ] && [ -f "g-docs/ROADMAP.md" ] && grep -q '## Active Session' g-docs/ROADMAP.md 2>/dev/null; then
        _has_handoff=true
    fi
    if [ "$_has_handoff" = true ]; then
        if grep -qi 'verify ADR' g-docs/ROADMAP.md .claude/compact-state.md 2>/dev/null; then
            echo "  🔄 Fresh session, pending handoff — run /g-resume to re-hydrate; a handed-off ADR needs verifying first"
        else
            echo "  🔄 Fresh session, pending handoff — run /g-resume to re-hydrate context before new work"
        fi
    fi
fi

# Between-milestone alignment nudge — /g-align runs automatically at milestone
# close; this nudges a drift check between closes once 7 days have elapsed.
# Only meaningful when there's a brief to align against and a roadmap to drift.
if [ -f "g-docs/project_brief.md" ] && [ -f "g-docs/ROADMAP.md" ]; then
    ALIGN_STAMP=".claude/last-align"
    NEEDS_ALIGN=true
    if [ -f "$ALIGN_STAMP" ] && find "$ALIGN_STAMP" -mmin -10080 2>/dev/null | grep -q .; then
        NEEDS_ALIGN=false
    fi
    if [ "$NEEDS_ALIGN" = true ]; then
        echo "  🎯 Brief-alignment check due — run /g-align to confirm progress still serves g-docs/project_brief.md"
    fi
fi

# Self-update check — background curl once per day, zero blocking latency
CLAUDE_DIR="$HOME/.claude"
INSTALLED_MANIFEST="$CLAUDE_DIR/plugins/cache/g-forge/g-forge/.claude-plugin/plugin.json"
VERSION_CACHE="$CLAUDE_DIR/g-forge-latest-version"
CHECK_STAMP="$CLAUDE_DIR/g-forge-check-stamp"

if [ -f "$INSTALLED_MANIFEST" ]; then
    INSTALLED_VER=$(grep '"version"' "$INSTALLED_MANIFEST" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?[a-zA-Z0-9]*' | head -1)

    NEEDS_CHECK=true
    if [ -f "$CHECK_STAMP" ] && find "$CHECK_STAMP" -mmin -1440 2>/dev/null | grep -q .; then
        NEEDS_CHECK=false
    fi

    if [ "$NEEDS_CHECK" = true ]; then
        (curl -sf --max-time 5 \
          "https://raw.githubusercontent.com/onlygian/G-Forge/main/.claude-plugin/plugin.json" \
          | grep '"version"' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?[a-zA-Z0-9]*' | head -1 \
          > "$VERSION_CACHE" && touch "$CHECK_STAMP") >/dev/null 2>&1 &
    fi

    if [ -f "$VERSION_CACHE" ]; then
        LATEST_VER=$(cat "$VERSION_CACHE")
        if [ -n "$LATEST_VER" ] && [ "$LATEST_VER" != "$INSTALLED_VER" ]; then
            echo "  ⚡ g-forge update available: $INSTALLED_VER → $LATEST_VER — run /g-update to pull and sync"
        fi
    fi
fi

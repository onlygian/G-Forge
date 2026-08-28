#!/bin/bash
# G-Forge workflow checkpoint — UserPromptSubmit hook.
# Outputs current workflow state so Claude can auto-trigger the right step.

# Sources shared lib helpers so this hook's project guard and review-sentinel
# read agree with the ADR-004/005 commit gate (hooks/check-commit.sh,
# hooks/pre-commit) on how to find the governing .claude/, instead of
# drifting apart across two hand-edited implementations (M-audit finding
# #21 / BUG-2 pattern). Resolved relative to this script's own location so
# the installed copy (.claude/hooks/workflow-checkpoint.sh, with libs under
# .claude/hooks/lib/) finds its libs the same way the repo source
# (hooks/workflow-checkpoint.sh, hooks/lib/) does.
_GF_HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/worktree-resolve.sh
. "$_GF_HOOK_DIR/lib/worktree-resolve.sh"
# shellcheck source=lib/sentinel-read.sh
. "$_GF_HOOK_DIR/lib/sentinel-read.sh"
# shellcheck source=lib/stdin-read.sh
[ -f "$_GF_HOOK_DIR/lib/stdin-read.sh" ] && . "$_GF_HOOK_DIR/lib/stdin-read.sh"
# shellcheck source=lib/semver-compare.sh
[ -f "$_GF_HOOK_DIR/lib/semver-compare.sh" ] && . "$_GF_HOOK_DIR/lib/semver-compare.sh"
# Define-once fallback (observe.sh idiom). Without it a missing/unsourceable lib
# makes the call below fail with `command not found` BEFORE stdin is drained —
# the `: "${_STDIN_PAYLOAD:=}"` default runs after the failure, so it cannot
# substitute for the read it was documented as protecting. The body mirrors
# lib/stdin-read.sh's `read -t -d ''` mechanism rather than a bare `cat`: the
# missing-lib path is exactly the broken-install population this guard is for,
# and an unbounded fallback there would trade a noisy failure for the
# 66-minute orphaned-hook hang that lib was written to prevent.
if ! command -v gf_read_stdin_timeout >/dev/null 2>&1; then
    gf_read_stdin_timeout() {
        local t="${1:-5}" p=""
        IFS= read -r -t "$t" -d '' p || true
        printf '%s' "$p"
        return 0
    }
fi

# Consume stdin payload — UserPromptSubmit delivers tool_input JSON here. We
# don't use it, but reading it prevents broken-pipe edge cases on some
# shells. Moved below lib-sourcing so it can use the bounded
# hooks/lib/stdin-read.sh helper instead of a bare blocking `cat`.
if [ ! -t 0 ]; then
    _STDIN_PAYLOAD=$(gf_read_stdin_timeout 5)
    : "${_STDIN_PAYLOAD:=}"
fi

# G-Forge project guard — act only inside a G-Forge-managed project (one that ran
# /g-init, which writes .claude/integration-tier). Keeps the checkpoint inert
# everywhere else, so it never prints in a non-G-Forge project and so multiple
# registration sources never cause it to misfire.
#
# ADR-005 — worktree primary-state resolution: a linked git worktree has no
# local .claude/ of its own (gitignored, so it's simply absent in a fresh
# worktree). Before treating that as "not a G-Forge project", try resolving
# the PRIMARY working tree's .claude/ via the shared lib
# (hooks/lib/worktree-resolve.sh) and use it if the primary is itself a
# gated project — a worktree of a gated project inherits the checkpoint
# instead of silently staying inert. GF_CLAUDE_DIR is the resolved base for
# every .claude/ read below (tier + the review sentinel); it defaults to the
# local "." tree, which keeps the primary-tree / non-worktree path
# byte-identical to before this change. This hook is NON-GATING — it never
# blocks anything — so any resolution failure or ambiguity exits 0 silently
# instead of escalating (contrast hooks/check-commit.sh, which denies on
# ambiguity for a confirmed commit — there is nothing analogous to deny
# here). gf_guard_claude_dir() (hooks/lib/worktree-resolve.sh) is the
# single shared implementation of this local-.claude-else-resolved-primary
# decision every non-gating hook in this repo needs (ADR-005).
GF_CLAUDE_DIR=$(gf_guard_claude_dir) || exit 0

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
# auto-trigger advisory; `light` emits only Branch + Tier. _t is kept (not
# just TIER) so the § Tier line display below can tell "file absent/empty,
# defaulted to full" apart from "file holds an unrecognized value, defaulted
# to full" and surface the latter distinctly instead of silently collapsing it.
TIER="full"
_t=""
if [ -f "$GF_CLAUDE_DIR/integration-tier" ]; then
    _t=$(tr -d '[:space:]' < "$GF_CLAUDE_DIR/integration-tier" 2>/dev/null)
    case "$_t" in
        full|balanced|light) TIER="$_t" ;;
    esac
fi

ACTIVE_CONTEXT=""
if [ -f "g-docs/ROADMAP.md" ]; then
    # Anchored to line start: a greedy `.*` strip removes through the LAST
    # occurrence of the label on the line, so prose repeating the label served
    # garbage on every prompt (retros 2026-07-23, 2026-07-26, 2026-08-15).
    ACTIVE_CONTEXT=$(grep -m1 '^Active context:' g-docs/ROADMAP.md | sed 's/^Active context:[[:space:]]*//')
fi

# Review sentinel — resolved under the same GF_CLAUDE_DIR as the project
# guard above (ADR-005), so a linked worktree's "Review:" line reflects the
# primary tree's sentinel instead of reporting "not yet approved" merely
# because it has no local .claude/ of its own.
#
# The gate (hooks/pre-commit, ADR-004/005) binds each sentinel to the exact
# worktree it was reviewed in via a `commit_sentinel_worktree=<toplevel>`
# field, because GF_CLAUDE_DIR can resolve to a primary .claude/ SHARED by
# every worktree of this repo — a sentinel written by /g-review in one tree
# would otherwise read as "approved" in a sibling tree it never reviewed.
# Mirror that per-worktree binding here (not the tree/HEAD staleness check
# the gate also performs — this line is advisory status, not enforcement)
# so the reported status is true for the CURRENT worktree, matching the
# gate's own scheme.
REVIEW_APPROVED=false
_gf_sentinel="$GF_CLAUDE_DIR/g-forge-approved"
if [ -f "$_gf_sentinel" ]; then
    _gf_sentinel_line=$(cat -- "$_gf_sentinel" 2>/dev/null)
    case "$_gf_sentinel_line" in
        *commit_sentinel_worktree=*)
            if gf_parse_stamp "$_gf_sentinel"; then
                _gf_sentinel_worktree="$STAMP_WORKTREE"
                _gf_current_worktree=$(gf_worktree_key)
                # Empty current-worktree resolution means gf_worktree_key()
                # itself failed (not a git failure this hook can meaningfully
                # gate on — it's advisory only): fall back to the pre-ADR-004
                # existence signal rather than under-report.
                if [ -z "$_gf_current_worktree" ] || [ "$_gf_sentinel_worktree" = "$_gf_current_worktree" ]; then
                    REVIEW_APPROVED=true
                fi
            else
                # Line matched the new-format marker (contains
                # commit_sentinel_worktree=) but gf_parse_stamp rejected it
                # because commit_sentinel_ts or commit_sentinel_head is
                # missing — a malformed partial stamp that should never
                # occur from /g-review itself (which always writes all
                # three fields), only from a hand-edited/corrupted file.
                # hooks/lib/sentinel-read.sh is this repo's single reader
                # of the stamp format (tests/test-sentinel-read.sh
                # invariant (c)), so re-adding an inline fallback
                # extraction here to preserve the pre-extraction behavior
                # (worktree-compare even on a partial stamp) is out of
                # scope — see g-docs/agent-output/wave-w15d/extraction.md
                # for the quantified delta. Fall back to the legacy/
                # presence-only branch's outcome instead: this hook is
                # advisory-only (never blocks a commit; hooks/pre-commit's
                # gf_validate_sentinel still requires all three fields for
                # the real gate), so the only effect is a possibly-optimistic
                # status line on this specific malformed-input edge case.
                REVIEW_APPROVED=true
            fi
            ;;
        *)
            # No worktree field — a bare/legacy sentinel (pre-ADR-004 format
            # or a hand-created fixture). Not worktree-bound either way, so
            # presence alone is the same signal it always was: keeps the
            # primary-tree / non-worktree path byte-identical to before.
            REVIEW_APPROVED=true
            ;;
    esac
fi

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
    echo "  · Roundtable bound${_table_title:+: $_table_title} — /g-roundtable sync at this boundary (read deltas, write only salient state)"
fi

if [ -f ".claude/tier3-active" ]; then
    ITEM_COUNT=$(cat ".claude/tier3-active" 2>/dev/null || echo 0)
    echo "  Listen mode ACTIVE — ${ITEM_COUNT} item(s) logged — no action until user says done"
fi

# Context depth counter — increments each prompt; thresholds vary by session mode.
# Reset to 0 by session-start.sh on a genuinely new session (startup/clear);
# preserved across `compact`/`resume` SessionStarts so it keeps climbing toward
# the gate (same session continuing either way — see hooks/session-start.sh).
#
# Session identity — keyed the same way session-start.sh keys its reset
# (M-audit W3 task 14): this hook's own UserPromptSubmit payload carries the
# same stable session_id for the session's whole lifetime, so increments here
# land in the exact per-session file session-start.sh resets/preserves —
# never a concurrent session's counter on the same project. No session_id in
# the payload falls back to the legacy bare filename (graceful degrade,
# identical to pre-fix single-session behavior).
SESSION_ID=$(printf '%s' "${_STDIN_PAYLOAD:-}" \
    | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[a-zA-Z0-9_-]+"' | head -1 \
    | grep -oE '"[a-zA-Z0-9_-]+"$' | tr -d '"')
PROMPT_COUNT_FILE="$GF_CLAUDE_DIR/session-prompt-count"
[ -n "$SESSION_ID" ] && PROMPT_COUNT_FILE="$GF_CLAUDE_DIR/session-prompt-count.$SESSION_ID"
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
if [ -f "$GF_CLAUDE_DIR/context-threshold-offset" ]; then
    OFFSET=$(to_int "$(cat "$GF_CLAUDE_DIR/context-threshold-offset" 2>/dev/null)")
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
    echo "  !! Context depth: ~${PROMPT_COUNT} exchanges [${SESSION_MODE}], threshold ${RED_THRESHOLD} — ENFORCED: finish task in flight, auto-trigger /g-retro, tell user to start fresh session NOW (do not let the window reach compaction)"
elif [ "$PROMPT_COUNT" -ge "$AMBER_THRESHOLD" ]; then
    echo "  ⚠ Context depth: ~${PROMPT_COUNT} exchanges [${SESSION_MODE}], threshold ${AMBER_THRESHOLD} — ACTIVE MONITORING: run /context THIS turn and every turn from now; the moment remaining capacity drops below ${CAP_FLOOR_PCT}%, reset immediately (finish in-flight work, /g-retro, fresh session) — do not wait for the red exchange count. Goal: reset before compaction, never after."
fi

# Compaction escalation — auto-compaction is the strongest "context overloaded"
# signal there is, and the prompt counter alone misses it: the post-compaction
# SessionStart used to reset that counter, so a session could compact repeatedly
# without ever tripping the red gate above. pre-compact.sh now counts compactions
# (carried across the compact SessionStart by session-start.sh); surface the §A7
# reset directly off that count. Even one auto-compaction means the window is full.
COMPACTION_COUNT=0
if [ -f "$GF_CLAUDE_DIR/session-compaction-count" ]; then
    COMPACTION_COUNT=$(to_int "$(cat "$GF_CLAUDE_DIR/session-compaction-count" 2>/dev/null)")
fi
if [ "$COMPACTION_COUNT" -ge 1 ]; then
    echo "  !! Context compacted ${COMPACTION_COUNT}× this session — the window is overloaded; finish in-flight work, auto-trigger /g-retro, then start a fresh session (run /g-resume to re-hydrate)"
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
# A garbage/corrupted tier file (non-empty, unrecognized) still defaults TIER
# to "full" above — but must surface that distinctly here rather than reading
# identically to a clean, deliberate "full" (missing/empty file, or the
# literal value "full", both keep the plain line below unchanged).
if [ "$TIER" = "balanced" ]; then
    echo "  Tier:   balanced — no auto-triggers; invoke skills manually"
elif [ -n "$_t" ] && [ "$_t" != "full" ] && [ "$_t" != "balanced" ] && [ "$_t" != "light" ]; then
    echo "  Tier:   full (unrecognized value '$_t' — defaulting)"
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
                echo "  · $AGENT has never been used in this project — dispatch it directly or see the Playbook"
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
    echo "  · Weekly optimization due — run /g-trim to compact CLAUDE.md and agent memory"
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
            echo "  · Fresh session, pending handoff — run /g-resume to re-hydrate; a handed-off ADR needs verifying first"
        else
            echo "  · Fresh session, pending handoff — run /g-resume to re-hydrate context before new work"
        fi
    fi
fi

# Duplicate-heading warning — §I requires the Active Session block be replaced
# wholesale, never appended; an appended second block is the form this check
# detects (intra-block residue, the 2026-07-23 m46 incident's shape, is not).
if [ -f "g-docs/ROADMAP.md" ]; then
    _active_session_count=$(grep -c '^## Active Session' g-docs/ROADMAP.md 2>/dev/null)
    if [ "${_active_session_count:-0}" -gt 1 ] 2>/dev/null; then
        echo "  ⚠ g-docs/ROADMAP.md has $_active_session_count '## Active Session' headings — replace-never-append violated (G-RULES §I)"
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
        echo "  · Brief-alignment check due — run /g-align to confirm progress still serves g-docs/project_brief.md"
    fi
fi

# Self-update check — background curl once per day, zero blocking latency.
# INSTALLED_MANIFEST resolves the HIGHEST-versioned directory under the
# plugin cache (mirrors skills/g-update/SKILL.md Step 2: "Glob for
# subdirectories, pick the highest semver, read its .claude-plugin/plugin.json").
# The real installed layout always has a version-numbered directory between
# g-forge/g-forge/ and the plugin content (e.g. .../g-forge/g-forge/0.3.3/
# .claude-plugin/plugin.json) — the previous bare two-segment path here
# (M-audit W3 task 13) had no version segment at all, so it never matched a
# real install and this whole nudge was silently dead on every consumer
# project. Pick the highest-semver cache dir by reducing with the shared
# gf_semver_compare (ADR-009: one ordering contract, no per-site sort -V) so
# the hotfix-suffix grammar (2.3.3a) orders the same here as in /g-update and
# /g-doctor. `sort -V` stays only as the fallback when the lib failed to source
# — a missing lib must never dead-end this advisory nudge. Misordering is
# harmless anyway: it only shifts which release the message names, never blocks
# (this hook is non-gating).
CLAUDE_DIR="$HOME/.claude"
_gf_plugin_cache_base="$CLAUDE_DIR/plugins/cache/g-forge/g-forge"
INSTALLED_MANIFEST=""
if [ -d "$_gf_plugin_cache_base" ]; then
    _gf_highest_version_dir=""
    if command -v gf_semver_compare >/dev/null 2>&1; then
        _gf_highest_ver=""
        for _gf_d in "$_gf_plugin_cache_base"/*/; do
            [ -d "$_gf_d" ] || continue
            _gf_v=$(basename "$_gf_d")
            if [ -z "$_gf_highest_ver" ]; then
                _gf_highest_ver="$_gf_v"; _gf_highest_version_dir="$_gf_d"; continue
            fi
            _gf_cmp=$(gf_semver_compare "$_gf_v" "$_gf_highest_ver")
            if [ "$?" -eq 0 ] && [ "$_gf_cmp" = "1" ]; then
                _gf_highest_ver="$_gf_v"; _gf_highest_version_dir="$_gf_d"
            fi
        done
    else
        _gf_highest_version_dir=$(ls -d "$_gf_plugin_cache_base"/*/ 2>/dev/null | sort -V | tail -1)
    fi
    [ -n "$_gf_highest_version_dir" ] && INSTALLED_MANIFEST="${_gf_highest_version_dir}.claude-plugin/plugin.json"
fi
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
        # Direction-aware comparison (M46 W2 task 4) — gf_semver_compare tells
        # LATEST vs INSTALLED apart instead of a bare inequality, which fires
        # backwards ("2.3.0 → 2.2.1") whenever the async-fetched cache lags
        # behind the installed copy (e.g. right after a dev-repo release push,
        # before the next daily GitHub fetch catches up). Malformed input or a
        # missing lib both degrade to printing nothing — this hook is
        # non-gating and must never surface a wrong-direction nudge.
        if [ -n "$LATEST_VER" ] && command -v gf_semver_compare >/dev/null 2>&1; then
            _GF_VER_CMP=$(gf_semver_compare "$LATEST_VER" "$INSTALLED_VER")
            _GF_VER_CMP_RC=$?
            if [ "$_GF_VER_CMP_RC" -eq 0 ]; then
                if [ "$_GF_VER_CMP" -eq 1 ]; then
                    echo "  ⚡ g-forge update available: $INSTALLED_VER → $LATEST_VER — run /g-update to pull and sync"
                elif [ "$_GF_VER_CMP" -eq -1 ]; then
                    echo "  ℹ g-forge cache ($INSTALLED_VER) is ahead of GitHub ($LATEST_VER) — dev repo: cache lags repo after release push"
                fi
            fi
        fi
    fi
fi

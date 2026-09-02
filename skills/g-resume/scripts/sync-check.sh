#!/bin/bash
# sync-check.sh — deterministic implementation of /g-resume Step 0 (0a–0g).
#
# Run from the project root. Prints KEY: value lines for the skill to interpret;
# always exits 0 — every outcome is in the output, never the exit code.
# Rationale for each branch lives in ../references/sync-edge-cases.md (0a–0g
# sections mirror this file top-to-bottom; keep both in sync when editing).
# Cross-ref: hooks/session-start.sh prints advisory behind/ahead + drift lines
# at session open; this script's figures supersede them (one-owner rule).
#
# Output contract:
#   EXIT: existence-gate            neither ROADMAP nor compact-state exists (0a)
#   NOTE: <text>                    0+ human-readable notes
#   FRESHNESS: <value>              exactly one, from the closed set — absent
#                                   only on EXIT or DIVERGED
#   DIVERGED: behind=N ahead=M      diverged row (0f) — the skill must ask the
#                                   developer; no FRESHNESS is printed
#   FF: ok <short-sha> | failed     printed only when a fast-forward was tried
#   RECORD_AXIS: <value>            0g line; absent when the current branch IS
#                                   the record branch, or 0a–0d exited early
#   REMOTE/BRANCH/REF: <names>      resolution facts for the briefing
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }
finish() { out "FRESHNESS: $1"; [ -n "${2:-}" ] && out "NOTE: $2"; record_axis; exit 0; }
# Early exits (before classification) never print RECORD_AXIS (0g never ran).
bail() { out "FRESHNESS: $1"; [ -n "${2:-}" ] && out "NOTE: $2"; exit 0; }

RECORD_READY=0
record_axis() {
    # 0g — record-drift line. Only meaningful once classification ran.
    [ "$RECORD_READY" = 1 ] || return 0
    local cand rb name
    cand=$(git symbolic-ref --short "refs/remotes/$REMOTE/HEAD" 2>/dev/null)
    cand=${cand#"$REMOTE"/}
    for name in "$cand" main master; do
        [ -n "$name" ] || continue
        if git rev-parse --verify -q "$REMOTE/$name" >/dev/null 2>&1; then
            # Silent case: the current branch IS the record branch — Freshness covers it.
            [ "$name" = "$BRANCH" ] && return 0
            if ! rb=$(git rev-list --count "HEAD..$REMOTE/$name" 2>/dev/null); then
                out "RECORD_AXIS: record-drift count failed — cannot tell whether the handoff is current"
            elif [ "$rb" -gt 0 ]; then
                out "RECORD_AXIS: $rb commits behind $REMOTE/$name — the handoff you are re-hydrating from may be stale"
            else
                out "RECORD_AXIS: not behind $REMOTE/$name"
            fi
            return 0
        fi
    done
    out "RECORD_AXIS: record branch could not be resolved — cannot tell whether the handoff is current"
}

# ── 0a — existence gate ──────────────────────────────────────────────────────
if [ ! -f g-docs/ROADMAP.md ] && [ ! -f .claude/compact-state.md ]; then
    out "EXIT: existence-gate"; exit 0
fi

# ── 0b — resolve remote, then comparison ref ────────────────────────────────
[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] \
    || bail "unsynced — not a git repo" "Not a git repository — skipping sync"
BRANCH=$(git branch --show-current)
[ -n "$BRANCH" ] || bail "unsynced — detached HEAD" "Detached HEAD — skipping sync"
out "BRANCH: $BRANCH"

REMOTE=$(git config --get "branch.$BRANCH.remote" || true)
[ "$REMOTE" = "." ] && bail "unsynced — local-only remote" "Tracks a local ref (remote = .) — skipping sync"

PATH_KIND=""; BLOCKER=""; MISSING_REF_FRESHNESS=""
if REF=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
    PATH_KIND="configured"
    if [ -z "$REMOTE" ]; then
        REMOTE=${REF%%/*}
        { [ -z "$REMOTE" ] || [ "$REMOTE" = "$REF" ]; } \
            && bail "unsynced — no remote" "Could not determine which remote $REF belongs to — skipping sync"
    fi
    MISSING_REF_FRESHNESS="unsynced — upstream branch gone"
elif [ -n "$REMOTE" ]; then
    PATH_KIND="noat-a"; REF="$REMOTE/$BRANCH"          # tracking config, no @{u}
    BLOCKER="upstream ref unresolved"
    MISSING_REF_FRESHNESS="unsynced — upstream branch gone"
else
    PATH_KIND="noat-b"; REMOTE=origin; REF="origin/$BRANCH"  # no tracking config
    BLOCKER="no tracking configuration"
    MISSING_REF_FRESHNESS="unsynced — no upstream"
fi
git remote | grep -qx "$REMOTE" \
    || bail "unsynced — no remote" "No $REMOTE remote — skipping sync"
out "REMOTE: $REMOTE"; out "REF: $REF"

# ── 0c — bounded, non-interactive fetch ─────────────────────────────────────
if command -v timeout >/dev/null 2>&1; then
    GIT_TERMINAL_PROMPT=0 timeout 10 git fetch "$REMOTE" --quiet --no-tags 2>/dev/null
else
    GIT_TERMINAL_PROMPT=0 git fetch "$REMOTE" --quiet --no-tags 2>/dev/null
fi
[ $? -eq 0 ] || bail "unverified — fetch failed" "Fetch of $REMOTE failed (offline/auth/timeout) — skipping compare"

# ── 0d — post-fetch re-check, then classify ─────────────────────────────────
git rev-parse --verify -q HEAD >/dev/null 2>&1 \
    || bail "unsynced — unborn HEAD" "No commits yet — skipping sync"
if ! git rev-parse --verify -q "$REF" >/dev/null 2>&1; then
    if [ "$PATH_KIND" = "noat-b" ]; then
        bail "$MISSING_REF_FRESHNESS" "No upstream — skipping sync"
    else
        bail "$MISSING_REF_FRESHNESS" "Upstream branch no longer on the remote — skipping sync"
    fi
fi

BEHIND=$(git rev-list --count "HEAD..$REF"); AHEAD=$(git rev-list --count "$REF..HEAD")
STATUS_OUT=$(git status --porcelain --untracked-files=no 2>/dev/null); STATUS_RC=$?
CLEAN=unknown
if [ $STATUS_RC -eq 0 ]; then [ -z "$STATUS_OUT" ] && CLEAN=yes || CLEAN=no; fi
RECORD_READY=1

if [ "$BEHIND" -eq 0 ] && [ "$AHEAD" -eq 0 ]; then
    finish "synced" "✓ In sync with $REMOTE"
elif [ "$BEHIND" -eq 0 ]; then
    finish "synced — $AHEAD unpushed" "↑ $AHEAD unpushed local commits — $REMOTE can't see them yet"
elif [ "$AHEAD" -gt 0 ]; then
    out "DIVERGED: behind=$BEHIND ahead=$AHEAD"
    record_axis; exit 0                                  # 0f — the skill asks
fi

# ── 0e — behind-only: fast-forward or name the first unmet gate ─────────────
# Gate order is fixed: status-unknown · dirty · path blocker · session phase.
WHY=""
if   [ "$CLEAN" = "unknown" ]; then WHY="working-tree state unknown"
elif [ "$CLEAN" = "no" ];      then WHY="dirty tree"
elif [ -n "$BLOCKER" ];        then WHY="$BLOCKER"
else
    # Session-start check — prompt counter, resolved per ADR-005 local-else-primary.
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
    COUNT=""
    if [ -n "$CDIR" ]; then
        set -- "$CDIR"/session-prompt-count*
        if [ $# -eq 1 ] && [ -f "$1" ]; then COUNT=$(cat "$1" 2>/dev/null); fi
        # >1 concurrent counters, none, or unreadable → conservative (never mtime-pick here).
    fi
    case "$COUNT" in
        1) : ;;                                        # session-start — 0e may run
        ''|*[!0-9]*) WHY="session phase unknown" ;;
        0) WHY="session phase unknown" ;;
        *) WHY="mid-session run" ;;
    esac
fi

if [ -z "$WHY" ]; then
    # merge, never pull — 0c already fetched; no second network call at prompt 1.
    if git merge --ff-only "$REF" >/dev/null 2>&1; then
        out "FF: ok $(git rev-parse --short HEAD)"
        finish "synced — fast-forwarded $BEHIND" "Fast-forwarded $BEHIND commits — now at $(git rev-parse --short HEAD)"
    else
        out "FF: failed"
        finish "stale — $BEHIND behind (fast-forward failed)" "↓ $BEHIND behind $REMOTE — fast-forward refused (local cause: collision or non-ff ref)"
    fi
else
    finish "stale — $BEHIND behind (not pulled: $WHY)" "↓ $BEHIND behind $REMOTE"
fi

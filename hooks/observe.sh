#!/bin/bash
# G-Forge silent observer — maintains a passive activity journal.
# Wired to PostToolUse(Bash) and SessionStart. Writes NOTHING to stdout:
# it observes, it never interrupts. The daily journal it produces is the
# raw material /g-retro later synthesizes into a retrospective — no
# end-of-session interview required.
#
# Journal: .claude/journal/YYYY-MM-DD.jsonl  (append-only, one event per line)
#   {"ts":"<iso8601>","kind":"<kind>","detail":"<text>"}
#   Linked-worktree events (see below) additionally carry "wt":"<toplevel>".
#
# Usage: observe.sh log      # PostToolUse — categorize the Bash command
#        observe.sh session  # SessionStart — mark a session open
#
# Sources shared lib helpers so commit detection and worktree resolution
# agree with the ADR-004 native pre-commit hook and the commit gate instead
# of drifting apart across hand-edited implementations (M-audit finding #21
# / BUG-2). Resolved relative to this script's own location so the installed
# copy (.claude/hooks/observe.sh, with libs under .claude/hooks/lib/) finds
# its libs the same way the repo source (hooks/observe.sh, hooks/lib/) does.
_GF_HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/commit-detect.sh
. "$_GF_HOOK_DIR/lib/commit-detect.sh"
# shellcheck source=lib/worktree-resolve.sh
. "$_GF_HOOK_DIR/lib/worktree-resolve.sh"
# shellcheck source=lib/stdin-read.sh
# Bounds stdin reads so an abandoned tool call can never hang this hook forever.
[ -f "$_GF_HOOK_DIR/lib/stdin-read.sh" ] && . "$_GF_HOOK_DIR/lib/stdin-read.sh"
# Body mirrors lib/stdin-read.sh's `read -t -d ''` mechanism rather than a bare
# `cat` — an unbounded fallback would reintroduce the very hang the lib exists
# to bound, on precisely the missing-lib path this shim covers.
if ! command -v gf_read_stdin_timeout >/dev/null 2>&1; then
    gf_read_stdin_timeout() {
        local t="${1:-5}" p=""
        IFS= read -r -t "$t" -d '' p || true
        printf '%s' "$p"
        return 0
    }
fi

MODE="${1:-log}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DAY=$(date -u +"%Y-%m-%d")

# G-Forge project guard — journal only inside a G-Forge-managed project (one
# that ran /g-init, which writes .claude/integration-tier). Stays silent (and
# cheap) everywhere else, so multiple registration sources never cause it to
# misfire.
#
# Local-first-else-primary (ADR-005; developer decision 2026-07-15: one
# project = one /g-retro timeline): a local .claude/integration-tier means
# this IS the primary tree (or a standalone, non-worktree project) — behave
# exactly as before. Otherwise this may be a linked worktree of a gated
# primary tree; resolve the primary .claude/ via the shared helper and defer
# entirely to its tier + journal. This hook is NON-GATING — any resolution
# failure or ambiguity exits silently rather than guessing or blocking.
GF_CLAUDE_DIR=$(gf_guard_claude_dir) || exit 0
IS_LINKED_WORKTREE=0
[ "$GF_CLAUDE_DIR" != ".claude" ] && IS_LINKED_WORKTREE=1

# `light` tier means the user opted G-Forge out — don't journal either.
_t=$(tr -d '[:space:]' < "$GF_CLAUDE_DIR/integration-tier" 2>/dev/null)
[ "$_t" = "light" ] && exit 0

# Linked-worktree events tag the journal line with which worktree fired it
# (gf_worktree_key — the absolute --show-toplevel path), since every linked
# worktree of a gated primary now shares that primary's single journal.
# Escaped the same way as the "detail" field below for JSON safety.
WT_KEY=""
if [ "$IS_LINKED_WORKTREE" -eq 1 ]; then
    WT_KEY=$(gf_worktree_key 2>/dev/null | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\000-\037')
fi

JOURNAL_DIR="$GF_CLAUDE_DIR/journal"
JOURNAL="$JOURNAL_DIR/$DAY.jsonl"

mkdir -p "$JOURNAL_DIR" 2>/dev/null || exit 0

# utf8_safe_truncate <string> <max-bytes> — truncate to at most max-bytes
# without splitting a UTF-8 multi-byte sequence mid-character. `cut -c1-N`
# truncates by BYTES on this platform's userland regardless of locale (git-
# bash GNU cut under C.UTF-8 confirmed live), so a boundary landing inside a
# multi-byte sequence emits invalid UTF-8 that breaks downstream `jq -e .`
# decode. Built on head/tail/od/wc — byte-exact, locale-independent POSIX
# tools — rather than bash's own string indexing (`${s:0:n}`), which on at
# least one observed bash build stays character-aware even under LC_ALL=C
# and so cannot be trusted to truncate by raw byte count.
utf8_safe_truncate() {
    local s="$1" max="$2" tmp n i back ord need have
    tmp=$(printf '%s' "$s" | head -c "$max")
    n=$(printf '%s' "$tmp" | wc -c | tr -d ' ')
    back=0
    i="$n"
    while [ "$back" -lt 4 ] && [ "$i" -gt 0 ]; do
        ord=$(printf '%s' "$tmp" | head -c "$i" | tail -c1 | od -An -tu1 | tr -d ' ')
        if [ "$ord" -ge 128 ] && [ "$ord" -lt 192 ]; then
            # continuation byte — walk back to find its lead byte.
            back=$((back + 1))
            i=$((i - 1))
            continue
        fi
        if [ "$ord" -ge 192 ]; then
            # Lead byte at position i — determine its sequence length and
            # compare against how many continuation bytes actually survived
            # the truncation; drop the whole sequence if it was cut short.
            need=1
            [ "$ord" -ge 224 ] && need=2
            [ "$ord" -ge 240 ] && need=3
            have=$((n - i))
            [ "$have" -lt "$need" ] && tmp=$(printf '%s' "$tmp" | head -c $((i - 1)))
        fi
        break
    done
    printf '%s' "$tmp"
}

append() {
    # $1 = kind, $2 = detail. Escape for JSON, strip ALL control chars
    # (0x00-0x1F, not just CR/LF — a raw tab or other C0 control byte left
    # in the JSON string value breaks `jq -e .` the same way a bare quote
    # would), then cap length UTF-8-safely so the cut can never split a
    # multi-byte character and emit invalid UTF-8 downstream.
    # Primary-tree events stay byte-identical to the historical format; only
    # linked-worktree events (with a resolved WT_KEY) gain the "wt" field.
    local kind="$1" detail="$2"
    detail=$(printf '%s' "$detail" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\000-\037')
    detail=$(utf8_safe_truncate "$detail" 300)
    if [ "$IS_LINKED_WORKTREE" -eq 1 ] && [ -n "$WT_KEY" ]; then
        printf '{"ts":"%s","kind":"%s","detail":"%s","wt":"%s"}\n' "$TS" "$kind" "$detail" "$WT_KEY" >> "$JOURNAL" 2>/dev/null || true
    else
        printf '{"ts":"%s","kind":"%s","detail":"%s"}\n' "$TS" "$kind" "$detail" >> "$JOURNAL" 2>/dev/null || true
    fi
}

if [ "$MODE" = "session" ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo unknown)
    # SessionStart carries a `source`: startup | resume | clear | compact.
    # Journaling it disambiguates the platform's documented multi-fire-per-source
    # behavior (W1.7 Task-18 characterization) from a genuine duplicate-event bug
    # when mining the journal for /g-retro. Same grep-only extraction idiom as
    # hooks/session-start.sh (lines 60-62) reading the same field off the same
    # event — kept identical rather than reinventing extract_cmd's heavier
    # jq/python3/node cascade below, which exists only for the PostToolUse
    # command payload this branch never sees.
    # A bare unquoted `"source":null` never matches the quoted-value pattern, so
    # SESSION_SRC stays empty and the suffix is omitted entirely (W1.6 F-node
    # lesson: never stringify an absent/null field into the journal as "null").
    # Bounded read (see hooks/lib/stdin-read.sh) before feeding the payload downstream.
    _SESSION_INPUT=$(gf_read_stdin_timeout 5)
    SESSION_SRC=$(printf '%s' "$_SESSION_INPUT" \
        | grep -oE '"source"[[:space:]]*:[[:space:]]*"[a-zA-Z]+"' | head -1 \
        | grep -oE '"[a-zA-Z]+"$' | tr -d '"')
    if [ -n "$SESSION_SRC" ]; then
        append "session" "session opened on $BRANCH (source: $SESSION_SRC)"
    else
        append "session" "session opened on $BRANCH"
    fi
    exit 0
fi

# Extract the tool command from a PostToolUse JSON payload. Same hardened
# cascade as the commit gate: probe each parser before trusting it (the
# Windows Microsoft-Store python3 stub fails the probe), then fall back to
# the raw payload. Never depend on a lone silenced interpreter.
extract_cmd() {
    local payload="$1" cmd=""
    if command -v jq >/dev/null 2>&1; then
        cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // .command // ""' 2>/dev/null)
    fi
    if [ -z "$cmd" ] && python3 -c 'import sys' >/dev/null 2>&1; then
        cmd=$(printf '%s' "$payload" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', '') or d.get('command', ''))
except Exception:
    pass
" 2>/dev/null)
    fi
    if [ -z "$cmd" ] && command -v node >/dev/null 2>&1; then
        cmd=$(printf '%s' "$payload" | node -e "
let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{const d=JSON.parse(s);process.stdout.write((d.tool_input&&d.tool_input.command)||d.command||'');}catch(e){}});
" 2>/dev/null)
    fi
    # Last-resort tier: no working JSON parser at all (e.g. every interpreter
    # shadowed/broken). Pull the "command" field's string value out with a
    # plain sed capture instead of falling straight to the raw payload — the
    # commit probe below now classifies via is_git_commit()'s argv walk,
    # which needs the bare command text, not the surrounding JSON envelope,
    # to recognize `git commit`.
    if [ -z "$cmd" ]; then
        cmd=$(printf '%s' "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p')
    fi
    printf '%s' "$cmd"
}

# Bounded read (see hooks/lib/stdin-read.sh) so an abandoned tool call can't hang this hook.
INPUT=$(gf_read_stdin_timeout 5)
CMD=$(extract_cmd "$INPUT")
[ -z "$CMD" ] && CMD="$INPUT"
[ -z "$CMD" ] && exit 0

# Journal only meaningful workflow events — not every `ls` and `cat`.
# Commit detection defers to the shared is_git_commit() helper (hooks/lib/
# commit-detect.sh) so this hook and the commit gate can never classify the
# same command differently (M-audit finding #21 / BUG-2 — two hand-edited
# regexes drifting apart).
if is_git_commit "$CMD"; then
    append "commit" "$CMD"
    exit 0
fi
case "$CMD" in
    *"git push"*)                            append "push"        "$CMD" ;;
    *"git merge"*)                           append "merge"       "$CMD" ;;
    *"git checkout -b"*|*"git switch -c"*)   append "branch"      "$CMD" ;;
    *"git revert"*)                          append "revert"      "$CMD" ;;
    *npm\ test*|*"pytest"*|*"make test"*|*"bun test"*|*yarn\ test*|*go\ test*|*cargo\ test*|*vitest*|*jest*)
                                             append "test"        "$CMD" ;;
    *"rm -rf"*)                              append "destructive" "$CMD" ;;
    *) : ;;  # uninteresting — stay silent
esac
exit 0

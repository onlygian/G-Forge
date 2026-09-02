#!/bin/bash
# merge-gitignore.sh — deterministic implementation of /g-init Step 5a
# (.gitignore idempotent merge).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. Rationale for the tracked-vs-ignored boundary lives in
# ../references/tracked-vs-ignored.md.
#
# Merge semantics: exact-pattern match (whole line); only missing patterns
# are appended, grouped under their labelled section header; a developer's
# existing entries are never removed or reordered.
#
# Output contract:
#   GITIGNORE: created|updated|unchanged
#   ADDED: <pattern>        pattern appended this run
#   PRESENT: <pattern>      pattern already there — left alone
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

TARGET=.gitignore
NEW=0
[ -f "$TARGET" ] || { : > "$TARGET"; NEW=1; }

CHANGED=0
CUR_HEADER=""

# section <header-line> — sets the group header for subsequent add calls.
section() { CUR_HEADER="$1"; }

# add <pattern> — append if not present (exact whole-line match).
add() {
    if grep -qxF -- "$1" "$TARGET" 2>/dev/null; then
        out "PRESENT: $1"
        return 0
    fi
    if [ -n "$CUR_HEADER" ] && ! grep -qxF -- "$CUR_HEADER" "$TARGET" 2>/dev/null; then
        [ -s "$TARGET" ] && printf '\n' >> "$TARGET"
        printf '%s\n' "$CUR_HEADER" >> "$TARGET"
    fi
    printf '%s\n' "$1" >> "$TARGET"
    out "ADDED: $1"
    CHANGED=1
}

# Pattern list — byte-identical to the block /g-init Step 5a always appended,
# plus .claude/banner-hash.* (session state, alongside the other counters).
section "# ── OS / editor ──"
add ".DS_Store"
add "Thumbs.db"
add "*.swp"

section "# ── Secrets / local env ──"
add ".env"
add ".env.*"
add "!.env.example"
add "*.local"

section "# ── Worktrees ──"
add ".worktrees/"

section "# ── G-Forge runtime state (per-developer / ephemeral — never shared) ──"
add ".claude/g-forge-approved"
add ".claude/g-forge-docs-approved"
add ".claude/journal/"
add ".claude/compact-state.md"
add ".claude/reentry.md"
add ".claude/session-prompt-count*"
add ".claude/session-compaction-count"
add ".claude/banner-hash.*"
add ".claude/context-threshold-offset"
add ".claude/review-holds"
add ".claude/tier3-active"
add ".claude/training-mode"
add ".claude/training-progress.md"
add ".claude/telemetry-coverage"
add ".claude/last-trim"
add ".claude/last-align"
add ".claude/coverage-nudge-stamp"
add ".claude/coverage-nudge-index"
add ".claude/agent-memory-local/"

section "# ── G-Forge regenerable output (not project record) ──"
add "g-docs/agent-output/"

if [ "$NEW" = 1 ]; then
    out "GITIGNORE: created"
elif [ "$CHANGED" = 1 ]; then
    out "GITIGNORE: updated"
else
    out "GITIGNORE: unchanged"
fi
exit 0

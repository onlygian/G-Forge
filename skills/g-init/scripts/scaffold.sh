#!/bin/bash
# scaffold.sh [--skip-rules] [--skip-agents] <plugin-root> — deterministic
# implementation of /g-init Steps 2a + 3 + 4 + 5 (rules install, g-docs
# skeletons, CLAUDE.md status).
#
# Skip flags honor /g-onboard's recorded conflict preferences (Step 1b):
#   --skip-rules    do not install G-RULES.md, rule sections, rule
#                   references, or the dispatch matrix (Step 2a skipped)
#   --skip-agents   recorded for the contract — scaffold.sh installs no
#                   agents (that is /g-specialize, Step 7b); accepted so the
#                   skill can pass both preferences in one call
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. CLAUDE.md creation/injection itself stays model-side (the
# skill's Step 2) so /g-onboard conflict preferences are honored; this
# script only reports the file's status.
#
# The g-docs skeletons below are the canonical blocks: the ROADMAP handoff's
# '## Active Session' heading, '━' banner lines, and 'Active context:' prefix
# are grepped by hooks/workflow-checkpoint.sh and hooks/pre-compact.sh —
# byte-identical, written raw (not code-fenced).
#
# Output contract:
#   CREATED: <path>         file written (new, or G-Forge-managed overwrite
#                           where nothing was there before)
#   EXISTS: <path>          skeletons: left untouched; G-Forge-managed copies
#                           (G-RULES.md, rules): overwritten in place
#   RULES_INSTALLED: <n>    g-rules section files installed — counted from
#                           disk after the copy, never typed
#   SKIPPED: <what>         a skip flag was honored (rules|agents)
#   CLAUDEMD: missing|ok|no-marker|no-import
#                           missing = no CLAUDE.md; no-marker = lacks
#                           '<!-- G-Forge Rules'; no-import = lacks
#                           '@G-RULES.md'; ok = both present
#   NOTE: <text>            0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

SKIP_RULES=no
SKIP_AGENTS=no
PLUGIN_ROOT=""
for a in "$@"; do
    case "$a" in
        --skip-rules)  SKIP_RULES=yes ;;
        --skip-agents) SKIP_AGENTS=yes ;;
        *) [ -z "$PLUGIN_ROOT" ] && PLUGIN_ROOT="$a" ;;
    esac
done
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT" ]; then
    out "NOTE: plugin root missing or not a directory: '$PLUGIN_ROOT' — rules install skipped"
    PLUGIN_ROOT=""
fi
[ "$SKIP_AGENTS" = yes ] && out "SKIPPED: agents"

# managed_copy <src> <dest> — overwrite always (G-Forge managed).
managed_copy() {
    if [ -f "$2" ]; then
        cp "$1" "$2" 2>/dev/null && out "EXISTS: $2"
    else
        cp "$1" "$2" 2>/dev/null && out "CREATED: $2"
    fi
}

# ── Step 2a — G-RULES.md + rule section files ───────────────────────────────
if [ "$SKIP_RULES" = yes ]; then
    out "SKIPPED: rules"
elif [ -n "$PLUGIN_ROOT" ]; then
    if [ -f "$PLUGIN_ROOT/G-RULES.md" ]; then
        managed_copy "$PLUGIN_ROOT/G-RULES.md" "G-RULES.md"
    else
        out "NOTE: $PLUGIN_ROOT/G-RULES.md not found — skipped"
    fi

    mkdir -p .claude/rules
    for f in "$PLUGIN_ROOT"/rules/g-rules/*.md; do
        [ -f "$f" ] || continue
        managed_copy "$f" ".claude/rules/g-rules-$(basename "$f")"
    done

    # Lazy rule references — installed alongside the sections, NOT @-imported
    # (loaded on demand by the rules that name them).
    if [ -d "$PLUGIN_ROOT/rules/references" ]; then
        mkdir -p .claude/rules/references
        for f in "$PLUGIN_ROOT"/rules/references/*.md; do
            [ -f "$f" ] || continue
            managed_copy "$f" ".claude/rules/references/$(basename "$f")"
        done
    fi

    # Dispatch matrix — installed as g-dispatch-matrix.md, NOT @-imported.
    if [ -f "$PLUGIN_ROOT/rules/dispatch-matrix.md" ]; then
        managed_copy "$PLUGIN_ROOT/rules/dispatch-matrix.md" ".claude/rules/g-dispatch-matrix.md"
    fi
fi

# Counted from disk, never typed (ADR-011 derive-don't-type).
RULES_N=$(ls -1 .claude/rules/g-rules-*.md 2>/dev/null | wc -l | tr -d ' ')
out "RULES_INSTALLED: $RULES_N"

# ── Steps 3/4/5 — g-docs skeletons (create only if absent) ──────────────────
mkdir -p g-docs g-docs/milestones

if [ -f g-docs/ROADMAP.md ]; then
    out "EXISTS: g-docs/ROADMAP.md"
else
    cat > g-docs/ROADMAP.md <<'GF_EOF'
# Roadmap

## Active Session

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — [project] | branch: [branch]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · (nothing yet)
Next up:          · Define M1 scope in g-docs/milestones/M1.md
Active context:   · Fresh project, just initialized
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Milestones

### M1 — [Define milestone name]
**Status:** 🔄 In progress
**Goal:** [one line — what M1 delivers]
**Scope:**
- [ ] Task 1

## Backlog
- M2 — [Define next milestone]
GF_EOF
    out "CREATED: g-docs/ROADMAP.md"
fi

if [ -f g-docs/milestones/M1.md ]; then
    out "EXISTS: g-docs/milestones/M1.md"
else
    cat > g-docs/milestones/M1.md <<'GF_EOF'
# M1 — [Milestone Name]

## Goal
[One sentence describing what this milestone delivers]

## Scope
- [ ] Task 1
- [ ] Task 2

## Done condition
[Specific, mechanically checkable condition]

## Status
🔄 In progress
GF_EOF
    out "CREATED: g-docs/milestones/M1.md"
fi

if [ -f g-docs/todo.md ]; then
    out "EXISTS: g-docs/todo.md"
else
    cat > g-docs/todo.md <<'GF_EOF'
## Tasks
| # | Task | Notes |
|---|------|-------|
| 1 | Define M1 scope | Update g-docs/milestones/M1.md |

## Details
GF_EOF
    out "CREATED: g-docs/todo.md"
fi

# ── Step 2 support — CLAUDE.md status (writes stay model-side) ──────────────
if [ ! -f CLAUDE.md ]; then
    out "CLAUDEMD: missing"
elif ! grep -qF -- '<!-- G-Forge Rules' CLAUDE.md 2>/dev/null; then
    out "CLAUDEMD: no-marker"
elif ! grep -qF -- '@G-RULES.md' CLAUDE.md 2>/dev/null; then
    out "CLAUDEMD: no-import"
else
    out "CLAUDEMD: ok"
fi
exit 0

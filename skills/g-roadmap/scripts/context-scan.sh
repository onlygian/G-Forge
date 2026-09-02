#!/bin/bash
# context-scan.sh — deterministic implementation of /g-roadmap Step 0 detection.
#
# Run from the project root. Prints KEY: value lines for the skill to interpret;
# always exits 0 — every outcome is in the output, never the exit code.
# The skill keeps the judgment: ACTIVE != none → ask add-vs-replan; MANIFESTS
# != none → dispatch dependency-auditor; VERSION unversioned → note that the
# developer must establish a starting version.
#
# Output contract:
#   ROADMAP: exists|missing          g-docs/ROADMAP.md presence
#   ACTIVE: <title>|none             first ### milestone whose **Status:** line
#                                    contains 🔄 (printed only when ROADMAP exists)
#   COMPLETED: <title>               0+ lines — ✅ milestones, in file order
#   BACKLOG_COUNT: <n>               list items under ## Backlog
#   BRIEF: exists|missing            g-docs/project_brief.md presence
#   VERSION: v<x.y.z>|unversioned    current version
#   VERSION_SOURCE: <file>|none      first hit in the fixed cascade order:
#                                    .claude-plugin/plugin.json, package.json,
#                                    pyproject.toml, Cargo.toml
#   MANIFESTS: <names>|none          space-separated, from: package.json
#                                    requirements.txt Cargo.toml go.mod Pipfile
#                                    pyproject.toml pom.xml build.gradle
#   NOTE: <text>                     0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

# ── ROADMAP existence + milestone scan ──────────────────────────────────────
if [ -f g-docs/ROADMAP.md ]; then
    out "ROADMAP: exists"
    # Walk the file: remember the latest ### heading; classify it by the next
    # **Status:** line (🔄 active — first wins; ✅ completed, in file order).
    ACTIVE=""
    COMPLETED_LINES=""
    TITLE=""
    while IFS= read -r line; do
        case "$line" in
            "### "*)
                TITLE=${line#"### "} ;;
            *"**Status:**"*)
                case "$line" in
                    *"🔄"*) [ -n "$ACTIVE" ] || ACTIVE="$TITLE" ;;
                    *"✅"*) [ -n "$TITLE" ] && COMPLETED_LINES="${COMPLETED_LINES}COMPLETED: $TITLE
" ;;
                esac ;;
        esac
    done < g-docs/ROADMAP.md
    out "ACTIVE: ${ACTIVE:-none}"
    [ -n "$COMPLETED_LINES" ] && printf '%s' "$COMPLETED_LINES"
    # Backlog items: list lines under ## Backlog until the next ## heading.
    BACKLOG_COUNT=$(awk '
        /^## Backlog/ { inb=1; next }
        /^## /        { inb=0 }
        inb && /^(- |· )/ { n++ }
        END { print n+0 }' g-docs/ROADMAP.md)
    out "BACKLOG_COUNT: $BACKLOG_COUNT"
else
    out "ROADMAP: missing"
    out "ACTIVE: none"
    out "BACKLOG_COUNT: 0"
fi

# ── Brief existence ─────────────────────────────────────────────────────────
if [ -f g-docs/project_brief.md ]; then
    out "BRIEF: exists"
else
    out "BRIEF: missing"
fi

# ── Current version — fixed 4-file cascade, first hit wins ──────────────────
VERSION=""
VERSION_SOURCE=""
for f in .claude-plugin/plugin.json package.json pyproject.toml Cargo.toml; do
    [ -f "$f" ] || continue
    case "$f" in
        *.json) V=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null \
                    | head -n1 | sed 's/.*"\([^"]*\)"$/\1/') ;;
        *)      V=$(grep -E '^[[:space:]]*version[[:space:]]*=[[:space:]]*"' "$f" 2>/dev/null \
                    | head -n1 | sed 's/.*"\([^"]*\)".*/\1/') ;;
    esac
    if [ -n "${V:-}" ]; then
        VERSION="v${V#v}"
        VERSION_SOURCE="$f"
        break
    fi
done
if [ -n "$VERSION" ]; then
    out "VERSION: $VERSION"
    out "VERSION_SOURCE: $VERSION_SOURCE"
else
    out "VERSION: unversioned"
    out "VERSION_SOURCE: none"
    out "NOTE: no version found — the developer will need to establish a starting version"
fi

# ── Manifest presence (dependency-scan trigger) ─────────────────────────────
MANIFESTS=""
for f in package.json requirements.txt Cargo.toml go.mod Pipfile pyproject.toml pom.xml build.gradle; do
    [ -f "$f" ] && MANIFESTS="$MANIFESTS $f"
done
MANIFESTS=${MANIFESTS# }
out "MANIFESTS: ${MANIFESTS:-none}"

exit 0

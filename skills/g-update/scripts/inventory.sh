#!/bin/bash
# inventory.sh — deterministic implementation of /g-update Step 2 (inventory
# of installed G-Forge content in the current project).
#
# Run from the project root. Prints KEY: value lines the skill renders into
# the "Installed G-Forge content:" summary frame (frame lives in SKILL.md);
# always exits 0 — read-only, no outcome lives in the exit code.
#
# Output contract:
#   RULES_BLOCK: present|absent     CLAUDE.md G-Forge Rules marker block
#   ARCH_STACK: <name>              0+ — one per CLAUDE.md architecture block
#   AGENT: <file> name=<name> class=architect|implementer|other
#                                   0+ — one per .claude/agents/*.md;
#                                   class from the name: field pattern
#                                   (*-architect / *-implementer; the shipped
#                                   feature-implementer classifies as other —
#                                   it is not a per-stack implementer)
#   RULES_FILE: <file>              0+ — one per .claude/rules/*.md
#   HOOK: <file> present|absent     per check-commit.sh and workflow-checkpoint.sh
#   GRULES_MD: present|absent       project-root G-RULES.md
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

# ── CLAUDE.md markers ──────────────────────────────────────────────────────
if [ -f CLAUDE.md ] && grep -q '<!-- G-Forge Rules' CLAUDE.md; then
    out "RULES_BLOCK: present"
else
    out "RULES_BLOCK: absent"
fi

if [ -f CLAUDE.md ]; then
    sed -n 's/^<!-- G-Forge \(.*\) Architecture Rules.*/\1/p' CLAUDE.md \
        | while IFS= read -r stack; do
            [ -n "$stack" ] && out "ARCH_STACK: $stack"
          done
fi

# ── Agents ─────────────────────────────────────────────────────────────────
if [ -d .claude/agents ]; then
    for f in .claude/agents/*.md; do
        [ -f "$f" ] || continue
        name=$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1)
        class=other
        case "$name" in
            feature-implementer) class=other ;;
            *-implementer)       class=implementer ;;
            *-architect)         class=architect ;;
        esac
        out "AGENT: $(basename "$f") name=${name:-unknown} class=$class"
    done
fi

# ── Rules files ────────────────────────────────────────────────────────────
if [ -d .claude/rules ]; then
    for f in .claude/rules/*.md; do
        [ -f "$f" ] && out "RULES_FILE: $(basename "$f")"
    done
fi

# ── Hooks ──────────────────────────────────────────────────────────────────
for h in check-commit.sh workflow-checkpoint.sh; do
    if [ -f ".claude/hooks/$h" ]; then
        out "HOOK: $h present"
    else
        out "HOOK: $h absent"
    fi
done

# ── G-RULES.md ─────────────────────────────────────────────────────────────
if [ -f G-RULES.md ]; then
    out "GRULES_MD: present"
else
    out "GRULES_MD: absent"
fi

exit 0

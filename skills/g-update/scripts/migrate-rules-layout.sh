#!/bin/bash
# migrate-rules-layout.sh <plugin-root> — /g-update Step 2a: move pre-ADR-017
# G-Forge rule copies out of .claude/rules/.
#
# Why: Claude Code auto-loads every .md under .claude/rules/ (recursively) at
# launch. Before ADR-017, /g-init installed the G-Rules sections there AND
# @-imported them from G-RULES.md, and installed the "on-demand" references
# and dispatch matrix there too — so all of them loaded every session and
# trimming G-RULES.md imports could not reduce the load. The new sites are
# .claude/g-rules/ (sections, loaded only via @-imports) and
# .claude/g-references/ (references + matrix, read on demand).
#
# Run from the project root. Touches ONLY names the plugin ships (enumerated
# from <plugin-root> on disk, never a typed list); anything else under
# .claude/rules/ is reported and left alone. Files move AND imports are
# repointed in the same run, so G-RULES.md / CLAUDE.md never point at a
# section that has already moved. Idempotent: a second run on a migrated
# project prints MIGRATION: none. Always exits 0 — every outcome is in the
# output.
#
# Output contract:
#   MOVED: <old> -> <new>     old copy relocated (new path was absent)
#   REMOVED: <old>            byte-identical duplicate removed (new path present)
#   CONFLICT: <old>           old and new copies differ — old left in place
#                             (it still auto-loads; diff, keep what you need,
#                             delete it by hand; /g-doctor Check 16 flags it)
#   KEPT: <path>              G-Forge-looking file the plugin does not ship —
#                             left in place
#   REWROTE_IMPORT: <file>: <old> -> <new>
#                             an import line (optionally indented or a list
#                             bullet) of an old section path, repointed in
#                             G-RULES.md, CLAUDE.md, .claude/CLAUDE.md or
#                             CLAUDE.local.md
#   NOTE: <text>              0+ diagnostics (incl. an old section path still
#                             mentioned in one of those files after the rewrite)
#   MIGRATION: none|done|skipped
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

PLUGIN_ROOT="${1:-}"
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT/rules" ]; then
    out "NOTE: plugin root missing or has no rules/: '$PLUGIN_ROOT' — layout migration skipped"
    out "MIGRATION: skipped"
    exit 0
fi

CHANGED=0

# relocate <old> <new> — move when the new site is free; drop the old copy
# only when it is byte-identical to the new one; otherwise never delete.
relocate() {
    [ -f "$1" ] || return 0
    mkdir -p "$(dirname "$2")"
    if [ ! -f "$2" ]; then
        if mv "$1" "$2"; then out "MOVED: $1 -> $2"; CHANGED=1
        else out "NOTE: could not move $1 — left in place"; fi
    elif cmp -s "$1" "$2"; then
        if rm -f "$1"; then out "REMOVED: $1"; CHANGED=1
        else out "NOTE: could not remove $1 — left in place"; fi
    else
        out "CONFLICT: $1"
    fi
}

# ── Sections: .claude/rules/g-rules-<X>.md → .claude/g-rules/<X>.md ─────────
SECTIONS=""
for src in "$PLUGIN_ROOT"/rules/g-rules/*.md; do
    [ -f "$src" ] || continue
    b=$(basename "$src")
    SECTIONS="$SECTIONS $b"
    relocate ".claude/rules/g-rules-$b" ".claude/g-rules/$b"
done
for f in .claude/rules/g-rules-*.md; do
    [ -f "$f" ] || continue
    case " $SECTIONS " in *" ${f#.claude/rules/g-rules-} "*) ;; *) out "KEPT: $f" ;; esac
done

# ── References: .claude/rules/references/<f> → .claude/g-references/<f> ─────
for src in "$PLUGIN_ROOT"/rules/references/*.md; do
    [ -f "$src" ] || continue
    b=$(basename "$src")
    relocate ".claude/rules/references/$b" ".claude/g-references/$b"
done
if [ -d .claude/rules/references ]; then
    for f in .claude/rules/references/*; do
        [ -e "$f" ] || continue
        b=$(basename "$f")
        [ -f "$PLUGIN_ROOT/rules/references/$b" ] || out "KEPT: $f"
    done
    rmdir .claude/rules/references 2>/dev/null \
        && out "NOTE: removed empty .claude/rules/references/"
fi

# ── Dispatch matrix ─────────────────────────────────────────────────────────
if [ -f "$PLUGIN_ROOT/rules/dispatch-matrix.md" ]; then
    relocate ".claude/rules/g-dispatch-matrix.md" ".claude/g-references/dispatch-matrix.md"
fi

# ── Import lines in the always-loaded entry files ───────────────────────────
# A line whose only content is an import of "@.claude/rules/g-rules-<shipped>.md"
# — optionally indented, optionally a "-", "*" or "+" list bullet, trailing
# whitespace or CR kept — is repointed. Prose mentions are never touched;
# any that remain are reported as NOTE so a hand-written variant is not lost
# silently.
for doc in G-RULES.md CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md; do
    [ -f "$doc" ] || continue
    grep -q '@\.claude/rules/g-rules-' "$doc" || continue
    tmp=$(mktemp)
    awk -v names="$SECTIONS" -v doc="$doc" '
        BEGIN { n = split(names, a, " "); for (i = 1; i <= n; i++) ok[a[i]] = 1 }
        {
            line = $0; cr = ""
            if (sub(/\r$/, "", line)) cr = "\r"
            if (match(line, /@\.claude\/rules\/g-rules-[A-Za-z0-9-]+\.md/)) {
                pre = substr(line, 1, RSTART - 1)
                tok = substr(line, RSTART, RLENGTH)
                post = substr(line, RSTART + RLENGTH)
                b = substr(tok, length("@.claude/rules/g-rules-") + 1)
                if ((b in ok) && pre ~ /^[ \t]*([-*+][ \t]+)?$/ && post ~ /^[ \t]*$/) {
                    printf "%s@.claude/g-rules/%s%s%s\n", pre, b, post, cr
                    printf "REWROTE_IMPORT: %s: %s -> @.claude/g-rules/%s\n", doc, tok, b > "/dev/stderr"
                    next
                }
            }
            print
        }' "$doc" > "$tmp" 2> "$tmp.log"
    if [ -s "$tmp.log" ]; then
        cat "$tmp" > "$doc"
        cat "$tmp.log"
        CHANGED=1
    fi
    rm -f "$tmp" "$tmp.log"
    if grep -q '\.claude/rules/g-rules-' "$doc"; then
        out "NOTE: $doc still mentions .claude/rules/g-rules-* — not an import line this script rewrites; repoint it to .claude/g-rules/ by hand"
    fi
done

if [ "$CHANGED" = 1 ]; then
    out "MIGRATION: done"
else
    out "MIGRATION: none"
fi
exit 0

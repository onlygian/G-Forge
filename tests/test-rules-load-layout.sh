#!/bin/bash
# Pins the G-Rules install layout against Claude Code's documented loading
# (ADR-017, g-docs/decisions/017-install-g-rules-outside-auto-loaded-rules-dir.md):
# every .md under .claude/rules/ auto-loads at launch, @-imports load with the
# importing file, and each always-loaded file should stay under 200 lines.
#
# What each block pins (instrument-claim rule, G-RULES §H):
#   1-3  G-RULES.md: each line-initial @-import is .claude/g-rules/<name>.md
#        with a shipped rules/g-rules/<name>.md (resolve), every shipped
#        section is imported exactly once (bijection), and no import target
#        sits under the auto-loaded .claude/rules/ (never loaded twice)
#   4-7  a real scaffold.sh run into a temp project: zero .md files under
#        .claude/rules/ (absence), installed G-RULES.md imports resolve to
#        installed files when parsed the way Claude Code does (relative to the
#        importing file), every shipped reference + the matrix land in
#        .claude/g-references/, and no installed import target is auto-loaded
#   8    always-loaded sources (templates/CLAUDE.md, G-RULES.md, each section)
#        are each under 200 lines
#   9    templates/CLAUDE.md carries the maintainer guidance as a block HTML
#        comment (stripped before injection) holding no '@' (never an import)
#   10   every .claude/g-rules/ and .claude/g-references/ path named on a live
#        surface resolves to a shipped source file
#   11   old installed paths appear on live surfaces only at the
#        legacy-handling sites (doctor detection, update migration)
#   12   README's section-count word equals the shipped section count
#
# Counts are derived from disk at run time (ADR-013); none is typed here.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$TESTS_DIR")"
GRULES="$REPO/G-RULES.md"
TEMPLATE="$REPO/templates/CLAUDE.md"
SCAFFOLD="$REPO/skills/g-init/scripts/scaffold.sh"

PASS=0
FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

BASE="$(mktemp -d)"
trap 'rm -rf "$BASE"' EXIT

# ── 1-3: G-RULES.md import set ─────────────────────────────────────────────
IMPORTS=$(grep -E '^@' "$GRULES" | sed 's/^@//; s/[[:space:]]*$//')
bad_form=""; missing_src=""
for imp in $IMPORTS; do
    case "$imp" in
        .claude/g-rules/*.md) b=${imp#.claude/g-rules/}
                              [ -f "$REPO/rules/g-rules/$b" ] || missing_src="$missing_src $imp" ;;
        *) bad_form="$bad_form $imp" ;;
    esac
done
[ -z "$bad_form$missing_src" ] && [ -n "$IMPORTS" ] \
    && ok "G-RULES.md: every import is .claude/g-rules/<name>.md backed by a shipped section" \
    || bad "G-RULES.md: wrong-form imports [$bad_form ] / no shipped source [$missing_src ]"

unimported=""; dup=""
for f in "$REPO"/rules/g-rules/*.md; do
    n=$(printf '%s\n' "$IMPORTS" | grep -cx ".claude/g-rules/$(basename "$f")")
    [ "$n" = 0 ] && unimported="$unimported $(basename "$f")"
    [ "$n" -gt 1 ] && dup="$dup $(basename "$f")"
done
[ -z "$unimported$dup" ] \
    && ok "G-RULES.md: each shipped section imported exactly once" \
    || bad "G-RULES.md: not imported [$unimported ] / imported twice [$dup ]"

# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-10-28
autoloaded=$(printf '%s\n' "$IMPORTS" | grep -E '^\.claude/rules/' || true)
[ -z "$autoloaded" ] \
    && ok "G-RULES.md: no import target lives under auto-loaded .claude/rules/" \
    || bad "G-RULES.md: imports auto-loaded files (would load twice): $autoloaded"

# ── 4-7: simulated /g-init scaffold into a temp project ────────────────────
PROJ="$BASE/proj"; mkdir -p "$PROJ"
(cd "$PROJ" && bash "$SCAFFOLD" "$REPO" >/dev/null 2>&1)

# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-10-28
AUTO=$(cd "$PROJ" && find .claude/rules -name '*.md' 2>/dev/null)
[ -z "$AUTO" ] \
    && ok "scaffold: nothing under auto-loaded .claude/rules/" \
    || bad "scaffold: auto-loaded files installed: $(printf '%s ' $AUTO)"

unresolved=""
for imp in $(grep -E '^@' "$PROJ/G-RULES.md" | sed 's/^@//; s/[[:space:]]*$//'); do
    # Claude Code resolves a relative import against the importing file's dir
    [ -f "$PROJ/$(dirname G-RULES.md)/$imp" ] || unresolved="$unresolved $imp"
done
[ -z "$unresolved" ] \
    && ok "scaffold: installed G-RULES.md imports all resolve to installed files" \
    || bad "scaffold: unresolved imports:$unresolved"

miss_ref=""
for f in "$REPO"/rules/references/*.md; do
    [ -f "$PROJ/.claude/g-references/$(basename "$f")" ] || miss_ref="$miss_ref $(basename "$f")"
done
[ -f "$PROJ/.claude/g-references/dispatch-matrix.md" ] || miss_ref="$miss_ref dispatch-matrix.md"
[ -z "$miss_ref" ] \
    && ok "scaffold: every shipped reference + the matrix installed to .claude/g-references/" \
    || bad "scaffold: missing from .claude/g-references/:$miss_ref"

both=""
for imp in $(grep -E '^@' "$PROJ/G-RULES.md" | sed 's/^@//'); do
    case "$imp" in .claude/rules/*) both="$both $imp" ;; esac
    b=$(basename "$imp")
    # both the current name and the pre-ADR-017 g-rules- prefixed name
    for cand in ".claude/rules/$b" ".claude/rules/g-rules-$b"; do
        [ -f "$PROJ/$cand" ] && both="$both $cand"
    done
done
[ -z "$both" ] \
    && ok "scaffold: no section is both imported and auto-loaded" \
    || bad "scaffold: section both imported and auto-loaded:$both"

# ── 8: always-loaded files stay under 200 lines ────────────────────────────
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-10-28
long=""
for f in "$TEMPLATE" "$GRULES" "$REPO"/rules/g-rules/*.md; do
    n=$(wc -l < "$f" | tr -d ' ')
    [ "$n" -lt 200 ] || long="$long ${f#$REPO/}=$n"
done
[ -z "$long" ] \
    && ok "always-loaded sources each under 200 lines" \
    || bad "always-loaded files at/over 200 lines:$long"

# ── 9: template maintainer guidance is a block comment, never an import ────
CMT=$(awk '/^<!--[[:space:]]*$/{inb=1; next} inb && /^-->[[:space:]]*$/{exit} inb{print}' "$TEMPLATE")
if printf '%s\n' "$CMT" | grep -qF '200 lines' \
   && printf '%s\n' "$CMT" | grep -qi 'derive' \
   && ! printf '%s\n' "$CMT" | grep -qF '@'; then
    ok "template: block-comment guidance names the 200-line target and derivable content, holds no '@'"
else
    bad "template: guidance block missing, incomplete, or contains '@'"
fi

# ── 10: every installed-path mention on a live surface resolves ────────────
LIVE="$REPO/skills $REPO/agents $REPO/hooks $REPO/rules $REPO/templates $REPO/g-wiki $REPO/README.md $REPO/G-RULES.md"
dangling=""
for p in $(grep -rhoE '\.claude/g-rules/[A-Za-z0-9-]+\.md' $LIVE | sort -u); do
    [ "$p" = .claude/g-rules/X-name.md ] && continue   # doc placeholder for "any section"
    [ -f "$REPO/rules/g-rules/${p#.claude/g-rules/}" ] || dangling="$dangling $p"
done
for p in $(grep -rhoE '\.claude/g-references/[A-Za-z0-9-]+\.md' $LIVE | sort -u); do
    b=${p#.claude/g-references/}
    if [ "$b" = dispatch-matrix.md ]; then [ -f "$REPO/rules/dispatch-matrix.md" ] || dangling="$dangling $p"
    else [ -f "$REPO/rules/references/$b" ] || dangling="$dangling $p"; fi
done
[ -z "$dangling" ] \
    && ok "live surfaces: every .claude/g-rules/ and .claude/g-references/ path resolves to shipped source" \
    || bad "live surfaces: dangling installed paths:$dangling"

# ── 11: old installed paths survive only at legacy-handling sites ──────────
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-10-28
ALLOW='^(skills/g-doctor/scripts/checks\.sh|skills/g-doctor/references/check-catalog\.md|skills/g-doctor/SKILL\.md|skills/g-update/scripts/migrate-rules-layout\.sh|skills/g-update/SKILL\.md)$'
stale=$(cd "$REPO" && grep -rlE '\.claude/rules/g-rules-|\.claude/rules/references|g-dispatch-matrix' \
        skills agents hooks rules templates g-wiki README.md G-RULES.md 2>/dev/null | grep -vE "$ALLOW")
[ -z "$stale" ] \
    && ok "live surfaces: old install paths only at doctor/update legacy-handling sites" \
    || bad "live surfaces still name old install paths: $(printf '%s ' $stale)"

# ── 12: README section-count word ──────────────────────────────────────────
N_SEC=$(ls -1 "$REPO"/rules/g-rules/*.md | wc -l | tr -d ' ')
WORDS="zero one two three four five six seven eight nine ten eleven twelve"
WANT=$(echo $WORDS | cut -d' ' -f$((N_SEC+1)))
if grep -qF "G-RULES.md has $WANT sections, each installed as a separate file in \`.claude/g-rules/\`" "$REPO/README.md"; then
    ok "README: section-count word ($WANT) matches shipped sections"
else
    bad "README: 'G-RULES.md has $WANT sections, each installed …' sentence not found (shipped: $N_SEC)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

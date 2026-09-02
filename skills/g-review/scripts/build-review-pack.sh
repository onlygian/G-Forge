#!/bin/bash
# build-review-pack.sh — deterministic context-pack builder for the review gates.
#
# Shared by /g-review (--gate code) and /g-doc-review (--gate doc). Run from the
# project root. Prints KEY: value lines for the skill to interpret; always exits
# 0 — every outcome is in the output, never the exit code. The pack replaces the
# manual diff-gathering prose: HQ builds it once, reviewers read it from disk,
# and the diff never rides through a model window or a dispatch prompt.
# Rationale: skills/g-review/references/sentinel-binding.md (ADR-004 — the
# staged∪unstaged-tracked union is what `git commit -a` would fold in, and
# PACK_TREE is the same `git write-tree` hooks/pre-commit hashes at commit time,
# computed on a temp index so the real index is never mutated).
# Note: the mainline resolution ladder below is also stated in
# skills/g-resume/scripts/sync-check.sh (record axis) and was previously
# triplicated in g-review/g-doc-review prose — keep the chain identical.
#
# CLI:
#   --gate code|doc     agent series (code-lead vs doc-reviewer); default code
#   --slug SLUG         request slug for the series; default "review"
#   --path P            scope the reviewed union to a pathspec (doc-gate path mode)
#   --closes FILE       file listing prior-round findings this run claims to close
#   --force-full        force MODE: full (recovery profile / prior ESCALATE / dev request)
#   --check DIR         freshness check only: recompute the tree, compare DIR/MANIFEST
#   --reuse DIR         doc gate: adopt an existing code-gate pack when PACK_TREE
#                       matches and no --path is set; falls through to a build otherwise
#
# Output contract (build mode; every line also written to <pack>/MANIFEST):
#   EXIT: not-a-repo | no-changes        early exits; nothing built
#   PACK_DIR: g-docs/agent-output/review/pack-<YYYY-MM-DD>-<slug>-r<N>
#   ROUND: N                             1 + highest existing ordinal across pack
#                                        dirs AND <agent>-…-r*.md records for the
#                                        date+slug series (highest-plus-one, never
#                                        a count)
#   OUTPUT_FILE: g-docs/agent-output/review/<agent>-<date>-<slug>-r<N>.md
#   MODE: full | delta
#   DELTA_BASE: <tree-sha>               delta only — prior round's PACK_TREE
#   DELTA_INELIGIBLE: <reason>           ROUND>1 yet MODE: full; closed set:
#                                        fix-outside-reviewed-set <path> |
#                                        no-prior-pack | prior-record-missing | forced
#   PACK_TREE: <sha>   PACK_HEAD: <sha>   BRANCH: <name>   MAINLINE: <ref>
#   SCOPE: <path>                        only when --path was given
#   DIFF_SOURCE: staged-union | mainline-fallback
#   FILES: N
#   MANIFEST_CHANGED: true|false         dependency-manifest name match (package.json,
#                                        requirements.txt, Cargo.toml, go.mod, Pipfile,
#                                        pyproject.toml, pom.xml, build.gradle)
#   DOC_SURFACE: <path>                  0+ lines; closed name patterns only (README*,
#                                        CHANGELOG.md, g-docs/env-vars.md,
#                                        g-docs/decisions/*.md, openapi.yaml|json,
#                                        swagger.json)
#   PACK: fresh | stale old=<sha> new=<sha>   --check mode only
#   NOTE: <text>                         0+
#
# Pack layout (immutable once built; one dir per gate-series round, never deleted):
#   MANIFEST · diff.patch (full) · fix-delta.patch + prior/records.txt +
#   prior/claimed-closed.txt (delta) · files.txt · slices/<path with / → __> ·
#   done-conditions.md
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

GATE=code; SLUG=review; SCOPE=""; CLOSES=""; FORCE=0; CHECK_DIR=""; REUSE_DIR=""
while [ $# -gt 0 ]; do
    case "$1" in
        --gate)       GATE="${2:-code}"; shift 2 ;;
        --slug)       SLUG="${2:-review}"; shift 2 ;;
        --path)       SCOPE="${2:-}"; shift 2 ;;
        --closes)     CLOSES="${2:-}"; shift 2 ;;
        --force-full) FORCE=1; shift ;;
        --check)      CHECK_DIR="${2:-}"; shift 2 ;;
        --reuse)      REUSE_DIR="${2:-}"; shift 2 ;;
        *)            out "NOTE: unknown argument $1 ignored"; shift ;;
    esac
done
case "$GATE" in code) AGENT=code-lead ;; doc) AGENT=doc-reviewer ;; *) AGENT=code-lead; out "NOTE: unknown gate '$GATE' — defaulting to code"; GATE=code ;; esac

[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] \
    || { out "EXIT: not-a-repo"; exit 0; }
cd "$(git rev-parse --show-toplevel)" || { out "EXIT: not-a-repo"; exit 0; }

REVIEW_DIR=g-docs/agent-output/review

# ── tree computation — ADR-004's binding, on a temp index (never the real one) ──
compute_tree() {
    # $1: optional pathspec scope
    local idx tmp tree
    idx=$(git rev-parse --git-path index)
    tmp=$(mktemp) || return 1
    [ -f "$idx" ] && cp "$idx" "$tmp" 2>/dev/null
    if [ -n "${1:-}" ]; then
        GIT_INDEX_FILE=$tmp git add -u -- "$1" 2>/dev/null
    else
        GIT_INDEX_FILE=$tmp git add -u 2>/dev/null
    fi
    tree=$(GIT_INDEX_FILE=$tmp git write-tree 2>/dev/null)
    rm -f "$tmp"
    printf '%s' "$tree"
}

# ── --check: freshness only ──────────────────────────────────────────────────
if [ -n "$CHECK_DIR" ]; then
    OLD=""; CK_SCOPE=""
    if [ -f "$CHECK_DIR/MANIFEST" ]; then
        OLD=$(sed -n 's/^PACK_TREE: //p' "$CHECK_DIR/MANIFEST" | head -1)
        CK_SCOPE=$(sed -n 's/^SCOPE: //p' "$CHECK_DIR/MANIFEST" | head -1)
    fi
    NEW=$(compute_tree "$CK_SCOPE")
    if [ -z "$OLD" ]; then
        out "PACK: stale old=missing new=$NEW"
        out "NOTE: $CHECK_DIR/MANIFEST unreadable — treat the pack as unusable and build the next round's pack"
    elif [ "$OLD" = "$NEW" ]; then
        out "PACK: fresh"
    else
        out "PACK: stale old=$OLD new=$NEW"
    fi
    exit 0
fi

BRANCH=$(git branch --show-current); [ -n "$BRANCH" ] || BRANCH=detached
PACK_HEAD=$(git rev-parse --verify -q HEAD 2>/dev/null) || PACK_HEAD=none
PACK_TREE=$(compute_tree "$SCOPE")

# mainline resolution — configured remote else origin; remote HEAD, main, master,
# first that rev-parse verifies (same chain the prose carried; keep identical).
REMOTE=$(git config --get "branch.$BRANCH.remote" 2>/dev/null); [ -n "$REMOTE" ] || REMOTE=origin
CAND=$(git symbolic-ref --short "refs/remotes/$REMOTE/HEAD" 2>/dev/null); CAND=${CAND#"$REMOTE"/}
MAINLINE=""
for name in "$CAND" main master; do
    [ -n "$name" ] || continue
    if git rev-parse --verify -q "$name" >/dev/null 2>&1; then MAINLINE="$name"; break; fi
done
[ -n "$MAINLINE" ] || MAINLINE=unresolved

# ── --reuse: doc gate adopts a code-gate pack when trees match ───────────────
if [ -n "$REUSE_DIR" ] && [ -z "$SCOPE" ] && [ -f "$REUSE_DIR/MANIFEST" ]; then
    RT=$(sed -n 's/^PACK_TREE: //p' "$REUSE_DIR/MANIFEST" | head -1)
    if [ -n "$RT" ] && [ "$RT" = "$PACK_TREE" ]; then
        DATE=$(date +%Y-%m-%d)
        HI=0
        for f in "$REVIEW_DIR/pack-$DATE-$SLUG-r"* "$REVIEW_DIR/$AGENT-$DATE-$SLUG-r"*.md; do
            [ -e "$f" ] || continue
            n=${f##*-r}; n=${n%.md}
            case "$n" in *[!0-9]*|'') continue ;; esac
            [ "$n" -gt "$HI" ] && HI=$n
        done
        ROUND=$((HI + 1))
        out "PACK_DIR: $REUSE_DIR"
        out "ROUND: $ROUND"
        out "OUTPUT_FILE: $REVIEW_DIR/$AGENT-$DATE-$SLUG-r$ROUND.md"
        sed -n 's/^MODE: /MODE: /p' "$REUSE_DIR/MANIFEST" | head -1
        out "PACK_TREE: $PACK_TREE"
        out "PACK_HEAD: $PACK_HEAD"
        out "BRANCH: $BRANCH"
        out "MAINLINE: $MAINLINE"
        out "NOTE: reused code-gate pack $REUSE_DIR — PACK_TREE matches the current tree"
        exit 0
    fi
    out "NOTE: reuse declined — $REUSE_DIR PACK_TREE does not match the current tree; building a fresh pack"
elif [ -n "$REUSE_DIR" ]; then
    out "NOTE: reuse declined — --path set or $REUSE_DIR/MANIFEST unreadable; building a fresh pack"
fi

# ── reviewed diff source: staged∪unstaged-tracked union, else mainline fallback ──
DIFF_SOURCE=""
if [ "$PACK_HEAD" != "none" ]; then
    DIFF_BASE=HEAD
else
    # unborn HEAD (initial-commit review): diff against the empty tree so the
    # pack carries exactly the staged content the sentinel tree binds (ADR-004)
    DIFF_BASE=$(git hash-object -t tree /dev/null)
fi
if [ -n "$SCOPE" ]; then UNION=$(git diff --name-only "$DIFF_BASE" -- "$SCOPE" 2>/dev/null)
else UNION=$(git diff --name-only "$DIFF_BASE" 2>/dev/null); fi
if [ -n "$UNION" ]; then
    DIFF_SOURCE=staged-union
    [ "$PACK_HEAD" = "none" ] && out "NOTE: unborn HEAD — diff base is the empty tree"
elif [ "$MAINLINE" != "unresolved" ] && [ "$PACK_HEAD" != "none" ] \
     && [ -n "$(git diff --name-only "$MAINLINE...HEAD" 2>/dev/null)" ]; then
    DIFF_SOURCE=mainline-fallback
else
    [ "$MAINLINE" = "unresolved" ] && out "NOTE: mainline unresolved — ask the developer what to review"
    out "EXIT: no-changes"
    exit 0
fi

# ── round minting — highest-plus-one across pack dirs AND agent records ──────
DATE=$(date +%Y-%m-%d)
HI=0
for f in "$REVIEW_DIR/pack-$DATE-$SLUG-r"* "$REVIEW_DIR/$AGENT-$DATE-$SLUG-r"*.md; do
    [ -e "$f" ] || continue
    n=${f##*-r}; n=${n%.md}
    case "$n" in *[!0-9]*|'') continue ;; esac
    [ "$n" -gt "$HI" ] && HI=$n
done
ROUND=$((HI + 1))
PACK_DIR="$REVIEW_DIR/pack-$DATE-$SLUG-r$ROUND"
OUTPUT_FILE="$REVIEW_DIR/$AGENT-$DATE-$SLUG-r$ROUND.md"

# ── delta eligibility (deterministic; HQ never eyeballs it) ──────────────────
MODE=full; DELTA_BASE=""; INELIGIBLE=""
if [ "$ROUND" -gt 1 ]; then
    if [ "$FORCE" = 1 ]; then
        INELIGIBLE=forced
    else
        # prior pack: highest rK < ROUND with a readable MANIFEST
        PRIOR_PACK=""
        k=$((ROUND - 1))
        while [ "$k" -ge 1 ]; do
            if [ -f "$REVIEW_DIR/pack-$DATE-$SLUG-r$k/MANIFEST" ]; then
                PRIOR_PACK="$REVIEW_DIR/pack-$DATE-$SLUG-r$k"; break
            fi
            k=$((k - 1))
        done
        if [ -z "$PRIOR_PACK" ]; then
            INELIGIBLE=no-prior-pack
        else
            DELTA_BASE=$(sed -n 's/^PACK_TREE: //p' "$PRIOR_PACK/MANIFEST" | head -1)
            [ -n "$DELTA_BASE" ] || INELIGIBLE=no-prior-pack
        fi
        if [ -z "$INELIGIBLE" ]; then
            k=1
            while [ "$k" -lt "$ROUND" ]; do
                if [ ! -f "$REVIEW_DIR/$AGENT-$DATE-$SLUG-r$k.md" ]; then
                    INELIGIBLE=prior-record-missing; break
                fi
                k=$((k + 1))
            done
        fi
        if [ -z "$INELIGIBLE" ]; then
            # every name in the tree-to-tree fix delta must be in the prior files.txt
            PRIOR_SET=$(cut -f2- "$PRIOR_PACK/files.txt" 2>/dev/null | tr '\t' '\n')
            OUT_OF_SET=""
            while IFS= read -r p; do
                [ -n "$p" ] || continue
                printf '%s\n' "$PRIOR_SET" | grep -qxF "$p" || { OUT_OF_SET="$p"; break; }
            done <<EOF
$(git diff --name-only "$DELTA_BASE" "$PACK_TREE" 2>/dev/null)
EOF
            if [ -n "$OUT_OF_SET" ]; then
                INELIGIBLE="fix-outside-reviewed-set $OUT_OF_SET"
            else
                MODE=delta
            fi
        fi
    fi
fi

# ── build the pack ───────────────────────────────────────────────────────────
mkdir -p "$PACK_DIR/slices"
MANIFEST="$PACK_DIR/MANIFEST"
: > "$MANIFEST"
emit() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$MANIFEST"; }

if [ "$MODE" = delta ]; then
    git diff "$DELTA_BASE" "$PACK_TREE" > "$PACK_DIR/fix-delta.patch" 2>/dev/null
    git diff --name-status "$DELTA_BASE" "$PACK_TREE" > "$PACK_DIR/files.txt" 2>/dev/null
    mkdir -p "$PACK_DIR/prior"
    : > "$PACK_DIR/prior/records.txt"
    k=1
    while [ "$k" -lt "$ROUND" ]; do
        printf '%s\n' "$REVIEW_DIR/$AGENT-$DATE-$SLUG-r$k.md" >> "$PACK_DIR/prior/records.txt"
        k=$((k + 1))
    done
    if [ -n "$CLOSES" ] && [ -f "$CLOSES" ]; then
        cp "$CLOSES" "$PACK_DIR/prior/claimed-closed.txt"
    else
        : > "$PACK_DIR/prior/claimed-closed.txt"
        [ -n "$CLOSES" ] && out "NOTE: --closes file $CLOSES unreadable — claimed-closed.txt left empty"
    fi
elif [ "$DIFF_SOURCE" = staged-union ]; then
    if [ -n "$SCOPE" ]; then
        git diff "$DIFF_BASE" "$PACK_TREE" -- "$SCOPE" > "$PACK_DIR/diff.patch" 2>/dev/null
        git diff --name-status "$DIFF_BASE" "$PACK_TREE" -- "$SCOPE" > "$PACK_DIR/files.txt" 2>/dev/null
    else
        git diff "$DIFF_BASE" "$PACK_TREE" > "$PACK_DIR/diff.patch" 2>/dev/null
        git diff --name-status "$DIFF_BASE" "$PACK_TREE" > "$PACK_DIR/files.txt" 2>/dev/null
    fi
else
    git diff "$MAINLINE...HEAD" > "$PACK_DIR/diff.patch" 2>/dev/null
    git diff --name-status "$MAINLINE...HEAD" > "$PACK_DIR/files.txt" 2>/dev/null
fi
if [ "$MODE" = full ] && [ -n "$CLOSES" ] && [ -f "$CLOSES" ]; then
    mkdir -p "$PACK_DIR/prior"
    cp "$CLOSES" "$PACK_DIR/prior/claimed-closed.txt"
fi

# slices — full current content of every file in files.txt (never truncated)
FILE_COUNT=0
while IFS= read -r p; do
    [ -n "$p" ] || continue
    FILE_COUNT=$((FILE_COUNT + 1))
    [ -f "$p" ] || continue          # deleted files have no current content
    cp "$p" "$PACK_DIR/slices/$(printf '%s' "$p" | sed 's,/,__,g')" 2>/dev/null
done <<EOF
$(cut -f2- "$PACK_DIR/files.txt" 2>/dev/null | tr '\t' '\n' | awk 'NF' | sort -u)
EOF

# done-conditions.md — fetched, not judged: newest plan + active milestone ## Scope
{
    printf '# Done conditions (fetched by build-review-pack.sh — HQ confirms/overrides)\n\n'
    NEWEST_PLAN=$(ls -t g-docs/plans/*.md 2>/dev/null | head -1)
    if [ -n "$NEWEST_PLAN" ]; then
        printf '## Plan candidate: %s\n\n' "$NEWEST_PLAN"
        cat "$NEWEST_PLAN"
        printf '\n'
    else
        printf 'No plan files found in g-docs/plans/.\n\n'
    fi
    for m in g-docs/milestones/*.md; do
        [ -f "$m" ] || continue
        grep -q "🔄 In progress" "$m" 2>/dev/null || continue
        printf '## Active milestone scope: %s\n\n' "$m"
        awk '/^## Scope/{f=1} f && /^## / && !/^## Scope/{exit} f' "$m"
        printf '\n'
    done
} > "$PACK_DIR/done-conditions.md" 2>/dev/null

# ── MANIFEST + stdout ────────────────────────────────────────────────────────
emit "PACK_DIR: $PACK_DIR"
emit "ROUND: $ROUND"
emit "OUTPUT_FILE: $OUTPUT_FILE"
emit "MODE: $MODE"
[ "$MODE" = delta ] && emit "DELTA_BASE: $DELTA_BASE"
[ -n "$INELIGIBLE" ] && emit "DELTA_INELIGIBLE: $INELIGIBLE"
emit "PACK_TREE: $PACK_TREE"
emit "PACK_HEAD: $PACK_HEAD"
emit "BRANCH: $BRANCH"
emit "MAINLINE: $MAINLINE"
[ -n "$SCOPE" ] && emit "SCOPE: $SCOPE"
emit "DIFF_SOURCE: $DIFF_SOURCE"
emit "FILES: $FILE_COUNT"

MANIFEST_CHANGED=false
DOCLINES=""
while IFS= read -r p; do
    [ -n "$p" ] || continue
    base=${p##*/}
    case "$base" in
        package.json|requirements.txt|Cargo.toml|go.mod|Pipfile|pyproject.toml|pom.xml|build.gradle)
            MANIFEST_CHANGED=true ;;
    esac
    case "$base" in
        README*|CHANGELOG.md|openapi.yaml|openapi.json|swagger.json)
            DOCLINES="$DOCLINES$p
" ;;
    esac
    case "$p" in
        g-docs/env-vars.md) DOCLINES="$DOCLINES$p
" ;;
        g-docs/decisions/*.md) DOCLINES="$DOCLINES$p
" ;;
    esac
done <<EOF
$(cut -f2- "$PACK_DIR/files.txt" 2>/dev/null | tr '\t' '\n' | awk 'NF' | sort -u)
EOF
emit "MANIFEST_CHANGED: $MANIFEST_CHANGED"
printf '%s' "$DOCLINES" | sort -u | while IFS= read -r p; do
    [ -n "$p" ] && printf 'DOC_SURFACE: %s\n' "$p" | tee -a "$MANIFEST"
done

exit 0

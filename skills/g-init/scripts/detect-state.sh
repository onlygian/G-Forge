#!/bin/bash
# detect-state.sh — deterministic implementation of /g-init Steps 1a + 1b
# (source-root resolution, initialized check, brief check, directory class).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. Rationale for the consumer-vs-self-host split lives in
# ../references/self-host.md.
#
# Output contract:
#   SELF_HOST: on|off       root .claude-plugin/plugin.json exists AND its
#                           name is g-forge → on (source root = working tree)
#   PLUGIN_ROOT: <path>     working tree when SELF_HOST is on; the
#                           highest-versioned plugin-cache dir when off
#   CACHE_MISSING: yes      printed only when SELF_HOST is off and no cache
#                           dir could be resolved (no PLUGIN_ROOT printed)
#   INITIALIZED: yes|no     .claude/integration-tier exists AND CLAUDE.md
#                           contains '<!-- G-Forge Rules'
#   BRIEF: present|absent   g-docs/project_brief.md exists
#   CLASS: existing|greenfield|ambiguous
#                           existing = a dependency manifest, source dirs, or
#                           more than a couple of commits of real code;
#                           greenfield = nothing beyond docs/README;
#                           ambiguous = the skill judges the signals or asks
#                           the developer (CLASS is a signal, not a verdict —
#                           the skill's judgment may override it)
#   MANIFEST: <file>        0+ evidence lines, one per manifest found
#   COMMITS: <n>            commit count on HEAD when the project root is a
#                           git toplevel (0 otherwise) — evidence for the
#                           commits-of-real-code disjunct
#   NOTE: <text>            0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

# ── Step 1a — self-host detection ───────────────────────────────────────────
SELF_HOST=off
if [ -f .claude-plugin/plugin.json ]; then
    NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' .claude-plugin/plugin.json 2>/dev/null \
           | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    [ "$NAME" = "g-forge" ] && SELF_HOST=on
fi
out "SELF_HOST: $SELF_HOST"

if [ "$SELF_HOST" = "on" ]; then
    out "PLUGIN_ROOT: $PWD"
else
    CACHE="${GF_PLUGIN_CACHE_DIR:-$HOME/.claude/plugins/cache/g-forge/g-forge}"
    BEST=""
    if [ -d "$CACHE" ]; then
        # Highest version wins: numeric sort on dot-separated segments.
        BEST=$(ls -1 "$CACHE" 2>/dev/null | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
    fi
    if [ -n "$BEST" ] && [ -d "$CACHE/$BEST" ]; then
        out "PLUGIN_ROOT: $CACHE/$BEST"
    else
        out "CACHE_MISSING: yes"
        out "NOTE: no plugin cache found under $CACHE — reinstall with /plugin install g-forge"
    fi
fi

# ── Step 1b — already initialized? ──────────────────────────────────────────
INIT=no
if [ -f .claude/integration-tier ] && [ -f CLAUDE.md ] \
   && grep -qF -- '<!-- G-Forge Rules' CLAUDE.md 2>/dev/null; then
    INIT=yes
fi
out "INITIALIZED: $INIT"

# ── Step 1b — brief present? ────────────────────────────────────────────────
if [ -f g-docs/project_brief.md ]; then out "BRIEF: present"; else out "BRIEF: absent"; fi

# ── Step 1b — classify the directory ────────────────────────────────────────
# Dependency-manifest closed set (byte-identical to the prose it replaces):
# package.json, pyproject.toml, Cargo.toml, go.mod, Gemfile, composer.json,
# pubspec.yaml, *.csproj, pom.xml/build.gradle.
MANIFESTS=0
for m in package.json pyproject.toml Cargo.toml go.mod Gemfile composer.json \
         pubspec.yaml pom.xml build.gradle; do
    if [ -f "$m" ]; then out "MANIFEST: $m"; MANIFESTS=$((MANIFESTS+1)); fi
done
for c in *.csproj; do
    if [ -f "$c" ]; then out "MANIFEST: $c"; MANIFESTS=$((MANIFESTS+1)); fi
done

# Commit history — evidence for the third 'existing' disjunct ("more than a
# couple of commits of real code"). Counted only when the project root is
# itself the git toplevel, so a parent repo's history never bleeds in.
COMMITS=0
TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$TOPLEVEL" ] && [ "$TOPLEVEL" = "$(pwd -P)" ]; then
    COMMITS=$(git rev-list --count HEAD 2>/dev/null)
    [ -n "$COMMITS" ] || COMMITS=0
fi
out "COMMITS: $COMMITS"

# Source directories count as real source too. This set is a signal, not
# exhaustive — the skill may override CLASS on its own read of the tree
# (e.g. real code in lib/ or cmd/).
SRCDIR=no
for d in src app source; do
    if [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ]; then SRCDIR=yes; fi
done

# Anything beyond docs/README/G-Forge files at the root?
NONDOC=no
for f in * .[!.]*; do
    [ -e "$f" ] || continue
    case "$f" in
        *.md|LICENSE*|docs|g-docs|g-wiki|.git|.claude|.claude-plugin|.gitignore) : ;;
        *) NONDOC=yes ;;
    esac
done

CLASS=ambiguous
if [ "$MANIFESTS" -gt 0 ] || [ "$SRCDIR" = yes ]; then
    CLASS=existing
elif [ "$NONDOC" = yes ] && [ "$COMMITS" -gt 2 ]; then
    # More than a couple of commits of real code → existing.
    CLASS=existing
elif [ "$NONDOC" = no ]; then
    CLASS=greenfield
fi
# NONDOC=yes with no manifest, no source dir, and ≤2 commits stays
# ambiguous — the skill judges the signals or asks the developer one
# routing question.
out "CLASS: $CLASS"
exit 0

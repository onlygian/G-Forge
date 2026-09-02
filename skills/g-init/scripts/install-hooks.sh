#!/bin/bash
# install-hooks.sh <plugin-root> — deterministic implementation of /g-init
# Steps 6 + 6a (hook copy, tier marker, native pre-commit gate + its lib/).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. Rationale (divergence history, ADR-004 authority, ADR-011
# derive-don't-type) lives in ../references/hook-install-notes.md.
#
# Ordering is load-bearing: the integration-tier marker is written BEFORE
# any hook is copied — every hook self-guards on it and stays inert without
# it. The install set is derived from disk (ls hooks/*.sh hooks/lib/*.sh
# pre-commit), never a typed list (ADR-011). Foreign pre-commit hooks are
# never overwritten (detected by the 'G-Forge commit gate' header literal).
#
# Output contract:
#   TIER_MARKER: created|exists     .claude/integration-tier ('full' when new)
#   COPIED: <dest>                  per file installed into .claude/hooks/
#   MISSING: <plugin-hooks>/<rel>   source not found / copy failed / a lib the
#                                   cache's own hooks source is absent from
#                                   lib/ — per individually missing file
#                                   (derived from the hooks' lib/<name>.sh
#                                   references, never a typed list, ADR-011);
#                                   the skill prints its pinned stop message
#   GITHOOKS_DIR: <path>            git rev-parse --git-path hooks
#   PRECOMMIT: installed|updated|foreign
#                                   installed = fresh copy; updated = previous
#                                   G-Forge install overwritten; foreign =
#                                   non-G-Forge hook left untouched (nothing
#                                   installed on that branch, lib/ included)
#   GITHOOK_LIBS: <n>               lib scripts copied into <git-hooks-dir>/lib/
#   NOTE: <text>                    0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

PLUGIN_ROOT="${1:-}"
SRC="$PLUGIN_ROOT/hooks"
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$SRC" ]; then
    out "MISSING: $SRC"
    out "NOTE: plugin hooks directory not found — nothing installed"
    exit 0
fi

# ── Tier marker FIRST (hooks self-guard on it) ──────────────────────────────
mkdir -p .claude
if [ -f .claude/integration-tier ]; then
    out "TIER_MARKER: exists"
else
    printf 'full\n' > .claude/integration-tier
    out "TIER_MARKER: created"
fi

# ── Step 6 — copy hooks + lib/ into .claude/hooks/ (derived from disk) ──────
mkdir -p .claude/hooks/lib

FOUND_TOP=0
for f in "$SRC"/*.sh; do
    [ -f "$f" ] || continue
    FOUND_TOP=1
    b=$(basename "$f")
    if cp "$f" ".claude/hooks/$b" 2>/dev/null; then
        chmod +x ".claude/hooks/$b" 2>/dev/null  # best effort (Windows)
        out "COPIED: .claude/hooks/$b"
    else
        out "MISSING: $SRC/$b"
    fi
done
[ "$FOUND_TOP" = 1 ] || out "MISSING: $SRC/*.sh"

FOUND_LIB=0
for f in "$SRC"/lib/*.sh; do
    [ -f "$f" ] || continue
    FOUND_LIB=1
    b=$(basename "$f")
    if cp "$f" ".claude/hooks/lib/$b" 2>/dev/null; then
        out "COPIED: .claude/hooks/lib/$b"
    else
        out "MISSING: $SRC/lib/$b"
    fi
done
[ "$FOUND_LIB" = 1 ] || out "MISSING: $SRC/lib/*.sh"

# Per-file completeness check (ADR-011 derive-don't-type): the canonical lib
# set is whatever the cache's own hooks reference — derive it from their
# lib/<name>.sh lines and report each individually absent file, so a cache
# missing a single lib (the 4-of-6 class) stops the install by name instead
# of installing a partial set silently.
for need in $(grep -rhoE 'lib/[a-z0-9-]+\.sh' "$SRC"/*.sh "$SRC/pre-commit" 2>/dev/null \
              | sed 's|^lib/||' | sort -u); do
    [ -f "$SRC/lib/$need" ] || out "MISSING: $SRC/lib/$need"
done

# ── Step 6a — native pre-commit gate + <git-hooks-dir>/lib/ ─────────────────
GITHOOKS=$(git rev-parse --git-path hooks 2>/dev/null)
if [ -z "$GITHOOKS" ]; then
    out "NOTE: not a git repository — native pre-commit gate skipped"
    exit 0
fi
out "GITHOOKS_DIR: $GITHOOKS"

if [ ! -f "$SRC/pre-commit" ]; then
    out "MISSING: $SRC/pre-commit"
    exit 0
fi

MODE=""
if [ ! -f "$GITHOOKS/pre-commit" ]; then
    MODE=installed
elif head -5 "$GITHOOKS/pre-commit" 2>/dev/null | grep -qF 'G-Forge commit gate'; then
    MODE=updated
else
    out "PRECOMMIT: foreign"
    exit 0
fi

mkdir -p "$GITHOOKS"
if cp "$SRC/pre-commit" "$GITHOOKS/pre-commit" 2>/dev/null; then
    chmod +x "$GITHOOKS/pre-commit" 2>/dev/null  # best effort
    out "PRECOMMIT: $MODE"
else
    out "MISSING: $SRC/pre-commit"
    exit 0
fi

# Enumerate the lib set from disk — never a typed list (ADR-011).
mkdir -p "$GITHOOKS/lib"
N=0
for f in "$SRC"/lib/*.sh; do
    [ -f "$f" ] || continue
    if cp "$f" "$GITHOOKS/lib/$(basename "$f")" 2>/dev/null; then
        N=$((N+1))
    else
        out "MISSING: $SRC/lib/$(basename "$f")"
    fi
done
out "GITHOOK_LIBS: $N"
exit 0

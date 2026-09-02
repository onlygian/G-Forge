#!/bin/bash
# preflight.sh — deterministic implementation of /g-update Step 0 (staleness
# preflight) + Step 0a (legacy g-team detection).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome lives in the output, never the
# exit code. Rationale for each branch lives in
# ../references/preflight-rationale.md (keep both in sync when editing).
# Cross-ref: g-dev/fixtures/g-update-staleness-preflight.sh sandbox-proves
# this same contract; /g-doctor Check 23 resolves the same version triple
# read-only. All three source hooks/lib/semver-compare.sh — one ordering
# contract (ADR-009), never a hand-rolled compare or `sort -V`.
#
# Output contract:
#   SELF_HOST: on|off               root plugin.json name-matches g-forge
#   PLUGIN_ROOT: <path>|MISSING     source root (self-host: project root;
#                                   consumer: versioned cache dir)
#   CACHE_VERSION: <v>|unknown|none none = no cache dir at all
#   GITHUB_VERSION: <v>|unreachable (consumer only; curl bounded --max-time 10)
#   INSTALLED_VERSION: <v>|unknown  no project version stamp exists today
#   COMPARE: cache-current|cache-stale|github-unreachable|no-cache|cannot-compare
#   GTEAM: found|absent             omitted when COMPARE: cache-stale ends the
#                                   run (the skill stops before Step 0a) and in
#                                   self-host mode (no cache surface at all)
#   GTEAM_PATH: <path>              0+ — each probe hit
#   NOTE: <text>                    0+ — reprint each verbatim
#   BANNER_BEGIN: stale|unreachable|gteam ... BANNER_END
#                                   block for the skill to reprint verbatim
#
# Self-host short-circuits BEFORE any network call — self-host runs stay
# offline-clean; the curl only ever fires on the consumer branch.
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEMVER_LIB="$SCRIPT_DIR/../../../hooks/lib/semver-compare.sh"

# ── Self-host detection (before anything else — no cache, no network) ──────
if [ -f .claude-plugin/plugin.json ] \
   && grep -q '"name"[[:space:]]*:[[:space:]]*"g-forge"' .claude-plugin/plugin.json; then
    out "SELF_HOST: on"
    out "PLUGIN_ROOT: $PWD"
    out "NOTE: ✓ Self-host mode detected — working tree is source, skipping cache version check."
    exit 0
fi
out "SELF_HOST: off"

HAVE_LIB=0
if [ -f "$SEMVER_LIB" ]; then
    # shellcheck disable=SC1090
    . "$SEMVER_LIB" && HAVE_LIB=1
fi
[ "$HAVE_LIB" = 1 ] || out "NOTE: hooks/lib/semver-compare.sh not found beside this script — version ordering unavailable."

json_version() {
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" 2>/dev/null | head -1
}

# ── Resolve the version triple ─────────────────────────────────────────────
CACHE_BASE="$HOME/.claude/plugins/cache/g-forge/g-forge"
PLUGIN_ROOT=""
BEST_VER=""
if [ -d "$CACHE_BASE" ]; then
    for d in "$CACHE_BASE"/*/; do
        [ -d "$d" ] || continue
        v=$(basename "$d")
        if [ -z "$BEST_VER" ]; then
            PLUGIN_ROOT="${d%/}"; BEST_VER="$v"
        elif [ "$HAVE_LIB" = 1 ]; then
            cmp=$(gf_semver_compare "$v" "$BEST_VER") && \
                [ "$cmp" = "1" ] && { PLUGIN_ROOT="${d%/}"; BEST_VER="$v"; }
        fi
    done
fi

CACHE_VERSION=""
if [ -n "$PLUGIN_ROOT" ]; then
    CACHE_VERSION=$(json_version "$PLUGIN_ROOT/.claude-plugin/plugin.json")
    [ -n "$CACHE_VERSION" ] || CACHE_VERSION="unknown"
    out "PLUGIN_ROOT: $PLUGIN_ROOT"
    out "CACHE_VERSION: $CACHE_VERSION"
else
    out "PLUGIN_ROOT: MISSING"
    out "CACHE_VERSION: none"
fi

# No project version stamp is recorded anywhere today (Step 2's inventory
# records presence, not versions) — unknown unless a future manifest lands.
INSTALLED="unknown"
out "INSTALLED_VERSION: $INSTALLED"

if [ -z "$PLUGIN_ROOT" ]; then
    out "COMPARE: no-cache"
    out "NOTE: no plugin cache found — nothing can be stale; Step 1 will report the missing-plugin error."
else
    GH_JSON=$(curl -sf --max-time 10 https://raw.githubusercontent.com/onlygian/G-Forge/main/.claude-plugin/plugin.json 2>/dev/null)
    CURL_RC=$?
    LATEST=""
    [ $CURL_RC -eq 0 ] && LATEST=$(printf '%s\n' "$GH_JSON" \
        | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

    if [ $CURL_RC -ne 0 ] || [ -z "$LATEST" ]; then
        out "GITHUB_VERSION: unreachable"
        out "COMPARE: github-unreachable"
        out "BANNER_BEGIN: unreachable"
        out "⚠ GitHub unreachable — cannot confirm the cache is current."
        out "  Cache version:              v$CACHE_VERSION"
        out "  Project-installed version:  v$INSTALLED"
        out ""
        out "Proceeding from a cache-vs-installed comparison only — this cannot detect a stale cache."
        out "If you suspect the cache is behind, update it via /plugins before trusting this sync."
        out "BANNER_END"
    else
        out "GITHUB_VERSION: $LATEST"
        CMP="0"; CMP_RC=1
        if [ "$HAVE_LIB" = 1 ]; then
            CMP=$(gf_semver_compare "$CACHE_VERSION" "$LATEST"); CMP_RC=$?
        fi
        if [ $CMP_RC -ne 0 ]; then
            # Malformed/uncomparable — degrade loudly like the unreachable
            # branch, never assume the cache is current.
            out "COMPARE: cannot-compare"
            out "NOTE: ⚠ Version strings could not be compared (v$CACHE_VERSION vs v$LATEST) — cannot confirm the cache is current."
            out "NOTE: Proceeding from a cache-vs-installed comparison only — this cannot detect a stale cache. If you suspect the cache is behind, update it via /plugins before trusting this sync."
        elif [ "$CMP" = "-1" ]; then
            out "COMPARE: cache-stale"
            out "BANNER_BEGIN: stale"
            out "⚠ Cannot sync — plugin cache is behind GitHub (v$CACHE_VERSION installed, v$LATEST available)."
            out "  Project-installed version: v$INSTALLED"
            out ""
            out "/g-update cannot fix this itself — it only syncs this project from the cache, and the"
            out "cache is behind. Syncing now would silently install OLD files into this project."
            out ""
            out "Update the plugin cache first:"
            out "  /plugins  →  Installed  →  g-forge  →  Update now"
            out ""
            out "Then re-run /g-update to sync your project files."
            out "BANNER_END"
            exit 0    # zero writes this run — the skill stops before Step 0a
        else
            out "COMPARE: cache-current"
            out "NOTE: ✓ Plugin cache already at latest (v$CACHE_VERSION) — proceeding with project sync."
        fi
    fi
fi

# ── Step 0a — legacy g-team detection ──────────────────────────────────────
GTEAM_FOUND=0
if [ -d "$HOME/.claude/plugins/cache/g-team" ]; then
    GTEAM_FOUND=1
    out "GTEAM_PATH: $HOME/.claude/plugins/cache/g-team"
fi
for cfg in "$HOME/.claude/plugins/config.json" "$HOME/.claude/settings.json"; do
    if [ -f "$cfg" ] && grep -q '"g-team"' "$cfg" 2>/dev/null; then
        GTEAM_FOUND=1
        out "GTEAM_PATH: $cfg"
    fi
done

if [ "$GTEAM_FOUND" = 1 ]; then
    out "GTEAM: found"
    out "BANNER_BEGIN: gteam"
    out '⚠ Legacy "g-team" plugin still installed — it duplicates every /g-* command.'
    out "  g-team was renamed to g-forge; the old plugin must be removed."
    out ""
    out "  Remove it:"
    out "    /plugin  →  Installed  →  g-team  →  Uninstall"
    out "    (or: /plugin uninstall g-team, then remove any g-team marketplace entry)"
    out ""
    out "  Then re-run /g-update."
    out "BANNER_END"
else
    out "GTEAM: absent"
    out "NOTE: ✓ No legacy g-team plugin — commands are g-forge only."
fi

exit 0

#!/bin/bash
# Pins .claude-plugin/plugin.json's "agents" array against the agents/*.md
# directory listing (ADR-013 rule 1: consumers derive, never restate — but a
# typed list in plugin.json is permitted here because it is the manifest
# schema's declared mechanism for turning off the plugin loader's directory
# auto-scan; this suite is the pin that makes the typed list legitimate).
#
# WHY this matters: the plugin loader treats every .md file directly under
# agents/ as a dispatchable agent unless "agents" is explicitly set in
# plugin.json — at which point auto-load is disabled and only the listed
# paths register. agents/references/*.md holds 15 reference documents that
# must never register as agents; declaring the 19 real agents here is what
# keeps them out. If the manifest list and the directory ever disagree —
# a path added to agents/ but not to plugin.json, or a stale path left in
# plugin.json after a file is removed — this suite goes red.
#
# Assertion is SET EQUALITY on the sorted path sets, not count equality —
# a count-only check would pass a misspelled path paired with a missing one.
#
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-09-03

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
AGENTS_DIR="$REPO_ROOT/agents"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# ── Preconditions ─────────────────────────────────────────────────────────────

[ -f "$PLUGIN_JSON" ] || { echo "FAIL: .claude-plugin/plugin.json not found"; echo ""; echo "Results: 0 passed, 1 failed"; exit 1; }
[ -d "$AGENTS_DIR" ] || { echo "FAIL: agents/ directory not found"; echo ""; echo "Results: 0 passed, 1 failed"; exit 1; }

# ── Extraction: manifest "agents" array vs agents/*.md directory listing ────

# Extracts the "agents" array from a plugin.json-shaped file as a sorted,
# newline-separated list of basenames (without ./ prefix or .md suffix).
# Uses jq when available (exact JSON array parse); falls back to grep+sed on
# the array's string literals otherwise.
extract_manifest_agents() {
    local file="$1"
    if command -v jq >/dev/null 2>&1; then
        jq -r '.agents[]?' "$file" | sed -e 's#^\./agents/##' -e 's/\.md$//' | sort
    else
        awk '/"agents"[[:space:]]*:/{f=1} f{print} f && /\]/{exit}' "$file" \
            | grep -o '"\./agents/[^"]*\.md"' \
            | sed -e 's/^"//' -e 's/"$//' -e 's#^\./agents/##' -e 's/\.md$//' \
            | sort
    fi
}

# Derives the real agent basenames from the agents/*.md glob directly
# (references/ is a subdirectory and is not matched by the *.md glob).
derive_dir_agents() {
    local dir="$1"
    for f in "$dir"/*.md; do
        [ -f "$f" ] || continue
        basename "$f" .md
    done | sort
}

MANIFEST_AGENTS=$(extract_manifest_agents "$PLUGIN_JSON")
DIR_AGENTS=$(derive_dir_agents "$AGENTS_DIR")

if [ -n "$MANIFEST_AGENTS" ]; then
    pass "manifest agents array extracted — $(printf '%s\n' "$MANIFEST_AGENTS" | grep -c .) entries"
else
    fail "manifest agents array extraction returned empty (from $PLUGIN_JSON)"
fi

if [ -n "$DIR_AGENTS" ]; then
    pass "agents/*.md directory listing derived — $(printf '%s\n' "$DIR_AGENTS" | grep -c .) entries"
else
    fail "agents/*.md directory listing returned empty (from $AGENTS_DIR)"
fi

# ── Test: set equality between manifest list and directory listing ──────────

if [ "$MANIFEST_AGENTS" = "$DIR_AGENTS" ]; then
    pass "manifest agents array and agents/*.md directory agree (set equality)"
else
    fail "manifest agents array and agents/*.md directory disagree"
    ONLY_IN_MANIFEST=$(comm -23 <(printf '%s\n' "$MANIFEST_AGENTS") <(printf '%s\n' "$DIR_AGENTS"))
    ONLY_IN_DIR=$(comm -13 <(printf '%s\n' "$MANIFEST_AGENTS") <(printf '%s\n' "$DIR_AGENTS"))
    [ -n "$ONLY_IN_MANIFEST" ] && echo "    only in plugin.json agents[]: $(printf '%s ' $ONLY_IN_MANIFEST)"
    [ -n "$ONLY_IN_DIR" ] && echo "    only in agents/*.md:          $(printf '%s ' $ONLY_IN_DIR)"
fi

# ── Test: manifest paths use the ./agents/NAME.md form (schema convention) ──

if command -v jq >/dev/null 2>&1; then
    BAD_PATHS=$(jq -r '.agents[]?' "$PLUGIN_JSON" | grep -v '^\./agents/[^/]*\.md$' || true)
    if [ -z "$BAD_PATHS" ]; then
        pass "all manifest agent paths use the ./agents/NAME.md form"
    else
        fail "manifest agent paths not in ./agents/NAME.md form: $(printf '%s ' $BAD_PATHS)"
    fi
else
    echo "PASS: path-form check skipped (jq unavailable) — set-equality test above already covers basename correctness"
    PASS=$((PASS+1))
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

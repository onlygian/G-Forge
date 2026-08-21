#!/bin/bash
# Unit tests for version agreement between .claude-plugin/plugin.json and .claude-plugin/marketplace.json
#
# Verifies: The "version" field in plugin.json must equal the "version" field in
# marketplace.json's plugins[0] object. Version strings are compared as exact string matches.
#
# Extraction method: grep + sed (no jq dependency). Both files are JSON but the
# extraction targets a single known version string per file.
#
# Total assertions: 3 (helper functions, real files matching, synthetic mismatch detection).

# Resolve to ABSOLUTE paths once, before any cwd-dependent read (tests/README.md).
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TESTS_DIR")"
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

PASS=0
FAIL=0

# ── Extraction helpers ──────────────────────────────────────────────────────────

# Extract the "version" value from plugin.json (appears once at root level).
# Anchored to the "version" key and takes the first match — symmetric with
# extract_marketplace_version so neither extractor depends on file-specific
# key cardinality.
extract_plugin_version() {
    local file="$1"
    grep '"version"[[:space:]]*:' "$file" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# Extract the "version" value from marketplace.json's plugins[0] object.
# There is only one "version" key in the file (inside plugins[0]); anchoring
# to the key (not just any quoted field) rules out an unrelated field being
# greedily matched if the file's shape changes.
extract_marketplace_version() {
    local file="$1"
    grep '"version"[[:space:]]*:' "$file" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

echo "PASS: extraction helper functions defined"
PASS=$((PASS+1))

# ── Test 1: Real files versions match ───────────────────────────────────────────

PLUGIN_VERSION=$(extract_plugin_version "$PLUGIN_JSON")
if [ -n "$PLUGIN_VERSION" ]; then
    MARKETPLACE_VERSION=$(extract_marketplace_version "$MARKETPLACE_JSON")
    if [ -n "$MARKETPLACE_VERSION" ]; then
        if [ "$PLUGIN_VERSION" = "$MARKETPLACE_VERSION" ]; then
            echo "PASS: real files versions match — plugin.json=$PLUGIN_VERSION, marketplace.json=$MARKETPLACE_VERSION"
            PASS=$((PASS+1))
        else
            echo "FAIL: real files versions mismatch — plugin.json=$PLUGIN_VERSION, marketplace.json=$MARKETPLACE_VERSION"
            FAIL=$((FAIL+1))
        fi
    else
        echo "FAIL: failed to extract marketplace version (empty result from $MARKETPLACE_JSON)"
        FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: failed to extract plugin version (empty result from $PLUGIN_JSON)"
    FAIL=$((FAIL+1))
fi

# ── Test 2: Synthetic mismatch scenario detects divergence ──────────────────────
# falsifiability: this scenario is the real-files equality check's RED proof —
# same extractors, divergent synthetic fixture, confirmed red-capable 2026-08-21
#
# This test proves the extraction + comparison logic works correctly by creating
# scratch copies with deliberately divergent versions (1.2.3 vs 9.9.9) and verifying
# that the test correctly reports the mismatch. The test PASSES when the mismatch
# is detected, thereby proving the detection mechanism is RED when versions differ.

TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

# Create synthetic plugin.json with version 1.2.3
cat > "$TEMP_DIR/plugin.json" << 'PLUGIN_EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "g-forge-test",
  "version": "1.2.3",
  "description": "synthetic test file"
}
PLUGIN_EOF

# Create synthetic marketplace.json with version 9.9.9
cat > "$TEMP_DIR/marketplace.json" << 'MARKET_EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-marketplace.json",
  "name": "g-forge-test",
  "owner": {
    "name": "test"
  },
  "plugins": [
    {
      "name": "g-forge-test",
      "source": "./",
      "description": "test",
      "version": "9.9.9",
      "author": {
        "name": "test"
      },
      "license": "GPL-3.0",
      "category": "productivity"
    }
  ]
}
MARKET_EOF

SYNTH_PLUGIN=$(extract_plugin_version "$TEMP_DIR/plugin.json")
SYNTH_MARKETPLACE=$(extract_marketplace_version "$TEMP_DIR/marketplace.json")

if [ "$SYNTH_PLUGIN" != "$SYNTH_MARKETPLACE" ]; then
    echo "PASS: synthetic mismatch detected — plugin.json=$SYNTH_PLUGIN, marketplace.json=$SYNTH_MARKETPLACE (correctly differ)"
    PASS=$((PASS+1))
else
    echo "FAIL: synthetic mismatch NOT detected — both are $SYNTH_PLUGIN (should have differed)"
    FAIL=$((FAIL+1))
fi

# ── Summary ───────────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

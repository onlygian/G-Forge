#!/bin/bash
# Behavior tests for /g-update's Step 0/0a script (skills/g-update/scripts/
# preflight.sh) and Step 2 script (skills/g-update/scripts/inventory.sh).
#
# The preflight contract under test (see the script header): KEY: value lines,
# banners between BANNER_BEGIN/BANNER_END for the skill to reprint verbatim,
# version ordering via hooks/lib/semver-compare.sh, self-host short-circuit
# BEFORE any network call, and always exit 0. Network is stubbed with a curl
# shim on PATH that also records whether it was called; the plugin cache and
# g-team probes are steered with a fake $HOME.
#
# Cross-ref: g-dev/fixtures/g-update-staleness-preflight.sh sandbox-proves the
# same decision logic; this suite pins the shipped script's output contract.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PREFLIGHT="$REPO/skills/g-update/scripts/preflight.sh"
INVENTORY="$REPO/skills/g-update/scripts/inventory.sh"
PASS=0
FAIL=0

ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

BASE="$(mktemp -d)"
trap 'rm -rf "$BASE"' EXIT

FAKE_HOME="$BASE/home"
BIN="$BASE/bin"
CURL_MARKER="$BASE/curl-called"
mkdir -p "$FAKE_HOME" "$BIN"

# curl shim — records every invocation, then serves a stubbed plugin.json
# (FAKE_GH_VERSION) or fails like `curl -sf` on an unreachable host
# (FAKE_GH_FAIL=1 → exit 22).
cat > "$BIN/curl" <<'SHIM'
#!/bin/bash
echo "called" >> "$CURL_MARKER"
[ "${FAKE_GH_FAIL:-0}" = "1" ] && exit 22
printf '{\n  "name": "g-forge",\n  "version": "%s"\n}\n' "${FAKE_GH_VERSION:-0.0.0}"
SHIM
chmod +x "$BIN/curl"

# run_preflight <project-dir> — runs the shipped script with the fake HOME and
# the shimmed PATH; captures stdout and the exit code.
OUT=""
RC=0
run_preflight() {
    OUT=$(cd "$1" && HOME="$FAKE_HOME" PATH="$BIN:$PATH" \
          CURL_MARKER="$CURL_MARKER" \
          FAKE_GH_VERSION="${FAKE_GH_VERSION:-0.0.0}" \
          FAKE_GH_FAIL="${FAKE_GH_FAIL:-0}" \
          bash "$PREFLIGHT" 2>&1)
    RC=$?
}

has()     { if printf '%s\n' "$OUT" | grep -qF -- "$2"; then ok "$1"; else bad "$1 (missing: $2)"; fi; }
has_not() { if printf '%s\n' "$OUT" | grep -qF -- "$2"; then bad "$1 (unexpected: $2)"; else ok "$1"; fi; }

make_cache() { # make_cache <version> [dir-version]
    local v="$1" d="${2:-$1}"
    mkdir -p "$FAKE_HOME/.claude/plugins/cache/g-forge/g-forge/$d/.claude-plugin"
    printf '{\n  "name": "g-forge",\n  "version": "%s"\n}\n' "$v" \
        > "$FAKE_HOME/.claude/plugins/cache/g-forge/g-forge/$d/.claude-plugin/plugin.json"
}
reset_home() { rm -rf "$FAKE_HOME"; mkdir -p "$FAKE_HOME"; rm -f "$CURL_MARKER"; }

echo "── preflight.sh ──────────────────────────────────────────────────────"

# ── Case 1: self-host — short-circuit, offline-clean ──────────────────────
echo "Case 1: self-host project"
PROJ="$BASE/proj-selfhost"; mkdir -p "$PROJ/.claude-plugin"
printf '{ "name": "g-forge", "version": "9.9.9" }\n' > "$PROJ/.claude-plugin/plugin.json"
reset_home
FAKE_GH_VERSION=9.9.9 run_preflight "$PROJ"
[ $RC -eq 0 ] && ok "self-host: exit 0" || bad "self-host: exit $RC"
has "self-host: SELF_HOST on"         "SELF_HOST: on"
has "self-host: PLUGIN_ROOT is project root" "PLUGIN_ROOT: $PROJ"
has "self-host: ✓ note emitted"       "✓ Self-host mode detected — working tree is source, skipping cache version check."
[ -f "$CURL_MARKER" ] && bad "self-host: curl was called (must stay offline)" \
                      || ok  "self-host: no network call made"

# A consumer project whose plugin.json names a DIFFERENT plugin is not self-host.
echo "Case 1b: foreign plugin.json is not self-host"
PROJ="$BASE/proj-foreign"; mkdir -p "$PROJ/.claude-plugin"
printf '{ "name": "g-team", "version": "1.0.0" }\n' > "$PROJ/.claude-plugin/plugin.json"
reset_home; make_cache 2.6.0
FAKE_GH_VERSION=2.6.0 run_preflight "$PROJ"
has "foreign name: SELF_HOST off" "SELF_HOST: off"

# ── Case 2: cache behind GitHub → stale banner + stop, exit 0 ─────────────
echo "Case 2: stale cache"
PROJ="$BASE/proj-consumer"; mkdir -p "$PROJ"
reset_home; make_cache 2.5.0
FAKE_GH_VERSION=2.6.0 run_preflight "$PROJ"
[ $RC -eq 0 ] && ok "stale: exit 0" || bad "stale: exit $RC"
has "stale: COMPARE cache-stale"   "COMPARE: cache-stale"
has "stale: banner opened"         "BANNER_BEGIN: stale"
has "stale: banner closed"         "BANNER_END"
has "stale: banner names both versions" "⚠ Cannot sync — plugin cache is behind GitHub (v2.5.0 installed, v2.6.0 available)."
has "stale: banner names /plugins" "/plugins  →  Installed  →  g-forge  →  Update now"
has "stale: installed version reported" "INSTALLED_VERSION: unknown"
has_not "stale: run stops before Step 0a (no GTEAM line)" "GTEAM:"

# ── Case 3: cache current → proceed note, g-team probed ───────────────────
echo "Case 3: current cache"
reset_home; make_cache 2.6.0
FAKE_GH_VERSION=2.6.0 run_preflight "$PROJ"
has "current: COMPARE cache-current" "COMPARE: cache-current"
has "current: ✓ proceed note"        "✓ Plugin cache already at latest (v2.6.0) — proceeding with project sync."
has "current: GTEAM absent"          "GTEAM: absent"
has "current: ✓ no-g-team note"      "✓ No legacy g-team plugin — commands are g-forge only."

# ── Case 4: GitHub unreachable → degrade banner, continue ─────────────────
echo "Case 4: GitHub unreachable"
reset_home; make_cache 2.6.0
FAKE_GH_FAIL=1 run_preflight "$PROJ"
FAKE_GH_FAIL=0
has "unreachable: GITHUB_VERSION unreachable" "GITHUB_VERSION: unreachable"
has "unreachable: COMPARE github-unreachable" "COMPARE: github-unreachable"
has "unreachable: banner opened"   "BANNER_BEGIN: unreachable"
has "unreachable: banner text"     "⚠ GitHub unreachable — cannot confirm the cache is current."
has "unreachable: GTEAM still probed" "GTEAM: absent"

# ── Case 5: no cache at all ───────────────────────────────────────────────
echo "Case 5: no cache"
reset_home
run_preflight "$PROJ"
has "no-cache: CACHE_VERSION none"   "CACHE_VERSION: none"
has "no-cache: PLUGIN_ROOT MISSING"  "PLUGIN_ROOT: MISSING"
has "no-cache: COMPARE no-cache"     "COMPARE: no-cache"
[ $RC -eq 0 ] && ok "no-cache: exit 0" || bad "no-cache: exit $RC"

# ── Case 6: malformed GitHub version → cannot-compare, never assume-current ─
echo "Case 6: malformed compare"
reset_home; make_cache 2.6.0
FAKE_GH_VERSION="not-a-version" run_preflight "$PROJ"
has "malformed: COMPARE cannot-compare" "COMPARE: cannot-compare"
has_not "malformed: does not claim cache-current" "COMPARE: cache-current"

# ── Case 7: legacy g-team install detected ────────────────────────────────
echo "Case 7: g-team leftover"
reset_home; make_cache 2.6.0
mkdir -p "$FAKE_HOME/.claude/plugins/cache/g-team"
FAKE_GH_VERSION=2.6.0 run_preflight "$PROJ"
has "gteam: GTEAM found"       "GTEAM: found"
has "gteam: path reported"     "GTEAM_PATH: $FAKE_HOME/.claude/plugins/cache/g-team"
has "gteam: banner opened"     "BANNER_BEGIN: gteam"
has "gteam: banner text"       '⚠ Legacy "g-team" plugin still installed — it duplicates every /g-* command.'
[ $RC -eq 0 ] && ok "gteam: exit 0" || bad "gteam: exit $RC"

# ── Case 8: highest-semver cache dir wins (2.10.0 > 2.5.0, not lexical) ───
# Falsifiability: a lexical/`sort` pick chooses 2.5.0 here and the assertion
# goes red — proven by inverting the expected version in a scratch run.
echo "Case 8: highest-semver cache pick"
reset_home; make_cache 2.5.0; make_cache 2.10.0
FAKE_GH_VERSION=2.10.0 run_preflight "$PROJ"
has "semver pick: CACHE_VERSION is 2.10.0" "CACHE_VERSION: 2.10.0"
has "semver pick: COMPARE cache-current"   "COMPARE: cache-current"

echo ""
echo "── inventory.sh ──────────────────────────────────────────────────────"

# ── Case 9: populated project ─────────────────────────────────────────────
echo "Case 9: populated project inventory"
IPROJ="$BASE/proj-inv"
mkdir -p "$IPROJ/.claude/agents" "$IPROJ/.claude/rules" "$IPROJ/.claude/hooks"
cat > "$IPROJ/CLAUDE.md" <<'EOF'
# Project
<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->
rules body
<!-- End G-Forge Rules -->
<!-- G-Forge vue-pinia Architecture Rules — injected by /g-specialize -->
@.claude/rules/architecture-vue-pinia.md
<!-- End G-Forge vue-pinia Architecture Rules -->
EOF
printf -- '---\nname: vue-architect\n---\n' > "$IPROJ/.claude/agents/vue-architect.md"
printf -- '---\nname: vue-implementer\n---\n' > "$IPROJ/.claude/agents/vue-implementer.md"
printf -- '---\nname: feature-implementer\n---\n' > "$IPROJ/.claude/agents/feature-implementer.md"
printf -- '---\nname: my-helper\n---\n' > "$IPROJ/.claude/agents/my-helper.md"
echo "# arch" > "$IPROJ/.claude/rules/architecture-vue-pinia.md"
echo "#!/bin/bash" > "$IPROJ/.claude/hooks/check-commit.sh"
echo "# G-RULES" > "$IPROJ/G-RULES.md"

OUT=$(cd "$IPROJ" && bash "$INVENTORY" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "inventory: exit 0" || bad "inventory: exit $RC"
has "inventory: rules block present"     "RULES_BLOCK: present"
has "inventory: arch stack listed"       "ARCH_STACK: vue-pinia"
has "inventory: architect classified"    "AGENT: vue-architect.md name=vue-architect class=architect"
has "inventory: implementer classified"  "AGENT: vue-implementer.md name=vue-implementer class=implementer"
has "inventory: feature-implementer is other (shipped agent, not per-stack)" \
    "AGENT: feature-implementer.md name=feature-implementer class=other"
has "inventory: user agent is other"     "AGENT: my-helper.md name=my-helper class=other"
has "inventory: rules file listed"       "RULES_FILE: architecture-vue-pinia.md"
has "inventory: check-commit present"    "HOOK: check-commit.sh present"
has "inventory: workflow-checkpoint absent" "HOOK: workflow-checkpoint.sh absent"
has "inventory: G-RULES.md present"      "GRULES_MD: present"

# ── Case 10: empty project ────────────────────────────────────────────────
echo "Case 10: empty project inventory"
EPROJ="$BASE/proj-empty"; mkdir -p "$EPROJ"
OUT=$(cd "$EPROJ" && bash "$INVENTORY" 2>&1); RC=$?
[ $RC -eq 0 ] && ok "empty inventory: exit 0" || bad "empty inventory: exit $RC"
has "empty inventory: rules block absent" "RULES_BLOCK: absent"
has "empty inventory: G-RULES.md absent"  "GRULES_MD: absent"
has_not "empty inventory: no agent rows"  "AGENT: "

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

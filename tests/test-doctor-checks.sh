#!/bin/bash
# Unit tests for skills/g-doctor/scripts/checks.sh — the deterministic
# implementation of /g-doctor Checks 1–23 and 25 (v2.6 token diet).
#
# Verifies the KEY: line output contract against fixture projects:
#   Tests 1-6:  healthy fixture — SUMMARY 16/16, closed-set pass literals,
#               Check 22 SKIP when unbound, Check 24 NEEDS-MODEL, exit 0
#   Tests 7-10: broken fixture — presence FAILs, stale sentinel, duplicate
#               registration, exit STILL 0 (outcomes in output, never exit code)
#   Tests 11-12: Check 16 drift — modified installed hook goes FAIL with the
#               byte-frozen drift literal
#   Tests 13-14: install-list completeness — missing sourced lib emits the
#               sourced-by line; empty .claude/hooks emits the inconclusive ⚠,
#               never Pass (vacuous-truth guard)
#   Tests 15-17: Check 25 tier — valid local value, unrecognized value, missing
#   Tests 18-19: Check 22 bound + tracked + secret-in-bind
#   Test  20:   Check 21 inverted stray-doc scan flags a parallel docs/ tree
#   Tests 21-23: mirror pin — the three hash_file cascade lines derived from
#               skills/g-doctor/SKILL.md (the test-pinned canonical) must each
#               appear verbatim in checks.sh (the script mirrors the block;
#               silent divergence between the two is the drift this catches)
#   Tests 24-25: Check 16(g) frontmatter strip — an architecture-skill body
#               containing --- horizontal rules is NOT drift (strip consumes
#               exactly through the closing fence, never body hrs)
#   Tests 26-27: Check 23 — installed version ahead of cache never prints the
#               aligned Pass; the installed-ahead ℹ literal prints instead
#   Test  28:   Check 22 always-reminder surfaces as a LINE row (transcribed
#               into the report on advisory branches too, not a NOTE)
#   Tests 29-30: Check 20 outside a git repo — literal-pattern fallback still
#               verifies both lists (clean passes; over-broad bare pattern warns)
#
# Falsifiability: probed in a scratch copy (never the production tree) —
# blanking a cascade line in a scratch checks.sh turns Tests 21-23 red;
# forcing `exit 1` after a FAIL turns Test 10 red; the pre-fix strip
# (awk '/^---$/{n++; next}' without the n<2 guard) turns Tests 24-25 red;
# the pre-fix Check 23 fall-through turns Test 27 red; the pre-fix
# unconditional non-git ✓ turns Test 30 red.
#
# The fixture project installs its copies FROM the repo itself, so the repo
# acts as the plugin root (checks.sh resolves PLUGIN_ROOT from its own path).
# HOME is pointed at an empty fixture home and GF_DOCTOR_OFFLINE=1 is set, so
# Checks 19/23 never touch the real user cache or the network.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECKS="$REPO_ROOT/skills/g-doctor/scripts/checks.sh"
SKILL_MD="$REPO_ROOT/skills/g-doctor/SKILL.md"

PASS=0
FAIL=0

check() { # name expected actual
    if [ "$2" = "$3" ]; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 (expected '$2', got '$3')"; FAIL=$((FAIL+1))
    fi
}

has_line() { # name output fixed-string
    if printf '%s\n' "$2" | grep -qF -- "$3"; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 (missing: $3)"; FAIL=$((FAIL+1))
    fi
}

[ -f "$CHECKS" ] || { echo "FAIL: $CHECKS not found"; exit 1; }

# build_fixture <dir> — a healthy G-Forge project installed from the repo
build_fixture() {
    local d="$1"
    mkdir -p "$d/project/.claude/hooks/lib" "$d/project/.claude/rules" \
             "$d/project/.claude/agents" "$d/project/g-docs" "$d/home"
    cd "$d/project" || return 1
    git init -q 2>/dev/null
    cp "$REPO_ROOT"/hooks/*.sh .claude/hooks/
    cp "$REPO_ROOT"/hooks/lib/*.sh .claude/hooks/lib/
    for f in "$REPO_ROOT"/rules/g-rules/*.md; do
        cp "$f" ".claude/rules/g-rules-$(basename "$f")"
    done
    cat > .claude/settings.json <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": ".claude/hooks/check-commit.sh" } ] }
    ],
    "PostToolUse": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/observe.sh" } ] },
      { "hooks": [ { "type": "command", "command": ".claude/hooks/post-commit-cleanup.sh" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/workflow-checkpoint.sh" } ] }
    ],
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/session-start.sh" } ] },
      { "hooks": [ { "type": "command", "command": ".claude/hooks/observe.sh" } ] }
    ],
    "SubagentStart": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/agent-lifecycle.sh" } ] }
    ],
    "SubagentStop": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/agent-lifecycle.sh" } ] }
    ],
    "PreCompact": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/pre-compact.sh" } ] }
    ]
  }
}
JSON
    cat > CLAUDE.md <<'MD'
# Fixture project

<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->
@G-RULES.md
<!-- End G-Forge Rules -->
MD
    printf '%s\n' "# G-RULES fixture" > G-RULES.md
    cat > .gitignore <<'GI'
.claude/g-forge-approved
.claude/g-forge-docs-approved
.claude/journal/
g-docs/agent-output/
GI
    local gh
    gh=$(git rev-parse --git-path hooks)
    mkdir -p "$gh/lib"
    cp "$REPO_ROOT/hooks/pre-commit" "$gh/pre-commit"
    cp "$REPO_ROOT"/hooks/lib/*.sh "$gh/lib/"
    printf 'full\n' > .claude/integration-tier
}

run_checks() { # from cwd = fixture project; fixture home one level up
    HOME="$(cd .. && pwd)/home" GF_DOCTOR_OFFLINE=1 bash "$CHECKS" 2>/dev/null
}

# ────────────────────────────────────────────────────────────────────────────
# Tests 1-6: healthy fixture

echo "Tests 1-6: healthy fixture passes all 16 required checks"
FIX1=$(mktemp -d)
build_fixture "$FIX1" || { echo "FAIL: could not build fixture"; exit 1; }
OUT=$(run_checks); RC=$?

check    "healthy: exit code is 0" "0" "$RC"
has_line "healthy: SUMMARY reports 16/16 required" "$OUT" "SUMMARY: required_passed=16 required_total=16"
has_line "healthy: hooks no-drift pass literal" "$OUT" "LINE: ✓ Installed hooks match plugin source (no drift)"
has_line "healthy: Check 22 skips when no Roundtable bound" "$OUT" "CHECK: 22 SKIP"
has_line "healthy: Check 24 is handed to the model" "$OUT" "CHECK: 24 NEEDS-MODEL"
has_line "healthy: tier pass literal names value and source" "$OUT" "LINE: ✓ integration tier set: full (local)"

cd / && rm -rf "$FIX1"

# ────────────────────────────────────────────────────────────────────────────
# Tests 7-10: broken fixture — presence FAILs, duplicate registration, exit 0

echo "Tests 7-10: broken fixture fails loud in output, never in exit code"
FIX2=$(mktemp -d)
build_fixture "$FIX2"
rm .claude/hooks/check-commit.sh
touch .claude/g-forge-approved
# a second PreToolUse entry for the same script = duplicate registration
cat > .claude/settings.json <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": ".claude/hooks/check-commit.sh" } ] },
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": ".claude/hooks/check-commit.sh" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/workflow-checkpoint.sh" } ] }
    ]
  }
}
JSON
OUT=$(run_checks); RC=$?

has_line "broken: Check 1 fails with the missing-hook literal" "$OUT" "LINE: ✗ commit hook missing"
has_line "broken: Check 9 flags the stale sentinel" "$OUT" "LINE: ✗ Stale approval sentinel found"
has_line "broken: Check 15 counts the duplicate registration" "$OUT" "LINE: ✗ check-commit.sh registered 2× under PreToolUse in settings.json — will double-fire"
check    "broken: exit code is STILL 0 (contract: outcomes in output)" "0" "$RC"

cd / && rm -rf "$FIX2"

# ────────────────────────────────────────────────────────────────────────────
# Tests 11-12: Check 16 drift on a modified installed hook

echo "Tests 11-12: modified installed hook is reported as drift"
FIX3=$(mktemp -d)
build_fixture "$FIX3"
printf '\n# local edit\n' >> .claude/hooks/check-commit.sh
OUT=$(run_checks)

has_line "drift: Check 16 goes FAIL" "$OUT" "CHECK: 16 FAIL"
has_line "drift: per-file drift literal" "$OUT" "LINE: ✗ check-commit.sh installed copy differs from plugin source (drift)"

cd / && rm -rf "$FIX3"

# ────────────────────────────────────────────────────────────────────────────
# Tests 13-14: install-list completeness

echo "Tests 13-14: sourced-but-uninstalled lib, and the inconclusive branch"
FIX4=$(mktemp -d)
build_fixture "$FIX4"
rm .claude/hooks/lib/commit-detect.sh
OUT=$(run_checks)
FOUND="no"
printf '%s\n' "$OUT" | grep -F "sourced by" | grep -qF "hooks/lib/commit-detect.sh" && FOUND="yes"
check "completeness: missing sourced lib emits the sourced-by line" "yes" "$FOUND"

rm .claude/hooks/*.sh   # no installed hooks left to derive from
OUT=$(run_checks)
has_line "completeness: zero references is inconclusive, never Pass" "$OUT" "LINE: ⚠ install-list completeness — inconclusive (no installed hooks found to derive from)"

cd / && rm -rf "$FIX4"

# ────────────────────────────────────────────────────────────────────────────
# Tests 15-17: Check 25 integration-tier guard

echo "Tests 15-17: tier valid / unrecognized / missing"
FIX5=$(mktemp -d)
build_fixture "$FIX5"
OUT=$(run_checks)
has_line "tier: valid local value passes" "$OUT" "CHECK: 25 PASS"

printf 'bogus\n' > .claude/integration-tier
OUT=$(run_checks)
has_line "tier: unrecognized value literal" "$OUT" 'LINE: ⚠ governing `integration-tier` contains an unrecognized value: bogus'

rm .claude/integration-tier
OUT=$(run_checks)
has_line "tier: missing governing file goes inert-warning" "$OUT" 'LINE: ⚠ governing `integration-tier` missing — all hooks (commit gate included) are silently inert'

cd / && rm -rf "$FIX5"

# ────────────────────────────────────────────────────────────────────────────
# Tests 18-19: Check 22 bound Roundtable — tracked bind record + secret

echo "Tests 18-19: bound Roundtable with a tracked record and a secret"
FIX6=$(mktemp -d)
build_fixture "$FIX6"
printf 'doc=https://example.invalid/d/1\ntoken=abc123\n' > .claude/roundtable
OUT=$(run_checks)

has_line "roundtable: tracked bind record advisory" "$OUT" 'LINE: ⚠ `.claude/roundtable` is tracked — the bound surface ref (and any creds near it) could be pushed'
has_line "roundtable: secret-in-bind literal" "$OUT" 'LINE: 🔴 A credential is stored in `.claude/roundtable` — move it to an environment variable and remove the line. Never commit a token.'

cd / && rm -rf "$FIX6"

# ────────────────────────────────────────────────────────────────────────────
# Test 20: Check 21 inverted stray-doc scan

echo "Test 20: parallel docs/ tree sharing a g-docs/ dir name is a stray"
FIX7=$(mktemp -d)
build_fixture "$FIX7"
mkdir -p g-docs/plans docs/plans
printf 'canonical plan\n' > g-docs/plans/f.md
printf 'stray plan\n' > docs/plans/f.md
OUT=$(run_checks)
FOUND="no"
printf '%s\n' "$OUT" | grep -F "stray G-Forge document(s) outside g-docs/" | grep -qF "docs/plans" && FOUND="yes"
check "stray-docs: inverted scan flags docs/plans/" "yes" "$FOUND"

cd / && rm -rf "$FIX7"

# ────────────────────────────────────────────────────────────────────────────
# Tests 21-23: hash cascade mirror pin — checks.sh must carry, verbatim, the
# three cascade lines pinned in SKILL.md (test-g-doctor-drift.sh evals them
# out of SKILL.md; the script's hash_file mirrors that canonical block).

echo "Tests 21-23: checks.sh mirrors the SKILL.md hash_file cascade"
for snippet in 'sha256sum "$1"' 'shasum -a 256 "$1"' 'cksum "$1"'; do
    CANON=$(grep -F "$snippet" "$SKILL_MD" | sed 's/^[[:space:]]*//')
    if [ -z "$CANON" ]; then
        echo "FAIL: could not derive '$snippet' line from $SKILL_MD"; FAIL=$((FAIL+1))
        continue
    fi
    MIRRORED="no"
    grep -F "$snippet" "$CHECKS" | sed 's/^[[:space:]]*//' | grep -qxF -- "$CANON" && MIRRORED="yes"
    check "cascade mirror: '$snippet' line identical in checks.sh" "yes" "$MIRRORED"
done

# ────────────────────────────────────────────────────────────────────────────
# Tests 24-25: Check 16(g) — architecture-skill body containing --- hr lines
# is not drift (the profile source frontend-data-flow carries ^---$ body hrs)

echo "Tests 24-25: architecture-skill body hr lines survive the frontmatter strip"
FIX8=$(mktemp -d)
build_fixture "$FIX8"
mkdir -p .claude/skills/architecture-frontend-data-flow
{ printf -- '---\nname: architecture-frontend-data-flow\ndescription: fixture\n---\n'
  cat "$REPO_ROOT/profiles/frontend-data-flow/rules/architecture.md"; } \
  > .claude/skills/architecture-frontend-data-flow/SKILL.md
OUT=$(run_checks)

has_line "arch-skill: hr-bearing body matches its profile source" "$OUT" "LINE: ✓ Installed architecture-skill copies match profile source (no drift)"
FOUND="no"
printf '%s\n' "$OUT" | grep -qF "architecture-frontend-data-flow/SKILL.md installed copy differs" && FOUND="yes"
check "arch-skill: no false drift FAIL for the hr-bearing body" "no" "$FOUND"

cd / && rm -rf "$FIX8"

# ────────────────────────────────────────────────────────────────────────────
# Tests 26-27: Check 23 — installed version ahead of cache is never "aligned"

echo "Tests 26-27: installed ahead of cache never prints the aligned Pass"
FIX9=$(mktemp -d)
build_fixture "$FIX9"
mkdir -p ../home/.claude/plugins/cache/g-forge/g-forge/2.5.0/.claude-plugin
printf '{ "name": "g-forge", "version": "2.5.0" }\n' \
    > ../home/.claude/plugins/cache/g-forge/g-forge/2.5.0/.claude-plugin/plugin.json
mkdir -p .claude-plugin
printf '{ "name": "g-forge", "version": "2.6.0" }\n' > .claude-plugin/plugin.json
OUT=$(run_checks)

FOUND="no"
printf '%s\n' "$OUT" | grep -qF "✓ Plugin versions aligned" && FOUND="yes"
check "check23: installed ahead of cache does not print the aligned Pass" "no" "$FOUND"
has_line "check23: installed-ahead ℹ literal (distinct from cache-ahead)" "$OUT" "LINE: ℹ Project files (v2.6.0) are ahead of the plugin cache (v2.5.0) — expected on the plugin source repo when the working tree's version is bumped before the cache updates; not actionable."

cd / && rm -rf "$FIX9"

# ────────────────────────────────────────────────────────────────────────────
# Test 28: Check 22 always-reminder is a LINE row (survives transcription)

echo "Test 28: bound Roundtable always emits the link-restricted reminder LINE"
FIX10=$(mktemp -d)
build_fixture "$FIX10"
printf 'doc=https://example.invalid/d/1\n' > .claude/roundtable
OUT=$(run_checks)

has_line "roundtable: always-reminder surfaces as a LINE row" "$OUT" 'LINE: the bound Doc must be **link-restricted, never public** — `/g-roundtable` enforces this at bind, but confirm sharing hasn'\''t been widened since.'

cd / && rm -rf "$FIX10"

# ────────────────────────────────────────────────────────────────────────────
# Tests 29-30: Check 20 without git — the literal-pattern fallback verifies

echo "Tests 29-30: non-git Check 20 still verifies .gitignore patterns"
FIX11=$(mktemp -d)
mkdir -p "$FIX11/project" "$FIX11/home"
cd "$FIX11/project" || { echo "FAIL: could not build non-git fixture"; exit 1; }
cat > .gitignore <<'GI'
.claude/g-forge-approved
.claude/g-forge-docs-approved
.claude/journal/
g-docs/agent-output/
GI
OUT=$(run_checks)
has_line "check20 non-git: clean .gitignore still earns the pass literal" "$OUT" "LINE: ✓ .gitignore vets G-Forge artifacts (runtime ignored, project record tracked)"

printf 'todo.md\n' >> .gitignore
OUT=$(run_checks)
has_line "check20 non-git: over-broad bare pattern caught without git" "$OUT" "LINE: ⚠ .gitignore ignores g-docs/todo.md — project record won't be committed"

cd / && rm -rf "$FIX11"

# ────────────────────────────────────────────────────────────────────────────
# Summary

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

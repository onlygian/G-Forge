#!/bin/bash
# Unit tests for skills/g-specialize/scripts/detect-stack.sh
# Pins the Step 1 detection contract: dependency→stack mapping (closed-set
# stack names byte-identical to the SKILL.md frontmatter list), combo
# detection, the frontend-data-flow supplementary trigger, candidate-arg
# validation (UNSUPPORTED), conflict lines, and Step 5 file location
# (AGENT_FILE/RULES_FILE/MISSING, local-first).
#
# Fixture dirs are built under mktemp; HOME is pointed at an empty fixture
# home so the plugin-cache fallback resolves nothing and every location
# assert is driven by the fixture's local profiles/ tree.
#
# falsifiability: assert_has flipped to a wrong expected literal in a scratch
# run, suite confirmed red — 2026-09-02. devDependencies guard probed by
# relaxing hdd→hd on the @react-router/dev check in a scratch run: the
# not-remix asserts confirmed red — 2026-09-02.

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../skills/g-specialize/scripts/detect-stack.sh"
[ -f "$SCRIPT" ] || { echo "FAIL: script not found at $SCRIPT"; echo "Results: 0 passed, 1 failed"; exit 1; }

PASS=0
FAIL=0

ROOT=$(mktemp -d)
FAKE_HOME="$ROOT/home"
mkdir -p "$FAKE_HOME"
trap 'rm -rf "$ROOT"' EXIT

OUT=""
RC=0
run_in() { # <fixture-dir> [args...] — run the script there, capture output
    local dir="$1"; shift
    OUT=$(cd "$dir" && HOME="$FAKE_HOME" bash "$SCRIPT" "$@" 2>&1)
    RC=$?
}

assert_has() { # <name> <exact-line>
    if printf '%s\n' "$OUT" | grep -qxF "$2"; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 — expected line '$2' in output:"; printf '%s\n' "$OUT" | sed 's/^/    /'
        FAIL=$((FAIL+1))
    fi
}
assert_not() { # <name> <line-prefix that must be absent>
    if printf '%s\n' "$OUT" | grep -q "^$2"; then
        echo "FAIL: $1 — line matching '^$2' must be absent:"; printf '%s\n' "$OUT" | sed 's/^/    /'
        FAIL=$((FAIL+1))
    else
        echo "PASS: $1"; PASS=$((PASS+1))
    fi
}
assert_rc0() { # <name>
    if [ "$RC" -eq 0 ]; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 — exit code $RC (contract: always 0)"; FAIL=$((FAIL+1))
    fi
}

# ── package.json mappings ────────────────────────────────────────────────────

D="$ROOT/vue-tauri"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"vue": "^3.4", "pinia": "^2.1", "@tauri-apps/api": "^1.5"}}
EOF
run_in "$D"
assert_rc0 "vue+pinia+tauri: exit 0"
assert_has "vue+pinia → vue-pinia (deps)" "STACK: vue-pinia source=deps"
assert_has "@tauri-apps/api → tauri (deps)" "STACK: tauri source=deps"
assert_has "vue-pinia+tauri covers combo" "COMBO: tauri-vue-pinia"
assert_has "vue-pinia triggers supplementary" "SUPPLEMENTARY: frontend-data-flow"
assert_has "no local/cache profiles → MISSING vue-pinia" "MISSING: vue-pinia"

D="$ROOT/react-plain"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"react": "^18", "react-dom": "^18"}}
EOF
run_in "$D"
assert_has "react alone → react" "STACK: react source=deps"
assert_not "react alone: no react-native" "STACK: react-native "

D="$ROOT/nextjs"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"next": "^14", "react": "^18"}}
EOF
run_in "$D"
assert_has "next → next-js" "STACK: next-js source=deps"
assert_not "next suppresses plain react" "STACK: react source"

D="$ROOT/rrv7"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"react": "^18", "react-router": "^7"}, "devDependencies": {"@react-router/dev": "^7"}}
EOF
run_in "$D"
assert_has "react-router v7 framework mode → remix" "STACK: remix source=deps"
assert_not "remix suppresses plain react" "STACK: react source"

D="$ROOT/rrv7-not-dev"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"react": "^18", "react-router": "^7", "@react-router/dev": "^7"}}
EOF
run_in "$D"
assert_not "@react-router/dev outside devDependencies, no config file → not remix" "STACK: remix "
assert_has "library-mode react-router stays plain react" "STACK: react source=deps"

D="$ROOT/rrv7-config"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"react": "^18", "react-router": "^7"}}
EOF
touch "$D/react-router.config.ts"
run_in "$D"
assert_has "react-router + react-router.config.ts → remix" "STACK: remix source=deps"

D="$ROOT/expo"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"expo": "^51", "react": "^18"}}
EOF
run_in "$D"
assert_has "expo → react-native" "STACK: react-native source=deps"
assert_not "react-native suppresses plain react" "STACK: react source"

D="$ROOT/nodets"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"fastify": "^4"}, "devDependencies": {"typescript": "^5"}}
EOF
run_in "$D"
assert_has "typescript+fastify → node-ts" "STACK: node-ts source=deps"

D="$ROOT/expressjs"; mkdir -p "$D"
cat > "$D/package.json" <<'EOF'
{"dependencies": {"express": "^4"}, "devDependencies": {"typescript": "^5"}}
EOF
run_in "$D"
assert_has "express → express" "STACK: express source=deps"
assert_not "express match blocks node-ts fallback" "STACK: node-ts "

# ── python mappings ─────────────────────────────────────────────────────────

D="$ROOT/fastapi"; mkdir -p "$D"
printf 'fastapi==0.111\nsqlalchemy>=2.0\n' > "$D/requirements.txt"
run_in "$D"
assert_has "fastapi → fastapi" "STACK: fastapi source=deps"
assert_not "sqlalchemy with web framework: no python-data" "STACK: python-data "

D="$ROOT/pydata"; mkdir -p "$D"
printf 'pandas\n' > "$D/requirements.txt"
run_in "$D"
assert_has "pandas, no web framework → python-data" "STACK: python-data source=deps"

# ── Cargo mappings ──────────────────────────────────────────────────────────

D="$ROOT/axum"; mkdir -p "$D"
printf '[dependencies]\naxum = "0.7"\nclap = "4"\n' > "$D/Cargo.toml"
run_in "$D"
assert_has "axum → rust-axum" "STACK: rust-axum source=deps"
assert_not "clap with axum: no rust-cli" "STACK: rust-cli "

D="$ROOT/rustcli"; mkdir -p "$D"
printf '[dependencies]\nclap = "4"\n' > "$D/Cargo.toml"
run_in "$D"
assert_has "clap without axum → rust-cli" "STACK: rust-cli source=deps"

# ── csproj: xamarin EOL vs maui ─────────────────────────────────────────────

D="$ROOT/xam"; mkdir -p "$D"
printf '<Project><PackageReference Include="Xamarin.Forms" /></Project>\n' > "$D/App.csproj"
run_in "$D"
assert_has "Xamarin.Forms without Maui → xamarin" "STACK: xamarin source=deps"
if printf '%s\n' "$OUT" | grep -q "^NOTE: Xamarin.Forms reached end-of-support"; then
    echo "PASS: xamarin detection carries the EOL NOTE"; PASS=$((PASS+1))
else
    echo "FAIL: xamarin detection missing the EOL NOTE"; FAIL=$((FAIL+1))
fi

D="$ROOT/maui"; mkdir -p "$D"
printf '<Project><FrameworkReference Include="Microsoft.Maui" /></Project>\n' > "$D/App.csproj"
run_in "$D"
assert_has "Microsoft.Maui → maui" "STACK: maui source=deps"
assert_not "Maui present: no xamarin" "STACK: xamarin "

# ── claude-plugin detection ─────────────────────────────────────────────────

D="$ROOT/plugin"; mkdir -p "$D/.claude-plugin"
printf '{"name": "x", "version": "0.0.1"}\n' > "$D/.claude-plugin/plugin.json"
run_in "$D"
assert_has ".claude-plugin/plugin.json → claude-plugin" "STACK: claude-plugin source=deps"

# ── roadmap dropped as a detection source ───────────────────────────────────
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-09-03

D="$ROOT/roadmap-catalog"; mkdir -p "$D/g-docs"
printf 'Supported stacks: react, vue-pinia, django, flask, rust-axum, tauri\n' > "$D/g-docs/ROADMAP.md"
run_in "$D"
assert_not "ROADMAP.md naming stacks the project does not use → no source=roadmap" "STACK: .* source=roadmap"
assert_has "no brief + no deps + roadmap-only mentions → still CONFLICT" "CONFLICT: no brief and no dependency files found — ask the developer which profiles to apply"

# ── brief scan, boundary rule, conflict ─────────────────────────────────────

D="$ROOT/brief"; mkdir -p "$D/g-docs"
printf 'Tech decisions: fastapi backend. Frontend uses react-native only.\n' > "$D/g-docs/project_brief.md"
run_in "$D"
assert_has "brief names fastapi → source=brief" "STACK: fastapi source=brief"
assert_has "brief names react-native" "STACK: react-native source=brief"
assert_not "hyphen boundary: react not matched inside react-native" "STACK: react source"

D="$ROOT/conflict"; mkdir -p "$D/g-docs"
printf 'Stack: react frontend\n' > "$D/g-docs/project_brief.md"
printf '{"dependencies": {"express": "^4"}}\n' > "$D/package.json"
run_in "$D"
assert_has "brief stack unconfirmed by deps → CONFLICT" "CONFLICT: react named in brief but not confirmed by dependency files"

# ── no sources at all ───────────────────────────────────────────────────────

D="$ROOT/empty"; mkdir -p "$D"
run_in "$D"
assert_rc0 "empty dir: exit 0"
assert_has "no brief + no deps → CONFLICT" "CONFLICT: no brief and no dependency files found — ask the developer which profiles to apply"

# ── candidate-arg validation ────────────────────────────────────────────────

run_in "$ROOT/empty" django gatsby
assert_has "supported candidate arg → STACK source=arg" "STACK: django source=arg"
assert_has "unknown candidate arg → UNSUPPORTED" "UNSUPPORTED: gatsby"
assert_not "candidate args present: no no-sources CONFLICT" "CONFLICT: no brief"

# ── Step 5 file location: local-first, irregular basename via glob ──────────

D="$ROOT/local"; mkdir -p "$D/profiles/go-gin/agents" "$D/profiles/go-gin/rules"
printf '# stub architect\n' > "$D/profiles/go-gin/agents/go-architect.md"
printf '# stub rules\n' > "$D/profiles/go-gin/rules/architecture.md"
run_in "$D" go-gin
assert_has "irregular basename resolved by glob" "AGENT_FILE: profiles/go-gin/agents/go-architect.md"
assert_has "rules file located locally" "RULES_FILE: profiles/go-gin/rules/architecture.md"
assert_not "profile found: no MISSING" "MISSING: go-gin"

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

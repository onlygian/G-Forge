#!/bin/bash
# Unit tests for skills/g-specialize/scripts/derive-owns.sh
# Pins the layer-map → owns-glob conversion contract shared by /g-specialize
# Step 6 and /g-update Step 5 (one owner): directory path → "<path>**",
# <placeholder> segment → *, concrete file path verbatim, EVERY backtick-quoted
# path in the bullet's layer segment (before the " — " description separator;
# backticks after the dash are description code and ignored), OWNS: none when
# no **Layer map:** section or no extractable paths, always exit 0.
#
# falsifiability: expected glob flipped to a wrong value in a scratch run,
# suite confirmed red — 2026-09-02. Multi-path guard probed by re-inserting
# first-path-only extraction (head -1) in a scratch run: the second-path
# asserts (apps/common/**, android/**) confirmed red — 2026-09-02.

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../skills/g-specialize/scripts/derive-owns.sh"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
[ -f "$SCRIPT" ] || { echo "FAIL: script not found at $SCRIPT"; echo "Results: 0 passed, 1 failed"; exit 1; }

PASS=0
FAIL=0

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

OUT=""
RC=0
run_on() { OUT=$(bash "$SCRIPT" "$@" 2>&1); RC=$?; }

assert_has() { # <name> <exact-line>
    if printf '%s\n' "$OUT" | grep -qxF "$2"; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 — expected line '$2' in output:"; printf '%s\n' "$OUT" | sed 's/^/    /'
        FAIL=$((FAIL+1))
    fi
}
assert_not() { # <name> <exact-line that must be absent>
    if printf '%s\n' "$OUT" | grep -qxF "$2"; then
        echo "FAIL: $1 — line '$2' must be absent"; FAIL=$((FAIL+1))
    else
        echo "PASS: $1"; PASS=$((PASS+1))
    fi
}
assert_rc0() {
    if [ "$RC" -eq 0 ]; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 — exit code $RC (contract: always 0)"; FAIL=$((FAIL+1))
    fi
}

# ── conversion rules ────────────────────────────────────────────────────────

cat > "$ROOT/rules1.md" <<'EOF'
## Some Stack Architecture Rules

**Layer map:**
- `src/components/` — reusable UI units
- `apps/<feature>/views.py` — request/response only; delegates to `services.py`
- `src/state.rs` — single mutable state struct
- `profiles/<stack>/` — per-stack profile dirs

**Import direction:** downward only.
EOF
run_on "$ROOT/rules1.md"
assert_rc0 "conversion fixture: exit 0"
assert_has "directory path → path**" 'OWNS: "src/components/**"'
assert_has "<placeholder> → *" 'OWNS: "apps/*/views.py"'
assert_has "concrete file path verbatim" 'OWNS: "src/state.rs"'
assert_has "placeholder + trailing slash → both rules" 'OWNS: "profiles/*/**"'
assert_not "description code after the dash ignored" 'OWNS: "services.py"'
assert_not "section ends at Import direction" 'OWNS: "downward only."'
assert_not "paths found → no OWNS: none" "OWNS: none"

# ── multi-path bullets: every backtick path before the dash extracted ───────

cat > "$ROOT/rules5.md" <<'EOF'
## Multi-Path Stack Architecture Rules

**Layer map:**
- `utils/` or `apps/common/` — pure utility functions; no ORM, no HTTP imports
- `ios/` and `android/` — platform shells; managed by tooling
- `app/DTOs/` — immutable data transfer objects; plain PHP or `spatie/data`
EOF
run_on "$ROOT/rules5.md"
assert_rc0 "multi-path fixture: exit 0"
assert_has "multi-path or-bullet: first path" 'OWNS: "utils/**"'
assert_has "multi-path or-bullet: second path" 'OWNS: "apps/common/**"'
assert_has "multi-path and-bullet: first path" 'OWNS: "ios/**"'
assert_has "multi-path and-bullet: second path" 'OWNS: "android/**"'
assert_has "single-path bullet unchanged" 'OWNS: "app/DTOs/**"'
assert_not "code token after the dash not extracted" 'OWNS: "spatie/data"'

# ── no layer map / table-format layer map → OWNS: none ─────────────────────

cat > "$ROOT/rules2.md" <<'EOF'
## Table Stack Architecture Rules

## Layer Map

| Layer | Directory | Responsibility |
|-------|-----------|----------------|
| Views | `Views/`  | XAML |
EOF
run_on "$ROOT/rules2.md"
assert_rc0 "table-format fixture: exit 0"
assert_has "table-format Layer Map (no **Layer map:** bullets) → OWNS: none" "OWNS: none"

printf '# nothing here\n' > "$ROOT/rules3.md"
run_on "$ROOT/rules3.md"
assert_has "no layer map at all → OWNS: none" "OWNS: none"

# ── bullets with no backticked path → OWNS: none ────────────────────────────

cat > "$ROOT/rules4.md" <<'EOF'
**Layer map:**
- views layer, no backticks anywhere
- another prose bullet
EOF
run_on "$ROOT/rules4.md"
assert_has "bullets without backticked paths → OWNS: none" "OWNS: none"

# ── missing file / no argument ──────────────────────────────────────────────

run_on "$ROOT/does-not-exist.md"
assert_rc0 "missing file: exit 0"
assert_has "missing file → OWNS: none" "OWNS: none"
assert_has "missing file → NOTE" "NOTE: rules file not found: $ROOT/does-not-exist.md"

run_on
assert_rc0 "no argument: exit 0"
assert_has "no argument → OWNS: none" "OWNS: none"

# ── real repo card: vue-pinia (pins the shipped profile's derivation) ───────

run_on "$REPO_ROOT/profiles/vue-pinia/rules/architecture.md"
assert_has "vue-pinia card: views glob" 'OWNS: "src/views/**"'
assert_has "vue-pinia card: components glob" 'OWNS: "src/components/**"'
assert_has "vue-pinia card: composables glob" 'OWNS: "src/composables/**"'
assert_has "vue-pinia card: stores glob" 'OWNS: "src/stores/**"'
assert_has "vue-pinia card: services glob" 'OWNS: "src/services/**"'
assert_has "vue-pinia card: types glob" 'OWNS: "src/types/**"'

# ── real repo cards with multi-path bullets: django and capacitor ───────────

run_on "$REPO_ROOT/profiles/django/rules/architecture.md"
assert_has "django card: utils glob" 'OWNS: "utils/**"'
assert_has "django card: apps/common glob (second path in bullet)" 'OWNS: "apps/common/**"'

run_on "$REPO_ROOT/profiles/capacitor/rules/architecture.md"
assert_has "capacitor card: ios glob" 'OWNS: "ios/**"'
assert_has "capacitor card: android glob (second path in bullet)" 'OWNS: "android/**"'

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

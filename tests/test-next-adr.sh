#!/bin/bash
# Unit tests for skills/g-adr/scripts/next-adr.sh — the v2.6 prose→script
# extraction of /g-adr Step 5 (next ADR number + filename derivation).
#
# Verifies:
# - Always-exit-0 contract (numbering outcomes live in output, never rc)
# - DIR_STATE created|exists, LAST none|<file>, NEXT zero-padded (001 start)
# - Gap tolerance: highest + 1, not count + 1
# - Non-numeric/legacy filenames yield NOTE and never crash or shift NEXT
# - FILENAME kebab derivation, printed only when a title argument is given
#
# Total assertions: 14

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../skills/g-adr/scripts/next-adr.sh"

PASS=0
FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
has() {
    if printf '%s\n' "$1" | grep -qF -- "$2"; then ok "$3"; else bad "$3 (missing: $2)"; fi
}

# ── Task 1: fresh project — dir created, NEXT: 001 ─────────────────────────
DIR=$(mktemp -d)
OUT=$(cd "$DIR" && bash "$SCRIPT"); RC=$?
[ $RC -eq 0 ] && ok "fresh: exit 0" || bad "fresh: exit $RC"
has "$OUT" "DIR_STATE: created" "fresh: g-docs/decisions created"
has "$OUT" "LAST: none" "fresh: LAST none"
has "$OUT" "NEXT: 001" "fresh: NEXT starts at 001, zero-padded"
printf '%s\n' "$OUT" | grep -q '^FILENAME:' \
    && bad "fresh: FILENAME printed without a title arg" \
    || ok "fresh: no FILENAME without a title arg"
rm -rf "$DIR"

# ── Task 2: existing ADRs with a gap — highest + 1 ─────────────────────────
DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/decisions"
touch "$DIR/g-docs/decisions/001-first.md" "$DIR/g-docs/decisions/003-third.md"
OUT=$(cd "$DIR" && bash "$SCRIPT")
has "$OUT" "DIR_STATE: exists" "existing: dir already there"
has "$OUT" "LAST: 003-third.md" "existing: LAST is highest-numbered file"
has "$OUT" "NEXT: 004" "existing: NEXT = highest + 1 (gap tolerated)"
rm -rf "$DIR"

# ── Task 3: legacy/non-numeric filename — NOTE, no crash, NEXT unshifted ───
DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/decisions"
touch "$DIR/g-docs/decisions/002-ok.md" "$DIR/g-docs/decisions/README.md"
OUT=$(cd "$DIR" && bash "$SCRIPT"); RC=$?
[ $RC -eq 0 ] && ok "legacy: exit 0 despite non-numeric file" || bad "legacy: exit $RC"
has "$OUT" "NOTE: non-numeric or legacy filename ignored: README.md" "legacy: anomaly NOTE printed"
has "$OUT" "NEXT: 003" "legacy: NEXT unaffected by non-numeric file"
rm -rf "$DIR"

# ── Task 4: FILENAME kebab derivation from a title argument ────────────────
DIR=$(mktemp -d)
OUT=$(cd "$DIR" && bash "$SCRIPT" "Use PostgreSQL instead of SQLite!")
has "$OUT" "FILENAME: 001-use-postgresql-instead-of-sqlite.md" \
    "title: kebab filename (lowercased, punctuation squeezed, trimmed)"
rm -rf "$DIR"

# ── Task 5: node_modules exclusion ─────────────────────────────────────────
DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/decisions" "$DIR/node_modules/pkg/g-docs/decisions"
touch "$DIR/g-docs/decisions/005-real.md"
touch "$DIR/node_modules/pkg/g-docs/decisions/099-vendored.md"
OUT=$(cd "$DIR" && bash "$SCRIPT")
has "$OUT" "NEXT: 006" "node_modules: vendored decisions dir excluded from numbering"
has "$OUT" "LAST: 005-real.md" "node_modules: LAST comes from the real corpus"
rm -rf "$DIR"

# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

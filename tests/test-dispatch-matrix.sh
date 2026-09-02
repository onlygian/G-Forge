#!/bin/bash
# Pins the v2.6 model-economy dispatch matrix (rules/dispatch-matrix.md — the
# canonical file) against agent frontmatter:
#   1. The agent list is DERIVED from the agents/*.md glob (ADR-013 rule 1:
#      consumers derive, never restate; the references/ subdir is naturally
#      excluded by the glob). Every agent file must have a matrix row, and
#      every per-agent matrix row must have an agent file.
#   2. Each agent's frontmatter `model:` and `effort:` must equal the matrix
#      row's model and effort columns. The matrix file is canonical: on a real
#      divergence the agent file is wrong, not this suite.
#   3. The six Haiku-Executability Standard (HES) items are pinned to parity
#      between rules/dispatch-matrix.md (canonical, single-line items) and the
#      embedded copy in agents/spec-writer.md (hard-wrapped for prose width).
#      Comparison is byte-exact after unwrapping continuation lines and
#      collapsing runs of whitespace — the only transform applied, so any
#      wording, punctuation, or ordering drift still goes red.
#
# The matrix's "stack implementers (templates/stack-implementer.md)" row is not
# an agents/*.md file and is exempt from the file<->row pairing (checked via
# its own template pin instead).
#
# falsifiability: spec-writer effort flipped to 'low' and HES item 6 reworded
# in a scratch copy, suite confirmed red on both — 2026-09-02.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
MATRIX="$REPO_ROOT/rules/dispatch-matrix.md"
SPEC_WRITER="$REPO_ROOT/agents/spec-writer.md"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# ── Preconditions ─────────────────────────────────────────────────────────────

[ -f "$MATRIX" ] || { echo "FAIL: canonical matrix not found at rules/dispatch-matrix.md"; echo ""; echo "Results: 0 passed, 1 failed"; exit 1; }
[ -f "$SPEC_WRITER" ] || { echo "FAIL: agents/spec-writer.md not found"; echo ""; echo "Results: 0 passed, 1 failed"; exit 1; }

# ── Parse the matrix table into name<TAB>model<TAB>effort ────────────────────
# Table rows look like: | agent-name | role | model | effort | escalates-to |
# Header and separator rows are skipped; the stack-implementers template row is
# excluded from the per-agent-file pairing.

MATRIX_ROWS=$(awk -F'|' '
    /^## The matrix/ { insec=1; next }
    /^## / { insec=0 }
    insec && /^\|/ {
        name=$2; role=$3; model=$4; effort=$5
        gsub(/^[ \t]+|[ \t]+$/, "", name)
        gsub(/^[ \t]+|[ \t]+$/, "", model)
        gsub(/^[ \t]+|[ \t]+$/, "", effort)
        if (name == "Agent" || name ~ /^-+$/) next
        if (name ~ /stack implementers/) next
        print name "\t" model "\t" effort
    }' "$MATRIX")

MATRIX_COUNT=$(printf '%s\n' "$MATRIX_ROWS" | grep -c .)
if [ "$MATRIX_COUNT" -gt 0 ]; then
    pass "matrix table parsed — $MATRIX_COUNT per-agent rows"
else
    fail "matrix table parsed — no per-agent rows found in rules/dispatch-matrix.md"
fi

matrix_lookup() { # <agent-name> -> "model<TAB>effort" or empty
    printf '%s\n' "$MATRIX_ROWS" | awk -F'\t' -v n="$1" '$1 == n { print $2 "\t" $3; exit }'
}

# ── 1+2. Derived agent list vs matrix ────────────────────────────────────────

AGENT_NAMES=""
for f in "$REPO_ROOT"/agents/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    AGENT_NAMES="$AGENT_NAMES$name
"
    # frontmatter = lines between the first two --- fences
    model=$(awk '/^---$/{c++; next} c==1 && /^model:/{sub(/^model:[ \t]*/, ""); print; exit}' "$f")
    effort=$(awk '/^---$/{c++; next} c==1 && /^effort:/{sub(/^effort:[ \t]*/, ""); print; exit}' "$f")

    row=$(matrix_lookup "$name")
    if [ -z "$row" ]; then
        fail "$name — agent file has no row in the dispatch matrix"
        continue
    fi
    want_model=$(printf '%s' "$row" | cut -f1)
    want_effort=$(printf '%s' "$row" | cut -f2)

    if [ "$model" = "$want_model" ]; then
        pass "$name model: $model"
    else
        fail "$name model: frontmatter '$model' != matrix '$want_model' (matrix is canonical)"
    fi
    if [ "$effort" = "$want_effort" ]; then
        pass "$name effort: $effort"
    else
        fail "$name effort: frontmatter '$effort' != matrix '$want_effort' (matrix is canonical)"
    fi
done

# Reverse direction: every per-agent matrix row names an existing agent file.
MISSING=$(printf '%s\n' "$MATRIX_ROWS" | cut -f1 | while read -r n; do
    printf '%s' "$AGENT_NAMES" | grep -qx "$n" || echo "$n"
done)
if [ -z "$MISSING" ]; then
    pass "every per-agent matrix row has an agents/*.md file"
else
    fail "matrix rows without an agent file: $(echo "$MISSING" | tr '\n' ' ')"
fi

# The template row is pinned separately: it must exist and point at a real file.
if grep -q '| stack implementers (templates/stack-implementer.md) |' "$MATRIX"; then
    pass "stack-implementers template row present in matrix"
else
    fail "stack-implementers template row missing from matrix"
fi

# ── 3. HES six-item parity (canonical vs embedded copy) ──────────────────────
# Extract "1. Exact paths" through "6. Bounded scope" from each file, unwrap
# hard-wrapped continuation lines (leading whitespace) into single spaces,
# collapse whitespace runs, then require byte equality.

hes_block() { # <file>
    awk '/^1\. Exact paths/{f=1} f{print} f && /^6\. Bounded scope/{exit}' "$1" \
        | sed -E ':a;N;$!ba;s/\n[[:space:]]+/ /g' \
        | sed -E 's/[[:space:]]+/ /g; s/ $//'
}

HES_CANON=$(hes_block "$MATRIX")
HES_EMBED=$(hes_block "$SPEC_WRITER")

canon_items=$(printf '%s\n' "$HES_CANON" | grep -cE '^[1-6]\. ')
embed_items=$(printf '%s\n' "$HES_EMBED" | grep -cE '^[1-6]\. ')
if [ "$canon_items" -eq 6 ]; then
    pass "canonical HES block has 6 items"
else
    fail "canonical HES block in rules/dispatch-matrix.md has $canon_items items, expected 6"
fi
if [ "$embed_items" -eq 6 ]; then
    pass "embedded HES block has 6 items"
else
    fail "embedded HES block in agents/spec-writer.md has $embed_items items, expected 6"
fi

if [ -n "$HES_CANON" ] && [ "$HES_CANON" = "$HES_EMBED" ]; then
    pass "HES six items byte-identical (whitespace-unwrapped) between matrix and spec-writer"
else
    fail "HES items diverge between rules/dispatch-matrix.md (canonical) and agents/spec-writer.md"
    diff <(printf '%s\n' "$HES_CANON") <(printf '%s\n' "$HES_EMBED") | sed 's/^/    /'
fi

# The embedded copy must still name the canonical home so future editors know
# which side to fix.
if grep -q 'canonical home: rules/dispatch-matrix.md' "$SPEC_WRITER"; then
    pass "embedded copy carries the canonical-home comment"
else
    fail "embedded copy in agents/spec-writer.md lost its canonical-home comment"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

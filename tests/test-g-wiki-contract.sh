#!/bin/bash
# tests/test-g-wiki-contract.sh — pins the /g-wiki "sharp edges" fixes (#37).
#
# Each case checks a promise that lives in prose (skills / docs) against the
# thing it describes, so the prose cannot drift from its source silently:
#   - the dispatch-shape advice quotes doc-writer's real turn ceiling
#   - the review step exists and names the gate it runs
#   - the .claude/wiki-cadence knob has a READ SITE (a documented-but-unread
#     knob is the .claude/voice-profile defect class, 2.6.2 "Known")
#   - the gate docs carry the timing note and the nested-README note, and the
#     nested-README note is true of the classifier as shipped
#
# Total assertions: 12
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIKI="$ROOT/skills/g-wiki/SKILL.md"
RETRO="$ROOT/skills/g-retro/SKILL.md"
MCLOSE="$ROOT/skills/g-review/references/milestone-close.md"
GATE="$ROOT/g-wiki/commit-gate.md"
WRITER="$ROOT/agents/doc-writer.md"
PASS=0; FAIL=0

ok() { # name  cmd...
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "PASS: $name"; PASS=$((PASS+1))
    else echo "FAIL: $name"; FAIL=$((FAIL+1)); fi
}
has() { grep -qF -- "$2" "$1"; }

# --- review step ---------------------------------------------------------
ok "g-wiki has a Step 4b verify step"                    has "$WIKI" "## Step 4b — Verify (default-on)"
ok "g-wiki Step 4b runs /g-doc-review and loops to DOCS READY" \
    bash -c 'grep -qF "/g-doc-review" "$1" && grep -qF "until **DOCS READY**" "$1"' _ "$WIKI"
ok "g-wiki report carries the Review line"               has "$WIKI" 'Review: DOCS READY'

# --- dispatch shape quotes the real ceiling --------------------------------
TURNS=$(sed -n 's/^maxTurns: *//p' "$WRITER" | head -1)
ok "doc-writer declares maxTurns (parsed: ${TURNS:-none})" test -n "$TURNS"
ok "g-wiki dispatch advice cites doc-writer's real maxTurns ($TURNS)" has "$WIKI" "$TURNS-turn ceiling"
ok "g-wiki dispatch advice says one page per dispatch and write early" \
    bash -c 'grep -qF "One page per dispatch" "$1" && grep -qF "write early and iterate" "$1"' _ "$WIKI"

# --- cadence knob: documented AND read ---------------------------------------
ok "g-wiki documents .claude/wiki-cadence"               has "$WIKI" ".claude/wiki-cadence"
ok "g-retro READS .claude/wiki-cadence (the knob has a read site)" has "$RETRO" "Read \`.claude/wiki-cadence\`"
ok "milestone-close says its refresh still runs under the override" has "$MCLOSE" "this milestone-close refresh still runs"

# --- gate docs ---------------------------------------------------------------
ok "commit-gate.md carries the PreToolUse timing note"   has "$GATE" "stamp and commit in separate tool calls"
# The nested-README note must be true of the shipped classifier.
nested_is_code() {
    # shellcheck source=../hooks/lib/classify-changeset.sh
    . "$ROOT/hooks/lib/classify-changeset.sh" || return 1
    gf_classify_changeset <<'PATHS'
benchmarks/quality-eval/README.md
PATHS
    [ "$HAS_CODE" = 1 ] && [ "$HAS_DOC" != 1 ]
}
ok "commit-gate.md nested-README note matches the classifier (nested README = code only)" \
    bash -c 'grep -qF "Known false-positive: nested" "$1"' _ "$GATE"
ok "classifier really classifies a nested README as code, not doc" nested_is_code

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

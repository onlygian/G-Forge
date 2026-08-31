#!/bin/bash
# Contract guard for the review-pipeline severity fixes (Bugs B & C).
# The pipeline is LLM-driven — its runtime behaviour can't be unit-tested here.
# What we CAN pin is the prompt contract that makes the fail-open impossible:
# the orchestrator normalizes native scales + forces FAIL on any axis HOLD +
# emits an AXES line; code-lead honours that AXES line when one is supplied; and
# every auditor's return-block scale matches the shared Critical/Major/Minor
# vocabulary it feeds.
# NOTE (2026-08-29): the orchestrator is INERT AS SHIPPED — no shipped skill
# dispatches it and code-lead holds no Agent( grant (agents/code-lead.md, INERT
# stamp), so no AXES line is produced at runtime. These greps pin the CONTRACT
# TEXT so the fail-open cannot silently return if the panel is ever wired; they
# do not assert that the pipeline runs. A future edit that reopens the wording
# mismatch fails these greps — that's the point.
#
# F2 audit (2026-08-30) added three more guard groups: (a) every agents/*.md
# with a `memory:` frontmatter key carries the "Memory holds method, never
# verdicts." rule (F2-3 — a reviewer's persistent memory must never carry a
# cached verdict or count); (b) the ask-and-wait phrases F2-1 identified (a
# dispatched agent has no channel to block on a human answer) are absent from
# every agents/*.md; (c) project-manager.md carries a ## Return format block
# (F2-2). Group (a) is enumerated from disk (grep -l '^memory:'), never a
# typed list, so it grows or shrinks with the agents that actually declare
# memory. The F2 redo pass (same date, finding R-2) added group (b)'s seventh
# literal ('Wait for human approval…'), a positive pin of its dispatched-mode
# replacement text, and the three falsifiability markers.
#
# Total assertions: derived at runtime — group (a)'s size depends on how many
# agents/*.md carry a memory: key on disk. The runner's `Results:` line is the
# RUNNER-OBSERVED total and the only authoritative count (finding-#20
# cross-check); this comment intentionally carries no fixed number to disagree
# with it.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok() { # name  test-cmd...
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "PASS: $name"; PASS=$((PASS+1));
    else echo "FAIL: $name"; FAIL=$((FAIL+1)); fi
}
no() { # name  test-cmd... (asserts the grep does NOT match)
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "FAIL: $name"; FAIL=$((FAIL+1));
    else echo "PASS: $name"; PASS=$((PASS+1)); fi
}

ORCH="$ROOT/agents/review-orchestrator.md"
LEAD="$ROOT/agents/code-lead.md"
PERF="$ROOT/agents/performance-auditor.md"
DEP="$ROOT/agents/dependency-auditor.md"
SEC="$ROOT/agents/security-auditor.md"

# --- Bug B: orchestrator normalization + HOLD propagation + AXES ---
ok  "orchestrator maps security High → Critical" \
    grep -qi 'Critical \*\*and High\*\*' "$ORCH"
ok  "orchestrator: any reviewer HOLD forces aggregate FAIL" \
    grep -qi 'forces aggregate \*\*\?FAIL\|forces aggregate FAIL' "$ORCH"
ok  "orchestrator return block emits an AXES line" \
    grep -q '^AXES:' "$ORCH"
ok  "code-lead honours an AXES line when one is supplied (contract text; inert as shipped)" \
    grep -qi 'axis is HOLD\|AXES' "$LEAD"

# --- Bug C: auditor return scales match the shared Critical/Major/Minor buckets ---
ok  "performance-auditor return uses critical·major·minor" \
    grep -q 'ISSUES: N critical · M major · K minor' "$PERF"
ok  "performance-auditor body defines the Critical/Major/Minor scale" \
    grep -qi 'Severity scale' "$PERF"
ok  "dependency-auditor return uses critical·major·minor" \
    grep -q 'ISSUES: N critical · M major · K minor' "$DEP"
no  "dependency-auditor return no longer uses the stale high/medium/low scale" \
    grep -q 'M high · M medium · K low' "$DEP"

# --- security-auditor KEEPS its native Critical/High/Medium/Low (orchestrator normalizes it) ---
ok  "security-auditor retains its native Critical/High/Medium/Low scale" \
    grep -q 'ISSUES: N critical · M high · M medium · K low' "$SEC"

# --- F2-3: every memory-holding agent carries "Memory holds method, never verdicts." ---
# Enumerated from disk — never a typed list — so a new memory: agent is caught automatically.
# falsifiability: guard neutered in scratch copy (doc-reviewer's rule line deleted → RED; a memory: agent with no rule added → RED naming the new file), test confirmed red — 2026-08-30
MEMORY_AGENTS="$(grep -l '^memory:' "$ROOT"/agents/*.md 2>/dev/null)"
if [ -z "$MEMORY_AGENTS" ]; then
    echo "FAIL: no agents/*.md with a memory: key found on disk (expected at least one)"
    FAIL=$((FAIL+1))
else
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        ok  "$(basename "$f") carries 'Memory holds method, never verdicts.'" \
            grep -qF 'Memory holds method, never verdicts.' "$f"
    done <<< "$MEMORY_AGENTS"
fi

# --- F2-1: ask-and-wait phrases absent from every dispatched agent (no channel to block on) ---
# falsifiability: representative literals re-added in scratch copy ('Only proceed after they answer'; 'Wait for human approval before writing anything'), test confirmed red — 2026-08-30
no  "no 'Only proceed after they answer' in agents/*.md" \
    grep -q 'Only proceed after they answer' "$ROOT"/agents/*.md
no  "no \"Ask for the project's layer rules before reviewing\" in agents/*.md" \
    grep -q "Ask for the project's layer rules before reviewing" "$ROOT"/agents/*.md
no  "no 'ask for the actual error output if not provided' in agents/*.md" \
    grep -q 'ask for the actual error output if not provided' "$ROOT"/agents/*.md
no  "no 'Wait for the developer to answer all three' in agents/*.md" \
    grep -q 'Wait for the developer to answer all three' "$ROOT"/agents/*.md
no  "no 'Do not proceed without explicit human approval' in agents/*.md" \
    grep -q 'Do not proceed without explicit human approval' "$ROOT"/agents/*.md
no  "no 'If Superpowers is available' in agents/*.md" \
    grep -q 'If Superpowers is available' "$ROOT"/agents/*.md
no  "no 'Wait for human approval before writing anything' in agents/*.md" \
    grep -q 'Wait for human approval before writing anything' "$ROOT"/agents/*.md

# Positive pin of the replacement text (code-gate r1 Minor 6): the absence grep above is
# case-sensitive by design — the live PM line carries the same words lowercase behind an
# interactive-role qualifier — so the qualifier's presence is pinned directly here.
ok  "PM Level-1 approval line carries its dispatched-mode route" \
    grep -q 'When dispatched as a subagent, return the proposal' "$ROOT/agents/project-manager.md"

# --- F2-2: project-manager returns a contract, not prose ---
# falsifiability: '## Return format' heading broken in scratch copy, test confirmed red — 2026-08-30
ok  "project-manager.md has a ## Return format block" \
    grep -q '^## Return format' "$ROOT/agents/project-manager.md"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

#!/bin/bash
# Unit tests pinning README.md's hand-typed counts against their disk-derived sources
# (ADR-013 rule 2: a hand-typed count is pinned by a test that fails when source and
# claim disagree, or omitted — never left unpinned).
#
# Pins three README sentences, each matched by anchor text/shape rather than by line
# number (which moves) or by the numbers they currently carry (which drift — see the
# derivation notes below and the Results line at the end of a run, never a count
# restated here per ADR-013):
#   - README agent/skill/profile sentence — "All **N** G-Forge agents, **N** skills,
#     N stack profiles, N combo profiles, and N supplementary profile..."
#   - README doctor-checks sentence — /g-forge doctor check total + required/advisory split
#   - README Agents-section count — the agent count repeated in the Agents section
#
# Each sentence is matched by its full literal shape (fixed text anchors, numbers
# captured via regex groups) so a moved/reworded sentence FAILs, not just a changed
# number. README path is overridable via GF_README_PATH for the falsifiability probe.
#
# Profile split derivation (stack / combo / supplementary, summing to the total
# `profiles/*/` dirs on disk):
#   - combo profiles install rules only, no architect agent (skills/g-specialize/SKILL.md:121,389)
#     -> on disk this is exactly "no profiles/<name>/agents/ subdirectory"
#   - the one supplementary profile is frontend-data-flow (skills/g-specialize/SKILL.md:295) —
#     it DOES have an agents/ subdir (frontend-data-flow-architect.md), so it is pinned by
#     name, not by the agents-subdir test that isolates combos
#   - stack profile count = total - combo - supplementary
#
# Doctor check split derivation (required / advisory, summing to the total heading count):
#   skills/g-doctor/SKILL.md numbers each check as a bold heading "**N. name**" (optionally
#   suffixed "(advisory...)" for the advisory-tier checks, confirmed by Step 1's own prose
#   at SKILL.md:10). Total = count of heading lines; advisory = count of heading lines
#   containing "(advisory"; required = total - advisory.

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TESTS_DIR")"
README="${GF_README_PATH:-$REPO_ROOT/README.md}"
AGENTS_DIR="$REPO_ROOT/agents"
SKILLS_DIR="$REPO_ROOT/skills"
PROFILES_DIR="$REPO_ROOT/profiles"
DOCTOR_SKILL="$SKILLS_DIR/g-doctor/SKILL.md"

PASS=0
FAIL=0

# ── Derive counts from disk ─────────────────────────────────────────────────

AGENT_COUNT=0
for f in "$AGENTS_DIR"/*.md; do
    [ -e "$f" ] || continue
    AGENT_COUNT=$((AGENT_COUNT+1))
done

SKILL_COUNT=0
for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    SKILL_COUNT=$((SKILL_COUNT+1))
done

PROFILE_TOTAL=0
COMBO_COUNT=0
for d in "$PROFILES_DIR"/*/; do
    [ -d "$d" ] || continue
    PROFILE_TOTAL=$((PROFILE_TOTAL+1))
    if [ ! -d "${d}agents" ]; then
        COMBO_COUNT=$((COMBO_COUNT+1))
    fi
done
# The one supplementary profile — pinned by name (has an agents/ subdir, so it is not
# swept up by the combo test above; frontend-data-flow is the only such case on disk).
SUPPLEMENTARY_COUNT=0
if [ -d "$PROFILES_DIR/frontend-data-flow" ] && [ -d "$PROFILES_DIR/frontend-data-flow/agents" ]; then
    SUPPLEMENTARY_COUNT=1
fi
STACK_COUNT=$((PROFILE_TOTAL - COMBO_COUNT - SUPPLEMENTARY_COUNT))

DOCTOR_TOTAL=$(grep -c -E '^\*\*[0-9]+\.' "$DOCTOR_SKILL")
DOCTOR_ADVISORY=$(grep -c -E '^\*\*[0-9]+\..*\(advisory' "$DOCTOR_SKILL")
DOCTOR_REQUIRED=$((DOCTOR_TOTAL - DOCTOR_ADVISORY))

echo "PASS: derived counts from disk — agents=$AGENT_COUNT skills=$SKILL_COUNT profiles_total=$PROFILE_TOTAL (stack=$STACK_COUNT combo=$COMBO_COUNT supplementary=$SUPPLEMENTARY_COUNT) doctor_checks=$DOCTOR_TOTAL (required=$DOCTOR_REQUIRED advisory=$DOCTOR_ADVISORY)"
PASS=$((PASS+1))

if [ ! -f "$README" ]; then
    echo "FAIL: README not found at $README"
    FAIL=$((FAIL+1))
    echo ""
    echo "Results: $PASS passed, $FAIL failed"
    exit 1
fi

# ── Test 1: README agent/skill/profile sentence ────────────────────────────
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-29

LINE150=$(grep -m1 -E '^All \*\*[0-9]+\*\* G-Forge agents, \*\*[0-9]+\*\* skills, [0-9]+ stack profiles, [0-9]+ combo profiles, and [0-9]+ supplementary profile \(frontend-data-flow\) become available globally across all your projects\.$' "$README")

if [ -n "$LINE150" ]; then
    R_AGENTS=$(echo "$LINE150" | sed -E 's/^All \*\*([0-9]+)\*\*.*/\1/')
    R_SKILLS=$(echo "$LINE150" | sed -E 's/^.*G-Forge agents, \*\*([0-9]+)\*\* skills.*/\1/')
    R_STACK=$(echo "$LINE150" | sed -E 's/^.*skills, ([0-9]+) stack profiles.*/\1/')
    R_COMBO=$(echo "$LINE150" | sed -E 's/^.*stack profiles, ([0-9]+) combo profiles.*/\1/')
    R_SUPP=$(echo "$LINE150" | sed -E 's/^.*combo profiles, and ([0-9]+) supplementary profile.*/\1/')

    if [ "$R_AGENTS" = "$AGENT_COUNT" ] && [ "$R_SKILLS" = "$SKILL_COUNT" ] && \
       [ "$R_STACK" = "$STACK_COUNT" ] && [ "$R_COMBO" = "$COMBO_COUNT" ] && \
       [ "$R_SUPP" = "$SUPPLEMENTARY_COUNT" ]; then
        echo "PASS: README agent/skill/profile sentence counts agree with disk ($R_AGENTS/$R_SKILLS/$R_STACK/$R_COMBO/$R_SUPP)"
        PASS=$((PASS+1))
    else
        echo "FAIL: README agent/skill/profile sentence counts disagree with disk — README has agents=$R_AGENTS skills=$R_SKILLS stack=$R_STACK combo=$R_COMBO supplementary=$R_SUPP; disk has agents=$AGENT_COUNT skills=$SKILL_COUNT stack=$STACK_COUNT combo=$COMBO_COUNT supplementary=$SUPPLEMENTARY_COUNT"
        FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: README agent/skill/profile sentence not found (moved, reworded, or missing) — expected shape 'All **N** G-Forge agents, **N** skills, N stack profiles, N combo profiles, and N supplementary profile (frontend-data-flow) become available globally across all your projects.'"
    FAIL=$((FAIL+1))
fi

# ── Test 2: README doctor-checks sentence ───────────────────────────────────
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-29

LINE277=$(grep -m1 -E '^/g-forge doctor →   verify hooks, settings, rules block, and drift — [0-9]+ checks \([0-9]+ required \+ [0-9]+ advisory\)$' "$README")

if [ -n "$LINE277" ]; then
    R_DTOTAL=$(echo "$LINE277" | sed -E 's/^.*drift — ([0-9]+) checks.*/\1/')
    R_DREQ=$(echo "$LINE277" | sed -E 's/^.*\(([0-9]+) required \+ [0-9]+ advisory\)$/\1/')
    R_DADV=$(echo "$LINE277" | sed -E 's/^.*\+ ([0-9]+) advisory\)$/\1/')

    if [ "$R_DTOTAL" = "$DOCTOR_TOTAL" ] && [ "$R_DREQ" = "$DOCTOR_REQUIRED" ] && [ "$R_DADV" = "$DOCTOR_ADVISORY" ]; then
        echo "PASS: README doctor-checks sentence counts agree with disk ($R_DTOTAL checks, $R_DREQ required + $R_DADV advisory)"
        PASS=$((PASS+1))
    else
        echo "FAIL: README doctor-checks sentence counts disagree with disk — README has total=$R_DTOTAL required=$R_DREQ advisory=$R_DADV; disk has total=$DOCTOR_TOTAL required=$DOCTOR_REQUIRED advisory=$DOCTOR_ADVISORY"
        FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: README doctor-checks sentence not found (moved, reworded, or missing) — expected shape '/g-forge doctor ->   verify hooks, settings, rules block, and drift - N checks (N required + N advisory)'"
    FAIL=$((FAIL+1))
fi

# ── Test 3: README Agents-section count ─────────────────────────────────────
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-29

LINE382=$(grep -m1 -E '^\*\*[0-9]+\*\* agents ship with every install\. Full reference: \[g-docs/agents\.md\]\(g-docs/agents\.md\)$' "$README")

if [ -n "$LINE382" ]; then
    R_AGENTS382=$(echo "$LINE382" | sed -E 's/^\*\*([0-9]+)\*\*.*/\1/')

    if [ "$R_AGENTS382" = "$AGENT_COUNT" ]; then
        echo "PASS: README Agents-section count agrees with disk ($R_AGENTS382)"
        PASS=$((PASS+1))
    else
        echo "FAIL: README Agents-section count disagrees with disk — README has $R_AGENTS382, disk has $AGENT_COUNT"
        FAIL=$((FAIL+1))
    fi
else
    echo "FAIL: README Agents-section count sentence not found (moved, reworded, or missing) — expected shape '**N** agents ship with every install. Full reference: [g-docs/agents.md](g-docs/agents.md)'"
    FAIL=$((FAIL+1))
fi

# ── Summary ──────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

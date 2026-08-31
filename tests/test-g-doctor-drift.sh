#!/bin/bash
# Unit tests for g-doctor Check 16: installed-copy drift detection
# Verifies the hash-comparison mechanism correctly identifies matching and mismatched
# hooks using the portable cascade (sha256sum → shasum -a 256 → cksum).
#
# Extended for W1.5g (M-audit tasks 3+4):
#   Tests 1-3: Hook drift detection (3 assertions, existing)
#   Tests 4-6: G-rules path drift (3 assertions, 10-file flat-rename mapping: rules/g-rules/*.md → .claude/rules/g-rules-*.md)
#   Tests 7-11: Agent classifier (6 assertions: profile-copied match/mismatch/missing, template-instantiated advisory-only, project-local *-dev.md excluded)
# Extended for W3 task 3 (M-audit finding #23 / BUG-4):
#   Tests 12-14: Check 21 stray-doc scan, fail-before/pass-after (5 assertions: old fixed 6-name
#   allowlist misses agent-output/plans strays, new inverted check — canonical names derived from
#   g-docs/ subdirs — catches them, no false positive on a clean tree)
# Extended for M48b tasks 5+6 (audit-7 finding F4):
#   Test 3b: cksum branch derivation (2 assertions) — the cksum fallback in compare_hashes()
#   now executes a `cksum_hash` function eval'd from the line grepped out of the shipped
#   skills/g-doctor/SKILL.md hash_file() cascade at runtime, instead of a hand-typed mimic.
#   Catches the exact drift that had already crept in: the old mimic hand-typed
#   `awk '{print $1}'` while the shipped snippet reads `awk '{print $1, $2}'`.
# Extended in fix round r1 (code-lead HOLD, minor m3 — F4 was closed for only
# 1 of 3 cascade branches): the sha256sum and shasum -a 256 branches of
# compare_hashes() are now ALSO derived at runtime from SKILL.md
# (sha256sum_hash / shasum_hash), the same mechanism as cksum_hash — these
# are the two branches that actually run on a dev machine with either tool
# installed, so they were the un-derived branches actually being exercised.
# Each of the three derivations is now preceded by a single-match assertion
# on its grep (grep -cF … -eq 1) so a SKILL.md shape change (second matching
# line) fails loud with `exit 1` instead of eval-ing an unexpected snippet.
# Extended for A7 drift-set resync (task 10): Check 16 now also drift-checks
# the installed `.claude/skills/architecture-<stack>/SKILL.md` copy against
# its `profiles/<stack>/rules/architecture.md` source (frontmatter stripped).
#   Tests 15-16: grep-pins — skills/g-doctor/SKILL.md Check 16 and
#   skills/g-update/SKILL.md Step 6 both name the artifact, so a future edit
#   that silently drops it goes red here.
#   Tests 17-18: frontmatter-strip + hash-compare actually discriminates —
#   identical stripped body vs. profile source → MATCH; differing → MISMATCH.
# See the Results line at the end of a run for the current total — not
# restated here as a fixed number (an unpinned count is a review finding,
# G-RULES §G/ADR-013).

PASS=0
FAIL=0

check() { # name expected actual
    if [ "$2" = "$3" ]; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1 (expected '$2', got '$3')"; FAIL=$((FAIL+1))
    fi
}

# ── Derive all three hash-cascade branches from the shipped
# skills/g-doctor/SKILL.md hash_file() cascade at runtime, instead of
# hand-typing mimics of them here.
# Falsifiability: this derivation exists because the mimic it replaces had
# already silently diverged — it hand-typed `awk '{print $1}'` while the
# shipped snippet (skills/g-doctor/SKILL.md:125) reads `awk '{print $1, $2}'`
# (checksum AND byte count). Revert this block to hand-typed mimics, or edit
# any of the three SKILL.md lines, in a scratch copy (never in the
# production tree) — the field-count / single-match assertions below must go
# RED.
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_MD="$REPO_ROOT/skills/g-doctor/SKILL.md"

# Each grep must match exactly one line in SKILL.md — a second match means
# the block's shape changed underneath this derivation (e.g. a second cascade
# added, a duplicated example elsewhere in the doc) and eval-ing an
# unexpected line is worse than failing loud here.
SHA256SUM_MATCHES=$(grep -cF 'sha256sum "$1"' "$SKILL_MD")
[ "$SHA256SUM_MATCHES" -eq 1 ] || { echo "FAIL: expected exactly 1 match for sha256sum snippet in $SKILL_MD, got $SHA256SUM_MATCHES"; exit 1; }
SHASUM_MATCHES=$(grep -cF 'shasum -a 256 "$1"' "$SKILL_MD")
[ "$SHASUM_MATCHES" -eq 1 ] || { echo "FAIL: expected exactly 1 match for shasum snippet in $SKILL_MD, got $SHASUM_MATCHES"; exit 1; }
CKSUM_MATCHES=$(grep -cF 'cksum "$1"' "$SKILL_MD")
[ "$CKSUM_MATCHES" -eq 1 ] || { echo "FAIL: expected exactly 1 match for cksum snippet in $SKILL_MD, got $CKSUM_MATCHES"; exit 1; }

SHA256SUM_LINE=$(grep -F 'sha256sum "$1"' "$SKILL_MD" | sed 's/^[[:space:]]*//')
[ -n "$SHA256SUM_LINE" ] || { echo "FAIL: could not derive sha256sum snippet from $SKILL_MD"; exit 1; }
eval "sha256sum_hash() { $SHA256SUM_LINE ; }"

SHASUM_LINE=$(grep -F 'shasum -a 256 "$1"' "$SKILL_MD" | sed 's/^[[:space:]]*//')
[ -n "$SHASUM_LINE" ] || { echo "FAIL: could not derive shasum snippet from $SKILL_MD"; exit 1; }
eval "shasum_hash() { $SHASUM_LINE ; }"

CKSUM_LINE=$(grep -F 'cksum "$1"' "$SKILL_MD" | sed 's/^[[:space:]]*//')
[ -n "$CKSUM_LINE" ] || { echo "FAIL: could not derive cksum snippet from $SKILL_MD"; exit 1; }
eval "cksum_hash() { $CKSUM_LINE ; }"

# compare_hashes <canonical> <installed> — verifies drift detection
# Returns "MATCH" if hashes are identical, "MISMATCH" if different, "MISSING" if installed copy absent.
# Implements the portable cascade: sha256sum → shasum -a 256 → cksum (all
# three branches execute their *_hash function, derived above, verbatim from
# SKILL.md)
compare_hashes() {
    local canonical="$1" installed="$2"

    # If installed copy does not exist, report MISSING
    [ -f "$installed" ] || { echo "MISSING"; return 0; }

    local canon_hash installed_hash

    # Cascade 1: Try sha256sum (Linux, macOS, modern BSD) — derived from SKILL.md
    if command -v sha256sum >/dev/null 2>&1; then
        canon_hash=$(sha256sum_hash "$canonical" 2>/dev/null)
        installed_hash=$(sha256sum_hash "$installed" 2>/dev/null)
    # Cascade 2: Fallback to shasum -a 256 (macOS, BSD, git-bash) — derived from SKILL.md
    elif command -v shasum >/dev/null 2>&1; then
        canon_hash=$(shasum_hash "$canonical" 2>/dev/null)
        installed_hash=$(shasum_hash "$installed" 2>/dev/null)
    # Cascade 3: Fallback to cksum (portable, POSIX-only) — derived from SKILL.md, not hand-typed
    elif command -v cksum >/dev/null 2>&1; then
        canon_hash=$(cksum_hash "$canonical" 2>/dev/null)
        installed_hash=$(cksum_hash "$installed" 2>/dev/null)
    else
        # No hash command available
        echo "ERROR"
        return 1
    fi

    # Compare hashes: equal → MATCH, different → MISMATCH
    if [ "$canon_hash" = "$installed_hash" ]; then
        echo "MATCH"
    else
        echo "MISMATCH"
    fi
}

# ────────────────────────────────────────────────────────────────────────────

# Test 1: IDENTICAL CONTENT → hashes equal → MATCH (no drift)
# Scenario: canonical and installed copies have identical content (expected steady state).
# Expected: compare_hashes reports MATCH.
#
# Trace:
#   - Create hooks/sample.sh with "#!/bin/bash\necho hook1\n"
#   - Copy it to .claude/hooks/sample.sh (bit-identical)
#   - Compute hash of hooks/sample.sh (e.g., sha256sum = abc123...)
#   - Compute hash of .claude/hooks/sample.sh (same content = abc123...)
#   - abc123... == abc123... → MATCH ✓

echo "Test 1: Identical canonical and installed hooks"
FIXTURE1=$(mktemp -d)
cd "$FIXTURE1" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p hooks .claude/hooks

# Fixed, deterministic content (no Date.now, no random)
HOOK_CONTENT="#!/bin/bash
# Sample hook for g-forge
echo 'sample hook executed'
exit 0
"
printf '%s\n' "$HOOK_CONTENT" > hooks/sample.sh
cp hooks/sample.sh .claude/hooks/sample.sh

RESULT=$(compare_hashes "hooks/sample.sh" ".claude/hooks/sample.sh")
check "identical files: hashes match (no drift)" "MATCH" "$RESULT"

cd / && rm -rf "$FIXTURE1"

# Test 2: DIFFERENT CONTENT → hashes differ → MISMATCH (drift detected)
# Scenario: canonical has current code, installed copy has staled old code (drift).
# Expected: compare_hashes reports MISMATCH.
#
# Trace:
#   - Create hooks/other.sh with "#!/bin/bash\necho v1\n" (canonical, current)
#   - Create .claude/hooks/other.sh with "#!/bin/bash\necho v2-staled\n" (installed, old)
#   - Compute hash of hooks/other.sh (e.g., sha256sum = def456...)
#   - Compute hash of .claude/hooks/other.sh (different content = ghi789...)
#   - def456... != ghi789... → MISMATCH ✓

echo "Test 2: Staled installed hook (drift)"
FIXTURE2=$(mktemp -d)
cd "$FIXTURE2" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p hooks .claude/hooks

# Canonical (current)
CURRENT="#!/bin/bash
# Current version of hook
echo 'current implementation'
exit 0
"
printf '%s\n' "$CURRENT" > hooks/other.sh

# Installed (staled)
STALED="#!/bin/bash
# Old staled version
echo 'staled implementation'
exit 1
"
printf '%s\n' "$STALED" > .claude/hooks/other.sh

RESULT=$(compare_hashes "hooks/other.sh" ".claude/hooks/other.sh")
check "different files: hashes differ (drift detected)" "MISMATCH" "$RESULT"

cd / && rm -rf "$FIXTURE2"

# Test 3: MISSING INSTALLED COPY → no hash comparison possible → MISSING
# Scenario: canonical hook exists but its installed copy is absent (not yet deployed).
# Expected: compare_hashes reports MISSING.
#
# Trace:
#   - Create hooks/missing.sh with "#!/bin/bash\necho hook\n" (canonical)
#   - Do NOT create .claude/hooks/missing.sh (missing)
#   - Check if .claude/hooks/missing.sh exists → NO
#   - Return MISSING without computing hashes ✓

echo "Test 3: Canonical hook with no installed copy"
FIXTURE3=$(mktemp -d)
cd "$FIXTURE3" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p hooks .claude/hooks

HOOK_CONTENT="#!/bin/bash
# Hook not yet installed
echo 'missing installed copy'
exit 0
"
printf '%s\n' "$HOOK_CONTENT" > hooks/missing.sh
# Intentionally do NOT create .claude/hooks/missing.sh

RESULT=$(compare_hashes "hooks/missing.sh" ".claude/hooks/missing.sh")
check "missing installed copy: detected as MISSING" "MISSING" "$RESULT"

cd / && rm -rf "$FIXTURE3"

# Test 3b: CKSUM BRANCH DERIVATION — cksum_hash (derived from SKILL.md) outputs
# checksum AND byte count, matching the shipped `awk '{print $1, $2}'` snippet.
# Scenario: sha256sum/shasum are present on most CI boxes, so compare_hashes'
# cascade never actually reaches the cksum branch in a normal run — that branch
# would otherwise go untested and the derivation unfalsifiable. This test calls
# cksum_hash directly (bypassing the cascade) so the derivation is provable on
# any box. Expected: 2 space-separated fields (checksum, bytes), first field
# equal to a raw `cksum` call's checksum field.
#
# Trace:
#   - Create f.txt with fixed content
#   - cksum_hash "f.txt" → runs the eval'd line derived from SKILL.md:125
#   - Shipped snippet is `cksum "$1" | awk '{print $1, $2}'` → 2 fields
#   - Field count == 2 (would be 1 if the old hand-typed single-field mimic
#     were still in effect) ✓
#   - Field 1 matches a raw cksum call's checksum field ✓

echo "Test 3b: cksum_hash derivation outputs checksum + byte count (2 fields)"
FIXTURE3B=$(mktemp -d)
cd "$FIXTURE3B" || { echo "FAIL: could not create fixture"; exit 1; }

printf 'cksum derivation fixture, fixed content\n' > f.txt

CK_OUT=$(cksum_hash "f.txt")
CK_FIELD_COUNT=$(echo "$CK_OUT" | wc -w | tr -d ' ')
check "cksum_hash (derived from SKILL.md) outputs 2 fields, matching shipped {print \$1, \$2}" "2" "$CK_FIELD_COUNT"

RAW_FIELD1=$(cksum "f.txt" | cut -d' ' -f1)
CK_FIELD1=$(echo "$CK_OUT" | cut -d' ' -f1)
check "cksum_hash field 1 matches raw cksum checksum field" "$RAW_FIELD1" "$CK_FIELD1"

cd / && rm -rf "$FIXTURE3B"

# ────────────────────────────────────────────────────────────────────────────
# Test 4: G-RULES IDENTICAL CONTENT → hashes equal → MATCH (no drift)
# Scenario: canonical g-rules file and installed copy have identical content.
# Expected: compare_hashes reports MATCH.
# This verifies the 10-file flat-rename mapping: rules/g-rules/X-name.md → .claude/rules/g-rules-X-name.md
#
# Trace:
#   - Create rules/g-rules/A-session.md with "## A · Session Rules\n..."
#   - Copy it to .claude/rules/g-rules-A-session.md (bit-identical)
#   - Compute hash of both → identical hashes → MATCH ✓

echo "Test 4: Identical g-rules file (no drift)"
FIXTURE4=$(mktemp -d)
cd "$FIXTURE4" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p rules/g-rules .claude/rules

# Fixed g-rules content (10-file mapping example: A-session.md)
GRULES_CONTENT="## A · Session Rules

This is the canonical A-session rules file.
Model selection, planning, execution, token optimisation.
"
printf '%s\n' "$GRULES_CONTENT" > rules/g-rules/A-session.md
cp rules/g-rules/A-session.md .claude/rules/g-rules-A-session.md

RESULT=$(compare_hashes "rules/g-rules/A-session.md" ".claude/rules/g-rules-A-session.md")
check "identical g-rules: hashes match (no drift)" "MATCH" "$RESULT"

cd / && rm -rf "$FIXTURE4"

# Test 5: G-RULES DIFFERENT CONTENT → hashes differ → MISMATCH (drift detected)
# Scenario: canonical g-rules has current rules, installed copy has staled version.
# Expected: compare_hashes reports MISMATCH.
#
# Trace:
#   - Create rules/g-rules/B-workflow.md with "## B · Workflow Rules\n..." (canonical, current)
#   - Create .claude/rules/g-rules-B-workflow.md with old "## OLD Workflow\n..." (installed, staled)
#   - Compute hashes → different → MISMATCH ✓

echo "Test 5: Different g-rules file (drift detected)"
FIXTURE5=$(mktemp -d)
cd "$FIXTURE5" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p rules/g-rules .claude/rules

# Canonical (current)
CURRENT_GRULES="## B · Workflow Rules

G-Forge lifecycle, per-task loop, PM interface, skills reference.
Version 2.0 with updated semantics.
"
printf '%s\n' "$CURRENT_GRULES" > rules/g-rules/B-workflow.md

# Installed (staled)
STALED_GRULES="## B · OLD Workflow

Legacy workflow rules (outdated).
Do not use this version.
"
printf '%s\n' "$STALED_GRULES" > .claude/rules/g-rules-B-workflow.md

RESULT=$(compare_hashes "rules/g-rules/B-workflow.md" ".claude/rules/g-rules-B-workflow.md")
check "different g-rules: hashes differ (drift detected)" "MISMATCH" "$RESULT"

cd / && rm -rf "$FIXTURE5"

# Test 6: G-RULES MISSING INSTALLED COPY → no hash comparison possible → MISSING
# Scenario: canonical g-rules exists but its installed copy is absent.
# Expected: compare_hashes reports MISSING.
#
# Trace:
#   - Create rules/g-rules/C-agent-discipline.md (canonical)
#   - Do NOT create .claude/rules/g-rules-C-agent-discipline.md (missing)
#   - Check if installed copy exists → NO
#   - Return MISSING without computing hashes ✓

echo "Test 6: Missing g-rules installed copy"
FIXTURE6=$(mktemp -d)
cd "$FIXTURE6" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p rules/g-rules .claude/rules

GRULES_CONTENT="## C · Agent Discipline

Wave model, spawn decisions, agent caps.
"
printf '%s\n' "$GRULES_CONTENT" > rules/g-rules/C-agent-discipline.md
# Intentionally do NOT create .claude/rules/g-rules-C-agent-discipline.md

RESULT=$(compare_hashes "rules/g-rules/C-agent-discipline.md" ".claude/rules/g-rules-C-agent-discipline.md")
check "missing g-rules installed copy: detected as MISSING" "MISSING" "$RESULT"

cd / && rm -rf "$FIXTURE6"

# ────────────────────────────────────────────────────────────────────────────
# Agent Classifier Tests (Tests 7-11)
# Three classes of agents in G-Forge:
#   1. Profile-copied agents: profiles/<stack>/agents/<name>.md (hash-compare, Fail on mismatch/missing)
#   2. Template-instantiated agents: agents/<name>.md at root (advisory-only, never Fail)
#   3. Project-local *-dev.md agents: .claude/agents/*-dev.md (excluded entirely, zero-drift)

# Helper function: classify_agent <canonical_path>
# Returns: "PROFILE_COPIED", "TEMPLATE_INSTANTIATED", or "PROJECT_LOCAL_DEV"
# This mimics the Check 16 agent classification logic
classify_agent() {
    local canonical="$1"

    # Check if it's a project-local *-dev.md agent (.claude/agents/*-dev.md)
    if [[ "$canonical" =~ \.claude/agents/.*-dev\.md$ ]]; then
        echo "PROJECT_LOCAL_DEV"
        return 0
    fi

    # Check if it's a profile-copied agent (profiles/<stack>/agents/<name>.md)
    if [[ "$canonical" =~ ^profiles/[^/]+/agents/[^/]+\.md$ ]]; then
        echo "PROFILE_COPIED"
        return 0
    fi

    # Otherwise, it's template-instantiated (agents/<name>.md at root)
    if [[ "$canonical" =~ ^agents/[^/]+\.md$ ]]; then
        echo "TEMPLATE_INSTANTIATED"
        return 0
    fi

    # Unknown classification
    echo "UNKNOWN"
    return 1
}

# Test 7: PROFILE-COPIED AGENT MATCHING → hashes equal → MATCH (no drift)
# Scenario: profile-copied agent exists in both canonical (plugin profiles/) and installed (.claude/agents/)
# with identical content. This represents a healthy, synced profile-copied agent.
# Expected: compare_hashes reports MATCH.
#
# Trace:
#   - Create profiles/test-stack/agents/test-architect.md (canonical, in plugin source)
#   - Create .claude/agents/test-architect.md (installed, copied by /g-init)
#   - Content is identical
#   - Classify as PROFILE_COPIED
#   - compare_hashes reports MATCH ✓

echo "Test 7: Profile-copied agent matching (no drift)"
FIXTURE7=$(mktemp -d)
cd "$FIXTURE7" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p profiles/test-stack/agents .claude/agents

AGENT_CONTENT="---
name: test-architect
description: Test stack architecture specialist. Validates structure and design.
model: sonnet
tools: Read, Glob, Grep
---

You are a test stack architecture validator.
"
printf '%s\n' "$AGENT_CONTENT" > profiles/test-stack/agents/test-architect.md
cp profiles/test-stack/agents/test-architect.md .claude/agents/test-architect.md

# Classify
CLASSIFICATION=$(classify_agent "profiles/test-stack/agents/test-architect.md")
check "profile-copied agent classification" "PROFILE_COPIED" "$CLASSIFICATION"

# Compare hashes
RESULT=$(compare_hashes "profiles/test-stack/agents/test-architect.md" ".claude/agents/test-architect.md")
check "profile-copied agent matching (no drift)" "MATCH" "$RESULT"

cd / && rm -rf "$FIXTURE7"

# Test 8: PROFILE-COPIED AGENT MISMATCH → hashes differ → MISMATCH (drift detected)
# Scenario: profile-copied agent has drifted — canonical and installed have different content.
# Expected: compare_hashes reports MISMATCH.
#
# Trace:
#   - Create profiles/another-stack/agents/another-architect.md (canonical, current)
#   - Create .claude/agents/another-architect.md (installed, staled version)
#   - Hashes differ
#   - compare_hashes reports MISMATCH ✓

echo "Test 8: Profile-copied agent mismatch (drift detected)"
FIXTURE8=$(mktemp -d)
cd "$FIXTURE8" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p profiles/another-stack/agents .claude/agents

# Canonical (current, v2.0)
CURRENT_AGENT="---
name: another-architect
description: Another stack architecture specialist. Validates structure and design (v2.0).
model: sonnet
tools: Read, Glob, Grep
---

You are an another stack architecture validator.
Current version with new rules.
"
printf '%s\n' "$CURRENT_AGENT" > profiles/another-stack/agents/another-architect.md

# Installed (staled, v1.0)
STALED_AGENT="---
name: another-architect
description: Another stack architecture specialist (v1.0 - outdated).
model: sonnet
tools: Read, Glob
---

You are an another stack architecture validator.
Old version.
"
printf '%s\n' "$STALED_AGENT" > .claude/agents/another-architect.md

RESULT=$(compare_hashes "profiles/another-stack/agents/another-architect.md" ".claude/agents/another-architect.md")
check "profile-copied agent mismatch (drift detected)" "MISMATCH" "$RESULT"

cd / && rm -rf "$FIXTURE8"

# Test 9: PROFILE-COPIED AGENT MISSING → installed copy absent → MISSING
# Scenario: profile-copied agent exists in canonical but its installed copy is absent (not yet deployed).
# Expected: compare_hashes reports MISSING.
#
# Trace:
#   - Create profiles/new-stack/agents/new-architect.md (canonical)
#   - Do NOT create .claude/agents/new-architect.md (missing)
#   - Check if installed copy exists → NO
#   - Return MISSING ✓

echo "Test 9: Profile-copied agent missing (not yet deployed)"
FIXTURE9=$(mktemp -d)
cd "$FIXTURE9" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p profiles/new-stack/agents .claude/agents

AGENT_CONTENT="---
name: new-architect
description: New stack architecture specialist.
model: sonnet
tools: Read, Glob, Grep
---

You are a new stack architecture validator.
"
printf '%s\n' "$AGENT_CONTENT" > profiles/new-stack/agents/new-architect.md
# Intentionally do NOT create .claude/agents/new-architect.md

RESULT=$(compare_hashes "profiles/new-stack/agents/new-architect.md" ".claude/agents/new-architect.md")
check "profile-copied agent missing (not yet deployed)" "MISSING" "$RESULT"

cd / && rm -rf "$FIXTURE9"

# Test 10: TEMPLATE-INSTANTIATED AGENT CLASSIFICATION → advisory-only (never Fail)
# Scenario: template-instantiated agent (e.g., agents/feature-implementer.md) is classified correctly
# and is treated as advisory-only, never Fail.
# Expected: classify_agent reports TEMPLATE_INSTANTIATED.
# This test verifies that the agent classifier correctly identifies template-instantiated agents
# and ensures Check 16 will only produce advisories for them, not failures.
#
# Trace:
#   - Classify agents/feature-implementer.md
#   - Classification should be TEMPLATE_INSTANTIATED
#   - Check 16 logic: template-instantiated agents are advisory-only (never Fail) ✓

echo "Test 10: Template-instantiated agent classification (advisory-only, never Fail)"
FIXTURE10=$(mktemp -d)
cd "$FIXTURE10" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p agents

TEMPLATE_AGENT="---
name: feature-implementer
description: Generic, stack-agnostic wave implementer.
model: sonnet
tools: Read, Glob, Grep, Write, Edit, Bash
---

You are a generic wave implementer.
"
printf '%s\n' "$TEMPLATE_AGENT" > agents/feature-implementer.md

CLASSIFICATION=$(classify_agent "agents/feature-implementer.md")
check "template-instantiated agent classification" "TEMPLATE_INSTANTIATED" "$CLASSIFICATION"

cd / && rm -rf "$FIXTURE10"

# Test 11: PROJECT-LOCAL *-DEV.MD AGENT EXCLUSION → completely excluded (zero-drift/no-op)
# Scenario: project-local agent (e.g., .claude/agents/g-forge-dev.md) is classified and excluded
# from drift detection entirely. It should never be compared against anything.
# Expected: classify_agent reports PROJECT_LOCAL_DEV and Check 16 produces zero-drift (no-op).
#
# Trace:
#   - Classify .claude/agents/g-forge-dev.md
#   - Classification should be PROJECT_LOCAL_DEV
#   - Check 16 logic: project-local *-dev.md agents are excluded entirely (zero-drift/no-op) ✓

echo "Test 11: Project-local *-dev.md agent excluded (zero-drift/no-op)"
FIXTURE11=$(mktemp -d)
cd "$FIXTURE11" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p .claude/agents

DEV_AGENT="---
name: g-forge-dev
description: Use proactively to run this repo's test suites.
model: haiku
tools: Read, Glob, Grep, Bash
---

You run G-Forge's own test suites and report VERBATIM runner output.
"
printf '%s\n' "$DEV_AGENT" > .claude/agents/g-forge-dev.md

CLASSIFICATION=$(classify_agent ".claude/agents/g-forge-dev.md")
check "project-local *-dev.md agent classification" "PROJECT_LOCAL_DEV" "$CLASSIFICATION"

cd / && rm -rf "$FIXTURE11"

# ────────────────────────────────────────────────────────────────────────────
# Check 21 Stray-Doc Scan Tests (Tests 12-14)
# M-audit finding #23 / BUG-4: the old Check 21 used a fixed 6-name dir allowlist
# (decisions|retros|forecasts|telemetry|blast-radius|alignment), so a parallel docs/
# tree (agent-output/, plans/, qa-scope/) slipped through undetected. The fix inverts
# the check: canonical dir names are derived from whatever already lives directly
# under g-docs/ in the project, then any directory sharing one of those names anywhere
# outside g-docs/ or g-wiki/ is flagged as a stray.

# old_stray_check — mimics the OLD (pre-fix) Check 21 bash snippet: a fixed 6-name
# dir allowlist. Must be run with cwd at the fixture root. Prints stray dir paths found
# (empty output = none found).
old_stray_check() {
    find . -type d \( -name decisions -o -name retros -o -name forecasts -o -name telemetry -o -name blast-radius -o -name alignment \) \
      -not -path './g-docs/*' -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null
}

# new_stray_check — mimics the NEW (post-fix) Check 21 bash snippet: an inverted check.
# Canonical dir names are derived from whatever already lives directly under g-docs/ in
# this fixture, then any directory sharing one of those names anywhere outside g-docs/ or
# g-wiki/ is a stray. Must be run with cwd at the fixture root.
new_stray_check() {
    for canon in $(find g-docs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n1 basename); do
        find . -type d -name "$canon" \
          -not -path './g-docs*' -not -path './g-wiki*' -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null
    done
}

# Test 12: FAIL-BEFORE — OLD fixed 6-name allowlist misses a parallel docs/ tree
# Scenario: canonical g-docs/plans/ and g-docs/agent-output/ exist (project record), and a
# stray parallel tree docs/plans/ and docs/agent-output/ also exists (drifted copy). Neither
# "plans" nor "agent-output" is in the OLD fixed 6-name list, so the old check misses both —
# this is the exact M-audit #23/BUG-4 gap.
# Expected: old_stray_check reports neither stray (empty for both).
#
# Trace:
#   - Create g-docs/plans/f.md, g-docs/agent-output/f.md (canonical)
#   - Create docs/plans/f.md, docs/agent-output/f.md (stray parallel tree)
#   - old_stray_check searches only for decisions|retros|forecasts|telemetry|blast-radius|alignment
#   - "plans" and "agent-output" are not in that list → docs/plans, docs/agent-output NOT reported ✓ (bug reproduced)

echo "Test 12: OLD fixed-allowlist check misses agent-output/plans strays (fail-before)"
FIXTURE12=$(mktemp -d)
cd "$FIXTURE12" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p g-docs/plans g-docs/agent-output docs/plans docs/agent-output
printf '%s\n' "canonical plan" > g-docs/plans/f.md
printf '%s\n' "canonical agent output" > g-docs/agent-output/f.md
printf '%s\n' "stray plan" > docs/plans/f.md
printf '%s\n' "stray agent output" > docs/agent-output/f.md

OLD_RESULT=$(old_stray_check)

FOUND_PLANS_OLD="no"
echo "$OLD_RESULT" | grep -q "docs/plans" && FOUND_PLANS_OLD="yes"
check "OLD allowlist misses docs/plans/ (bug reproduced)" "no" "$FOUND_PLANS_OLD"

FOUND_AGENT_OUTPUT_OLD="no"
echo "$OLD_RESULT" | grep -q "docs/agent-output" && FOUND_AGENT_OUTPUT_OLD="yes"
check "OLD allowlist misses docs/agent-output/ (bug reproduced)" "no" "$FOUND_AGENT_OUTPUT_OLD"

# Test 13: PASS-AFTER — NEW inverted check catches the same strays
# Scenario: same fixture as Test 12. The NEW check derives canonical names from what
# actually lives under g-docs/ (here: "plans" and "agent-output"), then flags any directory
# sharing those names found outside g-docs/ or g-wiki/.
# Expected: new_stray_check reports both docs/plans and docs/agent-output as strays.
#
# Trace:
#   - Same fixture tree as Test 12 (cwd unchanged)
#   - new_stray_check derives canonical names {"plans", "agent-output"} from g-docs/ subdirs
#   - Searches repo for dirs named "plans" or "agent-output" outside g-docs/ or g-wiki/
#   - Finds ./docs/plans and ./docs/agent-output → reported as strays ✓ (bug fixed)

echo "Test 13: NEW inverted check catches agent-output/plans strays (pass-after)"

NEW_RESULT=$(new_stray_check)

FOUND_PLANS_NEW="no"
echo "$NEW_RESULT" | grep -q "docs/plans" && FOUND_PLANS_NEW="yes"
check "NEW inverted check flags docs/plans/ (bug fixed)" "yes" "$FOUND_PLANS_NEW"

FOUND_AGENT_OUTPUT_NEW="no"
echo "$NEW_RESULT" | grep -q "docs/agent-output" && FOUND_AGENT_OUTPUT_NEW="yes"
check "NEW inverted check flags docs/agent-output/ (bug fixed)" "yes" "$FOUND_AGENT_OUTPUT_NEW"

cd / && rm -rf "$FIXTURE12"

# Test 14: NEW check produces no false positive on a clean tree (regression guard)
# Scenario: canonical-only tree — g-docs/plans/ and g-docs/decisions/ exist, no parallel
# stray tree anywhere else. The NEW inverted check must report zero strays (it must not
# flag g-docs/ contents against themselves, nor invent false matches).
# Expected: new_stray_check reports nothing.
#
# Trace:
#   - Create g-docs/plans/f.md, g-docs/decisions/f.md only (no stray copies elsewhere)
#   - new_stray_check derives canonical names {"plans", "decisions"} from g-docs/ subdirs
#   - Searches repo for dirs named "plans" or "decisions" outside g-docs/ or g-wiki/ → none exist
#   - Reports empty ✓ (no false positive)

echo "Test 14: NEW inverted check has no false positive on a clean tree"
FIXTURE14=$(mktemp -d)
cd "$FIXTURE14" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p g-docs/plans g-docs/decisions
printf '%s\n' "canonical plan" > g-docs/plans/f.md
printf '%s\n' "canonical decision" > g-docs/decisions/f.md

NEW_RESULT_CLEAN=$(new_stray_check)
check "NEW inverted check: clean tree produces no strays" "" "$NEW_RESULT_CLEAN"

cd / && rm -rf "$FIXTURE14"

# ────────────────────────────────────────────────────────────────────────────
# Architecture-Skill Drift Tests (Tests 15-18)
# Task 10 (A7 drift-set resync): /g-doctor Check 16 now also drift-checks the
# installed `.claude/skills/architecture-<stack>/SKILL.md` copy `/g-specialize`
# writes (frontmatter + the full `profiles/<stack>/rules/architecture.md` body)
# against its profile source. Tests 15-16 grep-pin that the shipped skill text
# actually names the artifact (guard tests: they pass because a future edit
# has NOT silently dropped the naming — falsifiability probed, see markers).
# Tests 17-18 prove the frontmatter-strip + hash-compare mechanism the SKILL
# prescribes actually discriminates match vs. mismatch.

# strip_frontmatter <file> — mimics the Check 16 prescription: "strip the
# installed file's frontmatter (everything through the closing `---` line)".
# Prints everything after the second `---` line.
strip_frontmatter() {
    awk 'BEGIN{n=0} /^---$/{n++; next} n<2{next} {print}' "$1"
}

# Test 15: SKILL TEXT NAMES THE ARTIFACT — skills/g-doctor/SKILL.md Check 16
# grep-pins the literal `.claude/skills/architecture-*/SKILL.md` string, so a
# future edit that silently drops the artifact from Check 16 goes red here.
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-29
echo "Test 15: g-doctor SKILL.md Check 16 names .claude/skills/architecture-*/SKILL.md"
GDOCTOR_MATCH=$(grep -cF '.claude/skills/architecture-*/SKILL.md' "$SKILL_MD")
GDOCTOR_NAMED="no"
[ "$GDOCTOR_MATCH" -ge 1 ] && GDOCTOR_NAMED="yes"
check "g-doctor Check 16 names .claude/skills/architecture-*/SKILL.md" "yes" "$GDOCTOR_NAMED"

# Test 16: g-update SKILL.md Step 6 names the same artifact the same way.
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-29
echo "Test 16: g-update SKILL.md Step 6 names .claude/skills/architecture-[stack]/SKILL.md"
GUPDATE_SKILL_MD="$REPO_ROOT/skills/g-update/SKILL.md"
GUPDATE_MATCH=$(grep -cF '.claude/skills/architecture-[stack]/SKILL.md' "$GUPDATE_SKILL_MD")
GUPDATE_NAMED="no"
[ "$GUPDATE_MATCH" -ge 1 ] && GUPDATE_NAMED="yes"
check "g-update Step 6 names .claude/skills/architecture-[stack]/SKILL.md" "yes" "$GUPDATE_NAMED"

# Test 17: FRONTMATTER-STRIP MATCH — installed skill body equals profile
# source body → hashes equal after frontmatter strip (no drift).
#
# Trace:
#   - Create profiles/test-stack/rules/architecture.md (canonical body)
#   - Create .claude/skills/architecture-test-stack/SKILL.md: frontmatter +
#     the SAME body content
#   - strip_frontmatter the installed file → stripped-body.md
#   - compare_hashes(profile source, stripped-body.md) → MATCH ✓

echo "Test 17: Architecture-skill installed copy matches profile source (frontmatter stripped)"
FIXTURE17=$(mktemp -d)
cd "$FIXTURE17" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p profiles/test-stack/rules .claude/skills/architecture-test-stack

ARCH_BODY="## Test Stack Architecture Rules

Layer map: components/, lib/, services/.
"
printf '%s' "$ARCH_BODY" > profiles/test-stack/rules/architecture.md

INSTALLED_SKILL="---
name: architecture-test-stack
description: Test Stack architecture rules and patterns. Preloaded into the test-stack architect agent at startup.
---
$ARCH_BODY"
printf '%s' "$INSTALLED_SKILL" > .claude/skills/architecture-test-stack/SKILL.md

strip_frontmatter ".claude/skills/architecture-test-stack/SKILL.md" > stripped-body.md

RESULT=$(compare_hashes "profiles/test-stack/rules/architecture.md" "stripped-body.md")
check "architecture-skill match: hashes equal after frontmatter strip (no drift)" "MATCH" "$RESULT"

cd / && rm -rf "$FIXTURE17"

# Test 18: FRONTMATTER-STRIP MISMATCH — installed skill body differs from
# profile source body → hashes differ after frontmatter strip (drift).
#
# Trace:
#   - Create profiles/other-stack/rules/architecture.md (canonical, current)
#   - Create .claude/skills/architecture-other-stack/SKILL.md: frontmatter +
#     a DIFFERENT (staled) body content
#   - strip_frontmatter the installed file → stripped-body.md
#   - compare_hashes(profile source, stripped-body.md) → MISMATCH ✓

echo "Test 18: Architecture-skill installed copy differs from profile source (drift detected)"
FIXTURE18=$(mktemp -d)
cd "$FIXTURE18" || { echo "FAIL: could not create fixture"; exit 1; }

mkdir -p profiles/other-stack/rules .claude/skills/architecture-other-stack

CURRENT_ARCH="## Other Stack Architecture Rules (current)

Layer map: components/, lib/, services/, stores/.
"
printf '%s' "$CURRENT_ARCH" > profiles/other-stack/rules/architecture.md

STALED_BODY="## Other Stack Architecture Rules (staled)

Layer map: components/, lib/.
"
STALED_INSTALLED="---
name: architecture-other-stack
description: Other Stack architecture rules and patterns. Preloaded into the other-stack architect agent at startup.
---
$STALED_BODY"
printf '%s' "$STALED_INSTALLED" > .claude/skills/architecture-other-stack/SKILL.md

strip_frontmatter ".claude/skills/architecture-other-stack/SKILL.md" > stripped-body.md

RESULT=$(compare_hashes "profiles/other-stack/rules/architecture.md" "stripped-body.md")
check "architecture-skill mismatch: hashes differ after frontmatter strip (drift detected)" "MISMATCH" "$RESULT"

cd / && rm -rf "$FIXTURE18"

# ────────────────────────────────────────────────────────────────────────────
# Summary

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

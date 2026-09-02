#!/bin/bash
# Unit tests for skills/g-roadmap/scripts/context-scan.sh and
# skills/g-roadmap/scripts/split-suffix.sh (v2.6 Step 0 / Step 3 extraction).
#
# Verifies the KEY: value output contracts (always exit 0; outcomes in output,
# never exit codes), the fixed 4-file version cascade order, first-🔄-wins
# active-milestone detection, backlog counting bounded by the next ## heading,
# the not-end-anchored -split[0-9]+ depth read, the replace-not-append rule for
# an already-marked parent (a -split2 parent yields -split3, with a NOTE line),
# and the cross-copy literals (status key in SKILL.md core AND
# references/templates.md; the -split grep pattern shared with /g-plan Step 3c;
# the replace-not-append rule on the SKILL.md core and split-lineage reference).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$SCRIPT_DIR/.."
SCAN="$REPO/skills/g-roadmap/scripts/context-scan.sh"
SPLIT="$REPO/skills/g-roadmap/scripts/split-suffix.sh"

PASS=0
FAIL=0

check() { # check <label> <condition-result 0|nonzero>
    if [ "$2" -eq 0 ]; then
        echo "PASS: $1"; PASS=$((PASS+1))
    else
        echo "FAIL: $1"; FAIL=$((FAIL+1))
    fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ── Task 1: context-scan on an empty project ────────────────────────────────

mkdir -p "$TMP/empty"
OUT=$(cd "$TMP/empty" && bash "$SCAN"); RC=$?
check "empty project — exit 0" "$RC"
echo "$OUT" | grep -qx "ROADMAP: missing";          check "empty — ROADMAP: missing" $?
echo "$OUT" | grep -qx "ACTIVE: none";              check "empty — ACTIVE: none" $?
echo "$OUT" | grep -qx "BACKLOG_COUNT: 0";          check "empty — BACKLOG_COUNT: 0" $?
echo "$OUT" | grep -qx "BRIEF: missing";            check "empty — BRIEF: missing" $?
echo "$OUT" | grep -qx "VERSION: unversioned";      check "empty — VERSION: unversioned" $?
echo "$OUT" | grep -qx "VERSION_SOURCE: none";      check "empty — VERSION_SOURCE: none" $?
echo "$OUT" | grep -qx "MANIFESTS: none";           check "empty — MANIFESTS: none" $?

# ── Task 2: context-scan on a populated project ─────────────────────────────

mkdir -p "$TMP/full/g-docs"
cat > "$TMP/full/g-docs/ROADMAP.md" <<'EOF'
# Roadmap

## Milestones

### M1 — Core
**Status:** ✅ Complete
**Version:** v0.1.0

---

### M2 — Auth
**Status:** 🔄 In progress
**Version:** v0.2.0

### M3 — Polish
**Status:** ⬜ Not started

## Backlog
- item one
- item two
· item three

## Notes
- not a backlog item
EOF
echo "# Project Brief" > "$TMP/full/g-docs/project_brief.md"
printf '{\n  "name": "x",\n  "version": "1.2.3"\n}\n' > "$TMP/full/package.json"
touch "$TMP/full/go.mod"

OUT=$(cd "$TMP/full" && bash "$SCAN"); RC=$?
check "full project — exit 0" "$RC"
echo "$OUT" | grep -qx "ROADMAP: exists";              check "full — ROADMAP: exists" $?
echo "$OUT" | grep -qx "ACTIVE: M2 — Auth";            check "full — ACTIVE is the 🔄 milestone title" $?
echo "$OUT" | grep -qx "COMPLETED: M1 — Core";         check "full — COMPLETED line for the ✅ milestone" $?
# RED falsifiability probes: counting must stop at the next ## heading, and
# must count '·' bullets bytewise under LC_ALL=C (banner style), not just '-'.
echo "$OUT" | grep -qx "BACKLOG_COUNT: 3";             check "full — BACKLOG_COUNT: 3 ('-' and '·' bullets, bounded by next ## heading)" $?
echo "$OUT" | grep -qx "BRIEF: exists";                check "full — BRIEF: exists" $?
echo "$OUT" | grep -qx "VERSION: v1.2.3";              check "full — VERSION: v1.2.3" $?
echo "$OUT" | grep -qx "VERSION_SOURCE: package.json"; check "full — VERSION_SOURCE: package.json" $?
echo "$OUT" | grep -qx "MANIFESTS: package.json go.mod"; check "full — MANIFESTS lists both, fixed order" $?

# ── Task 3: version cascade — plugin.json beats package.json ────────────────

mkdir -p "$TMP/cascade/.claude-plugin"
printf '{ "version": "2.5.0" }\n' > "$TMP/cascade/.claude-plugin/plugin.json"
printf '{ "version": "9.9.9" }\n' > "$TMP/cascade/package.json"
echo "x" > "$TMP/cascade/g-docs" 2>/dev/null; rm -f "$TMP/cascade/g-docs"
mkdir -p "$TMP/cascade/g-docs"; echo "# Roadmap" > "$TMP/cascade/g-docs/ROADMAP.md"
OUT=$(cd "$TMP/cascade" && bash "$SCAN")
echo "$OUT" | grep -qx "VERSION: v2.5.0";                             check "cascade — .claude-plugin/plugin.json wins" $?
echo "$OUT" | grep -qx "VERSION_SOURCE: .claude-plugin/plugin.json";  check "cascade — VERSION_SOURCE names the winner" $?

# ── Task 4: version parse — pyproject.toml, and v-prefix normalization ──────

mkdir -p "$TMP/py/g-docs"; echo "# Roadmap" > "$TMP/py/g-docs/ROADMAP.md"
printf '[project]\nversion = "v0.4.1"\n' > "$TMP/py/pyproject.toml"
OUT=$(cd "$TMP/py" && bash "$SCAN")
echo "$OUT" | grep -qx "VERSION: v0.4.1";               check "pyproject — version parsed, single v prefix" $?
echo "$OUT" | grep -qx "VERSION_SOURCE: pyproject.toml"; check "pyproject — VERSION_SOURCE: pyproject.toml" $?
echo "$OUT" | grep -q  "MANIFESTS: pyproject.toml";      check "pyproject — listed as manifest" $?

# ── Task 5: first 🔄 milestone wins ────────────────────────────────────────

mkdir -p "$TMP/two/g-docs"
cat > "$TMP/two/g-docs/ROADMAP.md" <<'EOF'
## Milestones

### MA — First active
**Status:** 🔄 In progress

### MB — Second active
**Status:** 🔄 In progress
EOF
OUT=$(cd "$TMP/two" && bash "$SCAN")
echo "$OUT" | grep -qx "ACTIVE: MA — First active";  check "two active — first 🔄 wins" $?

# ── Task 6: split-suffix — no marker ────────────────────────────────────────

OUT=$(bash "$SPLIT" M9); RC=$?
check "split M9 — exit 0" "$RC"
echo "$OUT" | grep -qx "PARENT: M9";        check "split M9 — PARENT echoed" $?
echo "$OUT" | grep -qx "DEPTH: 0";          check "split M9 — DEPTH: 0" $?
echo "$OUT" | grep -qx "SUFFIX: -split1";   check "split M9 — SUFFIX: -split1" $?
# RED probe: no marker on the parent → no replace-reminder NOTE line.
! echo "$OUT" | grep -q "replace that marker"
check "split M9 — no replace NOTE for unmarked parent" $?

# ── Task 7: split-suffix — existing marker increments ───────────────────────

OUT=$(bash "$SPLIT" M47-split1)
echo "$OUT" | grep -qx "DEPTH: 1";          check "split M47-split1 — DEPTH: 1" $?
echo "$OUT" | grep -qx "SUFFIX: -split2";   check "split M47-split1 — SUFFIX: -split2" $?
echo "$OUT" | grep -qx "NOTE: parent carries -split1 — replace that marker with SUFFIX, never append after it"
check "split M47-split1 — replace-the-marker NOTE line" $?

# ── Task 7b: split-suffix — -split2 parent: marker replaced, never appended ─

OUT=$(bash "$SPLIT" M47-split2)
echo "$OUT" | grep -qx "DEPTH: 2";          check "split M47-split2 — DEPTH: 2" $?
echo "$OUT" | grep -qx "SUFFIX: -split3";   check "split M47-split2 — SUFFIX: -split3 (replaces -split2, not appended after)" $?
echo "$OUT" | grep -qx "NOTE: parent carries -split2 — replace that marker with SUFFIX, never append after it"
check "split M47-split2 — replace-the-marker NOTE line" $?

# ── Task 8: split-suffix — pattern NOT end-anchored (g-plan Step 3c parity) ─

OUT=$(bash "$SPLIT" M47-split1-auth)
echo "$OUT" | grep -qx "DEPTH: 1";          check "split M47-split1-auth — mid-id marker still read (not end-anchored)" $?
echo "$OUT" | grep -qx "SUFFIX: -split2";   check "split M47-split1-auth — SUFFIX: -split2" $?

# ── Task 9: split-suffix — no argument ──────────────────────────────────────

OUT=$(bash "$SPLIT"); RC=$?
check "split no-arg — exit 0" "$RC"
echo "$OUT" | grep -qx "NOTE: no parent id given"; check "split no-arg — NOTE line" $?
echo "$OUT" | grep -qx "SUFFIX: -split1";          check "split no-arg — SUFFIX: -split1" $?

# ── Task 10: cross-copy literal guards ──────────────────────────────────────

STATUS_KEY='Milestone status key: ⬜ Not started · 🔄 In progress · ✅ Complete'
grep -qF "$STATUS_KEY" "$REPO/skills/g-roadmap/SKILL.md"
check "status key line present in g-roadmap SKILL.md core (Step 5)" $?
grep -qF "$STATUS_KEY" "$REPO/skills/g-roadmap/references/templates.md"
check "status key line present in references/templates.md" $?
grep -qF -- '-split[0-9]' "$SPLIT"
check "split-suffix.sh carries the -split[0-9] grep pattern (/g-plan Step 3c parity)" $?
grep -qF -- '-split<N>' "$REPO/skills/g-roadmap/SKILL.md"
check "g-roadmap SKILL.md core keeps the -split<N> convention literal" $?
REPLACE_RULE='an existing `-split<N>` marker is replaced with the `SUFFIX`, never appended after it'
grep -qF "$REPLACE_RULE" "$REPO/skills/g-roadmap/SKILL.md"
check "g-roadmap SKILL.md core carries the replace-not-append split rule" $?
grep -qF 'replaced with `-split<N+1>`' "$REPO/skills/g-roadmap/references/split-lineage.md"
check "references/split-lineage.md carries the replace-not-append split rule" $?

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

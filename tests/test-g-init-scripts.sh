#!/bin/bash
# Unit tests for skills/g-init/scripts/ (detect-state.sh, scaffold.sh,
# merge-gitignore.sh, install-hooks.sh) — the v2.6 prose→script extraction
# of /g-init Steps 1a/1b, 2a/3/4/5, 5a, and 6/6a.
#
# Verifies:
# - Always-exit-0 contract on every script, valid and degenerate inputs
# - detect-state: SELF_HOST on/off, INITIALIZED, BRIEF, CLASS closed set,
#   MANIFEST evidence lines (closed-set literal package.json etc.), and the
#   commits-of-real-code disjunct (COMMITS evidence line; >2 commits of
#   non-doc code → existing, ≤2 stays ambiguous)
# - scaffold: skeleton create-only semantics (CREATED then EXISTS),
#   RULES_INSTALLED derived from disk, CLAUDEMD state machine, the
#   hook-grepped handoff literals ('## Active Session', '━' banner,
#   'Active context:') written raw into g-docs/ROADMAP.md, and the
#   /g-onboard skip preference (--skip-rules/--skip-agents → SKIPPED lines,
#   no rules installed, skeletons still written), and the M1 milestone
#   guard recognizing a pre-existing slugged file (M1-*.md, not just the
#   literal M1.md) so it is reported EXISTS rather than duplicated
# - merge-gitignore: created/updated/unchanged, idempotency, developer
#   entries preserved, banner-hash pattern present
# - install-hooks: tier marker written BEFORE hooks copy, disk-derived
#   copy set, PRECOMMIT installed/updated/foreign branches, foreign hook
#   never overwritten, GITHOOK_LIBS count, and the per-file completeness
#   check (a lib the cache's own hooks source but lib/ lacks → named
#   MISSING line, ADR-011 derived)
# - RED falsifiability probes: a doctored plugin root with no hooks dir
#   yields MISSING; a cache missing one sourced lib yields a per-file
#   MISSING — proving both MISSING paths can actually fire
#
# Total assertions: 62
# Count is the RUNNER-OBSERVED total and must equal the `Results:` line.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS="$REPO/skills/g-init/scripts"

PASS=0
FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# has <output> <line-substring> <name>
has() {
    if printf '%s\n' "$1" | grep -qF -- "$2"; then ok "$3"; else bad "$3 (missing: $2)"; fi
}

# ── detect-state.sh ────────────────────────────────────────────────────────

# Task 1: greenfield empty dir
DIR=$(mktemp -d)
OUT=$(cd "$DIR" && GF_PLUGIN_CACHE_DIR="$DIR/nocache" bash "$SCRIPTS/detect-state.sh"); RC=$?
[ $RC -eq 0 ] && ok "detect-state: exit 0 on empty dir" || bad "detect-state: exit $RC on empty dir"
has "$OUT" "SELF_HOST: off" "detect-state: empty dir is not self-host"
has "$OUT" "CACHE_MISSING: yes" "detect-state: missing cache reported"
has "$OUT" "INITIALIZED: no" "detect-state: empty dir not initialized"
has "$OUT" "BRIEF: absent" "detect-state: empty dir has no brief"
has "$OUT" "CLASS: greenfield" "detect-state: empty dir classes greenfield"
rm -rf "$DIR"

# Task 2: manifest → existing, MANIFEST evidence line
DIR=$(mktemp -d)
touch "$DIR/package.json"
OUT=$(cd "$DIR" && GF_PLUGIN_CACHE_DIR="$DIR/nocache" bash "$SCRIPTS/detect-state.sh")
has "$OUT" "MANIFEST: package.json" "detect-state: package.json evidence line"
has "$OUT" "CLASS: existing" "detect-state: manifest classes existing"
rm -rf "$DIR"

# Task 3: self-host on (plugin.json name g-forge) + cache resolution unused
DIR=$(mktemp -d)
mkdir -p "$DIR/.claude-plugin"
printf '{ "name": "g-forge", "version": "9.9.9" }\n' > "$DIR/.claude-plugin/plugin.json"
OUT=$(cd "$DIR" && bash "$SCRIPTS/detect-state.sh")
has "$OUT" "SELF_HOST: on" "detect-state: g-forge plugin.json flips self-host on"
has "$OUT" "PLUGIN_ROOT: $DIR" "detect-state: self-host PLUGIN_ROOT is the working tree"
rm -rf "$DIR"

# Task 4: foreign plugin.json stays off; highest-version cache dir wins
DIR=$(mktemp -d)
mkdir -p "$DIR/.claude-plugin" "$DIR/cache/1.9.0" "$DIR/cache/1.10.2"
printf '{ "name": "other-plugin" }\n' > "$DIR/.claude-plugin/plugin.json"
OUT=$(cd "$DIR" && GF_PLUGIN_CACHE_DIR="$DIR/cache" bash "$SCRIPTS/detect-state.sh")
has "$OUT" "SELF_HOST: off" "detect-state: foreign plugin.json is not self-host"
has "$OUT" "PLUGIN_ROOT: $DIR/cache/1.10.2" "detect-state: highest version cache dir wins (1.10.2 > 1.9.0)"
rm -rf "$DIR"

# Task 4b: commits-of-real-code disjunct — >2 commits of non-doc code with no
# manifest and no src dir → existing; the same tree at ≤2 commits stays
# ambiguous (RED side: proves the disjunct is what flips the class).
DIR=$(mktemp -d)
printf 'int main(){}\n' > "$DIR/main.c"
(cd "$DIR" && git init -q && git add main.c \
    && git -c user.email=t@t -c user.name=t commit -qm c1 \
    && git -c user.email=t@t -c user.name=t commit -qm c2 --allow-empty)
OUT=$(cd "$DIR" && GF_PLUGIN_CACHE_DIR="$DIR/nocache" bash "$SCRIPTS/detect-state.sh")
has "$OUT" "COMMITS: 2" "detect-state: commit count emitted as evidence"
has "$OUT" "CLASS: ambiguous" "detect-state: a couple of commits (2) is not yet existing"
(cd "$DIR" && git -c user.email=t@t -c user.name=t commit -qm c3 --allow-empty)
OUT=$(cd "$DIR" && GF_PLUGIN_CACHE_DIR="$DIR/nocache" bash "$SCRIPTS/detect-state.sh")
has "$OUT" "COMMITS: 3" "detect-state: commit count tracks history"
has "$OUT" "CLASS: existing" "detect-state: more than a couple of commits of real code classes existing"
rm -rf "$DIR"

# Task 5: initialized project detected
DIR=$(mktemp -d)
mkdir -p "$DIR/.claude" "$DIR/g-docs"
printf 'full\n' > "$DIR/.claude/integration-tier"
printf '# X\n<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->\n' > "$DIR/CLAUDE.md"
touch "$DIR/g-docs/project_brief.md"
OUT=$(cd "$DIR" && GF_PLUGIN_CACHE_DIR="$DIR/nocache" bash "$SCRIPTS/detect-state.sh")
has "$OUT" "INITIALIZED: yes" "detect-state: tier marker + marker comment = initialized"
has "$OUT" "BRIEF: present" "detect-state: brief detected"
rm -rf "$DIR"

# ── scaffold.sh ────────────────────────────────────────────────────────────

# Fixture plugin root with rules
PROOT=$(mktemp -d)
mkdir -p "$PROOT/rules/g-rules" "$PROOT/rules/references"
printf '# G-RULES\n' > "$PROOT/G-RULES.md"
printf 'A\n' > "$PROOT/rules/g-rules/A-session.md"
printf 'B\n' > "$PROOT/rules/g-rules/B-workflow.md"
printf 'ref\n' > "$PROOT/rules/references/deep-dive.md"
printf 'matrix\n' > "$PROOT/rules/dispatch-matrix.md"

DIR=$(mktemp -d)
OUT=$(cd "$DIR" && bash "$SCRIPTS/scaffold.sh" "$PROOT"); RC=$?
[ $RC -eq 0 ] && ok "scaffold: exit 0" || bad "scaffold: exit $RC"
has "$OUT" "CREATED: g-docs/ROADMAP.md" "scaffold: ROADMAP created"
has "$OUT" "RULES_INSTALLED: 2" "scaffold: rules count derived from disk (2)"
has "$OUT" "CLAUDEMD: missing" "scaffold: CLAUDEMD missing reported"
[ -f "$DIR/.claude/rules/g-rules-A-session.md" ] \
    && ok "scaffold: g-rules section installed with g-rules- prefix" \
    || bad "scaffold: g-rules-A-session.md not installed"
[ -f "$DIR/.claude/rules/references/deep-dive.md" ] \
    && ok "scaffold: rules/references installed (not @-imported)" \
    || bad "scaffold: rules/references/deep-dive.md not installed"
[ -f "$DIR/.claude/rules/g-dispatch-matrix.md" ] \
    && ok "scaffold: dispatch matrix installed as g-dispatch-matrix.md" \
    || bad "scaffold: g-dispatch-matrix.md not installed"

# Handoff literals hooks grep for — must be raw in the file, byte-identical.
grep -qF '## Active Session' "$DIR/g-docs/ROADMAP.md" \
    && ok "scaffold: ROADMAP carries ## Active Session" || bad "scaffold: no ## Active Session"
grep -qF 'Active context:   · Fresh project, just initialized' "$DIR/g-docs/ROADMAP.md" \
    && ok "scaffold: ROADMAP carries Active context: line" || bad "scaffold: no Active context line"
grep -qF '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' "$DIR/g-docs/ROADMAP.md" \
    && ok "scaffold: ROADMAP carries ━ banner line" || bad "scaffold: no ━ banner line"

# Task: rerun is idempotent — skeletons EXISTS, CLAUDEMD state machine
printf '# T\n@G-RULES.md\n' > "$DIR/CLAUDE.md"
OUT=$(cd "$DIR" && bash "$SCRIPTS/scaffold.sh" "$PROOT")
has "$OUT" "EXISTS: g-docs/ROADMAP.md" "scaffold: rerun leaves ROADMAP untouched (EXISTS)"
has "$OUT" "CLAUDEMD: no-marker" "scaffold: CLAUDE.md without marker → no-marker"
printf '<!-- G-Forge Rules -->\n' >> "$DIR/CLAUDE.md"
OUT=$(cd "$DIR" && bash "$SCRIPTS/scaffold.sh" "$PROOT")
has "$OUT" "CLAUDEMD: ok" "scaffold: marker + import → ok"
rm -rf "$DIR"

# Task: /g-onboard skip preference honored — --skip-rules installs no rules
# but still writes the g-docs skeletons; --skip-agents is acknowledged.
DIR=$(mktemp -d)
OUT=$(cd "$DIR" && bash "$SCRIPTS/scaffold.sh" --skip-rules --skip-agents "$PROOT"); RC=$?
[ $RC -eq 0 ] && ok "scaffold: exit 0 with skip flags" || bad "scaffold: exit $RC with skip flags"
has "$OUT" "SKIPPED: rules" "scaffold: --skip-rules reports SKIPPED: rules"
has "$OUT" "SKIPPED: agents" "scaffold: --skip-agents reports SKIPPED: agents"
has "$OUT" "RULES_INSTALLED: 0" "scaffold: --skip-rules installs zero rules"
if [ ! -f "$DIR/G-RULES.md" ] && [ ! -f "$DIR/.claude/rules/g-rules-A-session.md" ]; then
    ok "scaffold: --skip-rules leaves G-RULES.md and .claude/rules/ untouched"
else
    bad "scaffold: --skip-rules still installed rules files"
fi
has "$OUT" "CREATED: g-docs/ROADMAP.md" "scaffold: skip flags do not block g-docs skeletons"
rm -rf "$DIR"

# Task: M1 guard recognizes a slugged milestone file (M1-foundation.md), not
# just the literal M1.md — a pre-existing M1-*.md must not spawn a duplicate
# literal M1.md skeleton beside it (2026-09-02 dogfood defect).
DIR=$(mktemp -d)
mkdir -p "$DIR/g-docs/milestones"
printf '# M1 — Foundation\n' > "$DIR/g-docs/milestones/M1-foundation.md"
OUT=$(cd "$DIR" && bash "$SCRIPTS/scaffold.sh" "$PROOT"); RC=$?
[ $RC -eq 0 ] && ok "scaffold: exit 0 with pre-seeded M1-foundation.md" || bad "scaffold: exit $RC with pre-seeded M1-foundation.md"
has "$OUT" "EXISTS: g-docs/milestones/M1-foundation.md" "scaffold: slugged M1 milestone reported EXISTS"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-09-03
[ ! -f "$DIR/g-docs/milestones/M1.md" ] \
    && ok "scaffold: no duplicate literal M1.md created beside M1-foundation.md" \
    || bad "scaffold: duplicate M1.md created beside M1-foundation.md"
rm -rf "$DIR"

# ── merge-gitignore.sh ─────────────────────────────────────────────────────

DIR=$(mktemp -d)
OUT=$(cd "$DIR" && bash "$SCRIPTS/merge-gitignore.sh"); RC=$?
[ $RC -eq 0 ] && ok "merge-gitignore: exit 0" || bad "merge-gitignore: exit $RC"
has "$OUT" "GITIGNORE: created" "merge-gitignore: fresh file → created"
has "$OUT" "ADDED: .claude/banner-hash.*" "merge-gitignore: banner-hash session state pattern added"
OUT=$(cd "$DIR" && bash "$SCRIPTS/merge-gitignore.sh")
has "$OUT" "GITIGNORE: unchanged" "merge-gitignore: rerun is idempotent (unchanged)"
has "$OUT" "PRESENT: .env" "merge-gitignore: rerun reports PRESENT"
rm -rf "$DIR"

# Developer entries preserved, partial merge → updated
DIR=$(mktemp -d)
printf 'node_modules/\n.env\n' > "$DIR/.gitignore"
OUT=$(cd "$DIR" && bash "$SCRIPTS/merge-gitignore.sh")
has "$OUT" "GITIGNORE: updated" "merge-gitignore: partial file → updated"
has "$OUT" "PRESENT: .env" "merge-gitignore: existing pattern not re-added"
head -1 "$DIR/.gitignore" | grep -qxF 'node_modules/' \
    && ok "merge-gitignore: developer entries never removed or reordered" \
    || bad "merge-gitignore: developer entry lost or moved"
rm -rf "$DIR"

# ── install-hooks.sh ───────────────────────────────────────────────────────

# Fixture plugin root with hooks + libs + pre-commit
mkdir -p "$PROOT/hooks/lib"
printf '#!/bin/bash\necho hook\n' > "$PROOT/hooks/check-commit.sh"
printf '#!/bin/bash\n# G-Forge commit gate\n' > "$PROOT/hooks/pre-commit"
printf '# lib\n' > "$PROOT/hooks/lib/commit-detect.sh"
printf '# lib\n' > "$PROOT/hooks/lib/stdin-read.sh"

DIR=$(mktemp -d)
OUT=$(cd "$DIR" && git init -q && bash "$SCRIPTS/install-hooks.sh" "$PROOT"); RC=$?
[ $RC -eq 0 ] && ok "install-hooks: exit 0" || bad "install-hooks: exit $RC"
has "$OUT" "TIER_MARKER: created" "install-hooks: tier marker written (full)"
[ "$(cat "$DIR/.claude/integration-tier")" = "full" ] \
    && ok "install-hooks: integration-tier contains full" \
    || bad "install-hooks: integration-tier wrong content"
has "$OUT" "COPIED: .claude/hooks/check-commit.sh" "install-hooks: top-level hook copied"
has "$OUT" "COPIED: .claude/hooks/lib/commit-detect.sh" "install-hooks: lib copied (disk-derived)"
has "$OUT" "PRECOMMIT: installed" "install-hooks: fresh pre-commit → installed"
has "$OUT" "GITHOOK_LIBS: 2" "install-hooks: git-hooks lib count matches disk (2)"

# Rerun: G-Forge-managed pre-commit → updated
OUT=$(cd "$DIR" && bash "$SCRIPTS/install-hooks.sh" "$PROOT")
has "$OUT" "PRECOMMIT: updated" "install-hooks: G-Forge-managed pre-commit → updated"

# Foreign pre-commit: never overwritten, no lib install
HOOKSDIR=$(cd "$DIR" && git rev-parse --git-path hooks)
case "$HOOKSDIR" in /*) : ;; *) HOOKSDIR="$DIR/$HOOKSDIR" ;; esac
printf '#!/bin/sh\n# my own hook\n' > "$HOOKSDIR/pre-commit"
OUT=$(cd "$DIR" && bash "$SCRIPTS/install-hooks.sh" "$PROOT")
has "$OUT" "PRECOMMIT: foreign" "install-hooks: foreign pre-commit → foreign"
grep -qF 'my own hook' "$HOOKSDIR/pre-commit" \
    && ok "install-hooks: foreign hook left untouched" \
    || bad "install-hooks: foreign hook was overwritten"
rm -rf "$DIR"

# Per-file completeness (ADR-011 derived): a cache whose own hooks reference
# a lib absent from lib/ yields a named MISSING line for exactly that file —
# the 4-of-6 partial-install class stops by name, not only on an empty glob.
PROOT2=$(mktemp -d)
mkdir -p "$PROOT2/hooks/lib"
printf '#!/bin/bash\n. "$D/lib/commit-detect.sh"\n' > "$PROOT2/hooks/check-commit.sh"
printf '#!/bin/bash\n# G-Forge commit gate\n. "$D/lib/sentinel-read.sh"\n' > "$PROOT2/hooks/pre-commit"
printf '# lib\n' > "$PROOT2/hooks/lib/commit-detect.sh"
DIR=$(mktemp -d)
OUT=$(cd "$DIR" && git init -q && bash "$SCRIPTS/install-hooks.sh" "$PROOT2")
has "$OUT" "MISSING: $PROOT2/hooks/lib/sentinel-read.sh" \
    "install-hooks: individually absent sourced lib yields named MISSING (per-file)"
if printf '%s\n' "$OUT" | grep -qF "MISSING: $PROOT2/hooks/lib/commit-detect.sh"; then
    bad "install-hooks: present sourced lib falsely reported MISSING"
else
    ok "install-hooks: present sourced lib not reported MISSING"
fi
rm -rf "$DIR" "$PROOT2"

# RED falsifiability probe: doctored plugin root without hooks/ → MISSING
DIR=$(mktemp -d)
EMPTYROOT=$(mktemp -d)
OUT=$(cd "$DIR" && bash "$SCRIPTS/install-hooks.sh" "$EMPTYROOT"); RC=$?
[ $RC -eq 0 ] && ok "install-hooks: exit 0 even when plugin hooks dir missing" \
             || bad "install-hooks: nonzero exit on missing hooks dir"
has "$OUT" "MISSING: $EMPTYROOT/hooks" "install-hooks: missing hooks dir yields MISSING (red path provable)"
rm -rf "$DIR" "$EMPTYROOT" "$PROOT"

# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

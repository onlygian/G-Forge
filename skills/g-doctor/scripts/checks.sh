#!/bin/bash
# checks.sh — deterministic implementation of /g-doctor Checks 1–23 and 25.
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the exit
# code. Check 24 is deliberately NOT implemented here (security contract:
# untrusted CLAUDE.md content must never reach a shell) — this script emits
# `CHECK: 24 NEEDS-MODEL` and the model runs ../references/check-24-injection.md.
# Manual fallback catalog (prose mirror of this script):
# ../references/check-catalog.md — keep both in sync when editing.
#
# Output contract:
#   CHECK: <n> PASS|FAIL|ADVISORY|INFO|SKIP|INCONCLUSIVE|NEEDS-MODEL
#                                   one per check, in order 1–25
#   LINE: <exact report line>       1+ per check (✓/✗/⚠/ℹ/🔴 and wording
#                                   byte-identical to the g-doctor closed-set
#                                   literals; Check 16 emits one LINE per
#                                   drifted surface). The model transcribes
#                                   these verbatim, indented 2 spaces.
#   FIX: <exact fix-instruction text, without the → prefix — the model adds
#        the 4-space indent and arrow>  0+, only after FAIL/ADVISORY lines
#   NOTE: <diagnostic>              0+ human-readable notes
#   SUMMARY: required_passed=<n> required_total=16 advisories=<n>
#
# hash_file below MIRRORS the canonical cascade pinned in ../SKILL.md Check 16
# (tests/test-g-doctor-drift.sh evals its three lines out of that file) — the
# SKILL.md block is canonical; keep this mirror in sync when editing.
# Env seams: honors $HOME (Checks 19/23 cache probes);
# GF_DOCTOR_OFFLINE=1 skips the Check 23 GitHub fetch (test seam).
set -u
LC_ALL=C

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)

REQ_PASSED=0
ADVISORIES=0
CBUF=""

out()   { printf '%s\n' "$*"; }
bline() { CBUF="${CBUF}LINE: $1
"; }
bfix()  { CBUF="${CBUF}FIX: $1
"; }
bnote() { CBUF="${CBUF}NOTE: $1
"; }
flush() { # <n> <status> — print the CHECK row, then the buffered rows
    out "CHECK: $1 $2"
    [ -n "$CBUF" ] && printf '%s' "$CBUF"
    CBUF=""
    if [ "$1" -le 16 ] && [ "$2" = "PASS" ]; then REQ_PASSED=$((REQ_PASSED+1)); fi
    if [ "$2" = "ADVISORY" ]; then ADVISORIES=$((ADVISORIES+1)); fi
    return 0
}

# Mirror of the canonical hash_file cascade in ../SKILL.md Check 16.
hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        cksum "$1" | awk '{print $1, $2}'
    fi
}

# regs <event> <script> — count entries referencing <script> under the <event>
# key in .claude/settings.json (0 if the file is absent).
regs() {
    [ -f .claude/settings.json ] || { echo 0; return 0; }
    awk -v ev="$1" -v sc="$2" '
        /"(PreToolUse|PostToolUse|UserPromptSubmit|SessionStart|SessionEnd|SubagentStart|SubagentStop|PreCompact|Stop|Notification)"[ \t]*:/ {
            inev = (index($0, "\"" ev "\"") > 0)
        }
        inev && index($0, sc) > 0 { n++ }
        END { print n+0 }
    ' .claude/settings.json
}

json_version() { # <plugin.json> — extract the "version" value
    grep -m1 '"version"' "$1" 2>/dev/null \
        | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
}

GF_SCRIPTS="check-commit.sh post-commit-cleanup.sh observe.sh agent-lifecycle.sh pre-compact.sh session-start.sh workflow-checkpoint.sh"
EVENTS="PreToolUse PostToolUse UserPromptSubmit SessionStart SessionEnd SubagentStart SubagentStop PreCompact Stop Notification"

# ── Check 1 — commit hook ───────────────────────────────────────────────────
if [ -f .claude/hooks/check-commit.sh ]; then
    bline "✓ commit hook installed"; flush 1 PASS
else
    bline "✗ commit hook missing"
    bfix 'Run `/g-init` to install hooks.'
    flush 1 FAIL
fi

# ── Check 2 — workflow hook ─────────────────────────────────────────────────
if [ -f .claude/hooks/workflow-checkpoint.sh ]; then
    bline "✓ workflow hook installed"; flush 2 PASS
else
    bline "✗ workflow hook missing"
    bfix 'Run `/g-init` or `/g-update` to install the workflow checkpoint hook.'
    flush 2 FAIL
fi

# ── Check 3 — post-commit hook ──────────────────────────────────────────────
if [ -f .claude/hooks/post-commit-cleanup.sh ]; then
    bline "✓ post-commit hook installed"; flush 3 PASS
else
    bline "✗ post-commit hook missing"
    bfix 'Run `/g-init` or `/g-update` to install the post-commit cleanup hook.'
    flush 3 FAIL
fi

# ── Check 4 — PreToolUse registered ─────────────────────────────────────────
if [ "$(regs PreToolUse check-commit.sh)" -ge 1 ]; then
    bline "✓ PreToolUse hook registered"; flush 4 PASS
else
    bline "✗ PreToolUse hook not registered"
    bfix 'Run `/g-init` or `/g-update` to register the commit gate hook.'
    flush 4 FAIL
fi

# ── Check 5 — UserPromptSubmit registered ───────────────────────────────────
if [ "$(regs UserPromptSubmit workflow-checkpoint.sh)" -ge 1 ]; then
    bline "✓ UserPromptSubmit hook registered"; flush 5 PASS
else
    bline "✗ UserPromptSubmit hook not registered"
    bfix 'Run `/g-init` or `/g-update` to register the workflow checkpoint hook.'
    flush 5 FAIL
fi

# ── Check 6 — G-Forge Rules block ───────────────────────────────────────────
if [ -f CLAUDE.md ] && grep -qF '<!-- G-Forge Rules' CLAUDE.md; then
    bline "✓ G-Forge Rules block present in CLAUDE.md"; flush 6 PASS
else
    bline "✗ G-Forge Rules block missing from CLAUDE.md"
    bfix 'Run `/g-init` to inject G-Forge rules into CLAUDE.md.'
    flush 6 FAIL
fi

# ── Check 7 — G-RULES.md present ────────────────────────────────────────────
if [ -f G-RULES.md ]; then
    bline "✓ G-RULES.md present"; flush 7 PASS
else
    bline "✗ G-RULES.md missing"
    bfix 'Run `/g-init` or `/g-update` to install G-RULES.md.'
    flush 7 FAIL
fi

# ── Check 8 — @G-RULES.md referenced in CLAUDE.md ───────────────────────────
if [ -f CLAUDE.md ] && grep -qF '@G-RULES.md' CLAUDE.md; then
    bline "✓ @G-RULES.md reference present in CLAUDE.md"; flush 8 PASS
else
    bline "✗ @G-RULES.md reference missing from CLAUDE.md"
    bfix 'Run `/g-init` or `/g-update` to add the @G-RULES.md reference.'
    flush 8 FAIL
fi

# ── Check 9 — no stale sentinel ─────────────────────────────────────────────
if [ ! -f .claude/g-forge-approved ]; then
    bline "✓ No stale approval sentinel"; flush 9 PASS
else
    bline "✗ Stale approval sentinel found"
    bfix 'A stale approval sentinel exists. Delete it: `rm .claude/g-forge-approved`'
    flush 9 FAIL
fi

# ── Check 10 — no stale doc-approval sentinel ───────────────────────────────
if [ ! -f .claude/g-forge-docs-approved ]; then
    bline "✓ No stale doc-approval sentinel"; flush 10 PASS
else
    bline "✗ Stale doc-approval sentinel found"
    bfix 'A stale doc-approval sentinel exists — the doc gate is stuck open. Delete it: `rm .claude/g-forge-docs-approved`'
    flush 10 FAIL
fi

# ── Check 11 — PreCompact hook installed and registered ─────────────────────
c11=PASS
if [ ! -f .claude/hooks/pre-compact.sh ]; then
    bline "✗ PreCompact hook script missing"
    bfix 'Run `/g-init` or `/g-update` to install pre-compact.sh.'
    c11=FAIL
fi
if [ "$(regs PreCompact pre-compact.sh)" -lt 1 ]; then
    bline "✗ PreCompact hook not registered in settings.json"
    bfix 'Run `/g-init` or `/g-update` to register the PreCompact hook.'
    c11=FAIL
fi
[ "$c11" = PASS ] && bline "✓ PreCompact hook installed and registered"
flush 11 "$c11"

# ── Check 12 — SessionStart hook installed and registered ───────────────────
c12=PASS
if [ ! -f .claude/hooks/session-start.sh ]; then
    bline "✗ SessionStart hook script missing"
    bfix 'Run `/g-init` or `/g-update` to install session-start.sh.'
    c12=FAIL
fi
if [ "$(regs SessionStart session-start.sh)" -lt 1 ]; then
    bline "✗ SessionStart hook not registered in settings.json"
    bfix 'Run `/g-init` or `/g-update` to register the SessionStart hook.'
    c12=FAIL
fi
[ "$c12" = PASS ] && bline "✓ SessionStart hook installed and registered"
flush 12 "$c12"

# ── Check 13 — observer hooks installed and registered ──────────────────────
c13=PASS
if [ ! -f .claude/hooks/observe.sh ]; then
    bline "✗ Observer hook script missing"
    bfix 'Run `/g-init` or `/g-update` to install observe.sh.'
    c13=FAIL
fi
if [ "$(regs PostToolUse observe.sh)" -lt 1 ] || [ "$(regs SessionStart observe.sh)" -lt 1 ]; then
    bline "✗ Observer hook not registered in settings.json"
    bfix 'Run `/g-init` or `/g-update` to register the PostToolUse + SessionStart observer hooks.'
    c13=FAIL
fi
[ "$c13" = PASS ] && bline "✓ Observer hook installed and registered"
flush 13 "$c13"

# ── Check 14 — agent lifecycle hooks installed and registered ───────────────
c14=PASS
if [ ! -f .claude/hooks/agent-lifecycle.sh ]; then
    bline "✗ Agent lifecycle hook script missing"
    bfix 'Run `/g-init` or `/g-update` to install agent-lifecycle.sh.'
    c14=FAIL
fi
if [ "$(regs SubagentStart agent-lifecycle.sh)" -lt 1 ] || [ "$(regs SubagentStop agent-lifecycle.sh)" -lt 1 ]; then
    bline "✗ Agent lifecycle hook not registered in settings.json"
    bfix 'Run `/g-init` or `/g-update` to register the SubagentStart + SubagentStop hooks.'
    c14=FAIL
fi
[ "$c14" = PASS ] && bline "✓ Agent lifecycle hook installed and registered"
flush 14 "$c14"

# ── Check 15 — no duplicate / double-firing hook registration ───────────────
c15=PASS
for s in $GF_SCRIPTS; do
    for ev in $EVENTS; do
        n=$(regs "$ev" "$s")
        if [ "$n" -gt 1 ]; then
            bline "✗ $s registered ${n}× under $ev in settings.json — will double-fire"
            bfix 'Run `/g-update` to de-duplicate, or delete the extra entr(y/ies) from `.claude/settings.json`.'
            c15=FAIL
        fi
    done
done
MANIFEST="$PLUGIN_ROOT/hooks/hooks.json"
if [ -f "$MANIFEST" ]; then
    flat=$(tr -d ' \n\r\t' < "$MANIFEST")
    case "$flat" in
        *'"hooks":{}'*) : ;;
        *)
            for s in $GF_SCRIPTS; do
                if grep -qF "$s" "$MANIFEST"; then
                    inreg=0
                    for ev in $EVENTS; do
                        [ "$(regs "$ev" "$s")" -ge 1 ] && inreg=1
                    done
                    if [ "$inreg" = 1 ]; then
                        bline "✗ $s registered by BOTH the plugin manifest and settings.json — double-fires every session"
                        bfix 'Update the plugin (`/g-update`, or reinstall) so the manifest registers no hooks; `.claude/settings.json` is the single registrar.'
                        c15=FAIL
                    fi
                fi
            done ;;
    esac
else
    bnote "plugin manifest hooks/hooks.json not found under the plugin root — manifest leg skipped"
fi
[ "$c15" = PASS ] && bline "✓ No duplicate hook registration (settings.json is the single registrar)"
flush 15 "$c15"

# ── Check 16 — installed-copy drift ─────────────────────────────────────────
c16=PASS

# (a) 7 top-level hooks
hooks_clean=1
for s in $GF_SCRIPTS; do
    src="$PLUGIN_ROOT/hooks/$s"; inst=".claude/hooks/$s"
    if [ ! -f "$src" ]; then
        bnote "plugin source hooks/$s missing — cannot verify"; hooks_clean=0; continue
    fi
    if [ ! -f "$inst" ]; then
        bnote "$s not installed — presence carried by Checks 1-3/11-14"; hooks_clean=0; continue
    fi
    if [ "$(hash_file "$src")" != "$(hash_file "$inst")" ]; then
        bline "✗ $s installed copy differs from plugin source (drift)"
        bfix 'Run `/g-update` to re-sync hooks/ into .claude/hooks/.'
        c16=FAIL; hooks_clean=0
    fi
done
[ "$hooks_clean" = 1 ] && bline "✓ Installed hooks match plugin source (no drift)"

# (b) hooks/lib/ drift — canonical set enumerated from disk, never a list
for src in "$PLUGIN_ROOT"/hooks/lib/*.sh; do
    [ -f "$src" ] || continue
    b=$(basename "$src"); inst=".claude/hooks/lib/$b"
    if [ ! -f "$inst" ]; then
        bline "✗ hooks/lib/$b missing from installed copy (drift)"
        bfix 'Run `/g-update` to re-sync hooks/ into .claude/hooks/.'
        c16=FAIL
    elif [ "$(hash_file "$src")" != "$(hash_file "$inst")" ]; then
        bline "✗ hooks/lib/$b installed copy differs from plugin source (drift)"
        bfix 'Run `/g-update` to re-sync hooks/ into .claude/hooks/.'
        c16=FAIL
    fi
done

# (c) sourced-but-uninstalled libs (install-list completeness) — derive the
# requirement from the INSTALLED hooks; -H is load-bearing (see
# ../references/check-16-drift.md). Zero references → inconclusive, never Pass.
REFS=$(grep -oHE 'lib/[a-z0-9-]+\.sh' .claude/hooks/*.sh 2>/dev/null | sort -u)
if [ -z "$REFS" ]; then
    bline "⚠ install-list completeness — inconclusive (no installed hooks found to derive from)"
else
    for libref in $(printf '%s\n' "$REFS" | sed 's/.*://' | sort -u); do
        if [ ! -f ".claude/hooks/$libref" ]; then
            b=${libref#lib/}
            hooks_for=$(printf '%s\n' "$REFS" | grep -F ":$libref" | sed 's/:[^:]*$//')
            first=$(printf '%s\n' "$hooks_for" | head -1)
            first=$(basename "$first")
            cnt=$(printf '%s\n' "$hooks_for" | grep -c .)
            extra=""
            [ "$cnt" -gt 1 ] && extra=" (+$((cnt-1)) more)"
            bline "✗ hooks/lib/$b sourced by $first$extra but not installed (install list incomplete)"
            bfix "Run \`/g-update\` to re-sync hooks/ into .claude/hooks/. If \`/g-update\` does not resolve it, the skill's install list is short — report it as a plugin defect rather than a project defect."
            c16=FAIL
        fi
    done
fi

# (d) native pre-commit + <hooks-dir>/lib/*.sh drift
GH=$(git rev-parse --git-path hooks 2>/dev/null)
if [ -z "$GH" ]; then
    bnote "not a git repository — native pre-commit drift not checked"
else
    pc="$GH/pre-commit"
    if [ ! -f "$pc" ]; then
        bline "✗ pre-commit missing from installed git hooks dir (drift)"
        bfix 'Run `/g-update` to re-sync hooks/pre-commit into <hooks-dir>/.'
        c16=FAIL
    elif head -5 "$pc" 2>/dev/null | grep -qF 'G-Forge commit gate'; then
        if [ -f "$PLUGIN_ROOT/hooks/pre-commit" ] \
           && [ "$(hash_file "$PLUGIN_ROOT/hooks/pre-commit")" != "$(hash_file "$pc")" ]; then
            bline "✗ pre-commit installed copy differs from plugin source (drift)"
            bfix 'Run `/g-update` to re-sync hooks/pre-commit into <hooks-dir>/.'
            c16=FAIL
        fi
        # <hooks-dir>/lib/*.sh — only beside a G-Forge-managed pre-commit,
        # canonical set enumerated from disk (same derive-from-disk rule)
        for src in "$PLUGIN_ROOT"/hooks/lib/*.sh; do
            [ -f "$src" ] || continue
            b=$(basename "$src"); tgt="$GH/lib/$b"
            if [ ! -f "$tgt" ]; then
                bline "✗ <hooks-dir>/lib/$b missing — native pre-commit will deny every commit with \"could not load\" (drift)"
                bfix 'Run `/g-update` to re-sync hooks/lib/ into <hooks-dir>/lib/.'
                c16=FAIL
            elif [ "$(hash_file "$src")" != "$(hash_file "$tgt")" ]; then
                bline "✗ <hooks-dir>/lib/$b installed copy differs from plugin source (drift)"
                bfix 'Run `/g-update` to re-sync hooks/lib/ into <hooks-dir>/lib/.'
                c16=FAIL
            fi
        done
    else
        bline "⚠ foreign pre-commit present (gate not installed — advisory, run /g-update to see options)"
    fi
fi

# (e) g-rules section files — 10-file flat-rename mapping
for x in A-session B-workflow C-agent-discipline D-code-quality E-architecture-gate F-design-patterns G-documentation H-testing I-project-tracking J-memory; do
    src="$PLUGIN_ROOT/rules/g-rules/$x.md"; inst=".claude/rules/g-rules-$x.md"
    if [ ! -f "$src" ]; then
        bnote "plugin source rules/g-rules/$x.md missing — cannot verify"; continue
    fi
    if [ ! -f "$inst" ]; then
        bline "✗ g-rules-$x.md missing from installed copy (drift)"
        bfix 'Run `/g-update` to re-sync rules/g-rules/ into .claude/rules/.'
        c16=FAIL
    elif [ "$(hash_file "$src")" != "$(hash_file "$inst")" ]; then
        bline "✗ g-rules-$x.md installed copy differs from plugin source (drift)"
        bfix 'Run `/g-update` to re-sync rules/g-rules/ into .claude/rules/.'
        c16=FAIL
    fi
done

# (f) installed agents — classify provenance BEFORE applying any rule
for f in .claude/agents/*.md; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    case "$b" in *-dev.md) continue ;; esac   # project-local: excluded entirely
    psrc=$(find "$PLUGIN_ROOT/profiles" -maxdepth 3 -type f -path "*/agents/$b" 2>/dev/null | head -1)
    if [ -n "$psrc" ]; then
        if [ "$(hash_file "$psrc")" = "$(hash_file "$f")" ]; then
            bline "✓ $b matches profile source (no drift)"
        else
            bline "✗ $b installed copy differs from profile source (drift)"
            bfix 'Run `/g-specialize` to re-sync the architect agent from its profile source.'
            c16=FAIL
        fi
    else
        case "$b" in
            *-implementer.md)
                bline "⚠ $b is template-instantiated (no canonical source — not checked for drift)" ;;
            *)
                bline "✗ $b has no matching profile source — cannot verify (drift)"
                bfix 'Run `/g-update` to check for a renamed or removed profile.'
                c16=FAIL ;;
        esac
    fi
done

# (g) installed architecture skills — enumerate instances from disk
arch_found=0; arch_clean=1
for d in .claude/skills/architecture-*/; do
    [ -d "$d" ] || continue
    arch_found=1
    stack=$(basename "$d"); stack=${stack#architecture-}
    f="${d}SKILL.md"
    if [ ! -f "$f" ]; then
        bnote ".claude/skills/architecture-$stack/ has no SKILL.md — cannot verify"
        arch_clean=0; continue
    fi
    if [ "$(grep -c '^---$' "$f")" -lt 2 ]; then
        bline "✗ .claude/skills/architecture-$stack/SKILL.md malformed (no frontmatter fence) — cannot verify (drift)"
        bfix 're-run `/g-specialize`'
        c16=FAIL; arch_clean=0; continue
    fi
    src="$PLUGIN_ROOT/profiles/$stack/rules/architecture.md"
    if [ ! -f "$src" ]; then
        bline "⚠ .claude/skills/architecture-$stack/SKILL.md has no matching profile source (no canonical source — not checked for drift)"
        bfix 'Run `/g-update` to check for a renamed or removed profile.'
        arch_clean=0; continue
    fi
    tmp=$(mktemp)
    # strip exactly through the closing --- fence — body horizontal rules survive
    awk 'BEGIN{n=0} n<2 && /^---$/{n++; next} n<2{next} {print}' "$f" > "$tmp"
    if [ "$(hash_file "$src")" != "$(hash_file "$tmp")" ]; then
        bline "✗ .claude/skills/architecture-$stack/SKILL.md installed copy differs from profile source (drift)"
        bfix "Run \`/g-update\` to realign it from profiles/$stack/rules/architecture.md."
        c16=FAIL; arch_clean=0
    fi
    rm -f "$tmp"
done
if [ "$arch_found" = 0 ]; then
    bline "ℹ no installed architecture skills — check skipped"
elif [ "$arch_clean" = 1 ]; then
    bline "✓ Installed architecture-skill copies match profile source (no drift)"
fi
flush 16 "$c16"

# ── Check 17 — CLAUDE.md architecture rules format (advisory) ───────────────
nleg=0
if [ -f CLAUDE.md ]; then
    nleg=$(awk '
        /<!-- End G-Forge .*Architecture Rules/ { if (inb && cnt > 3) legacy++; inb=0; next }
        /<!-- G-Forge .*Architecture Rules/     { inb=1; cnt=0; next }
        inb && NF > 0                           { cnt++ }
        END { print legacy+0 }
    ' CLAUDE.md)
fi
if [ "$nleg" -gt 0 ]; then
    bline "⚠ CLAUDE.md has $nleg inline architecture block(s) — legacy format"
    bfix 'Run `/g-update` to extract inline rules to `.claude/rules/` and compact CLAUDE.md automatically.'
    flush 17 ADVISORY
else
    bline "✓ CLAUDE.md architecture rules compact (@reference format)"
    flush 17 PASS
fi

# ── Check 18 — CLAUDE.md total size (advisory) ──────────────────────────────
clines=0
[ -f CLAUDE.md ] && clines=$(wc -l < CLAUDE.md | tr -d ' ')
if [ "$clines" -le 150 ]; then
    bline "✓ CLAUDE.md compact ($clines lines)"
    flush 18 PASS
else
    bline "⚠ CLAUDE.md is $clines lines — may contain inline rules content"
    bfix 'Run `/g-update` to migrate inline rules to `.claude/rules/` files.'
    flush 18 ADVISORY
fi

# ── Check 19 — no leftover legacy g-team plugin (advisory) ──────────────────
gteam=0
[ -d "$HOME/.claude/plugins/cache/g-team" ] && gteam=1
if [ -f "$HOME/.claude/plugins/config.json" ] \
   && grep -q '"g-team"' "$HOME/.claude/plugins/config.json" 2>/dev/null; then
    gteam=1
fi
if [ "$gteam" = 0 ]; then
    bline "✓ No legacy g-team plugin — commands are g-forge only"
    flush 19 PASS
else
    bline "⚠ Legacy g-team plugin still installed — every /g-* command is duplicated"
    bfix 'Remove it via `/plugin` → Installed → g-team → Uninstall (then re-run `/g-update`).'
    flush 19 ADVISORY
fi

# ── Check 20 — .gitignore vets G-Forge artifacts (advisory) ─────────────────
c20=PASS
if [ ! -f .gitignore ]; then
    bline "⚠ No .gitignore — runtime artifacts (sentinels, journal, agent-output) may be committed"
    bfix 'Run `/g-init` (Step 5a) to write the project `.gitignore`.'
    c20=ADVISORY
else
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        GI_MODE=git
    else
        GI_MODE=literal
        bnote "not a git repository — matching .gitignore patterns literally (git check-ignore unavailable)"
    fi
    # gi_ignored <path> — is <path> ignored? `git check-ignore` inside a repo;
    # outside one, a literal .gitignore matcher (exact path / directory-prefix /
    # bare-name component match, last match wins; wildcards not interpreted).
    gi_ignored() {
        if [ "$GI_MODE" = git ]; then
            git check-ignore -q -- "$1" 2>/dev/null
        else
            awk -v p="$1" '
                /^[ \t]*(#|$)/ { next }
                { pat = $0
                  sub(/^[ \t]+/, "", pat); sub(/[ \t]+$/, "", pat)
                  neg = sub(/^!/, "", pat)
                  sub(/\/$/, "", pat)
                  anch = sub(/^\//, "", pat)
                  hit = 0
                  if (!anch && index(pat, "/") == 0) {
                      n = split(p, seg, "/")
                      for (i = 1; i <= n; i++) if (seg[i] == pat) hit = 1
                  } else if (p == pat || index(p, pat "/") == 1) hit = 1
                  if (hit) m = neg ? 0 : 1
                }
                END { exit m ? 0 : 1 }
            ' .gitignore
        fi
    }
    for a in ".claude/g-forge-approved" ".claude/g-forge-docs-approved" ".claude/journal/" "g-docs/agent-output/"; do
        probe="$a"; case "$a" in */) probe="${a}x" ;; esac
        if ! gi_ignored "$probe"; then
            bline "⚠ .gitignore does not ignore $a — it may be committed"
            bfix 'Add the missing runtime-artifact pattern(s) (see `/g-init` Step 5a).'
            c20=ADVISORY
        fi
    done
    for p in "g-docs/ROADMAP.md" "g-docs/todo.md" "g-docs/milestones/" "g-docs/decisions/" "g-docs/retros/" "g-docs/patterns/" "g-docs/inbox/" "g-wiki/"; do
        probe="$p"; case "$p" in */) probe="${p}x" ;; esac
        if gi_ignored "$probe"; then
            bline "⚠ .gitignore ignores $p — project record won't be committed"
            bfix 'Remove or scope the over-broad pattern so the `g-docs/` project record stays tracked.'
            c20=ADVISORY
        fi
    done
    [ "$c20" = PASS ] && bline "✓ .gitignore vets G-Forge artifacts (runtime ignored, project record tracked)"
fi
flush 20 "$c20"

# ── Check 21 — no stray G-Forge documents (advisory) ────────────────────────
strays=""
for f in ROADMAP.md todo.md todo-done.md project_brief.md; do
    [ -f "$f" ] && strays="$strays $f"
done
[ -d milestones ] && strays="$strays milestones/"
# canonical dir-name set = whatever already lives directly under g-docs/ in
# this project (inverted check, not a fixed allowlist); a candidate is only a
# stray if its contents look like docs: >=1 .md file, no source-code file.
for canon in $(find g-docs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n1 basename 2>/dev/null); do
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        has_md=$(find "$d" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)
        has_src=$(find "$d" -maxdepth 1 -type f \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' -o -name '*.jsx' -o -name '*.py' -o -name '*.sh' -o -name '*.rs' -o -name '*.go' -o -name '*.java' -o -name '*.vue' \) 2>/dev/null | head -1)
        [ -n "$has_md" ] && [ -z "$has_src" ] && strays="$strays $d"
    done <<EOF
$(find . -type d -name "$canon" -not -path './g-docs*' -not -path './g-wiki*' -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null)
EOF
done
strays=${strays# }
if [ -z "$strays" ]; then
    bline "✓ No stray G-Forge documents — all tracking lives under g-docs/"
    flush 21 PASS
else
    set -- $strays
    bline "⚠ $# stray G-Forge document(s) outside g-docs/: $strays"
    bfix 'Move each into `g-docs/` preserving history, then re-run /g-doctor: `git mv ROADMAP.md g-docs/ROADMAP.md` · `git mv milestones g-docs/milestones` (etc.)'
    bfix 'Offer to run the moves now. After moving, update any references with `/g-update`, and confirm nothing still points at the old root path.'
    flush 21 ADVISORY
fi

# ── Check 22 — Roundtable security (advisory, only when bound) ──────────────
if [ ! -f .claude/roundtable ]; then
    bnote "no Roundtable bound — skip"
    flush 22 SKIP
else
    c22=PASS
    tracked=0
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git check-ignore -q .claude/roundtable 2>/dev/null || tracked=1
        git ls-files --error-unmatch .claude/roundtable >/dev/null 2>&1 && tracked=1
    fi
    if [ "$tracked" = 1 ]; then
        bline '⚠ `.claude/roundtable` is tracked — the bound surface ref (and any creds near it) could be pushed'
        bfix 'Add `.claude/` to `.gitignore` (it should already be — see Check 20) and `git rm --cached .claude/roundtable`.'
        c22=ADVISORY
    fi
    if grep -qiE '^(token|secret|password|api[_-]?key)=' .claude/roundtable 2>/dev/null; then
        bline '🔴 A credential is stored in `.claude/roundtable` — move it to an environment variable and remove the line. Never commit a token.'
        c22=ADVISORY
    fi
    [ "$c22" = PASS ] && bline "✓ Roundtable security — bind record gitignored, no credential in it (confirm the Doc is link-restricted, not public)"
    # always-reminder (old spec: "Advisory (always, reminder)") — a LINE row so
    # it survives into the transcribed report on every branch; never flips c22
    bline 'the bound Doc must be **link-restricted, never public** — `/g-roundtable` enforces this at bind, but confirm sharing hasn'\''t been widened since.'
    flush 22 "$c22"
fi

# ── Check 23 — plugin version lag (advisory) ────────────────────────────────
SEMVER_LIB="$PLUGIN_ROOT/hooks/lib/semver-compare.sh"
if [ ! -f "$SEMVER_LIB" ]; then
    bnote "hooks/lib/semver-compare.sh not found under the plugin root — Check 23 skipped"
    flush 23 SKIP
else
    . "$SEMVER_LIB"
    LATEST=""; LATEST_STATE=unreachable
    if [ "${GF_DOCTOR_OFFLINE:-0}" != 1 ]; then
        raw=$(curl -sf --max-time 10 https://raw.githubusercontent.com/onlygian/G-Forge/main/.claude-plugin/plugin.json 2>/dev/null | grep '"version"')
        if [ -n "$raw" ]; then
            LATEST=$(printf '%s\n' "$raw" | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
            LATEST_STATE=ok
        fi
    fi
    CACHE_DIR=""; CACHE=""
    for d in "$HOME/.claude/plugins/cache/g-forge/g-forge"/*/; do
        [ -d "$d" ] || continue
        v=$(basename "$d")
        if [ -z "$CACHE_DIR" ]; then
            CACHE_DIR="$v"
        else
            r=$(gf_semver_compare "$v" "$CACHE_DIR" 2>/dev/null) && [ "$r" = 1 ] && CACHE_DIR="$v"
        fi
    done
    if [ -n "$CACHE_DIR" ] && [ -f "$HOME/.claude/plugins/cache/g-forge/g-forge/$CACHE_DIR/.claude-plugin/plugin.json" ]; then
        CACHE=$(json_version "$HOME/.claude/plugins/cache/g-forge/g-forge/$CACHE_DIR/.claude-plugin/plugin.json")
    fi
    INSTALLED=""
    if [ -f .claude-plugin/plugin.json ] \
       && grep -q '"name"[[:space:]]*:[[:space:]]*"g-forge"' .claude-plugin/plugin.json 2>/dev/null; then
        INSTALLED=$(json_version .claude-plugin/plugin.json)
    fi
    INST_DISP=${INSTALLED:-unknown}
    had_warn=0; had_info=0; compared=0; aligned=1
    if [ "$LATEST_STATE" = unreachable ] && [ -n "$CACHE" ]; then
        bline "⚠ Could not reach GitHub — staleness cannot be ruled out. Comparing cache (v$CACHE) vs. installed (v$INST_DISP) only."
        had_warn=1
    fi
    if [ "$LATEST_STATE" = ok ] && [ -n "$CACHE" ]; then
        r=$(gf_semver_compare "$CACHE" "$LATEST"); rc=$?
        compared=1
        if [ "$rc" -ne 0 ]; then
            bline "⚠ cache version string is malformed — cannot compare against GitHub latest"
            had_warn=1; aligned=0
        elif [ "$r" = "-1" ]; then
            bline "⚠ Plugin cache is stale — v$CACHE installed, v$LATEST available"
            bfix 'Update the cache first: `/plugins` → Installed → g-forge → Update now — then run `/g-update` to sync this project.'
            had_warn=1; aligned=0
        elif [ "$r" = "1" ]; then
            bline "ℹ Plugin cache (v$CACHE) is ahead of the GitHub latest release (v$LATEST) — expected on the plugin source repo when work is committed but not yet released; not actionable."
            had_info=1; aligned=0
        fi
    fi
    if [ -n "$CACHE" ] && [ -n "$INSTALLED" ]; then
        r=$(gf_semver_compare "$INSTALLED" "$CACHE"); rc=$?
        compared=1
        if [ "$rc" -ne 0 ]; then
            bline "⚠ installed version string is malformed — cannot compare against cache"
            had_warn=1; aligned=0
        elif [ "$r" = "-1" ]; then
            bline "⚠ Project files are behind the plugin cache — v$INST_DISP installed, v$CACHE in cache"
            bfix "Run \`/g-update\` to realign this project's G-Forge-managed files."
            had_warn=1; aligned=0
        elif [ "$r" = "1" ]; then
            # installed ahead of cache: never "aligned" (Pass requires every
            # resolvable comparison to return 0) — distinct from the
            # cache-ahead-of-release ℹ branch above
            bline "ℹ Project files (v$INST_DISP) are ahead of the plugin cache (v$CACHE) — expected on the plugin source repo when the working tree's version is bumped before the cache updates; not actionable."
            had_info=1; aligned=0
        fi
    fi
    if [ "$aligned" = 1 ] && [ "$compared" = 1 ] && [ "$had_warn" = 0 ]; then
        bline "✓ Plugin versions aligned — cache v$CACHE, installed v$INST_DISP"
        flush 23 PASS
    elif [ "$had_warn" = 1 ]; then
        flush 23 ADVISORY
    elif [ "$had_info" = 1 ]; then
        flush 23 INFO
    else
        bnote "no plugin cache found and no comparison possible — nothing to compare"
        flush 23 INCONCLUSIVE
    fi
fi

# ── Check 24 — CLAUDE.md injection-rule compliance (model-executed) ─────────
bnote "Check 24 is model-executed by security contract — load references/check-24-injection.md and run the classification pass in-model"
flush 24 NEEDS-MODEL

# ── Check 25 — integration-tier guard file (advisory) ───────────────────────
tier=""; tier_src=""
if [ -f .claude/integration-tier ]; then
    tier=$(head -1 .claude/integration-tier 2>/dev/null | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    tier_src=local
else
    WLIB="$PLUGIN_ROOT/hooks/lib/worktree-resolve.sh"
    if [ -f "$WLIB" ]; then
        . "$WLIB"
        pdir=$(gf_resolve_primary_claude_dir 2>/dev/null)
        if [ -n "$pdir" ] && [ -f "$pdir/integration-tier" ]; then
            tier=$(head -1 "$pdir/integration-tier" 2>/dev/null | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
            tier_src=primary
        fi
    fi
fi
if [ -z "$tier_src" ]; then
    bline '⚠ governing `integration-tier` missing — all hooks (commit gate included) are silently inert'
    bfix 'Run `/g-tier full` (or re-run `/g-init`) **from the primary tree** to restore the tier file.'
    flush 25 ADVISORY
else
    case "$tier" in
        full|balanced|light)
            bline "✓ integration tier set: $tier ($tier_src)"
            flush 25 PASS ;;
        *)
            bline '⚠ governing `integration-tier` contains an unrecognized value: '"$tier"
            bfix 'Run `/g-tier` to write one of `full`, `balanced`, `light`.'
            flush 25 ADVISORY ;;
    esac
fi

out "SUMMARY: required_passed=$REQ_PASSED required_total=16 advisories=$ADVISORIES"
exit 0

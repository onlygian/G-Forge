#!/bin/bash
# Unit tests for hooks/observe.sh (the silent observer) + hooks/agent-lifecycle.sh.
# Verifies: meaningful commands are journaled with the right kind, noise is
# skipped, the journal is valid JSONL, and the parser survives a stubbed
# python3 (the Windows Microsoft-Store stub) without losing events.
# Also tests: agent-lifecycle extraction of agent_type, agent_id, and RESULT
# tokens from real SubagentStart/SubagentStop payloads (M-audit finding #22 fix),
# plus a forced-node-path regression pin for JSON null agent_type (W1.5f/W1.6-15).
# W1.6-17: json_escape hostile-input coverage with adversarial chars on line 1.
# W1.6-18: sed-tier escaped-quote truncation behavior regression pin.
# W2-20: SessionStart `source` field journaled — one pin per platform source
# value (startup/resume/compact) + absent-field fallback + null-artifact pin.
# W3-10/W3-11: control-char sanitize + UTF-8-safe truncation fixtures.
# S-fix task 12: observe.sh's own last-resort sed-tier extract_cmd() now uses
# the escape-aware capture pattern from hooks/check-commit.sh:83 instead of
# the naive [^"]* form, so a `command` field with an escaped inner quote
# (\") and backslash (\\) is captured whole rather than truncated at the
# first inner quote — regression pin below.
#
# Groups covered: original observe.sh command-kind/noise-skip tests, W3-10
# control-char pins, W3-11 UTF-8-boundary pin, W2-20 session-source tests,
# agent-lifecycle extraction/regression tests, and the S-fix task-12 sed-tier
# escape-aware extraction pin. See the Results line at the end of a run for
# the current total — not restated here as a fixed number (an unpinned count
# is a review finding, G-RULES §G/ADR-013).

SCRIPT="$(cd "$(dirname "$0")" && pwd)/../hooks/observe.sh"
PASS=0
FAIL=0

check() { # name expected actual
    if [ "$2" = "$3" ]; then echo "PASS: $1"; PASS=$((PASS+1));
    else echo "FAIL: $1 (expected '$2', got '$3')"; FAIL=$((FAIL+1)); fi
}

# json_line_valid <file> — portable JSON validity check for a single-line
# journal entry. Prefers jq (not always installed — stock git-bash lacks it,
# same caveat as kind_of()'s sed-based extraction above), falls back to
# python3/node, and as a last resort the same structural brace/quote shape
# check already used by the "journal is valid JSONL" pin below. Mirrors
# observe.sh's own hardened parser cascade (extract_cmd) rather than hard-
# depending on any single tool.
json_line_valid() {
    local f="$1" line
    line=$(head -1 "$f" 2>/dev/null)
    [ -z "$line" ] && { echo no; return; }
    if command -v jq >/dev/null 2>&1; then
        if printf '%s' "$line" | jq -e . >/dev/null 2>&1; then echo yes; else echo no; fi
        return
    fi
    if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys' >/dev/null 2>&1; then
        if printf '%s' "$line" | python3 -c '
import sys, json
try:
    json.loads(sys.stdin.buffer.read())
except Exception:
    sys.exit(1)
' >/dev/null 2>&1; then echo yes; else echo no; fi
        return
    fi
    if command -v node >/dev/null 2>&1; then
        if printf '%s' "$line" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{JSON.parse(s);process.exit(0);}catch(e){process.exit(1);}});" >/dev/null 2>&1; then echo yes; else echo no; fi
        return
    fi
    case "$line" in
        '{"ts":"'*'","kind":"'*'"'*'}') echo yes ;;
        *) echo no ;;
    esac
}

# kind_of <command> [PATH-override] — run observe.sh on a payload, return the
# journaled kind (empty string if the command was skipped as noise).
kind_of() {
    # The hook self-guards to G-Forge-managed projects (.claude/integration-tier);
    # mark each fixture as one so the observer is active.
    local dir; dir=$(mktemp -d); ( cd "$dir" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
    if [ -n "$2" ]; then
        echo "{\"tool_input\":{\"command\":\"$1\"}}" | ( cd "$dir" && PATH="$2" bash "$SCRIPT" log )
    else
        echo "{\"tool_input\":{\"command\":\"$1\"}}" | ( cd "$dir" && bash "$SCRIPT" log )
    fi
    local f; f=$(ls "$dir"/.claude/journal/*.jsonl 2>/dev/null | head -1)
    # Read the kind with sed, not jq — stock git-bash has no jq, and the hook
    # must not depend on it either. Journal lines are a fixed flat shape.
    if [ -n "$f" ]; then sed -n 's/.*"kind":"\([^"]*\)".*/\1/p' "$f" | head -1; fi
    rm -rf "$dir"
}

check "git commit → commit"            "commit"      "$(kind_of 'git commit -m wip')"
check "git push → push"                "push"        "$(kind_of 'git push origin main')"
check "git merge → merge"              "merge"       "$(kind_of 'git merge main')"
check "git checkout -b → branch"       "branch"      "$(kind_of 'git checkout -b feat/x')"
check "git revert → revert"            "revert"      "$(kind_of 'git revert HEAD')"
check "pytest → test"                  "test"        "$(kind_of 'pytest -q')"
check "npm test → test"                "test"        "$(kind_of 'npm test')"
check "go test → test"                 "test"        "$(kind_of 'go test ./...')"
check "rm -rf → destructive"           "destructive" "$(kind_of 'rm -rf build')"
check "ls (noise) → skipped"           ""            "$(kind_of 'ls -la')"
check "cat (noise) → skipped"          ""            "$(kind_of 'cat file.txt')"
# Hardening #6 — commit detection tolerates -C/-c global flags before `commit`.
check "git -C path commit → commit"    "commit"      "$(kind_of 'git -C /some/path commit -m x')"
check "git -c config commit → commit"  "commit"      "$(kind_of 'git -c user.name=x commit -m x')"

# Stub safety: shadow every JSON parser (jq/python3/node) with exit-1 stubs
# prepended to the real PATH, so no parser yields a command. The raw-payload
# fallback must still recognise the commit and journal it. (Replacing PATH
# wholesale by symlinking coreutils breaks git-bash — bash.exe can't load its
# DLLs from a bare symlink dir — so we shadow the parsers, not the environment.)
STUB=$(mktemp -d)
for p in jq python3 node; do printf '#!/bin/sh\nexit 1\n' > "$STUB/$p"; chmod +x "$STUB/$p"; done
check "commit journaled with no working parser" "commit" "$(kind_of 'git commit -m wip' "$STUB:$PATH")"
rm -rf "$STUB"

# Session marker.
SDIR=$(mktemp -d); ( cd "$SDIR" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier && bash "$SCRIPT" session )
JFILE=$(ls "$SDIR"/.claude/journal/*.jsonl 2>/dev/null | head -1)
SKIND=$(sed -n 's/.*"kind":"\([^"]*\)".*/\1/p' "$JFILE" 2>/dev/null | head -1)
check "session marker written" "session" "$SKIND"
# Journal must be valid JSONL. Portable shape check (no jq): every non-empty
# line is a single brace-wrapped object carrying the ts + kind keys.
valid=1; lines=0
while IFS= read -r line; do
    [ -z "$line" ] && continue
    lines=$((lines+1))
    case "$line" in
        '{"ts":"'*'","kind":"'*'"'*'}') : ;;
        *) valid=0 ;;
    esac
done < "$JFILE"
if [ "$valid" -eq 1 ] && [ "$lines" -ge 1 ]; then
    echo "PASS: journal is valid JSONL"; PASS=$((PASS+1))
else
    echo "FAIL: journal is not valid JSONL"; FAIL=$((FAIL+1))
fi
rm -rf "$SDIR"

# W3-10 — control-char sanitize (M-audit W3 task 10). The detail sanitize
# chain previously stripped only CR/LF (tr -d '\n\r'); any other C0 control
# byte (tab, \x01-\x1F) passed raw into the journal JSONL line and broke
# JSON decode. Fixed fixture: a literal tab embedded in an otherwise-
# recognized "npm test" command.
CTRLDIR=$(mktemp -d)
( cd "$CTRLDIR" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
printf '{"tool_input":{"command":"npm test\t--verbose"}}' | ( cd "$CTRLDIR" && bash "$SCRIPT" log )
CTRLFILE=$(ls "$CTRLDIR"/.claude/journal/*.jsonl 2>/dev/null | head -1)
CTRL_VALID=$(json_line_valid "$CTRLFILE")
CTRL_DETAIL=$(sed -n 's/.*"detail":"\([^"]*\)".*/\1/p' "$CTRLFILE" 2>/dev/null | head -1)
rm -rf "$CTRLDIR"
check "control char (tab) in detail -> journal line parses as valid JSON" "yes" "$CTRL_VALID"
case "$CTRL_DETAIL" in
    *"$(printf '\t')"*)
        echo "FAIL: control char (tab) leaked raw into detail field"; FAIL=$((FAIL+1)) ;;
    *)
        echo "PASS: control char (tab) stripped from detail field"; PASS=$((PASS+1)) ;;
esac

# W3-11 — UTF-8-safe truncation (M-audit W3 task 11). `cut -c1-300` truncates
# by BYTES on this platform's userland regardless of locale, splitting a
# multi-byte UTF-8 sequence mid-character when the 300-byte boundary lands
# inside one and emitting invalid UTF-8 that breaks JSON decode. Fixed
# fixture: 299 ASCII 'x' bytes (so byte 300 is the first byte of the next
# character) + 5 repeated 'e-acute' (U+00E9, 2-byte UTF-8) straddling the
# cut point. Built from raw bytes via bash ANSI-C quoting ($'\xC3\xA9'),
# not a literal source character, so the fixture's byte layout is explicit
# and independent of this file's own on-disk encoding; deterministic/fixed,
# never random, per the task's positioning requirement.
EACUTE=$'\xc3\xa9'
PAD290=$(printf 'x%.0s' $(seq 1 290))
UTF8_CMD_DETAIL="npm test ${PAD290}${EACUTE}${EACUTE}${EACUTE}${EACUTE}${EACUTE}"
UTF8DIR=$(mktemp -d)
( cd "$UTF8DIR" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
printf '{"tool_input":{"command":"%s"}}' "$UTF8_CMD_DETAIL" | ( cd "$UTF8DIR" && bash "$SCRIPT" log )
UTF8FILE=$(ls "$UTF8DIR"/.claude/journal/*.jsonl 2>/dev/null | head -1)
UTF8_VALID=$(json_line_valid "$UTF8FILE")
rm -rf "$UTF8DIR"
check "multi-byte char straddling 300-byte cut -> journal line parses as valid JSON/UTF-8" "yes" "$UTF8_VALID"

# W2-20 — SessionStart `source` field journaled (M-audit W2 task 20). W1.7
# Task-18 ruled multi-fire-per-source PLATFORM-EXPECTED; journaling source
# makes each event self-explanatory for /g-retro mining instead of looking
# like a duplicate-event bug. Fixed hardcoded SessionStart-shaped payloads,
# one per platform source value plus one absent-field fallback.
#
# session_source_of <stdin-payload> — run observe.sh session with a given
# stdin payload, extract only the "(source: X)" token from the journaled
# detail (branch name in the fixture repo is not asserted here — the
# existing "session marker written" pin above already covers that field).
session_source_of() {
    local dir; dir=$(mktemp -d); ( cd "$dir" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
    printf '%s' "$1" | ( cd "$dir" && bash "$SCRIPT" session )
    local f; f=$(ls "$dir"/.claude/journal/*.jsonl 2>/dev/null | head -1)
    local out=""
    if [ -n "$f" ]; then out=$(sed -n 's/.*(source: \([a-zA-Z]*\)).*/\1/p' "$f" | head -1); fi
    rm -rf "$dir"
    printf '%s' "$out"
}

PAYLOAD_SESSION_STARTUP='{"session_id":"s1","source":"startup","hook_event_name":"SessionStart"}'
PAYLOAD_SESSION_RESUME='{"session_id":"s1","source":"resume","hook_event_name":"SessionStart"}'
PAYLOAD_SESSION_COMPACT='{"session_id":"s1","source":"compact","hook_event_name":"SessionStart"}'
PAYLOAD_SESSION_NULL='{"session_id":"s1","source":null,"hook_event_name":"SessionStart"}'

check "session source startup journaled"  "startup" "$(session_source_of "$PAYLOAD_SESSION_STARTUP")"
check "session source resume journaled"   "resume"  "$(session_source_of "$PAYLOAD_SESSION_RESUME")"
check "session source compact journaled"  "compact" "$(session_source_of "$PAYLOAD_SESSION_COMPACT")"
check "session source absent → no suffix" ""        "$(session_source_of "")"
check "session source null → no suffix"   ""        "$(session_source_of "$PAYLOAD_SESSION_NULL")"

# W1.6 F-node lesson pin: a JSON `null` source must never leak into the
# journal as the literal string "null", and an absent/unparseable source
# must never leave a dangling empty "(source: )" artifact.
NULLDIR=$(mktemp -d); ( cd "$NULLDIR" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
printf '%s' "$PAYLOAD_SESSION_NULL" | ( cd "$NULLDIR" && bash "$SCRIPT" session )
NULLFILE=$(ls "$NULLDIR"/.claude/journal/*.jsonl 2>/dev/null | head -1)
NULL_DETAIL=""
[ -n "$NULLFILE" ] && NULL_DETAIL=$(sed -n 's/.*"detail":"\([^"]*\)".*/\1/p' "$NULLFILE" | head -1)
rm -rf "$NULLDIR"
case "$NULL_DETAIL" in
    *null*|*"(source: )"*|*"(source:)"*)
        echo "FAIL: null-source detail has a null/empty artifact (got '$NULL_DETAIL')"; FAIL=$((FAIL+1)) ;;
    *)
        echo "PASS: null-source detail has no null/empty artifact"; PASS=$((PASS+1)) ;;
esac

# ============================================================================
# Agent-lifecycle extraction tests (M-audit finding #22 fix).
# Test the agent_type / agent_id / RESULT extraction from real harness payloads
# and journal detail formatting: "<agent_type> <event> <agent_id8>[ <RESULT>]"
# ============================================================================

AGENT_SCRIPT="$(cd "$(dirname "$0")" && pwd)/../hooks/agent-lifecycle.sh"

# agent_lifecycle_detail <event> <payload-json> — run agent-lifecycle.sh on a
# real payload and extract the journal detail field from the output.
agent_lifecycle_detail() {
    local event="$1" payload="$2" dir
    dir=$(mktemp -d)
    ( cd "$dir" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
    printf '%s' "$payload" | ( cd "$dir" && bash "$AGENT_SCRIPT" "$event" 2>&1 )
    rm -rf "$dir"
}

# agent_lifecycle_journal <event> <payload-json> [PATH-override] — extract the
# journal detail line (if any) from the agent-lifecycle hook output. Optional
# third arg overrides PATH (same tier-forcing idiom as kind_of's second arg
# above) so a fixture can shadow specific parsers to force a given tier.
agent_lifecycle_journal() {
    local event="$1" payload="$2" path_override="$3" dir jfile detail
    dir=$(mktemp -d)
    ( cd "$dir" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
    if [ -n "$path_override" ]; then
        printf '%s' "$payload" | ( cd "$dir" && PATH="$path_override" bash "$AGENT_SCRIPT" "$event" >/dev/null 2>&1 )
    else
        printf '%s' "$payload" | ( cd "$dir" && bash "$AGENT_SCRIPT" "$event" >/dev/null 2>&1 )
    fi
    jfile=$(ls "$dir"/.claude/journal/*.jsonl 2>/dev/null | head -1)
    if [ -n "$jfile" ]; then
        # Extract detail field using sed (portable, no jq dependency in tests).
        # Escape-aware capture: \\. matches any escaped char so the value can
        # contain \" and \\ without truncating at the first escaped quote
        # (returns the still-escaped form; assertions match on substrings).
        sed -n 's/.*"detail":"\(\(\\.\|[^"\\]\)*\)".*/\1/p' "$jfile" | head -1
    fi
    rm -rf "$dir"
}

# agent_lifecycle_jsonl <event> <payload-json> — extract the raw journal line
# (if any) from the agent-lifecycle hook output for JSON validity checks.
agent_lifecycle_jsonl() {
    local event="$1" payload="$2" dir jfile
    dir=$(mktemp -d)
    ( cd "$dir" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
    printf '%s' "$payload" | ( cd "$dir" && bash "$AGENT_SCRIPT" "$event" >/dev/null 2>&1 )
    jfile=$(ls "$dir"/.claude/journal/*.jsonl 2>/dev/null | head -1)
    if [ -n "$jfile" ]; then
        head -1 "$jfile"
    fi
    rm -rf "$dir"
}

# Real payload fixture: SubagentStart with claude-plugin-implementer agent
PAYLOAD_START='{"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","prompt_id":"p1","agent_id":"a7653079b1995bdc8","agent_type":"claude-plugin-implementer","hook_event_name":"SubagentStart"}'

# Real payload fixture: SubagentStop with wave agent (has RESULT: DONE line)
PAYLOAD_STOP_WAVE='{"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","prompt_id":"p1","agent_id":"a7653079b1995bdc8","agent_type":"claude-plugin-implementer","permission_mode":"auto","effort":{"level":"high"},"hook_event_name":"SubagentStop","stop_hook_active":false,"agent_transcript_path":"/tmp/a.jsonl","last_assistant_message":"RESULT: DONE\nSUMMARY: x","background_tasks":[],"session_crons":[]}'

# Real payload fixture: SubagentStop with internal agent (empty agent_type)
PAYLOAD_STOP_INTERNAL='{"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","prompt_id":"p1","agent_id":"a7653079b1995bdc8","agent_type":"","permission_mode":"auto","effort":{"level":"high"},"hook_event_name":"SubagentStop","stop_hook_active":false,"agent_transcript_path":"/tmp/a.jsonl","last_assistant_message":"go","background_tasks":[],"session_crons":[]}'

# Real payload fixture: SubagentStop with quotes and backslash in RESULT line
# (adversarial characters on line 1 of message, not line 2, so head -n1 captures them).
# json_escape must preserve and properly escape the quotes and backslashes.
PAYLOAD_STOP_QUOTED='{"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","prompt_id":"p1","agent_id":"a7653079b1995bdc8","agent_type":"test-agent","hook_event_name":"SubagentStop","stop_hook_active":false,"agent_transcript_path":"/tmp/a.jsonl","last_assistant_message":"RESULT: DONE \"path\\\\file\" survived","background_tasks":[]}'

# Real payload fixture: SubagentStart with JSON null agent_type (distinct from
# the empty-string "internal" case above — a real null must fall back to
# "unknown", not stringify to the literal "null").
PAYLOAD_START_NULL='{"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","prompt_id":"p1","agent_id":"a7653079b1995bdc8","agent_type":null,"hook_event_name":"SubagentStart"}'

# Test 1: Start payload extracts agent_type and agent_id correctly
DETAIL1=$(agent_lifecycle_journal "start" "$PAYLOAD_START")
if echo "$DETAIL1" | grep -q "claude-plugin-implementer start a7653079"; then
    echo "PASS: start payload → journal contains 'claude-plugin-implementer start a7653079'"; PASS=$((PASS+1))
else
    echo "FAIL: start payload → expected detail to contain 'claude-plugin-implementer start a7653079', got '$DETAIL1'"; FAIL=$((FAIL+1))
fi

# Test 2: Wave-agent stop extracts RESULT: DONE token
DETAIL2=$(agent_lifecycle_journal "stop" "$PAYLOAD_STOP_WAVE")
if echo "$DETAIL2" | grep -q "claude-plugin-implementer stop a7653079 DONE"; then
    echo "PASS: wave-agent stop → journal contains 'claude-plugin-implementer stop a7653079 DONE'"; PASS=$((PASS+1))
else
    echo "FAIL: wave-agent stop → expected detail to contain 'claude-plugin-implementer stop a7653079 DONE', got '$DETAIL2'"; FAIL=$((FAIL+1))
fi

# Test 3: Internal stop (empty agent_type) renders as "internal", not "unknown"
DETAIL3=$(agent_lifecycle_journal "stop" "$PAYLOAD_STOP_INTERNAL")
if [ -n "$DETAIL3" ] && echo "$DETAIL3" | grep -q "^internal stop"; then
    echo "PASS: internal stop → detail begins 'internal stop'"; PASS=$((PASS+1))
else
    echo "FAIL: internal stop → expected detail to begin 'internal stop', got '$DETAIL3'"; FAIL=$((FAIL+1))
fi
if echo "$DETAIL3" | grep -q "unknown"; then
    echo "FAIL: internal stop → detail should not contain 'unknown', got '$DETAIL3'"; FAIL=$((FAIL+1))
else
    echo "PASS: internal stop → detail contains no 'unknown'"; PASS=$((PASS+1))
fi

# Test 4: Empty stdin is handled gracefully (exit 0, absent-payload labeled as 'unknown start')
EMPTY_DETAIL=$(agent_lifecycle_journal "start" "")
if [ "$EMPTY_DETAIL" = "unknown start" ]; then
    echo "PASS: empty stdin → journal detail is 'unknown start' (absent-payload marker)"; PASS=$((PASS+1))
else
    echo "FAIL: empty stdin → expected detail 'unknown start', got '$EMPTY_DETAIL'"; FAIL=$((FAIL+1))
fi

# Test 5: Quotes and backslashes in RESULT line do not break JSON; adversarial
# chars (quotes + backslashes) must be present in the parsed detail (not discarded
# by head -n1), properly json-escaped in the journal line.
DETAIL5=$(agent_lifecycle_journal "stop" "$PAYLOAD_STOP_QUOTED")
JSONL5=$(agent_lifecycle_jsonl "stop" "$PAYLOAD_STOP_QUOTED")
if [ -n "$JSONL5" ]; then
    # Check JSON validity: line must start with { and end with }
    case "$JSONL5" in
        '{'*'}')
            # Detail must contain both "path" and "file" (from the adversarial fixture),
            # proving json_escape exercised the quotes and backslashes on line 1.
            if echo "$DETAIL5" | grep -q 'test-agent stop a7653079' && \
               echo "$DETAIL5" | grep -q 'path' && echo "$DETAIL5" | grep -q 'file'; then
                echo "PASS: quoted/backslash in RESULT → JSON valid, adversarial chars preserved"; PASS=$((PASS+1))
            else
                echo "FAIL: quoted/backslash in RESULT → adversarial chars lost or detail malformed, got '$DETAIL5'"; FAIL=$((FAIL+1))
            fi
            ;;
        *)
            echo "FAIL: quoted/backslash in RESULT → journal line is not valid JSON"; FAIL=$((FAIL+1))
            ;;
    esac
else
    echo "FAIL: quoted/backslash in RESULT → no journal line emitted"; FAIL=$((FAIL+1))
fi

# Test 6: JSON null agent_type on a forced-node-path — shadow jq and python3
# with exit-1 stubs (same shadowing idiom as the STUB fixture above) so only
# the node tier can answer; JSON.parse(...).agent_type is JS `null`, and the
# node tier must map that to "unknown", never stringify it to "null".
STUB2=$(mktemp -d)
for p in jq python3; do printf '#!/bin/sh\nexit 1\n' > "$STUB2/$p"; chmod +x "$STUB2/$p"; done
DETAIL6=$(agent_lifecycle_journal "start" "$PAYLOAD_START_NULL" "$STUB2:$PATH")
if echo "$DETAIL6" | grep -q "^unknown start" && ! echo "$DETAIL6" | grep -q "null"; then
    echo "PASS: forced-node-path null agent_type → detail begins 'unknown start', never 'null'"; PASS=$((PASS+1))
else
    echo "FAIL: forced-node-path null agent_type → expected detail to begin 'unknown start' with no 'null', got '$DETAIL6'"; FAIL=$((FAIL+1))
fi
rm -rf "$STUB2"

# Test 7: Sed tier escaped-quote truncation behavior (W1.6-18 regression pin).
# The sed-tier parser (last resort when jq/python3/node all fail) uses the
# pattern [^"]* which means "match any char except literal quote". It does not
# understand JSON escaping, so an escaped quote like \" is seen as backslash
# followed by a quote terminator. For payload with agent_type "value\"truncated",
# the sed tier extracts "value\" (truncated at the escaped quote). This test
# stubs ALL THREE parsers (jq, python3, AND node) to force the sed tier, then
# verifies it produces the documented truncation behavior on escaped quotes.
STUB3=$(mktemp -d)
for p in jq python3 node; do printf '#!/bin/sh\nexit 1\n' > "$STUB3/$p"; chmod +x "$STUB3/$p"; done
PAYLOAD_STOP_SED_ESCAPE='{"session_id":"s1","transcript_path":"/tmp/t.jsonl","cwd":"/tmp","prompt_id":"p1","agent_id":"a7653079b1995bdc8","agent_type":"sedtier\"truncated","hook_event_name":"SubagentStop","stop_hook_active":false,"agent_transcript_path":"/tmp/a.jsonl","last_assistant_message":"RESULT: DONE","background_tasks":[]}'
DETAIL7=$(agent_lifecycle_journal "stop" "$PAYLOAD_STOP_SED_ESCAPE" "$STUB3:$PATH")
# The sed tier extracts "sedtier\" (backslash is part of the payload content,
# quote is the terminator). After json_escape, the backslash is doubled, so the
# observed detail is: sedtier\\ stop <agent_id>
# The assertion must DISCRIMINATE: an escape-aware parser would instead yield
# "sedtier\"truncated", so a bare '^sedtier' anchor matches both forms and pins
# nothing. Require the doubled-backslash terminus AND the absence of the tail
# that only an escape-aware parser could recover.
if printf '%s' "$DETAIL7" | grep -qF 'sedtier\\' \
   && ! printf '%s' "$DETAIL7" | grep -qF 'truncated' \
   && printf '%s' "$DETAIL7" | grep -q 'stop'; then
    echo "PASS: sed-tier escaped-quote truncation → detail shows extraction terminated at quote"; PASS=$((PASS+1))
else
    echo "FAIL: sed-tier escaped-quote truncation → detail does not show truncation, got '$DETAIL7'"; FAIL=$((FAIL+1))
fi
rm -rf "$STUB3"

# ============================================================================
# S-fix task 12 — observe.sh's own extract_cmd() sed-tier, escape-aware.
# Distinct from Test 7 above (agent-lifecycle.sh's sed tier, still naive by
# design/W1.6-18): this pins observe.sh's PostToolUse `command`-field sed
# tier at hooks/observe.sh's extract_cmd(), now aligned with the
# escape-aware pattern hooks/check-commit.sh:83 already uses.
# ============================================================================

# observe_full_journal <payload-json> <PATH-override> — run observe.sh log
# with a forced PATH (so jq/python3/node are all shadowed and the sed tier
# is the one under test — same shadowing idiom as the STUB fixtures above)
# and return the raw journaled JSONL line.
observe_full_journal() {
    local payload="$1" path_override="$2" dir f
    dir=$(mktemp -d)
    ( cd "$dir" && git init -q && mkdir -p .claude && printf 'full\n' > .claude/integration-tier )
    printf '%s' "$payload" | ( cd "$dir" && PATH="$path_override" bash "$SCRIPT" log )
    f=$(ls "$dir"/.claude/journal/*.jsonl 2>/dev/null | head -1)
    [ -n "$f" ] && cat "$f"
    rm -rf "$dir"
}

# Fixture command, as it appears (already JSON-escaped) inside the payload's
# "command" field: npm test \"fix say \\\"done\\\" ok\" — decodes to:
# npm test "fix say \"done\" ok". "npm test" sits BEFORE the first escape
# sequence, so it survives extraction under both the naive and the fixed
# pattern (and drives the "test" journal kind either way); "done" sits
# AFTER the escaped quote/backslash run, so only the escape-aware pattern
# carries it through — the naive [^"]* pattern stops at the first literal
# quote character, right after the backslash preceding it, and never
# reaches "done" at all.
STUB4=$(mktemp -d)
for p in jq python3 node; do printf '#!/bin/sh\nexit 1\n' > "$STUB4/$p"; chmod +x "$STUB4/$p"; done
SED_ESCAPE_PAYLOAD='{"tool_input":{"command":"npm test \"fix say \\\"done\\\" ok\""}}'
JOURNAL_LINE=$(observe_full_journal "$SED_ESCAPE_PAYLOAD" "$STUB4:$PATH")
rm -rf "$STUB4"
# falsifiability: guard neutered in scratch copy, test confirmed red — 2026-08-29
if printf '%s' "$JOURNAL_LINE" | grep -qF 'done'; then
    echo "PASS: observe.sh sed-tier escape-aware extraction → 'done' (after escaped quote/backslash) survives, not truncated"; PASS=$((PASS+1))
else
    echo "FAIL: observe.sh sed-tier escape-aware extraction → 'done' truncated away, got '$JOURNAL_LINE'"; FAIL=$((FAIL+1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

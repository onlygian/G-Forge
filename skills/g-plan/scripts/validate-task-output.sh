#!/bin/bash
# validate-task-output.sh — deterministic half of /g-plan Step 2's fallback:
# structural checks (1)-(2) on task-decomposer's on-disk output_file.
#
# Usage: validate-task-output.sh <file>
# Run from the project root. Prints KEY: value lines; always exits 0.
#
# Check (3) — the content plausibly describes THIS request — is model judgment
# and lives in ../references/decomposer-fallback.md (load it whenever this
# script runs). A structural-pass here is necessary, never sufficient.
#
# The table-header literal below is the contract with agents/task-decomposer.md
# ('## Task List' section + '| # | Task | Files | Done condition |' header) —
# byte-identical, never paraphrased.
#
# Output contract:
#   FILE: exists|missing|empty
#   HEADER: ok|missing
#   VERDICT: structural-pass|failed
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

F="${1:-}"
if [ -z "$F" ] || [ ! -f "$F" ]; then
    out "FILE: missing"; out "HEADER: missing"; out "VERDICT: failed"; exit 0
fi
if [ ! -s "$F" ]; then
    out "FILE: empty"; out "HEADER: missing"; out "VERDICT: failed"; exit 0
fi
out "FILE: exists"
if grep -qF '## Task List' "$F" && grep -qF '| # | Task | Files | Done condition |' "$F"; then
    out "HEADER: ok"
    out "VERDICT: structural-pass"
else
    out "HEADER: missing"
    out "VERDICT: failed"
fi
exit 0

#!/bin/bash
# telemetry-profile.sh — deterministic implementation of /g-execute Step 0
# (read + normalize the telemetry profile, print the dispatch adjustments).
#
# Usage: telemetry-profile.sh          (no args; run from the project root)
# Prints KEY: value lines for the skill to interpret; always exits 0.
# Fails OPEN to `stable`: a missing, unreadable, or malformed
# .claude/telemetry-profile must never serialize waves by accident.
#
# MODEL_BUMP is a per-lane BOUND (v2.6 model economy, specs/model-economy §4):
# defensive bumps the judgment/diagnostic/spec-executor lanes one tier;
# recovery bumps all non-mechanical lanes one tier; the mechanical lane
# (refactor-executor, test-writer, doc-writer, pr-writer)
# never inflates to opus — under recovery it bumps haiku→sonnet at most. A
# failed mechanical task escalates via the tier-gate/FAILED loop, never via
# profile inflation.
#
# The two CLAUSE literals are appended verbatim to agent prompts — byte-frozen.
#
# Output contract:
#   PROFILE: stable|cautious|defensive|recovery
#   WAVE_CAP: none|3|1
#   MODEL_BUMP: none
#             | one-tier — judgment/diagnostic/spec-executor lanes; mechanical lane no bump
#             | one-tier — non-mechanical lanes; mechanical haiku-to-sonnet at most
#   CLAUSE: none | <exact clause literal to append to every agent prompt>
#   NOTE: <text>          0+ human-readable notes
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

RAW=""
[ -f .claude/telemetry-profile ] && RAW=$(cat .claude/telemetry-profile 2>/dev/null)
PROFILE=$(printf '%s' "$RAW" | tr -d '[:space:]')
case "$PROFILE" in
    stable|cautious|defensive|recovery) : ;;
    *) PROFILE=stable ;;
esac

out "PROFILE: $PROFILE"
case "$PROFILE" in
    stable)
        out "WAVE_CAP: none"
        out "MODEL_BUMP: none"
        out "CLAUSE: none"
        ;;
    cautious)
        out "WAVE_CAP: none"
        out "MODEL_BUMP: none"
        out "CLAUSE: none"
        out "NOTE: cautious — /g-review reviewer adjustment not wired as shipped (skills/g-review/SKILL.md Step 0 note)"
        ;;
    defensive)
        out "WAVE_CAP: 3"
        out "MODEL_BUMP: one-tier — judgment/diagnostic/spec-executor lanes; mechanical lane no bump"
        out "CLAUSE: Telemetry profile: defensive. Be extra strict about scope boundaries."
        ;;
    recovery)
        out "WAVE_CAP: 1"
        out "MODEL_BUMP: one-tier — non-mechanical lanes; mechanical haiku-to-sonnet at most"
        out "CLAUSE: Telemetry profile: recovery. Verify every file path before writing. Surface uncertainty immediately."
        ;;
esac
exit 0

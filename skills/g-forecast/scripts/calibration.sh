#!/bin/bash
# calibration.sh — deterministic implementation of /g-forecast Step 5b
# (forecast-outcome corpus parsing, confirm/discard rule, mitigation-held
# half-credit, N/M counting, hit_rate + calibration_adjustment arithmetic,
# sample floor) plus cold-start detection (Step 3's no-signal condition).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. Rationale for each rule (confirmed-legacy, half-credit
# limitation, neutral midpoint, rounding visibility) lives in
# ../references/calibration-notes.md.
# Cross-ref: /g-retro writes the cells this script parses — its
# "## Step 4 — Forecast outcome reconciliation" block (branch-slug keyed,
# retro-time; formerly skills/g-retro/SKILL.md:49-59) defines the verdict
# phrase + one-word evidence tag format (formerly :58) that /g-forecast
# Step 5b reads verbatim. Markdown emphasis (**) around cells is tolerated.
#
# Output contract:
#   OUTCOME: file=<f> row=<n> verdict=<v> tag=<t> credit=<c>[ mitigation-held]
#       one line per parsed non-blank Outcome-table row, in file order.
#       verdict: happened|happened-variant|yes|did-not-happen|no|partial
#                |unverified (the bare-cell form)
#       tag: journal|git|pass|none|unverified — "pass" is any other
#            parenthesized pass-reference (e.g. "Pass 1", "retro 2026-08-22",
#            "review record r1", "attestation"), accepted per the SKILL's
#            "or explicit pass-reference" arm, never a hardcoded whitelist
#       credit: 1|0.5|0 — a tag=unverified (or bare-unverified) row is
#            DISCARDED: printed for visibility but never counted in N
#       mitigation-held suffix: the Notes cell begins with the literal
#            PREFIX "mitigation-held:" on a did-not-happen/no verdict —
#            credited 0.5 and counted in M. Prefix only, never substring
#            (a "mitigation-held" mid-text elsewhere must not match), and
#            only the Notes column is consulted.
#       Blank or placeholder ("[yes / no / partial]") cells carry no signal
#       and print nothing. Rows in tables other than "## Outcome" are
#       never parsed.
#   NOTE: <text>          0+ — e.g. an unparsed outcome cell
#   N: <n>                confirmed rows (discard rule applied first)
#   M: <m>                mitigation-credited rows within N
#   HIT_RATE: 0.xx        printed only when N >= 5
#   CALIBRATION: <A>      round((hit_rate - 0.5) * 20) clamped to [-10, 10]
#            | 0 (floor-not-met N=<n>)   when N < 5
#   COLD_START: yes|no    yes = retros empty/missing AND
#            g-docs/patterns-deferred.md missing AND no rework markers
#            (revert:, fix-of-fix, take 2, retry) in git log --oneline -50
set -u
LC_ALL=C

FILES=$(ls g-docs/forecasts/*.md 2>/dev/null)

if [ -n "$FILES" ]; then
    # shellcheck disable=SC2086
    awk '
    function trim(s)  { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function strip(s) { gsub(/\*\*/, "", s); return trim(s) }
    FNR == 1 { in_outcome = 0; rownum = 0 }
    /^## /   { in_outcome = ($0 ~ /^## Outcome/) ? 1 : 0; next }
    in_outcome && /^\|/ {
        if ($0 ~ /Actually happened/) next        # header row
        if ($0 ~ /^\|[ \t:|-]+$/) next            # separator row
        n = split($0, c, "|")
        while (n > 4 && trim(c[n]) == "") n--     # drop trailing empty field
        actually = strip(c[4])
        notes = ""
        for (i = 5; i <= n; i++) notes = notes (i > 5 ? "|" : "") c[i]
        notes = strip(notes)
        rownum++
        if (actually == "" || actually ~ /^\[/) next   # blank/placeholder — no signal
        low = tolower(actually)
        verdict = ""
        if      (low ~ /^did not happen/)         verdict = "did-not-happen"
        else if (low ~ /^no($|[^a-z])/)           verdict = "no"
        else if (low ~ /^partial/)                verdict = "partial"
        else if (low ~ /^happened[^(]*variant/)   verdict = "happened-variant"
        else if (low ~ /^happened/)               verdict = "happened"
        else if (low ~ /^yes/)                    verdict = "yes"
        else if (low ~ /^unverified/)             verdict = "unverified"
        else {
            printf "NOTE: unparsed outcome cell — %s row %d\n", FILENAME, rownum
            next
        }
        tag = "none"
        if (match(actually, /\([^)]*\)/)) {
            t = tolower(substr(actually, RSTART + 1, RLENGTH - 2))
            if      (t == "journal")    tag = "journal"
            else if (t == "git")        tag = "git"
            else if (t == "unverified") tag = "unverified"
            else                        tag = "pass"
        }
        if (verdict == "unverified") tag = "unverified"
        credit = "0"; held = 0
        if (verdict == "happened" || verdict == "happened-variant" || verdict == "yes")
            credit = "1"
        else if (verdict == "partial")
            credit = "0.5"
        else if (verdict == "did-not-happen" || verdict == "no") {
            if (notes ~ /^mitigation-held:/) { credit = "0.5"; held = 1 }
        }
        printf "OUTCOME: file=%s row=%d verdict=%s tag=%s credit=%s%s\n", \
               FILENAME, rownum, verdict, tag, credit, (held ? " mitigation-held" : "")
        if (tag == "unverified") next             # DISCARDED — not counted in N
        N++; SUM += credit + 0
        if (held) M++
    }
    END {
        printf "N: %d\n", N + 0
        printf "M: %d\n", M + 0
        if (N + 0 >= 5) {
            hr = SUM / N
            printf "HIT_RATE: %.2f\n", hr
            dev = (hr - 0.5) * 20
            adj = int(dev + (dev < 0 ? -0.5 : 0.5))
            if (adj > 10)  adj = 10
            if (adj < -10) adj = -10
            printf "CALIBRATION: %d\n", adj
        } else {
            printf "CALIBRATION: 0 (floor-not-met N=%d)\n", N + 0
        }
    }' $FILES
else
    echo "N: 0"
    echo "M: 0"
    echo "CALIBRATION: 0 (floor-not-met N=0)"
fi

# Cold-start detection — Step 3 finding no signals at all (independent of the
# N<5 floor above; a plan can hit either, both, or neither).
COLD=no
RETRO_N=$(ls g-docs/retros/*.md 2>/dev/null | grep -c .)
if [ "$RETRO_N" -eq 0 ] && [ ! -f g-docs/patterns-deferred.md ]; then
    if ! git log --oneline -50 2>/dev/null | grep -qiE 'revert:|fix-of-fix|take 2|retry'; then
        COLD=yes
    fi
fi
echo "COLD_START: $COLD"
exit 0

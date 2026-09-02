#!/bin/bash
# forecast-calc.sh — deterministic arithmetic for /g-forecast Steps 2b, 2c
# and 6 (blast-radius adjustment, token-cost band, miss_risk formula).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. Formula-tuning rationale lives in ../references/scoring-notes.md;
# the cold-start treatment in ../references/cold-start.md.
# The Narrow +0 / Moderate +1 / Wide +2 blast mapping is a deliberate
# parity copy of skills/g-blast-radius/SKILL.md Step 7's statement — keep
# the two in sync, never dedup.
#
# Modes and output contracts:
#   tokens --tasks N --files F
#       agent_dispatches = N (sum of task counts over waves)
#       total = N*4000 + (F*80)*4 + 6000 + 2000*N   (80 lines/file = the
#               historical median; review overhead = 6000 base + 2000/agent)
#       low = total*0.6, high = total*1.8, both rounded to nearest 1k
#       -> TOKENS: low=<k> high=<k> tag=<Small|Medium|Large|Very Large — consider re-scoping>
#          tag by high estimate: <50k Small; 50-200k Medium; 200-800k Large;
#          >800k Very Large — consider re-scoping
#   score --complexity X --scenario-scores a,b,c --calibration A [--blast narrow|moderate|wide]
#       blast: narrow/absent +0, moderate +1, wide +2, re-clamped to 0-10
#       -> COMPLEXITY_ADJ: <0-10>
#       contribution = sum over first 3 scores of min(score,15) * 1.5
#       raw = 10 + complexity*3 + contribution        (no upper bound)
#       -> RAW: <n>              unrounded, unclamped
#       -> RAW_DISPLAY: <n>|>=100   display clamp [0,100]; ">=100" is the
#          saturation marker — a genuinely-computed 100 and a clamped
#          triple-digit score never read the same
#       miss_risk = clamp(0, 95, raw + calibration), THEN rounded to the
#       nearest 5 — once, at the end, never on raw alone
#       -> MISS_RISK: <p>
#       -> TAG: Low|Moderate|Elevated|High   (0-25 / 26-50 / 51-75 / 76-95)
#   cold --complexity X [--blast narrow|moderate|wide]
#       blast: same narrow/absent +0, moderate +1, wide +2 mapping as score
#       mode, re-clamped to 0-10 — HEAD parity: Step 2b adjusted the
#       complexity score BEFORE any formula ran, cold-start included
#       -> COMPLEXITY_ADJ: <0-10>
#       miss_risk_cold = clamp(15, 60, 15 + complexity_adj*3); no calibration
#       -> MISS_RISK: <p>
#       -> MODE: cold-start
set -u
LC_ALL=C

MODE="${1:-}"
[ $# -gt 0 ] && shift

case "$MODE" in
tokens)
    TASKS=0; FILES=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --tasks) TASKS="${2:-0}"; shift 2 ;;
            --files) FILES="${2:-0}"; shift 2 ;;
            *) shift ;;
        esac
    done
    awk -v t="$TASKS" -v f="$FILES" 'BEGIN {
        total = t*4000 + f*80*4 + 6000 + 2000*t
        low = total*0.6; high = total*1.8
        lowk = int(low/1000 + 0.5); highk = int(high/1000 + 0.5)
        if      (high < 50000)   tag = "Small"
        else if (high <= 200000) tag = "Medium"
        else if (high <= 800000) tag = "Large"
        else                     tag = "Very Large — consider re-scoping"
        printf "TOKENS: low=%dk high=%dk tag=%s\n", lowk, highk, tag
    }'
    ;;
score)
    COMPLEX=0; SCORES=""; CAL=0; BLAST=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --complexity)      COMPLEX="${2:-0}"; shift 2 ;;
            --scenario-scores) SCORES="${2:-}";   shift 2 ;;
            --calibration)     CAL="${2:-0}";     shift 2 ;;
            --blast)           BLAST="${2:-}";    shift 2 ;;
            *) shift ;;
        esac
    done
    awk -v cx="$COMPLEX" -v ss="$SCORES" -v cal="$CAL" -v blast="$BLAST" '
    function fmt(x) { return (x == int(x)) ? sprintf("%d", x) : sprintf("%.1f", x) }
    BEGIN {
        b = 0
        if (blast == "moderate") b = 1
        else if (blast == "wide") b = 2      # narrow / absent = +0
        cx = cx + b
        if (cx > 10) cx = 10
        if (cx < 0)  cx = 0
        printf "COMPLEXITY_ADJ: %d\n", cx
        n = split(ss, a, ","); contrib = 0
        for (i = 1; i <= n && i <= 3; i++) {
            s = a[i] + 0
            if (s > 15) s = 15                # per-scenario cap: min(score,15)*1.5
            contrib += s * 1.5
        }
        raw = 10 + cx*3 + contrib
        printf "RAW: %s\n", fmt(raw)
        if (raw > 100) print "RAW_DISPLAY: >=100"
        else { d = raw; if (d < 0) d = 0; printf "RAW_DISPLAY: %s\n", fmt(d) }
        miss = raw + cal
        if (miss > 95) miss = 95
        if (miss < 0)  miss = 0
        miss = int(miss/5 + 0.5) * 5          # round once, at the end
        printf "MISS_RISK: %d\n", miss
        if      (miss <= 25) tag = "Low"
        else if (miss <= 50) tag = "Moderate"
        else if (miss <= 75) tag = "Elevated"
        else                 tag = "High"
        printf "TAG: %s\n", tag
    }'
    ;;
cold)
    COMPLEX=0; BLAST=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --complexity) COMPLEX="${2:-0}"; shift 2 ;;
            --blast)      BLAST="${2:-}";    shift 2 ;;
            *) shift ;;
        esac
    done
    awk -v cx="$COMPLEX" -v blast="$BLAST" 'BEGIN {
        b = 0
        if (blast == "moderate") b = 1
        else if (blast == "wide") b = 2      # narrow / absent = +0
        cx = cx + b
        if (cx > 10) cx = 10
        if (cx < 0)  cx = 0
        printf "COMPLEXITY_ADJ: %d\n", cx
        m = 15 + cx*3
        if (m < 15) m = 15
        if (m > 60) m = 60
        printf "MISS_RISK: %d\n", m
        print "MODE: cold-start"
    }'
    ;;
*)
    echo "NOTE: unknown mode '$MODE' — expected tokens|score|cold"
    ;;
esac
exit 0

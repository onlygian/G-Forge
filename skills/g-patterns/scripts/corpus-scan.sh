#!/bin/bash
# corpus-scan.sh — deterministic implementation of /g-patterns Step 2's
# corpus-too-thin gate, Step 3c's git-log rework extraction, and Step 3d's
# forecast-outcome signal extraction.
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. Step 3b (todo-done duplicate-title / repeated-file-target
# detection) and the "unstructured — skipped" judgment stay model-side.
#
# The rework MARKER SET below is a closed set, byte-identical to the prose
# it replaced and deliberately mirrored in hooks/workflow-checkpoint.sh's
# rework-count regex (comment near its milestone-health block) — keep the
# two in sync, never dedup: case-insensitive
#   ^revert:  ^fix-of-fix  take 2  retry  another attempt  ^revert "  re-do
#
# Step 3c has TWO detection branches (both from the prose it replaced):
#   (1) subject markers — the closed set above;
#   (2) same-branch reverts within a 20-commit window — a commit whose body
#       carries git's "This reverts commit <sha>" trailer, where the
#       reverted commit sits at most 20 positions older in the same
#       -100 log window (same branch by construction). Catches manual
#       reverts whose subject carries no marker; commits already matched
#       by branch (1) are never re-emitted.
#
# Output contract:
#   RETROS: N                 .md files in g-docs/retros/ (0 if missing)
#   TODO_DONE: present|missing
#   FORECASTS: N              .md files in g-docs/forecasts/
#   GIT_COMMITS: N            lines of git log --oneline -100 (0 outside git)
#   CORPUS: ok|partial|thin   thin = retros empty/missing AND todo-done
#           missing AND <10 commits (the skill prints its stop block);
#           partial = retros empty/missing but another source present
#   REWORK: <sha> <subject>   0+ — commit subjects matching the marker set,
#           or same-branch reverts per branch (2); each commit at most once
#   FORECAST_SIGNAL: file=<f> scenario="<label>" outcome=yes|partial weight=2|1
#       0+ — filled Outcome-table rows: yes/happened = weight 2 (predicted
#       AND observed), partial = weight 1; "no" rows are negative evidence,
#       discarded; a blank Actually-happened? cell is no signal (matches
#       /g-forecast Step 5b doctrine). The label is resolved from the same
#       file's Premortem table by rank (truncated to 60 chars); "row<rank>"
#       when unmatched. Only "## Outcome" tables are parsed.
set -u
LC_ALL=C

RETROS=$(ls g-docs/retros/*.md 2>/dev/null | grep -c .)
echo "RETROS: $RETROS"
if [ -f g-docs/todo-done.md ]; then TODO=present; else TODO=missing; fi
echo "TODO_DONE: $TODO"
FORECAST_FILES=$(ls g-docs/forecasts/*.md 2>/dev/null)
FORECASTS=$(printf '%s' "$FORECAST_FILES" | grep -c .)
echo "FORECASTS: $FORECASTS"
GITLOG=$(git log --oneline -100 2>/dev/null)
COMMITS=$(printf '%s' "$GITLOG" | grep -c .)
echo "GIT_COMMITS: $COMMITS"

if [ "$RETROS" -eq 0 ] && [ "$TODO" = missing ] && [ "$COMMITS" -lt 10 ]; then
    echo "CORPUS: thin"
elif [ "$RETROS" -eq 0 ]; then
    echo "CORPUS: partial"
else
    echo "CORPUS: ok"
fi

# Step 3c branch (1) — rework commit markers (closed set; see header).
MARKER_RE='^revert:|^fix-of-fix|take 2|retry|another attempt|^revert "|re-do'
if [ "$COMMITS" -gt 0 ]; then
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        sha=${line%% *}
        subject=${line#* }
        if printf '%s\n' "$subject" | grep -qiE "$MARKER_RE"; then
            echo "REWORK: $sha $subject"
        fi
    done <<EOF
$GITLOG
EOF
fi

# Step 3c branch (2) — same-branch reverts within a 20-commit window (see
# header). awk builds sha→position over the same -100 window, then emits a
# revert whose "This reverts commit <sha>" target is ≤20 positions older;
# the bash filter drops subjects branch (1) already emitted.
if [ "$COMMITS" -gt 0 ]; then
    git log -100 --format='%x01%h %H %s%x02%b' 2>/dev/null \
    | awk 'BEGIN { RS = "\x01"; np = 0 }
    NR > 1 {
        i = index($0, "\x02")
        header = (i > 0) ? substr($0, 1, i - 1) : $0
        body   = (i > 0) ? substr($0, i + 1)    : ""
        np++
        split(header, w, " ")
        short[np] = w[1]
        fullpos[w[2]] = np
        subject = header
        sub(/^[^ ]+ [^ ]+ ?/, "", subject)
        subj[np] = subject
        if (match(body, /This reverts commit [0-9a-f]+/))
            revsha[np] = substr(body, RSTART + 20, RLENGTH - 20)
    }
    END {
        for (p = 1; p <= np; p++) {
            if (!(p in revsha)) continue
            q = 0
            if (revsha[p] in fullpos) q = fullpos[revsha[p]]
            else for (f in fullpos)
                if (index(f, revsha[p]) == 1) { q = fullpos[f]; break }
            if (q > p && q - p <= 20)
                printf "%s %s\n", short[p], subj[p]
        }
    }' \
    | while IFS= read -r line; do
        [ -n "$line" ] || continue
        subject=${line#* }
        # dedup: branch (1) already emitted marker-matched subjects
        printf '%s\n' "$subject" | grep -qiE "$MARKER_RE" && continue
        echo "REWORK: $line"
    done
fi

# Step 3d — forecast-outcome signals.
if [ "$FORECASTS" -gt 0 ]; then
    # shellcheck disable=SC2086
    awk '
    function trim(s)  { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function strip(s) { gsub(/\*\*/, "", s); return trim(s) }
    FNR == 1 { sect = ""; delete label }
    /^## Premortem scenarios/ { sect = "prem"; next }
    /^## Outcome/             { sect = "out";  next }
    /^## /                    { sect = "";     next }
    sect == "prem" && /^\|/ {
        if ($0 ~ /Scenario/ && $0 ~ /Likelihood/) next
        if ($0 ~ /^\|[ \t:|-]+$/) next
        split($0, c, "|")
        r = trim(c[2]); s = strip(c[3])
        gsub(/"/, "\x27", s)
        if (r ~ /^[0-9]+$/) {
            if (length(s) > 60) s = substr(s, 1, 60)
            label[r] = s
        }
    }
    sect == "out" && /^\|/ {
        if ($0 ~ /Actually happened/) next
        if ($0 ~ /^\|[ \t:|-]+$/) next
        split($0, c, "|")
        rank = trim(c[2]); actually = strip(c[4])
        if (actually == "" || actually ~ /^\[/) next   # blank/placeholder — no signal
        low = tolower(actually)
        if      (low ~ /^partial/)                       { out = "partial"; w = 1 }
        else if (low ~ /^did not happen/)                next
        else if (low ~ /^no($|[^a-z])/)                  next
        else if (low ~ /^unverified/)                    next
        else if (low ~ /^happened/ || low ~ /^yes/)      { out = "yes"; w = 2 }
        else next
        lb = (rank in label) ? label[rank] : "row" rank
        printf "FORECAST_SIGNAL: file=%s scenario=\"%s\" outcome=%s weight=%d\n", \
               FILENAME, lb, out, w
    }' $FORECAST_FILES
fi
exit 0

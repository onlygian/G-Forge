#!/bin/bash
# inbox-scan.sh — deterministic listing half of /g-patterns Step 12
# (adversarial-inbox enumeration, sizing, ordering, display sanitization).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the
# exit code. This script only LISTS, SORTS and MEASURES: the mechanical
# ingress screen itself is contractually IN-MODEL (the SKILL mandates
# "never shell out, never eval") and must never move here. Window-slot
# fill and quarantine decisions stay model-side over these ordered rows.
#
# Two CLOSED-SET charsets, one character apart — the difference is
# contractual, keep both exact:
#   display sanitization  [A-Za-z0-9._/-]  (what is safe to PRINT; wider)
#   portable-name test    [A-Za-z0-9._-]   (what a producer may MINT; no "/")
#
# Output contract:
#   INBOX: missing|empty|N    N = regular files (ANY extension, or none;
#                             never globbed by extension)
#   FILE: idx=<n> name=<sanitized> portable=yes|no oversize=yes|no size=<bytes> mtime=<epoch>
#       one line per regular file, most-recent-first (mtime order).
#       sanitized: truncate to 80 chars, strip to [A-Za-z0-9._/-];
#                  empty after stripping -> "file #N" (N = idx)
#       portable:  name consists only of [A-Za-z0-9._-]
#       oversize:  size > 51200 bytes (50KB) — the skill skips it entirely,
#                  never reads it, and it never counts against the window
set -u
LC_ALL=C

DIR=g-docs/inbox/adversarial
if [ ! -d "$DIR" ]; then
    echo "INBOX: missing"
    exit 0
fi

names=(); epochs=(); sizes=()
for f in "$DIR"/* "$DIR"/.[!.]* "$DIR"/..?*; do
    [ -f "$f" ] || continue
    e=$(stat -c %Y "$f" 2>/dev/null) || e=$(stat -f %m "$f" 2>/dev/null) || e=0
    s=$(wc -c < "$f" 2>/dev/null) || s=0
    names+=("$f"); epochs+=("$e"); sizes+=("$s")
done

count=${#names[@]}
if [ "$count" -eq 0 ]; then
    echo "INBOX: empty"
    exit 0
fi
echo "INBOX: $count"

order=$(for i in "${!names[@]}"; do printf '%s %s\n' "${epochs[$i]}" "$i"; done \
        | sort -rn -k1,1 | awk '{print $2}')

idx=0
for i in $order; do
    idx=$((idx+1))
    base=$(basename "${names[$i]}")
    san=$(printf '%s' "$base" | cut -c1-80 | tr -cd 'A-Za-z0-9._/-')
    [ -n "$san" ] || san="file #$idx"
    case "$base" in
        *[!A-Za-z0-9._-]*) portable=no ;;
        *)                 portable=yes ;;
    esac
    size=$(printf '%s' "${sizes[$i]}" | tr -d ' \t')
    if [ "$size" -gt 51200 ] 2>/dev/null; then oversize=yes; else oversize=no; fi
    echo "FILE: idx=$idx name=$san portable=$portable oversize=$oversize size=$size mtime=${epochs[$i]}"
done
exit 0

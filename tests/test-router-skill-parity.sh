#!/bin/bash
# Unit tests for router <-> skills directory bidirectional parity (audit-7 H5),
# extended to the router's other two token surfaces (F3-11).
#
# Verifies: the bare subcommand tokens listed in commands/g-forge.md's routing
# list, frontmatter `description:` subcommand list, and `argument-hint` list
# all maintain bidirectional parity with the skills/ directory structure AND
# with each other. Every router token must map to an existing
# skills/g-<token>/SKILL.md, every skills/g-<name>/SKILL.md must have a
# corresponding router token, and the description-list / argument-hint token
# sets must match the routing list exactly -- a token missing from either
# surface leaves a shipped skill unreachable from the command palette even
# though the routing list itself is correct.
#
# Both sides are derived from disk at run time -- never a typed list (ADR-013).
#
# ── Canonical form ─────────────────────────────────────────────────────────────
# The two sides are named differently on disk: the router lists bare tokens
# (`adr`) and the skills tree uses prefixed directories (`g-adr`). Comparing
# them requires a normalization step, and the two previous versions of this
# suite each got that step wrong in a way that surfaced as a *bogus parity
# mismatch* rather than as an extraction bug:
#   - v1 compared bare tokens against directory names (no g- prefix at all);
#   - v2 added the prefix but its extractor captured the token *with* its
#     literal backticks, yielding `g-\`adr\`` -- router lines are formatted
#     ``- `adr`  -> `skills/g-adr/SKILL.md```, not bare words.
#
# So this suite pins ONE canonical form -- `g-<token>`, characters [a-z0-9-]
# only -- and pushes BOTH derived sets through the same canonicalize() before
# any comparison. It then asserts the shape of both canonicalized sets up
# front. An extraction bug now fails at extraction, loudly, printing the
# offending element -- it can no longer masquerade as a parity failure.
#
# Two self-checks guard the token/skills-dir extractors:
#   1. Coverage  -- every routing line (ROUTER_LINE_RE) yields exactly one
#                   token. A routing line the parser cannot read is a hard
#                   failure, not a silently-dropped token that reads as
#                   "skills-only".
#   2. Shape     -- every element of both sets matches ^g-[a-z0-9-]+$ and
#                   neither set is empty.
#
# Parity itself is a bidirectional comm diff over the canonicalized sets.
#
# A third check runs independently of parity: every routing line's SECOND
# backticked field (the target path) must equal the canonical
# skills/g-<token>/SKILL.md implied by its OWN first field (the token). Token
# and target are extracted together, through the same sed pass
# (extract_router_fields), so a target-path bug cannot hide behind a token
# that still happens to resolve -- the token is a label, the target is what
# actually gets Read at dispatch.
#
# Scope note: skills are enumerated with a shell glob over skills/*/SKILL.md
# (not `find`), which is exactly the layout the architecture profile defines.
# A nested skills/g-foo/sub/SKILL.md is deliberately not a skill. The glob also
# sidesteps Windows' find.exe shadowing /usr/bin/find on a stray PATH.
#
# Coverage: this suite pins THREE token surfaces against each other and
# against skills/ -- the routing list (the `- `token` -> `target`` lines),
# the frontmatter `description:` subcommand token list, and the
# `argument-hint` pipe-separated token list. A token present on one surface
# and missing from another is a parity failure, named in the FAIL message
# (F3-11: g-skill-design previously registered only the routing-list line,
# which left new skills unreachable from the router's description-list and
# argument-hint surfaces without failing any test).
#
# Assertion groups: extraction-helper definitions, router-line extraction
# coverage, canonical-shape self-check, real-files parity (token/skills-dir,
# target-path, description-list, argument-hint), and synthetic-fixture
# detection proving each parity/integrity check actually goes red on a real
# mismatch (router-only, skills-only, target-path, description-list-missing,
# argument-hint-missing). See the Results line at the end of a run for the
# current total -- not restated here as a fixed number (an unpinned count is
# a review finding, G-RULES §G/ADR-013).

# Byte collation for sort/comm, and fixed character classes for sed/grep.
# sort and comm MUST agree on ordering or comm silently mis-diffs.
export LC_ALL=C

PASS=0
FAIL=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SUITE_TMP="$(mktemp -d)" || { echo "FAIL: mktemp -d failed"; exit 1; }
trap 'rm -rf "$SUITE_TMP"' EXIT

# ── Canonical form ─────────────────────────────────────────────────────────────

# The one shape both derived sets must reduce to before any comparison.
CANONICAL_RE='^g-[a-z0-9-]+$'

# Predicate identifying a routing line in the router file. Textually IDENTICAL
# to the anchor the extractor's own sed pattern requires below (dash, optional
# spaces, opening backtick) -- not just similarly-shaped -- so the coverage
# self-check and the extractor can never disagree about what counts as a
# routing line. (Previously this was the looser '^- ', which also matched
# non-routing "- " lines the extractor would never parse, misdiagnosing them
# as parser breakage instead of correctly excluding them.) Kept as a literal
# copy rather than interpolated into the sed script below: embedding a
# backtick-bearing variable inside a double-quoted sed script risks tripping
# shell command substitution on the unescaped backtick.
ROUTER_LINE_RE='^- *`'

# ── Extraction helpers ─────────────────────────────────────────────────────────

# Capture BOTH backtick-delimited fields of every routing line -- the token
# AND the target path -- in a single sed pass, so token and target extraction
# can never drift out of sync with each other (the v1/v2 failure class this
# suite's header documents, extended to the target field per R-18).
# Real line: - `blast-radius` -> `skills/g-blast-radius/SKILL.md`  (args...)
# Output: one "token<TAB>target" line per routing line. TAB is not a legal
# character in either backticked field, so it's a safe separator.
# Capture is PERMISSIVE ([^`]* rather than [a-z0-9-]*) on purpose: a malformed
# token or target must survive into the set so the shape/target self-checks
# can print it, instead of being dropped here and reappearing later as a
# phantom parity mismatch.
extract_router_fields() {
    local file="$1"
    sed -n 's/^- *`\([^`]*\)`[^`]*`\([^`]*\)`.*/\1\t\2/p' "$file"
}

# Token-only view, derived from extract_router_fields -- never a second,
# independently-written parse of the router line format.
extract_router_tokens() {
    extract_router_fields "$1" | cut -f1
}

# Bare token set from the frontmatter `description:` line's "Subcommands —
# a, b, c." clause (F3-11). Trailing [[:space:]]* before $ absorbs a stray CR
# on a CRLF checkout, same as canonicalize() does downstream for every other
# extractor here. Per-token trim is done HERE, not left to canonicalize():
# the list is comma-SPACE separated ("help, status"), so splitting on `,`
# alone leaves a leading space baked into every token but the first --
# add_g_prefix would then turn it into "g- status" (space stuck mid-token,
# past where canonicalize()'s ^/$ trim can reach it).
extract_description_tokens() {
    local file="$1"
    sed -n 's/^description:.*Subcommands — \(.*\)\.[[:space:]]*$/\1/p' "$file" \
        | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# Bare token set from the frontmatter `argument-hint` line's `<a|b|c>` clause
# (F3-11). The trailing `.*` swallows " [args]" and any CR.
extract_arghint_tokens() {
    local file="$1"
    sed -n 's/^argument-hint: <\(.*\)>.*/\1/p' "$file" | tr '|' '\n'
}

# Count the routing lines the extractor is expected to cover.
# Always prints an integer: a missing/unreadable router file yields 0, which
# fails the coverage assertion cleanly instead of feeding "" into [ -gt ].
count_router_lines() {
    local file="$1"
    local n
    n=$(grep -c "$ROUTER_LINE_RE" "$file" 2>/dev/null)
    case "$n" in
        ''|*[!0-9]*) printf '0\n' ;;
        *)           printf '%s\n' "$n" ;;
    esac
}

# Bare router token -> canonical namespace. The skills side is already
# g-prefixed on disk, so only the router side needs this.
add_g_prefix() {
    sed 's/^/g-/'
}

# Enumerate skill directory names from a skills tree: skills/g-help/SKILL.md
# yields g-help. Already canonical by construction -- but still validated,
# because "already canonical" is an assumption, not a guarantee.
extract_skill_dirs() {
    local skills_dir="$1"
    local d
    for d in "$skills_dir"/*/; do
        [ -f "$d/SKILL.md" ] || continue
        d="${d%/}"
        printf '%s\n' "${d##*/}"
    done
}

# THE shared normalizer -- both sets go through this, unmodified.
# Strips CR (CRLF-checked-out sources on Windows), trims surrounding
# whitespace, drops blank lines, sorts. It deliberately does NOT repair or
# filter by shape: malformed elements pass through so shape_offenders() can
# name them.
canonicalize() {
    tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' | sort
}

# Elements of a canonicalized set that are not in canonical form.
shape_offenders() {
    grep -vE "$CANONICAL_RE" "$1"
}

# Routing lines whose target path does NOT match the canonical
# skills/g-<token>/SKILL.md form implied by their OWN token. Reads a
# "token<TAB>target" fields file (extract_router_fields output, CR-stripped).
# Prints "token<TAB>got<TAB>expected" for each offender -- a typo'd target
# (`skills/g-adrr/SKILL.md` for token `adr`) fails here even though the token
# still resolves to a real skills/ directory, which is exactly the R-18 gap:
# the token is a label, the target is what actually gets Read at dispatch.
target_offenders() {
    local fields_file="$1"
    local token target expected
    while IFS="$(printf '\t')" read -r token target; do
        [ -n "$token" ] || continue
        expected="skills/g-${token}/SKILL.md"
        [ "$target" = "$expected" ] || printf '%s\t%s\t%s\n' "$token" "$target" "$expected"
    done < "$fields_file"
}

# Always prints an integer, for the same reason as count_router_lines above.
count_lines() {
    local n
    n=$(wc -l < "$1" 2>/dev/null | tr -d '[:space:]')
    case "$n" in
        ''|*[!0-9]*) printf '0\n' ;;
        *)           printf '%s\n' "$n" ;;
    esac
}

# Bidirectional set equality over two sorted files.
sets_equal() {
    local a="$1" b="$2"
    [ -z "$(comm -23 "$a" "$b")" ] && [ -z "$(comm -13 "$a" "$b")" ]
}

# Derive both canonicalized sets for a (router file, skills dir) pair, plus
# (optionally) the raw token/target fields file used by target_offenders.
# Used by the live check and by all synthetic fixtures, so the synthetic
# scenarios exercise the real parser rather than a simplified stand-in.
derive_sets() {
    local router_file="$1" skills_dir="$2" router_out="$3" skills_out="$4" fields_out="${5:-}"
    extract_router_tokens "$router_file" | add_g_prefix | canonicalize > "$router_out"
    extract_skill_dirs "$skills_dir" | canonicalize > "$skills_out"
    if [ -n "$fields_out" ]; then
        extract_router_fields "$router_file" | tr -d '\r' > "$fields_out"
    fi
}

echo "PASS: extraction helper functions defined"
PASS=$((PASS+1))

# ── Live derivation ────────────────────────────────────────────────────────────

ROUTER_FILE="$REPO_ROOT/commands/g-forge.md"
SKILLS_DIR="$REPO_ROOT/skills"

ROUTER_SET="$SUITE_TMP/live-router.txt"
SKILLS_SET="$SUITE_TMP/live-skills.txt"
ROUTER_FIELDS="$SUITE_TMP/live-router-fields.txt"
DESC_SET="$SUITE_TMP/live-description.txt"
ARGHINT_SET="$SUITE_TMP/live-arghint.txt"

derive_sets "$ROUTER_FILE" "$SKILLS_DIR" "$ROUTER_SET" "$SKILLS_SET" "$ROUTER_FIELDS"

# The description-list and argument-hint token sets go through the SAME
# add_g_prefix + canonicalize normalizer as the routing-list set above, so
# all three land in one comparable canonical form (F3-11).
extract_description_tokens "$ROUTER_FILE" | add_g_prefix | canonicalize > "$DESC_SET"
extract_arghint_tokens "$ROUTER_FILE" | add_g_prefix | canonicalize > "$ARGHINT_SET"

# ── Test 1: extraction coverage — every routing line yields exactly one token ──
#
# Guards the v2 failure class from the other side: if the extractor's regex
# stops matching the router's line format, the token count drops below the
# routing-line count and this fails here, naming the shortfall -- rather than
# the missing tokens showing up downstream as bogus "skills without a router
# token" entries.

ROUTER_LINE_COUNT=$(count_router_lines "$ROUTER_FILE")
ROUTER_TOKEN_COUNT=$(count_lines "$ROUTER_SET")

if [ "$ROUTER_LINE_COUNT" -gt 0 ] && [ "$ROUTER_TOKEN_COUNT" -eq "$ROUTER_LINE_COUNT" ]; then
    echo "PASS: router extraction coverage — all $ROUTER_LINE_COUNT routing lines yielded a token"
    PASS=$((PASS+1))
else
    echo "FAIL: router extraction coverage — $ROUTER_LINE_COUNT routing lines but $ROUTER_TOKEN_COUNT tokens extracted"
    echo "  Extractor regex no longer matches the router's line format in $ROUTER_FILE"
    echo "  First unparsed routing lines:"
    grep -n "$ROUTER_LINE_RE" "$ROUTER_FILE" \
        | grep -vE '^[0-9]+:- *`[^`]*`[^`]*`[^`]*`' \
        | head -5 \
        | sed 's/^/    /'
    FAIL=$((FAIL+1))
fi

# ── Test 2: canonical shape self-check — both derived sets ─────────────────────
#
# Both live sets must be non-empty and every element must be g-<[a-z0-9-]+>.
# This is the assertion the previous two attempts lacked: it turns a
# normalization defect into a named extraction failure at the point of
# extraction, printing the offending element.

SHAPE_ERRORS=""

ROUTER_SET_COUNT=$(count_lines "$ROUTER_SET")
SKILLS_SET_COUNT=$(count_lines "$SKILLS_SET")

[ "$ROUTER_SET_COUNT" -gt 0 ] || SHAPE_ERRORS="${SHAPE_ERRORS}  router set is EMPTY — extraction produced nothing from $ROUTER_FILE"$'\n'
[ "$SKILLS_SET_COUNT" -gt 0 ] || SHAPE_ERRORS="${SHAPE_ERRORS}  skills set is EMPTY — no skills/*/SKILL.md found under $SKILLS_DIR"$'\n'

ROUTER_BAD=$(shape_offenders "$ROUTER_SET")
SKILLS_BAD=$(shape_offenders "$SKILLS_SET")

if [ -n "$ROUTER_BAD" ]; then
    SHAPE_ERRORS="${SHAPE_ERRORS}  router element(s) not in canonical form $CANONICAL_RE:"$'\n'
    SHAPE_ERRORS="${SHAPE_ERRORS}$(printf '%s\n' "$ROUTER_BAD" | head -5 | sed 's/^/    [/; s/$/]/')"$'\n'
fi
if [ -n "$SKILLS_BAD" ]; then
    SHAPE_ERRORS="${SHAPE_ERRORS}  skills element(s) not in canonical form $CANONICAL_RE:"$'\n'
    SHAPE_ERRORS="${SHAPE_ERRORS}$(printf '%s\n' "$SKILLS_BAD" | head -5 | sed 's/^/    [/; s/$/]/')"$'\n'
fi

if [ -z "$SHAPE_ERRORS" ]; then
    echo "PASS: canonical shape self-check — both derived sets non-empty and all elements match $CANONICAL_RE (router $ROUTER_SET_COUNT, skills $SKILLS_SET_COUNT)"
    PASS=$((PASS+1))
else
    echo "FAIL: canonical shape self-check — derived sets are malformed (extraction bug, NOT a parity mismatch)"
    printf '%s' "$SHAPE_ERRORS"
    FAIL=$((FAIL+1))
fi

# ── Test 3: real files parity — router tokens match skills directories ─────────

if sets_equal "$ROUTER_SET" "$SKILLS_SET"; then
    echo "PASS: real files parity — router tokens and skills/ directories match ($ROUTER_SET_COUNT entries each)"
    PASS=$((PASS+1))
else
    ROUTER_ONLY=$(comm -23 "$ROUTER_SET" "$SKILLS_SET" | tr '\n' ',' | sed 's/,$//')
    SKILLS_ONLY=$(comm -13 "$ROUTER_SET" "$SKILLS_SET" | tr '\n' ',' | sed 's/,$//')
    echo "FAIL: real files parity mismatch"
    [ -n "$ROUTER_ONLY" ] && echo "  Router tokens without a skills/ directory: $ROUTER_ONLY"
    [ -n "$SKILLS_ONLY" ] && echo "  Skills directories without a router token: $SKILLS_ONLY"
    FAIL=$((FAIL+1))
fi

# ── Test 4: real files target-path integrity — targets match their own token ───
# falsifiability: target_offenders neutered in scratch copy, test confirmed
# red — 2026-08-21
#
# Guards the R-18 gap: the token/skills-dir parity above only proves the
# TOKEN resolves to a real directory. It says nothing about the TARGET path
# on the same routing line, which is what actually gets Read at dispatch. A
# typo'd target (`- \`adr\` -> \`skills/g-adrr/SKILL.md\``) would pass Test 3
# in full. This asserts every routing line's own target equals
# skills/g-<token>/SKILL.md, derived from that same line's own token.

ROUTER_TARGET_BAD=$(target_offenders "$ROUTER_FIELDS")

if [ -z "$ROUTER_TARGET_BAD" ]; then
    echo "PASS: real files target-path integrity — every routing line's target matches skills/g-<token>/SKILL.md"
    PASS=$((PASS+1))
else
    echo "FAIL: real files target-path integrity — target path diverges from its own token"
    printf '%s\n' "$ROUTER_TARGET_BAD" | head -5 | while IFS="$(printf '\t')" read -r t got exp; do
        echo "  token '$t': got [$got] expected [$exp]"
    done
    FAIL=$((FAIL+1))
fi

# ── Synthetic fixture builder ──────────────────────────────────────────────────
#
# Fixtures are built as REAL trees with REAL router files in the production
# backticked line format, then run through derive_sets() -- the same extractors
# and the same canonicalize() the live check uses. A fixture written in a
# simplified format would let an extractor bug pass the synthetic cases while
# breaking the live one, which is precisely how the v2 defect survived review.

make_fixture_router() {
    local out="$1"
    shift
    : > "$out"
    printf '%s\n' '---' 'description: fixture router' '---' '' >> "$out"
    printf '%s\n' 'Route to the correct skill file based on the subcommand in $ARGUMENTS.' '' >> "$out"
    local token
    for token in "$@"; do
        printf -- '- `%s`        → `skills/g-%s/SKILL.md`  (remaining args: $ARGUMENTS)\n' "$token" "$token" >> "$out"
    done
    printf '%s\n' '' 'If $ARGUMENTS is empty or unrecognized, print the bare subcommand tokens.' >> "$out"
}

make_fixture_skills() {
    local dir="$1"
    shift
    local name
    for name in "$@"; do
        mkdir -p "$dir/g-$name" || return 1
        : > "$dir/g-$name/SKILL.md"
    done
}

# Same production line format as make_fixture_router, except one token's
# target path is deliberately typo'd (an extra trailing "X" before
# /SKILL.md) while its token stays valid. Proves the target-path check goes
# RED on exactly the R-18 defect class: a token that still resolves while
# its own target silently points at the wrong file.
make_fixture_router_bad_target() {
    local out="$1" bad_token="$2"
    shift 2
    : > "$out"
    printf '%s\n' '---' 'description: fixture router' '---' '' >> "$out"
    printf '%s\n' 'Route to the correct skill file based on the subcommand in $ARGUMENTS.' '' >> "$out"
    local token target
    for token in "$@"; do
        if [ "$token" = "$bad_token" ]; then
            target="skills/g-${token}X/SKILL.md"
        else
            target="skills/g-${token}/SKILL.md"
        fi
        printf -- '- `%s`        → `%s`  (remaining args: $ARGUMENTS)\n' "$token" "$target" >> "$out"
    done
    printf '%s\n' '' 'If $ARGUMENTS is empty or unrecognized, print the bare subcommand tokens.' >> "$out"
}

# Small join helper -- bash's "$*" only honors the FIRST character of $IFS as
# separator, which can't produce ", " or other multi-char separators. Used
# below to build the description-list ("a, b, c") and argument-hint
# ("a|b|c") clauses for the F3-11 fixtures.
join_by() {
    local sep="$1"
    shift
    local result="$1"
    shift
    local tok
    for tok in "$@"; do
        result="${result}${sep}${tok}"
    done
    printf '%s' "$result"
}

# Fixture router with all three token surfaces present (routing list,
# description-list, argument-hint) built from the SAME token set, so all
# three agree unless a caller deliberately omits one token from one surface.
# desc_missing / hint_missing name (at most) one token each to drop from the
# description-list / argument-hint clause respectively while the routing
# list keeps every token -- driving exactly one surface out of parity with
# the other two, the F3-11 defect class. Pass "" for either to omit nothing.
make_fixture_router_surfaces() {
    local out="$1" desc_missing="$2" hint_missing="$3"
    shift 3
    local full_tokens=("$@")
    local desc_tokens=() hint_tokens=()
    local t
    for t in "${full_tokens[@]}"; do
        [ "$t" = "$desc_missing" ] || desc_tokens+=("$t")
        [ "$t" = "$hint_missing" ] || hint_tokens+=("$t")
    done
    : > "$out"
    printf '%s\n' "---" \
        "description: fixture router. Subcommands — $(join_by ', ' "${desc_tokens[@]}")." \
        "argument-hint: <$(join_by '|' "${hint_tokens[@]}")> [args]" \
        "---" '' >> "$out"
    printf '%s\n' 'Route to the correct skill file based on the subcommand in $ARGUMENTS.' '' >> "$out"
    for t in "${full_tokens[@]}"; do
        printf -- '- `%s`        → `skills/g-%s/SKILL.md`  (remaining args: $ARGUMENTS)\n' "$t" "$t" >> "$out"
    done
    printf '%s\n' '' 'If $ARGUMENTS is empty or unrecognized, print the bare subcommand tokens.' >> "$out"
}

# ── Test 5: synthetic mismatch — router token with no skills/ directory ────────
#
# Proves the detector goes RED on a real divergence. The fixture router lists
# `nonexistent-skill`; the fixture skills tree does not contain it. The case
# PASSES when exactly that element is reported router-only and nothing is
# reported skills-only.

SYN1="$SUITE_TMP/syn1"
mkdir -p "$SYN1/skills"
make_fixture_router "$SYN1/router.md" help status nonexistent-skill plan
make_fixture_skills "$SYN1/skills" help plan status

derive_sets "$SYN1/router.md" "$SYN1/skills" "$SYN1/router-set.txt" "$SYN1/skills-set.txt"

SYN1_ROUTER_ONLY=$(comm -23 "$SYN1/router-set.txt" "$SYN1/skills-set.txt" | tr '\n' ',' | sed 's/,$//')
SYN1_SKILLS_ONLY=$(comm -13 "$SYN1/router-set.txt" "$SYN1/skills-set.txt" | tr '\n' ',' | sed 's/,$//')

if ! sets_equal "$SYN1/router-set.txt" "$SYN1/skills-set.txt" \
   && [ "$SYN1_ROUTER_ONLY" = "g-nonexistent-skill" ] \
   && [ -z "$SYN1_SKILLS_ONLY" ]; then
    echo "PASS: router-only token detected — router has 'g-nonexistent-skill' but skills/ does not"
    PASS=$((PASS+1))
else
    echo "FAIL: router-only token NOT detected as expected"
    echo "  expected router-only 'g-nonexistent-skill' and no skills-only entries"
    echo "  got router-only [$SYN1_ROUTER_ONLY] skills-only [$SYN1_SKILLS_ONLY]"
    FAIL=$((FAIL+1))
fi

# ── Test 6: synthetic mismatch — skills/ directory with no router token ────────
#
# The reverse direction. The fixture skills tree contains g-orphan-skill; the
# fixture router does not route to it. The case PASSES when exactly that
# element is reported skills-only and nothing is reported router-only.

SYN2="$SUITE_TMP/syn2"
mkdir -p "$SYN2/skills"
make_fixture_router "$SYN2/router.md" help plan status
make_fixture_skills "$SYN2/skills" help orphan-skill plan status

derive_sets "$SYN2/router.md" "$SYN2/skills" "$SYN2/router-set.txt" "$SYN2/skills-set.txt"

SYN2_ROUTER_ONLY=$(comm -23 "$SYN2/router-set.txt" "$SYN2/skills-set.txt" | tr '\n' ',' | sed 's/,$//')
SYN2_SKILLS_ONLY=$(comm -13 "$SYN2/router-set.txt" "$SYN2/skills-set.txt" | tr '\n' ',' | sed 's/,$//')

if ! sets_equal "$SYN2/router-set.txt" "$SYN2/skills-set.txt" \
   && [ "$SYN2_SKILLS_ONLY" = "g-orphan-skill" ] \
   && [ -z "$SYN2_ROUTER_ONLY" ]; then
    echo "PASS: skills-only directory detected — skills/ has 'g-orphan-skill' but router does not"
    PASS=$((PASS+1))
else
    echo "FAIL: skills-only directory NOT detected as expected"
    echo "  expected skills-only 'g-orphan-skill' and no router-only entries"
    echo "  got router-only [$SYN2_ROUTER_ONLY] skills-only [$SYN2_SKILLS_ONLY]"
    FAIL=$((FAIL+1))
fi

# ── Test 7: synthetic mismatch — target path typo'd, token still resolves ──────
#
# Proves the target-path check (Test 4) goes RED on a real divergence. The
# fixture router's `plan` line points at `skills/g-planX/SKILL.md` instead of
# `skills/g-plan/SKILL.md`; the fixture skills tree DOES contain g-plan (so
# Test 3-equivalent token/skills-dir parity would pass in full -- this is the
# case that only a target-path check catches). PASSES when exactly one
# offender is reported, for token `plan`, with the typo'd/expected paths.

SYN3="$SUITE_TMP/syn3"
mkdir -p "$SYN3/skills"
make_fixture_router_bad_target "$SYN3/router.md" plan help status plan
make_fixture_skills "$SYN3/skills" help plan status

derive_sets "$SYN3/router.md" "$SYN3/skills" "$SYN3/router-set.txt" "$SYN3/skills-set.txt" "$SYN3/router-fields.txt"

SYN3_BAD=$(target_offenders "$SYN3/router-fields.txt")
SYN3_BAD_COUNT=$(printf '%s\n' "$SYN3_BAD" | grep -c . 2>/dev/null || printf '0')

if [ "$SYN3_BAD_COUNT" -eq 1 ] \
   && printf '%s' "$SYN3_BAD" | grep -qF "$(printf 'plan\tskills/g-planX/SKILL.md\tskills/g-plan/SKILL.md')"; then
    echo "PASS: target-path mismatch detected — token 'plan' resolves but its target is typo'd"
    PASS=$((PASS+1))
else
    echo "FAIL: target-path mismatch NOT detected as expected"
    echo "  expected exactly one offender: plan -> got skills/g-planX/SKILL.md, expected skills/g-plan/SKILL.md"
    echo "  got ($SYN3_BAD_COUNT offender(s)):"
    printf '%s\n' "$SYN3_BAD" | sed 's/^/    /'
    FAIL=$((FAIL+1))
fi

# ── Test 8: real files — description-list parity with the routing list ────────
# provenance: shares extract_description_tokens with Test 10, the
# RED-proving synthetic case (extract_description_tokens neutered in scratch
# copy -- Test 8 stayed green, Test 10 went red) -- scratch probe run
# 2026-08-31, output in g-docs/agent-output/wave-f3/task-40-router-parity.md
#
# Guards the F3-11 gap: g-skill-design registered only the routing-list line,
# never the frontmatter `description:` subcommand list, so a new skill's
# token could resolve at dispatch while staying invisible in the command
# palette. This asserts the description-list token set matches the routing
# list exactly, in both directions.

if sets_equal "$ROUTER_SET" "$DESC_SET"; then
    echo "PASS: real files description-list parity — routing list and frontmatter description-list tokens match ($ROUTER_SET_COUNT entries each)"
    PASS=$((PASS+1))
else
    ROUTER_ONLY_DESC=$(comm -23 "$ROUTER_SET" "$DESC_SET" | tr '\n' ',' | sed 's/,$//')
    DESC_ONLY=$(comm -13 "$ROUTER_SET" "$DESC_SET" | tr '\n' ',' | sed 's/,$//')
    echo "FAIL: real files description-list parity mismatch"
    [ -n "$ROUTER_ONLY_DESC" ] && echo "  Routing-list tokens missing from the description list: $ROUTER_ONLY_DESC"
    [ -n "$DESC_ONLY" ] && echo "  Description-list tokens missing from the routing list: $DESC_ONLY"
    FAIL=$((FAIL+1))
fi

# ── Test 9: real files — argument-hint parity with the routing list ───────────
# provenance: shares extract_arghint_tokens with Test 11, the RED-proving
# synthetic case (extract_arghint_tokens neutered in scratch copy -- Test 9
# stayed green, Test 11 went red) -- scratch probe run 2026-08-31, output in
# g-docs/agent-output/wave-f3/task-40-router-parity.md
#
# Same F3-11 gap, the third surface: the `argument-hint` pipe-separated list
# must also match the routing list exactly.

if sets_equal "$ROUTER_SET" "$ARGHINT_SET"; then
    echo "PASS: real files argument-hint parity — routing list and argument-hint tokens match ($ROUTER_SET_COUNT entries each)"
    PASS=$((PASS+1))
else
    ROUTER_ONLY_HINT=$(comm -23 "$ROUTER_SET" "$ARGHINT_SET" | tr '\n' ',' | sed 's/,$//')
    HINT_ONLY=$(comm -13 "$ROUTER_SET" "$ARGHINT_SET" | tr '\n' ',' | sed 's/,$//')
    echo "FAIL: real files argument-hint parity mismatch"
    [ -n "$ROUTER_ONLY_HINT" ] && echo "  Routing-list tokens missing from argument-hint: $ROUTER_ONLY_HINT"
    [ -n "$HINT_ONLY" ] && echo "  Argument-hint tokens missing from the routing list: $HINT_ONLY"
    FAIL=$((FAIL+1))
fi

# ── Test 10: synthetic mismatch — description-list omits a routed token ───────
#
# Fixture routes `help`, `status`, `plan` but the description-list clause
# omits `plan` (argument-hint stays complete). PASSES when exactly
# 'g-plan' is reported missing from the description list.

SYN4="$SUITE_TMP/syn4"
mkdir -p "$SYN4"
make_fixture_router_surfaces "$SYN4/router.md" "plan" "" help status plan

SYN4_ROUTER_SET="$SUITE_TMP/syn4-router-set.txt"
SYN4_DESC_SET="$SUITE_TMP/syn4-desc-set.txt"
extract_router_tokens "$SYN4/router.md" | add_g_prefix | canonicalize > "$SYN4_ROUTER_SET"
extract_description_tokens "$SYN4/router.md" | add_g_prefix | canonicalize > "$SYN4_DESC_SET"

SYN4_ROUTER_ONLY=$(comm -23 "$SYN4_ROUTER_SET" "$SYN4_DESC_SET" | tr '\n' ',' | sed 's/,$//')
SYN4_DESC_ONLY=$(comm -13 "$SYN4_ROUTER_SET" "$SYN4_DESC_SET" | tr '\n' ',' | sed 's/,$//')

if ! sets_equal "$SYN4_ROUTER_SET" "$SYN4_DESC_SET" \
   && [ "$SYN4_ROUTER_ONLY" = "g-plan" ] \
   && [ -z "$SYN4_DESC_ONLY" ]; then
    echo "PASS: description-list-missing token detected — routing list has 'g-plan' but the description list omits it"
    PASS=$((PASS+1))
else
    echo "FAIL: description-list-missing token NOT detected as expected"
    echo "  expected router-only 'g-plan' and no description-only entries"
    echo "  got router-only [$SYN4_ROUTER_ONLY] description-only [$SYN4_DESC_ONLY]"
    FAIL=$((FAIL+1))
fi

# ── Test 11: synthetic mismatch — argument-hint omits a routed token ──────────
#
# Fixture routes `help`, `status`, `plan` but the argument-hint clause omits
# `plan` (description list stays complete). PASSES when exactly 'g-plan' is
# reported missing from argument-hint.

SYN5="$SUITE_TMP/syn5"
mkdir -p "$SYN5"
make_fixture_router_surfaces "$SYN5/router.md" "" "plan" help status plan

SYN5_ROUTER_SET="$SUITE_TMP/syn5-router-set.txt"
SYN5_HINT_SET="$SUITE_TMP/syn5-hint-set.txt"
extract_router_tokens "$SYN5/router.md" | add_g_prefix | canonicalize > "$SYN5_ROUTER_SET"
extract_arghint_tokens "$SYN5/router.md" | add_g_prefix | canonicalize > "$SYN5_HINT_SET"

SYN5_ROUTER_ONLY=$(comm -23 "$SYN5_ROUTER_SET" "$SYN5_HINT_SET" | tr '\n' ',' | sed 's/,$//')
SYN5_HINT_ONLY=$(comm -13 "$SYN5_ROUTER_SET" "$SYN5_HINT_SET" | tr '\n' ',' | sed 's/,$//')

if ! sets_equal "$SYN5_ROUTER_SET" "$SYN5_HINT_SET" \
   && [ "$SYN5_ROUTER_ONLY" = "g-plan" ] \
   && [ -z "$SYN5_HINT_ONLY" ]; then
    echo "PASS: argument-hint-missing token detected — routing list has 'g-plan' but argument-hint omits it"
    PASS=$((PASS+1))
else
    echo "FAIL: argument-hint-missing token NOT detected as expected"
    echo "  expected router-only 'g-plan' and no argument-hint-only entries"
    echo "  got router-only [$SYN5_ROUTER_ONLY] argument-hint-only [$SYN5_HINT_ONLY]"
    FAIL=$((FAIL+1))
fi

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

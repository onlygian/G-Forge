#!/bin/bash
# hooks/lib/classify-changeset.sh — shared CODE/DOC/REFERENCE file-set
# classifier. Sets three flags (HAS_CODE/HAS_DOC/HAS_REFERENCE); each
# consumer then derives its own five-way CLASS from them (reference, mixed,
# doc, code, and an empty/no-bucket input defaulting to code).
#
# Sourced (never executed directly) by hooks/check-commit.sh and the ADR-004
# native pre-commit hook, so both enforcement sites classify a changeset's
# file set identically instead of two hand-edited case-statements that can
# drift apart. This file defines a function only — sourcing it alone has no
# output and no side effects.
#
# Public API:
#   gf_classify_changeset — read a changeset's file paths (one per line) on
#     stdin, classify each path into the CODE, DOC, or REFERENCE bucket, and
#     set the caller-visible globals HAS_CODE / HAS_DOC / HAS_REFERENCE
#     accordingly (1 = present in this changeset, 0 = absent). Always sets
#     all three globals. Empty lines are skipped, so a fully empty input
#     leaves all three flags at 0 (no bucket present). A whitespace-only line
#     (e.g. a single space) is NOT empty and is NOT skipped — it falls
#     through every case arm to the unmatched→CODE default, so HAS_CODE=1 for
#     that input. This is fail-toward-deny (an unparseable/garbage path gates
#     as the stricter CODE bucket rather than silently vanishing). The three
#     flags this function sets are the whole of its output; the derived CLASS
#     a caller computes from them (`reference`, then `mixed`/`doc`/`code`, and
#     an empty/no-bucket input defaulting to `code` — five named outcomes) is
#     each consumer's own logic, not this function's — see
#     hooks/check-commit.sh:239 and hooks/pre-commit:168 for that derivation.
#
# Bucket rules (do not extend or "improve" without a corresponding update to
# every caller and to tests/test-classify-changeset.sh, tests/test-check-commit.sh
# and tests/test-pre-commit.sh):
#   g-docs/* | g-wiki/* | docs/*        → DOC
#   reference/<bundle>/<file on the inert allowlist: .md/.markdown/.txt/.rst/
#     .pdf/.png/.jpg/.jpeg/.gif/.webp/.svg/.csv/.json/.html/.xml> → checked
#     against the bundle's marker (below); anything NOT on this allowlist —
#     extensionless files, .ps1/.bat/.yml, Makefile, unknown or uppercase
#     extensions (matching is case-sensitive) — never reaches the marker
#     lookup and gates as CODE outright (M40 Task 17, hardened Session C: a
#     denylist guarding this exemption can never make "a REFERENCE bundle
#     must never smuggle an executable past the review gate" true — only an
#     allowlist can, so the polarity was flipped from denylist to allowlist).
#   reference/<bundle>/... (allowlisted extension, no `..`, `.` or empty
#     segment anywhere in the path, and reference/<bundle>/SNAPSHOT.md or
#     reference/<bundle>/NOTE.md exists on disk under GF_CLASSIFY_ROOT) →
#     REFERENCE (a frozen external snapshot with no code it describes is
#     neither DOC nor CODE; marker-gated so an unmarked reference/ path stays
#     CODE, fail-toward-deny)
#   reference/<bundle>/... (allowlisted extension, bundle unmarked) → CODE,
#     fail-toward-deny
#   reference/... with a `..`, `.` or empty segment ANYWHERE in the path
#     (e.g. reference/<marked>/../../x.md, reference/./x.md, reference//x.md)
#     → CODE before the marker lookup is attempted — check-commit.sh folds
#     argv pathspecs in verbatim, so a traversal below a marked bundle would
#     otherwise resolve to that bundle's marker and exempt a file outside
#     reference/
#   README* | CHANGELOG* | LICENSE* at repo root (no slash) → DOC
#   README* | CHANGELOG* | LICENSE* nested (contains a slash) → CODE
#     (M-audit W3 task 12: a bare `README*` glob matches the *entire* path
#     string, not just a basename, so a non-root path whose top-level
#     component merely starts with "README" — e.g. `README-archive/notes.txt`,
#     a directory, not the doc file — was over-matching into DOC. Narrowed to
#     mirror the existing root-vs-nested split already used for *.md below.
#     Root-level oddities like `README_extended` intentionally stay DOC —
#     that pinned case is unchanged.)
#   *.md at repo root (no slash)        → DOC
#   *.md nested (contains a slash)      → CODE
#   hooks/* | skills/* | agents/* | commands/* | profiles/* | tests/* |
#     .claude-plugin/* | .claude/rules/*  → CODE
#   anything else (unmatched)           → CODE (default — the stricter gate,
#                                          so a misclassification never
#                                          weakens enforcement)
#   empty input                         → no flags set; caller's CLASS
#                                          derivation falls through to CODE
#                                          (the historical fail-safe default)
#
# REFERENCE is exempt-with-advisory, never a silent bypass: a changeset that
# is REFERENCE-only (HAS_REFERENCE=1, HAS_CODE=0, HAS_DOC=0) skips the
# code/doc sign-off gate but the consumer still prints an advisory line
# naming the class — see hooks/check-commit.sh and hooks/pre-commit. A mix of
# REFERENCE with CODE or DOC never weakens those gates: REFERENCE only ever
# adds an exemption for the reference-only case, it never removes CODE/DOC's
# existing requirement.
#
# GF_CLASSIFY_ROOT — the directory the reference/<bundle> marker lookup
# (`[ -f ... ]`, never `git ls-files`, so it works without a repo) is rooted
# at. Defaults to "." (the consumer hooks' cwd, the repo/primary worktree
# root). Overridable so tests can point the marker lookup at a plain
# `mktemp -d` fixture directory (no git needed) instead of this repo's tree.
#
# Call convention: invoke with a HEREDOC or input redirection —
#   gf_classify_changeset <<EOF
#   $STAGED
#   EOF
# — never by piping (`printf '%s' "$STAGED" | gf_classify_changeset`). A pipe
# runs the function in a subshell in plain bash, so its HAS_CODE/HAS_DOC/
# HAS_REFERENCE assignments would not propagate back to the caller; a
# heredoc/redirection does not fork a subshell, so the globals land in the
# caller's own shell — exactly how hooks/check-commit.sh's original inline
# loop consumed $STAGED.

# gf_classify_changeset — see header. Sets globals HAS_CODE, HAS_DOC, and
# HAS_REFERENCE.
gf_classify_changeset() {
    HAS_CODE=0
    HAS_DOC=0
    HAS_REFERENCE=0
    # Marker-lookup root — overridable by the caller/test, never hardcoded to
    # this repo's tree. See header note.
    GF_CLASSIFY_ROOT="${GF_CLASSIFY_ROOT:-.}"
    local _f _bundle
    while IFS= read -r _f; do
        [ -z "$_f" ] && continue
        # Normalize a Windows-style backslash pathspec to forward slashes
        # BEFORE the case ladder below — classification only, the actual
        # staged/committed path list is never rewritten. Left un-normalized,
        # a backslash path (e.g. `skills\g-review\SKILL.md`) matches neither
        # the `skills/*` CODE arm nor any `*/*` nested split — it has no
        # forward slash at all — and falls through to the *.md root-only arm
        # as a false DOC classification instead of the nested CODE bucket it
        # should hit (C-4, 2026-08-30). An unmatched path still defaults to
        # CODE either way (fail-toward-deny unchanged).
        _f="${_f//'\'/'/'}"
        case "$_f" in
            # DOC paths — narrative documentation surface. Documentation
            # directories first.
            g-docs/*|g-wiki/*|docs/*) HAS_DOC=1 ;;
            # reference/<bundle>/... — M40 Task 17. Checked before every other
            # arm below (including *.md, so a marked reference/foo/SNAPSHOT.md
            # is REFERENCE, not nested-.md CODE) so this zone is classified by
            # its own marker rule rather than any generic doc/code pattern.
            reference/*/*)
                case "$_f" in
                    # Inert allowlist, WHY: a denylist guarding an exemption
                    # can never make the "must never smuggle an executable
                    # past the review gate" claim true — anything NOT on this
                    # list (extensionless files, .ps1/.bat/.yml, Makefile,
                    # unknown/uppercase extensions) falls through to the `*)`
                    # arm below and gates as CODE. Only these formats — inert
                    # for THIS gate's purpose (rendered/data formats;
                    # `.html`/`.svg`/`.json` can carry script but nothing on
                    # the plugin surface executes them) — reach the marker
                    # lookup. Matching is
                    # case-sensitive by design — e.g. `*.md` does not match
                    # `.MD` — so an uppercase-extension file also falls
                    # through to CODE, the safe direction. A path with a
                    # `..`, `.` or empty segment anywhere in it never reaches
                    # the marker lookup either — see the guard below.
                    *.md|*.markdown|*.txt|*.rst|*.pdf|*.png|*.jpg|*.jpeg|*.gif|*.webp|*.svg|*.csv|*.json|*.html|*.xml)
                        # Bundle name = the path segment right after
                        # "reference/", regardless of how deep the file
                        # itself is nested under it.
                        _bundle="${_f#reference/}"
                        _bundle="${_bundle%%/*}"
                        # Dot-segment guard on the WHOLE path, not just the
                        # bundle name: check-commit.sh folds argv pathspecs
                        # in verbatim, so `reference/<marked>/../../x.md`
                        # would otherwise resolve to the bundle's marker and
                        # exempt a file outside reference/ (code-lead r2,
                        # 2026-08-30). Any `..`, `.` or empty segment
                        # anywhere → CODE, fail-toward-deny.
                        case "/$_f/" in
                            *"/../"*|*"/./"*|*"//"*)
                                HAS_CODE=1
                                ;;
                            *)
                                if [ -f "$GF_CLASSIFY_ROOT/reference/$_bundle/SNAPSHOT.md" ] || [ -f "$GF_CLASSIFY_ROOT/reference/$_bundle/NOTE.md" ]; then
                                    HAS_REFERENCE=1
                                else
                                    # Unmarked reference/ bundle — fail-toward-deny,
                                    # same default polarity as the unmatched arm below.
                                    HAS_CODE=1
                                fi
                                ;;
                        esac
                        ;;
                    *)
                        # Everything else, including extensionless files —
                        # fail toward deny.
                        HAS_CODE=1
                        ;;
                esac
                ;;
            # Root-level documentation files (README*, CHANGELOG*, LICENSE*)
            # and any root-level *.md (no slash in the path = repo root)
            # treated as docs. A bare README*/CHANGELOG*/LICENSE* glob matches
            # the whole path string, so without the root check a non-root path
            # whose top-level component merely starts with one of these words
            # (e.g. README-archive/notes.txt) would over-match into DOC; narrow
            # to root-only, same split already used for *.md below (M-audit W3
            # task 12). Non-matches fall through to the unmatched→CODE default,
            # keeping fail-toward-deny polarity unchanged.
            README*|CHANGELOG*|LICENSE*) case "$_f" in */*) HAS_CODE=1 ;; *) HAS_DOC=1 ;; esac ;;
            *.md) case "$_f" in */*) HAS_CODE=1 ;; *) HAS_DOC=1 ;; esac ;;
            # CODE paths — plugin executable/instruction surface. .claude/rules/
            # is instruction surface (code); anything under it gates as code.
            hooks/*|skills/*|agents/*|commands/*|profiles/*|tests/*|.claude-plugin/*|.claude/rules/*) HAS_CODE=1 ;;
            # When in doubt, treat as CODE — the code gate is the stricter one.
            *) HAS_CODE=1 ;;
        esac
    done
}

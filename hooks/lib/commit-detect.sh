#!/bin/bash
# Shared argv-based git-commit detection + pathspec extraction.
#
# Sourced (never executed directly) by hooks/check-commit.sh and the ADR-004
# native pre-commit hook, so both enforcement sites agree on "what is a git
# commit" from a single implementation instead of two hand-edited regexes
# that can drift apart (M-audit finding #21 / BUG-2 root cause). This file
# defines functions only — sourcing it alone has no output and no side
# effects.
#
# Public API:
#   is_git_commit <cmd>      — return 0 iff <cmd> really invokes `git commit`
#   extract_pathspecs <cmd>  — print, one per line, <cmd>'s positional
#                              pathspec arguments (assumes is_git_commit true)
#   gf_commit_skips_hooks <cmd>          — return 0 iff <cmd> is a real
#                                          `git commit` carrying --no-verify
#                                          (or any prefix of it the function's
#                                          `case` arm lists — every prefix, so
#                                          the arm never depends on which ones
#                                          git treats as ambiguous), or a
#                                          single-dash short-flag
#                                          cluster in which `n` appears before
#                                          any value-taking short flag — the
#                                          set is the one the function's own
#                                          cluster-walk `case` arm names; a
#                                          value-taking flag consumes the rest
#                                          of the cluster, so `-mnote` is a
#                                          message and `-na` is a skip. Both
#                                          skip the native ADR-004 pre-commit
#                                          hook (F1-2). False on a non-commit
#                                          or a commit with no such flag.
#   gf_commit_overrides_hookspath <cmd>  — return 0 iff <cmd> is a real
#                                          `git commit` whose tokens BEFORE
#                                          `commit` name core.hooksPath (key
#                                          case-insensitive) in any of the
#                                          forms the function's `case` arms
#                                          match — a global `-c` (separate or
#                                          glued value) or an env-assignment
#                                          prefix token; each redirects git to
#                                          skip the same native hook (F1-2).
#                                          False otherwise.

# _commit_detect_tokenize <cmd> — split <cmd> into argv-like tokens, one per
# output line. Uses `xargs -n1` (shell-style quote/whitespace splitting)
# rather than `eval` — eval re-parses the string as shell code and would
# execute embedded command substitutions/backticks even when the caller only
# wants to inspect argv, including on a command the gate ultimately denies.
# On malformed input (e.g. an unmatched quote), GNU xargs emits the tokens it
# had already assembled up to the malformed point, then errors — so we get
# partial tokens, not zero tokens. That partial argv typically still starts
# `git commit ...` and so is typically DETECTED: fail-toward-deny, the safe
# direction for a commit gate.
#
# F1-2 fix: `xargs -n1` with NO command given runs its default, `echo` — GNU
# coreutils `echo`, not the bash builtin — and GNU `echo` treats a bare `-n`
# (also `-e`, `-E`, `--help`, `--version`, ...) argument as ITS OWN flag
# rather than printing it as literal output, so that token vanished from the
# tokenized stream entirely (discovered live: `git commit -n -m x` tokenized
# to `git commit -m x`, silently dropping the very flag
# gf_commit_skips_hooks needs to see). Passing `printf '%s\n'` explicitly as
# the command xargs runs sidesteps this — printf has no flag-like arguments
# of its own to swallow, so every token, including a bare `-n`, reaches the
# output unchanged. Malformed-input behavior (partial tokens + stderr error)
# is unaffected — that error path is xargs's own quote handling, not the
# command it invokes.
_commit_detect_tokenize() {
    printf '%s' "$1" | xargs -n1 printf '%s\n' 2>/dev/null
}

# _commit_detect_is_var_assign <tok> — true iff <tok> is a shell env-style
# assignment (`NAME=value`, NAME possibly one character). Deliberately NOT
# the single glob `[A-Za-z_][A-Za-z0-9_]*=*` — that compound (two adjacent
# bracket expressions) fails to match single-character names such as `A=1`
# under git-bash bash 5.2.37 (verified live, both `case` and `[[ ]]`; ledger
# finding #26). Split-then-validate with single-class patterns instead.
_commit_detect_is_var_assign() {
    local tok="$1"
    case "$tok" in
        *=*) ;;
        *) return 1 ;;
    esac
    local name="${tok%%=*}"
    [ -n "$name" ] || return 1
    case "${name:0:1}" in
        [A-Za-z_]) ;;
        *) return 1 ;;
    esac
    case "${name:1}" in
        *[!A-Za-z0-9_]*) return 1 ;;
    esac
    return 0
}

# _commit_detect_walk_core — the argv walk for a SINGLE already-isolated
# segment (no chain operators inside it — see _commit_detect_scan_segments).
# Assumes _CD_TOKENS/_CD_N already hold that segment's tokens; sets
# _CD_OK/_CD_IDX. May splice extra tokens into _CD_TOKENS/_CD_N in place when
# unwrapping `env -S "..."` (the quoted value is itself re-tokenized and its
# tokens take the place of the single -S value token).
_commit_detect_walk_core() {
    _CD_OK=0
    _CD_IDX=0
    local i=0

    # Strip leading VAR=val assignments (env-style prefix, e.g. `FOO=bar git commit`).
    while [ "$i" -lt "$_CD_N" ] && _commit_detect_is_var_assign "${_CD_TOKENS[$i]}"; do
        i=$((i + 1))
    done

    # Strip a leading `env` / `env -S ...` prefix (its own flags and any
    # VAR=val pairs it carries), landing on the real command token.
    if [ "$i" -lt "$_CD_N" ] && [ "${_CD_TOKENS[$i]}" = "env" ]; then
        i=$((i + 1))
        while [ "$i" -lt "$_CD_N" ]; do
            case "${_CD_TOKENS[$i]}" in
                -S | --split-string)
                    if [ "$((i + 1))" -lt "$_CD_N" ]; then
                        # The -S value is one token containing embedded
                        # whitespace (e.g. "git commit -m x"). Re-tokenize it
                        # and splice the pieces in place of the flag + value,
                        # then keep walking from the same position — the
                        # spliced tokens may themselves be `VAR=val git commit …`.
                        local -a _cd_spliced=()
                        while IFS= read -r _cd_stok; do
                            _cd_spliced+=("$_cd_stok")
                        done < <(_commit_detect_tokenize "${_CD_TOKENS[$((i + 1))]}")
                        _CD_TOKENS=("${_CD_TOKENS[@]:0:i}" "${_cd_spliced[@]}" "${_CD_TOKENS[@]:$((i + 2))}")
                        _CD_N=${#_CD_TOKENS[@]}
                    else
                        i=$((i + 1))
                    fi
                    ;;
                -*) i=$((i + 1)) ;;
                *)
                    if _commit_detect_is_var_assign "${_CD_TOKENS[$i]}"; then
                        i=$((i + 1))
                    else
                        break
                    fi
                    ;;
            esac
        done
    fi

    [ "$i" -lt "$_CD_N" ] || return 0

    # F1-3: strip a bounded run of "transparent" prefix tokens — each of
    # these wraps or introduces a command without changing which program
    # actually runs (an `if`/`elif`/`while`/`until` conditional test, a `!`
    # negation, `command`/`exec` wrapping, `time`/`nohup`/`builtin`
    # instrumentation, or a bare `$(` subshell/command-substitution opener —
    # normally split off as its own boundary token by the paren padding in
    # _commit_detect_scan_segments, but stripped here too for any caller that
    # hands this function an unpadded segment directly). Closed on purpose —
    # no general "skip unknown words", which would let arbitrary tokens
    # masquerade as transparent and silently swallow a real command. Runs
    # AFTER the var-assign/env strip above and BEFORE the `git` test below, so
    # `if git commit`, `command git commit`, `exec git commit`, `time git
    # commit`, and `$( git commit` all still land on the `git` token next.
    while [ "$i" -lt "$_CD_N" ]; do
        case "${_CD_TOKENS[$i]}" in
            if | elif | while | until | "!" | command | exec | time | nohup | builtin | '$(')
                i=$((i + 1))
                ;;
            *)
                break
                ;;
        esac
    done

    [ "$i" -lt "$_CD_N" ] || return 0

    # The first real token must be `git` (bare, or a path ending in /git) —
    # anything else means this isn't a git invocation at all.
    case "${_CD_TOKENS[$i]}" in
        git | */git) ;;
        *) return 0 ;;
    esac
    i=$((i + 1))

    # M-audit W3 task 2 (finding #6b split — full `.git/config` [alias]
    # resolution is DEFERRED, see g-docs/agent-output/wave-w3-1/*; only this
    # zero-cost argv-visible sub-case is implemented): `-c alias.NAME=VALUE`
    # defines an alias entirely on the command line, no config file read and
    # no git subprocess spawn needed — the definition already sits in the
    # tokenized argv this loop already walks. If VALUE's first word is
    # literally `commit` (bare, or with embedded flags e.g. `commit -m`),
    # remember NAME so that if it's later invoked in subcommand position it
    # is treated exactly like the literal `commit`. Shell-form (`!...`)
    # alias values are intentionally NOT resolved here — recognizing a
    # commit hidden inside one requires recursive re-entry into the whole
    # chain/heredoc detection pipeline, which is part of the DEFERRED
    # config-file case, not this narrow argv sub-case.
    local _cd_alias_name=""

    # Walk forward skipping global flags: value-taking -C/-c/--git-dir/
    # --work-tree/--namespace (separate-value or `=`-glued), and boolean
    # --no-pager/-p. Unknown `-*` tokens intentionally break the loop — the
    # first non-flag token after `git` must be `commit` itself; we don't
    # invent a general flag-skipper that could over-skip and create false
    # positives on flags we haven't verified.
    while [ "$i" -lt "$_CD_N" ]; do
        case "${_CD_TOKENS[$i]}" in
            -c)
                if [ "$((i + 1))" -lt "$_CD_N" ]; then
                    case "${_CD_TOKENS[$((i + 1))]}" in
                        alias.*=*)
                            local _cd_adef="${_CD_TOKENS[$((i + 1))]#alias.}"
                            local _cd_aname="${_cd_adef%%=*}"
                            local _cd_aval="${_cd_adef#*=}"
                            [ "${_cd_aval%% *}" = "commit" ] && _cd_alias_name="$_cd_aname"
                            ;;
                    esac
                fi
                i=$((i + 2))
                ;;
            -C | --git-dir | --work-tree | --namespace) i=$((i + 2)) ;;
            --git-dir=* | --work-tree=* | --namespace=*) i=$((i + 1)) ;;
            --no-pager | -p) i=$((i + 1)) ;;
            *) break ;;
        esac
    done

    [ "$i" -lt "$_CD_N" ] || return 0

    # The first non-flag token after `git` (and its global flags) must be
    # exactly the literal `commit` — not a substring, not a quoted fragment
    # of some other argument — OR exactly the ad-hoc alias name captured
    # above from a `-c alias.NAME=commit...` definition earlier in argv.
    if [ "${_CD_TOKENS[$i]}" = "commit" ]; then
        _CD_OK=1
        _CD_IDX=$((i + 1))
    elif [ -n "$_cd_alias_name" ] && [ "${_CD_TOKENS[$i]}" = "$_cd_alias_name" ]; then
        _CD_OK=1
        _CD_IDX=$((i + 1))
    fi
    return 0
}

# _commit_detect_scan_segments <raw> — normalize <raw>, tokenize it, and
# split the token stream into segments at shell command-separator
# boundaries: the tokens `&&`, `||`, `;`, `|`, `&`, and a `;` glued onto the
# end of the previous token (xargs word-splitting yields `hi;` as one token
# when there's no space before the semicolon — that's still a boundary,
# just spelled differently).
#
# GLUED-OPERATOR NORMALIZATION (ledger finding #25, W1.5a review r1): a chain
# operator glued directly onto a non-space word (`x&&git commit`,
# `true|git commit`, `echo hi;git commit`) is NOT isolated as its own
# xargs token — it survives as part of a larger word (`x&&git`, `true|git`,
# `hi;git`) and the boundary `case` below never sees it, so the chained
# `git commit` slips through undetected. Fixed by a `sed` pass that pads
# every bare `&`, `|`, `;` in the RAW string with surrounding spaces
# BEFORE tokenizing — done on the string, never on the already-split
# tokens, because after xargs a quoted `"a&&b"` and a glued `a&&b` are
# indistinguishable as tokens; splitting post-tokenization would corrupt
# quoted content with no way back. Padding on the raw string is safe
# because it composes correctly with xargs's own quote handling: the sed
# pass doesn't (and doesn't need to) know about quotes — it blindly pads
# every bare operator character, including ones that happen to sit inside
# a quoted region (e.g. a commit message `-m "a && b"`). But the quote
# characters themselves are untouched by sed, so when xargs tokenizes the
# padded string it still sees the same opening/closing quotes and folds
# everything between them back into ONE token — the extra padding just
# becomes harmless extra whitespace inside that token's value. So an
# operator glued OUTSIDE quotes becomes a real boundary token, while the
# same character sitting INSIDE quotes never becomes its own token and
# so is never treated as a boundary — a real commit message containing
# `&&`/`|`/`;` is never split. `&&`/`||` need no special-case handling:
# padding each `&` independently turns `&&` into two adjacent `&` tokens
# (two boundaries with an empty segment between them, which the loop below
# already skips via the `${#_cd_seg[@]} -gt 0` guard); same for `||`.
#
# WRAPPER-SHAPE NORMALIZATION (F1-3): the same reasoning extends to `(`, `)`,
# `{`, `}`, and a backtick — a `git commit` wrapped in a subshell
# `(git commit -m x)`, a command substitution `$(git commit -m x)` or
# `` `git commit -m x` ``, or a brace group `{ git commit -m x; }` is
# likewise invisible to the boundary `case` unless these characters are
# padded into their own tokens first. Same sed pass, same quote-safety
# argument: a message body containing a literal `(`/`)`/`{`/`}`/backtick
# (e.g. `-m "a (b) {c}"`) stays inside its quotes and folds back into one
# token, so it is never mistaken for a wrapper boundary.
#
# NOTE: an unescaped `&` in a sed REPLACEMENT means "the matched text" —
# the `&` replacement below is written `s/&/ \& /g` (escaped) so it
# inserts a literal ampersand rather than relying on that coincidence.
#
# Runs _commit_detect_walk_core on each segment in order and stops at the
# FIRST one that resolves to a real `git commit`: `_CD_TOKENS`/`_CD_N`/
# `_CD_IDX` are left describing that committing segment so
# extract_pathspecs keeps working unchanged. If a chained command has
# several committing segments (e.g. `git commit -m a && git commit -m b`),
# only the first is reported — deliberate and conservative; which one is
# "the" commit rarely matters since the gate treats both identically.
# Returns 0 iff some segment committed, 1 otherwise.
_commit_detect_scan_segments() {
    local raw="$1"
    local _cd_norm
    _cd_norm=$(printf '%s' "$raw" | sed -e 's/&/ \& /g' -e 's/|/ | /g' -e 's/;/ ; /g' -e 's/(/ ( /g' -e 's/)/ ) /g' -e 's/{/ { /g' -e 's/}/ } /g' -e 's/`/ ` /g')

    local -a _cd_flat=()
    while IFS= read -r _cd_tok; do
        _cd_flat+=("$_cd_tok")
    done < <(_commit_detect_tokenize "$_cd_norm")
    local _cd_flat_n=${#_cd_flat[@]}

    local -a _cd_seg=()
    local _cd_i=0
    local _cd_cur

    while [ "$_cd_i" -le "$_cd_flat_n" ]; do
        if [ "$_cd_i" -eq "$_cd_flat_n" ]; then
            if [ "${#_cd_seg[@]}" -gt 0 ]; then
                _CD_TOKENS=("${_cd_seg[@]}")
                _CD_N=${#_CD_TOKENS[@]}
                _commit_detect_walk_core
                [ "$_CD_OK" -eq 1 ] && return 0
            fi
            break
        fi

        _cd_cur="${_cd_flat[$_cd_i]}"
        case "$_cd_cur" in
            "&&" | "||" | ";" | "|" | "&" | "(" | ")" | "{" | "}" | "\`")
                if [ "${#_cd_seg[@]}" -gt 0 ]; then
                    _CD_TOKENS=("${_cd_seg[@]}")
                    _CD_N=${#_CD_TOKENS[@]}
                    _commit_detect_walk_core
                    [ "$_CD_OK" -eq 1 ] && return 0
                fi
                _cd_seg=()
                ;;
            *";")
                _cd_seg+=("${_cd_cur%;}")
                _CD_TOKENS=("${_cd_seg[@]}")
                _CD_N=${#_CD_TOKENS[@]}
                _commit_detect_walk_core
                [ "$_CD_OK" -eq 1 ] && return 0
                _cd_seg=()
                ;;
            *)
                _cd_seg+=("$_cd_cur")
                ;;
        esac
        _cd_i=$((_cd_i + 1))
    done

    _CD_OK=0
    return 1
}

# _commit_detect_strip_heredocs <raw> — remove well-formed heredoc BODY
# lines from <raw> before the newline-suffix walk in _commit_detect_parse
# (M-audit finding #21 residual, characterized in
# g-docs/agent-output/wave-w2-1/heredoc-characterization.md). The suffix
# walk has no heredoc awareness: every embedded newline starts a fresh scan
# suffix, so a heredoc BODY line that happens to read like `git commit ...`
# (e.g. a `cat > report.md <<EOF` reviewer write, or a script being authored
# via heredoc) is indistinguishable from a real standalone command and gets
# falsely DETECTED. Three conservative guards, in this order:
#   1. Only a WELL-FORMED heredoc is stripped — an opener token found AND a
#      matching terminator line found later in the string. An unterminated
#      heredoc returns the ENTIRE input untouched (not just that region):
#      fail-toward-deny, same direction as the malformed-input handling
#      already documented at _commit_detect_tokenize (:16-28).
#   2. Never strip when the heredoc's own command is (or might be — an
#      UNIDENTIFIABLE prefix is treated the same as a positive match, not
#      stripped) a shell interpreter (bash/sh/zsh/dash/ksh/eval/source/.):
#      that body really executes, so `bash <<EOF ... git commit ... EOF`
#      must stay detected. Checked by tokenizing everything on the opener
#      line before the heredoc operator and scanning every token — not just
#      the first — so `x && bash <<EOF` is still caught. Also checked on the
#      opener-line SUFFIX (tokens after the heredoc operator on the same
#      line, M-audit W3 task 16): `cat <<EOF | bash` pipes the body to an
#      interpreter that never appears in the prefix, so the suffix is
#      scanned too and an interpreter match there overrides a
#      non-interpreter prefix verdict.
#   3. The opener line's real command tokens are never removed — only the
#      `<<WORD` operator match itself is excised from it (todo row 10 fix,
#      2026-08-23: modeling real shell argv, which never passes the
#      redirection operator or its terminator word to the invoked program).
#      A real `git commit <<EOF` on the opener line is still scanned
#      normally by the caller; so is anything before/after the operator on
#      that same line (e.g. the `| bash` suffix in guard 2). The terminator
#      line is likewise never re-emitted as its own output line in either
#      branch below — it is a bare delimiter word, not a command, and
#      leaving it in as an unflagged token is what let it (and the excised
#      operator) leak into extract_pathspecs' positional-pathspec walk as
#      false CODE pathspecs on an otherwise doc-only heredoc commit.
# Only one heredoc form is recognised per opener: `<<[-]?WORD`,
# `<<[-]?'WORD'`, or `<<[-]?"WORD"`. Anything else on a `<<` line (e.g. a
# non-heredoc bitshift `1 << 2`, where `2` isn't a valid heredoc word) simply
# never matches and that line is passed through unchanged.
_commit_detect_strip_heredocs() {
    local raw="$1"

    case "$raw" in
        *'<<'*) ;;
        *)
            printf '%s' "$raw"
            return 0
            ;;
    esac

    local -a _cd_lines=()
    local _cd_line
    while IFS= read -r _cd_line || [ -n "$_cd_line" ]; do
        _cd_lines+=("$_cd_line")
    done <<<"$raw"

    local _cd_n=${#_cd_lines[@]}
    local -a _cd_out=()
    local i=0
    local _cd_re="<<(-)?[[:space:]]*('([A-Za-z_][A-Za-z0-9_]*)'|\"([A-Za-z_][A-Za-z0-9_]*)\"|([A-Za-z_][A-Za-z0-9_]*))"

    while [ "$i" -lt "$_cd_n" ]; do
        local _cd_opener="${_cd_lines[$i]}"
        local _cd_dash=0
        local _cd_word=""

        if [[ "$_cd_opener" =~ $_cd_re ]]; then
            [ -n "${BASH_REMATCH[1]}" ] && _cd_dash=1
            if [ -n "${BASH_REMATCH[3]}" ]; then
                _cd_word="${BASH_REMATCH[3]}"
            elif [ -n "${BASH_REMATCH[4]}" ]; then
                _cd_word="${BASH_REMATCH[4]}"
            else
                _cd_word="${BASH_REMATCH[5]}"
            fi
            local _cd_full_match="${BASH_REMATCH[0]}"

            # Find a matching terminator line among the remaining lines. A
            # `<<-` terminator may be indented with leading tabs; a plain
            # `<<` terminator must match with no leading whitespace at all
            # (real heredoc semantics — matches shell behaviour exactly).
            local _cd_term_idx=-1
            local j=$((i + 1))
            while [ "$j" -lt "$_cd_n" ]; do
                local _cd_tline="${_cd_lines[$j]}"
                if [ "$_cd_dash" -eq 1 ]; then
                    while [ "${_cd_tline:0:1}" = $'\t' ]; do
                        _cd_tline="${_cd_tline:1}"
                    done
                fi
                if [ "$_cd_tline" = "$_cd_word" ]; then
                    _cd_term_idx=$j
                    break
                fi
                j=$((j + 1))
            done

            if [ "$_cd_term_idx" -eq -1 ]; then
                printf '%s' "$raw"
                return 0
            fi

            local _cd_prefix="${_cd_opener%%"${_cd_full_match}"*}"
            local _cd_suffix="${_cd_opener#*"${_cd_full_match}"}"
            local -a _cd_ptoks=()
            local _cd_ptok
            while IFS= read -r _cd_ptok; do
                _cd_ptoks+=("$_cd_ptok")
            done < <(_commit_detect_tokenize "$_cd_prefix")
            local -a _cd_stoks=()
            local _cd_stok
            while IFS= read -r _cd_stok; do
                _cd_stoks+=("$_cd_stok")
            done < <(_commit_detect_tokenize "$_cd_suffix")

            local _cd_is_interp=1
            local _cd_k=0
            if [ "${#_cd_ptoks[@]}" -gt 0 ]; then
                _cd_is_interp=0
                while [ "$_cd_k" -lt "${#_cd_ptoks[@]}" ]; do
                    case "${_cd_ptoks[$_cd_k]}" in
                        bash | sh | zsh | dash | ksh | eval | source | . | */bash | */sh | */zsh | */dash | */ksh)
                            _cd_is_interp=1
                            break
                            ;;
                    esac
                    _cd_k=$((_cd_k + 1))
                done
            fi
            # M-audit W3 task 16: tokens AFTER the heredoc operator on the
            # SAME opener line (e.g. `cat <<EOF | bash` — the body is piped
            # to bash, which really executes it) were never scanned before
            # this fix, only PREFIX tokens were — so a heredoc fed to an
            # interpreter via a trailing pipe/redirect was misclassified as
            # a non-interpreter and its commit-containing body silently
            # stripped. An interpreter token anywhere in the suffix
            # overrides a non-interpreter prefix verdict; it never overrides
            # an already-interpreter prefix verdict downward.
            local _cd_k2=0
            while [ "$_cd_k2" -lt "${#_cd_stoks[@]}" ]; do
                case "${_cd_stoks[$_cd_k2]}" in
                    bash | sh | zsh | dash | ksh | eval | source | . | */bash | */sh | */zsh | */dash | */ksh)
                        _cd_is_interp=1
                        break
                        ;;
                esac
                _cd_k2=$((_cd_k2 + 1))
            done

            # todo row 10 (2026-08-16 repro): the heredoc OPERATOR
            # (`<<'MSG'`/`<<EOF`/...) and its TERMINATOR line are shell
            # redirection syntax — real bash strips both from the argv the
            # invoked program ever sees, they are never positional
            # arguments. The old code kept the operator embedded in the
            # opener line and re-appended the bare terminator word as its
            # own output line; extract_pathspecs' walk has no redirection
            # awareness, so `<<MSG` and `MSG` both survived tokenization as
            # unflagged tokens and were misread as positional pathspecs
            # (unmatched paths default to CODE in check-commit.sh, turning a
            # doc-only heredoc commit into a false MIXED deny). Emitting
            # prefix+suffix (the opener line's real command tokens with only
            # the `<<WORD` match excised) and never emitting the terminator
            # line models real shell argv exactly, in both branches below —
            # this is strictly more accurate, not more permissive: is_git_commit
            # detection is unaffected (its own tests, HEREDOC-a..j, stay
            # green) since prefix/suffix already carried every token that
            # mattered for the `git ... commit` walk.
            _cd_out+=("${_cd_prefix}${_cd_suffix}")
            if [ "$_cd_is_interp" -eq 1 ]; then
                # Interpreter-fed (or unidentifiable) — keep the body, it
                # really executes (or we can't prove it doesn't). The
                # terminator word itself is still dropped (see above).
                local _cd_m=$((i + 1))
                while [ "$_cd_m" -lt "$_cd_term_idx" ]; do
                    _cd_out+=("${_cd_lines[$_cd_m]}")
                    _cd_m=$((_cd_m + 1))
                done
            fi
            # Positively-identified non-interpreter case: body already
            # excluded (no `_cd_out` append) and the terminator is dropped
            # above — nothing further to emit for this heredoc.

            i=$((_cd_term_idx + 1))
            continue
        fi

        _cd_out+=("$_cd_opener")
        i=$((i + 1))
    done

    local _cd_result
    _cd_result=$(printf '%s\n' "${_cd_out[@]}")
    printf '%s' "$_cd_result"
}

# _commit_detect_parse <cmd> — internal shared walk, used by both public
# functions so they classify a command identically (never two implementations
# that could disagree). A raw multi-line command string is one or more
# separate commands — same root cause as the chain operators handled in
# _commit_detect_scan_segments, just spelled with a newline instead of `;`
# (M-audit finding #25). We try the whole string first (a bare embedded
# newline inside what is really one command, e.g. a wrapped `git\ncommit -m
# x`, tokenizes to a single flattened segment there, same as before this
# fix), then each suffix starting right after an embedded newline, so a
# `git commit` that only appears standalone on a later line is still caught.
# Stops at the first entry point that yields a committing segment (leftmost
# wins). Runs _commit_detect_strip_heredocs on <cmd> first (M-audit finding
# #21 residual) so a well-formed, non-interpreter-fed heredoc body is never
# a source of newline-suffix entry points — see that function's header for
# the full guard rationale. Sets globals:
#   _CD_TOKENS  — array of argv tokens for the COMMITTING segment
#   _CD_N       — token count of that segment
#   _CD_OK      — 1 if <cmd> is confirmed `git commit`, 0 otherwise
#   _CD_IDX     — index of the first token AFTER the `commit` subcommand
#                 (only meaningful when _CD_OK=1)
_commit_detect_parse() {
    local cmd="$1"
    _CD_TOKENS=()
    _CD_N=0
    _CD_OK=0
    _CD_IDX=0

    local _cd_stripped
    _cd_stripped=$(_commit_detect_strip_heredocs "$cmd")

    local _cd_rest="$_cd_stripped"
    local _cd_next
    while :; do
        if _commit_detect_scan_segments "$_cd_rest"; then
            return 0
        fi
        _cd_next="${_cd_rest#*$'\n'}"
        [ "$_cd_next" = "$_cd_rest" ] && break
        _cd_rest="$_cd_next"
    done

    _CD_OK=0
    return 0
}

# is_git_commit <cmd> — true (exit 0) iff <cmd> actually invokes `git commit`
# as the real command being run, per the argv walk above.
is_git_commit() {
    _commit_detect_parse "$1"
    [ "$_CD_OK" -eq 1 ]
}

# extract_pathspecs <cmd> — print, one per line, the positional pathspec
# arguments of a `git commit` invocation. Walks argv strictly after the
# `commit` subcommand token (never a blind slice after the last literal
# "commit" word, which would also match one cited inside the message body).
# Assumes <cmd> already passed is_git_commit; prints nothing otherwise.
extract_pathspecs() {
    _commit_detect_parse "$1"
    [ "$_CD_OK" -eq 1 ] || return 0

    local i=$_CD_IDX
    local seen_dashdash=0
    local tok

    while [ "$i" -lt "$_CD_N" ]; do
        tok="${_CD_TOKENS[$i]}"
        i=$((i + 1))
        if [ "$seen_dashdash" -eq 0 ]; then
            if [ "$tok" = "--" ]; then
                seen_dashdash=1
                continue
            fi
            case "$tok" in
                -m | --message | -c | -C | --reuse-message | --reedit-message | -F | --file | -A | --author | --date | --template | --fixup | --squash | --trailer)
                    i=$((i + 1)) # skip the flag's separate value token
                    continue
                    ;;
                --message=* | --reuse-message=* | --reedit-message=* | --file=* | --author=* | --date=* | --template=* | --fixup=* | --squash=* | --trailer=*)
                    continue
                    ;;
                -*)
                    continue
                    ;;
            esac
        fi
        printf '%s\n' "$tok"
    done
}

# gf_commit_skips_hooks <cmd> — true (exit 0) iff <cmd> is a real `git commit`
# (per is_git_commit) carrying `--no-verify` (or any prefix of it — the
# `case` arm below lists every one, fail-toward-deny, so this predicate never
# depends on which prefixes git would accept), or a single-dash short-flag
# cluster in which `n` appears before any value-taking short flag (`-n`,
# `-an`, `-na`, `-anm` — but not `-mnote`, where `m` consumes `note` as its
# glued value) — both skip the native ADR-004 pre-commit hook (F1-2). Walks
# argv strictly after the `commit` subcommand token, using the SAME
# flag/value-skip rules as extract_pathspecs above (so a `-m` value, e.g. a
# message body that merely mentions "-n", is skipped whole and never misread
# as the flag). False on a non-commit, or a commit with no such flag.
gf_commit_skips_hooks() {
    _commit_detect_parse "$1"
    [ "$_CD_OK" -eq 1 ] || return 1

    local i=$_CD_IDX
    local seen_dashdash=0
    local tok

    while [ "$i" -lt "$_CD_N" ]; do
        tok="${_CD_TOKENS[$i]}"
        i=$((i + 1))
        if [ "$seen_dashdash" -eq 0 ]; then
            if [ "$tok" = "--" ]; then
                seen_dashdash=1
                continue
            fi
            case "$tok" in
                --no-verify | --no-verif | --no-veri | --no-ver | --no-ve | --no-v)
                    # git's parse-options accepts any UNAMBIGUOUS long-option
                    # prefix (probed: `git status --shor` runs --short), so
                    # every prefix of --no-verify is matched, exact-literal.
                    # `--no-ver` and shorter are expected to collide with
                    # --no-verbose and be rejected by git as ambiguous — that
                    # was NOT probed (permission-denied in review), so they
                    # are denied here anyway: fail-toward-deny costs nothing on
                    # a form git would refuse, and removes the unverified
                    # claim. `--no-verbose` itself is not in the alternation
                    # (code-lead F1 r1/r2, 2026-08-30).
                    return 0
                    ;;
                -m | --message | -c | -C | --reuse-message | --reedit-message | -F | --file | -A | --author | --date | --template | --fixup | --squash | --trailer)
                    i=$((i + 1)) # skip the flag's separate value token
                    continue
                    ;;
                --message=* | --reuse-message=* | --reedit-message=* | --file=* | --author=* | --date=* | --template=* | --fixup=* | --squash=* | --trailer=*)
                    continue
                    ;;
                -[a-zA-Z]*)
                    # Single-dash short-flag cluster — -n itself, or -n fused
                    # with other boolean short flags (-an, -anm, ...). Walked
                    # char by char, not matched with a bare `*n*`: the first
                    # VALUE-taking short flag (m C c F t S u — message,
                    # reuse/reedit, file, template, gpg-sign, untracked-files)
                    # consumes the rest of the cluster as its glued value, so
                    # `-mnote` / `-m"no…"` is a message, never a hook-skip
                    # flag (HQ F1 self-review 2026-08-30: `*n*` produced a
                    # false --no-verify deny on a glued -m value).
                    local _cd_cl="${tok#-}" _cd_ch
                    while [ -n "$_cd_cl" ]; do
                        _cd_ch="${_cd_cl:0:1}"
                        _cd_cl="${_cd_cl:1}"
                        case "$_cd_ch" in
                            n) return 0 ;;
                            m | C | c | F | t | S | u) break ;;
                        esac
                    done
                    continue
                    ;;
                -*)
                    continue
                    ;;
            esac
        fi
    done
    return 1
}

# gf_commit_overrides_hookspath <cmd> — true (exit 0) iff <cmd> is a real
# `git commit` (per is_git_commit) whose tokens BEFORE `commit` carry
# core.hooksPath (key compared case-insensitively) in any of three forms:
# separate-value `-c core.hooksPath=X`, glued `-ccore.hooksPath=X`, or an
# env-assignment prefix token naming it (`GIT_CONFIG_PARAMETERS='core.hooksPath=X'`,
# or the `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_<n>=core.hooksPath` triple) —
# each redirects git to a different hooks directory, skipping the same native
# ADR-004 hook `--no-verify` does (F1-2). False on a non-commit, or a commit
# whose pre-`commit` tokens name no such key.
gf_commit_overrides_hookspath() {
    _commit_detect_parse "$1"
    [ "$_CD_OK" -eq 1 ] || return 1

    local i=0
    local _cd_commit_idx=$((_CD_IDX - 1))
    local tok

    while [ "$i" -lt "$_cd_commit_idx" ]; do
        tok="${_CD_TOKENS[$i]}"
        case "$tok" in
            -c)
                if [ "$((i + 1))" -lt "$_cd_commit_idx" ]; then
                    case "$(_commit_detect_lower "${_CD_TOKENS[$((i + 1))]}")" in
                        core.hookspath=*) return 0 ;;
                    esac
                fi
                i=$((i + 2))
                continue
                ;;
            -c*)
                case "$(_commit_detect_lower "$tok")" in
                    -ccore.hookspath=*) return 0 ;;
                esac
                ;;
            *=*)
                # Env-assignment form of the same override, sitting in the
                # VAR=val prefix the walk strips: `GIT_CONFIG_PARAMETERS=
                # 'core.hooksPath=x' git commit`, or the GIT_CONFIG_COUNT /
                # GIT_CONFIG_KEY_<n>=core.hooksPath triple. Either reaches git
                # exactly as `-c` does. A message body can never sit before
                # `commit`, so a substring test on these tokens is safe (HQ F1
                # self-review 2026-08-30).
                case "$(_commit_detect_lower "$tok")" in
                    *core.hookspath*) return 0 ;;
                esac
                ;;
        esac
        i=$((i + 1))
    done
    return 1
}

# _commit_detect_lower <str> — print <str> lower-cased. `tr`, not bash's
# `${var,,}`: that operator is bash 4.0+ and is a *bad substitution* on the
# bash 3.2 that macOS ships at /bin/bash (which `#!/bin/bash` pins), so the
# predicate above would abort — fail-OPEN at PreToolUse — on exactly the
# `-c core.hooksPath=` input it exists to catch (code-lead F1 r1, 2026-08-30).
# Nothing else in hooks/ uses a bash-4-only construct; keep it that way.
_commit_detect_lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

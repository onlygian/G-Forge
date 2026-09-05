# The Commit Gate

G-Forge's enforcement mechanism that blocks commits unless they have been explicitly reviewed and approved. The gate is the reason review cannot be skipped.

## How it works

The workflow is:

1. **Plan, execute, review** — you write code, then `/g-review` (or `/g-doc-review` for docs) runs the review agents
2. **Passing verdict** — the review issues MERGE READY (code) or an approval decision (docs) and stamps `.claude/g-forge-approved` (code) or `.claude/g-forge-docs-approved` (docs)
3. **git commit** — you run `git commit` from your terminal or Claude Code
4. **Two hooks check the sentinel** — a PreToolUse hook (early feedback) and a native `pre-commit` hook (final enforcement) verify the approval
5. **Commit proceeds** — only if the sentinel matches the exact tree being committed; the sentinel is consumed (deleted) after use

The gate refuses commits if:
- No sentinel exists yet (review hasn't run)
- The sentinel is stale (HEAD has moved since review, or the working tree has been edited since approval)
- The sentinel is in the wrong worktree (ADR-005 — in a linked `git worktree`, the gate is inherited from the primary tree)
- A mixed commit (code + docs) is missing either sentinel

## The sentinel stamp (ADR-004 binding)

When `/g-review` issues MERGE READY, it stamps three pieces of data into `.claude/g-forge-approved` as space-separated `key=value` fields:

- **`commit_sentinel_ts`** — the `git write-tree` hash of the staged+unstaged index at review time
- **`commit_sentinel_head`** — the git HEAD sha at review time (empty string on a first commit)
- **`commit_sentinel_worktree`** — the worktree identity from `git rev-parse --show-toplevel`

This three-field binding (verified in the `gf_validate_sentinel()` function in `hooks/pre-commit`) prevents two silent integrity holes documented in ADR-004:

1. **Edit-after-review (#8 content-blind):** If you edit a file after getting MERGE READY, the sentinel's tree hash no longer matches the new working tree, and the commit is denied.
2. **Stale approval on raw-terminal commits (#9 staleness):** If you commit from a bare terminal, the sentinel isn't cleaned up. The next commit would use a stale approval. The gate denies it because HEAD has moved.

The tree hash binding via `git write-tree` is the load-bearing mechanism — if the tree hashes differ, the sentinel is invalid.

## Two enforcement sites

The gate runs in **two places**, with the native `pre-commit` hook being authoritative (SOURCE: `hooks/pre-commit` lines 4–12):

### 1. PreToolUse hook (SOURCE: `hooks/check-commit.sh` lines 1–50)

Fires in Claude Code **before** git stages anything. Parses the invoked command via `hooks/lib/commit-detect.sh` to detect `git commit`, then checks for a sentinel file's **existence only**. If missing, it denies the tool call with a rich, model-facing reason (contract: `exit 2` + JSON permissionDecision deny).

**Why this isn't sufficient for enforcement:** PreToolUse fires before staging, so it cannot see what `git commit -a` or `git commit -p` (interactive) actually adds to the index. It also doesn't fire on raw-terminal commits.

### 2. Native git `pre-commit` hook (SOURCE: `hooks/pre-commit` lines 1–252)

Installed into `.git/hooks/pre-commit` (per lines 33–38: installed by `/g-init` step 6a and `/g-update` step 7a). Runs natively whenever git is about to commit, regardless of whether Claude Code invoked it. This hook:

1. Runs `git write-tree` on the **final staged index** to get the actual tree hash (lines 154–155)
2. Reads the sentinel and parses its stamp via `hooks/lib/sentinel-read.sh` (line 58)
3. Verifies all three fields: tree hash, HEAD sha, worktree key (lines 79–98: `gf_validate_sentinel`)
4. Denies if any field doesn't match; permits and **consumes** (deletes) the sentinel if all three pass (lines 226–248)

This hook is the authoritative gate because it fires on **every** commit and verifies the tree hash at the moment git has finalized the index. The tree hash is reproducible: git's own normalized identifier of what will be committed.

## Dual sentinels for mixed commits (SOURCE: `hooks/pre-commit` lines 233–248)

If you commit both code *and* documentation changes, the gate requires **both** sentinels to be present and valid. Each sentinel carries the same `commit_sentinel_ts` + `commit_sentinel_head` pair (the same reviewed tree), ensuring you can't sneak unreviewed code past a doc-only review, or vice versa.

File classification happens in the shared lib `hooks/lib/classify-changeset.sh` (lines 104–202), used by both `check-commit.sh` and `pre-commit`:

- **Code class:** executable files, instructions (scripts, configs, source code), including nested `.md` files like `skills/*/SKILL.md` (plugin behavior, not prose)
- **Doc class:** narrative documentation — `g-docs/`, `g-wiki/`, `docs/` trees (line 127), plus root-level `README*`, `CHANGELOG*`, `LICENSE*`, and `*.md` at repo root only (nested `*.md` gates as code, lines 193–194)
- **Reference class:** `reference/<bundle>/` entries with marked bundles (`SNAPSHOT.md` or `NOTE.md` present, line 167); exempt-with-advisory (lines 281–282)
- **Mixed:** both code and doc present in the staged set
- **None:** empty or unknown (falls back to code class, the stricter gate)

## Why two sites despite the overlap?

The PreToolUse hook alone cannot see the final tree (it fires before staging). The native hook alone would give the model no feedback on why a commit was blocked. Together:

- **PreToolUse** provides early feedback and denies before git is even invoked
- **Native hook** is the canonical, payload-independent enforcement that actually blocks the commit

This separation enforces the two-class hook contract (SOURCE: `hooks/pre-commit` lines 14–23):
- Claude Code plugin hooks (PreToolUse): JSON stdin, JSON deny, `exit 2` to block
- Native git hooks (pre-commit): stderr reason, `exit 1` to block, no JSON

Both exit with non-zero, both deny—different protocols, same guarantee.

## Fail-toward-deny polarity

If anything goes wrong — unparseable JSON, missing tools, git commands failing, timeout on stdin — the gate defaults to **denying** the commit, with one exception:

- **PreToolUse stdin timeout (v2.3.0):** On a 5-second read timeout from an abandoned tool call (SOURCE: `hooks/check-commit.sh` lines 88–104), the input is incomplete/lost. PreToolUse fails OPEN because the native `pre-commit` hook (ADR-004 lines 4–12) is the authoritative, payload-independent backstop. A stalled stdin on PreToolUse is a tooling hiccup, not a security signal.

**Project guard:** Both hooks check for `.claude/integration-tier` (or the primary tree's copy in a worktree via `hooks/lib/worktree-resolve.sh`). If absent, they exit 0 silently — the gate only applies to projects that ran `/g-init`.

**Worktree resolution (ADR-005, SOURCE: `hooks/pre-commit` lines 100–131):** In a linked `git worktree`, the `.claude/` directory is gitignored and normally absent. Both hooks resolve the primary tree's `.claude/` via `git rev-parse --git-common-dir`, so a worktree of a gated project inherits the gate. Ambiguous worktree resolution (nested trees, `--separate-git-dir`, submodules) fails closed — denies the commit rather than guessing.

## The review pack (M53 — v2.6.0)

The review pack (SOURCE: `skills/g-review/scripts/build-review-pack.sh` lines 2–58) is a deterministic, immutable context artifact built once per review round. Built by `build-review-pack.sh`, which outputs `KEY: value` lines (lines 27–52: output contract):

- **PACK_DIR:** `g-docs/agent-output/review/pack-<YYYY-MM-DD>-<slug>-r<N>` — one per round, never deleted
- **ROUND:** N — highest-plus-one across existing pack dirs and agent records (lines 189–196)
- **MODE:** `full` or `delta` — determined by round eligibility (lines 200–247)
- **PACK_TREE:** the `git write-tree` hash of the staged+unstaged union (same binding as ADR-004 stamping)
- **DIFF_SOURCE:** `staged-union` (reviewed state) or `mainline-fallback` (when no staged changes)

Pack layout (immutable once built, line 54):
- **Full mode:** MANIFEST, diff.patch (complete changeset), files.txt (file list), slices/ (full current content of every file in the diff)
- **Delta mode:** same, but fix-delta.patch instead of diff.patch, plus prior/records.txt (list of prior-round output files) and prior/claimed-closed.txt (findings claimed fixed)

The tree hash binding ensures the pack is bound to the exact review boundary.

## Delta review rounds (HOLD rounds ≥2)

When a commit fails review and is re-reviewed, the second round (R2) and later can run in **delta mode** instead of re-reviewing the entire diff (SOURCE: `skills/g-review/references/round-consolidation.md` lines 14–32, and `skills/g-review/scripts/build-review-pack.sh` lines 200–247).

A delta round:
- Compares the PACK_TREE of the current round against the prior round's PACK_TREE (lines 218–238: fix-delta generation and file-set validation)
- Generates only the fix delta (`git diff prior-tree current-tree`)
- Packs only the files in that delta, plus prior records and claimed-closed findings

**Eligibility (lines 200–247):** Delta mode is automatically used if:
- ROUND > 1 (not the first round)
- A readable prior pack exists for the same date+slug series (lines 210–214)
- All prior-round output files exist in `g-docs/agent-output/review/` (lines 223–227)
- Every file in the fix delta was in the prior-round reviewed set, or force-full override is set (lines 230–244; escapes: `fix-outside-reviewed-set`, `no-prior-pack`, `prior-record-missing`, or `--force-full`)

**Round consolidation:** If a finding class (Critical or Major) recurs across three or more consecutive rounds, consolidate the repeated facts into one source of truth instead of patching (SOURCE: `round-consolidation.md` lines 14–28: procedure to count consecutive round appearances per finding class).

## Escape hatches

The gate can be disabled per project (via `/g-tier light`, which sets TIER to "light" — checked at `hooks/pre-commit` lines 138–141) or bypassed per commit (`git commit --no-verify`, detected and denied at `hooks/check-commit.sh` lines 198–202). Both are deliberate opt-outs, not hidden back doors.

## See also

- [Architecture](architecture.md) — the full plugin architecture, including how skills and hooks fit together
- [Usage](usage.md) — how to invoke `/g-review`, `/g-doc-review`, and the full workflow
- [ADR-004: Bind the review sentinel to the reviewed tree](../g-docs/decisions/004-bind-sentinel-to-reviewed-tree.md)
- [ADR-005: Define what the commit gate means inside a git worktree](../g-docs/decisions/005-worktree-enforcement-semantics.md)

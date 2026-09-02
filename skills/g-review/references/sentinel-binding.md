# Sentinel binding — why the reviewed surface is the staged∪unstaged union (ADR-004)

Load when editing the pack builder, the Step 6 sentinel path, or when the
stamped tree and the committed tree disagree. The operational rule lives in the
core and in `scripts/build-review-pack.sh`; this file carries the rationale.

## The union
The primary review target is the tree the sentinel will bind to at commit time —
the staged set unioned with unstaged-but-tracked modifications, the same union
`hooks/check-commit.sh`'s `-a`/`--all` handling already computes. This is what
`git write-tree` will hash if the developer commits as-is (including via
`git commit -a`), so reviewing it is what makes the sentinel binding coherent
(ADR-004): reviewed tree == stamped tree == committed tree, closed with one hash.

## The fallback
If that union is empty, the diff falls back to `git diff <mainline>...HEAD` —
this covers resuming review on a branch that already carries
committed-but-unreviewed history (e.g. an interrupted multi-commit session).
This fallback role is unchanged from before the v2.5 diff-target flip; only the
priority is inverted. When the fallback fires, the index already equals HEAD's
tree and no extra staging is needed for the stamp.

## The stamp computation (now inside the pack builder)
`commit_sentinel_ts` binds the sentinel to the exact reviewed tree: stage the
unstaged-but-tracked part of the union (`git add -u` — scoped
`git add -u -- <path>` on a scoped doc review, never an unscoped add on a
scoped review), then take `git write-tree`. This reproduces the same tree
`hooks/pre-commit`'s own `git write-tree` will hash at commit time, whether the
developer commits with plain `git commit` or `git commit -a`, keeping the
stamped tree and the committed tree identical. The pack builder performs this
computation on a **temporary copy of the index** (`GIT_INDEX_FILE`), so the real
index is never mutated by building a pack — `PACK_TREE` in the pack MANIFEST is
ADR-004's binding computed once, and Step 6 stamps that value after a
`--check` confirms the tree has not moved since the pack was built.

## Mainline resolution ladder (shared statement)
Resolve `<mainline>` once and reuse it: the current branch's configured remote
(`git config --get branch.<branch>.remote`, else `origin`), then the first of
`refs/remotes/<remote>/HEAD` (short name, remote prefix stripped), `main`,
`master` that `git rev-parse --verify` accepts. This chain is implemented in
`scripts/build-review-pack.sh` and mirrored in
`skills/g-resume/scripts/sync-check.sh` — it deterministically encodes the
hardcoded-`main` fix (F2-6 twin class) so the audited wording cannot regress.

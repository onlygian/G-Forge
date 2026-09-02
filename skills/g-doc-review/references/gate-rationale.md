# Doc-gate rationale — union binding, fallback history, dispatch boundary

Load when editing Step 1/Step 4 mechanics or questioning why this gate detects
changes the way it does.

## Why the staged∪unstaged-tracked union (ADR-004)
The primary target is the staged index tree the sentinel will bind to at commit
time. To cover what `git commit -a` would fold in, the changed set unions the
staged files with unstaged-but-tracked modifications — the same union
`hooks/check-commit.sh`'s `-a`/`--all` handling already computes. Reviewing
this union means the review covers what would be committed with
`git commit -a`, ensuring that staging the union before the Step 4 stamp makes
the stamped tree coherent with the reviewed tree (ADR-004). The pack builder
computes the stamp tree (`PACK_TREE`) on a temporary index copy, so building a
pack never mutates the real index; on a scoped (path-argument) review the
staging is `git add -u -- <path>` — never an unscoped add on a scoped review
(the deliberate, declared index write of an otherwise read-only gate).

## Fallback history
If the union is empty, the gate falls back to `<mainline>...HEAD` — covering a
branch that already carries committed-but-unreviewed history (e.g. an
interrupted multi-commit session). This fallback role is unchanged from before
the v2.5 diff-target flip; only the priority was inverted. The mainline
resolution ladder (configured remote else `origin`; remote HEAD, `main`,
`master`, first that verifies) is implemented once in
`build-review-pack.sh` — the deterministic encoding of the F2-6/R-4
hardcoded-`main` fix, so the audited wording cannot regress.

## Dispatch boundary
This gate dispatches `doc-reviewer` **directly** — `review-orchestrator` is the
code-review pipeline's aggregator (and is itself inert as shipped); routing doc
review through it would put a code-severity normalizer between the gate and the
BLOCKING/WARNING/PASS contract for no benefit. The mixed-commit rule: when
`/g-review` also stamps `.claude/g-forge-approved` for the same tree, both
sentinels carry the identical stamp — one tree, one hash, two gates.

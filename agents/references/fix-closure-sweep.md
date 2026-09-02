# Fix-closure sweep — shared rationale (code-lead + doc-reviewer)

Maintainer-facing rationale. NOT read by dispatched agents — each agent core
keeps the three operational bullets and the clause "a closure claim with no
recorded sweep evidence does not count as closed"; this file holds the why.

The sweep runs while the reviewer is alive and dispatched, as part of the
review — not as a follow-up step by another actor — because the reviewer is the
only party holding the finding context at the moment closure is claimed, and a
deferred sweep is a sweep that silently never happens. code-lead's sweep is the
code-side mirror of doc-reviewer's (`agents/doc-reviewer.md`); the two
contracts are kept in step deliberately.

The evidence demanded is checkable, not a prose claim of "verified": the exact
literal fact the fix changed (a count, a `file:line` citation, a name, a
version number), the grep command run across the whole repo — not just the
touched file — and the grep output, recorded in the reviewer's own review
record under `g-docs/agent-output/review/`. A stale copy of the old fact
surviving elsewhere is a Currency-class defect — the fix corrected one carrier
and left a sibling stale — and HQ's record check (/g-review Step 4b,
/g-doc-review Step 2b) converts an unevidenced claim into an effective HOLD.
The skill-side long form lives in each gate's
`references/fix-closure-sweep.md`.

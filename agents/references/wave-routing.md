# wave-planner — routing narratives (maintainer reference)

Maintainer-facing; not read at dispatch. Backing elaborations for the compressed
decision rules in `agents/wave-planner.md` Step 3.

## Multi-stack monorepo tie-break

When more than one discovered `<stack>-implementer` matches a task's files (overlapping
`owns:` globs in a multi-stack monorepo), the **most specific** pattern wins: the
longest / deepest glob, or the one matching by file extension over a bare directory
match. Example: `src/components/**` (vue-implementer) vs `src/**` (a broad fallback) —
the deeper `src/components/**` wins for a component file. If specificity still ties,
tag `feature-implementer` rather than guess: a wrong stack routing puts a stack-idiom
implementer on files whose conventions it will misapply, which costs a review round;
the generic implementer is the safe default.

## Single-stack projects

In a single-stack project there is exactly one installed implementer and its globs
cover the whole stack — route all implementation tasks to it. The matching machinery
exists for the multi-stack case; it degrades to "always that one" when only one is
installed.

## Grant check — mechanism-produces-effect

Beyond tool-grant sufficiency (a done condition requiring a file write needs
`Write`/`Edit` on the assignee), the check also asks whether the stated mechanism can
actually produce the claimed effect — e.g. reordering serial steps cannot itself reduce
total runtime, so a task whose done condition claims a runtime reduction from
reordering alone is a decomposition defect. Flag such tasks back to the decomposition
rather than tagging them silently and letting an executor discover the impossibility
mid-wave.

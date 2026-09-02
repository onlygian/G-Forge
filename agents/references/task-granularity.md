# task-decomposer — granularity carve-out and self-check rationale (maintainer reference)

Maintainer-facing; not read at dispatch. Backing narratives for `agents/task-decomposer.md`.

## The same-file serial-chain carve-out — recorded failure (2026-07-28)

The carve-out ("a same-file serial chain of edits is ONE task, takes precedence over the
one-action rule, never key on task count") exists because of a recorded failure: on
2026-07-28 the decomposer emitted 11 tasks where 5 were sequential edits to the same
file — each edit depending on the state left by the previous one — and the wave schedule
had to group those 5 into a single agent slot downstream. The "more tasks looks more
thorough" instinct produced work that `wave-planner` immediately had to undo. Decompose
it correctly the first time: key granularity on **same file + serial/sequential
dependency**, even when that drops the emitted total well below what looks thorough.
Do not split a same-file sequential chain into one task per edit and leave the collapse
to `wave-planner`.

## The pre-return self-check — why it exists

The self-check (re-read the `output_file` to confirm the write landed; confirm the
compact block is non-empty before returning) guards against a real failure shape: an
agent that believes its `Write` succeeded, returns an empty or hollow compact block, and
leaves the calling session to discover the missing task list and resume the work
manually. An about-to-be-empty return is a self-check failure the agent corrects itself
before returning — never something to hand back to the caller.

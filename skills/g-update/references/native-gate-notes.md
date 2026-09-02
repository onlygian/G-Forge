# Step 7a background — native pre-commit gate rationale

Load when editing Step 7a or when a developer asks why the native gate is
handled apart from the Claude-Code hooks. The operational branches
(absent / G-Forge-managed / foreign, the lib realign, chmod) stay in SKILL.md
Step 7a — this file holds the why.

## ADR-004 — the authoritative enforcement site

The commit gate's authoritative enforcement site is a **native git hook**,
`[plugin-root]/hooks/pre-commit` — installed straight into the consumer repo's
real git hooks directory, never into `.claude/hooks/`. `.claude/hooks/` only
ever holds Claude-Code-invoked scripts (the ones registered in
`.claude/settings.json`); a native git hook is invoked by `git` itself and
`.claude/settings.json` has no say over it, which is why it needs its own
realignment pass and why no settings entry helps or harms it.

## Why `git rev-parse --git-path hooks`, never `.git/hooks/`

Assuming `.git/hooks/` breaks in two real configurations: a custom
`core.hooksPath`, and linked worktrees (where `.git` is a file, not a
directory). `git rev-parse --git-path hooks` resolves the directory git will
actually consult in both cases — the only `<hooks-dir>` worth installing into.

## Why pre-commit gets no `.claude/settings.json` entry

Git invokes `pre-commit` natively on every `git commit`, the same way it
invokes any other native git hook. An entry in `.claude/settings.json` would
be a no-op at best and a confusing duplicate at worst — a reader could
conclude the settings entry is what enforces the gate and "fix" it there.

## ADR-011 — derive-don't-type (the 4-of-6 lib install story)

The native `pre-commit` hook sources its shared libs from its own directory at
runtime (the set is whatever `hooks/pre-commit`'s `. "$_GF_HOOK_DIR/lib/…"`
lines name — read them, never restate them), denying every commit with an
internal error if any is missing. Step 7a therefore enumerates the canonical
set **from disk** — `ls [plugin-root]/hooks/lib/*.sh` — never from a typed
list of lib names. A hardcoded list is exactly how `/g-init` once shipped a
4-of-6 lib install undetected: two libs were added to `hooks/lib/` and never
to any enumeration, and the defect passed the commit gate, a full review
pipeline, `/g-doctor`, and a release, because it never appeared in a diff.
`tests/test-lib-install-completeness.sh` now derives the truth from the code
and asserts every documenting surface agrees.

The lib realign runs only on the absent and G-Forge-managed branches — never
when the existing `pre-commit` is foreign, because populating a foreign hook's
`lib/` directory would be writing into machinery this skill does not own.

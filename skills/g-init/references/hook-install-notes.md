# Hook install — history and rationale (Steps 6 + 6a)

Load this only when the install hits a `MISSING:`/`foreign` edge or a maintainer asks why the mechanics are shaped this way. (Overlaps `hooks/pre-commit`'s own header, ADR-004, and `tests/test-lib-install-completeness.sh`'s header — those stay authoritative; this is the operator's copy.)

## Why hooks are copied verbatim, never inlined (Step 6)

All hook scripts are **copied verbatim from the plugin cache** rather than inlined in the skill, so a fresh `/g-init` installs the same canonical hook bodies that `/g-update` and `hooks/*.sh` in the plugin source ship. Inlining them in the skill previously caused divergence — new projects ran the pre-M15 hooks until `/g-update` was run.

The `lib/` files are `source`d by the top-level hooks, never executed directly, so the executable bit is optional for them; the top-level hooks get `chmod +x` (best effort — on Windows, file mode bits may not apply but Claude Code still runs the script via bash).

## The two commit-gate sentinels

The commit gate has **two sentinels**: `post-commit-cleanup.sh` deletes both `.claude/g-forge-approved` (the code-review gate, written by `/g-review` on MERGE READY) and `.claude/g-forge-docs-approved` (the doc-review gate, written by `/g-doc-review` on DOCS READY) after every successful commit, so both gates reset together.

## Why the native pre-commit hook is authoritative (Step 6a, ADR-004)

ADR-004 makes the native git `pre-commit` hook (`<plugin-hooks>/pre-commit`) — not the PreToolUse `check-commit.sh` hook installed in Step 6 — the authoritative enforcement site for the commit gate: it fires after `git commit` has already staged the true to-be-committed tree, so it sees things PreToolUse cannot (e.g. `git commit -a`/`-p`, raw-terminal commits). It had never been installed by `/g-init` until this step existed. Installing the `pre-commit` script by itself is not the full deliverable: it `source`s several `lib/` scripts from its own directory at runtime and denies every commit with an internal-error message if any is missing — which is why the same step installs `<git-hooks-dir>/lib/`.

The hooks directory is resolved with `git rev-parse --git-path hooks` — never a fixed default path. This honors `core.hooksPath` overrides and, in a linked worktree, correctly resolves to the primary checkout's shared hooks directory rather than a per-worktree path.

## Why the lib set is derived from disk, never typed (ADR-011)

The canonical lib set is whatever `hooks/pre-commit`'s `. "$_GF_HOOK_DIR/lib/…"` lines name — enumerate it from disk (`ls <plugin-hooks>/lib/*.sh`), never restate it as a list. A hardcoded list is exactly how `/g-init` once shipped a 4-of-6 lib install undetected, because every reader of that list iterated the same short set — `tests/test-lib-install-completeness.sh` pins this (derive-don't-type, ADR-011).

## Foreign pre-commit hooks

A previous G-Forge install is recognized by the literal string `G-Forge commit gate` in the hook's first lines (the canonical `hooks/pre-commit`'s own line-2 header) and is safely overwritten. Anything else is a developer- or another-tool-installed hook: it is left untouched, nothing is installed on that branch (lib/ included), and the skill surfaces the warning naming the path.

# The Commit Gate

G-Forge's flagship enforcement feature: a hard gate that blocks commits unless they have been explicitly reviewed and approved. The gate is the reason review can't be skipped.

## How it works

The workflow is simple:

1. **Plan, execute, review** — you write code, then `/g-review` (or `/g-doc-review` for docs) runs the review agents
2. **Passing verdict** — the two review paths are separate pipelines: `/g-review`'s code-lead issues MERGE READY and stamps `.claude/g-forge-approved` (code), while `/g-doc-review` issues DOCS READY and stamps `.claude/g-forge-docs-approved` (docs)
3. **git commit** — you run `git commit` from your terminal or Claude Code
4. **Gate checks the sentinel** — two hooks intercept the commit and verify the approval is valid
5. **Commit proceeds** — only if the sentinel matches the exact code tree being committed; the sentinel is consumed (deleted) after use

The gate refuses commits if:
- No sentinel exists yet (review hasn't run)
- The sentinel is stale (HEAD has moved since review, or the working tree has been edited since MERGE READY)
- The sentinel is in the wrong worktree (ADR-005 — in a linked `git worktree`, the gate is inherited from the primary tree)
- A mixed commit (code + docs) is missing either sentinel

## The sentinel stamp

The sentinel file isn't just an approval flag—it's **bound to the exact tree you reviewed**. When `/g-review` issues MERGE READY, it writes three pieces of data into the sentinel (as `key=value` space-separated fields on one line):

- **`commit_sentinel_ts`** — the `git write-tree` hash of the staged+unstaged index at review time (what will actually be committed)
- **`commit_sentinel_head`** — the git HEAD sha at review time (tracks staleness)
- **`commit_sentinel_worktree`** — the worktree identity from `git rev-parse --show-toplevel` (enforced per ADR-005)

This design—the **ADR-004** decision—prevents two silent integrity holes:

1. **Edit-after-review:** If you edit a file after getting MERGE READY, the sentinel's tree hash no longer matches the new working tree, and the commit is denied.
2. **Stale approval on raw-terminal commits:** If you commit from a bare terminal (outside Claude Code), the sentinel doesn't get cleaned up. The next commit in Claude Code would use the stale approval. The gate denies it because HEAD has moved.

Content-binding via `git write-tree` is the load-bearing mechanism—if the tree hashes differ, the sentinel is invalid.

## Two enforcement sites

The gate runs in **two places**, and the second one is authoritative (see ADR-004):

### 1. PreToolUse hook (`hooks/check-commit.sh`)

Fires in Claude Code **before** git stages anything. Parses the invoked command via `hooks/lib/commit-detect.sh` to detect `git commit`, then checks for a sentinel file. If missing, it denies the tool call with a rich, model-facing reason.

**Timing consequence — stamp and commit in separate tool calls.** The gate evaluates *before* the Bash command runs, so a single invocation that stamps a sentinel and then commits (`… && git commit`) is always denied: the sentinel does not exist yet when the gate looks. Run `/g-review` / `/g-doc-review` to completion first, then commit in a later call.

**Why this isn't enough:** PreToolUse fires before staging, so it can't see what `git commit -a` or `git commit -p` (interactive) actually adds to the index—it would hash the wrong tree. It also doesn't fire on raw-terminal commits.

### 2. Native git `pre-commit` hook (`hooks/pre-commit`)

Installed into the repository's git hook path (`.git/hooks/pre-commit`). Runs natively whenever git is about to commit, regardless of whether Claude Code invoked it. This hook:

1. Runs `git write-tree` on the **final staged index** to get the actual tree hash
2. Reads the sentinel and parses its stamp (via `hooks/lib/sentinel-read.sh`)
3. Verifies all three fields: tree hash, HEAD sha, worktree key
4. Denies if any field doesn't match; permits and **consumes** (deletes) the sentinel if all three pass

This hook is the authoritative gate because it fires on **every** commit—terminal commits, `git commit -a`, interactive staging, all paths. The tree hash it verifies is reproducible: git's own normalized identifier of what will be committed, accounting for clean filters and `.gitattributes`.

## Dual sentinels for mixed commits

If you commit both code *and* documentation changes, the gate requires **both** sentinels to be present and valid. Each sentinel carries the same `commit_sentinel_ts` + `commit_sentinel_head` pair (the same reviewed tree), ensuring you can't sneak unreviewed code past a doc-only review, or vice versa.

File classification happens in the shared lib `hooks/lib/classify-changeset.sh`, used by both `check-commit.sh` and `pre-commit`:

- **Code class:** executable files, instructions (scripts, configs, source code) — including **nested** `.md` files like `skills/*/SKILL.md` and `agents/*.md`, which are plugin behavior, not prose
- **Doc class:** narrative documentation — root-level `*.md`/`README*`/`CHANGELOG*`/`LICENSE*` and the `g-docs/`, `g-wiki/`, `docs/` trees only
- **Mixed:** both present in the staged set

**Known false-positive: nested `README*`.** Only *root-level* `README*`/`CHANGELOG*`/`LICENSE*` are doc class; a nested one (e.g. a provenance note at `benchmarks/quality-eval/README.md`) is code class, deliberately — fail toward the stricter gate. A pass that only edits such a file is therefore a **mixed** commit needing both `/g-review` and `/g-doc-review` sign-offs. Data-directory provenance notes are the common trigger. To keep a doc-only pass doc-class, put the note under `g-docs/`, `g-wiki/` or `docs/` (or at the repo root) and link to it from the data directory. The classifier has no carve-out for them.
- **None:** empty or unknown (falls back to code class, the stricter gate)

## Why two sites despite the redundancy?

The PreToolUse hook alone can't see the final tree. The native hook alone would give the model no feedback on why a commit was blocked. Together:

- **PreToolUse** provides early feedback and denies before git is even invoked, saving a round trip
- **Native hook** is the canonical, payload-independent enforcement that actually blocks the commit

This separation also matches the **two-class hook contract** (a design constraint documented in the architecture rules):

- Claude Code plugin hooks (PreToolUse/PostToolUse): JSON stdin, JSON deny, `exit 2` to block
- Native git hooks (pre-commit): stderr reason, `exit 1` to block, no JSON

Both exit with non-zero, both deny—different protocols, same guarantee.

## Fail-toward-deny polarity

If anything goes wrong—unparseable JSON, missing tools, git commands failing, timeout on stdin—the gate defaults to **denying** the commit. Exceptions:

- **PreToolUse stdin timeout (v2.3.0):** On a 5-second read timeout from an abandoned tool call, the input is incomplete/lost. PreToolUse fails OPEN because the native `pre-commit` hook (ADR-004) is the authoritative, payload-independent backstop. A stalled stdin on PreToolUse is a tooling hiccup, not a security signal—the native hook always fires and will enforce correctly.
- **Non-G-Forge projects:** Both hooks check for `.claude/integration-tier` (or the primary tree's copy in a worktree). If it's absent, they exit 0 silently—the gate only applies to projects that ran `/g-init`.

**Worktree resolution (ADR-005):** In a linked `git worktree`, the `.claude/` directory is gitignored and normally absent. Both hooks resolve the primary tree's `.claude/` via `git rev-parse --git-common-dir` and `hooks/lib/worktree-resolve.sh`, so a worktree of a gated project inherits the gate. Ambiguous worktree resolution (nested trees, `--separate-git-dir`, submodules) fails closed—denies the commit rather than guessing.

## The stdin read timeout guard (v2.3.0)

All seven stdin-reading hooks—including the PreToolUse gate—now use `hooks/lib/stdin-read.sh` to bound reads. When Claude Code abandons a tool call mid-stream, stdin stays open with no EOF, and a bare `cat` blocks forever. On Windows Git Bash, this timeout is unenforced, and production saw two 66-minute orphaned processes.

The shared library provides `gf_read_stdin_timeout`, using bash builtins (no `timeout` coreutil dependency, cross-platform). On timeout, the input is partial/empty, and the hook degrades gracefully:

- **PreToolUse:** empty input → no commit detected → exit 0 (native hook is the backstop)
- **Observe, agent-lifecycle, cleanup, checkpoint, compact, session-start:** degrade silently (read-only hooks)
- **Native pre-commit:** never uses the timeout helper (it reads directly from git, not stdin)

## Escape hatches

The gate can be disabled per project (via `/g-tier light`) or bypassed per commit (`git commit --no-verify`), but both are deliberate opt-outs, not hidden back doors. They're out of scope for the gate itself—the gate's job is to enforce when armed.

## See also

- [Architecture](architecture.md) — the full plugin architecture, including how skills and hooks fit together
- [Usage](usage.md) — how to invoke `/g-review`, `/g-doc-review`, and the full workflow
- [ADR-004: Bind the review sentinel to the reviewed tree](../g-docs/decisions/004-bind-sentinel-to-reviewed-tree.md)
- [ADR-005: Define what the commit gate means inside a git worktree](../g-docs/decisions/005-worktree-enforcement-semantics.md)

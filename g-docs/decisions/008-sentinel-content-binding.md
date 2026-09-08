# 008 — Sentinel content-binding (diff-hash stamping contract)

**Date:** 2026-07-02
**Status:** Accepted (design) — pending implementation (M-audit-2026-07 Wave 1, item 8)
**Reversibility:** two-way door — the sentinel format is internal to the gate; changing it later only requires a version bump of the sentinel schema (see Edge-case matrix, "legacy" row).
**Context:** Forge Integrity audit finding 8 (Major). `/g-review` writes `.claude/g-forge-approved` at MERGE READY, but the sentinel is a flat `approved` marker with no binding to the reviewed content. Any edit made after the verdict — including edits to files the reviewer never saw — still passes `check-commit.sh`'s gate, because the gate only checks *existence* of the sentinel, never *what* it was approved for.

This note is the spike/ADR required before implementation (`g-docs/milestones/M-audit-2026-07.md` execution notes: "Wave 1 items 8–10 need design decisions before implementation"). It is precise enough for a cheap executor to implement without judgment calls. No code changes are made by this note.

## Design

### The timing seam (the crux)

The sentinel is written at **review time** (`/g-review` Step 6, `skills/g-review/SKILL.md:135`) but checked at **gate time** (`check-commit.sh`, on `git commit`). Between those two moments, the working tree can change in ways the reviewer never saw. The binding must therefore be a hash that is:

1. **Computable at review time**, when the reviewed changes may be unstaged, partially staged, or already committed to the feature branch (code-lead reviews a diff — `git diff` against a base ref — not necessarily a staged index).
2. **Reproducible at gate time**, when HQ has staged the files for commit (`git add`) and the hook reads `git diff --cached`.

These are two different git states (working tree / branch-vs-base at review time vs. the staged index at gate time), so hashing the literal staged tree at review time is not an option — nothing may be staged yet when `/g-review` runs. The binding must instead hash **the same logical content** through a projection that is stable across that gap: the set of tracked file paths and their blob contents that differ from the merge-base, independent of whether those diffs currently live in the working tree, the index, or a branch tip.

### Hash choice — content hash of the reviewed diff's resulting blobs, keyed by path

**Chosen approach:** at review time, compute the hash over the **sorted list of `path + blob-sha` pairs for every file that differs from `merge-base`**, using each file's **current on-disk content** (working tree if dirty, else index, else `HEAD`) — not a single `git write-tree` and not `git diff | hash-object`. Concretely:

```
git diff --name-only $(git merge-base main HEAD) -- .
```
gives the reviewed file set. For each path, take its content hash via `git hash-object <path>` (working-tree content) if the path exists on disk, or the null-hash sentinel `0000000000000000000000000000000000000000` if the path was deleted. Sort the `path<TAB>blob-sha` lines, then hash the joined list with `git hash-object --stdin`. This final value is **the sentinel hash**.

At gate time, recompute the identical projection but read blobs from the **staged index** instead of the working tree: `git diff --cached --name-only` for the file set, and `git ls-files --stage <path>` (or `git hash-object <path>` on the working copy that was staged — see below) for each blob sha. Compare the two path+blob-sha manifests.

**Why this, vs. alternatives:**

- **`git diff --cached | git hash-object --stdin` (raw diff text hash)** — rejected. This hash is only computable once something is staged, so it cannot be produced at review time (nothing may be staged yet — code-lead reviews working-tree or branch diffs). It would force `/g-review` to stage files itself, which crosses into HQ's job (staging happens after approval, per the audit's own framing) and risks staging things the reviewer didn't intend to approve.
- **`git write-tree` (full tree object hash)** — rejected. This hashes the *entire* tree, not just the reviewed diff, so any unrelated concurrent change elsewhere in the repo (e.g. a rebase touching unrelated files, or an out-of-band edit to an untouched file) would falsely invalidate the sentinel. It also requires a populated index to exist at review time, which — as above — it may not.
- **Path+blob-sha manifest over the merge-base diff (chosen)** — computable from whichever content source exists at each moment (working tree at review time, staged index at gate time) because a blob's SHA-1 is a pure content hash independent of whether it currently sits in the working tree, the index, or a commit. This is the only option that survives the working-tree-then-index transition without requiring the reviewer to pre-stage anything.

### Reproducibility note

`git hash-object <path>` on a working-tree file and the blob SHA that ends up in the index after `git add <path>` are **identical** (git's blob hash is defined purely over `"blob " + size + "\0" + content`, independent of index/tree/commit context). This is what makes the path+blob-sha manifest reproducible across the review→stage→commit timing gap: HQ staging the exact files code-lead reviewed reproduces the same blob shas, so the manifest — and therefore the final hash — matches. Any file edited between review and staging produces a different blob sha for that path, and the manifest hash changes, which is exactly the drift this design must catch.

## Hash format

Sentinel file content, 3 lines, newline-terminated, no trailing blank line:

```
<line 1> sha256 hex digest of the sorted "path<TAB>blob-sha" manifest (produced by: printf '%s\n' "$MANIFEST" | git hash-object --stdin) — call this HASH
<line 2> ISO-8601 UTC timestamp of when /g-review wrote the sentinel, e.g. 2026-07-02T14:03:11Z
<line 3> branch name at review time, from `git branch --show-current`
```

Example:
```
a3f8c1e9d2b4...  (40 hex chars — git hash-object output, sha1; do not invent a different digest algorithm — reuse git's own object hash so no extra hashing dependency is introduced)
2026-07-02T14:03:11Z
feat/sentinel-binding
```

**Backward compatibility — legacy/empty sentinel:** the current sentinel is the literal string `approved` (or empty, in older installs). Under this design, `approved` (or any file that is not exactly 3 lines with a valid 40-hex-char line 1) is **not a valid hash-bound sentinel**. Decision: **treat legacy content as invalid and fail closed** — check-commit.sh denies the commit and instructs the developer to re-run `/g-review`. Rationale: silently accepting `approved` as "trust it" would reintroduce exactly the content-blind gap this design closes; failing closed on an ambiguous/old sentinel is one extra `/g-review` run, which is cheap compared to the risk of an unreviewed merge.

## Verification contract

Exact `check-commit.sh` gate logic to add, per sentinel, at the point where the script currently does `[ ! -f ".claude/g-forge-approved" ]` (code gate) and `[ ! -f ".claude/g-forge-docs-approved" ]` (doc gate) — this is an **additional check that runs after the existence check passes**, not a replacement of it:

1. If the sentinel file does not exist → existing behavior (deny "No code-lead sign-off...").
2. If the sentinel exists, read it. If it does not have exactly 3 non-empty lines, or line 1 is not a 40-character hex string → **treat as legacy/malformed → deny** with: `"Sentinel is legacy or malformed — tree changed since MERGE READY (or a pre-content-binding sentinel). Re-run /g-review."` (exit 2, same `deny()` helper, same stdout-JSON + stderr + exit-2 contract already used).
3. If the sentinel is well-formed, recompute the manifest hash at gate time:
   - Determine the file set: `git diff --cached --name-only` (the classifier already computes `$STAGED` for this purpose — reuse it, do not recompute).
   - For each staged path, get its staged blob sha via `git diff --cached --name-only -z` paired with `git ls-files --stage -- "$path"` (field 2 of the `ls-files --stage` output is the blob sha) — this reads the **index**, not the working tree, which is correct because gate time must hash what is *actually about to be committed*, not whatever the working tree currently holds (these can differ under partial staging — see Edge-case matrix).
   - For deleted staged paths, use the null-hash `0000000000000000000000000000000000000000` (git's own placeholder for "no blob"), matching the review-time convention.
   - Sort `path<TAB>blob-sha` lines, hash with `git hash-object --stdin`, call this `GATE_HASH`.
4. Compare `GATE_HASH` to line 1 of the sentinel (`SENTINEL_HASH`).
   - Match → allow (fall through, no deny call).
   - Mismatch → deny with: `"Tree changed since MERGE READY — re-run /g-review."` (exit 2).
5. All comparisons are plain string equality on two 40-hex-char values — no floating point, no locale-dependent sort (`sort` must be invoked with `LC_ALL=C` to guarantee stable, byte-order sorting across machines/locales; this is a required detail, not optional polish, since path sort order changes the final hash).

This is an **additive check inside the existing `if [ ! -f ... ]` / `elif` branches** in `check-commit.sh` — the doc sentinel (`.claude/g-forge-docs-approved`) gets the identical verification logic, parameterized by which sentinel file and which staged-file subset (doc paths vs. code paths per the existing classifier) it applies to.

## Edge-case matrix

Default posture: **fail closed** (deny + require re-review) whenever the gate cannot prove the staged content matches what was reviewed.

| Case | Expected gate behavior | Fail open/closed | Rationale |
|---|---|---|---|
| **Amend commit** (`git commit --amend`) | Gate re-runs on the amend's staged set exactly as on any commit; hash is recomputed against current index. If content changed since the sentinel was stamped, mismatch → deny. | Closed | Amend still runs through the same PreToolUse hook and staged index; no special-case needed — the general mismatch path already covers it. |
| **Rebase between review and commit** | If rebase altered any reviewed file's content (conflict resolution, re-applied patch with different context), blob shas differ → mismatch → deny. If rebase is a no-op replay (identical blobs), hash matches → allow. | Closed on any content change | A rebase is exactly the kind of post-review tree change this design must catch; a clean no-op replay correctly still passes since nothing actually changed. |
| **Mixed doc+code staging** | Both sentinels required (existing `mixed` classifier path, unchanged). Each sentinel's hash is verified independently against its own path subset (doc paths vs code paths) as staged. | Closed if either mismatches | Keeps the two gates orthogonal — a stale code sentinel must not be masked by a fresh doc sentinel or vice versa. |
| **Partial staging** (some reviewed files staged, others left in working tree unstaged) | Gate hash is computed only over the **staged** file set (`git diff --cached --name-only`). If the reviewed manifest included paths that are not in the staged set, the manifests differ in membership, not just content → mismatch → deny. | Closed | A partially-staged commit ships a different (incomplete) change than what was reviewed — this must not silently pass under the old sentinel's reviewed hash. |
| **Empty index** (`git commit` with nothing staged — git itself would normally reject this, but if it reaches the hook) | `$STAGED` is empty → classifier's existing `none → code` fallback applies; gate hash of an empty manifest almost certainly mismatches a non-empty sentinel manifest → deny. | Closed | Consistent with existing "empty staged set falls through to the stricter code gate" behavior; an empty manifest hash should never coincidentally equal a real sentinel's hash. |
| **`commit -a` where worktree ≠ index** | `commit -a` stages all tracked modifications immediately before the commit object is built, so by the time the PreToolUse hook's `git diff --cached` runs, the index already reflects the worktree — no divergence is observable at gate time. If the worktree contains changes beyond what code-lead reviewed, those are now staged and included in `GATE_HASH`, differing from `SENTINEL_HASH` → mismatch → deny. | Closed | This is the audit's existing finding 7 concern (classifier bypass) plus this design's mismatch check compounding to catch it: even if `commit -a` fools the file-set classifier, the content hash still won't match if anything changed. |
| **Sentinel present but hash line missing** (legacy 1-line `approved` sentinel, or hand-edited file) | Line-count/format validation (Verification contract step 2) fails → treated as legacy/malformed → deny, "re-run /g-review". | Closed | Explicit backward-compatibility decision above — never trust an unbound sentinel as if it were hash-verified. |
| **Both sentinels present with different hash "eras"** (e.g. code sentinel is hash-bound, doc sentinel is still the old flat `approved` from before this design shipped, or vice versa) | Each sentinel is validated independently per its own format check. A malformed one denies on its own path regardless of the other sentinel's validity. | Closed | Sentinels are independent gates (per the existing two-sentinel model) — one being upgraded does not grant the other a pass. |

## Consumer updates

**This wave** (files in task 8's scheduled set: `skills/g-review/SKILL.md`, `hooks/check-commit.sh`, `tests/test-check-commit.sh`):
- `skills/g-review/SKILL.md` Step 6 (`skills/g-review/SKILL.md:129-137`): replace "Write `.claude/g-forge-approved` with content: `approved`" with the manifest-hash computation (file set = `git diff --name-only $(git merge-base main HEAD)` or equivalent base-ref diff used by code-lead in Step 2) and the 3-line sentinel format above.
- `hooks/check-commit.sh`: add the hash-verification block described in Verification contract, applied to both the `code` and `doc`/`mixed` branches (parameterized per sentinel).
- `tests/test-check-commit.sh`: add fixture cases for — well-formed matching hash (allow), well-formed mismatched hash (deny), legacy 1-line sentinel (deny), missing sentinel (deny, existing case), mixed-commit with one sentinel hash-mismatched (deny).

**Follow-up task** (out of this wave's scheduled files — do not touch in this task):
- `skills/g-doc-review/SKILL.md` Step 4 (`skills/g-doc-review/SKILL.md:48-56`): apply the identical hash-stamping to `.claude/g-forge-docs-approved`, scoped to the doc-surface file set from that skill's Step 1. Decision (per this design): **yes, same mechanism** — the doc sentinel gets the same 3-line format and the same manifest-hash algorithm, just computed over the doc-surface path set instead of the full reviewed diff.
- `hooks/workflow-checkpoint.sh` review-state line (`hooks/workflow-checkpoint.sh:43-44,65`): currently reports `REVIEW_APPROVED=true` purely on file existence. Update to also read line 1 (hash) and optionally surface "review sign-off may be stale" if a cheap check (e.g. comparing `git status --porcelain` non-empty vs. sentinel presence) suggests drift — full hash reverification here is optional/advisory only, since the authoritative deny still happens in `check-commit.sh` at actual commit time.
- `/g-doctor` (`skills/g-doctor/SKILL.md:60-70`, checks 9 and 10): extend the "stale sentinel" checks to also flag a **malformed** hash-bound sentinel (wrong line count / non-hex line 1) as a distinct failure from "stale/present when it shouldn't be" — currently doctor only checks presence, not shape.
- `g-status` / `g-help` renderings: any surface that prints "Review: approved" from sentinel presence alone should note it is content-bound as of this design, but no functional change is required — advisory copy only.

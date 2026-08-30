---
name: g-doc-review
description: Documentation review gate. Dispatches the doc-reviewer agent on the changed file set to check documentation currency against the code it describes, then issues a standalone DOCS READY or DOCS HOLD verdict. On DOCS READY it writes the doc-approval sentinel that the commit gate checks for doc/mixed commits. Read-only on project content — it judges and gates, never writes docs. Distinct from /g-review (code review) and /g-docs (audits and generates docs).
context: [task, sprint]
---

**Announce:** "Using g-doc-review to run the documentation review gate."

You are running the documentation merge gate. It has its own verdict — **DOCS READY** or **DOCS HOLD** — separate from /g-review's code verdict. This skill judges documentation currency only; it never writes or fixes docs. Execute these steps in order.

## Step 1 — Determine the changed file set

Identify the set of files under review.

**If a path argument was provided** (e.g. `/g-doc-review src/services`):
- Restrict the review to files under that path. Skip the git detection below.

**If no argument was provided**, detect the changed set from git. The primary target is the staged index tree the sentinel will bind to at commit time. To cover what `git commit -a` would fold in, union the staged set with unstaged-but-tracked modifications — the same union `hooks/check-commit.sh`'s `-a`/`--all` handling already computes:
```
git diff --name-only --staged
```
unioned with:
```
git diff --name-only
```
Combine both into the changed set under review — reviewing this union means the review covers what would be committed with `git commit -a`, ensuring that staging the union before the Step 4 stamp makes the stamped tree coherent with the reviewed tree (ADR-004).

If that union is empty, fall back to `git diff --name-only <mainline>...HEAD` — this covers resuming review on a branch that already carries committed-but-unreviewed history (e.g. an interrupted multi-commit session). This fallback role is unchanged from before; only the priority is inverted. Resolve `<mainline>` the way `/g-resume` Step 0g resolves the record-bearing branch — binding `<remote>` first (the current branch's configured remote, `git config --get branch.<branch>.remote`, else `origin`): the short name from `git symbolic-ref --short refs/remotes/<remote>/HEAD` (stripped of the leading `<remote>/`), else `main`, else `master` — take the first candidate that verifies (`git rev-parse --verify <mainline>` succeeds). If none verifies, ask the developer which branch is the mainline for this fallback — wait for the answer (this skill runs in the session, so asking here is fine).

If both are empty, ask the developer: "No changes detected. What branch, commit range, or path should I review for documentation currency?" — wait for the answer.

From the changed set, separate:
- **Doc surfaces** — files carrying documentation: source files with exported/public symbols, module headers, `README*.md`, `CHANGELOG.md`, `g-docs/env-vars.md`, `g-docs/decisions/*.md`, OpenAPI specs (`openapi.yaml`/`openapi.json`/`swagger.json`).
- **Code-of-record** — the source files whose behaviour the docs must stay current with (function signatures, exported symbols, env var reads, route definitions, public API shape).

## Step 2 — Dispatch doc-reviewer

Dispatch the `doc-reviewer` agent (read-only on project content; it holds a `Write` grant scoped to its own review-record path only — never docs, never anything else). This gate calls doc-reviewer **directly** — review-orchestrator is for code review, not this gate. Provide in the prompt:

- The full changed file set from Step 1, split into **doc surfaces** and **code-of-record**.
- Instruction: "Verify documentation currency against the code it describes. For every changed public/exported symbol, check that its doc (JSDoc / docstring / doc comment) exists and matches the current signature and behaviour. For every changed env var read, README section, public route, or CHANGELOG-worthy change, check the corresponding documentation is present and accurate. Report findings as BLOCKING, WARNING, or PASS with `file:line` refs. Do not fix anything."
- The severity contract (so its verdict aligns with this gate):
  - **BLOCKING (→ DOCS HOLD):** a public/exported symbol or public API surface (route, SDK export, webhook/event schema) has missing documentation; documentation that **contradicts** the current code (stale signature, wrong param, removed behaviour still documented); an undocumented env var read by the app; a shipped user-facing change with no CHANGELOG entry.
  - **WARNING (advisory — still DOCS READY):** internal/private symbol lacking docs; module-header gap on an internal file; clarity or wording issues; minor incompleteness that does not mislead; volatile in-flight state hardcoded instead of handled per lens 5's remedy order (a test that fails when the count and its source disagree, or omit the number — the pin-with-a-test-or-omit rule, G-Forge ADR-013 — with record-citation pointer language as the contract's own addition for unpinnable must-state numbers) — escalates to BLOCKING only when the hardcoded number already contradicts the record it should match, which is then a Currency finding, not lens 5.
- **If this run claims to close one or more findings from a prior DOCS HOLD** (this is the trigger — not "the same file set", see Step 2b): instruct doc-reviewer to perform the fix-closure sweep described in its own contract (`agents/doc-reviewer.md`) — for each finding claimed closed, identify the exact literal fact the fix changed, grep it across the whole repo to confirm no stale copy survives, and record the grep command and its output in its own review record. List the specific prior-round findings being claimed closed in the dispatch prompt so doc-reviewer knows which ones to sweep.
- `output_file`: mint a per-run path, `g-docs/agent-output/review/doc-reviewer-[YYYY-MM-DD]-[request-slug]-r[N].md`, where `[request-slug]` is a short slugified form of the path argument if one was given (Step 1), or otherwise a slug summarizing what's under review (e.g. the active milestone, or the changed file set) — same slugify convention `/g-plan` uses. `[N]` is the round ordinal: **1 + the highest ordinal among existing files matching `doc-reviewer-[same date]-[same slug]-r*.md`** in `g-docs/agent-output/review/` (glob that pattern before minting the path; no matches → `r1`, highest `r2` → `r3`, and so on — highest-plus-one, not a count, so a hand-deleted middle record can never cause an overwrite). Round records are **never deleted** — the round ordinal is what discriminates the path, so two same-day rounds on the same target mint distinct files and neither collides with nor overwrites the other; every prior round's record survives on disk for Step 2c to read. Create the `g-docs/agent-output/review/` directory first if it does not exist.

Wait for doc-reviewer's complete report. Parse its findings into BLOCKING vs WARNING.

## Step 2b — Fix-closure sweep record check (HQ-side, required whenever this round claims to close prior findings)

Trigger: this run claims to close one or more findings from a prior DOCS HOLD — keyed on that claim, never on "the same file set", which the normal fix-and-re-run cycle routinely changes (a fix commonly touches lines the prior round's finding did not cite).

doc-reviewer performs the sweep itself, in Step 2, while it is alive and dispatched — this step is HQ's required check that its record actually carries the evidence, not a step that performs the sweep:

- Open doc-reviewer's review record at the per-run `output_file` path minted in Step 2.
- For every prior-round finding this run claims to close, confirm the record states: the exact literal fact that changed, the grep command used to search for stale copies elsewhere, and the grep output.
- A closure claim with no recorded sweep evidence in the record does not count as closed — see Step 3 for the verdict consequence.
- The record above lives at `g-docs/agent-output/review/`, which is gitignored and session-scoped (G-RULES §I) — it does not survive a fresh clone and is not itself the durable proof of closure. Once a closure is confirmed here, carry it forward onto a committed surface: add one line to the `## Active Session` handoff or the closing `g-docs/todo.md` row naming the finding closed and the sweep result (e.g. `"closure sweep: grep '<the old literal>' — 0 hits outside historical records, closed"`, with the angle-bracket text replaced by the actual literal that changed).

## Step 2c — Round-3 consolidation note

State source: round history means the surviving `doc-reviewer-[YYYY-MM-DD]-[request-slug]-r[N].md` record series minted in Step 2 — round-discriminated and never deleted, so the full `r1..rN` run for the current date+slug is always on disk (and, for a review target spanning multiple dates, prior dates' series for that same target alongside it).

- **If prior rounds' record files are visible** (the `r1..r(N-1)` records of the current date+slug series are present in `g-docs/agent-output/review/` this session, or a prior date's series for the same target is locatable): count, per finding **class** (the same recurring claim or fact across rounds — not the round counter alone), how many consecutive rounds it has appeared as a BLOCKING or WARNING finding — grep the finding class across the `r1..rN` records of the series to get this count. When a class reaches its third round, add a note alongside the Step 4 presentation: "round 3 on this class — consolidate the repeated facts into one source of truth instead of patching."
- **If prior rounds' records are not visible** — a fresh session with no `g-docs/agent-output/review/` history, or no prior-round records locatable for the same target — note that plainly: "round history unavailable this session; cannot determine round count for this finding class." Do not guess or infer a count from memory.
- This is a **note only** either way. It never blocks, never changes the DOCS READY/DOCS HOLD verdict, and never overrides the Step 2 severity contract. It exists to name the moment a class of fix should stop being patched instance-by-instance and start being consolidated — e.g. one canonical count referenced from elsewhere instead of restated in five places.

## Step 3 — Derive the verdict

- **If doc-reviewer returned one or more BLOCKING findings → DOCS HOLD.**
- **If Step 2b's required sweep check found a surviving stale copy of a claimed-closed fact, or found the required sweep missing from the record → DOCS HOLD**, classed as Currency (a stale fact surviving is exactly what the Currency lens blocks on). This is a second, HQ-derived verdict input alongside doc-reviewer's own findings list — it does not modify or override what doc-reviewer returned (the Rules below still hold: never modify doc-reviewer's findings).
- **If doc-reviewer returned only WARNING findings (or PASS), and Step 2b's check (when triggered) passed → DOCS READY.** WARNING findings are advisory and never block.

## Step 4 — Present verdict and manage the sentinel

Present doc-reviewer's findings to the developer verbatim, grouped BLOCKING / WARNING / PASS. Append any round-3 consolidation note from Step 2c under the finding class it applies to — as a note, never as a reason to change the verdict.

**If verdict is DOCS READY:**
- Create the `.claude/` directory if it does not exist.
- Compute the sentinel stamp (binds the sentinel to the exact reviewed tree — ADR-004, same format `/g-review` uses for the code sentinel):
  - `commit_sentinel_ts`: first stage what Step 1 actually reviewed, if any of it is unstaged — `git add -u` when Step 1 detected the changed set from git (the no-argument branch), or `git add -u -- <path>` scoped to the path argument when one was given, never an unscoped add on a scoped review — so the index holds exactly the reviewed set; then `git write-tree` of the now-staged index
  - `commit_sentinel_head`: `git rev-parse HEAD`
  - `commit_sentinel_worktree`: `git rev-parse --show-toplevel`
- Write `.claude/g-forge-docs-approved` with content: `commit_sentinel_ts=<write-tree output> commit_sentinel_head=<rev-parse HEAD output> commit_sentinel_worktree=<show-toplevel output>` (one line, space-separated `key=value` fields, exact field names — do not rename them)
- If this review covered code/mixed changes and `.claude/g-forge-approved` is also being written (see `/g-review`), the two sentinels should carry the identical stamp — both bind to the one tree being committed.
- Tell the developer: "DOCS READY. Documentation gate open — the doc/mixed-commit gate is satisfied for these changes."
- If any WARNING findings were reported, list them as advisory follow-ups and note: "These do not block. Run `/g-docs <path>` or dispatch `doc-writer` to close them."

**If verdict is DOCS HOLD:**
- Do **NOT** write `.claude/g-forge-docs-approved`.
- List every BLOCKING finding with its `file:line` ref and what is missing or contradicted.
- **If the HOLD is (in whole or in part) from Step 2b's sweep check** rather than doc-reviewer's own findings list, list that separately: the stale copy found (with `file:line`), or the required-but-missing sweep record, and name it as a Currency-class HOLD raised by HQ's sweep-record check — not by doc-reviewer.
- Recommend the fix path — `/g-docs <path>` to audit-and-generate, or `doc-writer` to fill a specific gap — but do not run it from this skill.
- Stop with: "DOCS HOLD. Fix every blocking item above, then re-run `/g-doc-review`."

## Rules
- This skill is **READ-ONLY on project content** — it judges and gates only. It never writes, edits, or generates documentation itself. The only files *this skill* writes are the `.claude/g-forge-docs-approved` sentinel (Step 4, only on DOCS READY) and the `g-docs/agent-output/review/` directory itself if it does not yet exist (Step 2, `mkdir` only, before dispatch — no delete happens here, round records are never removed). `doc-reviewer` writes its own review record (including the fix-closure sweep, when instructed) under its own scoped `Write` grant (`g-docs/agent-output/review/doc-reviewer-*`) — that write is doc-reviewer's, not this skill's.
- The fix-closure sweep is **required**, not advisory, whenever this run claims to close one or more findings from a prior DOCS HOLD — keyed on that claim, never on "the same file set". doc-reviewer performs the sweep itself in Step 2 while dispatched; Step 2b is HQ's required check that its record actually carries the sweep evidence. A closure claim with no recorded sweep output in doc-reviewer's review record file does not count as closed, and — per Step 3 — a missing or failed sweep is its own Currency-class DOCS HOLD, independent of doc-reviewer's findings list.
- When a doc-fix round and a code-fix round run in parallel on the same HOLD, each fix dispatch greps the other lane's changed literals (the facts each round rewrote) before returning — a fact changed in one lane and not swept in the other is a Currency-class finding next round, not a surprise.
- The round-3 consolidation note (Step 2c) is advisory phrasing only — it is never grounds to change a verdict, hold a clean pass, or override the Step 2 severity contract.
- To fix gaps, recommend `/g-docs` or the `doc-writer` agent — never perform doc edits here, and never dispatch doc-writer from this gate.
- Never write `.claude/g-forge-docs-approved` for anything other than a DOCS READY verdict.
- Public-API / exported-symbol doc gaps and contradicts-code findings are **BLOCKING** → DOCS HOLD. Internal-only gaps and clarity issues are **WARNING** → advisory, still DOCS READY.
- This is the documentation gate. It is distinct from `/g-review` (code-review gate, sentinel `.claude/g-forge-approved`) and from `/g-docs` (which audits and generates docs). Do not run code review or the test suite here.
- Never modify doc-reviewer's findings — present them exactly as returned.
- Dispatch `doc-reviewer` directly; do not route through `review-orchestrator` (that pipeline is for code).
- The sentinel is cleared automatically after the next `git commit` by the commit hook — re-run this gate for the next change set.

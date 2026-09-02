---
name: g-doc-review
description: Documentation review gate. Dispatches the doc-reviewer agent on the changed file set to check documentation currency against the code it describes, then issues a standalone DOCS READY or DOCS HOLD verdict. On DOCS READY it writes the doc-approval sentinel that the commit gate checks for doc/mixed commits. Read-only on project content — it judges and gates, never writes docs. Distinct from /g-review (code review) and /g-docs (audits and generates docs).
context: [task, sprint]
---

**Announce:** "Using g-doc-review to run the documentation review gate."

You are running the documentation merge gate. It has its own verdict — **DOCS READY** or **DOCS HOLD** — separate from /g-review's code verdict. This skill judges documentation currency only; it never writes or fixes docs. Execute these steps in order.

## Step 1 — Build the review pack

Locate the shared pack builder: Glob for `skills/g-review/scripts/build-review-pack.sh` under `~/.claude/plugins/cache/g-forge/g-forge/` (in a plugin-source checkout, use the repo's own copy). Run it from the project root: `bash <script> --gate doc --slug <slug>` — with `--path <path>` when a path argument was provided (e.g. `/g-doc-review src/services`; the slug is then the slugified path), `--closes <file>` when this run claims to close prior findings, and `--reuse <code pack dir>` when /g-review built a pack for the same tree this session (adopted only when `PACK_TREE` still matches and no `--path` is set). Interpret its `KEY: value` output — the changed set, diff, full-file `slices/`, and MANIFEST are on disk; the union/fallback/mainline mechanics and ADR-004 rationale live in the script and `references/gate-rationale.md`. On `EXIT: no-changes`, ask the developer: "No changes detected. What branch, commit range, or path should I review for documentation currency?" — wait for the answer.

From the pack's `files.txt`, separate the changed set: **doc surfaces** — the MANIFEST's `DOC_SURFACE:` lines (`README*.md`, `CHANGELOG.md`, `g-docs/env-vars.md`, `g-docs/decisions/*.md`, `openapi.yaml`/`openapi.json`/`swagger.json`) plus source files with exported/public symbols or module headers (your judgment); **code-of-record** — the source files whose behaviour the docs must stay current with (function signatures, exported symbols, env var reads, route definitions, public API shape).

## Step 2 — Dispatch doc-reviewer

Dispatch the `doc-reviewer` agent **directly** — never through `review-orchestrator` (that pipeline is for code; background in `references/gate-rationale.md`). It is read-only on project content, with a `Write` grant scoped to its own review record. Provide in the prompt — never the diff itself:

- The `pack_dir` (`PACK_DIR:` from Step 1) and a one-line MANIFEST summary (MODE, FILES), plus the doc-surface / code-of-record split — the pack is the reviewed surface, per the "Reviewing from a pack" clause in doc-reviewer's Input contract.
- Instruction: "Verify documentation currency against the code it describes. For every changed public/exported symbol, check that its doc exists and matches the current signature and behaviour. For every changed env var read, README section, public route, or CHANGELOG-worthy change, check the corresponding documentation is present and accurate. Report findings as BLOCKING, WARNING, or PASS with `file:line` refs. Do not fix anything."
- The severity contract:
  - **BLOCKING (→ DOCS HOLD):** a public/exported symbol or public API surface with missing documentation; documentation that **contradicts** the current code; an undocumented env var read by the app; a shipped user-facing change with no CHANGELOG entry.
  - **WARNING (advisory — still DOCS READY):** internal gaps, clarity issues, minor incompleteness; volatile in-flight state hardcoded instead of handled per lens 5's remedy order. Edge cases (hardcoded volatile counts, the lens-5 remedy order, escalation to Currency): load `references/severity-edge-cases.md`.
- **If this run claims to close findings from a prior DOCS HOLD** (the trigger is the claim, never "the same file set" — see Step 2b): list them (they ride in the pack at `prior/claimed-closed.txt`) and instruct the fix-closure sweep per doc-reviewer's own contract (`agents/doc-reviewer.md` `## Fix-closure sweep (when instructed)`).
- `output_file`: the `OUTPUT_FILE:` path from Step 1 — the round-ordinal record series `doc-reviewer-[YYYY-MM-DD]-[request-slug]-r[N].md`, minted highest-plus-one by the script; round records are never deleted.

Wait for doc-reviewer's complete report. Parse its findings into BLOCKING vs WARNING.

## Step 2b — Fix-closure sweep record check (HQ-side, required whenever this round claims to close prior findings)

Trigger: the closure claim itself — never "the same file set". doc-reviewer performs the sweep while dispatched; this step is HQ's check that its record carries the evidence:
- Open doc-reviewer's record at the Step 2 `output_file`. For each claimed closure, confirm it states: the exact literal fact that changed, the grep command, and the grep output.
- A closure claim with no recorded sweep evidence does not count as closed — see Step 3 for the verdict consequence.
- Confirmed closures are carried onto a committed surface per `references/fix-closure-sweep.md` (the gitignored record is not durable proof).

## Step 2c — Round-3 consolidation note

When a finding class recurs across the never-deleted `r1..rN` record series, follow `references/round-consolidation.md`: at a class's third consecutive round, append the advisory consolidation note to Step 4; when round history is unavailable, say so plainly. Never blocks, never changes a verdict.

## Step 3 — Derive the verdict

- **If doc-reviewer returned one or more BLOCKING findings → DOCS HOLD.**
- **If Step 2b's required sweep check found a surviving stale copy of a claimed-closed fact, or found the required sweep missing from the record → DOCS HOLD**, classed as Currency (a stale fact surviving is exactly what the Currency lens blocks on). This is a second, HQ-derived verdict input alongside doc-reviewer's own findings list — it does not modify or override what doc-reviewer returned.
- **If doc-reviewer returned only WARNING findings (or PASS), and Step 2b's check (when triggered) passed → DOCS READY.** WARNING findings are advisory and never block.

## Step 4 — Present verdict and manage the sentinel

Present doc-reviewer's findings verbatim, grouped BLOCKING / WARNING / PASS, with any Step 2c note under its finding class (a note, never a reason to change the verdict).

**If verdict is DOCS READY:**
- Re-verify freshness: run the pack builder with `--check <pack_dir>`. `PACK: stale` → do not stamp; build the next round's pack and re-review. `PACK: fresh` → create `.claude/` if needed and write `.claude/g-forge-docs-approved` with content: `commit_sentinel_ts=<write-tree output> commit_sentinel_head=<rev-parse HEAD output> commit_sentinel_worktree=<show-toplevel output>` (one line, space-separated `key=value` fields, exact field names — do not rename them). The write-tree value is the pack's `PACK_TREE` (ADR-004, same format `/g-review` uses) after staging what was reviewed — `git add -u`, or `git add -u -- <path>` scoped to a path argument, never an unscoped add on a scoped review.
- If this review covered code/mixed changes and `.claude/g-forge-approved` is also being written (see `/g-review`), the two sentinels carry the identical stamp — both bind to the one tree being committed.
- Tell the developer: "DOCS READY. Documentation gate open — the doc/mixed-commit gate is satisfied for these changes."
- If any WARNING findings were reported, list them as advisory follow-ups and note: "These do not block. Run `/g-docs <path>` or dispatch `doc-writer` to close them."

**If verdict is DOCS HOLD:**
- Do **NOT** write `.claude/g-forge-docs-approved`.
- List every BLOCKING finding with its `file:line` ref and what is missing or contradicted.
- **If the HOLD is (in whole or in part) from Step 2b's sweep check**, list that separately — the stale copy found (with `file:line`), or the required-but-missing sweep record — and name it as a Currency-class HOLD raised by HQ's sweep-record check, not by doc-reviewer.
- Recommend the fix path — `/g-docs <path>` or `doc-writer` — but do not run it from this skill.
- Stop with: "DOCS HOLD. Fix every blocking item above, then re-run `/g-doc-review`."

## Rules
- This skill is **READ-ONLY on project content** — it judges and gates only; it never writes, edits, or generates documentation. The only writes on its behalf are: the `.claude/g-forge-docs-approved` sentinel (Step 4, DOCS READY only), and the pack the shared builder script assembles under `g-docs/agent-output/review/` (gitignored, regenerable; the script computes its tree on a temporary index copy and never mutates the real index — the only real-index write on this skill's behalf is Step 4's own scoped/unscoped `git add -u` staging at stamp time, declared per ADR-004). `doc-reviewer` writes its own review record under its own scoped `Write` grant (`g-docs/agent-output/review/doc-reviewer-*`) — that write is doc-reviewer's, not this skill's. Round records and packs are never deleted.
- The fix-closure sweep is **required**, not advisory, whenever this run claims to close prior DOCS HOLD findings — keyed on the claim, never on "the same file set". A closure claim with no recorded sweep output in doc-reviewer's record does not count as closed and — per Step 3 — is its own Currency-class DOCS HOLD.
- When a doc-fix round and a code-fix round run in parallel on the same HOLD, each fix dispatch greps the other lane's changed literals (the facts each round rewrote) before returning — a fact changed in one lane and not swept in the other is a Currency-class finding next round, not a surprise.
- The round-3 consolidation note (Step 2c) is advisory phrasing only.
- To fix gaps, recommend `/g-docs` or the `doc-writer` agent — never perform doc edits here, and never dispatch doc-writer from this gate.
- Never write `.claude/g-forge-docs-approved` for anything other than a DOCS READY verdict.
- Public-API / exported-symbol doc gaps and contradicts-code findings are **BLOCKING** → DOCS HOLD. Internal-only gaps and clarity issues are **WARNING** → advisory, still DOCS READY.
- This is the documentation gate — distinct from `/g-review` (code-review gate, sentinel `.claude/g-forge-approved`) and `/g-docs` (audits and generates docs). Do not run code review or the test suite here.
- Never modify doc-reviewer's findings — present them exactly as returned.
- Dispatch `doc-reviewer` directly; do not route through `review-orchestrator` (that pipeline is for code).
- The pack is immutable and bound to `PACK_TREE`: run `--check` before reusing a pack built earlier in the session and again before stamping; stale → build the next round's pack. The doc and code gates hold independent round series; one going full never drags the other.
- The sentinel is cleared automatically after the next `git commit` by the commit hook — re-run this gate for the next change set.

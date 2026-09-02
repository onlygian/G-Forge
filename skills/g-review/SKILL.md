---
name: g-review
description: Run the review gate on the current branch diff. Runs the test suite, captures the diff, and dispatches code-lead, which verifies done conditions and reviews the diff itself. Issues MERGE READY or HOLD.
context: [task, sprint, architectural]
---

**Announce:** "Using g-review to run the full review pipeline."

You are running the merge gate. Execute these steps in order.

## Step 0 — Read telemetry profile (adaptive review intensity)

Read `.claude/telemetry-profile`; treat the contents as one of `stable`, `cautious`, `defensive`, or `recovery` (missing/malformed → `stable`). Intensity ladder — `stable`: default reviewer set (code-reviewer, security-auditor when auth/external IO touched, architecture-enforcer when layer-boundary changes, performance-auditor when hot-path changes); `cautious`: +1 stricter code-reviewer pass; `defensive`: +1 code-reviewer, +1 architecture-enforcer regardless of diff, debugger pre-review; `recovery`: full reviewer set regardless of diff (code-reviewer, security-auditor, architecture-enforcer, performance-auditor) plus debugger + error-detective pre-review.

**Step 0 note:** neither the reviewer-adjustment nor the pre-review column is wired as shipped — `code-lead` reviews the diff **solo** (no `Agent(` grant), and no shipped agent emits an `AXES:` line; the ladder is what HQ applies by hand when a run warrants extra scrutiny. Before treating it as automatic fan-out, load `references/panel-history.md` (also load it whenever the profile is not `stable`).

Pass the active profile to code-lead in Step 4 and announce it once:
```
Telemetry profile: [profile] — review intensity adjusted accordingly
```

## Step 1 — Run the test suite

**Installed-copy drift check (routine, visible-only — ADR-008 clause 5).** Hash-compare (sha256sum, else shasum -a 256, else cksum) each canonical `hooks/` and `hooks/lib/*.sh` script against its installed counterpart at `.claude/hooks/<file>` and `.claude/hooks/lib/<file>` — the hooks+libs subset of `/g-doctor` Check 16; a missing installed file counts as drift. Also resolve `<git-hooks-dir>` via `git rev-parse --git-path hooks` and extend the comparison to the native install site — `hooks/pre-commit` → `<git-hooks-dir>/pre-commit` and each lib → `<git-hooks-dir>/lib/<file>` — but first check `<git-hooks-dir>/pre-commit`'s opening lines for the literal marker `G-Forge commit gate`; if absent, the slot holds a foreign hook — skip that half with the note `<git-hooks-dir>/pre-commit not G-Forge-managed — skipped`. If `hooks/` does not exist at the repo root, report `Installed-copy drift: not applicable — no canonical hooks/ in this checkout`. Otherwise report one line verbatim in the review record: `Installed-copy drift: clean` or `Installed-copy drift: N file(s) drifted — run /g-update ([file], [file], ...)`. **This result NEVER gates the verdict** — carry it into Step 4's dispatch and Step 6's presentation unchanged, and never let drift turn MERGE READY into HOLD.

**Run the deterministic suite directly — no agent indirection.** If `tests/run-all.sh` exists, run `bash tests/run-all.sh` and capture its output verbatim; otherwise detect the command in priority order: package.json `"test"` script → `npm test` (or `bun test` / `yarn test` based on lockfile); `pytest` signals (`pytest.ini`, `pyproject.toml` with `[tool.pytest]`, or `tests/` with `.py` files) → `pytest`; `Makefile` with a `test` target → `make test`; then the `g-docs/project_brief.md` Tests field; else ask the developer "What command runs your test suite?". Attestation imperatives: verbatim runner output is required; HQ sums the per-suite table itself — the summed table wins over any stated total; near the ~10-min tool timeout run the suite detached via `nohup … & disown` and poll the log, never trailing a pipe. When a total disagrees with its table, an agent self-declares a pass, or a detached run is needed, load `references/attestation-doctrine.md`.

On a green run: report `✓ Tests passed — proceeding to code review`, then Glob `.claude/agents/*-dev.md` — exactly one match: dispatch it scoped to project-specific gate fixtures needing judgment, under the same attestation rules (a self-declared pass with no runner output is UNVERIFIED and treated as a failed run); several matches: ask which; none: no-op. Then Step 2.

On any red run: do NOT write `.claude/g-forge-approved`; report the failures verbatim; dispatch `error-detective` (test output + current diff), then `debugger` (its findings + sources) for a fix strategy; present both and stop with: `HOLD — tests failing. Diagnosis above. Fix all failures before re-running /g-review.`

If the project has no tests: report `⚠ No test suite detected` and offer (a) dispatch `test-writer` now — once written and passing, continue; or (b) one-time skip — note `⚠ No tests — developer override` and continue.

## Step 2 — Build the review pack

Run `bash scripts/build-review-pack.sh --gate code --slug <slug>` from the project root (script resolved relative to this skill's directory; mint `<slug>` with `/g-plan`'s slugify convention from the milestone or changed set; add `--closes <file>` listing prior-round findings this run claims to close, and `--force-full` when the profile is `recovery`, a prior round returned ESCALATE, or the developer asks). Interpret its `KEY: value` output: the pack (diff, `files.txt`, full-file `slices/`, `done-conditions.md`, MANIFEST) is built on disk — the diff never enters this window. `MODE: delta` means the builder verified the fix stayed inside the previously reviewed set and carried the prior records; a `DELTA_INELIGIBLE:` line names why a round runs full. `MANIFEST_CHANGED: true` arms the dependency-auditor lane. On `EXIT: no-changes`, ask the developer: "What branch or commit range should I review?" The union/fallback/stamp rationale is ADR-004 — `references/sentinel-binding.md`.

## Step 3 — Gather done conditions

The pack's `done-conditions.md` is fetched, not judged — confirm or override it in this order: the relevant plan file (`g-docs/plans/`, or a spec the developer named) → the current milestone file in `g-docs/milestones/` → ask the developer: "What are the done conditions for this implementation?" If none can be found, note it — code-lead will flag it as a process gap.

## Step 4 — Dispatch code-lead

Dispatch `code-lead` with a prompt carrying — never the diff itself:
- the `pack_dir` (`PACK_DIR:` from Step 2) and a one-line MANIFEST summary (MODE, FILES, DIFF_SOURCE) — the pack is the reviewed surface, per the "Reviewing from a pack" clause in code-lead's Step 2;
- attested test result (`"Tests: PASS (attested — exit 0, output below)"` + Step 1 output, or `"Tests: skipped — developer override"`) and, when run, `"Type-check: PASS (attested — exit 0)"`;
- the `Installed-copy drift:` line verbatim — informational only, never a verdict factor;
- the confirmed done conditions, branch name, task list (if known), and the telemetry profile;
- `output_file`: the `OUTPUT_FILE:` path from Step 2 (round-ordinal record series `code-lead-[YYYY-MM-DD]-[request-slug]-r[N].md` — highest-plus-one, records never deleted);
- when this run claims closures: name the prior-round findings (they ride in the pack at `prior/claimed-closed.txt`) and instruct the sweep per code-lead's `## Fix-closure sweep (when instructed)` section.

If `MANIFEST_CHANGED: true`, dispatch `dependency-auditor` **in parallel** — pass the same `pack_dir` (it reads changed manifests from `slices/`) and its own `output_file` (`dependency-auditor-[YYYY-MM-DD]-r[N].md`, same highest-plus-one discipline). Wait for both to return, then include dependency-auditor's findings in the materials passed to code-lead for its final verdict (so any dependency risks are factored into MERGE READY / HOLD). Its `RESULT: HOLD` or any CRITICAL/MAJOR finding is blocking regardless of code-lead's position. Parse code-lead's `RESULT:`; on HOLD/ESCALATE read `DETAIL:` before presenting.

**`.claude/review-holds` — this skill owns both sides of it** (currently-unresolved HOLDs, not a lifetime total; `g-docs/telemetry-metrics.md` metric 4). On a HOLD return, increment `.claude/review-holds` by 1 (create with `1` if absent; unconditional, profile-independent). When this run closes prior HOLD findings and reaches an effective MERGE READY, decrement by 1 per closed HOLD round, **floored at 0** (absent/unparseable → treat as `0`, leave at `0`) — only after Step 4b confirms the evidence: an unevidenced closure claim is not a closure, so it does not decrement. Never reset it wholesale — history: `references/review-holds-history.md`.

## Step 4b — Fix-closure sweep record check (HQ-side, required whenever this round claims to close prior findings)

Trigger: the closure claim itself — never "the same file set". code-lead performs the sweep while dispatched (its `## Fix-closure sweep (when instructed)` section); this step is HQ's check that the record carries the evidence:
- Open code-lead's record at the Step 4 `output_file`. For each claimed closure, confirm it states: the exact literal fact that changed, the grep command, and the grep output.
- **A closure claim with no recorded sweep evidence does not count as closed.** This converts the round's **effective verdict** to HOLD (classed Currency) as a distinct HQ-derived input — never a rewrite of code-lead's verdict text. Step 5 is then correctly skipped and Step 6 writes no sentinel; if code-lead's own line read MERGE READY, also increment `.claude/review-holds` by 1 here so the counter never undercounts a 4b block. Conversely, evidenced closure is what authorises Step 4's decrement — this step gates both directions.
- Confirmed closures are carried onto a committed surface per `references/fix-closure-sweep.md` (the gitignored record is not durable proof).
- No closure claim → skip silently.

## Step 4c — Round-3 consolidation note

When a Critical/Major finding class recurs across the never-deleted `r1..rN` record series, follow `references/round-consolidation.md`: at a class's third consecutive round, append the advisory consolidation note to Step 6; when round history is unavailable, say so plainly. Never blocks, never changes a verdict.

## Step 5 — Tier 3 Smoke Test (MERGE READY path only)

On HOLD or ESCALATE, skip to Step 6. On MERGE READY:
1. If `.claude/tier3-active` exists, a listen-mode session is in progress — skip to Step 6.
2. Print the testing instrument: `g-docs/qa-scope/<milestone-slug>.md` if present, else the project's QA panel groups, else the milestone test plan in full.
3. Prompt:
   > "Code review passed. **Tier 3 — smoke test the changes.**
   > Work through the list above and report each finding in chat — say **'done this round'** when finished."
4. Write `0` to `.claude/tier3-active`.
5. **Listen mode:** no edits, no fix suggestions; acknowledge each finding only with `Bug N logged — <area>` and increment the count in `.claude/tier3-active`.
6. On **"done this round"**: delete `.claude/tier3-active`. Count 0 → Step 6. Otherwise triage the batch, dispatch fix waves, and re-run from Step 1 until a clean round returns 0 bugs.

## Step 6 — Present verdict and manage sentinel

Present code-lead's verdict verbatim, then the `Installed-copy drift:` line (visibility-only), any Step 4c note under its finding class, and — if Step 4b fired — the HQ-derived blocking item alongside code-lead's line, named as an HQ-side gate.

**If verdict is MERGE READY:**
- Re-verify freshness: `bash scripts/build-review-pack.sh --check <pack_dir>`. `PACK: stale` → do not stamp; the tree moved since review — build the next round's pack and re-review. `PACK: fresh` → create `.claude/` if needed and write `.claude/g-forge-approved` with content: `commit_sentinel_ts=<write-tree output> commit_sentinel_head=<rev-parse --verify HEAD output> commit_sentinel_worktree=<show-toplevel output>` (one line, space-separated `key=value` fields, exact field names — do not rename them). The write-tree value is the pack's `PACK_TREE` — the same computation `hooks/pre-commit` performs at commit time (ADR-004; `references/sentinel-binding.md`) — after staging the reviewed union (`git add -u`; not needed on the mainline fallback). On a mixed doc/code change where `.claude/g-forge-docs-approved` is also being written, both sentinels carry the identical stamp.
- Tell the developer: "MERGE READY. Commit gate unlocked — you can now run git commit and merge."
- Ask once: "Would you like a PR description? (yes/no)" — if yes, dispatch `pr-writer` with the pack's diff and the done conditions.

**Milestone close-out (MERGE READY only):** Read `g-docs/todo.md`, `g-docs/ROADMAP.md` (active `🔄 In progress` milestone) and the matching `g-docs/milestones/` file (missing → skip silently). Mark completed `## Scope` items `[x]`. If ALL are now `[x]`: set the milestone header and ROADMAP entry to `✅ Complete` (status key: ⬜ Not started · 🔄 In progress · ✅ Complete; completed milestones stay in place), report `✓ Milestone [ID — Name] closed out`, then load `references/milestone-close.md` and follow it exactly — version-bump prompt, auto-retro, close swarm (/g-telemetry, /g-align, ADR prompt), /g-patterns after the swarm, /g-wiki refresh, every-other-milestone /g-doctor. If only some are done: save the partial updates and report `✓ [N] milestone tasks checked off — [M] remaining`.

**If verdict is HOLD — FIX REQUIRED:** do NOT write `.claude/g-forge-approved`; tell the developer: "HOLD. Fix all blocking items listed above, then re-run /g-review."

**If verdict is ESCALATE:** do NOT write `.claude/g-forge-approved`; present the escalation details and ask the developer for guidance.

## Rules
- Never modify code-lead's verdict — present it exactly.
- The Step 1 installed-copy drift check is visible-only — always reported, never gates or downgrades the verdict. Its comparison covers `hooks/`, `hooks/lib/`, and the native `<git-hooks-dir>/pre-commit` + `<git-hooks-dir>/lib/` install sites.
- Never write `.claude/g-forge-approved` for anything other than MERGE READY.
- Never skip Step 5 on MERGE READY — except when Step 4b has converted the effective verdict to HOLD (Currency), which correctly skips it. The sentinel is not written until a clean smoke-test round completes.
- The pack is immutable and bound to `PACK_TREE`: run `--check` before any dispatch that reuses a pack built earlier in the session and again before stamping in Step 6; stale → build the next round's pack, never edit one.
- If code-lead is blocked by missing information, gather it and re-dispatch — do not guess.
- The sentinel is automatically cleared after the next `git commit` by the commit hook.
- In listen mode: zero edits, zero suggestions, acknowledgement only. Violations of listen mode reset the round.
- Step 4b is required, not advisory, whenever a run claims to close prior HOLD findings — keyed on the claim, never on "the same file set". A closure claim with no recorded sweep output blocks MERGE READY the same way a HOLD does.
- When a code-fix round and a doc-fix round run in parallel on the same HOLD, each fix dispatch greps the other lane's changed literals (the facts each round rewrote) before returning — a fact changed in one lane and not swept in the other is a Currency-class finding next round, not a surprise.
- The Step 4c round-3 consolidation note is advisory phrasing only — never grounds to change a verdict, skip Step 5, or override the Step 4 severity contract.

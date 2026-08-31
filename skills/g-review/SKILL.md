---
name: g-review
description: Run the review gate on the current branch diff. Runs the test suite, captures the diff, and dispatches code-lead, which verifies done conditions and reviews the diff itself. Issues MERGE READY or HOLD.
context: [task, sprint, architectural]
---

**Announce:** "Using g-review to run the full review pipeline."

You are running the merge gate. Execute these steps in order.

## Step 0 — Read telemetry profile (adaptive review intensity)

Read `.claude/telemetry-profile` if it exists. Treat the contents as one of `stable`, `cautious`, `defensive`, or `recovery`. Missing or malformed → treat as `stable`.

Apply the following review adjustments throughout this skill:

| Profile | Reviewer adjustment | Pre-review additions |
|---------|---------------------|----------------------|
| `stable` | Default reviewer set (code-reviewer, security-auditor when auth/external IO touched, architecture-enforcer when layer-boundary changes, performance-auditor when hot-path changes) | None |
| `cautious` | +1 additional `code-reviewer` pass with stricter instructions | None |
| `defensive` | +1 `code-reviewer`, +1 `architecture-enforcer` regardless of diff | Dispatch `debugger` pre-review on the diff for root-cause sanity check |
| `recovery` | Full reviewer set regardless of diff (`code-reviewer`, `security-auditor`, `architecture-enforcer`, `performance-auditor`) | Dispatch `debugger` + `error-detective` pre-review |

**What actually applies these adjustments (stated plainly, 2026-08-28).** **Neither column is wired as shipped** *(corrected 2026-08-29 at the code gate: the 2026-08-28 stamp wrongly called the Pre-review column live)*. The **Pre-review additions** column has no profile-conditional dispatch anywhere in this skill — the only `debugger` / `error-detective` dispatch is Step 1's red-test diagnosis, which is triggered by failing tests rather than by the profile, is fed the test output rather than the diff, and stops the run before Step 2, so by construction it is never *pre-*review. The **Reviewer adjustment** column is **not wired** either: no agent in this pipeline fans out to `code-reviewer` / `security-auditor` / `architecture-enforcer` / `performance-auditor`. `code-lead` reviews the diff **solo** — `agents/code-lead.md` grants it `Read, Glob, Grep, Bash, Write` and no `Agent(`, so it cannot dispatch a panel. Its contract *does* still refer to one: `agents/code-lead.md:50`, `:52` and `:107` condition the verdict on an orchestrator `AXES:` line. Those clauses are stamped there as inert — no agent in this pipeline emits an `AXES:` line — and a code-lead that receives none applies its remaining criteria rather than blocking on a missing artifact. Read that column as the intensity ladder HQ applies by hand when it judges a run warrants extra scrutiny, not as automatic fan-out. Wiring the panel was M51 item 1, dropped 2026-08-28 with the minimal freeze (`ROADMAP.md`, ADR-012 amendment 4) — the review panel is a component the rebuild map marks DIES, so G-Proof rebuilds it rather than 2.5 wiring it.

Pass the active profile to code-lead in Step 4 so it can scale its own scrutiny. Announce the profile once at the top of the run:
```
Telemetry profile: [profile] — review intensity adjusted accordingly
```

## Step 1 — Run the test suite

**Installed-copy drift check (routine, visible-only — ADR-008 clause 5).** Before anything else, do a one-shot hash comparison of the installed `.claude/hooks/` copy (plus `.claude/hooks/lib/`) against the canonical `hooks/` source in this repo. This covers hooks and libs only — it is the hooks+libs subset of the comparison `/g-doctor` Check 16 performs; Check 16 proper additionally covers g-rules and agents, which this routine check does not:
```bash
hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    cksum "$1" | awk '{print $1, $2}'
  fi
}
```
For each top-level script in `hooks/` and each lib script in `hooks/lib/*.sh`, compare `hash_file` of the canonical source against its installed counterpart at `.claude/hooks/<file>` and `.claude/hooks/lib/<file>` respectively. A missing installed file counts as drift, same as Check 16. Skip this check silently (report `Installed-copy drift: not applicable — no canonical hooks/ in this checkout`) if `hooks/` does not exist at the repo root, so /g-review stays usable outside this repo's own dogfooded copy.

Also resolve `<git-hooks-dir>` via `git rev-parse --git-path hooks` and extend the same comparison to the native install site: `hooks/pre-commit` → `<git-hooks-dir>/pre-commit`, and each file in `hooks/lib/*.sh` → `<git-hooks-dir>/lib/<file>`. Before comparing, read the first lines of `<git-hooks-dir>/pre-commit` for the literal marker `G-Forge commit gate`; if it is absent, the slot holds a foreign, non-G-Forge hook — skip this half of the comparison with a note (`<git-hooks-dir>/pre-commit not G-Forge-managed — skipped`) rather than counting it as drift.

Report the result as one line, verbatim, in the review record:
- Clean: `Installed-copy drift: clean`
- Drifted: `Installed-copy drift: N file(s) drifted — run /g-update ([file], [file], ...)`

**This result NEVER gates the MERGE READY / HOLD verdict.** It is reported for visibility only — carry the line forward unchanged into Step 4's dispatch to code-lead and into the verdict presented in Step 6, but do not let drift (of any degree) turn a MERGE READY into a HOLD, and do not ask code-lead to treat it as a finding.

Before reviewing any code, verify the test suite passes.

**Run the deterministic suite directly — no agent indirection.** The suite run is a fixed command with a parseable `Results:` contract; it needs no judgment, so it is executed directly by HQ rather than dispatched through an agent. If `tests/run-all.sh` exists at the repo root:
- Run `bash tests/run-all.sh` directly and capture its output verbatim. This is the mandatory suite action for this repo — do not glob or dispatch anything to obtain it.
- If the suite's expected runtime may exceed the shell tool's maximum timeout (~10 min), run it detached — `nohup bash tests/run-all.sh > <logfile> 2>&1 & disown` — then poll the log for the runner's final results line. Never trail a pipe (e.g. `| tail`) onto a backgrounded suite run: it silently drops output or fakes a hang.
- Its report must include real pass/fail counts and, on any failure, the actual failing lines from the runner output.
- HQ sums the runner's per-suite table independently before accepting any total. A summary total that disagrees with its own table is treated as confabulated — the summed table wins, and the discrepancy is recorded in the review record (claim-vs-data doctrine, three occurrences through M-audit).
- Include the captured verbatim runner output as the attested test result passed to code-lead in Step 4.
- Apply the pass/fail branching described below: on a fully green run, continue to the **Project-specific gate fixtures needing judgment** step immediately below, then Step 2; on any red or partial run, follow the **If any tests fail** branch below.

**Project-specific gate fixtures needing judgment.** After the deterministic suite run above, Glob `.claude/agents/*-dev.md`. If exactly one file matches, dispatch it — scoped strictly to project-specific gate fixtures whose pass/fail requires interpretation (e.g. a `g-dev/` fixture set), never as a substitute for the direct `tests/run-all.sh` run above. Apply the same attestation doctrine: real pass/fail counts, verbatim runner output required (a self-declared "tests pass" claim with no runner evidence is UNVERIFIED per finding #20 doctrine and is treated the same as a failed run below), and HQ sums its per-suite table independently before accepting any total. Fold its verbatim output into the attested test result passed to code-lead in Step 4, and apply the same pass/fail branching above to its result. If more than one `.claude/agents/*-dev.md` file matches, ask the developer which one to dispatch. If none match, this step is a no-op. Either way, continue to Step 2.

**If `tests/run-all.sh` does not exist, fall back to the following inline detect-and-run behavior.**

**Detect the test command** using this priority order:
1. Check `package.json` scripts for `"test"` — if found, use `npm test` (or `bun test` / `yarn test` based on lockfile)
2. Check for `pytest.ini`, `pyproject.toml` with `[tool.pytest]`, or `tests/` with `.py` files — use `pytest`
3. Check for `Makefile` with a `test` target — use `make test`
4. Check `g-docs/project_brief.md` Tests field for the framework name
5. If no test command can be detected: ask the developer — "What command runs your test suite?" — wait for answer

**Run the test command.** Capture the output.

**If all tests pass:**
- Report: `✓ Tests passed — proceeding to code review`
- Continue to Step 2

**If any tests fail:**
- Do NOT write `.claude/g-forge-approved`
- Report the failing tests verbatim
- Dispatch `error-detective` with the full test output and the current diff (`git diff <mainline>...HEAD` — `<mainline>` per Step 2's resolution). Ask it to identify the root cause of each failure — file, line, pattern.
- After error-detective returns, dispatch `debugger` with error-detective's findings and the relevant source files. Ask for a concrete fix strategy.
- Present both diagnoses to the developer, then stop with verdict: `HOLD — tests failing. Diagnosis above. Fix all failures before re-running /g-review.`
- Do not proceed to Step 2.

**If the project has no tests** (no test directory, no test script, no test framework detected):
- Report: `⚠ No test suite detected`
- Ask the developer: "No tests found. Options: (a) dispatch test-writer to add an appropriate test suite now, (b) skip tests for this review (one-time override). Which do you prefer?"
- **If developer chooses (a):** dispatch the `test-writer` agent with the current diff and project stack context. Ask test-writer to write tests covering the changed code. Once tests are written and pass, continue to Step 2.
- **If developer chooses (b):** note `⚠ No tests — developer override` in the review output and continue to Step 2. Do not block.

## Step 2 — Gather the diff

The primary target is the tree the sentinel will bind to at commit time — the staged set unioned with unstaged-but-tracked modifications, the same union `hooks/check-commit.sh`'s `-a`/`--all` handling already computes:
```
git diff --staged
```
unioned with:
```
git diff --name-only
```
Combine both into the diff under review — this is what `git write-tree` will hash if the developer commits as-is (including via `git commit -a`), so reviewing it here is what makes the Step 6 sentinel binding coherent (ADR-004).

If that union is empty, fall back to `git diff <mainline>...HEAD` — this covers resuming review on a branch that already carries committed-but-unreviewed history (e.g. an interrupted multi-commit session). This fallback role is unchanged from before; only the priority is inverted. Resolve `<mainline>` once here and reuse it wherever this skill diffs against the mainline: the current branch's configured remote (`git config --get branch.<branch>.remote`, else `origin`), then the first of `refs/remotes/<remote>/HEAD` (short name, remote prefix stripped), `main`, `master` that `git rev-parse --verify` accepts.

If both are empty, ask the developer: "What branch or commit range should I review?"

After capturing the diff, check whether it includes changes to any dependency manifest: `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Pipfile`, `pyproject.toml`, `pom.xml`, `build.gradle`. Set `manifest_changed: true` if any are present in the diff. This flag is used in Step 4 to dispatch `dependency-auditor` in parallel.

## Step 3 — Gather done conditions

Check for done conditions in this order:
1. The relevant plan file (check `g-docs/plans/` for the most recent `.md` file, or a spec mentioned by the developer)
2. The current milestone file in `g-docs/milestones/`
3. Ask the developer: "What are the done conditions for this implementation?"

If no done conditions can be found, note this — code-lead will flag it as a process gap.

## Step 4 — Dispatch code-lead

Dispatch the `code-lead` agent. Provide **all of the following** in the prompt so code-lead does not re-run already-completed checks. Code-lead uses the compact return format — parse its `RESULT:` field; on `HOLD` or `ESCALATE` read the `DETAIL:` file before presenting verdict to the developer.

- **Attested test result** — state explicitly: `"Tests: PASS (attested — exit 0, output below)"` and include the captured output from Step 1, OR `"Tests: skipped — developer override"` if the developer chose (b). If tests failed, you do not reach this step.
- **Attested type-check result** — if a type-checker was run (e.g. `vue-tsc --noEmit`, `tsc --noEmit`) in any prior step or by an implementing agent, include: `"Type-check: PASS (attested — exit 0)"`. If not run, omit this line.
- The `Installed-copy drift:` line from Step 1, verbatim. Tell code-lead explicitly: this is informational only, it must appear in the review record but must never factor into the MERGE READY / HOLD verdict.
- The full diff from Step 2
- The done conditions from Step 3
- The current branch name (from `git branch --show-current`)
- The task list (if known)
- **If this run claims to close one or more findings from a prior HOLD** (trigger: the claim itself, not "the same file set" — the normal fix-and-re-run cycle routinely changes which lines are touched — see Step 4b): instruct code-lead to perform the fix-closure sweep described in its own contract (`agents/code-lead.md` `## Fix-closure sweep (when instructed)`, code-lead.md:55-66) — for each finding claimed closed, identify the exact literal fact the fix changed, grep it across the whole repo to confirm no stale copy survives, and record the grep command and its output in its own review record. List the specific prior-round findings being claimed closed in the dispatch prompt so code-lead knows which ones to sweep.
- `output_file`: mint a per-run path, `g-docs/agent-output/review/code-lead-[YYYY-MM-DD]-[request-slug]-r[N].md`, where `[request-slug]` is a short slug minted at dispatch summarizing what's under review (e.g. the active milestone, or the changed file set) — same slugify convention `/g-plan` uses, and the same convention `doc-reviewer-[date]-[slug]-r[N].md` uses on the doc-side gate. `[N]` is the round ordinal: **1 + the highest ordinal among existing files matching `code-lead-[same date]-[same slug]-r*.md`** in `g-docs/agent-output/review/` (glob that pattern before minting the path; no matches → `r1`, highest `r2` → `r3`, and so on — highest-plus-one, not a count, so a hand-deleted middle record can never cause an overwrite). Round records are **never deleted** — the round ordinal is what discriminates the path, so two same-day review rounds on the same request mint distinct files and neither collides with nor overwrites the other; every prior round's record survives on disk for Step 4c to read. Create the `g-docs/agent-output/review/` directory first if it does not exist.

code-lead will verify remaining done conditions structurally (file checks, grep, read) and review the diff itself — it holds no `Agent(` grant, so this is a solo review, not a panel (see Step 0). It must NOT re-run tests or type-check when attested results are provided. Pass the telemetry profile from Step 0 to code-lead so it can scale its own scrutiny; no pre-review additions are dispatched for it by anyone as shipped — see the Step 0 note.

If `manifest_changed` is true, dispatch `dependency-auditor` **in parallel** with code-lead. Provide it the changed manifest file(s), the diff context, and mint its `output_file` with the same round-ordinal discipline as code-lead's path above: `g-docs/agent-output/review/dependency-auditor-[YYYY-MM-DD]-r[N].md`, where `[N]` is **1 + the highest ordinal among existing files matching `dependency-auditor-[same date]-r*.md`** in `g-docs/agent-output/review/` (glob that pattern before minting the path; no matches → `r1`, highest-plus-one otherwise — round records are never deleted). (dependency-auditor holds a `Write` grant scoped to its own report files, so it writes this record itself.) Wait for both to return, then include dependency-auditor's findings in the materials passed to code-lead for its final verdict (so any dependency risks are factored into MERGE READY / HOLD). If dependency-auditor returns `RESULT: HOLD` or any **CRITICAL or MAJOR** severity findings (its shared Critical/Major/Minor scale — a CRITICAL is a security advisory, a MAJOR is a deprecated/unmaintained or license-conflict dep), include them as blocking items in the HOLD verdict regardless of code-lead's position on other issues.

Wait for code-lead's complete verdict.

**`.claude/review-holds` — this skill owns both sides of it.** The counter is the number of code-gate HOLDs that are **currently unresolved**, not a lifetime total, and no other skill writes it (`g-docs/telemetry-metrics.md` metric 4, counter policy).

- **Increment.** If code-lead returns HOLD, increment by 1 — this feeds the rework-rate telemetry metric regardless of the active profile. If the file does not exist, create it with value `1`. The increment is unconditional; only the *review-intensity adjustments above* depend on the profile.
- **Decrement.** If this run **closes** one or more prior-round HOLD findings and reaches an effective MERGE READY, decrement by 1 per closed HOLD round, **floored at 0** (never write a negative value; if the file is absent or unparseable, treat it as `0` and leave it at `0`). Do this only after Step 4b has confirmed the closure evidence — an unevidenced closure claim is not a closure, so it does not decrement. Resolution is the trigger: the HOLD that was counted has stopped being true, so it stops being counted.
- **Never reset it wholesale**, and do not expect `/g-telemetry` to. *(Retired 2026-08-28: `/g-telemetry` used to reset the counter to `0` on a `stable` profile, and that was the only clearing path. With no decrement it made a latch — the counter only grew, growth forced a ⚠ on rework rate, and a ⚠ made `stable`, hence the reset, unreachable. Found 2026-08-29 on this repo at `fix_after_feat` 7 + `review_holds` 34 = `rework_signal` 41, over 30 `feat:` commits — a 137% rework rate against a 20% threshold. See `g-docs/field-reports/2026-08-28-g-sharp-telemetry.md` §2.)*

## Step 4b — Fix-closure sweep record check (HQ-side, required whenever this round claims to close prior findings)

Trigger: this run claims to close one or more findings from a prior HOLD — keyed on that claim, never on "the same file set" (see the dispatch-prompt bullet in Step 4).

code-lead performs the sweep itself, in Step 4, while it is alive and dispatched, per its own contract (`agents/code-lead.md` `## Fix-closure sweep (when instructed)`, code-lead.md:55-66) — this step is HQ's required check that its record actually carries the evidence, not a step that performs the sweep:

- Open code-lead's review record at the per-run `output_file` path minted in Step 4.
- For every prior-round finding this run claims to close, confirm the record states: the exact literal fact that changed, the grep command used to search for stale copies elsewhere, and the grep output.
- **A closure claim with no recorded sweep evidence in the record does not count as closed.** This converts the round's **effective verdict** to HOLD, classed as Currency — a stale/unswept fact surviving is exactly what the Currency lens blocks on — as a distinct HQ-derived verdict input alongside code-lead's own `RESULT:` line, never a rewrite of code-lead's verdict text (presented in Step 6 as a separate HQ-derived blocking item). Because the effective verdict is no longer MERGE READY, Step 5 is correctly skipped under the ordinary Step 5 rule (HOLD/ESCALATE verdicts skip the smoke test) and Step 6 does not write `.claude/g-forge-approved`, even if code-lead's own `RESULT:` line reads MERGE READY. If code-lead's own line read MERGE READY, also increment `.claude/review-holds` by 1 here per Step 4's telemetry rule — the effective HOLD counts for rework-rate telemetry the same as a literal HOLD return, so the counter never undercounts a Step 4b block. Conversely, a closure that **does** carry its sweep evidence is what authorises Step 4's decrement: this step is the gate on both directions, so an unevidenced claim can neither clear a finding nor clear the counter.
- The record above lives at `g-docs/agent-output/review/`, which is gitignored and session-scoped (G-RULES §I) — it does not survive a fresh clone and is not itself the durable proof of closure. Once a closure is confirmed here, carry it forward onto a committed surface: add one line to the `## Active Session` handoff or the closing `g-docs/todo.md` row naming the finding closed and the sweep result (e.g. `"closure sweep: grep '<the old literal>' — 0 hits outside historical records, closed"`, with the angle-bracket text replaced by the actual literal that changed).
- If this run does not claim to close prior findings, skip this step silently — it does not apply.

## Step 4c — Round-3 consolidation note

State source: round history means the surviving `code-lead-[YYYY-MM-DD]-[request-slug]-r[N].md` record series minted in Step 4 — round-discriminated and never deleted, so the full `r1..rN` run for the current date+slug is always on disk (and, for a review spanning multiple dates, prior dates' series for that same request alongside it).

- **If prior rounds' record files are visible** (the `r1..r(N-1)` records of the current date+slug series are present in `g-docs/agent-output/review/` this session, or a prior date's series for the same request is locatable): count, per finding **class** (the same recurring claim or fact across rounds — not the round counter alone), how many consecutive rounds it has appeared as a Critical or Major finding — grep the finding class across the `r1..rN` records of the series to get this count. When a class reaches its third round, add a note alongside the Step 6 presentation: "round 3 on this class — consolidate the repeated facts into one source of truth instead of patching."
- **If prior rounds' records are not visible** — a fresh session with no `g-docs/agent-output/review/` history, or no prior-round records locatable for the same request — note that plainly: "round history unavailable this session; cannot determine round count for this finding class." Do not guess or infer a count from memory.
- This is a **note only**. It never blocks, never changes the MERGE READY / HOLD verdict, and never overrides the Step 4 severity contract. It exists to name the moment a class of finding should stop being patched instance-by-instance and start being consolidated.

## Step 5 — Tier 3 Smoke Test (MERGE READY path only)

If code-lead's verdict is **HOLD** or **ESCALATE**, skip to Step 6 — no smoke test needed until blocking issues are fixed.

If code-lead's verdict is **MERGE READY**:

1. Check whether `.claude/tier3-active` exists. If it does, a listen-mode session is already in progress — skip straight to Step 6.
2. Print the testing instrument:
   - Check for `g-docs/qa-scope/<milestone-slug>.md`. If it exists, read it and print the in-scope test groups.
   - If no QA scope doc: check whether the project has a QA panel (README, project docs). If it does, list the known affected test groups.
   - If no QA panel: retrieve or regenerate the test plan that was produced at milestone planning. Print it in full — the developer uses it as their checklist.
3. Prompt the developer:

   > "Code review passed. **Tier 3 — smoke test the changes.**
   > Work through the list above and report each finding in chat — say **'done this round'** when finished."

4. Write `0` to `.claude/tier3-active`.
5. **Listen mode is now active.** Rules while in listen mode:
   - Do NOT edit any files.
   - Do NOT suggest fixes or make comments about what might be wrong.
   - For each finding the developer reports, respond only with: `Bug N logged — <area>`
   - Increment the count in `.claude/tier3-active` after each acknowledgement.
6. When the developer says **"done this round"**:
   - Delete `.claude/tier3-active`.
   - If the count was **0** (no bugs reported): proceed to Step 6.
   - If any bugs were logged: triage the full batch (systemic vs. isolated), dispatch fix waves, re-run from Step 1 after fixes land. Do not proceed to Step 6 until a clean smoke-test round returns 0 bugs.

## Step 6 — Present verdict and manage sentinel

Present code-lead's verdict to the developer verbatim, followed by the `Installed-copy drift:` line from Step 1 — this is a visibility-only report and never changes the verdict above it, whatever it says.

Append any round-3 consolidation note from Step 4c under the finding class it applies to — advisory only, never a reason to change the verdict. If Step 4b's required sweep-record check fired (in whole or in part) — a surviving stale copy of a claimed-closed fact, or the required sweep evidence missing from code-lead's record — present that as a separate HQ-derived blocking item alongside code-lead's own verdict line, name it as an HQ-side gate (not a rewrite of what code-lead returned), and do not proceed to the MERGE READY path below on it.

**If verdict is MERGE READY:**
- Create `.claude/` directory if it does not exist
- Compute the sentinel stamp (binds the sentinel to the exact reviewed tree — ADR-004):
  - `commit_sentinel_ts`: binds the sentinel to the exact tree reviewed in Step 2, computed in order:
    - First, stage any unstaged-but-tracked files that were part of the Step 2 staged + unstaged-tracked union (`git add -u`), so the index now holds exactly what was reviewed.
    - Then take `git write-tree` of the now-staged index. This reproduces the same tree `hooks/pre-commit`'s own `git write-tree` will hash at commit time (whether the developer commits with plain `git commit` or `git commit -a`), keeping the stamped tree and the committed tree identical.
    - If Step 2 instead fell back to `git diff <mainline>...HEAD` (nothing staged or unstaged to review), the index already equals HEAD's tree and no extra staging is needed.
  - `commit_sentinel_head`: `git rev-parse --verify HEAD`
  - `commit_sentinel_worktree`: `git rev-parse --show-toplevel`
- Write `.claude/g-forge-approved` with content: `commit_sentinel_ts=<write-tree output> commit_sentinel_head=<rev-parse --verify HEAD output> commit_sentinel_worktree=<show-toplevel output>` (one line, space-separated `key=value` fields, exact field names — do not rename them)
- If this review covered doc/mixed changes and `.claude/g-forge-docs-approved` is also being written (see doc-review flows), write the identical stamp format there too, using the same tree+HEAD pair — on a mixed commit both sentinels bind to the one tree being committed.
- Tell the developer: "MERGE READY. Commit gate unlocked — you can now run git commit and merge."
- Ask once: "Would you like a PR description? (yes/no)" — if yes, dispatch `pr-writer` with the full diff from Step 2 and the done conditions from Step 3. Present the PR description. If no, continue silently.

**Milestone close-out (MERGE READY only):**

1. Read `g-docs/todo.md` — identify tasks marked as done or the tasks being reviewed in this session.
2. Read `g-docs/ROADMAP.md` — find the current active milestone (look for `🔄 In progress`).
3. Read the active milestone file from `g-docs/milestones/` (e.g. `g-docs/milestones/M1.md`). If the `g-docs/milestones/` directory does not exist or no matching tasks are found, skip silently — do not report anything.
4. For each task in the milestone's `## Scope` checklist that matches a completed task from this review, mark it `[x]`.
5. If ALL scope items in the milestone are now `[x]`:
   - Update the milestone status header to `✅ Complete`
   - Update the corresponding milestone entry in `g-docs/ROADMAP.md` from `🔄 In progress` to `✅ Complete`
   - Leave the completed milestone in place under `## Milestones` marked `✅ Complete` — there is no separate `## Done` section; completed milestones stay as history where they are (status key: ⬜ Not started · 🔄 In progress · ✅ Complete)
   - Report: `✓ Milestone [ID — Name] closed out`
   - **Version bump prompt:** Check the milestone entry in `g-docs/ROADMAP.md` for a `**Version:**` field. If present, use that as the target. If absent, detect the current version from (in order): `.claude-plugin/plugin.json`, `package.json`, `pyproject.toml`, `Cargo.toml`, and suggest a bump based on the milestone's nature (features → minor, fixes → patch, breaking → major).
   - Tell the developer:
     ```
     ✓ Milestone closed — version bump recommended
       Target version:  [from g-docs/ROADMAP.md Version field, or suggested]
       Run /g-update after bumping to sync project files.
     ```
   - Do not bump the version automatically — the developer decides and commits it separately.
   - **Auto-retro:** Immediately run `/g-retro` — use Glob to find `skills/g-retro/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it, then follow its instructions. Use the milestone name as the topic slug (e.g. `M3-auth-refactor`). Do not wait for the developer to trigger it.
   - **Milestone close swarm:** Once the retro is written, dispatch the following concurrently — they are read-only analysis and can run in parallel:
     - `/g-telemetry` — refreshes reliability metrics now that the milestone is in the corpus. Use Glob to find `skills/g-telemetry/SKILL.md` and follow its instructions.
     - `/g-align` — brief-deviation check now that a milestone has closed: confirms the project is still serving `g-docs/project_brief.md` (goals, non-goals, MVP, tech decisions) rather than drifting. Use Glob to find `skills/g-align/SKILL.md` and follow its instructions. Advisory — surfaces ALIGNED or DRIFTING with a recommendation; never blocks the close-out. Skip silently if `g-docs/project_brief.md` does not exist.
     - **ADR prompt** — ask the developer once: "Were any significant architectural decisions made during this milestone that should be recorded as an ADR? (e.g. a new pattern adopted, a library chosen, a structural constraint introduced) — yes/no." If yes, run `/g-adr`. If no, continue.
   - **Pattern mining (after the swarm, not part of it):** Once the close swarm above has finished, run `/g-patterns` — use Glob to find `skills/g-patterns/SKILL.md` and follow its instructions. It mines the retro just written alongside previous retros. Unlike the swarm members, it is not read-only and not safe to run concurrently with them: it writes `g-docs/patterns/latest.md` on every run, it may append a bullet to `g-docs/ROADMAP.md`'s `## Active Session` block in a MINE pass and **removes that same bullet** at RESOLVE close-out — either edit would race the handoff `/g-retro` just wrote if the two ran in parallel — and it pauses for developer input at its triage step. In a RESOLVE pass (entered when an earlier session left a PENDING report) it additionally **edits the fix target itself** — a rule, profile, agent, skill, or hook file, plus the mirrored `.claude/` copy when run in a plugin-source checkout — renames `g-docs/patterns/latest.md` to its resolution date, may append to `g-docs/patterns-deferred.md`, and may append to `CHANGELOG.md` under an existing `## [Unreleased]` when an applied fix lands in shipped source. Running it after the swarm lets the retro's handoff settle first and lets its triage prompt stand alone. **Ordering against the version bump:** the bump prompt above is presented before this step, so a RESOLVE pass reached here can append an `[Unreleased]` entry after the developer has been told to cut the release. When both fire in one close-out, cut the release section only after this step returns, so a rule change applied at close is not stranded under `[Unreleased]` while its own release section is being written.
   - **Wiki refresh (end-of-milestone task):** After the close swarm, run `/g-wiki` to update the human-facing project wiki (`g-wiki/`) for the milestone that just shipped — use Glob to find `skills/g-wiki/SKILL.md` and follow its instructions (incremental scope: document what this milestone built and reconcile existing pages against the code). The wiki is committed project content; refreshing it at each milestone close is what stops it going stale. If the developer would rather defer, note `Refresh g-wiki for [milestone]` as a pending task in `g-docs/todo.md` instead of running it now.
   - **Every-other-milestone health check:** Read `.claude/milestone-count` if it exists (contains an integer, default 0 if absent). Increment by 1. If the result is odd, run `/g-doctor` after the close swarm — use Glob to find `skills/g-doctor/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it, then follow its instructions. Write the new count back to `.claude/milestone-count`.
6. If only some tasks are done:
   - Save the partial updates to the milestone file
   - Report: `✓ [N] milestone tasks checked off — [M] remaining`

**If verdict is HOLD — FIX REQUIRED:**
- Do NOT write `.claude/g-forge-approved`
- Tell the developer: "HOLD. Fix all blocking items listed above, then re-run /g-review."

**If verdict is ESCALATE:**
- Do NOT write `.claude/g-forge-approved`
- Present the escalation details and ask the developer for guidance before proceeding.

## Rules
- Never modify code-lead's verdict — present it exactly.
- The Step 1 installed-copy drift check is visible-only — it is always reported in the review record, but it never gates or downgrades the MERGE READY / HOLD verdict.
- Never write `.claude/g-forge-approved` for anything other than MERGE READY.
- Never skip Step 5 (Tier 3 smoke test) on a MERGE READY verdict — unless Step 4b's required sweep check has converted the round's effective verdict to HOLD (Currency), in which case Step 5 is correctly skipped because the effective verdict is no longer MERGE READY. The sentinel must not be written until at least one clean smoke-test round completes.
- If code-lead is blocked by missing information, gather it and re-dispatch — do not guess.
- The sentinel is automatically cleared after the next `git commit` by the commit hook.
- In listen mode: zero edits, zero suggestions, acknowledgement only. Violations of listen mode reset the round.
- The Step 4b fix-closure sweep record check is required, not advisory, whenever a run claims to close one or more findings from a prior HOLD — keyed on that claim, never on "the same file set". code-lead performs the sweep itself in Step 4 while dispatched; Step 4b is HQ's required check that its record actually carries the sweep evidence. A closure claim with no recorded sweep output in code-lead's review record does not count as closed, and blocks MERGE READY the same way a HOLD does, independent of code-lead's own verdict line.
- When a code-fix round and a doc-fix round run in parallel on the same HOLD, each fix dispatch greps the other lane's changed literals (the facts each round rewrote) before returning — a fact changed in one lane and not swept in the other is a Currency-class finding next round, not a surprise.
- The Step 4c round-3 consolidation note is advisory phrasing only — it is never grounds to change a verdict, skip Step 5, or override the Step 4 severity contract.

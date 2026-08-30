# Fable audit F2 — SURVIVES agents + the record seam (2026-08-30)

**Cycle:** M52 F2 (scope amendment 2026-08-30, `ROADMAP.md` M52 entry). **Read by:** HQ on the session model, directly — §A1 override, developer-decided. **Slice:** `agents/{architecture-enforcer,doc-reviewer,spec-writer,test-writer,debugger,error-detective,doc-writer,project-manager}.md` and `skills/{g-resume,g-retro,g-adr,g-doc-review}/SKILL.md` — every file read whole at `4e54ef1` (pre-wave text). **Filter:** every finding below sits on a SURVIVES component (`audits/2026-07-rebuild-map.md:30-62`) or is adopter-facing (F2-3's three out-of-slice carriers: DIES/SHRINKS on the map, shipped in 2.5, same gate fail-open).

**Probes:** two live dispatches (`project-manager` on sonnet, `test-writer` on haiku — output quoted per finding), plus disk/git/grep probes recorded inline. No probe touched the project tree (`git status --porcelain` empty after both dispatches; the test-writer probe wrote only to the session scratchpad).

## Findings

### F2-1 — Major · "ask the developer and wait" in dispatched agents has no channel

- `agents/architecture-enforcer.md:54` — "Ask for the project's layer rules before reviewing if they haven't been provided." Its contract has no `BLOCKED` value (`:47` `RESULT: PASS|HOLD`), and neither `agents/review-orchestrator.md:21` nor `skills/g-review/SKILL.md:19-22` passes the rules file in the dispatch prompt (`grep -n -i "layer rules\|rules/architecture\|architecture-<stack>" skills/g-review/SKILL.md agents/review-orchestrator.md agents/code-lead.md` → no hits).
- `agents/test-writer.md:35-37` — "tell the developer that no test framework was detected and ask … Only proceed after they answer" / "ask before defaulting to anything".
- `agents/error-detective.md:59` — "ask for the actual error output if not provided."
- `agents/project-manager.md:83` — "Wait for the developer to answer all three." · `:101` — "Do not proceed without explicit human approval."

A dispatched agent returns exactly once; there is no user channel. **Probe — `project-manager` dispatched with "can you ask the user a question and wait for their answer from inside this dispatch?":**
```
No — I have no user-facing message/response tool distinct from my final output; this dispatch
has no mechanism to send a question and block for a reply, only to return one final text result.
```
**Probe — `test-writer` dispatched on `hooks/lib/semver-compare.sh` with no framework named (this repo has no `package.json`):** it neither asked nor returned `BLOCKED`; it inferred the bash convention from `tests/` and returned `RESULT: WRITTEN … TESTS: 3 written`. The behaviour is right; the contract text is dead prose the agent ignores — and for `architecture-enforcer` the same dead text means a review dispatched without rules has no defined path at all.

**Fix (Task 29 / 30):** `architecture-enforcer` locates the rules itself — Glob `.claude/rules/architecture-*.md`, then `CLAUDE.md`'s layer map — and, when none exists, reviews against the general principles in its own "What to check" list and says so in the record (no new result value; `review-orchestrator` parses `PASS|HOLD`). `test-writer` matches existing test files under the project's test directory in any language before declaring no framework; only when no convention is discoverable does it return `BLOCKED` with the question in `SUMMARY`. `error-detective` returns `BLOCKED` naming the output it needs. `project-manager`: when dispatched as a subagent, questions and approval requests are *returned* to the calling session, which carries them to the developer — the agent never waits.

### F2-2 — Major · `project-manager` contradicts itself and the shipped pipeline

- `:114` "Never touch a file yourself." vs `:67` "Update `g-docs/ROADMAP.md` and the milestone file once approved", `:42` "Record override in the plan header", and the `Write, Edit` grant at `:5`. The description at `:3` says "Does not write code or touch implementation files" — the narrower, correct rule.
- `:106` "If Superpowers is available, use `subagent-driven-development` for wave execution." — a third-party plugin path that `skills/g-execute/SKILL.md:9` ("Never substitute `superpowers:dispatching-parallel-agents`") and `skills/g-plan/SKILL.md:361` ("never via superpowers") both forbid. `grep -rn -i superpowers agents/ skills/` → this line is the only live carrier outside `g-docs/archive/` and CHANGELOG history.
- `:95-111` Phases 2–4 re-implement the `/g-plan → /g-execute → /g-review` pipeline inline: dispatch `task-decomposer`/`wave-planner`/`spec-writer` directly, "hand each wave to HQ", "dispatch `code-lead` with the full branch diff … until MERGE READY". `code-lead` never writes the commit sentinel — `skills/g-review/SKILL.md:211` is its only writer (`grep -n g-forge-approved agents/code-lead.md` → 0 hits) — so a MERGE READY reached this way leaves `check-commit.sh` denying the commit.
- No `## Return format` block (`grep -L "## Return format" agents/*.md` → `feature-implementer`, `pr-writer`, `project-manager`); the other two are out of slice and left alone.

**Fix (Task 29):** `:114` → "Never touch implementation files. The only files you write are `g-docs/ROADMAP.md`, `g-docs/milestones/*`, `g-docs/todo.md` and a plan header (override record)." Delete `:106`. Phases 2–4 route to the skills by name (`/g-plan`, `/g-execute`, `/g-review` — which dispatches `code-lead` and writes the sentinel) instead of re-dispatching the agents; keep the `Agent(...)` grant (Level 1's `code-lead` consult is legitimate). Add a compact return block (`RESULT: DONE|BLOCKED` · `VERDICT:` · `QUESTIONS:` · `SUMMARY:`) so a dispatched PM returns a contract, not prose.

### F2-3 — Major · reviewer `memory: project` carries verdicts across dispatches — a "verified clean, don't re-spend" list that is already stale

Five agents grant persistent memory (`grep -ln "^memory:" agents/*.md` → `architecture-enforcer`, `code-reviewer`, `dependency-auditor`, `doc-reviewer`, `security-auditor`); no body constrains what the memory may hold (`grep -n -i memory` on the five bodies → only the frontmatter key). What it holds today, on this repo (`.claude/agent-memory/g-forge-doc-reviewer/`, 42 files, 1,418 lines across all four memory dirs):

```
waves45-skills-tests-ci-gate.md:28  ## Don't re-spend a round on these (all verified exact 2026-08-29)
waves45-skills-tests-ci-gate.md:30  `profiles/claude-plugin/rules/architecture.md:6` … / `:19` … · `README.md:150`/`:277`/`:382` (the three test-pinned counts, all correct and at those lines) …
waves45-skills-tests-ci-gate.md:52  - **Verified clean, don't re-spend:** `:42` and `:8` both TRUE …
minimal-freeze-rescope-gate.md:94   ## Don't re-spend a round on
minimal-freeze-rescope-gate.md:96   Every count reproduces: 19 agents · 38 skills · 56 profiles · **23 suites / 645 assertions** (hand-summed at r3, unchanged at r4) …
```
Against disk: `git log --since=2026-08-29 --name-only -- profiles/claude-plugin/rules/architecture.md skills/g-plan/SKILL.md .github/workflows/tests.yml` → changed in `9dd49c4` and `5ed9839` (both 2026-08-30); the suite is 24 suites / 720 assertions since `5ed9839`. A `doc-reviewer` dispatched today reads a memory that tells it those lines and counts are "verified exact" and not worth a round. `code-reviewer`'s memory (`review-multi-round-fix-wave-heuristics.md:20`) records the same habit as method: "Open the record with a 'Verified CLEAN' table … asks not to re-derive settled ground." Inside one round ladder that is HQ's instruction; across milestones it is a gate reviewer skipping the file it is gating. Fail direction: open.

**Fix (Task 30):** one rule in each of the five memory-holding agent bodies — *memory holds method (how to check, where a class of defect hides), never verdicts: no "verified clean", no "don't re-spend", no count. Anything in memory that reads as a verdict or a number is re-derived from disk in this dispatch before it is relied on.* Pinned by a test (Task 31) that every agent with a `memory:` key carries the rule. The existing memory files are local, gitignored here, and not touched by this cycle — the fix is the contract; the agents prune their own memory under it.

### F2-4 — Major · `/g-retro`'s handoff refresh cannot advance the handoff

`skills/g-retro/SKILL.md:45` — Cold-start "next-up line (**verbatim** from the `## Active Session` handoff)". `:99` — Step 5b writes the new handoff's "**Next up** ← the lead next action" from that cold-start. Followed as written, the only source for the new Next up is the *previous* session's Next up, so the block the skill says it "owns" (`:95`) can only reproduce itself. The ritual works in this repo because HQ rewrites the handoff by hand per §A3 before or after the retro — the skill is not the writer it claims to be.

**Fix (Task 32):** Step 3's Cold-start derives Next up from evidence — the lead open `g-docs/todo.md` row, else the active milestone's next unchecked task, else the plan's next incomplete wave — and falls back to the old handoff's line only when none exists, marked `(carried — no open task found)`; Step 5b writes that derived line. The retro file keeps the old line under a separate `**Handoff at retro:**` field so the record shows both.

### F2-5 — Minor · `/g-resume` treats a stale `.claude/compact-state.md` as a live handoff

`skills/g-resume/SKILL.md:131` reads it unconditionally as "the same block captured mid-session"; `:17`/`:135` treat its presence as "mid-flight". Nothing removes the file: `hooks/pre-compact.sh:83` writes it, `hooks/session-start.sh` never deletes it (`grep -n compact hooks/session-start.sh` → comments and counter logic only), `skills/g-init/SKILL.md:201` gitignores it. On this repo the file is a `2026-08-16T21:38:37Z` snapshot of `main`, read by a 2026-08-30 session on `chore/v2.5-minimal-freeze`. The file carries its own `# Compact State — <ts>` header and `## Branch` section, so the check is cheap.

**Fix (Task 32):** Step 1 compares the snapshot's timestamp and branch against the ROADMAP handoff's date/branch; older or on another branch → say `compact-state.md is stale (<ts>, <branch>) — ignored` and use the ROADMAP block alone.

*Out of slice, same file, carried to F3:* `hooks/workflow-checkpoint.sh:389` uses the same presence test, and `:394` greps `verify ADR` across the **whole** of `g-docs/ROADMAP.md` + `compact-state.md` — `ROADMAP.md:210` is body prose, so this repo prints "a handed-off ADR needs verifying first" on every fresh session (seen at this session's first prompt) with no ADR handed off.

### F2-6 — Minor · repo-only facts and a hardcoded mainline in shipped contracts

- `agents/doc-reviewer.md:38` — `[ADR-013](../g-docs/decisions/013-…)` relative link + "the pattern of Group D in `tests/test-lib-install-completeness.sh`": neither file exists in a consumer project; the rule (pin with a test, else omit) is stated inline and survives, the citations dangle. `skills/g-doc-review/SKILL.md:44` "ADR-013's" — same.
- `skills/g-adr/SKILL.md:227` — "ADRs written before M9 (v0.10.0) are pre-lineage" — this repo's milestone history in a consumer's skill.
- `skills/g-doc-review/SKILL.md:28` — fallback `git diff --name-only main...HEAD`: hardcoded `main`; errors on a `master`/`develop` mainline. (`skills/g-review/SKILL.md:85`, `:108`, `:208` carry the same literal — out of slice, F3.)

**Fix (Task 30 / 32):** cite the rule as plain text with "(G-Forge ADR-013)" attribution, no relative link, and describe the pin generically ("a test that fails when the count and its source disagree"); drop the M9 line; resolve the mainline the way `/g-resume` 0g does (`refs/remotes/<remote>/HEAD`, then `main`, then `master`, first that verifies).

### F2-7 — Minor · `doc-writer` body does not carry §G's README check

`.claude/rules/g-rules-G-documentation.md` (Documentation ownership): doc-writer "also checks whether the project README has a relevant section and updates it or flags the gap." `agents/doc-writer.md:27-32` covers README only when a README section is the request; the inline-doc path (`:15-25`) never mentions it, and the return block (`:41-45`) has no gap field.

**Fix (Task 30):** one line under "What good inline documentation explains": after documenting, check the README for the surface's section — update it if it exists and is stale, else report `README GAP:` in the return block.

## Not findings (read, considered, left alone)

- `agents/spec-writer.md:53` cites `profiles/claude-plugin/rules/architecture.md:6` and `:19` — both verified at those lines (`sed -n '6p;19p'`), explicitly scoped "in this repo's self-hosted case".
- `skills/g-adr/SKILL.md:206` hardcodes `~/.claude/plugins/cache/g-forge/g-forge/` for the sibling-skill Glob — the same convention as `g-afk:134/:150`, `g-execute:176`, `g-plan:163/:243/:296`, `g-review:235`; the "never hardcode" rule at `g-init:502`/`g-update:356` is about `[plugin-root]` resolution for *installs*, a different concern.
- `skills/g-doc-review/SKILL.md:82` `git add -u` before `write-tree` — an index write on a "read-only on project content" skill, but it mirrors `/g-review` Step 4 and is what ADR-004's stamp needs; documented at `:26`.
- `skills/g-retro/SKILL.md:136` "Do not commit the retro file" vs §A7 "handoff … committed before the session ends" — consistent: `/g-retro` writes, HQ commits through the gate.
- `test-writer`/`doc-writer` on haiku with §A1 "Sonnet: implement / write" — a tiering choice, not a defect; the probe showed test-writer authoring a correct bash suite on haiku.
- `test-writer` inferring the framework (probe above) — correct behaviour; the contract text is the defect (F2-1).
- `project-manager`'s `Agent(...)` grant — the probe confirmed the tool is present in a nested dispatch (`Agent, Read, Write, Edit`); the grant is live, and with F2-2 fixed it has a legitimate use (Level 1 `code-lead` consult).
- `debugger.md`, `spec-writer.md` bodies: no defect found beyond the shared items above.
- `g-resume` Step 0 (0a–0g): walked live at this session's open — every branch taken (`no-@{u}` sub-case (b), `unsynced — no upstream`, 0g `not behind origin/main`) rendered the value the closed set names. No defect found.

## Out-of-slice observations carried to F3 (evidence recorded here, no fix this cycle)

1. `agents/review-orchestrator.md:11` — "subagents cannot spawn other subagents" — contradicted by the PM probe above (nested dispatch holds an `Agent` tool) and by `audits/2026-07-modernization-report.md:293-310` (GF-21, nested subagents since v2.1.172, **[VERIFY]** still open). The README/§C claims it drags along go with it.
2. `hooks/workflow-checkpoint.sh:389/:394` — F2-5's out-of-slice half (false "ADR needs verifying" nudge every fresh session on this repo).
3. `skills/g-review/SKILL.md:85/:108/:208` — hardcoded `main...HEAD` (F2-6's twin).
4. `agents/feature-implementer.md`, `agents/pr-writer.md` — no `## Return format` block (F2-2's twin).
5. `code-reviewer` (DIES), `security-auditor` (DIES), `dependency-auditor` (SHRINKS) receive the F2-3 memory rule in this cycle because the hazard is adopter-facing and the edit is one identical line; their bodies were **not** audited.

## Wave F2 (one wave, three dispatches under the 30-call cap, then a separate attestation)

- **Task 29** — `project-manager.md`: F2-1 (PM part) + F2-2 (agent: claude-plugin-implementer).
- **Task 30** — `architecture-enforcer.md`, `test-writer.md`, `error-detective.md` (F2-1); the five `memory:` agents (F2-3 rule line); `doc-reviewer.md:38` (F2-6); `doc-writer.md` (F2-7) (agent: claude-plugin-implementer).
- **Task 31** — `tests/test-review-severity.sh`: (a) every agent with a `memory:` key carries the F2-3 rule literal; (b) absence-grep across `agents/*.md` for the ask-and-wait phrases F2-1 removes; (c) `project-manager.md` has a `## Return format` block (agent: claude-plugin-implementer, same dispatch as Task 32 — files disjoint).
- **Task 32** — `g-retro` Step 3/5b (F2-4), `g-resume` Step 1 (F2-5), `g-doc-review` `:28`/`:44` + `g-adr:227` (F2-6) (agent: claude-plugin-implementer).
- **Task 33** — attestation: full suite + falsifiability probe for every new guard in Task 31 (agent: g-forge-dev, separate dispatch).
- **Task 34** — CHANGELOG `[2.5.0]` Fixed entries; todo rows for the F3 carries (HQ).

Gate: `/g-review` + `/g-doc-review` → commit → `/g-retro` → handoff.

## HQ self-review of the fix wave (before the gate)

All three dispatches returned `DONE` first attempt, no stalls, no child dispatch; records at `g-docs/agent-output/wave-f2/task-{29,30,31-32}*.md`. HQ read every diff (`git diff` per file set) before the gate:

- Task 29 — one HQ inline correction: the implementer typed `skills/g-review/SKILL.md:211` into the Phase 4 text (an unpinned line ref, the todo 15 R2-2 class); replaced with "`/g-review` Step 4", and "re-dispatch after fixes" → "re-run `/g-review` after fixes" for coherence with the routed pipeline.
- Task 30 — the memory rule is byte-identical in all five `memory:` agents; test-writer's `BLOCKED` description at `:61` was realigned with the F2-1 edit (disclosed in the record).
- Task 31/32 — the suite's header comment replaces its typed `Total assertions: 9` with a derived-at-runtime statement (group (a) is enumerated from disk), which is the ADR-013 rule applied to the suite itself.
- Carrier sweep after the wave (`grep -rn` across `README.md`, `g-wiki/`, `g-docs/*.md`, `rules/`, `profiles/`, `templates/`, `skills/`, `agents/`, `tests/` for every literal the wave removed or moved: Superpowers / `subagent-driven-development`, the four ask-and-wait phrases, `Never touch a file yourself`, `next-up line (verbatim`, the ADR-013 relative link as a shipped-agent citation, `test-lib-install-completeness.sh` as a doc-reviewer pointer): no survivors on any shipped surface outside the audit record and the pinning test. One in-repo carrier of the ADR-013 relative link stays by design — `tests/README.md:7` (`grep -rn "013-derive-in-consumers-keep-counts-in-prose" tests/` → that one line): repo-local, the path resolves, ships to no consumer, so F2-6 does not apply to it (the r1 doc gate caught the unqualified "zero survivors" this sentence first carried). `main...HEAD` twins found out of slice — `agents/code-lead.md:38`, `agents/pr-writer.md:13`, `g-docs/agents.md:200` — added to todo row 18 (3).

## Attestation (Task 33)

`g-forge-dev-2026-08-30-f2-r1.md` (gitignored): runner `Grand total: 732 passed, 0 failed across 24 suites`, the delegate's independent per-suite sum agrees; `test-review-severity.sh: Results: 21 passed, 0 failed`. Falsifiability, scratch copy, script-driven: baseline GREEN 21/0 · doc-reviewer's memory rule deleted → RED 20/1 naming doc-reviewer · `Only proceed after they answer` re-added to test-writer → RED 20/1 naming the literal · `## Return format` broken in project-manager → RED 20/1 · a `memory: project` agent with no rule added → RED 21/1 naming the new file (the enumeration is disk-derived). Markers not yet written into the test file.

## Gate rounds

*Not run this cycle.* The session closed on a developer directive — redo this audit on Fable 5 Extra in a fresh session with the wave kept on disk — before `/g-review` or `/g-doc-review` ran on the wave. The wave and `CHANGELOG.md` are uncommitted; only this record, the retro, `g-docs/todo.md` and the handoff go through the pass-close doc gate.

Pass-close doc gate (`/g-doc-review g-docs`, records `doc-reviewer-2026-08-30-f2-passclose-r[N].md`, gitignored): **r1 DOCS HOLD 3B/2W** — every backward-facing figure reproduced; the blockers were forward-facing claims in HQ's own records (a `CLAUDE.md:23` rewrite scheduled after it was already done; an unqualified "zero survivors" sweep claim that `tests/README.md:7` falsified; `ROADMAP.md`'s M52 F3 ledger missing the row 18 this pass minted) and the warnings a pre-wave line count with no source label and the Next-up derivation being disclosed outside the ladder. The three blockers and the line-count warning fixed by HQ inline; the derivation-order warning left open by design (disclosed in the retro, the redo owns it); r2 dispatched with the closure sweep. **r2 DOCS HOLD 2B/2W** — B-1, B-3, W-2 closed with grep evidence; the two new blockers were the F1 class again: the "zero survivors" claim qualified in this record but left standing in the retro (`:6`) and the handoff (`ROADMAP.md:7`), and this very paragraph's "all five fixed" contradicting the open W-1. Fixed inline — every carrier the r2 record names, and this paragraph's own tally — plus the r2 warning that the F3 ledger omitted todo row 11 without saying why (now stated at the M52 entry); r3 dispatched. **r3 DOCS HOLD 1B/1W** — all three instructed closures held with grep evidence; the one blocker was this paragraph's *replacement* tally ("three carriers"), an unpinned count minted by a fix round — the §B hard-stop class this session's own carried rules name. The tally is omitted now; the r2 and r3 records own the carrier lists. W-1 (Next-up derivation) stays open by design; r4 dispatched.

## Tally

4 Major (F2-1, F2-2, F2-3, F2-4) + 3 Minor (F2-5, F2-6, F2-7) found; 5 out-of-slice observations carried to F3. Summed from the headed sections above.

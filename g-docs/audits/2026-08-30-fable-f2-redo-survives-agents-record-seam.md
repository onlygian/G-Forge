# Fable audit F2 REDO — SURVIVES agents + the record seam (2026-08-30)

**Cycle:** M52 F2 redo (developer directive at F2 close: redo the audit on Fable 5, fresh session, tree as is). **Read by:** HQ on the session model, directly — §A1 override carried from the F2 amendment. **Read basis:** every slice file read whole from the **working tree** (the Wave F2 fixes on disk, uncommitted); pre-wave text = `git show HEAD:<path>` at `9835c34` (the pass-close commit carries no wave files, so `HEAD` still holds the pre-wave text — confirmed by `git diff --stat`, 15 files). **Diffed against:** `g-docs/audits/2026-08-30-fable-f2-survives-agents-record-seam.md` (the F2 record), finding by finding. **Filter:** unchanged — every finding sits on a SURVIVES component (`audits/2026-07-rebuild-map.md`) or is adopter-facing. **Line-ref basis:** refs in the verdict and finding sections cite the read-time tree (Wave F2 on disk, pre-F2-R); the Wave F2-R fixes recorded below shifted some of them (e.g. `project-manager.md` `:93`→`:95`).

**Probes this cycle:** disk/grep only, recorded inline per finding — no live agent dispatches (the F2 PM/test-writer probe results are carried, not re-run; nothing in this redo contradicts them). No probe touched the project tree.

## Verdicts on the seven F2 findings

### F2-1 (ask-and-wait in dispatched agents) — **KEEP, and EXTEND** (→ R-2)

The four landed fixes verified against the working tree:
- `agents/architecture-enforcer.md:55` — locates rules itself (Glob `.claude/rules/architecture-*.md`, then `CLAUDE.md`), general-principles fallback stated in the record's first line. Matches `/g-specialize`'s install naming. Holds.
- `agents/test-writer.md:35` — any-language convention match before `BLOCKED`; `:59` `BLOCKED` description realigned. Holds.
- `agents/error-detective.md:59` — `BLOCKED` naming the output needed in `TOP_CAUSE`; consistent with `:53`. Holds.
- `agents/project-manager.md:83` — interactive/dispatched split with the `QUESTIONS:` route. Holds, and it is exactly the shape `skills/g-plan/SKILL.md:43` needs (the session presents the PM's questions and passes answers to a fresh dispatch).

**But the class was not fully swept in the one file that had three carriers.** `grep -n -i "wait for\|ask the developer\|ask before\|ask for\|human approval\|ask one" agents/*.md` (the command as actually run — an earlier transcription here dropped alternates and an escape, the code gate's r1 Minor 7) finds two survivors in `agents/project-manager.md` that F2 did not list: `:66` (Level 1 step 4) — "Wait for human approval before writing anything" — and `:93` (Phase 1) — "ask one focused clarifying question" with no dispatched-mode route. Same class, same file, same no-channel hazard. → R-2.

### F2-2 (`project-manager` contradictions + Superpowers + inline pipeline) — **KEEP, and EXTEND** (→ R-2)

- `:122` names the PM's writable files; description `:3` and body now agree. Holds.
- Superpowers line gone; `grep -rn "If Superpowers is available" agents/ skills/` → 0 hits; pinned by the test. Holds.
- Phases 2–4 route to `/g-plan` → `/g-execute` → `/g-review`; Phase 4 correctly names `/g-review` Step 4 as the sentinel's only writer. Holds.
- `## Return format` block present, pinned. Holds.

**Two residues of the same finding:**
1. **Phase 2's dispatched-mode sentence presumes outputs a dispatched PM cannot produce.** "When dispatched as a subagent, return the schedule and specs with a `QUESTIONS:` line" — a dispatched PM holds no skill tool (`tools:` `Agent(…), Read, Write, Edit`), so it cannot run `/g-plan`, and the schedule/specs it is told to return do not exist unless it re-dispatches `task-decomposer`/`wave-planner`/`spec-writer` inline — the exact path F2-2 removed. Phase 4 has the same gap unstated.
2. **Grant residue invites the removed path back.** The `Agent(task-decomposer, wave-planner, spec-writer, …)` grants have zero remaining uses in the body (Phase 2 mentions the three only descriptively, as what `/g-plan` dispatches); `code-lead` (Level 1 consult, `/g-plan` Step 1 is unaffected — it dispatches PM, not the reverse) and `pr-writer` (Phase 4) are the live grants. `grep -rn "Agent(task-decomposer" README.md g-docs/agents.md templates/ profiles/ skills/` → 0 carriers outside the frontmatter; `skills/g-plan/SKILL.md` and `/g-roadmap` dispatch those agents from the session, never through a dispatched PM. Trimming to `Agent(code-lead, pr-writer)` is safe and closes the door the F2-2 text fix left ajar. → R-2.

### F2-3 (reviewer memory carrying verdicts) — **KEEP**, no extension

The rule is byte-identical in all five `memory:` agents (diff + `grep -c`), the test enumerates the population from disk (`grep -l '^memory:'`), and the f2-r1 attestation proved both the deleted-rule and new-agent-without-rule probes RED. The three out-of-slice bodies (`code-reviewer`, `security-auditor`, `dependency-auditor`) remain un-audited — todo 18 (5) stands.

### F2-4 (`/g-retro` handoff self-copy) — **KEEP the mechanism, AMEND the order** (→ R-3)

The fix's mechanism (derive Next up from evidence, keep the old line as `**Handoff at retro:**`) is right and verified in `skills/g-retro/SKILL.md:45/:83-84/:100`. Two defects in the fix as landed:

1. **The derivation order is wrong, and the very close that shipped it proved so** (F2 retro, "Avoid"): "lead open `g-docs/todo.md` row" first would have minted todo row 5 — a carry — as Next up, when the real next action was the developer's close directive. Amended order (the retro's own suggestion, adopted): **(1) an explicit developer directive given this session about what happens next → (2) the active plan's next incomplete wave (`g-docs/plans/`) → (3) the active milestone's next unchecked task → (4) the lead open `g-docs/todo.md` row → (5) the old handoff's line, marked `(carried — no open task found)`.** Intent-proximate sources first; the todo table is the weakest evidence because §A3's own discipline leaves it holding carries, not the next action. The CHANGELOG `[2.5.0]` F2-4 entry states the old order and must move with it.
2. **Step 2's read list does not gather what Step 3's new derivation needs.** Step 2 reads journal, ROADMAP, todo, todo-done, git log, branch — but the derivation chain reads `g-docs/milestones/M*.md` and `g-docs/plans/*.md`, neither in the list. Followed literally, the fix dereferences sources it never loaded. → R-3.

*Micro-item, same file:* `skills/g-retro/SKILL.md:26` claims the journal kind set includes `note`; no hook emits it (`hooks/observe.sh:154/:156` emit `session`, `:209-220` the command kinds — commit/push/merge/branch/revert/test/destructive; `agent-lifecycle.sh` emits `agent`). Drop `note` or mark it reserved. → R-3.

### F2-5 (stale `compact-state.md`) — **KEEP**, mechanics verified

`hooks/pre-compact.sh:83-86` writes exactly the `# Compact State — <ts>` header and `## Branch` section the fix parses. One quirk, not a defect: the fix's primary comparator (trailing date in the `HANDOFF — … | <date>` title line) is this repo's practice — G-RULES §I's canonical block carries no date — so on a template-conformant consumer the primary parse always fails and the stated fallback (last commit touching `g-docs/ROADMAP.md`) always decides. The fallback covers it; recorded here so nobody reads the primary as load-bearing. The hook-side root fix (nothing ever deletes the file) stays with todo 18 (2)'s neighbour — out of slice, F3.

### F2-6 (repo-only facts / hardcoded mainline) — **KEEP, and EXTEND** (→ R-4, R-5)

- `doc-reviewer.md:38` + `g-doc-review:44` — ADR-013 cited inline with attribution, no relative link, generic pin description; both surfaces consistent. Holds.
- `g-adr:227` M9 line deleted; clean. Holds.
- `g-doc-review:28` mainline resolution added — **but the borrowed text dangles its `<remote>`**: 0g resolves `<remote>` in `/g-resume` 0b before ever using it; this skill has no remote-resolution step, so `git symbolic-ref --short refs/remotes/<remote>/HEAD` is uninstantiable as written. Bind it: the current branch's configured remote, else `origin`. → R-4.
- **One in-slice carrier of the class survived:** `agents/test-writer.md:64` "(M-audit finding #20)" — a pointer to a G-Forge-repo audit record no consumer has; the sentence already states the why self-contained, so the parenthetical can drop. (`agents/code-lead.md:32` carries the same literal — out of slice, carried to F3 alongside todo 18's items.) → R-5.

### F2-7 (`doc-writer` README check) — **KEEP**, no extension

`agents/doc-writer.md:20` (check + update-or-report) and `:45` (`README GAP:` return field) verified; matches §G's ownership rule.

## New findings (all Minor; slice components all SURVIVE the rebuild, and R-1 is adopter-facing)

### R-1 — Minor · `/g-resume`'s typed cross-refs into the hooks have drifted, unpinned

Three citations in the shipped skill are wrong on disk today (each verified by `grep -n` against the current hooks):
- `skills/g-resume/SKILL.md:104` — "`hooks/session-start.sh:182` zeroes `session-prompt-count.<session_id>`" → the zeroing `printf` is at **`:183`** (`:182` is the `else`).
- `skills/g-resume/SKILL.md:121` — "`✓ Clean and in sync with remote` (`hooks/session-start.sh:166`)" → the echo is at **`:167`**.
- `skills/g-resume/SKILL.md:108` — "`skills/g-plan/SKILL.md:105` is the owning statement of the ADR-005 local-else-primary rule" → the owning statement now sits at **`:115`**; `:105` is review-chain coefficient prose.

Also verified accurate this cycle, stated per-ref with no completeness claim: `:173` light-tier exit, `:226-227` increment, `:387` nudge block, `:133-137` timeout guard, `:150-151` rev-list fallbacks, `:154` pull line, `:157-161` drift block. The code gate's r1 enumeration surfaced an eighth surviving citation this list had missed — `skills/g-resume/SKILL.md:113` → `session-start.sh:179-184`, the same +1 shift, corrected to `:180-185` in the r1 fix round. The sentence originally here read "the rest of the file's hook refs were verified accurate this cycle" — an unpinned completeness claim minted by a fix round (the §B hard stop) and false on disk; it was the code gate's r1 Major and is corrected in place. No test pins any of them (`tests/test-workflow-checkpoint.sh` pins the nudge *behaviour*, `tests/test-session-start.sh` the counter *behaviour*), and the hooks' cross-reference comments (`session-start.sh:153/:158`) did not prevent the drift. Fail direction: a skill executor or maintainer follows a citation to the wrong line — the exact currency class the doc gate blocks on. **Fix:** correct the three numbers (post-freeze the hooks stop moving, so corrected numbers hold); re-verify the full ref set in the same edit.

### R-2 — Minor · `project-manager.md` residue (extends F2-1 + F2-2, one file)

Four limbs, one dispatch: (a) `:66` ask-and-wait split for dispatched mode (approval request → `QUESTIONS:`); (b) `:93` same route for the Phase-1 clarifying question; (c) a Level-2 preamble stating the phases run in the session's interactive PM role and a dispatched PM — which holds no skill tool — returns the routing/approval need via the Return format instead of emulating `/g-plan`/`/g-review` with its own dispatches, with Phase 2's dispatched-mode sentence corrected to match; (d) frontmatter grant trimmed to `Agent(code-lead, pr-writer)`. Plus the `:66` phrase pinned in `tests/test-review-severity.sh` group (b).

### R-3 — Minor · `g-retro` fix completion (extends F2-4, one file + CHANGELOG)

The F2-4 amendment above: derivation order re-ranked (directive → plan wave → milestone task → todo row → carried), Step 2's read list gains the active milestone file and active plan (conditional reads), the Step 5 template line updated to match, `note` dropped from the `:26` kind set, and the CHANGELOG `[2.5.0]` F2-4 entry rewritten to the amended order.

### R-4 — Minor · `g-doc-review:28` `<mainline>` resolution: bind `<remote>` (extends F2-6)

Resolve the remote first — `git config --get branch.<branch>.remote`, else `origin` — then run the 0g-style candidate chain against it. One sentence.

### R-5 — Minor · `test-writer.md:64` repo-only pointer (extends F2-6)

Drop "(M-audit finding #20)"; the sentence's why is already self-contained. (`code-lead.md:32` twin → F3 carry.)

### R-6 — Minor · `doc-writer` return contract has no failure value

`RESULT: DONE` is the only value (`agents/doc-writer.md:42`); a doc-writer that cannot complete (target file missing, scope mismatch) has no contract path and must break the "only this compact block" rule to say so. Add `DONE|BLOCKED` with `BLOCKED` naming what is missing in `SUMMARY` — the same shape every sibling contract carries.

## Not findings (read or re-examined, left alone)

- `agents/spec-writer.md:53` — F2's adjudication **upheld**: both cited lines re-verified on disk this cycle (`sed -n '6p;19p' profiles/claude-plugin/rules/architecture.md` — the three-tool-class line and the Agent rule), and the parenthetical is explicitly self-host-scoped; consumers read the installed-path clause, which is correct for them. The line-ref fragility is real but freeze-bounded.
- `hooks/workflow-checkpoint.sh:389/:394` false "verify ADR" nudge — reconfirmed at this session's own first prompt; stays todo 18 (2), out of slice.
- F2's remaining "Not findings" list — re-read, all upheld; nothing in this redo contradicts the F2 probes (the PM nested-`Agent` probe result is what R-2(d) acts on).
- `git`'s LF→CRLF warning on `project-manager.md` — checkout normalization, not a defect.
- The observer's test-pattern set misses this repo's `bash tests/*.sh` runs (HQ suite runs unjournaled) — known, recorded in the handoff, out of slice.
- `tests/test-review-severity.sh` new guard groups — mechanics audited: disk-derived enumeration, herestring loop, inverted `no` semantics, quoting on the apostrophe phrase — all sound; probes RED per the f2-r1 attestation. What is owed is the §H falsifiability **markers** (maintenance comments) — scheduled below, written by HQ after the r2 attestation so the new R-2 guard's marker cites a real probe.

## Wave F2-R (one wave, three dispatches, files disjoint; then attestation, markers, gates)

- **Task 35** — `agents/project-manager.md` + `tests/test-review-severity.sh` (R-2 a–d + the new pin) (agent: claude-plugin-implementer).
- **Task 36** — `skills/g-resume/SKILL.md` (R-1), `skills/g-retro/SKILL.md` (R-3), `skills/g-doc-review/SKILL.md` (R-4), `CHANGELOG.md` (R-3 entry rewrite + one `[2.5.0]` line for R-1) (agent: claude-plugin-implementer).
- **Task 37** — `agents/test-writer.md` (R-5), `agents/doc-writer.md` (R-6) (agent: claude-plugin-implementer).
- **Task 38** — attestation: full suite + neuter probes for the Task 35 guard (and re-confirm the four f2-r1 probes still bind) (agent: g-forge-dev, dispatched as soon as Task 35's file lands — the F2 retro's dispatch-early rule).
- **Task 39** — falsifiability markers for all five new/changed guards, written by HQ inline after Task 38's probes, citing the probe outputs by attestation record; then `/g-review` + `/g-doc-review` over the full uncommitted diff (Wave F2 + Wave F2-R), commit, `/g-retro`, handoff.

## HQ self-review of the fix wave (before the gate)

All three dispatches returned `DONE` first attempt, no stalls, no child dispatch; records at `g-docs/agent-output/wave-f2r/task-{35,36,37}*.md`. HQ read every diff before the gate:

- Task 35 — all five edits exact; no pinned absence literal reintroduced; the suite's `Results:` line went 21→22 passed, 0 failed (pasted in the task record).
- Task 36 — the three `g-resume` substitutions verified with zero stale copies of the old literals; the g-retro read-list, `:47` derivation chain, and `:85` template all carry the amended order. **One disclosed hunk beyond the dispatch list, reverted by HQ:** the implementer's own-scope grep found `g-plan/SKILL.md:105` restated inside the `## [2.4.1]` released CHANGELOG section and updated it to `:115` — but released sections are append-only history (the CHANGELOG's own recorded convention, and the citation was true at release time; the same bullet's other hook refs were left stale, making the partial update internally inconsistent). HQ reverted that one substitution (`grep -c` guard: exactly 1 occurrence, back to `:105`).
- Two warts were **HQ's own dispatch-text bugs, fixed inline by HQ**: the Task 36 prompt literally specified the malformed `— :` punctuation in `g-doc-review:28` (rewritten to a parenthesized binding clause), and its "WHY this order" context paragraph was pasted verbatim into shipped `g-retro:47` — repo-only history (the F2-6 class) plus a broken sentence seam — trimmed to a one-clause parenthetical. Lesson, carried: dispatch prompts must separate REPLACEMENT TEXT from RATIONALE explicitly, or the rationale ships.
- Task 37 — both edits exact; `code-lead.md:32` confirmed untouched as instructed.

## Attestation (Task 38)

`g-forge-dev-2026-08-30-f2r-r1.md` (gitignored): runner `Grand total: 733 passed, 0 failed across 24 suites` — the delegate's independent per-suite sum agrees (733), and the +1 over f2-r1's 732 is exactly the new Task 35 assertion (`test-review-severity.sh` 21→22). These are that dated run's figures; the code gate's r1 fix round later added one more assertion — the post-fix run (734/0 across 24 suites, `test-review-severity.sh` 23) is recorded under Gate rounds below. Falsifiability, scratch copy, script-driven, production tree untouched: baseline GREEN `Results: 22 passed, 0 failed` → the phrase `Wait for human approval before writing anything` re-added to the scratch `project-manager.md` → RED `Results: 21 passed, 1 failed`, failing line naming that exact assertion. The f2-r1-proven guards were not re-probed — their assertion text is unchanged since that record. §H markers written into the test file by HQ after this attestation (three group markers, dated 2026-08-30, honest about representative-literal basis); this section is the pass-record entry those markers point at.

## Gate rounds

- **Code gate r1 — HOLD, 1 Major · 6 Minor** (`code-lead-2026-08-30-f2-redo-wave-r1.md`, gitignored; the gate numbered its findings 1–7 — #1 the Major, #2–#7 the six Minors — which are the labels used below). All seven done conditions PASS. The Major: this record's own R-1 section carried "the rest of the file's hook refs were verified accurate" over a seven-item list while disk held an eighth, drifted ref (`g-resume:113` → `session-start.sh:179-184`, actual `:180-185`) — a fix round minting a false, unpinned completeness claim (§B hard stop). Fix round (HQ inline, every hunk disclosed here): the `g-resume:113` ref corrected; this record's sentence rewritten per-ref (above); a `BLOCKED` trigger sentence added to `project-manager.md`'s return block (Minor 3); the compact-state comparator given timestamp granularity + a same-day-supersession rule (Minor 4); `CLAUDE.md:23` re-summed from the runner (Minor 5, fixed before r1 returned); the case-sensitivity gap on the new absence guard closed by a positive pin of the dispatched-mode qualifier text (Minor 6 — a new `ok` assertion, not a case-insensitive grep, which would false-RED on the legitimate lowercase qualified line); this record's mis-transcribed evidence grep corrected to the command actually run (Minor 7).
- **Doc gate r1 — DOCS HOLD, 4 BLOCKING · 6 WARNING** (`doc-reviewer-2026-08-30-f2-redo-wave-r1.md`, gitignored). All four blockers were ripple carriers the wave falsified outside its own file set: `skills/g-forecast/SKILL.md:116/:117` citing `g-retro` at pre-insert lines (→ `:49-59`/`:58`, verified on disk before typing); `g-docs/agents.md:22` still describing the PM as driving `task-decomposer`/`wave-planner`/`spec-writer` after the grant trim; `g-docs/todo.md` R4-2 quoting the deleted "Never touch a file yourself" at a dead `:114`; `CLAUDE.md:23` typing 21 for a suite deriving 22. All fixed by HQ inline, plus the six warnings (CHANGELOG F2-4 chain completed to five steps; the redo bullet gains the `note`-kind clause; the test header attributes the seventh literal to this redo; this record's read-basis stamp and observe.sh citation corrected; `g-docs/agents.md` doc-writer Returns updated for `README GAP:`/`BLOCKED`).
- **r2 (both gates), on the settled tree with fix-closure sweep instructions.** Post-fix attestation (HQ direct run, 2026-08-30, log `run-all-f2redo-fixround.log`): `Grand total: 734 passed, 0 failed across 24 suites`, HQ-summed independently (734 — the only row moved vs the 733 run is `test-review-severity.sh` 22→23, exactly the fix round's added pin). **Code gate r2 — MERGE READY, 0 Critical · 0 Major · 2 Minor** (`code-lead-…-r2.md`): all seven r1 findings verified closed with recorded grep evidence; the two new Minors (this record's attestation figures one round behind their own tree; todo.md R4-2 crediting the redo for Wave F2 Task 29's rule rewrite) are closed by this very edit and the todo.md correction beside it. **Doc gate r2 — DOCS HOLD, 1 BLOCKING · 2 WARNING** (`doc-reviewer-…-r2.md`): all ten r1 findings verified closed with recorded sweep evidence, zero stale literals; the three new items (the Gate rounds numbering key now stated above; this attestation reconciliation; the CHANGELOG F2-5 ignore-set gaining the same-day-supersession clause) are closed in the same edit set. **Doc gate r3** verifies these closures; its outcome is carried in the pass-close handoff and retro rather than another edit to this section.

## Tally

Seven F2 verdicts: **7 KEEP** (four of them extended — F2-1, F2-2, F2-4, F2-6; zero reverts). Six redo findings R-1…R-6, all Minor, summed from the headed sections above.

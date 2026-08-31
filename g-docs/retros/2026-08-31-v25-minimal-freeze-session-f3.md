# Retro — v2.5 minimal freeze, Session F3 (audit cycle 3: SURVIVES skills + open ledger)

**Date:** 2026-08-30 → 2026-08-31 (session crossed midnight) · **Branch:** `chore/v2.5-minimal-freeze` · **Commit:** `81b585b` (50 files)

## What happened

- **Audit:** HQ on the session model read all 16 remaining SURVIVES skills whole-file (§A1 override, developer-decided) and verified every typed cross-reference against disk. 11 new findings (10 Minor + 1 Major — `g-skill-design` guaranteed new skills ship absent from the router's `description:` palette list, which the parity suite deliberately did not pin), 9 skills clean on the new read. All 7 open ledger rows dispositioned: row 5 closed with zero work (everything had already shipped), row 6's population derived per its own instruction (5 reviewers instructed to write records with no Write grant — two on live dispatch paths). Record: `g-docs/audits/2026-08-30-fable-f3-survives-skills-ledger.md` + addendum.
- **Wave:** 7 file-disjoint single-use implementers (T39–T45) with HQ-authored REPLACEMENT TEXT, + T46 (fresh redeploy of T44's skipped H1) + post-gate doc tasks T47/T48/T49. Five delegates capped and were resumed once each (§C routine yield); T44 returned an honest `FAILED` on one skipped item.
- **Attestation:** g-forge-dev, separate dispatch — **752/0 across 24 suites**, HQ-summed from the per-suite table; independent re-probes for commit-detect ROW16 and checkpoint §22b.
- **Gates:** code r1–r6 HOLD → **r7 MERGE READY** (0C/0M/2m advisory); doc wave r1–r3 HOLD → **r4 DOCS READY** (0B/3W); currency re-check (the developer's F3 amendment add) r1–r4 HOLD → **r5 DOCS READY** (0B/6W). The currency add earned its keep: 6 blockers on README/agents.md at r1, including a phantom review pipeline documented as live.
- **Ledger:** rows 5/6/9/14/15/16/18 closed to `todo-done.md` (row 9's text preserved verbatim there — its only committed copy); **row 19 opened** — the commit-gate quote-aware-pad Minor carried from Session B was never dispatched (wave-planning miss, disclosed; hooks surface, fails toward deny).

## Decisions

- **HEREDOC-p pinned leak narrowing blessed** (5 tokens → 1, gate-neutral side effect of the row-16 NL-sentinel; the pin always pinned current unfixed behaviour).
- **R2-3's real closure at code r6:** scoped Write grants extended to `debugger` + `error-detective` (diagnostic-class record-producers); `review-orchestrator` — no file-access tools — corrected to inline return. The write-instruction-without-grant class is extinct on the shipped surface (code r7's verified claim).
- **Doc gate not re-opened for the r5–r7 record edits** — each of those hunks was verified line-by-line by the code gate rounds that demanded them; recorded here as the deciding rationale.
- **Row 19 carried, not implemented** — new gate mechanism at context red was the wrong trade; the developer decides whether it gates the release bar (hooks surface — the stated F3 bar names skills/agents).

## Patterns

### Worked well
- File-disjoint wave tasks with pre-authored replacement text: the T39–T46 implementer dispatches, zero cross-task collisions, one honest FAILED.
- Separate attestation + independent probes (Session C's carried rule) — and HQ summing the runner's table caught nothing amiss this time because the table was honest.
- The developer-mandated README/agents.md currency re-check — the highest-yield dispatch of the session (6 blockers no other gate owned).
- Repo-wide literal greps after site-list fixes — found the seventh carrier twice ("shared Table" in `g-plan`, `main...HEAD` in `orchestration-patterns.md`).

### Avoid / do differently
- **A resume message must never assert a delegate's per-item progress.** T44's H1 skip traces to my resume text claiming H1 "already completed" — the agent trusted it and compiled the final report around it. Resume with "verify your own per-item state", never with an asserted state.
- **Fix rounds minted unpinned counts/enumerations repeatedly — 4th consecutive session of forecast scenario 1.** The §B hard stop has to fire at write time; the gates catch it one round later, every time, at a round's cost each.
- **Never cite line numbers from a concatenated read.** Two `security-auditor` cites in the audit record were `cat -n`-over-two-files artifacts (:153/:165 against the file as it stood at audit time). Per-file greps only.
- **Disposition a finding from its verbatim text, not from memory of it.** R2-3 was "incomplete by three"; I verified its premise (the five names present) and called it complete. Cost: three extra gate rounds.
- **Size dispatches under the cap** (Session C's rule, violated by T44: 2 caps) and remember doc-writer/doc-reviewer budget ≈ 10 calls ≈ 6 edits.
- **Delivery-scope claims come from `/g-update`'s own text** — the consumers line was wrong twice before being derived from the authority.

**Forecast reconciliation (Step 4):**

`g-docs/forecasts/v25-minimal-freeze.md` Outcome rows 1 and 2 appended with F3 evidence this pass: scenario 1 **happened again** (4th consecutive); scenario 2 **happened, mitigated — budget-one-resume held** (5 routine yields resumed; 1 true FAILED redeployed fresh).

## Cold-start context

**Branch:** `chore/v2.5-minimal-freeze` — ahead of `origin/main` by the full unpushed branch history (`81b585b` at its tip) + this pass-close commit; never pushed, no upstream. Tree clean after `81b585b` except this pass-close set (retro · handoff · forecast rows).
**Active milestone:** M52 — v2.5 Minimal Freeze 🔄 (A, B, C, F1, F2+F2-R, **F3 closed**; Session D owed).
**Handoff at retro:** the F2-R handoff Next-up (F3 audit cycle — remaining SURVIVES slice + open ledger + the two approved Session D adds) — executed this session; superseded by the Next up below.
**Next up (derived — no explicit directive this session; source: the M52 entry's "Then Session D as written"):** **Session D — the release.** Preconditions in order: read `g-docs/communication-plan-2.5.md` · run `/g-doctor` and resolve-or-accept every finding before the bump (the F2-R-added release-hygiene precondition) · **developer decision: does todo row 19 (quote-aware pad, hooks surface) gate the release or ride to G-Proof R0?** · Task 20 version bump (plugin.json + marketplace.json) · Task 21 release grep sweep (§D step 5) · merge to `main` `--no-ff` + push · Task 22 tag `v2.5.0` + GitHub release · freeze. Nudges due: `/g-trim` (last 2026-08-18), `/g-align`, M52-close `/g-wiki`.
**Key files touched:** the skills, agents, hooks and libs, test suites, README, `g-docs/agents.md`, CHANGELOG `[2.5.0]`, ROADMAP annotations, todo/todo-done, patterns-deferred, the audit record (all in `81b585b`).
**Carry-over context:** Records (gitignored): wave `agent-output/wave-f3/task-{39..49}*.md`; attestation `g-forge-dev-2026-08-31-f3-r1.md`; gate records `code-lead-2026-08-31-f3-wave-r*`, `doc-reviewer-2026-08-31-f3-wave-r*`, `doc-reviewer-2026-08-31-f3-readme-currency-r*`; frozen diffs `diff-2026-08-31-f3-wave{,-fixround}.patch`. Advisory carries: code r7's two "five reviewers" scope qualifiers (extension sentences sit beside both); currency r5's warnings (agents.md:129 inert-chain qualifier, README RESULT families, "staged file set" shorthand, count twins incl. `g-wiki/usage.md`, agents.md:19/:22 prose). `review-holds` 0 (1 up code r1, 1 down on the r7 MERGE READY). Observer gap persists: suite runs unjournaled.

## Journal basis

`.claude/journal/2026-08-30.jsonl` (session open) + `2026-08-31.jsonl` (agent start/stop pairs for the wave, gate, and attestation dispatches; the `81b585b` commit). Suite runs remain unjournaled (known observer gap, carried).

# F3 audit — remaining SURVIVES skills + open ledger (M52, Fable cycle 3)

> **Date:** 2026-08-30 · **Auditor:** HQ on the session model (§A1 override, developer-decided per the M52 2026-08-30 amendment — no reviewer agents for the read)
> **Slice:** the 16 remaining SURVIVES skills (`g-roadmap`, `g-intake`, `g-align`, `g-brief`, `g-kickoff`, `g-onboard`, `g-forecast`, `g-blast-radius`, `g-patterns`, `g-identity`, `g-wiki`, `g-tier`, `g-train`, `g-skill-design`, `g-skill-validate`, `g-roundtable`) + open ledger todo rows 5, 6, 9, 14, 15, 16, 18 (row 11 outside scope per the M52 entry — M51/G-Proof design input)
> **Filter:** ADR-012 amendment 4 — a finding earns a fix only if the surface SURVIVES the G-Proof rebuild (`audits/2026-07-rebuild-map.md`) or the defect is adopter-facing. All 16 slice skills are SURVIVES (map rows 58, 60, 63, 68 — verified this session).
> **Method:** every slice file read whole-file (`cat -n` / Read, complete line ranges); every typed cross-reference, contract claim, and ledger assertion below verified against disk this session with the command class named per finding. Whole-surface claims in this record rest on those whole-file reads.

---

## Part 1 — Skill findings (new, this audit)

### F3-1 · Minor · g-roadmap — auto-trigger collides with `/g-intake`
`skills/g-roadmap/SKILL.md:3` (description) and `:240` (Rules): "The developer mentions any feature idea, even a single one" auto-triggers g-roadmap. G-RULES §B routes a single dropped idea through `/g-intake` first, and `g-intake/SKILL.md:324` claims exactly that trigger ("the developer mentions a **single** new feature idea mid-stream"), deferring to g-roadmap only for multi-feature dumps. Two skills claim the same trigger; the heavier one wins by its own text, defeating the triage g-intake exists to provide. **Fix:** narrow g-roadmap's third auto-trigger (and its description) to an explicit multi-feature dump / full re-plan; note single ideas arrive via `/g-intake`. Filter: SURVIVES + adopter-facing (workflow routing).

### F3-2 · Minor · g-roadmap — auto-triggers not tier-qualified
`skills/g-roadmap/SKILL.md:237`: the auto-trigger block carries no "full tier only" qualifier. §B gates all auto-triggering on the `full` tier; siblings carry it (`g-intake:324`, `g-align:101`). **Fix:** add the qualifier. Filter: SURVIVES.

### F3-3 · Minor · g-roadmap — "the shared Table" drifted from §B
`skills/g-roadmap/SKILL.md:142` says "(lanes/claims, the shared Table, a new gate)"; the owning rule (`rules/g-rules/B-workflow.md:54`) says "the shared Roundtable". Verified both sides this session. **Fix:** align the token. Filter: SURVIVES.

### F3-4 · Minor · g-align — date-keyed record path has no same-day discriminator
`skills/g-align/SKILL.md:50` mints `g-docs/alignment/YYYY-MM-DD-<milestone-or-slug>.md`. Two same-day runs share the slug (the active milestone, or `adhoc`) → silent overwrite — exactly the §I date-keyed-path rule's gap class ("a writer that mints a bare `YYYY-MM-DD.md` path with no discriminator silently overwrites a same-day run"). **Fix:** first-free numeric suffix on collision (`-2`, `-3`, … — the g-patterns convention). Filter: SURVIVES + adopter-facing (record loss).

### F3-5 · Minor · g-kickoff — "at the project root" contradicts its own path
`skills/g-kickoff/SKILL.md:212`: "write `g-docs/project_brief.md` at the project root" — the path is under `g-docs/`; "at the project root" is a leftover from the brief's old location. **Fix:** delete the phrase. Filter: SURVIVES.

### F3-6 · Minor · g-kickoff — embedded duplicate of the `/g-voice` intake
`skills/g-kickoff/SKILL.md:20-48` embeds a full copy of the 2-question voice intake that `g-voice/SKILL.md` Step 1a owns. Question wording has already drifted between the copies (verified side-by-side this session; the 9-row mapping tables are still identical — nothing pins them together). `g-train/SKILL.md:20` already does this right: "run the language intake (same 2-question interview as `/g-voice` no-arg)". **Fix:** replace the embed with the same by-reference form. Filter: SURVIVES.

### F3-7 · Minor · g-onboard — severity vocabulary matches no shipped agent
`skills/g-onboard/SKILL.md:177` asks a dispatched `code-lead` to "flag BLOCKING / HIGH / MEDIUM / LOW violations". code-lead reports **Critical / Major / Minor** (`agents/code-lead.md:45`, verified); no shipped agent uses BLOCKING/HIGH/MEDIUM/LOW (doc-reviewer: BLOCKING/WARNING; security-auditor: Critical/High/Medium/Low). The dispatch requests a scale the agent will not emit. **Fix:** Critical/Major/Minor. Filter: SURVIVES + adopter-facing (contract mismatch).

### F3-8 · Minor · g-tier — per-tier hook list has no named source
`skills/g-tier/SKILL.md:247` (read-mode status): "Hooks: [list which hooks will fire under the active tier]" — no source named; the list would be recalled, not derived. The tier model's owner is `g-docs/integration-tiers.md` (exists, verified). **Fix:** name it in the template line ("per `g-docs/integration-tiers.md`"). Filter: SURVIVES.

### F3-9 · Minor · g-train — Step 6 never removes `.claude/training-mode`
`skills/g-train/SKILL.md:273` (Rules) mandates "Remove it when the project is complete (Step 6 close)", but Step 6's body (`:238-263`) contains no removal action. A session following Step 6 verbatim leaves training mode latched — and `g-afk/SKILL.md:32` blocks on the file's existence, so `/g-afk` stays blocked forever after a completed training project. **Fix:** add the removal action to Step 6. Filter: SURVIVES + adopter-facing.

### F3-10 · Minor · g-train — typed step count of another file
`skills/g-train/SKILL.md:91`: "runs the full `/g-kickoff` process (all 7 steps)" — an unpinned hand-typed count of a sibling file's structure (ADR-013 rule 2 class). **Fix:** drop the count ("the full `/g-kickoff` process"). Filter: SURVIVES.

### F3-11 · **Major** · g-skill-design — Step 5 misdescribes the router; new skills ship invisible in the palette
`skills/g-skill-design/SKILL.md:472-478`: (a) "Do not add anything to the subcommand description list **at the bottom**" — no such list exists at the bottom of `commands/g-forge.md`; the subcommand list lives in the YAML frontmatter `description:` at `commands/g-forge.md:2` (verified). A phantom-structure instruction. (b) The "two additions only" contract (argument-hint + routing line) never adds the new token to that `description:` list — and `tests/test-router-skill-parity.sh:52-55` **deliberately excludes** the description list from parity ("a separate, drift-prone surface this suite deliberately does not check"). So the one skill-creation path guarantees the new skill is absent from the command palette description, unpinned, forever. **Fix:** correct the location language; make the `description:` token the third addition (bare token — ADR-007 bans prose, not tokens); extend the parity suite to pin description-list tokens ↔ routing-list tokens and update its coverage/assertion comment. Filter: SURVIVES + adopter-facing.

### Clean verdicts (basis: whole-file read + the named verifications)
- **g-intake** — clean. Anchors/manifest reads, backlog write, mid-wave guard, tier-qualified trigger all coherent.
- **g-brief** — clean.
- **g-forecast** — clean. All typed refs verified live: `g-retro:49-59` (Step 4 spans exactly that range), `:58` (verdict + one-word evidence tag line), `mitigation-held:` marker at `g-retro:59`; `/g-plan` Step 3a writes `.pending-forecast.md` (`g-plan:235-239`), Step 3b invokes (`:241-243`); Step 2b table matches `g-blast-radius:383` both directions.
- **g-blast-radius** — clean. Plan `Scope` column (`g-plan:311`) and `Progress`/`pending` table (`g-plan:325-330`) verified.
- **g-patterns** — clean on this audit's read; row 14's Step-14 anchor gap stands (Part 2). Verified: `/g-doctor` Check 22 (`g-doctor:260-272`), Check 24 report-laundering guard (`g-doctor:328`), `g-forecast` Step 5b unfilled-cell symmetry (`:79`↔`g-forecast:116`), source-tree detection dirs exist (`rules/g-rules/`, `profiles/`, `skills/`).
- **g-identity** — clean. Sentinel-filter cross-refs hold both directions.
- **g-wiki** — clean. Close-swarm queue verified (`g-review:241`); `/g-init` surfaces the wiki (`g-init:488` — as a closing tip; the skill's "Offered at `/g-init`" is looser than the tip's register — recorded as an observation, no fix).
- **g-roundtable** — clean. Check-22 citations accurate; checkpoint heartbeat nudge tier-gated as claimed (`workflow-checkpoint.sh:190-196`, after the `:170` light-tier exit); `templates/roundtable/roundtable-template.md` exists.
- **g-skill-validate** — structurally clean and its typed refs (`architecture.md:6`/`:19`) verified **accurate today**; the carried row-15 findings against it (unpinned refs, hardcoded class copy, class-enumeration gaps) stand and are fixed this wave (Part 2, T41).
- Structure conformance, all 16: Announce line present, `## Step N —` numbering, `## Rules` section, no `Skill()` calls, no `argument-hint`, no absolute paths, frontmatter limited to name/description(/context).

---

## Part 2 — Open-ledger dispositions (todo rows, verified on disk this session)

### Row 5 — Audit Wave C test teeth · **CLOSE with evidence, no work remaining**
All four sub-items shipped since the row was minted: (1) `tests/test-pre-commit.sh` exists — 18 tests, in the runner; (2) §13 un-inerted (`test-workflow-checkpoint.sh:405-408`); (3) §12 mode-detection assertions present with dated falsifiability markers (`:357-399`, probes RED 2026-08-22); (4) the falsifiability convention shipped as the §H rule (`rules/g-rules/H-testing.md`), markers now present in 15 test files (`grep -l "falsifiability:" tests/*.sh` this session). Close to todo-done citing this record.

### Row 6 — reviewer record-write contract · **population derived; fixed this wave (A-1)**
Derived per the row's own instruction (body report-write instruction vs `tools:` line, all `agents/*.md` read): **five** agents instruct "Write the full review/audit to the `output_file` path" while holding no Write grant — `architecture-enforcer.md:42`, `code-reviewer.md:66`, `security-auditor.md:70`, `performance-auditor.md:63`, `dependency-auditor.md:102`. Two of the write instructions sit on **live shipped dispatch paths**: `g-review:139` mints an `output_file` for dependency-auditor; `g-refactor:66` dispatches code-reviewer + architecture-enforcer. Fix per the 2026-08-20 directive (scoped Write grants, the doc-reviewer/task-decomposer pattern): add `Write` to `tools:` + a body sentence scoping it to the agent's own record path. `spec-writer`/`wave-planner` stay on the returns-content mechanism (M52 Tasks 7/8) — that seam hands content to HQ for an approval gate, a different contract from a reviewer persisting its own record; T41/T42 state the distinction where F9 flags the divergence.

### Row 9 — attested-total confabulation record · **close to todo-done at pass end**
No code action. The row's own settlement note holds: closing appends it to committed `todo-done.md`, preserving the only durable copy. Feeds the next `/g-patterns` MINE.

### Row 14 — g-patterns Step 14 anchor gap · **fix this wave (T43)**
Verified still open: `g-patterns:313` enumerates file-absent / heading-absent / machine-generated but not present-but-empty `## [Unreleased]`; `:328`'s Rules line is ambiguous on whether `### Changed` may be created. Fix: add the empty-[Unreleased] arm (create `### Changed` under the existing heading; never create the heading itself); clarify `:328`; CHANGELOG entry.

### Row 15 — carried code-gate Minors (F1–F9 minus F6, R3-2, R2-2/3/4, R4-1/2/4, C-1…C-9) · **execute in full this wave**
Distributed to tasks T40–T45 + HQ inline (map in Part 3). Informational items closed with a recorded no-action disposition: F7 (GNU-sed `\|` second carrier — consistent with the existing `check-commit.sh:83` convention, informational per the row) and C-9 (superseded verdict row inside a gitignored record — the two HQ addenda beneath it are the record's correction; records are not rewritten).

### Row 16 — commit-detect trailing-command false deny · **fix this wave (T44)**
Verified constraint set unchanged: whole-string newline flatten deliberate (`commit-detect.sh:474-483`) and pinned green (`test-commit-detect.sh:84,:89,:92`); the `;` segment form handled, newline not a segment separator (`:26-28`, `:247-268`). Fix designed at task time under that constraint, pinned by a new case. Fails-closed today (false deny); adopter-facing hook bug → passes the filter.

### Row 18 — F2 carries · **all five items resolved this wave**
1. `review-orchestrator.md:11` "subagents cannot spawn other subagents" — **false on the current platform** (probe 2026-08-30: a dispatched project-manager held a working Agent tool). No other live carriers: README/§C/agents.md greps for the claim class returned zero hits; `README.md:396` already truthful ("Shipped but not currently dispatched"); the GF-21 [VERIFY] lives in a received-input record whose banner (`2026-07-modernization-report.md:2`) already records the falsification — received-input records are never rewritten. Fix: rewrite `:11` to the probed truth (A-2).
2. `workflow-checkpoint.sh:389-394` — confirmed: presence-only `compact-state.md` test + whole-file `grep -qi 'verify ADR'` over `g-docs/ROADMAP.md` + compact-state fires "a handed-off ADR needs verifying first" on every fresh session here (`ROADMAP.md` body prose carries the phrase; the local compact-state is a 2026-08-16 snapshot from `main`). Fix + test pin (A-5).
3. `main...HEAD` hardcodes confirmed at all six sites: `g-review:85,:108,:208`, `code-lead.md:38`, `pr-writer.md:13`, `g-docs/agents.md:200`. Fix with the F2-6/R-4 pattern — resolve the mainline (configured remote → `symbolic-ref` candidate chain → `main`/`master`) instead of hardcoding (A-4).
4. `feature-implementer.md` and `pr-writer.md` carry no headed `## Return format` block (grep zero hits). feature-implementer's contract exists inline (`:142`) — give it the heading + structured block; pr-writer returns its PR body inline and writes nothing — a minimal Return format stating exactly that (A-3, F2-2 pattern per `spec-writer.md`).
5. `code-reviewer`, `security-auditor`, `dependency-auditor` audited whole-file this session: F2-3 memory rule present in all three (`:78`, `:82`, `:115`); severity scales conform to the shipped contract (security-auditor's native Critical/High/Medium/Low is the deliberate carve-out); the one defect found is the A-1 write-instruction class, fixed this wave.

---

## Part 3 — Wave plan (single wave, file-disjoint tasks, HQ-authored replacement text)

Carried process rules apply: REPLACEMENT TEXT separated from RATIONALE in every dispatch; whole-file read per edit; disclose every hunk; per-ref facts in fix rounds; attestation dispatched the moment test files land; scratch probes from a script file. §C note: 7 single-use implementers exceeds the 4-per-wave warning threshold — accepted deliberately over splitting the cycle's one wave; every task is file-disjoint and single-attempt with pre-authored text.

| Task | Files | Findings |
|---|---|---|
| T39 skills batch 1 | g-roadmap, g-align, g-kickoff, g-onboard, g-tier, g-train SKILL.md | F3-1…F3-10 |
| T40 router/design | g-skill-design SKILL.md, tests/test-router-skill-parity.sh | F3-11 (+ parity pin) |
| T41 class taxonomy | g-skill-validate SKILL.md, profiles/claude-plugin/agents/claude-plugin-architect.md, profiles/claude-plugin/rules/architecture.md, agents/spec-writer.md, agents/wave-planner.md | row-15 F2, F9, R3-2, R2-2 (spec-writer site), R2-4, R4-1, R4-2, R4-4 |
| T42 agents | architecture-enforcer, code-reviewer, security-auditor, performance-auditor, dependency-auditor, review-orchestrator, feature-implementer, pr-writer, code-lead (.md) + g-docs/agents.md | A-1 (row 6), A-2, A-3, A-4 agent sites + agents.md:200 |
| T43 skills batch 2 | g-review, g-refactor, g-doctor, g-update, g-patterns SKILL.md | A-4 skill sites, row-15 F1 + R2-2 (g-refactor sites), F8 (g-doctor:190, g-update:251), row 14 |
| T44 hooks + tests | workflow-checkpoint.sh, check-commit.sh, lib/classify-changeset.sh, lib/commit-detect.sh + their test suites | A-5 (row 18-2), row 16, C-1, C-2, C-3, C-4, C-6 |
| T45 test consistency | test-readme-counts.sh, test-observe.sh, test-agent-lifecycle.sh | row-15 F3, F4, F5 |
| HQ inline | ROADMAP:406 (C-5), CHANGELOG:17 (C-7), todo row-16 citation (C-8), patterns-deferred:3 (R2-3), CHANGELOG entries, `.claude/` mirror realign, row closures 5/6/9 | — |

Gate: attestation (g-forge-dev full suite) → `/g-review` + `/g-doc-review` (doc gate includes the amendment's README + `g-docs/agents.md` currency re-check against everything shipped since Session A) → commit → `/g-retro` → handoff.

---

## Addendum — 2026-08-31 (execution + gate rounds)

Part 3 above is the wave PLAN as authored 2026-08-30; execution diverged from it in three recorded ways:

1. **T44 returned `FAILED` (honest):** items H2–H7 landed green, H1 was never implemented — the HQ resume message mid-task wrongly asserted H1 complete and the agent trusted it. H1 was re-dispatched as fresh **Task 46** (files `hooks/workflow-checkpoint.sh` + `tests/test-workflow-checkpoint.sh`), which closed it (§22b, suite 94/0). The dispatch series ran T39–T49 (records in `wave-f3/`), not the seven tasks Part 3 planned.
2. **Post-gate doc fix tasks were added:** T47 (README currency blockers B4/B5/B6), T48 (`g-docs/agents.md` currency), T49 (code r1 Major #4 marker truth + Minors #6/#7/#8 + the test-header count).
3. **Cite corrections in this record:** the two `agents/security-auditor.md` line cites in Part 2 (rows 6 and 18.5) originally read `:153`/`:165` — concatenated-read offsets from a two-file `cat -n`; corrected in place to the pre-wave truth `:70`/`:82` (verified against `git show HEAD:agents/security-auditor.md`).

Gate ladder to this point: attestation 752/0 across 24 suites (HQ-summed, `g-forge-dev-2026-08-31-f3-r1.md`) · code r1 HOLD 0C/5M/6m (`code-lead-2026-08-31-f3-wave-r1.md`) · doc wave r1 DOCS HOLD 2B/5W · doc currency r1 DOCS HOLD 6B/3W.

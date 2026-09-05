> **Promoted to the committed record on 2026-09-05.** Originally written to
> `g-docs/agent-output/wave-4/task-6c-doc-review.md`, which is gitignored and
> did not survive the working copy. This is the `/g-doc-review` verdict that
> put M54 (Wiki & README Currency) into DOCS HOLD on 2026-09-02 — 16 blocking
> and 7 warning findings — and it is the basis for M54's outstanding fix
> round. M54's work is on `origin/m54-wiki-readme-currency`, with two
> stash-orphaned files on `origin/m54-untracked-rescue`. Body below is
> verbatim as written; only this header was added. Promoted under G-RULES §I.
>
> **Read as of its own date.** M53.1/v2.6.2 has since landed on `main` and
> changed some of the surfaces this verdict discusses. Re-gate rather than
> working the list blind.

# Documentation Review — M54 Wiki & README Currency Pass

**Agent:** doc-reviewer · **Date:** 2026-09-02 · **Tree:** working tree at `c24d594` + M54 changeset (README restored to 388 lines after the `test-lib-install-completeness.sh` regression fix)
**Scope reviewed:** `g-wiki/architecture.md`, `g-wiki/commit-gate.md`, `g-wiki/usage.md`, `g-wiki/reference.md`, `g-wiki/README.md`, `README.md` — every structural claim checked against the source path it names or should name.

## VERDICT: DOCS HOLD

16 blocking · 7 warning.

The reference-layer, agent-taxonomy, hook-registration and review-pipeline claims in `g-wiki/architecture.md` and `g-wiki/usage.md` describe a system that does not exist in this tree. Several are contradicted by files in this same changeset. `README.md`'s front-door narrative still says 2.5 is the last release.

---

## Section 0 — Independent count re-derivation

Re-derived from disk with `Glob` in this dispatch (not taken from the dispatch prompt's list):

| Figure | Derivation | Result | HQ's figure | Agree? |
|---|---|---|---|---|
| Skills | `skills/*/SKILL.md` | 38 | 38 | ✓ |
| Agents | `agents/*.md` | 19 | 19 | ✓ |
| Skill scripts | `skills/*/scripts/*.sh` | 26 | 26 | ✓ |
| Skill reference files | `skills/*/references/*.md` | 63 | 63 | ✓ |
| Rule reference files | `rules/references/*.md` | 9 | 9 | ✓ |
| **Agent reference files** | `agents/references/*.md` | **15** | *(absent from the list)* | **✗ — see B1** |
| Reference files, all homes | `**/references/*.md` (no non-`.md` present) | **87** | 72 | **✗ — see B1** |
| Doctor checks | `grep -c '^\*\*[0-9]\+\.' skills/g-doctor/SKILL.md` = 25; with `(advisory` = 9 | 25 = 16 + 9 | 25 = 16 + 9 | ✓ |
| ADRs | `g-docs/decisions/*.md` | 16 (001–016, no gaps) | 16 | ✓ |
| Profile dirs | `profiles/*/rules/architecture.md` | 56 total; 7 combo + 1 supplementary ⇒ 48 stack | 56 (48+7+1) | ✓ |
| G-RULES cores | `rules/g-rules/*.md` | 10 files, A–J | ~7.1k words | file count ✓; **word count not verifiable — I hold no Bash grant** |

**One disagreement with the ground-truth list, and it is load-bearing:** the list omits `agents/references/` (15 files). The lazy-reference layer has three homes on disk, not two. See B1.

**Unverifiable by me (declared, not assumed):** every word-count figure (`~37.5k`, `~7.1k`, `84k → 48k`) requires `wc -w`. I verified those against the records that state them instead, which is where B6 and B16 come from.

## Section 1 — Re-verification of HQ's four inline corrections (known-open item 2)

| # | Correction claimed | Landed? | Surviving sibling? |
|---|---|---|---|
| 1 | reference-file count → "63 + 9 = 72", "113 total" removed | Number changed at `architecture.md:36` | **NO — the correction went the wrong way.** It deleted the `agents/references/` home (`architecture.md:34`) instead of counting it. `CHANGELOG.md:30` and `M53-v2.6-token-diet.md:13` both still say three homes / 113 files. Disk says three homes / 87 files. Three different numbers now stand in three documents. **B1.** |
| 2 | "24 diagnostic checks" → 25 (16 + 9) | ✓ `architecture.md:42` correct | ✓ No stale `24` survives: `usage.md:356`, `usage.md:374`, `README.md:290`, `skills/g-doctor/SKILL.md:3` all read 25. Sweep: grep `24 (checks|diagnostic|point)` → no hits in changed files. |
| 3 | G-RULES word range corrected | `architecture.md:86` now cites `~7.1k` with a dated derivation | Consistent with `M53:22` ("8,884 → 7,088"). No conflicting range found elsewhere. |
| 4 | `gf_validate_sentinel` given two different line ranges | ✓ Resolved — `commit-gate.md:29` now names the function with no range; `:52` carries the single range `79–98`, which matches `hooks/pre-commit:79-98` | **Sibling survives, same defect class:** `round-consolidation.md` is cited as `lines 14–32` at `commit-gate.md:110` and `lines 14–28` at `commit-gate.md:123` for the same procedure. **W1.** |

**Two of four corrections carry an uncorrected twin.** Partial enumeration is live in this changeset.

## Section 2 — Pinned-sentence check (known-open item 4)

`tests/test-readme-counts.sh` matches by literal shape, not line number. All three survive the restore:

| Test | Regex anchor | Now at | Intact? | Section still coherent? |
|---|---|---|---|---|
| 1 | `^All \*\*N\*\* G-Forge agents, \*\*N\*\* skills, N stack profiles, N combo profiles, and N supplementary profile \(frontend-data-flow\)…$` | `README.md:162` | ✓ byte-shape match, values 19/38/48/7/1 all agree with disk | ✓ under `### Install the plugin → Via CLI` |
| 2 | `^/g-forge doctor →   verify hooks, settings, rules block, and drift — N checks \(N required \+ N advisory\)$` | `README.md:290` (was :268) | ✓ values 25/16/9 agree with `skills/g-doctor/SKILL.md` | ✓ still inside the `## Workflow` fenced block |
| 3 | `^\*\*N\*\* agents ship with every install\. Full reference: \[g-docs/agents\.md\]\(g-docs/agents\.md\)$` | `README.md:312` (was :290) | ✓ value 19 agrees with disk | ✓ under `## Agents` |

No orphaning. Note the drift the dispatch predicted did happen — two of three moved between my first read and my last (`:268 → :290`, `:290 → :312`) because of the `<details>` restore alone. This is evidence for W1, not a finding of its own.

## Section 3 — The restored `<details>` block (coordinator's item 1)

`README.md:223-243`. Verified independently, not taken on trust.

- Seven hook paths named: `session-start.sh`, `workflow-checkpoint.sh`, `check-commit.sh`, `post-commit-cleanup.sh`, `observe.sh`, `agent-lifecycle.sh`, `pre-compact.sh` — `Glob hooks/**/*` returns exactly these seven `.sh` at top level. ✓
- Six lib paths named: `commit-detect.sh`, `worktree-resolve.sh`, `classify-changeset.sh`, `sentinel-read.sh`, `stdin-read.sh`, `semver-compare.sh` — `hooks/lib/` contains exactly these six. ✓
- Every parenthetical event annotation matches the registration JSON in `skills/g-init/SKILL.md:158-229`: `observe.sh` on PostToolUse **and** SessionStart ✓; `agent-lifecycle.sh` on SubagentStart/Stop ✓.
- Install target `.claude/hooks/` + `.claude/hooks/lib/` matches `skills/g-init/scripts/install-hooks.sh:56-82`. ✓
- Closing sentence, both halves: "the plugin manifest registers none" — `hooks/hooks.json:3` is `"hooks": {}` ✓. "installed into the repository's git hooks path with a clobber guard" — `install-hooks.sh:111-114` recognises a prior G-Forge install by the `G-Forge commit gate` header literal and emits `PRECOMMIT: foreign` (installing nothing, lib/ included) otherwise ✓.

**The restored block is accurate. No finding against it.**

## Section 4 — Partial-enumeration check on the restored block (coordinator's item 2)

Cross-checked every other hook/lib enumeration and count in the changeset:

| Location | Claim | Agrees with the restored block? |
|---|---|---|
| `README.md:112-119` | 7 scripts, per-event | ✓ same seven, same events |
| `README.md:218` | "seven event hooks, six shared lib scripts" | ✓ |
| `README.md:300` | "seven event hooks plus six shared lib scripts" | ✓ |
| `README.md:253` | hooks in `.claude/hooks/`, registered in `.claude/settings.json` | ✓ |
| **`g-wiki/architecture.md:56-61`** | 5 bullets, 6 scripts, `agent-lifecycle.sh` under **PostToolUse**, `post-commit-cleanup.sh` absent, event list omits SubagentStart/Stop | **✗ — direct contradiction with `README.md:232` and `README.md:118`, inside one changeset. B3.** |

The README side is clean and self-consistent. The wiki side is the twin that says something else.

---

# Findings

## BLOCKING

### `g-wiki/architecture.md:34` and `:36` — [BLOCKING]
**Lens:** Accuracy / Currency
**Issue:** Line 34 states, as an architectural fact with a rationale attached: *"**No agent references** — the 19 agents' full text remains in-tool (they are infrequently dispatched and rarely re-prompted; context poisoning risk is per-agent, not per-session)."* `agents/references/` exists and holds 15 files: `architecture-violations.md`, `code-reviewer-solid.md`, `test-writer-contract.md`, `doc-reviewer-lenses.md`, `shared-contract.md`, `code-lead-attestation.md`, `dependency-auditor-example.md`, `performance-checks.md`, `security-checks.md`, `fix-closure-sweep.md`, `task-granularity.md`, `doc-reviewer-volatile-state.md`, `wave-routing.md`, `axes-inert.md`, `pm-interface.md`. They are live, not vestigial: `agents/doc-reviewer.md:13,25,39`, `agents/code-lead.md:22,59,81`, `agents/code-reviewer.md:13,27`, `agents/dependency-auditor.md:15,24,33`, `agents/security-auditor.md:20`, `agents/architecture-enforcer.md:19`, `agents/performance-auditor.md:19`, `agents/test-writer.md:58`, `agents/wave-planner.md:35`, `agents/project-manager.md:23`, `agents/review-orchestrator.md:10,62` all cite them by relative path. Line 36's "63 skill reference files + 9 rule reference files — 72 total" excludes them; disk total across the three homes is **87**.
**Checked against:** `Glob agents/references/*.md` (15); `Glob **/references/*.md` (87, no non-`.md` members); `CHANGELOG.md:30` — *"`skills/*/references/`, `rules/references/`, `agents/references/` — 113 files"*; `g-docs/milestones/M53-v2.6-token-diet.md:13` — same three homes.
**Why it matters:** This is the flagship v2.6 mechanism and the page's own headline section. A maintainer reading it will not look for agent references, will not know `agents/references/shared-contract.md` governs the reviewer-class Write carve-out, and — following the stated rationale — may argue against creating a layer that already ships. Note the direction of the earlier in-pass correction: it removed a true home rather than fixing a wrong count, and left the number it replaced (`113`) standing in two other records. Three documents now assert 72, 87 and 113.
**Recommendation:** Dispatch `doc-writer` to restore the third home and reconcile the count once, across `architecture.md:34,36`, `CHANGELOG.md:30` and `M53:13`, deriving from disk. Per ADR-013, if the number is worth stating, pin it with a test that fails when the count and `**/references/*.md` disagree; otherwise state the three homes and omit the total.

### `g-wiki/architecture.md:16-18` — [BLOCKING]
**Lens:** Accuracy
**Issue:** All three tool-grant claims are false, and the partition is incomplete.
- `:16` "**Judgment reviewers** (code-lead, doc-reviewer, security-auditor, code-reviewer, architecture-enforcer) — **Read/Glob/Grep only**". Frontmatter: `agents/code-lead.md:5` = `Read, Glob, Grep, Bash, Write`; `agents/doc-reviewer.md:5`, `agents/security-auditor.md:5`, `agents/code-reviewer.md:5`, `agents/architecture-enforcer.md:5` = `Read, Glob, Grep, Write`. Five of five hold Write; one also holds Bash.
- `:17` "**Diagnostics** (debugger, error-detective, dependency-auditor, performance-auditor) — **Add Bash**". `agents/dependency-auditor.md:5` and `agents/performance-auditor.md:5` are `Read, Glob, Grep, Write` — no Bash. Two of four wrong.
- `:18` "**Implementers** (… pr-writer) — **Add Write/Edit**". `agents/pr-writer.md:5` = `Read, Bash` — neither Write nor Edit.
- `:15` says "The 19 agents … split into classes" and then names 14 of them; `project-manager`, `review-orchestrator`, `task-decomposer`, `wave-planner`, `spec-writer` appear in no class.
**Checked against:** frontmatter of all 19 `agents/*.md`; `profiles/claude-plugin/rules/architecture.md:6,19` (the canonical taxonomy: reviewer = Read/Glob/Grep, **diagnostic = +Bash e.g. code-lead**, writer = +Write/Edit, *"a reviewer may hold a Write grant only when its body scopes it to its own record files"*).
**Why it matters:** This is a regression of a defect already found and fixed in this repo — `g-docs/milestones/M-audit-2026-07.md:92` finding #18: *"Architecture rule stale: 'agents are reviewers only, Read/Glob/Grep' predates diagnostic (code-lead/debugger/error-detective +Bash) and implementer (+Write/Edit/Bash) classes."* Re-minting it in the public wiki reintroduces the exact misconception the M-audit removed, and misstates the security-relevant fact that reviewers hold a *scoped* Write.
**Recommendation:** Dispatch `doc-writer` to rewrite `:15-18` from `profiles/claude-plugin/rules/architecture.md:6,19` and the frontmatter, covering all 19 agents or dropping the "split into classes" framing.

### `g-wiki/architecture.md:56` and `:60` — [BLOCKING]
**Lens:** Currency
**Issue:** `:56` enumerates the plugin-hook events as "`PreToolUse`, `SessionStart`, `PostToolUse`, `PreCompact`, `UserPromptSubmit`" — omitting `SubagentStart` and `SubagentStop`. `:60` then files "**`observe.sh`** + **`agent-lifecycle.sh`** (PostToolUse)". `agent-lifecycle.sh` is registered on SubagentStart and SubagentStop, never PostToolUse; `post-commit-cleanup.sh` — the other real PostToolUse hook — is missing from the list entirely.
**Checked against:** `skills/g-init/SKILL.md:181-196` (PostToolUse = `post-commit-cleanup.sh` + `observe.sh`), `:198-217` (SubagentStart/SubagentStop = `agent-lifecycle.sh`); `skills/g-doctor/SKILL.md:29` (Check 14 requires SubagentStart + SubagentStop entries); `skills/g-doctor/scripts/checks.sh:230`; `hooks/agent-lifecycle.sh:3` (*"Wired to SubagentStart and SubagentStop hooks"*); `skills/g-update/SKILL.md:96`.
**Why it matters:** Two files in this one changeset now disagree: `README.md:118` and the restored `README.md:232` both say SubagentStart/Stop. A reader who trusts the architecture page and hand-writes a `settings.json` registration gets no agent journalling and fails `/g-doctor` Check 14 with no idea why. This is the partial-enumeration risk the coordinator flagged, and it is already present.
**Recommendation:** Dispatch `doc-writer` to regenerate `:56-61` from `skills/g-init/SKILL.md:158-240`, so the wiki and the restored README block derive from the same source.

### `g-wiki/architecture.md:54, :63, :71, :97` — [BLOCKING]
**Lens:** Currency
**Issue:** Four ADR links target filenames that do not exist:

| Line | Link target in the doc | Actual file |
|---|---|---|
| `:54`, `:93` | `../g-docs/decisions/003-why-two-gate-sites.md` | `003-cowork-not-a-host.md` |
| `:63` | `../g-docs/decisions/004-two-truths-of-the-gate.md` | `004-bind-sentinel-to-reviewed-tree.md` |
| `:71` | `../g-docs/decisions/005-per-worktree-approval-keying.md` | `005-worktree-enforcement-semantics.md` |
| `:97` | `../g-docs/decisions/008-self-host-split.md` | `008-self-host-working-tree-split-cadence.md` |

**Checked against:** `Glob g-docs/decisions/*.md` — the four invented names return nothing; the four real names are present.
**Why it matters:** Five dead links on the page whose stated purpose is "reachable from the front door", in a milestone whose DoD is that every structural claim cites a source path. `g-wiki/commit-gate.md:133-134` links ADR-004 and ADR-005 by their **correct** filenames — so this is again one instance fixed and its twin left wrong, in the same changeset.
**Recommendation:** Dispatch `doc-writer` to rewrite all ADR links in `architecture.md` from a `Glob` of `g-docs/decisions/`, not from remembered titles.

### `g-wiki/architecture.md:48` — [BLOCKING]
**Lens:** Accuracy
**Issue:** "[ADR-016] pins 19 agents across **five role lanes**." The canonical matrix has **six** distinct Role values: `orchestrator`, `planner`, `judgment-reviewer`, `diagnostic`, `spec-executor`, `mechanical-worker`.
**Checked against:** `rules/dispatch-matrix.md:13-32` (Role column); `:56` and `g-docs/decisions/016-model-economy-dispatch-matrix.md:14`, which name four lanes for the escalation-bounds rule. No reading of either source yields five. The likely origin is `ADR-016:10`'s "all **five** gate/reviewer agents" — a different quantity.
**Why it matters:** The dispatch matrix is the single seam the future fleet port maps onto (`rules/dispatch-matrix.md:69-71`); a wrong lane count in the architecture page is the number someone will build the mapping against.
**Recommendation:** `doc-writer` — derive the lane count from the Role column, or state the lanes by name and omit the count (ADR-013).

### `g-wiki/architecture.md:112` (first clause) — [BLOCKING]
**Lens:** Accuracy
**Issue:** "38 SKILL.md cores dropped **−43% (median)**, from 84k → 48k words ([M53 measured])." The cited source states an **aggregate**, not a median: `M53:21` — "SKILL.md cores (38): 84,205 → 47,925 (−43%; specced heavy skills −60…−84%)". 47,925 / 84,205 = −43.1%, i.e. the −43% *is* the total-to-total ratio. No median is computed anywhere in `M53` or `CHANGELOG.md:23`.
**Checked against:** `g-docs/milestones/M53-v2.6-token-diet.md:21`; `CHANGELOG.md:23`.
**Why it matters:** A one-word mislabel that changes what the reader thinks was measured, attributed to a named source that says otherwise — the exact "false-claim minting in fix prose" the M54 premortem (`ROADMAP.md:627`) names as the high-risk failure mode for this milestone.
**Recommendation:** `doc-writer` — drop "(median)" or replace with the source's own framing.

### `g-wiki/architecture.md:112` (final clause) — [BLOCKING]
**Lens:** Accuracy
**Issue:** "The 27× token multiplier vs. ungoverned process is accepted as the price of quality; **v2.6 pays half that price.**" The record explicitly forbids this inference. `ADR-014:32`: *"The 27× figure is a felt estimate, not instrumented; token accounting lands as roadmap backlog, so v2.6's measured claim is **payload word counts, not a live multiplier**."* The −43% word-count reduction is not a multiplier measurement, and "half" is derived from it.
**Checked against:** `g-docs/decisions/014-v26-token-diet-reopens-after-freeze.md:32`; `M53:33` (token accounting is open backlog).
**Why it matters:** This is precisely the class of claim `README.md:15` congratulates the project for not making ("no lift figure is claimed anywhere in this README"). Minting an uninstrumented performance number in the wiki undoes that discipline at the page an adopter reads for the technical story.
**Recommendation:** `doc-writer` — state the measured word-count reduction and stop there, mirroring `ADR-014:32`'s own wording.

### `g-wiki/usage.md:332-341` (and the sample at `:152`) — [BLOCKING]
**Lens:** Accuracy / Currency
**Issue:** The "Adaptive Review Intensity" section describes an automatic reviewer fan-out that is documented in source as **not wired**, and misstates three of its four rungs.
- `skills/g-review/SKILL.md:15` — *"**Step 0 note:** neither the reviewer-adjustment nor the pre-review column is wired as shipped — `code-lead` reviews the diff **solo** (no `Agent(` grant), and no shipped agent emits an `AXES:` line; the ladder is what HQ applies by hand."* `usage.md:341` says the opposite: *"You don't configure this yourself… the system tightens the review gate before the next wave."*
- `:336` "**Stable** (default): Standard review set (code-lead + **2 specialists**)". `SKILL.md:13` lists a conditional set (code-reviewer always; security-auditor *when auth/external IO touched*; architecture-enforcer *when layer-boundary changes*; performance-auditor *when hot-path changes*). "2" appears nowhere.
- `:338` "**Defensive**: … pre-review by **error-detective**". `SKILL.md:13` for defensive is "**debugger** pre-review". Wrong agent.
- `:339` "**Recovery**: … pre-review diagnostic agents **on every dispatch**". `SKILL.md:13` scopes it to the review, not to dispatches; `skills/g-execute/SKILL.md:15` applies profile bumps per-lane, not "diagnostic pre-review on every dispatch".
- `:149-155` presents the canonical success block including `Reviewers: code-reviewer ✓ · architect ✓`. `SKILL.md:80-87` (Step 6) presents code-lead's verdict verbatim; no shipped path emits a reviewer roster line.
**Checked against:** `skills/g-review/SKILL.md:13,15,42-52,80-87`; `skills/g-review/references/panel-history.md`; `skills/g-execute/SKILL.md:15`.
**Why it matters:** The load-bearing caveat — that the panel is manual, not automatic — is exactly what a user needs to know, and it is the one thing the page drops. A reader concludes G-Forge is auto-escalating review depth on their project when it is not.
**Recommendation:** Dispatch `doc-writer` to rewrite the section from `SKILL.md:13` **including its `:15` note**, correct `debugger`, drop the invented "2 specialists", and remove the `Reviewers:` line from the sample block.

### `g-wiki/usage.md:179-194` (citation at `:181`) — [BLOCKING]
**Lens:** Accuracy
**Issue:** *"The `error-detective` agent (mentioned in `skills/g-execute/SKILL.md` Step 0)…"* — `error-detective` appears **nowhere** in `skills/g-execute/SKILL.md` (grep: no matches). Step 0 of that file is "Read telemetry profile (adaptive orchestration)". The real dispatch lives in `skills/g-execute/references/result-handling.md:22`, and its trigger is an agent returning **`BLOCKED`**, not a user pasting a stack trace. The other shipped error-detective→debugger chain is `skills/g-review/SKILL.md:30`, on a red test run.
**Checked against:** `Grep "error-detective" skills/g-execute/SKILL.md` → no matches; `skills/g-execute/references/result-handling.md:22`; `skills/g-review/SKILL.md:30`.
**Why it matters:** The whole "Debugging a Bug" walkthrough rests on a trigger the code does not have. A user pastes a stack trace, nothing auto-dispatches, and the page told them it would.
**Recommendation:** `doc-writer` — re-derive the walkthrough from `references/result-handling.md:22` and `g-review/SKILL.md:30`, and cite those paths.

### `g-wiki/usage.md:13` — [BLOCKING]
**Lens:** Accuracy
**Issue:** *"the first thing you'll see is the workflow checkpoint (from `skills/g-status/SKILL.md`)"*, followed by the `[G-Forge Workflow Checkpoint]` block. That block is emitted by `hooks/workflow-checkpoint.sh` on `UserPromptSubmit` — `:172-174` (`[G-Forge Workflow Checkpoint]`, `  Branch:`, `  Tier:`), `:281-302` (`  Health:`, `  Tier:`), `:319-334` (`  Active:`, `  Review:`). `skills/g-status/SKILL.md:23-32` emits a different, `━━━`-ruled "G-Forge Status" block.
**Checked against:** `hooks/workflow-checkpoint.sh:172-174,281-302,319-334`; `skills/g-status/SKILL.md:19-32`.
**Why it matters:** The page attributes the automatic session banner to a skill the user has to type. It also undercuts its own later section — `usage.md:263-274` correctly attributes the *other* block to `g-status` and matches Step 2 exactly, so the two citations for the same skill disagree.
**Recommendation:** `doc-writer` — re-attribute to `hooks/workflow-checkpoint.sh`.

### `g-wiki/usage.md:77` — [BLOCKING]
**Lens:** Accuracy
**Issue:** *"The workflow checkpoint hook (from `skills/g-plan/SKILL.md` Step 0a) reads your message. If it's non-trivial (involves ≥3 files, introduces a new surface, or has unclear scope), Claude auto-triggers `/g-plan`."* `skills/g-plan/SKILL.md:11-15` Step 0a is "Identify the task" and contains no trigger criteria and no reference to the hook. The ≥3-files rule lives in `g-docs/integration-tiers.md:16` and `g-docs/orchestration-patterns.md:24,77`.
**Checked against:** `skills/g-plan/SKILL.md:11-15`; `g-docs/integration-tiers.md:16`; `g-docs/orchestration-patterns.md:24,77`.
**Why it matters:** Same class as `:13` and `:181` — a citation that sends the reader to a file that does not contain the fact. Three such in one page is a systematic sourcing problem, not a typo.
**Recommendation:** `doc-writer` — cite `g-docs/integration-tiers.md:16` (which `usage.md:286` already links) and `hooks/workflow-checkpoint.sh`.

### `README.md:17` — [BLOCKING]
**Lens:** Currency
**Issue:** *"**[Architectural decision records](g-docs/decisions/)**: **13** numbered ADRs…"* — `g-docs/decisions/` holds 16 (`001`–`016`, no gaps).
**Checked against:** `Glob g-docs/decisions/*.md` → 16 files. Contradicted inside the changeset by `g-wiki/architecture.md:80` ("16 to date, 001–016") and `:144`, and by `README.md:379`, which links ADR-014 three ADRs past its own claimed ceiling.
**Why it matters:** It is in the "Evidence" section — the block whose whole rhetorical point is that G-Forge's self-reports are checkable. The first count a sceptical reader checks is wrong, and the wiki was updated while the front door was not.
**Recommendation:** `doc-writer` — per ADR-013, either pin it (`tests/test-readme-counts.sh` already has the shape for a fourth pin, deriving from `g-docs/decisions/*.md`) or drop the number and link the directory.

### `README.md:24` (with `:26`, `:40-48`) — [BLOCKING]
**Lens:** Currency
**Issue:** *"**G-Forge 2.5 is the last feature release.**"* and *"2.5 is the version I'll build the next thing with, which is the real reason for freezing it"*. Superseded: `g-docs/decisions/014-v26-token-diet-reopens-after-freeze.md:10` — *"**1. v2.5.0 is no longer the final release.** ADR-012's minimal-freeze scope stands for what 2.5 contained; its finality claim is superseded. Development resumes with v2.6."* Two releases have shipped since. `### What shipped in 2.5` (`:40`) remains the newest release narrative on the page.
**Checked against:** `ADR-014:10`; `README.md:5` ("Version 2.6.1"); `README.md:379` (M53 → v2.6.0); `CHANGELOG.md:9,21`; `g-docs/ROADMAP.md:678` ("the freeze/fork sentence no longer governs"); `g-wiki/README.md:7`, which states the supersession correctly.
**Why it matters:** M54's goal is *"Everything G-Forge says about itself is true, and reachable from the front door"* — this is the front door, and it tells a prospective adopter the project is frozen two versions ago. `ROADMAP.md:622` put this in M54's scope explicitly ("Fix `README.md:40` — the heading reads `### What's in 2.5` at v2.6.1, contradicting the version strip at `:5`"). The heading was reworded to "What shipped in 2.5"; the contradiction it names is untouched. The scope item is not closed.
**Recommendation:** `doc-writer` — rewrite `## Where G-Forge is headed` from `ADR-014` and `CHANGELOG.md:9,21`; keep the G-Proof successor paragraphs, which remain true (`ROADMAP.md:678`).

### `README.md:259` and `README.md:314` — [BLOCKING]
**Lens:** Accuracy
**Issue:** Two pointers promise content the target page does not carry.
- `:259` — *"Full rules reference, presets, and design pattern details: [g-wiki/reference.md]"*. `g-wiki/reference.md` contains Skills, Agents, Stack Profiles, Supplementary, Combo, See-also. No rules reference, no presets, no design patterns. Presets are at `rules/references/install-presets.md`; the rules are `rules/g-rules/A-session.md … J-memory.md`.
- `:314` — *"For a complete agent catalog with descriptions, **dispatch rules, output architecture, and single-use discipline**, see [g-wiki/reference.md]"*. `reference.md:58-79` is a three-column `Agent | Tier | Role` table. Dispatch rules are `rules/dispatch-matrix.md`; single-use discipline is `rules/g-rules/C-agent-discipline.md` and `g-wiki/architecture.md:114-116`.
**Checked against:** full read of `g-wiki/reference.md` (146 lines); `Glob rules/g-rules/*.md`; `rules/references/install-presets.md`; `rules/dispatch-matrix.md`.
**Why it matters:** Introduced by the thinning: content was relocated out of README and the pointers were aimed at the new page without checking that the content landed there. This is known-open item 5 (condensation minting an unverified statement), realised. `:314` is also directly adjacent to pinned sentence 3, so it will be read by anyone following that count.
**Recommendation:** `doc-writer` — repoint to the files that hold the content, or drop the unfulfilled clauses.

### `g-wiki/commit-gate.md:65` — [BLOCKING]
**Lens:** Accuracy
**Issue:** The bullet list at `:62-67` is introduced at `:61` as *"File classification happens in the shared lib `hooks/lib/classify-changeset.sh` (lines 104–202)"*, so every bare line reference in it reads against that file. `:65` ends *"exempt-with-advisory (lines 281–282)"*. `hooks/lib/classify-changeset.sh` is **203 lines**; 281-282 is past EOF. The referenced code is `hooks/check-commit.sh:281-284`, a different file, unnamed at that point.
**Checked against:** `hooks/lib/classify-changeset.sh` (203 lines; function body 104-202 ✓ — the sibling citations at `:64` line 127, lines 193-194, and `:65` line 167 all verify correctly); `hooks/check-commit.sh:281-284`.
**Why it matters:** It is the one citation on the page that cannot resolve at all, and it sits among four that do — so a reader who spot-checks the others will trust it.
**Recommendation:** `doc-writer` — name the file, or convert to a symbol anchor per W1.

### `g-wiki/README.md:5` — [BLOCKING]
**Lens:** Currency
**Issue:** *"**Current state:** **v2.6.1 released** (2026-09-02 — the token-diet release, M53; …)"*. v2.6.1 is not the token-diet release and did not ship M53. `CHANGELOG.md:21` — `## [2.6.0] — 2026-09-02` is the token diet, "Milestone record: `g-docs/milestones/M53-v2.6-token-diet.md`". `CHANGELOG.md:9-19` — `## [2.6.1] — 2026-09-02` is the post-update nudge in `hooks/workflow-checkpoint.sh`. `README.md:379` maps M53 → **v2.6.0**.
**Checked against:** `CHANGELOG.md:9,13,21,23`; `README.md:379`; `g-docs/ROADMAP.md:605`.
**Why it matters:** `ROADMAP.md:619` scoped this line as a version-string bump ("current-state line → v2.6.1"); the version was advanced but the apposition describing v2.6.0's content was carried over unchanged, so the wiki index and the README roadmap table now disagree about which version M53 shipped as — and the one thing v2.6.1 actually contains goes unmentioned on the page that claims to state current state.
**Recommendation:** `doc-writer` — state v2.6.1 and what it shipped, then describe the 2.6 line's token diet as v2.6.0 / M53.

---

## WARNING

### `g-wiki/commit-gate.md` — ~25 line-number citations — [WARNING]
**Lens:** Clarity / Currency risk
**Issue:** The page's evidentiary structure is line ranges into five files. I verified them; **the substantive ones are accurate today** — `:38` (pre-commit 4-12 ✓), `:48` (33-38 ✓), `:50` (154-155 ✓), `:51` (line 58 ✓), `:52` (79-98 ✓), `:53` (226-248 ✓), `:57` (233-248 ✓), `:61` (104-202 ✓), `:64` (127, 193-194 ✓), `:65` (167 ✓), `:76` (14-23 ✓), `:90` (100-131 ✓), `:94` (2-58, 27-52 ✓), `:97` (189-196 ✓), `:98`/`:117` (200-247 ✓), `:102` (line 54 ✓), `:113` (218-238 ✓), `:119` (210-214 ✓), `:120` (223-227 ✓), `:121` (230-244 ✓), `:127` (138-141 ✓, 198-202 ✓). Three are already imprecise: `:46` "lines 1–252" for a 253-line file; `:86` "(ADR-004 lines 4–12)" applies `hooks/pre-commit`'s range to the ADR document, whose lines 4-12 are frontmatter and Context (the matching statement is `ADR-004:14`); and `:110` vs `:123` give `round-consolidation.md` two different ranges (`14–32`, `14–28`) for the same procedure — the same double-range defect corrected in-pass for `gf_validate_sentinel`. One BLOCKING instance is already past EOF (see above).
**Why it matters:** Line refs going stale on insertion is a recorded defect class here, and it demonstrated itself during this review: two of the three pinned README sentences moved (`:268 → :290`, `:290 → :312`) from a single `<details>` insertion. `tests/test-readme-counts.sh:6-8` already records the lesson — it matches "by anchor text/shape rather than by line number (which moves)". Twenty-five unpinned line refs are twenty-five future Currency findings.
**Recommendation:** Not blocking as shipped — I verified them and they resolve. Convert to sentence/symbol anchors (`the `gf_validate_sentinel()` function in `hooks/pre-commit``, as `:29` already does correctly; `the `--check` freshness branch`) via `doc-writer`, and fix the three imprecise ones in the same pass.

### `g-wiki/architecture.md:22` — [WARNING]
**Lens:** Accuracy
**Issue:** "deterministic logic moved to `scripts/detect-stack.sh` and `scripts/derive-owns.sh`" — neither path resolves. Actual: `skills/g-specialize/scripts/detect-stack.sh` and `skills/g-specialize/scripts/derive-owns.sh`. There is no repo-root `scripts/`, and the sentence's subject is `profiles/<stack>/`, so a reader looks in the wrong place twice.
**Recommendation:** `doc-writer` — use full repo-relative paths, as `:42` and `:44` correctly do.

### `g-wiki/reference.md:84` — [WARNING]
**Lens:** Accuracy
**Issue:** "**48 stack profiles** — from `profiles/*/rules/architecture.md`." That glob returns **56**. 48 is correct as *stack* profiles, but the stated derivation does not produce it; the real derivation is total − combo − supplementary, as `tests/test-readme-counts.sh:59-74` implements. The number is right and the receipt is wrong.
**Recommendation:** `doc-writer` — cite the derivation the test uses, or drop the derivation clause.

### `g-wiki/reference.md:98-100` — [WARNING]
**Lens:** Accuracy
**Issue:** `phoenix-liveview` is filed under "### JVM / .NET (8 profiles)". Phoenix LiveView is Elixir/BEAM — `profiles/phoenix-liveview/rules/architecture.md:4-8` is Ecto contexts and `lib/<app>_web/`. The group total (8) is only right because the misfile balances out.
**Recommendation:** `doc-writer` — regroup and re-total; the flat 48-name list is otherwise complete and correct against disk.

### `g-wiki/README.md:26` — [WARNING]
**Lens:** Accuracy
**Issue:** *"This convention was chosen at M54 (see `g-docs/ROADMAP.md` M54 scope)."* `ROADMAP.md:623` still poses it as open: *"Decide the currency guard: pinned claims (as `tests/test-readme-counts.sh` does) vs. an explicit 'narrative — verify against source' convention."* The citation points at the question, not the answer.
**Recommendation:** `doc-writer` — cite the record that holds the decision once it exists (an ADR, or the M54 close-out), rather than the scope line that asked it.

### `g-wiki/commit-gate.md:103` — [WARNING]
**Lens:** Completeness
**Issue:** The full-mode pack layout lists MANIFEST, diff.patch, files.txt, slices/ — omitting `done-conditions.md`, which is written on every build. Source: `build-review-pack.sh:54-57` (layout header names it) and `:299-317` (always written).
**Recommendation:** `doc-writer` — add it; it is the artifact that carries done conditions into the review.

### `g-wiki/usage.md:374` — [WARNING]
**Lens:** Accuracy
**Issue:** *"This is a 25-point diagnostic (from the README § "Commit Enforcement")…"* — the count is correct, the pointer is not. `README.md:298-300` (§ Commit Enforcement) carries no check count; the figure lives at `README.md:290`, inside the `## Workflow` block.
**Recommendation:** `doc-writer` — cite `skills/g-doctor/SKILL.md` (the source of truth the count is derived from) rather than a README section.

---

## Verified clean — checked and found accurate

Recorded so the next round does not re-spend on them. Each was opened and compared, not assumed.

- **`g-wiki/reference.md` skill table (`:11-50`)** — all 38 rows present; spot-checked descriptions against `skills/*/SKILL.md:3` frontmatter for g-init, g-plan, g-review, g-doc-review, g-status, g-doctor, g-execute, g-audit, g-docs, g-wiki, g-tier, g-voice, g-telemetry, g-retro, g-specialize, g-afk, g-trim, g-update, g-forecast, g-blast-radius, g-identity, g-align, g-brief, g-onboard, g-kickoff, g-intake, g-train, g-listen, g-help, g-refactor, g-optimize, g-skill-design, g-skill-validate — byte-identical.
- **`g-wiki/reference.md` agent table (`:58-79`)** — 19 rows; every Tier matches both `agents/*.md` frontmatter `model:` and `rules/dispatch-matrix.md:13-32`. `review-orchestrator`'s "(Shipped but not currently dispatched)" matches `agents/review-orchestrator.md:10`.
- **`g-wiki/reference.md` profile lists** — all 48 stack names match disk; 7 combo (`:132-138`) and 1 supplementary (`:122`) match the `agents/`-subdir split that `tests/test-readme-counts.sh:59-74` derives. `/g-specialize`'s 48-name frontmatter list at `:17` is complete.
- **`g-wiki/commit-gate.md` mechanism claims** — three-field stamp and its space-separated `key=value` format (`hooks/lib/sentinel-read.sh:18-29`); `commit_sentinel_ts` carrying write-tree not a timestamp; mixed-commit both-sentinels-or-deny and consume-both-together (`hooks/pre-commit:233-249`); five-bucket classification with unmatched→CODE (`classify-changeset.sh:124-200`); fail-open stdin-timeout exception and its rationale (`check-commit.sh:88-113`); `--no-verify` / `core.hooksPath` denial (`check-commit.sh:198-203`); light-tier and worktree escape paths.
- **`g-wiki/usage.md` `/g-plan` walkthrough (`:87-122`)** — Step 0 QA-panel question, Step 1 project-manager three-question challenge, Step 2 task-decomposer, Step 3 wave-planner, Step 3b forecast, Step 4 approval gate: all match `skills/g-plan/SKILL.md:19,21-27,29,48,87-89,91-93` including step numbering.
- **`g-wiki/usage.md` `/g-status` block (`:265-274`)** — matches `skills/g-status/SKILL.md:23-32` field for field.
- **`g-wiki/usage.md` milestone close-out (`:347-356`)** — matches `skills/g-review/SKILL.md:89`; `:59` "≤150 words" matches `skills/g-retro/SKILL.md:109`; `:242` cites `skills/g-docs/SKILL.md` Step 3, which is indeed "Parallel documentation scan".
- **`g-wiki/usage.md` g-docs reachability (M54 scope `ROADMAP.md:620`)** — all seven targets reachable: `env-vars.md`, `memory-taxonomy.md`, `orchestration-patterns.md` (`architecture.md:122-124`), `integration-tiers.md` (`usage.md:286`), `voice-profiles.md` (`:310`), `telemetry-metrics.md` (`:334`), `agents.md` (`reference.md:144`). All seven files exist.
- **`g-wiki/architecture.md:93`** — "every clone inherits the gate from committed `.claude/settings.json` + `.claude/rules/` + `.claude/hooks/`" is **true for consumer projects**: `skills/g-init/references/tracked-vs-ignored.md:12,23` deliberately leaves those tracked. This repo's own `.gitignore:11` ignores `.claude/*` as a documented self-host exception, which does not falsify the claim. Checked rather than assumed.
- **`README.md` structural claims** — five-bucket gate (`:96`, matches `pre-commit:169-181`); seven hooks and their events (`:112-119`); registration-in-settings-not-manifest (`:123`, `hooks/hooks.json:3`); ten G-RULES sections A–J (`:106`, `:259`, `Glob rules/g-rules/*.md`); 38 subcommand tokens (`:205`, one per skill, exact match); version 2.6.1 (`:5`, `.claude-plugin/plugin.json:4`); jq/python3/node fallback chain (`:149`, `check-commit.sh:62-86`); all four Documentation Index links resolve.

---

## Summary

**16 findings blocking · 7 warning.**

Top finding: `g-wiki/architecture.md:34` denies the existence of `agents/references/` — a shipped v2.6 layer of 15 files that eleven agent bodies read by path, and that `CHANGELOG.md:30` and `M53:13` both name — and `:36`'s "72 total" excludes them.

The pattern across the blocking list is one thing, not sixteen: claims that read plausibly and cite a path that does not contain them. `usage.md` carries three such citations (`:13`, `:77`, `:181`); `architecture.md` carries four dead ADR links plus three wrong counts and two wrong tool-grant claims; `README.md` carries two pointers into `reference.md` for content that is not there. This is the failure mode `ROADMAP.md:627`'s own premortem named as **high** for this milestone, and it is the reason `/g-doc-review` was told to check claims against source rather than plausibility.

Two of HQ's four in-pass corrections left an uncorrected twin, and one of them corrected in the wrong direction. Recommend the fix round re-derives from disk rather than editing prose in place, and re-runs this gate — a fix wave that edits only the lines named here will very likely mint the next round's findings in its own fix prose.

The restored `<details>` hook/lib manifest (`README.md:223-243`) is accurate and consistent with every other README enumeration; the only conflicting twin is `architecture.md:56-61`, which was already wrong before the restore.

**DETAIL:** `g-docs/agent-output/wave-4/task-6c-doc-review.md`

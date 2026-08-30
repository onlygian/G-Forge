# Retro: v2.5 minimal-freeze Session C (Waves 6–8 + gates) — 2026-08-30

## What was done
- Wave 6: Task 14 — `hooks/workflow-checkpoint.sh` amber echo rewritten from "remaining capacity drops below 25%" to "~25% of the window has been used"; `tests/test-workflow-checkpoint.sh` pins the direction and two absence guards (probe RED 85/3 → 88/0).
- Wave 6: Task 16 — `/g-forecast` "Miss-risk" relabeled "likelihood ≥1 premortem scenario fires" (`Scenario-fire:` label); README row + `/g-plan` blurb + voice-profile samples follow; formula, calibration and bands untouched.
- Wave 6: Task 17 — REFERENCE changeset class in `hooks/lib/classify-changeset.sh`: marked `reference/<bundle>/` (SNAPSHOT.md|NOTE.md) + inert-extension allowlist + dot-segment guard on the whole path → `HAS_REFERENCE`; both hook consumers exempt reference-only commits with a stdout advisory; unmarked, non-inert, extensionless and traversal paths gate as CODE.
- Wave 7 residual: Task 10b confirmed (installed architecture-skill body identical to profile source, frontmatter stripped).
- Wave 8: Task 19 — `CHANGELOG.md` `## [2.5.0] — 2026-08-30` written, `[Unreleased]` emptied; `g-docs/env-vars.md` gains `GF_CLASSIFY_ROOT`.
- Gates: code r1 HOLD → r2 HOLD → r3 HOLD → r4 MERGE READY (0C/0M/7m); doc r1 HOLD → r2 HOLD → r3 DOCS READY → r4 scoped DOCS READY. Full suite 684/0 across 24 suites (HQ-summed each round: 673, 681, 684). `review-holds` 0→1→2→3→0.
- Committed `6592bf2` (14 files). Installed copies hand-synced: `.claude/hooks/` ×3 + lib, `.git/hooks/pre-commit` + `.git/hooks/lib/`.

## Decisions made
- The REFERENCE exemption is an allowlist of inert extensions, not a denylist of code extensions (code-lead r1: a denylist guarding an exemption inverts fail-toward-deny; this repo's own `hooks/pre-commit` is extensionless). Evidence: r1 record, fix-round patch.
- The dot-segment guard checks the whole path, not the bundle name (code-lead r2: `reference/<marked>/../../CLAUDE.md` reaches the marker through `check-commit.sh`'s verbatim argv fold; native `pre-commit` unaffected). Evidence: r2 record, smoke record r3 (5/5).
- The exemption advisory prints on stdout in both hooks: the native hook's contract is stderr = deny, and Claude Code discards exit-0 stderr from a PreToolUse hook. Evidence: `tests/test-pre-commit.sh` Allow contract, r1 wave record.
- Tier 3 listen mode skipped per the standing release-and-dogfood decision (no hands-on smoke rounds).

## Patterns
### Worked well
- Falsifiability probes as a separate `g-forge-dev` dispatch caught a green-while-broken guard (probe C) that the implementer's own marker claimed was red.
- Running both gates in parallel on a frozen patch, with each fix lane grepping the other lane's literals, kept cross-lane drift to zero across three rounds.
- HQ re-summing the runner table each round (673 → 681 → 684) caught every count that moved on a committed surface before the doc gate did.

### Avoid / do differently
- Dispatch sizing: Task 17 as one dispatch (lib + consumers + tests + probes + record) blew through the 30-call cap twice and never wrote its record; the doc-writer and doc-reviewer caps are 10. Split by tool budget, not by topic; probes and attestation always separate; record before any long run.
- A guard test's fixture must contain what the unguarded path would find: probe C stayed green because nothing sat at `$ROOT/SNAPSHOT.md`, so "neutered → still passes" proved nothing until the marker was planted.
- Each fix round minted a smaller defect in the prose it added at the site it edited (`CHANGELOG.md:17` three rounds running; the test header's "Total assertions" ladder). Derive counts from the run at write time or omit them.
- `.git/hooks/lib/` was a stale July copy while `.git/hooks/pre-commit` and `.claude/hooks/lib/` were current; no drift check covers it (todo 17). The hook errored `[: : integer expression expected` and fell through fail-toward-deny, so the gate held, but by accident.
- Amber fired at 15 exchanges; the session finished the gate and pass-close under active monitoring without a `/context` reading, which only the developer can take.

## Cold-start context
**Branch:** `chore/v2.5-minimal-freeze` — ahead of `origin/main` by `59c7c63` · `7beeabf` · `9dd49c4` · `7208967` · `2633981` · `6592bf2` · this pass-close commit; never pushed, no upstream; sentinels consumed; `.claude/review-holds` 0.
**Active milestone:** M52 — v2.5 Minimal Freeze 🔄 In progress (Sessions A, B, C closed and committed; Session D release owed; target date 2026-08-30, today).
**Next up:** · **Session D — release** (`/g-resume` first): read `communication-plan-2.5.md` · decide todo 17 (`.git/hooks/lib/` outside every drift check, found at this commit; hand-synced) — fix in D or ship as a known gap · before first push: todo 15 F6 (`tests.yml` `permissions: contents: read` + `concurrency:`) · Task 20 bump both manifests to 2.5.0 (`test-version-agreement.sh`) · Task 21 §D step 5 literal-fact grep sweep (`2.4.1`, `coming in 2.5`, `candidate`, `pending`, `Unreleased`) · merge `main` `--no-ff` + push · Task 22 tag `v2.5.0` + GitHub release with the CHANGELOG section · freeze. Nudges due: `/g-trim` (last 2026-08-18), `/g-align`, M52-close `/g-wiki`.
**Key files touched:** classify-changeset.sh, check-commit.sh, pre-commit, workflow-checkpoint.sh, test-classify-changeset.sh, test-check-commit.sh, test-pre-commit.sh, test-workflow-checkpoint.sh, SKILL.md (g-forecast), README.md, CHANGELOG.md, env-vars.md, voice-profiles.md, tests/README.md, todo.md, ROADMAP.md, v25-minimal-freeze.md (forecast + plan), 2026-08-30-v25-minimal-freeze-session-c.md
**Carry-over context:** Gate records (gitignored): `agent-output/review/code-lead-2026-08-30-v25-session-c-waves678-r1..r4.md`, `doc-reviewer-…-r1..r4.md`, `g-forge-dev-…-r1..r3.md`, patches `diff-2026-08-30-session-c-waves678{,-fixround,-fixround2,-fixround3}.patch`; wave records `wave-6/`, `wave-8/`; plan Progress rows 6–8 complete (`g-docs/plans/` is gitignored). Carried: todo 15 now holds the Session C Minor set C-1…C-9; Session B's carried doc WARNINGs unchanged except two CLOSED (g-forecast co-sites → Task 16; CHANGELOG `[Unreleased]` Tasks 6–13 → Task 19); open advisory: `CHANGELOG.md:17` gitignored-record pointer (C-7), todo row 16 line cite (C-8), §I taxonomy row for `reference/` (Task 18 CUT). Forecast scenario 4 reconciled: did not happen, mitigation-held. Installed copies hand-synced; `/g-update` not run. Process rules carried + added: a fix reads the whole file and derives wording from the authority; pre-existing blockers → rule-text task; one wave + gate per session; MERGE READY closing counted HOLDs decrements `review-holds` in the same step; cite the sentence, not only the line, at a site about to be edited; size every dispatch under its agent's tool-call cap (implementer 30, doc-writer / doc-reviewer 10), probes + attestation as a separate `g-forge-dev` dispatch, record before any long run; a guard test's fixture must contain what the unguarded path would find; an allowlist guards an exemption, a denylist never can. Observer gap: HQ suite runs unjournaled.

## Journal basis
279 events read from `.claude/journal/2026-08-30.jsonl` at pass close: 4 commit · 273 agent · 2 session · 0 test (HQ's five direct suite runs are not journaled — the standing observer gap).

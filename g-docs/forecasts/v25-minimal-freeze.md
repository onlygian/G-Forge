# Forecast: v2.5 Minimal Freeze

> Created: 2026-08-28
> Plan: g-docs/plans/.pending-forecast.md
> Mode: regular

## Complexity
- Score: 9/10
- Breakdown: files 3, waves 2, boundaries 2, new surface 1, rule edits 1

## Miss-risk: 95% — High risk
- Raw score (pre-calibration): ≥100% (display-clamped; unclamped raw_score = 104.5)
- Calibration: adjustment -3, N=75 confirmed outcomes, M=8 mitigation-held (sample floor met)

## Premortem scenarios

| Rank | Scenario | Likelihood | Impact | Score | Mitigation | Source |
|------|----------|------------|--------|-------|------------|--------|
| 1 | Stale-carrier facts survive multi-round review / release sweep | 5 | 4 | 20 | Grep the literal facts (milestone tokens, version strings, counts, "candidate"/"pending") across every live surface before Task 21's release sweep and before each doc-gate — never walk an enumerated site list from memory. | g-docs/retros/2026-08-24-v241-release-cut.md, g-docs/retros/2026-08-28-patterns-resolve-27.md, g-docs/retros/2026-08-15-g-patterns-two-phase-lifecycle.md, g-docs/retros/2026-07-23-m46-update-integrity.md, g-docs/retros/2026-05-19-m10-m14-pre-shipping-sweep.md, g-docs/patterns-deferred.md (summary-disagrees-with-own-detail) |
| 2 | Delegate lost-write — agent stalls or returns without writing its report/record file | 5 | 4 | 20 | Every doc-writer / claude-plugin-implementer dispatch in this plan writes its record with the Write tool (never a Bash heredoc) to a named output_file; HQ reads back that exact path before accepting DONE; budget one SendMessage resume round-trip per dispatch before treating a stall as failed. | g-docs/retros/2026-07-23-m-audit-close-v230.md, g-docs/retros/2026-07-23-m46-update-integrity.md, g-docs/retros/2026-07-19-adr007-w15e.md, g-docs/retros/2026-07-19-w15f-guard-and-22.md, g-docs/retros/2026-08-23-m48de-close.md (5th sighting), g-docs/patterns-deferred.md (reviewer-record-write-blocked-by-missing-grant, deferred to M51 item 4, not yet applied) |
| 3 | Budget/deadline overrun against the Sunday hard stop | 4 | 5 | 20 | Run /context at every wave boundary (11 waves scheduled); if W1 (Saturday) is not closing by end-of-day, cut scope on the sweep-only items (Tasks 15/18) rather than compress W2's Sunday release steps. | g-docs/retros/2026-07-19-w15f-guard-and-22.md, g-docs/retros/2026-07-19-adr007-w15e.md, g-docs/retros/2026-07-21-w15g-pass1.md, g-docs/retros/2026-08-19-m48-split-and-m48a-wave.md |
| 4 | Hook edit breaks its own string-pinned test — a literal label lands in the line the hook parses | 4 | 4 | 16 | After editing hooks/workflow-checkpoint.sh and tests/test-workflow-checkpoint.sh (Task 14), simulate the consumer's own parse rather than eyeballing the string match, and grep-verify no duplicate/label-collision line was introduced into text the hook greedily parses. | g-docs/retros/2026-07-26-adr-010-verify.md, g-docs/retros/2026-08-15-patterns-resolve-and-n8n-roundtrip.md |
| 5 | New guard/mechanical check verifies the wrong claim (presence, not the qualifier beside it) | 4 | 3 | 12 | For the Task 17 REFERENCE classifier class, write the falsifiability probe (neuter the guard in a scratch copy, confirm RED) before trusting the guard green, and state which exact claim each check pins — not just presence, but the ordinal/qualifier next to it. | g-docs/retros/2026-08-17-m50-scope-and-scoped-review.md |

## Recommendations

Re-scope before approving. Cut the highest-impact items or move to a follow-up milestone.

## Outcome (filled in at /g-retro time)

| Scenario | Predicted | Actually happened? | Notes |
|----------|-----------|---------------------|-------|
| 1 | yes | **happened** — three consecutive rounds (r1 6B, r2 5B, r3 3B); every round's blockers were twins of the prior round's fix class, e.g. README:42 fixed while comms-plan:66 survived, g-execute:156 conditional flipped while "Above the floor, proceed." survived | record: pre-gate sweeps ran each round and caught one unscheduled stale fact per round (g-proof-roadmap tracking, g-telemetry:131 roster count), but the twin-in-same-file class still reached the gate every time. Instrument lesson recorded at plan Task 15: phrase-grep ≠ direction-grep |
| 2 | yes | **did not happen** — session ran zero implementation delegates; HQ applied all fixes inline after Session A's yield rate. Both doc-reviewer dispatches wrote their record on the first attempt | mitigation-held: every reviewer dispatch named an output_file and was told to write it first; HQ verified both paths on disk before reading (record) |
| 3 | yes | **happened** — overrun rule invoked 2026-08-28 to pay for Task 23 (adopter telemetry defects); Task 15 then partially un-cut at the r2 gate when the cut removed the owner of a 3× normative-rule contradiction. Session B closed at 40% window used, past the 25% floor, with the doc gate still HOLD and the code gate unrun | git+record: Tasks 15/18 cut in plan+ROADMAP; /context read 397.5k/1M at reset |
| 4 | yes | **unverified** — Task 14 (the hook/test pair) is Session C scope and did not run this session | unverified |
| 5 | yes | **happened** — twice, in the same session, on the new test-telemetry-contract.sh: the first falsifiability probe found 3 of 5 guards green-while-broken (shell function invisible in bash -c; a `[^.]` class that could not cross the dot in the target path). Then the Task 15 done condition was a phrase-grep that passed over a surviving clause carrying the old direction without the old phrase | record: probe output in plan Task 23 pass record; r3 gate finding B-2 |

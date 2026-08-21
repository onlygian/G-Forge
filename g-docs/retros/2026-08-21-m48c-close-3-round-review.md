# Retro — M48c close: waves 3-5 + 3-round review (r3-r5) (2026-08-21)

**Session:** resumed via /g-resume at the approved Wave 2/3 seam; ran waves 3-5, then the full review loop to MERGE READY and the gated commit `55c5bef`. M48c ✅.

## What happened

- **Wave 3 (task 5):** GF_FAST_STDIN_GUARD_MS validated from 40 quiet-machine samples (worst 6806ms, 2× = 13612) — 15000 initially retained.
- **Wave 4 (task 8):** EXPECTED_SUITE_COUNT 19→21; detached full run 590/0/21 (wall 1069s), HQ-summed independently.
- **Wave 5 (task 9):** env-vars finalized; CHANGELOG M48c bullet via doc-writer (HQ fixed a wrong step ref in its output: Step 2b→4b).
- **Review r3 — HOLD (0C/11M/18m):** orchestrator (cautious: code-reviewer ×2 + architecture-enforcer, all three HOLD, 18 Major raw) then code-lead downgraded 7 with evidence, confirmed 11. Two done conditions FAILED: version-agreement suite was cwd-dependent (proven red from $HOME), and the CHANGELOG:35 revalidation promise was never closed. The milestone's own headline artifacts carried the most findings.
- **Fix wave F1 (4 agents, all DONE):** cwd-independence · router target-path validation (6→8 tests, typo RED-proven) · contract fixes (Step-4b→HOLD conversion, durability bullet, per-request slug paths, single-owner 4c) · production-mode case restored (GF_HOOK_STDIN_GUARD_MS consumer back, probe 5-FAIL+1-green).
- **Loaded revalidation (r3 item 3, HQ):** 16-core busy-loop saturation; loaded worst 12849ms — ~2.1s under the 15000 bound. Finding vindicated; bound → 30000 (2× loaded worst 25698, rounded).
- **Attestation #2:** 592/0/21 (wall 1610s), router +2 the only delta.
- **r4 — HOLD (0C/3M/8m):** sweep contract's first live firing: 8 facts grepped, 3 stale prose survivors caught (incl. one minted BY the fix round's own CHANGELOG edit). All three fixed inline.
- **r5 — MERGE READY (0C/0M/4m cosmetic):** closures 8/8 sweep-clean; meta-check verified the replacement claims themselves.

## Decisions inferred

- Quiet-machine timing validation alone is insufficient for MSYS bounds — loaded measurement (nproc busy-loops around the fixture run) is now the method, and it changed the answer (15000→30000).
- One fixture case stays production-mode per bound so no timing constant goes consumer-less and no production path goes untested.
- Test-1-asserts-nothing (version-agreement) deliberately carried: fixing cascades an assertion-count re-attestation; recorded in handoff CARRIED.

## Patterns

- **Stale-literal-in-prose is the dominant defect class of doc-heavy changesets** — r3 found it 6 times, the fix round re-minted it, r4's sweep caught 3 more. The sweep contract this milestone shipped is aimed at exactly this and demonstrably works; authoring discipline alone did not.
- **Numbers I write go stale within the same session** — 581→590→592 and 15000→30000 each invalidated my own earlier doc edits. Derive-at-the-end beats fix-as-you-go for totals.
- Tooling: plain run_in_background got reaped twice on the long suite run — nohup+disown + Monitor-on-log is the reliable shape. Trailing a pipe onto a suite with sleep-300 stdin writers cost a 5-minute false hang (the handoff warned exactly this).
- Subagent record-write stalls: 2 resumes needed (~in line with the 1-in-3 class); SendMessage resume worked both times.

## Cold-start context
**Branch:** main
**Active milestone:** M48 — Review-Pipeline Hardening (a ✅ b ✅ c ✅ `55c5bef`; M48d next)
**Next up:** /g-plan M48d per the ROADMAP M48 section. Carried items in the handoff CARRIED list.
**Key files:** agents/code-lead.md (sweep contract) · skills/g-review/SKILL.md (Steps 4/4b/4c, slug paths) · tests/lib/timing-bounds.sh (30000, single-consumer note) · tests/test-router-skill-parity.sh (8) · tests/test-version-agreement.sh (3) · review records g-docs/agent-output/review/code-lead-2026-08-21*-r{3,4,5}.md (gitignored — durable closure evidence is in the handoff + this retro)

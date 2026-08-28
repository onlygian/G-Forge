## H · Testing Protocol

**Three tiers — different owners, different rules.**

**Tier 1 — Automated Gates** (Claude owns · blocking on every commit)
Lint · type-check · unit tests · build verification. Any red = stop, do not commit, report and fix first.
An agent reporting tests "written" or "done" is **not** evidence they pass — `test-writer` has no execution tool; it authors, it never verifies. Tier-1 green requires an **actual run with pasted output** (framework + pass/fail counts); MERGE READY is blocked until a real run is green. Whoever holds the execution tool runs the suite and owns the verdict (M-audit finding #20). HQ sums the runner's per-suite table independently before accepting any total — a summary total disagreeing with its own table is confabulated; the summed table wins. This applies beyond test suites — any tally in a review or closure record (findings count, "N of M closed") cites the table it was summed from in the same breath; a summary line that disagrees with its own table is confabulated.

**Falsifiability rule (applies in projects with an executable test suite).** A guard/negative test — one that pins a timeout, a suppression, an early exit, a deny path, or anything else that passes by something NOT happening — must prove it can fail before it's trusted: copy the guard's file (or the relevant test+guard pair) to a scratch location, neuter the guard in the copy, run the test against the copy, confirm RED, then discard the copy — nothing in the production tree is ever mutated, so there is no restore step and no aborted-run hazard. Whoever holds the execution tool performs the probe (same ownership rule as Tier 1, above). The probe's actual output goes in the pass record — the review/wave record for the change that introduced the guard test; the in-file comment next to the assertion is a **maintenance marker, not evidence**, and when the guard, the bound, or the assertion later changes, the old comment no longer covers the code — re-prove and re-date it, or the stale comment is worse than none. A new guard/negative test landing without both the marker and the pass-record entry is a review finding (Major), not a silent pass — reviewers check for it. The comment is a provenance record, not a WHY, and stands as an explicit exception to §D's WHY-only comment rule. Why: a guard test that never proved it can fail may be green because it tests nothing — this repo's audit found probe-proven green-while-broken assertions passing undetected.
Comment content: `falsifiability: guard neutered in scratch copy, test confirmed red — YYYY-MM-DD`, in the comment syntax the project's language uses (§G's per-language table) — never a bare `#` literal.

**Instrument-claim rule.** Every verification step states, in the same sentence as the check, which claim it pins — a line count is not an occurrence count, a presence-grep is not an absence-grep, a matched string is not the ordinal or qualifier beside it. Prefer absence-grep and simulate-the-consumer's-parse forms over counting matches.

**Tier 2 — Tooling-Assisted** (Claude runs when infrastructure exists)
E2E, integration, contract tests. If infrastructure is missing and the task touches a critical path, flag the gap explicitly — never silently skip.

**Tier 3 — Human-Driven** (user owns the verdict · Claude never infers pass from output)
Smoke tests · acceptance · design review · business logic correctness. User exercises the real app and reports findings in chat. Claude cannot substitute judgement here.

**Tier 3 native-app fallback** — for native/desktop apps (e.g. Tauri), computer-use `request_access` cannot grant permissions to an unregistered running binary (M-audit finding #24 / BUG-5), so a mid-session smoke test on a freshly built app is silently impossible. The app must be **installed before the session starts** (so the OS permission grant already exists) **or run in dev-mode** (which runs under an already-registered/trusted host process). If neither holds, flag the gap explicitly and fall back to the manual protocol below rather than assume computer-use can drive the app.

---

**Tier 3 Instrument — QA Panel or Test Plan**

Tier 3 requires a testing instrument. Which one depends on the project:

- **QA panel present** — a structured in-app testing UI. G-Forge integrates it from the start, not as an afterthought.
  - At milestone planning: identify which test groups are impacted. Compile `g-docs/qa-scope/<milestone-slug>.md` mapping each in-scope group to what must pass.
  - QA panel currency: any task adding/removing user-facing surface must include "QA panel updated" as a done condition. MERGE READY is blocked if the panel is stale.
- **No QA panel** — at milestone planning, generate a test plan and print it in chat. The test plan lists scenarios to exercise, grouped by feature area, derived from the milestone scope. The developer uses this as their checklist during Tier 3. No file saved — it is a live prompt artifact.

The instrument is established at milestone start. Tier 3 without an instrument (no QA panel and no generated test plan) is not valid.

---

**Tier 3 Protocol — Listen Mode**

Run `/g-listen` to enter listen mode. It writes the state file, prints the instrument, and enforces the collect-only discipline automatically.

Manual protocol (if `/g-listen` is unavailable):

1. Print the instrument: QA panel scope (from `g-docs/qa-scope/<milestone-slug>.md`) or the test plan generated at milestone start.
2. Prompt: `Ready for smoke test? Work through the list above and report each finding in chat — say "done this round" when finished.`
3. Claude enters **listen mode** — no fixes, no suggestions, no edits. Acknowledge each report only:
   > `Bug N logged — <bug area>`
4. User declares **"done this round"**
5. Claude triages the full batch:
   - Same class ≥ 2 occurrences → **systemic**: grep all instances, treat as one wave
   - Single occurrence, known location → **isolated**: inline fix
6. Systemic waves execute first, then isolated fixes
7. Tier 1 gates run after fixes before next round begins
8. Next Tier 3 round → back to listen mode
9. Repeat until user declares DoD met

**Hard stops during listen mode:** No file edits. No mid-round fixes. No "quick suggestions." Collect and triage only — never act on a single report in isolation.

**Listen mode state file — `.claude/tier3-active`**
- When entering listen mode: write `0` to `.claude/tier3-active`
- After each bug is acknowledged: increment the count in `.claude/tier3-active`
- After triage and fix wave completes: delete `.claude/tier3-active`
- The workflow-checkpoint hook reads this file and surfaces listen mode status on every prompt

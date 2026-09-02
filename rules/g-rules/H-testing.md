## H · Testing Protocol

**Three tiers — different owners, different rules.**

**Tier 1 — Automated Gates** (Claude owns · blocking on every commit)
Lint · type-check · unit tests · build verification. Any red = stop, do not commit, report and fix first.
An agent reporting tests "written" or "done" is **not** evidence they pass — `test-writer` has no execution tool; it authors, it never verifies. Tier-1 green requires an **actual run with pasted output** (framework + pass/fail counts); MERGE READY is blocked until a real run is green. Whoever holds the execution tool runs the suite and owns the verdict. HQ sums the runner's per-suite table independently before accepting any total — a summary total disagreeing with its own table is confabulated; the summed table wins. This applies beyond test suites: any tally in a review or closure record (findings count, "N of M closed") cites the table it was summed from in the same breath.

**Falsifiability rule (applies in projects with an executable test suite).** A guard/negative test — one that pins a timeout, a suppression, an early exit, a deny path, or anything else that passes by something NOT happening — must prove it can fail before it's trusted: copy the guard's file (or the relevant test+guard pair) to a scratch location, neuter the guard in the copy, run the test against the copy, confirm RED, then discard the copy — nothing in the production tree is ever mutated. Whoever holds the execution tool performs the probe. The probe's actual output goes in the pass record (the review/wave record for the change that introduced the guard test); the in-file comment next to the assertion is a **maintenance marker, not evidence** — when the guard, the bound, or the assertion later changes, re-prove and re-date it. A new guard/negative test landing without both the marker and the pass-record entry is a review finding (Major). The comment is a provenance record and stands as an explicit exception to §D's WHY-only comment rule.
Comment content: `falsifiability: guard neutered in scratch copy, test confirmed red — YYYY-MM-DD`, in the comment syntax the project's language uses (§G's per-language table) — never a bare `#` literal.
Why this rule exists, and its audit provenance: `.claude/rules/references/testing-notes.md`.

**Instrument-claim rule.** Every verification step states, in the same sentence as the check, which claim it pins — a line count is not an occurrence count, a presence-grep is not an absence-grep, a matched string is not the ordinal or qualifier beside it. Prefer absence-grep and simulate-the-consumer's-parse forms over counting matches.

**Tier 2 — Tooling-Assisted** (Claude runs when infrastructure exists)
E2E, integration, contract tests. If infrastructure is missing and the task touches a critical path, flag the gap explicitly — never silently skip.

**Tier 3 — Human-Driven** (user owns the verdict · Claude never infers pass from output)
Smoke tests · acceptance · design review · business logic correctness. User exercises the real app and reports findings in chat. Claude cannot substitute judgement here. When Tier 3 targets a native/desktop app (e.g. Tauri), read `.claude/rules/references/testing-notes.md` first — a mid-session smoke test on a freshly built binary is silently impossible unless preconditions hold.

---

**Tier 3 Instrument — QA Panel or Test Plan**

Tier 3 requires a testing instrument:

- **QA panel present** — a structured in-app testing UI, integrated from the start.
  - At milestone planning: identify impacted test groups. Compile `g-docs/qa-scope/<milestone-slug>.md` mapping each in-scope group to what must pass.
  - QA panel currency: any task adding/removing user-facing surface must include "QA panel updated" as a done condition. MERGE READY is blocked if the panel is stale.
- **No QA panel** — at milestone planning, generate a test plan and print it in chat: scenarios to exercise, grouped by feature area, derived from the milestone scope. No file saved — a live prompt artifact.

The instrument is established at milestone start. Tier 3 without an instrument is not valid.

---

**Tier 3 Protocol — Listen Mode**

Run `/g-listen` to enter listen mode. It writes the state file, prints the instrument, and enforces the collect-only discipline automatically — no fixes, no suggestions, no edits while listening; collect, then triage the full batch (systemic waves first, then isolated fixes; Tier 1 gates after fixes; repeat until the user declares DoD met). If `/g-listen` is unavailable, read `.claude/rules/references/testing-notes.md` and follow the manual protocol there step by step.

**Listen mode state file — `.claude/tier3-active`**
- When entering listen mode: write `0` to `.claude/tier3-active`
- After each bug is acknowledged: increment the count in `.claude/tier3-active`
- After triage and fix wave completes: delete `.claude/tier3-active`
- The workflow-checkpoint hook reads this file each prompt and surfaces listen-mode status in the checkpoint banner, which reprints on state change — each acknowledged bug increments the count and forces a reprint.

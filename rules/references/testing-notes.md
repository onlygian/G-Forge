# Testing protocol — rationale and edge cases (G-RULES §H companion)

Load trigger: read this when introducing or reviewing a guard/negative test (the falsifiability WHY), or when Tier 3 targets a native/desktop app. The normative rules live in `.claude/rules/g-rules-H-testing.md`; this file holds the reasoning and walkthroughs moved out of them (v2.6 token diet).

## Why the falsifiability rule exists

A guard test that never proved it can fail may be green because it tests nothing — this repo's audit found probe-proven green-while-broken assertions passing undetected. The scratch-copy procedure exists so nothing in the production tree is ever mutated: there is no restore step and no aborted-run hazard. A stale falsifiability comment — one whose guard, bound, or assertion has since changed — no longer covers the code and is worse than none, which is why re-prove-and-re-date is mandatory.

## Tier-1 verdict ownership — provenance

"Whoever holds the execution tool runs the suite and owns the verdict" is M-audit finding #20: agents without execution tools were reporting suites as passing.

## Manual listen-mode protocol (fallback when /g-listen is unavailable)

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

Maintain the `.claude/tier3-active` state file exactly as §H's core specifies (write `0` on entry, increment per acknowledged bug, delete after the fix wave).

## Tier 3 native-app fallback (M-audit finding #24 / BUG-5)

For native/desktop apps (e.g. Tauri), computer-use `request_access` cannot grant permissions to an unregistered running binary, so a mid-session smoke test on a freshly built app is silently impossible. The app must be **installed before the session starts** (so the OS permission grant already exists) **or run in dev-mode** (which runs under an already-registered/trusted host process). If neither holds, flag the gap explicitly and fall back to the manual listen-mode protocol rather than assume computer-use can drive the app.

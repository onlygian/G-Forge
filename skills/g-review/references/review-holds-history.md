# `.claude/review-holds` — the retired latch, and why wholesale resets are banned

Load when tempted to reset the counter, or when auditing the counter contract.
The live contract (increment / decrement / floor / never-reset) stays in the
/g-review core — the five phrases there are test-pinned
(`tests/test-telemetry-contract.sh`). This file carries the history.

**Never reset it wholesale**, and do not expect `/g-telemetry` to. *(Retired
2026-08-28: `/g-telemetry` used to reset the counter to `0` on a `stable`
profile, and that was the only clearing path. With no decrement it made a
latch — the counter only grew, growth forced a ⚠ on rework rate, and a ⚠ made
`stable`, hence the reset, unreachable. Found 2026-08-29 on this repo at
`fix_after_feat` 7 + `review_holds` 34 = `rework_signal` 41, over 30 `feat:`
commits — a 137% rework rate against a 20% threshold. See
`g-docs/field-reports/2026-08-28-g-sharp-telemetry.md` §2.)*

The counter is the number of code-gate HOLDs that are **currently unresolved**,
not a lifetime total (`g-docs/telemetry-metrics.md` metric 4, counter policy).
Resolution is the trigger for the decrement: the HOLD that was counted has
stopped being true, so it stops being counted. Mechanics: create-with-`1` when
the file is absent on an increment; on a decrement, an absent or unparseable
file is treated as `0` and left at `0` — never write a negative value.

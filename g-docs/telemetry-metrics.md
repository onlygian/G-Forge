# Telemetry Metrics

The 8 reliability metrics G-Forge tracks. Each metric is defined here; `/g-telemetry` computes them from observable artifacts (retros, forecasts, todo-done, git log, review-holds counter). All values are session-local approximations — no remote telemetry, no daemon, no background collection.

> **Known limitation — five of these eight metrics will read `n/a` on most projects, and that is the honest answer, not a bug.**
> Metrics 1, 2, 5, 6 and 8 source from retro prose by **literal token match** (`hallucinated-`, `re-dispatched`, `review caught`, `scope creep`, `escalated`, …). `/g-retro` does not emit those labels and never has — the metric spec and the retro-writing skill were never wired to a shared vocabulary. Measured across this repo's whole retro corpus, 2026-08-29: metrics 1 and 8 match **nothing at all**, and metrics 2, 5 and 6 match a handful of files between them. (No counts or denominator are stated here on purpose — `/g-retro` is a standing session-close step, so every figure of this kind is falsified by the next session, and ADR-013 rule 2 says pin it with a test or omit it. The *nothing at all* is the load-bearing part and needs no number.)
> **The correct behaviour is `n/a`, loudly** — see `/g-telemetry` Step 3. What is forbidden is filling the gap by reading the prose semantically and presenting the result as a measurement; that failure is what `g-docs/field-reports/2026-08-28-g-sharp-telemetry.md` documents.
> Closing the gap properly — teaching `/g-retro` the vocabulary, or replacing literal match with a marked interpretive pass — is **deliberately not in v2.5** (ADR-012 amendment 4: `g-docs/audits/2026-07-rebuild-map.md:53` marks telemetry's hand-counting as dying in the G-Proof rebuild, so 2.5 fixes only the dishonesty, not the collection mechanism). It is a G-Proof R0 candidate.

## How to read this file

- **What it measures** — the failure mode the metric is trying to catch.
- **Source** — files or commands the value is computed from.
- **Formula** — the exact computation, in pseudo-bash.
- **Range** — typical observed values; out-of-range values surface as `⚠`.
- **Used by** — which skill or hook adjusts behavior when this metric goes outside range.

---

## 1. Hallucination rate

**What it measures.** Fraction of agent outputs that referenced non-existent files, functions, or APIs and required correction.

**Source.** `g-docs/retros/*.md` — bullets under an `Avoid / do differently` heading at **any level** (`## ` or `### `; `/g-retro` ships it as `###`, nested under `## Patterns` — `skills/g-retro/SKILL.md`), matching the labels `hallucinated-`, `nonexistent-`, `wrong-api`, `bad-citation`.

**Formula.**
```
hallucination_rate = count(matching_bullets) / count(retros) * 100
```

**Range.** Expected 0–10%. ⚠ above 15%.

**Used by.** `/g-execute` — bumps reviewer count when hallucination rate is high; `/g-review` — adds an extra `code-reviewer` pass.

---

## 2. Review catch rate

**What it measures.** Fraction of `/g-review` cycles that caught at least one Major or Critical finding before the merge gate opened.

**Source.** `g-docs/retros/*.md` — bullets mentioning `review caught`, `code-lead caught`, `architect caught`. Negative signal: bullets matching `bug missed by review`, `review didn't catch`.

**Formula.**
```
review_catch_rate = (caught_bullets / (caught_bullets + missed_bullets)) * 100
```
If denominator is 0, report `n/a`.

**Range.** Expected 70–100%. ⚠ below 60%.

**Used by.** `/g-review` — declining catch rate triggers a 2nd code-reviewer pass with stricter instructions.

---

## 3. Regression frequency

**What it measures.** How often a closed task is reopened or a fix is followed by a fix-of-fix within the same milestone.

**Source.** `git log --oneline -200` — count of commits matching the rework regex used by `workflow-checkpoint.sh`.

**Formula.**
```
regression_frequency = rework_commits_last_50 / 50 * 100
```

**Range.** Expected 0–8%. ⚠ above 12%.

**Used by.** `/g-execute` — high regression triggers smaller wave sizes (max 2 agents/wave).

---

## 4. Rework rate

**What it measures.** Fraction of merged PRs that required a follow-up fix within the same week, **plus** review-time HOLDs that did not produce a clean review on first attempt.

**Source.** `git log --oneline -200` for commits; `.claude/review-holds` for the running HOLD counter (written by `/g-review` Step 4 on any HOLD verdict).

**Formula.**
```
fix_after_feat       = count of `fix:` commits within 7 commits after a `feat:` commit (last 200)
feat_commits         = count of `feat:` commits (last 200)
review_holds         = value in .claude/review-holds (default 0 if absent)
rework_signal        = fix_after_feat + review_holds
rework_rate          = (rework_signal / max(feat_commits, 1)) * 100
```

**Counter policy (rewritten 2026-08-28 — the previous policy was a latch; see below).** `.claude/review-holds` is a count of **currently-unresolved** code-gate HOLDs, not a lifetime total:
- `/g-review` **increments** it by 1 on a HOLD verdict (Step 4).
- `/g-review` **decrements** it by 1, floored at 0, when a subsequent run closes that HOLD — it already knows it is re-reviewing after one, because Step 4b's fix-closure sweep is keyed on exactly that claim. Resolution is the decrement trigger.
- `/g-telemetry` does **not** reset it. A telemetry run is an observer of this counter and never a writer of it.

~~Previous policy: reset to `0` whenever `/g-telemetry` derives a `stable` profile.~~ **Retired 2026-08-28 — it was a positive feedback loop.** The counter only ever grew (increment unconditional, no decrement), which inflated rework rate, which produced a ⚠, which made `stable` unreachable, which prevented the only reset — so the latch closed on itself and the subsystem drove every long-running project toward `recovery` as a function of age rather than quality. Measured on this repo the day it was found (2026-08-29, all three formula inputs stated so the figure reproduces): `fix_after_feat` 7 + `review_holds` 34 = `rework_signal` 41, over `feat_commits` 30 — a **137%** rework rate against a 20% threshold. A "rate" over 100% is the tell. Reported by an adopter at `g-docs/field-reports/2026-08-28-g-sharp-telemetry.md` §2, where a HOLD raised and resolved on 2026-07-12 was still inflating the metric 47 days later.

**Migrating a counter written under the old policy.** A counter carried over from 2.4.x is a *lifetime* total, not a count of unresolved HOLDs, so it is not comparable under this policy and will read far too high — this repo's own stood at 34 against 30 `feat:` commits. On the first run under this policy, set the file to the number of code-gate HOLDs that are **actually still open** (usually `0` — a HOLD whose fixes were merged is resolved, whatever the counter says), and note the reset with its evidence in the session record. This is a one-time correction, not a recurring reset: there is no reset path in this policy by design, because the reset path is what made the latch.

**Scope — code-gate HOLDs only, by design.** `/g-doc-review`'s `DOCS HOLD` does not touch this counter. That is deliberate and stated here so the omission is a decision rather than an accident: the doc gate has its own verdict and its own record, and giving two gates one counter makes the number mean different things depending on which gate caught the failure. Rework rate therefore measures the code gate. Anything wanting doc-gate rework needs its own counter and its own metric — not a second writer to this one.

**Range.** Expected 0–15%. ⚠ above 20%.

**Used by.** `/g-review` — reads and announces the profile and passes it to `code-lead`; the profile-conditional `debugger` pre-review this metric was designed to drive is **not wired as shipped** (see the stamp under the profile table below). `/g-review` owns both sides of the counter: it increments on a HOLD verdict regardless of profile, and decrements on the run that closes one (the increment and decrement are both unconditional; only the *consumption* changes with profile).

---

## 5. Spec deviation

**What it measures.** How often executors deviated from the approved spec — e.g. added unscoped files, refactored adjacent code, scope-crept.

**Source.** `g-docs/retros/*.md` — bullets under an `Avoid / do differently` heading at **any level** (`## ` or `### `; see metric 1's Source note), matching `scope creep`, `unscoped`, `refactored adjacent`, `out of plan`, `deviated`.

**Formula.**
```
spec_deviation = count(matching_bullets) / count(retros) * 100
```

**Range.** Expected 0–10%. ⚠ above 15%.

**Used by.** `/g-execute` — high deviation appends a stricter scope-boundary reminder to every agent prompt.

---

## 6. Escalation frequency

**What it measures.** How often a task escalated to a higher model tier (Sonnet → Opus) due to repeated failure.

**Source.** `.claude/escalation-log` — a plain-text counter written by `/g-execute` whenever the Three-Strikes rule (G-RULES.md §A8) escalates a task. One line per escalation: `YYYY-MM-DD <task-id-or-label>`. `g-docs/retros/*.md` bullets matching `escalated`, `bumped to opus`, `three-strikes` are read as a fallback for sessions before `.claude/escalation-log` was introduced.

**Formula.**
```
escalations  = wc -l of .claude/escalation-log  (or retro-bullet count if log absent)
dispatches   = total commits in this branch's history (cheap proxy for total work)
escalation_frequency = (escalations / max(dispatches, 1)) * 100
```

The window is intentionally **all-time** — escalations are rare events and a 30-day window produces noisy ratios on small corpora.

**Range.** Expected 0–5%. ⚠ above 10%.

**Used by.** `/g-execute` — high escalation triggers Opus-default for the next dispatch in this milestone. `/g-execute` also writes a new line to `.claude/escalation-log` whenever it applies Three-Strikes, so this metric is self-feeding.

---

## 7. Token efficiency

**What it measures.** Average context tokens used per closed task — proxied by reading the average commit diff size for the last 30 commits and the number of tool calls observed in retros (when noted).

**Source.** `git log --stat -30` for diff size; retros for tool-count notes (often "many parallel agents", "single dispatch", etc.).

**Formula.**
```
avg_diff_size = sum(insertions + deletions, last 30 commits) / 30
efficiency_score = clamp(0, 100, 100 - (avg_diff_size - 50) / 5)
```
Higher is better. A tight 50-line average commit is 100%; a 500-line commit average is 10%.

**Range.** Expected 50–100. ⚠ below 40.

**Used by.** Surfaces in `/g-help` as a hint to refactor or split waves; not auto-actioned.

---

## 8. Retry dependency

**What it measures.** Fraction of dispatched agent waves that required a re-dispatch with corrections.

**Source.** `g-docs/retros/*.md` — bullets matching `re-dispatched`, `wave 2 take 2`, `had to retry the agent`, `agent returned empty`.

**Formula.**
```
retry_dependency = count(matching_bullets) / count(retros) * 100
```

**Range.** Expected 0–8%. ⚠ above 12%.

**Used by.** `/g-execute` — high retry dependency adds an explicit pre-dispatch verification step.

---

## Health profile derivation

`/g-telemetry` aggregates the metrics into one of four health profiles. Profiles are derived from the **ratio** of ⚠ metrics to **computable** metrics, not the absolute count — so a project with several `n/a` (insufficient-data) metrics still has a meaningful health profile.

```
computable = count of metrics whose status is ✓ or ⚠ (excludes n/a)
warn_ratio = ⚠ count / max(computable, 1)
```

| Profile | Trigger | Effect |
|---------|---------|--------|
| `stable` | `warn_ratio == 0` (all computable metrics in range) | Default behavior — no adaptive changes. **Writes no counter** — `.claude/review-holds` is owned by `/g-review` alone (see metric 4's counter policy). |
| `cautious` | `0 < warn_ratio ≤ 0.25` (small fraction ⚠) | `/g-review`: announced and passed to `code-lead`, which scales its own scrutiny — no extra reviewer is dispatched as shipped (see stamp below); no model changes |
| `defensive` | `0.25 < warn_ratio ≤ 0.50` | `/g-execute` bumps model tier on next dispatch (wired — `skills/g-execute/SKILL.md` Step 0); the `/g-review` +2 reviewers and `debugger` pre-pass are **not wired as shipped** (see stamp below) |
| `recovery` | `warn_ratio > 0.50` (majority ⚠) | `/g-execute` reduces wave size to 1 agent (wired); the `/g-review` all-reviewers fan-out is **not wired as shipped** (see stamp below); `/g-help` prints the profile in its status line (`skills/g-help/SKILL.md`) — the "consider /g-audit" suggestion is not implemented |

**Stamped 2026-08-29 (code gate r1) — the `/g-review` effects above are the design, not the shipped behaviour.** As shipped, `/g-review` reads the profile, announces it, and passes it to `code-lead`, which holds no `Agent(` grant — so no extra reviewer, no `debugger` pre-pass, and no full-set fan-out is dispatched by any agent (`agents/code-lead.md` INERT stamp; `skills/g-review/SKILL.md` Step 0 note). The `/g-execute` effects (wave-size cap, model tier, prompt clause) are wired in `skills/g-execute/SKILL.md` Step 0. Wiring the review panel was M51 item 1, dropped 2026-08-28 (ADR-012 amendment 4).

Floor: if `computable < 5`, force `stable` regardless of ratio, and report the run as a **measurement vacuum** — say so in the snapshot summary and name which metrics were `n/a`. Too few signals to classify reliably: with five of eight metrics sourced from retro prose, a run that computes only a minority of them is reporting on git hygiene alone, which says nothing about agent reliability. This subsumes the bootstrapping case (≤2 computable metrics is the same condition).

*(Raised from `computable < 3` on 2026-08-28. The old floor did not catch the failure it existed to catch: the adopter run in `g-docs/field-reports/2026-08-28-g-sharp-telemetry.md` landed at exactly 3 computable — one above the floor — and all three were git-derived. A forced `stable` here is a floor, not an assessment, and the snapshot must say which it is.)*

The profile is written to `.claude/telemetry-profile` (single-line, value is the profile name). `/g-execute` Step 0 and `/g-review` Step 0 read it; absence of the file is equivalent to `stable`.

---

## Bootstrapping note

On a project with fewer than 3 retros and fewer than 30 commits, telemetry derivation is unreliable. `/g-telemetry` emits `cold-start — too thin to compute` for any metric whose source has insufficient data, and the profile defaults to `stable`.

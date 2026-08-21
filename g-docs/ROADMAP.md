## Active Session

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — g-forge | branch: main | M48c COMPLETE pending final review round MERGE READY + gated commit · 2026-08-21
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · **M48c waves 3-5 executed**: task 5 bound validated quiet (worst 6806ms) · task 8 EXPECTED_SUITE_COUNT 19→21 + full run · task 9 doc closeout. · **/g-review r3: HOLD** (0C/11M/18m, record code-lead-2026-08-21-r3.md; orchestrator cautious set: code-reviewer ×2 + architecture-enforcer, all three HOLD). · **Fix wave F1 (4 agents, all DONE)**: version-agreement cwd-independent 3/3 two-cwd proven · router-parity target-path validation 6→8 tests, typo RED-proven · g-review/code-lead contracts (Step-4b→HOLD conversion + :249 qualifier, durability bullet restored, per-request slug paths code-lead-[date]-[slug]-r[N], dep-auditor r[N], review-holds on 4b blocks, single-owner Step 4c), severity 9/0 · override fixtures: post-commit-cleanup restored to production-mode 5s guard (GF_HOOK_STDIN_GUARD_MS consumer restored), probe re-proven RED (5 fast FAIL + 1 production PASS), GF_FAST_STDIN_OVERRIDE_S centralized. · **HQ loaded revalidation**: 16-core saturation, loaded worst 12849ms vs 15000 (~2.1s margin — r3 item 3 vindicated) → GF_FAST_STDIN_GUARD_MS=30000 (2× loaded worst), probe comments literal-updated with provenance. · **Docs sweep**: CHANGELOG M48c bullet corrected (592/30000/updated-not-new) + M48b promise closed · tests/README 21/592 · ROADMAP :556 counts+line-refs · env-vars rows 15-16/36/38 · run-all :117 comment · CLAUDE.md 592/21 + router 8. · **Attestation: 592/0/21** (detached run, wall 1610s, HQ-summed = runner total; post-run edits doc-only, grep-proven unread by suites).
Next up:          · **confirm latest review round** (records code-lead-2026-08-21*-r*.md; r4 HOLDed 3 stale-prose survivors — fixed same session, r5 dispatched) — on MERGE READY: Step 4b sweep-record check (first live run — r4 claims r3 closures, record code-lead-2026-08-21-m48c-r4.md), then sentinel stamp (ADR-004: stage → write-tree/HEAD/toplevel, separate calls) → gated commit → M48c ✅ close-out (version bump decision — all M48 subs ride v2.5.0 — retro, close swarm). · Then M48d per ROADMAP M48 section. · CARRIED: AFK permissions-block decision · §A7 25%-USED doc task (B9 → M51 item 6) · M43 W4 governance ADR · n8n slugify · inbox trust-boundary ADR · M38 delivery decision · intake rows (a)-(h) · task 6 (M51 rider, execution only) · task 7 remainder (sleeper reaping) · version-agreement Test 1 asserts-nothing (r3/r4/r5 carried minor — fixing cascades an assertion-count re-attestation) · r5 cosmetic minors (ROADMAP:541 tail wording, timing-bounds:18 wrap siblings).
Active context:   · **MERGE READY at r5** (0C/0M/4m cosmetic-carried; record code-lead-2026-08-21-m48c-r5.md) — Step 4b passed on recorded sweep evidence (r4: 8 facts, 3 survivors caught then fixed; r5: 8/8 clean, no new stale literal); attestation 592/0/21 VALID. · r3/r4 closures CONFIRMED with sweep evidence in the r4+r5 records (durability carry): version-agreement REPO_ROOT · router target-paths · SKILL :147/:249 · durability bullet · slug paths · bound 30000 · GF_HOOK consumer · doc counts 592/21 · provisional-clause sweep clean. · Loaded-measurement method: nproc busy-loops around fixture run, harvest worst, 2× — reusable. · ADR-004: sentinels bind the STAGED tree — stage, then stamp commit_sentinel_ts=<write-tree> commit_sentinel_head=<HEAD> commit_sentinel_worktree=<toplevel>, separate calls; commit messages via Write-tool file, never heredoc. · Suite runs >10min: nohup+disown (plain run_in_background got reaped twice) + Monitor on the log; never trail a pipe (sleep-300 writers hold it — cost one 5-min false hang this session). · Subagent stalls ~1-in-3 — SendMessage resume, twice needed this session. · LOCAL STATE: review-holds 30 · voice gian · telemetry cautious · last-trim 2026-08-18 · escalation-log +1 (m48c-t7). · Format note: keep this line's leading label intact, use exactly the three section labels, replace this block **wholesale** each pass, and never repeat this line's own leading label text anywhere else on it (workflow-checkpoint.sh strips with a greedy BRE through the LAST occurrence; pre-compact.sh uses awk block capture — the two disagree when violated).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Milestones

### M1 — Foundation
**Status:** ✅ Complete
**Version:** v0.1.0
**Goal:** Repo, plugin.json, 16 agent stubs, skill dirs, hooks, profiles, milestone files

---

### M2 — Agent Roster
**Status:** ✅ Complete
**Version:** v0.2.0
**Goal:** Full system prompts for all 16 agents — mandates, output contracts, scope discipline

---

### M3 — Skills & Orchestration
**Status:** ✅ Complete
**Version:** v0.3.0
**Goal:** /g-kickoff, /g-init, /g-plan, /g-execute, /g-review — end-to-end with commit enforcement

---

### M4 — Stack Profiles
**Status:** ✅ Complete
**Version:** v0.4.0
**Goal:** /g-specialize + 44 profiles across web, mobile, desktop, game dev, and systems

---

### M5 — Publish
**Status:** ✅ Complete
**Version:** v0.5.0
**Goal:** README, docs/agents.md, docs/orchestration-patterns.md, marketplace listing

---

### M6 — Auto-trigger & Project Hygiene
**Status:** ✅ Complete
**Version:** v0.6.0
**Goal:** workflow-checkpoint hook, auto-trigger plan/execute/review, /g-help /g-status /g-brief /g-doctor

---

### M7 — Correctness, Validation & Polish
**Status:** ✅ Complete
**Version:** v0.7.0
**Goal:** Section F design patterns, game-dev profile rules, per-project G-RULES.md, full alignment pass

---

### M8 — Deploy & Use
**Status:** ✅ Complete
**Version:** v0.9.0
**Goal:** Self-host G-Forge on this repo; add claude-plugin profile; add skill-design and skill-validate vibecoding skills
**Scope:**
- Install G-Forge into this repo (CLAUDE.md, hooks, settings.json, milestone files)
- Create milestones/M6, milestones/M7 files (retroactive)
- claude-plugin stack profile — architect agent + architecture rules
- /g-skill-design skill — guided workflow for designing new skills/agents
- /g-skill-validate skill — validates SKILL.md and agent files against quality criteria
- Register skill-design and skill-validate in commands/g-forge.md router

**Depends on:** —

---

### M9 — Intelligence Foundation
**Status:** ✅ Complete
**Version:** v0.10.0
**Goal:** Structural substrate for agent context management and decision memory
**Scope:**
- **Rename pass** — project renamed from G-Team → G-Forge; update all display strings, doc references, CHANGELOG heading, README, plugin.json `name`/`display_name`, marketplace.json, and any in-file prose mentioning "G-Team" across the full repo
- Context profiles v1 — memory slice declared in skill/agent frontmatter
- Memory layer taxonomy — 6 tiers (Working / Task / Sprint / Architectural / Institutional / Human Preference) with lifetime + audience
- ADR lineage fields — rejected alternatives, assumptions that held, constraints that drove the decision

**Depends on:** M8

---

### M10 — Organizational Learning Loop
**Status:** ✅ Complete
**Version:** v0.11.0
**Goal:** G-Forge detects recurring failure patterns and proposes self-corrections
**Scope:**
- /g-patterns skill — mines retros + todo-done for recurring failure modes; surfaces systemic health report
- Self-evolution — detected systemic pattern surfaces suggested fix to architecture profile rules, not just a report

**Depends on:** M9, accumulated retro/todo-done history

---

### M11 — Planning Intelligence
**Status:** ✅ Complete
**Version:** v0.12.0
**Goal:** /g-plan and /g-roadmap gain forecast, premortem, and in-flight health tracking
**Scope:**
- /g-forecast skill — scope realism analysis, complexity scoring, quantified risk estimate ("X% likely to miss target")
- Premortem wired into /g-forecast — ranked failure scenarios before plan approval, seeded by /g-patterns history
- Feedback loop closed — /g-patterns → premortem → /g-retro → /g-patterns
- Milestone health live monitoring — in-flight signal: blocker count, rework rate, review churn; surfaces via /g-help or hook

**Depends on:** M10 (/g-patterns must exist to seed premortem scenarios)

---

### M12 — Reliability & Adaptive Systems
**Status:** ✅ Complete
**Version:** v0.13.0
**Goal:** Instrument agent performance; system adapts its behavior based on measured reliability
**Scope:**
- 8-metric reliability telemetry: hallucination rate, review catch rate, regression frequency, rework rate, spec deviation, escalation frequency, token efficiency, retry dependency
- Adaptive orchestration — telemetry scores drive model selection and conditional reviewer spawning
- Governance intelligence — adaptive review gates by project stability and zone risk

**Depends on:** M11 (planning workflows must be instrumented before measuring them)

---

### M13 — Profile Additions
**Status:** ✅ Complete
**Version:** v0.14.0
**Goal:** Expand stack coverage and deepen existing frontend profiles
**Scope:**
- flask profile
- pygame profile
- xamarin profile
- dependency-auditor agent
- `frontend-data-flow` supplementary profile — rules + architect agent implementing the two-network model (read/write), dead-end component rule, and V1–V4 violation patterns; installed alongside any component-framework profile by `/g-specialize`
  - **Implementation note:** `/g-specialize` detection logic must be updated to auto-install `frontend-data-flow` whenever a component-framework stack is detected (vue-pinia, react, nuxt, next-js, sveltekit, angular, remix, astro, and composites). The profile is supplementary — it lives in its own directory and must be explicitly wired into the specialize skill's profile map; it will not activate automatically just by existing.

**Depends on:** M8 (independent of intelligence milestones; slots here as pacing break between M12 and M14)

---

### M14 — Advanced Production Modeling
**Status:** ✅ Complete
**Version:** v0.15.0
**Goal:** PM layer reasons about feature dependencies, costs, and long-term project trajectory
**Scope:**
- Dependency intelligence — feature-level dependency graph, blast radius analysis, volatility scoring; surfaces before execution ("this touches 4 high-volatility systems")
- Economic reasoning — token cost estimates, system impact counts, strategic deferral suggestions
- Temporal project cognition — persistent operational identity from accumulated signals: recurring risks, architectural personality, delivery patterns

**Depends on:** M12 (telemetry data), M10 (pattern history), M11 (blast radius feeds /g-forecast)

---

### M15 — Hook / Behavioral Integration Pass
**Status:** ✅ Complete — v1.0.0 shipped
**Version:** v1.0.0
**Goal:** G-Forge becomes a coherent production intelligence system, not a collection of additions
**Scope:**
- Full hook audit and behavioral flow wiring end-to-end
- Health surfaces in /g-help; premortem auto-runs in /g-plan; pattern suggestions feed /g-retro output
- UX tuning across the full system — flows feel cohesive, not additive

**Depends on:** M14 (all capabilities must be in place before the integration pass)

---

### M19 — Ambient Proactivity
**Status:** ✅ Complete
**Version:** v1.6.0
**Goal:** G-Forge watches continuously, stays anchored to the brief, and reacts to feature drops — less command-driven, more ambient
**Scope:**
- Silent observer (`hooks/observe.sh` + `hooks/agent-lifecycle.sh`) — passive `.claude/journal/` activity log; `/g-retro` reworked to synthesize from it (no interview)
- `/g-align` — brief-deviation check vs `project_brief.md`; auto-runs at milestone close, nudged between milestones; advisory
- `/g-intake` — proactive feature-drop triage (classify against brief → propose placement + version + risk → ask before writing)
- Hardened the JSON-parse cascade across all hooks (no fail-open on the Windows python3 stub)

**Depends on:** M18 (compact-return + plan-derisking foundation)

> Note: M16–M18 shipped between M15 and M19 (see CHANGELOG and README roadmap table for v1.2.0 / v1.3.3 / v1.5.0) — this file tracks the headline milestones.

---

### M20 — Single-Use Agent Doctrine
**Status:** ✅ Complete
**Version:** v1.7.0
**Goal:** Make context poisoning structurally impossible — agents are single-use; retries live at HQ via clean learnings reports, not inside a degrading executor context
**Scope:**
- Single-use agent doctrine in G-RULES §C — one approach, one attempt; names and prevents context poisoning
- `FAILED` agent outcome + `LEARNINGS:` field in the return contract, distinct from `BLOCKED`
- `/g-execute` redeploy loop — HQ analyzes learnings and deploys a fresh agent with a different mechanism, bounded by Three-Strikes (§A8), then escalates to the human
- Doctrine note in `docs/orchestration-patterns.md` framing it as the automatable form of the deliberation/execution split

**Depends on:** M18 (compact-return contract this extends)

---

### M21 — Decision Hygiene Loop
**Status:** ✅ Complete
**Version:** v1.8.0
**Goal:** Apply the single-use doctrine to HQ's own deliberation and close the loop — high-stakes thinking happens off-context, and the session resets after a decision is finalized
**Scope:**
- `/g-adr` offloads the weighing to a throwaway deliberation subagent; HQ promotes only the finalized draft (HQ window stays clean)
- Decision-hygiene reset reuses the §A7 context-gate path on a semantic trigger — `/g-retro` + handoff (`verify ADR-NNN` first) + fresh-session recommendation
- G-RULES §C extended with HQ deliberation hygiene; orchestration-patterns doctrine section extended

**Depends on:** M20 (single-use agent doctrine this generalizes to HQ)

---

### M22 — Session Re-entry
**Status:** ✅ Complete
**Version:** v1.9.0
**Goal:** Make "start a fresh session" cheap — the read side of the reset seam, so a clean window re-hydrates the right slice of the durable record instead of inheriting a poisoned one
**Scope:**
- `/g-resume` — selective re-hydration: pulls the relevant retro cold-start, in-force ADRs, journal tail, and handoff first-task into a clean window, keyed to branch/milestone/first-task; offers the clean-slate ADR verification when one was handed off
- First-prompt `/g-resume` nudge in `workflow-checkpoint.sh` when a handoff is pending
- §A7 reframed as a two-sided reset (promote out via `/g-retro`; re-hydrate in via `/g-resume`); orchestration-patterns doctrine extended with the read side

**Depends on:** M19 (observer journal), M20–M21 (the reset path `/g-resume` re-enters from)

---

### M23 — G-Forge 2.0 (Production-Readiness Audit)
**Status:** ✅ Complete
**Version:** v2.0.0
**Depends on:** all prior milestones (this audits the whole surface).

Self-contained kickoff — paste the block below into a fresh session (or open cold and run `/g-resume`, which points here):

```
G-Forge 2.0 — production-readiness audit. The bar: "no shit." Ruthless pass for
consistency, clarity, and shippability. No half-measures, no leftover cruft, no
stale docs, no claims the repo doesn't back up. Fix what you find; don't just report.

Work on a fresh branch (e.g. claude/g-forge-2.0-audit). Do NOT push to main without
explicit approval. Use G-Forge's own tooling where it fits (/g-audit, /g-docs,
/g-doctor, /g-review). Keep CHANGELOG.md AND README in sync as part of "done" for
every change — standing rule, not an afterthought.

EXPLICIT DELIVERABLES
1. .gitignore — review and tighten. Confirm it excludes everything generated
   (.claude/ runtime, scratch, agent-output, journals, sentinels, OS files) and
   nothing that is real plugin content. (Current file uses legacy "G-Team" wording.)
2. Clean the repo — remove dead/stray files; decide what should not ship. Known:
   hooks/test-check-commit.sh and hooks/test-observe.sh ship in hooks/ — move to a
   tests/ dir or exclude. Sweep orphaned references, dead links, placeholder files.
3. Agents <> hooks reconciliation — every agent a skill references exists (17
   present); every hook in hooks/hooks.json matches g-init's install table AND
   g-doctor's checks (paths, names, registration); nothing referenced-but-missing
   or installed-but-unregistered.
4. README v2 — rewrite from scratch (don't patch). Start under a PLACEHOLDER project
   name; keep the real name out until content is approved, then swap it in one pass.

CONSISTENCY / CLARITY SWEEP (seeded findings — start here, don't stop here)
- Legacy "G-Team" strings still in: hooks/hooks.json, hooks/pre-compact.sh,
  hooks/check-commit.sh, hooks/post-commit-cleanup.sh, hooks/workflow-checkpoint.sh,
  ROADMAP.md. Rename to G-Forge (leave historical retros untouched).
- Count claims vs reality: marketplace.json says "17 agents, 35 skills" but there
  are 37 commands and 35 skill dirs. Reconcile everywhere they appear (marketplace.json,
  README, CHANGELOG, /g-help) against ground truth.
- Docs vs recent behavior: /g-adr is now a 9-step flow (entry triage, capture mode,
  reversibility + premortem); the §A7 context gate now prevents compaction
  (auto-calibrating thresholds, amber active-monitoring, wave /context checks). Check
  every doc that describes these (README, G-RULES, docs/orchestration-patterns.md,
  skill/command descriptions) for stale step numbers / thresholds.
- One voice: descriptions, headers, terminology consistent across commands/, skills/,
  agents/, rules/, docs/.

VERSION: major — bump to 2.0.0 only when the audit is genuinely complete and you'd
stake "production ready" on it. Developer approves the bump.

DONE = repo clean; .gitignore correct; agents<>hooks fully reconciled; zero legacy
naming; all counts/claims true; README v2 approved and named; CHANGELOG + docs in
sync; /g-doctor green. If something can't be made production-ready in scope, say so
plainly with the reason — don't paper over it.
```

---

### M24 — Positioning & Reliability Methodology
**Status:** ✅ Complete
**Version:** v2.0.1 (shipped — this line previously read "v2.1.0 (docs-only; ships with the next release)", written before the cut; the work actually shipped in v2.0.1 per the Version Plan and CHANGELOG. Corrected 2026-08-10.)
**Goal:** State what G-Forge actually is, and define how to prove it.
**Scope:**
- [x] Reposition README + marketplace + plugin descriptions around "educated, enforced project management" (governance layer, not another agent orchestrator) — grounded in the 107-agent landscape research.
- [x] `g-docs/benchmark.md` — reproducible reliability-benchmark methodology (model + G-Forge vs. raw, scored on success rate + the 8 `/g-telemetry` metrics).

**Depends on:** M23. *(Committed on `claude/m23-release-u3rx0d` (`8a20f92`); lands on `main` with the next merge.)*

---

### M27 — Documentation Review Gate (separate from code review)
**Status:** ✅ Complete
**Version:** v2.1.0
**Goal:** Make documentation review its own gate with its own verdict — distinct from code review in trigger, lens, and process. Today doc review is a sub-check of `code-reviewer`; this promotes it to a first-class gate that can run **even when there are no code commits**.
**Scope:**
- [x] New **`doc-reviewer`** agent (read-only: Read/Glob/Grep). Lens: accuracy-vs-code, **currency** (docs that contradict the code), completeness (public exports, README sections, env vars, ADR/CHANGELOG coverage), clarity. Output: BLOCKING / WARNING / PASS → **DOCS READY / DOCS HOLD**. (17 → 18 agents)
- [x] New **`/g-doc-review`** standalone gate skill — own verdict, own cadence. (36 → 37 skills · 37 → 38 commands)
- [x] **File-set-keyed enforcement** *(the hard part)* — gate triggers on the changed file set, not on the presence of a code diff: docs touched (incl. **no-code-commit** changes — wiki, README, ADRs) **|** public/exported surface changed **|** milestone close. Doc-only commits must require a doc-review sentinel (e.g. `.claude/g-forge-docs-approved`); mixed commits require **both** gates; code-only commits are unaffected.
- [x] **Defense-in-depth split** — `code-reviewer` keeps its "missing public-export doc = Major" as a fast **backstop**; `doc-reviewer` owns the deep review. Define precedence so the two don't double-report (backstop defers when the doc gate ran).
- [x] **Blocking on public, advisory on internal** — public-API/exported doc gaps + docs that *contradict code* → DOCS HOLD; internal-only gaps + clarity/terseness → WARNING.
- [x] Clean boundary vs. `/g-docs` (audit+**generate**/write) and `doc-writer` (fills gaps): `/g-doc-review` only **judges & gates** — read-only, may *recommend* `/g-docs`, never writes. Update G-RULES §G to document the two-gate model; update `check-commit.sh` + tests.
- [x] Version bump to v2.1.0 — update plugin.json and marketplace.json version fields in one commit (developer commits at milestone close)

**Tier 3 DoD:** A doc-only change (stale README section + a `g-wiki/` edit) with **no code commit** triggers `/g-doc-review`, the gate blocks the commit until DOCS READY, and a public-export doc gap yields DOCS HOLD; a code+doc PR runs both gates; a code-only PR is untouched by the doc gate (code backstop still catches a missing public-export doc).

**Premortem (per `/g-roadmap` Step 3b):**
- *No-code trigger is the real engineering* — gating doc-only changes means the commit hook must classify the file set (code / doc / mixed), not ask "is this a code commit." Mitigate with an explicit doc-path globset + a `tests/` case per class.
- *Two-sentinel collision* — code and doc approvals can race or misclassify a mixed commit. Mitigate: mixed ⇒ both required; precedence rules; hook tests.
- *Overlap with `/g-docs`* — audit/generate vs. review/gate blur into duplicated logic. Mitigate: `/g-doc-review` is strictly read-only verdict; writing stays in `/g-docs`/`doc-writer`.
- *Backstop double-report* — retained code-reviewer doc check + doc-reviewer flag the same gap, noisy. Mitigate: backstop fires only when the doc gate was skipped.
- *"Stale" is judgment-heavy* — false HOLDs on terse-but-correct docs create friction. Mitigate: block only on contradicts-code or missing-public-surface; clarity = WARNING.

**Depends on:** M23 (review infrastructure). Independent of M24/M25/M26.

**Re-prioritization:** Promoted to the next buildable milestone (v2.2.0) — strongest fit for the M24 governance positioning and actively in design. Sits ahead of the deferred M26. (M25 is compute-gated and runs on a parallel track.)

---

### M28 — g-docs as the canonical home for all G-Forge documents
**Status:** ✅ Built — pending release (v2.2.0)
**Goal:** Make `g-docs/` the single home for every G-Forge document — including the project-tracking files (`ROADMAP.md`, `todo.md`, `todo-done.md`, `milestones/`, `project_brief.md`) that live at the root today — and give `/g-doctor` the checks to keep it that way.
**Scope:**
- [x] **Migrate tracking into `g-docs/`** — `git mv`'d the root tracking paths under `g-docs/`; updated every *live* reference (skills, hooks, rules, agents, commands, templates, README, live `g-docs/` doctrine docs) to the new path. Historical records (retros, archive, CHANGELOG history, the M23 kickoff block) untouched.
- [x] **`/g-init` defines the `.gitignore`** — new Step 5a writes/merges a project `.gitignore` that **ignores** runtime/dev artifacts (OS files, `.env*`, `.worktrees/`, ephemeral `.claude/` state + sentinels + journal, `g-docs/agent-output/`) and **tracks** the software code plus the project-tracking value (`g-docs/` records, `g-docs/ROADMAP.md`, `g-docs/todo.md`, `g-docs/milestones/`, `g-wiki/`, `CLAUDE.md`, `G-RULES.md`) and shared `.claude/` config. Idempotent merge.
- [x] **`/g-doctor` vets the `.gitignore`** — new advisory Check 19: runtime-artifact exclusions present, nothing tracked-by-design ignored (incl. over-broad bare patterns).
- [x] **`/g-doctor` finds + relocates stray g-forge docs** — new advisory Check 20: scans root + non-`g-docs/` doc folders, reports each with a `git mv` fix, offers to move.
- [x] **Confirm every skill writes under `g-docs/`** — audited; canonical `g-docs/` subpath map encoded in `g-rules-I-project-tracking`.
- [x] Sync CHANGELOG + README to the new layout; grep-clean of old root paths. Version bump deferred to release (developer's call).

**Scope boundary:** `CLAUDE.md` (Claude Code reads it at root), `G-RULES.md` (`@`-referenced config), and `CHANGELOG.md`/`README.md`/`LICENSE` stay at the root. Full breakdown in `g-docs/milestones/M28-g-docs-canonical-tracking.md`.

**Depends on:** nothing — touches scaffolding/docs/hooks paths only. Independent of M25/M26.

---

### M-audit-2026-07 — Forge Integrity (technical debt audit)
**Status:** ✅ Complete (W0–W3 + stdin-guard release rider; v2.3.0 released 2026-07-23, `9b2488e`)
**Version:** v2.3.0 (upgraded from the original v2.2.2 patch — developer call, 2026-07-18: W1 ships genuinely new capability, not fixes — the native pre-commit enforcement site, 4 shared libs, the 12-file install set, 187-test suite. **Release pass at close:** ship v2.3.0 with the first README **status strip** — version badge + "What's new" → CHANGELOG.md + "Where this is going" → this roadmap, placed high on the page — and the CHANGELOG `[Unreleased]` → `[2.3.0]` cut. This starts the standing README/CHANGELOG maintenance convention (developer, 2026-07-18): both stay current from every release onward; M41's `/g-release` later bakes the currency check into the release gate itself.)
**Goal:** Resolve the 2026-07-01 three-agent audit findings — enforcement layer provably enforces, drift detectable. Full prioritised tables in `g-docs/milestones/M-audit-2026-07.md`.
**Scope:**
- W0 ✅ quick wins: Windows matcher fail-open, /g-update g-rules sync gap, skill count (merged `4158ffa`)
- W1 (P0): ADR-004 (sentinel↔tree binding) + ADR-005 (worktree enforcement) implementation + finding #21 fold-in — 37 tasks / 8 waves, split into budget-scoped sub-parts (each sized to fit a session's `/g-plan` context-budget gate; sequenced 1→7, run `/g-plan` on each in order):
  - **W1.1 — Shared foundations ✅ Complete (`9688e95`):** `hooks/lib/commit-detect.sh`, `hooks/lib/worktree-resolve.sh`, `/g-review` stamp-format + diff-target flip (tasks 1, 2, 9+10). Reviewed MERGE READY by code-lead (0 critical, 0 major, 4 minor carry-forwards to W1.5). Depends on: —
  - **W1.2 — Commit gate + native pre-commit hook ✅ Complete (`1621a70` + fix commit):** `check-commit.sh` swapped onto shared libs (+ new `hooks/lib/classify-changeset.sh` so the classifier exists once), new native `hooks/pre-commit` (write-tree/HEAD/worktree stamp verify, first-commit fail-toward-deny, sentinel consume), g-doc-review Step 1 diff-target flip (ledger 8d residual). Reviewed MERGE READY by code-lead round 2 after one Major fix (worktree stamp field truncated at first space — spaced Windows paths permanently denied); 2 minors carried to W1.5/W2. Sandbox-proven per Tier 3 DoD (19/19 + 6/6 fixture assertions); live verification stays in W1.7. Depends on: W1.1
  - **W1.3 — Remaining hook worktree integrations ✅ Reviewed MERGE READY (2026-07-16, pending commit):** `post-commit-cleanup.sh`, `observe.sh`, `pre-compact.sh`, `session-start.sh`, `workflow-checkpoint.sh`, `agent-lifecycle.sh` (tasks 11+12, 13+14, 15, 16, 17, 18) — all six resolve primary state from a linked worktree, non-gating per ADR-005, primary paths byte-identical, single-classifier grep 0 across `hooks/`. Reviewed MERGE READY by code-lead (0 critical, 0 major, 4 minor → W1.4/W1.5/W1.6: post-commit-cleanup sed command-field-extraction parity gap, observe.sh sed escaped-quote awareness, W4 guard-idiom variance, W5 duplicate stamp reader). Sandbox-proven per Tier 3 DoD; live verification stays in W1.7. Depends on: W1.1. ⚠ oversized estimate handled without further split
  - **W1.4 — Install wiring + drift detection ✅ Complete (`1fdf016`):** `/g-init`/`/g-update` install/realign the 11-file set (7 hooks + 3 libs into `.claude/hooks/`, native `pre-commit` into the git hooks path via `--git-path hooks` with a `G-Forge commit gate`-marker clobber guard — foreign hooks preserved); `/g-doctor` Check 16 extended to libs + pre-commit (missing/stale/foreign distinguished, no renumbering); post-commit-cleanup sed-tier parity fix pinned by fail-before/pass-after test (tasks 20+21, 22, 19 + W1.3 minor). Reviewed MERGE READY (0c/0M/2m: g-init warning text hardcodes `.git/hooks` path — W1.5; cheat-sheet pre-commit line optional); doc gate DOCS HOLD→READY twice caught count drift (forecast scenario 2 hit: README ×3 + g-update lib-sourcing rows). Suite 61/61. Depends on: W1.2
  - **W1.5 — Foundation + gate tests — SPLIT 2026-07-17 into W1.5a–f** (decomposed to 25 tasks / ~84 est. exchanges, far over one session's budget; approved split below — each slice is its own `/g-plan` run, sized ≤26 est. exchanges; the fail-before → fix → attest sandwich stays intact inside each slice; every test-writer suite is followed by a `g-forge-dev` attestation task per finding #20; standing rule: minors found during W1.5x reviews route to W1.6/W2, never back into a W1.5 slice):
    - **W1.5a — commit-detect suite + hardening** (~24): `tests/test-commit-detect.sh` incl. failing global-flag + failing `env -S` cases and the xargs-malformed-quote pin; fix the global-flag walk (`--no-pager`, `-p`, `--git-dir`, `--work-tree`, `--namespace`) + env-S re-tokenization (clarify-resolution: behavior fix, not comment-only — developer-approved 2026-07-17); attested run. Closes W1.1 minors 2–4. Depends on: —
    - **W1.5b — worktree-resolve + classify-changeset suites** (~23): `tests/test-worktree-resolve.sh` (both public functions, relative/absolute `--git-common-dir`, reject paths) + `tests/test-classify-changeset.sh` (every bucket rule, sourced not re-implemented, single-classifier invariant grep); attested runs. Depends on: —
    - **W1.5c — pre-commit gate fixtures ✅ Complete (2026-07-18):** `g-dev/fixtures/pre-commit-gate-verify.sh` extended 19→35 assertions (doc-only-class pass/deny/consume ×3, conflicted-index write-tree-failure deny with standalone write-tree canary, ambiguous-worktree-resolution deny with resolver-reject canary on the separate-git-dir construction); attested green via g-forge-dev (35/35 fixture + 171/171 suite). Reviewed MERGE READY (0c/0M/0m — zero findings). No hook bugs surfaced. Depends on: —
    - **W1.5d — sentinel-read extraction + install propagation ✅ Complete (2026-07-18):** fail-before/pass-after sandwich closed clean (suite 0/16 exit 1 attested pre-extraction → 16/16 after; full suite 187/187 across 10 files; fixture 35/35 through the real hook). `gf_parse_stamp` moved byte-identical into new `hooks/lib/sentinel-read.sh`, both call sites converted, single-reader invariant now grep-pinned; validator unchanged. 4 install surfaces propagated 11→12 (attested consistent, zero stale/over-bump). Reviewed MERGE READY (0c/0M/2m → W1.6/W2: case-(b) advisory-delta note; wave-agent doc-writer overreach — retro-edited the shipped W1.4 CHANGELOG entry, caught+reverted by HQ, history intact). Depends on: —
    - **W1.5e — skill-layer edits ✅ Complete (2026-07-19):** g-review Step 6 ↔ Step 2 reconciled (`--verify HEAD` + explicit `git add -u` union staging, validated sound against the hook's write-tree re-derivation on all three commit paths) + Step 1 generalized to the project-local test-runner convention (`.claude/agents/<name>-dev.md` delegate + attested-output rule + inline fallback; convention-text-is-generic grep 0); g-init `<git-hooks-dir>` warning fixed; post-commit-cleanup dual-sentinel header fixed (comment-only, 6/6 held). 2 waves / 4 dispatches, all first-attempt; attested 187/187 + 35/35 + 4/4 (HQ-run — g-forge-dev dispatch killed by session limit, W1.5a precedent). Reviewed MERGE READY (0c/0M/1m → W1.6/W2: Step 6 run-on bullet split); DOCS READY (0 blocking). Bonus: CHANGELOG finding-#20 bullet header restored — lost in the W1.5d doc-writer overreach (damage exceeded what the retro recorded). [optional → W2 #18] architecture-rule native-git-hook class note. Depends on: —
    - **W1.5f — guard-idiom normalization + terminal attestation ✅ Complete (2026-07-19):** shared `gf_guard_claude_dir()` added to `hooks/lib/worktree-resolve.sh`; all six non-gating W1.3 hooks normalized to the identical canonical line, conformance-invariant-pinned (worktree suite 25→42); gating pair (`check-commit.sh`/`pre-commit`) deliberately excluded — fail-toward-deny keeps the raw resolver. **Finding #22 fixed in the same pass (pulled forward from W2, developer order):** real payload field `agent_type` + `agent_id` + RESULT token, verified against live-captured payloads, pinned by real-payload fixtures (observe suite 16→22); start/stop imbalance explained (internal agents), session-open multi-fire ruled registration-side (→W1.7 check). Terminal attestation 210/210 + fixture 35/35 + drift 3/3 (HQ-run per W1.5a precedent — 3rd session-limit kill on a long dispatch, this time an implementer, resumed to completion). Reviewed MERGE READY (0c/0M/3m → W1.6/W2: node-tier null→"null" mapping; retired-token scan file-list vs dir; quote-safety test line-2 gap). Depends on: W1.5d, W1.5e
  - **W1.5g — Self-Host Integrity ("the Fix slice" — finding #28 / ADR-008, inserted 2026-07-19):** ends the vN-develops/vN−1-runs dogfood gap for the installable layers. ⚠ ENTRY GATE: verify ADR-008 against the repo from a fresh window BEFORE planning (the ADR was authored in the same session that discovered the gap — clean-slate check per decision hygiene). Task sketch for `/g-plan`, in dependency order: **(1) #27 first — verification before installation:** extend `/g-doctor` Check 16 (or sibling required check) to `.claude/rules/g-rules-*.md` + installed agents vs canonical, missing = drift; fail-before evidence exists live (this machine: 0/10 rules files; `claude-plugin-architect` drifted). Agent surface is three-class (plan review 2026-07-20): profile-copied — hash-comparable vs `profiles/<stack>/agents/`; template-instantiated (e.g. `claude-plugin-implementer` from `templates/stack-implementer.md`) — no byte-canonical, needs a marker/provenance rule or advisory-only; project-local (e.g. `g-forge-dev` per the W1.5e runner convention) — no canonical, excluded. Rules mapping: install + check must share the `rules/g-rules/X-name.md` → `.claude/rules/g-rules-X-name.md` flat rename that `G-RULES.md`'s `@`-includes expect. **(2) Self-host-aware install mechanism:** `/g-update` + `/g-init` detect the-repo-IS-the-plugin-source (`.claude-plugin/plugin.json` at root, `name` match) → source root flips from plugin cache to working tree; consumers structurally unaffected; kills the /g-update-installs-stale-cache footgun. **(3) Routine drift check:** `/g-review` Step 1 runs the installed-copy drift check and reports in the review record (visible, not blocking) — the decay-proof element. **(4) Class-split invariant:** suite assertion that non-gating hooks never exit non-zero (split becomes enforced, not conventional). **(5) Non-gating install EXECUTED via the new mechanism** (6 non-gating hooks + 4 libs + 10 rules files + profile-installed agents — NOT `check-commit.sh`, which is gating class per ADR-008 §2 and stays W1.7 clone-first [corrected from "7 hooks" at plan review 2026-07-20]; refresh the `.claude/` snapshot first per the ADR rollback contract, to a durable location — the 2026-07-19 snapshot sits in a session-scoped temp scratchpad) → verified green by the extended Check 16; payoff: g-rules A–J load for the first time, #22 fix goes live locally (journal finally attributes). **(6) Spike S1 (skills/agents layer, the remaining 38+19 files):** two empirical questions — does a local-marketplace `g-forge` install replace or collide with the GitHub-marketplace install? how do command routers' cache Globs behave with multiple version dirs? Outcome = a decision input, not an install. **NOT in scope: gating hooks** (`check-commit.sh`, native `pre-commit`) — clone-first at the W1.7 checkpoint only. Depends on: W1.5f (shipped). Records: ADR-008, ledger #28, snapshot at scratchpad `claude-install-snapshot-2026-07-19`.
  - **W1.6 — Remaining hook tests + drift test:** tests for W1.3 + W1.4 (tasks 27, 28, 29, 30, 31, 32, 33). Depends on: W1.3, W1.4. ⚠ oversized estimate — expect `/g-plan` to split further
  - **W1.7 — Gating-hook install checkpoint + live verification + ledger close (RESCOPED 2026-07-19 per ADR-008):** clone-first exercise of `check-commit.sh` + native `pre-commit` against real commits in a scratch clone → then live install with the rollback contract active (snapshot refreshed; git-level hatches: `--no-verify`, hook-file delete) → full suite green, real gated commit through primary tree, real gated commit through a linked worktree — the FIRST live run of the stamped-sentinel + native path, now on source-current hooks (non-gating layer already live since W1.5g) → residual checks: session-open multi-fire (registration-side, from #22), journal attribution live-confirmed → M-audit ledger sign-off (HQ-executed, not delegated). Local `/g-update` is no longer a W1.7 task — the non-gating install happens in W1.5g via the new mechanism. Depends on: W1.5a–g, W1.6
- W2 (P1) — planned 2026-07-22 (`g-docs/plans/m-audit-w2-shim-retirement-conformance.md`, 24 tasks / 6 waves / 4-pass split): **finding #19 / ADR-007 implementation** (amend g-skill-validate + g-skill-design + architecture rule commands/-definition FIRST, then delete all 38 command shims; umbrella g-forge.md → bare tokens + roundtable row; teaching-docs-only sweep for retired `/g-<name>` forms + g-help unknown-token catch — both developer-approved 2026-07-22); SKILL.md conformance vs amended rules (argument-hint ×9, Announce ×3, Rules ×3, Steps ×2); architecture-enforcer verdict alignment; architecture rule additions (#18 hook-class note, three-class agent taxonomy, `context:` carve-out) + ADR-008 eager install of the amended rule copy; W1.7-routed residuals (#21 heredoc-content false-positive characterize/fix, journal SessionStart `source` field, PostToolUse-skip-on-error characterization); post-release ADR-007 migration check gets a release-checklist owner line. (#22 shipped in W1.5f — no longer W2 scope.)
- W3 (P2, deferrable): 10 minors

**Depends on:** —

---

### M38 — G-Report (outbound incident/feedback reporter)
**Status:** ⬜ Not started
**Version:** v2.5.0 (re-stamped per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10 — rides the final release; was v2.12.0. The freeze story's maintenance channel — §3a of the communication plan leans on `/g-report` existing. Delivery reconciliation ("hands you a file" vs via-git) is open, decided at this milestone's plan gate — see comms plan §7 item 2.)
**Goal:** Prepare **scrubbed, project-agnostic `.md` incident/feedback reports** destined for the G-Forge author — the outbound surface G-tweak calls, also invocable standalone.
**Scope:**
- Report template(s); project-agnostic scrub mode for sensitive data.
- **Local-`.md`-first floor:** the guaranteed job is to *prepare* the report; the human sends it. **No automation on any user data.**
- Opt-in, consent-gated send (Gmail draft-and-nod / GitHub issue on `onlygian/G-Forge`) reusing existing MCP surfaces + ADR-001 draft-and-nod discipline; degrade gracefully (prepared `.md`, you send it) when no MCP is configured.
- `/g-doctor` leak check — no secrets/tokens/absolute paths in the report.
- Boundary vs the inward reporters (`/g-retro`, `/g-telemetry`, `/g-patterns`): G-Report is strictly **outbound-to-author, incident/feedback only.**

**Depends on:** — (leaf).

**Premortem:**
- *Privacy / exfiltration* (high) → local-first floor + consent-gated send + scrub default + `/g-doctor` check.
- *Transport MCP absent on a surface* (med) → degrade to "prepared `.md`, you send it"; never block.

---

### M40 — Reference Convention (recognize-and-vet external material)
**Status:** ⬜ Not started
**Version:** v2.5.0 (re-stamped per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10 — rides the final release; was v2.14.0. New recognized folder class + classifier arm + doctor advisory + intake questions + optional ADR field.)
**Goal:** Name the one committed-content class the taxonomy can't see — human-curated external material a project builds *against* but never *from* (pinned corpora, design handoffs, spec copies) — stop the commit gate mis-gating it, and let `/g-doctor` vet its provenance discipline. **Recognize-and-vet, never own-and-generate.**

**Origin:** the `reference/` convention already runs in the wild in `keyline` (root `reference/`, `SNAPSHOT.md`/`NOTE.md` provenance notes) and was independently reinvented — divergently — in `omnibook` (same corpus, squatting inside `g-docs/`). Two projects, two placements → no rule exists. Full evidence + options in the reference-folder report (advisory, Francesco / CryusFrey, 2026-07-11).

**Scope (waved):**
- **Wave 1 — Gate safety** (the load-bearing fix; independently shippable):
  - `hooks/check-commit.sh`: new **REFERENCE** classifier class (not DOC — a frozen snapshot has no code-it-describes), **exempt-with-advisory** and **marker-gated** — a `reference/*` path is exempt only if its top-level bundle carries a `SNAPSHOT.md`/`NOTE.md`; unmarked paths fall through to CODE, real code under `reference/` still gates.
  - `rules/g-rules/I-project-tracking.md`: one taxonomy row — root `reference/` = **external + human-ported + frozen** (all three or it doesn't go in), git-tracked, **never machine-written**.
  - `skills/g-init/SKILL.md` Step 5a + `.gitignore`: "never ignore `reference/`".
  - Tests: marked reference-only commit passes without a code sentinel; unmarked `reference/` path still gates; code-extension file under `reference/` still gates.
- **Wave 2 — Visibility & non-contamination:**
  - `skills/g-doctor/SKILL.md` advisory: every top-level bundle carries a note; flag code-extension files under `reference/`; **flag reference-like bundles squatting inside `g-docs/`** (turns omnibook's state into a detectable finding).
  - Scope guard: one "skip `reference/` unless explicitly pointed at it" line in `/g-audit`, `/g-optimize`, `/g-refactor`, and Explore-style deep reads (stops scanners reporting SOLID violations in frozen material — the machine-write corruption vector).
  - Intake: one question in `g-onboard` + `g-kickoff` — *"Any specs, design handoffs, or reference corpora this project builds against?"*
- **Wave 3 — Provenance link:**
  - `skills/g-adr/SKILL.md`: optional `Derives from:` field (path to a `reference/` artifact + snapshot edition) + one back-link confirmation step — closes the ADR↔snapshot loop that already broke once in keyline.
  - `SNAPSHOT.md`/`NOTE.md` template blurb: a **License / permission-to-commit** line (Chromium `README.chromium` precedent) + the **external+human-ported+frozen** inclusion test.

**Explicitly out of scope:** scaffolding an empty `reference/` into every project, a `/g-reference` skill, delta-check machinery, and any default read or write of `reference/` by any skill or agent (YAGNI — keyline ran the whole pattern with zero plugin support).

**Depends on:** M-audit-2026-07 (v2.3.0) — shares `check-commit.sh` + `g-doctor`; land after the enforcement-integrity fixes, not concurrent. Otherwise independent of the memory/salience/multiplayer arc.

**Sequencing note (historical — superseded by ADR-012, rides v2.5.0 per the Version line):** slotted at the tail (v2.12.0 at the time — renumbered back into the 2.x line by the 2026-07-18 restructure; the rebrand lives in M44 (⚠ "capstone" framing retired by ADR-010 — M44 is the rebuild's release vehicle)) originally to avoid renumbering the planned M29→M39 lane (a rationale since overtaken, position unchanged). **Wave 1 is a pull-forward candidate** — the reference-only mis-gate is a live enforcement fail-open, thematically M-audit's own territory, and could ship as a `v2.3.x` patch ahead of the arc if the developer wants the gate honest sooner.

**Premortem:**
- *Gate softening leaks* (med) → REFERENCE exemption becomes a code-smuggling path. Mitigation in scope: marker-gated exemption (unmarked → CODE) + doctor flags code-extension files under `reference/`.
- *Taxonomy scope creep* (med — the named failure mode) → one class implies a doctor check implies g-update handling implies docs. Mitigation: hard-scope to the three waves; Phase-4 primitive stays backlog; no scaffold/skill; re-confirm at each wave close that nothing crept.
- *Name collision on onboarded repos* (low) → `reference/` is a common dir with unrelated semantics. Mitigation: doctor check is **opt-in by marker** (bundle note present, or CLAUDE.md declares the convention); g-onboard asks, never assumes.

**Cross-cutting propagation (G-RULES §B):** the REFERENCE classifier class is a shared primitive the gate, doctor, intake, and scanning skills must all respect — that is why Wave 2's scope-guard line and doctor check are folded *into* this milestone, not left as follow-ups. Run `/g-blast-radius` at Wave 1 close to confirm no reader (skill, hook, or rule) was missed.

---

### M46 — Update Integrity: detect / diagnose / fix split
**Status:** ✅ Complete (shipped v2.4.0, 2026-07-23 — work commit `e3d9d71`; plan `g-docs/plans/m46-update-integrity.md`, forecast `g-docs/forecasts/m46-update-integrity.md`)
**Version:** v2.4.0 (minor — contract change across two skills + one hook; inserted 2026-07-23 ahead of M41, developer call: small, high impact over time — every consumer walks the update path at every release)
**Goal:** The update path can never silently realign a project from a stale plugin cache, and exactly one skill writes while exactly one diagnoses. Three verbs, three owners, one writer: **detect** (`workflow-checkpoint.sh`, direction-aware) → **diagnose** (`/g-doctor`, read-only, recommends the vector) → **fix** (`/g-update`, sole writer, staleness-preflight-guarded).
**Origin:** live G-Cash incident 2026-07-23 — `/g-update` run before the manual `/plugins` cache update "realigned" from the stale 2.2.1 cache while presenting as an update; plus the backwards "update available: 2.3.0 → 2.2.1" checkpoint banner on this repo (check not direction-aware). Full scope, done conditions, and premortem in `g-docs/milestones/M46-update-integrity.md`.
**Scope sketch:** Wave 1 — `/g-update` staleness preflight (stale cache ⇒ stop, write nothing, advise `/plugins` first) + checkpoint semver direction fix (both shipped-bug fixes, test-pinned fail-before/pass-after). Wave 2 — contract split: doctor absorbs version-lag diagnosis (shared compare lib, single implementation), update sheds diagnostic overlap, docs sweep rides.
**Depends on:** — (independent). Ahead of M41: release machinery only compounds traffic on a path that misleads consumers today.

---

### M41 — Release Machinery + README Currency (gated release pipeline)
**Status:** ⬜ Not started
**Version:** v2.5.0 (renumbered 2026-07-23 — M46 Update Integrity inserted ahead at v2.4.0; minor — new release commands + skills + a `/g-doctor` version-consistency check. **RESTRUCTURED 2026-07-18 (developer) — ⚠ the version-arc half of this note is RETIRED by ADR-010 (2026-07-26): the 2.x line ends at v2.5 and M44 is the rebuild's release vehicle, not this arc's capstone; the split-out itself stands. See the ADR-010 stamps on M44 (moved to `g-docs/g-proof-roadmap.md` per ADR-012) and `g-docs/milestones/M41.md`.** Sequenced LAST in the 2.5 build order (ADR-012) — `/g-release` cuts v2.5.0 itself. **Precondition: the session cutting the release reads `g-docs/communication-plan-2.5.md` first** (approved copy, placement rules, open §7 decisions). the G-Proof rebrand + full README restyle were split OUT of this milestone into **M44 — the G-Proof 1.0 capstone, sequenced dead last** — the roadmap runs its whole natural life as G-Forge 2.x, then restarts clean as G-Proof 1.0. What stays here is the release machinery and the standing README/CHANGELOG *currency* convention, which starts even earlier — at the v2.3.0 release (see M-audit's release pass). `g-docs/milestones/M41.md` is the source of truth for `/g-plan`.)
**Goal:** Make cutting a release a **single gated step** instead of a manual, multi-file, error-prone ritual — and make README/CHANGELOG currency a structural property of every release, not a memory-dependent chore. Distribution is straight off `main` (no tags, no CI) — the version field in `plugin.json` **is** the "latest available" signal that `/g-update` and the daily `workflow-checkpoint.sh` check advertise to every installed project — so a wrong or premature bump ships immediately. `/g-release` owns that bump with preconditions and consistency.

**Origin:** observed pain, not hypothetical. Six releases in ~2 weeks (2.0.0→2.2.1), each hand-editing the version in **three places** (`plugin.json`, `marketplace.json`, README counts) + cutting CHANGELOG `[Unreleased]`→dated + (always skipped) tagging. On 2026-07-12 a v2.2.2 bump was made mid-milestone and had to be reverted precisely because nothing gated "is this a coherent, complete release?" — the exact failure `/g-release` prevents. On 2026-07-18 the developer flagged the GitHub README as visibly stale — the currency convention is the structural answer.

**Scope (waved — full task breakdown + done conditions in `g-docs/milestones/M41.md`):**
- **Wave 1 — Release tooling (`/g-changelog` + `/g-release`):** `/g-changelog` **drafts** `[Unreleased]` from the **curated durable record** (milestone-ledger rows, review verdicts, plan done-conditions) — **never raw `git log`** (ledger rows are already human-curated signal; commits are not); Keep-a-Changelog buckets inferred from row type; **draft + human nod** before any write. `/g-release` gates the cut: preconditions (active milestone ✅ closed, full suite green on a **real run** with pasted evidence per finding #20, gate self-hosted clean, no orphaned `[Unreleased]`; refuse on a partial milestone), one-shot version bump across **every** manifest, `[Unreleased]` → dated `## [x.y.z]`, annotated `v{x.y.z}` tag (closes the tagging gap the alveria adopter works around with pinned SHAs). Adds a `/g-doctor` **version-consistency check** (manifests agree; README counts match the `agents/`+`skills/`+`profiles/` inventory) as the standing backstop against a hand bump.
- **Wave 2 — README currency machinery:** `/g-release` verifies the README **status strip** (version badge · "What's new" → CHANGELOG.md · "Where this is going" → ROADMAP — first shipped at v2.3.0 by M-audit's release pass) is current as a release precondition; the lighter `/g-review` Step-6 close-out README-currency mechanism (optional, behavior-change-gated) becomes the reusable per-milestone pass. **The full persuasion-ordered README restyle (gate GIF, positioning narrative, before/after table, FAQ) is NOT here — it ships with M44/G-Proof 1.0 (fork-bound, `g-docs/g-proof-roadmap.md`).**

**Explicitly out of scope:** the G-Proof rename and everything branded (→ M44, fork-bound in `g-docs/g-proof-roadmap.md`); publishing pipelines/CI, signing, changelog generation **from raw commits** (`git log` is never a source), auto-deciding the semver bump (the developer states major/minor/patch; `/g-release` enforces consistency, not the decision), auto-applied README rewrites (always drafted + nodded).

**Depends on:** — (independent; composes with `/g-roadmap`'s milestone close and finding #20's "green run with evidence"). Sequenced **LAST** in the 2.5 build order per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) — `/g-release` cuts v2.5.0 itself, so M47, M48, M51 (absorbing M45), M50, M38, M40, M43, M49 all precede it. *(The earlier "immediately after M-audit, before M42" ordering is retired — M42 is fork-bound.)*

**Premortem:**
- *Becomes a rubber stamp* (med) → if the preconditions are advisory not blocking, it just automates a bad bump. Mitigation: milestone-closed + green-run are hard gates; refuse, don't warn.
- *Version drift across files reappears* (low) → the `/g-doctor` consistency check is the standing backstop even when someone bumps by hand.
- *Tag/manifest divergence* (low) → tag is cut from the same run that writes the manifest; never a separate step.
- *Currency convention decays without enforcement* (med) → that's why the strip check is a `/g-release` precondition, not a habit; the doc gate already covers CHANGELOG on every mixed/doc commit.

**Cross-cutting propagation (G-RULES §B):** the version number is a shared primitive read by `/g-update`, `workflow-checkpoint.sh` (daily update nudge), `/g-doctor`, and the manifests — `/g-release` must be the single writer, and the `/g-doctor` check the single verifier. Run `/g-blast-radius` at Wave 1 close.

---

### M45 — Review Pipeline Rework (code-lead takes seat in HQ)
**Status:** 🔀 Folded into M51 (developer directive 2026-08-20 — the v2.5 release-condition scope change). M51 executes this milestone's core as "M45-lite": review-orchestrator dispatched from `/g-review` at depth 0, the reviewer record-write question settled by directive (scoped-Write pattern, the doc-reviewer/task-decomposer precedent), review scope = diff + blast radius as a hard requirement. The "after M50's contract map" sequencing rationale below is moot — the grants decision the map was meant to inform has been taken. Entry body retained as the design record; the `/g-blast-radius` no-persist producer change and the audit-cadence carve-out transfer to M51's scope.
**Version:** v2.5.0 (re-stamped per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10 — rides the final release; was v2.6.0. `/g-review` restructure + reviewer/agent contract changes; sequenced after M48's cheap hardening of the current pipeline, before M38/M40/M43/M41.)
**Goal:** Replace the monolithic code-lead review (200k+ tokens on a smallish repo, §C context poisoning by the fourth axis) with an HQ-embodied code-lead **role** dispatching scoped parallel reviewer waves and a cheap synthesis step — one 200k monolith becomes ~5 small disposable contexts + findings-only verdict assembly.
**Origin:** developer field feedback at the W3 review gate (2026-07-22), `g-docs/milestones/M36-salience-inputs/2026-07-22-review-cost-scaling-feedback.md`. Root cause confirmed against frontmatter: `code-lead` has no Agent tool; `review-orchestrator` degrades when nested; so the whole review runs in one context. Two live stall incidents on the record-write path (W3 r1, v2.3.0 release code-lead).
**Scope:**
- **Design ADR first** (via `/g-adr`): does `code-lead` survive as an agent or fold into the `/g-review` SKILL (ADR-007 one-thing-one-home spirit suggests fold); verdict/HOLD adjudication ownership; telemetry-profile composition (`cautious`/`defensive` reviewer adds vs partitioned waves); record-write structural answer (Write grant per g-forge-dev precedent vs HQ-writes-records convention — 2 stall occurrences). **Fixed input, not an open question: review scope = the change + its blast radius (developer decision 2026-08-16, scope-review bullet below) — the ADR records the rationale, it does not reopen it.**
- `/g-review` restructure: HQ embodies the code-lead role (same pattern as the PM interface rule); dispatches partitioned reviewer waves (per-cluster: gating libs / hooks / skills-docs / tests, or per-axis) — clusters group the **change-derived file set** (the changes done + their blast radius, per the scope-review bullet below), never a whole-codebase sweep — each wave a small disposable context returning compact findings only; synthesis emits MERGE READY / HOLD off findings blocks — never re-reads the diff.
- **Depth-selection slot** built into the partition step, defaulting to flat-deep — the change-class → depth selector is M37's salience consumer, not built here (M36/M37 fork-bound per ADR-012; M36 names review-depth as a first-consumer contract).
- Attestation seam unchanged: g-forge-dev runner + header-vs-runner reconcile (finding #20 doctrine untouched).
- First slice runs with the monolith path still available as fallback (telemetry `recovery` profile) until the partitioned shape proves verdict-equivalent.
- **Review scope = the change, not the codebase (developer decision 2026-08-16):** every review wave is scoped by the changes done plus their blast radius — `/g-blast-radius` on the changed file set seeds the reviewer partition, and reviewers never sweep unrelated code. Full-codebase audit reviews leave the per-commit pipeline entirely: **proposed** as a dedicated pass every 7–10 milestones (the `/g-audit` vehicle) — offered to the developer at that cadence, never auto-run and never folded into a merge gate. The carve-out is a *class*, not a single case: whole-system coherence checks consumed as review **inputs** are not reviewer waves and sit outside this rule — the T1 transitional rule's `/g-doctor` report is the fork-bound example (T1 activates at the G-Proof fork, `g-docs/transitional-rules.md`; the class is carved out here, the example goes live there). Cadence owner: `/g-review`'s milestone close-out proposes the audit, reading `.claude/milestone-count` plus a last-audit marker written when an audit is accepted — the 7–10 range needs both pieces of state; exact marker file named at M45 plan time.
- **Cross-cutting propagation (§B):** review verdicts feed the sentinels, telemetry counts holds, `/g-afk` auto-reviews — run `/g-blast-radius` at the design wave; the partition step itself now *consumes* `/g-blast-radius` output at every review (new inter-skill dependency — reaches `/g-afk`'s auto-review path too); the partition consumes the blast-radius computation **in-memory — no per-review `g-docs/blast-radius/` record write** (that directory is committed content per G-RULES §I; minting a tracked artifact on every review would collide with the ADR-004 sentinel/write-tree flow) unless the design ADR's record-write question decides otherwise; and `/g-audit` becomes the audit-cadence vehicle; scope incomplete until the completeness gate confirms no consumer missed.
- **Producer change for the in-memory mode (`/g-blast-radius`):** the bullet above fixes a constraint no producer currently satisfies — `skills/g-blast-radius/SKILL.md` Step 7 (`:111`) persists `g-docs/blast-radius/<slug>.md` unconditionally and its `## Rules` output line (`:134`) names that write as the skill's only output, and the completeness guard above is consumer-scoped so it cannot catch a missing *producer* change. M45 must therefore add a **return-only / no-persist invocation mode** to `/g-blast-radius` — amending both the skill body (Step 7) and that `## Rules` line — so the review partition can consume the computation without minting a tracked record per review.

**Depends on:** *(Pre-fold history — superseded by the `Status:` line above; M45 is folded into M51 and the ordinal below no longer applies.)* — (sequenced **fourth** in the 2.5 build order per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), moved from third by the 2026-08-17 M50 amendment: after M48's hardening of the current pipeline **and after M50**, whose agent contract map is a required input to this milestone's design ADR — M45 must decide whether the 11 reviewer agents get scoped Write grants or HQ writes their records (todo row 6), and M50 produces the evidence for that call. Before M38/M40/M43/M41. *The 2026-07-15 "release machinery first" ordering is retired — M41 now cuts the release last.*) Independent of M36/M37, both fork-bound in `g-docs/g-proof-roadmap.md` (ships flat-depth; the depth selector arrives, if ever, with G-Proof's salience layer).

**Premortem:**
- *Synthesis-verdict regression — findings-block verdict misses what a whole-diff read catches* (med) → A/B on the first slice; monolith fallback stays; HOLD adjudication human-visible.
- *Nesting-limit surprises* (low-med) → "directly from a skill in the main session" is explicitly permitted by review-orchestrator's contract; doc-reviewer dispatches from `/g-doc-review` prove the shape.
- *Premature depth-selection* (med) → defaults flat-deep; selector arrives, if ever, with M37 (fork-bound, `g-docs/g-proof-roadmap.md`).

---

### M43 — Operator Controls (/g-settings + inspection cadence)
**Status:** ⬜ Not started (scoped 2026-07-15, developer)
**Version:** v2.5.0 (re-stamped per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10 — rides the final release; was v2.15.0. **Parallel-friendly** — independent of the other 2.5 items, touches only g-init/g-execute skill prose + a new skill. Position is pinned seventh by the ADR-012 build order (M47, M48, M51, M50, M38, M40, **M43**); the old free-floating "pull-forward eligible, like M36" framing is retired — M36 is fork-bound, `g-docs/g-proof-roadmap.md`.)
**Goal:** Give the operator **visibility and control over G-Forge's setup and operative variables**, and give actual programmers (non-vibe-coders) a first-class way to *read the code* at wave boundaries instead of only meeting it at the review verdict.
**Scope (waved):**
- **Wave 1 — `/g-settings`:** one skill that surfaces every G-Forge state variable with current value, owner (which skill/hook writes it), and effect — `integration-tier`, `voice-profile`, `telemetry-profile`, `inspection-cadence` (Wave 2), Roundtable binding, plus read-only diagnostics (`review-holds`, `milestone-count`, `session-prompt-count`, `escalation-log`, `last-trim`). Safe edits routed through it (validated values only); gate-relevant changes (tier) get an explicit are-you-sure with consequences. **Distinct from `/g-doctor`** — doctor validates *health/state*, settings shows and sets *intent*. Registered in the `/g-forge` router.
- **Wave 2 — Inspection cadence (the programmer's wave-boundary hold):** new variable `.claude/inspection-cadence` ∈ `every-wave` | `every-milestone` | `off` (default `off`). `/g-init` gains ONE intake question ("Do you want to personally inspect the code at wave boundaries?" — framed for experienced devs; decline = off, no friction for vibe-coders). `/g-execute`'s wave-completion gate honors it as a **hard hold**: present the wave's diff summary + changed-file list, dispatch nothing further until the developer nods (consistent with gates-gate; an ignorable pause is not an inspection gate). `every-milestone` holds only before the final wave's `/g-review` handoff.
- **Wave 3 — Propagation (G-RULES §B):** `/g-voice` cross-references (voice = how it *talks*, settings = how it *runs* — the intake flows must not duplicate questions); `/g-doctor` gains a check that `inspection-cadence` holds a valid value; **M39 G-tweak reassess hook** — *(narrowed per ADR-012: M39 is fork-bound, so the interview itself cannot ship from this repo. The 2.5 deliverable is only the documented hook point — the cadence variable readable + the reassess contract written down; the Phase A interview that consumes it lands, if ever, in G-Proof.)*

- **Wave 4 — Governance cadence: the health passes become gating, not hopeful** *(added 2026-08-17, developer — "these passes must be mandatory and gating if the full g-forge thing is up, or setup in the upcoming settings")*. New variable `.claude/governance-cadence`, tier-defaulted: **`full` = gating · `balanced` = nudge-only (today's behaviour) · `light` = silent**, overridable per-pass via `/g-settings`. Covers `/g-align`, `/g-telemetry`, `/g-trim`, `/g-doctor` — the passes that report on G-Forge's own health.
  - **Evidence this is needed (2026-08-17 close swarm):** `/g-align` last ran 2026-07-23 — **25 days against a 7-day nudge cadence**, and the nudge had been printing on every prompt the whole time. `/g-telemetry` had not run since 2026-07-23 either, and when it did it found five structural defects in its own gauges (→ M50). A nudge that can be ignored indefinitely is not a control; it is a log line. Both failures share one shape: **an instrument reports clean when it is simply not being run.**
  - **The load-bearing design constraint — gate on RUN-RECENCY, never turn the pass into a blocker.** `/g-align`'s own `## Rules` state *"Advisory only. Never write `.claude/g-forge-approved`, never block a commit, plan, or milestone close."* The obvious implementation — let `/g-align` return a blocking verdict — flips that contract and makes a drift *opinion* into a merge blocker, which also collides with the brief's non-goal *"not a replacement for the developer's judgment."* The correct shape keeps the two separate: **the pass stays advisory and never issues a HOLD; the existing commit gate refuses to open while a required pass is stale.** Staleness is a mechanical, falsifiable fact (`.claude/last-align` vs today); a drift verdict is a judgment. Only the first is safe to gate on.
  - **The stamp layer is a deliverable, not a given — corrected 2026-08-17 after measuring.** An earlier draft of this wave claimed the passes "already write" their stamps and that gating needs "no new bookkeeping." **False.** Exactly **one** stamp file exists on this repo: `.claude/last-align`. `/g-trim` *specifies* `.claude/last-trim` (`skills/g-trim/SKILL.md:58`, "the only file write this skill performs") and `workflow-checkpoint.sh:370` *reads* it — **but the file has never existed**, because `/g-trim` has never completed a run here. Consequence: its weekly nudge has fired on **every prompt, indefinitely**, with no reachable state that clears it. Wave 4 therefore owns defining and writing the full stamp set before anything can gate on it.
  - **A nudge that can never clear is worse than no nudge** — it trains the operator to filter the whole checkpoint block, which is the same alarm-fatigue failure already recorded against the forecast miss-risk figure. Every cadence pass must have a stamp its own completion writes, and a nudge that goes quiet when it does.
  - **Per-pass cadence decision, made explicitly rather than by default** — the four layers this milestone must cover, with today's measured state: **eval** (`/g-align` ✓ stamped · `/g-telemetry` no stamp · `/g-doctor` no stamp · `/g-blast-radius` **2 runs total** despite being a named core instrument — now structurally required by M51 (inherited from folded M45) and M50's §B checks, so the fix is upstream) · **intelligence** (`/g-patterns` no cadence · `/g-forecast` event-driven at plan approval, correctly not clock-driven · **`/g-identity` has NEVER run — no `g-docs/identity.md` exists**, a shipped capability that is dead in practice: wire it to a cadence or record it as on-demand, but decide) · **self-repair** (`/g-update` event-driven ✓ · `/g-trim` broken as above) · **gates** (`/g-review`, `/g-doc-review` already hard — unchanged).
  - Two classes, and they must not be conflated: **clock-gated** passes (stale stamp blocks) versus **event-gated** passes (`/g-forecast` at plan approval, `/g-blast-radius` at a cross-cutting change, `/g-retro` at the §A7 red gate). Putting an event-driven pass on a clock is how you manufacture the next permanent nudge.
  - **Needs an ADR** (`/g-adr`) before build: it changes what the commit gate blocks on, which is the project's single load-bearing enforcement point and the brief's declared differentiator. Not a quiet scope addition.

**Premortem (sketch):**
- *A stale-pass gate becomes the new `--no-verify` magnet* (med, added 2026-08-17) — a gate that fires on cadence rather than on evidence of a problem is the kind developers learn to route around, and G-RULES already forbids bypassing the commit gate. → Default the staleness windows generously and let `/g-settings` widen them; the bypass posture stays the recorded one (`/g-tier light` is the supported off switch, per the brief's 2026-07-26 override), never `--no-verify`.
- *Settings sprawl* (med) — /g-settings becomes a junk drawer as every future milestone adds variables. → Registry table in the skill is THE inventory; adding a variable without registering it = a `/g-doctor` advisory (mirrors finding #19's single-source lesson).
- *Hold fatigue* (med) — `every-wave` on a 7-wave milestone = 7 interrupts; the developer stops reading and nods blind. → G-tweak reassess hook exists precisely for this; the hold prompt shows diff *size* so the developer can calibrate; switching cadence is one /g-settings command away.
- *Second intake question creep on g-init* (low) — init interview bloats one question at a time (the kickoff-friction premortem lesson from M42, fork-bound per ADR-012 — same failure). → Hard rule: ONE question, recommended default, decline = silent off.

**Depends on:** — (standalone. The M39 reassess hook is fork-bound per ADR-012 and cannot activate from this repo — Wave 3's deliverable narrows to the documented hook point above.)

---

### M47 — Planning-Pipeline Honesty (decomposer + calibration)
**Status:** ✅ Complete (shipped 2026-08-12 — merge `6590b60`, 4-round review + parallel cautious reviewer, MERGE READY r4; suite 564/564 attested)
**Version:** v2.5.0 (rides the freeze release — patch-class process fixes, no separate bump)
**Goal:** Plans sized and priced so their numbers get believed and their tasks match how the work actually executes.
**Scope:**
- `task-decomposer`: sizing rule — never split a serial single-file chain across agents (evidence: 2026-07-28 session, 11 tasks collapsed to 1 by wave-planner)
- Reliable result return across the decomposer seam (evidence: same session, empty final message needed a resume to recover the task list)
- Forecast miss-risk calibration derived from recorded forecasts-vs-outcomes, not a static constant (standing complaint: number reads high/static, gets ignored)
- `/g-plan` Step 3c: review-chain cost term + split-depth cap (field-reported by keyline, `g-docs/field-reports/2026-08-10-keyline-francesco.md` §2 — review chain ran 3–10x the implementation estimate and drove a 3-level-deep milestone re-split; their flat-tax constant gets re-derived from both corpora, not copied)

**Premortem:**
- *Over-correction — decomposer under-splits into context-blowing mega-tasks* (med) → sizing rule keyed on file-seriality, not task count; validate against the recorded 11→1 case.
- *Seam contract change ripples to wave-planner / g-execute consumers* (med) → additive output contract only; blast-radius the seam at plan time.
- *Calibration lands but the number still gets ignored* (med) → done condition = number moves with recorded evidence, not another constant.

**Depends on:** —

---

### M48 — Review-Pipeline Hardening (fix-loop killers)
**Status:** 🔄 In progress (M48a ✅ shipped `df2ca1b` 2026-08-20; M48b ✅ shipped `72fcfd3` 2026-08-21; M48c ✅ this commit — 5-round review: r3 HOLD 0C/11M, r4 HOLD 0C/3M, r5 MERGE READY; M48d next) — **split into M48a–M48e on 2026-08-19** (developer decision at `/g-plan`'s budget gate: the monolithic plan estimated ~74 exchanges against a ~33-exchange session budget; split along the wave-dependency structure so each sub fits one session with no mid-plan handoff, each closing through its own review + commit. Execution order is fixed a→e — b's lib overrides must exist before c wires them into fixtures. All subs ride v2.5.0; the split is sequencing only, no scope change. Sub-milestone task detail below is the durable record — the per-sub plan files in `g-docs/plans/` are gitignored scratch.)

**M48a — Doc-gate teeth & suite runner** ✅ `df2ca1b` (2026-08-20; 4-round code review 30→9→4→0 + 4-round doc gate; suite 575/19 attested) · grep-the-literal-fact sweep + round-3 consolidation note as a required `/g-doc-review` step (doc-reviewer executes the sweep itself, in Step 2, under its own record-scoped `Write` grant, recording evidence in its per-run record at `g-docs/agent-output/review/doc-reviewer-[YYYY-MM-DD]-[request-slug]-r[N].md`; Step 2b is HQ's check that the record carries it, not the sweep itself; a surviving stale copy or a missing sweep → DOCS HOLD) · doc-reviewer volatile-fact heuristic (in-flight process counts in a reviewed doc are a smell; ADR-013 remedy is pin-with-a-test-first or omit; pointer language to the owning record is this contract's own addition) · falsifiability comment rule in `rules/g-rules/H-testing.md` (applies in projects with an executable test suite; shipped source only) · `tests/run-all.sh` (derives suite set from the `tests/test-*.sh` glob per ADR-013, front-loads the two suites that would otherwise run last in glob order so the big suites don't tail the run, parallelism deliberately off, must prove identical totals vs serial).

**M48b — Lib overrides & first test fixes** ⬜ · env-injectable timeout override in `hooks/lib/stdin-read.sh` (unset = byte-identical; production call sites untouched) · fast test-time guard-window constant in `tests/lib/timing-bounds.sh` (additive, WHY comment, never replaces `GF_HOOK_STDIN_GUARD_MS`) · audit-7 F4: `test-g-doctor-drift.sh` derives the hash-cascade snippets from shipped `skills/g-doctor/SKILL.md` at runtime instead of hand-copied mimics (cksum in the wave; sha256sum/shasum extended in the fix round) · audit-7 H3+H9: grep-pin the g-init settings.json template matchers and `hooks/hooks.json` = `{"hooks": {}}` in `test-lib-install-completeness.sh`.

**M48c — Code-gate teeth & new suites** ✅ · grep-the-literal-fact sweep + round-3 note as a required `/g-review` step (recorded in code-lead's review record) · wire the fast override into the abandoned-stdin fixtures (`test-class-split-invariant.sh` six-hook loop, `test-check-commit.sh` cases 23/25; guard-deleted probe must still go RED; re-sum counts from Results lines) · revalidate `GF_FAST_STDIN_GUARD_MS` (`tests/lib/timing-bounds.sh`) against real override-wired runs before any suite depends on it — the value is validated 2026-08-21 and raised to 30000 on loaded-machine evidence (`CHANGELOG.md:36`, `tests/lib/timing-bounds.sh:62-72`) and this milestone delivered that revalidation (both refs now record it) · audit-7 H4: version-agreement suite (`plugin.json` vs `marketplace.json`) · audit-7 H5: router-token ↔ `skills/` dir parity suite (derive-and-compare both sets at runtime, never a typed list).

**M48d — Direct runner & the big hole** ⬜ · `/g-review` Step 1 runs the deterministic suite directly via `tests/run-all.sh` (drop the `*-dev.md` preference for the suite run; keep it only for judgment-needing gate fixtures) · audit-7 H1: `tests/test-pre-commit.sh` — first-ever execution coverage of the native gate (native git-hook contract: no stdin JSON, deny = stderr + exit 1; sentinel 3-field validation, worktree binding, HEAD staleness, valid pass-through) · un-inert `test-workflow-checkpoint.sh` §12/§13 (real assertions, probe-verified RED with the code deleted).

**M48e — Tier cases & heredoc fix** ⬜ · audit-7 H2: tier cases in `test-check-commit.sh` (light gate-off, balanced gate-on, garbage value → gate-on) · CANDIDATE (todo task 10, confirm at this sub's plan approval): heredoc-body pathspec misclassification fix in `hooks/lib/commit-detect.sh` `extract_pathspecs` + regression cases in `test-commit-detect.sh` — sole consumer is `hooks/check-commit.sh:222`; `hooks/pre-commit` verified unaffected (classifies from `git diff --cached --name-only` only, grep-confirmed 2026-08-19).

**Version:** v2.5.0 (rides the freeze release)
**Goal:** A fix pass can't silently mint the next defect. Field-proven twice independently: keyline's flagship incident (~20 review dispatches for one milestone, `g-docs/field-reports/2026-08-10-keyline-francesco.md` §1) and this repo's own `ec9bf8a` pass (9 rounds, 7 found defects, 2 after clean verdicts).
**Scope:**
- Grep-the-literal-fact sweep as a **required** `/g-review` + `/g-doc-review` step before accepting a fix as closing a finding — sweep output recorded in the review record, checkable, not advisory
- Round-3-same-finding-class consolidation checkpoint ("round 3 on this class — consolidate the repeated facts into one source of truth instead of patching") — surfaced note, never a block
- `doc-reviewer` volatile-fact heuristic: claims about in-flight process counts (round counts, commits-ahead) inside a document under review are a smell — ADR-013 remedy is pin-with-a-test-first or omit; pointer language to the owning record is this contract's own addition
- Falsifiability comment rule for guard/negative tests (G-RULES §H, scoped to projects with an executable test suite): guard neutered in a scratch copy, test confirmed red, copy discarded — nothing in the production tree is ever mutated, so there is no restore step — recorded as an in-file one-line comment
- **`/g-review` Step 1 must not route a deterministic suite run through an agent.** Step 1 currently prefers a `.claude/agents/*-dev.md` runner over the inline path. `for f in tests/test-*.sh; do bash "$f"; done` needs zero judgment, so the agent buys nothing and costs the progress signal: observed 2026-08-16 as a 74-minute opaque dispatch with no way to tell running from hung, plus a confabulated total (todo task 9). Direct execution yields the identical runner output in a pollable file and satisfies finding #20 *better*, since the doctrine is "a claim with no output is unverified" and first-hand output outranks relayed output. Keep the `*-dev.md` preference for project-specific gate fixtures that genuinely need judgment; drop it for the suite run
- **Suite wall-clock is a review-gate cost, not just a test concern.** Three compounding causes measured 2026-08-16 on this repo: roughly 9 minutes of deliberate waiting on abandoned-stdin guard tests (`test-class-split-invariant.sh:124` looping `< <(sleep 300)` over six hooks — measured pre-override at 65000ms bounds; since the M48c wiring five run at the ~2s override — plus `test-check-commit.sh:344,390` and `test-stdin-read.sh:83`); MSYS fork overhead across 564 assertions (suite population measured at that date; current population is 592); and 18 independent suites (also measured at that date; current count is 21) run serially — the hint front-loads the two suites that would otherwise run last in glob order (test-workflow-checkpoint.sh 81, test-worktree-resolve.sh 42) so they don't tail the run. Reordering or parallelising the suites cannot reduce total serial runtime — only perceived progress; that was a plan-time arithmetic error, not a fix (`g-docs/retros/2026-08-19-m48-split-and-m48a-wave.md:22`). The real wall-clock levers are the M1 output-capture fix (landed in M48a's fix round) and M48b/c's guard-window overrides so tests prove the timeout at 2s while production keeps 65s. **Never shrink the constants themselves** — the same architecture note records `GUARD_WINDOW_MS` being widened 8000→20000 because real MSYS overhead breached a tighter bound. Related: todo task 7 already carries the `< <(sleep 300)` sleeper-reaping rider
- **Carried from the 2026-08-11 whole-system audit (todo row 7), assigned here 2026-08-17:** audit-7 F4 + H2–H5 + H9 — fixture drift and the coverage holes below `hooks/pre-commit`. Same family as todo row 5's Wave C test-teeth rider, which already folds into this milestone; keeping them together avoids two passes over the same fixtures

**Premortem:**
- *Regression in the gate degrades every future review* (med) → additive steps only; exercised on a scratch changeset before merge; `test-review-severity` stays green.
- *New steps decay into skipped prose — the vigilance trap this milestone fixes* (med) → grep-sweep output must appear in the review record; absence is itself a findable gap.
- *Rule bloat for no-test projects* (low) → falsifiability rule scoped to projects with an executable test suite.

**Depends on:** — (sequenced after M47; no hard dependency. Both fed the whole-system audit's scope; the audit ran 2026-08-11 — its Wave C findings fold back into M48's plan as todo task 5. Relationship to M51: M48 is the cheap field-proven hardening of the *current* pipeline, landing before M51's panel wiring rebuilds it — M51 absorbs M45's structural rework — per the ADR-012 build order.)

---

### M50 — Eval-Chain Integrity (instruments measure what they claim)
**Status:** ⬜ Not started (folded into 2.5 by developer decision 2026-08-17 at `/g-intake` triage — amends the ADR-012 milestone list a second time. **Scope amended 2026-08-17** at a second `/g-intake`: two state-surface instrument defects absorbed — see the two bullets below — with the general state-lifecycle capability declined to `g-docs/g-proof-roadmap.md`. No version, sequence, or dependency change, so ADR-012 is untouched; premortem extended in place rather than re-running `/g-roadmap`'s four phases for two scope bullets)
**Version:** v2.5.0 (rides the freeze release)
**Goal:** The instruments G-Forge governs itself with measure what they claim, and every agent's declared contract matches what its body actually instructs. Triggered by the 2026-08-17 `/g-telemetry` run, which produced a clean-looking report while four of its own gauges were structurally incapable of registering the failures this project keeps recording.
**Origin:** developer intake 2026-08-17 — "telemetry and blast-radius are probably the most important tools in the eval chain." Full scope in 2.5 by explicit developer override of a proposed 2.5/G-Proof split: 2.5 is a **maintained freeze with real users**, so it must do what it says at the best of its capabilities regardless of what the rebuild replaces later.
**Scope:**
- **Telemetry spec gets a ship vehicle.** `g-docs/telemetry-metrics.md` is `/g-telemetry`'s declared authoritative source and its Rules forbid inlining the formulas — yet **no skill or hook creates the file**. `/g-init`'s g-docs scaffold list (`skills/g-init/SKILL.md:169`) omits it, so on any consumer project `/g-telemetry` Step 1 reads a missing file and Step 3 has no definitions. This repo only works because the file was hand-written here. The one user-facing defect in this milestone
- **§1 hallucination Source labels match the language retros actually use.** The spec matches `hallucinated-`/`nonexistent-`/`wrong-api`/`bad-citation` — zero hits across 22 retros, while the project has recorded **four** attested-total confabulations (todo row 9, latest 2026-08-16). Retros write "confabulation", "invented a number", "fabricated". The gauge reads 0% during an active streak
- **§4 rework reset policy — unlock the self-sustaining ⚠.** `review_holds` resets only on a `stable` profile; `stable` requires zero ⚠; the rework metric guarantees a ⚠ at 24 holds / 31 `feat:` commits. It can never recover. **Pulled forward ahead of M48** — `cautious` currently adds +1 reviewer to every review off this gauge, so M48's own reviews pay for it
- **Coverage sourced from ground truth.** Step 5b counts retro *prose*; `.claude/journal/` records every dispatch by name (324 agent events on 2026-08-16 alone). Proof of the defect: `g-forge:code-reviewer start a8e145c2` is journalled for 2026-08-16 while coverage scores `code-reviewer` as `never`. Journal primary, retros fallback
- **Agent-count consumers derived, never typed** — governed by [ADR-013](decisions/013-derive-in-consumers-keep-counts-in-prose.md) (two rules: consumers derive from the directory; documents keep concrete numbers). Live defect: `/g-telemetry`'s coverage table types 17 agent names against 19 in `agents/` (`doc-reviewer`, `feature-implementer` uncountable), and the committed 2026-08-17 report shipped blind to `doc-reviewer`. Same class, latent: `/g-doctor`'s typed hook lists, `/g-specialize`'s typed stack lists (its frontmatter list's only consumer should be a `[ -d profiles/<arg> ]` test — delete the list). Done condition is a **test that fails when any typed list diverges from its directory**, never a corrected list.
  - **v2.5 scope fence:** fix the known consumers only; parity assertions land in their own suite file so a red parity suite can't destabilise the 19 green ones.
  - **End-to-end done condition:** add an agent, run `/g-telemetry`, confirm the persisted report counts it — the one check a static test can't make.
- **Carried from the 2026-08-11 whole-system audit (todo row 7), same defect classes:** `/g-doctor` Check 16's typed 7-hook list (audit-1 #5) · `/g-specialize`'s three hand-typed stack enumerations · the 8 state surfaces bypassing `GF_CLAUDE_DIR`/ADR-005 resolution (audit-3 W3) · the ADR-005 keying follow-up back-stamp (audit-6 N1) · §I's "three hook scripts" under-describing the two-sentinel gate (audit-1 #4) · audit-5 F-3–F-6 dead-pointer/state items
- **Unbounded state accumulation has already killed a decision path — `/g-resume` Step 0e's fallback is dead code.** Added 2026-08-17 at `/g-intake` triage. Nothing in `hooks/` or `skills/` ever deletes a `.claude/session-prompt-count.*` file — verified by grep; only `tests/` deletes, and it `cd`s to a fixture first (`tests/test-workflow-checkpoint.sh:651`), so the suite is clean. **87 files match `session-prompt-count*` as of 2026-08-17** — 80 UUID-keyed session counters accumulated since 2026-07-22, plus the legacy bare file and six ad-hoc leftovers from 2026-07-26 manual verification (`.test`/`.verify`/`.verify2`/`.v3`/`.v4`/`.v5`) sitting in live `.claude/`. *The set definition matters and the number is live: Step 0e enumerates the **whole glob**, so 87 is the figure that governs it, while the UUID subset is the one that grows — by one per session, and it grew from 79 to 80 during this triage's own doc review. Both numbers are stamped rather than replaced with a pointer, per the prose rule in the derive-don't-type boundary below; the currency check is that they are re-countable by set in one command.* Step 0e's session-id-unknowable branch requires **exactly one** candidate and enumerates all 87, so it returns `session phase unknown` unconditionally and the session-start fast-forward can never run on that path — on any repo older than about a week. The bytes are irrelevant (~3 KB); the defect is a shipped branch that cannot execute. Same accumulation class, unfixed and unmeasured: `g-forge-agent-log.jsonl` (277 KB, no rotation) · `.claude/journal/` (451 KB / 32 files) · `g-docs/agent-output/` (3.4 MB / 334 files). **Done condition is a test that fails when the 0e fallback cannot resolve against a realistic counter population — never a one-off deletion of the accumulated files.** The fix is deliberately not pre-decided: reaping the surface and relaxing 0e's rule are both legitimate, and a reaper is **concurrency-sensitive on the ADR-005 axis** — deleting a live sibling session's counter is precisely the hazard 0e's conservative branch exists to prevent, so it lands with the `GF_CLAUDE_DIR` rider above, not separately. **Scope boundary:** the general "G-Forge cleans up after itself" lifecycle capability is *not* in 2.5 — it traces to no Goal or roadmap item, and went to `g-docs/g-proof-roadmap.md` at the same triage. What is in scope here is only the two instruments that read false
- **`.claude/compact-state.md` is never cleaned up, so a stale snapshot is indistinguishable from a fresh one.** Added 2026-08-17 at the same triage, and **demonstrated live in the session that found it**: a 2026-08-16T21:38Z snapshot was read as evidence that the 2026-08-17 pass had compacted, and the wrong answer was given to the developer before `session-compaction-count` and `context-threshold-offset` mtimes disproved it. `pre-compact.sh` writes all three within ~3 s (`hooks/pre-compact.sh:47-64,83`), so the corroborating evidence exists — but nothing makes a consumer check it, and the snapshot itself carries no currency signal a reader is obliged to consult. Done condition is a consumer that **cannot** read a stale snapshot as current — the freshness key checked mechanically, not a convention that readers are trusted to follow
- **Why these two are absorbed and the rest is not** (against this milestone's own leftovers-bucket premortem): both are gauges structurally incapable of registering what they claim — the identical class as §1's hallucination labels scoring 0% during an active confabulation streak and coverage scoring `code-reviewer` as `never` while the journal records its dispatch. The remaining accumulation surfaces above are *housekeeping* and are named here as measured context only; they do not become M50 scope unless they are found to blind an instrument
- **Agent contract map:** frontmatter tool grants vs what each body instructs, across all 19 agents; the dispatch graph across the 17 skills that dispatch; nesting constraints (`review-orchestrator` must run as root session agent). Informs M51 item 4's record-write decision, which covers the same question for the reviewer agents (todo row 6) — settled by developer directive rather than a separate design ADR; the M45 design-ADR path this bullet originally named is retired, folded into M51. **Two known instances recovered from `g-docs/agent-output/audit/audit-4-structure.md` on 2026-08-17** — W3: `review-orchestrator.md:22` holds `Agent(…doc-writer)` and dispatches it to *write* docs mid-review, contradicting G-RULES §G's validate-don't-generate split and "review agents output findings, never fixes" · W4: five agents (`architecture-enforcer`, `code-lead`, `code-reviewer`, `doc-reviewer`, `security-auditor`) pin `model: opus` with no in-file justification — §A1 sanctions pinned per-agent tiers, so the defect is the missing WHY, not the pin
- **Firing audit:** 4 skills declaring auto-trigger conditions · 24 emit points in `workflow-checkpoint.sh` · 6 registered hook events across 7 hooks + 6 libs · tier gating interacting with all of it. Enumerate, justify each, tighten
- **Per-prompt payload is a context cost, not a dollar cost — measured 2026-08-17.** `workflow-checkpoint.sh` emits **3,482 B ≈ 870 tokens on every prompt**, of which the `Active context:` line alone is **2,832 B ≈ 700 tokens**. A 40-prompt session therefore accumulates roughly **35,000 tokens** of near-duplicate banner text in the window. Cheap in dollars (it appends after the cached prefix, so it reads at ~0.1× input price) and expensive in exactly the resource §A7 exists to protect — **the hook is consuming the context budget it was built to defend.** Options to weigh: emit the full `Active context:` only at session start and a short digest thereafter · gate the heavy lines behind a change-detector · move the block behind an on-demand `/g-status`. Decide with a measurement, not a guess.
- **Explicitly NOT in scope — prompt-cache tuning.** G-Forge is a Claude Code plugin and never assembles the API request: it cannot set `cache_control` breakpoints, choose a 5m/1h TTL, or order the prefix. What it *does* control is what enters the prefix and how stable that is. Verified benign: `CLAUDE.md` + its 14 `@`-imports total **80 KB ≈ 20,000 tokens**, stable and front-loaded, which is the cache-friendly shape already — shrinking it via `/g-trim` is a token-weight decision, not a caching fix. **Open question, deliberately unresolved:** whether editing a rule file mid-session (`/g-update`, `/g-patterns apply`) invalidates the in-context copy depends on whether Claude Code re-reads `CLAUDE.md` per turn — harness behaviour we have not established. Establish it before acting on it.
- **Cross-cutting propagation (§B):** changing what fires automatically is a shared primitive — `/g-blast-radius` runs at the design wave **scoped to the firing surface**; the done condition is incomplete until architecture-review confirms no touchpoint was missed

**Depends on:** M48 and M51 (sequenced **fourth** in the 2.5 build order per the 2026-08-20 M51 insertion — M47 ✅, then M48's hardening, then M51's panel wiring, then M50; measuring the review pipeline before M51 rewires it would measure the wrong machine. M45 is folded into M51). **Explicitly excludes — owned elsewhere, verified 2026-08-17 against both milestone entries:** the `/g-blast-radius` in-memory producer change (`skills/g-blast-radius/SKILL.md:111`) and review-scoping-by-changed-files → **M51** (inherited from folded M45); the "don't route a deterministic suite run through an agent" fix and the suite wall-clock work → **M48**. Scoping this milestone from the developer's phrasing alone would have duplicated all three.
**Feeds:** M51 item 4's record-write decision (todo row 6) — supersedes the M45 reviewer record-write design ADR previously named here; M45 is folded into M51.

**Premortem:**
- *Scope collides with M45/M48 and work is done twice* (**high** — nearly happened during this milestone's own intake; M45 is now folded into M51) → exclusion boundary written into `Depends on:` above, re-verified against both entries before any `/g-plan`.
- *"Audit" milestone goes unbounded* (med — M-audit-2026-07's remainder is **still** carried as todo rows 5 and 7, a year on) → M50 ships **fixes, not reports**. No `g-docs/audits/` deliverable. Every finding either lands a fix in-milestone or becomes a named carry-row with an owning milestone. Absorbed audit items are limited to those matching a defect class M50 is already fixing — this is not a leftovers bucket.
- *A state reaper deletes a live sibling session's file* (**high**, added with the 2026-08-17 scope amendment — it is the exact hazard `/g-resume` Step 0e's conservative branch was written to avoid, so building the fix carelessly would destroy the property that exposed the bug) → the reaper lands **with** the `GF_CLAUDE_DIR`/ADR-005 rider, never as an independent pass; age-based deletion only, with the liveness rule stated before any code; exercised against a multi-session fixture, not a single-session one.
- *The two absorbed state items pull the whole cleanliness backlog in behind them* (med — the leftovers-bucket failure this milestone's premortem already names) → the scope bullet states the boundary explicitly and the general lifecycle capability is recorded in `g-docs/g-proof-roadmap.md`; a housekeeping surface enters M50 only on evidence that it blinds an instrument.
- *The derive-don't-type fix reintroduces a typed list* (med — **five** prior recurrences: `/g-doctor` Check 16, `/g-telemetry`'s 18-name list, its 17-row coverage table, `/g-specialize`'s three stack enumerations, and the founding `/g-init` bug) → every fix pinned by a test that fails on divergence, never by a corrected list.

---

### M49 — Devil's-Advocate Agent (internal adversarial pattern review)
**Status:** ⬜ Not started (folded into 2.5 by developer decision 2026-08-14 at /g-patterns lifecycle intake — amends the ADR-012 milestone list)
**Version:** v2.5.0 (rides the freeze release)
**Goal:** The adversarial seat in the `/g-patterns` resolve phase gets an internal occupant. The two-phase pattern lifecycle (shipping ahead of this milestone as a standalone 2.5 rider) reads external counter-reports from `g-docs/inbox/adversarial/` — currently other models via n8n automation, advisory-only. This milestone adds a G-Forge reviewer agent that argues *against* each PENDING pattern resolution from inside the repo, with full source access the external models deliberately don't get.
**Scope:**
- New reviewer-class agent `devils-advocate` (Read/Glob/Grep, findings only) — receives the PENDING resolutions from the saved pattern report and argues against each: is the pattern real, is the proposed rule edit the right fix, what does the edit break
- `/g-patterns` resolve phase dispatches it alongside the external-inbox read; both feed the same triage — internal findings and external counter-reports are suggestions, the human weighs them, neither blocks
- Registration ride-alongs: README agent count, doctor drift-class listing, `test-review-severity` untouched (no shared-ladder verdict — findings list only)

**Premortem:**
- *Agent anchors on the report and rubber-stamps* (med) → prompt contract is refute-first: it must state the strongest case against each resolution before any agreement; agreement without an attempted refutation is a malformed report.
- *Redundant with the external inbox, double noise* (med) → different evidence classes: external models see only the principle-level report; the internal agent sees source. Findings that merely repeat an external counter-report are deduped in triage.
- *Scope creep into a general review agent* (low) → scoped to pattern resolutions only; `/g-review` pipeline untouched.

**Depends on:** the `/g-patterns` two-phase lifecycle rider (report persistence + inbox read) being merged first.

---

### M51 — Release Reliability (M45-lite)
**Status:** ⬜ Not started (added 2026-08-20 by developer directive — the v2.5 release-condition scope change; amends the ADR-012 milestone list a third time. Sequenced **third** in the build order: after the M48 family, before M50, absorbing M45. Evidence base: two 2026-08-20 external audit reports — gaps-and-fixes (A1–A10, B1–B12) and the benchmark pilot report; every acted-on claim re-verified against the current tree per ADR-013 at intake: code-lead holds no Agent grant, the jq rc-only check at `hooks/agent-lifecycle.sh:89-91` is live, `g-docs/g-proof-roadmap.md` is gitignored at `.gitignore:67`.)
**Version:** v2.5.0 (rides the freeze release — this milestone *defines* its bar: "a reliable and very usable harness" is the release condition, not a doc patch)
**Goal:** v2.5 ships reliable and very usable: the review panel actually runs (MERGE READY has been solo-review since May — `daf15e3` removed code-lead's Agent grant, `51e5220` re-added AXES language without it), the invariants are machine-enforced, and the mechanisms the rebuild map already sanctions as DIES are deleted rather than polished.
**Scope (dependency order, per the 2026-08-20 directive):**

*RELIABLE*
- **1 · Panel wiring (M45-lite)** — developer decision 2026-08-20: wire it, don't doc-fix it. `review-orchestrator` dispatched from `/g-review` at depth 0; strip the stale AXES/dispatch language from `code-lead` and `g-review`; add a test that any agent named as a dispatcher holds the Agent grant for what it dispatches. Design input from claude-code-review-council (same panel shape, top-level dispatch), adopting: synthesis verifies every cited file:line by opening the file and drops unverifiable findings · findings tagged with source reviewer(s), cross-reviewer agreement raised as confidence, disagreements surfaced not blended · a reviewer that fails to run is NAMED as not-run in the report (a review is "looked and found nothing", never silently "never looked") · one panel seat reviews the diff blind to plan/spec context. Explicitly rejected: external-CLI multi-model seats (breaks zero-dependency install; optional adapter post-2.5 at most) · resuming reviewers to defend findings (violates §C single-use — dispatch a fresh verifier instead). Severity contract unchanged (`test-review-severity.sh` stays authoritative; no P0–P3 ladder). Done condition inherited from folded-M45's A/B obligation (ADR-012 Assumptions): the wired panel demonstrates verdict-equivalence against the monolith path on a real changeset — or records the trade explicitly — before the 2.5 "same verdict, a fraction of the cost" claim publishes. Inherits from folded M45: the `/g-blast-radius` return-only/no-persist invocation mode (producer change, `skills/g-blast-radius/SKILL.md` Step 7 + Rules line) and the audit-cadence carve-out class.
- **2 · Gate execution coverage** — owned by **M48d**, not restated here; CI (item 3) runs it once landed.
- **3 · CI** — GitHub Actions running all suites + the gate fixture on push/PR (gaps A1: the founding doctrine is "structural impossibility beats enforced discipline" and the whole suite is currently policed by memory). The windows-latest vs linux timing-bounds question decided deliberately, not defaulted.
- **4 · A6 grants** — apply the doc-reviewer/task-decomposer scoped-Write pattern to the remaining Write-less agents whose bodies instruct output_file writes; fix the two dispatch sites that never pass output_file (wave-planner in `g-plan`, spec-writer in `g-refactor`); correct README's all-agents-write claim. This settles M45's record-write question by directive.
- **5 · A7 re-sync** — add `.claude/skills/architecture-*/SKILL.md` to `/g-update` realign + `/g-doctor` Check 16 (derive the set from `profiles/*/rules/architecture.md`, never enumerate); regenerate the drifted copy (pre-ADR-007 relic that contradicts the three-tool-class rule).
- **6 · S-fixes** — jq empty-input guard at the `agent-lifecycle.sh` rc-only check (`&& [ -n "$val" ]`) · `observe.sh` sed fallback aligned with check-commit/post-commit-cleanup (escape-aware) · `g-skill-validate` rewritten to the three-tool-class rule, derived from the architecture profile (A8) · stale §A7 threshold text in README + rules + `hooks/workflow-checkpoint.sh:268,276` (amber banner) + `skills/g-execute/SKILL.md:156` → 25% of window USED, not remaining (B9; site list re-derived from a `25%` grep across README/rules/hooks/skills/tests, not the prior incomplete enumerations — the hook's wording is test-pinned at `tests/test-workflow-checkpoint.sh:394`, so treat that as a done condition, not a surprise) · telemetry report-template rows for doc-reviewer + feature-implementer (B1 narrow fix; **M50 keeps the class fix** — the derive-from-directory parity test) · CLAUDE.md suite table — ✅ re-derived 2026-08-21 from the attested M48b run incl. test-run-all.sh (local file; done ahead of the milestone).

*USABLE (mostly deletion — the rebuild map sanctions these as DIES)*
- **7 · Delete the context estimator** — prompt counter / threshold-offset arithmetic goes; §A7 *policy* text stays; slim the workflow-checkpoint banner (~870 tokens/prompt is the harness eating the budget it defends). Closes gaps A5, B4, part of B5. **Blast-radius mandatory at plan time**: known consumers include `/g-plan`'s budget check, `/g-resume` Step 0e, `pre-compact.sh`, `session-start.sh`, and their tests.
- **8 · Forecast relabel** — output states what the formula predicts ("likelihood ≥1 premortem scenario fires"); drop the percentage (gaps A10 option b — 23 of the 23 scored forecasts as of the 2026-08-20 gaps report sat 55–95%, the number is ignored).
- **9 · Trivial-task story** — recommend/route `light` tier for trivial edits; the benchmark pilot's 36× trivial-control cost is the evidence.

**Process requirements (bind M51's own `/g-plan` and `/g-review` — hard requirements, on record 2026-08-20; fix-round governance added 2026-08-21 by developer direction):**
- **Fix-round governance:** review-arc fix rounds are deployments and get the same instruments as planned work — before any fix dispatch, a blast-radius sweep of the restatement surface (which facts the fixes change, restated where) scopes the dispatch, and the dispatch carries the known minting-mechanism premortem (fix-round prose mints enumeration/completeness defects; ADR-013 omit-or-derive applies to the fixes themselves). Evidence: four consecutive M48-family fix rounds each minted a defect at a site the round itself edited, with neither instrument firing.
- **Review scoping:** every review's file universe = branch diff + its blast-radius set, computed once at review start via the existing `/g-blast-radius` logic (wired, not rebuilt). Findings outside the universe are recorded "out of scope, noted for backlog", never HOLDs. Re-review rounds NARROW: round N+1 covers only fix diffs + files named in prior findings. Round cap: not converged by round 3 → escalate to the human (Three-Strikes applied to reviews) — oscillation is not convergence. The blind seat is blind to plan/spec context only; same bounded file set. Rationale on record: one unscoped review ran ~3h/~130k tokens before being killed; rework rate 110%.
- **Wave structure:** maximally parallel waves per the dependency graph — independent items (CI, S-fixes, estimator deletion, A6 grants, A7 re-sync) are separate wave tasks, never one blob. Review runs INCREMENTALLY at each wave boundary, scoped to that wave's diff + blast radius. The final MERGE READY review is thin by construction: cross-wave integration seams only (files touched by >1 wave + interfaces between wave outputs), never a re-review of surface already passed. Rationale: the pilot's one Critical was created by wave parallelism and existed in no single wave's output.

**Not in scope** (fork-side per directive): reviewer scorekeeping/calibration, salience, telemetry re-sourcing (B2), B6 rotation. The gaps report's §3 (deliberate tradeoffs) and §7 (already fixed) stay closed.

**Premortem:**
- *Panel wiring regresses the gate that reviews everything else* (med likelihood, max impact) → additive dispatch path proven on a scratch changeset before merge; the dispatcher-grant test; `test-review-severity` stays green.
- *Estimator deletion silently breaks consumers* (high) → the item-7 blast-radius is mandatory at `/g-plan` time; consumer updates are in-scope wave tasks. §B cross-cutting check applies to both changed primitives (estimator removal; incremental-review cadence).
- *Scope collision with M48d/M50 repeats M50's own intake near-miss* (med) → exclusion boundaries written into the scope bullets above (A4→M48d, parity class→M50, fork-side list explicit).

**Depends on:** M48 (family completes first — A4 lands in M48d; M48c wires the M48b lib overrides). **Supersedes:** M45 (folded — see its entry).

---

## Backlog

*Emptied 2026-08-10 ([ADR-012](decisions/012-g-forge-2.5-final-release-scope.md)): both candidates (multi-session orchestration, unified provenance) are fork-bound and moved to `g-docs/g-proof-roadmap.md` — a **local-only, gitignored** file (developer choice). If that file is missing on this machine, it was lost the way gitignored files get lost — its content is only recoverable from this repo's git history (ROADMAP.md as of any commit before the 2026-08-10 re-scope). Carrying it to the G-Proof fork by hand is a named fork-checklist item.*

## Version Plan

```
v0.8.1 → v0.9.0 (M8) → v0.10.0 (M9) → v0.11.0 (M10) → v0.12.0 (M11)
       → v0.13.0 (M12) → v0.14.0 (M13) → v0.15.0 (M14) → **v1.0.0 (M15) ✅ shipped**
       → **v2.0.0 (M23) ✅** → **v2.0.1 (M24 + stack implementers) ✅** → **v2.1.0 (M27 — doc-review gate) ✅** → **v2.2.0 (M28 — g-docs canonical tracking) ✅**
       → **v2.3.0 (M-audit-2026-07 — Forge Integrity; upgraded from v2.2.2 — W1 is new capability, not fixes; ships the first README status strip + starts the CHANGELOG/README currency convention)** → **v2.4.0 (M46 — Update Integrity: /g-update staleness preflight + checkpoint direction fix + detect/diagnose/fix split; inserted 2026-07-23 — G-Cash stale-cache incident)** → **v2.5.0 — THE FINAL G-FORGE RELEASE** ([ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10 — full announced scope, one release vehicle, no v2.6+ ever ships from this repo). Build order: **M47** (Planning-Pipeline Honesty) → **M48** (Review-Pipeline Hardening) → **M51** (Release Reliability / M45-lite — added 2026-08-20 by developer directive, amends ADR-012 scope a third time; M45 folded into it) → **M50** (Eval-Chain Integrity — folded in 2026-08-17, amends ADR-012 scope a second time) → **M38** (G-Report) → **M40** (Reference Convention) → **M43** (Operator Controls) → **M49** (Devil's-Advocate Agent — folded in 2026-08-14, amends ADR-012 scope) → **M41** (Release Machinery — cuts the release, sequenced last). Already shipped into 2.5: Check 24 injection detector, `/g-init` lib-install fix (`ec9bf8a`). After v2.5.0: this repo freezes (maintenance-only), the tree forks, and **G-Proof 1.0 ships from the fork as the rebuild's release vehicle** (ADR-010 — versioning restarts; no G-Forge 3.0). Everything fork-bound (M25, M26, M29–M37, M39, M42, M44 + both backlog candidates) lives in `g-docs/g-proof-roadmap.md` — local-only, gitignored, carried to the fork by hand per ADR-012. Release comms: `g-docs/communication-plan-2.5.md` (copy approved 2026-07-28; README publication happened 2026-08-10 by recorded developer override of its §4 timing rule — the remaining surfaces publish at release).
```

MVP cut: M9 + M10 + M11 — context structure + failure detection + intelligent planning with premortems.

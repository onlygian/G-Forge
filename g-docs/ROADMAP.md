## Active Session

```
━━━━━━━━━━━━━━━━━━━━
HANDOFF — g-forge | branch: fix/v2.6.2-dogfooding-defects | M53.1 built & green, REVIEW GATE NOT RUN · 2026-09-03
━━━━━━━━━━━━━━━━━━━━
Done this pass:   **M53.1 (v2.6.2 patch) built and green — NOTHING COMMITTED, REVIEW GATE NEVER RAN.** Planned (5 tasks / 2 waves), forecast (complexity 5/10, 85% High), executed both waves, all four defects addressed. **Defect 1 fix changed route:** not the roadmap's directory move but an explicit `agents` array in `.claude-plugin/plugin.json` — the installed CLI's manifest schema (v2.1.259) documents it as "List of agent file paths. When set, the agents/ directory is not auto-loaded." Collapsed 6 tasks to 1, repointed 0 of the 23 citation sites, left the three-homes reference architecture true (so M54's fix round is not restaled). **Developer verified it LIVE 2026-09-03** — cp to cache + `/reload-plugins` dropped exactly the 15 `g-forge:references:*` types. Defect 2 (`scaffold.sh` literal `M1.md` → glob) and defect 3 (`detect-stack.sh` roadmap source dropped; live run now emits `claude-plugin source=deps` alone, 11 false positives gone) both fixed with falsifiability-proven guard tests. Defect 4 diagnosed read-only, verdict **(a) nothing reads `.claude/voice-profile` at render time** for the PM/general conversational surface; `g-voice` and `g-tier` read it only for their own confirmation output — so G-RULES §B's Voice rule asserts a contract nothing implements. Suite `1379 passed, 0 failed across 39 suites` (HQ-run, verbatim). Records: `g-docs/plans/m53-1-dogfooding-defects-voice-honesty.md` (gitignored; per-wave Progress notes carry the incident record), `g-docs/forecasts/m53-1-dogfooding-defects-voice-honesty.md`, `g-docs/agent-output/wave-{1,2}/`, diagnosis at `g-docs/agent-output/g-plan/m53-1-voice-profile-diagnosis.md`.
Next up:          **(1) Run the M53.1 review gate — it was never run; no code-lead dispatch, no MERGE READY, no sentinel.** Re-do the changeset split first (procedure below), then `/g-review`. **(2) Then the M54 fix round** (16 blocking + 7 warning, `g-docs/agent-output/wave-4/task-6c-doc-review.md`) — unchanged and still open. **(3) `/g-intake` the multirepo concern** (developer raised 2026-09-03, NOT triaged): G-Cosmos and G-Forge should not share namespace or knowledge. Facts gathered — only 2 plugins load (`g-forge@g-forge` 2.6.1, `cosmos-socket@g-cosmos` 0.1.0) so nothing pollutes the runtime today, but `~/.claude/plugins/cache/g-cosmos/g-forge/0.1.0/` is a stale cached plugin *named* g-forge shipping the same two fleet skills cosmos-socket now ships; plugin ids are marketplace-qualified (`g-forge@g-cosmos` ≠ `g-forge@g-forge`) while the skill/agent namespace prefix is bare `g-forge:` with nothing to disambiguate; G-Cosmos is a `directory` source (live working tree), G-Forge a pinned `github` source. **(4) Defect 4's fix needs a DoD from the developer** before it can be specced — the diagnosis is done, the done condition is not written.
Active context:   **Tree state is unusual — read before touching anything.** On branch `fix/v2.6.2-dogfooding-defects` (created this session, never pushed, HEAD still `c24d594`). Working tree holds BOTH changesets; the index records the split: **8 M53.1 files staged** (`.claude-plugin/plugin.json`, `skills/g-init/scripts/scaffold.sh`, `skills/g-specialize/scripts/detect-stack.sh`, `tests/test-{detect-stack,g-init-scripts,run-all,agents-manifest}.sh`, `g-docs/forecasts/m53-1-*.md`) and **9 M54 files unstaged** (`.gitignore`, `README.md`, `g-docs/ROADMAP.md`, `g-wiki/{README,architecture,commit-gate,usage,reference}.md`, `g-docs/forecasts/m54-*.md`). A stash was used and **popped — no stash is dangling**. · **Why the gate stalled:** `build-review-pack.sh` derives its set from `git diff HEAD`, so a review pack cannot be scoped to one milestone when two share a tree (`--path` takes a single pathspec; M53.1 spans `.claude-plugin/`, `skills/`, `tests/`), and the sentinel binds `git write-tree` over the whole index — the tree reviewed must equal the tree committed. Procedure that worked: `git stash push -u -m "…" -- <the 9 M54 paths>`, `git add <the 8 M53.1 paths>`, rebuild pack (came back `FILES: 8`, correct), review, commit, `git stash pop`. · **Two shipped G-Forge defects found while running the gate, neither triaged:** (a) **`build-review-pack.sh` silently excludes untracked files** — `tests/test-agents-manifest.sh`, M53.1's whole ADR-013 pin, was absent from the r1 pack; any milestone adding a new file gets it excluded from code review. (b) **`tests/test-review-pack.sh` is nondeterministic under `run-all.sh`** — failed 2 assertions on 2 of 5 runs of an unchanged tree, passed 3; passes 53/0 in isolation. An intermittent suite makes attestation unstable. · **Process notes:** the task-decomposer capped at 12 turns having written nothing and was resumed (not redeployed — §C interrupted≠FAILED); the resume said "verify your own state", never asserting progress. HQ corrected a corrupted verbatim quote in the diagnosis record ("canonical assumes" → "canonical samples") that had a twin. `tests/test-run-all.sh`'s `EXPECTED_SUITE_COUNT` was bumped 38→39 inline for the new suite. · **No `/g-retro` was run this session** — the journal has signal; a retro doc is owed. · Budget: `/g-plan` estimated ~44 exchanges against ~39 remaining and the session ran past it, which is why the gate was stopped rather than pushed through on a spent window.
━━━━━━━━━━━━━━━━━━━━
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
**Status:** 🗄 Dropped (2026-08-28, ADR-012 amendment 4) — full entry in g-docs/archive/roadmap-dropped-2026-08-28.md
Outbound incident/feedback reports for the G-Forge author; G-Proof candidate.

---

### M40 — Reference Convention (recognize-and-vet external material)
**Status:** 🔀 Absorbed into M52 (Wave 1 only) — Waves 2–3 dropped, archived in g-docs/archive/roadmap-dropped-2026-08-28.md
**Version:** v2.5.0 (re-stamped per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10 — rides the final release; was v2.14.0. New recognized folder class + classifier arm + doctor advisory + intake questions + optional ADR field.)
**Goal:** Name the one committed-content class the taxonomy can't see — human-curated external material a project builds *against* but never *from* (pinned corpora, design handoffs, spec copies) — stop the commit gate mis-gating it, and let `/g-doctor` vet its provenance discipline. **Recognize-and-vet, never own-and-generate.**

**Origin:** the `reference/` convention already runs in the wild in `keyline` (root `reference/`, `SNAPSHOT.md`/`NOTE.md` provenance notes) and was independently reinvented — divergently — in `omnibook` (same corpus, squatting inside `g-docs/`). Two projects, two placements → no rule exists. Full evidence + options in the reference-folder report (advisory, Francesco / CryusFrey, 2026-07-11).

**Scope (waved):**
- **Wave 1 — Gate safety** (the load-bearing fix; independently shippable):
  - `hooks/check-commit.sh`: new **REFERENCE** classifier class (not DOC — a frozen snapshot has no code-it-describes), **exempt-with-advisory** and **marker-gated** — a `reference/*` path is exempt only if its top-level bundle carries a `SNAPSHOT.md`/`NOTE.md`; unmarked paths fall through to CODE, real code under `reference/` still gates.
  - `rules/g-rules/I-project-tracking.md`: one taxonomy row — root `reference/` = **external + human-ported + frozen** (all three or it doesn't go in), git-tracked, **never machine-written**.
  - `skills/g-init/SKILL.md` Step 5a + `.gitignore`: "never ignore `reference/`".
  - Tests: marked reference-only commit passes without a code sentinel; unmarked `reference/` path still gates; code-extension file under `reference/` still gates.
- ~~**Wave 2 — Visibility & non-contamination:**~~ — dropped 2026-08-28
  - `skills/g-doctor/SKILL.md` advisory: every top-level bundle carries a note; flag code-extension files under `reference/`; **flag reference-like bundles squatting inside `g-docs/`** (turns omnibook's state into a detectable finding).
  - Scope guard: one "skip `reference/` unless explicitly pointed at it" line in `/g-audit`, `/g-optimize`, `/g-refactor`, and Explore-style deep reads (stops scanners reporting SOLID violations in frozen material — the machine-write corruption vector).
  - Intake: one question in `g-onboard` + `g-kickoff` — *"Any specs, design handoffs, or reference corpora this project builds against?"*
- ~~**Wave 3 — Provenance link:**~~ — dropped 2026-08-28
  - `skills/g-adr/SKILL.md`: optional `Derives from:` field (path to a `reference/` artifact + snapshot edition) + one back-link confirmation step — closes the ADR↔snapshot loop that already broke once in keyline.
  - `SNAPSHOT.md`/`NOTE.md` template blurb: a **License / permission-to-commit** line (Chromium `README.chromium` precedent) + the **external+human-ported+frozen** inclusion test.

**Explicitly out of scope:** scaffolding an empty `reference/` into every project, a `/g-reference` skill, delta-check machinery, and any default read or write of `reference/` by any skill or agent (YAGNI — keyline ran the whole pattern with zero plugin support).

**Depends on:** M-audit-2026-07 (v2.3.0) — shares `check-commit.sh` + `g-doctor`; land after the enforcement-integrity fixes, not concurrent. Otherwise independent of the memory/salience/multiplayer arc.

**Sequencing note (historical — superseded by ADR-012, rides v2.5.0 per the Version line):** slotted at the tail (v2.12.0 at the time — renumbered back into the 2.x line by the 2026-07-18 restructure; the rebrand lives in M44 (⚠ "capstone" framing retired by ADR-010 — M44 is the rebuild's release vehicle)) originally to avoid renumbering the planned M29→M39 lane (a rationale since overtaken, position unchanged). **Wave 1 is a pull-forward candidate** — the reference-only mis-gate is a live enforcement fail-open, thematically M-audit's own territory, and could ship as a `v2.3.x` patch ahead of the arc if the developer wants the gate honest sooner.

**Premortem:**
- *Gate softening leaks* (med) → REFERENCE exemption becomes a code-smuggling path. Mitigation in scope: marker-gated exemption (unmarked → CODE) + doctor flags code-extension files under `reference/`. *(2026-08-30: the doctor-flag half was dropped with M40 Waves 2–3 — ADR-012 amendment 4; the shipped mitigation is the marker-gated exemption alone.)*
- *Taxonomy scope creep* (med — the named failure mode) → one class implies a doctor check implies g-update handling implies docs. Mitigation: hard-scope to the three waves; Phase-4 primitive stays backlog; no scaffold/skill; re-confirm at each wave close that nothing crept. *(2026-08-30: Waves 2–3 dropped to G-Proof — ADR-012 amendment 4.)*
- *Name collision on onboarded repos* (low) → `reference/` is a common dir with unrelated semantics. Mitigation: doctor check is **opt-in by marker** (bundle note present, or CLAUDE.md declares the convention); g-onboard asks, never assumes. *(2026-08-30: the doctor-check half was dropped with M40 Waves 2–3 — ADR-012 amendment 4.)*

**Cross-cutting propagation (G-RULES §B):** the REFERENCE classifier class is a shared primitive the gate, doctor, intake, and scanning skills must all respect — that is why Wave 2's scope-guard line and doctor check are folded *into* this milestone, not left as follow-ups. Run `/g-blast-radius` at Wave 1 close to confirm no reader (skill, hook, or rule) was missed. *(2026-08-30: Waves 2–3 dropped to G-Proof — ADR-012 amendment 4; the Wave-1 classifier shipped alone.)*

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
**Status:** 🗄 Dropped (2026-08-28, ADR-012 amendment 4) — full entry in g-docs/archive/roadmap-dropped-2026-08-28.md
Release tooling (`/g-changelog`, `/g-release`) and README currency machinery; G-Proof candidate.

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

**Depends on:** *(Pre-fold history — superseded by the `Status:` line above; M45 is folded into M51 and the ordinal below no longer applies.)* — (sequenced **fourth** in the 2.5 build order per [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) — that build order retired 2026-08-28, ADR-012 amendment 4, moved from third by the 2026-08-17 M50 amendment: after M48's hardening of the current pipeline **and after M50**, whose agent contract map is a required input to this milestone's design ADR — M45 must decide whether the 11 reviewer agents get scoped Write grants or HQ writes their records (todo row 6), and M50 produces the evidence for that call. Before M38/M40/M43/M41. *The 2026-07-15 "release machinery first" ordering is retired — M41 now cuts the release last.*) Independent of M36/M37, both fork-bound in `g-docs/g-proof-roadmap.md` (ships flat-depth; the depth selector arrives, if ever, with G-Proof's salience layer).

**Premortem:**
- *Synthesis-verdict regression — findings-block verdict misses what a whole-diff read catches* (med) → A/B on the first slice; monolith fallback stays; HOLD adjudication human-visible.
- *Nesting-limit surprises* (low-med) → "directly from a skill in the main session" is explicitly permitted by review-orchestrator's contract; doc-reviewer dispatches from `/g-doc-review` prove the shape.
- *Premature depth-selection* (med) → defaults flat-deep; selector arrives, if ever, with M37 (fork-bound, `g-docs/g-proof-roadmap.md`).

---

### M43 — Operator Controls (/g-settings + inspection cadence)
**Status:** 🗄 Dropped (2026-08-28, ADR-012 amendment 4) — full entry in g-docs/archive/roadmap-dropped-2026-08-28.md
Operator visibility and control over G-Forge setup variables; G-Proof candidate.
**Goal:** Give the operator **visibility and control over G-Forge's setup and operative variables**, and give actual programmers (non-vibe-coders) a first-class way to *read the code* at wave boundaries instead of only meeting it at the review verdict.
**Scope (waved):**
- **Wave 1 — `/g-settings`:** one skill that surfaces every G-Forge state variable with current value, owner (which skill/hook writes it), and effect — `integration-tier`, `voice-profile`, `telemetry-profile`, `inspection-cadence` (Wave 2), Roundtable binding, plus read-only diagnostics (`review-holds`, `milestone-count`, `session-prompt-count`, `escalation-log`, `last-trim`). Safe edits routed through it (validated values only); gate-relevant changes (tier) get an explicit are-you-sure with consequences. **Distinct from `/g-doctor`** — doctor validates *health/state*, settings shows and sets *intent*. Registered in the `/g-forge` router.
- **Wave 2 — Inspection cadence (the programmer's wave-boundary hold):** new variable `.claude/inspection-cadence` ∈ `every-wave` | `every-milestone` | `off` (default `off`). `/g-init` gains ONE intake question ("Do you want to personally inspect the code at wave boundaries?" — framed for experienced devs; decline = off, no friction for vibe-coders). `/g-execute`'s wave-completion gate honors it as a **hard hold**: present the wave's diff summary + changed-file list, dispatch nothing further until the developer nods (consistent with gates-gate; an ignorable pause is not an inspection gate). `every-milestone` holds only before the final wave's `/g-review` handoff.
- **Wave 3 — Propagation (G-RULES §B):** `/g-voice` cross-references (voice = how it *talks*, settings = how it *runs* — the intake flows must not duplicate questions); `/g-doctor` gains a check that `inspection-cadence` holds a valid value; **M39 G-tweak reassess hook** — *(narrowed per ADR-012: M39 is fork-bound, so the interview itself cannot ship from this repo. The 2.5 deliverable is only the documented hook point — the cadence variable readable + the reassess contract written down; the Phase A interview that consumes it lands, if ever, in G-Proof.)*

- **Wave 4 — Governance cadence: the health passes become gating, not hopeful** *(added 2026-08-17, developer — "these passes must be mandatory and gating if the full g-forge thing is up, or setup in the upcoming settings")*. New variable `.claude/governance-cadence`, tier-defaulted: **`full` = gating · `balanced` = nudge-only (today's behaviour) · `light` = silent**, overridable per-pass via `/g-settings`. Covers `/g-align`, `/g-telemetry`, `/g-trim`, `/g-doctor` — the passes that report on G-Forge's own health.
  - **Evidence this is needed (2026-08-17 close swarm):** `/g-align` last ran 2026-07-23 — **25 days against a 7-day nudge cadence**, and the nudge had been printing on every prompt the whole time. `/g-telemetry` had not run since 2026-07-23 either, and when it did it found five structural defects in its own gauges (→ M50). A nudge that can be ignored indefinitely is not a control; it is a log line. Both failures share one shape: **an instrument reports clean when it is simply not being run.**
  - **The load-bearing design constraint — gate on RUN-RECENCY, never turn the pass into a blocker.** `/g-align`'s own `## Rules` state *"Advisory only. Never write `.claude/g-forge-approved`, never block a commit, plan, or milestone close."* The obvious implementation — let `/g-align` return a blocking verdict — flips that contract and makes a drift *opinion* into a merge blocker, which also collides with the brief's non-goal *"not a replacement for the developer's judgment."* The correct shape keeps the two separate: **the pass stays advisory and never issues a HOLD; the existing commit gate refuses to open while a required pass is stale.** Staleness is a mechanical, falsifiable fact (`.claude/last-align` vs today); a drift verdict is a judgment. Only the first is safe to gate on.
  - **The stamp layer is a deliverable, not a given — corrected 2026-08-17 after measuring.** An earlier draft of this wave claimed the passes "already write" their stamps and that gating needs "no new bookkeeping." **False.** Exactly **one** stamp file exists on this repo: `.claude/last-align`. `/g-trim` *specifies* `.claude/last-trim` (`skills/g-trim/SKILL.md:58`, "the only file write this skill performs") and `workflow-checkpoint.sh:373` *reads* it — **but the file has never existed**, because `/g-trim` has never completed a run here. Consequence: its weekly nudge has fired on **every prompt, indefinitely**, with no reachable state that clears it. Wave 4 therefore owns defining and writing the full stamp set before anything can gate on it.
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
**Version:** shipped in **v2.4.1** (2026-08-24, intermediate cut at the M48-family close per ADR-012 amendment 2026-08-22), and cumulatively in the final **v2.5.0** — patch-class process fixes.
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
**Status:** ✅ COMPLETE (M48a ✅ shipped `df2ca1b` 2026-08-20; M48b ✅ shipped `72fcfd3` 2026-08-21; M48c ✅ shipped `55c5bef` 2026-08-21 — 3 review rounds: r3 HOLD 0C/11M, r4 HOLD 0C/3M, r5 MERGE READY; M48d ✅ shipped `1fc8ace` 2026-08-23 — 3 review rounds + 2 fix rounds, converged at the round cap via HQ doc-class closure + pinpoint re-verify; M48e ✅ shipped `7a6ea08` 2026-08-23 — 3 review rounds + 1 fix round, converged at the cap; family-close v2.4.1 cut executed 2026-08-24, developer decision) — **split into M48a–M48e on 2026-08-19** (developer decision at `/g-plan`'s budget gate: the monolithic plan estimated ~74 exchanges against a ~33-exchange session budget; split along the wave-dependency structure so each sub fits one session with no mid-plan handoff, each closing through its own review + commit. Execution order is fixed a→e — b's lib overrides must exist before c wires them into fixtures. All subs shipped in v2.4.1 (2026-08-24, the intermediate cut at the M48-family close) and cumulatively in the final v2.5.0 (per ADR-012 amendment 2026-08-22); the split is sequencing only, no scope change. Sub-milestone task detail below is the durable record — the per-sub plan files in `g-docs/plans/` are gitignored scratch.)

**M48a — Doc-gate teeth & suite runner** ✅ `df2ca1b` (2026-08-20; 4-round code review 30→9→4→0 + 4-round doc gate; suite 575/19 attested) · grep-the-literal-fact sweep + round-3 consolidation note as a required `/g-doc-review` step (doc-reviewer executes the sweep itself, in Step 2, under its own record-scoped `Write` grant, recording evidence in its per-run record at `g-docs/agent-output/review/doc-reviewer-[YYYY-MM-DD]-[request-slug]-r[N].md`; Step 2b is HQ's check that the record carries it, not the sweep itself; a surviving stale copy or a missing sweep → DOCS HOLD) · doc-reviewer volatile-fact heuristic (in-flight process counts in a reviewed doc are a smell; ADR-013 remedy is pin-with-a-test-first or omit; pointer language to the owning record is this contract's own addition) · falsifiability comment rule in `rules/g-rules/H-testing.md` (applies in projects with an executable test suite; shipped source only) · `tests/run-all.sh` (derives suite set from the `tests/test-*.sh` glob per ADR-013, front-loads the two suites that would otherwise run last in glob order so the big suites don't tail the run, parallelism deliberately off, must prove identical totals vs serial).

**M48b — Lib overrides & first test fixes** ✅ (shipped `72fcfd3` 2026-08-21) · env-injectable timeout override in `hooks/lib/stdin-read.sh` (unset = byte-identical; production call sites untouched) · fast test-time guard-window constant in `tests/lib/timing-bounds.sh` (additive, WHY comment, never replaces `GF_HOOK_STDIN_GUARD_MS`) · audit-7 F4: `test-g-doctor-drift.sh` derives the hash-cascade snippets from shipped `skills/g-doctor/SKILL.md` at runtime instead of hand-copied mimics (cksum in the wave; sha256sum/shasum extended in the fix round) · audit-7 H3+H9: grep-pin the g-init settings.json template matchers and `hooks/hooks.json` = `{"hooks": {}}` in `test-lib-install-completeness.sh`.

**M48c — Code-gate teeth & new suites** ✅ · grep-the-literal-fact sweep + round-3 note as a required `/g-review` step (recorded in code-lead's review record) · wire the fast override into the abandoned-stdin fixtures (`test-class-split-invariant.sh` six-hook loop, `test-check-commit.sh` cases 23/25; guard-deleted probe must still go RED; re-sum counts from Results lines) · revalidate `GF_FAST_STDIN_GUARD_MS` (`tests/lib/timing-bounds.sh`) against real override-wired runs before any suite depends on it — the value is validated 2026-08-21 and raised to 30000 on loaded-machine evidence (`CHANGELOG.md`'s M48c `### Changed` entry, "Code-gate fix-closure sweep & new test suites", `tests/lib/timing-bounds.sh:62-72`) and this milestone delivered that revalidation (both refs now record it) · audit-7 H4: version-agreement suite (`plugin.json` vs `marketplace.json`) · audit-7 H5: router-token ↔ `skills/` dir parity suite (derive-and-compare both sets at runtime, never a typed list).

**M48d — Direct runner & the big hole** ✅ `1fc8ace` (2026-08-23; 3 review rounds + 2 fix rounds, converged at the round cap via HQ doc-class closure + pinpoint re-verify) · `/g-review` Step 1 runs the deterministic suite directly via `tests/run-all.sh` (drop the `*-dev.md` preference for the suite run; keep it only for judgment-needing gate fixtures) · audit-7 H1: `tests/test-pre-commit.sh` — first-ever execution coverage of the native gate (native git-hook contract: no stdin JSON, deny = stderr + exit 1; sentinel 3-field validation, worktree binding, HEAD staleness, valid pass-through) · un-inert `test-workflow-checkpoint.sh` §12/§13 (real assertions, probe-verified RED with the code deleted).

**M48e — Tier cases & heredoc fix** ✅ `7a6ea08` (2026-08-23) · audit-7 H2: tier cases in `test-check-commit.sh` (light gate-off, balanced gate-on, garbage value → gate-on) · CANDIDATE (todo task 10, confirm at this sub's plan approval): heredoc-body pathspec misclassification fix in `hooks/lib/commit-detect.sh` `extract_pathspecs` + regression cases in `test-commit-detect.sh` — sole consumer is `hooks/check-commit.sh:222`; `hooks/pre-commit` verified unaffected (classifies from `git diff --cached --name-only` only, grep-confirmed 2026-08-19).

**Version:** shipped in **v2.4.1** (2026-08-24, intermediate cut at the M48-family close per ADR-012 amendment 2026-08-22), and cumulatively in the final **v2.5.0**.
**Goal:** A fix pass can't silently mint the next defect. Field-proven twice independently: keyline's flagship incident (~20 review dispatches for one milestone, `g-docs/field-reports/2026-08-10-keyline-francesco.md` §1) and this repo's own `ec9bf8a` pass (9 rounds, 7 found defects, 2 after clean verdicts).
**Scope:**
- Grep-the-literal-fact sweep as a **required** `/g-review` + `/g-doc-review` step before accepting a fix as closing a finding — sweep output recorded in the review record, checkable, not advisory
- Round-3-same-finding-class consolidation checkpoint ("round 3 on this class — consolidate the repeated facts into one source of truth instead of patching") — surfaced note, never a block
- `doc-reviewer` volatile-fact heuristic: claims about in-flight process counts (round counts, commits-ahead) inside a document under review are a smell — ADR-013 remedy is pin-with-a-test-first or omit; pointer language to the owning record is this contract's own addition
- Falsifiability comment rule for guard/negative tests (G-RULES §H, scoped to projects with an executable test suite): guard neutered in a scratch copy, test confirmed red, copy discarded — nothing in the production tree is ever mutated, so there is no restore step — recorded as an in-file one-line comment
- **`/g-review` Step 1 must not route a deterministic suite run through an agent.** Step 1 currently prefers a `.claude/agents/*-dev.md` runner over the inline path. `for f in tests/test-*.sh; do bash "$f"; done` needs zero judgment, so the agent buys nothing and costs the progress signal: observed 2026-08-16 as a 74-minute opaque dispatch with no way to tell running from hung, plus a confabulated total (todo task 9). Direct execution yields the identical runner output in a pollable file and satisfies finding #20 *better*, since the doctrine is "a claim with no output is unverified" and first-hand output outranks relayed output. Keep the `*-dev.md` preference for project-specific gate fixtures that genuinely need judgment; drop it for the suite run
- **Suite wall-clock is a review-gate cost, not just a test concern.** Three compounding causes measured 2026-08-16 on this repo: roughly 9 minutes of deliberate waiting on abandoned-stdin guard tests (`test-class-split-invariant.sh:124` looping `< <(sleep 300)` over six hooks — measured pre-override at 65000ms bounds; since the M48c wiring five run at the ~2s override — plus `test-check-commit.sh:344,390` and `test-stdin-read.sh:83`); MSYS fork overhead across 564 assertions (suite population measured at that date; current population is 622); and 18 independent suites (also measured at that date; current count is 22) run serially — the hint front-loads the two suites that would otherwise run last in glob order (test-workflow-checkpoint.sh 86, test-worktree-resolve.sh 42) so they don't tail the run. Reordering or parallelising the suites cannot reduce total serial runtime — only perceived progress; that was a plan-time arithmetic error, not a fix (`g-docs/retros/2026-08-19-m48-split-and-m48a-wave.md:22`). The real wall-clock levers are the M1 output-capture fix (landed in M48a's fix round) and M48b/c's guard-window overrides so tests prove the timeout at 2s while production keeps 65s. **Never shrink the constants themselves** — the same architecture note records `GUARD_WINDOW_MS` being widened 8000→20000 because real MSYS overhead breached a tighter bound. Related: todo task 7 already carries the `< <(sleep 300)` sleeper-reaping rider
- **Carried from the 2026-08-11 whole-system audit (todo row 7), assigned here 2026-08-17:** audit-7 F4 + H2–H5 + H9 — fixture drift and the coverage holes below `hooks/pre-commit`. Same family as todo row 5's Wave C test-teeth rider *(row 5 closed 2026-08-31, M52 F3 — see the todo-done close entry)*, which already folds into this milestone; keeping them together avoids two passes over the same fixtures

**Premortem:**
- *Regression in the gate degrades every future review* (med) → additive steps only; exercised on a scratch changeset before merge; `test-review-severity` stays green.
- *New steps decay into skipped prose — the vigilance trap this milestone fixes* (med) → grep-sweep output must appear in the review record; absence is itself a findable gap.
- *Rule bloat for no-test projects* (low) → falsifiability rule scoped to projects with an executable test suite.

**Depends on:** — (sequenced after M47; no hard dependency. Both fed the whole-system audit's scope; the audit ran 2026-08-11 — its Wave C findings fold back into M48's plan as todo task 5. Relationship to M51: M48 is the cheap field-proven hardening of the *current* pipeline, landing before M51's panel wiring rebuilds it — M51 absorbs M45's structural rework — per the ADR-012 build order, retired 2026-08-28 by ADR-012 amendment 4: the panel wiring was dropped, M51's surviving items ride M52.)

---

### M50 — Eval-Chain Integrity (instruments measure what they claim)
**Status:** 🗄 Dropped (2026-08-28, ADR-012 amendment 4) — full entry in g-docs/archive/roadmap-dropped-2026-08-28.md
Instruments and agent contracts integrity checks; G-Proof candidate.

---

### M49 — Devil's-Advocate Agent (internal adversarial pattern review)
**Status:** 🗄 Dropped (2026-08-28, ADR-012 amendment 4) — full entry in g-docs/archive/roadmap-dropped-2026-08-28.md
Internal adversarial reviewer for `/g-patterns` resolve phase; G-Proof candidate.

---

### M51 — Release Reliability (M45-lite)
**Status:** 🔀 Absorbed into M52 (items 3, 4 narrowed, 5, 6, 8, 9) — items 1, 7, 10 dropped, archived in g-docs/archive/roadmap-dropped-2026-08-28.md
**Version:** v2.5.0 (rides the freeze release — this milestone *defines* its bar: "a reliable and very usable harness" is the release condition, not a doc patch)
**Goal:** v2.5 ships reliable and very usable: the review panel actually runs (MERGE READY has been solo-review since May — `daf15e3` removed code-lead's Agent grant, `51e5220` re-added AXES language without it), the invariants are machine-enforced, and the mechanisms the rebuild map already sanctions as DIES are deleted rather than polished.
**Scope (dependency order, per the 2026-08-20 directive):**

*RELIABLE*
- ~~**1 · Panel wiring (M45-lite)**~~ — dropped 2026-08-28 (review-orchestrator DIES per the rebuild map; archived in `g-docs/archive/roadmap-dropped-2026-08-28.md`) — ~~developer decision 2026-08-20:~~ wire it, don't doc-fix it. `review-orchestrator` dispatched from `/g-review` at depth 0; strip the stale AXES/dispatch language from `code-lead` and `g-review`; add a test that any agent named as a dispatcher holds the Agent grant for what it dispatches. Design input from claude-code-review-council (same panel shape, top-level dispatch), adopting: synthesis verifies every cited file:line by opening the file and drops unverifiable findings · findings tagged with source reviewer(s), cross-reviewer agreement raised as confidence, disagreements surfaced not blended · a reviewer that fails to run is NAMED as not-run in the report (a review is "looked and found nothing", never silently "never looked") · one panel seat reviews the diff blind to plan/spec context. Explicitly rejected: external-CLI multi-model seats (breaks zero-dependency install; optional adapter post-2.5 at most) · resuming reviewers to defend findings (violates §C single-use — dispatch a fresh verifier instead). Severity contract unchanged (`test-review-severity.sh` stays authoritative; no P0–P3 ladder). Done condition inherited from folded-M45's A/B obligation (ADR-012 Assumptions): the wired panel demonstrates verdict-equivalence against the monolith path on a real changeset — or records the trade explicitly — before the 2.5 "same verdict, a fraction of the cost" claim publishes. Inherits from folded M45: the `/g-blast-radius` return-only/no-persist invocation mode (producer change, `skills/g-blast-radius/SKILL.md` Step 7 + Rules line) and the audit-cadence carve-out class.
- **2 · Gate execution coverage** — owned by **M48d**, not restated here; CI (item 3) runs it once landed.
- **3 · CI** — GitHub Actions running all suites + the gate fixture on push/PR (gaps A1: the founding doctrine is "structural impossibility beats enforced discipline" and the whole suite is currently policed by memory). The windows-latest vs linux timing-bounds question decided deliberately, not defaulted.
- **4 · A6 grants** — apply the doc-reviewer/task-decomposer scoped-Write pattern to the remaining Write-less agents whose bodies instruct output_file writes; fix the two dispatch sites that never pass output_file (wave-planner in `g-plan`, spec-writer in `g-refactor`); correct README's all-agents-write claim. This settles M45's record-write question by directive.
- **5 · A7 re-sync** — add `.claude/skills/architecture-*/SKILL.md` to `/g-update` realign + `/g-doctor` Check 16 (derive the set from `profiles/*/rules/architecture.md`, never enumerate); regenerate the drifted copy (pre-ADR-007 relic that contradicts the three-tool-class rule).
- **6 · S-fixes** — jq empty-input guard at the `agent-lifecycle.sh` rc-only check (`&& [ -n "$val" ]`) · `observe.sh` sed fallback aligned with check-commit/post-commit-cleanup (escape-aware) · `g-skill-validate` rewritten to the three-tool-class rule, derived from the architecture profile (A8) · stale §A7 threshold text in README + rules + `hooks/workflow-checkpoint.sh:271,279` (amber banner) + `skills/g-execute/SKILL.md:156` → 25% of window USED, not remaining (B9; site list re-derived from a `25%` grep across README/rules/hooks/skills/tests, not the prior incomplete enumerations — the hook's wording is test-pinned at `tests/test-workflow-checkpoint.sh:462`, so treat that as a done condition, not a surprise) · telemetry report-template rows for doc-reviewer + feature-implementer (B1 narrow fix; **M50 keeps the class fix** — the derive-from-directory parity test) · CLAUDE.md suite table — ✅ re-derived 2026-08-21 from the attested M48b run incl. test-run-all.sh (local file; done ahead of the milestone).

*USABLE (mostly deletion — the rebuild map sanctions these as DIES)*
- ~~**7 · Delete the context estimator**~~ — dropped 2026-08-28 (widest blast radius of anything left; the fork deletes it on day one; archived in `g-docs/archive/roadmap-dropped-2026-08-28.md`) — ~~prompt counter~~ / threshold-offset arithmetic goes; §A7 *policy* text stays; slim the workflow-checkpoint banner (~870 tokens/prompt is the harness eating the budget it defends). Closes gaps A5, B4, part of B5. **Blast-radius mandatory at plan time**: known consumers include `/g-plan`'s budget check, `/g-resume` Step 0e, `pre-compact.sh`, `session-start.sh`, and their tests.
- **8 · Forecast relabel** — output states what the formula predicts ("likelihood ≥1 premortem scenario fires"); drop the percentage (gaps A10 option b — 23 of the 23 scored forecasts as of the 2026-08-20 gaps report sat 55–95%, the number is ignored).
- **9 · Trivial-task story** — recommend/route `light` tier for trivial edits; the benchmark pilot's 36× trivial-control cost is the evidence.
- ~~**10 · Review-progress rendering (adopter framing)**~~ — dropped 2026-08-28 (cosmetic; archived in `g-docs/archive/roadmap-dropped-2026-08-28.md`) — ~~intake 2026-08-22:~~ `mid`/`eli5` voice profiles render review rounds as quality passes ("pass N of ~expected — X issues caught pre-ship") in `/g-review` progress output and the AFK handoff, so the fix loop reads as finishing work, not a tool correcting its own failures; expected-rounds figure telemetry-seeded once a rounds-per-pass metric exists (small metric addition rides along), static "normally 2–3" until then; `dev` (and local overrides) unchanged. Hard bound (§B voice rule): rendering only — verdicts, severities, counts byte-exact; a HOLD never reads as anything but a stop. Kin to item 8: 8 fixes the ignored forecast number, 10 fixes the review narration.

**Process requirements (bind M51's own `/g-plan` and `/g-review` — hard requirements, on record 2026-08-20; fix-round governance added 2026-08-21 by developer direction):**
- **Fix-round governance:** review-arc fix rounds are deployments and get the same instruments as planned work — before any fix dispatch, a blast-radius sweep of the restatement surface (which facts the fixes change, restated where) scopes the dispatch, and the dispatch carries the known minting-mechanism premortem (fix-round prose mints enumeration/completeness defects; ADR-013 omit-or-derive applies to the fixes themselves). Evidence: four consecutive M48-family fix rounds each minted a defect at a site the round itself edited, with neither instrument firing.
- **Review scoping:** every review's file universe = branch diff + its blast-radius set, computed once at review start via the existing `/g-blast-radius` logic (wired, not rebuilt). Findings outside the universe are recorded "out of scope, noted for backlog", never HOLDs. Re-review rounds NARROW: round N+1 covers only fix diffs + files named in prior findings. Round cap: not converged by round 3 → escalate to the human (Three-Strikes applied to reviews) — oscillation is not convergence. The blind seat is blind to plan/spec context only; same bounded file set. Rationale on record: one unscoped review ran ~3h/~130k tokens before being killed; rework rate 110%.
- **Wave structure:** maximally parallel waves per the dependency graph — independent items (CI, S-fixes, estimator deletion, A6 grants, A7 re-sync) are separate wave tasks, never one blob. Review runs INCREMENTALLY at each wave boundary, scoped to that wave's diff + blast radius. The final MERGE READY review is thin by construction: cross-wave integration seams only (files touched by >1 wave + interfaces between wave outputs), never a re-review of surface already passed. Rationale: the pilot's one Critical was created by wave parallelism and existed in no single wave's output.

**Not in scope** (fork-side per directive): reviewer scorekeeping/calibration, salience, telemetry re-sourcing (B2), B6 rotation. The gaps report's §3 (deliberate tradeoffs) and §7 (already fixed) stay closed.

**Premortem:**
- *Panel wiring regresses the gate that reviews everything else* (med likelihood, max impact) → additive dispatch path proven on a scratch changeset before merge; the dispatcher-grant test; `test-review-severity` stays green.
- *Estimator deletion silently breaks consumers* (high) → the item-7 blast-radius is mandatory at `/g-plan` time; consumer updates are in-scope wave tasks. §B cross-cutting check applies to both changed primitives (estimator removal; incremental-review cadence).
- *Scope collision with M48d/M50 repeats M50's own intake near-miss* (med) → exclusion boundaries written into the scope bullets above (A4→M48d, parity class→M50, fork-side list explicit).
- *Item-10 rendering softens a verdict for non-dev profiles* (low likelihood, high impact) → §B rendering-only rule made test-pinnable: an assertion that the literal HOLD verdict survives every profile's rendering; review verifies the rendering layer never gates or rewords a verdict line.

**Depends on:** M48 (family completes first — A4 lands in M48d; M48c wires the M48b lib overrides). **Supersedes:** M45 (folded — see its entry).

---

### M52 — v2.5 Minimal Freeze (release)
**Status:** ✅ Complete (2026-08-31 — v2.5.0 cut)
**Version:** v2.5.0 — the final G-Forge release, hand-cut per G-RULES §D the way v2.4.1 was on 2026-08-24; no `/g-release` machinery.
**Goal:** The README and the release say only what is true, and 2.5 shipped 2026-08-31 at the close of the F1–F3 audit cycle and the Session D gates (was "by Sunday 2026-08-30" until the 2026-08-30 amendment below inserted F1–F3 ahead of Session D). Filter: the rebuild map's verdict column (`audits/2026-07-rebuild-map.md`) — 2.5 does only what SURVIVES the G-Proof rebuild or is an adopter-facing bug; everything built on a DIES/TRANSFORMS component is dropped to `archive/roadmap-dropped-2026-08-28.md` as a G-Proof candidate, decided at R0.
**Absorbs:** M51 items 3 (test CI, not a gate), 4 (narrowed to the two `output_file` dispatch sites + the README all-agents-write correction), 5 (A7 re-sync), 6 (S-fixes), 8 (forecast relabel), 9 (trivial-task light-tier routing); M40 Wave 1 (REFERENCE classifier arm + taxonomy row + g-init line + tests).
**Scope — four planned sessions (A–D; the 2026-08-30 amendment below inserts audit cycles F1–F3 before D), each opened with `/g-resume` and closed with its gate, a commit, and a `/g-retro` handoff** (plan: `plans/v25-minimal-freeze.md` · forecast: `forecasts/v25-minimal-freeze.md`):
- **Session A (Fri 2026-08-28) — record + README, doc-only.** Wave 1: ADR-012 amendment 4 · ROADMAP archive + this entry. Wave 2: comms plan §3a/§3c/§7 · README audit (findings only, every claim vs source). Wave 3: README fixes. Gate: `/g-doc-review`.
- **Session B (Sat AM) — skills + small fixes.** Wave 3b: the doc-gate r1 fix round (B1–B6) — **done 2026-08-28**. Wave 4: CI workflow · `g-plan` consolidated edit (wave-planner `output_file`, forecast line, light-tier sentence) · `g-refactor` spec-writer `output_file` · light-tier routing in `g-help` + `integration-tiers.md`. Wave 5: A7 drift-set resync + test · S-fixes a (agent-lifecycle jq guard), b (observe.sh sed fallback), c (g-skill-validate three-tool-class rewrite) · **Task 23 — telemetry latch + measurement vacuum** (added mid-session, see the scope amendment below). Gate: scoped `/g-review`.
- **Session C (Sat PM) — hooks + classifier.** Wave 6: §A7 wording pinned pair (hook + test — reset at 25% of the window *used*) · forecast relabel · M40 REFERENCE classifier + tests + falsifiability probe. Wave 7: local architecture-skill copy regenerated (HQ). *(Wave 7's other two items were **cut 2026-08-28** under the overrun rule — see the two notes below, which together are authoritative. **Task 18** (M40 taxonomy row + g-init line) is cut entirely. **Task 15 is cut only in part**: its repo-wide `25%` sweep stays cut, but its rule-text half was un-cut on 2026-08-29 and is **done** — `rules/g-rules/A-session.md` ×2 and `skills/g-execute/SKILL.md` all read "~25% of the window used". Wave 7's residual scope is the single item named above.)* Wave 8: CHANGELOG `[2.5.0]`. Gate: `/g-review` + `/g-doc-review`.
- **Session D (after the F3 gate closes; was Sun 2026-08-30) — release, HQ only.** **Precondition (inherited from the dropped M41, 2026-08-28): read `g-docs/communication-plan-2.5.md` before cutting v2.5.0** — it holds the approved release copy, the §4 placement rules, and the §7 decisions that settle at publish time. **Second precondition (added 2026-08-30 at F2-R close): run `/g-doctor` and resolve — or explicitly accept in the record — every finding before the version bump.** Then: version bump → release grep sweep (§D step 5) → tag `v2.5.0` + GitHub release → freeze.
**Scope amended 2026-08-28 (developer, mid-session) — adopter telemetry defects added, paid for by the overrun rule.** A field report from the `G-Sharp` project (`g-docs/field-reports/2026-08-28-g-sharp-telemetry.md`, committed with this change) documents two live defects in 2.4.x telemetry, both reproduced against source before acceptance: (1) `.claude/review-holds` is a **latch** — unconditional increment, no decrement, and its only reset requires a `stable` profile that the counter's own growth makes unreachable, so the subsystem drives every long-running project toward `recovery` as a function of age; measured on this repo 2026-08-29 at `fix_after_feat` 7 + `review_holds` 34 = 41, over 30 `feat:` commits = a **137%** rework rate against a 20% threshold. (2) Five of the eight metrics grep retro prose for tokens `/g-retro` has never emitted (0/34 files here for metrics 1 and 8), and a run filled them in by semantic reading and presented the result as measurement, escalating an adopter's review posture for three weeks. **Accepted into 2.5** as Task 23: the latch fix passes both limbs of the filter (`audits/2026-07-rebuild-map.md:53` — "8 derived metrics + adaptive profile **survive**") and the vacuum fix passes the adopter-facing-bug limb. **Declined to G-Proof R0:** teaching `/g-retro` the tag vocabulary, the marked-interpretive-pass redesign, and recency weighting — all three improve hand-counting, which the same map row marks as dying.
**Overrun rule — invoked 2026-08-28 to pay for Task 23.** Both named sweep-only tasks are **cut**: Task 15 (§A7 remaining sites + `25%` sweep) and Task 18 (M40 taxonomy row + g-init never-ignore line). Their gate-fixing halves survive — Task 14 still lands the pinned §A7 hook/test pair, Task 17 still ships the REFERENCE classifier arm. Session D is not compressed.
**Task 15 partially un-cut 2026-08-29 (developer, at the r2 doc gate).** The gate raised the §A7 rule text to BLOCKING once the cut removed its owner, and it was right to: `rules/g-rules/A-session.md` is the normative rule installed into every consumer project, not surrounding prose, and the two readings differ by 3× (fire at 25% used vs. at 75% used). The **three known sites** are therefore restored and fixed — `rules/g-rules/A-session.md` ×2 and `skills/g-execute/SKILL.md`, all now reading "~25% of the window used". What stays cut is the open-ended half the overrun rule was invoked for: the repo-wide `25%` sweep with a per-hit disposition. `hooks/workflow-checkpoint.sh` remains Task 14's pinned hook/test pair in Session C.
**Scope amended 2026-08-30 (developer, at Session D open) — Fable audit cycles F1–F3 inserted before Session D.** Session D (release) is deferred until three audit-and-fix cycles close; the release date moves from 2026-08-30 to when F3's gate closes. Each cycle: HQ on the session model (Fable) reads one slice of source **directly** and writes the findings itself — no reviewer agents for the read (**§A1 override, developer-decided**: the audit is the one place the top tier is used first, because the gap being hunted is the class the Haiku/Sonnet reviewers already passed); every finding is filtered by the amendment-4 rule (survives the G-Proof rebuild per `audits/2026-07-rebuild-map.md`, or adopter-facing) before it earns a fix; fixes are dispatched to implementers under the tool-call caps (HQ edits only single-file known-location sites); the diff closes through `/g-review` + `/g-doc-review`, a commit, `/g-retro`, and the handoff; the next cycle opens with `/g-resume`. One slice, one wave, one gate per cycle (carried rule). Slices: **F1** — the commit-gate path (`check-commit.sh`, native `pre-commit`, `post-commit-cleanup.sh`, the libs they source), the git-hooks-dir install steps in `/g-init` Step 6a and `/g-update` Step 7a (todo 17), and `tests.yml` (todo 15 F6). **F2** — agents marked SURVIVES on the map (`architecture-enforcer`, `doc-reviewer`, `spec-writer`, `test-writer`, `debugger`, `error-detective`, `doc-writer`, `project-manager`) and the record seam (`g-resume`, `g-retro`, `g-adr`, `g-doc-review`). **F3** — the remaining SURVIVES skills (`g-roadmap`, `g-intake`, `g-align`, `g-brief`, `g-kickoff`, `g-onboard`, `g-forecast`, `g-blast-radius`, `g-patterns`, `g-identity`, `g-wiki`, `g-tier`, `g-train`, `g-skill-design`, `g-skill-validate`, `g-roundtable`) plus the open ledger (todo 5, 6, 9, 14, 15, 16, and 18 — the F2 carries, minted 2026-08-30; row 11 is deliberately outside: it is M51/G-Proof design input, not 2.5 scope). **Not in scope:** DIES / TRANSFORMS components — a whole-system pass over those is the **first act of G-Proof R0**, run on the shipped 2.5 (recorded on `g-proof-roadmap.md`'s R0 entry), not on the release branch. Then Session D as written.
**Scope amended 2026-08-30 (developer, at F2-R close) — two adds approved, and F3's bar stated.** (1) **F3's doc gate explicitly includes a `README.md` + `g-docs/agents.md` currency re-check** against every behaviour change shipped since Session A's README audit — F1, F2 and F2-R changed shipped contracts after that audit. §D step 4 already requires a README update at the release cut and step 5's sweep is literal-driven; this add front-loads the claim-vs-source re-check into F3's gate so the cut inherits verified claims instead of performing the audit on release day. (2) **Session D gains a release-hygiene precondition before the version bump:** run `/g-doctor` (read-only — its checks include the gitignore line and stray-document detection) and resolve, or explicitly accept in the record, every finding — §D step 9's never-tag-over-unresolved-drift rule anchors the drift half of this; the gitignore and stray-document checks are the half this amendment adds. Developer's stated bar for F3: **all shipped skills and agents spotless** — concretely, F3 closes only when its audit record lists zero unfixed filter-passing findings on any shipped skill or agent surface and both gates are green; fixes still pass the amendment-4 filter (SURVIVES the rebuild, or adopter-facing in 2.5).
**Depends on:** M47 ✅, M48 ✅ (both shipped in v2.4.1).

---

### M53 — v2.6 Token Diet
**Status:** ✅ Complete (2026-09-02 — v2.6.0 cut)
**Version:** v2.6.0 — reopens development after the v2.5 freeze ([ADR-014](decisions/014-v26-token-diet-reopens-after-freeze.md) supersedes ADR-012's finality claim; developer verdict: ~27× token multiplier makes the harness's quality not worth its price).
**Goal:** Same governance, a fraction of the tokens — no gate removed, no round capped, no verdict literal changed, no knowledge deleted. Full scope, mechanisms, and measured before/after in `milestones/M53-v2.6-token-diet.md`. Companion decisions: [ADR-015](decisions/015-g-specialize-diet-not-regenerate.md) (specialize: diet, not kill/regenerate), [ADR-016](decisions/016-model-economy-dispatch-matrix.md) (dispatch matrix + Haiku-executability standard).
**Process note:** Executed under the ADR-014 §3 exception — session-model workflow orchestration, not the /g-* pipeline, because this milestone rewrites the pipeline's own skills. Suites, commit gate, and the durable record still applied (baseline 772/0 across 24 suites → 1,244/0 across 37 at implementation close).

---

### M53.1 — 2.6.2 Patch: dogfooding defects + voice honesty
**Status:** ⬜ Not started
**Version:** v2.6.2 — patch: four defects in shipped 2.6.1, no new capability, no contract change.
**Goal:** 2.6.1 stops doing things it does not claim to do.
**Why split from M54 (developer, 2026-09-02):** these were briefly folded into M54 and pulled back out — they affect every current install, M54 is a documentation pass gated behind a 16-finding DOCS HOLD, and shipping four live defects behind a docs milestone delays fixes adopters are already running.
**Scope:**
- **`agents/references/` mis-registers as 15 dispatchable agents.** The loader treats everything under `agents/` as an agent, so 15 reference documents surface as `g-forge:references:*` agent types (observed live at `/reload-plugins`, 2026-09-02: "41 agents"). Move the directory or teach the loader to exclude it. Pin with a test asserting the dispatchable-agent count equals `ls agents/*.md`.
- **`skills/g-init/scripts/scaffold.sh` mints a duplicate M1.** Tests for the literal `g-docs/milestones/M1.md`, not `M1-*.md`; on this repo it created an empty skeleton beside the real `M1-foundation.md`. Pin with a test.
- **`skills/g-specialize/scripts/detect-stack.sh` reads roadmap keywords as detections.** Reported 12 stacks on this repo where 1 is real — `claude-plugin` from `source=deps`, 11 more from `source=roadmap` because the ROADMAP documents the supported-stack catalog. Any project whose docs *name* stacks gets false positives. Weight `deps` over `roadmap`, or drop `roadmap` as a detection source.
- **`.claude/voice-profile` is written but not honoured.** `dev` means "terse, assumes you know the jargon" (`g-docs/voice-profiles.md`); observed output on a `dev` seat was multi-section reports with tables and restated context for one-line questions (developer feedback, 2026-09-02: "you're too verbose with the user"). Either the skills' output templates are verbose regardless of profile, or nothing actually reads the file at render time — establish which before writing a fix, and pin whatever the contract turns out to be.

**Constraint:** patch release — no scope beyond these four. Run `tests/run-all.sh` before and after; baseline 1370/0 across 38 at `c24d594`.

**Depends on:** — (independent of M54; ships first)

---

### M54 — Wiki & README Currency Pass
**Status:** 🔄 In progress — waves 1–4 executed 2026-09-02, `/g-doc-review` returned DOCS HOLD; fix round outstanding (code defects split to M53.1). Nothing committed.
**Version:** v2.7.0 — minor: the public documentation surface is restructured and the front door changes shape (adopter-visible), and no executable behaviour changes. *(The code defects briefly folded in on 2026-09-02 moved to M53.1 / v2.6.2 the same day, so the original rationale stands as written.)*
**Goal:** Everything G-Forge says about itself is true, and reachable from the front door.

**Execution record (2026-09-02):** plan `plans/m54-wiki-readme-currency.md` (per-wave Progress notes carry the incident record) · forecast `forecasts/m54-wiki-readme-currency.md` (complexity 7/10, 90% High; it recommended splitting, developer proceeded whole) · wave records `agent-output/wave-{1..4}/` · gate verdict `agent-output/wave-4/task-6c-doc-review.md` (293 lines, **16 blocking + 7 warning**). Delivered: wiki 471→851 lines with `g-wiki/reference.md` new; README 801→388; suite 1370/0 across 38 = baseline, `tests/` undiffed.

**Scope:**
- Rebuild `g-wiki/architecture.md` (last touched 2026-08-18), `g-wiki/commit-gate.md` (2026-07-23), and `g-wiki/usage.md` (2026-08-17) against v2.6 source — all three predate the token diet
- Document the five v2.6 concepts absent from the wiki body: the lazy `references/` layer, the `scripts/` layer, the dispatch matrix ([ADR-016](decisions/016-model-economy-dispatch-matrix.md)), delta review rounds, and the review pack
- Deepen `usage.md` from a heading-list (229 lines / ~1,123 words) into actual instruction — ideal workflows, with opinion labelled as opinion
- `g-wiki/README.md` current-state line → v2.6.1 (currently reads "v2.6.0 released")
- Wiki links out to the existing `g-docs/` reference layer so it stops being unreachable: `env-vars.md`, `integration-tiers.md`, `voice-profiles.md`, `memory-taxonomy.md`, `telemetry-metrics.md`, `orchestration-patterns.md`, `agents.md`
- Thin `README.md` (801 lines / ~10,056 words — 2.4× the entire wiki): relocate reference-shaped bulk (the Skills/Agents/Stack Profiles block, ~157 non-blank lines) to the wiki, retain the sell and install, add a table of contents linking every wiki page
- Fix `README.md:40` — the heading reads `### What's in 2.5` at v2.6.1, contradicting the version strip at `:5`
- ~~Decide the currency guard~~ — **DECIDED 2026-09-02 (developer): narrative convention only.** No new pinned-claim tests; wiki pages declare themselves narrative and `/g-doc-review` checks claims against source at each gate. Shipped as the Currency note in `g-wiki/README.md`.

**Fix round, 2026-09-02 — clear the DOCS HOLD.** *(The three shipped-code defects folded in earlier the same day were split back out to **M53.1 / v2.6.2**, which ships first — see that block. M54 stays a documentation milestone.)*

- **Fix round — 16 blocking + 7 warning** from `agent-output/wave-4/task-6c-doc-review.md`. Take as two sub-passes (the split the forecast asked for, boundary now self-evident), re-gating after each rather than once at the end: **(1) wiki currency** — 11 findings in `architecture.md` (7), `usage.md` (4), `commit-gate.md` (1), `g-wiki/README.md` (1); **(2) README front door** — 3 findings: `:24` still asserts "G-Forge 2.5 is the last feature release" two releases after [ADR-014](decisions/014-v26-token-diet-reopens-after-freeze.md) superseded it (**the original `README.md:40` scope item above is NOT closed — only the heading was reworded**), `:17` claims 13 ADRs against 16 on disk, and `:259`/`:314` point at `g-wiki/reference.md` for rules/presets/design-patterns/dispatch-rules/single-use content that page does not hold (pointers aimed at the new page without checking the content landed there).
- **Correct the reference-layer fact everywhere it appears.** The lazy-reference layer has **three** homes, not two: `skills/*/references/` (63), `rules/references/` (9), `agents/references/` (15 files, read by 12 agent bodies). HQ omitted the third from the ground truth it handed the gate, so `architecture.md:36`'s in-pass correction resolved the wrong way and `:34` still asserts agent references do not exist. `CHANGELOG.md:30` and `milestones/M53-v2.6-token-diet.md:13` say three homes / 113 files; disk says three homes / 87. Three documents, three figures — sweep the string class, not the flagged line.

**Constraint:** `tests/test-readme-counts.sh` pins three README sentences by exact regex shape (agents/skills/profiles, doctor-checks with its required/advisory split, and the Agents-section repeat). Treat them as frozen literals or update the test in the same commit; run `tests/run-all.sh` before and after. **Second pinning suite, found the hard way 2026-09-02:** `tests/test-lib-install-completeness.sh` also reads README, requiring all six `.claude/hooks/lib/*.sh` named by literal path — the thinning removed that manifest as collateral damage of the Playbook cut and took the suite red (1364/6) before it was restored into `### Set up`. **Run `grep -l README tests/*.sh` at plan time; the constraint above naming one suite is what caused the miss.**

**Premortem:** Scope blow-up on the README (**high**) — "thin it" has no stopping condition; fix the target at plan time, not during execution. False-claim minting in fix prose (**high**) — the top carry-over from the 2026-08-31 D1 retro was five false or unpinned claims in one gate arc, four minted in a round's own fix prose; a doc rewrite is the maximum-exposure case, so every structural claim cites a path and `/g-doc-review` checks claims against source, not plausibility ([ADR-013](decisions/013-derive-in-consumers-keep-counts-in-prose.md) rule 2). Breaking the counts test (**medium**) — see Constraint.

**Premortem — outcome, 2026-09-02.** All three fired. Scope blow-up: pre-empted, the developer fixed the README target at the Step-0 gate ("explain and sell its value, no silly AI numbers blurb, TOC of the g-wiki, install guides and first steps") and it held — 801→388. False-claim minting: fired hard, and **from HQ as much as from the agents** — HQ's spot-check caught four false claims in wave-2 prose, then HQ's own inline correction of one went the wrong direction on a fact HQ had itself supplied wrongly, and the gate found 16 more. Counts test: survived byte-identical; its *unlisted sibling* broke instead. New premortem entry for the fix round: **fix prose is where this milestone's defects are minted, so the fix round is higher-risk than the build round was** — re-gate per sub-pass, prefer deletion over rewording (deletion-form fixes closed the D1 arc, rewording never did), and sweep every corrected claim for surviving twins before closing it.

**Process finding (feed to `/g-patterns`):** doc-writer dispatches capped at ~10 turns on **5 of 5** attempts this pass, each having written nothing at the cap — HQ shaped every task as "read the tree broadly, then author a full page", which is two jobs against a one-job budget the F3 retro already records (≈10 calls ≈ 6 edits). Recovery was continuation, not redeploy: a turn-cap stop is not a `FAILED` approach, so §C single-use does not bar it. Durable fix: split research from authoring, or hand the agent its source set pre-derived — the one dispatch built that way (wave 3) still capped but produced the whole deliverable.

**Depends on:** —

---

### M55 — Adoption Doctrine: M0 + FAQ
**Status:** ⬜ Not started
**Version:** v2.7.1 — patch: additive pages into an established structure, no restructuring.
**Goal:** Tell adopters when to reach for G-Forge — and when not to yet.
**Scope:**
- The M0 approach captured as an ADR first, then rendered as a wiki page: a "do it all" prompt to a top-tier model (Opus/Fable) → prototype testing → small iteration until the foundation is right → G-Forge takes over to ship it
- FAQ page seeded only from real friction — `g-docs/field-reports/2026-08-10-keyline-francesco.md`, `g-docs/field-reports/2026-08-28-g-sharp-telemetry.md`, the 15 `**Consumers:**` lines in `CHANGELOG.md`, `g-docs/retros/`, and `g-docs/todo.md`. Any entry not traceable to a real friction point is cut.
- Propagation: `/g-init`, `/g-kickoff`, `/g-onboard`, `/g-train` currently assume you start with G-Forge, which the doctrine contradicts by implication — run `/g-blast-radius` at plan time rather than trusting that four-skill guess

**Premortem:** The doctrine is a position rendered as fact (**high**) — if the page reads like documentation, adopters take it as tested behaviour; `/g-adr` first, so it carries a reversibility check and its own premortem and the page renders a recorded decision. Doctrine collides with the brief's non-goals (**medium**) — `project_brief.md` explicitly rejects "autonomous AI-dispatches-AI" and "swapping humans for brains", and an M0 that hands everything to a top-tier model sits close to that line; `/g-align` confirms rather than assertion. FAQ invents its own questions (**medium**) — see the seeding constraint in Scope.

**Cross-cutting note (G-RULES §B):** M55 introduces a cross-cutting position, not an isolated page — the propagation item above is part of the done condition, and the architecture-review gate confirms no touchpoint was missed. M54 adds no cross-cutting primitive.

**Depends on:** M54 — M55's pages need a settled page structure and a TOC slot to land in.

---

## Backlog

### Context-budget gauge — G-Forge measures the wrong thing, from the wrong seat *(added 2026-08-29, developer directive; G-Proof R0 candidate, not 2.5)*

**Evidence, this session (M52 Session B):** the §A7 amber banner fired at ~15 exchanges. `/context` at that moment read **40% used** (397.5k / 1M) — past the 25%-used floor by 15 points, on the session *after* Session A had already closed at 28%. The proxy fired late twice running, on the same milestone, in the direction the rule exists to prevent.

**Four defects, one root cause — the gauge is a proxy read from the wrong seat:**
1. **The exchange count is not the budget.** `hooks/workflow-checkpoint.sh` counts prompts; a prompt that dispatches three gate rounds and edits twenty files costs the same as "yes". The offset auto-calibration (`.claude/context-threshold-offset`) tightens only on *compaction*, so a 40%-used session that never compacts teaches it nothing.
2. **The model cannot read the real gauge.** `/context` is a local terminal command; its output is not a tool result. HQ can *instruct* the developer to run it and cannot run it itself. On Remote Control the developer sees it and the model does not unless the output is pasted back — which is what happened here.
3. **The gauge the model *can* see lies by proximity.** The session-budget counter (`total_tokens` remaining, ~15M) sat at ~1% consumed while the window was at 40%. Different quantity, same shape, adjacent in the model's view — HQ read it as reassurance. Nothing in G-RULES names the two apart.
4. **The banner itself reads the retired direction** — "the moment remaining capacity drops below 25%" (`hooks/workflow-checkpoint.sh:271,:279`), the exact wording the developer corrected on 2026-08-19 and Task 15 un-cut in rule text today. Task 14 owns the hook; noted here because the gate contradicted its own rule while firing.

**Shape of the fix (design, not a patch):** the gate needs a signal that is (a) the actual window fill, not a proxy, (b) readable by the model without a human relay, and (c) explicitly distinct from the session budget. Candidates in rough order — a hook that reads the platform's context figure if any surface exposes it; failing that, a per-turn token accumulator from the hook payloads (`observe.sh` already sees every tool call) rendered as a window-fill estimate; at minimum, a G-RULES §A7 line naming the budget counter as *not the window* so HQ stops misreading it. Rebuild map: the context estimator is a DIES/TRANSFORMS component (M51 item 7 was its deletion case), so this is R0 scope — but the §A7 *rule* survives, and the rule is only as good as its gauge.


*2026-08-28 (ADR-012 amendment 4): the five 2.5 milestones dropped by the minimal freeze (M38, M41, M43, M49, M50) plus M51 items 1/7/10 and M40 Waves 2–3 are archived, committed, in `archive/roadmap-dropped-2026-08-28.md` — G-Proof candidates decided at R0, not pre-committed to the G-Proof roadmap.*

*Emptied 2026-08-10 ([ADR-012](decisions/012-g-forge-2.5-final-release-scope.md)): both candidates (multi-session orchestration, unified provenance) are fork-bound and moved to `g-docs/g-proof-roadmap.md` — **a committed, tracked file** since 2026-08-21 (`45e21ad`, gaps A9 developer directive; `.gitignore:67` records the un-ignore). It was local-only and gitignored by developer choice from 2026-08-10 until then; that is retired, so the file forks with the repo and the hand-carry fork-checklist item is retired with it.*

## Version Plan

```
v0.8.1 → v0.9.0 (M8) → v0.10.0 (M9) → v0.11.0 (M10) → v0.12.0 (M11)
       → v0.13.0 (M12) → v0.14.0 (M13) → v0.15.0 (M14) → **v1.0.0 (M15) ✅ shipped**
       → **v2.0.0 (M23) ✅** → **v2.0.1 (M24 + stack implementers) ✅** → **v2.1.0 (M27 — doc-review gate) ✅** → **v2.2.0 (M28 — g-docs canonical tracking) ✅**
       → **v2.3.0 (M-audit-2026-07 — Forge Integrity; upgraded from v2.2.2 — W1 is new capability, not fixes; ships the first README status strip + starts the CHANGELOG/README currency convention)** → **v2.4.0 (M46 — Update Integrity: /g-update staleness preflight + checkpoint direction fix + detect/diagnose/fix split; inserted 2026-07-23 — G-Cash stale-cache incident)** → **v2.4.1 (M47 + M48a–e + all post-2.4.0 fixes on `main` — intermediate cut at the M48-family close, shipped 2026-08-24; [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) amendment 2026-08-22) ✅** — further intermediate patch cuts remain candidates at each family close → **v2.5.0 — THE FINAL G-FORGE RELEASE**, hand-cut 2026-08-31 as **M52 — Minimal Freeze** at the close of the F1–F3 audit cycle and the Session D gates (was Sunday 2026-08-30 — F1–F3 amendment, 2026-08-30) (ADR-012 amendment 4, 2026-08-28: the copy follows reality; the M41-cuts-it / M51-defines-it sequencing that follows is retired history) ([ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10 — single final release label, no v2.6+ ever ships from this repo; that ADR's "full announced scope" clause is **retired by its 2026-08-28 amendment 4** and is not what 2.5.0 contains). **Build order: retired 2026-08-28** (ADR-012 amendment 4) — M52's audit-and-release sessions replace it (`g-docs/plans/v25-minimal-freeze.md`); the nine-milestone chain it replaced, and every entry dropped with it, are preserved in full at `archive/roadmap-dropped-2026-08-28.md`. Already shipped into 2.5: Check 24 injection detector, `/g-init` lib-install fix (`ec9bf8a`). After v2.5.0: this repo freezes (maintenance-only), the tree forks, and **G-Proof 1.0 ships from the fork as the rebuild's release vehicle** (ADR-010 — versioning restarts; no G-Forge 3.0). Everything fork-bound (M25, M26, M29–M37, M39, M42, M44 + both backlog candidates) lives in `g-docs/g-proof-roadmap.md` — committed and tracked since 2026-08-21 (`.gitignore:67`), so it forks with the repo; the earlier local-only/hand-carry arrangement is retired (see the Backlog note above). Release comms: `g-docs/communication-plan-2.5.md` (copy approved 2026-07-28; README publication happened 2026-08-10 by recorded developer override of its §4 timing rule — the remaining surfaces publish at release).
```

**Chain amendment, 2026-09-01 (developer; [ADR-014](decisions/014-v26-token-diet-reopens-after-freeze.md)).** v2.5.0's "THE FINAL G-FORGE RELEASE" label above is retired history — kept verbatim per the dated-record convention, superseded here: the chain continues **→ v2.6.0 (M53 — Token Diet)**, and the freeze/fork sentence no longer governs (this repo resumes releases; the G-Proof fork remains a future plan, unscheduled). ADR-012 stands for what 2.5 contained, not for finality.

**Chain amendment, 2026-09-02 (developer, at the M54/M55 roadmap gate).** The chain continues **→ v2.7.0 (M54 — Wiki & README Currency Pass) → v2.7.1 (M55 — Adoption Doctrine: M0 + FAQ)**. A **3.0-and-freeze** cut was weighed at this gate and declined on three grounds: [ADR-010](decisions/010-full-rebuild-on-current-platform.md) is Accepted and untouched by ADR-014 (which supersedes only ADR-012's finality claim), and it allocates the major slot elsewhere — the rebuild forks this tree and ships as "G-Proof, first released as **1.0**, not a 2.x release"; the previous freeze held for **one day** (v2.5.0 shipped 2026-08-31, ADR-014 reopened development 2026-09-01), so a second finality claim would carry less credibility than the first; and semver does not support a major for a documentation pass — nothing breaks and no public contract changes. **No freeze is declared here.** Should freezing return to the table it goes through `/g-adr`, not a version choice at a roadmap gate: it would supersede part of ADR-010's delivery shape, and ADR-010 attaches its own discipline (freeze, publish no roadmap with the announcement, fork, G-Proof 1.0). Sequencing note recorded with the decision: stale documentation is the same class of defect as the ~27× token multiplier that broke the last freeze — a defect the author cannot live with — so the docs pass is what makes a freeze able to hold, not what ships as one.

MVP cut: M9 + M10 + M11 — context structure + failure detection + intelligent planning with premortems.

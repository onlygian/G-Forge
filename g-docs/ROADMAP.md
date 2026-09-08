# G-Forge

> Multi-agent Claude Code plugin — planned execution, production architecture, enforced review.

> **⚠ Open chore — check the global git identity** *(added 2026-08-13; delete once verified)*
>
> GitHub handle changed from `hllrm` to `onlygian`. This repo's remote and its per-repo `user.name`
> are already corrected. `~/.gitconfig` is the gap — it was out of reach during the rename sweep and
> is probably still on the old handle. Per-repo settings do nothing for a repo that does not exist yet,
> so the first fresh clone reintroduces the problem.
>
> Check `git config --global user.name`; if it reads `hllrm`, set it to `onlygian`.

## Active Session

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — g-forge | branch: main | main @ v2.2.1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · **Released v2.2.1** (alveria-forge fixes #25/#26 versioned; full gate cycle self-hosted). · **Root-stray cleanup:** M1–M15 milestone files → `g-docs/milestones/` (only surviving record of M6–M15 drift); legacy brief + todo → `g-docs/archive/root-legacy/`; M27 retro committed. · **Full 3-agent audit** (structure / enforcement / consistency — ~49 findings triaged into M-audit-2026-07). **Headline: two stacked fail-opens found LIVE** — (1) hook matchers were `Bash`-only, so on Windows (PowerShell tool) the gate/cleanup/observer never fired; (2) installed `.claude/hooks/` copies had drifted pre-M27 (Bug A still active locally, doc sentinel never cleared) and nothing could detect it. · **Quick wins merged (`4158ffa`, W0 of M-audit):** matchers → `Bash\|PowerShell` in g-init/g-update + tests 17–18; /g-update Step 6a now syncs the 10 g-rules sections; count → 38. Local hooks realigned + gate loop proven live (deny unsigned → deny same-call smuggle → pass earned → auto-clear). **Downstream projects must run /g-update.** · **Roadmap resequenced (approved):** M-audit-2026-07 (v2.2.2) inserted first; **M35 Memory Forge** (v2.4.0 — linked/layered memory, real `context:` loader, graph-walk /g-resume, opt-in Obsidian) slotted after M29, before M33-B, so shared-state milestones build on the memory substrate. **Bug A (critical):** the commit gate was a NO-OP — `check-commit.sh` used `exit 1` on block paths, but PreToolUse only blocks on `exit 2`/JSON deny, so commits ran anyway (the headline differentiator, broken through v2.2.0, invisible because the test asserted exit 1). Now: `deny()` → deny JSON on stdout + exit 2; test asserts real blocking. **Bug B (high):** review pipeline failed open — a security `High` mapped to no orchestrator bucket → PASS → MERGE READY. Now: orchestrator normalizes (security High→Critical) + any-axis-HOLD⇒FAIL + `AXES:` line honored by code-lead. **Bug C:** auditor return-scales aligned to bodies. New `tests/test-review-severity.sh` (9) pins the contract. **The enforcement layer actually enforces now.** · **M33 — the Roundtable** BUILT (Phase A) + dual-surface validated LIVE (Confluence in-place v1→v2 · Gmail floor draft-and-nod · Drive eliminated). · **ADR-001** (surface adapter + tiers) · **ADR-002** (one HUMAN orchestrator seat, never co-chairs, owns `main`). · **M34 scoped** (cross-session dependency tracking + pull/push, suggest-not-act). · Table→Roundtable rename; cross-cutting propagation rule (g-rules-B + /g-roadmap/g-plan); `/g-resume` polish; project_brief.md created. (10 PRs merged: #17–#26.) · **M29 spec refined + de-risked (master seat, on `claude/g-resume-dogfood-0vu50d`):** A4 step-one **confirmed LIVE** — the official Gmail MCP exposes labels as a mutable register field (`list_labels`/`create_label`/`label_thread`/`unlabel_*`) → build commits to the **Gmail-labels variant** (Drive-doc fallback); two gaps pinned to design — no-CAS (A1 tiebreak+re-read is load-bearing) · shared-account identity (holder/session id lives *in* the claim payload, per A2). Fixed M29 premortem inconsistency ("ship Discord first" → ship official Google first; Discord is community/unofficial, never the reference). · **ADR-003 — Cowork is NOT a G-Forge host** (evaluated on GA): Cowork doesn't fire `.claude/` hooks (#63360/#40495), so the commit gate + enforcement are inert there → CLI/web/Actions stay primary, CLI not deprecated. Cowork-as-future-shared-*surface* (M29/M33 backend) survives; re-probe when Cowork honors hooks.
Next up:          · **M-audit-2026-07 Wave 1 (P0 enforcement integrity)** — /g-doctor installed-copy drift check, commit-detection hardening, sentinel lifecycle design (items 8–10 spike/ADR first), hook test coverage. Then ship v2.2.2. · **Then M29 Phase A — the register.** Start FRESH. A4's mutable-field question answered (Gmail labels ✓); Phase A proves: is convention (tiebreak + re-read, no CAS) enough? A1 schema → A2 identity/lease → A3 adapter → A4 Gmail-labels adapter over remote MCP, then the two-session collision test. · Then M35 Memory Forge (v2.4.0) → M33 B–D (v2.5.0) → M34 → M30–32. · M26 (deferred) · M25 (compute-gated).
Active context:   · main @ v2.2.1 + quick-wins merge (`4158ffa`); v2.2.2 ships when M-audit W1 closes. Arc sequence: **M-audit-2026-07 → M29 → M35 → M33 B–D → M34 → M30–M32.** M-audit 🔄 (W0 done, W1 next — items 8–10 need spike/ADR before code); M29 + M34 ⬜ specs in g-docs/milestones/; M35 spec written this pass. Cleanup queue unchanged: Confluence page 109314050 + Drive doc + stale `g-table` Gmail labels — delete or keep as fixtures. Windows note: hook matchers + installed-copy drift were fail-open here — see memory `windows-hook-gotchas`. Re-enter with /g-resume.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

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
**Version:** v2.1.0 (docs-only; ships with the next release)
**Goal:** State what G-Forge actually is, and define how to prove it.
**Scope:**
- [x] Reposition README + marketplace + plugin descriptions around "educated, enforced project management" (governance layer, not another agent orchestrator) — grounded in the 107-agent landscape research.
- [x] `g-docs/benchmark.md` — reproducible reliability-benchmark methodology (model + G-Forge vs. raw, scored on success rate + the 8 `/g-telemetry` metrics).

**Depends on:** M23. *(Committed on `claude/m23-release-u3rx0d` (`8a20f92`); lands on `main` with the next merge.)*

---

### M25 — Run the Reliability Benchmark
**Status:** ⬜ Not started
**Version:** v2.1.0 (or whenever the number ships)
**Goal:** Turn "punch above its weight" from a claim into a defensible, published number.
**Scope:**
- [ ] **Pilot first** — run the 2–3 task B-vs-A pilot in `g-docs/benchmark.md` to shake out the harness and check for signal on a multi-file / architecture-touching task.
- [ ] **Gate:** only fund the full run if the pilot shows a lift; a null result on a task class is recorded honestly and stops the spend.
- [ ] Full benchmark (n ≥ 20, arms A–D), blind mechanical scoring, the chart + 8-metric table.

**Premortem (per `/g-roadmap` Step 3b — this milestone was added, so it ran):**
- *Harness is the real cost, not the run* — automating the G-Forge arm headless (plan→execute→review) is eval engineering; mitigate by piloting on 2–3 tasks before building the full runner.
- *Operator confound* — the G-Forge arm must be driven by a fresh model session executing the plugin, never hand-simulated, or the result is meaningless.
- *Task-class dependence* — lift concentrates on multi-file/architecture work; report per-class, never a single blended number.
- *Skeptical market* — a sloppy number is net-negative (87% distrust accuracy); do not publish until n and scoring are defensible.

**Depends on:** M24 (methodology), and a session/compute budget allocated to run it.

**Re-prioritization:** M25 sits after M24 and is gated on a pilot — it does not block any other planned work; the run happens when compute is deliberately allocated.

---

### M26 — Provable Wave Dispatch (Workflow-script execution engine)
**Status:** ⬜ Not started (deferred — re-slot after the M-audit → M29 → M35 arc)
**Version:** TBD when re-slotted (v2.3.0 reassigned to M29 in the 2026-07-01 resequence)
**Goal:** Make `/g-execute`'s fan-out *provable* rather than instructed — without G-Forge becoming "another agent orchestrator." This enforces the existing orchestration contract; it does not add a new one.
**Scope (additive opt-in — prose dispatch stays the default and the fallback):**
- [ ] Feasibility spike + design note (`g-docs/g-execute-engine-design.md`) — Workflow-tool availability detection from a skill, plugin-shipped `scriptPath` invocation, wave-plan→`args` contract, and where the per-wave `/context` capacity gate relocates once the loop is backgrounded. **Gates the build.**
- [ ] `skills/g-execute/wave-runner.workflow.js` — deterministic `parallel()` fan-out, per-wave barrier, `RESULT`-block parsing, and journal/Progress/agent-output writes **identical to the prose path**.
- [ ] Script retry/BLOCKED control flow — attempt counter, Three-Strikes ceiling, escalation-log; the §A8 "different mechanism" choice stays a model `agent()` callback (loop in script, *judgment stays model-made*).
- [ ] `skills/g-execute/SKILL.md` Step 3 opt-in branch + `.claude/execution-engine` sentinel + `/g-doctor` surfacing; prose path byte-for-byte unchanged when opt-out.
- [ ] Dual-execution-model docs + parity runbook.

**Tier 3 DoD:** Parity run — a 3-task wave (one forced-FAILED) through *both* paths yields identical FILES, `.claude/journal` + Progress-table writes, commit-gate behavior, and retry-ceiling stop.

**Forecast (advisory):** Complexity 7/10 · Miss-risk ~50% (Elevated) — risk concentrated in the spike; clean spike drops it to Moderate. Top scenarios: spike fails (→ reshape to "document the pattern"), orphaned capacity gate, parity drift, retry degradation, two-path maintenance tax.

**Depends on:** M23. Independent of M24/M25.

**Re-prioritization:** Deferred to v2.3.0 behind M27 (developer's call). Internal orchestration mechanism, spike-gated; nothing depends on it, so it slots last among non-completed milestones.

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
**Status:** 🔄 In progress (Wave 0 shipped as the audit-quick-wins merge)
**Version:** v2.2.2
**Goal:** Resolve the 2026-07-01 three-agent audit findings — enforcement layer provably enforces, drift detectable. Full prioritised tables in `g-docs/milestones/M-audit-2026-07.md`.
**Scope:**
- W0 ✅ quick wins: Windows matcher fail-open, /g-update g-rules sync gap, skill count (merged `4158ffa`)
- W1 (P0): installed-hook drift detection in /g-doctor; commit-detection hardening (`-C`/`-c`/`-a`/alias); sentinel lifecycle (content-binding, terminal-commit staleness); worktree-gating design spike; test coverage for the 5 untested hooks
- W2 (P1): SKILL.md conformance (argument-hint ×9, Announce ×3, Rules ×3, Steps ×2); architecture-enforcer verdict alignment; /g-forge router roundtable row; agent-class taxonomy + `context:` carve-out in the claude-plugin architecture rules
- W3 (P2, deferrable): 10 minors

**Depends on:** —

---

### M29 — Multi-session coordination (claim/lease for concurrent sessions)
**Status:** ⬜ Not started (scoped, awaiting go)
**Version:** v2.3.0 (minor — the register is a new capability)
**Goal:** Stop concurrent sessions from silently colliding on milestone numbers, branches, and the handoff — by coordinating through a shared, MCP-reached surface, with three pluggable backends behind one adapter, degrading cleanly to today's git handoff when none is configured.
**Scope (phased):**
- [ ] **Phase A — core + first adapter:** surface-agnostic claim protocol + register schema (resource = milestone/branch/wave; claim = holder/session/ts/lease/status), session identity + signed writes + lease/heartbeat + stale-claim reclaim, a capability-flagged adapter interface (`push|poll`, `cas|convention`, identity), and the **Google (Gmail/Drive)** reference adapter — official MCP, the flow+floor — to answer "is convention enough?" (ships as a standalone gating spike; rest of the arc proceeds on its verdict)
- [ ] **Phase B — workflow integration:** collision check in `/g-roadmap` + `/g-plan` (fetch + warn + offer alternatives before assigning), hook surfacing of others' active claims + heartbeat in `workflow-checkpoint.sh`/`session-start.sh`, release on milestone close. Honors tiers (off on `light`).
- [ ] **Phase C — setup, health, more adapters:** **Confluence** adapter (version-CAS = real lock) + optional **Discord** adapter (real-time, **community/unofficial MCP — flagged**), `/g-init` opt-in setup wiring a **remote MCP into `.mcp.json`** (tokens via env-var, never committed) + `/g-doctor` reachability check, graceful degradation + docs.

**Position:** phase one of **multiplayer G-Forge** — full multi-user cooperation on one project ("human orchestration, powered by humans"), a framework that engages whenever >1 session/user is live and degrades to single-player when alone. M29 is the claim/lease substrate; **assignment-by-person, cross-person handoff, cross-person review, and reconciliation** are later phases of the arc (not cut). Permanent line: humans orchestrate — no autonomous AI-dispatches-AI, no hosted authority.

**Cross-surface requirement:** each adapter's MCP must be **remote HTTP/SSE in `.mcp.json`** so cloud / Slack / GitHub-Actions sessions can reach it (local stdio servers are invisible to those surfaces). Same property that makes G-Forge enforcement travel — committed config follows you everywhere.

**Premortem + done condition:** full breakdown in `g-docs/milestones/M29-multi-session-coordination.md` (top risks: credential leakage · convention races on Gmail/Discord · local-vs-remote MCP divergence · stale claims · scope creep). Promoted from the backlog candidate below; this is the milestone version of it.

**Re-prioritization:** promoted to the **next buildable milestone → v2.3.0**, ahead of the deferred M26 — M26 is spike-gated with nothing depending on it, while M29 is buildable now and strategically central (governance scaled to teams, per M24). Its Phase A doubles as the **de-risking spike for the whole arc** — it answers "is convention enough?" before M30–M32 commit. (M25 stays a parallel compute-gated track.)

---

### M30 — Membership, presence & assignment  *(multiplayer arc — sketch)*
**Status:** ⬜ Sketch (provisional — firms up after M29 ships)
**Goal:** Know who's on the project, and let work be owned by *people*. The layer where the multiplayer framework's identity and activation live.
**Scope (sketch):**
- Membership roster + stable per-member identities (built on M29's session identity).
- Live **presence** / heartbeat → "who's active, and on what."
- **Assignment:** an owner on milestones / waves / tasks; `/g-roadmap` + `/g-plan` can assign to a person.
- **Activation rules:** the framework engages when >1 identity is present, is tier-gated, and degrades back to single-player when alone.

**Premortem (sketch-level):**
- *Session-identity vs person-identity conflated* (med) — a person across machines/sessions must map to **one** identity or presence + assignment fragment. → Make person-identity primary in M30; session-ids map onto it (carried deliberately from M29).
- *Presence flap* (med) — noisy/stale heartbeats toggle the framework on/off. → TTL + debounce on presence; activation **hysteresis** (don't switch on a single missed beat).
- *Toothless or rigid assignment* (med) — "owned by X" is either a meaningless label or a hard block. → Assignment = advisory claim with logged override (reuse M29 claim semantics), not a lock.

**Depends on:** M29 (identity, register, heartbeat).

---

### M31 — Cross-person handoff & review  *(multiplayer arc — sketch)*
**Status:** ⬜ Sketch (provisional)
**Goal:** Make handoff and review cross *people*, not just sessions.
**Scope (sketch):**
- **Person→person handoff:** the `## Active Session` block generalizes from session→session to person→person; `/g-resume` can re-hydrate from a teammate's handoff.
- **Cross-person review gate:** `/g-review` / `/g-doc-review` can require approval from a *different* member; the approval sentinel is keyed to approver identity.
- **Notifications** via the chosen surface ("@you — review requested on wave-3").

**Premortem (sketch-level):**
- *Cross-person review deadlock* (high) — A needs B's approval, B is offline → work stalls. → Timeout + logged self-approve fallback (tier-gated); async notify; cross-approval never unconditionally mandatory.
- *Handoff race reintroduces the M29 collision* (med) — concurrent person→person edits to the one `## Active Session` block. → Per-member handoff lanes, or treat the handoff itself as an M29-claimed resource.
- *Untrustworthy identity-keyed sentinels* (low–med) — approver identity in the gate sentinel must be forgeable-proof. → Signed approvals tied to M30 identity.

**Depends on:** M30 (identity/assignment), M29 (register/log).

---

### M32 — Reconciliation of concurrent work  *(multiplayer arc — sketch)*
**Status:** ⬜ Sketch (provisional — hardest phase; spike-gate before building)
**Goal:** When people work concurrently, reconcile branches / waves with conflicts **surfaced**, never auto-merged behind anyone's back.
**Scope (sketch):**
- Detect overlapping file-sets / waves across members (uses M29's claim granularity).
- Conflict surfacing + **guided** reconciliation — who integrates, in what order.
- A team convention for "who owns `main`" and ordered integration.

**Premortem (sketch-level):**
- *Scope blow-up into a full merge/consensus engine* (high) — "who owns `main`" distributed coordination is the hard part and easy to overbuild past the governance lane. → Spike-gate; ship "surface conflicts + recommend an integration order," **never auto-merge**; auto-resolution is an explicit non-goal.
- *Fuzzy done condition* (high) — "reconcile concurrent work" is vague. → Done = overlapping file-sets/waves across members are **detected and surfaced with a recommended order**, not auto-resolved.
- *Weak overlap detection from coarse claims* (med) — if M29/M30 file-set claims aren't granular, conflict detection is blind. → Validate claim granularity upstream before M32; spike.

**Depends on:** M30, M31. This is the genuinely distributed part — feasibility-spike it before committing.

**Re-prioritization (arc):** M30→M31→M32 kept in strict dependency order; **M32 stays last and spike-gated** (highest likelihood + fuzziest done condition). The whole arc is provisional behind M29 — building M29 Phase A first is the deliberate de-risking move. **M26** (Provable Wave Dispatch) is pushed behind the arc's first release onto its own spike-gated track (nothing depends on it); **M25** unchanged (compute-gated, parallel).

> *The M30–M32 split is a **provisional sketch** of the multiplayer arc, not a commitment — the exact boundaries, sequence, and contents are expected to change once M29 is built and we learn whether convention-based coordination is sufficient. North star + framework in `g-docs/multi-session-coordination.md`.*

---

### M33 — The Roundtable (shared-doc communication layer)  *(multiplayer arc — scoped)*
**Status:** ⬜ Not started (scoped, awaiting go) — full spec in `g-docs/milestones/M33-the-roundtable.md`
**Version:** v2.5.0 (minor — Phase A shipped un-versioned; ships when Phase B lands. Follows M35 so shared digests build on the memory substrate.)
**Goal:** Give G-Forge a real-time, human-facing **communication surface** — a shared Google Doc ("the Roundtable") that is the live UI between developers, *non-programmers* (PMs, friends vibecoding a game), and their Claude sessions. State of play is visible; humans steer in plain language; live decisions/plans **distill to the durable record + action points** on a human nod. Triggerable; works **solo** or **shared**. This is the **harmonious cooperation layer** — the interface the M30–M32 mechanics render on.
**Scope (phased):** A — Solo Roundtable (`/g-roundtable start|sync|close`, templates, session rules, end-of-session distill; proves the make-or-break distill loop with one person, no M29 needed). B — Shared Roundtable (link-restricted join, lanes/presence via M29, cross-person catch-up + handoff). C — Maintenance/grooming, `/g-init` opt-in + `/g-doctor` health, templates, clean degradation. **D — Propagation** (every skill/hook/rule that assigns, plans, executes, reviews, resumes, or reports becomes lane/Roundtable-aware — per the §B cross-cutting propagation rule; gated by the architecture-review completeness check).

**Premortem (top risks — full set in the spec):**
- *Distillation quality is the whole game* (high) — lossy ⇒ intent drifts, noisy ⇒ the Doc swamps. → human nod gates every distill; salience filter on writes; the C grooming step; keep living-state small.
- *🔴 "Public" doc = data leak* (high) — a public Google Doc is world-readable. → default **link-restricted, never public**; no credentials on the Roundtable; `/g-doctor` flags world-readable.
- *Propagation forgotten — the island risk* (med) — the Roundtable works alone but `/g-roadmap`/`/g-plan`/hooks ignore it. → Phase D + the §B propagation rule + the gate completeness check. **A Roundtable the engine doesn't respect is not done.**

**Depends on:** M29 (register) for shared-mode lanes/presence; Phase A is standalone. **Relation to the arc:** M33 is the *interface* the provisional M30–M32 sketch (membership · handoff · reconciliation) renders on — when M29 ships and the sketch firms up, expect M30–M32 to reconcile against (and partly fold into) the Roundtable.

---

### M34 — Cross-session dependency tracking & pull/push orchestration  *(multiplayer arc — scoped)*
**Status:** ⬜ Not started (scoped, awaiting go) — full spec in `g-docs/milestones/M34-cross-session-orchestration.md`
**Goal:** Make G-Forge's single-session orchestration work across **many sessions/users** — surface a live **who-depends-on-whom** graph and turn it into **git coordination suggestions** (pull / push / coordinate), all **advised, never automated**. The "super important" part: the orchestration *is* the product; the Roundtable is where it becomes visible.
**Scope (phased):** A — Dependency declaration & graph (extend the M29 claim with `depends-on`; `/g-status` renders blocked-by/blocking — the spike). B — Pull/push suggestion engine (graph + git ahead/behind → advisories at boundaries, salience-gated). C — Roadmap-update propagation (a roadmap change surfaces to everyone's Roundtable; shared re-prioritization). D — Overlap + cycle detection (coordinate warnings; never auto-resolve).

**Premortem (top risks — full set in the spec):**
- *Suggestion spam* (high) — advisories every boundary become noise. → salience gate: suggest only on a state change; tier-gated; dedupe.
- *Overreach into auto-merge* (med) — the tempting next step is "just pull for them." → hard non-goal; suggest-only, the human runs every git command (inherits M32).
- *Coarse claims blind overlap detection* (med, carried from M32) → validate M29 claim granularity upstream before Phase D; spike.

**Depends on:** **M29** (claims = the substrate) + **M33** (Roundtable = the surface). **Relation to the arc:** dependency tracking is the **spine** the provisional M30–M32 mechanics (assignment · handoff · reconciliation) hang off — they are consequences of the graph M34 builds and likely **fold under** it. Degrades to single-session (no deps) when neither substrate is configured.

**Re-prioritization (arc):** M34 slots **immediately after M29**, ahead of and largely absorbing the provisional **M30–M32** sketch — assignment/handoff/reconciliation presuppose the dependency graph, so the graph is built first. Sequence within the arc: **M29 (register) → M33 Phase A (Roundtable, standalone, already built) → M34 Phase A (dependency graph spike) → M34 B–D + M33 B–D + the M30–M32 mechanics reconciled against M34**. M34 is spike-gated on its Phase A (prove the graph is legible with two sessions before the suggestion engine). M26/M25 unchanged (spike-/compute-gated parallel tracks).

---

### M35 — Memory Forge (deep memory layer + optional Obsidian surface)
**Status:** ⬜ Not started — full spec in `g-docs/milestones/M35-memory-forge.md`
**Version:** v2.4.0 (minor — new capability)
**Goal:** The distilled record becomes a linked, layered, queryable memory that `/g-resume` hydrates task-specifically — wikilink + frontmatter conventions (`g-docs/` *is* the vault), a real `context:`-layer loader (implement or retire the paper contract), graph-walk hydration, memory hit-rate telemetry, and a strictly opt-in `.obsidian/` scaffold ("viewer, never dependency" — ADR at Phase C).
**Sequence:** after M29, before M33 B–D — shared-state milestones (M33-B digests, M34 dependency records) build *on* this substrate rather than inventing their own record shapes.
**Depends on:** M29 (shared-layer design only), M-audit-2026-07

---

## Backlog

### Candidate — Multi-session / multi-operator orchestration ("orchestrating humans")
G-Forge orchestrates *agents* inside one session today. It already does **sequential, git-mediated** multi-session handoff — the ROADMAP `## Active Session` block + `/g-resume` + the observer journal are the primitives; this very session ran that way across two machines. The open question is **concurrent** coordination: can HQ in one session treat *other live sessions* (human or agent, same or different machine) as dispatchable units?

The motivating failure is concrete and already observed: a session began planning **M24** while another session had already claimed **M24/M25** — multi-session work has no **claim/lock** primitive, so parallel sessions silently collide on milestone numbers, branches, and the handoff block.

Possible scope when promoted to a milestone:
- A claim/lease primitive (e.g. `.claude/claims/` or a remote-backed lock) so a session can reserve a milestone number / wave / file-set before work starts.
- Collision detection in `/g-roadmap` and `/g-plan` (fetch + check before assigning a milestone number).
- A handoff/merge protocol for *concurrent* (not just sequential) sessions — who owns `main`, how waves from different operators reconcile.
- Decide the honest boundary: is this "orchestrating humans," or just safer git-mediated coordination? (Aligns with the M24 positioning — governance, not orchestration-for-its-own-sake.)

A brainstormed approach — coordinate through an always-available, instantly-visible **shared surface reached via an MCP** rather than git, which only propagates on push/fetch — is captured in `g-docs/multi-session-coordination.md`. Direction chosen: ship spread surfaces behind a common, extensible adapter, **leading on official MCPs** — **Google (Gmail/Drive)** as flow+floor, **Confluence** as the enterprise lock, **Discord** optional (community MCP). Scoped as M29.

*Status: **the goal is now explicit — multiplayer G-Forge** (full multi-user cooperation on one project; "human orchestration, powered by humans"). The concurrent claim/lease is **M29** (phase one, scoped, awaiting go); the cooperation layer — assignment, cross-person handoff/review, reconciliation — is the milestone arc beyond it. North star + framework captured in `g-docs/multi-session-coordination.md`.*

---

## Version Plan

```
v0.8.1 → v0.9.0 (M8) → v0.10.0 (M9) → v0.11.0 (M10) → v0.12.0 (M11)
       → v0.13.0 (M12) → v0.14.0 (M13) → v0.15.0 (M14) → **v1.0.0 (M15) ✅ shipped**
       → **v2.0.0 (M23) ✅** → **v2.0.1 (M24 + stack implementers) ✅** → **v2.1.0 (M27 — doc-review gate) ✅** → **v2.2.0 (M28 — g-docs canonical tracking) ✅**
       → v2.3.0 (M29 — multiplayer phase one) → v2.4.0+ (multiplayer arc: **M33 — the Roundtable** [Phase A standalone, already built] → **M34 — cross-session dependency tracking + pull/push orchestration**, the arc's spine, spike-gated on M29; M30–M32 mechanics reconcile against M34) · M26 (Provable Wave Dispatch) deferred to its own minor when its spike clears · M25 benchmark ships its number when run
```

MVP cut: M9 + M10 + M11 — context structure + failure detection + intelligent planning with premortems.

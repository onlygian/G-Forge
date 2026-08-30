# G-Proof Roadmap (fork-bound milestones)

> **Committed file** — tracked in git since 2026-08-21 (`45e21ad`, gaps A9 developer directive: a 42KB single-copy planning doc is a known-fatal loss pattern). ~~Local-only, gitignored by explicit developer choice ([ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10)~~ — that choice was reversed; see `.gitignore:67`.
> These milestones left `g-docs/ROADMAP.md` when the 2.5 final-release scope was settled: they ship from the **G-Proof** fork (ADR-010), never from this repo. Statuses and milestone numbers preserved as-moved; every version stamp below is STALE — versioning restarts at G-Proof 1.0.
> ~~**Fork checklist item: carry this file to the new repo BY HAND.** It is not in git; a clone or git-mediated fork will not bring it.~~ **Retired 2026-08-21** — the file is committed, so a clone or git-mediated fork brings it automatically and no hand-carry step is needed. The reason it was un-ignored stands as the warning: this repo already lost one gitignored planning file (CLAUDE.md, regenerated 2026-07-10).

---

### M25 — Run the Reliability Benchmark
**Status:** 🔄 In progress — pilot ran 2026-08-13; full run NOT funded on the current design (instrument defect, see record)
**Version:** v2.1.0 (or whenever the number ships)
**Goal:** Turn "punch above its weight" from a claim into a defensible, published number.
**Scope:**
- [x] **Pilot first** — ran 2026-08-13 (4 tasks, purpose-built `ledger` fixture substituted for SWE-bench Lite — recorded as a threat to validity). Record: `g-docs/benchmark-pilot-2026-08-13.md` (committed).
- [x] **Gate:** verdict recorded — **do not fund the n ≥ 20 run on this design**; the benchmark as specified cannot measure the claimed effect. Fix the instrument first. (`benchmark.md` carries the required-changes list from the record.)
- [ ] Full benchmark (n ≥ 20, arms A–D), blind mechanical scoring, the chart + 8-metric table — **blocked on instrument redesign**, not abandoned.

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

### M29 — Multi-session coordination (claim/lease for concurrent sessions)
**Status:** ⬜ Not started (scoped, awaiting go)
**Version:** v2.8.0 (minor — the register is a new capability; renumbered 2026-07-23 — M45+M46 inserted ahead)
**Goal:** Stop concurrent sessions from silently colliding on milestone numbers, branches, and the handoff — by coordinating through a shared, MCP-reached surface, with three pluggable backends behind one adapter, degrading cleanly to today's git handoff when none is configured.
**Scope (phased):**
- [ ] **Phase A — core + first adapter:** surface-agnostic claim protocol + register schema (resource = milestone/branch/wave; claim = holder/session/ts/lease/status), session identity + signed writes + lease/heartbeat + stale-claim reclaim, a capability-flagged adapter interface (`push|poll`, `cas|convention`, identity), and the **Google (Gmail/Drive)** reference adapter — official MCP, the flow+floor — to answer "is convention enough?" (ships as a standalone gating spike; rest of the arc proceeds on its verdict)
- [ ] **Phase B — workflow integration:** collision check in `/g-roadmap` + `/g-plan` (fetch + warn + offer alternatives before assigning), hook surfacing of others' active claims + heartbeat in `workflow-checkpoint.sh`/`session-start.sh`, release on milestone close. Honors tiers (off on `light`).
- [ ] **Phase C — setup, health, more adapters:** **Confluence** adapter (version-CAS = real lock) + optional **Discord** adapter (real-time, **community/unofficial MCP — flagged**), `/g-init` opt-in setup wiring a **remote MCP into `.mcp.json`** (tokens via env-var, never committed) + `/g-doctor` reachability check, graceful degradation + docs.

**Position:** phase one of **multiplayer G-Forge** — full multi-user cooperation on one project ("human orchestration, powered by humans"), a framework that engages whenever >1 session/user is live and degrades to single-player when alone. M29 is the claim/lease substrate; **assignment-by-person, cross-person handoff, cross-person review, and reconciliation** are later phases of the arc (not cut). Permanent line: humans orchestrate — no autonomous AI-dispatches-AI, no hosted authority.

**Cross-surface requirement:** each adapter's MCP must be **remote HTTP/SSE in `.mcp.json`** so cloud / Slack / GitHub-Actions sessions can reach it (local stdio servers are invisible to those surfaces). Same property that makes G-Forge enforcement travel — committed config follows you everywhere.

**Premortem + done condition:** full breakdown in `g-docs/milestones/M29-multi-session-coordination.md` (top risks: credential leakage · convention races on Gmail/Discord · local-vs-remote MCP divergence · stale claims · scope creep). Promoted from the backlog candidate below; this is the milestone version of it.

**Re-prioritization:** promoted to the **next buildable milestone** (v2.3.0 at the time of that decision; now v2.6.0 after the M42 + M41 insertions — the 2026-07-18 restructure moved the G-Proof rebrand to the M44 capstone, so the line stayed 2.x (⚠ that rationale is retired by ADR-010 — the line ends at v2.5; this milestone's position is unchanged)), ahead of the deferred M26 — M26 is spike-gated with nothing depending on it, while M29 is buildable now and strategically central (governance scaled to teams, per M24). Its Phase A doubles as the **de-risking spike for the whole arc** — it answers "is convention enough?" before M30–M32 commit. (M25 stays a parallel compute-gated track.)

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
**Version:** v2.11.0 (minor — Phase A shipped un-versioned; ships when Phase B lands. Follows M37 per the version plan; shared digests build on the memory substrate. Renumbered 2026-07-23 — M45+M46 inserted ahead.)
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
**Version:** v2.9.0 (minor — new capability; renumbered 2026-07-23 — M45+M46 inserted ahead)
**Goal:** The distilled record becomes a linked, layered, queryable memory that `/g-resume` hydrates task-specifically — wikilink + frontmatter conventions (`g-docs/` *is* the vault), a real `context:`-layer loader (implement or retire the paper contract), graph-walk hydration, memory hit-rate telemetry, and a strictly opt-in `.obsidian/` scaffold ("viewer, never dependency" — ADR at Phase C).
**Sequence:** after M29, before M33 B–D — shared-state milestones (M33-B digests, M34 dependency records) build *on* this substrate rather than inventing their own record shapes.
**Depends on:** M29 (shared-layer design only), M-audit-2026-07

---

### M36 — Salience Layer: Approach (priority / severity / impact / relevance)
**Status:** ⬜ Not started
**Version:** design/decision (ADR outcome — no standalone bump; the M37 build carries the minor)
**Goal:** Decide the approach for a **system-wide salience model** — how G-Forge scores **priority / severity / impact / relevance** — so every planning and governance skill reasons about "how much does this matter" instead of hand-waving it. This is the *whole layer* (roadmaps, plans, review, forecast, patterns, the arc's salience gates, G-tweak's de-gate safety), not an ADR- or G-tweak-scoped feature.
**Scope:**
- ADR (via `/g-adr`) defining the model: the four dimensions, how each is derived, and a **deterministic, documented rubric** — the model *proposes*, the human overrides, it **never auto-acts** on a score.
- First-consumer contract anchored to concrete consumers (`/g-roadmap` prioritization, `/g-plan`, the M33-B/M34 salience gates, **and M45's review-depth slot — change-class → review depth, added 2026-07-23 from the review-cost field feedback**) — not designed in a vacuum.
- Positioning vs existing scoring (`/g-forecast` risk %, `/g-telemetry` reliability, `/g-review` adaptive intensity, `/g-patterns` frequency buckets): define how salience absorbs, defers to, or complements each so M37 integrates rather than duplicates.

**Depends on:** M-audit-2026-07 (enforcement integrity must be sound before layering a cross-cutting substrate). Independent of M29 — design-only, can run in parallel. Gates M37.

**Premortem:**
- *Analysis paralysis on a "grand unified" model* (med) → timebox to an approach decision + first-consumer contract; the model can evolve.
- *Deciding in a vacuum* (med) → anchor to the named consumers, not abstraction.

---

### M37 — Salience Layer: Propagation
**Status:** ⬜ Not started
**Version:** v2.10.0 (minor — the salience substrate + its cross-system wiring; renumbered 2026-07-23 — M45+M46 inserted ahead)
**Goal:** Implement the M36 salience model and **weave it across the system** so priority/severity/impact/relevance is one shared layer, not per-skill guesswork.
**Scope (phased — do not require all consumers in one milestone):**
- Model implementation + highest-value consumers first: `/g-roadmap` (milestone prioritization), `/g-plan` (task/wave priority), and the arc's salience gates (M33-B digests, M34 suggestion salience).
- Then propagate to the rest: `/g-forecast`, `/g-review`, `/g-patterns`, `/g-adr`.
- **Cross-cutting propagation (G-RULES §B):** run `/g-blast-radius` to enumerate every skill/hook/rule that must become salience-aware; fold each touchpoint into scope; **done condition is incomplete until the architecture-review completeness gate confirms none was missed.**
- Rubric is deterministic and documented; salience **proposes**, the human overrides — never auto-acts.

**Depends on:** M36 (the approach decision). Inserted **before M33-B** so the arc consumes one real model instead of hand-rolling gates.

**Premortem:**
- *Boiling the ocean* (high) → phase it (model + 2–3 consumers first); propagate the rest after.
- *Forgotten-consumer / island risk* (high) → the §B blast-radius + architecture-review completeness gate is the mitigation, not optional.
- *Collision with existing scoring* (med) → M36's ADR defines the boundaries; M37 integrates, not duplicates.
- *Subjective-score drift* (med) → documented rubric; propose-not-act.

---

### M39 — G-tweak (periodic self-feedback + safe self-tune)
**Status:** ⬜ Not started
**Version:** v2.13.0 (minor — new skill; Phase A ships it, B/C fold in as they land; renumbered 2026-07-23 — M45+M46 inserted ahead)
**Goal:** Every N milestones, **offer (never enforce)** an interview on how G-Forge is serving the user — what's working (to *protect*) and what's friction (gating / overplanning / bottlenecks / poor performance) — then optionally self-tune and/or report out.
**Scope (phased):**
- **Phase A — Interview core:** offered every N (3–5, configurable) milestones; asks **both poles**; on decline it self-schedules (resurface in X milestones) or deactivates; **deactivation is flagged by `/g-doctor`** — allowed, never silent. Depends on nothing.
- **Phase B — Report-out:** action-(b) **calls G-Report** (M38).
- **Phase C — Safe self-tune:** action-(a) proposes local tweaks, **structurally barred from the commit gate / enforcement sentinels**; uses the M37 salience layer to distinguish needless bureaucracy from load-bearing enforcement; every tweak approve-before-write. Includes the **M43 inspection-cadence reassess hook** (added 2026-07-15): read the operator's cadence setting + observed hold behavior and propose adjustments (always-waved-through ⇒ suggest `off`; friction reports ⇒ suggest `every-wave`), approve-before-write like every tweak.
- **No automation on any user data**, ever.

**Depends on:** M38 (Phase B), M37 (Phase C). Phase A is standalone.

**Premortem:**
- *De-gating drift erodes the differentiator* (high) → action-(a) barred from enforcement; gated on M37; approve-before-write.
- *Reintroduces the interview M19 removed* (med) → offered-not-enforced + self-schedule/deactivate; framed as meta-feedback, distinct from session retro.
- *Silent deactivation* (low, mitigated) → `/g-doctor` flags it.

---

### M42 — Planning Cold-Start Integrity
**Status:** ⬜ Not started
**Version:** v2.7.0 (minor — new planning capability + gate; renumbered 2026-07-23: M45 (v2.6.0) + M46 (v2.4.0) inserted ahead)
**Goal:** No planning gate can green-light a product unusable from an empty state — the human cold-start becomes a represented, probed dimension of kickoff, roadmap, and review.

**Origin:** field report from **G-Cash** (first from-scratch G-Forge consumer), 2026-07-13. A top-tier `/g-roadmap` pass shipped M1–M5 all-green (MERGE READY); the first human smoke test found **no way for a user to create their household, accounts, pots, salaries, or savings goals** — the only creator of standing-config entities was `fixture_seed.sql`. Root-cause chain: ingestion-first brief → `/g-kickoff` never forced the cold-start question → `/g-roadmap` absorbed the gap via fixture-satisfied done-conditions → no gate represents the empty state (`/g-align` is brief-relative; the gap was *in* the brief). Systemic theme: **AI planning optimizes to its own done-conditions; no gate represents the human's first five minutes.** The Tier-3 human gate held — nothing shipped. Source brief: G-Cash scratchpad `gforge-patch-brief.md`.

**Scope (waved):**
- **Wave 1 — front line (P0):**
  - **Cold-start grill in `/g-kickoff`** — a relentless one-question-at-a-time interview against the draft brief: depth-first over the plan's dependency tree, every question carries a recommended answer + rationale, concludes at shared understanding. **Seeded with the fixed cold-start probe set** (fires regardless of what the brief mentions): (1) *cold start / empty state* — brand-new user, empty DB, day one: what do they see and do; (2) *entity-creation path* — for every domain entity: manual / imported / derived, and where is the surface; (3) *first-run reachability* — every planned feature reachable from zero data; (4) *fixture-leaning done conditions* — any milestone "done" standing in for a real user path. Mechanism prior art: the external "grill-me" skill — **implemented natively, no third-party dependency**.
  - **Fixture-as-crutch detector in `/g-roadmap`** — any milestone done-condition satisfiable only by seed/fixture data is surfaced as an open question at the buy-in gate, never absorbed into "done".
  - Probe set **single-sourced** (one shared rules/reference location); kickoff + roadmap reference it, never copy it.
- **Wave 2 (P1): reachability gate** — brief-independent check: *from an empty DB, can a real user reach every shipped feature?* Home undecided (new standalone gate vs `/g-align` extension vs a review-pipeline axis) — decide first (mini-ADR if contested), then implement. Output = per-entity creation matrix (entity → create surface? → evidence) + advisory verdict **with evidence** — never a bare green stamp.
- **Wave 3 (P1/P2):** `/g-patterns` seed rule — "planning omits the human first-run path"; `/g-align` blind-spot doc — brief-relative checks cannot catch requirements missing from the brief itself (why the reachability gate is not redundant). *(The brief's secondary signal — test-writer false DONE ≥4× — was appended to M-audit finding #20 at triage, not scoped here.)*

**Depends on:** M-audit-2026-07 (sequencing only — prose-only skill edits, touches no hooks or enforcement code).

**Sequencing note:** ID tailed at M42, but **sequenced early — after M41 (which the 2026-07-15 pull-forward slotted directly behind M-audit), before M29** — field-validated by the first real consumer's first smoke test, cheap (skill prose, no enforcement code), and it protects every project *birth*: the blind spot compounds worst at kickoff. Takes **v2.6.0** (renumbered 2026-07-23 — M45 inserted ahead; see version plan).

**Premortem:**
- *Kickoff friction / interview bloat* (high) — a relentless grill makes `/g-kickoff` exhausting; users rubber-stamp to escape and the probe's value dies. → Fixed, small probe set (4 categories); recommended answer on every question; concludes at shared understanding, hard-capped; the grill surfaces, never blocks.
- *Reachability gate becomes theater* (med) — "every feature reachable" is judgment-heavy; a checkbox version is false confidence. → The gate must emit the evidence (the entity→create-surface matrix, exactly the table the G-Cash brief hand-built) and stays advisory-with-evidence.
- *Probe-set copy drift* (med — finding #19's exact failure mode) → single source, referenced not copied by kickoff / roadmap / gate / patterns; `/g-blast-radius` at Wave 1 close.
- *External-skill coupling* (med, pre-mitigated) — adopting grill-me as a runtime dependency couples kickoff to unversioned third-party content. → Native implementation; prior-art credit only.

**Cross-cutting propagation (G-RULES §B):** the cold-start probe set is a shared primitive consumed by `/g-kickoff`, `/g-roadmap`, the reachability gate, and `/g-patterns` — run `/g-blast-radius` at Wave 1 close; the done condition is incomplete until the architecture-review completeness gate confirms no consumer was missed.

---

### M44 — G-Proof 1.0 (rebrand — now the rebuild's release vehicle)
**Status:** ⬜ Not started · ⚠ **PARTLY SUPERSEDED by [ADR-010](decisions/010-full-rebuild-on-current-platform.md) (2026-07-26)** — read this stamp before planning against the text below.
**Version:** **G-Proof 1.0** — versioning restarts under the new name. The 2.x line ends where this begins; no `3.0.0` ever ships. **Unchanged by ADR-010 and explicitly reaffirmed there.**

> **ADR-010 supersession stamp.** What changed: this milestone is **no longer the capstone of the 2.x arc and no longer gated** on M35–M37, M29/M33/M34 or M38/M39 shipping first. Under the freeze-and-fork delivery shape, v2.5 ships from this repo (~~only M41 is a candidate for it~~ — *superseded by ADR-012, 2026-08-10: v2.5 ships the full announced scope, seven milestones — eight since the 2026-08-14 amendment added M49; this stamp is ADR-010's dated text, kept verbatim otherwise*), this repo freezes, and the tree is forked into a new repo and transformed into G-Proof — so **the rebrand is the rebuild's release vehicle**, landing right after the rebuild rather than dead last. What survives unchanged: the version identity (1.0, restart under the new name), Wave 2's README restyle, and the requirement that the CHANGELOG and announcement lead with a version-lineage note. **What is RETIRED and must be re-cut — do NOT plan off the wave text below:** (a) **Wave 1's repo rename** `onlygian/g-forge` → `onlygian/g-proof` — under ADR-010 this repo stays published as **frozen G-Forge**, so the new name belongs to a *new* repo, not to a rename of this one; (b) **Wave 3's `/g-update` migration path and its done condition** — ADR-010's Consequences are explicit that "consumers must be migrated, not merely updated — a cross-repo migration path, not a `/g-update` realign"; (c) the **`2.13→1.0` lineage number** used in Wave 1/Wave 3 copy and the premortem — the real lineage is **v2.5 → G-Proof 1.0**; (d) **`**Depends on:**`'s M38/M39 hard prerequisite** (see the note on that line). What is still open, at the gate: M44's three detail calls (done-definition rewrite, whether M41 remains a prerequisite, ride-alongs). The "name lands when the product can back it" rationale below now rests on the *rebuild* backing it, not on the six-milestone list. **`g-docs/milestones/M44.md` carries the same retirements** — it was written pre-ADR-010 and is stamped accordingly.

**Goal:** Rebrand **G-Forge → G-Proof** as the release vehicle for the rebuild — the name lands when the product can fully back it. Originally scoped (pre-ADR-010) as the arc's conclusion gated on: enforcement provably enforcing (M-audit), releases gated (M41), memory + salience live (M35–M37), the multiplayer arc shipped (M29/M33/M34), and self-governance measuring itself honestly (M38/M39 + the 2026-07-18 calibration item). "Proof" is a claim; this milestone ships it as a demonstrated property, not a promise.
**Rationale for the original capstone placement (developer decision, 2026-07-18 — placement RETIRED by ADR-010, see stamp; the naming logic below still holds):** consumers (G-Cash, the alveria fork) keep a stable name/URL through the heaviest milestones; the awkward 3.x mid-arc renumbering disappears; the rebrand becomes a single, complete story ("G-Proof 1.0") instead of a mid-flight costume change. GitHub's rename redirect keeps the mechanical cost of renaming late identical to renaming early.
**Scope (waves carried over from the pre-split M41 — full task detail in `g-docs/milestones/M44.md`):**
- **Wave 1 — Rename & manifest:** repo `onlygian/g-forge` → `onlygian/g-proof` (GitHub auto-redirects); `plugin.json` + `marketplace.json` name/display-name/description + version → **1.0.0** under the new name; sweep internal `g-forge` → `g-proof` (CLAUDE.md, skill frontmatter, hook headers) — **historical retros + dated ADRs left as-written** (rename globset excludes them); CHANGELOG heading + G-Proof 1.0 anchor with an explicit version-lineage note (G-Forge 2.x → G-Proof 1.0).
- **Wave 2 — Full README restyle (persuasion-ordered, G-Proof-branded):** ~250–300 lines (from ~700); tagline ("Claude Code is powerful. It's also optimized for velocity, not reliability. But you can G-Proof it."), producer's-seal analogy, **gate GIF** (commit blocked → `/g-review` → MERGE READY → commit passes; fallback animated-SVG/mermaid/text), before/after table, 5-minute install, FAQ, roadmap table. The status strip (shipped v2.3.0, maintained since) carries over restyled. Uses M41's `/g-release` + `/g-doctor` consistency machinery — by this point both are long-shipped.
- **Wave 3 — Field communication:** migration notes + announcement for known installs (`onlygian/G-Cash`, marketplace listing) — repo renamed, plugin name changed, **run `/g-update` to resync**; version-lineage explanation front and center (1.0 = rename + maturity marker, same enforcement model); flag Confluence `109314050` / Drive refs for cleanup. Done = consumers notified + confirmed able to `/g-update`; no broken links.

**Premortem (carried from the pre-split M41 where applicable):**
- *Rename churn / broken clones* (med) → GitHub auto-redirects; no force-push; field installs resync via `/g-update`.
- *Downstream fork breakage* (med) → migration notes + tested `/g-update` path; done condition includes "consumer can resync," not just "announced."
- *Version-lineage confusion* (med — HIGHER than the old v3.0.0 plan's "culture shock" risk, since the lineage — v2.5 → 1.0 post-ADR-010, 2.13 → 1.0 as originally written — reads as a downgrade to the unbriefed) → the announcement + CHANGELOG lineage note lead with it; `/g-update` compares (name, version) pairs, not bare numbers — verify this explicitly in Wave 1.
- *Gate GIF can't be captured* (low) → fallback to animated SVG / mermaid / text sequence.

**Depends on:** ⚠ **superseded by ADR-010 — the pre-ADR-010 text was:** *"everything — that's the point. Hard prerequisites: M41 (release machinery cuts this release), M38/M39 (the self-governance story the name claims)."* **Now:** the hard prerequisite is **the rebuild** (R0 first, then whatever R-bands R0 authorizes). **R0's first act (developer, 2026-08-30):** a whole-system Fable audit of the shipped 2.5 — the DIES / TRANSFORMS components the M52 F-cycles deliberately skipped — read directly by HQ on the session model, findings filed as G-Proof planning input, not as 2.5 fixes. M38/M39 are **not** prerequisites — they sit behind a 2.x sequence that ends at v2.5, so keeping them would block M44 permanently. Whether **M41** remains a prerequisite is one of the three open detail calls at the gate.

---

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

### Candidate — Unified Provenance Primitive (decide, don't build)
Two independent inventions describe the same shape: **a pinned external source + a provenance note + the rule that change lives in the decision layer, not a silent swap.** M40's `reference/` `SNAPSHOT.md` (source pin + deriving-ADR + delta-not-swap rule) and the alveria-forge fork's `al-docs/UPSTREAM.md` (pinned upstream commit + PORTED/DROPPED/DIVERGED ledger + on-release review checklist) each reinvented it — one for external corpora, one for upstream lineage. Worth an ADR to **name the primitive once** so both share a template, instead of solving provenance twice. **YAGNI on tooling** — no skill, no scaffold; the decision is whether it's one named g-forge concept. Gated behind M40 shipping (it needs one concrete instance in-tree first).

---

### Candidate — State Lifecycle (G-Forge cleans up after itself)
*Triaged here 2026-08-17 via `/g-intake`. Classified **scope-creep against the brief**: it advances no stated Goal, is implied by no MVP or roadmap item, and is forbidden by no Non-goal — the dangerous middle. Declined from 2.5 because ADR-012 closed that scope and a lifecycle policy is a thing the rebuild should design in, not a thing to bolt onto a maintained freeze.*

**The gap.** G-Forge writes state continuously and deletes almost none of it. Nothing in `hooks/` or `skills/` reaps, rotates, or ages out any surface it creates; the only deletions in the tree are sentinel **consumptions on the success path** — `hooks/pre-commit:214,218,235` once validation passes and the commit is allowed to proceed, and `post-commit-cleanup.sh:103-104` after the commit succeeds — which are gate mechanics, not lifecycle. *Note the direction, because it was documented backwards once already: a **rejected** sentinel is never deleted. `deny()` prints and `exit 1`s (`hooks/pre-commit:40-43`) before any `rm` is reached, so a stale or invalid stamp is left on disk deliberately — consumption is the reward for passing, not the punishment for failing.* Measured on this repo 2026-08-17: **87 files matching `.claude/session-prompt-count*`** (80 UUID-keyed counters accumulated since 2026-07-22 and growing one per session, plus the legacy bare file and six ad-hoc `.{test,verify,verify2,v3,v4,v5}` leftovers from manual verification) · `g-forge-agent-log.jsonl` 277 KB unrotated · `.claude/journal/` 451 KB across 32 files · `g-docs/agent-output/` 3.4 MB across 334 files.

**Why it is not merely untidy.** Accumulation silently disabled a shipped decision path — `/g-resume` Step 0e's session-id-unknowable fallback requires *exactly one* counter candidate and gets 87, so it can never resolve on a repo older than about a week. That specific defect, plus `compact-state.md`'s stale-reads-as-fresh failure, were **absorbed into 2.5's M50** as instrument defects; they are fixed there and are not this candidate's scope. What remains here is the general policy that would have prevented both.

**Possible scope when promoted:**
- A declared lifetime per state surface — session-scoped, milestone-scoped, or durable — with the taxonomy written before any reaper exists. Most surfaces have never had their intended lifetime stated anywhere, which is the actual root cause.
- Reaping and rotation honoring that taxonomy, on the ADR-005 worktree-resolution axis: a reaper must never delete a **live** sibling session's file. Age-based only; liveness rule stated first.
- The consumer-side rule that falls out of it: a consumer reading a state surface with an unbounded population must degrade determinately, never assume a small one. Step 0e assumed and went dead.
- Scaffold-side default — whether `/g-init` writes a lifetime declaration for each surface it creates, so consumer projects inherit the policy instead of accumulating the same debt silently.

*Not gated on anything. Cheap to design, and the rebuild touches every one of these surfaces anyway — deciding the taxonomy before that work is worth more than doing it after.*

---



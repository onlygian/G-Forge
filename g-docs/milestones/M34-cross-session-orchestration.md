# M34 — Cross-session dependency tracking & pull/push orchestration

> ⚠ **FORK-BOUND per [ADR-012](../decisions/012-g-forge-2.5-final-release-scope.md) (2026-08-10):** this milestone left the G-Forge 2.x roadmap — it ships, if ever, from the G-Proof fork. Its roadmap entry lives in `g-docs/g-proof-roadmap.md` (committed and tracked since 2026-08-21 — it forks with the repo; the original local-only arrangement is retired). Nothing here is in the v2.5 final-release scope, and every 2.x Version field below is STALE — versioning restarts at G-Proof 1.0.

**Status:** ⬜ Not started (scoped, awaiting go) — **hard-depends on M29** (register)
**Version:** ships its own minor once M29 lands (late-2.x arc — see ROADMAP Version Plan)
**Depends on:** **M29** (claim/lease register — the substrate that carries claims) · **M33** (the Roundtable — the surface that renders the graph and the suggestions). Degrades cleanly to today's single-session flow when neither is configured.

## Goal
Take G-Forge's single-session orchestration — plan, track dependencies, coordinate work — and make it work across **many sessions/users**. Surface **who-depends-on-whom** as a live graph, and turn that graph into **git coordination suggestions** (pull / push / coordinate). Everything is **advised, never automated**: the machine runs the process and surfaces the move; the human decides and executes it. This is the concrete engine under the multiplayer cooperation arc — the "super important" part.

## Position — dependency tracking is the spine of the cooperation arc
The provisional **M30–M32** sketch (membership → handoff → reconciliation) all presupposes one thing: knowing *who depends on whom*. Assignment is meaningless without it; handoff is guesswork without it; reconciliation is blind without it. M34 builds that spine — the cross-session **dependency graph** derived from M29 claims — and the **suggestion engine** on top. M30–M32's mechanics become consequences of the graph and likely **reconcile into / fold under** M34 once it exists. Renders *on* M33's Roundtable; runs *on* M29's register. **The orchestration is the product; the Roundtable is where it becomes visible.**

## Non-goals
- **No auto-merge, no autonomous git.** M34 *suggests* pull/push/coordinate; the human runs the command. Reconciliation stays human-guided (inherits M32's non-goal).
- **No AI-dispatches-AI.** Sessions surface state and advisories; humans orchestrate. No hosted authority.
- **Not a CI/build system, not a git replacement.** It reads git + register state and advises; it never gates or automates the pipeline.
- **No new coordination substrate.** Rides M29's register + M33's Roundtable. Ships no service.

## The shape
- **Claims carry dependencies.** An M29 claim/lane declares `owner` (person+session), `file-set`, `status`, and **`depends-on`** (the lanes/claims it needs first).
- **A dependency graph** is derived from the live claims: nodes = lanes, edges = depends-on. "Your lane is blocked by their lane" is a query on it.
- **A suggestion engine** turns graph + git ahead/behind into advisories:
  - **pull** — an upstream lane you depend on just completed → pull before continuing.
  - **push** — your lane is done and others depend on it → push so they unblock.
  - **coordinate** — your file-set overlaps an active claim, or a dependency **cycle** is forming → talk before you collide.
- **Surfaced** via `workflow-checkpoint` (at boundaries), `/g-status`/`/g-help` (the graph on demand), and the Roundtable (shared visibility).
- **Suggestions route to the orchestrator seat (ADR-002).** Anything touching shared state — integration order, "who pulls/pushes what into `main`", breaking a dependency cycle — is *surfaced* to the one human orchestrator seat, who decides. The seat **owns `main`** (this is the concrete answer to M32/M34's "who owns `main`"). Peers get advisories for their own lanes; cross-lane/integration calls are the seat's. Never co-chairs; the seat rotates by the M33 Phase-B handoff.

## Scope / phases

### Phase A — Dependency declaration & graph (the spike)
- [ ] **A1 — Extend the claim.** Add `depends-on` to the M29 claim record; `/g-plan` and `/g-execute` declare it when claiming a wave's file-set.
- [ ] **A2 — Build/read the graph.** Derive the who-blocks-whom graph from live claims; `/g-status` renders "blocked-by / blocking" for the current lane. Prove the graph is legible with 2 sessions before any suggestions.

### Phase B — Pull/push suggestion engine
- [ ] **B1 — pull/push advisories.** Given the graph + `git` ahead/behind, emit **pull** (upstream done) and **push** (downstream waiting) at boundaries via `workflow-checkpoint`/`/g-status`. Advised only — never runs git.
- [ ] **B2 — Salience gate.** Suggest only on a *state change* (a dep resolves, a lane completes) — not every boundary. Tier-gated (off on `light`).

### Phase C — Roadmap-update propagation
- [ ] **C1 — Shared roadmap.** A roadmap change by one session surfaces to everyone's Roundtable; `/g-roadmap`'s premortem + re-prioritization runs on the *shared* roadmap so the plan is common knowledge, not siloed.

### Phase D — Conflict & cycle detection
- [ ] **D1 — Overlap warnings.** Detect overlapping file-sets across active claims → **coordinate** advisory (needs granular claims — validate upstream in M29).
- [ ] **D2 — Cycle detection.** Detect dependency cycles → warn, never auto-resolve.
- [ ] **D3 — Grooming.** Dependencies decay with the M29 claim/lease TTL; groom stale edges at `/g-roundtable close` / lane release.

## Done condition
In a 2-session repo: session A sees **"blocked by B's lane"** on `/g-status` and the Roundtable; when B completes, A gets a **"pull B"** suggestion and B gets a **"push — A is waiting"** suggestion; an overlapping file-set raises a **coordinate** warning and a dependency cycle raises a warning — **all as advisories, zero auto-merge, zero auto-git.** The dependency graph is visible on `/g-status` and the Roundtable. With no register/Roundtable configured, behaviour is byte-identical to today's single-session flow.

## Premortem (per `/g-roadmap` Step 3b)
- **Suggestion spam** (high) — advisories every boundary become noise the way any nag does. *Mitigate:* the B2 salience gate — suggest only on a state change; tier-gated off on `light`; dedupe repeats.
- **Stale / wrong dependencies** (med) — a `depends-on` that no longer holds misleads. *Mitigate:* deps decay with the M29 claim/lease TTL; groom at close; mark unverifiable edges advisory.
- **Overreach into auto-merge** (med) — the tempting next step is "just pull for them." *Mitigate:* hard non-goal; suggest-only; the human runs every git command. Reconciliation stays human-guided (M32).
- **Coarse claim granularity blinds overlap detection** (med, carried from M32) — file-set claims too coarse ⇒ conflict detection is blind. *Mitigate:* validate claim granularity upstream in M29 before D1; spike.
- **Dependency cycles** (med) — A waits on B waits on A → deadlock. *Mitigate:* detect + warn (D2); never auto-resolve; surface for a human to break.
- **Register/Roundtable unavailable** (low–med) — the substrate isn't there. *Mitigate:* degrade to single-session (no deps, no suggestions) cleanly; never block work.

## Sequencing
**Hard-depends on M29** (no claims ⇒ no graph). **Phase A is the spike** — prove the dependency graph is legible with two sessions before building the suggestion engine. Slots **immediately after M29**, ahead of (and largely absorbing) the provisional M30–M32 mechanics, since assignment/handoff/reconciliation are consequences of the graph M34 builds. Uses M33's Roundtable as the shared surface. Dogfood on this repo (the M24/M25 collision that motivated M29 is the canonical test case).

## Cross-cutting propagation (per G-RULES §B / `/g-roadmap` Step 4)
M34 introduces a cross-cutting primitive — the **cross-session dependency graph** (claims-with-`depends-on`). Every skill/hook/rule that assigns, plans, executes, resumes, or reports must respect it (enumerate with `/g-blast-radius`; the architecture gate verifies completeness):

| Surface | Becomes dependency-aware — how |
|---|---|
| `/g-plan` · `/g-execute` | declare `depends-on` when claiming a wave's file-set |
| `/g-status` · `/g-help` | render the blocked-by / blocking graph + current advisories |
| `workflow-checkpoint` | surface pull/push/coordinate advisories at boundaries (salience-gated) |
| `/g-roadmap` | run premortem/re-prioritization on the *shared* roadmap; surface roadmap changes to all Tables |
| `/g-resume` | cross-session catch-up includes the dependency deltas |
| `/g-review` | releasing a lane on merge resolves downstream deps → triggers others' "pull" advisory |
| `/g-retro` · `/g-roundtable close` | groom stale dependency edges at close |
| `g-rules-B / -I` | "declare dependencies when you claim," dependency-graph-as-coordination-fabric |

# Project Brief — G-Forge

**Created:** 2026-07-01 (retroactive — project is live at v2.2.0; review/amend as needed)
**Status:** Approved (retroactive draft — supersede via `/g-brief` when refined)

## What this builds

G-Forge is an opinionated multi-agent **Claude Code plugin** that wraps an *educated, enforced project-management* layer around Claude: planned execution, production architecture, enforced review, and context/hallucination control. It lets a solo developer — or a small team — get disciplined, senior-engineer-grade delivery out of an LLM: the machine runs the **process** (decompose → wave-dispatch → review-gate → commit-gate → retro), the human owns the **judgment**. The point is to let models *punch above their weight* while keeping the human the most valuable part of the loop. It is an **empowerment tool**, not a human-replacement — "simpler for humans," not "minimal."

## Goals

- **Enforce the process the way a good team lead would** — non-trivial work goes plan → execute → review → commit, and the **hard git commit gate** (a hook that blocks `git commit` without a review sign-off sentinel) makes the discipline non-optional, not advisory. This is the one novel, load-bearing differentiator.
- **Control context and hallucination** — single-use agents, distilled memory (retros/ADRs/handoff), the §A7 context reset, and `/g-resume` re-hydration keep the working window clean instead of poisoned.
- **Make the LLM govern itself honestly** — premortems, forecasts, architecture-review and doc-review gates, alignment/drift checks, and a passive observer journal (retro without interview) so quality is measured, not asserted.
- **Stay opinionated but degradable** — three integration tiers (`full`/`balanced`/`light`); with the plugin inert the repo behaves byte-identically to a plain project.
- **Scale governance from one session to many** — the multiplayer arc (see Roadmap): coordinate concurrent sessions/users without an AI ever becoming the master.

## Non-goals (explicitly out of scope)

- **Not autonomous AI-dispatches-AI, not a hosted authority.** Humans orchestrate; the machine surfaces, suggests, and records. Even the shared-work arc keeps a *human* orchestrator seat (ADR-002).
- **Not a replacement for the developer's judgment.** Every gate proposes; the human approves. "Swapping humans for brains" is explicitly rejected.
- **Not a CI/build system or a git replacement.** It advises git actions; it never auto-merges or gates the pipeline.
- **Not a general framework** — it is specifically a Claude Code plugin, leaning on Claude Code's skills/agents/hooks/MCP surfaces.
- **Not defence against a user who breaks the tool they adopted.** G-Forge is opted into deliberately and is degradable by design: `/g-tier` (`full` / `balanced` / `light`) is the supported way to reduce or switch off enforcement, commit gate included. Anyone who deletes a hook instead of switching the tier has made a decision, and it is theirs to make. Nothing here is designed to be un-bypassable by its own operator — "make X un-bypassable" is not a valid hardening argument, and any proposal resting on it is a positioning change, to be decided as one.

## MVP

Shipped at **M15 / v1.0.0**: the end-to-end enforced loop — `/g-kickoff` → `/g-roadmap` → `/g-init` → `/g-specialize`, then the per-task loop `/g-plan` → `/g-execute` → `/g-review` with the **commit gate** enforcing review sign-off. **Done condition (met):** a non-trivial feature can be taken from request to reviewed, gated, committed code without the developer manually orchestrating agents.

## Roadmap

| Milestone | Features | Rationale |
|-----------|----------|-----------|
| M1–M15 — Foundation → v1.0 | Agent roster, skills/orchestration, stack profiles, commit enforcement, intelligence (patterns/forecast/telemetry) | The enforced-PM MVP and its self-improvement loop |
| M23 — Production audit → v2.0.0 | Hardening, self-guarded hooks, rename pass | Make it shippable and safe to install anywhere |
| M27–M28 → v2.1–2.2 | Doc-review gate; `g-docs/` as canonical committed home | Docs gated like code; one tracking home |
| ~~M46→M41→M45→M42 — process-integrity tranche~~ *(superseded 2026-08-10, [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md))* | M46 shipped v2.4.0; the tranche's survivors fold into the 2.5 scope below; M42 fork-bound | Superseded — see the v2.5 row |
| ~~v2.5 — full announced scope, nine milestones~~ *(superseded 2026-08-28, [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) amendment 4)* | M47 → M48 → M51 → M50 → M38 → M40 → M43 → M49 → M41 | Superseded — see the v2.5 minimal-freeze row below. Dropped entries preserved in full at `archive/roadmap-dropped-2026-08-28.md`, G-Proof candidates decided at R0 |
| **v2.5 — the final G-Forge release, minimal freeze** *(current)* | M47 Planning-Pipeline Honesty ✅ + M48 Review-Pipeline Hardening ✅ (both shipped in v2.4.1) → **M52 — v2.5 Minimal Freeze**, hand-cut 2026-08-31 | 2.5 ships only what survives the G-Proof rebuild or is an adopter-facing bug — filter is the rebuild map's verdict column (`audits/2026-07-rebuild-map.md`). The copy follows reality; the approved-announcement commitment is dissolved (ADR-012 amendment 4, 2026-08-28) |
| ~~M29 · M33 · M34 · M30–M32 — the multiplayer arc~~ *(fork-bound per ADR-012)* | Claim/lease register · the Roundtable (Phase A built) · cross-session orchestration · membership/handoff/reconciliation | Leaves with the G-Proof fork — entries in the committed `g-docs/g-proof-roadmap.md` (tracked since 2026-08-21) |

## Tech decisions

| Component | Choice | Rationale | Risk | Code-lead note |
|-----------|--------|-----------|------|----------------|
| Platform | Claude Code plugin (skills/agents/hooks/rules/commands) | Native to the target runtime; auto-discovered, travels to web/mobile/Actions when committed in `.claude/` | Coupled to Claude Code's plugin model | None |
| Enforcement | Git hook commit gate + review/doc sentinels (`.claude/g-forge-approved`, `-docs-approved`) | The hard gate is the differentiator — discipline made non-optional | Hook must self-guard to G-Forge projects only | Verified by unit tests |
| Memory | Distilled durable record in `g-docs/` (ROADMAP handoff, ADRs, retros) + passive observer journal | Clean-window re-entry over transcript inheritance | Distillation quality is load-bearing | `/g-retro` synthesizes; no interview |
| Agents | Single-use, scoped dispatch (task-decomposer, wave-planner, code-lead, etc.) | Keep HQ's context clean; offload high-branching reasoning | Agent sprawl | Promote finished answers only |
| Coordination surface (multiplayer) | Surface-agnostic adapter; **Confluence advised**, Gmail floor, Drive out (ADR-001) | Lead on official MCPs; degrade by capability tier without skill change | MCP availability divergence | Confluence = in-place; Gmail = draft-and-nod |
| Authority (multiplayer) | One **human** orchestrator seat per Roundtable, never co-chairs (ADR-002) | Answers "who owns `main`"; keeps AI out of the master role | Stale seat blocks decisions | Seat is an M29-leased claim |
| Deployment | GitHub repo + Claude Code marketplace; self-hosted on this repo (dogfood) | Distribution + continuous dogfooding | — | `/g-update` realigns installs |
| Naming / version strategy | **G-Proof 1.0** — versioning restarts under the new name; **no `3.0.0`** (developer, 2026-07-18–19; downgraded from ADR — product strategy, not architecture). ⚠ **PARTLY SUPERSEDED by ADR-010 (2026-07-26): only the version identity survives** — reaffirmed verbatim. Retired: "arc runs its natural life as G-Forge 2.x" (the arc is cut at **v2.5**), "rebrand ships as the M44 capstone" (M44 is now the *rebuild's* release vehicle), and the M38/M39 backing rationale (the **rebuild** backs the claim). Corrected: the lineage is **v2.5 → G-Proof 1.0**, not 2.13→1.0 — announcement + CHANGELOG copy derived from the old number must be re-cut. | Consumers keep a stable name through the heavy middle; "proof" claimed only when the product can back it — post-ADR-010 that backing is the rebuild | **v2.5**→1.0 reads as a downgrade to the unbriefed — announcement + CHANGELOG lead with the lineage note (M44.md premortem) | Not an ADR by triage; version identity reaffirmed by ADR-010 |

## Success metrics

- **MVP worked:** a non-trivial change goes request → gated, reviewed, committed code without manual agent orchestration (met since v1.0).
- **Feature-complete signal:** context stays clean across long projects (compaction avoided via the gate), review catches regressions before merge, and — for the multiplayer arc — two sessions/users cooperate on one repo without colliding and without an AI taking the master seat.
- **Adoption:** the enforced-PM + commit-gate combination is recognizably the thing that makes an LLM "punch above its weight."

## Decisions and overrides

- **Positioning locked as "educated, enforced project management"** — context/hallucination control + the hard commit gate are the distinguishing capabilities (validated by deep research).
- **Empowerment over automation** — recurring developer directive: the human is the most valuable part of the loop; reject anything that reads as replacing them.
- **Multiplayer arc, human-first** — humans orchestrate; the Roundtable surfaces and records; the orchestrator seat is always human (ADR-002).
- **Bypass posture settled (2026-07-26)** — the commit gate is *switchable by design*, not deletable-by-oversight: `/g-tier light` already disables it as a supported operation. The modernization report's GF-43 ("a gate the gated party can delete is a convention, not enforcement") therefore rests on a false premise and is **retired**; the CI-side *enforcer* it proposed collides with two non-goals above and is **rejected** as an implementation row — reopening it means amending this brief first. The residual real need is a *findable* switch with legible consequences, which is M43 `/g-settings`, not new enforcement. A CI **reporter** (advisory status, human decides whether to merge) stays brief-compatible and parks against the multiplayer arc, where a second person's commits first exist.
- **Full rebuild + freeze/fork (2026-07-26, [ADR-010](decisions/010-full-rebuild-on-current-platform.md))** — v2.5 ships and this repo **freezes** on bug-report maintenance; it is forked into a new repo and transformed into **G-Proof**. This **retires the pre-arc tranche sequencing below from M45 onward** and retires **M44's gating** (it no longer waits on M35–M37, M29/M33/M34 or M38/M39) — the rebrand becomes the rebuild's release vehicle. *(Scope superseded twice: 2026-08-10, [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) replaced "only M41" with the full announced scope; **2026-08-28, ADR-012 amendment 4 reversed that** — v2.5 is a minimal freeze, M47 ✅ + M48 ✅ + M52, and M41 is dropped.)* **The version identity in the Naming/version strategy row above is unchanged and reaffirmed: G-Proof 1.0, versioning restarts under the new name, no `3.0.0`.** The full milestone re-scope was originally deferred until after the rebuild plan (developer, 2026-07-26) but was pulled forward and executed 2026-08-10 (developer, ADR-012) — the roadmap's 2.5 arc is authoritative again; fork-bound milestones moved to `g-docs/g-proof-roadmap.md` (committed and tracked since 2026-08-21; it forks with the repo).
- **Pre-arc process-integrity tranche (recorded 2026-07-23, /g-align follow-up — now superseded IN FULL: from M45 onward by ADR-010, and the remainder by [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md), 2026-08-10)** — the recorded order was M46 → M41 → M45 → M42, each inserted on a dated, incident-anchored developer decision (G-Cash stale-cache update, hand-cut releases, review-cost stalls, G-Cash cold-start). Standing state *(updated 2026-08-28, [ADR-012](decisions/012-g-forge-2.5-final-release-scope.md) amendment 4)*: M46 shipped v2.4.0; ~~M41 rides v2.5.0 in the ADR-012 build order, sequenced LAST~~ — **M41 is dropped from 2.5 entirely** (the minimal freeze drops the release machinery; v2.4.1 proved the hand-cut), archived at `archive/roadmap-dropped-2026-08-28.md` as a G-Proof candidate; M45 was folded into M51, which is itself dropped bar the items M52 absorbs; M42 is fork-bound. The "insertion queue closed ahead of M29" clause is **moot** — M29 is fork-bound, and M47/M48 entered by ADR-012 as a developer scope decision, not an incident insertion; the next alignment check grades against the ADR-012 scope, not this bullet.

## Open questions

- **M29 feasibility:** is convention (an MCP mutable field — Confluence property / Gmail label) enough for a reliable claim/lease register? Phase A is the gating spike.
- **M30–M32 boundaries** will firm up (and likely fold under M34) once M29 ships and the dependency graph is real.
- **Versioning:** M33 Phase A shipped un-versioned on `main`; it ships its own minor when Phase B lands.

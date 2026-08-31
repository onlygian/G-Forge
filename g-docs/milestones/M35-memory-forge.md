# M35 — Memory Forge (deep memory layer + optional Obsidian surface)

> ⚠ **FORK-BOUND per [ADR-012](../decisions/012-g-forge-2.5-final-release-scope.md) (2026-08-10):** this milestone left the G-Forge 2.x roadmap — it ships, if ever, from the G-Proof fork. Its roadmap entry lives in `g-docs/g-proof-roadmap.md` (committed and tracked since 2026-08-21 — it forks with the repo; the original local-only arrangement is retired). Nothing here is in the v2.5 final-release scope, and every 2.x Version field below is STALE — versioning restarts at G-Proof 1.0.

**Status:** ⬜ Not started (scoped at roadmap level; `/g-plan` decomposes at start)
**Version:** v2.9.0 (minor — new user-facing capability; synced 2026-07-23 to ROADMAP after M45+M46 insertions)
**Goal:** The distilled durable record (retros, ADRs, handoff, brief, journal) becomes a *linked, layered, queryable* memory that `/g-resume` hydrates precisely and task-specifically — Obsidian-compatible by convention, never Obsidian-dependent.
**Depends on:** M29 (shared-layer design only — single-session value stands alone); M-audit-2026-07 (enforcement substrate stable first).

## Why (brief traceability)

Goal 2 of `project_brief.md`: context/hallucination control via distilled memory + clean-window re-entry — whose declared risk is "distillation quality is load-bearing." Today the record is flat files with implicit relationships; hydration (`/g-resume`) already keys its slice selection to the branch/milestone/first-task, but it selects from *fixed categories* (relevant retro, in-force ADRs, journal, handoff) and cannot follow relationships between records — a task whose context lives two links away (an ADR superseded by another, a pattern recorded in an older retro) is out of reach. The 6-layer taxonomy (g-rules-J) declares a `context:` frontmatter contract that **no orchestrator actually consumes** (confirmed by the 2026-07 audit — documented, not implemented).

## Scope

### Phase A — the linked record (spike-first)
- [ ] **Linking conventions:** `[[wikilinks]]` + YAML frontmatter (type, milestone, tags, supersedes) across retros/ADRs/handoff/brief/milestones. Pure markdown — `g-docs/` *is* the vault.
- [ ] **`context:` loader made real:** define and implement the load contract — which files each declared layer (task/sprint/architectural/…) resolves to, who loads them (skill preamble step), and what "loaded" means. Spike the contract first (M29-A4 pattern); kill or implement, no paper contracts.
- [ ] **Layer homes:** `g-docs/memory/` for sprint/architectural/institutional layer files + eviction per `g-docs/memory-taxonomy.md`.

### Phase B — hydration v2
- [ ] **`/g-resume` graph-walk:** hydration keyed to the first task — follow links N deep from the entry points (handoff → linked ADRs/retros → linked patterns) instead of fixed slices; budget-capped.
- [ ] **`/g-retro` writes into the graph:** new retros link decisions → ADRs, patterns → prior retros, tasks → milestone files.
- [ ] **Memory hit-rate telemetry:** `/g-telemetry` metric — did the hydrated slice get used (referenced) by the session? Feeds loader tuning.

### Phase C — Obsidian surface (opt-in)
- [ ] **`.obsidian/` scaffold** via `/g-init` opt-in flag (graph view, starred entry points, templates); never required by any skill.
- [ ] **`/g-doctor` advisory check:** vault-integrity (broken wikilinks, orphaned memory files).
- [ ] **ADR:** "Obsidian is a viewer, never a dependency" — surface-tier framing per ADR-001; pins the boundary before creep starts.

### Shared-layer design constraint (not scope)
Design layer/link schemas so M33-B digests and M34 dependency records can live *in* this substrate (sprint-layer entries on a shared surface) rather than inventing parallel record shapes. Interfaces only — multiplayer implementation stays in M33/M34.

## Premortem (top 3)
- **Scope blow-up** (high) — memory systems attract features. → Phase A is conventions + loader *only*; each phase gated on measured `/g-resume` improvement, not vibes.
- **Loader semantics undefined / dead-on-arrival** (med) — the `context:` contract has been paper for 25 milestones. → Phase A spike decides implement-or-delete before anything else builds on it.
- **Obsidian coupling creep** (low) — a skill quietly starts requiring the vault. → the Phase C ADR pins "viewer, never dependency"; `/g-skill-validate` can grep for `.obsidian` references in skills.

## Done condition
A fresh session on a real task hydrates via graph-walk and demonstrably pulls a more relevant slice than fixed-slice `/g-resume` (compared on the same task); all links valid; taxonomy layers either implemented or explicitly retired; no skill depends on Obsidian.

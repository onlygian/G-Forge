# G-Forge Wiki

**What:** G-Forge is a Claude Code plugin that installs an educated, enforced project-management layer into any project. It layers a PM that challenges scope, parallel execution waves, and an unskippable commit gate — making discipline non-optional, not advisory.

**Current state:** **v2.4.1 released** (2026-08-24; intermediate cut on the road to 2.5 per ADR-012, carrying M47 + M48a–e + all post-2.4.0 fixes). M-audit, M46 Update Integrity, M47 Planning-Pipeline Honesty, and M48 Review-Pipeline Hardening all closed.

**v2.5.0 is the final G-Forge feature release** ([ADR-012](../g-docs/decisions/012-g-forge-2.5-final-release-scope.md), amendment 4 — 2026-08-28). It is a **minimal freeze**: 2.5 ships only what survives the G-Proof rebuild or fixes something an adopter hits. Remaining work is one milestone — **M52 — v2.5 Minimal Freeze**, closing with a hand-cut release when the F3 audit gate closes (moved from 2026-08-30). The earlier nine-milestone build order (M51 → M50 → M38 → M40 → M43 → M49 → M41) is retired; those entries are preserved as G-Proof candidates in [`archive/roadmap-dropped-2026-08-28.md`](../g-docs/archive/roadmap-dropped-2026-08-28.md). After 2.5 this repo freezes on maintenance only, forks, and ships as **G-Proof 1.0** from the fork ([ADR-010](../g-docs/decisions/010-full-rebuild-on-current-platform.md) — versioning restarts; there is no G-Forge 3.0). See [ROADMAP](../g-docs/ROADMAP.md).

**This wiki covers the architecture, workflows, and operations behind G-Forge.** Start with [Getting Started](usage.md) if you're new; use [Commit Gate](commit-gate.md) if you need to understand enforcement; refer to [Architecture](architecture.md) for design decisions and data flow.

---

## Contents

| Page | What's in it |
|------|-------------|
| [**Getting Started**](usage.md) | Install, project lifecycle, per-task workflows, integration tiers, session rhythm, voice profiles |
| [**Commit Gate**](commit-gate.md) | How the review enforcement works, sentinel flow, hook architecture, context depth management |
| [**Architecture**](architecture.md) | Design decisions, layer model, skill vs agent distinction, memory taxonomy, single-use agents, wave dispatch |

---

**G-Forge is shipped as a Claude Code plugin.** Install via `/plugin marketplace add onlygian/g-forge` + `/plugin install g-forge` — see [README](../README.md) for full install instructions.

Full project documentation lives in `g-docs/` — milestones in `g-docs/milestones/`, architectural decisions in `g-docs/decisions/`, operational tracking in `g-docs/ROADMAP.md` and `g-docs/todo.md`.

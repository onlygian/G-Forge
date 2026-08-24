# G-Forge Wiki

**What:** G-Forge is a Claude Code plugin that installs an educated, enforced project-management layer into any project. It layers a PM that challenges scope, parallel execution waves, and an unskippable commit gate — making discipline non-optional, not advisory.

**Current state:** **v2.4.1 released** (2026-08-24; intermediate cut on the road to 2.5 per ADR-012, carrying M47 + M48a–e + all post-2.4.0 fixes). M-audit, M46 Update Integrity, M47 Planning-Pipeline Honesty, and M48 Review-Pipeline Hardening all closed.

**v2.5.0 is the final G-Forge feature release** ([ADR-012](../g-docs/decisions/012-g-forge-2.5-final-release-scope.md)). Build order (remaining): **M51** Release Reliability (M45-lite, absorbing M45) → **M50** Eval-Chain Integrity → **M38** G-Report → **M40** Reference Convention → **M43** Operator Controls → **M49** Devil's-Advocate Agent → **M41** Release Machinery (cuts the release, last). After 2.5 this repo freezes on maintenance only, forks, and ships as **G-Proof 1.0** from the fork ([ADR-010](../g-docs/decisions/010-full-rebuild-on-current-platform.md) — versioning restarts; there is no G-Forge 3.0). See [ROADMAP](../g-docs/ROADMAP.md).

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

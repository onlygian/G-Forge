# G-Forge Wiki

**What:** G-Forge is a Claude Code plugin that installs an educated, enforced project-management layer into any project. It layers a PM that challenges scope, parallel execution waves, and an unskippable commit gate — making discipline non-optional, not advisory.

**Current state:** **v2.6.1 released** (2026-09-02 — the token-diet release, M53; [ADR-014](../g-docs/decisions/014-v26-token-diet-reopens-after-freeze.md) supersedes ADR-012's finality label and reopens development). Same governance, a fraction of the tokens: deterministic prose scripted, rationale moved to lazily-loaded references, one review pack per round with delta re-review, pinned model/effort dispatch economy — no gate removed, no verdict changed, no knowledge deleted.

**The v2.5 freeze is history, recorded as it happened:** v2.5.0 shipped 2026-08-31 as **M52 — v2.5 Minimal Freeze** under the then-standing "final G-Forge release" decision ([ADR-012](../g-docs/decisions/012-g-forge-2.5-final-release-scope.md) amendment 4 — only what survives the G-Proof rebuild or fixes something an adopter hits; the retired nine-milestone build order is preserved in [`archive/roadmap-dropped-2026-08-28.md`](../g-docs/archive/roadmap-dropped-2026-08-28.md)). The freeze-then-fork plan was superseded on 2026-09-01 when the developer reopened the repo for v2.6 (the measured ~27× token multiplier made the harness too expensive to keep using as-was). The G-Proof rebuild ([ADR-010](../g-docs/decisions/010-full-rebuild-on-current-platform.md)) remains a future plan, unscheduled. See [ROADMAP](../g-docs/ROADMAP.md).

**This wiki covers the architecture, workflows, and operations behind G-Forge.** Start with [Getting Started](usage.md) if you're new; use [Commit Gate](commit-gate.md) if you need to understand enforcement; refer to [Architecture](architecture.md) for design decisions and data flow.

---

## Contents

| Page | What's in it |
|------|-------------|
| [**Getting Started**](usage.md) | Install, project lifecycle, per-task workflows, integration tiers, session rhythm, voice profiles |
| [**Commit Gate**](commit-gate.md) | How the review enforcement works, sentinel flow, hook architecture, context depth management |
| [**Architecture**](architecture.md) | Design decisions, layer model, skill vs agent distinction, memory taxonomy, single-use agents, wave dispatch |
| [**Reference**](reference.md) | Complete catalog of skills, agents, and stack profiles — lookup tables with descriptions |

---

## Currency

Wiki pages are narrative documentation, synthesized from the codebase and verified against source code by `/g-doc-review` at each gate rather than pinned by claim tests. This convention was chosen at M54 (see `g-docs/ROADMAP.md` M54 scope) to keep documentation live and maintainable as the project evolves.

---

**G-Forge is shipped as a Claude Code plugin.** Install via `/plugin marketplace add onlygian/g-forge` + `/plugin install g-forge` — see [README](../README.md) for full install instructions.

Full project documentation lives in `g-docs/` — milestones in `g-docs/milestones/`, architectural decisions in `g-docs/decisions/`, operational tracking in `g-docs/ROADMAP.md` and `g-docs/todo.md`.

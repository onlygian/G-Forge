# M33 — The Roundtable (shared-doc interface: the human-facing communication layer)

> ⚠ **FORK-BOUND per [ADR-012](../decisions/012-g-forge-2.5-final-release-scope.md) (2026-08-10):** this milestone left the G-Forge 2.x roadmap — it ships, if ever, from the G-Proof fork. Its roadmap entry lives in `g-docs/g-proof-roadmap.md` (committed and tracked since 2026-08-21 — it forks with the repo; the original local-only arrangement is retired). Nothing here is in the v2.5 final-release scope, and every 2.x Version field below is STALE — versioning restarts at G-Proof 1.0.

**Status:** 🟡 Phase A (solo) built against the adapter — live Google dogfood pending MCP-in-session · Phases B–D not started
**Version:** ships its own minor when built
**Depends on:** **M29** (claim/lease register) for lanes/presence in shared mode. Degrades cleanly to today's solo, git-mediated flow when no Roundtable is configured.
**Design note:** the multiplayer north star and surface ladder live in `g-docs/multi-session-coordination.md`. M29 is the *coordination substrate* (machine↔machine collision-avoidance); the provisional **M30–M32** arc (membership · handoff · reconciliation) is the *mechanics*. **M33 is the cooperation arc's communication *interface*** — the **harmonious cooperation layer**: the shared, human-facing surface that M30–M32 render on, where humans and their Claude sessions see the state of play, steer in plain language, and reach agreement before it hardens into the record. Because Phase A is valuable **solo** (no M29 needed), the Roundtable can ship ahead of the rest of the arc, and it is the concrete shape the provisional M30–M32 sketch firms up into once M29 lands.

## Goal
Give G-Forge a real-time, human-facing **communication surface** — a shared Google Doc ("the Roundtable") that is the live UI between developers, *non-programmers*, and their Claude sessions. The state of play is visible; humans steer in plain language; plans and decisions are shaped live, then **distilled into the durable record + action points** the existing engine executes. Triggerable; works **solo** (your own live surface) or **shared** (the multiplayer table).

## Position — M29's register and M33's Roundtable are one surface, two faces
M29 uses a Google/Drive surface as a **register/log** (structured claim records: who holds what). M33 uses a Google **Doc** as the **Roundtable** (where people and Claudes actually talk, plan, and decide). Same vendor surface, same MCP, two faces. The register keeps work *safe* (no collisions); the Roundtable makes work *legible and shared*.

## Non-goals (inherits M29's, adds)
- **Working memory, not truth.** The Doc is the *live* surface; `g-docs/` (ROADMAP, ADRs, the `## Active Session` handoff) stays authoritative. The Roundtable **writes through** to the record on a human nod — it is never a second source of truth.
- **Not always-on, not autonomous.** Triggerable, off by default. Humans orchestrate; the Roundtable surfaces, records, and distills — it never dispatches a person or a session.
- **Surface-borrowed.** Rides a Doc the team already has, via a remote MCP. Ships no service.

## The shape
- **The Roundtable** = a structured Doc: *living-state* up top (**Now/Lanes · Decided · Open questions · Asks**) + an append-only **"what just happened"** feed at the bottom.
- **Heartbeat:** sessions read the Roundtable at turn/wave boundaries (via `workflow-checkpoint`), write only *what counts* (salience gate); a **human nod** distills live decisions → ADRs/ROADMAP and live plans → action points. *Distillation quality is the make-or-break — see premortem.*
- **Solo vs shared:** solo = your own live surface (and your future self's); shared = lanes/presence from the M29 register stop two sessions touching the same area.
- **One orchestrator seat (ADR-002).** A shared Roundtable is **not flat** — it has exactly one **human** orchestrator seat (the §B PM role) that owns the roadmap writes, tie-breaks, `main`/integration order, and the final distill nod. The machine surfaces and suggests; the seat decides. The seat is a role, not a fixed person — it **rotates via the Phase-B handoff** (one gavel, handed off atomically). **Never co-chairs.** Solo, you are trivially the chair.

## Scope / tasks

### Phase A — Solo Roundtable (prove the heartbeat with one person)
- [x] **A1 — Trigger + setup.** `/g-roundtable start|sync|close` (`skills/g-roundtable/SKILL.md` + `commands/g-roundtable.md`); bind via the surface adapter (**ADR-001**); token by env-var, **never committed**. **Concrete adapters now specced** in the skill: **Confluence** (bind/read/in-place write via `get`+`updateConfluencePage`) and **Gmail** (labeled thread, watermark scan, `create_draft`-and-human-send, label routing) + best-first surface resolution + bind-record v2 (`watermark`/`cloudId`/`spaceId`/`label`). **Both surfaces validated live:** Confluence — bind/read/security + **in-place write** (page v1→v2); Gmail floor — label `bind` + draft `append`/`write` + read-back (send = human, by design). The Drive surface is eliminated (read-only).
- [x] **A2 — Templates.** Starter Doc template (living-state sections + feed) + **session-rules** + **end-of-session-summary** templates under **`templates/roundtable/`** (plugin content, alongside `skills/`/`hooks/` — refines the spec's earlier `g-docs/templates/`, which would wrongly copy plugin assets into every consumer repo; `g-docs/` is for *generated* records).
- [x] **A3 — Session rules.** Read-the-Roundtable at turn/wave boundaries; write-what-counts salience gate — codified as the `/g-roundtable` skill + the `workflow-checkpoint` hook heartbeat (tier-gated, off on `light`; null-adapter silent when no Roundtable bound — regression-tested in `tests/test-roundtable-degradation.sh`).
- [x] **A4 — End-of-session distill.** `/g-roundtable close` → distill the live Doc into the `## Active Session` handoff + ADRs + an action list, **human nod required.** Built and exercised once (this ADR addendum *is* a distilled-to-record finding). **Live dogfood result (2026-06-30, see ADR-001 addendum):** bind ✅ · read ✅ · security ✅ against real Google Drive; **session write-back ❌ — the Drive MCP is create+read-only.** Session-writes-the-feed needs a Google *Docs*-API MCP (`batchUpdate`); Drive-only gives a read-mostly Roundtable (session reads, humans write). Contract unchanged.

### Phase B — Shared Roundtable (two+ human+AI pairs)
- [ ] **B1 — Join.** A collaborator binds their session to the same Roundtable (**permissioned, never public**) — the same Confluence page, or the same shared mailbox thread (below).
- [ ] **B2 — Lanes / presence** via the M29 register: who owns what, live, so two sessions don't collide on the same area. On the mailbox surface, lanes = labels (the M29 "label *is* the mutable field" idea).
- [ ] **B3 — Cross-person catch-up.** A session re-hydrates *"what your collaborator established since you last synced"* — cross-person `/g-resume`.
- [ ] **B4 — Person→person handoff/asks** on the Roundtable (the `## Active Session` block generalizing session→session to person→person; ties into the cooperation arc).

**Shared-mode surface scoping (mailbox floor — from the ADR-001 dogfood).** The mailbox is the *universal floor* surface (Tier 2, append-only). How a shared mailbox Roundtable is scoped is the load-bearing choice, and it splits by mode:

| Mode | Anchor | Identity | Lanes |
|---|---|---|---|
| **Solo** | a **label** in the user's own mailbox (`g-roundtable/<repo>`) | native — your own `From:` | labels |
| **Shared** | a **shared address (Google Group / list)** — *not* a shared login | native — each person's real `From:` | labels on the Group thread |

- **Avoid "one shared Gmail account per repo."** A shared *account* shares credentials (a `/g-doctor` security fail) and **collapses identity** — everyone becomes "the project account," destroying *who-said-what*, which is exactly what the cooperation layer exists to preserve.
- **A Group/list address fixes both:** everyone stays on their own account (real `From:` = native attribution), and the Group thread is the shared feed every session reads. This is the concrete answer to the founding question — *"how do two sessions know what counts?"* → both are on the shared thread; each drafts salient deltas; the human sends; identity rides in the `From:`.
- **Draft-and-nod is native here:** the Gmail MCP can `create_draft` but not send — the session proposes a feed entry, the human sends it. The salience gate + human nod are enforced by the medium, not bolted on.

**Mailbox read model (the sync scan — from the live dogfood).** The write side is scoped above; the read side is what `/g-roundtable sync` does each boundary, and the inbox *is* a multiplexed inbound channel:

- **Bounded window, watermark delta.** A sync reads only what arrived **since the last-seen mark** (a watermark — message id/timestamp persisted in `.claude/roundtable`), bounded by the last-N (5–10) as the fallback on first sync. Never re-scan seen items; never miss one if many landed between boundaries. (The last-5 scan returns near-instantly — proven live — so this is cheap enough to run every boundary, which is what makes the heartbeat viable. This is ADR-001's "read deltas, never the whole surface," made concrete for a mailbox.)
- **Classify each item in the window** into three buckets:
  - **User message** (`From:` a real person) → an **Ask** / a steer. The non-programmer path: email the agent, never touch the repo.
  - **Multistream update** (`From:` a known session/agent identity, or a lane label) → **lanes / coordination** — the M29 register face riding the same mailbox.
  - **System noise** (`no-reply@`, `accounts.google.com`, etc.) → **ignore.** (The live inbox was *all* such noise — the filter is not optional.)
- **One inbox, two faces, routed not separated:** user Asks (M33) and multistream coordination (M29) share the mailbox; they're disambiguated by `From:`/label, not by separate accounts.

### Phase C — Maintenance, setup, hardening
- [ ] **C1 — Maintenance / grooming.** A "groom the Roundtable" routine: archive resolved items off the live Doc into the record; keep living-state small; prevent the swamp.
- [ ] **C2 — Setup + health.** `/g-init` opt-in ("set up a Roundtable? none|solo|shared"); `/g-doctor` advisory check (Doc reachable, template present, **not world-readable**, token not committed).
- [ ] **C3 — Templates per context** (game / app / PM-coordination).
- [ ] **C4 — Degradation + docs.** No Roundtable configured → behavior byte-identical to today (git-mediated handoff). Doc unreachable → warn + fall back, **never block work.** Update `g-rules-I` + README.

### Phase D — Propagation (make the surface lane/Roundtable-aware) — *part of "done," not optional*
A cross-cutting primitive (lanes, the Roundtable) is not done as an isolated component. Every skill/hook/rule that *assigns, plans, executes, reviews, resumes, or reports* must respect it, or the feature is an island. Enumerate with `/g-blast-radius`; the architecture gate verifies completeness. Touchpoints:

| Surface | Becomes lane/Roundtable-aware — how |
|---|---|
| `/g-roadmap` | read lanes before assigning a milestone #; surface the plan/decisions on the Roundtable |
| `/g-plan` | check lanes for the file-set before a wave; claim it; post action points to the Roundtable |
| `/g-execute` · `/g-afk` | claim the wave's lane, heartbeat, post progress/done, release on complete |
| `/g-review` · `/g-doc-review` | cross-person review of another's lane; post MERGE READY/HOLD; release on merge |
| `/g-resume` | read the Roundtable + collaborator deltas (cross-person catch-up) |
| `/g-retro` | distill the Roundtable → record; release lanes at close |
| `/g-adr` | decisions surface on the Roundtable, then promote to the ADR record |
| `/g-status` · `/g-help` | show current lanes + Roundtable state/link |
| `workflow-checkpoint` · `session-start` · `pre-compact` | surface others' lanes, heartbeat own claim, snapshot the Roundtable pointer |
| `/g-init` · `/g-doctor` · `/g-update` | setup, health checks, keep template + config in sync |
| `g-rules-A / -B / -I` | "read the Roundtable," "claim before work," Roundtable-as-record-fabric |

#### The orchestration layer *on* the Roundtable — the actual payoff (multi-session/user)

Propagation isn't just "make skills Roundtable-aware." The point is to run **G-Forge's existing orchestration** — the thing it already does well for one session — across **many sessions/users**, with the Roundtable as the shared surface and the M29 register as the coordination substrate. Three capabilities, all **suggest-not-act** (machine runs process, human owns judgment):

1. **Roadmap updates, live and shared.** Milestones/decisions shaped on the Roundtable distill into `g-docs/ROADMAP.md` (`/g-roundtable close` + `/g-adr`), and — the new part — a roadmap change by *one* person/session **surfaces to everyone's Roundtable** so the plan is common knowledge, not siloed. `/g-roadmap`'s premortem + re-prioritization runs on the *shared* roadmap.

2. **Cross-session/user dependency tracking — *super important*.** Today dependencies live inside one plan (`/g-plan` waves, `/g-blast-radius`). Across sessions they're invisible — the exact failure that motivated M29 (two sessions colliding on M24/M25). The Roundtable + register make them legible: each lane/claim declares its file-set and what it **depends on**; the Roundtable shows *"your lane is blocked by their lane,"* and `/g-status`/`/g-help` report the cross-person dependency graph. This is the spine — assignment, handoff, and reconciliation (the M30–M32 arc) all hang off knowing who-depends-on-whom.

3. **Pull/push suggestions (git coordination, advised not automated).** Driven by register + Roundtable state: *"B finished the lane you depend on → **pull** before you continue,"* *"your lane is done and three people are waiting on it → **push** so they unblock,"* *"your file-set overlaps an active claim → coordinate before you start."* Surfaced by `workflow-checkpoint` / `/g-status`; never an auto-merge (reconciliation stays human-guided per M32's non-goal).

**Dependency:** these are the concrete realization of the **M30–M32 cooperation arc** (membership/assignment → handoff → reconciliation) rendered *through* the Roundtable, on the **M29** register. They likely warrant their own milestone(s) once M29 ships — tracked here so Phase D's "done" isn't read as merely cosmetic Roundtable-awareness. The orchestration *is* the product; the Roundtable is just where it becomes visible.

## Done condition
- **Solo:** `/g-roundtable start` binds a structured Doc; the session reads it each boundary and writes only salient deltas; `/g-roundtable close` distills to handoff + ADRs + action list on a human nod. With **no** Roundtable configured, behavior is byte-identical to today.
- **Shared:** two people on one Doc see each other's lanes (via the M29 register), catch up on deltas, and hand off person→person without colliding — and the Doc is never the source of truth.
- A **non-programmer** can read the Roundtable and steer by typing into it.
- **Propagation complete:** every touchpoint in the Phase-D matrix is wired, and the architecture-review gate confirms none was missed. *A Roundtable that works in isolation but that `/g-roadmap`, `/g-plan`, and the hooks don't respect is **not done.***

## Premortem (per `/g-roadmap` Step 3b)
- **Distillation quality is the whole game.** Lossy ⇒ intent drifts; noisy ⇒ the Doc swamps. *Mitigate:* human nod gates every distill; salience filter on writes; the C1 grooming step; keep living-state small.
- **🔴 "Public" doc = data leak.** A *public* Google Doc is world-readable — project intent/decisions/secrets exposed. *Mitigate:* default **link-restricted, not public**; never put credentials on the Roundtable; `/g-doctor` flags world-readable; document the policy.
- **Read-cadence token cost.** Reading the Doc every turn burns tokens. *Mitigate:* read deltas/sections, not the whole Doc; on boundaries only; tier-gated (off on `light`).
- **Two sources of truth.** *Mitigate:* Doc = working memory, repo = truth; nothing is "decided" until it's in the record.
- **Concurrent-write clobber.** *Mitigate:* Google Docs' native concurrent-edit merge + append-only feed + section ownership via M29 lanes.
- **MCP availability divergence.** Same as M29 — remote MCP requirement + `/g-doctor` reachability check.
- **Scope creep into autonomous orchestration.** *Mitigate:* the non-goals — the Roundtable surfaces and records; humans orchestrate.
- **Propagation forgotten** (the island risk). *Mitigate:* Phase D + the §B cross-cutting propagation rule + the gate completeness check.

## Sequencing
**Phase A ships as a standalone spike** — valuable solo, and it proves the make-or-break (the distill loop). **Phase B depends on M29's register** being available for lanes. **Phase D runs alongside B/C** (you propagate as you add the shared behavior), and gates "done." Dogfood on this repo.

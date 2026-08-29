# M29 — Multi-session coordination (claim/lease for concurrent sessions)

> ⚠ **FORK-BOUND per [ADR-012](../decisions/012-g-forge-2.5-final-release-scope.md) (2026-08-10):** this milestone left the G-Forge 2.x roadmap — it ships, if ever, from the G-Proof fork. Its roadmap entry lives in `g-docs/g-proof-roadmap.md` (committed and tracked since 2026-08-21 — it forks with the repo; the original local-only arrangement is retired). Nothing here is in the v2.5 final-release scope, and every 2.x Version field below is STALE — versioning restarts at G-Proof 1.0.

**Status:** ⬜ Not started (scoped, awaiting go)
**Version:** ships its own minor when built; sequence relative to M26 is the developer's call
**Depends on:** nothing structural — adds an optional coordination layer. Builds on the M28 `.claude/` "committed config travels" property and the existing `## Active Session` git handoff (which remains the fallback).
**Design note:** the full rationale, surface ladder, and the chosen-direction trade-offs live in `g-docs/multi-session-coordination.md`. This file is the buildable scope.

## Goal
Stop **concurrent** sessions from silently colliding on milestone numbers, branches, and the handoff block, by coordinating through a shared, MCP-reached surface — with pluggable backends behind one adapter — leading on official MCPs (**Google: Gmail/Drive** as flow+floor, **Confluence** as the enterprise lock), with **Discord** an optional flagged real-time adapter (community MCP) — and a clean fall-back to today's sequential git handoff when nothing is configured.

## Position in the bigger goal — phase one of multiplayer G-Forge
The north star is **full multi-user cooperation on one project** — "human orchestration,
powered by humans": a human team, each with their own Claude, playing on a shared
governance fabric that engages whenever more than one session/user is live (see
`g-docs/multi-session-coordination.md`). **M29 is phase one**: the atomic claim/lease
substrate every later cooperation feature is built on. The cooperation layer —
**assignment by person**, **cross-person handoff** (the `## Active Session` block going
person→person), **cross-person review gates**, and **reconciliation** of concurrent
work — is a **milestone arc beyond M29**, not cut. M29 makes the rest *safe*.

## Non-goals
- **Permanent line:** no autonomous AI-orchestrating-AI. Humans orchestrate; G-Forge
  enforces and records. No session silently dispatches another session or a person, and
  G-Forge never runs as an always-on hosted authority.
- **Surface-borrowed, not self-hosted:** coordination rides on a surface the team
  already uses (Gmail / Discord / Confluence) via a remote MCP — M29 ships no service.
- **Deferred to later phases of the multiplayer arc (not cut, just not M29):**
  assignment/ownership semantics, cross-person review gates, and concurrent-wave
  merge/reconciliation. M29 is the substrate they depend on.

## The shape (recap from the design note)
- **Register** = a mutable field on the surface: "who holds what right now."
- **Log** = an append-only history on the surface: claims/releases as events.
- **Protocol** = read register → if target free, write a claim (signed, timestamped, leased) → heartbeat → release. `/g-roadmap` and `/g-plan` consult the register before assigning.

## Scope / tasks

### Phase A — Surface-agnostic core + first adapter (proves the model)
- [ ] **A1 — Coordination protocol + register schema.** Define the resource keys we claim (milestone number · branch · wave/file-set), and the claim record: `{resource, holder_identity, session_id, ts, lease_ttl, status:(active|released)}`. Define operations: `read_register`, `claim`, `release`, `heartbeat`, `list_active`. Define the **tiebreak rule** for non-atomic surfaces (earliest `ts`; ties broken by lexically-lowest `session_id`) and the **CAS rule** where the surface supports it.
- [ ] **A2 — Session identity + lease/heartbeat.** A stable per-session id; every write is **signed** with it (mandatory on shared-account Gmail). Lease TTL + periodic heartbeat so a crashed session's claim auto-expires; define **stale-claim reclamation** (a claim past TTL with no heartbeat is reclaimable, logged as a takeover).
- [ ] **A3 — Adapter interface.** Thin contract every backend implements: `readRegister() · writeClaim() · appendLog() · casUpdate?(version)`. **Capability flags** per adapter: `push|poll`, `cas|convention`, `nativeIdentity|sharedAccount`. The workflow logic reads flags, never vendor specifics.
- [ ] **A4 — First reference adapter: Google (Gmail or Drive).** Chosen because it rides an **official** MCP and is the *flow + floor* almost everyone already has. Register + log via whatever the official MCP actually exposes — e.g. Gmail **labels** as the mutable claim field + a thread as the append log, or a Drive doc/file set. **Step one of the spike is confirming the official MCP gives a usable mutable field** (labels vs draft-edit vs file-create) — not an assumption. Convention tiebreak (no CAS). Reached via a **remote MCP in `.mcp.json`**. This is the spike that answers *is convention enough in practice?* (Discord — real-time but **community/unofficial** MCP — is deferred to an optional adapter in the C-phase.)
  - **Step-one finding (confirmed live, master session 2026-07-01):** the official Gmail MCP exposes labels as a first-class mutable field — `list_labels` (read register), `create_label` (declare a claim), `label_thread`/`label_message` + `unlabel_*` (set/clear the claim on the log thread). So **Gmail labels are a viable register mechanism**; the A4 build can commit to the labels variant rather than re-deciding labels-vs-draft. Two capability gaps to design around, both known: (1) **no CAS** — label writes don't take a version, so two sessions can both apply a `claim:*` label; the A1 tiebreak (earliest `ts` → lowest `session_id`) + mandatory re-read is load-bearing, not optional; (2) **shared-account identity** — labels carry no author, so the `holder_identity`/`session_id` must live *inside* the claim payload (label name or the log thread's signed entry), per A2. Drive-doc variant stays the documented fallback if a labels register proves awkward at volume. *(Aside: the probe found stale `g-table` / `g-table/G-Forge` labels from before the Table→Roundtable rename — add to the live test-artifact cleanup tracked in the ROADMAP `## Active Session` handoff.)*

### Phase B — Workflow integration
- [ ] **B1 — Collision check in `/g-roadmap` + `/g-plan`.** Before assigning a milestone number (roadmap) or starting a wave (plan), `read_register` + a fresh fetch; if the target is claimed by another live session, **warn with who/when and offer alternatives** (next free number / different wave); on proceed, `claim` it.
- [ ] **B2 — Hook surfacing.** `workflow-checkpoint.sh` shows others' active claims ("⚠ M29 claimed by sess-ab12, 8m ago") and **heartbeats** the current session's claim. `session-start.sh` lists active claims at open. Release on milestone close / `/g-retro`. **Honor tiers:** active on `full`/`balanced`; `light` opts out entirely.

### Phase C — Setup, health, docs, and the other two adapters
- [ ] **C1 — Confluence adapter (the lock).** Page = register, page history = log, **version-CAS** = genuine atomic claim. This is the answer if Phase-A convention proves insufficient for teams.
- [ ] **C2 — Discord adapter (optional, real-time).** Push + native identity for teams that want live coordination — **flagged**: rides a community (unofficial) MCP, so it's opt-in, behind the same adapter interface. (The Google flow+floor already shipped in Phase A; if a JSON-in-Drive register proves awkward, a Gmail-labels variant is the fallback floor.)
- [ ] **C3 — `/g-init` opt-in setup + `/g-doctor` check.** Optional `/g-init` step: "Configure multi-session coordination? (none | discord | confluence | gmail)" → wires the chosen **remote MCP into `.mcp.json`** (token via env-var expansion, **never committed**) and writes `.claude/coordination` config. New `/g-doctor` advisory check: configured surface's MCP is reachable and the register is readable.
- [ ] **C4 — Degradation + docs.** No surface configured → behavior byte-identical to today (sequential git handoff). Surface unreachable → warn + fall back, **never block work**. Update `g-rules-I` and the README.

## Done condition
- Two concurrent sessions both attempting to claim the same milestone end with **exactly one** holding it and the other told it's taken — atomically on Confluence (CAS), and via the documented tiebreak + re-read on Discord/Gmail (with the convention race window explicitly documented, not hidden).
- A crashed session's claim expires by lease and is cleanly reclaimable.
- With **no** surface configured, `/g-roadmap`, `/g-plan`, and the hooks behave exactly as they do today.
- `/g-doctor` reports coordination health when a surface is configured; credentials are never committed.

## Premortem (per `/g-roadmap` Step 3b)
- **Credential leakage** — a token committed in `.mcp.json`. *Mitigate:* env-var expansion only; `/g-doctor` + `.gitignore` guard; doc warning.
- **Convention races (Gmail/Discord)** — two sessions both believe they "won." *Mitigate:* deterministic tiebreak (ts + session_id) + mandatory re-read after write; document the window; steer teams needing hard exclusion to Confluence.
- **MCP-availability divergence** — a local stdio adapter would silently fail to coordinate cloud/Slack/Actions sessions. *Mitigate:* **remote HTTP/SSE MCP in `.mcp.json` is a hard requirement**; `/g-doctor` reachability check.
- **Stale claims block work** — a crashed holder never releases. *Mitigate:* lease TTL + heartbeat + logged reclamation.
- **Three-adapter maintenance drift.** *Mitigate:* surface-agnostic core + capability-flagged thin interface; ship the **official Google (Gmail/Drive)** adapter first (Phase A reference), add Confluence (C1) and the optional/flagged Discord (C2) only behind the same contract. *(Corrected 2026-07-01: earlier draft said "ship Discord first" — superseded by the "prefer official MCPs" decision; the community/unofficial Discord MCP can never be the load-bearing reference.)*
- **Scope creep into orchestration.** *Mitigate:* the non-goals section above; reject merge/dispatch work into a later milestone.

## Sequencing
**Phase A ships as a standalone gating spike** — core protocol + the official-MCP Google adapter — and answers "is convention enough?" Dogfood it on this repo's own multi-machine workflow. **B-phase integration and the C-phase adapters proceed only on its verdict:** if convention holds, the Confluence hard lock (C1) becomes optional rather than urgent; if it doesn't, C1 leads. Discord (C2) is opt-in regardless.

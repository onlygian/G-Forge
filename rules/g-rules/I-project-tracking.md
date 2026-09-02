## I · Project Tracking

### File hierarchy

| File | Written by | Purpose |
|------|-----------|---------|
| `g-docs/project_brief.md` | `/g-kickoff` | Project goals, constraints, stack decisions |
| `g-docs/ROADMAP.md` | `/g-roadmap`, HQ | Milestone plan (current, backlog, done) **+ the `## Active Session` handoff** — the single canonical cold-start (Done this pass / Next up / Active context), rewritten each pass |
| `g-docs/milestones/M*.md` | `/g-roadmap`, `/g-plan` | Per-milestone scope, tasks, done conditions |
| `g-docs/todo.md` | HQ | Active task ledger — Tasks + Details (tactical; the handoff lives in `g-docs/ROADMAP.md`) |
| `g-docs/todo-done.md` | HQ | Archive of closed tasks and pass reports |
| `g-docs/decisions/NNN-title.md` | `/g-adr` | Architectural Decision Records — rationale behind significant technical choices |
| `g-docs/env-vars.md` | `doc-writer`, `/g-docs` | Environment variable reference — name, purpose, required/optional, example |
| `CHANGELOG.md` | HQ, `doc-writer`, `/g-patterns` (append-only under an existing `## [Unreleased]`) | Version history — features, fixes, breaking changes, deprecations |
| `g-wiki/` | `/g-wiki` | Human-facing project wiki — narrative architecture + how-to. **Committed** project content; refreshed at each milestone close. Distinct from `g-docs/` (operational records) and `/g-docs` (code-level doc hygiene). |

### Working memory vs. the durable record — the Roundtable (M33)

`/g-roundtable` can bind the session to **the Roundtable** — a shared live Doc, the human-facing communication layer. The Roundtable is **working memory, not truth**; the files above are the **durable record** — authoritative. It writes through to the record only on a human nod (`/g-roundtable close` → handoff + ADRs + todo); nothing is "decided" until it is in the record. Bind record: `.claude/roundtable` (gitignored; surface ref, never a credential). **Off by default:** no bind file ⇒ every `/g-roundtable` path is a no-op, behaviour **byte-identical** to the git-mediated flow. Design details (ADR-001 four-op adapter, no-secrets rule): `.claude/rules/references/project-tracking-notes.md` and `g-docs/milestones/M33-the-roundtable.md` — read when binding or editing the Roundtable.

### `g-docs/` is the canonical home for every G-Forge document

All G-Forge-generated documents live under `g-docs/`. Nothing G-Forge writes belongs at the project root except `CLAUDE.md` (Claude Code loads it there), `G-RULES.md` (`@`-referenced config), and `CHANGELOG.md`. Every skill writes into one of these canonical subpaths:

| Subpath | Written by | Holds |
|---------|-----------|-------|
| `g-docs/ROADMAP.md` · `g-docs/todo.md` · `g-docs/todo-done.md` · `g-docs/milestones/` · `g-docs/project_brief.md` | `/g-roadmap`, `/g-plan`, `/g-kickoff`, HQ | Project tracking |
| `g-docs/decisions/` | `/g-adr` | ADRs |
| `g-docs/retros/` | `/g-retro` | Session retrospectives |
| `g-docs/forecasts/` · `g-docs/plans/` | `/g-forecast`, `/g-plan`, `/g-execute` | Plans + wave forecasts |
| `g-docs/blast-radius/` | `/g-blast-radius` | Change-impact maps |
| `g-docs/telemetry/` · `g-docs/telemetry-metrics.md` | `/g-telemetry` | Usage telemetry |
| `g-docs/alignment/` | `/g-align` | Brief-drift checks |
| `g-docs/agent-output/` · `g-docs/qa-scope/` | `/g-execute`, `/g-review` | Raw agent output (regenerable) |
| `g-docs/env-vars.md` · `g-docs/identity.md` · `g-docs/patterns-deferred.md` | `/g-docs`, `/g-identity`, `/g-patterns` | Reference docs |
| `g-docs/patterns/` | `/g-patterns` | Abstracted pattern-mining reports (principle-level, externally shareable); the open report is always `g-docs/patterns/latest.md` — renamed to its resolution date (`YYYY-MM-DD.md`) once resolved. PENDING resolutions tracked per report |
| `g-docs/audits/` · `g-docs/archive/` | HQ (audit passes; supersession moves) | Whole-system audit reports that outlive their milestone, and superseded documents retired from active paths. **Committed** |
| `g-docs/inbox/adversarial/` | external automation (third-party) | Advisory counter-reports to pending pattern resolutions — **read** by `/g-patterns`' resolve phase (Step 12); suggestions only, human-weighed, never authoritative. **Filenames must be `[A-Za-z0-9._-]` only** — the producer slugifies at the point the name is minted |
| `g-docs/field-reports/` | external — the adopter project or a session on it (committed verbatim; never rewritten at intake) | Field reports from projects running G-Forge — a defect or gap observed in the field, reproduced against source **before** any scope decision is taken on it; the reproduction, not the report, earns a task. **Committed** — the evidence base a scope amendment cites |

**Tracked vs. ignored:** the `g-docs/` project record is **committed** (it *is* the project) — except `g-docs/agent-output/` (and any local `g-docs/plans/` scratch), which is regenerable and gitignored. The `.gitignore` `/g-init` writes (Step 5a) draws this line; `/g-doctor` Check 20 keeps it honest, and Check 21 flags any G-Forge document outside `g-docs/`. `g-docs/inbox/adversarial/` and `g-docs/field-reports/` are the two deliberate exceptions to "G-Forge writes it, G-Forge tracks it": both are third-party-written yet still committed by design — the inbound input itself is part of the project record once it lands. Incident history behind the committed-record rule: `.claude/rules/references/project-tracking-notes.md`.

**Date-keyed record paths discriminate same-day collisions** — a slug, a round ordinal (`-r[N]`), or a numeric suffix (`-2`, `-3`, …). `/g-review`, `/g-doc-review`, `/g-patterns`, and `/g-telemetry` carry the shipped conventions; a writer that mints a bare `YYYY-MM-DD.md` path with no discriminator silently overwrites a same-day run and is a gap against this rule.

### Commit gate infrastructure

Three hook scripts installed by `/g-init` under `.claude/hooks/`:

- **`check-commit.sh`** (PreToolUse) — blocks `git commit` if `.claude/g-forge-approved` is absent. `/g-review` writes the sentinel after issuing MERGE READY.
- **`post-commit-cleanup.sh`** (PostToolUse) — deletes `.claude/g-forge-approved` after each successful commit. The gate resets automatically.
- **`workflow-checkpoint.sh`** (UserPromptSubmit) — reads branch, milestone, review state, and Tier 3 listen mode on every prompt; its banner appears as a system reminder and reprints on state change — absence of a banner means the state is unchanged since the last one printed (escalation lines repeat every prompt while active).

Never bypass the commit gate with `--no-verify` or by manually writing the sentinel. Never chain verification commands onto a gated commit invocation — a failed trailing step makes PostToolUse skip, leaving the commit unjournaled.

### The handoff lives in g-docs/ROADMAP.md

There is **one** handoff, and it lives in `g-docs/ROADMAP.md` under a `## Active Session` heading — not in `g-docs/todo.md`. `g-docs/ROADMAP.md` is committed, so a fresh session (or clone) targets exactly one document for "where am I / what's next." The handoff is rewritten (replaced, never appended) each pass and committed; the same block is posted in chat (chat is for paste, the file is the persistent record).

```
## Active Session

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HANDOFF — <project> | branch: <branch>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done this pass:   · <item>
Next up:          · <item>
Active context:   · <file:line, state, in-flight logic>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

`workflow-checkpoint.sh` reads the `Active context:` line each prompt (its banner reprints on state change); `pre-compact.sh` snapshots the whole block; `/g-resume` re-hydrates from it; `/g-retro` refreshes it at session end. One writer-target, one read-target.

### g-docs/todo.md structure

**`g-docs/todo.md`** — two sections only (tactical task ledger, no handoff):
1. `## Tasks` — `| # | Task | Notes |` table. Notes column: `*` when a Details section exists.
2. `## Details` — `### N — Title` subsections for asterisked rows only.

**`g-docs/todo-done.md`** — archive. All closed tasks, pass reports, and summaries. Never inflate `g-docs/todo.md` with history.

Rules: closing a task = remove row + Details from `g-docs/todo.md`, append to `g-docs/todo-done.md`. Both files committed every session. Every edit to either file commits immediately — never left dirty.

---
name: g-resume
description: Re-hydrate a fresh session with the right slice of the durable record. The read-side counterpart to /g-retro — selectively retrieves the relevant retro, ADRs, journal, and handoff keyed by the current branch/milestone/first-task, and assembles a focused re-entry briefing. Loads distilled context into a clean window, not a poisoned transcript. Auto-nudged on the first prompt of a session when a handoff is pending. Verifies the clone is current with origin first — fast-forwarding only at session start, when strictly behind on a clean tree — before any file is read.
context: [task, sprint, architectural]
---

**Announce:** "Using g-resume to re-hydrate context for this session."

This is the read side of the seam: `/g-retro` and the §A7 context gate **promote** the clean record out of a finishing session; `/g-resume` **pulls the right slice back in** so a fresh window picks up the knowledge without the residue. Retrieval is deterministic candidate-gathering plus judged relevance — distilled sections only, never whole histories.

## Step 0 — Sync with origin before reading anything

Run `scripts/sync-check.sh` from the project root (locate it via Glob inside `~/.claude/plugins/cache/g-forge/g-forge/`, as `/g-afk` does for g-execute — never an absolute path) and interpret its `KEY: value` output:

- `EXIT: existence-gate` → go to Step 1 (its stop condition fires).
- `NOTE:` lines → surface in the briefing's "Where we are".
- `FRESHNESS:` → the briefing's `Freshness:` value, verbatim.
- `DIVERGED: behind=N ahead=M` → the 0f ask: warn prominently with both counts, then ask — proceed on this possibly-stale record, or stop and resolve first? **Proceed** → Freshness `⚠ STALE — proceeding on developer's call (N behind, M ahead)`. **Decline** → print `Re-hydration stopped — resolve the divergence (pull/rebase/push as appropriate), then re-run /g-resume` and stop; Steps 1–4 do not run.
- `FF:` → informational (a fast-forward was tried).
- `RECORD_AXIS:` (0g) → the briefing's `Record axis:` line, verbatim; absent = the current branch IS the record-bearing branch, or an early exit.
- `REMOTE:` ≠ origin → note the non-origin upstream in the briefing.

Read the two lines separately: `Freshness:` covers the current branch against its own upstream ONLY; `Record axis:` alone speaks to the durable record — `synced` never means the handoff is current. Step 0's figures supersede `hooks/session-start.sh`'s advisory behind/ahead line, `git pull` suggestion, clean summary, and behind-main drift line (the hook carries matching cross-ref comments); never follow the hook's bare `git pull` on a diverged tree.

For the rationale behind any branch, when editing the script, or when output doesn't match the contract, load `references/sync-edge-cases.md`.

## Step 1 — Establish the re-entry keys

Gather in parallel: **branch** (extract `<slug>` from `feat/ fix/ refactor/ chore/` names) · **active milestone** (the 🔄 In progress entry in `g-docs/ROADMAP.md`) · **handoff** (the `## Active Session` block — "Next up" and "Active context") · **first task** (the lead "Next up" item; watch for `verify ADR-NNN` — a first-class re-entry signal) · **recently touched files** (`git log --name-only -n 10 --pretty=format:`, unique basenames).

If `.claude/compact-state.md` exists, check it before trusting it: compare its `# Compact State — <timestamp>` header and `## Branch` section against the ROADMAP handoff's date (HANDOFF title-line date, else the last commit touching `g-docs/ROADMAP.md`) and the current branch. Older, different branch, or only a same-day tie → print `compact-state.md is stale (<ts>, <branch>) — ignored` and use the ROADMAP block alone (rationale: `references/sync-edge-cases.md` appendix).

If neither `g-docs/ROADMAP.md` nor `.claude/compact-state.md` exists, say so in one line and stop: `Nothing to re-hydrate — no handoff or roadmap found.`

## Step 2 — Retrieve the relevant slice (selective)

Gather candidates deterministically, then judge relevance — load only what serves the first task:

1. **The first task's anchor** — a `verify ADR-NNN` handoff task → load that ADR's **Decision**, **Consequences**, and **Assumptions That Held** sections; full weight.
2. **The carry-over retro** — most recent retro in `g-docs/retros/` matching the branch slug or milestone; no match → the single most recent, tagged `(low relevance — no slug/milestone match)`. Load only its **Cold-start context** and **Avoid / do differently** sections. Empty dir → skip.
3. **Decisions touching this work** — grep `g-docs/decisions/` for the slug and touched basenames; load the **Decision** line of the top 1–3 ADRs, list the rest as pointers.
4. **The alignment anchor** — `g-docs/project_brief.md` Goals + active milestone Scope, one line each; no brief → the ROADMAP title/blurb + active milestone Goal, tagged `(roadmap — no brief)`, noting `/g-brief` could create one. Never leave the briefing with no anchor.
5. **Recent activity** — latest `.claude/journal/*.jsonl` (~15 events) + `git log --oneline -5`.

Cap it: many matches → the most relevant few, plus `(N more — see <dir>)` pointers.

## Step 3 — Assemble the re-entry briefing

Present a single focused briefing — distilled, scannable, pointer-rich:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Re-entry — [branch] · [milestone or "—"]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
First task:    [lead "Next up" item — e.g. "Verify ADR-007 against the repo"]
Where we are:  [1–2 lines from handoff "Active context" + recent commits + Step 0 sync notes (unpushed count, non-origin upstream, fetch failure)]
Freshness:     [synced | synced — N unpushed | synced — fast-forwarded N | stale — N behind (not pulled: <why>) | stale — N behind (fast-forward failed) | unverified — fetch failed | unsynced — detached HEAD | unsynced — not a git repo | unsynced — no remote | unsynced — local-only remote | unsynced — no upstream | unsynced — upstream branch gone | unsynced — unborn HEAD | ⚠ STALE — proceeding on developer's call (N behind, M ahead)]
Record axis:   [N commits behind <remote>/<record-branch> — the handoff you are re-hydrating from may be stale | not behind <remote>/<record-branch> | record branch could not be resolved — cannot tell whether the handoff is current | record-drift count failed — cannot tell whether the handoff is current]

Decisions in force:
  · ADR-NNN — [Decision line]            [+ N more in g-docs/decisions/]
Carry-over (do differently):
  · [from the relevant retro's "Avoid / do differently", or "—"]   [append "(low relevance — no slug/milestone match)" if this is a fallback retro]
Anchored to:   [brief goal(s) the active milestone serves — or roadmap goal + "(roadmap — no brief)" if no project_brief.md]
Recent:        [last commit + last few journal events, one line]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

The `Freshness:` bracket is the closed set of values Step 0 can emit; `<why>` is one of `working-tree state unknown` · `dirty tree` · `upstream ref unresolved` · `no tracking configuration` · `mid-session run` · `session phase unknown` (0e's priority order). `Record axis:` is a separate line with its own closed set of four values — never a `Freshness:` variant. Exactly two walks render no value at all, by design: the 0a existence-gate skip and the 0f decline. Optionally write the same briefing to `.claude/reentry.md` (overwrite).

## Step 4 — Hand off to the first task

End by pointing at the first task — do not start it unprompted unless it is a pure verification. If it is `verify ADR-NNN`: offer "Verify ADR-NNN against ground truth now? (y/n)"; on yes, check each Decision/Consequences claim against current code/config/deps, reporting `holds` / `drifted — [what changed]` per claim. Otherwise state the single next action and stop, the way `/g-help` does.

## Rules
- Selective, not exhaustive — distilled sections and pointers, never whole files; relevance is judged, not dumped. When unsure, prefer the pointer over the paste. A clean window is the entire point.
- Read-only retrieval, with a bounded sync exception. `/g-resume` may write exactly three things: (1) Step 0's `git fetch` (0c); (2) Step 0's **local** fast-forward, `git merge --ff-only <ref>` — never `git pull` — and only when ALL hold: 0a existence gate passed, fetch succeeded, behind-only on a clean tree, configured-upstream path, session-start invocation (prompt counter reads `1`); (3) the optional `.claude/reentry.md` briefing write. Nothing else, and it triggers no other skill on its own.
- Never re-litigate a decision an in-force ADR settled — surface it as a constraint. (Verifying an ADR named in the handoff is the one exception; that is the task itself.)
- If the durable record is thin, re-hydrate from handoff + roadmap + journal alone and say so — degrade gracefully.
- Auto-trigger condition (full tier only): the first prompt of a session when a handoff is pending (`g-docs/ROADMAP.md` `## Active Session` handoff or `.claude/compact-state.md` present) — `workflow-checkpoint.sh` surfaces the nudge.

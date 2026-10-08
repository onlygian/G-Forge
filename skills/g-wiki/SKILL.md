---
name: g-wiki
description: Build and maintain a human-facing project wiki in g-wiki/ — narrative documentation of what the project is, how it's architected, how each major area works, and how to use it. Synthesizes from the codebase, ROADMAP, ADRs, and brief via the doc-writer agent. Run anytime; queued as a task at the end of every milestone so the wiki tracks the product. Distinct from /g-docs (which audits code-level doc hygiene — docstrings, READMEs, env vars, ADRs).
---

**Announce:** "Using g-wiki to update the project wiki."

You maintain the project's **wiki** — committed, human-facing documentation in `g-wiki/` that explains the project to a person (a new contributor, a user, your future self): what it is, how it's built, how each major area works, and how to use it. This is narrative product/architecture documentation, not code-level doc hygiene (that's `/g-docs`) and not the operational record (that's `g-docs/`).

The wiki lives in `g-wiki/` and **is committed** — it is real project content, never a runtime artifact.

## Step 1 — Scope

- **No argument** → incremental refresh: document what changed since the wiki was last updated (new/changed features this milestone), and reconcile existing pages against the current code.
- **An area/topic argument** (e.g. `/g-wiki auth`, `/g-wiki data model`) → write or refresh just that page.
- **`full`** → (re)generate the whole wiki from scratch. Use on first run or a major restructure.

State the chosen scope in one line and proceed.

## Step 2 — Establish the wiki structure

Create `g-wiki/` if it does not exist. The canonical layout:

| File | Purpose |
|------|---------|
| `g-wiki/README.md` | Landing page / index — what the project is in 2–3 sentences, the current state (from ROADMAP), and a linked table of contents to every other page. |
| `g-wiki/architecture.md` | System architecture — the layers/modules, how they fit, the key data flows, and the constraints that shaped them (cite in-force ADRs). |
| `g-wiki/<area>.md` | One page per major feature or subsystem — what it does, how it works, the important files, and the decisions behind it. |
| `g-wiki/usage.md` | Getting started / how to use or run the project — setup, common workflows, configuration. |

Don't invent pages with no content. Start with `README.md` + `architecture.md`, add `<area>.md` pages as real areas exist, and add `usage.md` once there's something to run.

## Step 3 — Gather sources (read, don't guess)

In parallel, read the ground truth so the wiki is accurate, not aspirational:
- The codebase — the actual module/directory structure and the key entry points (Glob the source tree; read the files that matter for the page in scope).
- `g-docs/ROADMAP.md` — milestones and the feature set (what exists vs. planned).
- `g-docs/project_brief.md` — goals, constraints, stack decisions.
- `g-docs/decisions/` — in-force ADRs (the "why" behind the architecture). Cite them; never contradict one.
- The most recent `g-docs/retros/` — recent changes worth reflecting.

If a page would describe something that doesn't exist in the code yet, mark it clearly as planned (from ROADMAP) rather than documenting vapor.

## Step 4 — Write via doc-writer

For each page in scope, dispatch the **`doc-writer`** agent with the gathered sources and the target file. `doc-writer` writes the WHY — constraints, invariants, non-obvious decisions — not a restatement of the code. Give it: the page's purpose (from Step 2), the relevant files, and the ADR/brief context.

**Dispatch shape — `doc-writer` has a 10-turn ceiling** (`maxTurns: 10`), and a read-everything-then-write run exhausts it after reading and before (or mid-) writing. So:
- **One page per dispatch.** A multi-section page is split into sequential dispatches, one section each, each told which sections already exist.
- **Tell it to write early and iterate:** create the page skeleton after the first source is read, then fill and correct it as it reads — never hold the whole page until every source is read.
- Pages are independent, so dispatch them in parallel; do not trust any of the output yet — Step 4b is what makes it trustworthy.

Pages must be:
- **Accurate** — every claim traceable to the code, ROADMAP, brief, or an ADR. No invented behavior.
- **Navigable** — every page linked from `g-wiki/README.md`'s table of contents; cross-link related pages.
- **Current** — when refreshing, reconcile against the code and flag anything that drifted (a page describing a removed/renamed thing) for correction rather than leaving it stale.

After writing the pages, update `g-wiki/README.md`'s index so the new/changed pages are linked.

## Step 4b — Verify (default-on)

Reference documentation is where plausible-but-wrong is most dangerous, and parallel `doc-writer` runs produce it confidently (a dogfooding pass of six parallel dispatches yielded 14 blocking accuracy findings: invented mechanics, fabricated figures, a documented command the tool cannot perform). So before reporting, run `/g-doc-review` over the wiki change — use Glob to find `skills/g-doc-review/SKILL.md` and follow it. On **DOCS HOLD**, re-dispatch `doc-writer` with the blocking findings (same dispatch shape as Step 4), then re-run `/g-doc-review`; repeat until **DOCS READY**. Do not fix findings yourself, and never report the wiki as updated on a HOLD.

Skipping the review is allowed only when the developer explicitly says so in this run; the Step 5 report must then say `review: skipped (developer waived)`.

## Step 5 — Report

```
g-wiki updated ✓  (scope: [incremental | <area> | full])

  Written / refreshed:
    · g-wiki/<file> — [one line]
  Flagged as drifted (need attention):
    · g-wiki/<file> — [what no longer matches the code]
  Index: g-wiki/README.md — [N pages linked]
```

Add the review line to the report: `Review: DOCS READY (rN)` (or `skipped (developer waived)`).

Committing is the developer's choice (the wiki is committed content, but `/g-wiki` doesn't bypass the commit gate). State that the wiki is ready to commit — the `/g-doc-review` run in Step 4b already stamped the doc sentinel the gate checks.

## When this runs

- **Anytime**, manually: `/g-wiki [area]`.
- **Offered at `/g-init`** as part of project setup (optional — the wiki can start empty and grow).
- **End of every milestone**: milestone close queues a `/g-wiki` task so the wiki tracks the product as it ships. Running it then keeps `architecture.md` and the area pages honest against what the milestone actually built.
- **Every session (per-project opt-in)**: a project that keeps its wiki under a stricter currency rule than milestone-close sets `.claude/wiki-cadence` to the single word `session`. `/g-retro` (the session-end ritual) then runs an incremental `/g-wiki` after writing the retro. Absent file, empty file, or `milestone` → the default above; any other value is treated as the default. The override only adds refreshes — milestone close always refreshes regardless.

## Rules

- `g-wiki/` is **committed** project content — never add it to `.gitignore`, never treat it as a runtime artifact. (Operational records go in `g-docs/`, which *is* git-ignored where appropriate; the wiki is not.)
- Document reality, not intent — read the code. Anything not yet built is labeled "planned," sourced from ROADMAP.
- Never contradict an in-force ADR; cite it as the rationale.
- Narrative and human-facing — explain how and why, with cross-links. This is not an API dump (that's `/g-docs`) and not a changelog.
- Incremental by default — don't rewrite stable, accurate pages; refresh what changed and fix what drifted.
- One page per real area. No empty scaffold pages.

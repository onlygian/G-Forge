---
name: g-retro
description: Synthesize a session retrospective from the silent-observer journal — no interview. Reads the passive activity log (.claude/journal/), git history, and g-docs/todo.md, and writes g-docs/retros/YYYY-MM-DD-topic.md with what happened, decisions inferred, patterns, and cold-start context.
context: [task, sprint, institutional]
---

**Announce:** "Using g-retro to synthesize a retrospective from the session journal."

No interview: the silent observer (`hooks/observe.sh` + `hooks/agent-lifecycle.sh`) already recorded what happened into an append-only daily journal. This skill reads that journal plus git and `g-docs/todo.md` and **synthesizes** — the developer verifies, never recalls.

## Step 1 — Determine topic

Use the topic argument as the slug if given (lowercase, hyphen-separated). Otherwise infer without stopping to ask: a `feat/ fix/ refactor/ chore/<slug>` branch gives `<slug>`; else infer a ≤30-char slug from the `## Active Session` handoff + `git log --oneline -5`. Print `Retro topic: [topic]` and proceed (rename the file if the developer corrects it afterward).

## Step 2 — Read the journal and project state

Read in parallel: `.claude/journal/*.jsonl` — today's file in full plus the two most recent prior days (lines are `{"ts","kind","detail"}`, `kind` ∈ `session · agent · commit · branch · test · push · merge · revert · destructive`) · the ROADMAP `## Active Session` handoff and active milestone · `g-docs/todo.md` Tasks table · `g-docs/todo-done.md` last 10 entries · the 🔄 milestone file under `g-docs/milestones/` (if any) · the active plan under `g-docs/plans/` for the branch slug or milestone (if any) · `git log --oneline -15` · `git branch --show-current`.

If `.claude/journal/` is missing or empty, print `No journal entries — synthesizing from git + todo only` and continue thinner.

## Step 3 — Synthesize (no interview)

Derive each section from evidence — read the signals, never ask:

- **What was done** ← `commit` journal entries + git log + closed todo-done entries, one bullet per logical unit of work, not per commit.
- **Decisions made** ← inferred from journal/commit evidence, each stated factually with its evidence; nothing inferable → `None inferred from journal.`
- **Patterns** ← clean signals (*Worked well*) vs friction signals (*Avoid / do differently*); an empty category → `None observed.`
- **Cold-start context** ← branch, active milestone, key files touched (unique basenames this session), carry-over context (the handoff "Active context" line), and **Next up derived from evidence** — in order: (1) an explicit developer directive this session (stated in-session or recorded in the journal); (2) the active plan's next incomplete wave; (3) the active milestone's next unchecked task; (4) the lead open `g-docs/todo.md` row; (5) else the old handoff's "Next up" line, marked `(carried — no open task found)`.

For the full signal catalogs, decision-inference examples, and the derivation rationale, load `references/synthesis-signals.md`.

## Step 4 — Forecast outcome reconciliation (conditional, evidence-based)

Derive the active plan slug deterministically: branch `feat/<slug>` etc. → `<slug>` when `g-docs/forecasts/<slug>.md` exists; else the most-recently-modified `g-docs/forecasts/*.md` whose `g-docs/plans/<slug>.md` has an incomplete wave. None → skip this step silently.

If a forecast file is found, **load `references/forecast-reconciliation.md` — unconditionally, before writing anything** — and reconcile that file's `## Outcome` table from journal/git evidence per that reference (verdict + evidence tag + the `mitigation-held:` marker rule). Never guess a positive — anything unsubstantiated is `unverified`.

## Step 5 — Write the retro file

Create `g-docs/retros/` if needed. File: `g-docs/retros/YYYY-MM-DD-[topic].md` (today's date + slug), with this exact structure:

```markdown
# Retro: [topic] — [YYYY-MM-DD]

## What was done
[bullet list derived from journal commits + git log + closed g-docs/todo-done.md entries — one bullet per logical unit of work]

## Decisions made
[inferred from journal/commit evidence, each with its evidence; or "None inferred from journal."]

## Patterns
### Worked well
[evidence-backed positives, or "None observed."]
### Avoid / do differently
[evidence-backed friction signals, or "None observed."]

## Cold-start context
**Branch:** [current branch]
**Active milestone:** [milestone name and status]
**Next up:** [derived from evidence per Step 3 — developer directive this session, else the active plan's next incomplete wave, else the active milestone's next unchecked task, else the lead open `g-docs/todo.md` row, else the old handoff's "Next up" line marked "(carried — no open task found)"]
**Handoff at retro:** [the "Next up" line the handoff carried when the retro ran, verbatim]
**Key files touched:** [comma-separated basenames from git log this session]
**Carry-over context:** [the "Active context" line from the ROADMAP `## Active Session` handoff]

## Journal basis
[count of journal events read, by kind — e.g. "8 commit · 3 test · 12 agent · 1 revert", or "No journal — git + todo only"]
```

Do not add extra sections.

**Record density (hard bar).** Target ≤350 words excluding headings: What was done ≤7 one-line bullets; Decisions ≤5 bullets with evidence in parens; ≤4 one-line bullets per Patterns subsection; every Cold-start `**Field:**` line exactly one line (never dropped — each is read downstream); Journal basis one line. Over a cap → distill (cite SHAs/paths instead of describing), never truncate meaning, never pad to the cap. Caps constrain length only — headings and field names are unchanged.

## Step 5b — Refresh the ROADMAP handoff

`/g-retro` is the session-end ritual, so it owns refreshing the single canonical handoff — the `## Active Session` block in `g-docs/ROADMAP.md`. Rewrite that block (replace, never append) in the G-RULES §I format — don't restate the format here, fill it from this retro:
- **Done this pass** ← one-line summary of "What was done"
- **Next up** ← this retro's derived Next up (Step 3) — never the previous handoff's line
- **Active context** ← the carry-over context line

**The whole block is ≤150 words** (Done this pass ≤1 line; Next up 1 imperative line; Active context ≤2 lines — `workflow-checkpoint.sh` re-reads the Active context line every prompt, so its length is a per-prompt tax). If no `## Active Session` block exists, insert one directly after the top `# ` title. Committing is the developer's choice; writing the block is not. The §A7 reset, `/g-review`'s milestone close, and `/g-adr` all run `/g-retro` and delegate this write here (the one exception: a plain end-of-pass update with no retro, done directly per §A3).

## Step 6 — Surface for verification

Report the path and print the **Cold-start context** and **Patterns** sections verbatim so the developer can correct the synthesis:

```
Retro written: g-docs/retros/YYYY-MM-DD-[topic].md  (synthesized from [N] journal events)

--- Patterns ---
[paste]

--- Cold-start context ---
[paste]
```

If the developer corrects a section, edit the file and re-print only that section.

## Step 7 — Pattern suggestions (informational)

Read every retro under `g-docs/retros/` (including the one just written), drop `None recorded.` / `None observed.` sentinels, extract the `Avoid / do differently` bullets, group by normalised label, and count distinct source files. Any label with ≥2 source files → print the `Pattern signal` block and suggest `/g-patterns`; none → print nothing. Never modify rule files from inside `/g-retro` — surfacing is the cap.

## Rules
- **No interview.** Never block on a question — the journal and git are the sources of truth. (Step 1's one-line topic statement is not a blocking question.)
- Evidence-backed synthesis — every decision and pattern traces to a journal entry, commit, or todo line; anything unsubstantiated is marked inferred/unverified.
- Today's date for the filename — never inferred from git history. Collision → append `-2` and note it.
- Never commit the retro file — writing it is the done condition.
- Keep "What was done" at the logical-work level, not the commit level.
- If journal and todo ledgers are all absent, synthesize from git log alone and note the gap.
- **Density is a hard bar** — the Step 5 caps and the ≤150-word handoff apply always; when over, distill (pointers over paste), never pad.
- No opinions or follow-up recommendations in the retro file — it is a factual record.

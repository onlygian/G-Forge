---
name: g-retro
description: Synthesize a session retrospective from the silent-observer journal — no interview. Reads the passive activity log (.claude/journal/), git history, and g-docs/todo.md, and writes g-docs/retros/YYYY-MM-DD-topic.md with what happened, decisions inferred, patterns, and cold-start context.
context: [task, sprint, institutional]
---

**Announce:** "Using g-retro to synthesize a retrospective from the session journal."

g-retro no longer interviews. The silent observer (`hooks/observe.sh` + `hooks/agent-lifecycle.sh`) records what actually happened as it happens — commits, branches, tests, pushes, agent dispatches, reverts — into an append-only daily journal. This skill reads that journal plus git and `g-docs/todo.md`, then **synthesizes** the retro. The developer's job is to verify, not to recall.

## Step 1 — Determine topic

If the user provided a topic argument, use it as the slug (lowercase, hyphen-separated, e.g. `auth-refactor`).

Otherwise infer a slug automatically — do **not** stop to ask:
1. If the current branch matches `feat/<slug>`, `fix/<slug>`, `refactor/<slug>`, or `chore/<slug>`, use `<slug>`.
2. Else read the `## Active Session` handoff in `g-docs/ROADMAP.md` and `git log --oneline -5` and infer a short descriptive slug capturing the session's main theme (e.g. `precompact-hook`, `m3-wave2`).
3. Keep it under 30 characters.

State the chosen topic in one line and proceed: `Retro topic: [topic]`. If the developer corrects it afterward, rename the file.

## Step 2 — Read the journal and project state

Read the following in parallel:

- **The observer journal** — `.claude/journal/*.jsonl`. Read today's file in full and the two most recent prior days (the work being retro'd may span sessions). Each line is `{"ts","kind","detail"}` with `kind` ∈ `session · agent · commit · branch · test · push · merge · revert · destructive`.
- `g-docs/ROADMAP.md` — the `## Active Session` handoff (Done this pass / Next up / Active context) and the active milestone.
- `g-docs/todo.md` — the Tasks table (tactical ledger; no handoff lives here).
- `g-docs/todo-done.md` — last 10 entries (read from the end of the file).
- **The active milestone file** — the `g-docs/milestones/M*.md` marked 🔄 In progress in `g-docs/ROADMAP.md`, if one exists — Step 3's Next-up derivation reads its next unchecked task.
- **The active plan** — the `g-docs/plans/*.md` for the current branch slug or milestone, if one exists — Step 3's Next-up derivation reads its next incomplete wave.
- `git log --oneline -15` via Bash.
- `git branch --show-current` via Bash.

If `.claude/journal/` does not exist or is empty (e.g. the observer never fired this session, or the project predates it), say so in one line — `No journal entries — synthesizing from git + todo only` — and continue with git + todo as the sources. The retro is still produced; it is just thinner.

## Step 3 — Synthesize (no interview)

Derive each section from evidence. Do not ask the developer questions — read the signals.

- **What was done** — from `commit` journal entries + git log + closed `g-docs/todo-done.md` entries. One bullet per logical unit of work, not per commit. Group related commits.
- **Decisions made** — infer from the journal and commit messages: a `branch` event starting `refactor/*` plus its commits implies an approach decision; a `revert` followed by a different fix implies a reversed decision; a new dependency in a commit implies a library choice. State each as a factual observation, e.g. "Adopted X over Y (commit abc123 replaced the Z approach)." If nothing is inferable, write `None inferred from journal.`
- **Patterns** —
  - *Worked well*: clean signal — tests run before commits (`test` entries preceding `commit` entries), no reverts, no `destructive` flags, agents finishing without re-dispatch.
  - *Avoid / do differently*: friction signal — `revert` entries, repeated `test` failures before a commit, `destructive` flags, the same agent dispatched repeatedly on one task, or commits with `fix-of-fix`/`take 2`/`retry` messages.
  - If a category has no signal, write `None observed.`
- **Cold-start context** — branch, active milestone (from `g-docs/ROADMAP.md`), **Next up derived from evidence** — in order: (1) an explicit developer directive given this session about what happens next (stated in-session or recorded in the journal); (2) the next incomplete wave in the active `g-docs/plans/*.md`; (3) the active milestone's next unchecked task in `g-docs/milestones/M*.md`; (4) the lead open row of `g-docs/todo.md`'s `## Tasks` table; (5) else fall back to the old handoff's "Next up" line (verbatim from the `## Active Session` handoff in `g-docs/ROADMAP.md`), marked `(carried — no open task found)` (intent-proximate sources first — a todo lead row is often a long-lived carry, not the next action) — key files touched (unique basenames across the git log this session), and carry-over context (from the handoff "Active context" line).

## Step 4 — Forecast outcome reconciliation (conditional, evidence-based)

Derive the active plan slug deterministically:
1. Branch name `feat/<slug>` etc. → `<slug>`.
2. `g-docs/forecasts/<candidate>.md` exists → that is the active plan.
3. Fallback: most-recently-modified `g-docs/forecasts/*.md` whose `g-docs/plans/<slug>.md` has an incomplete wave. If none, skip this step silently.

If a forecast file is found, reconcile its predicted scenarios against the journal evidence rather than asking the developer:
- For each predicted scenario, mark `happened` / `did not happen` / `unverified` based on journal + git signals (e.g. a forecasted "auth refactor will cause regressions" is `happened` if reverts or HOLD-related rework appear around the auth files).
- Update the `## Outcome` table in the forecast file with the verdict **and** a one-word evidence tag (`journal` / `git` / `unverified`). This keeps the `/g-patterns` feedback loop running without a manual interview. Mark anything you cannot substantiate as `unverified` — never guess a positive.
- **`mitigation-held:` marker.** If the verdict for a row is `did not happen` / `no` (the scenario did NOT materialize) AND the forecast's recorded `Mitigation` for that scenario was demonstrably applied during the pass and held — journal, git, or record evidence shows the mitigating action was taken and the predicted failure never occurred — begin that row's Notes cell with the literal token `mitigation-held:` followed by the evidence (e.g. `mitigation-held: tests run before every commit this pass (journal)`). This is the only condition that earns the marker; a scenario that simply didn't happen with no applied mitigation gets no marker. `/g-forecast` Step 5b reads this token verbatim to award half credit instead of zero — do not paraphrase or omit the leading token.

## Step 5 — Write the retro file

Create `g-docs/retros/` if it does not exist. Use today's date (`YYYY-MM-DD`) and the topic slug: `g-docs/retros/YYYY-MM-DD-[topic].md`.

Write the file with this exact structure:

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

## Step 5b — Refresh the ROADMAP handoff

`/g-retro` is the session-end ritual, so it **owns** refreshing the single canonical handoff — the `## Active Session` block in `g-docs/ROADMAP.md` — from the cold-start it just synthesized. This is what guarantees the next session opens with an accurate target.

Rewrite that block (replace, never append) using the canonical format defined in **G-RULES §I** (Project Tracking) — don't restate the format here, fill it from this retro:
- **Done this pass** ← one-line summary of "What was done"
- **Next up** ← the derived Next up from this retro's Cold-start context (Step 3) — never the previous handoff's Next up line
- **Active context** ← the carry-over context line

If `g-docs/ROADMAP.md` has no `## Active Session` block yet (older project), insert one directly after the top `# ` title. Committing the change is the developer's choice (same as the retro file), but the block must be written.

This is the only place the handoff *write* is spelled out. The §A7 reset, `/g-review`'s milestone close, and `/g-adr`'s decision-hygiene handoff all run `/g-retro` — they delegate the write here rather than re-implementing it. The one routine exception is a plain end-of-pass update with no retro, which HQ does directly per §A3 (same block, same §I format).

## Step 6 — Surface for verification

Report the file path and print the **Cold-start context** and **Patterns** sections verbatim so the developer can correct anything the synthesis got wrong:

```
Retro written: g-docs/retros/YYYY-MM-DD-[topic].md  (synthesized from [N] journal events)

--- Patterns ---
[paste]

--- Cold-start context ---
[paste]
```

If the developer corrects a section, edit the file and re-print only the corrected section.

## Step 7 — Pattern suggestions (informational)

After writing, surface any ≥2-occurrence patterns this retro contributes to — same as before:
1. Read every retro under `g-docs/retros/`, including the one just written.
2. Apply the `None recorded.` / `None observed.` sentinel filter.
3. Extract `Avoid / do differently` bullets, group by normalised label, count distinct source files.

If any label now has ≥2 source files, print the `Pattern signal` block and suggest `/g-patterns`. If none reach ≥2, print nothing. Never modify rule files from inside `/g-retro` — surfacing is the cap.

## Rules
- **No interview.** Never block on a question. The journal and git are the sources of truth; the developer verifies the output, they do not supply it. (A single one-line topic statement in Step 1 is not a blocking question.)
- Synthesis must be evidence-backed — every decision and pattern traces to a journal entry, commit, or todo line. Mark anything unsubstantiated as inferred/unverified rather than asserting it.
- Use today's date for the filename — never infer the date from git history.
- One retro file per session — if a retro file already exists for today's topic, append a `-2` suffix rather than overwriting, and note it.
- Do not commit the retro file — writing it is the done condition; committing is the developer's choice.
- Keep "What was done" at the logical-work level, not the commit level.
- If `.claude/journal/`, `g-docs/todo.md`, and `g-docs/todo-done.md` are all absent, synthesize from git log alone and note the gap.
- Never add opinions or follow-up recommendations to the retro file — it is a factual record.

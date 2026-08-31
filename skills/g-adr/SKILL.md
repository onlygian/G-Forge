---
name: g-adr
description: Capture an architectural decision record. First triages whether the decision merits an ADR or just a one-line entry in the brief's tech-decisions table (keeping the corpus rare and high-signal). Captures pre-deliberated reasoning or interviews from scratch, offloads the high-branching weighing to a throwaway deliberation subagent (keeps HQ's context clean), and promotes only the finalized draft to g-docs/decisions/NNN-title.md. Runs a mandatory reversibility check + premortem (premortem depth scales with reversibility) so the developer has the full picture before building. On a consequential decision it closes the loop — runs /g-retro and recommends a fresh session whose first task is verifying the ADR. Run when making a significant technical choice.
---

**Announce:** "Using g-adr to record an architectural decision."

Architectural decisions undocumented become invisible. New team members re-litigate settled choices. Drift happens without anyone knowing why the original constraint existed. This skill captures decisions while the context is fresh — and it does so without poisoning HQ's own window with the deliberation that produced them.

> **Why this skill is built the way it is.** Weighing options is exactly the high-branching reasoning that poisons a context (G-RULES §C): three-way pattern debates, rejected alternatives, and wrong first guesses all stay in-window and drag on everything HQ does next. The single-use doctrine applies to HQ's *own* deliberation, not just dispatched agents. So this skill offloads the weighing to a throwaway subagent and promotes only the finished answer — and, once a consequential decision is finalized, it resets the residue: retro, then verify from a fresh session.

## Step 1 — Establish the title, then triage the entry

### Title

**If an argument was provided** (e.g. `/g-adr "use PostgreSQL instead of SQLite"`):
- Use it as the working title. Confirm: "Recording ADR: '[title]' — is that the right framing?"
- Wait for confirmation or correction.

**If no argument was provided**, ask:
> "What decision are you recording? Give it a short, verb-first title — e.g. 'Use Pinia over Vuex', 'Adopt server-side rendering for marketing pages', 'Keep auth stateless with JWTs'."

Wait for the title.

### Entry triage — ADR, brief row, or nothing?

ADRs are only valuable while they stay **rare and high-signal**; a full record on a small, local choice dilutes the corpus. Before running the interview, place the decision:

- **ADR** — a significant architectural choice: a new stack component or external dependency, a pattern applied project-wide, a structural constraint, or replacing an existing approach. → proceed to Step 2.
- **Brief row** — contained, local, and reversible (one component, undoable in roughly a day, nothing else commits to it). This is **not** an ADR; it belongs as a one-line entry in `g-docs/project_brief.md`'s tech-decisions table. → offer to add that line, then stop — do not run the interview. (No `g-docs/project_brief.md`? Note it in the commit/chat, or record a minimal ADR if the developer prefers.)
- **Nothing** — a routine implementation detail with no lasting rationale. → say so; record nothing.

**Propose, don't impose:** state the call with one line of evidence and let the developer confirm or override — e.g. "This looks like a **brief row** — contained and reversible. Record it as a tech-decisions line instead of a full ADR, or override and record the ADR anyway?" On override toward ADR, proceed. **Reversibility is the tell** — a contained, reversible change is almost always a brief row, not an ADR.

## Step 2 — Gather raw inputs

First, pick the capture mode — ask once and wait:

> "Have you already worked this decision out (in a prior session, a doc, or your head), or do you want me to interview you from scratch?
> **(a)** I've worked it out — I'll give you the reasoning, you structure it.
> **(b)** Interview me — ask me one question at a time."

- **(a) Pre-deliberated capture** — the developer pastes or dictates their worked-out reasoning. Map it onto the seven fields below yourself, then ask **only about the fields they left genuinely empty** (a targeted gap-fill, not the full sequence). This is the fast path for decisions already reasoned out off the interview — the deliberation happened elsewhere; you are capturing it, not re-running it.
- **(b) Interview from scratch** — the default. Ask each question in sequence; wait for the answer before the next. Do not batch them.

Either way you are collecting the developer's raw inputs — facts, options on the table, constraints. You are gathering material, not yet weighing it.

**Q1 — Context:** "What situation, problem, or requirement forced this decision? Include constraints (performance, team skill, cost, existing infrastructure) that shaped the options."
**Q2 — Decision:** "What did you decide, specifically? Name the technology, pattern, or approach. Be concrete — 'use X', not 'improve Y'."
**Q3 — Alternatives:** "What other options did you evaluate? Name each."
**Q4 — Consequences (as you see them):** "What becomes easier? What becomes harder or off the table? Any risks or follow-up decisions?"
**Q5 — Status:** "Accepted (in effect) · Proposed (under discussion) · Deprecated · Superseded by ADR-NNN (which)?"
**Q6 — Constraints that drove it:** "What constraints (time, team, compatibility, compliance, cost) were the primary drivers? Would you decide differently without them?"
**Q7 — Assumptions:** "What is this decision relying on? Which assumptions are most likely to be invalidated later?"

Keep it to raw answers — do not start analyzing the trade-offs yourself. That happens in Step 3, off-context.

## Step 3 — Deliberate off-context (throwaway subagent)

Dispatch a **single-use deliberation subagent** to do the weighing and drafting. This is the load-bearing step: the messy comparison happens in the subagent's window, never in HQ's.

Dispatch one general-purpose subagent with this prompt (fill in the raw inputs from Step 2):

```
You are a single-use decision analyst. Stress-test and structure an architectural
decision — do NOT make it; the developer already has. Return ONLY the finalized ADR
body below. Do not return your reasoning, comparisons, or any exploration — only the
distilled result crosses back.

Decision title: [title]
Developer's raw inputs:
  Context: [Q1]
  Decision: [Q2]
  Alternatives named: [Q3]
  Consequences (developer's view): [Q4]
  Status: [Q5]
  Constraints: [Q6]
  Assumptions: [Q7]

Read g-docs/project_brief.md, CLAUDE.md (layer map / import rules), and any directly relevant
source to ground the analysis. Then produce:

1. A rigorous "Alternatives considered" table (option → why rejected), including any
   strong alternative the developer did not name but should have.
2. A "Consequences" block: Easier / Harder-constrained / Follow-up decisions / Risks.
3. A "Rejected Alternatives" table (alternative → deciding factor).
4. "Assumptions That Held" — each with its fragility.
5. "Constraints That Drove This Decision".
6. WEAKNESSES: a short list of any place the rationale is thin, an assumption is load-
   bearing-and-fragile, or a rejected option deserves a second look. (This is the one
   place you may flag judgment — keep it to bullet points, no narrative.)

Return ONLY those six sections. No preamble, no reasoning trace.
```

The subagent is single-use and discarded after it returns. You never see its deliberation — only the finalized sections. **Do not** re-prompt it or continue its context; if the draft needs rework, dispatch a fresh one with the adjustment.

## Step 4 — Promote across the seam

Present the subagent's finalized draft to the developer for approval — this is the clean contract crossing the boundary:

> "Here's the structured decision record. I had it stress-tested off-context — note the **weaknesses** flagged at the bottom. Approve as-is, or tell me what to change."

Show the draft plus the WEAKNESSES list. If the developer wants substantive changes to the analysis, dispatch a **fresh** deliberation subagent with the adjustment (never re-prompt the spent one). Minor wording edits, apply directly. Drop the WEAKNESSES section from the final ADR — it is decision-support, not part of the record. Loop until the developer approves.

## Step 5 — Determine ADR number

```bash
find . -path "*/g-docs/decisions/*.md" -not -path "*/node_modules/*" | sort
```

If `g-docs/decisions/` does not exist, create it. Next number = highest existing + 1, zero-padded to 3 digits. If none exist, start at 001.

## Step 6 — Write the ADR

Derive a kebab-case filename from the title (e.g. "Use PostgreSQL instead of SQLite" → `001-use-postgresql-instead-of-sqlite.md`). Write to `g-docs/decisions/[NNN]-[kebab-title].md`:

```markdown
# ADR-[NNN]: [Title]

**Date:** [YYYY-MM-DD]
**Status:** [Accepted | Proposed | Deprecated | Superseded by ADR-NNN]
**Reversibility:** [two-way door (reversible) | one-way door (hard to reverse) — set in Step 8]
**Context:** [project name or area this applies to]

## Context

[Q1 — situation, problem, constraints. 2–5 sentences.]

## Decision

[Q2 — what was chosen, specifically. 1–3 sentences.]

## Alternatives considered

| Option | Why rejected |
|--------|-------------|
| [from the promoted draft] | [reason] |

## Consequences

**Easier:** [what this enables]
**Harder / constrained:** [what this makes more difficult or rules out]
**Follow-up decisions:** [any decisions this creates or defers — or "none"]
**Risks:** [known risks — or "none identified"]

## Rejected Alternatives

| Alternative | Why rejected |
|-------------|--------------|
| [name] | [deciding factor] |

## Assumptions That Held

- [assumption and its fragility]

## Constraints That Drove This Decision

- [constraint: time/team/compliance/cost/etc.]
```

## Step 7 — Surface follow-up actions

Check downstream files:
- Affects architecture: "Does this change the layer map or import rules in CLAUDE.md? Update it or run `/g-specialize` to reinstall the profile."
- New external dependency: "Consider adding it to `g-docs/project_brief.md`'s tech decisions table."
- Deprecates a previous approach: "If an ADR exists for the old approach, set its status to Deprecated and add 'Superseded by ADR-[NNN]'."

Report:
```
ADR-[NNN] written: g-docs/decisions/[NNN]-[title].md
Status: [Accepted | Proposed | ...]

[Follow-up actions if any, or "No follow-up actions identified."]
```

## Step 8 — Reversibility check + premortem (mandatory)

Before recommending anything be built on this decision, give the developer the full picture: *how hard is it to undo, and how is it most likely to fail?* This runs for **every** ADR — it is the one always-on decision-support pass, and the developer should have it before pulling the trigger on downstream work.

1. **Reversibility check (always, cheap).** Classify the decision and confirm with the developer:
   - **Two-way door** — reversible at low cost; you could undo it in roughly a day and little else commits to it. Proceed lightly.
   - **One-way door** — expensive or impossible to reverse; other code, data, public contracts, or external dependencies will commit to it. Proceed with care.

   Reversibility — not self-rated "importance" — is the signal that scales the rest of this step. Update the ADR's **Reversibility** header line with the verdict.

2. **Premortem, scaled by reversibility.** Assume the decision has failed badly some months out; surface the likely causes *now*.
   - **Two-way door →** a quick inline read: state the single most likely failure mode and its earliest warning sign. One or two lines. Do not dispatch a subagent.
   - **One-way door →** dispatch a **single-use throwaway premortem subagent** (premortem is high-branching failure reasoning — running it inline poisons HQ's window, the same reason Step 3 is offloaded). Prompt it:
     > "A team shipped this decision: [Decision + the one-line Context]. Assume that six months from now it has failed badly. Give the 3–5 most likely failure causes, ranked by likelihood × impact, each with its earliest observable warning sign. Return ONLY the ranked list — no preamble, no reasoning trace."
     The subagent is discarded after it returns; never re-prompt it.

3. **Present, don't bury.** Show the developer the reversibility verdict and the premortem findings together:
   > "Reversibility: **[two-way / one-way door]**. Premortem surfaced these failure modes: [list]. You've got the full picture before anything builds on this."

   The premortem is decision-support, like the Step 4 WEAKNESSES list — it is **not** written into the ADR verbatim. If a failure mode is serious enough to belong in the record, offer to fold it into the ADR's **Risks** or **Assumptions That Held** before finalizing.

## Step 9 — Close the circle (consequential, Accepted decisions only)

A finalized ADR is a high-stakes artifact produced through deliberation. Even with the weighing offloaded, this session's window now carries the interview and the promotion loop — you should not keep building architecture on top of it, and the ADR itself was produced in a context that should be **checked, not trusted from memory** (airtight = checked, not remembered).

**This reuses the existing session-reset path, it does not invent one.** The context gate (G-RULES §A7, driven by the exchange counter in `workflow-checkpoint.sh`) already runs exactly this reset — auto-`/g-retro` + handoff write + "open a fresh session" — when the *quantitative* trigger fires (exchange count hits red). Finalizing a consequential ADR is the *semantic* trigger for the same response: you don't wait for the exchange count to climb, because an architecture decision warrants the reset now. Same path, different trigger.

Apply this step only when the ADR is **Accepted** and consequential (a real stack / pattern / dependency / layer decision — the skill's normal case). For a **Proposed** ADR or a minor record, skip this step and stop after Step 8 (the reversibility check + premortem still ran — it is mandatory; only the session-reset is consequential-only).

1. **Promote the record — run `/g-retro`** (the same `/g-retro` the context gate triggers at red). Use Glob to find `skills/g-retro/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and follow it; topic slug `adr-[NNN]-[short]`. The observer journal already captured the session; the retro distills it into the durable record. **Skip if a retro has already run or is scheduled this session** — e.g. the §A7 red gate already fired, or you reached `/g-adr` via `/g-review`'s milestone close, which runs `/g-retro` itself. Don't double-retro.

2. **Write the handoff** — the same `## Active Session` block §A7 writes on reset, in `g-docs/ROADMAP.md`. Set its "Next up" line (additively, don't clobber existing handoff content) to lead with:
   > `⚠ FIRST: verify ADR-[NNN] against the actual repo state before building on it (clean-slate check).`
   If `g-docs/ROADMAP.md` has no `## Active Session` block, insert one after the title (or carry the task in the chat recommendation only if there is no `g-docs/ROADMAP.md`).

3. **Recommend a fresh session** (the same recommendation the red gate makes). Tell the developer:
   > "ADR-[NNN] is finalized. This session's context now carries the deliberation that produced it — that's residue I shouldn't keep building on, and the ADR itself is an airtight answer that should be *checked*, not trusted from memory. Recommend: **start a fresh session and run `/g-resume`** — it re-hydrates a clean window with the handoff, this retro, and ADR-[NNN], and offers to verify the decision against the actual repo as the first task. You lose the residue, not the knowledge."

   This is a recommendation, not a gate — the developer decides. Do not force a new session or block further work.

## Rules
- Never reconstruct past decisions from code alone — the developer provides the context (Step 2).
- The weighing happens in the Step 3 subagent, never in HQ. If you catch yourself drafting the alternatives analysis inline, stop and dispatch — that is the poison this skill exists to avoid.
- Single-use all the way down: never re-prompt or continue the deliberation subagent. Rework = a fresh dispatch.
- If the developer cannot articulate why the decision was made, record what is known and mark Context with `[Note: rationale partially reconstructed — verify with original decision-makers]`.
- Do not editorialize the decision in the ADR — record it faithfully. The WEAKNESSES list (Step 4) and the premortem findings (Step 8) are decision-support shown to the developer and are NOT written into the ADR file — except the reversibility verdict, which is recorded, and any failure mode the developer chooses to fold into Risks/Assumptions.
- Still-debated decision → status **Proposed**, record the leading option, skip Step 9 (close the circle). The Step 8 reversibility check + premortem still runs. Update to **Accepted** when confirmed.
- The Step 8 reversibility check + premortem is mandatory and runs for every ADR; the premortem's depth scales with reversibility (inline for a two-way door, an off-context subagent for a one-way door). It is decision-support, not a gate — never block on it.
- ADR numbers are permanent. Never renumber existing ADRs.
- Step 9 is a recommendation, never a gate. The developer owns whether to open a fresh session.

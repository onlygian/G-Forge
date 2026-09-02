---
name: g-adr
description: Capture an architectural decision record. First triages whether the decision merits an ADR or just a one-line entry in the brief's tech-decisions table (keeping the corpus rare and high-signal). Captures pre-deliberated reasoning or interviews from scratch, offloads the high-branching weighing to a throwaway deliberation subagent (keeps HQ's context clean), and promotes only the finalized draft to g-docs/decisions/NNN-title.md. Runs a mandatory reversibility check + premortem (premortem depth scales with reversibility) so the developer has the full picture before building. On a consequential decision it closes the loop — runs /g-retro and recommends a fresh session whose first task is verifying the ADR. Run when making a significant technical choice.
---

**Announce:** "Using g-adr to record an architectural decision."

This skill captures decisions while the context is fresh — without poisoning HQ's own window with the deliberation that produced them (full rationale: `references/why-offload-and-reset.md`, read only if the developer pushes back or a maintainer asks why).

## Step 1 — Establish the title, then triage the entry

**Title.** With an argument: use it as the working title, confirm "Recording ADR: '[title]' — is that the right framing?" and wait. Without one, ask for a short, verb-first title (e.g. 'Use Pinia over Vuex') and wait.

**Entry triage — ADR, brief row, or nothing?** ADRs stay rare and high-signal; place the decision before interviewing:
- **ADR** — significant architectural choice: new stack component or external dependency, project-wide pattern, structural constraint, or replacing an existing approach → Step 2.
- **Brief row** — contained, local, reversible (one component, undoable in roughly a day, nothing else commits to it) → offer a one-line entry in `g-docs/project_brief.md`'s tech-decisions table, then stop — no interview. (No brief? Note it in the commit/chat, or a minimal ADR if the developer prefers.)
- **Nothing** — routine implementation detail, no lasting rationale → say so; record nothing.

**Propose, don't impose:** state the call with one line of evidence; the developer confirms or overrides (override toward ADR → proceed). **Reversibility is the tell** — contained and reversible is almost always a brief row, not an ADR.

## Step 2 — Gather raw inputs

Pick the capture mode — ask once and wait:
> "Have you already worked this decision out (in a prior session, a doc, or your head), or do you want me to interview you from scratch?
> **(a)** I've worked it out — I'll give you the reasoning, you structure it.
> **(b)** Interview me — ask me one question at a time."

- **(a) Pre-deliberated capture** — map the developer's reasoning onto the seven fields — **Context, Decision, Alternatives, Consequences, Status, Constraints, Assumptions** — then ask only about fields left genuinely empty (targeted gap-fill, not the full sequence).
- **(b) Interview from scratch** — the default: ask Q1–Q7 **verbatim from `references/interview-questions.md`**, one at a time, never batched.

Either way: gather, don't weigh. No trade-off analysis here — that happens off-context in Step 3.

## Step 3 — Deliberate off-context (throwaway subagent)

Dispatch one **single-use** general-purpose deliberation subagent with the Deliberation prompt in `references/subagent-prompts.md`, filled in verbatim with the Step 2 inputs. Only the six finalized sections cross back — you never see its deliberation. Never re-prompt or continue it; rework = a fresh dispatch.

## Step 4 — Promote across the seam

Present the draft: "Here's the structured decision record. I had it stress-tested off-context — note the **weaknesses** flagged at the bottom. Approve as-is, or tell me what to change." Substantive analysis changes → fresh subagent; minor wording → apply directly. Drop the WEAKNESSES section from the final ADR — decision-support only. Loop until approved.

## Step 5 — Determine ADR number

Run `scripts/next-adr.sh "[title]"` and use its `NEXT:` and `FILENAME:` lines (contract in the script header). On any `NOTE:` anomaly, verify by eye before writing — numbers are permanent.

## Step 6 — Write the ADR

Write `g-docs/decisions/[NNN]-[kebab-title].md` from the template in `references/adr-template.md` — byte-identical structure; its Status/Reversibility closed sets and section headings must not drift.

## Step 7 — Surface follow-up actions

Check downstream: affects architecture → "Does this change the layer map or import rules in CLAUDE.md? Update it or run `/g-specialize`." · new external dependency → suggest a brief tech-decisions row · deprecates a previous approach → set that ADR to Deprecated + 'Superseded by ADR-[NNN]'.

Report:
```
ADR-[NNN] written: g-docs/decisions/[NNN]-[title].md
Status: [Accepted | Proposed | ...]

[Follow-up actions if any, or "No follow-up actions identified."]
```

## Step 8 — Reversibility check + premortem (mandatory)

Runs for **every** ADR — the developer sees *how hard to undo, and how it most likely fails* before anything builds on the decision.

1. **Reversibility check (always, cheap).** Classify and confirm: **two-way door** — reversible at low cost, undoable in roughly a day, little else commits to it; **one-way door** — expensive or impossible to reverse; code, data, public contracts, or external dependencies will commit to it. Reversibility — not self-rated importance — scales the rest. Update the ADR's **Reversibility** header line with the verdict.
2. **Premortem, scaled by reversibility.** Two-way → inline: the single most likely failure mode and its earliest warning sign, one or two lines, no subagent. One-way → dispatch a **single-use** premortem subagent with the Premortem prompt in `references/subagent-prompts.md`; discard after it returns; never re-prompt.
3. **Present, don't bury:** "Reversibility: **[two-way / one-way door]**. Premortem surfaced these failure modes: [list]. You've got the full picture before anything builds on this." The premortem is decision-support, not written into the ADR — except the reversibility verdict, and any failure mode the developer folds into **Risks** or **Assumptions That Held**.

## Step 9 — Close the circle (consequential, Accepted decisions only)

This session's window now carries the interview and promotion loop; a consequential **Accepted** ADR (real stack / pattern / dependency / layer decision) is the *semantic* trigger for the same session-reset the §A7 context gate runs on its *quantitative* trigger — same path, different trigger (`references/why-offload-and-reset.md`). Proposed or minor ADR → skip this step and stop after Step 8.

1. **Run `/g-retro`** (the same one the context gate triggers at red) — Glob `skills/g-retro/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and follow it; topic slug `adr-[NNN]-[short]`. It writes the handoff — delegate the write there, never re-implement it. **Skip if a retro already ran or is scheduled this session** (e.g. §A7 red fired, or `/g-review`'s milestone close ran it) — don't double-retro.
2. **Set the handoff's "Next up" lead line** in `g-docs/ROADMAP.md`'s `## Active Session` block (additively — don't clobber existing handoff content):
   > `⚠ FIRST: verify ADR-[NNN] against the actual repo state before building on it (clean-slate check).`
   No `## Active Session` block → insert one after the title (or carry the task in the chat recommendation only, if there is no `g-docs/ROADMAP.md`).
3. **Recommend a fresh session:** "ADR-[NNN] is finalized. This session carries the deliberation residue — recommend: **start a fresh session and run `/g-resume`**. It re-hydrates a clean window with the handoff, this retro, and ADR-[NNN], and offers to verify the decision against the actual repo as the first task. You lose the residue, not the knowledge." This is a recommendation, not a gate — the developer decides; never force a new session or block further work.

## Rules
- Never reconstruct past decisions from code alone — the developer provides the context (Step 2).
- The weighing happens in the Step 3 subagent, never in HQ. Catch yourself drafting the alternatives analysis inline → stop and dispatch.
- Single-use all the way down: never re-prompt or continue a deliberation or premortem subagent. Rework = a fresh dispatch.
- Rationale unknown → record what is known and mark Context with `[Note: rationale partially reconstructed — verify with original decision-makers]`.
- Record the decision faithfully — never editorialize it in the ADR. The WEAKNESSES list (Step 4) and premortem findings (Step 8) are decision-support shown to the developer, NOT written into the ADR file — except the reversibility verdict, and any failure mode the developer folds into Risks/Assumptions.
- Still-debated decision → status **Proposed**, record the leading option, skip Step 9. Step 8 still runs. Update to **Accepted** when confirmed.
- The Step 8 reversibility check + premortem is mandatory for every ADR; premortem depth scales with reversibility (inline for a two-way door, off-context subagent for a one-way door). Decision-support, not a gate — never block on it.
- ADR numbers are permanent. Never renumber existing ADRs.
- Step 9 is a recommendation, never a gate. The developer owns whether to open a fresh session.

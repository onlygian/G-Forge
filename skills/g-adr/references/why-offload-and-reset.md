# Why /g-adr is built the way it is

Load this when the developer pushes back on the offload/reset behavior or a maintainer asks why. (The doctrine is duplicated — authoritatively — in `rules/g-rules/C-agent-discipline.md`, and the depth model in `g-docs/g-adr-depth-model.md`; this is the skill's operational copy. Overlap noted for later dedup — nothing deleted.)

## Why decisions get recorded at all

Architectural decisions undocumented become invisible. New team members re-litigate settled choices. Drift happens without anyone knowing why the original constraint existed. This skill captures decisions while the context is fresh — and it does so without poisoning HQ's own window with the deliberation that produced them.

## Why the weighing is offloaded (Step 3)

Weighing options is exactly the high-branching reasoning that poisons a context (G-RULES §C): three-way pattern debates, rejected alternatives, and wrong first guesses all stay in-window and drag on everything HQ does next. The single-use doctrine applies to HQ's *own* deliberation, not just dispatched agents. So this skill offloads the weighing to a throwaway subagent and promotes only the finished answer — and, once a consequential decision is finalized, it resets the residue: retro, then verify from a fresh session.

## Why the corpus stays rare (Step 1 triage)

ADRs are only valuable while they stay **rare and high-signal**; a full record on a small, local choice dilutes the corpus. That is why every entry is triaged (ADR / brief row / nothing) before any interview runs.

## Why reversibility, not importance, scales the premortem (Step 8)

Reversibility — not self-rated "importance" — is the signal that scales the decision-support pass. Importance is a self-assessment that inflates under enthusiasm; reversibility is a property of the change itself (what commits to it, what it would cost to undo). A premortem is high-branching failure reasoning — running it inline poisons HQ's window, the same reason Step 3 is offloaded — so only the one-way door pays for a subagent.

## Why the close-the-circle reset reuses §A7 (Step 9)

A finalized ADR is a high-stakes artifact produced through deliberation. Even with the weighing offloaded, the session's window carries the interview and the promotion loop — you should not keep building architecture on top of it, and the ADR itself was produced in a context that should be **checked, not trusted from memory** (airtight = checked, not remembered).

**Step 9 reuses the existing session-reset path, it does not invent one.** The context gate (G-RULES §A7, driven by the exchange counter in `workflow-checkpoint.sh`) already runs exactly this reset — auto-`/g-retro` + handoff write + "open a fresh session" — when the *quantitative* trigger fires (exchange count hits red). Finalizing a consequential ADR is the *semantic* trigger for the same response: you don't wait for the exchange count to climb, because an architecture decision warrants the reset now. Same path, different trigger.

The full recommendation, in the skill's voice: "This session's context now carries the deliberation that produced the ADR — that's residue I shouldn't keep building on, and the ADR itself is an airtight answer that should be *checked*, not trusted from memory. Start a fresh session and run `/g-resume` — it re-hydrates a clean window with the handoff, the retro, and the ADR, and offers to verify the decision against the actual repo as the first task. You lose the residue, not the knowledge."

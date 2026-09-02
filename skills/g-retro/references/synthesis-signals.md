# synthesis-signals — the evidence catalogs behind Step 3

Load this when synthesizing a retro (Step 3) and you need the full signal catalogs, the decision-inference examples, or the rationale for the Next-up derivation order. The sentinel literals (`None inferred from journal.`, `None observed.`) and the 5-item derivation order themselves live in the SKILL.md core — this file explains how to fill them.

## Decision inference — examples

Infer decisions from the journal and commit messages, never by asking:
- A `branch` event starting `refactor/*` plus its commits implies an **approach decision**.
- A `revert` followed by a different fix implies a **reversed decision**.
- A new dependency appearing in a commit implies a **library choice**.

State each as a factual observation, e.g. "Adopted X over Y (commit abc123 replaced the Z approach)."

## Pattern signals

- **Worked well** — clean signal: tests run before commits (`test` entries preceding `commit` entries), no reverts, no `destructive` flags, agents finishing without re-dispatch.
- **Avoid / do differently** — friction signal: `revert` entries, repeated `test` failures before a commit, `destructive` flags, the same agent dispatched repeatedly on one task, or commits with `fix-of-fix`/`take 2`/`retry` messages.

## Next-up derivation — why that order

The 5-item order (developer directive → plan's next incomplete wave → milestone's next unchecked task → lead open `g-docs/todo.md` row → old handoff line marked `(carried — no open task found)`) puts **intent-proximate sources first**: what the developer said this session — stated in-session or recorded in the journal, so a retro synthesized after the fact can still find it — outranks any file, the active plan is the closest written statement of intent, and the milestone task list is the next-closest. A todo lead row comes late because it is often a long-lived carry, not the next action — treating it as the next action would hand the fresh session a stale target. The old handoff line is last and explicitly marked, because carrying it forward unexamined is exactly the drift the derivation exists to prevent.

## Source resolution notes (Step 2)

- The journal spans sessions: read today's file in full plus the two most recent prior days — the work being retro'd may have started earlier.
- `g-docs/todo.md` is the tactical ledger; no handoff lives there.
- The active milestone file is the `g-docs/milestones/M*.md` marked 🔄 In progress in `g-docs/ROADMAP.md`; the active plan is the `g-docs/plans/*.md` for the current branch slug or milestone. Both feed the Next-up derivation; both may be absent, and their absence just advances the derivation chain.
- A missing/empty journal is not a stop condition — the retro is still produced from git + todo, just thinner, and the gap is noted in `## Journal basis`.

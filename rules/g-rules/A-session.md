## A · Session Rules

**A1 Model** — Dispatch at the cheapest sufficient tier; agent frontmatter pins each default (matrix: `.claude/rules/g-dispatch-matrix.md`, read lazily when routing or escalating — never @-imported). Haiku: mechanical work passing the haiku-executability check · Sonnet: implement / plan / diagnose · Opus tier: merge, doc, and security gates. A dispatch failing the haiku check escalates the executor, never degrades the spec. Escalate one tier after 2 fails on the same task; never because it 'feels hard'. Session tier is never inherited — delegation tiers stay pinned per-agent.

**A2 Plan** — Atomic verifiable tasks before touching files. Log in `g-docs/todo.md`. Identify Wave 1 (no blockers). Vague goals ("make it work") → ask before starting.

**A3 Execution workflow**
- Execute 1st pass only (no scope creep mid-wave)
- Before committing — mandatory gate: run the project's lint and test commands (check `package.json`, `Makefile`, `pyproject.toml`, or CI config for the right commands). Any red = stop, fix first.
- Business logic / public API / bug fix → tests required. Pure UI render → skip is OK, state why explicitly. Silence = not acceptable.
- Pure functions inside a component → extract to the project's lib/utils layer first, then test
- After each commit: update `g-docs/todo.md` (remove closed rows + Details), append to `g-docs/todo-done.md`, commit immediately — never leave either file dirty
- End of pass: rewrite the `## Active Session` handoff block in `g-docs/ROADMAP.md` (replace, never append), commit, post the same block in chat. This is the single canonical handoff — a fresh session targets one committed document for "where am I / what's next." `g-docs/todo.md` holds only the tactical task ledger, never a handoff.

**A4 Token optimisation**
- Grep before Read — find line numbers, then read only those lines (`limit` + `offset`)
- No full-file reads on files >100 lines unless rewriting the whole file
- All independent tool calls in the same message (parallel)
- Cache `file:line` refs — never re-read the same file. Never re-Grep what an agent returned.
- Edit tool for partials; Write only for full rewrites. One logical change per commit.
- Don't refactor or optimise in the same pass as the feature/fix

**A5 Mindset** — State assumptions. No features / abstractions / error-handling beyond the ask. Every changed line traces to the request. Don't improve adjacent code. Remove imports made unused by your changes; leave pre-existing dead code alone and mention it.

**A6 Delivery** — Complete snippets with all imports. Explain WHY not what. Mark placeholders (`YOUR_API_KEY`). Flag security risks. No `TODO`/`FIXME` in delivered code.

**A7 Context gate** — **Reset *before* the window ever compacts; a compaction means the gate fired too late.** The workflow checkpoint classifies the session as `implementation` (recent commits / dirty tree / active plan) or `conversation` (clean / no plan), with lenient baseline thresholds (impl 30/45, conv 45/65) that auto-calibrate downward: every compaction grows `.claude/context-threshold-offset`, subtracted from the baselines (floored). The checkpoint's amber/red/compaction lines repeat every prompt while active; its stable banner reprints only on state change.

At ⚠ **amber** — active monitoring, not a one-time warning: run `/context` **this turn and every turn from now**, and the moment **~25% of the window has been used**, reset immediately — finish in-flight work, `/g-retro`, fresh session — *without waiting for the red exchange count*. Surface a direct, visible warning to the user.

At !! **red** — enforce without waiting for the user: accept no new scope, complete only the task currently executing, then auto-trigger `/g-retro` (writes the `## Active Session` handoff, its Step 5b). After it completes, tell the user: *"Session context exhausted — open a fresh session and run `/g-resume` to continue."* Confirm the handoff is written and committed before the session ends — non-negotiable.

**Wave-boundary guard:** run `/context` right after each wave (`/g-execute`) completes. At or past **~25% of the window used** → reset before dispatching the next wave; the remaining waves resume in the fresh session.

The reset has two sides: `/g-retro` + the handoff promote the clean record *out*; `/g-resume`, run on the first prompt of the fresh session (nudged automatically when a pending handoff exists), pulls the right slice back *in*. The same re-entry serves both this quantitative trigger and the semantic ADR-finalized trigger in §C. If a compaction happens anyway, the depth counter carries across, `pre-compact.sh` records it and tightens the threshold, and the checkpoint surfaces the red reset. When the gate fires (amber/red) or a compaction occurs, read `.claude/rules/references/context-gate.md` for the calibration philosophy, the compaction-as-backstop mechanics, and the two-sided reset rationale.

**A8 Three-Strikes** — Same bug class × 3 attempts = STOP. Name the mechanism. List what failed and why. Find an alternative that bypasses it entirely. Escalate model before attempt 3, not after.
Warning signs: error message changes but bug class persists · you're explaining why *this* approach should work when the last one didn't · fix requires knowing internals of a platform component you don't control.
Three-Strikes is the ceiling on §C's single-use retry loop — each strike is a **fresh** agent with a *different* mechanism, seeded only by distilled learnings. After the third failed approach, stop and escalate to the human with the full learnings trail; do not deploy a fourth.

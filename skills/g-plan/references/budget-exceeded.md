# Budget exceeded — the Step 3c stop path

Load trigger: `scripts/budget-check.sh` prints `VERDICT: exceeded`. Stop — do
not proceed to Step 3d. Use the script's `REMAINING` (M), `RED` (R), `DEPTH`
(C), `ESTIMATED` (N), `SPLIT_TARGET` (floor(M × 0.8)) and `SPLIT_DEPTH` lines
below.

## Split depth

`SPLIT_DEPTH ≥ 1` means the identifier passed as `--id` carries a `-split<N>`
suffix — this plan is already the product of one prior split. `SPLIT_DEPTH: 0`
(including every ad-hoc run with no identifier — no milestone, no prior save;
Step 4a only mints a slug after approval) means depth 0 by definition.

## Present the budget-exceeded prompt

One block, both depths — only the availability of option 1 and the presence of option 3 change, so option numbers never change meaning between a depth-0 and a depth-≥1 answer:

```
⚠ Context budget exceeded

  Estimated cost:   ~[N] exchanges
  Remaining budget: ~[M] exchanges  (derived red threshold [R] − current depth [C])
  Shortfall:        ~[N−M] exchanges

  Running this plan would push the session into red mid-execution,
  forcing an incomplete-wave handoff.
  [depth ≥ 1 only, appended:] This milestone is already a split
  product — a prior lineage re-split 3 levels deep from one original
  unit with no benefit (derived 2026-08-12 from a field report).

  Options:
  1. Split — invoke /g-roadmap to break this milestone into
     sub-milestones that each fit within ~[floor(M × 0.8)] exchanges.
     [depth ≥ 1 only:] — unavailable at this depth; see option 3.
  2. Proceed — accept the mid-plan handoff risk. Execution will pause
     at red and require a fresh session to resume incomplete waves.
  3. [depth ≥ 1 only:] Escalate to the developer for a manual
     re-scope — the plan's actual shape, not another mechanical
     split, is the likely fix at this depth.

  Which would you prefer?
```

## Choice handling

**If the developer chooses option 1 — split (depth 0 only; unavailable at depth ≥ 1):**

Use Glob to find `skills/g-roadmap/SKILL.md` inside `~/.claude/plugins/cache/g-forge/g-forge/` and read it. Run `/g-roadmap` with the following framing passed as context:

> "The current milestone task list is [task list]. The session context budget is ~[M] exchanges per sub-milestone. Split this milestone into sub-milestones where each sub-milestone's estimated cost (base 5 + waves×3 + agents×2 + tasks×1 + tasks×4) does not exceed [floor(M × 0.8)] exchanges. Name each sub-milestone ID/slug with a trailing `-split<N>` suffix (no existing suffix on the parent → `-split1`; parent already `-split<N>` → replace it with `-split<N+1>`) so a future Step 3c pass can detect that it is already a split product. Produce a revised g-docs/ROADMAP.md with the sub-milestones sequenced in dependency order."

After `/g-roadmap` completes, stop the current `/g-plan` run. Tell the developer: "g-docs/ROADMAP.md updated with sub-milestones. Run /g-plan on the first sub-milestone to begin."

**If the developer chooses option 2 — proceed (either depth):**

Add `> ⚠ Risk: estimated ~[N] exchanges exceeds session budget — mid-plan handoff likely` to the plan header. Proceed to Step 3d.

**If the developer chooses option 3 — manual re-scope (depth ≥ 1 only):** stop the current `/g-plan` run and hand back to the developer — do not invoke `/g-roadmap` automatically at this depth.

**If the developer answers "1" at depth ≥ 1** (where option 1 is printed but annotated unavailable): do not invoke `/g-roadmap`. Tell the developer split is withheld at this depth, and treat the answer as option 3 — hand back for a manual re-scope.

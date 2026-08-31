# Archived documents

Superseded material retired from active `g-docs/` paths (G-RULES §I). The bulk is historical planning docs from G-Forge's early milestones (originally under `docs/`,
later the gitignored `g-docs/plans/` + `g-docs/superpowers/` operational-artifact paths).

These were recovered from git history (commit `416ce69^`, the last tree that held them
before the "clean repo to plugin content only" cleanup untracked them) and moved here
under the **tracked** `g-docs/archive/` path so they can't be lost again.

## Coverage gap

The **M9–M15 plans** (`m9-intelligence-foundation`, `m10`–`m15`, `v0-8-0-retro-precompact-mcp`)
were never committed to any branch — they existed only as untracked local files and were
not recoverable. The milestones themselves remain documented in `ROADMAP.md` and the
session retros under `g-docs/retros/`.

## roadmap-dropped-2026-08-28.md

v2.5 scope cut (ADR-012 amendment 4, minimal freeze — 2026-08-28): full entries for five dropped milestones (M38, M41, M43, M49, M50), three scope items from M51 (items 1, 7, 10), and two waves from M40 (Waves 2–3). Each is archived with a timestamp note; all are G-Proof candidates (`decide at R0`). The rebuild map's verdict column (`g-docs/audits/2026-07-rebuild-map.md`) filtered the final release to what SURVIVES or is adopter-facing bug fixes; everything in this file reads DIES or is narrowed in the final milestone.

## milestones/

Milestone files retired from `g-docs/milestones/`, which is `/g-plan`'s source of truth — a dropped milestone left in that directory stays plannable, which is the reason for the move rather than a status edit in place. Each file keeps its full task breakdown and carries a dated archive stamp at the top naming the decision that dropped it. First entry: `M41.md` (Release Machinery + README Currency), moved 2026-08-28 by ADR-012 amendment 4 — its roadmap entry and drop rationale are in `roadmap-dropped-2026-08-28.md` above.

## inbox-adversarial/

Consumed third-party counter-reports moved out of `g-docs/inbox/adversarial/` after a `/g-patterns` RESOLVE pass weighed them (first batch: the 2026-08-27 pass, `g-docs/retros/2026-08-28-patterns-resolve-27.md`) (skill Step 14 close-out item 3). The inbox holds only material not yet considered; these are kept here as the record of what was received and when.

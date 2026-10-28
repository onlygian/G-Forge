# ADR-017: Install G-Rules outside auto-loaded rules dir

**Date:** 2026-10-28
**Status:** Accepted
**Reversibility:** two-way door (reversible) — the source tree is unchanged; reversing means pointing `scaffold.sh`, `G-RULES.md` and the consumers back at the old paths and shipping the inverse migration.
**Context:** G-Forge install layout in consumer projects (`/g-init`, `/g-update`, `/g-doctor`); realigning `G-RULES.md` and the `CLAUDE.md` template with Claude Code's documented memory loading.

## Context

Claude Code's memory documentation (code.claude.com/docs/en/memory, read 2026-10-28) states that every `.md` file under `.claude/rules/` is discovered recursively and that rules without `paths:` frontmatter load at launch; that `@`-imports load together with the importing file and "help organization but don't reduce context cost"; and that each CLAUDE.md should stay under about 200 lines, with a startup warning when files are over that length or add up past a combined limit (each CLAUDE.md, rules file and import counting as a file). Up to v2.6.3, `/g-init` installed the G-Rules sections as `.claude/rules/g-rules-*.md` **and** `@`-imported them from `G-RULES.md`, and installed the `rules/references/*.md` essays plus the dispatch matrix under `.claude/rules/` while every rule described them as "never @-imported — loaded on demand". By the documented behaviour that made the references load every session (25,465 bytes measured in a scaffolded project) and made the README's "selective loading" preset unable to reduce what loads, since the folder loads every section whether or not CLAUDE.md imports it. Whether Claude Code de-duplicates a file that is both auto-loaded and imported is not documented (the docs mention de-duplication only for `AGENTS.md`).

## Decision

Install nothing of G-Rules under `.claude/rules/`. Sections go to `.claude/g-rules/<X-name>.md` and load only through `G-RULES.md`'s `@`-imports (so importing a subset really loads a subset); references and the dispatch matrix go to `.claude/g-references/` (matrix as `dispatch-matrix.md`) and load only when a rule tells Claude to read them. `/g-update` migrates old installs (`scripts/migrate-rules-layout.sh`, Step 2a — it moves the files and repoints `G-RULES.md`/CLAUDE.md section imports in one run, never deletes a copy that differs from the new one) and `/g-doctor` Check 16 fails on any legacy copy left in `.claude/rules/`. Source paths in this repository (`rules/g-rules/`, `rules/references/`, `rules/dispatch-matrix.md`) do not change, and no rule's meaning or threshold changes.

## Alternatives considered

| Option | Why rejected |
|--------|-------------|
| Keep sections in `.claude/rules/` and drop the `@`-imports from `G-RULES.md` | Selective loading becomes impossible — the folder loads every section regardless of CLAUDE.md — and `G-RULES.md` turns into an empty shell that ADR-011's injection model and Checks 7/8 still require. |
| Keep references in `.claude/rules/` with a `paths:` glob that never matches | Abuses path scoping to mean "never"; the references are triggered by events (gate fires, release time), not by file paths, and a later glob edit would silently start loading them. |
| `claudeMdExcludes` setting to hide the G-Forge files | Moves the fix into per-machine settings each developer must carry; the install layout would still contradict what the rules say about themselves. |
| One combined directory (`.claude/g-rules/` holding sections, references and matrix) | Mixes always-imported sections with on-demand notes in one folder, so a disk count of sections (`RULES_INSTALLED`) would need a filename filter; two directories keep each one's loading contract obvious. |

## Consequences

**Easier:** the always-loaded set is exactly CLAUDE.md + `G-RULES.md` + the imported sections, so `/context` matches what the rules claim; a trimmed preset in CLAUDE.md actually trims; the references are on demand as described.
**Harder / constrained:** consumer projects carry two new committed directories; every surface that names an installed path must use the new one (pinned by `tests/test-rules-load-layout.sh`); old installs need one `/g-update` run.
**Follow-up decisions:** `/g-specialize` still installs `.claude/rules/architecture-<stack>.md` **and** `@`-imports it from CLAUDE.md — the same auto-load-plus-import shape. Those rules are meant to be always loaded, so the only possible cost is double injection, which the documentation does not settle; left unchanged here and recorded as a follow-up to verify with `/context` in a live session.
**Risks:** the loading behaviour is inferred from the documentation, not observed with `/context` in a live session; a future Claude Code change to which `.claude/` subdirectories auto-load would need this layout revisited.

## Rejected Alternatives

| Alternative | Why rejected |
|-------------|--------------|
| Leave the layout and reword the rules to admit the references always load | Keeps 25 KB of essays in every session's context — the opposite of the v2.6 token diet (ADR-014) that created them as lazy references. |
| Delete stale copies in `/g-init` instead of a `/g-update` migration | `/g-init` runs once per project; existing installs realign through `/g-update`, which already owns "make installed copies match the plugin". |

## Assumptions That Held

- Claude Code auto-loads `.md` files only from `.claude/rules/` (plus CLAUDE.md files and their imports) and not from other `.claude/` subdirectories such as `.claude/g-rules/` — taken from the documented discovery rules; fragile if Claude Code widens discovery.
- A relative `@`-import in `G-RULES.md` resolves against the file containing it (documented), so `@.claude/g-rules/A-session.md` from the project-root `G-RULES.md` reaches the installed file.

## Constraints That Drove This Decision

- No change to any rule's meaning or threshold, and no change to source paths other skills and tests derive from.
- Existing consumer projects must migrate without hand work and without losing a hand-picked section preset.

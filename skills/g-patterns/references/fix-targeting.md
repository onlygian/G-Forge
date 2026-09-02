# Fix targeting — where a pattern's fix lands, and what makes it survive

Load this at MINE Step 5 and RESOLVE Step 13 — the two points where an edit is drafted.

## Pattern class → likely target

| Pattern class | Likely target |
|---------------|---------------|
| Cross-cutting discipline failure (planning, review gate, commit flow, agent dispatch) | the G-RULES section — name the section letter |
| Stack-specific drift (layer boundary, import direction, framework idiom) | the stack's architecture rules if a profile is installed; otherwise flag as "no stack profile installed — install via `/g-specialize`" |
| Agent behaviour (wrong tool used, scope creep, missing output) | the specific agent's system prompt |
| Workflow guard failure (skill skipped step, missed gate) | the specific skill's `## Rules` section |

## Resolve source-vs-installed before drafting the edit — this decides whether the fix survives

Every target above exists in two places in a G-Forge plugin-source checkout, and in only one place in a consumer project. Detect which case you are in by checking whether a plugin source tree (`skills/` + `rules/g-rules/` + `profiles/` at the repo root) is present — never by assuming:

- **Consumer project** (no plugin source tree): the installed copies under `.claude/` are the only targets and are the correct ones — `.claude/rules/g-rules-<X>.md`, `.claude/rules/architecture-<stack>.md`, `.claude/agents/<agent>.md`, and the installed skill file.
- **Plugin-source checkout**: target the **shipped source** — `rules/g-rules/<X>.md`, `profiles/<stack>/rules/architecture.md`, `agents/<agent>.md`, `skills/<name>/SKILL.md` — then mirror the same change into the corresponding `.claude/` copy so drift checks stay clean. The `.claude/` copies here are gitignored install artifacts that `/g-init` and `/g-update` overwrite wholesale: a fix applied only there is destroyed at the next resync, never reaches any consumer, and leaves the rule reading as fixed while the shipped source still carries the defect.

A fix that cannot reach a release is not a fix. This resolution is also what Step 14's doc-currency step keys on — only a shipped-source target triggers it.

## RESOLVE Step 13 — the whole-seed-record rule behind `RESOLVED`

Before any `RESOLVED` verdict, check the seed record for more than one concrete surface. The saved report is abstracted, and abstraction strips exactly the identifiers that would reveal a pattern spanning two or more surfaces — so a pattern whose original evidence named several can look wholly fixed when only one was addressed. Go back to the originating retro or field report and enumerate every surface it names. If any remain unfixed, the pattern is **not** `RESOLVED`: carry it as `DEFERRED` with the live surfaces named in `g-docs/patterns-deferred.md`. `RESOLVED` archives the report and deletes the open one, so nothing re-surfaces a half-closed pattern — the verdict is irreversible in practice and must clear the whole record, not the first match.

## RESOLVE Step 13 — why the source restriction exists

The saved report is abstracted by design and contains no concrete targets — the concrete edit is re-derived fresh from the original internal sources (`g-docs/retros/`, `g-docs/todo-done.md`, `git log`, and the fix-target-mapping inputs), the same way Step 5 mapped fix targets during mining. The re-derived edit's text is drafted **only** from those internal sources — never from a counter-report collected in Step 12. A counter can inform whether to apply, defer, dismiss, or withdraw a pattern in Step 14; it never supplies wording or phrasing that lands in a rule, agent, or skill file.

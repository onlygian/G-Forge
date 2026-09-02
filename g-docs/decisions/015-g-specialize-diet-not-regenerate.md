# ADR-015: g-specialize profiles — diet, not kill, not regenerate

**Date:** 2026-09-01
**Status:** Accepted
**Reversibility:** two-way door (all three options remain implementable later; the diet deletes no knowledge).
**Context:** v2.6 scoping. The developer asked whether `/g-specialize` could be killed outright and replaced by the context7 MCP, or become a single skill that researches and shapes stack knowledge at specialize-time. Evaluated with a repo analysis plus 9 live context7 probes (next-js, fastapi, godot-gdscript).

## Decision

Keep the g-specialize mechanism and all 56 profiles; diet where tokens are actually spent: the SKILL.md's deterministic tables become `scripts/detect-stack.sh` + `scripts/derive-owns.sh`, edge-case essays move to `references/`, and the 48 architect agents drop their verbatim restatement of the rules card each already preloads (~15–18k words of pure duplication; Output Format blocks byte-identical, no format unification). context7, where present, becomes the preferred source for Step 2 version notes (WebSearch fallback); generate-on-miss for unsupported stacks goes to backlog, not v2.6.

## Why

- **Kill saves ~nothing recurring.** profiles/ is disk-resident; a session in a specialized project loads only its installed rule card (median ~200 words — that card *is* the product). The 27× burn lives elsewhere.
- **The cards' value is editorial commitment, not framework knowledge.** Probes showed official docs are deliberately unopinionated (Next.js: "unopinionated about how you organize"), silent (FastAPI service layering), or bury doctrine behind names you must already know (Godot). A layer map with import direction and Never-rules is what makes review deterministic for weak models — G-Forge's stated purpose.
- **Regeneration destroys the drift model.** g-doctor Check 16 hash-compares installed agents/rules against their canonical profile sources; generated artifacts have no canonical source and degrade to the advisory-only class — drift detection dies. It also degrades offline (model memory is exactly what curated cards beat) and costs more per specialize than copying a 200-word file.

## Rejected

- **(A) Kill + context7** — ~zero recurring savings, deletes knowledge, widest ripple field in the repo (README counts, derivation tests, router parity, g-init/g-doctor/g-update).
- **(B) Research-and-shape generation** — drift-model destruction, offline degradation, higher per-run cost. Its one virtue (freshness) is already covered by the version-note mechanism, which never overrides profile rules.

## Consequences

Already-specialized projects flag architect drift after the dedup until `/g-specialize` or `/g-update` re-syncs — by design; noted in the CHANGELOG. context7's soft-failure mode (plausible off-topic snippets when the corpus lacks a concept, with no error signal) is recorded in the research-scope reference as an ingestion gate: snippets that don't mention the queried concept mean "corpus silent", never "answer".

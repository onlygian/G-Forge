# Documentation standards — rationale (G-RULES §G companion)

Load trigger: read this when a doc-scope judgment call comes up — whether something needs documenting, or why the ownership rule points at the implementer. The normative rules live in `.claude/rules/g-rules-G-documentation.md`; this file holds the reasoning moved out of them (v2.6 token diet).

## Why documentation is a delivery requirement

Undocumented decisions become invisible. Undocumented APIs block adoption. Undocumented env vars stop new developers from running the project.

## WHY-comment guidance

If a comment would only say "gets the user by ID", omit it — the name already says that. The comment earns its place only when it carries the constraint respected, the invariant maintained, or the consequence of misuse.

## Why the implementer owns documentation

The implementing agent has full context of what it just built and why — that context is most valuable at the moment of implementation, not during retrospective review. Reviewers validate coverage because generation-by-reviewer would recreate the context the implementer already had; the expectation is that the implementing agent already handled it, so a review-caught gap is evidence the doc-writer dispatch was skipped.

# doc-reviewer lenses 1–4 — elaborations and examples

Maintainer-facing rationale. NOT read by dispatched agents — the trigger lists
stay in `agents/doc-reviewer.md`; the why-essays live here.

**1. Accuracy vs. code.** Documentation that describes behavior the code does
not have. A README that claims a flag exists when no code reads it; a docstring
that promises a return shape the function never produces; a quickstart whose
example would throw. The doc is internally coherent but disagrees with what the
code actually does.

**2. Currency (headline lens).** Documentation that contradicts the *current*
code because the code moved and the docs did not. Stale docs are worse than
missing docs — they actively mislead a reader who trusts them. This is the
primary reason the doc gate exists.

**3. Completeness.** The five triggers in the core, elaborated: an exported
symbol with non-obvious behavior needs a doc comment precisely because its name
and types do not fully explain it; a new user-facing capability with no README
section is invisible to adopters; an env var read with no entry in the env var
reference (`g-docs/env-vars.md`, `.env.example`, or README) fails silently at
deploy time; a shipped significant change with no CHANGELOG entry breaks the
release narrative; a significant architectural decision (new dependency, new
layer, new project-wide pattern, replacement of an existing approach) with no
ADR in `g-docs/decisions/` loses the WHY forever.

**4. Clarity.** Documentation that exists but does not help. A comment that
only restates the function name or type signature ("gets the user by id") adds
noise. Prose that is confusingly written, ambiguous, or buries the WHY. Docs
that narrate implementation steps the code already shows clearly.

## G · Documentation Standards

Documentation is a delivery requirement, not a post-delivery polish task. Rationale and edge guidance: `.claude/rules/references/documentation-notes.md` (read when a doc-scope judgment call comes up).

### What must be documented

**Code level — required when behaviour is non-obvious:**
- Every exported function, class, interface, or type where the name and type signature do not fully explain the WHY: the constraint respected, the invariant maintained, or the consequence of misuse.
- Every source module >100 lines where the filename alone does not explain the module's purpose and constraints — one-paragraph header at the top.
- Format by language: TypeScript/JavaScript → JSDoc (`/** ... */`); Python → docstring (`"""..."""`); Go → doc comment (`// FunctionName ...`); Rust → `///`; C# → `/// <summary>`.
- Document the WHY. Never restate the type signature or function name in prose.

**Architecture level:** every significant technical decision — new stack component, new external dependency, new project-wide pattern, replacement of an existing approach — gets an ADR in `g-docs/decisions/` (`/g-adr`, captured immediately while context is fresh). CLAUDE.md carries architecture *rules*; ADRs carry the *rationale*. Both are required.

**Project level:** README (what it is, why use it, install, quickstart, configuration, public API link/description) · CHANGELOG entry for every release (features, fixes, breaking changes, deprecations — updated in the same PR as the change, never retroactively) · every env var documented in `g-docs/env-vars.md`, `.env.example`, or a README section (name, purpose, required/optional, example, default).

**API level:** REST → OpenAPI spec updated in the same PR as the endpoint change · SDK/library → complete JSDoc/docstrings on every exported symbol are the reference · webhooks/events → document the payload shape and all fields.

**Operational level (before first deployment):** deployment guide from clean checkout · env var reference · runbook for common failure modes (what breaks, how to detect, how to recover).

**Not documented:** private/internal functions whose name and types fully explain them · trivial getters/setters · test files (test names are the docs) · generated files (document the generator).

### Currency rule

Any PR that changes a function signature, module responsibility, user-facing behaviour, configuration option, or public API must update the corresponding documentation in the same PR. Outdated documentation is a Major finding in code review — it actively misleads.

A hand-typed count (suite totals, "N of M" tallies, list sizes) is either pinned by a test that fails when the source and the count disagree, or omitted — never left as an unpinned number in prose. A hand-typed number without a pinning test is a review finding.

A design decision changed after a review round has already dispatched (code or doc gate) invalidates any doc pass written against the prior design — the round owning the change explicitly re-opens the doc pass (a fresh `/g-doc-review` dispatch scoped to the changed surface), never relying on the next round's incidental sweep to catch the drift.

### Documentation ownership

Documentation is the implementing agent's responsibility, not the reviewer's. Every subagent that creates or modifies code with public interfaces dispatches `doc-writer` as its **final step**, before returning its result to HQ — scoped to the doc files inside its own stated file scope; docs outside that scope are reported to HQ as a `LEARNINGS` gap, never reached by widening a child's scope (§C). `doc-writer` receives: the files changed, what changed and why, and any design intent not obvious from the code; it also checks whether the README has a relevant section and updates it or flags the gap.

`code-reviewer` and `review-orchestrator` **validate** documentation coverage rather than generate it. Missing documentation on public exports remains a **Major** finding — and a caught gap means the agent failed to dispatch doc-writer; this feeds the hallucination-rate metric.

Run `/g-docs [path|all]` at any time for a full documentation audit. Run `/g-adr` to capture any architectural decision.

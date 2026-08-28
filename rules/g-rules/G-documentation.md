## G · Documentation Standards

Undocumented decisions become invisible. Undocumented APIs block adoption. Undocumented env vars stop new developers from running the project. Documentation is a delivery requirement, not a post-delivery polish task.

### What must be documented

**Code level — required when behaviour is non-obvious:**
- Every exported function, class, interface, or type where the name and type signature do not fully explain the WHY: the constraint respected, the invariant maintained, or the consequence of misuse.
- Every source module >100 lines where the filename alone does not explain the module's purpose and constraints — one-paragraph header at the top.
- Format by language: TypeScript/JavaScript → JSDoc (`/** ... */`); Python → docstring (`"""..."""`); Go → doc comment (`// FunctionName ...`); Rust → `///`; C# → `/// <summary>`.
- Document the WHY. Never restate the type signature or function name in prose. If a comment would only say "gets the user by ID", omit it — the name already says that.

**Architecture level — required for significant decisions:**
- Every significant technical decision — new stack component, new external dependency, new pattern applied project-wide, replacement of an existing approach — must have an ADR in `g-docs/decisions/`.
- Run `/g-adr` to capture decisions interactively. Capture immediately, while context is fresh.
- CLAUDE.md carries architecture *rules*. ADRs carry the *rationale* behind those rules. Both are required.

**Project level — required for every project:**
- README must contain: what the project is (one sentence), why someone would use it, installation/setup, quickstart example, configuration reference, and a link to or description of the public API (if one exists).
- CHANGELOG must have an entry for every release covering: new features, bug fixes, breaking changes, deprecations. Update CHANGELOG in the same PR as the change — never retroactively.
- Environment variables: every env var read by the application must be documented in `g-docs/env-vars.md`, `.env.example`, or a dedicated README section. Include: var name, purpose, required/optional, example value, default if optional.

**API level — required when a public API is exposed:**
- REST APIs: maintain an OpenAPI spec (`openapi.yaml` or equivalent). Update the spec in the same PR as the endpoint change.
- SDK/library public APIs: JSDoc/docstrings on every exported symbol are the API reference. No additional reference document needed if docs are complete.
- Webhook payloads, event schemas, message formats: document the payload shape and all fields.

**Operational level — required before first deployment:**
- Deployment guide: steps to deploy to production from a clean checkout.
- Environment variable reference (see Project level above).
- Runbook for common failure modes: what breaks, how to detect it, how to recover.

### What does not need documentation

- Private/internal functions whose name and types fully explain them.
- Trivial getters/setters with self-evident names.
- Test files — test names serve as documentation.
- Generated files — document the generator, not the output.

### Currency rule

Any PR that changes a function signature, module responsibility, user-facing behaviour, configuration option, or public API must update the corresponding documentation in the same PR. Outdated documentation is a Major finding in code review — it actively misleads.

A hand-typed count (suite totals, "N of M" tallies, list sizes) is either pinned by a test that fails when the source and the count disagree, or omitted — never left as an unpinned number in prose. A hand-typed number without a pinning test is a review finding.

A design decision changed after a review round has already dispatched (code or doc gate) invalidates any doc pass written against the prior design — the round owning the change explicitly re-opens the doc pass (a fresh `/g-doc-review` dispatch scoped to the changed surface), never relying on the next round's incidental sweep to catch the drift.

### Documentation ownership

Documentation is the implementing agent's responsibility, not the reviewer's. Every subagent that creates or modifies code with public interfaces dispatches `doc-writer` as its **final step**, before returning its result to HQ — scoped to the doc files inside its own stated file scope; docs that live outside that scope are reported to HQ as a `LEARNINGS` gap, never reached by widening a child's scope (§C). The implementing agent has full context of what it just built and why — that context is most valuable at the moment of implementation, not during retrospective review.

`doc-writer` receives: the files changed, what changed and why, and any design intent not obvious from the code. It also checks whether the project README has a relevant section and updates it or flags the gap.

`code-reviewer` and `review-orchestrator` then **validate** documentation coverage rather than generate it. Missing documentation on public exports remains a **Major** finding — but the expectation is that the implementing agent already handled it. If review catches a gap, it means the agent failed to dispatch doc-writer; this feeds into the hallucination-rate metric.

Run `/g-docs [path|all]` at any time for a full documentation audit. Run `/g-adr` to capture any architectural decision.

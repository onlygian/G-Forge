# Shared agent contract — canonical long forms (maintainer reference)

Maintainer-facing rationale backing the one-line forms in the agent cores. This file is
NOT read by dispatched agents (plugin references do not resolve from a consumer-project
CWD) — every operational rule lives in the agent cores; only the WHY lives here.
Not an agent: no frontmatter, never installed.

## Write-grant carve-out (reviewer/diagnostic families)

Canonical long form, compressed to one line in each carrying agent (security-auditor,
performance-auditor, architecture-enforcer, debugger, error-detective; the review-family
files code-lead / doc-reviewer / code-reviewer / dependency-auditor carry the same
carve-out):

> Your `Write` grant is scoped to your own report files under `g-docs/agent-output/`
> **only** — never project content, never the files you are reviewing or diagnosing. It
> exists solely to persist the record named by an `output_file` in your dispatch prompt —
> the same reviewer-class carve-out `doc-reviewer` and `code-lead` use.

Why it exists: reviewer- and diagnostic-class agents are read-only on project content by
architecture rule (see the Agent rule in the installed architecture profile), but the
orchestration layer needs their full reports persisted outside the conversation window.
The narrow `Write` grant squares the two: the body text scoping the grant to record
paths is what `/g-skill-validate` checks for (a reviewer-shaped `tools:` list plus
`Write` with no in-body scoping sentence fails validation), so the scoping sentence must
stay in each agent file itself.

## output_file plumbing and the heredoc prohibition

Canonical form: "When your dispatch prompt passes an `output_file`, write the full
report there with the `Write` tool, never a Bash heredoc; create parent directories if
needed. When no `output_file` is passed, return the report inline before the compact
block and put `inline` in `DETAIL:`."

The heredoc prohibition records a real failure: Bash heredoc record writes stall in the
permission layer (the permission prompt for a multi-line heredoc never resolves in a
dispatched-agent context), leaving the record unwritten while the agent believes it
persisted. The `Write` tool is the only reliable path. Agents with no Bash grant keep
the warning anyway — it also guards against a future grant widening.

## Memory rule — "Memory holds method, never verdicts."

Canonical elaboration (each `memory:` agent keeps the bolded sentence verbatim — it is
test-pinned via `grep -l '^memory:'` enumeration in tests/test-review-severity.sh —
plus a compressed clause):

> Your persistent memory may record how to check and where a class of defect hides —
> never "verified clean", "don't re-spend", a count, or any other verdict. Anything in
> memory that reads as a verdict or a number is re-derived from disk in this dispatch
> before it is relied on.

Why: a cached verdict in persistent memory survives across dispatches and silently
substitutes for a fresh review — the F2 audit class of failure. Method compounds;
verdicts rot.

## Single-use / LEARNINGS doctrine (executor family)

Canonical long form (feature-implementer, refactor-executor, test-writer, and the
stack-implementer template each keep a ~2-line operational form):

You are single-use: one committed approach, one attempt. If the approach works, return
`DONE` (or `WRITTEN` for test-writer). If it does not, return `FAILED` with a
`LEARNINGS` report — the approach you tried, where and why it broke, what is now ruled
out, and a recommended DIFFERENT approach — and stop. Never thrash or start a second
approach in the same context: a fresh agent redeployed by HQ with your LEARNINGS
outperforms a context polluted by a failed attempt. `BLOCKED` is reserved for external
gaps (a missing dependency, an ambiguous spec step, no discoverable convention) where a
different approach would not help — it is not a failed approach.

## Compact-return-block doctrine

Every dispatched agent returns ONLY its compact `RESULT: ...` block — no narrative
prose around it. The calling session parses the block mechanically; the full report
lives in the `output_file` (or inline before the block when none is passed). Narrative
wrapping burns the orchestrator's context window, and prose between block fields breaks
mechanical parsing. Verdict literals and scale lines inside the blocks are closed sets
pinned by tests/test-review-severity.sh — byte-identical, including the `·` (U+00B7)
separators.

## Documentation backstop (code-reviewer)

code-reviewer's doc-coverage checks are a BACKSTOP for the dedicated documentation
gate (`/g-doc-review` + `doc-reviewer`): they fire only when
`.claude/g-forge-docs-approved` is absent; when the sentinel is present,
doc-reviewer owns the deep documentation review and code-reviewer defers to avoid
double-reporting. The sub-checks mirror doc-reviewer's Completeness/Clarity lenses
but carry code-reviewer's own Major/Minor scale, which is load-bearing — the two
scales are deliberately not unified. Doctrine behind the checks: a doc should
explain WHY — the constraint or decision — not restate the type signature; stale
docs actively mislead callers and are worse than no docs; a diff introducing a
significant architectural decision with no ADR loses the reasoning permanently
(suggest `/g-adr`).

## Pack consumption (review pipeline, v2.6)

When a dispatch prompt names a `pack_dir`, the pack under
`g-docs/agent-output/review/pack-*` is the reviewed surface: MANIFEST first, then
`diff.patch` (or `fix-delta.patch` on `MODE: delta`) and the full-file `slices/` —
the reviewer never re-derives the diff itself, killing the fourth re-derivation of
the same bytes each round used to cost. Read/Glob/Grep stay granted, so the pack
changes the DEFAULT source of truth, not the ceiling — a reviewer can still chase
anything it judges relevant. Delta rounds carry prior findings by reading the
actual record files listed in `prior/records.txt` (records are never deleted, so
the carry costs zero copies); prior Critical/Major (code) or BLOCKING (doc)
findings stay OPEN and block the verdict unless the round evidences closure —
silence is not closure.

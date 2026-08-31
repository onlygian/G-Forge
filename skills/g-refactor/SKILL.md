---
name: g-refactor
description: Guided refactor workflow — identify target, pre-analyse, spec, approve, execute, review. Accepts a scope path, an audit milestone file, or runs interactively. Safe-by-default: checks test coverage before execution and runs the full review gate after.
---

**Announce:** "Using g-refactor to run the guided refactor workflow."

You orchestrate the refactor pipeline. You do not write code yourself — you coordinate spec-writer, refactor-executor, and the review gate.

## Step 1 — Identify the target

**If the argument is a milestone file** (e.g. `g-docs/milestones/M-audit-2025-05.md`):
- Read the milestone file.
- Print the P0 and P1 task tables.
- Ask: "Which task(s) do you want to refactor in this session? Enter task number(s) or **all P0** / **all P1**."
- Wait for the answer. Set `targets: [list of selected rows]`.

**If the argument is a path** (e.g. `src/services/UserService.ts` or `src/services/`):
- Set `targets: [path]`.
- Skip the milestone prompt.

**If no argument was provided**, ask:
> "What do you want to refactor? Options:
> a) Path or file — e.g. `src/services/UserService.ts`
> b) Load findings from an audit — e.g. `g-docs/milestones/M-audit-2025-05.md`
> c) Describe what to improve in plain English"

Wait for the answer and resolve to a concrete target list before continuing.

## Step 2 — Gather context

For each target:

1. If target is a file: read it fully.
2. If target is a directory: Glob `[target]/**/*` for source files (exclude tests, node_modules, dist). Read files that are ≤200 lines. For files >200 lines, read the first 50 lines to understand structure.
3. Read the project's layer rules from `CLAUDE.md` and `.claude/rules/architecture-*.md` if present.
4. Run: `git log --oneline -10 -- [target]` to understand change frequency (high churn = higher risk).

## Step 3 — Test coverage check

For each target file, check whether a corresponding test file exists:

```bash
# Find test files for each target
find . -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" \
  -not -path "*/node_modules/*" | grep -i "[basename of target]"
```

**Coverage assessment:**
- **Good**: test file exists and tests public API surface
- **Partial**: test file exists but covers <50% of public methods (estimate from reading)
- **None**: no test file found

**If coverage is None or Partial**, surface this before proceeding:
> "⚠ [target] has [no / partial] test coverage. Refactoring without tests risks undetected regressions.
> Options:
> a) Add tests first — dispatch test-writer now, then refactor (recommended)
> b) Proceed anyway — I'll note this as a risk in the spec"

Wait for the developer's choice.
- If (a): dispatch `test-writer` with the target file and its public API. After tests are written and Tier 1 gates pass, continue to Step 4.
- If (b): proceed, but mark `coverage_risk: HIGH` in the spec.

## Step 4 — Pre-analysis

Dispatch `code-reviewer` and `architecture-enforcer` in parallel on the target(s):

Prompt to `code-reviewer`:
> Review [target files] for code quality issues, SOLID violations, and smells. Focus on what should change — not what's already good. This is a pre-refactor analysis, not a merge gate review.

Prompt to `architecture-enforcer`:
> Review [target files] against the project's layer rules in CLAUDE.md [and .claude/rules/architecture-*.md]. Report any import direction, circular dependency, SRP, or DIP violations.

Collect both reports. Merge them into a findings list.

## Step 5 — Generate the spec

Dispatch `spec-writer` with:
- The target file(s) content from Step 2
- The merged findings from Step 4
- The coverage risk flag from Step 3
- The project layer rules
- An `output_file` path, following the `g-docs/agent-output/` convention: `g-docs/agent-output/g-refactor/spec-writer-[YYYY-MM-DD]-[slug].md`, where `[slug]` is a short slugified form of the target being refactored. Create the `g-docs/agent-output/g-refactor/` directory first if it does not exist.
- This constraint prompt:

> Write a refactor spec for [target]. The spec must:
> 1. Address every finding from the pre-analysis (list them).
> 2. Not change external behaviour — public API contracts must be preserved.
> 3. Include a done condition that is mechanically verifiable (grep, file check, or test output).
> 4. Flag any step that carries HIGH change risk due to test coverage gaps.
> 5. If the scope would produce >10 implementation steps, split into waves and note which steps are independent.

Wait for spec-writer to return. spec-writer holds no Write tool (reviewer-class per the installed `.claude/rules/architecture-<stack>.md` — in this repo's self-hosted case the `agents/` layer-map bullet and the **Agent rule** paragraph of `profiles/claude-plugin/rules/architecture.md`) — it returns the full spec content in its result rather than writing the file itself. Write that returned content to the `output_file` path assigned above using your own Write tool before proceeding to Step 6.

## Step 6 — Human approval gate

Present the spec to the developer:

```
## Refactor Spec — [target]

[full spec content from spec-writer]

---
Pre-analysis findings addressed: [N]
Coverage risk: [LOW / MEDIUM / HIGH]
Estimated waves: [N]

Approve this spec? (approve / edit / cancel)
```

Wait for explicit approval. Do not proceed without it.

- **"approve"** or equivalent ("yes", "looks good", "do it"): proceed to Step 7.
- **"edit"**: ask what to change, re-dispatch spec-writer with the edit note and a new `output_file` path (same convention as Step 5, with a `-r2`-style round suffix so the prior run's file is never overwritten). Write the returned spec content to it as in Step 5, re-present.
- **"cancel"**: stop. Report: "Refactor cancelled at spec review."

## Step 7 — Execute in waves

If the spec has a single wave (≤10 steps):

Dispatch `refactor-executor` with the full spec. Wait for completion report.

If the spec defines multiple waves:

For each wave in order:
1. Announce: `── Wave [N] — [wave description] ──`
2. Dispatch `refactor-executor` with the wave's steps only.
3. Wait for completion report.
4. Run Tier 1 gates (lint + type-check + tests) before proceeding to the next wave:
   ```bash
   # Detect and run Tier 1 gates — check package.json / Makefile / pyproject.toml
   ```
   If any gate fails: stop. Report the failure. Do not proceed to the next wave. Ask the developer how to resolve.

After all waves complete:

Report:
```
Refactor complete.
Waves: [N/N done]
Files modified: [list]
All Tier 1 gates: PASS
```

## Step 8 — Review gate

Run `/g-review` on the refactored branch.

If code-lead issues **MERGE READY**: report success and stop.

If code-lead issues **HOLD**: present the blocking findings. Ask:
> "The review has [N] blocking findings. Fix them now and re-run `/g-review`, or open a follow-up task? (fix / defer)"

- **"fix"**: for each blocking finding, dispatch `spec-writer` to produce a targeted fix spec — assign each an `output_file` path following the Step 5 convention (one per finding, discriminated: `g-docs/agent-output/g-refactor/spec-writer-[YYYY-MM-DD]-[slug]-fix-r[N].md`, `[N]` = 1 + the highest existing ordinal for that date+slug — never overwrite a prior fix spec) and write the returned content there as in Step 5 — get approval (Step 6 abbreviated), execute. Re-run `/g-review` after all fixes.
- **"defer"**: add each unresolved finding as a follow-up task to `g-docs/todo.md`. Stop.

## Step 9 — Update the milestone (if launched from audit/optimize milestone)

If this refactor session was launched from an audit or optimize milestone file:
- Mark each completed task row as `✅` in the milestone file.
- If all P0 tasks are now ✅, update the milestone status in `g-docs/ROADMAP.md` to `🔄 In progress` (or `✅ Complete` if all tiers are done).
- Commit both files with message: `chore: mark [task names] complete in [milestone file]`

## Rules
- Never write code — only orchestrate. spec-writer writes specs; refactor-executor makes changes.
- Never proceed past Step 6 without explicit developer approval of the spec.
- Never skip the Tier 1 gate between waves.
- Never skip the Step 8 review gate — a refactor that doesn't pass `/g-review` is not done.
- If `coverage_risk: HIGH` and the developer chose to proceed anyway (Step 3b): remind them at Step 6 and Step 8 that regressions may be silent without test coverage.
- Public API contracts must be preserved — if the spec requires a breaking change, surface it explicitly and wait for developer acknowledgment before approving.
- Scope creep is a hard stop: if refactor-executor reports adjacent issues, do not act on them. Log them to `g-docs/todo.md` as follow-up items.

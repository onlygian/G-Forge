---
name: g-skill-validate
description: Validate a skill or agent file against G-Forge structural rules. Checks SKILL.md format, retired-shim absence, router registration, and agent frontmatter. Issues VALID or NEEDS FIXES verdict.
---

**Announce:** "Using g-skill-validate to validate the skill."

You are validating a G-Forge skill or agent against structural rules. Run all checks, produce a ✓/✗ checklist, and issue a final verdict.

## Step 1 — Identify what to validate

If a skill name was provided as an argument (e.g. the user typed `/g-skill-validate g-foo`), use that name.

If no argument was provided, ask:

> "Which skill or agent do you want to validate? Provide the skill name (e.g. `g-foo`) or agent filename (e.g. `code-reviewer.md`)."

Wait for input.

Determine from the name whether this is a skill (look for `skills/[name]/SKILL.md`) or an agent (look for `agents/[name]`).

## Step 2 — Validate SKILL.md (skills only)

Locate `skills/[name]/SKILL.md`. If the file does not exist, record: ✗ SKILL.md not found — skip remaining skill checks and go to Step 6.

Run these checks and record ✓ or ✗ for each:

**Frontmatter checks:**
- `name:` field present
- `description:` field present
- `context:` field (memory-layer declaration, G-RULES §J) is optional — its presence or absence is ✓ either way
- `argument-hint:` is NOT present (its presence is a violation — breaks skill loading)
- No frontmatter fields beyond `name`, `description`, and optionally `context` (any other field is a violation — flag it by name)

**Body checks:**
- `**Announce:**` line present (must appear before the first step)
- At least 2 numbered steps present (`## Step N —` format)
- `## Rules` section present
- No `Skill()` invocations anywhere in the file (search for `Skill(`)
- No hardcoded absolute paths starting with `/home/`, `/Users/`, `C:\`, `D:\` (use Glob to discover paths instead)

## Step 3 — Validate shim absence (skills only)

Per ADR-007, `skills/[name]/SKILL.md` is the sole authored source for a skill — standalone `commands/[name].md` shims are retired.

Check whether `commands/[name].md` exists:
- If it exists, record: ✗ retired shim present — `commands/[name].md` must be deleted (ADR-007: SKILL.md is the sole authored source; the shim produces a second, independently-drifting description surface).
- If it does not exist, record: ✓ no retired shim present.

## Step 4 — Validate router registration (skills only)

Read `commands/g-forge.md`. Check and record ✓ or ✗:
- A bare-token routing line exists for this skill's subcommand (`- \`[token]\` → \`skills/g-[name]/SKILL.md\`` format)
- No per-skill prose or description accompanies that routing line or its subcommand token elsewhere in the router (the router carries bare tokens only — per-skill prose is a violation, ADR-007: it is the third description surface that drifted)

## Step 5 — Validate agent file (agents only)

If validating an agent, locate the agent file in `agents/`. If absent, record: ✗ agent file not found — skip to Step 6.

If present, check and record ✓ or ✗:

**Frontmatter checks:**
- `name:` field present
- `description:` field present
- `model:` field present (must be a model alias Claude Code accepts — `haiku`, `sonnet`, `opus`, or a newer top-tier alias such as `fable` — or a full `claude-*` model id. Warn rather than fail on an unrecognised bare alias: new model families ship ahead of this list)
- `tools:` field present

**Body checks:**
- Output Format section present (agents must define their report structure)
- Tool grants match the agent's declared class (see below) — a grant outside every class, or an unscoped Write grant on a reviewer, is a violation
- Body outputs findings, never fixes — a prose suggestion of how to fix is a finding; executing a fix or emitting implementation content is not (look for steps that instruct the agent itself to edit files) — applies to the reviewer class only: diagnostic-class agents likewise propose fix strategies by role and never implement, and writer-class agents implement by role

**Determining the permitted tool grants:**

Do not hardcode a tool list here — read the class definitions from the installed architecture profile: `.claude/rules/architecture-<stack>.md` (or, in this repo's self-hosted case, `profiles/claude-plugin/rules/architecture.md:6` and `:19`, the `agents/` layer-map bullet and the **Agent rule** paragraph). Those bullets define three tool classes:

- **reviewer** — `Read`, `Glob`, `Grep` only; findings, never fixes. A `Write` grant is sanctioned only when the agent body scopes it explicitly to its own record/report paths (e.g. `code-lead` writing review records), never to implementation files.
- **diagnostic** — reviewer's grants plus `Bash`, for verification runs (e.g. `code-lead`, `debugger`, `error-detective`).
- **writer** — reviewer's grants plus `Write`/`Edit`, for outputs the agent owns (e.g. `doc-writer`, `test-writer`, `<stack>`-implementers, `refactor-executor`).

An `Agent(...)` dispatch grant is orthogonal to these classes — it names which children the holder may dispatch, never what it may read or write — and is disregarded when classifying (e.g. `review-orchestrator` holds only a dispatch grant; `feature-implementer` is a writer that also dispatches `doc-writer`).

Classify the agent under validation by its declared `tools:` frontmatter field, then fail only if: (a) it holds a file-access tool outside all three classes (the `Agent(...)` dispatch grant is not counted), or (b) it holds `Write` while its body does not scope that grant to its own record/report paths and it is not otherwise a declared writer-class agent.

## Step 6 — Report

Output the full checklist, then issue the verdict:

```
## Skill Validation: [name]

### SKILL.md
✓ name: present
✓ description: present
✗ argument-hint: found on line 3 (must be removed — breaks skill loading)
✓ Announce line present
✓ Numbered steps (4 found)
✓ Rules section present
✗ Skill() invocation found on line 23 (remove — causes infinite loop)
✓ No hardcoded absolute paths

### Shim absence (commands/[name].md)
✓ no retired shim present

### Router (commands/g-forge.md)
✓ Bare-token routing line present
✗ Per-skill prose found alongside the subcommand token (must be removed — ADR-007)

---
VERDICT: NEEDS FIXES — 3 issues found
```

If all checks pass:

```
---
VERDICT: VALID — all checks passed
```

## Rules
- Run all checks before issuing the verdict — do not stop at the first failure.
- Never fix the issues yourself — report only. The developer fixes and re-runs validation.
- If the target file does not exist, the verdict is NEEDS FIXES with "file not found" as the finding.
- For skills: validate SKILL.md + shim absence + router bare-token line together — not just SKILL.md alone (ADR-007: no per-skill command file; `commands/[name].md` existing is a violation, not a requirement).
- For agents: validate agent file only (no command file or router check needed).

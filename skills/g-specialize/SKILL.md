---
name: g-specialize
description: Determine which stack profiles to apply by reading the project brief, roadmap, and dependency files. Handles multi-stack projects. Detects known stack combos and installs combo architecture rules covering emergent cross-stack patterns. Consults code-lead when the picture is ambiguous or risky. Installs architect agents, a write-side implementer agent per stack, and architecture rules. Supported stacks: angular, asp-net-core, astro, bun, c-embedded, capacitor, cpp-cmake, django, electron, express, fastapi, flask, flutter, go-fiber, go-gin, godot-csharp, godot-gdscript, hono, kotlin-android, kotlin-ktor, laravel, maui, nest-js, next-js, node-ts, nuxt, phoenix-liveview, pygame, python-cli, python-data, python-ml, python-textual, rails, react, react-native, remix, rust-axum, rust-cli, spring-boot, sveltekit, swift-ios, tauri, unity, unreal, vue-pinia, wpf-csharp, xamarin, claude-plugin. Supplementary: frontend-data-flow (auto-installed alongside component frameworks).
---

**Announce:** "Using g-specialize to apply the stack profile."

You install, per detected stack: an **architect** (read-side, reviews layer violations), an **implementer** (write-side, executes wave tasks in the stack's idioms), and the architecture rules both rely on — all project-native afterward.

## Step 1 — Detect stacks

Run `scripts/detect-stack.sh` from the project root. It scans the brief, roadmap, and dependency manifests (the dependency→stack mapping, combo table, and supplementary trigger live in it) and prints `STACK:`/`COMBO:`/`SUPPLEMENTARY:`/`UNSUPPORTED:`/`CONFLICT:` lines plus per-profile `AGENT_FILE:`/`RULES_FILE:`/`MISSING:` paths (local `profiles/` first, then the plugin cache under `~/.claude/plugins/cache/g-forge/g-forge/*/`). Also read `g-docs/project_brief.md` yourself for names its grep misses (prose like "Vue 3") and re-run with those — and any explicit argument — as candidate args. Synthesise: stacks + sources, unsupported, conflicts, profiles to apply, combos.

## Step 2 — Research current stable/LTS state

Per profile, verify current stable/LTS state — prefer context7 (resolve-library-id + query-docs) when available, WebSearch fallback with `"[stack] stable release [current year]"` and `"[stack] best practices [current year]"`. Stable/LTS/GA only, ignore pre-release. Read `references/research-scope.md` for scope rules, extract/do-not-extract lists, and the version-note format; store one note per stack for Steps 4 and 6.

## Step 3 — Handle edge cases before confirming

When any of these fire, read `references/detection-edge-cases.md` and follow it: explicit stack argument (validate, skip detection), `UNSUPPORTED:`/`CONFLICT:` lines, no brief and no dependency files (ask the developer), ambiguous picture (dispatch code-lead with the consult prompt there), a code-lead Medium/High risk flag, xamarin (EOL note). To explain combos or frontend-data-flow, read `references/combo-rationale.md`.

## Step 4 — Confirm with developer

Present each profile's architect + implementer + rules, combo rules (no agent), version notes with material changes, and every write to come (`.claude/agents/`, `.claude/rules/`, CLAUDE.md `@`-references, architect version notes). End with `Continue? (y/n)` and wait before writing anything.

## Step 5 — Locate and read profile files

Use Step 1's `AGENT_FILE:`/`RULES_FILE:` paths; read both files per profile before writing anything (combos: rules only). On `MISSING: [stack]`, tell the developer: "Could not find the profile files for '[stack]'. If this is a new profile, ensure it exists under profiles/<stack>/. Otherwise run `/plugin update g-forge` to refresh the cache." and stop.

## Step 6 — Write agents to .claude/agents/

Per profile (combos skip this step):

1. Write the agent content to `.claude/agents/<agent-filename>`. If a file with a matching frontmatter `name:` exists, ask "[agent-name] is already installed. Overwrite? (y/n)" and wait.
2. **After writing each agent file**, append the stack's Step 2 version note (skip if none):
   ```
   ---
   <!-- Stable/LTS version note — injected by /g-specialize, [date]. Do not edit manually. -->
   [stack] stable [version] (LTS: [version or "same"])
   Notable current patterns:
     • [changes, or "No material pattern changes found — profile defaults apply."]
   <!-- End version note -->
   ```
3. **Also after writing each agent file**, write `.claude/skills/architecture-[stack]/SKILL.md` — frontmatter (`name: architecture-[stack]`, `description: [Stack] architecture rules and patterns. Preloaded into the [stack] architect agent at startup.`) followed by the full unmodified content of `profiles/[stack]/rules/architecture.md` as the body — then re-read the agent file and add, immediately before the frontmatter's closing `---`:
   ```yaml
   skills:
     - architecture-[stack]
   ```
4. Install the stack **implementer** (wave execution routes the stack's implementation tasks to it). Read `templates/stack-implementer.md` (same local-first/cache lookup); substitute `{{IMPLEMENTER_NAME}}` (architect filename base, `-architect` → `-implementer`), `{{ARCHITECT_NAME}}`, `{{STACK_LABEL}}`, `{{ARCHITECTURE_SKILL}}` (`architecture-[stack]`), and `{{OWNS_GLOBS}}`: run `scripts/derive-owns.sh <rules-file>`, paste each `OWNS: "<glob>"` value as a two-space-indented YAML list item; on `OWNS: none` remove the entire `owns:` key (wave-planner falls back to stack-label routing). Strip the leading template-usage comment, write `.claude/agents/[implementer-name].md`, same overwrite gate.

Report `✓` per profile: architect, architecture-[stack] skill, implementer.

## Step 7 — Install architecture rules

For each profile AND combo key: copy the rules file to `.claude/rules/architecture-[stack].md` (create the dir; overwrite — G-Forge managed). Read CLAUDE.md (create with a `# [Project]` header if absent); unless `<!-- G-Forge [stack] Architecture Rules` is already present, append:
```
<!-- G-Forge [stack] Architecture Rules — injected by /g-specialize. Do not edit manually. -->
@.claude/rules/architecture-[stack].md
<!-- End G-Forge [stack] Architecture Rules -->
```
CLAUDE.md holds only these one-line `@`-references — never rules content inline. Report `✓` per file.

## Step 8 — Report and initial dependency audit

Report what was applied; note the agents are project-native (architects dispatched during review/planning on their stack; implementers dispatched automatically by wave execution). Then dispatch `dependency-auditor` with all manifests from Step 1 as the baseline audit; if none, skip silently.

## Rules

- Never write any file before Step 4 confirmation; never overwrite an existing agent without confirmation.
- Profile files are read from the plugin directory — never embedded or hardcoded here. If it cannot be located, give the developer the expected path and ask them to verify the install.
- code-lead is consulted only on ambiguity or a risk-flagged brief stack — not every run.
- An explicit stack arg skips all detection: straight to Step 2 (research) then Step 4 (confirm).
- Research covers stable and LTS releases only — pre-release, canary, experimental, and RC versions are ignored regardless of recency.
- Version notes are informational — they never override profile rules; surface contradictions during confirmation, never silently rewrite the rules file.

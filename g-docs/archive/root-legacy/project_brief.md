# G-Forge Plugin

**Created:** 2026-05-04
**Status:** Active development

## Current state

**Stack:** Claude Code plugin — Markdown + Bash + JSON (no runtime)
**Architecture:** `commands/` (router) → `skills/` (skill logic) → `agents/` (specialists) → `profiles/` (44 stack configs) → `hooks/` (enforcement)
**Tests:** None — skills and agents are validated manually by deploying and using
**Entry point:** `commands/g-team.md` (routes subcommands to skill SKILL.md files via Glob+Read)
**Version:** 0.3.1 (published to Claude Code marketplace as onlygian/g-team)

## Problem / Goal

G-Forge is a structured development workflow plugin for Claude Code. It enforces plan→execute→review discipline, gates commits behind a review pipeline, and brings specialist agents and stack-specific architecture rules to any project.

The immediate goals are:
1. **Self-host g-team on the g-team repo** — the plugin itself should follow the workflow it enforces (CLAUDE.md, project_brief.md, commit hooks, milestone files, roadmap aligned)
2. **Add a `claude-plugin` stack profile** — a first-class profile for building Claude Code plugins/skills/agents, with an architect agent and architecture rules
3. **Add vibecoding skills** — skills that help developers design and validate new Claude Code skills/agents (skill-design, skill-validate or equivalent)
4. **Establish best practices for AI-driven development** that live in the `claude-plugin` profile rules and can be referenced by any project building AI tooling

## Scope

### In scope
- Install g-team into this repo: `CLAUDE.md` with G-rules, `G-RULES.md`, commit enforcement hooks, `.claude/settings.json` hook registration
- Create milestone files for M6, M7, M8 (files exist in ROADMAP but have no corresponding `milestones/` entries)
- `claude-plugin` stack profile: architect agent + architecture rules covering skill format, agent format, command routing, hook patterns, output contracts
- `/g-skill-design` skill: guided workflow for designing a new skill or agent — asks about purpose, trigger conditions, step structure, output format; produces a SKILL.md or agent .md draft
- `/g-skill-validate` skill: validates an existing SKILL.md or agent file against quality criteria — checks announce line, step completeness, output format, rules section, ambiguity
- Best practice rules for plugin/skill development baked into the `claude-plugin` architecture rules

### Out of scope
- Changing the existing skill file format or plugin structure
- Breaking backwards compatibility with published skills
- Adding a runtime or test framework (addressed separately as a known risk)

### Known risks / existing issues
- **No automated tests** — all skill/agent quality is validated by hand. Changes to skills or hooks can introduce regressions that aren't caught until the plugin is used in a real project. Addressing this is lower priority but worth tracking.
- **milestones/ directory is stale** — M6, M7, M8 have no files; milestone close-out logic in `/g-review` will silently skip them.
- **docs/superpowers/** — stale subdirectory from an earlier development phase; may contain outdated references.

## Tech decisions

| Component | Choice | Rationale | Risk | Code-lead note |
|-----------|--------|-----------|------|----------------|
| Plugin format | Claude Code plugin manifest (plugin.json + marketplace.json) | Required by Claude Code platform | Low | - |
| Skill format | Markdown with YAML frontmatter (name, description) | Platform requirement; Glob+Read pattern for loading | Low | No `argument-hint` in frontmatter — causes loading failure |
| Agent format | Markdown with YAML frontmatter (name, description, model, tools) | Platform requirement | Low | - |
| Hook scripts | Bash (check-commit.sh, workflow-checkpoint.sh, post-commit-cleanup.sh) | Claude Code hook system; bash is cross-platform with Git Bash | Low-Medium | Windows requires Git Bash; `python3` vs `python` may differ |
| Config | JSON (.claude/settings.json) | Claude Code settings format | Low | - |

## Technical constraints

- Stays true to the plugin's core goal: planned execution, enforced review, production architecture
- Backwards compatible with existing skill format and published plugin version
- No new runtimes or build steps

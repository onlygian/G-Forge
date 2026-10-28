# [Project Name]

<!--
Maintainer note — Claude Code strips block-level HTML comments before this file reaches the model, so this costs no context.
Keep this file under 200 lines: every line loads every session, and longer files are followed less reliably. Imported files load in full too — imports organize, they do not shrink.
Write what Claude cannot derive from the code: constraints, pitfalls, the WHY behind conventions that differ from tool defaults.
Leave out what it can read for itself: directory layouts, dependency lists, architecture overviews.
Behaviour that must happen every time belongs in a hook, not in prose here.
-->

@G-RULES.md

[One paragraph: what this project is, who it's for, and the core thing it does. Include any key design constraints or principles that should shape every decision.]

---

## Quick commands

```bash
[dev server]      # e.g. npm run dev
[type-check]      # e.g. npx vue-tsc --noEmit
[lint]            # e.g. npm run lint
[test]            # e.g. npm test
[build]           # e.g. npm run build
```

---

## Stack

| Layer | Choice |
|-------|--------|
| [Framework] | [e.g. Vue 3, React 18, SvelteKit] |
| [State] | [e.g. Pinia, Zustand, Redux] |
| [Backend / Runtime] | [e.g. Express, FastAPI, Tauri, Electron] |
| [Persistence] | [e.g. SQLite, Postgres, localStorage] |
| [Styling] | [e.g. Tailwind, CSS modules, scoped SFCs] |
| [Types] | [e.g. TypeScript strict, no any] |

---

## Architecture constraints

[Invariants a reader cannot see from the tree: layer boundaries and import directions that must hold, who owns which state, where side effects may happen. Not the directory layout — Claude reads that itself.]

---

## Conventions

- [Naming rules — files, functions, stores, composables]
- [Patterns that must always be followed]
- [Patterns that must never be used]
- [Anything surprising about this codebase a new reader should know]

---

## Project Tracking

`g-docs/ROADMAP.md` is the milestone roadmap and single source of truth.

---

<!-- G-Forge Rules — injected by /g-init. Do not edit manually. -->
<!-- (rules loaded via @G-RULES.md at top of file) -->
<!-- End G-Forge Rules -->

<!-- G-Forge [stack] Architecture Rules — injected by /g-specialize. Do not edit manually. -->
<!-- Replace this block: @.claude/rules/architecture-[stack].md -->
<!-- End G-Forge [stack] Architecture Rules -->

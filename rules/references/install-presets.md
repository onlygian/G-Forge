# G-Rules install presets

Provenance: moved from the `G-RULES.md` v2.5 preamble during the v2.6 token diet — install-time guidance, never needed in-session. README §G-RULES.md carries the condensed preset table and points here for the full per-section import list.

Drop `G-RULES.md` at project root. In `CLAUDE.md` add: `@G-RULES.md`

To reduce per-session token cost, replace `@G-RULES.md` in `CLAUDE.md` with only the sections your project needs. This works because the section files live in `.claude/g-rules/`, which Claude Code does not auto-load — a section nobody imports costs nothing (ADR-017). Never copy a section into `.claude/rules/`: everything there loads every session. Common presets:

| Project type | Recommended sections |
|---|---|
| Minimal (any project) | A, B, C, D |
| + architecture enforcement | + E |
| + design patterns | + F |
| + documentation standards | + G |
| + testing protocol | + H |
| + project tracking | + I |
| Full (all rules) | A–J (`@G-RULES.md`) |

Available sections:
- `@.claude/g-rules/A-session.md` — model selection, planning, execution, token optimisation
- `@.claude/g-rules/B-workflow.md` — G-Forge lifecycle, per-task loop, PM interface, skills reference
- `@.claude/g-rules/C-agent-discipline.md` — wave model, spawn decisions, agent caps
- `@.claude/g-rules/D-code-quality.md` — SOLID, style, naming, testing, branch discipline, versioning
- `@.claude/g-rules/E-architecture-gate.md` — mandatory architecture review sequence
- `@.claude/g-rules/F-design-patterns.md` — principles and anti-patterns
- `@.claude/g-rules/G-documentation.md` — what must be documented, currency rule, ownership
- `@.claude/g-rules/H-testing.md` — three-tier testing protocol, listen mode
- `@.claude/g-rules/I-project-tracking.md` — file hierarchy, commit gate, g-docs/todo.md structure
- `@.claude/g-rules/J-memory.md` — memory layer taxonomy

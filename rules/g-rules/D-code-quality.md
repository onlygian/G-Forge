## D · Code Quality

**SOLID**
- **Single Responsibility (SRP)** — one reason to change per module/class/function. Symptom: the name contains "and"/"also", or the file has two clearly separable sections.
- **Open/Closed (OCP)** — extend by adding new code, not modifying existing code. A switch/if-else chain edited for every new type → strategy map, polymorphic dispatch, or registry.
- **Liskov Substitution (LSP)** — subtypes honour the full supertype contract: no overrides that throw where the base returns, narrow the input type, or silently ignore behaviour. Prefer composition over inheritance.
- **Interface Segregation (ISP)** — depend only on what you use: narrow types/destructured params over fat objects; split any interface half-implemented with `not implemented` stubs.
- **Dependency Inversion (DIP)** — business logic never `new`s its own services or imports concrete adapters (database driver, HTTP client, third-party SDK); wrap behind an interface and inject via constructor/function.

Borderline calls and worked examples: `.claude/rules/references/code-quality-notes.md`.

**Style**
- `const` everywhere; `let` only when reassignment is unavoidable; never `var`
- Module-level `let` requires a WHY comment — explain why it's not a reactive/store value
- Named exports only (no `export default` in lib/composables; components/classes are the exception)
- Return early / fail fast — validate at top, minimise nesting
- No duplication — extract shared logic.

**Naming — files**

| Type | Convention |
|------|------------|
| Components / classes | `PascalCase` |
| Lib / utilities / stores | `camelCase` |
| Composables | `camelCase`, prefix `use` |

**Naming — functions**

| Type | Convention |
|------|------------|
| Data reads | `fetchX` |
| Data writes | `createX` / `updateX` |
| Event handlers | `handleX` |
| Booleans | `isX` / `hasX` |
| Store actions | verb + noun (`setActivePage`) |
| Unused args | `_arg` prefix |

Composable export matches filename: `useFoo.ts` → `export function useFoo`.

**Comments** — WHY only: hidden constraint, subtle invariant, platform workaround. One line max. No commented-out blocks. Use `// region Name` / `// endregion` in files >~150 lines.

**Error handling** — Explicit errors, no silent failures. Validate at system boundaries only (user input, external API). Never hardcode secrets. Watch for O(n²) on critical paths.

**Testing**
- Fixed hardcoded data — never `Date.now()` or random values in setup
- Static expected values — no programmatically built expected strings
- Happy path + boundary conditions + error cases
- Named by scenario, not "it works"
- Mandatory: bug fixes · critical business logic · public APIs
- Optional: internal helpers tested indirectly via integration tests

**Component / module structure** — Stack-specific. See `.claude/rules/architecture-<stack>.md` installed by `/g-specialize`.

**Branch discipline**
- Non-trivial work (≥3 files, new feature, layer-boundary change, unclear bug, public API change) → create a feature branch before the first file change: `git checkout -b feat/<slug>`, `fix/<slug>`, or `refactor/<slug>`
- All work subject to the commit gate (`.claude/g-forge-approved` required) regardless of branch
- MERGE READY verdict on a feature branch → HQ merges to main (`git merge --no-ff`) or opens a PR. Never force-push to main.
- MERGE READY on main is only acceptable for: hotfixes (single-file bug fix), doc-only changes (README, CHANGELOG, comments), or version bumps. Everything else requires a branch.
- Branch naming: `feat/<slug>` for new features, `fix/<slug>` for bug fixes, `refactor/<slug>` for refactors, `chore/<slug>` for housekeeping

**Versioning & release flow**

The project uses [Semantic Versioning](https://semver.org/) with an optional hotfix suffix. Versions are milestone-scoped — every milestone gets a target version at planning time (`/g-roadmap` Step 3, developer-confirmed), and the bump happens when the milestone closes: `/g-review` prompts it, the developer decides and commits — never auto-bumped.

*Version format:* `MAJOR.MINOR.PATCH[a]` — **MINOR** (`x.Y.0`): new user-facing capability, public API, skill/command, or profile · **PATCH** (`x.y.Z`): bug fixes, internal refactors, polish, dependency updates, doc-only changes · **MAJOR** (`X.0.0`): breaking change · **hotfix suffix** (`a`): out-of-band fix after a release (e.g. `0.3.3a`); resets on next planned version.

*Version sources — must always agree, updated in the same commit; disagreement is a release-blocking defect:*

| File | Field |
|------|-------|
| `.claude-plugin/plugin.json` | `version` |
| `.claude-plugin/marketplace.json` | `plugins[0].version` |

*Version never changes mid-milestone.* If scope creep changes the bump type, update the milestone's `**Version:**` field in `g-docs/ROADMAP.md` and note the reason before continuing.

**At release time (version bump / milestone close / hotfix), read `.claude/rules/references/release-flow.md` and follow its release commit sequence — it is mandatory at that moment, including the grep-the-released-fact sweep (ADR-012/ADR-013) and the git-tag rules.**

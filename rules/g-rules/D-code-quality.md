## D · Code Quality

**SOLID**
- **Single Responsibility (SRP)** — one reason to change per module/class/function. A unit that handles data access *and* business logic needs splitting. Symptom: the name contains "and" or "also", or the file has two clearly separable sections.
- **Open/Closed (OCP)** — extend behaviour by adding new code, not by modifying existing code. A switch/if-else chain that must be edited every time a new type is added is a violation — replace with a strategy map, polymorphic dispatch, or registry.
- **Liskov Substitution (LSP)** — subtypes must honour the full contract of their supertype. An override that throws where the base returns a value, accepts a narrower input type, or silently ignores part of the supertype's behaviour is a violation. Prefer composition over inheritance to sidestep LSP traps.
- **Interface Segregation (ISP)** — depend only on what you use. A function that receives a large object and reads two fields out of ten should accept a narrower type or destructured params. A class that implements an interface but leaves half the methods as `throw new Error('not implemented')` needs the interface split.
- **Dependency Inversion (DIP)** — high-level modules depend on abstractions, not concrete implementations. Business logic must not `new` its own services — receive them via constructor/function injection. An import of a concrete adapter (database driver, HTTP client, third-party SDK) inside a domain or business-logic module is a DIP violation; wrap it behind an interface and inject it.

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

The project uses [Semantic Versioning](https://semver.org/) (semver) with an optional hotfix suffix. Versions are milestone-scoped — every milestone gets a target version at planning time, and the bump happens when the milestone closes.

*Version format:* `MAJOR.MINOR.PATCH[a]`
- **MINOR** bump (`x.Y.0`) — new user-facing capability, new public API, new skill/command, new profile
- **PATCH** bump (`x.y.Z`) — bug fixes, internal refactors, polish, dependency updates, doc-only changes
- **MAJOR** bump (`X.0.0`) — breaking change to public API or incompatible behaviour change
- **Hotfix suffix** (`a`) — appended to patch for out-of-band fixes after a release (e.g. `0.3.3a`, `0.3.5a`). Used when a critical fix must ship without bundling into the next planned release. Resets on next planned version.

*Version sources — must always agree:*

| File | Field |
|------|-------|
| `.claude-plugin/plugin.json` | `version` |
| `.claude-plugin/marketplace.json` | `plugins[0].version` |

Both files are updated in the same commit. Disagreement between them is a release-blocking defect.

*When to bump:*
- `/g-roadmap` assigns a target version to each milestone at planning time (Step 3). The developer confirms before milestones are written.
- `/g-review` prompts a version bump when all tasks in a milestone are closed. The developer decides and commits it — never auto-bumped.
- Hotfix patches (`a` suffix) bypass the milestone cycle: fix on `main`, bump `PATCH` + append `a`, commit, push.

*Release commit sequence:*
1. All milestone work merged to `main` and MERGE READY
2. Update version in `plugin.json` and `marketplace.json`
3. Add CHANGELOG entry under the new version heading (Keep a Changelog format)
4. Update README if skill/profile counts, command lists, or capability descriptions changed
5. Grep the literal fact being released (old version string, "candidate"/"pending"/status word, milestone token) across every live surface — never walk a typed site list (ADR-012, ADR-013). The v2.4.1 cut missed live carriers this way.
6. Single commit: `chore: bump to vX.Y.Z` or `vX.Y.Z — <milestone summary>`
7. Push immediately — never leave a version bump unpushed
8. Run `/g-update` on any downstream projects to sync installed files
9. If this repo self-hosts the plugin, resolve any `Installed-copy drift:` line flagged by the review record before tagging — realign `.claude/` from source (`/g-update`) or hand-sync the drifted file; never tag a release over unresolved self-host drift
10. Tag the release commit `vX.Y.Z` (lightweight) and cut the GitHub release with that version's CHANGELOG section as the body — from v2.4.0 onward, per the *Git tags* note below

*Version never changes mid-milestone.* If scope creeps enough to change the bump type (e.g. patch → minor), update the milestone's `**Version:**` field in `g-docs/ROADMAP.md` and note the reason before continuing.

*Git tags:* used from **v2.4.0 onward**, for GitHub releases only. Tag the release commit as `vX.Y.Z` (lightweight tag, no GPG) and cut the release with the CHANGELOG section for that version as the body. The CHANGELOG heading `## [X.Y.Z] — YYYY-MM-DD` remains the **authoritative** version record; the tag is a convenience for `git describe` and the GitHub releases page, never a second source of truth. Versions released before v2.4.0 are deliberately un-tagged and un-released — backfilling them would notify watchers with fictional dates.

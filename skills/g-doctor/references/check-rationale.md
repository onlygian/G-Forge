# Advisory checks — per-check rationale

Load when a Check 20/21/22/25 advisory fires and the developer asks why, or when
editing those checks. Mechanics live in `scripts/checks.sh`; nothing here changes a
verdict.

## Check 20 — `.gitignore` vets G-Forge artifacts

The `.gitignore` is the boundary between the project record (tracked) and
runtime/dev artifacts (ignored). `/g-init` writes it; the check confirms it still
holds. It must **ignore** the runtime artifacts: the commit-gate sentinels
(`.claude/g-forge-approved`, `.claude/g-forge-docs-approved`), the observer journal
(`.claude/journal/`), and the regenerable agent output (`g-docs/agent-output/`). It
must **not ignore** anything tracked-by-design: `g-docs/ROADMAP.md`,
`g-docs/todo.md`, `g-docs/milestones/`, `g-docs/decisions/`, `g-docs/retros/`,
`g-docs/patterns/`, `g-docs/inbox/`, or `g-wiki/`. Watch for over-broad bare
patterns — e.g. a literal `todo.md` or `milestones/` line will wrongly ignore the
`g-docs/` copies.

## Check 21 — why the stray-doc scan is inverted, not an allowlist

Every G-Forge document belongs under `g-docs/` (project record) or `g-wiki/`
(human-facing). Strays are usually tracking files left at the project root from
before the `g-docs/` migration, or ADR/retro/agent-output folders created in a
parallel tree (e.g. `docs/decisions/`, `docs/plans/`). The check is **inverted, not
a fixed allowlist**: rather than checking a short hardcoded list of dir names
(which misses any canonical dir not on the list — the M-audit #23/BUG-4 gap, where
`agent-output/`, `plans/`, and `qa-scope/` slipped through a 6-name allowlist), the
canonical dir-name set is derived from whatever already lives one level under
`g-docs/` in *this* project — every name found there is a G-Forge tracking
convention. This self-updates as new `g-docs/` subdirectories are added (per
G-RULES §I: `decisions/`, `retros/`, `forecasts/`, `plans/`, `blast-radius/`,
`telemetry/`, `alignment/`, `agent-output/`, `qa-scope/`, `milestones/`,
`patterns/`, `inbox/`, etc.) — no manual list maintenance.

**The generic-name collision and the content filter.** A name match alone is not
enough — `patterns/` and `inbox/` are generic enough that a consumer project's
`src/patterns/` or `src/features/inbox/` shares the name by coincidence, not by
drift (generic canonical names entered the set 2026-08-14). A candidate directory
found outside `g-docs/` and `g-wiki/` is only a stray if its own contents look like
G-Forge documents — at least one `.md` file and no source-code file
(`.js`/`.ts`/`.tsx`/`.jsx`/`.py`/`.sh`/`.rs`/`.go`/`.java`/`.vue`) directly inside
it; the content filter tells a stray tracking-doc folder apart from a same-named
source folder.

## Check 22 — Roundtable security (ADR-001 premortem framing)

Runs only if `.claude/roundtable` exists (the M33 Roundtable bind record). Guards
the two failure modes from ADR-001's premortem: a leaked credential and a
world-readable Doc. The bind record and any credentials near it must be gitignored
and never committed; a token-looking line must never sit in the bind record itself
(tokens belong in env vars). And always, as a reminder even on a clean pass: the
bound Doc must be **link-restricted, never public** — `/g-roundtable` enforces this
at bind, but confirm sharing hasn't been widened since.

## Check 25 — why doctor must never suggest a per-worktree tier file

"Governing" means the same ADR-005 resolution the hooks use: the local
`.claude/integration-tier` if present, else the resolved primary tree's
(`gf_guard_claude_dir` / `gf_resolve_primary_claude_dir` in
`hooks/lib/worktree-resolve.sh`). In a linked worktree the local file is
legitimately absent by design and the primary's governs — do NOT report the hook
system inert, and do not tell the developer to write a per-worktree tier file,
which would diverge from the primary — unless **neither** location resolves a valid
value. All 8 hooks — the commit gate included — self-guard on this file
(`check-commit.sh`, `workflow-checkpoint.sh`, `session-start.sh`, `observe.sh`,
`agent-lifecycle.sh`, `post-commit-cleanup.sh`, `pre-compact.sh`, and the native
`pre-commit`), so a missing or corrupt governing file makes the entire hook system
silently go inert while every file-presence check still passes.

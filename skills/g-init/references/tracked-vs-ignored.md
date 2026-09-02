# Tracked vs. ignored — the .gitignore boundary

Load this when a developer questions the boundary or an existing `.gitignore` conflicts with the patterns `scripts/merge-gitignore.sh` adds. (Partial overlap with `rules/g-rules/I-project-tracking.md` — that rule stays authoritative for the doctrine; this is the install-time rationale.)

G-Forge generates two kinds of files, and the `.gitignore` is what keeps them straight: **tracked project record** (commit these — they ARE the project) versus **runtime/dev artifacts** (never commit — per-developer, ephemeral, secret, or regenerable). Getting this boundary right is what makes a clone reproducible and a diff readable. Establish it at init so the first commit lands clean.

**Track (do NOT ignore) — the project and its shared enforcement:**
- Source code and the project's own build/config.
- `CLAUDE.md`, `G-RULES.md`, `CHANGELOG.md`, `README.md`.
- The `g-docs/` project record: `g-docs/ROADMAP.md`, `g-docs/todo.md`, `g-docs/todo-done.md`, `g-docs/milestones/`, `g-docs/project_brief.md`, and `g-docs/decisions/ retros/ forecasts/ telemetry/ blast-radius/ alignment/ patterns/ inbox/adversarial/`.
- `g-wiki/` — committed human-facing content.
- Shared G-Forge config so teammates inherit the same gates: `.claude/hooks/`, `.claude/settings.json`, `.claude/rules/`, `.claude/agents/`.

**Ignore — runtime/dev artifacts:**
- OS/editor: `.DS_Store`, `Thumbs.db`, `*.swp`.
- Secrets/local: `.env`, `.env.*` (but not `.env.example`), `*.local`.
- Worktrees: `.worktrees/`.
- Per-developer + ephemeral G-Forge state under `.claude/`: the two commit-gate sentinels, the observer journal, and the session/runtime counters and caches (including the `.claude/banner-hash.*` session state file).
- Regenerable raw output: `g-docs/agent-output/`.

**Merge behavior:** the script adds only patterns not already present (matching on the exact pattern), appends under a labelled block, and never removes or reorders a developer's existing entries — and never ignores a tracked-by-design path above.

**Note for the developer:** shared G-Forge config (`.claude/hooks/`, `.claude/settings.json`, `.claude/rules/`, `.claude/agents/`) is intentionally **left tracked** so the whole team inherits the same hooks and gates. If this project prefers each developer to run `/g-init` themselves, they can add `.claude/` to `.gitignore` — but then teammates won't get the commit gate from a clone.

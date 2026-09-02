# Manual check catalog — Checks 1–23 and 25

Fallback for when `scripts/checks.sh` is missing or errors: run every check below
by hand against the current working directory and emit the same report lines. This
catalog is the prose mirror of checks.sh — keep the two in sync when editing.
Rationale essays live in `check-16-drift.md` and `check-rationale.md` (deduped from
here); Check 24 is model-executed on every run per `check-24-injection.md` and is
deliberately absent from this catalog. The `hash_file` cascade referenced below is
the fenced block in SKILL.md Check 16 (canonical copy).

**1. commit hook**
Check if `.claude/hooks/check-commit.sh` exists.
- Pass: ✓ commit hook installed
- Fail: ✗ commit hook missing
  → Run `/g-init` to install hooks.

**2. workflow hook**
Check if `.claude/hooks/workflow-checkpoint.sh` exists.
- Pass: ✓ workflow hook installed
- Fail: ✗ workflow hook missing
  → Run `/g-init` or `/g-update` to install the workflow checkpoint hook.

**3. post-commit hook**
Check if `.claude/hooks/post-commit-cleanup.sh` exists.
- Pass: ✓ post-commit hook installed
- Fail: ✗ post-commit hook missing
  → Run `/g-init` or `/g-update` to install the post-commit cleanup hook.

**4. PreToolUse registered**
Read `.claude/settings.json` and check if it contains a `PreToolUse` hook entry pointing to `check-commit.sh`.
- Pass: ✓ PreToolUse hook registered
- Fail: ✗ PreToolUse hook not registered
  → Run `/g-init` or `/g-update` to register the commit gate hook.

**5. UserPromptSubmit registered**
Read `.claude/settings.json` and check if it contains a `UserPromptSubmit` hook entry pointing to `workflow-checkpoint.sh`.
- Pass: ✓ UserPromptSubmit hook registered
- Fail: ✗ UserPromptSubmit hook not registered
  → Run `/g-init` or `/g-update` to register the workflow checkpoint hook.

**6. G-Forge Rules block**
Read `CLAUDE.md` and check if it contains the string `<!-- G-Forge Rules`.
- Pass: ✓ G-Forge Rules block present in CLAUDE.md
- Fail: ✗ G-Forge Rules block missing from CLAUDE.md
  → Run `/g-init` to inject G-Forge rules into CLAUDE.md.

**7. G-RULES.md present**
Check if `G-RULES.md` exists at the project root.
- Pass: ✓ G-RULES.md present
- Fail: ✗ G-RULES.md missing
  → Run `/g-init` or `/g-update` to install G-RULES.md.

**8. @G-RULES.md referenced in CLAUDE.md**
Read `CLAUDE.md` and check if it contains `@G-RULES.md`.
- Pass: ✓ @G-RULES.md reference present in CLAUDE.md
- Fail: ✗ @G-RULES.md reference missing from CLAUDE.md
  → Run `/g-init` or `/g-update` to add the @G-RULES.md reference.

**9. No stale sentinel**
Check if `.claude/g-forge-approved` exists. It should NOT exist (it is auto-cleared after each commit).
- Pass (file absent): ✓ No stale approval sentinel
- Fail (file present): ✗ Stale approval sentinel found
  → A stale approval sentinel exists. Delete it: `rm .claude/g-forge-approved`

**10. No stale doc-approval sentinel**
Check if `.claude/g-forge-docs-approved` exists. It should NOT exist (it is written by `/g-doc-review` on DOCS READY and auto-cleared by `post-commit-cleanup.sh` after each commit). A leftover sentinel means the doc-review gate is stuck open.
- Pass (file absent): ✓ No stale doc-approval sentinel
- Fail (file present): ✗ Stale doc-approval sentinel found
  → A stale doc-approval sentinel exists — the doc gate is stuck open. Delete it: `rm .claude/g-forge-docs-approved`

**11. PreCompact hook installed and registered**
Check if `.claude/hooks/pre-compact.sh` exists AND `.claude/settings.json` contains a `PreCompact` hook entry pointing to `pre-compact.sh`.
- Pass: ✓ PreCompact hook installed and registered
- Fail (file missing): ✗ PreCompact hook script missing
  → Run `/g-init` or `/g-update` to install pre-compact.sh.
- Fail (not registered): ✗ PreCompact hook not registered in settings.json
  → Run `/g-init` or `/g-update` to register the PreCompact hook.

**12. SessionStart hook installed and registered**
Check if `.claude/hooks/session-start.sh` exists AND `.claude/settings.json` contains a `SessionStart` hook entry pointing to `session-start.sh`.
- Pass: ✓ SessionStart hook installed and registered
- Fail (file missing): ✗ SessionStart hook script missing
  → Run `/g-init` or `/g-update` to install session-start.sh.
- Fail (not registered): ✗ SessionStart hook not registered in settings.json
  → Run `/g-init` or `/g-update` to register the SessionStart hook.

**13. observer hooks installed and registered**
Check if `.claude/hooks/observe.sh` exists AND `.claude/settings.json` contains a `PostToolUse` hook entry pointing to `observe.sh` AND a `SessionStart` hook entry pointing to `observe.sh`.
- Pass: ✓ Observer hook installed and registered
- Fail (file missing): ✗ Observer hook script missing
  → Run `/g-init` or `/g-update` to install observe.sh.
- Fail (not registered): ✗ Observer hook not registered in settings.json
  → Run `/g-init` or `/g-update` to register the PostToolUse + SessionStart observer hooks.

**14. agent lifecycle hooks installed and registered**
Check if `.claude/hooks/agent-lifecycle.sh` exists AND `.claude/settings.json` contains a `SubagentStart` hook entry AND a `SubagentStop` hook entry pointing to `agent-lifecycle.sh`.
- Pass: ✓ Agent lifecycle hook installed and registered
- Fail (file missing): ✗ Agent lifecycle hook script missing
  → Run `/g-init` or `/g-update` to install agent-lifecycle.sh.
- Fail (not registered): ✗ Agent lifecycle hook not registered in settings.json
  → Run `/g-init` or `/g-update` to register the SubagentStart + SubagentStop hooks.

**15. No duplicate / double-firing hook registration**
G-Forge hooks must be registered in exactly ONE place — `.claude/settings.json` — with one entry per script per event. A hook registered twice fires twice (the context-depth counter double-increments, the commit gate runs twice, the journal gets double entries). Check both ways it can happen:
- Read `.claude/settings.json`. For each G-Forge script (`check-commit.sh`, `post-commit-cleanup.sh`, `observe.sh`, `agent-lifecycle.sh`, `pre-compact.sh`, `session-start.sh`, `workflow-checkpoint.sh`), count the entries referencing it under the same event key. More than one is a duplicate.
- Read the plugin manifest `hooks/hooks.json` from the plugin cache (Glob `~/.claude/plugins/cache/g-forge/g-forge/*/hooks/hooks.json`). Its `hooks` object must be empty `{}`. If it registers any hook that is ALSO in `.claude/settings.json`, that hook double-fires — the manifest fires it globally in every session AND the project fires it.
- Pass: ✓ No duplicate hook registration (settings.json is the single registrar)
- Fail (in-settings duplicate): ✗ [script] registered [N]× under [Event] in settings.json — will double-fire
  → Run `/g-update` to de-duplicate, or delete the extra entr(y/ies) from `.claude/settings.json`.
- Fail (manifest + project): ✗ [script] registered by BOTH the plugin manifest and settings.json — double-fires every session
  → Update the plugin (`/g-update`, or reinstall) so the manifest registers no hooks; `.claude/settings.json` is the single registrar.

**16. Installed-copy drift**
For each of the 7 canonical hook scripts (`check-commit.sh`, `workflow-checkpoint.sh`, `post-commit-cleanup.sh`, `pre-compact.sh`, `session-start.sh`, `observe.sh`, `agent-lifecycle.sh`) in `hooks/` (plugin source), hash-compare against its installed counterpart in `.claude/hooks/` using the `hash_file` cascade (SKILL.md Check 16, canonical copy).
- Pass (per file): installed copy exists AND its hash matches the canonical source in `hooks/`.
- Pass (overall): ✓ Installed hooks match plugin source (no drift)
- Fail (per file): ✗ [script] installed copy differs from plugin source (drift)
  → Run `/g-update` to re-sync hooks/ into .claude/hooks/.

Related canonical-vs-installed surfaces (why each rule is shaped this way: `check-16-drift.md`):

- `hooks/lib/` drift. Enumerate the canonical lib set from disk (`ls [plugin-root]/hooks/lib/*.sh`), never from a written list. For each `.sh` in the source `hooks/lib/`, check for an installed counterpart at `.claude/hooks/lib/<file>` and hash-compare.
  - Fail (missing): ✗ hooks/lib/[file] missing from installed copy (drift)
    → Run `/g-update` to re-sync hooks/ into .claude/hooks/.
  - Fail (hash mismatch, file present): ✗ hooks/lib/[file] installed copy differs from plugin source (drift)
    → Run `/g-update` to re-sync hooks/ into .claude/hooks/.

- Sourced-but-uninstalled libs (install-list completeness). Grep the **installed** top-level hooks for `lib/<name>.sh` source references (`grep -oHE 'lib/[a-z0-9-]+\.sh' .claude/hooks/*.sh | sort -u` — the `-H` is load-bearing); split each hit on the **last** `:`, prefix the right-hand field with `.claude/hooks/` verbatim, and assert that file exists. Zero references → report `⚠ install-list completeness — inconclusive (no installed hooks found to derive from)`, never Pass. One line per missing lib, naming the first referencing hook and `(+N more)`.
  - Pass: every lib referenced by an installed hook is present in `.claude/hooks/lib/`.
  - Fail: ✗ hooks/lib/[file] sourced by [hook] but not installed (install list incomplete)
    → Run `/g-update` to re-sync hooks/ into .claude/hooks/. If `/g-update` does not resolve it, the skill's install list is short — report it as a plugin defect rather than a project defect.

- Native `pre-commit` git hook drift. Resolve the installed git hooks directory with `git rev-parse --git-path hooks` and look for `<hooks-dir>/pre-commit`; check its first few lines for the literal marker `G-Forge commit gate` before comparing.
  - Pass: `<hooks-dir>/pre-commit` exists, carries the `G-Forge commit gate` marker, AND its hash matches the canonical `hooks/pre-commit`.
  - Fail (missing): ✗ pre-commit missing from installed git hooks dir (drift)
    → Run `/g-update` to re-sync hooks/pre-commit into <hooks-dir>/.
  - Fail (G-Forge pre-commit present but hash differs): ✗ pre-commit installed copy differs from plugin source (drift)
    → Run `/g-update` to re-sync hooks/pre-commit into <hooks-dir>/.
  - Advisory (marker absent — foreign pre-commit): ⚠ foreign pre-commit present (gate not installed — advisory, run /g-update to see options)

  `<hooks-dir>/lib/*.sh` drift — only when a G-Forge-managed `pre-commit` is present (never the foreign case): enumerate the canonical set from disk (`ls [plugin-root]/hooks/lib/*.sh`) and hash-compare each against `<hooks-dir>/lib/<file>`.
  - Fail (missing): ✗ <hooks-dir>/lib/[file] missing — native pre-commit will deny every commit with "could not load" (drift)
    → Run `/g-update` to re-sync hooks/lib/ into <hooks-dir>/lib/.
  - Fail (hash mismatch, file present): ✗ <hooks-dir>/lib/[file] installed copy differs from plugin source (drift)
    → Run `/g-update` to re-sync hooks/lib/ into <hooks-dir>/lib/.

- `g-rules` section-file drift. For each of the 10 canonical g-rules section files in `rules/g-rules/` — `A-session.md`, `B-workflow.md`, `C-agent-discipline.md`, `D-code-quality.md`, `E-architecture-gate.md`, `F-design-patterns.md`, `G-documentation.md`, `H-testing.md`, `I-project-tracking.md`, `J-memory.md` — hash-compare against its installed counterpart using the same flat-rename mapping CLAUDE.md's own `@` references use: `rules/g-rules/X-name.md` (source) → `.claude/rules/g-rules-X-name.md` (installed).
  - Fail (missing): ✗ g-rules-[X-name].md missing from installed copy (drift)
    → Run `/g-update` to re-sync rules/g-rules/ into .claude/rules/.
  - Fail (hash mismatch, file present): ✗ g-rules-[X-name].md installed copy differs from plugin source (drift)
    → Run `/g-update` to re-sync rules/g-rules/ into .claude/rules/.

- Installed-agents drift. For each file in `.claude/agents/`, classify its provenance first (three classes — full reasoning in `check-16-drift.md`), then apply that class's rule:
  1. Profile-copied (byte-canonical source under `profiles/<stack>/agents/<name>.md`) — hash-compare.
     - Pass: ✓ [agent].md matches profile source (no drift)
     - Fail (hash mismatch): ✗ [agent].md installed copy differs from profile source (drift)
       → Run `/g-specialize` to re-sync the architect agent from its profile source.
     - Fail (canonical source missing): ✗ [agent].md has no matching profile source — cannot verify (drift)
       → Run `/g-update` to check for a renamed or removed profile.
  2. Template-instantiated (generated from `templates/stack-implementer.md`; no byte-canonical source) — advisory-only, never Fail:
     - Advisory: ⚠ [agent].md is template-instantiated (no canonical source — not checked for drift)
  3. Project-local `*-dev.md` — excluded entirely (zero drift output); skip before classification even runs.

- Installed architecture-skill drift. Enumerate installed instances from disk (`ls -d .claude/skills/architecture-*/`), derive `<stack>` from the directory name, strip the installed file's frontmatter (everything through the closing `---` line), and hash-compare the body against `[plugin-root]/profiles/<stack>/rules/architecture.md`.
  - Pass (overall): ✓ Installed architecture-skill copies match profile source (no drift)
  - Fail (hash mismatch): ✗ .claude/skills/architecture-[stack]/SKILL.md installed copy differs from profile source (drift)
    → Run `/g-update` to realign it from profiles/[stack]/rules/architecture.md.
  - Advisory (canonical source missing): ⚠ .claude/skills/architecture-[stack]/SKILL.md has no matching profile source (no canonical source — not checked for drift)
    → Run `/g-update` to check for a renamed or removed profile.
  - No instances: report `ℹ no installed architecture skills — check skipped` (zero instances is a valid state, not drift). No closing `---` fence: `✗ .claude/skills/architecture-<stack>/SKILL.md malformed (no frontmatter fence) — cannot verify (drift)` → re-run `/g-specialize`.

**17. CLAUDE.md architecture rules format** (advisory)
Read `CLAUDE.md`. For each `<!-- G-Forge [stack] Architecture Rules` block, count the non-empty lines between the opening and closing markers. If any block has more than 3 lines of content, it is using the legacy inline format.
- Pass: ✓ CLAUDE.md architecture rules compact (@reference format)
- Advisory: ⚠ CLAUDE.md has [N] inline architecture block(s) — legacy format
  → Run `/g-update` to extract inline rules to `.claude/rules/` and compact CLAUDE.md automatically.

**18. CLAUDE.md total size** (advisory)
Count the total lines in `CLAUDE.md`.
- Pass (≤150 lines): ✓ CLAUDE.md compact ([N] lines)
- Advisory (>150 lines): ⚠ CLAUDE.md is [N] lines — may contain inline rules content
  → Run `/g-update` to migrate inline rules to `.claude/rules/` files.

**19. No leftover legacy `g-team` plugin** (advisory)
G-Forge was formerly named `g-team`; the rename created a new plugin rather than replacing the old one, so a leftover `g-team` install duplicates every `/g-*` command. Check `~/.claude/plugins/cache/g-team` and any `"g-team"` entry in `~/.claude/plugins/config.json`.
- Pass (absent): ✓ No legacy g-team plugin — commands are g-forge only
- Advisory (present): ⚠ Legacy g-team plugin still installed — every /g-* command is duplicated
  → Remove it via `/plugin` → Installed → g-team → Uninstall (then re-run `/g-update`).

**20. `.gitignore` vets G-Forge artifacts** (advisory)
Read `.gitignore` and verify the ignore/tracked-by-design boundary (the two path lists and the over-broad-pattern warning: `check-rationale.md`).
- Pass: ✓ .gitignore vets G-Forge artifacts (runtime ignored, project record tracked)
- Advisory (missing): ⚠ No .gitignore — runtime artifacts (sentinels, journal, agent-output) may be committed
  → Run `/g-init` (Step 5a) to write the project `.gitignore`.
- Advisory (runtime not ignored): ⚠ .gitignore does not ignore [artifact] — it may be committed
  → Add the missing runtime-artifact pattern(s) (see `/g-init` Step 5a).
- Advisory (tracked path ignored): ⚠ .gitignore ignores [path] — project record won't be committed
  → Remove or scope the over-broad pattern so the `g-docs/` project record stays tracked.

**21. No stray G-Forge documents** (advisory)
Inverted scan (rationale and the generic-name content filter: `check-rationale.md`). Look for:
- `ROADMAP.md`, `todo.md`, `todo-done.md`, or `project_brief.md` at the **project root** (canonical home is `g-docs/`).
- A `milestones/` directory at the **project root** (canonical home is `g-docs/milestones/`).
- A directory sharing a name with a top-level `g-docs/` subdirectory, found anywhere **outside** `g-docs/` and `g-wiki/`, **whose own contents look like G-Forge documents** — at least one `.md` file and no source-code file directly inside it.
```bash
# strays at root
for f in ROADMAP.md todo.md todo-done.md project_brief.md; do [ -f "$f" ] && echo "stray: $f"; done
[ -d milestones ] && echo "stray: milestones/"
# canonical dir-name set = whatever already lives directly under g-docs/ in this project
# (inverted check: any of those names found outside g-docs/ or g-wiki/ is a candidate, not a fixed allowlist)
# a candidate is only a stray if its own contents look like docs: >=1 .md file, no source-code file
for canon in $(find g-docs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n1 basename); do
  find . -type d -name "$canon" \
    -not -path './g-docs*' -not -path './g-wiki*' -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null | while read -r d; do
    has_md=$(find "$d" -maxdepth 1 -type f -name '*.md' 2>/dev/null | head -1)
    has_src=$(find "$d" -maxdepth 1 -type f \( -name '*.js' -o -name '*.ts' -o -name '*.tsx' -o -name '*.jsx' -o -name '*.py' -o -name '*.sh' -o -name '*.rs' -o -name '*.go' -o -name '*.java' -o -name '*.vue' \) 2>/dev/null | head -1)
    [ -n "$has_md" ] && [ -z "$has_src" ] && echo "$d"
  done
done
```
- Pass (none found): ✓ No stray G-Forge documents — all tracking lives under g-docs/
- Advisory (strays found): ⚠ [N] stray G-Forge document(s) outside g-docs/: [list]
  → Move each into `g-docs/` preserving history, then re-run /g-doctor:
    `git mv ROADMAP.md g-docs/ROADMAP.md` · `git mv milestones g-docs/milestones` (etc.)
  → Offer to run the moves now. After moving, update any references with `/g-update`, and confirm nothing still points at the old root path.

**22. Roundtable security** (advisory — only when a Roundtable is bound)
Runs only if `.claude/roundtable` exists (framing: `check-rationale.md`).
```bash
[ -f .claude/roundtable ] || echo "no Roundtable bound — skip"
# (a) bind record + credentials must be gitignored, never committed
git check-ignore -q .claude/roundtable 2>/dev/null && echo "ignored ✓" || echo "TRACKED ✗"
git ls-files --error-unmatch .claude/roundtable >/dev/null 2>&1 && echo "COMMITTED ✗"
# (b) a token-looking line must never be in the bind record (token belongs in env)
grep -qiE '^(token|secret|password|api[_-]?key)=' .claude/roundtable 2>/dev/null && echo "SECRET-IN-BIND ✗"
```
- Pass: ✓ Roundtable security — bind record gitignored, no credential in it (confirm the Doc is link-restricted, not public)
- Advisory (bind record tracked/committed): ⚠ `.claude/roundtable` is tracked — the bound surface ref (and any creds near it) could be pushed
  → Add `.claude/` to `.gitignore` (it should already be — see Check 20) and `git rm --cached .claude/roundtable`.
- Advisory (secret in bind record): 🔴 A credential is stored in `.claude/roundtable` — move it to an environment variable and remove the line. Never commit a token.
- Advisory (always, reminder): the bound Doc must be **link-restricted, never public** — `/g-roundtable` enforces this at bind, but confirm sharing hasn't been widened since.

**23. Plugin version lag** (advisory)
Resolve the same version triple `/g-update`'s Step 0 staleness preflight resolves, read-only — never write anything and never run `/g-update` itself; diagnose and point at the right direction:
- **GitHub latest** — fetch it, same idiom `/g-update` Step 0 already uses:
  ```bash
  curl -sf --max-time 10 https://raw.githubusercontent.com/onlygian/G-Forge/main/.claude-plugin/plugin.json | grep '"version"'
  ```
  If `curl` fails (offline), mark this leg `unreachable` and degrade gracefully — do not fail the check, compare only the legs you have.
- **Cache version** — Glob `~/.claude/plugins/cache/g-forge/g-forge/` for subdirectories, pick the highest semver, read its `.claude-plugin/plugin.json`, extract `version`. If nothing is found, there is no cache to compare — treat as `unknown`.
- **Project-installed version** — if this project is self-hosting the plugin (root `.claude-plugin/plugin.json` exists and its `name` is `g-forge`), read its `version` field directly; otherwise report `unknown` (no version stamp is recorded in installed copies).
- **Compare — source every ordering from `hooks/lib/semver-compare.sh`'s `gf_semver_compare`, never hand-roll version ordering.**
  ```bash
  . hooks/lib/semver-compare.sh   # or [plugin-root]/hooks/lib/semver-compare.sh
  gf_semver_compare "$cache_version" "$latest_version"
  ```
  `gf_semver_compare A B` prints `-1`/`0`/`1` (A older/equal/newer than B) to stdout. On malformed input it prints `0` and returns exit status 1 — treat that as "cannot compare" for that pair, not as "equal", and report it as such rather than asserting alignment.
- Pass (all resolvable legs aligned, i.e. every comparison returns `0`): ✓ Plugin versions aligned — cache v[cache], installed v[installed-or-unknown]
- Advisory (cache < GitHub latest): ⚠ Plugin cache is stale — v[cache] installed, v[latest] available
  → Update the cache first: `/plugins` → Installed → g-forge → Update now — then run `/g-update` to sync this project.
- Advisory (installed < cache): ⚠ Project files are behind the plugin cache — v[installed-or-unknown] installed, v[cache] in cache
  → Run `/g-update` to realign this project's G-Forge-managed files.
- Info (cache > GitHub latest): ℹ Plugin cache (v[cache]) is ahead of the GitHub latest release (v[latest]) — expected on the plugin source repo when work is committed but not yet released; not actionable.
- Info (installed > cache): ℹ Project files (v[installed]) are ahead of the plugin cache (v[cache]) — expected on the plugin source repo when the working tree's version is bumped before the cache updates; not actionable.
- Advisory (GitHub unreachable): ⚠ Could not reach GitHub — staleness cannot be ruled out. Comparing cache (v[cache]) vs. installed (v[installed-or-unknown]) only.
- Advisory (a comparison returned "cannot compare"): ⚠ [leg] version string is malformed — cannot compare against [other leg]

**25. Integration-tier guard file** (advisory)
Check that the **governing** `integration-tier` file exists and contains exactly one of `full`, `balanced`, or `light` (single line, whitespace-trimmed) — governing per the ADR-005 local-else-primary resolution; worktree caveat and the do-not-write-a-per-worktree-tier-file rule: `check-rationale.md`.
- Pass: ✓ integration tier set: [value] ([local | primary])
- Fail (neither resolves): ⚠ governing `integration-tier` missing — all hooks (commit gate included) are silently inert
  → Run `/g-tier full` (or re-run `/g-init`) **from the primary tree** to restore the tier file.
- Fail (unrecognized value): ⚠ governing `integration-tier` contains an unrecognized value: [value]
  → Run `/g-tier` to write one of `full`, `balanced`, `light`.

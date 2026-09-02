# Check 16 — installed-copy drift: rationale essays

Load this file when Check 16 reports FAIL or an inconclusive ⚠ and the developer asks
why, or when editing the check. The mechanics live in `scripts/checks.sh`; the
one-line summaries live in SKILL.md Check 16. Nothing here changes a verdict.

## Why the canonical copy matters at all

The plugin source (`hooks/`) is the canonical copy of each hook script; `/g-init` and
`/g-update` copy it into `.claude/hooks/`. If the installed copy drifts from the
canonical source (e.g. a manual edit, or an update that didn't get re-synced), the
project silently runs stale hook logic.

## Why `hooks/lib/` is enumerated from disk, never from a written list

**Enumerate the canonical lib set from disk — `ls [plugin-root]/hooks/lib/*.sh` —
never from a list written in the skill.** A hardcoded enumeration cannot detect a lib
that is missing *from the enumeration*, which is precisely how `/g-init` shipped a
4-of-6 install through this check in v2.4.0: two libs were sourced by the hooks,
absent from every install list, and every reader of those lists — including this
check — iterated the short list and reported clean.

## Sourced-but-uninstalled libs — the residual hole and its closure

The drift pass compares *source* against *installed*, so it stays silent when a lib
is missing from **both** — the residual hole it structurally cannot see. (That was
not the v2.4.0 shape: there, both libs were present in source and missing only from
the install lists, which the derives-from-disk drift pass now catches on its own.)
Close it by deriving the requirement from the code that actually uses it: grep the
**installed** top-level hooks for `lib/<name>.sh` source references
(`grep -oHE 'lib/[a-z0-9-]+\.sh' .claude/hooks/*.sh | sort -u`).

**The `-H` is load-bearing and must not be dropped**: it forces the `<hook-path>:`
prefix onto every hit even when the glob matches exactly one file — reachable
precisely on a broken install — which is what makes the two-field contract hold for
every input. Each hit reads `<hook-path>:lib/<name>.sh`; split on the **last** `:`
to get the two fields. The right-hand field already ends in `.sh`; prefix it with
`.claude/hooks/` verbatim and assert that file exists. Do not re-append an
extension, and do not pass the whole unsplit hit as a path. The left-hand field
binds the `[hook]` name in the failure line. Grep the installed copies, not the
plugin source — a consumer's install is what breaks, and the reference set is what
that install will actually execute.

## Why zero references is inconclusive — never Pass

An absent or empty `.claude/hooks/` leaves the glob unexpanded and the reference set
empty, which makes "every referenced lib is installed" vacuously true and would emit
✓ on the most broken install possible. Report
`⚠ install-list completeness — inconclusive (no installed hooks found to derive from)`
and let the hook-presence checks (1–3, 11–14, each carrying an explicit missing-file
Fail branch) and Check 16's own top-level hook-drift pass carry the failure — those
are the checks that actually go red on an empty hooks directory. (Check 15 is *not*
one of them despite sitting next door: it reads `.claude/settings.json` and
`hooks.json` for duplicate registrations and has no file-existence logic at all, so
an empty hooks directory does not make it fail.) An inconclusive sub-check leaves
Check 16's own ✓/✗ untouched — it neither passes nor fails the parent, matching the
⚠ branches already in the check.

Report **one line per missing lib**, not one per reference — a lib sourced by all
seven hooks would otherwise emit the same defect seven times. Name the first
referencing hook and, when there are others, append `(+N more)`. If `/g-update`
does not resolve a missing lib, the skill's install list is short — report it as a
plugin defect rather than a project defect.

## Native pre-commit — the foreign-copy precedent

Resolve the installed git hooks directory with `git rev-parse --git-path hooks` (do
not assume `.git/hooks` — it can be relocated, e.g. worktrees). Before comparing,
check whether the occupant is a G-Forge-managed pre-commit: read its first few lines
for the literal marker `G-Forge commit gate`. A marker-less, foreign pre-commit is
advisory, not a failure — the /g-init·/g-update clobber guard preserves it rather
than overwriting it, so its presence is a deliberate state, and there is no
comparable canonical copy to hash against. The `<hooks-dir>/lib/*.sh` drift pass
runs only when a G-Forge-managed pre-commit is present (Pass and hash-differs
cases, never the foreign case), because those are the libs it sources from its own
directory at runtime — a missing one makes the native pre-commit deny every commit
with "could not load". The lib set there is enumerated from disk too, same
derive-from-disk rule as `.claude/hooks/lib/`.

## Why installed agents get three provenance classes, not one rule

`.claude/agents/` mixes three provenance classes, and agents differ from
hooks/lib/rules in that not every installed agent has a byte-canonical source:

1. **Profile-copied** agents (e.g. `claude-plugin-architect.md`) — a byte-canonical
   source exists under `profiles/<stack>/agents/<name>.md`, installed verbatim by
   `/g-specialize`. Hash-compare; drift is a Fail. A profile-copied agent whose
   canonical source has vanished (the profile that installed it was renamed or
   removed upstream) is also a Fail — it cannot be verified.
2. **Template-instantiated** agents (e.g. `claude-plugin-implementer.md`) —
   generated per-project by `/g-specialize` from `templates/stack-implementer.md`
   with per-stack substitutions ({{IMPLEMENTER_NAME}}, {{ARCHITECT_NAME}},
   {{STACK_LABEL}}, etc.); no byte-canonical per-stack source exists to hash
   against. This class is advisory-only and must never Fail — it mirrors the
   foreign-pre-commit precedent above, where the absence of a comparable canonical
   copy rules out a hash-based verdict.
3. **Project-local** agents matching `*-dev.md` (e.g. `g-forge-dev.md`) are never
   shipped by the plugin and are excluded entirely (zero drift output) — neither
   Pass, Fail, nor Advisory; skip them before classification even runs.

## Installed architecture skills

`/g-specialize` writes `.claude/skills/architecture-[stack]/SKILL.md` per
specialized stack — a frontmatter block (`name: architecture-[stack]`,
`description: ...`) followed by the full unmodified content of
`profiles/[stack]/rules/architecture.md` as the body (`skills/g-specialize/SKILL.md`
"Also after writing each agent file" step). Enumerate installed instances from disk
— `ls -d .claude/skills/architecture-*/` — never from a hardcoded stack list;
derive `<stack>` from the directory name, strip the installed file's frontmatter
(everything through the closing `---` line) to isolate the body, and hash-compare
the body against `[plugin-root]/profiles/<stack>/rules/architecture.md`. Zero
instances is a valid state, not drift (`ℹ no installed architecture skills — check
skipped`). A file with no closing `---` fence must not be hash-compared as a
mis-stripped body — it is flagged malformed instead.

# Milestone close-out choreography — retro, swarm, patterns, wiki, doctor

Load at Step 6 on a full milestone completion, after the core's `## Scope`
checklist reconciliation has marked every item `[x]` and set the milestone to
`✅ Complete`. Follow this file exactly — starting with the version-bump prompt
below — the ordering constraints here are load-bearing.

## Report lines (byte-identical closed set)
- Full completion: `✓ Milestone [ID — Name] closed out`
- Partial: `✓ [N] milestone tasks checked off — [M] remaining`
- Status key: ⬜ Not started · 🔄 In progress · ✅ Complete — completed
  milestones stay in place under `## Milestones` marked `✅ Complete`; there is
  no separate `## Done` section, they stay as history where they are.

## Version bump prompt
Check the milestone entry in `g-docs/ROADMAP.md` for a `**Version:**` field. If
present, use that as the target. If absent, detect the current version from (in
order): `.claude-plugin/plugin.json`, `package.json`, `pyproject.toml`,
`Cargo.toml`, and suggest a bump based on the milestone's nature (features →
minor, fixes → patch, breaking → major). Tell the developer:

```
✓ Milestone closed — version bump recommended
  Target version:  [from g-docs/ROADMAP.md Version field, or suggested]
  Run /g-update after bumping to sync project files.
```

Do not bump the version automatically — the developer decides and commits it
separately.

## Auto-retro
Immediately run `/g-retro` — use Glob to find `skills/g-retro/SKILL.md` inside
`~/.claude/plugins/cache/g-forge/g-forge/` and read it, then follow its
instructions. Use the milestone name as the topic slug (e.g.
`M3-auth-refactor`). Do not wait for the developer to trigger it.

## Milestone close swarm
Once the retro is written, dispatch the following concurrently — they are
read-only analysis and can run in parallel:
- `/g-telemetry` — refreshes reliability metrics now that the milestone is in
  the corpus. Use Glob to find `skills/g-telemetry/SKILL.md` and follow its
  instructions.
- `/g-align` — brief-deviation check now that a milestone has closed: confirms
  the project is still serving `g-docs/project_brief.md` (goals, non-goals,
  MVP, tech decisions) rather than drifting. Use Glob to find
  `skills/g-align/SKILL.md` and follow its instructions. Advisory — surfaces
  ALIGNED or DRIFTING with a recommendation; never blocks the close-out. Skip
  silently if `g-docs/project_brief.md` does not exist.
- **ADR prompt** — ask the developer once: "Were any significant architectural
  decisions made during this milestone that should be recorded as an ADR?
  (e.g. a new pattern adopted, a library chosen, a structural constraint
  introduced) — yes/no." If yes, run `/g-adr`. If no, continue.

## Pattern mining (after the swarm, not part of it)
Once the close swarm above has finished, run `/g-patterns` — use Glob to find
`skills/g-patterns/SKILL.md` and follow its instructions. It mines the retro
just written alongside previous retros. Unlike the swarm members, it is not
read-only and not safe to run concurrently with them: it writes
`g-docs/patterns/latest.md` on every run, it may append a bullet to
`g-docs/ROADMAP.md`'s `## Active Session` block in a MINE pass and **removes
that same bullet** at RESOLVE close-out — either edit would race the handoff
`/g-retro` just wrote if the two ran in parallel — and it pauses for developer
input at its triage step. In a RESOLVE pass (entered when an earlier session
left a PENDING report) it additionally **edits the fix target itself** — a
rule, profile, agent, skill, or hook file, plus the mirrored `.claude/` copy
when run in a plugin-source checkout — renames `g-docs/patterns/latest.md` to
its resolution date, may append to `g-docs/patterns-deferred.md`, and may
append to `CHANGELOG.md` under an existing `## [Unreleased]` when an applied
fix lands in shipped source. Running it after the swarm lets the retro's
handoff settle first and lets its triage prompt stand alone.

**Ordering against the version bump:** the bump prompt above is presented
before this step, so a RESOLVE pass reached here can append an `[Unreleased]`
entry after the developer has been told to cut the release. When both fire in
one close-out, cut the release section only after this step returns, so a rule
change applied at close is not stranded under `[Unreleased]` while its own
release section is being written.

## Wiki refresh (end-of-milestone task)
After the close swarm, run `/g-wiki` to update the human-facing project wiki
(`g-wiki/`) for the milestone that just shipped — use Glob to find
`skills/g-wiki/SKILL.md` and follow its instructions (incremental scope:
document what this milestone built and reconcile existing pages against the
code). The wiki is committed project content; refreshing it at each milestone
close is what stops it going stale. If the developer would rather defer, note
`Refresh g-wiki for [milestone]` as a pending task in `g-docs/todo.md` instead
of running it now.

## Every-other-milestone health check
Read `.claude/milestone-count` if it exists (contains an integer, default 0 if
absent). Increment by 1. If the result is odd, run `/g-doctor` after the close
swarm — use Glob to find `skills/g-doctor/SKILL.md` inside
`~/.claude/plugins/cache/g-forge/g-forge/` and read it, then follow its
instructions. Write the new count back to `.claude/milestone-count`.

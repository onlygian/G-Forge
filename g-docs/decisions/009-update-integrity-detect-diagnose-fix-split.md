# ADR-009: Split update integrity into detect / diagnose / fix contracts

**Date:** 2026-07-24
**Status:** Accepted (shipped v2.4.0, 2026-07-23, work commit `e3d9d71`)
**Reversibility:** two-way door (reversible)
**Context:** G-Forge plugin — the consumer update path (install / cache / project realign)

## Context

Live consumer incident (2026-07-23, `onlygian/G-Cash`, first post-v2.3.0 downstream update): `/g-update` ran before the manual `/plugins` marketplace update, so the plugin cache still held 2.2.1 and the skill "realigned" the project with old files while presenting as an update. The same class appeared on the G-Forge dev repo itself: `workflow-checkpoint.sh` printed "update available: 2.3.0 → 2.2.1" — a backwards advisory from a direction-blind check. Neither failure corrupts, but both misrepresent state on the one path every consumer walks at every release.

## Decision

Three verbs, three owners, one writer. **Detect** = `workflow-checkpoint.sh` (fires every prompt; direction-aware semver compare; nudges only when the cache is genuinely newer than installed). **Diagnose** = `/g-doctor` (sole diagnostic surface, read-only; Check 23 resolves the installed / cache / latest triple and recommends the right vector — `/plugins` when the cache lags latest, `/g-update` when installed lags the cache). **Fix** = `/g-update` (sole writer; Step-0 staleness preflight is a write-safety gate, not a diagnostic — if cache < latest it stops with zero writes and prints the three versions plus the manual `/plugins` instruction). Version ordering itself is a shared primitive: `hooks/lib/semver-compare.sh` is the sole ordering contract — one implementation, three consumers, never hand-rolled compares per site.

## Alternatives considered

| Option | Why rejected |
|--------|-------------|
| Spot-fix the direction bug with per-site hand-rolled compares | Treats the symptom, preserves the disease: three sites hand-rolling version ordering is exactly the split-brain shape that produced the backwards nudge; any future consumer re-diverges |
| Auto-update the plugin cache from `/g-update` | Cache is owned by Claude Code `/plugins`, not G-Forge — no reliable programmatic update path; writing into another tool's cache risks state G-Forge cannot repair |
| Scheduled / self-firing staleness check skill | Per-prompt hook already covers detection at zero marginal cost; violates the "triggerable, never autonomous" posture; second cadence to keep consistent |
| Keep diagnostics duplicated across `/g-update` and `/g-doctor` | Two diagnostic surfaces drift independently; no grep-provable single owner; every future check written twice and able to disagree |
| Hook-level hard gate on the write (commit-gate symmetry) | Wrong hook class for the job: staleness needs network triple-resolution and an explicit offline-degrade judgment that a binary per-prompt exit-2 gate cannot express; skill-internal preflight keeps the degrade path explicit |
| Pin the expected cache version in the installed project | Adds a fourth version source to keep consistent, breaks self-host mode (working tree *is* the source), still needs the same triple resolution — more state, no added safety |

## Consequences

**Easier:** Every version-order question has one answer (`gf_semver_compare`, tested once, consumed by hook + doctor + update). Diagnosis has one address (Check 23, direction-aware, recommends the correct vector). The highest-traffic consumer path can no longer silently realign from a stale cache — a stale-cache run provably writes zero files. M41 release machinery extends the existing diagnostic surface instead of inventing one. Ownership is grep-provable: no check exists in both skills.

**Harder / constrained:** When the cache lags, consumers have a mandatory two-step (manual `/plugins` update, then `/g-update`) — deliberate friction. Any new consumer of version ordering must source the lib; a hand-rolled compare anywhere is an architecture violation reviewers must police. `/g-update` cannot grow diagnostic features; `/g-doctor` cannot grow write features. The lib must stay side-effect-free at source time.

**Follow-up decisions:** ~~Retire or re-route the legacy `agents/project-manager.md:21` direction-blind version check (queued backlog rider).~~ *(Done 2026-08-11 back-stamp — `agents/project-manager.md:21` now forbids the version check and defers to `workflow-checkpoint.sh` as the sole update-detect surface, citing this ADR.)* M41: whether release-cut machinery extends the Check-23 family or opens a new range. ~~Decide whether `workflow-checkpoint.sh:414`'s `sort -V` cache-dir selection must also route through the lib.~~ *(Done — cache-dir selection routes through `gf_semver_compare` (`hooks/workflow-checkpoint.sh:436`); `sort -V` survives only as the lib-failed-to-source fallback at `:461`.)* Whether the offline-degrade advisory needs escalation after repeated unreachable runs.

**Risks:** Latest-version resolution is network-dependent; offline runs degrade to cache-vs-installed only and a stale cache stays invisible until connectivity returns. The Step-0 zero-writes stop is skill-instruction enforcement, not a mechanical hook — no backstop if the skill text is misread or degraded. A corrupted or multi-version cache directory could misreport the cache leg of the triple. **Semver is a knowingly incomplete staleness signal on the dev repo** (deliberate deferred bumps make version-equal ≠ content-equal); safety there rests on the separate installed-copy drift check — the combined guarantee spans two checks and is documented only here. **No journal/telemetry event fires on preflight stops**, so how often the guard fires in the field is unmeasurable and the "small, high impact" sequencing claim cannot be verified later.

## Rejected Alternatives

| Alternative | Deciding factor |
|-------------|-----------------|
| Per-site spot-fix, hand-rolled compares | The bug *was* the hand-rolling — three implementations guarantee recurrence |
| Auto-update cache from `/g-update` | Cache ownership: `/plugins` owns it; G-Forge cannot own a write it cannot repair |
| Scheduled / self-firing check skill | Per-prompt hook gives sufficient cadence free; no autonomous surfaces |
| Duplicated diagnostics | Grep-provable single ownership was the milestone's done condition; duplication is the drift vector |
| Hook-level hard gate on the write | Network resolution + offline-degrade judgment don't fit a binary per-prompt hook contract |
| Version pinning in the installed project | Fourth version source; breaks self-host mode; zero added safety |

## Assumptions That Held

- Latest-available version resolvable from the marketplace manifest / source repo — **medium fragility**: network-dependent; the degrade path is loud, but while offline the exact failure this ADR closes is undetectable. Assumes the GitHub `plugin.json` stays the authoritative latest signal.
- Semver ordering is a sufficient staleness signal — **low-medium**: holds while both manifests are bump-disciplined (G-RULES §D); the dev repo's deferred bumps are the known exception, covered by the drift check (see Risks).
- Per-prompt hook firing is sufficient detection cadence — **low**: a prompt always precedes an update action in practice; doctor and the preflight backstop it.
- ADR-007 sole-source model holds (SKILL.md only, no shims) — **low**: structural, enforced by architecture rules and `/g-skill-validate`.
- Hotfix-suffix grammar (`2.3.3a`) is the only non-numeric version form the lib must order — **low**: repo-owned convention; an unrecognized prerelease scheme falls into the safe "cannot compare / no action" path rather than misordering.

## Constraints That Drove This Decision

- **External cache ownership** — `/plugins` owns the cache; no reliable programmatic update path. This alone eliminates self-healing and forces the stop-and-instruct preflight shape.
- **Offline must fail toward today's behavior, loudly** — latest-unreachable degrades to cache-vs-installed with an explicit advisory; a network failure never blocks realign. Ruled out any hard gate requiring the full triple.
- **Highest-traffic path** — every consumer walks it at every release; misleading state here scales with adoption. Justified sequencing M46 ahead of M41 and the minor (contract) bump.
- **Non-corrupting, trust-damaging failure class** — no data was destroyed; the harm is misrepresented state, so the remedy is honest reporting plus refusal-to-write, not rollback machinery.
- **Existing one-writer discipline** — the repo already runs single-owner contracts (single classifier, single sentinel reader, ADR-004/ADR-008); this split extends an established, grep-provable invariant style.
- **Self-host exemption** — on the plugin source repo the working tree *is* the source; the preflight applies to consumer projects, and cache-ahead-of-latest is expected (info, not warning) on the dev repo.

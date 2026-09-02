# Step 0 rationale — why the staleness preflight exists and behaves as it does

Load this when `scripts/preflight.sh` stops or degrades and the developer asks
why, or when editing Step 0. The operational branches live in SKILL.md Step 0;
this file holds the reasoning behind them.

## Why /g-update cannot update the cache itself

`/g-update` cannot update the plugin cache — the cache is owned by Claude
Code's plugin manager (`/plugins`), not by this skill. If the cache is behind
GitHub, syncing this project from it would silently install OLD files into the
project while reporting success. The preflight exists to catch that *before*
any write happens. That is why a `COMPARE: cache-stale` result means zero
writes this run, unconditionally: every later step reads from the cache, so
every later step would propagate stale content. Only `/plugins` (Installed →
g-forge → Update now) can fix the cache; the skill re-run after that is the
correct sequence.

For a standalone, read-only diagnosis of version alignment at any time (not
just before a sync) — including which side is behind and why — see `/g-doctor`
Check 23. The preflight gate only decides whether *this run* may write.

## Self-host mode and the ADR-008 dogfood gap

Self-host detection exists because the plugin's own repository dogfoods the
plugin (ADR-008). There, the working tree already IS the current source — a
plugin-cache copy may not exist at all, and if it does it describes a released
version, not the branch under development. Running the consumer-mode preflight
in the source repo produced the dogfood gap: the skill compared a released
cache against GitHub and blocked (or, worse, "realigned" the source tree from
an older release). Hence the rule: root `.claude-plugin/plugin.json` whose
`name` matches `g-forge` flips the source root from the cache to the working
tree, there is no separate cache copy that can be behind GitHub, and the
staleness preflight does not apply at all. Consumer projects (no root
`.claude-plugin/plugin.json`) are structurally unaffected — detection cannot
fire there, and the plugin-cache path is the fallback branch, unchanged.

The self-host short-circuit sits BEFORE the GitHub fetch inside the script, so
self-host runs stay offline-clean — no network call is made on that branch.

## ADR-009 — one ordering contract

Every version ordering in G-Forge is sourced from
`hooks/lib/semver-compare.sh`'s `gf_semver_compare` — the checkpoint hook,
`/g-doctor` Check 23, and this preflight all share it. Three consumers
hand-rolling their own idiom (string compare, `sort -V`, field-by-field) is
exactly the split-brain shape that produced the "backwards nudge" bug class —
a naive compare telling the user to update when the cache was actually ahead.
`gf_semver_compare A B` prints `-1`/`0`/`1` (A older/equal/newer than B).
Moving the compare into `scripts/preflight.sh` (which sources the lib
directly) closed the M46-wave1 advisory that Step 0's compare was model-inline
while Check 23 sourced the lib.

## Malformed-compare degrade reasoning

On malformed input `gf_semver_compare` prints `0` and returns exit status 1.
`0` looks like "equal", and treating it that way would silently convert
"cannot compare" into "assume the cache is current" — the one failure mode the
preflight exists to prevent. So the script maps a nonzero status to
`COMPARE: cannot-compare` and degrades exactly like the GitHub-unreachable
branch: loud notes, then continue comparing the project's installed content
against the cache only (which is all Steps 2–7 do anyway). Degrading is
acceptable because it can only miss a stale cache, never install from one that
is *known* stale; staying silent about the degradation is not.

## Why the GitHub-unreachable branch continues instead of stopping

An offline machine must still be able to realign a project against its local
cache — that is a strictly local operation and refusing it would make
/g-update useless offline. The risk (an undetected stale cache) is disclosed
loudly in the banner rather than silently accepted, and the developer is told
the only remedy (`/plugins`) for when connectivity returns.

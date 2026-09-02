# Scoring notes — measurement footnotes, example matches, and formula tuning

Two kinds of content. The `## Step 2` section below is **normative thresholds** — it fires on every run: load it whenever you score complexity (the core's Step 2 says so). Everything after it is pure rationale — load when re-deriving why a weight or constant is what it is, or when Step 4 matching feels ambiguous.

## Step 2 — measurement thresholds (normative — load on every scoring pass)

- **File count touched**: sum of distinct file paths in the plan's Scope columns — 1 (≤2 files), 2 (3–5), 3 (≥6).
- **Wave count**: 1 wave: 0; 2 waves: 1; 3+ waves: 2.
- **Layer-boundary crossings**: grep plan Scope columns for cross-layer paths (e.g. UI ↔ service, agent ↔ skill): 0 (none), 1 (one boundary), 2 (multiple).
- **New external dependency / new public surface**: 0 (none), 1 (one new skill/agent/dep), 2 (multiple or new public API).
- **Architecture rule changes**: 0 (no rule edits), 1 (G-RULES or architecture rules modified).

## Step 4 — past-failure → trigger examples

These rows are illustrative, not a closed set — the labels are examples of the judgment call.

| Past failure | Triggered if plan touches… |
|--------------|---------------------------|
| `commit-without-tests` | adds business logic or public API in a stack with no tests |
| `wave-split-across-messages` | has ≥3 waves with parallel tasks |
| `layer-boundary-skip` | crosses architecture layers (any `core ↔ ui`, `agent ↔ skill`, `service ↔ component` mix) |
| `agent-given-write-tool` | new agents in scope |
| `version-mismatch-plugin-vs-marketplace` | version bump touches one but not both manifest files |
| `stale-handoff-block` | release pass touches g-docs/ROADMAP.md |

## Formula tuning rationale (Steps 2c and 6 — encoded in `scripts/forecast-calc.sh`)

- **Per-scenario cap 22.5** (`min(score, 15) × 1.5`): no single severe pattern alone drives the result into High territory on a trivial plan.
- **Complexity multiplier ×3**: tuned so a max-complexity plan (10/10) contributes 30 percentage points before scenario evidence.
- **Token-band constants**: 4000 tokens per agent dispatch; diff size = files × 80 lines (80 lines per file is the historical median) × 4 tokens/line; review overhead = base 6000 tokens + 2000 per agent dispatched. The result is intentionally a band (`× 0.6` / `× 1.8`, rounded to the nearest 1k), not a point estimate — token consumption is governed by agent dispatch counts and diff sizes, both of which vary widely. The band is advisory — it never blocks approval.

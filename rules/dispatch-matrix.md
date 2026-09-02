# Dispatch Matrix — model & effort economy (canonical)

Installed by `/g-init` as `.claude/rules/g-dispatch-matrix.md`. Deliberately **not** @-imported — skills Read this file lazily at routing or escalation time (G-RULES §A1 names it).

**Degrade gracefully:** `model:` and `effort:` are recommendations the harness applies to dispatched subagents; a session on any model runs every skill unchanged; unknown frontmatter keys are ignored.

## The matrix

"opus" means the top tier — Opus, or any newer model above it (e.g. Fable). Opus-lane agents have no model above them: their escalation target is the human. Never `effort: max` — measured overthinking regression on top-tier families (CHANGELOG entry "Review agents `effort: max` → `effort: xhigh`").

| Agent | Role | model | effort | Escalates to |
|---|---|---|---|---|
| project-manager | orchestrator | sonnet | high | opus |
| review-orchestrator | orchestrator | sonnet | medium | opus |
| task-decomposer | planner | sonnet | high | opus |
| wave-planner | planner | sonnet | medium | opus |
| spec-writer | planner | sonnet | high | opus |
| code-lead | judgment-reviewer | opus | xhigh | — (human) |
| doc-reviewer | judgment-reviewer | opus | xhigh | — (human) |
| security-auditor | judgment-reviewer | opus | xhigh | — (human) |
| code-reviewer | judgment-reviewer | opus | xhigh | — (human) |
| architecture-enforcer | judgment-reviewer | opus | xhigh | — (human) |
| debugger | diagnostic | sonnet | high | opus |
| error-detective | diagnostic | sonnet | medium | opus |
| dependency-auditor | diagnostic | sonnet | medium | opus |
| performance-auditor | diagnostic | sonnet | medium | opus |
| feature-implementer | spec-executor | sonnet | medium | opus |
| stack implementers (templates/stack-implementer.md) | spec-executor | sonnet | medium | opus |
| refactor-executor | mechanical-worker | haiku | low | feature-implementer (sonnet) |
| test-writer | mechanical-worker | haiku | medium | sonnet |
| doc-writer | mechanical-worker | haiku | medium | sonnet |
| pr-writer | mechanical-worker | haiku | low | sonnet |

## Haiku-Executability Standard (HES) — canonical text

A task package is haiku-executable only when it passes all six items. The embedded copy in `agents/spec-writer.md` carries this list word-for-word — hard-wrapped for prose width, byte-identical after unwrapping continuation lines (`tests/test-dispatch-matrix.sh` pins the parity); this file is canonical.

1. Exact paths — every file named by exact repo-relative path; no "find the file that…".
2. Closed steps — every step is an exact edit or a closed decision procedure (enumerated cases, one rule per case, defined stop-default). Banned words: "appropriate", "as needed", "handle edge cases", "improve", "clean up".
3. Command-verifiable done — a command with expected output/exit code, a grep count, or a file-existence check.
4. Zero unstated context — self-sufficient: every interface, signature, or convention quoted in the spec, never referenced.
5. No judgment residue — every choice pre-made; the executor's only sanctioned response to ambiguity is BLOCKED.
6. Bounded scope — explicit may-touch list and not-touch boundary.

## Effort policy

Frontmatter `effort:` is each agent's default (matrix above). A skill adds ONE advisory line under `Task:` in a dispatch prompt ONLY when a stage genuinely deviates from the agent's default: `Effort: low|medium|high — [stage reason]` (advisory prose; degrades gracefully where effort control is absent).

| Stage | effort |
|---|---|
| mechanical apply | low |
| constrained procedure / synthesis | medium |
| planning / open judgment / post-failure diagnosis | high |
| gate review | xhigh |

**Telemetry-profile bounds:** defensive → judgment/diagnostic/spec-executor lanes bump one tier, mechanical lane does not bump; recovery → one-tier bump on non-mechanical lanes, mechanical lane bumps haiku→sonnet at most. A failed mechanical task escalates via the HES/`FAILED` loop, never via profile inflation.

## Escalation ladder

- **HES gate** (run by `/g-execute` before parallel dispatch and `/g-refactor` before dispatching refactor-executor; doc-writer/pr-writer exempt — non-implementation output, gate-reviewed): before dispatching any task tagged to a haiku-tier implementation executor, verify the package against the six HES items. On failure: (a) one spec-tightening round, re-check; still failing → (b) re-tag to feature-implementer (sonnet) and proceed.
- **Failure ladder:** escalate one tier after 2 fails on the same task — before attempt 3, not after (§A8 Three-Strikes); after three failed approaches, stop and escalate to the human.
- **Forbidden degrade moves:** NEVER weaken a spec, delete a constraint, or soften a done condition to pass the gate — escalating the model is the honest resolution of an open spec; degrading the spec is quality loss and forbidden.
- **Log:** `YYYY-MM-DD <task-label> tier-gate:<respecced|escalated>` appended to `.claude/tier-gate-log` (NOT `.claude/escalation-log` — that file feeds the escalation-frequency telemetry metric and must not be polluted).

## Downgrade-evidence protocol (FUTURE unlocks — not current work)

Replay ≥10 real historical dispatches from `g-docs/agent-output/` + retros at the candidate tier; unlock only on 0 missed Critical/Major (reviewers) or equivalent schedules/tags (planners) across 2 independent sessions; record the verdict as an ADR. Ranked candidates: doc-reviewer opus→sonnet, architecture-enforcer opus→sonnet, error-detective sonnet→haiku, wave-planner sonnet→haiku. code-lead / security-auditor: no downgrade path.

## Fleet-role migration note

This file is the single seam for the future local-kernel takeover (G-Forge on the G-Agent fleet): the tiers map onto fleet roles — judgment-reviewer → reviewer · orchestrator/planner → planner · spec-executor/diagnostic → builder/executor · mechanical-worker → worker. The takeover swaps the model column for fleet role ids here, without touching any skill or agent body.

## C · Agent Discipline

**HQ = command centre only.** Decomposes, directs, integrates, commits. Never does grunt work an agent could do.

**Wave model** — Classify every step: Independent / Dependent / Sequential-by-file. All independent steps launch in one message. Never split a wave across messages.

**When to spawn vs. inline**

| Situation | Action |
|-----------|--------|
| Non-trivial feature or multi-step task | `/g-plan` first |
| All agent work ready to merge | `/g-review` gate before commit |
| Open-ended search, unknown locations, >3 files | Spawn **Explore** agent |
| Self-contained implementation, inputs fully known | Spawn the matching **`<stack>-implementer`** (if `/g-specialize` installed one for the task's stack), else **`feature-implementer`** — never a bare general-purpose agent |
| Long task that would bloat main context | Spawn agent |
| Exact file:line known, <3 targeted edits | Inline |
| Needs mid-task judgment or back-and-forth | Inline — keep in HQ |
| Build / audit >2 min with clear done condition | Background agent |
| Same bug class, 3rd attempt | Stop inline. Explore agent + escalate model + different mechanism. |

**Agent prompt must include:** exact `file:line` refs for known things · scope boundary (what NOT to touch) · one specific verifiable done condition · enough WHY for judgment calls · **record/report files are written with the Write tool, never Bash heredocs** (an agent with Bash-only write ability returns content to HQ instead, or is granted Write scoped to its record path) · **no child dispatch unless the task explicitly requires it** · **the agent reads back its own report/output file at the exact dispatched path before returning DONE**, and HQ verifies the path exists before accepting the result. (Mechanism and incident history behind these clauses: `.claude/rules/references/context-poisoning.md`.)

**Out-of-scope edit recovery:** when any agent touches a file outside its stated scope, recovery is a full-file diff against git for every file it touched — never a spot-revert of the noticed line.

**Results flow:** summary + `file:line` refs back to HQ — never raw file dumps. A claim about a file's *whole* surface ("no other occurrences", "nothing else changed", "near-nil") requires a whole-file read or exhaustive grep — targeted reads support only targeted claims. A **negative, capability, or disk-state claim** ("cannot be detected", "no leftover files", "nothing else references X") is not relayed to the developer as fact until the delegate's exact command and its pasted output travel with it — an unverified claim is reported as unverified, not as confirmed. **Never declare a record lost without checking the disk first** — gitignored is not deleted; a directory listing or grep of the actual path is required before reporting anything as unrecoverable.

**Caps:** Hard limit 7 agents/task. 4 agents in one wave = warning sign, restructure first.

**Background by default** for anything >~2 min that doesn't block HQ's next move.

### Single-use agents — one approach, one attempt

**An agent is single-use. It gets one approach and one attempt. It is never continued, re-prompted, or reused for a retry.** (One carve-out: an agent stopped *externally* mid-attempt is resumed, not redeployed — see **Interrupted ≠ `FAILED`** below.) If its approach works, it returns `DONE`. If not, it does **not** thrash — it returns `FAILED` with a learnings report and is discarded. HQ owns every retry. Why: **context poisoning** — the failed exploration must die with the agent; full doctrine in `.claude/rules/references/context-poisoning.md` (read it when a retry loop engages or when tempted to re-prompt an agent).

**The failure loop (`FAILED` → learnings → fresh redeploy):**

1. A failing agent returns `RESULT: FAILED` with a `LEARNINGS:` block — the approach it tried, where and why it broke, what is now ruled out, and a recommended *different* approach. A clean contract, not a transcript.
2. HQ reads the learnings (and may dispatch `error-detective` / `debugger` on them for a different mechanism). It does **not** re-prompt the dead agent.
3. HQ deploys a **fresh** single-use agent for the same task, seeded **only** by the revised approach + distilled learnings — never the failed agent's context or output file. Hand it a clean starting point: revert the failed attempt's partial changes, or describe the working-tree state explicitly.
4. **Bound = Three-Strikes (§A8).** Each strike is a fresh agent with a *different* mechanism. Escalate the model tier before attempt 3. After three failed approaches, **stop and escalate to the human** with the full learnings trail — do not deploy a fourth.

`FAILED` (the approach didn't work — HQ analyzes and redeploys) is distinct from `BLOCKED` (an external dependency makes the task impossible to proceed — surface to the human immediately; redeploying a fresh agent won't help).

**Interrupted ≠ `FAILED`.** A dispatch killed mid-task by a session limit or platform stop — context intact, approach not refuted — is **resumed to completion**, not discarded. The single-use rule bars re-prompting *failed* agents; it does not bar resuming *interrupted* ones that never finished their one attempt.

**Budget the resume.** A delegate whose task includes a long shell run or ends in a record-write step routinely yields silently there — the common case of the carve-out. Budget one resume round-trip per dispatch; a second stall on the same run is genuinely stuck.

**HQ poisons too — offload high-stakes deliberation.** High-branching deliberation (weighing architecture options, debating a pattern, drafting an ADR) poisons HQ's own window. For a consequential decision, **offload the weighing to a throwaway subagent and promote only the finished answer** (this is what `/g-adr` does). When the decision is finalized, reset via the path §A7 already provides — finalizing a consequential ADR is a *semantic* trigger for the same reset the quantitative gate runs: auto-`/g-retro`, write the handoff, recommend a fresh session whose *first task verifies the decision against ground truth*. An airtight answer must be checked, not trusted from memory. Full rationale: `.claude/rules/references/context-poisoning.md`.

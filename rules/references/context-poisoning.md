# Context poisoning — the doctrine behind single-use agents (G-RULES §C companion)

Load trigger: read this when a retry loop engages (an agent returned `FAILED`), when tempted to re-prompt or reuse an agent, or before running high-stakes deliberation in HQ. The normative rules live in `.claude/rules/g-rules-C-agent-discipline.md`; this file holds the reasoning and incident history moved out of them (v2.6 token diet).

## Why — context poisoning

A context window conditions the next token on its *entire* contents, not just the parts that were "accepted." When an agent explores options, hits dead-ends, makes a wrong first guess, and then keeps going in the same context, that crossed-out reasoning stays on the page it is reading from. The agent then anchors on options it already rejected, hedges because conflicting half-conclusions are still in-window, and clings to a wrong first guess even after correcting it. The residue of deliberation poisons execution — and the higher-stakes the task, the more exploration it needed, so the most consequential work gets the most poison. **Single-use agents make this structurally impossible: the failed exploration dies with the agent. Nothing crosses back to HQ except the distilled learnings.** Each strike of the retry loop is a fresh agent seeded only by the prior attempts' distilled learnings — never the same context re-poked, which only poisons it further.

## The airtight-contract framing

This is the same airtight-contract discipline G-Forge already uses for *first* attempts — `spec-writer` produces a spec precise enough for a cheap executor to run without judgment calls — extended to *retries*. The learnings report is the fixed-contract value crossing the seam; thinking out loud inside a reused agent is mutating the shared object (the executor's window) in place. Keep the seam clean.

## HQ poisons too — why the ADR reset exists

The doctrine applies to HQ's own window, not just dispatched agents. High-branching deliberation is exactly the reasoning that poisons a context, and HQ runs it directly — hence the offload-and-promote rule, and the semantic reset on ADR finalization (`/g-adr`'s single-use deliberation subagent stress-tests and drafts; HQ never sees the comparison). The verification-first fresh session exists because an airtight answer's deliberation context may have gone confidently stale: the verification is the seam check; the fresh session is the clean executor.

## Mechanism and incident history behind the agent-prompt clauses

- **Write-tool-not-heredocs clause:** heredocs stall in the permission layer and trip the commit-gate multi-line walk.
- **Read-back clause:** distinct from content-edit read-back — it exists because agents returned `DONE` without ever writing the report file they were dispatched to produce.
- **No-child-dispatch clause:** an unscoped `doc-writer` child falsified a shipped CHANGELOG entry twice before this line was enforced by hand.

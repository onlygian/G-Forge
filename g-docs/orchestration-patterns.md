# G-Forge Orchestration Patterns

Four standard workflows built from G-Forge agents. Each pattern shows which agents run, in what order, and what each one receives and returns.

See also: [G-RULES.md §B–C](../G-RULES.md) for enforcement rules, and the individual SKILL.md files under `skills/`.

---

## Auto-Trigger Workflow

Plan, execute, and review fire **automatically** — you do not need to type the commands for non-trivial tasks.

After `/g-init`, two hooks are installed in `.claude/settings.json`:

**`workflow-checkpoint.sh`** (`UserPromptSubmit`) — fires on every message. Reports:
- Whether an active plan exists in `g-docs/plans/`
- The current wave number and total waves (read from the plan's Progress table)
- Whether `.claude/g-forge-approved` is set (commit gate state)

Claude reads this output and auto-triggers the correct step:

| Checkpoint output | Auto-trigger |
|---|---|
| No active plan + non-trivial task detected | `/g-plan` |
| Active plan with pending/in-progress wave | `/g-execute` |
| All waves complete, no sentinel | `/g-review` |
| `g-forge-approved` present | Commit gate open — no action needed |

**`check-commit.sh`** (`PreToolUse`) — blocks any `git commit` Bash call unless `.claude/g-forge-approved` exists. Cleared automatically by `post-commit-cleanup.sh` (`PostToolUse`) after each successful commit.

You can still invoke `/g-plan`, `/g-execute`, and `/g-review` manually at any time.

---

## Plan File Format

Approved plans are saved to `g-docs/plans/<feature-slug>.md` by `g-plan` immediately after developer approval (before execution begins).

```markdown
# Plan: [Feature Name]

> Created: [date]

## Tasks

| # | Task | Scope | Done condition |
|---|------|-------|----------------|
| 1 | [task name] | [files/area] | [verifiable condition] |

## Wave Schedule

### Wave 1
- Task 1 — [task name]
- Task 2 — [task name]

### Wave 2
- Task 3 — [task name]

## Progress

| Wave | Status | Notes |
|------|--------|-------|
| 1 | pending | |
| 2 | pending | |
```

The **Progress table** drives auto-resumption: `workflow-checkpoint.sh` reads it to find the first wave not marked `complete` and reports that as the current wave. `g-execute` uses the same table to determine the starting wave without prompting the developer (unless a wave is `in progress`, which requires confirmation).

Status values: `pending` | `in progress` | `complete`.

---

## Pattern 1 — Feature Build

**Trigger:** `/g-plan` — or auto-triggered when a non-trivial task is detected.

**When to use:** Any non-trivial feature — three or more files, a new component, a layer-boundary change, or unclear scope.

**Flow:**

```
/g-plan
  └─ task-decomposer (Sonnet)
       receives: feature request, file paths, constraints
       returns:  numbered task list with done conditions

  └─ wave-planner (Sonnet)
       receives: task list from task-decomposer
       returns:  wave schedule (Wave 1 = parallel starters, Wave N = unblocked by prior wave)

  └─ [approval gate — developer reviews and approves]

  └─ plan saved to g-docs/plans/<feature-slug>.md
       (Tasks table + Wave Schedule + Progress table, all waves set to "pending")

/g-execute   [sole executor for all wave-based dispatch]
  Wave 1 — all tasks dispatched in a SINGLE parallel message
    └─ agent per task: implement → test
         each agent: receives task, done condition, file scope, constraint
         each agent: returns summary + whether done condition is met

  [wave boundary held — Wave 2 does not start until Wave 1 complete]
  [Progress table updated: Wave 1 → "complete"]

  Wave 2 (if dependencies exist)
    └─ dependent tasks dispatched in parallel

  [BLOCKED signal on any task → stop, report, do not advance wave]

/g-review
  └─ code-lead (Opus)
       receives: diff, done conditions, branch name
       dispatches review-orchestrator →
         code-reviewer (Opus)         — in parallel
         security-auditor (Opus)      — in parallel
         performance-auditor (Sonnet) — in parallel
         architecture-enforcer (Opus) — if layer boundaries touched
       returns: MERGE READY or HOLD with fix list

  └─ on MERGE READY:
       writes .claude/g-forge-approved  (commit gate unlocked)
       runs milestone close-out (see Pattern 2)
```

**Example — adding user authentication:**

```
task-decomposer receives:
  "Add email/password auth with JWT. Users table in Postgres.
   Protected routes return 401 if no valid token."

task-decomposer returns:
  1. Create User model and migration           (src/models/user.ts)       done: migration runs clean
  2. Create auth service (hash, verify, sign)  (src/services/auth.ts)     done: unit tests pass
  3. Create /auth/register and /auth/login     (src/routes/auth.ts)       done: returns JWT on success
  4. Create auth middleware                    (src/middleware/auth.ts)    done: 401 on missing/invalid token
  5. Write tests for service                   (tests/services/auth.ts)   done: happy + error cases pass
  6. Write tests for routes                    (tests/routes/auth.ts)     done: integration tests pass

wave-planner returns:
  Wave 1: tasks 1, 2 (independent)
  Wave 2: tasks 3, 4 (depend on 1 + 2)
  Wave 3: tasks 5, 6 (depend on 2 + 3)
```

---

## Pattern 2 — Full Review

**Trigger:** `/g-review` — or auto-triggered when all waves are complete.

**When to use:** Before any merge. Non-negotiable — the commit gate is locked until MERGE READY.

**Flow:**

```
/g-review
  └─ [gather diff: git diff <mainline>...HEAD — resolved remote HEAD, else main/master]
  └─ [gather done conditions: from g-docs/plans/*.md or g-docs/milestones/ file]

  └─ code-lead (Opus)
       receives: diff, done conditions, branch name
       verifies: all done conditions are met in the diff
       dispatches →

         review-orchestrator (Sonnet)
           dispatches in parallel →
             code-reviewer (Opus)
               receives: diff + context
               returns:  BLOCKING/WARNING/SUGGESTION findings with file:line

             security-auditor (Opus)
               receives: diff + data flow context
               returns:  CRITICAL/HIGH/MEDIUM/LOW findings with remediation

             performance-auditor (Sonnet)
               receives: diff + data volume context
               returns:  findings with impact estimate

             architecture-enforcer (Opus)   [only if layer-boundary files touched]
               receives: diff + layer map from CLAUDE.md
               returns:  violations with file:line and correct pattern

           aggregates: all findings into single report

       code-lead issues verdict:
         MERGE READY  → skill writes .claude/g-forge-approved
         HOLD         → prioritised fix list, no sentinel written
```

**Milestone close-out (MERGE READY only):**

On a MERGE READY verdict, `g-review` automatically:

1. Reads `g-docs/todo.md` to identify tasks completed in this session.
2. Reads `g-docs/ROADMAP.md` to find the active milestone (`🚧 In progress`).
3. Reads the matching `g-docs/milestones/<ID>.md` file.
4. Checks off each completed task in the milestone's `## Scope` checklist.
5. If **all** scope items are now `[x]`:
   - Updates milestone status header to `✅ Done`
   - Updates the g-docs/ROADMAP.md entry from `🚧 In progress` to `✅ Done`
   - Moves the milestone to the `## Done` section of g-docs/ROADMAP.md
   - Reports: `✓ Milestone [ID — Name] closed out`
6. If only some tasks are done — saves partial updates, reports count remaining.

If `g-docs/milestones/` does not exist or no matching tasks are found, this step is skipped silently.

**Verdict meanings:**

- **MERGE READY** — all done conditions met, no BLOCKING findings. Commit gate unlocked.
- **HOLD — FIX REQUIRED** — one or more BLOCKING findings or done conditions not met. Fix all items and re-run `/g-review`.
- **ESCALATE** — code-lead cannot determine verdict (missing context, contradictory requirements). Needs developer input before proceeding.

---

## Pattern 3 — Debug

**Trigger:** Manual — when a bug is confirmed and reproduction steps exist.

**When to use:** A specific, reproducible bug. Not for intermittent issues without logs.

**Flow:**

```
error-detective (Sonnet)
  receives: raw error output, stack trace, or log excerpt
  returns:  pattern identified, probable root cause, confidence level

debugger (Sonnet)
  receives: error-detective's findings + relevant source files
  returns:  root cause with file:line, how the bug occurs step-by-step,
            proposed fix strategy (not implementation)

[developer reviews fix strategy — approves or adjusts]

test-writer (Haiku)
  receives: debugger's fix strategy + test framework in use
  returns:  regression test that fails before the fix and passes after

[implement fix]

/g-review    ← always run before committing the fix
```

**Example — N+1 query bug:**

```
error-detective receives:
  "API response time 8s on /api/orders. Server logs show 47 DB queries per request."

error-detective returns:
  Pattern: N+1 query — one query per order item fetching product details.
  Probable cause: orders.map(o => db.product.findById(o.productId)) in OrderService.
  Confidence: High. Recommend: dispatch debugger with OrderService.ts.

debugger receives:
  error-detective findings + src/services/order.ts

debugger returns:
  Root cause: OrderService.getOrdersWithProducts() line 34 — fetches products
  in a loop inside an async map. Each iteration issues a separate SELECT.
  Fix strategy: replace with a single JOIN query or batch fetch all product IDs
  first, then do one SELECT ... WHERE id IN (...). Recommend the JOIN approach
  for this schema.

test-writer receives:
  Fix strategy + existing test setup

test-writer returns:
  test that mocks DB and asserts getOrdersWithProducts calls db.query exactly once
```

---

## Pattern 4 — Planned Refactor

**Trigger:** Manual — when a refactor has clear scope and must not break architecture.

**When to use:** Any refactor touching more than two files, crossing a module boundary, or renaming a public interface.

**Flow:**

```
spec-writer (Sonnet)
  receives: refactor description, files to touch, scope boundary
  returns:  precise spec with: what moves where, exact renames,
            what is explicitly NOT changing, done condition

architecture-enforcer (Opus)
  receives: spec + current layer map
  returns:  PASS (spec is safe) or violations the spec would introduce
            [if violations: adjust spec before proceeding]

refactor-executor (Haiku)
  receives: approved spec + files to touch
  returns:  refactored files — exactly what the spec said, nothing extra

code-reviewer (Opus)
  receives: diff of the refactor
  returns:  quality findings — logic errors, missed renames, broken references

/g-review    ← always run before committing
```

**Example — extracting a service layer:**

```
spec-writer receives:
  "Extract database calls from UserController into UserRepository.
   Controller should call repository methods, not query DB directly.
   Do not change any public API endpoints or response shapes."

spec-writer returns:
  1. Create src/repositories/user.ts
     - Move: UserController.findById() → UserRepository.findById(id: string): Promise<User|null>
     - Move: UserController.create() → UserRepository.create(dto: CreateUserDto): Promise<User>
     - Move: UserController.update() → UserRepository.update(id, dto): Promise<User|null>
  2. Modify src/controllers/user.ts
     - Replace direct db calls with UserRepository method calls
     - Import UserRepository, remove db import
  3. Scope boundary: only these two files. No route changes. No schema changes.
  Done condition: all existing UserController tests pass unchanged.

architecture-enforcer receives: spec + layer map
architecture-enforcer returns: PASS — repository pattern is correct for this layer.

refactor-executor receives: spec
refactor-executor returns: src/repositories/user.ts created, src/controllers/user.ts updated.
  Report: 3 methods moved, 1 import added, 1 import removed. Nothing outside scope touched.
```

---

## Doctrine — single-use agents and context poisoning

Every pattern above shares one rule: **an agent is single-use.** It gets one approach and one attempt. If it works, it returns `DONE`. If the approach doesn't work, it returns `FAILED` with a learnings report and is discarded — never re-prompted, never continued.

### The failure mode: context poisoning

A context window doesn't merely *store* information — the model **conditions the next token on the entire window.** So when an agent explores options, hits dead-ends, makes a wrong first guess, and keeps going *in the same context*, that crossed-out reasoning never leaves the page it's reading from. The executor then:

- **anchors on options it already rejected** (and quietly reintroduces them),
- **hedges**, because conflicting half-conclusions are still in-window,
- **clings to a wrong first guess** even after correcting it, because the wrong guess is still being weighted.

The cruel part: the more consequential the task, the more exploration it needed — so the highest-stakes work accumulates the most poison. This is distinct from "context is getting long." It is specifically *the residue of deliberation polluting execution.*

### The fix: burn the context, keep the lesson

Single-use agents make context poisoning **structurally impossible**. The failed exploration dies with the agent. The only thing that crosses back to HQ is the distilled `LEARNINGS:` report — a clean contract, not a transcript. HQ analyzes it (optionally via `error-detective` / `debugger` for a *different* mechanism), then deploys a **fresh** agent seeded only by the revised approach. The new agent conditions on ground truth, never on residue.

```
agent (attempt 1)  → FAILED + LEARNINGS  ─┐  (agent discarded — context gone)
                                          │
HQ: analyze learnings, pick a different   │
    mechanism, revert partial changes,    │
    escalate model tier before attempt 3  │
                                          ▼
agent (attempt 2, FRESH)  → FAILED + LEARNINGS  ─┐
                                                 ▼
agent (attempt 3, FRESH, escalated)  → DONE | FAILED
                                                 │
                          3× FAILED → STOP, escalate to human with the trail
```

The retry ceiling is **Three-Strikes** (G-RULES §A8): three fresh attempts with different mechanisms, then HQ stops and hands the developer the full learnings trail rather than spending a fourth. `FAILED` (approach didn't work → HQ retries) is distinct from `BLOCKED` (external dependency → straight to the human; a different approach won't help).

### Why it generalizes

This is the same airtight-handoff discipline G-Forge already trusts for *first* attempts — `spec-writer` produces a spec precise enough for a cheap executor to run without judgment calls — extended to *retries*, which is the one place a naive model leaks. It is also the **automatable form of the deliberation/execution split**: instead of a human carrying finished answers between a messy thinking session and a clean execution session, the pipeline encodes the same boundary structurally. The learnings report is the fixed-contract value crossing the seam; re-prompting a spent agent is mutating the shared object — the executor's window — in place. Keep the seam clean and the executor stays sharp; you aren't making the agent smarter, you're keeping its input clean.

### HQ deliberates too — closing the circle

Dispatched agents aren't the only context that gets poisoned. **HQ poisons its own window** whenever it runs high-branching deliberation directly — weighing architecture options, debating a pattern, drafting an ADR. The single-use doctrine applies one level up, and `/g-adr` is where it's wired:

1. **Offload the weighing.** HQ gathers the developer's raw inputs, then dispatches a **single-use deliberation subagent** to stress-test and draft the decision record. The three-way pattern debate happens in the subagent's window; HQ sees only the finalized draft.
2. **Promote across the seam.** HQ presents the clean draft (plus a flagged weaknesses list) to the developer for approval. The reasoning never crossed back.
3. **Reset the residue — via the path that already exists.** A finalized ADR is an airtight answer produced through deliberation — and the first guardrail is that a deliberation context *goes confidently stale*, so an airtight answer built on it is worse than none. G-Forge already has the reset path: the **context gate** (G-RULES §A7, driven by the exchange counter in `workflow-checkpoint.sh`) auto-triggers `/g-retro`, writes the handoff, and tells the user to open a fresh session when the *exchange count* hits red. `/g-adr` reuses that exact path on a *semantic* trigger — a consequential decision is finalized — so the reset happens when the decision warrants it, not only when the counter climbs. It promotes the clean record (`/g-retro`), writes the handoff with `verify ADR-NNN` as the first task, and recommends a fresh session. Airtight = checked, not remembered; the handoff and the ADR carry the clean record across, so you shed the residue, not the knowledge.

```
[developer raw inputs] → HQ
   │
   ├─ dispatch single-use deliberation subagent (weighing happens HERE)
   │     └─ returns ONLY the finalized ADR draft + weaknesses
   ▼
HQ promotes draft → developer approves → ADR-NNN written
   │
   ▼  reuse the §A7 context-gate reset path (semantic trigger, not exchange-count)
   ├─ /g-retro            (promote the clean record)
   ├─ g-docs/todo.md Next up:    "FIRST: verify ADR-NNN against ground truth"
   ▼
[recommend fresh session] → first task = verify the decision → then build
```

The reset is not a new mechanism: the **context gate** (§A7) already triggers `/g-retro` + handoff + fresh-session on the *quantitative* trigger (exchange count → red). The ADR loop is the *semantic* trigger for the same response — a consequential decision is finalized, so reset now rather than waiting for the counter. The two triggers share one reset path, which is what keeps the fresh session's re-entry clean: it picks up the handoff and the durable record (retro, ADR, journal) instead of the poisoned window.

### The read side — `/g-resume`

Promoting the clean record *out* (`/g-retro` + handoff) is only half the seam. The other half is pulling the right slice back *in* when the fresh session starts — otherwise "start a fresh session" means losing your place. **`/g-resume`** is that read side: on the first prompt of a session (auto-nudged by `workflow-checkpoint.sh` when a handoff is pending), it first verifies the clone is current with origin (fast-forwarding only when safely possible — session start, clean tree), then re-hydrates the clean window selectively — the relevant retro's cold-start, the in-force ADRs, the journal tail, the handoff's first task — keyed to the branch/milestone/first-task. It is "retrieval" in the honest sense available to a markdown-and-shell plugin: gather candidates deterministically by key (grep/glob the durable record), judge relevance, load only the **distilled** sections, never whole histories. A clean window is the point, so re-hydration that dumped everything would just re-poison it.

```
finishing session                          fresh session
─────────────────                          ─────────────
/g-retro  ──promote──▶  durable record  ──/g-resume──▶  clean window
handoff   ──promote──▶  (retros, ADRs,   selective       + first task
                         journal, brief)  retrieval       (e.g. verify ADR-NNN)
```

The same `/g-resume` serves both reset triggers — the red context gate (§A7) and the finalized-ADR trigger (§C). When the first task it surfaces is `verify ADR-NNN`, it offers to run the clean-slate check immediately: confirm the decision still matches ground truth before anything builds on it. That is the loop fully closed — deliberate off-context, promote clean, reset, re-hydrate clean, verify, then build.

---

## Hooks Reference

Installed by `/g-init` into `.claude/hooks/` and registered in `.claude/settings.json`.

| Hook | Event | File | What it does |
|------|-------|------|--------------|
| `workflow-checkpoint.sh` | `UserPromptSubmit` | `.claude/hooks/workflow-checkpoint.sh` | Reports active plan path, current wave, and review-approved state on every message. Claude uses this to auto-trigger plan/execute/review. |
| `check-commit.sh` | `PreToolUse` (Bash) | `.claude/hooks/check-commit.sh` | Blocks any `git commit` command unless `.claude/g-forge-approved` exists. |
| `post-commit-cleanup.sh` | `PostToolUse` (Bash) | `hooks/post-commit-cleanup.sh` | Deletes `.claude/g-forge-approved` after a successful commit, resetting the gate. |
| `agent-lifecycle.sh` | `SubagentStart` / `SubagentStop` | `hooks/agent-lifecycle.sh` | Logs agent start/stop events to `.claude/g-forge-agent-log.jsonl` **and** the silent-observer journal, and echoes a status line to Claude. Hardened JSON parse (no fail-open on the Windows python3 stub). |
| `observe.sh` | `PostToolUse` (Bash) · `SessionStart` | `hooks/observe.sh` | **Silent observer.** Journals meaningful workflow events (commits, branches, tests, pushes, reverts, session opens) to `.claude/journal/YYYY-MM-DD.jsonl`. No stdout — never interrupts. `/g-retro` synthesizes from this journal. Off on the `light` tier. |

**Sentinel file:** `.claude/g-forge-approved` — written by `g-review` on MERGE READY, deleted by `post-commit-cleanup.sh` after commit. Its presence is the only condition that unlocks `git commit`.

**Observer journal:** `.claude/journal/YYYY-MM-DD.jsonl` — append-only, one event per line (`{"ts","kind","detail"}`). Written by `observe.sh` and `agent-lifecycle.sh`; read by `/g-retro` and `/g-align`. Passive — it records, it never acts.

**Note:** `workflow-checkpoint.sh` and `check-commit.sh` are project-local (written to `.claude/hooks/` by `/g-init`). The lifecycle and cleanup hooks ship with the plugin at `hooks/`.

# Using G-Forge: Day-to-Day Workflows

G-Forge is a governance layer, not a code generator. You describe work, Claude breaks it into parallel tasks, implements them, and gates every merge. This page walks you through the real workflows — what you actually do, in order, and what happens back.

---

## The Session Rhythm

A G-Forge session has a clear shape: **start**, **work**, **close**, **resume**. Understanding this rhythm is the foundation for everything else.

### Starting a session

When you open Claude Code in a G-Forge project, the first thing you'll see is the workflow checkpoint (from `skills/g-status/SKILL.md`):

```
[G-Forge Workflow Checkpoint]
  Branch: main
  Active: M3 — Auth refactor · 🚧 In progress
  Review: not yet approved — run /g-review before merging
  Health: ✓ clean
  Tier:   full
```

This tells you where you are: which milestone is active, what the last session left unfinished, and whether the merge gate is open. The moment you land on a branch with carry-over work, run:

```bash
/g-forge resume
```

`/g-resume` (documented in `skills/g-resume/SKILL.md`) does something simple but powerful: it re-hydrates your context with only what matters for this session. It reads the last retro (if one was written), pulls relevant architectural decisions, and surfaces the handoff from wherever you left off — without loading your entire project history. The goal is a clean window. You'll see:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Re-entry — feat/auth-flow · M3 — Auth refactor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
First task:    Implement OAuth token refresh logic
Where we are:  Wave 1 complete. Wave 2 starts with debugger dispatch on refresh timeout.
Freshness:     synced — 2 unpushed commits
Decisions in force:
  · ADR-008 — OAuth PKCE required for all client types
Carry-over:    Remember: token validation must reject expired tokens server-side, not client-side
Anchored to:   M3 closes the OAuth2 authentication stack
Recent:        2 commits (token service tests, retry logic stub)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

This tells you everything you need without scrolling through a 10,000-word transcript. On your first session of a day, `/g-resume` is auto-triggered — you'll see the nudge from the `workflow-checkpoint.sh` hook.

### Ending a session

Before you close, run:

```bash
/g-forge retro
```

`/g-retro` (documented in `skills/g-retro/SKILL.md`) synthesizes what happened from the silent observer journal (a passive log of every commit, branch, test, and agent dispatch written to `.claude/journal/`) plus git history. It writes `g-docs/retros/YYYY-MM-DD-<topic>.md` with what you built, decisions you made, patterns you noticed, and what to do next. You verify the output — you don't recall from memory.

At the same time, `/g-retro` refreshes the canonical handoff in `g-docs/ROADMAP.md` under `## Active Session`. This single block is the golden record for the next session: what closed, what's next, and what context matters. It's ≤150 words (around 30–40 seconds to read).

**Opinion:** The session retrospective is the most underrated tool in the kit. Most developers skip the end-of-session summary because it feels like busywork. It's not — it's the difference between a fresh session that knows exactly where to land versus one that has to re-derive the state from 47 commits and guesswork. Build the habit of `/g-retro` before you close.

---

## Planning a Feature: End-to-End

You have a feature to build. Here's what happens from start to merge.

### 1. Describe the work

Tell Claude what you want to build:

> "Add a search bar to the homepage that filters products by name and category, with autocomplete suggestions from the product database."

### 2. Claude auto-triggers planning (or you trigger it manually)

The workflow checkpoint hook (from `skills/g-plan/SKILL.md` Step 0a) reads your message. If it's non-trivial (involves ≥3 files, introduces a new surface, or has unclear scope), Claude auto-triggers `/g-plan`. If not, or if you want manual control, run:

```bash
/g-forge plan
```

### 3. The planning sequence

`/g-plan` runs a structured interview:

**Step 0 — Scope the testing approach.** Claude asks: "Does this project have a QA panel or structured manual test UI?" This isn't busywork — it gates the whole plan. Done conditions that involve "smoke test this flow" mean nothing without knowing what "this flow" actually is to your team.

**Step 1 — Challenge scope (for features only).** A `project-manager` agent asks three questions:
- Does this fit the project brief?
- Are we solving a real problem or gold-plating?
- What trade-offs does this accept?

You answer. If scope concerns surface, you can override — but the concern is recorded as a risk in the plan.

**Step 2 — Break into tasks.** A `task-decomposer` reads your request and produces atomic, implementable tasks. Search bar → "fetch product list", "build autocomplete component", "write search query filter", "integration test". Each task has a done condition you can verify.

**Step 3 — Schedule into waves.** A `wave-planner` organizes tasks into **waves** — batches that run in parallel because they don't depend on each other. Wave 1 might be "set up the UI component and query"; Wave 2 might be "integration tests and polish". Wave 1 must complete fully before Wave 2 starts.

**Step 3b — Premortem.** `/g-forecast` (called during planning; see `skills/g-forecast/SKILL.md` Step 1) asks: "What could break?" It surfaces scenarios like "autocomplete response times degrade with large datasets" or "autocomplete requests race condition on rapid typing". This is advisory — it doesn't block the plan — but you see the risks before you start.

**Step 4 — Approval gate.** Claude presents the plan:

```
Plan: Search bar with autocomplete

Wave 1 (2 tasks, 1 exchange est.):
  • Implement search input component + styling
  • Wire product fetch query to the API

Wave 2 (2 tasks, 2 exchanges est.):
  • Autocomplete filtering logic
  • Smoke test the end-to-end flow

Risks:
  · High autocomplete latency if dataset is large (mitigation: pagination)
  · Race condition on rapid typing (mitigation: debounce + request deduplication)

Ready to execute? Reply 'approved' to begin, or describe changes.
```

You review. If it looks right, you type `approved`. If you want changes, describe them and the plan adjusts.

### 4. Execution (auto-triggered after approval)

Once you approve, Claude immediately runs `/g-execute` (from `skills/g-execute/SKILL.md`). This dispatches all Wave 1 tasks as parallel subagents **in a single message**:

```
── Wave 1 of 2 ──────────────────────────
Dispatching 2 tasks in parallel:
  • Implement search input component + styling
  • Wire product fetch query to the API
─────────────────────────────────────────
```

You see compact summaries back as each agent finishes. Wave 1 complete? Claude automatically moves to Wave 2. One of the agents returns `FAILED`? Execution stops immediately, and you see the learnings report (what was tried, why it broke, what's ruled out) before any retry happens.

### 5. Review (auto-triggered when all waves finish)

Once all tasks are done, Claude runs `/g-review` (from `skills/g-review/SKILL.md`). This is the merge gate:

- **Tests run** (deterministically from your test script). If any fail, the gate stops and you see the error + a fix strategy.
- **Code review** via the `code-lead` agent — checks for logic errors, architecture violations, anything that would cause problems in production.
- **Tier 3 smoke test** — Claude gives you the manual test checklist and you work through it. Any bugs you find are logged and fixed automatically.

If all passes:

```
MERGE READY
  Tests:        PASS (attested)
  code-lead:    PASS
  Reviewers:    code-reviewer ✓ · architect ✓
  Sentinel:     .claude/g-forge-approved written
  Next:         run git commit
```

The commit gate is now unlocked. You run `git commit` and the changes merge.

### 6. Session close

Run `/g-retro` to write a retrospective. The milestone is auto-checked off in the roadmap. You're ready for the next task.

---

## Debugging a Bug: Triage and Fix

You have an error stack trace or a failing test. What's the workflow?

### 1. Share the stack trace

Paste it into Claude:

```
Error: Cannot read property 'id' of undefined
  at getUserProducts (services/product.ts:42:18)
  at async handleSearch (handlers/search.ts:15:9)
```

### 2. Claude auto-dispatches error-detective

The `error-detective` agent (mentioned in `skills/g-execute/SKILL.md` Step 0) pattern-matches the stack trace and returns:

```
Diagnosis:
  The error occurs at product.ts:42 in a null-coalescing pattern.
  Stack suggests undefined product object being passed from search handler.
  
  Root cause (likely): search handler calls getProductList() but doesn't verify
  response structure before passing to getUserProducts().
```

### 3. Dispatch the debugger

Claude then dispatches the `debugger` agent with the error diagnosis + source files. It returns a fix strategy:

```
Fix: Add null check in handleSearch before getUserProducts() call.
  Verify: response.data && response.data.products before proceeding.
  Test: Write test case for empty product list response.
```

### 4. Plan and execute the fix

If the fix is trivial, Claude may implement it inline. For larger changes, `/g-plan` runs, you approve, and `/g-execute` runs the fix waves. `/g-review` gates the merge.

---

## Auditing Code Quality

You want to understand technical debt in your codebase. Run:

```bash
/g-forge audit
```

Or target a specific area:

```bash
/g-forge audit src/handlers
```

**Targeted scope** (from `skills/g-audit/SKILL.md` Step 1): Claude scans the path for SOLID violations, code smells, and architectural drift. You get an inline report with severity and file:line references. You can fix issues immediately or save them for a refactor sprint.

**Full codebase scope**: Claude produces a prioritized roadmap milestone with every finding grouped by severity and category. This becomes M7 or M8 in your roadmap — a dedicated refactoring pass.

---

## Handling Documentation Debt

Documentation gaps compound. Run:

```bash
/g-forge docs
```

Or scope it:

```bash
/g-forge docs src/api
```

Claude scans for (from `skills/g-docs/SKILL.md` Step 3):
- Undocumented public exports (functions, classes, types without docstrings)
- Stale documentation (docstrings that don't match the current signature)
- Missing README sections (quickstart, API reference, contributing guide)
- Undocumented environment variables
- Architectural decisions without ADRs

**Targeted scope**: The `doc-writer` agent fixes gaps immediately — you review and approve the changes.

**Full codebase scope**: A prioritized documentation debt report becomes a roadmap milestone. You schedule it into a future sprint.

---

## Checking Your Status and Recovering

At any point, you can ask where you are:

```bash
/g-forge status
```

This outputs a snapshot (from `skills/g-status/SKILL.md`):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
G-Forge Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Milestone:    M3 — Auth refactor · 🚧 In progress
Plan:         g-docs/plans/search-autocomplete.md · Wave 2 of 2
Review gate:  locked
Handoff:      Write integration tests for autocomplete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If something goes wrong mid-execution (a wave fails, review gate halts, or context runs out), the handoff in `g-docs/ROADMAP.md` tells the next session exactly where to resume. You don't have to dig through git history or remember what you were doing.

---

## Customizing Your Workflow

G-Forge adapts to how much automation you want. All workflows are controlled by two settings:

### Integration Tiers

See [`../g-docs/integration-tiers.md`](../g-docs/integration-tiers.md) for full details. The default is `full`:

```bash
/g-tier full
```

This auto-triggers planning, execution, and review. If you want to stay in control:

```bash
/g-tier balanced
```

This keeps the commit gate on (no accidental merges) but turns off auto-triggers. You invoke `/g-plan`, `/g-execute`, and `/g-review` manually.

For trivial edits (one file, known location), you can:

```bash
/g-tier light
```

This disables the commit gate entirely. Make your change, commit it, and switch back to `full`.

### Voice Profiles

See [`../g-docs/voice-profiles.md`](../g-docs/voice-profiles.md). G-Forge speaks in one of three registers:

```bash
/g-voice dev
```

Terse, assumes you know the jargon (default for experienced developers).

```bash
/g-voice mid
```

Same information, plus one sentence of context per result.

```bash
/g-voice eli5
```

Plain language for collaborators who aren't engineers.

---

## Adaptive Review Intensity

G-Forge adapts the intensity of review based on project health. See [`../g-docs/telemetry-metrics.md`](../g-docs/telemetry-metrics.md) for the detailed metrics. The gist:

- **Stable** (default): Standard review set (code-lead + 2 specialists for architecture/security/performance).
- **Cautious**: Extra code-reviewer pass on the way.
- **Defensive**: Extra architecture reviewer + pre-review by error-detective.
- **Recovery**: Full reviewer set + pre-review diagnostic agents on every dispatch.

You don't configure this yourself. G-Forge measures rework rate, review catch rate, regression frequency, and others from your project history (from your own retros and git log). If you see patterns — say, the same class of bug gets caught three reviews running — the system tightens the review gate before the next wave. If fixes start sticking, it relaxes.

---

## What Happens at Milestones

When you complete the last task in a milestone and pass review, several things happen automatically (from `skills/g-review/SKILL.md` Step 6, "Milestone close-out"):

1. Tasks in `g-docs/milestones/M[N].md` are marked `[x]`.
2. The milestone status in the roadmap flips from 🔄 to ✅.
3. `/g-retro` runs automatically.
4. `/g-telemetry` computes health metrics.
5. `/g-patterns` mines for recurring friction patterns.
6. `/g-wiki` refreshes the human-facing project narrative.

Every other milestone, `/g-doctor` runs a 25-point health check on hooks, rules, and config drift. This is automatic — you're not managing infrastructure.

---

## Emergency Commands

If something feels off, run:

```bash
/g-forge help
```

This detects your current state (which milestone, what's in progress, what's the blocker) and suggests the next action. If you need detail:

```bash
/g-forge doctor
```

This is a 25-point diagnostic (from the README § "Commit Enforcement") that checks hooks are installed, settings are aligned, rules are current, and the commit gate isn't jammed.

If you want to step out of the workflow entirely:

```bash
/g-forge afk
```

This runs all pending waves and review unattended (useful if you're about to lose internet). Safety limits apply — no remote push, no destructive commands.

---

## Key Takeaways

1. **Start each session with `/g-resume`** — it pulls only the context you need.
2. **End each session with `/g-retro`** — it writes the handoff for the next one.
3. **Describe work naturally** — Claude decides whether to auto-trigger `/g-plan`.
4. **Approve the plan before it runs** — you control the sequence.
5. **Trust the review gate** — it's enforced, not advisory. Code doesn't merge until `/g-review` issues MERGE READY.
6. **Check your tier and voice** — customize the automation and communication style to match your workflow.
7. **Let telemetry adapt review intensity** — the system tightens review on unstable projects and relaxes when you're shipping clean.

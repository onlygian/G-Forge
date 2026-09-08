# M1 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the complete G-Team plugin repository so that `/plugin install g-team` succeeds and all 15 agent stubs and 4 skill directories are present with correct structure.

**Architecture:** All deliverables are configuration files and markdown — no compiled code. Validation is structural (file existence, valid JSON/YAML). The repo must satisfy Claude Code's plugin loader: `.claude-plugin/plugin.json` references valid paths, agent frontmatter is parseable, skill directories contain `SKILL.md` files.

**Tech Stack:** Markdown, JSON, Git. No build tooling required.

---

## File Map

| File | Responsibility |
|---|---|
| `.gitignore` | Exclude OS/editor artifacts |
| `README.md` | Public stub — full content delivered in M5 by doc-writer |
| `.claude-plugin/plugin.json` | Plugin manifest — tells Claude Code where agents, skills, hooks live |
| `agents/*.md` (×15) | Agent stubs — correct frontmatter, empty body |
| `skills/*/SKILL.md` (×4) | Skill stubs — correct frontmatter, implementation deferred to M3 |
| `hooks/hooks.json` | Hook config stub — SubagentStart/Stop event stubs |
| `profiles/*/agents/.gitkeep` (×5) | Keep profile directories in git |
| `profiles/*/rules/.gitkeep` (×5) | Keep profile rule directories in git |
| `ROADMAP.md` | Project dashboard — human-controlled |
| `milestones/M1-foundation.md` | M1 tracking entry |
| `milestones/M2-agent-roster.md` | M2 tracking entry — fully specced |
| `milestones/M3-orchestration.md` | Goal defined only |
| `milestones/M4-profiles.md` | Goal defined only |
| `milestones/M5-publish.md` | Goal defined only |

---

## Task 1: Project hygiene

**Files:**
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: Create .gitignore**

```
.DS_Store
Thumbs.db
*.local
.env
```

- [ ] **Step 2: Create README.md stub**

```markdown
# G-Team

> Multi-agent Claude Code plugin — code quality, production architecture, planned execution.

Install:
```bash
/plugin marketplace add onlygian/g-team
/plugin install g-team
```

Full documentation coming in M5.
```

- [ ] **Step 3: Commit and push**

```bash
git add .gitignore README.md
git commit -m "chore: add .gitignore and README stub" && git push
```

---

## Task 2: Plugin manifest

**Files:**
- Create: `.claude-plugin/plugin.json`

- [ ] **Step 1: Create the manifest**

```bash
mkdir -p .claude-plugin
```

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "g-team",
  "version": "0.1.0",
  "description": "Specialized multi-agent system for code quality, production architecture, and planned execution",
  "repository": "https://github.com/onlygian/g-team",
  "license": "MIT",
  "agents": "./agents/",
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json"
}
```

- [ ] **Step 2: Validate JSON parses**

```bash
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8')); console.log('VALID')"
```

Expected output: `VALID`

- [ ] **Step 3: Commit and push**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: add plugin manifest" && git push
```

---

## Task 3: Agent stubs

**Files:**
- Create: `agents/task-decomposer.md`
- Create: `agents/wave-planner.md`
- Create: `agents/spec-writer.md`
- Create: `agents/code-reviewer.md`
- Create: `agents/architecture-enforcer.md`
- Create: `agents/security-auditor.md`
- Create: `agents/performance-auditor.md`
- Create: `agents/debugger.md`
- Create: `agents/error-detective.md`
- Create: `agents/test-writer.md`
- Create: `agents/pr-writer.md`
- Create: `agents/doc-writer.md`
- Create: `agents/refactor-executor.md`
- Create: `agents/project-manager.md`
- Create: `agents/review-orchestrator.md`

- [ ] **Step 1: Create agents/ directory**

```bash
mkdir -p agents
```

- [ ] **Step 2: Create task-decomposer.md**

```markdown
---
name: task-decomposer
description: Breaks any request into atomic, verifiable tasks with done conditions. Invoke at the start of any multi-step implementation before touching code.
model: sonnet
tools: Read, Glob, Grep
---
```

- [ ] **Step 3: Create wave-planner.md**

```markdown
---
name: wave-planner
description: Takes a task list and produces a parallel wave schedule by mapping dependencies. Invoke after task-decomposer to determine execution order.
model: sonnet
tools: Read
---
```

- [ ] **Step 4: Create spec-writer.md**

```markdown
---
name: spec-writer
description: Produces a precise implementation spec from a brief or task — precise enough for a Haiku agent to execute without judgment calls. Invoke when a task needs speccing before handoff.
model: sonnet
tools: Read, Glob, Grep
---
```

- [ ] **Step 5: Create code-reviewer.md**

```markdown
---
name: code-reviewer
description: Reviews code changes for logic errors, code smells, DRY violations, and edge cases. Reports with file:line refs and severity. Does not fix. Invoke before any merge.
model: opus
tools: Read, Glob, Grep
---
```

- [ ] **Step 6: Create architecture-enforcer.md**

```markdown
---
name: architecture-enforcer
description: Validates layer boundary integrity, import directions, and separation of concerns. Reports violations with file:line refs. Does not fix. Invoke when layer-boundary files are changed.
model: opus
tools: Read, Glob, Grep
---
```

- [ ] **Step 7: Create security-auditor.md**

```markdown
---
name: security-auditor
description: Audits for OWASP Top 10 vulnerabilities, injection vectors, secrets exposure, and auth flaws. Reports with severity and remediation guidance. Does not fix. Invoke before any merge touching auth or external integrations.
model: opus
tools: Read, Glob, Grep
---
```

- [ ] **Step 8: Create performance-auditor.md**

```markdown
---
name: performance-auditor
description: Flags O(n²) paths, N+1 queries, unnecessary re-renders, and hot-path waste. Reports with file:line refs and estimated impact. Does not fix. Invoke on performance-sensitive changes.
model: sonnet
tools: Read, Glob, Grep
---
```

- [ ] **Step 9: Create debugger.md**

```markdown
---
name: debugger
description: Reproduces a failing test or bug, traces root cause, and proposes a fix strategy. Does not implement. Invoke when a bug resists a first fix attempt.
model: sonnet
tools: Read, Glob, Grep, Bash
---
```

- [ ] **Step 10: Create error-detective.md**

```markdown
---
name: error-detective
description: Parses logs, stack traces, and error output to identify patterns and narrow root causes. Does not fix. Invoke when facing cryptic errors or production incidents before attempting a fix.
model: sonnet
tools: Read, Glob, Grep, Bash
---
```

- [ ] **Step 11: Create test-writer.md**

```markdown
---
name: test-writer
description: Writes unit tests from a function signature or implementation spec. Fixed data only — no Date.now() or random values. Invoke after spec-writer or after implementing a function needing coverage.
model: haiku
tools: Read, Glob, Grep, Write, Edit
---
```

- [ ] **Step 12: Create pr-writer.md**

```markdown
---
name: pr-writer
description: Generates a PR description from git diff — what changed, why, and how to test. Invoke before opening a pull request.
model: haiku
tools: Read, Bash
---
```

- [ ] **Step 13: Create doc-writer.md**

```markdown
---
name: doc-writer
description: Writes inline documentation and README sections from code. Explains WHY not WHAT. Invoke after implementation is complete or to generate public-facing documentation.
model: haiku
tools: Read, Glob, Grep, Write, Edit
---
```

- [ ] **Step 14: Create refactor-executor.md**

```markdown
---
name: refactor-executor
description: Executes a written refactor spec exactly — no scope creep, no adjacent improvements, no judgment calls. Invoke with a spec from spec-writer.
model: haiku
tools: Read, Glob, Grep, Write, Edit, Bash
---
```

- [ ] **Step 15: Create project-manager.md**

```markdown
---
name: project-manager
description: Coordinates the full feature development pipeline from planning through PR. Dispatches specialist agents per phase — does not write code or edit files itself. Invoke for end-to-end feature development.
model: sonnet
tools: Agent
---
```

- [ ] **Step 16: Create review-orchestrator.md**

```markdown
---
name: review-orchestrator
description: Coordinates the full review pipeline — code review, architecture, security, and performance in parallel. Aggregates findings into one report. Does not review itself. Invoke before any significant merge.
model: sonnet
tools: Agent
---
```

- [ ] **Step 17: Validate 15 agent files exist**

```bash
find agents/ -name "*.md" | wc -l
```

Expected output: `15`

- [ ] **Step 18: Validate all frontmatter has required fields**

```bash
for f in agents/*.md; do
  echo "=== $f ===";
  grep -E "^(name|description|model):" "$f" || echo "MISSING REQUIRED FIELD";
done
```

Expected: every file shows name, description, and model lines. No "MISSING REQUIRED FIELD" output.

- [ ] **Step 19: Commit and push**

```bash
git add agents/
git commit -m "feat: add 15 agent stubs with frontmatter" && git push
```

---

## Task 4: Skills scaffold

**Files:**
- Create: `skills/g-team-init/SKILL.md`
- Create: `skills/g-team-plan/SKILL.md`
- Create: `skills/g-team-review/SKILL.md`
- Create: `skills/g-team-specialize/SKILL.md`

- [ ] **Step 1: Create skill directories**

```bash
mkdir -p skills/g-team-init skills/g-team-plan skills/g-team-review skills/g-team-specialize
```

- [ ] **Step 2: Create g-team-init/SKILL.md**

```markdown
---
name: g-team-init
description: Scaffold a new project with CLAUDE.md template, ROADMAP.md dashboard, and milestones/ directory. Run once in a new project after installing g-team.
---

Implementation in M3.
```

- [ ] **Step 3: Create g-team-plan/SKILL.md**

```markdown
---
name: g-team-plan
description: Decompose the current request into atomic tasks and produce a parallel wave schedule. Runs task-decomposer then wave-planner. Use at the start of any multi-step implementation.
---

Implementation in M3.
```

- [ ] **Step 4: Create g-team-review/SKILL.md**

```markdown
---
name: g-team-review
description: Run the full review pipeline on the current branch diff. Dispatches code-reviewer, security-auditor, performance-auditor, and architecture-enforcer in parallel via review-orchestrator.
---

Implementation in M3.
```

- [ ] **Step 5: Create g-team-specialize/SKILL.md**

```markdown
---
name: g-team-specialize
description: Detect the project stack and write the matching profile agents and architecture rules into .claude/agents/. Accepts an optional stack argument to skip detection.
argument-hint: [stack]
---

Implementation in M4.
```

- [ ] **Step 6: Validate 4 SKILL.md files exist**

```bash
find skills/ -name "SKILL.md" | wc -l
```

Expected output: `4`

- [ ] **Step 7: Commit and push**

```bash
git add skills/
git commit -m "feat: add 4 skill stubs" && git push
```

---

## Task 5: Hooks and profiles scaffold

**Files:**
- Create: `hooks/hooks.json`
- Create: `profiles/vue-pinia/agents/.gitkeep`
- Create: `profiles/vue-pinia/rules/.gitkeep`
- Create: `profiles/react/agents/.gitkeep`
- Create: `profiles/react/rules/.gitkeep`
- Create: `profiles/node-ts/agents/.gitkeep`
- Create: `profiles/node-ts/rules/.gitkeep`
- Create: `profiles/fastapi/agents/.gitkeep`
- Create: `profiles/fastapi/rules/.gitkeep`
- Create: `profiles/tauri/agents/.gitkeep`
- Create: `profiles/tauri/rules/.gitkeep`

- [ ] **Step 1: Create hooks/hooks.json**

```bash
mkdir -p hooks
```

```json
{
  "hooks": {
    "SubagentStart": [],
    "SubagentStop": []
  }
}
```

- [ ] **Step 2: Validate hooks JSON**

```bash
node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8')); console.log('VALID')"
```

Expected: `VALID`

- [ ] **Step 3: Create profile scaffolds**

```bash
for profile in vue-pinia react node-ts fastapi tauri; do
  mkdir -p "profiles/$profile/agents" "profiles/$profile/rules"
  touch "profiles/$profile/agents/.gitkeep" "profiles/$profile/rules/.gitkeep"
done
```

- [ ] **Step 4: Validate profile structure**

```bash
find profiles/ -name ".gitkeep" | wc -l
```

Expected output: `10`

- [ ] **Step 5: Commit and push**

```bash
git add hooks/ profiles/
git commit -m "feat: add hooks stub and profile scaffolds" && git push
```

---

## Task 6: ROADMAP.md

**Files:**
- Create: `ROADMAP.md`

- [ ] **Step 1: Create ROADMAP.md**

```markdown
# G-Team

> Multi-agent Claude Code plugin — code quality, production architecture, planned execution.

---

## Current: M1 — Foundation  🟡 In Progress

Repo scaffold, plugin manifest, agent stubs, skill stubs, hooks, profiles, milestone files.

→ [milestones/M1-foundation.md](milestones/M1-foundation.md)

---

## Milestones

| # | Milestone | Goal | Status |
|---|---|---|---|
| M1 | Foundation | Repo, plugin.json, 15 agent stubs, 4 skill dirs, hooks, profiles, milestone files | 🟡 In Progress |
| M2 | Agent Roster | Full system prompts for all 15 agents — mandates, output contracts, scope discipline | ⬜ Planned |
| M3 | Skills & Orchestration | /g-team plan, review, init wired and working end-to-end | ⬜ Goal defined |
| M4 | Stack Profiles | /g-team specialize + vue-pinia, node-ts, fastapi profiles complete | ⬜ Goal defined |
| M5 | Publish | README (by doc-writer), docs/agents.md, marketplace listing | ⬜ Goal defined |

---

## Backlog

- [ ] tauri profile (M4+)
- [ ] react profile (M4+)
- [ ] dependency-auditor agent
- [ ] /g-team health — project-level audit snapshot
```

- [ ] **Step 2: Commit and push**

```bash
git add ROADMAP.md
git commit -m "feat: add ROADMAP.md project dashboard" && git push
```

---

## Task 7: Milestone files

**Files:**
- Create: `milestones/M1-foundation.md`
- Create: `milestones/M2-agent-roster.md`
- Create: `milestones/M3-orchestration.md`
- Create: `milestones/M4-profiles.md`
- Create: `milestones/M5-publish.md`

- [ ] **Step 1: Create milestones/ directory**

```bash
mkdir -p milestones
```

- [ ] **Step 2: Create M1-foundation.md**

```markdown
# M1 — Foundation

## Goal
Scaffolded repo with valid plugin structure that loads in Claude Code.

## Done condition
All 15 agent files and 4 skill directories present. `plugin.json` is valid JSON. `hooks.json` is valid JSON. All 5 profile scaffolds exist.

## Plan
→ [docs/superpowers/plans/2026-05-03-m1-foundation.md](../docs/superpowers/plans/2026-05-03-m1-foundation.md)

## Tasks
- [x] Init git repo
- [x] Add design spec
- [ ] .gitignore + README stub
- [ ] .claude-plugin/plugin.json
- [ ] agents/ — 15 stubs
- [ ] skills/ — 4 stubs
- [ ] hooks/hooks.json
- [ ] profiles/ — 5 scaffolds
- [ ] ROADMAP.md
- [ ] milestones/ — all 5 files
- [ ] Validate structure
```

- [ ] **Step 3: Create M2-agent-roster.md**

```markdown
# M2 — Agent Roster

## Goal
All 15 agents have complete system prompts: single mandate, output contract (summary + file:line refs + done condition), and scope discipline (flag adjacent issues, never act on them).

## Done condition
Every agent in agents/ has a non-empty body. Every agent's system prompt includes: its mandate, output format, and at least one explicit scope rule.

## Plan
→ [docs/superpowers/plans/2026-05-03-m2-agent-roster.md](../docs/superpowers/plans/2026-05-03-m2-agent-roster.md)

## Agents

### Planning (Sonnet)
- [ ] task-decomposer
- [ ] wave-planner
- [ ] spec-writer

### Quality (Opus)
- [ ] code-reviewer
- [ ] architecture-enforcer
- [ ] security-auditor

### Reasoning (Sonnet)
- [ ] performance-auditor
- [ ] debugger
- [ ] error-detective

### Execution (Haiku)
- [ ] test-writer
- [ ] pr-writer
- [ ] doc-writer
- [ ] refactor-executor

### Orchestration (Sonnet)
- [ ] project-manager
- [ ] review-orchestrator
```

- [ ] **Step 4: Create M3-orchestration.md**

```markdown
# M3 — Skills & Orchestration

## Goal
The four /g-team skills are implemented and working end-to-end: /g-team plan runs task-decomposer → wave-planner and presents a wave schedule; /g-team review runs review-orchestrator and returns an aggregated report; /g-team init scaffolds a new project correctly.

## Status
Goal defined. Will be fully specced when M2 closes.
```

- [ ] **Step 5: Create M4-profiles.md**

```markdown
# M4 — Stack Profiles

## Goal
/g-team specialize detects the project stack (or accepts a stack arg) and writes the correct profile agents and architecture rules into .claude/agents/. Three launch profiles complete: vue-pinia, node-ts, fastapi.

## Status
Goal defined. Will be fully specced when M3 closes.
```

- [ ] **Step 6: Create M5-publish.md**

```markdown
# M5 — Publish

## Goal
README.md generated by doc-writer from docs/agents.md and docs/orchestration-patterns.md — public-facing: install guide, agent reference with model tiers, orchestration pattern examples, profile guide. Marketplace listing submitted.

## Status
Goal defined. Will be fully specced when M4 closes.
```

- [ ] **Step 7: Commit and push**

```bash
git add milestones/
git commit -m "feat: add milestone tracking files" && git push
```

---

## Task 8: Validate complete structure

- [ ] **Step 1: Verify all required files exist**

```bash
echo "=== Plugin manifest ===" && test -f .claude-plugin/plugin.json && echo "OK" || echo "MISSING"
echo "=== Agents (expect 15) ===" && find agents/ -name "*.md" | wc -l
echo "=== Skills (expect 4) ===" && find skills/ -name "SKILL.md" | wc -l
echo "=== Hooks ===" && test -f hooks/hooks.json && echo "OK" || echo "MISSING"
echo "=== Profile scaffolds (expect 10) ===" && find profiles/ -name ".gitkeep" | wc -l
echo "=== ROADMAP ===" && test -f ROADMAP.md && echo "OK" || echo "MISSING"
echo "=== Milestones (expect 5) ===" && find milestones/ -name "*.md" | wc -l
```

Expected output:
```
=== Plugin manifest ===
OK
=== Agents (expect 15) ===
15
=== Skills (expect 4) ===
4
=== Hooks ===
OK
=== Profile scaffolds (expect 10) ===
10
=== ROADMAP ===
OK
=== Milestones (expect 5) ===
5
```

- [ ] **Step 2: Update ROADMAP.md — mark M1 done, M2 in progress**

In `ROADMAP.md`, change:

```markdown
## Current: M1 — Foundation  🟡 In Progress
```
to:
```markdown
## Current: M2 — Agent Roster  🟡 In Progress
```

And update the milestone table:
```markdown
| M1 | Foundation | Repo, plugin.json, 15 agent stubs, 4 skill dirs, hooks, profiles, milestone files | ✅ Done |
| M2 | Agent Roster | Full system prompts for all 15 agents — mandates, output contracts, scope discipline | 🟡 In Progress |
```

- [ ] **Step 3: Update M1-foundation.md — mark all tasks done**

In `milestones/M1-foundation.md`, change all `- [ ]` to `- [x]`.

- [ ] **Step 4: Final commit and push**

```bash
git add ROADMAP.md milestones/M1-foundation.md
git commit -m "chore: close M1 — foundation scaffold complete" && git push
```

---

**M1 done condition:** All validation checks in Task 8 Step 1 pass. ROADMAP.md shows M2 as current.

# Kickoff + Specialize Stack Depth Implementation Plan

> **For agentic workers:** Use G-Team's own wave execution model. Both tasks are independent — dispatch in parallel (Wave 1). No Wave 2 needed.

**Goal:** Make `/g-team kickoff` deeply interrogate and validate every stack and integration decision, producing a locked tech decisions table in the brief; make `/g-team specialize` read the brief and roadmap first, handle multi-stack projects, and consult code-lead when the picture is ambiguous or risky.

**Architecture:** Both changes are isolated SKILL.md rewrites. Kickoff adds a new Group 4 (stack deep dive + integration map), a dedicated stack-challenge step, an expanded code-lead mandate, and a tech decisions table in the proposal and brief templates. Specialize prepends a context-gathering phase that reads project_brief.md + ROADMAP.md + dependency files, synthesises which profiles to apply (including multi-stack), and gates code-lead involvement on ambiguity or risk.

**Tech Stack:** Markdown (SKILL.md)

---

## File Map

| Action | File | What changes |
|--------|------|--------------|
| Modify | `skills/g-team-kickoff/SKILL.md` | New Group 4 (stack deep dive + integration map); dedicated stack challenge step; expanded code-lead mandate; tech decisions table in proposal and brief |
| Modify | `skills/g-team-specialize/SKILL.md` | New Step 1 reads brief + ROADMAP + deps; multi-stack handling; conditional code-lead gate; confirmation lists all profiles |

---

## Task 1 — Update skills/g-team-kickoff/SKILL.md

**Files:**
- Modify: `skills/g-team-kickoff/SKILL.md`

- [ ] **Step 1: Read current file**

```bash
cat skills/g-team-kickoff/SKILL.md
```

- [ ] **Step 2: Overwrite with full updated implementation**

Write `skills/g-team-kickoff/SKILL.md` with this exact content:

```markdown
---
name: g-team-kickoff
description: Interview the developer about their project goals, constraints, and stack. Challenges scope and every tech choice honestly. Works with project-manager and code-lead to define an MVP, validate the stack, and produce a locked project_brief.md with a tech decisions table.
---

**Announce:** "Using g-team-kickoff to shape the project brief."

You are a critical friend. Your job is to ask good questions, challenge scope and stack choices honestly, involve the right agents, and produce a clear `project_brief.md`. You give real opinions. The developer always has the final word, but they get your honest take first.

## Step 1 — Interview the developer

Ask these question groups one at a time. Wait for full answers before moving to the next group.

**Group 1 — The problem:**
- What does this project do in one sentence?
- Who uses it, and what specific pain does it solve for them?
- What does success look like in 3 months? In 12 months?

**Group 2 — Scope:**
- What are the features you absolutely cannot launch without?
- What are features you want but could live without for the first version?
- What is explicitly out of scope — things you've decided NOT to build?

**Group 3 — Technical context (surface):**
- What stack or technologies are you committed to (if any)?
- Any existing systems this must integrate with?
- Team size, experience level with the stated stack, and how much time per week on this?

**Group 4 — Stack deep dive:**

Ask these only after Group 3 answers are in hand. Go through each technology mentioned in Group 3 and each integration dimension below. Ask the questions that aren't already answered — don't repeat what the developer already told you.

*For each committed technology (framework, language, runtime):*
- "You mentioned [tech]. What alternatives did you consider and rule out, and why [tech]?"
- "What's the team's actual experience with [tech] — have you shipped something with it before?"

*Integration map — ask about each of these explicitly if not already covered:*
- **Auth:** Are users logging in? Which provider — Supabase Auth, Auth0, Firebase, Clerk, custom JWT, or something else?
- **Database:** What are you storing? Relational or document? Which engine (Postgres, MySQL, SQLite, MongoDB, etc.)?
- **File storage:** Any uploads, images, or documents to store? (S3, Cloudflare R2, Supabase Storage, local?)
- **Real-time:** Any live updates, chat, notifications, or presence? (WebSockets, SSE, polling?)
- **External APIs:** Which third-party services does this call? (payment processors, maps, email, SMS, analytics?)
- **Deployment target:** Where does this run — Vercel, Netlify, VPS, Railway, AWS, self-hosted, local only?
- **CI/CD:** Any automated testing or deployment pipeline already in place or planned?

Wait for answers before proceeding.

## Step 2 — Challenge stack choices

Before involving agents, review the developer's tech answers critically. For each committed technology or integration choice, ask yourself:

- **Is this the right size tool?** Does it match the problem complexity and team size (e.g., microservices for a 2-person project)?
- **Does the team actually know this?** Committing to a stack the team hasn't shipped with before is a risk worth naming.
- **Is there a simpler option?** Could a managed service replace a self-built integration?
- **Are there known pain points?** Specific version, library, or combination choices that commonly cause issues.

For any choice that raises a flag, ask one honest question:

> "You've committed to [tech/choice]. [Specific concern — e.g. 'Your team hasn't shipped with it before' / 'This is usually overkill for a project this size' / 'This combination has known issues with X']. Are you set on this, or is it worth reconsidering before we build around it?"

Wait for the answer. Accept it if the developer explains the need. If the answer is vague, note the risk in the tech decisions table. Do not push more than once per choice.

## Step 3 — Challenge the scope

Review the developer's feature answers critically. For each feature or requirement, ask yourself:

- **Is this overengineered?** Does it solve a problem the developer doesn't actually have yet?
- **Is this redundant?** Does something already solve this — a library, a SaaS, an existing tool?
- **Is this speculative?** Is the developer building for a user who doesn't exist yet?
- **Does this double down on complexity?** Does it add a second way to do something already handled?

For any feature that raises a flag, ask the developer directly — one honest question:

> "You've mentioned [feature]. I want to make sure we're solving a real problem — [specific concern]. Why do you need this now rather than later?"

Wait for the answer. Accept it if the developer explains the need. If the answer is vague, note it as a Could-have or non-goal. Do not push more than once per feature.

## Step 4 — Involve project-manager

Dispatch the `project-manager` agent with:
- A summary of the developer's answers (verbatim where relevant)
- The list of features, flagged as Must / Should / Could based on the Step 3 challenge

Ask project-manager to:
> "Given these answers, define an MVP — the smallest thing that proves the core value and can ship. Then define the path to feature-complete in milestones. Be honest: if any Must-have looks like scope creep or premature complexity, say so."

Wait for project-manager's response. Present it to the developer with: "Here is how project-manager suggests structuring the scope — do you agree with the MVP boundary? Anything that should move in or out?"

## Step 5 — Involve code-lead for stack and integration validation

Dispatch the `code-lead` agent with:
- The developer's full Group 3 + Group 4 answers (all tech choices + the complete integration map)
- project-manager's MVP and milestone proposal
- Any stack concerns surfaced in Step 2

Ask code-lead to address these specifically:
> "Review the technical choices for this project. I need answers on four things:
>
> 1. **Stack fit:** Is this stack appropriate for the use case, problem size, and team experience? Flag anything mismatched.
> 2. **Integration risks:** Which integrations are likely to be underestimated or block the MVP? Give a realistic complexity rating (Low / Medium / High) for each.
> 3. **Specific pain points:** Are there known issues with the stated library versions, combinations, or deployment choices that will cause pain? Name them concretely.
> 4. **Starting point recommendation:** What should they build first technically — what's the right skeleton to avoid painting themselves into a corner?
>
> Be blunt. The developer needs real opinions, not reassurance."

Wait for code-lead's response. Present it to the developer with: "Here is code-lead's technical read — any corrections or disagreements?"

## Step 6 — Present proposal including tech decisions table

Synthesize everything into a structured proposal. Present this to the developer before writing any file:

```
## Kickoff Proposal — [Project Name]

### MVP
What ships first and proves the core value:
- [Feature 1] — [why it's in MVP]
- [Feature 2] — [why it's in MVP]

**MVP done condition:** [specific, observable thing that means MVP is working]

### Path to feature-complete
| Milestone | Features | Why this order |
|-----------|----------|----------------|
| M1 — MVP | [list] | Validates core value before investing further |
| M2 — [name] | [list] | [dependency or user feedback reason] |
| M3 — [name] | [list] | [dependency or user feedback reason] |

### Tech decisions
| Component | Choice | Rationale | Risk | Code-lead note |
|-----------|--------|-----------|------|----------------|
| [e.g. Frontend] | [e.g. Vue 3 + Pinia] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Backend] | [e.g. FastAPI] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Auth] | [e.g. Supabase Auth] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Database] | [e.g. Postgres via Supabase] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |
| [e.g. Deployment] | [e.g. Vercel + Railway] | [why] | [Low/Medium/High — reason] | [code-lead flag or "None"] |

### Honest notes
[List any features or stack choices that were challenged and why — e.g.:]
- [Feature X] moved to M2: premature without knowing if MVP gets traction
- [Stack choice Y]: noted risk — [concern]; developer confirmed intentional

### Open questions
- [Unresolved decision that affects scope, stack, or sequencing]
```

Tell the developer: "This is my honest recommendation. You have the final word — tell me what to change or say 'approved' to lock it."

If the developer overrides a recommendation, accept it without argument. Note the override in the brief.

## Step 7 — Produce and lock project_brief.md

Once the developer approves (or amends and approves), write `project_brief.md` at the project root:

```
# Project Brief — [Project Name]

**Created:** [today's date]
**Status:** Approved

## What this builds
[One paragraph: what it is, what problem it solves, who uses it]

## Goals
- [Measurable goal 1]
- [Measurable goal 2]

## Non-goals (explicitly out of scope)
- [What we are NOT building, and why]

## MVP
[List of features in the MVP and the MVP done condition]

## Roadmap
| Milestone | Features | Rationale |
|-----------|----------|-----------|
| M1 — MVP | [list] | [why] |
| M2 | [list] | [why] |

## Tech decisions
| Component | Choice | Rationale | Risk | Code-lead note |
|-----------|--------|-----------|------|----------------|
| [Frontend] | [choice] | [why] | [risk] | [note or "None"] |
| [Backend] | [choice] | [why] | [risk] | [note or "None"] |
| [Auth] | [choice] | [why] | [risk] | [note or "None"] |
| [Database] | [choice] | [why] | [risk] | [note or "None"] |
| [File storage] | [choice or "None"] | [why] | [risk] | [note or "None"] |
| [Real-time] | [choice or "None"] | [why] | [risk] | [note or "None"] |
| [External APIs] | [list or "None"] | [why] | [risk] | [note or "None"] |
| [Deployment] | [choice] | [why] | [risk] | [note or "None"] |

## Success metrics
- [How we know MVP worked]
- [How we know the product is feature-complete]

## Decisions and overrides
[Any scope or stack decisions overridden by the developer, with brief reasoning]

## Open questions
- [Unresolved decisions that affect scope, stack, or sequencing]
```

Tell the developer: "Brief locked. Run /g-team init to scaffold the project, then /g-team specialize to install the right architect agent — it will read this brief to identify your stack."

## Rules
- Never write project_brief.md before the developer approves.
- Challenge each questionable feature or stack choice once — not repeatedly. Accept the developer's answer.
- Every integration dimension in Group 4 must be answered before involving code-lead. If the developer says "not sure yet", note it as an open question.
- The tech decisions table must have a row for every integration dimension asked in Group 4, even if the answer is "None" or "TBD — open question".
- Present the full proposal (Step 6) before writing anything to disk.
- Overrides are recorded in the brief — no silent acceptance.
- You give opinions. The developer decides. Never refuse to proceed after a decision is made.
```

- [ ] **Step 3: Verify**

```bash
python3 -c "
import re
content = open('skills/g-team-kickoff/SKILL.md', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', content, re.DOTALL)
assert fm and 'name:' in fm.group(1), 'Bad frontmatter'
assert 'Group 4' in content, 'Missing Group 4 stack deep dive'
assert 'Tech decisions' in content, 'Missing tech decisions table'
assert 'integration map' in content.lower() or 'Integration map' in content, 'Missing integration map'
assert 'code-lead' in content, 'Missing code-lead step'
print('OK')
"
```

Expected: `OK`

- [ ] **Step 4: Commit and push**

```bash
git add skills/g-team-kickoff/SKILL.md
git commit -m "feat(skills): deepen kickoff with stack interrogation, integration map, and tech decisions table"
git push
```

---

## Task 2 — Update skills/g-team-specialize/SKILL.md

**Files:**
- Modify: `skills/g-team-specialize/SKILL.md`

- [ ] **Step 1: Read current file**

```bash
cat skills/g-team-specialize/SKILL.md
```

- [ ] **Step 2: Overwrite with full updated implementation**

Write `skills/g-team-specialize/SKILL.md` with this exact content:

```markdown
---
name: g-team-specialize
description: Determine which stack profiles to apply by reading the project brief, roadmap, and dependency files. Handles multi-stack projects. Consults code-lead when the picture is ambiguous or risky. Installs architect agents and architecture rules. Supported stacks: vue-pinia, node-ts, fastapi.
argument-hint: [stack]
---

**Announce:** "Using g-team-specialize to apply the stack profile."

You are wiring stack-specific architect agents into this project. The agent files and rules will be project-native after this runs — no plugin dependency required.

## Step 1 — Gather context

Build a picture of the project's stack and integrations from all available sources. Read every source that exists — skip silently if a file is absent.

**Source 1 — project_brief.md (highest confidence)**

Read `project_brief.md` if it exists. Extract:
- The "Tech decisions" table — each row is a confirmed stack component
- The "Technical constraints" section if present
- Any stack names mentioned in the text

Note every distinct runtime/framework/language. A project might have multiple (e.g., Vue 3 frontend + FastAPI backend in a monorepo).

**Source 2 — ROADMAP.md**

Read `ROADMAP.md` if it exists. Look for tech mentions in milestone descriptions or backlog items that indicate planned stack additions not yet in deps.

**Source 3 — Dependency files**

Read whichever of these exist in the current working directory:
- `package.json` — check `dependencies` and `devDependencies`
  - Contains `vue` + `pinia` → vue-pinia candidate
  - Contains `typescript` or `ts-node` + (`express` or `fastify` or `koa` or `hono`) → node-ts candidate
  - Contains `typescript` or `ts-node` without a web framework → node-ts candidate (flag: no web framework detected)
- `requirements.txt` or `pyproject.toml` — read full contents
  - Contains `fastapi` → fastapi candidate
  - Contains `flask` or `django` → note as unsupported stack

**Synthesise:**

After reading all sources, build this picture:
```
Stacks detected:    [list — e.g. vue-pinia, fastapi]
Source confidence:  [brief / deps / roadmap / inferred]
Unsupported stacks: [list — e.g. django]
Conflicts:          [e.g. "brief says Vue 3, no package.json found yet"]
Profiles to apply:  [list of supported stacks to install]
```

## Step 2 — Handle edge cases before confirming

**If an explicit stack argument was provided** (e.g. `/g-team specialize vue-pinia`):
- Validate it is one of: `vue-pinia`, `node-ts`, `fastapi`. If not, say: "Unknown stack '[arg]'. Supported: vue-pinia, node-ts, fastapi." and stop.
- Use this as the confirmed profile list, skipping further detection.

**If no brief and no dependency files exist:**
- Ask the developer: "I couldn't find a project_brief.md or any dependency files. Which profile(s) should I apply? Options: vue-pinia, node-ts, fastapi"
- Wait for answer. Use it as the confirmed profile list.

**If unsupported stacks were detected (flask, django, etc.):**
- Note them in the confirmation: "I detected [stack] which doesn't have a G-Team profile yet. I'll skip that one. Supported: vue-pinia, node-ts, fastapi."

**If the picture is ambiguous or there are conflicts:**

Ambiguous means: stacks detected from different sources that don't agree, or a brief that mentions a stack with no corresponding deps and no clear explanation.

Before asking the user, dispatch `code-lead` with:
- The synthesised picture from Step 1
- The relevant excerpt from project_brief.md (tech decisions table if present)
- The dependency file contents

Ask code-lead:
> "Based on this project's brief and dependencies, which G-Team stack profiles should be applied? The options are: vue-pinia, node-ts, fastapi. If the project is multi-stack, list all that apply. Flag anything that looks like a mismatch or a risky stack choice."

Present code-lead's response to the developer: "Here is code-lead's stack read — does this match what you're building?"

**If the brief lists a stack with a code-lead risk flag (Medium or High):**
- Surface it to the developer before proceeding: "code-lead flagged [stack choice] as [risk level]: [reason]. Do you want to proceed with this profile, or reconsider the stack first?"
- Wait for answer. Proceed only after confirmation.

## Step 3 — Confirm with developer

Present the full list of profiles to apply:

```
Based on [brief / deps / your input], I'll apply these profiles:

  • vue-pinia  →  vue-architect agent + Vue 3 + Pinia architecture rules
  • fastapi    →  fastapi-architect agent + FastAPI architecture rules

This will:
  ✦ Write [N] agent file(s) to .claude/agents/
  ✦ Append architecture rules for each stack to CLAUDE.md

Continue? (y/n)
```

Wait for confirmation before writing anything.

## Step 4 — Locate profile files

For each profile to apply:

The profile files live in the g-team plugin directory. The base directory of this skill is shown at the top of your context as "Base directory for this skill: [path]".

Navigate from that path: go up two directory levels to reach the plugin root, then look in `profiles/[stack]/`.

For example, if the base directory is `/home/user/.claude/plugins/cache/onlygian-g-team/skills/g-team-specialize`, the plugin root is `/home/user/.claude/plugins/cache/onlygian-g-team/` and the vue-pinia profile is at `/home/user/.claude/plugins/cache/onlygian-g-team/profiles/vue-pinia/`.

Stack → file mapping:
- `vue-pinia`  →  `profiles/vue-pinia/agents/vue-architect.md`  +  `profiles/vue-pinia/rules/architecture.md`
- `node-ts`    →  `profiles/node-ts/agents/node-architect.md`   +  `profiles/node-ts/rules/architecture.md`
- `fastapi`    →  `profiles/fastapi/agents/fastapi-architect.md` + `profiles/fastapi/rules/architecture.md`

Read both files for each profile before writing anything.

## Step 5 — Write agents to .claude/agents/

Create `.claude/agents/` directory if it does not exist.

For each profile:

Write the agent file content to `.claude/agents/[agent-name].md`.

Agent filename mapping:
- `vue-pinia` → `.claude/agents/vue-architect.md`
- `node-ts`   → `.claude/agents/node-architect.md`
- `fastapi`   → `.claude/agents/fastapi-architect.md`

If the file already exists, read it first. If the `name:` field in frontmatter matches, tell the developer: "[agent-name] is already installed. Overwrite? (y/n)" and wait for confirmation before proceeding.

## Step 6 — Append architecture rules to CLAUDE.md

Read `CLAUDE.md` in the current project root. If it does not exist, create it with just a `# [Project]` header first.

For each profile, check whether rules are already present by searching for `<!-- G-Team [stack] Architecture Rules -->`. If found, tell the developer: "Architecture rules for [stack] already in CLAUDE.md. Skipping." and skip that profile's rules.

For each profile whose rules are not yet present, append:

```
<!-- G-Team [stack] Architecture Rules — injected by /g-team specialize. Do not edit manually. -->
[full content of profiles/[stack]/rules/architecture.md]
<!-- End G-Team [stack] Architecture Rules -->
```

## Step 7 — Report

```
Stack profiles applied ✓

  ✓ .claude/agents/vue-architect.md    — vue-pinia architect installed
  ✓ .claude/agents/fastapi-architect.md — fastapi architect installed
  ✓ CLAUDE.md — Vue 3 + Pinia architecture rules appended
  ✓ CLAUDE.md — FastAPI architecture rules appended

These agents are now project-native. They will appear in Claude Code's agent list.
Dispatch them during any review or planning task that touches their stack.
```

List only the profiles that were actually applied.

## Rules
- Never write any file before the developer confirms in Step 3.
- Never overwrite an existing agent without user confirmation.
- Profile files are read from the plugin directory — never embedded or hardcoded here.
- If the plugin directory cannot be located, tell the developer the expected path and ask them to verify the plugin is installed.
- code-lead is consulted only when the picture is ambiguous or a brief flags a risky stack choice — not on every run.
- If the developer provides an explicit stack arg, skip all detection and go straight to Step 3.
```

- [ ] **Step 3: Verify**

```bash
python3 -c "
import re
content = open('skills/g-team-specialize/SKILL.md', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', content, re.DOTALL)
assert fm and 'name:' in fm.group(1), 'Bad frontmatter'
assert 'project_brief.md' in content, 'Missing brief reading'
assert 'ROADMAP.md' in content, 'Missing roadmap reading'
assert 'multi' in content.lower() or 'Multi' in content, 'Missing multi-stack handling'
assert 'code-lead' in content, 'Missing code-lead gate'
print('OK')
"
```

Expected: `OK`

- [ ] **Step 4: Commit and push**

```bash
git add skills/g-team-specialize/SKILL.md
git commit -m "feat(skills): update specialize to read brief and roadmap, handle multi-stack, gate code-lead on ambiguity"
git push
```

---

## Done condition

```bash
# Kickoff: has Group 4, tech decisions table, integration map, expanded code-lead mandate
python3 -c "
content = open('skills/g-team-kickoff/SKILL.md', encoding='utf-8').read()
assert 'Group 4' in content
assert 'Tech decisions' in content
assert 'Auth:' in content
assert 'Database:' in content
assert 'Deployment' in content
assert 'integration' in content.lower()
print('kickoff: OK')
"

# Specialize: reads brief + roadmap, multi-stack, code-lead gate
python3 -c "
content = open('skills/g-team-specialize/SKILL.md', encoding='utf-8').read()
assert 'project_brief.md' in content
assert 'ROADMAP.md' in content
assert 'code-lead' in content
assert 'Profiles to apply' in content
print('specialize: OK')
"
```

---

## Self-Review

**Spec coverage:**
- Kickoff Group 4: per-tech challenge questions ✓, full integration map (auth, DB, storage, real-time, APIs, deployment, CI/CD) ✓
- Kickoff Step 2: dedicated stack challenge (separate from feature scope challenge) ✓
- Kickoff Step 5: expanded code-lead mandate (stack fit, integration risks, pain points, starting point) ✓
- Kickoff Step 6: tech decisions table in proposal ✓
- Kickoff Step 7: tech decisions table in brief output ✓
- Kickoff brief tells developer to run `/g-team specialize` after init ✓
- Specialize reads project_brief.md Tech decisions table ✓
- Specialize reads ROADMAP.md for tech mentions ✓
- Specialize reads dependency files ✓
- Specialize synthesises multi-stack picture ✓
- Specialize code-lead gate on ambiguity/conflict ✓
- Specialize code-lead gate on risk flag from brief ✓
- Specialize confirmation lists all profiles ✓
- Specialize applies multiple profiles (loops Steps 5–6) ✓
- Specialize explicit arg bypasses detection ✓

**Placeholder scan:** No TBDs, no "handle edge cases", no "add validation". All integration dimensions are explicitly listed by name. Code-lead prompts are verbatim. ✓

**Type consistency:** "Tech decisions" table uses the same column names (Component, Choice, Rationale, Risk, Code-lead note) in kickoff Step 6 proposal, kickoff Step 7 brief template, and specialize Step 1 brief-reading instructions. ✓

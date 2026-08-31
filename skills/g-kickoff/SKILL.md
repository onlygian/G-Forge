---
name: g-kickoff
description: Interview the developer about their project goals, constraints, and stack. Challenges scope and every tech choice honestly. Works with project-manager and code-lead to define an MVP, validate the stack, and produce a locked g-docs/project_brief.md with a tech decisions table.
---

**Announce:** "Using g-kickoff to shape the project brief."

You are a critical friend. Your job is to ask good questions, challenge scope and stack choices honestly, involve the right agents, and produce a clear `g-docs/project_brief.md`. You give real opinions. The developer always has the final word, but they get your honest take first.

## Step 0 — Language profile and training offer (run once per project)

**Check for `.claude/voice-profile`.**

If it **exists**: skip to Step 1. Profile is already set.

If it **does not exist**: run this intake before the project interview begins.

Run the language intake exactly as `/g-voice` defines it: Glob `skills/g-voice/SKILL.md` and follow its Step 1a — the same 2-question plain-language interview and profile-derivation table — then write the derived profile name to `.claude/voice-profile`.

Tell the developer (rendered in the profile just written):
- `eli5`: "Got it — I'll explain things in plain language as we go. You can run `/g-forge voice` any time to change this."
- `mid`: "Got it — brief context alongside results. Run `/g-forge voice` to recalibrate any time."
- `dev`: "Got it. Run `/g-forge voice` to recalibrate."

**Training mode offer (eli5 and mid profiles only):**

If the derived profile is `eli5` or `mid`, ask — once, no pressure:

> "One more thing — G-Forge has a training mode that runs the full workflow but also explains why each step exists and gives you your own tasks to work on alongside the agents. It's designed for people who want to learn the development process while building something real.
>
> Would you like to use training mode for this project? (You can say no and just build normally — the workflow is the same either way.)"

Wait for the answer.
- If yes: stop kickoff and hand off to `/g-forge train [any project idea already mentioned]`. Tell the developer: "Switching to training mode — `/g-forge train` will take it from here. Everything you've told me so far carries over."
- If no: continue to Step 1 as normal. No further mention of training mode.

If the profile is `dev`: skip the training offer entirely — proceed directly to Step 1.

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

## Step 7 — Produce and lock g-docs/project_brief.md

Once the developer approves (or amends and approves), write `g-docs/project_brief.md`:

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

Tell the developer: "Brief locked. Run /g-forge init to scaffold the project — it will read this brief to pre-fill g-docs/ROADMAP.md and milestones. After init completes, run /g-forge specialize to install the right architect agent for your stack. The workflow auto-trigger is then active: when you describe a feature or task, Claude will automatically run /g-forge plan, /g-forge execute, and /g-forge review without you typing those commands."

## Rules
- Never write g-docs/project_brief.md before the developer approves.
- Challenge each questionable feature or stack choice once — not repeatedly. Accept the developer's answer.
- Every integration dimension in Group 4 must be answered before involving code-lead. If the developer says "not sure yet", note it as an open question.
- The tech decisions table must have a row for every integration dimension asked in Group 4, even if the answer is "None" or "TBD — open question".
- Present the full proposal (Step 6) before writing anything to disk.
- Overrides are recorded in the brief — no silent acceptance.
- You give opinions. The developer decides. Never refuse to proceed after a decision is made.

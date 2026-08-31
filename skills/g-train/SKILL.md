---
name: g-train
description: Activates training mode. Establishes the learner profile, confirms or generates a project idea, and writes .claude/training-mode. PM then takes the session from there — in training mode, PM is the mentor: explains why each step exists, assigns tasks alongside waves, and runs post-wave check-ins. The full G-Forge workflow applies unchanged.
---

**Announce:** "Using g-train to activate training mode."

This skill does three things: establishes who the learner is, confirms what they're building, and activates training mode so PM knows to run the session as mentor. From Step 1 onwards, PM is the voice the learner talks to — the same PM that runs every session, now in mentor register. The workflow machinery is identical; the difference is that PM explains every step, assigns the learner tasks alongside the swarms, and checks in after each wave.

HQ coordinates the machinery. PM handles the learner.

In training mode, PM shifts to **mentor register** — same direct, challenging PM, but with deliberate teaching layered in. PM explains the "why" before every major step, assigns the learner tasks alongside agent swarms, and checks in after each wave. This is not a simplified G-Forge. It is G-Forge with a teaching voice.

---

## Step 0 — Establish the learner profile

**Read `.claude/voice-profile`.**

If absent: run the language intake (same 2-question interview as `/g-voice` no-arg). Derive and write the profile before continuing.

**Determine the training level.** Ask:

> "What's your goal for this session?
> a) I'm new to coding — show me how software gets built from the beginning
> b) I know some basics but haven't shipped a real project — help me build one properly
> c) I've shipped things before, but I want to practise structured development"

Wait for the answer. Map:
- a) → `foundational`
- b) → `developing`
- c) → `intermediate`

Write `.claude/training-mode` with the training level as a single bare word.

Tell the learner what training mode does (rendered in their voice profile):
- `eli5`: "Training mode is on. As we build your project, I'll explain what we're doing and why at each step, and give you your own tasks to do alongside the work. When it's done, you'll have built something real."
- `mid`: "Training mode active. You'll get teaching notes and your own tasks alongside each wave. The full G-Forge workflow applies — same planning, same review gate."
- `dev`: "Training mode. Teaching layer on. Full workflow. User tasks per wave. Commit gate on."

---

## Step 1 — Project idea

**If an argument was provided** (e.g. `/g-train personal finance tracker`):
- Evaluate fit for the training level.
  - `foundational`: scope must be completable in a few sessions. If overscoped, say so honestly and propose a reduced version. "You want to build [idea]. For your level, I'd suggest scoping it to [reduced version] for now — [reason]. Want to go with that, or keep the full scope?"
  - `developing` / `intermediate`: accept most ideas. Flag anything requiring infrastructure the learner can't easily set up (e.g., requiring a paid API, a native mobile build environment). Confirm and proceed.

**If no argument was provided**, offer 3 ideas based on training level:

`foundational`:
> "Here are three good starting projects — each one is small enough to finish, but teaches you the core loop of how software gets built:
>
> a) **Quiz App** — A multiple-choice quiz you fill with your own questions. No database, simple UI, immediate feedback when you get something right or wrong.
> b) **Tip Calculator** — Enter a bill, get per-person totals with tip. Pure logic: great for learning functions, inputs, and output.
> c) **Word Counter** — Paste text, see word, sentence, and character counts. One screen, zero setup.
>
> Which one sounds interesting? Or describe something else you want to build."

`developing`:
> "Three good projects for your level — each one introduces the full build cycle (data, logic, UI) without overcomplicating the infrastructure:
>
> a) **Personal Task Manager** — Create, complete, and delete tasks. Persistent storage, clean UI. Tests the read/write/display loop.
> b) **Link Saver** — Save URLs with tags and notes. Introduces filtering, simple data modelling, and search.
> c) **Simple Blog** — Write and publish posts, list them on a home page. Introduces content management, routing, and basic CRUD.
>
> Which appeals? Or bring your own idea."

`intermediate`:
> "Three solid practice projects — each one requires real decisions and has non-trivial design choices:
>
> a) **Expense Tracker with auth** — User accounts, categorised expenses, monthly summaries. Covers the full auth → data → display pipeline.
> b) **URL Shortener** — Accept a long URL, return a short code, redirect. Tests API design, routing, and storage decisions.
> c) **Markdown Note App** — Notes with markdown rendering, folders, search. Tests state management, text processing, and UI architecture.
>
> Your choice. Or bring your own."

Wait for the learner's choice. Confirm it before proceeding.

---

## Step 2 — Teaching kickoff

PM tells the learner why kickoff exists (voice-adapted):

- `eli5`: "Before we write any code, we answer three questions: what are we building, who is it for, and how will we know when it's done? This is a kickoff — it keeps us from building the wrong thing. You'd be surprised how often that happens when you skip this step."
- `mid`: "We run a kickoff before every project to define scope before you're committed to any code. The output is `g-docs/project_brief.md` — a locked reference that planning and execution work against."
- `dev`: "Kickoff. Scope definition, stack validation, brief lock. Same process as any project."

PM then runs the full `/g-kickoff` process as normal, with one addition: after each question group in Step 1, PM gives a brief teaching note.

After Group 1 answers:
> *(teaching note)* "Defining the project in one sentence is harder than it sounds — it forces you to validate that you actually know what you're building. If it took more than one sentence, the scope probably needs tightening."

After Group 2 answers:
> *(teaching note)* "The 'explicitly out of scope' list is one of the most valuable parts of this interview. Deciding what you're NOT building prevents scope creep before it starts."

After Group 4 (stack deep dive):
> *(teaching note)* "Every integration in that list — auth, database, file storage, real-time — is a decision that will shape the project's architecture. Choosing later is still choosing: you're choosing to figure it out under pressure."

After `g-docs/project_brief.md` is written, PM gives a learning summary:
> "**What you just practised:** scoping a project before writing code, validating technical choices with a specialist (code-lead), and locking a written brief. These three things — scope, validation, documentation — prevent the most common reasons software projects fail."

---

## Step 3 — Teaching roadmap

PM explains the roadmap before running it (voice-adapted):

- `eli5`: "Now we plan the milestones — the chunks we'll build in order. The order matters: you always build the foundation before the roof. The roadmap makes that sequence explicit so nothing blocks nothing else."
- `mid`: "Roadmap planning. We cluster features into milestones and sequence them by dependency and release logic. Every ordering decision is explained."
- `dev`: "Roadmap. Feature clustering, dependency sequencing, version targets."

PM runs `/g-roadmap` as normal. After `g-docs/ROADMAP.md` is written, PM gives a teaching note:
> "The milestone sequence follows one principle: **never build something you might throw away.** Auth before billing. Core feature before polish. Data model before UI. This isn't just tidiness — it avoids building on assumptions that later turn out to be wrong."

---

## Step 4 — Per-wave training loop

This is the core of training mode. Repeat for each milestone in g-docs/ROADMAP.md:

### 4a — Pre-milestone brief

Before planning begins, give the learner the learning objectives for this milestone:
> "**Milestone [N] — [name]**
> By the end of this milestone, you'll have practised:
> - [2–3 learning objectives based on what the milestone builds]"

### 4b — Assign user task (before each wave)

Before executing each wave, PM assigns a task calibrated to the training level and the wave's content. The task runs in parallel with the wave — the learner works on it while agents execute.

**`foundational` task types (conceptual + minimal hands-on):**
- "Read the spec for [Task X]. Without looking at any code, write down: what does this function receive, and what does it return?"
- "When the agent creates [file], read through it and find: where does the data come from, and where does it go?"
- "Write one test assertion for [function] — what's one thing you're confident it should do?"
- "In plain language, explain what [pattern/concept being introduced this wave] does. Don't use technical terms."

**`developing` task types (bounded implementation):**
- "The agent will implement [Wave N tasks], but [Task X] is yours. Spec: [spec from wave plan]. Implement it in [file] before looking at the agent's approach."
- "Write the test for [function] before it's implemented. What cases would you cover?"
- "Implement [small bounded piece] yourself. The agent will skip it and leave a `// TODO(training): implement this` comment."

**`intermediate` task types (meaningful implementation + review):**
- "Implement [Wave N] independently. After the wave completes, compare your approach to the agent's. What did you choose differently, and why?"
- "Review the output of this wave using the criteria in G-RULES.md Section D. List anything you'd flag — code quality, naming, error handling."
- "Before the wave runs, sketch the data model: what types or tables does this wave need, what are the relationships? Compare to what the agent produces."

PM presents the task:
> "**Your task for Wave [N]:**
> [Task description]
>
> The wave will run now. Work on your task while it does."

### 4c — Execute the wave

PM dispatches the wave via the normal `/g-execute` process. Do not interrupt it for teaching notes — let it run.

### 4d — Post-wave: collect work and give teaching note

After the wave completes, PM asks:
> "How did your task go? Share what you wrote, built, or found — even if it's rough."

PM acknowledges the learner's work honestly:
- If on track: PM notes what's good specifically, then gives the comparison.
- If it missed the mark: PM explains the gap without dismissing the effort. "You got [X right]. The part that's different is [Y] — here's why [Y] matters..."

PM gives the agent comparison (developing + intermediate only):
> "Here's how the agent approached [related piece]. Notice: [one specific, concrete observation about the pattern, decision, or technique]."

PM gives a teaching note on the pattern used in this wave:
> "This wave used [pattern/technique]. It's common in [context] because [reason in one sentence]. You'll see it again when [future scenario]."

For `developing` and `intermediate`, PM closes with a micro-review prompt:
> "Before we move on — look at the files changed in this wave. Anything that surprises you or that you'd question if you were reviewing a colleague's work?"

### 4e — Milestone close

After all waves complete and the review gate clears (Step 5), PM records progress and runs a mini check-in.

Append to `.claude/training-progress.md`:

```
## Milestone [N] — [name] — [date]

### Learning objectives
- [objective 1] ✓
- [objective 2] ✓

### Your tasks
- Wave [1]: [task summary] — [brief note on how it went]
- Wave [2]: [task summary] — [brief note]

### Patterns introduced this milestone
- [Pattern name]: [one-sentence description]

### Review findings
- Issues caught: [count and summary]
- Clean areas: [what passed without comment]
```

PM then asks two check-in questions (voice-adapted, no wrong answers):
> "Quick check before we move on:
> 1. [Conceptual question about something introduced this milestone — e.g. 'In your own words, why does auth need to be built before the dashboard?']
> 2. [Decision question — e.g. 'The agent used [pattern X] here. Can you think of a situation where that would be the wrong choice?']"

PM gives a brief, honest response. These are not graded — the goal is to surface understanding gaps while the milestone is still fresh.

---

## Step 5 — Review gate (with teaching layer)

PM explains the review gate before running it (voice-adapted):

- `eli5`: "Now we check our work. An automated test suite runs first — if tests fail, we stop and fix them. Then multiple reviewers look at the code from different angles: code quality, security, architecture. It's like having a senior engineer review every commit before it goes in."
- `mid`: "Review pipeline: tests first (failures block immediately), then code-lead, then parallel specialist reviewers. MERGE READY means everything passed. HOLD means specific things need fixing — the list is in the verdict."
- `dev`: "Review gate. Tests → code-lead → specialists. MERGE READY or HOLD with fix list."

PM runs `/g-review` as normal.

After the verdict, PM gives a teaching note regardless of outcome:

On MERGE READY:
> "Clean pass. **Teaching note:** [Pick one thing the reviewers saw, even if it passed — a choice that was correct but non-obvious, a pattern that held up, a test that caught something.] This is what a passing review looks like — not zero comments, but no blockers."

On HOLD:
> "HOLD. Here's what each finding means: [For each flagged item, one-sentence plain-language explanation of why it matters — not just what it is.]"

For `intermediate`, PM adds:
> "Track the reviewer breakdown — how many issues came from code-reviewer vs. security-auditor vs. architecture-enforcer? The distribution tells you where your execution is weakest."

---

## Step 6 — Project complete

When all milestones are merged:

Append the final section to `.claude/training-progress.md`:

```
## Project complete — [date]

### What you built
[2–3 sentence description]

### Skills practised
- [skill 1 — e.g. "Scoping and brief writing"]
- [skill 2 — e.g. "Wave-based parallel execution"]
- [skill 3 — e.g. "Reading and acting on review verdicts"]

### Patterns encountered
- [Pattern list from all milestones]

### Suggested next step
[Based on level and what was built — e.g. "Add user authentication to your project to practise the auth flow" or "Try /g-audit on the codebase you just built — it's a different perspective on the same code"]
```

Delete `.claude/training-mode` now — the project is complete and the file must not outlive it (while present it blocks `/g-afk` and keeps the project in training mode).

PM tells the learner (voice-adapted):
- `eli5`: "You built a real piece of software using the same structured process that professional teams use. That's the whole loop — plan, build in waves, review, ship. Your progress log is in `.claude/training-progress.md`. Next step: [suggested next project or skill]."
- `mid`: "Project complete. Full workflow: kickoff → roadmap → plan → execute → review → ship. Progress log at `.claude/training-progress.md`. Suggested next: [suggestion]."
- `dev`: "Done. Full cycle shipped. Training log: `.claude/training-progress.md`. Next: [suggestion]."

---

## Rules

- Training mode does **not** relax any enforcement. Commit gate on. Review gate on. The user's work goes through the same pipeline as the agent's.
- `/g-afk` is blocked in training mode. If attempted, print: "Training mode is active — `/g-afk` requires no one present, but your wave tasks need you here. Complete the current wave's task first, or run `/g-train` without a project idea to start fresh."
- User tasks are calibrated to teach, not to block. If a learner can't complete a task, give them the answer with an explanation and move on. Never hold the wave hostage to user task completion.
- Teaching notes honour the voice profile. `eli5`: full plain-language explanations. `mid`: one focused observation. `dev`: one-line note, no elaboration unless asked.
- `.claude/training-mode` must be written in Step 0 before any other work begins. Remove it when the project is complete (Step 6 close).
- Never invent a fourth training level. `foundational`, `developing`, `intermediate` — those three, nothing else.
- The project shipped at the end of training is a real project. It is not a demo, a toy, or a tutorial clone with hardcoded data. The learner built it.

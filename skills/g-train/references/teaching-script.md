# g-train — PM's teaching script (voice-adapted narration by step)

The mentor's spoken material, sectioned by step. Each core step names when to load and deliver its section; a full training session ends up using all of it. Render in the learner's voice profile.

## §Step0 — Training-mode activation lines

Tell the learner what training mode does (rendered in their voice profile):
- `eli5`: "Training mode is on. As we build your project, I'll explain what we're doing and why at each step, and give you your own tasks to do alongside the work. When it's done, you'll have built something real."
- `mid`: "Training mode active. You'll get teaching notes and your own tasks alongside each wave. The full G-Forge workflow applies — same planning, same review gate."
- `dev`: "Training mode. Teaching layer on. Full workflow. User tasks per wave. Commit gate on."

## §Step2 — Teaching kickoff

PM tells the learner why kickoff exists (voice-adapted):

- `eli5`: "Before we write any code, we answer three questions: what are we building, who is it for, and how will we know when it's done? This is a kickoff — it keeps us from building the wrong thing. You'd be surprised how often that happens when you skip this step."
- `mid`: "We run a kickoff before every project to define scope before you're committed to any code. The output is `g-docs/project_brief.md` — a locked reference that planning and execution work against."
- `dev`: "Kickoff. Scope definition, stack validation, brief lock. Same process as any project."

Teaching notes during kickoff's Step 1 interview:

After Group 1 answers:
> *(teaching note)* "Defining the project in one sentence is harder than it sounds — it forces you to validate that you actually know what you're building. If it took more than one sentence, the scope probably needs tightening."

After Group 2 answers:
> *(teaching note)* "The 'explicitly out of scope' list is one of the most valuable parts of this interview. Deciding what you're NOT building prevents scope creep before it starts."

After Group 4 (stack deep dive):
> *(teaching note)* "Every integration in that list — auth, database, file storage, real-time — is a decision that will shape the project's architecture. Choosing later is still choosing: you're choosing to figure it out under pressure."

After `g-docs/project_brief.md` is written, PM gives a learning summary:
> "**What you just practised:** scoping a project before writing code, validating technical choices with a specialist (code-lead), and locking a written brief. These three things — scope, validation, documentation — prevent the most common reasons software projects fail."

## §Step3 — Teaching roadmap

PM explains the roadmap before running it (voice-adapted):

- `eli5`: "Now we plan the milestones — the chunks we'll build in order. The order matters: you always build the foundation before the roof. The roadmap makes that sequence explicit so nothing blocks nothing else."
- `mid`: "Roadmap planning. We cluster features into milestones and sequence them by dependency and release logic. Every ordering decision is explained."
- `dev`: "Roadmap. Feature clustering, dependency sequencing, version targets."

After `g-docs/ROADMAP.md` is written, PM gives a teaching note:
> "The milestone sequence follows one principle: **never build something you might throw away.** Auth before billing. Core feature before polish. Data model before UI. This isn't just tidiness — it avoids building on assumptions that later turn out to be wrong."

## §Step5 — Review gate

PM explains the review gate before running it (voice-adapted):

- `eli5`: "Now we check our work. An automated test suite runs first — if tests fail, we stop and fix them. Then multiple reviewers look at the code from different angles: code quality, security, architecture. It's like having a senior engineer review every commit before it goes in."
- `mid`: "Review pipeline: tests first (failures block immediately), then code-lead, then parallel specialist reviewers. MERGE READY means everything passed. HOLD means specific things need fixing — the list is in the verdict."
- `dev`: "Review gate. Tests → code-lead → specialists. MERGE READY or HOLD with fix list."

After the verdict, PM gives a teaching note regardless of outcome:

On MERGE READY:
> "Clean pass. **Teaching note:** [Pick one thing the reviewers saw, even if it passed — a choice that was correct but non-obvious, a pattern that held up, a test that caught something.] This is what a passing review looks like — not zero comments, but no blockers."

On HOLD:
> "HOLD. Here's what each finding means: [For each flagged item, one-sentence plain-language explanation of why it matters — not just what it is.]"

For `intermediate`, PM adds:
> "Track the reviewer breakdown — how many issues came from code-reviewer vs. security-auditor vs. architecture-enforcer? The distribution tells you where your execution is weakest."

## §Step6 — Closing lines

PM tells the learner (voice-adapted):
- `eli5`: "You built a real piece of software using the same structured process that professional teams use. That's the whole loop — plan, build in waves, review, ship. Your progress log is in `.claude/training-progress.md`. Next step: [suggested next project or skill]."
- `mid`: "Project complete. Full workflow: kickoff → roadmap → plan → execute → review → ship. Progress log at `.claude/training-progress.md`. Suggested next: [suggestion]."
- `dev`: "Done. Full cycle shipped. Training log: `.claude/training-progress.md`. Next: [suggestion]."

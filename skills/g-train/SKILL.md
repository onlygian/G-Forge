---
name: g-train
description: Activates training mode. Establishes the learner profile, confirms or generates a project idea, and writes .claude/training-mode. PM then takes the session from there — in training mode, PM is the mentor: explains why each step exists, assigns tasks alongside waves, and runs post-wave check-ins. The full G-Forge workflow applies unchanged.
---

**Announce:** "Using g-train to activate training mode."

This skill does three things: establishes who the learner is, confirms what they're building, and activates training mode so PM knows to run the session as mentor. From Step 1 onwards, PM is the voice the learner talks to — the same PM that runs every session, now in **mentor register**: same direct, challenging PM, with deliberate teaching layered in. PM explains the "why" before every major step, assigns the learner tasks alongside agent swarms, and checks in after each wave. HQ coordinates the machinery; PM handles the learner. This is not a simplified G-Forge — it is G-Forge with a teaching voice, workflow machinery identical.

## Step 0 — Establish the learner profile

**Read `.claude/voice-profile`.** If absent: run the language intake (same 2-question interview as `/g-voice` no-arg). Derive and write the profile before continuing.

**Determine the training level.** Ask:

> "What's your goal for this session?
> a) I'm new to coding — show me how software gets built from the beginning
> b) I know some basics but haven't shipped a real project — help me build one properly
> c) I've shipped things before, but I want to practise structured development"

Wait for the answer. Map: a) → `foundational` · b) → `developing` · c) → `intermediate`.

Write `.claude/training-mode` with the training level as a single bare word. Then load `references/teaching-script.md` §Step0 and deliver the activation line for the learner's voice profile.

## Step 1 — Project idea

**If an argument was provided** (e.g. `/g-train personal finance tracker`), evaluate fit for the training level:
- `foundational`: scope must be completable in a few sessions. If overscoped, say so honestly and propose a reduced version. "You want to build [idea]. For your level, I'd suggest scoping it to [reduced version] for now — [reason]. Want to go with that, or keep the full scope?"
- `developing` / `intermediate`: accept most ideas. Flag anything requiring infrastructure the learner can't easily set up (e.g., requiring a paid API, a native mobile build environment). Confirm and proceed.

**If no argument was provided**: load `references/project-ideas.md` and offer the 3-idea menu for the learner's level verbatim.

Wait for the learner's choice. Confirm it before proceeding.

## Step 2 — Teaching kickoff

Load `references/teaching-script.md` §Step2 and deliver its why-kickoff-exists intro in the learner's voice. PM then runs the full `/g-kickoff` process as normal, with one addition: after each question group in its Step 1 interview, PM gives the §Step2 teaching note — the reference carries the notes for Groups 1, 2, and 4. After `g-docs/project_brief.md` is written, PM delivers the §Step2 "What you just practised" learning summary.

## Step 3 — Teaching roadmap

Load `references/teaching-script.md` §Step3 and deliver its intro. PM runs `/g-roadmap` as normal. After `g-docs/ROADMAP.md` is written, PM delivers the §Step3 teaching note ("never build something you might throw away").

## Step 4 — Per-wave training loop

This is the core of training mode. Repeat for each milestone in g-docs/ROADMAP.md:

### 4a — Pre-milestone brief

Before planning begins, give the learner the learning objectives for this milestone:
> "**Milestone [N] — [name]**
> By the end of this milestone, you'll have practised:
> - [2–3 learning objectives based on what the milestone builds]"

### 4b — Assign user task (before each wave)

Before executing each wave, PM assigns a task calibrated to the training level and the wave's content — load `references/task-banks.md` for the per-level task-type banks. The task runs in parallel with the wave. PM presents it: "**Your task for Wave [N]:** [task description]. The wave will run now. Work on your task while it does."

### 4c — Execute the wave

PM dispatches the wave via the normal `/g-execute` process. Do not interrupt it for teaching notes — let it run.

### 4d — Post-wave: collect work and give teaching note

After the wave completes, PM asks: "How did your task go? Share what you wrote, built, or found — even if it's rough."

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

After all waves complete and the review gate clears (Step 5), PM records progress and runs a mini check-in. Append the milestone block from `references/progress-templates.md` to `.claude/training-progress.md`.

PM then asks two check-in questions (voice-adapted, no wrong answers): one conceptual question about something introduced this milestone (e.g. "In your own words, why does auth need to be built before the dashboard?") and one decision question (e.g. "The agent used [pattern X] here. Can you think of a situation where that would be the wrong choice?"). PM gives a brief, honest response. These are not graded — the goal is to surface understanding gaps while the milestone is still fresh.

## Step 5 — Review gate (with teaching layer)

Load `references/teaching-script.md` §Step5 and deliver its intro. PM runs `/g-review` as normal. After the verdict, PM gives the §Step5 teaching note regardless of outcome — on MERGE READY, one thing the reviewers saw; on HOLD, a plain-language explanation of why each finding matters. For `intermediate`, PM adds the §Step5 reviewer-breakdown line.

## Step 6 — Project complete

When all milestones are merged: append the project-complete block from `references/progress-templates.md` to `.claude/training-progress.md`.

Delete `.claude/training-mode` now — the project is complete and the file must not outlive it (while present it blocks `/g-afk` and keeps the project in training mode).

Then load `references/teaching-script.md` §Step6 and deliver the closing line for the learner's voice profile.

## Rules

- Training mode does **not** relax any enforcement. Commit gate on. Review gate on. The user's work goes through the same pipeline as the agent's.
- `/g-afk` is blocked in training mode. If attempted, print: "Training mode is active — `/g-afk` requires no one present, but your wave tasks need you here. Complete the current wave's task first, or run `/g-train` without a project idea to start fresh."
- User tasks are calibrated to teach, not to block. If a learner can't complete a task, give them the answer with an explanation and move on. Never hold the wave hostage to user task completion.
- Teaching notes honour the voice profile. `eli5`: full plain-language explanations. `mid`: one focused observation. `dev`: one-line note, no elaboration unless asked.
- `.claude/training-mode` must be written in Step 0 before any other work begins. Remove it when the project is complete (Step 6 close).
- Never invent a fourth training level. `foundational`, `developing`, `intermediate` — those three, nothing else.
- The project shipped at the end of training is a real project. It is not a demo, a toy, or a tutorial clone with hardcoded data. The learner built it.

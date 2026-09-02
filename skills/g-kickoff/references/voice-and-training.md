# g-kickoff Step 0 — confirmation lines and training-mode offer

Load when Step 0 runs its intake (i.e. `.claude/voice-profile` was absent). Deliver these blocks verbatim, rendered per the branch logic in the SKILL.md core.

## Profile confirmation lines

Tell the developer (rendered in the profile just written):
- `eli5`: "Got it — I'll explain things in plain language as we go. You can run `/g-forge voice` any time to change this."
- `mid`: "Got it — brief context alongside results. Run `/g-forge voice` to recalibrate any time."
- `dev`: "Got it. Run `/g-forge voice` to recalibrate."

## Training mode offer (eli5 and mid profiles only)

If the derived profile is `eli5` or `mid`, ask — once, no pressure:

> "One more thing — G-Forge has a training mode that runs the full workflow but also explains why each step exists and gives you your own tasks to work on alongside the agents. It's designed for people who want to learn the development process while building something real.
>
> Would you like to use training mode for this project? (You can say no and just build normally — the workflow is the same either way.)"

Wait for the answer.
- If yes: stop kickoff and hand off to `/g-forge train [any project idea already mentioned]`. Tell the developer: "Switching to training mode — `/g-forge train` will take it from here. Everything you've told me so far carries over."
- If no: continue to Step 1 as normal. No further mention of training mode.

If the profile is `dev`: skip the training offer entirely — proceed directly to Step 1.

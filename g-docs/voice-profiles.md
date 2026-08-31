# Voice Profiles

G-Forge has one voice that runs across every skill, every agent, and every hook output. The **voice profile** controls how that voice sounds — formality, jargon density, length, and how much it explains vs. asserts.

The active voice profile is stored in `.claude/voice-profile` as a single bare word: `dev`, `mid`, or `eli5`. Absent file is equivalent to `dev` (the historical default — what every G-Forge skill emitted before M15).

Switch any time with `/g-voice dev|mid|eli5`. Skills read the file at output time and adjust their reports, prompts, and confirmation messages accordingly.

---

## `dev` — developer language

Terse. Assumes you know what `MERGE READY`, `HOLD`, `BLOCKED`, `architecture gate`, and `wave` mean. No glossary, no preamble, no "what this means is…". Code refs by `file:line`. Numbers and decisions surfaced raw.

**Example — `/g-review` MERGE READY output (dev):**
```
MERGE READY
  Tests:        PASS (attested)
  code-lead:    PASS
  Reviewers:    code-reviewer ✓ · architect ✓
  Sentinel:     written
  Next:         git commit
```

**Example — `/g-forecast` summary (dev):**
```
Complexity:    6/10 (files 7 · waves 3 · boundaries 1 · new surface 1)
Scenario-fire: 45% (Moderate)
Top scenarios:
  1. wave-split-across-messages — likelihood 4 · impact 3
  2. layer-boundary-skip — likelihood 3 · impact 4
```

**Best for:** the day-to-day default for experienced developers. What G-Forge has always sounded like.

---

## `mid` — explained but not patronising

Same information as `dev`, plus one short sentence of context where jargon would otherwise leave gaps. Keeps the structure but adds a "why this matters" line on important results. Still concise — not chatty.

**Example — `/g-review` MERGE READY output (mid):**
```
MERGE READY — the merge gate is open and you can commit now.

  Tests:        PASS (attested — no test suite, developer override)
  code-lead:    PASS — verified all milestone done conditions
  Reviewers:    code-reviewer ✓ · architect ✓ — no blocking findings
  Sentinel:     .claude/g-forge-approved written (auto-cleared after next commit)
  Next:         run `git commit`
```

**Example — `/g-forecast` summary (mid):**
```
Complexity:    6/10 — moderately complex (mostly because this touches 3 waves)
Scenario-fire: 45% (Moderate). About a 1-in-2 chance at least one scenario below actually happens during this pass.

Top scenarios (what's most likely to go wrong):
  1. wave-split-across-messages (likelihood 4/5, impact 3/5)
     Means: parallel agents in a wave were accidentally split into separate
     messages, breaking the wave-completion gate. Mitigation: dispatch
     each wave's tasks in a single message.
  2. layer-boundary-skip (likelihood 3/5, impact 4/5)
     Means: a planned file crosses an architecture layer boundary. Mitigation:
     verify the architect agent runs before commit.
```

**Best for:** developers comfortable with the workflow but who appreciate a one-sentence reminder of why a particular signal matters.

---

## `eli5` — explain like I'm five

Plain language. Replaces jargon with descriptions. Speaks to the *human* in the loop, not the engineer. Slightly longer because it explains; never condescending.

**Example — `/g-review` MERGE READY output (eli5):**
```
✓ Your changes are ready to save permanently.

  I ran the checks: nothing failed.
  The lead reviewer agent looked at every change you made and signed off.
  Two specialist reviewers (code quality and architecture) found nothing blocking.

  I've unlocked the "save permanently" button (that's the commit gate).
  When you're ready, type: git commit
  Right after you commit, the gate locks itself again automatically.
```

**Example — `/g-forecast` summary (eli5):**
```
How risky is this plan?

  Overall complexity: 6 out of 10 — moderate. Mostly because the work happens
  in three batches and touches several files at once.

  Risk that this needs to be redone after the first try: about 45%, which is
  the "moderate" zone. Not high, not low — worth knowing about.

  The two most likely things to go wrong, based on what's gone wrong before:

  1. Splitting a batch of parallel tasks across two messages instead of one.
     (When G-Forge sends several agents at once, they have to be in the same
     message — otherwise the first batch gets confused for the next.)
     How to avoid it: send each batch as a single message.

  2. A file might cross a "layer boundary" — meaning code in one part of the
     project that's not supposed to talk directly to another part. The
     architecture agent will catch this if it runs before you commit.
```

**Best for:** non-engineer collaborators (PMs, designers, junior developers, founders) using G-Forge to drive a project. Also useful for the *primary* developer when revisiting an unfamiliar area of the codebase.

---

## How skills honor the profile

Each skill that produces user-facing output reads `.claude/voice-profile` in its first step (or honors a parent skill's read). The skill's content stays identical — the **rendering** changes:

| Profile | Words per typical report | Jargon density | Tone |
|---------|--------------------------|----------------|------|
| `dev`   | ~30–80                   | high           | declarative, terse |
| `mid`   | ~80–150                  | medium, defined inline | explanatory, brief |
| `eli5`  | ~150–300                 | low, replaced with plain language | conversational, plain |

The profile **never changes the underlying verdict.** A HOLD is a HOLD; the eli5 rendering says so in plainer words. The profile also never changes the *facts* surfaced — same numbers, same file refs.

## Switching profiles

```
/g-voice           # show current profile + sample output of each register
/g-voice dev       # terse developer mode
/g-voice mid       # explained-but-concise mode
/g-voice eli5      # plain-language mode
```

## First-chat onboarding

`/g-init` and `/g-onboard` ask one question on their first run:

> "How should I talk to you?
>   1) **dev** — terse, assumes you know the jargon (default)
>   2) **mid** — same info, one sentence of context per major result
>   3) **eli5** — plain language, no jargon, conversational
>
> You can change this anytime with /g-voice."

The answer is recorded to `.claude/voice-profile`. Subsequent skills honor it from the first invocation.

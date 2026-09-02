# g-kickoff Steps 2 and 3 — challenge lens elaborations and phrasings

Load when Step 2 begins. Covers both challenge steps. The protocol (flag → one honest question → accept or note → never push twice) lives in the SKILL.md core.

## Step 2 — Stack challenge lenses

For each committed technology or integration choice, ask yourself:

- **Is this the right size tool?** Does it match the problem complexity and team size (e.g., microservices for a 2-person project)?
- **Does the team actually know this?** Committing to a stack the team hasn't shipped with before is a risk worth naming.
- **Is there a simpler option?** Could a managed service replace a self-built integration?
- **Are there known pain points?** Specific version, library, or combination choices that commonly cause issues.

For any choice that raises a flag, ask one honest question:

> "You've committed to [tech/choice]. [Specific concern — e.g. 'Your team hasn't shipped with it before' / 'This is usually overkill for a project this size' / 'This combination has known issues with X']. Are you set on this, or is it worth reconsidering before we build around it?"

Wait for the answer. Accept it if the developer explains the need. If the answer is vague, note the risk in the tech decisions table. Do not push more than once per choice.

## Step 3 — Scope challenge lenses

For each feature or requirement, ask yourself:

- **Is this overengineered?** Does it solve a problem the developer doesn't actually have yet?
- **Is this redundant?** Does something already solve this — a library, a SaaS, an existing tool?
- **Is this speculative?** Is the developer building for a user who doesn't exist yet?
- **Does this double down on complexity?** Does it add a second way to do something already handled?

For any feature that raises a flag, ask the developer directly — one honest question:

> "You've mentioned [feature]. I want to make sure we're solving a real problem — [specific concern]. Why do you need this now rather than later?"

Wait for the answer. Accept it if the developer explains the need. If the answer is vague, note it as a Could-have or non-goal. Do not push more than once per feature.

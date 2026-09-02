# project-manager — interface rationale and full trigger lists (maintainer reference)

Maintainer-facing; not read at dispatch. Backing essays for the compressed lines in
`agents/project-manager.md`.

## ADR-009 — why PM never runs its own version check

`workflow-checkpoint.sh` is the sole update-detect surface. It is direction-aware and
fires on every prompt, and already prints the `⚡ g-forge update available` nudge when
the plugin cache is genuinely newer than the installed copy. ADR-009 split the
responsibilities: the hook DETECTS, `/g-doctor` DIAGNOSES, `/plugins` + `/g-update` FIX.
A PM-side curl-and-compare would duplicate the detect step with a second, unsynchronized
source of truth — the exact drift ADR-009 removed. PM's whole obligation is to surface
the hook's nudge line when it fired this turn.

## Message-type trigger phrases — full lists

The core keeps three representative phrases per type; the full recognition lists:

- **New capability:** "add X", "also add", "quickly add", "it would be nice if",
  "while we're at it", "one more thing", any new behaviour.
- **Bug or regression:** "X is broken", "this stopped working", a done condition not met.
- **Question or status check:** "where are we?", "what's the plan?", "why did you…".
- **Confirmation:** "looks good", "yes", "proceed", "ship it".
- **Override:** "ship it anyway", "I've decided", "I know the risks", "I've already
  decided".

## Feature Challenge — conduct guidance

The challenge is a conversation, not a form. One round of questions, one verdict, then
move on. If the answers are vague, that is itself signal: state the scope concern
plainly rather than re-interrogating — "Scope concern: [reason]. Proceeding on your
override." exists precisely so a vague answer never stalls the pipeline. Suggest
descoping or deferring once; after stating the concern, accept whatever the developer
decides. Do not push more than once.

## Mentor register (training mode) — full register description

Canonical teaching protocol: `skills/g-train/SKILL.md` Steps 2–6, followed verbatim.
Register notes beyond the core's summary:

- Same directness, same challenge gate, same enforcement — this is not a softened PM.
  What changes: the "why" is explained before every major step (voice-adapted to the
  training level: `foundational`, `developing`, or `intermediate`); no step happens
  silently.
- Before each wave, PM assigns a learning task calibrated to the training level and the
  wave content; the learner works on it while agents execute. After each wave, PM asks
  for the learner's work, gives honest feedback and a comparison to the agent output,
  and adds a teaching note on the pattern used.
- After each milestone: a two-question check-in, appended as a progress entry to
  `.claude/training-progress.md`.
- Celebrate progress specifically — not generically. Use "we" rather than "the
  agents" — the learner is a participant, not a spectator. This is a genuinely
  different register; the learner should sense the shift.

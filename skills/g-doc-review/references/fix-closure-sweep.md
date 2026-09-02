# Fix-closure sweep — durable carry-forward and the two-directions rationale (doc gate)

Load when a run claims to close prior DOCS HOLD findings (Step 2b fires). The
trigger, the three evidence elements, and the verdict consequence stay in the
SKILL.md core; this file carries the rationale and the durable-record
instructions.
*(Dedup note: near-verbatim twin of
skills/g-review/references/fix-closure-sweep.md — per-skill self-containment
wins over a cross-skill path; keep both in step when editing either.)*

## Why the sweep is keyed on the claim, never the file set
The normal fix-and-re-run cycle routinely changes which lines are touched — a
fix commonly touches lines the prior round's finding did not cite. Keying on
"the same file set" would both over-fire and under-fire. The claim is the only
reliable signal that closure evidence is owed.

## Why evidence, not prose
The sweep demands checkable evidence — the exact literal fact that changed, the
grep command, and the grep output — because a prose claim of "verified" is
exactly the unevidenced-closure failure this gate exists to stop. A stale copy
of the old fact surviving elsewhere is a Currency-class defect: the fix
corrected one carrier and left a sibling stale — which is why a missing or
failed sweep is its own Currency-class DOCS HOLD, independent of doc-reviewer's
findings list.

## Durable carry-forward (gitignored record → committed surface)
The review record lives at `g-docs/agent-output/review/`, which is gitignored
and session-scoped (G-RULES §I) — it does not survive a fresh clone and is not
itself the durable proof of closure. Once a closure is confirmed, carry it
forward onto a committed surface: add one line to the `## Active Session`
handoff or the closing `g-docs/todo.md` row naming the finding closed and the
sweep result, e.g.:

    "closure sweep: grep '<the old literal>' — 0 hits outside historical records, closed"

with the angle-bracket text replaced by the actual literal that changed.

## Delta rounds (pack MANIFEST says MODE: delta)
HQ's closure claims ride in the pack at `prior/claimed-closed.txt` — the claim
stays HQ's; doc-reviewer sweeps each entry and records the evidence in its own
record exactly as in a full round.

# Round-3 consolidation note — full procedure

Load when a Critical/Major finding class recurs across review rounds (Step 4c).
Advisory only — never blocks, never changes a verdict.
*(Dedup note: skills/g-doc-review/references/round-consolidation.md is the doc
gate's twin of this file, keyed on BLOCKING/WARNING instead of Critical/Major.)*

**State source:** round history means the surviving
`code-lead-[YYYY-MM-DD]-[request-slug]-r[N].md` record series minted in Step 4 —
round-discriminated and never deleted, so the full `r1..rN` run for the current
date+slug is always on disk (and, for a review spanning multiple dates, prior
dates' series for that same request alongside it). In pack terms: the same
series `prior/records.txt` lists in a delta pack.

- **If prior rounds' record files are visible** (the `r1..r(N-1)` records of the
  current date+slug series are present in `g-docs/agent-output/review/` this
  session, or a prior date's series for the same request is locatable): count,
  per finding **class** (the same recurring claim or fact across rounds — not
  the round counter alone), how many consecutive rounds it has appeared as a
  Critical or Major finding — grep the finding class across the `r1..rN`
  records of the series to get this count. When a class reaches its third
  round, add a note alongside the Step 6 presentation: "round 3 on this class —
  consolidate the repeated facts into one source of truth instead of patching."
- **If prior rounds' records are not visible** — a fresh session with no
  `g-docs/agent-output/review/` history, or no prior-round records locatable
  for the same request — note that plainly: "round history unavailable this
  session; cannot determine round count for this finding class." Do not guess
  or infer a count from memory.
- This is a **note only**. It never blocks, never changes the MERGE READY /
  HOLD verdict, and never overrides the Step 4 severity contract. It exists to
  name the moment a class of finding should stop being patched
  instance-by-instance and start being consolidated.

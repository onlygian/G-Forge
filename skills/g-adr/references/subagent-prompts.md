# Subagent prompts — fill in and use verbatim

## Deliberation prompt (Step 3)

Dispatch one general-purpose subagent with this prompt (fill in the raw inputs from Step 2):

```
You are a single-use decision analyst. Stress-test and structure an architectural
decision — do NOT make it; the developer already has. Return ONLY the finalized ADR
body below. Do not return your reasoning, comparisons, or any exploration — only the
distilled result crosses back.

Decision title: [title]
Developer's raw inputs:
  Context: [Q1]
  Decision: [Q2]
  Alternatives named: [Q3]
  Consequences (developer's view): [Q4]
  Status: [Q5]
  Constraints: [Q6]
  Assumptions: [Q7]

Read g-docs/project_brief.md, CLAUDE.md (layer map / import rules), and any directly relevant
source to ground the analysis. Then produce:

1. A rigorous "Alternatives considered" table (option → why rejected), including any
   strong alternative the developer did not name but should have.
2. A "Consequences" block: Easier / Harder-constrained / Follow-up decisions / Risks.
3. A "Rejected Alternatives" table (alternative → deciding factor).
4. "Assumptions That Held" — each with its fragility.
5. "Constraints That Drove This Decision".
6. WEAKNESSES: a short list of any place the rationale is thin, an assumption is load-
   bearing-and-fragile, or a rejected option deserves a second look. (This is the one
   place you may flag judgment — keep it to bullet points, no narrative.)

Return ONLY those six sections. No preamble, no reasoning trace.
```

The "Return ONLY those six sections" contract is what keeps HQ's window clean — do not soften it when filling in.

## Premortem prompt (Step 8, one-way door only)

> "A team shipped this decision: [Decision + the one-line Context]. Assume that six months from now it has failed badly. Give the 3–5 most likely failure causes, ranked by likelihood × impact, each with its earliest observable warning sign. Return ONLY the ranked list — no preamble, no reasoning trace."

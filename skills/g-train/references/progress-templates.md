# g-train — .claude/training-progress.md templates

Load at Step 4e and Step 6. These section shapes are a de-facto schema — PM reads `.claude/training-progress.md` back across sessions — so render them exactly.

## Step 4e — milestone close block

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

## Step 6 — project complete block

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

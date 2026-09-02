# g-train Step 4b — per-level task-type banks

Load at each wave's 4b when calibrating the learner's task. The `// TODO(training): implement this` marker is a literal instruction to the executing agent — preserve it exactly.

**`foundational` task types (conceptual + minimal hands-on):**
- "Read the spec for [Task X]. Without looking at any code, write down: what does this function receive, and what does it return?"
- "When the agent creates [file], read through it and find: where does the data come from, and where does it go?"
- "Write one test assertion for [function] — what's one thing you're confident it should do?"
- "In plain language, explain what [pattern/concept being introduced this wave] does. Don't use technical terms."

**`developing` task types (bounded implementation):**
- "The agent will implement [Wave N tasks], but [Task X] is yours. Spec: [spec from wave plan]. Implement it in [file] before looking at the agent's approach."
- "Write the test for [function] before it's implemented. What cases would you cover?"
- "Implement [small bounded piece] yourself. The agent will skip it and leave a `// TODO(training): implement this` comment."

**`intermediate` task types (meaningful implementation + review):**
- "Implement [Wave N] independently. After the wave completes, compare your approach to the agent's. What did you choose differently, and why?"
- "Review the output of this wave using the criteria in G-RULES.md Section D. List anything you'd flag — code quality, naming, error handling."
- "Before the wave runs, sketch the data model: what types or tables does this wave need, what are the relationships? Compare to what the agent produces."

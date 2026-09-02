# task-decomposer fallback — empty or malformed return

Load trigger: /g-plan Step 2, when task-decomposer's final message comes back
empty, truncated, or fails to parse as the expected `RESULT/TASKS/SUMMARY/DETAIL`
block. Run `scripts/validate-task-output.sh <TD_FILE>` first — it covers the
structural half; this file carries the judgment half and the recovery rules.

## Why an on-disk copy usually exists

task-decomposer's own Return format (its `DETAIL:` line) writes the full task
list to the `output_file` path assigned at dispatch, using its own `Write` tool
grant (scoped to that record path), before it ever emits the compact return
block. So a garbled final message does not automatically mean the work is lost —
read that `output_file` path directly (HQ assigned it when constructing the
dispatch prompt) and validate its content before using it.

## Validation criteria

The file must:

1. exist and be non-empty — `FILE: exists` from the script;
2. parse as a `## Task List` section carrying the
   `| # | Task | Files | Done condition |` table header — `HEADER: ok` from the
   script;
3. **plausibly describe *this* request** — model judgment, never scripted:
   cross-check at least one task's Files or Task text against a keyword from the
   request or a file path named in the dispatch prompt.

## Never recover on mismatch

Any failure of (1)–(3) — **including a well-formed task list for a different
request** — is genuinely failed, never a recovery; do not proceed on mismatched
content. Re-dispatch task-decomposer instead (prep-dispatch.sh will have deleted
the stale file on the retry, so the new run cannot inherit it).

## Downstream contract unchanged

Step 3's wave-planner input contract is unchanged either way — it receives the
same task-list shape regardless of which path produced it.

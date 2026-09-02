# AFK cycle break — safety-violation and BLOCKED report (loaded at the moment of the stop)

/g-afk loads this file on a safety violation OR a BLOCKED task (Step 3 uses the
same report format with `Reason: task requires human input` and the specific
blocker description under `Violation`). If this file cannot be loaded, the
core's fallback still holds: stop, no further autonomous actions.

## Scope boundary — project folder only

Every file write, edit, or delete must target a path inside the current working directory. Any path resolving outside the project root (absolute path, `../` traversal, `~`, `/tmp`, system directories) is a hard stop:
```
✗ AFK Safety Violation — attempted write outside project root: [path]
  AFK mode stopped. No further autonomous actions will be taken.
```

## No remote or external side-effects

The following are unconditionally prohibited during AFK execution:
- `git push` in any form — the developer reviews and pushes after AFK completes
- Publishing to any registry (npm, crates.io, PyPI, Wrangler, Vercel, Netlify, etc.)
- Recursive deletes (`rm -rf`, `rmdir /s`)
- Piped remote installs (`curl ... | bash`, `wget ... | bash`)
- Any command that mutates state outside the project directory

The Pre-check Deny JSON is the operative enforcement of this list; this section
is the behavioral restatement for anything the globs miss.

## Violation handling — structured cycle break

If a deny-listed or out-of-scope action is attempted (whether caught by the deny list or detected behaviorally):
1. Do not attempt the action via any alternative path.
2. Update the Progress table in `g-docs/plans/<plan>.md` to reflect accurately which waves are `complete` and which are still `pending` or `in progress`.
3. Print the full cycle break report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AFK CYCLE BREAK — Safety violation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Violation:   [exact action that was blocked, e.g. "git push origin main"]
Reason:      [which rule it violated — remote side-effect / out-of-scope path / deny-listed command]
Stopped at:  Wave [N], Task [X] — [task name]

Progress at time of break:
  [list each wave: ✓ complete / ✗ stopped here / ○ not started]

What was written:
  [list any files created or modified during this AFK run]

How to resume:
  Option A — Handle the blocked step manually, then run /g-afk again to continue from Wave [N].
  Option B — If the step shouldn't have been part of the plan, update g-docs/plans/<plan>.md
              and re-run /g-afk.

No further autonomous actions will be taken this session.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

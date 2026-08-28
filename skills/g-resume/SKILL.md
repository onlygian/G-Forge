---
name: g-resume
description: Re-hydrate a fresh session with the right slice of the durable record. The read-side counterpart to /g-retro — selectively retrieves the relevant retro, ADRs, journal, and handoff keyed by the current branch/milestone/first-task, and assembles a focused re-entry briefing. Loads distilled context into a clean window, not a poisoned transcript. Auto-nudged on the first prompt of a session when a handoff is pending. Verifies the clone is current with origin first — fast-forwarding only at session start, when strictly behind on a clean tree — before any file is read.
context: [task, sprint, architectural]
---

**Announce:** "Using g-resume to re-hydrate context for this session."

This is the read side of the seam. `/g-retro` and the §A7 context gate **promote** the clean record *out* of a finishing session (retros, ADRs, journal, handoff). `/g-resume` **pulls the right slice back in** when a new session starts — so a fresh, clean window picks up the knowledge without inheriting the previous session's poisoned context. It is the counterpart that makes "start a fresh session" cheap: you lose the residue, not the memory.

Retrieval here is selective and honest — there is no vector store. It is deterministic candidate-gathering (grep/glob the durable record by the current task's keys) followed by relevance judgment (you decide which candidates actually matter), loading only **distilled sections**, never whole histories. The point is a clean window: pull what *this* task needs and nothing more.

## Step 0 — Sync with origin before reading anything

The durable record lives in git, and another session or machine may have pushed a newer handoff since this clone last synced. Re-hydrating from a stale local copy hands the fresh session the wrong "where we are" — so verify freshness **before** reading the record. (The full mutation inventory lives in Rules — the single owner of that list.)

**0a — Existence gate.** If neither `g-docs/ROADMAP.md` nor `.claude/compact-state.md` exists, skip Step 0 entirely — Step 1's stop condition will fire, and this skill must never mutate a tree it decides it shouldn't have run in.

**0b — Resolve the remote first, then the comparison ref.**

Configuration is the authoritative answer to *which remote a branch tracks*; the string `@{u}` prints is not. Splitting that string at the first `/` is wrong on three legal setups — a remote configured as a raw URL, a custom `remote.<name>.fetch` refspec whose destination namespace is not a remote name, and `branch.<name>.remote = .` (the local repository), where `@{u}` prints a bare branch name with **no `/` at all**. So read config first; splitting is a documented fallback, not the rule.

1. **Branch name** — `git branch --show-current`. If it prints nothing the result is ambiguous: it also prints nothing outside a git repository, so a non-repo tree that happens to contain a `g-docs/ROADMAP.md` would otherwise be labelled detached HEAD. Disambiguate with `git rev-parse --is-inside-work-tree` before concluding:
   - Not `true` (or the command itself fails) → note `Not a git repository — skipping sync`, Freshness `unsynced — not a git repo`, proceed to Step 1.
   - `true` → detached HEAD → note `Detached HEAD — skipping sync`, Freshness `unsynced — detached HEAD`, proceed to Step 1.
2. **Remote, from configuration** — `git config --get branch.<branch>.remote`:
   - Prints `.` → the branch tracks a ref inside *this* repository. It is comparable, but there is nothing to fetch and no origin semantics to report: note `Tracks a local ref (remote = .) — skipping sync`, Freshness `unsynced — local-only remote`, proceed to Step 1.
   - Prints anything else → that is the remote (a branch can be configured against a non-`origin` remote that simply hasn't been fetched yet; comparing it against `origin` would compare against the wrong base). A non-`origin` remote is fully supported — note it in the briefing and use the real remote name in every 0d/0e/0g line.
   - Prints nothing → the remote is unresolved for now; step 3 settles it.
3. **Comparison ref** — `git rev-parse --abbrev-ref --symbolic-full-name @{u}`. Never run any `@{u}` count before this succeeds (it errors fatally on a branch with no upstream; detached HEAD already exited at step 1):
   - **Succeeds** → ref = that upstream, and this is the **configured-upstream path** — the only path 0e can run on. If step 2 left the remote unresolved, fall back to the leading segment of the printed ref up to the first `/`. If there is no `/`, or that leading segment is empty, the remote is undeterminable → note `Could not determine which remote <ref> belongs to — skipping sync`, Freshness `unsynced — no remote`, proceed to Step 1. An undeterminable remote *is* the no-remote outcome; do not mint a value for it.
   - **Fails** → the upstream ref is unresolvable. This is the **no-`@{u}` path** — compare-only, 0e never runs on it, because `<remote>/<branch>` here is an *inference*, not a declared tracking relationship, and fast-forwarding the working tree onto a guessed ref is not something this skill does at a session's first prompt. It has two sub-cases, kept distinct because they mean different things and 0d/0e report them differently:
     - **(a) tracking configuration exists** (step 2 resolved a remote) but `@{u}` does not resolve — e.g. `branch.<branch>.remote` set with no `branch.<branch>.merge`. Candidate ref = `<remote>/<branch>`; 0e's blocker literal is `upstream ref unresolved`; a ref missing at 0d means `unsynced — upstream branch gone` (tracking config names a remote, so the branch was configured against something that existed — after a *successful* fetch its absence is a removal, not a never-push).
     - **(b) no tracking configuration at all** (step 2 printed nothing). Remote = `origin`; candidate ref = `origin/<branch>`; 0e's blocker literal is `no tracking configuration`; a ref missing at 0d means `unsynced — no upstream` (never pushed).
   - Do **not** test whether the candidate ref exists yet — the 0c fetch is what creates or updates it, and 0d's post-fetch check is the single place that test lives.
4. If the resolved remote is not listed by `git remote` → note `No <remote> remote — skipping sync`, Freshness `unsynced — no remote`, proceed to Step 1. (A remote of `.` never reaches here — step 2 already exited.)

**Name the path correctly.** It is the **no-`@{u}` path** (the upstream ref does not resolve) — never "tracking-less". Sub-case (a) *has* tracking configuration, and calling the whole path tracking-less both misnames it and makes 0e report the wrong blocker.

**0c — Fetch** the resolved remote — **bounded and non-interactive**. This runs at a session's *first* prompt, so it must never hang there: set `GIT_TERMINAL_PROMPT=0` (git refuses rather than blocking on a credential prompt) and cap the call at 10 seconds — `GIT_TERMINAL_PROMPT=0 timeout 10 git fetch <remote> --quiet --no-tags` when `command -v timeout >/dev/null 2>&1` succeeds, falling back to the same call without `timeout` when it doesn't (MSYS/Git-Bash and minimal containers don't always ship `timeout`, and an unguarded `timeout 10 …` simply fails to exec, so the fetch would never run at all). What is borrowed from `hooks/session-start.sh:133-137` is the `command -v timeout` **guard pattern** and nothing more — that hook's fetch is *backgrounded*, so its untimed fallback never blocks anyone, while 0c runs in the foreground at the first prompt; the same bounding register as `/g-update`'s `curl --max-time 10`.
- **Residual, stated honestly.** `GIT_TERMINAL_PROMPT=0` closes git's *own* terminal prompt; it does not cover a GUI credential helper, an SSH key passphrase prompt, or a host-key verification prompt. On a system that has `timeout`, the 10s cap bounds those anyway. On a system without it, the fallback is bounded by nothing — a real exposure, accepted because the alternative (skipping the fetch) is a silent no-op.
- **Failure — one branch for every non-zero exit.** Offline, auth rejection, the `GIT_TERMINAL_PROMPT=0` credential refusal, `timeout`'s `124`, or any other non-zero status all route here identically: one-line note, Freshness `unverified — fetch failed`, and **skip 0d–0g entirely** — stale remote-tracking refs must never drive a compare (0g's record-axis count included), and never a fast-forward against a remote just proven unreachable. Proceed to Step 1. There is no separate timeout or credential outcome.

**0d — Post-fetch resolution re-check, then classify.**

Run the re-check first, **unconditionally and on both paths** (configured-upstream and no-`@{u}`), before any `rev-list`. It must run *after* 0c and not only before, because the fetch itself can destroy what 0b resolved: with `fetch.prune` or `remote.<name>.prune` set, 0c deletes the remote-tracking ref of a branch that was removed on the remote — so the ref 0b validated is already gone when `rev-list` needs it. A `rev-list` against a missing ref, or from an unborn `HEAD`, exits fatal; the repo's own hook blunts the same call with `|| echo 0` (`hooks/session-start.sh:150-151`), but here the failure gets an explicit outcome instead of a silent zero.

Check in this order — the first failure wins, so exactly one outcome fires:
1. `git rev-parse --verify HEAD` fails (repository with no commits yet) → note `No commits yet — skipping sync`, Freshness `unsynced — unborn HEAD`, proceed to Step 1. Checked first so a zero-commit repo lands here regardless of whether the remote ref happens to resolve.
2. `git rev-parse --verify <ref>` fails → the ref no longer resolves after the fetch. On the **no-`@{u}` path sub-case (b)** (no tracking configuration) that means the branch was never pushed: note `No upstream — skipping sync`, Freshness `unsynced — no upstream`. On the **configured-upstream path** *and* on **no-`@{u}` sub-case (a)** (tracking configuration exists) it means the remote branch is gone (deleted upstream, pruned by this very fetch): note `Upstream branch no longer on the remote — skipping sync`, Freshness `unsynced — upstream branch gone`. Either way, proceed to Step 1. **This is the only ref-existence test in Step 0** — it subsumes and replaces the no-`@{u}`-only test that previously sat at the end of 0c; the two are not overlapping checks, there is exactly one.
3. Both resolve → classify.

**Classify — total over the walks that reach it.** Every walk reaching the table below lands in exactly one row, and every walk that reaches Step 3 renders exactly one `Freshness:` value. Two walks end before the briefing by design and render none: the 0a existence-gate skip (Step 1's own stop condition fires) and the 0f decline (re-hydration halts on the developer's call). Both are correct behaviour, not a coverage gap.

- **behind** = `git rev-list --count HEAD..<ref>` · **ahead** = `git rev-list --count <ref>..HEAD`
- **clean** = `git status --porcelain --untracked-files=no` **exits 0 AND prints nothing** (tracked modifications only — untracked files never count as dirty here). Both halves are required: empty output on its own conflates "no tracked modifications" with "the command failed and printed nothing", and a failing `git status` reading as clean would let 0e fast-forward a tree whose state was never established. A non-zero exit is **not clean** — it routes exactly where a dirty tree routes (no fast-forward), with 0e's blocker literal `working-tree state unknown`.

**What `Freshness:` is scoped to.** Every value in the table below describes the **current branch against its own upstream**, and nothing else. It says nothing about whether the durable record this skill re-hydrates from is current — that is 0g's separate `Record axis:` line. `synced` must never be read as "the handoff is current".

| State | Report | Freshness |
|---|---|---|
| behind 0 · ahead 0 | `✓ In sync with <remote>` | `synced` |
| ahead only | `↑ N unpushed local commits — <remote> can't see them yet` — surfaced in the briefing's "Where we are" | `synced — N unpushed` |
| behind only | `↓ N behind <remote>` — 0e decides whether a fast-forward happens | `stale — N behind (not pulled: <why>)`, upgraded by 0e |
| diverged (both > 0) | prominent warning with both counts | set by 0f |

**0e — Fast-forward: an action on the behind-only row, never an outcome of its own.** Runs only when ALL hold: behind-only row · clean · configured-upstream path (never the no-`@{u}` path) · session-start invocation. Then fast-forward **locally**: `git merge --ff-only <ref>`.

**Why `merge`, not `git pull --ff-only`.** `pull` runs its own fetch — a second unbounded, credential-capable network call at a session's first prompt, reopening on the sibling call exactly the hazard 0c is carefully bounded to close. Nothing remains to fetch: 0c already fetched this remote and 0d already verified `<ref>` resolves. And because no ref moves between the count and the merge, the reported N is exactly the count 0d classified, instead of a pre-pull figure the pull's own fetch can silently invalidate. The `--ff-only` guarantee is unchanged — the merge refuses rather than creating a merge commit.

- Success → `Fast-forwarded N commits — now at <short-sha>`, Freshness upgrades to `synced — fast-forwarded N`.
- Failure (untracked-file path collision, a ref that isn't fast-forwardable, any non-zero exit) → do not retry; one-line warning, Freshness `stale — N behind (fast-forward failed)`. The literal says *fast-forward*, not *pull*, because no network call happens here: a reader debugging `(pull failed)` would hunt a credential or connectivity cause when the actual causes are the local ones named on this line.
- Any condition unmet → 0e simply doesn't run; the row's default Freshness stands with `<why>` naming the blocker. When more than one gate fails, name the **first** unmet in this order:
  1. `working-tree state unknown` — `git status` exited non-zero (0d)
  2. `dirty tree` — tracked modifications present
  3. `upstream ref unresolved` — no-`@{u}` path, sub-case (a): tracking configuration exists, `@{u}` does not resolve
  4. `no tracking configuration` — no-`@{u}` path, sub-case (b)
  5. `mid-session run` — the prompt counter reads ≥ 2
  6. `session phase unknown` — the prompt counter could not be read as a first prompt

**0f — Diverged: ask before anything.** No pull, ever. Warn prominently with both counts, then ask the developer: proceed on this possibly-stale record, or stop and resolve first?
- **Proceed** → Freshness `⚠ STALE — proceeding on developer's call (N behind, M ahead)` — the loudest tag, never dropped.
- **Decline** → print `Re-hydration stopped — resolve the divergence (pull/rebase/push as appropriate), then re-run /g-resume` and stop; Steps 1–4 do not run.

**0g — Record axis: the branch you are on is not the branch the record lives on.**

0d compares the *current branch* against *its own* upstream. The handoff being re-hydrated (`g-docs/ROADMAP.md`'s `## Active Session` block) lives on the mainline branch — so a session on `feat/x` that is level with `origin/feat/x` renders `✓ In sync` / `synced` while the record on `origin/main` has moved on, and 0e's fast-forward advances only `feat/x`, so `synced — fast-forwarded N` carries exactly the same stale record. Feature branches are the normal case (G-RULES §D branch discipline). This is the one walk that produces a **confident wrong answer** rather than an honest skip, which is precisely the failure Step 0 exists to prevent.

**When it runs.** After classification, on any walk that reached 0d's table — including after 0e, and after a 0f **proceed**. It never runs on an earlier exit (0a, any 0b skip, a failed 0c fetch, 0d's HEAD/ref failures), and on a 0f **decline** its line goes nowhere because no briefing is printed at all. 0g **never emits or changes a `Freshness:` value** — its output is a separate briefing line.

1. **Record-bearing branch — one ordered candidate list, verified per candidate.** The candidates, in order: (i) the short name printed by `git symbolic-ref --short refs/remotes/<remote>/HEAD`, with the leading `<remote>/` stripped, (ii) `main`, (iii) `master`. Take the **first candidate that verifies** — `git rev-parse --verify <remote>/<name>` succeeds. A candidate that does not verify advances to the next one; a failed verify never ends the chain. Both halves matter and neither gates the other: `refs/remotes/<remote>/HEAD` is created only by `git clone` or an explicit `git remote set-head`, so a locally-`init`ed-then-pushed repo has none at all, and where it does exist it can still dangle (default branch renamed, or HEAD left pointing at a deleted branch) — gating the `main`/`master` fallback on `symbolic-ref` *failing* would skip straight past a perfectly good `<remote>/main` that is holding the record. If all three candidates are exhausted → emit `Record axis:   record branch could not be resolved — cannot tell whether the handoff is current` and stop 0g.
2. If the current branch **is** the resolved record-bearing branch → 0g emits nothing. **This is the only silent case**: 0d's row already ran exactly that comparison, so `Freshness:` genuinely covers the record here.
3. Otherwise `record_behind` = `git rev-list --count HEAD..<remote>/<record-branch>`. If that command fails → emit `Record axis:   record-drift count failed — cannot tell whether the handoff is current` and stop. Never a guessed number.
4. Emit one **briefing line**, never a `Freshness:` variant:
   - `record_behind` > 0 → `Record axis:   <N> commits behind <remote>/<record-branch> — the handoff you are re-hydrating from may be stale`
   - `record_behind` = 0 → `Record axis:   not behind <remote>/<record-branch>` — *not behind* is what `rev-list --count HEAD..<ref>` measures, and it is not the same as level: a feature branch 20 ahead and 0 behind is not level with anything.

**An unknown is emitted, never swallowed.** Steps 1 and 3 above fail *visibly* because a silent skip would render a briefing byte-identical to the case-2 briefing, where `Freshness: synced` legitimately means the record is current. Reusing silence for "could not tell" reproduces, through 0g's own escape hatch, exactly the confident wrong answer 0g was added to eliminate — and the trigger is ordinary, not exotic: any repo whose mainline is `develop`, or that was `init`ed locally and pushed, hits it on every feature-branch session. These two literals are `Record axis:` values only; they are **not** `Freshness:` values and change nothing about that line.

**Read the two lines separately.** `Freshness:` is the current branch against its own upstream and nothing more. `Record axis:` is the only line that speaks to the durable record. A reader must never be able to take `synced` as "the record is current".

**Session-start only — keyed on the prompt counter, not on a banner.** The 0e fast-forward exists for the fresh-session path. Do **not** key it on `workflow-checkpoint.sh`'s pending-handoff nudge having printed: that banner is triple-gated — the `light` tier exits at `hooks/workflow-checkpoint.sh:173`, long before the nudge block at `:387`, and the block additionally requires `PROMPT_COUNT -eq 1` and a pending handoff. On `light` it can therefore *never* print, and a genuinely fresh session invoking `/g-resume` at prompt 2 would be misreported as mid-session.

Key on observable state instead — the per-session prompt counter the hooks already maintain on disk: `hooks/session-start.sh:182` zeroes `session-prompt-count.<session_id>` (bare `session-prompt-count` when the payload carries no session id) on a genuine session open, and `hooks/workflow-checkpoint.sh:226-227` increments it once per prompt.

**Resolving that file is part of the rule, and it fails safe.** A skill is not handed the hook payload, so neither the governing `.claude/` directory nor the session id arrives for free — both have to be resolved, and where the resolution is uncertain 0e declines rather than guesses. Read literally, "the counter file" is not a constructible path; this is:

1. **Governing `.claude/`** — resolve it by the ADR-005 local-else-primary rule (local `.claude/` if this tree has one, else the resolved primary tree's; in a linked worktree the counter lives in the primary's). `skills/g-plan/SKILL.md:105` is the owning statement of that rule — follow it there rather than restating it differently here.
2. **Session id knowable** → read the keyed `session-prompt-count.<session_id>` in that directory. A value of exactly `1` → **session-start**; 0e may run.
3. **Session id not knowable** → enumerate the `session-prompt-count*` candidates in that directory. **Exactly one** candidate, holding exactly `1` → session-start. **Zero candidates, more than one candidate, an unreadable or non-numeric value, or `0`** → `<why>` = `session phase unknown`. Never disambiguate concurrent candidates by mtime *for this decision*: `/g-plan` may take the most-recently-modified match because its use is read-only, but here the wrong pick is a sibling session's counter reading `1`, and the cost of that mistake is a fast-forward landing under a session that is already running — the precise hazard this gate exists to prevent. The cost of being conservative is only that the developer pulls by hand.
4. **Counter reads ≥ `2`** → mid-session; `<why>` = `mid-session run`.

**The consequence, stated plainly.** On the `light` tier the counter sits at `0` for the whole session — `hooks/workflow-checkpoint.sh:173` exits before the increment at `:226-227`, while `hooks/session-start.sh:179-184` resets the counter outside the tier block, on every tier — so `0` is never evidence of a first prompt. On `light`, and in any ambiguous multi-session case, `<why>` = `session phase unknown` (never borrowed from `mid-session run`) and **0e simply does not run**. Step 0 still fetches, classifies, and reports freshness; it just does not touch the working tree. That is the intended trade, not a gap to route around.

Mid-session, whatever the reason: compare and report, never fast-forward (files the session already read must not move underneath it).

**One owner — for the numbers and for the instruction.** `hooks/session-start.sh` prints a behind/ahead line against `origin/<branch>` at session open, plus a behind-`origin/main` drift line on any non-mainline branch (both tier-gated), and it prints at SessionStart — *before* the first prompt — so the developer reads it before Step 0 has run anything. Step 0 is the deciding owner on all four counts:

- **The figures.** The hook compares against `origin/<branch>`; Step 0 compares against the resolved upstream. When the two disagree (non-origin upstream, differently-named remote branch), Step 0's figure wins.
- **The `git pull` instruction.** The hook's behind line is imperative, not advisory — `⚠ N commit(s) behind origin/$BRANCH — git pull` (`hooks/session-start.sh:154`) — and its test is independent of the ahead test, so it **also fires on a diverged tree**, recommending exactly the pull 0f refuses. Whenever Step 0 runs it supersedes that suggestion: never follow the hook's bare `git pull` on a diverged tree — 0f asks first and never pulls.
- **The clean summary.** `✓ Clean and in sync with remote` (`hooks/session-start.sh:166`) is a categorical claim, and it is computed against `origin/<branch>` with `rev-list` failures defaulting to zero (`|| echo 0`, `hooks/session-start.sh:150-151`) — so on a never-pushed or non-origin branch, where that comparison never actually ran, it reads clean anyway. Step 0's classification is authoritative: a tree the hook calls in sync can be `unsynced — no upstream` here.
- **The behind-`origin/main` drift line.** `⚠ N commit(s) behind origin/main — consider rebasing` (`hooks/session-start.sh:157-161`) is the same figure 0g computes, printed at session open on any branch that isn't `main`/`master`. 0g owns it from here: it resolves the record-bearing branch properly — the ordered candidate list `refs/remotes/<remote>/HEAD`, then `main`, then `master`, each taken only if `git rev-parse --verify` accepts it — instead of hardcoding `origin/main`, and it states the consequence the hook's line leaves implicit, that the handoff being re-hydrated may be stale. Where the two disagree, 0g's figure wins.

The hook carries a matching cross-reference comment; editing either site means re-checking the other.

## Step 1 — Establish the re-entry keys

Gather, in parallel:
- **Branch** — `git branch --show-current`. If it matches `feat/<slug>` / `fix/<slug>` / `refactor/<slug>` / `chore/<slug>`, extract `<slug>`.
- **Active milestone** — the milestone marked 🔄 In progress in `g-docs/ROADMAP.md` (name + scope).
- **Handoff** — the `## Active Session` block in `g-docs/ROADMAP.md` (the "Next up" and "Active context" lines). Also read `.claude/compact-state.md` if it exists (the PreCompact snapshot) — it is the same block captured mid-session before a compaction.
- **First task** — the lead item of "Next up". Watch specifically for a `verify ADR-NNN` task (written by `/g-adr`'s decision-hygiene reset) — that is a first-class re-entry signal.
- **Recently touched files** — `git log --name-only -n 10 --pretty=format:` (unique basenames) — used to match decisions to the active work.

If neither `g-docs/ROADMAP.md` nor `.claude/compact-state.md` exists, this isn't a G-Forge project mid-flight — say so in one line and stop: `Nothing to re-hydrate — no handoff or roadmap found.`

## Step 2 — Retrieve the relevant slice (selective)

Gather candidates deterministically, then judge relevance — load only what serves the first task.

1. **The first task's anchor.** If the handoff names `verify ADR-NNN` (or any specific ADR), load that ADR file from `g-docs/decisions/` — its **Decision**, **Consequences**, and **Assumptions That Held** sections. This is the task; it gets full weight. (Verifying it against ground truth is exactly why the previous session handed it over rather than trusting it from memory.)
2. **The carry-over retro.** In `g-docs/retros/`, find the most recent retro whose slug matches the branch `<slug>` or the active milestone. If **none** matches, fall back to the single most recent retro **but mark it low-relevance** — the `Carry-over` briefing line gets a `(low relevance — no slug/milestone match)` tag so the fresh session weights it accordingly rather than trusting a stale, unrelated retro. Load only its **Cold-start context** and **Avoid / do differently** sections — never the whole file. If `g-docs/retros/` is empty, skip this line.
3. **Decisions touching this work.** `grep` `g-docs/decisions/` for the branch slug and the recently-touched file basenames. From the matches, load the **Decision** line of the top 1–3 most relevant ADRs (constraints the fresh session must not re-litigate). List the rest as pointers only.
4. **The alignment anchor.** `g-docs/project_brief.md` — the **Goals** list and the active milestone's **Scope**, one line each. This is what the work is *for*; it keeps the fresh session from drifting (same anchor `/g-align` uses). **If no `project_brief.md` exists**, fall back explicitly to `g-docs/ROADMAP.md` — the project intent (the `#` title + top blurb) plus the **active milestone's Goal** — and tag the briefing's `Anchored to` line `(roadmap — no brief)`. A brief is the stronger anchor, so when the fallback fires, note that `/g-brief` could create one. Never leave the briefing with no anchor.
5. **Recent activity.** The latest `.claude/journal/*.jsonl` (last ~15 events) and `git log --oneline -5` — the texture of what just happened.

Cap it: if a category has many matches, take the most relevant few and leave the rest as `(N more — see <dir>)` pointers. Re-hydration that dumps everything just re-poisons the window.

## Step 3 — Assemble the re-entry briefing

Present a single focused briefing — distilled, scannable, pointer-rich:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Re-entry — [branch] · [milestone or "—"]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
First task:    [lead "Next up" item — e.g. "Verify ADR-007 against the repo"]
Where we are:  [1–2 lines from handoff "Active context" + recent commits + Step 0 sync notes (unpushed count, non-origin upstream, fetch failure)]
Freshness:     [synced | synced — N unpushed | synced — fast-forwarded N | stale — N behind (not pulled: <why>) | stale — N behind (fast-forward failed) | unverified — fetch failed | unsynced — detached HEAD | unsynced — not a git repo | unsynced — no remote | unsynced — local-only remote | unsynced — no upstream | unsynced — upstream branch gone | unsynced — unborn HEAD | ⚠ STALE — proceeding on developer's call (N behind, M ahead)]
Record axis:   [N commits behind <remote>/<record-branch> — the handoff you are re-hydrating from may be stale | not behind <remote>/<record-branch> | record branch could not be resolved — cannot tell whether the handoff is current | record-drift count failed — cannot tell whether the handoff is current]

Decisions in force:
  · ADR-NNN — [Decision line]            [+ N more in g-docs/decisions/]
Carry-over (do differently):
  · [from the relevant retro's "Avoid / do differently", or "—"]   [append "(low relevance — no slug/milestone match)" if this is a fallback retro]
Anchored to:   [brief goal(s) the active milestone serves — or roadmap goal + "(roadmap — no brief)" if no project_brief.md]
Recent:        [last commit + last few journal events, one line]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

The `Freshness:` bracket is the **closed set** of values Step 0 can emit — every outcome in 0b–0f renders one of them and nothing else, and the set diffs to empty against 0b–0f in both directions. The two walks that never reach this briefing (the 0a existence-gate skip and the 0f decline) render no value at all, by design. `<why>` is one of: `working-tree state unknown` · `dirty tree` · `upstream ref unresolved` · `no tracking configuration` · `mid-session run` · `session phase unknown` (0e's priority order).

`Record axis:` is a **separate** line with its own closed set of four values (0g's steps 1, 3 and 4), and it is never a `Freshness:` value and never modifies one: `Freshness:` speaks for the current branch against its own upstream, `Record axis:` for the durable record. The line is absent in exactly two situations — the current branch **is** the record-bearing branch (0g case 2, where `Freshness:` already covers the record), or 0g never ran at all (any walk that exited before 0d's table). Neither an unresolvable record branch nor a failed drift count is silent; both emit their honest-unknown value above, so absence can only ever be read one way.

Optionally write the same briefing to `.claude/reentry.md` (overwrite) so it is available without re-running.

## Step 4 — Hand off to the first task

End by pointing at the first task — do not start it unprompted unless it is a pure verification:

- **If the first task is `verify ADR-NNN`:** offer to run it now — "First task is verifying ADR-NNN against the actual repo. Want me to check the decision still matches ground truth before we build on it? (y/n)". On yes, read the ADR's Decision/Consequences and confirm each against the current code/config/deps, reporting `holds` / `drifted — [what changed]` per claim. This is the clean-slate check the decision-hygiene loop exists to force.
- **Otherwise:** state the single next action and stop, the way `/g-help` does — e.g. "Resume Wave 2 with `/g-execute 2`," or "Run `/g-plan` for the next milestone scope."

## Rules
- Selective, not exhaustive. Load distilled sections (retro Cold-start, ADR Decision/Consequences) and pointers — never whole files or full histories. A clean window is the entire point.
- Read-only retrieval, with a bounded sync exception. `/g-resume` may write exactly three things: (1) Step 0c's `git fetch` — an object-store/remote-tracking-ref write that runs on every non-skipped path; (2) Step 0e's **local** fast-forward, `git merge --ff-only <ref>` — never `git pull`, which would open a second unbounded network call at the first prompt — and only when all of these hold: 0a existence gate passed, fetch succeeded, behind-only on a clean tree (`git status` exited 0 with no tracked modifications), configured-upstream path, session-start invocation (prompt counter reads `1`); (3) the optional `.claude/reentry.md` briefing write. Nothing else, and it triggers no other skill on its own.
- Relevance is judged, not dumped — gather candidates by keys (grep/glob), then keep only what serves the first task. When unsure, prefer the pointer over the paste.
- Never re-litigate a decision that an in-force ADR already settled — surface it as a constraint, not an open question. (Verifying an ADR named in the handoff is the one exception, and that is the task itself.)
- If the durable record is thin (no retros/ADRs yet), re-hydrate from the handoff + roadmap + journal alone and say so — degrade gracefully.
- Auto-trigger condition (full tier only): the **first prompt of a session** when a handoff is pending (`g-docs/ROADMAP.md` `## Active Session` handoff or `.claude/compact-state.md` present) — `workflow-checkpoint.sh` surfaces the nudge.

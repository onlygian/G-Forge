# Fable audit F1 — commit-gate path, git-hooks-dir install, CI (2026-08-30)

**Cycle:** M52 F1 (scope amendment 2026-08-30, `ROADMAP.md` M52 entry). **Read by:** HQ on the session model, directly — §A1 override, developer-decided. **Slice:** `hooks/check-commit.sh`, `hooks/pre-commit`, `hooks/post-commit-cleanup.sh`, `hooks/lib/{classify-changeset,commit-detect,sentinel-read,stdin-read,worktree-resolve}.sh` (1,686 lines, every file read whole), `/g-init` Step 6a, `/g-update` Step 7a, `/g-doctor` Check 16, `/g-review` Step 1, `.github/workflows/tests.yml`. **Filter:** every finding below is on a SURVIVES component (`audits/2026-07-rebuild-map.md:74`) and adopter-facing.

**Probe:** `scratchpad/f1-probe.sh` (session-local), run 2026-08-30 against a throwaway `git init` repo — output pasted per finding. The probe had to run from a script file: the repo's own PreToolUse gate denied the inline form because the probe text contains `git commit` literals. That is the gate working, not a probe defect.

## Findings

### F1-1 — Critical · native `pre-commit` is installed without the `lib/` it sources → every commit denied on a fresh install

- `hooks/pre-commit:50-56` resolves `_GF_HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"` and sources `lib/worktree-resolve.sh`, `lib/classify-changeset.sh`, `lib/sentinel-read.sh` from **its own directory**, each `|| deny "internal error — could not load …"`.
- `skills/g-init/SKILL.md:286-304` (Step 6a) and `skills/g-update/SKILL.md:305-314` (Step 7a) copy `<git-hooks-dir>/pre-commit` **only**. No step anywhere copies `lib/` into the git hooks directory. `skills/g-update/SKILL.md:280-282` itself documents that `worktree-resolve`, `classify-changeset`, `sentinel-read` are "sourced by … the native `pre-commit` hook", then realigns them to `.claude/hooks/lib/` only.
- `skills/g-doctor/SKILL.md:150-155` (Check 16, native pre-commit sub-check) hashes `<hooks-dir>/pre-commit` alone. `skills/g-review/SKILL.md:33-45` (Step 1 drift) compares `.claude/hooks/` + `.claude/hooks/lib/` only.
- Zero tests exercise the installed layout: `grep -l 'git-path hooks\|hooks-dir\|\.git/hooks' tests/*.sh` → no files. `tests/test-pre-commit.sh:61` runs the source in place ("its real, unmoved location under hooks/"), so the suite can never see this.
- This repo only works because `.git/hooks/lib/` was hand-copied 2026-07-22 (todo 17's evidence) and hand-synced 2026-08-30.

**Probe output (pre-commit copied alone, `.claude/integration-tier` = full, one staged file):**
```
.git/hooks/pre-commit: line 52: /tmp/tmp.EHigXDU0ue/.git/hooks/lib/worktree-resolve.sh: No such file or directory
G-Forge: internal error — could not load hooks/lib/worktree-resolve.sh
commit rc=1
--- with lib/ copied alongside ---
G-Forge: no valid code-lead sign-off (missing or unparseable sentinel). Run /g-review and wait for MERGE READY before committing.
commit rc=1
```
Fail direction is toward deny (no silent bypass), but the product's authoritative gate (ADR-004) blocks **all** commits on every consumer that ran `/g-init` as written. Todo 17 recorded this as drift; it is install-incompleteness — the same class as the v2.4.0 4-of-6 lib install (`tests/test-lib-install-completeness.sh:4-12`), one directory over.

**Fix (Task 24):** `/g-init` Step 6a + `/g-update` Step 7a install `<git-hooks-dir>/lib/*.sh`, enumerated **from disk** (`ls <plugin-hooks>/lib/*.sh`), never a typed list (ADR-011 / completeness-suite doctrine); `/g-doctor` Check 16's pre-commit sub-check and `/g-review` Step 1's drift set each add `<git-hooks-dir>/lib/*.sh`; `tests/test-pre-commit.sh` gains an installed-layout pair (pre-commit alone → the exact `could not load` deny; with `lib/` → the normal sentinel deny), and `tests/test-lib-install-completeness.sh` pins that Step 6a and Step 7a name the git-hooks-dir `lib/` install.

### F1-2 — Major · `--no-verify` / `core.hooksPath` skip the authoritative gate and the PreToolUse layer never looks

- `hooks/check-commit.sh:170-272` checks sentinel **existence** only (`[ ! -f … ]`); content binding (tree hash, HEAD, worktree — ADR-004) lives solely in `hooks/pre-commit:77-96`. Documented split (`check-commit.sh:12`, `pre-commit:4-12`).
- Nothing in `check-commit.sh` or `hooks/lib/commit-detect.sh` inspects `--no-verify`, `-n` (or an `n` inside a short-flag cluster), or `-c core.hooksPath=…`. `grep -c 'no-verify\|hooksPath' tests/test-{commit-detect,check-commit,pre-commit}.sh` → `0 0 0`.
- Consequence on the common path: a sentinel that **exists but is stale** (tree edited after MERGE READY) passes PreToolUse; `--no-verify` skips the native hook; the ADR-004 binding is never evaluated. G-RULES §I says "Never bypass the commit gate with `--no-verify`" — prose, unenforced.

**Probe output (lib present, no sentinel):**
```
--- with lib/ + --no-verify ---
commit rc=0
7ea47bc t
```

**Fix (Task 25, with F1-3):** in `commit-detect.sh`, two argv-walk predicates over the already-tokenized committing segment (same flag/value-skip rules as `extract_pathspecs:531-562`, so a `-m "…-n…"` message body is never misread): `gf_commit_skips_hooks <cmd>` → true on `--no-verify` or a single-dash cluster containing `n` in flag position after `commit`; `gf_commit_overrides_hookspath <cmd>` → true on `-c core.hooksPath=*` (key case-insensitive) among the global tokens before `commit`. `check-commit.sh` denies on either, **before** the sentinel check and regardless of tier-`full`/`balanced` sentinel state, with a reason naming the flag. Tests in `test-commit-detect.sh` (predicates) and `test-check-commit.sh` (deny path, plus a `-m "use -n"` message-body negative).

**Known limit, stated:** a commit issued from inside a script file (`bash x.sh`) is invisible to argv inspection by construction; with `--no-verify` inside the script neither layer fires. Not fixable at the hook layer — recorded, not hidden.

### F1-3 — Major · eight wrapper shapes are invisible to `commit-detect.sh`

`_commit_detect_walk_core` (`commit-detect.sh:60-172`) requires the segment's first real token to be `git` or `*/git` after env-prefix stripping; `_commit_detect_scan_segments:223` pads only `& | ;` as boundaries. So:

```
0  (git commit -m x)            0  $(git commit -m x)         0  `git commit -m x`
0  { git commit -m x; }         0  if git commit -m x; then :; fi
0  command git commit -m x      0  exec git commit -m x       0  time git commit -m x
1  git commit --no-verify -m x  1  git -c core.hooksPath=/dev/null commit -m x
```

Alone, the native hook still denies these (authoritative). Combined with F1-2 — `(git commit --no-verify -m x)` — PreToolUse is silent **and** native is skipped: full bypass. `tests/test-commit-detect.sh` has no case for any of the eight (`grep -n "(git commit\|{ git commit\|if git commit\|command git commit\|exec git commit"` → none).

**Fix (Task 25):** extend the raw-string pad in `_commit_detect_scan_segments:223` to treat `(`, `)`, `{`, `}` and a backtick as boundaries (same reasoning as the existing `& | ;` pad — quotes are untouched, so operators inside a quoted message body fold back into one token); strip a bounded transparent-prefix set in `_commit_detect_walk_core` before the `git` test — `if elif while until ! command exec time nohup builtin` and `$(` — the way `env` is stripped at `:72-103`. Each shape becomes a test case; the `-m "(not a commit)"` and `-m "if x then y"` negatives pin that message bodies still don't split.

### F1-4 — Minor · `tests.yml` hardening (todo 15 F6, carried)

`.github/workflows/tests.yml:40-48`: no `permissions: contents: read`, no `concurrency:` group, `push` + `pull_request` double-run. Fixed inline by HQ this cycle (single file, known location).

## Not findings (read, considered, left alone)

- `check-commit.sh:24-30` fail-open on a missing `commit-detect.sh` and `:88-104` fail-open on stdin timeout — deliberate, documented, and correct for a hook that fires on every shell call; the native hook is the backstop. F1-1 is what makes that backstop real on consumers.
- `pre-commit:225` consumes the sentinel at pre-commit time; a later hook aborting the commit (commit-msg, foreign prepare-commit-msg) forces a re-review. Fail-toward-deny; acceptable.
- `check-commit.sh:209` `-a` regex can match a `-a…` word inside a quoted message body → widens the classified set. Fail-toward-deny; acceptable.
- `check-commit.sh:83` GNU-sed `\|` — already todo 15 F7.
- `classify-changeset.sh`, `sentinel-read.sh`, `worktree-resolve.sh`, `stdin-read.sh`: read whole; no defect found. `worktree-resolve.sh:60-63` correctly denies on `--separate-git-dir` / submodule shapes rather than guessing.

## HQ self-review of the fix wave (before the gate)

Read the whole `hooks/` diff after Task 25 returned. Two hardenings applied inline by HQ (single-file known-location edits, `hooks/lib/commit-detect.sh` + `tests/test-commit-detect.sh`):

- **Cluster check was blunt.** `gf_commit_skips_hooks` matched any single-dash cluster containing `n`, so a glued value — `git commit -mnote` — produced a false `--no-verify` deny. Now a char-by-char walk: `n` fires; the first value-taking short flag (`m C c F t S u`) consumes the rest of the cluster. Cases: `-mnote` → false (guard, marker planted), `-na` → true.
- **`core.hooksPath` env form.** `GIT_CONFIG_PARAMETERS='core.hooksPath=x' git commit` and the `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n` triple reach git exactly as `-c` does and sit in the var-assign prefix the walk already holds; one `*=*` arm in `gf_commit_overrides_hookspath` covers both. Cases: both forms → true.
- Found by Task 25 on the way, kept: `xargs -n1` with no command runs GNU `echo`, which swallowed a bare `-n` token; tokenizer now `xargs -n1 printf '%s\n'`.

**Probe (the `-mnote` guard, `probe-mnote.sh`, scratch mirror, `break` on the value-taking arm removed):**
```
neuter applied (expect 1): 1
FAIL: NOVERIFY: -mnote (glued -m value containing n) not flagged (expected gf_commit_skips_hooks false, but was true)
Results: 94 passed, 1 failed
```
Production run after the hardening: `Results: 95 passed, 0 failed`. The six markers Task 25 planted were probed red by `g-forge-dev` (`agent-output/review/g-forge-dev-2026-08-30-f1-r1.md`, Part 2). Attested full suite before the two inline edits: 712/0 across 24 suites, HQ-summed from the per-suite table.

## Gate rounds

- **Code r1 — HOLD 0C/4M/5m** (`agent-output/review/code-lead-2026-08-30-v25-f1-commit-gate-r1.md`). Majors: `${var,,}` is bash-4-only, so on macOS `/bin/bash` 3.2 `check-commit.sh` aborted (fail-open) on exactly the `-c core.hooksPath=` input the predicate targets → `_commit_detect_lower` via `tr`; `--no-verify` matched as an exact literal while git accepts unambiguous abbreviations (probed: `git status --shor`) → `--no-veri`/`--no-verif` arms, `--no-verbose` guard; a hand-typed `+19`/`91` in the `test-commit-detect.sh` header went stale within the session → removed, runner-observed only; case 32 (light tier + `--no-verify`) was a guard with no marker/probe → marker + probe below. Minors: `/g-doctor` remediation pointed at `.claude/hooks/` for a `<hooks-dir>/lib/` miss → fixed; `tests.yml` `push: branches: [main]` moved CI post-merge on a repo that merges locally → push on every branch, no `pull_request`, `cancel-in-progress` off on `main`; quoted pathspec with `( ) { }` mutated by the raw-string pad → carried to todo 15 (pre-existing class, safe direction); stale patch → regenerated after the last edit; audit file untracked → staged.
- **Doc r1 — HOLD 4B/3W**, **doc r2 — HOLD 2B/2W** (`doc-reviewer-…-r1.md`, `-r2.md`). Every blocker was a contradiction I introduced or left standing while editing the same file: predicate contract blocks not updated with their bodies; `pre-commit:33-36` and `:48` still describing an uninstalled file; ROADMAP `:586` Goal date and `:592` Session D date after the amendment. Warnings: `<git-hooks-dir>` token in `/g-update`, hand-typed three-lib enumerations in two skills, unqualified roll-up lines, and the header enumerations my r1 fix minted (pin-or-omit → omitted; the `case` arms are the authority).

**Probes for the two guards added in the code-r1 fix round** (`probe-r2.sh`, scratch mirror):
```
=== Probe A: --no-verbose guard — neuter: abbreviation arm widened to --no-ver* ===
neuter applied (expect 1): 1
FAIL: NOVERIFY: --no-verbose (a different --no-ver* option) not flagged (expected gf_commit_skips_hooks false, but was true)
Results: 97 passed, 1 failed
=== Probe B: case 32 light-tier guard — neuter: light-tier exit 0 removed from check-commit.sh ===
neuter applied (expect 0 remaining light exits near the comment): 0
FAIL: light tier: gated commit allowed with no sentinel (gate off) (expected exit 0, got 2)
FAIL: light tier: --no-verify commit allowed (gate off, predicate never evaluated) (expected exit 0, got 2)
Results: 30 passed, 2 failed
```
Production after that round: `test-commit-detect.sh` 98/0 (99/0 after code r2 added the `--no-v` case; the live figure is always the suite's own `Results:` line).

- **Code r2 — HOLD 0C/1M/5m.** All four r1 Majors closed with sweep evidence. Major: the CI trigger fix (push-only, no `pull_request`) landed without sweeping its carriers — CHANGELOG `[2.5.0]` said the opposite twice (the Session B "Added" bullet and my own "Fixed" bullet) and the `todo-done.md` 15-F6 closure row recorded the reverted `push: branches: [main]` form. All three rewritten. Minors: `tests.yml:3` header (already fixed by doc r3); the `gf_commit_skips_hooks` contract omitting the abbreviation arms (fixed by doc r3); the `--no-ver`/`--no-ve`/`--no-v` ambiguity claim was unprobed (the reviewer's scratch probe was permission-denied) → arm widened to every prefix, fail-toward-deny, the ambiguity claim kept in the comment but marked unprobed and no longer load-bearing, `--no-v` case added (`test-commit-detect.sh` 99/0); audit file re-staged.
- **Code r3 — HOLD 0C/1M/1m.** r2's six closed with sweeps. Major: the doc-r3 fix re-typed the assertion total (719) into `tests/README.md`, and the code-r2 fix moved it to 720 one edit later — the class r1 had already closed by omission in `test-commit-detect.sh`'s header. Fixed by omission: `tests/README.md` and the local `CLAUDE.md` now say the total is the runner's `Grand total` line, never typed. Minor: Probe A's provenance predated the arm widening (3 → 6 members) → re-run against the six-arm form, output below.
  ```
  === Probe A (re-proof, six-arm alternation replaced by --no-ver*) ===
  neuter applied (expect 1): 1
  FAIL: NOVERIFY: --no-v (shortest prefix, fail-toward-deny even if git would reject it) detected (expected gf_commit_skips_hooks true, but was false)
  FAIL: NOVERIFY: --no-verbose (a different --no-ver* option) not flagged (expected gf_commit_skips_hooks false, but was true)
  Results: 97 passed, 2 failed
  ```
  (The `--no-v` red is the neuter glob not matching that spelling — a side effect of the neuter, not a second guard; the `--no-verbose` line is the guard under proof.)
- **Doc r3 — HOLD 4B/0W.** r2's four closed with sweeps. New: `tests/README.md` "684 assertions" (re-typed to that round's attested figure — a resolution code r3 then superseded by omitting the total altogether; local `CLAUDE.md` per-suite counts updated to match the run), `tests.yml:3` header, the abbreviation arms missing from the function contract, and the native pre-commit sub-check's own two remediation lines still pointing at `.claude/hooks/`. All four fixed.

## Tally

3 findings fixed this cycle (F1-1 Critical, F1-2 Major, F1-3 Major) + 1 carried Minor closed (F1-4) + 2 HQ self-review hardenings on the F1-2 fix. Summed from the headed sections above.

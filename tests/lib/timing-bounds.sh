#!/bin/bash
# tests/lib/timing-bounds.sh — the suite's timing assertion bounds, declared once.
#
# Sourced by test suites; side-effect-free at source time (constants only, no
# top-level execution, no output).
#
# WHY a shared file rather than a constant per suite: these bounds are ONE fact
# each, and a fact duplicated across suites drifts. It already did — the
# hook-guard bound was widened in test-class-split-invariant.sh on fresh
# evidence and not in test-check-commit.sh, and that suite went red on the next
# run (20919ms / 20955ms against a 20000ms bound). A comment saying "keep these
# in step" does not enforce; a single definition does.
#
# Authoring rule (profiles/claude-plugin/rules/architecture.md, timing note):
# at least 2x the worst observed run on MSYS/Git-Bash, named *_MS, WHY stated.
# Author generous, tighten on evidence. The two empirical bounds below were
# first authored tight, both breached, and both now sit at 2x worst observed;
# all three now carry dated empirical evidence (the fast-override bound was
# validated, then raised on loaded-machine samples, 2026-08-21).

# Hook-body-under-abandoned-pipe bound: a hook invoked with stdin attached to an
# open pipe that has no writer and never sends EOF must return once its 5s stdin
# guard fires. Since M48c wired the fast override into the fixtures, this bound
# has exactly ONE consumer: the production-mode post-commit-cleanup.sh case in
# test-class-split-invariant.sh (the one abandoned-stdin call deliberately run
# WITHOUT the override so the production 5s guard path keeps regression
# coverage). The other five hooks there, and test-check-commit.sh cases 23/25,
# run override-mode under GF_FAST_STDIN_GUARD_MS below.
#
# WHY 65000 and not 5s+epsilon: the epsilon is MSYS subprocess-spawn overhead in
# the hook body AFTER the read, which scales with machine load and dwarfs the
# guard it protects. Authored at 20000 when the worst observed was 9.9s on a
# quiet machine; breached on 2026-08-16 under a full suite plus agents
# (agent-lifecycle 21.8s, workflow-checkpoint 31.9s, check-commit 20.9s, and
# post-commit-cleanup — the smallest hook, no network, nothing after the read —
# at 23.5s). The same six hooks return in 9.3-15.4s idle, so 20000 sat only ~30%
# above the IDLE worst case and well inside the loaded distribution: a flaky
# bound, not a regression signal. 65000 is 2x the worst ever observed (31.9s).
#
# Still decisive: the guard-deleted failure mode blocks ~300s on the sleeper
# fixture, so this stays 4.6x under a genuine hang, and 61x under the 66-minute
# field orphan the guard exists to catch. It proves the hook RETURNS, which is
# the whole invariant. The fine-grained regression detector is the bound below,
# which exercises the lib directly with no hook body in the way.
GF_HOOK_STDIN_GUARD_MS=65000

# Bare-lib-read bound: gf_read_stdin_timeout called directly with a 1s timeout,
# no hook body, no subprocess fan-out. Used by test-stdin-read.sh.
#
# WHY 6000 and not 2000: the original was a bare literal allowing 1000ms over
# its own 1s timeout, tighter than the hook-body bound above that had already
# breached twice. It then reproduced red at 2876ms loaded and 2588ms on a quiet
# machine (2026-08-16), so it was a wrong bound rather than load flake. 6000 is
# 2x the worst observed (2876ms). Still 50x under the 300s sleeper fixture, so
# an unbounded read is caught with the same certainty as before.
GF_LIB_READ_WINDOW_MS=6000

# Fast-stdin-guard override bound: a hook invoked with stdin-timeout override
# set to ~2s (fast mode, test acceleration) instead of the production 5s
# guard. Bounds hooks running in override mode after M48c wires the override
# into test runs.
#
# Validated 2026-08-21 from real override-wired runs (M48c task 5 + r3 fix
# round). Quiet-machine: 5 full runs of each consuming fixture (40 samples),
# worst 6806ms (workflow-checkpoint.sh). Loaded-machine (r3 blocking item 3 —
# quiet samples alone were rejected in review): 3 fixture runs under full
# 16-core CPU saturation, worst 12849ms (agent-lifecycle.sh), which left only
# ~2.1s of margin against the provisional 15000 — a flaky bound, not a
# regression signal, same class as the 20000 breach above. 30000 clears 2x the
# loaded worst (25698ms, rounded up to a clean bound), and stays 10x under the 300s sleeper
# fixture, so a guard-deleted hang is still caught decisively. Re-validate if
# any sample exceeds 15000ms (half this bound).
GF_FAST_STDIN_GUARD_MS=30000

# Fast-stdin-guard override value (seconds): the GF_STDIN_TIMEOUT_OVERRIDE
# fixtures export to force gf_read_stdin_timeout's ~2s fast path instead of
# the production 5s argument. WHY a constant and not a bare `2` at each export
# site: it is the same fact GF_FAST_STDIN_GUARD_MS above is bounding — the
# guard bound and the override that produces the timing it bounds must move
# together, and three bare-literal export sites already drifted from each
# other once (code-lead round r3, minor finding).
GF_FAST_STDIN_OVERRIDE_S=2

# Environment variables

G-RULES §G reference. G-Forge's shipped surfaces read the environment variables listed below;
three more names that look like env vars are actually test-suite constants,
not environment variables at all — listed below to prevent that confusion.

## `GF_STDIN_TIMEOUT_OVERRIDE`

| | |
|---|---|
| **Purpose** | Test-fixture timeout override for `gf_read_stdin_timeout` (`hooks/lib/stdin-read.sh:63-80`). When set and non-empty, its value replaces the effective stdin-read timeout before argument normalization — an invalid override (negative, non-numeric) falls through the same normalization/default path as an invalid `seconds` argument. |
| **Required/optional** | Optional. |
| **Default when unset** | No-op — unset or empty is byte-identical to today's behaviour; the function's `seconds` argument governs exactly as before. |
| **Set in production?** | No. Every top-level hook sources `stdin-read.sh` and so runs the `[ -n "${GF_STDIN_TIMEOUT_OVERRIDE:-}" ]` check on every invocation, but none of the seven hooks sets the variable itself — it is a test hook, not a runtime tuning knob. An operator or CI environment that exports it would be honored by every hook that reads stdin through this helper. |
| **Wired into fixtures** | Wired in M48c: `test-class-split-invariant.sh` (five of the six abandoned-stdin hooks; the sixth deliberately runs the production 5s guard un-overridden for regression coverage) and `test-check-commit.sh` cases 23/25. |
| **Example value** | `GF_STDIN_TIMEOUT_OVERRIDE=2` (fast mode — `GF_FAST_STDIN_GUARD_MS` below is the bound that governs it). |

## `GF_RUNALL_SUITE_DIR`

| | |
|---|---|
| **Purpose** | Overrides the suite directory `tests/run-all.sh` globs for `test-*.sh` (`tests/run-all.sh:48`). Test-only — lets `tests/test-run-all.sh` point the runner at fixture directories. |
| **Required/optional** | Optional. |
| **Default when unset** | `tests` — behavior unchanged. |
| **Set in production?** | No — consumed only by the runner's own test suite. Also documented at `tests/README.md`. |
| **Example value** | `GF_RUNALL_SUITE_DIR=/tmp/fixture-suites` |

## `GF_README_PATH`

| | |
|---|---|
| **Purpose** | Overrides the README path `tests/test-readme-counts.sh` pins its hand-typed counts against (`tests/test-readme-counts.sh:32`). Test-only — exists so the G-RULES §H falsifiability probe can point the suite at a scratch copy with one count neutered and confirm RED without touching the production `README.md`. |
| **Required/optional** | Optional. |
| **Default when unset** | `README.md` at the repo root — behavior unchanged. |
| **Set in production?** | No — consumed only by the count-pinning suite and its probe. |
| **Example value** | `GF_README_PATH=/tmp/README-probe.md` |

## Test-suite constants (not environment variables)

Sourced from `tests/lib/timing-bounds.sh` — declared once as shell constants
inside test suites, never read from the process environment. Listed here only
because their `GF_`-prefixed names read like the env var above at a glance.

| Constant | Value | What it bounds |
|---|---|---|
| `GF_HOOK_STDIN_GUARD_MS` | `65000` | A hook invoked with stdin attached to an abandoned pipe (no writer, no EOF) must return once its 5s stdin guard fires plus MSYS subprocess overhead. Since M48c its single consumer is the production-mode (un-overridden) post-commit-cleanup case in `test-class-split-invariant.sh`. |
| `GF_LIB_READ_WINDOW_MS` | `6000` | `gf_read_stdin_timeout` called directly with a 1s timeout, no hook body, no subprocess fan-out. |
| `GF_FAST_STDIN_GUARD_MS` | `30000` | A hook invoked in override mode (`GF_STDIN_TIMEOUT_OVERRIDE` set, ~2s fast-mode guard) — wired into test runs by M48c. Validated 2026-08-21: quiet-machine worst 6806ms across 40 samples, loaded-machine (full 16-core saturation) worst 12849ms; 30000 clears 2× the loaded worst, 25698ms rounded up (evidence comment in `tests/lib/timing-bounds.sh`). |

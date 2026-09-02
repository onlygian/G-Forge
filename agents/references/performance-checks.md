# performance-auditor — expanded category examples (maintainer reference)

Maintainer-facing; not read at dispatch. Full trigger elaborations behind the one-line
categories in `agents/performance-auditor.md`.

**Algorithmic complexity** — nested loops over unbounded collections (O(n²) or worse);
sorting inside a function called on every render/request when the result could be
cached; linear search (find/filter) inside another loop.

**Database / API N+1** — a query or API call inside a loop that iterates over a
collection, where a single batched query or a join would do the same work in one round
trip.

**Hot path waste** — regex compilation (`new RegExp(...)`) inside a frequently called
function: the compiled regex should be a module-level constant. Object/array
construction inside tight loops when the structure is static. Expensive computation
(sorting, deep cloning, serialization) triggered on every state change.

**UI re-render issues** (React, Vue, etc.) — state updates that trigger re-renders of
components with no dependency on the changed state; missing memoization on expensive
computed values passed as props; event handler functions recreated on every render
without `useCallback`/`computed`.

**Resource leaks** — event listeners added in a component/hook without a corresponding
cleanup/removal; subscriptions or timers started without teardown — the leak grows with
every mount cycle and only surfaces under sustained real use.

## Severity scale — full definitions

Same Critical/Major/Minor scale as the return block and the review-orchestrator, so
nothing is mis-bucketed downstream:

- **Critical** — a hot-path blow-up that will degrade or break production under real
  load: unbounded O(n²)/O(n³) on user-scaled data, an N+1 across a request, a memory
  leak that grows without bound.
- **Major** — a real, measurable inefficiency that should be fixed before merge but
  won't take the system down: avoidable re-renders, a missing index-backed lookup,
  repeated work hoistable out of a loop.
- **Minor** — a micro-optimization or defense-in-depth improvement with no user-visible
  impact.

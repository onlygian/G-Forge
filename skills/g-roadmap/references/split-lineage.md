# g-roadmap Step 3 — split-lineage naming rationale

Load only when this run is breaking an existing, already-milestoned scope into sub-milestones (whether invoked from `/g-plan`'s Step 3c context-budget gate or run manually for the same reason). The suffix itself comes from `scripts/split-suffix.sh <parent-id>`.

The milestone/plan ID being split may already carry a trailing `-split<N>` marker (e.g. `M47-split1`) from an earlier split. Grep the parent ID/slug for `-split[0-9]+` before naming the sub-milestones. No existing marker → each sub-milestone ID gets `-split1` appended. An existing `-split<N>` marker → each sub-milestone ID has that marker replaced with `-split<N+1>` (parent depth + 1).

Why the marker exists: `/g-plan`'s Step 3c context-budget gate reads the `-split<N>` suffix back to decide whether a further automatic split is offered — an already-split milestone that still blows the budget gets escalated instead of endlessly re-split. This is why the suffix must land on the ID regardless of which surface triggered this run, and why the pattern is deliberately not end-anchored on the read side (`M47-split1-auth` still reads depth 1). /g-roadmap is the only writer of the convention; /g-plan Step 3c is its reader.

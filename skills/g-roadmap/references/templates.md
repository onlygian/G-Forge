# g-roadmap — presentation and file templates

Load each block at the step that renders it. The Step 5 skeleton and status key are a cross-skill contract — `/g-init` writes the same skeleton and the same status key — render them byte-identical.

## Step 3 — Proposed sequence block

```
M1[-split<N>] — [Title]  [MVP / post-MVP]
     Goal: ...
     Scope: ...
     Depends on: —
     Version: v[x.y.z]  ([minor/patch/major] — [one-line reason])
     Risk: ...

M2[-split<N>] — [Title]  [MVP / post-MVP]
     Goal: ...
     Scope: ...
     Depends on: M1
     Version: v[x.y.z]  ([minor/patch/major] — [one-line reason])
     Risk: ...

...

Backlog (no milestone assigned yet):
     · [items that don't clearly belong to any milestone]
```

`[-split<N>]` — append per the split-lineage naming rule (Step 3) only when this run is breaking an existing milestone into sub-milestones; omit it entirely for a normal milestone ID.

## Step 4 — PROPOSED ROADMAP banner

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROPOSED ROADMAP — [Project Name]
Current version: v[x.y.z]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M1 — [Title]  [MVP]  → v[x.y.z]
  Goal: [one line]
  Scope:
    · [item]
    · [item]
  Depends on: —

M2 — [Title]  [post-MVP]  → v[x.y.z]
  Goal: [one line]
  Scope:
    · [item]
  Depends on: M1

...

Backlog:
  · [item]

Version plan:  v[current] → v[M1] → v[M2] → ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 5 — g-docs/ROADMAP.md skeleton

```markdown
# Roadmap

## Milestones

### M1[-split<N>] — [Title]
**Status:** ⬜ Not started
**Version:** v[x.y.z]
**Goal:** [one line]
**Scope:**
- [item]
- [item]

**Depends on:** —

---

### M2[-split<N>] — [Title]
**Status:** ⬜ Not started
**Version:** v[x.y.z]
...

## Backlog
- [item]
```

`[-split<N>]` — same conditional as the Step 3 template above: append only when this run is breaking an existing, already-milestoned scope into sub-milestones; omit for a normal milestone ID.

Milestone status key: ⬜ Not started · 🔄 In progress · ✅ Complete

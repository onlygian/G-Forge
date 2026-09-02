# Step 2 — version research: scope rules, extraction lists, version-note format

Load trigger: read this when running Step 2 (research current stable/LTS state).

## Sources — context7 preferred, WebSearch fallback

Prefer the context7 MCP tools when they are available in the session: `resolve-library-id` for the stack, then `query-docs` for its current stable/LTS version and any changed recommended patterns — cheaper and more precise than a web search. Guard against context7's one soft failure mode: when the corpus lacks the queried concept it returns adjacent-but-off-topic snippets with no error signal — if the returned snippets do not mention the queried concept, treat the corpus as silent (fall back to WebSearch), never as an answer.

WebSearch fallback — run in parallel, one pair per stack:
- `"[stack] stable release [current year]"`
- `"[stack] best practices [current year]"`

## Scope rules — strict

- Only consider releases tagged as **stable**, **LTS**, or **GA (generally available)**.
- Ignore anything labelled alpha, beta, RC, canary, nightly, preview, experimental, or unreleased.
- If the only available information is pre-release, skip and note: "No stable/LTS data found — profile defaults apply."

## Extract per stack (skip if not found in stable/LTS sources)

- Current stable version number (and LTS version if the ecosystem tracks both separately)
- Any **breaking changes or major deprecations** since the prior major version — only if they affect recommended code patterns (file structure, API surface, idioms)
- Any **updated recommended patterns** that differ from what the profile likely captures (e.g., a new router API replacing the old one, a new state management recommendation, a compiler option that is now the default)

## Do not extract

- Changelogs, release notes verbatim, or lists of bug fixes
- Minor patch details
- Anything still behind a feature flag or opt-in experimental API

## Version-note format — synthesise one per stack

```
[stack] — stable [version] (LTS: [version or "same"])
Notable since last major:
  • [change 1 — one line, code-impact only]
  • [change 2]
  (or: "No material pattern changes found.")
```

If a stack returns no stable-version data after searching, note `"stable version not confirmed — profile defaults apply"` and continue.

Store all version notes for use in Step 4 (confirmation) and Step 6 (agent installation, where the note is appended to each installed architect).

Version notes are informational — they never override profile rules. If a current stable pattern contradicts a profile rule, surface the conflict to the developer during confirmation; do not silently rewrite the rules file.

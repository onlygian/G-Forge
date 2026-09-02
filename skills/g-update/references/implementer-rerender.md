# Step 5 — implementer agent re-render procedure

Load this only when Step 2's inventory reports at least one `class=implementer`
agent (the edge fires only on specialized projects). The trigger condition and
the skip rule for `feature-implementer` (a shipped agent, not a per-stack one)
live in SKILL.md Step 5.

For each `*-implementer` agent file found in Step 2, re-render it from the
current implementer template so template improvements propagate:

1. Read the implementer template `[plugin-root]/templates/stack-implementer.md`.
2. Recover the substitutions from the installed file's frontmatter:
   - `{{IMPLEMENTER_NAME}}` — its `name:` field.
   - `{{ARCHITECTURE_SKILL}}` — its existing `skills:` entry.
   - `{{ARCHITECT_NAME}}` — the implementer name with `-implementer` →
     `-architect`.
   - `{{STACK_LABEL}}` — from its description (or the matching architect's).
3. Re-derive `{{OWNS_GLOBS}}` from the stack's **current** plugin architecture
   rules (`[plugin-root]/profiles/[stack]/rules/architecture.md`) by running
   `skills/g-specialize/scripts/derive-owns.sh` (under `[plugin-root]`) — that
   script is the one owner of the layer-map → glob conversion, shared with
   `/g-specialize`; never re-derive the globs by hand here. Rule changes
   propagate through it; if no globs can be derived, remove the `owns:` key.
4. Substitute, strip the leading template-usage comment, and overwrite the
   file.

If an implementer's stack skill no longer exists in the plugin, tell the
developer: "Could not find a current profile for `[name]` — skipping." Do not
delete the file.

Report `✓ .claude/agents/[filename] — updated` for each re-rendered agent
(same report line as the architect branch).

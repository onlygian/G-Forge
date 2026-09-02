# Self-host source-root detection — why and how

Load this when `scripts/detect-state.sh`'s `SELF_HOST` verdict looks wrong, or a maintainer asks why the split exists.

**Self-host detection:** root `.claude-plugin/plugin.json` exists AND its `name` matches the plugin's own name (`g-forge`) → the source root flips from the plugin cache to the working tree (self-host mode); every plugin-cache Glob resolves through this detected source root instead. Consumer projects (no root `.claude-plugin/plugin.json`) are structurally unaffected — detection cannot fire there, and the plugin-cache path is the fallback branch, unchanged.

- **Self-host mode on:** `[plugin-root]` = the project root itself. Every step that references `[plugin-root]` or "the plugin cache" uses this working-tree path directly — no Glob into `~/.claude/plugins/cache/` is needed. This is what lets the G-Forge repo itself run `/g-init` against its own uncommitted sources rather than a stale installed copy.
- **Self-host mode off (fallback branch — every consumer project):** `[plugin-root]` resolves via Glob into `~/.claude/plugins/cache/g-forge/g-forge/`, using the highest-versioned entry found.

Step 1a is the single source-root resolution point: `[plugin-root]` is resolved there once and reused everywhere. Never hardcode `~/.claude/plugins/cache/...` outside that step's fallback branch.

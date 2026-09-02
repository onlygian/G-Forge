# Recommended MCPs (printed at the end of Step 8)

**Recommended MCPs** — install these in Claude Code for best results with G-Forge:
- `context7` — pulls current library docs into context, eliminates stale-training hallucinations
- `github` — read PRs, diffs, issues directly from chat
- `supabase` — SQL, migrations, schemas from chat (install if your project uses Supabase)

To install: Claude Code → Settings → MCP Servers, or add to `~/.claude/settings.json` under `mcpServers`.

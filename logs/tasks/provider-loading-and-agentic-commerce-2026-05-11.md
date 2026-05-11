# Provider Loading and Agentic Commerce Fix - 2026-05-11

## Summary
- Added visible lifecycle loading for provider install, run, stop, and delete actions.
- Lifecycle buttons now stay disabled while an active backend task exists for the provider.
- Added task progress strip using `/api/tasks/active`.
- Increased Agentic Commerce MCP browser timeout from 65s to 180s for slow first-run agent calls.
- Patched Agentic Commerce setup scripts so future clone/install runs apply the timeout fix after pulling upstream source.

## Verification
- `npm.cmd run typecheck --prefix frontend`: pass.
- `bash -n setup.sh providers/agentic-commerce-blueprint/scripts/linux/setup.sh`: pass.
- PowerShell parser check for `providers/agentic-commerce-blueprint/scripts/windows/setup.ps1`: pass.
- Rebuilt and restarted the current Agentic Commerce `ui` container.
- Direct MCP smoke test through `http://127.0.0.1:8088/apps-sdk/api/mcp`: pass in 3 seconds.

## Provider Upstream Push
- Repository: `https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-`
- Commit: `426454f35b2900554183d951f9ee4387207f8b90`
- Message: `fix(ui): extend MCP client timeout`
- Provider verification before push: `corepack pnpm run typecheck` from `src/ui`: pass.

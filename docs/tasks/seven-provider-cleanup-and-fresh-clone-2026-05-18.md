# Seven Provider Cleanup and Fresh Clone Readiness

Date: 2026-05-18

## Goal

Keep AI Hub focused on seven active providers and make the repository clearer for a fresh clone on a new machine.

## Active Providers

- `agentic-commerce-blueprint`
- `ai-virtual-assistant-provider`
- `aiq`
- `nemotron-voice-agent-provider`
- `shop-retail-provider`
- `multi-agent-intelligent-warehouse`
- `pdf-to-podcast`

## Changes

- Removed inactive provider folders outside the seven-provider catalog.
- Updated backend provider seed logic so setup reads real provider manifests instead of restoring old mock providers.
- Updated frontend fallback data and typing so the UI fallback catalog matches backend provider contracts.
- Archived Ambient Healthcare docs as removed-provider history instead of active integration documentation.
- Updated README with fresh clone instructions, active provider table, lifecycle notes, CI/CD checks, and release packaging guidance.
- Added `banner.jpg` at the repository root for README hero usage.
- Updated provider delete wrappers so provider-owned Docker Compose cleanup runs before deploy removal, including volumes, orphans, and local images.
- Hardened Windows deploy removal for transient locked files by retrying, clearing read-only attributes, and deferring cleanup after a safe rename without killing unrelated processes.
- Restricted AIQ Windows stop fallback process termination to processes running from `deploy/aiq`.
- Moved provider UI defaults away from Hub frontend dev ports: Shop Retail uses `13000`, AI Virtual Assistant uses `13001`, and Warehouse uses `13002` with nginx on `13003`.
- Added backend lifecycle protection so provider scripts are blocked if a local config tries to use reserved Hub frontend ports `3000` or `3001`.

## Verification

- Backend provider registry/API contract subset passed after updating the seven-provider expectations.
- Frontend provider detail tests passed.
- Frontend TypeScript typecheck passed after adding provider command typing.
- PowerShell and Bash provider delete script syntax checks passed.
- Windows dry-run delete passed for all seven active providers.
- Windows setup-delete verification passed for all seven active providers.
- Provider manifest validation passed with exactly seven manifests.
- Backend provider tests passed: provider registry, API contract, and lifecycle subsets all green.
- Reserved-port regression test passed: lifecycle scripts fail before execution when a provider is configured to use Hub frontend port `3000`.
- Frontend TypeScript typecheck passed after updating fallback provider ports.

## Remaining Release Gate

Before final push/release, run the full backend suite, frontend suite, provider validation, secret scan, script syntax checks, build workflows, and CI status monitoring.

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

## Verification

- Backend provider registry/API contract subset passed after updating the seven-provider expectations.
- Frontend provider detail tests passed.
- Frontend TypeScript typecheck passed after adding provider command typing.

## Remaining Release Gate

Before final push/release, run the full backend suite, frontend suite, provider validation, secret scan, script syntax checks, build workflows, and CI status monitoring.

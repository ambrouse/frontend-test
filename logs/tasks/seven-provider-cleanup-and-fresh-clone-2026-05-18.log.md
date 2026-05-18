# Seven Provider Cleanup and Fresh Clone Readiness Log

Date: 2026-05-18

## Summary

Cleaned AI Hub provider catalog down to seven active providers and updated supporting docs, README, and banner assets.

## Completed

- Removed inactive providers outside the official seven-provider list.
- Updated backend provider registry tests for exact provider count and IDs.
- Fixed AIQ detail contract expectation to port `13080`.
- Fixed provider query regression test to use `AI-Q` display-name search.
- Added frontend provider command types so fallback manifest data typechecks.
- Confirmed backend provider registry/API subset passed.
- Confirmed frontend provider detail tests passed.
- Confirmed frontend typecheck passed.
- Updated README and archived Ambient provider docs.
- Created root `banner.jpg`.

## Safety

No secrets, API keys, runtime local config, provider logs, Docker volumes, or deploy artifacts should be included in commits.

## Validation

- Backend provider registry/API contract subset: passed.
- Full backend pytest suite: passed.
- Backend Ruff lint: passed.
- Backend Ruff format check: passed after formatting backend files.
- Backend mypy typecheck: passed.
- Provider manifest/catalog validation: passed with an exact seven-provider gate.
- Provider dry-run lifecycle: passed for the dry-run eligible providers.
- Backend latency benchmark: passed under the configured threshold.
- Repository secret scan: passed.
- Frontend provider detail tests: passed.
- Frontend TypeScript typecheck: passed.
- Frontend unit tests: passed.
- Frontend production build: passed.
- PowerShell provider script syntax check: completed without reported parser errors.
- Provider delete cleanup update: Windows and Linux delete wrappers now call provider-specific Docker Compose cleanup with volumes, orphans, and local image removal before removing deploy directories.
- Windows delete robustness: deploy removal now retries locked files, clears read-only attributes, and renames locked deploy folders for deferred cleanup if needed without killing unrelated processes.
- AIQ Windows stop safety: port-bound process termination is restricted to processes whose command line is inside `deploy/aiq`.
- Seven-provider Windows setup-delete verification: passed for `agentic-commerce-blueprint`, `ai-virtual-assistant-provider`, `aiq`, `nemotron-voice-agent-provider`, `shop-retail-provider`, `multi-agent-intelligent-warehouse`, and `pdf-to-podcast`.
- Provider manifest/catalog validation after delete cleanup changes: passed with 7 manifests.
- Backend provider tests after delete cleanup changes: 14 passed across provider registry, API contract, and lifecycle tests.
- Frontend interruption follow-up: repeated syntax, dry-run delete, seven-provider setup-delete, provider validation, and backend provider tests after removing shared auto-kill behavior; all passed.
- Frontend install crash follow-up: identified remaining risk as provider UI port collisions with Hub dev ports `3000`/`3001`; moved Shop Retail to `13000`, AI Virtual Assistant to `13001`, Warehouse to `13002`, and Warehouse nginx to `13003`.
- Added backend reserved-port guard and regression test so provider lifecycle scripts fail before execution if a local config attempts to use `3000` or `3001`.
- Validation after port-collision fix: provider manifests passed, backend provider tests passed with 15 tests, frontend typecheck passed, seven-provider Windows setup-delete passed, and `deploy/` was clean.

## Next

Stage only provider cleanup and task documentation/log files, commit, push, then monitor CI.

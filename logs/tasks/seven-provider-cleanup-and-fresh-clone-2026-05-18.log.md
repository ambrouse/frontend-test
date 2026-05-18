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

## Next

Stage only project cleanup/release files, commit, push, monitor CI, then create release artifacts if CI stays green.

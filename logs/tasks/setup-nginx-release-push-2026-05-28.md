# Setup, Nginx, and Release Push - 2026-05-28

## 10:39 Start

- User requested a GitHub push and asked to format README, docs, logs, plans, and tests according to `.codex` skills.
- Applied skills: `push-code-skill`, `readme-style`, `documentation-skill`, `logging-skill`, `plan-skill`, and `testing-skill`.
- Created plan: `plans/plan-setup-nginx-release-push.md`.

## Cleanup and Documentation

- Kept the current setup/provider fixes in the worktree.
- Normalized legacy evidence path references to the current `tests/` folder in the relevant provider validation logs/plans.
- Added setup and Nginx operations doc: `docs/setup-and-nginx-gateway-2026-05-28.md`.
- Updated README to include the setup/gateway note in the docs index.
- Confirmed `providers/*/runtime/*`, provider logs, `deploy/`, `.env`, and `.env.local` remain ignored.

## Verification Summary

- `printf '\n' | ./setup.sh`: passed; seeded 8 providers and reported 0 npm vulnerabilities.
- `bash -n setup.sh`: passed.
- `npm ci --prefix frontend`: passed.
- `npm audit --prefix frontend --audit-level=moderate`: passed with 0 vulnerabilities.
- `npm run typecheck --prefix frontend`: passed.
- `npm test --prefix frontend`: 9 passed.
- `./.venv/bin/python -m pytest backend/tests`: 24 passed.
- `./.venv/bin/python backend/scripts/validate_providers.py`: validated 8 provider manifests.
- `docker compose -f docker-compose.nginx.yml config -q`: passed.
- `docker exec ai-hub-nginx nginx -t`: passed.
- Evidence hygiene:
  - README files under `tests/` are non-empty.
  - No temporary `.har`, `.log`, `.json`, or `.tmp` evidence files found under `tests/`.
  - Duplicate image hash scan returned no duplicates.

## Notes

- Current validation host is Linux ARM/aarch64. Setup logic remains architecture-neutral for Linux AMD64.
- PowerShell is not installed on this host, so `setup.ps1` was reviewed by source inspection rather than executed here.
- The shell has `NODE_TLS_REJECT_UNAUTHORIZED=0` set outside the project; setup does not create that variable.

# Plan: Setup Nginx Release Push

- Created: 2026-05-28 10:39
- Updated: 2026-05-28 10:39
- Status: closed
- Related log: logs/tasks/setup-nginx-release-push-2026-05-28.md

## Goal

Prepare the accumulated setup, Nginx, provider wrapper, evidence, and documentation changes for a clean push to `origin/main`.

## Scope

- In:
  - Review dirty worktree and keep current provider/setup fixes.
  - Normalize README, docs, logs, plans, and tests/evidence paths.
  - Verify setup, frontend, backend, provider manifests, Nginx config, dependency audit, and secret hygiene.
  - Commit with a timestamped message and push to GitHub.
- Out:
  - Re-running every provider end-to-end again.
  - Editing ignored `.env`, provider runtime state, or deployed source clones.

## Skills

- push-code-skill
- readme-style
- documentation-skill
- logging-skill
- plan-skill
- testing-skill

## Phases

| Phase | Goal | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Inspect dirty tree, remotes, docs/logs/plans/tests, and secret risk | done | `git status --short`, remote `origin/main`, secret scan by filename |
| 2 | Normalize docs/logs/plans/tests and add setup gateway documentation | done | `docs/setup-and-nginx-gateway-2026-05-28.md`, README docs index, updated evidence path references |
| 3 | Run verification before commit | done | Frontend tests/typecheck, backend tests, provider validation, setup rerun, audit, Nginx config |
| 4 | Commit and push | done | Commit on `main`, pushed to `origin/main` |

## Verification

- `printf '\n' | ./setup.sh`
- `bash -n setup.sh`
- `npm ci --prefix frontend`
- `npm audit --prefix frontend --audit-level=moderate`
- `npm run typecheck --prefix frontend`
- `npm test --prefix frontend`
- `./.venv/bin/python -m pytest backend/tests`
- `./.venv/bin/python backend/scripts/validate_providers.py`
- `docker compose -f docker-compose.nginx.yml config -q`
- `docker exec ai-hub-nginx nginx -t`
- Evidence hygiene: README presence, temp artifact scan, duplicate image hash scan, secret filename scan.

## Close Criteria

- Setup rerun is clean on the current Linux host.
- Windows setup script is syntax-reviewed by inspection and keeps platform-native paths.
- Docs/logs/plans/tests point at current `tests/` evidence.
- No tracked runtime files or raw secrets are committed.
- Push to GitHub completes.

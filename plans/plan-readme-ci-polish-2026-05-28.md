# Plan: README and CI Polish

- Created: 2026-05-28 10:54
- Updated: 2026-05-28 11:02
- Status: closed
- Related log: logs/tasks/readme-ci-polish-2026-05-28.md

## Goal

Fix the GitHub README presentation so the banner does not render cropped, make the README visually richer while keeping the existing content accurate, and strengthen CI with setup, docs/evidence, Nginx, and security gates.

## Scope

- In:
  - GitHub-safe README hero markup and richer badge/table presentation.
  - CI workflow additions for setup smoke, docs/evidence hygiene, Nginx config, local link checks, dependency review, and CodeQL.
  - Documentation/log updates for the polish pass.
  - Local verification before commit and push.
- Out:
  - Changing product runtime behavior.
  - Replacing provider evidence screenshots.
  - Rebuilding provider source repositories.

## Skills

- readme-style
- push-code-skill
- plan-skill
- documentation-skill
- logging-skill
- testing-skill
- security-skill

## Phases

| Phase | Goal | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Audit banner and current CI | done | `banner.gif` is `1120x501`; current CI lacks setup/nginx/docs/link/security-analysis gates |
| 2 | Polish README presentation | done | GitHub-safe `<img width="100%">`, richer badges, visual cards and status tables |
| 3 | Harden CI | done | Updated `.github/workflows/ci.yml`; added `.github/workflows/security.yml` |
| 4 | Verify locally | done | Workflow syntax, tests, audit, secret scan, docs/evidence hygiene, build |
| 5 | Commit and push | done | Timestamped commit pushed to `origin/main` |

## Verification

- `bash -n setup.sh`
- Provider Linux script syntax
- `npm run typecheck --prefix frontend`
- `npm test --prefix frontend`
- `npm audit --prefix frontend --audit-level=moderate`
- `./.venv/bin/python -m pytest backend/tests`
- `./.venv/bin/python backend/scripts/validate_providers.py`
- `./.venv/bin/python backend/scripts/check_no_secrets.py`
- `docker compose -f docker-compose.nginx.yml config -q`
- README/docs local-link and evidence hygiene checks.

## Close Criteria

- README banner uses explicit width and renders without markdown auto-cropping.
- README has a richer GitHub-friendly visual system without inaccurate claims.
- CI includes setup, docs/evidence, Nginx, dependency review, and CodeQL gates.
- Local verification passes.
- Changes are committed and pushed.

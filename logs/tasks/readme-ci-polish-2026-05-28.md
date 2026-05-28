# README and CI Polish - 2026-05-28

## 10:54 Start

- User reported that the GitHub banner appears cropped and that CI/README presentation still feels too plain.
- Applied skills: `readme-style`, `push-code-skill`, `plan-skill`, `documentation-skill`, `logging-skill`, `testing-skill`, and `security-skill`.
- Created plan: `plans/plan-readme-ci-polish-2026-05-28.md`.

## Audit

- `banner.gif` is a `1120 x 501` GIF. README used plain markdown image syntax, which gives less control over GitHub rendering.
- Existing CI already had cross-platform frontend/backend tests, provider script syntax, release artifacts, audits, provider validation, dry-run lifecycle, and latency benchmark.
- Missing CI gates identified:
  - setup smoke from root script;
  - Nginx compose/template validation;
  - docs/evidence local-link and artifact hygiene;
  - dependency review on pull requests;
  - CodeQL analysis for Python and JavaScript/TypeScript.

## Planned Changes

- Replace the README banner markdown with explicit HTML image markup using `width="100%"`.
- Add richer GitHub-friendly shields, status boards, provider matrix badges, and command cards while keeping the current technical content.
- Extend CI with repository hygiene and setup/Nginx checks.
- Add security workflow for dependency review and CodeQL.

## Changes Applied

- Updated README hero, badges, provider matrix, quick-start cards, and architecture diagram.
- Added `docs/ci-and-readme-polish-2026-05-28.md`.
- Extended `.github/workflows/ci.yml` with repository hygiene and setup smoke jobs.
- Added `.github/workflows/security.yml` for Dependency Review and CodeQL.

## Verification

- `actionlint`: passed for GitHub workflow syntax.
- README/docs local-link check: checked 118 markdown files.
- Evidence hygiene: README presence, temp artifact scan, and duplicate image scan passed.
- `docker compose -f docker-compose.nginx.yml config -q`: passed.
- `docker exec ai-hub-nginx nginx -t`: passed.
- `npm run typecheck`: passed.
- `npm test`: 9 passed.
- `npm audit --audit-level=moderate`: found 0 vulnerabilities.
- `./.venv/bin/python -m pytest backend/tests`: 24 passed.
- `./.venv/bin/python backend/scripts/validate_providers.py`: validated 8 provider manifests.
- `./.venv/bin/python backend/scripts/check_no_secrets.py`: passed.
- `printf '\n' | ./setup.sh`: passed and seeded 8 providers.
- `npm run build`: passed.
- Backend `ruff check`, `ruff format --check`, and `mypy app`: passed.

## Result

- README is more visually structured for GitHub while preserving the same technical content.
- Banner now uses responsive HTML image markup instead of plain markdown image syntax.
- CI now covers root setup, repository hygiene, Nginx config, Dependency Review, and CodeQL in addition to existing frontend/backend/provider gates.
- Final step: commit and push this polish pass to `origin/main`.

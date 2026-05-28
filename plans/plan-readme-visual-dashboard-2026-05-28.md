# Plan: README Visual Dashboard

- Created: 2026-05-28 11:07
- Updated: 2026-05-28 11:17
- Status: closed
- Related log: logs/tasks/readme-visual-dashboard-2026-05-28.md

## Goal

Make the README more visually distinctive with AI/tech dashboard sections, image proof panels, GIF/banner presence, and stronger GitHub-safe design.

## Scope

- In:
  - Add dashboard/stat cards and visual evidence panels to README.
  - Use existing curated screenshots from `tests/`.
  - Update CI local-link checker for HTML `href`/`src`.
  - Add docs/log/plan for the polish pass.
- Out:
  - Replacing provider evidence screenshots.
  - Rebuilding the app UI or provider UIs.
  - Adding fake generated pass evidence.

## Skills

- readme-style
- documentation-skill
- logging-skill
- testing-skill
- push-code-skill

## Phases

| Phase | Goal | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Add README dashboard and proof board | done | `README.md` |
| 2 | Update CI link hygiene for HTML assets | done | `.github/workflows/ci.yml` |
| 3 | Document and log | done | `docs/readme-visual-dashboard-2026-05-28.md`, this plan, related log |
| 4 | Verify and push | done | Local link/evidence/test checks passed; ready to push |

## Verification

- README/docs local link check, including Markdown and HTML links.
- Evidence hygiene check.
- `actionlint`.
- Frontend typecheck/test.
- Backend provider/secret checks as needed.

Completed verification:

- `actionlint -color`
- README/docs/logs/plans/tests/infra local link check, including Markdown and HTML links
- Evidence hygiene duplicate/temp/empty README scan
- Frontend typecheck, unit tests, build, and audit
- Backend provider validation, secret scan, ruff, format, mypy, coverage tests, provider dry-run, benchmark, OpenAPI smoke, package build, and pip-audit
- `bash -n setup.sh`, provider Linux script syntax, and Docker Compose Nginx config

## Close Criteria

- README has richer dashboard-style visual sections.
- All local README image/link references resolve.
- No temporary evidence or secret is introduced.
- Commit is pushed to `origin/main`.

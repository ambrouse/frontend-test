# README Visual Dashboard - 2026-05-28

## Purpose

This note records the README visual dashboard pass requested after the initial CI and banner polish.

## Changes

- Added `AI Ops Cockpit` near the top of the README:
  - GitHub stats card;
  - top language card;
  - streak card;
  - local quality signal badges for provider count, test counts, audit, Nginx, and screenshot evidence.
- Added `Visual Proof Board`:
  - LAN Hub provider dashboard;
  - Agentic Commerce checkout evidence;
  - AI-Q file-grounded chat evidence;
  - Warehouse agent output evidence;
  - PDF to Podcast generation evidence;
  - Web Agent search-with-sources evidence.
- Updated CI markdown hygiene to validate local HTML `href` and `src` references as well as Markdown links.

## Constraints

- GitHub Markdown strips custom CSS, so the dashboard uses safe HTML tables, shields, local images, and external SVG stat cards.
- The screenshots are existing curated evidence under `tests/`; no generated or fake UI evidence was introduced.

## Verification

- `actionlint -color`
- Local README/docs/logs/plans/tests/infra link validation for Markdown links and HTML `href`/`src`
- Evidence hygiene scan for empty evidence README files, temporary artifacts, and duplicate image hashes
- Frontend typecheck, unit tests, build, and audit
- Backend lint/type/test/security/provider checks, OpenAPI smoke, package build, benchmark, and pip-audit

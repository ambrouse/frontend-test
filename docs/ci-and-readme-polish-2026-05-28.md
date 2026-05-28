# CI and README Polish - 2026-05-28

## Purpose

This note records the GitHub presentation and CI/CD hardening pass for AI Hub.

## README Presentation

- The banner is rendered with explicit HTML image markup:
  - source path: root `banner.gif`
  - `width="100%"`
  - descriptive alt text
- This avoids GitHub Markdown's default image sizing behavior and keeps the banner responsive in the repository view.
- README visual density is improved with GitHub-safe elements:
  - `for-the-badge` shields for build/runtime signals;
  - HTML tables for card-like sections;
  - provider matrix badges;
  - collapsible setup sections;
  - updated Mermaid architecture including the Nginx gateway.

## CI/CD Additions

The main CI workflow now includes:

- Cross-platform frontend typecheck, tests, and build.
- Cross-platform backend lint, format, typecheck, tests, package build, provider validation, dry-run lifecycle, secret scan, and latency benchmark.
- Provider Bash and PowerShell syntax validation.
- Frontend dependency audit.
- Repository hygiene:
  - local README/docs link checks;
  - evidence README checks;
  - temporary evidence artifact rejection;
  - duplicate evidence image detection;
  - Nginx Docker Compose config and `nginx -t`.
- Root setup smoke test without secrets.

The security workflow now includes:

- Dependency Review on pull requests.
- CodeQL for Python and JavaScript/TypeScript.
- Weekly scheduled security analysis.

## Notes

- The CI gates intentionally avoid requiring real provider secrets.
- Provider full-function proof remains documented in `tests/` evidence folders.
- CodeQL and Dependency Review require GitHub Advanced Security availability depending on repository plan/settings.

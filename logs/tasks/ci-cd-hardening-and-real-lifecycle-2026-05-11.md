# CI/CD Hardening + Real Lifecycle Verification

## 2026-05-11 (Asia/Saigon)

- Cleaned old deploy clones under `deploy/` and kept only `.gitkeep`.
- Executed real lifecycle loops for both target providers through backend task APIs:
  - `agentic-commerce-blueprint`
  - `multi-agent-intelligent-warehouse`
- Real sequence `install -> run -> stop -> delete` completed successfully:
  - 2 full rounds before CI/CD hardening
  - 1 full rerun after fixes

## Fixes Applied During Verification

- Hardened secret scan script to skip git-ignored local files (for example `.env.local`) while still scanning tracked project files.
- Fixed frontend Vitest alias resolution so tests resolve `@/` imports correctly on Windows/Linux/macOS.
- Normalized backend formatting/lint compliance for strict CI gates.

## CI/CD Hardening

- Replaced legacy mixed workflow with strict unified `CI` workflow:
  - workflow lint (`actionlint`)
  - frontend matrix: Ubuntu + Windows + macOS
  - backend matrix: Ubuntu + Windows + macOS
  - security/dependency audits
  - provider script syntax gates
  - backend package build gate
- Updated frontend artifact workflow to depend on `CI`.
- Added backend production artifact workflow:
  - build wheel/sdist
  - twine metadata check
  - upload artifact

## Local Verification Commands (pass)

- `python backend/scripts/validate_providers.py`
- `python backend/scripts/check_no_secrets.py`
- `python backend/scripts/provider_dry_run_lifecycle.py`
- `python backend/scripts/benchmark_latency.py --iterations 40 --warmup 10 --threshold-ms 100`
- `pytest backend --cov=app --cov-fail-under=80`
- `ruff check backend && ruff format --check backend && mypy backend/app`
- `npm run typecheck --prefix frontend`
- `npm run test --prefix frontend`
- `npm run build --prefix frontend`

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

## Follow-up Fix (same date)

- Investigated failed CI run (`bf72048`) via GitHub check-run annotations:
  - `Workflow lint`: `rhysd/actionlint@v1` could not be resolved.
  - `Backend (ubuntu/macos)`: failed at `Provider dry-run lifecycle`.
- Root cause for backend dry-run failure:
  - Linux `load_nvidia_api_key` helper in provider scripts returned non-zero when `.env.local` was missing.
  - With `set -euo pipefail`, this exited setup/run scripts early on clean CI machines.
- Applied fixes:
  - workflow lint now installs/runs `actionlint` via official download script (no unresolved action reference).
  - provider Linux scripts now use `return 0` when `.env.local` or key line is absent.
- Clean-machine bootstrap verification:
  - removed old `source-github-provider/` and `deploy/*`.
  - removed local runtime artifacts (`frontend/node_modules`, rebuilt `.venv`).
  - cloned provider sources fresh from GitHub into `source-github-provider/`.
  - reran root `setup.ps1` end-to-end successfully.

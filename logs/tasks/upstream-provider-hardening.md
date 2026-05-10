# Upstream Provider Hardening Log

## 2026-05-11 - Phase 0 audit

- Created `source-github-provider/` and cloned both upstream provider repos.
- Agentic Commerce source was at `f8878cf`; previous Node 22/pnpm pin exists.
- Warehouse source was at `30470c5`; previous local NIM opt-in profile exists.
- Remaining source-level issues:
  - Agentic compose files still declare `acp-infra-network` as external, so direct `docker compose -f docker-compose.infra.yml -f docker-compose.yml up` fails unless `runall.sh` created the network first.
  - Warehouse root `.env.example` does not include the host port variables used by compose/wrapper, so a clean user can miss port customization and collide with common local services.
  - Hub provider manifests do not yet expose OS/arch/tool/framework detail for frontend readiness UI.
  - Root Hub setup scripts detect/install Python deps but do not yet prompt-install missing Git/Node/Docker.

## 2026-05-11 - Phase 1 upstream fixes

- Agentic Commerce:
  - `f0d41b6`: compose network became self-managed.
  - `aaf098a`: removed fixed Docker network name so stale `acp-infra-network` from older installs cannot break clean runs.
  - `f90df7a`: moved one-shot `milvus-seeder` behind `seed` profile and updated `runall.sh`/README so `docker compose up --wait` can pass while still seeding explicitly.
- Warehouse:
  - `22e42b4`: added host port defaults to `.env.example`.
- Upstream compose config checks passed for both repos before Hub lifecycle retest.

## 2026-05-11 - Phase 2 Hub metadata/frontend

- Added provider `environment` schema: supported OS, architectures, frameworks, required tools, runtime modes, setup notes and machine readiness.
- Backend enriches provider detail with current OS/arch and cached Git/Docker/Compose availability.
- Frontend detail page now renders runtime requirements, tool readiness, framework chips and runtime modes per provider.
- Updated provider manifests for Agentic Commerce and Warehouse with real Docker/API-mode requirements.

## 2026-05-11 - Phase 3 setup scripts

- `setup.ps1` now checks Git, Node/npm, Python 3.11+, Docker and Docker Compose, prompting before installing via `winget`.
- `setup.sh` now checks Git, Node/npm, Python 3.11+, Docker and Compose, prompting before installing via `apt`, `dnf`, `pacman`, or `brew` when available.
- Both scripts still create `.venv`, install backend dev deps, install frontend deps, seed providers and optionally write `.env.local`.

## 2026-05-11 - Phase 4 real lifecycle

- Real backend lifecycle test cloned from GitHub into `deploy/`, not from `source-github-provider/`.
- Agentic Commerce passed at upstream commit `f90df7a`:
  - install clone, commit assertion, compose config, run, logs, metrics, stop, delete.
- Warehouse passed at upstream commit `22e42b4`:
  - install clone, commit assertion, compose config, run, logs, metrics, stop, delete.
- Final `deploy/` cleanup verified through delete actions.

## 2026-05-11 - Phase 5 local CI

- Backend: `ruff check`, `ruff format --check`, `mypy`, `pytest` all passed.
- Provider gates: manifest validation, dry-run lifecycle, latency benchmark and secret scan passed.
- Frontend: typecheck, unit tests and production build passed.
- Latency benchmark stayed well below 100 ms p95; representative p95 values were 1.99-3.41 ms for health, hardware, provider list/detail and logs.
- Removed temporary `source-github-provider/`; `deploy/` contains only `.gitkeep` after lifecycle delete.

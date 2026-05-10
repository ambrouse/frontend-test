# AI Hub

AI Hub is a local control center for installing and running provider projects from GitHub. The web UI is Next.js, the runtime API is FastAPI, and provider source is cloned only when a user clicks Install.

## What It Runs

- Frontend: `frontend/`, Next.js 16 app with production build checks.
- Backend: `backend/`, FastAPI provider registry, hardware probe, task queue, lifecycle API, logs and metrics.
- Providers: `providers/`, small wrapper contracts that know how to install/run/stop/delete real GitHub projects.
- Deploy target: `deploy/`, ignored runtime clone directory.

Current real provider integrations:

| Provider | Source | Default port | Runtime |
| --- | --- | ---: | --- |
| Agentic Commerce Blueprint | `baolnq-ai/Agentic-Commerce-blueprint-provider-` | `8088` | Docker Compose, NVIDIA API mode |
| Multi-Agent Intelligent Warehouse | `baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia` | `8091` | Docker Compose, NVIDIA API mode |

## Quick Start

Windows PowerShell:

```powershell
.\setup.ps1
.\.venv\Scripts\python -m uvicorn app.main:app --reload --app-dir backend
cd frontend
npm run dev
```

Linux or Git Bash:

```bash
./setup.sh
./.venv/bin/python -m uvicorn app.main:app --reload --app-dir backend
cd frontend
npm run dev
```

The setup scripts check Git, Node/npm, Python 3.11+, and Docker. If a required tool is missing, the script asks before installing with `winget`, `apt`, `dnf`, `pacman`, or `brew` when available. Docker is required for real provider install/run.

## Provider Lifecycle

The frontend calls the backend API; the backend runs provider wrapper scripts:

- `POST /api/providers/{id}/install`: clone source from GitHub into `deploy/{id}` and write provider `.env`.
- `POST /api/providers/{id}/run`: start Docker Compose or the provider runtime.
- `POST /api/providers/{id}/stop`: stop runtime services.
- `DELETE /api/providers/{id}`: stop and remove the deployed source directory.
- `GET /api/providers/{id}/logs|status|metrics|config`: feed the detail page.

Provider wrappers expose OS, architecture, framework and tool requirements through `environment` metadata so the frontend can show what the current machine has before install.

## Verification

Backend:

```powershell
.\.venv\Scripts\python -m ruff check backend
.\.venv\Scripts\python -m ruff format --check backend
.\.venv\Scripts\python -m mypy backend\app
.\.venv\Scripts\python -m pytest backend
.\.venv\Scripts\python backend\scripts\validate_providers.py
.\.venv\Scripts\python backend\scripts\provider_dry_run_lifecycle.py
.\.venv\Scripts\python backend\scripts\benchmark_latency.py --threshold-ms 100
.\.venv\Scripts\python backend\scripts\check_no_secrets.py
```

Frontend:

```powershell
npm.cmd run typecheck --prefix frontend
npm.cmd run test --prefix frontend
npm.cmd run build --prefix frontend
```

Script syntax:

```powershell
# PowerShell parser
Get-ChildItem providers -Recurse -Filter *.ps1 | % {
  $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$null,[ref]$e); if($e){throw $e}
}

# Bash parser
bash -lc "bash -n setup.sh && find providers -path '*/scripts/linux/*.sh' -print0 | xargs -0 -n1 bash -n"
```

## CI/CD

GitHub Actions runs:

- frontend install, typecheck, unit tests and production build;
- backend lint, format, mypy, pytest, provider manifest validation, dry-run lifecycle, latency benchmark and secret scan;
- setup script syntax checks for Windows/Linux paths.

## Notes

- Do not commit `.env`, `.env.local`, provider runtime logs, or `deploy/`.
- NVIDIA keys are accepted by setup/lifecycle requests and written only to ignored local env files.
- Hardware shortages are warnings; required missing tools are shown clearly and provider scripts return a hard error.

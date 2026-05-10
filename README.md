# AI Hub

Monorepo for the local AI Hub frontend, FastAPI runtime backend, and provider wrappers.

## Structure

- `frontend/`: Next.js frontend application.
- `backend/`: FastAPI API, hardware snapshot, provider runtime, task queue.
- `providers/`: provider manifests and cross-platform lifecycle wrappers.
- `deploy/`: ignored runtime clone target for provider source repos.
- `docs/`: provider contract and architecture notes.
- `plans/`: implementation plans.
- `logs/`: work logs.

## Setup

Windows:

```powershell
.\setup.ps1
.\.venv\Scripts\python -m uvicorn app.main:app --reload --app-dir backend
cd frontend
npm run dev
```

Linux/macOS/Git Bash:

```bash
./setup.sh
./.venv/bin/python -m uvicorn app.main:app --reload --app-dir backend
cd frontend
npm run dev
```

The setup scripts create `.venv`, install backend dev dependencies, install frontend dependencies, seed provider manifests, and optionally write `.env.local` with the NVIDIA key. Provider install clones source repos into `deploy/{provider_id}` only when the web/API install action is called.

## Verification

```bash
cd frontend
npm ci
npm run typecheck
npm run test
npm run build

cd ../backend
ruff check .
ruff format --check .
mypy app
pytest
python scripts/provider_dry_run_lifecycle.py
python scripts/benchmark_latency.py --threshold-ms 100
```

PowerShell note: if `npm.ps1` is blocked by execution policy, use `npm.cmd`.

## CI/CD

GitHub Actions runs frontend checks, backend lint/type/test/coverage gates, provider manifest validation, secret scan, dry-run provider lifecycle, and warm latency benchmark on Linux/Windows where appropriate.

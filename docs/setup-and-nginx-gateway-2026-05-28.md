# Setup and Nginx Gateway - 2026-05-28

## Purpose

This note records the current supported local setup path for AI Hub after the setup, LAN access, and Docker-managed Nginx gateway hardening.

## Setup Scripts

Use the platform-native setup script:

- Linux/macOS/Git Bash: `./setup.sh`
- Windows PowerShell: `.\setup.ps1`

Both scripts check Git, Node/npm, Python 3.11+, Docker, and Docker Compose. Docker is optional for viewing the Hub shell, but required for provider install/run flows.

If an NVIDIA key is entered, setup updates only `NVIDIA_API_KEY` in `.env.local` and preserves other local variables. The setup scripts must not write secrets into tracked files.

## Runtime

Start backend and frontend:

```bash
./.venv/bin/python -m uvicorn app.main:app --reload --app-dir backend
cd frontend && npm run dev
```

For LAN testing, bind the frontend to all interfaces and set the host allowed by Next.js dev resources:

```bash
cd frontend
AIHUB_LAN_HOST=<LAN-IP> npm run dev -- --hostname 0.0.0.0 --port 3000
```

## Nginx Gateway

After backend `8000` and frontend `3000` are running:

```bash
docker compose -f docker-compose.nginx.yml up -d
```

Default entrypoints:

- Local: `http://localhost:8080`
- LAN: `http://<LAN-IP>:8080`

The gateway proxies:

- `/api/` to the FastAPI backend
- `/_next/*` and app routes to the Next.js frontend
- `/_next/webpack-hmr` with a dedicated dev HMR route

## Verification

Recommended checks before push:

```bash
bash -n setup.sh
docker compose -f docker-compose.nginx.yml config -q
docker exec ai-hub-nginx nginx -t
npm run typecheck --prefix frontend
npm test --prefix frontend
./.venv/bin/python -m pytest backend/tests
./.venv/bin/python backend/scripts/validate_providers.py
npm audit --prefix frontend --audit-level=moderate
```

## Notes

- Evidence screenshots now live under `tests/`.
- Runtime output under `providers/*/runtime/`, `providers/*/logs/`, and `deploy/` remains ignored.
- The current Linux validation host is ARM/aarch64; the setup logic is architecture-neutral for Linux AMD64.

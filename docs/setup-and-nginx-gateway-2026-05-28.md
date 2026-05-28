# Setup and Nginx Gateway - 2026-05-28

## Purpose

This note records the current supported local setup path for AI Hub after the setup, LAN access, and Docker-managed Nginx gateway hardening.

## Setup Scripts

Use the platform-native setup script:

- Linux/macOS/Git Bash: `./setup.sh`
- Windows PowerShell: `.\setup.ps1`

Both scripts check Git, Node/npm, Python 3.11+, Docker, and Docker Compose. `setup.sh` also starts the Linux/macOS/Git Bash Hub runtime on ports `6900-6902`. Docker is optional for viewing the Hub shell, but required for the gateway and provider install/run flows.

If an NVIDIA key is entered, setup updates only `NVIDIA_API_KEY` in `.env.local` and preserves other local variables. The setup scripts must not write secrets into tracked files.

## Runtime

Manual backend and frontend commands:

```bash
./.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 6902 --reload --reload-dir backend --app-dir backend
cd frontend && API_PROXY_PORT=6902 npm run dev -- --hostname 0.0.0.0 --port 6901
```

For LAN testing, bind the frontend to all interfaces and set the host allowed by Next.js dev resources:

```bash
cd frontend
AIHUB_LAN_HOST=<LAN-IP> API_PROXY_PORT=6902 npm run dev -- --hostname 0.0.0.0 --port 6901
```

## Nginx Gateway

After backend `6902` and frontend `6901` are running:

```bash
docker compose -f docker-compose.nginx.yml up -d
```

Default entrypoints:

- Local: `http://localhost:6900`
- LAN: `http://<LAN-IP>:6900`

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

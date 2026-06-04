# Setup and Nginx Gateway - 2026-05-28

## Purpose

This note records the current supported local setup path for AI Hub after the setup, LAN access, and Docker-managed Nginx gateway hardening.

## Setup Scripts

Use the root Bash scripts:

- Start/setup: `./setup.sh`
- Stop: `./stop.sh`

The root PowerShell setup entrypoint has been removed. `setup.sh` checks Git, Node/npm, Python 3.11+, curl, Docker, Docker Compose, the Nginx image, and ports `6900-6902`, then starts the Hub runtime and reports ports, URLs, logs, and health states after boot. If a port is already busy, setup asks whether to reuse, kill, or abort. `stop.sh` asks before stopping PID-file processes, Docker gateway services, and matching port listeners. Docker is optional for viewing the Hub shell, but required for the gateway and provider install/run flows.

If an NVIDIA key is entered, setup updates only `NVIDIA_API_KEY` in `.env.local` and preserves other local variables. The setup scripts must not write secrets into tracked files.

## Runtime

`setup.sh` starts backend and frontend as background processes and writes PID/log files under `logs/hub/`:

```bash
tail -f logs/hub/backend.log
tail -f logs/hub/frontend.log
```

Use `./stop.sh` for a clean shutdown. Use `./stop.sh --providers` when provider containers/scripts should be stopped too.

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

The Nginx template resolves `host.docker.internal` through Docker DNS at request time with IPv6 disabled. This avoids Docker Desktop choosing an unreachable IPv6 upstream for the Windows host while keeping the default upstream values unchanged.

## Verification

Recommended checks before push:

```bash
bash -n setup.sh
bash -n stop.sh
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

# Setup and Nginx Gateway - 2026-05-28

## Purpose

This note records the current supported local setup path for AI Hub after the setup, LAN access, and Docker-managed Nginx gateway hardening.

## Setup Scripts

Use the root Bash scripts:

- Start/setup: `./setup.sh`
- Stop: `./stop.sh`

The root PowerShell setup entrypoint has been removed. `setup.sh` checks Git, Node/npm, Python 3.11+, curl, Docker, Docker Compose, the Nginx image, and ports `6900-6902`, then starts the Hub runtime and reports ports, URLs, logs, and health states after boot. If a port is already busy, setup asks whether to reuse, kill, or abort. `stop.sh` asks before stopping systemd user units, PID-file processes, Docker gateway services, and matching port listeners. Docker is optional for viewing the Hub shell, but required for the gateway and provider install/run flows.

On Debian/Ubuntu fresh machines, `setup.sh --yes` attempts to install missing host packages with apt, including Git, curl, Python venv support, Docker Engine, and Docker Compose v2. It also starts the Docker daemon when systemd is available and can add the current user to the `docker` group for future no-sudo access. The current shell may still need `newgrp docker` or a new login session before plain `docker` works.

On Windows Git Bash, setup can try `winget` for missing Git/Python/Node/Docker Desktop components when available, but Docker Desktop must still be started by the user after installation. On macOS, setup can use Homebrew for command-line dependencies when `brew` is installed, while Docker Desktop remains the expected runtime for gateway/provider containers. Linux AMD64 and ARM64/aarch64 are supported by the local scripts and by the default Nginx image.

If an NVIDIA key is entered, setup updates only `NVIDIA_API_KEY` in `.env.local` and preserves other local variables. The setup scripts must not write secrets into tracked files.

## Runtime

`setup.sh` starts backend and frontend as user-managed detached processes and writes PID/log files under `logs/hub/`. On Linux with user systemd, it uses `systemd-run --user` so services survive the setup shell exiting; otherwise it falls back to `nohup`.

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

The Nginx template resolves dynamic upstreams through Docker DNS with IPv6 disabled. On Linux setup passes the host Docker bridge gateway IP as the upstream because variable-based `proxy_pass` does not read `/etc/hosts` entries from `extra_hosts`; on Windows/macOS it keeps the `host.docker.internal` fallback expected by Docker Desktop.

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
- The setup logic is intended for Linux AMD64 and ARM64/aarch64. Other CPU architectures are reported as untested during setup.

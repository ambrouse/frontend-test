# Setup Port 6900 Evidence - 2026-05-28

## Scope

Validated that `setup.sh` now starts AI Hub and exposes the web app through the `6900-6902` Hub ports.

## Result

- Backend health: `curl http://127.0.0.1:6902/api/health` returned `{"ok":true}`.
- Frontend direct: `curl -I http://127.0.0.1:6901` returned HTTP 200.
- Local gateway: `curl -I http://127.0.0.1:6900` returned HTTP 200.
- LAN gateway: `curl -I http://192.168.2.182:6900` returned HTTP 200.
- Listeners confirmed:
  - `0.0.0.0:6902` backend
  - `0.0.0.0:6901` frontend
  - `0.0.0.0:6900` nginx gateway

## Notes

- Runtime logs are in `logs/hub/`.
- No secrets or request payloads were captured.

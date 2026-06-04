# Frontend Light Mode And Bash Setup Release Log - 2026-06-04

## Scope

- Restore the navbar button animation to a thinner crescent style.
- Restore banner motion in light mode so it follows the dark-mode water reveal instead of becoming static.
- Audit light-mode button colors across navbar, Hub filters, banners, cards, and settings.
- Remove the root PowerShell setup entrypoint and keep `setup.sh` / `stop.sh` as the supported runtime scripts.
- Verify setup, stop, UI screenshots, GIF evidence, docs, README, and CI references before push.

## Implementation Notes

- `frontend/src/styles/globals.css` received the final visual correction block for thin navbar crescents and light-mode banner water motion.
- `setup.sh` now checks prerequisites, validates ports, prompts for reuse/kill/abort on busy ports, checks Docker and the Nginx image, starts backend/frontend/gateway, and prints a runtime report.
- `stop.sh` now prompts before stopping the gateway, PID-file services, matching port listeners, and optionally provider containers/scripts.
- `setup.ps1` was removed from the root setup flow.
- CI script syntax checks now cover `setup.sh` and `stop.sh`; root `setup.ps1` is no longer referenced.

## Evidence

- Visual screenshots and GIF are under `tests/current-frontend-fix-2026-06-04/`.
- Demo GIF: `tests/current-frontend-fix-2026-06-04/ai-hub-demo-2026-06-04.gif`.
- Git Bash syntax checks passed for `setup.sh` and `stop.sh`.
- `stop.sh --yes` stopped the existing backend, frontend, and gateway services.
- `setup.sh --yes` started backend, frontend, and Docker Nginx gateway successfully.
- Runtime checks passed for backend health, frontend HTTP 200, Docker gateway health, and provider API data through the gateway.
- Frontend typecheck passed with `npm run typecheck`.
- Frontend production build passed with `npm run build`.
- Backend tests passed with `24 passed`.
- Docker compose config and live `nginx -t` passed.
- `nginx:1.27-alpine` is present locally.

## Follow-Up Watchpoints

- Keep root setup docs Bash-only and do not reintroduce `setup.ps1`.

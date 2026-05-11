# 2026-05-11 - Warehouse provider startup and Hub log layout

## Summary
- Fixed Hub terminal log layout so provider logs wrap instead of overlapping.
- Fixed Multi-Agent-Intelligent-Warehouse login failures caused by missing database schema/default users.
- Fixed duplicated `/api/v1/api/v1` auth verification calls in the Warehouse UI.
- Pushed provider-source fixes to `baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia`.

## Changes
- `frontend/src/styles/globals.css`
  - Changed terminal log feed to a stable block scroller.
  - Added per-line padding, wrapping, and responsive gaps for multiline log messages.
- `providers/multi-agent-intelligent-warehouse/scripts/windows/run.ps1`
  - Runs Docker build/start, applies idempotent SQL migrations, seeds default users, clears Redis rate-limit cache, and smoke-tests admin login.
- `providers/multi-agent-intelligent-warehouse/scripts/linux/run.sh`
  - Uses upstream `scripts/run_all_services.sh` so Linux startup includes migration/seed/smoke checks.
- `providers/multi-agent-intelligent-warehouse/.env.example`
  - Added `DEFAULT_ADMIN_PASSWORD` and `DEFAULT_USER_PASSWORD`.
- Upstream provider commits:
  - `e6f68ec fix(setup): make warehouse startup idempotent`
  - `4729d72 fix(setup): keep startup smoke checks reliable`

## Verification
- `powershell -ExecutionPolicy Bypass -File providers/multi-agent-intelligent-warehouse/scripts/windows/run.ps1` passed.
- Backend direct auth passed: `POST http://localhost:8091/api/v1/auth/login`, `GET /api/v1/auth/me`.
- Frontend proxy auth passed: `POST http://localhost:3001/api/v1/auth/login`, `GET /api/v1/auth/me`.
- Hub frontend typecheck passed: `npm run typecheck`.
- Warehouse frontend typecheck passed inside `wosa-frontend`: `npm run type-check`.
- Upstream `main` verified at `4729d726076fe3ed716383440ca2ced3a03c1323`.

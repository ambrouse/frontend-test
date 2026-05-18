# Real Provider Config And AIQ Lifecycle Log - 2026-05-13

## Timeline
- Investigated hanging Hub lifecycle tests and found `_run_script` waited on stdout EOF while AIQ child processes kept inherited handles open.
- Reworked backend script execution to write command output to a provider log file and poll the direct lifecycle process.
- Found PowerShell `Set-Content -Encoding utf8` status/metrics JSON used a BOM; updated backend and registry JSON loading to `utf-8-sig`.
- Validated AIQ health and metrics with bounded test commands: backend `18080`, frontend `13080`, benchmark `2 agents`.
- Started Docker Desktop daemon and validated the three Docker-backed providers with real Hub install/run/metrics/stop/delete loops.
- Cleaned all deploy folders and verified no provider containers or deploy processes were left running.

## Validation Commands
- `..\.venv\Scripts\python -m pytest`
- `..\.venv\Scripts\python -m ruff check .`
- `npm test`
- `npm run build`
- `npm run typecheck`
- `.\.venv\Scripts\python backend\scripts\check_no_secrets.py`
- `.\.venv\Scripts\python backend\scripts\validate_providers.py`

## Notes
- Lifecycle test harnesses used explicit timeouts per action to prevent another stuck terminal session.
- Provider pipeline scripts keep their normal runtime behavior; the timeout discipline was applied to the validation harness and backend command runner only.
- Follow-up AIQ fix pushed upstream: `PhuongHo03/aiq.git` `develop` commit `8973979`.
- Retest after push: clean Hub clone install passed; run completed in 326 seconds with metrics `2 agents`; stop/delete cleanup passed.
- Follow-up frontend localhost issue: found gateway was listening on `192.168.2.22:13080` because `server.js` used `process.env.HOSTNAME` as bind host.
- Pushed upstream AIQ fix `580610a`, restarted through provider scripts, and verified `0.0.0.0:13080` listen state plus `http://localhost:13080` 200/title `AI-Q`.
- Final bounded checks after restart: backend `/health` 200, async agents 200 with 2 agents, health script `ok`, metrics `2 agents`.
- Quick config follow-up: replaced read-only config display with editable fields and a save action; config saves to ignored runtime local JSON.
- Added env field defaults for the four real providers and wired backend to inject saved env into setup/run/health/metrics scripts.
- Made `installDirectory` effective through `AIHUB_INSTALL_DIRECTORY`; provider scripts now use it for deploy path resolution.
- Validation: backend pytest 16 passed, ruff passed, frontend vitest 8 passed, frontend typecheck passed, provider manifests passed, and runtime/log/deploy leftovers were cleaned after smoke tests.
- Hydration follow-up: moved Hub cache and selected-provider cache reads out of initial render and into client effects.
- Validation after hydration fix: frontend vitest 8 passed, frontend typecheck passed, and Next production build passed.
- Provider key flow follow-up: removed action-level `nvidiaApiKey` and deleted `.env.local` key fallback from the four real provider wrappers.
- Validation after key-flow cleanup: full backend pytest 16 passed, ruff passed, provider manifests passed, frontend vitest 8 passed, and frontend typecheck passed.

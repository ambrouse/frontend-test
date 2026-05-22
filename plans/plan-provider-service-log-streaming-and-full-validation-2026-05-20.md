# Plan: Provider Service Log Streaming and Full Provider Validation

Date: 2026-05-20

Updated: 2026-05-22

Status: closed

## Goal

Test the real lifecycle for the in-scope active Hub providers and add a clean provider service-log streaming experience to the Hub frontend. The current Hub can show lifecycle/install logs from the provider wrapper path, but it does not yet expose live logs for each running service inside every provider stack. The implementation must handle provider differences without hard-coding fragile frontend behavior, provide a safe clear-logs mechanism, and redesign the log UI so it stays compact, readable, responsive, and useful.

No acceptance gate in this plan can be satisfied by dry-run validation alone. The provider validation phase must use fresh Hub install/run flows, real status/health/metrics checks, and real service/runtime log inspection.

## Context Audit Summary

Read/reviewed:

- Root `README.md`: Hub lifecycle, active provider catalog, verification commands, deploy/source rules.
- `docs/backend-api.md`: existing provider endpoints include `/api/providers/{id}/logs`, status, metrics, config, lifecycle tasks.
- `docs/provider-plan.md`: provider contract expects `runtime/status.json`, `runtime/metrics.json`, `logs/runtime.log` newline JSON, and backend tailing `/logs?tail=200`.
- `docs/real-provider-stability-and-log-ui-2026-05-12.md` and matching plan: prior work split Progress vs Detailed logs and validated three providers.
- `docs/tasks/seven-provider-cleanup-and-fresh-clone-2026-05-18.md`: project was intended to focus on seven active providers.
- `backend/app/services/provider_runtime.py`: backend currently tails one provider runtime log file and appends wrapper script output; it does not collect per-service Docker/process logs.
- `backend/app/services/provider_seed.py`: current seed list includes `web-agent`; this task keeps `web-agent` in the scoped validation matrix because another agent is adding it.
- `frontend/src/components/hub/ProjectDetailView.tsx`: UI already has progress/details tabs but no service-level log source selector or clear provider-service logs action.
- Fresh provider source clones were created outside the main workspace in `C:\code\provider-log-audit` for investigation only.

Important scope update:

- The Hub active catalog may still contain eight providers, but this validation pass explicitly excludes `nemotron-voice-agent-provider` and `pdf-to-podcast`.
- The in-scope validation matrix is six providers: `agentic-commerce-blueprint`, `ai-virtual-assistant-provider`, `aiq`, `shop-retail-provider`, `multi-agent-intelligent-warehouse`, and `web-agent`.
- `web-agent` is being added by another agent and must remain in the log-streaming/test plan. Because another agent is actively adding it, implementation must avoid overwriting unrelated `web-agent` changes and should re-read its files before editing.
- If any fix is made in a cloned provider source repository, that provider repo must be committed and pushed before the Hub fresh-install validation is repeated. Fresh install must clone the pushed provider source, not rely on local-only source changes.
- Current status as of 2026-05-21: `aiq` passed the real Hub install/run/status/metrics/service-log/UI validation under the user's updated "use existing keys only" scope. Web-search/paper-search paths that require missing `TAVILY_API_KEY`/`SERPER_API_KEY` were recorded as skipped/limited, not blockers.

## Provider Source Investigation

Provider source clones were placed outside this repo in `C:\code\provider-log-audit` to avoid touching the active multi-agent workspace.

### Provider matrix for this task

1. `agentic-commerce-blueprint`
   - Source: `https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-`
   - Runtime: Docker Compose.
   - Compose files observed: `docker-compose.yml`, `docker-compose.infra.yml`, `docker-compose-nim.yml`.
   - Services include nginx, UI, merchant, psp, apps-sdk, NAT agents, and infra services.
   - Log strategy: Docker Compose service logs by compose file/project; important filter by service.

2. `ai-virtual-assistant-provider`
   - Source: `https://github.com/mionm/ai-virtual-assistant-provider.git`
   - Runtime: Docker Compose under `deploy/compose/docker-compose.yaml`.
   - Services include redis, minio, api-service, agent-service, pdf-service, tts-service, jaeger, pdf-api, celery-worker.
   - Log strategy: Docker Compose service logs, grouped by service; likely many noisy infra logs.

3. `aiq`
   - Source: `https://github.com/PhuongHo03/aiq.git`
   - Runtime in source has Docker Compose under `deploy/compose/docker-compose.yaml`; previous plan noted branch `develop` and runtime wrapper specifics must be rechecked.
   - Services include aiq-agent, frontend, postgres.
   - Log strategy: Docker Compose logs when compose mode is used; if wrapper starts local Python/Node processes, also capture process stdout files.
   - Validation status: passed on 2026-05-21 under the accepted existing-key scope.

4. `nemotron-voice-agent-provider`
   - Source: `https://github.com/mionm/nemotron-voice-agent-provider.git`
   - Runtime: Docker Compose.
   - Compose files observed: `docker-compose.yml`, `docker-compose.jetson.yml` plus examples.
   - Services include tts-service, asr-service, nvidia-llm, python-app, ui-app.
   - Log strategy: Docker Compose logs with large NIM startup logs; UI needs service filter, severity search, and bounded tail.
   - Validation status: out of scope for this pass. Do not fresh install/run/test unless scope changes.

5. `shop-retail-provider`
   - Source: `https://github.com/mionm/Shop-Retail-Provider-mion-.git`
   - Runtime: Docker Compose.
   - Compose files observed: `docker-compose.yaml`, `docker-compose-nim-local.yaml`.
   - Services include chain-server, catalog-retriever, memory-retriever, rails, frontend, etcd, minio, milvus, nginx.
   - Log strategy: Docker Compose logs; prioritize app services by default and allow infra services on demand.

6. `multi-agent-intelligent-warehouse`
   - Source: `https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia`
   - Runtime: Docker Compose under `deploy/compose/`.
   - Compose files observed: `docker-compose.dev.yaml`, `docker-compose.gpu.yaml`, `docker-compose.monitoring.yaml`, `docker-compose.versioned.yaml`, `docker-compose.yaml`, `docker-compose.ci.yml`, `docker-compose.rapids.yml`.
   - Services include backend, frontend, nginx, TimescaleDB, Redis, Kafka, etcd, MinIO, Milvus, optional NIM services.
   - Log strategy: Compose logs with compose-file/profile awareness; service selector is mandatory to avoid unreadable logs.

7. `pdf-to-podcast`
   - Source: `https://github.com/PhuongHo03/pdf-to-podcast.git`
   - Runtime: Docker Compose plus Gradio/API process behavior from prior validation.
   - Compose file observed: `docker-compose.yaml`.
   - Log strategy: combine Docker Compose logs and any wrapper-managed Gradio/API stdout logs if the provider starts host processes.
   - Validation status: out of scope for this pass. Do not fresh install/run/test unless scope changes.

8. `web-agent`
   - Source: `https://github.com/baolnq-ai/web-agent.git`
   - Runtime: local FastAPI + Next.js dev servers, Docker helpers disabled by default.
   - Hub wrapper runs provider `run.ps1`/`run.sh`, checks backend `8011` and frontend `3005` by default.
   - Logs are process files under deploy `logs/`, not Docker Compose logs by default.
   - Log strategy: process/file log streaming for backend and frontend stdout/stderr, with optional Docker helper logs only if a future mode enables them.
   - Coordination note: this provider is being added by another agent; re-read its files before editing and avoid broad rewrites.

## Provider-Specific Deep Plan

### 1. `agentic-commerce-blueprint`

Files read:

- Hub manifest: `providers/agentic-commerce-blueprint/aihub.provider.json`.
- Hub wrappers: `scripts/windows/setup.ps1`, `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Source compose: `docker-compose.yml`, `docker-compose.infra.yml`, `docker-compose-nim.yml` in `C:\code\provider-log-audit\agentic-commerce-blueprint`.

Runtime facts:

- Windows/Linux run with `docker compose -f docker-compose.infra.yml -f docker-compose.yml`.
- Run builds `promotion-agent`, starts the full stack, waits for gateway `http://127.0.0.1:{port}/api/health`, then runs `milvus-seeder` under profile `seed`.
- Default Hub port is `8088` via `HTTP_HOST_PORT`.
- Important app services from source: `nginx`, `ui`, `merchant`, `psp`, `apps-sdk`, `promotion-agent`, `post-purchase-agent`, plus other NAT agents.
- Infra/noisy services are in infra compose, including Milvus/MinIO/Phoenix-style dependencies.

Provider-specific log plan:

- Add service log mode: `docker_compose`.
- Compose files: `docker-compose.infra.yml`, `docker-compose.yml`.
- Default visible services: `nginx`, `merchant`, `psp`, `apps-sdk`, `promotion-agent`, `post-purchase-agent`, `ui`.
- Secondary/infra services: Milvus, MinIO, Phoenix and seed services; hidden by default but selectable.
- Log adapter must include both compose files in the same order as wrapper run.
- Clear behavior: Docker `clear view` only; lifecycle log file can be truncated separately.
- Validation action: install/run, confirm gateway health, confirm service logs for `nginx` and one agent service, then make a real commerce/agent request if API key is available.

Risks:

- First NAT agent call can be slow; UI must not mark missing logs as failure while service is still warming.
- Seeder failures are currently warnings; plan should show seeder logs but not block the running log view if stack is healthy.

### 2. `ai-virtual-assistant-provider`

Files read:

- Hub manifest: `providers/ai-virtual-assistant-provider/aihub.provider.json`.
- Hub wrappers: `scripts/windows/setup.ps1`, `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Shared Linux dispatcher: `providers/_shared/linux-provider-dispatch.sh`.
- Source compose: `deploy/compose/docker-compose.yaml` in `C:\code\provider-log-audit\ai-virtual-assistant-provider`.

Runtime facts:

- Windows wrapper writes `.runtime/docker-compose.aihub.yaml` and `.runtime/docker-compose.cpu.yaml` overlays.
- Windows run uses args: `--env-file .env -f deploy/compose/docker-compose.yaml -f .runtime/docker-compose.aihub.yaml`, plus `.runtime/docker-compose.cpu.yaml` when `USE_CPU_MILVUS` is not `false`.
- Linux wrapper delegates to shared dispatcher; dispatcher currently calls `bash ./start.sh` for run and uses compose cleanup only during cleanup.
- Default Hub UI port is `13001`; API gateway default is `9000`.
- Source services include `redis`, `minio`, `api-service`, `agent-service`, `pdf-service`, `tts-service`, `jaeger`, `pdf-api`, `celery-worker`, and likely additional gateway/UI services depending source scripts.

Provider-specific log plan:

- Add service log mode: `docker_compose` for Windows path, with Linux discovery fallback if `start.sh` creates `.runtime/ports.env` or compose wrappers.
- Compose files: `deploy/compose/docker-compose.yaml`, `.runtime/docker-compose.aihub.yaml`, optional `.runtime/docker-compose.cpu.yaml`.
- Default visible services: `api-gateway-server` if present, `agent-chain-server`, `api-service`, `agent-service`, `agent-frontend`/UI service if present.
- Secondary services: `redis`, `minio`, `postgres`, `milvus`, `jaeger`, `pdf-service`, `tts-service`, `pdf-api`, `celery-worker`.
- Source listing endpoint should mark unavailable services cleanly if a compose override excludes them.
- Clear behavior: Docker `clear view`; lifecycle logs truncatable.
- Validation action: UI `13001`, API/agent health `9000`, service logs from API gateway/agent, one real assistant request if secrets/resources allow.

Risks:

- Provider is marked deprecated upstream; failures can be source drift, not Hub-only bugs.
- Linux path may rely on provider `start.sh`; implementation should inspect actual generated runtime metadata after install before finalizing source list.

### 3. `aiq`

Files read:

- Hub manifest: `providers/aiq/aihub.provider.json`.
- Hub wrappers: `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Source compose: `deploy/compose/docker-compose.yaml` in `C:\code\provider-log-audit\aiq`.

Runtime facts:

- Branch is `develop`.
- Manifest notes Hub applies lifecycle patch because direct upstream push may be blocked.
- Windows/Linux run call provider source `setup.sh --up`, then read `.runtime/ports.env`.
- Health checks use backend `http://127.0.0.1:{BACKEND_PORT}/health`, async agents endpoint, and frontend port.
- Source compose exists with services `aiq-agent`, `frontend`, `postgres`, but current Hub default notes local Python/Node with SQLite/Dask and optional Docker support disabled.
- Runtime may produce process logs under deploy `.runtime` or source-specific log files rather than Docker logs.

Provider-specific log plan:

- Add service log mode: `hybrid`, but prioritize `process_files` for current Hub default.
- File sources to discover/whitelist after install: `.runtime/*.log`, backend stdout/stderr logs if created by patched setup, frontend logs if created by patched setup, and Hub wrapper `providers/aiq/logs/*-script-output.log`.
- Compose services `aiq-agent`, `frontend`, `postgres` should be listed only when Docker compose mode is detected or enabled.
- Default visible sources: backend/API log, frontend log, setup/runtime log.
- Clear behavior: file logs can be truncated if whitelisted; Docker logs are `clear view` only.
- Validation action: run `setup.sh --up` through Hub, confirm `.runtime/ports.env`, backend health, async agents endpoint, frontend, then verify backend/frontend log sources update.

Risks:

- AIQ differs most from other providers; forcing compose-only log streaming would be wrong.
- Upstream push may be blocked; if source log fixes are required, document blocker and keep Hub patch deterministic.

### 4. `nemotron-voice-agent-provider` (out of validation scope)

Scope note:

- Retain these source notes as background only. Do not run fresh install/run validation for this provider in the current pass.

Files read:

- Hub manifest: `providers/nemotron-voice-agent-provider/aihub.provider.json`.
- Hub wrappers: `scripts/windows/setup.ps1`, `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Shared Linux dispatcher: `providers/_shared/linux-provider-dispatch.sh`.
- Source compose: `docker-compose.yml`, `docker-compose.jetson.yml` in `C:\code\provider-log-audit\nemotron-voice-agent-provider`.

Runtime facts:

- Hub default hosted mode writes `.aihub-hosted.compose.yml` and starts only `python-app` and `ui-app` with `--no-deps`.
- Default UI port is `9000`; pipeline docs/health is `7860` or `NEMOTRON_PIPELINE_PORT`.
- Source compose also defines heavy local NIM services: `tts-service`, `asr-service`, `nvidia-llm`.
- Local NIM services have very long startup logs and should not be default-visible in hosted mode.

Provider-specific log plan:

- Add service log mode: `docker_compose`.
- Compose files: `docker-compose.yml`, `.aihub-hosted.compose.yml` for default hosted mode.
- Default visible services: `python-app`, `ui-app`.
- Optional/local-NIM services: `tts-service`, `asr-service`, `nvidia-llm`; show only when local NIM mode/profile is active or user expands advanced services.
- Clear behavior: Docker `clear view`; lifecycle logs truncatable.
- Validation action: run hosted mode, confirm `python-app` logs, `ui-app` logs, pipeline docs endpoint, UI endpoint.

Risks:

- NIM logs may contain long model download/engine output; UI must handle high-volume lines and long startup without layout breakage.
- `--no-deps` means compose source list must not assume dependent services are running.

### 5. `shop-retail-provider`

Files read:

- Hub manifest: `providers/shop-retail-provider/aihub.provider.json`.
- Hub wrappers: `scripts/windows/setup.ps1`, `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Shared Linux dispatcher: `providers/_shared/linux-provider-dispatch.sh`.
- Source compose: `docker-compose.yaml`, `docker-compose-nim-local.yaml` in `C:\code\provider-log-audit\shop-retail-provider`.

Runtime facts:

- Hub setup patches source compose by removing hard-coded `container_name` and source `name` to avoid collisions.
- Hub setup writes `.env` with `COMPOSE_PROJECT_NAME=aihub-shop-retail-provider`.
- Run uses `docker compose --env-file .env -f docker-compose.yaml up -d --build`.
- Default gateway is `13000`; chain server health/metrics around `18109`.
- Services include `chain-server`, `catalog-retriever`, `memory-retriever`, `rails`, `frontend`, `nginx`, `etcd`, `minio`, `milvus`.

Provider-specific log plan:

- Add service log mode: `docker_compose`.
- Compose file: `docker-compose.yaml`.
- Compose project name: `aihub-shop-retail-provider`.
- Default visible services: `nginx`, `chain-server`, `frontend`, `catalog-retriever`, `memory-retriever`, `rails`.
- Infra services hidden by default: `etcd`, `minio`, `milvus`.
- Optional local NIM compose `docker-compose-nim-local.yaml` only included when local NIM mode is implemented/enabled.
- Clear behavior: Docker `clear view`; lifecycle logs truncatable.
- Validation action: gateway `/api/health`, chain server health, logs from `nginx` and `chain-server`, one retail assistant request if API key exists.

Risks:

- Source compose is patched at install time; log metadata must match post-patch runtime, not raw upstream assumptions.
- Hard-coded source names may reappear after upstream change; validation should catch project-name mismatch.

### 6. `multi-agent-intelligent-warehouse`

Files read:

- Hub manifest: `providers/multi-agent-intelligent-warehouse/aihub.provider.json`.
- Hub wrappers: `scripts/windows/setup.ps1`, `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Source compose: `deploy/compose/docker-compose.dev.yaml` and related compose files in `C:\code\provider-log-audit\multi-agent-intelligent-warehouse`.

Runtime facts:

- Windows run uses `docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml up -d --build --wait --wait-timeout 600`.
- Linux run calls source `scripts/run_all_services.sh` after patching env ports.
- Windows wrapper then applies DB migrations, seeds default users, flushes Redis, checks backend health, and performs login smoke check.
- Default frontend port is `13002`, backend is `8091`.
- Source services include app services `backend`, `frontend`, `nginx` plus infra `timescaledb`, `redis`, `kafka`, `etcd`, `minio`, `milvus`, optional `llm-nim`.

Provider-specific log plan:

- Add service log mode: `docker_compose` for Windows/dev compose; Linux should either use same compose metadata or read source runtime metadata from `run_all_services.sh`.
- Compose file: `deploy/compose/docker-compose.dev.yaml` for Hub default.
- Default visible services: `backend`, `frontend`, `nginx`.
- Secondary services: `timescaledb`, `redis`, `kafka`, `etcd`, `minio`, `milvus`.
- Optional model service: `llm-nim` only if local NIM profile is active.
- Add a special validation source for migration/login smoke output through lifecycle logs, not service logs.
- Clear behavior: Docker `clear view`; lifecycle logs truncatable.
- Validation action: backend `/api/v1/health`, frontend, admin login smoke, logs from `backend` and `frontend`, delete/cleanup.

Risks:

- `run_all_services.sh` Linux path may not match Windows compose invocation exactly; source listing should be runtime-aware per OS.
- Infra logs are very noisy; default UI must not open all services at once.

### 7. `pdf-to-podcast` (out of validation scope)

Scope note:

- Retain these source notes as background only. Do not run fresh install/run validation for this provider in the current pass.

Files read:

- Hub manifest: `providers/pdf-to-podcast/aihub.provider.json`.
- Hub wrappers: `scripts/windows/setup.ps1`, `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Source compose: `docker-compose.yaml` and source docs/scripts in `C:\code\provider-log-audit\pdf-to-podcast`.

Runtime facts:

- Windows run invokes Git Bash `setup.sh --up` and captures wrapper output in provider logs: `setup-up.out.log` and `setup-up.err.log`.
- Linux run calls `FRONTEND_PORT={port} API_SERVICE_PORT={port} bash setup.sh --up`.
- Source creates `.auto-ports.env` and `.auto-ports.compose.yaml`.
- Frontend is a local Gradio host process with `frontend/.frontend.pid` and source docs indicate `frontend/output.log`.
- Docker compose services include API/data/model services such as redis, minio, api-service, agent-service, pdf-service, tts-service, jaeger, pdf-api, celery-worker.
- Default frontend is `7860`; API health is `8002` by default.

Provider-specific log plan:

- Add service log mode: `hybrid`.
- Compose files: `docker-compose.yaml`, optional generated `.auto-ports.compose.yaml` when present.
- File log sources: `frontend/output.log`, `providers/pdf-to-podcast/logs/setup-up.out.log`, `providers/pdf-to-podcast/logs/setup-up.err.log`; include additional source runtime logs only after install discovery.
- Default visible sources: Gradio frontend file log, `api-service`, `agent-service`, `pdf-service`, `tts-service`.
- Secondary services: `redis`, `minio`, `jaeger`, `pdf-api`, `celery-worker`.
- Clear behavior: file logs can be truncated if whitelisted; Docker logs are `clear view` only.
- Validation action: API `/health`, Gradio UI, service logs for API and frontend file log, minimal PDF-to-podcast action only if NVIDIA and ElevenLabs keys are present.

Risks:

- Ports are auto-selected; log metadata must read `.auto-ports.env`/generated compose overlay after run.
- Frontend is not purely Docker, so compose-only implementation would miss the user-visible Gradio log.

### 8. `web-agent`

Files read:

- Hub manifest: `providers/web-agent/aihub.provider.json`.
- Hub wrappers: `scripts/windows/setup.ps1`, `scripts/windows/run.ps1`, `scripts/linux/run.sh`.
- Source process scripts: `run.ps1`, `run.sh` in `C:\code\provider-log-audit\web-agent`.

Runtime facts:

- This provider is actively being added by another agent, so implementation must re-read files before editing and preserve unrelated work.
- Default mode is local dev, not Docker Compose.
- Hub setup clones `https://github.com/baolnq-ai/web-agent.git`, requires Python 3.12+, installs deps, and disables auto-start helpers: `POSTGRES_AUTO_START=false`, `PGADMIN_AUTO_START=false`, `SEARXNG_AUTO_START=false`.
- Hub run sets `BACKEND_PORT=8011`, `FRONTEND_PORT=3005`, `AUTO_START_APPS=false`, then invokes source `run.ps1` or `run.sh`.
- Windows source `run.ps1` starts backend with `.venv\Scripts\python.exe -m uvicorn src.main:app --reload` and frontend with `npm run dev`, writing:
  - `logs/backend.dev.out.log`
  - `logs/backend.dev.err.log`
  - `logs/frontend.dev.out.log`
  - `logs/frontend.dev.err.log`
  - `logs/backend.pid`
  - `logs/frontend.pid`
- Linux source `run.sh` starts backend/frontend with `nohup` and writes:
  - `logs/backend.dev.log`
  - `logs/frontend.dev.log`
  - `logs/backend.pid`
  - `logs/frontend.pid`
- Health checks are backend `http://127.0.0.1:8011/api/v1/health` and frontend `http://127.0.0.1:3005` by default.

Provider-specific log plan:

- Add service log mode: `process_files`.
- File sources, Windows:
  - backend stdout: `deploy/web-agent/logs/backend.dev.out.log`
  - backend stderr: `deploy/web-agent/logs/backend.dev.err.log`
  - frontend stdout: `deploy/web-agent/logs/frontend.dev.out.log`
  - frontend stderr: `deploy/web-agent/logs/frontend.dev.err.log`
- File sources, Linux:
  - backend: `deploy/web-agent/logs/backend.dev.log`
  - frontend: `deploy/web-agent/logs/frontend.dev.log`
- Default visible sources: backend stdout/log, frontend stdout/log.
- Error sources should be visually grouped but not auto-expanded unless non-empty.
- Optional helper logs for PostgreSQL/pgAdmin/SearXNG should not be included until a runtime mode enables those helpers.
- Clear behavior: truncate whitelisted process log files only; do not delete PID files from the clear-log UI.
- Validation action: install/run, confirm backend health, frontend health, backend log updates, frontend log updates, SSE/chat search smoke if Tavily/LLM config is available.

Risks:

- `web-agent` is actively changing under another agent; stale plan assumptions must be verified immediately before implementation.
- Backend/frontend dev servers can restart and rewrite logs; cursor handling must tolerate truncation/rotation.
- Stop/clear must not kill unrelated processes on the same ports beyond provider-owned PID tracking.

## Required Skills

- `plan-skill`: this planning file and phase discipline.
- `backend-skill`: provider runtime API, task queue, log collection, clear-log endpoint, safe filesystem/process handling.
- `frontend-skill`: provider detail log UX, responsive layout, state/error/loading behavior.
- `frontend-design-skills`: compact, clean, accessible log UI that avoids layout breakage.
- `testing-skill`: unit/integration/manual lifecycle gates and negative tests.
- `documentation-skill`: update task docs only after implementation/validation.
- `logging-skill`: record execution logs under `logs/tasks/` without secrets.
- `security-skill`: prevent log path traversal, command injection, secret leakage, and unsafe clear/delete behavior.
- `push-code-skill`: after pass, push Hub repo and provider repo changes separately when source changes are needed.

## Proposed Architecture

### Backend

1. Keep existing provider `logs/runtime.log` as normalized Hub lifecycle log.
2. Add a provider service-log contract in provider manifest or local runtime metadata:
   - `runtime.serviceLogs.mode`: `docker_compose`, `process_files`, or `hybrid`.
   - `runtime.serviceLogs.composeFiles`: provider-source-relative compose files.
   - `runtime.serviceLogs.composeProjectName`: optional explicit project name used by wrappers.
   - `runtime.serviceLogs.services`: service IDs with labels, category (`app`, `infra`, `model`, `ui`), default visibility, and noisy/slow-start hints.
   - `runtime.serviceLogs.files`: optional provider-root/deploy-root relative stdout files for non-compose services.
3. Add backend service-log APIs:
   - `GET /api/providers/{id}/service-logs?service=...&tail=...&cursor=...&level=...&query=...`
   - `GET /api/providers/{id}/service-logs/sources`
   - `DELETE /api/providers/{id}/service-logs?scope=runtime|service|all&service=...`
4. Implement log adapters:
   - Docker Compose adapter: resolves allowed compose files and runs `docker compose ... logs --no-color --timestamps --tail N [service]` with fixed argv, never shell string interpolation.
   - File adapter: tails whitelisted files only under provider root or deploy install directory.
   - Normalizer: converts raw lines to a common shape with `time`, `level`, `source`, `service`, `message`, `cursor`, `stream`.
5. Keep request latency bounded:
   - Default tail 200, max tail 1000.
   - Timeout compose log calls quickly.
   - Cache source list/status briefly, not log payloads.
   - For high-frequency streaming, prefer frontend polling first; only add SSE/WebSocket if polling proves insufficient.
6. Clear logs safely:
   - Hub lifecycle clear truncates/rotates `providers/{id}/logs/runtime.log` and script output files.
   - Docker service clear cannot truly truncate Docker daemon json logs safely per container without Docker internals; implement `clear view` cursor reset/bookmark for Docker logs first.
   - If a provider writes service log files, truncate only whitelisted provider-owned files.
   - UI label must be honest: `Clear view` for Docker logs, `Clear file logs` only where truncation is real.

### Frontend

1. Redesign provider detail logs into a compact observability card:
   - Top summary row: provider state, health, current task, last update.
   - Tabs: `Progress`, `Service logs`, `Runtime files` if available.
   - Service chips/dropdown grouped by App, UI, Model, Infra.
   - Controls: level filter, search, tail size, auto-refresh toggle, pause/resume, copy/export visible logs, clear view/logs.
2. Avoid layout breakage:
   - Fixed-height log viewport with internal scroll.
   - Monospace line wrapping toggle; default wrap off on desktop, wrap on small screens.
   - Sticky toolbar within card, not page-wide.
   - Responsive two-column detail layout collapses to one column before logs overflow.
3. UX defaults:
   - Default to `Progress` while install/run tasks are active.
   - Default `Service logs` to app-facing services, not noisy infra.
   - Show clear empty states: not installed, installed but not running, Docker unavailable, service not found.
4. Accessibility:
   - Buttons have text labels/aria labels.
   - Log viewport has `aria-live="polite"` only for concise progress, not full noisy logs.
   - Keyboard-accessible filters and tabs.

## Implementation Phases

### Phase 0: Preflight and registry consistency

Estimated time: 30-60 minutes.

Steps:

1. Read required skills: `backend-skill`, `frontend-skill`, `testing-skill`, `security-skill`.
2. Check git status and identify files already changed by other agents.
3. Confirm the scoped validation list is six providers including `web-agent`, with `nemotron-voice-agent-provider` and `pdf-to-podcast` explicitly marked skipped/out of scope.
4. Re-read `web-agent` current files before any implementation because another agent is actively adding it.
5. Update README/docs/validation expectations to the current scoped matrix where needed, without overwriting unrelated `web-agent` work.
6. Confirm Docker and Compose availability without starting providers.
7. Confirm secrets are present only by key name/presence, never value.

Testing gate:

- Scoped provider matrix is explicit, including skipped providers and reasons.
- No unrelated agent changes are overwritten.
- Docker/Compose availability known.

### Phase 1: Provider log-source contract

Estimated time: 2-4 hours.

Steps:

1. Add typed schema for service log sources to backend models.
2. Extend manifests for each in-scope provider with service log metadata. Keep any existing metadata for out-of-scope providers only if already implemented, but do not make them validation blockers.
3. Keep metadata minimal and source-derived: compose files, service IDs, labels, categories, default services.
4. Add validation rules so bad service IDs, paths outside deploy/provider root, or missing compose files are caught.
5. Add tests for manifest validation and source listing.

Testing gate:

- Provider manifest validation passes.
- Backend tests cover service source parsing and path safety.

### Phase 2: Backend service-log API

Estimated time: 4-8 hours.

Steps:

1. Implement source listing endpoint.
2. Implement service log endpoint with Docker Compose and file adapters.
3. Normalize logs into a stable response shape compatible with existing `ProjectLog` where possible.
4. Add clear-view/clear-file logic with honest scopes.
5. Add security tests:
   - invalid provider ID.
   - invalid service ID.
   - path traversal in file log source.
   - unsupported clear scope.
   - Docker unavailable returns clean API error, not traceback.
6. Add latency tests with mocked adapters so hot provider APIs remain fast.

Testing gate:

- Backend unit tests pass.
- Existing `/api/providers/{id}/logs` behavior remains backward compatible.
- No shell command construction from user-provided strings.

### Phase 3: Provider wrapper alignment

Estimated time: 3-8 hours.

Steps:

1. For each in-scope provider, inspect current Hub wrapper run/setup scripts and source compose commands.
2. Ensure wrappers use stable compose file paths/project names that the log adapter can reproduce.
3. If a provider starts host processes, ensure stdout/stderr are redirected to whitelisted files under provider/deploy logs.
4. If changes belong in provider source, commit and push provider source before fresh Hub install testing. Fresh validation must use the pushed provider source from a new Hub install.
5. Update Hub manifests/wrappers only where Hub owns the behavior.

Testing gate:

- Script syntax checks pass for Windows and Linux wrappers.
- Dry-run/source-level validation confirms log source metadata matches actual runtime commands.

### Phase 4: Frontend log UI redesign

Estimated time: 4-8 hours.

Steps:

1. Add API client methods/types for service log sources, service logs, and clear-log actions.
2. Refactor `ProjectDetailView` logs card into smaller components if needed, without broad unrelated UI changes.
3. Add service selector, level/search filters, pause/auto-refresh, copy/export, and clear view/logs controls.
4. Update CSS to keep the log panel contained and responsive.
5. Add tests for:
   - progress tab remains default during lifecycle task.
   - service logs tab lists grouped services.
   - filter/search works.
   - clear view calls correct API and does not clear lifecycle task history.
   - empty/error states render cleanly.

Testing gate:

- Frontend typecheck passes.
- Frontend tests pass.
- Manual browser check confirms layout does not break on desktop and narrow viewport.

### Phase 5: Real provider validation

Estimated time: 1-3 hours per provider, longer if builds/model pulls are slow.

For each in-scope provider:

1. Delete old deploy/runtime state through Hub.
2. Install fresh through Hub so source is cloned from provider repo. If provider source was fixed, verify the provider repo was pushed before this step.
3. Run provider through Hub, no `dryRun`.
4. Verify status/metrics/log endpoints.
5. Open the Hub detail page and verify:
   - progress logs show lifecycle steps.
   - service logs show at least one real service stream.
   - service selector works.
   - pause/resume works.
   - clear view/logs works according to the provider capability.
6. Run a real provider-specific smoke action where feasible:
   - Agentic Commerce: gateway/storefront and one commerce/agent request.
   - AI Virtual Assistant: UI/API health and one assistant request.
   - AIQ: UI/API health and one AIQ backend request. Current blocker must be resolved or explicitly waived before completion.
   - Shop Retail: gateway and one retail agent request.
   - Warehouse: UI/API health, login/default flow if available.
   - Web Agent: backend/frontend health, backend/frontend process logs, and one search/chat smoke if Tavily/LLM config is available.
7. Stop and delete provider through Hub.
8. Confirm no provider-owned resources/log files are incorrectly left in tracked paths.
9. Record `nemotron-voice-agent-provider` and `pdf-to-podcast` as skipped/out of scope, not failed and not validated.

Testing gate per provider:

- Install/run/status/logs/metrics/stop/delete pass or blocker is documented with exact failing service.
- UI service logs display real runtime output.
- No secrets appear in logs/screenshots/docs.
- `aiq` blocker status is recorded with the exact failing step and cannot be treated as complete unless resolved or waived.

### Phase 6: Full verification

Estimated time: 1-2 hours plus build time.

Commands to run after implementation:

```powershell
.\.venv\Scripts\python -m ruff check backend
.\.venv\Scripts\python -m ruff format --check backend
.\.venv\Scripts\python -m mypy backend\app
.\.venv\Scripts\python -m pytest backend
.\.venv\Scripts\python backend\scripts\validate_providers.py
.\.venv\Scripts\python backend\scripts\provider_dry_run_lifecycle.py
.\.venv\Scripts\python backend\scripts\benchmark_latency.py --threshold-ms 100
.\.venv\Scripts\python backend\scripts\check_no_secrets.py
npm.cmd run typecheck --prefix frontend
npm.cmd run test --prefix frontend
npm.cmd run build --prefix frontend
```

Script syntax checks:

```powershell
Get-ChildItem providers -Recurse -Filter *.ps1 | ForEach-Object {
  $tokens = $null
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
  if ($errors) { throw $errors }
}
```

```bash
bash -lc "bash -n setup.sh && find providers -path '*/scripts/linux/*.sh' -print0 | xargs -0 -n1 bash -n"
```

Testing gate:

- All required checks pass.
- Browser manual verification completed for the new log UI.
- Provider validation matrix recorded, including skipped providers and the `aiq` blocker status.

### Phase 7: Documentation, task log, push workflow

Estimated time: 45-90 minutes.

Steps:

1. Read `documentation-skill`, `logging-skill`, and `push-code-skill` before writing docs/logs/pushing.
2. Write task documentation under `docs/` only for user-facing/operational changes.
3. Write task log under `logs/tasks/` with:
   - provider list validated.
   - providers skipped by scope: `nemotron-voice-agent-provider`, `pdf-to-podcast`.
   - `aiq` blocker status, exact failing step, and whether it was resolved or explicitly waived.
   - commit hashes of provider repos if changed.
   - commands/checks run.
   - blockers or skipped real actions with reason.
4. Ensure no provider clone, deploy artifact, service log, `.env`, or secret is staged.
5. Commit Hub repo changes.
6. Push provider source repos first if any provider source changed, then Hub repo. Do not claim fresh-install validation for a provider source fix until Hub has reinstalled from the pushed provider repo.
7. If requested, perform clean-clone verification after push.

Testing gate:

- Docs/logs are concise and secret-free.
- Git status reviewed before commit.
- Push follows `push-code-skill`.

## Acceptance Criteria

- Scoped provider validation list is consistent across docs/logs: six in scope, with `nemotron-voice-agent-provider` and `pdf-to-podcast` explicitly skipped/out of scope.
- Hub exposes service-log sources for in-scope providers.
- Hub can show live service logs for running in-scope provider services, not only install/wrapper logs.
- Logs are filterable by service and level, searchable, pausable, copyable/exportable, and bounded by tail/cursor.
- Clear mechanism exists and is honest about provider capability: clear view for Docker logs, clear/truncate only for whitelisted files.
- Frontend layout remains clean on desktop and mobile widths.
- Backend/frontend verification gates pass, and in-scope provider validation gates pass except unresolved blockers that are documented with exact failing steps.
- Real provider lifecycle testing is recorded for every in-scope provider, except unresolved blockers that are explicitly documented.
- `aiq` is either validated successfully or remains a documented blocker; the plan is not 100% complete while `aiq` is blocked unless the user changes scope.
- Provider source fixes, if any, are pushed to provider repos before fresh Hub install validation.

## Validation Update - 2026-05-22

- Status: complete for the updated six-provider scope.
- Real frontend validation completed for: `agentic-commerce-blueprint`, `ai-virtual-assistant-provider`, `aiq`, `shop-retail-provider`, `multi-agent-intelligent-warehouse`, and `web-agent`.
- Explicitly skipped by user scope: `nemotron-voice-agent-provider`, `pdf-to-podcast`.
- Evidence root: `test/provider-functional-evidence-2026-05-21/`.
- Evidence is split per provider into `app/`, `function/`, `lifecycle/`, and `logs/`; stale/no-output screenshots were removed.
- AIQ blocker status: resolved for current scope by retesting the frontend file-upload flow first, then asking the file-grounded question and capturing the answer output.
- Source provider fixes pushed before fresh reinstall:
  - `shop-retail-provider`: `8a4ab1e fix catalog retrieval fallback for image search`.
  - `multi-agent-intelligent-warehouse`: `4d45dac fix: use relative forecasting API URL 2026-05-21`, `ae588eb fix: include Pillow in Docker requirements 2026-05-22`, and `9558b93 fix: keep document pipeline running on judge fallback 2026-05-22`.
  - `web-agent`: `a908165 fix: preserve frontend env newlines on Windows setup 2026-05-22`.
  - `aiq`: `7418832 fix: harden Windows setup shell portability 2026-05-22` and `9bfbbdc fix: add PowerShell port probe for Windows setup 2026-05-22`.
- Fresh Hub reinstall/run was repeated after each pushed provider fix before collecting pass evidence.
- Existing-key limitations:
  - `aiq`: `TAVILY_API_KEY` and `SERPER_API_KEY` were not present, so web/paper search paths remain outside this accepted existing-key validation; file-grounded frontend flow passed.
  - `web-agent`: no Tavily key was present, so Tavily-specific rotation was not tested; real frontend search passed through SearXNG fallback plus LLM summary, with sources visible.
  - `agentic-commerce-blueprint`: checkout/provider functions visible on frontend were exercised under available local/default credentials.
- Final in-scope frontend functions exercised:
  - Agentic Commerce: catalog, product selection, quantity changes, coupon, checkout continuation, metrics, client modes, merchant UCP/ACP, Hub logs/status.
  - AI Virtual Assistant: customer selector, suggested/custom chat answers, manual data download, end chat, Hub logs/status.
  - AIQ: sources page, file upload, uploaded file availability, file-grounded question, grounded answer, Hub logs/status.
  - Shop Retail: category browsing, chat product search, product care, add/view cart, cart total, image upload/search, Hub logs/status.
  - Warehouse: login/dashboard, equipment table/details, forecasting dashboard after fix, operations, safety incident report, document upload, MCP tool search, analytics, chat answer, Hub logs/status.
  - Web Agent: search chat with sources, session history, Tavily key manager fallback state, Ops Dashboard LLM health, Hub logs/status.
- Secret scan was run after evidence cleanup; generated runtime/log copies of the NVIDIA key were redacted while leaving `.env.local` available for future local testing.

## Post-Push Pipeline Validation - 2026-05-22

- Status: complete after the requested clean deploy reset, Hub push, and fresh frontend validation loop.
- Pre-run cleanup: stopped provider-owned runtime containers/processes and removed stale provider deploy clones before retesting.
- Hub push-before-test checkpoint: `710e2fd feat: add provider service log validation evidence 2026-05-22`.
- Additional Hub fix/push loop for Warehouse wrapper/env handling: latest pushed commit `bdef5c5 fix: pass warehouse env values into compose 2026-05-22`.
- Post-push evidence root: `test/provider-post-push-pipeline-evidence-2026-05-22/`.
- In-scope providers retested through real Hub lifecycle and frontend:
  - `agentic-commerce-blueprint`: catalog, native commerce UI state, Apps SDK search results, Hub running status, service logs.
  - `ai-virtual-assistant-provider`: customer data, customer selector, delivery-status chat answer, Hub running status, service logs.
  - `aiq`: data-source UI, README upload, composer attachment, file-grounded chat answer with README citation, Hub running status, service logs.
  - `shop-retail-provider`: storefront/chat ready state and retail product search answer, Hub running status, service logs.
  - `multi-agent-intelligent-warehouse`: login/dashboard, forklift maintenance chat output after Hub fix, Hub running status, service logs.
  - `web-agent`: frontend search chat output with visible sources through SearXNG fallback, Hub running status, service logs.
- Explicitly skipped by user scope: `nemotron-voice-agent-provider`, `pdf-to-podcast`.
- Provider source repos changed during this post-push run: none. The failing Warehouse path was fixed in Hub wrapper/env handling, pushed to Hub, then freshly retested.
- Evidence cleanup: kept only `.png` screenshots and `.md` reports; removed debug, duplicate, prompt-only, no-output, raw `.txt`, raw `.json`, and raw log evidence.
- Remaining key limitations under the accepted existing-key scope:
  - `aiq`: Tavily/Serper paths not validated because those keys were not present; file-grounded frontend flow passed.
  - `web-agent`: Tavily-specific path not validated; SearXNG fallback plus LLM summary with visible sources passed.

## Risks and Mitigations

- Docker Compose logs can be slow or huge.
  - Mitigation: strict tail limits, timeout, service filter, default app services only.
- Docker logs cannot be safely truncated through Compose.
  - Mitigation: implement clear-view cursor/bookmark and label it accurately.
- Providers have inconsistent compose file paths and profiles.
  - Mitigation: manifest-level log metadata populated from source investigation.
- Secrets may appear in raw provider logs.
  - Mitigation: redact known secret env values in backend normalization and avoid copying raw logs into docs.
- Multi-agent workspace has many uncommitted changes.
  - Mitigation: inspect git status before edits and avoid unrelated files; provider source investigation stays in `C:\code\provider-log-audit`.
- `web-agent` is actively being added by another agent.
  - Mitigation: keep `web-agent` in the scoped validation list, re-read `web-agent` before edits, and avoid broad rewrites or unrelated conflict resolution.

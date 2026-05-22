# Provider Source Hub Readiness Checklist

Date: 2026-05-20

This document is a source-provider readiness checklist. It defines how a provider source repository should be structured, configured, tested, logged, and cleaned so that adding it to AI Hub does not break install/run/delete. It is not the implementation plan for adding live service-log streaming to the Hub UI; that work stays in `plans/plan-provider-service-log-streaming-and-full-validation-2026-05-20.md`.

A provider source is ready only when Hub can fresh-clone it, configure it from safe env/config, run the real runtime, expose useful runtime logs, execute the real user workflow, stop/restart it, and delete provider-owned artifacts without breaking Hub or other providers.

Current Hub target providers used as examples/check targets:

1. `agentic-commerce-blueprint`
2. `ai-virtual-assistant-provider`
3. `aiq`
4. `nemotron-voice-agent-provider`
5. `shop-retail-provider`
6. `multi-agent-intelligent-warehouse`
7. `pdf-to-podcast`
8. `web-agent`

## 1. Readiness definition

A provider is ready for Hub only when all are true:

- Hub install clones the expected source repo and branch into `deploy/{provider}` or the configured install directory.
- No manual patch is needed after Hub install.
- Runtime ports are configurable and do not collide with Hub or other providers.
- Run reports `running` only after the provider is actually usable.
- Health/readiness endpoints pass.
- The main real workflow passes, not just `/health` or a static UI.
- Logs are available for lifecycle and runtime services/processes.
- Stop is safe and repeatable.
- Delete is idempotent and removes provider-owned containers, volumes, networks, images, PID files, and generated runtime files where applicable.
- Secrets are never committed, printed, copied into docs, or exposed in logs.
- If provider source needs a fix, the fix is pushed to the provider repo before Hub fresh-install validation.

## 2. Provider source repository baseline

Every provider source repository should include:

- `README.md`
  - Required tools and versions.
  - Real setup/run/stop/delete commands.
  - Required keys/config for real mode.
  - Main feature smoke test, not only health checks.
- `.gitignore`
  - Ignore `.env`, `.env.local`, logs, runtime files, PIDs, build outputs, caches, Docker volumes, generated data.
  - Do not ignore required templates or source config.
- `.env.example`
  - Safe placeholders only.
  - Every supported env key documented.
  - Mandatory real-mode keys clearly marked.
- Runtime scripts when source owns lifecycle:
  - Linux: `setup.sh`, `run.sh`, `stop.sh`, `delete.sh` or documented equivalents.
  - Windows: `setup.ps1`, `run.ps1`, `stop.ps1`, `delete.ps1` when Windows is supported.
- Dependency files:
  - Python: `pyproject.toml`, `requirements.txt`, `uv.lock`, or equivalent.
  - Node: `package.json` and lockfile.
- Docker files when Docker is used:
  - Compose files in documented paths.
  - Relative build contexts.
  - No machine-specific absolute paths.
- Log output locations:
  - Runtime logs in `logs/` or documented process log files.
  - PID files in provider-owned runtime/log dirs only.
- A repeatable real workflow test:
  - API curl/script, UI flow, or smoke command proving the advertised feature works.

## 3. Hub wrapper baseline

Each Hub provider folder must contain:

- `providers/{provider_id}/aihub.provider.json`
  - `id` matches folder name.
  - `repoUrl`, branch, install directory, default port, health URL, metrics URL are accurate.
  - Requirements and runtime modes are honest.
  - Required tools are listed.
  - Runtime log/status/metrics files are defined.
- Windows scripts if Windows is supported:
  - `setup.ps1`
  - `run.ps1`
  - `stop.ps1`
  - `delete.ps1`
  - `health.ps1`
  - `collect-metrics.ps1`
- Linux scripts if Linux is supported:
  - `setup.sh`
  - `run.sh`
  - `stop.sh`
  - `delete.sh`
  - `health.sh`
  - `collect-metrics.sh`
- Wrapper scripts must pass Hub env correctly:
  - `AIHUB_PROVIDER_ID`
  - `AIHUB_PROVIDER_ROOT`
  - `AIHUB_DEPLOY_ROOT`
  - `AIHUB_INSTALL_DIRECTORY`
  - `AIHUB_PORT`
  - `AIHUB_BRANCH`
  - provider-specific env keys.
- Wrapper scripts must not hardcode local absolute paths.
- Wrapper scripts must not print secrets.
- Wrapper scripts must not kill unrelated Hub/backend/frontend/provider processes.

## 4. Secret and configuration rules

Mandatory rules:

- Never commit real secrets to Hub or provider source.
- Never print `.env`, `.env.local`, API keys, cookies, tokens, credentials, or private endpoints.
- Validation logs may record only:
  - key present/missing.
  - masked value.
  - value length.
  - pass/fail.
- `.env.example` must be safe to publish.
- Real mode must fail clearly if required keys are missing.
- Provider must not silently switch to mock/fallback mode when real mode is required.
- Demo/fallback modes must be explicit, named, and disabled for readiness validation unless the provider is explicitly demo-only.
- Backend log normalization should redact known secret values before exposing logs to frontend.

## 5. Port, process, and workspace isolation

Provider must not conflict with Hub or other providers.

Required:

- Every host port is configurable by env.
- Hub wrapper can override all user-facing and backend ports.
- No fixed `container_name` unless provider-prefixed and justified.
- No fixed global Docker network names unless provider-prefixed.
- Compose project name is unique per provider when Compose is used.
- PID files live inside provider-owned deploy/runtime/log directory.
- Stop/delete uses PID files or provider-owned compose project, not broad process matching.
- Startup must not kill unrelated processes on common ports unless ownership is proven.
- Provider works from paths containing spaces.
- Provider can be installed/run/deleted while Hub frontend/backend remain running.

Never use:

- Global `docker system prune`.
- Global `docker image prune -a`.
- Broad `Stop-Process`/`kill` by name such as all `node`, all `python`, all `uvicorn`.
- Broad deletion outside the provider deploy directory.

## 6. Docker Compose standards

For Compose-based providers:

- Compose files must work from a fresh clone.
- Build contexts must be relative.
- Host ports use env variables, for example `${API_PORT:-8000}:8000`.
- Provider-specific or compose-managed volume names.
- Provider-specific or compose-managed network names.
- Health checks for services that take time to start.
- Readiness waits for dependencies before Hub marks provider running.
- `docker compose config` should pass with expected env.
- Delete must use provider-specific compose args matching run args.
- Provider-owned images must be removable by delete.

Cleanup command for provider-owned Compose stacks:

```bash
docker compose ... down --volumes --remove-orphans --rmi all
```

Do not rely on only:

```bash
docker compose down
```

Do not use only `--remove-orphans` or `--rmi local` when provider-built images can remain.

## 7. Runtime log and service-log standards

Hub must show more than install logs. Each provider needs a clear runtime log strategy.

### Required log categories

- Lifecycle logs:
  - Hub wrapper setup/run/stop/delete output.
  - Stored under `providers/{id}/logs/` or Hub task state.
- Runtime service logs:
  - Docker Compose service logs, or
  - process stdout/stderr files, or
  - hybrid of both.
- Status/metrics:
  - `runtime/status.json`
  - `runtime/metrics.json` when supported.

### Supported service-log modes

- `docker_compose`
  - Provider runs services through Docker Compose.
  - Hub knows compose files, optional compose project, and service names.
- `process_files`
  - Provider runs local processes and writes stdout/stderr to files.
  - Hub tails whitelisted files only.
- `hybrid`
  - Provider has both Compose services and local host processes.

### Log API behavior expected from Hub

- Source listing endpoint should return available service/file sources.
- Log endpoint should support provider, source/service, tail limit, cursor, level, and search query.
- Default tail should be bounded.
- Log reads should time out quickly and never block hot provider APIs.
- Invalid provider/service/source must return clean errors.
- User-controlled paths are never accepted directly; sources must come from manifest/runtime whitelist.
- Docker logs are not truncated directly; UI should provide `Clear view` for Docker logs.
- File logs can be truncated only if they are whitelisted provider-owned log files.
- Clear logs must not delete PID files.

### UI log expectations

- Separate Progress/Lifecycle logs from Service logs.
- Service logs grouped by category: App, UI, Agent/Model, Infra, Files.
- Default to app-facing services, not noisy infra.
- Provide pause/resume, level filter, search, tail size, copy/export visible logs.
- Fixed-height scrollable log viewport to avoid layout breakage.
- Clear states for not installed, installed but stopped, Docker unavailable, log file not created yet.

## 8. Install validation

Before install:

- Delete old provider deploy folder through Hub or safe local cleanup.
- Confirm no old provider containers/images/volumes remain when testing cleanup.
- Confirm required keys are present without printing values.
- Confirm target ports are available or configure alternatives.

Install pass criteria:

- Hub clones expected `repoUrl`.
- Hub checks out expected branch.
- Fresh clone commit equals expected provider commit.
- Dependencies install without interactive prompts.
- Safe env files are generated from templates.
- No manual edits are required after clone.
- Install works on Windows path with spaces.
- Hub frontend/backend stay running.

## 9. Run validation

Run pass criteria:

- Provider starts from Hub-installed fresh source, not a manually patched deploy copy.
- Required containers/processes become ready.
- Health endpoint passes.
- UI/docs endpoint loads if provided.
- Hub status shows accurate state, port, current step, and health.
- Metrics endpoint/file works or returns an honest unsupported/minimal state.
- Runtime logs show no fatal startup errors.
- Runtime logs show no secrets.
- Service-log sources are visible in Hub.
- Provider can stop and run again.
- Provider can delete, reinstall, and run again.

## 10. Real functionality validation

Health checks are not enough.

A provider is not ready if it only:

- Starts containers.
- Returns `/health` OK.
- Shows a static UI.
- Returns a canned fallback response.
- Uses mock/demo data when real mode is required.
- Skips external API calls needed for advertised behavior.

Real validation must prove:

- Main user workflow succeeds.
- Required API keys are passed into the actual runtime process/container.
- Response depends on the request/data.
- Logs do not show hidden exceptions masked by a fallback.
- UI can call provider backend successfully.

Validation evidence should record:

- Endpoint/UI flow tested.
- Status code or visible result.
- Short non-secret response preview.
- Fallback detected: yes/no.
- Runtime services checked.
- Logs reviewed.
- Secrets not printed.

## 11. Provider-specific readiness checks

### `agentic-commerce-blueprint`

Runtime shape:

- Docker Compose, default port `8088`.
- Hub run uses `docker-compose.infra.yml` + `docker-compose.yml`.
- Important services: `nginx`, `ui`, `merchant`, `psp`, `apps-sdk`, `promotion-agent`, `post-purchase-agent`, other NAT agents.

Required tests:

- Fresh Hub install from `https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-`.
- Run through Hub with NVIDIA/API env present when real agent path requires it.
- Verify gateway `http://127.0.0.1:8088/api/health` or configured port.
- Verify service logs for gateway/API and at least one agent service.
- Execute a real commerce flow/query.
- Confirm response is not static/fallback.
- Delete through Hub and verify Compose containers, networks, volumes, and provider-built images are removed.

Special notes:

- Seeder warnings should be visible but should not hide the main stack status.
- First agent calls can be slow; readiness timeouts must be realistic.

### `ai-virtual-assistant-provider`

Runtime shape:

- Docker Compose under `deploy/compose/docker-compose.yaml` plus Hub runtime overlays.
- Default UI port `13001`, API gateway/agent health around `9000`.
- Provider is deprecated upstream, so drift must be documented clearly.

Required tests:

- Fresh Hub install from `https://github.com/mionm/ai-virtual-assistant-provider.git`.
- Run through Hub with generated `.runtime/docker-compose.aihub.yaml` and CPU Milvus override when used.
- Verify UI and `/agent/health`.
- Verify service logs for API gateway/agent services.
- Send a real assistant/customer-service request using seeded data if available.
- Reject hidden fallback responses.
- Delete through Hub and verify cleanup.

Special notes:

- Linux may go through provider `start.sh`; source listing must match actual runtime after install.
- SQL/user IDs must be safely parameterized; do not accept fallback caused by hidden database query errors.

### `aiq`

Runtime shape:

- Branch `develop`.
- Hub run calls source `setup.sh --up` and reads `.runtime/ports.env`.
- Current Hub default can behave as local Python/Node/process runtime rather than pure Compose.

Required tests:

- Fresh Hub install from `https://github.com/PhuongHo03/aiq.git` branch `develop`.
- Run through Hub.
- Verify `.runtime/ports.env` contains backend/frontend ports.
- Verify backend `/health`, async agents endpoint, and frontend.
- Verify process/file logs for backend and frontend, or Compose logs if compose mode is active.
- Submit a real AIQ query/workflow.
- Reject placeholder/static UI pass.
- Stop/delete and reinstall.

Special notes:

- Do not force compose-only log assumptions.
- If provider source push is blocked, document blocker and keep Hub patch deterministic.

### `nemotron-voice-agent-provider`

Runtime shape:

- Docker Compose.
- Hub hosted mode starts `python-app` and `ui-app` with `.aihub-hosted.compose.yml`.
- Default UI port `9000`, pipeline/docs around `7860`.
- Local NIM services exist but are not default in hosted mode.

Required tests:

- Fresh Hub install from `https://github.com/mionm/nemotron-voice-agent-provider.git`.
- Run hosted mode through Hub.
- Verify pipeline docs/health and UI.
- Verify service logs for `python-app` and `ui-app`.
- If WebSocket mode: test health and a real websocket/voice path if practical.
- If WebRTC mode: test `/offer` or scripted SDP flow if practical.
- Do not mark pass from container health alone.
- Delete and verify cleanup.

Special notes:

- `tts-service`, `asr-service`, `nvidia-llm` logs are optional/local NIM mode and should be hidden by default.
- NIM startup logs can be huge; UI must keep log panel bounded.

### `shop-retail-provider`

Runtime shape:

- Docker Compose.
- Hub setup sets `COMPOSE_PROJECT_NAME=aihub-shop-retail-provider`.
- Default gateway port `13000`, chain server around `18109`.
- Main services: `nginx`, `chain-server`, `frontend`, `catalog-retriever`, `memory-retriever`, `rails`, with infra `etcd`, `minio`, `milvus`.

Required tests:

- Fresh Hub install from `https://github.com/mionm/Shop-Retail-Provider-mion-.git`.
- Run through Hub.
- Verify `http://127.0.0.1:13000/api/health` or configured port.
- Verify logs for `nginx` and `chain-server`.
- Execute a real retail/shopping assistant request.
- Confirm NVIDIA/API-backed response is not fallback.
- Delete and verify provider Compose resources and images are removed.

Special notes:

- Source compose may be patched at install time to remove fixed names; validation must match post-patch runtime.

### `multi-agent-intelligent-warehouse`

Runtime shape:

- Docker Compose under `deploy/compose/docker-compose.dev.yaml` for Hub default.
- Default frontend port `13002`, backend `8091`.
- Windows wrapper applies migrations and login smoke after compose up.
- Main services: `backend`, `frontend`, `nginx`; infra: `timescaledb`, `redis`, `kafka`, `etcd`, `minio`, `milvus`.

Required tests:

- Fresh Hub install from `https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia`.
- Run through Hub.
- Verify backend `/api/v1/health` and frontend.
- Verify migration/default-user/login smoke result.
- Verify logs for `backend` and `frontend`.
- Execute a real warehouse workflow: inventory, routing, document/RAG, or planning.
- Reject static dashboard-only pass.
- Delete and verify cleanup.

Special notes:

- Linux `run_all_services.sh` may differ from Windows compose invocation; verify actual runtime sources per OS.

### `pdf-to-podcast`

Runtime shape:

- Hybrid: Docker Compose services plus local Gradio frontend process.
- Default frontend `7860`, API health `8002`.
- Source creates `.auto-ports.env` and `.auto-ports.compose.yaml`.
- Important file logs include `frontend/output.log` and Hub wrapper `setup-up.out.log`/`setup-up.err.log` on Windows.

Required tests:

- Fresh Hub install from `https://github.com/PhuongHo03/pdf-to-podcast.git`.
- Run through Hub.
- Verify API `/health` and Gradio frontend.
- Verify logs from API service and Gradio frontend file log.
- Upload/provide a real PDF and generate podcast output when NVIDIA/ElevenLabs keys are present.
- Confirm output audio/transcript is created and non-empty.
- Confirm no placeholder/fallback generation.
- Delete and verify containers/images/volumes/generated runtime files are cleaned.

Special notes:

- Do not implement compose-only log streaming; that misses the visible Gradio frontend.
- Port map must be read after run because ports can be auto-selected.

### `web-agent`

Runtime shape:

- Local FastAPI + Next.js dev servers, Docker helpers disabled by default.
- Default backend port `8011`, frontend port `3005`.
- Hub run calls provider `run.ps1`/`run.sh`.
- Process logs live under `deploy/web-agent/logs/`.

Required tests:

- Fresh Hub install from `https://github.com/baolnq-ai/web-agent.git`.
- Run through Hub.
- Verify backend `http://127.0.0.1:8011/api/v1/health` or configured port.
- Verify frontend `http://127.0.0.1:3005` or configured port.
- Verify backend and frontend process logs stream in Hub.
- Run a search/chat smoke test if Tavily/LLM config is available.
- Stop/delete and confirm provider-owned processes/logs/runtime files are cleaned safely.

Expected log files:

- Windows:
  - `logs/backend.dev.out.log`
  - `logs/backend.dev.err.log`
  - `logs/frontend.dev.out.log`
  - `logs/frontend.dev.err.log`
- Linux:
  - `logs/backend.dev.log`
  - `logs/frontend.dev.log`

Special notes:

- This provider is actively being added by another agent. Re-read current files before editing and avoid broad rewrites.
- Clear logs may truncate whitelisted log files only; never delete PID files from the log UI.

## 12. Provider source fix and push rule

If the problem is inside provider source:

1. Clone or use a clean source clone outside the Hub workspace when possible.
2. Fix provider source in that repo.
3. Run source syntax/config tests.
4. Run real provider functionality tests.
5. Commit provider source.
6. Push provider source.
7. Delete Hub deploy copy.
8. Install again through Hub from fresh clone.
9. Verify fresh clone commit equals pushed commit.
10. Run real functionality from the Hub-installed copy.
11. Only then mark provider pass.

Do not mark pass from a manually patched `deploy/` folder unless the same fix has been pushed and fresh-installed through Hub.

## 13. Hub wrapper fix rule

If the issue is only in Hub wrappers/manifests:

- Fix `providers/{provider_id}` in Hub.
- Run provider manifest validation.
- Run backend provider registry/lifecycle tests.
- Fresh install through Hub.
- Run real functionality.
- Verify service logs.
- Stop/delete through Hub.
- Verify cleanup.
- Commit Hub changes separately from provider source changes.

## 14. Required automated checks

Run relevant checks before accepting a provider.

General:

- `git diff --check`
- Hub repo status reviewed.
- Provider source repo status reviewed when source changed.
- No `.env`, `.env.local`, generated logs, runtime folders, build output, or secret files staged.

Hub backend:

```powershell
.\.venv\Scripts\python -m ruff check backend
.\.venv\Scripts\python -m ruff format --check backend
.\.venv\Scripts\python -m mypy backend\app
.\.venv\Scripts\python -m pytest backend
.\.venv\Scripts\python backend\scripts\validate_providers.py
.\.venv\Scripts\python backend\scripts\provider_dry_run_lifecycle.py
.\.venv\Scripts\python backend\scripts\check_no_secrets.py
```

Hub frontend:

```powershell
npm.cmd run typecheck --prefix frontend
npm.cmd run test --prefix frontend
npm.cmd run build --prefix frontend
```

PowerShell script syntax:

```powershell
Get-ChildItem providers -Recurse -Filter *.ps1 | ForEach-Object {
  $tokens = $null
  $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
  if ($errors) { throw $errors }
}
```

Bash script syntax:

```bash
bash -lc "bash -n setup.sh && find providers -path '*/scripts/linux/*.sh' -print0 | xargs -0 -n1 bash -n"
```

Provider source checks when applicable:

- Python compile/tests/lint if configured.
- Node typecheck/test/build if configured.
- `docker compose config` for compose stacks.
- Source-specific smoke tests.

## 15. Manual UI validation

For providers with UI:

- Open UI URL reported by Hub status.
- Verify page loads without console/runtime crash.
- Execute main user workflow through UI when practical.
- Confirm UI talks to correct backend port.
- Confirm no CORS/proxy errors.
- Confirm Hub provider detail stays responsive during install/run/log streaming.
- Confirm service-log panel does not break layout on desktop and narrow viewport.
- Refresh Hub page and confirm status/logs remain accurate.

## 16. Logs to inspect

Inspect only non-secret logs.

Required:

- Hub task output.
- Provider lifecycle log.
- Main API service/process log.
- Main UI service/process log.
- Agent/model worker logs when provider has agents/models.
- Database/migration logs when data setup is required.
- Error stderr logs for process-file providers.

Look for:

- Tracebacks.
- `ERROR`, `FATAL`, `Unhandled`, `Exception`.
- Hidden fallback paths.
- Missing env/config.
- Port bind failures.
- Docker name/network conflicts.
- External API failures.
- Timeout/readiness loops.
- Secret values.

Do not copy raw logs with secrets into docs, commits, PRs, or issues.

## 17. Conflict prevention checklist

Before adding a new provider:

- Provider ID is unique.
- Deploy folder is unique.
- Default ports do not collide with Hub or existing providers.
- Compose project name is unique if Compose is used.
- No fixed unprefixed `container_name`.
- No fixed unprefixed network/volume names.
- No global process kill.
- No global Docker prune.
- No broad file deletion outside deploy/provider dirs.
- Provider can run after another provider was installed/deleted.
- Provider delete does not remove another provider's resources.
- Provider source changes are pushed before fresh Hub install validation.

## 18. PASS / FAIL / BLOCKED

### PASS

A provider is PASS only when all are true:

- Fresh Hub install succeeds.
- Fresh clone commit is expected.
- Run through Hub succeeds.
- Health/readiness succeeds.
- Main real workflow succeeds.
- Runtime service/process logs are visible in Hub.
- No fallback/mock/static-only pass.
- No hidden fatal errors in logs.
- Stop works if supported.
- Delete works and is idempotent.
- Delete removes provider-owned containers, volumes, networks, images, PIDs, and generated runtime files where applicable.
- Reinstall after delete succeeds.
- Secrets are not printed or committed.
- Required source fixes are pushed to provider repo.
- Required Hub wrapper fixes are committed in Hub repo.

### FAIL

A provider is FAIL if any are true:

- It only passes health but not real workflow.
- It requires manual patching after Hub install.
- It leaves provider-owned Docker images/resources after delete.
- It kills Hub frontend/backend or another provider.
- It silently falls back when real config/API fails.
- It prints secrets.
- It has no repeatable test path for its advertised feature.

### BLOCKED

A provider is BLOCKED, not PASS, if:

- Required external service/API is unavailable.
- Required account/key/access is missing.
- Provider source repo cannot be pushed but source fix is required.
- Hardware/disk/network constraints prevent real validation.
- Another agent has unmerged provider changes that must be reconciled first.

## 19. Validation record template

Use this per provider after testing:

```markdown
## Provider: <provider_id>

- Source repo:
- Branch:
- Expected commit:
- Fresh Hub clone commit:
- Install task ID:
- Run task ID:
- Stop task ID:
- Delete task ID:
- Runtime ports:
- Health endpoint result:
- Service/process log sources verified:
- Real workflow tested:
- Real workflow result:
- Fallback detected: yes/no
- Key presence checked without printing value: yes/no/not required
- Containers cleaned: yes/no/not applicable
- Volumes cleaned: yes/no/not applicable
- Networks cleaned: yes/no/not applicable
- Source-built images cleaned: yes/no/not applicable
- PID files cleaned: yes/no/not applicable
- Remaining acceptable base images:
- Logs reviewed:
- Provider source changes pushed: yes/no/not needed
- Hub wrapper changes committed: yes/no/not needed
- Final status: PASS/FAIL/BLOCKED
- Blocker details if any:
```

# Plan Real Provider Integration

Ngay: 2026-05-10

## Muc tieu

Tich hop 2 provider that vao AI Hub:

- `Agentic-Commerce-blueprint-provider-`
  - Repo: `https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-`
  - Verified HEAD: `25fba33abd8382e7f3cf21e0372b1becaf5501d7`
- `Multi-Agent-Intelligent-WarehousePublic-nvidia`
  - Repo: `https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia`
  - Verified HEAD: `7825d6848afddaa9be59083df105f98e84db92a7`

Ket qua cuoi cung:

- Frontend van render gan nhu ngay lap tuc.
- Frontend phai noi vao backend that cho hardware/provider/tasks/logs/config/status/metrics; mock data chi duoc dung lam fallback offline trong dev/test, khong hien giao dien gia khi backend dang chay.
- Provider chi clone source that vao `deploy/{providerId}` khi user bam install tren web.
- Neu user delete provider thi xoa sach deploy/runtime/log/task lien quan.
- Moi lifecycle tren frontend phai dung duoc: install, start/run, stop, delete, logs, config, metrics, benchmark, status/detail.
- Neu port trung thi backend tra warning/error ro va frontend hien do trong config; khong tu doi port ngam trong source.
- Neu hardware khong du thi chi canh bao, user van co quyen bam install/run.
- Neu source upstream loi thi clone vao `sua-loi-provider/`, sua, test pass 100%, push lai source provider, clear folder tam, roi moi viet provider cho AI Hub.

## Nguyen tac secret va repo clean

Khong commit NVIDIA API key vao GitHub.

- File duoc commit:
  - `.env.example` trong provider source va provider wrapper.
  - setup script co prompt nhap `NVIDIA_API_KEY`.
  - docs huong dan nhap key.
- File local khong commit:
  - `.env`
  - `deploy/**/.env`
  - `sua-loi-provider/**/.env`
- Khi test local co the dung key user cung cap, nhung chi ghi vao `.env` local bi gitignore.
- Truoc moi commit phai chay `git diff --cached --check` va `git status --short` de dam bao khong co secret/runtime/cache bi stage.

## Skill can dung

- `backend-skill`: FastAPI endpoints, background task runner, process manager, provider runtime/cache/logs.
- `frontend-skill`: UI action state, loading, config validation, logs stream, metric/detail wiring khong gay khung.
- `testing-skill`: chua co skill file rieng; dung pytest, Vitest, Playwright/browser smoke, script smoke tren Windows/Linux.
- `documentation-skill`: cap nhat docs cho provider contract, lifecycle, deploy, env, troubleshooting.
- `logging-skill`: ghi log phase vao `logs/tasks/real-provider-integration.md`.
- `push-code-skill`: commit/push sau khi tat ca phase pass.

## Folder target

```text
sua-loi-provider/
  agentic-commerce/                  # temp clone de test/fix upstream
  warehouse-nvidia/                  # temp clone de test/fix upstream

providers/
  agentic-commerce-blueprint/
    aihub.provider.json
    .env.example
    config/default.json
    runtime/.gitkeep
    logs/.gitkeep
    scripts/windows/*.ps1
    scripts/linux/*.sh
  multi-agent-intelligent-warehouse/
    aihub.provider.json
    .env.example
    config/default.json
    runtime/.gitkeep
    logs/.gitkeep
    scripts/windows/*.ps1
    scripts/linux/*.sh

deploy/
  .gitkeep
  agentic-commerce-blueprint/        # chi co sau khi user install
  multi-agent-intelligent-warehouse/ # chi co sau khi user install
```

`deploy/**` phai bi ignore tru noi can thiet nhu `.gitkeep`, vi source that duoc clone luc install va bi xoa luc delete.

## Contract provider bat buoc

Moi provider moi phai co:

- `aihub.provider.json`
  - id, name, repoUrl, branch, type, description, tags, visual.
  - requirements minimum/recommended.
  - commands cho Windows va Linux.
  - runtime defaultPort, healthUrl, metricsUrl, statusFile, metricsFile, pidFile, logFile.
  - env safe schema, vi du `NVIDIA_API_KEY` la required secret nhung khong co value.
- `.env.example`
  - `NVIDIA_API_KEY=`
  - `PORT=...`
  - cac bien source can.
- `config/default.json`
  - branch, port, installDirectory, docker mode neu co.
  - safe editable fields de frontend sua.
- `scripts/windows/setup.ps1`, `run.ps1`, `stop.ps1`, `health.ps1`, `collect-metrics.ps1`, `delete.ps1` neu can.
- `scripts/linux/setup.sh`, `run.sh`, `stop.sh`, `health.sh`, `collect-metrics.sh`, `delete.sh` neu can.
- Runtime outputs:
  - `runtime/status.json`
  - `runtime/metrics.json`
  - `runtime/provider.pid`
  - `logs/runtime.log`

## Backend API can bo sung

### Lifecycle

- `POST /api/providers/{id}/install`
  - Tra `{ taskId }` ngay.
  - Background task clone source vao `deploy/{id}`.
  - Neu da clone thi pull/fetch hoac skip theo config.
  - Tao `.env` tu input key hoac existing local env.
- `POST /api/providers/{id}/run`
  - Check port conflict truoc khi start.
  - Neu port conflict: tra loi config co code `PORT_IN_USE`, frontend hien do.
  - Neu hardware thap: tra warning nhung van cho run neu user confirm.
- `POST /api/providers/{id}/stop`
  - Khong dung timeout cung ngan.
  - Gui signal stop, poll health/process cho toi khi stop hoac task failed co reason.
- `DELETE /api/providers/{id}`
  - Stop truoc neu dang chay.
  - Xoa `deploy/{id}`, runtime/log generated, task temp.
  - Khong xoa source wrapper trong `providers/{id}`.

### Status, config, logs, metrics

- `GET /api/providers/{id}/status`
- `GET /api/providers/{id}/metrics`
- `GET /api/providers/{id}/logs?tail=200&level=&source=&cursor=`
- `GET /api/providers/{id}/config`
- `PATCH /api/providers/{id}/config`
- `POST /api/providers/{id}/benchmark`
- `GET /api/tasks/{taskId}`
- `GET /api/tasks/{taskId}/events`
- `GET /api/events`

Tat ca action dai phai la background task, request path chi tao task va return nhanh.

## Frontend real-data policy

- AppShell:
  - `GET /api/tasks/active` la source chinh cho live task count.
  - Neu backend timeout/offline moi dung fallback local trong 250ms.
- Home:
  - `GET /api/hardware/snapshot`, `GET /api/providers/summary`, `GET /api/tasks`.
  - Khong hard-code CPU/GPU/RAM/task khi backend available.
  - Skeleton/lightweight stale state phai hien ngay, sau do replace bang backend data.
- Hub list:
  - `GET /api/providers` va `GET /api/providers/featured`.
  - Provider cards hien install/run/status/metric tu backend.
  - Static `hubProjects` chi duoc dung de render SSR/dev fallback neu backend khong reachable.
- Hub detail:
  - `GET /api/providers/{id}`, `/status`, `/metrics`, `/logs`, `/config`.
  - Action buttons dung lifecycle API that.
  - Logs/metrics/config khong dung mock khi backend reachable.
- Testing:
  - Vitest phai co case backend success de dam bao UI/API client khong lay mock.
  - Vitest phai co case backend timeout de dam bao fallback khong block UI.
  - Browser smoke phai verify data co the doi theo backend fixture.

## Co che chong timeout va khung UI

- Backend lifecycle runner:
  - Khong block request cho install/run/stop/delete.
  - Task co heartbeat moi 1-2s.
  - Poll process/health endpoint voi exponential backoff nhe.
  - Timeout co tinh theo phase lon, khong hard timeout ngan cho service khoi dong cham.
  - Task state: queued, running, waiting_health, warning, completed, failed, cancelled.
- Logs:
  - Tail theo byte window, cursor offset, khong doc full file.
  - Neu source khong co log JSON thi wrapper normalize stdout/stderr thanh JSONL.
- Metrics:
  - `collect-metrics` chay periodic background va cache file.
  - API chi doc cache memory/file mtime debounce.
- Frontend:
  - Bam nut phai optimistic loading ngay.
  - Poll task status/SSE, khong cho user nghi nut bi do.
  - Virtualize hoac incremental render neu log/card nhieu.
  - Tat ca fetch lifecycle co abort/retry ro, khong khoa main thread.

## Port va config

- Source provider khong duoc tu random/auto-change port.
- Port lay tu AI Hub config:
  - `providers/{id}/config/default.json`
  - user edit qua frontend config.
  - setup/run truyen `PORT` vao `.env`/command.
- Backend check port:
  - `GET /api/system/ports?ports=...` hoac validation trong `PATCH config` va `run`.
  - Neu trung port, luu warning vao config/status va frontend hien do.
- Hardware insufficient:
  - compatibility = warn/block visual tuy muc do.
  - Khong chan action install/run; chi them warning confirm.

## Phase 0 - Baseline va safety gate

Thoi gian du kien: 30-45 phut.

Viec can lam:

- Doc `backend-skill`, `frontend-skill`, `documentation-skill`, `logging-skill`.
- Tao `logs/tasks/real-provider-integration.md`.
- Tao/cap nhat `.gitignore` cho:
  - `sua-loi-provider/`
  - `deploy/*`
  - `!deploy/.gitkeep`
  - `**/.env`
  - runtime/cache files.
- Snapshot hien trang:
  - `git status --short`
  - backend pytest
  - frontend typecheck/test/build
- Tao branch neu can, hoac commit phase plan truoc khi code nang.

Pass criteria:

- Worktree clean truoc khi code phase 1.
- Khong co secret trong staged diff.
- Test baseline pass.

## Phase 1 - Clone, inspect, run, test 2 upstream sources

Thoi gian du kien: 2-4 gio tuy source.

Viec can lam:

- Clone vao temp:
  - `sua-loi-provider/agentic-commerce`
  - `sua-loi-provider/warehouse-nvidia`
- Doc README, package files, Docker compose, scripts, env needs, port usage.
- Tao `.env` local tu `.env.example` hoac README, ghi NVIDIA key local only.
- Chay install/test theo source:
  - Python: pytest/ruff/mypy neu co.
  - Node: npm/pnpm test/build/lint neu co.
  - Docker: docker compose config/build/smoke neu can.
- Run source, verify health endpoint/UI/API.
- Ghi lai:
  - required deps
  - default ports
  - env keys
  - startup time
  - health command
  - log location
  - metrics/benchmark co san.

Neu loi:

- Sua trong temp clone.
- Them `.env.example`, setup/run/health/metrics support neu source thieu.
- Them stream logs va dashboard-friendly metrics vao source neu can.
- Test pass 100%.
- Commit va push lai upstream repo source do.
- Ghi commit hash moi vao docs/log.

Pass criteria:

- Moi source co lenh setup/run/health/test ro rang.
- Source run duoc local voi key local.
- Source co `.env.example` clean.
- Source co co che doc port tu env/config, khong random doi port.
- Neu co sua source, da push upstream va clear temp sau khi ghi log.

## Phase 2 - Provider wrapper va deploy-on-install

Thoi gian du kien: 2-3 gio.

Viec can lam:

- Tao provider wrapper trong `providers/` cho 2 provider.
- Them `deploy/.gitkeep`.
- Implement script wrapper:
  - setup/install: clone source vao `deploy/{id}`, checkout branch/commit, tao `.env` neu chua co.
  - run: truyen port/env, start service/container, ghi status/log/pid.
  - stop: dung process/container, poll toi khi service stop.
  - delete: stop neu can, xoa deploy/runtime/log generated.
  - health: in JSON stdout va ghi `runtime/status.json`.
  - collect-metrics: in JSON stdout va ghi `runtime/metrics.json`.
- Linux script phai executable.
- Windows script dung PowerShell, uu tien `pwsh`.

Pass criteria:

- Khong co source cloned trong git.
- Install moi clone vao `deploy/{id}`.
- Delete xoa sach `deploy/{id}`.
- Script chay duoc dry-run/smoke tren Windows; Linux script shellcheck/simple bash parse neu co.

## Phase 3 - Backend runtime service day du

Thoi gian du kien: 3-5 gio.

Viec can lam:

- Them schemas:
  - task detail/event
  - provider config
  - provider status
  - provider log entry/cursor
  - provider metrics/benchmark
  - action warning/error.
- Them services:
  - `provider_runtime.py`
  - `provider_logs.py`
  - `provider_config.py`
  - `process_manager.py`
  - `port_registry.py`
  - `task_events.py`.
- Them API lifecycle va logs/config/metrics.
- Task runner:
  - background thread/process-safe queue.
  - heartbeat.
  - cancellation for stop/delete.
  - no hard timeout ngan.
- Provider registry:
  - include installed/running/status/cacheVersion.
  - read runtime/status cache without heavy IO on request path.
- Port validation:
  - warn on config edit.
  - block run with explicit `PORT_IN_USE` unless user changes port.

Pass criteria:

- Backend pytest covers:
  - install creates task fast.
  - logs tail cursor.
  - config patch + port conflict.
  - hardware warning does not block action.
  - delete cleans deploy dir.
  - request latency warm path still under budget.

## Phase 4 - Frontend connect 100% provider actions

Thoi gian du kien: 3-5 gio.

Viec can lam:

- Add API client functions for lifecycle/status/logs/config/metrics/benchmark/tasks/events.
- Replace mock-first display bang backend-first/stale-while-revalidate display:
  - SSR/static co the dung seed de page hien ngay.
  - Client mount phai fetch backend immediately va replace data neu backend online.
  - Khong giu metric/hardware/task gia khi backend da tra data.
- Hub detail:
  - Install, Start, Stop, Delete buttons.
  - Loading states per action.
  - Task progress and current step.
  - Port conflict red state in config.
  - Hardware warning but still allow action.
  - Logs panel live tail with cursor and level filter.
  - Metrics cards from backend.
  - Benchmark action/result if source supports; fallback provider-specific metric.
- Hub list/card:
  - installed/running/status sync from backend.
  - no blocking render.
- Navbar/top status:
  - active task count from task API/SSE.
- Add fallback polling if SSE unavailable.

Pass criteria:

- All frontend functions have visible loading/error/success states.
- Khi backend online, Home/Hub/Detail dung backend data that.
- Khi backend offline, UI fallback trong 250ms va khong khung.
- No button feels frozen; action returns task immediately.
- Theme/page navigation remains responsive.
- Vitest covers API client/task state helpers.
- Playwright/browser smoke covers install/start/stop/delete happy path with mocked backend or dry-run provider.

## Phase 5 - Real provider smoke with Docker/local services

Thoi gian du kien: 2-6 gio tuy Docker/model/download.

Viec can lam:

- Run backend and frontend.
- For each real provider:
  - Install from web.
  - Verify source appears in `deploy/{id}`.
  - Verify `.env` local exists and is not tracked.
  - Start from web.
  - Verify health/status/logs/metrics.
  - Run benchmark if source supports.
  - Stop from web.
  - Delete from web.
  - Verify deploy cleanup.
- Test port conflict:
  - set same port for 2 providers.
  - verify frontend red warning.
  - verify no silent auto-port-change.
- Test slow service:
  - simulate long startup.
  - verify heartbeat/log/ping keeps UI alive.

Pass criteria:

- 2 real providers pass full lifecycle from UI.
- No secret staged.
- No deploy source staged.
- No request path latency regression.

## Phase 6 - Docs, logs, CI/CD, push

Thoi gian du kien: 1-2 gio.

Viec can lam:

- Update docs:
  - `docs/backend-api.md`
  - `docs/provider-plan.md`
  - `docs/real-provider-integration.md`
  - provider READMEs if needed.
- Update logs after each phase:
  - `logs/tasks/real-provider-integration.md`
- CI:
  - backend pytest voi coverage threshold.
  - backend ruff lint va format check.
  - backend mypy hoac pyright strict enough cho app code.
  - backend pip-audit/safety dependency audit.
  - backend import smoke va FastAPI OpenAPI schema generation.
  - backend latency test gate cho warm path.
  - backend provider manifest validation.
  - backend lifecycle dry-run tests tren Windows va Linux.
  - frontend typecheck/test/build.
  - provider manifest validation.
  - script syntax checks:
    - PowerShell parser on `.ps1`.
    - bash `bash -n` on `.sh`.
  - secret scan pattern for `NVIDIA_API_KEY`, `nvapi-`, `.env`.
  - dependency lock/cache dung rieng cho frontend/backend.
  - matrix:
    - backend: Linux x64, Linux ARM64 neu runner co san, Windows x64.
    - frontend: Linux x64/ARM64, Windows x64/ARM64.
  - artifact:
    - pytest junit/coverage xml.
    - frontend test report/build summary.
    - provider validation report.
- Final commands:
  - `git diff --check`
  - `pytest` in backend
  - `npm.cmd run typecheck`
  - `npm.cmd run test`
  - `npm.cmd run build`
  - provider script syntax checks
  - real provider smoke result recorded.
- Commit and push.

Pass criteria:

- CI green or locally equivalent commands pass.
- Docs/logs complete.
- GitHub push complete.
- Final summary includes test results, latency numbers, provider source commits, and any remaining operational notes.

## Definition of Done

- 2 upstream providers are verified and fixed if needed.
- 2 provider wrappers exist in AI Hub and are discoverable on frontend.
- Install clones source into `deploy/` only after user action.
- Start/stop/delete/config/logs/status/metrics/benchmark work from frontend.
- Port conflict is visible and blocks run until changed; source does not auto-change port.
- Hardware insufficiency is warning-only.
- Slow install/start/stop/delete uses task heartbeat, not brittle hard timeout.
- `.env` with NVIDIA key remains local only.
- All tests/builds pass.
- Docs/logs are updated after each phase.
- Code is pushed to GitHub.

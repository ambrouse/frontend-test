# Plan Backend Provider Runtime

Ngay: 2026-05-10

## Muc tieu

Tao backend FastAPI trong folder `backend/` va provider runtime trong folder `providers/` o repo root. Moi folder con trong `providers/` la mot provider tu frontend. Backend phai doc provider, doc hardware, doc runtime/log/metrics, va phuc vu frontend voi do tre thap nhat co the. Uu tien cao nhat: frontend hien thi ngay lap tuc, khong bi do/khung khi backend doc IO hoac quet he thong.

## Skill can dung

- `backend-skill`: setup FastAPI, service layer, API contract, lifecycle command runner.
- `frontend-skill`: thay mock data bang API client/cache ma van giu UI responsive.
- `testing-skill`: chua co file skill trong repo; dung pytest cho backend va Vitest cho frontend.
- `documentation-skill`: cap nhat docs API/provider contract sau tung phase.
- `logging-skill`: ghi log task vao `logs/tasks/`.
- `push-code-skill`: truoc khi push phai chay test/build va kiem tra CI/CD.

## Cau truc folder muc tieu

```text
backend/
  pyproject.toml
  README.md
  app/
    main.py
    api/
      routes_health.py
      routes_hardware.py
      routes_providers.py
      routes_tasks.py
    core/
      config.py
      cache.py
      scheduler.py
      paths.py
    services/
      hardware.py
      provider_registry.py
      provider_runtime.py
      provider_logs.py
      compatibility.py
    schemas/
      hardware.py
      provider.py
      task.py
      log.py
    tests/
      test_hardware.py
      test_provider_registry.py
      test_api_contract.py
providers/
  local-llm-studio/
    aihub.provider.json
    config/default.json
    runtime/.gitkeep
    logs/.gitkeep
    scripts/windows/*.ps1
    scripts/linux/*.sh
  vision-lab/
  ...
frontend/
```

## Nguyen tac hieu nang

Backend khong doc file provider truc tiep tren moi request. Tat ca IO nang phai chay ngoai request path.

- Luc boot: tra API duoc ngay voi cache rong/snapshot cu; quet providers bang background task.
- Provider registry: doc manifest theo batch, cache in-memory, update bang file watcher hoac periodic scan.
- Hardware snapshot: lay CPU/RAM nhanh moi 1s; GPU/VRAM/temperature co the poll 1-2s va cache.
- Logs: khong doc full file; chi tail theo byte window hoac dung cursor.
- Metrics/status: doc file runtime theo debounced watcher, fallback periodic poll.
- Frontend: hydrate tu cached API response; revalidate nhe bang polling/SSE, khong block render.
- Request budget muc tieu:
  - `/api/health`: < 10ms.
  - `/api/hardware/snapshot`: < 20ms khi cache warm.
  - `/api/providers`: < 30ms khi cache warm.
  - `/api/providers/{id}`: < 20ms khi cache warm.
  - `/api/providers/{id}/logs?tail=200`: < 50ms voi tail byte window.

Neu IO bat buoc khung, doi pipeline: background indexer + in-memory snapshot + event stream, request chi doc cache.

## API frontend can

### App shell

- `GET /api/tasks/active`
  - Dung cho top status `1 task live`.
  - Tra `{ count, tasks: RunningTask[] }`.
  - Cache TTL 500-1000ms.

### Home page

- `GET /api/hardware/snapshot`
  - CPU: name, cores, usagePercent, temperatureC.
  - GPU: name, vendor, usagePercent, temperatureC, vramTotalMb, vramUsedMb, driverVersion.
  - RAM: totalMb, usedMb.
  - Disk: totalGb, freeGb, installPathFreeGb.
  - timestamp.
- `GET /api/providers/summary`
  - total providers, ready providers, blocked providers, installed/running counts.
- `GET /api/tasks`
  - running/installing/stopping/completed tasks, progress, CPU/GPU/RAM/VRAM per task.

### Hub list

- `GET /api/providers`
  - Query: `type`, `q`, `status`, `limit`, `cursor`.
  - Tra danh sach card data: id, name, type, description, tags, accentColor, visual, installStatus, runStatus, requirements.minimum, compatibility, lastBenchmark, lastRunAt.
  - Backend nen tinh compatibility bang cached hardware snapshot.
- `GET /api/providers/featured`
  - Tra 30 provider random/stable shuffle cho banner.
  - Backend dung deterministic daily seed hoac cached shuffle, khong random moi request.

### Hub detail

- `GET /api/providers/{id}`
  - Tra full manifest + editableConfig + status + metrics + benchmark.
- `GET /api/providers/{id}/status`
  - state, pid, port, platform, uptimeSec, currentStep, progressPercent, health.
- `GET /api/providers/{id}/metrics`
  - process CPU/RAM/GPU/VRAM, service request/latency/error, benchmark.
- `GET /api/providers/{id}/logs?tail=200&level=&source=&cursor=`
  - newline JSON logs normalized to ProjectLog.
- `GET /api/providers/{id}/config`
  - profile, branch, port, installDirectory, env safe keys.
- `PATCH /api/providers/{id}/config`
  - update safe config fields only.
- `POST /api/providers/{id}/install`
- `POST /api/providers/{id}/run`
- `POST /api/providers/{id}/stop`
- `DELETE /api/providers/{id}`
  - Tat ca action tra task id ngay, action chay background.

### Low-latency updates

- `GET /api/events`
  - SSE stream cho hardware/provider/task/log update.
  - Frontend fallback polling neu SSE khong co.

## Backend service design

### Provider registry

- Source of truth: `providers/*/aihub.provider.json`.
- On boot: schedule scan, return cached snapshot.
- Validate manifest bang Pydantic.
- Cache key: provider id + manifest mtime + runtime status mtime + metrics mtime.
- Watch strategy:
  - Windows/Linux: dung `watchfiles` neu co.
  - Fallback: scan mtime moi 2s.
- Khong parse log trong registry.

### Hardware service

- CPU/RAM/disk:
  - Dung `psutil`.
  - Temperature dung `psutil.sensors_temperatures()` neu support, fallback null/unknown.
- GPU/VRAM:
  - Uu tien NVML qua `pynvml` de nhanh va it parse string.
  - Fallback `nvidia-smi --query-gpu=... --format=csv,noheader,nounits` voi TTL 2s.
  - AMD/Intel GPU de adapter sau, schema van giu vendor.
- Cache snapshot in-memory, refresh background.
- Request khong goi `nvidia-smi` truc tiep.

### Provider runtime service

- `install/run/stop/delete` tao task background va tra task id ngay.
- Command runner:
  - Windows: `pwsh -File scripts/windows/run.ps1`.
  - Linux: `bash scripts/linux/run.sh`.
  - Working directory = provider root.
  - Timeout va process group rieng.
- Runtime state doc tu `runtime/status.json`, `runtime/metrics.json`, `logs/runtime.log`.
- Neu file chua co, derive state tu manifest/install folder.

### Logs service

- Doc tail theo byte window, vi du 256KB cuoi file.
- Parse JSONL tung dong, dong loi parse thi wrap thanh `level=warn source=system`.
- Ho tro cursor offset de frontend fetch incrementally.
- Khong bao gio doc full log lon trong request.

## Provider folder seed

Phase dau co the tao folder cho tat ca provider hien co tren frontend tu `hubProjects`.

Moi provider folder toi thieu:

```text
providers/{id}/
  aihub.provider.json
  config/default.json
  runtime/.gitkeep
  logs/.gitkeep
  scripts/windows/setup.ps1
  scripts/windows/run.ps1
  scripts/windows/stop.ps1
  scripts/windows/health.ps1
  scripts/windows/collect-metrics.ps1
  scripts/linux/setup.sh
  scripts/linux/run.sh
  scripts/linux/stop.sh
  scripts/linux/health.sh
  scripts/linux/collect-metrics.sh
```

Seed script nen generate tu mot data file, khong viet tay 30 folder bang code lap lai.

## Frontend migration plan

- Tao `frontend/src/services/apiClient.ts` voi fetch timeout ngan va abort.
- Tao hooks/data layer:
  - `useHardwareSnapshot()`
  - `useProviders()`
  - `useFeaturedProviders()`
  - `useProviderDetail(id)`
  - `useProviderLogs(id, filters)`
  - `useTasks()`
- Render ngay bang stale cache/mock fallback, sau do revalidate.
- Dung SSE `/api/events` de update nhe, fallback polling:
  - hardware/tasks: 1s khi page visible, 5s khi hidden.
  - providers list: 10-30s hoac khi event registry changed.
  - logs: cursor-based khi detail open.
- Khong de carousel state lam re-render provider grid.

## Phase thuc hien

### Phase 1 - Backend scaffold va contracts

Thoi gian: 2-3 gio.

- Tao `backend/` FastAPI app.
- Setup `pyproject.toml`, pytest, ruff hoac format command neu chon.
- Tao Pydantic schemas khop frontend types.
- Tao API stub tra cache rong/mock snapshot.
- Testing: pytest API contract.
- Docs/logs: update docs va log phase.

### Phase 2 - Provider registry va folder seed

Thoi gian: 3-4 gio.

- Tao `providers/`.
- Seed provider folders tu frontend provider list.
- Viet registry scanner async/background.
- Validate `aihub.provider.json`.
- API `/api/providers`, `/api/providers/{id}`, `/api/providers/featured`.
- Testing: manifest validation, scan cache, API latency warm path.

### Phase 3 - Hardware snapshot service

Thoi gian: 3-5 gio.

- Implement psutil CPU/RAM/disk.
- Implement NVML GPU/VRAM/temp, fallback `nvidia-smi`.
- Background refresh + TTL cache.
- API `/api/hardware/snapshot`.
- Testing: mock psutil/NVML, verify request khong spawn shell tren warm path.

### Phase 4 - Runtime, tasks, logs

Thoi gian: 4-6 gio.

- Implement task manager in-memory.
- Implement command runner cross-platform.
- Implement status/metrics file reader with mtime cache.
- Implement log tail cursor.
- APIs action run/install/stop/delete/logs/metrics/status.
- Testing: temp provider fixture, fake scripts Windows/Linux style, log tail large file.

### Phase 5 - Frontend API integration

Thoi gian: 3-5 gio.

- Replace direct mock imports with API hooks.
- Keep instant render using initial cached data/fallback.
- Add loading skeleton only for small areas, never block full page.
- Add abort/debounce for search.
- Testing: Vitest hooks/components with mocked fetch.

### Phase 6 - Realtime updates va performance pass

Thoi gian: 3-4 gio.

- Add SSE `/api/events`.
- Frontend subscribe when visible.
- Add performance checks:
  - no long request path IO.
  - no full provider re-render on hardware tick.
  - no full log read.
- Testing: backend async tests, frontend render count smoke where feasible.

### Phase 7 - CI/CD va production hardening

Thoi gian: 2-3 gio.

- Update GitHub Actions:
  - backend pytest on Linux/Windows.
  - frontend typecheck/test/build.
  - optional API contract test.
- Add `.env.example` for backend.
- Add README commands.
- Final full verification and push.

## Ruis ro va cach giam

- `nvidia-smi` cham: khong goi trong request; dung NVML va background cache.
- File IO provider/log cham: mtime cache, tail byte window, watcher/debounce.
- 30+ provider folder scan khung: scan background, hash/mtime incremental.
- Frontend khung khi polling: normalize state, memo card/grid, update only changed slices.
- Cross-platform scripts khac nhau: manifest command mapping Windows/Linux va tests fixture.

## Done criteria

- `backend/` chay FastAPI duoc tren Windows/Linux.
- `providers/` co folder provider seed va manifest hop le.
- Frontend load Home/Hub ngay ca khi backend dang scan provider.
- Warm API path khong doc IO nang.
- Run/stop/install action tra task id ngay.
- Typecheck/test/build frontend pass.
- Pytest backend pass.
- Docs/log updated.
- CI/CD cap nhat va pass.

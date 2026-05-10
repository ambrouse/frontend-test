# Provider Runtime Hardening Plan

Date: 2026-05-11

## 1. Muc tieu

Dam bao AI Hub chay bang real backend data, provider runtime hoat dong on dinh, frontend khong fallback sai, va do tre duoi `0.1s` cho cac API/UI path nong trong dieu kien thuc te. Ket qua cuoi cung phai cho phep clone repo moi, setup, install provider, run, stop, read logs, read metrics, delete, install lai va chay lai ma khong phu thuoc vao `sua-loi-provider/`.

## 2. Skill can dung

- `backend-skill`: sua API FastAPI, hardware collector, task queue, provider runtime, setup scripts.
- `frontend-skill`: noi UI vao backend real data, xoa fallback sai, toi uu render/nav/theme.
- `testing-skill`: unit, integration, e2e, latency benchmark, real clone/install smoke.
- `documentation-skill`: cap nhat docs cach setup/run/provider contract.
- `logging-skill`: ghi log phase vao `logs/tasks/real-provider-hardening.md`.

## 3. Nguyen tac pass bat buoc

- Khong doc provider tu `sua-loi-provider/` trong runtime. Thu muc nay phai co the bi xoa/doi ten ma web van install provider bang clone GitHub vao `deploy/`.
- Frontend chi duoc dung static data trong trang thai offline co chu y; khi backend online thi Home/Hub/Detail phai hien real data tu API.
- Moi action tren frontend phai co backend endpoint that: install, start, stop, delete, config port, logs, metrics, task status, hardware.
- Moi request nong cua backend phai tra ve tu cache/snapshot/task queue, khong duoc scan IO nang tren request path.
- Hardware collector phai doc dung CPU/RAM/Disk tren Windows/Linux; GPU/VRAM/temp phai dung `nvidia-smi` neu co NVIDIA, fallback ro rang `unknown` neu may khong ho tro.
- Provider install/run co the can lau, nhung request HTTP phai tra task id ngay. UI poll task/log/status, khong khoa thread render.
- Secret NVIDIA key khong duoc commit. Chi cho phep `.env`, `.env.local`, env runtime hoac input setup local.

## 4. Phase 0 - Baseline va moi truong sach

Thoi gian du kien: 20-30 phut.

Buoc thuc hien:

1. Kiem tra worktree sach, branch, remote.
2. Xoa/doi ten `sua-loi-provider/` de dam bao runtime khong map vao source temp.
3. Xoa `deploy/agentic-commerce-blueprint` va `deploy/multi-agent-intelligent-warehouse` neu ton tai.
4. Xoa runtime/log local trong `providers/*/runtime` va `providers/*/logs` tru `.gitkeep`.
5. Chay `setup.ps1` tren Windows va `setup.sh` qua Git Bash/WSL neu kha thi; kiem tra tao backend env, frontend deps, seed provider.

Tieu chi pass:

- Repo khong can `sua-loi-provider/` de backend start.
- `setup.ps1` va `setup.sh` syntax pass.
- Khong co `.env` that trong staged/tracked files.

## 5. Phase 1 - Kiem tra va sua hardware collector

Thoi gian du kien: 45-75 phut.

Buoc thuc hien:

1. Doc `backend/app/services/hardware.py`, schema hardware, frontend renderer tren Home/Detail.
2. Doi hardware collector thanh pipeline cache gom:
   - CPU cores/model/usage/temp neu OS ho tro.
   - RAM total/used/free.
   - Disk total/free/install path free.
   - GPU name/driver/load/VRAM/temp bang `nvidia-smi --query-gpu=... --format=csv,noheader,nounits`.
   - Fallback `null`/`unknown` ro rang khi khong co NVIDIA hoac command fail.
3. Them timeout cuc ngan cho hardware probes nang, vi du `nvidia-smi` 250-500ms chay background refresh, request path doc snapshot cu.
4. Them tests mock psutil/nvidia-smi cho Windows/Linux case.
5. Kiem tra UI khong hien so gia khi hardware field unknown.

Tieu chi pass:

- `GET /api/hardware/snapshot` p95 warm < `50ms`, muc tieu < `20ms`.
- So CPU/RAM/Disk khop may local trong sai so chap nhan duoc.
- GPU/VRAM/temp khong dung seed fake khi probe that fail; hien `unknown` hoac null co chu y.

## 6. Phase 2 - Provider runtime contract audit

Thoi gian du kien: 60-90 phut.

Buoc thuc hien:

1. Validate tat ca `providers/*/aihub.provider.json`.
2. Rieng 2 provider that, kiem tra:
   - repo URL.
   - branch.
   - install directory trong `deploy/`.
   - default port va config port.
   - script Windows/Linux setup/run/stop/delete/health/metrics.
   - log/status/metrics file path.
3. Sua runtime backend de:
   - refuse path traversal.
   - detect port conflict va tra status warning do UI hien do.
   - khong timeout cung ngan; long task co heartbeat/progress.
   - delete phai stop truoc, sau do xoa deploy dir an toan.
4. Them integration tests cho action order:
   - delete before install.
   - install twice idempotent.
   - run without install fail co message dung.
   - port conflict fail ro rang neu khong `force`.
   - stop/delete timeout-safe.

Tieu chi pass:

- Backend lifecycle dry-run pass 100%.
- Real delete cleanup khong xoa ngoai `deploy/`.
- UI nhan duoc task id ngay cho moi action.

## 7. Phase 3 - Real clone/install/run test tung provider

Thoi gian du kien: 2-4 gio, tuy Docker pull/provider startup.

Buoc thuc hien:

1. Dam bao `sua-loi-provider/` da bi xoa hoac doi ten.
2. Xoa `deploy/{provider_id}`.
3. Goi API install provider, khong chay script truc tiep tru khi debug.
4. Poll `/api/tasks/{task_id}`, `/api/providers/{id}/status`, `/logs`.
5. Xac nhan GitHub clone that vao `deploy/{provider_id}`.
6. Goi start/run:
   - Neu may thieu GPU/secret/model thi backend chi warning neu hardware thieu, nhung loi runtime source phai duoc log ro.
   - Neu source can key, test voi env local khong commit.
7. Goi health/metrics/logs.
8. Goi stop, start lai.
9. Goi delete, xac nhan deploy dir sach.
10. Install lai sau delete.

Provider can test:

- `agentic-commerce-blueprint`
- `multi-agent-intelligent-warehouse`

Tieu chi pass:

- Install clone that pass.
- Logs stream/doc duoc tren frontend.
- Stop/delete khong fail vi warning stderr cua Docker/PowerShell.
- Start neu fail do thieu external dependency thi UI hien loi that, khong hien fake running.
- Delete xoa sach `deploy/{provider_id}`.

## 8. Phase 4 - Frontend real-data audit, bo fallback sai

Thoi gian du kien: 60-90 phut.

Buoc thuc hien:

1. Audit `frontend/src/services/mockData.ts` va tat ca component dung mock.
2. Chuyen policy thanh:
   - initial skeleton/lightweight placeholder.
   - fetch backend real data.
   - offline fallback chi khi backend timeout/offline va UI co status offline.
3. Hub:
   - list provider tu backend.
   - featured/banner tu backend.
   - card status/runtime/log metric tu backend overlay.
4. Detail:
   - config port tu backend.
   - action buttons call API real.
   - logs/metrics/status poll real.
   - khong hien benchmark fake sau khi backend da tra data.
5. Home:
   - hardware/task tu backend.
   - khong dung GPU fake neu backend tra unknown.
6. Them frontend tests mock fetch success/offline/error de dam bao khong fallback bậy.

Tieu chi pass:

- Khi backend online, khong co trang nao doc provider list tu `mockData` sau initial render.
- Khi backend offline, UI hien offline/fallback ro rang.
- Button navbar/theme/action phan hoi ngay, khong block khi provider list nhieu.

## 9. Phase 5 - Latency benchmark va toi uu

Thoi gian du kien: 90-150 phut.

Buoc thuc hien:

1. Them script benchmark backend, vi du `backend/scripts/benchmark_latency.py`, do:
   - `/api/health`
   - `/api/hardware/snapshot`
   - `/api/providers`
   - `/api/providers/featured`
   - `/api/providers/{id}`
   - `/api/providers/{id}/status`
   - `/api/providers/{id}/logs`
2. Do p50/p95/p99 voi warm cache, 100-1000 requests local.
3. Them frontend Playwright hoac browser automation smoke:
   - first render Home.
   - nav Home -> Hub -> Detail.
   - theme toggle.
   - filter/search Hub.
   - click install/start/stop/delete dry-run or test provider.
4. Neu latency > `100ms`:
   - tim request path scan IO.
   - cache manifest/status/log tail.
   - tach heavy hardware probe ra background refresh.
   - virtualize/defer provider cards neu render qua nang.
   - memoize card/hero, giam image/layout thrash.
5. Do lai sau moi fix.

Tieu chi pass:

- Backend warm p95 < `100ms`, muc tieu < `50ms`.
- UI nav/button khong khung; interaction response muc tieu < `100ms`.
- Banner/card/image khong lam theme toggle hoac navbar bi delay dang ke.

## 10. Phase 6 - Setup reproducibility tren may moi

Thoi gian du kien: 60-120 phut.

Buoc thuc hien:

1. Kiem tra `setup.ps1` va `setup.sh`:
   - detect Python phu hop.
   - tao `.venv` neu chua co.
   - cai backend trong `.venv`.
   - cai frontend bang `npm ci`.
   - hoi NVIDIA key va ghi `.env.local` local.
   - khong ghi secret vao tracked provider files.
2. Neu Python khong du version:
   - Windows: dung `py -3.11` neu co; neu khong co thi thong bao lenh cai bang `winget`.
   - Linux: detect `python3.11`/`python3.12`; neu khong co thi thong bao package manager command.
3. Them docs run:
   - `setup.ps1`
   - `setup.sh`
   - backend dev server.
   - frontend dev server.
   - provider lifecycle.
4. Test clone sach trong folder temp:
   - clone repo.
   - chay setup.
   - chay backend/frontend.
   - chay provider lifecycle dry-run.

Tieu chi pass:

- Clone moi co the setup duoc tren Windows.
- Linux path/script syntax pass trong CI va WSL/Git Bash local neu co.
- Docs du de nguoi dung clone, nhap key, run.

## 11. Phase 7 - CI/CD strict gates

Thoi gian du kien: 45-75 phut.

Buoc thuc hien:

1. Backend CI:
   - ruff.
   - ruff format.
   - mypy.
   - pytest coverage.
   - provider manifest validation.
   - secret scan.
   - OpenAPI generation.
   - pip-audit.
   - latency benchmark with threshold.
2. Frontend CI:
   - npm ci.
   - typecheck.
   - vitest.
   - production build.
   - npm audit.
   - optional Playwright smoke with mocked backend.
3. Provider CI:
   - Bash syntax.
   - PowerShell syntax.
   - dry-run lifecycle scripts for the 2 real providers.
4. Matrix:
   - Windows x64.
   - Linux x64.
   - Linux ARM64 neu runner san sang.

Tieu chi pass:

- CI fail neu co secret, provider manifest invalid, latency vuot nguong, frontend build fail, lifecycle dry-run fail.

## 12. Phase 8 - Documentation, logs, push

Thoi gian du kien: 30-45 phut.

Buoc thuc hien:

1. Ghi log tung phase vao `logs/tasks/real-provider-hardening.md`.
2. Cap nhat docs:
   - backend API.
   - provider plan/contract.
   - setup/run guide.
   - known limitations neu provider source can external service/GPU/key.
3. Chay full gate local lan cuoi.
4. Commit theo nhom ro rang.
5. Push len GitHub.

Tieu chi pass:

- Worktree sach sau push, ngoai ignored cache/deploy/log runtime.
- Final note gom latency numbers that, test commands, provider status that, va commit hash.

## 13. Lenh test du kien

```powershell
# Backend gates
cd backend
ruff check .
ruff format --check .
mypy app
python scripts/validate_providers.py
python scripts/check_no_secrets.py
pytest --cov=app --cov-report=term-missing --cov-fail-under=70
python scripts/benchmark_latency.py --threshold-ms 100

# Frontend gates
cd ..\frontend
npm.cmd run typecheck
npm.cmd run test
npm.cmd run build
npm.cmd audit --audit-level=moderate

# Provider syntax
cd ..
bash -n /mnt/d/codeSetting/NTC_/custom-skill-cobilot-codex/setup.sh
Get-ChildItem providers -Recurse -Filter *.ps1 | % {
  $tokens=$null; $errors=$null
  [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) { throw $errors[0].Message }
}
```

## 14. Rủi ro va cach xu ly

- Provider upstream can Docker image lon hoac GPU/NVIDIA key: tach install clone/config pass rieng, run pass hoac fail co log that; neu source loi thi sua upstream va push truoc khi cap nhat wrapper.
- Windows PowerShell coi stderr warning la error: wrapper phai check exit code thay vi fail vi warning.
- Hardware probe cham: chay background refresh va doc snapshot cache.
- Frontend render nhieu card bi khung: memoize, defer image preload, requestIdleCallback, skeleton real-data state, bo state update dong loat lon.
- Port conflict: backend validate port truoc run, UI hien canh bao do va cho user doi port.

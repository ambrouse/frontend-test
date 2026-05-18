# Plan: Add Shop Retail Provider (Real Lifecycle, Real Pass)

Date: 2026-05-13

## 1. Muc tieu

Them provider tu repo `https://github.com/mionm/Shop-Retail-Provider-mion-.git` vao AI Hub theo chuan runtime that:

- Install clone that tu GitHub vao `deploy/shop-retail-provider`.
- Run/health/logs/metrics/stop/delete chay that qua Hub API/frontend path.
- Neu loi thuoc upstream source thi fix upstream, push upstream, xoa deploy va retest tu clone sach.
- Khong pass theo dry-run, khong pass theo fallback data.

## 2. Scope

- 1 provider chinh: `shop-retail-provider`.
- Repo co cac service thanh phan (`chain_server`, `catalog_retriever`, `memory_retriever`, `guardrails`, `ui`), coi la 1 provider lifecycle trong AI Hub.

## 3. Skills can dung

- `plan-skill`: quan ly phase + gate pass.
- `backend-skill`: runtime orchestration, task/log/metrics/status API.
- `frontend-skill`: provider detail, action state, logs/metrics display.
- `testing-skill`: unit/integration/real lifecycle tests.
- `documentation-skill`: ghi doc ket qua va runbook.
- `logging-skill`: ghi execution log theo phase.

## 4. Nguyen tac bat buoc

- Khong dung `dryRun=true` de ket luan pass.
- Khong dung source clone local de gia lap install; bat buoc clone tu GitHub trong install.
- Bat buoc dung vong lap `clone upstream -> test upstream -> fix/push neu loi -> xoa clone -> reclone -> Hub install/run` cho den khi clean clone va Hub install deu pass.
- Neu install/run qua Hub fail, phai doc logs co timeout, quay lai upstream clone hoac wrapper de fix dung nguon loi, push upstream khi loi nam o provider repo, roi retest tu deploy sach.
- Moi command test dai phai co timeout va co buoc tail log/status rieng; khong duoc chay kieu tha troi terminal.
- Neu can key de test, lay tu Quick config cua provider; trong giai do dev co the copy gia tri tu `.env.local` vao config local ignored, khong commit secret.
- Moi phase phai theo thu tu: doc skill can thiet -> thuc hien -> test that -> cap nhat docs -> cap nhat logs -> gate pass.
- Khong sang phase tiep theo neu phase hien tai chua pass.
- Khong dung cho den khi dat pass that; chi duoc tam dung neu blocker khach quan (permission upstream, downtime external) va phai ghi bang chung.

## 5. Runtime mode policy

- Mac dinh mode trong Hub: local/self-host path (uu tien khong phu thuoc paid endpoint).
- Cloud/NVIDIA hosted mode chi la tuy chon opt-in, khong dat lam default.
- Secret (`NVIDIA_API_KEY`, `NGC_API_KEY`) chi nam trong file ignored (`.env`, `.env.local`), khong commit.

## 6. Phase plan

### Phase 0 - Baseline safety gate

Estimate: 20-40 phut.

Viec can lam:

1. Doc lai `backend-skill`, `frontend-skill`, `testing-skill`, `documentation-skill`, `logging-skill`.
2. Tao/cap nhat log task: `logs/tasks/shop-retail-provider-2026-05-13.md`.
3. Chup baseline: `git status --short`, backend test gate, frontend test gate.
4. Xac nhan `.gitignore` da chan `deploy/*` (tru `.gitkeep`) va `**/.env`.

Test that:

- Backend: lint + unit tests pass baseline.
- Frontend: typecheck + tests + build pass baseline.

Pass gate:

- Baseline pass, khong co secret staged.

### Phase 1 - Upstream audit va run source that

Estimate: 60-150 phut.

Viec can lam:

1. Clone `Shop-Retail-Provider-mion-` vao thu muc tam (`source-github-provider/shop-retail-provider`).
2. Doc README + compose files + scripts + env requirements + ports.
3. Chay install/start theo huong dan upstream o mode local/self-host.
4. Ghi lai health endpoint, startup time, log locations, metrics path, stop command.

Test that:

- `docker compose config` pass.
- `docker compose up -d` that, service len healthy that.
- Health endpoint tra 200 hoac trang thai readiness hop le.
- Moi lenh setup/run/health dung timeout ro rang va ghi log tail khi fail.

Pass gate:

- Co du contract that de viet wrapper Hub, khong doan.

### Phase 2 - Upstream remediation (neu can)

Estimate: 45-240 phut.

Viec can lam:

1. Neu upstream fail, patch trong clone tam.
2. Uu tien fix: env defaults, scripts one-command, health endpoint on dinh, port config khong hard-code nguy hiem.
3. Chay lai test that upstream.
4. Commit/push upstream repo.
5. Xoa clone tam, clone lai moi, verify lai tu commit moi.

Test that:

- Re-clone clean pass setup/run/stop.
- Khong can thao tac thu cong ngoai scripts da documented.
- Upstream commit da push phai duoc verify bang clone moi, khong dung working tree cu.

Pass gate:

- Upstream clone sach pass 100% cac buoc can thiet.

### Phase 3 - Hub provider wrapper implementation

Estimate: 90-180 phut.

Viec can lam:

1. Tao `providers/shop-retail-provider/aihub.provider.json`.
2. Tao scripts cho Windows/Linux:
   - `setup`, `run`, `health`, `collect-metrics`, `stop`, `delete`.
3. Dam bao install clone tu GitHub vao `deploy/shop-retail-provider`.
4. Runtime outputs chuan hoa:
   - `runtime/status.json`
   - `runtime/metrics.json`
   - `runtime/provider.pid`
   - `logs/runtime.log`
5. Config default trong `config/default.json` (branch, port, mode, install path).

Test that:

- Script syntax pass (`pwsh parser`, `bash -n`).
- Dry syntax chi de check script; khong dung de ket luan runtime pass.

Pass gate:

- Provider xuat hien trong Hub registry va co day du actions.

### Phase 4 - Backend/Frontend wiring + task contract

Estimate: 90-180 phut.

Viec can lam:

1. Dam bao backend tra task id ngay cho install/run/stop/delete.
2. Dam bao API status/logs/metrics/config doc duoc output that cua provider.
3. Frontend detail provider:
   - action loading states,
   - task progress,
   - logs live tail,
   - metrics cards,
   - warning states (port conflict, dependency missing).
4. Xoa fallback fake data tren trang provider khi backend online.

Test that:

- Backend integration tests cho lifecycle order + error mapping.
- Frontend tests cho action states + data source backend-first.

Pass gate:

- UI/API cung behavior that, khong fake running.

### Phase 5 - Real lifecycle loop den khi pass that

Estimate: 120-300 phut.

Viec can lam (lap vong den khi pass):

1. Xoa `deploy/shop-retail-provider`.
2. Install qua Hub.
3. Run qua Hub.
4. Verify health/logs/metrics/status that.
5. Stop qua Hub.
6. Delete qua Hub.
7. Install lai sau delete.

Bat buoc test that:

- Chay toi thieu 3 vong lien tiep pass khong can sua tay.
- Moi vong luu evidence: timestamp, task id, endpoint response, trang thai process/container.
- Neu fail: quay lai Phase 2 hoac 3/4, fix, roi retest tu dau.
- Moi action install/run/stop/delete trong test harness co timeout rieng va log polling/status polling trong luc cho.

Pass gate:

- 3 vong lien tiep pass install->run->health/logs/metrics->stop->delete->reinstall.

### Phase 6 - Latency/stability benchmarks

Estimate: 45-120 phut.

Viec can lam:

1. Do backend latency cho cac endpoint provider (warm path).
2. Do UI responsiveness tren Hub/detail khi logs update lien tuc.
3. Xac nhan request nong khong scan IO nang tren request path.

Test that:

- p95 warm < 100ms (muc tieu < 50ms) cho endpoint metadata/status.
- UI action response ngay (task id hien nhanh, nut khong treo).

Pass gate:

- Khong co regression latency nghiem trong.

### Phase 7 - Docs, logs, cleanup, push

Estimate: 45-90 phut.

Viec can lam:

1. Ghi doc tong ket: `docs/provider-shop-retail-integration-2026-05-13.md`.
2. Ghi log chi tiet command/test/evidence: `logs/tasks/shop-retail-provider-2026-05-13.md`.
3. Dọn artifact tam (`source-github-provider/...`, deploy tam neu yeu cau).
4. Chay final gate mot lan nua.
5. Commit + push.

Test that:

- `git status` chi con file mong muon.
- Khong secret, khong deploy clone duoc track.

Pass gate:

- Da push source + co bang chung test that day du.

## 7. Test matrix bat buoc

- Unit/Integration:
  - backend provider runtime tests
  - backend logs/metrics/status tests
  - frontend provider detail tests
- Real runtime:
  - clean install
  - run + health
  - logs stream + metrics update
  - stop + delete
  - reinstall from clean deploy
- Repeatability:
  - 3 vong lien tiep pass

## 8. Dieu kien ket thuc

Task chi ket thuc khi:

- Tat ca phase da pass gate.
- Vong lifecycle that da pass lien tiep theo test matrix.
- Docs + logs + evidence da ghi day du.
- Neu con blocker khach quan thi phai co muc blocker ro rang + bang chung da thu toi da.

## 9. Ket qua thuc hien 2026-05-13

- Status: complete.
- Upstream commit da push va verify clean clone: `6685c86`.
- Hub lifecycle da pass 3 vong lien tiep.
- Evidence chinh: loop 1 `task-d9dd1651079b`, loop 2 `task-e78688113ed4`, loop 3 `task-add88514b35a`.
- Metrics: port `13100`, 9 containers, `gatewayOk=true`.
- Docs: `docs/provider-shop-retail-integration-2026-05-13.md`.
- Log: `logs/tasks/shop-retail-provider-2026-05-13.md`.

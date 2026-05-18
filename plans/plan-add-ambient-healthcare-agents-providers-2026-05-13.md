# Plan: Add Ambient Healthcare Agents Providers (2 Providers, Real Lifecycle, Real Pass)

Date: 2026-05-13

## 1. Muc tieu

Tich hop repo `https://github.com/mionm/ambient-healthcare-agents-provider.git` vao AI Hub thanh 2 provider rieng:

- `ambient-provider-agent`
- `ambient-patient-agent`

Va dat pass that lifecycle cho ca 2:

- install -> run -> health/logs/metrics -> stop -> delete -> reinstall.
- Neu loi thuoc upstream thi fix upstream, push, clone lai sach, retest.
- Khong dung dry-run/fallback-only de ket luan pass.

## 2. Scope

- 1 repo, 2 provider wrappers trong AI Hub.
- Ton trong rang buoc upstream: khuyen nghi run tung notebook/tung stack theo lan (khong ep run dong thoi neu upstream khong ho tro).

## 3. Skills can dung

- `plan-skill`
- `backend-skill`
- `frontend-skill`
- `testing-skill`
- `documentation-skill`
- `logging-skill`

## 4. Nguyen tac bat buoc

- Moi phase: doc skill -> implement -> test that -> docs -> logs -> gate pass.
- Khong phase nao duoc bo qua.
- Khong dung task neu chua pass that (tru blocker khach quan co bang chung).
- Bat buoc dung vong lap `clone upstream -> test upstream -> fix/push neu loi -> xoa clone -> reclone -> Hub install/run` cho den khi clean clone va Hub install deu pass cho ca 2 provider.
- Neu install/run qua Hub fail, phai doc logs co timeout, quay lai upstream clone hoac wrapper de fix dung nguon loi, push upstream khi loi nam o provider repo, roi retest tu deploy sach.
- Moi command test dai phai co timeout va co buoc tail log/status rieng; khong duoc chay kieu tha troi terminal.
- Neu can key de test, lay tu Quick config cua provider; trong giai do dev co the copy gia tri tu `.env.local` vao config local ignored, khong commit secret.
- Secret/API keys/PII/PHI khong commit.

## 5. Runtime mode policy

- Mac dinh Hub mode: local/self-host path (uu tien khong buoc paid endpoints).
- Hosted endpoint mode chi la opt-in.
- Neu may khong du tai nguyen, UI phai canh bao ro tung provider thay vi fake success.

## 6. Phase plan

### Phase 0 - Baseline safety gate

Estimate: 20-45 phut.

Viec can lam:

1. Baseline backend/frontend gates.
2. Tao log file: `logs/tasks/ambient-healthcare-providers-2026-05-13.md`.
3. Kiem tra ignore rules cho deploy/env/runtime artifacts.
4. Chot naming conventions cho 2 provider IDs.

Test that:

- Baseline pass.

Pass gate:

- Moi truong san sang, khong secret staged.

### Phase 1 - Upstream audit + direct run cho 2 workflows

Estimate: 120-300 phut.

Viec can lam:

1. Clone vao `source-github-provider/ambient-healthcare-agents-provider`.
2. Doc README + architecture + quickstart + security notes.
3. Tach contract runtime cho 2 luong:
   - ambient provider agent
   - ambient patient agent
4. Chay setup that upstream.
5. Chay run that tung luong (tuan thu huong dan one-at-a-time neu can).
6. Ghi endpoint, health signal, logs location, metrics source cho moi luong.

Test that:

- `docker compose config` pass.
- Tung luong co startup that + health that.
- Moi lenh setup/run/health dung timeout ro rang va ghi log tail khi fail.

Pass gate:

- Co contract ro cho 2 wrappers rieng.

### Phase 2 - Upstream remediation + clean clone verify (neu can)

Estimate: 90-360 phut.

Viec can lam:

1. Fix upstream loi script/env/compose/health cho tung luong.
2. Dam bao mode switch ro rang, khong hard-code ports nguy hiem.
3. Dam bao docs warning bao mat (PII/PHI, key handling) ro rang.
4. Push upstream.
5. Xoa clone tam -> clone lai moi -> rerun setup + run/stop cho ca 2 luong.

Test that:

- Clean clone pass cho ca 2 luong.
- Upstream commit da push phai duoc verify bang clone moi, khong dung working tree cu.

Pass gate:

- Upstream commit moi da verify clean clone.

### Phase 3 - Tao 2 Hub wrappers

Estimate: 120-240 phut.

Viec can lam:

1. Tao:
   - `providers/ambient-provider-agent/aihub.provider.json`
   - `providers/ambient-patient-agent/aihub.provider.json`
2. Tao scripts Windows/Linux cho tung provider:
   - setup/run/health/collect-metrics/stop/delete.
3. Mapping install path:
   - `deploy/ambient-provider-agent`
   - `deploy/ambient-patient-agent`
4. Runtime outputs tieu chuan cho moi provider:
   - `runtime/status.json`
   - `runtime/metrics.json`
   - `runtime/provider.pid`
   - `logs/runtime.log`

Test that:

- Manifest validation pass cho ca 2.
- Script parser pass.

Pass gate:

- Hub discover duoc 2 provider rieng + actions day du.

### Phase 4 - Backend/Frontend wiring cho 2 providers

Estimate: 120-240 phut.

Viec can lam:

1. Backend lifecycle/task/status/logs/metrics/config support 2 provider IDs.
2. Frontend detail pages cho 2 provider co:
   - loading states,
   - task progress,
   - logs live tail,
   - metrics,
   - warning GPU/tool/dependency.
3. Dam bao backend online thi data hien that, khong fallback fake.

Test that:

- Backend integration tests cho 2 provider IDs.
- Frontend tests cho action-state + rendering data that.

Pass gate:

- UI/API dung behavior cho tung provider, khong nham state qua lai.

### Phase 5 - Real lifecycle loops den khi pass that cho ca 2

Estimate: 180-420 phut.

Viec can lam (lap lai den pass):

1. `ambient-provider-agent`:
   - clean deploy
   - install -> run -> verify health/logs/metrics -> stop -> delete -> reinstall
2. `ambient-patient-agent`:
   - clean deploy
   - install -> run -> verify health/logs/metrics -> stop -> delete -> reinstall
3. Test order scenario:
   - run provider A xong stop,
   - run provider B,
   - dam bao khong conflict resources khong duoc xu ly.

Bat buoc test that:

- Moi provider dat 3 vong lien tiep pass.
- Co evidence tung vong: task ids + responses + process/container states.
- Neu fail provider nao, quay lai Phase 2 hoac 3/4 cho provider do roi retest tu dau.
- Moi action install/run/stop/delete trong test harness co timeout rieng va log polling/status polling trong luc cho.

Pass gate:

- Ca 2 provider deu dat 3/3 vong pass lien tiep.

### Phase 6 - Latency/stability + resource safety

Estimate: 60-150 phut.

Viec can lam:

1. Benchmark warm endpoints cho moi provider (status/logs/metrics).
2. Kiem tra UI responsiveness khi switch giua 2 provider lien tuc.
3. Kiem tra warning resources (GPU/RAM/disk) hien dung va khong fake pass.

Test that:

- p95 warm endpoint < 100ms (muc tieu < 50ms).
- UI buttons/task status khong bi treo.

Pass gate:

- Khong co regression hieu nang nghiem trong.

### Phase 7 - Security/docs/logs/cleanup/push

Estimate: 60-120 phut.

Viec can lam:

1. Ghi docs: `docs/provider-ambient-healthcare-integration-2026-05-13.md`.
2. Ghi log chi tiet phase: `logs/tasks/ambient-healthcare-providers-2026-05-13.md`.
3. Ghi luu y compliance data nhay cam (PII/PHI) va cach an toan logs.
4. Don source tam/deploy rac theo policy.
5. Final gate + commit + push.

Test that:

- Secret scan pass.
- Khong env/deploy source bi stage.

Pass gate:

- Push thanh cong, evidence day du cho ca 2 provider.

## 7. Test matrix bat buoc

- Backend integration tests cho 2 provider IDs.
- Frontend detail/action tests cho 2 providers.
- Real lifecycle loops:
  - ambient-provider-agent: 3 vong pass lien tiep.
  - ambient-patient-agent: 3 vong pass lien tiep.
- Scenario test chuyen doi qua lai 2 providers.
- Slow startup tolerance test.

## 8. Dieu kien ket thuc

Chi ket thuc khi:

- 2 providers deu pass gate va pass loops that.
- Docs/logs co evidence day du.
- Neu co blocker khach quan, ghi ro tung provider bi anh huong va muc da xu ly.

## 9. Ket qua thuc hien 2026-05-13

- Status: complete.
- Upstream commit da push va verify clean clone: `f4c553e`.
- `ambient-provider-agent` da pass 3 vong Hub lifecycle lien tiep.
- `ambient-patient-agent` da pass 3 vong Hub lifecycle lien tiep.
- Ambient Provider evidence: loop 2 `task-fe340dd72a6f`, loop 3 `task-65def5456070`, port `13473`, API port `13400`, 2 containers, `gatewayOk=true`.
- Ambient Patient evidence: loop 1 `task-80d45e739a9b`, loop 2 `task-0abc77b6f686`, loop 3 `task-f4715d07bc2e`, port `13540`, app `13581`, pipeline `13560`, 2 containers, `gatewayOk=true`.
- Docs: `docs/provider-ambient-healthcare-integration-2026-05-13.md`.
- Log: `logs/tasks/ambient-healthcare-providers-2026-05-13.md`.

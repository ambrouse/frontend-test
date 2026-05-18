# Plan: Add AI Virtual Assistant Provider (Real Lifecycle, Real Pass)

Date: 2026-05-13

## 1. Muc tieu

Them provider tu repo `https://github.com/mionm/ai-virtual-assistant-provider.git` vao AI Hub voi tieu chuan run that:

- Install clone that vao `deploy/ai-virtual-assistant-provider`.
- Run/health/logs/metrics/stop/delete qua Hub API/frontend that.
- Neu loi o upstream thi fix upstream, push, clone lai sach, retest.
- Khong dung dry-run/fallback-only de ket luan pass.

Luu y quan trong:

- Repo co thong bao deprecation (Apr 2026). Van tich hop duoc neu runtime con hoat dong, nhung plan phai ghi ro rui ro maintainability.

## 2. Scope

- 1 provider: `ai-virtual-assistant-provider`.
- Co nhieu thanh phan compose (agent, analytics, retrievers, db, ui). Hub quan ly nhu mot provider lifecycle.

## 3. Skills can dung

- `plan-skill`
- `backend-skill`
- `frontend-skill`
- `testing-skill`
- `documentation-skill`
- `logging-skill`

## 4. Nguyen tac bat buoc

- Moi phase: doc skill -> implement -> test that -> docs -> logs -> gate pass.
- Khong qua phase neu chua pass.
- Khong dung task cho den khi pass that (tru blocker khach quan co bang chung).
- Bat buoc dung vong lap `clone upstream -> test upstream -> fix/push neu loi -> xoa clone -> reclone -> Hub install/run` cho den khi clean clone va Hub install deu pass.
- Neu install/run qua Hub fail, phai doc logs co timeout, quay lai upstream clone hoac wrapper de fix dung nguon loi, push upstream khi loi nam o provider repo, roi retest tu deploy sach.
- Moi command test dai phai co timeout va co buoc tail log/status rieng; khong duoc chay kieu tha troi terminal.
- Neu can key de test, lay tu Quick config cua provider; trong giai do dev co the copy gia tri tu `.env.local` vao config local ignored, khong commit secret.
- Secret API key khong commit.

## 5. Runtime mode policy

- Mac dinh Hub mode: local/self-host path (uu tien khong bat buoc paid endpoint).
- NVIDIA hosted endpoint chi la opt-in.
- Neu mode local can tai nguyen lon, provider phai hien warning ro, khong duoc fake success.

## 6. Phase plan

### Phase 0 - Baseline safety gate

Estimate: 20-40 phut.

Viec can lam:

1. Chup baseline test backend/frontend.
2. Tao log file: `logs/tasks/ai-virtual-assistant-provider-2026-05-13.md`.
3. Kiem tra `.gitignore` cho `deploy/*`, `**/.env`, runtime artifacts.

Test that:

- Baseline gates pass.

Pass gate:

- Moi truong san sang, khong secret staged.

### Phase 1 - Upstream audit + direct run

Estimate: 90-240 phut.

Viec can lam:

1. Clone vao `source-github-provider/ai-virtual-assistant-provider`.
2. Doc README/deploy docs/compose/scripts (`setup.sh`, `start.sh`, `run.sh`, `stop.sh`).
3. Xac dinh mode:
   - local/self-host
   - hosted endpoints
4. Chay setup that + compose up that.
5. Ghi endpoint, ports, health signal, logs, metrics source.

Test that:

- `docker compose config` pass.
- Stack len thanh cong.
- Co endpoint UI/API that.
- Moi lenh setup/run/health dung timeout ro rang va ghi log tail khi fail.

Pass gate:

- Co contract ro rang cho Hub wrapper.

### Phase 2 - Upstream remediation + clean clone verify (neu can)

Estimate: 60-300 phut.

Viec can lam:

1. Fix upstream loi env/script/compose/health/port behavior.
2. Neu co warning deprecation, bo sung docs warning trong upstream (neu can) ma khong pha startup path.
3. Chay lai full setup-run-stop that.
4. Push upstream.
5. Xoa clone tam, clone lai moi, rerun full flow.

Test that:

- Clean clone pass y chang.
- Khong can sua tay ngoai script/documented command.
- Upstream commit da push phai duoc verify bang clone moi, khong dung working tree cu.

Pass gate:

- Upstream commit moi da verify trong clone sach.

### Phase 3 - Hub wrapper implementation

Estimate: 90-180 phut.

Viec can lam:

1. Tao `providers/ai-virtual-assistant-provider/aihub.provider.json`.
2. Tao config + scripts Windows/Linux:
   - setup/run/health/collect-metrics/stop/delete.
3. Install action clone that vao `deploy/ai-virtual-assistant-provider`.
4. Chuan hoa runtime outputs:
   - `runtime/status.json`
   - `runtime/metrics.json`
   - `runtime/provider.pid`
   - `logs/runtime.log`

Test that:

- Script syntax pass + manifest validation pass.

Pass gate:

- Hub nhan provider + action map dung.

### Phase 4 - Backend/Frontend wiring

Estimate: 90-180 phut.

Viec can lam:

1. Backend lifecycle APIs return task id ngay.
2. Backend status/logs/metrics/config map dung output provider.
3. Frontend detail:
   - action loading states,
   - task progress,
   - warning modes,
   - logs live tail,
   - metrics cards.
4. Khi backend online thi khong dung fallback fake values.

Test that:

- Backend integration tests cho lifecycle/error path.
- Frontend tests cho provider detail behavior.

Pass gate:

- UI phan anh that state, khong fake running.

### Phase 5 - Real lifecycle loop den khi pass that

Estimate: 150-360 phut.

Viec can lam (lap lai den pass):

1. Xoa `deploy/ai-virtual-assistant-provider`.
2. Install qua Hub.
3. Run qua Hub.
4. Verify health/logs/metrics/status that.
5. Stop qua Hub.
6. Delete qua Hub.
7. Install lai tu clean deploy.

Bat buoc test that:

- 3 vong lien tiep pass install->run->health/logs/metrics->stop->delete->reinstall.
- Moi vong luu evidence: task id, endpoint response, process/container state.
- Neu fail, quay lai Phase 2 hoac 3/4 va retest tu dau.
- Moi action install/run/stop/delete trong test harness co timeout rieng va log polling/status polling trong luc cho.

Pass gate:

- Dat 3/3 vong pass lien tiep.

### Phase 6 - Latency + resilience

Estimate: 45-120 phut.

Viec can lam:

1. Benchmark warm endpoints status/logs/metrics.
2. Verify UI responsiveness khi log stream nhieu.
3. Test service startup cham de xac nhan task heartbeat khong timeout cung.

Test that:

- p95 warm endpoint < 100ms (muc tieu < 50ms).
- Action response nhanh, khong treo nut.

Pass gate:

- Khong co regression nghiem trong.

### Phase 7 - Docs/logs/cleanup/push

Estimate: 45-90 phut.

Viec can lam:

1. Doc ket qua: `docs/provider-ai-virtual-assistant-integration-2026-05-13.md`.
2. Log chi tiet: `logs/tasks/ai-virtual-assistant-provider-2026-05-13.md`.
3. Ghi ro deprecation impact + recommendation theo doi upstream.
4. Don source tam/deploy rac theo policy.
5. Final gate + commit + push.

Test that:

- Khong secret/deploy source bi stage.

Pass gate:

- Push xong, evidence day du.

## 7. Test matrix bat buoc

- Backend integration tests (lifecycle/status/logs/metrics).
- Frontend provider detail tests (loading/error/success).
- Real lifecycle loops (3 vong lien tiep pass).
- Slow startup resilience test.

## 8. Dieu kien ket thuc

Chi ket thuc khi:

- Tat ca phase pass gate.
- Lifecycle pass that lien tiep.
- Docs/logs co evidence day du.
- Neu bi blocker khach quan, ghi ro blocker + tac dong + bang chung da thu toi da.

## 9. Ket qua thuc hien 2026-05-13

- Status: complete.
- Upstream commit da push va verify clean clone: `b6acc4f`.
- Hub lifecycle da pass 3 vong lien tiep.
- Evidence chinh: loop 1 `task-d953f856e135`, loop 2 `task-c5f947401a4b`, loop 3 `task-f32ae624146b`.
- Metrics: frontend port `13301`, API port `13300`, 13 containers, `gatewayOk=true`.
- Docs: `docs/provider-ai-virtual-assistant-integration-2026-05-13.md`.
- Log: `logs/tasks/ai-virtual-assistant-provider-2026-05-13.md`.

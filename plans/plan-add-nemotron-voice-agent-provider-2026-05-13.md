# Plan: Add Nemotron Voice Agent Provider (Real Lifecycle, Real Pass)

Date: 2026-05-13

## 1. Muc tieu

Them provider tu repo `https://github.com/mionm/nemotron-voice-agent-provider.git` vao AI Hub va dat pass that lifecycle:

- Install clone that tu GitHub vao `deploy/nemotron-voice-agent-provider`.
- Run that, health that, logs/metrics that, stop/delete that tu Hub.
- Neu upstream loi thi patch upstream -> push -> re-clone -> retest.
- Khong dung dry-run/fallback de ket luan pass.

## 2. Scope

- 1 provider: `nemotron-voice-agent-provider`.
- Co stack voice real-time (WebRTC, ASR/TTS, LLM). Hub chi quan ly lifecycle provider va observability; khong bo qua test endpoint that.

## 3. Skills can dung

- `plan-skill`
- `backend-skill`
- `frontend-skill`
- `testing-skill`
- `documentation-skill`
- `logging-skill`

## 4. Nguyen tac bat buoc

- Moi phase theo dung trinh tu: doc skill -> implement -> test -> docs -> logs -> pass gate.
- Khong qua phase neu gate chua pass.
- Khong dung cho den khi pass that (tru blocker khach quan co bang chung).
- Bat buoc dung vong lap `clone upstream -> test upstream -> fix/push neu loi -> xoa clone -> reclone -> Hub install/run` cho den khi clean clone va Hub install deu pass.
- Neu install/run qua Hub fail, phai doc logs co timeout, quay lai upstream clone hoac wrapper de fix dung nguon loi, push upstream khi loi nam o provider repo, roi retest tu deploy sach.
- Moi command test dai phai co timeout va co buoc tail log/status rieng; khong duoc chay kieu tha troi terminal.
- Neu can key de test, lay tu Quick config cua provider; trong giai do dev co the copy gia tri tu `.env.local` vao config local ignored, khong commit secret.
- Secret (`NVIDIA_API_KEY`, `NGC_API_KEY`, TURN secret neu co) khong commit.

## 5. Runtime mode policy

- Mac dinh mode trong Hub: local/self-host path.
- Cloud-hosted mode la tuy chon opt-in, khong default.
- Neu may khong du GPU cho self-host, provider phai hien warning ro + cho phep user chon mode khac (khong fake success).

## 6. Phase plan

### Phase 0 - Baseline + prerequisites gate

Estimate: 20-40 phut.

Viec can lam:

1. Snapshot baseline test backend/frontend.
2. Confirm toolchain: Docker + NVIDIA runtime + network ports + browser mic policy note.
3. Tao log task: `logs/tasks/nemotron-voice-agent-provider-2026-05-13.md`.

Test that:

- Baseline local gates pass.
- Script parser pass cho shell/PowerShell wrappers.

Pass gate:

- Moi truong co the bat dau integration that.

### Phase 1 - Upstream audit + direct run

Estimate: 90-210 phut.

Viec can lam:

1. Clone upstream vao `source-github-provider/nemotron-voice-agent-provider`.
2. Doc `README`, docs, `.env` config, compose files, script `setup/start/run/stop`.
3. Chay setup that theo upstream.
4. Chay stack that (uu tien mode local/self-host; neu khong du tai nguyen thi ghi ro fallback mode).
5. Ghi endpoint/ports:
   - UI
   - health API (neu co)
   - logs va metrics source.

Test that:

- `docker compose config` pass.
- `docker compose up -d` len thanh cong.
- Co endpoint live va traffic that.
- Moi lenh setup/run/health dung timeout ro rang va ghi log tail khi fail.

Pass gate:

- Co lifecycle contract that cho Hub wrapper.

### Phase 2 - Upstream remediation (neu can)

Estimate: 60-240 phut.

Viec can lam:

1. Fix upstream loi startup/stop, env defaults, compose profile, health script, mode switch.
2. Them script one-command neu thieu va output status co cau truc.
3. Test lai that.
4. Push upstream.
5. Xoa clone tam -> clone lai -> rerun full setup/run/stop.

Test that:

- Clean clone pass y chang, khong phu thuoc file local cu.
- Upstream commit da push phai duoc verify bang clone moi, khong dung working tree cu.

Pass gate:

- Upstream commit moi da duoc verify tren clone sach.

### Phase 3 - Hub provider wrapper va metadata

Estimate: 90-180 phut.

Viec can lam:

1. Tao `providers/nemotron-voice-agent-provider/aihub.provider.json`.
2. Add config mode + dependency metadata:
   - OS support
   - architecture
   - GPU requirement
   - required tools
3. Add scripts Windows/Linux:
   - setup/run/health/collect-metrics/stop/delete.
4. Chuan hoa runtime outputs (`status.json`, `metrics.json`, `provider.pid`, `runtime.log`).

Test that:

- Wrapper syntax pass.
- Manifest validation pass.

Pass gate:

- Hub nhan provider va action map dung command.

### Phase 4 - Backend/Frontend wiring

Estimate: 90-180 phut.

Viec can lam:

1. Ensure backend task contract cho lifecycle async.
2. Ensure status/logs/metrics API map dung output cua provider.
3. Frontend detail:
   - loading states,
   - task progress,
   - warning for missing GPU/tool,
   - logs live tail,
   - metrics refresh.
4. Khong hien fake running khi service that fail.

Test that:

- Backend integration tests: lifecycle + error mapping.
- Frontend tests: action-state + backend-first data.

Pass gate:

- UI phan anh dung trang thai that.

### Phase 5 - Real lifecycle loop den khi pass that

Estimate: 120-360 phut.

Viec can lam (lap lai den pass):

1. Xoa `deploy/nemotron-voice-agent-provider`.
2. Install qua Hub.
3. Run qua Hub.
4. Verify:
   - health endpoint,
   - logs streaming,
   - metrics update,
   - service process/container.
5. Stop qua Hub.
6. Delete qua Hub.
7. Install lai sau delete.

Bat buoc test that:

- 3 vong lien tiep pass tren clean deploy.
- Moi vong co evidence: task ids + response + logs timestamp.
- 1 vong test scenario startup cham (long startup) de xac nhan khong timeout cung.
- Moi action install/run/stop/delete trong test harness co timeout rieng va log polling/status polling trong luc cho.

Pass gate:

- Dat 3/3 vong pass, khong can hand-fix giua vong.

### Phase 6 - Voice-path sanity + latency

Estimate: 60-150 phut.

Viec can lam:

1. Sanity test luong voice path (neu hardware/network cho phep): ket noi UI va tao 1 session ngan.
2. Benchmark endpoint nong (status/logs/metrics) warm cache.
3. Verify UI khong khung khi logs update lien tuc.

Test that:

- p95 warm endpoint < 100ms (muc tieu < 50ms).
- Action response nhanh, nut khong bi treo.

Pass gate:

- Khong co regression hieu nang nghiem trong.

### Phase 7 - Docs/logs/cleanup/push

Estimate: 45-90 phut.

Viec can lam:

1. Ghi docs: `docs/provider-nemotron-voice-agent-integration-2026-05-13.md`.
2. Ghi log phase + evidence: `logs/tasks/nemotron-voice-agent-provider-2026-05-13.md`.
3. Don source tam/deploy rac theo policy.
4. Final test gate + commit + push.

Test that:

- Khong secret staged.
- Khong clone source deploy bi track.

Pass gate:

- Push thanh cong, evidence day du.

## 7. Test matrix bat buoc

- Backend runtime integration tests.
- Frontend provider detail behavior tests.
- Real lifecycle tests: install/run/health/logs/metrics/stop/delete/reinstall.
- Repeatability: 3 vong lien tiep pass.
- Slow-start tolerance test.

## 8. Dieu kien ket thuc

Chi ket thuc khi:

- Tat ca phase pass gate.
- Lifecycle that pass lien tiep.
- Docs/logs day du.
- Neu bi blocker khach quan, co bang chung va ghi ro muc da thu.

## 9. Ket qua thuc hien 2026-05-13

- Status: complete.
- Upstream commit da push va verify clean clone: `ad9d920`.
- Hub lifecycle da pass 3 vong lien tiep.
- Evidence chinh: loop 1 `task-448e00b3fada`, loop 2 `task-49b057389716`, loop 3 `task-7cb4914c486c`.
- Metrics: port `13200`, 2 containers, `gatewayOk=true`.
- Docs: `docs/provider-nemotron-voice-agent-integration-2026-05-13.md`.
- Log: `logs/tasks/nemotron-voice-agent-provider-2026-05-13.md`.

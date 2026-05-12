# Plan: Real Provider Stability and Log UI - 2026-05-12

## Muc tieu
- Doc lai README, docs, logs va source de nam day du ngu canh AI Hub.
- Kiem chung bang lifecycle that tu Hub/frontend install path, khong dung smoke/dry-run, cho 3 provider:
  - `pdf-to-podcast`
  - `agentic-commerce-blueprint`
  - `multi-agent-intelligent-warehouse`
- Neu loi nam trong upstream provider, sua va push len GitHub provider, sau do clone lai tu GitHub de retest.
- Chinh lai trai nghiem log provider: tab tien trinh ngan gon rieng, tab log chi tiet rieng; tranh chen/de/du thua.
- Don artifact runtime/test rac.
- Viet blog/doc/log tong ket, push source goc len GitHub.
- Xoa source hien tai, clone moi tu GitHub, setup lai bang key local, va kiem chung clean clone path.

## Skill can dung
- `plan-skill`: lap file plan va di theo phase.
- `backend-skill`: khi sua backend lifecycle/log/task API.
- `frontend-skill`: khi sua UI log tabs va frontend lifecycle view.
- `documentation-skill`: ghi blog/doc tong ket trong `docs/`.
- `logging-skill`: ghi task log ngan gon trong `logs/`.
- `push-code-skill`: test, commit va push source goc/provider neu can.

## Phase 1 - Context audit (15-25 phut)
- Doc README, backend/frontend docs, provider docs, task logs gan nhat.
- Doc provider manifests/scripts cho 3 provider.
- Doc backend provider runtime/task store/API va frontend detail/log UI.
- Ket qua mong doi: nam ro lifecycle path thuc te va cac diem co nguy co fallback/dry-run.

## Phase 2 - Plan + code audit fixes (30-60 phut)
- Kiem tra co che log provider hien tai.
- Tach UI thanh tab tien trinh/log chi tiet neu can.
- Dam bao log source/level/cursor khong tao cam giac bi chen/de.
- Bo sung test frontend/backend phu hop voi thay doi.

## Phase 3 - Local setup and real lifecycle validation (60-180 phut)
- Chay setup thuc te cua repo: backend venv, frontend install, seed providers.
- Start backend va frontend local.
- Goi lifecycle qua Hub API/frontend-equivalent path, khong dat `dryRun`.
- Kiem chung install/run/status/health/logs/metrics/stop/delete cho tung provider.
- Kiem tra deploy clone den tu GitHub, khong dung source co san lam fallback.

## Phase 4 - Upstream provider remediation (neu co loi) (30-180 phut)
- Neu loi nam trong upstream provider, sua trong clone provider tu `deploy/`.
- Chay test/lifecycle provider truc tiep.
- Commit/push upstream provider GitHub.
- Xoa deploy va retest Hub install de chac chan lan sau clone GitHub da on.

## Phase 5 - Verification, cleanup, docs/log/blog (30-90 phut)
- Chay backend checks, frontend typecheck/test/build, provider validation, script syntax.
- Don `deploy/`, runtime/log tam, task history va cac artifact test khong can commit.
- Viet blog/doc trong `docs/` va log task trong `logs/`.
- Cap nhat README neu can de phan anh 3 provider hien tai.

## Phase 6 - Push and clean clone verification (60-180 phut)
- Commit source goc voi message co thoi gian ro rang.
- Push source goc len GitHub.
- Luu lai cac key local tu env/gitignored files ma khong in ra log.
- Xoa source hien tai theo yeu cau, clone moi tu GitHub vao cung vi tri.
- Chay setup clean clone, start backend/frontend, va lap lai real lifecycle cho 3 provider.
- Ket thuc chi khi 3 provider/hub pass hoan toan hoac co blocker khach quan khong the vuot qua tren may hien tai.

## Tieu chi pass
- `pdf-to-podcast`, `agentic-commerce-blueprint`, `multi-agent-intelligent-warehouse` install/run/health/stop/delete thanh cong qua Hub lifecycle that.
- Khong co `AIHUB_DRY_RUN=1`, khong gui request `dryRun: true`, khong dung fallback source local.
- UI provider detail co tab tien trinh va tab log chi tiet ro rang.
- Tests/build/checks pass.
- Repo source goc da duoc push.
- Clean clone tu GitHub setup va lifecycle pass.

## Ket qua thuc thi tam thoi
- Context/docs/log/source audit: done.
- UI log tabs: done, co test `frontend/tests/projectDetailLogs.test.tsx`.
- Real lifecycle:
  - `pdf-to-podcast`: pass tu GitHub commit `4e9ffb6`.
  - `agentic-commerce-blueprint`: pass tu GitHub commit `426454f`.
  - `multi-agent-intelligent-warehouse`: pass tu GitHub commit `4729d72`.
- Upstream provider:
  - `PhuongHo03/pdf-to-podcast`: da push `3c7e7af` va `4e9ffb6`.
- Checks:
  - Backend lint/format/mypy/manifest/secret scan/pytest coverage/dry-run/latency/OpenAPI: pass.
  - Frontend typecheck/test/build: pass.
  - Provider PowerShell parser va Git Bash syntax: pass.
- Cleanup:
  - `deploy/` con `.gitkeep`.
  - Provider runtime/log folders con `.gitkeep`.
  - Build/cache/test artifacts da don.
- Con lai:
  - Don artifact lan cuoi.
  - Push log/doc ket qua clean clone.

## Ket qua clean clone
- Source local da duoc xoa va clone lai tu `https://github.com/ambrouse/frontend-test.git`.
- Commit clean clone duoc test: `37ea4f7`.
- `.env.local` da restore tu backup local ignored, khong in key.
- `setup.ps1` pass tren clean clone.
- Backend/frontend pass health tren clean clone.
- Lifecycle that tren clean clone:
  - `pdf-to-podcast`: pass tu `4e9ffb6`.
  - `agentic-commerce-blueprint`: pass tu `426454f`.
  - `multi-agent-intelligent-warehouse`: pass tu `4729d72`.

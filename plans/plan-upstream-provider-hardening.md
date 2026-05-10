# Upstream Provider Hardening Plan

Date: 2026-05-11

## 1. Muc tieu

Sua tan goc hai provider GitHub, khong chi sua wrapper trong `deploy/`. Moi provider phai duoc clone ve `source-github-provider/`, audit loi, patch upstream, test bang clone sach, push upstream, xoa folder tam, sau do test lai qua Hub backend/frontend. Hub va setup tong phai ro dependency, OS/framework/architecture va co prompt cai dat tren may moi.

Provider can harden:

- `https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-`
- `https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia`

## 2. Skill can dung

- `backend-skill`: provider runtime, schema metadata, setup prerequisite checker.
- `frontend-skill`: hien thi dependency/provider environment theo tung provider.
- `testing-skill`: clone sach, Docker compose, lifecycle, latency, CI.
- `documentation-skill`: README, provider docs, setup docs.
- `logging-skill`: phase log vao `logs/tasks/upstream-provider-hardening.md`.

## 3. Nguyen tac pass bat buoc

- Khong coi patch trong `deploy/` la fix tan goc. Moi loi source phai patch va push vao upstream provider neu thuoc provider.
- Source tam chi nam trong `source-github-provider/`; sau khi pass va push xong phai xoa folder nay.
- Test Hub phai clone tu GitHub vao `deploy/`, khong map/chep tu `source-github-provider/`.
- Provider co the khong can GPU local neu API mode ho tro; neu can GPU/OS/arch/toolchain thi phai khai bao ro trong provider config de frontend hien.
- Neu thieu phan cung thi frontend chi warning, user van duoc bam. Neu thieu toolchain bat buoc thi setup/run phai bao loi ro.
- Khong commit secret NVIDIA key. Chi ghi vao `.env.local` hoac `.env` ignored.

## 4. Phase 0 - Audit baseline va lap bang loi

Thoi gian du kien: 30-45 phut.

Buoc:

1. Kiem tra worktree, Docker, Git remote.
2. Tao `source-github-provider/` sach.
3. Clone 2 upstream repo vao folder nay.
4. Doc Dockerfile, compose, README, env example, health endpoint, scripts.
5. Tong hop loi da thay:
   - build/runtime loi.
   - port hard-code.
   - missing dependency.
   - OS/arch assumption.
   - missing setup/doc.
   - metadata chua du de frontend hien.

Tieu chi pass:

- Co bang loi trong log task.
- Khong co deploy clone dang chay/bi map sai.

## 5. Phase 1 - Patch upstream provider source

Thoi gian du kien: 2-4 gio.

Buoc:

1. Agentic Commerce:
   - Dam bao Dockerfile dung Node/pnpm reproducible.
   - Dam bao network external duoc tao truoc khi compose up tren Windows/Linux.
   - Dam bao `.env.example` va README noi ro NVIDIA API key, Docker, ports, API mode/local NIM mode.
   - Dam bao run scripts hoac compose default khong auto doi port ngoai config.
2. Warehouse:
   - Dam bao local NIM la opt-in profile, default API mode khong keo GPU NIM.
   - Dam bao host port doc tu env, khong hard-code `8001` ngoai container internal.
   - Dam bao `.env.example` du cac host port, NIM URL, model, timeout.
   - Dam bao README/setup noi ro Docker, Node, Python, arch/OS.
3. Commit va push tung provider upstream.

Tieu chi pass:

- Moi upstream repo sach, co commit moi neu co patch.
- `docker compose config` pass.
- Build/run that pass tren may hien tai trong API mode.

## 6. Phase 2 - Hub provider metadata va frontend dependency UI

Thoi gian du kien: 60-90 phut.

Buoc:

1. Mo rong schema provider config de co `environment`:
   - `supportedOs`
   - `architectures`
   - `requiredTools`
   - `runtimeModes`
   - `frameworks`
   - `setupNotes`
2. Cap nhat 2 `aihub.provider.json` voi thong tin OS/toolchain/framework that.
3. Backend enrich provider bang machine capability:
   - OS hien tai.
   - arch hien tai.
   - tool availability: git, docker, docker compose, node, npm, python.
4. Frontend detail page them panel dependency/machine readiness, dung container co san va ca nhan hoa theo tung provider.
5. UI phai hien warning neu thieu tool/OS/arch, nhung khong khoa nut run neu user force.

Tieu chi pass:

- Provider detail hien du dependency va trang thai may.
- Typecheck/build frontend pass.
- Provider manifest validation pass.

## 7. Phase 3 - Setup tong tren may moi

Thoi gian du kien: 90-150 phut.

Buoc:

1. Nang `setup.ps1`:
   - detect Python, Node/npm, Git, Docker.
   - neu thieu thi hoi y/n truoc khi cai bang winget neu co.
   - neu can thao tac tay thi in huong dan va cho user tiep tuc sau khi cai.
   - tao `.venv`, install backend, `npm ci`, seed provider.
2. Nang `setup.sh`:
   - detect python3.11+, node/npm, git, docker.
   - hoi y/n truoc khi cai bang apt/dnf/pacman/brew neu co.
   - neu khong co package manager thi in lenh tay.
3. Khong chay lenh destructive/cai dat khong hoi.

Tieu chi pass:

- Syntax PowerShell/Bash pass.
- Setup co the chay tren may da co toolchain ma khong can thao tac them.
- Doc ghi ro tool nao setup co the tu cai, tool nao can user cai tay.

## 8. Phase 4 - Test real Hub lifecycle tu clone GitHub

Thoi gian du kien: 2-4 gio.

Buoc:

1. Xoa `deploy/{provider}`.
2. Install qua backend API/Frontend path, xac nhan clone tu GitHub.
3. Run, health ping, logs, metrics/status.
4. Stop, start lai, delete.
5. Install lai sau delete.
6. Neu loi, quay lai Phase 1: clone/fix upstream trong `source-github-provider`, push, xoa deploy, test lai.

Tieu chi pass:

- Khong fallback/mock pass tam.
- Ca 2 provider health `200`, logs doc duoc, stop/start/delete pass.
- `deploy/` sach sau final cleanup.

## 9. Phase 5 - CI/CD, docs, log, cleanup, push

Thoi gian du kien: 60-90 phut.

Buoc:

1. CI:
   - backend gates, latency, provider dry-run.
   - frontend typecheck/test/build.
   - setup script syntax.
2. README thiet ke lai:
   - project overview.
   - quick start Windows/Linux.
   - provider lifecycle.
   - dependency matrix.
   - troubleshooting.
3. Cap nhat docs:
   - backend API.
   - provider contract.
   - upstream provider fixes.
4. Ghi log chi tiet vao `logs/tasks/upstream-provider-hardening.md`.
5. Xoa `source-github-provider/`.
6. Secret scan.
7. Commit va push repo tong.

Tieu chi pass:

- Source temp bi xoa.
- Worktree sach sau push, ngoai ignored runtime cache.
- Final report co commit hash upstream va hub, test commands, latency/lifecycle numbers.

## 10. Ket qua thuc thi

- Phase 0-5 hoan thanh ngay 2026-05-11.
- Agentic Commerce upstream da push den `f90df7a`.
- Warehouse upstream da push den `22e42b4`.
- Real Hub lifecycle pass cho ca hai provider: install clone tu GitHub, assert commit, compose config, run, logs, metrics, stop, delete.
- `source-github-provider/` da xoa; `deploy/` sach chi con `.gitkeep`.
- Local CI pass: backend lint/format/mypy/pytest, provider validation/dry-run/latency/secret scan, frontend typecheck/test/build, PowerShell/Bash syntax.

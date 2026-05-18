# Plan: Fresh Clone Validation and Seven-Provider Cleanup

## Mục tiêu

Đảm bảo dự án khi clone về một máy mới vẫn có thể setup và chạy bình thường, kể cả máy gần như chưa có gì ngoài hệ điều hành, đồng thời xoá toàn bộ provider không còn dùng và chỉ giữ lại 7 provider sau:

1. `agentic-commerce-blueprint`
2. `ai-virtual-assistant-provider`
3. `aiq`
4. `nemotron-voice-agent-provider`
5. `shop-retail-provider`
6. `multi-agent-intelligent-warehouse`
7. `pdf-to-podcast`

## Phạm vi thay đổi dự kiến

- Xoá các thư mục provider ngoài danh sách 7 provider trong `providers/`.
- Xoá mọi reference lifecycle/dispatch/seed/mock/cache liên quan đến provider bị xoá.
- Đảm bảo backend registry chỉ trả đúng 7 provider.
- Đảm bảo frontend Hub không còn hiển thị provider đã xoá.
- Kiểm tra setup trên môi trường sạch theo luồng clone mới.
- Cập nhật documentation và logging theo đúng quy trình dự án.
- Push code theo `push-code-skill` sau khi test pass.

## Skill cần dùng

- `backend-skill`: khi chỉnh backend provider registry, seed, runtime, API trả danh sách provider.
- `frontend-skill`: khi kiểm tra frontend Hub hiển thị đúng 7 provider và không fallback mock sai.
- `testing-skill`: bắt buộc cho từng phase; chạy test phù hợp sau mỗi thay đổi.
- `documentation-skill`: ghi lại kết quả fresh clone validation và danh sách provider chính thức.
- `logging-skill`: ghi task log quá trình cleanup/test.
- `security-skill`: kiểm tra không commit secrets, `.env`, runtime config, API key, provider deploy artifacts.
- `push-code-skill`: dùng khi commit/push cuối cùng.

## Phase 1 — Audit provider sources và registry hiện tại

**Thời gian dự kiến:** 30-45 phút

### Việc cần làm

1. Liệt kê toàn bộ provider manifests hiện tại bằng `providers/*/aihub.provider.json`.
2. Xác định chính xác 7 provider cần giữ.
3. Tìm toàn bộ reference đến provider ngoài danh sách trong:
   - `providers/`
   - `backend/`
   - `frontend/src/`
   - setup scripts
   - shared lifecycle scripts
   - tests
   - docs/plans/logs nếu đang ảnh hưởng runtime.
4. Kiểm tra backend API `/api/providers` hiện trả những provider nào.
5. Kiểm tra frontend Hub đang render từ backend hay fallback mock.

### Test phase

- Backend API `/api/providers` hiện tại phải được ghi nhận trước khi sửa.
- Grep provider ID ngoài danh sách để biết các điểm cần xoá.

### Output phase

- Danh sách provider sẽ xoá.
- Danh sách file cần chỉnh.

## Phase 2 — Xoá provider ngoài danh sách 7

**Thời gian dự kiến:** 45-90 phút

### Việc cần làm

1. Xoá tất cả thư mục trong `providers/` trừ 7 provider được giữ.
2. Xoá reference lifecycle trong shared scripts nếu có, ví dụ dispatch Linux/Windows cho provider đã xoá.
3. Xoá hoặc chỉnh seed/registry code nếu đang hard-code provider đã xoá.
4. Không xoá tài liệu lịch sử trong `docs/`, `plans/`, `logs/` nếu chúng không ảnh hưởng runtime, trừ khi chúng làm test/grep runtime bị nhiễu.
5. Không xoá runtime secret files bằng lệnh destructive rộng; chỉ stage file source liên quan.

### Test phase

- `git status --short` kiểm tra chỉ có thay đổi mong muốn.
- Grep trong runtime code không còn ID provider bị xoá.
- Backend provider validation script nếu có phải pass.

### Output phase

- Repo chỉ còn 7 provider manifests trong `providers/`.

## Phase 3 — Backend registry và API validation

**Thời gian dự kiến:** 45-60 phút

### Việc cần làm

1. Đọc `backend-skill` trước khi sửa backend.
2. Restart hoặc refresh backend registry nếu cần.
3. Đảm bảo `/api/providers` chỉ trả đúng 7 provider.
4. Đảm bảo direct endpoint của provider bị xoá trả 404.
5. Kiểm tra install/run/status/log endpoints không lỗi với 7 provider còn lại.

### Test phase

- Chạy backend tests liên quan provider registry/lifecycle.
- Gọi API:
  - `GET /api/providers`
  - `GET /api/providers/{kept_id}` cho 7 provider
  - `GET /api/providers/{removed_id}` cho một vài provider đã xoá, kỳ vọng 404.

### Output phase

- Backend API nhất quán với danh sách 7 provider.

## Phase 4 — Frontend Hub validation

**Thời gian dự kiến:** 45-75 phút

### Việc cần làm

1. Đọc `frontend-skill` trước khi sửa frontend.
2. Kiểm tra Hub list/detail lấy dữ liệu backend đúng.
3. Đảm bảo frontend không dùng mock provider đã xoá khi backend online.
4. Nếu mock data vẫn cần cho offline/dev, cập nhật để chỉ còn 7 provider hoặc không hiển thị provider xoá khi backend reachable.
5. Restart frontend dev server sau thay đổi.

### Test phase

- Gọi `http://127.0.0.1:3000` và trang Hub/detail.
- Kiểm tra UI chỉ hiện 7 provider.
- Chạy frontend tests liên quan Hub/provider detail.
- Chạy typecheck nếu project có script.

### Output phase

- Frontend không còn hiển thị provider ngoài danh sách.

## Phase 5 — Fresh clone setup validation trên máy sạch

**Thời gian dự kiến:** 2-4 giờ, tuỳ tốc độ mạng/Docker/image build

### Việc cần làm

1. Tạo môi trường clone mới riêng biệt, không dùng state hiện tại.
2. Test Windows path có dấu cách tương tự `C:\code\my source\frontend-test`.
3. Chạy setup script:
   - Windows: `setup.ps1`
   - Linux/macOS/Git Bash nếu cần: `setup.sh`
4. Xác nhận setup tự kiểm tra/cài hướng dẫn cho:
   - Git
   - Node.js/npm
   - Python 3.11+
   - Docker Desktop/Engine
   - Docker Compose v2
5. Xác nhận `.venv`, backend deps, frontend deps được cài đúng.
6. Xác nhận `backend/scripts/seed_providers.py` seed đúng 7 provider.
7. Start backend và frontend theo hướng dẫn setup in ra.
8. Không commit `.env.local`, runtime config, deploy artifacts hoặc secrets.

### Test phase

- Fresh clone setup chạy pass.
- Backend boot pass.
- Frontend boot pass.
- `/api/providers` trả đúng 7 provider.
- Hub UI hiển thị đúng 7 provider.

### Output phase

- Bằng chứng fresh clone có thể chạy trên máy mới.
- Danh sách thiếu prerequisite nếu setup chưa tự xử lý được.

## Phase 6 — Real provider smoke test cho 7 provider

**Thời gian dự kiến:** 3-8 giờ tuỳ provider và external image/API

### Việc cần làm

1. Với từng provider trong danh sách 7, kiểm tra manifest hợp lệ.
2. Chạy lifecycle tối thiểu:
   - setup/install
   - run
   - health/metrics
   - stop/delete nếu phù hợp
3. Riêng provider có source repo riêng, nếu phải sửa source provider thì commit/push lên repo provider đó trước khi fresh install test.
4. Không dùng local-only deploy changes làm bằng chứng pass.

### Test phase

- Mỗi provider phải có kết quả:
  - install pass hoặc lỗi được ghi rõ do prerequisite/credential ngoài phạm vi.
  - run health pass nếu đủ credential/prerequisite.
  - logs không giữ stale state sau delete/setup.
- Với provider yêu cầu key, test ít nhất luồng config/env injection và health endpoint nếu có key.

### Output phase

- Matrix trạng thái 7 provider.
- Provider nào chưa thể pass 100% vì thiếu external credential phải ghi rõ.

## Phase 7 — Documentation và task logs

**Thời gian dự kiến:** 45-90 phút

### Việc cần làm

1. Đọc `documentation-skill` trước khi cập nhật tài liệu.
2. Cập nhật docs cần thiết về danh sách provider chính thức còn lại.
3. Đọc `logging-skill` trước khi ghi task log.
4. Tạo log trong `logs/tasks/` ghi rõ:
   - provider đã xoá
   - provider giữ lại
   - test đã chạy
   - fresh clone result
   - lỗi gặp phải và cách xử lý.

### Test phase

- Docs không chứa hướng dẫn runtime sai cho provider đã xoá.
- Log không chứa secrets.

### Output phase

- Documentation và task log đầy đủ.

## Phase 8 — Final review, security check, push

**Thời gian dự kiến:** 45-75 phút

### Việc cần làm

1. Đọc `security-skill` trước khi review file thay đổi.
2. Kiểm tra không stage:
   - `.env`
   - `.env.local`
   - `runtime/config.local.json`
   - deploy clone artifacts
   - Docker volumes
   - API keys hoặc secrets.
3. Đọc `testing-skill` và xác nhận toàn bộ test đã pass.
4. Đọc `push-code-skill` trước khi commit/push.
5. Commit với message mô tả rõ việc giữ lại 7 provider và fresh clone validation.
6. Push lên repo Hub.
7. Nếu source provider nào trong 7 bị sửa, push repo provider tương ứng trước khi báo hoàn tất.

### Test phase

- `git status` sạch sau commit.
- Remote push pass.
- Nếu có PR/checks thì theo dõi tới khi pass.

### Output phase

- Commit/push hoàn tất.
- Tóm tắt cuối: 7 provider còn lại, test đã chạy, vấn đề còn tồn đọng nếu có.

## Acceptance criteria

Task chỉ được coi là hoàn thành khi:

1. `providers/` chỉ còn 7 provider được yêu cầu.
2. Backend `/api/providers` chỉ trả đúng 7 provider.
3. Frontend Hub chỉ hiển thị đúng 7 provider khi backend online.
4. Fresh clone setup trên môi trường mới chạy được tới backend/frontend local.
5. Không commit secrets/runtime/deploy artifacts.
6. Documentation và task log đã cập nhật.
7. Tests theo từng phase pass.
8. Code đã commit/push theo `push-code-skill`.

## Rủi ro và cách xử lý

- **Provider bị xoá vẫn hiện do frontend/browser cache:** restart backend/frontend, hard refresh, kiểm tra API source of truth.
- **Provider bị xoá vẫn hiện do mock fallback:** cập nhật mock/fallback để không chứa provider đã xoá hoặc chỉ dùng khi backend offline.
- **Fresh clone fail do thiếu Docker/Git/Node/Python:** setup scripts phải báo rõ prerequisite và hướng dẫn cài.
- **Windows path dài hoặc path có dấu cách:** test ở path có dấu cách và giữ `git -c core.longpaths=true` trong lifecycle cần thiết.
- **Provider source sửa local nhưng chưa push provider repo:** bắt buộc push provider repo riêng rồi fresh install lại.
- **External API/image registry cần credential:** ghi rõ prerequisite, không hard-code hoặc commit key.

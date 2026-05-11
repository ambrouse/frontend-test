# Plan: Add pdf-to-podcast Provider

## Mục tiêu
- Thêm provider mới từ `https://github.com/PhuongHo03/pdf-to-podcast.git` vào AI Hub.
- Clone và đọc source provider, chạy thử, fix lỗi nếu có, push lại provider upstream.
- Test vòng lặp install/run từ Hub đến khi pass 100%.
- Dọn toàn bộ repo clone/deploy tạm của provider sau khi pass.
- Ghi documentation/log và push source chính lên GitHub.

## Skills cần dùng
- `plan-skill`: lập và bám sát plan.
- `backend-skill`: chỉnh registry/runtime/API nếu cần.
- `frontend-skill`: chỉnh Hub UI/provider metadata nếu cần.
- `documentation-skill`: ghi tài liệu task sau khi hoàn tất.
- `logging-skill`: ghi log task.
- `push-code-skill`: commit/push provider và source chính.

## Phase 1: Khảo sát source chính và cấu trúc provider hiện có
- Thời gian dự kiến: 10-20 phút.
- Việc làm:
  - Đọc registry/provider schema/scripts mẫu.
  - Xác định cách Hub install/run/stop/delete provider.
  - Xác định thư mục deploy tạm cần dọn.
- Test:
  - Không sửa code khi chưa hiểu cấu trúc.

## Phase 2: Clone và đọc provider pdf-to-podcast
- Thời gian dự kiến: 20-40 phút.
- Việc làm:
  - Clone repo về khu vực deploy/tạm.
  - Đọc README, package manifests, Dockerfile, scripts, env requirements.
  - Chạy thử theo hướng dẫn gốc.
- Test:
  - Ghi lại lỗi install/run/build/typecheck/runtime nếu có.

## Phase 3: Fix provider upstream
- Thời gian dự kiến: 30-90 phút tùy lỗi.
- Việc làm:
  - Sửa lỗi trong clone provider để chạy ổn trên Windows/Linux/Docker.
  - Thêm hoặc sửa env/example/setup script nếu thiếu.
  - Commit và push lên repo provider.
- Test:
  - Chạy lại lệnh build/run/test của provider sau mỗi vòng fix.

## Phase 4: Thêm provider vào source chính
- Thời gian dự kiến: 30-60 phút.
- Việc làm:
  - Tạo folder `providers/pdf-to-podcast`.
  - Thêm metadata, `.env.example`, scripts Windows/Linux: `setup`, `run`, `stop`, `health`, `collect-metrics`, cleanup nếu pattern repo yêu cầu.
  - Đảm bảo script dùng repo upstream mới nhất và không hard-code đường dẫn OS-specific.
- Test:
  - Dry-run nếu có.
  - Install/run qua Hub scripts trực tiếp.

## Phase 5: Vòng lặp install/run đến khi pass
- Thời gian dự kiến: 30-120 phút tùy lỗi.
- Việc làm:
  - Xóa deploy/provider clone tạm.
  - Test install clean.
  - Test run/health/metrics/stop/delete.
  - Nếu lỗi: quay lại Phase 3 hoặc 4, fix, push provider nếu thuộc provider upstream, rồi test lại.
- Điều kiện pass:
  - Provider install không lỗi.
  - Provider run được.
  - Health báo ok hoặc degraded có lý do rõ nhưng app vẫn truy cập được.
  - Stop/delete không để lại process/container rác.

## Phase 6: Dọn dẹp, docs/logs, push source chính
- Thời gian dự kiến: 20-40 phút.
- Việc làm:
  - Dọn repo clone tạm và deploy provider.
  - Ghi documentation task.
  - Ghi log task.
  - Chạy test/typecheck phù hợp.
  - Commit và push source chính.
- Test:
  - `git status` kiểm tra chỉ còn thay đổi chủ đích.
  - Verify remote provider và remote source chính đã nhận commit.

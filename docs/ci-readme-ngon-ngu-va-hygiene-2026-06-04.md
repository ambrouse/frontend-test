# CI, README Và Quy Tắc Ngôn Ngữ - 2026-06-04

## Phạm Vi

Tài liệu này ghi lại lần sửa README, docs/log liên quan và các lỗi CI sau commit `78dc555`.

## Quy Định Đã Áp Dụng

- README, docs liên quan và log công việc mới viết bằng tiếng Việt có dấu.
- README không dùng banner động cũ.
- README không dùng dashboard ảnh ngoài dễ vỡ; ảnh minh họa chuyển sang file local trong `tests/`.
- Evidence trong `tests/` không giữ artifact tạm như `.json`, `.log`, `.har`, `.tmp` hoặc `trace.zip`.

## Lỗi CI Đã Xác Định

- `Frontend dependency audit`: workflow ghi audit production dependencies nhưng command cũ audit cả dev dependency, làm advisory của `vitest` chặn CI.
- `Repository hygiene`: còn JSON tracked trong `tests/`, trái quy tắc evidence hygiene.
- `Setup smoke`: CI đang chạy `printf '\n' | ./setup.sh`; command mới dùng `bash ./setup.sh --yes --no-start --skip-nginx` để kiểm tra setup không cần start service.

## Thay Đổi Chính

- Cập nhật `.github/workflows/ci.yml` để audit đúng production dependency bằng `npm audit --omit=dev --audit-level=moderate`.
- Cập nhật setup smoke để chạy root setup bằng Bash trên runner Ubuntu, tự động trả lời yes và bỏ qua start/nginx trong smoke test.
- Xóa `banner.gif` cũ khỏi repo, README dùng `banner.jpg`.
- Xóa JSON tracked trong `tests/current-frontend-fix-2026-06-04/` và `tests/navbar-shell-clean-2026-06-04/`.
- Dịch README chính, docs/log README liên quan và README evidence mới sang tiếng Việt có dấu.

## Kiểm Chứng Cục Bộ

- `git diff --cached --check`: đạt.
- Kiểm tra link README/docs/logs/plans/tests/infra: đạt với 155 file Markdown.
- Evidence hygiene theo tracked files: đạt.
- `npm audit --omit=dev --audit-level=moderate`: đạt.
- `npm run typecheck`: đạt.
- `npm run test`: đạt, 9 test pass.
- `npm run build`: đạt.
- Setup smoke local không chạy được vì máy Windows hiện chỉ có WSL stub và thiếu `/bin/bash`; phần này sẽ được xác nhận trên GitHub Actions runner Ubuntu sau push.

# Log Công Việc: CI, README Và Ngôn Ngữ - 2026-06-04

## Bối Cảnh

Người dùng báo README, docs và logs chưa thống nhất tiếng Việt có dấu, README còn dính banner cũ và CI trên GitHub chưa đạt.

## Việc Đã Làm

- Đọc quy định trong `.codex/skills/readme-style/SKILL.md` và `.codex/skills/push-code-skill/SKILL.md`.
- Kiểm tra GitHub Actions run `CI #53` trên commit `78dc555`; run fail ở `Frontend dependency audit`, `Repository hygiene` và `Setup smoke`.
- Tái hiện lỗi audit frontend bằng `npm audit --audit-level=moderate`.
- Xác nhận lệnh audit production đúng là `npm audit --omit=dev --audit-level=moderate`.
- Tái hiện repository hygiene và xác định JSON tracked trong `tests/` làm CI fail.
- Chuyển README chính sang tiếng Việt, bỏ banner cũ và bỏ dashboard ảnh ngoài.
- Xóa file `banner.gif` cũ khỏi repo.
- Dịch docs/log README liên quan và README evidence mới sang tiếng Việt.
- Cập nhật setup smoke để CI chạy `bash ./setup.sh --yes --no-start --skip-nginx`.
- Sửa `setup.sh` để log tạo `.venv` đi qua stderr, tránh làm bẩn giá trị path Python trả về qua stdout.

## Kiểm Chứng

- `git diff --cached --check`: đạt.
- Kiểm tra link local README/docs/logs/plans/tests/infra: đạt, 155 file Markdown.
- Evidence hygiene theo tracked files: đạt.
- `npm audit --omit=dev --audit-level=moderate`: đạt.
- `npm run typecheck`: đạt.
- `npm run test`: đạt, 9 test pass.
- `npm run build`: đạt.
- Setup smoke local bị chặn bởi WSL stub thiếu `/bin/bash`; cần xác nhận trên GitHub Actions Ubuntu sau push.

## Kết Quả

- README hiện là tiếng Việt có dấu, dùng ảnh local `banner.jpg`, không còn dashboard ảnh ngoài.
- CI production audit và evidence hygiene đã được sửa theo nguyên nhân fail.
- Các thay đổi đã sẵn sàng để commit và push khi staged diff cuối cùng sạch.

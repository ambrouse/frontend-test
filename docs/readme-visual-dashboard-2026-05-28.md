# Dashboard README - 2026-05-28

## Mục Đích

Ghi lại lần bổ sung dashboard README sau đợt chỉnh CI và banner ban đầu.

## Thay Đổi

- Dashboard ảnh ngoài cũ đã được thay bằng bảng tín hiệu nội bộ trong README.
- README hiện ưu tiên ảnh local và evidence thật:
  - ảnh Hub light/dark mode;
  - ảnh navbar light mode;
  - ảnh provider card và control button;
  - đường dẫn trực tiếp tới thư mục `tests/`.
- CI markdown hygiene kiểm tra cả link Markdown lẫn HTML `href` và `src` local.

## Ràng Buộc

- GitHub Markdown không cho CSS tùy ý, nên README dùng bảng Markdown, badge vừa đủ, ảnh local và Mermaid.
- Evidence dùng ảnh đã capture trong `tests/`; không đưa ảnh giả hoặc mock không kiểm chứng vào README.
- README không còn phụ thuộc stat card SVG ngoài để tránh ảnh vỡ trên GitHub.

## Kiểm Chứng

- `actionlint -color`.
- Kiểm tra link local trong README/docs/logs/plans/tests/infra, gồm Markdown link và HTML `href`/`src`.
- Evidence hygiene: chặn README evidence rỗng, artifact tạm và ảnh trùng hash.
- Frontend: typecheck, unit test, build và audit production dependency.
- Backend: lint, typecheck, test, security scan, provider check, OpenAPI smoke, package build, benchmark và pip-audit.

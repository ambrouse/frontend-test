# Dashboard README - 2026-05-28

## 11:07 Bắt Đầu

- User yêu cầu README hiện đại hơn, có màu sắc AI-tech, nhiều panel dashboard, ảnh và cảm giác động hơn.
- Skill đã áp dụng: `readme-style`, `documentation-skill`, `logging-skill`, `testing-skill` và `push-code-skill`.

## Thay Đổi

- README từng có dashboard stat card ngoài; hiện đã thay bằng bảng tín hiệu nội bộ để tránh ảnh vỡ trên GitHub.
- README có bảng bằng chứng giao diện với ảnh thật từ `tests/`.
- Banner cũ đã được thay bằng `banner.jpg`.
- CI repository hygiene kiểm tra cả HTML `href` và `src` local trong Markdown.
- CI evidence hygiene được viết bằng Python để actionlint/shellcheck chấp nhận phần quét ảnh trùng.
- Thêm tài liệu: `docs/readme-visual-dashboard-2026-05-28.md`.
- Thêm plan: `plans/plan-readme-visual-dashboard-2026-05-28.md`.

## 11:17 Kiểm Chứng

- `actionlint -color`: pass.
- Kiểm tra link local README/docs/logs/plans/tests/infra, gồm Markdown và HTML link: pass, 121 file Markdown.
- Evidence hygiene: pass, không có README evidence rỗng, artifact tạm hoặc screenshot trùng hash.
- Frontend: `npm run typecheck`, `npm test`, `npm run build` và audit: pass.
- Backend: validate provider manifest, secret scan, ruff, format check, mypy, coverage test, provider dry-run lifecycle, latency benchmark, OpenAPI smoke, package build và pip-audit: pass.
- Setup/script syntax: `bash -n setup.sh`, cú pháp provider Linux script và Docker Compose Nginx config: pass.
- Ghi chú local: host SSH lúc đó chưa có `pwsh`, nên phần parser PowerShell do GitHub CI runner kiểm tra.

## 11:17 Kết Quả

- README có dashboard GitHub rõ hơn, dùng ảnh evidence thật và tránh phụ thuộc ảnh ngoài dễ vỡ.
- Không thêm secret vào docs, logs, tests hoặc README.

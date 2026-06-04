# Tinh Chỉnh README Và CI - 2026-05-28

## 10:54 Bắt Đầu

- User báo banner GitHub bị crop và phần trình bày CI/README còn đơn giản.
- Skill đã áp dụng: `readme-style`, `push-code-skill`, `plan-skill`, `documentation-skill`, `logging-skill`, `testing-skill` và `security-skill`.
- Đã tạo plan: `plans/plan-readme-ci-polish-2026-05-28.md`.

## Audit

- README thời điểm đó dùng banner động cũ, sau này đã thay bằng ảnh tĩnh local `banner.jpg`.
- CI đã có test frontend/backend đa nền tảng, kiểm tra cú pháp provider script, release artifact, audit, validate provider, dry-run lifecycle và benchmark latency.
- Cổng CI còn thiếu:
  - setup smoke từ root script;
  - validate Nginx compose/template;
  - kiểm tra link docs/evidence và hygiene artifact;
  - Dependency Review trên pull request;
  - CodeQL cho Python và JavaScript/TypeScript.

## Thay Đổi Dự Kiến

- Render banner README bằng HTML có `width="100%"`.
- Thêm badge, bảng trạng thái, provider matrix và command card GitHub-safe.
- Mở rộng CI với repository hygiene và setup/Nginx check.
- Thêm security workflow cho Dependency Review và CodeQL.

## Đã Áp Dụng

- Cập nhật README hero, badge, provider matrix, quick-start card và sơ đồ kiến trúc.
- Thêm `docs/ci-and-readme-polish-2026-05-28.md`.
- Mở rộng `.github/workflows/ci.yml` với repository hygiene và setup smoke.
- Thêm `.github/workflows/security.yml` cho Dependency Review và CodeQL.

## Kiểm Chứng

- `actionlint`: pass cú pháp GitHub workflow.
- Kiểm tra link local README/docs: đã kiểm 118 file Markdown.
- Evidence hygiene: pass README presence, temp artifact scan và duplicate image scan.
- `docker compose -f docker-compose.nginx.yml config -q`: pass.
- `docker exec ai-hub-nginx nginx -t`: pass.
- `npm run typecheck`: pass.
- `npm test`: 9 test pass.
- `npm audit --audit-level=moderate`: không có vulnerability.
- `./.venv/bin/python -m pytest backend/tests`: 24 test pass.
- `./.venv/bin/python backend/scripts/validate_providers.py`: validate 8 provider manifest.
- `./.venv/bin/python backend/scripts/check_no_secrets.py`: pass.
- Setup root đã chạy và seed 8 provider.
- `npm run build`: pass.
- Backend `ruff check`, `ruff format --check` và `mypy app`: pass.

## Kết Quả

- README có cấu trúc rõ hơn trên GitHub và vẫn giữ nội dung kỹ thuật.
- Banner README được render responsive.
- CI bao phủ setup root, repository hygiene, Nginx config, Dependency Review và CodeQL bên cạnh các cổng frontend/backend/provider.

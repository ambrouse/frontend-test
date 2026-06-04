# Tinh Chỉnh CI Và README - 2026-05-28

## Mục Đích

Ghi lại lần chỉnh giao diện README trên GitHub và bổ sung cổng CI/CD cho AI Hub.

## Trình Bày README

- Banner README hiện dùng ảnh tĩnh local `banner.jpg`, không dùng banner động cũ.
- Ảnh được render bằng thẻ HTML có `width="100%"` và alt text rõ ràng để GitHub hiển thị ổn định.
- README dùng các thành phần GitHub-safe:
  - badge `for-the-badge` cho tín hiệu build/runtime;
  - bảng Markdown cho matrix trạng thái;
  - liên kết tới evidence thật trong `tests/`;
  - sơ đồ Mermaid cho kiến trúc có Nginx gateway.

## Bổ Sung CI/CD

Workflow chính đang kiểm tra:

- Frontend đa nền tảng: typecheck, unit test và build.
- Backend đa nền tảng: lint, format, typecheck, test coverage, build package, validate provider, dry-run lifecycle, secret scan và benchmark latency.
- Cú pháp Bash/PowerShell của provider script.
- Audit dependency production của frontend.
- Hygiene repo:
  - kiểm tra link local trong README/docs/logs/plans/tests/infra;
  - kiểm tra README evidence;
  - chặn artifact tạm trong evidence;
  - chặn ảnh evidence bị trùng hash;
  - validate Docker Compose Nginx và `nginx -t`.
- Setup smoke từ root, không cần secret provider thật.

Workflow security đang kiểm tra:

- Dependency Review trên pull request.
- CodeQL cho Python và JavaScript/TypeScript.
- Lịch quét bảo mật hằng tuần.

## Ghi Chú

- Các cổng CI không yêu cầu secret provider thật.
- Bằng chứng provider full-function vẫn nằm trong các thư mục `tests/`.
- CodeQL và Dependency Review phụ thuộc gói/quyền GitHub Advanced Security của repository.

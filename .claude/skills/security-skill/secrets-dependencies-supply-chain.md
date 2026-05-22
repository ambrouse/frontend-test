# Secrets Dependencies Supply Chain Raw

## Secrets

- Không commit `.env`, private key, token, credential, database URL thật hoặc cloud secret.
- Dùng secret manager hoặc CI secret store cho production.
- `.env.example` chỉ chứa placeholder an toàn.
- Secret rotation cần được đề xuất nếu phát hiện secret đã lộ.
- Logs/tests/docs không được chứa secret hoặc giá trị có thể dùng để truy cập hệ thống.

## Dependencies

- Chỉ thêm dependency khi lợi ích rõ và không thể dùng code/framework hiện có hợp lý.
- Kiểm license, maintenance, popularity, release cadence và vulnerability nếu dependency production.
- Pin/lock version qua lockfile; không cập nhật hàng loạt ngoài phạm vi task.
- Không chạy install script/package lạ mà không cần thiết.

## Supply chain

- Khuyến nghị SCA scan trong CI cho repo production.
- SBOM nên có cho hệ thống production hoặc compliance.
- Package publishing/release phải có provenance/signing nếu hệ sinh thái hỗ trợ.
- CI token cần least privilege; PR từ fork không được có quyền secret nguy hiểm.

## Git hygiene

- Trước commit/push, kiểm staged diff để tránh secret và file local.
- Nếu secret đã commit, không chỉ xóa file; cần rotate secret và xử lý history theo quy trình user duyệt.

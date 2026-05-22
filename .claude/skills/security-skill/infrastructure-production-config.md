# Infrastructure Production Config Raw

## Production defaults

- TLS bắt buộc cho traffic public; không tắt certificate verification.
- Debug mode off trong production.
- Error detail, stack trace, source map nhạy cảm không public nếu không có kiểm soát.
- Config phải tách dev/staging/prod rõ ràng.
- Default credentials phải bị chặn hoặc đổi trước production.

## Security headers

- Khuyến nghị thiết lập phù hợp: Content-Security-Policy, Strict-Transport-Security, X-Content-Type-Options, Referrer-Policy, frame-ancestors hoặc X-Frame-Options.
- Header phải phù hợp kiến trúc; không thêm bừa nếu phá app.

## Containers/IaC/cloud

- Container chạy non-root nếu có thể.
- Image base tối giản, cập nhật và scan vulnerability.
- Không bake secret vào image.
- IaC dùng least privilege IAM/security group/network rule.
- Public bucket/database/queue phải bị chặn trừ khi có lý do rõ.

## CI/CD

- Không expose secret cho untrusted PR.
- Build artifact phải reproducible ở mức phù hợp.
- Deploy production cần approval/gate nếu dự án yêu cầu.
- Security scan fail critical/high phải được xử lý hoặc user chấp nhận risk rõ ràng.

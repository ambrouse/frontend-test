# Logging Monitoring Incident Raw

## Security logging

- Log sự kiện security quan trọng: login fail nhiều lần, password reset, permission denied critical, admin action, token revoke, webhook verify fail.
- Audit log phải có actor, action, target, timestamp, result và correlation ID nếu có.
- Không log secret, password, token, cookie, authorization header, private key hoặc PII không cần thiết.
- Redaction phải áp dụng trước khi log ra sink bên ngoài.

## Monitoring

- Cảnh báo cho spike 401/403, rate limit hit, webhook failure, admin action bất thường, dependency/service security failure.
- Metric không được chứa cardinality cao từ dữ liệu user nhạy cảm.
- Error reporting phải scrub payload và headers nhạy cảm.

## Incident readiness

- Nếu phát hiện leak/vulnerability nghiêm trọng, dừng mở rộng thay đổi và báo user.
- Đề xuất containment: revoke/rotate secret, disable exposed path, patch dependency, block endpoint, add monitoring.
- Không tự force-push, rewrite history hoặc xóa evidence nếu chưa được user xác nhận.

## Dùng logging-skill/documentation-skill

- Task logs dùng `logging-skill`: ghi mục tiêu, hành động, kết quả verify, blocker, không ghi dữ liệu nhạy cảm.
- Docs dùng `documentation-skill`: cập nhật runbook/security notes nếu thay đổi vận hành hoặc incident response.

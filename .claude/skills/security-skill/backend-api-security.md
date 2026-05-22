# Backend API Security Raw

## API baseline

- Mọi endpoint mutating phải có authentication, authorization và validation phù hợp.
- Response error không lộ stack trace, SQL, internal service URL, token hoặc secret.
- Endpoint nhạy cảm cần rate limit, abuse protection và audit log.
- CORS phải allowlist origin cụ thể; không dùng wildcard với credentials.
- CSRF protection bắt buộc nếu dùng cookie session cho browser mutating requests.

## Database

- Principle of least privilege cho database user.
- Migration không làm lộ/mất dữ liệu; rollback plan nếu production critical.
- Query dynamic phải parameterized; sort/filter fields phải allowlist.
- Multi-tenant query phải enforce tenant scope ở mọi access path.

## Webhook và integration

- Verify signature với constant-time compare khi phù hợp.
- Kiểm timestamp/nonce để chống replay.
- Idempotency key hoặc event dedupe cho duplicate delivery.
- Không tin payload external trước khi verify.

## Error handling

- Fail closed cho auth, permission, payment, quota, compliance.
- Public error dùng code/message an toàn; internal detail chỉ ở log đã redact.
- Không swallow security-critical errors làm request thành công giả.

## API tests cần có

- Auth/permission matrix.
- Validation/malformed payload.
- Injection payload đại diện.
- Rate limit hoặc abuse case nếu endpoint critical.
- Error response không lộ thông tin nhạy cảm.

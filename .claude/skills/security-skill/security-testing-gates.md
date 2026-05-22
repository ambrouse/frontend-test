# Security Testing Gates Raw

## Loại kiểm thử

- SAST: phát hiện pattern code nguy hiểm như injection, hardcoded secret, unsafe deserialization.
- DAST: kiểm runtime web/API khi có môi trường phù hợp.
- SCA: dependency vulnerability và license risk.
- Secret scan: commit/worktree/CI logs.
- IaC scan: cloud permission, public exposure, insecure defaults.
- Container scan: base image và package vulnerabilities.
- Fuzz/property test: parser, validator, upload, serialization hoặc protocol logic critical.

## Khi chạy

- Chạy check liên quan khi thay đổi chạm security-sensitive path.
- Với production repo, đề xuất đưa SAST/SCA/secret scan vào CI nếu chưa có.
- Không bypass scan bằng ignore nếu chưa có justification, owner và expiry.

## Security regression tests

- Auth bypass case.
- IDOR/cross-tenant access.
- Injection payload representative.
- XSS payload render path.
- CSRF nếu cookie session.
- Webhook signature/replay.
- Rate limit hoặc brute force protection nếu endpoint nhạy cảm.

## Đánh giá gate

- Critical/High exploitable phải fix trước khi gọi ready, trừ khi user chấp nhận risk rõ.
- Medium cần remediation hoặc ticket/risk note.
- Low/hardening có thể ghi backlog nếu không thuộc phạm vi release.

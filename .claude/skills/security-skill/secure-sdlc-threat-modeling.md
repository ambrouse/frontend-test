# Secure SDLC And Threat Modeling Raw

## Secure SDLC

- Security phải được xem là requirement của task, không phải bước cuối.
- Với thay đổi chạm auth, payment, PII, tenant, admin, file upload, webhook hoặc infra, phải review security trước khi hoàn thành.
- Security acceptance criteria phải đo được: `verify that`, `test that`, `ensure that`.
- Tách rõ security requirement, implementation, verification và residual risk.

## Threat modeling nhanh

Luôn trả lời các câu hỏi:

- Asset nào cần bảo vệ?
- Actor nào hợp lệ, actor nào không hợp lệ?
- Entry point nào nhận input từ user/external system?
- Trust boundary ở đâu: browser/API/service/database/third-party?
- Dữ liệu nhạy cảm đi qua đâu, lưu ở đâu, log ở đâu?
- Abuse case nào thực tế nhất?
- Failure mode nào phải fail closed?

## Severity

- Critical: auth bypass, RCE, secret leak, cross-tenant data access, payment/data corruption critical.
- High: privilege escalation, injection exploitable, sensitive data exposure, insecure direct object reference.
- Medium: missing rate limit ở endpoint nhạy cảm, weak validation, verbose error, risky dependency.
- Low: hardening gap, missing header, minor info disclosure không nhạy cảm.

## Output review

Mỗi finding nên có:

- Tiêu đề ngắn.
- Severity và affected area.
- Evidence trong code/config.
- Impact và exploit precondition.
- Remediation cụ thể.
- Test/verification cần chạy.
- Residual risk nếu còn.

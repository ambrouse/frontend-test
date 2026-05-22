---
name: security-skill
description: Quy tắc raw bắt buộc khi Claude Code thiết kế, viết, review hoặc kiểm thử bảo mật production cho frontend, backend, API, config, dependency và vận hành.
argument-hint: "security task"
user-invocable: true
---

# Security Skill Raw

Áp dụng khi user yêu cầu security review, hardening, auth, permission, secrets, dependency security, secure config, production readiness hoặc khi thay đổi chạm dữ liệu/quyền/hạ tầng.

## Chuẩn tham chiếu

- Dùng OWASP ASVS làm baseline cho yêu cầu bảo mật ứng dụng production.
- Dùng OWASP Top 10 làm checklist rủi ro web phổ biến.
- Dùng OWASP Cheat Sheet Series cho hướng dẫn chi tiết theo chủ đề.
- Khi phù hợp, mapping phát hiện sang CWE/CVE/control để báo cáo rõ ràng.
- Không tuyên bố “secure/production-ready” nếu chưa có evidence từ review, test và cấu hình môi trường.

## Phân loại file phụ trợ

- `secure-sdlc-threat-modeling.md`: tư duy secure SDLC, threat model, trust boundary.
- `auth-session-access-control.md`: authentication, session, authorization, tenant boundary.
- `input-output-data-security.md`: validation, injection, XSS, serialization, file upload, privacy.
- `backend-api-security.md`: API/backend, database, transactions, rate limit, error handling.
- `frontend-security.md`: browser security, CSP, token handling, DOM/XSS, third-party scripts.
- `secrets-dependencies-supply-chain.md`: secrets, dependency, SBOM, package/scripts, CI safety.
- `infrastructure-production-config.md`: TLS, headers, config, container/IaC/cloud, environment.
- `security-testing-gates.md`: SAST, DAST, SCA, IaC, container scan, CI/CD gates.
- `logging-monitoring-incident.md`: audit log, monitoring, privacy-safe logs, incident readiness.
- `security-review-checklist.md`: checklist cuối trước khi merge/release.

## Quy trình bắt buộc

1. Xác định asset, dữ liệu nhạy cảm, actor, quyền, trust boundary và entry point.
2. Kiểm các lớp: client, API, service, database, dependency, config, deployment, logging.
3. Ưu tiên deny-by-default, least privilege, explicit allowlist, secure defaults.
4. Viết hoặc đề xuất test bảo mật cho authz, validation, injection, secrets, error leakage và config critical.
5. Kiểm không đưa secret/PII vào code, test, docs, logs, snapshot hoặc commit.
6. Nếu task có logging/docs, dùng `logging-skill` và `documentation-skill` nhưng phải redaction dữ liệu nhạy cảm.
7. Báo cáo risk theo severity, impact, exploitability, affected files, remediation và verification.

## Nguyên tắc không được làm

- Không hardcode secret, token, private key, credential hoặc endpoint nhạy cảm.
- Không tạo bypass auth/permission tạm thời trong production path.
- Không dùng string concatenation cho SQL/command/template nguy hiểm.
- Không log token, password, session ID, authorization header, PII hoặc payload nhạy cảm.
- Không thêm dependency không cần thiết hoặc package không rõ nguồn gốc.
- Không tắt security check, hook, linter, scan hoặc TLS verification trừ khi user yêu cầu rõ và có lý do.
- Không hướng dẫn tấn công phá hoại, DoS, credential abuse, evasion hoặc mass targeting.

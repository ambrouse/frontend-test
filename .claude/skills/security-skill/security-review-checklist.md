# Security Review Checklist Raw

## Code

- [ ] Input boundary có validation allowlist/schema.
- [ ] Query/command/template sink dùng API an toàn, không nối chuỗi nguy hiểm.
- [ ] Authn/authz kiểm ở backend cho action critical.
- [ ] Tenant/owner/resource scope được enforce.
- [ ] Error public không lộ stack/internal/secret.
- [ ] Sensitive data không log hoặc expose ra client.
- [ ] File upload/webhook/external input có verify phù hợp.

## Frontend

- [ ] Không có secret trong bundle/env public.
- [ ] User-generated content không gây XSS.
- [ ] Security control không chỉ nằm ở UI.
- [ ] External script/dependency có lý do rõ.

## Config/infra

- [ ] Production debug off.
- [ ] TLS/certificate verification không bị tắt.
- [ ] CORS/CSP/security headers phù hợp.
- [ ] Secret đến từ secret manager/CI secret, không hardcode.
- [ ] CI không expose secret cho untrusted PR.

## Dependencies

- [ ] Dependency mới cần thiết và đáng tin.
- [ ] Lockfile cập nhật đúng phạm vi.
- [ ] SCA/secret scan/SAST được chạy hoặc nêu rõ chưa chạy được.

## Báo cáo cuối

- [ ] Nêu finding theo severity.
- [ ] Nêu remediation đã làm.
- [ ] Nêu test/security scan đã chạy.
- [ ] Nêu residual risk hoặc việc cần user quyết định.

# Auth Session Access Control Raw

## Authentication

- Không tự viết crypto/password hashing nếu framework/library chuẩn đã có.
- Password phải hash bằng thuật toán phù hợp như Argon2id/bcrypt/scrypt với cost phù hợp; không dùng SHA/MD5 thuần.
- MFA, password reset, email verification và account recovery phải chống enumeration và token reuse.
- Token reset/invite phải có expiry, one-time use và storage an toàn.

## Session/token

- Cookie session production nên `HttpOnly`, `Secure`, `SameSite` phù hợp và domain/path tối thiểu.
- JWT phải verify signature, issuer, audience, expiry; không tin payload chưa verify.
- Không lưu access token nhạy cảm trong localStorage nếu có lựa chọn session cookie an toàn hơn.
- Refresh token phải rotate hoặc có replay protection khi phù hợp.
- Logout phải invalidate session/token server-side nếu hệ thống hỗ trợ.

## Authorization

- Authorization phải kiểm ở server/backend, không chỉ ẩn UI.
- Dùng deny-by-default; mỗi action critical có permission rõ.
- Kiểm owner, role, scope, tenant, organization và resource state.
- Không tin ID từ client; lookup resource rồi verify quyền trên resource đó.
- Admin/superuser path phải có guard riêng và audit log.

## Test bắt buộc khi phù hợp

- Unauthenticated bị 401.
- Authenticated nhưng thiếu quyền bị 403.
- User A không đọc/sửa/xóa resource của User B.
- Tenant A không truy cập tenant B.
- Expired/revoked token không dùng được.
- UI không hiển thị action cấm nhưng backend vẫn là nguồn enforce chính.

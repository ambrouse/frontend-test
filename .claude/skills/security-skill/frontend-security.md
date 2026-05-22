# Frontend Security Raw

## Browser security

- Không tin client-side checks cho security enforcement.
- Không expose secret trong frontend bundle, env public, source map hoặc console log.
- Token/session handling phải giảm XSS impact; ưu tiên HttpOnly cookie nếu kiến trúc cho phép.
- Không dùng eval/new Function/string-based timer với input không tin cậy.

## DOM/XSS

- Tránh direct DOM injection bằng `innerHTML` hoặc raw HTML.
- Nếu phải render rich text, sanitize bằng allowlist và test payload XSS.
- URL từ user phải validate scheme; chặn `javascript:` và scheme nguy hiểm.
- Link external nên cân nhắc `rel="noopener noreferrer"` khi mở tab mới.

## CSP và headers

- Khuyến nghị CSP production phù hợp, tránh `unsafe-inline`/`unsafe-eval` nếu có thể.
- Không phụ thuộc CSP thay thế output encoding; CSP là lớp phòng thủ bổ sung.
- Kiểm frame-ancestors/clickjacking nếu app có dữ liệu nhạy cảm.

## Third-party scripts

- Chỉ thêm script/package cần thiết và đáng tin.
- Đánh giá dữ liệu gửi tới analytics/chat/widget.
- Dùng SRI nếu tải script tĩnh từ CDN public và phù hợp.

## Frontend security tests

- Render user input không thực thi script.
- Sensitive action không chỉ bị ẩn UI mà backend cũng reject.
- Error boundary không hiển thị stack/secret ở production.
- Public env var không chứa key bí mật.

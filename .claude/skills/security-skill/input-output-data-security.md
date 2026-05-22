# Input Output Data Security Raw

## Input validation

- Validate tại boundary: HTTP request, form, CLI arg, webhook, file upload, message queue, external API.
- Dùng schema/DTO allowlist; reject field không mong muốn nếu có mass-assignment risk.
- Validation phải kiểm type, length, format, range, enum, encoding và size limit.
- Không chỉ validate frontend; backend phải validate lại.

## Injection prevention

- SQL/NoSQL query phải parameterized hoặc dùng ORM safe API đúng cách.
- OS command phải tránh shell khi có thể; nếu bắt buộc, dùng argument array và allowlist.
- Template/render phải escape theo context.
- LDAP/XPath/regex injection phải được xem xét nếu có sink tương ứng.

## XSS và output encoding

- Encode output theo context: HTML, attribute, URL, JS, CSS.
- Không dùng raw HTML/dangerouslySetInnerHTML trừ khi sanitize bằng library đáng tin.
- Sanitizer phải cấu hình allowlist và có test payload nguy hiểm.
- User-generated content phải được xử lý nhất quán từ lưu trữ đến render.

## File upload

- Kiểm MIME thực tế, extension allowlist, size limit, malware scan nếu production yêu cầu.
- Không lưu file upload trong path executable/public tùy tiện.
- Filename từ user không được dùng trực tiếp làm path.
- Image/PDF processing phải chống zip bomb/decompression bomb nếu phù hợp.

## Data privacy

- Thu thập dữ liệu tối thiểu.
- Mask/redact PII trong logs, analytics, error reporting.
- Encryption at rest/in transit tùy dữ liệu và môi trường.
- Retention/deletion phải rõ nếu xử lý dữ liệu người dùng.

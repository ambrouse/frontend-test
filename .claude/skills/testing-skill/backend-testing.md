# Backend Testing Raw

## API và contract

- Test status code, response schema, headers quan trọng, error body và side effects.
- Test authn/authz: no token, token invalid, user thiếu quyền, user đúng quyền, owner/non-owner.
- Test validation: thiếu field, sai type, sai format, payload quá lớn, field không cho phép.
- Test idempotency nếu endpoint có retry, payment, webhook hoặc job scheduling.

## Service và database

- Unit test rule thuần trong service khi không cần database.
- Integration test với database thật hoặc test container khi query, transaction, constraint, migration là phần rủi ro.
- Test transaction rollback khi một bước fail.
- Test unique constraint, foreign key, pagination, sorting, filtering và concurrency khi liên quan.
- Không mock database cho logic phụ thuộc SQL/ORM behavior quan trọng.

## External systems

- Mock/stub external API tại boundary có contract rõ.
- Test timeout, retry, circuit breaker, rate limit và fallback nếu code có các cơ chế này.
- Webhook test signature verification, replay protection, duplicate event và out-of-order event nếu phù hợp.

## Observability backend

- Test log/metric/audit event khi đó là requirement vận hành hoặc bảo mật.
- Không assert toàn bộ text log nếu dễ vỡ; assert event name, severity, field chính và không có secret.

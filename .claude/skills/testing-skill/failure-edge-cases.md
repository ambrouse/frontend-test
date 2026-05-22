# Failure And Edge Cases Raw

## Các lỗi phải nghĩ đến

- Null/undefined/missing data.
- Empty collection và single-item collection.
- Duplicate data, stale data, conflict update.
- Permission mismatch, tenant mismatch, owner mismatch.
- Timeout, abort, retry exhausted, dependency unavailable.
- Rate limit, payload too large, malformed JSON, unsupported media type.
- Timezone, daylight saving, leap day, clock skew.
- Concurrency: double submit, duplicate webhook, simultaneous update.
- Browser refresh/back navigation/offline nếu là frontend.

## Negative testing

- Negative case phải assert hệ thống fail an toàn: không ghi sai dữ liệu, không lộ thông tin nhạy cảm, trả lỗi đúng contract.
- Security-related negative tests phải kiểm authorization và input validation, không chỉ status code.
- Với lỗi user-facing, kiểm message hữu ích nhưng không lộ stack trace, SQL, token hoặc internal ID nhạy cảm.

## Flaky test prevention

- Không phụ thuộc sleep cố định; chờ theo condition/event.
- Không phụ thuộc network thật trong unit/integration local.
- Reset global state, localStorage, database, mocks, timers giữa test.
- Test parallel-safe nếu test runner chạy song song.

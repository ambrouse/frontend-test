# Test Case Design Raw

## Tư duy thiết kế

- Bắt đầu từ hành vi người dùng hoặc contract hệ thống, sau đó mới chọn framework test.
- Mỗi test case phải có mục tiêu rõ: verify rule, prevent regression, validate contract hoặc measure performance.
- Đặt tên test theo hành vi mong đợi: `returns 403 when user lacks role`, không đặt theo implementation.
- Ưu tiên Arrange-Act-Assert hoặc Given-When-Then để test dễ đọc.
- Test một ý chính mỗi case; có thể dùng table-driven tests cho nhiều biến thể cùng rule.

## Matrix tối thiểu

| Nhóm | Cần có khi phù hợp |
| --- | --- |
| Golden path | Dữ liệu hợp lệ, quyền đúng, trạng thái bình thường |
| Boundary | min/max length, zero, negative, null/undefined, empty list, large list |
| Invalid input | sai type, thiếu field, format sai, payload độc hại |
| Permission | unauthenticated, authenticated sai role, owner vs non-owner |
| State | loading, empty, partial data, stale data, conflict, retry |
| External failure | timeout, 4xx/5xx, network error, dependency unavailable |
| Regression | case từng lỗi hoặc rất dễ lỗi lại |

## Coverage

- Coverage là tín hiệu phụ, không phải mục tiêu duy nhất.
- Module critical nên có branch/path coverage cho rule quan trọng.
- Nếu coverage tăng nhưng thiếu assertion có ý nghĩa, test chưa đạt.
- Không viết test chỉ gọi function mà không assert kết quả hoặc side effect quan trọng.

## Fixture và dữ liệu test

- Fixture nhỏ, rõ nghĩa, không copy payload production nếu có PII.
- Dùng factory/builder khi nhiều test cần biến thể dữ liệu.
- Seed data phải reset được và không phụ thuộc thứ tự chạy.
- Time, random, ID generator phải được kiểm soát nếu ảnh hưởng assertion.

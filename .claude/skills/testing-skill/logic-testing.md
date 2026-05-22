# Logic Testing Raw

## Business logic

- Tách logic thuần ra khỏi framework khi hợp lý để test nhanh và chính xác.
- Dùng table-driven tests cho rule nhiều biến thể.
- Test invariant quan trọng: tổng tiền không âm, trạng thái không nhảy sai, quyền không leo thang, dữ liệu không mất.
- Với rule tài chính/định lượng, test rounding, currency, precision, timezone và boundary.

## Property-based và mutation testing

- Cân nhắc property-based tests khi input space lớn và có invariant rõ.
- Cân nhắc mutation testing cho module critical để phát hiện assertion yếu.
- Không dùng kỹ thuật nặng nếu làm chậm feedback loop mà không tăng niềm tin đáng kể.

## Pure function checklist

- Input hợp lệ trả output đúng.
- Input biên trả output đúng hoặc lỗi đúng kiểu.
- Hàm không mutate input nếu contract không cho phép.
- Hàm deterministic với cùng input.
- Error message/code đủ rõ cho caller xử lý nếu lỗi là public contract.

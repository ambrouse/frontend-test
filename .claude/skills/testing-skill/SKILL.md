---
name: testing-skill
description: Quy tắc raw bắt buộc khi Claude Code thiết kế, viết, chạy, đánh giá và ghi nhận test cho frontend, backend, logic, UI, benchmark và lỗi biên.
argument-hint: "testing task"
user-invocable: true
---

# Testing Skill Raw

Áp dụng khi user yêu cầu viết test, sửa test, tăng coverage, kiểm chứng bugfix, benchmark, QA checklist hoặc đánh giá chất lượng release.

## Mục tiêu

- Test phải chứng minh hành vi quan trọng của sản phẩm, không chỉ tăng số dòng coverage.
- Ưu tiên test ở đúng tầng: unit cho logic thuần, integration cho module phối hợp, API/backend test cho contract, UI/E2E cho luồng người dùng.
- Với bugfix, bắt buộc có test tái hiện lỗi trước hoặc mô tả rõ vì sao không thể tự động hóa.
- Không mock quá mức làm mất giá trị test; mock boundary bên ngoài hệ thống như payment, email, external API, clock, random, network.
- Test phải deterministic, chạy lại ổn định, không phụ thuộc thứ tự, timezone, dữ liệu thật hoặc trạng thái máy cá nhân.

## Phân loại file phụ trợ

- `test-case-design.md`: cách thiết kế test case, matrix, boundary, negative cases.
- `frontend-ui-testing.md`: test giao diện, accessibility, visual behavior, E2E.
- `frontend-testing.md`: unit/integration test frontend, state, hooks, client API.
- `backend-testing.md`: API, service, database, auth, concurrency, transaction.
- `logic-testing.md`: business rules, pure functions, property/table-driven tests.
- `failure-edge-cases.md`: lỗi biên, lỗi có thể xảy ra, resilience, retry, timeout.
- `benchmark-evaluation.md`: benchmark, performance regression, đánh giá kết quả.
- `test-logs-docs.md`: ghi logs và docs theo `logging-skill` và `documentation-skill`.
- `review-checklist.md`: checklist review cuối trước khi báo hoàn thành.

## Quy trình bắt buộc

1. Xác định rủi ro chính của thay đổi: dữ liệu, tiền, quyền truy cập, auth, migration, trạng thái UI, performance, security.
2. Chọn tầng test nhỏ nhất nhưng đủ niềm tin; không dùng E2E thay cho unit/integration nếu logic có thể test gần nguồn.
3. Viết test case cho golden path, boundary, invalid input, permission denied, empty state, loading/error state và regression case.
4. Chạy đúng test liên quan trước; nếu thay đổi có phạm vi rộng, chạy thêm suite tổng hoặc subset đại diện.
5. Đánh giá kết quả: pass/fail, flaky risk, coverage lỗ hổng, performance delta, rủi ro chưa test được.
6. Nếu task yêu cầu ghi nhận, dùng `logging-skill` để log kết quả test và `documentation-skill` để cập nhật docs phù hợp.

## Nguyên tắc không được làm

- Không sửa test để khớp bug sai nếu requirement chưa đổi.
- Không xóa test fail mà không thay bằng test đúng hơn.
- Không dùng snapshot lớn khó review làm bằng chứng chính.
- Không bỏ qua test/linter/hook bằng flag skip trừ khi user yêu cầu rõ.
- Không claim “đã test” nếu chỉ đọc code hoặc chỉ chạy typecheck.
- Không ghi secret, token, dữ liệu thật hoặc PII vào fixture, snapshot, logs hay report.

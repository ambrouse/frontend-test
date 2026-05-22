# Frontend UI Testing Raw

## Phạm vi

Áp dụng cho page, component hiển thị, interaction người dùng, accessibility, responsive state và luồng E2E.

## Bắt buộc kiểm chứng

- Render đúng trạng thái chính: loading, success, empty, error, disabled, optimistic/pending nếu có.
- Interaction đúng bằng hành vi người dùng thật: click, keyboard, form submit, focus, navigation.
- Accessibility: label, role, name, focus order, keyboard navigation, aria chỉ dùng khi cần.
- Responsive/layout: breakpoint quan trọng, overflow, text wrapping, modal/drawer behavior.
- Form: validation message, invalid submit, reset, dirty state, server error mapping.
- Network/UI contract: request đúng endpoint/client, loading không kẹt, lỗi hiển thị dễ hiểu.

## E2E/UI smoke

- Chỉ dùng E2E cho luồng có giá trị tích hợp: login, checkout, onboarding, CRUD critical, permission flow.
- E2E phải ít nhưng mạnh; tránh kiểm từng chi tiết visual bằng E2E nếu unit/integration đủ.
- Selector ưu tiên role/name hoặc test id ổn định; không phụ thuộc CSS class generated.
- Với UI change, nếu có dev server/browser, phải tự mở và test golden path + edge cases trước khi báo xong.

## Visual regression

- Snapshot ảnh chỉ dùng cho component/page có layout quan trọng và baseline review được.
- Tránh snapshot toàn trang quá lớn nếu thay đổi nhỏ.
- Khi snapshot đổi, mô tả lý do đổi và kiểm tra không có diff ngoài ý muốn.

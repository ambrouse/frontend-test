---
name: frontend-design-skill
description: Bộ skill tư duy thiết kế frontend dùng chung: rõ ràng, dữ liệu thật, màu sạch, card có chủ đích, responsive theo giai đoạn và accessibility.
argument-hint: "frontend design task"
user-invocable: true
---

# Frontend Design Skill

Bộ skill này ghi lại tư duy thiết kế frontend có thể dùng lại cho nhiều dự án. Không xem đây là checklist cố định cho một website cụ thể; hãy áp dụng theo ngữ cảnh sản phẩm, dữ liệu thật và mục tiêu người dùng.

## Các skill thành phần

- `frontend-design-core`: Tư duy cốt lõi: rõ ràng trước, đẹp sau; dữ liệu thật trước, demo sau; hành động chính phải dễ hiểu.
- `frontend-style-skill`: Phong cách visual: chọn mood có chủ đích, giữ độ chuyên nghiệp, tránh trang trí gây nhiễu.
- `frontend-color-skill`: Màu sắc: palette sạch, nền có chiều sâu nhưng không bẩn/neon quá tay, contrast đủ ở cả light/dark.
- `frontend-layout-skill`: Layout: hierarchy, grid, spacing, responsive theo từng giai đoạn thay vì chỉ scale nhỏ.
- `frontend-typography-skill`: Typography: chữ ngắn, có ích, scale tinh tế, metadata vừa đủ.
- `frontend-interaction-accessibility-skill`: Interaction/accessibility: state rõ, focus không mất, icon link có accessible name, motion nhẹ.

## Nguyên tắc chung

- Rõ ràng trước, đẹp sau.
- Phân cấp trước, trang trí sau.
- Dữ liệu thật trước, mockup đẹp sau.
- Mỗi card/container phải có lý do tồn tại; nếu chỉ làm nặng UI thì bỏ.
- Search/filter là công cụ thao tác, cần gọn, nhanh, không thô hoặc chiếm spotlight.
- Responsive phải có thiết kế riêng cho desktop, tablet và mobile; không chỉ dùng `clamp()` hoặc stack mọi thứ.
- Light mode cần sạch và cao cấp như dark mode, không dùng xám xanh bẩn hoặc glow neon tùy tiện.
- Motion chỉ dùng để báo trạng thái hoặc tạo nhịp nhẹ, không dùng để khoe hiệu ứng.

## Cách dùng

1. Xác định người dùng cần hiểu gì và bấm gì trước.
2. Kiểm tra dữ liệu thật có thể thiếu gì: ảnh, title, metadata, trạng thái, link.
3. Thiết kế layout/card để vẫn đẹp khi dữ liệu thiếu.
4. Chọn màu và background theo mood của sản phẩm, tránh hiệu ứng đang hot nhưng không hợp.
5. Kiểm tra breakpoint bằng tư duy bố cục riêng, không chỉ co nhỏ desktop.
6. Kiểm tra accessibility, focus, contrast và reduced motion trước khi coi là xong.

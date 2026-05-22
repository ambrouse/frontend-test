---
name: frontend-design-core
description: Tư duy thiết kế frontend cốt lõi dùng chung: rõ ràng, dữ liệu thật, hierarchy, hành động chính và tránh trang trí rỗng.
argument-hint: "frontend design task"
user-invocable: true
---

# Frontend Design Core

## Tư duy cốt lõi

Frontend tốt phải giúp người dùng hiểu nhanh: đây là gì, thông tin nào quan trọng, trạng thái hiện tại ra sao và họ nên làm gì tiếp theo. Giao diện đẹp nhưng không giúp hiểu hoặc hành động thì chưa tốt.

## Nguyên tắc ưu tiên

1. Rõ ràng trước, đẹp sau.
2. Nội dung thật trước, hiệu ứng sau.
3. Hierarchy trước, decoration sau.
4. State thật trước, screenshot đẹp sau.
5. Accessibility là yêu cầu gốc, không phải phần cộng thêm.

## Dữ liệu thật và trạng thái thiếu

- Thiết kế phải chịu được dữ liệu thiếu: ảnh lỗi, title dài, metadata trống, danh sách ít/nhiều item.
- Nếu dùng ảnh trong card/banner, luôn cần fallback visual cùng hệ thiết kế.
- Không để broken image, empty card hoặc container rỗng phá layout.
- Không thêm tag, badge, label hoặc mô tả nếu chúng không giúp người dùng hiểu hoặc quyết định.

## Container và component

- Mỗi container phải có vai trò rõ: nhóm thông tin, tạo hierarchy hoặc hỗ trợ thao tác.
- Nếu container chỉ làm UI nặng, tạo cảm giác thô hoặc lặp lại thông tin, nên bỏ hoặc biến thành metadata nhẹ.
- Card nên có một điểm đọc chính, một nhóm metadata phụ và một hành động rõ.
- CTA/action phải khác về priority; link phụ không nên tranh spotlight với hành động chính.

## Checklist hoàn thành

- Người dùng hiểu được màn hình trong vài giây.
- Action chính dễ thấy và dễ bấm.
- Dữ liệu thiếu không làm UI hỏng.
- Không có chữ, tag, badge hoặc container rỗng chỉ để trang trí.
- Light/dark, desktop/mobile và focus state đều kiểm tra được.

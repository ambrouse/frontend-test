---
name: frontend-interaction-accessibility-skill
description: Tư duy interaction/accessibility frontend dùng chung: state rõ, icon link đúng, fallback tốt, motion nhẹ, focus và reduced motion.
argument-hint: "frontend interaction accessibility task"
user-invocable: true
---

# Frontend Interaction Accessibility Skill

## Tư duy interaction

Interaction phải cho người dùng biết cái gì bấm được, cái gì đang active, cái gì đang lỗi và điều gì vừa thay đổi. Motion/state dùng để hỗ trợ hiểu, không dùng để khoe hiệu ứng.

## Link, button và icon

- Icon-only action phải có `aria-label` và `title` khi phù hợp.
- Icon cần cùng style, cùng stroke/size và căn giữa trong hit area.
- Link phụ nên nhỏ gọn nhưng vẫn đủ hit area và focus state.
- CTA chính phải rõ hơn link phụ bằng màu, vị trí hoặc weight.
- Không dùng icon lệch màu/hệ nếu nó làm action trông như lỗi visual.

## State và fallback

- Loading, empty, error và fallback phải là trạng thái được thiết kế, không phải phần thừa.
- Ảnh/media lỗi phải có fallback để layout không vỡ.
- Khi thử nhiều asset candidate, lỗi từng asset không được hiện broken image lâu hoặc phá card.
- State active/selected/focused phải nhận ra được bằng nhiều tín hiệu, không chỉ màu.

## Motion

- Motion nên nhẹ, ngắn và có mục đích: báo active, chuyển theme, hover, loading hoặc trạng thái đang hoạt động.
- Pulse/glow không được quá mạnh hoặc lệch palette.
- Background animation không nên tranh spotlight với nội dung.
- Luôn tôn trọng `prefers-reduced-motion`.

## Accessibility baseline

- Semantic HTML trước ARIA phức tạp.
- Focus state không được bị xóa khi custom style.
- Decorative image/canvas dùng `aria-hidden="true"` hoặc `alt=""` đúng ngữ cảnh.
- Form/search/filter cần label hoặc accessible name rõ.
- Contact/action external cần href đúng loại (`mailto:`, `tel:`, URL hợp lệ).
- QR hoặc mã liên hệ phải là dữ liệu thật và có link tương ứng; không dùng QR giả chỉ để trang trí.

## Checklist hoàn thành

- Action nào bấm được đều rõ và keyboard focus được.
- Icon-only link có accessible name.
- Media lỗi vẫn có fallback đẹp.
- Motion nhẹ, không gây nhiễu và có reduced-motion.
- Color/hover/focus state đủ contrast ở light và dark mode.

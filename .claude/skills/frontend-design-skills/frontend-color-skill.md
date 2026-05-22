---
name: frontend-color-skill
description: Tư duy màu frontend dùng chung: palette sạch, contrast rõ, background có chiều sâu, tránh neon/glow quá tay và màu bẩn.
argument-hint: "frontend color task"
user-invocable: true
---

# Frontend Color Skill

## Tư duy màu

Màu phải phục vụ nhận diện, hierarchy và readability. Không dùng màu vì trend hoặc vì hiệu ứng nhìn nổi ở screenshot nhưng mệt khi dùng thật.

## Palette

- Chọn base trước: neutral sáng, warm neutral, xanh đen, navy, graphite, v.v.
- Accent chỉ nên có vai trò rõ: CTA, trạng thái, focus, điểm nhấn dữ liệu.
- Light mode không được là bản “giảm sáng” của dark mode; cần palette riêng đủ sạch.
- Dark mode không đồng nghĩa với neon; glow quá mạnh dễ làm UI rẻ và nhiễu.
- Tránh nền xám xanh bẩn nếu không có chủ đích thương hiệu rõ.

## Background

- Background nên tạo chiều sâu bằng layer mềm: linear gradient, subtle texture, grid nhẹ hoặc radial rất tiết chế.
- Không lạm dụng đốm neon/radial glow nhiều màu vì dễ làm nền rối và quê.
- Nếu có glow, dùng như ánh sáng môi trường, không như các đốm trang trí nổi bật.
- Nền phải đẹp cả khi không có ảnh/banner hỗ trợ.

## Card và surface

- Surface phải tách khỏi nền bằng contrast, border và shadow vừa đủ.
- Shadow light mode nên sạch, không đen nặng.
- Border cần hỗ trợ structure, không biến thành khung thô.
- Ảnh/banner overlay phải hòa vào card nhưng không che mất ảnh.
- Fallback visual nên cùng hệ màu với trang, không dùng màu random.

## Semantic color và CTA

- Màu CTA chính phải nổi hơn link phụ.
- Link/icon phụ nên tinh tế, nhỏ và đúng màu hệ thống.
- Trạng thái hoạt động có thể dùng pulse/glow nhẹ, nhưng không được lệch palette.
- Error/success/warning phải đủ phân biệt và đủ contrast.

## Checklist hoàn thành

- Light mode sạch, không bẩn hoặc bạc màu.
- Dark mode sâu nhưng không neon quá tay.
- Background không tranh spotlight với nội dung.
- CTA nổi đúng mức, link phụ không quá thô.
- Card/fallback/ảnh cùng một hệ màu.
- Contrast text, icon, focus state đủ dùng.

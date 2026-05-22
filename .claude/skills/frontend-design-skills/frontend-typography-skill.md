---
name: frontend-typography-skill
description: Tư duy typography frontend dùng chung: hierarchy rõ, chữ ngắn có ích, font scale tinh tế, metadata vừa đủ và mobile không quá to.
argument-hint: "frontend typography task"
user-invocable: true
---

# Frontend Typography Skill

## Tư duy chữ

Typography không chỉ là chọn font. Nó quyết định tốc độ đọc, cảm giác chuyên nghiệp và mức độ tin cậy của UI. Chữ phải giúp người dùng hiểu nhanh, không phải lấp đầy khoảng trống.

## Voice & content

- Viết ngắn, rõ, có thông tin thật.
- Bỏ câu mô tả chung chung nếu không giúp hiểu sản phẩm, dữ liệu hoặc hành động.
- Không phóng đại nếu UI không có bằng chứng hỗ trợ.
- Metadata chỉ giữ những gì giúp scan, so sánh hoặc ra quyết định.
- Label/tag/category chỉ nên xuất hiện khi có vai trò thật trong hierarchy hoặc filter.

## Type hierarchy

- Heading định vị màn hình, không cần luôn cực lớn.
- Lead text chỉ dùng khi nó giải thích điều heading chưa nói.
- Card title phải đọc nhanh, không bị metadata hoặc badge lấn át.
- Body/summary nên trả lời: đây là gì, vì sao quan trọng, người dùng có thể làm gì.
- Microcopy của button, empty state và error state phải cụ thể.

## Font scale

- Desktop có thể dùng heading lớn nếu tạo được nhịp thị giác.
- Tablet cần giảm scale và line-height để tránh cảm giác bị ép layout.
- Mobile cần font tinh tế hơn, không giữ hero desktop thu nhỏ bằng viewport unit quá lớn.
- Tránh `vw` quá mạnh làm chữ mobile phình và thiếu cao cấp.
- Letter spacing âm chỉ nên dùng cho heading lớn; text nhỏ cần readability trước.

## Checklist hoàn thành

- Người dùng đọc được nội dung chính trong vài giây.
- Không có câu rỗng chỉ để làm đầy card/section.
- Heading, metadata và action có thứ bậc rõ.
- Mobile font không quá to hoặc thô.
- Text dài/thiếu dữ liệu không phá layout.

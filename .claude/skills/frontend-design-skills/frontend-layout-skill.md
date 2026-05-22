---
name: frontend-layout-skill
description: Tư duy layout frontend dùng chung: hierarchy, grid, spacing, card structure, search/filter và responsive theo từng giai đoạn.
argument-hint: "frontend layout task"
user-invocable: true
---

# Frontend Layout Skill

## Tư duy layout

Layout là cách dẫn mắt và giảm công sức đọc. Không chỉ là chia cột; nó quyết định thứ gì được hiểu trước, thứ gì là phụ và hành động nào dễ dùng nhất.

## Hierarchy và spacing

- Màn hình cần một điểm bắt đầu rõ: hero, title, search, data summary hoặc action chính.
- Spacing phải tạo nhóm thông tin, không chỉ làm rộng/thoáng.
- Container chỉ dùng khi cần nhóm nội dung hoặc tạo priority; container thừa làm UI thô.
- Grid nên theo dữ liệu thật: ít item, nhiều item, title dài, ảnh thiếu, state loading/error.

## Card layout

- Card cần form ổn định và dễ scan.
- Media/banner nếu là phần chính thì cần tỷ lệ cố định theo ý đồ hiển thị, không để mỗi ảnh tự kéo card lệch nhau.
- Ảnh trong card nên crop/fade theo hệ nền tổng để hỗ trợ nội dung, không trở thành mảng ảnh thô gây rối.
- Metadata nên nhỏ, gần nội dung liên quan và không tranh với title.
- Action chính/phụ phải đặt có chủ đích; icon nhỏ cần căn giữa và hit area đủ.
- Không nhồi tag/category nếu chưa có vai trò filter hoặc hierarchy thật.

## Search/filter layout

- Search/filter là công cụ thao tác, không phải hero thứ hai.
- Search bar nên gọn, nhẹ, focus rõ, không dùng border/padding quá nặng.
- Filter nên đọc được nhanh: nhóm cùng hàng ở desktop, chuyển thành cụm compact ở tablet/mobile.
- Khi filter nhiều, cần hierarchy: search trước, filter phụ sau.

## Responsive theo giai đoạn

Không chỉ stack mọi thứ hoặc dùng font `clamp()` lớn. Mỗi breakpoint cần thiết kế riêng:

- Desktop: tận dụng grid rộng, sidebar/aside nếu thật sự có giá trị.
- Tablet: giảm density, gom nhóm filter/action, giữ card đủ rộng.
- Mobile: ưu tiên một cột rõ, heading nhỏ hơn, action dễ bấm, bỏ container phụ nếu gây nặng.
- Small mobile: giảm font, spacing và card height có chủ đích; không giữ hero desktop thu nhỏ.

## Checklist hoàn thành

- Người dùng biết đọc từ đâu trước.
- Container nào cũng có lý do tồn tại.
- Card không vỡ khi thiếu ảnh hoặc text dài.
- Search/filter gọn và dễ dùng.
- Desktop/tablet/mobile có bố cục riêng, không chỉ scale.

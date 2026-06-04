# Kiểm chứng màu nút và chip của Hub

Phạm vi: kiểm tra nút CTA và pill trạng thái của Hub sau khi đồng bộ bảng màu cho light mode và dark mode.

Môi trường chạy: `http://localhost:6901/hub` trên dev server Next.js đang có sẵn.

Các điểm đã kiểm:
- Light theme: CTA của banner, action trong card và pill trạng thái không còn dùng nền trắng/xám lệch tông trên ảnh.
- Dark theme: CTA dùng cyan rõ hơn, pill trạng thái dùng dark glass đồng bộ với nền.
- Pill trạng thái ở shortcut và chip trong card vẫn đọc rõ, không làm lệch layout.

Bằng chứng:
- [Hub light mode](app/01-light-hub-controls.png)
- [Banner light mode](app/02-light-feature-card-controls.png)
- [Hub dark mode](app/03-dark-hub-controls.png)
- [Banner dark mode](app/04-dark-feature-card-controls.png)

Kết quả: đạt.

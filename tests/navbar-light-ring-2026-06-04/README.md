# Kiểm chứng vòng viền navbar light mode

Phạm vi: kiểm tra animation vòng viền navbar ở light mode cho cả dock dọc desktop và dock ngang mobile sau khi tăng độ tương phản.

Môi trường chạy: `http://localhost:6901/` trên dev server Next.js đang có sẵn.

Các điểm đã kiểm:
- Dock desktop light mode: vòng hover/active rõ trên nền trắng.
- Nút đổi theme light mode dùng cùng xử lý vòng viền rõ hơn.
- Navbar ngang mobile light mode giữ vòng viền rõ và không lệch layout.
- Dock desktop dark mode vẫn giữ cảm giác vòng viền cũ.

Bằng chứng:
- [Dock desktop light mode](app/01-light-desktop-dock-hub-hover.png)
- [Theme toggle light mode](app/02-light-desktop-theme-hover.png)
- [Navbar ngang mobile light mode](app/03-light-mobile-navbar-hub-hover.png)
- [Dock desktop dark mode](app/04-dark-desktop-dock-hub-hover.png)

Kết quả: đạt.

# Bằng chứng dọn CSS navbar shell - 2026-06-04

## Phạm vi

- Chuyển style của shell, dock navigation và nút đổi theme vào `frontend/src/styles/shell.css`.
- Gỡ các lớp override cũ bị chồng trong `frontend/src/styles/globals.css`.
- Giữ nút dock và theme toggle light mode dùng cùng hình học vòng khuyết với dark mode.

## Bằng chứng

- `01-dark-theme-hover.png` đến `04-dark-settings-hover.png`: ảnh cận cảnh hover ở dark mode.
- `05-light-theme-hover.png` đến `08-light-settings-hover.png`: ảnh cận cảnh hover ở light mode.
- `09-light-settings-panel.png` và `10-dark-settings-panel.png`: kiểm tra nhanh panel cài đặt sau khi dọn CSS.
- `layout-regression/07-hub-desktop-no-overflow-fixed-nav.png`: Hub desktop có navbar trái cố định và không tràn ngang.
- `layout-regression/08-hub-scroll-no-overflow-fixed-nav.png`: trang đã cuộn, chứng minh navbar vẫn cố định.
- `spin-proof/hub-hover-040ms.png` đến `spin-proof/hub-hover-880ms.png`: chuỗi ảnh kiểm tra chuyển động vòng hover.

## Kiểm chứng

- `npm run build` đã đạt.
- `npm run typecheck` đã đạt sau khi build tạo lại `.next/types`.
- Ảnh Playwright dùng khóa localStorage thật `ai-hub-theme` và chờ `document.documentElement.dataset.theme`.
- Kết quả kiểm tra bằng mắt: dock trái cố định, nội dung không tràn ngang, animation navbar giữ thời lượng khoảng `0.38s`.

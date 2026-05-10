# AI Hub Frontend Documentation

Ngày cập nhật: 2026-05-10

## Tổng quan

Đã khởi tạo frontend bằng Next.js 16.2.6, React 19.2.6 và TypeScript cho dự án AI Hub. App hiện chạy bằng mock data để mô phỏng phần cứng, provider/project, compatibility ping, benchmark, task đang chạy và logs.

## Màn hình đã có

- Home: command-center hiển thị GPU/VRAM/CPU/RAM/disk/nhiệt độ, task đang chạy, gợi ý capacity và activity gần đây.
- Hub: danh sách provider dạng bento/masonry, có search, filter theo loại project, card có ping xanh/vàng/đỏ.
- Hub Detail: trang chi tiết từng project, có requirement fit, benchmark gần nhất, quick config, logs filter và action Run/Stop/Install/Delete mock.

## Kiến trúc frontend

- `src/app`: Next.js App Router routes.
- `src/components`: UI components theo từng domain.
- `src/services`: type definitions, mock data, compatibility logic.
- `src/utils`: helper format dữ liệu.
- `src/styles/globals.css`: design tokens, theme dark/light, layout và responsive CSS.
- `tests`: Vitest setup và unit tests.

## Theme và visual direction

- Dark-first, nền graphite nhiều tầng surface, không dùng pure black làm nền chính.
- Light mode có token riêng và giữ cùng cấu trúc thị giác.
- Layout ưu tiên cockpit/bento/rail để tránh cảm giác dashboard card đều đều.
- Compatibility dùng status rõ: green `Fit`, yellow `Warn`, red `Block`.

## Kiểm thử

- `npm.cmd run typecheck`: pass.
- `npm.cmd run test`: pass, 3 tests cho compatibility logic.
- `npm.cmd run build`: pass, Next prerender được `/`, `/hub`, và các route detail.

## Ghi chú

- Repo hiện chưa phải git repository.
- Không tìm thấy `testing-skill` trong `.github/skills`, nên phần test dùng Vitest/Testing Library theo plan.
- `npm install` báo 7 moderate vulnerabilities từ dependency tree; chưa chạy `npm audit fix --force` vì có rủi ro nâng breaking.

## Cập nhật 2026-05-10

- Thêm theme transition dạng ripple lan từ nút theme, kèm stagger animation cho các container.
- Chuyển Hub banner thành carousel project nổi bật, tự shuffle sau khi load và auto rotate.
- Thêm background asset riêng cho từng project trong `public/assets/projects`, dùng overlay/tint để hòa với dark/light theme.
- Detail banner đã bỏ description/repo line trong hero, chỉ giữ tên project và meta/action ngắn.

## Cập nhật 2026-05-10 lần 2

- Thay project banner từ SVG abstract sang ảnh thật `.jpg` local.
- Xóa panel phụ trong carousel, giữ chữ chính và để ảnh/tint xử lý khoảng trống.
- Body background đổi theo project đang active trong carousel hoặc detail.
- Viết lại theme transition: container bloom từ giữa ra trước, root theme commit sau để tránh cảm giác trang đổi rời rạc.

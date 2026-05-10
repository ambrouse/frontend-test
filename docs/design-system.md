# AI Hub Design System Notes

Ngày cập nhật: 2026-05-10

## Token chính

- Background: graphite/ink, light mode dùng pale grey.
- Surface: translucent smoked surfaces với border mảnh.
- Accent: cyan/teal cho primary system state, amber cho warning/highlight.
- Status: mint green, amber yellow, coral red.
- Radius: nhỏ vừa phải, card/panel tối đa theo `--radius-lg`.

## Nguyên tắc layout

- Home dùng hardware cockpit, không dùng table/card grid thuần.
- Hub dùng bento grid có nhịp card khác nhau.
- Detail dùng split information: hero action, requirement fit, benchmark, config, logs terminal.
- Mobile chuyển dock xuống đáy để thao tác nhanh.

## Motion/accessibility

- Transition ngắn 180ms cho hover/focus.
- Có `prefers-reduced-motion` để giảm motion.
- Button icon có `aria-label` khi cần.
- Text dùng kích thước cố định/responsive bằng clamp, không scale trực tiếp theo viewport width.

## Project visuals

- Mỗi project có background asset riêng, hiện dùng ảnh thật đã lưu local.
- Banner luôn phủ tint theo `accentColor` và lớp overlay tối/sáng để ảnh không lệch khỏi visual system.
- Theme switch dùng ripple từ nút theme và container sweep animation để người dùng thấy rõ đổi mode.

## Cập nhật project visuals 2026-05-10

- Đã thay abstract background bằng ảnh thật lưu local trong `public/assets/projects`.
- Ảnh thật được phủ nhiều lớp gradient/tint theo màu project, không render raw trực tiếp.
- Body nhận `--page-image`, `--page-accent`, `--page-accent-soft` từ carousel/detail để nền trang hòa với banner hiện tại.
- Theme switch đổi sang container-first bloom: mỗi container wash màu target từ giữa ra, sau đó root theme mới commit.

## Cập nhật motion và light theme 2026-05-10

- Thêm route enter animation bằng `key={pathname}` trên main stage, thời lượng ngắn để không tạo cảm giác chờ.
- Thêm surface/card enter animation nhẹ, stagger tối đa 48ms.
- Tune lại light theme theo hướng xanh-xám/teal mềm hơn, giảm cảm giác trắng phẳng.
- Project card có lớp ảnh thật tint nhẹ phía trong card để card có chiều sâu hơn ở cả dark/light.
- Body ambient được tăng độ hiện diện bằng project image và radial tint rõ hơn.

## Light Theme Contrast Pass 2026-05-10

- Light palette chuyển sang nền xanh-xám ít chói hơn.
- Navbar light mode có surface, border và shadow rõ hơn để không chìm.
- Banner/detail light mode dùng overlay sáng phía text để chữ giữ tương phản trên ảnh.
- Card image layer ở light mode giảm opacity/saturation để tránh lóa và giữ text dễ đọc.

Nguồn ảnh:

- Pexels server racks/data center: https://www.pexels.com/photo/server-racks-on-data-center-5480781/
- Pexels server room search/download assets: https://www.pexels.com/search/server%20room/
- Pexels modern camera: https://www.pexels.com/photo/modern-camera-gadget-on-windowsill-indoors-13031873/

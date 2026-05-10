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

Nguồn ảnh:

- Pexels server racks/data center: https://www.pexels.com/photo/server-racks-on-data-center-5480781/
- Pexels server room search/download assets: https://www.pexels.com/search/server%20room/
- Pexels modern camera: https://www.pexels.com/photo/modern-camera-gadget-on-windowsill-indoors-13031873/

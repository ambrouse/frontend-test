# Test Logs And Documentation Raw

## Dùng logging-skill

Khi task yêu cầu ghi log phiên làm việc hoặc kết quả test, áp dụng `logging-skill`:

- Lưu task log trong folder tổng `logs` trừ khi user chỉ định khác.
- Log ngắn gọn: thời gian, mục tiêu test, command đã chạy, kết quả, blocker, rủi ro còn lại.
- Không ghi secret, token, password, PII, payload production hoặc stack trace nhạy cảm.
- Nếu nhiều log liên quan, gom và tóm tắt để tránh noise.

## Dùng documentation-skill

Khi test làm thay đổi cách vận hành, API contract, QA checklist hoặc hướng dẫn release, áp dụng `documentation-skill`:

- Cập nhật docs trong folder tổng `docs` trừ khi user chỉ định khác.
- Docs phải nêu phạm vi, cách chạy test, cấu hình cần có và giới hạn.
- Không tạo docs mới nếu thông tin phù hợp với file hiện có.
- Sau khi cập nhật, kiểm tra docs không bị lỗi thời hoặc overclaim so với test thực tế.

## Báo cáo cuối task

- Nêu test đã chạy và kết quả.
- Nêu test chưa chạy được và lý do.
- Nêu rủi ro còn lại nếu có.
- Không nói “production ready” nếu chưa có đủ evidence từ test, review và môi trường phù hợp.

# Testing Review Checklist Raw

## Trước khi hoàn thành

- [ ] Test mới kiểm hành vi quan trọng, không chỉ implementation detail.
- [ ] Có golden path và negative/error case phù hợp.
- [ ] Bugfix có regression test hoặc lý do rõ nếu không thể tự động hóa.
- [ ] Auth/permission/data boundary được test nếu thay đổi liên quan.
- [ ] Test deterministic, không phụ thuộc sleep/network/time thật nếu không cần.
- [ ] Không có secret/PII trong fixture, snapshot, log, report.
- [ ] Đã chạy command test liên quan và lưu ý kết quả.
- [ ] Nếu có UI change, đã kiểm bằng browser/dev server khi có thể.
- [ ] Nếu có performance risk, đã benchmark hoặc nêu rõ lý do chưa benchmark.
- [ ] Nếu cần docs/logs, đã dùng `documentation-skill` và `logging-skill`.

## Khi test fail

- Đọc lỗi để xác định root cause.
- Không bypass hook/test.
- Không sửa expectation nếu behavior đúng là đang sai.
- Nếu fail do test cũ lỗi thời vì requirement đổi, cập nhật test cùng explanation ngắn.

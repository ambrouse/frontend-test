# Benchmark And Evaluation Raw

## Khi cần benchmark

- Thay đổi query, rendering list lớn, algorithm, caching, serialization, file processing, startup, build hoặc hot path.
- User yêu cầu performance hoặc có regression nghi ngờ.
- Code ảnh hưởng endpoint/page critical trong production.

## Cách benchmark

- Xác định metric trước: latency p50/p95/p99, throughput, memory, CPU, bundle size, render time, query count.
- Có baseline trước và sau nếu có thể.
- Dữ liệu benchmark phải đại diện: small, typical, large, worst practical.
- Chạy đủ vòng warmup/iteration; loại bỏ kết quả nhiễu rõ ràng.
- Không dùng kết quả benchmark từ môi trường không tương đương để overclaim production.

## Đánh giá kết quả

- Báo delta, điều kiện chạy, command, dataset, số lần chạy và giới hạn đo.
- Nếu performance giảm, giải thích tradeoff hoặc sửa trước khi hoàn thành.
- Với frontend, kiểm bundle size, hydration/render cost hoặc interaction latency nếu thay đổi ảnh hưởng UX.
- Với backend, kiểm query plan/query count khi thay đổi database path.

## Quality gate

- Benchmark pass khi không có regression đáng kể trên metric đã chọn hoặc regression được user chấp nhận.
- Nếu không thể benchmark, ghi rõ lý do và đề xuất cách verify thủ công/CI.

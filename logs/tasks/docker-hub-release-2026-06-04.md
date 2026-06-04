# Log Công Việc: Docker Hub Release - 2026-06-04

## Bối Cảnh

Người dùng yêu cầu cập nhật phiên bản mới cho Docker Hub và chạy thử lựa chọn cài đặt bằng Docker 100%.

## Việc Đang Làm

- Kiểm tra repo hiện có: chưa có Dockerfile app, chỉ có compose Nginx gateway.
- Kiểm tra Docker daemon local: Docker Desktop đang chạy với Linux engine.
- Kiểm tra Docker Hub namespace `ambrouse`: chưa có repo `ai-hub` public trước task này.
- Thiết kế image `ambrouse/ai-hub:0.1.1` chạy frontend Next standalone và backend FastAPI trong cùng container.

## Kiểm Chứng Đã Chạy

- `docker build -t ambrouse/ai-hub:0.1.1 -t ambrouse/ai-hub:latest .`: đạt sau khi bỏ copy `deploy/.gitkeep` khỏi Dockerfile.
- `docker run -d --name ai-hub-docker-test -p 6911:6901 -p 6912:6902 ambrouse/ai-hub:0.1.1`: container healthy.
- `http://localhost:6912/api/health`: trả `ok = true`.
- `http://localhost:6911`: HTTP 200, có HTML frontend.
- `http://localhost:6912/api/providers`: trả `total = 8`.
- `docker compose -f docker-compose.hub.yml up -d --no-build` với host port `6913/6914`: container healthy.
- `http://localhost:6914/api/health`: trả `ok = true`.
- `http://localhost:6913`: HTTP 200, có HTML frontend.

## Trạng Thái Push Docker Hub

- `docker push ambrouse/ai-hub:0.1.1` fail với `insufficient_scope`.
- Docker config local dùng `credsStore: desktop`, nhưng push không có quyền ghi repo `ambrouse/ai-hub`.
- Cần login Docker Hub bằng tài khoản có quyền namespace `ambrouse` hoặc tạo repo `ai-hub` trước, rồi chạy lại push tag `0.1.1` và `latest`.

## Cleanup

- Đã dừng container test `ai-hub-docker-test`.
- Đã dừng stack compose test và xóa volume test.

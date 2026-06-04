# Docker Hub Release - 2026-06-04

## Phạm Vi

Tạo đường cài đặt AI Hub bằng Docker 100%, phát hành image `baonguyen3568/ai-hub:0.1.1` và kiểm thử bằng container sạch.

## Thay Đổi

- Thêm `Dockerfile` multi-stage.
- Thêm `.dockerignore` để loại cache, môi trường local, evidence và log khỏi build context.
- Thêm `docker-entrypoint.sh` chạy backend FastAPI và frontend Next standalone trong cùng container.
- Thêm `docker-compose.hub.yml` dùng image Docker Hub, không build từ source local.
- Bump version frontend, backend và FastAPI app lên `0.1.1`.
- README có thêm mục cài bằng Docker Hub.

## Cách Chạy

```bash
docker run --rm --name ai-hub -p 6901:6901 -p 6902:6902 baonguyen3568/ai-hub:0.1.1
```

Hoặc:

```bash
docker compose -f docker-compose.hub.yml up -d
```

## Kiểm Chứng Đã Chạy

- `docker build -t baonguyen3568/ai-hub:0.1.1 -t baonguyen3568/ai-hub:latest .`: đạt.
- `docker run -d --name ai-hub-docker-test -p 6911:6901 -p 6912:6902 baonguyen3568/ai-hub:0.1.1`: container healthy.
- `http://localhost:6912/api/health`: trả `{"ok": true}`.
- `http://localhost:6911`: trả HTTP 200.
- `http://localhost:6912/api/providers`: trả `total = 8`.
- `docker compose -f docker-compose.hub.yml up -d --no-build` với host port `6913/6914`: container healthy.
- `http://localhost:6914/api/health`: trả `{"ok": true}`.
- `http://localhost:6913`: trả HTTP 200.

## Trạng Thái Docker Hub

- Namespace phát hành đã chuyển sang `baonguyen3568`.
- Đã push thành công:

```bash
docker push baonguyen3568/ai-hub:0.1.1
docker push baonguyen3568/ai-hub:latest
```

- Docker Hub API xác nhận tag `0.1.1` và `latest` cùng digest `sha256:0be9171fe0c67a89a0fceab908d51fed48cf38e067ef6a8a123a857aa69a91c2`.
- Smoke test sau push bằng `baonguyen3568/ai-hub:0.1.1`: container healthy, frontend HTTP 200, backend `/api/health` trả `ok=true`, `/api/providers` trả `total=8`.

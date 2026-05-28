# Setup Port 6900 Autostart - 2026-05-28

## Thoi gian

- Bat dau: 2026-05-28 15:xx Asia/Ho_Chi_Minh
- Hoan thanh: 2026-05-28 15:43 Asia/Ho_Chi_Minh

## Noi dung

- Fix `setup.sh` khong tu mo web: script gio cai dependency, seed provider, start backend, frontend va nginx gateway.
- Chuyen Hub sang port mac dinh trong dai 6900-6950:
  - Gateway: `6900`
  - Frontend: `6901`
  - Backend: `6902`
- Chuyen provider default/runtime config sang dai `6903-6938` de tranh port cu nhu `3000`, `8000`, `8080`.
- Them log/PID cho Hub tai `logs/hub/backend.log`, `logs/hub/frontend.log`, `logs/hub/nginx.log`.
- Cap nhat `stop.sh` de dung dung PID/log moi va cac port mac dinh moi.
- Cap nhat README/docs lien quan den setup va nginx gateway.

## Kiem tra

- `bash -n setup.sh stop.sh providers/_shared/linux-provider-dispatch.sh`
- `find providers -path '*/scripts/linux/*.sh' -print0 | xargs -0 -n1 bash -n`
- `./.venv/bin/python -m pytest backend/tests/test_api_contract.py backend/tests/test_provider_lifecycle.py`
- `npm run typecheck --prefix frontend`
- `docker compose -f docker-compose.nginx.yml config -q`
- `./.venv/bin/python backend/scripts/validate_providers.py`
- `printf '\n' | ./setup.sh`
- Smoke:
  - `http://127.0.0.1:6902/api/health` returned `{"ok":true}`
  - `http://127.0.0.1:6901` returned HTTP 200
  - `http://127.0.0.1:6900` returned HTTP 200
  - `http://192.168.2.182:6900` returned HTTP 200

## Ket qua

- Hub dang chay tren `0.0.0.0:6901`, `0.0.0.0:6902`, va gateway Docker `0.0.0.0:6900`.
- LAN URL dung de mo tu may khac cung mang: `http://192.168.2.182:6900`.

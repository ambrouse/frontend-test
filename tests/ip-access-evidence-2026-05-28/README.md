# IP Access Evidence - 2026-05-28

Checked `http://192.168.2.182:8080/hub` through the Docker-managed Nginx gateway.

- `/api/providers/summary`: `200`, `ready: 8`
- `/api/providers`: `200`
- `/api/providers/featured`: `200`
- `/_next/webpack-hmr`: `101` after the Nginx HMR route fix
- UI proof: `hub-ip-providers.png`

# AI Hub Nginx Gateway

This gateway lets one Docker-managed Nginx endpoint serve the Hub frontend and backend through the same origin.

## Local Dev

Start the Hub backend on `8000` and frontend on `3000`, then run:

```bash
docker compose -f docker-compose.nginx.yml up -d
```

Open `http://localhost:8080`.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `AIHUB_NGINX_PORT` | `8080` | Host port exposed by Docker. Use `80` for a standard HTTP endpoint. |
| `AIHUB_FRONTEND_UPSTREAM` | `host.docker.internal:3000` | Frontend upstream. Later this can become a compose service name such as `frontend:3000`. |
| `AIHUB_BACKEND_UPSTREAM` | `host.docker.internal:8000` | Backend upstream. Later this can become `backend:8000`. |
| `AIHUB_CLIENT_MAX_BODY_SIZE` | `100m` | Upload limit for provider assets and test artifacts. |

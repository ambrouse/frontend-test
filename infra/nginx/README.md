# AI Hub Nginx Gateway

This gateway lets one Docker-managed Nginx endpoint serve the Hub frontend and backend through the same origin.

## Local Dev

Start the Hub backend on `6902` and frontend on `6901`, then run:

```bash
docker compose -f docker-compose.nginx.yml up -d
```

Open `http://localhost:6900`.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `AIHUB_NGINX_PORT` | `6900` | Host port exposed by Docker. Use `80` for a standard HTTP endpoint. |
| `AIHUB_FRONTEND_UPSTREAM` | `host.docker.internal:6901` | Frontend upstream. Later this can become a compose service name such as `frontend:6901`. |
| `AIHUB_BACKEND_UPSTREAM` | `host.docker.internal:6902` | Backend upstream. Later this can become `backend:6902`. |
| `AIHUB_CLIENT_MAX_BODY_SIZE` | `100m` | Upload limit for provider assets and test artifacts. |

The template resolves upstreams through Docker DNS with IPv6 disabled. Docker Desktop can publish an unreachable IPv6 address for `host.docker.internal`; forcing IPv4 resolution avoids intermittent `Network unreachable` gateway errors while keeping the default upstream host portable.

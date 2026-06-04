# syntax=docker/dockerfile:1.7

FROM node:22-bookworm-slim AS frontend-builder

WORKDIR /build/frontend
ENV NEXT_TELEMETRY_DISABLED=1
ENV API_PROXY_HOST=127.0.0.1
ENV API_PROXY_PORT=6902

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
RUN npm run build

FROM node:22-bookworm-slim AS runtime

LABEL org.opencontainers.image.title="AI Hub"
LABEL org.opencontainers.image.description="Local AI provider control center with FastAPI backend and Next.js frontend."
LABEL org.opencontainers.image.source="https://github.com/ambrouse/frontend-test"
LABEL org.opencontainers.image.version="0.1.1"

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV AIHUB_FRONTEND_PORT=6901
ENV AIHUB_BACKEND_PORT=6902
ENV PATH="/opt/venv/bin:${PATH}"

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates curl git python3 python3-venv \
  && rm -rf /var/lib/apt/lists/* \
  && python3 -m venv /opt/venv

COPY backend/ /app/backend/
RUN pip install --no-cache-dir --upgrade pip setuptools \
  && pip install --no-cache-dir -e /app/backend

COPY providers/ /app/providers/
COPY docker-entrypoint.sh /usr/local/bin/aihub-entrypoint
COPY --from=frontend-builder /build/frontend/.next/standalone /app/frontend
COPY --from=frontend-builder /build/frontend/.next/static /app/frontend/.next/static
COPY --from=frontend-builder /build/frontend/public /app/frontend/public

RUN chmod +x /usr/local/bin/aihub-entrypoint \
  && mkdir -p /app/logs/hub /app/deploy

EXPOSE 6901 6902

HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=12 \
  CMD curl -fsS "http://127.0.0.1:${AIHUB_BACKEND_PORT}/api/health" >/dev/null \
  && curl -fsS "http://127.0.0.1:${AIHUB_FRONTEND_PORT}" >/dev/null || exit 1

ENTRYPOINT ["aihub-entrypoint"]

#!/usr/bin/env bash
set -euo pipefail

ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/aiq}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-18080}"
FRONTEND_PORT="${AIHUB_PORT:-13080}"

if [ -f "$DEPLOY_DIR/.runtime/ports.env" ]; then
  # shellcheck disable=SC1090
  source "$DEPLOY_DIR/.runtime/ports.env"
fi

backend_ok=false
frontend_ok=false
curl -fsS "http://127.0.0.1:${BACKEND_PORT}/health" >/dev/null 2>&1 && backend_ok=true
curl -fsS "http://127.0.0.1:${FRONTEND_PORT}" >/dev/null 2>&1 && frontend_ok=true

if [ "$backend_ok" = true ] && [ "$frontend_ok" = true ]; then
  level="ok"; message="AI-Q backend and frontend are healthy"
elif [ "$backend_ok" = true ]; then
  level="warn"; message="AI-Q backend healthy, frontend unavailable"
else
  level="error"; message="AI-Q backend unavailable"
fi

printf '{"level":"%s","message":"%s","backendOk":%s,"frontendOk":%s,"backendPort":%s,"frontendPort":%s,"checkedAt":"%s"}\n' \
  "$level" "$message" "$backend_ok" "$frontend_ok" "$BACKEND_PORT" "$FRONTEND_PORT" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

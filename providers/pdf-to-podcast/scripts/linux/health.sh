#!/usr/bin/env bash
set -euo pipefail

ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/pdf-to-podcast}"
FRONTEND_PORT="${AIHUB_PORT:-7860}"
API_SERVICE_PORT="${API_SERVICE_PORT:-8002}"
if [[ -f "$DEPLOY_DIR/.auto-ports.env" ]]; then
  # shellcheck disable=SC1090
  source "$DEPLOY_DIR/.auto-ports.env"
fi

frontend_ok=false
api_ok=false
curl -fsS "http://127.0.0.1:${FRONTEND_PORT}" >/dev/null 2>&1 && frontend_ok=true
if curl -fsS "http://127.0.0.1:${API_SERVICE_PORT}/health" | grep -q '"healthy"'; then
  api_ok=true
fi

if [[ "$frontend_ok" == "true" && "$api_ok" == "true" ]]; then
  printf '{"ok":true,"level":"ok","frontendPort":%s,"apiPort":%s}\n' "$FRONTEND_PORT" "$API_SERVICE_PORT"
else
  printf '{"ok":false,"level":"error","frontendPort":%s,"apiPort":%s}\n' "$FRONTEND_PORT" "$API_SERVICE_PORT"
fi

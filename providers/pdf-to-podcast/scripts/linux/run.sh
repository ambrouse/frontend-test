#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-pdf-to-podcast}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
PORT="${AIHUB_PORT:-7860}"
API_SERVICE_PORT="${API_SERVICE_PORT:-8002}"

mkdir -p "$ROOT/logs" "$ROOT/runtime"

if [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  if [[ ! -d "$DEPLOY_DIR" ]]; then
    bash "$ROOT/scripts/linux/setup.sh"
  fi
  (cd "$DEPLOY_DIR" && FRONTEND_PORT="$PORT" API_SERVICE_PORT="$API_SERVICE_PORT" bash setup.sh --up)
fi

PORTS_FILE="$DEPLOY_DIR/.auto-ports.env"
FRONTEND_PORT="$PORT"
if [[ -f "$PORTS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$PORTS_FILE"
fi

wait_http() {
  local url="$1" name="$2"
  for _ in $(seq 1 90); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "ERROR: $name did not become ready at $url" >&2
  return 1
}

if [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  wait_http "http://127.0.0.1:${API_SERVICE_PORT}/health" "API health"
  wait_http "http://127.0.0.1:${FRONTEND_PORT}" "Gradio frontend"
fi

PID=""
if [[ -f "$DEPLOY_DIR/frontend/.frontend.pid" ]]; then
  PID="$(cat "$DEPLOY_DIR/frontend/.frontend.pid" || true)"
fi

python - "$ROOT/runtime/status.json" "$ID" "$FRONTEND_PORT" "$API_SERVICE_PORT" "${PID:-}" <<'PY'
import json, sys
from datetime import datetime, timezone

pid = int(sys.argv[5]) if sys.argv[5].isdigit() else None
json.dump({
    "projectId": sys.argv[2],
    "state": "running",
    "pid": pid,
    "port": int(sys.argv[3]),
    "platform": "linux",
    "startedAt": datetime.now(timezone.utc).isoformat(),
    "uptimeSec": 0,
    "currentStep": "Running PDF to Podcast stack",
    "progressPercent": 100,
    "health": {"level": "ok", "message": "Started", "apiPort": int(sys.argv[4])},
}, open(sys.argv[1], "w", encoding="utf-8"), indent=2)
PY

printf '{"state":"running","port":%s,"apiPort":%s}\n' "$FRONTEND_PORT" "$API_SERVICE_PORT"

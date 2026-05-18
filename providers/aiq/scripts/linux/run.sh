#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-aiq}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
FRONTEND_PORT="${AIHUB_PORT:-13080}"

mkdir -p "$ROOT/logs" "$ROOT/runtime"

wait_http() {
  local url="$1"
  local name="$2"
  for _ in $(seq 1 120); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "$name did not become ready at $url" >&2
  return 1
}

if [ "${AIHUB_DRY_RUN:-0}" != "1" ]; then
  [ -d "$DEPLOY_DIR" ] || "$ROOT/scripts/linux/setup.sh"
  (cd "$DEPLOY_DIR" && ./setup.sh --up)
fi

PORTS_FILE="$DEPLOY_DIR/.runtime/ports.env"
if [ -f "$PORTS_FILE" ]; then
  # shellcheck disable=SC1090
  source "$PORTS_FILE"
else
  BACKEND_PORT="${AIHUB_BACKEND_PORT:-18080}"
  FRONTEND_PORT="$FRONTEND_PORT"
fi

if [ "${AIHUB_DRY_RUN:-0}" != "1" ]; then
  wait_http "http://127.0.0.1:${BACKEND_PORT}/health" "AI-Q backend health"
  wait_http "http://127.0.0.1:${BACKEND_PORT}/v1/jobs/async/agents" "AI-Q async agents"
  wait_http "http://127.0.0.1:${FRONTEND_PORT}" "AI-Q frontend"
fi

BACKEND_PID=""
[ -f "$DEPLOY_DIR/.runtime/backend.pid" ] && BACKEND_PID="$(tr -d '[:space:]' < "$DEPLOY_DIR/.runtime/backend.pid")"
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"running","pid":${BACKEND_PID:-null},"port":$FRONTEND_PORT,"platform":"linux","startedAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","uptimeSec":0,"currentStep":"Running AI-Q backend and UI","progressPercent":100,"health":{"level":"ok","message":"Started","backendPort":$BACKEND_PORT}}
EOF
printf '{"state":"running","port":%s,"backendPort":%s}\n' "$FRONTEND_PORT" "$BACKEND_PORT"

#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-web-agent}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
FRONTEND_PORT="${AIHUB_PORT:-3005}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-8011}"
SEARXNG_PORT="${AIHUB_SEARXNG_PORT:-6004}"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python || true)}"
[[ -n "$PYTHON_BIN" ]] || { echo "python3 or python is required" >&2; exit 1; }

mkdir -p "$ROOT/logs" "$ROOT/runtime"

set_env_value() {
  local path="$1" key="$2" value="${3:-}"
  "$PYTHON_BIN" - "$path" "$key" "$value" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
text = path.read_text(encoding="utf-8-sig") if path.exists() else ""
lines = text.splitlines()
updated = False
for index, line in enumerate(lines):
    if line.startswith(f"{key}="):
        lines[index] = f"{key}={value}"
        updated = True
if not updated:
    lines.append(f"{key}={value}")
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

wait_http() {
  local url="$1" name="$2"
  for _ in $(seq 1 120); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "$name did not become ready at $url" >&2
  return 1
}

stop_by_port() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    local pids
    pids="$(lsof -ti tcp:"$port" 2>/dev/null || true)"
    if [[ -n "$pids" ]]; then
      kill $pids >/dev/null 2>&1 || true
      sleep 0.5
      kill -9 $pids >/dev/null 2>&1 || true
    fi
  fi
}

if [ "${AIHUB_DRY_RUN:-0}" != "1" ]; then
  if [ ! -d "$DEPLOY_DIR" ]; then
    "$ROOT/scripts/linux/setup.sh"
  fi
  set_env_value "$DEPLOY_DIR/.env" BACKEND_PORT "$BACKEND_PORT"
  set_env_value "$DEPLOY_DIR/.env" FRONTEND_PORT "$FRONTEND_PORT"
  set_env_value "$DEPLOY_DIR/.env" SEARXNG_PORT "$SEARXNG_PORT"
  set_env_value "$DEPLOY_DIR/.env" AUTO_START_APPS "false"
  set_env_value "$DEPLOY_DIR/backend/.env" APP_SEARXNG_BASE_URL "http://127.0.0.1:$SEARXNG_PORT"
  set_env_value "$DEPLOY_DIR/backend/.env" APP_SEARXNG_BACKUP_BASE_URLS ""
  stop_by_port "$BACKEND_PORT"
  stop_by_port "$FRONTEND_PORT"
  rm -f "$DEPLOY_DIR/logs/backend.pid" "$DEPLOY_DIR/logs/frontend.pid"
  bash "$DEPLOY_DIR/run.sh"
  wait_http "http://127.0.0.1:$BACKEND_PORT/api/v1/health" "Web Agent backend"
  wait_http "http://127.0.0.1:$FRONTEND_PORT" "Web Agent frontend"
fi

pid=""
if command -v lsof >/dev/null 2>&1; then
  pid="$(lsof -tiTCP:"$BACKEND_PORT" -sTCP:LISTEN | head -n 1 || true)"
fi
cat > "$ROOT/runtime/status.json" <<EOF
{"projectId":"$ID","state":"running","pid":${pid:-null},"port":$FRONTEND_PORT,"platform":"linux","startedAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","uptimeSec":0,"currentStep":"Running Web Agent","progressPercent":100,"health":{"level":"ok","message":"Started","backendPort":$BACKEND_PORT}}
EOF
printf '{"state":"running","port":%s,"backendPort":%s}\n' "$FRONTEND_PORT" "$BACKEND_PORT"

#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-multi-agent-intelligent-warehouse}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/$ID"
PORT="${AIHUB_PORT:-3001}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-8091}"
LOG="$ROOT/logs/runtime.log"
STATUS="$ROOT/runtime/status.json"
load_nvidia_api_key() {
  if [[ -n "${NVIDIA_API_KEY:-}" ]]; then
    return
  fi
  local repo_root local_env key_line key_value
  repo_root="$(cd "$ROOT/../.." && pwd)"
  local_env="$repo_root/.env.local"
  [[ -f "$local_env" ]] || return
  key_line="$(grep -E '^\s*NVIDIA_API_KEY=' "$local_env" | tail -n 1 || true)"
  [[ -n "$key_line" ]] || return
  key_value="${key_line#*=}"
  key_value="${key_value%\"}"
  key_value="${key_value#\"}"
  if [[ -n "$key_value" ]]; then
    export NVIDIA_API_KEY="$key_value"
    export EMBEDDING_API_KEY="$key_value"
    export RAIL_API_KEY="$key_value"
  fi
}
mkdir -p "$ROOT/logs" "$ROOT/runtime"
load_nvidia_api_key
if [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  if [[ ! -d "$DEPLOY_DIR" ]]; then
    SETUP_SCRIPT="$ROOT/scripts/linux/setup.sh"
    [[ -f "$SETUP_SCRIPT" ]] || { echo "deploy directory missing and setup script is unavailable" >&2; exit 2; }
    bash "$SETUP_SCRIPT"
  fi
  (cd "$DEPLOY_DIR" && BACKEND_PORT="$BACKEND_PORT" HOST_BACKEND_PORT="$BACKEND_PORT" FRONTEND_PORT="$PORT" HOST_FRONTEND_PORT="$PORT" docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml up -d --wait --wait-timeout 600)
fi
python - "$STATUS" "$ID" "$PORT" <<'PY'
import json, sys
from datetime import datetime, timezone
json.dump({"projectId":sys.argv[2],"state":"running","pid":None,"port":int(sys.argv[3]),"platform":"linux","startedAt":datetime.now(timezone.utc).isoformat(),"uptimeSec":0,"currentStep":"Running warehouse stack","progressPercent":100,"health":{"level":"ok","message":"Started"}}, open(sys.argv[1],"w",encoding="utf-8"), indent=2)
PY
echo "{\"state\":\"running\",\"port\":$PORT}"

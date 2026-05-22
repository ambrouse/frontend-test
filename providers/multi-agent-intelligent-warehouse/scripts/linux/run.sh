#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-multi-agent-intelligent-warehouse}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
PORT="${AIHUB_PORT:-13002}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-8091}"
LOG="$ROOT/logs/runtime.log"
STATUS="$ROOT/runtime/status.json"
mkdir -p "$ROOT/logs" "$ROOT/runtime"
if [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  if [[ ! -d "$DEPLOY_DIR" ]]; then
    SETUP_SCRIPT="$ROOT/scripts/linux/setup.sh"
    [[ -f "$SETUP_SCRIPT" ]] || { echo "deploy directory missing and setup script is unavailable" >&2; exit 2; }
    bash "$SETUP_SCRIPT"
  fi
  (
    cd "$DEPLOY_DIR"
    for env_file in deploy/compose/.env .env; do
      for kv in "BACKEND_PORT=$BACKEND_PORT" "HOST_BACKEND_PORT=$BACKEND_PORT" "FRONTEND_PORT=$PORT" "HOST_FRONTEND_PORT=$PORT"; do
        key="${kv%%=*}"
        value="${kv#*=}"
        if grep -qE "^${key}=" "$env_file"; then
          python - "$env_file" "$key" "$value" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
key, value = sys.argv[2], sys.argv[3]
lines = path.read_text(encoding="utf-8").splitlines()
path.write_text("\n".join(f"{key}={value}" if line.startswith(f"{key}=") else line for line in lines) + "\n", encoding="utf-8")
PY
        else
          printf '%s=%s\n' "$key" "$value" >> "$env_file"
        fi
      done
    done
    BACKEND_PORT="$BACKEND_PORT" HOST_BACKEND_PORT="$BACKEND_PORT" FRONTEND_PORT="$PORT" HOST_FRONTEND_PORT="$PORT" bash scripts/run_all_services.sh
  )
fi
python - "$STATUS" "$ID" "$PORT" <<'PY'
import json, sys
from datetime import datetime, timezone
json.dump({"projectId":sys.argv[2],"state":"running","pid":None,"port":int(sys.argv[3]),"platform":"linux","startedAt":datetime.now(timezone.utc).isoformat(),"uptimeSec":0,"currentStep":"Running warehouse stack","progressPercent":100,"health":{"level":"ok","message":"Started"}}, open(sys.argv[1],"w",encoding="utf-8"), indent=2)
PY
echo "{\"state\":\"running\",\"port\":$PORT}"

#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-multi-agent-intelligent-warehouse}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/$ID"
PORT="${AIHUB_PORT:-8091}"
LOG="$ROOT/logs/runtime.log"
STATUS="$ROOT/runtime/status.json"
mkdir -p "$ROOT/logs" "$ROOT/runtime"
if [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  [[ -d "$DEPLOY_DIR" ]] || { echo "deploy directory missing; install first" >&2; exit 2; }
  (cd "$DEPLOY_DIR" && BACKEND_PORT="$PORT" HOST_BACKEND_PORT="$PORT" docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml up -d --wait --wait-timeout 600)
fi
python - "$STATUS" "$ID" "$PORT" <<'PY'
import json, sys
from datetime import datetime, timezone
json.dump({"projectId":sys.argv[2],"state":"running","pid":None,"port":int(sys.argv[3]),"platform":"linux","startedAt":datetime.now(timezone.utc).isoformat(),"uptimeSec":0,"currentStep":"Running warehouse stack","progressPercent":100,"health":{"level":"ok","message":"Started"}}, open(sys.argv[1],"w",encoding="utf-8"), indent=2)
PY
echo "{\"state\":\"running\",\"port\":$PORT}"

#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-multi-agent-intelligent-warehouse}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/$ID"
PORT="${AIHUB_PORT:-8091}"
if [[ "${AIHUB_DRY_RUN:-0}" != "1" && -d "$DEPLOY_DIR" ]]; then
  (cd "$DEPLOY_DIR" && docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml down >> "$ROOT/logs/runtime.log" 2>&1 || true)
fi
python - "$ROOT/runtime/status.json" "$ID" "$PORT" <<'PY'
import json, sys
json.dump({"projectId":sys.argv[2],"state":"stopped","pid":None,"port":int(sys.argv[3]),"platform":"linux","startedAt":None,"uptimeSec":0,"currentStep":"Stopped","progressPercent":100,"health":{"level":"ok","message":"Stopped"}}, open(sys.argv[1],"w",encoding="utf-8"), indent=2)
PY
echo "{\"state\":\"stopped\"}"

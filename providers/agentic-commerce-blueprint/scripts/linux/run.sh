#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-agentic-commerce-blueprint}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/$ID"
PORT="${AIHUB_PORT:-8088}"
LOG="$ROOT/logs/runtime.log"
STATUS="$ROOT/runtime/status.json"
mkdir -p "$ROOT/logs" "$ROOT/runtime"
python - "$LOG" <<'PY'
import json, sys
from datetime import datetime, timezone
print(json.dumps({"source":"runtime","level":"info","timestamp":datetime.now(timezone.utc).isoformat(),"message":"run requested"}), file=open(sys.argv[1], "a", encoding="utf-8"))
PY
if [[ "${AIHUB_DRY_RUN:-0}" != "1" ]]; then
  [[ -d "$DEPLOY_DIR" ]] || { echo "deploy directory missing; install first" >&2; exit 2; }
  (
    cd "$DEPLOY_DIR"
    export HTTP_HOST_PORT="$PORT"
    docker compose -f docker-compose.infra.yml -f docker-compose.yml build promotion-agent
    docker compose -f docker-compose.infra.yml -f docker-compose.yml up -d --wait --wait-timeout 600
    docker compose -f docker-compose.infra.yml -f docker-compose.yml --profile seed run --rm milvus-seeder
  )
fi
python - "$STATUS" "$ID" "$PORT" <<'PY'
import json, sys
from datetime import datetime, timezone
json.dump({"projectId":sys.argv[2],"state":"running","pid":None,"port":int(sys.argv[3]),"platform":"linux","startedAt":datetime.now(timezone.utc).isoformat(),"uptimeSec":0,"currentStep":"Running commerce stack","progressPercent":100,"health":{"level":"ok","message":"Started"}}, open(sys.argv[1],"w",encoding="utf-8"), indent=2)
PY
echo "{\"state\":\"running\",\"port\":$PORT}"

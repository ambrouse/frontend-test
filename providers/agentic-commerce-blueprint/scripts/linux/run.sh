#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-agentic-commerce-blueprint}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/$ID}"
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
  if [[ ! -d "$DEPLOY_DIR" ]]; then
    SETUP_SCRIPT="$ROOT/scripts/linux/setup.sh"
    [[ -f "$SETUP_SCRIPT" ]] || { echo "deploy directory missing and setup script is unavailable" >&2; exit 2; }
    bash "$SETUP_SCRIPT"
  fi
  (
    cd "$DEPLOY_DIR"
    export HTTP_HOST_PORT="$PORT"
    docker compose -f docker-compose.infra.yml -f docker-compose.yml build promotion-agent
    docker compose -f docker-compose.infra.yml -f docker-compose.yml up -d
    python - "$PORT" <<'PY'
import sys, time, urllib.request

url = f"http://127.0.0.1:{sys.argv[1]}/api/health"
for _ in range(300):
    try:
        with urllib.request.urlopen(url, timeout=2) as response:
            if 200 <= response.status < 300:
                raise SystemExit(0)
    except Exception:
        pass
    time.sleep(2)
raise SystemExit(f"gateway health check did not become ready at {url} within timeout")
PY
    docker compose -f docker-compose.infra.yml -f docker-compose.yml --profile seed run --rm milvus-seeder
  )
fi
python - "$STATUS" "$ID" "$PORT" <<'PY'
import json, sys
from datetime import datetime, timezone
json.dump({"projectId":sys.argv[2],"state":"running","pid":None,"port":int(sys.argv[3]),"platform":"linux","startedAt":datetime.now(timezone.utc).isoformat(),"uptimeSec":0,"currentStep":"Running commerce stack","progressPercent":100,"health":{"level":"ok","message":"Started"}}, open(sys.argv[1],"w",encoding="utf-8"), indent=2)
PY
echo "{\"state\":\"running\",\"port\":$PORT}"

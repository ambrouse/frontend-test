#!/usr/bin/env bash
set -euo pipefail

ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/pdf-to-podcast"
FRONTEND_PORT="${AIHUB_PORT:-7860}"
API_SERVICE_PORT="8002"
if [[ -f "$DEPLOY_DIR/.auto-ports.env" ]]; then
  # shellcheck disable=SC1090
  source "$DEPLOY_DIR/.auto-ports.env"
fi

running_containers=0
if [[ -f "$DEPLOY_DIR/docker-compose.yaml" && -f "$DEPLOY_DIR/.auto-ports.compose.yaml" ]]; then
  running_containers="$(cd "$DEPLOY_DIR" && docker compose -f docker-compose.yaml -f .auto-ports.compose.yaml --env-file .env ps --services --filter status=running | wc -l | tr -d ' ')"
fi

python - "$ROOT/runtime/metrics.json" "$running_containers" "$FRONTEND_PORT" "$API_SERVICE_PORT" <<'PY'
import json, sys
from datetime import datetime, timezone

running = int(sys.argv[2])
metrics = {
    "sampledAt": datetime.now(timezone.utc).isoformat(),
    "platform": "linux",
    "process": {"cpuPercent": 0, "ramMb": 0, "gpuPercent": 0, "vramMb": 0},
    "service": {
        "requestsTotal": 0,
        "requestsPerMin": 0,
        "latencyP50Ms": 0,
        "latencyP95Ms": 0,
        "errorsLastHour": 0,
        "runningContainers": running,
        "frontendPort": int(sys.argv[3]),
        "apiPort": int(sys.argv[4]),
    },
    "benchmark": {
        "headlineMetric": f"{running} containers",
        "secondaryMetric": f"frontend {sys.argv[3]}",
        "vramPeakMb": 0,
    },
}
json.dump(metrics, open(sys.argv[1], "w", encoding="utf-8"), indent=2)
print(json.dumps(metrics))
PY

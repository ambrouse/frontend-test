#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-multi-agent-intelligent-warehouse}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/$ID"
PORT="${AIHUB_PORT:-8091}"
REPO_URL="https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia"
LOG="$ROOT/logs/runtime.log"
STATUS="$ROOT/runtime/status.json"
METRICS="$ROOT/runtime/metrics.json"
mkdir -p "$DEPLOY_ROOT" "$ROOT/logs" "$ROOT/runtime"
log_json() { python - "$1" "$2" "$3" >> "$LOG" <<'PY'
import json, sys
from datetime import datetime, timezone
print(json.dumps({"source": sys.argv[1], "level": sys.argv[2], "timestamp": datetime.now(timezone.utc).isoformat(), "message": sys.argv[3]}))
PY
}
status_json() { python - "$ID" "$PORT" "$1" "$2" "$3" > "$STATUS" <<'PY'
import json, sys
from datetime import datetime, timezone
print(json.dumps({"projectId": sys.argv[1], "state": sys.argv[3], "pid": None, "port": int(sys.argv[2]), "platform": "linux", "startedAt": datetime.now(timezone.utc).isoformat(), "uptimeSec": 0, "currentStep": sys.argv[4], "progressPercent": int(sys.argv[5]), "health": {"level": "ok", "message": sys.argv[4]}}, indent=2))
PY
}
log_json install info "install started"
if [[ "${AIHUB_DRY_RUN:-0}" == "1" ]]; then
  mkdir -p "$DEPLOY_DIR/deploy/compose"
else
  if [[ ! -d "$DEPLOY_DIR/.git" ]]; then
    git clone --depth 1 --branch "${AIHUB_BRANCH:-main}" "$REPO_URL" "$DEPLOY_DIR"
  else
    git -C "$DEPLOY_DIR" fetch --depth 1 origin "${AIHUB_BRANCH:-main}"
    git -C "$DEPLOY_DIR" checkout "${AIHUB_BRANCH:-main}"
    git -C "$DEPLOY_DIR" pull --ff-only
  fi
  find "$DEPLOY_DIR" -name "*.sh" -type f -exec sed -i 's/\r$//' {} +
fi
ENV_FILE="$DEPLOY_DIR/deploy/compose/.env"
mkdir -p "$(dirname "$ENV_FILE")"
if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ROOT/.env.example" "$ENV_FILE"
fi
python - "$ENV_FILE" "$PORT" <<'PY'
import os, sys
path, port = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
updates = {
    "BACKEND_PORT": port,
    "NVIDIA_API_KEY": os.environ.get("NVIDIA_API_KEY", ""),
    "EMBEDDING_API_KEY": os.environ.get("NVIDIA_API_KEY", ""),
    "RAIL_API_KEY": os.environ.get("NVIDIA_API_KEY", ""),
}
lines, seen = [], set()
for line in text.splitlines():
    key = line.split("=", 1)[0] if "=" in line else ""
    if key in updates and updates[key]:
        lines.append(f"{key}={updates[key]}")
        seen.add(key)
    elif key == "BACKEND_PORT":
        lines.append(f"BACKEND_PORT={port}")
        seen.add(key)
    else:
        lines.append(line)
for key, value in updates.items():
    if key not in seen:
        lines.append(f"{key}={value}")
open(path, "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
python - "$METRICS" <<'PY'
import json, sys
from datetime import datetime, timezone
json.dump({"sampledAt": datetime.now(timezone.utc).isoformat(), "platform": "linux", "process": {"cpuPercent": 0, "ramMb": 0, "gpuPercent": 0, "vramMb": 0}, "service": {"requestsTotal": 0, "requestsPerMin": 0, "latencyP50Ms": 0, "latencyP95Ms": 0, "errorsLastHour": 0}, "benchmark": {"headlineMetric": "installed", "secondaryMetric": "ready", "vramPeakMb": 0}}, open(sys.argv[1], "w", encoding="utf-8"), indent=2)
PY
status_json installed "Installed into $DEPLOY_DIR" 100
log_json install info "install completed"
echo "{\"state\":\"installed\",\"port\":$PORT}"

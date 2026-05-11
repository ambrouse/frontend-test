#!/usr/bin/env bash
set -euo pipefail

ID="${AIHUB_PROVIDER_ID:-agentic-commerce-blueprint}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/$ID"
PORT="${AIHUB_PORT:-8088}"
REPO_URL="https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-"
LOG="$ROOT/logs/runtime.log"
STATUS="$ROOT/runtime/status.json"
METRICS="$ROOT/runtime/metrics.json"

load_nvidia_api_key() {
  if [[ -n "${NVIDIA_API_KEY:-}" ]]; then
    return
  fi
  local repo_root local_env key_line key_value
  repo_root="$(cd "$ROOT/../.." && pwd)"
  local_env="$repo_root/.env.local"
  [[ -f "$local_env" ]] || return 0
  key_line="$(grep -E '^\s*NVIDIA_API_KEY=' "$local_env" | tail -n 1 || true)"
  [[ -n "$key_line" ]] || return 0
  key_value="${key_line#*=}"
  key_value="${key_value%\"}"
  key_value="${key_value#\"}"
  if [[ -n "$key_value" ]]; then
    export NVIDIA_API_KEY="$key_value"
    export NGC_API_KEY="$key_value"
  fi
}

mkdir -p "$DEPLOY_ROOT" "$ROOT/logs" "$ROOT/runtime"
load_nvidia_api_key
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
  mkdir -p "$DEPLOY_DIR"
else
  if [[ ! -d "$DEPLOY_DIR/.git" ]]; then
    if [[ -d "$DEPLOY_DIR" ]] && [[ -n "$(ls -A "$DEPLOY_DIR" 2>/dev/null)" ]]; then
      rm -rf "$DEPLOY_DIR"
    fi
    git clone --depth 1 --branch "${AIHUB_BRANCH:-main}" "$REPO_URL" "$DEPLOY_DIR"
  else
    git -C "$DEPLOY_DIR" fetch --depth 1 origin "${AIHUB_BRANCH:-main}"
    git -C "$DEPLOY_DIR" checkout "${AIHUB_BRANCH:-main}"
    git -C "$DEPLOY_DIR" pull --ff-only
  fi
  find "$DEPLOY_DIR" -name "*.sh" -type f -exec sed -i 's/\r$//' {} +
fi

if [[ ! -f "$DEPLOY_DIR/.env" ]]; then
  cp "$ROOT/.env.example" "$DEPLOY_DIR/.env"
fi
python - "$DEPLOY_DIR/.env" "$PORT" <<'PY'
import os, sys
path, port = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
lines = []
seen_port = False
seen_key = False
for line in text.splitlines():
    if line.startswith("HTTP_HOST_PORT="):
        lines.append(f"HTTP_HOST_PORT={port}")
        seen_port = True
    elif line.startswith("NVIDIA_API_KEY="):
        value = os.environ.get("NVIDIA_API_KEY", line.split("=", 1)[1])
        lines.append(f"NVIDIA_API_KEY={value}")
        seen_key = True
    else:
        lines.append(line)
if not seen_port:
    lines.append(f"HTTP_HOST_PORT={port}")
if not seen_key:
    lines.append(f"NVIDIA_API_KEY={os.environ.get('NVIDIA_API_KEY', '')}")
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

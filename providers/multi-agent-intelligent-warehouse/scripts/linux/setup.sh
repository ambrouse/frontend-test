#!/usr/bin/env bash
set -euo pipefail
ID="${AIHUB_PROVIDER_ID:-multi-agent-intelligent-warehouse}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../../deploy" && pwd)}"
DEPLOY_DIR="$DEPLOY_ROOT/$ID"
PORT="${AIHUB_PORT:-3001}"
REPO_URL="https://github.com/baolnq-ai/Multi-Agent-Intelligent-WarehousePublic-nvidia"
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
    export EMBEDDING_API_KEY="$key_value"
    export RAIL_API_KEY="$key_value"
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
  mkdir -p "$DEPLOY_DIR/deploy/compose"
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
ENV_FILE="$DEPLOY_DIR/deploy/compose/.env"
mkdir -p "$(dirname "$ENV_FILE")"
if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ROOT/.env.example" "$ENV_FILE"
fi
python - "$ENV_FILE" "$PORT" "$ROOT/.env.example" <<'PY'
import os, sys
path, port, defaults_path = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding="utf-8").read()
defaults = open(defaults_path, encoding="utf-8").read().splitlines()
existing = {line.split("=", 1)[0] for line in text.splitlines() if "=" in line}
for line in defaults:
    if "=" in line and not line.lstrip().startswith("#"):
        key = line.split("=", 1)[0]
        if key and key not in existing:
            text += "\n" + line
            existing.add(key)
updates = {
    "BACKEND_PORT": os.environ.get("AIHUB_BACKEND_PORT", "8091"),
    "HOST_BACKEND_PORT": os.environ.get("AIHUB_BACKEND_PORT", "8091"),
    "FRONTEND_PORT": port,
    "HOST_FRONTEND_PORT": port,
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
    elif key in {"BACKEND_PORT", "HOST_BACKEND_PORT"}:
        lines.append(f"{key}={os.environ.get('AIHUB_BACKEND_PORT', '8091')}")
        seen.add(key)
    elif key in {"FRONTEND_PORT", "HOST_FRONTEND_PORT"}:
        lines.append(f"{key}={port}")
        seen.add(key)
    elif key == "LLM_MODEL" and line.endswith("meta/llama-3.1-70b-instruct"):
        lines.append("LLM_MODEL=nvidia/llama-3.3-nemotron-super-49b-v1.5")
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

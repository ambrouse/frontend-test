#!/usr/bin/env bash
set -euo pipefail

PROVIDER_ID="${1:?provider id required}"
ACTION="${2:?action required}"
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../${PROVIDER_ID}" && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "${ROOT}/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-${DEPLOY_ROOT}/${PROVIDER_ID}}"
PORT="${AIHUB_PORT:-3000}"
BRANCH="${AIHUB_BRANCH:-main}"

repo_url() {
  case "$PROVIDER_ID" in
    shop-retail-provider) echo "https://github.com/mionm/Shop-Retail-Provider-mion-.git" ;;
    nemotron-voice-agent-provider) echo "https://github.com/mionm/nemotron-voice-agent-provider.git" ;;
    ai-virtual-assistant-provider) echo "https://github.com/mionm/ai-virtual-assistant-provider.git" ;;
    *) echo "Unknown provider ${PROVIDER_ID}" >&2; exit 2 ;;
  esac
}

write_status() {
  local state="$1" step="$2"
  mkdir -p "${ROOT}/runtime"
  python3 - "$ROOT/runtime/status.json" "$PROVIDER_ID" "$state" "$PORT" "$step" <<'PY'
import json, sys, datetime
path, pid, state, port, step = sys.argv[1:6]
json.dump({
  "projectId": pid, "state": state, "pid": None, "port": int(port), "platform": "linux",
  "startedAt": datetime.datetime.utcnow().isoformat() + "Z", "uptimeSec": 0,
  "currentStep": step, "progressPercent": 100, "health": {"level": "ok", "message": step}
}, open(path, "w", encoding="utf-8"))
PY
}

set_env_value() {
  local file="$1" key="$2" value="${3:-}"
  touch "$file"
  if grep -Eq "^${key}=" "$file"; then
    python3 - "$file" "$key" "$value" <<'PY'
import pathlib, sys
p, k, v = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
p.write_text("\n".join((f"{k}={v}" if line.startswith(k + "=") else line) for line in lines) + "\n", encoding="utf-8")
PY
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

clone_or_update() {
  mkdir -p "$(dirname "$DEPLOY_DIR")" "$ROOT/logs" "$ROOT/runtime"
  if [[ "${AIHUB_DRY_RUN:-}" == "1" ]]; then
    mkdir -p "$DEPLOY_DIR"
    return
  fi
  if [[ ! -d "$DEPLOY_DIR/.git" ]]; then
    rm -rf "$DEPLOY_DIR"
    git clone --depth 1 --branch "$BRANCH" "$(repo_url)" "$DEPLOY_DIR"
  else
    git -C "$DEPLOY_DIR" fetch --depth 1 origin "$BRANCH"
    git -C "$DEPLOY_DIR" checkout "$BRANCH"
    git -C "$DEPLOY_DIR" pull --ff-only
  fi
}

wait_http() {
  local url="$1" timeout="${2:-300}" end=$((SECONDS + timeout))
  until curl -fsS --max-time 5 "$url" >/dev/null 2>&1; do
    if (( SECONDS >= end )); then
      echo "Timed out waiting for ${url}" >&2
      return 1
    fi
    sleep 2
  done
}

setup_provider() {
  clone_or_update
  [[ "${AIHUB_DRY_RUN:-}" == "1" ]] && { write_status installed "Installed"; return; }
  local local_env_file="${ROOT}/../../.env.local"
  if [[ -f "$local_env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$local_env_file"
    set +a
  fi
  local nvidia="${NVIDIA_API_KEY:-}" ngc="${NGC_API_KEY:-${NVIDIA_API_KEY:-}}"
  case "$PROVIDER_ID" in
    shop-retail-provider)
      if [[ -f "$DEPLOY_DIR/docker-compose.yaml" ]]; then
        python3 - "$DEPLOY_DIR/docker-compose.yaml" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = re.sub(r"(?m)^\s*container_name:\s*.+\n", "", text)
text = re.sub(r"(?m)^\s*name:\s*retail-shopping-assistant_shopping-network\n", "", text)
path.write_text(text, encoding="utf-8")
PY
      fi
      if [[ -f "$DEPLOY_DIR/nginx.conf" ]]; then
        python3 - "$DEPLOY_DIR/nginx.conf" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
if "proxy_read_timeout" not in text:
    text = re.sub(r"(?m)^(\s*proxy_cache off;\s*)$", r"\1\n            proxy_read_timeout 600s;\n            proxy_send_timeout 600s;", text)
path.write_text(text, encoding="utf-8")
PY
      fi
      if [[ -f "$DEPLOY_DIR/ui/src/config/config.ts" ]]; then
        python3 - "$DEPLOY_DIR/ui/src/config/config.ts" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = re.sub(r"defaultState:\s*true", "defaultState: false", text)
path.write_text(text, encoding="utf-8")
PY
      fi
      cp -n "$DEPLOY_DIR/.env.example" "$DEPLOY_DIR/.env"
      for key in NVIDIA_API_KEY NGC_API_KEY LLM_API_KEY EMBED_API_KEY RAIL_API_KEY; do
        val="${!key:-}"
        [[ -z "$val" && "$key" != "NVIDIA_API_KEY" ]] && val="$nvidia"
        set_env_value "$DEPLOY_DIR/.env" "$key" "$val"
      done
      set_env_value "$DEPLOY_DIR/.env" CONFIG_OVERRIDE config-build.yaml
      set_env_value "$DEPLOY_DIR/.env" COMPOSE_PROJECT_NAME aihub-shop-retail-provider
      set_env_value "$DEPLOY_DIR/.env" HTTP_HOST_PORT "$PORT"
      declare -A default_ports=(
        [CHAIN_SERVER_PORT]=18109
        [CATALOG_RETRIEVER_PORT]=18110
        [MEMORY_RETRIEVER_PORT]=18111
        [GUARDRAILS_PORT]=18112
        [MILVUS_PORT]=19531
        [MILVUS_HEALTH_PORT]=19091
        [MINIO_PORT]=19000
        [MINIO_CONSOLE_PORT]=19001
        [ETCD_PORT]=12379
      )
      for key in CHAIN_SERVER_PORT CATALOG_RETRIEVER_PORT MEMORY_RETRIEVER_PORT GUARDRAILS_PORT MILVUS_PORT MILVUS_HEALTH_PORT MINIO_PORT MINIO_CONSOLE_PORT ETCD_PORT; do
        val="${!key:-${default_ports[$key]}}"
        set_env_value "$DEPLOY_DIR/.env" "$key" "$val"
      done
      ;;
    nemotron-voice-agent-provider)
      cp -n "$DEPLOY_DIR/config/env.example" "$DEPLOY_DIR/.env"
      set_env_value "$DEPLOY_DIR/.env" UI_PORT "$PORT"
      for key in NVIDIA_API_KEY NGC_API_KEY TRANSPORT ASR_SERVER_URL TTS_SERVER_URL NVIDIA_LLM_URL; do
        val="${!key:-}"
        [[ "$key" == "NGC_API_KEY" && -z "$val" ]] && val="$ngc"
        [[ -n "$val" ]] && set_env_value "$DEPLOY_DIR/.env" "$key" "$val"
      done
      [[ -n "${NEMOTRON_PIPELINE_PORT:-}" ]] && set_env_value "$DEPLOY_DIR/.env" PYTHON_APP_PORT "$NEMOTRON_PIPELINE_PORT"
      ;;
    ai-virtual-assistant-provider)
      cp -n "$DEPLOY_DIR/.env.example" "$DEPLOY_DIR/.env"
      for key in NVIDIA_API_KEY NGC_API_KEY USE_LOCAL_NIM USE_CPU_MILVUS PGADMIN_DEFAULT_EMAIL PGADMIN_DEFAULT_PASSWORD; do
        val="${!key:-}"
        [[ "$key" == "NGC_API_KEY" && -z "$val" ]] && val="$ngc"
        [[ -n "$val" ]] && set_env_value "$DEPLOY_DIR/.env" "$key" "$val"
      done
      ;;
  esac
  write_status installed "Installed"
}

run_provider() {
  [[ -d "$DEPLOY_DIR" ]] || setup_provider
  [[ "${AIHUB_DRY_RUN:-}" == "1" ]] && { write_status running "Running"; return; }
  case "$PROVIDER_ID" in
    shop-retail-provider)
      setup_provider
      (cd "$DEPLOY_DIR" && docker compose --env-file .env -f docker-compose.yaml up -d --build)
      wait_http "http://127.0.0.1:${PORT}/api/health" 600
      ;;
    nemotron-voice-agent-provider)
      local pipeline="${NEMOTRON_PIPELINE_PORT:-7860}"
      setup_provider
      (cd "$DEPLOY_DIR" && docker compose --env-file .env -f docker-compose.yml up -d --build --no-deps python-app)
      (cd "$DEPLOY_DIR" && docker compose --env-file .env -f docker-compose.yml up -d --build --no-deps ui-app)
      wait_http "http://127.0.0.1:${pipeline}/docs" 600
      wait_http "http://127.0.0.1:${PORT}" 300
      ;;
    ai-virtual-assistant-provider)
      (cd "$DEPLOY_DIR" && bash ./start.sh)
      PORT="$(grep -E '^UI_PORT=' "$DEPLOY_DIR/.runtime/ports.env" | cut -d= -f2)"
      wait_http "http://127.0.0.1:${PORT}" 300
      ;;
  esac
  write_status running "Running"
}

stop_provider() {
  [[ -d "$DEPLOY_DIR" && "${AIHUB_DRY_RUN:-}" != "1" ]] || { write_status stopped "Stopped"; return; }
  case "$PROVIDER_ID" in
    shop-retail-provider) (cd "$DEPLOY_DIR" && docker compose --env-file .env -f docker-compose.yaml down || true) ;;
    nemotron-voice-agent-provider) (cd "$DEPLOY_DIR" && docker compose --env-file .env -f docker-compose.yml down || true) ;;
    ai-virtual-assistant-provider) (cd "$DEPLOY_DIR" && bash ./stop.sh || true) ;;
  esac
  write_status stopped "Stopped"
}

cleanup_provider() {
  [[ -d "$DEPLOY_DIR" && "${AIHUB_DRY_RUN:-}" != "1" ]] || return 0
  case "$PROVIDER_ID" in
    shop-retail-provider)
      [[ -f "$DEPLOY_DIR/.env" && -f "$DEPLOY_DIR/docker-compose.yaml" ]] && (cd "$DEPLOY_DIR" && docker compose --env-file .env -f docker-compose.yaml down --volumes --remove-orphans --rmi all || true)
      ;;
    nemotron-voice-agent-provider)
      [[ -f "$DEPLOY_DIR/.env" && -f "$DEPLOY_DIR/docker-compose.yml" ]] && (cd "$DEPLOY_DIR" && docker compose --env-file .env -f docker-compose.yml down --volumes --remove-orphans --rmi all || true)
      ;;
    ai-virtual-assistant-provider)
      if [[ -f "$DEPLOY_DIR/deploy/compose/docker-compose.yaml" ]]; then
        local args=(--env-file .env -f deploy/compose/docker-compose.yaml)
        [[ -f "$DEPLOY_DIR/.runtime/docker-compose.aihub.yaml" ]] && args+=(-f .runtime/docker-compose.aihub.yaml)
        [[ -f "$DEPLOY_DIR/.runtime/docker-compose.cpu.yaml" ]] && args+=(-f .runtime/docker-compose.cpu.yaml)
        (cd "$DEPLOY_DIR" && docker compose "${args[@]}" down --volumes --remove-orphans --rmi all || true)
      fi
      ;;
  esac
}

metrics_provider() {
  mkdir -p "$ROOT/runtime"
  local running=0
  if [[ -d "$DEPLOY_DIR" ]]; then
    running="$(docker ps --format '{{.Names}}' | wc -l | tr -d ' ')"
  fi
  python3 - "$ROOT/runtime/metrics.json" "$running" "$PORT" <<'PY'
import json, sys, datetime
path, running, port = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
sampled = datetime.datetime.utcnow().isoformat() + "Z"
data = {"sampledAt": sampled, "platform": "linux", "process": {"cpuPercent": 0, "ramMb": 0, "gpuPercent": 0, "vramMb": 0}, "service": {"runningContainers": running, "gatewayPort": port}, "benchmark": {"headlineMetric": f"{running} containers", "secondaryMetric": f"port {port}", "latencyMs": 0, "throughput": 0, "vramPeakMb": 0, "measuredAt": sampled}}
json.dump(data, open(path, "w", encoding="utf-8"))
print(json.dumps(data))
PY
}

case "$ACTION" in
  setup) setup_provider ;;
  run) run_provider ;;
  stop) stop_provider ;;
  delete) cleanup_provider; rm -rf "$DEPLOY_DIR"; write_status not_installed "Deleted" ;;
  health) [[ -f "$ROOT/runtime/status.json" ]] && cat "$ROOT/runtime/status.json" || echo '{"state":"unknown","health":{"level":"unknown","message":"No status file"}}' ;;
  metrics) metrics_provider ;;
  *) echo "Unknown action ${ACTION}" >&2; exit 2 ;;
esac

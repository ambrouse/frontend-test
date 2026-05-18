#!/usr/bin/env bash
set -euo pipefail
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/multi-agent-intelligent-warehouse}"
FRONTEND_PORT="${AIHUB_PORT:-13002}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-8091}"
SAMPLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

backend_ok=false
if curl -fsS "http://127.0.0.1:${BACKEND_PORT}/api/v1/health" >/dev/null 2>&1; then
  backend_ok=true
fi

running_containers=0
if [[ -f "$DEPLOY_DIR/deploy/compose/docker-compose.dev.yaml" && -f "$DEPLOY_DIR/deploy/compose/.env" ]]; then
  running_containers="$(cd "$DEPLOY_DIR" && docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml ps --services --filter status=running 2>/dev/null | wc -l | tr -d ' ')"
fi

headline="not running"
secondary="backend unavailable"
if [[ "$backend_ok" == true ]]; then
  headline="${running_containers} containers"
  secondary="backend ${BACKEND_PORT}, frontend ${FRONTEND_PORT}"
fi

mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/metrics.json" <<EOF
{"sampledAt":"$SAMPLED_AT","platform":"linux","process":{"cpuPercent":0,"ramMb":0,"gpuPercent":0,"vramMb":0},"service":{"requestsTotal":0,"requestsPerMin":0,"latencyP50Ms":0,"latencyP95Ms":0,"errorsLastHour":0,"runningContainers":$running_containers,"backendOk":$backend_ok,"frontendPort":$FRONTEND_PORT,"backendPort":$BACKEND_PORT},"benchmark":{"headlineMetric":"$headline","secondaryMetric":"$secondary","latencyMs":0,"throughput":0,"vramPeakMb":0,"measuredAt":"$SAMPLED_AT"}}
EOF
cat "$ROOT/runtime/metrics.json"

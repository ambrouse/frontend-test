#!/usr/bin/env bash
set -euo pipefail
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/agentic-commerce-blueprint}"
PORT="${AIHUB_PORT:-8088}"
SAMPLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

gateway_ok=false
if curl -fsS "http://127.0.0.1:${PORT}/api/health" >/dev/null 2>&1; then
  gateway_ok=true
fi

running_containers=0
if [[ -f "$DEPLOY_DIR/docker-compose.infra.yml" && -f "$DEPLOY_DIR/docker-compose.yml" ]]; then
  running_containers="$(cd "$DEPLOY_DIR" && docker compose -f docker-compose.infra.yml -f docker-compose.yml ps --services --filter status=running 2>/dev/null | wc -l | tr -d ' ')"
fi

headline="not running"
secondary="gateway unavailable"
if [[ "$gateway_ok" == true ]]; then
  headline="${running_containers} containers"
  secondary="gateway ${PORT} healthy"
fi

mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/metrics.json" <<EOF
{"sampledAt":"$SAMPLED_AT","platform":"linux","process":{"cpuPercent":0,"ramMb":0,"gpuPercent":0,"vramMb":0},"service":{"requestsTotal":0,"requestsPerMin":0,"latencyP50Ms":0,"latencyP95Ms":0,"errorsLastHour":0,"runningContainers":$running_containers,"gatewayOk":$gateway_ok,"gatewayPort":$PORT},"benchmark":{"headlineMetric":"$headline","secondaryMetric":"$secondary","latencyMs":0,"throughput":0,"vramPeakMb":0,"measuredAt":"$SAMPLED_AT"}}
EOF
cat "$ROOT/runtime/metrics.json"

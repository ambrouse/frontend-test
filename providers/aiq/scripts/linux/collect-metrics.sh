#!/usr/bin/env bash
set -euo pipefail

ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEPLOY_ROOT="${AIHUB_DEPLOY_ROOT:-$(cd "$ROOT/../.." && pwd)/deploy}"
DEPLOY_DIR="${AIHUB_INSTALL_DIRECTORY:-$DEPLOY_ROOT/aiq}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-18080}"
FRONTEND_PORT="${AIHUB_PORT:-13080}"

if [ -f "$DEPLOY_DIR/.runtime/ports.env" ]; then
  # shellcheck disable=SC1090
  source "$DEPLOY_DIR/.runtime/ports.env"
fi

backend_ok=false
agent_count=0
if agents_json="$(curl -fsS "http://127.0.0.1:${BACKEND_PORT}/v1/jobs/async/agents" 2>/dev/null)"; then
  backend_ok=true
  agent_count="$(python -c 'import json,sys; print(len(json.load(sys.stdin).get("agents", [])))' <<<"$agents_json" 2>/dev/null || echo 0)"
fi

headline="not running"
secondary="backend unavailable"
if [ "$backend_ok" = true ]; then
  headline="${agent_count} agents"
  secondary="backend ${BACKEND_PORT}, frontend ${FRONTEND_PORT}"
fi

sampled_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "$ROOT/runtime"
cat > "$ROOT/runtime/metrics.json" <<EOF
{"sampledAt":"$sampled_at","platform":"linux","process":{"cpuPercent":0,"ramMb":0,"gpuPercent":0,"vramMb":0},"service":{"requestsTotal":0,"requestsPerMin":0,"latencyP50Ms":0,"latencyP95Ms":0,"errorsLastHour":0,"backendOk":$backend_ok,"agents":$agent_count,"frontendPort":$FRONTEND_PORT,"backendPort":$BACKEND_PORT},"benchmark":{"headlineMetric":"$headline","secondaryMetric":"$secondary","latencyMs":0,"throughput":0,"vramPeakMb":0,"measuredAt":"$sampled_at"}}
EOF
cat "$ROOT/runtime/metrics.json"

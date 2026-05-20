#!/usr/bin/env bash
set -euo pipefail
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
FRONTEND_PORT="${AIHUB_PORT:-3005}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-8011}"
mkdir -p "$ROOT/runtime"
backend_ok=false
frontend_ok=false
curl -fsS "http://127.0.0.1:$BACKEND_PORT/api/v1/health" >/dev/null 2>&1 && backend_ok=true
curl -fsS "http://127.0.0.1:$FRONTEND_PORT" >/dev/null 2>&1 && frontend_ok=true
headline="not running"
if [ "$backend_ok" = true ] && [ "$frontend_ok" = true ]; then headline="healthy"; fi
cat > "$ROOT/runtime/metrics.json" <<EOF
{"sampledAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","platform":"linux","process":{"cpuPercent":0,"ramMb":0,"gpuPercent":0,"vramMb":0},"service":{"backendOk":$backend_ok,"frontendOk":$frontend_ok,"backendPort":$BACKEND_PORT,"frontendPort":$FRONTEND_PORT,"requestsTotal":0,"requestsPerMin":0,"latencyP50Ms":0,"latencyP95Ms":0,"errorsLastHour":0},"benchmark":{"headlineMetric":"$headline","secondaryMetric":"frontend $FRONTEND_PORT / backend $BACKEND_PORT","latencyMs":0,"throughput":0,"vramPeakMb":0,"measuredAt":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"}}
EOF
cat "$ROOT/runtime/metrics.json"

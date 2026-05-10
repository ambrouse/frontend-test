#!/usr/bin/env bash
set -euo pipefail
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
cat "$ROOT/runtime/metrics.json" 2>/dev/null || echo '{"process":{},"service":{},"benchmark":{}}'

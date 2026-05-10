#!/usr/bin/env bash
set -euo pipefail
ROOT="${AIHUB_PROVIDER_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
cat "$ROOT/runtime/status.json" 2>/dev/null || echo '{"state":"unknown","health":{"level":"unknown","message":"No status file"}}'

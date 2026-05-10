#!/usr/bin/env bash
set -euo pipefail
"$(dirname "$0")/stop.sh" || true
echo "{\"state\":\"deleted\"}"

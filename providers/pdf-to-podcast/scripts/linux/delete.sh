#!/usr/bin/env bash
set -euo pipefail
bash "$(dirname "$0")/stop.sh"
printf '{"state":"deleted"}\n'

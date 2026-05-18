#!/usr/bin/env bash
set -euo pipefail
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../_shared" && pwd)/linux-provider-dispatch.sh" ai-virtual-assistant-provider setup

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/app"
FRONTEND_PORT="${AIHUB_FRONTEND_PORT:-6901}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-6902}"

mkdir -p "${ROOT_DIR}/logs/hub" "${ROOT_DIR}/deploy"

python "${ROOT_DIR}/backend/scripts/seed_providers.py"

cleanup() {
  local code=$?
  if [[ -n "${BACKEND_PID:-}" ]]; then
    kill "${BACKEND_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${FRONTEND_PID:-}" ]]; then
    kill "${FRONTEND_PID}" >/dev/null 2>&1 || true
  fi
  exit "${code}"
}
trap cleanup EXIT INT TERM

uvicorn app.main:app --host 0.0.0.0 --port "${BACKEND_PORT}" --app-dir "${ROOT_DIR}/backend" &
BACKEND_PID=$!

(
  cd "${ROOT_DIR}/frontend"
  HOSTNAME=0.0.0.0 PORT="${FRONTEND_PORT}" node server.js
) &
FRONTEND_PID=$!

wait -n "${BACKEND_PID}" "${FRONTEND_PID}"

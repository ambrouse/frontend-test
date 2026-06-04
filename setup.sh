#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
LOG_DIR="${ROOT_DIR}/logs/hub"
FRONTEND_PORT="${AIHUB_FRONTEND_PORT:-6901}"
BACKEND_PORT="${AIHUB_BACKEND_PORT:-6902}"
NGINX_PORT="${AIHUB_NGINX_PORT:-6900}"
HOST="${AIHUB_HOST:-0.0.0.0}"
NGINX_IMAGE="${AIHUB_NGINX_IMAGE:-nginx:1.27-alpine}"
ASSUME_YES="${AIHUB_ASSUME_YES:-0}"
NO_START=0
SKIP_NGINX=0

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--yes] [--no-start] [--skip-nginx] [--help]

Bootstraps and starts AI Hub with Bash only.

Options:
  --yes         Use non-interactive defaults. Healthy busy ports are reused; unhealthy busy ports are killed.
  --no-start    Install dependencies and seed providers, but do not start services.
  --skip-nginx  Do not start the Docker Nginx gateway.
  --help        Show this help.

Environment:
  AIHUB_FRONTEND_PORT  Frontend port, default 6901
  AIHUB_BACKEND_PORT   Backend port, default 6902
  AIHUB_NGINX_PORT     Gateway port, default 6900
  AIHUB_HOST           Bind host, default 0.0.0.0
  AIHUB_ASSUME_YES=1   Same as --yes
EOF
}

log() {
  printf '[AI Hub] %s\n' "$*"
}

warn() {
  printf '[AI Hub] WARN: %s\n' "$*" >&2
}

fail() {
  printf '[AI Hub] ERROR: %s\n' "$*" >&2
  exit 1
}

confirm() {
  local prompt="$1" default="${2:-n}" answer
  if [[ "${ASSUME_YES}" == "1" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    [[ "${default}" == "y" ]]
    return
  fi
  read -r -p "${prompt} " answer || answer=""
  answer="${answer:-${default}}"
  [[ "${answer}" =~ ^([yY]|yes|YES)$ ]]
}

require_command() {
  local label="$1" command_name="$2" install_hint="$3"
  if command -v "${command_name}" >/dev/null 2>&1; then
    log "OK: ${label}"
    return 0
  fi
  fail "${label} is missing. ${install_hint}"
}

is_windows_bash() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

is_number() {
  [[ "${1:-}" =~ ^[0-9]+$ ]]
}

validate_port() {
  local label="$1" port="$2"
  is_number "${port}" || fail "${label} port must be numeric, got '${port}'."
  (( port >= 1 && port <= 65535 )) || fail "${label} port must be between 1 and 65535, got '${port}'."
}

port_pids() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -tiTCP:"${port}" -sTCP:LISTEN 2>/dev/null | sort -u
    return 0
  fi
  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :${port}" 2>/dev/null | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' | sort -u
    return 0
  fi
  if command -v fuser >/dev/null 2>&1; then
    fuser "${port}/tcp" 2>/dev/null | tr ' ' '\n' | sed '/^$/d' | sort -u
    return 0
  fi
  if is_windows_bash && command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
      "Get-NetTCPConnection -LocalPort ${port} -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique" \
      2>/dev/null | tr -d '\r' | sed '/^$/d' | sort -u
    return 0
  fi
  return 0
}

port_in_use() {
  local port="$1"
  [[ -n "$(port_pids "${port}")" ]]
}

kill_pids() {
  local label="$1"
  shift
  local pids=("$@") pid alive=()
  [[ "${#pids[@]}" -gt 0 ]] || return 0

  log "Stopping ${label}: ${pids[*]}"
  if is_windows_bash && command -v taskkill.exe >/dev/null 2>&1; then
    for pid in "${pids[@]}"; do
      taskkill.exe //PID "${pid}" //T //F >/dev/null 2>&1 || true
    done
    return 0
  fi

  kill "${pids[@]}" 2>/dev/null || true
  sleep 2
  for pid in "${pids[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      alive+=("${pid}")
    fi
  done
  if [[ "${#alive[@]}" -gt 0 ]]; then
    kill -9 "${alive[@]}" 2>/dev/null || true
  fi
}

http_ready() {
  local url="$1"
  curl -fsS --max-time 5 "${url}" >/dev/null 2>&1
}

prepare_port() {
  local label="$1" port="$2" health_url="${3:-}" pids answer default_choice
  if ! port_in_use "${port}"; then
    log "OK: ${label} port ${port} is free."
    return 0
  fi

  pids="$(port_pids "${port}" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  if [[ -n "${health_url}" ]] && http_ready "${health_url}"; then
    log "${label} port ${port} is already healthy. PID(s): ${pids}"
    if [[ "${ASSUME_YES}" == "1" ]]; then
      log "Reusing healthy ${label} on port ${port}."
      return 1
    fi
    default_choice="r"
    read -r -p "Reuse healthy ${label} on port ${port}, kill it, or abort? [R/k/a]: " answer || answer=""
  else
    warn "${label} port ${port} is busy. PID(s): ${pids}"
    if [[ "${ASSUME_YES}" == "1" ]]; then
      answer="k"
    else
      default_choice="a"
      read -r -p "Kill process(es) on ${label} port ${port}, reuse anyway, or abort? [k/r/A]: " answer || answer=""
    fi
  fi

  answer="${answer:-${default_choice:-a}}"
  case "${answer}" in
    r|R) log "Reusing existing ${label} process."; return 1 ;;
    k|K|y|Y)
      pid_list=()
      while IFS= read -r pid; do
        [[ -n "${pid}" ]] && pid_list+=("${pid}")
      done < <(port_pids "${port}")
      kill_pids "${label} port ${port}" "${pid_list[@]}"
      sleep 1
      if port_in_use "${port}"; then
        fail "${label} port ${port} is still busy after kill."
      fi
      log "OK: ${label} port ${port} is free after cleanup."
      return 0
      ;;
    *) fail "Aborted because ${label} port ${port} is busy." ;;
  esac
}

resolve_python() {
  local candidate
  for candidate in python3.12 python3.11 python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
    then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  if is_windows_bash && command -v py >/dev/null 2>&1; then
    for version in -3.12 -3.11 -3; do
      if py "${version}" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
      then
        py "${version}" -c 'import sys; print(sys.executable)'
        return 0
      fi
    done
  fi
  fail "Python 3.11+ is required. Install Python and rerun ./setup.sh."
}

venv_python() {
  local candidates=(
    "${VENV_DIR}/bin/python"
    "${VENV_DIR}/bin/python3"
    "${VENV_DIR}/Scripts/python.exe"
    "${VENV_DIR}/Scripts/python"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

venv_is_valid() {
  local python_path="$1"
  "${python_path}" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
}

ensure_venv() {
  local python_bin="$1" venv_py=""
  if [[ -d "${VENV_DIR}" ]]; then
    venv_py="$(venv_python || true)"
    if [[ -n "${venv_py}" ]] && venv_is_valid "${venv_py}"; then
      printf '%s\n' "${venv_py}"
      return 0
    fi
    warn "Existing .venv is missing or uses Python older than 3.11."
    if confirm "Recreate .venv now? [y/N]:" "n"; then
      rm -rf -- "${VENV_DIR}"
    else
      fail ".venv must be recreated before setup can continue."
    fi
  fi

  log "Creating Python virtual environment..."
  "${python_bin}" -m venv "${VENV_DIR}"
  venv_py="$(venv_python || true)"
  [[ -n "${venv_py}" ]] || fail "Could not locate Python inside .venv."
  venv_is_valid "${venv_py}" || fail ".venv Python is still older than 3.11."
  printf '%s\n' "${venv_py}"
}

frontend_deps_ready() {
  [[ -f "${ROOT_DIR}/frontend/node_modules/next/package.json" ]] &&
    [[ -e "${ROOT_DIR}/frontend/node_modules/.bin/next" || -e "${ROOT_DIR}/frontend/node_modules/.bin/next.cmd" ]]
}

ensure_docker_image() {
  local image="$1"
  if ! command -v docker >/dev/null 2>&1; then
    warn "Docker is not installed. Nginx gateway and provider containers will be skipped."
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    warn "Docker daemon is not running. Start Docker before using gateway/provider containers."
    return 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    warn "Docker Compose v2 is unavailable. Nginx gateway will be skipped."
    return 1
  fi
  if docker image inspect "${image}" >/dev/null 2>&1; then
    log "OK: Docker image ${image} exists."
    return 0
  fi
  if confirm "Docker image ${image} is missing. Pull it now? [y/N]:" "n"; then
    docker pull "${image}"
    return 0
  fi
  warn "Skipped pulling ${image}; Nginx gateway will be skipped."
  return 1
}

install_dependencies() {
  local python_bin venv_py
  python_bin="$(resolve_python)"
  venv_py="$(ensure_venv "${python_bin}")"
  log "Installing backend dependencies..."
  "${venv_py}" -m pip install --upgrade pip setuptools
  (cd "${ROOT_DIR}/backend" && "${venv_py}" -m pip install -e ".[dev]")

  log "Installing frontend dependencies..."
  if [[ -f "${ROOT_DIR}/frontend/package-lock.json" ]]; then
    npm ci --prefix "${ROOT_DIR}/frontend"
  else
    npm install --prefix "${ROOT_DIR}/frontend"
  fi

  log "Seeding provider manifests..."
  "${venv_py}" "${ROOT_DIR}/backend/scripts/seed_providers.py"
  VENV_PYTHON="${venv_py}"
}

write_env_file() {
  local env_file="${ROOT_DIR}/.env.local" key value tmp
  if [[ ! -t 0 || "${ASSUME_YES}" == "1" ]]; then
    log "Skipping optional NVIDIA_API_KEY prompt in non-interactive mode."
    return 0
  fi
  read -r -p "NVIDIA API key (optional, press Enter to skip): " value || value=""
  value="${value//$'\r'/}"
  [[ -n "${value//[[:space:]]/}" ]] || return 0
  key="NVIDIA_API_KEY"
  if [[ -f "${env_file}" ]]; then
    tmp="$(mktemp)"
    awk -v key="${key}" -v value="${value}" '
      BEGIN { done = 0 }
      $0 ~ "^[[:space:]]*" key "=" { print key "=" value; done = 1; next }
      { print }
      END { if (!done) print key "=" value }
    ' "${env_file}" > "${tmp}"
    cp "${tmp}" "${env_file}"
    rm -f "${tmp}"
  else
    printf '%s=%s\n' "${key}" "${value}" > "${env_file}"
  fi
  log "Updated NVIDIA_API_KEY in .env.local."
}

start_background() {
  local label="$1" pid_file="$2" log_file="$3"
  shift 3
  mkdir -p "${LOG_DIR}"
  : > "${log_file}"
  log "Starting ${label}; log: ${log_file}"
  (
    cd "${ROOT_DIR}"
    printf '[%s] started at %s\n' "${label}" "$(date -Is)"
    exec "$@"
  ) >>"${log_file}" 2>&1 &
  printf '%s\n' "$!" > "${pid_file}"
}

wait_http() {
  local label="$1" url="$2" log_file="$3" timeout="${4:-90}" deadline
  deadline=$((SECONDS + timeout))
  until http_ready "${url}"; do
    if (( SECONDS >= deadline )); then
      warn "${label} did not become ready at ${url}."
      if [[ -f "${log_file}" ]]; then
        tail -n 80 "${log_file}" >&2 || true
      fi
      return 1
    fi
    sleep 2
  done
  log "OK: ${label} is ready at ${url}"
}

start_backend() {
  local venv_py="$1" log_file="${LOG_DIR}/backend.log" pid_file="${LOG_DIR}/backend.pid"
  if ! prepare_port "Backend" "${BACKEND_PORT}" "http://127.0.0.1:${BACKEND_PORT}/api/health"; then
    return 0
  fi
  start_background "backend" "${pid_file}" "${log_file}" \
    "${venv_py}" -m uvicorn app.main:app --host "${HOST}" --port "${BACKEND_PORT}" --app-dir backend
  wait_http "backend" "http://127.0.0.1:${BACKEND_PORT}/api/health" "${log_file}" 90
}

start_frontend() {
  local log_file="${LOG_DIR}/frontend.log" pid_file="${LOG_DIR}/frontend.pid"
  if ! prepare_port "Frontend" "${FRONTEND_PORT}" "http://127.0.0.1:${FRONTEND_PORT}"; then
    return 0
  fi
  mkdir -p "${LOG_DIR}"
  : > "${log_file}"
  log "Starting frontend; log: ${log_file}"
  (
    cd "${ROOT_DIR}/frontend"
    printf '[frontend] started at %s\n' "$(date -Is)"
    export API_PROXY_HOST=127.0.0.1
    export API_PROXY_PORT="${BACKEND_PORT}"
    export NEXT_PUBLIC_API_BASE=
    exec npm run dev -- --hostname "${HOST}" --port "${FRONTEND_PORT}"
  ) >>"${log_file}" 2>&1 &
  printf '%s\n' "$!" > "${pid_file}"
  wait_http "frontend" "http://127.0.0.1:${FRONTEND_PORT}" "${log_file}" 120
}

start_nginx() {
  local image_ready="$1"
  [[ "${SKIP_NGINX}" == "0" ]] || { log "Skipping Nginx gateway by request."; return 0; }
  [[ "${image_ready}" == "1" ]] || { warn "Skipping Nginx gateway because Docker image/runtime is unavailable."; return 0; }
  if ! prepare_port "Nginx gateway" "${NGINX_PORT}" "http://127.0.0.1:${NGINX_PORT}/nginx-health"; then
    return 0
  fi
  log "Starting Nginx gateway on port ${NGINX_PORT}..."
  (
    cd "${ROOT_DIR}"
    AIHUB_NGINX_PORT="${NGINX_PORT}" \
    AIHUB_FRONTEND_UPSTREAM="host.docker.internal:${FRONTEND_PORT}" \
    AIHUB_BACKEND_UPSTREAM="host.docker.internal:${BACKEND_PORT}" \
    docker compose -f docker-compose.nginx.yml up -d --remove-orphans
  )
  wait_http "nginx gateway" "http://127.0.0.1:${NGINX_PORT}/nginx-health" "${LOG_DIR}/nginx.log" 60 || true
}

print_report() {
  log "Runtime report"
  printf '  Frontend: http://localhost:%s\n' "${FRONTEND_PORT}"
  printf '  Backend:  http://localhost:%s/api/health\n' "${BACKEND_PORT}"
  printf '  Gateway:  http://localhost:%s\n' "${NGINX_PORT}"
  printf '  Logs:     %s\n' "${LOG_DIR}"
  if http_ready "http://127.0.0.1:${FRONTEND_PORT}"; then printf '  frontend: ready\n'; else printf '  frontend: not ready\n'; fi
  if http_ready "http://127.0.0.1:${BACKEND_PORT}/api/health"; then printf '  backend: ready\n'; else printf '  backend: not ready\n'; fi
  if http_ready "http://127.0.0.1:${NGINX_PORT}/nginx-health"; then printf '  gateway: ready\n'; else printf '  gateway: skipped or not ready\n'; fi
}

for arg in "$@"; do
  case "${arg}" in
    --yes|-y) ASSUME_YES=1 ;;
    --no-start) NO_START=1 ;;
    --skip-nginx) SKIP_NGINX=1 ;;
    --help|-h) usage; exit 0 ;;
    *) usage; fail "Unknown option: ${arg}" ;;
  esac
done

validate_port "Frontend" "${FRONTEND_PORT}"
validate_port "Backend" "${BACKEND_PORT}"
validate_port "Nginx gateway" "${NGINX_PORT}"

log "AI Hub setup starting."
log "Ports: gateway=${NGINX_PORT}, frontend=${FRONTEND_PORT}, backend=${BACKEND_PORT}"

require_command "Git" git "Install Git from https://git-scm.com/."
require_command "Node.js" node "Install Node.js LTS from https://nodejs.org/."
require_command "npm" npm "Install Node.js LTS, which includes npm."
require_command "curl" curl "Install curl or add it to PATH."

write_env_file
VENV_PYTHON=""
install_dependencies
[[ -n "${VENV_PYTHON}" ]] || fail "Could not resolve virtualenv Python path."

IMAGE_READY=0
if [[ "${SKIP_NGINX}" == "0" ]]; then
  if ensure_docker_image "${NGINX_IMAGE}"; then
    IMAGE_READY=1
  fi
fi

if [[ "${NO_START}" == "1" ]]; then
  log "Dependency setup complete. Service start skipped by --no-start."
  exit 0
fi

mkdir -p "${LOG_DIR}"
start_backend "${VENV_PYTHON}"
start_frontend
start_nginx "${IMAGE_READY}"
print_report
log "Setup complete."

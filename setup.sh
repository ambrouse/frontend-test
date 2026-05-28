#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
HUB_LOG_DIR="${ROOT_DIR}/logs/hub"
HUB_FRONTEND_PORT="${AIHUB_FRONTEND_PORT:-6901}"
HUB_BACKEND_PORT="${AIHUB_BACKEND_PORT:-6902}"
HUB_NGINX_PORT="${AIHUB_NGINX_PORT:-6900}"
HUB_HOST="${AIHUB_HOST:-0.0.0.0}"

is_windows_bash() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_install() {
  local label="$1"
  local answer
  read -r -p "${label} is missing. Install it now if possible? [y/N]: " answer
  [[ "${answer}" =~ ^([yY]|yes|YES)$ ]]
}

sudo_cmd() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "sudo is required to install packages. Install manually, then rerun setup.sh." >&2
    return 1
  fi
}

detect_manager() {
  if command -v apt-get >/dev/null 2>&1; then echo "apt"; return; fi
  if command -v dnf >/dev/null 2>&1; then echo "dnf"; return; fi
  if command -v pacman >/dev/null 2>&1; then echo "pacman"; return; fi
  if command -v brew >/dev/null 2>&1; then echo "brew"; return; fi
  echo "none"
}

install_packages() {
  local manager="$1"
  shift
  case "${manager}" in
    apt)
      sudo_cmd apt-get update
      sudo_cmd apt-get install -y "$@"
      ;;
    dnf)
      sudo_cmd dnf install -y "$@"
      ;;
    pacman)
      sudo_cmd pacman -Sy --needed --noconfirm "$@"
      ;;
    brew)
      brew install "$@"
      ;;
    *)
      echo "No supported package manager detected. Install manually: $*" >&2
      return 1
      ;;
  esac
}

ensure_tool() {
  local label="$1"
  local command_name="$2"
  shift 2
  local packages=("$@")
  if command -v "${command_name}" >/dev/null 2>&1; then
    echo "OK: ${label}"
    return 0
  fi
  if is_windows_bash; then
    echo "${label} is missing. On Windows, run setup.ps1 from PowerShell for guided install." >&2
    return 1
  fi
  if prompt_install "${label}"; then
    install_packages "$(detect_manager)" "${packages[@]}"
  else
    echo "Skipped ${label} install." >&2
  fi
  command -v "${command_name}" >/dev/null 2>&1
}

resolve_python() {
  for candidate in python3.12 python3.11 python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" - 2>/dev/null <<'PY'
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
      if py "${version}" - 2>/dev/null <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
      then
        local executable
        executable="$(py "${version}" -c 'import sys; print(sys.executable)' 2>/dev/null)"
        if command -v cygpath >/dev/null 2>&1; then
          executable="$(cygpath -u "${executable}")"
        fi
        printf '%s\n' "${executable}"
        return 0
      fi
    done
  fi

  if is_windows_bash; then
    echo "Python 3.11+ is required. On Windows, run setup.ps1 from PowerShell." >&2
    return 1
  fi
  if prompt_install "Python 3.11+"; then
    case "$(detect_manager)" in
      apt) install_packages apt python3 python3-venv python3-pip ;;
      dnf) install_packages dnf python3 python3-pip ;;
      pacman) install_packages pacman python python-pip ;;
      brew) install_packages brew python@3.12 ;;
      *) echo "Install Python 3.11+ manually, then rerun setup.sh." >&2; return 1 ;;
    esac
  fi

  for candidate in python3.12 python3.11 python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" - 2>/dev/null <<'PY'
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
      if py "${version}" - 2>/dev/null <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
      then
        local executable
        executable="$(py "${version}" -c 'import sys; print(sys.executable)' 2>/dev/null)"
        if command -v cygpath >/dev/null 2>&1; then
          executable="$(cygpath -u "${executable}")"
        fi
        printf '%s\n' "${executable}"
        return 0
      fi
    done
  fi
  echo "Python 3.11+ is still unavailable. Install it manually, then rerun setup.sh." >&2
  return 1
}

find_venv_python() {
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

python_major_minor() {
  "${PYTHON_BIN}" - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
PY
}

install_python_venv_support() {
  local manager
  manager="$(detect_manager)"
  case "${manager}" in
    apt)
      local version
      version="$(python_major_minor)"
      install_packages apt "python${version}-venv" || install_packages apt python3-venv
      ;;
    dnf)
      install_packages dnf python3 python3-pip
      ;;
    pacman)
      install_packages pacman python python-pip
      ;;
    brew)
      install_packages brew python@3.12
      ;;
    *)
      echo "Install Python venv support manually, then rerun setup.sh." >&2
      return 1
      ;;
  esac
}

remove_venv_dir() {
  if [[ "${VENV_DIR}" != "${ROOT_DIR}/.venv" ]]; then
    echo "Refusing to remove unexpected venv path: ${VENV_DIR}" >&2
    return 1
  fi
  rm -rf -- "${VENV_DIR}"
}

venv_python_is_supported() {
  local python_path="$1"
  "${python_path}" - 2>/dev/null <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
}

create_venv() {
  if "${PYTHON_BIN}" -m venv "${VENV_DIR}"; then
    return 0
  fi

  if is_windows_bash; then
    echo "Could not create Python virtual environment. On Windows, run setup.ps1 from PowerShell." >&2
    return 1
  fi

  echo "Python venv support is missing or incomplete." >&2
  if prompt_install "Python venv support"; then
    install_python_venv_support
    remove_venv_dir
    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
  else
    echo "Skipped Python venv support install." >&2
    return 1
  fi
}

write_local_env_value() {
  local key="$1"
  local value="$2"
  local env_file="${ROOT_DIR}/.env.local"
  local tmp_file

  if [[ -f "${env_file}" ]]; then
    tmp_file="$(mktemp)"
    awk -v key="${key}" -v value="${value}" '
      BEGIN { written = 0 }
      $0 ~ "^[[:space:]]*" key "=" {
        print key "=" value
        written = 1
        next
      }
      { print }
      END {
        if (!written) {
          print key "=" value
        }
      }
    ' "${env_file}" > "${tmp_file}"
    cat "${tmp_file}" > "${env_file}"
    rm -f "${tmp_file}"
  else
    printf '%s=%s\n' "${key}" "${value}" > "${env_file}"
  fi
}

print_backend_hints() {
  if is_windows_bash; then
    echo "Backend (PowerShell): .\\.venv\\Scripts\\python.exe -m uvicorn app.main:app --host ${HUB_HOST} --port ${HUB_BACKEND_PORT} --reload --app-dir backend"
    echo "Backend (Git Bash, reload): WATCHFILES_FORCE_POLLING=true ./.venv/Scripts/python.exe -m uvicorn app.main:app --host ${HUB_HOST} --port ${HUB_BACKEND_PORT} --reload --reload-dir backend --app-dir backend"
    echo "Backend (Git Bash, no reload): ./.venv/Scripts/python.exe -m uvicorn app.main:app --host ${HUB_HOST} --port ${HUB_BACKEND_PORT} --app-dir backend"
  else
    echo "Backend:  ./.venv/bin/python -m uvicorn app.main:app --host ${HUB_HOST} --port ${HUB_BACKEND_PORT} --reload --app-dir backend"
  fi
}

detect_lan_ip() {
  local ip
  if command -v hostname >/dev/null 2>&1; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if [[ -n "${ip}" ]]; then
      printf '%s\n' "${ip}"
      return 0
    fi
  fi
  return 1
}

ensure_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "OK: Docker"
  elif ! is_windows_bash && prompt_install "Docker"; then
    case "$(detect_manager)" in
      apt) install_packages apt docker.io docker-compose-plugin ;;
      dnf) install_packages dnf docker docker-compose-plugin ;;
      pacman) install_packages pacman docker docker-compose ;;
      brew) install_packages brew docker docker-compose ;;
      *) echo "Install Docker manually, then rerun setup.sh." >&2 ;;
    esac
  else
    echo "Docker is optional for Hub boot, but required for real provider install/run." >&2
  fi

  if command -v docker >/dev/null 2>&1; then
    if ! docker compose version >/dev/null 2>&1; then
      echo "Docker Compose v2 is not responding. Install the compose plugin before provider install/run." >&2
    fi
    if ! docker info >/dev/null 2>&1; then
      echo "Docker daemon is not running. Start Docker Desktop/Engine before provider install/run." >&2
    fi
  fi
}

pid_from_file() {
  local pid_file="$1"
  [[ -f "${pid_file}" ]] || return 1
  tr -cd '0-9' < "${pid_file}"
}

stop_pid_file() {
  local label="$1" pid_file="$2" pid
  pid="$(pid_from_file "${pid_file}" || true)"
  if [[ -z "${pid}" ]]; then
    rm -f "${pid_file}"
    return 0
  fi

  if kill -0 "${pid}" 2>/dev/null; then
    echo "Stopping previous ${label} process (${pid})..."
    kill "${pid}" 2>/dev/null || true
    sleep 1
    if kill -0 "${pid}" 2>/dev/null; then
      kill -9 "${pid}" 2>/dev/null || true
    fi
  fi
  rm -f "${pid_file}"
}

port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "sport = :${port}" 2>/dev/null | awk 'NR > 1 { found = 1 } END { exit found ? 0 : 1 }'
    return $?
  fi
  if command -v fuser >/dev/null 2>&1; then
    fuser "${port}/tcp" >/dev/null 2>&1
    return $?
  fi
  return 1
}

require_free_port() {
  local label="$1" port="$2"
  if port_in_use "${port}"; then
    echo "${label} port ${port} is already in use. Run ./stop.sh or set a free AIHUB_*_PORT in 6900-6950." >&2
    return 1
  fi
}

require_hub_port_range() {
  local label="$1" port="$2"
  if ! [[ "${port}" =~ ^[0-9]+$ ]] || (( port < 6900 || port > 6950 )); then
    echo "${label} port must be in the 6900-6950 range, got: ${port}" >&2
    return 1
  fi
}

wait_http() {
  local url="$1" label="$2" log_file="$3" timeout="${4:-90}" end
  end=$((SECONDS + timeout))
  until curl -fsS --max-time 5 "${url}" >/dev/null 2>&1; do
    if (( SECONDS >= end )); then
      echo "${label} did not become ready at ${url}." >&2
      if [[ -f "${log_file}" ]]; then
        echo "--- Last ${label} log lines (${log_file}) ---" >&2
        tail -n 80 "${log_file}" >&2 || true
      fi
      return 1
    fi
    sleep 2
  done
  echo "OK: ${label} is ready at ${url}"
}

start_backend() {
  local log_file="${HUB_LOG_DIR}/backend.log"
  local pid_file="${HUB_LOG_DIR}/backend.pid"
  local detach_cmd=()
  if command -v setsid >/dev/null 2>&1; then
    detach_cmd=(setsid)
  fi
  stop_pid_file "backend" "${pid_file}"
  require_free_port "Backend" "${HUB_BACKEND_PORT}"

  : > "${log_file}"
  echo "Starting backend on ${HUB_HOST}:${HUB_BACKEND_PORT}..."
  (
    cd "${ROOT_DIR}"
    nohup "${detach_cmd[@]}" "${VENV_PYTHON}" -m uvicorn app.main:app \
      --host "${HUB_HOST}" \
      --port "${HUB_BACKEND_PORT}" \
      --app-dir backend \
      > "${log_file}" 2>&1 &
    printf '%s\n' "$!" > "${pid_file}"
  )
  wait_http "http://127.0.0.1:${HUB_BACKEND_PORT}/api/health" "backend" "${log_file}"
}

start_frontend() {
  local log_file="${HUB_LOG_DIR}/frontend.log"
  local pid_file="${HUB_LOG_DIR}/frontend.pid"
  local detach_cmd=()
  if command -v setsid >/dev/null 2>&1; then
    detach_cmd=(setsid)
  fi
  stop_pid_file "frontend" "${pid_file}"
  require_free_port "Frontend" "${HUB_FRONTEND_PORT}"

  : > "${log_file}"
  echo "Starting frontend on ${HUB_HOST}:${HUB_FRONTEND_PORT}..."
  (
    cd "${ROOT_DIR}/frontend"
    nohup "${detach_cmd[@]}" env \
      AIHUB_LAN_HOST="${LAN_IP:-}" \
      API_PROXY_HOST="127.0.0.1" \
      API_PROXY_PORT="${HUB_BACKEND_PORT}" \
      NEXT_PUBLIC_API_BASE="" \
      npm run dev -- --hostname "${HUB_HOST}" --port "${HUB_FRONTEND_PORT}" \
      > "${log_file}" 2>&1 &
    printf '%s\n' "$!" > "${pid_file}"
  )
  wait_http "http://127.0.0.1:${HUB_FRONTEND_PORT}" "frontend" "${log_file}" 120
}

start_nginx_gateway() {
  local log_file="${HUB_LOG_DIR}/nginx.log"
  if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose is unavailable; skipping nginx gateway. Open http://localhost:${HUB_FRONTEND_PORT} instead." >&2
    return 0
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Docker daemon is not running; skipping nginx gateway. Open http://localhost:${HUB_FRONTEND_PORT} instead." >&2
    return 0
  fi

  : > "${log_file}"
  (cd "${ROOT_DIR}" && docker compose -f docker-compose.nginx.yml down --remove-orphans >/dev/null 2>&1) || true
  require_free_port "Nginx gateway" "${HUB_NGINX_PORT}"
  echo "Starting nginx gateway on 0.0.0.0:${HUB_NGINX_PORT}..."
  (
    cd "${ROOT_DIR}"
    AIHUB_NGINX_PORT="${HUB_NGINX_PORT}" \
    AIHUB_FRONTEND_UPSTREAM="host.docker.internal:${HUB_FRONTEND_PORT}" \
    AIHUB_BACKEND_UPSTREAM="host.docker.internal:${HUB_BACKEND_PORT}" \
    docker compose -f docker-compose.nginx.yml up -d --remove-orphans
  ) > "${log_file}" 2>&1 || {
    echo "Nginx gateway failed to start. See ${log_file}" >&2
    tail -n 80 "${log_file}" >&2 || true
    return 1
  }
  wait_http "http://127.0.0.1:${HUB_NGINX_PORT}/nginx-health" "nginx gateway" "${log_file}" 60
}

start_hub() {
  mkdir -p "${HUB_LOG_DIR}"
  require_hub_port_range "Nginx gateway" "${HUB_NGINX_PORT}"
  require_hub_port_range "Frontend" "${HUB_FRONTEND_PORT}"
  require_hub_port_range "Backend" "${HUB_BACKEND_PORT}"
  echo "Booting AI Hub on ports ${HUB_NGINX_PORT}, ${HUB_FRONTEND_PORT}, ${HUB_BACKEND_PORT}..."
  start_backend
  start_frontend
  start_nginx_gateway
}

echo "AI Hub setup"
echo "This checks prerequisites, installs frontend/backend dependencies, and seeds provider manifests."

ensure_tool "Git" git git
ensure_tool "Node.js" node nodejs
ensure_tool "npm" npm npm
ensure_docker

NVIDIA_API_KEY_INPUT=""
read -r -p "NVIDIA API key (optional, press Enter to skip): " NVIDIA_API_KEY_INPUT || true
NVIDIA_API_KEY_INPUT="${NVIDIA_API_KEY_INPUT//$'\r'/}"
NVIDIA_API_KEY_INPUT="${NVIDIA_API_KEY_INPUT#"${NVIDIA_API_KEY_INPUT%%[![:space:]]*}"}"
NVIDIA_API_KEY_INPUT="${NVIDIA_API_KEY_INPUT%"${NVIDIA_API_KEY_INPUT##*[![:space:]]}"}"

if [[ -n "${NVIDIA_API_KEY_INPUT}" ]]; then
  write_local_env_value "NVIDIA_API_KEY" "${NVIDIA_API_KEY_INPUT}"
  echo "Updated NVIDIA_API_KEY in .env.local (gitignored)."
fi

PYTHON_BIN="$(resolve_python)"
if [[ ! -d "${VENV_DIR}" ]]; then
  create_venv
fi
if ! VENV_PYTHON="$(find_venv_python)"; then
  echo "Existing venv is incomplete. Recreating ${VENV_DIR}..." >&2
  create_venv
  if ! VENV_PYTHON="$(find_venv_python)"; then
    echo "Could not locate venv python interpreter in ${VENV_DIR}." >&2
    echo "Expected one of: .venv/bin/python, .venv/bin/python3, or .venv/Scripts/python(.exe)." >&2
    exit 1
  fi
fi
if ! venv_python_is_supported "${VENV_PYTHON}"; then
  echo "Existing venv Python is older than 3.11. Recreating ${VENV_DIR}..." >&2
  remove_venv_dir
  create_venv
  if ! VENV_PYTHON="$(find_venv_python)" || ! venv_python_is_supported "${VENV_PYTHON}"; then
    echo "Could not create a Python 3.11+ virtual environment in ${VENV_DIR}." >&2
    exit 1
  fi
fi

"${VENV_PYTHON}" -m pip install --upgrade pip setuptools
pushd "${ROOT_DIR}/backend" >/dev/null
"${VENV_PYTHON}" -m pip install -e ".[dev]"
popd >/dev/null

if [[ -f "${ROOT_DIR}/frontend/package-lock.json" ]]; then
  npm ci --prefix "${ROOT_DIR}/frontend"
else
  npm install --prefix "${ROOT_DIR}/frontend"
fi

"${VENV_PYTHON}" "${ROOT_DIR}/backend/scripts/seed_providers.py"

LAN_IP="$(detect_lan_ip || true)"
start_hub

echo "Setup complete."
print_backend_hints
echo "Frontend: cd frontend && npm run dev -- --hostname ${HUB_HOST} --port ${HUB_FRONTEND_PORT}"
echo "Local frontend: http://localhost:${HUB_FRONTEND_PORT}"
echo "Local gateway:  http://localhost:${HUB_NGINX_PORT}"
if [[ -n "${LAN_IP}" ]]; then
  echo "LAN frontend: http://${LAN_IP}:${HUB_FRONTEND_PORT}"
  echo "LAN gateway:  http://${LAN_IP}:${HUB_NGINX_PORT}"
fi
echo "Logs: ${HUB_LOG_DIR}"

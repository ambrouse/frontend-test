#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"

resolve_python() {
  for candidate in python3.12 python3.11 python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" - <<'PY'
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
    then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  echo "Python 3.11+ is required. Install python3.11/python3.12 with your OS package manager." >&2
  return 1
}

echo "AI Hub setup"
echo "This installs frontend/backend dependencies and seeds provider manifests."
read -r -p "NVIDIA API key (optional, press Enter to skip): " NVIDIA_API_KEY_INPUT

if [[ -n "${NVIDIA_API_KEY_INPUT}" ]]; then
  {
    echo "NVIDIA_API_KEY=${NVIDIA_API_KEY_INPUT}"
  } > "${ROOT_DIR}/.env.local"
  echo "Wrote local key to .env.local (gitignored)."
fi

PYTHON_BIN="$(resolve_python)"
if [[ ! -d "${VENV_DIR}" ]]; then
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
fi
VENV_PYTHON="${VENV_DIR}/bin/python"
"${VENV_PYTHON}" -m pip install --upgrade pip setuptools
"${VENV_PYTHON}" -m pip install -e "${ROOT_DIR}/backend[dev]"

if [[ -f "${ROOT_DIR}/frontend/package-lock.json" ]]; then
  npm ci --prefix "${ROOT_DIR}/frontend"
else
  npm install --prefix "${ROOT_DIR}/frontend"
fi

"${VENV_PYTHON}" "${ROOT_DIR}/backend/scripts/seed_providers.py"

echo "Setup complete."
echo "Backend:  ./.venv/bin/python -m uvicorn app.main:app --reload --app-dir backend"
echo "Frontend: cd frontend && npm run dev"

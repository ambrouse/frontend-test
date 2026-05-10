#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "AI Hub setup"
echo "This installs frontend/backend dependencies and seeds provider manifests."
read -r -p "NVIDIA API key (optional, press Enter to skip): " NVIDIA_API_KEY_INPUT

if [[ -n "${NVIDIA_API_KEY_INPUT}" ]]; then
  {
    echo "NVIDIA_API_KEY=${NVIDIA_API_KEY_INPUT}"
  } > "${ROOT_DIR}/.env.local"
  echo "Wrote local key to .env.local (gitignored)."
fi

python -m pip install --upgrade pip setuptools
python -m pip install -e "${ROOT_DIR}/backend[dev]"

if [[ -f "${ROOT_DIR}/frontend/package-lock.json" ]]; then
  npm ci --prefix "${ROOT_DIR}/frontend"
else
  npm install --prefix "${ROOT_DIR}/frontend"
fi

python "${ROOT_DIR}/backend/scripts/seed_providers.py"

echo "Setup complete."
echo "Backend:  cd backend && uvicorn app.main:app --reload"
echo "Frontend: cd frontend && npm run dev"

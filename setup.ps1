$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "AI Hub setup"
Write-Host "This installs frontend/backend dependencies and seeds provider manifests."
$NvidiaApiKeyInput = Read-Host "NVIDIA API key (optional, press Enter to skip)"

if ($NvidiaApiKeyInput) {
  "NVIDIA_API_KEY=$NvidiaApiKeyInput" | Set-Content -LiteralPath (Join-Path $RootDir ".env.local") -Encoding UTF8
  Write-Host "Wrote local key to .env.local (gitignored)."
}

python -m pip install --upgrade pip setuptools
python -m pip install -e "$RootDir/backend[dev]"

if (Test-Path -LiteralPath (Join-Path $RootDir "frontend/package-lock.json")) {
  npm.cmd ci --prefix (Join-Path $RootDir "frontend")
} else {
  npm.cmd install --prefix (Join-Path $RootDir "frontend")
}

python (Join-Path $RootDir "backend/scripts/seed_providers.py")

Write-Host "Setup complete."
Write-Host "Backend:  cd backend; uvicorn app.main:app --reload"
Write-Host "Frontend: cd frontend; npm run dev"

$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "multi-agent-intelligent-warehouse" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3001" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8091" }
function Get-LocalNvidiaApiKey {
  param([string]$ProviderRoot)
  try {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProviderRoot "..\.."))
    $LocalEnvFile = Join-Path $RepoRoot ".env.local"
    if (!(Test-Path $LocalEnvFile)) { return "" }
    $Line = Get-Content -Path $LocalEnvFile | Where-Object { $_ -match '^\s*NVIDIA_API_KEY\s*=' } | Select-Object -Last 1
    if (-not $Line) { return "" }
    $Value = ($Line -split '=', 2)[1].Trim()
    if ($Value.StartsWith('"') -and $Value.EndsWith('"') -and $Value.Length -ge 2) {
      $Value = $Value.Substring(1, $Value.Length - 2)
    }
    return $Value
  } catch {
    return ""
  }
}
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -ne "1") {
  if (-not $env:NVIDIA_API_KEY) {
    $ResolvedNvidiaApiKey = Get-LocalNvidiaApiKey -ProviderRoot $Root
    if ($ResolvedNvidiaApiKey) {
      $env:NVIDIA_API_KEY = $ResolvedNvidiaApiKey
      $env:EMBEDDING_API_KEY = $ResolvedNvidiaApiKey
      $env:RAIL_API_KEY = $ResolvedNvidiaApiKey
    }
  }
  if (!(Test-Path $DeployDir)) {
    $SetupScript = Join-Path $Root "scripts\windows\setup.ps1"
    if (!(Test-Path $SetupScript)) { throw "deploy directory missing and setup script is unavailable" }
    & $SetupScript
    if ($LASTEXITCODE -ne 0) { throw "setup failed while preparing deploy directory" }
  }
  Push-Location $DeployDir
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $env:BACKEND_PORT = $BackendPort
    $env:HOST_BACKEND_PORT = $BackendPort
    $env:FRONTEND_PORT = $Port
    $env:HOST_FRONTEND_PORT = $Port
    docker compose --env-file deploy/compose/.env -f deploy/compose/docker-compose.dev.yaml up -d --wait --wait-timeout 600
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed with exit code $LASTEXITCODE" }
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
    Pop-Location
  }
}
$Status = @{ projectId=$Id; state="running"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Running warehouse stack"; progressPercent=100; health=@{ level="ok"; message="Started" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="running"; port=[int]$Port } | ConvertTo-Json -Compress)

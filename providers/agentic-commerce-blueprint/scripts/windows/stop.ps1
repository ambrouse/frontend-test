$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "agentic-commerce-blueprint" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }
if ($env:AIHUB_DRY_RUN -ne "1" -and (Test-Path $DeployDir)) {
  Push-Location $DeployDir
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    docker compose -f docker-compose.infra.yml -f docker-compose.yml down
    if ($LASTEXITCODE -ne 0) { throw "docker compose down failed with exit code $LASTEXITCODE" }
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
    Pop-Location
  }
}
$Status = @{ projectId=$Id; state="stopped"; pid=$null; port=[int]$Port; platform="windows"; startedAt=$null; uptimeSec=0; currentStep="Stopped"; progressPercent=100; health=@{ level="ok"; message="Stopped" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="stopped" } | ConvertTo-Json -Compress)

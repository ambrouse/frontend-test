$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "agentic-commerce-blueprint" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -ne "1") {
  if (!(Test-Path $DeployDir)) { throw "deploy directory missing; install first" }
  Push-Location $DeployDir
  $PreviousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $env:HTTP_HOST_PORT = $Port
    docker network inspect acp-infra-network *> $null
    if ($LASTEXITCODE -ne 0) {
      docker network create acp-infra-network
      if ($LASTEXITCODE -ne 0) { throw "docker network create acp-infra-network failed with exit code $LASTEXITCODE" }
    }
    docker compose -f docker-compose.infra.yml -f docker-compose.yml build promotion-agent
    if ($LASTEXITCODE -ne 0) { throw "docker compose build promotion-agent failed with exit code $LASTEXITCODE" }
    docker compose -f docker-compose.infra.yml -f docker-compose.yml up -d --wait --wait-timeout 600
    if ($LASTEXITCODE -ne 0) { throw "docker compose up failed with exit code $LASTEXITCODE" }
  } finally {
    $ErrorActionPreference = $PreviousErrorActionPreference
    Pop-Location
  }
}
$Status = @{ projectId=$Id; state="running"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Running commerce stack"; progressPercent=100; health=@{ level="ok"; message="Started" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="running"; port=[int]$Port } | ConvertTo-Json -Compress)

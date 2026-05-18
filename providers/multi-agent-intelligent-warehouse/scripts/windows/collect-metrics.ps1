$ErrorActionPreference = "Stop"

$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot "multi-agent-intelligent-warehouse" }
$FrontendPort = $env:AIHUB_PORT; if (-not $FrontendPort) { $FrontendPort = "3001" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8091" }

$BackendOk = $false
try {
  $BackendOk = (Invoke-WebRequest -Uri "http://127.0.0.1:$BackendPort/api/v1/health" -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200
} catch {}

$RunningContainers = 0
$ComposeFile = Join-Path $DeployDir "deploy\compose\docker-compose.dev.yaml"
$EnvFile = Join-Path $DeployDir "deploy\compose\.env"
if ((Test-Path $ComposeFile) -and (Test-Path $EnvFile)) {
  try {
    Push-Location $DeployDir
    $RunningContainers = (docker compose --env-file "deploy/compose/.env" -f "deploy/compose/docker-compose.dev.yaml" ps --services --filter "status=running" | Measure-Object).Count
  } catch {
    $RunningContainers = 0
  } finally {
    Pop-Location
  }
}

$Headline = if ($BackendOk) { "$RunningContainers containers" } else { "not running" }
$Secondary = if ($BackendOk) { "backend $BackendPort, frontend $FrontendPort" } else { "backend unavailable" }
$SampledAt = (Get-Date).ToUniversalTime().ToString("o")
$Metrics = @{
  sampledAt = $SampledAt
  platform = "windows"
  process = @{ cpuPercent = 0; ramMb = 0; gpuPercent = 0; vramMb = 0 }
  service = @{ requestsTotal = 0; requestsPerMin = 0; latencyP50Ms = 0; latencyP95Ms = 0; errorsLastHour = 0; runningContainers = $RunningContainers; backendOk = $BackendOk; frontendPort = [int]$FrontendPort; backendPort = [int]$BackendPort }
  benchmark = @{ headlineMetric = $Headline; secondaryMetric = $Secondary; latencyMs = 0; throughput = 0; vramPeakMb = 0; measuredAt = $SampledAt }
}
New-Item -ItemType Directory -Force -Path "$Root\runtime" | Out-Null
$Metrics | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\metrics.json" -Encoding utf8
$Metrics | ConvertTo-Json -Compress -Depth 5

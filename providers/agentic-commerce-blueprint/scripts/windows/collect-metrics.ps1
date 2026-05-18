$ErrorActionPreference = "Stop"

$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot "agentic-commerce-blueprint" }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }

$GatewayOk = $false
try {
  $GatewayOk = (Invoke-WebRequest -Uri "http://127.0.0.1:$Port/api/health" -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200
} catch {}

$RunningContainers = 0
if ((Test-Path (Join-Path $DeployDir "docker-compose.infra.yml")) -and (Test-Path (Join-Path $DeployDir "docker-compose.yml"))) {
  try {
    Push-Location $DeployDir
    $RunningContainers = (docker compose -f docker-compose.infra.yml -f docker-compose.yml ps --services --filter "status=running" | Measure-Object).Count
  } catch {
    $RunningContainers = 0
  } finally {
    Pop-Location
  }
}

$Headline = if ($GatewayOk) { "$RunningContainers containers" } else { "not running" }
$Secondary = if ($GatewayOk) { "gateway $Port healthy" } else { "gateway unavailable" }
$SampledAt = (Get-Date).ToUniversalTime().ToString("o")
$Metrics = @{
  sampledAt = $SampledAt
  platform = "windows"
  process = @{ cpuPercent = 0; ramMb = 0; gpuPercent = 0; vramMb = 0 }
  service = @{ requestsTotal = 0; requestsPerMin = 0; latencyP50Ms = 0; latencyP95Ms = 0; errorsLastHour = 0; runningContainers = $RunningContainers; gatewayOk = $GatewayOk; gatewayPort = [int]$Port }
  benchmark = @{ headlineMetric = $Headline; secondaryMetric = $Secondary; latencyMs = 0; throughput = 0; vramPeakMb = 0; measuredAt = $SampledAt }
}
New-Item -ItemType Directory -Force -Path "$Root\runtime" | Out-Null
$Metrics | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\metrics.json" -Encoding utf8
$Metrics | ConvertTo-Json -Compress -Depth 5

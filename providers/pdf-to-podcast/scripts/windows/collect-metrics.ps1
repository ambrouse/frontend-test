$ErrorActionPreference = "Stop"

$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot "pdf-to-podcast"
$PortsPath = Join-Path $DeployDir ".auto-ports.env"
$Ports = if (Test-Path $PortsPath) { Get-Content $PortsPath | ConvertFrom-StringData } else { @{ FRONTEND_PORT = "7860"; API_SERVICE_PORT = "8002" } }
$RunningContainers = 0
try {
  $RunningContainers = (docker compose -f (Join-Path $DeployDir "docker-compose.yaml") -f (Join-Path $DeployDir ".auto-ports.compose.yaml") --env-file (Join-Path $DeployDir ".env") ps --services --filter "status=running" | Measure-Object).Count
} catch {
}
$Metrics = @{
  sampledAt = (Get-Date).ToUniversalTime().ToString("o")
  platform = "windows"
  process = @{ cpuPercent = 0; ramMb = 0; gpuPercent = 0; vramMb = 0 }
  service = @{ requestsTotal = 0; requestsPerMin = 0; latencyP50Ms = 0; latencyP95Ms = 0; errorsLastHour = 0; runningContainers = $RunningContainers; frontendPort = [int]$Ports.FRONTEND_PORT; apiPort = [int]$Ports.API_SERVICE_PORT }
  benchmark = @{ headlineMetric = "$RunningContainers containers"; secondaryMetric = "frontend $($Ports.FRONTEND_PORT)"; vramPeakMb = 0 }
}
$Metrics | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\metrics.json" -Encoding utf8
$Metrics | ConvertTo-Json -Compress

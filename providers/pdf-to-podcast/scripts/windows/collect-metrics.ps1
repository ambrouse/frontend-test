$ErrorActionPreference = "Stop"

$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot "pdf-to-podcast" }
$PortsPath = Join-Path $DeployDir ".auto-ports.env"
$DefaultFrontendPort = $env:AIHUB_PORT; if (-not $DefaultFrontendPort) { $DefaultFrontendPort = "7860" }
$DefaultApiPort = $env:API_SERVICE_PORT; if (-not $DefaultApiPort) { $DefaultApiPort = "8002" }
$Ports = if (Test-Path $PortsPath) { Get-Content $PortsPath | ConvertFrom-StringData } else { @{ FRONTEND_PORT = $DefaultFrontendPort; API_SERVICE_PORT = $DefaultApiPort } }
$RunningContainers = 0
try {
  $ComposeFile = Join-Path $DeployDir "docker-compose.yaml"
  $PortsComposeFile = Join-Path $DeployDir ".auto-ports.compose.yaml"
  $EnvFile = Join-Path $DeployDir ".env"
  if ((Test-Path $ComposeFile) -and (Test-Path $PortsComposeFile) -and (Test-Path $EnvFile)) {
    $RunningContainers = (docker compose -f $ComposeFile -f $PortsComposeFile --env-file $EnvFile ps --services --filter "status=running" | Measure-Object).Count
  }
} catch {
}
$SampledAt = (Get-Date).ToUniversalTime().ToString("o")
$Metrics = @{
  sampledAt = $SampledAt
  platform = "windows"
  process = @{ cpuPercent = 0; ramMb = 0; gpuPercent = 0; vramMb = 0 }
  service = @{ requestsTotal = 0; requestsPerMin = 0; latencyP50Ms = 0; latencyP95Ms = 0; errorsLastHour = 0; runningContainers = $RunningContainers; frontendPort = [int]$Ports.FRONTEND_PORT; apiPort = [int]$Ports.API_SERVICE_PORT }
  benchmark = @{ headlineMetric = "$RunningContainers containers"; secondaryMetric = "frontend $($Ports.FRONTEND_PORT)"; latencyMs = 0; throughput = 0; vramPeakMb = 0; measuredAt = $SampledAt }
}
$Metrics | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\metrics.json" -Encoding utf8
$Metrics | ConvertTo-Json -Compress

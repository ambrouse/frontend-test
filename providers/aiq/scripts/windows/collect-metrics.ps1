$ErrorActionPreference = "Stop"

$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot "aiq" }
$PortsPath = Join-Path $DeployDir ".runtime\ports.env"
$Ports = if (Test-Path $PortsPath) { Get-Content $PortsPath | ConvertFrom-StringData } else { @{ FRONTEND_PORT = "13080"; BACKEND_PORT = "18080" } }
$BackendPort = [int]$Ports.BACKEND_PORT
$FrontendPort = [int]$Ports.FRONTEND_PORT
$BackendPidPath = Join-Path $DeployDir ".runtime\backend.pid"
$FrontendPidPath = Join-Path $DeployDir ".runtime\frontend.pid"

function Get-ProcSample {
  param([string]$Path, [int]$Port)
  $ProcessId = $null
  if (Test-Path $Path) {
    $Text = (Get-Content $Path -Raw).Trim()
    if ($Text -match '^\d+$') { $ProcessId = [int]$Text }
  }
  if ($ProcessId) {
    try {
      $Proc = Get-Process -Id $ProcessId -ErrorAction Stop
      return @{ pid=$Proc.Id; running=$true; cpuPercent=0; ramMb=[math]::Round($Proc.WorkingSet64 / 1MB, 1) }
    } catch {}
  }
  try {
    $Connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1
    if ($Connection -and $Connection.OwningProcess) { $ProcessId = [int]$Connection.OwningProcess }
  } catch {}
  if (-not $ProcessId) { return @{ pid=$null; running=$false; cpuPercent=0; ramMb=0 } }
  try {
    $Proc = Get-Process -Id $ProcessId -ErrorAction Stop
    return @{ pid=$Proc.Id; running=$true; cpuPercent=0; ramMb=[math]::Round($Proc.WorkingSet64 / 1MB, 1) }
  } catch {
    return @{ pid=$ProcessId; running=$false; cpuPercent=0; ramMb=0 }
  }
}

$BackendOk = $false
$AgentCount = 0
try {
  $Agents = Invoke-RestMethod -Uri "http://127.0.0.1:$BackendPort/v1/jobs/async/agents" -TimeoutSec 8
  $BackendOk = $true
  $AgentCount = @($Agents.agents).Count
} catch {}

$BackendProc = Get-ProcSample -Path $BackendPidPath -Port $BackendPort
$FrontendProc = Get-ProcSample -Path $FrontendPidPath -Port $FrontendPort
$RamMb = [math]::Round([double]$BackendProc.ramMb + [double]$FrontendProc.ramMb, 1)
$Headline = if ($BackendOk) { "$AgentCount agents" } else { "not running" }
$Secondary = if ($BackendOk) { "backend $BackendPort, frontend $FrontendPort" } else { "backend unavailable" }

$SampledAt = (Get-Date).ToUniversalTime().ToString("o")
$Metrics = @{
  sampledAt = $SampledAt
  platform = "windows"
  process = @{ cpuPercent = 0; ramMb = $RamMb; gpuPercent = 0; vramMb = 0; backend = $BackendProc; frontend = $FrontendProc }
  service = @{ requestsTotal = 0; requestsPerMin = 0; latencyP50Ms = 0; latencyP95Ms = 0; errorsLastHour = 0; backendOk = $BackendOk; agents = $AgentCount; frontendPort = $FrontendPort; backendPort = $BackendPort }
  benchmark = @{ headlineMetric = $Headline; secondaryMetric = $Secondary; latencyMs = 0; throughput = 0; vramPeakMb = 0; measuredAt = $SampledAt }
}
$Metrics | ConvertTo-Json -Depth 6 | Set-Content "$Root\runtime\metrics.json" -Encoding utf8
$Metrics | ConvertTo-Json -Compress -Depth 6

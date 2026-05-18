$ErrorActionPreference = "Stop"

function Get-ProviderRoot {
  if ($env:AIHUB_PROVIDER_ROOT) { return $env:AIHUB_PROVIDER_ROOT }
  return (Resolve-Path "$PSScriptRoot\..\..").Path
}

function Get-DeployDir {
  param([string]$ProviderId)
  if ($env:AIHUB_INSTALL_DIRECTORY) { return $env:AIHUB_INSTALL_DIRECTORY }
  $Root = Get-ProviderRoot
  $DeployRoot = $env:AIHUB_DEPLOY_ROOT
  if (-not $DeployRoot) { $DeployRoot = (Resolve-Path "$Root\..\..\deploy").Path }
  return (Join-Path $DeployRoot $ProviderId)
}

function Find-Bash {
  foreach ($Candidate in @("C:\Program Files\Git\bin\bash.exe", "C:\Program Files\Git\usr\bin\bash.exe", "bash")) {
    try { return (Get-Command $Candidate -ErrorAction Stop).Source } catch {}
  }
  throw "Git Bash or bash is required"
}

function Set-EnvValue {
  param([string]$Text, [string]$Key, [string]$Value)
  if ($null -eq $Value) { $Value = "" }
  $Pattern = "(?m)^$([regex]::Escape($Key))=.*$"
  if ($Text -match $Pattern) { return ($Text -replace $Pattern, "$Key=$Value") }
  return ($Text.TrimEnd() + "`n$Key=$Value`n")
}

function Remove-EnvValue {
  param([string]$Text, [string]$Key)
  $Pattern = "(?m)^$([regex]::Escape($Key))=.*(\r?\n)?"
  return ($Text -replace $Pattern, "")
}

function Copy-EnvIfMissing {
  param([string]$Source, [string]$Target)
  New-Item -ItemType Directory -Force -Path (Split-Path $Target) | Out-Null
  if (!(Test-Path -LiteralPath $Target)) {
    Copy-Item -LiteralPath $Source -Destination $Target
  }
}

function Sync-Repo {
  param([string]$RepoUrl, [string]$Branch, [string]$DeployDir)
  $Parent = Split-Path $DeployDir
  New-Item -ItemType Directory -Force -Path $Parent | Out-Null
  if ($env:AIHUB_DRY_RUN -eq "1") {
    New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null
    return
  }
  $NeedsClone = !(Test-Path -LiteralPath (Join-Path $DeployDir ".git"))
  if (-not $NeedsClone) {
    git -c core.longpaths=true -C $DeployDir status --short --untracked-files=no | Out-Null
    if ($LASTEXITCODE -ne 0) { $NeedsClone = $true }
    $IndexChanges = git -c core.longpaths=true -C $DeployDir diff --cached --name-only
    if ($IndexChanges) { $NeedsClone = $true }
  }
  if ($NeedsClone) {
    if (Test-Path -LiteralPath $DeployDir) {
      $Existing = Get-ChildItem -Force -LiteralPath $DeployDir -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($Existing) { Remove-Item -LiteralPath $DeployDir -Recurse -Force }
    }
    git -c core.longpaths=true clone --depth 1 --branch $Branch $RepoUrl $DeployDir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
  } else {
    git -c core.longpaths=true -C $DeployDir fetch --depth 1 origin $Branch
    if ($LASTEXITCODE -ne 0) { throw "git fetch failed" }
    git -c core.longpaths=true -C $DeployDir checkout -f $Branch
    if ($LASTEXITCODE -ne 0) { throw "git checkout failed" }
    git -c core.longpaths=true -C $DeployDir pull --ff-only
    if ($LASTEXITCODE -ne 0) { throw "git pull failed" }
  }
  git -c core.longpaths=true -C $DeployDir status --short --untracked-files=no | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "git checkout validation failed" }
  $Unmerged = git -c core.longpaths=true -C $DeployDir diff --name-only --diff-filter=U
  if ($Unmerged) { throw "git checkout left unresolved files" }
  $IndexChanges = git -c core.longpaths=true -C $DeployDir diff --cached --name-only
  if ($IndexChanges) { throw "git checkout left staged files" }
}

function Wait-Http {
  param([string]$Url, [string]$Name, [int]$TimeoutSec = 300)
  $Deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $Deadline) {
    try {
      $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
      if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 500) { return }
    } catch {}
    Start-Sleep -Seconds 2
  }
  throw "$Name did not become ready at $Url within ${TimeoutSec}s"
}

function Write-ProviderStatus {
  param(
    [string]$ProviderId,
    [string]$Root,
    [string]$State,
    [int]$Port,
    [string]$Step,
    [string]$Message = $Step,
    [hashtable]$ExtraHealth = @{}
  )
  New-Item -ItemType Directory -Force -Path (Join-Path $Root "runtime") | Out-Null
  $Health = @{ level = "ok"; message = $Message }
  foreach ($Key in $ExtraHealth.Keys) { $Health[$Key] = $ExtraHealth[$Key] }
  $Status = @{
    projectId = $ProviderId
    state = $State
    pid = $null
    port = $Port
    platform = "windows"
    startedAt = (Get-Date).ToUniversalTime().ToString("o")
    uptimeSec = 0
    currentStep = $Step
    progressPercent = 100
    health = $Health
  }
  $Status | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $Root "runtime\status.json") -Encoding utf8
}

function Write-ProviderMetrics {
  param(
    [string]$Root,
    [string]$DeployDir,
    [string[]]$ComposeArgs,
    [string]$HealthUrl,
    [int]$Port
  )
  $GatewayOk = $false
  try {
    $GatewayOk = (Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 5).StatusCode -lt 500
  } catch {}
  $RunningContainers = 0
  try {
    Push-Location $DeployDir
    $RunningContainers = (& docker compose @ComposeArgs ps --services --filter "status=running" | Measure-Object).Count
  } catch {
    $RunningContainers = 0
  } finally {
    Pop-Location
  }
  $SampledAt = (Get-Date).ToUniversalTime().ToString("o")
  $Metrics = @{
    sampledAt = $SampledAt
    platform = "windows"
    process = @{ cpuPercent = 0; ramMb = 0; gpuPercent = 0; vramMb = 0 }
    service = @{ runningContainers = $RunningContainers; gatewayOk = $GatewayOk; gatewayPort = $Port; requestsTotal = 0; requestsPerMin = 0; latencyP50Ms = 0; latencyP95Ms = 0; errorsLastHour = 0 }
    benchmark = @{ headlineMetric = if ($GatewayOk) { "$RunningContainers containers" } else { "not running" }; secondaryMetric = if ($GatewayOk) { "port $Port healthy" } else { "health unavailable" }; latencyMs = 0; throughput = 0; vramPeakMb = 0; measuredAt = $SampledAt }
  }
  New-Item -ItemType Directory -Force -Path (Join-Path $Root "runtime") | Out-Null
  $Metrics | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $Root "runtime\metrics.json") -Encoding utf8
  $Metrics | ConvertTo-Json -Compress -Depth 5
}

$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "web-agent" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$FrontendPort = $env:AIHUB_PORT; if (-not $FrontendPort) { $FrontendPort = "6925" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "6926" }
$SearxngPort = $env:AIHUB_SEARXNG_PORT; if (-not $SearxngPort) { $SearxngPort = "6927" }

function Set-EnvValueNoBom {
  param([string]$Path, [string]$Key, [string]$Value)
  $Text = if (Test-Path -LiteralPath $Path) { Get-Content -LiteralPath $Path -Raw } else { "" }
  if ($Text -match "(?m)^$([regex]::Escape($Key))=") {
    $Text = $Text -replace "(?m)^$([regex]::Escape($Key))=.*$", "$Key=$Value"
  } else {
    $Text = $Text.TrimEnd() + "`n$Key=$Value`n"
  }
  $Encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Text, $Encoding)
}

function Wait-Http {
  param([string]$Url, [string]$Name, [int]$Retries = 120)
  for ($i = 1; $i -le $Retries; $i++) {
    try {
      $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
      if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 500) { return }
    } catch {}
    Start-Sleep -Seconds 2
  }
  throw "$Name did not become ready at $Url"
}

function Get-PortProcessId {
  param([int]$Port)
  try {
    $Connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1
    if ($Connection -and $Connection.OwningProcess) { return [int]$Connection.OwningProcess }
  } catch {}
  return $null
}

New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null

if ($env:AIHUB_DRY_RUN -ne "1") {
  if (!(Test-Path -LiteralPath $DeployDir)) {
    & (Join-Path $Root "scripts\windows\setup.ps1")
    if ($LASTEXITCODE -ne 0) { throw "setup failed while preparing deploy directory" }
  }
  $RootEnv = Join-Path $DeployDir ".env"
  Set-EnvValueNoBom -Path $RootEnv -Key "BACKEND_PORT" -Value $BackendPort
  $BackendEnv = Join-Path $DeployDir "backend\.env"
  Set-EnvValueNoBom -Path $RootEnv -Key "FRONTEND_PORT" -Value $FrontendPort
  Set-EnvValueNoBom -Path $RootEnv -Key "SEARXNG_PORT" -Value $SearxngPort
  Set-EnvValueNoBom -Path $RootEnv -Key "AUTO_START_APPS" -Value "false"
  Set-EnvValueNoBom -Path $BackendEnv -Key "APP_SEARXNG_BASE_URL" -Value "http://127.0.0.1:$SearxngPort"
  Set-EnvValueNoBom -Path $BackendEnv -Key "APP_SEARXNG_BACKUP_BASE_URLS" -Value ""
  & (Join-Path $DeployDir "run.ps1")
  if (-not $?) { throw "web-agent run failed" }
  Wait-Http -Url "http://127.0.0.1:$BackendPort/api/v1/health" -Name "Web Agent backend"
  Wait-Http -Url "http://127.0.0.1:$FrontendPort" -Name "Web Agent frontend"
}

$BackendPid = Get-PortProcessId -Port ([int]$BackendPort)
$Status = @{ projectId=$Id; state="running"; pid=$BackendPid; port=[int]$FrontendPort; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Running Web Agent"; progressPercent=100; health=@{ level="ok"; message="Started"; backendPort=[int]$BackendPort } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="running"; port=[int]$FrontendPort; backendPort=[int]$BackendPort } | ConvertTo-Json -Compress)

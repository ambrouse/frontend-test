$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "pdf-to-podcast" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "7860" }

function Find-Bash {
  $Candidates = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files\Git\usr\bin\bash.exe",
    "bash"
  )
  foreach ($Candidate in $Candidates) {
    try {
      $Command = Get-Command $Candidate -ErrorAction Stop
      return $Command.Source
    } catch {
    }
  }
  throw "Git Bash or bash is required to run this provider"
}

function Read-PortMap {
  param([string]$DeployPath)
  $Path = Join-Path $DeployPath ".auto-ports.env"
  if (!(Test-Path $Path)) {
    return @{ FRONTEND_PORT = $Port; API_SERVICE_PORT = "8002" }
  }
  return Get-Content $Path | ConvertFrom-StringData
}

function Wait-Http {
  param([string]$Url, [string]$Name, [int]$Retries = 90)
  for ($i = 1; $i -le $Retries; $i++) {
    try {
      $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
      if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 500) { return }
    } catch {
    }
    Start-Sleep -Seconds 2
  }
  throw "$Name did not become ready at $Url"
}

function Start-BashScript {
  param(
    [Parameter(Mandatory = $true)][string]$Bash,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$LogName
  )
  $OutPath = Join-Path $Root "logs\$LogName.out.log"
  $ErrPath = Join-Path $Root "logs\$LogName.err.log"
  Remove-Item -LiteralPath $OutPath, $ErrPath -ErrorAction SilentlyContinue
  $ArgumentText = $Arguments -join " "
  $Command = "start `"`" /min cmd.exe /c `" `"$Bash`" $ArgumentText > `"$OutPath`" 2> `"$ErrPath`" `""
  Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", $Command) -WorkingDirectory $WorkingDirectory -WindowStyle Hidden | Out-Null
  Write-Output "Started PDF to Podcast bootstrap process."
}

function Write-BashScriptLog {
  param([Parameter(Mandatory = $true)][string]$LogName)
  $OutPath = Join-Path $Root "logs\$LogName.out.log"
  $ErrPath = Join-Path $Root "logs\$LogName.err.log"
  if (Test-Path $OutPath) { Get-Content -LiteralPath $OutPath -Tail 200 }
  if (Test-Path $ErrPath) { Get-Content -LiteralPath $ErrPath -Tail 80 }
}

function Wait-File {
  param([Parameter(Mandatory = $true)][string]$Path, [int]$Retries = 120)
  for ($i = 1; $i -le $Retries; $i++) {
    if (Test-Path $Path) { return }
    Start-Sleep -Seconds 2
  }
  throw "Timed out waiting for $Path"
}

function Wait-PortMap {
  param([Parameter(Mandatory = $true)][string]$Path, [int]$Retries = 120)
  for ($i = 1; $i -le $Retries; $i++) {
    if (Test-Path $Path) {
      $Text = Get-Content -LiteralPath $Path -Raw
      if ($Text -match "(?m)^FRONTEND_PORT=\d+" -and $Text -match "(?m)^API_SERVICE_PORT=\d+") { return }
    }
    Start-Sleep -Seconds 2
  }
  throw "Timed out waiting for complete port map at $Path"
}

New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null

if ($env:AIHUB_DRY_RUN -ne "1") {
  if (!(Test-Path $DeployDir)) {
    & (Join-Path $Root "scripts\windows\setup.ps1")
    if ($LASTEXITCODE -ne 0) { throw "setup failed while preparing deploy directory" }
  }

  $Bash = Find-Bash
  $env:FRONTEND_PORT = $Port
  Start-BashScript -Bash $Bash -WorkingDirectory $DeployDir -Arguments @("setup.sh", "--up") -LogName "setup-up"
  Wait-PortMap -Path (Join-Path $DeployDir ".auto-ports.env")
}

$Ports = Read-PortMap -DeployPath $DeployDir
$FrontendPort = [int]$Ports.FRONTEND_PORT
$ApiPort = [int]$Ports.API_SERVICE_PORT
if ($env:AIHUB_DRY_RUN -ne "1") {
  Wait-Http -Url "http://127.0.0.1:$ApiPort/health" -Name "API health"
  Wait-Http -Url "http://127.0.0.1:$FrontendPort" -Name "Gradio frontend"
  Write-Output "PDF to Podcast bootstrap health checks passed."
}

$PidPath = Join-Path $DeployDir "frontend\.frontend.pid"
$FrontendPid = $null
if (Test-Path $PidPath) {
  $PidText = (Get-Content $PidPath -Raw).Trim()
  if ($PidText -match '^\d+$') { $FrontendPid = [int]$PidText }
}
$Status = @{ projectId=$Id; state="running"; pid=$FrontendPid; port=$FrontendPort; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Running PDF to Podcast stack"; progressPercent=100; health=@{ level="ok"; message="Started"; apiPort=$ApiPort } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="running"; port=$FrontendPort; apiPort=$ApiPort } | ConvertTo-Json -Compress)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "web-agent" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$FrontendPort = $env:AIHUB_PORT; if (-not $FrontendPort) { $FrontendPort = "3005" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "8011" }
$SearxngPort = $env:AIHUB_SEARXNG_PORT; if (-not $SearxngPort) { $SearxngPort = "18080" }
$SearxngContainer = $env:AIHUB_SEARXNG_CONTAINER; if (-not $SearxngContainer) { $SearxngContainer = "web-agent-searxng" }
$RepoUrl = "https://github.com/baolnq-ai/web-agent.git"

function Write-Utf8NoBom {
  param([string]$Path, [string]$Text)
  $Encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Text, $Encoding)
}

function Set-EnvValueNoBom {
  param([string]$Path, [string]$Key, [string]$Value)
  if ($null -eq $Value) { $Value = "" }
  $Text = if (Test-Path -LiteralPath $Path) { Get-Content -LiteralPath $Path -Raw } else { "" }
  if ($Text -match "(?m)^$([regex]::Escape($Key))=") {
    $Text = $Text -replace "(?m)^$([regex]::Escape($Key))=.*$", "$Key=$Value"
  } else {
    $Text = $Text.TrimEnd() + "`n$Key=$Value`n"
  }
  Write-Utf8NoBom -Path $Path -Text $Text
}

function Resolve-Python312 {
  $Candidates = @(
    @("py", @("-3.12", "-c", "import sys; print(sys.executable)")),
    @("python", @("-c", "import sys; raise SystemExit(0 if sys.version_info >= (3,12) else 1); print(sys.executable)")),
    @("python3", @("-c", "import sys; raise SystemExit(0 if sys.version_info >= (3,12) else 1); print(sys.executable)"))
  )
  foreach ($Candidate in $Candidates) {
    try {
      $Exe = $Candidate[0]
      $Args = $Candidate[1]
      $Output = & $Exe @Args 2>$null
      if ($LASTEXITCODE -eq 0 -and $Output) { return ($Output | Select-Object -First 1).Trim() }
    } catch {}
  }
  throw "Python 3.12 or newer is required. Install Python 3.12+, or ensure py -3.12 is available."
}

function Sync-WebAgentEnv {
  $RootEnv = Join-Path $DeployDir ".env"
  $RootExample = Join-Path $DeployDir ".env.example"
  $BackendEnv = Join-Path $DeployDir "backend\.env"
  $BackendExample = Join-Path $DeployDir "backend\.env.example"
  if (!(Test-Path -LiteralPath $RootEnv)) { Copy-Item -LiteralPath $RootExample -Destination $RootEnv }
  if (!(Test-Path -LiteralPath $BackendEnv)) { Copy-Item -LiteralPath $BackendExample -Destination $BackendEnv }
  Set-EnvValueNoBom -Path $RootEnv -Key "BACKEND_HOST" -Value "127.0.0.1"
  Set-EnvValueNoBom -Path $RootEnv -Key "BACKEND_PORT" -Value $BackendPort
  Set-EnvValueNoBom -Path $RootEnv -Key "FRONTEND_HOST" -Value "0.0.0.0"
  Set-EnvValueNoBom -Path $RootEnv -Key "FRONTEND_PORT" -Value $FrontendPort
  Set-EnvValueNoBom -Path $RootEnv -Key "PUBLIC_BACKEND_HOST" -Value "127.0.0.1"
  Set-EnvValueNoBom -Path $RootEnv -Key "AUTO_START_APPS" -Value "false"
  Set-EnvValueNoBom -Path $RootEnv -Key "POSTGRES_AUTO_START" -Value "false"
  Set-EnvValueNoBom -Path $RootEnv -Key "PGADMIN_AUTO_START" -Value "false"
  Set-EnvValueNoBom -Path $RootEnv -Key "SEARXNG_AUTO_START" -Value "true"
  Set-EnvValueNoBom -Path $RootEnv -Key "SEARXNG_PORT" -Value $SearxngPort
  Set-EnvValueNoBom -Path $RootEnv -Key "SEARXNG_CONTAINER_NAME" -Value $SearxngContainer
  Set-EnvValueNoBom -Path $BackendEnv -Key "APP_SEARXNG_BASE_URL" -Value "http://127.0.0.1:$SearxngPort"
  Set-EnvValueNoBom -Path $BackendEnv -Key "APP_SEARXNG_BACKUP_BASE_URLS" -Value ""
  if ($env:LLM_BASE_URL) { Set-EnvValueNoBom -Path $RootEnv -Key "LLM_BASE_URL" -Value $env:LLM_BASE_URL }
  if ($env:LLM_MODEL) { Set-EnvValueNoBom -Path $RootEnv -Key "LLM_MODEL" -Value $env:LLM_MODEL }
}

New-Item -ItemType Directory -Force -Path $DeployRoot, "$Root\logs", "$Root\runtime" | Out-Null

if ($env:AIHUB_DRY_RUN -eq "1") {
  New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null
} else {
  Sync-Repo -RepoUrl $RepoUrl -Branch $Branch -DeployDir $DeployDir
  Sync-WebAgentEnv
  $Python312 = Resolve-Python312
  $env:PATH = "$(Split-Path $Python312);$env:PATH"
  & (Join-Path $DeployDir "setup.ps1")
  if (-not $?) { throw "web-agent setup failed" }
}

$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$FrontendPort; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed Web Agent"; progressPercent=100; health=@{ level="ok"; message="Installed"; backendPort=[int]$BackendPort } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$FrontendPort; backendPort=[int]$BackendPort } | ConvertTo-Json -Compress)

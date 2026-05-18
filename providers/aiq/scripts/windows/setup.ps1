$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "aiq" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "develop" }
$FrontendPort = $env:AIHUB_PORT; if (-not $FrontendPort) { $FrontendPort = "13080" }
$BackendPort = $env:AIHUB_BACKEND_PORT; if (-not $BackendPort) { $BackendPort = "18080" }
$NextInternalPort = $env:AIHUB_NEXT_INTERNAL_PORT; if (-not $NextInternalPort) { $NextInternalPort = ([int]$FrontendPort + 1).ToString() }
$PostgresPort = $env:AIHUB_POSTGRES_PORT; if (-not $PostgresPort) { $PostgresPort = "15432" }
$RepoUrl = "https://github.com/PhuongHo03/aiq.git"
$PatchPath = Join-Path $Root "patches\windows-lifecycle.patch"
$ProviderEnvKeys = @("NVIDIA_API_KEY", "TAVILY_API_KEY", "SERPER_API_KEY")

function Write-Utf8NoBom {
  param([string]$Path, [string]$Text)
  $Encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Text, $Encoding)
}

function Set-EnvValue {
  param([string]$Path, [string]$Key, [string]$Value)
  if ($null -eq $Value) { $Value = "" }
  $Text = if (Test-Path $Path) { Get-Content -Path $Path -Raw } else { "" }
  if ($Text -match "(?m)^$([regex]::Escape($Key))=") {
    $Text = $Text -replace "(?m)^$([regex]::Escape($Key))=.*$", "$Key=$Value"
  } else {
    $Text = $Text.TrimEnd() + "`n$Key=$Value`n"
  }
  Write-Utf8NoBom -Path $Path -Text $Text
}

function Test-PatchApplied {
  $Plugin = Join-Path $DeployDir "frontends\aiq_api\src\aiq_api\plugin.py"
  $DevNext = Join-Path $DeployDir "frontends\ui\scripts\dev-next.js"
  return ((Test-Path $Plugin) -and (Select-String -LiteralPath $Plugin -Pattern "typing_extensions import override" -Quiet) -and (Test-Path $DevNext))
}

function Apply-ProviderPatch {
  if (Test-PatchApplied) { return }
  git -C $DeployDir apply --check $PatchPath
  git -C $DeployDir apply $PatchPath
}

function Ensure-ServiceTimeout {
  $SetupScript = Join-Path $DeployDir "setup.sh"
  if (!(Test-Path $SetupScript)) { return }
  $Text = Get-Content -LiteralPath $SetupScript -Raw
  $Updated = $Text -replace 'local attempts=60', 'local attempts="${AIQ_SERVICE_START_ATTEMPTS:-180}"'
  $Updated = $Updated.Replace(
    '    export NEXT_PUBLIC_BACKEND_URL="$BACKEND_URL"' + "`n" + '    export PORT="$FRONTEND_PORT"',
    '    export NEXT_PUBLIC_BACKEND_URL="$BACKEND_URL"' + "`n" + '    export AIQ_FRONTEND_HOST="${AIQ_FRONTEND_HOST:-0.0.0.0}"' + "`n" + '    export PORT="$FRONTEND_PORT"'
  )
  if ($Updated -ne $Text) {
    Write-Utf8NoBom -Path $SetupScript -Text $Updated
  }
}

function Ensure-FrontendHostBinding {
  $ServerScript = Join-Path $DeployDir "frontends\ui\server.js"
  if (!(Test-Path $ServerScript)) { return }
  $Text = Get-Content -LiteralPath $ServerScript -Raw
  $Updated = $Text -replace "const hostname = process\.env\.HOSTNAME \|\| '0\.0\.0\.0'", "const hostname = process.env.AIQ_FRONTEND_HOST || process.env.HOST || '0.0.0.0'"
  if ($Updated -ne $Text) {
    Write-Utf8NoBom -Path $ServerScript -Text $Updated
  }
}

function Sync-ProviderEnv {
  $EnvDir = Join-Path $DeployDir "deploy"
  $EnvFile = Join-Path $EnvDir ".env"
  $Example = Join-Path $EnvDir ".env.example"
  if (!(Test-Path $EnvFile)) { Copy-Item $Example $EnvFile }

  foreach ($Key in $ProviderEnvKeys) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    Set-EnvValue -Path $EnvFile -Key $Key -Value $Value
  }

  $HasTavily = [bool][Environment]::GetEnvironmentVariable("TAVILY_API_KEY")
  $HasSerper = [bool][Environment]::GetEnvironmentVariable("SERPER_API_KEY")
  Set-EnvValue -Path $EnvFile -Key "AIQ_REQUIRE_FULL_SOURCES" -Value ($(if ($HasTavily -and $HasSerper) { "true" } else { "false" }))
  Set-EnvValue -Path $EnvFile -Key "AIQ_SUPPORT_SERVICES" -Value ($(if ($env:AIQ_SUPPORT_SERVICES) { $env:AIQ_SUPPORT_SERVICES } else { "false" }))
  Set-EnvValue -Path $EnvFile -Key "AIQ_BACKEND_PORT" -Value $BackendPort
  Set-EnvValue -Path $EnvFile -Key "AIQ_FRONTEND_PORT" -Value $FrontendPort
  Set-EnvValue -Path $EnvFile -Key "AIQ_NEXT_INTERNAL_PORT" -Value $NextInternalPort
  Set-EnvValue -Path $EnvFile -Key "AIQ_POSTGRES_PORT" -Value $PostgresPort
  Set-EnvValue -Path $EnvFile -Key "REQUIRE_AUTH" -Value "false"
}

New-Item -ItemType Directory -Force -Path $DeployRoot, "$Root\logs", "$Root\runtime" | Out-Null

if ($env:AIHUB_DRY_RUN -eq "1") {
  New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null
} elseif (!(Test-Path (Join-Path $DeployDir ".git"))) {
  if (Test-Path $DeployDir) {
    $ExistingItem = Get-ChildItem -Force -LiteralPath $DeployDir -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ExistingItem) { Remove-Item -LiteralPath $DeployDir -Recurse -Force }
  }
  Invoke-GitChecked -Arguments @("clone", "--branch", $Branch, $RepoUrl, $DeployDir) -FailureMessage "git clone failed for $RepoUrl branch $Branch"
} else {
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "reset", "--hard") -FailureMessage "git reset failed for $DeployDir"
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "fetch", "origin", $Branch) -FailureMessage "git fetch failed for $RepoUrl branch $Branch"
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "checkout", $Branch) -FailureMessage "git checkout failed for branch $Branch"
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "pull", "--ff-only") -FailureMessage "git pull failed for branch $Branch"
}

if ($env:AIHUB_DRY_RUN -ne "1") {
  Apply-ProviderPatch
  Ensure-ServiceTimeout
  Ensure-FrontendHostBinding
  Sync-ProviderEnv
}

$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$FrontendPort; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed AI-Q provider"; progressPercent=100; health=@{ level="ok"; message="Installed"; backendPort=[int]$BackendPort } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$FrontendPort; backendPort=[int]$BackendPort } | ConvertTo-Json -Compress)

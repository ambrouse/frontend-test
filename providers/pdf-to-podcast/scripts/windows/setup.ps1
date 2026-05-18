$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "pdf-to-podcast" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "7860" }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$RepoUrl = "https://github.com/PhuongHo03/pdf-to-podcast.git"
$ProviderEnvKeys = @(
  "NVIDIA_API_KEY",
  "ELEVENLABS_API_KEY",
  "API_SERVICE_PORT",
  "MAX_CONCURRENT_REQUESTS",
  "MODEL_API_URL",
  "DEFAULT_VOICE_1",
  "DEFAULT_VOICE_2"
)

function Set-EnvValue {
  param([string]$Path, [string]$Key, [string]$Value)
  if (-not $Value) { return }
  $Text = if (Test-Path $Path) { Get-Content -Path $Path -Raw } else { "" }
  if ($Text -match "(?m)^$([regex]::Escape($Key))=") {
    $Text = $Text -replace "(?m)^$([regex]::Escape($Key))=.*$", "$Key=$Value"
  } else {
    $Text = $Text.TrimEnd() + "`n$Key=$Value`n"
  }
  Set-Content -Path $Path -Value $Text -Encoding utf8
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
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "fetch", "origin", $Branch) -FailureMessage "git fetch failed for $RepoUrl branch $Branch"
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "checkout", $Branch) -FailureMessage "git checkout failed for branch $Branch"
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "pull", "--ff-only") -FailureMessage "git pull failed for branch $Branch"
}

if ($env:AIHUB_DRY_RUN -ne "1") {
  $EnvFile = Join-Path $DeployDir ".env"
  if (!(Test-Path $EnvFile)) {
    Copy-Item (Join-Path $DeployDir ".env.example") $EnvFile
  }

  foreach ($Key in $ProviderEnvKeys) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    Set-EnvValue -Path $EnvFile -Key $Key -Value $Value
  }
}

$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)

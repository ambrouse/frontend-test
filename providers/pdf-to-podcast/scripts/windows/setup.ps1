$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "pdf-to-podcast" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "7860" }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$RepoUrl = "https://github.com/PhuongHo03/pdf-to-podcast.git"

function Get-LocalEnvValue {
  param([string]$ProviderRoot, [string]$Key)
  try {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProviderRoot "..\.."))
    $LocalEnvFile = Join-Path $RepoRoot ".env.local"
    if (!(Test-Path $LocalEnvFile)) { return "" }
    $Line = Get-Content -Path $LocalEnvFile | Where-Object { $_ -match "^\s*$([regex]::Escape($Key))\s*=" } | Select-Object -Last 1
    if (-not $Line) { return "" }
    $Value = ($Line -split '=', 2)[1].Trim()
    if ($Value.StartsWith('"') -and $Value.EndsWith('"') -and $Value.Length -ge 2) {
      $Value = $Value.Substring(1, $Value.Length - 2)
    }
    return $Value
  } catch {
    return ""
  }
}

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
  git clone --branch $Branch $RepoUrl $DeployDir
} else {
  git -C $DeployDir fetch origin $Branch
  git -C $DeployDir checkout $Branch
  git -C $DeployDir pull --ff-only
}

if ($env:AIHUB_DRY_RUN -ne "1") {
  $EnvFile = Join-Path $DeployDir ".env"
  if (!(Test-Path $EnvFile)) {
    Copy-Item (Join-Path $DeployDir ".env.example") $EnvFile
  }

  $NvidiaKey = $env:NVIDIA_API_KEY
  if (-not $NvidiaKey) { $NvidiaKey = Get-LocalEnvValue -ProviderRoot $Root -Key "NVIDIA_API_KEY" }
  $ElevenLabsKey = $env:ELEVENLABS_API_KEY
  if (-not $ElevenLabsKey) { $ElevenLabsKey = Get-LocalEnvValue -ProviderRoot $Root -Key "ELEVENLABS_API_KEY" }
  Set-EnvValue -Path $EnvFile -Key "NVIDIA_API_KEY" -Value $NvidiaKey
  Set-EnvValue -Path $EnvFile -Key "ELEVENLABS_API_KEY" -Value $ElevenLabsKey
}

$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)

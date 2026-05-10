$ErrorActionPreference = "Stop"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "agentic-commerce-blueprint" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = Join-Path $DeployRoot $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }
$RepoUrl = "https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-"
New-Item -ItemType Directory -Force -Path $DeployRoot, "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -eq "1") {
  New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null
} elseif (!(Test-Path (Join-Path $DeployDir ".git"))) {
  git clone --depth 1 --branch "main" $RepoUrl $DeployDir
} else {
  git -C $DeployDir pull --ff-only
}
$EnvFile = Join-Path $DeployDir ".env"
if (!(Test-Path $EnvFile)) { Copy-Item "$Root\.env.example" $EnvFile }
$Text = Get-Content $EnvFile -Raw
$Text = $Text -replace '(?m)^HTTP_HOST_PORT=.*$', "HTTP_HOST_PORT=$Port"
if ($env:NVIDIA_API_KEY) { $Text = $Text -replace '(?m)^NVIDIA_API_KEY=.*$', "NVIDIA_API_KEY=$($env:NVIDIA_API_KEY)" }
Set-Content -Path $EnvFile -Value $Text -Encoding utf8
$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)

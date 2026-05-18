$ErrorActionPreference = "Stop"
. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "agentic-commerce-blueprint" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$RepoUrl = "https://github.com/baolnq-ai/Agentic-Commerce-blueprint-provider-"
$ProviderEnvKeys = @("NVIDIA_API_KEY", "NGC_API_KEY", "MERCHANT_API_KEY", "PSP_API_KEY")

function Set-EnvValue {
  param([string]$Text, [string]$Key, [string]$Value)
  if ($null -eq $Value -or $Value -eq "") { return $Text }
  if ($Text -match "(?m)^$([regex]::Escape($Key))=") {
    return ($Text -replace "(?m)^$([regex]::Escape($Key))=.*$", "$Key=$Value")
  }
  return ($Text.TrimEnd() + "`n$Key=$Value`n")
}

function Update-DeploySource {
  param([string]$DeployPath)
  $McpClient = Join-Path $DeployPath "src\ui\hooks\useMCPClient.ts"
  if (!(Test-Path -LiteralPath $McpClient)) { return }
  $Text = Get-Content -LiteralPath $McpClient -Raw
  $Updated = $Text.Replace(
    "AbortSignal.timeout(65000), // 65s timeout for search agent (can take 20-30s)",
    "AbortSignal.timeout(180000), // 180s timeout for slower first-run search agent calls"
  ).Replace(
    "AbortSignal.timeout(65000), // 65s timeout for ARAG agent (takes ~25s)",
    "AbortSignal.timeout(180000), // 180s timeout for slower first-run agent calls"
  )
  if ($Updated -ne $Text) {
    Set-Content -LiteralPath $McpClient -Value $Updated -Encoding utf8
  }
}
New-Item -ItemType Directory -Force -Path $DeployRoot, "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -eq "1") {
  New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null
} elseif (!(Test-Path (Join-Path $DeployDir ".git"))) {
  if (Test-Path $DeployDir) {
    $ExistingItem = Get-ChildItem -Force -LiteralPath $DeployDir -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ExistingItem) { Remove-Item -LiteralPath $DeployDir -Recurse -Force }
  }
  Invoke-GitChecked -Arguments @("clone", "--depth", "1", "--branch", $Branch, $RepoUrl, $DeployDir) -FailureMessage "git clone failed for $RepoUrl branch $Branch"
} else {
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "fetch", "--depth", "1", "origin", $Branch) -FailureMessage "git fetch failed for $RepoUrl branch $Branch"
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "checkout", $Branch) -FailureMessage "git checkout failed for branch $Branch"
  Invoke-GitChecked -Arguments @("-C", $DeployDir, "pull", "--ff-only") -FailureMessage "git pull failed for branch $Branch"
}
if (!(Test-Path -LiteralPath $DeployDir)) { throw "deploy directory was not created: $DeployDir" }
Update-DeploySource -DeployPath $DeployDir
$EnvFile = Join-Path $DeployDir ".env"
$EnvExample = Join-Path $Root ".env.example"
if (!(Test-Path $EnvFile)) {
  if (!(Test-Path $EnvExample)) { throw "provider .env.example is missing: $EnvExample" }
  Copy-Item $EnvExample $EnvFile
}
$Text = Get-Content $EnvFile -Raw
$Text = $Text -replace '(?m)^HTTP_HOST_PORT=.*$', "HTTP_HOST_PORT=$Port"
$ResolvedNvidiaApiKey = $env:NVIDIA_API_KEY
if ($ResolvedNvidiaApiKey) {
  $Text = Set-EnvValue -Text $Text -Key "NVIDIA_API_KEY" -Value $ResolvedNvidiaApiKey
}
foreach ($Key in $ProviderEnvKeys) {
  $Value = [Environment]::GetEnvironmentVariable($Key)
  if ($Key -eq "NGC_API_KEY" -and -not $Value) { $Value = $ResolvedNvidiaApiKey }
  $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value
}
Set-Content -Path $EnvFile -Value $Text -Encoding utf8
$Status = @{ projectId=$Id; state="installed"; pid=$null; port=[int]$Port; platform="windows"; startedAt=(Get-Date).ToUniversalTime().ToString("o"); uptimeSec=0; currentStep="Installed"; progressPercent=100; health=@{ level="ok"; message="Installed" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)

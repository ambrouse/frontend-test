$ErrorActionPreference = "Stop"

$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "aiq" }
$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$DeployRoot = $env:AIHUB_DEPLOY_ROOT; if (-not $DeployRoot) { $DeployRoot = Resolve-Path "$Root\..\..\deploy" }
$DeployDir = $env:AIHUB_INSTALL_DIRECTORY; if (-not $DeployDir) { $DeployDir = Join-Path $DeployRoot $Id }

& (Join-Path $Root "scripts\windows\stop.ps1") | Out-Null

if (Test-Path $DeployDir) {
  $ResolvedDeployRoot = [System.IO.Path]::GetFullPath($DeployRoot)
  $ResolvedDeployDir = [System.IO.Path]::GetFullPath($DeployDir)
  if (-not $ResolvedDeployDir.StartsWith($ResolvedDeployRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to delete outside deploy root: $ResolvedDeployDir"
  }
  Remove-Item -LiteralPath $DeployDir -Recurse -Force
}

$Status = @{ projectId=$Id; state="not_installed"; pid=$null; port=13080; platform="windows"; startedAt=$null; uptimeSec=0; currentStep="Deleted"; progressPercent=100; health=@{ level="unknown"; message="Deleted" } }
$Status | ConvertTo-Json -Depth 5 | Set-Content "$Root\runtime\status.json" -Encoding utf8
Write-Output (@{ state="not_installed" } | ConvertTo-Json -Compress)

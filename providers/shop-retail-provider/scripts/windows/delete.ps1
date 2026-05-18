. "$PSScriptRoot\stop.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "shop-retail-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
if ($env:AIHUB_DRY_RUN -ne "1" -and (Test-Path -LiteralPath $DeployDir)) { Remove-Item -LiteralPath $DeployDir -Recurse -Force }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3000" }
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted Shop Retail deploy"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)

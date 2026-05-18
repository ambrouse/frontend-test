. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "shop-retail-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13000" }
if ($env:AIHUB_DRY_RUN -ne "1" -and (Test-Path -LiteralPath $DeployDir)) {
  Push-Location $DeployDir
  try {
    $Args = @("--env-file",".env","-f","docker-compose.yaml")
    docker compose @Args down
  } finally { Pop-Location }
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "stopped" -Port ([int]$Port) -Step "Stopped Shop Retail stack"
Write-Output (@{ state="stopped"; port=[int]$Port } | ConvertTo-Json -Compress)

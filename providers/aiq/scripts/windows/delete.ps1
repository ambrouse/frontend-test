. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "aiq" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "13080" }
$ComposeDir = Join-Path $DeployDir "deploy"
if ((Test-Path -LiteralPath (Join-Path $ComposeDir ".env")) -and (Test-Path -LiteralPath (Join-Path $ComposeDir "docker-compose.yml"))) {
  Invoke-DockerComposeCleanup -WorkingDirectory $ComposeDir -ComposeArgs @("--env-file", ".env", "-f", "docker-compose.yml")
}
& (Join-Path $Root "scripts\windows\stop.ps1") | Out-Null
Remove-DeployDirSafe -DeployDir $DeployDir
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted AI-Q deploy and local Docker resources" -ExtraHealth @{ backendPort = 18080 }
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)

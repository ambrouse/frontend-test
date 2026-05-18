. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "pdf-to-podcast" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "7860" }
if (Test-Path -LiteralPath (Join-Path $DeployDir "docker-compose.yml")) {
  Invoke-DockerComposeCleanup -WorkingDirectory $DeployDir -ComposeArgs @("-f", "docker-compose.yml")
}
& (Join-Path $Root "scripts\windows\stop.ps1") | Out-Null
Remove-DeployDirSafe -DeployDir $DeployDir
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted PDF to Podcast deploy and local Docker resources"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)

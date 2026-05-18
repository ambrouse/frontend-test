. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "agentic-commerce-blueprint" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "8088" }
if (Test-Path -LiteralPath (Join-Path $DeployDir "docker-compose.yml")) {
  Invoke-DockerComposeCleanup -WorkingDirectory $DeployDir -ComposeArgs @("-f", "docker-compose.infra.yml", "-f", "docker-compose.yml")
}
Remove-DeployDirSafe -DeployDir $DeployDir
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted Agentic Commerce deploy and local Docker resources"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)

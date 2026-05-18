. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "multi-agent-intelligent-warehouse" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3001" }
$ComposeDir = Join-Path $DeployDir "deploy\compose"
if ((Test-Path -LiteralPath (Join-Path $ComposeDir ".env")) -and (Test-Path -LiteralPath (Join-Path $ComposeDir "docker-compose.dev.yaml"))) {
  Invoke-DockerComposeCleanup -WorkingDirectory $DeployDir -ComposeArgs @("--env-file", "deploy/compose/.env", "-f", "deploy/compose/docker-compose.dev.yaml")
}
Remove-DeployDirSafe -DeployDir $DeployDir
Write-ProviderStatus -ProviderId $Id -Root $Root -State "not_installed" -Port ([int]$Port) -Step "Deleted Warehouse deploy and local Docker resources"
Write-Output (@{ state="deleted" } | ConvertTo-Json -Compress)

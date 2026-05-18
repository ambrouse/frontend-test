. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId "shop-retail-provider"
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "3000" }
$Args = @("--env-file",".env","-f","docker-compose.yaml")
Write-ProviderMetrics -Root $Root -DeployDir $DeployDir -ComposeArgs $Args -HealthUrl "http://127.0.0.1:$Port/api/health" -Port ([int]$Port)

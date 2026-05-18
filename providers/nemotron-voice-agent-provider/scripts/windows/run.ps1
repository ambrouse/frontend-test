. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "nemotron-voice-agent-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "9000" }
$PipelinePort = $env:NEMOTRON_PIPELINE_PORT; if (-not $PipelinePort) { $PipelinePort = "7860" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
if ($env:AIHUB_DRY_RUN -ne "1") {
  if (!(Test-Path -LiteralPath $DeployDir)) { & "$Root\scripts\windows\setup.ps1" }
  & "$Root\scripts\windows\setup.ps1"
  Push-Location $DeployDir
  try {
    docker compose --env-file .env -f docker-compose.yml up -d --build --no-deps python-app
    if ($LASTEXITCODE -ne 0) { throw "docker compose python-app failed" }
    docker compose --env-file .env -f docker-compose.yml up -d --build --no-deps ui-app
    if ($LASTEXITCODE -ne 0) { throw "docker compose ui-app failed" }
  } finally { Pop-Location }
  Wait-Http -Url "http://127.0.0.1:$PipelinePort/docs" -Name "Nemotron pipeline" -TimeoutSec 600
  Wait-Http -Url "http://127.0.0.1:$Port" -Name "Nemotron UI" -TimeoutSec 300
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "running" -Port ([int]$Port) -Step "Running Nemotron Voice Agent" -ExtraHealth @{ pipelinePort=[int]$PipelinePort }
Write-Output (@{ state="running"; port=[int]$Port; pipelinePort=[int]$PipelinePort } | ConvertTo-Json -Compress)

. "$PSScriptRoot\..\..\..\_shared\windows-provider-utils.ps1"
$Id = $env:AIHUB_PROVIDER_ID; if (-not $Id) { $Id = "nemotron-voice-agent-provider" }
$Root = Get-ProviderRoot
$DeployDir = Get-DeployDir -ProviderId $Id
$Branch = $env:AIHUB_BRANCH; if (-not $Branch) { $Branch = "main" }
$Port = $env:AIHUB_PORT; if (-not $Port) { $Port = "9000" }
New-Item -ItemType Directory -Force -Path "$Root\logs", "$Root\runtime" | Out-Null
Sync-Repo -RepoUrl "https://github.com/mionm/nemotron-voice-agent-provider.git" -Branch $Branch -DeployDir $DeployDir
if ($env:AIHUB_DRY_RUN -ne "1") {
  Copy-EnvIfMissing -Source (Join-Path $DeployDir "config\env.example") -Target (Join-Path $DeployDir ".env")
  $EnvFile = Join-Path $DeployDir ".env"
  $Text = Get-Content -LiteralPath $EnvFile -Raw
  $NvidiaKey = $env:NVIDIA_API_KEY
  if (-not $env:NGC_API_KEY -and $NvidiaKey) { $env:NGC_API_KEY = $NvidiaKey }
  $Text = Set-EnvValue -Text $Text -Key "UI_PORT" -Value $Port
  foreach ($Key in @("NVIDIA_API_KEY","NGC_API_KEY","TRANSPORT","ASR_SERVER_URL","TTS_SERVER_URL","NVIDIA_LLM_URL","NEMOTRON_PIPELINE_PORT","PYTHON_APP_PORT","TTS_GRPC_PORT","ASR_GRPC_PORT","LLM_HTTP_PORT")) {
    $Value = [Environment]::GetEnvironmentVariable($Key)
    if ($Key -eq "NGC_API_KEY" -and -not $Value) { $Value = $NvidiaKey }
    if ($Key -eq "NEMOTRON_PIPELINE_PORT" -and $Value) {
      $Text = Set-EnvValue -Text $Text -Key "PYTHON_APP_PORT" -Value $Value
      continue
    }
    if ($Value) { $Text = Set-EnvValue -Text $Text -Key $Key -Value $Value }
  }
  Set-Content -LiteralPath $EnvFile -Value $Text -Encoding utf8
}
Write-ProviderStatus -ProviderId $Id -Root $Root -State "installed" -Port ([int]$Port) -Step "Installed Nemotron Voice Agent source"
Write-Output (@{ state="installed"; port=[int]$Port } | ConvertTo-Json -Compress)

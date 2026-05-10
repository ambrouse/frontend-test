param()
$ErrorActionPreference = "Stop"
$providerRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
New-Item -ItemType Directory -Force -Path (Join-Path $providerRoot "runtime"), (Join-Path $providerRoot "logs") | Out-Null
Write-Output '{"ok":true,"message":"stub"}'

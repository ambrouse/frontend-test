$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$Path = "$Root\runtime\metrics.json"
if (Test-Path $Path) { Get-Content $Path -Raw } else { '{"process":{},"service":{},"benchmark":{}}' }

$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$Path = Join-Path $Root "runtime\status.json"
if (Test-Path -LiteralPath $Path) { Get-Content -LiteralPath $Path -Raw } else { '{"state":"unknown","port":3000,"currentStep":"No status file","progressPercent":0,"health":{"level":"unknown","message":"No status file"}}' }

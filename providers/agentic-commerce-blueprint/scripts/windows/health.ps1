$Root = $env:AIHUB_PROVIDER_ROOT; if (-not $Root) { $Root = Resolve-Path "$PSScriptRoot\..\.." }
$Path = "$Root\runtime\status.json"
if (Test-Path $Path) { Get-Content $Path -Raw } else { '{"state":"unknown","health":{"level":"unknown","message":"No status file"}}' }

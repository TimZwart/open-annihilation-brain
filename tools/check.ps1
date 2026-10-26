# Loads the brain against a game: seats it on a flat stand-in map and
# reports whether it loaded, fitted and started. It never ticks.
param([string]$GameDir)

. (Join-Path $PSScriptRoot "common.ps1")
if (-not $GameDir) { $GameDir = $DefaultGameDir }
Assert-BrainSupport

& $OaTool brain check $BrainDir --game-dir $GameDir
exit $LASTEXITCODE

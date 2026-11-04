# Checks and installs the brain, then opens a hosted game room with you
# against it, ready to START. The game has no option that skips the room.
param(
    [string]$Map = "Fullmoon",
    [string]$Side = "arm",
    [string]$BrainSide = "core",
    [ValidateSet("easy", "medium", "hard")][string]$Level = "hard",
    [string]$GameDir
)

. (Join-Path $PSScriptRoot "common.ps1")

& (Join-Path $PSScriptRoot "check.ps1") -GameDir $GameDir
if ($LASTEXITCODE -ne 0) { Write-Output "Check failed; not starting the game."; exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "install.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$Game = Join-Path (Split-Path $OaTool) "open-annihilation.exe"
$manifest = Get-BrainManifest
# --computer-player is SIDE:TEAM:COLOUR:DIFFICULTY:BRAIN; colour left to the room.
$arguments = @(
    "--host",
    "--map", "`"$Map`"",
    "--side", $Side,
    "--team", "1",
    "--computer-player", "${BrainSide}:2::${Level}:$($manifest.Id)"
)
Start-Process -FilePath $Game -ArgumentList $arguments
Write-Output "Started $Game $($arguments -join ' ')"
exit 0

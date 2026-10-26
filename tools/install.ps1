# Copies my-brain/ into <Documents>\Open Annihilation\Brains\<id> for quick
# iteration. A brain may be installed as the folder a .oabrain unpacks to.
. (Join-Path $PSScriptRoot "common.ps1")

$manifest = Get-BrainManifest
$target = Join-Path $DataDir "Brains\$($manifest.Id)"
New-Item -ItemType Directory -Force $target | Out-Null
# /MIR makes the target match the source, removing files deleted here.
robocopy $BrainDir $target /MIR /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { exit $LASTEXITCODE }
Write-Output "Installed $($manifest.Id) $($manifest.Version) to $target"
exit 0

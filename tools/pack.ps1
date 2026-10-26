# Packs my-brain/ into dist/<id>-<version>.oabrain. Packing checks the
# manifest and the file layout and compiles (but does not run) the Lua.
. (Join-Path $PSScriptRoot "common.ps1")
Assert-BrainSupport

$manifest = Get-BrainManifest
$dist = Join-Path $PSScriptRoot "..\dist"
New-Item -ItemType Directory -Force $dist | Out-Null
$out = Join-Path $dist "$($manifest.Id)-$($manifest.Version).oabrain"

& $OaTool brain pack $BrainDir --out $out --force
exit $LASTEXITCODE

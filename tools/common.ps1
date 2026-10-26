# Shared settings for the brain tools. Dot-source this file.

$BrainDir = Resolve-Path (Join-Path $PSScriptRoot "..\my-brain")
$DataDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Open Annihilation"
$DefaultGameDir = Join-Path $DataDir "Games\totala"

$OaTool = $env:OA_TOOL
if (-not $OaTool) { $OaTool = "C:\Program Files\Open Annihilation\oa-tool.exe" }
if (-not (Test-Path $OaTool)) { throw "oa-tool not found at $OaTool; set OA_TOOL" }

function Get-BrainManifest {
    $text = Get-Content (Join-Path $BrainDir "oabrain.yaml") -Raw
    $id = [regex]::Match($text, '(?m)^id:\s*"?([a-z0-9-]+)"?').Groups[1].Value
    $version = [regex]::Match($text, '(?m)^version:\s*"([^"]+)"').Groups[1].Value
    [pscustomobject]@{ Id = $id; Version = $version }
}

# Brain commands arrived after oa-tool 0.8.5. Fail early with a clear line.
function Assert-BrainSupport {
    $help = & $OaTool --help 2>&1 | Out-String
    if ($help -notmatch "oa-tool brain") {
        $version = (& $OaTool --version 2>&1 | Out-String).Trim()
        throw "This oa-tool ($version) has no 'brain' command. Update Open Annihilation."
    }
}

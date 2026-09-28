[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$NoBootstrap,
    [string]$ToolRoot,
    [string]$DataRoot,
    [ValidateSet('baseline', 'aggressive')]
    [string]$OptimizationProfile = 'aggressive',
    [ValidateSet('c', 'asm')]
    [string]$MemoryImplementation = 'asm',
    [ValidateSet('control', 'local')]
    [string]$AliasPrepareImplementation = 'control',
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightImplementation = 'c',
    [ValidateSet('control', 'loadfirst')]
    [string]$TextureSpanLoadOrder = 'control',
    [ValidateSet('control', 'branch')]
    [string]$TextureSpanAddressing = 'control',
    [int]$TimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        throw 'Could not determine the Windows local application-data directory.'
    }
    $ToolRoot = Join-Path $localAppData '486quake\tools'
}
$ToolRoot = [IO.Path]::GetFullPath($ToolRoot)
if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $repoRoot 'testdata\id1'
}
$DataRoot = [IO.Path]::GetFullPath($DataRoot)

$toolManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$profileSuffixParts = @()
if ($OptimizationProfile -eq 'baseline') { $profileSuffixParts += 'baseline' }
if ($MemoryImplementation -eq 'asm') { $profileSuffixParts += 'memasm' }
if ($TextureSpanLoadOrder -eq 'loadfirst') { $profileSuffixParts += 'spanloadfirst' }
if ($TextureSpanAddressing -eq 'branch') { $profileSuffixParts += 'spanaddrbranch' }
$profileSuffixParts += 'zneg4'
if ($AliasPrepareImplementation -eq 'local') { $profileSuffixParts += 'aliaslocal' }
$profileSuffixParts += 'aliasmatrixspecial'
$profileSuffixParts += 'lightmapstylesasm'
$profileSuffixParts += 'fusedlightmapasm'
if ($DynamicLightImplementation -eq 'asm') { $profileSuffixParts += 'dlightasm' }
$profileSuffix = if ($profileSuffixParts.Count) { '-' + ($profileSuffixParts -join '-') } else { '' }
$djgppExe = Join-Path $repoRoot ('out\dos' + $profileSuffix + '\quake.exe')
$dosboxRoot = Join-Path $ToolRoot $toolManifest.dosboxX.installDirectory
$dosbox = Join-Path $dosboxRoot ($toolManifest.dosboxX.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
$bootstrap = Join-Path $PSScriptRoot 'bootstrap-dos.ps1'
$build = Join-Path $PSScriptRoot 'build-dos.ps1'

if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    if ($NoBootstrap) {
        throw "DOSBox-X not found at '$dosbox'. Run bootstrap-dos.ps1 first or omit -NoBootstrap."
    }
    & $bootstrap -ToolRoot $ToolRoot
}
if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    throw "Required DOSBox-X executable is missing: '$dosbox'."
}

if (-not (Test-Path -LiteralPath $djgppExe -PathType Leaf)) {
    if ($SkipBuild) {
        throw "DOS executable not found at '$djgppExe'. Run build-dos.ps1 first or omit -SkipBuild."
    }
    $buildParams = @{
        ToolRoot = $ToolRoot
        OptimizationProfile = $OptimizationProfile
        MemoryImplementation = $MemoryImplementation
        AliasPrepareImplementation = $AliasPrepareImplementation
        DynamicLightImplementation = $DynamicLightImplementation
        TextureSpanLoadOrder = $TextureSpanLoadOrder
        TextureSpanAddressing = $TextureSpanAddressing
    }
    if ($NoBootstrap) {
        $buildParams['NoBootstrap'] = $true
    }
    & $build @buildParams
}
if (-not (Test-Path -LiteralPath $djgppExe -PathType Leaf)) {
    throw "Required DOS executable is missing: '$djgppExe'."
}

if (-not (Test-Path -LiteralPath $DataRoot -PathType Container)) {
    throw "Game data directory '$DataRoot' does not exist. Put legally obtained data there or pass -DataRoot."
}
$pak0 = Get-ChildItem -LiteralPath $DataRoot -Filter 'pak0.pak' -File | Select-Object -First 1
if ($null -eq $pak0) {
    throw "'$DataRoot' must contain pak0.pak. Game data is intentionally not included in Git."
}
if ($TimeoutSeconds -lt 5) {
    throw 'TimeoutSeconds must be at least 5 seconds.'
}

$stagingRoot = Join-Path $repoRoot 'out\dos-smoke'
if (Test-Path -LiteralPath $stagingRoot) {
    Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}
$quakeRoot = Join-Path $stagingRoot 'quake'
$stagedData = Join-Path $quakeRoot 'id1'
New-Item -ItemType Directory -Path $quakeRoot -Force | Out-Null
New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

Copy-Item -LiteralPath $djgppExe -Destination (Join-Path $quakeRoot 'quake.exe') -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'WinQuake\cwsdpmi.exe') -Destination (Join-Path $quakeRoot 'cwsdpmi.exe') -Force
# Stage only PAK files. Steam id1 also contains configs, saves, and
# autoexec lines that can prevent +quit from returning under the 486 cycle cap.
$pakFiles = @(Get-ChildItem -LiteralPath $DataRoot -Filter 'pak*.pak' -File)
if ($pakFiles.Count -eq 0) {
    throw "'$DataRoot' must contain pak0.pak. Game data is intentionally not included in Git."
}
foreach ($pak in $pakFiles) {
    Copy-Item -LiteralPath $pak.FullName -Destination (Join-Path $stagedData $pak.Name) -Force
}

# quake.rc runs startdemos after stuffcmds in some layouts; a local autoexec
# quits during Host_Init's first Cbuf_Execute so smoke never plays demo1.
# -forcquit skips the Y/N quit menu, key-wait notify boxes, and the VGA sell
# screen (which writes B800:0000 after VID_Shutdown).
'quit' | Set-Content -LiteralPath (Join-Path $stagedData 'autoexec.cfg') -Encoding ASCII

# Keep generated DOS filenames within the 8.3 limit used by DOSBox-X here.
$batchPath = Join-Path $quakeRoot 'smoke.bat'
@'
@echo off
cd \quake
quake.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio -stdvid -forcquit +quit
echo 0 > \quake\smoke.exi
exit
'@ | Set-Content -LiteralPath $batchPath -Encoding ASCII

$profilePath = Join-Path $PSScriptRoot 'dosbox-x-486-high.conf'
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "486 DOSBox-X profile is missing: '$profilePath'."
}
$profileText = Get-Content -LiteralPath $profilePath -Raw
$mountPath = $stagingRoot.Replace('"', '""')
$autoexec = (@"
[autoexec]
mount c "$mountPath"
c:
cd \quake
call smoke.bat
exit
"@).TrimEnd() + [Environment]::NewLine
$runtimeConfig = [regex]::Replace(
    $profileText,
    '(?ms)^\[autoexec\]\s*.*?(?=^\[devices\])',
    [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $autoexec })
if ($runtimeConfig -eq $profileText) {
    throw "Could not replace the autoexec section in '$profilePath'."
}
$configPath = Join-Path $stagingRoot 'dosbox-x.conf'
$runtimeConfig | Set-Content -LiteralPath $configPath -Encoding ASCII

function ConvertTo-ProcessArgument {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + $Value.Replace('"', '\"') + '"'
}

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $dosbox
$processInfo.Arguments = '-conf ' + (ConvertTo-ProcessArgument $configPath) + ' -exit'
$processInfo.WorkingDirectory = Split-Path -Parent $dosbox
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
try {
    Write-Host 'Launching DOSBox-X smoke test'
    if (-not $process.Start()) {
        throw 'DOSBox-X failed to start.'
    }
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "DOSBox-X smoke test exceeded $TimeoutSeconds seconds."
    }
    $dosboxExit = $process.ExitCode
} finally {
    $process.Dispose()
}

$exitMarker = Join-Path $quakeRoot 'smoke.exi'
if (-not (Test-Path -LiteralPath $exitMarker -PathType Leaf)) {
    throw "DOSBox-X exited with code $dosboxExit but Quake did not write '$exitMarker'."
}
$quakeExitText = (Get-Content -LiteralPath $exitMarker -Raw).Trim()
$quakeExit = 0
if (-not [int]::TryParse($quakeExitText, [ref]$quakeExit)) {
    throw "Invalid Quake exit marker '$quakeExitText'."
}
if (($dosboxExit -ne 0) -or ($quakeExit -ne 0)) {
    throw "DOS smoke test failed: DOSBox-X=$dosboxExit, Quake=$quakeExit."
}

$result = [ordered]@{
    dosboxExitCode = $dosboxExit
    quakeExitCode = $quakeExit
    executable = $djgppExe
    dataRoot = $DataRoot
    dynamicLightImplementation = $DynamicLightImplementation
    aliasPrepareImplementation = $AliasPrepareImplementation
    textureSpanLoadOrder = $TextureSpanLoadOrder
    textureSpanAddressing = $TextureSpanAddressing
    timeoutSeconds = $TimeoutSeconds
}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stagingRoot 'smoke-result.json') -Encoding ASCII
Write-Host 'DOS smoke test passed.'

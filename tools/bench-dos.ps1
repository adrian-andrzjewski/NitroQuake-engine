[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$NoBootstrap,
    [string]$ToolRoot,
    [string]$DataRoot,
    [ValidateSet('baseline', 'aggressive')]
    [string]$OptimizationProfile = 'aggressive',
    [ValidateSet(64, 128, 256)]
    [int]$TextureAxisCacheEntries = 256,
    [ValidateSet('c', 'asm')]
    [string]$TextureAxisImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SurfaceCacheImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MipLevelImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MemoryImplementation = 'asm',
    [ValidateSet('c', 'asm', 'stosb')]
    [string]$TurbulentImplementation = 'stosb',
    [ValidateSet('byte', 'word', 'dword', 'loop')]
    [string]$TextureSpanStores = 'word',
    [ValidateSet('c', 'asm')]
    [string]$AliasProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasBBoxProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasTransformFinalImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$TextureAnimationImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$LightMapNormalizeImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$LightMapStylesImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BspPlaneDotImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BspClipImplementation = 'c',
    [switch]$TurbulentOnly,
    [switch]$AliasProjectOnly,
    [switch]$AliasBBoxProjectOnly,
    [switch]$AliasTransformFinalOnly,
    [switch]$TextureAnimationOnly,
    [switch]$LightMapNormalizeOnly,
    [switch]$LightMapStylesOnly,
    [switch]$BspPlaneDotOnly,
    [switch]$BspClipOnly,
    [int]$TimeoutSeconds = 180
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
if ($TimeoutSeconds -lt 10) {
    throw 'TimeoutSeconds must be at least 10 seconds.'
}

$toolManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$profileSuffixParts = @()
if ($OptimizationProfile -eq 'baseline') {
    $profileSuffixParts += 'baseline'
}
if ($TextureAxisCacheEntries -ne 256) {
    $profileSuffixParts += "cache$TextureAxisCacheEntries"
}
if ($MemoryImplementation -eq 'asm') {
    $profileSuffixParts += 'memasm'
}
if ($TextureAxisImplementation -eq 'asm') {
    $profileSuffixParts += 'axisasm'
}
if ($SurfaceCacheImplementation -eq 'asm') {
    $profileSuffixParts += 'surfaceasm'
}
if ($MipLevelImplementation -eq 'asm') {
    $profileSuffixParts += 'mipasm'
}
if ($TurbulentImplementation -eq 'c') {
    $profileSuffixParts += 'turbc'
}
elseif ($TurbulentImplementation -eq 'asm') {
    $profileSuffixParts += 'turbasm'
}
if ($TextureSpanStores -eq 'byte') {
    $profileSuffixParts += 'spanbyte'
}
elseif ($TextureSpanStores -eq 'dword') {
    $profileSuffixParts += 'spandword'
}
elseif ($TextureSpanStores -eq 'loop') {
    $profileSuffixParts += 'spanloop'
}
if ($AliasProjectImplementation -eq 'c') {
    $profileSuffixParts += 'aliasc'
}
if ($AliasBBoxProjectImplementation -eq 'c') {
    $profileSuffixParts += 'aliasbboxc'
}
if ($AliasTransformFinalImplementation -eq 'c') {
    $profileSuffixParts += 'aliastransformc'
}
if ($TextureAnimationImplementation -eq 'c') {
    $profileSuffixParts += 'textureanimc'
}
if ($LightMapNormalizeImplementation -eq 'c') {
    $profileSuffixParts += 'lightmapc'
}
if ($LightMapStylesImplementation -eq 'asm') {
    $profileSuffixParts += 'lightmapstylesasm'
}
if ($DynamicLightImplementation -eq 'asm') {
    $profileSuffixParts += 'dlightasm'
}
if ($BspPlaneDotImplementation -eq 'asm') {
    $profileSuffixParts += 'bspdotasm'
}
if ($BspClipImplementation -eq 'asm') {
    $profileSuffixParts += 'bspclipasm'
}
$profileSuffix = if ($profileSuffixParts.Count) {
    '-' + ($profileSuffixParts -join '-')
}
else {
    ''
}
$benchmarkExe = Join-Path $repoRoot ('out\dos' + $profileSuffix + '\qbench.exe')
$dosboxRoot = Join-Path $ToolRoot $toolManifest.dosboxX.installDirectory
$dosbox = Join-Path $dosboxRoot ($toolManifest.dosboxX.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
$profilePath = Join-Path $PSScriptRoot 'dosbox-x-486-high.conf'
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

if (-not (Test-Path -LiteralPath $benchmarkExe -PathType Leaf)) {
    if ($SkipBuild) {
        throw "Benchmark executable not found at '$benchmarkExe'. Run build-dos.ps1 -Benchmark first or omit -SkipBuild."
    }

    $buildArgs = @('-Benchmark', '-OptimizationProfile', $OptimizationProfile,
        '-TextureAxisCacheEntries', $TextureAxisCacheEntries,
        '-TextureAxisImplementation', $TextureAxisImplementation,
        '-SurfaceCacheImplementation', $SurfaceCacheImplementation,
        '-MipLevelImplementation', $MipLevelImplementation,
        '-MemoryImplementation', $MemoryImplementation,
        '-TurbulentImplementation', $TurbulentImplementation,
        '-TextureSpanStores', $TextureSpanStores,
        '-AliasProjectImplementation', $AliasProjectImplementation,
        '-AliasBBoxProjectImplementation', $AliasBBoxProjectImplementation,
        '-AliasTransformFinalImplementation', $AliasTransformFinalImplementation,
        '-TextureAnimationImplementation', $TextureAnimationImplementation,
        '-LightMapNormalizeImplementation', $LightMapNormalizeImplementation,
        '-LightMapStylesImplementation', $LightMapStylesImplementation,
        '-DynamicLightImplementation', $DynamicLightImplementation,
        '-BspPlaneDotImplementation', $BspPlaneDotImplementation,
        '-BspClipImplementation', $BspClipImplementation,
        '-ToolRoot', $ToolRoot)
    if ($NoBootstrap) {
        $buildArgs += '-NoBootstrap'
    }
    & $build @buildArgs
}
if (-not (Test-Path -LiteralPath $benchmarkExe -PathType Leaf)) {
    throw "Required benchmark executable is missing: '$benchmarkExe'."
}
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "486 DOSBox-X profile is missing: '$profilePath'."
}
if (-not (Test-Path -LiteralPath $DataRoot -PathType Container)) {
    throw "Game data directory '$DataRoot' does not exist. Put legally obtained data there or pass -DataRoot."
}
$pak0 = Get-ChildItem -LiteralPath $DataRoot -Filter 'pak0.pak' -File | Select-Object -First 1
if ($null -eq $pak0) {
    throw "'$DataRoot' must contain pak0.pak. Game data is intentionally not included in Git."
}

$runName = 'dos-bench-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$stagingRoot = Join-Path (Join-Path $repoRoot 'out') $runName
if (Test-Path -LiteralPath $stagingRoot) {
    throw "Benchmark staging path already exists; refusing to overwrite '$stagingRoot'."
}
$quakeRoot = Join-Path $stagingRoot 'quake'
$stagedData = Join-Path $quakeRoot 'id1'
New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

Copy-Item -LiteralPath $benchmarkExe -Destination (Join-Path $quakeRoot 'qbench.exe')
Copy-Item -LiteralPath (Join-Path $repoRoot 'WinQuake\cwsdpmi.exe') -Destination (Join-Path $quakeRoot 'cwsdpmi.exe')
Copy-Item -Path (Join-Path $DataRoot '*') -Destination $stagedData -Recurse -Force

$benchCommand = if ($AliasProjectOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasproject -benchexit'
}
elseif ($AliasBBoxProjectOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasbboxproject -benchexit'
}
elseif ($AliasTransformFinalOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliastransformfinal -benchexit'
}
elseif ($LightMapNormalizeOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchlightmapnormalize -benchexit'
}
elseif ($LightMapStylesOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchlightmapstyles -benchexit'
}
elseif ($BspClipOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchbspclip -benchexit'
}
elseif ($BspPlaneDotOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchbspplanedot -benchexit'
}
elseif ($TextureAnimationOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchtextureanimation -benchexit'
}
elseif ($TurbulentOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchturbulent -benchexit'
}
else {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchexit'
}
$batchPath = Join-Path $quakeRoot 'bench.bat'
@"
@echo off
cd \quake
$benchCommand
exit
"@ | Set-Content -LiteralPath $batchPath -Encoding ASCII

$profileText = Get-Content -LiteralPath $profilePath -Raw
$mountPath = $stagingRoot.Replace('"', '""')
$autoexec = (@"
[autoexec]
mount c "$mountPath"
c:
cd \quake
call bench.bat
exit
"@).TrimEnd() + [Environment]::NewLine
$runtimeConfig = [regex]::Replace(
    $profileText,
    '(?ms)^\[autoexec\]\s*.*?(?=^\[devices\])',
    [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $autoexec })
if ($runtimeConfig -eq $profileText) {
    throw "Could not replace the autoexec section in '$profilePath'."
}
$configPath = Join-Path $stagingRoot 'dosbox-x-bench.conf'
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
    Write-Host "Launching DOSBox-X 486 benchmark in $stagingRoot"
    if (-not $process.Start()) {
        throw 'DOSBox-X failed to start.'
    }
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "DOSBox-X benchmark exceeded $TimeoutSeconds seconds."
    }
    $dosboxExit = $process.ExitCode
}
finally {
    $process.Dispose()
}

$reportPath = Join-Path $quakeRoot 'bench486.txt'
if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    throw "DOSBox-X exited with code $dosboxExit but Quake did not produce '$reportPath'."
}
$report = Get-Content -LiteralPath $reportPath -Raw
if ($dosboxExit -ne 0) {
    throw "DOSBox-X benchmark failed with exit code $dosboxExit."
}
if ($report -match 'correctness FAIL') {
    throw "486 microbenchmark correctness validation failed; inspect '$reportPath'."
}
if ($report -notmatch '486 benchmark correctness PASS') {
    throw "486 microbenchmark did not report a correctness pass; inspect '$reportPath'."
}

$result = [ordered]@{
    dosboxExitCode = $dosboxExit
    executable = $benchmarkExe
    optimizationProfile = $OptimizationProfile
    textureAxisCacheEntries = $TextureAxisCacheEntries
    textureAxisImplementation = $TextureAxisImplementation
    surfaceCacheImplementation = $SurfaceCacheImplementation
    mipLevelImplementation = $MipLevelImplementation
    memoryImplementation = $MemoryImplementation
    turbulentImplementation = $TurbulentImplementation
    textureSpanStores = $TextureSpanStores
    aliasProjectImplementation = $AliasProjectImplementation
    aliasBBoxProjectImplementation = $AliasBBoxProjectImplementation
    aliasTransformFinalImplementation = $AliasTransformFinalImplementation
    textureAnimationImplementation = $TextureAnimationImplementation
    lightMapNormalizeImplementation = $LightMapNormalizeImplementation
    lightMapStylesImplementation = $LightMapStylesImplementation
    dynamicLightImplementation = $DynamicLightImplementation
    bspPlaneDotImplementation = $BspPlaneDotImplementation
    bspClipImplementation = $BspClipImplementation
    turbulentOnly = [bool]$TurbulentOnly
    aliasProjectOnly = [bool]$AliasProjectOnly
    aliasBBoxProjectOnly = [bool]$AliasBBoxProjectOnly
    aliasTransformFinalOnly = [bool]$AliasTransformFinalOnly
    textureAnimationOnly = [bool]$TextureAnimationOnly
    lightMapNormalizeOnly = [bool]$LightMapNormalizeOnly
    lightMapStylesOnly = [bool]$LightMapStylesOnly
    bspPlaneDotOnly = [bool]$BspPlaneDotOnly
    bspClipOnly = [bool]$BspClipOnly
    dataRoot = $DataRoot
    stagingRoot = $stagingRoot
    report = $report
}
$result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stagingRoot 'bench-result.json') -Encoding ASCII
Write-Host $report
Write-Host "Benchmark result: $($stagingRoot)\bench-result.json"

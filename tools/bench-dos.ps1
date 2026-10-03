[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$NoBootstrap,
    [string]$ToolRoot,
    [string]$DataRoot,
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
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
    [ValidateSet('byte', 'word', 'dword', 'loop', 'stosw')]
    [string]$TextureSpanStores = 'word',
    [ValidateSet('control', 'word')]
    [string]$TextureSpanTailStores = 'control',
    [ValidateSet('control', 'norowcross')]
    [string]$TextureSpanRowPath = 'control',
    [ValidateSet('control', 'loadfirst')]
    [string]$TextureSpanLoadOrder = 'control',
    [ValidateSet('control', 'branch')]
    [string]$TextureSpanAddressing = 'control',
    [ValidateSet('control', 'branch')]
    [string]$AliasSpanAddressing = 'control',
    [ValidateSet('control', 'unroll8')]
    [string]$ZSpanNegativeUnroll = 'control',
    [ValidateSet('control', 'unroll4', 'unroll8', 'unroll16')]
    [string]$SurfaceBlockMip0Rows = 'unroll16',
    [ValidateSet('control', 'fast')]
    [string]$SurfaceBlockMip0HorizontalFlat = 'fast',
    [ValidateSet('control', 'unroll8')]
    [string]$SurfaceBlockMip1Rows = 'unroll8',
    [ValidateSet('control', 'fast')]
    [string]$SurfaceBlockMip1HorizontalFlat = 'fast',
    # Hoist the mip-1 flat row's colormap-index byte moves to the top of the
    # row.  Only has an effect when the flat path is on.
    [ValidateSet('control', 'hoist')]
    [string]$SurfaceBlockMip1IndexHoist = 'hoist',
    # Dead-scratch probe over one edge-scan block; measurement only.
    [ValidateSet('control', 'entry', 'step', 'trailing', 'emit', 'insert', 'sort', 'newtop', 'leadin', 'insertexit')]
    [string]$EdgeScanProbe = 'control',
    # Dead-scratch probe at the head of the span16 per-segment setup.
    # $-O3 does not touch this file; the probe is assembler.
    [ValidateSet('control', 'setup')]
    [string]$SpanSetupProbe = 'control',
    # Dead-scratch probe over one block of R_RenderFace's C scaffolding.
    # $-O3 deletes a dead store, so the probe accumulates into a reported
    # global instead. Measurement only, never a candidate.
    [ValidateSet('control', 'prologue', 'edgeval')]
    [string]$RenderFaceProbe = 'control',
    [ValidateSet('control', 'setup')]
    [string]$AliasGlueProbe = 'control',
    [string]$AliasProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasBBoxProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasTransformFinalImplementation = 'asm',
    [ValidateSet('control', 'local')]
    [string]$AliasPrepareImplementation = 'control',
    [ValidateSet('c', 'special')]
    [string]$AliasMatrixCompositionImplementation = 'special',
    [ValidateSet('c', 'asm')]
    [string]$TextureAnimationImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$LightMapNormalizeImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$LightMapStylesImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$FusedLightMapImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$BspPlaneDotImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BspClipImplementation = 'c',
    [ValidateSet('control', 'local')]
    [string]$BspFrameCountImplementation = 'control',
    [ValidateSet('control', 'skipzero')]
    [string]$GibTrailHorizontalIntegration = 'control',
    [switch]$TurbulentOnly,
    [switch]$AliasProjectOnly,
    [switch]$AliasBBoxProjectOnly,
    [switch]$AliasTransformFinalOnly,
    [switch]$TextureAnimationOnly,
    [switch]$LightMapNormalizeOnly,
    [switch]$LightMapStylesOnly,
    [switch]$FusedLightMapOnly,
    [switch]$BspPlaneDotOnly,
    [switch]$BspClipOnly,
    [int]$TimeoutSeconds = 600
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
if ($TextureSpanLoadOrder -eq 'loadfirst' -and $TextureSpanStores -ne 'word') {
    throw 'The loadfirst texture-span path requires -TextureSpanStores word.'
}
if ($TextureSpanAddressing -eq 'branch' -and $TextureSpanStores -ne 'word') {
    throw 'The branch texture-span address path requires -TextureSpanStores word.'
}
if ($TextureSpanAddressing -eq 'branch' -and $TextureSpanLoadOrder -ne 'control') {
    throw 'The branch texture-span address path requires -TextureSpanLoadOrder control.'
}
if ($TextureSpanAddressing -eq 'branch' -and $TextureSpanRowPath -ne 'control') {
    throw 'The branch texture-span address path requires -TextureSpanRowPath control.'
}
if ($TextureSpanStores -eq 'stosw' -and
		($TextureSpanLoadOrder -ne 'control' -or
		$TextureSpanAddressing -ne 'control' -or
		$TextureSpanRowPath -ne 'control')) {
	throw 'The stosw texture-span store path requires control load order, addressing, and row path.'
}

$toolManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$build = Join-Path $PSScriptRoot 'build-dos.ps1'
$bootstrap = Join-Path $PSScriptRoot 'bootstrap-dos.ps1'
$buildParams = @{
        Benchmark = $true
        CpuTarget = $CpuTarget
        OptimizationProfile = $OptimizationProfile
        TextureAxisCacheEntries = $TextureAxisCacheEntries
        TextureAxisImplementation = $TextureAxisImplementation
        SurfaceCacheImplementation = $SurfaceCacheImplementation
        MipLevelImplementation = $MipLevelImplementation
        MemoryImplementation = $MemoryImplementation
        TurbulentImplementation = $TurbulentImplementation
        TextureSpanStores = $TextureSpanStores
        TextureSpanTailStores = $TextureSpanTailStores
        TextureSpanRowPath = $TextureSpanRowPath
        TextureSpanLoadOrder = $TextureSpanLoadOrder
        TextureSpanAddressing = $TextureSpanAddressing
        AliasSpanAddressing = $AliasSpanAddressing
        ZSpanNegativeUnroll = $ZSpanNegativeUnroll
        SurfaceBlockMip0Rows = $SurfaceBlockMip0Rows
        SurfaceBlockMip0HorizontalFlat = $SurfaceBlockMip0HorizontalFlat
        SurfaceBlockMip1Rows = $SurfaceBlockMip1Rows
        SurfaceBlockMip1HorizontalFlat = $SurfaceBlockMip1HorizontalFlat
        SurfaceBlockMip1IndexHoist = $SurfaceBlockMip1IndexHoist
        EdgeScanProbe = $EdgeScanProbe
        SpanSetupProbe = $SpanSetupProbe
        RenderFaceProbe = $RenderFaceProbe
        AliasGlueProbe = $AliasGlueProbe
        AliasProjectImplementation = $AliasProjectImplementation
        AliasBBoxProjectImplementation = $AliasBBoxProjectImplementation
        AliasTransformFinalImplementation = $AliasTransformFinalImplementation
        AliasPrepareImplementation = $AliasPrepareImplementation
        AliasMatrixCompositionImplementation = $AliasMatrixCompositionImplementation
        TextureAnimationImplementation = $TextureAnimationImplementation
        LightMapNormalizeImplementation = $LightMapNormalizeImplementation
        LightMapStylesImplementation = $LightMapStylesImplementation
        FusedLightMapImplementation = $FusedLightMapImplementation
        DynamicLightImplementation = $DynamicLightImplementation
        BspPlaneDotImplementation = $BspPlaneDotImplementation
        BspClipImplementation = $BspClipImplementation
        BspFrameCountImplementation = $BspFrameCountImplementation
        GibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
        ToolRoot = $ToolRoot
    }

# Ask the builder where the output lands instead of recomputing the profile
# suffix here.  This runner used to carry its own copy of that arithmetic, and so
# did smoke-dos.ps1 and timedemo-dos.ps1; three copies of one rule is a standing
# invitation for a runner to look for an executable the builder never wrote.
# The builder is the only place that knows.
$resolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
$buildRoot = $resolved.outputRoot
$benchmarkExe = $resolved.executable
$dosboxRoot = Join-Path $ToolRoot $toolManifest.dosboxX.installDirectory
$dosbox = Join-Path $dosboxRoot ($toolManifest.dosboxX.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
$profilePath = Join-Path $PSScriptRoot 'dosbox-x-486-high.conf'

if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    if ($NoBootstrap) {
        throw "DOSBox-X not found at '$dosbox'. Run bootstrap-dos.ps1 first or omit -NoBootstrap."
    }
    & $bootstrap -ToolRoot $ToolRoot
}
if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    throw "Required DOSBox-X executable is missing: '$dosbox'."
}

# Fingerprint the sources and the selector set, exactly as timedemo-dos.ps1 does,
# and rebuild when they have moved.  This runner used to rebuild only when the
# executable was *missing*, which meant an existing qbench.exe was benchmarked
# indefinitely no matter how many sources had changed -- so a correctness FAIL
# could be reported against a binary that no longer matched the tree.  That is
# not hypothetical: it is how an i386 bsp-clip failure survived a source fix and
# was re-observed three times before the stale binary was noticed.
$sourceRoot = Join-Path $repoRoot 'WinQuake'
$selectorState = (@(
        $OptimizationProfile, $TextureAxisCacheEntries, $TextureAxisImplementation,
        $SurfaceCacheImplementation, $MipLevelImplementation, $TurbulentImplementation,
        $MemoryImplementation, $TextureSpanStores, $TextureSpanTailStores,
        $TextureSpanRowPath, $TextureSpanLoadOrder, $TextureSpanAddressing,
        $AliasSpanAddressing, $ZSpanNegativeUnroll, $SurfaceBlockMip0Rows,
        $SurfaceBlockMip0HorizontalFlat, $SurfaceBlockMip1Rows,
        $SurfaceBlockMip1HorizontalFlat, $SurfaceBlockMip1IndexHoist,
        $EdgeScanProbe, $SpanSetupProbe, $RenderFaceProbe, $AliasGlueProbe,
        $AliasProjectImplementation, $AliasBBoxProjectImplementation,
        $AliasTransformFinalImplementation, $AliasPrepareImplementation,
        $AliasMatrixCompositionImplementation, $TextureAnimationImplementation,
        $LightMapNormalizeImplementation, $LightMapStylesImplementation,
        $FusedLightMapImplementation, $DynamicLightImplementation,
        $BspPlaneDotImplementation, $BspClipImplementation,
        $BspFrameCountImplementation, $GibTrailHorizontalIntegration
    ) -join '|')
$buildInputs = @(
    Get-ChildItem -LiteralPath $sourceRoot -Include '*.c', '*.s', '*.h' -File -Recurse |
        Sort-Object FullName |
        ForEach-Object { "$($_.FullName.Substring($sourceRoot.Length))=$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)" }
)
$buildInputs += "selectors=$selectorState"
$buildInputs += "cpuTarget=$CpuTarget"
$fingerprintHasher = [Security.Cryptography.SHA256]::Create()
try {
    $sourceFingerprint = ([BitConverter]::ToString(
            $fingerprintHasher.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes($buildInputs -join "`n")))).Replace('-', '')
}
finally {
    $fingerprintHasher.Dispose()
}
$fingerprintPath = Join-Path (Split-Path -Parent $benchmarkExe) 'qbench.sources.sha256'
$executableExists = Test-Path -LiteralPath $benchmarkExe -PathType Leaf
$staleBuild = $false
if ($executableExists) {
    if (-not (Test-Path -LiteralPath $fingerprintPath -PathType Leaf)) {
        # Pre-fingerprint binary: its provenance is unknowable, so rebuild it.
        $staleBuild = $true
    }
    else {
        $staleBuild = ((Get-Content -LiteralPath $fingerprintPath -Raw).Trim() -ne $sourceFingerprint)
    }
}
if ((-not $executableExists) -or $staleBuild) {
    if ($SkipBuild) {
        if ($staleBuild) {
            throw "Benchmark executable '$benchmarkExe' is stale with respect to the current sources (fingerprint $sourceFingerprint). Rerun without -SkipBuild to rebuild."
        }
        throw "Benchmark executable not found at '$benchmarkExe'. Run build-dos.ps1 -Benchmark first or omit -SkipBuild."
    }

    if ($staleBuild) {
        Write-Host ("Benchmark build is stale (fingerprint {0}); rebuilding." -f $sourceFingerprint.Substring(0, 12))
    }
    if ($NoBootstrap) {
        $buildParams['NoBootstrap'] = $true
    }
    & $build @buildParams
    if (-not (Test-Path -LiteralPath $benchmarkExe -PathType Leaf)) {
        throw "Required benchmark executable is missing: '$benchmarkExe'."
    }
    Set-Content -LiteralPath $fingerprintPath -Value $sourceFingerprint -Encoding ASCII -NoNewline
}
if (-not (Test-Path -LiteralPath $benchmarkExe -PathType Leaf)) {
    throw "Required benchmark executable is missing: '$benchmarkExe'."
}
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "DOSBox-X profile is missing: '$profilePath'."
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

# Hardlink the paks instead of copying ~50 MB per run. Same volume as the
# repository is required because NTFS hardlinks cannot span volumes.
if ([IO.Path]::GetPathRoot($DataRoot) -ne [IO.Path]::GetPathRoot($repoRoot)) {
    throw "Game data must be on the same volume as the repository so staging can hardlink it instead of copying 50 MB per run. Copy pak*.pak to '$(Join-Path $repoRoot 'testdata\id1')' and drop -DataRoot. See BUILD-DOS.md."
}
foreach ($pak in Get-ChildItem -LiteralPath $DataRoot -Filter 'pak*.pak' -File) {
    New-Item -ItemType HardLink -Path (Join-Path $stagedData $pak.Name) -Value $pak.FullName -Force | Out-Null
}

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
elseif ($FusedLightMapOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchfusedlightmap -benchexit'
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

# Follow the build target's CPU model.  The base profile uses a fixed cycle count
# so timings stay comparable; only the emulated CPU changes.  DOSBox-X's cputype
# does not enforce instruction-set gating, so the ISA audit remains the gate.
if ($CpuTarget -ne 'i486') {
    $cpuModel = $CpuTarget -replace '^i', ''
    $forcedConfig = [regex]::Replace(
        $runtimeConfig,
        '(?m)^cputype\s*=\s*\S+',
        "cputype            = $cpuModel")
    if ($forcedConfig -eq $runtimeConfig) {
        throw "Could not set the DOSBox-X cputype to '$cpuModel' in '$profilePath'."
    }
    $runtimeConfig = $forcedConfig
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
    textureSpanTailStores = $TextureSpanTailStores
    textureSpanRowPath = $TextureSpanRowPath
    textureSpanLoadOrder = $TextureSpanLoadOrder
    textureSpanAddressing = $TextureSpanAddressing
    aliasSpanAddressing = $AliasSpanAddressing
    zSpanNegativeUnroll = $ZSpanNegativeUnroll
    surfaceBlockMip0Rows = $SurfaceBlockMip0Rows
    surfaceBlockMip0HorizontalFlat = $SurfaceBlockMip0HorizontalFlat
    surfaceBlockMip1Rows = $SurfaceBlockMip1Rows
    surfaceBlockMip1HorizontalFlat = $SurfaceBlockMip1HorizontalFlat
    surfaceBlockMip1IndexHoist = $SurfaceBlockMip1IndexHoist
    edgeScanProbe = $EdgeScanProbe
    aliasProjectImplementation = $AliasProjectImplementation
    aliasBBoxProjectImplementation = $AliasBBoxProjectImplementation
    aliasTransformFinalImplementation = $AliasTransformFinalImplementation
    aliasPrepareImplementation = $AliasPrepareImplementation
    aliasMatrixCompositionImplementation = $AliasMatrixCompositionImplementation
    textureAnimationImplementation = $TextureAnimationImplementation
    lightMapNormalizeImplementation = $LightMapNormalizeImplementation
    lightMapStylesImplementation = $LightMapStylesImplementation
    fusedLightMapImplementation = $FusedLightMapImplementation
    dynamicLightImplementation = $DynamicLightImplementation
    bspPlaneDotImplementation = $BspPlaneDotImplementation
    bspClipImplementation = $BspClipImplementation
    bspFrameCountImplementation = $BspFrameCountImplementation
    gibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
    turbulentOnly = [bool]$TurbulentOnly
    aliasProjectOnly = [bool]$AliasProjectOnly
    aliasBBoxProjectOnly = [bool]$AliasBBoxProjectOnly
    aliasTransformFinalOnly = [bool]$AliasTransformFinalOnly
    textureAnimationOnly = [bool]$TextureAnimationOnly
    lightMapNormalizeOnly = [bool]$LightMapNormalizeOnly
    lightMapStylesOnly = [bool]$LightMapStylesOnly
    fusedLightMapOnly = [bool]$FusedLightMapOnly
    bspPlaneDotOnly = [bool]$BspPlaneDotOnly
    bspClipOnly = [bool]$BspClipOnly
    dataRoot = $DataRoot
    stagingRoot = $stagingRoot
    report = $report
}
$result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stagingRoot 'bench-result.json') -Encoding ASCII
Write-Host $report
Write-Host "Benchmark result: $($stagingRoot)\bench-result.json"

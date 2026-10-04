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
. (Join-Path $PSScriptRoot 'common.ps1')
$ToolRoot = Resolve-ToolRoot -ToolRoot $ToolRoot
$DataRoot = Resolve-DataRoot -DataRoot $DataRoot -RepoRoot $repoRoot
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

$toolManifest = Read-ToolchainManifest -ToolsDirectory $PSScriptRoot
$build = Join-Path $PSScriptRoot 'build-dos.ps1'
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
$benchmarkExe = $resolved.executable
$dosbox = Resolve-DosboxExecutable -Manifest $toolManifest -ToolRoot $ToolRoot `
    -ToolsDirectory $PSScriptRoot -NoBootstrap:$NoBootstrap

# Fingerprint the sources and the selector set, exactly as timedemo-dos.ps1 does,
# and rebuild when they have moved.  This runner used to rebuild only when the
# executable was *missing*, which meant an existing qbench.exe was benchmarked
# indefinitely no matter how many sources had changed -- so a correctness FAIL
# could be reported against a binary that no longer matched the tree.  That is
# not hypothetical: it is how an i386 bsp-clip failure survived a source fix and
# was re-observed three times before the stale binary was noticed.
#
# The hashing is shared, via tools\common.ps1, which smoke-dos.ps1,
# coverage-dos.ps1 and timedemo-dos.ps1 also use.
$sourceFingerprint = Get-BuildFingerprint -RepoRoot $repoRoot -Resolved $resolved

$freshness = Get-BuildFreshness -Executable $benchmarkExe -Fingerprint $sourceFingerprint
$executableExists = $freshness.Exists
$staleBuild = $freshness.Stale
if ((-not $executableExists) -or $staleBuild) {
    if ($SkipBuild) {
        if ($staleBuild) {
            throw "Benchmark executable '$benchmarkExe' is stale with respect to the current sources (fingerprint $sourceFingerprint). Rerun without -SkipBuild to rebuild."
        }
        throw "Benchmark executable not found at '$benchmarkExe'. Run build-dos.ps1 -Benchmark first or omit -SkipBuild."
    }

    if ($staleBuild) {
        Write-Host ("Benchmark build is stale (fingerprint {0}); rebuilding." -f $freshness.FingerprintPrefix)
    }
    if ($NoBootstrap) {
        $buildParams['NoBootstrap'] = $true
    }
    & $build @buildParams
    if (-not (Test-Path -LiteralPath $benchmarkExe -PathType Leaf)) {
        throw "Required benchmark executable is missing: '$benchmarkExe'."
    }
    Set-BuildFingerprint -Executable $benchmarkExe -Fingerprint $sourceFingerprint
}
if (-not (Test-Path -LiteralPath $benchmarkExe -PathType Leaf)) {
    throw "Required benchmark executable is missing: '$benchmarkExe'."
}

# The staging directory is UTC-stamped, so it cannot already exist; New-QuakeStaging
# refuses rather than overwrites.  The data-root and pak checks, the same-volume check
# and the hardlinking are in there; the note on why paks and nothing else is on that
# function.
$staging = New-QuakeStaging -RepoRoot $repoRoot `
    -StagingRoot (Join-Path (Join-Path $repoRoot 'out') ('dos-bench-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))) `
    -Executable $benchmarkExe -StagedExecutableName 'qbench.exe' -DataRoot $DataRoot `
    -OnExistingStaging Throw -StageDpmiHost
$stagingRoot = $staging.StagingRoot
$quakeRoot = $staging.QuakeRoot
$stagedData = $staging.StagedData

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

$configPath = New-DosboxRuntimeConfig -ProfileTemplate (Get-DosboxProfilePath -ToolsDirectory $PSScriptRoot) `
    -StagingRoot $stagingRoot -BatchName 'bench.bat' -CpuTarget $CpuTarget -ConfigName 'dosbox-x-bench.conf'

$run = Invoke-DosboxProcess -Dosbox $dosbox -ConfigPath $configPath `
    -TimeoutSeconds $TimeoutSeconds -Description "DOSBox-X 486 benchmark in $stagingRoot"
if ($run.TimedOut) {
    throw "DOSBox-X benchmark exceeded $TimeoutSeconds seconds."
}
$dosboxExit = $run.ExitCode

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

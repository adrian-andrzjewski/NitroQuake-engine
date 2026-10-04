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
    [ValidateSet('c', 'asm')]
    [string]$MemoryImplementation = 'asm',
    [ValidateSet('control', 'local')]
    [string]$AliasPrepareImplementation = 'control',
    # 'asm' to match build-dos.ps1, bench-dos.ps1 and timedemo-dos.ps1.  This
    # used to be 'c', and because this runner computed the profile suffix itself
    # it then looked for out\dos-memasm-...-fusedlightmapasm\quake.exe while the
    # release build lives in out\dos-memasm-...-fusedlightmapasm-dlightasm\.
    # So `smoke-dos.ps1 -SkipBuild` was not testing the release binary at all.
    # The runner now asks the builder for its output path, which is what made the
    # divergence visible.
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightImplementation = 'asm',
    [ValidateSet('byte', 'word', 'dword', 'loop', 'stosw')]
    [string]$TextureSpanStores = 'word',
    [ValidateSet('control', 'loadfirst')]
    [string]$TextureSpanLoadOrder = 'control',
    [ValidateSet('control', 'branch')]
    [string]$TextureSpanAddressing = 'control',
    [ValidateSet('control', 'branch')]
    [string]$AliasSpanAddressing = 'control',
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
    [string]$BspFrameCountImplementation = 'control',
    [ValidateSet('control', 'skipzero')]
    [string]$GibTrailHorizontalIntegration = 'control',
    [int]$TimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'common.ps1')
$ToolRoot = Resolve-ToolRoot -ToolRoot $ToolRoot
$DataRoot = Resolve-DataRoot -DataRoot $DataRoot -RepoRoot $repoRoot

if ($TextureSpanStores -eq 'stosw' -and
		($TextureSpanLoadOrder -ne 'control' -or
		$TextureSpanAddressing -ne 'control')) {
	throw 'The stosw texture-span store path requires control load order and addressing.'
}

$toolManifest = Read-ToolchainManifest -ToolsDirectory $PSScriptRoot
$build = Join-Path $PSScriptRoot 'build-dos.ps1'
$buildParams = @{
    ToolRoot = $ToolRoot
    CpuTarget = $CpuTarget
    OptimizationProfile = $OptimizationProfile
    MemoryImplementation = $MemoryImplementation
    AliasPrepareImplementation = $AliasPrepareImplementation
    DynamicLightImplementation = $DynamicLightImplementation
    TextureSpanStores = $TextureSpanStores
    TextureSpanLoadOrder = $TextureSpanLoadOrder
    TextureSpanAddressing = $TextureSpanAddressing
    AliasSpanAddressing = $AliasSpanAddressing
    SurfaceBlockMip0Rows = $SurfaceBlockMip0Rows
    SurfaceBlockMip0HorizontalFlat = $SurfaceBlockMip0HorizontalFlat
    SurfaceBlockMip1Rows = $SurfaceBlockMip1Rows
    SurfaceBlockMip1HorizontalFlat = $SurfaceBlockMip1HorizontalFlat
    SurfaceBlockMip1IndexHoist = $SurfaceBlockMip1IndexHoist
    EdgeScanProbe = $EdgeScanProbe
    SpanSetupProbe = $SpanSetupProbe
    RenderFaceProbe = $RenderFaceProbe
    AliasGlueProbe = $AliasGlueProbe
    BspFrameCountImplementation = $BspFrameCountImplementation
    GibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
}

# Ask the builder where the output lands instead of recomputing the profile
# suffix here.  This runner used to carry its own copy of that arithmetic, and
# so did bench-dos.ps1 and timedemo-dos.ps1; three copies of one rule is a
# standing invitation for a runner to look for an executable the builder never
# wrote.  The builder is the only place that knows.
$resolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
$djgppExe = $resolved.executable
$dosbox = Resolve-DosboxExecutable -Manifest $toolManifest -ToolRoot $ToolRoot `
    -ToolsDirectory $PSScriptRoot -NoBootstrap:$NoBootstrap

# Rebuild when the executable is missing OR when it no longer matches the tree.
# This runner used to test only for existence, so an existing quake.exe was
# smoke-tested indefinitely no matter how many sources had changed -- the same
# defect bench-dos.ps1 had already fixed for itself, and the reason a correctness
# failure there could once be reported against a stale binary. The hashing is
# shared with the other three runners via tools\common.ps1.
$sourceFingerprint = Get-BuildFingerprint -RepoRoot $repoRoot -Resolved $resolved
$freshness = Get-BuildFreshness -Executable $djgppExe -Fingerprint $sourceFingerprint
if ((-not $freshness.Exists) -or $freshness.Stale) {
    if ($SkipBuild) {
        if ($freshness.Stale) {
            throw "DOS executable '$djgppExe' is stale with respect to the current sources (fingerprint $sourceFingerprint). Rerun without -SkipBuild to rebuild."
        }
        throw "DOS executable not found at '$djgppExe'. Run build-dos.ps1 first or omit -SkipBuild."
    }
    if ($freshness.Stale) {
        Write-Host ("Release build is stale (fingerprint {0}); rebuilding." -f $freshness.FingerprintPrefix)
    }
    if ($NoBootstrap) {
        $buildParams['NoBootstrap'] = $true
    }
    & $build @buildParams
    if (-not (Test-Path -LiteralPath $djgppExe -PathType Leaf)) {
        throw "Required DOS executable is missing: '$djgppExe'."
    }
    Set-BuildFingerprint -Executable $djgppExe -Fingerprint $sourceFingerprint
}
if (-not (Test-Path -LiteralPath $djgppExe -PathType Leaf)) {
    throw "Required DOS executable is missing: '$djgppExe'."
}

if ($TimeoutSeconds -lt 5) {
    throw 'TimeoutSeconds must be at least 5 seconds.'
}

# This runner's staging directory has a fixed name, so it is overwritten rather
# than refused.  The data-root and pak checks, the same-volume check and the
# hardlinking are in New-QuakeStaging; the ordering note on hardlinks and Steam's
# extra files is on that function.
$staging = New-QuakeStaging -RepoRoot $repoRoot -StagingRoot (Join-Path $repoRoot 'out\dos-smoke') `
    -Executable $djgppExe -StagedExecutableName 'quake.exe' -DataRoot $DataRoot `
    -OnExistingStaging Overwrite -StageDpmiHost
$stagingRoot = $staging.StagingRoot
$quakeRoot = $staging.QuakeRoot
$stagedData = $staging.StagedData

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

# One DOSBox-X profile serves every runner and both CPU targets; the runtime copy
# differs only in its [autoexec] and, for a non-i486 build, its cputype.
$configPath = New-DosboxRuntimeConfig -ProfileTemplate (Get-DosboxProfilePath -ToolsDirectory $PSScriptRoot) `
    -StagingRoot $stagingRoot -BatchName 'smoke.bat' -CpuTarget $CpuTarget -ConfigName 'dosbox-x.conf'

$run = Invoke-DosboxProcess -Dosbox $dosbox -ConfigPath $configPath `
    -TimeoutSeconds $TimeoutSeconds -Description 'DOSBox-X smoke test'
if ($run.TimedOut) {
    throw "DOSBox-X smoke test exceeded $TimeoutSeconds seconds."
}
$dosboxExit = $run.ExitCode

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
    textureSpanStores = $TextureSpanStores
    aliasPrepareImplementation = $AliasPrepareImplementation
    textureSpanLoadOrder = $TextureSpanLoadOrder
    textureSpanAddressing = $TextureSpanAddressing
    aliasSpanAddressing = $AliasSpanAddressing
    surfaceBlockMip0Rows = $SurfaceBlockMip0Rows
    surfaceBlockMip0HorizontalFlat = $SurfaceBlockMip0HorizontalFlat
    surfaceBlockMip1Rows = $SurfaceBlockMip1Rows
    bspFrameCountImplementation = $BspFrameCountImplementation
    surfaceBlockMip1HorizontalFlat = $SurfaceBlockMip1HorizontalFlat
    surfaceBlockMip1IndexHoist = $SurfaceBlockMip1IndexHoist
    edgeScanProbe = $EdgeScanProbe
    gibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
    timeoutSeconds = $TimeoutSeconds
}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stagingRoot 'smoke-result.json') -Encoding ASCII
Write-Host 'DOS smoke test passed.'

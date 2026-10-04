[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$Instrumentation,
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
    # Dead-scratch probe over one edge-scan block; measurement only, never a
    # candidate.  See build-dos.ps1 for what the probe actually duplicates.
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
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$DemoName = 'demo1',
    [ValidateRange(1, 9)]
    [int]$Runs = 3,
    [int]$TimeoutSeconds = 180,
    # Per-frame FPS collection costs ~0.0117 s on the 969-frame demo1 run
    # (0.020%, about 39% of the 0.05% promotion gate), so it is OFF by default
    # and opt-in. The recorded baseline 59.227329 s was measured with it off.
    [switch]$FpsStats,
    # Retained so older recorded commands keep working; now the default.
    [switch]$NoFpsStats,
    # External DPMI host only; does not change the Quake/DJGPP binary.
    # cwsdpmi: stage CWSDPMI.EXE (DJGPP stub auto-loads it when no host is resident).
    # hdpmi32: stage HDPMI32.EXE, omit CWSDPMI, install resident with -r before Quake.
    [ValidateSet('cwsdpmi', 'hdpmi32')]
    [string]$DpmiHost = 'cwsdpmi',
    # Extra HDPMI32 flags after -r (e.g. '-m' to disable DPMI 1.0 memory APIs for DJGPP).
    [string]$HdpmiExtraArgs = '',
    # Optional DOS environment assignments before HDPMI32 (e.g. 'HDPMI=512').
    [string]$HdpmiEnv = '',
    # Extra Quake/qbench command-line tokens (e.g. '-mem 8' to pin heap size across DPMI hosts).
    [string]$QuakeExtraArgs = '',
    # When using hdpmi32, still run DPMI.EXE to record the resident host identity.
    [switch]$SkipDpmiProbe,
    #
    # Parity gates. These were previously recorded in the report but never
    # compared, so a changed emulator core or profile would silently re-baseline
    # every number in the ledger. They are now enforced; a mismatch fails the run.
    # Pass -AllowGateOverride to record a deliberate exception, which is logged.
    [string]$ExpectedProfileSha256 = 'F3948708A493A0AD3B7D167230065CAF3827CD16DD350E83C6B547E48DDD8E45',
    [int]$ExpectedFrames = 969,
    [int]$ExpectedChecksum = 1047377823,
    [switch]$AllowGateOverride
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
if ($TimeoutSeconds -lt 30) {
    throw 'TimeoutSeconds must be at least 30 seconds.'
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
$buildParams = @{
    Benchmark                            = $true
    CpuTarget                            = $CpuTarget
    OptimizationProfile                  = $OptimizationProfile
    TextureAxisCacheEntries              = $TextureAxisCacheEntries
    TextureAxisImplementation            = $TextureAxisImplementation
    SurfaceCacheImplementation           = $SurfaceCacheImplementation
    MipLevelImplementation               = $MipLevelImplementation
    MemoryImplementation                 = $MemoryImplementation
    TurbulentImplementation              = $TurbulentImplementation
    TextureSpanStores                    = $TextureSpanStores
    TextureSpanTailStores                = $TextureSpanTailStores
    TextureSpanRowPath                   = $TextureSpanRowPath
    TextureSpanLoadOrder                 = $TextureSpanLoadOrder
    TextureSpanAddressing                = $TextureSpanAddressing
    AliasSpanAddressing                  = $AliasSpanAddressing
    ZSpanNegativeUnroll                  = $ZSpanNegativeUnroll
    SurfaceBlockMip0Rows                 = $SurfaceBlockMip0Rows
    SurfaceBlockMip0HorizontalFlat       = $SurfaceBlockMip0HorizontalFlat
    SurfaceBlockMip1Rows                 = $SurfaceBlockMip1Rows
    SurfaceBlockMip1HorizontalFlat       = $SurfaceBlockMip1HorizontalFlat
    SurfaceBlockMip1IndexHoist           = $SurfaceBlockMip1IndexHoist
    EdgeScanProbe                        = $EdgeScanProbe
    SpanSetupProbe                       = $SpanSetupProbe
    RenderFaceProbe                      = $RenderFaceProbe
    AliasGlueProbe                       = $AliasGlueProbe
    AliasProjectImplementation           = $AliasProjectImplementation
    AliasBBoxProjectImplementation       = $AliasBBoxProjectImplementation
    AliasTransformFinalImplementation    = $AliasTransformFinalImplementation
    AliasPrepareImplementation           = $AliasPrepareImplementation
    AliasMatrixCompositionImplementation = $AliasMatrixCompositionImplementation
    TextureAnimationImplementation       = $TextureAnimationImplementation
    LightMapNormalizeImplementation      = $LightMapNormalizeImplementation
    LightMapStylesImplementation         = $LightMapStylesImplementation
    FusedLightMapImplementation          = $FusedLightMapImplementation
    DynamicLightImplementation           = $DynamicLightImplementation
    BspPlaneDotImplementation            = $BspPlaneDotImplementation
    BspClipImplementation                = $BspClipImplementation
    BspFrameCountImplementation          = $BspFrameCountImplementation
    GibTrailHorizontalIntegration       = $GibTrailHorizontalIntegration
    ToolRoot                             = $ToolRoot
}

$build = Join-Path $PSScriptRoot 'build-dos.ps1'
$bootstrap = Join-Path $PSScriptRoot 'bootstrap-dos.ps1'

# Ask the builder where the output lands instead of recomputing the profile
# suffix here.  This runner used to carry its own copy of that arithmetic, and so
# did smoke-dos.ps1 and bench-dos.ps1; three copies of one rule is a standing
# invitation for a runner to look for an executable the builder never wrote.
# The builder is the only place that knows.
$resolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
$benchmarkExe = $resolved.executable

$dosboxRoot = Join-Path $ToolRoot $toolManifest.dosboxX.installDirectory
$dosbox = Join-Path $dosboxRoot ($toolManifest.dosboxX.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
$profilePath = Join-Path $PSScriptRoot 'dosbox-x-486-high.conf'

# The staged executable name follows the builder's resolution too: -Benchmark
# gives qbench.exe and -Instrumentation gives qprof.exe, and duplicating that
# rule here is what let the two sides drift apart.
$executableName = [IO.Path]::GetFileName($resolved.executable)

if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    if ($NoBootstrap) {
        throw "DOSBox-X not found at '$dosbox'. Run bootstrap-dos.ps1 first or omit -NoBootstrap."
    }
    & $bootstrap -ToolRoot $ToolRoot
}
if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    throw "Required DOSBox-X executable is missing: '$dosbox'."
}

# The previous gate here was `if (-not (Test-Path $benchmarkExe))`, keyed on the
# selector profile alone. That silently ignored every source edit once the
# executable existed, so a timedemo could report the previous binary's time; it
# produced a real false negative in this project. Hash the sources and the
# resolved selectors instead, and rebuild whenever they differ.
#
# The hashing is shared with bench-dos.ps1, smoke-dos.ps1 and coverage-dos.ps1 via
# tools\common.ps1, and derives the configuration half from the builder's resolved
# output rather than from a hand-kept selector list. This runner and bench-dos.ps1
# both build -Benchmark into the same directory, and their two hand-written
# selector lists had drifted in order, so a fixed fingerprint filename would have
# had them overwrite each other's record and rebuild each other's binary on
# alternating runs.
. (Join-Path $PSScriptRoot 'common.ps1')
$sourceFingerprint = Get-BuildFingerprint -RepoRoot $repoRoot -Resolved $resolved

$freshness = Get-BuildFreshness -Executable $benchmarkExe -Fingerprint $sourceFingerprint
$executableExists = $freshness.Exists
$staleBuild = $freshness.Stale
if ((-not $executableExists) -or $staleBuild) {
    if ($SkipBuild) {
        if ($staleBuild) {
            throw "Benchmark executable '$benchmarkExe' is stale with respect to the current sources (fingerprint $sourceFingerprint). Rerun without -SkipBuild to rebuild; see ASM486-HANDOFF.md 'the timedemo runner will not rebuild after a source edit'."
        }
        throw "Benchmark executable not found at '$benchmarkExe'. Run build-dos.ps1 -Benchmark first or omit -SkipBuild."
    }

    Write-Host ("Benchmark build is stale (fingerprint {0}); rebuilding." -f $freshness.FingerprintPrefix)

    if ($Instrumentation) {
        $buildParams['Instrumentation'] = $true
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

$dpmiSuffix = if ($DpmiHost -eq 'cwsdpmi') { '' } else { '-hdpmi32' }
$runName = 'dos-timedemo' + $dpmiSuffix + '-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$stagingRoot = Join-Path (Join-Path $repoRoot 'out') $runName
if (Test-Path -LiteralPath $stagingRoot) {
    throw "Timedemo staging path already exists; refusing to overwrite '$stagingRoot'."
}
$quakeRoot = Join-Path $stagingRoot 'quake'
$stagedData = Join-Path $quakeRoot 'id1'
$fpsStatsEnabled = [bool]($FpsStats -and -not $NoFpsStats)
$fpsStatsOptions = if ($fpsStatsEnabled) { ' -fpsstats' } else { '' }
New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

$cwsdpmiSource = Join-Path $repoRoot 'src\cwsdpmi.exe'
$hdpmiDir = Join-Path $PSScriptRoot 'thirdparty\hdpmi'
$hdpmiSource = Join-Path $hdpmiDir 'HDPMI32.EXE'
$dpmiProbeSource = Join-Path $hdpmiDir 'DPMI.EXE'
$dpmiHostPath = $null
$dpmiHostSha256 = $null
$hdpmiLoadLine = ''
$dpmiProbeLines = @()

Copy-Item -LiteralPath $benchmarkExe -Destination (Join-Path $quakeRoot $executableName)

# Hardlink the paks instead of copying ~50 MB per run. Same volume as the
# repository is required because NTFS hardlinks cannot span volumes.
if ([IO.Path]::GetPathRoot($DataRoot) -ne [IO.Path]::GetPathRoot($repoRoot)) {
    throw "Game data must be on the same volume as the repository so staging can hardlink it instead of copying 50 MB per run. Copy pak*.pak to '$(Join-Path $repoRoot 'testdata\id1')' and drop -DataRoot. See BUILD-DOS.md."
}
foreach ($pak in Get-ChildItem -LiteralPath $DataRoot -Filter 'pak*.pak' -File) {
    New-Item -ItemType HardLink -Path (Join-Path $stagedData $pak.Name) -Value $pak.FullName -Force | Out-Null
}

if ($DpmiHost -eq 'cwsdpmi') {
    if (-not (Test-Path -LiteralPath $cwsdpmiSource -PathType Leaf)) {
        throw "CWSDPMI binary missing: '$cwsdpmiSource'."
    }
    Copy-Item -LiteralPath $cwsdpmiSource -Destination (Join-Path $quakeRoot 'cwsdpmi.exe')
    $dpmiHostPath = $cwsdpmiSource
}
else {
    if (-not (Test-Path -LiteralPath $hdpmiSource -PathType Leaf)) {
        throw "HDPMI32 binary missing: '$hdpmiSource'. See tools\thirdparty\hdpmi\SOURCE.txt."
    }
    if (-not (Test-Path -LiteralPath $dpmiProbeSource -PathType Leaf)) {
        throw "DPMI host probe missing: '$dpmiProbeSource'."
    }
    # Do not stage cwsdpmi.exe: the DJGPP GO32 stub auto-loads CWSDPMI.EXE by name
    # when no DPMI host is already resident. Omitting it forces use of resident HDPMI32.
    Copy-Item -LiteralPath $hdpmiSource -Destination (Join-Path $quakeRoot 'HDPMI32.EXE')
    Copy-Item -LiteralPath $dpmiProbeSource -Destination (Join-Path $quakeRoot 'DPMI.EXE')
    $dpmiHostPath = $hdpmiSource
    $extra = if ([string]::IsNullOrWhiteSpace($HdpmiExtraArgs)) { '' } else { ' ' + $HdpmiExtraArgs.Trim() }
    $hdpmiLoadLine = "HDPMI32 -r$extra"
    if (-not $SkipDpmiProbe) {
        $dpmiProbeLines = @(
            'if exist \quake\dpmihost.txt del \quake\dpmihost.txt'
            'DPMI.EXE > \quake\dpmihost.txt'
        )
    }
    if (-not [string]::IsNullOrWhiteSpace($HdpmiEnv)) {
        # Applied before HDPMI32 -r so the host sees the bits at install time.
        $hdpmiLoadLine = ("set {0}`r`n{1}" -f $HdpmiEnv.Trim(), $hdpmiLoadLine)
    }
}

$sha256Host = [Security.Cryptography.SHA256]::Create()
try {
    $dpmiHostSha256 = ([BitConverter]::ToString(
            $sha256Host.ComputeHash([IO.File]::ReadAllBytes($dpmiHostPath)))).Replace('-', '')
}
finally {
    $sha256Host.Dispose()
}

$batchPath = Join-Path $quakeRoot 'timedemo.bat'
$probeBlock = if ($dpmiProbeLines.Count) { ($dpmiProbeLines -join "`r`n") + "`r`n" } else { '' }
$loadBlock = if ($hdpmiLoadLine) { "$hdpmiLoadLine`r`n" } else { '' }
$quakeExtras = if ([string]::IsNullOrWhiteSpace($QuakeExtraArgs)) { '' } else { ' ' + $QuakeExtraArgs.Trim() }
@"
@echo off
cd \quake
$loadBlock$probeBlock$executableName -basedir \quake -timedemoexit$fpsStatsOptions -nosound -nojoy -nomouse -nocdaudio$quakeExtras +timedemo $DemoName
exit
"@ | Set-Content -LiteralPath $batchPath -Encoding ASCII

$profileText = Get-Content -LiteralPath $profilePath -Raw
$mountPath = $stagingRoot.Replace('"', '""')
$autoexec = (@"
[autoexec]
mount c "$mountPath"
c:
cd \quake
call timedemo.bat
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
$configPath = Join-Path $stagingRoot 'dosbox-x-timedemo.conf'
$runtimeConfig | Set-Content -LiteralPath $configPath -Encoding ASCII

function ConvertTo-ProcessArgument {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + $Value.Replace('"', '\"') + '"'
}

$sha256 = [Security.Cryptography.SHA256]::Create()
try {
	$profileHash = ([BitConverter]::ToString(
			$sha256.ComputeHash([IO.File]::ReadAllBytes($profilePath)))).Replace('-', '')
}
finally {
	$sha256.Dispose()
}
$culture = [Globalization.CultureInfo]::InvariantCulture
$results = @()

# The profile hash protects the file, not the numbers behind it. Compare it
# against the pinned constant so a changed DOSBox-X core or configuration cannot
# silently re-baseline the ledger -- see docs\ledger\2026-10-03-region-pricing-sweep.md,
# under "Correction: the general block row is minimal".
if ($profileHash -ne $ExpectedProfileSha256) {
    if (-not $AllowGateOverride) {
        throw ("DOSBox-X profile SHA-256 mismatch.`n  expected {0}`n  actual   {1}`n" +
            "The pinned 486 profile has changed, so its timings are not comparable to the recorded baseline. " +
            "Re-baseline deliberately with -AllowGateOverride, and record the new profile in BENCHMARK-COMPARISON.md.") -f `
            $ExpectedProfileSha256, $profileHash
    }
    Write-Warning "PROFILE GATE OVERRIDDEN: expected $ExpectedProfileSha256, got $($profileHash). Results are NOT comparable to the recorded baseline."
}

# Per-frame FPS collection adds two Sys_FloatTime reads per frame, worth about
# 0.0117 s over 969 frames (0.020%, roughly 39% of the 0.05% promotion gate).
# A run with it enabled is a valid diagnostic but not a valid promotion result.
if ($fpsStatsEnabled) {
    Write-Warning ("FPS STATS ENABLED: this run pays per-frame timer reads and is inflated by about 0.020% " +
        "relative to the recorded baseline. It is valid as a diagnostic, NOT as a promotion measurement. " +
        "Re-run without -FpsStats to compare against 59.227329 s.")
}

for ($run = 1; $run -le $Runs; $run++) {
    $reportPath = Join-Path $quakeRoot 'timedemo.txt'
    if (Test-Path -LiteralPath $reportPath) {
        Remove-Item -LiteralPath $reportPath -Force
    }
    $timedemoJsonPath = Join-Path $quakeRoot 'timedemo.jsn'
    if (Test-Path -LiteralPath $timedemoJsonPath) {
        Remove-Item -LiteralPath $timedemoJsonPath -Force
    }
    $profileJsonPath = Join-Path $quakeRoot 'profile.jsn'
    if (Test-Path -LiteralPath $profileJsonPath) {
        Remove-Item -LiteralPath $profileJsonPath -Force
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
        Write-Host "Launching DOSBox-X 486 timedemo run $run/$Runs"
        if (-not $process.Start()) {
            throw 'DOSBox-X failed to start.'
        }
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            throw "DOSBox-X timedemo exceeded $TimeoutSeconds seconds."
        }
        $dosboxExit = $process.ExitCode
    }
    finally {
        $process.Dispose()
    }

    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
        throw "DOSBox-X exited with code $dosboxExit but Quake did not produce '$reportPath'."
    }
    $report = Get-Content -LiteralPath $reportPath -Raw
    if ($dosboxExit -ne 0) {
        throw "DOSBox-X timedemo failed with exit code $dosboxExit."
    }

    $match = [regex]::Match($report,
        '(?<frames>\d+)\s+frames\s+(?<seconds>[0-9.]+)\s+seconds\s+(?<fps>[0-9.]+)\s+fps')
    if (-not $match.Success) {
        throw "Could not parse the timedemo report: $report"
    }

    $fpsStatsData = $null
    if (Test-Path -LiteralPath $timedemoJsonPath -PathType Leaf) {
        $fpsStatsData = Get-Content -LiteralPath $timedemoJsonPath -Raw | ConvertFrom-Json
    }

    $profileData = $null
    if ($Instrumentation) {
        if (-not (Test-Path -LiteralPath $profileJsonPath -PathType Leaf)) {
            throw "Instrumented Quake did not produce '$profileJsonPath'."
        }
        $profileData = Get-Content -LiteralPath $profileJsonPath -Raw | ConvertFrom-Json
    }

    $runFrames = [int]$match.Groups['frames'].Value
    $runSeconds = [double]::Parse($match.Groups['seconds'].Value, $culture)
    $runFps = [double]::Parse($match.Groups['fps'].Value, $culture)

    # A run that completed the wrong number of frames, or rendered a different
    # framebuffer, is not a timing result. Fail rather than report it.
    $checksumMatch = [regex]::Match($report, 'framebuffer-checksum\s+(?<checksum>\d+)')
    $runChecksum = if ($checksumMatch.Success) {
        [int64]$checksumMatch.Groups['checksum'].Value
    }
    else {
        $null
    }
    $gateFailures = @()
    if ($runFrames -ne $ExpectedFrames) {
        $gateFailures += "frames $runFrames != $ExpectedFrames"
    }
    if ($null -eq $runChecksum) {
        $gateFailures += 'framebuffer checksum absent from the report'
    }
    elseif ($runChecksum -ne $ExpectedChecksum) {
        $gateFailures += "framebuffer checksum $runChecksum != $ExpectedChecksum"
    }
    if ($gateFailures.Count -gt 0) {
        $detail = $gateFailures -join '; '
        if (-not $AllowGateOverride) {
            throw "Timedemo run $run failed the parity gate: $detail. This is not a valid timing result; fix the regression or re-baseline deliberately with -AllowGateOverride."
        }
        Write-Warning "PARITY GATE OVERRIDDEN on run ${run}: $detail. Results are NOT comparable to the recorded baseline."
    }

    $results += [ordered]@{
        run = $run
        frames = $runFrames
        seconds = $runSeconds
        fps = $runFps
        fpsStats = $fpsStatsData
        report = $report.Trim()
        profile = $profileData
    }
}

function Get-MedianNumber {
    param([object[]]$Values)

    $numbers = @($Values | ForEach-Object { [double]$_ } | Sort-Object)
    if ($numbers.Count -eq 0) {
        return $null
    }
    $middle = [int][math]::Floor($numbers.Count / 2)
    if (($numbers.Count % 2) -eq 1) {
        return $numbers[$middle]
    }
    return ($numbers[$middle - 1] + $numbers[$middle]) / 2.0
}

# The headline figure uses the same helper as the 30-odd FPS-summary fields below.
# It used to re-implement the median inline, which meant the one number a reader
# acts on and the same statistic in the summary block were computed by two
# separately-edited copies of the same rule.
$medianFps = Get-MedianNumber @($results | ForEach-Object { $_.fps })

$fpsStatsRuns = @($results | Where-Object { $null -ne $_.fpsStats })
$fpsSummary = $null
if ($fpsStatsRuns.Count -gt 0) {
    $firstFpsStats = $fpsStatsRuns[0].fpsStats
    $fpsSummary = [ordered]@{
        runs = $fpsStatsRuns.Count
        frames = [int]$firstFpsStats.benchmark.frames
        measuredFrames = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.measured_frames
        })
        storedFrames = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.stored_frames
        })
        overflowFrames = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.overflow_frames
        })
        invalidFrames = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.invalid_frames
        })
        timerReads = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.timer_reads
        })
        durationSeconds = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.benchmark.duration_seconds
        })
        averageFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.benchmark.average_fps
        })
        minimumFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.minimum_fps
        })
        maximumFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.maximum_fps
        })
        medianFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.median_fps
        })
        low1PercentFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.low_1_percent_fps
        })
        low0_1PercentFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.low_0_1_percent_fps
        })
        high1PercentFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.high_1_percent_fps
        })
        standardDeviationFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.standard_deviation_fps
        })
        varianceFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.fps.variance_fps
        })
        p0_1Fps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.percentiles.p0_1
        })
        p1Fps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.percentiles.p1
        })
        p5Fps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.percentiles.p5
        })
        p95Fps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.percentiles.p95
        })
        p99Fps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.percentiles.p99
        })
        p99_9Fps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.percentiles.p99_9
        })
        dropThresholdFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.events.drop_threshold_fps
        })
        spikeThresholdFps = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.events.spike_threshold_fps
        })
        drops = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.events.drops
        })
        spikes = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.events.spikes
        })
        longestDropRun = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.events.longest_drop_run
        })
        longestSpikeRun = Get-MedianNumber @($fpsStatsRuns | ForEach-Object {
            $_.fpsStats.events.longest_spike_run
        })
    }
}

$dpmiHostProbe = $null
$dpmiHostProbePath = Join-Path $quakeRoot 'dpmihost.txt'
if (Test-Path -LiteralPath $dpmiHostProbePath -PathType Leaf) {
    $dpmiHostProbe = (Get-Content -LiteralPath $dpmiHostProbePath -Raw).Trim()
}

$result = [ordered]@{
    demo = $DemoName
    runs = $Runs
    medianFps = $medianFps
    fpsSummary = $fpsSummary
    dosboxVersion = $toolManifest.dosboxX.version
    profile = $profilePath
    profileSha256 = $profileHash
    sourceFingerprint = $sourceFingerprint
    parityGate = [ordered]@{
        expectedProfileSha256 = $ExpectedProfileSha256
        expectedFrames = $ExpectedFrames
        expectedChecksum = $ExpectedChecksum
        enforced = (-not $AllowGateOverride)
    }
    executable = $benchmarkExe
    dpmiHost = $DpmiHost
    dpmiHostPath = $dpmiHostPath
    dpmiHostSha256 = $dpmiHostSha256
    hdpmiExtraArgs = if ($DpmiHost -eq 'hdpmi32') { $HdpmiExtraArgs } else { $null }
    hdpmiEnv = if ($DpmiHost -eq 'hdpmi32') { $HdpmiEnv } else { $null }
    quakeExtraArgs = $QuakeExtraArgs
    dpmiHostProbe = $dpmiHostProbe
    optimizationProfile = $OptimizationProfile
    textureAxisCacheEntries = $TextureAxisCacheEntries
    textureAxisImplementation = $TextureAxisImplementation
    surfaceCacheImplementation = $SurfaceCacheImplementation
    mipLevelImplementation = $MipLevelImplementation
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
    spanSetupProbe = $SpanSetupProbe
    renderFaceProbe = $RenderFaceProbe
    aliasGlueProbe = $AliasGlueProbe
    memoryImplementation = $MemoryImplementation
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
    instrumentation = [bool]$Instrumentation
    frameFpsStats = $fpsStatsEnabled
    dataRoot = $DataRoot
    stagingRoot = $stagingRoot
    results = $results
}
$resultPath = Join-Path $stagingRoot 'timedemo-result.json'
$result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $resultPath -Encoding ASCII

Write-Host ($results | ForEach-Object { $_.report })
Write-Host ("DPMI host: {0} ({1})" -f $DpmiHost, $dpmiHostSha256)
if ($null -ne $dpmiHostProbe -and $dpmiHostProbe.Length -gt 0) {
    Write-Host "DPMI probe:"
    Write-Host $dpmiHostProbe
}
Write-Host ("Median FPS: {0:N1}" -f $medianFps)
if ($null -ne $fpsSummary) {
    Write-Host ("FPS stats (median across {0} run(s)): avg {1:0.000000} min {2:0.000000} max {3:0.000000} median {4:0.000000} low1 {5:0.000000} low0.1 {6:0.000000} high1 {7:0.000000} stddev {8:0.000000} drops {9} spikes {10}" -f
        $fpsSummary.runs, $fpsSummary.averageFps, $fpsSummary.minimumFps,
        $fpsSummary.maximumFps, $fpsSummary.medianFps,
        $fpsSummary.low1PercentFps, $fpsSummary.low0_1PercentFps,
        $fpsSummary.high1PercentFps, $fpsSummary.standardDeviationFps,
        $fpsSummary.drops, $fpsSummary.spikes)
}
Write-Host "Timedemo result: $resultPath"

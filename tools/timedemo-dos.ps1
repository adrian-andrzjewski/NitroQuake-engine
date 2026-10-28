[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$Instrumentation,
    [switch]$NoBootstrap,
    [string]$ToolRoot,
    [string]$DataRoot,
    # Optional diagnostic profile template. Supplying this requires an explicit
    # ExpectedProfileSha256 so the altered emulator environment remains pinned.
    [string]$DosboxProfilePath,
    [string]$LocalOutputDirectoryName,
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
    [string]$SurfaceDrawImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SurfaceZGradientImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SurfaceGradientImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SurfaceDispatcherImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MipLevelImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MemoryImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$FillRectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$ZPointImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$SkySpanImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$WarpScreenImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SolidSurfaceImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$TurbulentScanImplementation = 'c',
    [ValidateSet('c', 'asm', 'stosb', 'pair', 'quad', 'octa', 'twelve', 'fourteen', 'fourteen-stosb')]
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
    [ValidateSet('control', 'local', 'asm')]
    [string]$AliasPrepareImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasClipImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasClipZImplementation = 'c',
    [ValidateSet('c', 'special', 'asm')]
    [string]$AliasMatrixCompositionImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasSetupLightingImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasSetupFrameImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasSetupSkinImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasGradientImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasLineScanImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasEdgeTableImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasSkinTableImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasRasterizeImplementation = 'asm',
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
    [string]$DynamicLightOrchestrationImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightPushImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$DlightContributesImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MarkLightsImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$LightMapBuildImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BspPlaneDotImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BspClipImplementation = 'c',
    [ValidateSet('control', 'local')]
    [string]$BspFrameCountImplementation = 'control',
    [ValidateSet('c', 'asm')]
    [string]$BspWalkImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParticleUpdateImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParticleDrawImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$DamageParseImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParticleExplosion2Implementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BlobExplosionImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$LavaSplashImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$TeleportSplashImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RocketTrailImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParticleExplosionImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParseParticleEffectImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RunParticleEffectImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$EntityParticlesImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteBeamImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteClipImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteFrameImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteGradientImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteScanLeftImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteScanRightImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteDrawImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteSetupImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteOrientationImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RenderMathImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AnimatedLightImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$PointLightImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$FrameControlImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$LineGraphImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$TimeGraphImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$PaletteImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MathClosureImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$VisibilityImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$PublicBindingsImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SkyImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RenderDispatchImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$DrawingDriverImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ViewControlImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$DrawingImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ConsoleImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenNotifyImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenCenterStringImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenEraseCenterStringImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenConsoleSetupImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenRefdefImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenDrawRamImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenOverlaysImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenUpdateImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenNetImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenTurtleImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ChaseImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$HullCheckImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [ValidateSet('c', 'asm')]
    [string]$HullForEntityImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ClipMoveToEntityImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ClipToLinksImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$FindTouchedLeafsImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$AliasControlImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasStatsImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$PrintTimesImplementation = 'c',
    [ValidateSet(
        'c', 'asm', 'asm-fixture',
        'rotation', 'efrags', 'edges',
        'rotation-efrags', 'rotation-edges', 'efrags-edges'
    )]
    [string]$WorldControlImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RenderWorldImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RenderFaceImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RenderBmodelFaceImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BmodelPolygonClipImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SolidClippedSubmodelPolygonsImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SubmodelPolygonsImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ZSubmodelPolygonsImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$TransformFrustumImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$TransformPlaneImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$EdgeDrawingImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScanEdgesImplementation = 'c',
    [ValidateSet('legacy', 'c', 'asm')]
    [string]$EdgeListMaintenanceImplementation = 'legacy',
    [ValidateSet('c', 'asm')]
    [string]$BackwardSpansImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$EfragStoreImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$EmitCachedEdgeImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RenderPolyImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$SbarPrimitiveImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$SbarDrawImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SbarInventoryImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$SbarFragsImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$PlayerTranslationImplementation = 'asm',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$CacheCheckImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$CacheAllocImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$CacheMoveImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$CacheFreeImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$CacheFreeHighImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$CacheFreeLowImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$CacheTryAllocImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$HunkMarkReleaseImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$HunkTempAllocImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$HunkNamedAllocImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$ZoneHeapImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VesaCopyRectsImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VesaSwapBuffersImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VgaPresentationImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VesaPaletteImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VesaDefaultModeImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VesaLifecycleImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VesaWaitImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VideoUpdateImplementation = 'c',
    [ValidateSet('control', 'skipzero')]
    [string]$GibTrailHorizontalIntegration = 'control',
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$DemoName = 'demo1',
    [ValidateRange(1, 9)]
    [int]$Runs = 3,
    [int]$TimeoutSeconds = 180,
    [switch]$VisualParityOnly,
    # Per-frame FPS collection adds timer-read overhead, so it is OFF by default
    # and opt-in. Keep promotion timing uninstrumented even though there is no
    # minimum gain threshold; the recorded baseline was measured with it off.
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
    # Deterministic Quake commands written to the isolated id1\autoexec.cfg.
    # This runs before Quake's automatic demo startup; use it for renderer cvars
    # rather than adding more '+' commands after the timedemo command.
    [string[]]$AutoexecCommands = @(),
    # JSON-encoded string array for callers that need to forward multiple lines
    # across a pwsh -File process boundary without positional-argument ambiguity.
    [string]$AutoexecCommandsJson = '',
    # Optional compact demo fixture configuration supplied by render validation.
    [string]$DemoFixtureJson = '',
    # Record one framebuffer checksum per rendered timedemo frame. This detects
    # temporal instability and synchronization regressions that a final-frame
    # checksum cannot see.
    [switch]$FrameChecksums,
    # Capture a PCX image at this zero-based timedemo frame. Requires
    # -FrameChecksums because the existing renderer hook records captures there.
    [ValidateRange(-1, 65535)]
    [int]$FrameCaptureIndex = -1,
    # When using hdpmi32, still run DPMI.EXE to record the resident host identity.
    [switch]$SkipDpmiProbe,
    #
    # Parity gates. These were previously recorded in the report but never
    # compared, so a changed emulator core or profile would silently re-baseline
    # every number in the ledger. They are now enforced; a mismatch fails the run.
    # Pass -AllowGateOverride to record a deliberate exception, which is logged.
    #
    # This constant is the hash of the profile with its line endings NORMALISED to
    # LF, not of the bytes on disk. See Get-TextFileHash below: hashing the working
    # copy made the promotion gate depend on the machine's git configuration.
    [string]$ExpectedProfileSha256 = '532284EA01C1A93C8B96D70FB538625B694DFAD0172BA13B9BA9C36C8FE845BA',
    [int]$ExpectedFrames = 969,
    [uint32]$ExpectedChecksum = 1047377823,
    [switch]$AllowGateOverride
)

. (Join-Path $PSScriptRoot 'timedemo-event-record.ps1')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'common.ps1')
Set-DefaultI486AssemblySelectors -CpuTarget $CpuTarget -BoundParameters $PSBoundParameters

function ConvertTo-DemoFixtureInteger {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][long]$Minimum,
        [Parameter(Mandatory = $true)][long]$Maximum
    )

    if ($Value -is [bool] -or $Value -isnot [System.ValueType]) {
        throw "demoFixture.$Name must be an integer JSON number."
    }
    try { $number = [decimal]$Value }
    catch { throw "demoFixture.$Name must be an integer JSON number." }
    if ($number -ne [decimal]::Truncate($number) -or $number -lt $Minimum -or $number -gt $Maximum) {
        throw "demoFixture.$Name must be an integer in [$Minimum, $Maximum]."
    }
    return [int]$number
}

function ConvertTo-DemoFixtureMemberName {
    param(
        [Parameter(Mandatory = $true)][AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) {
        throw "demoFixture.$Name must be a non-empty relative PACK member path."
    }
    $member = ([string]$Value).Replace('\', '/')
    if ($member -notmatch '^[A-Za-z0-9_./-]+$' -or $member.StartsWith('/') -or
        $member.Split('/') -contains '..' -or $member.Split('/') -contains '.' -or
        $member.Split('/') -contains '') {
        throw "demoFixture.$Name must be a safe relative PACK member path."
    }
    if ([Text.Encoding]::ASCII.GetByteCount($member) -gt 55) {
        throw "demoFixture.$Name must fit the 55-byte PACK name limit."
    }
    return $member
}

function ConvertFrom-DemoFixtureJson {
    param([string]$Json, [string]$RequestedDemoName)

    if ([string]::IsNullOrWhiteSpace($Json)) { return $null }
    if ($Json.Length -gt 4096 -or -not $Json.TrimStart().StartsWith('{')) {
        throw '-DemoFixtureJson must be a small JSON object.'
    }
    try { $parsed = ConvertFrom-Json -InputObject $Json -ErrorAction Stop }
    catch { throw "-DemoFixtureJson is invalid JSON: $($_.Exception.Message)" }
    if ($null -eq $parsed -or $parsed -is [array] -or $parsed -isnot [pscustomobject]) {
        throw '-DemoFixtureJson must contain one JSON object.'
    }

    $required = @(
        'sourceMember', 'firstPostSignonRecord', 'keepPostSignonRecords',
        'eventRecord', 'eventType', 'coordShorts', 'pakEntry'
    )
    $actual = @($parsed.PSObject.Properties | ForEach-Object { [string]$_.Name })
    $missing = @($required | Where-Object { $_ -notin $actual })
    $unknown = @($actual | Where-Object { $_ -notin $required })
    if ($missing.Count -gt 0 -or $unknown.Count -gt 0 -or $actual.Count -ne $required.Count) {
        throw ("-DemoFixtureJson fields must be exactly: {0}. Missing: [{1}]. Unknown: [{2}]." -f
            ($required -join ', '), ($missing -join ', '), ($unknown -join ', '))
    }

    $sourceMember = ConvertTo-DemoFixtureMemberName -Value $parsed.sourceMember -Name 'sourceMember'
    if (-not $sourceMember.EndsWith('.dem', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'demoFixture.sourceMember must end in .dem.'
    }
    $pakEntry = ConvertTo-DemoFixtureMemberName -Value $parsed.pakEntry -Name 'pakEntry'
    $expectedEntry = "$RequestedDemoName.dem"
    if (-not $pakEntry.Equals($expectedEntry, [StringComparison]::Ordinal) -or
        $pakEntry.Contains('/')) {
        throw "demoFixture.pakEntry must exactly match the case-sensitive root member '$expectedEntry' used by the timedemo command."
    }

    $firstRecord = ConvertTo-DemoFixtureInteger -Value $parsed.firstPostSignonRecord `
        -Name 'firstPostSignonRecord' -Minimum 0 -Maximum 1000000
    $keepRecords = ConvertTo-DemoFixtureInteger -Value $parsed.keepPostSignonRecords `
        -Name 'keepPostSignonRecords' -Minimum 1 -Maximum 65535
    $eventRecord = ConvertTo-DemoFixtureInteger -Value $parsed.eventRecord `
        -Name 'eventRecord' -Minimum 0 -Maximum 1000000
    $eventType = ConvertTo-DemoFixtureInteger -Value $parsed.eventType `
        -Name 'eventType' -Minimum 0 -Maximum 255
    if ($eventType -eq 18) {
        # svc_particle packet payload is fixed by make_blobexplosion_demo.py.
    }
    elseif ($eventType -notin @(4, 7, 10, 11, 19)) {
        throw 'demoFixture.eventType must be TE_TAREXPLOSION (4), TE_WIZSPIKE (7), TE_LAVASPLASH (10), TE_TELEPORT (11), svc_particle (18), or svc_damage (19).'
    }
    if ([long]$firstRecord + $keepRecords -gt 1000001 -or
        $eventRecord -lt $firstRecord -or $eventRecord -ge ([long]$firstRecord + $keepRecords)) {
        throw 'demoFixture.eventRecord must fall within the retained post-signon record prefix.'
    }

    if ($parsed.coordShorts -isnot [array] -or $parsed.coordShorts.Count -ne 3) {
        throw 'demoFixture.coordShorts must be an array of exactly three signed 16-bit integers.'
    }
    $coordShorts = @()
    for ($coordinate = 0; $coordinate -lt 3; $coordinate++) {
        $coordShorts += ConvertTo-DemoFixtureInteger -Value $parsed.coordShorts[$coordinate] `
            -Name "coordShorts[$coordinate]" -Minimum -32768 -Maximum 32767
    }

    return [pscustomobject]@{
        sourceMember = $sourceMember
        firstPostSignonRecord = $firstRecord
        keepPostSignonRecords = $keepRecords
        eventRecord = $eventRecord
        eventType = $eventType
        coordShorts = $coordShorts
        pakEntry = $pakEntry
    }
}

function Get-FullPathUnderDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $rootPath = [IO.Path]::GetFullPath($Directory)
    $separator = [string][IO.Path]::DirectorySeparatorChar
    if (-not $rootPath.EndsWith($separator)) {
        $rootPath += $separator
    }
    if (-not $fullPath.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label path '$fullPath' is outside '$Directory'."
    }
    return $fullPath
}

$demoFixtureConfig = ConvertFrom-DemoFixtureJson -Json $DemoFixtureJson -RequestedDemoName $DemoName
if ($null -ne $demoFixtureConfig -and $DemoName -ne [IO.Path]::GetFileNameWithoutExtension($demoFixtureConfig.pakEntry)) {
    throw 'demoFixture.pakEntry must match -DemoName.'
}

$ToolRoot = Resolve-ToolRoot -ToolRoot $ToolRoot
$DataRoot = Resolve-DataRoot -DataRoot $DataRoot -RepoRoot $repoRoot
if ($VisualParityOnly -and ($CpuTarget -ne 'i486' -or $DpmiHost -ne 'cwsdpmi')) {
    throw '-VisualParityOnly requires CpuTarget i486 and the independently audited cwsdpmi provider.'
}
if ($VisualParityOnly) {
    Write-Host 'VISUAL PARITY ONLY: renderer ISA audit is explicitly skipped; this run cannot prove 486 compatibility.' -ForegroundColor Yellow
}
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

$toolManifest = Read-ToolchainManifest -ToolsDirectory $PSScriptRoot
$buildParams = @{
    Benchmark                            = $true
    CpuTarget                            = $CpuTarget
    OptimizationProfile                  = $OptimizationProfile
    TextureAxisCacheEntries              = $TextureAxisCacheEntries
    TextureAxisImplementation            = $TextureAxisImplementation
    SurfaceCacheImplementation           = $SurfaceCacheImplementation
    SurfaceDrawImplementation            = $SurfaceDrawImplementation
    SurfaceZGradientImplementation       = $SurfaceZGradientImplementation
    SurfaceGradientImplementation        = $SurfaceGradientImplementation
    SurfaceDispatcherImplementation      = $SurfaceDispatcherImplementation
    MipLevelImplementation               = $MipLevelImplementation
    MemoryImplementation                 = $MemoryImplementation
    FillRectImplementation                = $FillRectImplementation
    ZPointImplementation                  = $ZPointImplementation
    SkySpanImplementation                 = $SkySpanImplementation
    WarpScreenImplementation               = $WarpScreenImplementation
    SolidSurfaceImplementation              = $SolidSurfaceImplementation
    TurbulentScanImplementation             = $TurbulentScanImplementation
    TurbulentImplementation              = $TurbulentImplementation
    TextureSpanStores                    = $TextureSpanStores
    TextureSpanTailStores                = $TextureSpanTailStores
    TextureSpanRowPath                   = $TextureSpanRowPath
    TextureSpanLoadOrder                 = $TextureSpanLoadOrder
    TextureSpanAddressing                = $TextureSpanAddressing
    AliasSpanAddressing                  = $AliasSpanAddressing
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
    AliasClipImplementation              = $AliasClipImplementation
    AliasClipZImplementation             = $AliasClipZImplementation
    AliasMatrixCompositionImplementation = $AliasMatrixCompositionImplementation
        AliasSetupLightingImplementation = $AliasSetupLightingImplementation
        AliasSetupFrameImplementation = $AliasSetupFrameImplementation
        AliasSetupSkinImplementation = $AliasSetupSkinImplementation
        AliasGradientImplementation = $AliasGradientImplementation
        AliasLineScanImplementation = $AliasLineScanImplementation
        AliasEdgeTableImplementation = $AliasEdgeTableImplementation
        AliasSkinTableImplementation = $AliasSkinTableImplementation
        AliasRasterizeImplementation = $AliasRasterizeImplementation
    TextureAnimationImplementation       = $TextureAnimationImplementation
    LightMapNormalizeImplementation      = $LightMapNormalizeImplementation
    LightMapStylesImplementation         = $LightMapStylesImplementation
    FusedLightMapImplementation          = $FusedLightMapImplementation
    DynamicLightImplementation           = $DynamicLightImplementation
    DynamicLightOrchestrationImplementation = $DynamicLightOrchestrationImplementation
    DynamicLightPushImplementation       = $DynamicLightPushImplementation
    DlightContributesImplementation      = $DlightContributesImplementation
    MarkLightsImplementation             = $MarkLightsImplementation
    LightMapBuildImplementation          = $LightMapBuildImplementation
    BspPlaneDotImplementation            = $BspPlaneDotImplementation
    BspClipImplementation                = $BspClipImplementation
    BspFrameCountImplementation          = $BspFrameCountImplementation
    BspWalkImplementation                = $BspWalkImplementation
    ParticleUpdateImplementation         = $ParticleUpdateImplementation
    ParticleDrawImplementation           = $ParticleDrawImplementation
    DamageParseImplementation            = $DamageParseImplementation
    ParticleExplosion2Implementation     = $ParticleExplosion2Implementation
    RunParticleEffectImplementation      = $RunParticleEffectImplementation
    EntityParticlesImplementation        = $EntityParticlesImplementation
    BlobExplosionImplementation          = $BlobExplosionImplementation
    LavaSplashImplementation             = $LavaSplashImplementation
    TeleportSplashImplementation         = $TeleportSplashImplementation
    RocketTrailImplementation            = $RocketTrailImplementation
    ParticleExplosionImplementation      = $ParticleExplosionImplementation
    SpriteBeamImplementation             = $SpriteBeamImplementation
    SpriteClipImplementation             = $SpriteClipImplementation
    SpriteFrameImplementation            = $SpriteFrameImplementation
    SpriteGradientImplementation         = $SpriteGradientImplementation
    SpriteScanLeftImplementation         = $SpriteScanLeftImplementation
    SpriteScanRightImplementation        = $SpriteScanRightImplementation
    SpriteDrawImplementation              = $SpriteDrawImplementation
    SpriteSetupImplementation              = $SpriteSetupImplementation
        RenderWorldImplementation            = $RenderWorldImplementation
        RenderFaceImplementation             = $RenderFaceImplementation
        RenderBmodelFaceImplementation       = $RenderBmodelFaceImplementation
        BmodelPolygonClipImplementation       = $BmodelPolygonClipImplementation
        SolidClippedSubmodelPolygonsImplementation = $SolidClippedSubmodelPolygonsImplementation
        SubmodelPolygonsImplementation       = $SubmodelPolygonsImplementation
        ZSubmodelPolygonsImplementation      = $ZSubmodelPolygonsImplementation
        TransformFrustumImplementation       = $TransformFrustumImplementation
        TransformPlaneImplementation         = $TransformPlaneImplementation
        LineGraphImplementation              = $LineGraphImplementation
        TimeGraphImplementation              = $TimeGraphImplementation
        AliasStatsImplementation             = $AliasStatsImplementation
        PrintTimesImplementation              = $PrintTimesImplementation
        EdgeDrawingImplementation             = $EdgeDrawingImplementation
        ScanEdgesImplementation               = $ScanEdgesImplementation
        EdgeListMaintenanceImplementation     = $EdgeListMaintenanceImplementation
        BackwardSpansImplementation            = $BackwardSpansImplementation
        EfragStoreImplementation              = $EfragStoreImplementation
        EmitCachedEdgeImplementation           = $EmitCachedEdgeImplementation
        RenderPolyImplementation              = $RenderPolyImplementation
        SbarPrimitiveImplementation           = $SbarPrimitiveImplementation
        SbarDrawImplementation                = $SbarDrawImplementation
        SbarInventoryImplementation            = $SbarInventoryImplementation
        SbarFragsImplementation                 = $SbarFragsImplementation
        PlayerTranslationImplementation         = $PlayerTranslationImplementation
        CacheCheckImplementation                 = $CacheCheckImplementation
        CacheAllocImplementation                 = $CacheAllocImplementation
        CacheMoveImplementation                  = $CacheMoveImplementation
        CacheFreeImplementation                  = $CacheFreeImplementation
        CacheFreeHighImplementation              = $CacheFreeHighImplementation
        CacheFreeLowImplementation               = $CacheFreeLowImplementation
        CacheTryAllocImplementation              = $CacheTryAllocImplementation
        HunkMarkReleaseImplementation            = $HunkMarkReleaseImplementation
        HunkTempAllocImplementation              = $HunkTempAllocImplementation
        HunkNamedAllocImplementation             = $HunkNamedAllocImplementation
        ZoneHeapImplementation                   = $ZoneHeapImplementation
        VesaCopyRectsImplementation              = $VesaCopyRectsImplementation
        VesaSwapBuffersImplementation             = $VesaSwapBuffersImplementation
        VgaPresentationImplementation             = $VgaPresentationImplementation
        VesaPaletteImplementation                 = $VesaPaletteImplementation
        VesaDefaultModeImplementation              = $VesaDefaultModeImplementation
        VesaLifecycleImplementation                = $VesaLifecycleImplementation
        VesaWaitImplementation                    = $VesaWaitImplementation
        VideoUpdateImplementation                 = $VideoUpdateImplementation
        GibTrailHorizontalIntegration       = $GibTrailHorizontalIntegration
    ToolRoot                             = $ToolRoot
}

$build = Join-Path $PSScriptRoot 'build-dos.ps1'
if (-not [string]::IsNullOrWhiteSpace($LocalOutputDirectoryName)) {
    $buildParams['LocalOutputDirectoryName'] = $LocalOutputDirectoryName
}

# Resolve the same executable variant that will be used for the run. If this is
# deferred until a stale-build rebuild, the earlier DumpFlags call points at
# qbench.exe while -Instrumentation actually builds qprof.exe.
if ($Instrumentation) {
    $buildParams['Instrumentation'] = $true
}

# Ask the builder where the output lands instead of recomputing the profile
# suffix here.  This runner used to carry its own copy of that arithmetic, and so
# did smoke-dos.ps1 and bench-dos.ps1; three copies of one rule is a standing
# invitation for a runner to look for an executable the builder never wrote.
# The builder is the only place that knows.
Add-RunnerBuildSelectors -BuildParameters $buildParams -Command $MyInvocation.MyCommand -SessionState $ExecutionContext.SessionState
$defaultResolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
if ($VisualParityOnly) {
    $buildParams['SkipIsaAudit'] = $true
    $profileDirectory = Split-Path -Leaf ([string]$defaultResolved.outputRoot)
    $visualOutputRoot = Join-Path $repoRoot (Join-Path 'out' ("visual-parity-" + $profileDirectory))
    $buildParams['DiagnosticOutputRoot'] = $visualOutputRoot
    $resolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
    if ([IO.Path]::GetFullPath($resolved.outputRoot) -ne [IO.Path]::GetFullPath($visualOutputRoot)) {
        throw "The builder did not honor the isolated visual parity output root '$visualOutputRoot'."
    }
    Write-Host "Visual parity build output: $($resolved.outputRoot)"
}
else {
    $resolved = $defaultResolved
}
$benchmarkExe = $resolved.executable

$dosbox = Resolve-DosboxExecutable -Manifest $toolManifest -ToolRoot $ToolRoot `
    -ToolsDirectory $PSScriptRoot -NoBootstrap:$NoBootstrap
# Still needed by name below: the parity gate hashes this file, and the result
# document records which profile produced the numbers.
if (-not [string]::IsNullOrWhiteSpace($DosboxProfilePath)) {
    if (-not $PSBoundParameters.ContainsKey('ExpectedProfileSha256')) {
        throw 'A custom DOSBox-X profile requires an explicit -ExpectedProfileSha256 pin.'
    }
    $profilePath = if ([IO.Path]::IsPathRooted($DosboxProfilePath)) {
        [IO.Path]::GetFullPath($DosboxProfilePath)
    }
    else {
        [IO.Path]::GetFullPath((Join-Path $repoRoot $DosboxProfilePath))
    }
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        throw "Custom DOSBox-X profile is missing: '$profilePath'."
    }
}
else {
    $profilePath = Get-DosboxProfilePath -ToolsDirectory $PSScriptRoot
}

# The staged executable name follows the builder's resolution too: -Benchmark
# gives qbench.exe and -Instrumentation gives qprof.exe, and duplicating that
# rule here is what let the two sides drift apart.
$executableName = [IO.Path]::GetFileName($resolved.executable)

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
# alternating runs. (common.ps1 is dot-sourced once, at the top.)
$sourceFingerprint = Get-BuildFingerprint -RepoRoot $repoRoot -Resolved $resolved
$sourceTreeFingerprint = Get-SourceTreeFingerprint -RepoRoot $repoRoot

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
$selectorVerification = Assert-RunnerBuildManifest -Resolved $resolved -BuildParameters $buildParams `
    -VisualParityOnly:$VisualParityOnly

$fpsStatsEnabled = [bool]($FpsStats -and -not $NoFpsStats)
$fpsStatsOptions = if ($fpsStatsEnabled) { ' -fpsstats' } else { '' }

$dpmiSuffix = if ($DpmiHost -eq 'cwsdpmi') { '' } else { '-hdpmi32' }
# The DPMI host is NOT staged here: this runner chooses between cwsdpmi and
# HDPMI32, and for HDPMI32 it must leave cwsdpmi.exe out so the DJGPP GO32 stub
# does not auto-load it. Its own block below stages the right one.
$staging = New-QuakeStaging -RepoRoot $repoRoot `
    -StagingRoot (Join-Path (Join-Path $repoRoot 'out') ('dos-timedemo' + $dpmiSuffix + '-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))) `
    -Executable $benchmarkExe -StagedExecutableName $executableName -DataRoot $DataRoot `
    -OnExistingStaging Throw
$stagingRoot = $staging.StagingRoot
$quakeRoot = $staging.QuakeRoot
$stagedData = $staging.StagedData
$demoFixtureResult = $null
if ($null -ne $demoFixtureConfig) {
    $stagedData = Get-FullPathUnderDirectory -Path $stagedData -Directory $stagingRoot -Label 'staged id1'
    $pak0Path = Get-FullPathUnderDirectory -Path (Join-Path $stagedData 'pak0.pak') `
        -Directory $stagedData -Label 'source pak0'
    if (-not (Test-Path -LiteralPath $pak0Path -PathType Leaf)) {
        throw "demoFixture requires staged pak0.pak at '$pak0Path'."
    }

    $pakIndices = @{}
    foreach ($pakFile in @(Get-ChildItem -LiteralPath $stagedData -Filter 'pak*.pak' -File)) {
        if ($pakFile.Name -match '^pak(?<index>\d+)\.pak$') {
            $pakIndex = [int]$Matches.index
            if ($pakIndices.ContainsKey($pakIndex)) {
                throw "Multiple staged PAK files resolve to index $pakIndex."
            }
            $pakIndices[$pakIndex] = $pakFile.FullName
        }
    }
    if (-not $pakIndices.ContainsKey(0)) {
        throw 'demoFixture requires staged pak0.pak at index zero.'
    }
    $presentPakIndices = @($pakIndices.Keys | ForEach-Object { [int]$_ } | Sort-Object)
    for ($expectedIndex = 0; $expectedIndex -lt $presentPakIndices.Count; $expectedIndex++) {
        if (-not $pakIndices.ContainsKey($expectedIndex)) {
            throw "Staged PAK indices are not contiguous; missing pak$expectedIndex.pak."
        }
    }
    $nextPakIndex = [int]$presentPakIndices[-1] + 1
    $overridePakPath = Get-FullPathUnderDirectory `
        -Path (Join-Path $stagedData ("pak{0}.pak" -f $nextPakIndex)) `
        -Directory $stagedData -Label 'fixture PAK override'
    if (Test-Path -LiteralPath $overridePakPath) {
        throw "Refusing to overwrite staged PAK '$overridePakPath'."
    }

    $fixtureWorkDirectory = Get-FullPathUnderDirectory `
        -Path (Join-Path $stagingRoot 'demo-fixture-temp') `
        -Directory $stagingRoot -Label 'temporary demo fixture directory'
    $fixtureDemPath = Get-FullPathUnderDirectory `
        -Path (Join-Path $fixtureWorkDirectory 'source-fixture.dem') `
        -Directory $fixtureWorkDirectory -Label 'temporary demo fixture'
    if (Test-Path -LiteralPath $fixtureWorkDirectory) {
        throw "Refusing to reuse temporary fixture directory '$fixtureWorkDirectory'."
    }
    $fixtureGeneratorPath = Join-Path $PSScriptRoot 'make_blobexplosion_demo.py'
    if (-not (Test-Path -LiteralPath $fixtureGeneratorPath -PathType Leaf)) {
        throw "demoFixture generator was not found at '$fixtureGeneratorPath'."
    }

    New-Item -ItemType Directory -Path $fixtureWorkDirectory | Out-Null
    $fixtureDemSha256 = $null
    $fixtureDemBytes = $null
    try {
        $fixtureGeneratorArgs = @(
            '-B', $fixtureGeneratorPath,
            '--pak0', $pak0Path,
            '--output', $fixtureDemPath,
            '--member', $demoFixtureConfig.sourceMember,
            '--first-post-signon-record', [string]$demoFixtureConfig.firstPostSignonRecord,
            '--keep-post-signon-records', [string]$demoFixtureConfig.keepPostSignonRecords,
            '--event-record', [string]$demoFixtureConfig.eventRecord,
            '--event-type', [string]$demoFixtureConfig.eventType,
            '--coord-shorts'
        )
        $fixtureGeneratorArgs += @($demoFixtureConfig.coordShorts | ForEach-Object { [string]$_ })
        $fixtureGeneratorArgs += @(
            '--pak-output', $overridePakPath,
            '--pak-entry', $demoFixtureConfig.pakEntry
        )
        & python @fixtureGeneratorArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Demo fixture generator exited with code $LASTEXITCODE."
        }
        if (-not (Test-Path -LiteralPath $fixtureDemPath -PathType Leaf) -or
            -not (Test-Path -LiteralPath $overridePakPath -PathType Leaf)) {
            throw 'Demo fixture generator did not produce both requested artifacts.'
        }
        $fixtureDemInfo = Get-Item -LiteralPath $fixtureDemPath
        $fixtureDemBytes = [int64]$fixtureDemInfo.Length
        $fixtureDemSha256 = (Get-FileHash -LiteralPath $fixtureDemPath -Algorithm SHA256).Hash
        $overridePakInfo = Get-Item -LiteralPath $overridePakPath
        $overridePakSha256 = (Get-FileHash -LiteralPath $overridePakPath -Algorithm SHA256).Hash
    }
    finally {
        if (Test-Path -LiteralPath $fixtureDemPath) {
            Remove-Item -LiteralPath $fixtureDemPath -Force
        }
        if (Test-Path -LiteralPath $fixtureWorkDirectory) {
            $remainingFixtureFiles = @(Get-ChildItem -LiteralPath $fixtureWorkDirectory -Force)
            if ($remainingFixtureFiles.Count -eq 0) {
                Remove-Item -LiteralPath $fixtureWorkDirectory -Force
            }
            else {
                throw "Temporary demo fixture cleanup left unexpected files in '$fixtureWorkDirectory'."
            }
        }
    }
    if (Test-Path -LiteralPath $fixtureDemPath) {
        throw "Temporary loose DEM still exists after fixture creation: '$fixtureDemPath'."
    }

    $demoFixtureResult = [ordered]@{
        parameters = [ordered]@{
            sourceMember = $demoFixtureConfig.sourceMember
            firstPostSignonRecord = $demoFixtureConfig.firstPostSignonRecord
            keepPostSignonRecords = $demoFixtureConfig.keepPostSignonRecords
            eventRecord = $demoFixtureConfig.eventRecord
            eventType = $demoFixtureConfig.eventType
            coordShorts = @($demoFixtureConfig.coordShorts)
            pakEntry = $demoFixtureConfig.pakEntry
        }
        overridePakIndex = $nextPakIndex
        overridePakPath = $overridePakPath
        overridePakBytes = [int64]$overridePakInfo.Length
        overridePakSha256 = $overridePakSha256
        temporaryDemoRemoved = $true
        temporaryDemoBytes = $fixtureDemBytes
        temporaryDemoSha256 = $fixtureDemSha256
    }
}

if (-not [string]::IsNullOrWhiteSpace($AutoexecCommandsJson)) {
    if (-not $AutoexecCommandsJson.TrimStart().StartsWith('[')) {
        throw '-AutoexecCommandsJson must contain a JSON array of command strings.'
    }
    try {
        $decodedAutoexecCommands = @(ConvertFrom-Json -InputObject $AutoexecCommandsJson -ErrorAction Stop)
    }
    catch {
        throw "-AutoexecCommandsJson must contain a JSON array of command strings: $($_.Exception.Message)"
    }
    if ($decodedAutoexecCommands.Count -eq 0) {
        throw '-AutoexecCommandsJson must contain a non-empty JSON array of command strings.'
    }
    foreach ($command in $decodedAutoexecCommands) {
        if ($command -isnot [string]) {
            throw '-AutoexecCommandsJson values must all be strings.'
        }
    }
    $AutoexecCommands = @($AutoexecCommands) + @($decodedAutoexecCommands)
}

if ($AutoexecCommands.Count -gt 0) {
    foreach ($command in $AutoexecCommands) {
        if ($command.Contains("`r") -or $command.Contains("`n")) {
            throw 'Each -AutoexecCommands value must be a single command line.'
        }
    }
    $autoexecPath = Join-Path $stagedData 'autoexec.cfg'
    $autoexecText = ($AutoexecCommands -join "`r`n") + "`r`n"
    [IO.File]::WriteAllText($autoexecPath, $autoexecText, [Text.Encoding]::ASCII)
}

$cwsdpmiSource = Join-Path $repoRoot 'src\cwsdpmi.exe'
$hdpmiDir = Join-Path $PSScriptRoot 'thirdparty\hdpmi'
$hdpmiSource = Join-Path $hdpmiDir 'HDPMI32.EXE'
$dpmiProbeSource = Join-Path $hdpmiDir 'DPMI.EXE'
$dpmiHostPath = $null
$dpmiHostSha256 = $null
$hdpmiLoadLine = ''
$dpmiProbeLines = @()

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

if ($FrameCaptureIndex -ge 0 -and -not $FrameChecksums) {
    throw '-FrameCaptureIndex requires -FrameChecksums.'
}
if (-not [string]::IsNullOrWhiteSpace($LocalOutputDirectoryName) -and $VisualParityOnly) {
    throw '-LocalOutputDirectoryName cannot be combined with -VisualParityOnly.'
}

$sha256Host = [Security.Cryptography.SHA256]::Create()
try {
    $dpmiHostSha256 = ([BitConverter]::ToString(
            $sha256Host.ComputeHash([IO.File]::ReadAllBytes($dpmiHostPath)))).Replace('-', '')
}
finally {
    $sha256Host.Dispose()
}
$providerProofPath = $null
if ($VisualParityOnly -and $selectorVerification.isaAuditStatus -eq 'SKIPPED') {
    $providerProofRoot = Join-Path $resolved.outputRoot 'provider-proof'
    $providerProofPath = Join-Path $providerProofRoot 'provider-proof.json'
    if (-not (Test-Path -LiteralPath $providerProofPath -PathType Leaf)) {
        if (Test-Path -LiteralPath $providerProofRoot) {
            throw "Incomplete provider proof output already exists at '$providerProofRoot'; remove that exact generated directory and retry."
        }
        $providerCompiler = Join-Path (Join-Path $ToolRoot $toolManifest.djgpp.installDirectory) `
            ($toolManifest.djgpp.compiler -replace '/', [IO.Path]::DirectorySeparatorChar)
        $providerProofArgs = @(
            (Join-Path $PSScriptRoot 'cws-provider-proof.py'),
            '--executable', $cwsdpmiSource,
            '--compiler', $providerCompiler,
            '--output', $providerProofRoot,
            '--tool-root', $ToolRoot
        )
        & python @providerProofArgs
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $providerProofPath -PathType Leaf)) {
            throw 'Independent DPMI-provider ISA proof failed during visual-only parity setup.'
        }
    }
}
$providerVerification = Assert-RunnerDpmiProvider -CpuTarget $CpuTarget -BuildVerification $selectorVerification `
    -ProviderPath (Join-Path $quakeRoot ([IO.Path]::GetFileName($dpmiHostPath))) `
    -VisualParityOnly:$VisualParityOnly -ProviderProofPath $providerProofPath

$batchPath = Join-Path $quakeRoot 'timedemo.bat'
$probeBlock = if ($dpmiProbeLines.Count) { ($dpmiProbeLines -join "`r`n") + "`r`n" } else { '' }
$loadBlock = if ($hdpmiLoadLine) { "$hdpmiLoadLine`r`n" } else { '' }
$quakeExtras = if ([string]::IsNullOrWhiteSpace($QuakeExtraArgs)) { '' } else { ' ' + $QuakeExtraArgs.Trim() }
$frameChecksumOptions = if ($FrameChecksums) { ' -framechecksums' } else { '' }
$frameCaptureOption = if ($FrameCaptureIndex -ge 0) { " -framecapture $FrameCaptureIndex" } else { '' }
$quakeCommandTail = "-timedemoexit$fpsStatsOptions$frameChecksumOptions$frameCaptureOption -nosound -nocdaudio$quakeExtras +timedemo $DemoName"
$quakeCommandLine = "$executableName $quakeCommandTail"
# DOS stores the argument tail in the PSP, including the separating space after
# the executable name. Validate those exact bytes before DOSBox starts.
$quakeCommandTailBytes = Assert-DosPspCommandTail -CommandTail (' ' + $quakeCommandTail)
# The executable name is excluded from the PSP tail. The batch changes to
# \quake, so -basedir \quake is redundant.
# Timedemo playback does not consume live mouse/joystick input; omitting those
# switches keeps event-enabled command tails within the DOS limit.
@"
@echo off
cd \quake
$loadBlock$probeBlock$quakeCommandLine
exit
"@ | Set-Content -LiteralPath $batchPath -Encoding ASCII

$configPath = New-DosboxRuntimeConfig -ProfileTemplate $profilePath `
    -StagingRoot $stagingRoot -BatchName 'timedemo.bat' -CpuTarget $CpuTarget -ConfigName 'dosbox-x-timedemo.conf'

$profileHash = Get-TextFileHash -Path $profilePath

$culture = [Globalization.CultureInfo]::InvariantCulture
$results = @()

# The profile hash protects the file's content, not its line endings and not the
# numbers behind it. Compare it against the pinned constant so a changed DOSBox-X
# core or configuration cannot silently re-baseline the ledger -- see
# docs\ledger\2026-10-03-region-pricing-sweep.md, under "Correction: the general
# block row is minimal". Get-TextFileHash normalises line endings first, so this
# gate no longer depends on the machine's git configuration.
if ($profileHash -ne $ExpectedProfileSha256) {
    if (-not $AllowGateOverride) {
        throw ("DOSBox-X profile SHA-256 mismatch.`n  expected {0}`n  actual   {1}`n" +
            "The pinned 486 profile has changed, so its timings are not comparable to the recorded baseline. " +
            "Re-baseline deliberately with -AllowGateOverride, and record the new profile in BENCHMARK-COMPARISON.md.") -f `
            $ExpectedProfileSha256, $profileHash
    }
    Write-Warning "PROFILE GATE OVERRIDDEN: expected $ExpectedProfileSha256, got $($profileHash). Results are NOT comparable to the recorded baseline."
}

# Per-frame FPS collection adds two Sys_FloatTime reads per frame. A run with
# it enabled is diagnostic only, not a promotion timing, because the collection
# changes runtime even when the candidate gain is small.
if ($fpsStatsEnabled) {
    Write-Warning ("FPS STATS ENABLED: this run pays per-frame timer reads and is inflated by about 0.020% " +
        "relative to an uninstrumented run. It is valid as a diagnostic, NOT as a promotion measurement. " +
        "Re-run without -FpsStats for a matched performance comparison.")
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
    $frameChecksumDosPath = Join-Path $quakeRoot 'FRAMECHE.TXT'
    if (Test-Path -LiteralPath $frameChecksumDosPath) {
        Remove-Item -LiteralPath $frameChecksumDosPath -Force
    }
    $frameCaptureDosPath = Join-Path $stagedData 'FRAME.PCX'
    if (Test-Path -LiteralPath $frameCaptureDosPath) {
        Remove-Item -LiteralPath $frameCaptureDosPath -Force
    }

    # The per-frame checksum file is written as the demo renders, so it doubles
    # as a lightweight live-progress stream for the parent runner. Without
    # -FrameChecksums, the final timedemo report is only created after playback.
    $progressFile = if ($FrameChecksums) { $frameChecksumDosPath } else { $null }
    $dosboxRun = Invoke-DosboxProcess -Dosbox $dosbox -ConfigPath $configPath `
        -TimeoutSeconds $TimeoutSeconds -Description "DOSBox-X 486 timedemo run $run/$Runs" `
        -ProgressFile $progressFile
    if ($dosboxRun.TimedOut) {
        throw "DOSBox-X timedemo exceeded $TimeoutSeconds seconds."
    }
    $dosboxExit = $dosboxRun.ExitCode

    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
        throw "DOSBox-X exited with code $dosboxExit but Quake did not produce '$reportPath'."
    }
    $report = Get-Content -LiteralPath $reportPath -Raw
    if ($dosboxExit -ne 0) {
        throw "DOSBox-X timedemo failed with exit code $dosboxExit."
    }

    # Keep old binaries usable by representing an absent event record as null.
    # The parser also verifies that stored frames plus overflow equals total count.
    $blobExplosionEventData = Read-Bench486BlobExplosionEvents -Report $report
    $lavaSplashEventData = Read-Bench486LavaSplashEvents -Report $report
    $teleportSplashEventData = Read-Bench486TeleportSplashEvents -Report $report
    $runParticleEffectEventData = Read-Bench486RunParticleEffectEvents -Report $report
    $entityParticlesEventData = Read-Bench486EntityParticlesEvents -Report $report
    $blobExplosionEventFrames = $blobExplosionEventData.Frames
    $blobExplosionEventOverflow = $blobExplosionEventData.Overflow
    $lavaSplashEventCount = $lavaSplashEventData.Count
    $lavaSplashEventFrames = $lavaSplashEventData.Frames
    $lavaSplashEventOverflow = $lavaSplashEventData.Overflow
    $teleportSplashEventCount = $teleportSplashEventData.Count
    $teleportSplashEventFrames = $teleportSplashEventData.Frames
    $teleportSplashEventOverflow = $teleportSplashEventData.Overflow
    $runParticleEffectEventCount = $runParticleEffectEventData.Count
    $runParticleEffectEventFrames = $runParticleEffectEventData.Frames
    $runParticleEffectEventOverflow = $runParticleEffectEventData.Overflow
    $entityParticlesEventCount = $entityParticlesEventData.Count
    $entityParticlesEventFrames = $entityParticlesEventData.Frames
    $entityParticlesEventOverflow = $entityParticlesEventData.Overflow
    $svcDamageEventData = Read-Bench486SvcDamageEvents -Report $report
    $svcDamageEventCount = $svcDamageEventData.Count
    $svcDamageEventFrames = $svcDamageEventData.Frames
    $svcDamageEventOverflow = $svcDamageEventData.Overflow

    $runDiagnostics = [ordered]@{
        blobExplosionEventFrames = $blobExplosionEventFrames
        blobExplosionEventOverflow = $blobExplosionEventOverflow
        lavaSplashEventCount = $lavaSplashEventCount
        lavaSplashEventFrames = $lavaSplashEventFrames
        lavaSplashEventOverflow = $lavaSplashEventOverflow
        teleportSplashEventCount = $teleportSplashEventCount
        teleportSplashEventFrames = $teleportSplashEventFrames
        teleportSplashEventOverflow = $teleportSplashEventOverflow
        runParticleEffectEventCount = $runParticleEffectEventCount
        runParticleEffectEventFrames = $runParticleEffectEventFrames
        runParticleEffectEventOverflow = $runParticleEffectEventOverflow
        entityParticlesEventCount = $entityParticlesEventCount
        entityParticlesEventFrames = $entityParticlesEventFrames
        entityParticlesEventOverflow = $entityParticlesEventOverflow
        svcDamageEventCount = $svcDamageEventCount
        svcDamageEventFrames = $svcDamageEventFrames
        svcDamageEventOverflow = $svcDamageEventOverflow
    }
    if ($FrameChecksums) {
        if (-not (Test-Path -LiteralPath $frameChecksumDosPath -PathType Leaf)) {
            throw "Timedemo did not produce per-frame checksums at '$frameChecksumDosPath'."
        }
        $checksumText = Get-Content -LiteralPath $frameChecksumDosPath -Raw
        $checksumSummary = [regex]::Match($checksumText, '(?m)^frames\s+(?<frames>\d+)\s+overflow\s+(?<overflow>\d+)\s*$')
        if (-not $checksumSummary.Success) {
            throw "Per-frame checksum output has no completion summary: '$frameChecksumDosPath'."
        }
        $checksumOverflow = [int]$checksumSummary.Groups['overflow'].Value
        if ($checksumOverflow -ne 0) {
            throw "Per-frame checksum output overflowed by $checksumOverflow frames; inspect '$frameChecksumDosPath'."
        }

        $runDiagnosticsRoot = Join-Path $stagingRoot ('runs\run-{0:D2}' -f $run)
        New-Item -ItemType Directory -Path $runDiagnosticsRoot -Force | Out-Null
        $runChecksumPath = Join-Path $runDiagnosticsRoot 'framechecksums.txt'
        Copy-Item -LiteralPath $frameChecksumDosPath -Destination $runChecksumPath -Force
        $runCapturePath = $null
        if ($FrameCaptureIndex -ge 0) {
            if (-not (Test-Path -LiteralPath $frameCaptureDosPath -PathType Leaf)) {
                throw "Timedemo did not produce the requested frame capture at '$frameCaptureDosPath'."
            }
            $runCapturePath = Join-Path $runDiagnosticsRoot 'frame.pcx'
            Copy-Item -LiteralPath $frameCaptureDosPath -Destination $runCapturePath -Force
        }
        $runDiagnostics['frameChecksumPath'] = $runChecksumPath
        $runDiagnostics['frameChecksumFrames'] = [int]$checksumSummary.Groups['frames'].Value
        $runDiagnostics['frameChecksumOverflow'] = $checksumOverflow
        $runDiagnostics['frameCapturePath'] = $runCapturePath
        $runDiagnostics['frameCaptureIndex'] = if ($FrameCaptureIndex -ge 0) { $FrameCaptureIndex } else { $null }
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
    if ($ExpectedFrames -gt 0 -and $runFrames -ne $ExpectedFrames) {
        $gateFailures += "frames $runFrames != $ExpectedFrames"
    }
    if ($null -eq $runChecksum) {
        $gateFailures += 'framebuffer checksum absent from the report'
    }
    elseif ($ExpectedChecksum -gt 0 -and $runChecksum -ne $ExpectedChecksum) {
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
        blobExplosionEventFrames = $blobExplosionEventFrames
        blobExplosionEventOverflow = $blobExplosionEventOverflow
        lavaSplashEventCount = $lavaSplashEventCount
        lavaSplashEventFrames = $lavaSplashEventFrames
        lavaSplashEventOverflow = $lavaSplashEventOverflow
        teleportSplashEventCount = $teleportSplashEventCount
        teleportSplashEventFrames = $teleportSplashEventFrames
        teleportSplashEventOverflow = $teleportSplashEventOverflow
        runParticleEffectEventCount = $runParticleEffectEventCount
        runParticleEffectEventFrames = $runParticleEffectEventFrames
        runParticleEffectEventOverflow = $runParticleEffectEventOverflow
        svcDamageEventCount = $svcDamageEventCount
        svcDamageEventFrames = $svcDamageEventFrames
        svcDamageEventOverflow = $svcDamageEventOverflow
        renderingDiagnostics = $runDiagnostics
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
    visualParityOnly = [bool]$VisualParityOnly
    isaAuditStatus = $selectorVerification.isaAuditStatus
    demo = $DemoName
    runs = $Runs
    medianFps = $medianFps
    fpsSummary = $fpsSummary
    dosboxVersion = $toolManifest.dosboxX.version
    profile = $profilePath
    profileSha256 = $profileHash
    customProfile = (-not [string]::IsNullOrWhiteSpace($DosboxProfilePath))
    sourceFingerprint = $sourceFingerprint
    sourceTreeFingerprint = $sourceTreeFingerprint
    parityGate = [ordered]@{
        expectedProfileSha256 = $ExpectedProfileSha256
        expectedFrames = $ExpectedFrames
        expectedChecksum = $ExpectedChecksum
        framesEnforced = ($ExpectedFrames -gt 0 -and -not $AllowGateOverride)
        checksumEnforced = ($ExpectedChecksum -gt 0 -and -not $AllowGateOverride)
        enforced = ((-not $AllowGateOverride) -and ($ExpectedFrames -gt 0 -or $ExpectedChecksum -gt 0))
    }
    executable = $benchmarkExe
    dpmiHost = $DpmiHost
    dpmiHostPath = $dpmiHostPath
    dpmiHostSha256 = $dpmiHostSha256
    hdpmiExtraArgs = if ($DpmiHost -eq 'hdpmi32') { $HdpmiExtraArgs } else { $null }
    hdpmiEnv = if ($DpmiHost -eq 'hdpmi32') { $HdpmiEnv } else { $null }
    quakeExtraArgs = $QuakeExtraArgs
    autoexecCommands = @($AutoexecCommands)
    frameChecksums = [bool]$FrameChecksums
    frameCaptureIndex = if ($FrameCaptureIndex -ge 0) { $FrameCaptureIndex } else { $null }
    dpmiHostProbe = $dpmiHostProbe
    optimizationProfile = $OptimizationProfile
    textureAxisCacheEntries = $TextureAxisCacheEntries
    textureAxisImplementation = $TextureAxisImplementation
    surfaceCacheImplementation = $SurfaceCacheImplementation
    surfaceDrawImplementation = $SurfaceDrawImplementation
    surfaceZGradientImplementation = $SurfaceZGradientImplementation
    surfaceGradientImplementation = $SurfaceGradientImplementation
    surfaceDispatcherImplementation = $SurfaceDispatcherImplementation
    mipLevelImplementation = $MipLevelImplementation
    turbulentImplementation = $TurbulentImplementation
    textureSpanStores = $TextureSpanStores
    textureSpanTailStores = $TextureSpanTailStores
    textureSpanRowPath = $TextureSpanRowPath
    textureSpanLoadOrder = $TextureSpanLoadOrder
    textureSpanAddressing = $TextureSpanAddressing
    aliasSpanAddressing = $AliasSpanAddressing
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
    fillRectImplementation = $FillRectImplementation
    zPointImplementation = $ZPointImplementation
    skySpanImplementation = $SkySpanImplementation
    warpScreenImplementation = $WarpScreenImplementation
    solidSurfaceImplementation = $SolidSurfaceImplementation
    turbulentScanImplementation = $TurbulentScanImplementation
    aliasProjectImplementation = $AliasProjectImplementation
    aliasBBoxProjectImplementation = $AliasBBoxProjectImplementation
    aliasTransformFinalImplementation = $AliasTransformFinalImplementation
    aliasPrepareImplementation = $AliasPrepareImplementation
    aliasClipImplementation = $AliasClipImplementation
    aliasClipZImplementation = $AliasClipZImplementation
    aliasMatrixCompositionImplementation = $AliasMatrixCompositionImplementation
    aliasSetupLightingImplementation = $AliasSetupLightingImplementation
    aliasSetupFrameImplementation = $AliasSetupFrameImplementation
    aliasSetupSkinImplementation = $AliasSetupSkinImplementation
    aliasGradientImplementation = $AliasGradientImplementation
    aliasLineScanImplementation = $AliasLineScanImplementation
    aliasEdgeTableImplementation = $AliasEdgeTableImplementation
    aliasSkinTableImplementation = $AliasSkinTableImplementation
    aliasRasterizeImplementation = $AliasRasterizeImplementation
    textureAnimationImplementation = $TextureAnimationImplementation
    lightMapNormalizeImplementation = $LightMapNormalizeImplementation
    lightMapStylesImplementation = $LightMapStylesImplementation
    fusedLightMapImplementation = $FusedLightMapImplementation
    dynamicLightImplementation = $DynamicLightImplementation
    dynamicLightOrchestrationImplementation = $DynamicLightOrchestrationImplementation
    dynamicLightPushImplementation = $DynamicLightPushImplementation
    dlightContributesImplementation = $DlightContributesImplementation
    markLightsImplementation = $MarkLightsImplementation
    lightMapBuildImplementation = $LightMapBuildImplementation
    bspPlaneDotImplementation = $BspPlaneDotImplementation
    bspClipImplementation = $BspClipImplementation
    bspFrameCountImplementation = $BspFrameCountImplementation
    bspWalkImplementation = $BspWalkImplementation
    particleUpdateImplementation = $ParticleUpdateImplementation
    particleDrawImplementation = $ParticleDrawImplementation
    damageParseImplementation = $DamageParseImplementation
    particleExplosion2Implementation = $ParticleExplosion2Implementation
    parseParticleEffectImplementation = $ParseParticleEffectImplementation
    blobExplosionImplementation = $BlobExplosionImplementation
    lavaSplashImplementation = $LavaSplashImplementation
    teleportSplashImplementation = $TeleportSplashImplementation
    rocketTrailImplementation = $RocketTrailImplementation
    particleExplosionImplementation = $ParticleExplosionImplementation
    runParticleEffectImplementation = $RunParticleEffectImplementation
    entityParticlesImplementation = $EntityParticlesImplementation
    spriteBeamImplementation = $SpriteBeamImplementation
    spriteClipImplementation = $SpriteClipImplementation
    spriteFrameImplementation = $SpriteFrameImplementation
    spriteGradientImplementation = $SpriteGradientImplementation
    spriteScanLeftImplementation = $SpriteScanLeftImplementation
    spriteScanRightImplementation = $SpriteScanRightImplementation
    spriteDrawImplementation = $SpriteDrawImplementation
    spriteSetupImplementation = $SpriteSetupImplementation
    spriteOrientationImplementation = $SpriteOrientationImplementation
    consoleImplementation = $ConsoleImplementation
    screenNotifyImplementation = $ScreenNotifyImplementation
    screenCenterStringImplementation = $ScreenCenterStringImplementation
    screenEraseCenterStringImplementation = $ScreenEraseCenterStringImplementation
    screenConsoleSetupImplementation = $ScreenConsoleSetupImplementation
    screenRefdefImplementation = $ScreenRefdefImplementation
    screenDrawRamImplementation = $ScreenDrawRamImplementation
    screenOverlaysImplementation = $ScreenOverlaysImplementation
    screenUpdateImplementation = $ScreenUpdateImplementation
    screenNetImplementation = $ScreenNetImplementation
    screenTurtleImplementation = $ScreenTurtleImplementation
    buildSelectorVerification = $selectorVerification
    chaseImplementation = $ChaseImplementation
    hullCheckImplementation = $HullCheckImplementation
    hullForEntityImplementation = $HullForEntityImplementation
    clipMoveToEntityImplementation = $ClipMoveToEntityImplementation
    clipToLinksImplementation = $ClipToLinksImplementation
    findTouchedLeafsImplementation = $FindTouchedLeafsImplementation
    aliasControlImplementation = $AliasControlImplementation
    aliasStatsImplementation = $AliasStatsImplementation
    printTimesImplementation = $PrintTimesImplementation
    worldControlImplementation = $WorldControlImplementation
    providerVerification = $providerVerification
    renderMathImplementation = $RenderMathImplementation
    animatedLightImplementation = $AnimatedLightImplementation
    pointLightImplementation = $PointLightImplementation
    frameControlImplementation = $FrameControlImplementation
    lineGraphImplementation = $LineGraphImplementation
    timeGraphImplementation = $TimeGraphImplementation
    paletteImplementation = $PaletteImplementation
    mathClosureImplementation = $MathClosureImplementation
    visibilityImplementation = $VisibilityImplementation
    publicBindingsImplementation = $PublicBindingsImplementation
    skyImplementation = $SkyImplementation
    renderWorldImplementation = $RenderWorldImplementation
    renderFaceImplementation = $RenderFaceImplementation
    renderBmodelFaceImplementation = $RenderBmodelFaceImplementation
    bmodelPolygonClipImplementation = $BmodelPolygonClipImplementation
    solidClippedSubmodelPolygonsImplementation = $SolidClippedSubmodelPolygonsImplementation
    submodelPolygonsImplementation = $SubmodelPolygonsImplementation
    zSubmodelPolygonsImplementation = $ZSubmodelPolygonsImplementation
    transformFrustumImplementation = $TransformFrustumImplementation
    transformPlaneImplementation = $TransformPlaneImplementation
    edgeDrawingImplementation = $EdgeDrawingImplementation
    scanEdgesImplementation = $ScanEdgesImplementation
    edgeListMaintenanceImplementation = $EdgeListMaintenanceImplementation
    backwardSpansImplementation = $BackwardSpansImplementation
    efragStoreImplementation = $EfragStoreImplementation
    emitCachedEdgeImplementation = $EmitCachedEdgeImplementation
    renderPolyImplementation = $RenderPolyImplementation
    sbarPrimitiveImplementation = $SbarPrimitiveImplementation
    sbarDrawImplementation = $SbarDrawImplementation
    sbarInventoryImplementation = $SbarInventoryImplementation
    sbarFragsImplementation = $SbarFragsImplementation
    playerTranslationImplementation = $PlayerTranslationImplementation
    cacheCheckImplementation = $CacheCheckImplementation
    cacheAllocImplementation = $CacheAllocImplementation
    cacheMoveImplementation = $CacheMoveImplementation
    cacheFreeImplementation = $CacheFreeImplementation
    cacheFreeHighImplementation = $CacheFreeHighImplementation
    cacheFreeLowImplementation = $CacheFreeLowImplementation
    cacheTryAllocImplementation = $CacheTryAllocImplementation
    hunkMarkReleaseImplementation = $HunkMarkReleaseImplementation
    hunkTempAllocImplementation = $HunkTempAllocImplementation
    hunkNamedAllocImplementation = $HunkNamedAllocImplementation
    zoneHeapImplementation = $ZoneHeapImplementation
    vesaCopyRectsImplementation = $VesaCopyRectsImplementation
    vesaSwapBuffersImplementation = $VesaSwapBuffersImplementation
    vgaPresentationImplementation = $VgaPresentationImplementation
    vesaPaletteImplementation = $VesaPaletteImplementation
    vesaDefaultModeImplementation = $VesaDefaultModeImplementation
    vesaLifecycleImplementation = $VesaLifecycleImplementation
    vesaWaitImplementation = $VesaWaitImplementation
    videoUpdateImplementation = $VideoUpdateImplementation
    gibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
    instrumentation = [bool]$Instrumentation
    frameFpsStats = $fpsStatsEnabled
    dataRoot = $DataRoot
    stagingRoot = $stagingRoot
    results = $results
}
if ($null -ne $demoFixtureResult) {
    $result['demoFixture'] = $demoFixtureResult
}
$resultPath = Join-Path $stagingRoot 'timedemo-result.json'
$result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $resultPath -Encoding ASCII

Write-Host ($results | ForEach-Object { $_.report })
Write-Host ("Timedemo result: {0}" -f $resultPath)
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

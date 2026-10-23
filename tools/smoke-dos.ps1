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
    [string]$TurbulentScanImplementation = 'c',
    [ValidateSet('control', 'local', 'asm')]
    [string]$AliasPrepareImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasClipImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasClipZImplementation = 'c',
    # 'asm' to match build-dos.ps1, bench-dos.ps1 and timedemo-dos.ps1.  This
    # used to be 'c', and because this runner computed the profile suffix itself
    # it then looked for out\dos-memasm-...-fusedlightmapasm\quake.exe while the
    # release build lives in out\dos-memasm-...-fusedlightmapasm-dlightasm\.
    # So `smoke-dos.ps1 -SkipBuild` was not testing the release binary at all.
    # The runner now asks the builder for its output path, which is what made the
    # divergence visible.
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightOrchestrationImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$DynamicLightPushImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MarkLightsImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteFrameImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteDrawImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteSetupImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$DlightContributesImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$LightMapBuildImplementation = 'c',
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
    [ValidateSet('c', 'asm')]
    [string]$BspWalkImplementation = 'c',
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
    [string]$ZSubmodelPolygonsImplementation = 'c',
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
    [string]$RenderPolyImplementation = 'c',
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
    [ValidateSet('control', 'skipzero')]
    [string]$GibTrailHorizontalIntegration = 'control',
    [ValidateSet(64, 128, 256)]
    [int]$TextureAxisCacheEntries = 256,
    [ValidateSet('c', 'asm')]
    [string]$TextureAxisImplementation = 'c',
    [ValidateSet('c', 'asm', 'stosb', 'octa', 'twelve', 'fourteen')]
    [string]$TurbulentImplementation = 'stosb',
    [ValidateSet('control', 'word')]
    [string]$TextureSpanTailStores = 'control',
    [ValidateSet('control', 'norowcross')]
    [string]$TextureSpanRowPath = 'control',
    [string]$AliasProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasBBoxProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasTransformFinalImplementation = 'asm',
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
    [string]$LightMapNormalizeImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$LightMapStylesImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$FusedLightMapImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$BspPlaneDotImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BspClipImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParticleUpdateImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParseParticleEffectImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RunParticleEffectImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$EntityParticlesImplementation = 'c',
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
    [string]$SpriteBeamImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteClipImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteGradientImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteScanLeftImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteScanRightImplementation = 'c',
    [int]$TimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'common.ps1')
Set-DefaultI486AssemblySelectors -CpuTarget $CpuTarget -BoundParameters $PSBoundParameters
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
    FillRectImplementation = $FillRectImplementation
    ZPointImplementation = $ZPointImplementation
    SurfaceCacheImplementation = $SurfaceCacheImplementation
    SurfaceDrawImplementation = $SurfaceDrawImplementation
    SurfaceZGradientImplementation = $SurfaceZGradientImplementation
    SurfaceGradientImplementation = $SurfaceGradientImplementation
    SurfaceDispatcherImplementation = $SurfaceDispatcherImplementation
    MipLevelImplementation = $MipLevelImplementation
    AliasLineScanImplementation = $AliasLineScanImplementation
    AliasEdgeTableImplementation = $AliasEdgeTableImplementation
    AliasSkinTableImplementation = $AliasSkinTableImplementation
    AliasRasterizeImplementation = $AliasRasterizeImplementation
    TextureAnimationImplementation = $TextureAnimationImplementation
    SkySpanImplementation = $SkySpanImplementation
    WarpScreenImplementation = $WarpScreenImplementation
    SolidSurfaceImplementation = $SolidSurfaceImplementation
    TurbulentScanImplementation = $TurbulentScanImplementation
    AliasPrepareImplementation = $AliasPrepareImplementation
    AliasClipImplementation = $AliasClipImplementation
    AliasClipZImplementation = $AliasClipZImplementation
    DynamicLightImplementation = $DynamicLightImplementation
    DynamicLightOrchestrationImplementation = $DynamicLightOrchestrationImplementation
    DynamicLightPushImplementation = $DynamicLightPushImplementation
    DlightContributesImplementation = $DlightContributesImplementation
    LightMapBuildImplementation = $LightMapBuildImplementation
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
    BspWalkImplementation = $BspWalkImplementation
    RenderWorldImplementation = $RenderWorldImplementation
    SpriteOrientationImplementation = $SpriteOrientationImplementation
    RenderMathImplementation = $RenderMathImplementation
    AnimatedLightImplementation = $AnimatedLightImplementation
    PointLightImplementation = $PointLightImplementation
    FrameControlImplementation = $FrameControlImplementation
    LineGraphImplementation = $LineGraphImplementation
    TimeGraphImplementation = $TimeGraphImplementation
    AliasStatsImplementation = $AliasStatsImplementation
    PrintTimesImplementation = $PrintTimesImplementation
    ParticleExplosion2Implementation = $ParticleExplosion2Implementation
    BlobExplosionImplementation = $BlobExplosionImplementation
    RocketTrailImplementation = $RocketTrailImplementation
    ParticleExplosionImplementation = $ParticleExplosionImplementation
    PaletteImplementation = $PaletteImplementation
    MathClosureImplementation = $MathClosureImplementation
    VisibilityImplementation = $VisibilityImplementation
    PublicBindingsImplementation = $PublicBindingsImplementation
    SkyImplementation = $SkyImplementation
    RenderFaceImplementation = $RenderFaceImplementation
    RenderBmodelFaceImplementation = $RenderBmodelFaceImplementation
    BmodelPolygonClipImplementation = $BmodelPolygonClipImplementation
    SolidClippedSubmodelPolygonsImplementation = $SolidClippedSubmodelPolygonsImplementation
    SubmodelPolygonsImplementation = $SubmodelPolygonsImplementation
    ZSubmodelPolygonsImplementation = $ZSubmodelPolygonsImplementation
    TransformFrustumImplementation = $TransformFrustumImplementation
    TransformPlaneImplementation = $TransformPlaneImplementation
    EdgeDrawingImplementation = $EdgeDrawingImplementation
    ScanEdgesImplementation = $ScanEdgesImplementation
    EdgeListMaintenanceImplementation = $EdgeListMaintenanceImplementation
    BackwardSpansImplementation = $BackwardSpansImplementation
    EfragStoreImplementation = $EfragStoreImplementation
    EmitCachedEdgeImplementation = $EmitCachedEdgeImplementation
    RenderPolyImplementation = $RenderPolyImplementation
    SbarPrimitiveImplementation = $SbarPrimitiveImplementation
    SbarDrawImplementation = $SbarDrawImplementation
    SbarInventoryImplementation = $SbarInventoryImplementation
    SbarFragsImplementation = $SbarFragsImplementation
    PlayerTranslationImplementation = $PlayerTranslationImplementation
    CacheCheckImplementation = $CacheCheckImplementation
    CacheAllocImplementation = $CacheAllocImplementation
    CacheMoveImplementation = $CacheMoveImplementation
    CacheFreeImplementation = $CacheFreeImplementation
    CacheFreeHighImplementation = $CacheFreeHighImplementation
    CacheFreeLowImplementation = $CacheFreeLowImplementation
    CacheTryAllocImplementation = $CacheTryAllocImplementation
    HunkMarkReleaseImplementation = $HunkMarkReleaseImplementation
    HunkTempAllocImplementation = $HunkTempAllocImplementation
    HunkNamedAllocImplementation = $HunkNamedAllocImplementation
    ZoneHeapImplementation = $ZoneHeapImplementation
    VesaCopyRectsImplementation = $VesaCopyRectsImplementation
    VesaSwapBuffersImplementation = $VesaSwapBuffersImplementation
    VgaPresentationImplementation = $VgaPresentationImplementation
    VesaPaletteImplementation = $VesaPaletteImplementation
    VesaDefaultModeImplementation = $VesaDefaultModeImplementation
    VesaLifecycleImplementation = $VesaLifecycleImplementation
    VesaWaitImplementation = $VesaWaitImplementation
    GibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
}

# Ask the builder where the output lands instead of recomputing the profile
# suffix here.  This runner used to carry its own copy of that arithmetic, and
# so did bench-dos.ps1 and timedemo-dos.ps1; three copies of one rule is a
# standing invitation for a runner to look for an executable the builder never
# wrote.  The builder is the only place that knows.
Add-RunnerBuildSelectors -BuildParameters $buildParams -Command $MyInvocation.MyCommand -SessionState $ExecutionContext.SessionState
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
$selectorVerification = Assert-RunnerBuildManifest -Resolved $resolved -BuildParameters $buildParams

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
$providerVerification = Assert-RunnerDpmiProvider -CpuTarget $CpuTarget -BuildVerification $selectorVerification `
    -ProviderPath (Join-Path $quakeRoot 'cwsdpmi.exe')

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
    dynamicLightOrchestrationImplementation = $DynamicLightOrchestrationImplementation
    dynamicLightPushImplementation = $DynamicLightPushImplementation
    dlightContributesImplementation = $DlightContributesImplementation
    surfaceCacheImplementation = $SurfaceCacheImplementation
    surfaceDrawImplementation = $SurfaceDrawImplementation
    surfaceZGradientImplementation = $SurfaceZGradientImplementation
    surfaceGradientImplementation = $SurfaceGradientImplementation
    surfaceDispatcherImplementation = $SurfaceDispatcherImplementation
    mipLevelImplementation = $MipLevelImplementation
    aliasLineScanImplementation = $AliasLineScanImplementation
    aliasEdgeTableImplementation = $AliasEdgeTableImplementation
    aliasSkinTableImplementation = $AliasSkinTableImplementation
    aliasRasterizeImplementation = $AliasRasterizeImplementation
    textureAnimationImplementation = $TextureAnimationImplementation
    lightMapBuildImplementation = $LightMapBuildImplementation
    textureSpanStores = $TextureSpanStores
    aliasPrepareImplementation = $AliasPrepareImplementation
    aliasClipImplementation = $AliasClipImplementation
    aliasClipZImplementation = $AliasClipZImplementation
    textureSpanLoadOrder = $TextureSpanLoadOrder
    textureSpanAddressing = $TextureSpanAddressing
    aliasSpanAddressing = $AliasSpanAddressing
    surfaceBlockMip0Rows = $SurfaceBlockMip0Rows
    surfaceBlockMip0HorizontalFlat = $SurfaceBlockMip0HorizontalFlat
    surfaceBlockMip1Rows = $SurfaceBlockMip1Rows
    bspFrameCountImplementation = $BspFrameCountImplementation
    bspWalkImplementation = $BspWalkImplementation
    renderWorldImplementation = $RenderWorldImplementation
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
    particleExplosion2Implementation = $ParticleExplosion2Implementation
    blobExplosionImplementation = $BlobExplosionImplementation
    lavaSplashImplementation = $LavaSplashImplementation
    teleportSplashImplementation = $TeleportSplashImplementation
    rocketTrailImplementation = $RocketTrailImplementation
    particleExplosionImplementation = $ParticleExplosionImplementation
    parseParticleEffectImplementation = $ParseParticleEffectImplementation
    runParticleEffectImplementation = $RunParticleEffectImplementation
    entityParticlesImplementation = $EntityParticlesImplementation
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
    surfaceBlockMip1HorizontalFlat = $SurfaceBlockMip1HorizontalFlat
    surfaceBlockMip1IndexHoist = $SurfaceBlockMip1IndexHoist
    edgeScanProbe = $EdgeScanProbe
    gibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
    timeoutSeconds = $TimeoutSeconds
}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stagingRoot 'smoke-result.json') -Encoding ASCII
Write-Host 'DOS smoke test passed.'

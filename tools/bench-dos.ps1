[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$Instrumentation,
    [switch]$NoBootstrap,
    # This bypass is for diagnostic experiments only. All normal C and assembly
    # profiles are expected to pass the selected target's ISA audit.
    [switch]$SkipIsaAudit,
    [string]$ToolRoot,
    [string]$DataRoot,
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
    [ValidateSet('c', 'asm', 'stosb')]
    [string]$TurbulentImplementation = 'stosb',
    [ValidateSet('c', 'asm')]
    [string]$TurbulentScanImplementation = 'c',
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
    [string]$ParticleUpdateImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParticleDrawImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$DamageParseImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParticleExplosionImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ParseParticleEffectImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$RunParticleEffectImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$EntityParticlesImplementation = 'c',
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
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$SbarDrawImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SbarInventoryImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$SbarFragsImplementation = 'c',
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
    [string]$VesaCopyRectsImplementation = 'c',
    [ValidateSet('c', 'asm', 'asm-fixture')]
    [string]$VesaSwapBuffersImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasStatsImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$PrintTimesImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$WorldControlImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SpriteDrawImplementation = 'c',
    [ValidateSet('control', 'skipzero')]
    [string]$GibTrailHorizontalIntegration = 'control',
    [switch]$MemoryOnly,
    [switch]$FillRectOnly,
    [switch]$ZPointOnly,
    [switch]$ZSpansOnly,
    [switch]$SkySpanOnly,
    [switch]$WarpScreenOnly,
    [switch]$SolidSurfaceOnly,
    [switch]$TurbulentOnly,
    [switch]$TurbulentScanOnly,
    [switch]$AliasProjectOnly,
    [switch]$AliasBBoxProjectOnly,
    [switch]$AliasTransformFinalOnly,
    [switch]$AliasSetupLightingOnly,
    [switch]$AliasSetupFrameOnly,
    [switch]$AliasSetupSkinOnly,
    [switch]$AliasGradientsOnly,
    [switch]$AliasLineScanOnly,
    [switch]$AliasEdgeTableOnly,
    [switch]$AliasSkinTableOnly,
    [switch]$SpriteBeamOnly,
    [switch]$SpriteClipOnly,
    [switch]$SpriteFrameOnly,
    [switch]$SpriteGradientOnly,
    [switch]$SpriteScanLeftOnly,
    [switch]$SpriteScanRightOnly,
    [switch]$SpriteDrawOnly,
    [switch]$SpriteSetupOnly,
    [switch]$SpriteOrientationOnly,
    [switch]$LightControlOnly,
    [switch]$FrameControlOnly,
    [switch]$LineGraphOnly,
    [switch]$TimeGraphOnly,
    [switch]$PaletteOnly,
    [switch]$MathClosureOnly,
    [switch]$VisibilityOnly,
    [switch]$PublicBindingsOnly,
    [switch]$SkyOnly,
    [switch]$RenderDispatchOnly,
    [switch]$DrawingDriverOnly,
    [switch]$ViewControlOnly,
    [switch]$ConsoleInputOnly,
    [switch]$ScreenNotifyOnly,
    [switch]$ScreenCenterStringOnly,
    [switch]$ScreenEraseCenterStringOnly,
    [switch]$ScreenConsoleSetupOnly,
    [switch]$ScreenRefdefOnly,
    [switch]$ScreenDrawRamOnly,
    [switch]$ScreenOverlaysOnly,
    [switch]$ScreenUpdateOnly,
    [switch]$ScreenNetOnly,
    [switch]$ScreenTurtleOnly,
    [switch]$DrawingOnly,
    [switch]$SbarPrimitivesOnly,
    [switch]$SbarInventoryOnly,
    [switch]$SbarFragsOnly,
    [switch]$CacheCheckOnly,
    [switch]$CacheAllocOnly,
    [switch]$CacheMoveOnly,
    [switch]$CacheFreeOnly,
    [switch]$CacheFreeHighOnly,
    [switch]$CacheFreeLowOnly,
    [switch]$CacheTryAllocOnly,
    [switch]$HunkMarkReleaseOnly,
    [switch]$HunkTempAllocOnly,
    [switch]$HunkNamedAllocOnly,
    [switch]$VesaCopyRectsOnly,
    [switch]$VesaSwapBuffersOnly,
    [switch]$ChaseOnly,
    [switch]$HullCheckOnly,
    [switch]$AliasControlOnly,
    [switch]$AliasModelLoadOnly,
    [switch]$SbarDrawOnly,
    [switch]$AliasStatsOnly,
    [switch]$PrintTimesOnly,
    [switch]$WorldControlOnly,
    [switch]$EfragStoreOnly,
    [switch]$MipLevelOnly,
    [switch]$TextureAnimationOnly,
    [switch]$LightMapNormalizeOnly,
    [switch]$LightMapStylesOnly,
    [switch]$FusedLightMapOnly,
    [switch]$LightMapBuildOnly,
    [switch]$SurfaceCacheOnly,
    [switch]$ParticleListOnly,
    [switch]$ParticleDrawOnly,
    [switch]$ParticleUpdateOnly,
    [switch]$DamageParseOnly,
    [switch]$ParticleExplosionOnly,
    [switch]$ParseParticleEffectOnly,
    [switch]$ForwardSpansOnly,
    [switch]$RunParticleEffectOnly,
    [switch]$EntityParticlesOnly,
    [switch]$ParticleExplosion2Only,
    [switch]$BlobExplosionOnly,
    [switch]$LavaSplashOnly,
    [switch]$TeleportSplashOnly,
    [switch]$RocketTrailOnly,
    [switch]$ZSubmodelPolygonsOnly,
    [switch]$FrustumTransformOnly,
    [switch]$TransformPlaneOnly,
    [switch]$SurfaceDrawOnly,
    [switch]$SurfaceZGradientOnly,
    [switch]$SurfaceGradientOnly,
    [switch]$BspPlaneDotOnly,
    [switch]$BspClipOnly,
    [int]$TimeoutSeconds = 600
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'common.ps1')
Set-DefaultI486AssemblySelectors -CpuTarget $CpuTarget -BoundParameters $PSBoundParameters
$ToolRoot = Resolve-ToolRoot -ToolRoot $ToolRoot
$DataRoot = Resolve-DataRoot -DataRoot $DataRoot -RepoRoot $repoRoot
if ($TimeoutSeconds -lt 10) {
    throw 'TimeoutSeconds must be at least 10 seconds.'
}
if ($AliasModelLoadOnly -and $AliasControlImplementation -ne 'asm-fixture') {
    throw '-AliasModelLoadOnly requires -AliasControlImplementation asm-fixture.'
}
if ($SbarDrawOnly -and $SbarDrawImplementation -ne 'asm-fixture') {
    throw '-SbarDrawOnly requires -SbarDrawImplementation asm-fixture.'
}
if ($SbarInventoryOnly -and $SbarInventoryImplementation -ne 'asm') {
    throw '-SbarInventoryOnly requires -SbarInventoryImplementation asm.'
}
if ($SbarFragsOnly -and $SbarFragsImplementation -ne 'asm-fixture') {
    throw '-SbarFragsOnly requires -SbarFragsImplementation asm-fixture.'
}
if ($CacheCheckOnly -and $CacheCheckImplementation -ne 'asm-fixture') {
    throw '-CacheCheckOnly requires -CacheCheckImplementation asm-fixture.'
}
if ($CacheFreeOnly -and $CacheFreeImplementation -ne 'asm-fixture') {
    throw '-CacheFreeOnly requires -CacheFreeImplementation asm-fixture.'
}
if ($CacheFreeHighOnly -and $CacheFreeHighImplementation -ne 'asm-fixture') {
    throw '-CacheFreeHighOnly requires -CacheFreeHighImplementation asm-fixture.'
}
if ($CacheFreeLowOnly -and $CacheFreeLowImplementation -ne 'asm-fixture') {
    throw '-CacheFreeLowOnly requires -CacheFreeLowImplementation asm-fixture.'
}
if ($CacheAllocOnly -and $CacheAllocImplementation -ne 'asm-fixture') {
    throw '-CacheAllocOnly requires -CacheAllocImplementation asm-fixture.'
}
if ($CacheMoveOnly -and $CacheMoveImplementation -ne 'asm-fixture') {
    throw '-CacheMoveOnly requires -CacheMoveImplementation asm-fixture.'
}
if ($CacheTryAllocOnly -and $CacheTryAllocImplementation -ne 'asm-fixture') {
    throw '-CacheTryAllocOnly requires -CacheTryAllocImplementation asm-fixture.'
}
if ($HunkMarkReleaseOnly -and $HunkMarkReleaseImplementation -ne 'asm-fixture') {
    throw '-HunkMarkReleaseOnly requires -HunkMarkReleaseImplementation asm-fixture.'
}
if ($HunkTempAllocOnly -and $HunkTempAllocImplementation -ne 'asm-fixture') {
    throw '-HunkTempAllocOnly requires -HunkTempAllocImplementation asm-fixture.'
}
if ($HunkNamedAllocOnly -and $HunkNamedAllocImplementation -ne 'asm-fixture') {
    throw '-HunkNamedAllocOnly requires -HunkNamedAllocImplementation asm-fixture.'
}
if ($VesaCopyRectsOnly -and $VesaCopyRectsImplementation -ne 'asm-fixture') {
    throw '-VesaCopyRectsOnly requires -VesaCopyRectsImplementation asm-fixture.'
}
if ($VesaSwapBuffersOnly -and $VesaSwapBuffersImplementation -ne 'asm-fixture') {
    throw '-VesaSwapBuffersOnly requires -VesaSwapBuffersImplementation asm-fixture.'
}
if ($MemoryOnly -and $MemoryImplementation -ne 'asm') {
    throw '-MemoryOnly requires -MemoryImplementation asm.'
}
if ($SurfaceCacheOnly -and $SurfaceCacheImplementation -ne 'asm') {
    throw '-SurfaceCacheOnly requires -SurfaceCacheImplementation asm.'
}
if ($ParticleListOnly -and $ParticleUpdateImplementation -ne 'asm') {
    throw '-ParticleListOnly requires -ParticleUpdateImplementation asm.'
}
if ($ParticleDrawOnly -and $ParticleDrawImplementation -ne 'asm') {
    throw '-ParticleDrawOnly requires -ParticleDrawImplementation asm.'
}
if ($ParticleUpdateOnly -and $ParticleUpdateImplementation -ne 'asm') {
    throw '-ParticleUpdateOnly requires -ParticleUpdateImplementation asm.'
}
if ($ParticleUpdateOnly -and $ParticleDrawImplementation -ne 'asm') {
    throw '-ParticleUpdateOnly requires -ParticleDrawImplementation asm for its framebuffer oracle.'
}
if ($DamageParseOnly -and $DamageParseImplementation -ne 'asm') {
    throw '-DamageParseOnly requires -DamageParseImplementation asm.'
}
if ($PaletteOnly -and $PaletteImplementation -ne 'asm') {
    throw '-PaletteOnly requires -PaletteImplementation asm.'
}
if ($ConsoleInputOnly -and $ConsoleImplementation -ne 'asm') {
    throw '-ConsoleInputOnly requires -ConsoleImplementation asm.'
}
if ($ScreenNotifyOnly -and $ScreenNotifyImplementation -ne 'asm') {
    throw '-ScreenNotifyOnly requires -ScreenNotifyImplementation asm.'
}
if ($ScreenCenterStringOnly -and $ScreenCenterStringImplementation -ne 'asm') {
    throw '-ScreenCenterStringOnly requires -ScreenCenterStringImplementation asm.'
}
if ($ScreenEraseCenterStringOnly -and $ScreenEraseCenterStringImplementation -ne 'asm') {
    throw '-ScreenEraseCenterStringOnly requires -ScreenEraseCenterStringImplementation asm.'
}
if ($ScreenConsoleSetupOnly -and $ScreenConsoleSetupImplementation -ne 'asm') {
    throw '-ScreenConsoleSetupOnly requires -ScreenConsoleSetupImplementation asm.'
}
if ($ScreenRefdefOnly -and $ScreenRefdefImplementation -ne 'asm') {
    throw '-ScreenRefdefOnly requires -ScreenRefdefImplementation asm.'
}
if ($ScreenDrawRamOnly -and $ScreenDrawRamImplementation -ne 'asm') {
    throw '-ScreenDrawRamOnly requires -ScreenDrawRamImplementation asm.'
}
if ($ScreenOverlaysOnly -and $ScreenOverlaysImplementation -ne 'asm') {
    throw '-ScreenOverlaysOnly requires -ScreenOverlaysImplementation asm.'
}
if ($ScreenUpdateOnly -and $ScreenUpdateImplementation -ne 'asm') {
    throw '-ScreenUpdateOnly requires -ScreenUpdateImplementation asm.'
}
if ($ScreenNetOnly -and $ScreenNetImplementation -ne 'asm') {
    throw '-ScreenNetOnly requires -ScreenNetImplementation asm.'
}
if ($ScreenTurtleOnly -and $ScreenTurtleImplementation -ne 'asm') {
    throw '-ScreenTurtleOnly requires -ScreenTurtleImplementation asm.'
}
if ($ParticleExplosionOnly -and $ParticleExplosionImplementation -ne 'asm') {
    throw '-ParticleExplosionOnly requires -ParticleExplosionImplementation asm.'
}
if ($ParseParticleEffectOnly -and $ParseParticleEffectImplementation -ne 'asm') {
    throw '-ParseParticleEffectOnly requires -ParseParticleEffectImplementation asm.'
}
if ($ParseParticleEffectOnly -and $RunParticleEffectImplementation -ne 'c') {
    throw '-ParseParticleEffectOnly requires -RunParticleEffectImplementation c so both parser paths use the C emitter.'
}
if ($RunParticleEffectOnly -and $RunParticleEffectImplementation -ne 'asm') {
    throw '-RunParticleEffectOnly requires -RunParticleEffectImplementation asm.'
}
if ($EntityParticlesOnly -and $EntityParticlesImplementation -ne 'asm') {
    throw '-EntityParticlesOnly requires -EntityParticlesImplementation asm.'
}
if ($ParticleExplosion2Only -and $ParticleExplosion2Implementation -ne 'asm') {
    throw '-ParticleExplosion2Only requires -ParticleExplosion2Implementation asm.'
}
if ($BlobExplosionOnly -and $BlobExplosionImplementation -ne 'asm') {
    throw '-BlobExplosionOnly requires -BlobExplosionImplementation asm.'
}
if ($LavaSplashOnly -and $LavaSplashImplementation -ne 'asm') {
    throw '-LavaSplashOnly requires -LavaSplashImplementation asm.'
}
if ($TeleportSplashOnly -and $TeleportSplashImplementation -ne 'asm') {
    throw '-TeleportSplashOnly requires -TeleportSplashImplementation asm.'
}
if ($RocketTrailOnly -and $RocketTrailImplementation -ne 'asm') {
    throw '-RocketTrailOnly requires -RocketTrailImplementation asm.'
}
if ($ZSubmodelPolygonsOnly -and $ZSubmodelPolygonsImplementation -ne 'asm') {
    throw '-ZSubmodelPolygonsOnly requires -ZSubmodelPolygonsImplementation asm.'
}
if ($FrustumTransformOnly -and $TransformFrustumImplementation -ne 'asm') {
    throw '-FrustumTransformOnly requires -TransformFrustumImplementation asm.'
}
if ($TransformPlaneOnly -and $TransformPlaneImplementation -ne 'asm') {
    throw '-TransformPlaneOnly requires -TransformPlaneImplementation asm.'
}
if ($LineGraphOnly -and $LineGraphImplementation -ne 'asm') {
    throw '-LineGraphOnly requires -LineGraphImplementation asm.'
}
if ($AliasStatsOnly -and $AliasStatsImplementation -ne 'asm') {
    throw '-AliasStatsOnly requires -AliasStatsImplementation asm.'
}
if ($PrintTimesOnly -and $PrintTimesImplementation -ne 'asm') {
    throw '-PrintTimesOnly requires -PrintTimesImplementation asm.'
}
if ($EfragStoreOnly -and $EfragStoreImplementation -ne 'asm') {
    throw '-EfragStoreOnly requires -EfragStoreImplementation asm.'
}
if ($SurfaceDrawOnly -and $SurfaceDrawImplementation -ne 'asm') {
    throw '-SurfaceDrawOnly requires -SurfaceDrawImplementation asm.'
}
if ($SurfaceZGradientOnly -and $SurfaceZGradientImplementation -ne 'asm') {
    throw '-SurfaceZGradientOnly requires -SurfaceZGradientImplementation asm.'
}
if ($SurfaceGradientOnly -and $SurfaceGradientImplementation -ne 'asm') {
    throw '-SurfaceGradientOnly requires -SurfaceGradientImplementation asm.'
}
if ($SpriteDrawOnly -and $SpriteDrawImplementation -ne 'asm') {
    throw '-SpriteDrawOnly requires -SpriteDrawImplementation asm.'
}
if ($SpriteSetupOnly -and $SpriteSetupImplementation -ne 'asm') {
    throw '-SpriteSetupOnly requires -SpriteSetupImplementation asm.'
}
if ($AliasSetupLightingOnly -and $AliasSetupLightingImplementation -ne 'asm') {
    throw '-AliasSetupLightingOnly requires -AliasSetupLightingImplementation asm.'
}
if ($AliasSetupFrameOnly -and $AliasSetupFrameImplementation -ne 'asm') {
    throw '-AliasSetupFrameOnly requires -AliasSetupFrameImplementation asm.'
}
if ($AliasSetupSkinOnly -and $AliasSetupSkinImplementation -ne 'asm') {
    throw '-AliasSetupSkinOnly requires -AliasSetupSkinImplementation asm.'
}
if ($AliasGradientsOnly -and $AliasGradientImplementation -ne 'asm') {
    throw '-AliasGradientsOnly requires -AliasGradientImplementation asm.'
}
if ($AliasLineScanOnly -and $AliasLineScanImplementation -ne 'asm') {
    throw '-AliasLineScanOnly requires -AliasLineScanImplementation asm.'
}
if ($AliasEdgeTableOnly -and $AliasEdgeTableImplementation -ne 'asm') {
    throw '-AliasEdgeTableOnly requires -AliasEdgeTableImplementation asm.'
}
if ($AliasSkinTableOnly -and $AliasSkinTableImplementation -ne 'asm') {
    throw '-AliasSkinTableOnly requires -AliasSkinTableImplementation asm.'
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
if (-not [string]::IsNullOrWhiteSpace($LocalOutputDirectoryName) -and $SkipIsaAudit) {
    throw '-LocalOutputDirectoryName requires the normal i486 ISA audit; it cannot be combined with -SkipIsaAudit.'
}
$buildParams = @{
        Benchmark = $true
        Instrumentation = [bool]$Instrumentation
        CpuTarget = $CpuTarget
        OptimizationProfile = $OptimizationProfile
        TextureAxisCacheEntries = $TextureAxisCacheEntries
        TextureAxisImplementation = $TextureAxisImplementation
        SurfaceCacheImplementation = $SurfaceCacheImplementation
        SurfaceDrawImplementation = $SurfaceDrawImplementation
        SurfaceZGradientImplementation = $SurfaceZGradientImplementation
        SurfaceGradientImplementation = $SurfaceGradientImplementation
        SurfaceDispatcherImplementation = $SurfaceDispatcherImplementation
        MipLevelImplementation = $MipLevelImplementation
        MemoryImplementation = $MemoryImplementation
        FillRectImplementation = $FillRectImplementation
        ZPointImplementation = $ZPointImplementation
        SkySpanImplementation = $SkySpanImplementation
        WarpScreenImplementation = $WarpScreenImplementation
        SolidSurfaceImplementation = $SolidSurfaceImplementation
        TurbulentImplementation = $TurbulentImplementation
        TurbulentScanImplementation = $TurbulentScanImplementation
        TextureSpanStores = $TextureSpanStores
        TextureSpanTailStores = $TextureSpanTailStores
        TextureSpanRowPath = $TextureSpanRowPath
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
        AliasProjectImplementation = $AliasProjectImplementation
        AliasBBoxProjectImplementation = $AliasBBoxProjectImplementation
        AliasTransformFinalImplementation = $AliasTransformFinalImplementation
        AliasPrepareImplementation = $AliasPrepareImplementation
        AliasClipImplementation = $AliasClipImplementation
        AliasClipZImplementation = $AliasClipZImplementation
        AliasMatrixCompositionImplementation = $AliasMatrixCompositionImplementation
        AliasSetupLightingImplementation = $AliasSetupLightingImplementation
        AliasSetupFrameImplementation = $AliasSetupFrameImplementation
        AliasSetupSkinImplementation = $AliasSetupSkinImplementation
        AliasGradientImplementation = $AliasGradientImplementation
        AliasLineScanImplementation = $AliasLineScanImplementation
        AliasEdgeTableImplementation = $AliasEdgeTableImplementation
        AliasSkinTableImplementation = $AliasSkinTableImplementation
        AliasRasterizeImplementation = $AliasRasterizeImplementation
        TextureAnimationImplementation = $TextureAnimationImplementation
        LightMapNormalizeImplementation = $LightMapNormalizeImplementation
        LightMapStylesImplementation = $LightMapStylesImplementation
        FusedLightMapImplementation = $FusedLightMapImplementation
        DynamicLightImplementation = $DynamicLightImplementation
        DynamicLightOrchestrationImplementation = $DynamicLightOrchestrationImplementation
        DynamicLightPushImplementation = $DynamicLightPushImplementation
        DlightContributesImplementation = $DlightContributesImplementation
        MarkLightsImplementation = $MarkLightsImplementation
        LightMapBuildImplementation = $LightMapBuildImplementation
        BspPlaneDotImplementation = $BspPlaneDotImplementation
        BspClipImplementation = $BspClipImplementation
        BspFrameCountImplementation = $BspFrameCountImplementation
        BspWalkImplementation = $BspWalkImplementation
        RenderWorldImplementation = $RenderWorldImplementation
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
        SpriteDrawImplementation = $SpriteDrawImplementation
        SpriteSetupImplementation = $SpriteSetupImplementation
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
        ParseParticleEffectImplementation = $ParseParticleEffectImplementation
        RunParticleEffectImplementation = $RunParticleEffectImplementation
        EntityParticlesImplementation = $EntityParticlesImplementation
        BlobExplosionImplementation = $BlobExplosionImplementation
        LavaSplashImplementation = $LavaSplashImplementation
        TeleportSplashImplementation = $TeleportSplashImplementation
        RocketTrailImplementation = $RocketTrailImplementation
        ParticleExplosionImplementation = $ParticleExplosionImplementation
        PaletteImplementation = $PaletteImplementation
        MathClosureImplementation = $MathClosureImplementation
        VisibilityImplementation = $VisibilityImplementation
        PublicBindingsImplementation = $PublicBindingsImplementation
        SkyImplementation = $SkyImplementation
        GibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
        ToolRoot = $ToolRoot
    }

if (-not [string]::IsNullOrWhiteSpace($LocalOutputDirectoryName)) {
    $buildParams['LocalOutputDirectoryName'] = $LocalOutputDirectoryName
}

if ($SkipIsaAudit) {
    $buildParams['SkipIsaAudit'] = $true
}

# Ask the builder where the output lands instead of recomputing the profile
# suffix here.  This runner used to carry its own copy of that arithmetic, and so
# did smoke-dos.ps1 and timedemo-dos.ps1; three copies of one rule is a standing
# invitation for a runner to look for an executable the builder never wrote.
# The builder is the only place that knows.
Add-RunnerBuildSelectors -BuildParameters $buildParams -Command $MyInvocation.MyCommand -SessionState $ExecutionContext.SessionState
$defaultResolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
$resolved = $defaultResolved
if ($SkipIsaAudit -and $CpuTarget -eq 'i486') {
    Write-Host 'DIAGNOSTIC ONLY: benchmark renderer ISA audit is skipped; this run cannot prove 486 compatibility.' -ForegroundColor Yellow
    $profileDirectory = Split-Path -Leaf ([string]$defaultResolved.outputRoot)
    $diagnosticOutputRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot (Join-Path 'out' ("diagnostic-bench-" + $profileDirectory))))
    $buildParams['DiagnosticOutputRoot'] = $diagnosticOutputRoot
    $resolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
    $resolvedOutputRoot = [IO.Path]::GetFullPath([string]$resolved.outputRoot)
    if (-not [string]::Equals($resolvedOutputRoot, $diagnosticOutputRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Diagnostic benchmark output root did not resolve as requested ('$resolvedOutputRoot' vs '$diagnosticOutputRoot')."
    }
}
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
$selectorVerification = Assert-RunnerBuildManifest -Resolved $resolved -BuildParameters $buildParams

# Keep a compact ownership/call-closure proof beside the selected build. This
# reports which renderer entries remain C-owned and verifies selected indirect
# dispatch targets from the exact objects used for the benchmark executable.
# qbench and qprof share an output root, so bind the report to the executable.
$ownershipReportName = 'renderer-ownership-{0}.json' -f `
    [IO.Path]::GetFileNameWithoutExtension([string]$resolved.executable)
$ownershipReport = Join-Path ([string]$resolved.outputRoot) $ownershipReportName
$ownershipManifest = Get-Content -LiteralPath ([string]$selectorVerification.manifest) -Raw | ConvertFrom-Json
$manifestObjectRoot = [IO.Path]::GetFullPath([string]$ownershipManifest.objectRoot)
$resolvedObjectRoot = [IO.Path]::GetFullPath([string]$resolved.objectRoot)
if (-not [string]::Equals($manifestObjectRoot, $resolvedObjectRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Renderer ownership object root '$manifestObjectRoot' differs from resolved build root '$resolvedObjectRoot'."
}
$objdumpPath = Join-Path (Join-Path $ToolRoot $toolManifest.djgpp.installDirectory) `
    ($toolManifest.djgpp.objdump -replace '/', [IO.Path]::DirectorySeparatorChar)
$ownershipArgs = @(
    (Join-Path $PSScriptRoot 'renderer-ownership.py'),
    '--manifest', [string]$selectorVerification.manifest,
    '--object-root', $manifestObjectRoot,
    '--objdump', $objdumpPath,
    '--root', '_R_RenderView',
    '--root', '_V_RenderView',
    '--root', '_V_UpdatePalette',
    '--root', '_SCR_UpdateScreen',
    '--output-json', $ownershipReport
)
& python @ownershipArgs
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ownershipReport -PathType Leaf)) {
    throw 'Renderer ownership and selected-dispatch proof failed for the benchmark build.'
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
$providerProofPath = $null
if ($selectorVerification.diagnosticOnly) {
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
            '--executable', (Join-Path $repoRoot 'src/cwsdpmi.exe'),
            '--compiler', $providerCompiler,
            '--output', $providerProofRoot,
            '--tool-root', $ToolRoot
        )
        & python @providerProofArgs
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $providerProofPath -PathType Leaf)) {
            throw 'Independent DPMI-provider ISA proof failed during diagnostic benchmark setup.'
        }
    }
}
$providerVerification = Assert-RunnerDpmiProvider -CpuTarget $CpuTarget -BuildVerification $selectorVerification `
    -ProviderPath (Join-Path $quakeRoot 'cwsdpmi.exe') `
    -DiagnosticOnly:$selectorVerification.diagnosticOnly -ProviderProofPath $providerProofPath

$benchCommand = if ($MemoryOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchmemory -benchexit'
}
elseif ($SbarPrimitivesOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsbarprimitives -benchexit'
}
elseif ($AliasProjectOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasproject -benchexit'
}
elseif ($SpriteBeamOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspritebeam -benchexit'
}
elseif ($SpriteClipOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspriteclip -benchexit'
}
elseif ($SpriteFrameOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspriteframe -benchexit'
}
elseif ($SpriteGradientOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspritegradient -benchexit'
}
elseif ($SpriteScanLeftOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspritescanleft -benchexit'
}
elseif ($SpriteScanRightOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspritescanright -benchexit'
}
elseif ($SpriteDrawOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspritedraw -benchexit'
}
elseif ($AliasControlOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliascontrol -benchexit'
}
elseif ($AliasModelLoadOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasmodelload -benchexit'
}
elseif ($SbarDrawOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsbar_draw -benchexit'
}
elseif ($SbarInventoryOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsbarinventory -benchexit'
}
elseif ($SbarFragsOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsbarfrags -benchexit'
}
elseif ($CacheCheckOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcachecheck -benchexit'
}
elseif ($CacheFreeOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcachefree -benchexit'
}
elseif ($CacheFreeHighOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcachefreehigh -benchexit'
}
elseif ($CacheFreeLowOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcachefreelow -benchexit'
}
elseif ($CacheAllocOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcachealloc -benchexit'
}
elseif ($CacheMoveOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcachemove -benchexit'
}
elseif ($CacheTryAllocOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcachetryalloc -benchexit'
}
elseif ($HunkMarkReleaseOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchhunkmarkfree -benchexit'
}
elseif ($HunkTempAllocOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchhunktempalloc -benchexit'
}
elseif ($HunkNamedAllocOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchhunknamedalloc -benchexit'
}
elseif ($VesaCopyRectsOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchvesacopy -benchexit'
}
elseif ($VesaSwapBuffersOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchvesaswap -benchexit'
}
elseif ($AliasStatsOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasstats -benchexit'
}
elseif ($PrintTimesOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchprinttimes -benchexit'
}
elseif ($WorldControlOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchworldcontrol -benchexit'
}
elseif ($EfragStoreOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchefragstore -benchexit'
}
elseif ($ChaseOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchchase -benchexit'
}
elseif ($HullCheckOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchhullcheck -benchexit'
}
elseif ($DrawingOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchdrawing -benchexit'
}
elseif ($ViewControlOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchviewcontrol -benchexit'
}
elseif ($ConsoleInputOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchconsoleinput -benchexit'
}
elseif ($ScreenNotifyOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreenotify -benchexit'
}
elseif ($ScreenCenterStringOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcenterstring -benchexit'
}
elseif ($ScreenEraseCenterStringOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchcentererase -benchexit'
}
elseif ($ScreenConsoleSetupOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreenconsolesetup -benchexit'
}
elseif ($ScreenRefdefOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreenrefdef -benchexit'
}
elseif ($ScreenDrawRamOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreenram -benchexit'
}
elseif ($ScreenOverlaysOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreenoverlays -benchexit'
}
elseif ($ScreenUpdateOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreenupdate -benchexit'
}
elseif ($ScreenNetOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreennet -benchexit'
}
elseif ($ScreenTurtleOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchscreenturtle -benchexit'
}
elseif ($DrawingDriverOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchdrawingdriver -benchexit'
}
elseif ($RenderDispatchOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchrenderdispatch -benchexit'
}
elseif ($SkyOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsky -benchexit'
}
elseif ($PublicBindingsOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchpublicbindings -benchexit'
}
elseif ($VisibilityOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchvisibility -benchexit'
}
elseif ($MathClosureOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchmathclosure -benchexit'
}
elseif ($PaletteOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchpalette -benchexit'
}
elseif ($FrameControlOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchframecontrol -benchexit'
}
elseif ($LineGraphOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchlinegraph -benchexit'
}
elseif ($TimeGraphOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchtimegraph -benchexit'
}
elseif ($LightControlOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchlightcontrol -benchexit'
}
elseif ($SpriteOrientationOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspriteorientation -benchexit'
}
elseif ($SpriteSetupOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchspritesetup -benchexit'
}
elseif ($AliasSetupLightingOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliassetuplighting -benchexit'
}
elseif ($AliasSetupFrameOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliassetupframe -benchexit'
}
elseif ($AliasSetupSkinOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliassetupskin -benchexit'
}
elseif ($AliasGradientsOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasgradients -benchexit'
}
elseif ($AliasLineScanOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliaslinescan -benchexit'
}
elseif ($AliasEdgeTableOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasedgetable -benchexit'
}
elseif ($AliasSkinTableOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchaliasskintable -benchexit'
}
elseif ($FillRectOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchfillrect -benchexit'
}
elseif ($ZPointOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchzpoint -benchexit'
}
elseif ($ZSpansOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchzspans -benchexit'
}
elseif ($SkySpanOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchskyspan -benchexit'
}
elseif ($WarpScreenOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchwarpscreen -benchexit'
}
elseif ($SolidSurfaceOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsolidsurface -benchexit'
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
elseif ($LightMapBuildOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchlightmapbuild -benchexit'
}
elseif ($ParticleListOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchparticlelist -benchexit'
}
elseif ($ParticleDrawOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchparticledraw -benchexit'
}
elseif ($ParticleUpdateOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchparticleupdate -benchexit'
}
elseif ($DamageParseOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchvparsedamage -benchexit'
}
elseif ($ParticleExplosionOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchparticleexplosion -benchexit'
}
elseif ($ParseParticleEffectOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchparseparticleeffect -benchexit'
}
elseif ($ForwardSpansOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchforwardspans -benchexit'
}
elseif ($RunParticleEffectOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchrunparticleeffect -benchexit'
}
elseif ($EntityParticlesOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchentityparticles -benchexit'
}
elseif ($ParticleExplosion2Only) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchparticleexplosion2 -benchexit'
}
elseif ($BlobExplosionOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchblobexplosion -benchexit'
}
elseif ($LavaSplashOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchlavasplash -benchexit'
}
elseif ($TeleportSplashOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchteleportsplash -benchexit'
}
elseif ($RocketTrailOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchrockettrail -benchexit'
}
elseif ($SurfaceCacheOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsurfacecache -benchexit'
}
elseif ($ZSubmodelPolygonsOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchzsubmodelpolys -benchexit'
}
elseif ($FrustumTransformOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchfrustumtransform -benchexit'
}
elseif ($TransformPlaneOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchtransformplane -benchexit'
}
elseif ($SurfaceDrawOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsurfacedraw -benchexit'
}
elseif ($SurfaceZGradientOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchzgradient -benchexit'
}
elseif ($SurfaceGradientOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchsurfacegradients -benchexit'
}
elseif ($BspClipOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchbspclip -benchexit'
}
elseif ($BspPlaneDotOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchbspplanedot -benchexit'
}
elseif ($MipLevelOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchmip -benchexit'
}
elseif ($TextureAnimationOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchtextureanimation -benchexit'
}
elseif ($TurbulentOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchturbulent -benchexit'
}
elseif ($TurbulentScanOnly) {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchturbulentscan -benchexit'
}
else {
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchexit'
}
$benchCommandSeparatorIndex = $benchCommand.IndexOf(' ')
if ($benchCommandSeparatorIndex -le 0) {
    throw "Could not locate the executable/argument separator in benchmark command '$benchCommand'."
}
# DOS's PSP tail starts at the separator after the executable; count that byte too.
$benchCommandTail = $benchCommand.Substring($benchCommandSeparatorIndex)
$benchCommandTailBytes = [Text.Encoding]::ASCII.GetByteCount($benchCommandTail)
$dosPspCommandTailMaxBytes = 126
if ($benchCommandTailBytes -gt $dosPspCommandTailMaxBytes) {
    throw ("Benchmark DOS command tail is {0} ASCII bytes including the leading separator; " +
        "the PSP limit is {1}: {2}") -f `
        $benchCommandTailBytes, $dosPspCommandTailMaxBytes, $benchCommand
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

$reportPath = Join-Path $quakeRoot 'bench486.txt'
$run = Invoke-DosboxProcess -Dosbox $dosbox -ConfigPath $configPath `
    -TimeoutSeconds $TimeoutSeconds -Description "DOSBox-X 486 benchmark in $stagingRoot" `
    -ProgressFile $reportPath
if ($run.TimedOut) {
    throw "DOSBox-X benchmark exceeded $TimeoutSeconds seconds."
}
$dosboxExit = $run.ExitCode

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
    isaAuditStatus = $selectorVerification.isaAuditStatus
    diagnosticOnly = $selectorVerification.diagnosticOnly
    executable = $benchmarkExe
    optimizationProfile = $OptimizationProfile
    textureAxisCacheEntries = $TextureAxisCacheEntries
    textureAxisImplementation = $TextureAxisImplementation
    surfaceCacheImplementation = $SurfaceCacheImplementation
    surfaceDrawImplementation = $SurfaceDrawImplementation
    surfaceZGradientImplementation = $SurfaceZGradientImplementation
    surfaceGradientImplementation = $SurfaceGradientImplementation
    surfaceDispatcherImplementation = $SurfaceDispatcherImplementation
    mipLevelImplementation = $MipLevelImplementation
    memoryImplementation = $MemoryImplementation
    memoryOnly = [bool]$MemoryOnly
    fillRectImplementation = $FillRectImplementation
    zPointImplementation = $ZPointImplementation
    skySpanImplementation = $SkySpanImplementation
    warpScreenImplementation = $WarpScreenImplementation
    solidSurfaceImplementation = $SolidSurfaceImplementation
    solidSurfaceOnly = [bool]$SolidSurfaceOnly
    turbulentImplementation = $TurbulentImplementation
    turbulentScanImplementation = $TurbulentScanImplementation
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
    spriteSetupImplementation = $SpriteSetupImplementation
    spriteOrientationImplementation = $SpriteOrientationImplementation
    buildSelectorVerification = $selectorVerification
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
    renderDispatchImplementation = $RenderDispatchImplementation
    drawingDriverImplementation = $DrawingDriverImplementation
    viewControlImplementation = $ViewControlImplementation
    drawingImplementation = $DrawingImplementation
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
    particleDrawImplementation = $ParticleDrawImplementation
    particleUpdateImplementation = $ParticleUpdateImplementation
    damageParseImplementation = $DamageParseImplementation
    blobExplosionImplementation = $BlobExplosionImplementation
    lavaSplashImplementation = $LavaSplashImplementation
    teleportSplashImplementation = $TeleportSplashImplementation
    rocketTrailImplementation = $RocketTrailImplementation
    particleExplosionImplementation = $ParticleExplosionImplementation
    parseParticleEffectImplementation = $ParseParticleEffectImplementation
    runParticleEffectImplementation = $RunParticleEffectImplementation
    entityParticlesImplementation = $EntityParticlesImplementation
    worldControlImplementation = $WorldControlImplementation
    instrumentation = [bool]$Instrumentation
    gibTrailHorizontalIntegration = $GibTrailHorizontalIntegration
    turbulentOnly = [bool]$TurbulentOnly
    aliasProjectOnly = [bool]$AliasProjectOnly
    aliasBBoxProjectOnly = [bool]$AliasBBoxProjectOnly
    aliasTransformFinalOnly = [bool]$AliasTransformFinalOnly
    aliasSetupFrameOnly = [bool]$AliasSetupFrameOnly
    spriteBeamOnly = [bool]$SpriteBeamOnly
    spriteClipOnly = [bool]$SpriteClipOnly
    spriteFrameOnly = [bool]$SpriteFrameOnly
    spriteGradientOnly = [bool]$SpriteGradientOnly
    spriteScanLeftOnly = [bool]$SpriteScanLeftOnly
    spriteScanRightOnly = [bool]$SpriteScanRightOnly
    spriteDrawOnly = [bool]$SpriteDrawOnly
    spriteSetupOnly = [bool]$SpriteSetupOnly
    spriteOrientationOnly = [bool]$SpriteOrientationOnly
    lightControlOnly = [bool]$LightControlOnly
    frameControlOnly = [bool]$FrameControlOnly
    lineGraphOnly = [bool]$LineGraphOnly
    timeGraphOnly = [bool]$TimeGraphOnly
    paletteOnly = [bool]$PaletteOnly
    mathClosureOnly = [bool]$MathClosureOnly
    visibilityOnly = [bool]$VisibilityOnly
    publicBindingsOnly = [bool]$PublicBindingsOnly
    skyOnly = [bool]$SkyOnly
    renderDispatchOnly = [bool]$RenderDispatchOnly
    drawingDriverOnly = [bool]$DrawingDriverOnly
    viewControlOnly = [bool]$ViewControlOnly
    consoleInputOnly = [bool]$ConsoleInputOnly
    screenConsoleSetupOnly = [bool]$ScreenConsoleSetupOnly
    screenRefdefOnly = [bool]$ScreenRefdefOnly
    screenDrawRamOnly = [bool]$ScreenDrawRamOnly
    screenOverlaysOnly = [bool]$ScreenOverlaysOnly
    screenUpdateOnly = [bool]$ScreenUpdateOnly
    screenNetOnly = [bool]$ScreenNetOnly
    screenTurtleOnly = [bool]$ScreenTurtleOnly
    drawingOnly = [bool]$DrawingOnly
    sbarPrimitivesOnly = [bool]$SbarPrimitivesOnly
    sbarInventoryOnly = [bool]$SbarInventoryOnly
    chaseOnly = [bool]$ChaseOnly
    hullCheckOnly = [bool]$HullCheckOnly
    aliasControlOnly = [bool]$AliasControlOnly
    aliasModelLoadOnly = [bool]$AliasModelLoadOnly
    sbarDrawOnly = [bool]$SbarDrawOnly
    aliasStatsOnly = [bool]$AliasStatsOnly
    printTimesOnly = [bool]$PrintTimesOnly
    worldControlOnly = [bool]$WorldControlOnly
    efragStoreOnly = [bool]$EfragStoreOnly
    spriteDrawImplementation = $SpriteDrawImplementation
    textureAnimationOnly = [bool]$TextureAnimationOnly
    lightMapNormalizeOnly = [bool]$LightMapNormalizeOnly
    lightMapStylesOnly = [bool]$LightMapStylesOnly
    fusedLightMapOnly = [bool]$FusedLightMapOnly
    lightMapBuildOnly = [bool]$LightMapBuildOnly
    surfaceCacheOnly = [bool]$SurfaceCacheOnly
    particleListOnly = [bool]$ParticleListOnly
    particleDrawOnly = [bool]$ParticleDrawOnly
    particleUpdateOnly = [bool]$ParticleUpdateOnly
    damageParseOnly = [bool]$DamageParseOnly
    particleExplosion2Only = [bool]$ParticleExplosion2Only
    blobExplosionOnly = [bool]$BlobExplosionOnly
    lavaSplashOnly = [bool]$LavaSplashOnly
    teleportSplashOnly = [bool]$TeleportSplashOnly
    rocketTrailOnly = [bool]$RocketTrailOnly
    particleExplosionOnly = [bool]$ParticleExplosionOnly
    parseParticleEffectOnly = [bool]$ParseParticleEffectOnly
    forwardSpansOnly = [bool]$ForwardSpansOnly
    zSpansOnly = [bool]$ZSpansOnly
    runParticleEffectOnly = [bool]$RunParticleEffectOnly
    entityParticlesOnly = [bool]$EntityParticlesOnly
    transformPlaneOnly = [bool]$TransformPlaneOnly
    zSubmodelPolygonsOnly = [bool]$ZSubmodelPolygonsOnly
    frustumTransformOnly = [bool]$FrustumTransformOnly
    surfaceDrawOnly = [bool]$SurfaceDrawOnly
    surfaceZGradientOnly = [bool]$SurfaceZGradientOnly
    surfaceGradientOnly = [bool]$SurfaceGradientOnly
    bspPlaneDotOnly = [bool]$BspPlaneDotOnly
    mipLevelOnly = [bool]$MipLevelOnly
    bspClipOnly = [bool]$BspClipOnly
    dataRoot = $DataRoot
    stagingRoot = $stagingRoot
    report = $report
}
$result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stagingRoot 'bench-result.json') -Encoding ASCII
Write-Host $report
Write-Host "Benchmark result: $($stagingRoot)\bench-result.json"

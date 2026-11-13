[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$Benchmark,
    [switch]$Instrumentation,
    [switch]$NoBootstrap,
    # Minimum CPU the build targets. i486 is the default and retained release
    # profile; i386 is a separate, separately audited codepath whose object
    # directory and executable never share the i486 output tree. Both targets'
    # resolved flags and paths are pinned in tools\test-build-dos.py.
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    # Print the resolved flag lists and output paths as JSON and exit without
    # compiling.  tools\test-build-dos.py drives this so the i486 flag lists can
    # be golden-pinned without the guard having to re-implement the profile
    # suffix arithmetic.
    [switch]$DumpFlags,
    # Blocking ISA gate. On by default: audit the selected objects and compare
    # the linked i486 executable against every mapped input .text contribution.
    # The object audit also ratchets above-target encodings against
    # tools\golden\isa-baseline.json. -SkipIsaAudit disables these promotion
    # checks and is only for quantifying a residual.
    [switch]$SkipIsaAudit,
    # Ratchet the ISA baseline down to whatever this build just produced.  Read
    # the diff afterwards: --record on a release gate can hide a regression, so
    # the recorded figures must be checked against the ones you meant to change.
    [switch]$RecordIsaBaseline,
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
    [ValidateSet('c', 'asm', 'stosb', 'pair', 'quad', 'octa', 'twelve', 'fourteen', 'fourteen-stosb')]
    [string]$TurbulentImplementation = 'stosb',
    [ValidateSet('c', 'asm')]
    [string]$TurbulentScanImplementation = 'c',
    [ValidateSet('byte', 'word', 'dword', 'loop', 'stosw')]
    [string]$TextureSpanStores = 'word',
    [ValidateSet('control', 'word')]
    [string]$TextureSpanTailStores = 'control',
    [ValidateSet('control', 'norowcross')]
    [string]$TextureSpanRowPath = 'control',
    [ValidateSet('control', 'zerot')]
    [string]$TextureSpanTZeroPath = 'control',
    [ValidateSet('control', 'zerot')]
    [string]$TextureSpanTailTZeroPath = 'control',
    [ValidateSet('control', 'nofxch')]
    [string]$ZSpanStartSchedule = 'control',
    [ValidateSet('control', 'loadfirst')]
    [string]$TextureSpanLoadOrder = 'control',
    [ValidateSet('control')]
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
    # Dead-scratch probe over one edge-scan block.  Duplicates a fixed,
    # side-effect-free instruction sequence at that block's inner point and
    # discards the result, so the timedemo delta prices those instructions.
    # Never a candidate: the probe only measures.  'control' is the release
    # path and must assemble instruction-for-instruction identically.
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
    [string]$BspFrameCountImplementation = 'local',
    [ValidateSet('c', 'asm')]
    [string]$BspWalkImplementation = 'c',
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
    [string]$PlayerTranslationImplementation = 'c',
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
    [string]$ToolRoot,
    # Isolated, non-promotion output for explicitly skipped i486 diagnostics.
    # The resolved path must remain below this checkout's out\.
    [string]$DiagnosticOutputRoot,
    # Put an audited i486 build in a direct child of out\local-<name>.
    # This avoids externally redirected long-profile paths when needed.
    [string]$LocalOutputDirectoryName,
    [switch]$ConsoleOutputOnlyBenchmark
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'selectors.ps1')
Set-DefaultI486AssemblySelectors -CpuTarget $CpuTarget -BoundParameters $PSBoundParameters

if ($AliasClipZImplementation -eq 'asm' -and $AliasClipImplementation -ne 'asm') {
    throw '-AliasClipZImplementation asm requires -AliasClipImplementation asm.'
}

if ($Instrumentation -and -not $Benchmark) {
    throw 'Profile builds require -Benchmark.'
}
if ($ConsoleOutputOnlyBenchmark -and -not $Benchmark) {
    throw '-ConsoleOutputOnlyBenchmark requires -Benchmark.'
}
if ($TextureSpanLoadOrder -eq 'loadfirst' -and $TextureSpanStores -ne 'word') {
    throw 'The loadfirst texture-span path requires -TextureSpanStores word.'
}
if ($TextureSpanStores -eq 'stosw' -and
		($TextureSpanLoadOrder -ne 'control' -or
		$TextureSpanAddressing -ne 'control' -or
		$TextureSpanRowPath -ne 'control' -or
		$TextureSpanTZeroPath -ne 'control' -or
		$TextureSpanTailTZeroPath -ne 'control')) {
	throw 'The stosw texture-span store path requires control load order, addressing, row path, and T-zero paths.'
}
if ($TextureSpanTailTZeroPath -eq 'zerot' -and $TextureSpanTailStores -ne 'control') {
	throw 'The exact-zero-T tail path requires -TextureSpanTailStores control.'
}

if ($AliasControlImplementation -in @('asm', 'asm-fixture')) {
    foreach ($dependency in @('AliasPrepareImplementation','AliasBBoxProjectImplementation','AliasMatrixCompositionImplementation','AliasSetupLightingImplementation','AliasSetupFrameImplementation','AliasSetupSkinImplementation')) {
        if ((Get-Variable -Name $dependency -ValueOnly) -ne 'asm') {
            throw "-AliasControlImplementation asm requires -$dependency asm."
        }
    }
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repoOutRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot 'out'))

function Assert-RendererOutputPathNoReparse {
    param(
        [Parameter(Mandatory)][string]$RepoOutRoot,
        [Parameter(Mandatory)][string]$Path
    )

    $rootFull = [IO.Path]::GetFullPath($RepoOutRoot)
    $pathFull = [IO.Path]::GetFullPath($Path)
    $prefix = $rootFull.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $pathFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Build output '$pathFull' is outside the repository out directory '$rootFull'."
    }

    # A fresh standalone clone has no ignored out directory yet. There can be
    # no redirected child when that root is absent; normal creation follows.
    if (-not (Test-Path -LiteralPath $rootFull)) { return }
    $rootItem = Get-Item -LiteralPath $rootFull -Force -ErrorAction Stop
    if ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Build output root '$rootFull' is a reparse point; refusing redirected output."
    }

    $relative = $pathFull.Substring($prefix.Length)
    $segments = @($relative -split '[\\/]+' | Where-Object { $_.Length -gt 0 })
    $current = $rootFull
    foreach ($segment in $segments) {
        $entry = $null
        foreach ($candidate in (Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop)) {
            if ($candidate.Name -ceq $segment) {
                $entry = $candidate
                break
            }
        }
        if ($null -eq $entry) {
            break
        }
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Build output path '$($entry.FullName)' is a reparse point; refusing redirected output."
        }
        if ($segment -ne $segments[-1] -and
                -not ($entry.Attributes -band [IO.FileAttributes]::Directory)) {
            throw "Build output parent '$($entry.FullName)' is not a directory."
        }
        $current = $entry.FullName
    }
}
if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        throw 'Could not determine the Windows local application-data directory.'
    }
    $ToolRoot = Join-Path $localAppData '486quake\tools'
}
$ToolRoot = [IO.Path]::GetFullPath($ToolRoot)

$toolManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$djgppRoot = Join-Path $ToolRoot $toolManifest.djgpp.installDirectory
$compiler = Join-Path $djgppRoot ($toolManifest.djgpp.compiler -replace '/', [IO.Path]::DirectorySeparatorChar)
$objdump = Join-Path $djgppRoot ($toolManifest.djgpp.objdump -replace '/', [IO.Path]::DirectorySeparatorChar)
$bootstrap = Join-Path $PSScriptRoot 'bootstrap-dos.ps1'

# -DumpFlags is a pure inspection of this script's own arithmetic, so it must
# not depend on a bootstrapped toolchain.  tools\test-build-dos.py relies on
# that: the i486 flag lists are golden-pinned without a compiler installed.
if (-not $DumpFlags) {
    if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
        if ($NoBootstrap) {
            throw "DJGPP compiler not found at '$compiler'. Run bootstrap-dos.ps1 first or omit -NoBootstrap."
        }
        & $bootstrap -ToolRoot $ToolRoot
    }

    foreach ($requiredPath in @($compiler, $objdump)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Required DJGPP tool is missing: '$requiredPath'."
        }
    }
}

$sourceRoot = Join-Path $repoRoot 'src'
Assert-SelectorOrdersIsConsistent
Assert-SelectorManifestOrderIsConsistent

# ---------------------------------------------------------------------------
# The profile suffix: one pass over the selector table.
#
# The architecture token leads, and only for the non-default target, so every i486
# output directory keeps the exact name it has always had. Then each selector
# contributes its token if it has one for the resolved value. A selector whose
# resolved value is its default simply has no entry, which is how the default build
# keeps a short suffix.
# ---------------------------------------------------------------------------
$profileSuffixParts = @()
foreach ($name in $script:SuffixOrder) {
    $selector = Get-SelectorEntry -Name $name
    $value = Get-SelectorValue -Name $name
    if ($null -ne $selector -and $selector.ContainsKey('ArchToken')) {
        if ($selector.ArchToken.ContainsKey($value)) {
            $profileSuffixParts += $selector.ArchToken[$value]
        }
        continue
    }
    if ($null -ne $selector -and $selector.Suffix.ContainsKey($value)) {
        $profileSuffixParts += $selector.Suffix[$value]
    }
}
$profileSuffix = if ($profileSuffixParts.Count) {
    '-' + ($profileSuffixParts -join '-')
}
else {
    ''
}
$outputRoot = Join-Path $repoRoot ('out\dos' + $profileSuffix)
if (-not [string]::IsNullOrWhiteSpace($LocalOutputDirectoryName)) {
    if (-not [string]::IsNullOrWhiteSpace($DiagnosticOutputRoot)) {
        throw '-LocalOutputDirectoryName cannot be combined with -DiagnosticOutputRoot.'
    }
    if ($CpuTarget -ne 'i486') {
        throw '-LocalOutputDirectoryName is available only for i486 builds.'
    }
    if ($LocalOutputDirectoryName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$' -or
            $LocalOutputDirectoryName.Contains('..')) {
        throw "Invalid local output directory name '$LocalOutputDirectoryName'; use one simple name without path separators."
    }
    $outputRoot = Join-Path $repoOutRoot ('local-' + $LocalOutputDirectoryName)
}
elseif (-not [string]::IsNullOrWhiteSpace($DiagnosticOutputRoot)) {
    if ($CpuTarget -ne 'i486' -or -not $SkipIsaAudit) {
        throw '-DiagnosticOutputRoot is only available for explicit i486 -SkipIsaAudit builds.'
    }
    $diagnosticOutputRoot = if ([IO.Path]::IsPathRooted($DiagnosticOutputRoot)) {
        [IO.Path]::GetFullPath($DiagnosticOutputRoot)
    } else {
        [IO.Path]::GetFullPath((Join-Path $repoRoot $DiagnosticOutputRoot))
    }
    $repoOutPrefix = $repoOutRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if ($diagnosticOutputRoot -eq $repoOutRoot -or
            -not $diagnosticOutputRoot.StartsWith($repoOutPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Diagnostic output must be a child of '$repoOutRoot'; got '$diagnosticOutputRoot'."
    }
    $outputRoot = $diagnosticOutputRoot
}
$objectDirectoryName = 'obj'
if ($Benchmark -and $Instrumentation) {
    # Combined selector suffixes can push object filenames beyond Windows'
    # legacy MAX_PATH limit. Keep the instrumented benchmark objects in a
    # compact, distinct directory while leaving release and qbench paths intact.
    $objectDirectoryName += '-bp'
}
else {
    if ($Benchmark) {
        $objectDirectoryName += '-bench'
    }
    if ($Instrumentation) {
        $objectDirectoryName += '-profile'
    }
}
$objectRoot = Join-Path $outputRoot $objectDirectoryName
$executableName = if ($Instrumentation) { 'qprof.exe' } elseif ($Benchmark) { 'qbench.exe' } else { 'quake.exe' }
$executable = Join-Path $outputRoot $executableName
$linkMap = Join-Path $outputRoot ($executableName + '.map')
$manifestName = if ($Instrumentation) { 'build-manifest-profile.json' } elseif ($Benchmark) { 'build-manifest-bench.json' } else { 'build-manifest.json' }

# The two targets must never resolve to the same output tree, because -Clean
# removes the directory it is handed.  They cannot collide by construction: the
# only difference between the targets is the leading arch token, so the i386 root
# is always the i486 root with `i386` inserted.  The assertion below states that
# invariant explicitly, and covers the case where the rest of the selector set is
# empty and the suffix degenerates to a bare `dos`.
$archToken = 'i386'
# The selector set for the *other* target is this one with the arch token
# removed, and only if the arch token was actually prepended -- for i486 the
# first token is the memory implementation, not the architecture.
$selectorPartsForOtherTarget = @($profileSuffixParts)
if (($CpuTarget -eq 'i386') -and $selectorPartsForOtherTarget.Count -gt 0 -and
    ($selectorPartsForOtherTarget[0] -eq $archToken)) {
    $selectorPartsForOtherTarget = @($selectorPartsForOtherTarget | Select-Object -Skip 1)
}
$otherSuffixBody = if ($selectorPartsForOtherTarget.Count) { '-' + ($selectorPartsForOtherTarget -join '-') } else { '' }
$i486RootForThisSelectorSet = Join-Path $repoRoot ('out\dos' + $otherSuffixBody)
$i386RootForThisSelectorSet = Join-Path $repoRoot ('out\dos-' + $archToken + $otherSuffixBody)
if ($CpuTarget -eq 'i386') {
    if (($outputRoot -ne $i386RootForThisSelectorSet) -or ($i486RootForThisSelectorSet -eq $i386RootForThisSelectorSet)) {
        throw "The i386 output root '$outputRoot' does not match the i486/i386 separation ('$i486RootForThisSelectorSet' vs '$i386RootForThisSelectorSet'). Refusing to build, because -Clean removes the directory it is given."
    }
}
elseif ([string]::IsNullOrWhiteSpace($DiagnosticOutputRoot) -and
        [string]::IsNullOrWhiteSpace($LocalOutputDirectoryName) -and
        $outputRoot -ne $i486RootForThisSelectorSet) {
    throw "The i486 output root '$outputRoot' does not match the i486/i386 separation ('$i486RootForThisSelectorSet' vs '$i386RootForThisSelectorSet')."
}

# Keep the profile's descriptive directory while the executable path fits the
# legacy Windows limit. If it does not, hash the complete profile directory into
# a short sibling under out\; the manifest still records every selector value.
if ([string]::IsNullOrWhiteSpace($LocalOutputDirectoryName) -and
        ($executable.Length -gt 259 -or $linkMap.Length -gt 259)) {
    $hashProvider = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashInput = [System.Text.Encoding]::UTF8.GetBytes(
            'profile-output-v1|' + $outputRoot)
        $outputPathHash = [BitConverter]::ToString(
            $hashProvider.ComputeHash($hashInput)).Replace('-', '').Substring(0, 16).ToLowerInvariant()
    }
    finally {
        $hashProvider.Dispose()
    }
    $outputRoot = Join-Path $repoOutRoot ('profile-' + $outputPathHash)
    $executable = Join-Path $outputRoot $executableName
    $linkMap = Join-Path $outputRoot ($executableName + '.map')
}

# The object directory is created here rather than next to the compile loop,
# because -Clean below needs to have removed it first.
#
# It is created AFTER the -DumpFlags early return, which is further down. That used
# to be the other way round, so a "pure inspection" -- the mode
# tools\test-build-dos.py, tools\guard-i486-release.py and tools\isa-audit-source.py
# all call, and which the builder's own comment promises "does not depend on the
# compile loop having run" -- created out\dos<suffix>\obj as a side effect. Four of
# those tools can now ask what a configuration resolves to without writing anything,
# which is also what let this whole script's flag arithmetic be pinned against a
# golden with no compiler installed.

$allCSources = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.c' -File | Sort-Object Name)
$includedCSources = @('net_comx.c')
$cSources = @($allCSources | Where-Object { $_.Name -notin $includedCSources })
$allAsmSources = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.s' -File | Sort-Object Name)

# Which .s files are live, from the selector table's SelectsAsm column rather than
# from a hand-copied list of the implementation selectors. A -Benchmark
# build compiles all of them, because the bench harness compares C against asm and
# needs both sides present.
$asmIsLive = $Benchmark -or (@(
        $script:SelectorTable |
            Where-Object { $_.SelectsAsm -and ((Get-SelectorValue -Name $_.Param) -eq 'asm') }
    ).Count -gt 0)

# Read the disjunction carefully, because it does not say what it looks like it
# says. This is a chain of -or, and -eq binds tighter, so the original condition
# parsed as "any implementation selector is asm, OR this file is not
# asm486_experiments.s". The name test is therefore an extra way for a file to be
# INCLUDED, not a way to exclude one: in the default release build every one of the
# 22 .s files is compiled, asm486_experiments.s among them, and the inventory pin
# below expects 21. Only when every implementation selector is 'c' and this is not a
# -Benchmark build does the name test do any work, and then it drops that one file
# and the expected count drops with it.
#
# Rewriting this as an exclusion -- "include the file unless it is
# asm486_experiments.s" -- compiles 20 and fails the inventory pin. That is what
# happened the first time this was table-driven, which is the pin doing its job.
$asmSources = @($allAsmSources | Where-Object { $asmIsLive -or $_.Name -ne 'asm486_experiments.s' })
$allSources = @($cSources + $asmSources)

# Keep descriptive selector suffixes in the executable output path. If their
# combined length would push an object filename past the legacy Windows MAX_PATH
# boundary, put just the objects in a deterministic short sibling under out\.
# The hash includes the full profile path and object class, so selector/profile
# combinations never share stale objects. Short profiles (including the pinned
# obj-bp instrumentation cache) retain their established objectRoot.
$objectRoot = Join-Path $outputRoot $objectDirectoryName
$longestObjectSource = $allSources |
    Sort-Object -Property @{ Expression = { $_.Name.Length }; Descending = $true } |
    Select-Object -First 1
if ($null -ne $longestObjectSource) {
    $longestObjectPath = Join-Path $objectRoot ($longestObjectSource.BaseName + '.obj')
    if ($longestObjectPath.Length -gt 259) {
        $hashProvider = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashInput = [System.Text.Encoding]::UTF8.GetBytes(
                'object-root-v1|' + $outputRoot + '|' + $objectDirectoryName)
            $objectPathHash = [BitConverter]::ToString(
                $hashProvider.ComputeHash($hashInput)).Replace('-', '').Substring(0, 16).ToLowerInvariant()
        }
        finally {
            $hashProvider.Dispose()
        }
        $repoOutRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot 'out'))
        $objectRoot = Join-Path $repoOutRoot ('obj-' + $objectPathHash + '-' + $objectDirectoryName)
    }
}

$repoOutRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot 'out'))
$repoOutPrefix = $repoOutRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$resolvedObjectRoot = [IO.Path]::GetFullPath($objectRoot)
if (-not $resolvedObjectRoot.StartsWith($repoOutPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Object root '$resolvedObjectRoot' is outside the repository out directory '$repoOutRoot'."
}
$objectRoot = $resolvedObjectRoot

# Never create, clean, or compile through a junction/symlink under out\. The
# component walk enumerates each parent on this checkout's out volume and stops
# at the first missing component; it does not traverse a reparse point.
if (-not $DumpFlags) {
    Assert-RendererOutputPathNoReparse -RepoOutRoot $repoOutRoot -Path $outputRoot
    Assert-RendererOutputPathNoReparse -RepoOutRoot $repoOutRoot -Path $objectRoot
    New-Item -ItemType Directory -Path $repoOutRoot -Force | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($LocalOutputDirectoryName)) {
        foreach ($entry in (Get-ChildItem -LiteralPath $repoOutRoot -Force -ErrorAction Stop)) {
            if ($entry.Name -ceq (Split-Path -Leaf $outputRoot)) {
                throw "Local build output '$outputRoot' already exists; choose a fresh -LocalOutputDirectoryName."
            }
        }
    }
}

if ($Clean) {
	if ($Benchmark) {
		foreach ($benchmarkPath in @($objectRoot, $executable,
				(Join-Path $outputRoot $manifestName))) {
			if (Test-Path -LiteralPath $benchmarkPath) {
				Remove-Item -LiteralPath $benchmarkPath -Recurse -Force
			}
		}
	}
	else {
		if (Test-Path -LiteralPath $objectRoot) {
			Remove-Item -LiteralPath $objectRoot -Recurse -Force
		}
		if (Test-Path -LiteralPath $outputRoot) {
			Remove-Item -LiteralPath $outputRoot -Recurse -Force
		}
	}
}

# The inventory pin. The expected counts are literal here for -DumpFlags and are
# independently mirrored in the target manifests and tools\test-build-dos.py.
# Update all of them when a source is legitimately added or removed.
#
# -DumpFlags stays pure and does NOT read the manifest: tools\test-build-dos.py
# drives it and then compares its output against the manifest, so having it read
# the manifest for its own expectations would make the comparison circular.  The
# manifest's counts are read only on a real build, and test-build-dos.py keeps
# its own literal pin, so the invariant is still enforced independently.
$expectedAllCSourceCount = 83
$expectedStandaloneCSourceCount = 82
$expectedAllAssemblySourceCount = 86
if (-not $DumpFlags) {
    $goldenFlagsPath = Join-Path $PSScriptRoot ('golden\build-flags-{0}.json' -f $CpuTarget)
    if (-not (Test-Path -LiteralPath $goldenFlagsPath -PathType Leaf)) {
        throw "Golden flag manifest not found: '$goldenFlagsPath'. It carries the expected source counts for target '$CpuTarget'."
    }
    $goldenFlags = Get-Content -LiteralPath $goldenFlagsPath -Raw | ConvertFrom-Json
    $expectedAllCSourceCount = [int]$goldenFlags.cSourceCount
    $expectedStandaloneCSourceCount = [int]$goldenFlags.standaloneCSourceCount
    $expectedAllAssemblySourceCount = [int]$goldenFlags.allAssemblySourceCount
}

# The expected active-assembly count is the total minus the one file that is never
# part of a release build, and it is derived from $asmIsLive -- the same flag that
# decided which .s files were compiled -- rather than from a fourth copy of the
# implementation-selector list.
$expectedAssemblySourceCount = if ($asmIsLive) {
    $expectedAllAssemblySourceCount
}
else {
    $expectedAllAssemblySourceCount - 1
}
if (($allCSources.Count -ne $expectedAllCSourceCount) -or ($cSources.Count -ne $expectedStandaloneCSourceCount) -or
	($allAsmSources.Count -ne $expectedAllAssemblySourceCount) -or ($asmSources.Count -ne $expectedAssemblySourceCount)) {
    throw ("Expected {1} retained C sources ({2} standalone), {3} total assembly sources, and {4} active assembly sources, found {5} C ({6} standalone), {7} total assembly, and {8} active assembly. If this change is intended, update {9} and re-record tools\test-build-dos.py." -f
        $CpuTarget, $expectedAllCSourceCount, $expectedStandaloneCSourceCount, $expectedAllAssemblySourceCount,
        $expectedAssemblySourceCount, $allCSources.Count, $cSources.Count, $allAsmSources.Count, $asmSources.Count,
        ('tools\golden\build-flags-{0}.json' -f $CpuTarget))
}

$objectNames = @($allSources | ForEach-Object { $_.BaseName + '.obj' })
$duplicateObjectNames = @($objectNames | Group-Object | Where-Object Count -gt 1)
if ($duplicateObjectNames.Count -gt 0) {
    throw "Source basename collision: $($duplicateObjectNames.Name -join ', ')"
}

$oldDjdir = $env:DJDIR
$oldGccExecPrefix = $env:GCC_EXEC_PREFIX
$oldPath = $env:PATH

try {
    $env:DJDIR = Join-Path $djgppRoot 'i586-pc-msdosdjgpp'
    $env:GCC_EXEC_PREFIX = Join-Path $djgppRoot 'lib\gcc\'
    $env:PATH = (Join-Path $djgppRoot 'bin') + ';' + (Join-Path $djgppRoot 'i586-pc-msdosdjgpp\bin') + ';' + $oldPath

    $optimizationLevel = if ($OptimizationProfile -eq 'aggressive') { '-O3' } else { '-O2' }
    # For i486 these are the exact strings the build has always used; the
    # parameterised form exists only so that the two targets cannot drift apart
    # in any other respect.
    $marchFlag = "-march=$CpuTarget"
    $mtuneFlag = "-mtune=$CpuTarget"
    $cpuModel = if ($CpuTarget -eq 'i486') { '486DX' } else { '386' }
    # Quake's renderer and supporting math require an x87.  Make the intended
    # 486DX-compatible floating-point instruction family explicit instead of
    # relying on GCC's target defaults.
    $fpuModel = '387-compatible'
    $floatingPointMode = '387'
    $cFlags = @(
        "-I$sourceRoot",
        $optimizationLevel,
        $marchFlag,
        $mtuneFlag,
        '-mfpmath=387',
        '-falign-loops=8',
        '-falign-jumps=16',
        '-falign-functions=8',
        '-freorder-blocks',
        '-freorder-functions',
        '-fomit-frame-pointer',
        '-frename-registers',
		'-fno-strict-aliasing',
        '-fcommon',
        '-ffast-math',
        '-std=gnu89',
        # Retain the exact compiler instruction listing from this compilation.
        '-save-temps=obj',
        "-DD_TEXAXIS_CACHE_SIZE=$TextureAxisCacheEntries"
    )
    if ($Benchmark) {
        $cFlags += '-DBENCH486'
    }
    if ($ConsoleOutputOnlyBenchmark) {
        $cFlags += '-DBENCH486_CONSOLE_OUTPUT_ONLY'
    }

    # ---------------------------------------------------------------------------
    # Selector-driven defines, in the order each language has always emitted them.
    #
    # The base list above ends at -DD_TEXAXIS_CACHE_SIZE and is positional: it must
    # stay exactly where it is, because the golden manifest compares this array
    # element by element. Everything after it was a hand-written conditional per
    # selector, in three interleaved blocks; it is now one pass per language over an
    # order declared in tools\selectors.ps1.
    #
    # The three orders are different permutations and are declared separately,
    # because they are not derivable from one another. Assert-SelectorOrdersIsConsistent,
    # called at the top of this script, is what stops a selector being added to the
    # table and to only some of the orders.
    # ---------------------------------------------------------------------------
    foreach ($name in $script:CDefineOrder) {
        if ($name.StartsWith('BUILD:')) {
            $switch = $script:BuildSwitchDefines[$name]
            if (& $switch.Emit) {
                $cFlags += ('-D' + $switch.Define)
            }
            continue
        }
        $selector = Get-SelectorEntry -Name $name
        $value = Get-SelectorValue -Name $name
        if ($selector.C.ContainsKey($value)) {
            foreach ($define in $selector.C[$value]) {
                $cFlags += ('-D' + $define)
            }
        }
    }

    $asmFlags = @(
        "-I$sourceRoot",
        $optimizationLevel,
        $marchFlag,
        $mtuneFlag,
        '-falign-loops=16',
        '-falign-jumps=16',
        '-falign-functions=16',
        '-x',
        'assembler-with-cpp'
    )
    foreach ($name in $script:AsmDefineOrder) {
        if ($name.StartsWith('BUILD:')) {
            $switch = $script:BuildSwitchDefines[$name]
            if (& $switch.Emit) {
                $asmFlags += ('-D' + $switch.Define)
            }
            continue
        }
        $selector = Get-SelectorEntry -Name $name
        $value = Get-SelectorValue -Name $name
        if ($selector.Asm.ContainsKey($value)) {
            foreach ($define in $selector.Asm[$value]) {
                $asmFlags += ('-D' + $define)
            }
        }
    }

    # GCC may lower a C null dereference into UD2, which is newer than the 486.
    # These two translation units contain cold legacy error paths where that
    # transformation occurs. Preserve the original 386-compatible memory access
    # behavior in those files without disabling the optimization project-wide.
    $buildNumberHeader = Join-Path $outputRoot 'nitroquake-build.h'
    $cSourceExtraFlags = [ordered]@{
        'host.c'    = @('-include', $buildNumberHeader)
        'r_main.c'   = @('-fno-jump-tables')
        'mathlib.c'  = @('-fno-jump-tables')
        # Keep support-command control flow directly decodable. Embedded switch
        # pointers in .text change their apparent ISA whenever code moves.
        'host_cmd.c' = @('-fno-jump-tables')
        'pr_edict.c' = @('-fno-delete-null-pointer-checks')
        'wad.c'      = @('-fno-delete-null-pointer-checks')
    }
    $linkFingerprintFlags = @($optimizationLevel, $marchFlag, $mtuneFlag, '-s', '<objects>', '-lm', "-Wl,-Map=$linkMap", '-o', $executable)
    if ($DumpFlags) {
        # The link list is reported with a placeholder for the object files so
        # that the dump does not depend on the compile loop having run.
        [ordered]@{
            cpuTarget = $CpuTarget
            cpuModel = $cpuModel
            fpuModel = $fpuModel
            fpuRequired = $true
            floatingPointMode = $floatingPointMode
            march = $marchFlag
            mtune = $mtuneFlag
            optimizationProfile = $OptimizationProfile
            optimizationLevel = $optimizationLevel
            profileSuffix = $profileSuffix
            outputRoot = $outputRoot
            objectRoot = $objectRoot
            executable = $executable
            manifest = $manifestName
            cSourceCount = $allCSources.Count
            standaloneCSourceCount = $cSources.Count
            includedCSources = @($includedCSources)
            allAssemblySourceCount = $allAsmSources.Count
            assemblySourceCount = $asmSources.Count
            cFlags = @($cFlags)
            cSourceExtraFlags = $cSourceExtraFlags
            asmFlags = @($asmFlags)
            linkFlags = $linkFingerprintFlags
            cSources = @($cSources.Name)
            assemblySources = @($asmSources.Name)
        } | ConvertTo-Json -Depth 5
        return
    }

    # Past this point the build touches the filesystem. Everything above -- the
    # inventory pin, the flag arithmetic, the source lists -- is inspection, and
    # -DumpFlags returns before any of it writes. See the note by the -Clean block.
    New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $objectRoot -Force | Out-Null

    . (Join-Path $PSScriptRoot 'build-number.ps1')
    $buildIdentity = New-NitroQuakeBuildIdentity -RepoRoot $repoRoot -HeaderPath $buildNumberHeader
    Write-Host $buildIdentity.version
    Write-Host $buildIdentity.build

    $objects = @()

    foreach ($source in $allSources) {
        $object = Join-Path $objectRoot ($source.BaseName + '.obj')
        $flags = if ($source.Extension -ieq '.c') { $cFlags } else { $asmFlags }
        if ($source.Extension -ieq '.c' -and $cSourceExtraFlags.Contains($source.Name)) {
            $flags = @($flags) + @($cSourceExtraFlags[$source.Name])
        }
        Write-Host "Compiling $($source.Name)"
        if ($source.Extension -ieq '.c') {
            & $compiler @flags -c $source.FullName -o $object
        }
        else {
            # Preprocess maintained assembly once, retain it, then assemble that
            # exact stream. No C-to-assembly generation occurs here.
            $preprocessedAssembly = Join-Path $objectRoot ($source.BaseName + '.pp.s')
            & $compiler @flags -E $source.FullName -o $preprocessedAssembly
            if ($LASTEXITCODE -ne 0) { throw "Assembly preprocessing failed for '$($source.Name)'." }
            & $compiler -c -x assembler $preprocessedAssembly -o $object
        }
        if ($LASTEXITCODE -ne 0) {
            throw "DJGPP compilation failed for '$($source.Name)' with exit code $LASTEXITCODE."
        }
        $objects += $object
    }

    Write-Host "Linking $executableName"
    $linkFlags = @($optimizationLevel, $marchFlag, $mtuneFlag, '-s') + $objects + @('-lm', "-Wl,-Map=$linkMap", '-o', $executable)
    & $compiler @linkFlags
    if ($LASTEXITCODE -ne 0) {
        throw "DJGPP link failed with exit code $LASTEXITCODE."
    }

    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "Link reported success but '$executable' was not created."
    }

    $format = (& $objdump -f $executable | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect the linked DOS executable with objdump.'
    }
    if ($format -notmatch 'coff-go32') {
        throw ("The linked file does not report the expected COFF/GO32 format:" + [Environment]::NewLine + $format)
    }

    # --- Blocking ISA gate -------------------------------------------------
    # The object audit is the instruction-level gate for the selected target.
    # Its ratchet rejects new or increasing above-target encodings; the i486
    # release baseline is zero. Unknown instructions and non-exempt P6
    # instructions always fail. See tools\golden\isa-baseline.json.
    $isaBaselinePath = Join-Path $PSScriptRoot 'golden\isa-baseline.json'
    $isaAuditScript = Join-Path $PSScriptRoot 'isa-audit.ps1'
    # Each executable variant owns its evidence even when selector sets share a
    # profile directory. qprof must never replace quake.exe's instruction proof.
    $isaReportRoot = Join-Path $outputRoot ('isa-' + [IO.Path]::GetFileNameWithoutExtension($executableName))
    New-Item -ItemType Directory -Path $isaReportRoot -Force | Out-Null
    $isaReportPath = Join-Path $isaReportRoot 'isa-audit.json'
    $linkedIsaReportPath = Join-Path $isaReportRoot 'isa-audit-linked.json'
    $projectProofIndex = $null
    if (-not $SkipIsaAudit -and $CpuTarget -eq 'i486') {
        $proofRunId = Get-Date -Format 'yyyyMMdd-HHmmssfff'
        $projectProofRoot = Join-Path $isaReportRoot ('project-source-' + $proofRunId)
        $projectInputsPath = Join-Path $isaReportRoot ('project-inputs-' + $proofRunId + '.json')
        $projectInputs = @(foreach ($unit in $allSources) {
            $assemblyName = $unit.BaseName + $(if ($unit.Extension -ieq '.c') { '.s' } else { '.pp.s' })
            [ordered]@{source=$unit.FullName;object=(Join-Path $objectRoot ($unit.BaseName + '.obj'));
                assembly=(Join-Path $objectRoot $assemblyName);handwrittenAssembly=($unit.Extension -ine '.c')}
        })
        ConvertTo-Json -InputObject $projectInputs -Depth 5 | Set-Content -LiteralPath $projectInputsPath -Encoding UTF8
        & python (Join-Path $PSScriptRoot 'project-source-proofs.py') --inputs $projectInputsPath `
            --compiler $compiler --output $projectProofRoot
        if ($LASTEXITCODE -ne 0) { throw 'Exact project source/instruction boundary reproduction failed.' }
        $projectProofIndex = Join-Path $projectProofRoot 'proof-index.json'
    }


    $isaExemptions = @('crc.obj:_crctable')
    # These are linker-runtime data, not executable instructions. The CRC table
    # is 256 words at .text+0x40; doserr2e's _map byte table is .text+0x30..12f.
    # DJGPP 12.2 libc's doprnt dispatch table is 123 relocated 32-bit text
    # pointers at .text offsets 0x2dc..0x4c7, indexed by the preceding indirect
    # jump. libc dpmiexcp's _except_to_sig has a 17-entry pointer table at
    # .text+0x2b8..0x2fb. Every exemption is applied only to its data range in
    # both objects and the linked executable.
    $linkedIsaExemptions = @()
    $linkedIsaExemptRanges = @(
        'crc.obj:.text:0x40:0x240',
        'libc-doserr2e.obj:.text:0x30:0x130',
        'libc-doprnt.obj:.text:0x2dc:0x4c8',
        'libc-dpmiexcp.obj:.text:0x2b8:0x2fc'
    )
    $isaExemptRanges = @()
    $hostCmdObjectPath = Join-Path $objectRoot 'host_cmd.obj'
    if (Test-Path -LiteralPath $hostCmdObjectPath -PathType Leaf) {
        $hostCmdSymbolLines = @(& $objdump -t $hostCmdObjectPath)
        if ($LASTEXITCODE -ne 0) { throw "objdump -t failed for '$hostCmdObjectPath'." }
        $hostCmdHeaders = @(& $objdump -h $hostCmdObjectPath)
        if ($LASTEXITCODE -ne 0) { throw "objdump -h failed for '$hostCmdObjectPath'." }
        $hostCmdTextHeaders = @($hostCmdHeaders | Where-Object { $_ -match '^\s*\d+\s+\.text\s+' })
        if ($hostCmdTextHeaders.Count -ne 1) { throw 'Expected one host_cmd .text section.' }
        $hostCmdTextNumber = [int]([regex]::Match($hostCmdTextHeaders[0], '^\s*(\d+)').Groups[1].Value) + 1
        $modeNameTextPattern = '\(sec\s+' + $hostCmdTextNumber + '\).*\s_mode_names\.\d+$'
        # A label table already stored in .data needs no .text boundary handling.
        $modeNameSymbolLines = @($hostCmdSymbolLines | Where-Object { $_ -match $modeNameTextPattern })
        if ($modeNameSymbolLines.Count -gt 1) {
            throw "Expected at most one benchmark mode-name table in '$hostCmdObjectPath'."
        }
        if ($modeNameSymbolLines.Count -eq 1) {
            $modeNameSymbolLine = [string]$modeNameSymbolLines[0]
            $modeNameMatch = [regex]::Match($modeNameSymbolLine, '0x(?<address>[0-9a-fA-F]+) (?<symbol>_mode_names\.\d+)$')
            if (-not $modeNameMatch.Success) {
                throw "Could not parse the benchmark mode-name table symbol in '$hostCmdObjectPath': $modeNameSymbolLine"
            }
            $modeNameSymbol = $modeNameMatch.Groups['symbol'].Value
            $modeNameStart = [Convert]::ToInt64($modeNameMatch.Groups['address'].Value, 16)
            $modeNameEnd = $modeNameStart + (5 * 4)

            # DJGPP places this five-pointer benchmark label table in .text.
            # A linear disassembly interprets the third pointer's 0f 5d bytes as
            # MINPS, although all five words are linker relocations to .text.
            # Discover the range from the local symbol and fail closed unless
            # every expected word has exactly one DIR32 relocation.
            $hostCmdRelocationLines = @(& $objdump -r $hostCmdObjectPath)
            if ($LASTEXITCODE -ne 0) { throw "objdump -r failed for '$hostCmdObjectPath'." }
            $currentRelocationSection = $null
            $modeNameRelocations = New-Object System.Collections.Generic.List[object]
            foreach ($relocationLine in $hostCmdRelocationLines) {
                $sectionMatch = [regex]::Match($relocationLine, '^RELOCATION RECORDS FOR \[(?<section>[^\]]+)\]:$')
                if ($sectionMatch.Success) {
                    $currentRelocationSection = $sectionMatch.Groups['section'].Value
                    continue
                }
                if ($currentRelocationSection -ne '.text') { continue }
                $relocationMatch = [regex]::Match($relocationLine, '^\s*(?<offset>[0-9a-fA-F]+)\s+(?<type>\S+)\s+(?<target>\S+)')
                if (-not $relocationMatch.Success) { continue }
                $relocationOffset = [Convert]::ToInt64($relocationMatch.Groups['offset'].Value, 16)
                if ($relocationOffset -ge $modeNameStart -and $relocationOffset -lt $modeNameEnd) {
                    $modeNameRelocations.Add([pscustomobject]@{
                        offset = $relocationOffset
                        type = $relocationMatch.Groups['type'].Value
                        target = $relocationMatch.Groups['target'].Value
                    })
                }
            }
            if ($modeNameRelocations.Count -ne 5) {
                throw "Expected five relocated pointers for $modeNameSymbol in '$hostCmdObjectPath'; found $($modeNameRelocations.Count)."
            }
            for ($pointerIndex = 0; $pointerIndex -lt 5; $pointerIndex++) {
                $expectedOffset = $modeNameStart + (4 * $pointerIndex)
                $pointerRelocation = @($modeNameRelocations | Where-Object { $_.offset -eq $expectedOffset })
                if ($pointerRelocation.Count -ne 1 -or
                    $pointerRelocation[0].type -ne 'dir32' -or
                    $pointerRelocation[0].target -ne '.text') {
                    throw "Benchmark mode-name table word at .text+0x$('{0:x}' -f $expectedOffset) is not one DIR32 .text relocation."
                }
            }

            $modeNameRange = 'host_cmd.obj:.text:0x{0:x}:0x{1:x}' -f $modeNameStart, $modeNameEnd
            $isaExemptRanges += $modeNameRange
            $linkedIsaExemptRanges += $modeNameRange
            Write-Host ("Recognized relocated benchmark label data: {0} ({1})" -f $modeNameRange, $modeNameSymbol)
        }
    }
    # Audit exactly the objects this build produced.  A build recompiles sources
    # in place, so an object directory also holds objects left behind by selector
    # sets that are no longer active; auditing the directory would make the count
    # depend on build history rather than on the current sources, which made the
    # i386 figure oscillate between 1027 and 1029 across identical builds.
    $isaObjectNames = @($objects | ForEach-Object { Split-Path -Leaf $_ })

    $strictProjectParameters = @{}
    if ($null -ne $projectProofIndex) {
        $strictProjectParameters.ObjectCodeDataProofJson = $projectProofIndex
        # Source directives and exact reassembly replace every legacy waiver.
        $isaExemptions = @()
        $isaExemptRanges = @()
        $linkedIsaExemptions = @()
        $linkedIsaExemptRanges = @()
    }
    if ($SkipIsaAudit) {
        Write-Host 'ISA audit: SKIPPED (-SkipIsaAudit) -- this build is not a promotion candidate.'
    }
    else {
        & $isaAuditScript @strictProjectParameters -BuildRoot $outputRoot -ObjectRoot $objectRoot `
            -ExeName $executableName -MaxIsa $CpuTarget -SkipExecutable `
            -ObjectNames $isaObjectNames `
            -OutputJson $isaReportPath -Exempt $isaExemptions -ExemptRange $isaExemptRanges
        if (-not (Test-Path -LiteralPath $isaReportPath -PathType Leaf)) {
            throw "isa-audit.ps1 did not write a report to '$isaReportPath'; the ISA gate cannot be evaluated."
        }
    }

    if ((-not $SkipIsaAudit) -or $RecordIsaBaseline) {
        $isaReport = Get-Content -LiteralPath $isaReportPath -Raw | ConvertFrom-Json
        $isaBaseline = Get-Content -LiteralPath $isaBaselinePath -Raw | ConvertFrom-Json
        # Key on the variant as well as the target.  -Benchmark compiles the
        # ~4335-line bench harness in host_cmd.c and -Instrumentation compiles
        # the PROFILE486 counters, so those builds are strictly larger code sets
        # with their own instruction mix, so each variant has its own baseline.
        $isaVariantKey = '{0}/{1}' -f $CpuTarget, $executableName
        $isaTarget = $isaBaseline.targets.PSObject.Properties[$isaVariantKey]

        # Normalise the report's "encoding (isa)" strings into a plain count map.
        $isaFound = [ordered]@{}
        foreach ($entry in @($isaReport.violationEncodings)) {
            $isaFound[$entry.encoding] = [int]$entry.count
        }
        $isaFoundTotal = [int](($isaFound.Values | Measure-Object -Sum).Sum)

        # Encodings that are string data decoded as instructions.  DJGPP emits
        # string literals into .text, so objdump reads them as code; 62 and 63 are
        # the two opcodes this tree's message text decodes into ("ad" -> bound,
        # "ck " -> arpl, and so on).  They are excluded from enforcement, not
        # hidden: they still print, and their count still tracks the message
        # strings rather than any instruction.  They cannot be exempted by symbol
        # the way crc.obj:_crctable is, because they appear in ~50 objects.  This
        # is the same defect tools\isa-audit-source.py avoids at source level, and
        # it cannot affect the i486 variants because arpl and bound are i486
        # instructions.  See noiseEncodings in tools\golden\isa-baseline.json.
        $isaNoise = @('62', '63')
        $isaNoiseSeen = @($isaFound.Keys | Where-Object { $isaNoise -contains ($_ -split ' ')[0] })
        $isaNoiseTotal = [int](($isaNoiseSeen | ForEach-Object { $isaFound[$_] } | Measure-Object -Sum).Sum)
        $isaEnforced = New-Object System.Collections.Generic.List[string]
        foreach ($key in $isaFound.Keys) {
            if ($isaNoise -notcontains ($key -split ' ')[0]) {
                $isaEnforced.Add($key)
            }
        }
        $isaEnforcedTotal = $isaFoundTotal - $isaNoiseTotal

        if ($RecordIsaBaseline) {
            if ($null -eq $isaTarget) {
                throw "Cannot record an ISA baseline for variant '$isaVariantKey': it is absent from $isaBaselinePath. Add the variant first."
            }
            $recorded = [ordered]@{}
            foreach ($key in $isaEnforced) { $recorded[$key] = $isaFound[$key] }
            $isaTarget.Value.encodings = $recorded
            $isaTarget.Value.totalAbove = $isaEnforcedTotal
            $isaTarget.Value.recorded = (Get-Date).ToString('yyyy-MM-dd')
            $isaBaseline | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $isaBaselinePath -Encoding ASCII
            Write-Host ("ISA baseline recorded for {0}: {1} enforced above-{2} instruction(s) (+{3} string-data decode, not enforced)." -f
                $isaVariantKey, $isaEnforcedTotal, $CpuTarget, $isaNoiseTotal)
            Write-Host ('  diff {0} and confirm every changed figure is one you intended to change.' -f $isaBaselinePath)
        }
        elseif ($null -eq $isaTarget) {
            throw (("No ISA baseline recorded for variant '{0}'. The gate fails closed: record one with" -f $isaVariantKey) +
            ' -RecordIsaBaseline, or read tools\golden\isa-baseline.json.')
        }
        else {
            $isaFailures = New-Object System.Collections.Generic.List[string]

            if ([int]$isaReport.unclassifiedCount -ne 0) {
                $isaFailures.Add(("unclassified instructions: {0} (must be 0; an unclassified instruction never passes)" -f $isaReport.unclassifiedCount))
            }

            # p6 is MMX/SSE/3DNow and is never acceptable in this tree, so it is
            # absolute rather than ratcheted -- but the CRC table's exemption is
            # what keeps it out of the violation list, so it is counted here too.
            $isaP6 = [int]$isaReport.isaTotals.p6
            $isaP6Exempt = [int]$isaReport.exemptedCount
            if (($isaP6 - $isaP6Exempt) -gt 0) {
                $isaFailures.Add(("non-exempt p6 (MMX/SSE) instructions: {0} (must be 0)" -f ($isaP6 - $isaP6Exempt)))
            }

            $isaRecorded = $isaTarget.Value.encodings
            # Noise was computed above, before the record branch, so both paths
            # compare the same enforced set.
            foreach ($key in $isaEnforced) {
                $recordedCount = 0
                if ($null -ne $isaRecorded -and
                    @($isaRecorded.PSObject.Properties | ForEach-Object { $_.Name }) -contains $key) {
                    $recordedCount = [int]$isaRecorded.$key
                }
                if ($isaFound[$key] -gt $recordedCount) {
                    $isaFailures.Add(("encoding '{0}': {1} above baseline {2}" -f $key, $isaFound[$key], $recordedCount))
                }
            }
            $isaRemoved = @()
            if ($null -ne $isaRecorded) {
                # Empty JSON objects have no adapted Properties.Name member
                # under StrictMode. Enumerate the property collection itself so
                # a valid zero-above-target baseline produces an empty key list.
                $isaRecordedKeys = @($isaRecorded.PSObject.Properties | ForEach-Object { $_.Name })
                foreach ($key in $isaRecordedKeys) {
                    if (-not ($isaFound.Keys -contains $key)) {
                        $isaRemoved += $key
                    }
                }
            }

            $isaProgress = if ($null -ne $isaTarget.Value.totalAbove -and [int]$isaTarget.Value.totalAbove -gt 0) {
                'baseline {0}, now {1}' -f $isaTarget.Value.totalAbove, $isaEnforcedTotal
            }
            else {
                '{0}' -f $isaEnforcedTotal
            }
            Write-Host ('ISA gate {0}: {1} enforced above-{2} instruction(s) [{3}], {4} unclassified, {5} exempt, {6} not enforced.' -f
                $(if ($isaFailures.Count -eq 0) { 'PASS' } else { 'FAIL' }),
                $isaEnforcedTotal, $CpuTarget, $isaProgress, $isaReport.unclassifiedCount, $isaReport.exemptedCount, $isaNoiseTotal)
            if ($isaNoiseSeen.Count -gt 0) {
                Write-Host ('  not enforced, string data decoded as code: {0} ({1} instruction(s))' -f
                    ($isaNoiseSeen -join ', '),
                    (($isaNoiseSeen | ForEach-Object { $isaFound[$_] }) | Measure-Object -Sum).Sum)
            }

            if ($isaRemoved.Count -gt 0) {
                Write-Host ('  cleared since the baseline: {0} -- ratchet with -RecordIsaBaseline.' -f ($isaRemoved -join ', '))
            }
            if ($isaFailures.Count -gt 0) {
                Write-Host ('  {0}' -f ($isaFailures -join [Environment]::NewLine + '  '))
                throw (("ISA gate failed for variant '{0}'. The nominal target is a ratchet, not yet an absolute pass:" -f $isaVariantKey) +
                ' an above-target instruction count regressed. See tools\golden\isa-baseline.json and the' +
                " 'A separate i386 codepath exists' entry in ASM486-HANDOFF.md.")
            }
        }
    }

    if ((-not $SkipIsaAudit) -and $CpuTarget -eq 'i486') {
        & (Join-Path $PSScriptRoot 'verify-executable-isa.ps1') -BuildRoot $outputRoot -MapPath $linkMap `
            -ReportRoot $isaReportRoot -ProjectProofIndex $projectProofIndex `
            -ExecutableName $executableName -ObjectRoot $objectRoot -ObjectNames $isaObjectNames
        if (-not (Test-Path -LiteralPath $linkedIsaReportPath -PathType Leaf)) {
            throw 'The linked ISA audit did not produce a report; the executable compatibility gate cannot be evaluated.'
        }
        $linkedIsaReport = Get-Content -LiteralPath $linkedIsaReportPath -Raw | ConvertFrom-Json
        if (-not $linkedIsaReport.pass -or [int]$linkedIsaReport.instructionAudit.linkedInstructionsVerified -le 0) {
            throw 'The linked executable ISA audit did not inspect an instruction stream.'
        }
    }
    elseif ($CpuTarget -eq 'i386') {
        Write-Host 'Linked executable i486 audit: skipped for the separate i386 target.'
    }

    # The build passed.  Record what it was made from, so every runner can tell
    # whether the executable it is about to test is this build rather than an
    # older one that happens to sit at the same path.  The builder is the only
    # component that knows, so it is the only one that can write this: a runner
    # invoked with -SkipBuild after somebody else's build has nothing else to
    # check against, and "the file exists" is not evidence of anything.
    #
    # Placed after the ISA gate deliberately.  A build that failed the gate throws
    # before reaching this, so a failed build never leaves a fingerprint behind
    # claiming the tree matches.
    . (Join-Path $PSScriptRoot 'common.ps1')
    # The same fields -DumpFlags emits, so a runner's digest and this one are the
    # same digest.  outputRoot and executable are included because they are part of
    # the identity: -Benchmark and -Instrumentation change the name and the
    # directory, and the profile suffix alone does not distinguish a release build
    # from its bench sibling.
    $fingerprintConfig = [pscustomobject]@{
        outputRoot    = $outputRoot
        profileSuffix = $profileSuffix
        cFlags        = @($cFlags)
        asmFlags      = @($asmFlags)
        executable    = $executable
        cSourceExtraFlags = $cSourceExtraFlags
        linkFlags = $linkFingerprintFlags
    }
    # Bind freshness to the inventory actually embedded at build start. A report
    # added during compilation must leave this binary stale for the next runner.
    $buildFingerprint = Get-BuildFingerprint -RepoRoot $repoRoot -Resolved $fingerprintConfig `
        -OptimizationInventorySha256 $buildIdentity.inventory.inventorySha256
    Set-BuildFingerprint -Executable $executable -Fingerprint $buildFingerprint

    $version = ((& $compiler --version | Select-Object -First 1).ToString()).Trim()
    $commit = $null
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($null -ne $git) {
        $commit = ((& $git.Source -C $repoRoot rev-parse HEAD 2>$null).ToString()).Trim()
    }
    $manifest = [ordered]@{
        buildNumber = $buildIdentity.number
        productVersion = $buildIdentity.version
        productBuild = $buildIdentity.build
        optimizationAttempts = $buildIdentity.inventory
        buildNumberHeaderSha256 = (Get-FileHash -LiteralPath $buildNumberHeader -Algorithm SHA256).Hash
        compiler = $version
        target = $toolManifest.djgpp.target
        cpuTarget = $CpuTarget
        cpuModel = $cpuModel
        fpuModel = $fpuModel
        fpuRequired = $true
        floatingPointMode = $floatingPointMode
        march = $marchFlag
        mtune = $mtuneFlag
        cSourceCount = $allCSources.Count
        standaloneCSourceCount = $cSources.Count
        includedCSourceCount = $includedCSources.Count
        includedCSources = $includedCSources
        assemblySourceCount = $asmSources.Count
        benchmarkBuild = [bool]$Benchmark
        profileBuild = [bool]$Instrumentation
        linkMap = $linkMap
    }

    # The selector echo, in the order the manifest has always listed it. That order
    # is SuffixOrder minus the three selectors already emitted above, which is
    # checked rather than assumed -- a fourth hand-maintained list here is exactly
    # what this refactor is removing.
    foreach ($name in $script:ManifestSelectorOrder) {
        $selector = Get-SelectorEntry -Name $name
        $manifest[$selector.Manifest] = Get-SelectorValue -Name $name
    }

    $manifest['optimizationProfile'] = $OptimizationProfile
    $manifest['optimizationLevel'] = $optimizationLevel
    $manifest['textureAxisCacheEntries'] = $TextureAxisCacheEntries
    $manifest['cSources'] = @($cSources.Name)
    $manifest['assemblySources'] = @($asmSources.Name)
    $manifest['sourceCommit'] = $commit
    $manifest['executable'] = $executable
    $manifest['objectRoot'] = $objectRoot
    $manifest['executableSha256'] = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash
    $manifest['compatibilityPolicySha256'] = Get-CompatibilityPolicyFingerprint -RepoRoot $repoRoot
    $manifest['isaAuditStatus'] = if ($SkipIsaAudit) { 'SKIPPED' } else { 'PASS' }
    $manifest['isaAuditReport'] = if ($SkipIsaAudit) { $null } else { $isaReportPath }
    $manifest['isaAuditReportSha256'] = if ($SkipIsaAudit) { $null } else { (Get-FileHash -LiteralPath $isaReportPath -Algorithm SHA256).Hash }
    $manifest['isaLinkedAuditReport'] = if ($SkipIsaAudit -or $CpuTarget -ne 'i486') { $null } else { $linkedIsaReportPath }
    $manifest['isaLinkedAuditReportSha256'] = if ($SkipIsaAudit -or $CpuTarget -ne 'i486') { $null } else { (Get-FileHash -LiteralPath $linkedIsaReportPath -Algorithm SHA256).Hash }
    $manifest['sourceBoundIsa'] = (-not $SkipIsaAudit -and $CpuTarget -eq 'i486')
    $manifest['embeddedStartupIsa'] = if ($SkipIsaAudit -or $CpuTarget -ne 'i486') { $null } else { $linkedIsaReport.embeddedStartupIsa }
    $manifest['actualRelocatedIsa'] = if ($SkipIsaAudit -or $CpuTarget -ne 'i486') { $null } else { $linkedIsaReport.actualRelocatedIsa }
    $manifest['externalDpmiProviderIsa'] = if ($SkipIsaAudit -or $CpuTarget -ne 'i486') { $null } else { $linkedIsaReport.externalDpmiProvider }

    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outputRoot $manifestName) -Encoding ASCII

    Write-Host "Built $executable"
    Write-Host "C sources: $($allCSources.Count) retained, $($cSources.Count) standalone; assembly sources: $($asmSources.Count)"} finally {
    $env:DJDIR = $oldDjdir
    $env:GCC_EXEC_PREFIX = $oldGccExecPrefix
    $env:PATH = $oldPath
}

[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$Benchmark,
    [switch]$Instrumentation,
    [switch]$NoBootstrap,
    # Minimum CPU the build targets.  i486 is the default and the retained
    # release profile; i386 is a separate, separately-audited codepath whose
    # object directory and executable never share the i486 output tree.  The
    # i486 path must stay byte-identical: -CpuTarget i486 resolves to the same
    # -march/-mtune pair, the same suffix, and the same output paths as before
    # this parameter existed.  See tools\test-build-dos.py.
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    # Print the resolved flag lists and output paths as JSON and exit without
    # compiling.  tools\test-build-dos.py drives this so the i486 flag lists can
    # be golden-pinned without the guard having to re-implement the profile
    # suffix arithmetic.
    [switch]$DumpFlags,
    # Blocking ISA gate.  On by default: the build audits its own objects after
    # the link and throws if an above-target instruction count regresses against
    # tools\golden\isa-baseline.json, if a new above-target encoding appears, or
    # if any instruction is unclassified.  -SkipIsaAudit downgrades this to the
    # report-only mode tools\isa-audit.ps1 already supports, which is for
    # quantifying a residual and is never a promotion path.
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
    [string]$ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Instrumentation -and -not $Benchmark) {
    throw 'Profile builds require -Benchmark.'
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

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
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
$profileSuffixParts = @()
# The architecture token is emitted only when the target is not the retained
# i486 release profile, so every i486 output directory keeps the exact name it
# has always had.  The token is `i386`, not the `march386` used by the reverted
# 2026-10-03 experiment, so a stale directory from that experiment can never be
# mistaken for -- or silently reused as -- a build of this target.
if ($CpuTarget -eq 'i386') {
    $profileSuffixParts += 'i386'
}
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
elseif ($TextureSpanStores -eq 'stosw') {
    $profileSuffixParts += 'spanstosw'
}
if ($TextureSpanTailStores -eq 'word') {
    $profileSuffixParts += 'spantailword'
}
if ($TextureSpanRowPath -eq 'norowcross') {
    $profileSuffixParts += 'spannorow'
}
if ($TextureSpanLoadOrder -eq 'loadfirst') {
    $profileSuffixParts += 'spanloadfirst'
}
if ($TextureSpanAddressing -eq 'branch') {
    $profileSuffixParts += 'spanaddrbranch'
}
if ($AliasSpanAddressing -eq 'branch') {
    $profileSuffixParts += 'aliasspanaddrbranch'
}
if ($ZSpanNegativeUnroll -eq 'unroll8') {
    $profileSuffixParts += 'zneg8'
}
else {
    $profileSuffixParts += 'zneg4'
}
if ($SurfaceBlockMip0Rows -eq 'unroll4') {
    $profileSuffixParts += 'surf0rows4'
}
elseif ($SurfaceBlockMip0Rows -eq 'unroll8') {
    $profileSuffixParts += 'surf0rows8'
}
elseif ($SurfaceBlockMip0Rows -eq 'unroll16') {
    $profileSuffixParts += 'surf0rows16'
}
if ($SurfaceBlockMip0HorizontalFlat -eq 'fast') {
    $profileSuffixParts += 'surf0hflat'
}
if ($SurfaceBlockMip1Rows -eq 'unroll8') {
    $profileSuffixParts += 'surf1rows8'
}
if ($SurfaceBlockMip1HorizontalFlat -eq 'fast') {
    $profileSuffixParts += 'surf1hflat'
}
if ($SurfaceBlockMip1IndexHoist -eq 'hoist') {
    $profileSuffixParts += 'surf1hflatidxhoist'
}
if ($EdgeScanProbe -ne 'control') {
    $profileSuffixParts += ('edgescanprobe' + $EdgeScanProbe)
}
if ($SpanSetupProbe -ne 'control') {
    $profileSuffixParts += ('spansetup' + $SpanSetupProbe)
}
if ($RenderFaceProbe -ne 'control') {
    $profileSuffixParts += ('rfprobe' + $RenderFaceProbe)
}
if ($AliasGlueProbe -ne 'control') {
    $profileSuffixParts += ('agprobe' + $AliasGlueProbe)
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
if ($AliasPrepareImplementation -eq 'local') {
    $profileSuffixParts += 'aliaslocal'
}
if ($AliasMatrixCompositionImplementation -eq 'special') {
    $profileSuffixParts += 'aliasmatrixspecial'
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
if ($FusedLightMapImplementation -eq 'asm') {
    $profileSuffixParts += 'fusedlightmapasm'
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
if ($BspFrameCountImplementation -eq 'local') {
    $profileSuffixParts += 'bspframecache'
}
if ($GibTrailHorizontalIntegration -eq 'skipzero') {
    $profileSuffixParts += 'gibskipzero'
}
if ($Instrumentation) {
    $profileSuffixParts += 'profile'
}
$profileSuffix = if ($profileSuffixParts.Count) {
    '-' + ($profileSuffixParts -join '-')
}
else {
    ''
}
$outputRoot = Join-Path $repoRoot ('out\dos' + $profileSuffix)
$objectDirectoryName = 'obj'
if ($Benchmark) {
    $objectDirectoryName += '-bench'
}
if ($Instrumentation) {
    $objectDirectoryName += '-profile'
}
$objectRoot = Join-Path $outputRoot $objectDirectoryName
$executableName = if ($Instrumentation) { 'qprof.exe' } elseif ($Benchmark) { 'qbench.exe' } else { 'quake.exe' }
$executable = Join-Path $outputRoot $executableName
$manifestName = if ($Benchmark) { 'build-manifest-bench.json' } else { 'build-manifest.json' }

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
elseif ($outputRoot -ne $i486RootForThisSelectorSet) {
    throw "The i486 output root '$outputRoot' does not match the i486/i386 separation ('$i486RootForThisSelectorSet' vs '$i386RootForThisSelectorSet')."
}

if ($Clean -and (Test-Path -LiteralPath $outputRoot)) {
	if ($Benchmark) {
		foreach ($benchmarkPath in @($objectRoot, $executable,
				(Join-Path $outputRoot $manifestName))) {
			if (Test-Path -LiteralPath $benchmarkPath) {
				Remove-Item -LiteralPath $benchmarkPath -Recurse -Force
			}
		}
	}
	else {
		Remove-Item -LiteralPath $outputRoot -Recurse -Force
	}
}
New-Item -ItemType Directory -Path $objectRoot -Force | Out-Null

$allCSources = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.c' -File | Sort-Object Name)
$includedCSources = @('net_comx.c')
$cSources = @($allCSources | Where-Object { $_.Name -notin $includedCSources })
$allAsmSources = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.s' -File | Sort-Object Name)
$asmSources = @($allAsmSources | Where-Object {
	$Benchmark -or $MemoryImplementation -eq 'asm' -or
		$TextureAxisImplementation -eq 'asm' -or
		$SurfaceCacheImplementation -eq 'asm' -or
	$MipLevelImplementation -eq 'asm' -or
	$TextureAnimationImplementation -eq 'asm' -or
	$LightMapNormalizeImplementation -eq 'asm' -or
	$LightMapStylesImplementation -eq 'asm' -or
	$FusedLightMapImplementation -eq 'asm' -or
	$DynamicLightImplementation -eq 'asm' -or
	$BspPlaneDotImplementation -eq 'asm' -or
		$BspClipImplementation -eq 'asm' -or
		$AliasBBoxProjectImplementation -eq 'asm' -or
		$AliasTransformFinalImplementation -eq 'asm' -or
		$_.Name -ne 'asm486_experiments.s'
})
$allSources = @($cSources + $asmSources)

# The inventory pin.  The expected counts come from the golden manifest for this
# target rather than from literals here, so there is one place to edit when a
# source is legitimately added or removed instead of four: this script, the two
# manifests, and tools\test-build-dos.py.  The pin itself is unchanged -- a
# source file appearing or disappearing without the manifest being updated still
# fails the build, which is the point of the guard.
#
# -DumpFlags stays pure and does NOT read the manifest: tools\test-build-dos.py
# drives it and then compares its output against the manifest, so having it read
# the manifest for its own expectations would make the comparison circular.  The
# manifest's counts are read only on a real build, and test-build-dos.py keeps
# its own literal pin, so the invariant is still enforced independently.
$expectedAllCSourceCount = 83
$expectedStandaloneCSourceCount = 82
$expectedAllAssemblySourceCount = 21
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

$expectedAssemblySourceCount = if ($Benchmark -or $MemoryImplementation -eq 'asm' -or
	$TextureAxisImplementation -eq 'asm' -or $SurfaceCacheImplementation -eq 'asm' -or
	$MipLevelImplementation -eq 'asm' -or $TextureAnimationImplementation -eq 'asm' -or
	$LightMapNormalizeImplementation -eq 'asm' -or
	$LightMapStylesImplementation -eq 'asm' -or
	$FusedLightMapImplementation -eq 'asm' -or
	$DynamicLightImplementation -eq 'asm' -or
	$BspPlaneDotImplementation -eq 'asm' -or
		$BspClipImplementation -eq 'asm' -or $AliasBBoxProjectImplementation -eq 'asm' -or
		$AliasTransformFinalImplementation -eq 'asm') { $expectedAllAssemblySourceCount } else { $expectedAllAssemblySourceCount - 1 }
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
    $cFlags = @(
        "-I$sourceRoot",
        $optimizationLevel,
        $marchFlag,
        $mtuneFlag,
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
        "-DD_TEXAXIS_CACHE_SIZE=$TextureAxisCacheEntries"
    )
    if ($Benchmark) {
        $cFlags += '-DBENCH486'
    }
    if ($MemoryImplementation -eq 'asm') {
        $cFlags += '-DASM486_RUNTIME_MEMOPS'
    }
    if ($TextureAxisImplementation -eq 'asm') {
        $cFlags += '-DASM486_TEXTURE_AXIS_CACHE'
    }
    if ($SurfaceCacheImplementation -eq 'asm') {
        $cFlags += '-DASM486_SURFACE_CACHE_CHECK'
    }
    if ($MipLevelImplementation -eq 'asm') {
        $cFlags += '-DASM486_MIP_LEVEL'
    }
    if ($TextureAnimationImplementation -eq 'asm') {
        $cFlags += '-DASM486_TEXTURE_ANIMATION'
    }
    if ($LightMapNormalizeImplementation -eq 'asm') {
        $cFlags += '-DASM486_LIGHTMAP_NORMALIZE'
    }
    if ($LightMapStylesImplementation -eq 'asm') {
        $cFlags += '-DASM486_LIGHTMAP_STYLES'
    }
    if ($FusedLightMapImplementation -eq 'asm') {
        $cFlags += '-DASM486_FUSED_LIGHTMAP'
    }
    if ($DynamicLightImplementation -eq 'asm') {
        $cFlags += '-DASM486_DYNAMIC_LIGHTS'
    }
    if ($BspPlaneDotImplementation -eq 'asm') {
        $cFlags += '-DASM486_BSP_PLANE_DOT'
    }
    if ($BspClipImplementation -eq 'asm') {
        $cFlags += '-DASM486_BSP_CLIP'
    }
    if ($BspFrameCountImplementation -eq 'local') {
        $cFlags += '-DASM486_BSP_FRAME_COUNT'
    }
    if ($GibTrailHorizontalIntegration -eq 'skipzero') {
        $cFlags += '-DASM486_GIB_TRAIL_SKIP_ZERO_XY'
    }
    if ($AliasBBoxProjectImplementation -eq 'asm') {
        $cFlags += '-DASM486_ALIAS_BBOX_PROJECT'
    }
    if ($AliasTransformFinalImplementation -eq 'asm') {
        $cFlags += '-DASM486_ALIAS_TRANSFORM_FINAL'
    }
    if ($AliasPrepareImplementation -eq 'local') {
        $cFlags += '-DASM486_ALIAS_PREPARE_LOCAL'
    }
    if ($AliasMatrixCompositionImplementation -eq 'special') {
        $cFlags += '-DASM486_ALIAS_MATRIX_COMPOSE'
    }
    if ($TurbulentImplementation -eq 'c') {
        $cFlags += '-DASM486_TURBULENT_C'
    }
    if ($Instrumentation) {
        $cFlags += '-DPROFILE486'
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
    if ($CpuTarget -eq 'i386') {
        $asmFlags += '-DTARGET_I386'
    }
    if ($Instrumentation) {
        $asmFlags += '-DPROFILE486'
    }
    if ($TurbulentImplementation -eq 'stosb') {
        $asmFlags += '-DASM486_TURBULENT_STOSB'
    }
    if ($TextureSpanStores -eq 'word') {
        $asmFlags += '-DASM486_SPAN16_WORD_STORES'
    }
    elseif ($TextureSpanStores -eq 'stosw') {
        $asmFlags += '-DASM486_SPAN16_WORD_STORES'
        $asmFlags += '-DASM486_SPAN16_WORD_STOS'
    }
    elseif ($TextureSpanStores -eq 'dword') {
        $asmFlags += '-DASM486_SPAN16_DWORD_STORES'
    }
    elseif ($TextureSpanStores -eq 'loop') {
        $asmFlags += '-DASM486_SPAN16_LOOP_STOSB'
    }
    if ($TextureSpanRowPath -eq 'norowcross') {
        $asmFlags += '-DASM486_SPAN16_NO_ROW_CROSS'
    }
    if ($TextureSpanTailStores -eq 'word') {
        $asmFlags += '-DASM486_SPAN16_TAIL_WORD_STORES'
    }
    if ($TextureSpanLoadOrder -eq 'loadfirst') {
        $asmFlags += '-DASM486_SPAN16_LOAD_FIRST'
    }
    if ($TextureSpanAddressing -eq 'branch') {
        $asmFlags += '-DASM486_SPAN16_BRANCH_ADDRESS'
    }
    if ($AliasSpanAddressing -eq 'branch') {
        $asmFlags += '-DASM486_ALIAS_SPAN_BRANCH_ADDRESS'
    }
    if ($ZSpanNegativeUnroll -eq 'unroll8') {
        $asmFlags += '-DASM486_ZSPAN_NEG_UNROLL8'
    }
    if ($SurfaceBlockMip0Rows -eq 'unroll4') {
        $asmFlags += '-DASM486_SURF8_MIP0_ROWS4'
    }
    elseif ($SurfaceBlockMip0Rows -eq 'unroll8') {
        $asmFlags += '-DASM486_SURF8_MIP0_ROWS8'
    }
    elseif ($SurfaceBlockMip0Rows -eq 'unroll16') {
        $asmFlags += '-DASM486_SURF8_MIP0_ROWS16'
    }
    if ($SurfaceBlockMip0HorizontalFlat -eq 'fast') {
        $asmFlags += '-DASM486_SURF8_MIP0_HORIZONTAL_FLAT'
    }
    if ($SurfaceBlockMip1Rows -eq 'unroll8') {
        $asmFlags += '-DASM486_SURF8_MIP1_ROWS8'
    }
    if ($SurfaceBlockMip1HorizontalFlat -eq 'fast') {
        $asmFlags += '-DASM486_SURF8_MIP1_HORIZONTAL_FLAT'
    }
    if ($SurfaceBlockMip1IndexHoist -eq 'hoist') {
        $asmFlags += '-DASM486_SURF8_MIP1_INDEX_HOIST'
    }
    if ($EdgeScanProbe -ne 'control') {
        # Uppercased so one -D per probe value, matching the #ifdef form.
        # gas macros are not C macros and #error is inert under
        # -x assembler-with-cpp, so the define is the only reliable selector.
        $asmFlags += ('-DEDGE_SCAN_PROBE_' + $EdgeScanProbe.ToUpperInvariant())
    }
    if ($SpanSetupProbe -ne 'control') {
        $asmFlags += ('-DASM486_SPAN_SETUP_PROBE_' + $SpanSetupProbe.ToUpperInvariant())
    }
    if ($AliasGlueProbe -ne 'control') {
        $cFlags += '-DASM486_ALIAS_GLUE_PROBE'
        $cFlags += ('-DASM486_ALIAS_GLUE_PROBE_' + $AliasGlueProbe.ToUpperInvariant())
    }
    if ($RenderFaceProbe -ne 'control') {
        $cFlags += '-DASM486_RENDERFACE_PROBE'
        $cFlags += ('-DASM486_RENDERFACE_PROBE_' + $RenderFaceProbe.ToUpperInvariant())
    }
    if ($AliasProjectImplementation -eq 'asm') {
        $cFlags += '-DASM486_ALIAS_PROJECT'
    }
    if ($CpuTarget -eq 'i386') {
        # Selects the i386 variants in the hand-written assembly.  Defined for
        # the C sources too so that a single spelling works in both languages
        # under -x assembler-with-cpp.
        $cFlags += '-DTARGET_I386'
    }

    if ($DumpFlags) {
        # The link list is reported with a placeholder for the object files so
        # that the dump does not depend on the compile loop having run.
        [ordered]@{
            cpuTarget = $CpuTarget
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
            asmFlags = @($asmFlags)
            linkFlags = @($optimizationLevel, $marchFlag, $mtuneFlag, '-s', '<objects>', '-lm', '-o', $executable)
            cSources = @($cSources.Name)
            assemblySources = @($asmSources.Name)
        } | ConvertTo-Json -Depth 5
        return
    }

    $objects = @()

    foreach ($source in $allSources) {
        $object = Join-Path $objectRoot ($source.BaseName + '.obj')
        $flags = if ($source.Extension -ieq '.c') { $cFlags } else { $asmFlags }
        Write-Host "Compiling $($source.Name)"
        & $compiler @flags -c $source.FullName -o $object
        if ($LASTEXITCODE -ne 0) {
            throw "DJGPP compilation failed for '$($source.Name)' with exit code $LASTEXITCODE."
        }
        $objects += $object
    }

    Write-Host "Linking $executableName"
    $linkFlags = @($optimizationLevel, $marchFlag, $mtuneFlag, '-s') + $objects + @('-lm', '-o', $executable)
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
    # The nominal target is a claim this tree does not yet honour: the shipped
    # executable carries 161 `0f af` (imul r32,r/m32, Pentium) and would fault
    # on real hardware.  Until the multiply-elimination work reaches zero, the
    # gate is a ratchet -- it refuses to let the count go up -- rather than an
    # absolute pass, because an absolute pass would be red on day one and would
    # simply be switched off.  Hard rules (unclassified, and any non-exempt p6)
    # are absolute from the first build.  See tools\golden\isa-baseline.json.
    $isaBaselinePath = Join-Path $PSScriptRoot 'golden\isa-baseline.json'
    $isaAuditScript = Join-Path $PSScriptRoot 'isa-audit.ps1'
    $isaReportPath = Join-Path $outputRoot 'isa-audit.json'

    $isaExemptions = @('crc.obj:_crctable')
    # Audit exactly the objects this build produced.  A build recompiles sources
    # in place, so an object directory also holds objects left behind by selector
    # sets that are no longer active; auditing the directory would make the count
    # depend on build history rather than on the current sources, which made the
    # i386 figure oscillate between 1027 and 1029 across identical builds.
    $isaObjectNames = @($objects | ForEach-Object { Split-Path -Leaf $_ })

    if ($SkipIsaAudit) {
        Write-Host 'ISA audit: SKIPPED (-SkipIsaAudit) -- this build is not a promotion candidate.'
    }
    else {
        & $isaAuditScript -BuildRoot $outputRoot -ObjectRoot $objectRoot `
            -ExeName $executableName -MaxIsa $CpuTarget -SkipExecutable `
            -ObjectNames $isaObjectNames `
            -OutputJson $isaReportPath -Exempt $isaExemptions
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
        # with their own instruction mix: the i486 release build has 170
        # above-target instructions and its -Benchmark sibling has 173.  One
        # figure per target would have made every bench run trip the gate.
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
                if ($null -ne $isaRecorded -and ($isaRecorded.PSObject.Properties.Name -contains $key)) {
                    $recordedCount = [int]$isaRecorded.$key
                }
                if ($isaFound[$key] -gt $recordedCount) {
                    $isaFailures.Add(("encoding '{0}': {1} above baseline {2}" -f $key, $isaFound[$key], $recordedCount))
                }
            }
            $isaRemoved = @()
            if ($null -ne $isaRecorded) {
                foreach ($key in $isaRecorded.PSObject.Properties.Name) {
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
    }
    $buildFingerprint = Get-BuildFingerprint -RepoRoot $repoRoot -Resolved $fingerprintConfig
    Set-BuildFingerprint -Executable $executable -Fingerprint $buildFingerprint

    $version = ((& $compiler --version | Select-Object -First 1).ToString()).Trim()
    $commit = $null
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($null -ne $git) {
        $commit = ((& $git.Source -C $repoRoot rev-parse HEAD 2>$null).ToString()).Trim()
    }
    $manifest = [ordered]@{
        compiler = $version
        target = $toolManifest.djgpp.target
        cpuTarget = $CpuTarget
        march = $marchFlag
        mtune = $mtuneFlag
        cSourceCount = $allCSources.Count
        standaloneCSourceCount = $cSources.Count
        includedCSourceCount = $includedCSources.Count
        includedCSources = $includedCSources
        assemblySourceCount = $asmSources.Count
        benchmarkBuild = [bool]$Benchmark
        profileBuild = [bool]$Instrumentation
        memoryImplementation = $MemoryImplementation
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
        optimizationProfile = $OptimizationProfile
        optimizationLevel = $optimizationLevel
        textureAxisCacheEntries = $TextureAxisCacheEntries
        cSources = @($cSources.Name)
        assemblySources = @($asmSources.Name)
        sourceCommit = $commit
        executable = $executable
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outputRoot $manifestName) -Encoding ASCII

    Write-Host "Built $executable"
    Write-Host "C sources: $($allCSources.Count) retained, $($cSources.Count) standalone; assembly sources: $($asmSources.Count)"} finally {
    $env:DJDIR = $oldDjdir
    $env:GCC_EXEC_PREFIX = $oldGccExecPrefix
    $env:PATH = $oldPath
}

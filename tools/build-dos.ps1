[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$Benchmark,
    [switch]$Instrumentation,
    [switch]$NoBootstrap,
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

$sourceRoot = Join-Path $repoRoot 'WinQuake'
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
$expectedAssemblySourceCount = if ($Benchmark -or $MemoryImplementation -eq 'asm' -or
	$TextureAxisImplementation -eq 'asm' -or $SurfaceCacheImplementation -eq 'asm' -or
	$MipLevelImplementation -eq 'asm' -or $TextureAnimationImplementation -eq 'asm' -or
	$LightMapNormalizeImplementation -eq 'asm' -or
	$LightMapStylesImplementation -eq 'asm' -or
	$FusedLightMapImplementation -eq 'asm' -or
	$DynamicLightImplementation -eq 'asm' -or
	$BspPlaneDotImplementation -eq 'asm' -or
	$BspClipImplementation -eq 'asm' -or $AliasBBoxProjectImplementation -eq 'asm' -or
	$AliasTransformFinalImplementation -eq 'asm') { 21 } else { 20 }
if (($allCSources.Count -ne 83) -or ($cSources.Count -ne 82) -or
	($allAsmSources.Count -ne 21) -or ($asmSources.Count -ne $expectedAssemblySourceCount)) {
    throw "Expected 83 retained C sources (82 standalone), 21 total assembly sources, and $expectedAssemblySourceCount active assembly sources, found $($allCSources.Count) C ($($cSources.Count) standalone), $($allAsmSources.Count) total assembly, and $($asmSources.Count) active assembly."
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
    $cFlags = @(
        "-I$sourceRoot",
        $optimizationLevel,
        '-march=i486',
        '-mtune=i486',
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
        '-march=i486',
        '-mtune=i486',
        '-falign-loops=16',
        '-falign-jumps=16',
        '-falign-functions=16',
        '-x',
        'assembler-with-cpp'
    )
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
    $linkFlags = @($optimizationLevel, '-march=i486', '-mtune=i486', '-s') + $objects + @('-lm', '-o', $executable)
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

    $version = ((& $compiler --version | Select-Object -First 1).ToString()).Trim()
    $commit = $null
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($null -ne $git) {
        $commit = ((& $git.Source -C $repoRoot rev-parse HEAD 2>$null).ToString()).Trim()
    }
    $manifest = [ordered]@{
        compiler = $version
        target = $toolManifest.djgpp.target
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
    Write-Host "C sources: $($allCSources.Count) retained, $($cSources.Count) standalone; assembly sources: $($asmSources.Count)"
} finally {
    $env:DJDIR = $oldDjdir
    $env:GCC_EXEC_PREFIX = $oldGccExecPrefix
    $env:PATH = $oldPath
}

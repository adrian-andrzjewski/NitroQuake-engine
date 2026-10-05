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
    [ValidateSet('control', 'local', 'asm')]
    [string]$AliasPrepareImplementation = 'control',
    [ValidateSet('c', 'asm')]
    [string]$AliasClipImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$AliasClipZImplementation = 'c',
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
    [string]$DynamicLightOrchestrationImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$DlightContributesImplementation = 'c',
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
    [ValidateSet('control', 'skipzero')]
    [string]$GibTrailHorizontalIntegration = 'control',
    [string]$ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($AliasClipZImplementation -eq 'asm' -and $AliasClipImplementation -ne 'asm') {
    throw '-AliasClipZImplementation asm requires -AliasClipImplementation asm.'
}

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
. (Join-Path $PSScriptRoot 'selectors.ps1')
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

# Keep the profile's descriptive directory while the executable path fits the
# legacy Windows limit. If it does not, hash the complete profile directory into
# a short sibling under out\; the manifest still records every selector value.
if ($executable.Length -gt 259) {
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
    $repoOutRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot 'out'))
    $outputRoot = Join-Path $repoOutRoot ('profile-' + $outputPathHash)
    $executable = Join-Path $outputRoot $executableName
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
# from a hand-copied list of the thirteen implementation selectors. A -Benchmark
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
# 21 .s files is compiled, asm486_experiments.s among them, and the inventory pin
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

    # Past this point the build touches the filesystem. Everything above -- the
    # inventory pin, the flag arithmetic, the source lists -- is inspection, and
    # -DumpFlags returns before any of it writes. See the note by the -Clean block.
    New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $objectRoot -Force | Out-Null

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
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outputRoot $manifestName) -Encoding ASCII

    Write-Host "Built $executable"
    Write-Host "C sources: $($allCSources.Count) retained, $($cSources.Count) standalone; assembly sources: $($asmSources.Count)"} finally {
    $env:DJDIR = $oldDjdir
    $env:GCC_EXEC_PREFIX = $oldGccExecPrefix
    $env:PATH = $oldPath
}

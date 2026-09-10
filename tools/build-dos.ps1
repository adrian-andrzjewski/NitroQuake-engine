[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$Benchmark,
    [switch]$Instrumentation,
    [switch]$NoBootstrap,
    [ValidateSet('baseline', 'aggressive')]
    [string]$OptimizationProfile = 'baseline',
    [ValidateSet(64, 128, 256)]
    [int]$TextureAxisCacheEntries = 256,
    [string]$ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Instrumentation -and -not $Benchmark) {
    throw 'Profile builds require -Benchmark.'
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
if ($OptimizationProfile -eq 'aggressive') {
    $profileSuffixParts += 'aggressive'
}
if ($TextureAxisCacheEntries -ne 256) {
    $profileSuffixParts += "cache$TextureAxisCacheEntries"
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
$asmSources = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.s' -File | Sort-Object Name)
$allSources = @($cSources + $asmSources)
if (($allCSources.Count -ne 83) -or ($cSources.Count -ne 82) -or ($asmSources.Count -ne 20)) {
    throw "Expected 83 retained C sources (82 standalone) and 20 assembly sources, found $($allCSources.Count) C ($($cSources.Count) standalone) and $($asmSources.Count) assembly."
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
        '-fomit-frame-pointer',
        '-fno-strict-aliasing',
        '-fcommon',
        '-ffast-math',
        '-std=gnu89',
        "-DD_TEXAXIS_CACHE_SIZE=$TextureAxisCacheEntries"
    )
    if ($Benchmark) {
        $cFlags += '-DBENCH486'
    }
    if ($Instrumentation) {
        $cFlags += '-DPROFILE486'
    }
    $asmFlags = @(
        "-I$sourceRoot",
        $optimizationLevel,
        '-march=i486',
        '-x',
        'assembler-with-cpp'
    )
    if ($Instrumentation) {
        $asmFlags += '-DPROFILE486'
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
    $linkFlags = @($optimizationLevel, '-march=i486', '-s') + $objects + @('-lm', '-o', $executable)
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

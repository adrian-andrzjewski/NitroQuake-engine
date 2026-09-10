[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$Instrumentation,
    [switch]$NoBootstrap,
    [string]$ToolRoot,
    [string]$DataRoot,
    [ValidateSet('baseline', 'aggressive')]
    [string]$OptimizationProfile = 'baseline',
    [ValidateSet(64, 128, 256)]
    [int]$TextureAxisCacheEntries = 256,
    [ValidateSet('c', 'asm')]
    [string]$TextureAxisImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$SurfaceCacheImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MipLevelImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$MemoryImplementation = 'c',
    [ValidateSet('c', 'asm', 'stosb')]
    [string]$TurbulentImplementation = 'stosb',
    [ValidateSet('c', 'asm')]
    [string]$AliasProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasBBoxProjectImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$AliasTransformFinalImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$TextureAnimationImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$LightMapNormalizeImplementation = 'asm',
    [ValidateSet('c', 'asm')]
    [string]$BspPlaneDotImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$BspClipImplementation = 'c',
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$DemoName = 'demo1',
    [ValidateRange(1, 9)]
    [int]$Runs = 3,
    [int]$TimeoutSeconds = 180,
    [switch]$NoFpsStats
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

$toolManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$profileSuffixParts = @()
if ($OptimizationProfile -eq 'aggressive') {
    $profileSuffixParts += 'aggressive'
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
if ($AliasProjectImplementation -eq 'c') {
    $profileSuffixParts += 'aliasc'
}
if ($AliasBBoxProjectImplementation -eq 'c') {
    $profileSuffixParts += 'aliasbboxc'
}
if ($AliasTransformFinalImplementation -eq 'c') {
    $profileSuffixParts += 'aliastransformc'
}
if ($TextureAnimationImplementation -eq 'c') {
    $profileSuffixParts += 'textureanimc'
}
if ($LightMapNormalizeImplementation -eq 'c') {
    $profileSuffixParts += 'lightmapc'
}
if ($BspPlaneDotImplementation -eq 'asm') {
    $profileSuffixParts += 'bspdotasm'
}
if ($BspClipImplementation -eq 'asm') {
    $profileSuffixParts += 'bspclipasm'
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
$executableName = if ($Instrumentation) { 'qprof.exe' } else { 'qbench.exe' }
$benchmarkExe = Join-Path $repoRoot ('out\dos' + $profileSuffix + '\' + $executableName)
$dosboxRoot = Join-Path $ToolRoot $toolManifest.dosboxX.installDirectory
$dosbox = Join-Path $dosboxRoot ($toolManifest.dosboxX.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
$profilePath = Join-Path $PSScriptRoot 'dosbox-x-486-high.conf'
$bootstrap = Join-Path $PSScriptRoot 'bootstrap-dos.ps1'
$build = Join-Path $PSScriptRoot 'build-dos.ps1'

if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    if ($NoBootstrap) {
        throw "DOSBox-X not found at '$dosbox'. Run bootstrap-dos.ps1 first or omit -NoBootstrap."
    }
    & $bootstrap -ToolRoot $ToolRoot
}
if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
    throw "Required DOSBox-X executable is missing: '$dosbox'."
}

if (-not (Test-Path -LiteralPath $benchmarkExe -PathType Leaf)) {
    if ($SkipBuild) {
        throw "Benchmark executable not found at '$benchmarkExe'. Run build-dos.ps1 -Benchmark first or omit -SkipBuild."
    }

    $buildArgs = @('-Benchmark', '-OptimizationProfile', $OptimizationProfile,
        '-TextureAxisCacheEntries', $TextureAxisCacheEntries,
        '-TextureAxisImplementation', $TextureAxisImplementation,
        '-SurfaceCacheImplementation', $SurfaceCacheImplementation,
        '-MipLevelImplementation', $MipLevelImplementation,
        '-MemoryImplementation', $MemoryImplementation,
        '-TurbulentImplementation', $TurbulentImplementation,
        '-AliasProjectImplementation', $AliasProjectImplementation,
        '-AliasBBoxProjectImplementation', $AliasBBoxProjectImplementation,
        '-AliasTransformFinalImplementation', $AliasTransformFinalImplementation,
        '-TextureAnimationImplementation', $TextureAnimationImplementation,
        '-LightMapNormalizeImplementation', $LightMapNormalizeImplementation,
        '-BspPlaneDotImplementation', $BspPlaneDotImplementation,
        '-BspClipImplementation', $BspClipImplementation,
        '-ToolRoot', $ToolRoot)
    if ($Instrumentation) {
        $buildArgs += '-Instrumentation'
    }
    if ($NoBootstrap) {
        $buildArgs += '-NoBootstrap'
    }
    & $build @buildArgs
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

$runName = 'dos-timedemo-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$stagingRoot = Join-Path (Join-Path $repoRoot 'out') $runName
if (Test-Path -LiteralPath $stagingRoot) {
    throw "Timedemo staging path already exists; refusing to overwrite '$stagingRoot'."
}
$quakeRoot = Join-Path $stagingRoot 'quake'
$stagedData = Join-Path $quakeRoot 'id1'
$fpsStatsOptions = if ($NoFpsStats) { '' } else { ' -fpsstats' }
New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

Copy-Item -LiteralPath $benchmarkExe -Destination (Join-Path $quakeRoot $executableName)
Copy-Item -LiteralPath (Join-Path $repoRoot 'WinQuake\cwsdpmi.exe') -Destination (Join-Path $quakeRoot 'cwsdpmi.exe')
Copy-Item -Path (Join-Path $DataRoot '*') -Destination $stagedData -Recurse -Force

$batchPath = Join-Path $quakeRoot 'timedemo.bat'
@"
@echo off
cd \quake
$executableName -basedir \quake -timedemoexit$fpsStatsOptions -nosound -nojoy -nomouse -nocdaudio +timedemo $DemoName
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

    $results += [ordered]@{
        run = $run
        frames = [int]$match.Groups['frames'].Value
        seconds = [double]::Parse($match.Groups['seconds'].Value, $culture)
        fps = [double]::Parse($match.Groups['fps'].Value, $culture)
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

$fpsValues = @($results | ForEach-Object { [double]$_.fps } | Sort-Object)
$middle = [int][math]::Floor($fpsValues.Count / 2)
if (($fpsValues.Count % 2) -eq 1) {
    $medianFps = $fpsValues[$middle]
}
else {
    $medianFps = ($fpsValues[$middle - 1] + $fpsValues[$middle]) / 2.0
}

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

$result = [ordered]@{
    demo = $DemoName
    runs = $Runs
    medianFps = $medianFps
    fpsSummary = $fpsSummary
    dosboxVersion = $toolManifest.dosboxX.version
    profile = $profilePath
    profileSha256 = $profileHash
    executable = $benchmarkExe
    optimizationProfile = $OptimizationProfile
    textureAxisCacheEntries = $TextureAxisCacheEntries
    textureAxisImplementation = $TextureAxisImplementation
    surfaceCacheImplementation = $SurfaceCacheImplementation
    mipLevelImplementation = $MipLevelImplementation
    turbulentImplementation = $TurbulentImplementation
    memoryImplementation = $MemoryImplementation
    aliasProjectImplementation = $AliasProjectImplementation
    aliasBBoxProjectImplementation = $AliasBBoxProjectImplementation
    aliasTransformFinalImplementation = $AliasTransformFinalImplementation
    textureAnimationImplementation = $TextureAnimationImplementation
    lightMapNormalizeImplementation = $LightMapNormalizeImplementation
    bspPlaneDotImplementation = $BspPlaneDotImplementation
    bspClipImplementation = $BspClipImplementation
    instrumentation = [bool]$Instrumentation
    frameFpsStats = [bool](-not $NoFpsStats)
    dataRoot = $DataRoot
    stagingRoot = $stagingRoot
    results = $results
}
$resultPath = Join-Path $stagingRoot 'timedemo-result.json'
$result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $resultPath -Encoding ASCII

Write-Host ($results | ForEach-Object { $_.report })
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

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
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$DemoName = 'demo1',
    [ValidateRange(1, 9)]
    [int]$Runs = 3,
    [int]$TimeoutSeconds = 180
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
        '-TextureAxisCacheEntries', $TextureAxisCacheEntries, '-ToolRoot', $ToolRoot)
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
New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

Copy-Item -LiteralPath $benchmarkExe -Destination (Join-Path $quakeRoot $executableName)
Copy-Item -LiteralPath (Join-Path $repoRoot 'WinQuake\cwsdpmi.exe') -Destination (Join-Path $quakeRoot 'cwsdpmi.exe')
Copy-Item -Path (Join-Path $DataRoot '*') -Destination $stagedData -Recurse -Force

$batchPath = Join-Path $quakeRoot 'timedemo.bat'
@"
@echo off
cd \quake
$executableName -basedir \quake -timedemoexit -nosound -nojoy -nomouse -nocdaudio +timedemo $DemoName
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

    $results += [ordered]@{
        run = $run
        frames = [int]$match.Groups['frames'].Value
        seconds = [double]::Parse($match.Groups['seconds'].Value, $culture)
        fps = [double]::Parse($match.Groups['fps'].Value, $culture)
        report = $report.Trim()
    }
}

$fpsValues = @($results | ForEach-Object { [double]$_.fps } | Sort-Object)
$middle = [int]($fpsValues.Count / 2)
if (($fpsValues.Count % 2) -eq 1) {
    $medianFps = $fpsValues[$middle]
}
else {
    $medianFps = ($fpsValues[$middle - 1] + $fpsValues[$middle]) / 2.0
}

$result = [ordered]@{
    demo = $DemoName
    runs = $Runs
    medianFps = $medianFps
    dosboxVersion = $toolManifest.dosboxX.version
    profile = $profilePath
    profileSha256 = $profileHash
    executable = $benchmarkExe
    optimizationProfile = $OptimizationProfile
    textureAxisCacheEntries = $TextureAxisCacheEntries
    instrumentation = [bool]$Instrumentation
    dataRoot = $DataRoot
    stagingRoot = $stagingRoot
    results = $results
}
$resultPath = Join-Path $stagingRoot 'timedemo-result.json'
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resultPath -Encoding ASCII

Write-Host ($results | ForEach-Object { $_.report })
Write-Host ("Median FPS: {0:N1}" -f $medianFps)
Write-Host "Timedemo result: $resultPath"

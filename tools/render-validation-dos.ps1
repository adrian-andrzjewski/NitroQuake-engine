<#
.SYNOPSIS
    Run deterministic DOS timedemo scenes and validate captured renderer output.

.DESCRIPTION
    Runs the scenarios in render-scenarios.json through the normal benchmark
    executable. Each scene records its final framebuffer checksum, a checksum
    stream for every rendered frame, a selected PCX frame, and timedemo metrics.
    Captured images are compared against committed references with configurable
    per-scenario tolerances. Repeated runs are compared frame by frame after the
    six configured startup frames to expose nondeterministic output and temporal instability.
#>
[CmdletBinding()]
param(
    [string[]]$Scenario = @(),
    [string]$ScenarioFile,
    [string]$OutputRoot,
    [string]$ToolRoot,
    [string]$DataRoot,
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    [ValidateRange(30, 3600)]
    [int]$TimeoutSeconds = 180,
    [switch]$SkipBuild,
    [switch]$NoBootstrap,
    [switch]$ListScenarios
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($ScenarioFile)) {
    $ScenarioFile = Join-Path $PSScriptRoot 'render-scenarios.json'
}
$scenarioData = Get-Content -LiteralPath $ScenarioFile -Raw | ConvertFrom-Json
if ($scenarioData.schemaVersion -ne 1) {
    throw "Unsupported rendering scenario schema version '$($scenarioData.schemaVersion)'."
}
$validationAutoexecProperty = $scenarioData.PSObject.Properties['validationAutoexecCommands']
if ($null -eq $validationAutoexecProperty -or @($validationAutoexecProperty.Value).Count -eq 0) {
    throw 'The scenario manifest must define validationAutoexecCommands to make rendering runs deterministic.'
}
$validationAutoexecCommands = @($validationAutoexecProperty.Value | ForEach-Object { [string]$_ })
$warmupChecksumFrames = [int]$scenarioData.warmupChecksumFrames
if ($warmupChecksumFrames -lt 0) {
    throw 'warmupChecksumFrames must be zero or greater.'
}

$allScenarios = @($scenarioData.scenarios)
if ($ListScenarios) {
    $allScenarios | Select-Object id, description, demo, quakeExtraArgs, repeatRuns, captureFrame | Format-Table -AutoSize | Out-Host
    exit 0
}

if ($Scenario.Count -gt 0) {
    $Scenario = @($Scenario | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
}

if ($Scenario.Count -gt 0) {
    $unknown = @($Scenario | Where-Object { $_ -notin @($allScenarios | ForEach-Object { $_.id }) })
    if ($unknown.Count -gt 0) {
        throw "Unknown rendering scenario(s): $($unknown -join ', '). Use -ListScenarios to list valid IDs."
    }
    $selectedScenarios = @($allScenarios | Where-Object { $_.id -in $Scenario })
}
else {
    $selectedScenarios = $allScenarios
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
    $OutputRoot = Join-Path $repoRoot (Join-Path 'out' "render-validation-$stamp")
}
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
if (Test-Path -LiteralPath $OutputRoot) {
    throw "Output path already exists; refusing to overwrite '$OutputRoot'."
}
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $pwshCommand) { $pwshCommand = Get-Command powershell }
$timedemoScript = Join-Path $PSScriptRoot 'timedemo-dos.ps1'
$compareScript = Join-Path $PSScriptRoot 'compare-rendering.py'
$scenarioResults = New-Object System.Collections.Generic.List[object]
$failures = New-Object System.Collections.Generic.List[object]
$suiteWatch = [Diagnostics.Stopwatch]::StartNew()

function Read-FrameChecksumLog {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$IgnoreLeadingFrames = 0
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Per-frame checksum output is missing: '$Path'."
    }
    $text = Get-Content -LiteralPath $Path -Raw
    $records = [regex]::Matches($text, '(?m)^(?<index>\d+)\s+(?<checksum>\d+)\s*$')
    $summary = [regex]::Match($text, '(?m)^frames\s+(?<frames>\d+)\s+overflow\s+(?<overflow>\d+)\s*$')
    if (-not $summary.Success) {
        throw "Per-frame checksum log has no completion summary: '$Path'."
    }
    $checksums = New-Object System.Collections.Generic.List[uint64]
    for ($i = 0; $i -lt $records.Count; $i++) {
        $index = [int]$records[$i].Groups['index'].Value
        if ($index -ne $i) {
            throw "Per-frame checksum log '$Path' jumps from frame $($i - 1) to frame $index."
        }
        $checksums.Add([uint64]$records[$i].Groups['checksum'].Value)
    }
    $declaredFrames = [int]$summary.Groups['frames'].Value
    $overflow = [int]$summary.Groups['overflow'].Value
    if ($declaredFrames -ne $checksums.Count) {
        throw "Per-frame checksum log '$Path' declares $declaredFrames frames but contains $($checksums.Count) records."
    }
    if ($overflow -ne 0) {
        throw "Per-frame checksum log '$Path' overflowed by $overflow frames."
    }

    $unique = New-Object 'System.Collections.Generic.HashSet[uint64]'
    $zeroCount = 0
    $longestRun = 0
    $currentRun = 0
    $previous = [uint64]::MaxValue
    for ($i = $IgnoreLeadingFrames; $i -lt $checksums.Count; $i++) {
        $value = $checksums[$i]
        [void]$unique.Add($value)
        if ($value -eq 0) { $zeroCount++ }
        if ($value -eq $previous) { $currentRun++ } else { $currentRun = 1 }
        if ($currentRun -gt $longestRun) { $longestRun = $currentRun }
        $previous = $value
    }
    return [pscustomobject]@{
        Path = $Path
        Checksums = $checksums.ToArray()
        Count = $checksums.Count
        Overflow = $overflow
        UniqueAfterWarmup = $unique.Count
        ZeroAfterWarmup = $zeroCount
        LongestIdenticalRunAfterWarmup = $longestRun
    }
}

function Find-FirstFrameMismatch {
    param(
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)]$Actual,
        [int]$IgnoreLeadingFrames = 0
    )
    if ($Expected.Count -ne $Actual.Count) {
        return [pscustomobject]@{ frame = $null; expected = $Expected.Count; actual = $Actual.Count; kind = 'frame-count' }
    }
    for ($frame = $IgnoreLeadingFrames; $frame -lt $Expected.Count; $frame++) {
        if ($Expected[$frame] -ne $Actual[$frame]) {
            return [pscustomobject]@{
                frame = $frame
                expected = $Expected[$frame]
                actual = $Actual[$frame]
                kind = 'checksum'
            }
        }
    }
    return $null
}

function Format-Invariant {
    param([double]$Value)
    return $Value.ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)
}

foreach ($scene in $selectedScenarios) {
    $sceneWatch = [Diagnostics.Stopwatch]::StartNew()
    $sceneOutput = Join-Path $OutputRoot $scene.id
    New-Item -ItemType Directory -Path $sceneOutput -Force | Out-Null
    $sceneStatus = 'PASS'
    $timedemoJson = $null
    $imageReports = New-Object System.Collections.Generic.List[object]
    $frameReports = New-Object System.Collections.Generic.List[object]
    $childOutputText = ''
    $timedemoResultPath = $null
    $effectiveAutoexecCommands = @($validationAutoexecCommands)
    $effectiveTolerance = $scenarioData.defaultTolerance
    $toleranceProperty = $scene.PSObject.Properties['tolerance']
    if ($null -ne $toleranceProperty -and $null -ne $toleranceProperty.Value) {
        $effectiveTolerance = $toleranceProperty.Value
    }

    Write-Host ''
    Write-Host ('=' * 78)
    Write-Host ("  {0} ({1})" -f $scene.id, $scene.description)
    Write-Host ('=' * 78)

    try {
        $timedemoArgs = @(
            '-NoProfile', '-File', $timedemoScript,
            '-DemoName', [string]$scene.demo,
            '-Runs', [string]$scene.repeatRuns,
            '-TimeoutSeconds', [string]$TimeoutSeconds,
            '-FrameChecksums',
            '-FrameCaptureIndex', [string]$scene.captureFrame,
            '-ExpectedFrames', [string]$scene.expectedFrames,
            '-ExpectedChecksum', [string]$scene.expectedChecksum
        )
        if (-not [string]::IsNullOrWhiteSpace([string]$scene.quakeExtraArgs)) {
            $timedemoArgs += @('-QuakeExtraArgs', [string]$scene.quakeExtraArgs)
        }
        $autoexecProperty = $scene.PSObject.Properties['autoexecCommands']
        if ($null -ne $autoexecProperty -and @($autoexecProperty.Value).Count -gt 0) {
            $effectiveAutoexecCommands += @($autoexecProperty.Value | ForEach-Object { [string]$_ })
        }
        if ($effectiveAutoexecCommands.Count -gt 0) {
            $timedemoArgs += @('-AutoexecCommandsJson', (ConvertTo-Json -InputObject $effectiveAutoexecCommands -Compress))
        }
        if ($NoBootstrap) { $timedemoArgs += '-NoBootstrap' }
        if ($SkipBuild) { $timedemoArgs += '-SkipBuild' }
        if (-not [string]::IsNullOrWhiteSpace($ToolRoot)) { $timedemoArgs += @('-ToolRoot', $ToolRoot) }
        if (-not [string]::IsNullOrWhiteSpace($DataRoot)) { $timedemoArgs += @('-DataRoot', $DataRoot) }
        $timedemoArgs += @('-CpuTarget', $CpuTarget)

        $childOutput = & $pwshCommand.Source @timedemoArgs 2>&1
        $childExit = $LASTEXITCODE
        $childOutputText = ($childOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
        $childOutputText | Set-Content -LiteralPath (Join-Path $sceneOutput 'timedemo-output.txt') -Encoding UTF8
        $childOutput | Out-Host
        if ($childExit -ne 0) {
            throw "timedemo-dos.ps1 exited with code $childExit. Captured output: '$([IO.Path]::GetFullPath((Join-Path $sceneOutput 'timedemo-output.txt')))'."
        }

        $resultLine = [regex]::Match($childOutputText, '(?m)^Timedemo result:\s*(?<path>.+?)\s*$')
        if (-not $resultLine.Success) {
            throw "timedemo-dos.ps1 did not report its result JSON path. Captured output: '$([IO.Path]::GetFullPath((Join-Path $sceneOutput 'timedemo-output.txt')))'."
        }
        $timedemoResultPath = $resultLine.Groups['path'].Value.Trim()
        if (-not (Test-Path -LiteralPath $timedemoResultPath -PathType Leaf)) {
            throw "Timedemo result JSON was not written to '$timedemoResultPath'."
        }
        $timedemoJson = Get-Content -LiteralPath $timedemoResultPath -Raw | ConvertFrom-Json

        $referencePath = [IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$scene.reference)))
        if (-not (Test-Path -LiteralPath $referencePath -PathType Leaf)) {
            throw "Scenario reference image is missing: '$referencePath'."
        }

        $previousChecksums = $null
        for ($i = 0; $i -lt $timedemoJson.results.Count; $i++) {
            $run = $timedemoJson.results[$i]
            $diagnostics = $run.renderingDiagnostics
            if ($null -eq $diagnostics -or [string]::IsNullOrWhiteSpace([string]$diagnostics.frameChecksumPath)) {
                throw "Run $($run.run) has no per-frame checksum artifact in '$timedemoResultPath'."
            }
            if ([string]::IsNullOrWhiteSpace([string]$diagnostics.frameCapturePath)) {
                throw "Run $($run.run) has no captured PCX image in '$timedemoResultPath'."
            }

            $frameData = Read-FrameChecksumLog -Path ([string]$diagnostics.frameChecksumPath) -IgnoreLeadingFrames $warmupChecksumFrames
            $frameReports.Add([pscustomobject]@{
                    run = $run.run
                    frames = $frameData.Count
                    timedemoFrames = $run.frames
                    uniqueAfterWarmup = $frameData.UniqueAfterWarmup
                    zeroAfterWarmup = $frameData.ZeroAfterWarmup
                    longestIdenticalRunAfterWarmup = $frameData.LongestIdenticalRunAfterWarmup
                    frameChecksumPath = $frameData.Path
                    repeatParity = $null
                })

            # CL_TimeDemo_f records one setup frame outside the measured interval.
            # A count drift is a synchronization/timing failure.
            if ($frameData.Count -ne ([int]$run.frames + 1)) {
                $sceneStatus = 'FAIL'
                $failures.Add([pscustomobject]@{
                        scenario = $scene.id
                        test = 'frame-count-synchronization'
                        expected = [int]$run.frames + 1
                        actual = $frameData.Count
                        metrics = @{ timedemoFrames = $run.frames; frameChecksumRecords = $frameData.Count }
                        capturedOutput = @{ timedemoResult = $timedemoResultPath; frameChecksums = $frameData.Path }
                    })
            }

            if ($null -ne $previousChecksums) {
                $mismatch = Find-FirstFrameMismatch -Expected $previousChecksums.Checksums -Actual $frameData.Checksums -IgnoreLeadingFrames $warmupChecksumFrames
                $frameReports[$frameReports.Count - 1].repeatParity = if ($null -eq $mismatch) { 'PASS' } else { 'FAIL' }
                if ($null -ne $mismatch) {
                    $sceneStatus = 'FAIL'
                    $failures.Add([pscustomobject]@{
                            scenario = $scene.id
                            test = 'repeat-frame-stability'
                            expected = $mismatch.expected
                            actual = $mismatch.actual
                            metrics = @{ firstMismatch = $mismatch; ignoredLeadingFrames = $warmupChecksumFrames; previousPath = $previousChecksums.Path; actualPath = $frameData.Path }
                            capturedOutput = @{ timedemoResult = $timedemoResultPath; expectedFrameChecksums = $previousChecksums.Path; actualFrameChecksums = $frameData.Path }
                        })
                }
            }
            $previousChecksums = $frameData

            $imageReportPath = Join-Path $sceneOutput ('run-{0:D2}-image-comparison.json' -f $run.run)
            $diffImagePath = Join-Path $sceneOutput ('run-{0:D2}-diff.png' -f $run.run)
            $comparisonArgs = @(
                $compareScript, $referencePath, [string]$diagnostics.frameCapturePath,
                '--scenario', [string]$scene.id,
                '--channel-tolerance', [string]$effectiveTolerance.channel,
                '--max-changed-pixel-fraction', (Format-Invariant ([double]$effectiveTolerance.maxChangedPixelFraction)),
                '--max-mean-absolute-error', (Format-Invariant ([double]$effectiveTolerance.maxMeanAbsoluteError)),
                '--report-json', $imageReportPath,
                '--diff-image', $diffImagePath
            )
            $comparisonOutput = & python @comparisonArgs 2>&1
            $comparisonExit = $LASTEXITCODE
            $comparisonOutputText = ($comparisonOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
            $comparisonOutput | Out-Host
            $imageReport = if (Test-Path -LiteralPath $imageReportPath -PathType Leaf) {
                Get-Content -LiteralPath $imageReportPath -Raw | ConvertFrom-Json
            }
            else {
                [pscustomobject]@{ pass = $false; error = "Comparator exited $comparisonExit without writing a report." }
            }
            $imageReports.Add($imageReport)
            if ($comparisonExit -ne 0 -or -not $imageReport.pass) {
                $sceneStatus = 'FAIL'
                $failures.Add([pscustomobject]@{
                        scenario = $scene.id
                        test = 'image-comparison'
                        expected = @{ path = $referencePath }
                        actual = @{ path = [string]$diagnostics.frameCapturePath }
                        metrics = $imageReport
                        capturedOutput = @{ timedemoResult = $timedemoResultPath; diffImage = $diffImagePath; comparatorOutput = $comparisonOutputText }
                    })
            }
        }
    }
    catch {
        $sceneStatus = 'FAIL'
        $message = $_.Exception.Message
        $failures.Add([pscustomobject]@{
                scenario = $scene.id
                test = if ($null -eq $timedemoJson) { 'timedemo-run' } else { 'render-validation' }
                expected = @{ frames = $scene.expectedFrames; checksum = $scene.expectedChecksum; reference = $scene.reference }
                actual = @{ error = $message }
                metrics = @{ quakeExtraArgs = $scene.quakeExtraArgs; demo = $scene.demo }
                capturedOutput = @{ output = Join-Path $sceneOutput 'timedemo-output.txt'; timedemoResult = $timedemoResultPath }
            })
        Write-Host ("  FAILED: {0}" -f $message) -ForegroundColor Red
    }
    finally {
        $sceneWatch.Stop()
    }

    $reportedFrames = @()
    $reportedSeconds = @()
    if ($null -ne $timedemoJson) {
        $reportedFrames = @($timedemoJson.results | ForEach-Object { $_.frames })
        $reportedSeconds = @($timedemoJson.results | ForEach-Object { $_.seconds })
    }
    $scenarioResults.Add([pscustomobject]@{
            scenario = $scene.id
            description = $scene.description
            result = $sceneStatus
            demo = $scene.demo
            quakeExtraArgs = $scene.quakeExtraArgs
            repeatRuns = $scene.repeatRuns
            expectedFrames = $scene.expectedFrames
            expectedChecksum = $scene.expectedChecksum
            captureFrame = $scene.captureFrame
            tolerance = $effectiveTolerance
            reference = [IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$scene.reference)))
            validationAutoexecCommands = $effectiveAutoexecCommands
            ignoredWarmupChecksumFrames = $warmupChecksumFrames
            timedemoResult = $timedemoResultPath
            sourceFingerprint = if ($null -ne $timedemoJson) { $timedemoJson.sourceFingerprint } else { $null }
            profile = if ($null -ne $timedemoJson) { $timedemoJson.profile } else { $null }
            profileSha256 = if ($null -ne $timedemoJson) { $timedemoJson.profileSha256 } else { $null }
            dosboxVersion = if ($null -ne $timedemoJson) { $timedemoJson.dosboxVersion } else { $null }
            medianFps = if ($null -ne $timedemoJson) { $timedemoJson.medianFps } else { $null }
            frames = $reportedFrames
            seconds = $reportedSeconds
            frameDiagnostics = $frameReports.ToArray()
            imageComparisons = $imageReports.ToArray()
            elapsedSeconds = [math]::Round($sceneWatch.Elapsed.TotalSeconds, 2)
        })
    if ($sceneStatus -eq 'PASS') {
        Write-Host ("  -> PASS ({0:N1}s)" -f $sceneWatch.Elapsed.TotalSeconds) -ForegroundColor Green
    }
    else {
        Write-Host ("  -> FAIL ({0:N1}s)" -f $sceneWatch.Elapsed.TotalSeconds) -ForegroundColor Red
    }
}

$suiteWatch.Stop()
$suiteResult = [ordered]@{
    schemaVersion = 1
    createdUtc = [DateTime]::UtcNow.ToString('o')
    result = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
    cpuTarget = $CpuTarget
    scenarioFile = [IO.Path]::GetFullPath($ScenarioFile)
    outputRoot = $OutputRoot
    validationAutoexecCommands = $validationAutoexecCommands
    warmupChecksumFrames = $warmupChecksumFrames
    scenarioCount = $scenarioResults.Count
    passed = @($scenarioResults.ToArray() | Where-Object { $_.result -eq 'PASS' }).Count
    failed = @($scenarioResults.ToArray() | Where-Object { $_.result -eq 'FAIL' }).Count
    elapsedSeconds = [math]::Round($suiteWatch.Elapsed.TotalSeconds, 2)
    scenarios = $scenarioResults.ToArray()
    failures = $failures.ToArray()
}
$suiteResultPath = Join-Path $OutputRoot 'render-validation-result.json'
$suiteResult | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $suiteResultPath -Encoding UTF8

Write-Host ''
Write-Host 'RENDER VALIDATION SUMMARY'
$scenarioResults | Select-Object scenario, result, medianFps, elapsedSeconds | Format-Table -AutoSize | Out-Host
Write-Host ("  {0} passed, {1} failed, {2:N1}s total" -f $suiteResult.passed, $suiteResult.failed, $suiteWatch.Elapsed.TotalSeconds)
Write-Host ("  Report: {0}" -f $suiteResultPath)

if ($failures.Count -gt 0) {
    Write-Host '  Failures:' -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host ("    {0} / {1}: expected={2}; actual={3}" -f
            $failure.scenario, $failure.test,
            ($failure.expected | ConvertTo-Json -Compress -Depth 5),
            ($failure.actual | ConvertTo-Json -Compress -Depth 5)) -ForegroundColor Red
        Write-Host ("      captured output: {0}" -f (($failure.capturedOutput | ConvertTo-Json -Compress -Depth 5))) -ForegroundColor Yellow
    }
    exit 1
}
exit 0

<#
.SYNOPSIS
    Run deterministic DOS timedemo scenes and validate captured renderer output.

.DESCRIPTION
    Runs the scenarios in render-scenarios.json through the normal benchmark
    executable. Each scene records its final framebuffer checksum, a checksum
    stream for every rendered frame, a selected PCX frame, and timedemo metrics.
    Captured images are compared against committed references with configurable
    per-scenario tolerances. Repeated runs are compared frame by frame after the
    configured startup frames to expose nondeterministic output and temporal
    instability. A pair-only scenario may omit its reference image when the
    caller defers golden comparison to render-parity-dos.ps1.
#>
[CmdletBinding()]
param(
    [string[]]$Scenario = @(),
    [string]$ScenarioFile,
    [string]$OutputRoot,
    [string]$ToolRoot,
    [string]$DataRoot,
    [string]$RendererSelectorProfile,
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    [ValidateRange(30, 3600)]
    [int]$TimeoutSeconds = 180,
    [ValidateRange(0, 9)]
    [int]$RunsOverride = 0,
    [switch]$SkipBuild,
    [switch]$VisualParityOnly,
    [switch]$NoBootstrap,
    [switch]$SkipGoldenImageComparison,
    [switch]$ListScenarios
)

. (Join-Path $PSScriptRoot 'bench-event-repeat.ps1')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-StreamingTimedemo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [scriptblock]$OnOutput = { param($Line) Write-Host $Line }
    )

    $outputLines = New-Object System.Collections.Generic.List[string]
    & $Executable @Arguments 2>&1 | ForEach-Object {
        $line = [string]$_
        $outputLines.Add($line)
        $null = & $OnOutput $line
    }
    $exitCode = $LASTEXITCODE

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $outputLines.ToArray()
    }
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($VisualParityOnly -and $CpuTarget -ne 'i486') {
    throw '-VisualParityOnly is supported only for the i486 visual comparison path.'
}
$timedemoScript = Join-Path $PSScriptRoot 'timedemo-dos.ps1'
$rendererSelectorProfileData = $null
$rendererSelectorProfilePathResolved = $null
if (-not [string]::IsNullOrWhiteSpace($RendererSelectorProfile)) {
    $profilePath = if ([IO.Path]::IsPathRooted($RendererSelectorProfile)) {
        [IO.Path]::GetFullPath($RendererSelectorProfile)
    }
    else {
        [IO.Path]::GetFullPath((Join-Path $repoRoot $RendererSelectorProfile))
    }
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        throw "Renderer selector profile was not found: '$profilePath'."
    }
    $rendererSelectorProfileData = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
    if ([int]$rendererSelectorProfileData.schemaVersion -ne 1) {
        throw "Unsupported renderer selector profile schema '$($rendererSelectorProfileData.schemaVersion)'."
    }
    if ([string]::IsNullOrWhiteSpace([string]$rendererSelectorProfileData.id) -or
        [string]$rendererSelectorProfileData.id -notmatch '^[A-Za-z0-9_.-]+$') {
        throw 'Renderer selector profile id must contain only letters, digits, dot, underscore, or hyphen.'
    }
    $selectorProperty = $rendererSelectorProfileData.PSObject.Properties['selectors']
    if ($null -eq $selectorProperty -or $null -eq $selectorProperty.Value) {
        throw 'Renderer selector profile must define a selectors object.'
    }
    $selectorProperties = @($selectorProperty.Value.PSObject.Properties)
    if ($selectorProperties.Count -eq 0) {
        throw 'Renderer selector profile must contain at least one selector.'
    }
    $timedemoSource = Get-Content -LiteralPath $timedemoScript -Raw
    foreach ($selector in $selectorProperties) {
        if ($selector.Name -notmatch 'Implementation$') {
            throw "Renderer profile selector '$($selector.Name)' is not an implementation selector."
        }
        if ($selector.Value -isnot [string]) {
            throw "Renderer profile selector '$($selector.Name)' must have a string value."
        }
        $escapedName = [regex]::Escape([string]$selector.Name)
        if (-not [regex]::IsMatch($timedemoSource, "(?m)^\s*\[string\]\`$$escapedName(?=\s|=)")) {
            throw "Renderer selector '$($selector.Name)' is not a parameter of timedemo-dos.ps1."
        }
    }
    # Older checked-in profiles predate newer selectors. Resolve omissions to
    # the reference implementation so adding a selector cannot silently turn
    # every focused profile into an assembly candidate.
    if ($null -eq $rendererSelectorProfileData.selectors.PSObject.Properties['ParticleDrawImplementation']) {
        $rendererSelectorProfileData.selectors | Add-Member -NotePropertyName ParticleDrawImplementation -NotePropertyValue 'c'
    }
    $rendererSelectorProfilePathResolved = $profilePath
}
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
    $referencePath = $null
    $imageReports = New-Object System.Collections.Generic.List[object]
    $frameReports = New-Object System.Collections.Generic.List[object]
$previousBlobExplosionEventState = $null
$previousLavaSplashEventState = $null
$previousTeleportSplashEventState = $null
$previousRunParticleEffectEventState = $null
    $effectiveRuns = if ($RunsOverride -gt 0) { $RunsOverride } else { [int]$scene.repeatRuns }
    $childOutputText = ''
    $timedemoResultPath = $null
    $effectiveAutoexecCommands = @($validationAutoexecCommands)
    $effectiveTolerance = $scenarioData.defaultTolerance
    $toleranceProperty = $scene.PSObject.Properties['tolerance']
    if ($null -ne $toleranceProperty -and $null -ne $toleranceProperty.Value) {
        $effectiveTolerance = $toleranceProperty.Value
    }
    $requiredBenchEvents = @()
    $requiredBenchEventsProperty = $scene.PSObject.Properties['requiredBenchEvents']
    if ($null -ne $requiredBenchEventsProperty -and $null -ne $requiredBenchEventsProperty.Value) {
        $requiredBenchEvents = @($requiredBenchEventsProperty.Value | ForEach-Object { [string]$_ })
    }
    $captureBenchEvents = @()
    $captureBenchEventsProperty = $scene.PSObject.Properties['captureBenchEvents']
    if ($null -ne $captureBenchEventsProperty) {
        if ($captureBenchEventsProperty.Value -isnot [array] -or $captureBenchEventsProperty.Value.Count -eq 0) {
            throw "Scenario '$($scene.id)' captureBenchEvents must be a non-empty JSON array."
        }
        foreach ($captureBenchEvent in $captureBenchEventsProperty.Value) {
            if ($captureBenchEvent -isnot [string] -or $captureBenchEvent -notin @('blobExplosion', 'lavaSplash', 'teleportSplash', 'runParticleEffect', 'entityParticles')) {
                throw "Scenario '$($scene.id)' has unsupported captureBenchEvents entry '$captureBenchEvent'."
            }
            $captureBenchEvents += $captureBenchEvent
        }
    }
    $expectedBenchEventFrames = @{}
    $expectedBenchEventFramesProperty = $scene.PSObject.Properties['expectedBenchEventFrames']
    if ($null -ne $expectedBenchEventFramesProperty -and $null -ne $expectedBenchEventFramesProperty.Value) {
        foreach ($expectedEventProperty in $expectedBenchEventFramesProperty.Value.PSObject.Properties) {
            if ($expectedEventProperty.Name -notin @('blobExplosion', 'lavaSplash', 'teleportSplash', 'runParticleEffect', 'entityParticles') -or
                $expectedEventProperty.Value -isnot [array]) {
                throw "Scenario '$($scene.id)' expectedBenchEventFrames has an invalid '$($expectedEventProperty.Name)' entry."
            }
            $expectedBenchEventFrames[$expectedEventProperty.Name] = @(
                $expectedEventProperty.Value | ForEach-Object { [int]$_ }
            )
        }
    }
    $expectedChecksumStreamFrames = $null
    $expectedChecksumStreamFramesProperty = $scene.PSObject.Properties['expectedChecksumStreamFrames']
    if ($null -ne $expectedChecksumStreamFramesProperty -and
        $null -ne $expectedChecksumStreamFramesProperty.Value) {
        $expectedChecksumStreamFrames = [int]$expectedChecksumStreamFramesProperty.Value
        if ($expectedChecksumStreamFrames -le 0) {
            throw "Scenario '$($scene.id)' expectedChecksumStreamFrames must be a positive integer."
        }
    }
    if ($requiredBenchEvents -contains 'lavaSplash' -and
        -not $expectedBenchEventFrames.ContainsKey('lavaSplash')) {
        throw "Scenario '$($scene.id)' requires lavaSplash but does not define expectedBenchEventFrames.lavaSplash."
    }
    if ($requiredBenchEvents -contains 'teleportSplash' -and
        -not $expectedBenchEventFrames.ContainsKey('teleportSplash')) {
        throw "Scenario '$($scene.id)' requires teleportSplash but does not define expectedBenchEventFrames.teleportSplash."
    }
    if ($requiredBenchEvents -contains 'runParticleEffect' -and
        -not $expectedBenchEventFrames.ContainsKey('runParticleEffect')) {
        throw "Scenario '$($scene.id)' requires runParticleEffect but does not define expectedBenchEventFrames.runParticleEffect."
    }
    if ($requiredBenchEvents -contains 'entityParticles' -and
        -not $expectedBenchEventFrames.ContainsKey('entityParticles')) {
        throw "Scenario '$($scene.id)' requires entityParticles but does not define expectedBenchEventFrames.entityParticles."
    }

    Write-Host ''
    Write-Host ('=' * 78)
    Write-Host ("  {0} ({1})" -f $scene.id, $scene.description)
    Write-Host ('=' * 78)

    try {
        $timedemoArgs = @(
            '-NoProfile', '-File', $timedemoScript,
            '-DemoName', [string]$scene.demo,
            '-Runs', [string]$effectiveRuns,
            '-TimeoutSeconds', [string]$TimeoutSeconds,
            '-FrameChecksums',
            '-FrameCaptureIndex', [string]$scene.captureFrame,
            '-ExpectedFrames', [string]$scene.expectedFrames
        )
        if (-not $SkipGoldenImageComparison) {
            $timedemoArgs += @('-ExpectedChecksum', [string]$scene.expectedChecksum)
        }
        else {
            # timedemo-dos.ps1 has a legacy pinned-checksum default. Pass zero
            # explicitly so paired runs defer checksum parity to the exact
            # C-versus-assembly stream comparator.
            $timedemoArgs += @('-ExpectedChecksum', '0')
        }
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
        $demoFixtureProperty = $scene.PSObject.Properties['demoFixture']
        if ($null -ne $demoFixtureProperty) {
            if ($null -eq $demoFixtureProperty.Value -or $demoFixtureProperty.Value -is [array]) {
                throw "Scenario '$($scene.id)' demoFixture must be a JSON object."
            }
            $demoFixtureJson = ConvertTo-Json -InputObject $demoFixtureProperty.Value -Compress -Depth 4
            $timedemoArgs += @('-DemoFixtureJson', $demoFixtureJson)
        }
        if ($NoBootstrap) { $timedemoArgs += '-NoBootstrap' }
        if ($SkipBuild) { $timedemoArgs += '-SkipBuild' }
        if ($VisualParityOnly) { $timedemoArgs += '-VisualParityOnly' }
        if (-not [string]::IsNullOrWhiteSpace($ToolRoot)) { $timedemoArgs += @('-ToolRoot', $ToolRoot) }
        if (-not [string]::IsNullOrWhiteSpace($DataRoot)) { $timedemoArgs += @('-DataRoot', $DataRoot) }
        $timedemoArgs += @('-CpuTarget', $CpuTarget)
        if ($null -ne $rendererSelectorProfileData) {
            foreach ($selector in @($rendererSelectorProfileData.selectors.PSObject.Properties)) {
                $timedemoArgs += @("-$($selector.Name)", [string]$selector.Value)
            }
        }

        $timedemoRun = Invoke-StreamingTimedemo -Executable $pwshCommand.Source -Arguments $timedemoArgs
        $childOutput = @($timedemoRun.Output)
        $childExit = $timedemoRun.ExitCode
        $childOutputText = $childOutput -join [Environment]::NewLine
        $childOutputText | Set-Content -LiteralPath (Join-Path $sceneOutput 'timedemo-output.txt') -Encoding UTF8
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

        $referencePath = $null
        $referenceRelativePath = [string]$scene.reference
        if ([string]::IsNullOrWhiteSpace($referenceRelativePath)) {
            if (-not $SkipGoldenImageComparison) {
                throw "Scenario '$($scene.id)' must define a reference image unless golden comparison is deferred to the exact paired-profile check."
            }
        }
        else {
            $referencePath = [IO.Path]::GetFullPath((Join-Path $repoRoot $referenceRelativePath))
            if (-not (Test-Path -LiteralPath $referencePath -PathType Leaf)) {
                throw "Scenario reference image is missing: '$referencePath'."
            }
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
            # Event frame indices are absolute offsets in the full checksum
            # stream. Warmup exclusion affects only post-warmup stability metrics.
            $checksumStreamFrameCount = $frameData.Checksums.Count
            $checksumPostWarmupFrameCount = [math]::Max(0, $checksumStreamFrameCount - $warmupChecksumFrames)
            if ($null -ne $expectedChecksumStreamFrames -and
                $checksumStreamFrameCount -ne $expectedChecksumStreamFrames) {
                $sceneStatus = 'FAIL'
                $failures.Add([pscustomobject]@{
                        scenario = $scene.id
                        test = 'expected-checksum-stream-frame-count'
                        expected = $expectedChecksumStreamFrames
                        actual = $checksumStreamFrameCount
                        metrics = @{ frameChecksumPath = $frameData.Path; timedemoFrames = $run.frames }
                        capturedOutput = @{ timedemoResult = $timedemoResultPath; frameChecksums = $frameData.Path }
                    })
            }
            $blobExplosionFramesProperty = $diagnostics.PSObject.Properties['blobExplosionEventFrames']
            $blobExplosionOverflowProperty = $diagnostics.PSObject.Properties['blobExplosionEventOverflow']
            $blobExplosionEventFrames = $null
            $blobExplosionEventOverflow = $null
            $blobExplosionEventFramesPresent = $false
            $blobExplosionEventOverflowPresent = $false
            $invalidBlobExplosionEventFrames = @()
            if ($null -ne $blobExplosionFramesProperty -and $blobExplosionFramesProperty.Value -is [System.Array]) {
                $blobExplosionEventFramesPresent = $true
                $blobExplosionEventFrames = @($blobExplosionFramesProperty.Value | ForEach-Object { [int]$_ })
                $invalidBlobExplosionEventFrames = @($blobExplosionEventFrames | Where-Object {
                        $_ -lt 0 -or $_ -ge $checksumStreamFrameCount
                    })
            }
            if ($null -ne $blobExplosionOverflowProperty -and $null -ne $blobExplosionOverflowProperty.Value) {
                $blobExplosionEventOverflowPresent = $true
                $blobExplosionEventOverflow = [int]$blobExplosionOverflowProperty.Value
            }
            $blobExplosionEventFrameSignature = if ($blobExplosionEventFramesPresent) {
                [string]::Join(',', [string[]]$blobExplosionEventFrames)
            }
            else {
                $null
            }

            $lavaSplashFramesProperty = $diagnostics.PSObject.Properties['lavaSplashEventFrames']
            $lavaSplashCountProperty = $diagnostics.PSObject.Properties['lavaSplashEventCount']
            $lavaSplashOverflowProperty = $diagnostics.PSObject.Properties['lavaSplashEventOverflow']
            $lavaSplashEventFrames = $null
            $lavaSplashEventCount = $null
            $lavaSplashEventOverflow = $null
            $lavaSplashEventFramesPresent = $false
            $lavaSplashEventCountPresent = $false
            $lavaSplashEventOverflowPresent = $false
            $invalidLavaSplashEventFrames = @()
            if ($null -ne $lavaSplashFramesProperty -and $lavaSplashFramesProperty.Value -is [System.Array]) {
                $lavaSplashEventFramesPresent = $true
                $lavaSplashEventFrames = @($lavaSplashFramesProperty.Value | ForEach-Object { [int]$_ })
                $invalidLavaSplashEventFrames = @($lavaSplashEventFrames | Where-Object {
                        $_ -lt 0 -or $_ -ge $checksumStreamFrameCount
                    })
            }
            if ($null -ne $lavaSplashCountProperty -and $null -ne $lavaSplashCountProperty.Value) {
                $lavaSplashEventCountPresent = $true
                $lavaSplashEventCount = [int]$lavaSplashCountProperty.Value
            }
            if ($null -ne $lavaSplashOverflowProperty -and $null -ne $lavaSplashOverflowProperty.Value) {
                $lavaSplashEventOverflowPresent = $true
                $lavaSplashEventOverflow = [int]$lavaSplashOverflowProperty.Value
            }
            $lavaSplashEventFrameSignature = if ($lavaSplashEventFramesPresent) {
                [string]::Join(',', [string[]]$lavaSplashEventFrames)
            }
            else {
                $null
            }

            $teleportSplashFramesProperty = $diagnostics.PSObject.Properties['teleportSplashEventFrames']
            $teleportSplashCountProperty = $diagnostics.PSObject.Properties['teleportSplashEventCount']
            $teleportSplashOverflowProperty = $diagnostics.PSObject.Properties['teleportSplashEventOverflow']
            $teleportSplashEventFrames = $null
            $teleportSplashEventCount = $null
            $teleportSplashEventOverflow = $null
            $teleportSplashEventFramesPresent = $false
            $teleportSplashEventCountPresent = $false
            $teleportSplashEventOverflowPresent = $false
            $invalidTeleportSplashEventFrames = @()
            if ($null -ne $teleportSplashFramesProperty -and $teleportSplashFramesProperty.Value -is [System.Array]) {
                $teleportSplashEventFramesPresent = $true
                $teleportSplashEventFrames = @($teleportSplashFramesProperty.Value | ForEach-Object { [int]$_ })
                $invalidTeleportSplashEventFrames = @($teleportSplashEventFrames | Where-Object {
                        $_ -lt 0 -or $_ -ge $checksumStreamFrameCount
                    })
            }
            if ($null -ne $teleportSplashCountProperty -and $null -ne $teleportSplashCountProperty.Value) {
                $teleportSplashEventCountPresent = $true
                $teleportSplashEventCount = [int]$teleportSplashCountProperty.Value
            }
            if ($null -ne $teleportSplashOverflowProperty -and $null -ne $teleportSplashOverflowProperty.Value) {
                $teleportSplashEventOverflowPresent = $true
                $teleportSplashEventOverflow = [int]$teleportSplashOverflowProperty.Value
            }
            $teleportSplashEventFrameSignature = if ($teleportSplashEventFramesPresent) {
                [string]::Join(',', [string[]]$teleportSplashEventFrames)
            }
            else {
                $null
            }

            $runParticleEffectFramesProperty = $diagnostics.PSObject.Properties['runParticleEffectEventFrames']
            $runParticleEffectCountProperty = $diagnostics.PSObject.Properties['runParticleEffectEventCount']
            $runParticleEffectOverflowProperty = $diagnostics.PSObject.Properties['runParticleEffectEventOverflow']
            $runParticleEffectEventFrames = $null
            $runParticleEffectEventCount = $null
            $runParticleEffectEventOverflow = $null
            $runParticleEffectEventFramesPresent = $false
            $runParticleEffectEventCountPresent = $false
            $runParticleEffectEventOverflowPresent = $false
            $invalidRunParticleEffectEventFrames = @()
            if ($null -ne $runParticleEffectFramesProperty -and $runParticleEffectFramesProperty.Value -is [System.Array]) {
                $runParticleEffectEventFramesPresent = $true
                $runParticleEffectEventFrames = @($runParticleEffectFramesProperty.Value | ForEach-Object { [int]$_ })
                $invalidRunParticleEffectEventFrames = @($runParticleEffectEventFrames | Where-Object {
                        $_ -lt 0 -or $_ -ge $checksumStreamFrameCount
                    })
            }
            if ($null -ne $runParticleEffectCountProperty -and $null -ne $runParticleEffectCountProperty.Value) {
                $runParticleEffectEventCountPresent = $true
                $runParticleEffectEventCount = [int]$runParticleEffectCountProperty.Value
            }
            if ($null -ne $runParticleEffectOverflowProperty -and $null -ne $runParticleEffectOverflowProperty.Value) {
                $runParticleEffectEventOverflowPresent = $true
                $runParticleEffectEventOverflow = [int]$runParticleEffectOverflowProperty.Value
            }
            $runParticleEffectEventFrameSignature = if ($runParticleEffectEventFramesPresent) {
                [string]::Join(',', [string[]]$runParticleEffectEventFrames)
            }
            else {
                $null
            }

            $entityParticlesFramesProperty = $diagnostics.PSObject.Properties['entityParticlesEventFrames']
            $entityParticlesCountProperty = $diagnostics.PSObject.Properties['entityParticlesEventCount']
            $entityParticlesOverflowProperty = $diagnostics.PSObject.Properties['entityParticlesEventOverflow']
            $entityParticlesEventFrames = $null
            $entityParticlesEventCount = $null
            $entityParticlesEventOverflow = $null
            $entityParticlesEventFramesPresent = $false
            $entityParticlesEventCountPresent = $false
            $entityParticlesEventOverflowPresent = $false
            $invalidEntityParticlesEventFrames = @()
            if ($null -ne $entityParticlesFramesProperty -and $entityParticlesFramesProperty.Value -is [System.Array]) {
                $entityParticlesEventFramesPresent = $true
                $entityParticlesEventFrames = @($entityParticlesFramesProperty.Value | ForEach-Object { [int]$_ })
                $invalidEntityParticlesEventFrames = @($entityParticlesEventFrames | Where-Object {
                        $_ -lt 0 -or $_ -ge $checksumStreamFrameCount
                    })
            }
            if ($null -ne $entityParticlesCountProperty -and $null -ne $entityParticlesCountProperty.Value) {
                $entityParticlesEventCountPresent = $true
                $entityParticlesEventCount = [int]$entityParticlesCountProperty.Value
            }
            if ($null -ne $entityParticlesOverflowProperty -and $null -ne $entityParticlesOverflowProperty.Value) {
                $entityParticlesEventOverflowPresent = $true
                $entityParticlesEventOverflow = [int]$entityParticlesOverflowProperty.Value
            }
            $entityParticlesEventFrameSignature = if ($entityParticlesEventFramesPresent) {
                [string]::Join(',', [string[]]$entityParticlesEventFrames)
            }
            else {
                $null
            }

            $blobExplosionEventRepeatParity = $null
            $blobExplosionEventRepeatComparison = $null
            if ($requiredBenchEvents -contains 'blobExplosion') {
                if ($null -ne $previousBlobExplosionEventState) {
                    $blobExplosionEventRepeatComparison = Compare-Bench486EventRepeat `
                        -ReferenceFramesPresent $previousBlobExplosionEventState.framesPresent `
                        -ReferenceFramesSignature $previousBlobExplosionEventState.framesSignature `
                        -ReferenceOverflowPresent $previousBlobExplosionEventState.overflowPresent `
                        -ReferenceOverflow $previousBlobExplosionEventState.overflow `
                        -CandidateFramesPresent $blobExplosionEventFramesPresent `
                        -CandidateFramesSignature $blobExplosionEventFrameSignature `
                        -CandidateOverflowPresent $blobExplosionEventOverflowPresent `
                        -CandidateOverflow $blobExplosionEventOverflow
                    $blobExplosionEventRepeatParity = if ($blobExplosionEventRepeatComparison.exactMatch) { 'PASS' } else { 'FAIL' }
                    if (-not $blobExplosionEventRepeatComparison.exactMatch) {
                        $sceneStatus = 'FAIL'
                        $failures.Add([pscustomobject]@{
                                scenario = $scene.id
                                test = 'repeat-blob-explosion-event-stability'
                                expected = @{
                                    frames = $previousBlobExplosionEventState.frames
                                    overflow = $previousBlobExplosionEventState.overflow
                                }
                                actual = @{ frames = $blobExplosionEventFrames; overflow = $blobExplosionEventOverflow }
                                metrics = $blobExplosionEventRepeatComparison
                                capturedOutput = @{ timedemoResult = $timedemoResultPath }
                            })
                    }
                }
                $previousBlobExplosionEventState = [pscustomobject]@{
                    framesPresent = $blobExplosionEventFramesPresent
                    frames = $blobExplosionEventFrames
                    framesSignature = $blobExplosionEventFrameSignature
                    overflowPresent = $blobExplosionEventOverflowPresent
                    overflow = $blobExplosionEventOverflow
                }
            }
            $lavaSplashEventRepeatParity = $null
            $lavaSplashEventRepeatComparison = $null
            if ($requiredBenchEvents -contains 'lavaSplash') {
                if ($null -ne $previousLavaSplashEventState) {
                    $lavaSplashEventRepeatComparison = Compare-Bench486EventRepeat `
                        -ReferenceFramesPresent $previousLavaSplashEventState.framesPresent `
                        -ReferenceFramesSignature $previousLavaSplashEventState.framesSignature `
                        -ReferenceOverflowPresent $previousLavaSplashEventState.overflowPresent `
                        -ReferenceOverflow $previousLavaSplashEventState.overflow `
                        -CandidateFramesPresent $lavaSplashEventFramesPresent `
                        -CandidateFramesSignature $lavaSplashEventFrameSignature `
                        -CandidateOverflowPresent $lavaSplashEventOverflowPresent `
                        -CandidateOverflow $lavaSplashEventOverflow
                    $lavaSplashEventRepeatParity = if ($lavaSplashEventRepeatComparison.exactMatch) { 'PASS' } else { 'FAIL' }
                    if (-not $lavaSplashEventRepeatComparison.exactMatch) {
                        $sceneStatus = 'FAIL'
                        $failures.Add([pscustomobject]@{
                                scenario = $scene.id
                                test = 'repeat-lava-splash-event-stability'
                                expected = @{
                                    frames = $previousLavaSplashEventState.frames
                                    overflow = $previousLavaSplashEventState.overflow
                                }
                                actual = @{ frames = $lavaSplashEventFrames; overflow = $lavaSplashEventOverflow }
                                metrics = $lavaSplashEventRepeatComparison
                                capturedOutput = @{ timedemoResult = $timedemoResultPath }
                            })
                    }
                }
                $previousLavaSplashEventState = [pscustomobject]@{
                    framesPresent = $lavaSplashEventFramesPresent
                    frames = $lavaSplashEventFrames
                    framesSignature = $lavaSplashEventFrameSignature
                    overflowPresent = $lavaSplashEventOverflowPresent
                    overflow = $lavaSplashEventOverflow
                }
            }
            $teleportSplashEventRepeatParity = $null
            $teleportSplashEventRepeatComparison = $null
            if ($requiredBenchEvents -contains 'teleportSplash') {
                if ($null -ne $previousTeleportSplashEventState) {
                    $teleportSplashEventRepeatComparison = Compare-Bench486EventRepeat `
                        -ReferenceFramesPresent $previousTeleportSplashEventState.framesPresent `
                        -ReferenceFramesSignature $previousTeleportSplashEventState.framesSignature `
                        -ReferenceOverflowPresent $previousTeleportSplashEventState.overflowPresent `
                        -ReferenceOverflow $previousTeleportSplashEventState.overflow `
                        -CandidateFramesPresent $teleportSplashEventFramesPresent `
                        -CandidateFramesSignature $teleportSplashEventFrameSignature `
                        -CandidateOverflowPresent $teleportSplashEventOverflowPresent `
                        -CandidateOverflow $teleportSplashEventOverflow
                    $teleportSplashEventRepeatParity = if ($teleportSplashEventRepeatComparison.exactMatch) { 'PASS' } else { 'FAIL' }
                    if (-not $teleportSplashEventRepeatComparison.exactMatch) {
                        $sceneStatus = 'FAIL'
                        $failures.Add([pscustomobject]@{
                                scenario = $scene.id
                                test = 'repeat-teleport-splash-event-stability'
                                expected = @{
                                    frames = $previousTeleportSplashEventState.frames
                                    overflow = $previousTeleportSplashEventState.overflow
                                }
                                actual = @{ frames = $teleportSplashEventFrames; overflow = $teleportSplashEventOverflow }
                                metrics = $teleportSplashEventRepeatComparison
                                capturedOutput = @{ timedemoResult = $timedemoResultPath }
                            })
                    }
                }
                $previousTeleportSplashEventState = [pscustomobject]@{
                    framesPresent = $teleportSplashEventFramesPresent
                    frames = $teleportSplashEventFrames
                    framesSignature = $teleportSplashEventFrameSignature
                    overflowPresent = $teleportSplashEventOverflowPresent
                    overflow = $teleportSplashEventOverflow
                }
            }
            $runParticleEffectEventRepeatParity = $null
            $runParticleEffectEventRepeatComparison = $null
            if ($requiredBenchEvents -contains 'runParticleEffect') {
                if ($null -ne $previousRunParticleEffectEventState) {
                    $runParticleEffectEventRepeatComparison = Compare-Bench486EventRepeat `
                        -ReferenceFramesPresent $previousRunParticleEffectEventState.framesPresent `
                        -ReferenceFramesSignature $previousRunParticleEffectEventState.framesSignature `
                        -ReferenceOverflowPresent $previousRunParticleEffectEventState.overflowPresent `
                        -ReferenceOverflow $previousRunParticleEffectEventState.overflow `
                        -CandidateFramesPresent $runParticleEffectEventFramesPresent `
                        -CandidateFramesSignature $runParticleEffectEventFrameSignature `
                        -CandidateOverflowPresent $runParticleEffectEventOverflowPresent `
                        -CandidateOverflow $runParticleEffectEventOverflow
                    $runParticleEffectEventRepeatParity = if ($runParticleEffectEventRepeatComparison.exactMatch) { 'PASS' } else { 'FAIL' }
                    if (-not $runParticleEffectEventRepeatComparison.exactMatch) {
                        $sceneStatus = 'FAIL'
                        $failures.Add([pscustomobject]@{
                                scenario = $scene.id
                                test = 'repeat-run-particle-effect-event-stability'
                                expected = @{
                                    frames = $previousRunParticleEffectEventState.frames
                                    overflow = $previousRunParticleEffectEventState.overflow
                                }
                                actual = @{ frames = $runParticleEffectEventFrames; overflow = $runParticleEffectEventOverflow }
                                metrics = $runParticleEffectEventRepeatComparison
                                capturedOutput = @{ timedemoResult = $timedemoResultPath }
                            })
                    }
                }
                $previousRunParticleEffectEventState = [pscustomobject]@{
                    framesPresent = $runParticleEffectEventFramesPresent
                    frames = $runParticleEffectEventFrames
                    framesSignature = $runParticleEffectEventFrameSignature
                    overflowPresent = $runParticleEffectEventOverflowPresent
                    overflow = $runParticleEffectEventOverflow
                }
            }
            $frameReports.Add([pscustomobject]@{
                    run = $run.run
                    frames = $frameData.Count
                    checksumStreamFrames = $checksumStreamFrameCount
                    checksumFramesAfterWarmup = $checksumPostWarmupFrameCount
                    timedemoFrames = $run.frames
                    uniqueAfterWarmup = $frameData.UniqueAfterWarmup
                    zeroAfterWarmup = $frameData.ZeroAfterWarmup
                    longestIdenticalRunAfterWarmup = $frameData.LongestIdenticalRunAfterWarmup
                    frameChecksumPath = $frameData.Path
                    blobExplosionEventFrames = $blobExplosionEventFrames
                    blobExplosionEventOverflow = $blobExplosionEventOverflow
                    blobExplosionEventRepeatParity = $blobExplosionEventRepeatParity
                    lavaSplashEventCount = $lavaSplashEventCount
                    lavaSplashEventFrames = $lavaSplashEventFrames
                    lavaSplashEventOverflow = $lavaSplashEventOverflow
                    lavaSplashEventRepeatParity = $lavaSplashEventRepeatParity
                    teleportSplashEventCount = $teleportSplashEventCount
                    teleportSplashEventFrames = $teleportSplashEventFrames
                    teleportSplashEventOverflow = $teleportSplashEventOverflow
                    teleportSplashEventRepeatParity = $teleportSplashEventRepeatParity
                    runParticleEffectEventCount = $runParticleEffectEventCount
                    runParticleEffectEventFrames = $runParticleEffectEventFrames
                    runParticleEffectEventOverflow = $runParticleEffectEventOverflow
                    runParticleEffectEventRepeatParity = $runParticleEffectEventRepeatParity
                    entityParticlesEventCount = $entityParticlesEventCount
                    entityParticlesEventFrames = $entityParticlesEventFrames
                    entityParticlesEventOverflow = $entityParticlesEventOverflow
                    captureBenchEvents = @($captureBenchEvents)
                    captureBenchEventChecks = @()
                    repeatParity = $null
                })

            if ($requiredBenchEvents -contains 'blobExplosion') {
                $eventFailure = $null
                if (-not $blobExplosionEventFramesPresent -or -not $blobExplosionEventOverflowPresent) {
                    $eventFailure = 'required blobExplosion event metadata is missing'
                }
                elseif ($blobExplosionEventFrames.Count -eq 0) {
                    $eventFailure = 'required blobExplosion event count is zero'
                }
                elseif ($invalidBlobExplosionEventFrames.Count -gt 0) {
                    $eventFailure = "blobExplosion event frame index/indices fall outside the total $checksumStreamFrameCount-frame checksum stream; warmup exclusion leaves $checksumPostWarmupFrameCount frame(s) for post-warmup metrics"
                }
                elseif ($blobExplosionEventOverflow -ne 0) {
                    $eventFailure = "blobExplosion event metadata overflowed by $blobExplosionEventOverflow event(s)"
                }
                if ($null -ne $eventFailure) {
                    $sceneStatus = 'FAIL'
                    $failures.Add([pscustomobject]@{
                            scenario = $scene.id
                            test = 'required-bench-event'
                            expected = @{ event = 'blobExplosion'; count = 'greater than zero'; overflow = 0 }
                            actual = @{ frames = $blobExplosionEventFrames; overflow = $blobExplosionEventOverflow }
                            metrics = @{
                                error = $eventFailure
                                invalidFrameIndices = $invalidBlobExplosionEventFrames
                                checksumStreamFrames = $checksumStreamFrameCount
                                checksumFramesAfterWarmup = $checksumPostWarmupFrameCount
                            }
                            capturedOutput = @{ timedemoResult = $timedemoResultPath }
                        })
                }
            }

            if ($requiredBenchEvents -contains 'lavaSplash') {
                $eventFailure = $null
                $expectedLavaSplashEventFrames = @($expectedBenchEventFrames['lavaSplash'])
                $expectedLavaSplashEventSignature = [string]::Join(',', [string[]]$expectedLavaSplashEventFrames)
                $actualLavaSplashEventSignature = if ($lavaSplashEventFramesPresent) {
                    [string]::Join(',', [string[]]$lavaSplashEventFrames)
                }
                else {
                    $null
                }
                if (-not $lavaSplashEventFramesPresent -or -not $lavaSplashEventCountPresent -or
                    -not $lavaSplashEventOverflowPresent) {
                    $eventFailure = 'required lavaSplash event count/frame/overflow metadata is missing'
                }
                elseif ($invalidLavaSplashEventFrames.Count -gt 0) {
                    $eventFailure = "lavaSplash event frame index/indices fall outside the total $checksumStreamFrameCount-frame checksum stream"
                }
                elseif ($lavaSplashEventOverflow -ne 0) {
                    $eventFailure = "lavaSplash event metadata overflowed by $lavaSplashEventOverflow event(s)"
                }
                elseif ($lavaSplashEventCount -ne $expectedLavaSplashEventFrames.Count -or
                    $lavaSplashEventFrames.Count -ne $expectedLavaSplashEventFrames.Count) {
                    $eventFailure = "lavaSplash event count must be exactly $($expectedLavaSplashEventFrames.Count)"
                }
                elseif ($actualLavaSplashEventSignature -ne $expectedLavaSplashEventSignature) {
                    $eventFailure = "lavaSplash event frame indices must be exactly '$expectedLavaSplashEventSignature'"
                }
                if ($null -ne $eventFailure) {
                    $sceneStatus = 'FAIL'
                    $failures.Add([pscustomobject]@{
                            scenario = $scene.id
                            test = 'required-bench-event'
                            expected = @{ event = 'lavaSplash'; count = $expectedLavaSplashEventFrames.Count; frames = $expectedLavaSplashEventFrames; overflow = 0 }
                            actual = @{ count = $lavaSplashEventCount; frames = $lavaSplashEventFrames; overflow = $lavaSplashEventOverflow }
                            metrics = @{
                                error = $eventFailure
                                invalidFrameIndices = $invalidLavaSplashEventFrames
                                checksumStreamFrames = $checksumStreamFrameCount
                            }
                            capturedOutput = @{ timedemoResult = $timedemoResultPath }
                        })
                }
            }

            if ($requiredBenchEvents -contains 'teleportSplash') {
                $eventFailure = $null
                $expectedTeleportSplashEventFrames = @($expectedBenchEventFrames['teleportSplash'])
                $expectedTeleportSplashEventSignature = [string]::Join(',', [string[]]$expectedTeleportSplashEventFrames)
                $actualTeleportSplashEventSignature = if ($teleportSplashEventFramesPresent) {
                    [string]::Join(',', [string[]]$teleportSplashEventFrames)
                }
                else {
                    $null
                }
                if (-not $teleportSplashEventFramesPresent -or -not $teleportSplashEventCountPresent -or
                    -not $teleportSplashEventOverflowPresent) {
                    $eventFailure = 'required teleportSplash event count/frame/overflow metadata is missing'
                }
                elseif ($invalidTeleportSplashEventFrames.Count -gt 0) {
                    $eventFailure = "teleportSplash event frame index/indices fall outside the total $checksumStreamFrameCount-frame checksum stream"
                }
                elseif ($teleportSplashEventOverflow -ne 0) {
                    $eventFailure = "teleportSplash event metadata overflowed by $teleportSplashEventOverflow event(s)"
                }
                elseif ($teleportSplashEventCount -ne $expectedTeleportSplashEventFrames.Count -or
                    $teleportSplashEventFrames.Count -ne $expectedTeleportSplashEventFrames.Count) {
                    $eventFailure = "teleportSplash event count must be exactly $($expectedTeleportSplashEventFrames.Count)"
                }
                elseif ($actualTeleportSplashEventSignature -ne $expectedTeleportSplashEventSignature) {
                    $eventFailure = "teleportSplash event frame indices must be exactly '$expectedTeleportSplashEventSignature'"
                }
                if ($null -ne $eventFailure) {
                    $sceneStatus = 'FAIL'
                    $failures.Add([pscustomobject]@{
                            scenario = $scene.id
                            test = 'required-bench-event'
                            expected = @{ event = 'teleportSplash'; count = $expectedTeleportSplashEventFrames.Count; frames = $expectedTeleportSplashEventFrames; overflow = 0 }
                            actual = @{ count = $teleportSplashEventCount; frames = $teleportSplashEventFrames; overflow = $teleportSplashEventOverflow }
                            metrics = @{
                                error = $eventFailure
                                invalidFrameIndices = $invalidTeleportSplashEventFrames
                                checksumStreamFrames = $checksumStreamFrameCount
                            }
                            capturedOutput = @{ timedemoResult = $timedemoResultPath }
                        })
                }
            }
            if ($requiredBenchEvents -contains 'runParticleEffect') {
                $eventFailure = $null
                $expectedRunParticleEffectEventFrames = @($expectedBenchEventFrames['runParticleEffect'])
                $expectedRunParticleEffectEventSignature = [string]::Join(',', [string[]]$expectedRunParticleEffectEventFrames)
                $actualRunParticleEffectEventSignature = if ($runParticleEffectEventFramesPresent) {
                    [string]::Join(',', [string[]]$runParticleEffectEventFrames)
                }
                else {
                    $null
                }
                if (-not $runParticleEffectEventFramesPresent -or -not $runParticleEffectEventCountPresent -or
                    -not $runParticleEffectEventOverflowPresent) {
                    $eventFailure = 'required runParticleEffect event count/frame/overflow metadata is missing'
                }
                elseif ($invalidRunParticleEffectEventFrames.Count -gt 0) {
                    $eventFailure = "runParticleEffect event frame index/indices fall outside the total $checksumStreamFrameCount-frame checksum stream"
                }
                elseif ($runParticleEffectEventOverflow -ne 0) {
                    $eventFailure = "runParticleEffect event metadata overflowed by $runParticleEffectEventOverflow event(s)"
                }
                elseif ($runParticleEffectEventCount -ne $expectedRunParticleEffectEventFrames.Count -or
                    $runParticleEffectEventFrames.Count -ne $expectedRunParticleEffectEventFrames.Count) {
                    $eventFailure = "runParticleEffect event count must be exactly $($expectedRunParticleEffectEventFrames.Count)"
                }
                elseif ($actualRunParticleEffectEventSignature -ne $expectedRunParticleEffectEventSignature) {
                    $eventFailure = "runParticleEffect event frame indices must be exactly '$expectedRunParticleEffectEventSignature'"
                }
                if ($null -ne $eventFailure) {
                    $sceneStatus = 'FAIL'
                    $failures.Add([pscustomobject]@{
                            scenario = $scene.id
                            test = 'required-bench-event'
                            expected = @{ event = 'runParticleEffect'; count = $expectedRunParticleEffectEventFrames.Count; frames = $expectedRunParticleEffectEventFrames; overflow = 0 }
                            actual = @{ count = $runParticleEffectEventCount; frames = $runParticleEffectEventFrames; overflow = $runParticleEffectEventOverflow }
                            metrics = @{
                                error = $eventFailure
                                invalidFrameIndices = $invalidRunParticleEffectEventFrames
                                checksumStreamFrames = $checksumStreamFrameCount
                            }
                            capturedOutput = @{ timedemoResult = $timedemoResultPath }
                        })
                }
            }

            if ($requiredBenchEvents -contains 'entityParticles') {
                $eventFailure = $null
                $expectedEntityParticlesEventFrames = @($expectedBenchEventFrames['entityParticles'])
                $expectedEntityParticlesEventSignature = [string]::Join(',', [string[]]$expectedEntityParticlesEventFrames)
                $actualEntityParticlesEventSignature = if ($entityParticlesEventFramesPresent) {
                    [string]::Join(',', [string[]]$entityParticlesEventFrames)
                }
                else {
                    $null
                }
                if (-not $entityParticlesEventFramesPresent -or -not $entityParticlesEventCountPresent -or
                    -not $entityParticlesEventOverflowPresent) {
                    $eventFailure = 'required entityParticles event count/frame/overflow metadata is missing'
                }
                elseif ($invalidEntityParticlesEventFrames.Count -gt 0) {
                    $eventFailure = "entityParticles event frame index/indices fall outside the total $checksumStreamFrameCount-frame checksum stream"
                }
                elseif ($entityParticlesEventOverflow -ne 0) {
                    $eventFailure = "entityParticles event metadata overflowed by $entityParticlesEventOverflow event(s)"
                }
                elseif ($entityParticlesEventCount -ne $expectedEntityParticlesEventFrames.Count -or
                    $entityParticlesEventFrames.Count -ne $expectedEntityParticlesEventFrames.Count) {
                    $eventFailure = "entityParticles event count must be exactly $($expectedEntityParticlesEventFrames.Count)"
                }
                elseif ($actualEntityParticlesEventSignature -ne $expectedEntityParticlesEventSignature) {
                    $eventFailure = "entityParticles event frame indices must be exactly '$expectedEntityParticlesEventSignature'"
                }
                if ($null -ne $eventFailure) {
                    $sceneStatus = 'FAIL'
                    $failures.Add([pscustomobject]@{
                            scenario = $scene.id
                            test = 'required-bench-event'
                            expected = @{ event = 'entityParticles'; count = $expectedEntityParticlesEventFrames.Count; frames = $expectedEntityParticlesEventFrames; overflow = 0 }
                            actual = @{ count = $entityParticlesEventCount; frames = $entityParticlesEventFrames; overflow = $entityParticlesEventOverflow }
                            metrics = @{
                                error = $eventFailure
                                invalidFrameIndices = $invalidEntityParticlesEventFrames
                                checksumStreamFrames = $checksumStreamFrameCount
                            }
                            capturedOutput = @{ timedemoResult = $timedemoResultPath }
                        })
                }
            }

            $captureBenchEventChecks = @()
            foreach ($captureBenchEvent in $captureBenchEvents) {
                $capturedFrameIndexProperty = $diagnostics.PSObject.Properties['frameCaptureIndex']
                $capturedFrameIndex = if ($null -ne $capturedFrameIndexProperty -and
                    $null -ne $capturedFrameIndexProperty.Value) {
                    [int]$capturedFrameIndexProperty.Value
                }
                else {
                    $null
                }
                $eventFrames = if ($captureBenchEvent -eq 'blobExplosion') {
                    $blobExplosionEventFrames
                }
                elseif ($captureBenchEvent -eq 'lavaSplash') {
                    $lavaSplashEventFrames
                }
                elseif ($captureBenchEvent -eq 'teleportSplash') {
                    $teleportSplashEventFrames
                }
                elseif ($captureBenchEvent -eq 'runParticleEffect') {
                    $runParticleEffectEventFrames
                }
                elseif ($captureBenchEvent -eq 'entityParticles') {
                    $entityParticlesEventFrames
                }
                else {
                    @()
                }
                $captureContainsEvent = $null -ne $capturedFrameIndex -and
                    $null -ne $eventFrames -and $eventFrames -contains $capturedFrameIndex
                $captureBenchEventChecks += [pscustomobject]@{
                    event = $captureBenchEvent
                    captureFrameIndex = $capturedFrameIndex
                    eventFrameIndices = $eventFrames
                    pass = [bool]$captureContainsEvent
                }
                if (-not $captureContainsEvent) {
                    $sceneStatus = 'FAIL'
                    $failures.Add([pscustomobject]@{
                            scenario = $scene.id
                            test = 'capture-bench-event'
                            expected = @{ event = $captureBenchEvent; captureFrameInEventFrames = $true }
                            actual = @{ captureFrameIndex = $capturedFrameIndex; eventFrameIndices = $eventFrames }
                            metrics = @{ captureFrame = $scene.captureFrame }
                            capturedOutput = @{ timedemoResult = $timedemoResultPath; capture = $diagnostics.frameCapturePath }
                        })
                }
            }
            if ($captureBenchEventChecks.Count -gt 0) {
                $frameReports[$frameReports.Count - 1].captureBenchEventChecks = @($captureBenchEventChecks)
            }

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
            if ($SkipGoldenImageComparison) {
                $imageReport = [pscustomobject]@{
                    pass = $true
                    comparison = 'deferred-to-exact-paired-profile-comparison'
                    reference = @{ path = $referencePath; validation = 'skipped' }
                    actual = @{ path = [string]$diagnostics.frameCapturePath }
                }
                $imageReports.Add($imageReport)
                Write-Host ("  run {0}: committed-golden comparison deferred to paired profile check" -f $run.run)
                continue
            }
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
            repeatRuns = $effectiveRuns
            expectedFrames = $scene.expectedFrames
            expectedChecksumStreamFrames = $expectedChecksumStreamFrames
            expectedChecksum = $scene.expectedChecksum
            requiredBenchEvents = $requiredBenchEvents
            expectedBenchEventFrames = $expectedBenchEventFrames
            captureBenchEvents = $captureBenchEvents
            captureFrame = $scene.captureFrame
            rendererSelectorProfile = if ($null -ne $rendererSelectorProfileData) { [string]$rendererSelectorProfileData.id } else { 'timedemo-defaults' }
            rendererSelectorProfilePath = $rendererSelectorProfilePathResolved
            rendererSelectors = if ($null -ne $rendererSelectorProfileData) { $rendererSelectorProfileData.selectors } else { @{} }
            tolerance = $effectiveTolerance
            reference = $referencePath
            validationAutoexecCommands = $effectiveAutoexecCommands
            ignoredWarmupChecksumFrames = $warmupChecksumFrames
            visualParityOnly = [bool]$VisualParityOnly
            isaAuditStatus = if ($VisualParityOnly) { 'SKIPPED' } elseif ($null -ne $timedemoJson) { $timedemoJson.isaAuditStatus } else { 'NOT_RUN' }
            buildIsaAuditStatus = if ($null -ne $timedemoJson) { $timedemoJson.isaAuditStatus } else { 'NOT_RUN' }
            providerVerification = if ($null -ne $timedemoJson) { $timedemoJson.providerVerification } else { $null }
            timedemoResult = $timedemoResultPath
            sourceFingerprint = if ($null -ne $timedemoJson) { $timedemoJson.sourceFingerprint } else { $null }
            sourceTreeFingerprint = if ($null -ne $timedemoJson) { $timedemoJson.sourceTreeFingerprint } else { $null }
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
    visualParityOnly = [bool]$VisualParityOnly
    isaAuditStatus = if ($VisualParityOnly) { 'SKIPPED' } elseif ($CpuTarget -eq 'i486' -and $scenarioResults.Count -gt 0) { [string]$scenarioResults[0].buildIsaAuditStatus } elseif ($scenarioResults.Count -eq 0) { 'NOT_RUN' } else { 'NOT_ASSERTED' }
    rendererSelectorProfile = if ($null -ne $rendererSelectorProfileData) { [string]$rendererSelectorProfileData.id } else { 'timedemo-defaults' }
    rendererSelectorProfilePath = $rendererSelectorProfilePathResolved
    rendererSelectors = if ($null -ne $rendererSelectorProfileData) { $rendererSelectorProfileData.selectors } else { @{} }
    sourceTreeFingerprint = if ($scenarioResults.Count -gt 0) { $scenarioResults[0].sourceTreeFingerprint } else { $null }
    validationAutoexecCommands = $validationAutoexecCommands
    goldenImageComparison = if ($SkipGoldenImageComparison) { 'deferred-to-paired-profile-comparison' } else { 'committed-reference' }
    expectedChecksumValidation = if ($SkipGoldenImageComparison) { 'deferred-to-exact-paired-profile-comparison' } else { 'committed-reference' }
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

[CmdletBinding()]
param(
    [ValidateRange(1, 9)]
    [int]$Runs = 5,
    [string]$DataRoot,
    [string]$ToolRoot,
    [switch]$SkipBuild,
    [switch]$NoBootstrap,
    [int]$TimeoutSeconds = 180,
    [string]$QuakeExtraArgs = '',
    # Optional second HDPMI pass with DJGPP-friendly -m (disable DPMI 1.0 mem APIs).
    [switch]$AlsoHdpmiMinusM
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$timedemo = Join-Path $PSScriptRoot 'timedemo-dos.ps1'
$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$compareRoot = Join-Path (Join-Path $repoRoot 'out') ("dos-dpmi-compare-$stamp")
New-Item -ItemType Directory -Path $compareRoot -Force | Out-Null

function Invoke-DpmiTimedemo {
    param(
        [Parameter(Mandatory = $true)][string]$DpmiHost,
        [string]$HdpmiExtraArgs = ''
    )

    $args = @{
        SkipBuild = $true
        Runs = $Runs
        TimeoutSeconds = $TimeoutSeconds
        DpmiHost = $DpmiHost
    }
    if ($NoBootstrap) { $args.NoBootstrap = $true }
    if (-not [string]::IsNullOrWhiteSpace($DataRoot)) { $args.DataRoot = $DataRoot }
    if (-not [string]::IsNullOrWhiteSpace($ToolRoot)) { $args.ToolRoot = $ToolRoot }
    if (-not [string]::IsNullOrWhiteSpace($QuakeExtraArgs)) { $args.QuakeExtraArgs = $QuakeExtraArgs }
    if ($DpmiHost -eq 'hdpmi32' -and -not [string]::IsNullOrWhiteSpace($HdpmiExtraArgs)) {
        $args.HdpmiExtraArgs = $HdpmiExtraArgs
    }

    Write-Host ""
    Write-Host "=== DPMI compare: $DpmiHost $(if ($HdpmiExtraArgs) { "($HdpmiExtraArgs)" }) ==="
    & $timedemo @args
}

function Read-LatestTimedemoResult {
    param([Parameter(Mandatory = $true)][string]$HostTag)

    $pattern = if ($HostTag -eq 'cwsdpmi') {
        'dos-timedemo-20*'
    }
    else {
        'dos-timedemo-hdpmi32-*'
    }
    $dirs = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'out') -Directory |
        Where-Object { $_.Name -like $pattern } |
        Sort-Object LastWriteTimeUtc -Descending)
    if ($dirs.Count -eq 0) {
        throw "No timedemo staging directory matched '$pattern'."
    }
    # For cwsdpmi, exclude hdpmi32-tagged dirs.
    if ($HostTag -eq 'cwsdpmi') {
        $dirs = @($dirs | Where-Object { $_.Name -notlike '*-hdpmi32-*' })
    }
    $resultPath = Join-Path $dirs[0].FullName 'timedemo-result.json'
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        throw "Missing timedemo result: '$resultPath'."
    }
    return Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
}

function Get-ChecksumFromResult {
    param($Result)

    foreach ($run in @($Result.results)) {
        if ($run.report -match 'framebuffer-checksum\s+(\d+)') {
            return $Matches[1]
        }
    }
    return $null
}

function Get-FpsSpread {
    param($Result)

    $values = @($Result.results | ForEach-Object { [double]$_.fps } | Sort-Object)
    if ($values.Count -eq 0) { return $null }
    return [ordered]@{
        min = $values[0]
        max = $values[$values.Count - 1]
        range = $values[$values.Count - 1] - $values[0]
        values = $values
    }
}

# Freeze the binary under test once; both hosts reuse the same qbench.exe.
$common = @{
    SkipBuild = $true
    Runs = $Runs
    TimeoutSeconds = $TimeoutSeconds
}
if ($NoBootstrap) { $common.NoBootstrap = $true }
if (-not [string]::IsNullOrWhiteSpace($DataRoot)) { $common.DataRoot = $DataRoot }
if (-not [string]::IsNullOrWhiteSpace($ToolRoot)) { $common.ToolRoot = $ToolRoot }

if (-not $SkipBuild) {
    $build = Join-Path $PSScriptRoot 'build-dos.ps1'
    $buildArgs = @('-Benchmark')
    if (-not [string]::IsNullOrWhiteSpace($ToolRoot)) { $buildArgs += @('-ToolRoot', $ToolRoot) }
    if ($NoBootstrap) { $buildArgs += '-NoBootstrap' }
    Write-Host 'Ensuring qbench.exe is built once for both DPMI hosts...'
    & $build @buildArgs
}

Invoke-DpmiTimedemo -DpmiHost 'cwsdpmi'
$cws = Read-LatestTimedemoResult -HostTag 'cwsdpmi'

Invoke-DpmiTimedemo -DpmiHost 'hdpmi32'
$hdpmi = Read-LatestTimedemoResult -HostTag 'hdpmi32'

$hdpmiM = $null
if ($AlsoHdpmiMinusM) {
    Invoke-DpmiTimedemo -DpmiHost 'hdpmi32' -HdpmiExtraArgs '-m'
    # Latest hdpmi32 result is the -m pass.
    $hdpmiM = Read-LatestTimedemoResult -HostTag 'hdpmi32'
}

function New-HostSummary {
    param($Result, [string]$Label)

    $spread = Get-FpsSpread $Result
    $sum = $Result.fpsSummary
    return [ordered]@{
        label = $Label
        dpmiHost = $Result.dpmiHost
        hdpmiExtraArgs = $Result.hdpmiExtraArgs
        dpmiHostSha256 = $Result.dpmiHostSha256
        dpmiHostProbe = $Result.dpmiHostProbe
        stagingRoot = $Result.stagingRoot
        executable = $Result.executable
        runs = $Result.runs
        medianFps = $Result.medianFps
        fpsSpread = $spread
        framebufferChecksum = Get-ChecksumFromResult $Result
        fpsSummary = $sum
    }
}

$summaries = @(
    (New-HostSummary $cws 'cwsdpmi'),
    (New-HostSummary $hdpmi 'hdpmi32 -r')
)
if ($null -ne $hdpmiM) {
    $summaries += ,(New-HostSummary $hdpmiM 'hdpmi32 -r -m')
}

$delta = $null
if ($null -ne $cws.medianFps -and $null -ne $hdpmi.medianFps -and $cws.medianFps -ne 0) {
    $deltaFps = [double]$hdpmi.medianFps - [double]$cws.medianFps
    $deltaPct = 100.0 * $deltaFps / [double]$cws.medianFps
    $cwsSeconds = if ($null -ne $cws.fpsSummary) { [double]$cws.fpsSummary.durationSeconds } else { $null }
    $hdpmiSeconds = if ($null -ne $hdpmi.fpsSummary) { [double]$hdpmi.fpsSummary.durationSeconds } else { $null }
    $deltaSeconds = if ($null -ne $cwsSeconds -and $null -ne $hdpmiSeconds) {
        $hdpmiSeconds - $cwsSeconds
    } else { $null }

    $noiseFloor = $null
    $cwsSpread = Get-FpsSpread $cws
    $hdpmiSpread = Get-FpsSpread $hdpmi
    if ($null -ne $cwsSpread -and $null -ne $hdpmiSpread) {
        $noiseFloor = [math]::Max([double]$cwsSpread.range, [double]$hdpmiSpread.range)
    }

    $verdict = 'inconclusive'
    $knownGoodChecksum = '4154140932'
    $cwsChecksum = Get-ChecksumFromResult $cws
    $hdpmiChecksum = Get-ChecksumFromResult $hdpmi
    if ($hdpmiChecksum -ne $knownGoodChecksum) {
        $verdict = 'hdpmi32_incompatible_checksum'
    }
    elseif ($cwsChecksum -ne $knownGoodChecksum) {
        $verdict = 'cwsdpmi_unexpected_checksum'
    }
    elseif ($null -ne $noiseFloor) {
        if ([math]::Abs($deltaFps) -le ($noiseFloor + 0.0005)) {
            $verdict = 'no_measurable_benefit'
        }
        elseif ($deltaFps > ($noiseFloor + 0.0005)) {
            $verdict = 'hdpmi32_faster'
        }
        else {
            $verdict = 'cwsdpmi_faster'
        }
    }

    $delta = [ordered]@{
        medianFpsDelta = $deltaFps
        medianFpsDeltaPercent = $deltaPct
        durationSecondsDelta = $deltaSeconds
        noiseFloorFps = $noiseFloor
        cwsChecksum = $cwsChecksum
        hdpmiChecksum = $hdpmiChecksum
        knownGoodChecksum = $knownGoodChecksum
        verdict = $verdict
    }
}

$compare = [ordered]@{
    schema = 1
    createdUtc = (Get-Date).ToUniversalTime().ToString('o')
    methodology = [ordered]@{
        demo = 'demo1'
        runsPerHost = $Runs
        sameExecutable = $true
        engineUnchanged = $true
        dosboxProfile = 'tools/dosbox-x-486-high.conf'
        notes = @(
            'CWSDPMI: stage cwsdpmi.exe; DJGPP stub auto-loads it.',
            'HDPMI32: omit cwsdpmi.exe; run HDPMI32 -r then DPMI.EXE probe then qbench.exe.',
            'Verdict treats the larger per-host FPS range as the noise floor.'
        )
    }
    hosts = $summaries
    hdpmi32VsCwsdpmi = $delta
}

$comparePath = Join-Path $compareRoot 'dpmi-compare-result.json'
$compare | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $comparePath -Encoding ASCII

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine('# DPMI host comparison (CWSDPMI vs HDPMI32)')
[void]$md.AppendLine('')
[void]$md.AppendLine(('Created (UTC): {0}' -f $compare.createdUtc))
[void]$md.AppendLine('')
[void]$md.AppendLine('## Setup')
[void]$md.AppendLine('')
[void]$md.AppendLine('- Same qbench.exe, demo1, DOSBox-X 486-high profile, no engine changes.')
[void]$md.AppendLine(('- Runs per host: {0}' -f $Runs))
[void]$md.AppendLine('- CWSDPMI: cwsdpmi.exe beside the EXE (stub auto-load).')
[void]$md.AppendLine('- HDPMI32: HDPMI32 -r, no cwsdpmi.exe, verified with DPMI.EXE.')
[void]$md.AppendLine('')
[void]$md.AppendLine('## Results')
[void]$md.AppendLine('')
[void]$md.AppendLine('| Host | Median FPS | Duration (s) | 1% low | 0.1% low | High 1% | Stddev | Drops | Spikes | Checksum |')
[void]$md.AppendLine('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |')
foreach ($s in $summaries) {
    $fs = $s.fpsSummary
    $dur = if ($null -ne $fs) { '{0:0.000000}' -f $fs.durationSeconds } else { 'n/a' }
    $low1 = if ($null -ne $fs) { '{0:0.000000}' -f $fs.low1PercentFps } else { 'n/a' }
    $low01 = if ($null -ne $fs) { '{0:0.000000}' -f $fs.low0_1PercentFps } else { 'n/a' }
    $high1 = if ($null -ne $fs) { '{0:0.000000}' -f $fs.high1PercentFps } else { 'n/a' }
    $sd = if ($null -ne $fs) { '{0:0.000000}' -f $fs.standardDeviationFps } else { 'n/a' }
    $drops = if ($null -ne $fs) { "$($fs.drops)" } else { 'n/a' }
    $spikes = if ($null -ne $fs) { "$($fs.spikes)" } else { 'n/a' }
    [void]$md.AppendLine(("| {0} | {1:0.000000} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} |" -f
        $s.label, $s.medianFps, $dur, $low1, $low01, $high1, $sd, $drops, $spikes, $s.framebufferChecksum))
}
[void]$md.AppendLine('')
if ($null -ne $delta) {
    [void]$md.AppendLine('## Delta (HDPMI32 -r vs CWSDPMI)')
    [void]$md.AppendLine('')
    [void]$md.AppendLine(('- Median FPS delta: {0:0.000000} ({1:0.000}%)' -f $delta.medianFpsDelta, $delta.medianFpsDeltaPercent))
    if ($null -ne $delta.durationSecondsDelta) {
        [void]$md.AppendLine(('- Duration delta: {0:0.000000} s' -f $delta.durationSecondsDelta))
    }
    [void]$md.AppendLine(('- Noise floor (max per-host FPS range): {0:0.000000}' -f $delta.noiseFloorFps))
    [void]$md.AppendLine(('- CWSDPMI checksum: {0}' -f $delta.cwsChecksum))
    [void]$md.AppendLine(('- HDPMI32 checksum: {0}' -f $delta.hdpmiChecksum))
    [void]$md.AppendLine(('- Known-good checksum: {0}' -f $delta.knownGoodChecksum))
    [void]$md.AppendLine(('- Verdict: {0}' -f $delta.verdict))
    [void]$md.AppendLine('')
}
[void]$md.AppendLine('## Host identity probes')
[void]$md.AppendLine('')
foreach ($s in $summaries) {
    [void]$md.AppendLine(('### {0}' -f $s.label))
    [void]$md.AppendLine('')
    [void]$md.AppendLine('```')
    if ($null -ne $s.dpmiHostProbe -and ("{0}" -f $s.dpmiHostProbe).Length -gt 0) {
        [void]$md.AppendLine(("{0}" -f $s.dpmiHostProbe))
    }
    else {
        [void]$md.AppendLine('(no DPMI.EXE probe; CWSDPMI uses stub auto-load)')
    }
    [void]$md.AppendLine('```')
    [void]$md.AppendLine('')
    [void]$md.AppendLine(('- Staging: {0}' -f $s.stagingRoot))
    [void]$md.AppendLine('')
}

$mdPath = Join-Path $compareRoot 'DPMI-COMPARE.md'
$md.ToString() | Set-Content -LiteralPath $mdPath -Encoding UTF8

Write-Host ""
Write-Host ("Compare JSON: {0}" -f $comparePath)
Write-Host ("Compare report: {0}" -f $mdPath)
if ($null -ne $delta) {
    Write-Host ("Verdict: {0} (delta {1:0.000000} FPS / {2:0.000}%)" -f
        $delta.verdict, $delta.medianFpsDelta, $delta.medianFpsDeltaPercent)
}

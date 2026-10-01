<#
.SYNOPSIS
    The 486-cost gate: promotes on cycle-accurate 486 behaviour, not DOSBox-X time.

.DESCRIPTION
    DOSBox-X remains the parity gate (framebuffer checksum, frame count,
    functional correctness). This runner is the second gate, and it exists
    because DOSBox-X cannot see the costs a real 486 pays: it models x87 at
    roughly 1.04 cycles per operation where a 486DX spends about 12, and it
    models neither fetch boundaries, write-buffer occupancy, 4 KB page aliasing,
    nor L1 displacement. The fidelity suite measures exactly that gap and scores
    DOSBox-X 0 of 4 (see ASM486-HANDOFF.md).

    Method, and why it differs from timedemo-dos.ps1:

    - Promotion is on EMULATED CYCLES, never wall time. Cycle-accurate
      emulation's wall clock varies with host scheduling far more than
      DOSBox-X's 0.000049 s spread, and a millisecond figure from a different
      emulator is not comparable to a millisecond figure from this one.
    - At least 7 alternating runs per side, interleaved A/B/B/A to cancel
      thermal and scheduling drift. n=3 is not enough to separate a cycle
      median from its spread once the harness is this noisy.
    - Report median and MAD, not just a median. A candidate is promoted only
      when the medians separate AND the spreads do not overlap.

    Roles do not overlap. A DOSBox-X null is never grounds for rejecting a
    candidate (that is the whole point of this runner), and a PCem null is
    grounds for rejecting one -- but only after the fidelity suite has passed.

.PARAMETER Emulator
    Which cycle-accurate reference to use. Defaults to pcem.

.PARAMETER RequireFidelity
    Refuse to run unless tools\486-fidelity.ps1 reports PASS for this emulator.
    This is the default: a 486-cost gate whose fidelity is unvalidated would be
    a second, worse version of the mistake this project is correcting.

.EXAMPLE
    .\tools\bench486-dos.ps1 -Runs 7 -Label candidate
#>
[CmdletBinding()]
param(
    [ValidateSet('pcem')]
    [string]$Emulator = 'pcem',

    [string]$ToolRoot,
    [string]$DataRoot,

    [string]$BenchmarkExe,

    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$Label = 'run',

    # Number of timedemos the caller intends to collect for this label. This
    # runner performs ONE timedemo per invocation; repetition is the caller's
    # job because the alternation must interleave the candidate with the
    # control, and two different builds cannot be alternated from inside a
    # single run. The value is recorded in the result so a set of runs can be
    # checked for completeness afterwards.
    [ValidateRange(1, 21)]
    [int]$Runs = 7,

    [int]$TimeoutSeconds = 3600,

    # PCem only; forwarded to the fidelity suite. Empty means "use the
    # manifest's machine", which is the Award SiS 496/497.
    [string]$PcemMachine = '',

    # Run the fidelity suite first and refuse to proceed unless it passes.
    [switch]$SkipFidelity,

    # Parity is re-checked on DOSBox-X, and is necessary but NOT sufficient.
    [int]$ExpectedFrames = 969,
    [int]$ExpectedChecksum = 1047377823,

    [string]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Provision the machine (config text + CMOS) and read the report back out of
# the staged image.
Import-Module (Join-Path $PSScriptRoot 'pcem-machine.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'FatImage.psm1') -Force

function Test-SameBytes {
    param([byte[]]$A, [byte[]]$B)

    if ($null -eq $A -or $null -eq $B -or $A.Length -ne $B.Length) { return $false }
    for ($i = 0; $i -lt $A.Length; $i++) {
        if ($A[$i] -ne $B[$i]) { return $false }
    }
    return $true
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
if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $repoRoot 'testdata\id1'
}
$DataRoot = [IO.Path]::GetFullPath($DataRoot)
if (-not (Test-Path -LiteralPath $DataRoot -PathType Container)) {
    throw "Game data directory '$DataRoot' does not exist. Pass -DataRoot."
}
$pak0 = Get-ChildItem -LiteralPath $DataRoot -Filter 'pak0.pak' -File | Select-Object -First 1
if ($null -eq $pak0) {
    throw "'$DataRoot' must contain pak0.pak. Game data is intentionally not in Git."
}

# ---------------------------------------------------------------------------
# Fidelity gate. Do not measure 486 costs on a harness that has not been shown
# to price them.
# ---------------------------------------------------------------------------
if (-not $SkipFidelity) {
    Write-Host 'Verifying 486 fidelity before trusting this harness...'
    $fidelityJson = Join-Path $repoRoot ('out\fidelity-' + $Emulator + '-' + $Label + '.json')
    $fidelityArgs = @{
        Emulator = $Emulator
        ToolRoot = $ToolRoot
        DataRoot = $DataRoot
        Json = $fidelityJson
        Require = $true
    }
    if ($Emulator -eq 'pcem' -and -not [string]::IsNullOrWhiteSpace($PcemMachine)) {
        $fidelityArgs['PcemMachine'] = $PcemMachine
    }
    if (-not [string]::IsNullOrWhiteSpace($BenchmarkExe)) {
        $fidelityArgs['BenchmarkExe'] = $BenchmarkExe
    }
    & (Join-Path $PSScriptRoot '486-fidelity.ps1') @fidelityArgs
    Write-Host 'Fidelity PASS. Proceeding.'
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Locate the emulator and the benchmark executable.
# ---------------------------------------------------------------------------
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$emulatorDef = $manifest.$Emulator
if ($null -eq $emulatorDef) {
    throw "The toolchain manifest has no '$Emulator' block."
}
$emulatorPath = Join-Path (Join-Path $ToolRoot $emulatorDef.installDirectory) `
    ($emulatorDef.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $emulatorPath -PathType Leaf)) {
    throw "$Emulator is not installed at '$emulatorPath'. Run bootstrap-dos.ps1 -With$($Emulator.Substring(0,1).ToUpper() + $Emulator.Substring(1))."
}

if ([string]::IsNullOrWhiteSpace($BenchmarkExe)) {
    $candidate = Get-ChildItem (Join-Path $repoRoot 'out') -Recurse -Filter 'qbench.exe' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $candidate) {
        throw 'No qbench.exe under out\. Build one with .\tools\build-dos.ps1 -Benchmark -NoBootstrap'
    }
    $BenchmarkExe = $candidate.FullName
}
$BenchmarkExe = [IO.Path]::GetFullPath($BenchmarkExe)
if (-not (Test-Path -LiteralPath $BenchmarkExe -PathType Leaf)) {
    throw "Benchmark executable was not found: '$BenchmarkExe'."
}

# ---------------------------------------------------------------------------
# Stage. The DOS tree is identical to the timedemo's, so the two harnesses run
# byte-identical guest code and the only variable is the emulator. The guest
# tree lives inside dos.hdd rather than a host directory, because PCem cannot
# mount one; pcem-stage.ps1 owns that contract for both harnesses (the only
# difference is the benchmark command on AUTOEXEC.BAT) and reports back the
# geometry this machine must be told about.
# ---------------------------------------------------------------------------
$runName = 'dos-486cost-' + $Emulator + '-' + $Label + '-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$stagingRoot = Join-Path (Join-Path $repoRoot 'out') $runName
if (Test-Path -LiteralPath $stagingRoot) {
    throw "Staging path already exists; refusing to overwrite '$stagingRoot'."
}
$pcemConfigPath = Join-Path $stagingRoot 'pcem-machine.cfg'
# Only has to exist: pcem-stage.ps1 writes the payload into the image, and the
# report is read back out of the image, not from here.
New-Item -ItemType Directory -Path (Join-Path $stagingRoot 'quake') -Force | Out-Null

$pcemStage = & (Join-Path $PSScriptRoot 'pcem-stage.ps1') `
    -StagingRoot $stagingRoot `
    -BenchmarkExe $BenchmarkExe `
    -DataRoot $DataRoot `
    -BenchMode 'timedemo'
if ($null -eq $pcemStage) {
    throw "pcem-stage.ps1 produced no result. Staged run: $stagingRoot"
}

# The machine comes from the manifest so the BIOS that is booted is the BIOS
# the ROM set was verified against; -PcemMachine still overrides it.
$machineName = if ([string]::IsNullOrWhiteSpace($PcemMachine)) {
    [string]$manifest.pcemRomset.machine
}
else {
    $PcemMachine
}
if ([string]::IsNullOrWhiteSpace($machineName)) {
    throw 'No PCem machine to run: pass -PcemMachine or set pcemRomset.machine in the manifest.'
}

# CMOS before launch: the bytes are the firmware's own, and a machine whose
# CMOS has no drive table for C: halts at POST, which is indistinguishable from
# a failed measurement from the outside. Provisioned from scratch every run.
$nvr = Set-PcemMachineNvr `
    -PcemRoot (Split-Path -Parent $emulatorPath) `
    -Machine $machineName `
    -ConfigName ([IO.Path]::GetFileNameWithoutExtension($pcemConfigPath)) `
    -Cylinders $pcemStage.Cylinders `
    -Heads $pcemStage.Heads `
    -SectorsPerTrack $pcemStage.SectorsPerTrack
if ($null -ne $nvr) {
    Write-Host ("CMOS:    {0} {1}/{2}/{3}, checksum {4} -> {5}" -f $nvr.Vendor, $nvr.Cylinders,
        $nvr.Heads, $nvr.Sectors, $nvr.Checksum, [IO.Path]::GetFileName($nvr.Nvr))
}

# The machine config. Flat keys, no section header, because that is the shape
# PCem v17 actually reads; see tools\pcem-machine.psm1.
$pcemConfig = Get-PcemMachineConfigText `
    -Machine $machineName `
    -HardDisk $pcemStage.HardDisk `
    -Cylinders $pcemStage.Cylinders `
    -Heads $pcemStage.Heads `
    -SectorsPerTrack $pcemStage.SectorsPerTrack
$pcemConfig | Set-Content -LiteralPath $pcemConfigPath -Encoding ASCII

# ---------------------------------------------------------------------------
# Run. PCem is interactive and has no script argument, so the run is driven
# from inside the guest: AUTOEXEC.BAT ends by writing C:\DONE.TXT, and the
# host polls dos.hdd for it before reading the report back out. Two dashes on
# --config matter: a single dash is silently ignored and PCem boots model 0
# with 4 MB while reporting success (verified with `PCem.exe --help`).
# ---------------------------------------------------------------------------
$arguments = '--config "{0}"' -f $pcemConfigPath
Write-Host "Launching $Emulator ($($emulatorDef.version)) for label '$Label' (run 1 of $Runs planned)"
Write-Host "  executable: $BenchmarkExe"
Write-Host "  staged:     $stagingRoot"
Write-Host ''

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $emulatorPath
$processInfo.Arguments = $arguments
$processInfo.WorkingDirectory = Split-Path -Parent $emulatorPath
$processInfo.UseShellExecute = $false
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo

$hardDisk = $pcemStage.HardDisk
$partOffset = $pcemStage.PartitionOffset
$emulatorExit = $null
$report = $null
try {
    if (-not $process.Start()) {
        throw "$Emulator failed to start."
    }
    # PCem never exits on its own, so waiting for exit is waiting for the
    # timeout. Poll the image instead: the guest signals completion by writing
    # C:\DONE.TXT, and the report is only trusted once it reads byte-identical
    # on consecutive polls, because PCem's stdio buffer for the image is ~4 KB -
    # one successful read proves the file exists, not that its last sector has
    # reached the host.
    $deadlineUtc = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $stableReads = 0
    $lastReportBytes = $null
    $completed = $false
    while ([DateTime]::UtcNow -lt $deadlineUtc) {
        Start-Sleep -Milliseconds 500
        if ($process.HasExited) {
            throw ("$Emulator exited early (code $($process.ExitCode)) before the guest wrote " +
                "C:\DONE.TXT. Staged run: $stagingRoot`n" +
                'Attach dos.hdd to a diagnostic setup to read the guest screen: a POST halt ' +
                '(no C: drive, or a CMOS problem waiting for F1) and a boot failure both look ' +
                'like this from out here.')
        }
        $sentinel = $false
        try { $sentinel = Test-FatImageFile -Path $hardDisk -Name 'DONE.TXT' -Offset $partOffset }
        catch { continue }    # image mid-write; retry next tick
        if (-not $sentinel) { continue }
        $fresh = $null
        try { $fresh = Read-FatImageFile -Path $hardDisk -Name 'QUAKE\BENCH486.TXT' -Offset $partOffset }
        catch { continue }    # sentinel flushed before the report's last sector; retry
        if ($stableReads -ge 1 -and (Test-SameBytes -A $fresh -B $lastReportBytes)) {
            $stableReads++
        }
        else {
            $stableReads = 0
        }
        $lastReportBytes = $fresh
        if ($stableReads -ge 2) { $completed = $true; break }
    }
    if (-not $completed) {
    if (-not $process.HasExited) { $process.Kill() }
    $process.WaitForExit(10000) | Out-Null
    $emulatorExit = $process.ExitCode
        throw ("$Emulator did not produce a stable C:\QUAKE\BENCH486.TXT within $TimeoutSeconds " +
            "seconds (no C:\DONE.TXT sentinel, or the report never settled). Staged run: $stagingRoot")
    }
    if (-not $process.HasExited) { $process.Kill() }
    # Prefer a post-kill read: PCem's handle is closed, so nothing is in flight.
    try {
        $postKill = Read-FatImageFile -Path $hardDisk -Name 'QUAKE\BENCH486.TXT' -Offset $partOffset
        if ($postKill.Length -gt 0) { $lastReportBytes = $postKill }
    }
    catch { }
    if ($null -eq $lastReportBytes -or $lastReportBytes.Length -eq 0) {
        throw ("$Emulator signalled completion but the report in '$hardDisk' is empty. " +
            "Staged run: $stagingRoot")
    }
    $report = [Text.Encoding]::ASCII.GetString($lastReportBytes)
    Write-Host $report
}
finally {
    $process.Dispose()
}

# ---------------------------------------------------------------------------
# Parse and gate.
# ---------------------------------------------------------------------------
$framesMatch = [regex]::Match($report, '(?<frames>\d+)\s+frames\s+(?<seconds>[0-9.]+)\s+seconds\s+(?<fps>[0-9.]+)\s+fps')
$checksumMatch = [regex]::Match($report, 'framebuffer-checksum\s+(?<checksum>\d+)')
$correctnessMatch = [regex]::Match($report, '486 benchmark correctness\s+(?<result>PASS|FAIL)')

$gateFailures = @()
if (-not $framesMatch.Success) {
    $gateFailures += 'no timedemo report line'
}
elseif ([int]$framesMatch.Groups['frames'].Value -ne $ExpectedFrames) {
    $gateFailures += "frames $($framesMatch.Groups['frames'].Value) != $ExpectedFrames"
}
if ($checksumMatch.Success) {
    if ([int64]$checksumMatch.Groups['checksum'].Value -ne $ExpectedChecksum) {
        $gateFailures += "framebuffer checksum $($checksumMatch.Groups['checksum'].Value) != $ExpectedChecksum"
    }
}
else {
    $gateFailures += 'no framebuffer checksum in the report'
}
if ($correctnessMatch.Success -and $correctnessMatch.Groups['result'].Value -ne 'PASS') {
    $gateFailures += 'in-engine correctness reported FAIL'
}
if ($gateFailures.Count -gt 0) {
    throw ("Parity gate failed under ${Emulator}: " + ($gateFailures -join '; ') +
        ". This is not a valid measurement. Staged run: $stagingRoot")
}

$seconds = [double]::Parse($framesMatch.Groups['seconds'].Value, [Globalization.CultureInfo]::InvariantCulture)

Write-Host ''
Write-Host '486-cost gate'
Write-Host ("  emulator:      {0} {1}" -f $Emulator, $emulatorDef.version)
Write-Host ("  frames:        {0}" -f $framesMatch.Groups['frames'].Value)
Write-Host ("  checksum:      {0}" -f $checksumMatch.Groups['checksum'].Value)
Write-Host ("  in-engine:     {0}" -f $(if ($correctnessMatch.Success) { $correctnessMatch.Groups['result'].Value } else { 'not reported' }))
Write-Host ("  wall seconds:  {0}" -f $seconds)
Write-Host ''
Write-Host '  NOTE: this is a wall-clock figure from a different emulator. It is NOT'
Write-Host '  comparable to a DOSBox-X millisecond figure and must not be quoted as a'
Write-Host '  speedup. The promotion signal is the candidate/candidate comparison run'
Write-Host '  under this emulator, alternating and repeated, not this number alone.'

$result = [ordered]@{
    emulator = $Emulator
    emulatorVersion = $emulatorDef.version
    label = $Label
    executable = $BenchmarkExe
    frames = [int]$framesMatch.Groups['frames'].Value
    framebufferChecksum = [int64]$checksumMatch.Groups['checksum'].Value
    inEngineCorrectness = if ($correctnessMatch.Success) { $correctnessMatch.Groups['result'].Value } else { $null }
    wallSeconds = $seconds
    wallFps = [double]::Parse($framesMatch.Groups['fps'].Value, [Globalization.CultureInfo]::InvariantCulture)
    runsRequested = $Runs
    exitCode = $emulatorExit
    parityGate = [ordered]@{
        expectedFrames = $ExpectedFrames
        expectedChecksum = $ExpectedChecksum
        enforced = $true
    }
    stagedRun = $stagingRoot
    report = $report.Trim()
}
if (-not [string]::IsNullOrWhiteSpace($Json)) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Json -Encoding ASCII
    Write-Host "Wrote $Json"
}

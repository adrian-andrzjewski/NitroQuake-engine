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

    # PCem only; forwarded to the fidelity suite.
    [string]$PcemMachine = 'win486',
    [string]$PcemBiosRom,

    # Run the fidelity suite first and refuse to proceed unless it passes.
    [switch]$SkipFidelity,

    # Parity is re-checked on DOSBox-X, and is necessary but NOT sufficient.
    [int]$ExpectedFrames = 969,
    [int]$ExpectedChecksum = 1047377823,

    [string]$Json
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
    if ($Emulator -eq 'pcem') {
        $fidelityArgs['PcemMachine'] = $PcemMachine
        if (-not [string]::IsNullOrWhiteSpace($PcemBiosRom)) {
            $fidelityArgs['PcemBiosRom'] = $PcemBiosRom
        }
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
# byte-identical guest code and the only variable is the emulator.
# ---------------------------------------------------------------------------
$runName = 'dos-486cost-' + $Emulator + '-' + $Label + '-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$stagingRoot = Join-Path (Join-Path $repoRoot 'out') $runName
if (Test-Path -LiteralPath $stagingRoot) {
    throw "Staging path already exists; refusing to overwrite '$stagingRoot'."
}
$quakeRoot = Join-Path $stagingRoot 'quake'
$stagedData = Join-Path $quakeRoot 'id1'
New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

Copy-Item -LiteralPath $BenchmarkExe -Destination (Join-Path $quakeRoot 'qbench.exe') -Force
$dpmiSource = Join-Path $repoRoot 'WinQuake\cwsdpmi.exe'
if (Test-Path -LiteralPath $dpmiSource -PathType Leaf) {
    Copy-Item -LiteralPath $dpmiSource -Destination (Join-Path $quakeRoot 'cwsdpmi.exe') -Force
}
foreach ($pak in Get-ChildItem -LiteralPath $DataRoot -Filter 'pak*.pak' -File) {
    New-Item -ItemType HardLink -Path (Join-Path $stagedData $pak.Name) -Value $pak.FullName -Force | Out-Null
}

$batchPath = Join-Path $quakeRoot 'bench486cost.bat'
# '+bench486' runs the command at startup. Without the '+' Quake starts with
# nothing to do and falls into its demo loop instead of benchmarking.
@(
    '@echo off',
    'cd \quake',
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchexit',
    'exit'
) | Set-Content -LiteralPath $batchPath -Encoding ASCII

# The machine config. The guest sees an identical DOS tree whichever emulator
# runs it, so a cycle difference is attributable to the CPU model alone.
$pcemConfigPath = Join-Path $stagingRoot 'pcem-machine.cfg'
$romPath = if ([string]::IsNullOrWhiteSpace($PcemBiosRom)) {
    Join-Path $ToolRoot ('pcem-17\roms\' + $PcemMachine + '\bios.rom')
}
else {
    [IO.Path]::GetFullPath($PcemBiosRom)
}
if (-not (Test-Path -LiteralPath $romPath -PathType Leaf)) {
    throw ("PCem has no BIOS ROM for machine '$PcemMachine' at '$romPath'. PCem ships no copyrighted ROMs, " +
        "so one must be supplied via -PcemBiosRom before the 486-cost gate can run.")
}
@(
    '[PCem]',
    "machine = $PcemMachine",
    'scaler = fit',
    'window_width = 640',
    'window_height = 480',
    'window_zoomed = 0',
    'display = surface',
    'sound = none',
    'ramsize = 32',
    "bios_path = $romPath",
    '[cpu]',
    'cpu_type = 486',
    'cpu_speed = 25',
    'fpu = enabled',
    'fpu_type = internal',
    'cycles = 33445',
    'extfpu = disabled',
    'advanced = 0',
    '[display]',
    'display_type = internal'
) -join "`r`n" | Set-Content -LiteralPath $pcemConfigPath -Encoding ASCII

# ---------------------------------------------------------------------------
# Run. PCem is interactive, so it is launched and given the remaining time; the
# guest writes its result to bench486.txt, which is what we read.
# ---------------------------------------------------------------------------
$arguments = @('-config', $pcemConfigPath) -join ' '
Write-Host "Launching $Emulator ($($emulatorDef.version)) for label '$Label' (run 1 of $Runs planned)"
Write-Host "  executable: $BenchmarkExe"
Write-Host "  staged:     $stagingRoot"
Write-Host ''

$reportPath = Join-Path $quakeRoot 'bench486.txt'
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $emulatorPath
$processInfo.Arguments = $arguments
$processInfo.WorkingDirectory = Split-Path -Parent $emulatorPath
$processInfo.UseShellExecute = $false
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
try {
    if (-not $process.Start()) {
        throw "$Emulator failed to start."
    }
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "$Emulator exceeded $TimeoutSeconds seconds."
    }
    $emulatorExit = $process.ExitCode
}
finally {
    $process.Dispose()
}

if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    throw ("$Emulator exited with code $emulatorExit but produced no bench486.txt. Staged run: $stagingRoot`n" +
        "If Quake played a demo instead of benchmarking, the batch file is missing '+bench486'.")
}
$report = Get-Content -LiteralPath $reportPath -Raw
Write-Host $report

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

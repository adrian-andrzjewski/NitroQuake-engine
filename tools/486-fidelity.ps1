<#
.SYNOPSIS
    Decides whether an emulator is trustworthy as the 486-cost gate.

.DESCRIPTION
    The DOSBox-X timedemo cannot price the costs a real 486 pays: it models x87
    at roughly 1.04 cycles per operation where a 486DX spends about 12, and it
    models neither fetch boundaries, write-buffer occupancy, 4 KB page aliasing,
    nor L1 displacement. That is why a measured null there is weak evidence
    (ASM486-HANDOFF.md:452-509), and why this project needs a second harness.

    A second harness is only useful if it is demonstrably better on exactly the
    axes DOSBox-X is blind to. This script establishes that, before any
    candidate is promoted on it. It runs the in-engine probes added in
    WinQuake/host_cmd.c (-benchfidelity) and checks four things:

      1. x87 chain      a serialized x87 chain with a real FDIV must cost
                        materially more per op than a flat-FPU emulator charges
      2. FISTPL vs FIST 32-bit and 16-bit float-to-int stores must differ; the
                        cost model prices fistp at 39 cycles
      3. L1 residency   a working set that fits the 8 KB cache must beat one
                        that cannot
      4. set aliasing   two buffers sharing an L1 set must lose to two that do
                        not; this is the vid_vga.c:299-304 collision shape

    Probe 4 is the one that matters most for the 486 work: a DOSBox-X run will
    report the aliasing pair and the disjoint pair as identical, because it has
    no cache at all. That is the correct, expected behaviour for the parity
    gate, and it is why DOSBox-X stays the parity gate while this decides
    whether a cycle-accurate reference can gate promotions.

.PARAMETER Require
    Fail the script if fidelity does not pass. Without it the script reports and
    exits 0, so a machine that merely wants to see the numbers can run it.

.EXAMPLE
    .\tools\486-fidelity.ps1 -Emulator pcem -Require
#>
[CmdletBinding()]
param(
    # Which emulator to validate. 'dosbox-x' is the pinned parity gate and is
    # expected to FAIL fidelity by design; run it to record that expectation.
    [ValidateSet('dosbox-x', 'pcem')]
    [string]$Emulator = 'pcem',

    [string]$ToolRoot,
    [string]$DataRoot,

    # Benchmark executable built by build-dos.ps1 -Benchmark. Defaults to the
    # newest qbench.exe under out\.
    [string]$BenchmarkExe,

    [int]$TimeoutSeconds = 600,

    # Fail rather than report. Use this in any gate that depends on the answer.
    [switch]$Require,

    # Write the verdict to this path as JSON.
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

$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$profilePath = Join-Path $PSScriptRoot 'dosbox-x-486-high.conf'
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "486 profile is missing: '$profilePath'."
}

# ---------------------------------------------------------------------------
# Locate the emulator. DOSBox-X always exists (it is the parity gate); PCem is
# optional and is the intended 486-cost gate.
# ---------------------------------------------------------------------------
if ($Emulator -eq 'dosbox-x') {
    $dosboxRoot = Join-Path $ToolRoot $manifest.dosboxX.installDirectory
    $emulatorPath = Join-Path $dosboxRoot ($manifest.dosboxX.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
    $emulatorArgs = @('-conf', '{config}', '-exit')
    $emulatorVersion = $manifest.dosboxX.version
}
else {
    if ($null -eq $manifest.pcem) {
        throw 'The toolchain manifest has no "pcem" block.'
    }
    $pcemRoot = Join-Path $ToolRoot $manifest.pcem.installDirectory
    $emulatorPath = Join-Path $pcemRoot ($manifest.pcem.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
    # PCem takes its machine from a config file and drives DOS directly. The
    # arguments are filled in per-run below; the config is written next to the
    # staged batch file.
    $emulatorArgs = @('-config', '{config}', '-script', '{script}')
    $emulatorVersion = $manifest.pcem.version
    if ([string]::IsNullOrWhiteSpace([string]$manifest.pcem.sha256)) {
        Write-Warning 'PCem has no pinned SHA-256 in the manifest. Run bootstrap-dos.ps1 -RecordPcemHash and pin it before promoting anything on PCem cycles.'
    }
}
if (-not (Test-Path -LiteralPath $emulatorPath -PathType Leaf)) {
    if ($Emulator -eq 'pcem') {
        throw "PCem is not installed at '$emulatorPath'. Run bootstrap-dos.ps1 -WithPcem, or use -Emulator dosbox-x to record the parity-gate expectation."
    }
    throw "DOSBox-X is missing at '$emulatorPath'. Run bootstrap-dos.ps1."
}

# ---------------------------------------------------------------------------
# Locate the benchmark executable.
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($BenchmarkExe)) {
    $candidate = Get-ChildItem (Join-Path $repoRoot 'out') -Recurse -Filter 'qbench.exe' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $candidate) {
        throw 'No qbench.exe under out\. Build one with: .\tools\build-dos.ps1 -Benchmark -NoBootstrap'
    }
    $BenchmarkExe = $candidate.FullName
}
$BenchmarkExe = [IO.Path]::GetFullPath($BenchmarkExe)
if (-not (Test-Path -LiteralPath $BenchmarkExe -PathType Leaf)) {
    throw "Benchmark executable was not found: '$BenchmarkExe'."
}

# ---------------------------------------------------------------------------
# Stage the run: Quake, the DPMI host, and the id1 data, exactly as the
# timedemo and bench runners do.
# ---------------------------------------------------------------------------
$runName = 'dos-fidelity-' + $Emulator + '-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$stagingRoot = Join-Path (Join-Path $repoRoot 'out') $runName
if (Test-Path -LiteralPath $stagingRoot) {
    throw "Fidelity staging path already exists; refusing to overwrite '$stagingRoot'."
}
$quakeRoot = Join-Path $stagingRoot 'quake'
$stagedData = Join-Path $quakeRoot 'id1'
New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

Copy-Item -LiteralPath $BenchmarkExe -Destination (Join-Path $quakeRoot 'qbench.exe') -Force
$dpmiSource = Join-Path $repoRoot 'WinQuake\cwsdpmi.exe'
if (Test-Path -LiteralPath $dpmiSource -PathType Leaf) {
    Copy-Item -LiteralPath $dpmiSource -Destination (Join-Path $quakeRoot 'cwsdpmi.exe') -Force
}
$pak0 = Get-ChildItem -LiteralPath $DataRoot -Filter 'pak0.pak' -File | Select-Object -First 1
if ($null -eq $pak0) {
    throw "'$DataRoot' must contain pak0.pak. Game data is intentionally not in Git."
}
Copy-Item -LiteralPath $pak0.FullName -Destination (Join-Path $stagedData 'pak0.pak') -Force

$batchPath = Join-Path $quakeRoot 'fidelity.bat'
# '+bench486' is what actually runs the command at startup; -benchfidelity is
# only a selector that Bench486_f reads. Omitting the '+' leaves Quake with
# nothing to do and it falls into its demo loop instead of probing anything.
@(
    '@echo off',
    'cd \quake',
    'qbench.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio +bench486 -benchfidelity -benchexit',
    'exit'
) | Set-Content -LiteralPath $batchPath -Encoding ASCII

# ---------------------------------------------------------------------------
# Launch.
# ---------------------------------------------------------------------------
$configPath = Join-Path $stagingRoot "run-$Emulator.conf"
if ($Emulator -eq 'dosbox-x') {
    # Splice a new [autoexec] into the pinned profile rather than writing a
    # conf from scratch, so the fidelity run uses exactly the same CPU, memory
    # and renderer settings as the timedemo. This is the same substitution
    # timedemo-dos.ps1 performs, and a hand-built conf would silently drift from
    # the pinned profile.
    $profileText = Get-Content -LiteralPath $profilePath -Raw
    $mountPath = $stagingRoot.Replace('"', '""')
    $autoexec = (@"
[autoexec]
mount c "$mountPath"
c:
cd \quake
call fidelity.bat
exit
"@).TrimEnd() + [Environment]::NewLine
    $runtimeConfig = [regex]::Replace(
        $profileText,
        '(?ms)^\[autoexec\]\s*.*?(?=^\[devices\])',
        [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $autoexec })
    if ($runtimeConfig -eq $profileText) {
        throw "Could not replace the autoexec section in '$profilePath'."
    }
    $runtimeConfig | Set-Content -LiteralPath $configPath -Encoding ASCII
    $arguments = @('-conf', $configPath, '-exit') -join ' '
}
else {
    # PCem is configured with a machine file rather than a DOSBox-style conf.
    # The staged batch is handed to the emulator as a DOS boot script.
    $pcemConfigPath = Join-Path $stagingRoot 'pcem-machine.json'
    @{
        cpu = @{
            type            = 'i486'
            cycles          = 33445
            fpu             = $true
            fpu_type        = 'i387'
            # PCem reports an emulated cycle count when instruction counting is
            # enabled; that count, not wall time, is the promotion signal.
            instructions    = [int](33445 * 1000)
            bbios           = Join-Path $ToolRoot ($manifest.pcem.installDirectory + '\bios.bin')
        }
        ram = @{ size = 32 }
        display = @{ enable = 1 }
        devices = @{ fdc = 1 }
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $pcemConfigPath -Encoding ASCII
    $arguments = @('-config', $pcemConfigPath, '-script', $batchPath) -join ' '
}

Write-Host "Launching $Emulator $emulatorVersion fidelity probes"
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $emulatorPath
$processInfo.Arguments = $arguments
$processInfo.WorkingDirectory = Split-Path -Parent $emulatorPath
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
try {
    if (-not $process.Start()) {
        throw "$Emulator failed to start."
    }
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "$Emulator fidelity run exceeded $TimeoutSeconds seconds."
    }
    $emulatorExit = $process.ExitCode
}
finally {
    $process.Dispose()
}

$reportPath = Join-Path $quakeRoot 'bench486.txt'
if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    throw "$Emulator exited with code $emulatorExit but no bench486.txt was produced. Staged run: $stagingRoot`nIf Quake played a demo instead of probing, the batch file is missing '+bench486' - without it the command never runs and Quake falls into its demo loop."
}
$report = Get-Content -LiteralPath $reportPath -Raw
Write-Host ''
Write-Host $report

# ---------------------------------------------------------------------------
# Parse the probes and decide.
# ---------------------------------------------------------------------------
$probes = @{}
foreach ($line in ($report -split "`r?`n")) {
    if ($line -match 'fidelity (?<name>\S+)\s+(?<rest>.*)$') {
        $name = $Matches['name']
        $rest = $Matches['rest']
        if ($rest -match '(?<iterations>\d+)\s+ops\s+(?<seconds>[0-9.]+)\s+sec\s+(?<ns>[0-9.]+)\s+ns/op') {
            $probes[$name] = [ordered]@{
                iterations = [int]$Matches['iterations']
                seconds = [double]$Matches['seconds']
                nanosecondsPerOp = [double]$Matches['ns']
            }
        }
    }
}
if ($probes.Count -eq 0) {
    throw "No fidelity probe results found in the report. Staged run: $stagingRoot"
}

function Get-ProbeRatio {
    param([string]$Numerator, [string]$Denominator)

    if (-not $probes.ContainsKey($Numerator) -or -not $probes.ContainsKey($Denominator)) {
        return $null
    }
    $den = $probes[$Denominator].nanosecondsPerOp
    if ($den -le 0) {
        return $null
    }
    return $probes[$Numerator].nanosecondsPerOp / $den
}

# The cheapest possible outcome for a flat-FPU, cacheless emulator: every probe
# costs the same. Anything at or below this is a harness that cannot see 486.
$flatFloor = 1.05

$checks = @()

# 1. x87 chain. On a 486 the chain carries two FILDs, a dozen multiply/adds, a
# real divide and two FISTPLs, so it must be far dearer per op than the
# single-store FPU probe. A flat-FPU emulator makes the two converge.
$x87VsFpu = Get-ProbeRatio -Numerator 'x87chain' -Denominator 'fpu'
$checks += [ordered]@{
    name = 'x87 chain is charged for its latency'
    detail = 'x87chain vs single FPU store'
    ratio = $x87VsFpu
    pass = ($null -ne $x87VsFpu -and $x87VsFpu -ge 3.0)
    requirement = 'x87chain must be >= 3.0x the single-store FPU probe'
}

# 2. FISTPL against 16-bit FIST. The cost model prices fistp at 39 cycles and
# fistps materially less, so the two must separate. The two cases share a probe
# name and differ only by label, so read the timings out of the report.
$fist32Ns = $null
$fist16Ns = $null
if ($report -match 'fidelity fpu fistp32\s+\d+ ops\s+[0-9.]+ sec\s+(?<ns>[0-9.]+)') {
    $fist32Ns = [double]$Matches['ns']
}
if ($report -match 'fidelity fpu fist16\s+\d+ ops\s+[0-9.]+ sec\s+(?<ns>[0-9.]+)') {
    $fist16Ns = [double]$Matches['ns']
}
$fistSeparation = $null
if ($null -ne $fist32Ns -and $null -ne $fist16Ns -and $fist16Ns -gt 0) {
    $fistSeparation = $fist32Ns / $fist16Ns
}
$checks += [ordered]@{
    name = 'FISTPL and 16-bit FIST are charged differently'
    detail = 'fistp32 vs fist16'
    ratio = $fistSeparation
    pass = ($null -ne $fistSeparation -and $fistSeparation -ge $flatFloor)
    requirement = 'fistp32 must be >= 1.05x fist16 (the model prices it at 39 cy)'
}

# 3. L1 residency. 4 KB fits the 8 KB unified cache; 24 KB cannot.
$l1Ratio = Get-ProbeRatio -Numerator 'l1-24576' -Denominator 'l1-4096'
$checks += [ordered]@{
    name = 'L1 capacity is modelled'
    detail = '24 KB working set vs 4 KB'
    ratio = $l1Ratio
    pass = ($null -ne $l1Ratio -and $l1Ratio -ge $flatFloor)
    requirement = "the 24 KB set must be >= $flatFloor x the 4 KB set"
}

# 4. Set aliasing. The 486DX L1 is 8 KB, 4-way, 32-byte lines, 64 sets, so the
# set index is A[11:5] and two addresses share a set when they agree mod 2048.
# Offset 0 aliases; offset 64 does not. This is the vid_vga.c:299-304 shape.
$aliasRatio = Get-ProbeRatio -Numerator 'alias-0' -Denominator 'alias-64'
$checks += [ordered]@{
    name = 'cache-set aliasing is modelled'
    detail = 'same-set pair vs set-disjoint pair'
    ratio = $aliasRatio
    pass = ($null -ne $aliasRatio -and $aliasRatio -ge $flatFloor)
    requirement = "the aliasing pair must be >= $flatFloor x the disjoint pair"
}

$passed = @($checks | Where-Object { $_.pass }).Count
$total = $checks.Count
$verdict = if ($passed -eq $total) { 'PASS' } else { 'FAIL' }

Write-Host ''
Write-Host 'Fidelity verdict'
Write-Host ("  emulator: {0} {1}" -f $Emulator, $emulatorVersion)
foreach ($check in $checks) {
    $ratioText = if ($null -eq $check.ratio) { 'n/a' } else { '{0:N3}x' -f $check.ratio }
    $status = if ($check.pass) { 'PASS' } else { 'FAIL' }
    Write-Host ("  [{0}] {1}" -f $status, $check.name)
    Write-Host ("         {0} = {1}; {2}" -f $check.detail, $ratioText, $check.requirement)
}
Write-Host ("  RESULT: {0} ({1}/{2})" -f $verdict, $passed, $total)

if ($Emulator -eq 'dosbox-x') {
    Write-Host ''
    Write-Host '  DOSBox-X is the parity gate and is EXPECTED to fail these probes. Its flat'
    Write-Host '  FPU and absent cache are precisely why a measured null there is weak'
    Write-Host '  evidence (ASM486-HANDOFF.md:452-509). A failure here is the correct'
    Write-Host '  result and is the reason a 486-cost gate is being added.'
}

$result = [ordered]@{
    emulator = $Emulator
    emulatorVersion = $emulatorVersion
    executable = $BenchmarkExe
    exitCode = $emulatorExit
    probes = $probes
    checks = $checks
    passed = $passed
    total = $total
    verdict = $verdict
    stagedRun = $stagingRoot
}
if (-not [string]::IsNullOrWhiteSpace($Json)) {
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Json -Encoding ASCII
    Write-Host "Wrote $Json"
}

if ($Require -and $verdict -ne 'PASS') {
    throw "486 fidelity FAILED for $Emulator ($passed/$total). This emulator must not be used as the 486-cost gate: it does not price the costs a 486 pays. Staged run: $stagingRoot"
}

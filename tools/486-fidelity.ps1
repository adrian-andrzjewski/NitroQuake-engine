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

    # PCem only. ROMs are not supplied here: PCem ships none by design, and
    # the ROM set this project uses is consumed in place via [Paths]
    # roms_paths (tools\pcem-roms.ps1 wires it; pcemRomset in the manifest
    # locates it). What is tunable is the machine itself. The default is the
    # manifest's machine, Award SiS 496/497.
    [string]$PcemMachine = '',

    # cpus_i486[] index (src\cpu_tables.c): 12 = iDX4/100, 10 = i486DX2/66.
    # Exposed so the cross-check run at a slower 486 can be made without
    # editing the script.
    [int]$PcemCpuIndex = 12,

    # KiB. 16384 matches the DOSBox-X reference profile; Quake needs >= 8 MB.
    [int]$PcemMemKiB = 16384,

    # Override the manifest's PCem install directory (rarely needed; both
    # installs are recorded in dos-toolchain.json).
    [string]$PcemRoot,

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
# Used by the PCem branch to stage images and poll the guest's sentinel.
Import-Module (Join-Path $PSScriptRoot 'FatImage.psm1') -Force
# Emits the machine config and provisions the machine's CMOS (see its header
# for why both live in one place).
Import-Module (Join-Path $PSScriptRoot 'pcem-machine.psm1') -Force
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
    if (-not [string]::IsNullOrWhiteSpace($PcemRoot)) {
        $pcemRoot = [IO.Path]::GetFullPath($PcemRoot)
    }
    else {
        $pcemRoot = Join-Path $ToolRoot $manifest.pcem.installDirectory
    }
    $emulatorPath = Join-Path $pcemRoot ($manifest.pcem.executable -replace '/', [IO.Path]::DirectorySeparatorChar)
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
# Stage the run. DOSBox-X gets a host directory, exactly as the timedemo and
# bench runners do; PCem gets disk images (it cannot mount host paths).
# ---------------------------------------------------------------------------
$runName = 'dos-fidelity-' + $Emulator + '-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$stagingRoot = Join-Path (Join-Path $repoRoot 'out') $runName
if (Test-Path -LiteralPath $stagingRoot) {
    throw "Fidelity staging path already exists; refusing to overwrite '$stagingRoot'."
}
$quakeRoot = Join-Path $stagingRoot 'quake'
$pcemStage = $null
if ($Emulator -eq 'dosbox-x') {
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
}
else {
    # PCem cannot mount a host directory, so the guest tree lives inside
    # dos.hdd: pcem-stage.ps1 installs MS-DOS on C: (bootable MBR + VBR
    # chain loader) with C:\AUTOEXEC.BAT running the probes and writing
    # C:\DONE.TXT. The host staging directory only needs to exist so the
    # report read back out of the image has somewhere to land for the shared
    # parser below. No floppy image is involved.
    New-Item -ItemType Directory -Path $quakeRoot -Force | Out-Null
    $pcemStage = & (Join-Path $PSScriptRoot 'pcem-stage.ps1') `
        -StagingRoot $stagingRoot -BenchmarkExe $BenchmarkExe -DataRoot $DataRoot
    if ($null -eq $pcemStage) {
        throw "pcem-stage.ps1 produced no result. Staged run: $stagingRoot"
    }
}

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
    # PCem is configured with its own config file, not a DOSBox conf, and its
    # CLI accepts only --config/--fullscreen/--load_drive_a/--load_drive_b
    # (verified with `PCem.exe --help`). Two dashes matter: a single dash is
    # silently ignored and PCem boots model 0 with 4 MB while reporting success.
    #
    # Every key below is one src\pc.c:698-816 actually reads, in the blank
    # section (keys before any [header] land in CFG_MACHINE's "" section).
    # Notable values: cdrom_channel must be -1 because its default of 2 makes
    # src\ide.c:278 unconditionally retype channel 2 as CDROM and shadow the
    # hard disk; gfxcard is deliberately absent, because pc.c:720-724 maps an
    # empty value to standard VGA, which is Quake's guaranteed mode-13h path.

    # ROM wiring: the BIOS is found through [Paths] roms_paths in the global
    # pcem.cfg next to PCem.exe, not through any machine-config key. Refuse
    # here rather than launching an emulator that prints "Failed to load ROM!"
    # and carries on with is486 unset.
    $pcemCfgPath = Join-Path $pcemRoot 'pcem.cfg'
    if (-not (Test-Path -LiteralPath $pcemCfgPath -PathType Leaf) -or
        (Get-Content -LiteralPath $pcemCfgPath -Raw) -notmatch '(?m)^\s*roms_paths\s*=') {
        throw "PCem at '$pcemRoot' is not wired to the ROM set. Run .\tools\pcem-roms.ps1 first."
    }
    if ($null -eq $manifest.pcemRomset) {
        throw 'The toolchain manifest has no "pcemRomset" block.'
    }
    $biosFile = Join-Path ([IO.Path]::GetFullPath([string]$manifest.pcemRomset.path)) (
        ([string]$manifest.pcemRomset.bios) -replace '/', '\')
    if (-not (Test-Path -LiteralPath $biosFile -PathType Leaf) -or
        (Get-Item -LiteralPath $biosFile).Length -ne [int]$manifest.pcemRomset.expectedBiosBytes) {
        throw "ROM set is missing '$($manifest.pcemRomset.bios)' at the expected size: '$biosFile'."
    }

    $pcemConfigPath = Join-Path $stagingRoot 'pcem-machine.cfg'
    # The machine comes from the manifest so that the ROM that was verified
    # above is the ROM that is actually booted, and the default is named in
    # exactly one place. -PcemMachine still overrides it.
    $machineName = if ([string]::IsNullOrWhiteSpace($PcemMachine)) {
        [string]$manifest.pcemRomset.machine
    }
    else {
        $PcemMachine
    }
    if ([string]::IsNullOrWhiteSpace($machineName)) {
        throw 'No PCem machine to run: pass -PcemMachine or set pcemRomset.machine in the manifest.'
    }
    if ($machineName -ne [string]$manifest.pcemRomset.machine) {
        Write-Warning ("-PcemMachine '$machineName' is not the manifest's machine " +
            "'$($manifest.pcemRomset.machine)'. The BIOS verified above is the manifest's, so this " +
            'run is NOT using a verified ROM unless the set also carries the other machine.')
    }

    # CMOS. PCem stores NVRAM per config file (nvr\<config-basename>.<model>.nvr,
    # src\nvr.c:34-63) and the bytes are the firmware's own, so a CMOS with no
    # drive table for C: halts POST at "Hard Disk C: Type: None" - no INT13
    # drive 80, so DOS never mounts C: - and a stale checksum halts at "CMOS
    # checksum failure". Both are provisioned from scratch before every launch,
    # from the factory CMOS PCem ships plus the staged geometry, so the gate is
    # a pure function of the machine and the disk rather than of whatever the
    # last interactive run left behind. See tools\pcem-machine.psm1 for the
    # per-vendor byte layouts.
    $nvr = Set-PcemMachineNvr `
        -PcemRoot $pcemRoot `
        -Machine $machineName `
        -ConfigName ([IO.Path]::GetFileNameWithoutExtension($pcemConfigPath)) `
        -Cylinders $pcemStage.Cylinders `
        -Heads $pcemStage.Heads `
        -SectorsPerTrack $pcemStage.SectorsPerTrack
    if ($null -ne $nvr) {
        Write-Host ("CMOS:    {0} {1}/{2}/{3}, checksum {4} -> {5}" -f $nvr.Vendor, $nvr.Cylinders,
            $nvr.Heads, $nvr.Sectors, $nvr.Checksum, [IO.Path]::GetFileName($nvr.Nvr))
    }

    $pcemConfig = Get-PcemMachineConfigText `
        -Machine $machineName `
        -HardDisk $pcemStage.HardDisk `
        -Cylinders $pcemStage.Cylinders `
        -Heads $pcemStage.Heads `
        -SectorsPerTrack $pcemStage.SectorsPerTrack `
        -CpuIndex $PcemCpuIndex `
        -MemKiB $PcemMemKiB
    $pcemConfig | Set-Content -LiteralPath $pcemConfigPath -Encoding ASCII
    $arguments = '--config "{0}"' -f $pcemConfigPath
}

function Test-SameBytes {
    param([byte[]]$A, [byte[]]$B)

    if ($null -eq $A -or $null -eq $B -or $A.Length -ne $B.Length) { return $false }
    for ($i = 0; $i -lt $A.Length; $i++) {
        if ($A[$i] -ne $B[$i]) { return $false }
    }
    return $true
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
$emulatorExit = $null
try {
    if (-not $process.Start()) {
        throw "$Emulator failed to start."
    }
    if ($Emulator -eq 'pcem') {
        # PCem has no script argument and never exits on its own, so the run
        # is driven from inside the guest: AUTOEXEC.BAT ends by writing
        # C:\DONE.TXT, and the host polls dos.hdd for it. The report is then
        # read back out of the image only once it reads byte-identical on
        # consecutive polls - PCem's stdio buffer for the image is ~4 KB, so a
        # single successful read proves the file exists, not that every byte
        # has reached the host file. Only then is PCem killed.
        $hardDisk = $pcemStage.HardDisk
        $partOffset = $pcemStage.PartitionOffset
        $deadlineUtc = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        $completed = $false
        $stableReads = 0
        $lastReportBytes = $null
        while ([DateTime]::UtcNow -lt $deadlineUtc) {
            Start-Sleep -Milliseconds 500
            if ($process.HasExited) {
                throw ("$Emulator exited early (code $($process.ExitCode)) before the guest wrote " +
                    "C:\DONE.TXT. The guest screen shows where it stopped; attach dos.hdd to a " +
                    "diagnostic setup to read it. Staged run: $stagingRoot")
            }
            $sentinel = $false
            try {
                $sentinel = Test-FatImageFile -Path $hardDisk -Name 'DONE.TXT' -Offset $partOffset
            }
            catch {
                continue    # image mid-write; try again on the next tick
            }
            if (-not $sentinel) { continue }
            $fresh = $null
            try {
                $fresh = Read-FatImageFile -Path $hardDisk -Name 'QUAKE\BENCH486.TXT' -Offset $partOffset
            }
            catch {
                continue    # sentinel flushed before the report's last sector; retry
            }
            if (Test-SameBytes -A $fresh -B $lastReportBytes) {
                $stableReads++
            }
            else {
                $stableReads = 0
            }
            $lastReportBytes = $fresh
            if ($stableReads -ge 2) {
                $completed = $true
                break
            }
        }
        if (-not $completed) {
            if (-not $process.HasExited) { $process.Kill() }
            throw ("$Emulator did not produce a stable C:\QUAKE\BENCH486.TXT within $TimeoutSeconds seconds " +
                "(no C:\DONE.TXT sentinel, or the report never settled). Staged run: $stagingRoot`n" +
                "Attach dos.hdd (or the staged machine config) by hand to see where the guest stopped - " +
                "a halting POST (CMOS mismatch waiting for F1) or a boot failure both look like this from here.")
        }
        if (-not $process.HasExited) { $process.Kill() }
        # Prefer a post-kill read: PCem's handle is closed, so nothing is left
        # in flight. The bytes already proven stable are the fallback if the
        # image is momentarily unopenable.
        $finalReportBytes = $lastReportBytes
        try {
            $postKill = Read-FatImageFile -Path $hardDisk -Name 'QUAKE\BENCH486.TXT' -Offset $partOffset
            if ($postKill.Length -gt 0) { $finalReportBytes = $postKill }
        }
        catch { }
        [IO.File]::WriteAllBytes((Join-Path $quakeRoot 'bench486.txt'), $finalReportBytes)
    }
    else {
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            throw "$Emulator fidelity run exceeded $TimeoutSeconds seconds."
        }
        $emulatorExit = $process.ExitCode
    }
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
    # The two FPU cases share the probe name "fpu" and differ only by the
    # trailing label, so the label must be consumed explicitly. A greedy \S+
    # would swallow the iteration count and fail to match, which is how the
    # first version of this parser silently lost both FIST timings.
    if ($line -match 'fidelity\s+(?<name>\S+)(?:\s+(?<label>fistp32|fist16))?\s+(?<iterations>\d+)\s+ops\s+(?<seconds>[0-9.]+)\s+sec\s+(?<ns>[0-9.]+)\s+ns/op') {
        $key = if ($Matches['label']) { $Matches['label'] } else { $Matches['name'] }
        $probes[$key] = [ordered]@{
            probe = $Matches['name']
            label = $Matches['label']
            iterations = [int]$Matches['iterations']
            seconds = [double]$Matches['seconds']
            nanosecondsPerOp = [double]$Matches['ns']
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
# single-store FPU probe. A flat-FPU emulator makes the two converge. The
# denominator is 'fistp32' because the parser now keys the two FPU cases
# separately; the bare name 'fpu' no longer exists.
$x87VsFpu = Get-ProbeRatio -Numerator 'x87chain' -Denominator 'fistp32'
$checks += [ordered]@{
    name = 'x87 chain is charged for its latency'
    detail = 'x87chain vs single FPU store'
    ratio = $x87VsFpu
    pass = ($null -ne $x87VsFpu -and $x87VsFpu -ge 3.0)
    requirement = 'x87chain must be >= 3.0x the single-store FPU probe'
}

# 2. FISTPL against 16-bit FIST. The cost model prices fistp at 39 cycles and
# fistps materially less, so the two must separate. Both cases are now keyed
# distinctly by the parser above.
$fistSeparation = Get-ProbeRatio -Numerator 'fistp32' -Denominator 'fist16'
$checks += [ordered]@{
    name = 'FISTPL and 16-bit FIST are charged differently'
    detail = 'fistp32 vs fist16'
    ratio = $fistSeparation
    pass = ($null -ne $fistSeparation -and $fistSeparation -ge $flatFloor)
    requirement = "fistp32 must be >= $flatFloor x fist16 (the model prices it at 39 cy)"
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

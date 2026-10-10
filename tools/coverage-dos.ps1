<#
.SYNOPSIS
    Runs scenarios that exercise code the parity gate cannot see, and asserts they
    executed.

.DESCRIPTION
    Every gate in tools\run-tests.ps1 is a renderer gate. The timedemo plays demo1,
    which means:

      - no menu is ever opened (M_Draw returns at menu.c:2944 because m_state is
        m_none and key_dest is never key_menu);
      - the server is never started -- sv.active stays false, so the
        `if (sv.active) Host_ServerFrame()` at host.c:689 never fires;
      - no net socket is ever created -- NET_Init runs, but NET_Connect,
        NET_GetMessage, NET_SendMessage and NET_CheckNewConnections have no
        reachable caller, so the loopback driver's message path is dead;
      - -nosound returns from S_Init at snd_dma.c:167 before GUS_Init, and
        -nocdaudio returns from CDAudio_Init, so the entire sound path is dead.

    Consequently world.c (the whole 22 KB collision/trace/area-link system),
    sv_main/sv_phys/sv_user/sv_move, pr_exec/pr_cmds and every net driver past its
    Init are **not covered by any gate in the tree**. An assembly conversion of any
    of them would ship unverified and the timedemo would still report PASS.

    This tool closes that gap for the single-process multiplayer case, which is the
    cheapest way to light up the server, the collision code, the Quake bytecode
    builtins and the net socket layer at once, on one machine, with no second peer.

    **How the assertion works, and how weak it is.** The scenarios are bounded by
    `wait`, which delays the remainder of the command buffer by exactly one frame
    (cmd.c:53-56; the argument is ignored, so N waits means N frames). A successful
    `connect local` is itself the evidence: CL_Connect calls
    `Host_Error ("CL_Connect: connect failed")` (cl_main.c:159) if NET_Connect
    returns NULL, so a clean exit implies the server spawned, the client connected,
    and SV_RunClients -> SV_Physics ran -- which requires world.c. A failure exits
    non-zero.

    That is a *smoke-grade* proof of coverage: it proves the paths were taken, not
    how much of them ran. A measured proof needs counters, and the mechanism for
    those already exists -- see the metrics block emitted by the -Instrumentation
    build (host_cmd.c:1217), where a counter is declared at host_cmd.c:178,
    extern'd in quakedef.h:193, incremented at the site, and emitted in the format
    string at host_cmd.c:1219. Note the standing hazard: the reporter's
    `char text[1024]` is already at its limit, so add a field by adding a report
    call, never by growing that format string.

.PARAMETER Scenario
    localmp (default) runs `map e1m1` + `connect local`, which covers world.c,
    sv_main/sv_phys/sv_user/sv_move, pr_exec/pr_cmds and the net socket layer.
    Frames sets how many frames to run after connecting.

.PARAMETER CpuTarget
    i486 (default) or i386.

.PARAMETER TimeoutSeconds
    Wall-clock cap. The default is generous because this run loads a full map and
    compiles the Quake bytecode before it connects.

.EXAMPLE
    .\tools\coverage-dos.ps1 -NoBootstrap

.EXAMPLE
    .\tools\coverage-dos.ps1 -Scenario localmp -Frames 32
#>
[CmdletBinding()]
param(
    [ValidateSet('localmp')]
    [string]$Scenario = 'localmp',
    [ValidateRange(1, 256)]
    [int]$Frames = 64,
    [ValidateSet('c', 'asm')]
    [string]$ConsoleImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenNotifyImplementation = 'c',
    [ValidateSet('c', 'asm')]
    [string]$ScreenCenterStringImplementation = 'c',
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    [string]$DataRoot,
    [string]$ToolRoot,
    [int]$TimeoutSeconds = 300,
    [switch]$NoBootstrap,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'common.ps1')
$toolManifest = Read-ToolchainManifest -ToolsDirectory $PSScriptRoot
$ToolRoot = Resolve-ToolRoot -ToolRoot $ToolRoot
$DataRoot = Resolve-DataRoot -DataRoot $DataRoot -RepoRoot $repoRoot

$build = Join-Path $PSScriptRoot 'build-dos.ps1'
$buildParams = @{ CpuTarget = $CpuTarget }
if ($NoBootstrap) { $buildParams.NoBootstrap = $true }
# The builder is the only place that knows the output paths. `executable` is
# already an absolute path -- joining it onto outputRoot duplicates it.
Add-RunnerBuildSelectors -BuildParameters $buildParams -Command $MyInvocation.MyCommand -SessionState $ExecutionContext.SessionState
$resolved = (& $build @buildParams -DumpFlags | Out-String) | ConvertFrom-Json
$releaseExe = $resolved.executable

# Rebuild when the executable is missing OR when it no longer matches the tree.
# This runner used to test only for existence, so an existing quake.exe was
# coverage-tested indefinitely however many sources had changed. The claim this
# gate makes -- that world.c, sv_* and pr_* were reached -- is only worth
# anything if it was reached in the binary under test, so a stale binary
# invalidates the result. Hashing is shared with the other three runners via
# tools\common.ps1.
$sourceFingerprint = Get-BuildFingerprint -RepoRoot $repoRoot -Resolved $resolved
$freshness = Get-BuildFreshness -Executable $releaseExe -Fingerprint $sourceFingerprint
if ((-not $SkipBuild) -or $freshness.Stale) {
    if ($SkipBuild -and $freshness.Stale) {
        throw "DOS executable '$releaseExe' is stale with respect to the current sources (fingerprint $sourceFingerprint). Rerun without -SkipBuild to rebuild."
    }
    if ($freshness.Stale) {
        Write-Host ("Release build is stale (fingerprint {0}); rebuilding." -f $freshness.FingerprintPrefix)
    }
    & $build @buildParams
    if (-not (Test-Path -LiteralPath $releaseExe -PathType Leaf)) {
        throw "Required DOS executable is missing: '$releaseExe'."
    }
    Set-BuildFingerprint -Executable $releaseExe -Fingerprint $sourceFingerprint
}
if (-not (Test-Path -LiteralPath $releaseExe -PathType Leaf)) {
    throw "Required DOS executable is missing: '$releaseExe'."
}
$selectorVerification = Assert-RunnerBuildManifest -Resolved $resolved -BuildParameters $buildParams

# The build's ISA gate prints to stdout; -DumpFlags above is a pure inspection and
# must stay quiet, so nothing else is echoed here.

$dosbox = Resolve-DosboxExecutable -Manifest $toolManifest -ToolRoot $ToolRoot `
    -ToolsDirectory $PSScriptRoot -NoBootstrap:$NoBootstrap

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$staging = New-QuakeStaging -RepoRoot $repoRoot `
    -StagingRoot (Join-Path $repoRoot ('out\dos-coverage-{0}-{1}' -f $Scenario, $stamp)) `
    -Executable $releaseExe -StagedExecutableName 'quake.exe' -DataRoot $DataRoot `
    -OnExistingStaging Throw -StageDpmiHost
$stagingRoot = $staging.StagingRoot
$quakeRoot = $staging.QuakeRoot
$stagedData = $staging.StagedData
$providerVerification = Assert-RunnerDpmiProvider -CpuTarget $CpuTarget -BuildVerification $selectorVerification `
    -ProviderPath (Join-Path $quakeRoot 'cwsdpmi.exe')

# The scenario commands go in id1\autoexec.cfg, NOT in '+' arguments. quake.rc runs
#     exec default.cfg / exec config.cfg / exec autoexec.cfg / stuffcmds / startdemos
# and '+' arguments are appended by `stuffcmds`, which executes AFTER `startdemos`.
# So a '+map e1m1 +connect local +wait ...' sequence starts demo1 playback first and
# only then hosts a server in the same process; that combination terminates
# abnormally somewhere between the 5th and 6th frame after connecting, with no
# DOSBox-level exception, i.e. the process calls exit() itself. Executing the
# commands from autoexec.cfg instead puts them before startdemos, so sv.active is
# already true and Host_Startdemos_f takes its `else cls.demonum = -1` branch
# (host_cmd.c) and no demo ever starts. That was worth 4 frames -> 64 frames, both
# clean.
#
# '%ERRORLEVEL%' is also unusable here: this DOSBox-X command processor does not
# expand it, so `echo %ERRORLEVEL% > file` writes the literal text "ECHO is off."
# tools\smoke-dos.ps1 sidesteps this by writing a literal 0. Branching on
# `if errorlevel` does work, so the marker below is 0 for success and 1 for a
# non-zero exit.
$commands = switch ($Scenario) {
    'localmp' {
        $seq = @('map e1m1', 'connect local')
        $seq += (1..$Frames | ForEach-Object { 'wait' })
        $seq += 'quit'
        ($seq -join "`r`n") + "`r`n"
    }
}
$commands | Set-Content -LiteralPath (Join-Path $stagedData 'autoexec.cfg') -Encoding ASCII

$batchPath = Join-Path $quakeRoot 'coverage.bat'
@"
@echo off
cd \quake
quake.exe -basedir \quake -nosound -nojoy -nomouse -nocdaudio -stdvid -forcquit
if errorlevel 1 echo 1 > \quake\coverage.exi
if not errorlevel 1 echo 0 > \quake\coverage.exi
exit
"@ | Set-Content -LiteralPath $batchPath -Encoding ASCII

$configPath = New-DosboxRuntimeConfig -ProfileTemplate (Get-DosboxProfilePath -ToolsDirectory $PSScriptRoot) `
    -StagingRoot $stagingRoot -BatchName 'coverage.bat' -CpuTarget $CpuTarget -ConfigName 'dosbox-x.conf'

Write-Host ("Coverage scenario '{0}': map e1m1 + connect local + {1} frame(s)" -f $Scenario, $Frames)
Write-Host ("Staging: {0}" -f $stagingRoot)

# A timeout is not fatal here, unlike in the other three runners: this gate still
# has to write a result document recording that the scenario did not complete.
$run = Invoke-DosboxProcess -Dosbox $dosbox -ConfigPath $configPath `
    -TimeoutSeconds $TimeoutSeconds -Description "DOSBox-X coverage scenario '$Scenario'"
$timedOut = $run.TimedOut
$dosboxExit = $run.ExitCode

$markerPath = Join-Path $quakeRoot 'coverage.exi'
$quakeExit = $null
if (Test-Path -LiteralPath $markerPath -PathType Leaf) {
    $raw = (Get-Content -LiteralPath $markerPath -Raw).Trim()
    if ([int]::TryParse($raw, [ref]$quakeExit)) { } else { $quakeExit = $null }
}

# What each scenario is supposed to have made reachable. This is the coverage
# claim, and it is a claim about which code became *reachable*, not a count of how
# much of it ran -- see the .DESCRIPTION for why a measured proof needs counters.
$expectedCoverage = switch ($Scenario) {
    'localmp' {
        @(
            'world.c            SV_LinkEdict / SV_TouchLinks / SV_ClipMoveToEntity / SV_RecursiveHullCheck'
            'sv_main.c          SV_SpawnServer / SV_RunClients / SV_SendClientMessages / SV_CheckForNewClients'
            'sv_phys.c          SV_PhysicsClient / SV_Physics_Try / SV_RunThink'
            'sv_user.c          the client-message and edict builtins reached from a live client'
            'sv_move.c          SV_Move / SV_ClipMoveToEntity / SV_PushEntity'
            'pr_exec.c          PR_ExecuteProgram over the loaded prog.qc'
            'pr_cmds.c          the PF_* builtins that prog.qc calls'
            'net_main.c         NET_Connect / NET_CheckNewConnections / NET_GetMessage / NET_SendMessage / NET_Close'
            'net_loop.c         the loopback driver past Loop_Init, which had no reachable caller'
        )
    }
}

$ok = (-not $timedOut) -and ($null -ne $quakeExit) -and ($quakeExit -eq 0)

$report = [ordered]@{
    scenario        = $Scenario
    cpuTarget       = $CpuTarget
    consoleImplementation = $ConsoleImplementation
    screenNotifyImplementation = $ScreenNotifyImplementation
    screenCenterStringImplementation = $ScreenCenterStringImplementation
    buildSelectorVerification = $selectorVerification
    providerVerification = $providerVerification
    frames          = $Frames
    commands        = $commands
    timedOut        = $timedOut
    dosboxExit      = $dosboxExit
    quakeExit       = $quakeExit
    result          = $(if ($ok) { 'PASS' } else { 'FAIL' })
    proof           = 'A clean exit implies CL_Connect did not take the Host_Error path at cl_main.c:159, so the server spawned and the client connected, which requires SV_RunClients -> SV_Physics -> world.c. This is a smoke-grade proof that the paths were taken, not a count of how much of them ran.'
    expectedCoverage = @($expectedCoverage)
    stagingRoot     = $stagingRoot
}
$reportPath = Join-Path $stagingRoot 'coverage-result.json'
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding ASCII

Write-Host ''
Write-Host ('Coverage result: {0}  (dosbox exit {1}, quake exit {2})' -f $report.result, $dosboxExit, $quakeExit)
Write-Host ('Report: {0}' -f $reportPath)
if ($ok) {
    Write-Host ''
    Write-Host 'Now reachable, and previously reached by no gate:' -ForegroundColor Green
    foreach ($line in $expectedCoverage) { Write-Host ("  + {0}" -f $line) -ForegroundColor Green }
}
else {
    Write-Host ''
    Write-Host 'FAILED. The scenario did not complete cleanly:' -ForegroundColor Red
    if ($timedOut) { Write-Host ("  - timed out after {0}s" -f $TimeoutSeconds) -ForegroundColor Red }
    if ($null -eq $quakeExit) { Write-Host '  - no coverage.exi marker: the batch never reached the echo, so the executable did not return' -ForegroundColor Red }
    elseif ($quakeExit -ne 0) { Write-Host ("  - quake exited {0}" -f $quakeExit) -ForegroundColor Red }
    Write-Host ("  Staging kept for inspection: {0}" -f $stagingRoot) -ForegroundColor Red
}

if ($ok) { exit 0 }
exit 1

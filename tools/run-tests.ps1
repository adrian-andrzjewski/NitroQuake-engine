<#
.SYNOPSIS
    Runs every verification gate in this tree and aggregates the results.

.DESCRIPTION
    The gates existed but had no single entry point.  ASM486-HANDOFF.md carried a
    hand-copied six-command checklist that omitted tools\test-sysinfo-dos.py and
    tools\test-video-dos.py entirely, and the ledger's own rule is that an audit
    found ten of twelve anchors wrong -- so a checklist nobody runs is worth
    little.  This runner exists so the full set is one command, ordered cheapest
    and most fundamental first so a failure surfaces in seconds rather than
    minutes, and so a new gate cannot be added without somewhere obvious to
    register it.

    Order and why:

      0. doc-structure-check.ps1  pure text analysis over docs/; no compiler
                                and no emulator, so it is the cheapest gate
                                and the only one that judges the documents the
                                other gates are described by. It enforces the
                                ledger's own rule -- cite by heading, never by
                                ":NNNN" -- after an audit found ten of twelve
                                such citations wrong, each invalidated by a
                                later insertion above it.
      1. test-build-dos.py      pure build-configuration arithmetic; needs no
                                compiler, so it fails fastest and it is what
                                decides whether the other gates are testing the
                                build they think they are.
      2. test-sysinfo-dos.py    host-compiled harness over sys_dos.c's report
                                path.  Seconds.
      3. test-video-dos.py      host-compiled harness over vid_ext.c and three
                                vid_vga/vid_dos functions.  Seconds.
      4. build-dos.ps1         compiles, and now carries the blocking ISA gate,
                                so a build that emits a regressing above-target
                                instruction stops here rather than at promotion.
      5. smoke-dos.ps1         DOSBox-X startup and clean exit, both exit codes.
      6. coverage-dos.ps1     a local single-process multiplayer game, which is the
                                only gate that reaches sv_main/sv_phys/sv_user/sv_move,
                                world.c, pr_exec/pr_cmds and the net socket layer.
      7. bench-dos.ps1         bench486 correctness, including the C-versus-asm
                                comparisons that are the only parity oracle for the
                                assembly helpers.
      8. timedemo-dos.ps1      the promotion gate: 969 frames, framebuffer checksum,
                                and the median the 0.05% threshold is applied to.
                                Slowest, so it runs after bench486.
      9. guard-i486-release.py  104 SHA-256 pins over the release objects and the
                                executable.  Last, because it judges a finished build
                                and any earlier gate may have changed it.

    Note on what this suite does and does not assert.  bench486 checks for the
    string "486 benchmark correctness PASS" and timedemo-dos.ps1 asserts the frame
    count and checksum, but the bench end checksum 2378409472 is self-reported and
    is not compared against a constant by any script.  The timedemo itself exercises
    no menu, no server and no sound: M_Draw returns immediately, sv.active stays
    false so the `if (sv.active) Host_ServerFrame()` never fires, and -nosound
    returns from S_Init before GUS_Init.  Gate 6 exists to cover the server-side
    half of that, and it closes world.c, sv_main/sv_phys/sv_user/sv_move,
    pr_exec/pr_cmds and the net socket layer.  What is **still** uncovered is
    menu.c, the sound drivers (snd_dma/snd_dos/snd_gus/snd_mix/snd_mem) and
    cd_audio.c -- see ASM486-HANDOFF.md.

.PARAMETER SkipSlow
    Omit the timedemo (gate 8).  Use for a quick inner-loop check; the result is
    not a promotion result, because the timedemo is the promotion criterion.

.PARAMETER Runs
    Timedemo run count.  The project convention is 3, escalating to 5 when the
    median delta is under the 0.05% gate and therefore needs more samples.

.PARAMETER CpuTarget
    i486 (default, the retained release profile) or i386.

.PARAMETER NoBootstrap
    Pass through to the tools.  Use when the toolchain is already installed.

.EXAMPLE
    .\tools\run-tests.ps1

.EXAMPLE
    .\tools\run-tests.ps1 -SkipSlow -NoBootstrap
#>
[CmdletBinding()]
param(
    [switch]$SkipSlow,
    [ValidateRange(1, 9)]
    [int]$Runs = 3,
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    [switch]$NoBootstrap,
    [switch]$SkipReleaseGuard
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$pushLocation = Get-Location
Set-Location $repoRoot

$results = New-Object System.Collections.Generic.List[object]
$sw = [System.Diagnostics.Stopwatch]::StartNew()

function Invoke-Gate {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string[]]$Command,
        [int]$TimeoutSeconds = 0
    )

    Write-Host ''
    Write-Host ('=' * 78)
    Write-Host ("  {0}" -f $Name)
    Write-Host ('=' * 78)

    $gateWatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        if ($TimeoutSeconds -gt 0) {
            $job = Start-Job -ScriptBlock { param($c, $r) Set-Location $r; & $c[0] @($c[1..($c.Count - 1)]) } -ArgumentList (,$Command) -ArgumentList $repoRoot
            if (Wait-Job $job -Timeout $TimeoutSeconds) {
                Receive-Job $job | Out-Host
            }
            else {
                Stop-Job $job
                throw "timed out after $TimeoutSeconds s"
            }
            Remove-Job $job -Force
        }
        else {
            & $Command[0] @($Command[1..($Command.Count - 1)]) 2>&1 | Out-Host
        }
        $code = $LASTEXITCODE
    }
    catch {
        Write-Host ("  FAILED: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $code = 1
    }
    $gateWatch.Stop()

    $ok = ($code -eq 0)
    $results.Add([pscustomobject]@{
            gate     = $Name
            kind     = $Kind
            exit     = $code
            seconds  = [math]::Round($gateWatch.Elapsed.TotalSeconds, 1)
            result   = $(if ($ok) { 'PASS' } else { 'FAIL' })
        })
    if (-not $ok) {
        Write-Host ("  -> FAIL (exit {0})" -f $code) -ForegroundColor Red
    }
    else {
        Write-Host ("  -> PASS ({0:N1}s)" -f $gateWatch.Elapsed.TotalSeconds) -ForegroundColor Green
    }
    return $ok
}

$pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue)
if ($null -eq $pwshExe) { $pwshExe = (Get-Command powershell) }
$nb = if ($NoBootstrap) { @('-NoBootstrap') } else { @() }

# ---- 1-3: host-only tests.  No compiler, no emulator, seconds each. --------
Invoke-Gate -Name 'doc-structure-check (citations, links, ledger index)' -Kind 'host' `
    -Command @($pwshExe.Source, '-NoProfile', '-File', 'tools/doc-structure-check.ps1') | Out-Null
Invoke-Gate -Name 'test-build-dos (flag/suffix golden pins)' -Kind 'host' -Command @('python', 'tools/test-build-dos.py') | Out-Null
Invoke-Gate -Name 'test-sysinfo-dos (sys_dos report path)' -Kind 'host' -Command @('python', 'tools/test-sysinfo-dos.py') | Out-Null
Invoke-Gate -Name 'test-video-dos (vid_ext + vid_vga/vid_dos)' -Kind 'host' -Command @('python', 'tools/test-video-dos.py') | Out-Null

# ---- 4: build, carrying the blocking ISA gate. ----------------------------
Invoke-Gate -Name "build-dos ($CpuTarget; includes the blocking ISA gate)" -Kind 'build' `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/build-dos.ps1', '-CpuTarget', $CpuTarget) + $nb) | Out-Null

# ---- 5: smoke. ------------------------------------------------------------
Invoke-Gate -Name 'smoke-dos (DOSBox-X startup + clean exit)' -Kind 'dos' `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/smoke-dos.ps1', '-TimeoutSeconds', '90') + $nb) | Out-Null

# ---- 6: coverage of the paths the parity gate cannot see. ------------------
# Cheap (seconds) and it is the only gate that executes the server, the collision
# code, the Quake bytecode builtins and the net socket layer.
Invoke-Gate -Name 'coverage-dos (localmp: server/world/pr/net reachable)' -Kind 'dos' `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/coverage-dos.ps1', '-CpuTarget', $CpuTarget, '-SkipBuild') + $nb) | Out-Null

# ---- 7: bench486 correctness. ---------------------------------------------
Invoke-Gate -Name 'bench-dos (bench486 PASS, C-vs-asm parity)' -Kind 'dos' `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/bench-dos.ps1', '-TimeoutSeconds', '600') + $nb) | Out-Null

# ---- 7: the promotion gate. ----------------------------------------------
if ($SkipSlow) {
    $results.Add([pscustomobject]@{
            gate    = 'timedemo (969 frames, checksum, median)'
            kind    = 'dos'
            exit    = '-'
            seconds = 0
            result  = 'SKIP'
        })
    Write-Host ''
    Write-Host '  timedemo: SKIPPED (-SkipSlow) -- this run is not a promotion result.'
}
else {
    Invoke-Gate -Name "timedemo ($Runs runs; 969 frames + checksum + median)" -Kind 'dos' `
        -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/timedemo-dos.ps1', '-Runs', "$Runs", '-NoFpsStats') + $nb) | Out-Null
}

# ---- 8: release artefact pins.  Last: it judges a finished build. ---------
if ($SkipReleaseGuard) {
    $results.Add([pscustomobject]@{
            gate    = 'guard-i486-release (104 artefact hashes)'
            kind    = 'repo'
            exit    = '-'
            seconds = 0
            result  = 'SKIP'
        })
}
else {
    Invoke-Gate -Name 'guard-i486-release (104 artefact hashes)' -Kind 'repo' `
        -Command @('python', 'tools/guard-i486-release.py') | Out-Null
}

$sw.Stop()

# ---- summary --------------------------------------------------------------
Write-Host ''
Write-Host ('=' * 78)
Write-Host '  SUMMARY'
Write-Host ('=' * 78)
$results | Format-Table -AutoSize | Out-Host

$failed = @($results | Where-Object { $_.result -eq 'FAIL' })
$skipped = @($results | Where-Object { $_.result -eq 'SKIP' })

Write-Host ("  {0} passed, {1} failed, {2} skipped, {3:N1}s total" -f
    @($results | Where-Object { $_.result -eq 'PASS' }).Count, $failed.Count, $skipped.Count, $sw.Elapsed.TotalSeconds)

if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host '  Failing gates:' -ForegroundColor Red
    foreach ($f in $failed) { Write-Host ("    - {0} (exit {1})" -f $f.gate, $f.exit) -ForegroundColor Red }
}

Write-Host ''
Write-Host '  Coverage gates still missing (2026-10-03):' -ForegroundColor Yellow
Write-Host '    - menu.c (2607 lines): no gate ever opens a menu; M_Draw returns at' -ForegroundColor Yellow
Write-Host '      menu.c:2944 because m_state is m_none and key_dest is never key_menu.' -ForegroundColor Yellow
Write-Host '    - the sound path: snd_dma/snd_dos/snd_gus/snd_mix/snd_mem and cd_audio.' -ForegroundColor Yellow
Write-Host '      -nosound returns from S_Init at snd_dma.c:167 before GUS_Init, and' -ForegroundColor Yellow
Write-Host '      -nocdaudio returns from CDAudio_Init, so none of it executes.' -ForegroundColor Yellow
Write-Host '    - measured coverage counts: coverage-dos proves the server, world.c,' -ForegroundColor Yellow
Write-Host '      pr_exec/pr_cmds and net paths were TAKEN, not how much of them ran.' -ForegroundColor Yellow
Write-Host '      A count needs a counter on the metrics path (host_cmd.c:178 / 1219).' -ForegroundColor Yellow
Write-Host '    - bench486 asserts only the PASS string; its end checksum 2378409472 is' -ForegroundColor Yellow
Write-Host '      self-reported and compared by no script.' -ForegroundColor Yellow

Set-Location $pushLocation

if ($failed.Count -gt 0) { exit 1 }
exit 0
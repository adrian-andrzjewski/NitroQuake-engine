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
      1a. test-isa-audit.py     host-only ISA classifier checks for the 386
                                IMUL encodings and 32-bit target assumptions.
      2. test-sysinfo-dos.py    host-compiled harness over sys_dos.c's report
                                path.  Seconds.
      3. test-video-dos.py      host-compiled harness over vid_ext.c and three
                                vid_vga/vid_dos functions.  Seconds.
      3a. test-rendering.py, test_blobexplosion_demo_fixture.py,
          test-lavasplash.py, test-teleportsplash.py,
          test-runparticleeffect.py, and test-timedemo-event-record.ps1 host
          checks for frame comparisons, particle source contracts, and event
          report parsing. Seconds.
      3b. test-rendering-reports.py exact paired-profile report comparisons.
      3c. test-renderer-ownership.py compiler clones and direct root traces.
      4. build-dos.ps1         compiles, and now carries the blocking ISA gate,
                                so a build that emits a regressing above-target
                                instruction stops here rather than at promotion.
      5. isa-audit-source.py   the source-level ISA ratchet, and the cross-check
                                on gate 4: same question, different measurement
                                (compiler output rather than disassembled
                                objects), so its agreement with gate 4 is evidence
                                rather than a restatement. It uses the selected
                                target's ratchet: i486 expects zero above-target
                                instructions; i386 retains measured i486 forms.
      6. smoke-dos.ps1         DOSBox-X startup and clean exit, both exit codes.
      7. coverage-dos.ps1     a local single-process multiplayer game, which is the
                                only gate that reaches sv_main/sv_phys/sv_user/sv_move,
                                world.c, pr_exec/pr_cmds and the net socket layer.
      8. bench-dos.ps1         bench486 correctness, including the C-versus-asm
                                comparisons that are the only parity oracle for the
                                assembly helpers.
      9. render-validation-dos.ps1 deterministic demo1/2/3 scenes, VGA/VESA and
                                 lighting/viewport variants, per-frame checksums, and tolerant
                                 captured-image comparisons.
     10. timedemo-dos.ps1      969 frames, framebuffer checksum and timing for
                                material performance regressions. Speed does not
                                determine renderer conversion acceptance.
     11. guard-i486-release.py  SHA-256 pins over the release objects and the
                                executable.  Last, because it judges a finished
                                build and any earlier gate may have changed it.
                                The tool prints how many; nothing here counts them,
                                because a hardcoded count in the runner is a
                                second thing to keep in step with the golden.

    Note on what this suite does and does not assert.  bench486 checks for the
    string "486 benchmark correctness PASS" and timedemo-dos.ps1 asserts the frame
    count and checksum, but the bench end checksum 2378409472 is self-reported and
    is not compared against a constant by any script.  The timedemo itself exercises
    no menu and no sound: M_Draw returns immediately, and -nosound returns from
    S_Init before GUS_Init.  Gate 7 exists to cover the server-side half, and it
    closes world.c, sv_main/sv_phys/sv_user/sv_move, pr_exec/pr_cmds and the net
    socket layer.

    What is **still** uncovered is menu.c, the sound drivers
    (snd_dma/snd_dos/snd_gus/snd_mix/snd_mem) and cd_audio.c.  That list is kept in
    ASM486-HANDOFF.md, under "Coverage gates still missing" -- not here, because a
    checklist in this file's tail drifts from the code it describes, and this one
    had already gone stale.

.PARAMETER SkipSlow
    Omit the final three-run regression timedemo. Use for an inner-loop check.

.PARAMETER SkipRendering
    Omit the deterministic multi-scene rendering suite. Use with -SkipSlow for
    the shortest host/build checks.

.PARAMETER Runs
    Timedemo run count. Three runs provide representative regression evidence;
    repeat only when a material regression or unstable measurements require it.

.PARAMETER CpuTarget
    i486 (default, the retained release profile) or i386.

.PARAMETER NoBootstrap
    Pass through to the tools.  Use when the toolchain is already installed.

.EXAMPLE
    .\tools\run-tests.ps1

.EXAMPLE
    .\tools\run-tests.ps1 -SkipSlow -SkipRendering -NoBootstrap
#>
[CmdletBinding()]
param(
    [switch]$SkipSlow,
    [ValidateRange(1, 9)]
    [int]$Runs = 3,
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    [switch]$NoBootstrap,
    [switch]$SkipReleaseGuard,
    [switch]$SkipRendering
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
            # A job, not an in-process call: the only way to bound a child that
            # wedges.  -ArgumentList takes ONE flat array whose elements become
            # the scriptblock's parameters, so the command vector and the
            # directory are its two elements.  Passing -ArgumentList twice is a
            # binding error, and wrapping the command in a unary comma nests it
            # one level too deep ($Command[0] is then the whole vector, which
            # splats as a single joined command name), so both of those forms
            # were broken and this branch was unreachable.  The job's last
            # statement is the child's exit code, because a job returns values
            # rather than setting the caller's $LASTEXITCODE.
            $job = Start-Job -ScriptBlock {
                param($Command, $RepoRoot)
                Set-Location $RepoRoot
                & $Command[0] @($Command[1..($Command.Count - 1)])
                $LASTEXITCODE
            } -ArgumentList @($Command, $repoRoot)
            try {
                if (-not (Wait-Job $job -Timeout $TimeoutSeconds)) {
                    Stop-Job $job
                    throw "timed out after $TimeoutSeconds s"
                }
                $output = @(Receive-Job $job)
                $output | Out-Host
                $code = if ($output.Count -gt 0) { [int]$output[-1] } else { 1 }
            }
            finally {
                Remove-Job $job -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            & $Command[0] @($Command[1..($Command.Count - 1)]) 2>&1 | Out-Host
            $code = $LASTEXITCODE
        }
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
Invoke-Gate -Name 'test-runner-selectors (requested versus built)' -Kind 'host' -Command @('pwsh', '-NoProfile', '-File', 'tools/test-runner-selectors.ps1') | Out-Null
Invoke-Gate -Name 'test-render-progress (live timedemo output)' -Kind 'host' `
    -Command @($pwshExe.Source, '-NoProfile', '-File', 'tools/test-render-progress.ps1') | Out-Null
Invoke-Gate -Name 'test-build-fingerprints (instruction inputs and flags)' -Kind 'host' -Command @('pwsh', '-NoProfile', '-File', 'tools/test-build-fingerprints.ps1') | Out-Null
Invoke-Gate -Name 'test-isa-audit (486 opcode classifier)' -Kind 'host' -Command @('python', 'tools/test-isa-audit.py') | Out-Null
Invoke-Gate -Name 'test-sysinfo-dos (sys_dos report path)' -Kind 'host' -Command @('python', 'tools/test-sysinfo-dos.py') | Out-Null
Invoke-Gate -Name 'test-video-dos (vid_ext + vid_vga/vid_dos)' -Kind 'host' -Command @('python', 'tools/test-video-dos.py') | Out-Null
Invoke-Gate -Name 'test-rendering (PCX comparison + frame-log parser)' -Kind 'host' -Command @('python', 'tools/test-rendering.py') | Out-Null
Invoke-Gate -Name 'test-blobexplosion-demo-fixture (PACK + .dem format)' -Kind 'host' `
    -Command @('python', '-B', 'tools/test_blobexplosion_demo_fixture.py') | Out-Null
Invoke-Gate -Name 'test-lavasplash-fixture (assembly source contract)' -Kind 'host' `
    -Command @('python', '-B', 'tools/test-lavasplash.py') | Out-Null
Invoke-Gate -Name 'test-teleportsplash-fixture (assembly source contract)' -Kind 'host' `
    -Command @('python', '-B', 'tools/test-teleportsplash.py') | Out-Null
Invoke-Gate -Name 'test-runparticleeffect-fixture (assembly source contract)' -Kind 'host' `
    -Command @('python', '-B', 'tools/test-runparticleeffect.py') | Out-Null
Invoke-Gate -Name 'test-entityparticles-fixture (assembly source contract)' -Kind 'host' `
    -Command @('python', '-B', 'tools/test-entityparticles.py') | Out-Null
Invoke-Gate -Name 'test-timedemo-event-record (BENCH486 event report parser)' -Kind 'host' `
    -Command @($pwshExe.Source, '-NoProfile', '-File', 'tools/test-timedemo-event-record.ps1') | Out-Null
Invoke-Gate -Name 'test-rendering-reports (exact C/ASM parity report comparator)' -Kind 'host' -Command @('python', 'tools/test-rendering-reports.py') | Out-Null
Invoke-Gate -Name 'test-renderer-ownership (compiler clones and call traces)' -Kind 'host' -Command @('python', 'tools/test-renderer-ownership.py') | Out-Null

# ---- 4: build, carrying the blocking ISA gate. ----------------------------
Invoke-Gate -Name "build-dos ($CpuTarget; includes the blocking ISA gate)" -Kind 'build' `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/build-dos.ps1', '-CpuTarget', $CpuTarget) + $nb) | Out-Null

# Exercise the actual disassembler gate, including deliberately forbidden code.
# Runs after bootstrap/build so the pinned assembler and objdump are available.
Invoke-Gate -Name 'test-isa-audit-objects (permitted and forbidden machine code)' -Kind 'host' `
    -Command @('python', 'tools/test-isa-audit-objects.py') | Out-Null
foreach ($test in @('test-coff-code-data.py','test-runtime-source-proofs.py',
        'test-djgpp-assembler-tool.py','test-final-executable-isa-ranges.py',
        'test-source-bound-linked-isa.py','test-embedded-startup-isa.py','test-cws-provider-proof.py')) {
    Invoke-Gate -Name "$test (strict source/binary evidence)" -Kind 'host' `
        -Command @('python', "tools/$test") | Out-Null
}

# ---- 5: the source-level ISA cross-check -----------------------------------
# The gate above counts instructions in the real objects. This one counts them in
# the compiler's own output, which is a genuinely different measurement: the object
# tool sees every inlined copy, this one sees one hit per source construct. That
# independence is the point -- tools\golden\isa-baseline.json records that the two
# landing close together is the evidence its 62/63 string-data exclusion is sound --
# so an unregistered cross-check is not a cross-check.
#
# It was unregistered, which is the same defect run-tests.ps1's own .DESCRIPTION
# records about the six-command checklist this runner replaced.
#
# The ratchet checks each ISA bucket and keeps unknown/P6 counts at zero. This is
# host-only and requires the already installed DOS compiler, but no emulator.
#
# No -NoBootstrap is passed: this tool never installs the toolchain, it only needs
# it present, and it has no such switch. Appending one made argparse exit 2.
Invoke-Gate -Name 'isa-audit-source (source-level ISA ratchet, cross-check)' -Kind 'host' -TimeoutSeconds 600 `
    -Command @('python', 'tools/isa-audit-source.py', '-CpuTarget', $CpuTarget) | Out-Null

# ---- 6: smoke. ------------------------------------------------------------
Invoke-Gate -Name 'smoke-dos (DOSBox-X startup + clean exit)' -Kind 'dos' -TimeoutSeconds 300 `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/smoke-dos.ps1', '-TimeoutSeconds', '90') + $nb) | Out-Null

# ---- 7: coverage of the paths the parity gate cannot see. ------------------
# Cheap (seconds) and it is the only gate that executes the server, the collision
# code, the Quake bytecode builtins and the net socket layer.
Invoke-Gate -Name 'coverage-dos (localmp: server/world/pr/net reachable)' -Kind 'dos' -TimeoutSeconds 600 `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/coverage-dos.ps1', '-CpuTarget', $CpuTarget, '-SkipBuild') + $nb) | Out-Null

# ---- 8: bench486 correctness. ---------------------------------------------
# The gate-level -TimeoutSeconds is a watchdog above the runner's own 3600 s, not a
# second limit on the benchmark: it exists so a wedged DOSBox-X or a child that
# never returns cannot hold the suite open indefinitely. Same idea on the timedemo.
Invoke-Gate -Name 'bench-dos (bench486 PASS, C-vs-asm parity)' -Kind 'dos' -TimeoutSeconds 3900 `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/bench-dos.ps1', '-TimeoutSeconds', '3600') + $nb) | Out-Null

# ---- 9: deterministic rendered scenes, temporal checks and image diffs. ---
if ($SkipRendering) {
    $results.Add([pscustomobject]@{
            gate    = 'render-validation (demo scenes, frame stability, PCX comparisons)'
            kind    = 'dos'
            exit    = '-'
            seconds = 0
            result  = 'SKIP'
        })
    Write-Host ''
    Write-Host '  render-validation: SKIPPED (-SkipRendering).' -ForegroundColor Yellow
}
else {
    Invoke-Gate -Name 'render-validation (demo1/2/3, VGA/VESA, quality, images)' -Kind 'dos' -TimeoutSeconds 3600 `
        -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/render-validation-dos.ps1', '-CpuTarget', $CpuTarget, '-TimeoutSeconds', '600') + $nb) | Out-Null
}

# ---- 10: deterministic correctness and performance regression evidence. --
if ($SkipSlow) {
    $results.Add([pscustomobject]@{
            gate    = 'timedemo (969 frames, checksum, median)'
            kind    = 'dos'
            exit    = '-'
            seconds = 0
            result  = 'SKIP'
        })
    Write-Host ''
    Write-Host '  timedemo: SKIPPED (-SkipSlow); final timing evidence omitted.'
}
else {
    Invoke-Gate -Name "timedemo ($Runs runs; 969 frames + checksum + median)" -Kind 'dos' -TimeoutSeconds 900 `
        -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/timedemo-dos.ps1', '-Runs', "$Runs", '-NoFpsStats') + $nb) | Out-Null
}

# ---- 11: release artefact pins.  Last: it judges a finished build. --------
if ($SkipReleaseGuard) {
    $results.Add([pscustomobject]@{
            gate    = 'guard-i486-release'
            kind    = 'repo'
            exit    = '-'
            seconds = 0
            result  = 'SKIP'
        })
}
else {
    Invoke-Gate -Name 'guard-i486-release' -Kind 'repo' `
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
# The list of what the suite still does not cover lives in ASM486-HANDOFF.md, under
# "Coverage gates still missing".  It used to be printed here, and that was wrong
# twice over: a checklist maintained in a script's tail drifts from the code it
# describes, and this one had already gone stale -- it was dated and cited the
# source by line number, which is the exact form docs\INDEX.md's citation rule
# exists to prevent.
Write-Host '  Coverage gaps are tracked in ASM486-HANDOFF.md, under' -ForegroundColor Yellow
Write-Host '  "Coverage gates still missing".' -ForegroundColor Yellow

Set-Location $pushLocation

if ($failed.Count -gt 0) { exit 1 }
exit 0

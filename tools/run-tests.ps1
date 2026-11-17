<#
.SYNOPSIS
    Verify the standalone game: source/build contracts and strict DOS ISA audits.
.DESCRIPTION
    No emulator or external benchmark checkout is required. -HostOnly omits
    compilation and compiler-dependent binary gates. Runtime and performance
    acceptance belongs to the separately versioned benchmark suite.
#>
[CmdletBinding()]
param(
    [switch]$HostOnly,
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

foreach ($test in @('doc-structure-check.ps1', 'test-build-number.ps1', 'test-build-fingerprints.ps1', 'test-renderer-profile-completeness.ps1')) {
    Invoke-Gate -Name $test -Kind 'host' -Command @($pwshExe.Source, '-NoProfile', '-File', "tools/$test") | Out-Null
}
foreach ($test in @('test-source-layout.py', 'test-header-dependencies.py', 'test-build-dos.py', 'test-bootstrap-dos.py', 'test-frame-timing-export.py', 'test-profile-coarse.py', 'test-optimization-history.py', 'test-isa-audit.py', 'test-sysinfo-dos.py', 'test-video-dos.py', 'test-renderer-stack-budget.py', 'test-memory-budget.py', 'test-i486-release-guard.py')) {
    Invoke-Gate -Name $test -Kind 'host' -Command @('python', "tools/$test") | Out-Null
}
if (-not $HostOnly) {
# ---- 4: build, carrying the blocking ISA gate. ----------------------------
$configuration = if ($CpuTarget -eq 'i486') { 'i486-release' } else { 'c-reference' }
Invoke-Gate -Name "build-dos ($configuration / $CpuTarget; includes the blocking ISA gate)" -Kind 'build' `
    -Command (@($pwshExe.Source, '-NoProfile', '-File', 'tools/build-dos.ps1', '-Configuration', $configuration, '-CpuTarget', $CpuTarget) + $nb) | Out-Null

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
# Current qualification limits are documented with renderer status and the
# benchmark suite's physical-486 acceptance procedure.
Write-Host '  See docs/architecture/renderer-status.md and' -ForegroundColor Yellow
Write-Host '  ../benchmarks/docs/PHYSICAL-486-ACCEPTANCE.md for open qualification gates.' -ForegroundColor Yellow

Set-Location $pushLocation

if ($failed.Count -gt 0) { exit 1 }
exit 0

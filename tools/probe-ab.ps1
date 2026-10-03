<#
.SYNOPSIS
Runs the matched control/probe A/B a dead-scratch probe needs, and prints the
median delta with the signal ratio the project requires.

.DESCRIPTION
A probe is only a measurement if its delta is many times the run spread, so this
runs three control runs, three probe runs, and a trailing control, then reports
medians and the ratio.  The trailing control is not decoration: it is the only
thing that distinguishes a real delta from thermal drift, and this host produces
isolated ~0.36 s timedemo outliers that a median alone cannot explain.

Checksum parity is enforced on every run.  A probe that renders a different
framebuffer is a broken probe, not a fast one, so this throws rather than
reporting.

The probe builds itself.  Every probe selector is in the profile suffix and the
build fingerprint, so each variant rebuilds itself on its own - do NOT pass
-SkipBuild, or a probe run can silently measure the control binary.  That was the
single most expensive mistake in this project's history.

.PARAMETER Probe
The probe value, e.g. 'entry', 'newtop', 'prologue'.  Must be a valid value of
-Selector.

.PARAMETER Selector
Which probe selector to drive.  Defaults to EdgeScanProbe; pass RenderFaceProbe
for the C probes.

.PARAMETER Runs
Runs per variant, excluding the trailing control.  Default 3, which is the
project's standard.

.PARAMETER NoTrailingControl
Skip the trailing drift check.  Only for a quick look; never for a recorded
number.

.EXAMPLE
.\tools\probe-ab.ps1 -Probe newtop

.EXAMPLE
.\tools\probe-ab.ps1 -Probe prologue -Selector RenderFaceProbe

.NOTES
PowerShell invocation traps, all of which cost a cycle here and all of which
produce a wrong answer rather than an error:

  1. timedemo-dos.ps1 reports with Write-Host, which writes to the information
     stream (6).  `2>&1` does not capture it; `*>&1` is required.
  2. The build writes compiler warnings to stderr.  Under
     $ErrorActionPreference='Stop' those become terminating errors and truncate
     the captured output before the timedemo line is reached, which then reads
     as a parity failure.  Relax it around the call.
  3. A function that both Write-Outputs progress and returns a value returns
     both.  The [double[]] the caller accumulates gets the progress strings and
     every median breaks.  Use Write-Host for progress.
  4. A quoted parameter name is a literal string, not a parameter:
     "-RenderFaceProbe" binds positionally and lands in -DataRoot.
  5. Array splatting loses the parameter/value pairing, so '1' ends up bound to
     OptimizationProfile.  Hashtable splatting is correct.
#>
param(
    [Parameter(Mandatory = $true)][string]$Probe,
    [int]$Runs = 3,
    [switch]$NoTrailingControl,
    [string]$Selector = 'EdgeScanProbe'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Invoke-Timedemo {
    param([string]$Variant)

    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $tdArgs = @{ NoBootstrap = $true; Runs = 1; NoFpsStats = $true; $Selector = $Variant }
    $out = & "$repo\tools\timedemo-dos.ps1" @tdArgs *>&1 |
        ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { [string]$_ } }
    $ErrorActionPreference = $prev
    $text = $out -join "`n"

    if ($text -notmatch 'framebuffer-checksum\s+1047377823') {
        throw "PARITY FAILURE on '$Variant': checksum is not 1047377823. A probe that renders a different framebuffer is a broken probe, not a fast one. Output tail:`n$(($out | Select-Object -Last 25) -join "`n")"
    }
    $m = [regex]::Match($text, '(\d+)\s+frames\s+([\d.]+)\s+seconds')
    if (-not $m.Success) {
        throw "could not parse the timedemo line for '$Variant'. Output tail:`n$(($out | Select-Object -Last 25) -join "`n")"
    }

    Write-Host ("  {0,-16} {1:F6} s" -f $Variant, [double]$m.Groups[2].Value)
    return [double]$m.Groups[2].Value
}

function Get-Median([double[]]$v) {
    $s = $v | Sort-Object
    if ($s.Count % 2) { return $s[[int](($s.Count - 1) / 2)] }
    return ($s[$s.Count / 2 - 1] + $s[$s.Count / 2]) / 2
}

$control = @()
$probeRuns = @()

Write-Output "=== $Selector=$Probe  ($Runs runs per variant, plus trailing control) ==="
Write-Output "control block:"
for ($i = 0; $i -lt $Runs; $i++) { $control += Invoke-Timedemo 'control' }

Write-Output "probe block ($Probe):"
for ($i = 0; $i -lt $Runs; $i++) { $probeRuns += Invoke-Timedemo $Probe }

$trailing = $null
if (-not $NoTrailingControl) {
    Write-Output "trailing control (drift check):"
    $trailing = Invoke-Timedemo 'control'
}

$cm = Get-Median $control
$pm = Get-Median $probeRuns
$delta = $pm - $cm
$cspread = ($control | Measure-Object -Maximum).Maximum - ($control | Measure-Object -Minimum).Minimum

Write-Output ""
Write-Output "PROBE=$Probe  SELECTOR=$Selector"
Write-Output ("  control : {0}" -f (($control | ForEach-Object { '{0:F6}' -f $_ }) -join ' / '))
Write-Output ("  probe   : {0}" -f (($probeRuns | ForEach-Object { '{0:F6}' -f $_ }) -join ' / '))
Write-Output ("  medians : control {0:F6}  probe {1:F6}" -f $cm, $pm)
Write-Output ("  delta   : {0:+0.000000;-0.000000} s = {1:+0.0000;-0.0000}%" -f $delta, ($delta / $cm * 100))
Write-Output ("  control spread within block : {0:F6} s" -f $cspread)
if ($null -ne $trailing) {
    $drift = $trailing - $cm
    Write-Output ("  trailing control {0:F6}  drift {1:+0.000000;-0.000000} s ({2:+0.0000;-0.0000}%)" -f $trailing, $drift, ($drift / $cm * 100))
}

if ($Runs -lt 2) {
    Write-Output "  delta / spread ratio : n/a (needs 2+ control runs to have a spread)"
    Write-Output ""
    Write-Output "  This was a smoke run. -Runs 1 cannot produce a signal ratio and cannot"
    Write-Output "  support a recorded number. Re-run with -Runs 3 or more."
}
else {
    Write-Output ("  delta / spread ratio : {0:N0}x" -f [math]::Abs($delta / $cspread))
    if ([math]::Abs($delta / $cspread) -lt 100) {
        Write-Output ""
        Write-Output "  WARNING: under 100x the run spread. Treat as inconclusive and check for an"
        Write-Output "  isolated outlier in the block before believing it - this host produces"
        Write-Output "  ~0.36 s outliers and they inflate the reported spread."
    }
}
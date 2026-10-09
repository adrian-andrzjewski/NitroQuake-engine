<#
.SYNOPSIS
    Run reference and assembly renderer profiles on identical deterministic scenes.

.DESCRIPTION
    Executes the deterministic rendering suite once with the C-reference selector
    profile and once with the assembly profile, then compares all captured
    per-frame checksum streams and framebuffers exactly. The source tree is hashed
    around the pair so reports built from different source snapshots cannot pass.
#>
[CmdletBinding()]
param(
    [string]$ReferenceProfile = 'tools/renderer-profiles/i486-c-reference.json',
    [string]$CandidateProfile = 'tools/renderer-profiles/i486-asm-selectable.json',
    [string[]]$Scenario = @(),
    [string]$ScenarioFile,
    [string]$OutputRoot,
    [string]$ToolRoot,
    [string]$DataRoot,
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    [ValidateRange(30, 3600)]
    [int]$TimeoutSeconds = 600,
    [ValidateRange(0, 9)]
    [int]$RunsOverride = 0,
    [switch]$SkipBuild,
    [switch]$VisualParityOnly,
    [switch]$NoBootstrap,
    [switch]$KeepTransientNotifications
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'common.ps1')
if ($VisualParityOnly -and $CpuTarget -ne 'i486') {
    throw '-VisualParityOnly is supported only for the i486 visual comparison path.'
}
if ($VisualParityOnly) {
    Write-Host 'VISUAL PARITY ONLY: renderer ISA status will be reported as SKIPPED; this comparison does not certify 486 compatibility.' -ForegroundColor Yellow
}
$referencePath = if ([IO.Path]::IsPathRooted($ReferenceProfile)) {
    [IO.Path]::GetFullPath($ReferenceProfile)
} else {
    [IO.Path]::GetFullPath((Join-Path $repoRoot $ReferenceProfile))
}
$candidatePath = if ([IO.Path]::IsPathRooted($CandidateProfile)) {
    [IO.Path]::GetFullPath($CandidateProfile)
} else {
    [IO.Path]::GetFullPath((Join-Path $repoRoot $CandidateProfile))
}
foreach ($profilePath in @($referencePath, $candidatePath)) {
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        throw "Renderer selector profile was not found: '$profilePath'."
    }
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
    $OutputRoot = Join-Path $repoRoot (Join-Path 'out' "render-parity-$stamp")
}
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
if (Test-Path -LiteralPath $OutputRoot) {
    throw "Output path already exists; refusing to overwrite '$OutputRoot'."
}
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$referenceOutput = Join-Path $OutputRoot 'reference'
$candidateOutput = Join-Path $OutputRoot 'candidate'
$referenceReport = Join-Path $referenceOutput 'render-validation-result.json'
$candidateReport = Join-Path $candidateOutput 'render-validation-result.json'
$comparisonReport = Join-Path $OutputRoot 'render-parity-result.json'
$diffDirectory = Join-Path $OutputRoot 'framebuffer-diffs'
$sourceScenarioFile = if ([string]::IsNullOrWhiteSpace($ScenarioFile)) {
    Join-Path $PSScriptRoot 'render-scenarios.json'
} elseif ([IO.Path]::IsPathRooted($ScenarioFile)) {
    [IO.Path]::GetFullPath($ScenarioFile)
} else {
    [IO.Path]::GetFullPath((Join-Path $repoRoot $ScenarioFile))
}
$pairScenarioFile = Join-Path $OutputRoot 'render-parity-scenarios.json'
$renderValidationScript = Join-Path $PSScriptRoot 'render-validation-dos.ps1'
$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $pwshCommand) { $pwshCommand = Get-Command powershell }
$validationFailures = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $sourceScenarioFile -PathType Leaf)) {
    throw "Rendering scenario manifest was not found: '$sourceScenarioFile'."
}
$pairScenarioData = Get-Content -LiteralPath $sourceScenarioFile -Raw | ConvertFrom-Json
if ($null -eq $pairScenarioData.PSObject.Properties['validationAutoexecCommands']) {
    $pairScenarioData | Add-Member -NotePropertyName validationAutoexecCommands -NotePropertyValue @()
}
$pairAutoexec = @($pairScenarioData.validationAutoexecCommands)
if (-not $KeepTransientNotifications -and
    -not ($pairAutoexec | Where-Object { $_ -match '^\s*con_notifytime\s+-1(?:\s|$)' })) {
    $pairAutoexec += 'con_notifytime -1'
}
$pairScenarioData.validationAutoexecCommands = $pairAutoexec
$pairScenarioData | ConvertTo-Json -Depth 50 |
    Set-Content -LiteralPath $pairScenarioFile -Encoding utf8
Write-Host "Paired manifest: $pairScenarioFile"
if (-not $KeepTransientNotifications) {
    Write-Host 'Transient console notifications are disabled for deterministic frame comparisons.'
}

$sourceTreeBefore = Get-SourceTreeFingerprint -RepoRoot $repoRoot
foreach ($profile in @(
    [pscustomobject]@{ Label = 'C reference'; Path = $referencePath; Output = $referenceOutput },
    [pscustomobject]@{ Label = 'Assembly candidate'; Path = $candidatePath; Output = $candidateOutput }
)) {
    Write-Host ''
    Write-Host ('=' * 78)
    Write-Host ("  {0}: {1}" -f $profile.Label, $profile.Path)
    Write-Host ('=' * 78)

    $validationArgs = @(
        '-NoProfile', '-File', $renderValidationScript,
        '-RendererSelectorProfile', $profile.Path,
        '-OutputRoot', $profile.Output,
        '-CpuTarget', $CpuTarget,
        '-TimeoutSeconds', [string]$TimeoutSeconds
    )
    $validationArgs += @('-ScenarioFile', $pairScenarioFile)
    if ($Scenario.Count -gt 0) { $validationArgs += @('-Scenario', ($Scenario -join ',')) }
    if ($RunsOverride -gt 0) { $validationArgs += @('-RunsOverride', [string]$RunsOverride) }
    if (-not [string]::IsNullOrWhiteSpace($ToolRoot)) { $validationArgs += @('-ToolRoot', $ToolRoot) }
    if (-not [string]::IsNullOrWhiteSpace($DataRoot)) { $validationArgs += @('-DataRoot', $DataRoot) }
    if ($SkipBuild) { $validationArgs += '-SkipBuild' }
    if ($VisualParityOnly) { $validationArgs += '-VisualParityOnly' }
    if ($NoBootstrap) { $validationArgs += '-NoBootstrap' }
    $validationArgs += '-SkipGoldenImageComparison'

    & $pwshCommand.Source @validationArgs
    if ($LASTEXITCODE -ne 0) {
        $validationFailures.Add("$($profile.Label) render-validation exited with code $LASTEXITCODE")
    }
    if (-not (Test-Path -LiteralPath (Join-Path $profile.Output 'render-validation-result.json') -PathType Leaf)) {
        $validationFailures.Add("$($profile.Label) render-validation did not write its report to '$($profile.Output)'")
    }
}

$sourceTreeAfter = Get-SourceTreeFingerprint -RepoRoot $repoRoot
if ($sourceTreeBefore -ne $sourceTreeAfter) {
    throw "Renderer source tree changed during the paired run ($sourceTreeBefore -> $sourceTreeAfter); parity results are not comparable."
}
if (-not (Test-Path -LiteralPath $referenceReport -PathType Leaf) -or
    -not (Test-Path -LiteralPath $candidateReport -PathType Leaf)) {
    throw "A paired render-validation report is missing. $($validationFailures -join '; ')"
}

$compareScript = Join-Path $PSScriptRoot 'compare-rendering-reports.py'
$compareArgs = @(
    $compareScript,
    $referenceReport,
    $candidateReport,
    '--output-json', $comparisonReport,
    '--diff-dir', $diffDirectory
)
& python @compareArgs
$comparisonExit = $LASTEXITCODE
Write-Host ("Parity report: {0}" -f $comparisonReport)
if (Test-Path -LiteralPath $comparisonReport -PathType Leaf) {
    $comparison = Get-Content -LiteralPath $comparisonReport -Raw | ConvertFrom-Json
    $referenceIsaStatus = if (Test-Path -LiteralPath $referenceReport -PathType Leaf) {
        (Get-Content -LiteralPath $referenceReport -Raw | ConvertFrom-Json).isaAuditStatus
    } else { 'NOT_RUN' }
    $candidateIsaStatus = if (Test-Path -LiteralPath $candidateReport -PathType Leaf) {
        (Get-Content -LiteralPath $candidateReport -Raw | ConvertFrom-Json).isaAuditStatus
    } else { 'NOT_RUN' }
    $comparison | Add-Member -NotePropertyName visualParityOnly -NotePropertyValue ([bool]$VisualParityOnly) -Force
    $comparison | Add-Member -NotePropertyName isaAuditStatus -NotePropertyValue $(if ($VisualParityOnly) { 'SKIPPED' } elseif ($referenceIsaStatus -eq 'PASS' -and $candidateIsaStatus -eq 'PASS') { 'PASS' } else { 'NOT_ASSERTED' }) -Force
    $comparison | Add-Member -NotePropertyName buildIsaAuditStatuses -NotePropertyValue ([ordered]@{
        reference = $referenceIsaStatus
        candidate = $candidateIsaStatus
    }) -Force
    $comparison | Add-Member -NotePropertyName isaEvidenceScope -NotePropertyValue $(if ($VisualParityOnly) {
        'Framebuffer comparison only; renderer ISA compatibility was not asserted by this run.'
    } else {
        'Each build manifest was checked by the normal renderer compatibility gate.'
    }) -Force
    $comparison | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $comparisonReport -Encoding UTF8
}
if ($validationFailures.Count -gt 0 -or $comparisonExit -ne 0) {
    $reasons = @($validationFailures.ToArray())
    if ($comparisonExit -ne 0) { $reasons += "exact C-reference / assembly comparison exited with code $comparisonExit" }
    throw ($reasons -join '; ')
}
exit 0

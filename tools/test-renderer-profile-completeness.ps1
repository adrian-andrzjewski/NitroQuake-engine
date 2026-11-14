[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$selectorTablePath = Join-Path $PSScriptRoot 'selectors.ps1'
$profilePath = Join-Path $PSScriptRoot 'renderer-profiles\i486-asm-selectable-current.json'

. $selectorTablePath

if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "Cumulative assembly profile was not found: '$profilePath'."
}

$candidateProfile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
if ([int]$candidateProfile.schemaVersion -ne 1) {
    throw "Unsupported cumulative assembly profile schema '$($candidateProfile.schemaVersion)'."
}
if ([string]$candidateProfile.id -cne 'i486-asm-selectable-current') {
    throw "Unexpected cumulative assembly profile id '$($candidateProfile.id)'."
}

$selectorsProperty = $candidateProfile.PSObject.Properties['selectors']
if ($null -eq $selectorsProperty -or $null -eq $selectorsProperty.Value) {
    throw 'Cumulative assembly profile must define a selectors object.'
}

$requiredEntries = @($script:SelectorTable | Where-Object { $_.SelectsAsm -eq $true })
$requiredNames = @($requiredEntries | ForEach-Object { [string]$_.Param })
$duplicateNames = @($requiredNames | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicateNames.Count -gt 0) {
    throw 'Selector table has duplicate assembly selectors: ' + ($duplicateNames -join ', ')
}

$selectorByName = @{}
foreach ($selector in $script:SelectorTable) {
    $selectorByName[[string]$selector.Param] = $selector
}
$actualProperties = @($selectorsProperty.Value.PSObject.Properties)
$actualNames = @($actualProperties | ForEach-Object { [string]$_.Name })
$missing = @($requiredNames | Where-Object { $_ -notin $actualNames })
$unknown = @($actualNames | Where-Object { -not $selectorByName.ContainsKey($_) })
# The accepted release profile is selective: a measured C path or a faster
# retained legacy implementation is valid even when the selector can choose
# assembly. Completeness means the release profile records a known value for
# every assembly-capable selector, not that every entry selects assembly.
$invalidValues = @($actualProperties | Where-Object {
        if (-not $selectorByName.ContainsKey([string]$_.Name)) { return $false }
        $selector = $selectorByName[[string]$_.Name]
        $knownValues = @($selector.Suffix.Keys) + @($selector.C.Keys) + @($selector.Asm.Keys)
        [string]$_.Value -notin $knownValues -and -not (
            [string]$_.Name -ceq 'BspWalkImplementation' -and
            [string]$_.Value -ceq 'c'
        )
    } | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value })

if ($missing.Count -gt 0 -or $unknown.Count -gt 0 -or $invalidValues.Count -gt 0) {
    $details = @()
    if ($missing.Count -gt 0) { $details += 'missing SelectsAsm selectors: ' + ($missing -join ', ') }
    if ($unknown.Count -gt 0) { $details += 'unknown selectors: ' + ($unknown -join ', ') }
    if ($invalidValues.Count -gt 0) { $details += 'invalid selector values: ' + ($invalidValues -join ', ') }
    throw 'The i486 release profile is incomplete: ' + ($details -join '; ')
}

Write-Host ("PASS: {0} assembly-capable selectors have explicit, valid i486 release values; no assembly-entry quota is enforced." -f $requiredNames.Count) -ForegroundColor Green

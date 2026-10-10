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

$actualProperties = @($selectorsProperty.Value.PSObject.Properties)
$actualNames = @($actualProperties | ForEach-Object { [string]$_.Name })
$missing = @($requiredNames | Where-Object { $_ -notin $actualNames })
$extra = @($actualNames | Where-Object { $_ -notin $requiredNames })
$nonAssemblyValues = @($actualProperties | Where-Object { [string]$_.Value -cne 'asm' } |
    ForEach-Object { '{0}={1}' -f $_.Name, $_.Value })

if ($missing.Count -gt 0 -or $extra.Count -gt 0 -or $nonAssemblyValues.Count -gt 0) {
    $details = @()
    if ($missing.Count -gt 0) { $details += 'missing SelectsAsm selectors: ' + ($missing -join ', ') }
    if ($extra.Count -gt 0) { $details += 'extra selectors: ' + ($extra -join ', ') }
    if ($nonAssemblyValues.Count -gt 0) { $details += 'selectors not set to asm: ' + ($nonAssemblyValues -join ', ') }
    throw 'Cumulative assembly profile is incomplete: ' + ($details -join '; ')
}

Write-Host ("PASS: {0} current SelectsAsm selectors are present exactly once and set to asm." -f $requiredNames.Count) -ForegroundColor Green

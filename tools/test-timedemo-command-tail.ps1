$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$exactLimit = 'X' * 126
$actualBytes = Assert-DosPspCommandTail -CommandTail $exactLimit
if ($actualBytes -ne 126) {
    throw "A 126-byte DOS PSP command tail returned $actualBytes bytes."
}

$tailWithExecutableSeparator = Assert-DosPspCommandTail -CommandTail (' ' + ('X' * 125))
if ($tailWithExecutableSeparator -ne 126) {
    throw "The leading executable separator was not counted in the PSP tail ($tailWithExecutableSeparator bytes)."
}

$overLimitRejected = $false
try {
    [void](Assert-DosPspCommandTail -CommandTail ('X' * 127))
}
catch {
    $overLimitRejected = $_.Exception.Message -match '127 ASCII bytes; the PSP limit is 126'
}
if (-not $overLimitRejected) {
    throw 'A 127-byte DOS PSP command tail was not rejected with its measured size and limit.'
}

$timedemoSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'timedemo-dos.ps1') -Raw
$preflightIndex = $timedemoSource.IndexOf(
    "Assert-DosPspCommandTail -CommandTail (' ' + `$quakeCommandTail)",
    [StringComparison]::Ordinal)
$dosboxStartIndex = $timedemoSource.IndexOf(
    'Invoke-DosboxProcess -Dosbox $dosbox',
    [StringComparison]::Ordinal)
if ($preflightIndex -lt 0 -or $dosboxStartIndex -lt 0 -or $preflightIndex -ge $dosboxStartIndex) {
    throw 'The DOS PSP command-tail check must run before the timedemo runner starts DOSBox.'
}

Write-Output 'Timedemo DOS PSP command-tail preflight tests passed.'

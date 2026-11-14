<#
.SYNOPSIS
    Build one of the supported NitroQuake DOS configurations.

.DESCRIPTION
    This is the shipping build interface. It intentionally accepts named
    configurations only; per-routine selector changes, experimental schedules,
    and dead-scratch probes belong to the benchmark suite and its internal
    build-dos-experimental.ps1 backend.
#>
[CmdletBinding()]
param(
    [ValidateSet('i486-release', 'c-reference')]
    [string]$Configuration = 'i486-release',
    [ValidateSet('i486', 'i386')]
    [string]$CpuTarget = 'i486',
    [switch]$Clean,
    [switch]$NoBootstrap,
    [switch]$DumpFlags,
    [switch]$SkipIsaAudit,
    [switch]$RecordIsaBaseline,
    [string]$ToolRoot,
    [string]$DiagnosticOutputRoot,
    [string]$LocalOutputDirectoryName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Configuration -eq 'i486-release' -and $CpuTarget -ne 'i486') {
    throw "The i486-release configuration requires -CpuTarget i486; use -Configuration c-reference for the i386 reference build."
}

$profileName = if ($Configuration -eq 'i486-release') {
    'i486-asm-selectable-current.json'
} else {
    'i486-c-reference.json'
}
$profilePath = Join-Path $PSScriptRoot ('renderer-profiles\' + $profileName)
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
    throw "The supported '$Configuration' configuration file is missing: '$profilePath'."
}

$profile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
$expectedProfileId = if ($Configuration -eq 'i486-release') {
    'i486-asm-selectable-current'
} else {
    'i486-c-reference'
}
if ([int]$profile.schemaVersion -ne 1 -or $profile.id -cne $expectedProfileId) {
    throw "The '$Configuration' configuration has an unsupported schema or id."
}
$selectorsProperty = $profile.PSObject.Properties['selectors']
if ($null -eq $selectorsProperty -or $null -eq $selectorsProperty.Value) {
    throw "The '$Configuration' configuration has no selectors object."
}

$buildArguments = @{
    CpuTarget = $CpuTarget
    OptimizationProfile = 'aggressive'
    TextureAxisCacheEntries = 256
}
foreach ($property in $selectorsProperty.Value.PSObject.Properties) {
    $buildArguments[$property.Name] = [string]$property.Value
}
foreach ($name in @('Clean', 'NoBootstrap', 'DumpFlags', 'SkipIsaAudit', 'RecordIsaBaseline')) {
    if ((Get-Variable -Name $name -ValueOnly)) {
        $buildArguments[$name] = $true
    }
}
foreach ($name in @('ToolRoot', 'DiagnosticOutputRoot', 'LocalOutputDirectoryName')) {
    $value = Get-Variable -Name $name -ValueOnly
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $buildArguments[$name] = $value
    }
}

$experimentalBuilder = Join-Path $PSScriptRoot 'build-dos-experimental.ps1'
if (-not (Test-Path -LiteralPath $experimentalBuilder -PathType Leaf)) {
    throw "The internal build backend is missing: '$experimentalBuilder'."
}
& $experimentalBuilder @buildArguments

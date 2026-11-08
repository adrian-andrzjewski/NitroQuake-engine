# Identity is derived from recorded optimization attempts, never mutable state.
function Get-NitroQuakeOptimizationInventory {
    param([Parameter(Mandatory)][string]$RepoRoot,
          [string]$OutputPath)
    $arguments = @((Join-Path $PSScriptRoot 'optimization-history.py'), '--repo-root', $RepoRoot)
    if ($OutputPath) { $arguments += @('--output', $OutputPath) }
    $result = & python @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Cannot derive NitroQuake build identity from optimization history.' }
    return ($result | ConvertFrom-Json)
}

function New-NitroQuakeBuildIdentity {
    param([Parameter(Mandatory)][string]$RepoRoot,
          [Parameter(Mandatory)][string]$HeaderPath)
    $inventoryPath = Join-Path (Split-Path -Parent $HeaderPath) 'optimization-inventory.json'
    $inventory = Get-NitroQuakeOptimizationInventory -RepoRoot $RepoRoot -OutputPath $inventoryPath
    $number = $inventory.buildNumber
    $header = "/* Generated from optimization history; do not edit. */`n#define NITROQUAKE_BUILD_NUMBER $number`n"
    [IO.File]::WriteAllText($HeaderPath, $header, [Text.Encoding]::ASCII)
    return [pscustomobject]@{
        number = $number
        version = 'NitroQuake v0.999'
        build = "Build $number"
        inventory = $inventory
    }
}

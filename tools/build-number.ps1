# Product identity covers the source revision, resolved inputs, and classified
# optimization inventory; the numeric count is also embedded in the console.
function Get-NitroQuakeSourceRevision {
    param([Parameter(Mandatory)][string]$RepoRoot)

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($null -eq $git) { $git = Get-Command git -ErrorAction SilentlyContinue }
    if ($null -eq $git) { throw 'Build identity requires Git and a checkout with a HEAD revision.' }

    $revision = (& $git.Source -C $RepoRoot rev-parse --verify HEAD 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $revision -notmatch '^[0-9a-fA-F]{40,64}$') {
        throw 'Build identity requires Git and a checkout with a HEAD revision.'
    }
    return $revision.ToLowerInvariant()
}

function Get-NitroQuakeOptimizationInventory {
    param([Parameter(Mandatory)][string]$RepoRoot,
          [string]$OutputPath)
    $arguments = @((Join-Path $PSScriptRoot 'optimization-history.py'), '--repo-root', $RepoRoot)
    if ($OutputPath) { $arguments += @('--output', $OutputPath) }
    $result = & python @arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ('Optimization history is unavailable: ' + (($result | Out-String).Trim()))
    }
    return ($result | ConvertFrom-Json)
}

function Get-NitroQuakeOptimizationProvenance {
    param([Parameter(Mandatory)][string]$RepoRoot,
          [string]$OutputPath)

    try {
        $inventory = Get-NitroQuakeOptimizationInventory -RepoRoot $RepoRoot -OutputPath $OutputPath
        $inventory | Add-Member -NotePropertyName status -NotePropertyValue 'complete' -Force
        $inventory | Add-Member -NotePropertyName complete -NotePropertyValue $true -Force
        return $inventory
    }
    catch {
        $reason = if ($_.Exception.Message -match 'complete Git history|shallow') {
            'incomplete-history'
        }
        else {
            'inventory-unavailable'
        }
        Write-Warning "Optimization attempt provenance is unavailable ($reason); numeric build numbering cannot continue."
        $unavailable = [ordered]@{
            schemaVersion = 1
            status = 'unavailable'
            complete = $false
            reason = $reason
            buildNumber = $null
            accepted = $null
            rejected = $null
            inventorySha256 = $null
            gitRevision = $null
        }
        if ($OutputPath) {
            [IO.File]::WriteAllText($OutputPath,
                (($unavailable | ConvertTo-Json -Depth 8) + "`n"),
                [Text.Encoding]::ASCII)
        }
        return [pscustomobject]$unavailable
    }
}

function New-NitroQuakeBuildIdentity {
    param([Parameter(Mandatory)][string]$RepoRoot,
          [Parameter(Mandatory)][string]$HeaderPath,
          [Parameter(Mandatory)]$Resolved)

    $inventoryPath = Join-Path (Split-Path -Parent $HeaderPath) 'optimization-inventory.json'
    $inventory = Get-NitroQuakeOptimizationProvenance -RepoRoot $RepoRoot -OutputPath $inventoryPath
    if ($inventory.status -ne 'complete' -or $null -eq $inventory.buildNumber -or
            $inventory.buildNumber -ne ($inventory.accepted + $inventory.rejected) -or
            $inventory.inventorySha256 -notmatch '^[0-9a-f]{64}$') {
        throw 'A complete optimization-attempt history is required to generate the numeric build number. Fetch the full Git history and classify every optimization report.'
    }

    $sourceRevision = Get-NitroQuakeSourceRevision -RepoRoot $RepoRoot
    $fingerprint = Get-BuildFingerprint -RepoRoot $RepoRoot -Resolved $Resolved `
        -SourceRevision $sourceRevision -OptimizationInventorySha256 $inventory.inventorySha256
    $sourceTreeSha256 = Get-SourceTreeFingerprint -RepoRoot $RepoRoot
    $id = $sourceRevision.Substring(0, 12) + '-' + $fingerprint.Substring(0, 12).ToLowerInvariant()

    $headerLines = @(
        '/* Generated from the source revision and resolved build inputs. */',
        ('#define NITROQUAKE_BUILD_ID "' + $id + '"')
    )
    if ($null -ne $inventory.buildNumber) {
        $headerLines += ('#define NITROQUAKE_BUILD_NUMBER ' + $inventory.buildNumber)
    }
    [IO.File]::WriteAllText($HeaderPath, (($headerLines -join "`n") + "`n"), [Text.Encoding]::ASCII)

    return [pscustomobject]@{
        number = $inventory.buildNumber
        id = $id
        fingerprintSha256 = $fingerprint
        sourceRevision = $sourceRevision
        sourceTreeSha256 = $sourceTreeSha256
        version = 'NitroQuake v0.999'
        build = "Build $($inventory.buildNumber)"
        inventory = $inventory
    }
}

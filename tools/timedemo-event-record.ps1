function Read-Bench486BlobExplosionEvents {
    param([Parameter(Mandatory = $true)][string]$Report)

    $eventLines = [regex]::Matches($Report, '(?m)^blob-explosion-events\b.*$')
    if ($eventLines.Count -gt 1) {
        throw 'Timedemo report contains more than one blob-explosion-events record.'
    }
    if ($eventLines.Count -eq 0) {
        return [pscustomobject]@{
            Count = $null
            Frames = $null
            Overflow = $null
        }
    }

    $eventMatch = [regex]::Match(
        $eventLines[0].Value,
        '^blob-explosion-events\s+(?<count>\d+)\s+frames(?<frameTokens>(?:\s+\d+)*)\s+overflow\s+(?<overflow>\d+)\s*$')
    if (-not $eventMatch.Success) {
        throw 'Timedemo report contains a malformed blob-explosion-events record.'
    }

    $frames = New-Object 'System.Collections.Generic.List[int]'
    $frameTokenText = $eventMatch.Groups['frameTokens'].Value.Trim()
    if ($frameTokenText.Length -gt 0) {
        foreach ($frameToken in ($frameTokenText -split '\s+')) {
            $frames.Add([int]$frameToken)
        }
    }
    $count = [int]$eventMatch.Groups['count'].Value
    $overflow = [int]$eventMatch.Groups['overflow'].Value
    if ($count -ne ($frames.Count + $overflow)) {
        throw "Timedemo report declares $count blob explosion event(s) but lists $($frames.Count) frame index/indices with overflow $overflow."
    }

    return [pscustomobject]@{
        Count = $count
        Frames = $frames
        Overflow = $overflow
    }
}

function Read-Bench486LavaSplashEvents {
    param([Parameter(Mandatory = $true)][string]$Report)

    $eventLines = [regex]::Matches($Report, '(?m)^lava-splash-events\b.*$')
    if ($eventLines.Count -gt 1) {
        throw 'Timedemo report contains more than one lava-splash-events record.'
    }
    if ($eventLines.Count -eq 0) {
        return [pscustomobject]@{
            Count = $null
            Frames = $null
            Overflow = $null
        }
    }

    $eventMatch = [regex]::Match(
        $eventLines[0].Value,
        '^lava-splash-events\s+(?<count>\d+)\s+frames(?<frameTokens>(?:\s+\d+)*)\s+overflow\s+(?<overflow>\d+)\s*$')
    if (-not $eventMatch.Success) {
        throw 'Timedemo report contains a malformed lava-splash-events record.'
    }

    $frames = New-Object 'System.Collections.Generic.List[int]'
    $frameTokenText = $eventMatch.Groups['frameTokens'].Value.Trim()
    if ($frameTokenText.Length -gt 0) {
        foreach ($frameToken in ($frameTokenText -split '\s+')) {
            $frames.Add([int]$frameToken)
        }
    }
    $count = [int]$eventMatch.Groups['count'].Value
    $overflow = [int]$eventMatch.Groups['overflow'].Value
    if ($count -ne ($frames.Count + $overflow)) {
        throw "Timedemo report declares $count lava splash event(s) but lists $($frames.Count) frame index/indices with overflow $overflow."
    }

    return [pscustomobject]@{
        Count = $count
        Frames = $frames
        Overflow = $overflow
    }
}

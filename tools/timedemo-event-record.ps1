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

function Read-Bench486TeleportSplashEvents {
    param([Parameter(Mandatory = $true)][string]$Report)

    $eventLines = [regex]::Matches($Report, '(?m)^teleport-splash-events\b.*$')
    if ($eventLines.Count -gt 1) {
        throw 'Timedemo report contains more than one teleport-splash-events record.'
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
        '^teleport-splash-events\s+(?<count>\d+)\s+frames(?<frameTokens>(?:\s+\d+)*)\s+overflow\s+(?<overflow>\d+)\s*$')
    if (-not $eventMatch.Success) {
        throw 'Timedemo report contains a malformed teleport-splash-events record.'
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
        throw "Timedemo report declares $count teleport splash event(s) but lists $($frames.Count) frame index/indices with overflow $overflow."
    }

    return [pscustomobject]@{
        Count = $count
        Frames = $frames
        Overflow = $overflow
    }
}

function Read-Bench486RunParticleEffectEvents {
    param([Parameter(Mandatory = $true)][string]$Report)

    $eventLines = [regex]::Matches($Report, '(?m)^run-particle-effect-events\b.*$')
    if ($eventLines.Count -gt 1) {
        throw 'Timedemo report contains more than one run-particle-effect-events record.'
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
        '^run-particle-effect-events\s+(?<count>\d+)\s+frames(?<frameTokens>(?:\s+\d+)*)\s+overflow\s+(?<overflow>\d+)\s*$')
    if (-not $eventMatch.Success) {
        throw 'Timedemo report contains a malformed run-particle-effect-events record.'
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
        throw "Timedemo report declares $count run-particle-effect event(s) but lists $($frames.Count) frame index/indices with overflow $overflow."
    }

    return [pscustomobject]@{
        Count = $count
        Frames = $frames
        Overflow = $overflow
    }
}

function Read-Bench486EntityParticlesEvents {
    param([Parameter(Mandatory = $true)][string]$Report)

    $eventLines = [regex]::Matches($Report, '(?m)^entity-particles-events\b.*$')
    if ($eventLines.Count -gt 1) {
        throw 'Timedemo report contains more than one entity-particles-events record.'
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
        '^entity-particles-events\s+(?<count>\d+)\s+frames(?<frameTokens>(?:\s+\d+)*)\s+overflow\s+(?<overflow>\d+)\s*$')
    if (-not $eventMatch.Success) {
        throw 'Timedemo report contains a malformed entity-particles-events record.'
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
        throw "Timedemo report declares $count entity-particles event(s) but lists $($frames.Count) frame index/indices with overflow $overflow."
    }

    return [pscustomobject]@{
        Count = $count
        Frames = $frames
        Overflow = $overflow
    }
}

function Read-Bench486SvcDamageEvents {
    param([Parameter(Mandatory = $true)][string]$Report)

    $eventLines = [regex]::Matches($Report, '(?m)^svc-damage-events\b.*$')
    if ($eventLines.Count -gt 1) {
        throw 'Timedemo report contains more than one svc-damage-events record.'
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
        '^svc-damage-events\s+(?<count>\d+)\s+frames(?<frameTokens>(?:\s+\d+)*)\s+overflow\s+(?<overflow>\d+)\s*$')
    if (-not $eventMatch.Success) {
        throw 'Timedemo report contains a malformed svc-damage-events record.'
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
        throw "Timedemo report declares $count svc_damage event(s) but lists $($frames.Count) frame index/indices with overflow $overflow."
    }

    return [pscustomobject]@{
        Count = $count
        Frames = $frames
        Overflow = $overflow
    }
}

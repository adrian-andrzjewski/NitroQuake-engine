$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'timedemo-event-record.ps1')

$storedFrames = (0..31) -join ' '
$overflowReport = "blob-explosion-events 34 frames $storedFrames overflow 2`n"
$overflow = Read-Bench486BlobExplosionEvents -Report $overflowReport
if ($overflow.Count -ne 34 -or $overflow.Frames.Count -ne 32 -or $overflow.Overflow -ne 2) {
    throw 'Overflow event record did not preserve the total, stored frame list, and overflow count.'
}

$empty = Read-Bench486BlobExplosionEvents -Report "blob-explosion-events 0 frames overflow 0`n"
if ($empty.Count -ne 0 -or $empty.Frames.Count -ne 0 -or $empty.Overflow -ne 0) {
    throw 'Explicit zero-event record was not distinguished as an empty event list.'
}

$oldBinary = Read-Bench486BlobExplosionEvents -Report "320 frames 1.0 seconds 320.0 fps`n"
if ($null -ne $oldBinary.Count -or $null -ne $oldBinary.Frames -or $null -ne $oldBinary.Overflow) {
    throw 'A legacy report without the event record should return null event metadata.'
}

$rejectedMismatch = $false
try {
    [void](Read-Bench486BlobExplosionEvents -Report "blob-explosion-events 34 frames 0 1 overflow 2`n")
}
catch {
    $rejectedMismatch = $true
}
if (-not $rejectedMismatch) {
    throw 'Event parser accepted a total count inconsistent with stored frames plus overflow.'
}

Write-Output 'Timedemo event-record parser tests passed.'

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

$lava = Read-Bench486LavaSplashEvents -Report "lava-splash-events 1 frames 10 overflow 0`n"
if ($lava.Count -ne 1 -or $lava.Frames.Count -ne 1 -or $lava.Frames[0] -ne 10 -or $lava.Overflow -ne 0) {
    throw 'LavaSplash event record did not preserve the count, exact frame index, and overflow count.'
}

$lavaMissing = Read-Bench486LavaSplashEvents -Report "320 frames 1.0 seconds 320.0 fps`n"
if ($null -ne $lavaMissing.Count -or $null -ne $lavaMissing.Frames -or $null -ne $lavaMissing.Overflow) {
    throw 'A legacy report without the LavaSplash event record should return null event metadata.'
}

$lavaMismatchRejected = $false
try {
    [void](Read-Bench486LavaSplashEvents -Report "lava-splash-events 2 frames 9 overflow 0`n")
}
catch {
    $lavaMismatchRejected = $true
}
if (-not $lavaMismatchRejected) {
    throw 'LavaSplash event parser accepted a count inconsistent with its stored frames and overflow.'
}

$teleport = Read-Bench486TeleportSplashEvents -Report "teleport-splash-events 1 frames 10 overflow 0`n"
if ($teleport.Count -ne 1 -or $teleport.Frames.Count -ne 1 -or
    $teleport.Frames[0] -ne 10 -or $teleport.Overflow -ne 0) {
    throw 'TeleportSplash event record did not preserve the count, exact frame index, and overflow count.'
}

$teleportEmpty = Read-Bench486TeleportSplashEvents -Report "teleport-splash-events 0 frames overflow 0`n"
if ($teleportEmpty.Count -ne 0 -or $teleportEmpty.Frames.Count -ne 0 -or
    $teleportEmpty.Overflow -ne 0) {
    throw 'Explicit zero-event TeleportSplash record was not distinguished as an empty event list.'
}

$teleportMissing = Read-Bench486TeleportSplashEvents -Report "320 frames 1.0 seconds 320.0 fps`n"
if ($null -ne $teleportMissing.Count -or $null -ne $teleportMissing.Frames -or
    $null -ne $teleportMissing.Overflow) {
    throw 'A legacy report without the TeleportSplash event record should return null event metadata.'
}

$teleportMismatchRejected = $false
try {
    [void](Read-Bench486TeleportSplashEvents -Report "teleport-splash-events 2 frames 10 overflow 0`n")
}
catch {
    $teleportMismatchRejected = $true
}
if (-not $teleportMismatchRejected) {
    throw 'TeleportSplash event parser accepted a count inconsistent with its stored frames and overflow.'
}

$runParticleEffect = Read-Bench486RunParticleEffectEvents -Report "run-particle-effect-events 1 frames 10 overflow 0`n"
if ($runParticleEffect.Count -ne 1 -or $runParticleEffect.Frames.Count -ne 1 -or
    $runParticleEffect.Frames[0] -ne 10 -or $runParticleEffect.Overflow -ne 0) {
    throw 'R_RunParticleEffect event record did not preserve the count, exact frame index, and overflow count.'
}

$runParticleEffectEmpty = Read-Bench486RunParticleEffectEvents -Report "run-particle-effect-events 0 frames overflow 0`n"
if ($runParticleEffectEmpty.Count -ne 0 -or $runParticleEffectEmpty.Frames.Count -ne 0 -or
    $runParticleEffectEmpty.Overflow -ne 0) {
    throw 'Explicit zero-event R_RunParticleEffect record was not distinguished as an empty event list.'
}

$runParticleEffectMissing = Read-Bench486RunParticleEffectEvents -Report "320 frames 1.0 seconds 320.0 fps`n"
if ($null -ne $runParticleEffectMissing.Count -or $null -ne $runParticleEffectMissing.Frames -or
    $null -ne $runParticleEffectMissing.Overflow) {
    throw 'A legacy report without the R_RunParticleEffect event record should return null event metadata.'
}

$runParticleEffectMismatchRejected = $false
try {
    [void](Read-Bench486RunParticleEffectEvents -Report "run-particle-effect-events 2 frames 10 overflow 0`n")
}
catch {
    $runParticleEffectMismatchRejected = $true
}
if (-not $runParticleEffectMismatchRejected) {
    throw 'R_RunParticleEffect event parser accepted a count inconsistent with its stored frames and overflow.'
}

$entityParticles = Read-Bench486EntityParticlesEvents -Report "entity-particles-events 1 frames 10 overflow 0`n"
if ($entityParticles.Count -ne 1 -or $entityParticles.Frames.Count -ne 1 -or
    $entityParticles.Frames[0] -ne 10 -or $entityParticles.Overflow -ne 0) {
    throw 'R_EntityParticles event record did not preserve the count, exact frame index, and overflow count.'
}

$entityParticlesEmpty = Read-Bench486EntityParticlesEvents -Report "entity-particles-events 0 frames overflow 0`n"
if ($entityParticlesEmpty.Count -ne 0 -or $entityParticlesEmpty.Frames.Count -ne 0 -or
    $entityParticlesEmpty.Overflow -ne 0) {
    throw 'Explicit zero-event R_EntityParticles record was not distinguished as an empty event list.'
}

$entityParticlesMissing = Read-Bench486EntityParticlesEvents -Report "320 frames 1.0 seconds 320.0 fps`n"
if ($null -ne $entityParticlesMissing.Count -or $null -ne $entityParticlesMissing.Frames -or
    $null -ne $entityParticlesMissing.Overflow) {
    throw 'A legacy report without the R_EntityParticles event record should return null event metadata.'
}

$entityParticlesMismatchRejected = $false
try {
    [void](Read-Bench486EntityParticlesEvents -Report "entity-particles-events 2 frames 10 overflow 0`n")
}
catch {
    $entityParticlesMismatchRejected = $true
}
if (-not $entityParticlesMismatchRejected) {
    throw 'R_EntityParticles event parser accepted a count inconsistent with its stored frames and overflow.'
}

Write-Output 'Timedemo event-record parser tests passed.'

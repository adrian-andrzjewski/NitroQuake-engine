$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'bench-event-repeat.ps1')

$matching = Compare-Bench486EventRepeat `
    -ReferenceFramesPresent $true -ReferenceFramesSignature '4,9,9' `
    -ReferenceOverflowPresent $true -ReferenceOverflow 0 `
    -CandidateFramesPresent $true -CandidateFramesSignature '4,9,9' `
    -CandidateOverflowPresent $true -CandidateOverflow 0
if (-not $matching.exactMatch) {
    throw 'Matching event frame arrays and overflow counts should pass repeat parity.'
}

$frameMismatch = Compare-Bench486EventRepeat `
    -ReferenceFramesPresent $true -ReferenceFramesSignature '4,9,9' `
    -ReferenceOverflowPresent $true -ReferenceOverflow 0 `
    -CandidateFramesPresent $true -CandidateFramesSignature '4,9' `
    -CandidateOverflowPresent $true -CandidateOverflow 0
if ($frameMismatch.framesMatch -or $frameMismatch.exactMatch) {
    throw 'A changed event frame array should fail repeat parity.'
}

$overflowMismatch = Compare-Bench486EventRepeat `
    -ReferenceFramesPresent $true -ReferenceFramesSignature '4,9' `
    -ReferenceOverflowPresent $true -ReferenceOverflow 0 `
    -CandidateFramesPresent $true -CandidateFramesSignature '4,9' `
    -CandidateOverflowPresent $true -CandidateOverflow 1
if ($overflowMismatch.overflowMatch -or $overflowMismatch.exactMatch) {
    throw 'A changed event overflow count should fail repeat parity.'
}

$missingMetadata = Compare-Bench486EventRepeat `
    -ReferenceFramesPresent $false -ReferenceFramesSignature $null `
    -ReferenceOverflowPresent $false -ReferenceOverflow $null `
    -CandidateFramesPresent $true -CandidateFramesSignature '4' `
    -CandidateOverflowPresent $true -CandidateOverflow 0
if ($missingMetadata.exactMatch) {
    throw 'A run with missing event metadata should not match a run with event metadata.'
}

Write-Output 'Timedemo event-repeat parity tests passed.'

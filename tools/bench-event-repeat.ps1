function Compare-Bench486EventRepeat {
    param(
        [Parameter(Mandatory = $true)][bool]$ReferenceFramesPresent,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$ReferenceFramesSignature,
        [Parameter(Mandatory = $true)][bool]$ReferenceOverflowPresent,
        [Parameter(Mandatory = $true)][AllowNull()][object]$ReferenceOverflow,
        [Parameter(Mandatory = $true)][bool]$CandidateFramesPresent,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$CandidateFramesSignature,
        [Parameter(Mandatory = $true)][bool]$CandidateOverflowPresent,
        [Parameter(Mandatory = $true)][AllowNull()][object]$CandidateOverflow
    )

    $framesMatch = $ReferenceFramesPresent -eq $CandidateFramesPresent
    if ($framesMatch -and $ReferenceFramesPresent) {
        $framesMatch = $ReferenceFramesSignature -ceq $CandidateFramesSignature
    }

    $overflowMatch = $ReferenceOverflowPresent -eq $CandidateOverflowPresent
    if ($overflowMatch -and $ReferenceOverflowPresent) {
        $overflowMatch = $ReferenceOverflow -eq $CandidateOverflow
    }

    return [pscustomobject]@{
        framesMatch = $framesMatch
        overflowMatch = $overflowMatch
        exactMatch = $framesMatch -and $overflowMatch
    }
}

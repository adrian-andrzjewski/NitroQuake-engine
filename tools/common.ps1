<#
.SYNOPSIS
    Shared helpers for the DOS runners under tools\.

.DESCRIPTION
    smoke-dos.ps1, coverage-dos.ps1, bench-dos.ps1 and timedemo-dos.ps1 each stage
    a build into DOSBox-X and each need to know whether the executable they are
    about to run still matches the tree.  That knowledge was duplicated four ways
    and was wrong in two of them: bench-dos.ps1 and timedemo-dos.ps1 fingerprinted
    their inputs, while smoke-dos.ps1 and coverage-dos.ps1 only asked whether the
    file existed, so they would run a stale binary indefinitely.  This is where the
    rule lives now.

    Dot-sourced, not a module.  Every runner is launched with `pwsh -File`, and a
    .psm1 would add an import step plus module-scope parameter passing to four
    scripts that already work when invoked directly.

.NOTES
    Add a helper here when two or more runners need it and the rule is one rule.
    A helper that only one caller uses belongs in that caller.
#>

Set-StrictMode -Version Latest

function Get-BuildFingerprint {
    <#
    .SYNOPSIS
        Hash everything that determines a build: the sources and the configuration.

    .DESCRIPTION
        A build is identified by more than its configuration.  Editing a .c or a
        header changes the executable without changing any flag, so the digest
        covers every source file under src\ as well.

        The configuration half is taken from the builder's own resolved output --
        the profile suffix and both flag lists.  That is deliberate, and it is the
        reason this function takes flags rather than a selector table:

          * it is already complete.  Every selector's effect is visible in the
            suffix token or in a -D define, so this covers all forty of them
            without any runner having to declare them.
          * it is already the thing the project pins.  tools\golden\build-flags-*.json
            compares exactly these fields, so the fingerprint cannot say a build is
            fresh for a configuration the golden would reject.
          * it needs no agreed order.  The two runners that build -Benchmark into
            the same directory each used to spell out the same forty selectors by
            hand, and the two lists had drifted in order (TurbulentImplementation
            and MemoryImplementation are transposed).  Deriving the identity from
            resolved output removes the question.

    .PARAMETER RepoRoot
        Repository root.  src\ under it is the hashed source tree.

    .PARAMETER Resolved
        The resolved configuration, i.e. the object build-dos.ps1 -DumpFlags emits.
        Both halves of the digest come from here, so the builder and the runners
        cannot disagree about what a configuration is.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)]$Resolved
    )

    $sourceRoot = Join-Path $repoRoot 'src'
    $inputs = @(
        Get-ChildItem -LiteralPath $sourceRoot -Include '*.c', '*.s', '*.h' -File -Recurse |
            Sort-Object FullName |
            ForEach-Object {
                "$($_.FullName.Substring($sourceRoot.Length))=$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
            }
    )
    # Each on its own line so no combination of values can be re-partitioned into
    # the same text as a different combination.
    $inputs += "outputRoot=$($Resolved.outputRoot)"
    $inputs += "profileSuffix=$($Resolved.profileSuffix)"
    $inputs += "cFlags=$(@($Resolved.cFlags) -join ' ')"
    $inputs += "asmFlags=$(@($Resolved.asmFlags) -join ' ')"
    $inputs += "executable=$($Resolved.executable)"

    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString(
                $hasher.ComputeHash(
                    [Text.Encoding]::UTF8.GetBytes($inputs -join "`n")))).Replace('-', '')
    }
    finally {
        $hasher.Dispose()
    }
}

function Get-FingerprintPath {
    <#
    .SYNOPSIS
        Where the fingerprint for an executable is recorded.

    .DESCRIPTION
        Named after the executable, not fixed at qbench.sources.sha256.  All four
        runners stage into the same output directory for a given selector set, so a
        fixed name made the release build, the bench build and the instrumented
        build overwrite each other's record and then each rebuild the other's
        binary on every alternating run.  Deriving the name from the executable
        gives each variant its own record.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Executable)

    $directory = Split-Path -Parent $Executable
    $leaf = [IO.Path]::GetFileNameWithoutExtension($Executable)
    return Join-Path $directory ($leaf + '.sources.sha256')
}

function Get-BuildFreshness {
    <#
    .SYNOPSIS
        Decide whether an executable still matches the current sources.

    .DESCRIPTION
        Three outcomes, and the third is the one that used to be missing:

          Missing  the executable is not there.  Build it.
          Stale    the executable is there but the fingerprint file is absent or
                   differs.  Its provenance is unknowable or it no longer matches
                   the tree, so rebuild rather than measure a binary that is not
                   the thing under test.
          Fresh    the fingerprint matches.  Run it.

        A pre-fingerprint binary counts as Stale, not Fresh.  "It exists" is not
        evidence that it was built from this tree.

    .OUTPUTS
        A PSCustomObject with Exists, Stale, Fingerprint, FingerprintPath and
        FingerprintPrefix.  The caller decides what to do; this only reports.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string]$Fingerprint
    )

    $fingerprintPath = Get-FingerprintPath -Executable $Executable
    $exists = Test-Path -LiteralPath $Executable -PathType Leaf
    $stale = $false
    if ($exists) {
        if (-not (Test-Path -LiteralPath $fingerprintPath -PathType Leaf)) {
            $stale = $true
        }
        else {
            $stale = ((Get-Content -LiteralPath $fingerprintPath -Raw).Trim() -ne $Fingerprint)
        }
    }

    return [pscustomobject]@{
        Exists          = $exists
        Stale           = $stale
        Fingerprint     = $Fingerprint
        FingerprintPath = $fingerprintPath
        # Enough to recognise a digest in a log without printing all 64 digits.
        FingerprintPrefix = $Fingerprint.Substring(0, 12)
    }
}

function Set-BuildFingerprint {
    <#
    .SYNOPSIS
        Record a freshly built executable's fingerprint.

    .DESCRIPTION
        Written only after the build that the fingerprint describes has succeeded.
        Recording earlier would pin a binary that was never produced, and the next
        run would trust it.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string]$Fingerprint
    )

    Set-Content -LiteralPath (Get-FingerprintPath -Executable $Executable) `
        -Value $Fingerprint -Encoding ASCII -NoNewline
}
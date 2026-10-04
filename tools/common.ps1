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
# ---------------------------------------------------------------------------
# DOS staging and emulator harness
#
# Everything below was written out four times, once per runner.  The four copies
# had already drifted: coverage-dos.ps1 hardcoded the emulator's filename where
# the others read it from the manifest, coverage-dos.ps1 had no bootstrap
# fallback, and the two that lacked a staleness check were the two that could
# silently test the wrong binary.  One copy is the point.
# ---------------------------------------------------------------------------

function Read-ToolchainManifest {
    <#
    .SYNOPSIS
        Read tools\dos-toolchain.json.

    .DESCRIPTION
        Eight tools read this file independently.  The compiler path, the objdump
        path and the DOSBox-X path are all derived from it, so a manifest edit
        reaches all of them at once instead of failing in whichever tool happened
        to have spelled its own copy of the arithmetic.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ToolsDirectory)

    $manifestPath = Join-Path $ToolsDirectory 'dos-toolchain.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Toolchain manifest was not found: '$manifestPath'."
    }
    return (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json)
}

function Resolve-ToolRoot {
    <#
    .SYNOPSIS
        Resolve the toolchain installation directory.

    .DESCRIPTION
        Defaults to %LOCALAPPDATA%\486quake\tools.  GetFolderPath rather than
        $env:LOCALAPPDATA, because the environment variable can be empty or
        missing and the folder API cannot be -- an empty tool root produces a
        baffling "file not found" several steps later instead of one clear error.
    #>
    [CmdletBinding()]
    param([string]$ToolRoot)

    if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
        $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
        if ([string]::IsNullOrWhiteSpace($localAppData)) {
            throw 'Could not determine the Windows local application-data directory.'
        }
        $ToolRoot = Join-Path $localAppData '486quake\tools'
    }
    return [IO.Path]::GetFullPath($ToolRoot)
}

function Resolve-DataRoot {
    <#
    .SYNOPSIS
        Resolve the directory holding the game data.

    .DESCRIPTION
        Defaults to testdata\id1 in the repository.  Game data is deliberately not
        in Git, so the caller reports a missing directory itself, with the
        reminder about where to put it.
    #>
    [CmdletBinding()]
    param(
        [string]$DataRoot,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($DataRoot)) {
        $DataRoot = Join-Path $RepoRoot 'testdata\id1'
    }
    return [IO.Path]::GetFullPath($DataRoot)
}

function Resolve-DosboxExecutable {
    <#
    .SYNOPSIS
        Locate the DOSBox-X binary, bootstrapping the toolchain if allowed.

    .DESCRIPTION
        The executable name comes from dos-toolchain.json.dosboxX.executable, never
        from a literal.  coverage-dos.ps1 used to hardcode 'dosbox-x.exe' beside
        installDirectory, so it alone would break on a manifest that named the
        binary differently or shipped it in a subdirectory.

        With -NoBootstrap, a missing emulator is an error naming the fix.  Without
        it, bootstrap-dos.ps1 runs first.  coverage-dos.ps1 had no fallback at all,
        which made -NoBootstrap mean one thing there and another everywhere else.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ToolRoot,
        [Parameter(Mandatory = $true)][string]$ToolsDirectory,
        [switch]$NoBootstrap
    )

    $dosboxRoot = Join-Path $ToolRoot $Manifest.dosboxX.installDirectory
    $dosbox = Join-Path $dosboxRoot (
        $Manifest.dosboxX.executable -replace '/', [IO.Path]::DirectorySeparatorChar)

    if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
        if ($NoBootstrap) {
            throw "DOSBox-X not found at '$dosbox'. Run bootstrap-dos.ps1 first or omit -NoBootstrap."
        }
        & (Join-Path $ToolsDirectory 'bootstrap-dos.ps1') -ToolRoot $ToolRoot
    }
    if (-not (Test-Path -LiteralPath $dosbox -PathType Leaf)) {
        throw "Required DOSBox-X executable is missing: '$dosbox'."
    }
    return $dosbox
}

function Get-DosboxProfilePath {
    <#
    .SYNOPSIS
        The pinned 486-high DOSBox-X profile.

    .DESCRIPTION
        One profile template serves all four runners.  Its SHA-256 is a promotion
        gate in timedemo-dos.ps1, so this returns the file rather than its text:
        the hash is taken over the bytes on disk, and re-serialising the text first
        would let a line-ending change slip past a pin that exists precisely to
        catch one.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ToolsDirectory)

    $profile = Join-Path $ToolsDirectory 'dosbox-x-486-high.conf'
    if (-not (Test-Path -LiteralPath $profile -PathType Leaf)) {
        throw "DOSBox-X profile is missing: '$profile'."
    }
    return $profile
}

function New-DosboxRuntimeConfig {
    <#
    .SYNOPSIS
        Write a DOSBox-X config for one run and return its path.

    .DESCRIPTION
        Takes the pinned profile and replaces its [autoexec] section with one that
        mounts the staging directory and calls the run's batch file.  Then, for a
        non-i486 target, forces cputype to match the build target.

        On the cputype: one profile serves both CPU targets, and only the emulated
        CPU changes -- the base profile uses a fixed cycle count so timings stay
        comparable between them.  Note that DOSBox-X's cputype changes cycle costs
        but does not enforce instruction-set gating, so this makes a run
        representative and is not the ISA gate.  tools\isa-audit.ps1 is.

        The replacement is anchored on the [devices] header that follows
        [autoexec], and the result is compared against the input: an unchanged
        config means the substitution did not happen, and writing that out would
        run the pinned profile's own autoexec instead of the scenario's.

        The injected block adopts the template's own line ending rather than a
        hardcoded one.  A here-string takes its line endings from the .ps1 file it
        is written in, and this tree is not self-consistent about them: git stores
        these files as LF and core.autocrlf=true rewrites them to CRLF on checkout,
        so the same commit produces a different generated config depending on the
        machine's git configuration.  Worse, HEAD's version appended
        [Environment]::NewLine after a TrimEnd, which put CRLF at the end of a block
        whose interior was LF -- a mixed-ending block inside an otherwise CRLF
        file.

        Detecting the newline from the template makes the block match whatever it
        is being inserted into, on any checkout, under any git configuration.  The
        rest of the config is the template's bytes copied through unchanged, so this
        is the only place line endings are chosen.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ProfileTemplate,
        [Parameter(Mandatory = $true)][string]$StagingRoot,
        [Parameter(Mandatory = $true)][string]$BatchName,
        [Parameter(Mandatory = $true)][ValidateSet('i486', 'i386')][string]$CpuTarget,
        [Parameter(Mandatory = $true)][string]$ConfigName
    )

    $profileText = Get-Content -LiteralPath $ProfileTemplate -Raw
    # CRLF unless the template is entirely LF.
    $newline = if ($profileText.Contains("`r`n")) { "`r`n" } else { "`n" }
    # DOSBox-X parses the mount argument itself, so an embedded quote is doubled.
    $mountPath = $StagingRoot.Replace('"', '""')
    $autoexec = @(
        '[autoexec]'
        "mount c `"$mountPath`""
        'c:'
        'cd \quake'
        "call $BatchName"
        'exit'
        ''
    ) -join $newline
    $runtimeConfig = [regex]::Replace(
        $profileText,
        '(?ms)^\[autoexec\]\s*.*?(?=^\[devices\])',
        [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $autoexec })
    if ($runtimeConfig -eq $profileText) {
        throw "Could not replace the autoexec section in '$ProfileTemplate'."
    }

    if ($CpuTarget -ne 'i486') {
        $cpuModel = $CpuTarget -replace '^i', ''
        $forcedConfig = [regex]::Replace(
            $runtimeConfig,
            '(?m)^cputype\s*=\s*\S+',
            "cputype            = $cpuModel")
        if ($forcedConfig -eq $runtimeConfig) {
            throw "Could not set the DOSBox-X cputype to '$cpuModel' in '$ProfileTemplate'."
        }
        $runtimeConfig = $forcedConfig
    }

    $configPath = Join-Path $StagingRoot $ConfigName
    $runtimeConfig | Set-Content -LiteralPath $configPath -Encoding ASCII
    return $configPath
}

function ConvertTo-ProcessArgument {
    <#
    .SYNOPSIS
        Quote one argument for a ProcessStartInfo.Arguments string.

    .DESCRIPTION
        ProcessStartInfo on .NET takes a single Arguments string on Windows, so an
        argument containing a space has to be quoted by hand.  Doubles any embedded
        quote rather than backslash-escaping it, which is what the Win32 command
        line parser expects.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + $Value.Replace('"', '\"') + '"'
}

function Invoke-DosboxProcess {
    <#
    .SYNOPSIS
        Run DOSBox-X against a config and wait for it.

    .DESCRIPTION
        Starts hidden, waits, and kills on timeout.  Returns the outcome rather
        than throwing on timeout, because the runners disagree about what a timeout
        means: smoke, bench and timedemo treat it as a failure, while coverage-dos
        has to go on to write a result document saying the scenario did not
        complete.  Deciding that here would force one of those behaviours on all
        four, so the caller decides.

    .OUTPUTS
        ExitCode ($null when the process was killed) and TimedOut.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Dosbox,
        [Parameter(Mandatory = $true)][string]$ConfigPath,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds,
        # Prepended to the launch message, e.g. 'DOSBox-X smoke test'.
        [string]$Description = 'DOSBox-X'
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Dosbox
    $startInfo.Arguments = '-conf ' + (ConvertTo-ProcessArgument $ConfigPath) + ' -exit'
    # DOSBox-X resolves its own resources relative to its working directory.
    $startInfo.WorkingDirectory = Split-Path -Parent $Dosbox
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $timedOut = $false
    $exitCode = $null
    try {
        Write-Host "Launching $Description"
        if (-not $process.Start()) {
            throw 'DOSBox-X failed to start.'
        }
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            $timedOut = $true
        }
        else {
            # Read before the finally disposes the process; ExitCode is not
            # readable afterwards.
            $exitCode = $process.ExitCode
        }
    }
    finally {
        $process.Dispose()
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        TimedOut = $timedOut
    }
}

function New-QuakeStaging {
    <#
    .SYNOPSIS
        Stage a DOS build, its DPMI host and the game data into a run directory.

    .DESCRIPTION
        The layout is fixed because the batch files and the DOSBox autoexec both
        assume it:  <staging>\quake\{quake.exe,cwsdpmi.exe,<batch>}  and
        <staging>\quake\id1\*.pak.

        The paks are hardlinked, not copied.  pak0 plus pak1 is ~50 MB and four
        runners stage them per run; copying dominated the wall clock of every
        gate.  NTFS hardlinks cannot span volumes, so the data must sit on the same
        volume as the repository -- checked, with the fix in the message rather
        than a bare Win32 error.

        Only paks are staged.  A Steam id1 directory also holds configs, saves and
        autoexec lines, and a local autoexec can prevent +quit from ever returning
        under the cycle cap -- which reads as a hung emulator, not as bad data.

    .PARAMETER OnExistingStaging
        Throw    refuse to touch an existing directory (bench, timedemo, which
                 stamp their directory with a UTC timestamp).
        Overwrite remove it first (smoke, whose directory name is fixed).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$StagingRoot,
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string]$StagedExecutableName,
        [Parameter(Mandatory = $true)][string]$DataRoot,
        [ValidateSet('Throw', 'Overwrite')][string]$OnExistingStaging = 'Throw',
        [switch]$StageDpmiHost
    )

    if (Test-Path -LiteralPath $StagingRoot) {
        if ($OnExistingStaging -eq 'Throw') {
            throw "Staging path already exists; refusing to overwrite '$StagingRoot'."
        }
        Remove-Item -LiteralPath $StagingRoot -Recurse -Force
    }
    $quakeRoot = Join-Path $StagingRoot 'quake'
    $stagedData = Join-Path $quakeRoot 'id1'
    New-Item -ItemType Directory -Path $stagedData -Force | Out-Null

    Copy-Item -LiteralPath $Executable -Destination (Join-Path $quakeRoot $StagedExecutableName) -Force
    if ($StageDpmiHost) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot 'src\cwsdpmi.exe') `
            -Destination (Join-Path $quakeRoot 'cwsdpmi.exe') -Force
    }

    if (-not (Test-Path -LiteralPath $DataRoot -PathType Container)) {
        throw "Game data directory '$DataRoot' does not exist. Put legally obtained data there or pass -DataRoot."
    }
    $pakFiles = @(Get-ChildItem -LiteralPath $DataRoot -Filter 'pak*.pak' -File)
    if ($pakFiles.Count -eq 0) {
        throw "'$DataRoot' must contain pak0.pak. Game data is intentionally not included in Git."
    }
    if ([IO.Path]::GetPathRoot($DataRoot) -ne [IO.Path]::GetPathRoot($RepoRoot)) {
        throw "Game data must be on the same volume as the repository so staging can hardlink it instead of copying 50 MB per run. Copy pak*.pak to '$(Join-Path $RepoRoot 'testdata\id1')' and drop -DataRoot. See BUILD-DOS.md."
    }
    foreach ($pak in $pakFiles) {
        New-Item -ItemType HardLink -Path (Join-Path $stagedData $pak.Name) `
            -Value $pak.FullName -Force | Out-Null
    }

    return [pscustomobject]@{
        StagingRoot = $StagingRoot
        QuakeRoot   = $quakeRoot
        StagedData  = $stagedData
        PakFiles    = @($pakFiles)
    }
}
function Get-TextFileHash {
    <#
    .SYNOPSIS
        SHA-256 of a text file, with its line endings normalised to LF.

    .DESCRIPTION
        For pinning a text file's CONTENT rather than its representation.

        This exists because the timedemo promotion gate hashed
        tools\dosbox-x-486-high.conf as it sat on disk, and that made the gate
        depend on the machine's git configuration rather than on the repository.
        There is no .gitattributes in this tree and core.autocrlf is not recorded
        anywhere, so the committed blob is LF and a Windows checkout with
        core.autocrlf=true rewrites it to CRLF. The pinned constant was the hash
        of the CRLF form, so the gate passed here and would have failed on any
        checkout with core.autocrlf=false -- including Linux, and including a
        Windows clone made after someone set core.autocrlf=input.

        Normalising to LF before hashing pins what the file says rather than which
        platform checked it out. It does weaken the pin slightly: a change confined
        to line endings now passes. That is the right trade, because a CRLF/LF
        difference cannot change what DOSBox-X does with the file, and the frames,
        checksum and median gates below still catch any behavioural change.

        tools\guard-i486-release.py does the same normalisation for __TIME__ and
        __DATE__, for the same reason: the thing being pinned is not the clock.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = [IO.File]::ReadAllBytes($Path)
    $text = [Text.Encoding]::ASCII.GetString($bytes) -replace "`r`n", "`n"
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString(
                $hasher.ComputeHash([Text.Encoding]::ASCII.GetBytes($text)))).Replace('-', '')
    }
    finally {
        $hasher.Dispose()
    }
}
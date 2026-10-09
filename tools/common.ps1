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

. (Join-Path $PSScriptRoot 'selectors.ps1')

function Add-RunnerBuildSelectors {
    <# Every selector exposed by a runner is forwarded from its resolved local
       value. Do not maintain a second, partial forwarding list in each runner. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][hashtable]$BuildParameters,
        [Parameter(Mandatory = $true)][System.Management.Automation.CommandInfo]$Command,
        [Parameter(Mandatory = $true)][System.Management.Automation.SessionState]$SessionState
    )
    foreach ($selector in $script:SelectorTable) {
        if (-not $Command.Parameters.ContainsKey($selector.Param)) { continue }
        $variable = $SessionState.PSVariable.Get($selector.Param)
        if ($null -eq $variable) { throw "Runner selector '$($selector.Param)' has no resolved value." }
        $BuildParameters[$selector.Param] = $variable.Value
    }
}

function Assert-RunnerBuildManifest {
    <# A requested selector in run metadata is not evidence that it was built.
       Check the actual build manifest before staging or running the executable. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Resolved,
        [Parameter(Mandatory = $true)][hashtable]$BuildParameters,
        [switch]$VisualParityOnly
    )
    $manifestPath = Join-Path $Resolved.outputRoot $Resolved.manifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Build selector verification requires '$manifestPath'."
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.executable -ne $Resolved.executable) {
        throw "Build manifest executable '$($manifest.executable)' differs from '$($Resolved.executable)'."
    }
    $verified = [ordered]@{}
    foreach ($selector in $script:SelectorTable) {
        if (-not $BuildParameters.ContainsKey($selector.Param)) { continue }
        $actual = $manifest.PSObject.Properties[$selector.Manifest]
        $expected = [string]$BuildParameters[$selector.Param]
        if ($null -eq $actual -or [string]$actual.Value -ne $expected) {
            $built = if ($null -eq $actual) { '<missing>' } else { [string]$actual.Value }
            throw "Build selector mismatch for '$($selector.Param)': requested '$expected', built '$built' in '$manifestPath'."
        }
        $verified[$selector.Param] = $actual.Value
    }
    $executableHash = (Get-FileHash -LiteralPath $Resolved.executable -Algorithm SHA256).Hash
    $manifestIsaAuditStatus = if ($null -eq $manifest.PSObject.Properties['isaAuditStatus']) {
        'NOT_RECORDED'
    } else {
        [string]$manifest.isaAuditStatus
    }
    if ($manifest.cpuTarget -eq 'i486' -and $manifestIsaAuditStatus -eq 'SKIPPED') {
        $benchmarkDiagnosticOnly = $BuildParameters.ContainsKey('Benchmark') -and
            [bool]$BuildParameters['Benchmark'] -and
            $BuildParameters.ContainsKey('SkipIsaAudit') -and
            [bool]$BuildParameters['SkipIsaAudit']
        if (-not $VisualParityOnly -and -not $benchmarkDiagnosticOnly) {
            throw 'The i486 renderer requires a complete ISA audit; skipped audits are allowed only for explicit visual parity or benchmark diagnostics.'
        }
        if (-not $BuildParameters.ContainsKey('SkipIsaAudit') -or
                -not [bool]$BuildParameters['SkipIsaAudit']) {
            throw 'A skipped i486 ISA audit requires an explicit -SkipIsaAudit build parameter.'
        }
        if ($manifest.executableSha256 -ne $executableHash) {
            throw 'The visual-only i486 executable does not match its build manifest.'
        }
        $policy = Get-CompatibilityPolicyFingerprint -RepoRoot (Join-Path $PSScriptRoot '..')
        if ($manifest.compatibilityPolicySha256 -ne $policy) {
            throw 'The visual-only build used a different compatibility policy or runtime provider; rebuild it.'
        }
        return [pscustomobject]@{
            passed = $true
            manifest = $manifestPath
            manifestSha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
            executableSha256 = $executableHash
            selectors = $verified
            compatibility = $null
            isaAuditStatus = 'SKIPPED'
            visualParityOnly = [bool]$VisualParityOnly
            diagnosticOnly = [bool]($benchmarkDiagnosticOnly -and -not $VisualParityOnly)
        }
    }
    $compatibility = $null
    if ($manifest.cpuTarget -eq 'i486') {
        foreach ($name in @('executableSha256', 'isaAuditStatus', 'isaAuditReport',
                'isaAuditReportSha256', 'isaLinkedAuditReport', 'isaLinkedAuditReportSha256',
                'compatibilityPolicySha256', 'sourceBoundIsa', 'actualRelocatedIsa', 'embeddedStartupIsa', 'externalDpmiProviderIsa')) {
            if ($null -eq $manifest.PSObject.Properties[$name]) { throw "Build manifest lacks i486 evidence '$name'." }
        }
        if ($manifest.isaAuditStatus -ne 'PASS' -or $manifest.executableSha256 -ne $executableHash) {
            throw 'The i486 executable does not match a passed ISA audit.'
        }
        $policy = Get-CompatibilityPolicyFingerprint -RepoRoot (Join-Path $PSScriptRoot '..')
        if ($manifest.compatibilityPolicySha256 -ne $policy) {
            throw 'The build used a different compatibility policy or runtime provider; rebuild and audit it.'
        }
        foreach ($pair in @(@('isaAuditReport', 'isaAuditReportSha256'),
                @('isaLinkedAuditReport', 'isaLinkedAuditReportSha256'))) {
            $path = [string]$manifest.($pair[0])
            if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
                    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $manifest.($pair[1])) {
                throw "The build's ISA report '$path' is missing or changed."
            }
        }
        $linked = Get-Content -LiteralPath $manifest.isaLinkedAuditReport -Raw | ConvertFrom-Json
        if (-not $linked.pass -or $linked.cpuTarget -ne 'i486' -or
                $linked.executable -ne $Resolved.executable -or $linked.executableSha256 -ne $executableHash -or
                [int]$linked.instructionAudit.linkedInstructionsVerified -le 0 -or
                [int]$linked.instructionAudit.linkedOpcodeMismatches -ne 0) {
            throw 'The linked ISA evidence is not bound to this i486 executable.'
        }
        if ($manifest.sourceBoundIsa -ne $true -or $linked.sourceBoundCodeData -ne $true -or
                @($linked.instructionAudit.inputExempted).Count -ne 0 -or
                [int]$linked.instructionAudit.inputContinuationLines -ne 0 -or
                [int]$linked.instructionAudit.linkedDataSitesExempted -ne 0 -or
                [int]$linked.instructionAudit.linkedNonInstructionByteSitesMatched -ne 0 -or
                [int]$linked.instructionAudit.linkedRelocationCoveredDataSites -ne 0) {
            throw 'The i486 runner requires exact source boundaries without instruction exemptions or skipped bytes.'
        }
        $final = $linked.actualRelocatedIsa
        if ($final.sourceBound -ne $true -or [int]$final.instructionExemptions -ne 0 -or
                [int]$final.instructionCount -ne [int]$linked.instructionAudit.linkedInstructionsVerified -or
                $manifest.actualRelocatedIsa.reportSha256 -ne $final.reportSha256 -or
                -not (Test-Path -LiteralPath $final.report -PathType Leaf) -or
                (Get-FileHash -LiteralPath $final.report -Algorithm SHA256).Hash -ne $final.reportSha256) {
            throw 'The independent relocated-instruction report is incomplete, missing or changed.'
        }
        $finalReport = Get-Content -LiteralPath $final.report -Raw | ConvertFrom-Json
        if ([int]$finalReport.instructionCount -ne [int]$final.instructionCount -or
                [int]$finalReport.violationCount -ne 0 -or [int]$finalReport.unclassifiedCount -ne 0 -or
                @($finalReport.exempted).Count -ne 0) { throw 'The independent final instruction audit did not pass strictly.' }
        $startup = $linked.embeddedStartupIsa
        if ($startup.exactFinalBytes -ne $true -or [int]$startup.instructionExemptions -ne 0 -or
                [int]$startup.instructionCount -le 0 -or
                $manifest.embeddedStartupIsa.proofSha256 -ne $startup.proofSha256 -or
                -not (Test-Path -LiteralPath $startup.proof -PathType Leaf) -or
                (Get-FileHash -LiteralPath $startup.proof -Algorithm SHA256).Hash -ne $startup.proofSha256) {
            throw 'The final embedded startup proof is incomplete, missing or changed.'
        }
        $startupReport = Get-Content -LiteralPath $startup.proof -Raw | ConvertFrom-Json
        if ($startupReport.exactPrimarySourcesAndFinalBytes -ne $true -or
                $startupReport.executableSha256 -ne $executableHash -or
                [int]$startupReport.instructionRows -ne [int]$startup.instructionCount -or
                [int]$startupReport.loadedStartupBytesProved -ne [int]$startup.loadedBytes) {
            throw 'The embedded startup proof does not cover this exact executable.'
        }
        $provider = $linked.externalDpmiProvider
        $providerPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../src/cwsdpmi.exe'))
        $providerHash = (Get-FileHash -LiteralPath $providerPath -Algorithm SHA256).Hash
        if ($provider.exactMaintainedProvider -ne $true -or [int]$provider.instructionExemptions -ne 0 -or
                [int]$provider.instructionCount -ne 9207 -or [int]$provider.runtimeVariantInstructions -ne 1 -or
                $provider.executableSha256 -ne $providerHash -or
                $manifest.externalDpmiProviderIsa.proofSha256 -ne $provider.proofSha256 -or
                -not (Test-Path -LiteralPath $provider.proof -PathType Leaf) -or
                (Get-FileHash -LiteralPath $provider.proof -Algorithm SHA256).Hash -ne $provider.proofSha256) {
            throw 'The default DPMI provider does not match its complete i486 instruction proof.'
        }
        $providerReport = Get-Content -LiteralPath $provider.proof -Raw | ConvertFrom-Json
        if ($providerReport.passed -ne $true -or $providerReport.exactOriginalPlusMaintainedAssembly -ne $true -or
                $providerReport.executableSha256 -ne $providerHash -or [int]$providerReport.instructionCount -ne 9207 -or
                [int]$providerReport.runtimeVariantInstructions -ne 1 -or [int]$providerReport.instructionExemptions -ne 0 -or
                [int]$providerReport.unknownEncodings -ne 0 -or
                $providerReport.policySha256 -ne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'cws-provider-proof.py') -Algorithm SHA256).Hash) {
            throw 'The DPMI provider proof is stale or incomplete.'
        }
        foreach ($entry in @(@($providerReport.strictReport,$providerReport.strictReportSha256,9207),
                @($providerReport.runtimeVariantReport,$providerReport.runtimeVariantReportSha256,1))) {
            if (-not (Test-Path -LiteralPath $entry[0] -PathType Leaf) -or
                    (Get-FileHash -LiteralPath $entry[0] -Algorithm SHA256).Hash -ne $entry[1]) {
                throw 'The provider instruction report is missing or changed.'
            }
            $audit = Get-Content -LiteralPath $entry[0] -Raw | ConvertFrom-Json
            if ($audit.result -ne 'PASS' -or [int]$audit.instructionCount -ne [int]$entry[2] -or
                    [int]$audit.unclassifiedCount -ne 0 -or [int]$audit.violationCount -ne 0 -or
                    [int]$audit.exemptedCount -ne 0) { throw 'The provider instruction audit did not pass strictly.' }
        }
        $compatibility = [pscustomobject]@{
            passed = $true; linkedReport = $manifest.isaLinkedAuditReport
            linkedReportSha256 = $manifest.isaLinkedAuditReportSha256; policySha256 = $policy
            sourceBound = $true; relocatedInstructions = [int]$final.instructionCount
            embeddedStartupInstructions = [int]$startup.instructionCount
            externalDpmiProviderVerified = $true; externalDpmiProviderSha256 = $providerHash
            externalDpmiProviderInstructions = 9207
        }
    }
    return [pscustomobject]@{
        passed = $true
        manifest = $manifestPath
        manifestSha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
        executableSha256 = $executableHash
        selectors = $verified
        compatibility = $compatibility
        isaAuditStatus = $manifestIsaAuditStatus
        visualParityOnly = [bool]$VisualParityOnly
        diagnosticOnly = $false
    }
}

function Assert-RunnerDpmiProvider {
    <# Validate the exact staged provider, including changes between build and staging. #>
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$CpuTarget,
        [Parameter(Mandatory=$true)]$BuildVerification,
        [Parameter(Mandatory=$true)][string]$ProviderPath,
        [switch]$VisualParityOnly,
        [switch]$DiagnosticOnly,
        [string]$ProviderProofPath)
    $hash = (Get-FileHash -LiteralPath $ProviderPath -Algorithm SHA256).Hash
    if ($CpuTarget -ne 'i486') { return [pscustomobject]@{verified=$false;cpuTarget=$CpuTarget;sha256=$hash} }
    if ($BuildVerification.isaAuditStatus -eq 'SKIPPED') {
        $visualMode = $VisualParityOnly -and $BuildVerification.visualParityOnly
        $diagnosticMode = $DiagnosticOnly -and $BuildVerification.diagnosticOnly
        if (-not $visualMode -and -not $diagnosticMode) {
            throw 'The staged DPMI provider cannot turn a skipped renderer ISA audit into an i486 compatibility pass.'
        }
        if ([string]::IsNullOrWhiteSpace($ProviderProofPath) -or
                -not (Test-Path -LiteralPath $ProviderProofPath -PathType Leaf)) {
            throw 'A skipped i486 renderer audit requires a separate, complete maintained DPMI-provider proof.'
        }
        $repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
        $sourceProvider = [IO.Path]::GetFullPath((Join-Path $repoRoot 'src/cwsdpmi.exe'))
        $bundleManifestPath = Join-Path $PSScriptRoot 'isa-provider-reference/manifest.json'
        $bundleManifest = Get-Content -LiteralPath $bundleManifestPath -Raw | ConvertFrom-Json
        $bundleManifestHash = (Get-FileHash -LiteralPath $bundleManifestPath -Algorithm SHA256).Hash
        $sourceHash = (Get-FileHash -LiteralPath $sourceProvider -Algorithm SHA256).Hash
        $proof = Get-Content -LiteralPath $ProviderProofPath -Raw | ConvertFrom-Json
        $proofHash = (Get-FileHash -LiteralPath $ProviderProofPath -Algorithm SHA256).Hash
        if ($hash -ne $sourceHash -or $hash -ne $bundleManifest.candidateSha256 -or
                $proof.passed -ne $true -or $proof.exactOriginalPlusMaintainedAssembly -ne $true -or
                $proof.executableSha256 -ne $hash -or
                $proof.sourceManifestSha256 -ne $bundleManifestHash -or
                [int]$proof.instructionCount -ne 9207 -or
                [int]$proof.runtimeVariantInstructions -ne 1 -or
                [int]$proof.instructionExemptions -ne 0 -or [int]$proof.unknownEncodings -ne 0 -or
                $proof.policySha256 -ne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'cws-provider-proof.py') -Algorithm SHA256).Hash) {
            throw 'The independent maintained DPMI-provider proof is stale, incomplete or bound to another binary.'
        }
        foreach ($entry in @(@($proof.strictReport, $proof.strictReportSha256, 9207),
                @($proof.runtimeVariantReport, $proof.runtimeVariantReportSha256, 1))) {
            if (-not (Test-Path -LiteralPath $entry[0] -PathType Leaf) -or
                    (Get-FileHash -LiteralPath $entry[0] -Algorithm SHA256).Hash -ne $entry[1]) {
                throw 'An independent DPMI-provider instruction report is missing or changed.'
            }
            $audit = Get-Content -LiteralPath $entry[0] -Raw | ConvertFrom-Json
            if ($audit.result -ne 'PASS' -or [int]$audit.instructionCount -ne [int]$entry[2] -or
                    [int]$audit.continuationLineCount -ne 0 -or
                    [int]$audit.unclassifiedCount -ne 0 -or [int]$audit.violationCount -ne 0 -or
                    [int]$audit.exemptedCount -ne 0) {
                throw 'An independent DPMI-provider instruction audit did not pass strictly.'
            }
        }
        return [pscustomobject]@{
            verified = $true; cpuTarget = $CpuTarget; sha256 = $hash
            instructionCount = 9207; runtimeVariantInstructions = 1
            proof = [IO.Path]::GetFullPath($ProviderProofPath); proofSha256 = $proofHash
            verificationMode = 'independent-provider-isa-proof'
            rendererIsaAuditStatus = 'SKIPPED'
            visualParityOnly = [bool]$visualMode
            diagnosticOnly = [bool]$diagnosticMode
        }
    }
    if ($null -eq $BuildVerification.compatibility -or
            $BuildVerification.compatibility.externalDpmiProviderVerified -ne $true -or
            $BuildVerification.compatibility.externalDpmiProviderSha256 -ne $hash) {
        throw 'The staged DPMI provider has no matching i486 instruction proof in this build.'
    }
    return [pscustomobject]@{verified=$true;cpuTarget=$CpuTarget;sha256=$hash;instructionCount=9207;runtimeVariantInstructions=1}
}

function Get-CompatibilityPolicyFingerprint {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    # Runners pass tools/.. while the builder passes a canonical directory.
    # Normalize before deriving bundle-relative names so both identify the
    # same policy and no path spelling contaminates the digest.
    $RepoRoot = [IO.Path]::GetFullPath($RepoRoot)
    # Every decoder, source-boundary policy, primary runtime input, and external
    # DOS provider participates in cache identity. A prior audit cannot cover a
    # changed proof implementation or a changed source/listing bundle.
    $policyPaths = @('tools/build-dos.ps1', 'tools/common.ps1', 'tools/selectors.ps1',
            'tools/isa-audit.ps1', 'tools/isa-audit-linked.ps1', 'tools/dos-toolchain.json',
            'tools/isa-disassemble.py', 'tools/coff-code-data.py', 'tools/project-source-proofs.py',
            'tools/runtime-source-proofs.py', 'tools/djgpp-assembler-tool.py',
            'tools/verify-executable-isa.ps1', 'tools/mz-loader-proof.py',
            'tools/djgpp-startup-helpers-proof.py', 'tools/startup-linked-proof.py',
            'tools/final-executable-isa-ranges.py', 'tools/isa-runtime-reference/manifest.json',
            'tools/cws-provider-proof.py', 'tools/isa-provider-reference/manifest.json',
            'tools/golden/isa-baseline.json', 'src/cwsdpmi.exe')
    $bundle = Join-Path $RepoRoot 'tools/isa-runtime-reference'
    if (Test-Path -LiteralPath $bundle -PathType Container) {
        $policyPaths += @(Get-ChildItem -LiteralPath $bundle -File -Recurse | ForEach-Object {
            $_.FullName.Substring($RepoRoot.Length).TrimStart('\','/') -replace '\\','/'
        })
    }
    $providerBundle = Join-Path $RepoRoot 'tools/isa-provider-reference'
    if (Test-Path -LiteralPath $providerBundle -PathType Container) {
        $policyPaths += @(Get-ChildItem -LiteralPath $providerBundle -File -Recurse | ForEach-Object {
            $_.FullName.Substring($RepoRoot.Length).TrimStart('\','/') -replace '\\','/'
        })
    }
    $inputs = foreach ($relative in ($policyPaths | Sort-Object -Unique)) {
        $path = Join-Path $RepoRoot $relative
        $hash = if (Test-Path -LiteralPath $path -PathType Leaf) {
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        } else { 'MISSING' }
        "$relative=$hash"
    }
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { return [Convert]::ToHexString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($inputs -join "`n"))) }
    finally { $hasher.Dispose() }
}

function Get-SourceTreeFingerprint {
    <#
    .SYNOPSIS
        Hash the renderer source tree without build-profile settings.

    .DESCRIPTION
        Selector parity runs intentionally use different compiler flags and
        executable suffixes, so Get-BuildFingerprint differs between C and
        assembly profiles even when both were built from identical source. This
        digest identifies the .c, .s, .h and assembly .inc inputs and lets paired render
        reports prove they came from the same source snapshot.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $sourceRoot = Join-Path $RepoRoot 'src'
    $inputs = @(
        Get-ChildItem -LiteralPath $sourceRoot -Include '*.c', '*.s', '*.h', '*.inc' -File -Recurse |
            Sort-Object FullName |
            ForEach-Object {
                $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\', '/') -replace '\\', '/'
                "$relative=$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
            }
    )
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
        Get-ChildItem -LiteralPath $sourceRoot -Include '*.c', '*.s', '*.h', '*.inc' -File -Recurse |
            Sort-Object FullName |
            ForEach-Object {
                "$($_.FullName.Substring($sourceRoot.Length))=$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)"
            }
    )
    # Each on its own line so no combination of values can be re-partitioned into
    # the same text as a different combination.
    $inputs += 'build-fingerprint-schema=3'
    $inputs += ('compatibilityPolicy=' + (Get-CompatibilityPolicyFingerprint -RepoRoot $RepoRoot))
    $inputs += "outputRoot=$($Resolved.outputRoot)"
    $inputs += "profileSuffix=$($Resolved.profileSuffix)"
    $inputs += ('cFlags=' + (ConvertTo-Json -InputObject @($Resolved.cFlags) -Compress))
    $inputs += ('asmFlags=' + (ConvertTo-Json -InputObject @($Resolved.asmFlags) -Compress))
    $inputs += "executable=$($Resolved.executable)"
    if (@($Resolved.PSObject.Properties.Name) -contains 'cSourceExtraFlags') {
        $sourceFlags = if ($Resolved.cSourceExtraFlags -is [Collections.IDictionary]) {
            @($Resolved.cSourceExtraFlags.Keys | Sort-Object | ForEach-Object {
                [pscustomobject]@{ Name = [string]$_; Value = @($Resolved.cSourceExtraFlags[$_]) }
            })
        } else { @($Resolved.cSourceExtraFlags.PSObject.Properties | Sort-Object Name) }
        foreach ($entry in $sourceFlags) {
            $inputs += ('sourceFlags=' + $entry.Name + '=' +
                (ConvertTo-Json -InputObject @($entry.Value) -Compress))
        }
    }
    if (@($Resolved.PSObject.Properties.Name) -contains 'linkFlags') {
        $inputs += ('linkFlags=' + (ConvertTo-Json -InputObject @($Resolved.linkFlags) -Compress))
    }

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

    .PARAMETER ProgressFile
        Optional text file appended while DOSBox-X runs. Complete lines are
        echoed live to the caller, allowing long benchmarks to report progress.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Dosbox,
        [Parameter(Mandatory = $true)][string]$ConfigPath,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds,
        # Prepended to the launch message, e.g. 'DOSBox-X smoke test'.
        [string]$Description = 'DOSBox-X',
        [string]$ProgressFile
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
        if ([string]::IsNullOrWhiteSpace($ProgressFile)) {
            if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
                $process.Kill()
                $timedOut = $true
            }
        }
        else {
            $progressOffset = 0
            $progressPending = ''
            $stopwatch = [Diagnostics.Stopwatch]::StartNew()
            while (-not $process.HasExited) {
                if (Test-Path -LiteralPath $ProgressFile -PathType Leaf) {
                    try {
                        $progressText = [IO.File]::ReadAllText(
                            $ProgressFile, [Text.Encoding]::ASCII)
                        if ($progressText.Length -lt $progressOffset) {
                            $progressOffset = 0
                            $progressPending = ''
                        }
                        if ($progressText.Length -gt $progressOffset) {
                            $progressPending += $progressText.Substring($progressOffset)
                            $progressOffset = $progressText.Length
                            $lastNewline = $progressPending.LastIndexOf("`n")
                            if ($lastNewline -ge 0) {
                                $completeText = $progressPending.Substring(0, $lastNewline)
                                $progressPending = $progressPending.Substring($lastNewline + 1)
                                foreach ($line in ($completeText -split "`r?`n")) {
                                    if ($line.Length -gt 0) {
                                        Write-Host "[DOSBox-X] $line"
                                    }
                                }
                            }
                        }
                    }
                    catch [System.IO.IOException] {
                        # The DOS process may hold the report during a write;
                        # retry on the next poll without losing the offset.
                    }
                }

                if ($process.WaitForExit(1000)) {
                    break
                }
                if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                    $process.Kill()
                    $timedOut = $true
                    break
                }
            }

            # Flush the last complete or partial line after DOSBox exits.
            if (Test-Path -LiteralPath $ProgressFile -PathType Leaf) {
                try {
                    $progressText = [IO.File]::ReadAllText(
                        $ProgressFile, [Text.Encoding]::ASCII)
                    if ($progressText.Length -gt $progressOffset) {
                        $progressPending += $progressText.Substring($progressOffset)
                    }
                }
                catch [System.IO.IOException] {
                }
            }
            if ($progressPending.Length -gt 0) {
                foreach ($line in ($progressPending -split "`r?`n")) {
                    if ($line.Length -gt 0) {
                        Write-Host "[DOSBox-X] $line"
                    }
                }
            }
        }

        if (-not $timedOut -and $process.HasExited) {
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

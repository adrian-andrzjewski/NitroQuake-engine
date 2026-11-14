# Standalone game build and verification API. No emulator or benchmark-suite dependency.
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
    $policyPaths = @('tools/build-dos.ps1', 'tools/build-dos-experimental.ps1',
            'tools/build-number.ps1', 'tools/common.ps1', 'tools/selectors.ps1',
            'tools/optimization-history.py', 'tools/optimization-history-legacy.json',
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
        [Parameter(Mandatory = $true)]$Resolved,
        [string]$OptimizationInventorySha256
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
    . (Join-Path $PSScriptRoot 'build-number.ps1')
    if (-not $OptimizationInventorySha256) {
        $OptimizationInventorySha256 = (Get-NitroQuakeOptimizationInventory -RepoRoot $RepoRoot).inventorySha256
    }
    $inputs += ('optimizationInventory=' + $OptimizationInventorySha256)
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

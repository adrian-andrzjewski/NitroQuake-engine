<# Exercise real runner parameter blocks, promotions and forwarding without DOS.
   The regression was an ASM request recorded in metadata but omitted at build. #>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$reference = Get-Content (Join-Path $PSScriptRoot 'renderer-profiles/i486-c-reference.json') -Raw | ConvertFrom-Json
$candidate = Get-Content (Join-Path $PSScriptRoot 'renderer-profiles/i486-asm-selectable.json') -Raw | ConvertFrom-Json
$checks = 0
$runnerCounts = [ordered]@{}
foreach ($runner in @('bench-dos.ps1', 'timedemo-dos.ps1', 'smoke-dos.ps1', 'coverage-dos.ps1')) {
    $runnerPath = Join-Path $PSScriptRoot $runner
    $runnerCommand = Get-Command $runnerPath
    $tokens = $null; $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($runnerPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw "$runner has parse errors: $parseErrors" }
    $assign = $ast.Find({ param($node)
        $node -is [Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left.Extent.Text -eq '$buildParams'
    }, $true)
    $forward = $ast.Find({ param($node)
        $node -is [Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -eq 'Add-RunnerBuildSelectors'
    }, $true)
    if ($null -eq $assign -or $null -eq $forward) { throw "$runner does not forward selectors through the shared helper." }
    $promotions = @($ast.EndBlock.Statements | Where-Object {
        $_ -is [Management.Automation.Language.IfStatementAst] -and
        $_.Extent.Text -match 'PSBoundParameters.ContainsKey'
    } | ForEach-Object { $_.Extent.Text })
    # ScriptBlock invocations have a different MyCommand. Keep the actual runner
    # command's parameter declarations when executing its forwarding statement.
    $forwardText = $forward.Extent.Text.Replace('$MyInvocation.MyCommand', '$runnerCommand')
    $harness = [scriptblock]::Create($ast.ParamBlock.Extent.Text + "`n" +
        ($promotions -join "`n") + "`n" + $assign.Extent.Text + "`n" +
        $forwardText + "`nreturn ,`$buildParams")
    foreach ($profile in @($reference, $candidate)) {
        $requested = @{ CpuTarget = 'i486' }
        foreach ($property in $profile.selectors.PSObject.Properties) {
            if ($runnerCommand.Parameters.ContainsKey($property.Name)) {
                $requested[$property.Name] = $property.Value
            }
        }
        if ($profile.id -eq 'i486-asm-selectable') {
            foreach ($selector in $script:SelectorTable) {
                if ($selector.SelectsAsm -and $runnerCommand.Parameters.ContainsKey($selector.Param)) {
                    $requested[$selector.Param] = 'asm'
                }
            }
        }
        $forwarded = & $harness @requested
        $runnerCounts[$runner] = $requested.Count
        foreach ($name in $requested.Keys) {
            if (-not $forwarded.ContainsKey($name) -or $forwarded[$name] -ne $requested[$name]) {
                throw "$runner lost requested selector $name=$($requested[$name])."
            }
            $checks++
        }
        $resolved = (& (Join-Path $PSScriptRoot 'build-dos.ps1') @forwarded -DumpFlags | Out-String) | ConvertFrom-Json
        foreach ($selector in $script:SelectorTable) {
            if (-not $requested.ContainsKey($selector.Param)) { continue }
            $value = [string]$requested[$selector.Param]
            foreach ($mapName in @('C', 'Asm')) {
                $flags = if ($mapName -eq 'C') { @($resolved.cFlags) } else { @($resolved.asmFlags) }
                $required = if ($selector[$mapName].ContainsKey($value)) { @($selector[$mapName][$value]) } else { @() }
                $possible = @($selector[$mapName].Values | ForEach-Object { $_ } | Select-Object -Unique)
                foreach ($define in $possible) {
                    if (($flags -contains ('-D' + $define)) -ne ($required -contains $define)) {
                        throw "$runner resolved the wrong $mapName define $define for $($selector.Param)=$value."
                    }
                    $checks++
                }
            }
        }
    }
}

# Keep the visual-only signal connected from paired validation through the
# timedemo build boundary, and make its explicit ISA skip and isolated output
# path visible in source rather than relying on an unlabelled ad hoc command.
foreach ($runner in @('render-validation-dos.ps1', 'render-parity-dos.ps1')) {
    $runnerPath = Join-Path $PSScriptRoot $runner
    $tokens = $null; $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($runnerPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw "$runner has parse errors: $parseErrors" }
    $visualParameter = @($ast.ParamBlock.Parameters | Where-Object {
        $_.Name.VariablePath.UserPath -eq 'VisualParityOnly'
    })
    if ($visualParameter.Count -ne 1) { throw "$runner does not declare the explicit VisualParityOnly switch." }
    $checks++
}
$validationSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'render-validation-dos.ps1') -Raw
$paritySource = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'render-parity-dos.ps1') -Raw
$timedemoSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'timedemo-dos.ps1') -Raw
if (-not $validationSource.Contains("`$timedemoArgs += '-VisualParityOnly'")) {
    throw 'render-validation-dos.ps1 does not forward VisualParityOnly to timedemo-dos.ps1.'
}
if (-not $paritySource.Contains("`$validationArgs += '-VisualParityOnly'")) {
    throw 'render-parity-dos.ps1 does not forward VisualParityOnly to both profile runs.'
}
foreach ($contract in @("`$buildParams['SkipIsaAudit']", "VisualParityOutputRoot", 'cws-provider-proof.py')) {
    if (-not $timedemoSource.Contains($contract)) {
        throw "timedemo-dos.ps1 is missing visual-only contract '$contract'."
    }
    $checks++
}
$checks += 2

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('nq-runner-selectors-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $fixtureRoot | Out-Null
try {
    $fixtureExe = Join-Path $fixtureRoot 'fixture.exe'
    [IO.File]::WriteAllBytes($fixtureExe, [byte[]]@(0x90, 0xc3))
    $resolvedFixture = [pscustomobject]@{ outputRoot = $fixtureRoot; manifest = 'build.json'; executable = $fixtureExe }
    $request = @{
        CpuTarget = 'i486'; SpriteOrientationImplementation = 'asm'; RenderMathImplementation = 'asm'
    }
    $manifest = [ordered]@{ executable = $fixtureExe }
    $objectReportPath = Join-Path $fixtureRoot 'isa-objects.json'
    $linkedReportPath = Join-Path $fixtureRoot 'isa-linked.json'
    $finalReportPath = Join-Path $fixtureRoot 'isa-final.json'
    $startupProofPath = Join-Path $fixtureRoot 'startup.json'
    $providerProofPath = Join-Path $fixtureRoot 'provider.json'
    $providerAuditPath = Join-Path $fixtureRoot 'provider-isa.json'
    $variantAuditPath = Join-Path $fixtureRoot 'provider-variant-isa.json'
    $providerHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'src/cwsdpmi.exe') -Algorithm SHA256).Hash
    @{result='PASS';instructionCount=9207;continuationLineCount=0;unclassifiedCount=0;violationCount=0;exemptedCount=0} |
        ConvertTo-Json | Set-Content -LiteralPath $providerAuditPath
    @{result='PASS';instructionCount=1;continuationLineCount=0;unclassifiedCount=0;violationCount=0;exemptedCount=0} |
        ConvertTo-Json | Set-Content -LiteralPath $variantAuditPath
    @{passed=$true;exactOriginalPlusMaintainedAssembly=$true;executableSha256=$providerHash;
        instructionCount=9207;runtimeVariantInstructions=1;instructionExemptions=0;unknownEncodings=0;
        sourceManifestSha256=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'isa-provider-reference/manifest.json') -Algorithm SHA256).Hash;
        policySha256=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'cws-provider-proof.py') -Algorithm SHA256).Hash;
        strictReport=$providerAuditPath;strictReportSha256=(Get-FileHash -LiteralPath $providerAuditPath -Algorithm SHA256).Hash;
        runtimeVariantReport=$variantAuditPath;runtimeVariantReportSha256=(Get-FileHash -LiteralPath $variantAuditPath -Algorithm SHA256).Hash} |
        ConvertTo-Json | Set-Content -LiteralPath $providerProofPath
    [IO.File]::WriteAllText($objectReportPath, '{"unclassifiedCount":0,"violationCount":0}')
    [IO.File]::WriteAllText($finalReportPath, '{"instructionCount":2,"unclassifiedCount":0,"violationCount":0,"exempted":[]}')
    @{exactPrimarySourcesAndFinalBytes=$true;executableSha256=(Get-FileHash -LiteralPath $fixtureExe -Algorithm SHA256).Hash;
        instructionRows=1;loadedStartupBytesProved=1} | ConvertTo-Json | Set-Content -LiteralPath $startupProofPath
    $linkedFixture = [ordered]@{
        cpuTarget = 'i486'; pass = $true; executable = $fixtureExe
        sourceBoundCodeData = $true
        executableSha256 = (Get-FileHash -LiteralPath $fixtureExe -Algorithm SHA256).Hash
        instructionAudit = @{ linkedInstructionsVerified = 2; linkedOpcodeMismatches = 0;
            inputExempted=@();inputContinuationLines=0;linkedDataSitesExempted=0;
            linkedNonInstructionByteSitesMatched=0;linkedRelocationCoveredDataSites=0 }
        actualRelocatedIsa = @{report=$finalReportPath;reportSha256=(Get-FileHash -LiteralPath $finalReportPath -Algorithm SHA256).Hash;
            instructionCount=2;sourceBound=$true;instructionExemptions=0}
        embeddedStartupIsa = @{proof=$startupProofPath;proofSha256=(Get-FileHash -LiteralPath $startupProofPath -Algorithm SHA256).Hash;
            instructionCount=1;loadedBytes=1;exactFinalBytes=$true;instructionExemptions=0}
        externalDpmiProvider = @{proof=$providerProofPath;proofSha256=(Get-FileHash -LiteralPath $providerProofPath -Algorithm SHA256).Hash;
            executableSha256=$providerHash;instructionCount=9207;runtimeVariantInstructions=1;
            exactMaintainedProvider=$true;instructionExemptions=0}
    }
    $linkedFixture | ConvertTo-Json | Set-Content -LiteralPath $linkedReportPath
    $manifest['executableSha256'] = $linkedFixture.executableSha256
    $manifest['compatibilityPolicySha256'] = Get-CompatibilityPolicyFingerprint -RepoRoot (Join-Path $PSScriptRoot '..')
    $manifest['isaAuditStatus'] = 'PASS'
    $manifest['sourceBoundIsa'] = $true
    $manifest['actualRelocatedIsa'] = $linkedFixture.actualRelocatedIsa
    $manifest['embeddedStartupIsa'] = $linkedFixture.embeddedStartupIsa
    $manifest['externalDpmiProviderIsa'] = $linkedFixture.externalDpmiProvider
    $manifest['isaAuditReport'] = $objectReportPath
    $manifest['isaAuditReportSha256'] = (Get-FileHash -LiteralPath $objectReportPath -Algorithm SHA256).Hash
    $manifest['isaLinkedAuditReport'] = $linkedReportPath
    $manifest['isaLinkedAuditReportSha256'] = (Get-FileHash -LiteralPath $linkedReportPath -Algorithm SHA256).Hash
    foreach ($selector in $script:SelectorTable) {
        if ($request.ContainsKey($selector.Param)) { $manifest[$selector.Manifest] = $request[$selector.Param] }
    }
    $fixturePath = Join-Path $fixtureRoot 'build.json'
    $manifest | ConvertTo-Json | Set-Content $fixturePath
    $verified = Assert-RunnerBuildManifest -Resolved $resolvedFixture -BuildParameters $request
    if (-not $verified.passed) { throw 'Matching manifest failed verification.' }
    $stage = Join-Path $fixtureRoot 'provider.exe'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'src/cwsdpmi.exe') -Destination $stage
    $provider = Assert-RunnerDpmiProvider -CpuTarget i486 -BuildVerification $verified -ProviderPath $stage
    if (-not $provider.verified) { throw 'Exact staged provider was not verified.' }

    # A skipped renderer audit is accepted only through the explicit visual
    # parity path, with the skipped build still bound to its executable and the
    # DPMI provider independently proven against the pinned provider bundle.
    $manifest['isaAuditStatus'] = 'SKIPPED'
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $fixturePath
    $skipRequest = @{}
    foreach ($key in $request.Keys) { $skipRequest[$key] = $request[$key] }
    $skipRequest['SkipIsaAudit'] = $true
    $rejected = $false
    try { Assert-RunnerBuildManifest -Resolved $resolvedFixture -BuildParameters $skipRequest | Out-Null }
    catch { $rejected = $true }
    if (-not $rejected) { throw 'A skipped i486 renderer ISA audit passed without visual-only opt-in.' }
    $visualVerification = Assert-RunnerBuildManifest -Resolved $resolvedFixture -BuildParameters $skipRequest -VisualParityOnly
    if ($visualVerification.isaAuditStatus -ne 'SKIPPED' -or
            -not $visualVerification.visualParityOnly -or $null -ne $visualVerification.compatibility) {
        throw 'The visual-only build result did not preserve its skipped ISA status.'
    }
    $visualProvider = Assert-RunnerDpmiProvider -CpuTarget i486 -BuildVerification $visualVerification `
        -ProviderPath $stage -VisualParityOnly -ProviderProofPath $providerProofPath
    if (-not $visualProvider.verified -or $visualProvider.rendererIsaAuditStatus -ne 'SKIPPED' -or
            $visualProvider.verificationMode -ne 'independent-provider-isa-proof') {
        throw 'Visual-only mode did not retain the independent DPMI-provider proof.'
    }
    $manifest['isaAuditStatus'] = 'PASS'
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $fixturePath
    $checks += 3

    [IO.File]::WriteAllBytes($stage,[byte[]]@(0x0f,0xa2))
    $rejected = $false
    try { Assert-RunnerDpmiProvider -CpuTarget i486 -BuildVerification $verified -ProviderPath $stage | Out-Null }
    catch { $rejected = $true }
    if (-not $rejected) { throw 'A changed/unreviewed staged provider was accepted.' }
    $checks += 2
    $checks++
    foreach ($badKey in @('spriteOrientationImplementation', 'renderMathImplementation', 'cpuTarget', 'executable',
            'executableSha256', 'isaAuditStatus', 'isaAuditReport', 'isaAuditReportSha256',
            'isaLinkedAuditReport', 'isaLinkedAuditReportSha256', 'compatibilityPolicySha256',
            'sourceBoundIsa', 'actualRelocatedIsa', 'embeddedStartupIsa', 'externalDpmiProviderIsa')) {
        $old = $manifest[$badKey]
        $manifest[$badKey] = 'wrong-built-value'
        $manifest | ConvertTo-Json | Set-Content $fixturePath
        $rejected = $false
        try { Assert-RunnerBuildManifest -Resolved $resolvedFixture -BuildParameters $request | Out-Null }
        catch { $rejected = $true }
        if (-not $rejected) { throw "Manifest mismatch '$badKey' was accepted." }
        $manifest[$badKey] = $old
        $checks++
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $fixturePath
    [IO.File]::WriteAllBytes($fixtureExe, [byte[]]@(0x0f,0x31,0xc3))
    $rejected = $false
    try { Assert-RunnerBuildManifest -Resolved $resolvedFixture -BuildParameters $request | Out-Null }
    catch { $rejected = $true }
    if (-not $rejected) { throw 'Executable changed after its audit was accepted.' }
    [IO.File]::WriteAllBytes($fixtureExe, [byte[]]@(0x90,0xc3))
    $checks++
    foreach ($badField in @('pass', 'cpuTarget', 'executable', 'executableSha256', 'instructionAudit',
            'sourceBoundCodeData', 'actualRelocatedIsa', 'embeddedStartupIsa', 'externalDpmiProvider')) {
        $old = $linkedFixture[$badField]
        $linkedFixture[$badField] = switch ($badField) {
            pass { $false }; cpuTarget { 'p6' }; executable { 'other.exe' }
            executableSha256 { 'wrong' }; instructionAudit { @{ linkedInstructionsVerified = 0; linkedOpcodeMismatches = 1 } }
            sourceBoundCodeData { $false }; actualRelocatedIsa { @{sourceBound=$false} }; embeddedStartupIsa { @{exactFinalBytes=$false} }
            externalDpmiProvider { @{exactMaintainedProvider=$false} }
        }
        $linkedFixture | ConvertTo-Json | Set-Content -LiteralPath $linkedReportPath
        # Even a self-consistent new report hash cannot bind another executable,
        # a skipped audit or an empty instruction stream to the candidate.
        $manifest['isaLinkedAuditReportSha256'] = (Get-FileHash -LiteralPath $linkedReportPath -Algorithm SHA256).Hash
        $manifest | ConvertTo-Json | Set-Content -LiteralPath $fixturePath
        $rejected = $false
        try { Assert-RunnerBuildManifest -Resolved $resolvedFixture -BuildParameters $request | Out-Null }
        catch { $rejected = $true }
        if (-not $rejected) { throw "Invalid linked ISA evidence '$badField' was accepted." }
        $linkedFixture[$badField] = $old
        $checks++
    }
    $linkedFixture | ConvertTo-Json | Set-Content -LiteralPath $linkedReportPath
    $manifest['isaLinkedAuditReportSha256'] = (Get-FileHash -LiteralPath $linkedReportPath -Algorithm SHA256).Hash
    $manifest.Remove('renderMathImplementation')
    $manifest | ConvertTo-Json | Set-Content $fixturePath
    $rejected = $false
    try { Assert-RunnerBuildManifest -Resolved $resolvedFixture -BuildParameters $request | Out-Null }
    catch { $rejected = $true }
    if (-not $rejected) { throw 'Missing selector was accepted.' }
    $checks++
} finally {
    # Only delete the explicitly created fixture directory, inside TEMP.
    $resolvedFixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedFixtureRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe test fixture cleanup path '$resolvedFixtureRoot'."
    }
    Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
}
Write-Host "Runner selector forwarding and manifest regression: PASS ($checks checks)."
Write-Host ("Exercised selectors: " + (($runnerCounts.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))

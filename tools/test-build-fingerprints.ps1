[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('nq-fingerprints-' + [guid]::NewGuid().ToString('N'))
$source = Join-Path $fixtureRoot 'src'
New-Item -ItemType Directory -Path (Join-Path $source 'frozen') -Force | Out-Null
try {
    # Fingerprint fixtures need a Git revision; optimization history is not an input.
    $toolFolder = Join-Path $fixtureRoot 'tools'
    New-Item -ItemType Directory -Path $toolFolder -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'docs/ledger') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $toolFolder 'optimization-history-legacy.json'),
        '{"schemaVersion":1,"records":{},"supersededDocuments":{}}')
    & git -C $fixtureRoot init -q
    if ($LASTEXITCODE -ne 0) { throw 'Fixture Git initialization failed.' }
    & git -C $fixtureRoot -c user.name=Fixture -c user.email=fixture@example.invalid commit -q --allow-empty -m 'Initialize fixture history'
    if ($LASTEXITCODE -ne 0) { throw 'Fixture Git history creation failed.' }
    [IO.File]::WriteAllText((Join-Path $toolFolder 'optimization-history-legacy.json'),
        '{"schemaVersion":1,"records":{},"supersededDocuments":{}}')
    [IO.File]::WriteAllText((Join-Path $fixtureRoot 'docs/ledger/attempt-promoted.md'),
        '# Accepted fixture')
    $routine = Join-Path $source 'routine.s'
    $include = Join-Path $source 'frozen/routine.inc'
    [IO.File]::WriteAllText($routine, '#include "frozen/routine.inc"')
    [IO.File]::WriteAllText($include, 'movl %ebx,%eax')
    $resolved = [pscustomobject]@{
        outputRoot = (Join-Path $fixtureRoot 'out'); profileSuffix = '-fixture'
        cFlags = @('-march=i486'); asmFlags = @('-march=i486','-x','assembler-with-cpp')
        executable = (Join-Path $fixtureRoot 'out/fixture.exe')
        cSourceExtraFlags = [pscustomobject]@{ 'a.c' = @('-fno-jump-tables'); 'b.c' = @('-fcommon') }
        linkFlags = @('-lm')
    }
    $tree = Get-SourceTreeFingerprint -RepoRoot $fixtureRoot
    $build = Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved
    $resolved.profileSuffix = '-fixture-selector'
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $build) {
        throw 'A changed selector profile suffix did not invalidate build identity.'
    }
    $resolved.profileSuffix = '-fixture'
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -ne $build) {
        throw 'Restoring the selector profile suffix did not restore build identity.'
    }
    [IO.File]::WriteAllText((Join-Path $fixtureRoot 'docs/ledger/attempt-rejected.md'),
        '# Rejected fixture')
    [IO.File]::WriteAllText((Join-Path $toolFolder 'optimization-history-legacy.json'),
        '{"schemaVersion":1,"records":{"attempt-promoted.md":[]},"supersededDocuments":{}}')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -ne $build) {
        throw 'Optimization-history documents changed build identity or freshness.'
    }
    [IO.File]::WriteAllText($include, 'addl %ebx,%eax')
    if ((Get-SourceTreeFingerprint -RepoRoot $fixtureRoot) -eq $tree) { throw 'Assembly include change did not invalidate source identity.' }
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $build) { throw 'Assembly include change did not invalidate build identity.' }
    [IO.File]::WriteAllText($include, 'movl %ebx,%eax')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -ne $build) { throw 'Restored exact source did not restore its fingerprint.' }
    [IO.File]::WriteAllText((Join-Path $source 'notes.md'), 'Documentation is not an instruction input.')
    if ((Get-SourceTreeFingerprint -RepoRoot $fixtureRoot) -ne $tree) { throw 'Uncompiled documentation changed source identity.' }
    $toolFolder = Join-Path $fixtureRoot 'tools'
    New-Item -ItemType Directory -Path $toolFolder -Force | Out-Null
    $auditTool = Join-Path $toolFolder 'isa-audit.ps1'
    [IO.File]::WriteAllText($auditTool, 'strict-classifier-v1')
    $withPolicy = Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved
    if ($withPolicy -eq $build) { throw 'Adding an audit policy did not invalidate build identity.' }
    [IO.File]::WriteAllText($auditTool, 'strict-classifier-v2')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $withPolicy) { throw 'Changed ISA classifier did not invalidate build identity.' }
    if ((Get-SourceTreeFingerprint -RepoRoot $fixtureRoot) -ne $tree) { throw 'Policy changes contaminated cross-profile source identity.' }
    Remove-Item -LiteralPath $auditTool
    $decoder = Join-Path $toolFolder 'isa-disassemble.py'
    [IO.File]::WriteAllText($decoder, 'decoder-v1')
    $withDecoder = Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved
    [IO.File]::WriteAllText($decoder, 'decoder-v2')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $withDecoder) { throw 'Changed instruction decoder did not invalidate build identity.' }
    Remove-Item -LiteralPath $decoder
    $bundleRoot = Join-Path $toolFolder 'isa-runtime-reference/primary'
    New-Item -ItemType Directory -Path $bundleRoot -Force | Out-Null
    $primaryListing = Join-Path $bundleRoot 'runtime.s'
    [IO.File]::WriteAllText($primaryListing, 'ret')
    $withListing = Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved
    if ((Get-CompatibilityPolicyFingerprint -RepoRoot (Join-Path $fixtureRoot 'tools/..')) -ne
            (Get-CompatibilityPolicyFingerprint -RepoRoot $fixtureRoot)) {
        throw 'Equivalent repository paths disagree about the runtime source policy.'
    }
    [IO.File]::WriteAllText($primaryListing, 'cmovz %eax,%ebx')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $withListing) { throw 'Changed runtime listing did not invalidate build identity.' }
    Remove-Item -LiteralPath $primaryListing
    $provider = Join-Path $source 'cwsdpmi.exe'
    [IO.File]::WriteAllBytes($provider, [byte[]]@(0x90,0xc3))
    $withProvider = Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved
    [IO.File]::WriteAllBytes($provider, [byte[]]@(0x0f,0x31,0xc3))
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $withProvider) { throw 'Changed runtime provider did not invalidate build identity.' }
    Remove-Item -LiteralPath $provider
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -ne $build) { throw 'Restored source and compatibility policy did not restore build identity.' }
    $resolved.cSourceExtraFlags.'a.c' = @('-fno-jump-tables','-fno-delete-null-pointer-checks')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $build) { throw 'Per-source compiler flag change did not invalidate build identity.' }
    $resolved.cSourceExtraFlags = [pscustomobject]@{ 'b.c' = @('-fcommon'); 'a.c' = @('-fno-jump-tables') }
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -ne $build) { throw 'Dictionary key order changed an equivalent configuration fingerprint.' }
    $resolved.cSourceExtraFlags = [ordered]@{ 'a.c' = @('-fno-jump-tables'); 'b.c' = @('-fcommon') }
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -ne $build) { throw 'Native builder dictionary and JSON-resolved flags disagree.' }
    $resolved.linkFlags = @('-lm','-Wl,--no-undefined')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $build) { throw 'Link flag change did not invalidate build identity.' }
    $resolved.linkFlags = @('-lm')
    $resolved.cFlags = @('-DNAME=A B')
    $oneArgument = Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved
    $resolved.cFlags = @('-DNAME=A','B')
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -eq $oneArgument) { throw 'Different argument boundaries collided in a fingerprint.' }
    $resolved.cFlags = @('-march=i486')
    $resolved.outputRoot = Join-Path $fixtureRoot 'out-one'
    $resolved.executable = Join-Path $resolved.outputRoot 'fixture.exe'
    $resolved.cSourceExtraFlags = [ordered]@{
        'host.c' = @('-include', (Join-Path $resolved.outputRoot 'nitroquake-build.h'))
    }
    $resolved.linkFlags = @('-lm', ('-Wl,-Map=' + (Join-Path $resolved.outputRoot 'fixture.map')),
        '-o', $resolved.executable)
    $pathA = Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved
    $resolved.outputRoot = Join-Path $fixtureRoot 'out-two'
    $resolved.executable = Join-Path $resolved.outputRoot 'fixture.exe'
    $resolved.cSourceExtraFlags['host.c'] = @('-include', (Join-Path $resolved.outputRoot 'nitroquake-build.h'))
    $resolved.linkFlags = @('-lm', ('-Wl,-Map=' + (Join-Path $resolved.outputRoot 'fixture.map')),
        '-o', $resolved.executable)
    if ((Get-BuildFingerprint -RepoRoot $fixtureRoot -Resolved $resolved) -ne $pathA) {
        throw 'Output paths changed an otherwise identical build fingerprint.'
    }
    Write-Host 'Build fingerprint regression: PASS (source/config changes invalidate; history and output paths do not).'
} finally {
    $absolute = [IO.Path]::GetFullPath($fixtureRoot)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe fixture cleanup path '$absolute'." }
    Remove-Item -LiteralPath $absolute -Recurse -Force
}

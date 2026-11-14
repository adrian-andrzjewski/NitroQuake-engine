[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
& python (Join-Path $PSScriptRoot 'test-optimization-history.py')
if ($LASTEXITCODE -ne 0) { throw 'Optimization-history contract tests failed.' }
. (Join-Path $PSScriptRoot 'common.ps1')
. (Join-Path $PSScriptRoot 'build-number.ps1')
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('nitroquake-build-id-test-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($scratch) | Out-Null
try {
    $output = Join-Path $scratch 'out'
    [IO.Directory]::CreateDirectory($output) | Out-Null
    $header = Join-Path $output 'nitroquake-build.h'
    $resolved = [pscustomobject]@{
        cpuTarget = 'i486'
        cpuModel = '486DX'
        fpuModel = '387-compatible'
        fpuRequired = $true
        floatingPointMode = '387'
        march = '-march=i486'
        mtune = '-mtune=i486'
        optimizationProfile = 'standard'
        optimizationLevel = '-O2'
        profileSuffix = ''
        outputRoot = $output
        executable = (Join-Path $output 'quake.exe')
        cFlags = @('-O2', '-march=i486')
        cSourceExtraFlags = [ordered]@{
            'host.c' = @('-include', (Join-Path $output 'nitroquake-build.h'))
        }
        asmFlags = @('-O2', '-march=i486')
        linkFlags = @('-lm', ('-Wl,-Map=' + (Join-Path $output 'quake.map')),
            '-o', (Join-Path $output 'quake.exe'))
        cSources = @('host.c')
        assemblySources = @('draw.s')
        includedCSources = @()
    }
    $first = New-NitroQuakeBuildIdentity -RepoRoot $repo -HeaderPath $header -Resolved $resolved
    $before = [IO.File]::ReadAllText($header)
    $second = New-NitroQuakeBuildIdentity -RepoRoot $repo -HeaderPath $header -Resolved $resolved
    if ($first.id -ne $second.id -or $first.number -ne $second.number -or
        $first.version -ne 'NitroQuake v0.999' -or $first.build -ne "Build $($first.id)" -or
        $before -ne [IO.File]::ReadAllText($header) -or
        $before -notmatch ('#define NITROQUAKE_BUILD_ID "' + [regex]::Escape($first.id) + '"') -or
        $first.number -ne ($first.inventory.accepted + $first.inventory.rejected) -or
        $first.inventory.status -ne 'complete' -or $first.inventory.complete -ne $true) {
        throw 'Repeated product identities, generated header, or full-history provenance disagree.'
    }
    if ($first.id -notmatch '^[0-9a-f]{12}-[0-9a-f]{12}$' -or
        $first.sourceRevision -notmatch '^[0-9a-f]{40,64}$') {
        throw 'Build identity does not contain the abbreviated source revision and fingerprint.'
    }

    $movedOutput = Join-Path $scratch 'moved-output'
    $resolved.outputRoot = $movedOutput
    $resolved.executable = Join-Path $movedOutput 'quake.exe'
    $resolved.cSourceExtraFlags['host.c'] = @('-include', (Join-Path $movedOutput 'nitroquake-build.h'))
    $resolved.linkFlags = @('-lm', ('-Wl,-Map=' + (Join-Path $movedOutput 'quake.map')),
        '-o', (Join-Path $movedOutput 'quake.exe'))
    $sameInputsAtMovedOutput = New-NitroQuakeBuildIdentity -RepoRoot $repo -HeaderPath $header -Resolved $resolved
    if ($sameInputsAtMovedOutput.id -ne $first.id) {
        throw 'Output paths changed an otherwise identical product identity.'
    }
    $resolved.cFlags += '-O3'
    $differentConfig = New-NitroQuakeBuildIdentity -RepoRoot $repo -HeaderPath $header -Resolved $resolved
    if ($differentConfig.id -eq $first.id) { throw 'Resolved compiler configuration did not change product identity.' }

    $fixture = Join-Path $scratch 'fixture'
    $shallow = Join-Path $scratch 'shallow'
    foreach ($directory in @('src', 'tools', 'docs/ledger')) {
        [IO.Directory]::CreateDirectory((Join-Path $fixture $directory)) | Out-Null
    }
    [IO.File]::WriteAllText((Join-Path $fixture 'src/main.c'), "int fixture_source;`n", [Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $fixture 'tools/optimization-history-legacy.json'),
        '{"schemaVersion":1,"records":{},"supersededDocuments":{}}', [Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $fixture 'docs/ledger/one-promoted.md'),
        "# Accepted fixture`n", [Text.Encoding]::ASCII)
    & git -C $fixture init -q
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the shallow-clone identity fixture.' }
    & git -C $fixture -c user.name=Fixture -c user.email=fixture@example.invalid add .
    if ($LASTEXITCODE -ne 0) { throw 'Could not stage the shallow-clone identity fixture.' }
    & git -C $fixture -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'Identity fixture'
    if ($LASTEXITCODE -ne 0) { throw 'Could not commit the shallow-clone identity fixture.' }
    $fixtureUri = ([Uri]::new([IO.Path]::GetFullPath($fixture))).AbsoluteUri
    & git clone -q --depth=1 --no-hardlinks $fixtureUri $shallow
    if ($LASTEXITCODE -ne 0) { throw 'Could not create the shallow-clone identity fixture.' }
    [IO.Directory]::CreateDirectory((Join-Path $shallow 'out')) | Out-Null
    $shallowResolved = [pscustomobject]@{
        outputRoot = (Join-Path $shallow 'out')
        profileSuffix = ''
        executable = (Join-Path $shallow 'out/quake.exe')
        cFlags = @('-O2')
        asmFlags = @('-O2')
        cSourceExtraFlags = @{}
        linkFlags = @('-lm')
    }
    $shallowIdentity = New-NitroQuakeBuildIdentity -RepoRoot $shallow `
        -HeaderPath (Join-Path $shallow 'out/nitroquake-build.h') -Resolved $shallowResolved
    $shallowHeader = [IO.File]::ReadAllText((Join-Path $shallow 'out/nitroquake-build.h'))
    if ($shallowIdentity.inventory.status -ne 'unavailable' -or
        $shallowIdentity.inventory.reason -ne 'incomplete-history' -or
        $null -ne $shallowIdentity.number -or $shallowIdentity.inventory.complete -ne $false -or
        $shallowIdentity.id -notmatch '^[0-9a-f]{12}-[0-9a-f]{12}$' -or
        $shallowHeader -notmatch ('#define NITROQUAKE_BUILD_ID "' + [regex]::Escape($shallowIdentity.id) + '"')) {
        throw 'Shallow history prevented product identity generation or produced misleading attempt counts.'
    }
    $unavailableInventory = Get-Content -LiteralPath (Join-Path $shallow 'out/optimization-inventory.json') -Raw | ConvertFrom-Json
    if ($unavailableInventory.status -ne 'unavailable' -or $null -ne $unavailableInventory.buildNumber) {
        throw 'Shallow inventory output does not record its unavailable status.'
    }

    Write-Host "Source/configuration build identity PASS: $($first.build); shallow provenance remains optional."
} finally {
    $full = [IO.Path]::GetFullPath($scratch)
    if ([IO.Path]::GetDirectoryName($full) -ne [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') -or
        [IO.Path]::GetFileName($full) -notmatch '^nitroquake-build-id-test-[0-9a-f]{32}$') {
        throw "Refusing test cleanup outside its temporary directory: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
}

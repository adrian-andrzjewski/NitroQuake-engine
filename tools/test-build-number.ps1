[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
& python (Join-Path $PSScriptRoot 'test-optimization-history.py')
if ($LASTEXITCODE -ne 0) { throw 'Optimization-history contract tests failed.' }
. (Join-Path $PSScriptRoot 'build-number.ps1')
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$scratch = Join-Path ([IO.Path]::GetTempPath()) ('nitroquake-build-number-test-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($scratch) | Out-Null
try {
    $header = Join-Path $scratch 'identity.h'
    $first = New-NitroQuakeBuildIdentity -RepoRoot $repo -HeaderPath $header
    $before = [IO.File]::ReadAllText($header)
    $second = New-NitroQuakeBuildIdentity -RepoRoot $repo -HeaderPath $header
    if ($first.number -ne $second.number -or $first.version -ne 'NitroQuake v0.999' -or
        $first.build -ne "Build $($first.number)" -or
        $before -ne [IO.File]::ReadAllText($header) -or
        $before -notmatch "#define NITROQUAKE_BUILD_NUMBER $($first.number)" -or
        $first.number -ne ($first.inventory.accepted + $first.inventory.rejected)) {
        throw 'Repeated build identities or generated header disagree with the inventory.'
    }
    Write-Host "History-derived build identity PASS: $($first.version), $($first.build)."
} finally {
    $full = [IO.Path]::GetFullPath($scratch)
    if ([IO.Path]::GetDirectoryName($full) -ne [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') -or
        [IO.Path]::GetFileName($full) -notmatch '^nitroquake-build-number-test-[0-9a-f]{32}$') {
        throw "Refusing test cleanup outside its temporary directory: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
}

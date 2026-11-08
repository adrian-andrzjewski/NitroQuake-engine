Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'build-number.ps1')

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('nitroquake-build-number-test-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($scratch) | Out-Null
try {
    $state = Join-Path $scratch 'state'
    if ((Get-NextNitroQuakeBuildNumber $state) -ne 1 -or
        (Get-NextNitroQuakeBuildNumber $state) -ne 2) { throw 'Counter did not advance.' }

    # Independent processes exercise the file lock and atomic update, including
    # first creation and contention. Every reserved identity must be unique.
    $worker = Join-Path $scratch 'worker.ps1'
    @'
param($Helper, $State, $Result)
$ErrorActionPreference = 'Stop'
. $Helper
$values = 1..12 | ForEach-Object { Get-NextNitroQuakeBuildNumber $State }
$values | Set-Content -LiteralPath $Result
'@ | Set-Content -LiteralPath $worker
    $helper = Join-Path $PSScriptRoot 'build-number.ps1'
    $processes = @(1..4 | ForEach-Object {
        $result = Join-Path $scratch "worker-$_.txt"
        Start-Process -FilePath (Join-Path $PSHOME 'pwsh.exe') -WindowStyle Hidden -PassThru `
            -ArgumentList @('-NoProfile', '-File', ('"' + $worker + '"'),
                ('"' + $helper + '"'), ('"' + $state + '"'), ('"' + $result + '"'))
    })
    foreach ($process in $processes) {
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw 'Concurrent counter worker failed.' }
    }
    $values = @(Get-ChildItem -LiteralPath $scratch -Filter 'worker-*.txt' |
        Get-Content | ForEach-Object { [int]$_ } | Sort-Object)
    if (($values -join ',') -ne ((3..50) -join ',')) { throw 'Concurrent identities were duplicated or lost.' }

    $counter = Join-Path $state 'nitroquake-build-number'
    [IO.File]::WriteAllText($counter, 'corrupt')
    $failed = $false
    try { Get-NextNitroQuakeBuildNumber $state | Out-Null } catch { $failed = $true }
    if (-not $failed -or [IO.File]::ReadAllText($counter) -ne 'corrupt') {
        throw 'Invalid state was silently reset.'
    }

    $archive = Join-Path $scratch 'archive'
    [IO.Directory]::CreateDirectory($archive) | Out-Null
    $header = Join-Path $archive 'build.h'
    $identity = New-NitroQuakeBuildIdentity -RepoRoot $archive -HeaderPath $header
    if ($identity.number -ne 1 -or $identity.version -ne 'NitroQuake v0.999+1' -or
        [IO.File]::ReadAllText($header) -notmatch '#define NITROQUAKE_BUILD_NUMBER 1') {
        throw 'Source-archive identity/header did not match.'
    }
    $repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $realCounter = Join-Path (Get-NitroQuakeBuildStateDirectory $repo) 'nitroquake-build-number'
    $before = if (Test-Path -LiteralPath $realCounter) { [IO.File]::ReadAllText($realCounter) } else { $null }
    & (Join-Path $PSScriptRoot 'build-dos.ps1') -DumpFlags | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'DumpFlags failed.' }
    $after = if (Test-Path -LiteralPath $realCounter) { [IO.File]::ReadAllText($realCounter) } else { $null }
    if ($before -ne $after) { throw 'DumpFlags consumed a build number.' }
    Write-Host 'Build numbering PASS: sequential and 48 concurrent reservations, corrupt-state rejection, source-archive header.'
} finally {
    # Only remove the exact uniquely named test directory under the temp root.
    $full = [IO.Path]::GetFullPath($scratch)
    if ([IO.Path]::GetDirectoryName($full) -ne [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') -or
        [IO.Path]::GetFileName($full) -notmatch '^nitroquake-build-number-test-[0-9a-f]{32}$') {
        throw "Refusing test cleanup outside its temporary directory: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
}

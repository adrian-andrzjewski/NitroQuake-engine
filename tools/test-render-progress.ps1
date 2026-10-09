<# Host-only checks for the timedemo progress stream used by render validation. #>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$timedemoPath = Join-Path $PSScriptRoot 'timedemo-dos.ps1'
$validationPath = Join-Path $PSScriptRoot 'render-validation-dos.ps1'
$timedemoSource = Get-Content -LiteralPath $timedemoPath -Raw
$validationSource = Get-Content -LiteralPath $validationPath -Raw

if (-not $timedemoSource.Contains('$progressFile = if ($FrameChecksums)')) {
    throw 'timedemo-dos.ps1 must enable file progress only when per-frame checksums are requested.'
}
if (-not $timedemoSource.Contains('-ProgressFile $progressFile')) {
    throw 'timedemo-dos.ps1 must pass the checksum log to Invoke-DosboxProcess.'
}
if (-not $validationSource.Contains('Invoke-StreamingTimedemo -Executable $pwshCommand.Source -Arguments $timedemoArgs')) {
    throw 'render-validation-dos.ps1 must use its streaming child wrapper.'
}
if (-not $validationSource.Contains('$childOutputText | Set-Content -LiteralPath (Join-Path $sceneOutput')) {
    throw 'render-validation-dos.ps1 must retain the streamed child transcript.'
}

$timedemoTokens = $null
$timedemoErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
    $timedemoPath, [ref]$timedemoTokens, [ref]$timedemoErrors)
if ($timedemoErrors.Count -gt 0) {
    throw "timedemo-dos.ps1 has parse errors: $timedemoErrors"
}
$tokens = $null
$parseErrors = $null
$validationAst = [Management.Automation.Language.Parser]::ParseFile(
    $validationPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) {
    throw "render-validation-dos.ps1 has parse errors: $parseErrors"
}
$streamFunctionAst = $validationAst.Find({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Invoke-StreamingTimedemo'
}, $true)
if ($null -eq $streamFunctionAst) {
    throw 'render-validation-dos.ps1 is missing Invoke-StreamingTimedemo.'
}
$streamFunctionText = $streamFunctionAst.Extent.Text
foreach ($contract in @(
        '2>&1 | ForEach-Object',
        '$outputLines.Add($line)',
        '$null = & $OnOutput $line',
        'Write-Host $Line')) {
    if (-not $streamFunctionText.Contains($contract)) {
        throw "Invoke-StreamingTimedemo is missing contract '$contract'."
    }
}

# Load the exact production helper from its parsed function definition, then
# prove that its output callback runs before the child finishes while its return
# value still contains the lines needed to find the timedemo result path.
. ([scriptblock]::Create($streamFunctionText))
$testShell = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $testShell) { $testShell = Get-Command powershell }

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('nq-render-progress-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
try {
    $childScriptPath = Join-Path $fixtureRoot 'progress-child.ps1'
    $donePath = Join-Path $fixtureRoot 'progress-child.done'
    $escapedDonePath = $donePath.Replace("'", "''")
    $childSource = @"
[Console]::Out.WriteLine('progress')
Start-Sleep -Milliseconds 750
[IO.File]::WriteAllText('$escapedDonePath', 'complete')
[Console]::Out.WriteLine('Timedemo result: fixture')
exit 23
"@
    [IO.File]::WriteAllText($childScriptPath, $childSource, [Text.Encoding]::ASCII)

    $state = @{
        lines = New-Object System.Collections.Generic.List[string]
        firstLineArrivedEarly = $false
    }
    $callback = {
        param($Line)
        $state.lines.Add([string]$Line)
        if ([string]$Line -eq 'progress') {
            $state.firstLineArrivedEarly = -not (Test-Path -LiteralPath $donePath)
        }
    }.GetNewClosure()

    $run = Invoke-StreamingTimedemo -Executable $testShell.Source `
        -Arguments @('-NoProfile', '-File', $childScriptPath) -OnOutput $callback
    if ($run.ExitCode -ne 23) { throw "Progress fixture exit code was $($run.ExitCode), expected 23." }
    if (-not $state.firstLineArrivedEarly) {
        throw 'The first child line was not forwarded before the child completed.'
    }
    if (-not (Test-Path -LiteralPath $donePath -PathType Leaf)) {
        throw 'The progress fixture child did not reach its completion marker.'
    }

    $capturedLines = @($run.Output | ForEach-Object { [string]$_ })
    $capturedText = $capturedLines -join [Environment]::NewLine
    if ($capturedLines.Count -ne 2 -or
            $capturedText -ne "progress$([Environment]::NewLine)Timedemo result: fixture" -or
            ($state.lines -join [Environment]::NewLine) -ne $capturedText) {
        throw 'The streamed output and retained transcript do not match.'
    }
}
finally {
    $resolvedFixtureRoot = [IO.Path]::GetFullPath($fixtureRoot)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolvedFixtureRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsafe progress-test cleanup path '$resolvedFixtureRoot'."
    }
    Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
}

Write-Host 'Timedemo progress streaming and transcript retention: PASS.'

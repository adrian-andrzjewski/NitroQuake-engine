[CmdletBinding()]
param(
    [switch]$Force,
    [string]$ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        throw 'Could not determine the Windows local application-data directory.'
    }
    $ToolRoot = Join-Path $localAppData '486quake\tools'
}

$ToolRoot = [IO.Path]::GetFullPath($ToolRoot)
$manifestPath = Join-Path $PSScriptRoot 'dos-toolchain.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

function ConvertTo-NativeRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return ($Path -replace '/', [IO.Path]::DirectorySeparatorChar)
}

function Assert-FileHash {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Expected
    )

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::OpenRead($Path)
        try {
            $digest = $algorithm.ComputeHash($stream)
        } finally {
            $stream.Dispose()
        }
    } finally {
        $algorithm.Dispose()
    }
    $actual = (-join ($digest | ForEach-Object { $_.ToString('x2') })).ToUpperInvariant()
    if ($actual -ne $Expected.ToUpperInvariant()) {
        throw "SHA-256 mismatch for '$Path'. Expected $Expected, got $actual."
    }
}

function Get-VerifiedArchive {
    param([Parameter(Mandatory = $true)]$Definition)

    $downloadRoot = Join-Path $ToolRoot 'downloads'
    New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null

    $archiveName = [IO.Path]::GetFileName(([Uri]$Definition.url).AbsolutePath)
    $archivePath = Join-Path $downloadRoot $archiveName

    if ($Force -and (Test-Path -LiteralPath $archivePath)) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    if (Test-Path -LiteralPath $archivePath) {
        Assert-FileHash -Path $archivePath -Expected $Definition.sha256
    } else {
        Write-Host "Downloading $archiveName"
        Invoke-WebRequest -UseBasicParsing -Uri $Definition.url -OutFile $archivePath
        Assert-FileHash -Path $archivePath -Expected $Definition.sha256
    }

    return $archivePath
}

function Install-ZipArtifact {
    param(
        [Parameter(Mandatory = $true)]$Definition,
        [Parameter(Mandatory = $true)][string]$ArchivePath
    )

    $installRoot = Join-Path $ToolRoot $Definition.installDirectory
    $expectedPath = Join-Path $installRoot (ConvertTo-NativeRelativePath $Definition.marker)

    if ((Test-Path -LiteralPath $expectedPath) -and (-not $Force)) {
        return $installRoot
    }

    if (Test-Path -LiteralPath $installRoot) {
        if (-not $Force) {
            throw "Incomplete installation exists at '$installRoot'. Re-run with -Force to replace it."
        }
        Remove-Item -LiteralPath $installRoot -Recurse -Force
    }

    $extractRoot = Join-Path $ToolRoot ('.extract-' + $Definition.installDirectory)
    if (Test-Path -LiteralPath $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $extractRoot -Force

    $archiveRoot = Join-Path $extractRoot (ConvertTo-NativeRelativePath $Definition.archiveRoot)
    if (-not (Test-Path -LiteralPath $archiveRoot)) {
        throw "Archive '$ArchivePath' does not contain '$($Definition.archiveRoot)'."
    }

    Move-Item -LiteralPath $archiveRoot -Destination $installRoot
    Remove-Item -LiteralPath $extractRoot -Recurse -Force
    return $installRoot
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Path $ToolRoot -Force | Out-Null

$djgppArchive = Get-VerifiedArchive -Definition $manifest.djgpp
$dosboxArchive = Get-VerifiedArchive -Definition $manifest.dosboxX
$djgppRoot = Install-ZipArtifact -Definition $manifest.djgpp -ArchivePath $djgppArchive
$dosboxRoot = Install-ZipArtifact -Definition $manifest.dosboxX -ArchivePath $dosboxArchive

$compilerPath = Join-Path $djgppRoot (ConvertTo-NativeRelativePath $manifest.djgpp.compiler)
$objdumpPath = Join-Path $djgppRoot (ConvertTo-NativeRelativePath $manifest.djgpp.objdump)
$dosboxPath = Join-Path $dosboxRoot (ConvertTo-NativeRelativePath $manifest.dosboxX.executable)

foreach ($requiredPath in @($compilerPath, $objdumpPath, $dosboxPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Bootstrap completed but required tool is missing: '$requiredPath'."
    }
}

Write-Host "DJGPP root: $djgppRoot"
Write-Host "DOSBox-X:   $dosboxPath"
Write-Host 'Toolchain bootstrap complete.'

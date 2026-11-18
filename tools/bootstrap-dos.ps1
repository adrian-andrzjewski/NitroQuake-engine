[CmdletBinding()]
param(
    [switch]$Force,
    [string]$ToolRoot,
    [string]$ManifestPath
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
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $PSScriptRoot 'dos-toolchain.json'
}
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

function Assert-ArtifactPath {
    param([Parameter(Mandatory)][string]$Path, [switch]$Mutation)
    $full = [IO.Path]::GetFullPath($Path)
    $prefix = $ToolRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Artifact path escapes the tool installation root: $full"
    }
    if ($Mutation) {
        $current = $full
        while ($current -ne $ToolRoot) {
            if ((Test-Path -LiteralPath $current) -and
                ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Refusing to mutate a redirected artifact path: $current"
            }
            $current = [IO.Path]::GetDirectoryName($current)
        }
    }
}

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

    $expected = $null
    if ($Definition.PSObject.Properties.Name -contains 'sha256') {
        $expected = [string]$Definition.sha256
    }
    if ([string]::IsNullOrWhiteSpace($expected)) {
        throw "No pinned sha256 for '$($Definition.url)'. Pin it in '$ManifestPath' before installing this tool."
    }

    $downloadRoot = Join-Path $ToolRoot 'downloads'
    New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null

    $archiveName = [IO.Path]::GetFileName(([Uri]$Definition.url).AbsolutePath)
    $archivePath = Join-Path $downloadRoot $archiveName
    Assert-ArtifactPath -Path $archivePath

    if ($Force -and (Test-Path -LiteralPath $archivePath)) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    if (Test-Path -LiteralPath $archivePath) {
        Assert-FileHash -Path $archivePath -Expected $expected
    }
    else {
        Write-Host "Downloading $archiveName"
        Invoke-WebRequest -UseBasicParsing -Uri $Definition.url -OutFile $archivePath
        Assert-FileHash -Path $archivePath -Expected $expected
    }

    return $archivePath
}

function Install-ZipArtifact {
    param(
        [Parameter(Mandatory = $true)]$Definition,
        [Parameter(Mandatory = $true)][string]$ArchivePath
    )

    $installRoot = Join-Path $ToolRoot $Definition.installDirectory
    Assert-ArtifactPath -Path $installRoot
    $expectedPath = Join-Path $installRoot (ConvertTo-NativeRelativePath $Definition.marker)

    if ((Test-Path -LiteralPath $expectedPath) -and (-not $Force)) {
        return $installRoot
    }

    if (Test-Path -LiteralPath $installRoot) {
        if (-not $Force) {
            throw "Incomplete installation exists at '$installRoot'. Re-run with -Force to replace it."
        }
        Assert-ArtifactPath -Path $installRoot -Mutation
        Remove-Item -LiteralPath $installRoot -Recurse -Force
    }

    $extractRoot = Join-Path $ToolRoot ('.extract-' + $Definition.installDirectory)
    Assert-ArtifactPath -Path $extractRoot -Mutation
    if (Test-Path -LiteralPath $extractRoot) {
        Remove-Item -LiteralPath $extractRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $extractRoot -Force

    # An empty archiveRoot means the archive's own top level is the install
    # root, so move the extraction directory itself rather than a subdirectory
    # of it.
    if ([string]::IsNullOrWhiteSpace([string]$Definition.archiveRoot)) {
        $archiveRoot = $extractRoot
    }
    else {
        $archiveRoot = Join-Path $extractRoot (ConvertTo-NativeRelativePath $Definition.archiveRoot)
    }
    if (-not (Test-Path -LiteralPath $archiveRoot)) {
        throw "Archive '$ArchivePath' does not contain '$($Definition.archiveRoot)'."
    }

    Assert-ArtifactPath -Path $archiveRoot -Mutation
    Assert-ArtifactPath -Path $installRoot -Mutation
    Move-Item -LiteralPath $archiveRoot -Destination $installRoot
    Assert-ArtifactPath -Path $extractRoot -Mutation
    Remove-Item -LiteralPath $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
    return $installRoot
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Path $ToolRoot -Force | Out-Null

foreach ($artifact in $manifest.PSObject.Properties) {
    $definition = $artifact.Value
    $archive = Get-VerifiedArchive -Definition $definition
    $installed = Install-ZipArtifact -Definition $definition -ArchivePath $archive
    $required = @([string]$definition.marker)
    foreach ($field in @('compiler', 'objdump', 'executable')) {
        if ($definition.PSObject.Properties.Name -contains $field) { $required += [string]$definition.$field }
    }
    foreach ($relative in @($required | Select-Object -Unique)) {
        $requiredPath = Join-Path $installed (ConvertTo-NativeRelativePath $relative)
        Assert-ArtifactPath -Path $requiredPath
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Bootstrap completed but required tool is missing: '$requiredPath'."
        }
    }
    Write-Host "$($artifact.Name): $installed"
}

# The strict startup ISA proof rebuilds the exact DJGPP 2.05 loader and CRT
# helpers. Keep this upstream source archive in the local download cache rather
# than vendoring a third-party package in the repository.
$runtimeManifestPath = Join-Path $PSScriptRoot 'isa-runtime-reference/manifest.json'
$runtimeManifest = Get-Content -LiteralPath $runtimeManifestPath -Raw | ConvertFrom-Json
$startupSources = @($runtimeManifest.sources | Where-Object {
        $sourceUrl = $_.PSObject.Properties['sourceUrl']
        $null -ne $sourceUrl -and
        -not [string]::IsNullOrWhiteSpace([string]$sourceUrl.Value) -and
        [IO.Path]::GetFileName(([Uri]$sourceUrl.Value).AbsolutePath) -eq 'djlsr205.zip'
    })
if ($startupSources.Count -ne 1) {
    throw "Expected one pinned djlsr205.zip source entry in '$runtimeManifestPath'."
}
$startupSource = $startupSources[0]
$startupDefinition = [pscustomobject]@{
    url = [string]$startupSource.PSObject.Properties['sourceUrl'].Value
    sha256 = [string]$startupSource.sha256
}
$startupArchive = Get-VerifiedArchive -Definition $startupDefinition
if ([int64](Get-Item -LiteralPath $startupArchive).Length -ne [int64]$startupSource.bytes) {
    throw "Size mismatch for pinned startup source archive '$startupArchive'."
}
Write-Host "startup source: $startupArchive"
Write-Host 'Toolchain bootstrap complete.'

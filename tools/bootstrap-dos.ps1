[CmdletBinding()]
param(
    [switch]$Force,
    [string]$ToolRoot,
    # Also fetch the optional PCem cycle-accurate 486 reference. It is the
    # 486-cost gate, but DOSBox-X remains the parity gate, so a machine without
    # it can still build, benchmark, and time the demo.
    [switch]$WithPcem,
    # Print the SHA-256 of the PCem archive so it can be pinned in the manifest.
    # Required before any candidate is promoted on PCem cycles.
    [switch]$RecordPcemHash
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
    param(
        [Parameter(Mandatory = $true)]$Definition,
        # An unpinned definition is fetched and hashed but not verified against a
        # constant. Only for first-fetch hash recording; a tool that gates a
        # promotion must be pinned in the manifest.
        [switch]$AllowUnpinned
    )

    $expected = $null
    if ($Definition.PSObject.Properties.Name -contains 'sha256') {
        $expected = [string]$Definition.sha256
    }
    if ([string]::IsNullOrWhiteSpace($expected)) {
        if (-not $AllowUnpinned) {
            throw "No pinned sha256 for '$($Definition.url)'. Pin it in the manifest, or pass -AllowUnpinned to record the hash on first fetch."
        }
        $expected = $null
    }

    $downloadRoot = Join-Path $ToolRoot 'downloads'
    New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null

    $archiveName = [IO.Path]::GetFileName(([Uri]$Definition.url).AbsolutePath)
    $archivePath = Join-Path $downloadRoot $archiveName

    if ($Force -and (Test-Path -LiteralPath $archivePath)) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    if (Test-Path -LiteralPath $archivePath) {
        if ($null -ne $expected) {
            Assert-FileHash -Path $archivePath -Expected $expected
        }
    } else {
        Write-Host "Downloading $archiveName"
        Invoke-WebRequest -UseBasicParsing -Uri $Definition.url -OutFile $archivePath
        if ($null -ne $expected) {
            Assert-FileHash -Path $archivePath -Expected $expected
        }
        else {
            Write-Warning "Downloaded $archiveName with no pinned hash. Record it with -RecordPcemHash before trusting this tool."
        }
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

    Move-Item -LiteralPath $archiveRoot -Destination $installRoot
    Remove-Item -LiteralPath $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
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

if ($WithPcem -or $RecordPcemHash) {
    if ($null -eq $manifest.pcem) {
        throw 'The toolchain manifest has no "pcem" block.'
    }
    $pcemArchive = Get-VerifiedArchive -Definition $manifest.pcem -AllowUnpinned
    if ($RecordPcemHash) {
        Write-Host ''
        Write-Host "PCem archive:  $pcemArchive"
        Write-Host "PCem SHA-256:  $((Get-FileHash -LiteralPath $pcemArchive -Algorithm SHA256).Hash)"
        Write-Host 'Pin that value as "pcem"."sha256" in tools\dos-toolchain.json before promoting on PCem cycles.'
    }
    $pcemRoot = Install-ZipArtifact -Definition $manifest.pcem -ArchivePath $pcemArchive
    $pcemPath = Join-Path $pcemRoot (ConvertTo-NativeRelativePath $manifest.pcem.executable)
    if (-not (Test-Path -LiteralPath $pcemPath -PathType Leaf)) {
        throw "Bootstrap completed but PCem is missing: '$pcemPath'."
    }
    Write-Host "PCem:         $pcemPath"
}
else {
    Write-Host 'PCem:         not installed (pass -WithPcem to add the 486-cost gate)'
}

# ---------------------------------------------------------------------------
# 486-cost gate readiness: the gate also needs the ROM set wired and a clean
# DOS floppy, neither of which this script installs. Report both so a fresh
# machine can see what is still missing before 486-fidelity.ps1 -Emulator pcem.
# ---------------------------------------------------------------------------
if ($null -ne $manifest.pcemRomset) {
    $romsetPath = [IO.Path]::GetFullPath([string]$manifest.pcemRomset.path)
    $biosFile = Join-Path $romsetPath (([string]$manifest.pcemRomset.bios) -replace '/', '\')
    if ((Test-Path -LiteralPath $biosFile -PathType Leaf) -and
        (Get-Item -LiteralPath $biosFile).Length -eq [int]$manifest.pcemRomset.expectedBiosBytes) {
        Write-Host "PCem ROM set:  $romsetPath ($($manifest.pcemRomset.machine) BIOS found)"
    }
    else {
        Write-Host 'PCem ROM set:  NOT WIRED (pass .\tools\pcem-roms.ps1)'
    }
}
if ($null -ne $manifest.dosImage) {
    $dosImagePath = [IO.Path]::GetFullPath([string]$manifest.dosImage.path)
    if (-not (Test-Path -LiteralPath $dosImagePath -PathType Leaf)) {
        Write-Host "DOS image:     NOT FOUND ($dosImagePath)"
    }
    elseif ((Get-FileHash -LiteralPath $dosImagePath -Algorithm SHA256).Hash -ne
        ([string]$manifest.dosImage.sha256).ToUpperInvariant()) {
        Write-Host "DOS image:     HASH MISMATCH ($dosImagePath)"
    }
    else {
        Write-Host "DOS image:     $dosImagePath (hash OK)"
    }
}

Write-Host 'Toolchain bootstrap complete.'

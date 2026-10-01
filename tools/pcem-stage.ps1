<#
.SYNOPSIS
    Builds the PCem guest media for a 486-cost gate run: a bootable raw FAT16
    hard-disk image with MS-DOS 6.22, the benchmark, the DPMI host and the
    id1 data. No floppy is involved.

.DESCRIPTION
    PCem has no script argument: the run is driven entirely from inside the
    guest. The machine boots C: through a two-stage chain written by
    New-Fat16HardDiskImage:

      MBR    chain-loads the partition boot sector to 0000:4000
      VBR    implements the exact MS-DOS 6.22 boot contract (disassembled
             from Dos6.22.img's own boot sector): verify root entry0=IO.SYS
             and entry1=MSDOS.SYS, load IO.SYS's first 3 sectors to 0000:0700,
             copy the VBR to 0000:7C00, then jmp 0070:0000 with the registers
             IO.SYS expects (CH=media, DL=drive 80h, BX=dataStart).

    DOS lives entirely on C:. Root write order is the boot contract, not
    style: IO.SYS, MSDOS.SYS, COMMAND.COM must be the first three root
    entries (the VBR checks the first two; DOS documentation requires the
    first three), and writing IO.SYS first also lands it contiguous at
    cluster 2, exactly as FORMAT /S would place it.

    Dos6.22.img remains the hash-verified *source* of four binaries
    (IO.SYS, MSDOS.SYS, COMMAND.COM, HIMEM.SYS) and is never modified.

    CONFIG.SYS is generated fresh (HIMEM for the XMS that CWSDPMI needs;
    the floppy's cd1.SYS/MSCDEX lines are dropped - the harness exposes no
    ATAPI device). AUTOEXEC.BAT runs the probes and writes the host-visible
    sentinel C:\DONE.TXT.

    Refuses to overwrite a staging directory that already holds the image,
    for the same reason 486-fidelity.ps1 refuses to overwrite its run dir.

.EXAMPLE
    .\tools\pcem-stage.ps1 -BenchmarkExe out\djgpp\qbench.exe
#>
[CmdletBinding()]
param(
    # Directory that will hold dos.hdd. Defaults to a new
    # out\pcem-<timestamp> directory.
    [string]$StagingRoot,

    [Parameter(Mandatory = $true)]
    [string]$BenchmarkExe,

    [string]$DataRoot,
    [string]$Cwsdpmi,

    [string]$ManifestPath,

    # Geometry of dos.hdd. 486-fidelity.ps1 must be told the same numbers;
    # it reads them back from this script's output rather than restating them.
    [int]$Cylinders = 130,
    [int]$Heads = 16,
    [int]$SectorsPerTrack = 63,

    # Guest directory that receives the benchmark. 8.3, no leading slash.
    [ValidatePattern('^[A-Za-z0-9_]{1,8}$')]
    [string]$QuakeDir = 'QUAKE',

    # The guest's benchmark command. '+bench486 -benchfidelity' runs the
    # correctness probes and is what 486-fidelity.ps1 needs; the timedemo
    # command omits -benchfidelity because bench486-dos.ps1 gates on the
    # framebuffer checksum and frame count instead. The image is the same
    # either way - only the command line on AUTOEXEC.BAT differs - so the boot
    # contract stays in this one script.
    [ValidateSet('fidelity', 'timedemo')]
    [string]$BenchMode = 'fidelity'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $PSScriptRoot 'dos-toolchain.json'
}
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($null -eq $manifest.dosImage) {
    throw "The toolchain manifest has no 'dosImage' block; it records the DOS floppy this script reads from."
}
if ($null -eq $manifest.pcemRomset) {
    throw "The toolchain manifest has no 'pcemRomset' block; it records the machine this script targets."
}

Import-Module (Join-Path $PSScriptRoot 'FatImage.psm1') -Force

# ---------------------------------------------------------------------------
# Resolve every input before touching the staging directory, so a bad path
# fails without leaving half-built images behind.
# ---------------------------------------------------------------------------
$dosImage = [IO.Path]::GetFullPath([string]$manifest.dosImage.path)
if (-not (Test-Path -LiteralPath $dosImage -PathType Leaf)) {
    throw "DOS floppy '$dosImage' not found (dosImage.path in '$ManifestPath')."
}
$expectedBytes = [int]$manifest.dosImage.expectedBytes
$actualBytes = (Get-Item -LiteralPath $dosImage).Length
if ($actualBytes -ne $expectedBytes) {
    throw "DOS floppy '$dosImage' is $actualBytes bytes; expected $expectedBytes."
}
$expectedHash = ([string]$manifest.dosImage.sha256).ToUpperInvariant()
$actualHash = (Get-FileHash -LiteralPath $dosImage -Algorithm SHA256).Hash
if ($actualHash -ne $expectedHash) {
    throw "DOS floppy '$dosImage' has SHA-256 $actualHash; manifest records $expectedHash. Refusing to stage a tampered image."
}

$BenchmarkExe = [IO.Path]::GetFullPath($BenchmarkExe)
if (-not (Test-Path -LiteralPath $BenchmarkExe -PathType Leaf)) {
    throw "Benchmark executable was not found: '$BenchmarkExe'."
}
if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $repoRoot 'testdata\id1'
}
$DataRoot = [IO.Path]::GetFullPath($DataRoot)
$pak0 = Get-ChildItem -LiteralPath $DataRoot -Filter 'pak0.pak' -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($null -eq $pak0) {
    throw "'$DataRoot' must contain pak0.pak. Game data is intentionally not in Git. Pass -DataRoot."
}
if ([string]::IsNullOrWhiteSpace($Cwsdpmi)) {
    $Cwsdpmi = Join-Path $repoRoot 'WinQuake\cwsdpmi.exe'
}
$Cwsdpmi = [IO.Path]::GetFullPath($Cwsdpmi)
if (-not (Test-Path -LiteralPath $Cwsdpmi -PathType Leaf)) {
    throw "CWSDPMI binary missing: '$Cwsdpmi'. The DJGPP stub needs it beside the EXE to reach protected mode."
}

# ---------------------------------------------------------------------------
# Staging directory.
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($StagingRoot)) {
    $StagingRoot = Join-Path (Join-Path $repoRoot 'out') (
        'pcem-' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))
}
$StagingRoot = [IO.Path]::GetFullPath($StagingRoot)
$hddImg = Join-Path $StagingRoot 'dos.hdd'
if (Test-Path -LiteralPath $hddImg) {
    throw "Staging path already exists; refusing to overwrite '$hddImg'."
}
New-Item -ItemType Directory -Path $StagingRoot -Force | Out-Null

# ---------------------------------------------------------------------------
# dos.hdd: MBR + VBR loader + FAT16 partition + DOS + payload.
# ---------------------------------------------------------------------------
$geometry = New-Fat16HardDiskImage -Path $hddImg `
    -Cylinders $Cylinders -Heads $Heads -SectorsPerTrack $SectorsPerTrack
$partition = Get-FatPartitionOffset -Path $hddImg
$partOffset = [int]$partition.Offset

# Boot-critical bytes, checked directly: the host-side FAT reader never
# looks at signatures or the extended BPB, so a defect here passes every
# readback below while the guest refuses to boot or refuses to mount C:.
$stream = [IO.File]::Open($hddImg, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
try {
    $hdr = New-Object byte[] 512
    [void]$stream.Seek(0, [IO.SeekOrigin]::Begin)
    [void]$stream.Read($hdr, 0, 512)
    if ($hdr[510] -ne 0x55 -or $hdr[511] -ne 0xAA) {
        throw "MBR lacks the 0x55AA signature."
    }
    # MBR stub regression guard: mov dx,0x0180 / mov bx,0x4000 at fixed offsets.
    if ($hdr[0x12] -ne 0xBA -or $hdr[0x13] -ne 0x80 -or $hdr[0x14] -ne 0x01) {
        throw "MBR stub INT13 drive/head bytes wrong at 0x12 (want BA 80 01, got $('{0:X2} {1:X2} {2:X2}' -f $hdr[0x12], $hdr[0x13], $hdr[0x14]))."
    }
    if ($hdr[0x15] -ne 0xBB -or $hdr[0x16] -ne 0x00 -or $hdr[0x17] -ne 0x40) {
        throw "MBR stub load-target bytes wrong at 0x15 (want BB 00 40)."
    }
    $vbrHdr = New-Object byte[] 512
    [void]$stream.Seek($partOffset, [IO.SeekOrigin]::Begin)
    [void]$stream.Read($vbrHdr, 0, 512)
    if ($vbrHdr[510] -ne 0x55 -or $vbrHdr[511] -ne 0xAA) {
        throw "VBR lacks the 0x55AA signature; DOS will not mount C:."
    }
    if ($vbrHdr[0x24] -ne 0x80) {
        throw "VBR drive number at 0x24 is 0x$('{0:X2}' -f $vbrHdr[0x24]); must be 0x80 (IO.SYS receives it as DL)."
    }
    if ($vbrHdr[0x26] -ne 0x29) {
        throw "VBR extended boot signature at 0x26 is 0x$('{0:X2}' -f $vbrHdr[0x26]); must be 0x29."
    }
}
finally {
    $stream.Dispose()
}

# ---------------------------------------------------------------------------
# Install DOS on C:. Write order IS the boot contract: root entry0 must be
# IO.SYS (the VBR checks it), entry1 MSDOS.SYS, entry2 COMMAND.COM - and
# writing IO.SYS first lands it contiguous at cluster 2 like FORMAT /S.
# ---------------------------------------------------------------------------
$ascii = [Text.Encoding]::ASCII
$systemFiles = @(
    @{ Name = 'IO.SYS';     Attribute = 0x27 },   # hidden+system+archive
    @{ Name = 'MSDOS.SYS';  Attribute = 0x27 },
    @{ Name = 'COMMAND.COM'; Attribute = 0x20 },
    @{ Name = 'HIMEM.SYS';  Attribute = 0x20 }    # XMS for CWSDPMI (CONFIG.SYS)
)
foreach ($sys in $systemFiles) {
    $src = Read-FatImageFile -Path $dosImage -Name $sys.Name
    Set-FatImageFile -Path $hddImg -Name $sys.Name -Content $src `
        -Offset $partOffset -Attribute $sys.Attribute
    Write-Host ("staged {0,-12} {1,10:N0} bytes (attr 0x{2:X2})" -f $sys.Name, $src.Length, $sys.Attribute)
}

# Generated CONFIG.SYS: fresh - the floppy's cd1.SYS/MSCDEX lines assume an
# ATAPI device this harness deliberately does not expose. HIMEM first so
# CWSDPMI gets XMS.
$configSys = @(
    'DEVICE=C:\HIMEM.SYS /testmem:off',
    'FILES=30',
    'BUFFERS=20',
    'LASTDRIVE=Z',
    ''
) -join "`r`n"
Set-FatImageFile -Path $hddImg -Name 'CONFIG.SYS' -Content $ascii.GetBytes($configSys) -Offset $partOffset

# Generated AUTOEXEC.BAT: boot drive is already C:.
$benchCommand = if ($BenchMode -eq 'fidelity') {
    "QBENCH.EXE -basedir C:\$QuakeDir -nosound -nojoy -nomouse -nocdaudio +bench486 -benchfidelity -benchexit"
}
else {
    "QBENCH.EXE -basedir C:\$QuakeDir -nosound -nojoy -nomouse -nocdaudio +bench486 -benchexit"
}
$autoexec = @(
    '@echo off',
    "CD \$QuakeDir",
    $benchCommand,
    'ECHO DONE> C:\DONE.TXT',
    ''
) -join "`r`n"
Set-FatImageFile -Path $hddImg -Name 'AUTOEXEC.BAT' -Content $ascii.GetBytes($autoexec) -Offset $partOffset
Write-Host "staged CONFIG.SYS + AUTOEXEC.BAT (generated, bench mode: $BenchMode)"

# ---------------------------------------------------------------------------
# Payload.
# ---------------------------------------------------------------------------
$payload = @(
    @{ Name = "$QuakeDir\QBENCH.EXE"; Path = $BenchmarkExe },
    @{ Name = "$QuakeDir\CWSDPMI.EXE"; Path = $Cwsdpmi },
    @{ Name = "$QuakeDir\ID1\PAK0.PAK"; Path = $pak0.FullName }
)
foreach ($file in $payload) {
    $bytes = [IO.File]::ReadAllBytes($file.Path)
    Set-FatImageFile -Path $hddImg -Name $file.Name -Content $bytes -Offset $partOffset
    Write-Host ("staged {0,-24} {1,10:N0} bytes" -f $file.Name, $bytes.Length)
}

# ---------------------------------------------------------------------------
# Read-back verification through the same reader the host-side poll loop
# uses, plus the layout assertions that are the boot contract itself. A
# defect here must fail now, not six minutes into an emulated boot.
# ---------------------------------------------------------------------------
$root = Get-FatImageRoot -Path $hddImg -Offset $partOffset
$entries = @($root.Entries)
$expectedOrder = @('IO.SYS', 'MSDOS.SYS', 'COMMAND.COM')
for ($i = 0; $i -lt $expectedOrder.Count; $i++) {
    if ($entries.Count -le $i -or $entries[$i].Name -ne $expectedOrder[$i]) {
        $got = ($entries | ForEach-Object Name) -join ', '
        throw "Root entry $i must be '$($expectedOrder[$i])' (the VBR checks entries 0-1; DOS requires the first three). Got: $got"
    }
}
if ([int]$entries[0].StartCluster -ne 2) {
    throw "IO.SYS starts at cluster $($entries[0].StartCluster); the boot contract needs cluster 2 (write IO.SYS first on a fresh image)."
}

foreach ($sys in $systemFiles) {
    $readBack = Read-FatImageFile -Path $hddImg -Name $sys.Name -Offset $partOffset
    $source = Read-FatImageFile -Path $dosImage -Name $sys.Name
    if ($readBack.Length -ne $source.Length) {
        throw "Read-back of '$($sys.Name)' is $($readBack.Length) bytes; source is $($source.Length)."
    }
    for ($b = 0; $b -lt 8; $b++) {
        if ($readBack[$b] -ne $source[$b]) {
            throw "Read-back of '$($sys.Name)' differs from source at byte $b."
        }
    }
}
foreach ($file in $payload) {
    $readBack = Read-FatImageFile -Path $hddImg -Name $file.Name -Offset $partOffset
    if ($readBack.Length -ne (Get-Item -LiteralPath $file.Path).Length) {
        throw "Read-back of '$($file.Name)' from dos.hdd is $($readBack.Length) bytes; expected $((Get-Item -LiteralPath $file.Path).Length)."
    }
}
if (-not (Test-FatImageFile -Path $hddImg -Name 'CONFIG.SYS' -Offset $partOffset) -or
    -not (Test-FatImageFile -Path $hddImg -Name 'AUTOEXEC.BAT' -Offset $partOffset)) {
    throw 'CONFIG.SYS or AUTOEXEC.BAT missing from the image after write.'
}

Write-Host ''
Write-Host "dos.hdd   $hddImg  ($($geometry.Bytes) bytes, FAT16 at LBA $($partition.LbaStart), type 0x$('{0:X2}' -f $partition.Type))"
Write-Host "root[0..2]: $($expectedOrder -join ' / ')  (IO.SYS at cluster $($entries[0].StartCluster))"

[pscustomobject]@{
    StagingRoot     = $StagingRoot
    HardDisk        = $hddImg
    PartitionOffset = $partOffset
    Cylinders       = $Cylinders
    Heads           = $Heads
    SectorsPerTrack = $SectorsPerTrack
    QuakeDir        = $QuakeDir
}

<#
.SYNOPSIS
    Minimal FAT12/FAT16 reader and writer for raw disk and floppy images.

.DESCRIPTION
    PCem cannot mount a host directory the way DOSBox-X does, so the guest DOS
    environment has to be materialised inside an image file. This module is the
    only genuinely new code that requires: it reads the MS-DOS 6.22 FAT12
    floppy and synthesises a FAT16 hard-disk image, so the same primitives
    cover both.

    It deliberately does not implement deletion or long names. One level (and
    nested chains) of subdirectories IS implemented: the guest tree is
    \QUAKE\ID1\PAK0.PAK, and Quake will not look anywhere else.

    All readers open the image with read/write sharing, because the gate polls
    BENCH486.TXT out of the hard-disk image while PCem still holds it open
    (fopen "rb+" is deny-none on Windows; File.ReadAllBytes is not).

.NOTES
    Offsets in the BPB are fixed by the FAT spec: bytes/sector at 11,
    sectors/cluster at 13, reserved sectors at 14, FAT count at 16, root
    entries at 17, total sectors (16) at 19, media descriptor at 21,
    sectors/FAT at 22, sectors/track at 24, heads at 26, hidden sectors at 28,
    total sectors (32) at 32.

    NO [byte[]] PARAMETER MAY BE marked [Parameter(Mandatory = $true)]. The
    binder's emptiness check for mandatory collection parameters enumerates
    the whole array: ~6 seconds per call on a 64 MiB disk image, paid on every
    single call, which turns staging into a multi-minute hang. Callers always
    pass these arguments; the type constraint alone is the contract.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Bpb {
    param([byte[]]$Buffer, [int]$Offset = 0)

    $b = [byte[]]$Buffer.Clone()
    $info = [ordered]@{
        BytesPerSector    = [BitConverter]::ToUInt16($b, $Offset + 11)
        SectorsPerCluster = $b[$Offset + 13]
        ReservedSectors   = [BitConverter]::ToUInt16($b, $Offset + 14)
        NumFats           = $b[$Offset + 16]
        RootEntries       = [BitConverter]::ToUInt16($b, $Offset + 17)
        TotalSectors16    = [BitConverter]::ToUInt16($b, $Offset + 19)
        MediaDescriptor   = $b[$Offset + 21]
        SectorsPerFat     = [BitConverter]::ToUInt16($b, $Offset + 22)
        SectorsPerTrack   = [BitConverter]::ToUInt16($b, $Offset + 24)
        Heads             = [BitConverter]::ToUInt16($b, $Offset + 26)
        HiddenSectors     = [BitConverter]::ToUInt32($b, $Offset + 28)
        TotalSectors32    = [BitConverter]::ToUInt32($b, $Offset + 32)
    }
    # The 16-bit total is zero on volumes above 32 MB; the 32-bit field is
    # authoritative when it is non-zero.
    if ($info.TotalSectors32 -ne 0) { $info.TotalSectors = [int]$info.TotalSectors32 }
    else { $info.TotalSectors = [int]$info.TotalSectors16 }
    return $info
}

function Get-FatGeometry {
    <#
    .SYNOPSIS
        Derive every offset the rest of the module needs from a parsed BPB.

    .PARAMETER VolumeOffset
        Absolute byte offset of the volume inside the image. Zero for a whole
        floppy; the partition offset for a hard-disk image. Every offset this
        function returns is absolute - callers index $Bytes with them
        directly. Returning volume-relative offsets (as an earlier draft did)
        silently misplaces the entire directory tree and every cluster by the
        partition offset: the host-side reader and writer agree with each
        other, so self-tests pass, while DOS reads the spec-correct location
        and sees an empty disk.
    #>
    param([Parameter(Mandatory = $true)]$Bpb, [int]$VolumeOffset = 0)

    $sectorSize   = [int]$Bpb.BytesPerSector
    $clusterSize  = $sectorSize * [int]$Bpb.SectorsPerCluster
    $fatOffset    = $VolumeOffset + ([int]$Bpb.ReservedSectors * $sectorSize)
    $fatSize      = [int]$Bpb.SectorsPerFat * $sectorSize
    $rootOffset   = $fatOffset + ([int]$Bpb.NumFats * $fatSize)
    $rootSize     = [int]$Bpb.RootEntries * 32
    $dataOffset   = $rootOffset + $rootSize
    $dataSectors  = [int]$Bpb.TotalSectors - [int]$Bpb.ReservedSectors - ([int]$Bpb.NumFats * [int]$Bpb.SectorsPerFat) - ([int]$Bpb.RootEntries * 32 / $sectorSize)
    $clusterCount = [int][math]::Floor($dataSectors / [int]$Bpb.SectorsPerCluster)

    # FAT12 covers clusters 0..4084, FAT16 starts at 4085. Decide from the
    # count rather than trusting a stored type byte.
    $fatType = if ($clusterCount -lt 4085) { 12 } else { 16 }

    [pscustomobject]@{
        Bpb          = $Bpb
        FatType      = $fatType
        SectorSize   = $sectorSize
        ClusterSize  = $clusterSize
        FatOffset    = $fatOffset
        FatSize      = $fatSize
        RootOffset   = $rootOffset
        RootSize     = $rootSize
        DataOffset   = $dataOffset
        DataSectors  = $dataSectors
        ClusterCount = $clusterCount
    }
}

function Get-FatEntry {
    param([byte[]]$Bytes, [int]$FatOffset, [int]$Cluster, [int]$FatType)

    if ($FatType -eq 12) {
        $o = $FatOffset + [int]([math]::Floor($Cluster * 3 / 2))
        $v = [BitConverter]::ToUInt16($Bytes, $o)
        if (($Cluster % 2) -eq 0) { return $v -band 0x0FFF }
        return ($v -shr 4) -band 0x0FFF
    }
    return [BitConverter]::ToUInt16($Bytes, $FatOffset + ($Cluster * 2))
}

function Set-FatEntry {
    param(
        [byte[]]$Bytes,
        [int]$FatOffset, [int]$Cluster, [int]$Value, [int]$FatType
    )

    if ($FatType -eq 12) {
        $o = $FatOffset + [int]([math]::Floor($Cluster * 3 / 2))
        $v = [BitConverter]::ToUInt16($Bytes, $o)
        if (($Cluster % 2) -eq 0) {
            $v = ($v -band 0xF000) -bor ($Value -band 0x0FFF)
        }
        else {
            $v = ($v -band 0x000F) -bor (($Value -band 0x0FFF) -shl 4)
        }
        $b = [BitConverter]::GetBytes([uint16]$v)
        $Bytes[$o] = $b[0]
        $Bytes[$o + 1] = $b[1]
        return
    }
    $b = [BitConverter]::GetBytes([uint16]$Value)
    $Bytes[$FatOffset + ($Cluster * 2)] = $b[0]
    $Bytes[$FatOffset + ($Cluster * 2) + 1] = $b[1]
}

function Get-FatChain {
    param([byte[]]$Bytes, $Geometry, [int]$FirstCluster, [int]$MaxClusters = 4000000)

    $chain = New-Object System.Collections.Generic.List[int]
    if ($FirstCluster -lt 2) { return $chain }
    # FAT12 end-of-chain is 0xFF8-0xFFF, FAT16 is 0xFFF8-0xFFFF. Testing only
    # against 0xFFF8 (as an earlier draft did) never fires on FAT12: the 0xFFF
    # marker is read back as cluster 4095, which looks live, and the walk then
    # chases garbage past the end of the FAT for millions of iterations.
    $eoc = if ($Geometry.FatType -eq 12) { 0xFF8 } else { 0xFFF8 }
    $maxCluster = [int]$Geometry.ClusterCount + 1
    $cluster = $FirstCluster
    while ($cluster -ge 2 -and $cluster -lt $eoc -and $cluster -le $maxCluster -and $chain.Count -lt $MaxClusters) {
        $chain.Add($cluster)
        $cluster = Get-FatEntry -Bytes $Bytes -FatOffset $Geometry.FatOffset -Cluster $cluster -FatType $Geometry.FatType
    }
    return $chain
}

function Read-FatImageBytes {
    <#
    .SYNOPSIS
        Read a whole image file with read/write sharing allowed.

    .DESCRIPTION
        The buffer is returned with a unary comma. A bare `return $buffer`
        lets the pipeline unroll the array into one object per byte, and the
        caller's [byte[]] parameter then re-collects them: 67 million
        pipeline objects cost about 50 seconds for a 64 MiB disk image, which
        would dominate every poll of the host-side sentinel loop.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $len = $stream.Length
        $buffer = New-Object byte[] $len
        $read = 0
        while ($read -lt $len) {
            $n = $stream.Read($buffer, $read, $len - $read)
            if ($n -le 0) { throw "Unexpected end of stream reading '$Path'." }
            $read += $n
        }
        return , $buffer
    }
    finally {
        $stream.Dispose()
    }
}

function ConvertFrom-FatDirSlot {
    <#
    .SYNOPSIS
        Decode one raw 32-byte directory slot into a lookup object.
    #>
    param([byte[]]$Bytes, [Parameter(Mandatory = $true)][int]$Offset)

    $nameBytes = New-Object byte[] 11
    [Array]::Copy($Bytes, $Offset, $nameBytes, 0, 11)
    return [pscustomobject]@{
        Offset       = $Offset
        Attribute    = $Bytes[$Offset + 11]
        Name         = ConvertFrom-FatName -Bytes $nameBytes -Offset 0
        StartCluster = [BitConverter]::ToUInt16($Bytes, $Offset + 26)
        Size         = [BitConverter]::ToUInt32($Bytes, $Offset + 28)
    }
}

function Get-FatDirectoryEntries {
    <#
    .SYNOPSIS
        List the live slots of the volume root (Cluster 0) or of a
        subdirectory identified by its first cluster.
    #>
    param(
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)]$Geometry,
        [int]$Cluster = 0
    )

    $entries = New-Object System.Collections.Generic.List[object]
    if ($Cluster -eq 0) {
        for ($i = 0; $i -lt [int]$Geometry.Bpb.RootEntries; $i++) {
            $o = [int]$Geometry.RootOffset + ($i * 32)
            if ($o + 32 -gt $Bytes.Length) { break }
            $first = $Bytes[$o]
            if ($first -eq 0x00) { break }    # no further entries can exist past here
            if ($first -eq 0xE5) { continue }
            $attr = $Bytes[$o + 11]
            if (($attr -band 0x0F) -eq 0x0F) { continue }
            $entries.Add((ConvertFrom-FatDirSlot -Bytes $Bytes -Offset $o))
        }
        return $entries
    }

    $end = $false
    foreach ($c in (Get-FatChain -Bytes $Bytes -Geometry $Geometry -FirstCluster $Cluster)) {
        if ($end) { break }
        $base = [int]$Geometry.DataOffset + (($c - 2) * [int]$Geometry.ClusterSize)
        $slots = [int]$Geometry.ClusterSize / 32
        for ($s = 0; $s -lt $slots; $s++) {
            $o = $base + ($s * 32)
            if ($o + 32 -gt $Bytes.Length) { $end = $true; break }
            $first = $Bytes[$o]
            if ($first -eq 0x00) { $end = $true; break }
            if ($first -eq 0xE5) { continue }
            $attr = $Bytes[$o + 11]
            if (($attr -band 0x0F) -eq 0x0F) { continue }
            $entries.Add((ConvertFrom-FatDirSlot -Bytes $Bytes -Offset $o))
        }
    }
    return $entries
}

function Set-FatEntryAll {
    <#
    .SYNOPSIS
        Write one FAT entry to EVERY FAT copy on the volume.
        Only updating the second copy (as an earlier draft did) leaves FAT #1 -
        the one DOS reads - stale, and the staged tree then does not exist as
        far as the guest is concerned.
    #>
    param(
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)]$Geometry,
        [Parameter(Mandatory = $true)][int]$Cluster,
        [Parameter(Mandatory = $true)][int]$Value
    )
    for ($f = 0; $f -lt [int]$Geometry.Bpb.NumFats; $f++) {
        $fo = [int]$Geometry.FatOffset + ($f * [int]$Geometry.FatSize)
        Set-FatEntry -Bytes $Bytes -FatOffset $fo -Cluster $Cluster -Value $Value -FatType $Geometry.FatType
    }
}

function Set-FatDirSlotRaw {
    <#
    .SYNOPSIS
        Write one 32-byte directory slot from pre-built fields.
    #>
    param(
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$Offset,
        [byte[]]$Name83,   # exactly 11 bytes
        [Parameter(Mandatory = $true)][int]$Attribute,
        [Parameter(Mandatory = $true)][int]$StartCluster,
        [Parameter(Mandatory = $true)][uint32]$Size
    )
    if ($Name83.Length -ne 11) { throw 'Name83 must be exactly 11 bytes.' }
    if ($Offset + 32 -gt $Bytes.Length) { throw "Directory slot at $Offset runs past the end of the image." }
    for ($i = 0; $i -lt 32; $i++) { $Bytes[$Offset + $i] = 0 }
    [Array]::Copy($Name83, 0, $Bytes, $Offset, 11)
    $Bytes[$Offset + 11] = [byte]$Attribute
    [BitConverter]::GetBytes([uint16]$StartCluster).CopyTo($Bytes, $Offset + 26)
    [BitConverter]::GetBytes($Size).CopyTo($Bytes, $Offset + 28)
}

function Set-FatDirSlot {
    param(
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$Offset,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Attribute,
        [Parameter(Mandatory = $true)][int]$StartCluster,
        [Parameter(Mandatory = $true)][uint32]$Size
    )
    $entryName = ConvertTo-FatName -Path $Name
    $name83 = New-Object byte[] 11
    [Text.Encoding]::ASCII.GetBytes($entryName.Name).CopyTo($name83, 0)
    [Text.Encoding]::ASCII.GetBytes($entryName.Ext).CopyTo($name83, 8)
    Set-FatDirSlotRaw -Bytes $Bytes -Offset $Offset -Name83 $name83 -Attribute $Attribute -StartCluster $StartCluster -Size $Size
}

function Get-FreeClusterFrom {
    <#
    .SYNOPSIS
        Next free cluster at or after a cursor. Callers keep the cursor so a
        bulk stage does not rescan the FAT from cluster 2 for every allocation
        (that is O(n^2) and tens of seconds in PowerShell for a 19 MB pak).
    #>
    param(
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)]$Geometry,
        [int]$StartFrom = 2
    )
    for ($c = $StartFrom; $c -le [int]$Geometry.ClusterCount + 1; $c++) {
        $v = Get-FatEntry -Bytes $Bytes -FatOffset $Geometry.FatOffset -Cluster $c -FatType $Geometry.FatType
        if ($v -eq 0) { return $c }
    }
    return 0
}

function Add-FatDirEntry {
    <#
    .SYNOPSIS
        Place a new directory entry into a directory (root or subdirectory),
        growing a subdirectory's cluster chain when it is full.
    #>
    param(
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)]$Geometry,
        [Parameter(Mandatory = $true)][int]$DirCluster,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Attribute,
        [Parameter(Mandatory = $true)][int]$StartCluster,
        [Parameter(Mandatory = $true)][uint32]$Size
    )

    $writeAt = -1
    if ($DirCluster -eq 0) {
        for ($i = 0; $i -lt [int]$Geometry.Bpb.RootEntries; $i++) {
            $o = [int]$Geometry.RootOffset + ($i * 32)
            $first = $Bytes[$o]
            if ($first -eq 0x00 -or $first -eq 0xE5) { $writeAt = $o; break }
        }
        if ($writeAt -lt 0) { throw 'The root directory is full.' }
    }
    else {
        $chain = @(Get-FatChain -Bytes $Bytes -Geometry $Geometry -FirstCluster $DirCluster)
        if ($chain.Count -eq 0) { throw "Subdirectory cluster $DirCluster has no chain." }
        foreach ($c in $chain) {
            $base = [int]$Geometry.DataOffset + (($c - 2) * [int]$Geometry.ClusterSize)
            $slots = [int]$Geometry.ClusterSize / 32
            for ($s = 0; $s -lt $slots; $s++) {
                $o = $base + ($s * 32)
                $first = $Bytes[$o]
                if ($first -eq 0x00 -or $first -eq 0xE5) { $writeAt = $o; break }
            }
            if ($writeAt -ge 0) { break }
        }
        if ($writeAt -lt 0) {
            # Every slot in every cluster is live: append one cluster to the
            # directory's chain and use its first slot.
            $last = $chain[$chain.Count - 1]
            $next = Get-FreeClusterFrom -Bytes $Bytes -Geometry $Geometry
            if ($next -eq 0) { throw 'No free clusters left to grow a directory.' }
            Set-FatEntryAll -Bytes $Bytes -Geometry $Geometry -Cluster $last -Value $next
            Set-FatEntryAll -Bytes $Bytes -Geometry $Geometry -Cluster $next -Value $(if ($Geometry.FatType -eq 12) { 0xFFF } else { 0xFFFF })
            $base = [int]$Geometry.DataOffset + (($next - 2) * [int]$Geometry.ClusterSize)
            for ($k = 0; $k -lt [int]$Geometry.ClusterSize; $k++) { $Bytes[$base + $k] = 0 }
            $writeAt = $base
        }
    }

    Set-FatDirSlot -Bytes $Bytes -Offset $writeAt -Name $Name -Attribute $Attribute -StartCluster $StartCluster -Size $Size
}

function New-FatDirectory {
    <#
    .SYNOPSIS
        Allocate a subdirectory cluster, write its '.'/'..' slots, and link it
        into the parent. Returns the new directory's first cluster.
    #>
    param(
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)]$Geometry,
        [Parameter(Mandatory = $true)][int]$ParentCluster,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $cluster = Get-FreeClusterFrom -Bytes $Bytes -Geometry $Geometry
    if ($cluster -eq 0) { throw 'No free clusters left for a new directory.' }
    Set-FatEntryAll -Bytes $Bytes -Geometry $Geometry -Cluster $cluster -Value $(if ($Geometry.FatType -eq 12) { 0xFFF } else { 0xFFFF })

    $base = [int]$Geometry.DataOffset + (($cluster - 2) * [int]$Geometry.ClusterSize)
    for ($k = 0; $k -lt [int]$Geometry.ClusterSize; $k++) { $Bytes[$base + $k] = 0 }

    # '.' and '..' are raw 8.3 names no parser should ever normalise, so they
    # are built byte by byte: '.' is 0x2E followed by seven spaces, no extension.
    $dot = New-Object byte[] 11
    for ($i = 0; $i -lt 11; $i++) { $dot[$i] = 0x20 }
    $dot[0] = 0x2E
    Set-FatDirSlotRaw -Bytes $Bytes -Offset $base -Name83 $dot -Attribute 0x10 -StartCluster $cluster -Size 0
    $dotdot = New-Object byte[] 11
    for ($i = 0; $i -lt 11; $i++) { $dotdot[$i] = 0x20 }
    $dotdot[0] = 0x2E; $dotdot[1] = 0x2E
    Set-FatDirSlotRaw -Bytes $Bytes -Offset ($base + 32) -Name83 $dotdot -Attribute 0x10 -StartCluster $ParentCluster -Size 0

    Add-FatDirEntry -Bytes $Bytes -Geometry $Geometry -DirCluster $ParentCluster -Name $Name -Attribute 0x10 -StartCluster $cluster -Size 0
    return $cluster
}

function ConvertTo-FatName {
    <#
    .SYNOPSIS
        Split '/QUAKE/ID1/PAK0.PAK' into its 8.3 directory entry form.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $parts = @($Path -split '[\\/]+' | Where-Object { $_ -ne '' })
    if ($parts.Count -ne 1) {
        throw "Only flat root-level paths are supported, got '$Path'. Subdirectories are not implemented."
    }
    $leaf = $parts[0]
    if ($leaf -notmatch '^(?i)([^.]{1,8})(?:\.([^.]{1,3}))?$') {
        throw "'$leaf' is not a valid 8.3 name."
    }
    $base = $Matches[1].ToUpperInvariant().PadRight(8, ' ')
    $ext = if ($Matches[2]) { $Matches[2].ToUpperInvariant().PadRight(3, ' ') } else { '   ' }
    return [pscustomobject]@{ Name = $base; Ext = $ext }
}

function ConvertFrom-FatName {
    param([byte[]]$Bytes, [int]$Offset)

    $name = ([Text.Encoding]::ASCII.GetString($Bytes, $Offset, 8)).TrimEnd()
    $ext = ([Text.Encoding]::ASCII.GetString($Bytes, $Offset + 8, 3)).TrimEnd()
    if ($ext -ne '') { return "$name.$ext" }
    return $name
}

function Find-FatEntry {
    <#
    .SYNOPSIS
        Locate an entry by 8.3 path, root-relative ('QUAKE\ID1\PAK0.PAK').
        Returns $null when absent.
    #>
    param([byte[]]$Bytes, $Geometry, [Parameter(Mandatory = $true)][string]$Name, [switch]$MatchLabel)

    $components = @($Name -split '[\\/]+' | Where-Object { $_ -ne '' })
    if ($components.Count -eq 0) { throw "Empty volume path." }

    $dirCluster = 0
    for ($i = 0; $i -lt $components.Count - 1; $i++) {
        ConvertTo-FatName -Path $components[$i] | Out-Null    # validate the component
        $child = $null
        foreach ($e in (Get-FatDirectoryEntries -Bytes $Bytes -Geometry $Geometry -Cluster $dirCluster)) {
            if ($MatchLabel -and ($e.Attribute -band 0x08) -eq 0x08) { continue }
            if ($e.Name -eq $components[$i]) { $child = $e; break }
        }
        if ($null -eq $child) { return $null }
        if (($child.Attribute -band 0x10) -eq 0) { return $null }   # a file is not a directory
        $dirCluster = [int]$child.StartCluster
    }

    $leaf = $components[$components.Count - 1]
    ConvertTo-FatName -Path $leaf | Out-Null
    foreach ($e in (Get-FatDirectoryEntries -Bytes $Bytes -Geometry $Geometry -Cluster $dirCluster)) {
        if ($MatchLabel -and ($e.Attribute -band 0x08) -eq 0x08) { continue }
        if ($e.Name -eq $leaf) {
            return [pscustomobject]@{
                Offset       = $e.Offset
                Attribute    = $e.Attribute
                StartCluster = $e.StartCluster
                Size         = $e.Size
                Name         = $Name
            }
        }
    }
    return $null
}

function Get-FatImageRoot {
    <#
    .SYNOPSIS
        List the live entries in a volume's root directory, or in any
        subdirectory when -Directory is given (root-relative 8.3 path).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Offset = 0,
        [string]$Directory = ''
    )

    $bytes = Read-FatImageBytes -Path $Path
    $geom = Get-FatGeometry -Bpb (Read-Bpb -Buffer $bytes -Offset $Offset) -VolumeOffset $Offset
    $cluster = 0
    if (-not [string]::IsNullOrWhiteSpace($Directory)) {
        $dirEntry = Find-FatEntry -Bytes $bytes -Geometry $geom -Name $Directory
        if ($null -eq $dirEntry) { throw "'$Directory' not found in '$Path'." }
        if (($dirEntry.Attribute -band 0x10) -eq 0) { throw "'$Directory' in '$Path' is not a directory." }
        $cluster = [int]$dirEntry.StartCluster
    }
    $entries = @(Get-FatDirectoryEntries -Bytes $bytes -Geometry $geom -Cluster $cluster)
    return [pscustomobject]@{ Geometry = $geom; Entries = $entries }
}

function Read-FatImageFile {
    <#
    .SYNOPSIS
        Read one file out of a FAT12/FAT16 volume by 8.3 path.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$Offset = 0
    )

    $bytes = Read-FatImageBytes -Path $Path
    $geom = Get-FatGeometry -Bpb (Read-Bpb -Buffer $bytes -Offset $Offset) -VolumeOffset $Offset
    $entry = Find-FatEntry -Bytes $bytes -Geometry $geom -Name $Name
    if ($null -eq $entry) { throw "'$Name' not found in '$Path'." }
    $chain = Get-FatChain -Bytes $bytes -Geometry $geom -FirstCluster $entry.StartCluster
    $out = New-Object byte[] $entry.Size
    $written = 0
    foreach ($c in $chain) {
        if ($written -ge $entry.Size) { break }
        $src = [int]$geom.DataOffset + (($c - 2) * [int]$geom.ClusterSize)
        $take = [int][math]::Min([int]$geom.ClusterSize, [int]$entry.Size - $written)
        [Array]::Copy($bytes, $src, $out, $written, $take)
        $written += $take
    }
    if ($written -ne [int]$entry.Size) {
        throw "'$Name' is truncated: cluster chain yielded $written of $($entry.Size) bytes."
    }
    return , $out
}

function Test-FatImageFile {
    <#
    .SYNOPSIS
        Test whether a file exists on a FAT volume at an 8.3 path.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$Offset = 0
    )

    $bytes = Read-FatImageBytes -Path $Path
    $geom = Get-FatGeometry -Bpb (Read-Bpb -Buffer $bytes -Offset $Offset) -VolumeOffset $Offset
    return ($null -ne (Find-FatEntry -Bytes $bytes -Geometry $geom -Name $Name))
}

function Set-FatImageFile {
    <#
    .SYNOPSIS
        Create or replace a file on a FAT12/FAT16 volume at an 8.3 path.
        Missing intermediate directories are created.

    .DESCRIPTION
        When the entry already exists its cluster chain is reused and extended
        if the new content needs more clusters; otherwise a fresh chain is
        allocated. Every FAT copy is kept in step. Directory chains grow by a
        cluster when their slots run out.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [byte[]]$Content,
        # Directory attribute for the entry (0x20 archive; DOS system files
        # use 0x27 = hidden+system+archive). Applied to both the create and
        # the update path.
        [int]$Attribute = 0x20,
        [int]$Offset = 0
    )

    $bytes = Read-FatImageBytes -Path $Path
    $geom = Get-FatGeometry -Bpb (Read-Bpb -Buffer $bytes -Offset $Offset) -VolumeOffset $Offset

    $components = @($Name -split '[\\/]+' | Where-Object { $_ -ne '' })
    if ($components.Count -eq 0) { throw "Empty volume path." }

    # Walk (creating on the way down) every intermediate directory.
    $dirCluster = 0
    if ($components.Count -ge 2) {
        foreach ($component in $components[0..($components.Count - 2)]) {
            $child = $null
            foreach ($e in (Get-FatDirectoryEntries -Bytes $bytes -Geometry $geom -Cluster $dirCluster)) {
                if ($e.Name -eq $component) { $child = $e; break }
            }
            if ($null -eq $child) {
                $dirCluster = New-FatDirectory -Bytes $bytes -Geometry $geom -ParentCluster $dirCluster -Name $component
            }
            elseif (($child.Attribute -band 0x10) -eq 0) {
                throw "'$component' in '$Name' exists and is not a directory."
            }
            else {
                $dirCluster = [int]$child.StartCluster
            }
        }
    }
    $leaf = $components[$components.Count - 1]

    $entryName = ConvertTo-FatName -Path $leaf
    $clustersNeeded = [int][math]::Max(1, [math]::Ceiling($Content.Length / [double]$geom.ClusterSize))

    $entry = $null
    foreach ($e in (Get-FatDirectoryEntries -Bytes $bytes -Geometry $geom -Cluster $dirCluster)) {
        if ($e.Name -eq $leaf) { $entry = $e; break }
    }

    $chain = New-Object System.Collections.Generic.List[int]
    if ($null -ne $entry) {
        # Get-FatChain's output is unrolled by the pipeline, so a single-cluster
        # file arrives as a bare int (no .Count under StrictMode). Rebuild the
        # list explicitly: later steps call .Add() on it.
        foreach ($c in (Get-FatChain -Bytes $bytes -Geometry $geom -FirstCluster $entry.StartCluster)) {
            $chain.Add([int]$c)
        }
    }

    # Allocation cursor: a 19 MB pak needs ~9,400 clusters and rescanning from
    # cluster 2 for each one is O(n^2) in interpreter time.
    $cursor = 2

    # Grow the chain if the payload no longer fits.
    while ($chain.Count -lt $clustersNeeded) {
        $next = Get-FreeClusterFrom -Bytes $bytes -Geometry $geom -StartFrom $cursor
        if ($next -eq 0) { throw "No free clusters left in '$Path'." }
        $cursor = $next + 1
        if ($chain.Count -gt 0) {
            Set-FatEntryAll -Bytes $bytes -Geometry $geom -Cluster $chain[$chain.Count - 1] -Value $next
        }
        $chain.Add($next)
    }

    if ($chain.Count -eq 0) {
        $first = Get-FreeClusterFrom -Bytes $bytes -Geometry $geom -StartFrom $cursor
        if ($first -eq 0) { throw "No free clusters left in '$Path'." }
        $chain.Add($first)
    }

    # Terminate the tail.
    $endMarker = if ($geom.FatType -eq 12) { 0xFFF } else { 0xFFFF }
    Set-FatEntryAll -Bytes $bytes -Geometry $geom -Cluster $chain[$chain.Count - 1] -Value $endMarker

    # Payload. Clusters past the payload are zero-filled rather than left
    # holding a previous, longer file's tail.
    $written = 0
    foreach ($c in $chain) {
        $dst = [int]$geom.DataOffset + (($c - 2) * [int]$geom.ClusterSize)
        if ($dst + $geom.ClusterSize -gt $bytes.Length) { throw "Cluster $c runs past the end of '$Path'." }
        [Array]::Clear($bytes, $dst, [int]$geom.ClusterSize)
        if ($written -lt $Content.Length) {
            $take = [int][math]::Min([int]$geom.ClusterSize, [int]$Content.Length - $written)
            [Array]::Copy($Content, 0, $bytes, $dst, $take)
            $written += $take
        }
    }

    # Directory entry for the leaf.
    if ($null -eq $entry) {
        Add-FatDirEntry -Bytes $bytes -Geometry $geom -DirCluster $dirCluster -Name $leaf `
            -Attribute $Attribute -StartCluster $chain[0] -Size ([uint32]$Content.Length)
    }
    else {
        Set-FatDirSlot -Bytes $bytes -Offset $entry.Offset -Name $leaf -Attribute $Attribute `
            -StartCluster $chain[0] -Size ([uint32]$Content.Length)
    }

    [IO.File]::WriteAllBytes($Path, $bytes)
}

function ConvertTo-MbrChs {
    <#
    .SYNOPSIS
        Convert an LBA to the CHS triple an MBR partition entry stores.
        Sector 6 bits, cylinder low 8 bits, cylinder high 2 bits in the
        sector byte - the classic INT13 encoding.
    #>
    param(
        [Parameter(Mandatory = $true)][int]$Lba,
        [Parameter(Mandatory = $true)][int]$Heads,
        [Parameter(Mandatory = $true)][int]$SectorsPerTrack
    )
    $cylinder = [int][math]::Floor($Lba / ($Heads * $SectorsPerTrack))
    $rem = $Lba - ($cylinder * $Heads * $SectorsPerTrack)
    $head = [int][math]::Floor($rem / $SectorsPerTrack)
    $sector = ($rem % $SectorsPerTrack) + 1
    if ($cylinder -gt 1023 -or $head -gt 15 -or $sector -gt 63) {
        throw "LBA $Lba does not fit classic CHS (c=$cylinder h=$head s=$sector)."
    }
    return [pscustomobject]@{ Cylinder = $cylinder; Head = $head; Sector = $sector }
}

function Get-FatPartitionOffset {
    <#
    .SYNOPSIS
        Read an MBR and return the byte offset of the first partition (plus
        its type and LBA range). Distinguishes an MBR from a floppy/PBR
        superblock, which also ends in 55 AA but carries a valid BPB at +11.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = Read-FatImageBytes -Path $Path
    if ($bytes.Length -lt 512) { throw "'$Path' is smaller than one sector." }
    $hasBpb = ([BitConverter]::ToUInt16($bytes, 11) -eq 512 -and $bytes[13] -ne 0)
    if ($hasBpb) {
        return [pscustomobject]@{ Offset = 0; Type = $bytes[21]; LbaStart = 0; LbaSize = [int]($bytes.Length / 512) }
    }
    if ($bytes[510] -ne 0x55 -or $bytes[511] -ne 0xAA) { throw "'$Path' has no MBR signature (55 AA)." }
    $status = $bytes[446]
    if ($status -ne 0x00 -and $status -ne 0x80) { throw "'$Path' partition 1 status byte 0x$('{0:X2}' -f $status) is invalid." }
    $type = $bytes[450]
    if ($type -eq 0x00) { throw "'$Path' has an empty partition table." }
    $lbaStart = [BitConverter]::ToUInt32($bytes, 454)
    $lbaSize = [BitConverter]::ToUInt32($bytes, 458)
    return [pscustomobject]@{
        Offset   = [int]($lbaStart * 512)
        Type     = $type
        LbaStart = $lbaStart
        LbaSize  = $lbaSize
    }
}

function New-Fat16HardDiskImage {
    <#
    .SYNOPSIS
        Create a raw hard-disk image holding one active FAT16 partition.

    .DESCRIPTION
        The partition carries a valid BPB but no boot code, which is correct
        here because the guest boots from the DOS floppy in drive A:. That is
        deliberate: a volume MS-DOS itself would boot needs IO.SYS laid out
        immediately after the boot sector, and this image never has to satisfy
        that. IO.SYS still mounts it as C: from the partition table alone.

    .PARAMETER Cylinders
        Cylinders for the CHS geometry reported to the emulated BIOS. Kept at
        or below 1024 so the geometry stays classically addressable.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Cylinders = 130,
        [int]$Heads = 16,
        [int]$SectorsPerTrack = 63,
        [int]$PartitionStartLba = 63,
        [int]$RootEntries = 512,
        [int]$SectorsPerCluster = 0
    )

    $sectorSize = 512
    $totalSectors = $Cylinders * $Heads * $SectorsPerTrack
    if ($Cylinders -gt 1024) {
        throw "Cylinders must be 1024 or fewer for CHS-safe geometry, got $Cylinders."
    }
    if ($SectorsPerCluster -eq 0) {
        # 4 sectors/cluster = 2 KiB, a reasonable middle for a volume of this
        # size: small enough that the 18 MB pak does not waste much slack,
        # large enough that the FAT does not dominate.
        $SectorsPerCluster = 4
    }
    $clusterSize = $sectorSize * $SectorsPerCluster

    # Root directory must land on a sector boundary.
    $rootSectors = [int]($RootEntries * 32 / $sectorSize)

    # Iterate: cluster count depends on FAT size, which depends on cluster
    # count. A couple of passes converge for every geometry in range.
    $sectorsPerFat = 0
    for ($pass = 0; $pass -lt 8; $pass++) {
        $overhead = 1 + (2 * $sectorsPerFat) + $rootSectors
        $dataSectors = $totalSectors - $PartitionStartLba - $overhead
        if ($dataSectors -le 0) {
            throw "Geometry is too small: only $dataSectors data sectors remain after overhead."
        }
        $clusterCount = [int][math]::Floor($dataSectors / $SectorsPerCluster)
        $needed = [int][math]::Ceiling(($clusterCount + 2) * 2 / [double]$sectorSize)
        if ($needed -eq $sectorsPerFat) { break }
        $sectorsPerFat = $needed
    }
    if ($clusterCount -lt 4085) {
        throw "Geometry yields only $clusterCount clusters, which is FAT12 territory; increase the disk size."
    }

    $bytes = New-Object byte[] ($totalSectors * $sectorSize)

    # --- Partition boot record ---
    $pbr = $PartitionStartLba * $sectorSize
    $ascii = [Text.Encoding]::ASCII
    $bytes[$pbr + 0] = 0xEB; $bytes[$pbr + 1] = 0x3C; $bytes[$pbr + 2] = 0x90   # jmp short
    $ascii.GetBytes('MSDOS5.0').CopyTo($bytes, $pbr + 3)
    [BitConverter]::GetBytes([uint16]$sectorSize).CopyTo($bytes, $pbr + 11)
    $bytes[$pbr + 13] = [byte]$SectorsPerCluster
    [BitConverter]::GetBytes([uint16]1).CopyTo($bytes, $pbr + 14)                  # reserved
    $bytes[$pbr + 16] = 2                                                          # FATs
    [BitConverter]::GetBytes([uint16]$RootEntries).CopyTo($bytes, $pbr + 17)
    $bytes[$pbr + 19] = 0; $bytes[$pbr + 20] = 0                                    # total16 = 0 (32-bit field used)
    $bytes[$pbr + 21] = 0xF8                                                       # fixed disk
    [BitConverter]::GetBytes([uint16]$sectorsPerFat).CopyTo($bytes, $pbr + 22)
    [BitConverter]::GetBytes([uint16]$SectorsPerTrack).CopyTo($bytes, $pbr + 24)
    [BitConverter]::GetBytes([uint16]$Heads).CopyTo($bytes, $pbr + 26)
    [BitConverter]::GetBytes([uint32]$PartitionStartLba).CopyTo($bytes, $pbr + 28)  # hidden
    [BitConverter]::GetBytes([uint32]($totalSectors - $PartitionStartLba)).CopyTo($bytes, $pbr + 32)
    # Extended BPB: drive number first (0x24), reserved, then the 0x29
    # signature (0x26), serial (0x27). The drive number is load-bearing twice
    # over: the DOS boot contract passes BPB[0x24] to IO.SYS as DL, and the
    # loader here uses it as the INT 13h drive for every read. 0x80 = hard
    # disk. (An earlier draft put the 0x29 signature at 0x24 and the serial at
    # 0x26 - DL would have been 0x29, an invalid drive.)
    $bytes[$pbr + 36] = 0x80                                                       # drive number
    $bytes[$pbr + 37] = 0x00                                                       # reserved
    $bytes[$pbr + 38] = 0x29                                                       # extended boot signature
    [BitConverter]::GetBytes([uint32]0x4863716D).CopyTo($bytes, $pbr + 39)          # volume serial
    $ascii.GetBytes('NO NAME    ').CopyTo($bytes, $pbr + 43)
    $ascii.GetBytes('FAT16   ').CopyTo($bytes, $pbr + 54)
    # The partition's own boot sector carries the signature too. MS-DOS checks
    # 0x55AA on the VBR when it mounts the partition; without it the volume is
    # rejected wholesale and the guest sees "Invalid drive specification" for
    # C: - while the host-side FAT reader in this very module reads the same
    # bytes back happily, so nothing else in the toolchain catches it.
    $bytes[$pbr + 510] = 0x55
    $bytes[$pbr + 511] = 0xAA

    # --- VBR chain loader (runs at 0000:4000 after the MBR stub jumps here) ---
    # Implements the exact MS-DOS 6.22 boot contract, extracted by
    # disassembling Dos6.22.img's own boot sector:
    #   rootLBA  = hidden + reserved + numFats*spf
    #   dataStart= rootLBA + rootEnts/16          (bps=512 guaranteed)
    #   require root entry0 = "IO      SYS", entry1 = "MSDOS   SYS"
    #   load the first 3 sectors of IO.SYS to 0000:0700
    #   CH=[media], DL=[drive 0x80], BX=dataStart.lo, AX=0, jmp 0070:0000
    # Memory map (disjoint - a loader at 0x600 would collide with both DOS
    # buffers, which is why the load address is 0x4000):
    #   0500-06FF root-dir sector buffer   0700-0CFF IO.SYS first 1536 B
    #   4000-41FF this VBR image           7C00-7DFF SS:SP top + final copy
    #   7E00+     loader scratch (rootLBA/dataStart/CHS parts)
    # 16-bit LBA math: fine for this fixed 64 MiB geometry (dataStart=352,
    # hidden=63 - both far below 65536); revisit if geometry ever grows.
    $vbrLoader = [byte[]](
        # 403E: setup
        0xFA, 0x31, 0xC0, 0x8E, 0xD8, 0x8E, 0xC0, 0x8E, 0xD0,       # cli; xor ax,ax; ds=es=ss=0
        0xBC, 0x00, 0x7C, 0xFC, 0xFB,                                 # mov sp,0x7C00; cld; sti
        # rootLBA = hidden.lo + reserved + numFats*spf
        0x31, 0xC0,                                                   # xor ax,ax
        0xA0, 0x10, 0x40,                                             # mov al,[0x4010] numFats
        0xF7, 0x26, 0x16, 0x40,                                       # mul word [0x4016] spf
        0x03, 0x06, 0x1C, 0x40,                                       # add ax,[0x401C] hidden
        0x03, 0x06, 0x0E, 0x40,                                       # add ax,[0x400E] reserved
        0xA3, 0x00, 0x7E,                                             # mov [0x7E00],ax rootLBA
        # dataStart = rootLBA + rootEnts/16
        0x8B, 0x0E, 0x11, 0x40,                                       # mov cx,[0x4011] rootEnts
        0x89, 0xC8,                                                   # mov ax,cx
        0xB1, 0x04,                                                   # mov cl,4
        0xD3, 0xE8,                                                   # shr ax,cl (D3=16-bit; D2 would be shr AL!)
        0x03, 0x06, 0x00, 0x7E,                                       # add ax,[0x7E00]
        0xA3, 0x02, 0x7E,                                             # mov [0x7E02],ax dataStart
        # controller reset, then read the root directory to 0500 - and CHECK
        # the carry flag (an unchecked failed read used to fall into the name
        # check and report the wrong failure)
        0x8A, 0x16, 0x24, 0x40,                                       # mov dl,[0x4024] drive
        0xB4, 0x00, 0xCD, 0x13,                                       # mov ah,0; int 13h
        0xA1, 0x00, 0x7E,                                             # mov ax,[0x7E00] rootLBA
        0xBB, 0x00, 0x05,                                             # mov bx,0x0500
        0xE8, 0x84, 0x00,                                             # call read_lba (->0x4106)
        0x72, 0x67,                                                   # jb fail_read ('R') [+6]
        # entry0 must be IO.SYS ...
        0xBF, 0x00, 0x05,                                             # mov di,0x0500
        0xBE, 0x5A, 0x41,                                             # mov si,'IO      SYS' (linear 0x415A)
        0xB9, 0x0B, 0x00,                                             # mov cx,11
        0xF3, 0xA6,                                                   # repe cmps
        0x75, 0x5F,                                                   # jne fail_io ('I') [+6 -> 0x40F0]
        # ... and entry1 must be MSDOS.SYS. Rebase DI to 0x520 (DI+32 from
        # the post-compare 0x50B would land mid-entry) and RELOAD CX - a
        # second REPE CMPS with CX=0 compares nothing and false-passes.
        0xBF, 0x20, 0x05,                                             # mov di,0x0520
        0xBE, 0x65, 0x41,                                             # mov si,'MSDOS   SYS' (linear 0x4165)
        0xB9, 0x0B, 0x00,                                             # mov cx,11
        0xF3, 0xA6,                                                   # repe cmps
        0x75, 0x57,                                                   # jne fail_m ('M') [+6 -> 0x40F5]
        # IO.SYS LBA = (firstCluster-2)*spc + dataStart; load 3 sectors to 0700.
        # read_lba clobbers AX/CX/DX (it builds CHS in CX), so the loop's
        # counter and LBA must be pushed/popped around the call exactly as
        # DOS does - without this the loop counter became a CHS word and the
        # loader read dozens of stray sectors.
        0xA1, 0x1A, 0x05,                                             # mov ax,[0x051A] first cluster
        0x48, 0x48,                                                   # dec ax; dec ax
        0x8A, 0x1E, 0x0D, 0x40,                                       # mov bl,[0x400D] spc
        0x32, 0xFF,                                                   # xor bh,bh
        0xF7, 0xE3,                                                   # mul bx
        0x03, 0x06, 0x02, 0x7E,                                       # add ax,[0x7E02] dataStart
        0xBB, 0x00, 0x07,                                             # mov bx,0x0700
        0xB9, 0x03, 0x00,                                             # mov cx,3
        0x50, 0x51, 0x52,                                             # loop: push ax; push cx; push dx
        0xE8, 0x4B, 0x00,                                             # call read_lba
        0x5A, 0x59, 0x58,                                             # pop dx; pop cx; pop ax
        0x72, 0x2B,                                                   # jb fail_read ('R') [+6]
        0x40,                                                         # inc ax
        0x81, 0xC3, 0x00, 0x02,                                       # add bx,0x200
        0xE2, 0xEE,                                                   # loop (target predates the insert)
        # entry state, exactly as DOS leaves it
        0x8A, 0x2E, 0x15, 0x40,                                       # mov ch,[0x4015] media
        0x8A, 0x16, 0x24, 0x40,                                       # mov dl,[0x4024] drive 80h
        0x8B, 0x1E, 0x02, 0x7E,                                       # mov bx,[0x7E02] dataStart.lo
        0x31, 0xC0,                                                   # xor ax,ax (dataStart.hi=0)
        # hand IO.SYS the environment it expects: copy this sector to 7C00
        0xBE, 0x00, 0x40,                                             # mov si,0x4000
        0xBF, 0x00, 0x7C,                                             # mov di,0x7C00
        0xB9, 0x00, 0x02,                                             # mov cx,256
        0xF3, 0xA5,                                                   # rep movsw
        # instrumentation: print 'G' immediately before the handoff so the
        # guest screen distinguishes "our loader finished" from "IO.SYS hung".
        0xBE, 0x70, 0x41,                                             # mov si,'G' (linear 0x4170)
        0xE8, 0x5E, 0x00,                                             # call print_str (->0x4144)
        0xEA, 0x00, 0x00, 0x70, 0x00,                                 # jmp 0070:0000
        # fail branches: each prints one letter so the guest screen says
        # WHICH check failed - 'R' read_lba/INT13, 'I' entry0 (IO.SYS),
        # 'M' entry1 (MSDOS.SYS) - then falls into the common handler.
        0xBE, 0x54, 0x41,                                             # fail_read: mov si,'R' (0x4154)
        0xEB, 0x08,                                                   # jmp fail_common
        0xBE, 0x56, 0x41,                                             # fail_io: mov si,'I' (0x4156)
        0xEB, 0x03,                                                   # jmp fail_common
        0xBE, 0x58, 0x41,                                             # fail_m: mov si,'M' (0x4158)
        # fail_common: reset, print letter, wait for a key, reboot
        0x8A, 0x16, 0x24, 0x40,                                       # mov dl,[0x4024]
        0xB4, 0x00, 0xCD, 0x13,                                       # mov ah,0; int 13h
        0xE8, 0x41, 0x00,                                             # call print_str
        0x31, 0xC0, 0xCD, 0x16,                                       # xor ax,ax; int 16h
        0xCD, 0x19,                                                   # int 19h
        0xF4, 0xEB, 0xFD,                                             # hlt; jmp self
        # read_lba: AX=LBA, ES:BX=dest -> CHS via BPB spt/heads, INT 13h AH=02.
        # Clobbers AX,CX,DX - callers must protect what they need (see loop).
        0x33, 0xD2,                                                   # xor dx,dx
        0xF7, 0x36, 0x18, 0x40,                                       # div word [0x4018] spt
        0xFE, 0xC2,                                                   # inc dl (sector)
        0x88, 0x16, 0x08, 0x7E,                                       # mov [0x7E08],dl
        0x33, 0xD2,                                                   # xor dx,dx
        0xF7, 0x36, 0x1A, 0x40,                                       # div word [0x401A] heads
        0x88, 0x16, 0x09, 0x7E,                                       # mov [0x7E09],dl head
        0xA3, 0x0A, 0x7E,                                             # mov [0x7E0A],ax cyl
        0x8B, 0x16, 0x0A, 0x7E,                                       # mov dx,[0x7E0A]
        0xB1, 0x06, 0xD2, 0xE6,                                       # mov cl,6; shl dh,cl
        0x0A, 0x36, 0x08, 0x7E,                                       # or dh,[0x7E08] sector (36=dh!)
        0x89, 0xD1, 0x86, 0xE9,                                       # mov cx,dx; xchg cl,ch
        0x8A, 0x36, 0x09, 0x7E,                                       # mov dh,[0x7E09] head (36=dh!)
        0x8A, 0x16, 0x24, 0x40,                                       # mov dl,[0x4024] drive
        0xB4, 0x02, 0xB0, 0x01,                                       # mov ah,2; mov al,1
        0xCD, 0x13, 0xC3,                                             # int 13h; ret
        # print_str: zero-terminated string at DS:SI via INT 10h teletype
        0xAC, 0x0A, 0xC0, 0x74, 0x0A,                                 # lodsb; or al,al; jz done
        0xB4, 0x0E, 0xB7, 0x00, 0xB3, 0x07, 0xCD, 0x10,               # ah=0E,bh=0,bl=7,int10
        0xEB, 0xF1,                                                   # jmp loop
        0xC3,                                                         # ret
        # strings: fail letters, then the names the boot contract checks.
        # Both names are EXACTLY 11 bytes ("IO"+6 spaces+"SYS" = 8.3) - an
        # extra space shifts MSDOS.SYS and every compare fails with 'I'.
        0x52, 0x00,                                                   # "R" read/INT13 failed
        0x49, 0x00,                                                   # "I" IO.SYS not entry0
        0x4D, 0x00,                                                   # "M" MSDOS.SYS not entry1
        0x49, 0x4F, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x53, 0x59, 0x53,   # "IO      SYS" (11 B)
        0x4D, 0x53, 0x44, 0x4F, 0x53, 0x20, 0x20, 0x20, 0x53, 0x59, 0x53,     # "MSDOS   SYS" (11 B)
        0x47, 0x00                                                    # "G" handed off to IO.SYS
    )
    $vbrLoader.CopyTo($bytes, $pbr + 0x3E)

    # --- Master boot record ---
    # Chain-loader: the BIOS may prefer boot order C,A once a drive C: exists,
    # and this MBR carries no operating system; without real code the CPU
    # executes zero padding and hangs right after the POST summary. The stub
    # loads the active partition's boot sector to 0000:4000 (NOT 7C00 - that
    # would overwrite the instructions that follow the INT13) and jumps there;
    # on failure it raises INT 18h so the ROM can fall back.
    # DX encoding: INT 13h wants DH=head, DL=drive - partition start
    # LBA 63 on a 16-head disk is C0/H1/S1 on drive 80h, so DX=0x0180
    # (bytes BA 80 01). An earlier draft had BA 01 80 = DL=01h (drive B!),
    # DH=80h - a byte-order slip the comment didn't match; this path had
    # never executed before the floppy was removed.
    $mbrStub = [byte[]](
        0xFA, 0x31, 0xC0, 0x8E, 0xD8, 0x8E, 0xC0, 0x8E, 0xD0,       # cli; xor ax,ax; ds=es=ss=0
        0xBC, 0x00, 0x7C,                                             # mov sp,0x7C00
        0xB8, 0x01, 0x02,                                             # mov ax,0x0201 (read 1 sector)
        0xB9, 0x01, 0x00,                                             # mov cx,0x0001 (cyl 0, sec 1)
        0xBA, 0x80, 0x01,                                             # mov dx,0x0180 (head 1, drive 80h)
        0xBB, 0x00, 0x40,                                             # mov bx,0x4000
        0xCD, 0x13,                                                   # int 13h
        0x72, 0x05,                                                   # jc fail
        0xEA, 0x00, 0x40, 0x00, 0x00,                                 # jmp 0000:4000
        0xCD, 0x18, 0xF4, 0xEB, 0xFD                                  # fail: int 18h; hlt; jmp fail
    )
    $mbrStub.CopyTo($bytes, 0)
    [BitConverter]::GetBytes([uint32]0).CopyTo($bytes, 440)                       # disk signature
    $lbaStart = $PartitionStartLba
    $lbaEnd = $totalSectors - 1
    $firstChs = ConvertTo-MbrChs -Lba $lbaStart -Heads $Heads -SectorsPerTrack $SectorsPerTrack
    $lastChs = ConvertTo-MbrChs -Lba $lbaEnd -Heads $Heads -SectorsPerTrack $SectorsPerTrack
    $partitionSectors = $totalSectors - $PartitionStartLba
    # 0x04 = FAT16 below 32 MB, 0x06 = FAT16B at or above it. The boundary is
    # 65,536 sectors; DOS mounts either, but tools and DOS itself key on it.
    $partitionType = if ($partitionSectors -lt 65536) { 0x04 } else { 0x06 }
    $bytes[446] = 0x80                                                             # bootable
    $bytes[447] = [byte]$firstChs.Head
    $bytes[448] = [byte]($firstChs.Sector -bor (($firstChs.Cylinder -shr 2) -band 0xC0))
    $bytes[449] = [byte]($firstChs.Cylinder -band 0xFF)
    $bytes[450] = [byte]$partitionType
    $bytes[451] = [byte]$lastChs.Head
    $bytes[452] = [byte]($lastChs.Sector -bor (($lastChs.Cylinder -shr 2) -band 0xC0))
    $bytes[453] = [byte]($lastChs.Cylinder -band 0xFF)
    [BitConverter]::GetBytes([uint32]$lbaStart).CopyTo($bytes, 454)
    [BitConverter]::GetBytes([uint32]$partitionSectors).CopyTo($bytes, 458)
    $bytes[510] = 0x55; $bytes[511] = 0xAA

    # --- FATs: entry 0 media descriptor, entry 1 end-of-chain, rest free ---
    $fatBytes = $sectorsPerFat * $sectorSize
    for ($f = 0; $f -lt 2; $f++) {
        $fo = $pbr + $sectorSize + ($f * $fatBytes)
        $bytes[$fo] = 0xF8
        $bytes[$fo + 1] = 0xFF
        $bytes[$fo + 2] = 0xFF
        $bytes[$fo + 3] = 0xFF
    }

    [IO.File]::WriteAllBytes($Path, $bytes)

    return [pscustomobject]@{
        Path              = [IO.Path]::GetFullPath($Path)
        Bytes             = $bytes.Length
        TotalSectors      = $totalSectors
        PartitionStartLba = $PartitionStartLba
        PartitionBytes    = ($totalSectors - $PartitionStartLba) * $sectorSize
        ClusterSize       = $clusterSize
        ClusterCount      = $clusterCount
        SectorsPerFat     = $sectorsPerFat
        SectorsPerCluster = $SectorsPerCluster
    }
}

Export-ModuleMember -Function Read-Bpb, Get-FatGeometry, Get-FatImageRoot, Read-FatImageFile, Test-FatImageFile, Set-FatImageFile, New-Fat16HardDiskImage, Get-FatPartitionOffset, ConvertTo-FatName, ConvertFrom-FatName

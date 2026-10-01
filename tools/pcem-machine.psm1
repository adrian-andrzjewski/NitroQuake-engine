<#
.SYNOPSIS
    Provisions a PCem machine: its v17 config text and its CMOS (NVRAM).

.DESCRIPTION
    Both PCem harnesses (486-fidelity.ps1, bench486-dos.ps1) have to put a
    staged MS-DOS hard disk in front of a real firmware, unattended. Two
    things are needed for that and neither is a one-liner, so they live here
    rather than being written twice:

    Get-PcemMachineConfigText emits the machine config. PCem v17 reads its
    machine keys out of the NAMELESS first section: config_load allocates a
    section with an empty name before it reads a line (src\config.c:145-150)
    and find_section(NULL) matches on that empty name
    (src\config.c:241-259). So the file is a flat list of keys with no
    [Header] line at all. This is worth stating plainly because the opposite
    is easy to assume: a [PCem], [cpu] or [display] section in a v17 machine
    config is not ignored, it is unreadable, and every key in it silently
    falls back to its built-in default. A headerless config is the correct
    shape, not a shortcut.

    Set-PcemMachineNvr provisions CMOS. PCem keeps NVRAM per config file
    (src\nvr.c:34-63: nvr_path + config_name + '.' + <machine>.nvr) and the
    bytes in it are the firmware's own, not PCem's. A machine whose CMOS has
    no drive table for C: halts at POST before DOS ever mounts the staged
    image, so a CMOS is a precondition for booting, not an optimisation. The
    bytes are rebuilt from the CMOS PCem itself ships in
    <install>\nvr\default\<machine>.nvr and patched to describe the geometry
    the staged image actually has. That makes the result a function of the
    machine and the staged geometry, not of whatever the last interactive run
    happened to leave behind on disk.

.NOTES
    The offsets below belong to the firmware vendor, not to PCem, and they
    differ per vendor. The Award BIOS keeps the drive C table at 0x30; AMI
    WinBIOS keeps the type byte at 0x12 and the geometry at 0x19..0x1E. Only
    the Award layout is encoded here, because sis496 is the machine this
    project runs. Encoding a second vendor's offsets without a machine to
    verify them against would be a way to write a confidently corrupt CMOS,
    so a machine with no entry throws, naming the machine, rather than
    half-working. Select it, record what POST prints, and add its offsets
    then.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CmosLayouts = @{
    # Award SiS 496/497, ROM_SIS496 (src\mem_bios.c:548). The image is an
    # "Award Decompression Bios", so this is an Award 4.5x CMOS: the fixed
    # disk 0 entry occupies 0x30..0x38, and the checksum is the byte at 0x0F
    # such that 0x0F plus the sum of 0x10..0x3D totals zero.
    #
    # The range stops at 0x3D because 0x3E/0x3F are the RTC rollover bytes
    # that change every second; a checksum covering them could never be
    # valid. AMI WinBIOS puts its stored checksum at 0x3E/0x3F and sums
    # 0x10..0x3F, so the two vendors' tables differ in the range end and in
    # where the value lives, not just in the drive-table offsets.
    sis496 = @{
        Vendor      = 'Award'
        TypeOffset  = 0x30
        CylLow      = 0x31
        CylHigh     = 0x32
        Heads       = 0x33
        PrecompLow  = 0x34
        PrecompHigh = 0x35
        LandingLow  = 0x36
        LandingHigh = 0x37
        Sectors     = 0x38
        Checksum    = 0x0F
        SumFrom     = 0x10
        SumTo       = 0x3D
    }
}

function Get-PcemMachineLayout {
    <#
    .SYNOPSIS
        The CMOS layout table entry for a machine, or $null if it has none.
    #>
    param([Parameter(Mandatory = $true)][string]$Machine)

    if (-not $script:CmosLayouts.ContainsKey($Machine)) { return $null }
    return $script:CmosLayouts[$Machine]
}

function Set-PcemMachineNvr {
    <#
    .SYNOPSIS
        Write the machine's CMOS to <install>\nvr\<config>.<machine>.nvr.

    .DESCRIPTION
        The drive C table is pointed at the staged geometry and the vendor
        checksum is recomputed, so the file is self-consistent: an out-of-date
        checksum is what makes a BIOS stop with "CMOS checksum failure" and a
        stale drive table is what leaves POST reporting "Hard Disk C: Type:
        None" with no INT13 drive 80 for DOS to mount.

        Returns $null (after warning) for a machine with no layout here, so
        that an unprovisioned machine still runs on whatever NVRAM the install
        already has. That is what a machine without a layout in this module did
        before this module existed, and refusing to provision must not become
        refusing to run.

        Drive C is set to the firmware's own auto-detect type. That is the
        setting a user picks in BIOS setup on this board, and it leaves the
        geometry to the firmware's IDE detection. The geometry fields are
        written anyway, from the staged image rather than assumed, because
        they are what the firmware falls back to and because the factory CMOS
        that ships with PCem has none: its whole 0x30..0x38 entry is unset, so
        a machine that did not detect would otherwise present 0x7C/0x20
        cylinders and 0x80 heads.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PcemRoot,
        [Parameter(Mandatory = $true)][string]$Machine,
        [Parameter(Mandatory = $true)][string]$ConfigName,
        [Parameter(Mandatory = $true)][int]$Cylinders,
        [Parameter(Mandatory = $true)][int]$Heads,
        [Parameter(Mandatory = $true)][int]$SectorsPerTrack
    )

    $layout = Get-PcemMachineLayout -Machine $Machine
    if ($null -eq $layout) {
        # Not a failure: a machine with no layout here simply keeps whatever
        # NVRAM is already in the install. The previous behaviour of this
        # harness was exactly that - seed from a saved artifact if one existed,
        # otherwise leave the NVRAM alone and warn - so refusing to provision
        # must not mean refusing to run.
        $known = ($script:CmosLayouts.Keys | Sort-Object) -join ', '
        Write-Warning ("No CMOS layout for PCem machine '$Machine' (known: $known), so its NVRAM " +
            'is being left as it is. If the machine halts at POST with no C: drive, its CMOS ' +
            'needs either a layout here or a saved-setup artifact.')
        return $null
    }

    $nvrDir = Join-Path $PcemRoot 'nvr'
    $seed = Join-Path (Join-Path $nvrDir 'default') ($Machine + '.nvr')
    if (-not (Test-Path -LiteralPath $seed -PathType Leaf)) {
        throw ("PCem at '$PcemRoot' ships no factory CMOS for '$Machine' (expected '$seed'). " +
            'That file is the only trustworthy source of the machine''s CMOS bytes; synthesising ' +
            'them here would be indistinguishable from a corrupt CMOS.')
    }

    $cmos = [byte[]]::new(128)
    $factory = [IO.File]::ReadAllBytes($seed)
    [Array]::Copy($factory, 0, $cmos, 0, [Math]::Min($factory.Length, $cmos.Length))

    $cmos[$layout.TypeOffset] = 0x0F
    $cmos[$layout.CylLow] = [byte]($Cylinders -band 0xFF)
    $cmos[$layout.CylHigh] = [byte](($Cylinders -shr 8) -band 0xFF)
    $cmos[$layout.Heads] = [byte]$Heads
    # Write precomp and landing zone describe the drive's physical layout, not
    # what the guest can address. IDE ignores both, so they are set to the
    # cylinder count rather than left at the factory 0xFF: a landing zone
    # below the last cylinder is a geometry the firmware can reject.
    $cmos[$layout.PrecompLow] = [byte]($Cylinders -band 0xFF)
    $cmos[$layout.PrecompHigh] = [byte](($Cylinders -shr 8) -band 0xFF)
    $cmos[$layout.LandingLow] = [byte]($Cylinders -band 0xFF)
    $cmos[$layout.LandingHigh] = [byte](($Cylinders -shr 8) -band 0xFF)
    # 0x38 packs the sector count into its low six bits with a control field
    # above it. The sector count is authored; the control field is cleared
    # rather than inherited, because the factory entry for this drive is
    # 0xFF throughout (no drive has ever been configured on it) and inheriting
    # those two bits would be authoring garbage. The control field is left
    # unset on purpose: its meaning is board-specific, and the drive is set to
    # the firmware's auto-detect type, so the firmware re-derives the whole
    # entry at POST anyway.
    if ($SectorsPerTrack -gt 0x3F) {
        throw ("SectorsPerTrack $($SectorsPerTrack) does not fit the six-bit field this Award " +
            'CMOS uses. A drive with more than 63 sectors per track needs its own layout entry ' +
            'rather than a truncated count.')
    }
    $cmos[$layout.Sectors] = [byte]($SectorsPerTrack -band 0x3F)

    # Vendor checksum. The firmware requires the checksum byte plus SumFrom..
    # SumTo to total zero, so the stored byte is the two's complement of the
    # data range. The byte is cleared before summing because on this layout it
    # sits below SumFrom and is not itself data.
    $cmos[$layout.Checksum] = 0
    $sum = 0
    for ($i = $layout.SumFrom; $i -le $layout.SumTo; $i++) { $sum += $cmos[$i] }
    $cmos[$layout.Checksum] = [byte]((0x100 - ($sum -band 0xFF)) -band 0xFF)

    # Cheap self-check: a CMOS this function writes must satisfy the rule it
    # just applied, or the machine halts at POST with "CMOS checksum failure"
    # and the cause is a bug here rather than something visible in a
    # screenshot.
    $verify = 0
    for ($i = $layout.SumFrom; $i -le $layout.SumTo; $i++) { $verify += $cmos[$i] }
    $verify += $cmos[$layout.Checksum]
    if (($verify -band 0xFF) -ne 0) {
        throw ("Internal error: wrote a '$Machine' CMOS whose checksum region does not total " +
            "zero (it totals 0x{0:X2})." -f ($verify -band 0xFF))
    }

    if (-not (Test-Path -LiteralPath $nvrDir -PathType Container)) {
        New-Item -ItemType Directory -Path $nvrDir -Force | Out-Null
    }
    $target = Join-Path $nvrDir ($ConfigName + '.' + $Machine + '.nvr')
    [IO.File]::WriteAllBytes($target, $cmos)

    return [pscustomobject]@{
        Nvr         = $target
        Machine     = $Machine
        Vendor      = $layout.Vendor
        Cylinders   = $Cylinders
        Heads       = $Heads
        Sectors     = $SectorsPerTrack
        Checksum    = ('0x{0:X2}' -f $cmos[$layout.Checksum])
    }
}

function Get-PcemMachineConfigText {
    <#
    .SYNOPSIS
        Emit the text of a PCem v17 machine config.

    .DESCRIPTION
        Flat keys, no section header - see the module header for why that is
        the shape PCem actually reads. gfxcard is omitted deliberately: an
        empty gfxcard resolves to index 0, standard VGA, which is Quake's
        guaranteed mode-13h path (src\pc.c:720-724). Naming a card here would
        make the run depend on a card ROM the ROM set may not carry, and
        would put a video-card timing difference into a measurement that is
        only meant to price the CPU.

        The window keys are optional and, when given, are written with their
        v17 names (window_w / window_h) rather than the window_width /
        window_height of a config format PCem no longer reads.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Machine,

        [Parameter(Mandatory = $true)][string]$HardDisk,
        [Parameter(Mandatory = $true)][int]$Cylinders,
        [Parameter(Mandatory = $true)][int]$Heads,
        [Parameter(Mandatory = $true)][int]$SectorsPerTrack,

        # cpus_i486[] index (src\cpu_tables.c): 12 = iDX4/100, 10 = i486DX2/66.
        [int]$CpuIndex = 12,

        # KiB. Quake needs >= 8 MB; 16 MB matches the DOSBox-X reference.
        [int]$MemKiB = 16384,

        [string]$Floppy,
        [int]$WindowWidth,
        [int]$WindowHeight
    )

    if ($Cylinders -lt 1 -or $Heads -lt 1 -or $SectorsPerTrack -lt 1) {
        throw ("Refusing to write a machine config with a degenerate CHS geometry: " +
            "$Cylinders/$Heads/$SectorsPerTrack.")
    }
    if ($MemKiB -lt 1) { throw "Refusing to write a machine config with mem_size $MemKiB KiB." }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("model = $Machine")
    $lines.Add('cpu_manufacturer = 0')
    $lines.Add("cpu = $CpuIndex")
    $lines.Add('fpu = builtin')
    $lines.Add('cpu_use_dynarec = 1')
    $lines.Add("mem_size = $MemKiB")
    $lines.Add('hdd_controller = ide')
    $lines.Add('cdrom_drive = 0')
    $lines.Add('cdrom_channel = -1')
    $lines.Add('zip_channel = -1')
    $lines.Add("hdc_fn = $HardDisk")
    $lines.Add("hdc_sectors = $SectorsPerTrack")
    $lines.Add("hdc_heads = $Heads")
    $lines.Add("hdc_cylinders = $Cylinders")
    if (-not [string]::IsNullOrWhiteSpace($Floppy)) {
        $lines.Add("disc_a = $Floppy")
        $lines.Add('drive_a_type = 7')
    }
    $lines.Add('mouse_type = 0')
    if ($WindowWidth -gt 0 -and $WindowHeight -gt 0) {
        $lines.Add("window_w = $WindowWidth")
        $lines.Add("window_h = $WindowHeight")
    }

    return ($lines -join "`r`n")
}

Export-ModuleMember -Function Set-PcemMachineNvr, Get-PcemMachineConfigText

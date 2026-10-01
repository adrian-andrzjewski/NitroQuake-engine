<#
.SYNOPSIS
    Wires PCem's [Paths] roms_paths to this project's ROM set.

.DESCRIPTION
    PCem ships no ROMs by design ("NO COPYRIGHTED ROM FILES ARE INCLUDED NOR
    WILL THEY BE"), and its first-run default roms_paths points at the install's
    own roms\ directory, which contains only roms.txt placeholders. Every ROM
    lookup goes through romfopen() (src\rom.c), which searches each directory in
    roms_paths in order, so the fix is a single key in pcem.cfg:

        [Paths]
        roms_paths = <ROM set>;<install>\roms

    pcem.cfg lives next to PCem.exe (src\pc.c:673). When the key is present it
    REPLACES the default path entirely (src\paths.c:161-162), so both the ROM
    set and the install's own roms directory are listed: the ROM set first (it
    carries the machine BIOS the manifest names and the video BIOS files), the
    install second
    for anything the set does not carry.

    The ROM set is consumed in place, never copied, so it stays the single
    source of truth (see pcemRomset in dos-toolchain.json). This script is
    idempotent: it rewrites only roms_paths and preserves every other key and
    section of an existing pcem.cfg.

    Every install recorded in the manifest is patched (the managed install used
    by 486-fidelity.ps1/bench486-dos.ps1, plus any extraInstalls used for
    interactive hand-runs), so both paths find the same ROM set.

.EXAMPLE
    .\tools\pcem-roms.ps1
#>
[CmdletBinding()]
param(
    [string]$ToolRoot,

    # Explicit install directories to patch. Defaults to every PCem install the
    # manifest records that actually exists on this machine.
    [string[]]$InstallPath,

    [string]$ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $PSScriptRoot 'dos-toolchain.json'
}
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

if ($null -eq $manifest.pcemRomset) {
    throw "The toolchain manifest has no 'pcemRomset' block. Add the ROM set location before wiring PCem."
}
$romsetPath = [IO.Path]::GetFullPath([string]$manifest.pcemRomset.path)
if (-not (Test-Path -LiteralPath $romsetPath -PathType Container)) {
    throw "ROM set directory '$romsetPath' does not exist (pcemRomset.path in '$ManifestPath')."
}

# The ROM set is only useful if the machine BIOS this project runs is actually
# in it. Check the exact file mem_bios.c loads for the machine's ROM_* id, at
# the exact size the manifest records, so a truncated download fails here rather
# than as a boot failure inside the emulator.
$biosRelative = ([string]$manifest.pcemRomset.bios) -replace '/', '\'
$biosFile = Join-Path $romsetPath $biosRelative
if (-not (Test-Path -LiteralPath $biosFile -PathType Leaf)) {
    throw "ROM set at '$romsetPath' is missing '$($manifest.pcemRomset.bios)'. PCem cannot boot the '$($manifest.pcemRomset.machine)' machine without it."
}
$biosLength = (Get-Item -LiteralPath $biosFile).Length
$expectedBiosBytes = [int]$manifest.pcemRomset.expectedBiosBytes
if ($biosLength -ne $expectedBiosBytes) {
    throw "BIOS '$biosFile' is $biosLength bytes; expected $expectedBiosBytes. Refusing to wire a corrupt ROM set."
}

# ---------------------------------------------------------------------------
# Resolve the installs to patch.
# ---------------------------------------------------------------------------
if ($InstallPath -and $InstallPath.Count -gt 0) {
    $installs = @($InstallPath | ForEach-Object { [IO.Path]::GetFullPath($_) })
}
else {
    $installs = New-Object System.Collections.Generic.List[string]
    if ($null -ne $manifest.pcem) {
        if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
            $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
            if ([string]::IsNullOrWhiteSpace($localAppData)) {
                throw 'Could not determine the Windows local application-data directory.'
            }
            $ToolRoot = Join-Path $localAppData '486quake\tools'
        }
        $managed = Join-Path ([IO.Path]::GetFullPath($ToolRoot)) ([string]$manifest.pcem.installDirectory)
        $installs.Add($managed)
    }
    if ($null -ne $manifest.pcem.extraInstalls) {
        foreach ($extra in @($manifest.pcem.extraInstalls)) {
            $installs.Add([IO.Path]::GetFullPath([string]$extra.installDirectory))
        }
    }
}

$patched = @()
$skipped = @()
foreach ($install in $installs) {
    if (-not (Test-Path -LiteralPath $install -PathType Container)) {
        $skipped += $install
        continue
    }
    if (-not (Test-Path -LiteralPath (Join-Path $install $manifest.pcem.executable) -PathType Leaf)) {
        $skipped += $install
        continue
    }

    $installRoms = Join-Path $install 'roms'
    # ';' is the path separator src\paths.c uses on Windows. The install's own
    # roms directory is listed second and may be missing entries entirely; it is
    # kept so any card ROM the set does not carry still resolves.
    $value = $romsetPath + ';' + $installRoms
    $pcemCfg = Join-Path $install 'pcem.cfg'

    $lines = @()
    if (Test-Path -LiteralPath $pcemCfg -PathType Leaf) {
        $lines = @(Get-Content -LiteralPath $pcemCfg)
    }

    # Merge: replace roms_paths inside an existing [Paths] section, append the
    # key to that section when the section exists without it, otherwise append
    # a fresh section. Case-insensitive, matching how PCem's own parser treats
    # nothing (it is case-sensitive, so we write the canonical spelling it
    # reads: roms_paths).
    $out = New-Object System.Collections.Generic.List[string]
    $sectionStart = -1      # index of the [Paths] line, -1 when absent
    $keyIndex = -1          # index of the roms_paths line inside [Paths]
    $sectionEnd = -1        # index just past the section's last line
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*\[(?<name>[^\]]+)\]\s*$') {
            if ($sectionStart -ge 0) { $sectionEnd = $i; break }
            if ($Matches['name'] -eq 'Paths') { $sectionStart = $i }
        }
        elseif ($sectionStart -ge 0 -and $line -match '^\s*roms_paths\s*=') {
            $keyIndex = $i
        }
    }
    if ($sectionStart -ge 0 -and $sectionEnd -lt 0) { $sectionEnd = $lines.Count }

    if ($sectionStart -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -ne '') { $out.Add('') }
        $out.Add('[Paths]')
        $out.Add('roms_paths = ' + $value)
    }
    else {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -eq $keyIndex) {
                $out.Add('roms_paths = ' + $value)
            }
            elseif ($i -eq $sectionEnd -and $keyIndex -lt 0) {
                $out.Add('roms_paths = ' + $value)
                $out.Add($lines[$i])
            }
            else {
                $out.Add($lines[$i])
            }
        }
        if ($keyIndex -lt 0 -and $sectionEnd -ge $lines.Count) {
            $out.Add('roms_paths = ' + $value)
        }
    }

    Set-Content -LiteralPath $pcemCfg -Value $out -Encoding ASCII
    $patched += [pscustomobject]@{ Install = $install; PcemCfg = $pcemCfg; Value = $value }
    Write-Host "wired  $pcemCfg"
    Write-Host "       roms_paths = $value"
}

if ($patched.Count -eq 0) {
    throw ("No PCem install was patched. Looked at:`n  " + ($installs -join "`n  ") +
        "`nInstall PCem (bootstrap-dos.ps1 -WithPcem) or pass -InstallPath.")
}

foreach ($s in $skipped) { Write-Host "skipped (not installed): $s" }
Write-Host ''
Write-Host "ROM set: $romsetPath"
Write-Host ("BIOS:    {0} ({1} bytes, verified)" -f $biosRelative, $biosLength)

$patched

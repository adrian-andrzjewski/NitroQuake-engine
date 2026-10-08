<#
.SYNOPSIS
    Classifies every instruction in a DOS build by the minimum x86 ISA level it
    requires, by disassembling the objects and the linked executable with the
    pinned DJGPP objdump.

.DESCRIPTION
    A raw byte grep is not good enough here.  `objdump -d` prints a hex byte
    column and a decoded mnemonic side by side, so a search for the text
    "0f af" matches byte pairs that straddle two instructions -- and it does,
    several hundred times, in this tree.  This tool parses the *instruction*
    boundary instead: it takes the hex byte column of each disassembly line,
    anchors on the first byte of each instruction, and only then looks at what
    follows.

    Every instruction is mapped to one of i386 / i486 / i586 / p6 / unknown.
    Anything the table does not recognise is counted as `unknown` and listed,
    so a gap in the table is visible rather than silently treated as 386-safe.
    That direction is deliberate: an unclassified instruction must never pass a
    gate by default.

.PARAMETER BuildRoot
    The build output directory, i.e. out\dos<suffix>.  Object files are read
    from every obj* subdirectory; the linked executable is read from this
    directory.

.PARAMETER ExeName
    Linked executable to audit.  Defaults to quake.exe.

.PARAMETER ObjectRoot
    Audit exactly this object directory instead of every obj* subdirectory of
    -BuildRoot.  A build root normally holds obj/, obj-bench/ and
    obj-bench-profile/ at once, so the default sweep double-counts and mixes
    objects from different selector sets.  That is harmless for a report and
    wrong for a gate: pass the objectRoot the build actually produced.

.PARAMETER ObjectNames
    Audit only these object file names (e.g. surf8.obj, math.obj), resolved
    inside each object directory.  A build recompiles its sources in place, so
    an object directory also accumulates objects from selector sets that are no
    longer active -- asm486_experiments.s when every implementation selector is
    'c', net_comx.c which is #included rather than compiled.  Those are stale,
    and auditing a directory therefore audits them too, which makes the count
    depend on build history rather than on the current sources.  Naming the
    objects removes that.

.PARAMETER MaxIsa
    Highest ISA level the caller is willing to accept.  Violations are counted
    and reported either way; see -FailOnViolation for whether they also fail.

.PARAMETER OutputJson
    Where to write the report.  Defaults to <BuildRoot>\isa-audit.json.

.PARAMETER FailOnViolation
    Exit non-zero when any instruction requires more than -MaxIsa, or when any
    instruction is unclassified.  This is the release-gate mode.  Without it the
    audit only reports, which is the mode used while a residual is being
    quantified rather than eliminated.

.PARAMETER Exempt
    Symbols to exclude from violation counting, as `object:symbol`.  An
    exemption never hides anything: the exempted instructions are counted and
    listed under `exempted` in the report.  It exists for things objdump cannot
    tell apart from code -- the constant table in crc.c lives in .text and is
    disassembled as if it were instructions.

.PARAMETER SkipExecutable
    Audit only the objects, not the linked executable. The linked i486 gate uses
    this with SectionAllowListJson, then checks the exact mapped opcode sites in
    the final binary through isa-audit-linked.ps1. That wrapper also includes
    CRT and runtime archive members selected by the linker.

.PARAMETER SectionAllowListJson
    Optional JSON array of `{ object, section }` pairs. When supplied, only those
    sections are classified or written to instruction details. The linked
    executable audit uses this to inspect the exact input code contributions in
    the linker map, excluding unused cold sections from pulled archive members.

.EXAMPLE
    .\tools\isa-audit.ps1 -BuildRoot out\dos-memasm-zneg4-... -MaxIsa i486

.EXAMPLE
    .\tools\isa-audit.ps1 -BuildRoot out\dos-i386-memasm-zneg4-... -MaxIsa i386 -FailOnViolation
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BuildRoot,
    [string]$ExeName = 'quake.exe',

    [string]$ObjectRoot,
    [string[]]$ObjectNames = @(),
    [ValidateSet('i386', 'i486', 'i586', 'p6')]
    [string]$MaxIsa = 'i486',
    [string]$OutputJson,
    [string]$InstructionDetailsJsonl,
    [string]$SectionAllowListJson,
    [string]$ObjectCodeDataProofJson,
    [switch]$FailOnViolation,
    [string[]]$Exempt = @(),
    [string[]]$ExemptRange = @(),
    [switch]$ExecutableOnly,
    [string]$AddressRangesJson,
    [switch]$SkipExecutable,
    [string]$ToolRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        throw 'Could not determine the Windows local application-data directory.'
    }
    $ToolRoot = Join-Path $localAppData '486quake\tools'
}
$ToolRoot = [IO.Path]::GetFullPath($ToolRoot)

$toolManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$djgppRoot = Join-Path $ToolRoot $toolManifest.djgpp.installDirectory
$objdump = Join-Path $djgppRoot ($toolManifest.djgpp.objdump -replace '/', [IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $objdump -PathType Leaf)) {
    throw "Required DJGPP tool is missing: '$objdump'. Run bootstrap-dos.ps1 first."
}

if (-not (Test-Path -LiteralPath $BuildRoot -PathType Container)) {
    throw "Build root not found: '$BuildRoot'."
}
$BuildRoot = (Resolve-Path -LiteralPath $BuildRoot).Path
if ([string]::IsNullOrWhiteSpace($OutputJson)) {
    $OutputJson = Join-Path $BuildRoot 'isa-audit.json'
}

# Rank order.  Anything above the requested maximum is a violation.
$isaRank = @{ i386 = 0; i486 = 1; i586 = 2; p6 = 3; unknown = 99 }
$maxRank = $isaRank[$MaxIsa]

# Two-byte (0F xx) opcode map. The fallback treats unlisted forms as unknown,
# so this table includes both newer instructions and supported i386 forms that
# need an explicit classification; keys are "0f" + second byte.
$twoByteIsa = @{
    '0f00' = 'i386'   # LLDT
    # 0F 01 is classified by its ModRM below: legacy descriptor/control
    # operations share this escape with much newer fixed-register encodings.
    '0f06' = 'i386'   # CLTS
    '0f08' = 'i486'   # INVD
    '0f09' = 'i486'   # WBINVD
    '0f0b' = 'i586'   # UD2 -- GCC emits this only in unreachable cold blocks
    '0f0d' = 'p6'     # PREFETCH
    '0f0e' = 'p6'     # FEMMS (3DNow! / K5)
    '0f0f' = 'unknown' # 3DNow! prefix
    # 0F 20..24 and 26 are special-register MOV forms, validated by ModRM below.
    '0f30' = 'i586'   # WRMSR
    '0f31' = 'i586'   # RDTSC
    '0f32' = 'i586'   # RDMSR
    '0f33' = 'i586'   # RDPMC
    '0f34' = 'i586'   # SYSENTER
    '0f35' = 'i586'   # SYSEXIT
    '0fa2' = 'i586'   # CPUID
    '0fa3' = 'i386'   # BT r/m,r
    '0fa4' = 'i386'   # SHLD r/m,r,imm8
    '0fa5' = 'i386'   # SHLD r/m,r,CL
    '0fa8' = 'i386'   # PUSH GS
    '0fa6' = 'unknown' # reserved in the documented target
    '0fa7' = 'unknown' # reserved in the documented target
    '0fae' = 'p6'     # LFENCE/MFENCE/SFENCE/CLFLUSH/LDMXCSR/STMXCSR
    '0fab' = 'i386'   # BTS r/m,r
    '0fac' = 'i386'   # SHRD r/m,r,imm8
    '0fad' = 'i386'   # SHRD r/m,r,CL
    '0faf' = 'i386'   # IMUL r32,r/m32 -- documented by the Intel 80386 manual
    '0fb0' = 'i486'   # CMPXCHG
    '0fb1' = 'i486'   # CMPXCHG
    '0fb8' = 'p6'     # POPCNT
    '0fb9' = 'unknown' # UD1
    '0fb2' = 'i386'   # LSS
    '0fb4' = 'i386'   # LFS
    '0fb5' = 'i386'   # LGS
    '0fb3' = 'i386'   # BTR r/m,r
    '0fbb' = 'i386'   # BTC r/m,r
    '0fc0' = 'i486'   # XADD
    '0fc1' = 'i486'   # XADD
    # CMPXCHG8B is a Pentium instruction, not a 486 one. Both of these entries
    # said i486, and 0fc7 additionally carried the comment "RDRAND-ish", which is
    # a third ISA (RDRAND is SSE4a/Bulldozer, two generations later still) --
    # so one table row was standing in for three different levels.
    # isa-audit-source.py already had cmpxchg8b in its i586 list; the two tools
    # disagreed, and this one is the one wired into the build gate.
    # Measured: neither encoding occurs in the i486 or the i386 object set, so
    # correcting this moves no gate number.  It matters the moment the compiler
    # emits either, which is exactly when the gate has to be right.
    '0fc6' = 'i586'   # CMPXCHG8B
    '0fc7' = 'i586'   # CMPXCHG8B
    '0fc3' = 'p6'     # MOVNTI (SSE2)
}
# MMX and SSE: 0F 10..0F 17, 0F 28..0F 2F, 0F 50..0F 77, 0F 78, 0F 79,
# 0F 6F, 0F 7E, 0F 7F, 0F D4..0F FF.
foreach ($i in (@(0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x1E, 0x1F) +
    (0x28..0x2F) + (0x50..0x77) + @(0x6F, 0x78, 0x79, 0x7E, 0x7F) + (0xD4..0xFF))) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'p6'
}
# CMOVcc: 0F 40..4F, introduced with P6; never valid on i486.
for ($i = 0x40; $i -le 0x4F; $i++) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'p6'
}
# SETcc: 0F 90..9F
for ($i = 0x90; $i -le 0x9F; $i++) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'i386'
}
# BSWAP: 0F C8..CF
for ($i = 0xC8; $i -le 0xCF; $i++) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'i486'
}

$objectDirectories = @()
if (-not $ExecutableOnly) {
    $objectDirectories = if ([string]::IsNullOrWhiteSpace($ObjectRoot)) {
        @(Get-ChildItem -LiteralPath $BuildRoot -Directory -Filter 'obj*' -ErrorAction SilentlyContinue)
    }
    else {
        if (-not (Test-Path -LiteralPath $ObjectRoot -PathType Container)) {
            throw "Object root not found: '$ObjectRoot'."
        }
        @(Get-Item -LiteralPath (Resolve-Path -LiteralPath $ObjectRoot).Path)
    }
}
# Two states, not one: "no -ObjectNames given, sweep every object" and "-ObjectNames
# given, audit exactly those". $null was doing double duty as the off state, which
# made line 215's `$objectNameFilter.Count` a property read on $null -- a
# terminating error under Set-StrictMode -Version Latest, so omitting -ObjectNames
# aborted the audit instead of widening it. A boolean carries the state and the set
# is always a real set.
$filterByName = ($ObjectNames.Count -gt 0)
$objectNameFilter = [System.Collections.Generic.HashSet[string]]::new([string[]]$ObjectNames)
$addressRanges = @()
if (-not [string]::IsNullOrWhiteSpace($AddressRangesJson)) {
    if ($SkipExecutable) { throw '-AddressRangesJson requires executable disassembly; do not combine it with -SkipExecutable.' }
    if (-not (Test-Path -LiteralPath $AddressRangesJson -PathType Leaf)) { throw "Address range list not found: '$AddressRangesJson'." }
    $addressRanges = @(Get-Content -LiteralPath $AddressRangesJson -Raw | ConvertFrom-Json)
    if ($addressRanges.Count -eq 0) { throw "Address range list '$AddressRangesJson' is empty." }
    foreach ($range in $addressRanges) {
        if ([long]$range.end -le [long]$range.start) { throw "Invalid executable address range '$($range.label)'." }
    }
}
$allowedSectionKeys = $null
if (-not [string]::IsNullOrWhiteSpace($SectionAllowListJson)) {
    if (-not (Test-Path -LiteralPath $SectionAllowListJson -PathType Leaf)) {
        throw "Section allow-list not found: '$SectionAllowListJson'."
    }
    $allowedSectionKeys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $allowedSections = @(Get-Content -LiteralPath $SectionAllowListJson -Raw | ConvertFrom-Json)
    if ($allowedSections.Count -eq 0) { throw "Section allow-list '$SectionAllowListJson' is empty." }
    foreach ($allowedSection in $allowedSections) {
        $null = $allowedSectionKeys.Add([string]$allowedSection.object + '|' + [string]$allowedSection.section)
    }
}
if ($ExecutableOnly -and $filterByName) { throw '-ExecutableOnly cannot be combined with -ObjectNames.' }
$targets = New-Object System.Collections.Generic.List[object]
# Seeded from the request, so a name that matched nothing is still reported.
# This list used to start empty and only ever had entries removed from it, which
# meant the check below could not fire and a typo in -ObjectNames silently
# audited fewer objects than the caller asked for.
$missingObjects = New-Object System.Collections.Generic.List[string]
foreach ($requestedObject in $objectNameFilter) {
    $missingObjects.Add($requestedObject)
}
foreach ($dir in $objectDirectories) {
    foreach ($obj in (Get-ChildItem -LiteralPath $dir.FullName -Filter '*.obj' -File | Sort-Object Name)) {
        if ($filterByName) {
            if (-not $objectNameFilter.Contains($obj.Name)) {
                continue
            }
            $missingObjects.Remove($obj.Name) | Out-Null
        }
        $targets.Add([pscustomobject]@{ kind = 'object'; name = $obj.Name; path = $obj.FullName })
    }
}
if ($filterByName -and $missingObjects.Count -gt 0) {
    throw ("Named objects were not found under '{0}': {1}" -f (($objectDirectories | ForEach-Object { $_.FullName }) -join ', '), ($missingObjects -join ', '))
}
$exePath = Join-Path $BuildRoot $ExeName
if (((-not $SkipExecutable) -or $ExecutableOnly) -and (Test-Path -LiteralPath $exePath -PathType Leaf)) {
    $targets.Add([pscustomobject]@{ kind = 'executable'; name = $ExeName; path = $exePath })
}
if ($ExecutableOnly -and $targets.Count -ne 1) { throw "-ExecutableOnly expected '$exePath', but the executable was not found." }
if ($addressRanges.Count -gt 0 -and -not ($targets | Where-Object kind -eq 'executable')) {
    throw '-AddressRangesJson was provided but the executable is not an audit target.'
}

if ($targets.Count -eq 0) {
    throw "No objects or executable found under '$BuildRoot'."
}

$count386 = 0
$count486 = 0
$count586 = 0
$countP6 = 0
$countUnknown = 0
$instructionCount = 0
$continuationLineCount = 0
$violations = New-Object System.Collections.Generic.List[object]
$unclassified = New-Object System.Collections.Generic.List[object]
$exempted = New-Object System.Collections.Generic.List[object]
$instructionDetailLines = New-Object System.Collections.Generic.List[string]
$encodingTotals = [ordered]@{}

# Normalise the exemption list into "object:symbol" keys, so a caller can write
# `crc.obj:_crctable` without also having to know the object kind.
$exemptKeys = New-Object System.Collections.Generic.HashSet[string]
foreach ($entry in $Exempt) {
    $parts = $entry -split ':', 2
    if ($parts.Count -ne 2) {
        throw "Malformed -Exempt entry '$entry'; expected 'object:symbol'."
    }
    $null = $exemptKeys.Add("$($parts[0]):$($parts[1])")
}
$parsedExemptRanges = New-Object System.Collections.Generic.List[object]
foreach ($entry in $ExemptRange) {
    $parts = $entry -split ':', 4
    if ($parts.Count -ne 4) { throw "Malformed -ExemptRange entry '$entry'; expected 'object:section:start:end'." }
    $startText = $parts[2] -replace '^0x', ''
    $endText = $parts[3] -replace '^0x', ''
    if ($startText -notmatch '^[0-9a-fA-F]+$' -or $endText -notmatch '^[0-9a-fA-F]+$') {
        throw "Malformed -ExemptRange bounds in '$entry'; use hexadecimal offsets."
    }
    $start = [Convert]::ToInt64($startText, 16)
    $end = [Convert]::ToInt64($endText, 16)
    if ($end -le $start) { throw "Malformed -ExemptRange '$entry'; the end must follow the start." }
    $parsedExemptRanges.Add([pscustomobject]@{ object = $parts[0]; section = $parts[1]; start = $start; end = $end; specification = $entry })
}

$byteColumnPattern = [regex]::new('^\s*[0-9a-fA-F]+:\t((?:[0-9a-fA-F]{2} )+)[ ]*\t')
$addressPattern = [regex]::new('^\s*([0-9a-fA-F]+):\t')
$sectionPattern = [regex]::new('^Disassembly of section (.+):$')
$symbolPattern = [regex]::new('^[0-9a-fA-F]+ <(.+)>:$')
$disassemblyLinePattern = [regex]::new('^\s*[0-9a-fA-F]+:\t')
# Prefixes that do not change the instruction's ISA level.  LOCK (F0) and the
# REP family (F2/F3) are included: the opcode behind them decides, and skipping
# them is what keeps `lock cmpxchg` from being misfiled as i386.
$ignorablePrefixes = @('66', '67', '2e', '36', '3e', '26', '64', '65', 'f0', 'f2', 'f3')

# ModRM reg field is bits 3..5 of the ModRM byte, and mod is bits 6..7.
# Reading the second hex digit instead of shifting gets it wrong whenever bit 3
# is set -- `f7 c1` is TEST r/m,r32 (i386), not TEST r/m,imm32 (i486) -- so this
# must be a shift and a mask.
function Get-ModRmRegField {
    param([AllowEmptyString()][AllowNull()][string]$ModRm)
    if ([string]::IsNullOrEmpty($ModRm) -or $ModRm -notmatch '^[0-9a-f]{2}$') { return $null }
    return (([Convert]::ToInt32($ModRm, 16)) -shr 3) -band 7
}

function Get-ModRmModField {
    param([AllowEmptyString()][AllowNull()][string]$ModRm)
    if ([string]::IsNullOrEmpty($ModRm) -or $ModRm -notmatch '^[0-9a-f]{2}$') { return $null }
    return (([Convert]::ToInt32($ModRm, 16)) -shr 6) -band 3
}

$objectCodeRanges = @{}
if (-not [string]::IsNullOrWhiteSpace($ObjectCodeDataProofJson)) {
    if ($ExecutableOnly) { throw 'Object code/data proof cannot be used for raw executable disassembly.' }
    & python (Join-Path $PSScriptRoot 'coff-code-data.py') --verify-proof-index $ObjectCodeDataProofJson
    if ($LASTEXITCODE -ne 0) { throw 'The object code/data boundary evidence failed byte/relocation verification.' }
    $index = Get-Content -LiteralPath $ObjectCodeDataProofJson -Raw | ConvertFrom-Json
    foreach ($path in $index.proofs) {
        $proof = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $name = [IO.Path]::GetFileName($proof.object)
        if ($objectCodeRanges.ContainsKey($name)) { throw "Duplicate code/data proof for '$name'." }
        $objectCodeRanges[$name] = $proof
    }
}

foreach ($target in $targets) {
    $targetRanges = New-Object System.Collections.Generic.List[object]
    if ($target.kind -eq 'executable' -and $addressRanges.Count -gt 0) {
        foreach ($range in $addressRanges) { $targetRanges.Add($range) }
    }
    elseif ($target.kind -eq 'object' -and $objectCodeRanges.ContainsKey($target.name)) {
        $proof = $objectCodeRanges[$target.name]
        if ((Get-FileHash -LiteralPath $target.path -Algorithm SHA256).Hash -ne $proof.objectSha256) {
            throw "Code/data proof does not match '$($target.path)'."
        }
        foreach ($range in $proof.ranges) {
            if ($range.kind -ne 'code') { continue }
            if ($range.codeMode -notin @(16,32) -or $range.section -notmatch '^\.text') {
                throw 'Object code/data evidence names an unsupported mode or section.'
            }
            $targetRanges.Add([pscustomobject]@{ start = [long]$range.start; end = [long]$range.end;
                label = 'proved-compiler-code'; codeMode = [int]$range.codeMode; section = [string]$range.section })
        }
    }
    else {
        # -d stops at every symbol, including a patch label in the immediate
        # byte of an INT instruction. -D crosses those labels correctly, but
        # must be restricted to actual CODE sections so it never decodes .data.
        $headers = & $objdump -h $target.path 2>$null
        if ($LASTEXITCODE -ne 0) { throw "objdump section discovery failed on '$($target.path)'." }
        $pendingSection = $null
        foreach ($headerLine in $headers) {
            if ($headerLine -match '^\s*\d+\s+(\S+)\s+([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+') {
                $pendingSection = [pscustomobject]@{
                    section = $Matches[1]
                    size = [Convert]::ToInt64($Matches[2],16)
                    start = [Convert]::ToInt64($Matches[3],16)
                }
            }
            elseif ($null -ne $pendingSection -and $headerLine -match '\bCODE\b') {
                if ($pendingSection.size -gt 0 -and ($null -eq $allowedSectionKeys -or
                    $allowedSectionKeys.Contains($target.name + '|' + $pendingSection.section))) {
                    $targetRanges.Add([pscustomobject]@{
                        start = $pendingSection.start
                        end = $pendingSection.start + $pendingSection.size
                        section = $pendingSection.section
                        codeMode = 32
                        label = 'complete-code-section'
                    })
                }
                $pendingSection = $null
            }
        }
    }
    foreach ($targetRange in $targetRanges) {
    $symbol = '<none>'
    $section = '<none>'
    $codeMode = 32
    if ($null -ne $targetRange -and $null -ne $targetRange.PSObject.Properties['codeMode']) {
        $codeMode = [int]$targetRange.codeMode
    }
    $selectedSection = if ($null -ne $targetRange.PSObject.Properties['section']) { $targetRange.section } else { '.text' }
    $lines = & python (Join-Path $PSScriptRoot 'isa-disassemble.py') `
        --target $target.path --section $selectedSection `
        --start ('0x{0:x}' -f [long]$targetRange.start) `
        --end ('0x{0:x}' -f [long]$targetRange.end) --mode $codeMode --objdump $objdump
    if ($LASTEXITCODE -ne 0) {
        throw "objdump failed on '$($target.path)' with exit code $LASTEXITCODE."
    }
    foreach ($line in $lines) {
        $sectionMatch = $sectionPattern.Match($line)
        if ($sectionMatch.Success) {
            $section = $sectionMatch.Groups[1].Value
            continue
        }
        $symbolMatch = $symbolPattern.Match($line)
        if ($symbolMatch.Success) {
            $symbol = $symbolMatch.Groups[1].Value
            continue
        }
        if ($null -ne $allowedSectionKeys -and
            -not $allowedSectionKeys.Contains($target.name + '|' + $section)) {
            continue
        }
        # The hex byte column is the run of byte pairs between the first tab and
        # the second tab.  Anchoring here is what keeps the audit from matching
        # byte pairs that straddle two instructions.
        $byteMatch = $byteColumnPattern.Match($line)
        if (-not $byteMatch.Success) {
            # --insn-width=16 covers the architectural 15-byte maximum. Any
            # unparsed instruction-looking row is a parser error, never evidence
            # that can be counted and silently discarded.
            if ($disassemblyLinePattern.Match($line).Success) {
                throw "Unparsed objdump instruction row in '$($target.path)': $line"
            }
            continue
        }

        $bytes = $byteMatch.Groups[1].Value.Trim() -split ' '
        $b0 = $bytes[0]
        $b1 = $null
        if ($bytes.Count -ge 2) { $b1 = $bytes[1] }

        # Strip prefixes that do not change the instruction's ISA level.
        $skip = 0
        while (($skip -lt $bytes.Count) -and ($b0 -in $ignorablePrefixes)) {
            $skip++
            if ($b1 -eq $null) { break }
            $b0 = $b1
            $b1 = if ($bytes.Count -ge ($skip + 2)) { $bytes[$skip + 1] } else { $null }
        }
        $isa = $null
        if ($b0 -eq '0f') {
            if ($b1 -eq $null) {
                $isa = 'unknown'
            }
            else {
                $key = '0f' + $b1
                if ($b1 -in @('20', '21', '22', '23', '24', '26')) {
                    # Intel i486 Programmer's Reference Manual, chapters 4/26:
                    # CR0/2/3, DR0..3/6/7 and TR3..7 are documented. MOV CR4
                    # is a later target, despite sharing MOV's old opcode.
                    $isa = 'unknown'
                    if ($bytes.Count -ge ($skip + 3)) {
                        $specialModrm = $bytes[$skip + 2]
                        $specialReg = Get-ModRmRegField -ModRm $specialModrm
                        $specialMod = Get-ModRmModField -ModRm $specialModrm
                        if ($specialMod -eq 3) {
                            if ($b1 -in @('20', '22')) {
                                if ($specialReg -in @(0, 2, 3)) { $isa = 'i386' }
                                elseif ($specialReg -eq 4) { $isa = 'i586' }
                            }
                            elseif ($b1 -in @('21', '23')) {
                                if ($specialReg -in @(0, 1, 2, 3, 6, 7)) { $isa = 'i386' }
                            }
                            else {
                                if ($specialReg -in @(6, 7)) { $isa = 'i386' }
                                elseif ($specialReg -in @(3, 4, 5)) { $isa = 'i486' }
                            }
                        }
                    }
                }
                elseif ($twoByteIsa.ContainsKey($key)) {
                    $isa = $twoByteIsa[$key]
                }
                elseif ($b1 -eq '01') {
                    $isa = 'unknown' # validated using ModRM below
                }
                elseif ($b1 -eq 'ba') {
                    $isa = 'i386'   # BT/BTS/BTR/BTC with an immediate: 386
                }
                else {
                    # 0F 80..8F jcc rel32, 0F B6/B7/BE/BF movzx/movsx, 0F BC/BD
                    # bsf/bsr and 0F A0/A1/A8/A9 push/pop fs/gs
                    # are all i386.  Everything else in the 0F map that is not
                    # listed above is newer than this build's toolchain can emit.
                    $second = [Convert]::ToInt32($b1, 16)
                    if (($second -ge 0x80 -and $second -le 0x8F) -or
                        ($second -in @(0xB6, 0xB7, 0xBE, 0xBF, 0xBC, 0xBD, 0xA0, 0xA1, 0xA8, 0xA9)) -or
                        ($second -in @(0x02, 0x03))) {
                        $isa = 'i386'
                    }
                    else {
                        $isa = 'unknown'
                    }
                }
            }
            if ($b1 -eq '01' -and $bytes.Count -ge ($skip + 3)) {
                $modrm = $bytes[$skip + 2]
                $regField = Get-ModRmRegField -ModRm $modrm
                $modField = Get-ModRmModField -ModRm $modrm
                # SGDT/SIDT/LGDT/LIDT require memory; SMSW/LMSW also allow
                # registers. INVLPG is the i486 memory-only /7 form. Reject
                # fixed register encodings such as MONITOR, XGETBV, RDTSCP.
                if (($regField -in @(4, 6)) -or
                    (($modField -ne 3) -and ($regField -in @(0, 1, 2, 3)))) {
                    $isa = 'i386'
                }
                elseif (($modField -ne 3) -and ($regField -eq 7)) {
                    $isa = 'i486'
                }
            }
        }
        elseif ($b0 -in @('f6', 'f7')) {
            $isa = if ((Get-ModRmRegField -ModRm $b1) -eq 1) { 'unknown' } else { 'i386' }
        }
        elseif ($b0 -match '^[d][89a-f]$') {
            # Distinguish legacy x87 memory forms from newer register forms.
            #
            #   DA/DB /0..3 register forms are FCMOVcc (P6).
            #   DB/DF /5..6 register forms are F(U)COMI / F(U)COMIP (P6).
            #   DB /5 memory is FLD m80; DF /5 memory is FILD m64int. Those
            #   remain valid legacy forms and must not be rejected.
            #
            #   DB, DD and DF /1 in memory form are FISTTP, added with SSE3.
            $isa = 'i386'
            $regField = Get-ModRmRegField -ModRm $b1
            $modField = Get-ModRmModField -ModRm $b1
            if ($null -ne $regField) {
                if (($b0 -in @('da', 'db')) -and ($modField -eq 3) -and ($regField -le 3)) {
                    $isa = 'p6'
                }
                elseif (($b0 -in @('db', 'df')) -and ($modField -eq 3) -and ($regField -in @(5, 6))) {
                    $isa = 'p6'
                }
                elseif (($b0 -in @('db', 'dd', 'df')) -and ($regField -eq 1) -and ($modField -ne 3)) {
                    $isa = 'p6'
                }
            }
        }
        elseif (($b0 -in @('c4', 'c5', '62')) -and
                ((Get-ModRmModField -ModRm $b1) -eq 3)) {
            # In 32-bit mode VEX/EVEX use mod=11, invalid for the legacy
            # memory-only LES/LDS/BOUND instructions sharing these opcodes.
            $isa = 'p6'
        }
        else {
            # The one-byte 80386 map defines all remaining opcodes except these
            # reserved/undocumented values. Group encodings are checked below.
            $isa = if ($b0 -in @('82','d6','f1')) { 'unknown' } else { 'i386' }
        }

        # documented-486-encoding-policy: reject reserved operands and prefixes,
        # even if a modern disassembler supplies an old-looking mnemonic.
        # Sources: Intel 80386 PRM appendix A / section 17.2; Intel 80387 PRM
        # appendix A; Intel i486 PRM instruction formats and LOCK restrictions.
        $reg = Get-ModRmRegField -ModRm $b1
        $mod = Get-ModRmModField -ModRm $b1
        if ($skip -ge $bytes.Count) { $isa = 'unknown' }
        if ($b0 -in @('8d','c4','c5','62') -and ($null -eq $mod -or $mod -eq 3)) {
            if ($isa -ne 'p6') { $isa = 'unknown' }
        }
        if (($b0 -eq '8c' -and ($null -eq $reg -or $reg -gt 5)) -or
            ($b0 -eq '8e' -and ($null -eq $reg -or $reg -in @(1,6,7))) -or
            ($b0 -in @('8f','c6','c7') -and ($null -eq $reg -or $reg -ne 0)) -or
            ($b0 -eq 'fe' -and ($null -eq $reg -or $reg -gt 1)) -or
            ($b0 -eq 'ff' -and ($null -eq $reg -or $reg -eq 7 -or ($reg -in @(3,5) -and $mod -eq 3))) -or
            ($b0 -in @('c0','c1','d0','d1','d2','d3') -and ($null -eq $reg -or $reg -eq 6)) -or
            ($b0 -in @('d4','d5') -and $b1 -ne '0a')) { $isa = 'unknown' }
        if ($b0 -eq '0f' -and $bytes.Count -gt ($skip+2)) {
            $reg = Get-ModRmRegField -ModRm $bytes[$skip+2]
            $mod = Get-ModRmModField -ModRm $bytes[$skip+2]
            if (($b1 -eq '00' -and $reg -gt 5) -or
                ($b1 -eq 'ba' -and $reg -lt 4) -or
                ($b1 -in @('b2','b4','b5') -and $mod -eq 3) -or
                ($b1 -match '^9[0-9a-f]$' -and $reg -ne 0)) { $isa = 'unknown' }
        }
        if ($b0 -match '^d[89a-f]$' -and $null -ne $b1) {
            $reg = Get-ModRmRegField -ModRm $b1
            $mod = Get-ModRmModField -ModRm $b1
            $operand = [Convert]::ToInt32($b1,16)
            $documented = $false
            if ($mod -ne 3) {
                $documented = switch ($b0) {
                    d8 { $true }; d9 { $reg -in @(0,2,3,4,5,6,7) }
                    da { $true }; db { $reg -in @(0,2,3,5,7) }
                    dc { $true }; dd { $reg -in @(0,2,3,4,6,7) }
                    de { $true }; df { $reg -ne 1 }
                }
            } else {
                $documented = switch ($b0) {
                    d8 { $true }
                    d9 { ($operand -ge 0xc0 -and $operand -le 0xcf) -or $operand -eq 0xd0 -or
                        $operand -in @(0xe0,0xe1,0xe4,0xe5) -or
                        ($operand -ge 0xe8 -and $operand -le 0xee) -or $operand -ge 0xf0 }
                    da { $operand -eq 0xe9 }
                    db { $operand -in @(0xe0,0xe1,0xe2,0xe3,0xe4) } # obsolete documented FNOP encodings included
                    dc { ($operand -ge 0xc0 -and $operand -le 0xcf) -or $operand -ge 0xe0 }
                    dd { ($operand -ge 0xc0 -and $operand -le 0xc7) -or
                         ($operand -ge 0xd0 -and $operand -le 0xef) }
                    de { ($operand -ge 0xc0 -and $operand -le 0xcf) -or $operand -eq 0xd9 -or $operand -ge 0xe0 }
                    df { $operand -eq 0xe0 }
                }
            }
            if (-not $documented -and $isa -ne 'p6') { $isa = 'unknown' }
        }
        $prefixGroups = @{}
        $hasLock = $false; $hasRepeat = $false; $hasOperandPrefix = $false
        for ($prefixIndex=0; $prefixIndex -lt $skip; $prefixIndex++) {
            $prefix = $bytes[$prefixIndex]
            $group = switch ($prefix) {
                66 { 3 }; 67 { 4 }; f0 { 1 }; f2 { 1 }; f3 { 1 }; default { 2 }
            }
            if ($prefixGroups.ContainsKey($group)) { $isa = 'unknown' }
            $prefixGroups[$group] = $true
            if ($prefix -eq 'f0') { $hasLock = $true }
            if ($prefix -in @('f2','f3')) { $hasRepeat = $true }
            if ($prefix -eq '66') { $hasOperandPrefix = $true }
        }
        if ($b0 -eq '0f' -and $b1 -match '^c[89a-f]$' -and
            (($codeMode -eq 32 -and $hasOperandPrefix) -or ($codeMode -eq 16 -and -not $hasOperandPrefix))) {
            $isa = 'unknown'
        }
        if ($hasRepeat -and $b0 -notin @('6c','6d','6e','6f','a4','a5','a6','a7','aa','ab','ac','ad','ae','af')) {
            $isa = if ($b0 -eq '90' -and $bytes[0] -eq 'f3') { 'p6' } else { 'unknown' }
        }
        if ('f2' -in $bytes[0..([Math]::Max(0,$skip-1))] -and $skip -gt 0 -and
            $b0 -notin @('a6','a7','ae','af')) { $isa = 'unknown' }
        if ($hasLock) {
            $lockable = $false
            if ($mod -ne 3 -and $null -ne $mod) {
                $lockable = ($b0 -in @('00','01','08','09','10','11','18','19','20','21','28','29','30','31','86','87')) -or
                    ($b0 -in @('80','81','83') -and $reg -ne 7) -or
                    ($b0 -in @('f6','f7') -and $reg -in @(2,3)) -or
                    ($b0 -in @('fe','ff') -and $reg -in @(0,1)) -or
                    ($b0 -eq '0f' -and ($b1 -in @('ab','b0','b1','b3','bb','c0','c1') -or ($b1 -eq 'ba' -and $reg -in @(5,6,7))))
            }
            if (-not $lockable) { $isa = 'unknown' }
        }
        $decoded = $line.Substring($line.LastIndexOf("`t") + 1).Trim()
        if ($decoded -match '\(bad\)|^\.byte\b') { $isa = 'unknown' }

        $instructionCount++
        switch ($isa) {
            'i386' { $count386++ }
            'i486' { $count486++ }
            'i586' { $count586++ }
            'p6' { $countP6++ }
            default { $countUnknown++ }
        }

        if (($isaRank[$isa] -gt $maxRank) -or ($isa -eq 'unknown')) {
            $addressMatch = $addressPattern.Match($line)
            if (-not $addressMatch.Success) {
                throw "Could not recover an instruction address from '$($target.path)': $line"
            }
            $instructionAddress = [Convert]::ToInt64($addressMatch.Groups[1].Value, 16)
            $decoded = $line.Substring($line.LastIndexOf("`t") + 1).Trim()
            $record = [pscustomobject]@{
                kind = $target.kind
                object = $target.name
                symbol = $symbol
                required = $isa
                count = 1
                example = "$($bytes[0..([Math]::Min(3, $bytes.Count - 1))] -join ' ')  $decoded"
                encoding = if ($bytes.Count -ge 2 -and $b0 -eq '0f') { "0f $($bytes[1])" } else { $b0 }
            }
            $rangeExempt = $false
            foreach ($range in $parsedExemptRanges) {
                if ([string]::Equals($range.object, $target.name, [StringComparison]::OrdinalIgnoreCase) -and
                    [string]::Equals($range.section, $section, [StringComparison]::Ordinal) -and
                    $instructionAddress -ge $range.start -and $instructionAddress -lt $range.end) {
                    $rangeExempt = $true
                    break
                }
            }
            if ($exemptKeys.Contains("$($target.name):$symbol") -or $rangeExempt) {
                $exempted.Add($record)
            }
            else {
                if ($isa -eq 'unknown') { $unclassified.Add($record) }
                if ($isaRank[$isa] -gt $maxRank) {
                    $violations.Add($record)
                    $encodingTotals["$($record.encoding) ($isa)"]++
                }
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($InstructionDetailsJsonl)) {
            $addressMatch = $addressPattern.Match($line)
            if (-not $addressMatch.Success) {
                throw "Could not recover an instruction address from '$($target.path)': $line"
            }
            $decoded = $line.Substring($line.LastIndexOf("`t") + 1).Trim()
            $detail = [ordered]@{
                object = $target.name
                path = $target.path
                section = $section
                address = [Convert]::ToInt64($addressMatch.Groups[1].Value, 16)
                symbol = $symbol
                rangeLabel = if ($null -eq $targetRange) { $null } else { $targetRange.label }
                bytes = @($bytes)
                isa = $isa
                codeMode = $codeMode
                decoded = $decoded
            }
            $instructionDetailLines.Add(($detail | ConvertTo-Json -Depth 4 -Compress))
        }
    }
    }
}

if (-not [string]::IsNullOrWhiteSpace($InstructionDetailsJsonl)) {
    $detailDirectory = Split-Path -Parent $InstructionDetailsJsonl
    if (-not [string]::IsNullOrWhiteSpace($detailDirectory)) {
        New-Item -ItemType Directory -Path $detailDirectory -Force | Out-Null
    }
    [IO.File]::WriteAllLines(
        [IO.Path]::GetFullPath($InstructionDetailsJsonl),
        [string[]]$instructionDetailLines,
        [Text.UTF8Encoding]::new($false))
}

# Collapse to one row per (kind, object, symbol, required) with a count, so a
# report stays readable when a compiler-side residual runs to a hundred-odd
# sites.
function Collapse-IsoRows {
    param([System.Collections.Generic.List[object]]$Rows)
    $index = [ordered]@{}
    foreach ($row in $Rows) {
        $key = "$($row.kind)`u{1f}$($row.object)`u{1f}$($row.symbol)`u{1f}$($row.required)"
        if ($index.Contains($key)) {
            $index[$key].count++
        }
        else {
            $copy = [pscustomobject]@{
                kind = $row.kind
                object = $row.object
                symbol = $row.symbol
                required = $row.required
                count = 1
                example = $row.example
            }
            $index[$key] = $copy
        }
    }
    return @($index.Values)
}

$collapsedViolations = @(Collapse-IsoRows -Rows $violations | Sort-Object -Property required, object, symbol)
$collapsedUnclassified = @(Collapse-IsoRows -Rows $unclassified | Sort-Object -Property object, symbol)
$collapsedExempted = @(Collapse-IsoRows -Rows $exempted | Sort-Object -Property object, symbol)

$report = [ordered]@{
    schema = 1
    buildRoot = $BuildRoot
    maxIsa = $MaxIsa
    executable = $exePath
    executableOnly = [bool]$ExecutableOnly
    addressRangesJson = if ([string]::IsNullOrWhiteSpace($AddressRangesJson)) { $null } else { [IO.Path]::GetFullPath($AddressRangesJson) }
    disassemblyRangeCount = $addressRanges.Count
    objectDirectories = @($objectDirectories | ForEach-Object { $_.Name })
    objectCount = @($targets | Where-Object kind -eq 'object').Count
    executableCount = @($targets | Where-Object kind -eq 'executable').Count
    instructionCount = $instructionCount
    instructionDetailsJsonl = if ([string]::IsNullOrWhiteSpace($InstructionDetailsJsonl)) { $null } else { [IO.Path]::GetFullPath($InstructionDetailsJsonl) }
    continuationLineCount = $continuationLineCount
    isaTotals = [ordered]@{
        i386 = $count386
        i486 = $count486
        i586 = $count586
        p6 = $countP6
        unknown = $countUnknown
    }
    violationCount = $violations.Count
    unclassifiedCount = $unclassified.Count
    exemptedCount = $exempted.Count
    exemptions = @($exemptKeys | Sort-Object)
    rangeExemptions = @($parsedExemptRanges | ForEach-Object {
        [ordered]@{ object = $_.object; section = $_.section; start = ('0x{0:x}' -f $_.start); end = ('0x{0:x}' -f $_.end); specification = $_.specification }
    })
    # Encodings that actually exceed the maximum, in one line each.  This is the
    # number that matters: a handful of encodings means a handful of decisions,
    # whereas a long site list means the compiler is choosing them.
    violationEncodings = @($encodingTotals.GetEnumerator() | ForEach-Object {
            [ordered]@{ encoding = $_.Key; count = $_.Value }
        })
    result = if ($violations.Count -eq 0 -and $unclassified.Count -eq 0) {
        'PASS'
    }
    elseif ($violations.Count -eq 0) {
        'INCOMPLETE'
    }
    else {
        'FAIL'
    }
    violations = @($collapsedViolations | ForEach-Object {
            [ordered]@{
                kind = $_.kind
                object = $_.object
                symbol = $_.symbol
                required = $_.required
                count = $_.count
                example = $_.example
            }
        })
    unclassified = @($collapsedUnclassified | ForEach-Object {
            [ordered]@{
                kind = $_.kind
                object = $_.object
                symbol = $_.symbol
                count = $_.count
                example = $_.example
            }
        })
    exempted = @($collapsedExempted | ForEach-Object {
            [ordered]@{
                kind = $_.kind
                object = $_.object
                symbol = $_.symbol
                required = $_.required
                count = $_.count
                example = $_.example
            }
        })
}

$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputJson -Encoding ASCII

Write-Host ('ISA audit: {0}' -f $report.result)
Write-Host ('  build root     {0}' -f $BuildRoot)
Write-Host ('  targets        {0} objects + {1} executable' -f $report.objectCount, $report.executableCount)
Write-Host ('  instructions   {0}' -f $instructionCount)
Write-Host ('  continuation   {0} (objdump tails of 7+ byte instructions)' -f $continuationLineCount)
Write-Host ('  i386 {0}  i486 {1}  i586 {2}  p6 {3}  unknown {4}' -f $count386, $count486, $count586, $countP6, $countUnknown)
Write-Host ('  above {0}      {1}' -f $MaxIsa, $violations.Count)
Write-Host ('  exempted       {0}' -f $exempted.Count)
Write-Host ('  report         {0}' -f $OutputJson)

if ($collapsedUnclassified.Count -gt 0) {
    Write-Host ''
    Write-Host 'Unclassified -- must reach zero; a gap in the table is not a pass:'
    foreach ($row in $collapsedUnclassified) {
        Write-Host ('  {0,-22} {1,-38} x{2}  {3}' -f $row.object, $row.symbol, $row.count, $row.example)
    }
}

if ($collapsedViolations.Count -gt 0) {
    Write-Host ''
    Write-Host ('Above {0}, by encoding:' -f $MaxIsa)
    foreach ($row in $encodingTotals.GetEnumerator()) {
        Write-Host ('  {0,-18} {1}' -f $row.Key, $row.Value)
    }
    Write-Host ''
    Write-Host ('Above {0}, by site:' -f $MaxIsa)
    foreach ($row in $collapsedViolations) {
        Write-Host ('  {0,-22} {1,-38} {2,-6} x{3}  {4}' -f $row.object, $row.symbol, $row.required, $row.count, $row.example)
    }
}

if ($collapsedExempted.Count -gt 0) {
    Write-Host ''
    Write-Host 'Exempted (counted above, not counted against the gate):'
    foreach ($row in $collapsedExempted) {
        Write-Host ('  {0,-22} {1,-38} {2,-6} x{3}  {4}' -f $row.object, $row.symbol, $row.required, $row.count, $row.example)
    }
}

if ($FailOnViolation -and (($violations.Count -gt 0) -or ($unclassified.Count -gt 0))) {
    throw ("ISA audit failed for '{0}': {1} instruction(s) above {2}, {3} unclassified. See '{4}'." -f `
            $BuildRoot, $violations.Count, $MaxIsa, $unclassified.Count, $OutputJson)
}

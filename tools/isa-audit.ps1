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
    Audit only the objects, not the linked executable.  Use this for a gate.  A
    release build links with -s, so the executable has no symbol table and
    objdump labels every region with its section name (`.text`); a symbol-keyed
    exemption cannot be expressed against it.  The objects are the authoritative
    instruction set for this tree -- the executable is their concatenation plus
    the crt stubs -- so the gate runs on the objects and a second, reporting-only
    pass covers the executable.

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
    [ValidateSet('i386', 'i486', 'i586', 'p6')]
    [string]$MaxIsa = 'i486',
    [string]$OutputJson,
    [switch]$FailOnViolation,
    [string[]]$Exempt = @(),
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

# Two-byte (0F xx) opcode map.  Only the entries that differ from the i386
# baseline are listed; -SetConstructors are keyed on "0f" + second byte.
$twoByteIsa = @{
    '0f00' = 'i486'   # LLDT
    # 0F 01 has no fixed ISA: /1 LLDT and /2 LTR are i486, the rest of the
    # group (SGDT, SIDT, LGDT, LIDT, SMSW, LMSW) is i386.  Handled separately.
    '0f06' = 'i486'   # CLTS
    '0f09' = 'i486'   # WBINVD
    '0f0b' = 'i586'   # UD2 -- GCC emits this only in unreachable cold blocks
    '0f0d' = 'p6'     # PREFETCH
    '0f0e' = 'p6'     # FEMMS (3DNow! / K5)
    '0f0f' = 'unknown' # 3DNow! prefix
    '0f24' = 'unknown' # TEST r/m,r64 (long mode)
    '0f30' = 'i586'   # WRMSR
    '0f31' = 'i586'   # RDTSC
    '0f32' = 'i586'   # RDMSR
    '0f33' = 'i586'   # RDPMC
    '0f34' = 'i586'   # SYSENTER
    '0f35' = 'i586'   # SYSEXIT
    '0fa2' = 'i586'   # CPUID
    '0fa3' = 'i486'   # BT r/m,r
    '0fa4' = 'i486'   # SHLD r/m,r,imm8
    '0fa5' = 'i486'   # SHLD r/m,r,CL
    '0fa8' = 'i486'   # BT r/m,r (alias decode)
    '0fa6' = 'i386'   # CMPSB
    '0fa7' = 'i386'   # CMPSD
    '0fae' = 'p6'     # LFENCE/MFENCE/SFENCE/CLFLUSH/LDMXCSR/STMXCSR
    '0fab' = 'i486'   # BTS r/m,r
    '0fac' = 'i486'   # SHRD r/m,r,imm8
    '0fad' = 'i486'   # SHRD r/m,r,CL
    '0faf' = 'i586'   # IMUL r32,r/m32 -- Pentium
    '0fb0' = 'i486'   # CMPXCHG
    '0fb1' = 'i486'   # XCHG
    '0fb8' = 'p6'     # POPCNT
    '0fb9' = 'unknown' # UD1
    '0fb3' = 'i486'   # BTR r/m,r
    '0fbb' = 'i486'   # BTC r/m,r
    '0fc0' = 'i486'   # XADD
    '0fc1' = 'i486'   # XADD
    '0fc6' = 'i486'   # CMPXCHG8B
    '0fc7' = 'i486'   # CMPXCHG8B / RDRAND-ish
}
# MMX and SSE: 0F 10..0F 17, 0F 28..0F 2F, 0F 50..0F 77, 0F 78, 0F 79,
# 0F 6F, 0F 7E, 0F 7F, 0F D4..0F FF.
foreach ($i in (@(0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x1E, 0x1F) +
    (0x28..0x2F) + (0x50..0x77) + @(0x6F, 0x78, 0x79, 0x7E, 0x7F) + (0xD4..0xFF))) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'p6'
}
# CMOVcc: 0F 40..4F
for ($i = 0x40; $i -le 0x4F; $i++) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'i486'
}
# SETcc: 0F 90..9F
for ($i = 0x90; $i -le 0x9F; $i++) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'i486'
}
# BSWAP: 0F C8..CF
for ($i = 0xC8; $i -le 0xCF; $i++) {
    $twoByteIsa[('0f{0:x2}' -f $i)] = 'i486'
}

$objectDirectories = @(Get-ChildItem -LiteralPath $BuildRoot -Directory -Filter 'obj*' -ErrorAction SilentlyContinue)
$targets = New-Object System.Collections.Generic.List[object]
foreach ($dir in $objectDirectories) {
    foreach ($obj in (Get-ChildItem -LiteralPath $dir.FullName -Filter '*.obj' -File | Sort-Object Name)) {
        $targets.Add([pscustomobject]@{ kind = 'object'; name = $obj.Name; path = $obj.FullName })
    }
}
$exePath = Join-Path $BuildRoot $ExeName
if ((-not $SkipExecutable) -and (Test-Path -LiteralPath $exePath -PathType Leaf)) {
    $targets.Add([pscustomobject]@{ kind = 'executable'; name = $ExeName; path = $exePath })
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

$byteColumnPattern = [regex]::new('^\s*[0-9a-fA-F]+:\t((?:[0-9a-fA-F]{2} )+)[ ]*\t')
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

foreach ($target in $targets) {
    $symbol = '<none>'
    $lines = & $objdump -d $target.path 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "objdump failed on '$($target.path)' with exit code $LASTEXITCODE."
    }
    foreach ($line in $lines) {
        $symbolMatch = $symbolPattern.Match($line)
        if ($symbolMatch.Success) {
            $symbol = $symbolMatch.Groups[1].Value
            continue
        }
        # The hex byte column is the run of byte pairs between the first tab and
        # the second tab.  Anchoring here is what keeps the audit from matching
        # byte pairs that straddle two instructions.
        $byteMatch = $byteColumnPattern.Match($line)
        if (-not $byteMatch.Success) {
            # A disassembly line whose byte column did not parse is either an
            # objdump continuation line (the tail of a 7+ byte instruction, with
            # no mnemonic) or a parser gap.  Both are counted; the second kind is
            # the one that would silently hide instructions.
            if ($disassemblyLinePattern.Match($line).Success) {
                $continuationLineCount++
            }
            continue
        }

        $bytes = $byteMatch.Groups[1].Value.Trim() -split ' '
        $b0 = $bytes[0]
        $b1 = $null
        if ($bytes.Count -ge 2) { $b1 = $bytes[1] }

        # Strip prefixes that do not change the instruction's ISA level.
        $skip = 0
        while (($skip -lt 3) -and ($b0 -in $ignorablePrefixes)) {
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
                if ($twoByteIsa.ContainsKey($key)) {
                    $isa = $twoByteIsa[$key]
                }
                elseif ($b1 -eq '01') {
                    # 0F 01 /1 LLDT and /2 LTR are i486; the rest (SGDT, SIDT,
                    # LGDT, LIDT, SMSW, LMSW, and the INVLPG variants) are 386.
                    $reg = [Convert]::ToInt32($b1, 16)
                    $isa = 'i386'
                }
                elseif ($b1 -eq 'ba') {
                    $isa = 'i386'   # BT/BTS/BTR/BTC with an immediate: 386
                }
                else {
                    # 0F 80..8F jcc rel32, 0F B6/B7/BE/BF movzx/movsx, 0F BC/BD
                    # bsf/bsr, 0F A0/A1/A8/A9 push/pop fs/gs, 0F 20-23 mov CRn/DRn
                    # are all i386.  Everything else in the 0F map that is not
                    # listed above is newer than this build's toolchain can emit.
                    $second = [Convert]::ToInt32($b1, 16)
                    if (($second -ge 0x80 -and $second -le 0x8F) -or
                        ($second -in @(0xB6, 0xB7, 0xBE, 0xBF, 0xBC, 0xBD, 0xA0, 0xA1, 0xA8, 0xA9)) -or
                        ($second -ge 0x20 -and $second -le 0x23) -or
                        ($second -in @(0x02, 0x03, 0x04, 0x05))) {
                        $isa = 'i386'
                    }
                    else {
                        $isa = 'unknown'
                    }
                }
            }
            # 0F 01 needs the ModRM reg field, which is bytes[2] for the forms
            # that have one.
            if ($b1 -eq '01' -and $bytes.Count -ge 3) {
                $regField = Get-ModRmRegField -ModRm $bytes[2]
                if ($null -ne $regField -and $regField -in @(1, 2)) { $isa = 'i486' }
            }
        }
        elseif ($b0 -in @('f6', 'f7')) {
            # F6/F7 group 3 (TEST) and group 5 (INC/DEC/NEG/NOT/MUL/IMUL/DIV/IDIV).
            # reg == 1 is TEST r/m,imm, which only exists from i486; the other
            # reg values -- including reg == 5, the one-operand IMUL -- are 286+.
            $isa = 'i386'
            $regField = Get-ModRmRegField -ModRm $b1
            if ($null -ne $regField -and $regField -eq 1) { $isa = 'i486' }
        }
        elseif ($b0 -match '^[d][89a-f]$') {
            # The whole x87 map is i386, with three P6 exceptions that are worth
            # naming precisely because their encodings alias 386 ones:
            #
            #   DB /5 and DB /6 in *register* form are FUCOMI and FCOMI.  In
            #   memory form DB /5 is FLD m80 and DB /6 is unused, so only the
            #   register form (mod == 11) is a P6 instruction.  Getting this
            #   wrong is not hypothetical: an earlier version of this table
            #   treated DF /5 as FCOMI and reported 17 phantom FCOMIs, which are
            #   really FILD m64int.
            #
            #   DB, DD and DF /1 in memory form are FISTTP, added with SSE3.
            $isa = 'i386'
            $regField = Get-ModRmRegField -ModRm $b1
            $modField = Get-ModRmModField -ModRm $b1
            if ($null -ne $regField) {
                if (($b0 -eq 'db') -and ($modField -eq 3) -and ($regField -in @(5, 6))) {
                    $isa = 'p6'
                }
                elseif (($b0 -in @('db', 'dd', 'df')) -and ($regField -eq 1) -and ($modField -ne 3)) {
                    $isa = 'p6'
                }
            }
        }
        elseif ($b0 -in @('62', '63')) {
            $isa = 'i486'   # BOUND (486), ARPL (486)
        }
        elseif ($b0 -eq '9d') {
            $isa = 'i386'
            # POPF in 32-bit mode; a non-zero reg field is the i486 RDMSR escape.
            $regField = Get-ModRmRegField -ModRm $b1
            if ($null -ne $regField -and $regField -ne 0) { $isa = 'i486' }
        }
        else {
            $isa = 'i386'
        }

        $instructionCount++
        switch ($isa) {
            'i386' { $count386++ }
            'i486' { $count486++ }
            'i586' { $count586++ }
            'p6' { $countP6++ }
            default { $countUnknown++ }
        }

        if (($isaRank[$isa] -gt $maxRank) -or ($isa -eq 'unknown')) {
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
            if ($exemptKeys.Contains("$($target.name):$symbol")) {
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
    }
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
    objectDirectories = @($objectDirectories | ForEach-Object { $_.Name })
    objectCount = @($targets | Where-Object kind -eq 'object').Count
    executableCount = @($targets | Where-Object kind -eq 'executable').Count
    instructionCount = $instructionCount
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

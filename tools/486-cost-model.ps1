<#
.SYNOPSIS
    Static 486DX cost model for the DOS WinQuake renderer.

.DESCRIPTION
    Prices three axes that the pinned DOSBox-X harness cannot see:

      1. x87 latency        - DOSBox-X measures ~1.04 cy/op; a 486DX spends ~12.
      2. 4 KB page aliasing - not modelled at all, and the precondition is
                              physically present in the video buffer layout.
      3. L1 footprint       - 8 KB unified cache (there is NO instruction cache
                              on a 486); .text is 90x that.

    This tool is a DISQUALIFIER and a RANKING AID. It can never promote a
    change. The 0.05% DOSBox-X timedemo delta remains the sole promotion
    criterion; see ASM486-HANDOFF.md:452-509. A cycle figure printed here is a
    published-latency estimate, not a measurement taken by this project.

.NOTES
    The linked executable is stripped by the build (build-dos.ps1:489 passes
    -s), so per-function attribution is impossible from the image. Linked-image
    facts are therefore exact but coarse (.text total, x87 total); per-path x87
    accounting is done against the assembler sources, where labels and line
    numbers exist.
#>
[CmdletBinding()]
param(
    # Linked executable to disassemble. Defaults to the newest qbench.exe under out\.
    [string]$Executable,

    # PROFILE486 data. Accepts either a standalone profile JSON (schema 1) or a
    # timedemo-result.json that embeds one.
    [string]$ProfileJson,

    [string]$SourceRoot,
    [string]$ToolRoot,
    [string]$Objdump,

    # Frame dimensions used for the buffer-layout aliasing computation.
    [int]$ScreenWidth = 320,
    [int]$ScreenHeight = 200,

    # Directory of retained .obj files for the same build as -Executable. The
    # link step strips (-s), so the image carries no symbols and per-function
    # attribution is impossible from it. The objects are retained by the build
    # (out\dos<profile>\obj-bench), so this is where function-level x87
    # accounting comes from. Defaults to the sibling obj-bench directory.
    [string]$ObjectDirectory,

    # 486 clock used only as a time base for the percentage projection. The
    # projection scales linearly with it; 33.445 MHz matches the pinned
    # DOSBox-X profile (cycles = fixed 33445).
    [double]$CpuHz = 33445000,

    # Surface-cache size in bytes, matching vid_surfcachesize at vid_vga.c:279.
    [int]$SurfaceCacheSize = 1800 * 1024,

    [ValidateRange(1, 200)]
    [int]$Top = 15,

    [string]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = Join-Path $repoRoot 'WinQuake'
}

# Relative inputs resolve against the repository root, not the caller's
# working directory, so the tool behaves the same from anywhere.
function Resolve-InputPath {
    param([string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

$SourceRoot = Resolve-InputPath $SourceRoot

# ---------------------------------------------------------------------------
# Toolchain
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Objdump)) {
    $manifestPath = Join-Path $PSScriptRoot 'dos-toolchain.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Toolchain manifest was not found: '$manifestPath'."
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
        $ToolRoot = Join-Path $env:LOCALAPPDATA '486quake\tools'
    }
    $Objdump = Join-Path (Join-Path $ToolRoot $manifest.djgpp.installDirectory) `
        ($manifest.djgpp.objdump -replace '/', [IO.Path]::DirectorySeparatorChar)
}
$Objdump = [IO.Path]::GetFullPath($Objdump)
if (-not (Test-Path -LiteralPath $Objdump -PathType Leaf)) {
    throw "objdump was not found: '$Objdump'."
}

if ([string]::IsNullOrWhiteSpace($Executable)) {
    $candidate = Get-ChildItem (Join-Path $repoRoot 'out') -Recurse -Filter 'qbench.exe' `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $candidate) {
        throw "No qbench.exe was found under '$(Join-Path $repoRoot 'out')'. Pass -Executable."
    }
    $Executable = $candidate.FullName
}
$Executable = Resolve-InputPath $Executable
if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
    throw "Executable was not found: '$Executable'."
}

# ---------------------------------------------------------------------------
# 486DX published latencies.
#
# These are Intel 486 published figures (486 Family User's Manual, floating
# point instruction timings), NOT measurements taken by this project. They are
# order-of-magnitude correct and deliberately not tuned. The DOSBox-X
# comparison stands at ~1.04 cy/op for every one of them
# (ASM486-HANDOFF.md:458-461).
# ---------------------------------------------------------------------------
$latency = @{
    'fxch'     = 1;    'fwait'    = 1
    'fld'      = 3;    'flds'     = 3;    'fldl'     = 6
    'fldt'     = 6;    'fild'     = 6;    'fildl'    = 6
    'filds'    = 5;    'fildll'   = 10
    'fist'     = 39;   'fistl'    = 39;   'fistpl'   = 39
    'fists'    = 30;   'fistpll'  = 80
    'fst'      = 3;    'fstl'     = 3;    'fstt'     = 3
    'fsts'     = 3;    'fstps'    = 3;    'fstpl'    = 3
    'fstpt'    = 3;    'fstp'     = 3;    'fstsw'    = 3;    'fstcw'    = 3
    'fldz'     = 3;    'fld1'     = 3;    'fldpi'    = 3
    'fldln2'   = 3;    'fldlg2'   = 3;    'fldl2e'   = 3
    'fldl2t'   = 3;    'fldlge'   = 3
    'fadd'     = 3;    'fadds'    = 3;    'faddl'    = 3
    'faddp'    = 3;    'fiadd'    = 6;    'fiaddl'   = 6
    'fiadds'   = 5
    'fsub'     = 3;    'fsubs'    = 3;    'fsubl'    = 3
    'fsubp'    = 3;    'fsubr'    = 3;    'fsubrs'   = 3
    'fsubrl'   = 3;    'fsubrp'   = 3
    'fisub'    = 6;    'fisubl'   = 6;    'fisubrs'  = 6
    'fisubrl'  = 6;    'fisubs'   = 5
    'fmul'     = 3;    'fmuls'    = 3;    'fmull'    = 3
    'fmulp'    = 3;    'fimul'    = 6;    'fimull'   = 6
    'fimuls'   = 5
    'fdiv'     = 14;   'fdivs'    = 14;   'fdivl'    = 14
    'fdivp'    = 14;   'fdivr'    = 14;   'fdivrs'   = 14
    'fdivrl'   = 14;   'fdivrp'   = 14
    'fidiv'    = 14;   'fidivl'   = 14;   'fidivrl'  = 14
    'fidivs'   = 14
    'fcom'     = 3;    'fcoms'    = 3;    'fcoml'    = 3
    'fcomp'    = 3;    'fcomps'   = 3;    'fcompl'   = 3
    'fcompp'   = 3;    'fucom'    = 3;    'fucomi'   = 3
    'fucomip'  = 3;    'fucomp'   = 3;    'fucompp'  = 3
    'ficom'    = 6;    'ficoml'   = 6;    'ficompl'  = 6
    'ficomp'   = 6
    'ftst'     = 3;    'fxam'     = 3
    'fnstsw'   = 3;    'fnstcw'   = 3;    'fldcw'    = 3
    'fnstenv'  = 10;   'fldenv'   = 10
    'fchs'     = 3;    'fabs'     = 3
    'frndint'  = 20;   'fscale'   = 20;   'fxtract'  = 20
    'fprem'    = 20
    'fsqrt'    = 15
    'fsin'     = 50;   'fcos'     = 50;   'fptan'    = 50
    'fpatan'   = 100
    'fninit'   = 8;    'fclex'    = 3
}

# Tokens objdump can emit that are NOT x87 instructions:
#  - segment and operand-size prefixes, which it prints ahead of the mnemonic
#  - 'ff', the grp5 opcode prefix, which it emits bare on some 486 encodings
#  - AMD 3DNow! opcodes, which do not exist on a 486 at all
$notX87 = @('fs', 'gs', 'cs', 'ds', 'es', 'ss', 'ff',
    'data16', 'addr16', 'rep', 'repz', 'repnz', 'lock', 'bnd',
    'femms', 'fcmovnu', 'fcmovn', 'fcmovnb', 'fcmovbe', 'fcmovu',
    'fcmovnbe', 'fcmovne', 'pfadd', 'pfmul', 'pfsub', 'pfrcp', 'pfcmpeq')

function Get-X87Latency {
    param([string]$Mnemonic)
    if ($notX87 -contains $Mnemonic) { return 0.0 }
    if ($latency.ContainsKey($Mnemonic)) {
        return [double]$latency[$Mnemonic]
    }
    if ($Mnemonic -match '^f') {
        return 3.0   # unlisted x87 op: assume the common case rather than zero
    }
    return 0.0
}

# ---------------------------------------------------------------------------
# Profile loading.
#
# Two shapes are accepted. A timedemo-result.json carries the profile object
# per run, under results[].profile -- the top-level "profile" key there means
# the DOSBox conf path, not the profile data. A standalone profile JSON (the
# schema 1 document profile-report.ps1 consumes) carries nodes at top level.
# ---------------------------------------------------------------------------
function Read-Profile {
    param([string]$Path)

    $text = Get-Content -LiteralPath $Path -Raw
    $doc = [System.Text.Json.JsonDocument]::Parse($text)
    $objectKind = [System.Text.Json.JsonValueKind]::Object
    $arrayKind = [System.Text.Json.JsonValueKind]::Array
    try {
        $rootProperties = @($doc.RootElement.EnumerateObject())
        foreach ($property in $rootProperties) {
            if ($property.Name -eq 'nodes') {
                return ($text | ConvertFrom-Json)
            }
            if ($property.Name -ne 'results' -or $property.Value.ValueKind -ne $arrayKind) {
                continue
            }
            foreach ($run in $property.Value.EnumerateArray()) {
                foreach ($runProperty in $run.EnumerateObject()) {
                    if ($runProperty.Name -eq 'profile' -and
                        $runProperty.Value.ValueKind -eq $objectKind) {
                        return ($runProperty.Value.GetRawText() | ConvertFrom-Json)
                    }
                }
            }
        }
    }
    finally {
        $doc.Dispose()
    }
    return $null
}

function Get-NodeValue {
    param($Node, [string]$Name)
    if ($null -eq $Node) { return $null }
    if ($Node.PSObject.Properties.Name -contains $Name) { return $Node.$Name }
    return $null
}

$profile = $null
$profileNote = 'no profile supplied; per-frame projections are omitted'
if (-not [string]::IsNullOrWhiteSpace($ProfileJson)) {
    $ProfileJson = Resolve-InputPath $ProfileJson
    if (-not (Test-Path -LiteralPath $ProfileJson -PathType Leaf)) {
        throw "Profile JSON was not found: '$ProfileJson'."
    }
    $profile = Read-Profile -Path $ProfileJson
    if ($null -eq $profile) {
        $profileNote = "no embedded profile object in '$ProfileJson'"
    }
}

function Get-ProfileNode {
    param($Document, [string]$Id)
    if ($null -eq $Document) { return $null }
    foreach ($node in @($Document.nodes)) {
        if ([string]$node.id -eq $Id) { return $node }
    }
    return $null
}

# ---------------------------------------------------------------------------
# Section 1 - linked image facts
# ---------------------------------------------------------------------------
$headerText = (& $Objdump -h $Executable | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw "objdump -h failed for '$Executable'."
}

$textSize = 0
foreach ($line in ($headerText -split "`r?`n")) {
    if ($line -match '^\s*\d+\s+\.text\s+([0-9a-fA-F]+)\s') {
        $textSize = [Convert]::ToInt64($Matches[1], 16)
    }
}
if ($textSize -le 0) {
    throw "Could not read the .text size from the section headers."
}

$disasm = (& $Objdump -d $Executable | Out-String)
if ($LASTEXITCODE -ne 0) {
    throw "objdump -d failed for '$Executable'."
}
$disasmLines = $disasm -split "`r?`n"

$x87Total = 0
$binaryX87 = @{}
$mnemonicCounts = @{}
$unknownX87 = @{}
foreach ($line in $disasmLines) {
    # "    18a8:\t66 90                \txchg   %ax,%ax"
    if ($line -match '^\s*([0-9a-fA-F]+):\s+(?:[0-9a-fA-F]{2}\s+)+(\S+)(?:\s+(.*))?$') {
        $mnemonic = $Matches[2]
        # No non-FP x86 instruction begins with 'f', but objdump prints segment
        # prefixes as separate tokens and disassembles some data regions
        # linearly, so the exclusion list is what keeps the count honest.
        if ($mnemonic -match '^f' -and $notX87 -notcontains $mnemonic) {
            $x87Total++
            if (-not $mnemonicCounts.ContainsKey($mnemonic)) {
                $mnemonicCounts[$mnemonic] = 0
            }
            $mnemonicCounts[$mnemonic]++
            if (-not $latency.ContainsKey($mnemonic)) {
                if (-not $unknownX87.ContainsKey($mnemonic)) {
                    $unknownX87[$mnemonic] = 0
                }
                $unknownX87[$mnemonic]++
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Section 1b - per-object x87 accounting from the retained .obj files.
#
# The linked image is stripped (build-dos.ps1:489 passes -s), so objdump -d on
# it reports no symbols and every function is anonymous. The objects are
# retained next to the executable, and an unstripped .obj disassembles with
# its symbol table intact, which is what makes per-function attribution
# possible. Without this the model can only report coarse image totals.
# ---------------------------------------------------------------------------
$objectFacts = $null
if ([string]::IsNullOrWhiteSpace($ObjectDirectory)) {
    $ObjectDirectory = Join-Path (Split-Path -Parent $Executable) 'obj-bench'
}
$ObjectDirectory = Resolve-InputPath $ObjectDirectory
if (Test-Path -LiteralPath $ObjectDirectory -PathType Container) {
    $objectList = @(Get-ChildItem -LiteralPath $ObjectDirectory -Filter '*.obj' -File |
            Sort-Object Name)
    $perObject = @()
    $objectX87Total = 0
    foreach ($obj in $objectList) {
        $objDisasm = (& $Objdump -d $obj.FullName 2>$null | Out-String)
        if ($LASTEXITCODE -ne 0) { continue }
        $currentSymbol = $null
        $symbolX87 = 0
        $symbolCycles = 0.0
        $symbolMnemonics = @{}
        $symbolBytes = 0

        $objLines = $objDisasm -split "`r?`n"
        for ($lineIndex = 0; $lineIndex -le $objLines.Count; $lineIndex++) {
            $line = if ($lineIndex -lt $objLines.Count) { $objLines[$lineIndex] } else { '' }

            # A function label: "00000220 <_D_DrawSpans16>:". The section header
            # "00000000 <.text>:" has the same shape, so a leading-dot name is
            # a section, not a function, and closes any open symbol.
            $isLabel = $false
            $nextSymbol = $null
            if ($line -match '^[0-9a-fA-F]+ <(?<name>[^>]+)>:$') {
                $name = $Matches['name']
                $nextSymbol = if ($name.StartsWith('.')) { $null } else { $name }
                $isLabel = $true
            }

            if ($isLabel) {
                if ($null -ne $currentSymbol) {
                    $perObject += [ordered]@{
                        object = $obj.Name
                        symbol = $currentSymbol
                        x87 = $symbolX87
                        x87Cycles = [math]::Round($symbolCycles, 2)
                        bytes = $symbolBytes
                        mnemonics = $symbolMnemonics
                    }
                }
                $currentSymbol = $nextSymbol
                $symbolX87 = 0
                $symbolCycles = 0.0
                $symbolBytes = 0
                $symbolMnemonics = @{}
                continue
            }

            # An instruction: " 12b:\tdc f9                \tfdivr  %st,%st(1)"
            if ($line -match '^\s*[0-9a-fA-F]+:\s+(?<bytes>(?:[0-9a-fA-F]{2}\s+)+)(?<mnemonic>\S+)(?:\s+(.*))?$') {
                $mnemonic = $Matches['mnemonic']
                $byteCount = ([regex]::Matches($Matches['bytes'], '\b[0-9a-fA-F]{2}\b')).Count
                $symbolBytes += $byteCount
                if ($mnemonic -match '^f' -and $notX87 -notcontains $mnemonic) {
                    $symbolX87++
                    $objectX87Total++
                    $symbolCycles += Get-X87Latency $mnemonic
                    if (-not $symbolMnemonics.ContainsKey($mnemonic)) {
                        $symbolMnemonics[$mnemonic] = 0
                    }
                    $symbolMnemonics[$mnemonic]++
                }
            }
        }
    }
    if ($objectList.Count -gt 0) {
        $objectFacts = [ordered]@{
            objectDirectory = $ObjectDirectory
            objectCount = $objectList.Count
            x87Total = $objectX87Total
            symbols = @($perObject | Where-Object { $_.x87 -gt 0 } |
                    Sort-Object -Property x87Cycles -Descending)
        }
    }
}

# ---------------------------------------------------------------------------
# Section 2 - per-path x87 accounting from the assembler sources
# ---------------------------------------------------------------------------
function Read-AsmPaths {
    param([string]$Root)

    $paths = @()
    foreach ($file in (Get-ChildItem $Root -Filter '*.s' -ErrorAction SilentlyContinue |
            Sort-Object Name)) {
        $label = $null
        $startLine = 0
        $ops = @()
        $lineNumber = 0
        foreach ($raw in (Get-Content -LiteralPath $file.FullName)) {
            $lineNumber++
            $code = $raw
            $comment = $code.IndexOf('//')
            if ($comment -ge 0) { $code = $code.Substring(0, $comment) }
            if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:') {
                if ($null -ne $label -and $ops.Count -gt 0) {
                    $paths += [pscustomobject]@{
                        File = $file.Name; Label = $label
                        StartLine = $startLine; Ops = $ops
                    }
                }
                $label = $Matches[1]; $startLine = $lineNumber; $ops = @()
                continue
            }
            if ([string]::IsNullOrWhiteSpace($label)) { continue }
            if ($code -match '^\s+([a-z][a-z0-9]*)\b') {
                $ops += [pscustomobject]@{
                    Mnemonic = $Matches[1]; Line = $lineNumber
                }
            }
        }
        if ($null -ne $label -and $ops.Count -gt 0) {
            $paths += [pscustomobject]@{
                File = $file.Name; Label = $label
                StartLine = $startLine; Ops = $ops
            }
        }
    }
    return $paths
}

$asmPaths = Read-AsmPaths -Root $SourceRoot

$pathRows = @()
foreach ($path in $asmPaths) {
    $ops = @($path.Ops)
    $x87 = @($ops | Where-Object {
        $_.Mnemonic -match '^f' -and (Get-X87Latency $_.Mnemonic) -gt 0
    })
    if ($x87.Count -eq 0) { continue }
    $cycles = 0.0
    foreach ($op in $x87) { $cycles += Get-X87Latency $op.Mnemonic }
    $endLine = $x87[-1].Line
    $pathRows += [pscustomobject]@{
        File = $path.File; Label = $path.Label
        StartLine = $path.StartLine; EndLine = $endLine
        TotalOps = $ops.Count; X87Ops = $x87.Count; X87Cycles = $cycles
    }
}
$pathRows = @($pathRows | Sort-Object { $_.X87Cycles } -Descending)

# The Z-span prologue, documented at ASM486-HANDOFF.md:541-546 and
# d_draw.s:LFSpanLoop. The ledger calls it "nine serialized x87 operations";
# the source region actually contains twelve x87 instructions. Both numbers
# are reported so the discrepancy stays visible rather than being baked in.
$prologue = @($asmPaths | Where-Object { $_.Label -eq 'LFSpanLoop' })
$prologueX87 = 0
$prologueCycles = 0.0
$prologueOps = @()
if ($prologue.Count -eq 1) {
    $prologueOps = @($prologue[0].Ops | Where-Object {
        $_.Mnemonic -match '^f' -and (Get-X87Latency $_.Mnemonic) -gt 0
    })
    $prologueX87 = $prologueOps.Count
    foreach ($op in $prologueOps) { $prologueCycles += Get-X87Latency $op.Mnemonic }
}

# ---------------------------------------------------------------------------
# Section 3 - 4 KB page aliasing precondition (vid_vga.c:299-304)
# ---------------------------------------------------------------------------
$zbufferSize = [int64]$ScreenWidth * $ScreenHeight * 2          # sizeof(short)
$surfcacheOffset = $zbufferSize
$bufferOffset = $surfcacheOffset + $SurfaceCacheSize

$surfcachePage = $surfcacheOffset % 4096
$bufferPage = $bufferOffset % 4096
$aliasCollision = ($surfcacheOffset % 4096) -eq ($bufferOffset % 4096)

# ---------------------------------------------------------------------------
# Section 4 - L1 footprint
# ---------------------------------------------------------------------------
$l1Bytes = 8 * 1024
$l1Windows = [Math]::Ceiling($textSize / $l1Bytes)
$l1Ratio = $textSize / $l1Bytes

# ---------------------------------------------------------------------------
# Section 5 - projection over the profile
# ---------------------------------------------------------------------------
$frameSeconds = 0.0
$spanCount = $null
$pixelCount = $null
$spanMetricSource = $null
$zSpanCalls = $null
if ($null -ne $profile) {
    $frameNode = Get-ProfileNode -Document $profile -Id 'frame'
    if ($null -ne $frameNode) {
        $value = Get-NodeValue -Node $frameNode -Name 'inclusive_seconds'
        if ($null -ne $value) { $frameSeconds = [double]$value }
    }
    $zSpanNode = Get-ProfileNode -Document $profile -Id 'z-spans'
    if ($null -ne $zSpanNode) {
        $calls = Get-NodeValue -Node $zSpanNode -Name 'calls'
        if ($null -ne $calls) { $zSpanCalls = [int64]$calls }
    }
    # The z-spans node carries no work_items, so the span count comes from the
    # run metrics. surface_span_count is the figure ASM486-HANDOFF.md cites as
    # 1,494,650 spans / 45,953,856 pixels.
    $metrics = $profile.metrics
    if ($null -ne $metrics) {
        $spans = Get-NodeValue -Node $metrics -Name 'surface_span_count'
        if ($null -ne $spans -and [int64]$spans -gt 0) {
            $spanCount = [int64]$spans
            $spanMetricSource = 'metrics.surface_span_count'
        }
        $pixels = Get-NodeValue -Node $metrics -Name 'surface_span_pixels'
        if ($null -ne $pixels -and [int64]$pixels -gt 0) {
            $pixelCount = [int64]$pixels
        }
    }
}

$prologueCycleTotal = 0.0
$prologueSeconds = 0.0
$prologuePercent = 0.0
$projectionAvailable = ($null -ne $spanCount -and $spanCount -gt 0 -and
    $frameSeconds -gt 0 -and $CpuHz -gt 0)
if ($projectionAvailable) {
    $prologueCycleTotal = [double]$prologueCycles * [double]$spanCount
    $prologueSeconds = $prologueCycleTotal / $CpuHz
    $prologuePercent = $prologueSeconds * 100.0 / $frameSeconds
}
$pixelsPerSpan = $null
if ($null -ne $spanCount -and $spanCount -gt 0 -and $null -ne $pixelCount) {
    $pixelsPerSpan = [Math]::Round($pixelCount / $spanCount, 2)
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Host '486DX static cost model - a disqualifier, never a promotion criterion.'
Write-Host ("Promotion remains the 0.05% DOSBox-X timedemo delta; see ASM486-HANDOFF.md:452-509.")
Write-Host ("Executable: {0}" -f $Executable)
Write-Host ("Profile:    {0}" -f $(if ($null -ne $profile) { $ProfileJson } else { $profileNote }))
Write-Host ''

Write-Host '1. Linked image facts (exact - the image is stripped, so these are image totals)'
Write-Host ("   .text                {0,10:N0} bytes" -f $textSize)
Write-Host ("   x87 instructions      {0,10:N0} in .text" -f $x87Total)
Write-Host ("   8 KB L1 windows       {0,10:N0}  (.text is {1:N1}x the 486 unified cache)" -f $l1Windows, $l1Ratio)
Write-Host '   Top x87 mnemonics by frequency:'
$ranked = 0
foreach ($entry in ($mnemonicCounts.GetEnumerator() | Sort-Object Value -Descending |
        Select-Object -First ([Math]::Min(8, $mnemonicCounts.Count)))) {
    $ranked++
    Write-Host ("     {0,2}. {1,-8} {2,7} instructions, 486 cost {3,4} cy each" -f
        $ranked, $entry.Key, $entry.Value, (Get-X87Latency $entry.Key))
}
if ($unknownX87.Count -gt 0) {
    $unknownTotal = ($unknownX87.Values | Measure-Object -Sum).Sum
    Write-Host ("   {0,7} instructions use an x87 opcode with no published latency in the" -f $unknownTotal)
    Write-Host '   table; they are priced at the 3-cycle default. Names:'
    Write-Host ('     ' + (($unknownX87.GetEnumerator() | Sort-Object Value -Descending |
                ForEach-Object { "$($_.Key) ($($_.Value))" }) -join ', '))
}
Write-Host ''

if ($null -ne $objectFacts) {
    Write-Host ("1b. Per-function x87 cost from the retained objects ({0} objects, symbols intact)" -f $objectFacts.objectCount)
    Write-Host ("   {0,-20} {1,-34} {2,6} {3,10}" -f 'OBJECT', 'SYMBOL', 'X87', '486 CYCLES')
    $objShown = 0
    foreach ($row in $objectFacts.symbols) {
        if ($objShown -ge $Top) { break }
        $objShown++
        $label = $row.symbol
        if ($label.Length -gt 34) { $label = $label.Substring(0, 31) + '...' }
        Write-Host ("   {0,-20} {1,-34} {2,6} {3,10:N0}" -f
            $row.object, $label, $row.x87, $row.x87Cycles)
    }
    Write-Host ''
}
else {
    Write-Host '1b. Per-function x87 cost: SKIPPED (no object directory found; the stripped'
    Write-Host '    image carries no symbols, so only image totals are available above).'
    Write-Host ''
}

Write-Host '2. x87 cost per assembly path (source-level; the image has no symbols)'
Write-Host ("   {0,-18} {1,-16} {2,6} {3,6} {4,10}" -f 'FILE', 'LABEL', 'OPS', 'X87', '486 CYCLES')
$shown = 0
foreach ($row in $pathRows) {
    if ($shown -ge $Top) { break }
    $shown++
    Write-Host ("   {0,-18} {1,-16} {2,6} {3,6} {4,10:N0}" -f
        $row.File, $row.Label, $row.TotalOps, $row.X87Ops, $row.X87Cycles)
}
Write-Host ''

Write-Host '3. Z-span x87 prologue (d_draw.s LFSpanLoop) - the documented anchor'
Write-Host ("   x87 instructions in region   {0,6}   (ledger records 'nine')" -f $prologueX87)
Write-Host ("   486DX cost per span         {0,6:N0} cycles" -f $prologueCycles)
Write-Host ("   DOSBox-X cost per span      {0,6:N1} cycles  (measured, 9 ops)" -f 9.4)
if ($null -ne $zSpanCalls) {
    Write-Host ("   z-spans node calls          {0,6:N0}" -f $zSpanCalls)
}
if ($projectionAvailable) {
    Write-Host ("   spans in the profiled run   {0,12:N0}   ({1})" -f $spanCount, $spanMetricSource)
    if ($null -ne $pixelsPerSpan) {
        Write-Host ("   pixels per span            {0,12:N2}   (ledger records 30.7)" -f $pixelsPerSpan)
    }
    Write-Host ("   486DX projection            {0,12:N0} cycles = {1,6:N2}% of the profiled frame" -f
        $prologueCycleTotal, $prologuePercent)
    Write-Host ("   the percentage scales linearly with -CpuHz; at {0:N1} MHz it is {1:N2}%" -f
        ($CpuHz * 2 / 1e6), ($prologuePercent * 0.5))
}
else {
    Write-Host '   no usable span count in this profile, so no per-frame projection is'
    Write-Host '   reported. The per-span figure above is the usable result; a 0.00% here'
    Write-Host '   would be an artefact, not a measurement.'
}
Write-Host '   Per-region instruction listing:'
if ($prologueOps.Count -gt 0) {
    Write-Host ("     line {0,4}  {1}" -f $prologue[0].StartLine, $prologue[0].Label)
    foreach ($op in $prologueOps) {
        Write-Host ("     line {0,4}  {1,-8} {2,4} cy" -f
            $op.Line, $op.Mnemonic, (Get-X87Latency $op.Mnemonic))
    }
}
Write-Host ''

Write-Host '4. 4 KB page aliasing precondition (vid_vga.c:299-304)'
Write-Host ("   zbuffer                  offset {0,12:N0}  size {1,12:N0}" -f 0, $zbufferSize)
Write-Host ("   vid_surfcache            offset {0,12:N0}  page offset {1,6:N0}" -f $surfcacheOffset, $surfcachePage)
Write-Host ("   lvid->buffer             offset {0,12:N0}  page offset {1,6:N0}" -f $bufferOffset, $bufferPage)
if ($aliasCollision) {
    Write-Host ("   COLLISION: surfcache and framebuffer share a 4 KB page offset ({0})." -f $surfcachePage)
    Write-Host '   A load from one and a store to the other in the same loop stalls on a real 486.'
    Write-Host '   DOSBox-X does not model paging, so this axis is DISQUALIFIED here.'
}
else {
    Write-Host '   No page-offset collision at this geometry.'
}
Write-Host ''

Write-Host '5. Disqualification verdicts'
Write-Host '   x87 latency        DISQUALIFIED as a target - DOSBox-X prices every x87 op at'
Write-Host '                      ~1.04 cy against a 486DX figure above. A change whose payoff'
Write-Host '                      is FP-op count cannot be promoted under the timedemo gate.'
Write-Host ("   L1 footprint       DISQUALIFIED - .text spans {0:N0} unified-cache windows and" -f $l1Windows)
Write-Host '                      DOSBox-X does not model cache displacement.'
if ($aliasCollision) {
    Write-Host '   4 KB aliasing      DISQUALIFIED - precondition is present, but the mechanism'
    Write-Host '                      is not modelled, so a null result would be uninformative.'
}
Write-Host ''
Write-Host '   Work whose payoff is instruction count, memory traffic, or arithmetic stays'
Write-Host '   admissible. That is where optimization effort belongs.'

if (-not [string]::IsNullOrWhiteSpace($Json)) {
    $result = [ordered]@{
        executable = $Executable
        objectFacts = $objectFacts
        text_bytes = $textSize
        x87_instructions = $x87Total
        l1_bytes = $l1Bytes
        l1_windows = $l1Windows
        l1_ratio = [Math]::Round($l1Ratio, 2)
        zspan_prologue = [ordered]@{
            x87_instructions = $prologueX87
            cycles_486_per_span = $prologueCycles
            cycles_dosbox_x_per_span = 9.4
            spans = $spanCount
            pixels_per_span = $pixelsPerSpan
            projected_cycles = $prologueCycleTotal
            projected_percent_of_frame = $(if ($projectionAvailable) {
                [Math]::Round($prologuePercent, 2)
            }
            else { $null })
            cpu_hz = $CpuHz
        }
        aliasing = [ordered]@{
            zbuffer_size = $zbufferSize
            surfcache_offset = $surfcacheOffset
            buffer_offset = $bufferOffset
            surfcache_page_offset = $surfcachePage
            buffer_page_offset = $bufferPage
            collision = $aliasCollision
        }
        disqualifies = @('x87-latency', 'l1-footprint',
            $(if ($aliasCollision) { '4kb-aliasing' } else { $null }))
    }
    $Json = Resolve-InputPath $Json
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Json -Encoding utf8
    Write-Host ("JSON report written to {0}" -f $Json)
}

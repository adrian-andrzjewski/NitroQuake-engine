<#
.SYNOPSIS
    Audits the exact i486 object and runtime closure linked into a DOS executable.

.DESCRIPTION
    Uses the GNU linker map to enumerate every input .text contribution, including
    CRT objects and members pulled from static runtime archives. It audits those
    input objects with isa-audit.ps1, then disassembles each mapped range in the
    final executable and checks that its instruction boundaries and ISA-defining
    opcode bytes agree with the audited input object. Relocation fields may
    differ, but opcodes and ModRM bytes may not. Hash-bound linked input copies
    are retained beneath ReportRoot because durable reports reference them.
    An exclusive ReportRoot lock prevents concurrent runs from mixing fixed-name
    report files. ScratchRoot directs transient archive extracts and linked
    section bytes; it defaults to the repository out directory.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BuildRoot,
    [Parameter(Mandatory = $true)]
    [string]$MapPath,
    [string]$ExecutableName = 'quake.exe',
    [string]$ReportRoot,
    [Parameter(Mandatory = $true)]
    [string]$ObjectRoot,
    [Parameter(Mandatory = $true)]
    [string[]]$ObjectNames,
    [ValidateSet('i386', 'i486', 'i586', 'p6')]
    [string]$MaxIsa = 'i486',
    [string[]]$Exempt = @(),
    [string[]]$ExemptRange = @(),
    [string]$ObjectCodeDataProofJson,
    [string]$RuntimeSourceBundle,
    [string]$ToolRoot,
    [string]$ScratchRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

if (-not (Test-Path -LiteralPath $BuildRoot -PathType Container)) { throw "Build root not found: '$BuildRoot'." }
if (-not (Test-Path -LiteralPath $MapPath -PathType Leaf)) { throw "Link map not found: '$MapPath'." }
if (-not (Test-Path -LiteralPath $ObjectRoot -PathType Container)) { throw "Object root not found: '$ObjectRoot'." }
$BuildRoot = (Resolve-Path -LiteralPath $BuildRoot).Path
if ([string]::IsNullOrWhiteSpace($ReportRoot)) { $ReportRoot = $BuildRoot }
$ReportRoot = [IO.Path]::GetFullPath($ReportRoot)
New-Item -ItemType Directory -Path $ReportRoot -Force | Out-Null
$MapPath = (Resolve-Path -LiteralPath $MapPath).Path
$ObjectRoot = (Resolve-Path -LiteralPath $ObjectRoot).Path
$executable = Join-Path $BuildRoot $ExecutableName
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Executable not found: '$executable'." }

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($ToolRoot)) {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localAppData)) { throw 'Could not determine the local application-data directory.' }
    $ToolRoot = Join-Path $localAppData '486quake\tools'
}
$toolManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dos-toolchain.json') -Raw | ConvertFrom-Json
$djgppRoot = Join-Path ([IO.Path]::GetFullPath($ToolRoot)) $toolManifest.djgpp.installDirectory
$objdump = Join-Path $djgppRoot ($toolManifest.djgpp.objdump -replace '/', [IO.Path]::DirectorySeparatorChar)
$archiver = Join-Path (Split-Path -Parent $objdump) ($toolManifest.djgpp.target + '-ar.exe')
$objcopy = Join-Path (Split-Path -Parent $objdump) ($toolManifest.djgpp.target + '-objcopy.exe')
if (-not (Test-Path -LiteralPath $objdump -PathType Leaf)) { throw "Required DJGPP objdump is missing: '$objdump'." }
if (-not (Test-Path -LiteralPath $archiver -PathType Leaf)) { throw "Required DJGPP archiver is missing: '$archiver'." }
if (-not (Test-Path -LiteralPath $objcopy -PathType Leaf)) { throw "Required DJGPP objcopy is missing: '$objcopy'." }

$runId = (Get-Date -Format 'yyyyMMdd-HHmmssfff') + '-' + [Guid]::NewGuid().ToString('N')
if ([string]::IsNullOrWhiteSpace($ScratchRoot)) {
    $ScratchRoot = Join-Path $repoRoot 'out'
}
$ScratchRoot = [IO.Path]::GetFullPath($ScratchRoot)
New-Item -ItemType Directory -Path $ScratchRoot -Force | Out-Null
$inputRoot = Join-Path $ReportRoot ('isa-linked-inputs-' + $runId)
$runtimeExtractRoot = Join-Path $ScratchRoot ('isa-archive-extract-' + $runId)
$reportLock = $null
try {
try {
    $reportLockPath = Join-Path $ReportRoot '.isa-audit-linked.lock'
    $reportLock = [IO.File]::Open($reportLockPath, [IO.FileMode]::OpenOrCreate,
        [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
}
catch [IO.IOException] {
    $ioCode = $_.Exception.HResult -band 0xffff
    if ($ioCode -in @(32, 33)) {
        throw "Another linked ISA audit is using ReportRoot '$ReportRoot' (exclusive lock '$reportLockPath' is held)."
    }
    throw
}
New-Item -ItemType Directory -Path $inputRoot -Force | Out-Null
New-Item -ItemType Directory -Path $runtimeExtractRoot -Force | Out-Null

$sourceObjectSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($name in $ObjectNames) { $null = $sourceObjectSet.Add($name) }
foreach ($name in $ObjectNames) {
    $sourcePath = Join-Path $ObjectRoot $name
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Selected source object is missing: '$sourcePath'." }
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $inputRoot $name) -Force
}

$mapStarted = $false
$mainText = $null
$rawContributions = New-Object System.Collections.Generic.List[object]
$rawTextFills = New-Object System.Collections.Generic.List[object]
$currentOutputSection = $null
$pendingInputSection = $null
$outputSectionPattern = [regex]::new('^(?<section>\.\S+)\s+0x(?<address>[0-9a-fA-F]+)\s+0x(?<size>[0-9a-fA-F]+)\s*$')
$inputContributionPattern = [regex]::new('^\s+\.(?<section>\S+)\s+0x(?<address>[0-9a-fA-F]+)\s+0x(?<size>[0-9a-fA-F]+)\s+(?<input>.+?)\s*$')
$inputSectionPattern = [regex]::new('^\s+\.(?<section>\S+)\s*$')
$wrappedContributionPattern = [regex]::new('^\s+0x(?<address>[0-9a-fA-F]+)\s+0x(?<size>[0-9a-fA-F]+)\s+(?<input>.+?)\s*$')
$fillPattern = [regex]::new('^\s+\*fill\*\s+0x(?<address>[0-9a-fA-F]+)\s+0x(?<size>[0-9a-fA-F]+)\s*$')
foreach ($line in Get-Content -LiteralPath $MapPath) {
    if ($line -match '^Linker script and memory map\s*$') { $mapStarted = $true; continue }
    if (-not $mapStarted) { continue }

    # GNU ld prints output section headers flush-left. Inputs may be on one
    # line, or as a section-name line followed by an address/size/origin line
    # (common for .text.unlikely and .rodata contributions).
    $outputMatch = $outputSectionPattern.Match($line)
    if ($outputMatch.Success) {
        $currentOutputSection = $outputMatch.Groups['section'].Value
        $pendingInputSection = $null
        if ($currentOutputSection -eq '.text') {
            if ($null -ne $mainText) { throw 'The linker map contains more than one output .text section.' }
            $mainText = [pscustomobject]@{
                address = [Convert]::ToInt64($outputMatch.Groups['address'].Value, 16)
                size = [Convert]::ToInt64($outputMatch.Groups['size'].Value, 16)
            }
        }
        continue
    }

    if ($currentOutputSection -ne '.text') { continue }
    $fillMatch = $fillPattern.Match($line)
    if ($fillMatch.Success) {
        $rawTextFills.Add([pscustomobject]@{
            address = [Convert]::ToInt64($fillMatch.Groups['address'].Value, 16)
            size = [Convert]::ToInt64($fillMatch.Groups['size'].Value, 16)
        })
        $pendingInputSection = $null
        continue
    }
    $inputMatch = $inputContributionPattern.Match($line)
    if ($inputMatch.Success) {
        $rawContributions.Add([pscustomobject]@{
            section = '.' + $inputMatch.Groups['section'].Value
            address = [Convert]::ToInt64($inputMatch.Groups['address'].Value, 16)
            size = [Convert]::ToInt64($inputMatch.Groups['size'].Value, 16)
            input = $inputMatch.Groups['input'].Value.Trim()
        })
        $pendingInputSection = $null
        continue
    }
    $sectionMatch = $inputSectionPattern.Match($line)
    if ($sectionMatch.Success) {
        $pendingInputSection = '.' + $sectionMatch.Groups['section'].Value
        continue
    }
    if (-not [string]::IsNullOrWhiteSpace($pendingInputSection)) {
        $wrappedMatch = $wrappedContributionPattern.Match($line)
        if ($wrappedMatch.Success) {
            $rawContributions.Add([pscustomobject]@{
                section = $pendingInputSection
                address = [Convert]::ToInt64($wrappedMatch.Groups['address'].Value, 16)
                size = [Convert]::ToInt64($wrappedMatch.Groups['size'].Value, 16)
                input = $wrappedMatch.Groups['input'].Value.Trim()
            })
            $pendingInputSection = $null
            continue
        }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
    }
    $pendingInputSection = $null
}
if ($null -eq $mainText) { throw "No output .text section was found in '$MapPath'." }
if ($rawContributions.Count -eq 0) { throw "No input .text contributions were found in '$MapPath'." }

$contributions = New-Object System.Collections.Generic.List[object]
$auditNameByOrigin = @{}
$runtimeInputs = New-Object System.Collections.Generic.List[object]
$runtimeOrdinal = 0
foreach ($entry in $rawContributions) {
    if ($entry.size -eq 0) { continue }
    $origin = $entry.input
    if ($origin -match '^(?<archive>.+\.a)\((?<member>[^)]+)\)$') {
        $archivePath = [IO.Path]::GetFullPath($Matches['archive'])
        $member = $Matches['member']
        $originKey = ('archive|' + $archivePath.ToLowerInvariant() + '|' + $member.ToLowerInvariant())
        if (-not $auditNameByOrigin.ContainsKey($originKey)) {
            $runtimeOrdinal++
            $archiveLabel = [IO.Path]::GetFileNameWithoutExtension($archivePath)
            $memberLabel = [IO.Path]::GetFileNameWithoutExtension($member)
            $auditName = '{0}-{1}.obj' -f $archiveLabel, $memberLabel
            if ($sourceObjectSet.Contains($auditName) -or (Test-Path -LiteralPath (Join-Path $inputRoot $auditName))) {
                $auditName = 'runtime-{0:D4}.obj' -f $runtimeOrdinal
            }
            $extractDir = Join-Path $runtimeExtractRoot ('member-{0:D4}' -f $runtimeOrdinal)
            New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
            Push-Location -LiteralPath $extractDir
            try {
                & $archiver x $archivePath $member
                if ($LASTEXITCODE -ne 0) { throw "Could not extract '$member' from '$archivePath' (ar exit $LASTEXITCODE)." }
            }
            finally { Pop-Location }
            $extracted = Join-Path $extractDir $member
            if (-not (Test-Path -LiteralPath $extracted -PathType Leaf)) {
                throw "The archiver did not produce '$member' from '$archivePath'."
            }
            $destination = Join-Path $inputRoot $auditName
            Copy-Item -LiteralPath $extracted -Destination $destination -Force
            $auditNameByOrigin[$originKey] = $auditName
            $hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            $runtimeInputs.Add([pscustomobject]@{ kind = 'archive-member'; archive = $archivePath; member = $member; object = $auditName; sha256 = $hash })
        }
        $auditName = $auditNameByOrigin[$originKey]
    }
    elseif ($origin -match '^(?<file>.+\.(?:obj|o))$') {
        $sourceLeaf = [IO.Path]::GetFileName($Matches['file'])
        if ($sourceObjectSet.Contains($sourceLeaf)) {
            $auditName = $sourceLeaf
            $origin = Join-Path $ObjectRoot $sourceLeaf
        }
        else {
            $directPath = [IO.Path]::GetFullPath($Matches['file'])
            if (-not (Test-Path -LiteralPath $directPath -PathType Leaf)) { throw "Linked runtime object is missing: '$directPath'." }
            $originKey = ('object|' + $directPath.ToLowerInvariant())
            if (-not $auditNameByOrigin.ContainsKey($originKey)) {
                $runtimeOrdinal++
                $auditName = 'runtime-{0:D4}.obj' -f $runtimeOrdinal
                $destination = Join-Path $inputRoot $auditName
                Copy-Item -LiteralPath $directPath -Destination $destination -Force
                $auditNameByOrigin[$originKey] = $auditName
                $hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
                $runtimeInputs.Add([pscustomobject]@{ kind = 'runtime-object'; path = $directPath; object = $auditName; sha256 = $hash })
            }
            $auditName = $auditNameByOrigin[$originKey]
        }
    }
    else {
        throw "Cannot resolve linker-map .text input '$origin'."
    }

    $contributions.Add([pscustomobject]@{
        section = $entry.section
        address = $entry.address
        size = $entry.size
        object = $auditName
        origin = $origin
    })
}

if ($contributions.Count -eq 0) { throw 'No nonempty executable .text contributions were selected.' }
if (-not [string]::IsNullOrWhiteSpace($RuntimeSourceBundle)) {
    if ([string]::IsNullOrWhiteSpace($ObjectCodeDataProofJson)) {
        throw 'Automatic runtime source proofs require exact project source proofs.'
    }
    if ($Exempt.Count -gt 0 -or $ExemptRange.Count -gt 0) {
        throw 'Automatic source-bound validation forbids instruction and range exemptions.'
    }
    $runtimeProviderIndex = Join-Path $ReportRoot ('runtime-providers-' + $runId + '.json')
    ConvertTo-Json -InputObject $runtimeInputs.ToArray() -Depth 6 | Set-Content -LiteralPath $runtimeProviderIndex -Encoding UTF8
    $runtimeProofRoot = Join-Path $ReportRoot ('runtime-source-' + $runId)
    $compiler = Join-Path (Split-Path -Parent $objdump) ($toolManifest.djgpp.target + '-gcc.exe')
    & python (Join-Path $PSScriptRoot 'runtime-source-proofs.py') --bundle $RuntimeSourceBundle `
        --runtime-directory $inputRoot --runtime-inputs $runtimeProviderIndex --compiler $compiler --output $runtimeProofRoot
    if ($LASTEXITCODE -ne 0) { throw 'Exact runtime source reproduction failed.' }
    $projectProofIndex = Get-Content -LiteralPath $ObjectCodeDataProofJson -Raw | ConvertFrom-Json
    $runtimeProofIndex = Get-Content -LiteralPath (Join-Path $runtimeProofRoot 'proof-index.json') -Raw | ConvertFrom-Json
    if (-not $projectProofIndex.pass -or @($projectProofIndex.failures).Count -gt 0 -or -not $runtimeProofIndex.pass) {
        throw 'Cannot merge incomplete project/runtime source proofs.'
    }
    $ObjectCodeDataProofJson = Join-Path $ReportRoot ('all-source-proofs-' + $runId + '.json')
    [ordered]@{pass=$true;failures=@();proofs=@($projectProofIndex.proofs)+@($runtimeProofIndex.proofs)} |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ObjectCodeDataProofJson -Encoding UTF8
}
$inputNames = @($ObjectNames + @($runtimeInputs | ForEach-Object { $_.object }) | Sort-Object -Unique)
$inputObjectPaths = @($inputNames | ForEach-Object { Join-Path $inputRoot $_ })
# Long isolated-worktree paths can overflow Windows' native command-line limit.
# Inspect every input in bounded batches; concatenation preserves object headers
# and does not omit any runtime member or executable section from the gate.
$inputHeaders = @(for ($headerStart = 0; $headerStart -lt $inputObjectPaths.Count; $headerStart += 32) {
    $headerEnd = [math]::Min($headerStart + 31, $inputObjectPaths.Count - 1)
    $headerBatch = @($inputObjectPaths[$headerStart..$headerEnd])
    & $objdump -h @headerBatch
    if ($LASTEXITCODE -ne 0) { throw 'objdump -h failed while inspecting linked input sections.' }
})
$nonTextCodeSections = New-Object System.Collections.Generic.List[object]
$currentHeaderObject = $null
$currentHeaderSection = $null
$headerObjectPattern = [regex]::new('^(?<path>.+):\s+file format\s+')
$headerSectionPattern = [regex]::new('^\s*\d+\s+(?<section>\S+)\s+')
foreach ($line in $inputHeaders) {
    $objectMatch = $headerObjectPattern.Match($line)
    if ($objectMatch.Success) {
        $currentHeaderObject = [IO.Path]::GetFileName($objectMatch.Groups['path'].Value)
        $currentHeaderSection = $null
        continue
    }
    $sectionMatch = $headerSectionPattern.Match($line)
    if ($sectionMatch.Success) { $currentHeaderSection = $sectionMatch.Groups['section'].Value; continue }
    if ($line -match '\bCODE\b' -and $currentHeaderSection -notmatch '^\.text') {
        $nonTextCodeSections.Add([pscustomobject]@{
            object = $currentHeaderObject; section = $currentHeaderSection; flags = $line.Trim()
        })
    }
}
if ($nonTextCodeSections.Count -gt 0) {
    throw ("Linked inputs contain code sections outside the mapped .text family: {0}" -f
        (($nonTextCodeSections | ForEach-Object { $_.object + ':' + $_.section }) -join ', '))
}
$objectAudit = Join-Path $ReportRoot 'isa-audit-linked-objects.json'
$instructionDetails = Join-Path $ReportRoot 'isa-audit-linked-instructions.jsonl'
$mappedSectionsPath = Join-Path $ReportRoot 'isa-audit-linked-sections.json'
$mappedSections = @($contributions | ForEach-Object {
    [pscustomobject]@{ object = $_.object; section = $_.section }
} | Sort-Object -Property object, section -Unique)
$mappedSections | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $mappedSectionsPath -Encoding ASCII
$isaAuditScript = Join-Path $PSScriptRoot 'isa-audit.ps1'
$strictProof = -not [string]::IsNullOrWhiteSpace($ObjectCodeDataProofJson)
if ($strictProof -and ($Exempt.Count -gt 0 -or $ExemptRange.Count -gt 0)) {
    throw 'Source-bound linked inspection cannot be combined with instruction or range exemptions.'
}
# The pinned fdlibm pow object embeds this double constant in .text. Its bytes
# decode as FCMOV only when linearly disassembled as code. The real reference
# is FADDL at .text+0x303 with a DIR32 relocation at +0x305 to +0x8c0.
# Exempt only these eight bytes and only in the exact inspected object; a
# changed runtime object receives no exemption and must be reviewed again.
$verifiedRuntimeData = @()
foreach ($runtime in $runtimeInputs) {
    if (-not $strictProof -and $runtime.object -eq 'libm-e_pow.obj' -and
        $runtime.sha256 -eq '89E451E432DC68FEC2B3F49EEB64A29BDCA1046FD566AC58695F8B9CA3EB913B') {
        $constantRange = 'libm-e_pow.obj:.text:0x8c0:0x8c8'
        $ExemptRange = @($ExemptRange) + @($constantRange)
        $verifiedRuntimeData += [pscustomobject]@{
            object = $runtime.object; sha256 = $runtime.sha256; range = $constantRange
            bytes = '65dbc9934a86cd3f'; reason = 'FADDL double constant 0.23066074577556175'
        }
    }
}
$proofParameters = @{}
if ($strictProof) { $proofParameters['ObjectCodeDataProofJson'] = $ObjectCodeDataProofJson }
& $isaAuditScript @proofParameters -BuildRoot $BuildRoot -ObjectRoot $inputRoot -ObjectNames $inputNames `
    -MaxIsa $MaxIsa -SkipExecutable -OutputJson $objectAudit `
    -InstructionDetailsJsonl $instructionDetails -SectionAllowListJson $mappedSectionsPath -Exempt $Exempt `
    -ExemptRange $ExemptRange -FailOnViolation
$auditReport = Get-Content -LiteralPath $objectAudit -Raw | ConvertFrom-Json

$coffImage = Export-Go32CoffImage -Executable $executable -Output (Join-Path $runtimeExtractRoot ('linked-' + $runId + '.coff'))
$format = (& $objdump -f $coffImage | Out-String)
if ($LASTEXITCODE -ne 0 -or $format -notmatch 'coff-go32') { throw "Cannot inspect linked executable format:`n$format" }
$headers = & $objdump -h $coffImage
if ($LASTEXITCODE -ne 0) { throw "objdump -h failed for '$executable'." }
$binaryText = $null
$executableCodeSections = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::Ordinal)
$currentExecutableSection = $null
$binaryTextPattern = [regex]::new('^\s*\d+\s+\.text\s+(?<size>[0-9a-fA-F]+)\s+(?<vma>[0-9a-fA-F]+)\s+(?<lma>[0-9a-fA-F]+)\s+(?<offset>[0-9a-fA-F]+)')
$executableSectionPattern = [regex]::new('^\s*\d+\s+(?<section>\S+)\s+')
foreach ($line in $headers) {
    $sectionHeaderMatch = $executableSectionPattern.Match($line)
    if ($sectionHeaderMatch.Success) { $currentExecutableSection = $sectionHeaderMatch.Groups['section'].Value }
    if ($line -match '\bCODE\b' -and $null -ne $currentExecutableSection) {
        $null = $executableCodeSections.Add($currentExecutableSection)
    }
    $match = $binaryTextPattern.Match($line)
    if ($match.Success) {
        $binaryText = [pscustomobject]@{
            size = [Convert]::ToInt64($match.Groups['size'].Value, 16)
            address = [Convert]::ToInt64($match.Groups['vma'].Value, 16)
        }
    }
}
if ($null -eq $binaryText) { throw "No .text section found in '$executable'." }
if ($executableCodeSections.Count -ne 1 -or -not $executableCodeSections.Contains('.text')) {
    throw ("Expected all executable code in the GO32 .text section; found: {0}" -f
        (@($executableCodeSections | Sort-Object) -join ', '))
}
if ($binaryText.address -ne $mainText.address -or $binaryText.size -ne $mainText.size) {
    throw ("Linker-map .text ({0:x8}+{1:x8}) does not match executable .text ({2:x8}+{3:x8})." -f
        $mainText.address, $mainText.size, $binaryText.address, $binaryText.size)
}

$textDumpPath = Join-Path $runtimeExtractRoot ('isa-linked-text-' + $runId + '.bin')
& $objcopy --dump-section ".text=$textDumpPath" $coffImage
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $textDumpPath -PathType Leaf)) {
    throw "Could not extract the executable .text bytes from '$executable'."
}
$linkedTextBytes = [IO.File]::ReadAllBytes($textDumpPath)
if ($linkedTextBytes.Length -ne $binaryText.size) {
    throw ("Extracted executable .text length {0} does not match section size {1}." -f $linkedTextBytes.Length, $binaryText.size)
}

# Account for every byte in the executable .text output section. This includes
# linker-mapped input data such as .rodata and generated alignment fills. The
# pinned GNU ld emits each in-.text fill as repeated 66 90 (XCHG AX,AX), an
# explicitly 486-safe two-byte instruction; any changed fill encoding fails.
$textCoverageSpans = New-Object System.Collections.Generic.List[object]
foreach ($entry in $contributions) {
    if ($entry.size -le 0) { continue }
    $textCoverageSpans.Add([pscustomobject]@{
        address = [long]$entry.address; size = [long]$entry.size
        kind = 'input'; label = $entry.object + ':' + $entry.section
    })
}
$textFillReport = New-Object System.Collections.Generic.List[object]
$textEnd = [long]$mainText.address + [long]$mainText.size
foreach ($fill in $rawTextFills) {
    if ($fill.size -le 0) { continue }
    $fillEnd = [long]$fill.address + [long]$fill.size
    if ([long]$fill.address -lt [long]$mainText.address -or $fillEnd -gt $textEnd) {
        throw ("Linker fill 0x{0:x8}+0x{1:x} falls outside executable .text." -f $fill.address, $fill.size)
    }
    if (($fill.size % 2) -ne 0) {
        throw ("Linker fill 0x{0:x8}+0x{1:x} is not a whole number of 486-safe XCHG AX,AX pairs." -f $fill.address, $fill.size)
    }
    $fillOffset = [int]([long]$fill.address - [long]$binaryText.address)
    $fillLength = [int]$fill.size
    if ($fillOffset -lt 0 -or ($fillOffset + $fillLength) -gt $linkedTextBytes.Length) {
        throw 'Linker fill lies outside the extracted executable .text bytes.'
    }
    for ($byteOffset = 0; $byteOffset -lt $fillLength; $byteOffset += 2) {
        if ($linkedTextBytes[$fillOffset + $byteOffset] -ne 0x66 -or
            $linkedTextBytes[$fillOffset + $byteOffset + 1] -ne 0x90) {
            throw ("Linker fill at 0x{0:x8}+0x{1:x} contains bytes outside the documented 486-safe 66 90 policy." -f $fill.address, $fill.size)
        }
    }
    $textCoverageSpans.Add([pscustomobject]@{
        address = [long]$fill.address; size = [long]$fill.size
        kind = 'linker-fill'; label = '486-safe 66 90 alignment'
    })
    $textFillReport.Add([pscustomobject]@{
        address = ('0x{0:x8}' -f [long]$fill.address)
        size = ('0x{0:x}' -f [long]$fill.size)
        pattern = '66 90 repeated'
    })
}
$sortedTextCoverage = @($textCoverageSpans | Sort-Object -Property address, size, kind)
$textCoverageCursor = [long]$mainText.address
foreach ($span in $sortedTextCoverage) {
    if ([long]$span.address -gt $textCoverageCursor) {
        throw ("Unmapped executable .text bytes at 0x{0:x8}+0x{1:x}; map inputs and linker fills must cover the section continuously." -f $textCoverageCursor, ([long]$span.address - $textCoverageCursor))
    }
    if ([long]$span.address -lt $textCoverageCursor) {
        throw ("Overlapping executable .text coverage near 0x{0:x8} ({1})." -f $span.address, $span.label)
    }
    $textCoverageCursor = [long]$span.address + [long]$span.size
}
if ($textCoverageCursor -ne $textEnd) {
    throw ("Unmapped executable .text tail at 0x{0:x8}+0x{1:x}." -f $textCoverageCursor, ($textEnd - $textCoverageCursor))
}

# Keep relocations from every linked input object. Jump tables and literal
# pointers can live in .text and are rewritten by the linker; a linear objdump
# sweep may decode those relocated bytes as if they were instructions.
$relocationLines = @(for ($relocStart = 0; $relocStart -lt $inputObjectPaths.Count; $relocStart += 32) {
    $relocEnd = [math]::Min($relocStart + 31, $inputObjectPaths.Count - 1)
    $relocBatch = @($inputObjectPaths[$relocStart..$relocEnd])
    & $objdump -r @relocBatch
    if ($LASTEXITCODE -ne 0) { throw 'objdump -r failed while inspecting linked input relocations.' }
})
$relocationDisassemblyPath = Join-Path $ReportRoot 'isa-audit-linked-relocations.txt'
[IO.File]::WriteAllLines($relocationDisassemblyPath, [string[]]$relocationLines, [Text.UTF8Encoding]::new($false))
$relocationRangesByKey = @{}
$currentRelocationObject = $null
$currentRelocationSection = $null
$relocationObjectPattern = [regex]::new('^(?<path>.+):\s+file format\s+')
$relocationSectionPattern = [regex]::new('^RELOCATION RECORDS FOR \[(?<section>[^\]]+)\]:$')
$relocationLinePattern = [regex]::new('^\s*(?<offset>[0-9a-fA-F]+)\s+(?<type>[A-Za-z0-9_]+)\s+')
foreach ($line in $relocationLines) {
    $objectMatch = $relocationObjectPattern.Match($line)
    if ($objectMatch.Success) {
        $currentRelocationObject = [IO.Path]::GetFileName($objectMatch.Groups['path'].Value).ToLowerInvariant()
        $currentRelocationSection = $null
        continue
    }
    $sectionMatch = $relocationSectionPattern.Match($line)
    if ($sectionMatch.Success) {
        $currentRelocationSection = $sectionMatch.Groups['section'].Value
        continue
    }
    if ($null -eq $currentRelocationObject -or $null -eq $currentRelocationSection -or
        -not $currentRelocationSection.StartsWith('.text', [StringComparison]::Ordinal)) { continue }
    $relocationMatch = $relocationLinePattern.Match($line)
    if (-not $relocationMatch.Success) { continue }
    $type = $relocationMatch.Groups['type'].Value.ToLowerInvariant()
    $width = switch -Regex ($type) {
        '^(dir32|disp32|rel32|dir32nb)$' { 4; break }
        '^(dir16|disp16|rel16|dir16nb)$' { 2; break }
        '^(dir8|disp8|rel8)$' { 1; break }
        default { throw "Unsupported linked .text relocation type '$type' in $currentRelocationObject." }
    }
    $relocationKey = $currentRelocationObject + '|' + $currentRelocationSection
    if (-not $relocationRangesByKey.ContainsKey($relocationKey)) {
        $relocationRangesByKey[$relocationKey] = New-Object System.Collections.Generic.List[object]
    }
    $relocationOffset = [Convert]::ToInt64($relocationMatch.Groups['offset'].Value, 16)
    $relocationRangesByKey[$relocationKey].Add([pscustomobject]@{
        start = $relocationOffset; end = $relocationOffset + [int]$width; type = $type
    })
}
$textRelocationCount = 0
$relocationByteSets = @{}
foreach ($relocationKey in $relocationRangesByKey.Keys) {
    $ranges = $relocationRangesByKey[$relocationKey]
    $textRelocationCount += $ranges.Count
    $coveredBytes = [System.Collections.Generic.HashSet[long]]::new()
    foreach ($range in $ranges) {
        for ($offset = [long]$range.start; $offset -lt [long]$range.end; $offset++) {
            $null = $coveredBytes.Add($offset)
        }
    }
    $relocationByteSets[$relocationKey] = $coveredBytes
}

# Validate that the linker retained the input section sizes. DJGPP's linker
# applies relocations but does not relax x86 instruction widths in this build;
# equal input/output contribution sizes make input disassembly offsets exact in
# the final image. If a future linker changes that, this check fails closed.
$rangeReports = New-Object System.Collections.Generic.List[object]
$sectionSizeCache = @{}
$sortedContributions = @($contributions | Sort-Object -Property address, section, object)
$lastEnd = $mainText.address
foreach ($entry in $sortedContributions) {
    $end = $entry.address + $entry.size
    if ($entry.address -lt $mainText.address -or $end -gt ($mainText.address + $mainText.size)) {
        throw ("Mapped input range {0} {1:x8}+{2:x} falls outside executable .text." -f $entry.origin, $entry.address, $entry.size)
    }
    if ($entry.address -lt $lastEnd) { throw ("Overlapping mapped .text inputs near {0:x8} ({1})." -f $entry.address, $entry.origin) }
    $lastEnd = $end

    $sizeKey = $entry.object + '|' + $entry.section
    if (-not $sectionSizeCache.ContainsKey($sizeKey)) {
        $inputObjectPath = Join-Path $inputRoot $entry.object
        $inputHeaders = & $objdump -h $inputObjectPath
        if ($LASTEXITCODE -ne 0) { throw "objdump -h failed for linked input '$inputObjectPath'." }
        $sectionHeaderPattern = [regex]::new('^\s*\d+\s+' + [regex]::Escape($entry.section) + '\s+(?<size>[0-9a-fA-F]+)\s+')
        $inputSize = $null
        foreach ($headerLine in $inputHeaders) {
            $sectionMatch = $sectionHeaderPattern.Match($headerLine)
            if ($sectionMatch.Success) { $inputSize = [Convert]::ToInt64($sectionMatch.Groups['size'].Value, 16); break }
        }
        if ($null -eq $inputSize) { throw "Input object '$inputObjectPath' has no '$($entry.section)' section." }
        $sectionSizeCache[$sizeKey] = $inputSize
    }
    if ([long]$sectionSizeCache[$sizeKey] -ne $entry.size) {
        throw ("Linker changed {0} {1} section size from 0x{2:x} to 0x{3:x}; linked opcode addresses cannot be proven." -f
            $entry.object, $entry.section, $sectionSizeCache[$sizeKey], $entry.size)
    }
    $rangeReports.Add([pscustomobject]@{
        section = $entry.section
        address = ('0x{0:x8}' -f $entry.address)
        size = ('0x{0:x}' -f $entry.size)
        object = $entry.object
        origin = $entry.origin
        endAddress = ('0x{0:x8}' -f $end)
        sizeMatchesInput = $true
    })
}

$contributionByKey = @{}
foreach ($entry in $contributions) {
    $key = $entry.object + '|' + $entry.section
    if ($contributionByKey.ContainsKey($key)) { throw "Multiple linked ranges map to '$key'; split section mapping is unsupported." }
    $contributionByKey[$key] = $entry
}
$parsedDataRanges = New-Object System.Collections.Generic.List[object]
foreach ($specification in $ExemptRange) {
    $parts = $specification -split ':', 4
    if ($parts.Count -ne 4) { throw "Malformed linked input exemption '$specification'." }
    $startOffset = [Convert]::ToInt64(($parts[2] -replace '^0x', ''), 16)
    $endOffset = [Convert]::ToInt64(($parts[3] -replace '^0x', ''), 16)
    $key = $parts[0] + '|' + $parts[1]
    if (-not $contributionByKey.ContainsKey($key)) { throw "Input exemption '$specification' did not match any mapped text contribution." }
    $entry = $contributionByKey[$key]
    if ($startOffset -lt 0 -or $endOffset -le $startOffset -or $endOffset -gt $entry.size) {
        throw "Input exemption '$specification' falls outside $($entry.object) $($entry.section)."
    }
    $parsedDataRanges.Add([pscustomobject]@{
        object = $parts[0]; section = $parts[1]; start = $startOffset; end = $endOffset
        linkedStart = $entry.address + $startOffset; linkedEnd = $entry.address + $endOffset
        reason = $specification
    })
}

function Get-OpcodeKeyLength {
    param([string[]]$Bytes)
    $prefixes = @('66', '67', '2e', '36', '3e', '26', '64', '65', 'f0', 'f2', 'f3')
    $prefixCount = 0
    while ($prefixCount -lt $Bytes.Count -and $Bytes[$prefixCount] -in $prefixes) { $prefixCount++ }
    if ($prefixCount -ge $Bytes.Count) { throw 'Instruction has prefixes but no opcode byte.' }
    $opcode = $Bytes[$prefixCount]
    $count = $prefixCount + 1
    if ($opcode -eq '0f') {
        if ($count -ge $Bytes.Count) { throw 'Instruction has an incomplete 0F opcode.' }
        $second = $Bytes[$count]
        $count++
        if ($second -in @('01', 'ba')) { $count++ }
        elseif ($second -eq '0f') { $count += 2 }
        elseif ($second -in @('38', '3a')) { $count++ }
    }
    elseif ($opcode -in @('f6', 'f7', 'd8', 'd9', 'da', 'db', 'dc', 'dd', 'de', 'df')) { $count++ }
    if ($count -gt $Bytes.Count) { throw 'Instruction does not contain all ISA-defining opcode bytes.' }
    return $count
}

# objdump's whole-section sweep can enter string and jump-table bytes embedded
# in .text. The input-object disassembly supplies instruction boundaries and
# symbols; compare the ISA-defining bytes at those exact addresses in the linked
# .text image. Data ranges above are excluded by explicit, source-backed spans.
$binaryInstructionDetails = Join-Path $ReportRoot 'isa-audit-linked-executable-instructions.jsonl'
$binaryDetailLines = New-Object System.Collections.Generic.List[string]
$verifiedInstructionSites = 0
$exemptedDataSites = 0
$nonInstructionByteSites = 0
$relocatedDataSites = 0
$mismatches = New-Object System.Collections.Generic.List[object]
foreach ($jsonLine in Get-Content -LiteralPath $instructionDetails) {
    if ([string]::IsNullOrWhiteSpace($jsonLine)) { continue }
    $detail = $jsonLine | ConvertFrom-Json
    if (-not $detail.section.StartsWith('.text', [StringComparison]::Ordinal)) { continue }
    $key = $detail.object + '|' + $detail.section
    if (-not $contributionByKey.ContainsKey($key)) {
        throw "Disassembled input section '$key' has no linked map contribution."
    }
    $entry = $contributionByKey[$key]
    $sourceAddress = [long]$detail.address
    if ($sourceAddress -ge $entry.size) { throw "Input instruction offset $sourceAddress exceeds '$key'." }
    $exemptRange = $null
    foreach ($range in $parsedDataRanges) {
        if ([string]::Equals($range.object, $detail.object, [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($range.section, $detail.section, [StringComparison]::Ordinal) -and
            $sourceAddress -ge $range.start -and $sourceAddress -lt $range.end) {
            $exemptRange = $range
            break
        }
    }
    if ($null -ne $exemptRange) { $exemptedDataSites++; continue }

    $sourceBytes = @($detail.bytes)
    $linkedAddress = $entry.address + $sourceAddress
    $textOffset = $linkedAddress - $binaryText.address
    $relocationKey = $detail.object.ToLowerInvariant() + '|' + $detail.section
    $insideRelocation = $relocationByteSets.ContainsKey($relocationKey) -and
        $relocationByteSets[$relocationKey].Contains($sourceAddress)
    if ($insideRelocation) {
        if ($strictProof) { throw "Proved instruction begins in a relocation field at '$key' +$sourceAddress." }
        $relocatedDataSites++
        $linkedByteCount = [Math]::Min($sourceBytes.Count, [Math]::Max(0, $linkedTextBytes.Length - [int]$textOffset))
        $linkedRelocatedBytes = New-Object System.Collections.Generic.List[string]
        for ($byteIndex = 0; $byteIndex -lt $linkedByteCount; $byteIndex++) {
            $linkedRelocatedBytes.Add(('{0:x2}' -f $linkedTextBytes[[int]$textOffset + $byteIndex]))
        }
        $binaryDetailLines.Add((([ordered]@{
            object = $detail.object; origin = $entry.origin; section = $detail.section
            inputAddress = ('0x{0:x}' -f $sourceAddress); linkedAddress = ('0x{0:x8}' -f $linkedAddress)
            symbol = $detail.symbol; isa = $detail.isa
            inputBytes = ($sourceBytes -join ' '); linkedBytes = ($linkedRelocatedBytes -join ' ')
            decoded = $detail.decoded; disposition = 'relocation-covered-object-data'
        } | ConvertTo-Json -Depth 4 -Compress)))
        continue
    }
    $decodedText = [string]$detail.decoded
    $standalonePrefix = $decodedText -match '^(?:es|cs|ss|ds|fs|gs|data16|addr16|lock|rep|repe|repz|repne|repnz)$'
    $objdumpDataByte = $decodedText -match '^\.byte\b'
    if ($sourceBytes.Count -eq 1 -and ($standalonePrefix -or $objdumpDataByte)) {
        if ($strictProof) { throw "Proved CODE contains an incomplete instruction at '$key' +$sourceAddress." }
        if ($textOffset -lt 0 -or $textOffset -ge $linkedTextBytes.Length) {
            throw ("Linked byte at 0x{0:x} is outside the executable .text image." -f $linkedAddress)
        }
        $sourceByte = [string]$sourceBytes[0]
        $linkedByte = '{0:x2}' -f $linkedTextBytes[[int]$textOffset]
        if ($sourceByte -ne $linkedByte) {
            $mismatches.Add([pscustomobject]@{
                object = $detail.object; origin = $entry.origin; section = $detail.section
                sourceOffset = ('0x{0:x}' -f $sourceAddress); linkedAddress = ('0x{0:x8}' -f $linkedAddress)
                symbol = $detail.symbol; inputIsa = $detail.isa
                sourceOpcode = $sourceByte; linkedOpcode = $linkedByte
            })
            continue
        }
        $nonInstructionByteSites++
        $binaryDetailLines.Add((([ordered]@{
            object = $detail.object; origin = $entry.origin; section = $detail.section
            inputAddress = ('0x{0:x}' -f $sourceAddress); linkedAddress = ('0x{0:x8}' -f $linkedAddress)
            symbol = $detail.symbol; isa = $detail.isa; opcodeBytes = $linkedByte
            decoded = $decodedText; disposition = 'matched-non-instruction-byte'
        } | ConvertTo-Json -Depth 4 -Compress)))
        continue
    }
    $keyLength = Get-OpcodeKeyLength -Bytes $sourceBytes
    if ($textOffset -lt 0 -or ($textOffset + $keyLength) -gt $linkedTextBytes.Length) {
        throw ("Linked opcode address 0x{0:x} is outside the executable .text image." -f $linkedAddress)
    }
    $linkedOpcodeBytes = New-Object System.Collections.Generic.List[string]
    for ($byteIndex = 0; $byteIndex -lt $keyLength; $byteIndex++) {
        $linkedOpcodeBytes.Add(('{0:x2}' -f $linkedTextBytes[$textOffset + $byteIndex]))
    }
    $mismatch = $false
    for ($byteIndex = 0; $byteIndex -lt $keyLength; $byteIndex++) {
        if ($sourceBytes[$byteIndex] -ne $linkedOpcodeBytes[$byteIndex]) { $mismatch = $true; break }
    }
    if ($mismatch) {
        $mismatches.Add([pscustomobject]@{
            object = $detail.object; origin = $entry.origin; section = $detail.section
            sourceOffset = ('0x{0:x}' -f $sourceAddress); linkedAddress = ('0x{0:x8}' -f $linkedAddress)
            symbol = $detail.symbol; inputIsa = $detail.isa
            sourceOpcode = ($sourceBytes[0..($keyLength - 1)] -join ' ')
            linkedOpcode = ($linkedOpcodeBytes -join ' ')
        })
        continue
    }
    $verifiedInstructionSites++
    $binaryDetailLines.Add((([ordered]@{
        object = $detail.object; origin = $entry.origin; section = $detail.section
        inputAddress = ('0x{0:x}' -f $sourceAddress); linkedAddress = ('0x{0:x8}' -f $linkedAddress)
        symbol = $detail.symbol; isa = $detail.isa
        opcodeBytes = ($linkedOpcodeBytes -join ' '); disposition = 'matched-input-opcode'
    } | ConvertTo-Json -Depth 4 -Compress)))
}
if ($mismatches.Count -gt 0) {
    $mismatchPath = Join-Path $ReportRoot 'isa-audit-linked-opcode-mismatches.json'
    $mismatches | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $mismatchPath -Encoding ASCII
    throw ("{0} linked opcode site(s) differ from their audited inputs; inspect '{1}'." -f $mismatches.Count, $mismatchPath)
}
[IO.File]::WriteAllLines($binaryInstructionDetails, [string[]]$binaryDetailLines, [Text.UTF8Encoding]::new($false))

# Run a full executable disassembly for the build artifact as an additional
# inspection record. The ISA gate above uses object-derived boundaries because
# GO32 combines code and linker tables in .text.
$fullExecutableDisassembly = Join-Path $ReportRoot 'isa-audit-linked-executable-disassembly.txt'
& $objdump -d --insn-width=16 $coffImage 2>$null | Set-Content -LiteralPath $fullExecutableDisassembly -Encoding ASCII
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $fullExecutableDisassembly -PathType Leaf)) {
    throw "objdump -d failed on linked executable '$executable'."
}

$runtimeInputReport = $runtimeInputs.ToArray()
$textContributionReport = $rangeReports.ToArray()
$dataRangeReport = New-Object System.Collections.Generic.List[object]
foreach ($range in $parsedDataRanges) {
    $dataRangeReport.Add([pscustomobject]@{
        object = $range.object; section = $range.section
        inputStart = ('0x{0:x}' -f $range.start); inputEnd = ('0x{0:x}' -f $range.end)
        linkedStart = ('0x{0:x8}' -f $range.linkedStart); linkedEnd = ('0x{0:x8}' -f $range.linkedEnd)
        reason = $range.reason
    })
}
$report = [ordered]@{
    schemaVersion = 2
    sourceBoundCodeData = $strictProof
    objectCodeDataProofJson = if ($strictProof) { [IO.Path]::GetFullPath($ObjectCodeDataProofJson) } else { $null }
    cpuTarget = $MaxIsa
    pass = $true
    executable = $executable
    executableSha256 = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash
    linkerMapSha256 = (Get-FileHash -LiteralPath $MapPath -Algorithm SHA256).Hash
    linkerMap = $MapPath
    executableFormat = 'coff-go32'
    executableCodeSections = @($executableCodeSections | Sort-Object)
    nonTextExecutableInputSections = $nonTextCodeSections.ToArray()
    executableText = [ordered]@{ address = ('0x{0:x8}' -f $binaryText.address); size = ('0x{0:x}' -f $binaryText.size) }
    linkedTextCoverage = [ordered]@{
        continuous = $true
        bytes = $binaryText.size
        fillPolicy = 'Every linker *fill* span in output .text must contain an even number of repeated 66 90 bytes (486-safe XCHG AX,AX).'
    }
    textFillSpans = @($textFillReport.ToArray())
    instructionAudit = [ordered]@{
        inputObjectAudit = $objectAudit
        inputInstructionDetailsJsonl = $instructionDetails
        linkedInputSectionsJson = $mappedSectionsPath
        inputObjects = $auditReport.objectCount
        inputInstructions = $auditReport.instructionCount
        inputContinuationLines = $auditReport.continuationLineCount
        inputIsaTotals = $auditReport.isaTotals
        inputExempted = $auditReport.exempted
        linkedOpcodeAudit = $binaryInstructionDetails
        linkedInstructionsVerified = $verifiedInstructionSites
        linkedDataSitesExempted = $exemptedDataSites
        linkedNonInstructionByteSitesMatched = $nonInstructionByteSites
        linkedRelocationCoveredDataSites = $relocatedDataSites
        linkedTextRelocationCount = $textRelocationCount
        linkedOpcodeMismatches = $mismatches.Count
        fullExecutableDisassemblyCompleted = $true
    }
    runtimeInputs = $runtimeInputReport
    verifiedRuntimeData = @($verifiedRuntimeData)
    relocationDisassembly = $relocationDisassemblyPath
    fullExecutableDisassembly = $fullExecutableDisassembly
    dataRanges = $dataRangeReport.ToArray()
    textContributions = $textContributionReport
}
$reportPath = Join-Path $ReportRoot 'isa-audit-linked.json'
$reportJson = $null
try { $reportJson = ConvertTo-Json -InputObject $report -Depth 8 }
catch {
    $diagnosticPath = Join-Path $ReportRoot 'isa-audit-linked-report-error.txt'
    [IO.File]::WriteAllText($diagnosticPath, ($_ | Format-List * -Force | Out-String) + "`n" + $_.ScriptStackTrace)
    throw
}
Set-Content -LiteralPath $reportPath -Value $reportJson -Encoding ASCII
Write-Host 'Linked i486 ISA audit: PASS'
Write-Host ('  runtime inputs              {0}' -f $runtimeInputs.Count)
Write-Host ('  executable .text ranges     {0}' -f $rangeReports.Count)
Write-Host ('  input instructions          {0}' -f $auditReport.instructionCount)
Write-Host ('  linked opcodes verified     {0}' -f $verifiedInstructionSites)
Write-Host ('  known data sites exempted   {0}' -f $exemptedDataSites)
Write-Host ('  non-instruction bytes       {0}' -f $nonInstructionByteSites)
Write-Host ('  relocation data sites       {0}' -f $relocatedDataSites)
Write-Host ('  linked opcode report        {0}' -f $binaryInstructionDetails)
Write-Host ('  report                      {0}' -f $reportPath)
}
finally {
    # The object copies are retained in ReportRoot because instruction and
    # runtime-source proof reports contain their absolute paths. Only archive
    # extracts and linked .text staging bytes are disposable.
    try {
        $fullTemporaryRoot = [IO.Path]::GetFullPath($runtimeExtractRoot)
        $fullScratchRoot = [IO.Path]::GetFullPath($ScratchRoot)
        $temporaryParent = [IO.Path]::GetFullPath((Split-Path -Parent $fullTemporaryRoot))
        if (-not [StringComparer]::OrdinalIgnoreCase.Equals($temporaryParent, $fullScratchRoot) -or
            (Split-Path -Leaf $fullTemporaryRoot) -notmatch '^isa-archive-extract-\d{8}-\d{9}-[0-9a-f]{32}$') {
            throw "Refusing to remove ISA scratch directory outside its run-specific ScratchRoot child: '$fullTemporaryRoot'."
        }
        if (Test-Path -LiteralPath $fullTemporaryRoot -PathType Container) {
            $temporaryItem = Get-Item -LiteralPath $fullTemporaryRoot -Force
            if (($temporaryItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing to remove reparse-point ISA scratch directory: '$fullTemporaryRoot'."
            }
            Remove-Item -LiteralPath $fullTemporaryRoot -Recurse -Force
        }
    }
    catch {
        # Cleanup failure must not replace the audit's actual failure or turn an
        # already-written PASS report into a misleading process failure.
        Write-Warning ("Could not remove transient ISA scratch directory: {0}" -f $_.Exception.Message)
    }
    if ($null -ne $reportLock) {
        try { $reportLock.Dispose() }
        catch { Write-Warning ("Could not release linked ISA report lock: {0}" -f $_.Exception.Message) }
    }
}

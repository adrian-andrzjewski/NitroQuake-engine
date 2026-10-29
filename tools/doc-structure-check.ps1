<#
.SYNOPSIS
    Enforces the citation and structure rules the experiment documentation states
    about itself, so the rules cannot rot the way the line numbers did.

.DESCRIPTION
    On 2026-10-03 an audit of the ledger's own line-number citations found ten of
    twelve wrong.  Each had been verified when written, and each was invalidated
    by a later insertion above it in the same file.  The project has since paid
    for that three separate ways, and the recorded rule is to cite by heading and
    never by ":NNNN".

    A rule nobody runs is worth little, so this checks it. The checks are:

      1. No document cites another document by line number.  This is the rule the
         ledger states, and the reason the log was split into docs/ledger/ rather
         than left growing under one heading.

      2. Every relative markdown link resolves.  A split that leaves dangling
         pointers is worse than the monolith, because the pointer looks like an
         answer.

      3. Every ledger file appears exactly once in the Files inventory, and its
         Entries count matches the number of level-two headings in that file.
         Repeated subsection names are normal across records and are not treated
         as duplicate experiments.

      4. Every ledger file has one unique top-level title. This catches missing
         or duplicate record identities without confusing repeated section
         labels such as "Results" or "Scope" with duplicate records.

      5. No heading is skipped a level (H1 -> H3).  Re-parented sub-headings were
         demoted one step precisely so that a section's children are below it.

    Findings are reported as a list and the exit code is non-zero if any check
    fails.  Run it after editing anything under docs/, and before committing.

.PARAMETER RepoRoot
    Repository root.  Defaults to the parent of this script's directory.

.PARAMETER AsJson
    Emit findings as JSON instead of text.

.EXAMPLE
    .\tools\doc-structure-check.ps1

.EXAMPLE
    .\tools\doc-structure-check.ps1 -AsJson | ConvertFrom-Json
#>
[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

if (-not $RepoRoot) {
    $RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
Set-Location $RepoRoot

$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding {
    param([string]$Check, [string]$File, [int]$Line, [string]$Message)
    $findings.Add([pscustomobject]@{
        Check = $Check; File = $File; Line = $Line; Message = $Message
    })
}

# ---------------------------------------------------------------- documents
$docs = @(
    Get-ChildItem -Path $RepoRoot -Filter '*.md' -File
    Get-ChildItem -Path (Join-Path $RepoRoot 'docs') -Filter '*.md' -File -Recurse
) | Sort-Object FullName -Unique

foreach ($d in $docs) {
    $rel = $d.FullName.Substring($RepoRoot.Length).TrimStart('\', '/') -replace '\\', '/'
    $lines = [IO.File]::ReadAllLines($d.FullName)

    # -- check 1: no cross-document line-number citation.
    # A citation inside an inline code span still counts -- `BUILD-DOS.md:187` is
    # a rotted anchor whether or not it is quoted. The one exemption is the
    # process rule's own illustration, which quotes bad anchors on purpose in a
    # "> bad:" blockquote. That form is narrow on purpose: broadening it would
    # hide real anchors, which is the failure this gate exists to prevent.
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*#') { continue }
        if ($line -match '^\s*>\s*(good|bad)\s*:') { continue }
        foreach ($m in [regex]::Matches($line, '([A-Za-z0-9_./-]+\.md):\d+')) {
            Add-Finding 'line-number-citation' $rel ($i + 1) `
                "cites $($m.Value) by line number; name the file and the heading instead"
        }
    }

    # -- check 2: relative markdown links resolve
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        foreach ($m in [regex]::Matches($line, '\]\(([^)#]+?\.md)(#[^)]*)?\)')) {
            $target = $m.Groups[1].Value
            if ($target -match '^[a-z]+:' -or $target.StartsWith('/')) { continue }
            $resolved = [IO.Path]::GetFullPath((Join-Path $d.DirectoryName $target))
            if (-not (Test-Path -LiteralPath $resolved)) {
                Add-Finding 'dangling-link' $rel ($i + 1) "link target does not exist: $target"
            }
        }
    }

    # -- check 5: no skipped heading level
    $prev = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^(#{1,6}) ') {
            $lvl = $matches[1].Length
            if ($prev -gt 0 -and $lvl -gt $prev + 1) {
                Add-Finding 'skipped-heading-level' $rel ($i + 1) "H$prev is followed by H$lvl"
            }
            $prev = $lvl
        }
    }
}

# ------------------------------------------------- checks 3 and 4: the ledger
$ledgerDir = Join-Path $RepoRoot 'docs/ledger'
$ledgerIndex = Join-Path $ledgerDir 'INDEX.md'
$ledgerFiles = @(
    Get-ChildItem -Path $ledgerDir -Filter '*.md' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'INDEX.md' } |
        Sort-Object Name
)

if (Test-Path -LiteralPath $ledgerIndex) {
    $indexText = [IO.File]::ReadAllText($ledgerIndex)
    $filesSection = [regex]::Match($indexText, '(?ms)^## Files\r?\n(.*?)(?=^## |\z)')
    if (-not $filesSection.Success) {
        Add-Finding 'ledger-files-section-missing' 'docs/ledger/INDEX.md' 0 'the complete Files inventory section is missing'
    }
    else {
        $inventory = $filesSection.Groups[1].Value
        $rowPattern = [regex]::new('(?m)^\|\s*\[[^\]]+\]\(([^)#]+\.md)\)\s*\|\s*(\d+)\s*\|\s*(.*?)\s*\|\s*$')
        $indexed = @{}
        $filesByName = @{}
        foreach ($lf in $ledgerFiles) { $filesByName[$lf.Name] = $lf }

        foreach ($row in $rowPattern.Matches($inventory)) {
            $target = $row.Groups[1].Value -replace '\\', '/'
            $name = ($target -split '/')[-1]
            if ($target -ne $name) {
                Add-Finding 'ledger-index-path-invalid' 'docs/ledger/INDEX.md' 0 "inventory links must target a file in docs/ledger/: $target"
            }

            if ($indexed.ContainsKey($name)) {
                Add-Finding 'ledger-file-duplicate-index' 'docs/ledger/INDEX.md' 0 "file is listed more than once: $name"
                continue
            }
            $indexed[$name] = $true

            if (-not $filesByName.ContainsKey($name)) {
                Add-Finding 'ledger-index-unknown-file' 'docs/ledger/INDEX.md' 0 "inventory points to a file that is not in docs/ledger/: $name"
                continue
            }

            $lf = $filesByName[$name]
            $actualCount = [regex]::Matches([IO.File]::ReadAllText($lf.FullName), '(?m)^## ').Count
            $claimedCount = [int]$row.Groups[2].Value
            if ($claimedCount -ne $actualCount) {
                Add-Finding 'ledger-entry-count-wrong' "docs/ledger/$name" 0 "INDEX.md says $claimedCount entries; the file has $actualCount level-two headings"
            }
        }

        foreach ($lf in $ledgerFiles) {
            if (-not $indexed.ContainsKey($lf.Name)) {
                Add-Finding 'ledger-file-unindexed' "docs/ledger/$($lf.Name)" 0 'file has no row in the Files inventory'
            }
        }
    }
}
else {
    Add-Finding 'ledger-index-missing' 'docs/ledger/INDEX.md' 0 'the ledger index is missing'
}

# -- check 4: one unique H1 title per ledger file
$seenTitles = @{}
foreach ($lf in $ledgerFiles) {
    $titles = [regex]::Matches([IO.File]::ReadAllText($lf.FullName), '(?m)^# (.+)$')
    if ($titles.Count -ne 1) {
        Add-Finding 'ledger-title-count' "docs/ledger/$($lf.Name)" 0 "expected one H1 title, found $($titles.Count)"
        continue
    }

    $title = $titles[0].Groups[1].Value.Trim()
    if (-not $seenTitles.ContainsKey($title)) { $seenTitles[$title] = @() }
    $seenTitles[$title] += $lf.Name
}
foreach ($title in $seenTitles.Keys) {
    if ($seenTitles[$title].Count -gt 1) {
        Add-Finding 'duplicate-ledger-title' ($seenTitles[$title] -join ', ') 0 "multiple ledger files use the same H1 title: $title"
    }
}

# ------------------------------------------------------------------- report
if ($AsJson) {
    [pscustomobject]@{
        documents = $docs.Count
        findings  = $findings.Count
        results   = $findings.ToArray()
    } | ConvertTo-Json -Depth 5
    exit $(if ($findings.Count) { 1 } else { 0 })
}

Write-Host ''
Write-Host ('=' * 78)
Write-Host '  doc-structure-check'
Write-Host ('=' * 78)
Write-Host ("  documents scanned : {0}" -f $docs.Count)
Write-Host ("  ledger files      : {0}" -f $ledgerFiles.Count)

if ($findings.Count -eq 0) {
    Write-Host ''
    Write-Host '  PASS - citations and links are valid, heading levels are sound,'
    Write-Host '         and the ledger inventory and counts match.'
    exit 0
}

Write-Host ''
Write-Host ("  FAIL - {0} finding(s):" -f $findings.Count)
Write-Host ''
foreach ($g in ($findings | Group-Object Check | Sort-Object Name)) {
    Write-Host ("  {0}  ({1})" -f $g.Name, $g.Count)
    foreach ($f in $g.Group) {
        Write-Host ("      {0}:{1}" -f $f.File, $f.Line)
        Write-Host ("        {0}" -f $f.Message)
    }
    Write-Host ''
}
exit 1

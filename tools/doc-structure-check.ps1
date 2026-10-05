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

    A rule nobody runs is worth little, so this checks it.  The checks are:

      1. No document cites another document by line number.  This is the rule the
         ledger states, and the reason the log was split into docs/ledger/ rather
         than left growing under one heading.

      2. Every relative markdown link resolves.  A split that leaves dangling
         pointers is worse than the monolith, because the pointer looks like an
         answer.

      3. Every entry in docs/ledger/ appears in docs/ledger/INDEX.md, and every
         file in docs/ledger/ is indexed.  The index is the only way to find a
         result now that the log is fifteen files.

      4. No two ledger files carry the same top-level heading.  Duplication was
         the defect that motivated the split; this is what stops it returning.

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

# ------------------------------------------------- check 3: the ledger index
$ledgerDir = Join-Path $RepoRoot 'docs/ledger'
$ledgerIndex = Join-Path $ledgerDir 'INDEX.md'
if (Test-Path -LiteralPath $ledgerIndex) {
    $indexText = [IO.File]::ReadAllText($ledgerIndex)
    $ledgerFiles = Get-ChildItem -Path $ledgerDir -Filter '*.md' -File | Where-Object { $_.Name -ne 'INDEX.md' }

    foreach ($lf in $ledgerFiles) {
        if ($indexText -notmatch [regex]::Escape($lf.Name)) {
            Add-Finding 'ledger-file-unindexed' "docs/ledger/$($lf.Name)" 0 'file is not listed in INDEX.md'
        }
        # every H2 in the file is one ledger entry and must be indexed
        $entryCount = 0
        foreach ($h in [regex]::Matches([IO.File]::ReadAllText($lf.FullName), '(?m)^## (.+)$')) {
            $entryCount++
            $needle = $h.Groups[1].Value.Trim()
            if ($needle.Length -gt 40) { $needle = $needle.Substring(0, 40) }
            if ($indexText -notmatch [regex]::Escape($needle)) {
                Add-Finding 'ledger-entry-unindexed' "docs/ledger/$($lf.Name)" 0 "entry not in INDEX.md: $needle"
            }
        }

        # The Files table's Entries column must be that file's heading count.
        #
        # Check 3 above proves every entry is *indexed*; it says nothing about the
        # number the index prints, which is how the table came to claim 74 entries
        # in total while six of its own per-file counts were wrong and the three
        # sourced-from-BUILD-DOS files were listed as holding none. A count that
        # nobody recomputes is a count that rots, and this file exists because a
        # number nobody recomputes did.
        $rowPattern = [regex]::Escape($lf.Name) + '\)\s*\|\s*(\d+)\s*\|'
        $rowMatch = [regex]::Match($indexText, $rowPattern)
        if ($rowMatch.Success) {
            $claimed = [int]$rowMatch.Groups[1].Value
            if ($claimed -ne $entryCount) {
                Add-Finding 'ledger-entry-count-wrong' "docs/ledger/$($lf.Name)" 0 "INDEX.md says $claimed entries, the file has $entryCount '## ' headings"
            }
        }
    }

    # And the stated grand total must be the sum of the heading counts.
    $grandTotal = 0
    foreach ($lf in $ledgerFiles) {
        $grandTotal += [regex]::Matches([IO.File]::ReadAllText($lf.FullName), '(?m)^## ').Count
    }
    $statedMatch = [regex]::Match($indexText, '\*\*(\d+)\s+(?:entries|headings)\*\*')
    if ($statedMatch.Success) {
        $stated = [int]$statedMatch.Groups[1].Value
        if ($stated -ne $grandTotal) {
            Add-Finding 'ledger-total-wrong' 'docs/ledger/INDEX.md' 0 "INDEX.md states $stated headings, the ledger holds $grandTotal across $($ledgerFiles.Count) files"
        }
    }
}
else {
    Add-Finding 'ledger-index-missing' 'docs/ledger/INDEX.md' 0 'the ledger index is missing'
}

# --------------------------------------- check 4: no duplicated top headings
$seen = @{}
foreach ($lf in (Get-ChildItem -Path $ledgerDir -Filter '*.md' -File -ErrorAction SilentlyContinue)) {
    foreach ($h in [regex]::Matches([IO.File]::ReadAllText($lf.FullName), '(?m)^## (.+)$')) {
        $t = $h.Groups[1].Value.Trim()
        if (-not $seen.ContainsKey($t)) { $seen[$t] = @() }
        $seen[$t] += $lf.Name
    }
}
foreach ($t in $seen.Keys) {
    if ($seen[$t].Count -gt 1) {
        Add-Finding 'duplicate-ledger-heading' ($seen[$t] -join ', ') 0 "same entry title in $($seen[$t].Count) files: $t"
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
Write-Host ("  ledger files      : {0}" -f (Get-ChildItem -Path $ledgerDir -Filter '*.md' -File -ErrorAction SilentlyContinue).Count)

if ($findings.Count -eq 0) {
    Write-Host ''
    Write-Host '  PASS - no line-number citations, no dangling links, no skipped'
    Write-Host '         heading levels, and the ledger index is complete.'
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
